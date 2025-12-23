-- QBX Weed System - Client Main
local QBX = exports.qbx_core
local currentPed = cache.ped

-- Load locales on resource start
Weed.LoadLocale()

-- Initialize
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end
    
    Wait(2000)
    
    -- Load strains from server
    local strains = lib.callback.await('Ferp-Weed:server:getStrains', false)
    if strains then
        Weed.Strains.Created = strains
    end
    
    Weed.Plants.ConfigReady = true

end)

-- Update current ped cache
CreateThread(function()
    while true do
        currentPed = cache.ped
        Wait(1000)
    end
end)

-- Receive strain updates from server
RegisterNetEvent('Ferp-Weed:client:loadStrains', function(strains)
    Weed.Strains.Created = strains

end)

-- Helper function to get closest player
function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = radius or 5.0
    local closestPlayer = -1
    local coords = GetEntityCoords(currentPed)
    
    for _, player in ipairs(players) do
        local target = GetPlayerPed(player)
        if target ~= currentPed then
            local targetCoords = GetEntityCoords(target)
            local distance = #(coords - targetCoords)
            if distance < closestDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end
    
    return closestPlayer, closestDistance
end

-- Animation helper
function PlayAnimation(dict, name, duration, flag)
    flag = flag or 1
    duration = duration or -1
    
    lib.requestAnimDict(dict, 5000)
    TaskPlayAnim(currentPed, dict, name, 8.0, -8.0, duration, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end

-- Scenario helper
function PlayScenario(scenario, duration)
    duration = duration or -1
    TaskStartScenarioInPlace(currentPed, scenario, 0, true)
    
    if duration > 0 then
        Wait(duration)
        ClearPedTasks(currentPed)
    end
end

-- Progress helper with full options
function ShowProgress(options)
    local defaults = {
        duration = 5000,
        label = 'Processing...',
        useWhileDead = false,
        canCancel = true,
        position = Config.ProgressPosition or 'bottom',
        disable = {
            move = false,
            car = false,
            combat = false,
            mouse = false
        },
        anim = {},
        prop = {}
    }
    
    -- Merge options
    for k, v in pairs(options) do
        defaults[k] = v
    end
    
    if Config.ProgressType == 'circle' then
        return lib.progressCircle(defaults)
    else
        return lib.progressBar(defaults)
    end
end

-- Vehicle door helper
function OpenVehicleDoor(vehicle, door)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorOpen(vehicle, door, false, false)
    end
end

function CloseVehicleDoor(vehicle, door)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorShut(vehicle, door, false)
    end
end

-- Get ground material
function GetGroundMaterial(coords)
    local retval, groundZ, material = GetGroundZAndNormalFor_3dCoord(coords.x, coords.y, coords.z + 1.0)
    return material
end

-- Check if in building
function IsPlayerInBuilding()
    local interior = GetInteriorFromEntity(currentPed)
    return interior ~= 0
end

-- Exports
exports('GetClosestPlayer', GetClosestPlayer)
exports('PlayAnimation', PlayAnimation)
exports('PlayScenario', PlayScenario)
exports('ShowProgress', ShowProgress)

