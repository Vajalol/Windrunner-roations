local addonName, WR = ...

-- Dungeons data module - stores dungeon and encounter information
WR.Data.Dungeons = {}

-- Dungeon affixes
local AFFIXES = {
    [3] = { id = 3, name = "Volcanic", description = "While in combat, enemies periodically cause gouts of flame to erupt beneath the feet of distant players." },
    [4] = { id = 4, name = "Necrotic", description = "All enemies' melee attacks apply a stacking blight that inflicts damage over time and reduces healing received." },
    [6] = { id = 6, name = "Raging", description = "Enemies enrage at 30% health remaining, dealing 75% increased damage until defeated." },
    [7] = { id = 7, name = "Bolstering", description = "When any enemy dies, its death cry empowers nearby allies, increasing their maximum health and damage by 20%." },
    [8] = { id = 8, name = "Sanguine", description = "When enemies die, they leave behind a pool of blood that grows. Enemies in the pool are healed for 5% max health and players standing in it are damaged for 10% max health." },
    [9] = { id = 9, name = "Tyrannical", description = "Bosses have 30% more health and inflict up to 15% increased damage." },
    [10] = { id = 10, name = "Fortified", description = "Non-boss enemies have 20% more health and inflict up to 30% increased damage." },
    [11] = { id = 11, name = "Bursting", description = "When slain, non-boss enemies explode, causing all players to suffer 12% of their maximum health in damage over 5 sec. This effect stacks." },
    [12] = { id = 12, name = "Grievous", description = "Injured players suffer increasing damage over time until healed above 90% health." },
    [13] = { id = 13, name = "Explosive", description = "While in combat, enemies periodically summon Explosive Orbs that will detonate if not destroyed." },
    [14] = { id = 14, name = "Quaking", description = "Players periodically emit a shockwave, afflicting nearby allies with Quake." },
    [123] = { id = 123, name = "Spiteful", description = "Fiends rise from the corpses of non-boss enemies and pursue random players." },
    [124] = { id = 124, name = "Storming", description = "While in combat, enemies periodically summon damaging whirlwinds." },
    [130] = { id = 130, name = "Encrypted", description = "Encrypted enemies throughout the dungeon possess Relics that empower Enemies." },
    [134] = { id = 134, name = "Entangling", description = "While in combat, webs periodically appear beneath the feet of distant players, rooting and applying Entangled Web. Entangled Web inflicts Nature damage every 1 second." },
    [135] = { id = 135, name = "Afflicted", description = "While in combat, afflicted souls periodically seek the aid of players. Some souls explode in negative energy when they reach their target, while others continue to follow, bestowing a boon that increases damage and healing." },
}

-- Dungeon Info for The War Within Season 2
local DUNGEONS = {
    -- Dawnbreaker
    [2579] = {
        id = 2579,
        name = "Dawn of the Infinite: Dawnbreak",
        shortName = "Dawnbreak",
        instanceType = "party",
        mapID = 2195,
        timeLimit = 35 * 60, -- 35 minutes
        bosses = 4,
        expansion = 10, -- The War Within
        season = 2,
        encounters = {
            [2526] = { 
                id = 2526, 
                name = "Tyr, the Infinite Keeper",
                interruptPriorities = {
                    [411164] = 90, -- Infinite Bolt
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = false, -- Single target focus fight
                }
            },
            [2515] = { 
                id = 2515, 
                name = "Morchie", 
                interruptPriorities = {
                    [412505] = 100, -- Greater Healing Touch
                    [412027] = 90, -- Tempoblast
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true, -- AOE adds phases
                }
            },
            [2523] = { 
                id = 2523, 
                name = "Time-Lost Battlefield",
                interruptPriorities = {
                    [408228] = 100, -- Temporal Sickness (from the Temporal Fusion)
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            },
            [2536] = { 
                id = 2536, 
                name = "Chrono-Lord Deios",
                interruptPriorities = {
                    [416139] = 100, -- Temporal Breath
                    [418046] = 90, -- Infinity Bolt
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            }
        },
        interruptPriorities = {
            [408228] = 100, -- Temporal Sickness
            [412505] = 100, -- Greater Healing Touch
            [411164] = 80, -- Infinite Bolt
            [412027] = 90, -- Tempoblast
        },
        rotationSettings = {
            enableInterrupts = true,
            enableDefensives = true,
            enableCooldowns = false, -- Save for bosses by default
            enableAOE = true,
        }
    },
    
    -- Galakrond's Fall
    [2570] = {
        id = 2570,
        name = "Galakrond's Fall",
        shortName = "Galakrond",
        instanceType = "party",
        mapID = 2251,
        timeLimit = 30 * 60, -- 30 minutes
        bosses = 4,
        expansion = 10, -- The War Within
        season = 2,
        encounters = {
            [2535] = { 
                id = 2535, 
                name = "Warlord Kagra",
                interruptPriorities = {
                    [404583] = 100, -- Ice Storm
                    [404045] = 90, -- Frozen Solid
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            },
            [2537] = { 
                id = 2537, 
                name = "Entropy",
                interruptPriorities = {},
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            },
            [2538] = { 
                id = 2538, 
                name = "Loszkeleth",
                interruptPriorities = {
                    [404654] = 100, -- Frost Overload
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = false, -- Mostly single target
                }
            },
            [2528] = { 
                id = 2528, 
                name = "Vydhar",
                interruptPriorities = {
                    [405279] = 100, -- Arcane Barrage
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = false, -- Single target priority
                }
            }
        },
        interruptPriorities = {
            [404583] = 100, -- Ice Storm
            [404045] = 90, -- Frozen Solid
            [404654] = 100, -- Frost Overload
            [405279] = 100, -- Arcane Barrage
            [404789] = 95, -- Frost Bolt
        },
        rotationSettings = {
            enableInterrupts = true,
            enableDefensives = true,
            enableCooldowns = false, -- Save for bosses by default
            enableAOE = true,
        }
    },
    
    -- Cinderbrew
    [2579] = {
        id = 2579,
        name = "The Cinderbrew Meadery",
        shortName = "Cinderbrew",
        instanceType = "party",
        mapID = 2352,
        timeLimit = 31 * 60, -- 31 minutes
        bosses = 4,
        expansion = 10, -- The War Within
        season = 2,
        encounters = {
            [2537] = { 
                id = 2537, 
                name = "Kegcrusher Bimbsy",
                interruptPriorities = {
                    [420421] = 100, -- Keg Breakin'
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            },
            [2540] = { 
                id = 2540, 
                name = "Gorgosh the Pygmy Behemoth", 
                interruptPriorities = {},
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = false, -- Single target priority
                }
            },
            [2538] = { 
                id = 2538, 
                name = "Burnished Kragennan",
                interruptPriorities = {
                    [423230] = 100, -- Frenzied Thirst
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = false, -- Single target with add phases
                }
            },
            [2539] = { 
                id = 2539, 
                name = "Cinderbrew Champion",
                interruptPriorities = {
                    [427412] = 100, -- Rising Heat
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true, -- Multiple targets
                }
            }
        },
        interruptPriorities = {
            [420421] = 100, -- Keg Breakin'
            [423230] = 100, -- Frenzied Thirst
            [427412] = 100, -- Rising Heat
            [421348] = 95, -- Ale Blast
        },
        rotationSettings = {
            enableInterrupts = true,
            enableDefensives = true,
            enableCooldowns = false, -- Save for bosses by default
            enableAOE = true,
        }
    },
    
    -- Sunken City
    [2515] = {
        id = 2515,
        name = "Sunken City of Neltharion",
        shortName = "Sunken City",
        instanceType = "party",
        mapID = 2196,
        timeLimit = 33 * 60, -- 33 minutes
        bosses = 4,
        expansion = 10, -- The War Within
        season = 2,
        encounters = {
            [2519] = { 
                id = 2519, 
                name = "Molgoth",
                interruptPriorities = {},
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            },
            [2517] = { 
                id = 2517, 
                name = "Thal'kiel the Lifebinder",
                interruptPriorities = {
                    [401010] = 100, -- Binding Flames
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            },
            [2510] = { 
                id = 2510, 
                name = "Belzish, Maiden of Ruin",
                interruptPriorities = {
                    [408227] = 100, -- Blazing Breath
                },
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = false, -- Mostly single target
                }
            },
            [2512] = { 
                id = 2512, 
                name = "The Undisputed Champion",
                interruptPriorities = {},
                rotationSettings = {
                    enableInterrupts = true,
                    enableDefensives = true,
                    enableCooldowns = true,
                    enableAOE = true,
                }
            }
        },
        interruptPriorities = {
            [401010] = 100, -- Binding Flames
            [408227] = 100, -- Blazing Breath
            [404741] = 95, -- Abolishing Flame
            [404548] = 90, -- Earthfury
        },
        rotationSettings = {
            enableInterrupts = true,
            enableDefensives = true,
            enableCooldowns = false, -- Save for bosses by default
            enableAOE = true,
        }
    },
}

-- Initialize the dungeons database
function WR.Data.Dungeons:Initialize()
    -- Process the dungeon data for easier access
    self.Affixes = AFFIXES
    self.DungeonList = {}
    self.EncounterList = {}
    self.InterruptPriorities = {}
    
    -- Process each dungeon
    for dungeonID, dungeonData in pairs(DUNGEONS) do
        -- Add to dungeon list
        self.DungeonList[dungeonID] = dungeonData
        
        -- Extract interrupt priorities
        if dungeonData.interruptPriorities then
            for spellID, priority in pairs(dungeonData.interruptPriorities) do
                self.InterruptPriorities[spellID] = priority
            end
        end
        
        -- Process each encounter
        if dungeonData.encounters then
            for encounterID, encounterData in pairs(dungeonData.encounters) do
                -- Add to encounter list
                self.EncounterList[encounterID] = encounterData
                encounterData.dungeonID = dungeonID
                
                -- Extract interrupt priorities
                if encounterData.interruptPriorities then
                    for spellID, priority in pairs(encounterData.interruptPriorities) do
                        self.InterruptPriorities[spellID] = priority
                    end
                end
            end
        end
    end
    
    WR:Debug("Dungeons data initialized")
end

-- Get a dungeon by ID
function WR.Data.Dungeons:GetDungeonByID(dungeonID)
    return self.DungeonList[dungeonID]
end

-- Get an encounter by ID
function WR.Data.Dungeons:GetEncounterByID(encounterID)
    return self.EncounterList[encounterID]
end

-- Get an affix by ID
function WR.Data.Dungeons:GetAffixByID(affixID)
    return self.Affixes[affixID]
end

-- Get the interrupt priority for a spell
function WR.Data.Dungeons:GetInterruptPriority(spellID)
    return self.InterruptPriorities[spellID] or 0
end

-- Get all dungeons for the current season
function WR.Data.Dungeons:GetCurrentSeasonDungeons()
    local currentDungeons = {}
    
    for dungeonID, dungeonData in pairs(self.DungeonList) do
        if dungeonData.season == 2 then -- Current season is 2
            table.insert(currentDungeons, dungeonData)
        end
    end
    
    return currentDungeons
end

-- Get rotation settings for a dungeon
function WR.Data.Dungeons:GetDungeonRotationSettings(dungeonID)
    local dungeon = self:GetDungeonByID(dungeonID)
    if dungeon and dungeon.rotationSettings then
        return dungeon.rotationSettings
    end
    return nil
end

-- Get rotation settings for an encounter
function WR.Data.Dungeons:GetEncounterRotationSettings(encounterID)
    local encounter = self:GetEncounterByID(encounterID)
    if encounter and encounter.rotationSettings then
        return encounter.rotationSettings
    end
    return nil
end

-- Initialize the dungeons data
WR.Data.Dungeons:Initialize()
