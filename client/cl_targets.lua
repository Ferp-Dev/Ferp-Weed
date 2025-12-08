local Target = exports.ox_target
local currentTime = "none"

-- Update current time
local function UpdateCurrentTime()
    local hours = GetClockHours()
    currentTime = (hours >= 7 and hours <= 20) and "day" or "night"
end

-- Wait for plants config to load
CreateThread(function()
    while not Weed.Plants.ConfigReady do
        Wait(100)
    end
    
    -- Initialize time
    UpdateCurrentTime()
    
    -- Setup all targets
    SetupVehicleTargets()
    SetupPedTargets()
    SetupNPCTargets()
    
    Weed.Debug("Targets initialized")
end)

-- Keep time updated
CreateThread(function()
    while true do
        Wait(60000)
        UpdateCurrentTime()
    end
end)

-- Vehicle Targets
function SetupVehicleTargets()
    -- Lista de classes de veículos proibidos
    local blockedVehicleClasses = {
        [8] = true,   -- Motorcycles
        [13] = true,  -- Cycles (bicicletas)
        [14] = true,  -- Boats
        [15] = true,  -- Helicopters
        [16] = true,  -- Planes
        [21] = true,  -- Trains
    }
    
    Target:addGlobalVehicle({
        {
            name = 'weed_start_cornering',
            label = Lang('menu', 'start_selling'),
            icon = 'fa-solid fa-handshake',
            distance = 3.0,
            items = {'weed_baggie'},
            canInteract = function(entity, distance, coords, name)
                -- Verifica básicas
                if not entity or not DoesEntityExist(entity) then return false end
                if corneringActive then return false end
                if IsPedInAnyVehicle(cache.ped, false) then return false end
                
                -- Bloqueia motos/bicicletas/etc
                local vehClass = GetVehicleClass(entity)
                if blockedVehicleClasses[vehClass] then return false end
                
                return true
            end,
            onSelect = function(data)
                print('[CORNERING DEBUG] ox_target clicado, disparando evento')
                TriggerEvent('Ferp-Weed:client:startCornering', data.entity)
            end
        },
        {
            name = 'weed_stop_cornering',
            label = Lang('menu', 'stop_selling'),
            icon = 'fa-solid fa-handshake-slash',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name)
                return corneringActive
            end,
            onSelect = function(data)
                exports.Ferp-Weed:StopCornering()
            end
        }
    })
end

-- Ped Targets (for cornering customers)
function SetupPedTargets()
    Target:addGlobalPed({
        {
            name = 'weed_sell_baggie',
            label = Lang('menu', 'sell_baggie'),
            icon = 'fa-solid fa-comment-dollar',
            distance = 2.5,
            items = {'weed_baggie'},
            canInteract = function(entity, distance, coords, name)
                -- Check if cornering is active and ped is a customer
                if not corneringActive then return false end
                if IsPedAPlayer(entity) then return false end
                local cornerPeds = corneringPeds or {}
                if not cornerPeds[entity] then return false end
                if cache.vehicle then return false end
                
                return true
            end,
            onSelect = function(data)
                exports.Ferp-Weed:SellToCustomer(data.entity)
            end
        }
    })
end

-- NPC Strain Dealer Target
function SetupNPCTargets()
    CreateThread(function()
        Wait(6000) -- Wait for NPC to spawn
        
        -- Get NPC location from server
        local npcData = lib.callback.await('Ferp-Weed:server:getNPCLocation', false)
        if not npcData then 
            Weed.Debug("No strain NPC data for targets")
            return 
        end
        
        local coords = npcData.coords
        
        -- Add target zone at NPC location
        Target:addSphereZone({
            coords = vec3(coords.x, coords.y, coords.z),
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'weed_npc_shop',
                    label = Lang('menu', 'buy_items'),
                    icon = 'fa-solid fa-shop',
                    distance = 2.0,
                    onSelect = function()
                        exports.Ferp-Weed:OpenWeedShop()
                    end
                },
                {
                    name = 'weed_npc_ranking',
                    label = Lang('menu', 'view_strain_ranking'),
                    icon = 'fa-solid fa-ranking-star',
                    distance = 2.0,
                    onSelect = function()
                        exports.Ferp-Weed:ShowStrainRanking()
                    end
                },
                {
                    name = 'weed_npc_manage',
                    label = Lang('menu', 'manage_my_strains'),
                    icon = 'fa-solid fa-leaf',
                    distance = 2.0,
                    onSelect = function()
                        exports.Ferp-Weed:ManageStrains()
                    end
                }
            }
        })
        
        Weed.Debug("Strain NPC target initialized at %s", npcData.name)
    end)
end

Weed.Debug("Client targets loaded")