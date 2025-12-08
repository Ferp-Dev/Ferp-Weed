local QBX = exports.qbx_core

-- Plant seed
RegisterNetEvent('Ferp-Weed:server:plantSeed', function(coords, heading, modifiers, slot)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Remove seed
    if not Weed.RemoveItem(src, 'weed_seed_female', 1, nil, slot) then
        return Weed.Notify(src, Lang('notify', 'plant_error'), 'error')
    end
    
    -- Get strain from modifiers or assign random default
    local strain = modifiers.strain or 0
    local n = modifiers.n or 0.5
    local p = modifiers.p or 0.5
    local k = modifiers.k or 0.5
    local strainName = modifiers.strain_name or nil
    
    -- If no strain (0), assign a random default strain with negative ID
    if strain == 0 then
        local randomStrain = Weed.Strains.GetRandomDefault()
        strain = randomStrain.id -- Negative ID (e.g., -1, -2, etc.)
        n = randomStrain.n
        p = randomStrain.p
        k = randomStrain.k
        strainName = randomStrain.name
        Weed.Debug("Assigned random default strain: %s (ID: %d)", randomStrain.name, strain)
    end
    
    -- Create plant metadata
    local metadata = {
        gender = 0, -- 0 = female, 1 = male
        strain = strain,
        strain_name = strainName,
        n = n,
        p = p,
        k = k,
        water = modifiers.water or 0.5,
        lastHarvest = 0,
        createdAt = os.time(),
    }
    
    -- Save to database
    local plantId = MySQL.insert.await([[
        INSERT INTO weed_plants (citizenid, coords, metadata, created_at, expires_at)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        Player.PlayerData.citizenid,
        json.encode({x = coords.x, y = coords.y, z = coords.z}),
        json.encode(metadata),
        os.time(),
        os.time() + (Weed.Plants.Config.LifeTime * 60)
    })
    
    if not plantId then
        return Weed.Notify(src, Lang('notify', 'save_error'), 'error')
    end
    
    -- Get current stage model
    local growth = Weed.Plants.GetGrowth({metadata = metadata}, os.time())
    local stage = Weed.Plants.GetStage(growth)
    local model = Weed.Plants.Config.Objects[stage].model
    
    -- Store in active plants
    Weed.Plants.Active[plantId] = {
        id = plantId,
        citizenid = Player.PlayerData.citizenid,
        coords = coords,
        heading = heading,
        model = model,
        metadata = metadata,
        netId = nil
    }
    
    -- Spawn for all clients
    TriggerClientEvent('Ferp-Weed:client:spawnPlant', -1, {
        id = plantId,
        coords = coords,
        heading = heading,
        model = model
    })
    
    Weed.Notify(src, Lang('notify', 'plant_success'), 'success')
    Weed.Debug("Plant %d created by %s", plantId, Player.PlayerData.citizenid)
end)

-- Get plant data by netId
lib.callback.register('Ferp-Weed:server:getPlant', function(source, netId)
    -- Find plant by network ID or entity
    for plantId, plant in pairs(Weed.Plants.Active) do
        if plant.netId == netId then
            return plant
        end
    end
    
    -- If not found in active, try to load from database
    return nil
end)

-- Get plant data by ID
lib.callback.register('Ferp-Weed:server:getPlantById', function(source, plantId)
    if Weed.Plants.Active[plantId] then
        return Weed.Plants.Active[plantId]
    end
    return nil
end)

-- Get plant data by coordinates (fallback search)
lib.callback.register('Ferp-Weed:server:getPlantByCoords', function(source, coords)
    local searchCoords = type(coords) == 'vector3' and coords or vector3(coords.x, coords.y, coords.z)
    
    for plantId, plant in pairs(Weed.Plants.Active) do
        local plantCoords = type(plant.coords) == 'vector3' and plant.coords or vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        local distance = #(searchCoords - plantCoords)
        if distance < 3.0 then
            return plant
        end
    end
    
    return nil
end)

-- Water plant
RegisterNetEvent('Ferp-Weed:server:waterPlant', function(plantId)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then 
        print('[WEED DEBUG] Player not found for source: ' .. tostring(src))
        return 
    end
    
    print('[WEED DEBUG] Water plant called - plantId: ' .. tostring(plantId))
    
    -- Find plant
    local plant = Weed.Plants.Active[plantId]
    
    if not plant then
        print('[WEED DEBUG] Plant not found in Active - plantId: ' .. tostring(plantId))
        print('[WEED DEBUG] Active plants: ' .. json.encode(Weed.Plants.Active))
        return Weed.Notify(src, Lang('notify', 'plant_not_found'), 'error')
    end
    
    print('[WEED DEBUG] Plant found - current water: ' .. tostring(plant.metadata.water))
    
    -- Check if already at max water BEFORE removing item
    if plant.metadata.water >= 1.0 then
        return Weed.Notify(src, Lang('notify', 'already_watered'), 'error')
    end
    
    -- Verificar regador com água
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    local wateringCanSlot = nil
    local wateringCanItem = nil
    
    for slot, item in pairs(inventory) do
        if item.name == 'wateringcan' then
            local waterLevel = item.metadata and item.metadata.water or 0
            if waterLevel > 0 then
                wateringCanSlot = slot
                wateringCanItem = item
                break
            end
        end
    end
    
    if not wateringCanSlot then
        return Weed.Notify(src, Lang('notify', 'need_watering_can_water'), 'error')
    end
    
    -- Diminuir água do regador (cada rega usa 20% da água)
    local waterUsed = 20
    local currentWater = wateringCanItem.metadata.water or 100
    local newWater = math.max(0, currentWater - waterUsed)
    
    local newMetadata = wateringCanItem.metadata or {}
    newMetadata.water = newWater
    
    if newWater > 0 then
        newMetadata.description = Lang('notify', 'watering_can_water', newWater)
    else
        newMetadata.description = Lang('notify', 'watering_can_empty')
    end
    
    exports.ox_inventory:SetMetadata(src, wateringCanSlot, newMetadata)
    
    print('[WEED DEBUG] Watering can water used: ' .. waterUsed .. '%, remaining: ' .. newWater .. '%')
    
    -- Add water to plant
    plant.metadata.water = math.min(1.0, plant.metadata.water + Weed.Plants.Config.WaterAdd)
    print('[WEED DEBUG] New water level: ' .. tostring(plant.metadata.water))
    
    -- Update database
    MySQL.update([[
        UPDATE weed_plants
        SET metadata = ?
        WHERE id = ?
    ]], {
        json.encode(plant.metadata),
        plantId
    })
    
    Weed.Notify(src, Lang('notify', 'plant_watered', plant.metadata.water * 100, newWater), 'success')
    Weed.Debug("Plant %d watered", plantId)
end)

-- Apply fertilizer (boost growth - one time use, 25% faster)
RegisterNetEvent('Ferp-Weed:server:applyFertilizer', function(plantId)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Find plant
    local plant = Weed.Plants.Active[plantId]
    
    if not plant then
        return Weed.Notify(src, Lang('notify', 'plant_not_found'), 'error')
    end
    
    -- Check if fertilizer already applied
    if plant.metadata.fertilized then
        return Weed.Notify(src, Lang('notify', 'already_fertilized'), 'error')
    end
    
    -- Remove fertilizer
    if not Weed.RemoveItem(src, 'fertilizer', 1) then
        return Weed.Notify(src, Lang('notify', 'no_fertilizer'), 'error')
    end
    
    -- Mark as fertilized and reduce growth time by 25%
    plant.metadata.fertilized = true
    
    -- Reduce createdAt to simulate 25% faster growth
    local currentTime = os.time()
    local elapsed = currentTime - plant.metadata.createdAt
    local boost = Weed.Plants.Config.FertilizerBoost or 0.25
    plant.metadata.createdAt = plant.metadata.createdAt - math.floor(elapsed * boost)
    
    -- Update database
    MySQL.update([[
        UPDATE weed_plants
        SET metadata = ?
        WHERE id = ?
    ]], {
        json.encode(plant.metadata),
        plantId
    })
    
    Weed.Notify(src, Lang('notify', 'fertilizer_applied'), 'success')
    Weed.Debug("Plant %d fertilized for 25%% growth boost", plantId)
end)

-- Create strain on plant (requires strain_modifier item)
RegisterNetEvent('Ferp-Weed:server:createStrain', function(plantId, strainData, isNew)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Find plant
    local plant = Weed.Plants.Active[plantId]
    
    if not plant then
        return Weed.Notify(src, Lang('notify', 'plant_not_found'), 'error')
    end

    if plant.metadata.strain and plant.metadata.strain > 0 then
        return Weed.Notify(src, Lang('notify', 'has_custom_strain'), 'error')
    end
    
    -- Verificar se tem o kit de modificação genética
    local strainModifier = exports.ox_inventory:GetItem(src, 'strain_modifier', nil, false)
    if not strainModifier or strainModifier.count < 1 then
        return Weed.Notify(src, Lang('notify', 'need_strain_modifier'), 'error')
    end
    
    -- Remover o item
    if not Weed.RemoveItem(src, 'strain_modifier', 1) then
        return Weed.Notify(src, Lang('notify', 'kit_error'), 'error')
    end
    
    local strain = strainData
    
    -- Create new strain if needed
    if isNew then
        local created = Weed.Strains.Create(Player.PlayerData.citizenid, strainData)
        if created then
            strain = Weed.Strains.GetByModifiers(strainData.n, strainData.p, strainData.k)
        else
            return Weed.Notify(src, Lang('notify', 'strain_limit_error'), 'error')
        end
    end
    
    -- Apply strain to plant
    plant.metadata.strain = strain.id or 0
    plant.metadata.n = math.min(2.0, plant.metadata.n + (strain.n * Weed.Plants.Config.FertilizerAdd))
    plant.metadata.p = math.min(2.0, plant.metadata.p + (strain.p * Weed.Plants.Config.FertilizerAdd))
    plant.metadata.k = math.min(2.0, plant.metadata.k + (strain.k * Weed.Plants.Config.FertilizerAdd))
    
    -- Update database
    MySQL.update([[
        UPDATE weed_plants
        SET metadata = ?
        WHERE id = ?
    ]], {
        json.encode(plant.metadata),
        plantId
    })
    
    Weed.Notify(src, Lang('notify', 'strain_applied', strain.name or 'Nova'), 'success')
    Weed.Debug("Plant %d got strain %d", plantId, strain.id or 0)
end)

-- Make plant male
RegisterNetEvent('Ferp-Weed:server:makePlantMale', function(plantId)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Find plant
    local plant = Weed.Plants.Active[plantId]
    
    if not plant then
        return Weed.Notify(src, Lang('notify', 'plant_not_found'), 'error')
    end
    
    -- Remove male seed
    if not Weed.RemoveItem(src, 'weed_seed_male', 1) then
        return Weed.Notify(src, Lang('notify', 'no_male_seed'), 'error')
    end
    
    -- Change gender
    plant.metadata.gender = 1
    
    -- Update database
    MySQL.update([[
        UPDATE weed_plants
        SET metadata = ?
        WHERE id = ?
    ]], {
        json.encode(plant.metadata),
        plantId
    })
    
    Weed.Notify(src, Lang('notify', 'plant_now_male'), 'success')
    Weed.Debug("Plant %d made male", plantId)
end)

-- Harvest plant
RegisterNetEvent('Ferp-Weed:server:harvestPlant', function(plantId)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Find plant
    local plant = Weed.Plants.Active[plantId]
    
    if not plant then
        return Weed.Notify(src, Lang('notify', 'plant_not_found'), 'error')
    end
    
    -- Check growth
    local growth = Weed.Plants.GetGrowth(plant, os.time())
    if growth < Weed.Plants.Config.HarvestPercent then
        return Weed.Notify(src, Lang('notify', 'plant_not_ready'), 'error')
    end
    
    -- Check time since last harvest
    local timeSinceHarvest = os.time() - plant.metadata.lastHarvest
    if timeSinceHarvest < (Weed.Plants.Config.TimeBetweenHarvest * 60) then
        return Weed.Notify(src, Lang('notify', 'wait_before_harvest'), 'error')
    end
    
    -- Update last harvest time
    plant.metadata.lastHarvest = os.time()
    
    -- Calculate quality
    local quality = Weed.Plants.GetQuality(plant.metadata)
    
    -- Get strain - check for custom strain
    local strainId = plant.metadata.strain
    local strain = nil
    
    if strainId and strainId > 0 then
        -- Custom strain created by player
        strain = Weed.Strains.Get(strainId)
        Weed.Debug("Found custom strain ID %s: %s", tostring(strainId), strain and strain.name or "NOT FOUND")
    elseif strainId and strainId < 0 then
        -- Default strain (negative ID)
        strain = Weed.Strains.GetDefaultById(strainId)
        Weed.Debug("Found default strain ID %s: %s", tostring(strainId), strain and strain.name or "NOT FOUND")
    end
    
    -- If still no strain found (shouldn't happen), get a random default
    if not strain then
        strain = Weed.Strains.GetRandomDefault()
        Weed.Debug("No strain found, assigned random: %s", strain.name)
    end
    
    -- Female plant - give buds (directly, no drying needed)
    if plant.metadata.gender == 0 then
        local budCount = math.random(Weed.Plants.Config.BudsFromFemale[1], Weed.Plants.Config.BudsFromFemale[2])
        local metadata = Weed.Items.CreateMetadata('weed_bud', strain, quality)
        Weed.AddItem(src, 'weed_bud', budCount, metadata)
        
        Weed.Notify(src, Lang('notify', 'harvested_buds', budCount), 'success')
    
    -- Male plant - give seeds
    else
        if Weed.Plants.Config.RemoveMaleOnHarvest then
            -- Remove plant
            MySQL.update('DELETE FROM weed_plants WHERE id = ?', {plantId})
            Weed.Plants.Active[plantId] = nil
            TriggerClientEvent('Ferp-Weed:client:removePlant', -1, plantId)
        end
        
        local seedCount = math.random(Weed.Plants.Config.SeedsFromMale[1], Weed.Plants.Config.SeedsFromMale[2])
        
        print(string.format("[Ferp-Weed] Harvesting male - strain ID: %d, name: %s", strain.id or 0, strain.name or "NONE"))
        
        for i = 1, seedCount do
            if math.random() <= Weed.Plants.Config.MaleChance then
                Weed.AddItem(src, 'weed_seed_male', 1)
            else
                local metadata = Weed.Items.CreateMetadata('weed_seed_female', strain, quality)
                print(string.format("[Ferp-Weed] Created seed metadata: strain=%d, strain_name=%s, n=%.2f", 
                    metadata.strain or 0, metadata.strain_name or "NONE", metadata.n or 0))
                Weed.AddItem(src, 'weed_seed_female', 1, metadata)
            end
        end
        
        Weed.Notify(src, Lang('notify', 'harvested_seeds', seedCount), 'success')
    end
    
    -- Update database if not removed
    if not Weed.Plants.Config.RemoveMaleOnHarvest or plant.metadata.gender == 0 then
        MySQL.update([[
            UPDATE weed_plants
            SET metadata = ?
            WHERE id = ?
        ]], {
            json.encode(plant.metadata),
            plantId
        })
    end
    
    Weed.Debug("Plant %d harvested by %s", plantId, Player.PlayerData.citizenid)
end)

-- Destroy plant
RegisterNetEvent('Ferp-Weed:server:destroyPlant', function(plantId)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Find plant
    local plant = Weed.Plants.Active[plantId]
    
    if not plant then
        return Weed.Notify(src, Lang('notify', 'plant_not_found'), 'error')
    end
    
    -- Check ownership or police
    local isOwner = plant.citizenid == Player.PlayerData.citizenid
    local isPolice = Weed.IsPolice(src)
    
    if not isOwner and not isPolice then
        return Weed.Notify(src, Lang('notify', 'cannot_destroy_plant'), 'error')
    end
    
    -- Remove from database
    MySQL.update('DELETE FROM weed_plants WHERE id = ?', {plantId})
    
    -- Remove from active
    Weed.Plants.Active[plantId] = nil
    
    -- Remove for all clients
    TriggerClientEvent('Ferp-Weed:client:removePlant', -1, plantId)
    
    Weed.Notify(src, Lang('notify', 'plant_removed'), 'success')
    Weed.Debug("Plant %d destroyed by %s", plantId, Player.PlayerData.citizenid)
end)

-- Load plants from database on startup
CreateThread(function()
    Wait(5000) -- Wait for database
    
    local plants = MySQL.query.await('SELECT * FROM weed_plants WHERE expires_at > ?', {os.time()})
    
    if plants then
        for _, plantData in ipairs(plants) do
            local coords = json.decode(plantData.coords)
            local metadata = json.decode(plantData.metadata)
            
            -- Calculate current stage
            local growth = Weed.Plants.GetGrowth({metadata = metadata}, os.time())
            local stage = Weed.Plants.GetStage(growth)
            local model = Weed.Plants.Config.Objects[stage].model
            
            Weed.Plants.Active[plantData.id] = {
                id = plantData.id,
                citizenid = plantData.citizenid,
                coords = vector3(coords.x, coords.y, coords.z),
                heading = 0.0,
                model = model,
                metadata = metadata,
                netId = nil
            }
        end
        
        Weed.Debug("Loaded %d plants from database", #plants)
    end
end)

-- Helper to count table
local function TableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Update plant growth periodically
CreateThread(function()
    -- Wait for config
    while not Config.Performance do
        Wait(1000)
    end
    
    local updateInterval = (Config.Performance.ServerUpdateInterval or 300) * 1000 -- Default 5 minutes
    
    while true do
        Wait(updateInterval)
        
        local currentTime = os.time()
        local updatedPlants = {} 
        local batchSize = 50 
        local processed = 0
        
        for plantId, plant in pairs(Weed.Plants.Active) do
            local growth = Weed.Plants.GetGrowth(plant, currentTime)
            local newStage = Weed.Plants.GetStage(growth)
            local currentStage = 1
            
            -- Find current stage
            for i, obj in ipairs(Weed.Plants.Config.Objects) do
                if obj.model == plant.model then
                    currentStage = i
                    break
                end
            end
            
            -- Update if stage changed
            if newStage ~= currentStage and Weed.Plants.Config.Objects[newStage] then
                plant.model = Weed.Plants.Config.Objects[newStage].model
                updatedPlants[plantId] = plant.model
            end
            
            processed = processed + 1
            
            -- Yield every batchSize plants to prevent blocking
            if processed % batchSize == 0 then
                Wait(0)
            end
        end
        
        -- Send batch update to clients
        if next(updatedPlants) then
            TriggerClientEvent('Ferp-Weed:client:batchUpdatePlants', -1, updatedPlants)
            Weed.Debug("Batch updated %d plants", TableCount(updatedPlants))
        end
    end
end)

-- Clean up expired plants
CreateThread(function()
    while true do
        Wait(600000) -- Every 10 minutes instead of 5
        
        local currentTime = os.time()
        local expiredIds = {}
        
        -- Collect expired plant IDs
        for plantId, plant in pairs(Weed.Plants.Active) do
            -- Check if plant expired based on metadata
            local expiresAt = plant.metadata.createdAt + (Weed.Plants.Config.LifeTime * 60)
            if currentTime > expiresAt then
                expiredIds[#expiredIds + 1] = plantId
            end
        end
        
        -- Batch delete from memory and notify clients
        if #expiredIds > 0 then
            for _, plantId in ipairs(expiredIds) do
                Weed.Plants.Active[plantId] = nil
            end
            
            -- Single DB query to delete all expired
            MySQL.update('DELETE FROM weed_plants WHERE expires_at < ?', {currentTime})
            
            -- Notify clients in batch
            TriggerClientEvent('Ferp-Weed:client:batchRemovePlants', -1, expiredIds)
            
            Weed.Debug("Cleaned up %d expired plants", #expiredIds)
        end
    end
end)

Weed.Debug("Server plants loaded")