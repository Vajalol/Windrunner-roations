local addonName, WR = ...

-- ClassKnowledge module for storing theorycrafting information and rotation optimizations
local ClassKnowledge = {}
WR.ClassKnowledge = ClassKnowledge

-- Constants for classes and specs
local CLASS = {
    WARRIOR = "WARRIOR",
    PALADIN = "PALADIN",
    HUNTER = "HUNTER",
    ROGUE = "ROGUE",
    PRIEST = "PRIEST",
    DEATHKNIGHT = "DEATHKNIGHT",
    SHAMAN = "SHAMAN",
    MAGE = "MAGE",
    WARLOCK = "WARLOCK",
    MONK = "MONK",
    DRUID = "DRUID",
    DEMONHUNTER = "DEMONHUNTER",
    EVOKER = "EVOKER"
}

local SPEC = {
    -- Warrior
    ARMS = 1,
    FURY = 2,
    PROTECTION_WARRIOR = 3,
    
    -- Paladin
    HOLY_PALADIN = 1,
    PROTECTION_PALADIN = 2,
    RETRIBUTION = 3,
    
    -- Hunter
    BEAST_MASTERY = 1,
    MARKSMANSHIP = 2,
    SURVIVAL = 3,
    
    -- Rogue
    ASSASSINATION = 1,
    OUTLAW = 2,
    SUBTLETY = 3,
    
    -- Priest
    DISCIPLINE = 1,
    HOLY_PRIEST = 2,
    SHADOW = 3,
    
    -- Death Knight
    BLOOD = 1,
    FROST_DK = 2,
    UNHOLY = 3,
    
    -- Shaman
    ELEMENTAL = 1,
    ENHANCEMENT = 2,
    RESTORATION_SHAMAN = 3,
    
    -- Mage
    ARCANE = 1,
    FIRE = 2,
    FROST_MAGE = 3,
    
    -- Warlock
    AFFLICTION = 1,
    DEMONOLOGY = 2,
    DESTRUCTION = 3,
    
    -- Monk
    BREWMASTER = 1,
    MISTWEAVER = 2,
    WINDWALKER = 3,
    
    -- Druid
    BALANCE = 1,
    FERAL = 2,
    GUARDIAN = 3,
    RESTORATION_DRUID = 4,
    
    -- Demon Hunter
    HAVOC = 1,
    VENGEANCE = 2,
    
    -- Evoker
    DEVASTATION = 1,
    PRESERVATION = 2,
    AUGMENTATION = 3
}

-- Structure for situation types
local SITUATION = {
    SINGLE_TARGET = "single_target",
    CLEAVE = "cleave",
    AOE = "aoe",
    EXECUTE = "execute",
    MOVEMENT = "movement",
    BURST = "burst",
    SUSTAINED = "sustained"
}

-- Reference Enum for resources
local RESOURCE = {
    MANA = Enum.PowerType.Mana,
    RAGE = Enum.PowerType.Rage,
    FOCUS = Enum.PowerType.Focus,
    ENERGY = Enum.PowerType.Energy,
    COMBO_POINTS = Enum.PowerType.ComboPoints,
    RUNES = Enum.PowerType.Runes,
    RUNIC_POWER = Enum.PowerType.RunicPower,
    SOUL_SHARDS = Enum.PowerType.SoulShards,
    ASTRAL_POWER = Enum.PowerType.LunarPower,
    HOLY_POWER = Enum.PowerType.HolyPower,
    MAELSTROM = Enum.PowerType.Maelstrom,
    CHI = Enum.PowerType.Chi,
    INSANITY = Enum.PowerType.Insanity,
    FURY = Enum.PowerType.Fury,
    PAIN = Enum.PowerType.Pain,
    ESSENCE = Enum.PowerType.Essence
}

-- Class Knowledge Database
local knowledgeDB = {
    -- MAGE
    [CLASS.MAGE] = {
        -- FROST
        [SPEC.FROST_MAGE] = {
            spells = {
                -- Core rotational abilities
                FROSTBOLT = {id = 116, name = "Frostbolt", icon = 135846, category = "generator"},
                ICE_LANCE = {id = 30455, name = "Ice Lance", icon = 135844, category = "core"},
                FLURRY = {id = 44614, name = "Flurry", icon = 135849, category = "proc"},
                FROZEN_ORB = {id = 84714, name = "Frozen Orb", icon = 630481, category = "cooldown"},
                BLIZZARD = {id = 190356, name = "Blizzard", icon = 135857, category = "aoe"},
                COMET_STORM = {id = 153595, name = "Comet Storm", icon = 2126009, category = "talent"},
                RAY_OF_FROST = {id = 205021, name = "Ray of Frost", icon = 1698700, category = "talent"},
                GLACIAL_SPIKE = {id = 199786, name = "Glacial Spike", icon = 1397904, category = "talent"},
                ICY_VEINS = {id = 12472, name = "Icy Veins", icon = 135838, category = "cooldown"},
                TIME_WARP = {id = 80353, name = "Time Warp", icon = 458224, category = "raid_cooldown"},
                
                -- Defensive/utility abilities
                ICE_BLOCK = {id = 45438, name = "Ice Block", icon = 135841, category = "defensive"},
                ICE_BARRIER = {id = 11426, name = "Ice Barrier", icon = 135988, category = "defensive"},
                FROST_NOVA = {id = 122, name = "Frost Nova", icon = 135848, category = "utility"},
                BLINK = {id = 1953, name = "Blink", icon = 135736, category = "utility"},
                SUMMON_WATER_ELEMENTAL = {id = 31687, name = "Summon Water Elemental", icon = 135862, category = "pet"},
                CONE_OF_COLD = {id = 120, name = "Cone of Cold", icon = 135852, category = "utility"},
                
                -- Important buffs and procs to track
                FINGERS_OF_FROST_BUFF = {id = 44544, name = "Fingers of Frost", icon = 1783007, category = "buff"},
                BRAIN_FREEZE_BUFF = {id = 190446, name = "Brain Freeze", icon = 236206, category = "buff"},
                WINTERS_CHILL = {id = 228358, name = "Winter's Chill", icon = 135836, category = "debuff"},
                ICY_VEINS_BUFF = {id = 12472, name = "Icy Veins", icon = 135838, category = "buff"},
                
                -- Talents to track
                FREEZING_RAIN_BUFF = {id = 270232, name = "Freezing Rain", icon = 2126012, category = "buff"},
                SLICK_ICE_BUFF = {id = 382143, name = "Slick Ice", icon = 135841, category = "buff"}
            },
            
            resources = {
                primary = RESOURCE.MANA
            },
            
            priorities = {
                [SITUATION.SINGLE_TARGET] = {
                    -- Maintain buffs/CDs
                    {spell = "ICY_VEINS", condition = "IsUsable() and not HasBuff() and IsBurstPhase()"},
                    
                    -- Use procs that are about to expire
                    {spell = "FLURRY", condition = "HasBuff(BRAIN_FREEZE_BUFF) and BuffRemains(BRAIN_FREEZE_BUFF) < 3 and not TargetHasDebuff(WINTERS_CHILL)"},
                    
                    -- Core rotation
                    {spell = "FROZEN_ORB", condition = "IsUsable() and not HasBuff(FINGERS_OF_FROST_BUFF)"},
                    {spell = "RAY_OF_FROST", condition = "IsUsable() and not IsMoving()"},
                    {spell = "GLACIAL_SPIKE", condition = "IsUsable() and (HasBuff(BRAIN_FREEZE_BUFF) or SpellCharges(FINGERS_OF_FROST_BUFF) >= 1)"},
                    {spell = "FLURRY", condition = "HasBuff(BRAIN_FREEZE_BUFF) and (LastSpell(FROSTBOLT) or LastSpell(GLACIAL_SPIKE))"},
                    {spell = "ICE_LANCE", condition = "HasBuff(FINGERS_OF_FROST_BUFF) or TargetHasDebuff(WINTERS_CHILL)"},
                    {spell = "COMET_STORM", condition = "IsUsable()"},
                    {spell = "FROSTBOLT", condition = "true"} -- Filler spell
                },
                
                [SITUATION.AOE] = {
                    -- Maintain buffs/CDs
                    {spell = "ICY_VEINS", condition = "IsUsable() and not HasBuff()"},
                    
                    -- AoE abilities
                    {spell = "FROZEN_ORB", condition = "IsUsable()"},
                    {spell = "BLIZZARD", condition = "IsUsable() and (HasBuff(FREEZING_RAIN_BUFF) or TargetCount() >= 2)"},
                    {spell = "COMET_STORM", condition = "IsUsable()"},
                    {spell = "ICE_LANCE", condition = "HasBuff(FINGERS_OF_FROST_BUFF)"},
                    {spell = "FLURRY", condition = "HasBuff(BRAIN_FREEZE_BUFF) and LastSpell(FROSTBOLT)"},
                    {spell = "FROSTBOLT", condition = "true"} -- Filler spell
                },
                
                [SITUATION.MOVEMENT] = {
                    {spell = "ICE_LANCE", condition = "true"},
                    {spell = "CONE_OF_COLD", condition = "IsUsable() and IsInRange()"}
                }
            },
            
            talent_builds = {
                ["Standard"] = {
                    talents = "123aaaa123aaaa12aaaa",
                    description = "Standard Frost Mage build focused on Brain Freeze and Glacial Spike",
                    priority_modifications = {
                        -- Any modifications to the standard priority for this build
                    }
                },
                ["AoE Focus"] = {
                    talents = "123aaaa321aaa13aaa",
                    description = "AoE-focused build with Freezing Rain and extra Blizzard damage",
                    priority_modifications = {
                        increase = {"BLIZZARD", "FROZEN_ORB"},
                        decrease = {"GLACIAL_SPIKE"}
                    }
                }
            },
            
            special_mechanics = {
                shatter_combo = {
                    description = "Cast Frostbolt followed by Flurry (with Brain Freeze proc) followed by Ice Lance to benefit from Winter's Chill",
                    implementation = "Track spell cast sequence and boost Ice Lance priority after Flurry if previous spell was Frostbolt"
                },
                winters_chill = {
                    description = "Winter's Chill increases the chance for spells to critically strike the target",
                    implementation = "Track Winter's Chill debuff on target and prioritize Ice Lance while active"
                }
            }
        },
        
        -- FIRE
        [SPEC.FIRE] = {
            spells = {
                -- Core rotational abilities
                FIREBALL = {id = 133, name = "Fireball", icon = 135812, category = "generator"},
                FIRE_BLAST = {id = 108853, name = "Fire Blast", icon = 135807, category = "proc"},
                PYROBLAST = {id = 11366, name = "Pyroblast", icon = 135808, category = "proc"},
                PHOENIX_FLAMES = {id = 257541, name = "Phoenix Flames", icon = 135813, category = "core"},
                FLAMESTRIKE = {id = 2120, name = "Flamestrike", icon = 135826, category = "aoe"},
                DRAGONS_BREATH = {id = 31661, name = "Dragon's Breath", icon = 134153, category = "utility"},
                SCORCH = {id = 2948, name = "Scorch", icon = 135827, category = "filler"},
                COMBUSTION = {id = 190319, name = "Combustion", icon = 135824, category = "cooldown"},
                TIME_WARP = {id = 80353, name = "Time Warp", icon = 458224, category = "raid_cooldown"},
                LIVING_BOMB = {id = 44457, name = "Living Bomb", icon = 236220, category = "talent"},
                METEOR = {id = 153561, name = "Meteor", icon = 1033911, category = "talent"},
                
                -- Defensive/utility abilities
                ICE_BLOCK = {id = 45438, name = "Ice Block", icon = 135841, category = "defensive"},
                BLAZING_BARRIER = {id = 235313, name = "Blazing Barrier", icon = 135806, category = "defensive"},
                BLINK = {id = 1953, name = "Blink", icon = 135736, category = "utility"},
                
                -- Important buffs and procs to track
                HEATING_UP = {id = 48107, name = "Heating Up", icon = 460857, category = "buff"},
                HOT_STREAK = {id = 48108, name = "Hot Streak", icon = 460857, category = "buff"},
                COMBUSTION_BUFF = {id = 190319, name = "Combustion", icon = 135824, category = "buff"},
                ENHANCED_PYROTECHNICS = {id = 157644, name = "Enhanced Pyrotechnics", icon = 460857, category = "buff"}
            },
            
            resources = {
                primary = RESOURCE.MANA
            },
            
            priorities = {
                [SITUATION.SINGLE_TARGET] = {
                    -- Combustion phase
                    {spell = "COMBUSTION", condition = "IsUsable() and not HasBuff() and IsBurstPhase()"},
                    {spell = "PYROBLAST", condition = "HasBuff(HOT_STREAK) and HasBuff(COMBUSTION_BUFF)"},
                    {spell = "FIRE_BLAST", condition = "HasBuff(HEATING_UP) and HasBuff(COMBUSTION_BUFF) and SpellCharges() > 0"},
                    
                    -- Outside combustion
                    {spell = "PYROBLAST", condition = "HasBuff(HOT_STREAK)"},
                    {spell = "FIRE_BLAST", condition = "HasBuff(HEATING_UP) and not IsOnCooldown() and not HasBuff(HOT_STREAK)"},
                    {spell = "PHOENIX_FLAMES", condition = "HasBuff(HEATING_UP) and not HasBuff(HOT_STREAK) and SpellCharges() > 0"},
                    {spell = "METEOR", condition = "IsUsable()"},
                    {spell = "FIREBALL", condition = "not IsMoving()"},
                    {spell = "SCORCH", condition = "IsMoving()"}
                },
                
                [SITUATION.AOE] = {
                    -- Combustion phase
                    {spell = "COMBUSTION", condition = "IsUsable() and not HasBuff() and IsBurstPhase()"},
                    
                    -- AoE abilities
                    {spell = "FLAMESTRIKE", condition = "HasBuff(HOT_STREAK) and TargetCount() >= 3"},
                    {spell = "METEOR", condition = "IsUsable()"},
                    {spell = "PHOENIX_FLAMES", condition = "SpellCharges() > 0 and TargetCount() >= 3"},
                    {spell = "DRAGONS_BREATH", condition = "IsInRange()"},
                    {spell = "LIVING_BOMB", condition = "IsUsable() and TargetCount() >= 3"},
                    {spell = "FLAMESTRIKE", condition = "HasBuff(HOT_STREAK)"},
                    {spell = "PYROBLAST", condition = "HasBuff(HOT_STREAK) and TargetCount() < 3"},
                    {spell = "FIRE_BLAST", condition = "HasBuff(HEATING_UP) and not IsOnCooldown()"},
                    {spell = "FIREBALL", condition = "not IsMoving()"},
                    {spell = "SCORCH", condition = "IsMoving()"}
                },
                
                [SITUATION.MOVEMENT] = {
                    {spell = "SCORCH", condition = "true"},
                    {spell = "FIRE_BLAST", condition = "HasBuff(HEATING_UP) and not IsOnCooldown()"},
                    {spell = "PHOENIX_FLAMES", condition = "SpellCharges() > 0"},
                    {spell = "DRAGONS_BREATH", condition = "IsInRange()"}
                }
            },
            
            talent_builds = {
                ["Standard"] = {
                    talents = "123aaaa123aaaa12aaaa",
                    description = "Standard Fire Mage build focused on Combustion and Hot Streak",
                    priority_modifications = {
                        -- Any modifications to the standard priority for this build
                    }
                },
                ["Kindling"] = {
                    talents = "123aaaa123baa12aaaa",
                    description = "Combustion-focused build with Kindling for more frequent Combustion usage",
                    priority_modifications = {
                        increase = {"COMBUSTION", "FIRE_BLAST"},
                        decrease = {}
                    }
                }
            },
            
            special_mechanics = {
                hot_streak = {
                    description = "Two crits in a row grant Hot Streak, making Pyroblast or Flamestrike instant cast",
                    implementation = "Track Hot Streak buff and prioritize Pyroblast or Flamestrike (AoE) when active"
                },
                combustion_phase = {
                    description = "During Combustion, all spells gain 100% crit chance, enabling rapid Hot Streak generation",
                    implementation = "Custom rotation during Combustion buff that focuses on maximizing Hot Streak usage"
                }
            }
        },
        
        -- ARCANE
        [SPEC.ARCANE] = {
            spells = {
                -- Core rotational abilities
                ARCANE_BLAST = {id = 30451, name = "Arcane Blast", icon = 135735, category = "generator"},
                ARCANE_BARRAGE = {id = 44425, name = "Arcane Barrage", icon = 135753, category = "spender"},
                ARCANE_MISSILES = {id = 5143, name = "Arcane Missiles", icon = 136096, category = "proc"},
                ARCANE_EXPLOSION = {id = 1449, name = "Arcane Explosion", icon = 136116, category = "aoe"},
                TOUCH_OF_THE_MAGI = {id = 321507, name = "Touch of the Magi", icon = 135734, category = "cooldown"},
                ARCANE_POWER = {id = 12042, name = "Arcane Power", icon = 136048, category = "cooldown"},
                EVOCATION = {id = 12051, name = "Evocation", icon = 136075, category = "cooldown"},
                TIME_WARP = {id = 80353, name = "Time Warp", icon = 458224, category = "raid_cooldown"},
                PRESENCE_OF_MIND = {id = 205025, name = "Presence of Mind", icon = 136031, category = "cooldown"},
                NETHER_TEMPEST = {id = 114923, name = "Nether Tempest", icon = 135734, category = "talent"},
                SUPERNOVA = {id = 157980, name = "Supernova", icon = 437124, category = "talent"},
                
                -- Defensive/utility abilities
                ICE_BLOCK = {id = 45438, name = "Ice Block", icon = 135841, category = "defensive"},
                PRISMATIC_BARRIER = {id = 235450, name = "Prismatic Barrier", icon = 135739, category = "defensive"},
                BLINK = {id = 1953, name = "Blink", icon = 135736, category = "utility"},
                SLOW = {id = 31589, name = "Slow", icon = 136091, category = "utility"},
                
                -- Important buffs and procs to track
                CLEARCASTING = {id = 263725, name = "Clearcasting", icon = 136170, category = "buff"},
                ARCANE_POWER_BUFF = {id = 12042, name = "Arcane Power", icon = 136048, category = "buff"},
                TOUCH_OF_THE_MAGI_DEBUFF = {id = 210824, name = "Touch of the Magi", icon = 135734, category = "debuff"},
                RULE_OF_THREES_BUFF = {id = 264774, name = "Rule of Threes", icon = 2584580, category = "buff"}
            },
            
            resources = {
                primary = RESOURCE.MANA,
                secondary = "ARCANE_CHARGES"
            },
            
            priorities = {
                [SITUATION.SINGLE_TARGET] = {
                    -- Burn phase
                    {spell = "TOUCH_OF_THE_MAGI", condition = "IsUsable() and IsBurstPhase()"},
                    {spell = "ARCANE_POWER", condition = "IsUsable() and not HasBuff() and IsBurstPhase()"},
                    {spell = "PRESENCE_OF_MIND", condition = "IsUsable() and HasBuff(ARCANE_POWER_BUFF)"},
                    
                    -- Proc usage
                    {spell = "ARCANE_MISSILES", condition = "HasBuff(CLEARCASTING) and GetArcaneCharges() >= 3"},
                    
                    -- Build/spend cycle
                    {spell = "ARCANE_BLAST", condition = "HasBuff(RULE_OF_THREES_BUFF)"},
                    {spell = "ARCANE_BARRAGE", condition = "GetArcaneCharges() == 4 and GetManaPercent() < 40 and not HasBuff(ARCANE_POWER_BUFF)"},
                    {spell = "ARCANE_BLAST", condition = "GetManaPercent() > 15 or HasBuff(ARCANE_POWER_BUFF)"},
                    {spell = "ARCANE_BARRAGE", condition = "true"} -- Fallback when low on mana
                },
                
                [SITUATION.AOE] = {
                    -- Cooldowns
                    {spell = "TOUCH_OF_THE_MAGI", condition = "IsUsable()"},
                    {spell = "ARCANE_POWER", condition = "IsUsable() and not HasBuff()"},
                    
                    -- AoE abilities
                    {spell = "SUPERNOVA", condition = "IsUsable()"},
                    {spell = "NETHER_TEMPEST", condition = "not TargetHasDebuff() and GetArcaneCharges() >= 3"},
                    {spell = "ARCANE_EXPLOSION", condition = "TargetCount() >= 3"},
                    {spell = "ARCANE_BARRAGE", condition = "GetArcaneCharges() >= 3 and TargetCount() >= 3"},
                    {spell = "ARCANE_MISSILES", condition = "HasBuff(CLEARCASTING)"},
                    {spell = "ARCANE_EXPLOSION", condition = "true"}
                },
                
                [SITUATION.MOVEMENT] = {
                    {spell = "ARCANE_BARRAGE", condition = "GetArcaneCharges() > 0"},
                    {spell = "ARCANE_MISSILES", condition = "HasBuff(CLEARCASTING)"}
                }
            },
            
            talent_builds = {
                ["Standard"] = {
                    talents = "123aaaa123aaaa12aaaa",
                    description = "Standard Arcane Mage build focused on mana management and burst windows",
                    priority_modifications = {
                        -- Any modifications to the standard priority for this build
                    }
                },
                ["AoE Focus"] = {
                    talents = "123aaaa321aaa13aaa",
                    description = "AoE-focused build with Resonance and Arcane Echo",
                    priority_modifications = {
                        increase = {"ARCANE_EXPLOSION", "NETHER_TEMPEST"},
                        decrease = {"ARCANE_MISSILES"}
                    }
                }
            },
            
            special_mechanics = {
                burn_conserve = {
                    description = "Arcane alternates between Burn (high damage, high mana usage) and Conserve (lower damage, mana recovery) phases",
                    implementation = "Track mana levels and cooldown availability to determine current phase"
                },
                touch_of_the_magi = {
                    description = "Touch of the Magi stores damage and releases it after expiration",
                    implementation = "Track Touch of the Magi debuff on target and ensure maximum damage during its duration"
                }
            }
        }
    },
    
    -- WARRIOR
    [CLASS.WARRIOR] = {
        -- ARMS
        [SPEC.ARMS] = {
            spells = {
                -- Core rotational abilities
                MORTAL_STRIKE = {id = 12294, name = "Mortal Strike", icon = 132355, category = "core"},
                SLAM = {id = 1464, name = "Slam", icon = 132340, category = "filler"},
                EXECUTE = {id = 163201, name = "Execute", icon = 135358, category = "execute"},
                OVERPOWER = {id = 7384, name = "Overpower", icon = 132223, category = "core"},
                WHIRLWIND = {id = 1680, name = "Whirlwind", icon = 132369, category = "aoe"},
                CLEAVE = {id = 845, name = "Cleave", icon = 132338, category = "aoe"},
                COLOSSUS_SMASH = {id = 167105, name = "Colossus Smash", icon = 464973, category = "cooldown"},
                WARBREAKER = {id = 262161, name = "Warbreaker", icon = 2065642, category = "cooldown"},
                BLADESTORM = {id = 227847, name = "Bladestorm", icon = 236303, category = "cooldown"},
                AVATAR = {id = 107574, name = "Avatar", icon = 613534, category = "cooldown"},
                SKULLSPLITTER = {id = 260643, name = "Skullsplitter", icon = 2065634, category = "talent"},
                
                -- Defensive/utility abilities
                DIE_BY_THE_SWORD = {id = 118038, name = "Die by the Sword", icon = 132336, category = "defensive"},
                DEFENSIVE_STANCE = {id = 197690, name = "Defensive Stance", icon = 132341, category = "defensive"},
                RALLYING_CRY = {id = 97462, name = "Rallying Cry", icon = 132351, category = "raid_cooldown"},
                VICTORIOUS_RUSH = {id = 34428, name = "Victory Rush", icon = 132342, category = "heal"},
                
                -- Important buffs and debuffs to track
                SUDDEN_DEATH = {id = 29725, name = "Sudden Death", icon = 132346, category = "buff"},
                DEEP_WOUNDS = {id = 262115, name = "Deep Wounds", icon = 132090, category = "debuff"},
                COLOSSUS_SMASH_DEBUFF = {id = 208086, name = "Colossus Smash", icon = 464973, category = "debuff"},
                OVERPOWER_BUFF = {id = 7384, name = "Overpower", icon = 132223, category = "buff"}
            },
            
            resources = {
                primary = RESOURCE.RAGE
            },
            
            priorities = {
                [SITUATION.SINGLE_TARGET] = {
                    -- Maintain debuffs/buffs
                    {spell = "COLOSSUS_SMASH", condition = "IsUsable() and not TargetHasDebuff(COLOSSUS_SMASH_DEBUFF)"},
                    {spell = "WARBREAKER", condition = "IsUsable() and not TargetHasDebuff(COLOSSUS_SMASH_DEBUFF)"},
                    
                    -- Cooldowns
                    {spell = "AVATAR", condition = "IsUsable() and not HasBuff() and IsBurstPhase()"},
                    {spell = "BLADESTORM", condition = "IsUsable() and TargetHasDebuff(COLOSSUS_SMASH_DEBUFF)"},
                    
                    -- Core rotation
                    {spell = "EXECUTE", condition = "IsUsable() or HasBuff(SUDDEN_DEATH)"},
                    {spell = "MORTAL_STRIKE", condition = "IsUsable()"},
                    {spell = "OVERPOWER", condition = "IsUsable()"},
                    {spell = "SKULLSPLITTER", condition = "IsUsable() and GetRage() < 60"},
                    {spell = "SLAM", condition = "GetRage() >= 20"},
                    {spell = "OVERPOWER", condition = "IsUsable()"} -- Filler if available again
                },
                
                [SITUATION.AOE] = {
                    -- Cooldowns and major abilities
                    {spell = "WARBREAKER", condition = "IsUsable()"},
                    {spell = "COLOSSUS_SMASH", condition = "IsUsable() and not TargetHasDebuff(COLOSSUS_SMASH_DEBUFF)"},
                    {spell = "BLADESTORM", condition = "IsUsable() and TargetCount() >= 3"},
                    {spell = "AVATAR", condition = "IsUsable() and not HasBuff() and TargetCount() >= 3"},
                    
                    -- AoE abilities
                    {spell = "CLEAVE", condition = "IsUsable() and TargetCount() >= 2"},
                    {spell = "WHIRLWIND", condition = "TargetCount() >= 2"},
                    
                    -- Single-target priorities for cleave
                    {spell = "EXECUTE", condition = "IsUsable() or HasBuff(SUDDEN_DEATH)"},
                    {spell = "MORTAL_STRIKE", condition = "IsUsable()"},
                    {spell = "OVERPOWER", condition = "IsUsable()"},
                    {spell = "WHIRLWIND", condition = "true"} -- Filler
                },
                
                [SITUATION.EXECUTE] = {
                    -- Maintain debuffs/buffs
                    {spell = "COLOSSUS_SMASH", condition = "IsUsable() and not TargetHasDebuff(COLOSSUS_SMASH_DEBUFF)"},
                    {spell = "WARBREAKER", condition = "IsUsable() and not TargetHasDebuff(COLOSSUS_SMASH_DEBUFF)"},
                    
                    -- Cooldowns
                    {spell = "AVATAR", condition = "IsUsable() and not HasBuff()"},
                    
                    -- Execute phase rotation
                    {spell = "EXECUTE", condition = "IsUsable() and GetRage() >= 40"},
                    {spell = "MORTAL_STRIKE", condition = "IsUsable() and not TargetHasDebuff(DEEP_WOUNDS)"},
                    {spell = "SKULLSPLITTER", condition = "IsUsable() and GetRage() < 60"},
                    {spell = "OVERPOWER", condition = "IsUsable()"},
                    {spell = "EXECUTE", condition = "IsUsable()"} -- Filler at lower rage
                }
            },
            
            talent_builds = {
                ["Standard"] = {
                    talents = "123aaaa123aaaa12aaaa",
                    description = "Standard Arms Warrior build focused on Mortal Strike and Execute",
                    priority_modifications = {
                        -- Any modifications to the standard priority for this build
                    }
                },
                ["Cleave"] = {
                    talents = "123aaaa321aaa13aaa",
                    description = "AoE-focused build with improved cleave and Bladestorm damage",
                    priority_modifications = {
                        increase = {"CLEAVE", "BLADESTORM", "WHIRLWIND"},
                        decrease = {"SLAM"}
                    }
                }
            },
            
            special_mechanics = {
                execute_phase = {
                    description = "Below 20% target health, Execute becomes available and the rotation changes significantly",
                    implementation = "Track target health and switch to execute-specific priority list when below 20%"
                },
                colossus_smash_window = {
                    description = "Colossus Smash creates a vulnerability debuff that increases damage to the target",
                    implementation = "Track Colossus Smash debuff on target and prioritize high-damage abilities while active"
                }
            }
        },
        
        -- Additional Warrior specs would be defined here
        [SPEC.FURY] = {
            -- Similar structure for Fury spec
        },
        [SPEC.PROTECTION_WARRIOR] = {
            -- Similar structure for Protection spec
        }
    },
    
    -- PALADIN
    [CLASS.PALADIN] = {
        -- RETRIBUTION
        [SPEC.RETRIBUTION] = {
            spells = {
                -- Core rotational abilities
                CRUSADER_STRIKE = {id = 35395, name = "Crusader Strike", icon = 135891, category = "generator"},
                BLADE_OF_JUSTICE = {id = 184575, name = "Blade of Justice", icon = 1360757, category = "generator"},
                JUDGMENT = {id = 20271, name = "Judgment", icon = 135959, category = "generator"},
                TEMPLARS_VERDICT = {id = 85256, name = "Templar's Verdict", icon = 461860, category = "spender"},
                DIVINE_STORM = {id = 53385, name = "Divine Storm", icon = 236250, category = "aoe"},
                WAKE_OF_ASHES = {id = 255937, name = "Wake of Ashes", icon = 1112939, category = "cooldown"},
                CONSECRATION = {id = 26573, name = "Consecration", icon = 135926, category = "aoe"},
                AVENGING_WRATH = {id = 31884, name = "Avenging Wrath", icon = 135875, category = "cooldown"},
                HAMMER_OF_WRATH = {id = 24275, name = "Hammer of Wrath", icon = 613533, category = "execute"},
                
                -- Defensive/utility abilities
                DIVINE_SHIELD = {id = 642, name = "Divine Shield", icon = 135896, category = "defensive"},
                SHIELD_OF_VENGEANCE = {id = 184662, name = "Shield of Vengeance", icon = 236264, category = "defensive"},
                LAY_ON_HANDS = {id = 633, name = "Lay on Hands", icon = 135928, category = "defensive"},
                BLESSING_OF_PROTECTION = {id = 1022, name = "Blessing of Protection", icon = 135964, category = "utility"},
                BLESSING_OF_FREEDOM = {id = 1044, name = "Blessing of Freedom", icon = 135968, category = "utility"},
                WORD_OF_GLORY = {id = 85673, name = "Word of Glory", icon = 646264, category = "heal"},
                
                -- Important buffs and debuffs to track
                AVENGING_WRATH_BUFF = {id = 31884, name = "Avenging Wrath", icon = 135875, category = "buff"},
                DIVINE_PURPOSE = {id = 223819, name = "Divine Purpose", icon = 135897, category = "buff"},
                EMPYREAN_POWER = {id = 326733, name = "Empyrean Power", icon = 135987, category = "buff"},
                THE_FIRES_OF_JUSTICE = {id = 209785, name = "The Fires of Justice", icon = 458468, category = "buff"}
            },
            
            resources = {
                primary = RESOURCE.HOLY_POWER
            },
            
            priorities = {
                [SITUATION.SINGLE_TARGET] = {
                    -- Cooldowns
                    {spell = "AVENGING_WRATH", condition = "IsUsable() and not HasBuff() and IsBurstPhase()"},
                    
                    -- Holy Power spenders
                    {spell = "TEMPLARS_VERDICT", condition = "GetHolyPower() >= 5"},
                    {spell = "TEMPLARS_VERDICT", condition = "HasBuff(DIVINE_PURPOSE)"},
                    {spell = "TEMPLARS_VERDICT", condition = "HasBuff(EMPYREAN_POWER)"},
                    
                    -- Holy Power generators
                    {spell = "WAKE_OF_ASHES", condition = "IsUsable()"},
                    {spell = "HAMMER_OF_WRATH", condition = "IsUsable()"},
                    {spell = "BLADE_OF_JUSTICE", condition = "IsUsable()"},
                    {spell = "JUDGMENT", condition = "IsUsable()"},
                    {spell = "CRUSADER_STRIKE", condition = "SpellCharges() > 0"},
                    
                    -- Filler
                    {spell = "CONSECRATION", condition = "IsUsable()"},
                    
                    -- Dump Holy Power if not saving for anything specific
                    {spell = "TEMPLARS_VERDICT", condition = "GetHolyPower() >= 3"}
                },
                
                [SITUATION.AOE] = {
                    -- Cooldowns
                    {spell = "AVENGING_WRATH", condition = "IsUsable() and not HasBuff() and TargetCount() >= 3"},
                    
                    -- Holy Power spenders
                    {spell = "DIVINE_STORM", condition = "GetHolyPower() >= 5"},
                    {spell = "DIVINE_STORM", condition = "HasBuff(DIVINE_PURPOSE)"},
                    {spell = "DIVINE_STORM", condition = "HasBuff(EMPYREAN_POWER)"},
                    
                    -- Holy Power generators
                    {spell = "WAKE_OF_ASHES", condition = "IsUsable() and TargetCount() >= 2"},
                    {spell = "HAMMER_OF_WRATH", condition = "IsUsable()"},
                    {spell = "BLADE_OF_JUSTICE", condition = "IsUsable()"},
                    {spell = "JUDGMENT", condition = "IsUsable()"},
                    {spell = "CRUSADER_STRIKE", condition = "SpellCharges() > 0"},
                    
                    -- Filler
                    {spell = "CONSECRATION", condition = "IsUsable() and TargetCount() >= 3"},
                    
                    -- Dump Holy Power if not saving for anything specific
                    {spell = "DIVINE_STORM", condition = "GetHolyPower() >= 3 and TargetCount() >= 2"},
                    {spell = "TEMPLARS_VERDICT", condition = "GetHolyPower() >= 3"}
                },
                
                [SITUATION.EXECUTE] = {
                    -- Prioritize Hammer of Wrath
                    {spell = "HAMMER_OF_WRATH", condition = "IsUsable()"},
                    
                    -- Then follow normal priority
                    {spell = "AVENGING_WRATH", condition = "IsUsable() and not HasBuff()"},
                    {spell = "TEMPLARS_VERDICT", condition = "GetHolyPower() >= 5"},
                    {spell = "TEMPLARS_VERDICT", condition = "HasBuff(DIVINE_PURPOSE)"},
                    {spell = "WAKE_OF_ASHES", condition = "IsUsable()"},
                    {spell = "BLADE_OF_JUSTICE", condition = "IsUsable()"},
                    {spell = "JUDGMENT", condition = "IsUsable()"},
                    {spell = "CRUSADER_STRIKE", condition = "SpellCharges() > 0"},
                    {spell = "CONSECRATION", condition = "IsUsable()"},
                    {spell = "TEMPLARS_VERDICT", condition = "GetHolyPower() >= 3"}
                }
            },
            
            talent_builds = {
                ["Standard"] = {
                    talents = "123aaaa123aaaa12aaaa",
                    description = "Standard Retribution Paladin build focused on consistent damage",
                    priority_modifications = {
                        -- Any modifications to the standard priority for this build
                    }
                },
                ["Divine Purpose"] = {
                    talents = "123aaaa321aaa13aaa",
                    description = "Build focused on Divine Purpose procs for Holy Power efficiency",
                    priority_modifications = {
                        increase = {"TEMPLARS_VERDICT", "DIVINE_STORM"},
                        decrease = {}
                    }
                }
            },
            
            special_mechanics = {
                avenging_wrath_window = {
                    description = "Avenging Wrath increases damage and critical strike chance",
                    implementation = "Track Avenging Wrath buff and prioritize high-damage abilities while active"
                },
                judgment_window = {
                    description = "Some talents make Judgment increase the damage of Holy Power spenders",
                    implementation = "Track Judgment debuff on target and prioritize Holy Power spenders while active"
                }
            }
        },
        
        -- Additional Paladin specs would be defined here
        [SPEC.HOLY_PALADIN] = {
            -- Similar structure for Holy spec
        },
        [SPEC.PROTECTION_PALADIN] = {
            -- Similar structure for Protection spec
        }
    },
    
    -- Additional classes would follow the same pattern
    [CLASS.HUNTER] = {
        -- Hunter specs
    },
    [CLASS.ROGUE] = {
        -- Rogue specs
    },
    [CLASS.PRIEST] = {
        -- Priest specs
    },
    [CLASS.DEATHKNIGHT] = {
        -- Death Knight specs
    },
    [CLASS.SHAMAN] = {
        -- Shaman specs
    },
    [CLASS.WARLOCK] = {
        -- Warlock specs
    },
    [CLASS.MONK] = {
        -- Monk specs
    },
    [CLASS.DRUID] = {
        -- Druid specs
    },
    [CLASS.DEMONHUNTER] = {
        -- Demon Hunter specs
    },
    [CLASS.EVOKER] = {
        -- Evoker specs
    }
}

-- Legendary effects database
local legendaryEffects = {
    -- Mage Legendaries
    [208080] = { -- Temporal Warp
        class = CLASS.MAGE,
        spec = SPEC.ARCANE,
        effect = "Improves Time Warp/Bloodlust/Heroism effect on you and reduces Arcane Power cooldown",
        priority_modifications = {
            increase = {"ARCANE_POWER"}
        }
    },
    [209455] = { -- Cold Front
        class = CLASS.MAGE,
        spec = SPEC.FROST_MAGE,
        effect = "Brain Freeze now affects the next 2 Flurry casts",
        priority_modifications = {
            increase = {"FLURRY"}
        }
    },
    
    -- Warrior Legendaries
    [206333] = { -- Battlelord
        class = CLASS.WARRIOR,
        spec = SPEC.ARMS,
        effect = "Mortal Strike has a chance to reset Colossus Smash",
        priority_modifications = {
            increase = {"MORTAL_STRIKE"}
        }
    },
    
    -- Each class would have similar legendary entries
}

-- Tier set bonuses database
local tierSetBonuses = {
    -- Example tier set bonuses
    ["Mage T29"] = {
        [2] = {
            class = CLASS.MAGE,
            spec = SPEC.FROST_MAGE,
            effect = "Flurry has a 20% chance to grant Brain Freeze",
            priority_modifications = {
                increase = {"FLURRY"}
            }
        },
        [4] = {
            class = CLASS.MAGE,
            spec = SPEC.FROST_MAGE,
            effect = "Ice Lance damage increased by 30%",
            priority_modifications = {
                increase = {"ICE_LANCE"}
            }
        }
    },
    
    ["Warrior T29"] = {
        [2] = {
            class = CLASS.WARRIOR,
            spec = SPEC.ARMS,
            effect = "Execute damage increased by 20%",
            priority_modifications = {
                increase = {"EXECUTE"}
            }
        },
        [4] = {
            class = CLASS.WARRIOR,
            spec = SPEC.ARMS,
            effect = "Mortal Strike has a 15% chance to trigger a free Overpower",
            priority_modifications = {
                increase = {"MORTAL_STRIKE", "OVERPOWER"}
            }
        }
    },
    
    -- Each class would have similar tier set entries
}

-- Encounter-specific adjustments
local encounterAdjustments = {
    -- Example raids
    ["Amirdrassil"] = {
        -- Bosses
        [2564] = { -- Gnarlroot
            phases = {
                [1] = {
                    mechanics = {
                        ["Controlled Burn"] = {
                            description = "Players need to spread out",
                            recommendations = {
                                movement = true,
                                defensive = false
                            }
                        }
                    }
                },
                [2] = {
                    mechanics = {
                        ["Smoldering Backdraft"] = {
                            description = "Heavy AoE damage phase",
                            recommendations = {
                                cooldown_hold = false,
                                defensive = true,
                                burst = true
                            }
                        }
                    }
                }
            }
        },
        
        -- Additional bosses would be defined here
    },
    
    -- Example dungeons 
    ["Dawn of the Infinite"] = {
        -- Bosses
        [198997] = { -- Chronikar
            phases = {
                [1] = {
                    mechanics = {
                        ["Temporal Breath"] = {
                            description = "Frontal cone attack that slows",
                            recommendations = {
                                movement = true
                            }
                        }
                    }
                }
            }
        },
        
        -- Additional bosses would be defined here
    }
}

-- Initialize the module
function ClassKnowledge:Initialize()
    -- Store the knowledge database
    self.knowledgeDB = knowledgeDB
    self.legendaryEffects = legendaryEffects
    self.tierSetBonuses = tierSetBonuses
    self.encounterAdjustments = encounterAdjustments
    
    -- Expose constants
    self.CLASS = CLASS
    self.SPEC = SPEC
    self.SITUATION = SITUATION
    self.RESOURCE = RESOURCE
    
    WR:Debug("ClassKnowledge module initialized")
    
    -- Initialize build detection
    self:InitializeBuildDetection()
    
    -- Initialize encounter detection
    self:InitializeEncounterDetection()
    
    -- Initialize gear scanning
    self:InitializeGearScanning()
end

-- Get class knowledge for the current player
function ClassKnowledge:GetPlayerClassKnowledge()
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    if not playerClass or not playerSpec then
        return nil
    end
    
    if not self.knowledgeDB[playerClass] or not self.knowledgeDB[playerClass][playerSpec] then
        return nil
    end
    
    return self.knowledgeDB[playerClass][playerSpec]
end

-- Get a spell by name for the current player
function ClassKnowledge:GetSpellByName(spellName)
    local playerClassKnowledge = self:GetPlayerClassKnowledge()
    if not playerClassKnowledge or not playerClassKnowledge.spells then
        return nil
    end
    
    for _, spell in pairs(playerClassKnowledge.spells) do
        if spell.name == spellName then
            return spell
        end
    end
    
    return nil
end

-- Get a spell by ID for the current player
function ClassKnowledge:GetSpellById(spellId)
    local playerClassKnowledge = self:GetPlayerClassKnowledge()
    if not playerClassKnowledge or not playerClassKnowledge.spells then
        return nil
    end
    
    for _, spell in pairs(playerClassKnowledge.spells) do
        if spell.id == spellId then
            return spell
        end
    end
    
    return nil
end

-- Get priority list for the current situation
function ClassKnowledge:GetCurrentPriorityList()
    local playerClassKnowledge = self:GetPlayerClassKnowledge()
    if not playerClassKnowledge or not playerClassKnowledge.priorities then
        return nil
    end
    
    local situation = self:DetermineSituation()
    if not playerClassKnowledge.priorities[situation] then
        situation = SITUATION.SINGLE_TARGET -- Default to single target
    end
    
    return playerClassKnowledge.priorities[situation]
end

-- Determine the current combat situation
function ClassKnowledge:DetermineSituation()
    -- Get target count
    local targetCount = 1
    
    -- Try to get target count from Combat module if available
    if WR.Combat and WR.Combat.GetTargetCount then
        targetCount = WR.Combat:GetTargetCount()
    else
        -- Basic implementation if Combat module not available
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
                targetCount = targetCount + 1
            end
        end
    end
    
    -- Check if target is in execute range
    local targetHealthPercent = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 100
    
    -- Check if player is moving
    local isMoving = GetUnitSpeed("player") > 0
    
    -- Determine situation based on conditions
    if targetCount >= 3 then
        return SITUATION.AOE
    elseif targetHealthPercent <= 20 then
        return SITUATION.EXECUTE
    elseif isMoving then
        return SITUATION.MOVEMENT
    else
        return SITUATION.SINGLE_TARGET
    end
end

-- Initialize build detection
function ClassKnowledge:InitializeBuildDetection()
    -- Set up event handler for talent changes
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        ClassKnowledge:ScanPlayerBuild()
    end)
    
    -- Initial scan
    self:ScanPlayerBuild()
    
    WR:Debug("Build detection initialized")
end

-- Scan player build (talents, etc.)
function ClassKnowledge:ScanPlayerBuild()
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    if not playerClass or not playerSpec then
        return
    end
    
    -- Scan talents
    local talentString = self:GetTalentString()
    
    -- Store current build
    self.currentBuild = {
        class = playerClass,
        spec = playerSpec,
        talents = talentString
    }
    
    -- Find matching talent build
    local playerClassKnowledge = self:GetPlayerClassKnowledge()
    if playerClassKnowledge and playerClassKnowledge.talent_builds then
        self.matchedBuild = self:FindMatchingBuild(playerClassKnowledge.talent_builds, talentString)
    end
    
    WR:Debug("Player build scanned: " .. playerClass .. " " .. playerSpec .. " with talents " .. talentString)
}

-- Get a string representation of the player's talents
function ClassKnowledge:GetTalentString()
    local talentString = ""
    
    -- This is a simplified version - in a real implementation, this would
    -- actually scan the talent tree and create a string representation
    
    -- For demonstration purposes, we'll return a placeholder
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    return "123aaaa123aaaa12aaaa" -- Placeholder
end

-- Find matching build in talent_builds
function ClassKnowledge:FindMatchingBuild(talent_builds, talentString)
    -- Look for exact match
    for buildName, buildData in pairs(talent_builds) do
        if buildData.talents == talentString then
            WR:Debug("Found exact talent build match: " .. buildName)
            return buildData
        end
    end
    
    -- If no exact match, find closest match
    local bestMatch = nil
    local bestMatchScore = 0
    
    for buildName, buildData in pairs(talent_builds) do
        local score = self:CalculateTalentSimilarity(buildData.talents, talentString)
        if score > bestMatchScore then
            bestMatchScore = score
            bestMatch = buildData
        end
    end
    
    if bestMatch then
        WR:Debug("Found approximate talent build match with score: " .. bestMatchScore)
        return bestMatch
    end
    
    return nil
end

-- Calculate similarity between two talent strings
function ClassKnowledge:CalculateTalentSimilarity(talents1, talents2)
    local score = 0
    local maxScore = math.min(#talents1, #talents2)
    
    for i = 1, maxScore do
        if talents1:sub(i,i) == talents2:sub(i,i) then
            score = score + 1
        end
    end
    
    return score / maxScore
end

-- Initialize encounter detection
function ClassKnowledge:InitializeEncounterDetection()
    -- Set up event handlers for encounter detection
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ENCOUNTER_START" then
            local encounterId, encounterName, difficultyId, raidSize = ...
            ClassKnowledge:OnEncounterStart(encounterId, encounterName, difficultyId, raidSize)
        elseif event == "ENCOUNTER_END" then
            local encounterId, encounterName, difficultyId, raidSize, success = ...
            ClassKnowledge:OnEncounterEnd(encounterId, encounterName, difficultyId, raidSize, success)
        elseif event == "PLAYER_ENTERING_WORLD" then
            ClassKnowledge:ScanCurrentZone()
        end
    end)
    
    -- Initial zone scan
    self:ScanCurrentZone()
    
    WR:Debug("Encounter detection initialized")
}

-- Scan current zone for dungeon/raid detection
function ClassKnowledge:ScanCurrentZone()
    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
    
    self.currentZone = {
        name = name,
        instanceType = instanceType,
        instanceID = instanceID,
        difficultyID = difficultyID
    }
    
    WR:Debug("Current zone detected: " .. name .. " (" .. instanceType .. ")")
}

-- Handle encounter start
function ClassKnowledge:OnEncounterStart(encounterId, encounterName, difficultyId, raidSize)
    self.currentEncounter = {
        id = encounterId,
        name = encounterName,
        difficultyId = difficultyId,
        raidSize = raidSize,
        phase = 1 -- Assume starting in phase 1
    }
    
    -- Look for encounter-specific adjustments
    self:LoadEncounterAdjustments()
    
    WR:Debug("Encounter started: " .. encounterName .. " (ID: " .. encounterId .. ")")
}

-- Handle encounter end
function ClassKnowledge:OnEncounterEnd(encounterId, encounterName, difficultyId, raidSize, success)
    self.currentEncounter = nil
    
    WR:Debug("Encounter ended: " .. encounterName .. " (Success: " .. tostring(success) .. ")")
}

-- Load encounter adjustments
function ClassKnowledge:LoadEncounterAdjustments()
    if not self.currentEncounter or not self.currentZone then
        return
    end
    
    local adjustments = nil
    
    -- Look for adjustments for this encounter
    for zoneName, zoneData in pairs(self.encounterAdjustments) do
        if zoneName == self.currentZone.name then
            adjustments = zoneData[self.currentEncounter.id]
            break
        end
    end
    
    if adjustments then
        WR:Debug("Loaded encounter adjustments for " .. self.currentEncounter.name)
    else
        WR:Debug("No encounter adjustments found for " .. self.currentEncounter.name)
    end
    
    self.currentEncounterAdjustments = adjustments
}

-- Initialize gear scanning
function ClassKnowledge:InitializeGearScanning()
    -- Set up event handler for gear changes
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        ClassKnowledge:ScanPlayerGear()
    end)
    
    -- Initial scan
    self:ScanPlayerGear()
    
    WR:Debug("Gear scanning initialized")
end

-- Scan player gear for legendaries and tier sets
function ClassKnowledge:ScanPlayerGear()
    local equippedLegendaries = {}
    local tierSetPieces = {}
    
    -- Scan each equipment slot
    for i = 1, 19 do -- 19 equipment slots
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            -- Check if legendary
            local isLegendary, legendaryID = self:IsLegendaryItem(itemLink)
            if isLegendary then
                table.insert(equippedLegendaries, {
                    slot = i,
                    link = itemLink,
                    id = legendaryID
                })
            end
            
            -- Check if tier set piece
            local isTier, setName = self:IsTierSetItem(itemLink)
            if isTier then
                tierSetPieces[setName] = (tierSetPieces[setName] or 0) + 1
            end
        end
    end
    
    -- Store results
    self.equippedLegendaries = equippedLegendaries
    self.tierSetPieces = tierSetPieces
    
    -- Apply legendary effects
    self:ApplyLegendaryEffects()
    
    -- Apply tier set bonuses
    self:ApplyTierSetBonuses()
    
    WR:Debug("Player gear scanned: " .. #equippedLegendaries .. " legendaries, " .. 
             self:TableSize(tierSetPieces) .. " tier sets")
}

-- Check if an item is legendary
function ClassKnowledge:IsLegendaryItem(itemLink)
    if not itemLink then
        return false, nil
    end
    
    -- In a real implementation, this would actually check the item quality and bonusIDs
    -- For demonstration purposes, we'll return a placeholder
    local itemName = GetItemInfo(itemLink)
    
    -- This is just a placeholder logic - real implementation would use GetItemStats
    if itemName and itemName:match("Legendary") then
        return true, 208080 -- Placeholder legendary ID
    end
    
    return false, nil
}

-- Check if an item is part of a tier set
function ClassKnowledge:IsTierSetItem(itemLink)
    if not itemLink then
        return false, nil
    end
    
    -- In a real implementation, this would check set bonus information
    -- For demonstration purposes, we'll return a placeholder
    local itemName = GetItemInfo(itemLink)
    
    -- This is just a placeholder logic
    if itemName and itemName:match("Mythic") then 
        return true, "Mage T29" -- Placeholder tier set name
    end
    
    return false, nil
}

-- Apply legendary effects to rotation
function ClassKnowledge:ApplyLegendaryEffects()
    if not self.equippedLegendaries then
        return
    end
    
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    for _, legendary in ipairs(self.equippedLegendaries) do
        local effect = self.legendaryEffects[legendary.id]
        
        if effect and effect.class == playerClass and effect.spec == playerSpec then
            -- Store this effect to modify rotation priorities
            WR:Debug("Applied legendary effect: " .. effect.effect)
        end
    end
}

-- Apply tier set bonuses to rotation
function ClassKnowledge:ApplyTierSetBonuses()
    if not self.tierSetPieces then
        return
    end
    
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    for setName, pieceCount in pairs(self.tierSetPieces) do
        -- Check for 2-piece bonus
        if pieceCount >= 2 and self.tierSetBonuses[setName] and self.tierSetBonuses[setName][2] then
            local bonus = self.tierSetBonuses[setName][2]
            
            if bonus.class == playerClass and bonus.spec == playerSpec then
                -- Store this bonus to modify rotation priorities
                WR:Debug("Applied 2-piece bonus: " .. bonus.effect)
            end
        end
        
        -- Check for 4-piece bonus
        if pieceCount >= 4 and self.tierSetBonuses[setName] and self.tierSetBonuses[setName][4] then
            local bonus = self.tierSetBonuses[setName][4]
            
            if bonus.class == playerClass and bonus.spec == playerSpec then
                -- Store this bonus to modify rotation priorities
                WR:Debug("Applied 4-piece bonus: " .. bonus.effect)
            end
        end
    end
}

-- Get table size
function ClassKnowledge:TableSize(tbl)
    local count = 0
    if tbl then
        for _ in pairs(tbl) do
            count = count + 1
        end
    end
    return count
end

-- Initialize the module
ClassKnowledge:Initialize()

return ClassKnowledge