-- Command to Open UI (for testing or usage)
lib.addCommand('weedlab', {
    help = 'Abrir o Laboratório de Cepas',
    restricted = false
}, function(source, args, raw)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('ferp-weed:openUI', source)
end)

-- Callbacks
lib.callback.register('ferp-weed:getStrainData', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return {} end

    local citizenid = Player.PlayerData.citizenid
    local myStrains = {}

    -- Filter strains owned by this player
    for id, strain in pairs(Weed.Strains.Created) do
        if strain.citizenid == citizenid then
            -- Format strain data for UI
            local perks = {}
            if strain.perks then
                for k, v in pairs(strain.perks) do
                    if v > 0 then perks[k] = v end
                end
            end
            
            -- Calculate Points
            local currentPointsUsed = 0
            if strain.perks then
                for pid, level in pairs(strain.perks) do
                    local pDef = Weed.Perks.List[pid]
                    if pDef then
                        currentPointsUsed = currentPointsUsed + (level * pDef.cost)
                    end
                end
            end
            
            local totalPoints = Weed.Perks.GetPointsTotal(strain.level)
            local pointsAvailable = totalPoints - currentPointsUsed

            table.insert(myStrains, {
                id = strain.id,
                name = strain.name,
                citizenid = strain.citizenid,
                level = strain.level, 
                points = pointsAvailable, 
                unlocked = perks,
                indoor_unlocked = strain.indoor_unlocked or false,
                indoor_upgrades = strain.indoor_upgrades or {} 
            })
        end
    end

    return myStrains
end)
