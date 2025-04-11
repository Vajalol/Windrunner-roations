------------------------------------------
-- WindrunnerRotations - Affliction Warlock Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Affliction = {}
-- This will be assigned to addon.Classes.Warlock.Affliction when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Warlock

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentSoulShards = 0
local maxSoulShards = 5
local darkSoulMiseryActive = false
local darkSoulMiseryEndTime = 0
local summonDarkglareActive = false
local summonDarkglareEndTime = 0
local phantomSingularityActive = false
local phantomSingularityEndTime = 0
local vileTranceCDActive = false
local vileTranceCDEndTime = 0
local shadowBoltNightFall = false
local hauntActive = false
local hauntEndTime = 0
local seedOfCorruptionExploding = false
local agonyActive = {}
local agonyEndTime = {}
local corruptionActive = {}
local corruptionEndTime = {}
local siphonLifeActive = {}
local siphonLifeEndTime = {}
local unstableAfflictionActive = {}
local unstableAfflictionStacks = {}
local unstableAfflictionEndTime = {}
local maleficRaptureBuffActive = false
local maleficRaptureBuffEndTime = 0
local maleficRaptureBuffStacks = 0
local shadowEmbracActive = {}
local shadowEmbracStacks = {}
local shadowEmbracEndTime = {}
local soulRotActive = false
local soulRotEndTime = 0
local dreadstalkers = false
local dreadstalkerEndTime = 0
local felguardAxeToss = false
local grimOfSacCDStacks = 0
local seedOfCorruptionActive = {}
local seedOfCorruptionEndTime = {}
local playerHealthPercent = 100
local playerHealthPercentDecrease = 0
local inevitableDemiseActive = false
local inevitableDemiseStacks = 0
local inevitableDemiseEndTime = 0
local darkSoul = false
local felStorm = false
local felStormActive = false
local felStormEndTime = 0
local felDomination = false
local absInProgress = false
local absEndTime = 0
local doomBrand = false
local doomBrandEndTime = 0
local petActive = false
local currentMana = 0
local maxMana = 100
local inRangeAgony = false
local unendingResolve = false
local healthstone = false
local drainLife = false
local darkcycle = false
local shadowburn = false
local soulBurn = false
local soulTap = false
local grimOfSacrifice = false
local creepingDeath = false
local sacSouls = false
local agony = false
local corruption = false
local unstableAffliction = false
local seedOfCorruption = false
local maleficRapture = false
local siphonLife = false
local phantomSingularity = false
local vileTranceCooldown = false
local summonDarkglare = false
local amplifyCurse = false
local mortalCoil = false
local curseOfExhaustion = false
local curseOfTongues = false
local curseOfWeakness = false
local darkPact = false
local demonSkin = false
local soulLeech = false
local shadowfury = false
local demonicStrength = false
local howlOfTerror = false
local shadowFlame = false
local exhaustion = false
local internalCombustion = false
local agonizingCorruption = false
local writheInAgony = false
local absoluteCorruption = false
local soulmeltStacks = 0
local sigilOfFlameStacks = 0
local warlockMisery = false
local soulTrauma = false
local dreadTouchStacks = 0
local infectedAspect = false
local infusedMalice = false

-- Constants
local AFFLICTION_SPEC_ID = 265
local DEFAULT_AOE_THRESHOLD = 3
local DARK_SOUL_MISERY_DURATION = 20 -- seconds
local SUMMON_DARKGLARE_DURATION = 20 -- seconds
local PHANTOM_SINGULARITY_DURATION = 16 -- seconds
local HAUNT_DURATION = 15 -- seconds
local SOUL_ROT_DURATION = 8 -- seconds
local IMMOLATION_DURATION = 18 -- seconds
local AGONY_DURATION = 18 -- seconds
local CORRUPTION_DURATION = 14 -- seconds
local UNSTABLE_AFFLICTION_DURATION = 16 -- seconds (base)
local SIPHON_LIFE_DURATION = 15 -- seconds
local SHADOW_EMBRACE_DURATION = 10 -- seconds
local DOOM_DURATION = 20 -- seconds (base)
local SEED_OF_CORRUPTION_DURATION = 12 -- seconds
local GRIMOIRE_OF_SACRIFICE_DURATION = 3600 -- seconds (1 hour)
local INEVITABLE_DEMISE_DURATION = 20 -- seconds
local DOT_RANGE = 40 -- yards
local MAX_TARGETS_TRACKED = 12 -- Max targets to track for multi-dotting
local DEFENSIVE_HEALTHSTONE_PERCENT = 40 -- When to use healthstone

-- Initialize the Affliction module
function Affliction:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Affliction Warlock module initialized")
    
    return true
end

-- Register spell IDs
function Affliction:RegisterSpells()
    -- Core rotational abilities
    spells.SHADOW_BOLT = 686
    spells.DRAIN_SOUL = 198590
    spells.MALEFIC_RAPTURE = 324536
    spells.SEED_OF_CORRUPTION = 27243
    spells.AGONY = 980
    spells.CORRUPTION = 172
    spells.UNSTABLE_AFFLICTION = 316099
    spells.SIPHON_LIFE = 63106
    spells.HAUNT = 48181
    spells.PHANTOM_SINGULARITY = 205179
    spells.VILE_TRANCE = 205180
    spells.SOUL_ROT = 325640
    spells.DARK_SOUL_MISERY = 113860
    spells.SUMMON_DARKGLARE = 205180
    spells.SHADOWBURN = 17877
    spells.DRAIN_LIFE = 234153
    
    -- Core utilities
    spells.UNENDING_RESOLVE = 104773
    spells.DARK_PACT = 108416
    spells.HEALTHSTONE = 6262
    spells.CREATE_HEALTHSTONE = 6201
    spells.HEALTH_FUNNEL = 755
    spells.FEL_DOMINATION = 333889
    spells.DEMONIC_GATEWAY = 111771
    spells.DEMONIC_CIRCLE = 48018
    spells.DEMONIC_CIRCLE_TELEPORT = 48020
    spells.FEAR = 5782
    spells.BANISH = 710
    spells.SHADOWFURY = 30283
    spells.MORTAL_COIL = 6789
    spells.HOWL_OF_TERROR = 5484
    spells.CURSE_OF_WEAKNESS = 702
    spells.CURSE_OF_TONGUES = 1714
    spells.CURSE_OF_EXHAUSTION = 334275
    
    -- Pet abilities
    spells.SUMMON_IMP = 688
    spells.SUMMON_VOIDWALKER = 697
    spells.SUMMON_FELHUNTER = 691
    spells.SUMMON_SUCCUBUS = 712
    spells.COMMAND_DEMON = 119898
    spells.SHADOW_BULWARK = 119907
    spells.SPELL_LOCK = 19647
    spells.SUMMON_FELGUARD = 30146
    spells.AXE_TOSS = 89766
    spells.FEL_STORM = 89751
    spells.GRIMOIRE_OF_SACRIFICE = 108503
    
    -- Talents and passives
    spells.NIGHTFALL = 108558
    spells.INEVITABLE_DEMISE = 334319
    spells.WRITHE_IN_AGONY = 196102
    spells.ABSOLUTE_CORRUPTION = 196103
    spells.SIPHON_LIFE = 63106
    spells.SOULBURN = 385899
    spells.EXHAUSTION = 198590
    spells.CREEPING_DEATH = 264000
    spells.HAUNT = 48181
    spells.SHADOW_EMBRACE = 32388
    spells.PHANTOM_SINGULARITY = 205179
    spells.SOUL_CONDUIT = 215941
    spells.DARK_SOUL_MISERY = 113860
    spells.SOUL_TAP = 387073
    spells.AMPLIFY_CURSE = 328774
    spells.GRIMOIRE_OF_SACRIFICE = 108503
    spells.DARKFURY = 264874
    spells.MORTAL_COIL = 6789
    spells.HOWL_OF_TERROR = 5484
    spells.DEMONIC_STRENGTH = 267171
    spells.INTERNAL_COMBUSTION = 266134
    spells.AGONIZING_CORRUPTION = 386105
    spells.SHADOWFLAME = 384069
    spells.SOUL_SWAP = -1 -- Removed in modern WoW but kept as reference
    spells.GRAND_WARLOCK = 266086
    spells.SUMMON_DARKGLARE = 205180
    spells.VILE_TRANCE = 205180
    
    -- War Within Season 2 specific
    spells.INFERNAL_PACT = 387173
    spells.SOULMELT = 387159
    spells.SIGIL_OF_FLAME = 385899
    spells.DRAIN_LIFE_SIPHON = 198590
    spells.WARLOCK_MISERY = 387079
    spells.DOOM_BRAND = 387084
    spells.MALEVOLENT_WRATH = 387158
    spells.INFERNAL_BOND = 387145
    spells.SOUL_TRAUMA = 387085
    spells.ABYSS_WALKER = 387106
    spells.DREAD_TOUCH = 386857
    spells.CASTING_CIRCLE = 221703
    spells.GRIM_FEAST = 387156
    spells.INFUSED_MALICE = 387075

    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.IMPENDING_CATASTROPHE = 375757
    spells.DECIMATING_BOLT = 325289
    spells.SCOURING_TITHE = 312321
    spells.SOUL_ROT = 325640
    
    -- Buff IDs
    spells.DARK_SOUL_MISERY_BUFF = 113860
    spells.NIGHTFALL_BUFF = 264571
    spells.INEVITABLE_DEMISE_BUFF = 334320
    spells.MALEFIC_RAPTURE_BUFF = 387550
    spells.GRIMOIRE_OF_SACRIFICE_BUFF = 196099
    spells.DARKGLARE_BUFF = 205180
    spells.PHANTOM_SINGULARITY_BUFF = 205179
    spells.SOUL_ROT_BUFF = 325640
    spells.DARK_PACT_BUFF = 108416
    spells.UNENDING_RESOLVE_BUFF = 104773
    spells.SOUL_LEECH_BUFF = 108366
    spells.DEMON_SKIN_BUFF = 219272
    
    -- Debuff IDs
    spells.AGONY_DEBUFF = 980
    spells.CORRUPTION_DEBUFF = 146739
    spells.UNSTABLE_AFFLICTION_DEBUFF = 316099
    spells.SIPHON_LIFE_DEBUFF = 63106
    spells.HAUNT_DEBUFF = 48181
    spells.SHADOW_EMBRACE_DEBUFF = 32390
    spells.SEED_OF_CORRUPTION_DEBUFF = 27243
    spells.PHANTOM_SINGULARITY_DEBUFF = 205179
    spells.SOUL_ROT_DEBUFF = 325640
    spells.CURSE_OF_WEAKNESS_DEBUFF = 702
    spells.CURSE_OF_TONGUES_DEBUFF = 1714
    spells.CURSE_OF_EXHAUSTION_DEBUFF = 334275
    spells.DOOM_DEBUFF = 603
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.DARK_SOUL_MISERY = spells.DARK_SOUL_MISERY_BUFF
    buffs.NIGHTFALL = spells.NIGHTFALL_BUFF
    buffs.INEVITABLE_DEMISE = spells.INEVITABLE_DEMISE_BUFF
    buffs.MALEFIC_RAPTURE = spells.MALEFIC_RAPTURE_BUFF
    buffs.GRIMOIRE_OF_SACRIFICE = spells.GRIMOIRE_OF_SACRIFICE_BUFF
    buffs.DARKGLARE = spells.DARKGLARE_BUFF
    buffs.PHANTOM_SINGULARITY = spells.PHANTOM_SINGULARITY_BUFF
    buffs.SOUL_ROT = spells.SOUL_ROT_BUFF
    buffs.DARK_PACT = spells.DARK_PACT_BUFF
    buffs.UNENDING_RESOLVE = spells.UNENDING_RESOLVE_BUFF
    buffs.SOUL_LEECH = spells.SOUL_LEECH_BUFF
    buffs.DEMON_SKIN = spells.DEMON_SKIN_BUFF
    
    debuffs.AGONY = spells.AGONY_DEBUFF
    debuffs.CORRUPTION = spells.CORRUPTION_DEBUFF
    debuffs.UNSTABLE_AFFLICTION = spells.UNSTABLE_AFFLICTION_DEBUFF
    debuffs.SIPHON_LIFE = spells.SIPHON_LIFE_DEBUFF
    debuffs.HAUNT = spells.HAUNT_DEBUFF
    debuffs.SHADOW_EMBRACE = spells.SHADOW_EMBRACE_DEBUFF
    debuffs.SEED_OF_CORRUPTION = spells.SEED_OF_CORRUPTION_DEBUFF
    debuffs.PHANTOM_SINGULARITY = spells.PHANTOM_SINGULARITY_DEBUFF
    debuffs.SOUL_ROT = spells.SOUL_ROT_DEBUFF
    debuffs.CURSE_OF_WEAKNESS = spells.CURSE_OF_WEAKNESS_DEBUFF
    debuffs.CURSE_OF_TONGUES = spells.CURSE_OF_TONGUES_DEBUFF
    debuffs.CURSE_OF_EXHAUSTION = spells.CURSE_OF_EXHAUSTION_DEBUFF
    debuffs.DOOM = spells.DOOM_DEBUFF
    
    return true
end

-- Register variables to track
function Affliction:RegisterVariables()
    -- Talent tracking
    talents.hasNightfall = false
    talents.hasInevitableDemise = false
    talents.hasWritheInAgony = false
    talents.hasAbsoluteCorruption = false
    talents.hasSiphonLife = false
    talents.hasSoulburn = false
    talents.hasExhaustion = false
    talents.hasCreepingDeath = false
    talents.hasHaunt = false
    talents.hasShadowEmbrace = false
    talents.hasPhantomSingularity = false
    talents.hasSoulConduit = false
    talents.hasDarkSoulMisery = false
    talents.hasSoulTap = false
    talents.hasAmplifyCurse = false
    talents.hasCurseOfExhaustion = false
    talents.hasCurseOfTongues = false
    talents.hasCurseOfWeakness = false
    talents.hasGrimoireOfSacrifice = false
    talents.hasDarkfury = false
    talents.hasMortalCoil = false
    talents.hasHowlOfTerror = false
    talents.hasDemonicStrength = false
    talents.hasInternalCombustion = false
    talents.hasAgonizingCorruption = false
    talents.hasShadowflame = false
    talents.hasSoulSwap = false
    talents.hasGrandWarlock = false
    talents.hasSummonDarkglare = false
    talents.hasVileTrance = false
    talents.hasDarkPact = false
    talents.hasDemonSkin = false
    talents.hasSoulLeech = false
    talents.hasShadowfury = false
    
    -- War Within Season 2 talents
    talents.hasInfernalPact = false
    talents.hasSoulmelt = false
    talents.hasSigilOfFlame = false
    talents.hasDrainLifeSiphon = false
    talents.hasWarlockMisery = false
    talents.hasDoomBrand = false
    talents.hasMalevolentWrath = false
    talents.hasInfernalBond = false
    talents.hasSoulTrauma = false
    talents.hasAbyssWalker = false
    talents.hasDreadTouch = false
    talents.hasCastingCircle = false
    talents.hasGrimFeast = false
    talents.hasInfusedMalice = false
    
    -- Initialize soul shards
    currentSoulShards = API.GetPlayerSoulShards() or 0
    
    -- Initialize mana
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    
    -- Initialize pet status
    petActive = API.HasActivePet()
    
    -- Initialize tracking tables
    agonyActive = {}
    agonyEndTime = {}
    corruptionActive = {}
    corruptionEndTime = {}
    siphonLifeActive = {}
    siphonLifeEndTime = {}
    unstableAfflictionActive = {}
    unstableAfflictionStacks = {}
    unstableAfflictionEndTime = {}
    shadowEmbracActive = {}
    shadowEmbracStacks = {}
    shadowEmbracEndTime = {}
    seedOfCorruptionActive = {}
    seedOfCorruptionEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Affliction:RegisterSettings()
    ConfigRegistry:RegisterSettings("AfflictionWarlock", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst damage",
                type = "toggle",
                default = true
            },
            aoeEnabled = {
                displayName = "Enable AoE Rotation",
                description = "Use area damage abilities when multiple targets are present",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Target Threshold",
                description = "Minimum number of targets to use AoE abilities",
                type = "slider",
                min = 2,
                max = 8,
                default = DEFAULT_AOE_THRESHOLD
            },
            fillWithDrainSoul = {
                displayName = "Fill With Drain Soul",
                description = "Use Drain Soul as filler instead of Shadow Bolt",
                type = "toggle",
                default = true
            },
            soulShardLimit = {
                displayName = "Soul Shard Builder Limit",
                description = "Stop building shards at this limit",
                type = "slider",
                min = 2,
                max = 5,
                default = 4
            },
            multidotMode = {
                displayName = "Multidot Mode",
                description = "How to handle multidotting targets",
                type = "dropdown",
                options = {"Conservative", "Balanced", "Aggressive", "Focused"},
                default = "Balanced"
            },
            dotRefreshThreshold = {
                displayName = "DoT Refresh Threshold",
                description = "Refresh DoTs when remaining time is below this many seconds",
                type = "slider",
                min = 1,
                max = 8,
                default = 4
            },
            usePetActive = {
                displayName = "Use Pet",
                description = "Summon and use pet instead of Grimoire of Sacrifice",
                type = "toggle",
                default = true
            },
            preferredPet = {
                displayName = "Preferred Pet",
                description = "Pet to summon when needed",
                type = "dropdown",
                options = {"Imp", "Felhunter", "Succubus", "Voidwalker", "Felguard"},
                default = "Imp"
            }
        },
        
        spellSettings = {
            priorityDotOrder = {
                displayName = "Priority DoT Order",
                description = "Order of DoT priority for application",
                type = "dropdown",
                options = {"Agony > Corruption > UA > SL", "Agony > UA > Corruption > SL", "UA > Agony > Corruption > SL", "UA > Agony > SL > Corruption"},
                default = "Agony > Corruption > UA > SL"
            },
            useUnstableAffliction = {
                displayName = "Use Unstable Affliction",
                description = "Automatically use Unstable Affliction",
                type = "toggle",
                default = true
            },
            useSiphonLife = {
                displayName = "Use Siphon Life",
                description = "Automatically use Siphon Life when talented",
                type = "toggle",
                default = true
            },
            siphonLifeTargetLimit = {
                displayName = "Siphon Life Target Limit",
                description = "Maximum targets to apply Siphon Life",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            useHaunt = {
                displayName = "Use Haunt",
                description = "Automatically use Haunt when talented",
                type = "toggle",
                default = true
            },
            maleficRaptureMinShards = {
                displayName = "Malefic Rapture Min Shards",
                description = "Minimum soul shards to use Malefic Rapture",
                type = "slider",
                min = 1,
                max = 4,
                default = 1
            },
            maleficRaptureMaxShards = {
                displayName = "Malefic Rapture Max Shards",
                description = "Maximum soul shards to use on a single Malefic Rapture cast",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            },
            seedMinTargets = {
                displayName = "Seed of Corruption Min Targets",
                description = "Minimum number of targets to use Seed of Corruption",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            }
        },
        
        cooldownSettings = {
            useDarkSoul = {
                displayName = "Use Dark Soul: Misery",
                description = "Automatically use Dark Soul: Misery when talented",
                type = "toggle",
                default = true
            },
            useDarkglare = {
                displayName = "Use Summon Darkglare",
                description = "Automatically use Summon Darkglare when talented",
                type = "toggle",
                default = true
            },
            darkglareDotThreshold = {
                displayName = "Darkglare DoT Threshold",
                description = "Minimum DoTs active to use Darkglare",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            },
            usePhantomSingularity = {
                displayName = "Use Phantom Singularity",
                description = "Automatically use Phantom Singularity when talented",
                type = "toggle",
                default = true
            },
            phantomSingularityMinTargets = {
                displayName = "Phantom Singularity Min Targets",
                description = "Minimum targets to use Phantom Singularity",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            useSoulRot = {
                displayName = "Use Soul Rot",
                description = "Automatically use Soul Rot when talented",
                type = "toggle",
                default = true
            },
            soulRotMinTargets = {
                displayName = "Soul Rot Min Targets",
                description = "Minimum targets to use Soul Rot",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            useVileTrance = {
                displayName = "Use Vile Trance",
                description = "Automatically use Vile Trance when talented",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            useUnendingResolve = {
                displayName = "Use Unending Resolve",
                description = "Automatically use Unending Resolve",
                type = "toggle",
                default = true
            },
            unendingResolveThreshold = {
                displayName = "Unending Resolve Health Threshold",
                description = "Health percentage to use Unending Resolve",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useDarkPact = {
                displayName = "Use Dark Pact",
                description = "Automatically use Dark Pact when talented",
                type = "toggle",
                default = true
            },
            darkPactThreshold = {
                displayName = "Dark Pact Health Threshold",
                description = "Health percentage to use Dark Pact",
                type = "slider",
                min = 20,
                max = 70,
                default = 50
            },
            useHealthstone = {
                displayName = "Use Healthstone",
                description = "Automatically use Healthstone",
                type = "toggle",
                default = true
            },
            healthstoneThreshold = {
                displayName = "Healthstone Health Threshold",
                description = "Health percentage to use Healthstone",
                type = "slider",
                min = 10,
                max = 60,
                default = DEFENSIVE_HEALTHSTONE_PERCENT
            },
            useDrainLife = {
                displayName = "Use Drain Life",
                description = "Automatically use Drain Life for healing",
                type = "toggle",
                default = true
            },
            drainLifeThreshold = {
                displayName = "Drain Life Health Threshold",
                description = "Health percentage to use Drain Life",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            }
        },
        
        utilitySettings = {
            useCurseOfWeakness = {
                displayName = "Use Curse of Weakness",
                description = "Automatically apply Curse of Weakness",
                type = "toggle",
                default = true
            },
            useCurseOfTongues = {
                displayName = "Use Curse of Tongues",
                description = "Automatically apply Curse of Tongues on casters",
                type = "toggle",
                default = true
            },
            useCurseOfExhaustion = {
                displayName = "Use Curse of Exhaustion",
                description = "Automatically apply Curse of Exhaustion on specific targets",
                type = "toggle",
                default = true
            },
            useShadowfury = {
                displayName = "Use Shadowfury",
                description = "Automatically use Shadowfury for crowd control",
                type = "toggle",
                default = true
            },
            shadowfuryMinTargets = {
                displayName = "Shadowfury Min Targets",
                description = "Minimum targets to use Shadowfury",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useFear = {
                displayName = "Use Fear",
                description = "Automatically use Fear",
                type = "toggle",
                default = true
            },
            useMortalCoil = {
                displayName = "Use Mortal Coil",
                description = "Automatically use Mortal Coil when talented",
                type = "toggle",
                default = true
            },
            mortalCoilThreshold = {
                displayName = "Mortal Coil Health Threshold",
                description = "Health percentage to use Mortal Coil for healing",
                type = "slider",
                min = 10,
                max = 70,
                default = 50
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Dark Soul: Misery controls
            darkSoulMisery = AAC.RegisterAbility(spells.DARK_SOUL_MISERY, {
                enabled = true,
                useDuringBurstOnly = true,
                requireDarkglare = false,
                minDotsOnTarget = 3
            }),
            
            -- Summon Darkglare controls
            summonDarkglare = AAC.RegisterAbility(spells.SUMMON_DARKGLARE, {
                enabled = true,
                useDuringBurstOnly = true,
                requireDarkSoul = false,
                minDotsOnTarget = 3
            }),
            
            -- Phantom Singularity controls
            phantomSingularity = AAC.RegisterAbility(spells.PHANTOM_SINGULARITY, {
                enabled = true,
                useDuringBurstOnly = false,
                useOnlyWithDarkglare = false,
                minTargets = 1
            })
        }
    })
    
    return true
end

-- Register for events 
function Affliction:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for shard updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "SOUL_SHARDS" then
            self:UpdateSoulShards()
        end
    end)
    
    -- Register for mana updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "MANA" then
            self:UpdateMana()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        end
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for pet events
    API.RegisterEvent("UNIT_PET", function(unit) 
        if unit == "player" then
            self:UpdatePetStatus()
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial pet status check
    self:UpdatePetStatus()
    
    return true
end

-- Update talent information
function Affliction:UpdateTalentInfo()
    -- Check for important talents
    talents.hasNightfall = API.HasTalent(spells.NIGHTFALL)
    talents.hasInevitableDemise = API.HasTalent(spells.INEVITABLE_DEMISE)
    talents.hasWritheInAgony = API.HasTalent(spells.WRITHE_IN_AGONY)
    talents.hasAbsoluteCorruption = API.HasTalent(spells.ABSOLUTE_CORRUPTION)
    talents.hasSiphonLife = API.HasTalent(spells.SIPHON_LIFE)
    talents.hasSoulburn = API.HasTalent(spells.SOULBURN)
    talents.hasExhaustion = API.HasTalent(spells.EXHAUSTION)
    talents.hasCreepingDeath = API.HasTalent(spells.CREEPING_DEATH)
    talents.hasHaunt = API.HasTalent(spells.HAUNT)
    talents.hasShadowEmbrace = API.HasTalent(spells.SHADOW_EMBRACE)
    talents.hasPhantomSingularity = API.HasTalent(spells.PHANTOM_SINGULARITY)
    talents.hasSoulConduit = API.HasTalent(spells.SOUL_CONDUIT)
    talents.hasDarkSoulMisery = API.HasTalent(spells.DARK_SOUL_MISERY)
    talents.hasSoulTap = API.HasTalent(spells.SOUL_TAP)
    talents.hasAmplifyCurse = API.HasTalent(spells.AMPLIFY_CURSE)
    talents.hasCurseOfExhaustion = API.HasTalent(spells.CURSE_OF_EXHAUSTION)
    talents.hasCurseOfTongues = API.HasTalent(spells.CURSE_OF_TONGUES)
    talents.hasCurseOfWeakness = API.HasTalent(spells.CURSE_OF_WEAKNESS)
    talents.hasGrimoireOfSacrifice = API.HasTalent(spells.GRIMOIRE_OF_SACRIFICE)
    talents.hasDarkfury = API.HasTalent(spells.DARKFURY)
    talents.hasMortalCoil = API.HasTalent(spells.MORTAL_COIL)
    talents.hasHowlOfTerror = API.HasTalent(spells.HOWL_OF_TERROR)
    talents.hasDemonicStrength = API.HasTalent(spells.DEMONIC_STRENGTH)
    talents.hasInternalCombustion = API.HasTalent(spells.INTERNAL_COMBUSTION)
    talents.hasAgonizingCorruption = API.HasTalent(spells.AGONIZING_CORRUPTION)
    talents.hasShadowflame = API.HasTalent(spells.SHADOWFLAME)
    talents.hasSoulSwap = API.HasTalent(spells.SOUL_SWAP)
    talents.hasGrandWarlock = API.HasTalent(spells.GRAND_WARLOCK)
    talents.hasSummonDarkglare = API.HasTalent(spells.SUMMON_DARKGLARE)
    talents.hasVileTrance = API.HasTalent(spells.VILE_TRANCE)
    talents.hasDarkPact = API.HasTalent(spells.DARK_PACT)
    talents.hasDemonSkin = API.HasTalent(spells.DEMON_SKIN)
    talents.hasSoulLeech = API.HasTalent(spells.SOUL_LEECH)
    talents.hasShadowfury = API.HasTalent(spells.SHADOWFURY)
    
    -- War Within Season 2 talents
    talents.hasInfernalPact = API.HasTalent(spells.INFERNAL_PACT)
    talents.hasSoulmelt = API.HasTalent(spells.SOULMELT)
    talents.hasSigilOfFlame = API.HasTalent(spells.SIGIL_OF_FLAME)
    talents.hasDrainLifeSiphon = API.HasTalent(spells.DRAIN_LIFE_SIPHON)
    talents.hasWarlockMisery = API.HasTalent(spells.WARLOCK_MISERY)
    talents.hasDoomBrand = API.HasTalent(spells.DOOM_BRAND)
    talents.hasMalevolentWrath = API.HasTalent(spells.MALEVOLENT_WRATH)
    talents.hasInfernalBond = API.HasTalent(spells.INFERNAL_BOND)
    talents.hasSoulTrauma = API.HasTalent(spells.SOUL_TRAUMA)
    talents.hasAbyssWalker = API.HasTalent(spells.ABYSS_WALKER)
    talents.hasDreadTouch = API.HasTalent(spells.DREAD_TOUCH)
    talents.hasCastingCircle = API.HasTalent(spells.CASTING_CIRCLE)
    talents.hasGrimFeast = API.HasTalent(spells.GRIM_FEAST)
    talents.hasInfusedMalice = API.HasTalent(spells.INFUSED_MALICE)
    
    -- Set specialized variables based on talents
    if talents.hasUnendingResolve then
        unendingResolve = true
    end
    
    if talents.hasDarkPact then
        darkPact = true
    end
    
    if API.IsSpellKnown(spells.DRAIN_LIFE) then
        drainLife = true
    end
    
    if talents.hasSoulburn then
        soulBurn = true
    end
    
    if talents.hasSoulTap then
        soulTap = true
    end
    
    if talents.hasGrimoireOfSacrifice then
        grimOfSacrifice = true
    end
    
    if talents.hasCreepingDeath then
        creepingDeath = true
    end
    
    if talents.hasSacSouls then
        sacSouls = true
    end
    
    if API.IsSpellKnown(spells.AGONY) then
        agony = true
    end
    
    if API.IsSpellKnown(spells.CORRUPTION) then
        corruption = true
    end
    
    if API.IsSpellKnown(spells.UNSTABLE_AFFLICTION) then
        unstableAffliction = true
    end
    
    if API.IsSpellKnown(spells.SEED_OF_CORRUPTION) then
        seedOfCorruption = true
    end
    
    if API.IsSpellKnown(spells.MALEFIC_RAPTURE) then
        maleficRapture = true
    end
    
    if talents.hasSiphonLife then
        siphonLife = true
    end
    
    if talents.hasPhantomSingularity then
        phantomSingularity = true
    end
    
    if talents.hasVileTrance then
        vileTranceCooldown = true
    end
    
    if talents.hasSummonDarkglare then
        summonDarkglare = true
    end
    
    if talents.hasSoulRot then
        soulRot = true
    end
    
    if talents.hasAmplifyCurse then
        amplifyCurse = true
    end
    
    if talents.hasMortalCoil then
        mortalCoil = true
    end
    
    if talents.hasCurseOfExhaustion then
        curseOfExhaustion = true
    end
    
    if talents.hasCurseOfTongues then
        curseOfTongues = true
    end
    
    if talents.hasCurseOfWeakness then
        curseOfWeakness = true
    end
    
    if talents.hasDarkSoulMisery then
        darkSoul = true
    end
    
    if talents.hasDemonSkin then
        demonSkin = true
    end
    
    if talents.hasSoulLeech then
        soulLeech = true
    end
    
    if talents.hasShadowfury then
        shadowfury = true
    end
    
    if talents.hasDemonicStrength then
        demonicStrength = true
    end
    
    if talents.hasHowlOfTerror then
        howlOfTerror = true
    end
    
    if talents.hasShadowflame then
        shadowFlame = true
    end
    
    if talents.hasExhaustion then
        exhaustion = true
    end
    
    if talents.hasInternalCombustion then
        internalCombustion = true
    end
    
    if talents.hasAgonizingCorruption then
        agonizingCorruption = true
    end
    
    if talents.hasWritheInAgony then
        writheInAgony = true
    end
    
    if talents.hasAbsoluteCorruption then
        absoluteCorruption = true
    end
    
    if talents.hasWarlockMisery then
        warlockMisery = true
    end
    
    if talents.hasSoulTrauma then
        soulTrauma = true
    end
    
    if talents.hasInfusedMalice then
        infusedMalice = true
    end
    
    API.PrintDebug("Affliction Warlock talents updated")
    
    return true
end

-- Update soul shard tracking
function Affliction:UpdateSoulShards()
    currentSoulShards = API.GetPlayerSoulShards() or 0
    return true
end

-- Update mana tracking
function Affliction:UpdateMana()
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    return true
end

-- Update health tracking
function Affliction:UpdateHealth()
    local previousHealth = playerHealthPercent
    playerHealthPercent = API.GetPlayerHealthPercent()
    playerHealthPercentDecrease = previousHealth - playerHealthPercent
    return true
end

-- Update pet status
function Affliction:UpdatePetStatus()
    petActive = API.HasActivePet()
    return true
end

-- Update target data
function Affliction:UpdateTargetData()
    -- Check if in range for Agony (safest DOT to check range with)
    inRangeAgony = API.IsSpellInRange(spells.AGONY, "target")
    
    -- Update tracking tables for the current target
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check Agony
        local agonyInfo = API.GetDebuffInfo(targetGUID, debuffs.AGONY)
        if agonyInfo then
            agonyActive[targetGUID] = true
            agonyEndTime[targetGUID] = select(6, agonyInfo)
        else
            agonyActive[targetGUID] = false
            agonyEndTime[targetGUID] = 0
        end
        
        -- Check Corruption
        local corruptionInfo = API.GetDebuffInfo(targetGUID, debuffs.CORRUPTION)
        if corruptionInfo then
            corruptionActive[targetGUID] = true
            corruptionEndTime[targetGUID] = select(6, corruptionInfo)
        else
            corruptionActive[targetGUID] = false
            corruptionEndTime[targetGUID] = 0
        end
        
        -- Check Unstable Affliction
        local uaInfo = API.GetDebuffInfo(targetGUID, debuffs.UNSTABLE_AFFLICTION)
        if uaInfo then
            unstableAfflictionActive[targetGUID] = true
            unstableAfflictionStacks[targetGUID] = select(4, uaInfo) or 1
            unstableAfflictionEndTime[targetGUID] = select(6, uaInfo)
        else
            unstableAfflictionActive[targetGUID] = false
            unstableAfflictionStacks[targetGUID] = 0
            unstableAfflictionEndTime[targetGUID] = 0
        end
        
        -- Check Siphon Life
        if siphonLife then
            local slInfo = API.GetDebuffInfo(targetGUID, debuffs.SIPHON_LIFE)
            if slInfo then
                siphonLifeActive[targetGUID] = true
                siphonLifeEndTime[targetGUID] = select(6, slInfo)
            else
                siphonLifeActive[targetGUID] = false
                siphonLifeEndTime[targetGUID] = 0
            end
        end
        
        -- Check Shadow Embrace
        if talents.hasShadowEmbrace then
            local shadowEmbraceInfo = API.GetDebuffInfo(targetGUID, debuffs.SHADOW_EMBRACE)
            if shadowEmbraceInfo then
                shadowEmbracActive[targetGUID] = true
                shadowEmbracStacks[targetGUID] = select(4, shadowEmbraceInfo) or 1
                shadowEmbracEndTime[targetGUID] = select(6, shadowEmbraceInfo)
            else
                shadowEmbracActive[targetGUID] = false
                shadowEmbracStacks[targetGUID] = 0
                shadowEmbracEndTime[targetGUID] = 0
            end
        end
        
        -- Check Haunt
        if talents.hasHaunt then
            local hauntInfo = API.GetDebuffInfo(targetGUID, debuffs.HAUNT)
            if hauntInfo then
                hauntActive = true
                hauntEndTime = select(6, hauntInfo)
            else
                hauntActive = false
                hauntEndTime = 0
            end
        end
        
        -- Check Seed of Corruption
        if talents.hasSeedOfCorruption then
            local seedInfo = API.GetDebuffInfo(targetGUID, debuffs.SEED_OF_CORRUPTION)
            if seedInfo then
                seedOfCorruptionActive[targetGUID] = true
                seedOfCorruptionEndTime[targetGUID] = select(6, seedInfo)
            else
                seedOfCorruptionActive[targetGUID] = false
                seedOfCorruptionEndTime[targetGUID] = 0
            end
        end
        
        -- Check Phantom Singularity
        if talents.hasPhantomSingularity then
            local psInfo = API.GetDebuffInfo(targetGUID, debuffs.PHANTOM_SINGULARITY)
            if psInfo then
                phantomSingularityActive = true
                phantomSingularityEndTime = select(6, psInfo)
            else
                phantomSingularityActive = false
                phantomSingularityEndTime = 0
            end
        end
        
        -- Check Soul Rot
        if talents.hasSoulRot then
            local srInfo = API.GetDebuffInfo(targetGUID, debuffs.SOUL_ROT)
            if srInfo then
                soulRotActive = true
                soulRotEndTime = select(6, srInfo)
            else
                soulRotActive = false
                soulRotEndTime = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Common AoE radius for warlocks
    
    return true
end

-- Get DoT count on current target
function Affliction:GetDotCount(targetGUID)
    if not targetGUID then
        targetGUID = API.GetTargetGUID()
    end
    
    if not targetGUID or targetGUID == "" then
        return 0
    end
    
    local count = 0
    
    if agonyActive[targetGUID] then
        count = count + 1
    end
    
    if corruptionActive[targetGUID] then
        count = count + 1
    end
    
    if unstableAfflictionActive[targetGUID] then
        count = count + 1
    end
    
    if siphonLife and siphonLifeActive[targetGUID] then
        count = count + 1
    end
    
    if seedOfCorruption and seedOfCorruptionActive[targetGUID] then
        count = count + 1
    end
    
    return count
end

-- Handle combat log events
function Affliction:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Dark Soul: Misery
            if spellID == buffs.DARK_SOUL_MISERY then
                darkSoulMiseryActive = true
                darkSoulMiseryEndTime = GetTime() + DARK_SOUL_MISERY_DURATION
                API.PrintDebug("Dark Soul: Misery activated")
            end
            
            -- Track Nightfall proc
            if spellID == buffs.NIGHTFALL then
                shadowBoltNightFall = true
                API.PrintDebug("Nightfall proc activated")
            end
            
            -- Track Inevitable Demise
            if spellID == buffs.INEVITABLE_DEMISE then
                inevitableDemiseActive = true
                inevitableDemiseStacks = select(4, API.GetBuffInfo("player", buffs.INEVITABLE_DEMISE)) or 1
                inevitableDemiseEndTime = select(6, API.GetBuffInfo("player", buffs.INEVITABLE_DEMISE))
                API.PrintDebug("Inevitable Demise activated: " .. tostring(inevitableDemiseStacks) .. " stacks")
            end
            
            -- Track Malefic Rapture buff
            if spellID == buffs.MALEFIC_RAPTURE then
                maleficRaptureBuffActive = true
                maleficRaptureBuffStacks = select(4, API.GetBuffInfo("player", buffs.MALEFIC_RAPTURE)) or 1
                maleficRaptureBuffEndTime = select(6, API.GetBuffInfo("player", buffs.MALEFIC_RAPTURE))
                API.PrintDebug("Malefic Rapture buff activated: " .. tostring(maleficRaptureBuffStacks) .. " stacks")
            end
            
            -- Track Grimoire of Sacrifice
            if spellID == buffs.GRIMOIRE_OF_SACRIFICE then
                grimOfSacCDStacks = select(4, API.GetBuffInfo("player", buffs.GRIMOIRE_OF_SACRIFICE)) or 1
                API.PrintDebug("Grimoire of Sacrifice activated: " .. tostring(grimOfSacCDStacks) .. " stacks")
            end
            
            -- Track Soulmelt
            if spellID == spells.SOULMELT then
                soulmeltStacks = select(4, API.GetBuffInfo("player", spells.SOULMELT)) or 1
                API.PrintDebug("Soulmelt stacks: " .. tostring(soulmeltStacks))
            end
            
            -- Track Sigil of Flame
            if spellID == spells.SIGIL_OF_FLAME then
                sigilOfFlameStacks = select(4, API.GetBuffInfo("player", spells.SIGIL_OF_FLAME)) or 1
                API.PrintDebug("Sigil of Flame stacks: " .. tostring(sigilOfFlameStacks))
            end
            
            -- Track Dread Touch
            if spellID == spells.DREAD_TOUCH then
                dreadTouchStacks = select(4, API.GetBuffInfo("player", spells.DREAD_TOUCH)) or 1
                API.PrintDebug("Dread Touch stacks: " .. tostring(dreadTouchStacks))
            end
            
            -- Track Doom Brand (personal buff, not a debuff)
            if spellID == spells.DOOM_BRAND then
                doomBrand = true
                doomBrandEndTime = select(6, API.GetBuffInfo("player", spells.DOOM_BRAND))
                API.PrintDebug("Doom Brand activated")
            end
        end
        
        -- Track target/destination specific debuffs
        if API.GetTargetGUID() == destGUID then
            -- Don't track the DoTs here, use UpdateTargetData instead
            -- That function gets triggered after target changes and it would duplicate the logic
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Dark Soul: Misery
            if spellID == buffs.DARK_SOUL_MISERY then
                darkSoulMiseryActive = false
                API.PrintDebug("Dark Soul: Misery faded")
            end
            
            -- Track Nightfall proc
            if spellID == buffs.NIGHTFALL then
                shadowBoltNightFall = false
                API.PrintDebug("Nightfall proc consumed")
            end
            
            -- Track Inevitable Demise
            if spellID == buffs.INEVITABLE_DEMISE then
                inevitableDemiseActive = false
                inevitableDemiseStacks = 0
                API.PrintDebug("Inevitable Demise faded")
            end
            
            -- Track Malefic Rapture buff
            if spellID == buffs.MALEFIC_RAPTURE then
                maleficRaptureBuffActive = false
                maleficRaptureBuffStacks = 0
                API.PrintDebug("Malefic Rapture buff faded")
            end
            
            -- Track Doom Brand
            if spellID == spells.DOOM_BRAND then
                doomBrand = false
                API.PrintDebug("Doom Brand faded")
            end
        end
    end
    
    -- Track Drain Life, Malefic Rapture, Agony, Unstable Affliction, Seed of Corruption, etc.
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.DRAIN_SOUL then
                API.PrintDebug("Drain Soul cast")
            elseif spellID == spells.MALEFIC_RAPTURE then
                API.PrintDebug("Malefic Rapture cast")
            elseif spellID == spells.DARK_SOUL_MISERY then
                darkSoulMiseryActive = true
                darkSoulMiseryEndTime = GetTime() + DARK_SOUL_MISERY_DURATION
                API.PrintDebug("Dark Soul: Misery cast")
            elseif spellID == spells.SUMMON_DARKGLARE then
                summonDarkglareActive = true
                summonDarkglareEndTime = GetTime() + SUMMON_DARKGLARE_DURATION
                API.PrintDebug("Summon Darkglare cast")
            elseif spellID == spells.PHANTOM_SINGULARITY then
                phantomSingularityActive = true
                phantomSingularityEndTime = GetTime() + PHANTOM_SINGULARITY_DURATION
                API.PrintDebug("Phantom Singularity cast")
            elseif spellID == spells.VILE_TRANCE then
                vileTranceCDActive = true
                vileTranceCDEndTime = GetTime() + API.GetSpellCooldown(spells.VILE_TRANCE)
                API.PrintDebug("Vile Trance cast")
            elseif spellID == spells.HAUNT then
                hauntActive = true
                hauntEndTime = GetTime() + HAUNT_DURATION
                API.PrintDebug("Haunt cast")
            elseif spellID == spells.AGONY then
                -- Update target data will handle buff tracking
                API.PrintDebug("Agony cast on " .. destName)
            elseif spellID == spells.SOUL_ROT then
                soulRotActive = true
                soulRotEndTime = GetTime() + SOUL_ROT_DURATION
                API.PrintDebug("Soul Rot cast")
            end
        end
    end
    
    -- Track Inevitable Demise stack gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.INEVITABLE_DEMISE and destGUID == API.GetPlayerGUID() then
        inevitableDemiseStacks = select(4, API.GetBuffInfo("player", buffs.INEVITABLE_DEMISE)) or 0
        API.PrintDebug("Inevitable Demise stacks: " .. tostring(inevitableDemiseStacks))
    end
    
    -- Track Malefic Rapture buff stack gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.MALEFIC_RAPTURE and destGUID == API.GetPlayerGUID() then
        maleficRaptureBuffStacks = select(4, API.GetBuffInfo("player", buffs.MALEFIC_RAPTURE)) or 0
        API.PrintDebug("Malefic Rapture buff stacks: " .. tostring(maleficRaptureBuffStacks))
    end
    
    -- Track Shadow Embrace stack gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == debuffs.SHADOW_EMBRACE then
        if shadowEmbracActive[destGUID] then
            shadowEmbracStacks[destGUID] = select(4, API.GetDebuffInfo(destGUID, debuffs.SHADOW_EMBRACE)) or 0
            API.PrintDebug("Shadow Embrace stacks on " .. destName .. ": " .. tostring(shadowEmbracStacks[destGUID]))
        end
    end
    
    -- Track Unstable Affliction stack gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == debuffs.UNSTABLE_AFFLICTION then
        if unstableAfflictionActive[destGUID] then
            unstableAfflictionStacks[destGUID] = select(4, API.GetDebuffInfo(destGUID, debuffs.UNSTABLE_AFFLICTION)) or 0
            API.PrintDebug("Unstable Affliction stacks on " .. destName .. ": " .. tostring(unstableAfflictionStacks[destGUID]))
        end
    end
    
    -- Track Seed of Corruption explosion
    if eventType == "SPELL_DAMAGE" and spellID == spells.SEED_OF_CORRUPTION and sourceGUID == API.GetPlayerGUID() then
        seedOfCorruptionExploding = true
        
        -- Reset after a short delay
        C_Timer.After(0.5, function()
            seedOfCorruptionExploding = false
        end)
        
        API.PrintDebug("Seed of Corruption exploded on " .. destName)
    end
    
    return true
end

-- Main rotation function
function Affliction:RunRotation()
    -- Check if we should be running Affliction Warlock logic
    if API.GetActiveSpecID() ~= AFFLICTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("AfflictionWarlock")
    
    -- Update variables
    self:UpdateSoulShards()
    self:UpdateMana()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Create a healthstone if don't have one
    if settings.defensiveSettings.useHealthstone and 
       not API.HasHealthstone() and
       API.CanCast(spells.CREATE_HEALTHSTONE) then
        API.CastSpell(spells.CREATE_HEALTHSTONE)
        return true
    end
    
    -- Check if we need to summon a pet
    if settings.rotationSettings.usePetActive and not petActive and 
       not API.PlayerHasBuff(buffs.GRIMOIRE_OF_SACRIFICE) then
        local petSpell = spells.SUMMON_IMP -- default
        
        if settings.rotationSettings.preferredPet == "Felhunter" then
            petSpell = spells.SUMMON_FELHUNTER
        elseif settings.rotationSettings.preferredPet == "Succubus" then
            petSpell = spells.SUMMON_SUCCUBUS
        elseif settings.rotationSettings.preferredPet == "Voidwalker" then
            petSpell = spells.SUMMON_VOIDWALKER
        elseif settings.rotationSettings.preferredPet == "Felguard" and API.CanCast(spells.SUMMON_FELGUARD) then
            petSpell = spells.SUMMON_FELGUARD
        end
        
        if API.CanCast(petSpell) then
            API.CastSpell(petSpell)
            return true
        end
    end
    
    -- Use Grimoire of Sacrifice if enabled and we have a pet
    if talents.hasGrimoireOfSacrifice and 
       not settings.rotationSettings.usePetActive and 
       petActive and 
       not API.PlayerHasBuff(buffs.GRIMOIRE_OF_SACRIFICE) and
       API.CanCast(spells.GRIMOIRE_OF_SACRIFICE) then
        API.CastSpell(spells.GRIMOIRE_OF_SACRIFICE)
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Skip if not in range
    if not inRangeAgony then
        return false
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Affliction:HandleInterrupts()
    -- Only attempt to interrupt if pet is available or we are using Grimoire of Sacrifice
    if petActive and API.CanCast(spells.COMMAND_DEMON) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.COMMAND_DEMON)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Affliction:HandleDefensives(settings)
    -- Use Unending Resolve
    if unendingResolve and
       settings.defensiveSettings.useUnendingResolve and
       playerHealthPercent <= settings.defensiveSettings.unendingResolveThreshold and
       API.CanCast(spells.UNENDING_RESOLVE) then
        API.CastSpell(spells.UNENDING_RESOLVE)
        return true
    end
    
    -- Use Dark Pact
    if darkPact and
       settings.defensiveSettings.useDarkPact and
       playerHealthPercent <= settings.defensiveSettings.darkPactThreshold and
       API.CanCast(spells.DARK_PACT) then
        API.CastSpell(spells.DARK_PACT)
        return true
    end
    
    -- Use Healthstone
    if settings.defensiveSettings.useHealthstone and
       playerHealthPercent <= settings.defensiveSettings.healthstoneThreshold and
       API.HasHealthstone() and
       API.CanUseItem(spells.HEALTHSTONE) then
        API.UseItem(spells.HEALTHSTONE)
        return true
    end
    
    -- Use Drain Life
    if drainLife and
       settings.defensiveSettings.useDrainLife and
       playerHealthPercent <= settings.defensiveSettings.drainLifeThreshold and
       API.CanCast(spells.DRAIN_LIFE) then
        API.CastSpell(spells.DRAIN_LIFE)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Affliction:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if not targetGUID or targetGUID == "" then
        return false
    end
    
    -- Calculate current DoT count
    local dotCount = self:GetDotCount(targetGUID)
    
    -- Use Dark Soul: Misery
    if darkSoul and
       settings.cooldownSettings.useDarkSoul and
       settings.abilityControls.darkSoulMisery.enabled and
       not darkSoulMiseryActive and
       API.CanCast(spells.DARK_SOUL_MISERY) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.darkSoulMisery.useDuringBurstOnly or burstModeActive then
            -- Check if requires Darkglare
            if not settings.abilityControls.darkSoulMisery.requireDarkglare or summonDarkglareActive then
                -- Check DoT requirements
                if dotCount >= settings.abilityControls.darkSoulMisery.minDotsOnTarget then
                    API.CastSpell(spells.DARK_SOUL_MISERY)
                    return true
                end
            end
        end
    end
    
    -- Use Summon Darkglare
    if summonDarkglare and
       settings.cooldownSettings.useDarkglare and
       settings.abilityControls.summonDarkglare.enabled and
       not summonDarkglareActive and
       API.CanCast(spells.SUMMON_DARKGLARE) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.summonDarkglare.useDuringBurstOnly or burstModeActive then
            -- Check if requires Dark Soul
            if not settings.abilityControls.summonDarkglare.requireDarkSoul or darkSoulMiseryActive then
                -- Check DoT requirements
                if dotCount >= settings.abilityControls.summonDarkglare.minDotsOnTarget then
                    API.CastSpell(spells.SUMMON_DARKGLARE)
                    return true
                end
            end
        end
    end
    
    -- Use Phantom Singularity
    if phantomSingularity and
       settings.cooldownSettings.usePhantomSingularity and
       settings.abilityControls.phantomSingularity.enabled and
       not phantomSingularityActive and
       API.CanCast(spells.PHANTOM_SINGULARITY) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.phantomSingularity.useDuringBurstOnly or burstModeActive then
            -- Check if requires Darkglare
            if not settings.abilityControls.phantomSingularity.useOnlyWithDarkglare or summonDarkglareActive then
                -- Check target count requirements
                if currentAoETargets >= settings.abilityControls.phantomSingularity.minTargets then
                    API.CastSpell(spells.PHANTOM_SINGULARITY)
                    return true
                end
            end
        end
    end
    
    -- Use Vile Trance
    if vileTranceCooldown and
       settings.cooldownSettings.useVileTrance and
       not vileTranceCDActive and
       API.CanCast(spells.VILE_TRANCE) then
        API.CastSpell(spells.VILE_TRANCE)
        return true
    end
    
    -- Use Soul Rot
    if talents.hasSoulRot and
       settings.cooldownSettings.useSoulRot and
       not soulRotActive and
       API.CanCast(spells.SOUL_ROT) and
       currentAoETargets >= settings.cooldownSettings.soulRotMinTargets then
        API.CastSpell(spells.SOUL_ROT)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Affliction:HandleAoERotation(settings)
    -- Use Seed of Corruption as main AoE spell
    if seedOfCorruption and
       currentAoETargets >= settings.spellSettings.seedMinTargets and
       currentSoulShards > 0 and
       API.CanCast(spells.SEED_OF_CORRUPTION) then
        
        -- Check if we should apply to the current target
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and (not seedOfCorruptionActive[targetGUID] or 
                         (seedOfCorruptionActive[targetGUID] and 
                          seedOfCorruptionEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) then
            API.CastSpell(spells.SEED_OF_CORRUPTION)
            return true
        end
    end
    
    -- Maintain Agony on multiple targets
    if agony and API.CanCast(spells.AGONY) then
        local dotTargetCount = 0
        local targetGUID = API.GetTargetGUID()
        
        -- Apply Agony to current target if needed
        if targetGUID and (not agonyActive[targetGUID] or 
                          (agonyActive[targetGUID] and 
                           agonyEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) then
            API.CastSpell(spells.AGONY)
            return true
        end
        
        -- Try to find additional targets for Agony
        local enemies = API.GetEnemiesInRange(DOT_RANGE)
        for _, enemy in ipairs(enemies) do
            local enemyGUID = API.UnitGUID(enemy)
            
            if not agonyActive[enemyGUID] and dotTargetCount < MAX_TARGETS_TRACKED then
                API.CastSpellOnUnit(spells.AGONY, enemy)
                dotTargetCount = dotTargetCount + 1
                return true
            end
        end
    end
    
    -- Use Malefic Rapture for AoE damage if we have enough Soul Shards
    if maleficRapture and
       currentSoulShards >= settings.spellSettings.maleficRaptureMinShards and
       API.CanCast(spells.MALEFIC_RAPTURE) then
        -- For AoE we can use more liberally
        local shardCountToUse = math.min(currentSoulShards, settings.spellSettings.maleficRaptureMaxShards)
        
        if shardCountToUse >= settings.spellSettings.maleficRaptureMinShards then
            API.CastSpell(spells.MALEFIC_RAPTURE)
            return true
        end
    end
    
    -- Apply or refresh Corruption on multiple targets if not using Seed for spread
    if corruption and 
       API.CanCast(spells.CORRUPTION) and
       currentAoETargets < settings.spellSettings.seedMinTargets then
        
        local dotTargetCount = 0
        local targetGUID = API.GetTargetGUID()
        
        -- Apply Corruption to current target if needed
        if targetGUID and (not corruptionActive[targetGUID] or 
                          (corruptionActive[targetGUID] and 
                           corruptionEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) then
            API.CastSpell(spells.CORRUPTION)
            return true
        end
        
        -- Try to find additional targets for Corruption
        local enemies = API.GetEnemiesInRange(DOT_RANGE)
        for _, enemy in ipairs(enemies) do
            local enemyGUID = API.UnitGUID(enemy)
            
            if not corruptionActive[enemyGUID] and dotTargetCount < MAX_TARGETS_TRACKED then
                API.CastSpellOnUnit(spells.CORRUPTION, enemy)
                dotTargetCount = dotTargetCount + 1
                return true
            end
        end
    end
    
    -- Apply Unstable Affliction to main target
    if unstableAffliction and
       settings.spellSettings.useUnstableAffliction and
       API.CanCast(spells.UNSTABLE_AFFLICTION) then
        
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and (not unstableAfflictionActive[targetGUID] or 
                          (unstableAfflictionActive[targetGUID] and 
                           unstableAfflictionEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) then
            API.CastSpell(spells.UNSTABLE_AFFLICTION)
            return true
        end
    end
    
    -- Apply Siphon Life to main target only in AoE (to conserve GCDs)
    if siphonLife and
       settings.spellSettings.useSiphonLife and
       API.CanCast(spells.SIPHON_LIFE) then
        
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and (not siphonLifeActive[targetGUID] or 
                          (siphonLifeActive[targetGUID] and 
                           siphonLifeEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) then
            API.CastSpell(spells.SIPHON_LIFE)
            return true
        end
    end
    
    -- Use Haunt for AoE damage boost
    if talents.hasHaunt and
       settings.spellSettings.useHaunt and
       not hauntActive and
       currentSoulShards > 0 and
       API.CanCast(spells.HAUNT) then
        API.CastSpell(spells.HAUNT)
        return true
    end
    
    -- Use Drain Soul filler to generate shards
    if settings.rotationSettings.fillWithDrainSoul and
       currentSoulShards < settings.rotationSettings.soulShardLimit and
       API.CanCast(spells.DRAIN_SOUL) then
        API.CastSpell(spells.DRAIN_SOUL)
        return true
    end
    
    -- Use Shadow Bolt filler if not using Drain Soul
    if not settings.rotationSettings.fillWithDrainSoul and
       currentSoulShards < settings.rotationSettings.soulShardLimit and
       API.CanCast(spells.SHADOW_BOLT) then
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Affliction:HandleSingleTargetRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if not targetGUID or targetGUID == "" then
        return false
    end
    
    -- Get DoT priority order from settings
    local dotOrder = {}
    if settings.spellSettings.priorityDotOrder == "Agony > Corruption > UA > SL" then
        dotOrder = {spells.AGONY, spells.CORRUPTION, spells.UNSTABLE_AFFLICTION, spells.SIPHON_LIFE}
    elseif settings.spellSettings.priorityDotOrder == "Agony > UA > Corruption > SL" then
        dotOrder = {spells.AGONY, spells.UNSTABLE_AFFLICTION, spells.CORRUPTION, spells.SIPHON_LIFE}
    elseif settings.spellSettings.priorityDotOrder == "UA > Agony > Corruption > SL" then
        dotOrder = {spells.UNSTABLE_AFFLICTION, spells.AGONY, spells.CORRUPTION, spells.SIPHON_LIFE}
    elseif settings.spellSettings.priorityDotOrder == "UA > Agony > SL > Corruption" then
        dotOrder = {spells.UNSTABLE_AFFLICTION, spells.AGONY, spells.SIPHON_LIFE, spells.CORRUPTION}
    end
    
    -- Apply DoTs in the priority order
    for _, dotSpell in ipairs(dotOrder) do
        -- Agony
        if dotSpell == spells.AGONY and
           agony and
           (not agonyActive[targetGUID] or
            (agonyActive[targetGUID] and
             agonyEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) and
           API.CanCast(spells.AGONY) then
            API.CastSpell(spells.AGONY)
            return true
        end
        
        -- Corruption
        if dotSpell == spells.CORRUPTION and
           corruption and
           (not corruptionActive[targetGUID] or
            (corruptionActive[targetGUID] and
             corruptionEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) and
           API.CanCast(spells.CORRUPTION) then
            API.CastSpell(spells.CORRUPTION)
            return true
        end
        
        -- Unstable Affliction
        if dotSpell == spells.UNSTABLE_AFFLICTION and
           unstableAffliction and
           settings.spellSettings.useUnstableAffliction and
           (not unstableAfflictionActive[targetGUID] or
            (unstableAfflictionActive[targetGUID] and
             unstableAfflictionEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) and
           API.CanCast(spells.UNSTABLE_AFFLICTION) then
            API.CastSpell(spells.UNSTABLE_AFFLICTION)
            return true
        end
        
        -- Siphon Life
        if dotSpell == spells.SIPHON_LIFE and
           siphonLife and
           settings.spellSettings.useSiphonLife and
           (not siphonLifeActive[targetGUID] or
            (siphonLifeActive[targetGUID] and
             siphonLifeEndTime[targetGUID] - GetTime() < settings.rotationSettings.dotRefreshThreshold)) and
           API.CanCast(spells.SIPHON_LIFE) then
            API.CastSpell(spells.SIPHON_LIFE)
            return true
        end
    end
    
    -- Use Haunt
    if talents.hasHaunt and
       settings.spellSettings.useHaunt and
       not hauntActive and
       currentSoulShards > 0 and
       API.CanCast(spells.HAUNT) then
        API.CastSpell(spells.HAUNT)
        return true
    end
    
    -- Use Malefic Rapture for damage if all DoTs are up
    if maleficRapture and
       self:GetDotCount(targetGUID) >= 3 and
       currentSoulShards >= settings.spellSettings.maleficRaptureMinShards and
       API.CanCast(spells.MALEFIC_RAPTURE) then
        
        -- Decide how many shards to use based on settings and available shards
        local shardCountToUse = math.min(currentSoulShards, settings.spellSettings.maleficRaptureMaxShards)
        
        if shardCountToUse >= settings.spellSettings.maleficRaptureMinShards then
            API.CastSpell(spells.MALEFIC_RAPTURE)
            return true
        end
    end
    
    -- Use Shadowburn if talented
    if talents.hasShadowburn and
       currentSoulShards > 0 and
       API.GetTargetHealthPercent() <= 20 and
       API.CanCast(spells.SHADOWBURN) then
        API.CastSpell(spells.SHADOWBURN)
        return true
    end
    
    -- Use Drain Soul filler
    if settings.rotationSettings.fillWithDrainSoul and
       API.CanCast(spells.DRAIN_SOUL) then
        API.CastSpell(spells.DRAIN_SOUL)
        return true
    end
    
    -- Use Shadow Bolt with Nightfall proc
    if shadowBoltNightFall and
       API.CanCast(spells.SHADOW_BOLT) then
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    -- Use Shadow Bolt filler if not using Drain Soul
    if not settings.rotationSettings.fillWithDrainSoul and
       API.CanCast(spells.SHADOW_BOLT) then
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    return false
end

-- Handle specialization change
function Affliction:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentSoulShards = 0
    maxSoulShards = 5
    darkSoulMiseryActive = false
    darkSoulMiseryEndTime = 0
    summonDarkglareActive = false
    summonDarkglareEndTime = 0
    phantomSingularityActive = false
    phantomSingularityEndTime = 0
    vileTranceCDActive = false
    vileTranceCDEndTime = 0
    shadowBoltNightFall = false
    hauntActive = false
    hauntEndTime = 0
    seedOfCorruptionExploding = false
    agonyActive = {}
    agonyEndTime = {}
    corruptionActive = {}
    corruptionEndTime = {}
    siphonLifeActive = {}
    siphonLifeEndTime = {}
    unstableAfflictionActive = {}
    unstableAfflictionStacks = {}
    unstableAfflictionEndTime = {}
    maleficRaptureBuffActive = false
    maleficRaptureBuffEndTime = 0
    maleficRaptureBuffStacks = 0
    shadowEmbracActive = {}
    shadowEmbracStacks = {}
    shadowEmbracEndTime = {}
    soulRotActive = false
    soulRotEndTime = 0
    dreadstalkers = false
    dreadstalkerEndTime = 0
    felguardAxeToss = false
    grimOfSacCDStacks = 0
    seedOfCorruptionActive = {}
    seedOfCorruptionEndTime = {}
    playerHealthPercent = 100
    playerHealthPercentDecrease = 0
    inevitableDemiseActive = false
    inevitableDemiseStacks = 0
    inevitableDemiseEndTime = 0
    darkSoul = false
    felStorm = false
    felStormActive = false
    felStormEndTime = 0
    felDomination = false
    absInProgress = false
    absEndTime = 0
    doomBrand = false
    doomBrandEndTime = 0
    petActive = false
    currentMana = 0
    maxMana = 100
    inRangeAgony = false
    unendingResolve = false
    healthstone = false
    drainLife = false
    darkcycle = false
    shadowburn = false
    soulBurn = false
    soulTap = false
    grimOfSacrifice = false
    creepingDeath = false
    sacSouls = false
    agony = false
    corruption = false
    unstableAffliction = false
    seedOfCorruption = false
    maleficRapture = false
    siphonLife = false
    phantomSingularity = false
    vileTranceCooldown = false
    summonDarkglare = false
    amplifyCurse = false
    mortalCoil = false
    curseOfExhaustion = false
    curseOfTongues = false
    curseOfWeakness = false
    darkPact = false
    demonSkin = false
    soulLeech = false
    shadowfury = false
    demonicStrength = false
    howlOfTerror = false
    shadowFlame = false
    exhaustion = false
    internalCombustion = false
    agonizingCorruption = false
    writheInAgony = false
    absoluteCorruption = false
    soulmeltStacks = 0
    sigilOfFlameStacks = 0
    warlockMisery = false
    soulTrauma = false
    dreadTouchStacks = 0
    infectedAspect = false
    infusedMalice = false
    
    petActive = API.HasActivePet()
    
    API.PrintDebug("Affliction Warlock state reset on spec change")
    
    return true
end

-- Return the module for loading
return Affliction