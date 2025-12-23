# Ferp-Weed

Advanced Weed Growing & Selling System for FiveM

## Overview

Ferp-Weed is a comprehensive weed cultivation and distribution framework for FiveM servers. Players can grow multiple weed strains, manage plant health through watering and nutrients, harvest buds and seeds, and sell their products. The system includes dealer interactions, laptop management, strain customization, perks progression, and a complete economy integration with dynamic street corner dealing.

## Features

- Full plant lifecycle management with growth stages
- Multiple weed strains with customizable attributes
- Advanced nutrient and watering systems
- Harvesting mechanics with male/female plant genetics
- Dealer system for selling products
- Laptop interface (Lab app) for farm and strain management
- Strain creation system with custom genetics
- Perk tree system with progression levels (1-15)
- Strain reputation and ranking system
- Street corner dealing (cornering) with dynamic events
- Hand prop animations when carrying items
- Police evidence collection on sales
- Stress system integration
- NPC strain dealer at random locations
- Dynamic customer events (haggling, drunk clients, scared customers)
- Bulk sales bonuses and extra purchases
- Language support (English, Portuguese)
- Optimized rendering with chunk-based spawning
- Item persistence and tracking

## Installation

1. Ensure dependencies are installed on your server:
   - qbx_core
   - ox_lib
   - ox_inventory
   - ox_target
   - oxmysql

2. Extract the resource to your server's resources folder

3. Add to your server.cfg:
   ```
   ensure Ferp-Weed
   ```

4. Import database file:
   ```
   mysql -u root -p < data.sql
   ```

5. Restart the server or use `refresh` command

## Configuration

Main configuration file: `shared/sh_config.lua`

### Key Settings

- `Config.Debug` - Enable debug mode
- `Config.ProgressType` - Progress indicator style (bar/circle)
- `Config.ProgressPosition` - Progress position on screen (top/middle/bottom)
- `Config.UseStress` - Enable/disable stress system
- `Config.StressReduction` - Stress reduced per joint consumed
- `Config.EvidenceChance` - Chance police evidence drops on sale
- `Config.Locale` - Language setting (en/pt)
- `Config.HandProps.Enabled` - Enable/disable hand prop animations
- `Config.UseObjectPersistence` - Enable object persistence system

### Performance Settings

- `SpawnDistance` - Distance to load plant visuals (default: 50.0m)
- `DespawnDistance` - Distance to unload plant visuals (default: 75.0m)
- `UpdateInterval` - Client update frequency (default: 2000ms)
- `BatchSize` - Plants spawned per tick (default: 15)
- `ServerUpdateInterval` - Growth update interval (default: 300s)
- `ChunkSize` - Size of chunks for spatial partitioning (default: 100.0)
- `MaxVisiblePlants` - Maximum visible plants per player (default: 200)

## Usage

### Growing Plants

1. Target a planter or designated grow location
2. Plant weed seeds
3. Water and add nutrients regularly
4. Wait for growth stages to complete
5. Harvest buds and seeds when ready

### Plant Health System

Plants require proper care through:

- **Watering**: Reduces plant water level. Optimal water level is 0.9
- **Nutrients**: Three types of nutrients (N, P, K) each with optimal level of 1.5
- **Growth**: Plants take 400 minutes to fully mature
- **Lifetime**: Plants live for 1400 minutes total before dying

Plant health affects yield quality and quantity. Males and females grow differently, with males taking 1.5x longer.

### Strain Management

Strains track custom genetics with three nutrient values (nitrogen, phosphorus, potassium). Each seed without a custom strain receives a random default strain from the pool (OG Kush, White Widow, Purple Haze, Sour Diesel, Blue Dream, Northern Lights).

Players can unlock reputation levels for strains:
- Common: Reputation 0
- Superior: Reputation 100
- Premium: Reputation 250
- Epic: Reputation 500 (can rename strain)
- Supreme: Reputation 1000 (can rename strain)
- Ascendant: Reputation 15000 (can rename strain)
- Imperial: Reputation 25000 (can rename strain)
- Unrivaled: Reputation 50000 (can rename strain)
- Mythic: Reputation 100000 (can rename strain)

### Laptop Lab Application

Access the laptop to view and manage your weed farm:

- View all owned strains and their current level
- Check available perk points
- Unlock perks for each strain
- Rename strains after reaching Epic reputation
- Monitor strain statistics and genetics
- Track indoor grow upgrades
- Maximum 5 strains per player

The Lab application registers as a custom app in the fd_laptop system and displays in the NUI interface. The app requires `fd_laptop` resource to function.

### Perk System

Strains gain experience from player actions (harvesting, watering, fertilizing, selling) and level up. Each level grants perk points to unlock perks from the perk tree.

#### Perk Categories

- **Production**: Yield boost, growth speed, resilience, master grower
- **Reproduction**: Seed production, male ratio control, mutation chance
- **Sales**: Price multipliers, bulk discounts, profit bonuses
- **Effects**: Plant visual enhancements, special abilities

Perks have level requirements and cost varying amounts of perk points. Each perk can be leveled multiple times up to a maximum level.

#### Perk Examples

- Yield Boost: +10% buds per level (max 5 levels)
- Growth Speed: -5% growth time per level (max 5 levels)
- Resilience: -15% resource decay per level (max 3 levels)
- Master Grower: Plant never dies from lack of water (1 level, requires level 10)

### Perk XP System

Players gain experience from various actions:

- Harvesting: 50 XP
- Watering: 10 XP
- Fertilizing: 15 XP
- Selling: 5 XP

Level progression requires increasing XP amounts:
- Level 2: 1000 XP (Beginner)
- Level 3: 2500 XP
- Level 4: 5000 XP (Amateur)
- Level 5: 10000 XP
- Level 6: 20000 XP (Expert)
- Level 7: 35000 XP
- Level 8: 55000 XP (Master)
- Level 9: 80000 XP
- Level 10: 120000 XP (Legendary)
- Level 11: 170000 XP
- Level 12: 230000 XP
- Level 13: 300000 XP
- Level 14: 380000 XP
- Level 15: 500000 XP (Godlike) Each perk can be leveled multiple times up to a maximum level.

### Street Corner Dealing (Cornering)

Active street corner selling with dynamic customer interactions:

- Spawn customers at designated corners
- Handle negotiations and sales
- Track sales count for bonuses
- Face random events:
  - Clients giving up (8% chance)
  - Clients without money (6% chance)
  - Clients haggling for discounts (12% chance, 70% payment)
  - Extra purchases (10% chance + bulk bonus)
  - Police nearby (5% chance)
  - Drunk clients (8% chance)
  - Scared customers (6% chance)
  - Tip bonuses (7% chance)
  - Returning customers (5% chance)

Customer attitudes and dialogues vary based on events and client states. Cornering system tracks current bulk sale chance and active status.

### Strain Dealer NPC

A random strain dealer NPC spawns at one of 7 locations across the map, changing location on server restart:
- Vespucci Beach
- Sandy Shores
- Paleto Bay
- Mirror Park
- La Mesa
- Del Perro Pier
- Vinewood Hills

View and interact with strain rankings and top growers. NPC spawns with custom model and animation.

### Selling

1. Visit designated dealers or street corners
2. Select products to sell
3. Risk police evidence collection based on configured chance
4. Receive payment
5. Gain perk XP for selling

## File Structure

```
client/          - Client-side scripts
server/          - Server-side scripts
shared/          - Shared configuration and data
web/             - HTML/JS interface for laptop
locales/         - Translation files
fxmanifest.lua   - Resource manifest
data.sql         - Database schema
README.md        - This file
```

### Key Files

- `client/cl_main.lua` - Core client functionality
- `client/cl_plants.lua` - Plant spawning and visuals
- `client/cl_strains.lua` - Strain UI and interactions
- `client/cl_cornering.lua` - Street corner dealing mechanics
- `client/cl_laptop.lua` - Laptop NUI callbacks
- `server/sv_main.lua` - Core server logic
- `server/sv_plants.lua` - Plant growth and persistence
- `server/sv_strains.lua` - Strain data management
- `server/sv_dealers.lua` - Dealer system
- `server/sv_laptop.lua` - Lab app callbacks

## Dependencies

- qbx_core (Framework)
- ox_lib (Library functions)
- ox_inventory (Inventory system)
- ox_target (Target system)
- oxmysql (Database)
- fd_laptop (for laptop interface)

## Languages

- English (en)
- Portuguese (pt)

Edit `Config.Locale` in `sh_config.lua` to change language.

## Localization Files

Translation files are located in `locales/`:
- `en.json` - English translations
- `pt.json` - Portuguese translations

Add new language support by creating a new JSON file and updating the config.

## Events and Callbacks

The system uses various server/client events for communication:

### Server Events
- `Ferp-Weed:server:unlockPerk` - Unlock a perk for a strain
- `Ferp-Weed:server:renameStrain` - Rename a strain

### Client Events
- `Ferp-Weed:client:laptopNotify` - Send notifications to laptop app

### Callbacks
- `Ferp-Weed:getStrainData` - Get player's strain data
- `Ferp-Weed:unlockPerk` - Unlock perk on strain
- `Ferp-Weed:server:getNPCLocation` - Get strain dealer NPC location

## Performance Tips

- Adjust `MaxVisiblePlants` based on server resources
- Increase `ServerUpdateInterval` to reduce load
- Decrease `BatchSize` if experiencing freezing
- Use smaller `ChunkSize` for detailed areas

## Database

The system uses MySQL for persistent storage. Import `data.sql` for required tables and structures.

## Events and Callbacks

The system uses various server/client events for communication:

- `Ferp-Weed:server:unlockPerk` - Unlock a perk for a strain
- `Ferp-Weed:server:renameStrain` - Rename a strain
- `Ferp-Weed:client:laptopNotify` - Send notifications to laptop app
- `Ferp-Weed:server:getNPCLocation` - Get strain dealer NPC location

## Items

The system tracks various items through ox_inventory:

- `weed_seed` - Standard cannabis seeds
- `weed_bud` - Harvested flower buds
- `weed_joint` - Consumable joint
- `weed_baggie` - Small amount of weed
- `weed_brick` - Compressed weed block
- `fertilizer` - Plant nutrient
- `water_bottle` - Plant hydration
- Evidence items (kief, baggie, papers, weed pipe, joint)
- Strain-specific seed and bud variants

## Customization

All default behaviors can be customized through configuration files:

- Plant models and growth times: `shared/sh_plants.lua`
- Strain genetics: `shared/sh_strains.lua`
- Perk tree structure: `shared/sh_perks.lua`
- Cornering events: `client/cl_cornering.lua`
- NPC locations: `shared/sh_strains.lua`
