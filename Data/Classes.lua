local addonName, WR = ...

-- Classes data module - stores class and specialization data
WR.Data.Classes = {}

-- Lookup tables for class information
local CLASS_INFO = {
    MAGE = {
        id = 8,
        name = "Mage",
        color = "69CCF0",
        specs = {
            [62] = { id = 62, name = "Arcane", role = "DPS", icon = 135932 },
            [63] = { id = 63, name = "Fire", role = "DPS", icon = 135810 },
            [64] = { id = 64, name = "Frost", role = "DPS", icon = 135846 },
        },
        baseSpells = {
            -- Universal Mage abilities
            ARCANE_INTELLECT = 1459,
            BLINK = 1953,
            COUNTERSPELL = 2139,
            FROST_NOVA = 122,
            ICE_BLOCK = 45438,
            POLYMORPH = 118,
            SLOW_FALL = 130,
            CONJURE_REFRESHMENT = 42955,
            SPELLSTEAL = 30449,
            TIME_WARP = 80353,
        },
    },
    HUNTER = {
        id = 3,
        name = "Hunter",
        color = "ABD473",
        specs = {
            [253] = { id = 253, name = "Beast Mastery", role = "DPS", icon = 461112 },
            [254] = { id = 254, name = "Marksmanship", role = "DPS", icon = 236179 },
            [255] = { id = 255, name = "Survival", role = "DPS", icon = 461113 },
        },
        baseSpells = {
            -- Universal Hunter abilities
            ASPECT_OF_THE_CHEETAH = 186257,
            ASPECT_OF_THE_TURTLE = 186265,
            DISENGAGE = 781,
            FEIGN_DEATH = 5384,
            FLARE = 1543,
            HUNTERS_MARK = 257284,
            MEND_PET = 136,
            MISDIRECTION = 34477,
            REVIVE_PET = 982,
            TRANQUILIZING_SHOT = 19801,
            FREEZING_TRAP = 187650,
            TAR_TRAP = 187698,
            WING_CLIP = 195645,
            COUNTER_SHOT = 147362,
        },
    },
    WARRIOR = {
        id = 1,
        name = "Warrior",
        color = "C79C6E",
        specs = {
            [71] = { id = 71, name = "Arms", role = "DPS", icon = 132355 },
            [72] = { id = 72, name = "Fury", role = "DPS", icon = 132347 },
            [73] = { id = 73, name = "Protection", role = "TANK", icon = 132341 },
        },
        baseSpells = {
            -- Universal Warrior abilities
            BATTLE_SHOUT = 6673,
            BERSERKER_RAGE = 18499,
            CHARGE = 100,
            HEROIC_THROW = 57755,
            INTERVENE = 3411,
            INTIMIDATING_SHOUT = 5246,
            PUMMEL = 6552,
            RALLYING_CRY = 97462,
            TAUNT = 355,
            VICTORY_RUSH = 34428,
            WHIRLWIND = 190411,
            DEFENSIVE_STANCE = 386164,
            HAMSTRING = 1715,
        },
    },
    DEMONHUNTER = {
        id = 12,
        name = "Demon Hunter",
        color = "A330C9",
        specs = {
            [577] = { id = 577, name = "Havoc", role = "DPS", icon = 1247266 },
            [581] = { id = 581, name = "Vengeance", role = "TANK", icon = 1247265 },
        },
        baseSpells = {
            -- Universal Demon Hunter abilities
            CONSUME_MAGIC = 278326,
            CHAOS_NOVA = 179057,
            DISRUPT = 183752,
            DEMONIC_SIGHT = 188501,
            FEL_RUSH = 195072,
            GLIDE = 131347,
            IMMOLATION_AURA = 258920,
            IMPRISON = 217832,
            METAMORPHOSIS_HAVOC = 191427,
            METAMORPHOSIS_VENGEANCE = 187827,
            THROW_GLAIVE = 185123,
            SPECTRAL_SIGHT = 188501,
            TORMENT = 185245,
        },
    },
}

-- Spec details - rotational priorities, spells, etc.
local SPEC_DETAILS = {
    -- Mage Specs
    [62] = { -- Arcane Mage
        name = "Arcane",
        role = "DPS",
        primaryResource = "Mana",
        secondaryResource = "Arcane Charges",
        strengths = {"Single Target Burst", "Mobility", "Utility"},
        weaknesses = {"Sustained AOE", "Mana Management", "Ramp-up Time"},
        spells = {
            -- Core rotational spells
            ARCANE_BLAST = 30451,
            ARCANE_BARRAGE = 44425,
            ARCANE_MISSILES = 5143,
            ARCANE_EXPLOSION = 1449,
            -- Cooldowns
            ARCANE_POWER = 12042,
            PRESENCE_OF_MIND = 205025,
            EVOCATION = 12051,
            -- Talents
            TOUCH_OF_THE_MAGI = 321507,
            RADIANT_SPARK = 376103,
            ARCANE_HARMONY = 384452,
            ARCANE_FAMILIAR = 205022,
            -- Defensive
            PRISMATIC_BARRIER = 235450,
            -- Utility
            GREATER_INVISIBILITY = 110959,
            ALTER_TIME = 342245,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "ARCANE_POWER",
                "TOUCH_OF_THE_MAGI", 
                "RADIANT_SPARK"
            },
            single_target = {
                "TOUCH_OF_THE_MAGI",
                "RADIANT_SPARK",
                "ARCANE_BLAST", -- Building charges
                "ARCANE_BLAST",
                "ARCANE_BLAST",
                "ARCANE_BLAST",
                "ARCANE_POWER",
                "ARCANE_BLAST",
                "ARCANE_BLAST",
                "ARCANE_BLAST",
                "ARCANE_MISSILES", -- Dump procs
                "ARCANE_BARRAGE" -- Dump charges
            },
            aoe = {
                "TOUCH_OF_THE_MAGI",
                "ARCANE_POWER",
                "ARCANE_EXPLOSION",
                "ARCANE_BARRAGE"
            },
            defensive = {
                "PRISMATIC_BARRIER",
                "GREATER_INVISIBILITY",
                "ICE_BLOCK"
            }
        }
    },
    [63] = { -- Fire Mage
        name = "Fire",
        role = "DPS",
        primaryResource = "Mana",
        secondaryResource = "None",
        strengths = {"Cleave", "Burst AOE", "Procs"},
        weaknesses = {"RNG Dependent", "Cooldown Reliant"},
        spells = {
            -- Core rotational spells
            FIREBALL = 133,
            FIRE_BLAST = 108853,
            PYROBLAST = 11366,
            FLAMESTRIKE = 2120,
            PHOENIX_FLAMES = 257541,
            SCORCH = 2948,
            -- Cooldowns
            COMBUSTION = 190319,
            -- Talents
            LIVING_BOMB = 44457,
            METEOR = 153561,
            SUN_KINGS_BLESSING = 383886,
            -- Defensive
            BLAZING_BARRIER = 235313,
            -- Utility
            DRAGONS_BREATH = 31661,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "COMBUSTION",
                "METEOR"
            },
            single_target = {
                "PYROBLAST", -- Hot Streak proc
                "FIRE_BLAST", -- To generate Hot Streak during Combustion
                "PHOENIX_FLAMES", -- To generate Heating Up
                "FIREBALL",
                "SCORCH" -- When moving
            },
            aoe = {
                "FLAMESTRIKE", -- Hot Streak proc with 3+ targets
                "PHOENIX_FLAMES",
                "FIRE_BLAST", -- To generate Hot Streak
                "FLAMESTRIKE", -- Hard cast with 5+ targets
                "LIVING_BOMB", 
                "DRAGON'S_BREATH"
            },
            defensive = {
                "BLAZING_BARRIER",
                "ICE_BLOCK",
                "ALTER_TIME"
            }
        }
    },
    [64] = { -- Frost Mage
        name = "Frost",
        role = "DPS",
        primaryResource = "Mana",
        secondaryResource = "None",
        strengths = {"Control", "Sustained Cleave", "Slows"},
        weaknesses = {"Single Target Burst", "Movement Phases"},
        spells = {
            -- Core rotational spells
            FROSTBOLT = 116,
            ICE_LANCE = 30455,
            FLURRY = 44614,
            FROZEN_ORB = 84714,
            BLIZZARD = 190356,
            -- Cooldowns
            ICY_VEINS = 12472,
            -- Talents
            COMET_STORM = 153595,
            GLACIAL_SPIKE = 199786,
            COLD_SNAP = 235219,
            EBONBOLT = 257537,
            RAY_OF_FROST = 205021,
            -- Defensive
            ICE_BARRIER = 11426,
            -- Utility
            CONE_OF_COLD = 120,
            SUMMON_WATER_ELEMENTAL = 31687,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "ICY_VEINS",
                "FROZEN_ORB",
                "COMET_STORM"
            },
            single_target = {
                "GLACIAL_SPIKE", -- If talented and Brain Freeze proc
                "FLURRY", -- With Brain Freeze proc
                "ICE_LANCE", -- When target is frozen
                "EBONBOLT", -- If talented
                "RAY_OF_FROST", -- If talented
                "GLACIAL_SPIKE", -- If talented (no Brain Freeze)
                "FROSTBOLT"
            },
            aoe = {
                "FROZEN_ORB",
                "BLIZZARD",
                "COMET_STORM",
                "ICE_LANCE", -- When target is frozen
                "FLURRY", -- With Brain Freeze proc
                "FROSTBOLT"
            },
            defensive = {
                "ICE_BARRIER",
                "ICE_BLOCK",
                "COLD_SNAP"
            }
        }
    },
    
    -- Hunter Specs
    [253] = { -- Beast Mastery Hunter
        name = "Beast Mastery",
        role = "DPS",
        primaryResource = "Focus",
        secondaryResource = "None",
        strengths = {"Mobile DPS", "Pet Management", "Sustained Cleave"},
        weaknesses = {"Cooldown Dependent", "Pet AI Limitations"},
        spells = {
            -- Core rotational spells
            KILL_COMMAND = 34026,
            COBRA_SHOT = 193455,
            BARBED_SHOT = 217200,
            MULTI_SHOT = 2643,
            -- Cooldowns
            BESTIAL_WRATH = 19574,
            ASPECT_OF_THE_WILD = 193530,
            -- Talents
            DIRE_BEAST = 120679,
            STAMPEDE = 201430,
            CALL_OF_THE_WILD = 359844,
            -- Defensive
            EXHILARATION = 109304,
            -- Utility
            BINDING_SHOT = 109248,
            CAMOUFLAGE = 199483,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "BESTIAL_WRATH",
                "ASPECT_OF_THE_WILD",
                "STAMPEDE"
            },
            single_target = {
                "BARBED_SHOT", -- To maintain Frenzy or about to get max charges
                "KILL_COMMAND",
                "DIRE_BEAST", -- If talented
                "BARBED_SHOT", -- If Bestial Wrath CD can be reduced
                "COBRA_SHOT", -- If enough Focus and Kill Command on CD
                "BARBED_SHOT" -- To dump charges before encounter ends
            },
            aoe = {
                "BARBED_SHOT", -- To maintain Frenzy
                "MULTI_SHOT", -- To maintain Beast Cleave
                "KILL_COMMAND",
                "DIRE_BEAST", -- If talented
                "COBRA_SHOT", -- If enough Focus
                "BARBED_SHOT" -- To dump charges
            },
            defensive = {
                "ASPECT_OF_THE_TURTLE",
                "EXHILARATION",
                "FEIGN_DEATH"
            }
        }
    },
    [254] = { -- Marksmanship Hunter
        name = "Marksmanship",
        role = "DPS",
        primaryResource = "Focus",
        secondaryResource = "None",
        strengths = {"Burst AOE", "Execute Damage", "Range"},
        weaknesses = {"Setup Time", "Mobility While Casting"},
        spells = {
            -- Core rotational spells
            AIMED_SHOT = 19434,
            ARCANE_SHOT = 185358,
            RAPID_FIRE = 257044,
            STEADY_SHOT = 56641,
            MULTI_SHOT = 257620,
            -- Cooldowns
            TRUESHOT = 288613,
            -- Talents
            VOLLEY = 260243,
            EXPLOSIVE_SHOT = 212431,
            TRICK_SHOTS = 257621,
            CALLING_THE_SHOTS = 260404,
            LOCK_AND_LOAD = 194594,
            CHIMAERA_SHOT = 342049,
            -- Defensive
            EXHILARATION = 109304,
            SURVIVAL_OF_THE_FITTEST = 264735, 
            -- Utility
            BINDING_SHOT = 109248,
            CAMOUFLAGE = 199483,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "TRUESHOT",
                "VOLLEY"
            },
            single_target = {
                "AIMED_SHOT", -- With Lock and Load proc
                "KILL_SHOT", -- If target below 20% health
                "EXPLOSIVE_SHOT", -- If talented
                "VOLLEY", -- If talented
                "AIMED_SHOT", -- Regular cast
                "RAPID_FIRE",
                "CHIMAERA_SHOT", -- If talented
                "ARCANE_SHOT", -- Focus dump
                "STEADY_SHOT" -- Focus generator
            },
            aoe = {
                "VOLLEY", -- If talented
                "TRICK_SHOTS", -- Via Multi-Shot
                "RAPID_FIRE",
                "AIMED_SHOT", -- With Trick Shots buff
                "EXPLOSIVE_SHOT", -- If talented
                "CHIMAERA_SHOT", -- If talented
                "MULTI_SHOT", -- Focus dump
                "STEADY_SHOT" -- Focus generator
            },
            defensive = {
                "ASPECT_OF_THE_TURTLE",
                "EXHILARATION",
                "SURVIVAL_OF_THE_FITTEST",
                "FEIGN_DEATH"
            }
        }
    },
    [255] = { -- Survival Hunter
        name = "Survival",
        role = "DPS",
        primaryResource = "Focus",
        secondaryResource = "None",
        strengths = {"Melee/Ranged Flexibility", "AOE Stuns", "DOT Cleave"},
        weaknesses = {"Complex Rotation", "Melee Range Limitations"},
        spells = {
            -- Core rotational spells
            RAPTOR_STRIKE = 186270,
            MONGOOSE_BITE = 259387,
            WILDFIRE_BOMB = 259495,
            CARVE = 187708,
            KILL_COMMAND = 259489,
            -- Cooldowns
            COORDINATED_ASSAULT = 360952,
            -- Talents
            BUTCHERY = 212436,
            FLANKING_STRIKE = 269751,
            CHAKRAMS = 259391,
            BIRDS_OF_PREY = 260331,
            WILDFIRE_INFUSION = 271014,
            -- Defensive
            EXHILARATION = 109304,
            -- Utility
            HARPOON = 190925,
            MUZZLE = 187707,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "COORDINATED_ASSAULT",
                "ASPECT_OF_THE_EAGLE" 
            },
            single_target = {
                "KILL_COMMAND",
                "WILDFIRE_BOMB",
                "FLANKING_STRIKE", -- If talented
                "MONGOOSE_BITE", -- If talented, prioritize during Mongoose Fury
                "RAPTOR_STRIKE", -- If not using Mongoose Bite
                "SERPENT_STING", -- If about to expire
                "CHAKRAMS" -- If talented
            },
            aoe = {
                "WILDFIRE_BOMB",
                "BUTCHERY", -- If talented
                "CARVE", -- If not using Butchery
                "KILL_COMMAND",
                "SERPENT_STING", -- Maintain on multiple targets
                "MONGOOSE_BITE", -- Cleave with Mad Bombardier
                "RAPTOR_STRIKE" -- Cleave with Mad Bombardier
            },
            defensive = {
                "ASPECT_OF_THE_TURTLE",
                "EXHILARATION",
                "FEIGN_DEATH"
            }
        }
    },
    
    -- Warrior Specs
    [71] = { -- Arms Warrior
        name = "Arms",
        role = "DPS",
        primaryResource = "Rage",
        secondaryResource = "None",
        strengths = {"Execute Phase", "Cleave Damage", "Burst Windows"},
        weaknesses = {"Rage Generation", "Target Switching"},
        spells = {
            -- Core rotational spells
            MORTAL_STRIKE = 12294,
            SLAM = 1464,
            EXECUTE = 163201,
            OVERPOWER = 7384,
            BLADESTORM = 227847,
            CLEAVE = 845,
            WHIRLWIND = 1680,
            -- Cooldowns
            COLOSSUS_SMASH = 167105,
            WARBREAKER = 262161,
            AVATAR = 107574,
            -- Talents
            SWEEPING_STRIKES = 260708,
            REND = 772,
            SKULLSPLITTER = 260643,
            STORM_BOLT = 107570,
            -- Defensive
            DIE_BY_THE_SWORD = 118038,
            DEFENSIVE_STANCE = 197690,
            -- Utility
            PIERCING_HOWL = 12323,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "AVATAR",
                "COLOSSUS_SMASH",
                "WARBREAKER"
            },
            single_target = {
                "COLOSSUS_SMASH", -- Or WARBREAKER if talented
                "EXECUTE", -- If target below 20% health
                "OVERPOWER",
                "MORTAL_STRIKE",
                "SKULLSPLITTER", -- If rage is low
                "REND", -- If not applied or about to expire
                "SLAM", -- If excess rage
                "WHIRLWIND" -- If nothing else to press
            },
            aoe = {
                "SWEEPING_STRIKES",
                "WARBREAKER", -- Or COLOSSUS_SMASH
                "BLADESTORM",
                "CLEAVE",
                "EXECUTE", -- With Cleave buff
                "MORTAL_STRIKE", -- With Cleave buff
                "OVERPOWER",
                "WHIRLWIND"
            },
            defensive = {
                "DIE_BY_THE_SWORD",
                "DEFENSIVE_STANCE",
                "RALLYING_CRY",
                "VICTORY_RUSH" -- When available for healing
            }
        }
    },
    [72] = { -- Fury Warrior
        name = "Fury",
        role = "DPS",
        primaryResource = "Rage",
        secondaryResource = "None",
        strengths = {"Sustained AOE", "Self-healing", "Mobility"},
        weaknesses = {"Ramp-up Time", "Cooldown Alignment"},
        spells = {
            -- Core rotational spells
            BLOODTHIRST = 23881,
            RAGING_BLOW = 85288,
            EXECUTE = 5308,
            RAMPAGE = 184367,
            WHIRLWIND = 190411,
            -- Cooldowns
            RECKLESSNESS = 1719,
            BLADESTORM = 46924,
            -- Talents
            ONSLAUGHT = 315720,
            MEAT_CLEAVER = 280392,
            SUDDEN_DEATH = 280721,
            SIEGEBREAKER = 280772,
            DRAGON_ROAR = 118000,
            -- Defensive
            ENRAGED_REGENERATION = 184364,
            -- Utility
            PIERCING_HOWL = 12323,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "RECKLESSNESS",
                "SIEGEBREAKER",
                "BLADESTORM"
            },
            single_target = {
                "RAMPAGE", -- If Enrage is down or at 80+ Rage
                "EXECUTE", -- If target below 20% or Sudden Death proc
                "BLOODTHIRST", -- If not Enraged
                "RAGING_BLOW", -- If 2 charges
                "ONSLAUGHT", -- If talented
                "BLOODTHIRST",
                "DRAGON_ROAR", -- If talented
                "RAGING_BLOW",
                "WHIRLWIND" -- If nothing else to press
            },
            aoe = {
                "WHIRLWIND", -- To maintain Meat Cleaver
                "RAMPAGE", -- For Enrage and Meat Cleaver cleaving
                "BLADESTORM", -- During Recklessness ideally
                "DRAGON_ROAR", -- If talented
                "BLOODTHIRST", -- For Enrage uptime
                "EXECUTE", -- With Sudden Death procs
                "RAGING_BLOW",
                "WHIRLWIND" -- Filler
            },
            defensive = {
                "ENRAGED_REGENERATION",
                "RALLYING_CRY",
                "IGNORE_PAIN" -- If talented
            }
        }
    },
    [73] = { -- Protection Warrior
        name = "Protection",
        role = "TANK",
        primaryResource = "Rage",
        secondaryResource = "None",
        strengths = {"Physical Damage Reduction", "Mobility", "Spell Reflection"},
        weaknesses = {"Self-healing", "Magic Damage"},
        spells = {
            -- Core rotational spells
            SHIELD_SLAM = 23922,
            THUNDER_CLAP = 6343,
            REVENGE = 6572,
            DEVASTATE = 20243,
            -- Cooldowns
            SHIELD_WALL = 871,
            AVATAR = 107574,
            DEMORALIZING_SHOUT = 1160,
            LAST_STAND = 12975,
            -- Talents
            RAVAGER = 228920,
            DRAGON_ROAR = 118000,
            BOLSTER = 280001,
            UNSTOPPABLE_FORCE = 275336,
            -- Defensive
            SHIELD_BLOCK = 2565,
            IGNORE_PAIN = 190456,
            -- Utility
            SPELL_REFLECTION = 23920,
            SHOCKWAVE = 46968,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "AVATAR",
                "DEMORALIZING_SHOUT",
                "RAVAGER"
            },
            single_target = {
                "SHIELD_SLAM",
                "THUNDER_CLAP",
                "REVENGE", -- If proc or excess rage
                "DEVASTATE"
            },
            aoe = {
                "THUNDER_CLAP",
                "SHOCKWAVE",
                "REVENGE",
                "SHIELD_SLAM",
                "DRAGON_ROAR" -- If talented
            },
            defensive = {
                "SHIELD_BLOCK", -- Proactive mitigation
                "IGNORE_PAIN", -- For magic damage or when Shield Block is down
                "LAST_STAND",
                "SHIELD_WALL", -- Major cooldown
                "SPELL_REFLECTION" -- For big spell hits
            }
        }
    },
    
    -- Demon Hunter Specs
    [577] = { -- Havoc Demon Hunter
        name = "Havoc",
        role = "DPS",
        primaryResource = "Fury",
        secondaryResource = "None",
        strengths = {"Mobility", "AOE Burst", "Utility"},
        weaknesses = {"Sustained Single Target", "Predictable Rotation"},
        spells = {
            -- Core rotational spells
            DEMONS_BITE = 162243,
            CHAOS_STRIKE = 162794,
            BLADE_DANCE = 188499,
            EYE_BEAM = 198013,
            FEL_RUSH = 195072,
            GLAIVE_TEMPEST = 342817,
            -- Cooldowns
            METAMORPHOSIS = 191427,
            -- Talents
            FELBLADE = 232893,
            FIRST_BLOOD = 206416,
            MOMENTUM = 206476,
            DEMONIC = 213410,
            ESSENCE_BREAK = 258860,
            -- Defensive
            BLUR = 198589,
            DARKNESS = 196718,
            -- Utility
            VENGEFUL_RETREAT = 198793,
            CHAOS_NOVA = 179057,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "METAMORPHOSIS",
                "ESSENCE_BREAK"
            },
            single_target = {
                "ESSENCE_BREAK", -- If talented
                "ANNIHILATION", -- CHAOS_STRIKE during Metamorphosis
                "DEATH_SWEEP", -- BLADE_DANCE during Metamorphosis
                "EYE_BEAM",
                "BLADE_DANCE", -- If First Blood talented
                "FELBLADE", -- If talented and Fury needed
                "IMMOLATION_AURA",
                "CHAOS_STRIKE",
                "THROW_GLAIVE", -- If moving
                "DEMONS_BITE" -- Fury generator
            },
            aoe = {
                "EYE_BEAM",
                "GLAIVE_TEMPEST", -- If talented
                "DEATH_SWEEP", -- BLADE_DANCE during Metamorphosis
                "BLADE_DANCE",
                "IMMOLATION_AURA",
                "FEL_RUSH", -- With Unbound Chaos or Momentum
                "CHAOS_STRIKE", -- Dump excess Fury
                "THROW_GLAIVE",
                "DEMONS_BITE" -- Fury generator
            },
            defensive = {
                "BLUR",
                "DARKNESS",
                "NETHERWALK" -- If talented
            }
        }
    },
    [581] = { -- Vengeance Demon Hunter
        name = "Vengeance",
        role = "TANK",
        primaryResource = "Fury",
        secondaryResource = "None",
        strengths = {"Self-healing", "Mobility", "Utility"},
        weaknesses = {"Against Magic Damage", "Spiky Damage"},
        spells = {
            -- Core rotational spells
            SHEAR = 203782,
            SOUL_CLEAVE = 228477,
            IMMOLATION_AURA = 258920,
            FRACTURE = 263642,
            SIGIL_OF_FLAME = 204596,
            INFERNAL_STRIKE = 189110,
            -- Cooldowns
            FIERY_BRAND = 204021,
            METAMORPHOSIS = 187827,
            -- Talents
            SPIRIT_BOMB = 247454,
            FELBLADE = 232893,
            FEL_DEVASTATION = 212084,
            BULK_EXTRACTION = 320341,
            -- Defensive
            DEMON_SPIKES = 203720,
            SOUL_BARRIER = 263648,
            -- Utility
            SIGIL_OF_SILENCE = 202137,
            SIGIL_OF_MISERY = 207684,
            SIGIL_OF_CHAINS = 202138,
        },
        rotation = {
            -- Simplified rotation priority
            cooldowns = {
                "FIERY_BRAND",
                "METAMORPHOSIS"
            },
            single_target = {
                "IMMOLATION_AURA",
                "SIGIL_OF_FLAME",
                "SPIRIT_BOMB", -- If talented and 4+ Soul Fragments
                "FRACTURE", -- If talented
                "SOUL_CLEAVE", -- Spend Fury and heal
                "FELBLADE", -- If talented and Fury needed
                "SHEAR" -- Fury generator
            },
            aoe = {
                "INFERNAL_STRIKE",
                "IMMOLATION_AURA",
                "SIGIL_OF_FLAME",
                "FEL_DEVASTATION", -- If talented
                "SPIRIT_BOMB", -- If talented and 4+ Soul Fragments
                "SOUL_CLEAVE",
                "FRACTURE", -- If talented
                "SHEAR"
            },
            defensive = {
                "DEMON_SPIKES", -- Proactive mitigation
                "FIERY_BRAND", -- For big hits
                "METAMORPHOSIS", -- Emergency cooldown
                "SOUL_BARRIER" -- If talented
            }
        }
    },
}

-- Main database initialization
function WR.Data.Classes:Initialize()
    -- Format the data for our addon
    self.ClassList = {}
    self.SpecList = {}
    
    -- Process each class
    for className, classData in pairs(CLASS_INFO) do
        self.ClassList[classData.id] = {
            id = classData.id,
            name = classData.name,
            color = classData.color,
            token = className,
            specs = {},
            baseSpells = classData.baseSpells
        }
        
        -- Process specs for this class
        for specID, specInfo in pairs(classData.specs) do
            -- Add to class list
            self.ClassList[classData.id].specs[specID] = {
                id = specID,
                name = specInfo.name,
                role = specInfo.role,
                icon = specInfo.icon
            }
            
            -- Add to spec list with detailed info
            self.SpecList[specID] = {
                id = specID,
                name = specInfo.name,
                role = specInfo.role,
                icon = specInfo.icon,
                classID = classData.id,
                className = classData.name
            }
            
            -- Add detailed spec data if available
            if SPEC_DETAILS[specID] then
                for key, value in pairs(SPEC_DETAILS[specID]) do
                    self.SpecList[specID][key] = value
                end
            end
        end
    end
    
    WR:Debug("Classes data initialized")
end

-- Get class data by ID
function WR.Data.Classes:GetClassByID(classID)
    return self.ClassList[classID]
end

-- Get spec data by ID
function WR.Data.Classes:GetSpecByID(specID)
    return self.SpecList[specID]
end

-- Get current player class data
function WR.Data.Classes:GetPlayerClass()
    local _, className = UnitClass("player")
    for id, classData in pairs(self.ClassList) do
        if classData.token == className then
            return classData
        end
    end
    return nil
end

-- Get current player spec data
function WR.Data.Classes:GetPlayerSpec()
    local specID = GetSpecialization()
    if not specID then return nil end
    
    local currentSpecID = GetSpecializationInfo(specID)
    return self.SpecList[currentSpecID]
end

-- Get a spell ID for the current class/spec
function WR.Data.Classes:GetSpellID(spellKey)
    if not spellKey then return nil end
    
    local playerClass = self:GetPlayerClass()
    local playerSpec = self:GetPlayerSpec()
    
    if not playerClass or not playerSpec then 
        return nil 
    end
    
    -- Check if it's a base class spell
    if playerClass.baseSpells and playerClass.baseSpells[spellKey] then
        return playerClass.baseSpells[spellKey]
    end
    
    -- Check if it's a spec-specific spell
    if playerSpec.spells and playerSpec.spells[spellKey] then
        return playerSpec.spells[spellKey]
    end
    
    return nil
end

-- Initialize the class data
WR.Data.Classes:Initialize()
