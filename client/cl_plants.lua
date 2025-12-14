local SpawnedPlants = {} -- [plantId] = entity
local PlantData = {} -- [plantId] = {coords, heading, model}
local PlantChunks = {} -- Spatial partitioning: [chunkKey] = {plantId1, plantId2, ...}
local PendingSpawns = {} -- Queue for batch spawning
local isSpawning = false -- Flag to prevent multiple spawn loops

-- Performance cache
local cachedPlayerCoords = vector3(0, 0, 0)
local lastCoordsUpdate = 0
local COORDS_UPDATE_INTERVAL = 500 

-- Helper function to count table entries
local function TableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Get chunk key from coordinates
local function GetChunkKey(coords)
    local chunkSize = Config.Performance and Config.Performance.ChunkSize or 100.0
    local cx = math.floor(coords.x / chunkSize)
    local cy = math.floor(coords.y / chunkSize)
    return cx .. '_' .. cy
end

-- Get nearby chunk keys (current + 8 surrounding)
local function GetNearbyChunks(coords)
    local chunkSize = Config.Performance and Config.Performance.ChunkSize or 100.0
    local cx = math.floor(coords.x / chunkSize)
    local cy = math.floor(coords.y / chunkSize)
    local chunks = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            chunks[#chunks + 1] = (cx + dx) .. '_' .. (cy + dy)
        end
    end
    return chunks
end

-- Add plant to chunk
local function AddToChunk(plantId, coords)
    local key = GetChunkKey(coords)
    if not PlantChunks[key] then
        PlantChunks[key] = {}
    end
    PlantChunks[key][plantId] = true
end

-- Remove plant from chunk
local function RemoveFromChunk(plantId, coords)
    local key = GetChunkKey(coords)
    if PlantChunks[key] then
        PlantChunks[key][plantId] = nil
    end
end

-- Get cached player coords
local function GetCachedPlayerCoords()
    local now = GetGameTimer()
    if now - lastCoordsUpdate > COORDS_UPDATE_INTERVAL then
        cachedPlayerCoords = GetEntityCoords(cache.ped)
        lastCoordsUpdate = now
    end
    return cachedPlayerCoords
end

-- Get current unix timestamp
local function GetCurrentTime()
    return lib.callback.await('Ferp-Weed:server:getTime', false) or 0
end


-- Request and spawn a plant object
local function SpawnPlantObject(plantId, coords, heading, model)
    lib.requestModel(model, 5000)
    
    -- Get z offset from config
    local zOffset = -0.5 -- Default offset to hide pot
    for _, obj in ipairs(Weed.Plants.Config.Objects) do
        if obj.model == model then
            zOffset = obj.zOffset or -0.5
            break
        end
    end
    
    -- Create object and place on ground first
    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, heading)
    PlaceObjectOnGroundProperly(entity)
    
    -- Now adjust Z position to bury the pot
    local currentCoords = GetEntityCoords(entity)
    SetEntityCoords(entity, currentCoords.x, currentCoords.y, currentCoords.z + zOffset, false, false, false, false)
    
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)
    
    return entity
end

-- Get plant data by entity
local function GetPlantByEntity(entity)
    if not DoesEntityExist(entity) then return nil end
    
    -- First: check if entity is directly in SpawnedPlants
    for plantId, spawnedEntity in pairs(SpawnedPlants) do
        if spawnedEntity == entity then
            local plantData = lib.callback.await('Ferp-Weed:server:getPlantById', false, plantId)
            if plantData then
                plantData.entity = entity
                return plantData
            end
        end
    end
    
    -- Second: search by coordinates with very small distance 
    local entityCoords = GetEntityCoords(entity)
    local closestPlantId = nil
    local closestDistance = 1.0 -- Max 1 meter
    
    for plantId, data in pairs(PlantData) do
        local plantCoords = type(data.coords) == 'vector3' and data.coords or vector3(data.coords.x, data.coords.y, data.coords.z)
        local distance = #(entityCoords - plantCoords)
        if distance < closestDistance then
            closestDistance = distance
            closestPlantId = plantId
        end
    end
    
    if closestPlantId then
        local plantData = lib.callback.await('Ferp-Weed:server:getPlantById', false, closestPlantId)
        if plantData then
            plantData.entity = entity
            -- Update SpawnedPlants for future exact matches
            SpawnedPlants[closestPlantId] = entity
            return plantData
        end
    end
    
    -- Fallback: search by coordinates on server
    local plantData = lib.callback.await('Ferp-Weed:server:getPlantByCoords', false, entityCoords)
    if plantData then
        PlantData[plantData.id] = {
            coords = plantData.coords,
            heading = plantData.heading or 0.0,
            model = plantData.model
        }
        SpawnedPlants[plantData.id] = entity
        plantData.entity = entity
        return plantData
    end
    
    return nil
end

-- Check plant
function CheckPlant(entity)
    if not DoesEntityExist(entity) then return end
    
    local plant = GetPlantByEntity(entity)
    if not plant then
        return Weed.Notify(cache.serverId, Lang('notify', 'plant_not_found'), 'error')
    end
    
    local currentTime = GetCurrentTime()
    local growth = Weed.Plants.GetGrowth(plant, currentTime)
    local QBX = exports.qbx_core
    local Player = QBX:GetPlayerData()
    local citizenid = Player.citizenid
    
    -- Debug strain info
    -- print(string.format("[Ferp-Weed] CheckPlant - strain ID: %s", tostring(plant.metadata.strain)))
    
    -- Get strain name - check if plant has a valid strain ID
    local strainId = plant.metadata.strain
    local strain = nil
    local strainName = nil
    local hasCustomStrain = false -- Only true for custom strains (positive ID)
    
    if strainId and strainId > 0 then
        -- Custom strain created by player - cannot be changed
        strain = Weed.Strains.Get(strainId)
        if strain and strain.name then
            strainName = strain.name
            hasCustomStrain = true
            -- print(string.format("[Ferp-Weed] Found custom strain: %s", strainName))
        else
            -- Strain exists but not loaded on client - use saved name or generate
            strainName = plant.metadata.strain_name or Weed.Strains.GenerateName(plant.metadata.n or 0.5, plant.metadata.p or 0.5, plant.metadata.k or 0.5)
            hasCustomStrain = true
            -- print(string.format("[Ferp-Weed] Strain %d not in cache, using: %s", strainId, strainName))
        end
    elseif strainId and strainId < 0 then
        -- Default strain
        strain = Weed.Strains.GetDefaultById(strainId)
        if strain then
            strainName = strain.name
            -- print(string.format("[Ferp-Weed] Found default strain: %s (can be replaced)", strainName))
        else
            strainName = plant.metadata.strain_name or Lang('plant', 'unknown_strain')
        end
        hasCustomStrain = false -- Default strains can be replaced
    else
        -- No strain yet
        strainName = Lang('plant', 'no_strain')
        -- print(string.format("[Ferp-Weed] No strain assigned"))
    end
    
    -- Build context menu options
    local options = {}
    
    -- Info header
    options[#options + 1] = {
        title = Lang('plant', 'growth_format', growth),
        description = Lang('plant', 'gender_info', plant.metadata.gender == 1 and Lang('plant', 'gender_male') or Lang('plant', 'gender_female')),
        icon = "fa-solid fa-cannabis",
        disabled = true
    }
    
    -- Water option (usar regador com água)
    local hasWateringCan = false
    local wateringCans = exports.ox_inventory:Search('slots', 'wateringcan')
    if wateringCans then
        for _, item in pairs(wateringCans) do
            if item.metadata and item.metadata.water and item.metadata.water > 0 then
                hasWateringCan = true
                break
            end
        end
    end
    
    options[#options + 1] = {
        title = Lang('menu', 'add_water'),
        description = Lang('plant', 'water_info', plant.metadata.water * 100),
        icon = "fa-solid fa-tint",
        disabled = plant.metadata.water >= 1.0 or not hasWateringCan,
        onSelect = function()
            WaterPlant(entity, plant.id)
        end
    }
    
    -- Fertilizer option
    local hasFertilizer = exports.ox_inventory:Search('count', 'fertilizer') > 0
    local alreadyFertilized = plant.metadata.fertilized or false
    
    if not alreadyFertilized and growth < Weed.Plants.Config.HarvestPercent then
        options[#options + 1] = {
            title = Lang('menu', 'add_fertilizer'),
            description = hasFertilizer and Lang('plant', 'fertilizer_info') or Lang('plant', 'fertilizer_required'),
            icon = "fa-solid fa-bolt",
            disabled = not hasFertilizer,
            onSelect = function()
                ApplyFertilizerBoost(entity, plant.id)
            end
        }
    end
    
    -- Strain creation option
    local hasStrainModifier = exports.ox_inventory:Search('count', 'strain_modifier') > 0
    local strainOptions = {}
    
    -- Option to create new strain
    local stage = Weed.Plants.GetStage(growth)
    strainOptions[#strainOptions + 1] = {
        title = Lang('menu', 'create_new_strain'),
        icon = "fa-solid fa-plus",
        disabled = stage >= 3,
        onSelect = function()
            CreateStrainNew(entity, plant)
        end
    }
    
    -- Add existing strains
    for _, s in pairs(Weed.Strains.Created or {}) do
        if s.citizenid == citizenid then
            strainOptions[#strainOptions + 1] = {
                title = s.name,
                icon = "fa-solid fa-dna",
                onSelect = function()
                    ApplyStrain(entity, plant.id, s, false)
                end
            }
        end
    end

    if not hasCustomStrain and hasStrainModifier and stage < 3 then
        options[#options + 1] = {
            title = Lang('menu', 'create_custom_strain'),
            description = strainId and strainId < 0 and Lang('plant', 'replace_strain', strainName) or Lang('plant', 'strain_modifier_required'),
            icon = "fa-solid fa-dna",
            args = { plant = plant },
            menu = 'weed_strain_menu'
        }
    end
    
    -- Make male optional
    local stage = Weed.Plants.GetStage(growth)
    local hasMaleSeed = exports.ox_inventory:Search('count', 'weed_seed_male') > 0
    if stage < 3 and plant.metadata.gender == 0 then
        options[#options + 1] = {
            title = Lang('menu', 'add_male_seed'),
            description = Lang('plant', 'transform_male'),
            icon = "fa-solid fa-mars",
            disabled = not hasMaleSeed,
            onSelect = function()
                MakePlantMale(entity, plant.id)
            end
        }
    end
    
    -- Destroy optional
    local playerJob = Player.job and Player.job.name or ''
    local isPolice = playerJob == 'police' or playerJob == 'sheriff'
    if growth >= 95 or isPolice then
        options[#options + 1] = {
            title = Lang('menu', 'destroy_plant'),
            icon = "fa-solid fa-times",
            iconColor = 'red',
            onSelect = function()
                DestroyPlant(entity, plant.id)
            end
        }
    end
    
    -- Register strain submenu
    lib.registerContext({
        id = 'weed_strain_menu',
        title = Lang('menu', 'choose_strain'),
        menu = 'weed_plant_menu',
        options = strainOptions
    })
    
    -- Show main menu
    lib.registerContext({
        id = 'weed_plant_menu',
        title = Lang('menu', 'cannabis_plant'),
        options = options
    })
    
    lib.showContext('weed_plant_menu')
end
exports('CheckPlant', CheckPlant)


-- Harvest plant
function HarvestPlant(entity, plantId)
    if not DoesEntityExist(entity) then return end
    
    local plant = GetPlantByEntity(entity)
    if not plant then return end
    
    local currentTime = GetCurrentTime()
    local timeSinceHarvest = currentTime - plant.metadata.lastHarvest
    local growth = Weed.Plants.GetGrowth(plant, currentTime)
    
    if growth < Weed.Plants.Config.HarvestPercent or timeSinceHarvest <= (Weed.Plants.Config.TimeBetweenHarvest * 60) then
        return lib.notify({
            title = Lang('menu', 'error'),
            description = Lang('notify', 'not_ready_harvest'),
            type = 'error'
        })
    end
    
    TaskTurnPedToFaceCoord(cache.ped, plant.coords.x, plant.coords.y, plant.coords.z, 3000)
    Wait(500)
    
    local success = ShowProgress({
        duration = 5000,
        label = Lang('progress', 'harvesting'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'anim@gangops@facility@servers@bodysearch@',
            clip = 'player_search'
        }
    })
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:harvestPlant', plant.id)
    end
end
exports('HarvestPlant', HarvestPlant)

-- Water plant
function WaterPlant(entity, plantId)
    if not DoesEntityExist(entity) then return end
    
    TaskTurnPedToFaceEntity(cache.ped, entity, 0)
    Wait(500)
    
    local playerPed = cache.ped
    local waterFx = nil
    local waterActive = true
    
    -- Thread para efeito de água no ped
    CreateThread(function()
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do Wait(0) end
        
        Wait(400)
        
        UseParticleFxAssetNextCall("core")
        waterFx = StartParticleFxLoopedOnPedBone(
            "water_cannon_jet",
            playerPed,
            0.01, -0.0, -0.1,    -- offset frente, lado (direita), cima
            260.0, 0.0, 0.0,    -- rotação para apontar para baixo
            18905,              -- bone (mão direita)
            0.1,               -- escala
            false, false, false
        )
        
        -- Esperar até terminar
        while waterActive do Wait(100) end
        
        if waterFx then
            StopParticleFxLooped(waterFx, false)
        end
        RemoveNamedPtfxAsset("core")
    end)
    
    local success = ShowProgress({
        duration = 4000,
        label = Lang('progress', 'watering'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
            blendIn = 8.0,
            blendOut = -8.0
        },
        prop = {
            model = 'prop_wateringcan',
            bone = 18905,
            pos = vec3(0.08, -0.2, 0.3),
            rot = vec3(-10.0, 80.0, 90.0)
        }
    })
    
    waterActive = false
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:waterPlant', plantId)
        Wait(500)
        CheckPlant(entity)
    end
end
exports('WaterPlant', WaterPlant)

-- Create new strain on plant
function CreateStrainNew(entity, plant)
    if not DoesEntityExist(entity) then return end
    
    -- Check if plant is small enough
    local currentTime = GetCurrentTime()
    local growth = Weed.Plants.GetGrowth(plant, currentTime)
    local stage = Weed.Plants.GetStage(growth)
    
    if stage >= 3 then
        return Weed.Notify(cache.serverId, Lang('notify', 'plant_too_big_strain'), 'error')
    end
    
    -- Verificar se tem o kit de modificação genética
    local strainModifier = exports.ox_inventory:Search('count', 'strain_modifier')
    if not strainModifier or strainModifier < 1 then
        return exports.qbx_core:Notify(Lang('notify', 'need_strain_modifier'), 'error')
    end
    
    local input = lib.inputDialog(Lang('menu', 'create_new_strain'), {
        {type = 'slider', label = Lang('menu', 'nitrogen'), default = 50, min = 1, max = 100, step = 1},
        {type = 'slider', label = Lang('menu', 'phosphorus'), default = 50, min = 1, max = 100, step = 1},
        {type = 'slider', label = Lang('menu', 'potassium'), default = 50, min = 1, max = 100, step = 1},
    })
    
    if not input then return end
    
    local strain = {
        n = input[1] / 100,
        p = input[2] / 100,
        k = input[3] / 100
    }
    
    ApplyStrain(entity, plant.id, strain, true)
end
exports('CreateStrainNew', CreateStrainNew)

-- Apply fertilizer boost (growth speed)
function ApplyFertilizerBoost(entity, plantId)
    if not DoesEntityExist(entity) then return end
    
    TaskTurnPedToFaceEntity(cache.ped, entity, 0)
    Wait(500)
    
    local success = ShowProgress({
        duration = 2000,
        label = Lang('progress', 'applying_fertilizer'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
            blendIn = 8.0,
            blendOut = -8.0
        },
        prop = {
            model = 'prop_wateringcan',
            bone = 18905,
            pos = vec3(0.08, -0.2, 0.3),
            rot = vec3(-10.0, 80.0, 90.0)
        }
    })
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:applyFertilizer', plantId)
        -- Refresh menu
        Wait(500)
        CheckPlant(entity)
    end
end
exports('ApplyFertilizerBoost', ApplyFertilizerBoost)

-- Apply strain to plant
function ApplyStrain(entity, plantId, strain, isNew)
    if not DoesEntityExist(entity) then return end
    
    TaskTurnPedToFaceEntity(cache.ped, entity, 0)
    Wait(500)
    
    local success = ShowProgress({
        duration = 3000,
        label = Lang('progress', 'applying_strain'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'weapon@w_sp_jerrycan',
            clip = 'fire',
            blendIn = 8.0,
            blendOut = -8.0
        },
        prop = {
            model = 'prop_wateringcan',
            bone = 18905,
            pos = vec3(0.08, -0.2, 0.3),
            rot = vec3(-10.0, 80.0, 90.0)
        }
    })
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:createStrain', plantId, strain, isNew)
        -- Refresh menu
        Wait(500)
        CheckPlant(entity)
    end
end
exports('ApplyStrain', ApplyStrain)

-- Alias for backwards compatibility
function ApplyFertilizer(entity, plantId, strain, isNew)
    ApplyStrain(entity, plantId, strain, isNew)
end
exports('ApplyFertilizer', ApplyFertilizer)

-- Make plant male
function MakePlantMale(entity, plantId)
    if not DoesEntityExist(entity) then return end
    
    local success = ShowProgress({
        duration = 3000,
        label = Lang('progress', 'adding_seed'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            scenario = 'WORLD_HUMAN_GARDENER_PLANT'
        }
    })
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:makePlantMale', plantId)
        -- Refresh menu
        Wait(500)
        CheckPlant(entity)
    end
end
exports('MakePlantMale', MakePlantMale)

-- Destroy plant
function DestroyPlant(entity, plantId)
    if not DoesEntityExist(entity) then return end
    
    local success = ShowProgress({
        duration = 3000,
        label = Lang('progress', 'removing'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            scenario = 'WORLD_HUMAN_GARDENER_PLANT'
        }
    })
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:destroyPlant', plantId)
    end
end
exports('DestroyPlant', DestroyPlant)

-- Plant seed (called from ox_inventory item use)
-- ox_inventory export format varies, need to handle multiple cases
function PlantSeed(data, slot)
    -- Debug
    -- print("[Ferp-Weed] ========== PlantSeed ==========")
    -- print("[Ferp-Weed] data type: " .. type(data))
    -- print("[Ferp-Weed] slot: " .. tostring(slot))
    
    -- Try to find the item data - ox_inventory may pass it differently
    local itemData = nil
    local itemSlot = slot
    
    -- Case 1: data is the full item object with metadata
    if type(data) == "table" and data.metadata then
        itemData = data
        -- print("[Ferp-Weed] Case 1: data has metadata directly")
    
    -- Case 2: data has slot info, need to search inventory
    elseif type(data) == "table" and data.slot then
        itemSlot = data.slot
        -- print("[Ferp-Weed] Case 2: data has slot=" .. tostring(itemSlot))
    end
    
    -- If we still don't have itemData, search inventory for weed_seed_female
    if not itemData then
        local items = exports.ox_inventory:Search('slots', 'weed_seed_female')
        if items and #items > 0 then
            -- If we have a specific slot, find that one
            if itemSlot then
                for _, item in ipairs(items) do
                    if item.slot == itemSlot then
                        itemData = item
                        break
                    end
                end
            end
            -- Fallback to first seed found
            if not itemData then
                itemData = items[1]
            end
            -- print(string.format("[Ferp-Weed] Found seed via Search - slot: %s, strain: %s", 
            --     tostring(itemData and itemData.slot), 
            --     tostring(itemData and itemData.metadata and itemData.metadata.strain)))
        end
    end
    
    -- Final debug
    if itemData and itemData.metadata then
        -- print(string.format("[Ferp-Weed] Seed metadata - strain: %s, strain_name: %s, n: %s", 
        --     tostring(itemData.metadata.strain),
        --     tostring(itemData.metadata.strain_name),
        --     tostring(itemData.metadata.n)))
    else
        -- print("[Ferp-Weed] WARNING: No metadata found for seed!")
    end
    -- print("[Ferp-Weed] ================================")
    
    -- Check if player is outside
    if IsPlayerInBuilding() then
        return lib.notify({
            title = Lang('menu', 'error'),
            description = Lang('notify', 'need_outdoor'),
            type = 'error'
        }), false
    end
    
    -- Get first stage model for preview
    local previewModel = Weed.Plants.Config.Objects[1].model
    local zOffset = Weed.Plants.Config.Objects[1].zOffset or -0.6
    
    -- Request model
    lib.requestModel(previewModel, 5000)
    
    -- Create preview object
    local playerCoords = GetEntityCoords(cache.ped)
    local previewObject = CreateObject(previewModel, playerCoords.x, playerCoords.y, playerCoords.z + zOffset, false, false, false)
    SetEntityAlpha(previewObject, 150, false) -- Make it semi-transparent
    SetEntityCollision(previewObject, false, false)
    FreezeEntityPosition(previewObject, true)
    
    local placed = false
    local cancelled = false
    local finalCoords = nil
    local finalHeading = 0.0
    local validPlacement = false
    
    -- Show instructions
    lib.showTextUI(Lang('menu', 'planting_instructions'), {
        position = 'top-center',
        icon = 'cannabis'
    })
    
    -- Preview loop
    CreateThread(function()
        while not placed and not cancelled do
            Wait(0)
            
            -- Raycast to find ground position
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            local endCoords = camCoords + forward * 8.0
            
            local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, cache.ped, 0)
            local _, hit, hitCoords, _, _ = GetShapeTestResult(ray)
            
            if hit == 1 then
                -- Check if surface is valid for planting
                local isValid, errorMsg = IsValidPlantingSurface(hitCoords)
                
                if isValid and not IsPlayerInBuilding() then
                    validPlacement = true
                    SetEntityAlpha(previewObject, 200, false)
                    -- Green tint for valid
                else
                    validPlacement = false
                    SetEntityAlpha(previewObject, 100, false)
                    -- Red tint for invalid
                end
                
                -- Update preview position with zOffset applied
                SetEntityCoords(previewObject, hitCoords.x, hitCoords.y, hitCoords.z + zOffset, false, false, false, false)
                finalCoords = hitCoords 
            end
            
            -- Rotate with scroll
            if IsControlPressed(0, 14) then -- Scroll Up
                finalHeading = finalHeading + 3.0
                SetEntityHeading(previewObject, finalHeading)
            elseif IsControlPressed(0, 15) then -- Scroll Down
                finalHeading = finalHeading - 3.0
                SetEntityHeading(previewObject, finalHeading)
            end
            
            -- Confirm with E
            if IsControlJustPressed(0, 38) then -- E
                if validPlacement and finalCoords then
                    -- Double check surface validity
                    local isValid, errorMsg = IsValidPlantingSurface(finalCoords)
                    if isValid then
                        placed = true
                    else
                        lib.notify({
                            title = Lang('menu', 'error'),
                            description = errorMsg or Lang('notify', 'invalid_location'),
                            type = 'error'
                        })
                    end
                else
                    lib.notify({
                        title = Lang('menu', 'error'),
                        description = Lang('notify', 'invalid_location'),
                        type = 'error'
                    })
                end
            end
            
            -- Cancel with Backspace
            if IsControlJustPressed(0, 177) then -- Backspace
                cancelled = true
            end
        end
    end)
    
    -- Wait for result
    while not placed and not cancelled do
        Wait(100)
    end
    
    -- Hide UI
    lib.hideTextUI()
    
    -- Delete preview object
    if DoesEntityExist(previewObject) then
        DeleteEntity(previewObject)
    end
    SetModelAsNoLongerNeeded(previewModel)
    
    if cancelled then
        return false
    end
    
    -- Get ground modifiers for final position
    local groundMaterial = GetGroundMaterial(finalCoords)
    local materialIndex = Weed.Plants.Config.Materials[groundMaterial] or 2
    local modifiers = {}
    local baseModifiers = Weed.Plants.Config.Modifiers[materialIndex] or Weed.Plants.Config.Modifiers[2]
    
    -- Deep copy modifiers
    for k, v in pairs(baseModifiers) do
        modifiers[k] = v
    end
    
    
    if itemData and itemData.metadata then
        -- Use NPK values from seed if available
        if itemData.metadata.n then modifiers.n = itemData.metadata.n end
        if itemData.metadata.p then modifiers.p = itemData.metadata.p end
        if itemData.metadata.k then modifiers.k = itemData.metadata.k end
        
        -- Use strain ID directly from seed metadataKey
        if itemData.metadata.strain and itemData.metadata.strain ~= 0 then
            modifiers.strain = itemData.metadata.strain
            modifiers.strain_name = itemData.metadata.strain_name
            -- print(string.format("[Ferp-Weed] Using strain ID %d from seed", modifiers.strain))
            
            -- If positive
            if itemData.metadata.strain > 0 then
                local strain = Weed.Strains.Get(itemData.metadata.strain)
                if strain then
                    if not itemData.metadata.n then modifiers.n = strain.n end
                    if not itemData.metadata.p then modifiers.p = strain.p end
                    if not itemData.metadata.k then modifiers.k = strain.k end
                end
            elseif itemData.metadata.strain < 0 then
                -- Default strain, get data from config
                local strain = Weed.Strains.GetDefaultById(itemData.metadata.strain)
                if strain then
                    if not itemData.metadata.n then modifiers.n = strain.n end
                    if not itemData.metadata.p then modifiers.p = strain.p end
                    if not itemData.metadata.k then modifiers.k = strain.k end
                    modifiers.strain_name = strain.name
                end
            end
        end
    end
    
    -- print(string.format("[Ferp-Weed] Planting with modifiers - strain: %s, n: %.2f, p: %.2f, k: %.2f", 
    --     tostring(modifiers.strain), modifiers.n or 0, modifiers.p or 0, modifiers.k or 0))
    
    -- Face the plant location
    TaskTurnPedToFaceCoord(cache.ped, finalCoords.x, finalCoords.y, finalCoords.z, 1000)
    Wait(500)
    
    -- Planting animation
    local success = ShowProgress({
        duration = 5000,
        label = Lang('progress', 'planting'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            scenario = 'WORLD_HUMAN_GARDENER_PLANT'
        }
    })
    
    if success then
        TriggerServerEvent('Ferp-Weed:server:plantSeed', finalCoords, finalHeading, modifiers, slot)
        return true -- Tell ox_inventory to consume the item
    end
    
    return false -- Don't consume item if cancelled
end
exports('PlantSeed', PlantSeed)

-- Helper function to convert rotation to direction vector
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return vector3(direction.x, direction.y, direction.z)
end

--[[
    Events
]]--

-- Spawn plant from server data
RegisterNetEvent('Ferp-Weed:client:spawnPlant', function(data)
    if not data then return end
    
    local plantId = data.id
    local coords = data.coords
    local heading = data.heading or 0.0
    local model = data.model
    
    local plantCoords = type(coords) == 'vector3' and coords or vector3(coords.x, coords.y, coords.z)
    
    -- Store plant data
    PlantData[plantId] = {
        coords = plantCoords,
        heading = heading,
        model = model
    }
    
    -- Add to spatial chunk
    AddToChunk(plantId, plantCoords)
    
    -- Only spawn if player is nearby (let the main loop handle it otherwise)
    local playerCoords = GetCachedPlayerCoords()
    local distance = #(playerCoords - plantCoords)
    local spawnDistance = Config.Performance and Config.Performance.SpawnDistance or 50.0
    
    if distance < spawnDistance and not SpawnedPlants[plantId] then
        local entity = SpawnPlantObject(plantId, coords, heading, model)
        SpawnedPlants[plantId] = entity
        Weed.Debug("Spawned plant %d with entity %d (immediate)", plantId, entity)
    end
end)

-- Remove plant
RegisterNetEvent('Ferp-Weed:client:removePlant', function(plantId)
    if not plantId then return end
    
    -- Remove from chunk
    if PlantData[plantId] then
        RemoveFromChunk(plantId, PlantData[plantId].coords)
    end
    
    -- Remove entity if spawned
    if SpawnedPlants[plantId] then
        if DoesEntityExist(SpawnedPlants[plantId]) then
            DeleteEntity(SpawnedPlants[plantId])
        end
        SpawnedPlants[plantId] = nil
    end
    
    -- Remove data
    PlantData[plantId] = nil
    
    Weed.Debug("Removed plant %d", plantId)
end)

-- Update plant model (growth stage change)
RegisterNetEvent('Ferp-Weed:client:updatePlant', function(plantId, newModel)
    if not plantId or not newModel then return end
    
    -- Update stored data
    if PlantData[plantId] then
        PlantData[plantId].model = newModel
    end
    
    -- Update entity if spawned
    if SpawnedPlants[plantId] and DoesEntityExist(SpawnedPlants[plantId]) then
        local coords = GetEntityCoords(SpawnedPlants[plantId])
        local heading = GetEntityHeading(SpawnedPlants[plantId])
        
        -- Delete old entity
        DeleteEntity(SpawnedPlants[plantId])
        
        -- Spawn new model
        local entity = SpawnPlantObject(plantId, coords, heading, newModel)
        SpawnedPlants[plantId] = entity
        
        Weed.Debug("Updated plant %d to new model", plantId)
    end
end)

-- Batch update plants (optimized for multiple updates)
RegisterNetEvent('Ferp-Weed:client:batchUpdatePlants', function(updates)
    if not updates then return end
    
    for plantId, newModel in pairs(updates) do
        -- Update stored data
        if PlantData[plantId] then
            PlantData[plantId].model = newModel
        end
        
        -- Update entity if spawned
        if SpawnedPlants[plantId] and DoesEntityExist(SpawnedPlants[plantId]) then
            local coords = GetEntityCoords(SpawnedPlants[plantId])
            local heading = GetEntityHeading(SpawnedPlants[plantId])
            
            -- Delete old entity
            DeleteEntity(SpawnedPlants[plantId])
            
            -- Spawn new model
            local entity = SpawnPlantObject(plantId, coords, heading, newModel)
            SpawnedPlants[plantId] = entity
        end
    end
    
    Weed.Debug("Batch updated %d plants", TableCount(updates))
end)

-- Batch remove plants (optimized for cleanup)
RegisterNetEvent('Ferp-Weed:client:batchRemovePlants', function(plantIds)
    if not plantIds then return end
    
    for _, plantId in ipairs(plantIds) do
        -- Remove from chunk
        if PlantData[plantId] then
            RemoveFromChunk(plantId, PlantData[plantId].coords)
        end
        
        -- Remove entity if spawned
        if SpawnedPlants[plantId] then
            if DoesEntityExist(SpawnedPlants[plantId]) then
                DeleteEntity(SpawnedPlants[plantId])
            end
            SpawnedPlants[plantId] = nil
        end
        
        -- Remove data
        PlantData[plantId] = nil
    end
    
    Weed.Debug("Batch removed %d plants", #plantIds)
end)

-- Load existing plants when player joins
RegisterNetEvent('Ferp-Weed:client:loadPlants', function(plants)
    if not plants then return end
    
    -- Clear existing data
    PlantData = {}
    PlantChunks = {}
    
    local count = 0
    for plantId, data in pairs(plants) do
        local coords = type(data.coords) == 'vector3' and data.coords or vector3(data.coords.x, data.coords.y, data.coords.z)
        PlantData[plantId] = {
            coords = coords,
            heading = data.heading or 0.0,
            model = data.model
        }
        -- Add to spatial chunk for fast lookup
        AddToChunk(plantId, coords)
        count = count + 1
    end
    
    Weed.Debug("Loaded %d plant data entries into %d chunks", count, TableCount(PlantChunks))
end)

--[[
    Threads
]]--

-- Spawn/despawn plants based on player proximity (OPTIMIZED with chunks)
CreateThread(function()
    -- Wait for performance config
    while not Config.Performance do
        Wait(100)
    end
    
    local spawnDistance = Config.Performance.SpawnDistance
    local despawnDistance = Config.Performance.DespawnDistance
    local updateInterval = Config.Performance.UpdateInterval
    local batchSize = Config.Performance.BatchSize
    local maxVisible = Config.Performance.MaxVisiblePlants
    
    while true do
        Wait(updateInterval)
        
        local playerCoords = GetCachedPlayerCoords()
        local nearbyChunks = GetNearbyChunks(playerCoords)
        local spawnedCount = TableCount(SpawnedPlants)
        local spawnQueue = {}
        
        -- First pass: collect plants to spawn from nearby chunks only
        for _, chunkKey in ipairs(nearbyChunks) do
            local chunk = PlantChunks[chunkKey]
            if chunk then
                for plantId, _ in pairs(chunk) do
                    local data = PlantData[plantId]
                    if data and not SpawnedPlants[plantId] then
                        local plantCoords = type(data.coords) == 'vector3' and data.coords or vector3(data.coords.x, data.coords.y, data.coords.z)
                        local distance = #(playerCoords - plantCoords)
                        
                        if distance < spawnDistance and spawnedCount < maxVisible then
                            spawnQueue[#spawnQueue + 1] = {
                                id = plantId,
                                data = data,
                                distance = distance
                            }
                        end
                    end
                end
            end
        end
        
        -- Sort by distance (spawn closest first)
        table.sort(spawnQueue, function(a, b) return a.distance < b.distance end)
        
        -- Spawn in batches to prevent freezing
        local spawned = 0
        for i, item in ipairs(spawnQueue) do
            if spawned >= batchSize then break end
            if spawnedCount + spawned >= maxVisible then break end
            
            local entity = SpawnPlantObject(item.id, item.data.coords, item.data.heading, item.data.model)
            SpawnedPlants[item.id] = entity
            spawned = spawned + 1
        end
        
        -- Second pass: despawn far plants
        for plantId, entity in pairs(SpawnedPlants) do
            if DoesEntityExist(entity) then
                local entityCoords = GetEntityCoords(entity)
                local distance = #(playerCoords - entityCoords)
                
                if distance > despawnDistance then
                    DeleteEntity(entity)
                    SpawnedPlants[plantId] = nil
                end
            else
                -- Entity no longer exists, clean up reference
                SpawnedPlants[plantId] = nil
            end
        end
    end
end)

-- Load plants from server on resource start / player login
CreateThread(function()
    -- Wait for config to be ready first
    while not Weed.Plants.ConfigReady do
        Wait(100)
    end
    
    -- Wait for performance config
    while not Config.Performance do
        Wait(100)
    end
    
    -- Wait for player to be logged
    local attempts = 0
    while not LocalPlayer.state.isLoggedIn and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    
    -- Give server time to load plants from DB
    Wait(3000)
    
    -- print('[WEED CLIENT] Requesting plants from server...')
    
    -- Request plants from server
    local plants = lib.callback.await('Ferp-Weed:server:getPlants', false)
    
    if plants then
        local count = 0
        for plantId, data in pairs(plants) do
            local coords = type(data.coords) == 'vector3' and data.coords or vector3(data.coords.x, data.coords.y, data.coords.z)
            PlantData[plantId] = {
                coords = coords,
                heading = data.heading or 0.0,
                model = data.model
            }
            -- Add to spatial chunk
            AddToChunk(plantId, coords)
            count = count + 1
        end
        -- print('[WEED CLIENT] Loaded ' .. count .. ' plants into ' .. TableCount(PlantChunks) .. ' chunks')
        
        -- Force spawn nearby plants immediately
        if count > 0 then
            local playerCoords = GetEntityCoords(cache.ped)
            local spawnDistance = Config.Performance.SpawnDistance
            local maxVisible = Config.Performance.MaxVisiblePlants
            local spawned = 0
            
            -- Only check nearby chunks
            local nearbyChunks = GetNearbyChunks(playerCoords)
            for _, chunkKey in ipairs(nearbyChunks) do
                local chunk = PlantChunks[chunkKey]
                if chunk then
                    for plantId, _ in pairs(chunk) do
                        if spawned >= maxVisible then break end
                        local data = PlantData[plantId]
                        if data then
                            local plantCoords = data.coords
                            local distance = #(playerCoords - plantCoords)
                            if distance < spawnDistance and not SpawnedPlants[plantId] then
                                local entity = SpawnPlantObject(plantId, data.coords, data.heading, data.model)
                                SpawnedPlants[plantId] = entity
                                spawned = spawned + 1
                            end
                        end
                    end
                end
                if spawned >= maxVisible then break end
            end
            -- print('[WEED CLIENT] Spawned ' .. spawned .. ' nearby plants')
        end
    else
        -- print('[WEED CLIENT] No plants received from server')
    end
end)

-- Setup targets when config is ready
CreateThread(function()
    while not Weed.Plants.ConfigReady do
        Wait(100)
    end
    
    local models = {}
    for _, object in ipairs(Weed.Plants.Config.Objects) do
        models[#models + 1] = object.model
    end
    
    -- Add target for all plant models - Check and Harvest
    exports.ox_target:addModel(models, {
        {
            name = 'weed_plants_check',
            label = Lang('target', 'check_plant'),
            icon = 'fa-solid fa-cannabis',
            distance = 1.5,
            onSelect = function(data)
                CheckPlant(data.entity)
            end
        },
        {
            name = 'weed_plants_harvest',
            label = Lang('target', 'harvest_plant'),
            icon = 'fa-solid fa-hand-paper',
            distance = 1.5,
            onSelect = function(data)
                HarvestPlant(data.entity)
            end
        }
    })
    
    Weed.Debug("Plant targets initialized")
end)

-- Get ground material using raycast
function GetGroundMaterial(coords)
    local start = vector3(coords.x, coords.y, coords.z + 1.0)
    local endCoords = vector3(coords.x, coords.y, coords.z - 2.0)
    
    local ray = StartShapeTestRay(start.x, start.y, start.z, endCoords.x, endCoords.y, endCoords.z, 1, PlayerPedId(), 0)
    local _, hit, hitCoords, _, materialHash, _ = GetShapeTestResultIncludingMaterial(ray)
    
    return materialHash, hitCoords.z
end

local BlockedPlantingMaterials = {
    -- Concrete/Cement (verified hashes)
    [1187676648] = "concreto",       -- concrete
    [549634957] = "concreto",        -- concrete_pothole
    [-1286696947] = "concreto",      -- concrete_pavement
    [2034802516] = "concreto",       -- pavement
    
    -- Asphalt/Tarmac/Roads (verified hashes)
    [-1595148316] = "asfalto",       -- tarmac_painted
    [765206029] = "asfalto",         -- tarmac
    [282940568] = "asfalto",         -- road
    [-2041329971] = "asfalto",       -- road_asphalt
    
    -- Metal (verified hashes)
    [-1639062694] = "metal",         -- metal_solid_small
    [-124107068] = "metal",          -- metal
    [1913209870] = "metal",          -- metal_grille
    [-404481737] = "metal",          -- metal_railing
    [-1732672295] = "metal",         -- metal_duct
    [2137197889] = "metal",          -- metal_garage_door
    [-746289813] = "metal",          -- metal_manhole
    
    -- Wood/Interior flooring (verified hashes)
    [555333567] = "madeira",         -- wood_solid_medium
    [-913351839] = "madeira",        -- wood_old_creaky
    [1912906641] = "madeira",        -- wood
    [-1461820571] = "madeira",       -- wood_hollow
    
    -- Tiles/Floor (verified hashes)
    [-1003825117] = "piso",          -- ceramic
    [-1084640111] = "piso",          -- linoleum
    [1084989449] = "carpete",        -- carpet_solid
    [-951663847] = "carpete",        -- carpet_solid_dusty
    [-2022786353] = "piso",          -- plaster_solid
    
    -- Glass/Plastic (verified hashes)  
    [1501078253] = "vidro",          -- glass_shoot_through
    [-1823564879] = "vidro",         -- glass
    [1911117513] = "plástico",       -- plastic
    [-1853927746] = "plástico",      -- plastic_hollow
    
    -- Brick/Stone (man-made - verified hashes)
    [-1147807032] = "tijolo",        -- brick
    [1109728704] = "tijolo",         -- brick_pavement
    [-2073312001] = "pedra",         -- stone
}

function IsValidPlantingSurface(coords)
    local material, groundZ = GetGroundMaterial(coords)
    
    -- Debug: print material hash to console
    -- print(string.format("[WEED DEBUG] Ground material at coords: %d", material))
    
    -- Check if material is blocked
    local blockedType = BlockedPlantingMaterials[material]
    if blockedType then
        return false, "Não é possível plantar em " .. blockedType
    end
    
    -- Everything else is allowed
    return true, nil
end

-- Check if in building
function IsPlayerInBuilding()
    local interior = GetInteriorFromEntity(cache.ped)
    return interior ~= 0
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Delete all spawned plants
    for plantId, entity in pairs(SpawnedPlants) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    
    SpawnedPlants = {}
    PlantData = {}
end)

Weed.Debug("Client plants loaded")
