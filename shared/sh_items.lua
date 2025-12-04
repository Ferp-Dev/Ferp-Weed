Weed.Items = {}

Weed.Items.Config = {
    -- Processing
    BudsPerBrick = 5, -- Buds needed to make 1 brick
    BaggiesPerBrick = 10, -- Baggies from 1 brick
    JointsPerBaggie = 3, -- Joints from 1 baggie (needs same amount of rolling paper)
    JointLossRate = 1.0, -- Quality loss rate
    
    -- Joint Effects
    JointDuration = 60, -- Seconds
    ArmorPerTick = 3, -- Armor gained per second
    StressReduction = 100, -- Stress reduced per tick
    MaxStressReduction = 5000, -- Maximum total stress reduction
    
    -- Evidence
    RedEyesDuration = 600, -- Seconds
    WeedSmellDuration = 600, -- Seconds
    
    -- Packaging NPCs
    PackagingNPCs = {
        -- NPC Sul
        Sul = {
            Model = `a_m_y_mexthug_01`,
            Scenario = "WORLD_HUMAN_DRUG_DEALER",
            Locations = {
                { name = "Rancho", coords = vector4(481.68, -1302.68, 28.25, 223.97) },
                { name = "Cypress Flats", coords = vector4(855.66, -2124.62, 29.55, 209.9) },
                { name = "Vespucci", coords = vector4(-1152.74, -1455.89, 3.57, 348.33) },
                { name = "El Burro Heights", coords = vector4(211.48, -1856.5, 26.2, 144.89) },
            }
        },
        -- NPC Norte
        Norte = {
            Model = `a_m_m_hillbilly_02`,
            Scenario = "WORLD_HUMAN_SMOKING",
            Locations = {
                { name = "Sandy Shores", coords = vector4(1994.53, 3703.24, 31.82, 254.68) },
                { name = "Grapeseed", coords = vector4(1697.75, 4790.6, 40.92, 30.26) },
                { name = "Paleto Bay", coords = vector4(-212.93, 6358.54, 30.49, 98.22) },
                { name = "Harmony", coords = vector4(556.05, 2665.0, 41.2, 214.86) },
            }
        }
    },
    
    -- Processing times (ms)
    ProcessingTimes = {
        BudsToBrick = 8000,
        BrickToBaggies = 5000,
        BaggieToJoints = 3000,
    },
    
    -- Scale durability
    ScaleDurabilityLoss = 10, -- % de durabilidade perdida por uso (10 usos = quebra)
}

-- Item Metadata Templates
Weed.Items.Templates = {
    weed_bud = {
        strain = 0,
        strain_name = "Unknown",
        quality = 50,
        _hideKeys = {"strain", "quality"}
    },
    
    weed_brick = {
        strain = 0,
        strain_name = "Unknown",
        quality = 50,
        _hideKeys = {"strain", "quality"}
    },
    
    weed_baggie = {
        strain = 0,
        strain_name = "Unknown",
        quality = 50,
        _hideKeys = {"strain", "quality"}
    },
    
    joint = {
        strain = 0,
        strain_name = "Unknown",
        quality = 50,
        weed_quality = 50,
        _hideKeys = {"strain", "quality", "weed_quality"}
    },
    
    weed_seed_female = {
        strain = 0,
        strain_name = "Unknown",
        quality = 50,
        n = 0.5,
        p = 0.5,
        k = 0.5,
        _hideKeys = {"strain", "n", "p", "k"}
    }
}

-- Helper Functions
function Weed.Items.CreateMetadata(itemType, strain, quality)
    local template = Weed.Items.Templates[itemType]
    if not template then return {} end
    
    local metadata = {}
    for k, v in pairs(template) do
        -- Skip _hideKeys from being copied to metadata
        if k ~= "_hideKeys" then
            metadata[k] = v
        end
    end
    
    local strainName = "Desconhecida"
    local strainId = 0
    
    if strain then
        strainId = strain.id or 0
        strainName = strain.name or "Desconhecida"
        
        metadata.strain = strainId
        metadata.strain_name = strainName
        
        -- Copy NPK values from strain for seeds
        if itemType == "weed_seed_female" then
            metadata.n = strain.n or 0.5
            metadata.p = strain.p or 0.5
            metadata.k = strain.k or 0.5
        end
    end
    
    if quality then
        metadata.quality = quality
        if itemType == "joint" then
            metadata.weed_quality = quality
        end
    end
    
    -- ox_inventory uses 'description' to show custom info in item details
    metadata.description = string.format("Strain: %s\nQualidade: %d%%", strainName, quality or 50)
    
    -- Debug print
    if IsDuplicityVersion then
        print(string.format("[FERP_WEED] CreateMetadata: type=%s, strain_id=%d, strain_name=%s", 
            itemType, strainId, strainName))
    end
    
    return metadata
end

function Weed.Items.GetQualityLabel(quality)
    if quality >= 90 then
        return "Exceptional"
    elseif quality >= 75 then
        return "Premium"
    elseif quality >= 60 then
        return "Good"
    elseif quality >= 40 then
        return "Average"
    elseif quality >= 25 then
        return "Poor"
    else
        return "Terrible"
    end
end

function Weed.Items.GetQualityColor(quality)
    if quality >= 90 then
        return "#FFD700" -- Gold
    elseif quality >= 75 then
        return "#9370DB" -- Purple
    elseif quality >= 60 then
        return "#4169E1" -- Blue
    elseif quality >= 40 then
        return "#32CD32" -- Green
    elseif quality >= 25 then
        return "#FFA500" -- Orange
    else
        return "#DC143C" -- Red
    end
end