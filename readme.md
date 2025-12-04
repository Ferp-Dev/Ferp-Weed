# 🌿 FERP Weed System

Complete cannabis growing and selling system for FiveM

---

## 📋 Index

- [Features](#-features)
- [Dependencies](#-dependencies)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Growing System](#-growing-system)
- [Strains System](#-strains-system)
- [Processing System](#-processing-system)
- [Selling System (Cornering)](#-selling-system-cornering)
- [Consumption System](#-consumption-system)
- [Commands and Exports](#-commands-and-exports)
- [Localization](#-localization)
- [Credits](#-credits)

---

## ✨ Features

### 🌱 Advanced Growing
- **Realistic growth system** with configurable time cycles
- **Male and female plants** with different behaviors
- **NPK system** (Nitrogen, Phosphorus, Potassium) that affects quality
- **Watering system** to keep plants healthy
- **Specific fertilizers** (N, P, K) to optimize growth
- **Plant models per growth stage** (5 stages)
- **Terrain influence** on initial nutrients

### 🧬 Strains System
- **Create custom strains** through crossbreeding
- **6 default strains** (OG Kush, White Widow, Purple Haze, etc.)
- **Reputation system** per strain (9 tiers)
- **Procedurally generated or customizable names**
- **NPC vendor** that appears at a random location on restart

### 📦 Processing
- **Full production chain**: Bud → Brick → Baggie → Joint
- **Processing NPCs** (South and North of the map)
- **Quality inheritance** from the original strain
- **Scale/weighting system** with durability

### 💰 Street Selling (Cornering)
- **Vehicle-based selling** (cars)
- **NPC customers** approach the player
- **Zone system** with over 50 allowed areas
- **Dealer reputation** that increases prices
- **Anti-exploit protections** (distance, vehicle checks, etc.)
- **Automatic cleanup** of dead customers

### 🚬 Consumption
- **Smoking animation** with hand prop
- **Visual effects** (blurred vision, red eyes)
- **Progressive armor buff**
- **Stress reduction** (if a stress system is used)
- **Evidence system** for police

### 🔧 Technical
- **Performance optimized** with spawn/despawn by distance
- **Chunking system** for plants
- **Database persistence**
- **Complete locales system** (PT-BR, EN)
- **Debug mode** for development

---

## 📦 Dependencies

| Resource | Required | Link |
|---------|-------------|------|
| qbx_core | ✅ | [GitHub](https://github.com/Qbox-project/qbx_core) |
| ox_lib | ✅ | [GitHub](https://github.com/overextended/ox_lib) |
| ox_inventory | ✅ | [GitHub](https://github.com/overextended/ox_inventory) |
| ox_target | ✅ | [GitHub](https://github.com/overextended/ox_target) |
| oxmysql | ✅ | [GitHub](https://github.com/overextended/oxmysql) |

---

## 🚀 Installation

### 1. Download the resource
Place the `ferp_weed` folder into `resources/[ox]/` or your preferred resources folder.

### 2. Run the SQL
Execute the `data.sql` file in your MySQL/MariaDB database.

```sql
-- The following tables will be created:
-- weed_plants
-- weed_strains
-- weed_dealers
```

### 3. Add items to `ox_inventory`
Copy the items from the `data.sql` file (commented section) into `ox_inventory/data/items.lua`.

### 4. Add to `server.cfg`
```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qbx_core
ensure ferp_weed
```

### 5. Restart the server

---

## ⚙️ Configuration

### Main file: `shared/sh_config.lua`

```lua
Config.Debug = false              -- Debug mode
Config.ProgressType = 'circle'    -- 'bar' or 'circle'
Config.ProgressPosition = 'bottom' -- 'bottom', 'middle', 'top'
Config.Locale = 'pt'              -- 'pt', 'en'

-- Performance
Config.Performance = {
    SpawnDistance = 50.0,         -- Distance to spawn plants
    DespawnDistance = 75.0,       -- Distance to despawn plants
    UpdateInterval = 2000,        -- Update interval (ms)
    BatchSize = 15,               -- Plants per tick
    MaxVisiblePlants = 200,       -- Maximum visible per player
}

-- Police
Config.PoliceJobs = {'police', 'sheriff'}
Config.EvidenceChance = 0.3       -- 30% chance to leave evidence
```

### Plants: `shared/sh_plants.lua`

```lua
Weed.Plants.Config = {
    GrowthTime = 1,               -- Minutes for full growth
    LifeTime = 1920,              -- Plant lifetime (minutes)
    HarvestPercent = 100.0,       -- % required to harvest
    TimeBetweenHarvest = 1,       -- Minutes between harvests
    BudsFromFemale = {1, 4},      -- Min/Max buds per harvest
    MaleChance = 0.34,            -- Chance of male plant
}
```

### Cornering: `shared/sh_cornering.lua`

```lua
Weed.Cornering.Config = {
    TimeBetweenAcquisition = 10,  -- Seconds between customers
    BasePrice = {200, 300},       -- Base price min/max
    MaxReputationBonus = 2.0,     -- Maximum reputation multiplier
}
```

### Processing: `shared/sh_items.lua`

```lua
Weed.Items.Config = {
    BudsPerBrick = 5,             -- Buds required for 1 brick
    BaggiesPerBrick = 10,         -- Baggies per brick
    JointsPerBaggie = {3, 4},     -- Joints per baggie
    JointDuration = 60,           -- Effect duration (seconds)
    ArmorPerTick = 3,             -- Armor per second
}
```

---

## 🌱 Growing System

### Planting
1. Obtain a **female seed** (`weed_seed_female`)
2. Go to a **suitable terrain** (grass, dirt)
3. **Use the seed** from your inventory
4. Select the desired **strain**
5. Wait for growth

### Caring for the Plant
- **Watering**: Use a watering can (`wateringcan`) on the plant
- **Fertilizing**: Use fertilizers (N, P, K) to improve quality
- **Monitoring**: Check water and nutrient status

### Harvesting
- Wait until **100% growth**
- Interact with the plant to harvest
- **Female plants**: produce buds
- **Male plants**: produce seeds

### Terrain and Nutrients
| Terrain Type | Initial NPK | Water |
|-----------------|-------------|------|
| Grass | 60% | 50% |
| Normal dirt | 30% | 40% |
| Wet soil | 90% | 90% |
| Rocky with grass | 60% | 50% |

---

## 🧬 Strains System

### Default Strains
- **OG Kush** (N: 0.60, P: 0.50, K: 0.40)
- **White Widow** (N: 0.45, P: 0.70, K: 0.55)
- **Purple Haze** (N: 0.55, P: 0.45, K: 0.65)
- **Sour Diesel** (N: 0.70, P: 0.40, K: 0.50)
- **Blue Dream** (N: 0.50, P: 0.60, K: 0.45)
- **Northern Lights** (N: 0.40, P: 0.55, K: 0.70)

### Reputation Tiers
| Reputation | Tier | Can Rename? |
|-----------|-------|----------------|
| 0+ | Common | ❌ |
| 100+ | Superior | ❌ |
| 250+ | Premium | ❌ |
| 500+ | Epic | ✅ |
| 1000+ | Supreme | ✅ |
| 15000+ | Ascendant | ✅ |
| 25000+ | Imperial | ✅ |
| 50000+ | Unrivaled | ✅ |
| 100000+ | Mythic | ✅ |

### Creating Strains
1. Find the **strains NPC** (random location)
2. Select a **male plant**
3. Cross it with **female plants**
4. The new strain inherits characteristics

---

## 📦 Processing System

### Production Chain

```
Bud (weed_bud)
    ↓ [5 buds]
Brick (weed_brick)
    ↓ [1 brick]
Baggies (weed_baggie) x10
    ↓ [1 baggie]
Joints (joint) x3-4
```

### Processing NPCs
- **South of the map**: 5 random locations (Rancho, La Mesa, etc.)
- **North of the map**: 5 random locations (Sandy Shores, Paleto Bay, etc.)

### Using the Scale
- Process buds into bricks
- **10 uses** per scale (durability)

---

## 💰 Selling System (Cornering)

### How to Sell
1. Get into a **vehicle** (not bikes/boats)
2. Go to an **allowed zone**
3. Park the vehicle
4. Open the selling menu (via `ox_target`)
5. Click **"Start Selling"**
6. Wait for **customers** to approach

### Rules
- ❌ You cannot sell from a **motorbike, bicycle, boat or helicopter**
- ❌ You cannot move more than **60m away from the vehicle**
- ❌ You cannot leave the **starting point** (80m)
- ❌ You cannot **enter the vehicle** while selling
- ✅ Dead customers are **automatically cleaned up**

### Allowed Zones
Over **50 zones** across Los Santos and Blaine County, including:
- Downtown, Vinewood, Del Perro
- Davis, Rancho, La Mesa
- Sandy Shores, Paleto Bay, Grapeseed
- And many more...

### Pricing
```
Final Price = Base Price × Reputation Bonus × Zone Bonus
```

---

## 🚬 Consumption System

### Smoking a Joint
1. Use the **joint** (`joint`) from your inventory
2. Smoking animation with hand prop
3. Applied effects:
   - **Armor** increases progressively
   - **Stress** reduced (if enabled)
   - **Temporary visual effects**

### Evidence for Police
- Red eyes (10 min)
- Smell of cannabis (10 min)
- Chance to leave evidence while selling (30%)

---

## 📡 Commands and Exports

### Client Exports

```lua
-- Plant a seed
exports['ferp_weed']:PlantSeed()

-- Harvest a plant
exports['ferp_weed']:HarvestPlant(entity)

-- Water a plant
exports['ferp_weed']:WaterPlant(entity)

-- Fertilize a plant
exports['ferp_weed']:FertilizePlant(entity, nutrient)

-- Smoke a joint
exports['ferp_weed']:SmokeJoint()
```

### Server Exports

```lua
-- Check if player has red eyes
exports['ferp_weed']:HasRedEyes(source)

-- Check if player smells like weed
exports['ferp_weed']:SmellsLikeWeed(source)
```

---

## 🌐 Localization

The system supports multiple languages through JSON files in the `locales/` folder.

### Available Languages
- 🇧🇷 Portuguese (pt.json)
- 🇺🇸 English (en.json)

### Setting the Language
```lua
-- In shared/sh_config.lua
Config.Locale = 'pt' -- or 'en'
```

### Adding a New Language
1. Copy `locales/en.json` to `locales/XX.json`
2. Translate all strings
3. Set `Config.Locale = 'XX'`

---

## 🎨 Hand Props

The system supports hand props when the player has certain items in their inventory.

### Configuration
```lua
-- In shared/sh_config.lua
Config.HandProps = {
    Enabled = true,
    Items = {
        ['weed_brick'] = {
            model = 'prop_weed_block_01',
            bone = 60309,
            pos = vec3(0.1, 0.1, 0.05),
            rot = vec3(0.0, -90.0, 90.0),
            anim = {
                dict = 'impexp_int-0',
                clip = 'mp_m_waremech_01_dual-0',
                flag = 49
            }
        }
    }
}
```

---

## 🛠️ Troubleshooting

### Plants do not appear
- Check that you are within `SpawnDistance`
- Enable `Config.Debug = true` for logs

### Items do not work
- Make sure you added the items to `ox_inventory/data/items.lua`
- Check that the exports are correct

### NPCs do not appear
- Restart the server to generate a new random location
- Check that NPC coordinates are correct

### SQL errors
- Re-run `data.sql`
- Verify database permissions

---

## 📝 Credits

- **Development**: FERP
- **Framework**: QBX (Qbox)
- **Libraries**: Overextended (`ox_lib`, `ox_inventory`, `ox_target`)
