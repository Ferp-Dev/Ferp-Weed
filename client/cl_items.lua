RegisterNetEvent('Ferp-Weed:client:processBud', function(itemData, slot)
    local success = ShowProgress({
        duration = 8000,
        label = Lang('progress', 'pressing_buds'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'anim@amb@business@weed@weed_sorting_seated@',
            clip = 'sorter_left_sort_v2_sorter01',
            flag = 17
        },
        prop = {
            model = `bkr_prop_weed_bud_pruned_01a`,
            bone = 58866,
            pos = vec3(0.09, -0.02, -0.03),
            rot = vec3(0.0, 0.0, 0.0)
        }
    })
    
    if not success then return end
    
    TriggerServerEvent('Ferp-Weed:server:useItem', 'weed_bud', itemData)
end)

-- Open brick into baggies
RegisterNetEvent('Ferp-Weed:client:openBrick', function(itemData, slot)
    local success = ShowProgress({
        duration = 5000,
        label = Lang('progress', 'opening_brick'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'anim@amb@business@weed@weed_sorting_seated@',
            clip = 'sorter_left_sort_v2_sorter01',
            flag = 17
        }
    })
    
    if not success then return end
    
    TriggerServerEvent('Ferp-Weed:server:useItem', 'weed_brick', itemData)
end)

-- Smoke joint
RegisterNetEvent('Ferp-Weed:client:smokeJoint', function(quality, slot)
    local effectiveness = 1.0 * (quality / 100)
    
    -- Inicia o scenario (já tem prop integrado)
    TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_SMOKING_POT', 0, true)
    
    -- ProgressBar (sem anim/prop pois o scenario já cuida disso)
    local success = ShowProgress({
        duration = Weed.Items.Config.JointDuration * 1000,
        label = Lang('progress', 'smoking_joint'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            combat = true,
        }
    })
    
    -- Para o scenario
    ClearPedTasks(cache.ped)
    
    -- Se cancelou, não remove item nem aplica efeitos
    if not success then
        Weed.Notify(nil, Lang('notify', 'joint_cancelled'), 'info')
        return
    end
    
    -- Só remove o joint quando terminar de fumar com sucesso
    TriggerServerEvent('Ferp-Weed:server:finishSmokingJoint', slot)
    
    -- Set evidence
    TriggerEvent('evidence:client:SetStatus', 'redeyes', Weed.Items.Config.RedEyesDuration)
    TriggerEvent('evidence:client:SetStatus', 'weedsmell', Weed.Items.Config.WeedSmellDuration)
    
    local screenEffectDuration = 15 - (effectiveness * 10) -- Range: 5-15 segundos
    
    CreateThread(function()
        local startTime = GetGameTimer()
        
        
        StartScreenEffect("DrugsMichaelAliensFight", screenEffectDuration * 1000, false)
        
        while GetGameTimer() - startTime < (screenEffectDuration * 1000) do
            ShakeGameplayCam("DRUNK_SHAKE", 0.25)
            Wait(50)
        end
        
        
        StopScreenEffect("DrugsMichaelAliensFight")
    end)
    
    -- Aplicar efeitos apenas no final (sucesso)
    
    -- Add armor baseado na qualidade (max 50 com quality 100%)
    local armorBonus = math.ceil(50 * effectiveness)
    local currentArmor = GetPedArmour(cache.ped)
    local newArmor = math.min(100, currentArmor + armorBonus)
    SetPedArmour(cache.ped, newArmor)
    
    
    if Config.UseStress then
        local stressReduction = math.ceil(Weed.Items.Config.MaxStressReduction * effectiveness)
        TriggerServerEvent('hud:server:RelieveStress', stressReduction)
    end
    
    Weed.Notify(nil, Lang('notify', 'feeling_relaxed'), 'success')
end)

-- Apply joint buffs (for external scripts via export)
RegisterNetEvent('Ferp-Weed:client:applyJointBuffs', function(effectiveness)
    -- Add armor (max 50 com quality 100%)
    local armorBonus = math.ceil(50 * effectiveness)
    local currentArmor = GetPedArmour(cache.ped)
    local newArmor = math.min(100, currentArmor + armorBonus)
    SetPedArmour(cache.ped, newArmor)
    
    -- Reduce stress
    if Config.UseStress then
        local stressReduction = math.ceil(Weed.Items.Config.MaxStressReduction * effectiveness)
        TriggerServerEvent('hud:server:RelieveStress', stressReduction)
    end
    
    Weed.Notify(nil, Lang('notify', 'feeling_relaxed'), 'success')
end)

-- Roll joint (combine baggie + paper)
RegisterNetEvent('Ferp-Weed:client:rollJoint', function()
    local input = lib.inputDialog(Lang('menu', 'roll_joint'), {
        {
            type = 'number',
            label = Lang('menu', 'baggie_slot'),
            description = Lang('menu', 'baggie_slot_desc'),
            required = true,
            min = 1,
            max = 50
        },
        {
            type = 'number',
            label = Lang('menu', 'paper_slot'),
            description = Lang('menu', 'paper_slot_desc'),
            required = true,
            min = 1,
            max = 50
        }
    })
    
    if not input then return end
    
    local baggieSlot = input[1]
    local paperSlot = input[2]
    
    -- Show animation
    local success = ShowProgress({
        duration = 3000,
        label = Lang('progress', 'rolling_joint'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'amb@prop_human_parking_meter@female@idle_a',
            clip = 'idle_a_female',
            flag = 49
        }
    })
    
    if not success then return end
    
    TriggerServerEvent('Ferp-Weed:server:combineItems', baggieSlot, paperSlot)
end)

-- View item quality
function ViewItemQuality(itemData)
    if not itemData.metadata or not itemData.metadata.quality then
        return Weed.Notify(nil, Lang('notify', 'no_quality'), 'error')
    end
    
    local quality = itemData.metadata.quality
    local qualityLabel = Weed.Items.GetQualityLabel(quality)
    local qualityColor = Weed.Items.GetQualityColor(quality)
    local strainName = itemData.metadata.strain_name or "Unknown"
    
    local content = string.format(
        '<p>Strain: <b>%s</b></p><p>Qualidade: <b style="color:%s">%s (%d/100)</b></p>',
        strainName,
        qualityColor,
        qualityLabel,
        quality
    )
    
    lib.alertDialog({
        header = Lang('notify', 'item_info'),
        content = content,
        centered = true
    })
end

-- Inspect weed item (context menu)
function InspectWeedItem(itemData)
    if not itemData or not itemData.name then return end
    
    local options = {
        {
            title = Lang('menu', 'info'),
            icon = 'info-circle',
            readOnly = true
        }
    }
    
    if itemData.metadata then
        -- Quality info
        if itemData.metadata.quality then
            local quality = itemData.metadata.quality
            local qualityLabel = Weed.Items.GetQualityLabel(quality)
            
            options[#options + 1] = {
                title = string.format('%s: %s', Lang('menu', 'quality'), qualityLabel),
                description = string.format('%d/100', quality),
                icon = 'star',
                readOnly = true
            }
        end
        
        -- Strain info
        if itemData.metadata.strain_name then
            options[#options + 1] = {
                title = Lang('menu', 'strain_prefix', itemData.metadata.strain_name),
                icon = 'cannabis',
                readOnly = true
            }
        end
    end
    
    if #options > 1 then
        lib.registerContext({
            id = 'inspect_weed',
            title = itemData.label or 'Weed Item',
            options = options
        })
        
        lib.showContext('inspect_weed')
    else
        Weed.Notify(nil, Lang('notify', 'no_info'), 'info')
    end
end

-- Exports
exports('ViewItemQuality', ViewItemQuality)
exports('InspectWeedItem', InspectWeedItem)

-- ============================================
-- PACKAGING NPCs SYSTEM (Sul e Norte)
-- ============================================

local packagingNPCs = {
    Sul = { entity = nil, blip = nil, location = nil },
    Norte = { entity = nil, blip = nil, location = nil }
}

-- Get NPC locations from server
local function GetPackagingNPCLocations()
    return lib.callback.await('Ferp-Weed:server:getPackagingNPCLocations', false)
end

-- Spawn a packaging NPC
local function SpawnPackagingNPC(region, npcData, locationData)
    if packagingNPCs[region].entity then return end
    
    local model = npcData.Model
    lib.requestModel(model, 5000)
    
    local coords = locationData.coords
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, npcData.Scenario, 0, true)
    
    packagingNPCs[region].entity = ped
    packagingNPCs[region].location = locationData
    
    Weed.Debug("Spawned packaging NPC at %s (%s)", locationData.name, region)
end

-- Remove packaging NPCs
local function RemovePackagingNPCs()
    for region, data in pairs(packagingNPCs) do
        if data.entity and DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
        packagingNPCs[region] = { entity = nil, location = nil }
    end
end

-- Open packaging menu (NPC faz bricks de todas as strains)
local function OpenPackagingMenu()
    local options = {}
    
    local budCount = exports.ox_inventory:Search('count', 'weed_bud')
    local budsNeeded = Weed.Items.Config.BudsPerBrick
    local possibleBricks = math.floor(budCount / budsNeeded)
    
    options[#options + 1] = {
        title = Lang('menu', 'press_all_buds'),
        description = Lang('menu', 'buds_count_desc', budCount, possibleBricks, possibleBricks ~= 1 and 's' or ''),
        icon = 'box',
        disabled = budCount < budsNeeded,
        onSelect = function()
            ProcessBudsToBrick()
        end
    }
    
    lib.registerContext({
        id = 'packaging_menu',
        title = Lang('menu', 'packager'),
        options = options
    })
    
    lib.showContext('packaging_menu')
end

-- Process Buds to Brick
function ProcessBudsToBrick()
    local success = ShowProgress({
        duration = Weed.Items.Config.ProcessingTimes.BudsToBrick,
        label = Lang('progress', 'pressing_buds'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'anim@amb@business@weed@weed_sorting_seated@',
            clip = 'sorter_left_sort_v2_sorter01'
        }
    })
    
    if not success then 
        Weed.Notify(nil, Lang('notify', 'cancelled'), 'error')
        return 
    end
    
    TriggerServerEvent('Ferp-Weed:server:processPackaging', 'buds_to_brick')
end

-- Process Brick to Baggies (usando brick do inventário)
RegisterNetEvent('Ferp-Weed:client:useBrick', function(brickSlot)
    -- Check for scale and empty baggies
    local hasScale = exports.ox_inventory:Search('count', 'weed_scale') >= 1
    local emptyBaggies = exports.ox_inventory:Search('count', 'empty_baggie')
    local baggiesNeeded = Weed.Items.Config.BaggiesPerBrick
    
    if not hasScale then
        return Weed.Notify(nil, Lang('notify', 'need_scale'), 'error')
    end
    
    if emptyBaggies < baggiesNeeded then
        return Weed.Notify(nil, Lang('notify', 'need_baggies', baggiesNeeded), 'error')
    end
    
    local success = ShowProgress({
        duration = Weed.Items.Config.ProcessingTimes.BrickToBaggies,
        label = Lang('progress', 'weighing_dividing'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'anim@amb@business@weed@weed_sorting_seated@',
            clip = 'sorter_left_sort_v2_sorter01'
        }
    })
    
    if not success then 
        Weed.Notify(nil, Lang('notify', 'cancelled'), 'error')
        return 
    end
    
    TriggerServerEvent('Ferp-Weed:server:useBrick', brickSlot)
end)

-- Process Baggie to Joints (usando saquinho do inventário)
RegisterNetEvent('Ferp-Weed:client:useBaggie', function(baggieSlot)
    -- Check for rolling paper
    local papers = exports.ox_inventory:Search('count', 'rolling_paper')
    
    if papers < 1 then
        return Weed.Notify(nil, Lang('notify', 'need_paper'), 'error')
    end
    
    local success = ShowProgress({
        duration = Weed.Items.Config.ProcessingTimes.BaggieToJoints,
        label = Lang('progress', 'rolling_joints'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'amb@prop_human_parking_meter@female@idle_a',
            clip = 'idle_a_female'
        }
    })
    
    if not success then 
        Weed.Notify(nil, Lang('notify', 'cancelled'), 'error')
        return 
    end
    
    TriggerServerEvent('Ferp-Weed:server:useBaggie', baggieSlot)
end)

-- Add target to NPCs
local function SetupPackagingTargets()
    for region, data in pairs(packagingNPCs) do
        if data.entity and DoesEntityExist(data.entity) then
            exports.ox_target:addLocalEntity(data.entity, {
                {
                    name = 'packaging_npc_' .. region,
                    icon = 'fas fa-box',
                    label = Lang('menu', 'package_drugs'),
                    onSelect = function()
                        OpenPackagingMenu()
                    end,
                    distance = 2.5
                }
            })
        end
    end
end

-- Initialize packaging NPCs
CreateThread(function()
    Wait(6000) -- Wait a bit after strain NPC spawns
    
    local locations = GetPackagingNPCLocations()
    if not locations then 
        Weed.Debug("No packaging NPC locations received")
        return 
    end
    
    local config = Weed.Items.Config.PackagingNPCs
    
    if locations.Sul and config.Sul then
        SpawnPackagingNPC('Sul', config.Sul, locations.Sul)
    end
    
    if locations.Norte and config.Norte then
        SpawnPackagingNPC('Norte', config.Norte, locations.Norte)
    end
    
    Wait(500)
    SetupPackagingTargets()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        RemovePackagingNPCs()
    end
end)

-- ============================================
-- WATERING CAN SYSTEM (Encher regador na água)
-- ============================================

local isFillingWater = false

-- Verificar se está na água (incluindo piscinas)
local function IsNearWater()
    local coords = GetEntityCoords(cache.ped)
    local testZ = coords.z - 1.0
    
    -- Verificar se o ped está na água
    if IsEntityInWater(cache.ped) then
        return true, coords
    end
    
    -- Testar probe de água natural (mar, rio, lago)
    local waterFound, waterZ = TestProbeAgainstWater(coords.x, coords.y, coords.z, coords.x, coords.y, testZ)
    
    if waterFound then
        return true, vector3(coords.x, coords.y, waterZ)
    end
    
    -- Testar pontos ao redor para água natural
    for angle = 0, 360, 45 do
        local rad = math.rad(angle)
        local testX = coords.x + math.cos(rad) * 2.0
        local testY = coords.y + math.sin(rad) * 2.0
        
        waterFound, waterZ = TestProbeAgainstWater(testX, testY, coords.z, testX, testY, testZ)
        if waterFound then
            return true, vector3(testX, testY, waterZ)
        end
    end
    
    -- Verificar material do chão (piscinas usam material de água)
    local retval, groundZ, normal = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    if retval then
        local materialHash = GetSurfaceMaterialHashBelow(cache.ped)
        -- Hashes de materiais de água/piscina
        local waterMaterials = {
            [-1595148316] = true, -- shallow water
            [435688960] = true,   -- water
            [223086562] = true,   -- water puddle
            [1109728704] = true,  -- water deep
            [-488882771] = true,  -- pool water
            [-840216541] = true,  -- water murky
        }
        if waterMaterials[materialHash] then
            return true, coords
        end
    end
    
    return false, nil
end

-- Verificar se está perto de torneira/hidrante
local function IsNearWaterSource()
    local coords = GetEntityCoords(cache.ped)
    
    -- Lista de props de água
    local waterProps = {
        `prop_watercooler`,
        `prop_watercooler_dark`,
        `prop_water_tap_01`,
        `prop_fire_hydrant_1`,
        `prop_fire_hydrant_2`,
        `prop_fire_hydrant_2_l1`,
        `prop_fire_hydrant_3`,
        `prop_water_fountain_a`,
        `prop_water_fountain_b`,
        `prop_water_fountain_c`,
        `prop_water_tap_03`,
        `prop_sink_01`,
        `prop_sink_02`,
        `prop_sink_03`,
        `prop_sink_04`,
        `prop_sink_05`,
        `prop_sink_06`,
        `prop_sink_07`,
        `prop_sink_08`,
        `prop_sink_09`,
        `v_res_tre_faucet`,
        `v_res_tre_faucet2`,
        `v_res_tt_sink`,
        `v_ret_gc_sink`,
        `v_61_sink`,
        `prop_toilet_01`,
        `prop_toilet_02`,
        -- Beach & Outdoor Props TEST
        `prop_shower_02`,
        `prop_shower_03`,
        `prop_shower_01`,
        `v_res_fabios_sink`,
    }
    
    local nearestDist = 999.0
    local nearestObj = nil
    
    for _, propHash in ipairs(waterProps) do
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, propHash, false, false, false)
        if obj ~= 0 then
            local objCoords = GetEntityCoords(obj)
            local dist = #(coords - objCoords)
            if dist < nearestDist then
                nearestDist = dist
                nearestObj = obj
            end
        end
    end
    
    return nearestObj ~= nil, nearestObj
end

-- Função para encher regador
function FillWateringCan(slot)
    if isFillingWater then
        return Weed.Notify(nil, Lang('notify', 'already_filling'), 'error')
    end
    
    -- Verificar se tem regador vazio
    local wateringCan = exports.ox_inventory:Search('slots', 'wateringcan')
    if not wateringCan or #wateringCan == 0 then
        return Weed.Notify(nil, Lang('notify', 'no_watering_can'), 'error')
    end
    
    -- Verificar água por perto
    local nearWater, waterCoords = IsNearWater()
    local nearSource, sourceObj = IsNearWaterSource()
    
    if not nearWater and not nearSource then
        return Weed.Notify(nil, Lang('notify', 'need_water_source'), 'error')
    end
    
    isFillingWater = true
    
    -- Prop do regador
    local canProp = CreateObject(`prop_wateringcan`, 0.0, 0.0, 0.0, true, true, true)
    local rightHand = GetPedBoneIndex(cache.ped, 28422)
    AttachEntityToEntity(canProp, cache.ped, rightHand, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    -- ProgressBar
    local success = ShowProgress({
        duration = 5000,
        label = nearWater and Lang('progress', 'filling_water_river') or Lang('progress', 'filling_water_tap'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'mp_arresting',
            clip = 'a_uncuff',
            flag = 49
        }
    })
    
    -- Cleanup prop
    if DoesEntityExist(canProp) then
        DeleteEntity(canProp)
    end
    
    isFillingWater = false
    
    if not success then
        Weed.Notify(nil, Lang('notify', 'cancelled'), 'error')
        return
    end
    
    -- Atualizar item no servidor
    TriggerServerEvent('Ferp-Weed:server:fillWateringCan', slot)
end

-- Export para ox_target ou uso direto
exports('FillWateringCan', FillWateringCan)

-- Usar regador do inventário (verifica se precisa encher)
RegisterNetEvent('Ferp-Weed:client:useWateringCan', function(slot, metadata)
    local waterLevel = metadata and metadata.water or 0
    
    if waterLevel <= 0 then
        -- Regador vazio - tentar encher
        FillWateringCan(slot)
    else
        Weed.Notify(nil, Lang('notify', 'watering_can_status', waterLevel), 'info')
    end
end)

-- ============================================
-- HAND PROP SYSTEM (Prop na mão quando tiver item)
-- ============================================

local handProps = {}
local handPropAnims = {}
local handPropCheckInterval = 500 -- Intervalo de checagem em ms (mais rápido)

-- Força checagem de inventário (mais confiável)
local function GetItemCount(itemName)
    local count = 0
    pcall(function()
        count = exports.ox_inventory:Search('count', itemName) or 0
    end)
    return count
end

-- Criar prop na mão
local function CreateHandProp(itemName, propConfig)
    -- Verifica se realmente tem o item antes de criar
    local itemCount = GetItemCount(itemName)
    if itemCount <= 0 then
        Weed.Debug("Skipping hand prop for %s - no items in inventory", itemName)
        return
    end
    
    -- Remove prop antigo se existir
    if handProps[itemName] and DoesEntityExist(handProps[itemName]) then
        DeleteEntity(handProps[itemName])
        handProps[itemName] = nil
    end
    
    local model = type(propConfig.model) == 'string' and joaat(propConfig.model) or propConfig.model
    
    lib.requestModel(model, 5000)
    
    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    if not DoesEntityExist(prop) then
        Weed.Debug("Failed to create hand prop for %s", itemName)
        return
    end
    
    local bone = GetPedBoneIndex(cache.ped, propConfig.bone)
    AttachEntityToEntity(
        prop,
        cache.ped,
        bone,
        propConfig.pos.x,
        propConfig.pos.y,
        propConfig.pos.z,
        propConfig.rot.x,
        propConfig.rot.y,
        propConfig.rot.z,
        true, true, false, true, 1, true
    )
    
    -- Aplicar animação se configurada
    if propConfig.anim then
        lib.requestAnimDict(propConfig.anim.dict, 5000)
        TaskPlayAnim(cache.ped, propConfig.anim.dict, propConfig.anim.clip, 3.0, 3.0, -1, propConfig.anim.flag or 49, 0, false, false, false)
        handPropAnims[itemName] = true
    end
    
    handProps[itemName] = prop
    Weed.Debug("Created hand prop for %s (count: %d)", itemName, itemCount)
end

-- Remover prop da mão (força remoção)
local function RemoveHandProp(itemName)
    local prop = handProps[itemName]
    
    -- Remove o prop
    if prop then
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
        handProps[itemName] = nil
    end
    
    -- Parar animação
    if handPropAnims[itemName] then
        ClearPedTasks(cache.ped)
        handPropAnims[itemName] = nil
    end
    
    Weed.Debug("Removed hand prop for %s", itemName)
end

-- Remover todos os props
local function RemoveAllHandProps()
    local hadAnims = next(handPropAnims) ~= nil
    
    for itemName, prop in pairs(handProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    handProps = {}
    handPropAnims = {}
    
    -- Limpar animações
    if hadAnims then
        ClearPedTasks(cache.ped)
    end
    
    Weed.Debug("Removed all hand props")
end

-- Verificar e sincronizar props com inventário
local function SyncHandProps()
    if not Config.HandProps or not Config.HandProps.Items then return end
    
    local inVehicle = IsPedInAnyVehicle(cache.ped, false)
    local isDead = IsPedDeadOrDying(cache.ped, true)
    
    -- Em veículo ou morto, remove todos
    if inVehicle or isDead then
        if next(handProps) then
            RemoveAllHandProps()
        end
        return
    end
    
    -- Verifica cada item configurado
    for itemName, propConfig in pairs(Config.HandProps.Items) do
        local itemCount = GetItemCount(itemName)
        local hasProp = handProps[itemName] and DoesEntityExist(handProps[itemName])
        
        if itemCount > 0 then
            -- Tem o item, cria prop se não existir
            if not hasProp then
                CreateHandProp(itemName, propConfig)
            end
        else
            -- Não tem o item, SEMPRE remove prop
            if hasProp or handProps[itemName] then
                RemoveHandProp(itemName)
            end
        end
    end
    
    -- Limpa props órfãos (props que existem mas item não está mais configurado)
    for itemName, prop in pairs(handProps) do
        if not Config.HandProps.Items[itemName] then
            RemoveHandProp(itemName)
        end
    end
end

-- Thread de checagem de inventário para props
if Config.HandProps and Config.HandProps.Enabled then
    CreateThread(function()
        while true do
            Wait(handPropCheckInterval)
            SyncHandProps()
        end
    end)
    
    -- Cleanup quando resource para
    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            RemoveAllHandProps()
        end
    end)
    
    -- Evento para atualização imediata quando inventário muda (ox_inventory)
    AddEventHandler('ox_inventory:itemCount', function(itemName, count)
        if not Config.HandProps.Items[itemName] then return end
        
        -- Aguarda um pouco para garantir que o inventário atualizou
        Wait(100)
        
        local realCount = GetItemCount(itemName)
        if realCount <= 0 then
            RemoveHandProp(itemName)
        elseif not IsPedInAnyVehicle(cache.ped, false) and not IsPedDeadOrDying(cache.ped, true) then
            if not handProps[itemName] or not DoesEntityExist(handProps[itemName]) then
                CreateHandProp(itemName, Config.HandProps.Items[itemName])
            end
        end
    end)
    
    -- Evento quando inventário atualiza (backup) - checa todos os itens configurados
    AddEventHandler('ox_inventory:updateInventory', function(changes)
        if not changes then return end
        
        -- Aguarda um pouco para garantir que o inventário atualizou
        Wait(100)
        SyncHandProps()
    end)
    
    -- Evento quando remove item (força checagem)
    AddEventHandler('ox_inventory:removedItem', function(itemName, count)
        if not Config.HandProps.Items[itemName] then return end
        
        Wait(100)
        local realCount = GetItemCount(itemName)
        if realCount <= 0 then
            RemoveHandProp(itemName)
        end
    end)
    
    -- Evento quando usa item
    AddEventHandler('ox_inventory:usedItem', function(itemName, slot, metadata)
        if not Config.HandProps.Items[itemName] then return end
        
        Wait(100)
        local realCount = GetItemCount(itemName)
        if realCount <= 0 then
            RemoveHandProp(itemName)
        end
    end)
    
    -- Checagem rápida quando inventário fecha
    AddEventHandler('ox_inventory:closed', function()
        Wait(100)
        SyncHandProps()
    end)
    
    -- Quando jogador spawna ou revive
    AddEventHandler('playerSpawned', function()
        Wait(500)
        SyncHandProps()
    end)
    
    -- Quando jogador morre
    AddStateBagChangeHandler('isDead', nil, function(bagName, key, value, _unused, replicated)
        if bagName ~= ('player:%s'):format(cache.serverId) then return end
        
        if value then
            RemoveAllHandProps()
        else
            Wait(1000)
            SyncHandProps()
        end
    end)
end

Weed.Debug("Client items loaded")