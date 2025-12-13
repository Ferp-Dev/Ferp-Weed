-- ============================================
-- FERP WEED SYSTEM - DATABASE INSTALLATION
-- ============================================
-- Execute este arquivo no seu banco de dados MySQL/MariaDB
-- Run this file on your MySQL/MariaDB database
-- ============================================

-- Tabela de Plantas / Plants Table
CREATE TABLE IF NOT EXISTS `weed_plants` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `coords` TEXT NOT NULL,
    `metadata` LONGTEXT NOT NULL,
    `created_at` INT(11) NOT NULL,
    `expires_at` INT(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Strains / Strains Table
CREATE TABLE IF NOT EXISTS `weed_strains` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) DEFAULT NULL,
    `strain` TEXT NOT NULL,
    `reputation` INT(11) DEFAULT 0,
    `renamed` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Dealers / Dealers Table
CREATE TABLE IF NOT EXISTS `weed_dealers` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `reputation` INT(11) DEFAULT 0,
    `last_sell` INT(11) DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- OX_INVENTORY ITEMS CONFIGURATION
-- ============================================
-- Adicione estes itens em: ox_inventory/data/items.lua
-- Add these items to: ox_inventory/data/items.lua
-- ============================================

--[[

-- ========== SEEDS ==========
['weed_seed_female'] = {
    label = 'Female Seed',
    weight = 100,
    stack = true,
    close = true,
    description = 'Female seed for planting',
    client = {
        usetime = 5000,
        export = 'Ferp-Weed.PlantSeed'
    }
},

['weed_seed_male'] = {
    label = 'Male Seed',
    weight = 100,
    stack = true,
    close = true,
    description = 'Male seed for pollination'
},

-- ========== BUDS ==========
['weed_bud'] = {
    label = 'Weed Bud',
    weight = 80,
    stack = true,
    close = true,
    description = 'bud?'
},

-- ========== PROCESSED PRODUCTS ==========
['weed_brick'] = {
    label = 'Weed Brick',
    weight = 500,
    stack = true,
    close = true,
    description = 'Compressed weed block'
},

['weed_baggie'] = {
    label = 'Weed Baggie',
    weight = 50,
    stack = true,
    close = true,
    description = 'Baggie ready to sell'
},

['joint'] = {
    label = 'Joint',
    weight = 20,
    stack = true,
    close = true,
    description = 'Weed joint ready to smoke',
    client = {
        usetime = 2000,
        export = 'Ferp-Weed.SmokeJoint'
    }
},

-- ========== MATERIALS ==========
['empty_baggie'] = {
    label = 'Empty Baggie',
    weight = 10,
    stack = true,
    close = true,
    description = 'Empty baggie'
},

['rolling_paper'] = {
    label = 'Rolling Paper',
    weight = 5,
    stack = true,
    close = true,
    description = 'Paper for rolling'
},

['fertilizer'] = {
    label = 'Fertilizer',
    weight = 500,
    stack = true,
    close = true,
    description = 'NPK fertilizer for plants'
},

['fertilizer_n'] = {
    label = 'Nitrogen Fertilizer',
    weight = 300,
    stack = true,
    close = true,
    description = 'Fertilizer rich in Nitrogen (N)'
},

['fertilizer_p'] = {
    label = 'Phosphorus Fertilizer',
    weight = 300,
    stack = true,
    close = true,
    description = 'Fertilizer rich in Phosphorus (P)'
},

['fertilizer_k'] = {
    label = 'Potassium Fertilizer',
    weight = 300,
    stack = true,
    close = true,
    description = 'Fertilizer rich in Potassium (K)'
},

['wateringcan'] = {
    label = 'Watering Can',
    weight = 1000,
    stack = false,
    close = true,
    description = 'Watering can for plants'
},

['weed_scale'] = {
    label = 'Scale',
    weight = 500,
    stack = false,
    close = true,
    description = 'Scale for weighing'
},

['strain_modifier'] = {
    label = 'Strain Modifier',
    weight = 500,
    stack = true,
    close = true,
    description = 'Modifier for strain attributes'
},

]]

-- ============================================
-- OX_INVENTORY SHOP CONFIGURATION (OPCIONAL)
-- ============================================
-- Adicione em: ox_inventory/data/shops.lua
-- Add to: ox_inventory/data/shops.lua
-- ============================================

--[[

['weed_supplies'] = {
    name = 'Suprimentos para Cultivo',
    inventory = {
        { name = 'weed_seed_female', price = 50 },
        { name = 'empty_baggie', price = 5 },
        { name = 'rolling_paper', price = 2 },
        { name = 'fertilizer', price = 20 },
        { name = 'fertilizer_n', price = 15 },
        { name = 'fertilizer_p', price = 15 },
        { name = 'fertilizer_k', price = 15 },
        { name = 'wateringcan', price = 150 },
        { name = 'scale', price = 500 },
    },
    groups = {
        -- Grupos permitidos (opcional)
    }
}

]]