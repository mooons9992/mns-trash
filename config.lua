Config = {}

-- ==========================================--
--             SYSTEM SETTINGS               --
-- ==========================================--
Config.Systems = {
    inventory = 'ox_inventory', -- 'ox_inventory', 'qb-inventory', or 'custom'
    target = 'ox_target',       -- 'ox_target', 'qb-target', or 'custom'
    progressBar = 'ox_lib',     -- 'ox_lib', 'qb-progressbar', or 'custom'
    notify = 'ox_lib',          -- 'ox_lib', 'qb-notify', or 'custom'
    minigame = 'ox_lib'         -- For lockpicking minigame
}

-- ==========================================--
--              CORE SETTINGS                --
-- ==========================================--
Config.Cooldown = 300 -- Cooldown time in seconds

Config.Animation = {
    scenario = 'PROP_HUMAN_BUM_BIN',
    duration = 5000, -- Duration in ms
    label = 'Searching the trash bin...'
}

-- Notification texts
Config.Notifications = {
    success = 'You found %sx %s in the trash bin',
    empty = 'Nothing useful found in this trash bin',
    cooldown = 'This trash bin was recently searched',
    canceled = 'You stopped searching',
    locked = 'This dumpster is locked. You need a lockpick to open it.'
}

-- ==========================================--
--             TRASH MODEL SETTINGS          --
-- ==========================================--
-- Bin models that can be looted
Config.TrashModels = {
    'prop_dumpster_01a',
    'prop_dumpster_02a',
    'prop_dumpster_4a',
    'prop_dumpster_02b',
    'prop_dumpster_4b',
    'prop_bin_05a',
    'prop_bin_01a'
}

-- Difficulty settings for different trash models
Config.DifficultyTiers = {
    -- Large dumpsters require lockpicking
    ['prop_dumpster_01a'] = {difficulty = 'medium', requireItem = 'lockpick'},
    ['prop_dumpster_02a'] = {difficulty = 'medium', requireItem = 'lockpick'},
    ['prop_dumpster_4a'] = {difficulty = 'hard', requireItem = 'lockpick'},
    ['prop_dumpster_02b'] = {difficulty = 'medium', requireItem = 'lockpick'},
    ['prop_dumpster_4b'] = {difficulty = 'hard', requireItem = 'lockpick'},
    -- Small bins don't need lockpicks
    ['prop_bin_05a'] = {difficulty = 'easy', requireItem = nil},
    ['prop_bin_01a'] = {difficulty = 'easy', requireItem = nil},
}

-- ==========================================--
--              LOOT SETTINGS                --
-- ==========================================--
-- Basic loot items
Config.LootItems = {
    {item = 'water', chance = 60, min = 1, max = 3},
    {item = 'burger', chance = 40, min = 1, max = 2},
    {item = 'plastic', chance = 50, min = 1, max = 5},
    {item = 'metalscrap', chance = 40, min = 1, max = 3},
    {item = 'aluminum', chance = 30, min = 1, max = 2},
    {item = 'glass', chance = 35, min = 1, max = 4},
    {item = 'rubber', chance = 25, min = 1, max = 2},
    {item = 'copper', chance = 15, min = 1, max = 2}
}

-- Rare valuable items
Config.RareItems = {
    {item = 'goldwatch', chance = 2, min = 1, max = 1},
    {item = 'diamond', chance = 1, min = 1, max = 1},
    {item = 'cryptostick', chance = 1, min = 1, max = 1},
    {item = 'rolex', chance = 3, min = 1, max = 1}
}

-- ==========================================--
--        LOCATION-BASED LOOT POOLS         --
-- ==========================================--
Config.LocationBasedLoot = {
    -- Casino area dumpsters have higher chance for valuables
    ['casino'] = {
        radius = 100.0,
        center = vector3(925.0, 45.0, 80.0),
        items = {
            {item = 'casinochip', chance = 15, min = 1, max = 5},
            {item = 'goldwatch', chance = 5, min = 1, max = 1}
        }
    },
    -- Hospital dumpsters might have medical supplies
    ['hospital'] = {
        radius = 80.0,
        center = vector3(295.0, -1447.0, 29.0),
        items = {
            {item = 'bandage', chance = 20, min = 1, max = 3},
            {item = 'painkillers', chance = 15, min = 1, max = 2}
        }
    }
}

-- ==========================================--
--            FEATURE TOGGLES                --
-- ==========================================--
Config.Features = {
    npcReactions = true,    -- Enable/disable NPC reactions
    timeImpact = true,      -- Enable/disable time of day impact
    weatherImpact = true,   -- Enable/disable weather impact
    collectibles = true,    -- Enable/disable collectibles system
    crafting = true,        -- Enable/disable crafting system
    trashRoutes = true      -- Enable/disable trash routes
}

-- ==========================================--
--            NPC REACTIONS                  --
-- ==========================================--
Config.NPCReactions = {
    enabled = Config.Features.npcReactions,
    chanceToSpawn = 25,  -- % chance an NPC notices and reacts
    policeCallChance = 20, -- % chance the NPC calls police
    dialogues = {
        "Hey! Get away from there!",
        "What are you doing in the trash?",
        "That's disgusting! Stop that!",
        "I'm calling the cops on you!",
        "You homeless or something?"
    }
}

-- ==========================================--
--        TIME & WEATHER IMPACT              --
-- ==========================================--
Config.TimeImpact = {
    enabled = Config.Features.timeImpact,
    nightBonus = {  -- Better loot at night when fewer people are around
        timeRange = {22, 5},  -- 10PM to 5AM
        chanceMultiplier = 1.5,
        amountMultiplier = 1.2
    }
}

Config.WeatherImpact = {
    enabled = Config.Features.weatherImpact,
    rainPenalty = {  -- Rain makes trash wet and less valuable
        weatherTypes = {'RAIN', 'THUNDER'},
        chanceMultiplier = 0.8
    }
}

-- ==========================================--
--           MINIGAME SETTINGS              --
-- ==========================================--
Config.LockpickSettings = {
    easy = {circles = 2, time = 10},
    medium = {circles = 3, time = 15},
    hard = {circles = 4, time = 20}
}

-- ==========================================--
--           COLLECTIBLES SYSTEM            --
-- ==========================================--
Config.Collectibles = {
    enabled = Config.Features.collectibles,
    items = {
        {id = 'bottle_cap_red', name = 'Red Bottle Cap', chance = 2},
        {id = 'bottle_cap_blue', name = 'Blue Bottle Cap', chance = 2},
        {id = 'bottle_cap_green', name = 'Green Bottle Cap', chance = 2},
        {id = 'bottle_cap_gold', name = 'Gold Bottle Cap', chance = 0.5},
    },
    rewards = {
        {
            required = {'bottle_cap_red', 'bottle_cap_blue', 'bottle_cap_green'},
            reward = {item = 'lockpick', amount = 1},
            name = "RGB Collection"
        },
        {
            required = {'bottle_cap_gold'},
            reward = {item = 'goldbar', amount = 1},
            name = "Gold Collection"
        }
    }
}

-- ==========================================--
--             CRAFTING SYSTEM              --
-- ==========================================--
Config.Crafting = {
    enabled = Config.Features.crafting,
    recipes = {
        {
            name = "Lockpick",
            items = {
                {item = "metalscrap", amount = 4},
                {item = "plastic", amount = 2}
            },
            result = {item = "lockpick", amount = 1}
        },
        {
            name = "Bandage",
            items = {
                {item = "cloth", amount = 2},
                {item = "alcohol", amount = 1}
            },
            result = {item = "bandage", amount = 1}
        }
    }
}

-- ==========================================--
--              TRASH ROUTES                --
-- ==========================================--
Config.TrashRoutes = {
    enabled = Config.Features.trashRoutes,
    minBins = 5,
    maxBins = 8,
    searchRadius = 200.0,
    rewards = {
        bonus = {item = 'cash', min = 100, max = 500},
        bonusChance = 75
    }
}

-- ==========================================--
--           RECYCLING CENTER                --
-- ==========================================--
Config.RecyclingCenter = {
    location = vector3(-354.26, -1542.35, 27.72), -- Location near Alta recycling center
    blip = {
        sprite = 365,
        color = 2,
        scale = 0.8,
        name = "Recycling Center"
    },
    ped = {
        model = "s_m_y_dockwork_01", -- Worker model
        heading = 280.0,
        scenario = "WORLD_HUMAN_CLIPBOARD"
    }
}
