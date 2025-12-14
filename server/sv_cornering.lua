local QBX = exports.qbx_core

-- Active cornering sessions
local corneringSessions = {}
local corneringZones = {}
local processingBaggies = {}
local processingSales = {}

-- Start cornering
lib.callback.register('Ferp-Weed:server:startCornering', function(source, coords, zone)
    local Player = QBX:GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if someone is already selling in this zone
    for cid, activeZone in pairs(corneringZones) do
        if activeZone == zone then
            return false
        end
    end
    
    -- Start session
    corneringSessions[source] = {
        citizenid = citizenid,
        zone = zone,
        coords = coords,
        startTime = os.time()
    }
    
    corneringZones[citizenid] = zone
    
    Weed.Debug("Player %s started cornering in %s", citizenid, zone)
    return true
end)

-- Stop cornering
RegisterNetEvent('Ferp-Weed:server:stopCornering', function()
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    corneringSessions[src] = nil
    corneringZones[citizenid] = nil
    
    Weed.Debug("Player %s stopped cornering", citizenid)
end)

-- Send customer to player
RegisterNetEvent('Ferp-Weed:server:sendCustomer', function(coords, pedNetId)
    local src = source
    
    if not corneringSessions[src] then return end
    
    -- Trigger client to make ped walk to player
    TriggerClientEvent('Ferp-Weed:client:customerApproach', src, pedNetId, coords)
end)

-- Customer handoff animation
RegisterNetEvent('Ferp-Weed:server:customerHandoff', function(pedNetId)
    local src = source
    
    -- Get ped owner
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    if ped == 0 then return end
    
    local owner = NetworkGetEntityOwner(ped)
    if owner == 0 then return end
    
    -- Trigger animation on owner's client
    TriggerClientEvent('Ferp-Weed:client:customerHandoff', owner, pedNetId)
end)

-- Prepare baggies
RegisterNetEvent('Ferp-Weed:server:prepareBaggies', function()
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    if processingBaggies[src] then
        return Weed.Notify(src, Lang('notify', 'already_preparing'), 'error')
    end
    
    processingBaggies[src] = true
    
    local citizenid = Player.PlayerData.citizenid
    local budsNeeded = Weed.Cornering.Config.BudsPerPrepare
    local baggiesNeeded = Weed.Cornering.Config.BaggiesPerBud * budsNeeded
    
    -- Get all weed_bud items
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    local buds = {}
    
    for slot, item in pairs(inventory) do
        if item.name == 'weed_bud' then
            table.insert(buds, {slot = slot, data = item})
            if #buds >= budsNeeded then break end
        end
    end
    
    if #buds < budsNeeded then
        processingBaggies[src] = nil
        return Weed.Notify(src, Lang('notify', 'need_buds', budsNeeded), 'error')
    end
    
    if not Weed.HasItem(src, 'empty_baggie', baggiesNeeded) then
        processingBaggies[src] = nil
        return Weed.Notify(src, Lang('notify', 'need_empty_baggies', baggiesNeeded), 'error')
    end
    
    -- Process buds
    for i = 1, budsNeeded do
        local bud = buds[i]
        
        -- Remove bud
        if Weed.RemoveItem(src, 'weed_bud', 1, nil, bud.slot) then
            -- Remove baggies
            Weed.RemoveItem(src, 'empty_baggie', Weed.Cornering.Config.BaggiesPerBud)
            
            -- Add weed baggies
            local metadata = Weed.Items.CreateMetadata('weed_baggie',
                Weed.Strains.Get(bud.data.metadata.strain),
                bud.data.metadata.quality
            )
            
            Weed.AddItem(src, 'weed_baggie', Weed.Cornering.Config.BaggiesPerBud, metadata)
        end
        
        Wait(100)
    end
    
    processingBaggies[src] = nil
    
    Weed.Notify(src, Lang('notify', 'baggies_prepared'), 'success')
    Weed.Debug("Player %s prepared baggies", citizenid)
end)

-- Sell baggie to customer
RegisterNetEvent('Ferp-Weed:server:sellBaggie', function(pedNetId, zone, moneyMult, quantity)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    if processingSales[src] then return end
    processingSales[src] = true
    
    -- Valores padrão
    moneyMult = moneyMult or 1.0
    quantity = quantity or 1
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get inventory
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    local baggies = {}
    
    for slot, item in pairs(inventory) do
        if item.name == 'weed_baggie' then
            table.insert(baggies, {slot = slot, data = item})
        end
    end
    
    if #baggies == 0 then
        processingSales[src] = nil
        return Weed.Notify(src, Lang('notify', 'no_baggies'), 'error')
    end
    
    -- Verificar se tem quantidade suficiente
    if #baggies < quantity then
        quantity = #baggies
    end
    
    local totalEarned = 0
    
    for i = 1, quantity do
        local baggie = baggies[i]
        
        -- Remove baggie
        if Weed.RemoveItem(src, 'weed_baggie', 1, nil, baggie.slot) then
            -- Calculate price
            local quality = baggie.data.metadata.quality or 50
            local strain = Weed.Strains.Get(baggie.data.metadata.strain)
            local strainRep = strain and strain.reputation or 0
            
            local price = Weed.Cornering.CalculatePrice(quality, strainRep)
            
            -- Aplicar multiplicador do evento
            price = math.floor(price * moneyMult)
            totalEarned = totalEarned + price
            
            -- Update reputations
            if quality > 50 then
                Weed.Dealers.UpdateReputation(citizenid, 1)
                if strain then
                    Weed.Strains.UpdateReputation(strain.id, 1)
                end
            elseif quality < 50 then
                Weed.Dealers.UpdateReputation(citizenid, -1)
                if strain then
                    Weed.Strains.UpdateReputation(strain.id, -1)
                end
            end
        end
        
        Wait(50)
    end
    
    if totalEarned > 0 then
        -- Payout controlled by config: 'dirty' or 'clean'
        local payoutType = 'dirty'
        local dirtyItem = 'black_money'
        local cleanItem = 'money'
        if Weed and Weed.Cornering and Weed.Cornering.Config and Weed.Cornering.Config.Payout then
            payoutType = Weed.Cornering.Config.Payout.Type or payoutType
            dirtyItem = (Weed.Cornering.Config.Payout.Items and Weed.Cornering.Config.Payout.Items.dirty) or dirtyItem
            cleanItem = (Weed.Cornering.Config.Payout.Items and Weed.Cornering.Config.Payout.Items.clean) or cleanItem
        end

        if payoutType == 'dirty' then
            if exports.ox_inventory:CanCarryItem(src, dirtyItem, totalEarned) then
                Weed.AddItem(src, dirtyItem, totalEarned)
            else
                -- Fallback:
                if cleanItem and exports.ox_inventory and exports.ox_inventory:CanCarryItem(src, cleanItem, totalEarned) then
                    Weed.AddItem(src, cleanItem, totalEarned)
                else
                    Player.Functions.AddMoney('cash', totalEarned)
                end
            end
        else
            -- payoutType == 'clean'
            if cleanItem and exports.ox_inventory and exports.ox_inventory:CanCarryItem(src, cleanItem, totalEarned) then
                Weed.AddItem(src, cleanItem, totalEarned)
            else
                Player.Functions.AddMoney('cash', totalEarned)
            end
        end
        
        -- Mensagem diferente baseada no multiplicador
        local msg
        if moneyMult > 1.0 then
            msg = Lang('notify', 'sold_baggies_tip', quantity, totalEarned)
        elseif moneyMult < 1.0 then
            msg = Lang('notify', 'sold_baggies_reduced', quantity, totalEarned)
        else
            msg = Lang('notify', 'sold_baggies_normal', quantity, totalEarned)
        end
        
        Weed.Notify(src, msg, 'success')
    end
    
    processingSales[src] = nil
    
    Weed.Debug("Player %s sold %d baggies for $%d (mult: %.1f)", citizenid, quantity, totalEarned, moneyMult)
end)

-- Create evidence
RegisterNetEvent('Ferp-Weed:server:createEvidence', function(data)
    local src = source
    
    -- Trigger evidence system if available
    if GetResourceState('evidence') == 'started' then
        TriggerEvent('evidence:server:CreateEvidence', src, 'weed', data)
    end
end)

-- Clean up on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBX:GetPlayer(src)
    
    if Player then
        local citizenid = Player.PlayerData.citizenid
        
        corneringSessions[src] = nil
        corneringZones[citizenid] = nil
        processingBaggies[src] = nil
        processingSales[src] = nil
    end
end)

Weed.Debug("Server cornering loaded")