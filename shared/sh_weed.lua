Weed = {}

local Locales = {}

function Weed.LoadLocale()
    local locale = Config.Locale or 'pt'
    local file = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. locale .. '.json')
    if file then
        Locales = json.decode(file) or {}
    else
        print('[FERP_WEED] Locale file not found: ' .. locale .. '.json')
    end
end

function Weed.Locale(category, key, ...)
    if Locales[category] and Locales[category][key] then
        local text = Locales[category][key]
        if ... then
            return string.format(text, ...)
        end
        return text
    end
    return key
end

-- Shorthand for locale
function Lang(category, key, ...)
    return Weed.Locale(category, key, ...)
end

-- Utility Functions
function Weed.Debug(message, ...)
    if not Config.Debug then return end
    
    local params = {}
    for _, param in ipairs({...}) do
        if type(param) == "table" then
            param = json.encode(param, {indent = true})
        end
        params[#params + 1] = tostring(param)
    end
    
    print(string.format("[QBX-WEED DEBUG] " .. message, table.unpack(params)))
end

function Weed.Notify(src, message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    if IsDuplicityVersion() then
        -- Server side
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Weed System',
            description = message,
            type = type,
            duration = duration
        })
    else
        -- Client side
        lib.notify({
            title = 'Weed System',
            description = message,
            type = type,
            duration = duration
        })
    end
end

function Weed.GetPlayerIdentifier(src)
    if not src then return nil end
    return exports.qbx_core:GetPlayer(src)?.PlayerData?.citizenid
end

function Weed.HasItem(src, item, amount)
    amount = amount or 1
    
    if IsDuplicityVersion() then
        -- Server side - usa GetItem
        local hasItem = exports.ox_inventory:GetItem(src, item, nil, true)
        return hasItem >= amount
    else
        -- Client side - usa Search
        local count = exports.ox_inventory:Search('count', item)
        return count >= amount
    end
end

function Weed.AddItem(src, item, amount, metadata)
    amount = amount or 1
    metadata = metadata or {}
    return exports.ox_inventory:AddItem(src, item, amount, metadata)
end

function Weed.RemoveItem(src, item, amount, metadata, slot)
    amount = amount or 1
    if slot then
        return exports.ox_inventory:RemoveItem(src, item, amount, metadata, slot)
    else
        return exports.ox_inventory:RemoveItem(src, item, amount, metadata)
    end
end

function Weed.GetItemSlot(src, item, metadata)
    local items = exports.ox_inventory:GetInventoryItems(src)
    for slot, itemData in pairs(items) do
        if itemData.name == item then
            if metadata then
                local match = true
                for k, v in pairs(metadata) do
                    if itemData.metadata[k] ~= v then
                        match = false
                        break
                    end
                end
                if match then return slot, itemData end
            else
                return slot, itemData
            end
        end
    end
    return nil
end

-- Hash function for strain generation
function Weed.Hash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) & 0xFFFFFFFF
    end
    return hash
end

-- Check if player is police
function Weed.IsPolice(src)
    if not IsDuplicityVersion() then return false end
    
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false end
    
    local jobName = Player.PlayerData.job and Player.PlayerData.job.name or ''
    for _, job in ipairs(Config.PoliceJobs or {'police', 'sheriff'}) do
        if jobName == job then
            return true
        end
    end
    return false
end

-- Get player coords
function Weed.GetPlayerCoords(src)
    if IsDuplicityVersion() then
        return GetEntityCoords(GetPlayerPed(src))
    else
        return GetEntityCoords(cache.ped)
    end
end