corneringActive = false 
corneringPeds = {} 
local corneringCoords = nil
local corneringZone = nil
local corneringVehicle = nil
local customerThreadActive = false
local salesCount = 0 

-- Configuração de eventos aleatórios 
local RandomEvents = {
    Chances = {
        clienteDesiste = 0.08,      
        clienteSemDinheiro = 0.06,  
        clientePechincha = 0.12,    
        clienteCompraExtra = 0.10,  
        policiaPerto = 0.05,        
        clienteBebado = 0.08,       
        clienteAssustado = 0.06,
        gorjetaExtra = 0.07,        
        clienteConhecido = 0.05,
    },
    
    -- Chaves de locale para pechincha
    PechinchaKeys = { 'client_haggle_1', 'client_haggle_2', 'client_haggle_3', 'client_haggle_4' },
    
    -- Chaves de locale para bêbado
    BebadoKeys = { 'client_drunk_1', 'client_drunk_2', 'client_drunk_3' },
    
    -- Chaves de locale para assustado
    AssustadoKeys = { 'client_scared_1', 'client_scared_2', 'client_scared_3' },
}

local function ProcessRandomEvent(ped)
    local roll = math.random()
    local cumulativeChance = 0
    
    -- Cliente desiste
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clienteDesiste
    if roll < cumulativeChance then
        return {
            type = "desiste",
            message = Lang('events', 'client_gave_up'),
            cancel = true,
            money = 0
        }
    end
    
    -- Cliente sem dinheiro
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clienteSemDinheiro
    if roll < cumulativeChance then
        return {
            type = "sem_dinheiro",
            message = Lang('events', 'client_no_money'),
            cancel = true,
            money = 0
        }
    end
    
    -- Cliente pechincha
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clientePechincha
    if roll < cumulativeChance then
        local key = RandomEvents.PechinchaKeys[math.random(#RandomEvents.PechinchaKeys)]
        return {
            type = "pechincha",
            message = Lang('events', key),
            cancel = false,
            moneyMult = 0.7  -- 70% do valor
        }
    end
    
    -- Cliente quer comprar mais
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clienteCompraExtra
    if roll < cumulativeChance then
        return {
            type = "compra_extra",
            message = Lang('events', 'client_extra'),
            cancel = false,
            extraSale = true
        }
    end
    
    -- Polícia passa perto
    cumulativeChance = cumulativeChance + RandomEvents.Chances.policiaPerto
    if roll < cumulativeChance then
        return {
            type = "policia",
            message = Lang('events', 'police_nearby'),
            cancel = false,
            tension = true
        }
    end
    
    -- Cliente bêbado
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clienteBebado
    if roll < cumulativeChance then
        local key = RandomEvents.BebadoKeys[math.random(#RandomEvents.BebadoKeys)]
        return {
            type = "bebado",
            message = Lang('events', key),
            cancel = false,
            slowSale = true
        }
    end
    
    -- Cliente assustado foge
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clienteAssustado
    if roll < cumulativeChance then
        local key = RandomEvents.AssustadoKeys[math.random(#RandomEvents.AssustadoKeys)]
        return {
            type = "assustado",
            message = Lang('events', key),
            cancel = true,
            flee = true,
            money = 0
        }
    end
    
    -- Gorjeta extra
    cumulativeChance = cumulativeChance + RandomEvents.Chances.gorjetaExtra
    if roll < cumulativeChance then
        return {
            type = "gorjeta",
            message = Lang('events', 'client_tip'),
            cancel = false,
            moneyMult = 1.5  -- 150% do valor
        }
    end
    
    -- Cliente conhecido
    cumulativeChance = cumulativeChance + RandomEvents.Chances.clienteConhecido
    if roll < cumulativeChance then
        return {
            type = "conhecido",
            message = Lang('events', 'client_regular'),
            cancel = false,
            fastSale = true,
            moneyMult = 0.9
        }
    end
    
    -- Venda normal
    return {
        type = "normal",
        cancel = false
    }
end

-- Export para verificar estado
exports('IsCorneringActive', function()
    return corneringActive
end)

exports('GetCorneringPeds', function()
    return corneringPeds
end)

-- Get random idle animation
local function GetRandomIdle()
    return Weed.Cornering.GetRandomAnimation()
end

-- Start cornering
RegisterNetEvent('Ferp-Weed:client:startCornering', function(vehicle)
    Weed.Debug("[CORNERING] Evento startCornering recebido, vehicle: %s", vehicle)
    
    if corneringActive then
        Weed.Debug("[CORNERING] Já está vendendo, retornando")
        return Weed.Notify(nil, Lang('notify', 'already_selling'), 'error')
    end
    
    -- Bloqueia motos e bicicletas
    if vehicle and DoesEntityExist(vehicle) then
        local vehClass = GetVehicleClass(vehicle)
        if vehClass == 8 or vehClass == 13 or vehClass == 14 then
            Weed.Debug("[CORNERING] Veículo é moto/bicicleta, bloqueando")
            return Weed.Notify(nil, Lang('notify', 'cannot_sell_motorcycle'), 'error')
        end
    end
    
    if not Weed.HasItem(cache.serverId, 'weed_baggie', 1) then
        Weed.Debug("[CORNERING] Sem saquinhos no inventário")
        return Weed.Notify(nil, Lang('notify', 'need_baggies_to_sell'), 'error')
    end
    
    corneringCoords = GetEntityCoords(cache.ped)
    corneringZone = GetNameOfZone(corneringCoords)
    
    Weed.Debug("[CORNERING] Zona atual: %s", corneringZone)
    
    if not Weed.Cornering.IsZoneAllowed(corneringZone) then
        Weed.Debug("[CORNERING] Zona não permitida: %s", corneringZone)
        return Weed.Notify(nil, Lang('notify', 'no_buyers'), 'error')
    end
    
    Weed.Debug("[CORNERING] Zona permitida, chamando callback do servidor")
    local success = lib.callback.await('Ferp-Weed:server:startCornering', false, corneringCoords, corneringZone)
    
    if not success then
        Weed.Debug("[CORNERING] Servidor recusou - alguém já vendendo na área")
        return Weed.Notify(nil, Lang('notify', 'area_occupied'), 'error')
    end
    
    Weed.Debug("[CORNERING] Servidor aprovou, iniciando venda")
    corneringActive = true
    corneringVehicle = vehicle
    
    -- Open vehicle trunk
    Weed.Debug("[CORNERING] Abrindo porta-malas do veículo")
    if DoesEntityExist(vehicle) then
        SetVehicleDoorOpen(vehicle, 5, false, false)
        Weed.Debug("[CORNERING] Porta-malas aberto com sucesso")
    else
        Weed.Debug("[CORNERING] ERRO: Veículo não existe!")
    end
    
    Weed.Notify(nil, Lang('notify', 'started_selling'), 'success')
    
    -- Start customer acquisition loop
    Weed.Debug("[CORNERING] Iniciando loop de clientes")
    StartCustomerLoop()
    
    -- Start dead customer cleanup loop
    StartDeadCustomerCleanup()
end)

-- Cleanup dead customers thread
function StartDeadCustomerCleanup()
    CreateThread(function()
        while corneringActive do
            Wait(2000) -- Check every 2 seconds
            
            for ped, _ in pairs(corneringPeds) do
                if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then
                    -- Remove dead/invalid ped from list
                    corneringPeds[ped] = nil
                    Weed.Debug("[CORNERING] Removed dead/invalid customer from list")
                    
                    if DoesEntityExist(ped) then
                        SetEntityAsNoLongerNeeded(ped)
                    end
                end
            end
        end
    end)
end

-- Stop cornering
function StopCornering()
    if not corneringActive then return end
    
    -- Fechar porta-malas do veículo
    if corneringVehicle and DoesEntityExist(corneringVehicle) then
        SetVehicleDoorShut(corneringVehicle, 5, false)
    end
    
    -- Clean up peds
    for ped, _ in pairs(corneringPeds) do
        if DoesEntityExist(ped) then
            SetEntityAsNoLongerNeeded(ped)
            SetPedKeepTask(ped, false)
        end
    end
    
    corneringPeds = {}
    corneringActive = false
    corneringCoords = nil
    corneringVehicle = nil
    corneringZone = nil
    customerThreadActive = false
    
    TriggerServerEvent('Ferp-Weed:server:stopCornering')
    Weed.Notify(nil, Lang('notify', 'stopped_selling'), 'info')
end

-- Customer acquisition loop
function StartCustomerLoop()
    if customerThreadActive then 
        -- print('[CORNERING] Loop já ativo, retornando')
        return 
    end
    customerThreadActive = true
    
    -- print('[CORNERING] Iniciando loop de clientes')
    
    -- Thread de verificação de distância (mais rápida)
    CreateThread(function()
        while corneringActive do
            Wait(1000) -- Verifica a cada 1 segundo
            
            if not corneringActive then break end
            
            local playerCoords = GetEntityCoords(cache.ped)
            
            -- Verifica se está em veículo (não pode vender de dentro do carro)
            if IsPedInAnyVehicle(cache.ped, false) then
                Weed.Notify(nil, Lang('notify', 'cannot_sell_in_vehicle'), 'error')
                StopCornering()
                return
            end
            
            -- Verifica distância do veículo
            if corneringVehicle and DoesEntityExist(corneringVehicle) then
                local vehicleCoords = GetEntityCoords(corneringVehicle)
                local distToVehicle = #(playerCoords - vehicleCoords)
                
                if distToVehicle > 60.0 then
                    Weed.Notify(nil, Lang('notify', 'too_far_from_vehicle'), 'error')
                    StopCornering()
                    return
                end
            else
                -- Veículo sumiu
                Weed.Notify(nil, Lang('notify', 'vehicle_gone'), 'error')
                StopCornering()
                return
            end
            
            -- Verifica distância do ponto inicial
            if corneringCoords then
                local distToStart = #(playerCoords - corneringCoords)
                if distToStart > 80.0 then
                    Weed.Notify(nil, Lang('notify', 'too_far_from_spot'), 'error')
                    StopCornering()
                    return
                end
            end
        end
    end)
    
    -- Thread principal de aquisição de clientes
    CreateThread(function()
        local notFoundCount = 0
        local dealerRep = lib.callback.await('Ferp-Weed:server:getDealerReputation', false)
        local timer = dealerRep and dealerRep.timer or Weed.Cornering.Config.TimeBetweenAcquisition
        
        -- print('[CORNERING] Timer entre clientes: ' .. timer .. ' segundos')
        
        while corneringActive do
            -- print('[CORNERING] Aguardando ' .. timer .. 's para próximo cliente...')
            Wait(timer * 1000)
            
            if not corneringActive then break end
            
            -- Find a suitable ped
            local foundPed = nil
            local peds = GetGamePool('CPed')
            
            -- print('[CORNERING] Procurando ped... Total de peds: ' .. #peds)
            
            for _, ped in ipairs(peds) do
                if DoesEntityExist(ped) and
                   not IsPedDeadOrDying(ped, true) and
                   not IsPedAPlayer(ped) and
                   not IsPedFleeing(ped) and
                   IsPedOnFoot(ped) and
                   not IsPedInAnyVehicle(ped, true) and
                   IsPedHuman(ped) and
                   not IsPedInMeleeCombat(ped) and
                   corneringPeds[ped] == nil and
                   #(corneringCoords - GetEntityCoords(ped)) < 100.0 then
                    foundPed = ped
                    notFoundCount = 0
                    -- print('[CORNERING] Ped encontrado!')
                    break
                end
            end
            
            if not foundPed then
                notFoundCount = notFoundCount + 1
                -- print('[CORNERING] Nenhum ped encontrado. Tentativas falhas: ' .. notFoundCount)
                
                if notFoundCount > 7 then
                    Weed.Notify(nil, Lang('notify', 'location_dried'), 'error')
                    StopCornering()
                    return
                end
            else
                -- Tenta encontrar um ponto válido na estrada
                local roadCoords = nil
                
                -- Método 1: GetPointOnRoadSide
                local retval, point = GetPointOnRoadSide(corneringCoords.x, corneringCoords.y, corneringCoords.z, 1)
                if retval and point then
                    roadCoords = point
                    -- print('[CORNERING] GetPointOnRoadSide sucesso!')
                else
                    -- print('[CORNERING] GetPointOnRoadSide falhou, tentando alternativas...')
                    
                    -- Método 2: GetClosestVehicleNode
                    local found, nodeCoords = GetClosestVehicleNode(corneringCoords.x, corneringCoords.y, corneringCoords.z, 1, 3.0, 0)
                    if found then
                        roadCoords = nodeCoords
                        -- print('[CORNERING] GetClosestVehicleNode sucesso!')
                    else
                        -- Método 3: GetNthClosestVehicleNode
                        local found2, nodeCoords2 = GetNthClosestVehicleNode(corneringCoords.x, corneringCoords.y, corneringCoords.z, 2, 1, 3.0, 0)
                        if found2 then
                            roadCoords = nodeCoords2
                            -- print('[CORNERING] GetNthClosestVehicleNode sucesso!')
                        else
                            -- Método 4: Posição próxima do veículo (fallback)
                            if corneringVehicle and DoesEntityExist(corneringVehicle) then
                                local vehCoords = GetEntityCoords(corneringVehicle)
                                local vehHeading = GetEntityHeading(corneringVehicle)
                                -- Pega ponto atrás do veículo
                                local offsetX = vehCoords.x - math.sin(math.rad(vehHeading)) * 3.0
                                local offsetY = vehCoords.y + math.cos(math.rad(vehHeading)) * 3.0
                                roadCoords = vector3(offsetX, offsetY, vehCoords.z)
                                -- print('[CORNERING] Usando posição atrás do veículo como fallback')
                            else
                                -- Método 5: Posição próxima do player (último fallback)
                                local playerCoords = GetEntityCoords(cache.ped)
                                roadCoords = vector3(playerCoords.x + math.random(-3, 3), playerCoords.y + math.random(-3, 3), playerCoords.z)
                                -- print('[CORNERING] Usando posição próxima do player como fallback')
                            end
                        end
                    end
                end
                
                if roadCoords then
                    corneringPeds[foundPed] = true
                    -- print('[CORNERING] Enviando cliente para servidor')
                    TriggerServerEvent('Ferp-Weed:server:sendCustomer', roadCoords, NetworkGetNetworkIdFromEntity(foundPed))
                else
                    -- print('[CORNERING] ERRO: Não conseguiu encontrar nenhuma posição válida')
                end
            end
        end
        
        customerThreadActive = false
    end)
end

-- Customer walks to player
RegisterNetEvent('Ferp-Weed:client:customerApproach', function(pedNetId, coords)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not DoesEntityExist(ped) then 
        -- print('[CORNERING] Ped do evento customerApproach não existe')
        return 
    end
    
    -- Garantir que o ped está na lista (pode ter handle diferente após passar pelo servidor)
    if not corneringPeds[ped] then
        corneringPeds[ped] = true
        -- print('[CORNERING] Ped adicionado à lista via customerApproach (handle: ' .. tostring(ped) .. ')')
    end
    
    ClearPedTasks(ped)
    
    local anim = GetRandomIdle()
    lib.requestAnimDict(anim.dict, 5000)
    
    local playerCoords = GetEntityCoords(cache.ped)
    
    TaskGoToEntity(ped, cache.ped, -1, 1.5, 1.0, 1073741824, 0)
    SetPedKeepTask(ped, true)
    
    -- Wait for ped to arrive
    CreateThread(function()
        local timeout = 45000 -- 45 segundos de timeout
        local arrived = false
        
        while timeout > 0 and not arrived do
            Wait(200)
            timeout = timeout - 200
            
            if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then
                corneringPeds[ped] = nil
                return
            end
            
            local pedCoords = GetEntityCoords(ped)
            local currentPlayerCoords = GetEntityCoords(cache.ped)
            local dist = #(pedCoords - currentPlayerCoords)
            
            if dist < 2.5 then
                arrived = true
                break
            end
            
            if dist > 5.0 then
                TaskGoToEntity(ped, cache.ped, -1, 1.5, 1.0, 1073741824, 0)
            end
        end
        
        if not arrived then
            -- print('[CORNERING] Cliente não conseguiu chegar, removendo...')
            corneringPeds[ped] = nil
            SetEntityAsNoLongerNeeded(ped)
            return
        end
        
        ClearPedTasks(ped)
        TaskTurnPedToFaceEntity(ped, cache.ped, 2000)
        Wait(1500)
        
        TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, -1, 1, 0, false, false, false)
        SetPedKeepTask(ped, true)
        SetEntityAsMissionEntity(ped, true, true)
        
        -- print('[CORNERING] Cliente chegou e está esperando (handle: ' .. tostring(ped) .. ')')
        
        SetTimeout(120000, function()
            if DoesEntityExist(ped) then
                corneringPeds[ped] = nil
                SetEntityAsNoLongerNeeded(ped)
                SetPedKeepTask(ped, false)
            end
        end)
    end)
end)

-- Sell to customer
function SellToCustomer(entity)
    if not DoesEntityExist(entity) or IsPedDeadOrDying(entity, true) then
        return Weed.Notify(nil, Lang('notify', 'invalid_customer'), 'error')
    end
    
    if not Weed.HasItem(cache.serverId, 'weed_baggie', 1) then
        return Weed.Notify(nil, Lang('notify', 'need_baggies_to_sell'), 'error')
    end
    
    if not corneringPeds[entity] then
        return Weed.Notify(nil, Lang('notify', 'not_customer'), 'error')
    end
    
    -- Processar evento aleatório
    local event = ProcessRandomEvent(entity)
    salesCount = salesCount + 1
    
    -- Se o evento cancela a venda
    if event.cancel then
        corneringPeds[entity] = nil
        
        if event.message then
            Weed.Notify(nil, event.message, 'error')
        end
        
        -- Cliente foge assustado
        if event.flee then
            TaskSmartFleePed(entity, cache.ped, 100.0, -1, false, false)
            SetPedKeepTask(entity, true)
        else
            -- Cliente vai embora normalmente
            TaskWanderStandard(entity, 10.0, 10)
        end
        
        -- Limpar ped após 30 segundos
        SetTimeout(30000, function()
            if DoesEntityExist(entity) then
                SetEntityAsNoLongerNeeded(entity)
                SetPedKeepTask(entity, false)
            end
        end)
        
        return
    end
    
    corneringPeds[entity] = false
    
    if event.message then
        Weed.Notify(nil, event.message, event.type == "policia" and 'warning' or 'info')
    end

    if event.tension then
        CreateThread(function()
            local playerCoords = GetEntityCoords(cache.ped)
            local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 50.0, 50.0, 0.0)
            
            local vehModel = `police`
            lib.requestModel(vehModel, 5000)
            
            local vehicle = CreateVehicle(vehModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
            
            if vehicle and DoesEntityExist(vehicle) then
                local pedModel = `s_m_y_cop_01`
                lib.requestModel(pedModel, 5000)
                
                local cop = CreatePedInsideVehicle(vehicle, 4, pedModel, -1, true, false)
                
                if cop and DoesEntityExist(cop) then
                    SetPedRandomComponentVariation(cop, 0)
                    TaskVehicleDriveWander(cop, vehicle, 15.0, 786603)
                    
                    SetTimeout(30000, function()
                        if DoesEntityExist(vehicle) then
                            DeleteEntity(vehicle)
                        end
                        if DoesEntityExist(cop) then
                            DeleteEntity(cop)
                        end
                    end)
                end
            end
        end)
    end
    
    local animDuration = 2000
    if event.slowSale then
        animDuration = 4000
        PlayAmbientSpeech1(entity, "GENERIC_DRUNK_HIGH", "Speech_Params_Force")
    elseif event.fastSale then
        animDuration = 1000
    end
    
    SetPedCanRagdoll(cache.ped, false)
    
    if not event.slowSale then
        PlayAmbientSpeech1(entity, "Generic_Hi", "Speech_Params_Force")
    end
    
    TaskTurnPedToFaceEntity(cache.ped, entity, 1000)
    Wait(500)
    
    lib.requestAnimDict('mp_safehouselost@', 5000)
    TaskPlayAnim(cache.ped, 'mp_safehouselost@', 'package_dropoff', 8.0, -8.0, -1, 16, 0, false, false, false)
    
    TriggerServerEvent('Ferp-Weed:server:customerHandoff', NetworkGetNetworkIdFromEntity(entity))
    
    Wait(animDuration)
    ClearPedTasks(cache.ped)
    SetPedCanRagdoll(cache.ped, true)
    
    if math.random() < Config.EvidenceChance then
        local evidences = Config.EvidenceTypes
        local coords = GetEntityCoords(cache.ped)
        
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
        TriggerServerEvent('Ferp-Weed:server:createEvidence', {
            coords = vector3(coords.x, coords.y, coords.z - 0.9),
            type = 'weed',
            item = evidences[math.random(#evidences)]
        })
    end
    
    local moneyMult = event.moneyMult or 1.0
    local quantity = event.extraSale and 2 or 1
    
    TriggerServerEvent('Ferp-Weed:server:sellBaggie', NetworkGetNetworkIdFromEntity(entity), corneringZone, moneyMult, quantity)
    
    if event.extraSale then
        Wait(500)
        Weed.Notify(nil, Lang('notify', 'sold_baggies', 2), 'success')
    end
    
    PlayAmbientSpeech1(entity, "Chat_State", "Speech_Params_Force")
end

-- Customer handoff animation
RegisterNetEvent('Ferp-Weed:client:customerHandoff', function(pedNetId)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not DoesEntityExist(ped) then return end
    
    local relation = GetPedRelationshipGroupHash(ped)
    SetRelationshipBetweenGroups(0, `PLAYER`, relation)
    SetRelationshipBetweenGroups(0, relation, `PLAYER`)
    
    lib.requestAnimDict('mp_safehouselost@', 5000)
    ClearPedTasks(ped)
    
    TaskTurnPedToFaceEntity(ped, cache.ped, 3000)
    Wait(500)
    TaskPlayAnim(ped, 'mp_safehouselost@', 'package_dropoff', 8.0, -8.0, -1, 0, 0, false, false, false)
    
    Wait(2000)
    TaskWanderStandard(ped, 10.0, 10)
    SetPedKeepTask(ped, true)
end)

function PrepareBaggies(vehicle)
    local budsNeeded = Weed.Cornering.Config.BudsPerPrepare
    local baggiesNeeded = Weed.Cornering.Config.BaggiesPerBud * budsNeeded
    
    if not Weed.HasItem(cache.serverId, 'weed_bud', budsNeeded) then
        return Weed.Notify(nil, Lang('notify', 'need_buds', budsNeeded), 'error')
    end
    
    if not Weed.HasItem(cache.serverId, 'empty_baggie', baggiesNeeded) then
        return Weed.Notify(nil, Lang('notify', 'need_baggies', baggiesNeeded), 'error')
    end
    
    if not Weed.HasItem(cache.serverId, 'scale', 1) then
        return Weed.Notify(nil, Lang('notify', 'need_scale'), 'error')
    end
    
    TaskTurnPedToFaceEntity(cache.ped, vehicle, 0)
    Wait(500)
    
    local success = ShowProgress({
        duration = 30000,
        label = Lang('progress', 'preparing_baggies'),
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
            {
                model = `sf_prop_sf_bag_weed_open_01b`,
                bone = 18905,
                pos = vec3(0.08, -0.07, 0.12),
                rot = vec3(79.16, 86.16, 167.33)
            },
            {
                model = `bkr_prop_weed_bud_pruned_01a`,
                bone = 58866,
                pos = vec3(0.09, -0.02, -0.03),
                rot = vec3(0.0, 0.0, 0.0)
            }
        }
    })
    
    if not success then return end
    
    TriggerServerEvent('Ferp-Weed:server:prepareBaggies')
end

-- Exports
exports('StopCornering', StopCornering)
exports('SellToCustomer', SellToCustomer)
exports('PrepareBaggies', PrepareBaggies)

-- Register event handlers
RegisterNetEvent('Ferp-Weed:client:stopCornering', StopCornering)

Weed.Debug("Client cornering loaded")