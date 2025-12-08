local QBX = exports.qbx_core

-- ============================================
-- PACKAGING NPCs SYSTEM (Sul e Norte)
-- ============================================
local packagingNPCLocations = {
    Sul = nil,
    Norte = nil
}

-- Initialize random locations on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local config = Weed.Items.Config.PackagingNPCs
        
        if config.Sul and config.Sul.Locations then
            local locations = config.Sul.Locations
            packagingNPCLocations.Sul = locations[math.random(#locations)]
            Weed.Debug("Packaging NPC Sul spawn: %s", packagingNPCLocations.Sul.name)
        end
        
        if config.Norte and config.Norte.Locations then
            local locations = config.Norte.Locations
            packagingNPCLocations.Norte = locations[math.random(#locations)]
            Weed.Debug("Packaging NPC Norte spawn: %s", packagingNPCLocations.Norte.name)
        end
    end
end)

-- Callback to get NPC locations
lib.callback.register('Ferp-Weed:server:getPackagingNPCLocations', function(source)
    return packagingNPCLocations
end)

-- Get strain helper
local function getStrain(strainId)
    if strainId and strainId > 0 then
        return Weed.Strains.Get(strainId)
    elseif strainId and strainId < 0 then
        return Weed.Strains.GetDefaultById(strainId)
    end
    return nil
end

-- Process packaging (from NPC - faz bricks de todas as strains automaticamente)
RegisterNetEvent('Ferp-Weed:server:processPackaging', function(processType)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    if processType == 'buds_to_brick' then
        local budsNeeded = Weed.Items.Config.BudsPerBrick or 5
        
        -- Get buds from inventory
        local buds = exports.ox_inventory:Search(src, 'slots', 'weed_bud')
        if not buds or #buds == 0 then
            return Weed.Notify(src, Lang('notify', 'no_buds'), 'error')
        end
        
        -- Agrupar buds por strain
        local strainGroups = {}
        
        for _, bud in ipairs(buds) do
            local strainId = bud.metadata and bud.metadata.strain or 0
            local key = tostring(strainId)
            
            if not strainGroups[key] then
                strainGroups[key] = {
                    strainId = strainId,
                    strainName = bud.metadata and bud.metadata.strain_name or "Desconhecida",
                    quality = bud.metadata and bud.metadata.quality or 50,
                    count = 0,
                    slots = {}
                }
            end
            
            strainGroups[key].count = strainGroups[key].count + bud.count
            table.insert(strainGroups[key].slots, { slot = bud.slot, count = bud.count })
        end
        
        -- Processar cada strain
        local totalBricks = 0
        local strainsSummary = {}
        
        for _, group in pairs(strainGroups) do
            local bricksToMake = math.floor(group.count / budsNeeded)
            
            if bricksToMake > 0 then
                local budsToRemove = bricksToMake * budsNeeded
                
                -- Remover buds dos slots dessa strain
                local toRemove = budsToRemove
                for _, slotInfo in ipairs(group.slots) do
                    if toRemove <= 0 then break end
                    
                    local removeAmount = math.min(toRemove, slotInfo.count)
                    exports.ox_inventory:RemoveItem(src, 'weed_bud', removeAmount, nil, slotInfo.slot)
                    toRemove = toRemove - removeAmount
                end
                
                -- Criar bricks dessa strain
                local strain = getStrain(group.strainId)
                local metadata = Weed.Items.CreateMetadata('weed_brick', strain, group.quality)
                
                Weed.AddItem(src, 'weed_brick', bricksToMake, metadata)
                
                totalBricks = totalBricks + bricksToMake
                table.insert(strainsSummary, string.format('%dx %s', bricksToMake, group.strainName))
            end
        end
        
        if totalBricks > 0 then
            local summary = table.concat(strainsSummary, ', ')
            Weed.Notify(src, string.format('Criou %d brick(s): %s', totalBricks, summary), 'success')
        else
            Weed.Notify(src, Lang('notify', 'need_buds_strain', budsNeeded), 'error')
        end
    end
end)

-- Use brick from inventory (precisa de balança + saquinhos vazios)
RegisterNetEvent('Ferp-Weed:server:useBrick', function(brickSlot)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    local baggiesNeeded = Weed.Items.Config.BaggiesPerBrick or 10
    
    -- Check for brick
    local brick = exports.ox_inventory:GetSlot(src, brickSlot)
    if not brick or brick.name ~= 'weed_brick' then
        return Weed.Notify(src, Lang('notify', 'brick_not_found'), 'error')
    end
    
    -- Check for scale
    local scales = exports.ox_inventory:Search(src, 'slots', 'weed_scale')
    if not scales or #scales == 0 then
        return Weed.Notify(src, Lang('notify', 'need_scale_item'), 'error')
    end
    
    local scale = scales[1]
    local scaleDurability = scale.metadata and scale.metadata.durability or 100
    
    -- Check for empty baggies
    local emptyBaggies = exports.ox_inventory:Search(src, 'count', 'empty_baggie')
    if emptyBaggies < baggiesNeeded then
        return Weed.Notify(src, Lang('notify', 'need_empty_baggies', baggiesNeeded), 'error')
    end
    
    local strain = getStrain(brick.metadata and brick.metadata.strain)
    local quality = brick.metadata and brick.metadata.quality or 50
    
    -- Remove brick
    if not exports.ox_inventory:RemoveItem(src, 'weed_brick', 1, nil, brickSlot) then
        return Weed.Notify(src, Lang('notify', 'process_error'), 'error')
    end
    
    -- Remove empty baggies
    if not exports.ox_inventory:RemoveItem(src, 'empty_baggie', baggiesNeeded) then
        -- Give brick back
        Weed.AddItem(src, 'weed_brick', 1, brick.metadata)
        return Weed.Notify(src, Lang('notify', 'process_error'), 'error')
    end
    
    -- Reduce scale durability (10% per use)
    local durabilityLoss = Weed.Items.Config.ScaleDurabilityLoss or 10
    local newDurability = scaleDurability - durabilityLoss
    
    if newDurability <= 0 then
        -- Remove broken scale
        exports.ox_inventory:RemoveItem(src, 'weed_scale', 1, nil, scale.slot)
        Weed.Notify(src, Lang('notify', 'scale_broke'), 'error')
    else
        -- Update scale durability
        exports.ox_inventory:SetMetadata(src, scale.slot, { durability = newDurability })
    end
    
    -- Create baggies
    local metadata = Weed.Items.CreateMetadata('weed_baggie', strain, quality)
    Weed.AddItem(src, 'weed_baggie', baggiesNeeded, metadata)
    Weed.Notify(src, Lang('notify', 'divided_brick', baggiesNeeded), 'success')
end)

-- Use baggie from inventory (precisa de papel)
RegisterNetEvent('Ferp-Weed:server:useBaggie', function(baggieSlot)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    -- Check for baggie
    local baggie = exports.ox_inventory:GetSlot(src, baggieSlot)
    if not baggie or baggie.name ~= 'weed_baggie' then
        return Weed.Notify(src, Lang('notify', 'baggie_slot_not_found'), 'error')
    end
    
    -- Check for rolling paper
    local papers = exports.ox_inventory:Search(src, 'count', 'rolling_paper')
    if papers < 1 then
        return Weed.Notify(src, Lang('notify', 'need_rolling_paper'), 'error')
    end
    
    local strain = getStrain(baggie.metadata and baggie.metadata.strain)
    local quality = baggie.metadata and baggie.metadata.quality or 50
    
    -- Remove baggie
    if not exports.ox_inventory:RemoveItem(src, 'weed_baggie', 1, nil, baggieSlot) then
        return Weed.Notify(src, Lang('notify', 'process_error'), 'error')
    end
    
    -- Remove paper (same amount as joints)
    local jointCount = Weed.Items.Config.JointsPerBaggie
    if not exports.ox_inventory:RemoveItem(src, 'rolling_paper', jointCount) then
        -- Give baggie back
        Weed.AddItem(src, 'weed_baggie', 1, baggie.metadata)
        return Weed.Notify(src, Lang('notify', 'need_rolling_paper', jointCount), 'error')
    end
    
    -- Create joints (fixed amount)
    local metadata = Weed.Items.CreateMetadata('joint', strain, quality)
    
    Weed.AddItem(src, 'joint', jointCount, metadata)
    Weed.Notify(src, Lang('notify', 'rolled_joints', jointCount), 'success')
end)

-- ============================================
-- OX_INVENTORY EXPORTS (item use)
-- ============================================

-- Export: Use weed_bud
exports('useWeedBud', function(event, item, inventory, slot, data)
    local src = inventory.id
    Weed.Notify(src, Lang('notify', 'find_packager'), 'info')
    return false -- não consome o item
end)

-- Export: Use weed_brick
exports('useWeedBrick', function(event, item, inventory, slot, data)
    local src = inventory.id
    TriggerClientEvent('Ferp-Weed:client:useBrick', src, slot)
    return false 
end)

-- Export: Use weed_baggie
exports('useWeedBaggie', function(event, item, inventory, slot, data)
    local src = inventory.id
    TriggerClientEvent('Ferp-Weed:client:useBaggie', src, slot)
    return false 
end)

-- Export: Use joint
exports('useJoint', function(event, item, inventory, slot, data)
    local src = inventory.id
    
    local quality = item.metadata and item.metadata.quality or 50
    TriggerClientEvent('Ferp-Weed:client:smokeJoint', src, quality, slot)
    
    return false
end)

-- Export: Use watering can
exports('useWateringCan', function(event, item, inventory, slot, data)
    local src = inventory.id
    local waterLevel = item.metadata and item.metadata.water or 0
    
    TriggerClientEvent('Ferp-Weed:client:useWateringCan', src, slot, item.metadata)
    
    return false
end)

-- Encher regador com água
RegisterNetEvent('Ferp-Weed:server:fillWateringCan', function(slot)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    -- Verificar se tem regador no slot
    local item = exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= 'wateringcan' then
        return Weed.Notify(src, Lang('items', 'watering_can_not_found'), 'error')
    end
    
    -- Atualizar metadata com água cheia
    local newMetadata = item.metadata or {}
    newMetadata.water = 100
    newMetadata.description = Lang('items', 'watering_can_full_desc')
    
    -- Atualizar item
    exports.ox_inventory:SetMetadata(src, slot, newMetadata)
    
    Weed.Notify(src, Lang('items', 'watering_can_filled'), 'success')
    Weed.Debug("Player %s filled watering can", Player.PlayerData.citizenid)
end)

-- ============================================
-- EXPORTS FOR OTHER SCRIPTS (Evidence System)
-- ============================================

-- Set red eyes evidence on a player
-- Usage: exports.Ferp-Weed:SetRedEyes(playerId, duration)
-- duration in seconds (optional, defaults to config)
exports('SetRedEyes', function(playerId, duration)
    local dur = duration or Weed.Items.Config.RedEyesDuration
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'redeyes', dur)
    return true
end)

-- Set weed smell evidence on a player
-- Usage: exports.Ferp-Weed:SetWeedSmell(playerId, duration)
-- duration in seconds (optional, defaults to config)
exports('SetWeedSmell', function(playerId, duration)
    local dur = duration or Weed.Items.Config.WeedSmellDuration
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'weedsmell', dur)
    return true
end)

-- Set both red eyes and weed smell
-- Usage: exports.Ferp-Weed:SetWeedEvidence(playerId, eyesDuration, smellDuration)
exports('SetWeedEvidence', function(playerId, eyesDuration, smellDuration)
    local eyesDur = eyesDuration or Weed.Items.Config.RedEyesDuration
    local smellDur = smellDuration or Weed.Items.Config.WeedSmellDuration
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'redeyes', eyesDur)
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'weedsmell', smellDur)
    return true
end)

-- Clear weed evidence from a player
-- Usage: exports.Ferp-Weed:ClearWeedEvidence(playerId)
exports('ClearWeedEvidence', function(playerId)
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'redeyes', 0)
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'weedsmell', 0)
    return true
end)

-- Get joint buff values (for other scripts to use same values)
-- Usage: local buffs = exports.Ferp-Weed:GetJointBuffs()
exports('GetJointBuffs', function()
    return {
        duration = Weed.Items.Config.JointDuration,
        armorPerTick = Weed.Items.Config.ArmorPerTick,
        stressReduction = Weed.Items.Config.StressReduction,
        maxStressReduction = Weed.Items.Config.MaxStressReduction,
        redEyesDuration = Weed.Items.Config.RedEyesDuration,
        weedSmellDuration = Weed.Items.Config.WeedSmellDuration
    }
end)

-- Apply joint buffs to a player (armor + stress reduction)
-- Usage: exports.Ferp-Weed:ApplyJointBuffs(playerId, quality)
-- quality = 1-100 (affects buff strength)
exports('ApplyJointBuffs', function(playerId, quality)
    local q = quality or 50
    local effectiveness = q / 100
    
    -- Set evidence
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'redeyes', Weed.Items.Config.RedEyesDuration)
    TriggerClientEvent('evidence:client:SetStatus', playerId, 'weedsmell', Weed.Items.Config.WeedSmellDuration)
    
    -- Apply buffs via client
    TriggerClientEvent('Ferp-Weed:client:applyJointBuffs', playerId, effectiveness)
    
    return true
end)

Weed.Debug("Server items loaded")