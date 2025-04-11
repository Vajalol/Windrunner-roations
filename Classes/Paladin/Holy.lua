------------------------------------------
-- WindrunnerRotations - Holy Paladin Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Holy = {}
-- This will be assigned to addon.Classes.Paladin.Holy when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Paladin

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentManaPct = 100
local currentHolyPower = 0
local maxHolyPower = 5
local beaconTargets = {}
local glimmerTargets = {}
local lightOfDawnTargets = {}
local holyShockCritChance = 0
local divineProtectionActive = false
local divineProtectionEndTime = 0
local avengingWrathActive = false
local avengingWrathEndTime = 0
local holyAvenger = false
local holyAvengerActive = false
local holyAvengerEndTime = 0
local infusionActive = false
local infusionEndTime = 0
local infusionOfLightStacks = 0
local divinePurposeActive = false
local divinePurposeEndTime = 0
local glimmerOfLightActive = false
local divineFavorActive = false
local divineFavorEndTime = 0
local avengingCrusaderActive = false
local avengingCrusaderEndTime = 0
local blessingOfDawnActive = false
local blessingOfDawnEndTime = 0
local blessingOfDuskActive = false
local blessingOfDuskEndTime = 0
local awakeningActive = false
local awakeningEndTime = 0
local ashenHallowActive = false
local ashenHallowEndTime = 0
local divineToilActive = false
local divineToilEndTime = 0
local beaconOfVirtueActive = false
local beaconOfVirtueEndTime = 0
local restorationFlameActive = false
local restorationFlameEndTime = 0
local selflessHealer = false
local selflessHealerStacks = 0
local selflessHealerActive = false
local maraadsDyingBreath = false
local healingHandsActive = false
local healingHandsEndTime = 0
local beaconOfFaith = false
local beaconOfVirtue = false
local divineResonance = false
local beaconOfYore = false
local sacredArbiter = false
local lightsHammer = false
local awakening = false
local holyPrism = false
local divineProtection = false
local holyLight = false
local flashOfLight = false
local wordOfGlory = false
local lightOfDawn = false
local holyShock = false
local judgement = false
local crusaderStrike = false
local divineToil = false
local bestowFaith = false
local blessingOfSacrifice = false
local blessingOfProtection = false
local layOnHands = false
local hammerOfWrath = false
local consecration = false
local divineFavor = false
local avengingCrusader = false
local beaconOfLight = false
local avengingWrath = false
local beaconRoyal = false
local beacon = false
local radiatingLight = false
local restorationFlame = false
local divinePurpose = false
local devotionAura = false
local healingHands = false
local glimmerOfLight = false
local lastHolyShock = 0
local lastCrusaderStrike = 0
local lastJudgement = 0
local lastLayOnHands = 0
local lastWordOfGlory = 0
local lastLightOfDawn = 0
local lastHammerOfWrath = 0
local lastAvengingWrath = 0
local lastBestowFaith = 0
local lastHolyLight = 0
local lastFlashOfLight = 0
local lowHealthAllyCount = 0
local criticalHealthAllyCount = 0
local inRange = false
local targetHealth = 100
local lightOfTheMartyr = false
local beaconTransfer = 0.4 -- 40% beacon transfer baseline
local isInMelee = false
local meleeRange = 5 -- yards

-- Constants
local HOLY_SPEC_ID = 65
local HOLY_SHOCK_BASE_CD = 7.5 -- seconds
local CRUSADER_STRIKE_BASE_CD = 6.0 -- seconds
local BESTOW_FAITH_BASE_CD = 12.0 -- seconds
local JUDGMENT_BASE_CD = 12.0 -- seconds
local HAMMER_OF_WRATH_BASE_CD = 7.5 -- seconds
local LIGHT_OF_DAWN_BASE_CD = 12.0 -- seconds
local AVENGING_WRATH_BASE_CD = 120.0 -- seconds
local AVENGING_WRATH_DURATION = 20.0 -- seconds
local BEACON_OF_LIGHT_BASE_CD = 0.0 -- seconds (no CD, just GCD)
local BEACON_OF_FAITH_BASE_CD = 0.0 -- seconds (no CD, just GCD)
local BEACON_OF_VIRTUE_BASE_CD = 15.0 -- seconds
local BEACON_OF_VIRTUE_DURATION = 8.0 -- seconds
local HOLY_AVENGER_BASE_CD = 180.0 -- seconds
local HOLY_AVENGER_DURATION = 20.0 -- seconds
local DIVINE_PROTECTION_BASE_CD = 60.0 -- seconds
local DIVINE_PROTECTION_DURATION = 8.0 -- seconds
local AVENGING_CRUSADER_BASE_CD = 120.0 -- seconds
local AVENGING_CRUSADER_DURATION = 20.0 -- seconds
local ASHEN_HALLOW_BASE_CD = 240.0 -- seconds
local ASHEN_HALLOW_DURATION = 30.0 -- seconds
local DIVINE_FAVOR_BASE_CD = 45.0 -- seconds
local DIVINE_FAVOR_DURATION = 20.0 -- seconds
local BLESSING_OF_DAWN_DURATION = 15.0 -- seconds
local BLESSING_OF_DUSK_DURATION = 15.0 -- seconds
local AWAKENING_DURATION = 15.0 -- seconds
local DIVINE_TOIL_BASE_CD = 30.0 -- seconds
local HEALING_HANDS_DURATION = 15.0 -- seconds
local RESTORATION_FLAME_DURATION = 5.0 -- seconds

-- Initialize the Holy module
function Holy:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Holy Paladin module initialized")
    
    return true
end

-- Register spell IDs
function Holy:RegisterSpells()
    -- Core healing abilities
    spells.HOLY_SHOCK = 20473
    spells.HOLY_LIGHT = 82326
    spells.FLASH_OF_LIGHT = 19750
    spells.WORD_OF_GLORY = 85673
    spells.LIGHT_OF_DAWN = 85222
    spells.LIGHT_OF_THE_MARTYR = 183998
    spells.BESTOW_FAITH = 223306
    spells.BEACON_OF_LIGHT = 53563
    spells.BEACON_OF_FAITH = 156910
    spells.BEACON_OF_VIRTUE = 200025
    spells.HOLY_PRISM = 114165
    spells.LIGHTS_HAMMER = 114158
    spells.BLESSING_OF_SACRIFICE = 6940
    spells.BLESSING_OF_PROTECTION = 1022
    spells.LAY_ON_HANDS = 633
    spells.DIVINE_SHIELD = 642
    spells.DEVOTION_AURA = 465
    
    -- Core offensive abilities
    spells.CRUSADER_STRIKE = 35395
    spells.JUDGMENT = 275773
    spells.HAMMER_OF_WRATH = 24275
    spells.CONSECRATION = 26573
    
    -- Cooldowns
    spells.AVENGING_WRATH = 31884
    spells.DIVINE_PROTECTION = 498
    spells.HOLY_AVENGER = 105809
    spells.AVENGING_CRUSADER = 216331
    spells.DIVINE_FAVOR = 210294
    spells.DIVINE_TOIL = 384810
    
    -- Talents and passives
    spells.INFUSION_OF_LIGHT = 53576
    spells.DIVINE_PURPOSE = 223817
    spells.GLIMMER_OF_LIGHT = 325966
    spells.BEACON_OF_FAITH = 156910
    spells.BEACON_OF_VIRTUE = 200025
    spells.DIVINE_RESONANCE = 386738
    spells.BLESSING_OF_DAWN = 384909
    spells.BLESSING_OF_DUSK = 385126
    spells.AWAKENING = 385831
    spells.MARAADS_DYING_BREATH = 388196
    spells.HEALING_HANDS = 391054
    spells.BEACON_OF_YORE = 385980
    spells.SACRED_ARBITER = 392913
    spells.SELFLESS_HEALER = 392951
    spells.RADIATING_LIGHT = 384127
    spells.ENLIGHTENMENT = 384576
    spells.RESTORATION_FLAME = 387926
    spells.BEACON_ROYAL = 394708
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.DIVINE_TOLL = 375576
    spells.ASHEN_HALLOW = 316958
    
    -- Buff IDs
    spells.BEACON_OF_LIGHT_BUFF = 53563
    spells.BEACON_OF_FAITH_BUFF = 156910
    spells.BEACON_OF_VIRTUE_BUFF = 200025
    spells.INFUSION_OF_LIGHT_BUFF = 54149
    spells.DIVINE_PURPOSE_BUFF = 223819
    spells.GLIMMER_OF_LIGHT_BUFF = 287280
    spells.DIVINE_FAVOR_BUFF = 210294
    spells.AVENGING_WRATH_BUFF = 31884
    spells.AVENGING_CRUSADER_BUFF = 216331
    spells.HOLY_AVENGER_BUFF = 105809
    spells.DIVINE_PROTECTION_BUFF = 498
    spells.BLESSING_OF_DAWN_BUFF = 384909
    spells.BLESSING_OF_DUSK_BUFF = 385126
    spells.AWAKENING_BUFF = 385833
    spells.ASHEN_HALLOW_BUFF = 316958
    spells.DIVINE_TOIL_BUFF = 384810
    spells.SELFLESS_HEALER_BUFF = 114250
    spells.HEALING_HANDS_BUFF = 391054
    spells.RESTORATION_FLAME_BUFF = 387926
    
    -- Debuff IDs
    spells.JUDGMENT_DEBUFF = 197277
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.BEACON_OF_LIGHT = spells.BEACON_OF_LIGHT_BUFF
    buffs.BEACON_OF_FAITH = spells.BEACON_OF_FAITH_BUFF
    buffs.BEACON_OF_VIRTUE = spells.BEACON_OF_VIRTUE_BUFF
    buffs.INFUSION_OF_LIGHT = spells.INFUSION_OF_LIGHT_BUFF
    buffs.DIVINE_PURPOSE = spells.DIVINE_PURPOSE_BUFF
    buffs.GLIMMER_OF_LIGHT = spells.GLIMMER_OF_LIGHT_BUFF
    buffs.DIVINE_FAVOR = spells.DIVINE_FAVOR_BUFF
    buffs.AVENGING_WRATH = spells.AVENGING_WRATH_BUFF
    buffs.AVENGING_CRUSADER = spells.AVENGING_CRUSADER_BUFF
    buffs.HOLY_AVENGER = spells.HOLY_AVENGER_BUFF
    buffs.DIVINE_PROTECTION = spells.DIVINE_PROTECTION_BUFF
    buffs.BLESSING_OF_DAWN = spells.BLESSING_OF_DAWN_BUFF
    buffs.BLESSING_OF_DUSK = spells.BLESSING_OF_DUSK_BUFF
    buffs.AWAKENING = spells.AWAKENING_BUFF
    buffs.ASHEN_HALLOW = spells.ASHEN_HALLOW_BUFF
    buffs.DIVINE_TOIL = spells.DIVINE_TOIL_BUFF
    buffs.SELFLESS_HEALER = spells.SELFLESS_HEALER_BUFF
    buffs.HEALING_HANDS = spells.HEALING_HANDS_BUFF
    buffs.RESTORATION_FLAME = spells.RESTORATION_FLAME_BUFF
    
    debuffs.JUDGMENT = spells.JUDGMENT_DEBUFF
    
    return true
end

-- Register variables to track
function Holy:RegisterVariables()
    -- Talent tracking
    talents.hasInfusionOfLight = false
    talents.hasDivinePurpose = false
    talents.hasGlimmerOfLight = false
    talents.hasBeaconOfFaith = false
    talents.hasBeaconOfVirtue = false
    talents.hasDivineResonance = false
    talents.hasBlessingOfDawn = false
    talents.hasBlessingOfDusk = false
    talents.hasAwakening = false
    talents.hasMaraadsDyingBreath = false
    talents.hasHealingHands = false
    talents.hasBeaconOfYore = false
    talents.hasSacredArbiter = false
    talents.hasSelflessHealer = false
    talents.hasRadiatingLight = false
    talents.hasEnlightenment = false
    talents.hasRestorationFlame = false
    talents.hasBeaconRoyal = false
    talents.hasHolyPrism = false
    talents.hasLightsHammer = false
    talents.hasHolyAvenger = false
    talents.hasDivineFavor = false
    talents.hasAvengingCrusader = false
    talents.hasDivineToll = false
    talents.hasAshenHallow = false
    talents.hasDivineToil = false
    
    -- Initialize resources
    currentManaPct = 100
    currentHolyPower = API.GetPlayerPower() or 0
    maxHolyPower = 5 -- Default, could be higher if talented
    
    -- Initialize tracking tables
    beaconTargets = {}
    glimmerTargets = {}
    lightOfDawnTargets = {}
    
    -- Track if in melee range
    isInMelee = false
    
    return true
end

-- Register spec-specific settings
function Holy:RegisterSettings()
    ConfigRegistry:RegisterSettings("HolyPaladin", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst healing",
                type = "toggle",
                default = true
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
            holyShockPriority = {
                displayName = "Holy Shock Priority",
                description = "How to prioritize Holy Shock",
                type = "dropdown",
                options = {"Healing Only", "Damage Only", "Smart Priority", "Always Heal"},
                default = "Smart Priority"
            },
            meleeWeaving = {
                displayName = "Enable Melee Weaving",
                description = "Use melee abilities to generate Holy Power",
                type = "toggle",
                default = true
            },
            judgmentWeaving = {
                displayName = "Enable Judgment Weaving",
                description = "Use Judgment on cooldown",
                type = "toggle",
                default = true
            },
            healthThreshold = {
                displayName = "Health Threshold",
                description = "Health percentage to consider an ally injured",
                type = "slider",
                min = 50,
                max = 95,
                default = 85
            },
            criticalHealthThreshold = {
                displayName = "Critical Health Threshold",
                description = "Health percentage to consider an ally in critical condition",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            targetSelection = {
                displayName = "Target Selection Method",
                description = "How to select targets for healing",
                type = "dropdown",
                options = {"Lowest Health", "Smart Priority", "Tanks First", "Role Based"},
                default = "Smart Priority"
            },
            glimmerManagement = {
                displayName = "Glimmer Management",
                description = "How to manage Glimmer of Light",
                type = "dropdown",
                options = {"Maintain on Tank Only", "Maintain on Melee", "Maintain on All", "Smart Priority"},
                default = "Smart Priority"
            },
            glimmerTargetCount = {
                displayName = "Glimmer Target Count",
                description = "Number of targets to maintain Glimmer on",
                type = "slider",
                min = 1,
                max = 8,
                default = 5
            },
            useHealingRacials = {
                displayName = "Use Healing Racials",
                description = "Automatically use racial abilities when appropriate",
                type = "toggle",
                default = true
            }
        },
        
        abilitySettings = {
            useBestowFaith = {
                displayName = "Use Bestow Faith",
                description = "Automatically use Bestow Faith",
                type = "toggle",
                default = true
            },
            bestowFaithTarget = {
                displayName = "Bestow Faith Target",
                description = "Who to target with Bestow Faith",
                type = "dropdown",
                options = {"Tank", "Lowest Health", "Self", "Smart Priority"},
                default = "Tank"
            },
            useWordOfGlory = {
                displayName = "Use Word of Glory",
                description = "Automatically use Word of Glory",
                type = "toggle",
                default = true
            },
            wordOfGloryThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory",
                type = "slider",
                min = 10,
                max = 90,
                default = 65
            },
            useLightOfDawn = {
                displayName = "Use Light of Dawn",
                description = "Automatically use Light of Dawn",
                type = "toggle",
                default = true
            },
            lightOfDawnMinTargets = {
                displayName = "Light of Dawn Min Targets",
                description = "Minimum injured targets to use Light of Dawn",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            lightOfDawnThreshold = {
                displayName = "Light of Dawn Health Threshold",
                description = "Health percentage to consider targets for Light of Dawn",
                type = "slider",
                min = 50,
                max = 95,
                default = 85
            },
            useLightOfTheMartyr = {
                displayName = "Use Light of the Martyr",
                description = "Automatically use Light of the Martyr",
                type = "toggle",
                default = true
            },
            lightOfTheMartyrThreshold = {
                displayName = "Light of the Martyr Health Threshold",
                description = "Health percentage to use Light of the Martyr",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useHolyPrism = {
                displayName = "Use Holy Prism",
                description = "Automatically use Holy Prism when talented",
                type = "toggle",
                default = true
            },
            holyPrismThreshold = {
                displayName = "Holy Prism Health Threshold",
                description = "Health percentage to use Holy Prism",
                type = "slider",
                min = 10,
                max = 95,
                default = 75
            },
            useLightsHammer = {
                displayName = "Use Light's Hammer",
                description = "Automatically use Light's Hammer when talented",
                type = "toggle",
                default = true
            },
            lightsHammerMinTargets = {
                displayName = "Light's Hammer Min Targets",
                description = "Minimum injured targets to use Light's Hammer",
                type = "slider",
                min = 3,
                max = 8,
                default = 4
            },
            useFlashOfLight = {
                displayName = "Use Flash of Light",
                description = "Automatically use Flash of Light",
                type = "toggle",
                default = true
            },
            flashOfLightThreshold = {
                displayName = "Flash of Light Health Threshold",
                description = "Health percentage to use Flash of Light",
                type = "slider",
                min = 10,
                max = 80,
                default = 65
            },
            useHolyLight = {
                displayName = "Use Holy Light",
                description = "Automatically use Holy Light",
                type = "toggle",
                default = true
            },
            holyLightThreshold = {
                displayName = "Holy Light Health Threshold",
                description = "Health percentage to use Holy Light",
                type = "slider",
                min = 50,
                max = 90,
                default = 80
            }
        },
        
        cooldownSettings = {
            useAvengingWrath = {
                displayName = "Use Avenging Wrath",
                description = "Automatically use Avenging Wrath",
                type = "toggle",
                default = true
            },
            avengingWrathMode = {
                displayName = "Avenging Wrath Usage",
                description = "When to use Avenging Wrath",
                type = "dropdown",
                options = {"On Cooldown", "Multiple Injured Allies", "Burst Only"},
                default = "Multiple Injured Allies"
            },
            avengingWrathInjuredCount = {
                displayName = "Avenging Wrath Injured Count",
                description = "Number of injured allies to use Avenging Wrath",
                type = "slider",
                min = 2,
                max = 10,
                default = 3
            },
            useDivineProtection = {
                displayName = "Use Divine Protection",
                description = "Automatically use Divine Protection",
                type = "toggle",
                default = true
            },
            divineProtectionMode = {
                displayName = "Divine Protection Usage",
                description = "When to use Divine Protection",
                type = "dropdown",
                options = {"On Cooldown", "When Taking Damage", "Burst Only"},
                default = "When Taking Damage"
            },
            useHolyAvenger = {
                displayName = "Use Holy Avenger",
                description = "Automatically use Holy Avenger when talented",
                type = "toggle",
                default = true
            },
            holyAvengerMode = {
                displayName = "Holy Avenger Usage",
                description = "When to use Holy Avenger",
                type = "dropdown",
                options = {"On Cooldown", "With Avenging Wrath", "Burst Only"},
                default = "With Avenging Wrath"
            },
            useAvengingCrusader = {
                displayName = "Use Avenging Crusader",
                description = "Automatically use Avenging Crusader when talented",
                type = "toggle",
                default = true
            },
            avengingCrusaderMode = {
                displayName = "Avenging Crusader Usage",
                description = "When to use Avenging Crusader",
                type = "dropdown",
                options = {"On Cooldown", "Multiple Injured Allies", "Burst Only"},
                default = "Multiple Injured Allies"
            },
            useDivineFavor = {
                displayName = "Use Divine Favor",
                description = "Automatically use Divine Favor when talented",
                type = "toggle",
                default = true
            },
            divineFavorMode = {
                displayName = "Divine Favor Usage",
                description = "When to use Divine Favor",
                type = "dropdown",
                options = {"On Cooldown", "Critical Health Ally", "Burst Only"},
                default = "Critical Health Ally"
            },
            useDivineToll = {
                displayName = "Use Divine Toll",
                description = "Automatically use Divine Toll when talented",
                type = "toggle",
                default = true
            },
            divineTollMode = {
                displayName = "Divine Toll Usage",
                description = "When to use Divine Toll",
                type = "dropdown",
                options = {"On Cooldown", "Multiple Injured Allies", "Burst Only"},
                default = "Multiple Injured Allies"
            },
            useAshenHallow = {
                displayName = "Use Ashen Hallow",
                description = "Automatically use Ashen Hallow when talented",
                type = "toggle",
                default = true
            },
            ashenHallowMode = {
                displayName = "Ashen Hallow Usage",
                description = "When to use Ashen Hallow",
                type = "dropdown",
                options = {"On Cooldown", "Multiple Injured Allies", "Burst Only"},
                default = "Burst Only"
            },
            useDivineToil = {
                displayName = "Use Divine Toil",
                description = "Automatically use Divine Toil when talented",
                type = "toggle",
                default = true
            },
            divineToilMode = {
                displayName = "Divine Toil Usage",
                description = "When to use Divine Toil",
                type = "dropdown",
                options = {"On Cooldown", "Multiple Injured Allies", "Burst Only"},
                default = "Multiple Injured Allies"
            }
        },
        
        beaconSettings = {
            useBeaconOfLight = {
                displayName = "Use Beacon of Light",
                description = "Automatically maintain Beacon of Light",
                type = "toggle",
                default = true
            },
            beaconOfLightTarget = {
                displayName = "Beacon of Light Target",
                description = "Who to target with Beacon of Light",
                type = "dropdown",
                options = {"Main Tank", "Off Tank", "Focus Target", "Manual Only"},
                default = "Main Tank"
            },
            useBeaconOfFaith = {
                displayName = "Use Beacon of Faith",
                description = "Automatically maintain Beacon of Faith when talented",
                type = "toggle",
                default = true
            },
            beaconOfFaithTarget = {
                displayName = "Beacon of Faith Target",
                description = "Who to target with Beacon of Faith",
                type = "dropdown",
                options = {"Off Tank", "Main Tank", "Focus Target", "Manual Only"},
                default = "Off Tank"
            },
            useBeaconOfVirtue = {
                displayName = "Use Beacon of Virtue",
                description = "Automatically use Beacon of Virtue when talented",
                type = "toggle",
                default = true
            },
            beaconOfVirtueMinTargets = {
                displayName = "Beacon of Virtue Min Targets",
                description = "Minimum injured targets to use Beacon of Virtue",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            beaconOfVirtueThreshold = {
                displayName = "Beacon of Virtue Health Threshold",
                description = "Health percentage to use Beacon of Virtue",
                type = "slider",
                min = 10,
                max = 80,
                default = 65
            }
        },
        
        defensiveSettings = {
            useBlessingOfProtection = {
                displayName = "Use Blessing of Protection",
                description = "Automatically use Blessing of Protection",
                type = "toggle",
                default = true
            },
            blessingOfProtectionThreshold = {
                displayName = "Blessing of Protection Health Threshold",
                description = "Health percentage to use Blessing of Protection",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            },
            useBlessingOfSacrifice = {
                displayName = "Use Blessing of Sacrifice",
                description = "Automatically use Blessing of Sacrifice",
                type = "toggle",
                default = true
            },
            blessingOfSacrificeThreshold = {
                displayName = "Blessing of Sacrifice Health Threshold",
                description = "Health percentage to use Blessing of Sacrifice",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useLayOnHands = {
                displayName = "Use Lay on Hands",
                description = "Automatically use Lay on Hands",
                type = "toggle",
                default = true
            },
            layOnHandsThreshold = {
                displayName = "Lay on Hands Health Threshold",
                description = "Health percentage to use Lay on Hands",
                type = "slider",
                min = 5,
                max = 25,
                default = 15
            },
            useDivineShield = {
                displayName = "Use Divine Shield",
                description = "Automatically use Divine Shield",
                type = "toggle",
                default = true
            },
            divineShieldThreshold = {
                displayName = "Divine Shield Health Threshold",
                description = "Health percentage to use Divine Shield",
                type = "slider",
                min = 5,
                max = 25,
                default = 15
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Avenging Wrath controls
            avengingWrath = AAC.RegisterAbility(spells.AVENGING_WRATH, {
                enabled = true,
                useDuringBurstOnly = false,
                minInjuredAllies = 3
            }),
            
            -- Word of Glory controls
            wordOfGlory = AAC.RegisterAbility(spells.WORD_OF_GLORY, {
                enabled = true,
                useDuringBurstOnly = false,
                targetMode = "Lowest Health",
                prioritizeTanks = true
            }),
            
            -- Holy Shock controls
            holyShock = AAC.RegisterAbility(spells.HOLY_SHOCK, {
                enabled = true,
                useDuringBurstOnly = false,
                allowDamageUse = true,
                healingPriority = "Smart"
            })
        }
    })
    
    return true
end

-- Register for events 
function Holy:RegisterEvents()
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
    
    -- Register for holy power updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "HOLY_POWER" then
            self:UpdateHolyPower()
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
    
    -- Register for group aura tracking (beacons, glimmers)
    API.RegisterEvent("UNIT_AURA", function(unit) 
        if unit and (UnitInParty(unit) or UnitInRaid(unit)) then
            self:UpdateUnitAuras(unit)
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initialize beacon tracking
    self:UpdateBeaconTargets()
    
    return true
end

-- Update talent information
function Holy:UpdateTalentInfo()
    -- Check for important talents
    talents.hasInfusionOfLight = API.HasTalent(spells.INFUSION_OF_LIGHT)
    talents.hasDivinePurpose = API.HasTalent(spells.DIVINE_PURPOSE)
    talents.hasGlimmerOfLight = API.HasTalent(spells.GLIMMER_OF_LIGHT)
    talents.hasBeaconOfFaith = API.HasTalent(spells.BEACON_OF_FAITH)
    talents.hasBeaconOfVirtue = API.HasTalent(spells.BEACON_OF_VIRTUE)
    talents.hasDivineResonance = API.HasTalent(spells.DIVINE_RESONANCE)
    talents.hasBlessingOfDawn = API.HasTalent(spells.BLESSING_OF_DAWN)
    talents.hasBlessingOfDusk = API.HasTalent(spells.BLESSING_OF_DUSK)
    talents.hasAwakening = API.HasTalent(spells.AWAKENING)
    talents.hasMaraadsDyingBreath = API.HasTalent(spells.MARAADS_DYING_BREATH)
    talents.hasHealingHands = API.HasTalent(spells.HEALING_HANDS)
    talents.hasBeaconOfYore = API.HasTalent(spells.BEACON_OF_YORE)
    talents.hasSacredArbiter = API.HasTalent(spells.SACRED_ARBITER)
    talents.hasSelflessHealer = API.HasTalent(spells.SELFLESS_HEALER)
    talents.hasRadiatingLight = API.HasTalent(spells.RADIATING_LIGHT)
    talents.hasEnlightenment = API.HasTalent(spells.ENLIGHTENMENT)
    talents.hasRestorationFlame = API.HasTalent(spells.RESTORATION_FLAME)
    talents.hasBeaconRoyal = API.HasTalent(spells.BEACON_ROYAL)
    talents.hasHolyPrism = API.HasTalent(spells.HOLY_PRISM)
    talents.hasLightsHammer = API.HasTalent(spells.LIGHTS_HAMMER)
    talents.hasHolyAvenger = API.HasTalent(spells.HOLY_AVENGER)
    talents.hasDivineFavor = API.HasTalent(spells.DIVINE_FAVOR)
    talents.hasAvengingCrusader = API.HasTalent(spells.AVENGING_CRUSADER)
    talents.hasDivineToll = API.HasTalent(spells.DIVINE_TOLL)
    talents.hasAshenHallow = API.HasTalent(spells.ASHEN_HALLOW)
    talents.hasDivineToil = API.HasTalent(spells.DIVINE_TOIL)
    
    -- Set specialized variables based on talents
    if talents.hasInfusionOfLight then
        infusionActive = API.UnitHasBuff("player", buffs.INFUSION_OF_LIGHT)
        infusionOfLightStacks = select(4, API.GetBuffInfo("player", buffs.INFUSION_OF_LIGHT)) or 0
    end
    
    if talents.hasDivinePurpose then
        divinePurpose = true
        divinePurposeActive = API.UnitHasBuff("player", buffs.DIVINE_PURPOSE)
    end
    
    if talents.hasGlimmerOfLight then
        glimmerOfLight = true
    end
    
    if talents.hasBeaconOfFaith then
        beaconOfFaith = true
    end
    
    if talents.hasBeaconOfVirtue then
        beaconOfVirtue = true
    end
    
    if talents.hasDivineResonance then
        divineResonance = true
    end
    
    if talents.hasBeaconOfYore then
        beaconOfYore = true
    end
    
    if talents.hasSacredArbiter then
        sacredArbiter = true
    end
    
    if talents.hasLightsHammer then
        lightsHammer = true
    end
    
    if talents.hasAwakening then
        awakening = true
    end
    
    if talents.hasHolyPrism then
        holyPrism = true
    end
    
    if talents.hasDivineFavor then
        divineFavor = true
    end
    
    if talents.hasAvengingCrusader then
        avengingCrusader = true
    end
    
    if API.IsSpellKnown(spells.DIVINE_PROTECTION) then
        divineProtection = true
    end
    
    if API.IsSpellKnown(spells.HOLY_LIGHT) then
        holyLight = true
    end
    
    if API.IsSpellKnown(spells.FLASH_OF_LIGHT) then
        flashOfLight = true
    end
    
    if API.IsSpellKnown(spells.WORD_OF_GLORY) then
        wordOfGlory = true
    end
    
    if API.IsSpellKnown(spells.LIGHT_OF_DAWN) then
        lightOfDawn = true
    end
    
    if API.IsSpellKnown(spells.HOLY_SHOCK) then
        holyShock = true
    end
    
    if API.IsSpellKnown(spells.JUDGMENT) then
        judgement = true
    end
    
    if API.IsSpellKnown(spells.CRUSADER_STRIKE) then
        crusaderStrike = true
    end
    
    if talents.hasDivineToil then
        divineToil = true
    end
    
    if API.IsSpellKnown(spells.BESTOW_FAITH) then
        bestowFaith = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_SACRIFICE) then
        blessingOfSacrifice = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_PROTECTION) then
        blessingOfProtection = true
    end
    
    if API.IsSpellKnown(spells.LAY_ON_HANDS) then
        layOnHands = true
    end
    
    if API.IsSpellKnown(spells.HAMMER_OF_WRATH) then
        hammerOfWrath = true
    end
    
    if API.IsSpellKnown(spells.CONSECRATION) then
        consecration = true
    end
    
    if API.IsSpellKnown(spells.BEACON_OF_LIGHT) then
        beaconOfLight = true
    end
    
    if API.IsSpellKnown(spells.AVENGING_WRATH) then
        avengingWrath = true
    end
    
    if talents.hasBeaconRoyal then
        beaconRoyal = true
    end
    
    if API.IsSpellKnown(spells.BEACON_OF_LIGHT) then
        beacon = true
    end
    
    if talents.hasRadiatingLight then
        radiatingLight = true
    end
    
    if talents.hasRestorationFlame then
        restorationFlame = true
    end
    
    if talents.hasDivinePurpose then
        divinePurpose = true
    end
    
    if API.IsSpellKnown(spells.DEVOTION_AURA) then
        devotionAura = true
    end
    
    if talents.hasHealingHands then
        healingHands = true
    end
    
    if talents.hasHolyAvenger then
        holyAvenger = true
    end
    
    if talents.hasMaraadsDyingBreath then
        maraadsDyingBreath = true
    end
    
    if talents.hasSelflessHealer then
        selflessHealer = true
    end
    
    if API.IsSpellKnown(spells.LIGHT_OF_THE_MARTYR) then
        lightOfTheMartyr = true
    end
    
    -- Update beacon transfer amount based on talents
    if talents.hasBeaconOfYore then
        beaconTransfer = 0.5 -- 50% transfer with Beacon of Yore
    end
    
    -- Calculate Holy Shock crit chance
    holyShockCritChance = API.GetSpellCritChance() + 30 -- Holy Shock has +30% crit baseline
    
    API.PrintDebug("Holy Paladin talents updated")
    
    return true
end

-- Update mana tracking
function Holy:UpdateMana()
    currentManaPct = API.GetPlayerManaPercentage()
    return true
end

-- Update Holy Power tracking
function Holy:UpdateHolyPower()
    currentHolyPower = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Holy:UpdateHealth()
    -- This is handled by API.GetPlayerHealthPercent() when needed
    return true
end

-- Update target health tracking
function Holy:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update unit auras for beacon/glimmer tracking
function Holy:UpdateUnitAuras(unit)
    local unitGUID = API.UnitGUID(unit)
    
    if not unitGUID then return false end
    
    -- Check for Beacon of Light or Faith
    if API.UnitHasBuff(unit, buffs.BEACON_OF_LIGHT) then
        beaconTargets[unitGUID] = "Light"
    elseif API.UnitHasBuff(unit, buffs.BEACON_OF_FAITH) then
        beaconTargets[unitGUID] = "Faith"
    elseif API.UnitHasBuff(unit, buffs.BEACON_OF_VIRTUE) then
        beaconTargets[unitGUID] = "Virtue"
    else
        beaconTargets[unitGUID] = nil
    end
    
    -- Check for Glimmer of Light
    if glimmerOfLight and API.UnitHasBuff(unit, buffs.GLIMMER_OF_LIGHT) then
        glimmerTargets[unitGUID] = true
    else
        glimmerTargets[unitGUID] = nil
    end
    
    return true
end

-- Update beacon targets tracking
function Holy:UpdateBeaconTargets()
    -- Clear existing list
    beaconTargets = {}
    
    -- Check all group members
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            local unitGUID = API.UnitGUID(unit)
            
            if unitGUID then
                -- Check for Beacon of Light or Faith
                if API.UnitHasBuff(unit, buffs.BEACON_OF_LIGHT) then
                    beaconTargets[unitGUID] = "Light"
                elseif API.UnitHasBuff(unit, buffs.BEACON_OF_FAITH) then
                    beaconTargets[unitGUID] = "Faith"
                elseif API.UnitHasBuff(unit, buffs.BEACON_OF_VIRTUE) then
                    beaconTargets[unitGUID] = "Virtue"
                end
                
                -- Check for Glimmer of Light
                if glimmerOfLight and API.UnitHasBuff(unit, buffs.GLIMMER_OF_LIGHT) then
                    glimmerTargets[unitGUID] = true
                end
            end
        end
    end
    
    return true
end

-- Check if unit is in melee range
function Holy:IsInMeleeRange(unit)
    if not unit or not API.UnitExists(unit) then
        return false
    end
    
    return API.GetUnitDistance("player", unit) <= meleeRange
end

-- Handle combat log events
function Holy:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Infusion of Light
            if spellID == buffs.INFUSION_OF_LIGHT then
                infusionActive = true
                infusionEndTime = select(6, API.GetBuffInfo("player", buffs.INFUSION_OF_LIGHT))
                infusionOfLightStacks = select(4, API.GetBuffInfo("player", buffs.INFUSION_OF_LIGHT)) or 1
                API.PrintDebug("Infusion of Light activated: " .. tostring(infusionOfLightStacks) .. " stack(s)")
            end
            
            -- Track Divine Purpose
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeActive = true
                divinePurposeEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_PURPOSE))
                API.PrintDebug("Divine Purpose activated")
            end
            
            -- Track Divine Favor
            if spellID == buffs.DIVINE_FAVOR then
                divineFavorActive = true
                divineFavorEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_FAVOR))
                API.PrintDebug("Divine Favor activated")
            end
            
            -- Track Avenging Wrath
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = true
                avengingWrathEndTime = select(6, API.GetBuffInfo("player", buffs.AVENGING_WRATH))
                API.PrintDebug("Avenging Wrath activated")
            end
            
            -- Track Avenging Crusader
            if spellID == buffs.AVENGING_CRUSADER then
                avengingCrusaderActive = true
                avengingCrusaderEndTime = select(6, API.GetBuffInfo("player", buffs.AVENGING_CRUSADER))
                API.PrintDebug("Avenging Crusader activated")
            end
            
            -- Track Holy Avenger
            if spellID == buffs.HOLY_AVENGER then
                holyAvengerActive = true
                holyAvengerEndTime = select(6, API.GetBuffInfo("player", buffs.HOLY_AVENGER))
                API.PrintDebug("Holy Avenger activated")
            end
            
            -- Track Divine Protection
            if spellID == buffs.DIVINE_PROTECTION then
                divineProtectionActive = true
                divineProtectionEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_PROTECTION))
                API.PrintDebug("Divine Protection activated")
            end
            
            -- Track Blessing of Dawn
            if spellID == buffs.BLESSING_OF_DAWN then
                blessingOfDawnActive = true
                blessingOfDawnEndTime = select(6, API.GetBuffInfo("player", buffs.BLESSING_OF_DAWN))
                API.PrintDebug("Blessing of Dawn activated")
            end
            
            -- Track Blessing of Dusk
            if spellID == buffs.BLESSING_OF_DUSK then
                blessingOfDuskActive = true
                blessingOfDuskEndTime = select(6, API.GetBuffInfo("player", buffs.BLESSING_OF_DUSK))
                API.PrintDebug("Blessing of Dusk activated")
            end
            
            -- Track Awakening
            if spellID == buffs.AWAKENING then
                awakeningActive = true
                awakeningEndTime = select(6, API.GetBuffInfo("player", buffs.AWAKENING))
                API.PrintDebug("Awakening activated")
            end
            
            -- Track Ashen Hallow
            if spellID == buffs.ASHEN_HALLOW then
                ashenHallowActive = true
                ashenHallowEndTime = select(6, API.GetBuffInfo("player", buffs.ASHEN_HALLOW))
                API.PrintDebug("Ashen Hallow activated")
            end
            
            -- Track Divine Toil
            if spellID == buffs.DIVINE_TOIL then
                divineToilActive = true
                divineToilEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_TOIL))
                API.PrintDebug("Divine Toil activated")
            end
            
            -- Track Selfless Healer
            if spellID == buffs.SELFLESS_HEALER then
                selflessHealerActive = true
                selflessHealerStacks = select(4, API.GetBuffInfo("player", buffs.SELFLESS_HEALER)) or 1
                API.PrintDebug("Selfless Healer activated: " .. tostring(selflessHealerStacks) .. " stack(s)")
            end
            
            -- Track Healing Hands
            if spellID == buffs.HEALING_HANDS then
                healingHandsActive = true
                healingHandsEndTime = select(6, API.GetBuffInfo("player", buffs.HEALING_HANDS))
                API.PrintDebug("Healing Hands activated")
            end
            
            -- Track Restoration Flame
            if spellID == buffs.RESTORATION_FLAME then
                restorationFlameActive = true
                restorationFlameEndTime = select(6, API.GetBuffInfo("player", buffs.RESTORATION_FLAME))
                API.PrintDebug("Restoration Flame activated")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Infusion of Light
            if spellID == buffs.INFUSION_OF_LIGHT then
                infusionActive = false
                infusionOfLightStacks = 0
                API.PrintDebug("Infusion of Light faded")
            end
            
            -- Track Divine Purpose
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeActive = false
                API.PrintDebug("Divine Purpose faded")
            end
            
            -- Track Divine Favor
            if spellID == buffs.DIVINE_FAVOR then
                divineFavorActive = false
                API.PrintDebug("Divine Favor faded")
            end
            
            -- Track Avenging Wrath
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = false
                API.PrintDebug("Avenging Wrath faded")
            end
            
            -- Track Avenging Crusader
            if spellID == buffs.AVENGING_CRUSADER then
                avengingCrusaderActive = false
                API.PrintDebug("Avenging Crusader faded")
            end
            
            -- Track Holy Avenger
            if spellID == buffs.HOLY_AVENGER then
                holyAvengerActive = false
                API.PrintDebug("Holy Avenger faded")
            end
            
            -- Track Divine Protection
            if spellID == buffs.DIVINE_PROTECTION then
                divineProtectionActive = false
                API.PrintDebug("Divine Protection faded")
            end
            
            -- Track Blessing of Dawn
            if spellID == buffs.BLESSING_OF_DAWN then
                blessingOfDawnActive = false
                API.PrintDebug("Blessing of Dawn faded")
            end
            
            -- Track Blessing of Dusk
            if spellID == buffs.BLESSING_OF_DUSK then
                blessingOfDuskActive = false
                API.PrintDebug("Blessing of Dusk faded")
            end
            
            -- Track Awakening
            if spellID == buffs.AWAKENING then
                awakeningActive = false
                API.PrintDebug("Awakening faded")
            end
            
            -- Track Ashen Hallow
            if spellID == buffs.ASHEN_HALLOW then
                ashenHallowActive = false
                API.PrintDebug("Ashen Hallow faded")
            end
            
            -- Track Divine Toil
            if spellID == buffs.DIVINE_TOIL then
                divineToilActive = false
                API.PrintDebug("Divine Toil faded")
            end
            
            -- Track Selfless Healer
            if spellID == buffs.SELFLESS_HEALER then
                selflessHealerActive = false
                selflessHealerStacks = 0
                API.PrintDebug("Selfless Healer faded")
            end
            
            -- Track Healing Hands
            if spellID == buffs.HEALING_HANDS then
                healingHandsActive = false
                API.PrintDebug("Healing Hands faded")
            end
            
            -- Track Restoration Flame
            if spellID == buffs.RESTORATION_FLAME then
                restorationFlameActive = false
                API.PrintDebug("Restoration Flame faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            if spellID == spells.HOLY_SHOCK then
                lastHolyShock = GetTime()
                API.PrintDebug("Holy Shock cast")
                
                -- Special holy shock calculations here if needed
            elseif spellID == spells.CRUSADER_STRIKE then
                lastCrusaderStrike = GetTime()
                API.PrintDebug("Crusader Strike cast")
            elseif spellID == spells.JUDGMENT then
                lastJudgement = GetTime()
                API.PrintDebug("Judgment cast")
            elseif spellID == spells.WORD_OF_GLORY then
                lastWordOfGlory = GetTime()
                API.PrintDebug("Word of Glory cast")
            elseif spellID == spells.LIGHT_OF_DAWN then
                lastLightOfDawn = GetTime()
                API.PrintDebug("Light of Dawn cast")
            elseif spellID == spells.HAMMER_OF_WRATH then
                lastHammerOfWrath = GetTime()
                API.PrintDebug("Hammer of Wrath cast")
            elseif spellID == spells.AVENGING_WRATH then
                lastAvengingWrath = GetTime()
                avengingWrathActive = true
                avengingWrathEndTime = GetTime() + AVENGING_WRATH_DURATION
                API.PrintDebug("Avenging Wrath cast")
            elseif spellID == spells.AVENGING_CRUSADER then
                avengingCrusaderActive = true
                avengingCrusaderEndTime = GetTime() + AVENGING_CRUSADER_DURATION
                API.PrintDebug("Avenging Crusader cast")
            elseif spellID == spells.HOLY_AVENGER then
                holyAvengerActive = true
                holyAvengerEndTime = GetTime() + HOLY_AVENGER_DURATION
                API.PrintDebug("Holy Avenger cast")
            elseif spellID == spells.DIVINE_PROTECTION then
                divineProtectionActive = true
                divineProtectionEndTime = GetTime() + DIVINE_PROTECTION_DURATION
                API.PrintDebug("Divine Protection cast")
            elseif spellID == spells.ASHEN_HALLOW then
                ashenHallowActive = true
                ashenHallowEndTime = GetTime() + ASHEN_HALLOW_DURATION
                API.PrintDebug("Ashen Hallow cast")
            elseif spellID == spells.DIVINE_FAVOR then
                divineFavorActive = true
                divineFavorEndTime = GetTime() + DIVINE_FAVOR_DURATION
                API.PrintDebug("Divine Favor cast")
            elseif spellID == spells.LAY_ON_HANDS then
                lastLayOnHands = GetTime()
                API.PrintDebug("Lay on Hands cast")
            elseif spellID == spells.BESTOW_FAITH then
                lastBestowFaith = GetTime()
                API.PrintDebug("Bestow Faith cast")
            elseif spellID == spells.HOLY_LIGHT then
                lastHolyLight = GetTime()
                API.PrintDebug("Holy Light cast")
            elseif spellID == spells.FLASH_OF_LIGHT then
                lastFlashOfLight = GetTime()
                API.PrintDebug("Flash of Light cast")
            elseif spellID == spells.BEACON_OF_LIGHT then
                -- Note the new beacon target
                if destGUID then
                    beaconTargets[destGUID] = "Light"
                    API.PrintDebug("Beacon of Light cast on " .. destName)
                end
            elseif spellID == spells.BEACON_OF_FAITH then
                -- Note the new beacon of faith target
                if destGUID then
                    beaconTargets[destGUID] = "Faith"
                    API.PrintDebug("Beacon of Faith cast on " .. destName)
                end
            elseif spellID == spells.BEACON_OF_VIRTUE then
                -- Note the new beacon of virtue target
                if destGUID then
                    beaconTargets[destGUID] = "Virtue"
                    beaconOfVirtueActive = true
                    beaconOfVirtueEndTime = GetTime() + BEACON_OF_VIRTUE_DURATION
                    API.PrintDebug("Beacon of Virtue cast on " .. destName)
                end
            end
        end
        
        -- Track heal casts for specialized calculations
        if eventType == "SPELL_HEAL" then
            -- Special healing calculations, Maraad's logic, etc. if needed
            if spellID == spells.HOLY_SHOCK and maraadsDyingBreath then
                -- Track for Maraad's Dying Breath if talented
                API.PrintDebug("Holy Shock healing for Maraad's tracking")
            end
        end
    end
    
    -- Track Holy Shock crits for Infusion of Light
    if eventType == "SPELL_HEAL_CRIT" and sourceGUID == API.GetPlayerGUID() and spellID == spells.HOLY_SHOCK then
        API.PrintDebug("Holy Shock crit healing")
    end
    
    return true
end

-- Main rotation function
function Holy:RunRotation()
    -- Check if we should be running Holy Paladin logic
    if API.GetActiveSpecID() ~= HOLY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    
    -- Update variables
    self:UpdateMana()
    self:UpdateHolyPower()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Check if we're in melee range of any target
    isInMelee = self:IsInMeleeRange("target")
    
    -- Count low health/critical health allies
    lowHealthAllyCount = API.GetInjuredGroupMembersCount(settings.rotationSettings.healthThreshold)
    criticalHealthAllyCount = API.GetInjuredGroupMembersCount(settings.rotationSettings.criticalHealthThreshold)
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Skip if in solo content with no healing needs
    if not API.IsInGroup() and API.GetPlayerHealthPercent() > 90 and not API.IsInCombat() then
        return false
    end
    
    -- Maintain devotion aura
    if devotionAura and not API.UnitHasBuff("player", spells.DEVOTION_AURA) and API.CanCast(spells.DEVOTION_AURA) then
        API.CastSpell(spells.DEVOTION_AURA)
        return true
    end
    
    -- Maintain beacons
    if self:HandleBeacons(settings) then
        return true
    end
    
    -- Handle emergency healing
    if self:HandleEmergencyHealing(settings) then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle cooldowns
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle regular healing rotation
    if self:HandleHealing(settings) then
        return true
    end
    
    -- Handle DPS if no healing is needed
    if self:HandleDPS(settings) then
        return true
    end
    
    return false
end

-- Handle beacon maintenance
function Holy:HandleBeacons(settings)
    -- Beacon of Light
    if beaconOfLight and settings.beaconSettings.useBeaconOfLight then
        local mainTank = API.GetMainTank()
        
        if mainTank and not self:UnitHasBeacon(mainTank) and settings.beaconSettings.beaconOfLightTarget == "Main Tank" and API.CanCast(spells.BEACON_OF_LIGHT) then
            API.CastSpellOnUnit(spells.BEACON_OF_LIGHT, mainTank)
            return true
        end
        
        local offTank = API.GetOffTank()
        
        if offTank and not self:UnitHasBeacon(offTank) and settings.beaconSettings.beaconOfLightTarget == "Off Tank" and API.CanCast(spells.BEACON_OF_LIGHT) then
            API.CastSpellOnUnit(spells.BEACON_OF_LIGHT, offTank)
            return true
        end
        
        if API.UnitExists("focus") and not self:UnitHasBeacon("focus") and settings.beaconSettings.beaconOfLightTarget == "Focus Target" and API.CanCast(spells.BEACON_OF_LIGHT) then
            API.CastSpellOnUnit(spells.BEACON_OF_LIGHT, "focus")
            return true
        end
    end
    
    -- Beacon of Faith
    if beaconOfFaith and settings.beaconSettings.useBeaconOfFaith then
        local offTank = API.GetOffTank()
        
        if offTank and not self:UnitHasBeacon(offTank) and settings.beaconSettings.beaconOfFaithTarget == "Off Tank" and API.CanCast(spells.BEACON_OF_FAITH) then
            API.CastSpellOnUnit(spells.BEACON_OF_FAITH, offTank)
            return true
        end
        
        local mainTank = API.GetMainTank()
        
        if mainTank and not self:UnitHasBeacon(mainTank) and settings.beaconSettings.beaconOfFaithTarget == "Main Tank" and API.CanCast(spells.BEACON_OF_FAITH) then
            API.CastSpellOnUnit(spells.BEACON_OF_FAITH, mainTank)
            return true
        end
        
        if API.UnitExists("focus") and not self:UnitHasBeacon("focus") and settings.beaconSettings.beaconOfFaithTarget == "Focus Target" and API.CanCast(spells.BEACON_OF_FAITH) then
            API.CastSpellOnUnit(spells.BEACON_OF_FAITH, "focus")
            return true
        end
    end
    
    -- Beacon of Virtue
    if beaconOfVirtue and 
       settings.beaconSettings.useBeaconOfVirtue and
       lowHealthAllyCount >= settings.beaconSettings.beaconOfVirtueMinTargets and
       API.CanCast(spells.BEACON_OF_VIRTUE) then
        
        local lowestAlly = API.GetLowestHealthGroupMember()
        if lowestAlly and API.GetUnitHealthPercent(lowestAlly) <= settings.beaconSettings.beaconOfVirtueThreshold then
            API.CastSpellOnUnit(spells.BEACON_OF_VIRTUE, lowestAlly)
            return true
        end
    end
    
    return false
end

-- Check if unit has any beacon
function Holy:UnitHasBeacon(unit)
    local unitGUID = API.UnitGUID(unit)
    
    if not unitGUID then return false end
    
    return beaconTargets[unitGUID] ~= nil
end

-- Handle emergency healing
function Holy:HandleEmergencyHealing(settings)
    -- Get lowest health ally in critical condition
    local lowestUnit, lowestHealth = API.GetLowestHealthGroupMember()
    
    -- Use Lay on Hands for critical situations
    if layOnHands and
       settings.defensiveSettings.useLayOnHands and
       lowestUnit and
       lowestHealth <= settings.defensiveSettings.layOnHandsThreshold and
       API.CanCast(spells.LAY_ON_HANDS) and
       not self:UnitHasBeacon(lowestUnit) then -- Avoid casting on beacon targets if possible
        API.CastSpellOnUnit(spells.LAY_ON_HANDS, lowestUnit)
        return true
    end
    
    -- Use Word of Glory for emergency healing
    if wordOfGlory and
       settings.abilitySettings.useWordOfGlory and
       (currentHolyPower >= 3 or divinePurposeActive) and
       lowestUnit and
       lowestHealth <= settings.abilitySettings.wordOfGloryThreshold and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, lowestUnit)
        return true
    end
    
    -- Use Holy Shock for emergency healing
    if holyShock and
       lowestUnit and
       lowestHealth <= 50 and -- Hard-coded lower threshold for emergency
       API.CanCast(spells.HOLY_SHOCK) then
        API.CastSpellOnUnit(spells.HOLY_SHOCK, lowestUnit)
        return true
    end
    
    -- Use Light of the Martyr as a last resort for emergency healing
    if lightOfTheMartyr and
       settings.abilitySettings.useLightOfTheMartyr and
       lowestUnit and
       lowestHealth <= settings.abilitySettings.lightOfTheMartyrThreshold and
       API.GetPlayerHealthPercent() > 50 and -- Don't sacrifice too much health
       API.CanCast(spells.LIGHT_OF_THE_MARTYR) then
        API.CastSpellOnUnit(spells.LIGHT_OF_THE_MARTYR, lowestUnit)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Holy:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Divine Shield for critical self-health
    if settings.defensiveSettings.useDivineShield and
       playerHealth <= settings.defensiveSettings.divineShieldThreshold and
       API.CanCast(spells.DIVINE_SHIELD) then
        API.CastSpell(spells.DIVINE_SHIELD)
        return true
    end
    
    -- Use Divine Protection
    if divineProtection and
       settings.cooldownSettings.useDivineProtection and
       not divineProtectionActive and
       API.CanCast(spells.DIVINE_PROTECTION) then
        
        local shouldUseDP = false
        
        if settings.cooldownSettings.divineProtectionMode == "On Cooldown" then
            shouldUseDP = true
        elseif settings.cooldownSettings.divineProtectionMode == "When Taking Damage" then
            shouldUseDP = playerHealth < 80
        elseif settings.cooldownSettings.divineProtectionMode == "Burst Only" then
            shouldUseDP = burstModeActive
        end
        
        if shouldUseDP then
            API.CastSpell(spells.DIVINE_PROTECTION)
            return true
        end
    end
    
    -- Use Blessing of Protection on critically low ally
    if blessingOfProtection and
       settings.defensiveSettings.useBlessingOfProtection then
        
        -- Find non-tank ally in critical condition
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) and not API.UnitIsTank(unit) then
                local unitHealth = API.GetUnitHealthPercent(unit)
                
                if unitHealth <= settings.defensiveSettings.blessingOfProtectionThreshold and API.CanCast(spells.BLESSING_OF_PROTECTION) then
                    API.CastSpellOnUnit(spells.BLESSING_OF_PROTECTION, unit)
                    return true
                end
            end
        end
    end
    
    -- Use Blessing of Sacrifice on low health tank
    if blessingOfSacrifice and
       settings.defensiveSettings.useBlessingOfSacrifice and
       playerHealth > 70 then -- Only if we're reasonably healthy
        
        -- Find tank in trouble
        local mainTank = API.GetMainTank()
        if mainTank and API.GetUnitHealthPercent(mainTank) <= settings.defensiveSettings.blessingOfSacrificeThreshold and API.CanCast(spells.BLESSING_OF_SACRIFICE) then
            API.CastSpellOnUnit(spells.BLESSING_OF_SACRIFICE, mainTank)
            return true
        end
        
        local offTank = API.GetOffTank()
        if offTank and API.GetUnitHealthPercent(offTank) <= settings.defensiveSettings.blessingOfSacrificeThreshold and API.CanCast(spells.BLESSING_OF_SACRIFICE) then
            API.CastSpellOnUnit(spells.BLESSING_OF_SACRIFICE, offTank)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Holy:HandleCooldowns(settings)
    -- Skip if not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Avenging Wrath
    if avengingWrath and
       settings.cooldownSettings.useAvengingWrath and
       settings.abilityControls.avengingWrath.enabled and
       not avengingWrathActive and
       not avengingCrusaderActive and -- Don't overlap with Avenging Crusader
       API.CanCast(spells.AVENGING_WRATH) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.avengingWrath.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseAW = false
            
            if settings.cooldownSettings.avengingWrathMode == "On Cooldown" then
                shouldUseAW = true
            elseif settings.cooldownSettings.avengingWrathMode == "Multiple Injured Allies" then
                shouldUseAW = lowHealthAllyCount >= settings.cooldownSettings.avengingWrathInjuredCount
            elseif settings.cooldownSettings.avengingWrathMode == "Burst Only" then
                shouldUseAW = burstModeActive
            end
            
            if settings.abilityControls.avengingWrath.minInjuredAllies > 0 then
                shouldUseAW = shouldUseAW and lowHealthAllyCount >= settings.abilityControls.avengingWrath.minInjuredAllies
            end
            
            if shouldUseAW then
                API.CastSpell(spells.AVENGING_WRATH)
                return true
            end
        end
    end
    
    -- Use Holy Avenger
    if holyAvenger and
       settings.cooldownSettings.useHolyAvenger and
       not holyAvengerActive and
       API.CanCast(spells.HOLY_AVENGER) then
        
        local shouldUseHA = false
        
        if settings.cooldownSettings.holyAvengerMode == "On Cooldown" then
            shouldUseHA = true
        elseif settings.cooldownSettings.holyAvengerMode == "With Avenging Wrath" then
            shouldUseHA = avengingWrathActive
        elseif settings.cooldownSettings.holyAvengerMode == "Burst Only" then
            shouldUseHA = burstModeActive
        end
        
        if shouldUseHA then
            API.CastSpell(spells.HOLY_AVENGER)
            return true
        end
    end
    
    -- Use Avenging Crusader
    if avengingCrusader and
       settings.cooldownSettings.useAvengingCrusader and
       not avengingCrusaderActive and
       not avengingWrathActive and -- Don't overlap with Avenging Wrath
       API.CanCast(spells.AVENGING_CRUSADER) then
        
        local shouldUseAC = false
        
        if settings.cooldownSettings.avengingCrusaderMode == "On Cooldown" then
            shouldUseAC = true
        elseif settings.cooldownSettings.avengingCrusaderMode == "Multiple Injured Allies" then
            shouldUseAC = lowHealthAllyCount >= 3
        elseif settings.cooldownSettings.avengingCrusaderMode == "Burst Only" then
            shouldUseAC = burstModeActive
        end
        
        if shouldUseAC then
            API.CastSpell(spells.AVENGING_CRUSADER)
            return true
        end
    end
    
    -- Use Divine Favor
    if divineFavor and
       settings.cooldownSettings.useDivineFavor and
       not divineFavorActive and
       API.CanCast(spells.DIVINE_FAVOR) then
        
        local shouldUseDF = false
        
        if settings.cooldownSettings.divineFavorMode == "On Cooldown" then
            shouldUseDF = true
        elseif settings.cooldownSettings.divineFavorMode == "Critical Health Ally" then
            shouldUseDF = criticalHealthAllyCount > 0
        elseif settings.cooldownSettings.divineFavorMode == "Burst Only" then
            shouldUseDF = burstModeActive
        end
        
        if shouldUseDF then
            API.CastSpell(spells.DIVINE_FAVOR)
            return true
        end
    end
    
    -- Use Divine Toil
    if divineToil and
       settings.cooldownSettings.useDivineToil and
       not divineToilActive and
       API.CanCast(spells.DIVINE_TOIL) then
        
        local shouldUseDT = false
        
        if settings.cooldownSettings.divineToilMode == "On Cooldown" then
            shouldUseDT = true
        elseif settings.cooldownSettings.divineToilMode == "Multiple Injured Allies" then
            shouldUseDT = lowHealthAllyCount >= 3
        elseif settings.cooldownSettings.divineToilMode == "Burst Only" then
            shouldUseDT = burstModeActive
        end
        
        if shouldUseDT then
            API.CastSpell(spells.DIVINE_TOIL)
            return true
        end
    end
    
    -- Use Light's Hammer
    if lightsHammer and
       settings.abilitySettings.useLightsHammer and
       lowHealthAllyCount >= settings.abilitySettings.lightsHammerMinTargets and
       API.CanCast(spells.LIGHTS_HAMMER) then
        API.CastSpellAtBestLocation(spells.LIGHTS_HAMMER)
        return true
    end
    
    -- Use Holy Prism
    if holyPrism and
       settings.abilitySettings.useHolyPrism and
       API.CanCast(spells.HOLY_PRISM) then
        
        local lowestUnit, lowestHealth = API.GetLowestHealthGroupMember()
        
        if lowestUnit and lowestHealth <= settings.abilitySettings.holyPrismThreshold then
            API.CastSpellOnUnit(spells.HOLY_PRISM, lowestUnit)
            return true
        elseif API.UnitExists("target") and API.IsUnitEnemy("target") then
            -- Cast on enemy target for AoE healing of nearby allies
            API.CastSpellOnUnit(spells.HOLY_PRISM, "target")
            return true
        end
    end
    
    return false
end

-- Handle regular healing
function Holy:HandleHealing(settings)
    -- Get the lowest health player for single-target healing
    local lowestUnit, lowestHealth = API.GetLowestHealthGroupMember()
    
    -- Check if unit has Glimmer of Light
    local function NeedsGlimmer(unit)
        if not glimmerOfLight then
            return false
        end
        
        local unitGUID = API.UnitGUID(unit)
        if not unitGUID then
            return false
        end
        
        return not glimmerTargets[unitGUID]
    end
    
    -- Use Holy Shock
    if holyShock and
       API.CanCast(spells.HOLY_SHOCK) and
       settings.abilityControls.holyShock.enabled then
        
        local shouldHealWithHolyShock = false
        local healTarget = nil
        
        -- Holy Shock healing logic
        if settings.rotationSettings.holyShockPriority == "Healing Only" or
           settings.rotationSettings.holyShockPriority == "Always Heal" then
            shouldHealWithHolyShock = true
            healTarget = lowestUnit
        elseif settings.rotationSettings.holyShockPriority == "Smart Priority" then
            -- Smart Holy Shock targeting - prioritize healing vs damage
            if lowestHealth and lowestHealth < 85 then
                shouldHealWithHolyShock = true
                healTarget = lowestUnit
            elseif API.IsUnitEnemy("target") and settings.abilityControls.holyShock.allowDamageUse and isInMelee then
                -- Offensive Holy Shock
                API.CastSpellOnUnit(spells.HOLY_SHOCK, "target")
                return true
            end
        elseif settings.rotationSettings.holyShockPriority == "Damage Only" and API.IsUnitEnemy("target") and isInMelee then
            -- Offensive Holy Shock
            API.CastSpellOnUnit(spells.HOLY_SHOCK, "target")
            return true
        end
        
        -- Handle Glimmer of Light application
        if glimmerOfLight and settings.rotationSettings.glimmerManagement ~= "Maintain on All" then
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and NeedsGlimmer(unit) then
                    local applyGlimmer = false
                    
                    if settings.rotationSettings.glimmerManagement == "Maintain on Tank Only" and API.UnitIsTank(unit) then
                        applyGlimmer = true
                    elseif settings.rotationSettings.glimmerManagement == "Maintain on Melee" and API.IsUnitMelee(unit) then
                        applyGlimmer = true
                    elseif settings.rotationSettings.glimmerManagement == "Smart Priority" then
                        -- Use on tanks first, then injured players, until we reach the desired count
                        if API.UnitIsTank(unit) or API.GetUnitHealthPercent(unit) < 80 then
                            local currentGlimmerCount = 0
                            for _, hasGlimmer in pairs(glimmerTargets) do
                                if hasGlimmer then
                                    currentGlimmerCount = currentGlimmerCount + 1
                                end
                            end
                            
                            if currentGlimmerCount < settings.rotationSettings.glimmerTargetCount then
                                applyGlimmer = true
                            end
                        end
                    end
                    
                    if applyGlimmer then
                        healTarget = unit
                        break
                    end
                end
            end
        end
        
        if shouldHealWithHolyShock and healTarget and API.UnitExists(healTarget) then
            API.CastSpellOnUnit(spells.HOLY_SHOCK, healTarget)
            return true
        end
    end
    
    -- Use Word of Glory
    if wordOfGlory and
       settings.abilitySettings.useWordOfGlory and
       settings.abilityControls.wordOfGlory.enabled and
       (currentHolyPower >= 3 or divinePurposeActive) and
       lowestUnit and
       lowestHealth <= settings.abilitySettings.wordOfGloryThreshold and
       API.CanCast(spells.WORD_OF_GLORY) then
        
        -- Check if should prioritize tanks
        if settings.abilityControls.wordOfGlory.prioritizeTanks then
            -- Check if tanks need healing
            local mainTank = API.GetMainTank()
            if mainTank and API.GetUnitHealthPercent(mainTank) <= settings.abilitySettings.wordOfGloryThreshold then
                API.CastSpellOnUnit(spells.WORD_OF_GLORY, mainTank)
                return true
            end
            
            local offTank = API.GetOffTank()
            if offTank and API.GetUnitHealthPercent(offTank) <= settings.abilitySettings.wordOfGloryThreshold then
                API.CastSpellOnUnit(spells.WORD_OF_GLORY, offTank)
                return true
            end
        end
        
        -- Default to lowest health target
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, lowestUnit)
        return true
    end
    
    -- Use Light of Dawn
    if lightOfDawn and
       settings.abilitySettings.useLightOfDawn and
       (currentHolyPower >= 3 or divinePurposeActive) and
       API.GetInjuredGroupMembersInFront(settings.abilitySettings.lightOfDawnThreshold) >= settings.abilitySettings.lightOfDawnMinTargets and
       API.CanCast(spells.LIGHT_OF_DAWN) then
        API.CastSpell(spells.LIGHT_OF_DAWN)
        return true
    end
    
    -- Use Bestow Faith
    if bestowFaith and
       settings.abilitySettings.useBestowFaith and
       API.CanCast(spells.BESTOW_FAITH) then
        
        local bestowTarget = nil
        
        if settings.abilitySettings.bestowFaithTarget == "Tank" then
            bestowTarget = API.GetMainTank() or API.GetOffTank()
        elseif settings.abilitySettings.bestowFaithTarget == "Lowest Health" then
            bestowTarget = lowestUnit
        elseif settings.abilitySettings.bestowFaithTarget == "Self" then
            bestowTarget = "player"
        elseif settings.abilitySettings.bestowFaithTarget == "Smart Priority" then
            -- Smart logic - use on tank that's actively tanking and taking damage
            bestowTarget = API.GetActivelyTankingUnit() or lowestUnit
        end
        
        if bestowTarget and API.UnitExists(bestowTarget) then
            API.CastSpellOnUnit(spells.BESTOW_FAITH, bestowTarget)
            return true
        end
    end
    
    -- Use Flash of Light with Infusion of Light proc
    if flashOfLight and
       settings.abilitySettings.useFlashOfLight and
       infusionActive and
       lowestUnit and
       lowestHealth <= settings.abilitySettings.flashOfLightThreshold and
       currentManaPct > (settings.rotationSettings.manaPooling and settings.rotationSettings.manaPoolingThreshold or 0) and
       API.CanCast(spells.FLASH_OF_LIGHT) then
        API.CastSpellOnUnit(spells.FLASH_OF_LIGHT, lowestUnit)
        return true
    end
    
    -- Use Holy Light with Infusion of Light proc
    if holyLight and
       settings.abilitySettings.useHolyLight and
       infusionActive and
       lowestUnit and
       lowestHealth <= settings.abilitySettings.holyLightThreshold and
       currentManaPct > (settings.rotationSettings.manaPooling and settings.rotationSettings.manaPoolingThreshold or 0) and
       API.CanCast(spells.HOLY_LIGHT) then
        API.CastSpellOnUnit(spells.HOLY_LIGHT, lowestUnit)
        return true
    end
    
    -- Use Flash of Light even without proc if somebody is very low
    if flashOfLight and
       settings.abilitySettings.useFlashOfLight and
       lowestUnit and
       lowestHealth <= (settings.abilitySettings.flashOfLightThreshold - 15) and -- Lower threshold without proc
       currentManaPct > (settings.rotationSettings.manaPooling and settings.rotationSettings.manaPoolingThreshold or 0) and
       API.CanCast(spells.FLASH_OF_LIGHT) then
        API.CastSpellOnUnit(spells.FLASH_OF_LIGHT, lowestUnit)
        return true
    end
    
    -- Use Holy Light for efficient healing
    if holyLight and
       settings.abilitySettings.useHolyLight and
       lowestUnit and
       lowestHealth <= settings.abilitySettings.holyLightThreshold and
       currentManaPct > (settings.rotationSettings.manaPooling and settings.rotationSettings.manaPoolingThreshold or 0) and
       API.CanCast(spells.HOLY_LIGHT) then
        API.CastSpellOnUnit(spells.HOLY_LIGHT, lowestUnit)
        return true
    end
    
    return false
end

-- Handle DPS rotation when no healing is needed
function Holy:HandleDPS(settings)
    -- Skip if not in melee range or no target
    if not isInMelee or not API.UnitExists("target") or not API.IsUnitEnemy("target") then
        return false
    end
    
    -- If Avenging Crusader is active, prioritize DPS abilities
    if avengingCrusaderActive then
        -- Use Judgment
        if judgement and API.CanCast(spells.JUDGMENT) then
            API.CastSpellOnUnit(spells.JUDGMENT, "target")
            return true
        end
        
        -- Use Crusader Strike
        if crusaderStrike and API.CanCast(spells.CRUSADER_STRIKE) then
            API.CastSpellOnUnit(spells.CRUSADER_STRIKE, "target")
            return true
        end
        
        -- Use Hammer of Wrath if available
        if hammerOfWrath and
           (targetHealth < 20 or avengingWrathActive) and
           API.CanCast(spells.HAMMER_OF_WRATH) then
            API.CastSpellOnUnit(spells.HAMMER_OF_WRATH, "target")
            return true
        end
    end
    
    -- Use Judgment to build Holy Power
    if judgement and
       settings.rotationSettings.judgmentWeaving and
       API.CanCast(spells.JUDGMENT) then
        API.CastSpellOnUnit(spells.JUDGMENT, "target")
        return true
    end
    
    -- Use Crusader Strike to build Holy Power
    if crusaderStrike and
       settings.rotationSettings.meleeWeaving and
       currentHolyPower < 5 and -- Don't overcap
       API.CanCast(spells.CRUSADER_STRIKE) then
        API.CastSpellOnUnit(spells.CRUSADER_STRIKE, "target")
        return true
    end
    
    -- Use Hammer of Wrath if target is below 20% health or Avenging Wrath is active
    if hammerOfWrath and
       (targetHealth < 20 or avengingWrathActive) and
       API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpellOnUnit(spells.HAMMER_OF_WRATH, "target")
        return true
    end
    
    -- Use Consecration if nothing else to do
    if consecration and
       isInMelee and
       API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    -- Use Holy Shock offensively if no healing needed
    if holyShock and
       settings.abilityControls.holyShock.allowDamageUse and
       settings.rotationSettings.holyShockPriority ~= "Healing Only" and
       settings.rotationSettings.holyShockPriority ~= "Always Heal" and
       lowHealthAllyCount == 0 and
       API.CanCast(spells.HOLY_SHOCK) then
        API.CastSpellOnUnit(spells.HOLY_SHOCK, "target")
        return true
    end
    
    return false
end

-- Handle specialization change
function Holy:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentManaPct = 100
    currentHolyPower = 0
    maxHolyPower = 5
    beaconTargets = {}
    glimmerTargets = {}
    lightOfDawnTargets = {}
    holyShockCritChance = 0
    divineProtectionActive = false
    divineProtectionEndTime = 0
    avengingWrathActive = false
    avengingWrathEndTime = 0
    holyAvenger = false
    holyAvengerActive = false
    holyAvengerEndTime = 0
    infusionActive = false
    infusionEndTime = 0
    infusionOfLightStacks = 0
    divinePurposeActive = false
    divinePurposeEndTime = 0
    glimmerOfLightActive = false
    divineFavorActive = false
    divineFavorEndTime = 0
    avengingCrusaderActive = false
    avengingCrusaderEndTime = 0
    blessingOfDawnActive = false
    blessingOfDawnEndTime = 0
    blessingOfDuskActive = false
    blessingOfDuskEndTime = 0
    awakeningActive = false
    awakeningEndTime = 0
    ashenHallowActive = false
    ashenHallowEndTime = 0
    divineToilActive = false
    divineToilEndTime = 0
    beaconOfVirtueActive = false
    beaconOfVirtueEndTime = 0
    restorationFlameActive = false
    restorationFlameEndTime = 0
    selflessHealer = false
    selflessHealerStacks = 0
    selflessHealerActive = false
    maraadsDyingBreath = false
    healingHandsActive = false
    healingHandsEndTime = 0
    beaconOfFaith = false
    beaconOfVirtue = false
    divineResonance = false
    beaconOfYore = false
    sacredArbiter = false
    lightsHammer = false
    awakening = false
    holyPrism = false
    divineProtection = false
    holyLight = false
    flashOfLight = false
    wordOfGlory = false
    lightOfDawn = false
    holyShock = false
    judgement = false
    crusaderStrike = false
    divineToil = false
    bestowFaith = false
    blessingOfSacrifice = false
    blessingOfProtection = false
    layOnHands = false
    hammerOfWrath = false
    consecration = false
    divineFavor = false
    avengingCrusader = false
    beaconOfLight = false
    avengingWrath = false
    beaconRoyal = false
    beacon = false
    radiatingLight = false
    restorationFlame = false
    divinePurpose = false
    devotionAura = false
    healingHands = false
    glimmerOfLight = false
    lastHolyShock = 0
    lastCrusaderStrike = 0
    lastJudgement = 0
    lastLayOnHands = 0
    lastWordOfGlory = 0
    lastLightOfDawn = 0
    lastHammerOfWrath = 0
    lastAvengingWrath = 0
    lastBestowFaith = 0
    lastHolyLight = 0
    lastFlashOfLight = 0
    lowHealthAllyCount = 0
    criticalHealthAllyCount = 0
    inRange = false
    targetHealth = 100
    lightOfTheMartyr = false
    beaconTransfer = 0.4
    isInMelee = false
    
    -- Initialize beacon tracking
    self:UpdateBeaconTargets()
    
    API.PrintDebug("Holy Paladin state reset on spec change")
    
    return true
end

-- Return the module for loading
return Holy