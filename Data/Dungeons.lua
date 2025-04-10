local addonName, WR = ...

-- DungeonsData module for holding data about dungeons, bosses, and mechanics
local DungeonsData = {}
WR.Data = WR.Data or {}
WR.Data.Dungeons = DungeonsData

-- Priority levels for reference
local PRIORITY_LOW = 1
local PRIORITY_MEDIUM = 2
local PRIORITY_HIGH = 3
local PRIORITY_CRITICAL = 4

-- Enemy types for reference
local ENEMY_TYPE_NORMAL = 1
local ENEMY_TYPE_ELITE = 2
local ENEMY_TYPE_MINIBOSS = 3
local ENEMY_TYPE_BOSS = 4

-- ========================
-- The War Within - Season 2
-- ========================

-- Valaran Garden
DungeonsData[2579] = {
    name = "Valaran Garden",
    bosses = {
        -- Iridikron's Sentinel
        [210234] = {
            name = "Iridikron's Sentinel",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Avoid Frozen Wind, CC adds",
                        prioritySpells = {},
                        defensives = true
                    }
                },
                interruptPriorities = {
                    [422776] = PRIORITY_HIGH,   -- Glacial Fusion
                    [420907] = PRIORITY_MEDIUM, -- Paralyzing Blizzard
                },
                avoidance = {
                    [420947] = true, -- Frozen Wind
                }
            }
        },
        -- Cycle Warden
        [204773] = {
            name = "Cycle Warden",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Dodge whirlwinds, focus adds when they spawn",
                        prioritySpells = {},
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [420284] = PRIORITY_HIGH, -- Temporal Detonation
                }
            }
        },
        -- Tindral Sageswift
        [205865] = {
            name = "Tindral Sageswift",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Kite Living Flames, dodge fire patches",
                        prioritySpells = {}
                    },
                    phase2 = {
                        description = "High damage phase, use defensives",
                        defensives = true
                    }
                },
                interruptPriorities = {
                    [419485] = PRIORITY_HIGH,   -- Sunfire Eruption
                    [419596] = PRIORITY_MEDIUM, -- Nature's Bulwark
                }
            }
        },
        -- Larodar, Keeper of the Flame
        [204431] = {
            name = "Larodar, Keeper of the Flame",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Spread for Scorching Roar, avoid Seeds of Flame",
                        prioritySpells = {},
                        defensives = true
                    },
                    phase2 = {
                        description = "Stay spread, dodge flame pools",
                        prioritySpells = {},
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [418539] = PRIORITY_CRITICAL, -- Raging Flame
                }
            }
        }
    },
    enemies = {
        -- Important Trash Mobs
        [204918] = { 
            name = "Blooming Gardener", 
            priority = PRIORITY_HIGH,
            dangerous = true,
            notes = "Heals other mobs, interrupt Growth Surge" 
        },
        [204773] = { 
            name = "Garden Sentinel", 
            priority = PRIORITY_MEDIUM,
            notes = "Has frontal cleave, avoid" 
        },
        [205002] = { 
            name = "Blazing Embercaster", 
            priority = PRIORITY_HIGH,
            notes = "Interrupt Flame Volley" 
        }
    },
    interrupts = {
        -- Priority Interrupts for Trash
        [420776] = PRIORITY_HIGH,   -- Growth Surge
        [420519] = PRIORITY_HIGH,   -- Flame Volley
        [420399] = PRIORITY_MEDIUM, -- Entangling Roots
    },
    avoidable = {
        [420947] = {
            spell = "Frozen Wind",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "frontal"
        },
        [419539] = {
            spell = "Seeds of Flame",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "ground"
        }
    },
    enemyForces = {
        -- Enemy forces values for M+
        [204918] = 4, -- Blooming Gardener
        [204773] = 5, -- Garden Sentinel
        [205002] = 3, -- Blazing Embercaster
        -- More mobs would be added here with proper values
    }
}

-- Cinderbrew Meadery
DungeonsData[2580] = {
    name = "Cinderbrew Meadery",
    bosses = {
        -- Burnished Brewmeister
        [205210] = {
            name = "Burnished Brewmeister",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Avoid fermenting pools, focus keg adds",
                        prioritySpells = {},
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [421024] = PRIORITY_HIGH, -- Fermentation
                }
            }
        },
        -- Head Brewer Voll
        [209524] = {
            name = "Head Brewer Voll",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Spread for Brew Explosion, use defensives for Intoxicating Brew",
                        prioritySpells = {},
                        defensives = true
                    }
                },
                interruptPriorities = {
                    [421630] = PRIORITY_CRITICAL, -- Intoxicating Brew
                }
            }
        },
        -- Dracthyr Flamebender
        [209602] = {
            name = "Dracthyr Flamebender",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Dodge flame patches, CC small adds",
                        prioritySpells = {},
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [422065] = PRIORITY_HIGH, -- Dragonflame Channel
                }
            }
        },
        -- Gakaraz
        [209669] = {
            name = "Gakaraz",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Spread out, use defensives during Flaming Onslaught",
                        prioritySpells = {},
                        defensives = true
                    },
                    phase2 = {
                        description = "Focus down adds quickly, avoid standing in fire",
                        prioritySpells = {},
                        aoe = true,
                        burst = true
                    }
                }
            }
        }
    },
    enemies = {
        -- Important Trash Mobs
        [205212] = { 
            name = "Cinderbrew Guardian", 
            priority = PRIORITY_HIGH,
            dangerous = true,
            notes = "Has frontal cleave, tank away from group" 
        },
        [205276] = { 
            name = "Volatile Emberspark", 
            priority = PRIORITY_HIGH,
            notes = "Explodes on death, keep away from group" 
        },
        [205298] = { 
            name = "Cinderbrew Brewmaster", 
            priority = PRIORITY_MEDIUM,
            notes = "Throws brew that causes damage over time" 
        }
    },
    interrupts = {
        -- Priority Interrupts for Trash
        [421234] = PRIORITY_HIGH,   -- Molten Shield
        [421389] = PRIORITY_HIGH,   -- Brew Toss
        [421402] = PRIORITY_MEDIUM, -- Ember Detonation
    },
    avoidable = {
        [421053] = {
            spell = "Fermenting Pool",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "ground"
        },
        [421636] = {
            spell = "Brew Explosion",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "targeted"
        }
    },
    enemyForces = {
        -- Enemy forces values for M+
        [205212] = 5, -- Cinderbrew Guardian
        [205276] = 3, -- Volatile Emberspark
        [205298] = 4, -- Cinderbrew Brewmaster
        -- More mobs would be added here with proper values
    }
}

-- The Dawnbreaker
DungeonsData[2570] = {
    name = "The Dawnbreaker",
    bosses = {
        -- Anduin Lothar
        [208459] = {
            name = "Anduin Lothar",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Avoid frontal attacks, spread for Valorous Charge",
                        prioritySpells = {},
                        defensives = true
                    }
                },
                interruptPriorities = {
                    [418585] = PRIORITY_MEDIUM, -- Rallying Cry
                }
            }
        },
        -- Khadgar
        [208447] = {
            name = "Khadgar",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Dodge arcane orbs, interrupt Arcane Blast",
                        prioritySpells = {}
                    },
                    phase2 = {
                        description = "Focus down clone images quickly",
                        prioritySpells = {},
                        aoe = true,
                        burst = true
                    }
                },
                interruptPriorities = {
                    [419123] = PRIORITY_HIGH, -- Arcane Blast
                }
            }
        },
        -- Alleria Windrunner
        [208442] = {
            name = "Alleria Windrunner",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Stay spread, dodge Void zones",
                        prioritySpells = {}
                    }
                },
                interruptPriorities = {
                    [419515] = PRIORITY_HIGH, -- Void Bolt Volley
                }
            }
        },
        -- Turalyon
        [208445] = {
            name = "Turalyon",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Move away during Judgment of Light, use defensives for Inquisition",
                        prioritySpells = {},
                        defensives = true
                    },
                    phase2 = {
                        description = "Maximize DPS during vulnerability phases",
                        prioritySpells = {},
                        burst = true
                    }
                }
            }
        }
    },
    enemies = {
        -- Important Trash Mobs
        [208462] = { 
            name = "Alliance Knight", 
            priority = PRIORITY_MEDIUM,
            notes = "Has shield reflect, avoid attacking during Shield Wall" 
        },
        [208464] = { 
            name = "Alliance Mage", 
            priority = PRIORITY_HIGH,
            notes = "Interrupt Fireball" 
        },
        [208463] = { 
            name = "Alliance Priest", 
            priority = PRIORITY_HIGH,
            dangerous = true,
            notes = "Interrupt Heal" 
        }
    },
    interrupts = {
        -- Priority Interrupts for Trash
        [419050] = PRIORITY_HIGH,   -- Heal
        [419052] = PRIORITY_MEDIUM, -- Fireball
        [419057] = PRIORITY_HIGH,   -- Mind Control
    },
    avoidable = {
        [418580] = {
            spell = "Valorous Charge",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "targeted"
        },
        [419127] = {
            spell = "Arcane Orb",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "ground"
        }
    },
    enemyForces = {
        -- Enemy forces values for M+
        [208462] = 4, -- Alliance Knight
        [208464] = 3, -- Alliance Mage
        [208463] = 4, -- Alliance Priest
        -- More mobs would be added here with proper values
    }
}

-- Chamber of the Aspects
DungeonsData[2582] = {
    name = "Chamber of the Aspects",
    bosses = {
        -- Blight of Galakrond
        [206172] = {
            name = "Blight of Galakrond",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Dodge Void Zones, spread for Necrotic Breath",
                        prioritySpells = {},
                        defensives = true
                    }
                }
            }
        },
        -- Chronormu
        [205290] = {
            name = "Chronormu",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Handle Time Anomalies, use defensives during Time Acceleration",
                        prioritySpells = {},
                        defensives = true
                    }
                }
            }
        },
        -- Alexstrasza the Life-Binder
        [204853] = {
            name = "Alexstrasza the Life-Binder",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Move as a group during Gift of Life, focus fire drakes",
                        prioritySpells = {}
                    },
                    phase2 = {
                        description = "Spread out for Flame Buffet, use defensive cooldowns",
                        prioritySpells = {},
                        defensives = true
                    }
                }
            }
        },
        -- Vyranoth
        [204481] = {
            name = "Vyranoth",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Move out of Twilight Flames, use defensives for Twilight Decimation",
                        prioritySpells = {},
                        defensives = true
                    },
                    phase2 = {
                        description = "Prioritize adds, avoid standing in darkness",
                        prioritySpells = {},
                        aoe = true
                    }
                }
            }
        }
    },
    enemies = {
        -- Important Trash Mobs
        [206099] = { 
            name = "Twilight Drake", 
            priority = PRIORITY_MEDIUM,
            notes = "Interrupt Twilight Flames" 
        },
        [206079] = { 
            name = "Bronze Timekeeper", 
            priority = PRIORITY_HIGH,
            dangerous = true,
            notes = "Can rewind time, priority target" 
        },
        [206128] = { 
            name = "Void Aberration", 
            priority = PRIORITY_HIGH,
            notes = "Explodes on death, keep away from group" 
        }
    },
    interrupts = {
        -- Priority Interrupts for Trash
        [417989] = PRIORITY_HIGH,   -- Twilight Flames
        [417992] = PRIORITY_MEDIUM, -- Temporal Shift
        [418025] = PRIORITY_HIGH,   -- Void Eruption
    },
    avoidable = {
        [416986] = {
            spell = "Necrotic Breath",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "frontal"
        },
        [418538] = {
            spell = "Twilight Flames",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "ground"
        }
    },
    enemyForces = {
        -- Enemy forces values for M+
        [206099] = 4, -- Twilight Drake
        [206079] = 5, -- Bronze Timekeeper
        [206128] = 3, -- Void Aberration
        -- More mobs would be added here with proper values
    }
}

-- Darkflame Cleft
DungeonsData[2584] = {
    name = "Darkflame Cleft",
    bosses = {
        -- Molten Primalist
        [208311] = {
            name = "Molten Primalist",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Dodge lava waves, spread for Molten Eruption",
                        prioritySpells = {},
                        defensives = true
                    }
                },
                interruptPriorities = {
                    [422917] = PRIORITY_HIGH, -- Lava Surge
                }
            }
        },
        -- Goregrind
        [208438] = {
            name = "Goregrind",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Kite during Crushing Charge, stack for Cleave",
                        prioritySpells = {}
                    }
                }
            }
        },
        -- Ancient Pyrelord
        [209390] = {
            name = "Ancient Pyrelord",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Use defensives during Inferno Nova, focus fire adds",
                        prioritySpells = {},
                        defensives = true,
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [423079] = PRIORITY_CRITICAL, -- Pyroblast
                }
            }
        },
        -- Emberblaze
        [209033] = {
            name = "Emberblaze",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Avoid Standing in Lava, use defensives during Darkflame Cleave",
                        prioritySpells = {},
                        defensives = true
                    },
                    phase2 = {
                        description = "Spread out, focus down elemental adds",
                        prioritySpells = {},
                        aoe = true,
                        burst = true
                    }
                }
            }
        }
    },
    enemies = {
        -- Important Trash Mobs
        [208302] = { 
            name = "Lava Elemental", 
            priority = PRIORITY_MEDIUM,
            notes = "Creates lava pools on death" 
        },
        [208307] = { 
            name = "Dark Flamecaller", 
            priority = PRIORITY_HIGH,
            dangerous = true,
            notes = "Interrupt Shadow Bolt Volley" 
        },
        [208305] = { 
            name = "Magma Tentacle", 
            priority = PRIORITY_HIGH,
            notes = "Knocks players back, focus target" 
        }
    },
    interrupts = {
        -- Priority Interrupts for Trash
        [423125] = PRIORITY_HIGH,   -- Shadow Bolt Volley
        [423136] = PRIORITY_MEDIUM, -- Magma Burst
        [423150] = PRIORITY_HIGH,   -- Ember Shield
    },
    avoidable = {
        [422924] = {
            spell = "Molten Eruption",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "targeted"
        },
        [423084] = {
            spell = "Inferno Nova",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "aoe"
        }
    },
    enemyForces = {
        -- Enemy forces values for M+
        [208302] = 3, -- Lava Elemental
        [208307] = 4, -- Dark Flamecaller
        [208305] = 3, -- Magma Tentacle
        -- More mobs would be added here with proper values
    }
}

-- Sunken Hollow
DungeonsData[2581] = {
    name = "Sunken Hollow",
    bosses = {
        -- Decatriarch Wraatom
        [208458] = {
            name = "Decatriarch Wraatom",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Avoid Shadow Crash, focus adds",
                        prioritySpells = {},
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [421633] = PRIORITY_HIGH, -- Shadow Bolt
                }
            }
        },
        -- Teramir
        [208967] = {
            name = "Teramir",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Dodge falling rocks, use defensives during Earthen Barrage",
                        prioritySpells = {},
                        defensives = true
                    }
                }
            }
        },
        -- Drowned Depths
        [209253] = {
            name = "Drowned Depths",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Avoid whirlpools, kill adds quickly",
                        prioritySpells = {},
                        aoe = true
                    }
                },
                interruptPriorities = {
                    [421812] = PRIORITY_HIGH, -- Aquatic Surge
                }
            }
        },
        -- Iron Dagger
        [208363] = {
            name = "Iron Dagger",
            tactics = {
                phases = {
                    phase1 = {
                        description = "Drop poison pools away from group, high movement",
                        prioritySpells = {}
                    },
                    phase2 = {
                        description = "Use defensives during Venomous Onslaught",
                        prioritySpells = {},
                        defensives = true,
                        burst = true
                    }
                }
            }
        }
    },
    enemies = {
        -- Important Trash Mobs
        [208404] = { 
            name = "Nerubian Seer", 
            priority = PRIORITY_HIGH,
            dangerous = true,
            notes = "Interrupt Shadow Bolt" 
        },
        [208401] = { 
            name = "Earth Elemental", 
            priority = PRIORITY_MEDIUM,
            notes = "Has knockback ability" 
        },
        [208409] = { 
            name = "Deep One", 
            priority = PRIORITY_HIGH,
            notes = "Creates damaging pools" 
        }
    },
    interrupts = {
        -- Priority Interrupts for Trash
        [421675] = PRIORITY_HIGH,   -- Shadow Bolt
        [421702] = PRIORITY_MEDIUM, -- Earth Shock
        [421724] = PRIORITY_HIGH,   -- Aquatic Healing
    },
    avoidable = {
        [421639] = {
            spell = "Shadow Crash",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "targeted"
        },
        [421758] = {
            spell = "Whirlpool",
            priority = PRIORITY_HIGH,
            isBossMechanic = true,
            avoidType = "ground"
        }
    },
    enemyForces = {
        -- Enemy forces values for M+
        [208404] = 4, -- Nerubian Seer
        [208401] = 3, -- Earth Elemental
        [208409] = 3, -- Deep One
        -- More mobs would be added here with proper values
    }
}

-- Return the module
return DungeonsData