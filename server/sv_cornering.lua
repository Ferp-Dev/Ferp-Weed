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
    
    -- Defaults and Capping
    moneyMult = moneyMult or 1.0
    quantity = quantity or 1
    if quantity > 5 then quantity = 5 end -- Safety Cap
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get all baggies in inventory
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    local baggies = {}
    
    for slot, item in pairs(inventory) do
        if item.name == 'weed_baggie' then
            table.insert(baggies, item) -- Store entire item object
        end
    end
    
    if #baggies == 0 then
        processingSales[src] = nil
        return Weed.Notify(src, Lang('notify', 'no_baggies'), 'error')
    end
    
    local totalEarned = 0
    local remainingToSell = quantity
    local soldCount = 0
    
    Weed.Debug("[SELL] Request: %d items | Mult: %.2f", quantity, moneyMult)
    
    for _, baggie in ipairs(baggies) do
        if remainingToSell <= 0 then break end
        
        local countInSlot = baggie.count
        local take = math.min(countInSlot, remainingToSell)
        
        -- Calculate Price Per Unit for this specific baggie
        local quality = baggie.metadata.quality or 50
        local strainId = baggie.metadata.strain
        local strain = Weed.Strains.Get(strainId)
        local strainRep = strain and strain.reputation or 0
        
        local priceUnit = Weed.Cornering.CalculatePrice(quality, strainRep)
        local originalPrice = priceUnit
        
        -- Apply Negotiator Perk
        if strain and type(strain) == 'table' then
            local negotiatorMult = Weed.Perks.GetModifier(strain.perks, 'negotiator')
            if negotiatorMult > 1.0 then
                priceUnit = math.floor(priceUnit * negotiatorMult)
            end
            
            -- MASTERY BUFFS: Sales
            if strain.unlocked then
                local function HasMastery(id)
                    for _, uid in ipairs(strain.unlocked) do
                        if uid == id then return true end
                    end
                    return false
                end
                
                -- m10q: Terpenes (1.5x Sell Price)
                if HasMastery('m10q') then
                    priceUnit = math.floor(priceUnit * 1.5)
                end
            end
        end
        
        -- Apply Event Multiplier
        local safeMult = math.min(moneyMult, 2.0) -- Hard cap multiplier at 2x
        priceUnit = math.floor(priceUnit * safeMult)
        
        -- ULTIMATE SAFETY CAP
        if priceUnit > 3000 then 
            Weed.Debug("[SELL] WARNING: Price Unit exceeded limit (%d). Capped at 3000.", priceUnit)
            priceUnit = 3000 
        end
        
        -- Weed.Debug("[SELL] Slot: %d | Take: %d | Unit Price: %d (Orig: %d)", baggie.slot, take, priceUnit, originalPrice)

        -- Try to remove items
        if Weed.RemoveItem(src, 'weed_baggie', take, nil, baggie.slot) then
            totalEarned = totalEarned + (priceUnit * take)
            remainingToSell = remainingToSell - take
            soldCount = soldCount + take
            
            -- Update Reputations logic (per bag logic)
             if quality > 50 then
                local repGain = 1
                if strain and strain.unlocked then
                    local function HasMastery(id)
                        for _, uid in ipairs(strain.unlocked) do
                            if uid == id then return true end
                        end
                         return false
                    end
                    if HasMastery('m15q') then repGain = 2 end
                end
                
                Weed.Dealers.UpdateReputation(citizenid, repGain * take)
                if strain then
                    Weed.Strains.UpdateReputation(strain.id, repGain * take)
                end
            end
            
            -- Add XP Logic
             if strain and strain.id and strain.id > 0 then
                Weed.Strains.AddXP(strain.id, Weed.Perks.XP.Actions.Sell * take)
            end
        else
            -- Weed.Debug("[SELL] Failed to remove item from slot %d", baggie.slot)
        end
    end
    
    if soldCount > 0 then
        -- Payout controlled by config: 'dirty' or 'clean'
        local payoutType = 'dirty'
        local dirtyItem = 'black_money'
        local cleanItem = 'money'
        if Weed and Weed.Cornering and Weed.Cornering.Config and Weed.Cornering.Config.Payout then
             payoutType = Weed.Cornering.Config.Payout.Type or payoutType
             dirtyItem = (Weed.Cornering.Config.Payout.Items and Weed.Cornering.Config.Payout.Items.dirty) or dirtyItem
             cleanItem = (Weed.Cornering.Config.Payout.Items and Weed.Cornering.Config.Payout.Items.clean) or cleanItem
        end
        
        -- Weed.Debug("[SELL] Total Earned: %d | Type: %s", totalEarned, payoutType)

        if payoutType == 'dirty' then
            if exports.ox_inventory:CanCarryItem(src, dirtyItem, totalEarned) then
                Weed.AddItem(src, dirtyItem, totalEarned)
            else
                if cleanItem and exports.ox_inventory:CanCarryItem(src, cleanItem, totalEarned) then
                    Weed.AddItem(src, cleanItem, totalEarned)
                else
                    Player.Functions.AddMoney('cash', totalEarned)
                end
            end
        else
             if cleanItem and exports.ox_inventory:CanCarryItem(src, cleanItem, totalEarned) then
                Weed.AddItem(src, cleanItem, totalEarned)
            else
                Player.Functions.AddMoney('cash', totalEarned)
            end
        end
        
        local msg
        if moneyMult > 1.0 then
            msg = Lang('notify', 'sold_baggies_tip', soldCount, totalEarned)
        elseif moneyMult < 1.0 then
             msg = Lang('notify', 'sold_baggies_reduced', soldCount, totalEarned)
        else
             msg = Lang('notify', 'sold_baggies_normal', soldCount, totalEarned)
        end
        
        Weed.Notify(src, msg, 'success')
        -- Weed.Debug("Player %s sold %d baggies (req: %d) for $%d", citizenid, soldCount, quantity, totalEarned)
    else
        Weed.Notify(src, Lang('notify', 'no_baggies'), 'error')
    end
    
    processingSales[src] = nil
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