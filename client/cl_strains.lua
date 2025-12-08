local npcSpawned = false
local npcEntity = nil
local currentNPCData = nil

-- Get current NPC location from server
local function GetNPCLocation()
    return lib.callback.await('Ferp-Weed:server:getNPCLocation', false)
end

-- Create NPC
local function SpawnStrainNPC()
    if npcSpawned then return end
    
    local npcData = GetNPCLocation()
    if not npcData then 
        Weed.Debug("No NPC data received from server")
        return 
    end
    
    currentNPCData = npcData
    
    local model = `a_m_y_beach_01`
    lib.requestModel(model, 5000)
    
    npcEntity = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z, npcData.coords.w, false, true)
    
    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)
    
    TaskStartScenarioInPlace(npcEntity, npcData.scenario, 0, true)
    
    npcSpawned = true
    
    Weed.Debug("Spawned strain NPC at %s", npcData.name)
end

-- Remove NPC
local function RemoveStrainNPC()
    if npcEntity and DoesEntityExist(npcEntity) then
        DeleteEntity(npcEntity)
        npcEntity = nil
        npcSpawned = false
        currentNPCData = nil
    end
end

-- Initialize
CreateThread(function()
    Wait(5000)
    SpawnStrainNPC()
end)

-- Show strain ranking
function ShowStrainRanking()
    local options = {
        {
            title = Lang('menu', 'top_strains'),
            icon = 'ranking-star',
            readOnly = true
        }
    }
    
    -- Sort strains by rank
    local ranking = {}
    for _, strain in pairs(Weed.Strains.Created) do
        if strain.rank and strain.rank <= 10 then
            ranking[strain.rank] = strain
        end
    end
    
    -- Add ranked strains
    for i = 1, 10 do
        local strain = ranking[i]
        if strain then
            local reputation = Weed.Strains.GetReputation(strain)
            options[#options + 1] = {
                title = string.format('#%d - %s', strain.rank, strain.name),
                description = Lang('notify', 'rank_format', reputation.name, strain.reputation),
                icon = 'seedling',
                readOnly = true
            }
        else
            options[#options + 1] = {
                title = string.format('#%d - %s', i, Lang('notify', 'empty_slot')),
                description = Lang('notify', 'no_strain_in_rank'),
                icon = 'minus',
                readOnly = true
            }
        end
    end
    
    lib.registerContext({
        id = 'strain_ranking',
        title = Lang('menu', 'strain_ranking'),
        options = options
    })
    
    lib.showContext('strain_ranking')
end

-- Manage player strains
function ManageStrains()
    local citizenid = exports.qbx_core:GetPlayerData().citizenid
    local playerStrains = {}
    
    for _, strain in pairs(Weed.Strains.Created) do
        if strain.citizenid == citizenid then
            playerStrains[#playerStrains + 1] = strain
        end
    end
    
    local options = {
        {
            title = Lang('menu', 'your_strains'),
            description = Lang('notify', 'strains_count', #playerStrains),
            icon = 'leaf',
            readOnly = true
        }
    }
    
    if #playerStrains == 0 then
        options[#options + 1] = {
            title = Lang('menu', 'no_strain'),
            description = Lang('notify', 'create_strains_hint'),
            icon = 'info-circle',
            readOnly = true
        }
    else
        for _, strain in ipairs(playerStrains) do
            local reputation = Weed.Strains.GetReputation(strain)
            
            options[#options + 1] = {
                title = strain.name,
                description = Lang('notify', 'rank_format', reputation.name, strain.reputation),
                icon = 'seedling',
                onSelect = function()
                    ShowStrainDetails(strain)
                end
            }
        end
    end
    
    lib.registerContext({
        id = 'manage_strains',
        title = Lang('menu', 'manage_strains'),
        options = options
    })
    
    lib.showContext('manage_strains')
end

-- Show strain details
function ShowStrainDetails(strain)
    local reputation = Weed.Strains.GetReputation(strain)
    
    local options = {
        {
            title = strain.name,
            description = Lang('notify', 'global_rank', strain.rank or 0),
            icon = 'cannabis',
            readOnly = true
        },
        {
            title = Lang('menu', 'info'),
            description = Lang('notify', 'npk_format', strain.n, strain.p, strain.k),
            icon = 'info-circle',
            readOnly = true
        },
        {
            title = Lang('menu', 'reputation'),
            description = Lang('notify', 'reputation_format', reputation.name, strain.reputation),
            icon = 'star',
            readOnly = true
        },
        {
            title = Lang('menu', 'rename_strain'),
            description = strain.renamed and Lang('notify', 'already_renamed_hint') or Lang('notify', 'can_rename_hint'),
            icon = 'pen',
            disabled = strain.renamed or not reputation.canChangeName,
            onSelect = function()
                RenameStrain(strain.id)
            end
        },
        {
            title = Lang('menu', 'delete_strain'),
            description = Lang('notify', 'remove_permanently'),
            icon = 'trash',
            disabled = not reputation.canChangeName,
            onSelect = function()
                DeleteStrain(strain.id)
            end
        }
    }
    
    lib.registerContext({
        id = 'strain_details',
        title = Lang('menu', 'strain_details'),
        menu = 'manage_strains',
        options = options
    })
    
    lib.showContext('strain_details')
end

-- Rename strain
function RenameStrain(strainId)
    local input = lib.inputDialog(Lang('menu', 'rename_strain'), {
        {
            type = 'input',
            label = Lang('menu', 'new_name'),
            description = Lang('notify', 'min_max_chars'),
            required = true,
            min = 5,
            max = 50
        }
    })
    
    if not input or not input[1] then
        return ManageStrains()
    end
    
    local name = input[1]
    
    if #name < 5 or #name > 50 then
        Weed.Notify(nil, Lang('notify', 'invalid_name_short'), 'error')
        return ManageStrains()
    end
    
    TriggerServerEvent('Ferp-Weed:server:renameStrain', strainId, name)
    
    Wait(500)
    ManageStrains()
end

-- Delete strain
function DeleteStrain(strainId)
    local alert = lib.alertDialog({
        header = Lang('menu', 'delete_strain'),
        content = Lang('notify', 'confirm_delete'),
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('Ferp-Weed:server:deleteStrain', strainId)
        
        Wait(500)
        ManageStrains()
    else
        ManageStrains()
    end
end

-- Open weed shop
function OpenWeedShop()
    TriggerServerEvent('Ferp-Weed:server:openShop')
end

-- Open shop via ox_inventory
RegisterNetEvent('Ferp-Weed:client:openShop', function()
    exports.ox_inventory:openInventory('shop', { type = 'weed_shop' })
end)

-- Exports
exports('ShowStrainRanking', ShowStrainRanking)
exports('ManageStrains', ManageStrains)
exports('OpenWeedShop', OpenWeedShop)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        RemoveStrainNPC()
    end
end)

Weed.Debug("Client strains loaded")