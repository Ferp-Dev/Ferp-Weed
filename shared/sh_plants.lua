Weed.Plants = {}

Weed.Plants.Config = {
    -- Growth Settings
    GrowthTime = 400, -- Minutes for full growth
    LifeTime = 1400, -- Total lifetime in minutes
    MaleFactor = 1.5, -- Male plants grow slower
    HarvestPercent = 100.0, -- Growth % needed to harvest
    TimeBetweenHarvest = 120, -- Minutes between harvests
    FertilizerFactor = 1.1, -- Growth speed boost with fertilizer
    
    -- Harvest Settings
    RemoveMaleOnHarvest = true,
    BudsFromFemale = {1, 4}, -- Min/Max buds from female plant
    SeedsFromMale = {3, 5}, -- Min/Max seeds from male
    MaleChance = 0.34, -- Chance for male seed
    
    -- Watering & Fertilizer
    WaterAdd = 0.2, -- Water amount per use
    FertilizerAdd = 0.4, -- Fertilizer amount per nutrient (for strain creation)
    FertilizerBoost = 0.25, -- 25% growth time reduction when using fertilizer
    
    -- Optimal Values
    WaterOptimal = 0.9,
    NOptimal = 1.5, -- Nitrogen
    POptimal = 1.5, -- Phosphorus
    KOptimal = 1.5, -- Potassium
    
    -- Plant Models 
    Objects = {
        {model = `bkr_prop_weed_01_small_01b`, zOffset = -0.45},  -- Pequena
        {model = `bkr_prop_weed_med_01a`, zOffset = -0.5},        -- Média 1
        {model = `bkr_prop_weed_med_01b`, zOffset = -0.5},        -- Média 2
        {model = `bkr_prop_weed_lrg_01a`, zOffset = -0.55},       -- Grande 1
        {model = `bkr_prop_weed_lrg_01b`, zOffset = -0.55},       -- Grande 2
    },
    
    -- Ground Materials
    Materials = {
        [-461750719] = 1, -- Grass
        [930824497] = 1,
        [581794674] = 2, -- Normal ground
        [-2041329971] = 2,
        [-309121453] = 2,
        [-913351839] = 2,
        [-1885547121] = 2,
        [-1915425863] = 2,
        [-1833527165] = 2,
        [2128369009] = 2,
        [-124769592] = 2,
        [-840216541] = 2,
        [-2073312001] = 3,
        [627123000] = 3,
        [1333033863] = 4, -- Grassy rocks
        [-1286696947] = 5, -- Mountain grass
        [-1942898710] = 5,
        [-1595148316] = 6,
        [435688960] = 7,
        [223086562] = 8, -- Wet ground
        [1109728704] = 8
    },
    
    -- Ground Modifiers (n, p, k, water)
    Modifiers = {
        {n = 0.6, p = 0.6, k = 0.6, water = 0.5}, -- Grass
        {n = 0.3, p = 0.3, k = 0.3, water = 0.4}, -- Normal
        {n = 0.6, p = 0.6, k = 0.6, water = 0.6}, -- Unknown
        {n = 0.6, p = 0.6, k = 0.6, water = 0.5}, -- Grassy rocks
        {n = 0.6, p = 0.6, k = 0.6, water = 0.4}, -- Mountain
        {n = 0.3, p = 0.3, k = 0.3, water = 0.5}, -- Unknown
        {n = 0.3, p = 0.3, k = 0.3, water = 0.5}, -- Unknown
        {n = 0.9, p = 0.9, k = 0.9, water = 0.9}, -- Wet
        {n = 0.9, p = 0.9, k = 0.9, water = 0.5}, -- Farmland
    }
}

-- Active Plants Storage
Weed.Plants.Active = {}
Weed.Plants.ConfigReady = false

-- Functions
function Weed.Plants.GetStage(percent)
    local growthObjects = #Weed.Plants.Config.Objects - 1
    local percentPerStage = 100 / growthObjects
    return math.floor((percent / percentPerStage) + 1.5)
end

function Weed.Plants.GetGrowth(plant, currentTime)
    local createdAt = plant.metadata.createdAt
    local gender = plant.metadata.gender
    local nFactor = plant.metadata.n
    local timeDiff = (currentTime - createdAt) / 60
    local genderFactor = (gender == 1 and Weed.Plants.Config.MaleFactor or 1)
    local fertilizerFactor = nFactor >= 0.9 and Weed.Plants.Config.FertilizerFactor or 1.0
    local growthFactors = (Weed.Plants.Config.GrowthTime * genderFactor * fertilizerFactor)
    return math.min((timeDiff / growthFactors) * 100, 100.0)
end

function Weed.Plants.GetQuality(plant)
    -- Calculate nutrient factors
    local nFactor = 1.0 - math.abs((plant.n / Weed.Plants.Config.NOptimal) - 1.0)
    local pFactor = 1.0 - math.abs((plant.p / Weed.Plants.Config.POptimal) - 1.0)
    local kFactor = 1.0 - math.abs((plant.k / Weed.Plants.Config.KOptimal) - 1.0)
    
    local strainQuality = (nFactor + pFactor + kFactor) / 3.0
    
    -- Calculate water factor
    local waterFactor = 1.0 - math.abs((plant.water - Weed.Plants.Config.WaterOptimal))
    
    -- Final quality (0-100)
    local quality = math.floor(100.0 * strainQuality * waterFactor)
    return math.max(0, math.min(quality, 100))
end