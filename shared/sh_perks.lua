Weed.Perks = {}

-- XP Configuration
Weed.Perks.XP = {
    Levels = {
        [2] = 1000,   -- Beginner
        [3] = 2500,
        [4] = 5000,   -- Amateur
        [5] = 10000,
        [6] = 20000,  -- Expert
        [7] = 35000,
        [8] = 55000,  -- Master
        [9] = 80000,
        [10] = 120000, -- Legendary
        [11] = 170000,
        [12] = 230000,
        [13] = 300000,
        [14] = 380000,
        [15] = 500000, -- Godlike
    },
    
    Actions = {
        Harvest = 50,      
        Water = 10,        
        Fertilize = 15,    
        Sell = 5,          
    }
}

-- Categories Definitions
Weed.Perks.Categories = {
    ['production'] = { label = 'Cultivo', icon = 'seedling', color = '#4CAF50' },
    ['reproduction'] = { label = 'Genética', icon = 'dna', color = '#2196F3' },
    ['sales'] = { label = 'Negócios', icon = 'hand-holding-dollar', color = '#FFC107' },
    ['effects'] = { label = 'Efeitos', icon = 'magic', color = '#9C27B0' },
}

-- RPG Perk Tree
Weed.Perks.List = {
    -- ================= PRODUCTION =================
    ['yield_boost'] = {
        category = 'production',
        label = 'Colheita Abundante',
        description = 'Aumenta a quantidade de buds colhidos por planta.',
        maxLevel = 5,
        cost = 1,
        reqLevel = 1,
        getModifier = function(level) 
            return 1.0 + (level * 0.10) -- +10% yield per level
        end
    },
    ['growth_speed'] = {
        category = 'production',
        label = 'Crescimento Acelerado',
        description = 'Reduz o tempo necessário para a planta crescer.',
        maxLevel = 5,
        cost = 1,
        reqLevel = 3,
        getModifier = function(level)
            return 1.0 - (level * 0.05) -- -5% growth time per level
        end
    },
    ['resilience'] = {
        category = 'production',
        label = 'Resistência Natural',
        description = 'A planta perde água e fertilizante mais lentamente.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 5,
        getModifier = function(level)
            return 1.0 - (level * 0.15) -- -15% decay per level
        end
    },
    ['master_grower'] = {
        category = 'production',
        label = 'Mestre Cultivador',
        description = 'A planta nunca morre por falta de água.',
        maxLevel = 1,
        cost = 5,
        reqLevel = 10, 
        getModifier = function(level) return true end
    },

    -- ================= REPRODUCTION =================
    ['seeding_chance'] = {
        category = 'reproduction',
        label = 'Polinização Controlada',
        description = 'Aumenta a chance de obter sementes de plantas macho.',
        maxLevel = 5,
        cost = 1,
        reqLevel = 2,
        getModifier = function(level)
            return level * 0.05 -- +5% chance per level
        end
    },
    ['fertility'] = {
        category = 'reproduction',
        label = 'Fertilidade',
        description = 'Aumenta a quantidade máxima de sementes geradas.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 4,
        getModifier = function(level)
            return level -- +1 max seed per level
        end
    },
    ['female_seed_chance'] = {
        category = 'reproduction',
        label = 'Feminização',
        description = 'Chance de obter sementes fêmeas de plantas macho.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 6,
        getModifier = function(level)
            return level * 0.05 -- +5% female seed chance
        end
    },

    -- ================= SALES =================
    ['negotiator'] = {
        category = 'sales',
        label = 'Lábia de Vendedor',
        description = 'Aumenta o valor de venda dos saquinhos.',
        maxLevel = 5,
        cost = 1,
        reqLevel = 3,
        getModifier = function(level)
            return 1.0 + (level * 0.05) -- +5% price per level
        end
    },
    ['fast_seller'] = {
        category = 'sales',
        label = 'Fluxo Rápido',
        description = 'Reduz o tempo de espera entre clientes no cornering.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 5,
        getModifier = function(level)
            return 1.0 - (level * 0.10) -- -10% wait time
        end
    },
    ['bulk_seller'] = {
        category = 'sales',
        label = 'Venda em Atacado',
        description = 'Chance de vender múltiplos saquinhos de uma vez.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 7,
        getModifier = function(level)
            return level * 20 -- +20% chance to sell double (Max 60%)
        end
    },

    -- ================= EFFECTS (BUFFS) =================
    ['stress_relief'] = {
        category = 'effects',
        label = 'Paz Interior',
        description = 'Remove muito mais estresse ao fumar.',
        maxLevel = 3,
        cost = 1,
        reqLevel = 1,
        getModifier = function(level)
            return 1.0 + (level * 0.20) -- +20% stress relief
        end
    },
    ['swiftness'] = {
        category = 'effects',
        label = 'Pés Ligeiros',
        description = 'Aumenta a velocidade de corrida.',
        maxLevel = 2,
        cost = 4,
        reqLevel = 2,
        getModifier = function(level)
            return 1.0 + (level * 0.05) -- +5% speed mult
        end
    },
    ['iron_lungs'] = {
        category = 'effects',
        label = 'Pulmões de Aço',
        description = 'Aumenta o fôlego debaixo d\'água.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 3,
        getModifier = function(level)
            return level * 1.5 -- Multiplier for max underwater time
        end
    },
    ['endurance'] = {
        category = 'effects',
        label = 'Maratonista',
        description = 'Estamina infinita por um tempo.',
        maxLevel = 3,
        cost = 2,
        reqLevel = 4,
        getModifier = function(level)
            return level * 30 -- Seconds of infinite stamina
        end
    },
    ['night_vision'] = {
        category = 'effects',
        label = 'Olhos de Gato',
        description = 'Concede visão noturna temporária.',
        maxLevel = 1,
        cost = 4,
        reqLevel = 5,
        getModifier = function(level)
            return 45 -- Seconds
        end
    },
    ['shadow'] = {
        category = 'effects',
        label = 'Passos de Sombra',
        description = 'Seus passos fazem menos barulho.',
        maxLevel = 3,
        cost = 3,
        reqLevel = 6,
        getModifier = function(level)
            return 1.0 - (level * 0.25) -- multiplier (0.25 = 25% noise, etc)
        end
    },
    ['stone_skin'] = {
        category = 'effects',
        label = 'Pele de Pedra',
        description = 'Fumar esta cepa concede bônus de colete.',
        maxLevel = 3,
        cost = 3,
        reqLevel = 7,
        getModifier = function(level)
             -- Level 1: +10 armor, Lvl 2: +20, Lvl 3: +30 (Added to base 50 max)
            return level * 10
        end
    },
    ['vitality'] = {
        category = 'effects',
        label = 'Vitalidade',
        description = 'Fumar esta cepa regenera vida lentamente.',
        maxLevel = 3,
        cost = 3,
        reqLevel = 8,
        getModifier = function(level)
            return level -- Regeneration tier
        end
    },
    ['strength'] = {
        category = 'effects',
        label = 'Força Bruta',
        description = 'Aumenta o dano corpo a corpo.',
        maxLevel = 3,
        cost = 3,
        reqLevel = 9,
        getModifier = function(level)
            return 1.0 + (level * 0.20) -- +20% damage
        end
    }
}

-- Helper Functions
function Weed.Perks.GetLevelFromXP(xp)
    local level = 1
    for lvl, reqXp in pairs(Weed.Perks.XP.Levels) do
        if xp >= reqXp and lvl > level then
            level = lvl
        end
    end
    return level
end

function Weed.Perks.GetPointsTotal(level)
    return math.max(0, (level - 1) * 3) -- 3 Points per level
end

function Weed.Perks.GetModifier(perks, perkName)
    if not perks then return 0 end
    local level = perks[perkName] or 0
    if level == 0 then return 0 end
    
    local perk = Weed.Perks.List[perkName]
    if not perk then return 0 end
    
    -- Safety Clamp
    if perk.maxLevel and level > perk.maxLevel then
        level = perk.maxLevel
    end

    if perk.getModifier then
        return perk.getModifier(level)
    end
    return 0
end
