Weed.Strains = {}

-- Configuration
Weed.Strains.Config = {
    UpdateTimer = 10 * 60 * 1000, -- 10 minutes
    MaxStrainsPerPlayer = 5,
    
    -- 6 Default Strains
    DefaultStrains = {
        { name = "OG Kush", n = 0.60, p = 0.50, k = 0.40 },
        { name = "White Widow", n = 0.45, p = 0.70, k = 0.55 },
        { name = "Purple Haze", n = 0.55, p = 0.45, k = 0.65 },
        { name = "Sour Diesel", n = 0.70, p = 0.40, k = 0.50 },
        { name = "Blue Dream", n = 0.50, p = 0.60, k = 0.45 },
        { name = "Northern Lights", n = 0.40, p = 0.55, k = 0.70 },
    },
    
    -- NPC Locations
    -- The NPC spawns at a random location from this list each server restart
    NPCLocations = {
        { name = "Praia de Vespucci", coords = vector4(-1098.86, -1676.23, 3.51, 130.2), scenario = "WORLD_HUMAN_STAND_IMPATIENT" },
        { name = "Sandy Shores", coords = vector4(1995.42, 3794.78, 31.21, 84.18), scenario = "WORLD_HUMAN_SMOKING" },
        { name = "Paleto Bay", coords = vector4(-188.55, 6268.45, 30.49, 11.55), scenario = "WORLD_HUMAN_HANG_OUT_STREET" },
        { name = "Mirror Park", coords = vector4(1111.2, -340.27, 66.15, 324.81), scenario = "WORLD_HUMAN_DRUG_DEALER" },
        { name = "La Mesa", coords = vector4(699.05, -997.58, 22.52, 40.89), scenario = "WORLD_HUMAN_STAND_IMPATIENT" },
        { name = "Del Perro Pier", coords = vector4(-1639.48, -1033.38, 12.15, 42.3), scenario = "WORLD_HUMAN_SMOKING" },
        { name = "Vinewood Hills", coords = vector4(598.34, 163.52, 97.27, 158.43), scenario = "WORLD_HUMAN_HANG_OUT_STREET" },
    },
    
    -- Current NPC location index
    CurrentNPCIndex = nil,
    
    -- Reputation Levels
    Reputations = {
        [0] = {
            name = "Common",
            canChangeName = false,
        },
        [100] = {
            name = "Superior",
            canChangeName = false,
        },
        [250] = {
            name = "Premium",
            canChangeName = false,
        },
        [500] = {
            name = "Epic",
            canChangeName = true,
        },
        [1000] = {
            name = "Supreme",
            canChangeName = true,
        },
        [15000] = {
            name = "Ascendant",
            canChangeName = true,
        },
        [25000] = {
            name = "Imperial",
            canChangeName = true,
        },
        [50000] = {
            name = "Unrivaled",
            canChangeName = true,
        },
        [100000] = {
            name = "Mythic",
            canChangeName = true,
        },
    }
}

-- Strain Name Generation Lists
Weed.Strains.NameParts = {
    First = {
        "Alien", "Arctic", "Atomic", "Banana", "Blazing",
        "Cali", "Cosmic", "Crazy", "Crystal", "Dark",
        "Diamond", "Dragon", "Dream", "Electric", "Fire",
        "Forbidden", "Frost", "Galactic", "Ghost", "Golden",
        "Gorilla", "Green", "Haze", "Honey", "Ice",
        "Jungle", "King", "Lava", "Lemon", "Lime",
        "Magic", "Mango", "Mellow", "Midnight", "Misty",
        "Moon", "Mystic", "Neon", "Night", "Nuclear",
        "Ocean", "Paradise", "Phantom", "Pineapple", "Pink",
        "Poison", "Power", "Purple", "Rainbow", "Red",
        "Royal", "Sacred", "Savage", "Shadow", "Silver",
        "Sky", "Sour", "Space", "Spicy", "Sticky",
        "Storm", "Strawberry", "Sugar", "Sun", "Super",
        "Sweet", "Thunder", "Toxic", "Tropical", "Turbo",
        "Ultra", "Vanilla", "Velvet", "Venom", "Wild",
        "Wonder", "Zen", "Zero", "Zombie", "Zone"
    },
    
    Second = {
        "Amnesia", "Blaze", "Blast", "Bomb", "Boost",
        "Brain", "Breeze", "Buddha", "Cake", "Candy",
        "Cheese", "Cherry", "Chill", "Cloud", "Cookie",
        "Cream", "Crush", "Daze", "Diesel", "Dope",
        "Dream", "Drop", "Dust", "Express", "Fantasy",
        "Flash", "Flow", "Force", "Frost", "Fuel",
        "Funk", "Fusion", "Glue", "Gold", "Grape",
        "Haze", "Heat", "High", "Hit", "Honey",
        "Ice", "Jack", "Jam", "Juice", "Kick",
        "King", "Kiss", "Kush", "Lady", "Leaf",
        "Life", "Light", "Love", "Lush", "Magic",
        "Mist", "Moon", "Nectar", "Night", "Nova",
        "OG", "Paradise", "Peace", "Peak", "Pie",
        "Punch", "Queen", "Rain", "Rush", "Sage",
        "Sauce", "Sherbet", "Skunk", "Slam", "Smoke",
        "Snow", "Sonic", "Soul", "Spark", "Spice",
        "Spirit", "Splash", "Star", "Stone", "Storm",
        "Sugar", "Sunrise", "Sunset", "Thunder", "Trance",
        "Trip", "Twist", "Vibe", "Wave", "Widow",
        "Wind", "Wolf", "Wrath", "Zen", "Zest"
    },
    
    Third = {
        "Bliss", "Bomb", "Boss", "Budz", "Chronic",
        "Cure", "Dank", "Delight", "Dream", "Elite",
        "Express", "Fire", "Flame", "Flash", "Flower",
        "Fuel", "Funk", "Ganja", "Gas", "Glory",
        "Gold", "Goods", "Green", "Haze", "Heaven",
        "Herb", "High", "Hit", "Hype", "Indica",
        "Juice", "Kief", "Kush", "Leaf", "Legend",
        "Life", "Light", "Lit", "Love", "Lush",
        "Magic", "Meds", "Mix", "Nectar", "Nugs",
        "OG", "Plant", "Plus", "Pot", "Power",
        "Prime", "Puff", "Pure", "Rush", "Sativa",
        "Smoke", "Soul", "Special", "Spirit", "Sticky",
        "Strain", "Supreme", "Therapy", "Thunder", "Toke",
        "Tree", "Vibe", "Wave", "Weed", "Zen"
    }
}

-- Data Storage
Weed.Strains.Created = {}
Weed.Strains.Time = "none"

-- Functions

-- Get a random default strain
function Weed.Strains.GetRandomDefault()
    local defaults = Weed.Strains.Config.DefaultStrains
    local index = math.random(1, #defaults)
    local selected = defaults[index]
    return {
        id = -index, -- Negative ID means default strain (e.g., -1 = OG Kush, -2 = White Widow, etc.)
        name = selected.name,
        n = selected.n,
        p = selected.p,
        k = selected.k,
        isDefault = true
    }
end

-- Get default strain by negative ID
function Weed.Strains.GetDefaultById(negativeId)
    local index = math.abs(negativeId)
    local defaults = Weed.Strains.Config.DefaultStrains
    if index >= 1 and index <= #defaults then
        local selected = defaults[index]
        return {
            id = negativeId,
            name = selected.name,
            n = selected.n,
            p = selected.p,
            k = selected.k,
            isDefault = true
        }
    end
    return nil
end

function Weed.Strains.GenerateName(n, p, k)
    local str = string.format("%s-%s-%s", tostring(n), tostring(p), tostring(k))
    local hash = Weed.Hash(str)
    
    local index1 = (((hash >> 16) & 0xFF) % (#Weed.Strains.NameParts.First))
    local first = Weed.Strains.NameParts.First[index1 + 1]
    
    local index2 = (((hash >> 8) & 0xFF) % (#Weed.Strains.NameParts.Second))
    local second = Weed.Strains.NameParts.Second[index2 + 1]
    
    local index3 = ((hash & 0xFF) % (#Weed.Strains.NameParts.Third))
    local third = Weed.Strains.NameParts.Third[index3 + 1]
    
    return string.format("%s %s %s", first, second, third)
end

function Weed.Strains.Get(id)
    if not id or id == 0 then return false end
    -- Try both number and string keys
    return Weed.Strains.Created[id] or Weed.Strains.Created[tonumber(id)] or Weed.Strains.Created[tostring(id)] or false
end

function Weed.Strains.GetByName(name)
    for id, strain in pairs(Weed.Strains.Created) do
        if strain.name == name then
            return strain
        end
    end
    return false
end

function Weed.Strains.GetByModifiers(n, p, k)
    for id, strain in pairs(Weed.Strains.Created) do
        if strain.n == n and strain.p == p and strain.k == k then
            return strain
        end
    end
    return false
end

function Weed.Strains.GetReputation(strain)
    local reputation = {name = "Common", canChangeName = false}
    local current = -1
    
    for required, data in pairs(Weed.Strains.Config.Reputations) do
        required = tonumber(required)
        if required <= strain.reputation and current < required then
            reputation = data
            current = required
        end
    end
    
    if reputation.name == "Mythic" and strain.rank == 1 then
        reputation.name = "Legendary"
    end
    
    return reputation
end