local QBX = exports.qbx_core

-- Load locales on resource start
Weed.LoadLocale()

-- Database Setup
CreateThread(function()
    -- Create tables if they don't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `weed_plants` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `coords` TEXT NOT NULL,
            `metadata` LONGTEXT NOT NULL,
            `created_at` INT(11) NOT NULL,
            `expires_at` INT(11) NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `weed_strains` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(255) DEFAULT NULL,
            `strain` TEXT NOT NULL,
            `reputation` INT(11) DEFAULT 0,
            `renamed` TINYINT(1) DEFAULT 0,
            PRIMARY KEY (`id`),
            INDEX `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `weed_dealers` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL UNIQUE,
            `reputation` INT(11) DEFAULT 0,
            `last_sell` INT(11) DEFAULT 0,
            PRIMARY KEY (`id`),
            INDEX `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    Weed.Debug("Database tables initialized")
end)

-- Player Loading
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player then return end
    
    local src = Player.PlayerData.source
    
    -- Load player strains
    TriggerClientEvent('Ferp-Weed:client:loadStrains', src, Weed.Strains.Created)
    
    -- Load all active plants
    TriggerClientEvent('Ferp-Weed:client:loadPlants', src, Weed.Plants.Active)
end)

-- Also handle player spawn for qbx
RegisterNetEvent('qbx_core:server:playerLoaded', function()
    local src = source
    
    -- Load player strains
    TriggerClientEvent('Ferp-Weed:client:loadStrains', src, Weed.Strains.Created)
    
    -- Load all active plants
    TriggerClientEvent('Ferp-Weed:client:loadPlants', src, Weed.Plants.Active)
end)

-- Callbacks
lib.callback.register('Ferp-Weed:server:getTime', function(source)
    return os.time()
end)

lib.callback.register('Ferp-Weed:server:getStrains', function(source)
    return Weed.Strains.Created
end)

lib.callback.register('Ferp-Weed:server:getPlants', function(source)
    return Weed.Plants.Active
end)

lib.callback.register('Ferp-Weed:server:getDealerReputation', function(source, citizenid)
    local Player = QBX:GetPlayer(source)
    if not Player then return nil end
    
    citizenid = citizenid or Player.PlayerData.citizenid
    return Weed.Dealers.GetReputation(citizenid)
end)

-- Inventory Item Use Events
RegisterNetEvent('Ferp-Weed:server:useItem', function(itemName, itemData)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    if itemName == 'weed_bud' then
        -- Buds não são mais usados diretamente - só pelo NPC
        Weed.Notify(src, Lang('notify', 'find_packager'), 'info')
        
    elseif itemName == 'weed_brick' then
        -- Brick - envia para client verificar balança e saquinhos
        TriggerClientEvent('Ferp-Weed:client:useBrick', src, itemData.slot)
        
    elseif itemName == 'weed_baggie' then
        -- Baggie - envia para client verificar papel
        TriggerClientEvent('Ferp-Weed:client:useBaggie', src, itemData.slot)
        
    elseif itemName == 'joint' then
        -- Smoke joint - item só é removido quando terminar de fumar
        local slot = itemData.slot
        local quality = itemData.metadata.quality or 50
        
        -- Envia pro client começar a fumar (item ainda no inventário)
        TriggerClientEvent('Ferp-Weed:client:smokeJoint', src, quality, slot)
    end
end)

-- Terminou de fumar o joint com sucesso - agora remove o item
RegisterNetEvent('Ferp-Weed:server:finishSmokingJoint', function(slot)
    local src = source
    
    -- Verifica se ainda tem o joint no slot
    local jointItem = exports.ox_inventory:GetSlot(src, slot)
    if not jointItem or jointItem.name ~= 'joint' then
        return -- Joint já foi removido ou não existe
    end
    
    -- Remove o joint
    Weed.RemoveItem(src, 'joint', 1, nil, slot)
end)

-- Combine items (rolling joint from baggie)
RegisterNetEvent('Ferp-Weed:server:combineItems', function(baggieSlot, paperSlot)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player then return end
    
    local baggie = exports.ox_inventory:GetSlot(src, baggieSlot)
    local paper = exports.ox_inventory:GetSlot(src, paperSlot)
    
    if not baggie or baggie.name ~= 'weed_baggie' then
        return Weed.Notify(src, Lang('notify', 'baggie_not_found'), 'error')
    end
    
    if not paper or paper.name ~= 'rolling_paper' then
        return Weed.Notify(src, Lang('notify', 'paper_not_found'), 'error')
    end
    
    -- Remove items
    if not Weed.RemoveItem(src, 'weed_baggie', 1, nil, baggieSlot) then return end
    if not Weed.RemoveItem(src, 'rolling_paper', 1, nil, paperSlot) then return end
    
    -- Get strain
    local strainId = baggie.metadata.strain
    local strain = nil
    if strainId and strainId > 0 then
        strain = Weed.Strains.Get(strainId)
    elseif strainId and strainId < 0 then
        strain = Weed.Strains.GetDefaultById(strainId)
    end
    
    -- Create joints (fixed amount)
    local jointCount = Weed.Items.Config.JointsPerBaggie
    local metadata = Weed.Items.CreateMetadata('joint', strain, baggie.metadata.quality)
    
    Weed.AddItem(src, 'joint', jointCount, metadata)
    Weed.Notify(src, Lang('notify', 'rolled_joints', jointCount), 'success')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Save all active plants
    for plantId, plant in pairs(Weed.Plants.Active) do
        -- Save logic here if needed
    end
    
    Weed.Debug("Resource stopped, cleanup complete")
end)

-- Admin Commands
lib.addCommand('giveseed', {
    help = 'Dar semente com strain específica',
    params = {
        {name = 'target', type = 'playerId', help = 'ID do jogador'},
        {name = 'strainId', type = 'number', help = 'ID da strain (0 = sem strain)', optional = true},
        {name = 'amount', type = 'number', help = 'Quantidade', optional = true},
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local targetId = args.target
    local strainId = args.strainId or 0
    local amount = args.amount or 1
    
    local strain = nil
    if strainId > 0 then
        strain = Weed.Strains.Get(strainId)
        if not strain then
            return Weed.Notify(source, Lang('notify', 'strain_not_found_cmd'), 'error')
        end
    else
        -- Assign random default strain if no strainId provided
        strain = Weed.Strains.GetRandomDefault()
    end
    
    local metadata = Weed.Items.CreateMetadata('weed_seed_female', strain, 100)
    
    for i = 1, amount do
        Weed.AddItem(targetId, 'weed_seed_female', 1, metadata)
    end
    
    Weed.Notify(source, string.format('Deu %d semente(s) para jogador %d', amount, targetId), 'success')
    Weed.Notify(targetId, string.format('Recebeu %d semente(s) de %s', amount, strain.name), 'success')
end)

lib.addCommand('givebud', {
    help = 'Dar buds de maconha',
    params = {
        {name = 'target', type = 'playerId', help = 'ID do jogador'},
        {name = 'amount', type = 'number', help = 'Quantidade', optional = true},
        {name = 'strainId', type = 'number', help = 'ID da strain (0 = aleatória)', optional = true},
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local targetId = args.target
    local amount = args.amount or 1
    local strainId = args.strainId or 0
    
    local strain = nil
    if strainId > 0 then
        strain = Weed.Strains.Get(strainId)
    elseif strainId < 0 then
        strain = Weed.Strains.GetDefaultById(strainId)
    end
    
    if not strain then
        strain = Weed.Strains.GetRandomDefault()
    end
    
    local metadata = Weed.Items.CreateMetadata('weed_bud', strain, 100)
    
    Weed.AddItem(targetId, 'weed_bud', amount, metadata)
    
    Weed.Notify(source, string.format('Deu %d bud(s) para jogador %d', amount, targetId), 'success')
    Weed.Notify(targetId, string.format('Recebeu %d bud(s) de %s', amount, strain.name), 'success')
end)

lib.addCommand('liststrains', {
    help = 'Listar todas as strains',
    restricted = 'group.admin'
}, function(source, args, raw)
    print('--- STRAINS REGISTRADAS ---')
    for id, strain in pairs(Weed.Strains.Created) do
        print(string.format('ID: %d | Nome: %s | Dono: %s | Rep: %d', 
            id, strain.name or 'SEM NOME', strain.citizenid or 'N/A', strain.reputation or 0))
    end
    print('--- FIM ---')
    Weed.Notify(source, Lang('notify', 'strains_listed_console'), 'info')
end)

lib.addCommand('mystrains', {
    help = 'Ver suas strains'
}, function(source, args, raw)
    local Player = QBX:GetPlayer(source)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local found = false
    
    print('--- SUAS STRAINS ---')
    for id, strain in pairs(Weed.Strains.Created) do
        if strain.citizenid == citizenid then
            found = true
            print(string.format('ID: %d | Nome: %s | NPK: %.1f/%.1f/%.1f | Rep: %d', 
                id, strain.name or 'SEM NOME', strain.n or 0, strain.p or 0, strain.k or 0, strain.reputation or 0))
            Weed.Notify(source, string.format('Strain #%d: %s', id, strain.name or 'SEM NOME'), 'info')
        end
    end
    
    if not found then
        Weed.Notify(source, Lang('notify', 'no_strains_registered'), 'error')
    end
end)

lib.addCommand('reloadstrains', {
    help = 'Recarregar strains do banco',
    restricted = 'group.admin'
}, function(source, args, raw)
    -- Reload strains from database
    local strains = MySQL.query.await([[
        SELECT *
        FROM weed_strains
        ORDER BY reputation DESC
    ]])
    
    Weed.Strains.Created = {}
    
    if strains then
        for rank, strainData in ipairs(strains) do
            local strain = json.decode(strainData.strain)
            
            local name = strainData.name
            if not name or name == '' then
                name = Weed.Strains.GenerateName(strain.n, strain.p, strain.k)
                MySQL.update('UPDATE weed_strains SET name = ? WHERE id = ?', {name, strainData.id})
            end
            
            Weed.Strains.Created[strainData.id] = {
                id = strainData.id,
                citizenid = strainData.citizenid,
                name = name,
                reputation = strainData.reputation or 0,
                n = strain.n,
                p = strain.p,
                k = strain.k,
                rank = rank,
                renamed = strainData.renamed == 1
            }
        end
    end
    
    -- Broadcast to all clients
    TriggerClientEvent('Ferp-Weed:client:loadStrains', -1, Weed.Strains.Created)
    
    Weed.Notify(source, string.format('Recarregado %d strains', strains and #strains or 0), 'success')
end)

Weed.Debug("Server main loaded successfully")