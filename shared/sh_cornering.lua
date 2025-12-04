Weed.Cornering = {}

Weed.Cornering.Config = {
    -- Timing
    PopulateRate = 2, -- Minutes between ped spawns (-1 to disable)
    TimeBetweenAcquisition = 10, -- Seconds between customer acquisition 
    
    -- Processing
    BudsPerPrepare = 10, -- Buds needed to prepare baggies
    BaggiesPerBud = 3, -- Baggies created per bud
    
    -- Pricing
    BasePrice = {200, 300}, -- Min/Max base price
    DividerReputationBonus = 10000, -- Divider for reputation multiplier
    MaxReputationBonus = 2.0, -- Max reputation multiplier
    MaxZoneBonus = 1.2, -- Zone familiarity bonus
    
    -- Allowed Zones
    AllowedZones = {
        ["AIRP"] = "Los Santos International Airport",
        ["ALTA"] = "Alta",
        ["BANNING"] = "Banning",
        ["BEACH"] = "Vespucci Beach",
        ["BURTON"] = "Burton",
        ["CHAMH"] = "Chamberlain Hills",
        ["CHIL"] = "Vinewood Hills",
        ["CHU"] = "Chumash",
        ["CYPRE"] = "Cypress Flats",
        ["DAVIS"] = "Davis",
        ["DELBE"] = "Del Perro Beach",
        ["DELPE"] = "Del Perro",
        ["DELSOL"] = "La Puerta",
        ["DOWNT"] = "Downtown",
        ["DTVINE"] = "Downtown Vinewood",
        ["EAST_V"] = "East Vinewood",
        ["EBURO"] = "El Burro Heights",
        ["ELGORL"] = "El Gordo Lighthouse",
        ["ELYSIAN"] = "Elysian Island",
        ["GALFISH"] = "Galilee",
        ["GOLF"] = "GWC and Golfing Society",
        ["GRAPES"] = "Grapeseed",
        ["GREATC"] = "Great Chaparral",
        ["HARMO"] = "Harmony",
        ["HAWICK"] = "Hawick",
        ["HORS"] = "Vinewood Racetrack",
        ["KOREAT"] = "Little Seoul",
        ["LEGSQU"] = "Legion Square",
        ["LMESA"] = "La Mesa",
        ["LOSPUER"] = "La Puerta",
        ["MIRR"] = "Mirror Park",
        ["MORN"] = "Morningwood",
        ["MOVIE"] = "Richards Majestic",
        ["MURRI"] = "Murrieta Heights",
        ["NCHU"] = "North Chumash",
        ["PALETO"] = "Paleto Bay",
        ["PBLUFF"] = "Pacific Bluffs",
        ["PBOX"] = "Pillbox Hill",
        ["RANCHO"] = "Rancho",
        ["RGLEN"] = "Richman Glen",
        ["RICHM"] = "Richman",
        ["ROCKF"] = "Rockford Hills",
        ["SANDY"] = "Sandy Shores",
        ["SKID"] = "Mission Row",
        ["STAD"] = "Maze Bank Arena",
        ["STRAW"] = "Strawberry",
        ["TEXTI"] = "Textile City",
        ["VCANA"] = "Vespucci Canals",
        ["VESP"] = "Vespucci",
        ["VINE"] = "Vinewood",
        ["WVINE"] = "West Vinewood",
    },
    
    -- Ped Animations
    Animations = {
        {dict = "anim@mp_corona_idles@male_c@idle_a", name = "idle_a"},
        {dict = "friends@fra@ig_1", name = "base_idle"},
        {dict = "amb@world_human_hang_out_street@male_b@idle_a", name = "idle_b"},
        {dict = "anim@heists@heist_corona@team_idles@male_a", name = "idle"},
        {dict = "anim@mp_celebration@idles@female", name = "celebration_idle_f_a"},
        {dict = "anim@mp_corona_idles@female_b@idle_a", name = "idle_a"},
        {dict = "random@shop_tattoo", name = "_idle_a"},
    }
}

-- Active Sessions
Weed.Cornering.Active = {}
Weed.Cornering.Sessions = {}
Weed.Cornering.Zones = {}

-- Helper Functions
function Weed.Cornering.IsZoneAllowed(zone)
    return Weed.Cornering.Config.AllowedZones[zone] ~= nil
end

function Weed.Cornering.GetRandomAnimation()
    local anims = Weed.Cornering.Config.Animations
    return anims[math.random(#anims)]
end

function Weed.Cornering.CalculatePrice(quality, strainReputation)
    local basePrice = math.random(
        Weed.Cornering.Config.BasePrice[1],
        Weed.Cornering.Config.BasePrice[2]
    )
    
    -- Quality multiplier
    local qualityMultiplier = quality > 50 
        and (quality / 200) 
        or -((quality - 50) / 100)
    local qualityBonus = math.floor(basePrice * qualityMultiplier)
    basePrice = quality > 50 
        and (basePrice + qualityBonus) 
        or (basePrice - qualityBonus)
    
    -- Strain reputation multiplier
    if strainReputation then
        local repMultiplier = strainReputation / Weed.Cornering.Config.DividerReputationBonus
        local repBonus = math.floor(basePrice * repMultiplier)
        basePrice = basePrice + repBonus
    end
    
    return math.floor(basePrice)
end

-- Payout configuration 
Weed.Cornering.Config.Payout = {
    Type = 'clean', -- 'dirty' or 'clean'
    Items = {
        dirty = 'black_money', -- item name for dirty money
        clean = 'money'         -- item name for clean money 
    }
}