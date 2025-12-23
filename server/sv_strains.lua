local QBX = exports.qbx_core

-- NPC Location (random per restart)
local currentNPCLocation = nil

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local locations = Weed.Strains.Config.NPCLocations
        if locations and #locations > 0 then
            currentNPCLocation = locations[math.random(#locations)]
            Weed.Debug("NPC spawn location: %s", currentNPCLocation.name)
        end
    end
end)

-- Callback para cliente obter localização do NPC
lib.callback.register('Ferp-Weed:server:getNPCLocation', function(source)
    return currentNPCLocation
end)

-- Create new strain
function Weed.Strains.Create(citizenid, strainData)
    -- Check if player already has max strains
    local existingStrains = MySQL.query.await([[
        SELECT COUNT(*) as count 
        FROM weed_strains 
        WHERE citizenid = ?
    ]], {citizenid})
    
    if existingStrains and existingStrains[1].count >= Weed.Strains.Config.MaxStrainsPerPlayer then
        return false
    end
    
    -- Generate name first
    local name = Weed.Strains.GenerateName(strainData.n, strainData.p, strainData.k)
    
    -- Insert new strain with name
    local insertId = MySQL.insert.await([[
        INSERT INTO weed_strains (citizenid, name, strain, reputation, xp, level, perks, unlocked, indoor_unlocked, indoor_upgrades, renamed)
        VALUES (?, ?, ?, 0, 0, 1, ?, ?, 0, ?, 0)
    ]], {
        citizenid,
        name,
        json.encode({
            n = strainData.n,
            p = strainData.p,
            k = strainData.k
        }),
        json.encode({}),
        json.encode({}),
        json.encode({})
    })
    
    if not insertId then return false end
    
    -- Add to active strains
    Weed.Strains.Created[insertId] = {
        id = insertId,
        citizenid = citizenid,
        name = name,
        reputation = 0,
        xp = 0,
        level = 1,
        perks = {},
        unlocked = {},
        indoor_unlocked = false,
        indoor_upgrades = {},
        n = strainData.n,
        p = strainData.p,
        k = strainData.k,
        rank = 0,
        renamed = false
    }
    
    -- Update rankings
    UpdateStrainRankings()
    
    -- Broadcast to all clients
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
    
    Weed.Debug("Strain %d created by %s", insertId, citizenid)
    return true
end

-- Update strain reputation
function Weed.Strains.UpdateReputation(strainId, value)
    if not Weed.Strains.Created[strainId] then return false end
    
    -- Update in memory
    Weed.Strains.Created[strainId].reputation = Weed.Strains.Created[strainId].reputation + value
    
    -- Update database
    MySQL.update([[
        UPDATE weed_strains
        SET reputation = reputation + ?
        WHERE id = ?
    ]], {value, strainId})
    
    -- Update rankings
    UpdateStrainRankings()
    
    Weed.Debug("Strain %d reputation updated by %d", strainId, value)
    return true
end

-- Add XP to Strain
function Weed.Strains.AddXP(strainId, amount)
    local strain = Weed.Strains.Created[strainId]
    if not strain then return false end
    
    -- Checks if max level
    local maxLevel = 10 -- Hardcoded max for safety, though defined in config
    if strain.level >= maxLevel then return false end
    
    strain.xp = strain.xp + amount
    local newLevel = Weed.Perks.GetLevelFromXP(strain.xp)
    
    local leveledUp = false
    if newLevel > strain.level then
        strain.level = newLevel
        leveledUp = true
        -- Find owner and notify
        local Player = QBX:GetPlayerByCitizenId(strain.citizenid)
        if Player then
            -- Use Laptop Notification for Level Up
             TriggerClientEvent('Ferp-Weed:client:laptopNotify', Player.PlayerData.source, 'Lab', Lang('notify', 'strain_level_up', strain.name, newLevel), 'success')
        end
    end
    
    -- Update DB
    MySQL.update('UPDATE weed_strains SET xp = ?, level = ? WHERE id = ?', {strain.xp, strain.level, strainId})
    
    if leveledUp then
        TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
    end
    
    Weed.Debug("Strain %d gained %d XP (Total: %d, Lvl: %d)", strainId, amount, strain.xp, strain.level)
    return true
end

-- Unlock/Upgrade Perk
RegisterNetEvent('Ferp-Weed:server:unlockPerk', function(strainId, perkId, type)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local strain = Weed.Strains.Created[strainId]
    if not strain then return end
    
    if strain.citizenid ~= Player.PlayerData.citizenid then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'not_strain_owner'), 'error')
    end
    
    type = type or 'perk'

    if type == 'perk' then
        local perkDef = Weed.Perks.List[perkId]
        if not perkDef then return end
        
        -- Check required level
        if perkDef.reqLevel and strain.level < perkDef.reqLevel then
            return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'strain_level_too_low'), 'error')
        end
        
        -- Check points
        local currentPointsUsed = 0
        for pid, level in pairs(strain.perks) do
            local pDef = Weed.Perks.List[pid]
            if pDef then
                currentPointsUsed = currentPointsUsed + (level * pDef.cost)
            end
        end
        
        local totalPoints = Weed.Perks.GetPointsTotal(strain.level)
        local pointsAvailable = totalPoints - currentPointsUsed
        
        if pointsAvailable < perkDef.cost then
            return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'not_enough_points'), 'error')
        end
        
        -- Check max level for perk
        local currentPerkLevel = strain.perks[perkId] or 0
        if currentPerkLevel >= perkDef.maxLevel then
            return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'perk_maxed'), 'error')
        end
        
        -- Upgrade
        strain.perks[perkId] = currentPerkLevel + 1
        TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'perk_unlocked'), 'success')

    elseif type == 'indoor_unlock' then
        strain.indoor_unlocked = true
        TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Indoor System', 'Indoor Unlocked!', 'success')

    elseif type == 'indoor_upgrade' then
        if not strain.indoor_upgrades then strain.indoor_upgrades = {} end
        table.insert(strain.indoor_upgrades, perkId)
        TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Indoor System', 'Upgrade Installed!', 'success')

    elseif type == 'mastery' then
        if not strain.unlocked then strain.unlocked = {} end
        table.insert(strain.unlocked, perkId)
        TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Mastery', 'Mastery Unlocked!', 'success')
    end
    
    -- Save (Comprehensive Update)
    MySQL.update('UPDATE weed_strains SET perks = ?, unlocked = ?, indoor_unlocked = ?, indoor_upgrades = ? WHERE id = ?', {
        json.encode(strain.perks or {}),
        json.encode(strain.unlocked or {}),
        strain.indoor_unlocked and 1 or 0,
        json.encode(strain.indoor_upgrades or {}),
        strainId
    })
    
    -- Update clients
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
end)

-- Update strain rankings
function UpdateStrainRankings()
    local ranking = {}
    
    -- Sort by reputation
    for id, strain in pairs(Weed.Strains.Created) do
        table.insert(ranking, strain)
    end
    
    table.sort(ranking, function(a, b)
        return a.reputation > b.reputation
    end)
    
    -- Assign ranks
    for rank, strain in ipairs(ranking) do
        Weed.Strains.Created[strain.id].rank = rank
    end
    
    -- Broadcast to all clients
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
end

-- Rename strain
RegisterNetEvent('Ferp-Weed:server:renameStrain', function(strainId, newName)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    local strain = Weed.Strains.Get(strainId)
    if not strain then
        return Weed.Notify(src, Lang('notify', 'strain_not_found'), 'error')
    end
    
    -- Check ownership
    if strain.citizenid ~= Player.PlayerData.citizenid then
        return Weed.Notify(src, Lang('notify', 'not_your_strain'), 'error')
    end
    
    -- Check if already renamed
    if strain.renamed then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'already_renamed'), 'error')
    end
    
    -- Check level requirement (Level 5+)
    if strain.level < 5 then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'insufficient_level_rename'), 'error')
    end
    
    -- Validate name
    if #newName < 5 or #newName > 50 then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'invalid_name'), 'error')
    end
    
    -- Update database
    local success, updated = pcall(MySQL.update.await, [[
        UPDATE weed_strains
        SET name = ?, renamed = 1
        WHERE id = ?
    ]], {newName, strain.id})
    
    if not success or not updated or updated == 0 then
        -- Fallback: If 'renamed' column is missing, try updating without it
        if not success then
             pcall(MySQL.update.await, 'UPDATE weed_strains SET name = ? WHERE id = ?', {newName, strain.id})
        else
             return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'rename_error'), 'error')
        end
    end
    
    -- Update in memory
    strain.name = newName
    strain.renamed = true
    
    -- Broadcast to all clients
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
    
    TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'strain_renamed'), 'success')
    Weed.Debug("Strain %d renamed to %s", strainId, newName)
end)

-- Delete strain
RegisterNetEvent('Ferp-Weed:server:deleteStrain', function(strainId)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    local strain = Weed.Strains.Created[strainId]
    if not strain then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'strain_not_found'), 'error')
    end
    
    -- Check ownership
    if strain.citizenid ~= Player.PlayerData.citizenid then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'not_your_strain'), 'error')
    end
    
    -- Check reputation level
    local reputation = Weed.Strains.GetReputation(strain)
    if not reputation.canChangeName then
        return TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'reputation_too_high'), 'error')
    end
    
    -- Delete from database
    MySQL.update('DELETE FROM weed_strains WHERE id = ?', {strainId})
    
    -- Remove from memory
    Weed.Strains.Created[strainId] = nil
    
    -- Update rankings
    UpdateStrainRankings()
    
    -- Broadcast to all clients
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
    
    TriggerClientEvent('Ferp-Weed:client:laptopNotify', src, 'Lab', Lang('notify', 'strain_deleted'), 'success')
    Weed.Debug("Strain %d deleted", strainId)
end)

-- Open weed shop (using ox_inventory shop)
RegisterNetEvent('Ferp-Weed:server:openShop', function()
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Open ox_inventory shop - send to client
    TriggerClientEvent('Ferp-Weed:client:openShop', src)
end)

-- Load strains from database on startup
CreateThread(function()
    Wait(2000)
    
    local strains = MySQL.query.await([[
        SELECT *
        FROM weed_strains
        ORDER BY reputation DESC
    ]])
    
    if strains then
        for rank, strainData in ipairs(strains) do
            local strain = json.decode(strainData.strain)
            
            -- Generate name if missing and save it
            local name = strainData.name
            if not name or name == '' then
                name = Weed.Strains.GenerateName(strain.n, strain.p, strain.k)
                -- Save generated name to database
                MySQL.update('UPDATE weed_strains SET name = ? WHERE id = ?', {name, strainData.id})
            end
            
            Weed.Strains.Created[strainData.id] = {
                id = strainData.id,
                citizenid = strainData.citizenid,
                name = name,
                reputation = strainData.reputation or 0,
                xp = strainData.xp or 0,
                level = strainData.level or 1,
                perks = strainData.perks and json.decode(strainData.perks) or {},
                unlocked = strainData.unlocked and json.decode(strainData.unlocked) or {},
                indoor_unlocked = strainData.indoor_unlocked == 1,
                indoor_upgrades = strainData.indoor_upgrades and json.decode(strainData.indoor_upgrades) or {},
                n = strain.n,
                p = strain.p,
                k = strain.k,
                rank = rank,
                renamed = strainData.renamed == 1
            }
        end
        
        Weed.Debug("Loaded %d strains from database", #strains)
    end
    
    -- Broadcast to all online players
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
end)

-- Periodic strain updates
CreateThread(function()
    while true do
        Wait(Weed.Strains.Config.UpdateTimer)
        
        -- Update rankings
        UpdateStrainRankings()
        
        -- Broadcast to all clients
        TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
        
        Weed.Debug("Strain rankings updated")
    end
end)

Weed.Debug("Server strains loaded")