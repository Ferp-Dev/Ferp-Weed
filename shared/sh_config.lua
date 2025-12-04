Config = Config or {}

-- Debug Mode
Config.Debug = false

-- UI Settings
Config.ProgressType = 'circle' -- 'bar' = progressBar, 'circle' = progressCircle
Config.ProgressPosition = 'bottom' -- 'bottom', 'middle', 'top'

-- Performance Settings
Config.Performance = {
    SpawnDistance = 50.0,      -- Distance to spawn plant objects (meters)
    DespawnDistance = 75.0,    -- Distance to despawn plant objects (meters)
    UpdateInterval = 2000,     -- Client-side spawn/despawn check interval (ms)
    BatchSize = 15,            -- Max plants to spawn per tick (prevents freezing)
    ServerUpdateInterval = 300, -- Server growth update interval (seconds) - 5 minutes
    ChunkSize = 100.0,         -- Size of chunks for spatial partitioning
    MaxVisiblePlants = 200,    -- Max plants visible at once per player
}

-- Police Job Names
Config.PoliceJobs = {
    'police',
    'sheriff'
}

-- Evidence System
Config.EvidenceChance = 0.3 -- 30% chance to drop evidence when selling
Config.EvidenceTypes = {
    "Kief",
    "Baggie", 
    "Papers",
    "Weed Pipe",
    "Joint"
}

-- Stress System
Config.UseStress = true
Config.StressReduction = 5000 -- Amount of stress reduced per joint

-- Locale
Config.Locale = 'en' -- pt, en, es

-- Object System
Config.UseObjectPersistence = true -- Requires object persistence script
Config.ObjectNetworked = true

-- Hand Prop System
Config.HandProps = {
    Enabled = true, -- Habilita/desabilita
    Items = {
        ['weed_brick'] = {
            model = 'prop_weed_block_01', -- Modelo do prop
            bone = 60309,
            pos = vec3(0.1, 0.1, 0.05), -- Posição
            rot = vec3(0.0, -90.0, 90.0), -- Rotação
            anim = {
                dict = 'impexp_int-0',
                clip = 'mp_m_waremech_01_dual-0',
                flag = 49 -- Loop + Move
            }
        },
        -- Adicione mais itens aqui se quiser
        -- ['weed_baggie'] = {
        --     model = 'prop_cs_weed_bag_01',
        --     bone = 28422,
        --     pos = vec3(0.0, 0.0, 0.0),
        --     rot = vec3(0.0, 0.0, 0.0),
        --     anim = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 }
        -- }
    }
}