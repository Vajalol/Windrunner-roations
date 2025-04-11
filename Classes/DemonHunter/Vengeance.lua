------------------------------------------
-- WindrunnerRotations - Vengeance Demon Hunter Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Vengeance = {}
-- This will be assigned to addon.Classes.DemonHunter.Vengeance when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local DemonHunter

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentFury = 0
local maxFury = 120
local fieryBrandActive = false
local fieryBrandEndTime = 0
local fieryBrandTargets = {}
local metamorphosisActive = false
local metamorphosisEndTime = 0
local demonSpikeCharges = 0
local demonSpikeMaxCharges = 0
local demonSpikeActive = false
local demonSpikeEndTime = 0
local immoAuraActive = false
local immoAuraEndTime = 0
local soulFragments = 0
local maxSoulFragments = 5
local felDevastation = false
local felDevastationEndTime = 0
local soulBarrierActive = false
local soulBarrierEndTime = 0
local spiritBombActive = false
local spiritBombEndTime = 0
local bulkExtraction = false
local bulkExtractionCooldown = 0
local frailtyActive = false
local frailtyEndTime = 0
local frailtyStacks = 0
local felFissureCount = 0
local sigil1Active = false
local sigil2Active = false
local sigil3Active = false
local sigilOfFlameActive = false
local sigilOfChainsCooldown = 0
local sigilOfChainsCharges = 0
local sigilOfSilenceCooldown = 0
local sigilOfMiseryCooldown = 0
local charredFleshActive = false
local roaringFireActive = false
local calcifiedSpikes = false
local voidReaver = false
local fieryDemise = false
local focusedCleave = false
local painBringer = false
local felblade = false
local fodderToTheFlame = false
local inSigil = false
local siegebreaker = false
local shearFury = false
local shearFuryEndTime = 0
local frenziedUptime = false
local livelihoodOfFlame = false
local inMeleeRange = false
local soulFragBuffActive = false
local burnOutActive = false
local burnOutStacks = 0
local reverseRapture = false

-- Constants
local VENGEANCE_SPEC_ID = 581
local DEFAULT_AOE_THRESHOLD = 3
local FIERY_BRAND_DURATION = 10 -- seconds
local METAMORPHOSIS_DURATION = 15 -- seconds
local DEMON_SPIKE_DURATION = 8 -- seconds
local IMMOLATION_AURA_DURATION = 6 -- seconds
local SOUL_BARRIER_DURATION = 12 -- seconds
local FRAILTY_DURATION = 6 -- seconds
local FEL_DEVASTATION_DURATION = 2 -- seconds
local MELEE_RANGE = 5 -- yards
local SIGIL_RANGE = 30 -- yards
local SPIRIT_BOMB_DURATION = 6 -- seconds

-- Initialize the Vengeance module
function Vengeance:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Vengeance Demon Hunter module initialized")
    
    return true
end

-- Register spell IDs
function Vengeance:RegisterSpells()
    -- Core rotational abilities
    spells.SHEAR = 203782
    spells.FRACTURE = 263642
    spells.SOUL_CLEAVE = 228477
    spells.IMMOLATION_AURA = 258920
    spells.SIGIL_OF_FLAME = 204596
    spells.SPIRIT_BOMB = 247454
    spells.FEL_DEVASTATION = 212084
    spells.THROW_GLAIVE = 204157
    spells.FELBLADE = 232893
    spells.INFERNAL_STRIKE = 189110
    
    -- Core defensives
    spells.DEMON_SPIKES = 203720
    spells.FIERY_BRAND = 204021
    spells.SOUL_BARRIER = 263648
    spells.METAMORPHOSIS = 187827
    
    -- Core utilities
    spells.CONSUME_MAGIC = 278326
    spells.DISRUPT = 183752
    spells.SIGIL_OF_SILENCE = 202137
    spells.SIGIL_OF_CHAINS = 202138
    spells.SIGIL_OF_MISERY = 207684
    spells.TORMENT = 185245
    spells.IMPRISON = 217832
    spells.SPECTRAL_SIGHT = 188501
    spells.FEL_ERUPTION = 211881
    spells.VENGEFUL_RETREAT = 198793
    spells.THROW_GLAIVE = 185123
    
    -- Talents and passives
    spells.BULK_EXTRACTION = 320341
    spells.VOID_REAVER = 268175
    spells.FEAST_OF_SOULS = 207697
    spells.FALLOUT = 227174
    spells.BURNING_ALIVE = 207739
    spells.INFERNAL_ARMOR = 320331
    spells.CHARRED_FLESH = 336639
    spells.ROARING_FIRE = 391178
    spells.CALCIFIED_SPIKES = 389972
    spells.FIERY_DEMISE = 389220
    spells.FOCUSED_CLEAVE = 343207
    spells.PAIN_BRINGER = 207387
    spells.CONCENTRATED_SIGILS = 207666
    spells.QUICKENED_SIGILS = 209281
    spells.SIGIL_OF_CHAINS = 202138
    spells.ABYSSAL_STRIKE = 207550
    spells.AGONIZING_FLAMES = 207548
    spells.FEL_DEFENDER = 205493
    spells.SOUL_CARVER = 207407
    spells.DEMONIC = 213410
    spells.SOUL_RENDING = 217996
    spells.FEED_THE_DEMON = 218612
    spells.FRACTURE = 263642
    spells.FELBLADE = 232893
    spells.FIRST_OF_THE_ILLIDARI = 235893
    spells.SPIRITBOMB = 247454
    spells.REVEL_IN_PAIN = 343014
    spells.FODDER_TO_THE_FLAME = 391430
    spells.CYCLE_OF_BINDING = 389718
    spells.SIGIL_OF_MISERY = 207684
    spells.CHAINS_OF_ANGER = 389695
    spells.UNENDING_HATRED = 389695
    spells.PERFECT_REFRACTION = 389820
    spells.PRECISE_SIGILS = 389799
    spells.DARKGLARE_BOON = 389708
    spells.ILLUMINATED_SIGILS = 428640
    spells.SOUL_FLAME = 391436
    spells.ERRATIC_FELHEART = 391393
    spells.STOKE_THE_FLAMES = 393827
    spells.METEORIC_STRIKE = 389987
    spells.BLIND_FAITH = 389847
    spells.ANY_MEANS_NECESSARY = 391205
    spells.RECRIMINATION = 389789
    spells.FRAILTY = 389958
    spells.SIGILBORN = 389720
    spells.DEMONIC_TRAMPLE = 205629
    spells.WICKED_INSTINCTS = 392799
    
    -- War Within Season 2 specific
    spells.RUINATION = 387167
    spells.DEFLECTING_SPIKES = 321028
    spells.EXTENDED_SPIKES = 411509
    spells.SHEAR_FURY = 375251
    spells.FRENZIED_UPTIME = 389985
    spells.LIVELIHOOD_OF_FLAME = 377258
    spells.BURN_OUT = 389086
    spells.REVERSE_RAPTURE = 389977
    spells.FLAME_CRASH = 227322
    spells.RAZORSPIKES = 407667
    spells.SIEGEBREAKER = 426347
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.ELYSIAN_DECREE = 390163
    spells.THE_HUNT = 370965
    spells.SINFUL_BRAND = 317009
    spells.FODDER_TO_THE_FLAME = 391430
    
    -- Buff IDs
    spells.FIERY_BRAND_BUFF = 207771
    spells.METAMORPHOSIS_BUFF = 187827
    spells.DEMON_SPIKES_BUFF = 203819
    spells.IMMOLATION_AURA_BUFF = 258920
    spells.SOUL_FRAGMENTS_BUFF = 203981
    spells.SOUL_BARRIER_BUFF = 263648
    spells.SPIRIT_BOMB_BUFF = 247454
    spells.FRAILTY_BUFF = 389958
    spells.FEL_DEVASTATION_BUFF = 212084
    spells.CHARRED_FLESH_BUFF = 336640
    spells.ROARING_FIRE_BUFF = 391180
    spells.SHEAR_FURY_BUFF = 375252
    spells.BURN_OUT_BUFF = 389090
    
    -- Debuff IDs
    spells.FIERY_BRAND_DEBUFF = 207771
    spells.SIGIL_OF_FLAME_DEBUFF = 204598
    spells.SIGIL_OF_CHAINS_DEBUFF = 204843
    spells.SIGIL_OF_SILENCE_DEBUFF = 204490
    spells.SIGIL_OF_MISERY_DEBUFF = 207685
    spells.FRAILTY_DEBUFF = 247456
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.FIERY_BRAND = spells.FIERY_BRAND_BUFF
    buffs.METAMORPHOSIS = spells.METAMORPHOSIS_BUFF
    buffs.DEMON_SPIKES = spells.DEMON_SPIKES_BUFF
    buffs.IMMOLATION_AURA = spells.IMMOLATION_AURA_BUFF
    buffs.SOUL_FRAGMENTS = spells.SOUL_FRAGMENTS_BUFF
    buffs.SOUL_BARRIER = spells.SOUL_BARRIER_BUFF
    buffs.SPIRIT_BOMB = spells.SPIRIT_BOMB_BUFF
    buffs.FRAILTY = spells.FRAILTY_BUFF
    buffs.FEL_DEVASTATION = spells.FEL_DEVASTATION_BUFF
    buffs.CHARRED_FLESH = spells.CHARRED_FLESH_BUFF
    buffs.ROARING_FIRE = spells.ROARING_FIRE_BUFF
    buffs.SHEAR_FURY = spells.SHEAR_FURY_BUFF
    buffs.BURN_OUT = spells.BURN_OUT_BUFF
    
    debuffs.FIERY_BRAND = spells.FIERY_BRAND_DEBUFF
    debuffs.SIGIL_OF_FLAME = spells.SIGIL_OF_FLAME_DEBUFF
    debuffs.SIGIL_OF_CHAINS = spells.SIGIL_OF_CHAINS_DEBUFF
    debuffs.SIGIL_OF_SILENCE = spells.SIGIL_OF_SILENCE_DEBUFF
    debuffs.SIGIL_OF_MISERY = spells.SIGIL_OF_MISERY_DEBUFF
    debuffs.FRAILTY = spells.FRAILTY_DEBUFF
    
    return true
end

-- Register variables to track
function Vengeance:RegisterVariables()
    -- Talent tracking
    talents.hasBulkExtraction = false
    talents.hasVoidReaver = false
    talents.hasFeastOfSouls = false
    talents.hasFallout = false
    talents.hasBurningAlive = false
    talents.hasInfernalArmor = false
    talents.hasCharredFlesh = false
    talents.hasRoaringFire = false
    talents.hasCalcifiedSpikes = false
    talents.hasFieryDemise = false
    talents.hasFocusedCleave = false
    talents.hasPainBringer = false
    talents.hasConcentratedSigils = false
    talents.hasQuickenedSigils = false
    talents.hasSigilOfChains = false
    talents.hasAbyssalStrike = false
    talents.hasAgonizingFlames = false
    talents.hasFelDefender = false
    talents.hasSoulCarver = false
    talents.hasDemonic = false
    talents.hasSoulRending = false
    talents.hasFeedTheDemon = false
    talents.hasFracture = false
    talents.hasFelblade = false
    talents.hasFirstOfTheIllidari = false
    talents.hasSpiritBomb = false
    talents.hasRevelInPain = false
    talents.hasFodderToTheFlame = false
    talents.hasCycleOfBinding = false
    talents.hasSigilOfMisery = false
    talents.hasChainsOfAnger = false
    talents.hasUnendingHatred = false
    talents.hasPerfectRefraction = false
    talents.hasPreciseSigils = false
    talents.hasDarkglareBoon = false
    talents.hasIlluminatedSigils = false
    talents.hasSoulFlame = false
    talents.hasErraticFelheart = false
    talents.hasStokingTheFlames = false
    talents.hasMeteorStrike = false
    talents.hasBlindFaith = false
    talents.hasAnyMeansNecessary = false
    talents.hasRecrimination = false
    talents.hasFrailty = false
    talents.hasSigilborn = false
    talents.hasDemonicTrample = false
    talents.hasWickedInstincts = false
    
    -- War Within Season 2 talents
    talents.hasRuination = false
    talents.hasDeflectingSpikes = false
    talents.hasExtendedSpikes = false
    talents.hasShearFury = false
    talents.hasFrenziedUptime = false
    talents.hasLivelihoodOfFlame = false
    talents.hasBurnOut = false
    talents.hasReverseRapture = false
    talents.hasFlameCrash = false
    talents.hasRazorspikes = false
    talents.hasSiegebreaker = false
    
    -- Initialize resources
    currentFury = API.GetPlayerPower()
    
    -- Initialize Soul Fragments
    soulFragments = API.GetSoulFragments() or 0
    
    -- Initialize ability charges
    demonSpikeCharges = API.GetSpellCharges(spells.DEMON_SPIKES) or 0
    demonSpikeMaxCharges = API.GetSpellMaxCharges(spells.DEMON_SPIKES) or 2
    
    return true
end

-- Register spec-specific settings
function Vengeance:RegisterSettings()
    ConfigRegistry:RegisterSettings("VengeanceDemonHunter", {
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
            furyPooling = {
                displayName = "Fury Pooling",
                description = "Pool Fury for priority abilities",
                type = "toggle",
                default = true
            },
            furyPoolingThreshold = {
                displayName = "Fury Pooling Threshold",
                description = "Minimum Fury to maintain",
                type = "slider",
                min = 30,
                max = 100,
                default = 50
            },
            useSpiritBomb = {
                displayName = "Use Spirit Bomb",
                description = "Automatically use Spirit Bomb when talented",
                type = "toggle",
                default = true
            },
            spiritBombFragments = {
                displayName = "Spirit Bomb Fragments",
                description = "Minimum Soul Fragments to use Spirit Bomb",
                type = "slider",
                min = 1,
                max = 5,
                default = 4
            },
            soulCleaveFragments = {
                displayName = "Soul Cleave Fragments",
                description = "Minimum Soul Fragments to prioritize Soul Cleave",
                type = "slider",
                min = 0,
                max = 5,
                default = 3
            }
        },
        
        defensiveSettings = {
            useDemonSpikes = {
                displayName = "Use Demon Spikes",
                description = "Automatically use Demon Spikes",
                type = "toggle",
                default = true
            },
            demonSpikesChargesReserved = {
                displayName = "Demon Spikes Charges Reserved",
                description = "Charges to save for emergencies",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            },
            demonSpikesHealthThreshold = {
                displayName = "Demon Spikes Health Threshold",
                description = "Health percentage to use Demon Spikes",
                type = "slider",
                min = 0,
                max = 100,
                default = 80
            },
            useFieryBrand = {
                displayName = "Use Fiery Brand",
                description = "Automatically use Fiery Brand",
                type = "toggle",
                default = true
            },
            fieryBrandHealthThreshold = {
                displayName = "Fiery Brand Health Threshold",
                description = "Health percentage to use Fiery Brand",
                type = "slider",
                min = 0,
                max = 100,
                default = 60
            },
            useMetamorphosis = {
                displayName = "Use Metamorphosis Defensively",
                description = "Automatically use Metamorphosis for survival",
                type = "toggle",
                default = true
            },
            metamorphosisHealthThreshold = {
                displayName = "Metamorphosis Health Threshold",
                description = "Health percentage to use Metamorphosis",
                type = "slider",
                min = 0,
                max = 50,
                default = 30
            },
            useSoulBarrier = {
                displayName = "Use Soul Barrier",
                description = "Automatically use Soul Barrier when talented",
                type = "toggle",
                default = true
            },
            soulBarrierHealthThreshold = {
                displayName = "Soul Barrier Health Threshold",
                description = "Health percentage to use Soul Barrier",
                type = "slider",
                min = 0,
                max = 100,
                default = 50
            },
            soulBarrierFragments = {
                displayName = "Soul Barrier Fragments",
                description = "Minimum Soul Fragments to use Soul Barrier",
                type = "slider",
                min = 0,
                max = 5,
                default = 3
            }
        },
        
        offensiveSettings = {
            useMetamorphosis = {
                displayName = "Use Metamorphosis Offensively",
                description = "Automatically use Metamorphosis for DPS",
                type = "toggle",
                default = true
            },
            useFelDevastation = {
                displayName = "Use Fel Devastation",
                description = "Automatically use Fel Devastation",
                type = "toggle",
                default = true
            },
            felDevastationMinTargets = {
                displayName = "Fel Devastation Min Targets",
                description = "Minimum targets to use Fel Devastation",
                type = "slider",
                min = 1,
                max = 6,
                default = 1
            },
            useBulkExtraction = {
                displayName = "Use Bulk Extraction",
                description = "Automatically use Bulk Extraction when talented",
                type = "toggle",
                default = true
            },
            bulkExtractionThreshold = {
                displayName = "Bulk Extraction Min Targets",
                description = "Minimum targets to use Bulk Extraction",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            useSoulCarver = {
                displayName = "Use Soul Carver",
                description = "Automatically use Soul Carver when talented",
                type = "toggle",
                default = true
            }
        },
        
        sigilSettings = {
            useSigilOfFlame = {
                displayName = "Use Sigil of Flame",
                description = "Automatically use Sigil of Flame",
                type = "toggle",
                default = true
            },
            sigilOfFlameMode = {
                displayName = "Sigil of Flame Placement",
                description = "How to place Sigil of Flame",
                type = "dropdown",
                options = {"At Cursor", "Under Target", "At Self"},
                default = "Under Target"
            },
            useSigilOfChains = {
                displayName = "Use Sigil of Chains",
                description = "Automatically use Sigil of Chains when talented",
                type = "toggle",
                default = true
            },
            sigilOfChainsMinTargets = {
                displayName = "Sigil of Chains Min Targets",
                description = "Minimum targets to use Sigil of Chains",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            useSigilOfSilence = {
                displayName = "Use Sigil of Silence",
                description = "Automatically use Sigil of Silence",
                type = "toggle",
                default = true
            },
            useSigilOfMisery = {
                displayName = "Use Sigil of Misery",
                description = "Automatically use Sigil of Misery when talented",
                type = "toggle",
                default = true
            }
        },
        
        utilitySettings = {
            useInfernalStrike = {
                displayName = "Use Infernal Strike",
                description = "Automatically use Infernal Strike for DPS",
                type = "toggle",
                default = true
            },
            infernalStrikeChargesReserved = {
                displayName = "Infernal Strike Charges Reserved",
                description = "Charges to save for movement",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            },
            infernalStrikeMode = {
                displayName = "Infernal Strike Placement",
                description = "How to place Infernal Strike",
                type = "dropdown",
                options = {"At Cursor", "Under Target", "At Self"},
                default = "Under Target"
            },
            useThrowGlaive = {
                displayName = "Use Throw Glaive",
                description = "Automatically use Throw Glaive",
                type = "toggle",
                default = true
            },
            useFelblade = {
                displayName = "Use Felblade",
                description = "Automatically use Felblade when talented",
                type = "toggle",
                default = true
            },
            useImprison = {
                displayName = "Use Imprison",
                description = "Automatically use Imprison on demon/elemental adds",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Fiery Brand controls
            fieryBrand = AAC.RegisterAbility(spells.FIERY_BRAND, {
                enabled = true,
                useDuringBurstOnly = false,
                priorityTargets = true
            }),
            
            -- Metamorphosis controls
            metamorphosis = AAC.RegisterAbility(spells.METAMORPHOSIS, {
                enabled = true,
                useDuringBurstOnly = true,
                preferOffensive = false
            }),
            
            -- Fel Devastation controls
            felDevastation = AAC.RegisterAbility(spells.FEL_DEVASTATION, {
                enabled = true,
                useDuringBurstOnly = false,
                minFury = 50
            })
        }
    })
    
    return true
end

-- Register for events 
function Vengeance:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for fury updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "FURY" then
            self:UpdateFury()
        end
    end)
    
    -- Register for soul fragment updates
    API.RegisterEvent("SOUL_FRAGMENT_CHANGED", function() 
        self:UpdateSoulFragments()
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    return true
end

-- Update talent information
function Vengeance:UpdateTalentInfo()
    -- Check for important talents
    talents.hasBulkExtraction = API.HasTalent(spells.BULK_EXTRACTION)
    talents.hasVoidReaver = API.HasTalent(spells.VOID_REAVER)
    talents.hasFeastOfSouls = API.HasTalent(spells.FEAST_OF_SOULS)
    talents.hasFallout = API.HasTalent(spells.FALLOUT)
    talents.hasBurningAlive = API.HasTalent(spells.BURNING_ALIVE)
    talents.hasInfernalArmor = API.HasTalent(spells.INFERNAL_ARMOR)
    talents.hasCharredFlesh = API.HasTalent(spells.CHARRED_FLESH)
    talents.hasRoaringFire = API.HasTalent(spells.ROARING_FIRE)
    talents.hasCalcifiedSpikes = API.HasTalent(spells.CALCIFIED_SPIKES)
    talents.hasFieryDemise = API.HasTalent(spells.FIERY_DEMISE)
    talents.hasFocusedCleave = API.HasTalent(spells.FOCUSED_CLEAVE)
    talents.hasPainBringer = API.HasTalent(spells.PAIN_BRINGER)
    talents.hasConcentratedSigils = API.HasTalent(spells.CONCENTRATED_SIGILS)
    talents.hasQuickenedSigils = API.HasTalent(spells.QUICKENED_SIGILS)
    talents.hasSigilOfChains = API.HasTalent(spells.SIGIL_OF_CHAINS)
    talents.hasAbyssalStrike = API.HasTalent(spells.ABYSSAL_STRIKE)
    talents.hasAgonizingFlames = API.HasTalent(spells.AGONIZING_FLAMES)
    talents.hasFelDefender = API.HasTalent(spells.FEL_DEFENDER)
    talents.hasSoulCarver = API.HasTalent(spells.SOUL_CARVER)
    talents.hasDemonic = API.HasTalent(spells.DEMONIC)
    talents.hasSoulRending = API.HasTalent(spells.SOUL_RENDING)
    talents.hasFeedTheDemon = API.HasTalent(spells.FEED_THE_DEMON)
    talents.hasFracture = API.HasTalent(spells.FRACTURE)
    talents.hasFelblade = API.HasTalent(spells.FELBLADE)
    talents.hasFirstOfTheIllidari = API.HasTalent(spells.FIRST_OF_THE_ILLIDARI)
    talents.hasSpiritBomb = API.HasTalent(spells.SPIRITBOMB)
    talents.hasRevelInPain = API.HasTalent(spells.REVEL_IN_PAIN)
    talents.hasFodderToTheFlame = API.HasTalent(spells.FODDER_TO_THE_FLAME)
    talents.hasCycleOfBinding = API.HasTalent(spells.CYCLE_OF_BINDING)
    talents.hasSigilOfMisery = API.HasTalent(spells.SIGIL_OF_MISERY)
    talents.hasChainsOfAnger = API.HasTalent(spells.CHAINS_OF_ANGER)
    talents.hasUnendingHatred = API.HasTalent(spells.UNENDING_HATRED)
    talents.hasPerfectRefraction = API.HasTalent(spells.PERFECT_REFRACTION)
    talents.hasPreciseSigils = API.HasTalent(spells.PRECISE_SIGILS)
    talents.hasDarkglareBoon = API.HasTalent(spells.DARKGLARE_BOON)
    talents.hasIlluminatedSigils = API.HasTalent(spells.ILLUMINATED_SIGILS)
    talents.hasSoulFlame = API.HasTalent(spells.SOUL_FLAME)
    talents.hasErraticFelheart = API.HasTalent(spells.ERRATIC_FELHEART)
    talents.hasStokingTheFlames = API.HasTalent(spells.STOKE_THE_FLAMES)
    talents.hasMeteorStrike = API.HasTalent(spells.METEORIC_STRIKE)
    talents.hasBlindFaith = API.HasTalent(spells.BLIND_FAITH)
    talents.hasAnyMeansNecessary = API.HasTalent(spells.ANY_MEANS_NECESSARY)
    talents.hasRecrimination = API.HasTalent(spells.RECRIMINATION)
    talents.hasFrailty = API.HasTalent(spells.FRAILTY)
    talents.hasSigilborn = API.HasTalent(spells.SIGILBORN)
    talents.hasDemonicTrample = API.HasTalent(spells.DEMONIC_TRAMPLE)
    talents.hasWickedInstincts = API.HasTalent(spells.WICKED_INSTINCTS)
    
    -- War Within Season 2 talents
    talents.hasRuination = API.HasTalent(spells.RUINATION)
    talents.hasDeflectingSpikes = API.HasTalent(spells.DEFLECTING_SPIKES)
    talents.hasExtendedSpikes = API.HasTalent(spells.EXTENDED_SPIKES)
    talents.hasShearFury = API.HasTalent(spells.SHEAR_FURY)
    talents.hasFrenziedUptime = API.HasTalent(spells.FRENZIED_UPTIME)
    talents.hasLivelihoodOfFlame = API.HasTalent(spells.LIVELIHOOD_OF_FLAME)
    talents.hasBurnOut = API.HasTalent(spells.BURN_OUT)
    talents.hasReverseRapture = API.HasTalent(spells.REVERSE_RAPTURE)
    talents.hasFlameCrash = API.HasTalent(spells.FLAME_CRASH)
    talents.hasRazorspikes = API.HasTalent(spells.RAZORSPIKES)
    talents.hasSiegebreaker = API.HasTalent(spells.SIEGEBREAKER)
    
    -- Set specialized variables based on talents
    if talents.hasVoidReaver then
        voidReaver = true
    end
    
    if talents.hasCalcifiedSpikes then
        calcifiedSpikes = true
    end
    
    if talents.hasFieryDemise then
        fieryDemise = true
    }
    
    if talents.hasFocusedCleave then
        focusedCleave = true
    }
    
    if talents.hasPainBringer then
        painBringer = true
    }
    
    if talents.hasFelblade then
        felblade = true
    }
    
    if talents.hasFodderToTheFlame then
        fodderToTheFlame = true
    }
    
    if talents.hasSiegebreaker then
        siegebreaker = true
    }
    
    if talents.hasShearFury then
        shearFury = true
    }
    
    if talents.hasFrenziedUptime then
        frenziedUptime = true
    }
    
    if talents.hasLivelihoodOfFlame then
        livelihoodOfFlame = true
    }
    
    if talents.hasReverseRapture then
        reverseRapture = true
    }
    
    if talents.hasCharredFlesh then
        charredFleshActive = true
    }
    
    if talents.hasRoaringFire then
        roaringFireActive = true
    }
    
    -- Initialize ability charges
    demonSpikeCharges = API.GetSpellCharges(spells.DEMON_SPIKES) or 0
    demonSpikeMaxCharges = API.GetSpellMaxCharges(spells.DEMON_SPIKES) or 2
    
    API.PrintDebug("Vengeance Demon Hunter talents updated")
    
    return true
end

-- Update fury tracking
function Vengeance:UpdateFury()
    currentFury = API.GetPlayerPower()
    return true
end

-- Update soul fragments tracking
function Vengeance:UpdateSoulFragments()
    soulFragments = API.GetSoulFragments() or 0
    soulFragBuffActive = API.HasBuff("player", buffs.SOUL_FRAGMENTS)
    return true
end

-- Update target data
function Vengeance:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Fiery Brand
        if fieryBrandTargets[targetGUID] then
            fieryBrandActive = true
            fieryBrandEndTime = fieryBrandTargets[targetGUID]
        else
            fieryBrandActive = false
            fieryBrandEndTime = 0
        end
        
        -- Check for Frailty
        if talents.hasFrailty then
            local frailtyInfo = API.GetDebuffInfo(targetGUID, debuffs.FRAILTY)
            if frailtyInfo then
                frailtyActive = true
                frailtyStacks = select(4, frailtyInfo) or 1
                frailtyEndTime = select(6, frailtyInfo)
            else
                frailtyActive = false
                frailtyStacks = 0
                frailtyEndTime = 0
            end
        end
        
        -- Check for Sigil of Flame
        local sigilInfo = API.GetDebuffInfo(targetGUID, debuffs.SIGIL_OF_FLAME)
        sigilOfFlameActive = sigilInfo ~= nil
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius
    
    return true
end

-- Handle combat log events
function Vengeance:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Metamorphosis
            if spellID == buffs.METAMORPHOSIS then
                metamorphosisActive = true
                metamorphosisEndTime = GetTime() + METAMORPHOSIS_DURATION
                API.PrintDebug("Metamorphosis activated")
            end
            
            -- Track Demon Spikes
            if spellID == buffs.DEMON_SPIKES then
                demonSpikeActive = true
                demonSpikeEndTime = GetTime() + DEMON_SPIKE_DURATION
                API.PrintDebug("Demon Spikes activated")
            end
            
            -- Track Immolation Aura
            if spellID == buffs.IMMOLATION_AURA then
                immoAuraActive = true
                immoAuraEndTime = GetTime() + IMMOLATION_AURA_DURATION
                API.PrintDebug("Immolation Aura activated")
            end
            
            -- Track Soul Barrier
            if spellID == buffs.SOUL_BARRIER then
                soulBarrierActive = true
                soulBarrierEndTime = GetTime() + SOUL_BARRIER_DURATION
                API.PrintDebug("Soul Barrier activated")
            end
            
            -- Track Charred Flesh
            if spellID == buffs.CHARRED_FLESH then
                charredFleshActive = true
                API.PrintDebug("Charred Flesh activated")
            end
            
            -- Track Roaring Fire
            if spellID == buffs.ROARING_FIRE then
                roaringFireActive = true
                API.PrintDebug("Roaring Fire activated")
            end
            
            -- Track Shear Fury
            if spellID == buffs.SHEAR_FURY then
                shearFury = true
                shearFuryEndTime = GetTime() + 12 -- typical duration
                API.PrintDebug("Shear Fury activated")
            end
            
            -- Track Burn Out
            if spellID == buffs.BURN_OUT then
                burnOutActive = true
                burnOutStacks = select(4, API.GetBuffInfo("player", buffs.BURN_OUT)) or 1
                API.PrintDebug("Burn Out activated: " .. tostring(burnOutStacks) .. " stacks")
            end
        end
        
        -- Track Fiery Brand application to target
        if spellID == debuffs.FIERY_BRAND then
            fieryBrandTargets[destGUID] = GetTime() + FIERY_BRAND_DURATION
            
            if destGUID == API.GetTargetGUID() then
                fieryBrandActive = true
                fieryBrandEndTime = fieryBrandTargets[destGUID]
            end
            
            API.PrintDebug("Fiery Brand applied to " .. destName)
        end
        
        -- Track Frailty application to target
        if spellID == debuffs.FRAILTY and destGUID == API.GetTargetGUID() then
            frailtyActive = true
            frailtyStacks = select(4, API.GetDebuffInfo(destGUID, debuffs.FRAILTY)) or 1
            frailtyEndTime = GetTime() + FRAILTY_DURATION
            API.PrintDebug("Frailty applied to target: " .. tostring(frailtyStacks) .. " stacks")
        end
        
        -- Track Spirit Bomb
        if spellID == buffs.SPIRIT_BOMB then
            spiritBombActive = true
            spiritBombEndTime = GetTime() + SPIRIT_BOMB_DURATION
            API.PrintDebug("Spirit Bomb activated")
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Metamorphosis
            if spellID == buffs.METAMORPHOSIS then
                metamorphosisActive = false
                API.PrintDebug("Metamorphosis faded")
            end
            
            -- Track Demon Spikes
            if spellID == buffs.DEMON_SPIKES then
                demonSpikeActive = false
                API.PrintDebug("Demon Spikes faded")
            end
            
            -- Track Immolation Aura
            if spellID == buffs.IMMOLATION_AURA then
                immoAuraActive = false
                API.PrintDebug("Immolation Aura faded")
            end
            
            -- Track Soul Barrier
            if spellID == buffs.SOUL_BARRIER then
                soulBarrierActive = false
                API.PrintDebug("Soul Barrier faded")
            end
            
            -- Track Charred Flesh
            if spellID == buffs.CHARRED_FLESH then
                charredFleshActive = false
                API.PrintDebug("Charred Flesh faded")
            end
            
            -- Track Roaring Fire
            if spellID == buffs.ROARING_FIRE then
                roaringFireActive = false
                API.PrintDebug("Roaring Fire faded")
            end
            
            -- Track Shear Fury
            if spellID == buffs.SHEAR_FURY then
                shearFury = false
                API.PrintDebug("Shear Fury faded")
            end
            
            -- Track Burn Out
            if spellID == buffs.BURN_OUT then
                burnOutActive = false
                burnOutStacks = 0
                API.PrintDebug("Burn Out faded")
            end
        end
        
        -- Track Fiery Brand removal from target
        if spellID == debuffs.FIERY_BRAND then
            fieryBrandTargets[destGUID] = nil
            
            if destGUID == API.GetTargetGUID() then
                fieryBrandActive = false
                fieryBrandEndTime = 0
            end
            
            API.PrintDebug("Fiery Brand faded from " .. destName)
        end
        
        -- Track Frailty removal from target
        if spellID == debuffs.FRAILTY and destGUID == API.GetTargetGUID() then
            frailtyActive = false
            frailtyStacks = 0
            API.PrintDebug("Frailty faded from target")
        end
        
        -- Track Spirit Bomb
        if spellID == buffs.SPIRIT_BOMB then
            spiritBombActive = false
            API.PrintDebug("Spirit Bomb faded")
        end
    end
    
    -- Track Frailty stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == debuffs.FRAILTY and destGUID == API.GetTargetGUID() then
        frailtyStacks = select(4, API.GetDebuffInfo(destGUID, debuffs.FRAILTY)) or 0
        API.PrintDebug("Frailty stacks on target: " .. tostring(frailtyStacks))
    end
    
    -- Track Burn Out stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.BURN_OUT and destGUID == API.GetPlayerGUID() then
        burnOutStacks = select(4, API.GetBuffInfo("player", buffs.BURN_OUT)) or 0
        API.PrintDebug("Burn Out stacks: " .. tostring(burnOutStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.DEMON_SPIKES then
            demonSpikeCharges = API.GetSpellCharges(spells.DEMON_SPIKES) or 0
            demonSpikeActive = true
            demonSpikeEndTime = GetTime() + DEMON_SPIKE_DURATION
            API.PrintDebug("Demon Spikes cast, charges remaining: " .. tostring(demonSpikeCharges))
        elseif spellID == spells.FIERY_BRAND then
            API.PrintDebug("Fiery Brand cast")
        elseif spellID == spells.METAMORPHOSIS then
            metamorphosisActive = true
            metamorphosisEndTime = GetTime() + METAMORPHOSIS_DURATION
            API.PrintDebug("Metamorphosis cast")
        elseif spellID == spells.IMMOLATION_AURA then
            immoAuraActive = true
            immoAuraEndTime = GetTime() + IMMOLATION_AURA_DURATION
            API.PrintDebug("Immolation Aura cast")
        elseif spellID == spells.SOUL_BARRIER then
            soulBarrierActive = true
            soulBarrierEndTime = GetTime() + SOUL_BARRIER_DURATION
            API.PrintDebug("Soul Barrier cast")
        elseif spellID == spells.FEL_DEVASTATION then
            felDevastation = true
            felDevastationEndTime = GetTime() + FEL_DEVASTATION_DURATION
            API.PrintDebug("Fel Devastation cast")
        elseif spellID == spells.BULK_EXTRACTION then
            bulkExtraction = true
            bulkExtractionCooldown = API.GetSpellCooldown(spells.BULK_EXTRACTION)
            API.PrintDebug("Bulk Extraction cast")
        elseif spellID == spells.SPIRIT_BOMB then
            spiritBombActive = true
            spiritBombEndTime = GetTime() + SPIRIT_BOMB_DURATION
            API.PrintDebug("Spirit Bomb cast")
        elseif spellID == spells.SOUL_CLEAVE then
            API.PrintDebug("Soul Cleave cast")
        elseif spellID == spells.SIGIL_OF_FLAME then
            sigil1Active = true
            
            -- Reset sigil status after a delay
            C_Timer.After(2, function()
                sigil1Active = false
                API.PrintDebug("Sigil of Flame activated")
            end)
            
            API.PrintDebug("Sigil of Flame cast")
        elseif spellID == spells.SIGIL_OF_CHAINS then
            sigil2Active = true
            sigilOfChainsCooldown = API.GetSpellCooldown(spells.SIGIL_OF_CHAINS)
            sigilOfChainsCharges = API.GetSpellCharges(spells.SIGIL_OF_CHAINS) or 0
            
            -- Reset sigil status after a delay
            C_Timer.After(2, function()
                sigil2Active = false
                API.PrintDebug("Sigil of Chains activated")
            end)
            
            API.PrintDebug("Sigil of Chains cast")
        elseif spellID == spells.SIGIL_OF_SILENCE then
            sigil3Active = true
            sigilOfSilenceCooldown = API.GetSpellCooldown(spells.SIGIL_OF_SILENCE)
            
            -- Reset sigil status after a delay
            C_Timer.After(2, function()
                sigil3Active = false
                API.PrintDebug("Sigil of Silence activated")
            end)
            
            API.PrintDebug("Sigil of Silence cast")
        elseif spellID == spells.SIGIL_OF_MISERY then
            sigilOfMiseryCooldown = API.GetSpellCooldown(spells.SIGIL_OF_MISERY)
            API.PrintDebug("Sigil of Misery cast")
        end
    end
    
    -- Track channeling start
    if eventType == "SPELL_CHANNEL_START" then
        if spellID == spells.FEL_DEVASTATION then
            felDevastation = true
            API.PrintDebug("Fel Devastation channel started")
        end
    end
    
    -- Track channeling stop
    if eventType == "SPELL_CHANNEL_STOP" then
        if spellID == spells.FEL_DEVASTATION then
            felDevastation = false
            API.PrintDebug("Fel Devastation channel ended")
        end
    end
    
    return true
end

-- Main rotation function
function Vengeance:RunRotation()
    -- Check if we should be running Vengeance Demon Hunter logic
    if API.GetActiveSpecID() ~= VENGEANCE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or felDevastation then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("VengeanceDemonHunter")
    
    -- Update variables
    self:UpdateFury()
    self:UpdateSoulFragments()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
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
    
    -- Check if in melee range for main rotation
    if not inMeleeRange then
        -- Use ranged abilities if not in melee range
        return self:HandleRangedAbilities(settings)
    end
    
    -- Handle sigils
    if self:HandleSigils(settings) then
        return true
    end
    
    -- Handle cooldowns
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
function Vengeance:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.DISRUPT) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.DISRUPT)
        return true
    end
    
    -- Use Sigil of Silence as backup interrupt if not in melee range
    if not inMeleeRange and
       API.IsUnitInRange("target", SIGIL_RANGE) and
       API.CanCast(spells.SIGIL_OF_SILENCE) and
       API.TargetIsSpellCastable() then
        local placement = "target"
        API.CastSpellAt(spells.SIGIL_OF_SILENCE, placement)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Vengeance:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Metamorphosis for emergency
    if settings.defensiveSettings.useMetamorphosis and
       playerHealth <= settings.defensiveSettings.metamorphosisHealthThreshold and
       not metamorphosisActive and
       API.CanCast(spells.METAMORPHOSIS) and
       (not settings.abilityControls.metamorphosis.useDuringBurstOnly or burstModeActive) then
        API.CastSpell(spells.METAMORPHOSIS)
        return true
    end
    
    -- Use Fiery Brand
    if settings.defensiveSettings.useFieryBrand and
       playerHealth <= settings.defensiveSettings.fieryBrandHealthThreshold and
       not fieryBrandActive and
       API.CanCast(spells.FIERY_BRAND) and
       (not settings.abilityControls.fieryBrand.useDuringBurstOnly or burstModeActive) then
        
        -- Cast on priority targets if enabled, otherwise on current target
        if settings.abilityControls.fieryBrand.priorityTargets then
            -- Look for a deadly mob to cast on
            local deadlyTarget = API.FindDeadliestTarget()
            if deadlyTarget then
                API.CastSpellOnUnit(spells.FIERY_BRAND, deadlyTarget)
            else
                API.CastSpell(spells.FIERY_BRAND)
            end
        else
            API.CastSpell(spells.FIERY_BRAND)
        end
        
        return true
    end
    
    -- Use Demon Spikes
    if settings.defensiveSettings.useDemonSpikes and
       not demonSpikeActive and
       playerHealth <= settings.defensiveSettings.demonSpikesHealthThreshold and
       demonSpikeCharges > settings.defensiveSettings.demonSpikesChargesReserved and
       API.CanCast(spells.DEMON_SPIKES) then
        API.CastSpell(spells.DEMON_SPIKES)
        return true
    end
    
    -- Use Soul Barrier
    if talents.hasSoulBarrier and
       settings.defensiveSettings.useSoulBarrier and
       not soulBarrierActive and
       playerHealth <= settings.defensiveSettings.soulBarrierHealthThreshold and
       soulFragments >= settings.defensiveSettings.soulBarrierFragments and
       API.CanCast(spells.SOUL_BARRIER) then
        API.CastSpell(spells.SOUL_BARRIER)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Vengeance:HandleRangedAbilities(settings)
    -- Use Throw Glaive
    if settings.utilitySettings.useThrowGlaive and
       API.CanCast(spells.THROW_GLAIVE) then
        API.CastSpell(spells.THROW_GLAIVE)
        return true
    end
    
    -- Use Felblade to close gap
    if talents.hasFelblade and
       settings.utilitySettings.useFelblade and
       API.CanCast(spells.FELBLADE) then
        API.CastSpell(spells.FELBLADE)
        return true
    end
    
    -- Use Sigil of Flame at a distance
    if settings.sigilSettings.useSigilOfFlame and
       API.IsUnitInRange("target", SIGIL_RANGE) and
       API.CanCast(spells.SIGIL_OF_FLAME) then
        local placement
        if settings.sigilSettings.sigilOfFlameMode == "At Cursor" then
            placement = "cursor"
        elseif settings.sigilSettings.sigilOfFlameMode == "Under Target" then
            placement = "target"
        else
            placement = "player"
        end
        
        API.CastSpellAt(spells.SIGIL_OF_FLAME, placement)
        return true
    end
    
    -- Use Infernal Strike to close the gap if not reserved
    if settings.utilitySettings.useInfernalStrike and
       API.GetSpellCharges(spells.INFERNAL_STRIKE) > settings.utilitySettings.infernalStrikeChargesReserved and
       API.CanCast(spells.INFERNAL_STRIKE) then
        
        local placement
        if settings.utilitySettings.infernalStrikeMode == "At Cursor" then
            placement = "cursor"
        elseif settings.utilitySettings.infernalStrikeMode == "Under Target" then
            placement = "target"
        else
            placement = "player"
        end
        
        API.CastSpellAt(spells.INFERNAL_STRIKE, placement)
        return true
    end
    
    return false
end

-- Handle sigil abilities
function Vengeance:HandleSigils(settings)
    -- Use Sigil of Flame
    if settings.sigilSettings.useSigilOfFlame and
       API.CanCast(spells.SIGIL_OF_FLAME) and
       not sigilOfFlameActive then
        
        local placement
        if settings.sigilSettings.sigilOfFlameMode == "At Cursor" then
            placement = "cursor"
        elseif settings.sigilSettings.sigilOfFlameMode == "Under Target" then
            placement = "target"
        else
            placement = "player"
        end
        
        API.CastSpellAt(spells.SIGIL_OF_FLAME, placement)
        return true
    end
    
    -- Use Sigil of Chains
    if talents.hasSigilOfChains and
       settings.sigilSettings.useSigilOfChains and
       currentAoETargets >= settings.sigilSettings.sigilOfChainsMinTargets and
       API.CanCast(spells.SIGIL_OF_CHAINS) then
        
        API.CastSpellAt(spells.SIGIL_OF_CHAINS, "target")
        return true
    end
    
    -- Use Sigil of Silence for mass interrupt if multiple casters
    if settings.sigilSettings.useSigilOfSilence and
       API.CountCastingEnemies() >= 2 and
       API.CanCast(spells.SIGIL_OF_SILENCE) then
        
        API.CastSpellAt(spells.SIGIL_OF_SILENCE, "target")
        return true
    end
    
    -- Use Sigil of Misery as crowd control
    if talents.hasSigilOfMisery and
       settings.sigilSettings.useSigilOfMisery and
       currentAoETargets >= 3 and
       API.CanCast(spells.SIGIL_OF_MISERY) then
        
        API.CastSpellAt(spells.SIGIL_OF_MISERY, "target")
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Vengeance:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive and not API.IsInCombat() then
        return false
    }
    
    -- Use Metamorphosis offensively
    if settings.offensiveSettings.useMetamorphosis and
       settings.abilityControls.metamorphosis.enabled and
       not metamorphosisActive and
       API.CanCast(spells.METAMORPHOSIS) then
        
        if (not settings.abilityControls.metamorphosis.useDuringBurstOnly or burstModeActive) and
           settings.abilityControls.metamorphosis.preferOffensive then
            API.CastSpell(spells.METAMORPHOSIS)
            return true
        end
    end
    
    -- Use Fel Devastation
    if settings.offensiveSettings.useFelDevastation and
       settings.abilityControls.felDevastation.enabled and
       currentAoETargets >= settings.offensiveSettings.felDevastationMinTargets and
       API.CanCast(spells.FEL_DEVASTATION) then
        
        if currentFury >= settings.abilityControls.felDevastation.minFury and
           (not settings.abilityControls.felDevastation.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.FEL_DEVASTATION)
            return true
        end
    end
    
    -- Use Bulk Extraction
    if talents.hasBulkExtraction and
       settings.offensiveSettings.useBulkExtraction and
       currentAoETargets >= settings.offensiveSettings.bulkExtractionThreshold and
       API.CanCast(spells.BULK_EXTRACTION) then
        API.CastSpell(spells.BULK_EXTRACTION)
        return true
    end
    
    -- Use Soul Carver
    if talents.hasSoulCarver and
       settings.offensiveSettings.useSoulCarver and
       API.CanCast(spells.SOUL_CARVER) then
        API.CastSpell(spells.SOUL_CARVER)
        return true
    end
    
    -- Use covenant abilities
    if talents.hasFodderToTheFlame and API.CanCast(spells.FODDER_TO_THE_FLAME) then
        API.CastSpell(spells.FODDER_TO_THE_FLAME)
        return true
    end
    
    if API.CanCast(spells.ELYSIAN_DECREE) then
        API.CastSpellAt(spells.ELYSIAN_DECREE, "target")
        return true
    end
    
    if API.CanCast(spells.THE_HUNT) then
        API.CastSpell(spells.THE_HUNT)
        return true
    end
    
    if API.CanCast(spells.SINFUL_BRAND) then
        API.CastSpell(spells.SINFUL_BRAND)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Vengeance:HandleAoERotation(settings)
    -- Use Immolation Aura
    if not immoAuraActive and API.CanCast(spells.IMMOLATION_AURA) then
        API.CastSpell(spells.IMMOLATION_AURA)
        return true
    end
    
    -- Use Spirit Bomb
    if talents.hasSpiritBomb and
       settings.rotationSettings.useSpiritBomb and
       soulFragments >= settings.rotationSettings.spiritBombFragments and
       API.CanCast(spells.SPIRIT_BOMB) then
        API.CastSpell(spells.SPIRIT_BOMB)
        return true
    end
    
    -- Use Infernal Strike for damage if not reserved
    if settings.utilitySettings.useInfernalStrike and
       API.GetSpellCharges(spells.INFERNAL_STRIKE) > settings.utilitySettings.infernalStrikeChargesReserved and
       API.CanCast(spells.INFERNAL_STRIKE) then
        
        local placement
        if settings.utilitySettings.infernalStrikeMode == "At Cursor" then
            placement = "cursor"
        elseif settings.utilitySettings.infernalStrikeMode == "Under Target" then
            placement = "target"
        else
            placement = "player"
        end
        
        API.CastSpellAt(spells.INFERNAL_STRIKE, placement)
        return true
    end
    
    -- Use Soul Cleave if we have enough Soul Fragments
    if API.CanCast(spells.SOUL_CLEAVE) and
       ((soulFragments >= settings.rotationSettings.soulCleaveFragments and currentFury >= 30) or
        (currentFury >= 70 and soulFragments < settings.rotationSettings.spiritBombFragments)) then
        API.CastSpell(spells.SOUL_CLEAVE)
        return true
    end
    
    -- Use Fracture to generate Soul Fragments
    if talents.hasFracture and
       currentFury >= 30 and
       API.CanCast(spells.FRACTURE) then
        API.CastSpell(spells.FRACTURE)
        return true
    end
    
    -- Use Shear if no Fracture
    if not talents.hasFracture and
       API.CanCast(spells.SHEAR) then
        API.CastSpell(spells.SHEAR)
        return true
    end
    
    -- Use Felblade for Fury generation
    if talents.hasFelblade and
       settings.utilitySettings.useFelblade and
       currentFury < 70 and
       API.CanCast(spells.FELBLADE) then
        API.CastSpell(spells.FELBLADE)
        return true
    end
    
    -- Throw Glaive as filler
    if settings.utilitySettings.useThrowGlaive and
       API.CanCast(spells.THROW_GLAIVE) then
        API.CastSpell(spells.THROW_GLAIVE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Vengeance:HandleSingleTargetRotation(settings)
    -- Use Immolation Aura
    if not immoAuraActive and API.CanCast(spells.IMMOLATION_AURA) then
        API.CastSpell(spells.IMMOLATION_AURA)
        return true
    end
    
    -- Use Spirit Bomb
    if talents.hasSpiritBomb and
       settings.rotationSettings.useSpiritBomb and
       soulFragments >= settings.rotationSettings.spiritBombFragments and
       API.CanCast(spells.SPIRIT_BOMB) then
        API.CastSpell(spells.SPIRIT_BOMB)
        return true
    end
    
    -- Use Soul Cleave
    if API.CanCast(spells.SOUL_CLEAVE) and
       ((soulFragments >= settings.rotationSettings.soulCleaveFragments and currentFury >= 30) or
        (currentFury >= 70 and not settings.rotationSettings.furyPooling) or
        (currentFury >= 90)) then
        API.CastSpell(spells.SOUL_CLEAVE)
        return true
    end
    
    -- Use Fracture to generate Soul Fragments
    if talents.hasFracture and
       currentFury >= 30 and
       (not settings.rotationSettings.furyPooling or 
        currentFury >= settings.rotationSettings.furyPoolingThreshold) and
       API.CanCast(spells.FRACTURE) then
        API.CastSpell(spells.FRACTURE)
        return true
    end
    
    -- Use Shear if no Fracture
    if not talents.hasFracture and API.CanCast(spells.SHEAR) then
        API.CastSpell(spells.SHEAR)
        return true
    end
    
    -- Use Felblade for Fury generation
    if talents.hasFelblade and
       settings.utilitySettings.useFelblade and
       currentFury < 70 and
       API.CanCast(spells.FELBLADE) then
        API.CastSpell(spells.FELBLADE)
        return true
    end
    
    -- Throw Glaive as filler
    if settings.utilitySettings.useThrowGlaive and
       API.CanCast(spells.THROW_GLAIVE) then
        API.CastSpell(spells.THROW_GLAIVE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Vengeance:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentFury = API.GetPlayerPower()
    maxFury = 120
    fieryBrandActive = false
    fieryBrandEndTime = 0
    fieryBrandTargets = {}
    metamorphosisActive = false
    metamorphosisEndTime = 0
    demonSpikeCharges = API.GetSpellCharges(spells.DEMON_SPIKES) or 0
    demonSpikeMaxCharges = API.GetSpellMaxCharges(spells.DEMON_SPIKES) or 2
    demonSpikeActive = false
    demonSpikeEndTime = 0
    immoAuraActive = false
    immoAuraEndTime = 0
    soulFragments = API.GetSoulFragments() or 0
    maxSoulFragments = 5
    felDevastation = false
    felDevastationEndTime = 0
    soulBarrierActive = false
    soulBarrierEndTime = 0
    spiritBombActive = false
    spiritBombEndTime = 0
    bulkExtraction = false
    bulkExtractionCooldown = 0
    frailtyActive = false
    frailtyEndTime = 0
    frailtyStacks = 0
    felFissureCount = 0
    sigil1Active = false
    sigil2Active = false
    sigil3Active = false
    sigilOfFlameActive = false
    sigilOfChainsCooldown = 0
    sigilOfChainsCharges = 0
    sigilOfSilenceCooldown = 0
    sigilOfMiseryCooldown = 0
    charredFleshActive = false
    roaringFireActive = false
    calcifiedSpikes = false
    voidReaver = false
    fieryDemise = false
    focusedCleave = false
    painBringer = false
    felblade = false
    fodderToTheFlame = false
    inSigil = false
    siegebreaker = false
    shearFury = false
    shearFuryEndTime = 0
    frenziedUptime = false
    livelihoodOfFlame = false
    inMeleeRange = false
    soulFragBuffActive = false
    burnOutActive = false
    burnOutStacks = 0
    reverseRapture = false
    
    API.PrintDebug("Vengeance Demon Hunter state reset on spec change")
    
    return true
end

-- Return the module for loading
return Vengeance