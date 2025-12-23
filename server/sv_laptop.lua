CreateThread(function()
    while GetResourceState('fd_laptop') ~= 'started' do 
        Wait(500) 
    end

    local success, err = exports.fd_laptop:addCustomApp({
        id = 'ferp-weed-lab',
        name = 'Lab',
        icon = 'flask', 
        ui = ("https://cfx-nui-%s/web/index.html"):format(GetCurrentResourceName()),
        isDefaultApp = true, 
        appstore = {
            description = 'Gerenciamento de Cepas e Perks',
            author = 'Ferp Dev',
        },
        -- Optional window configuration
        windowActions = { isResizable = false, isMaximizable = true, isClosable = true, isMinimizable = true, isDraggable = true },
        windowDefaultStates = { isMaximized = false, isMinimized = false },
    })

    if not success then
        print('^1[Ferp-Weed] Failed to register Weed Lab app: ' .. tostring(err) .. '^0')
    else
        print('^2[Ferp-Weed] Weed Lab app registered successfully^0')
    end
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
                    if v > 0 then table.insert(perks, k) end
                end
            end

            -- Calculate Level
            local level = strain.level
            local totalPoints = Weed.Perks.GetPointsTotal(level)
            local spentPoints = 0

            local unlockedPerks = {}
            if strain.perks then
                for k, v in pairs(strain.perks) do
                    local perkConfig = Weed.Perks.List[k]
                    if perkConfig then
                        spentPoints = spentPoints + (perkConfig.cost * v)
                        unlockedPerks[k] = v -- Store level
                    end
                end
            end
            
            if strain.unlocked then
                for _, masteryId in ipairs(strain.unlocked) do
                    -- Mastery doesn't cost perk points usually, but if it does, add here.
                    -- Assuming mastery is separate or costs 0 points as per sv_laptop logic (it ignored cost)
                    -- If mastery costs points, we need to know the cost. Assuming 0 for now.
                    unlockedPerks[masteryId] = 1 
                end
            end

            local availablePoints = math.max(0, totalPoints - spentPoints)

            table.insert(myStrains, {
                id = strain.id,
                name = strain.name,
                citizenid = strain.citizenid,
                level = level,
                points = availablePoints,
                unlocked = unlockedPerks, 
                indoor_unlocked = strain.indoor_unlocked or false,
                indoor_upgrades = strain.indoor_upgrades or {}
            })
        end
    end

    return myStrains
end)

lib.callback.register('ferp-weed:unlockPerk', function(source, data)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { success = false } end

    local strainId = data.strainId
    local perkId = data.perkId
    local type = data.type

    local strain = Weed.Strains.Get(strainId)
    if not strain then return { success = false } end
    if strain.citizenid ~= Player.PlayerData.citizenid then return { success = false } end

    if type == 'perk' then
        if not strain.perks then strain.perks = {} end
        strain.perks[perkId] = (strain.perks[perkId] or 0) + 1
    elseif type == 'indoor_unlock' then
        strain.indoor_unlocked = true
    elseif type == 'indoor_upgrade' then
        if not strain.indoor_upgrades then strain.indoor_upgrades = {} end
        table.insert(strain.indoor_upgrades, perkId)
    elseif type == 'mastery' then -- Added Mastery handling
        if not strain.unlocked then strain.unlocked = {} end
        table.insert(strain.unlocked, perkId) 
    end
    
    -- Save to Database
    MySQL.update('UPDATE weed_strains SET perks = ?, unlocked = ?, indoor_unlocked = ?, indoor_upgrades = ? WHERE id = ?', {
        json.encode(strain.perks or {}),
        json.encode(strain.unlocked or {}),
        strain.indoor_unlocked and 1 or 0,
        json.encode(strain.indoor_upgrades or {}),
        strainId
    })

    -- Sync to all clients so Item Use works with new perks
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
    
    -- Save logic here

    return { success = true }
end)
