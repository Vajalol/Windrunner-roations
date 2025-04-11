------------------------------------------
-- WindrunnerRotations - Discipline Priest Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Discipline = {}
-- This will be assigned to addon.Classes.Priest.Discipline when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Priest

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentMana = 0
local maxMana = 100
local atonementActive = {}
local atonementEndTime = {}
local powerWordShieldActive = {}
local powerWordShieldEndTime = {}
local painSuppressionActive = {}
local painSuppressionEndTime = {}
local raptureBuff = false
local raptureEndTime = 0
local powerInfusionActive = false
local powerInfusionEndTime = 0
local shadowCovenantActive = false
local shadowCovenantEndTime = 0
local mindBlastCharges = 0
local mindBlastMaxCharges = 0
local mindbenderActive = false
local mindbenderEndTime = 0
local borrowedTimeActive = false
local borrowedTimeEndTime = 0
local painSuppressActive = false
local painSuppressEndTime = 0
local painSuppressCharges = 0
local glimmerOfDawnActive = false
local glimmerOfDawnCount = 0
local shadowfiendActive = false
local shadowfiendEndTime = 0
local evangelismActive = false
local evangelismEndTime = 0
local spiritShellActive = false
local spiritShellEndTime = 0
local flashHealCastTime = 1.5
local penanceCharges = 0
local penanceMaxCharges = 0
local darkArchangelActive = false
local darkArchangelEndTime = 0
local schismActive = {}
local schismEndTime = {}
local powerWordRadianceCharges = 0
local powerWordRadianceMaxCharges = 0
local sinsSalve = false
local holyNova = false
local purgeTheWicked = false
local schism = false
local powerWordBarrier = false
local painSuppression = false
local rapture = false
local premonition = false
local powerWordLife = false
local divineStar = false
local halo = false
local luminousBarrier = false
local lenience = false
local indemnity = false
local contrition = false
local shadowCovenant = false
local clarity = false
local atonementPercent = 0
local evangelism = false
local spiritShell = false
local darkArchangel = false
local mindbender = false
local fiend = false
local shieldDiscipline = false
local painfulPunishment = false
local healingLightning = false
local lightsPromise = false
local speedOfThePious = false
local powerWordFortitude = false
local rampPartners = {}
local rampTarget = nil
local currentHealth = 100
local inRange = false
local targetHealth = 100
local atonementActiveCounts = 0
local maxGroupSize = 10
local penance = false

-- Constants
local DISCIPLINE_SPEC_ID = 256
local DEFAULT_AOE_THRESHOLD = 3
local ATONEMENT_DURATION = 15 -- seconds (base)
local POWER_WORD_SHIELD_DURATION = 15 -- seconds
local PAIN_SUPPRESSION_DURATION = 8 -- seconds
local RAPTURE_DURATION = 8 -- seconds
local POWER_INFUSION_DURATION = 20 -- seconds
local SHADOW_COVENANT_DURATION = 7 -- seconds
local MINDBENDER_DURATION = 15 -- seconds
local BORROWED_TIME_DURATION = 6 -- seconds
local SHADOWFIEND_DURATION = 15 -- seconds
local EVANGELISM_DURATION = 6 -- seconds
local SPIRIT_SHELL_DURATION = 10 -- seconds
local DARK_ARCHANGEL_DURATION = 8 -- seconds (using Legion duration as reference)
local SCHISM_DURATION = 9 -- seconds

-- Initialize the Discipline module
function Discipline:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Discipline Priest module initialized")
    
    return true
end

-- Register spell IDs
function Discipline:RegisterSpells()
    -- Core healing abilities
    spells.PENANCE = 47540
    spells.POWER_WORD_SHIELD = 17
    spells.SHADOW_MEND = 186263
    spells.POWER_WORD_RADIANCE = 194509
    spells.PAIN_SUPPRESSION = 33206
    spells.RAPTURE = 47536
    spells.POWER_WORD_BARRIER = 62618
    spells.LEAP_OF_FAITH = 73325
    spells.MASS_DISPEL = 32375
    spells.DIVINE_STAR = 110744
    spells.HALO = 120517
    spells.EVANGELISM = 246287
    spells.POWER_WORD_SOLACE = 129250
    spells.SPIRIT_SHELL = 109964
    spells.PURIFY = 527
    spells.DESPERATE_PRAYER = 19236
    spells.FLASH_HEAL = 2061
    spells.LUMINOUS_BARRIER = 271466
    spells.POWER_WORD_LIFE = 373481
    
    -- Core damage abilities
    spells.SMITE = 585
    spells.HOLY_NOVA = 132157
    spells.MIND_BLAST = 8092
    spells.MIND_CONTROL = 605
    spells.SHADOW_WORD_PAIN = 589
    spells.SHADOW_WORD_DEATH = 32379
    spells.PURGE_THE_WICKED = 204197
    spells.SCHISM = 214621
    spells.MINDGAMES = -1 -- Added placeholder, check if still in the game
    
    -- Core utilities
    spells.POWER_INFUSION = 10060
    spells.PSYCHIC_SCREAM = 8122
    spells.FADE = 586
    spells.DISPEL_MAGIC = 528
    spells.SHACKLE_UNDEAD = 9484
    spells.HOLY_WORD_CHASTISE = 88625
    spells.MASS_RESURRECTION = 212036
    spells.POWER_WORD_FORTITUDE = 21562
    spells.LEVITATE = 1706
    
    -- Pet abilities
    spells.SHADOWFIEND = 34433
    spells.MINDBENDER = 123040
    
    -- Talents and passives
    spells.DARK_ARCHANGEL = 197871
    spells.CLARITY_OF_WILL = 152118
    spells.CONTRITION = 197419
    spells.SHADOW_COVENANT = 314867
    spells.LENIENCE = 238063
    spells.SHIELD_DISCIPLINE = 197045
    spells.PREMONITION = 390669
    spells.ATONEMENT = 81749
    spells.INDEMNITY = 373338
    spells.LUMINOUS_BARRIER = 271466
    spells.SINS_SALVE = 390684
    spells.PAINFUL_PUNISHMENT = 390686
    spells.HEALING_LIGHTNING = 381859
    spells.LIGHTS_PROMISE = 373021
    spells.SPEED_OF_THE_PIOUS = 390638
    spells.PROTECTIVE_LIGHT = 193063
    spells.BORROWED_TIME = 59889
    
    -- War Within Season 2 specific
    spells.GLIMMER_OF_DAWN = 385751
    spells.STOLEN_PSYCHE = 373788
    spells.BINDING_HEALS = 368276
    spells.PARTING_SHADOW = 372991
    spells.DARKENED_DESTINY = 373062
    spells.BLESSED_RECOVERY = 390617
    spells.COSMIC_RIPPLE = 238136
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.MINDGAMES = 375901
    spells.UNHOLY_NOVA = 324724
    spells.ASCENDED_BLAST = 325315
    spells.ASCENDED_NOVA = 325020
    spells.FAE_GUARDIANS = 327661
    
    -- Buff IDs
    spells.ATONEMENT_BUFF = 194384
    spells.POWER_WORD_SHIELD_BUFF = 17
    spells.PAIN_SUPPRESSION_BUFF = 33206
    spells.RAPTURE_BUFF = 47536
    spells.POWER_INFUSION_BUFF = 10060
    spells.SHADOW_COVENANT_BUFF = 322105
    spells.BORROWED_TIME_BUFF = 59889
    spells.SHADOWFIEND_BUFF = 34433
    spells.EVANGELISM_BUFF = 246287
    spells.SPIRIT_SHELL_BUFF = 109964
    spells.DARK_ARCHANGEL_BUFF = 197871
    spells.POWER_WORD_BARRIER_BUFF = 81782
    spells.POWER_WORD_FORTITUDE_BUFF = 21562
    spells.LIGHTS_PROMISE_BUFF = 373021
    spells.SPEED_OF_THE_PIOUS_BUFF = 390638
    spells.BINDING_HEALS_BUFF = 368276
    
    -- Debuff IDs
    spells.SHADOW_WORD_PAIN_DEBUFF = 589
    spells.PURGE_THE_WICKED_DEBUFF = 204213
    spells.SCHISM_DEBUFF = 214621
    spells.MIND_CONTROL_DEBUFF = 605
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        if spellID > 0 then -- Skip placeholders like Mindgames if not available anymore
            API.RegisterSpell(spellID)
        end
    end
    
    -- Define aura tracking
    buffs.ATONEMENT = spells.ATONEMENT_BUFF
    buffs.POWER_WORD_SHIELD = spells.POWER_WORD_SHIELD_BUFF
    buffs.PAIN_SUPPRESSION = spells.PAIN_SUPPRESSION_BUFF
    buffs.RAPTURE = spells.RAPTURE_BUFF
    buffs.POWER_INFUSION = spells.POWER_INFUSION_BUFF
    buffs.SHADOW_COVENANT = spells.SHADOW_COVENANT_BUFF
    buffs.BORROWED_TIME = spells.BORROWED_TIME_BUFF
    buffs.SHADOWFIEND = spells.SHADOWFIEND_BUFF
    buffs.EVANGELISM = spells.EVANGELISM_BUFF
    buffs.SPIRIT_SHELL = spells.SPIRIT_SHELL_BUFF
    buffs.DARK_ARCHANGEL = spells.DARK_ARCHANGEL_BUFF
    buffs.POWER_WORD_BARRIER = spells.POWER_WORD_BARRIER_BUFF
    buffs.POWER_WORD_FORTITUDE = spells.POWER_WORD_FORTITUDE_BUFF
    buffs.LIGHTS_PROMISE = spells.LIGHTS_PROMISE_BUFF
    buffs.SPEED_OF_THE_PIOUS = spells.SPEED_OF_THE_PIOUS_BUFF
    buffs.BINDING_HEALS = spells.BINDING_HEALS_BUFF
    
    debuffs.SHADOW_WORD_PAIN = spells.SHADOW_WORD_PAIN_DEBUFF
    debuffs.PURGE_THE_WICKED = spells.PURGE_THE_WICKED_DEBUFF
    debuffs.SCHISM = spells.SCHISM_DEBUFF
    debuffs.MIND_CONTROL = spells.MIND_CONTROL_DEBUFF
    
    return true
end

-- Register variables to track
function Discipline:Initialize()
    -- Talent tracking
    talents.hasDarkArchangel = false
    talents.hasClarityOfWill = false
    talents.hasContrition = false
    talents.hasShadowCovenant = false
    talents.hasLenience = false
    talents.hasShieldDiscipline = false
    talents.hasPremonition = false
    talents.hasIndemnity = false
    talents.hasLuminousBarrier = false
    talents.hasSinsSalve = false
    talents.hasPurgeTheWicked = false
    talents.hasSchism = false
    talents.hasPowerWordBarrier = false
    talents.hasPainSuppression = false
    talents.hasRapture = false
    talents.hasDivineStar = false
    talents.hasHalo = false
    talents.hasPainfulPunishment = false
    talents.hasHealingLightning = false
    talents.hasLightsPromise = false
    talents.hasSpeedOfThePious = false
    talents.hasProtectiveLight = false
    talents.hasBorrowedTime = false
    talents.hasEvangelism = false
    talents.hasSpiritShell = false
    talents.hasMindbender = false
    talents.hasPowerWordRadiance = false
    talents.hasPowerWordLife = false
    
    -- War Within Season 2 talents
    talents.hasGlimmerOfDawn = false
    talents.hasStolenPsyche = false
    talents.hasBindingHeals = false
    talents.hasPartingShadow = false
    talents.hasDarkenedDestiny = false
    talents.hasBlessedRecovery = false
    talents.hasCosmicRipple = false
    
    -- Initialize mana
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    
    -- Initialize tracking tables
    atonementActive = {}
    atonementEndTime = {}
    powerWordShieldActive = {}
    powerWordShieldEndTime = {}
    painSuppressionActive = {}
    painSuppressionEndTime = {}
    schismActive = {}
    schismEndTime = {}
    
    -- Initialize ability charges
    penanceCharges = API.GetSpellCharges(spells.PENANCE) or 0
    penanceMaxCharges = API.GetSpellMaxCharges(spells.PENANCE) or 1
    mindBlastCharges = API.GetSpellCharges(spells.MIND_BLAST) or 0
    mindBlastMaxCharges = API.GetSpellMaxCharges(spells.MIND_BLAST) or 1
    powerWordRadianceCharges = API.GetSpellCharges(spells.POWER_WORD_RADIANCE) or 0
    powerWordRadianceMaxCharges = API.GetSpellMaxCharges(spells.POWER_WORD_RADIANCE) or 2
    
    -- Get max group size (needed for calculating atonement percentage)
    maxGroupSize = API.GetMaxGroupSize() or 5
    
    return true
end

-- Register spec-specific settings
function Discipline:RegisterSettings()
    ConfigRegistry:RegisterSettings("DisciplinePriest", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst healing",
                type = "toggle",
                default = true
            },
            aoeEnabled = {
                displayName = "Enable AoE Rotation",
                description = "Use AoE abilities when multiple targets are present",
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
            manaPooling = {
                displayName = "Mana Pooling",
                description = "Pool mana for important abilities",
                type = "toggle",
                default = true
            },
            manaPoolingThreshold = {
                displayName = "Mana Pooling Threshold",
                description = "Minimum mana percentage to maintain",
                type = "slider",
                min = 10,
                max = 70,
                default = 30
            },
            targetSelection = {
                displayName = "Target Selection Method",
                description = "How to select targets for healing",
                type = "dropdown",
                options = {"Lowest Health", "Smart Priority", "Tanks First", "Role Based"},
                default = "Smart Priority"
            },
            usePowerWordFortitude = {
                displayName = "Use Power Word: Fortitude",
                description = "Automatically use Power Word: Fortitude",
                type = "toggle",
                default = true
            },
            maintainAtonementPercent = {
                displayName = "Maintain Atonement %",
                description = "Percentage of group to maintain Atonement on",
                type = "slider",
                min = 20,
                max = 100,
                default = 40
            },
            useSchism = {
                displayName = "Use Schism",
                description = "Automatically use Schism when talented",
                type = "toggle",
                default = true
            },
            atonementMethod = {
                displayName = "Atonement Application Method",
                description = "How to apply Atonement to the group",
                type = "dropdown",
                options = {"Shield Only", "Radiance Only", "Mixed", "Shield Priority", "Radiance Priority"},
                default = "Mixed"
            }
        },
        
        healingSettings = {
            usePowerWordShield = {
                displayName = "Use Power Word: Shield",
                description = "Automatically use Power Word: Shield",
                type = "toggle",
                default = true
            },
            powerWordShieldThreshold = {
                displayName = "Power Word: Shield Health Threshold",
                description = "Health percentage to use Power Word: Shield",
                type = "slider",
                min = 10,
                max = 100,
                default = 95
            },
            useShadowMend = {
                displayName = "Use Shadow Mend",
                description = "Automatically use Shadow Mend for direct healing",
                type = "toggle",
                default = true
            },
            shadowMendThreshold = {
                displayName = "Shadow Mend Health Threshold",
                description = "Health percentage to use Shadow Mend",
                type = "slider",
                min = 10,
                max = 80,
                default = 60
            },
            usePenance = {
                displayName = "Use Penance",
                description = "How to use Penance",
                type = "dropdown",
                options = {"Damage Only", "Healing Only", "Smart"},
                default = "Smart"
            },
            penanceHealingThreshold = {
                displayName = "Penance Healing Threshold",
                description = "Health percentage to use Penance for healing",
                type = "slider",
                min = 10,
                max = 95,
                default = 80
            },
            usePowerWordRadiance = {
                displayName = "Use Power Word: Radiance",
                description = "Automatically use Power Word: Radiance for AoE healing",
                type = "toggle",
                default = true
            },
            powerWordRadianceThreshold = {
                displayName = "Power Word: Radiance Threshold",
                description = "Health percentage to use Power Word: Radiance",
                type = "slider",
                min = 10,
                max = 95,
                default = 75
            },
            usePowerWordRadianceMinTargets = {
                displayName = "Power Word: Radiance Min Targets",
                description = "Minimum injured targets to use Power Word: Radiance",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useHalo = {
                displayName = "Use Halo",
                description = "Automatically use Halo when talented",
                type = "toggle",
                default = true
            },
            haloThreshold = {
                displayName = "Halo Health Threshold",
                description = "Health percentage to use Halo",
                type = "slider",
                min = 10,
                max = 95,
                default = 85
            },
            haloMinTargets = {
                displayName = "Halo Min Targets",
                description = "Minimum injured targets to use Halo",
                type = "slider",
                min = 3,
                max = 10,
                default = 4
            },
            useDivineStar = {
                displayName = "Use Divine Star",
                description = "Automatically use Divine Star when talented",
                type = "toggle",
                default = true
            },
            divineStarThreshold = {
                displayName = "Divine Star Health Threshold",
                description = "Health percentage to use Divine Star",
                type = "slider",
                min = 10,
                max = 95,
                default = 90
            },
            divineStarMinTargets = {
                displayName = "Divine Star Min Targets",
                description = "Minimum injured targets to use Divine Star",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            }
        },
        
        cooldownSettings = {
            usePainSuppression = {
                displayName = "Use Pain Suppression",
                description = "Automatically use Pain Suppression",
                type = "toggle",
                default = true
            },
            painSuppressionThreshold = {
                displayName = "Pain Suppression Health Threshold",
                description = "Health percentage to use Pain Suppression",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useRapture = {
                displayName = "Use Rapture",
                description = "Automatically use Rapture",
                type = "toggle",
                default = true
            },
            raptureThreshold = {
                displayName = "Rapture Activation Threshold",
                description = "Group health percentage to use Rapture",
                type = "slider",
                min = 10,
                max = 85,
                default = 65
            },
            raptureMinTargets = {
                displayName = "Rapture Min Injured Targets",
                description = "Minimum injured targets to use Rapture",
                type = "slider",
                min = 2,
                max = 10,
                default = 4
            },
            usePowerInfusion = {
                displayName = "Use Power Infusion",
                description = "Automatically use Power Infusion",
                type = "toggle",
                default = true
            },
            powerInfusionMode = {
                displayName = "Power Infusion Usage",
                description = "When to use Power Infusion",
                type = "dropdown",
                options = {"Self Only", "On Cooldown", "With Rapture", "Burst Only"},
                default = "With Rapture"
            },
            usePowerWordBarrier = {
                displayName = "Use Power Word: Barrier",
                description = "Automatically use Power Word: Barrier when talented",
                type = "toggle",
                default = true
            },
            powerWordBarrierThreshold = {
                displayName = "Power Word: Barrier Health Threshold",
                description = "Group health percentage to use Power Word: Barrier",
                type = "slider",
                min = 10,
                max = 80,
                default = 50
            },
            powerWordBarrierMinTargets = {
                displayName = "Power Word: Barrier Min Targets",
                description = "Minimum stacked targets to use Power Word: Barrier",
                type = "slider",
                min = 2,
                max = 10,
                default = 4
            },
            useShadowfiend = {
                displayName = "Use Shadowfiend/Mindbender",
                description = "Automatically use Shadowfiend or Mindbender",
                type = "toggle",
                default = true
            },
            shadowfiendMode = {
                displayName = "Shadowfiend/Mindbender Usage",
                description = "When to use Shadowfiend or Mindbender",
                type = "dropdown",
                options = {"Mana Regeneration", "On Cooldown", "With Burst", "Manual Only"},
                default = "Mana Regeneration"
            },
            shadowfiendManaThreshold = {
                displayName = "Shadowfiend Mana Threshold",
                description = "Mana percentage to use Shadowfiend for regeneration",
                type = "slider",
                min = 10,
                max = 80,
                default = 60
            },
            useEvangelism = {
                displayName = "Use Evangelism",
                description = "Automatically use Evangelism when talented",
                type = "toggle",
                default = true
            },
            evangelismThreshold = {
                displayName = "Evangelism Atonement Threshold",
                description = "Percentage of group with Atonement to use Evangelism",
                type = "slider",
                min = 30,
                max = 100,
                default = 70
            },
            useSpiritShell = {
                displayName = "Use Spirit Shell",
                description = "Automatically use Spirit Shell when talented",
                type = "toggle",
                default = true
            },
            spiritShellMode = {
                displayName = "Spirit Shell Usage",
                description = "When to use Spirit Shell",
                type = "dropdown",
                options = {"On Cooldown", "Before Damage", "Burst Only", "Manual Only"},
                default = "Before Damage"
            }
        },
        
        damageSettings = {
            useMindBlast = {
                displayName = "Use Mind Blast",
                description = "Automatically use Mind Blast",
                type = "toggle",
                default = true
            },
            useHolyNova = {
                displayName = "Use Holy Nova",
                description = "Automatically use Holy Nova for AoE damage",
                type = "toggle",
                default = true
            },
            holyNovaMinTargets = {
                displayName = "Holy Nova Min Targets",
                description = "Minimum targets to use Holy Nova",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            useShadowWordDeath = {
                displayName = "Use Shadow Word: Death",
                description = "Automatically use Shadow Word: Death as an execute",
                type = "toggle",
                default = true
            },
            useShadowWordPain = {
                displayName = "Use Shadow Word: Pain/Purge the Wicked",
                description = "Automatically maintain Shadow Word: Pain or Purge the Wicked",
                type = "toggle",
                default = true
            },
            dotMaxTargets = {
                displayName = "Maximum DoT Targets",
                description = "Maximum targets to apply DoTs to",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            }
        },
        
        utilitySettings = {
            useLeapOfFaith = {
                displayName = "Use Leap of Faith",
                description = "Automatically use Leap of Faith to save allies",
                type = "toggle",
                default = true
            },
            leapOfFaithThreshold = {
                displayName = "Leap of Faith Health Threshold",
                description = "Health percentage to use Leap of Faith",
                type = "slider",
                min = 5,
                max = 30,
                default = 15
            },
            useMassDispel = {
                displayName = "Use Mass Dispel",
                description = "Automatically use Mass Dispel against AoE debuffs",
                type = "toggle",
                default = true
            },
            useDispelMagic = {
                displayName = "Use Dispel Magic",
                description = "Automatically use Dispel Magic against enemy buffs",
                type = "toggle",
                default = true
            },
            usePurify = {
                displayName = "Use Purify",
                description = "Automatically use Purify on allies",
                type = "toggle",
                default = true
            },
            useFade = {
                displayName = "Use Fade",
                description = "Automatically use Fade when threatened",
                type = "toggle",
                default = true
            },
            usePsychicScream = {
                displayName = "Use Psychic Scream",
                description = "Automatically use Psychic Scream for AoE fear",
                type = "toggle",
                default = true
            },
            psychicScreamMinTargets = {
                displayName = "Psychic Scream Min Targets",
                description = "Minimum targets to use Psychic Scream",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Rapture controls
            rapture = AAC.RegisterAbility(spells.RAPTURE, {
                enabled = true,
                useDuringBurstOnly = false,
                useDuringEmergenciesOnly = false,
                targetSelectionMode = "Lowest Health"
            }),
            
            -- Pain Suppression controls
            painSuppression = AAC.RegisterAbility(spells.PAIN_SUPPRESSION, {
                enabled = true,
                useDuringBurstOnly = false,
                targetSelectionMode = "Tank Priority",
                emergencyOnly = true
            }),
            
            -- Power Word: Barrier controls
            powerWordBarrier = AAC.RegisterAbility(spells.POWER_WORD_BARRIER, {
                enabled = true,
                useDuringBurstOnly = false,
                placementMode = "Group Center",
                requireTankInside = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Discipline:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
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
        elseif unit == "target" then
            self:UpdateTargetHealth()
        end
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for atonement tracking
    API.RegisterEvent("UNIT_AURA", function(unit) 
        if unit and unit ~= "player" and unit ~= "target" and (UnitInParty(unit) or UnitInRaid(unit)) then
            self:UpdateGroupMemberAuras(unit)
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initialize atonement counts
    self:UpdateAtonementCounts()
    
    return true
end

-- Update talent information
function Discipline:UpdateTalentInfo()
    -- Check for important talents
    talents.hasDarkArchangel = API.HasTalent(spells.DARK_ARCHANGEL)
    talents.hasClarityOfWill = API.HasTalent(spells.CLARITY_OF_WILL)
    talents.hasContrition = API.HasTalent(spells.CONTRITION)
    talents.hasShadowCovenant = API.HasTalent(spells.SHADOW_COVENANT)
    talents.hasLenience = API.HasTalent(spells.LENIENCE)
    talents.hasShieldDiscipline = API.HasTalent(spells.SHIELD_DISCIPLINE)
    talents.hasPremonition = API.HasTalent(spells.PREMONITION)
    talents.hasIndemnity = API.HasTalent(spells.INDEMNITY)
    talents.hasLuminousBarrier = API.HasTalent(spells.LUMINOUS_BARRIER)
    talents.hasSinsSalve = API.HasTalent(spells.SINS_SALVE)
    talents.hasPurgeTheWicked = API.HasTalent(spells.PURGE_THE_WICKED)
    talents.hasSchism = API.HasTalent(spells.SCHISM)
    talents.hasPowerWordBarrier = API.HasTalent(spells.POWER_WORD_BARRIER)
    talents.hasPainSuppression = API.HasTalent(spells.PAIN_SUPPRESSION)
    talents.hasRapture = API.HasTalent(spells.RAPTURE)
    talents.hasDivineStar = API.HasTalent(spells.DIVINE_STAR)
    talents.hasHalo = API.HasTalent(spells.HALO)
    talents.hasPainfulPunishment = API.HasTalent(spells.PAINFUL_PUNISHMENT)
    talents.hasHealingLightning = API.HasTalent(spells.HEALING_LIGHTNING)
    talents.hasLightsPromise = API.HasTalent(spells.LIGHTS_PROMISE)
    talents.hasSpeedOfThePious = API.HasTalent(spells.SPEED_OF_THE_PIOUS)
    talents.hasProtectiveLight = API.HasTalent(spells.PROTECTIVE_LIGHT)
    talents.hasBorrowedTime = API.HasTalent(spells.BORROWED_TIME)
    talents.hasEvangelism = API.HasTalent(spells.EVANGELISM)
    talents.hasSpiritShell = API.HasTalent(spells.SPIRIT_SHELL)
    talents.hasMindbender = API.HasTalent(spells.MINDBENDER)
    talents.hasPowerWordRadiance = API.HasTalent(spells.POWER_WORD_RADIANCE)
    talents.hasPowerWordLife = API.HasTalent(spells.POWER_WORD_LIFE)
    
    -- War Within Season 2 talents
    talents.hasGlimmerOfDawn = API.HasTalent(spells.GLIMMER_OF_DAWN)
    talents.hasStolenPsyche = API.HasTalent(spells.STOLEN_PSYCHE)
    talents.hasBindingHeals = API.HasTalent(spells.BINDING_HEALS)
    talents.hasPartingShadow = API.HasTalent(spells.PARTING_SHADOW)
    talents.hasDarkenedDestiny = API.HasTalent(spells.DARKENED_DESTINY)
    talents.hasBlessedRecovery = API.HasTalent(spells.BLESSED_RECOVERY)
    talents.hasCosmicRipple = API.HasTalent(spells.COSMIC_RIPPLE)
    
    -- Set specialized variables based on talents
    if talents.hasSinsSalve then
        sinsSalve = true
    end
    
    if API.IsSpellKnown(spells.HOLY_NOVA) then
        holyNova = true
    end
    
    if talents.hasPurgeTheWicked then
        purgeTheWicked = true
    end
    
    if talents.hasSchism then
        schism = true
    end
    
    if talents.hasPowerWordBarrier then
        powerWordBarrier = true
    end
    
    if talents.hasPainSuppression then
        painSuppression = true
    end
    
    if talents.hasRapture then
        rapture = true
    end
    
    if talents.hasPremonition then
        premonition = true
    end
    
    if talents.hasPowerWordLife then
        powerWordLife = true
    end
    
    if talents.hasDivineStar then
        divineStar = true
    end
    
    if talents.hasHalo then
        halo = true
    end
    
    if talents.hasLuminousBarrier then
        luminousBarrier = true
    end
    
    if talents.hasLenience then
        lenience = true
    end
    
    if talents.hasIndemnity then
        indemnity = true
    end
    
    if talents.hasContrition then
        contrition = true
    end
    
    if talents.hasShadowCovenant then
        shadowCovenant = true
    end
    
    if talents.hasClarityOfWill then
        clarity = true
    end
    
    if talents.hasEvangelism then
        evangelism = true
    end
    
    if talents.hasSpiritShell then
        spiritShell = true
    end
    
    if talents.hasDarkArchangel then
        darkArchangel = true
    end
    
    if talents.hasMindbender then
        mindbender = true
        fiend = true
    elseif API.IsSpellKnown(spells.SHADOWFIEND) then
        fiend = true
    end
    
    if talents.hasShieldDiscipline then
        shieldDiscipline = true
    end
    
    if talents.hasPainfulPunishment then
        painfulPunishment = true
    end
    
    if talents.hasHealingLightning then
        healingLightning = true
    end
    
    if talents.hasLightsPromise then
        lightsPromise = true
    end
    
    if talents.hasSpeedOfThePious then
        speedOfThePious = true
    end
    
    if API.IsSpellKnown(spells.POWER_WORD_FORTITUDE) then
        powerWordFortitude = true
    end
    
    if API.IsSpellKnown(spells.PENANCE) then
        penance = true
    end
    
    -- Update flash heal cast time based on talents
    flashHealCastTime = 1.5 -- Base cast time
    
    -- Check if we have any haste effects from talents
    if talents.hasSpeedOfThePious then
        -- Approximation for Speed of the Pious effect
        flashHealCastTime = flashHealCastTime * 0.9
    end
    
    API.PrintDebug("Discipline Priest talents updated")
    
    return true
end

-- Update mana tracking
function Discipline:UpdateMana()
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    return true
end

-- Update health tracking
function Discipline:UpdateHealth()
    currentHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Discipline:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update target data
function Discipline:UpdateTargetData()
    -- Check if in range for damage abilities
    inRange = API.IsSpellInRange(spells.SMITE, "target")
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Schism
        if schism then
            local schismInfo = API.GetDebuffInfo(targetGUID, debuffs.SCHISM)
            if schismInfo then
                schismActive[targetGUID] = true
                schismEndTime[targetGUID] = select(6, schismInfo)
            else
                schismActive[targetGUID] = false
                schismEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Shadow Word: Pain or Purge the Wicked
        if purgeTheWicked then
            local purgeTheWickedInfo = API.GetDebuffInfo(targetGUID, debuffs.PURGE_THE_WICKED)
            -- Handle tracking here
        else
            local shadowWordPainInfo = API.GetDebuffInfo(targetGUID, debuffs.SHADOW_WORD_PAIN)
            -- Handle tracking here
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Holy Nova radius
    
    return true
end

-- Update auras for a specific group member
function Discipline:UpdateGroupMemberAuras(unit)
    if not unit then return end
    
    local unitGUID = API.UnitGUID(unit)
    if not unitGUID then return end
    
    -- Check for Atonement
    local atonementInfo = API.UnitHasBuff(unit, buffs.ATONEMENT)
    if atonementInfo then
        atonementActive[unitGUID] = true
        atonementEndTime[unitGUID] = select(6, atonementInfo)
    else
        atonementActive[unitGUID] = false
        atonementEndTime[unitGUID] = 0
    end
    
    -- Check for Power Word: Shield
    local powerWordShieldInfo = API.UnitHasBuff(unit, buffs.POWER_WORD_SHIELD)
    if powerWordShieldInfo then
        powerWordShieldActive[unitGUID] = true
        powerWordShieldEndTime[unitGUID] = select(6, powerWordShieldInfo)
    else
        powerWordShieldActive[unitGUID] = false
        powerWordShieldEndTime[unitGUID] = 0
    end
    
    -- Check for Pain Suppression
    local painSuppressionInfo = API.UnitHasBuff(unit, buffs.PAIN_SUPPRESSION)
    if painSuppressionInfo then
        painSuppressionActive[unitGUID] = true
        painSuppressionEndTime[unitGUID] = select(6, painSuppressionInfo)
    else
        painSuppressionActive[unitGUID] = false
        painSuppressionEndTime[unitGUID] = 0
    end
    
    -- Update atonement percentage after updating a unit's status
    self:UpdateAtonementCounts()
    
    return true
end

-- Update atonement counts and percentage
function Discipline:UpdateAtonementCounts()
    local count = 0
    local groupSize = API.GetGroupSize() or 1
    
    -- Count total atonements active
    for guid, active in pairs(atonementActive) do
        if active and atonementEndTime[guid] > GetTime() then
            count = count + 1
        end
    end
    
    atonementActiveCounts = count
    atonementPercent = (count / groupSize) * 100
    
    return true
end

-- Handle combat log events
function Discipline:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Rapture
            if spellID == buffs.RAPTURE then
                raptureBuff = true
                raptureEndTime = GetTime() + RAPTURE_DURATION
                API.PrintDebug("Rapture activated")
            end
            
            -- Track Power Infusion
            if spellID == buffs.POWER_INFUSION then
                powerInfusionActive = true
                powerInfusionEndTime = GetTime() + POWER_INFUSION_DURATION
                API.PrintDebug("Power Infusion activated")
            end
            
            -- Track Shadow Covenant
            if spellID == buffs.SHADOW_COVENANT then
                shadowCovenantActive = true
                shadowCovenantEndTime = GetTime() + SHADOW_COVENANT_DURATION
                API.PrintDebug("Shadow Covenant activated")
            end
            
            -- Track Borrowed Time
            if spellID == buffs.BORROWED_TIME then
                borrowedTimeActive = true
                borrowedTimeEndTime = GetTime() + BORROWED_TIME_DURATION
                API.PrintDebug("Borrowed Time activated")
            end
            
            -- Track Evangelism
            if spellID == buffs.EVANGELISM then
                evangelismActive = true
                evangelismEndTime = GetTime() + EVANGELISM_DURATION
                API.PrintDebug("Evangelism activated")
            end
            
            -- Track Spirit Shell
            if spellID == buffs.SPIRIT_SHELL then
                spiritShellActive = true
                spiritShellEndTime = GetTime() + SPIRIT_SHELL_DURATION
                API.PrintDebug("Spirit Shell activated")
            end
            
            -- Track Dark Archangel
            if spellID == buffs.DARK_ARCHANGEL then
                darkArchangelActive = true
                darkArchangelEndTime = GetTime() + DARK_ARCHANGEL_DURATION
                API.PrintDebug("Dark Archangel activated")
            end
            
            -- Track Light's Promise
            if spellID == buffs.LIGHTS_PROMISE then
                API.PrintDebug("Light's Promise activated")
            end
            
            -- Track Speed of the Pious
            if spellID == buffs.SPEED_OF_THE_PIOUS then
                API.PrintDebug("Speed of the Pious activated")
            end
            
            -- Track Binding Heals
            if spellID == buffs.BINDING_HEALS then
                API.PrintDebug("Binding Heals activated")
            end
        end
        
        -- Track buffs on any unit
        if spellID == buffs.ATONEMENT then
            atonementActive[destGUID] = true
            atonementEndTime[destGUID] = GetTime() + ATONEMENT_DURATION
            self:UpdateAtonementCounts()
            API.PrintDebug("Atonement applied to " .. destName)
        elseif spellID == buffs.POWER_WORD_SHIELD then
            powerWordShieldActive[destGUID] = true
            powerWordShieldEndTime[destGUID] = GetTime() + POWER_WORD_SHIELD_DURATION
            API.PrintDebug("Power Word: Shield applied to " .. destName)
        elseif spellID == buffs.PAIN_SUPPRESSION then
            painSuppressionActive[destGUID] = true
            painSuppressionEndTime[destGUID] = GetTime() + PAIN_SUPPRESSION_DURATION
            API.PrintDebug("Pain Suppression applied to " .. destName)
        end
        
        -- Track debuffs on any target
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == debuffs.SCHISM then
                schismActive[destGUID] = true
                schismEndTime[destGUID] = GetTime() + SCHISM_DURATION
                API.PrintDebug("Schism applied to " .. destName)
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Rapture
            if spellID == buffs.RAPTURE then
                raptureBuff = false
                API.PrintDebug("Rapture faded")
            end
            
            -- Track Power Infusion
            if spellID == buffs.POWER_INFUSION then
                powerInfusionActive = false
                API.PrintDebug("Power Infusion faded")
            end
            
            -- Track Shadow Covenant
            if spellID == buffs.SHADOW_COVENANT then
                shadowCovenantActive = false
                API.PrintDebug("Shadow Covenant faded")
            end
            
            -- Track Borrowed Time
            if spellID == buffs.BORROWED_TIME then
                borrowedTimeActive = false
                API.PrintDebug("Borrowed Time faded")
            end
            
            -- Track Evangelism
            if spellID == buffs.EVANGELISM then
                evangelismActive = false
                API.PrintDebug("Evangelism faded")
            end
            
            -- Track Spirit Shell
            if spellID == buffs.SPIRIT_SHELL then
                spiritShellActive = false
                API.PrintDebug("Spirit Shell faded")
            end
            
            -- Track Dark Archangel
            if spellID == buffs.DARK_ARCHANGEL then
                darkArchangelActive = false
                API.PrintDebug("Dark Archangel faded")
            end
        end
        
        -- Track buff removals on any unit
        if spellID == buffs.ATONEMENT then
            atonementActive[destGUID] = false
            self:UpdateAtonementCounts()
            API.PrintDebug("Atonement faded from " .. destName)
        elseif spellID == buffs.POWER_WORD_SHIELD then
            powerWordShieldActive[destGUID] = false
            API.PrintDebug("Power Word: Shield faded from " .. destName)
        elseif spellID == buffs.PAIN_SUPPRESSION then
            painSuppressionActive[destGUID] = false
            API.PrintDebug("Pain Suppression faded from " .. destName)
        end
        
        -- Track debuff removals
        if spellID == debuffs.SCHISM and schismActive[destGUID] then
            schismActive[destGUID] = false
            API.PrintDebug("Schism faded from " .. destName)
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.POWER_WORD_SHIELD then
                API.PrintDebug("Power Word: Shield cast")
            elseif spellID == spells.PENANCE then
                penanceCharges = API.GetSpellCharges(spells.PENANCE) or 0
                API.PrintDebug("Penance cast, charges remaining: " .. tostring(penanceCharges))
            elseif spellID == spells.POWER_WORD_RADIANCE then
                powerWordRadianceCharges = API.GetSpellCharges(spells.POWER_WORD_RADIANCE) or 0
                API.PrintDebug("Power Word: Radiance cast, charges remaining: " .. tostring(powerWordRadianceCharges))
            elseif spellID == spells.MIND_BLAST then
                mindBlastCharges = API.GetSpellCharges(spells.MIND_BLAST) or 0
                API.PrintDebug("Mind Blast cast, charges remaining: " .. tostring(mindBlastCharges))
            elseif spellID == spells.RAPTURE then
                raptureBuff = true
                raptureEndTime = GetTime() + RAPTURE_DURATION
                API.PrintDebug("Rapture cast")
            elseif spellID == spells.PAIN_SUPPRESSION then
                painSuppressActive = true
                painSuppressEndTime = GetTime() + PAIN_SUPPRESSION_DURATION
                painSuppressCharges = API.GetSpellCharges(spells.PAIN_SUPPRESSION) or 0
                API.PrintDebug("Pain Suppression cast")
            elseif spellID == spells.POWER_INFUSION then
                powerInfusionActive = true
                powerInfusionEndTime = GetTime() + POWER_INFUSION_DURATION
                API.PrintDebug("Power Infusion cast")
            elseif spellID == spells.POWER_WORD_BARRIER then
                API.PrintDebug("Power Word: Barrier cast")
            elseif spellID == spells.SCHISM then
                API.PrintDebug("Schism cast")
            elseif spellID == spells.EVANGELISM then
                evangelismActive = true
                evangelismEndTime = GetTime() + EVANGELISM_DURATION
                API.PrintDebug("Evangelism cast")
            elseif spellID == spells.SPIRIT_SHELL then
                spiritShellActive = true
                spiritShellEndTime = GetTime() + SPIRIT_SHELL_DURATION
                API.PrintDebug("Spirit Shell cast")
            elseif spellID == spells.SHADOWFIEND then
                shadowfiendActive = true
                shadowfiendEndTime = GetTime() + SHADOWFIEND_DURATION
                API.PrintDebug("Shadowfiend cast")
            elseif spellID == spells.MINDBENDER then
                mindbenderActive = true
                mindbenderEndTime = GetTime() + MINDBENDER_DURATION
                API.PrintDebug("Mindbender cast")
            elseif spellID == spells.POWER_WORD_LIFE then
                API.PrintDebug("Power Word: Life cast")
            elseif spellID == spells.SHADOW_WORD_DEATH then
                API.PrintDebug("Shadow Word: Death cast")
            end
        end
    end
    
    -- Track Glimmer of Dawn
    if talents.hasGlimmerOfDawn and 
       eventType == "SPELL_HEAL" and
       sourceGUID == API.GetPlayerGUID() and
       spellID == spells.GLIMMER_OF_DAWN then
        glimmerOfDawnCount = glimmerOfDawnCount + 1
        glimmerOfDawnActive = true
        API.PrintDebug("Glimmer of Dawn healing: " .. tostring(glimmerOfDawnCount))
    end
    
    return true
end

-- Main rotation function
function Discipline:RunRotation()
    -- Check if we should be running Discipline Priest logic
    if API.GetActiveSpecID() ~= DISCIPLINE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("DisciplinePriest")
    
    -- Update variables
    self:UpdateMana()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    self:UpdateAtonementCounts() -- Make sure we have latest atonement counts
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Check for Power Word: Fortitude
    if powerWordFortitude and
       settings.rotationSettings.usePowerWordFortitude and
       not API.GroupHasBuff(buffs.POWER_WORD_FORTITUDE) and
       API.CanCast(spells.POWER_WORD_FORTITUDE) then
        API.CastSpell(spells.POWER_WORD_FORTITUDE)
        return true
    end
    
    -- Handle emergency healing
    if self:HandleEmergencyHealing(settings) then
        return true
    end
    
    -- Handle cooldowns
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle atonement setup
    if self:HandleAtonementSetup(settings) then
        return true
    end
    
    -- Handle healing rotations
    if self:HandleHealing(settings) then
        return true
    end
    
    -- Handle damage rotations when no healing needed
    if inRange then
        return self:HandleDamage(settings)
    end
    
    return false
end

-- Handle emergency healing
function Discipline:HandleEmergencyHealing(settings)
    -- Get lowest health group member
    local lowestUnit, lowestHealth = API.GetLowestHealthGroupMember()
    
    if lowestUnit and lowestHealth < 30 then
        local lowestUnitGUID = API.UnitGUID(lowestUnit)
        
        -- Check if target already has Pain Suppression
        if painSuppression and
           settings.cooldownSettings.usePainSuppression and
           lowestHealth <= settings.cooldownSettings.painSuppressionThreshold and
           not painSuppressionActive[lowestUnitGUID] and
           settings.abilityControls.painSuppression.enabled and
           API.CanCast(spells.PAIN_SUPPRESSION) then
           
            -- Check for tank priority
            local shouldCast = true
            if settings.abilityControls.painSuppression.targetSelectionMode == "Tank Priority" then
                shouldCast = API.UnitIsTank(lowestUnit)
            end
            
            if shouldCast and settings.abilityControls.painSuppression.emergencyOnly then
                API.CastSpellOnUnit(spells.PAIN_SUPPRESSION, lowestUnit)
                return true
            end
        end
        
        -- Use Power Word: Life if available (very low health)
        if powerWordLife and
           lowestHealth < 35 and
           API.CanCast(spells.POWER_WORD_LIFE) then
            API.CastSpellOnUnit(spells.POWER_WORD_LIFE, lowestUnit)
            return true
        end
        
        -- Use Shadow Mend for emergency direct healing
        if settings.healingSettings.useShadowMend and
           lowestHealth <= settings.healingSettings.shadowMendThreshold and
           API.CanCast(spells.SHADOW_MEND) then
            API.CastSpellOnUnit(spells.SHADOW_MEND, lowestUnit)
            return true
        end
    end
    
    return false
end

-- Handle cooldowns
function Discipline:HandleCooldowns(settings)
    -- Get overall group status
    local lowestUnit, lowestHealth = API.GetLowestHealthGroupMember()
    local averageGroupHealth = API.GetAverageGroupHealth()
    local injuredCount = API.GetInjuredGroupMembersCount(85)
    
    -- Use Rapture
    if rapture and
       settings.cooldownSettings.useRapture and
       settings.abilityControls.rapture.enabled and
       not raptureBuff and
       averageGroupHealth <= settings.cooldownSettings.raptureThreshold and
       injuredCount >= settings.cooldownSettings.raptureMinTargets and
       API.CanCast(spells.RAPTURE) then
        
        -- Check ability control settings
        if (not settings.abilityControls.rapture.useDuringBurstOnly or burstModeActive) and
           (not settings.abilityControls.rapture.useDuringEmergenciesOnly or lowestHealth < 50) then
            API.CastSpell(spells.RAPTURE)
            return true
        end
    end
    
    -- Use Power Infusion
    if settings.cooldownSettings.usePowerInfusion and
       not powerInfusionActive and
       API.CanCast(spells.POWER_INFUSION) then
        
        local shouldUsePowerInfusion = false
        
        if settings.cooldownSettings.powerInfusionMode == "Self Only" then
            shouldUsePowerInfusion = true
        elseif settings.cooldownSettings.powerInfusionMode == "On Cooldown" then
            shouldUsePowerInfusion = true
        elseif settings.cooldownSettings.powerInfusionMode == "With Rapture" then
            shouldUsePowerInfusion = raptureBuff
        elseif settings.cooldownSettings.powerInfusionMode == "Burst Only" then
            shouldUsePowerInfusion = burstModeActive
        end
        
        if shouldUsePowerInfusion then
            API.CastSpellOnUnit(spells.POWER_INFUSION, "player")
            return true
        end
    end
    
    -- Use Power Word: Barrier
    if powerWordBarrier and
       settings.cooldownSettings.usePowerWordBarrier and
       settings.abilityControls.powerWordBarrier.enabled and
       averageGroupHealth <= settings.cooldownSettings.powerWordBarrierThreshold and
       API.GetStackedGroupMembersCount() >= settings.cooldownSettings.powerWordBarrierMinTargets and
       API.CanCast(spells.POWER_WORD_BARRIER) then
        
        local placementTarget = "player"
        
        if settings.abilityControls.powerWordBarrier.placementMode == "Group Center" then
            placementTarget = API.GetGroupCenter()
        elseif settings.abilityControls.powerWordBarrier.placementMode == "On Tank" and settings.abilityControls.powerWordBarrier.requireTankInside then
            local tank = API.GetTank()
            if tank then
                placementTarget = tank
            end
        end
        
        API.CastSpellOnUnit(spells.POWER_WORD_BARRIER, placementTarget)
        return true
    end
    
    -- Use Shadowfiend/Mindbender
    if fiend and
       settings.cooldownSettings.useShadowfiend then
        
        local shouldUseShadowfiend = false
        local spellToUse = mindbender and spells.MINDBENDER or spells.SHADOWFIEND
        
        if settings.cooldownSettings.shadowfiendMode == "Mana Regeneration" then
            local manaPercent = (currentMana / maxMana) * 100
            shouldUseShadowfiend = manaPercent <= settings.cooldownSettings.shadowfiendManaThreshold
        elseif settings.cooldownSettings.shadowfiendMode == "On Cooldown" then
            shouldUseShadowfiend = true
        elseif settings.cooldownSettings.shadowfiendMode == "With Burst" then
            shouldUseShadowfiend = burstModeActive
        end
        
        if shouldUseShadowfiend and API.CanCast(spellToUse) then
            API.CastSpellAtTarget(spellToUse)
            return true
        end
    end
    
    -- Use Evangelism to extend Atonement
    if evangelism and
       settings.cooldownSettings.useEvangelism and
       atonementPercent >= settings.cooldownSettings.evangelismThreshold and
       atonementActiveCounts >= 3 and
       API.CanCast(spells.EVANGELISM) then
        API.CastSpell(spells.EVANGELISM)
        return true
    end
    
    -- Use Spirit Shell
    if spiritShell and
       settings.cooldownSettings.useSpiritShell and
       not spiritShellActive and
       API.CanCast(spells.SPIRIT_SHELL) then
        
        local shouldUseSpiritShell = false
        
        if settings.cooldownSettings.spiritShellMode == "On Cooldown" then
            shouldUseSpiritShell = true
        elseif settings.cooldownSettings.spiritShellMode == "Before Damage" then
            shouldUseSpiritShell = API.IsBigDamageIncoming()
        elseif settings.cooldownSettings.spiritShellMode == "Burst Only" then
            shouldUseSpiritShell = burstModeActive
        end
        
        if shouldUseSpiritShell then
            API.CastSpell(spells.SPIRIT_SHELL)
            return true
        end
    end
    
    return false
end

-- Handle atonement setup
function Discipline:HandleAtonementSetup(settings)
    -- Calculate current atonement percentage
    if atonementPercent < settings.rotationSettings.maintainAtonementPercent then
        -- Apply Atonement based on method
        local method = settings.rotationSettings.atonementMethod
        
        -- Get a target for Atonement that doesn't already have it
        local needsAtonementUnit = self:GetUnitNeedingAtonement()
        
        if needsAtonementUnit then
            local unitGUID = API.UnitGUID(needsAtonementUnit)
            
            -- Shield Priority or Shield Only method
            if (method == "Shield Only" or method == "Shield Priority" or method == "Mixed") and
               settings.healingSettings.usePowerWordShield and
               API.CanCast(spells.POWER_WORD_SHIELD) and
               (not powerWordShieldActive[unitGUID] or raptureBuff) then
                API.CastSpellOnUnit(spells.POWER_WORD_SHIELD, needsAtonementUnit)
                return true
            end
            
            -- Radiance Priority, Radiance Only, or Mixed method (and not already used Shield)
            if (method == "Radiance Only" or method == "Radiance Priority" or method == "Mixed") and
               talents.hasPowerWordRadiance and
               settings.healingSettings.usePowerWordRadiance and
               powerWordRadianceCharges > 0 and
               API.CanCast(spells.POWER_WORD_RADIANCE) then
                
                -- Find a target that would hit the most people without Atonement
                local bestRadianceTarget = self:GetBestRadianceTarget()
                if bestRadianceTarget then
                    API.CastSpellOnUnit(spells.POWER_WORD_RADIANCE, bestRadianceTarget)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle healing
function Discipline:HandleHealing(settings)
    -- Get lowest health group member
    local lowestUnit, lowestHealth = API.GetLowestHealthGroupMember()
    
    -- Use Divine Star for healing
    if divineStar and
       settings.healingSettings.useDivineStar and
       API.GetInjuredGroupMembersCount(settings.healingSettings.divineStarThreshold) >= settings.healingSettings.divineStarMinTargets and
       API.CanCast(spells.DIVINE_STAR) then
        API.CastSpellInFrontOfPlayer(spells.DIVINE_STAR)
        return true
    end
    
    -- Use Halo for healing
    if halo and
       settings.healingSettings.useHalo and
       API.GetInjuredGroupMembersCount(settings.healingSettings.haloThreshold) >= settings.healingSettings.haloMinTargets and
       API.CanCast(spells.HALO) then
        API.CastSpell(spells.HALO)
        return true
    end
    
    -- Use Power Word: Shield on low health targets
    if settings.healingSettings.usePowerWordShield and
       lowestUnit and lowestHealth <= settings.healingSettings.powerWordShieldThreshold then
        
        local unitGUID = API.UnitGUID(lowestUnit)
        
        if (not powerWordShieldActive[unitGUID] or raptureBuff) and
           API.CanCast(spells.POWER_WORD_SHIELD) then
            API.CastSpellOnUnit(spells.POWER_WORD_SHIELD, lowestUnit)
            return true
        end
    end
    
    -- Use Shadow Mend for direct healing on low health targets
    if settings.healingSettings.useShadowMend and
       lowestUnit and lowestHealth <= settings.healingSettings.shadowMendThreshold and
       API.CanCast(spells.SHADOW_MEND) then
        API.CastSpellOnUnit(spells.SHADOW_MEND, lowestUnit)
        return true
    end
    
    -- Use Penance for healing
    if penance and
       penanceCharges > 0 and
       lowestUnit and lowestHealth <= settings.healingSettings.penanceHealingThreshold and
       (settings.healingSettings.usePenance == "Healing Only" or 
        (settings.healingSettings.usePenance == "Smart" and lowestHealth < 80)) and
       API.CanCast(spells.PENANCE) then
        API.CastSpellOnUnit(spells.PENANCE, lowestUnit)
        return true
    end
    
    -- No emergency healing needed, check for atonement healing opportunities
    if atonementActiveCounts > 0 and inRange then
        -- Use Schism for increased healing through atonement
        if schism and
           settings.rotationSettings.useSchism and
           API.CanCast(spells.SCHISM) then
            
            local targetGUID = API.GetTargetGUID()
            
            if targetGUID and (not schismActive[targetGUID] or schismEndTime[targetGUID] - GetTime() < 3) then
                API.CastSpell(spells.SCHISM)
                return true
            end
        end
        
        -- Use Mind Blast for atonement healing
        if settings.damageSettings.useMindBlast and
           mindBlastCharges > 0 and
           API.CanCast(spells.MIND_BLAST) then
            API.CastSpell(spells.MIND_BLAST)
            return true
        end
        
        -- Use Penance for atonement healing if not needed for direct healing
        if penance and
           penanceCharges > 0 and
           settings.healingSettings.usePenance ~= "Healing Only" and
           API.CanCast(spells.PENANCE) then
            API.CastSpell(spells.PENANCE)
            return true
        end
    end
    
    return false
end

-- Handle damage rotation
function Discipline:HandleDamage(settings)
    -- Maintain Shadow Word: Pain/Purge the Wicked
    if settings.damageSettings.useShadowWordPain then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID then
            local spellToCast = purgeTheWicked ? spells.PURGE_THE_WICKED : spells.SHADOW_WORD_PAIN
            local debuffToCheck = purgeTheWicked ? debuffs.PURGE_THE_WICKED : debuffs.SHADOW_WORD_PAIN
            
            local dotInfo = API.GetDebuffInfo(targetGUID, debuffToCheck)
            if not dotInfo or select(6, dotInfo) - GetTime() < 4 then
                if API.CanCast(spellToCast) then
                    API.CastSpell(spellToCast)
                    return true
                end
            end
        end
    end
    
    -- Use Holy Nova for AoE damage
    if holyNova and
       settings.damageSettings.useHolyNova and
       currentAoETargets >= settings.damageSettings.holyNovaMinTargets and
       API.CanCast(spells.HOLY_NOVA) then
        API.CastSpell(spells.HOLY_NOVA)
        return true
    end
    
    -- Use Shadow Word: Death as an execute
    if settings.damageSettings.useShadowWordDeath and
       targetHealth <= 20 and
       API.CanCast(spells.SHADOW_WORD_DEATH) then
        API.CastSpell(spells.SHADOW_WORD_DEATH)
        return true
    end
    
    -- Use Smite as a filler ability to generate atonement healing
    if API.CanCast(spells.SMITE) then
        API.CastSpell(spells.SMITE)
        return true
    end
    
    return false
end

-- Get a unit that needs Atonement
function Discipline:GetUnitNeedingAtonement()
    local nearExpirationThreshold = 3 -- seconds
    
    -- Check group members for those without atonement or with atonement about to expire
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            local unitGUID = API.UnitGUID(unit)
            
            if not atonementActive[unitGUID] or 
               (atonementEndTime[unitGUID] and GetTime() > atonementEndTime[unitGUID] - nearExpirationThreshold) then
                return unit
            end
        end
    end
    
    return nil
end

-- Find the best target for Power Word: Radiance
function Discipline:GetBestRadianceTarget()
    local mostNeedingCount = 0
    local bestTarget = nil
    
    -- Check each group member for how many nearby allies would get atonement
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            local nearbyWithoutAtonement = self:CountNearbyWithoutAtonement(unit)
            
            if nearbyWithoutAtonement > mostNeedingCount then
                mostNeedingCount = nearbyWithoutAtonement
                bestTarget = unit
            end
        end
    end
    
    -- Find at least 3 targets that need atonement
    if mostNeedingCount >= 3 then
        return bestTarget
    end
    
    return nil
end

-- Count how many allies near a unit don't have atonement
function Discipline:CountNearbyWithoutAtonement(unit)
    local count = 0
    
    for i = 1, API.GetGroupSize() do
        local checkUnit
        if API.IsInRaid() then
            checkUnit = "raid" .. i
        else
            checkUnit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(checkUnit) and not API.UnitIsDead(checkUnit) then
            -- Check if unit is within range of Power Word: Radiance (30 yards)
            if API.GetUnitDistance(unit, checkUnit) <= 30 then
                local unitGUID = API.UnitGUID(checkUnit)
                
                if not atonementActive[unitGUID] then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

-- Handle specialization change
function Discipline:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentMana = 0
    maxMana = 100
    atonementActive = {}
    atonementEndTime = {}
    powerWordShieldActive = {}
    powerWordShieldEndTime = {}
    painSuppressionActive = {}
    painSuppressionEndTime = {}
    raptureBuff = false
    raptureEndTime = 0
    powerInfusionActive = false
    powerInfusionEndTime = 0
    shadowCovenantActive = false
    shadowCovenantEndTime = 0
    mindBlastCharges = 0
    mindBlastMaxCharges = 0
    mindbenderActive = false
    mindbenderEndTime = 0
    borrowedTimeActive = false
    borrowedTimeEndTime = 0
    painSuppressActive = false
    painSuppressEndTime = 0
    painSuppressCharges = 0
    glimmerOfDawnActive = false
    glimmerOfDawnCount = 0
    shadowfiendActive = false
    shadowfiendEndTime = 0
    evangelismActive = false
    evangelismEndTime = 0
    spiritShellActive = false
    spiritShellEndTime = 0
    flashHealCastTime = 1.5
    penanceCharges = 0
    penanceMaxCharges = 0
    darkArchangelActive = false
    darkArchangelEndTime = 0
    schismActive = {}
    schismEndTime = {}
    powerWordRadianceCharges = 0
    powerWordRadianceMaxCharges = 0
    sinsSalve = false
    holyNova = false
    purgeTheWicked = false
    schism = false
    powerWordBarrier = false
    painSuppression = false
    rapture = false
    premonition = false
    powerWordLife = false
    divineStar = false
    halo = false
    luminousBarrier = false
    lenience = false
    indemnity = false
    contrition = false
    shadowCovenant = false
    clarity = false
    atonementPercent = 0
    evangelism = false
    spiritShell = false
    darkArchangel = false
    mindbender = false
    fiend = false
    shieldDiscipline = false
    painfulPunishment = false
    healingLightning = false
    lightsPromise = false
    speedOfThePious = false
    powerWordFortitude = false
    rampPartners = {}
    rampTarget = nil
    currentHealth = 100
    inRange = false
    targetHealth = 100
    atonementActiveCounts = 0
    maxGroupSize = 10
    penance = false
    
    API.PrintDebug("Discipline Priest state reset on spec change")
    
    return true
end

-- Return the module for loading
return Discipline