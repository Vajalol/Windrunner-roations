------------------------------------------
-- WindrunnerRotations - Holy Priest Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Holy = {}
-- This will be assigned to addon.Classes.Priest.Holy when loaded

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
local tankHealth = 100
local lowestHealth = 100
local highestHealth = 100
local averageHealth = 100
local lowHealthAlliesCount = 0
local criticalHealthAlliesCount = 0
local lightOfTheNaaruActive = false
local apotheosisActive = false
local apotheosisEndTime = 0
local boonOfTheAscendedActive = false
local boonOfTheAscendedStacks = 0
local boonOfTheAscendedEndTime = 0
local flashConcentrationActive = false
local flashConcentrationStacks = 0
local flashConcentrationEndTime = 0
local divineWordActive = false
local divineWordEndTime = 0
local surgeOfLightActive = false
local surgeOfLightStacks = 0
local selfPlayerInCombat = false
local powerWordShieldWeak = false -- Weakened Soul tracking
local powerWordShieldWeakEndTime = 0
local desperatePrayerEndTime = 0
local desperatePrayerActive = false
local currentMana = 100
local maxMana = 100
local sanctifyGround = false
local sanctifyGroundEndTime = 0
local holyWordSanctifyOnCooldown = false
local holyWordSanctifyCooldownRemaining = 0
local holyWordChastiseOnCooldown = false
local holyWordChastiseCooldownRemaining = 0
local holyWordSerenityOnCooldown = false 
local holyWordSerenityCooldownRemaining = 0
local healingCircleActive = false
local guardianSpiritActive = false
local guardianSpiritCooldown = 0
local prayerOfMendingActive = false
local prayerOfMendingChargesLeft = 0
local symbolOfHopeActive = false
local symbolOfHopeEndTime = 0
local comfortTheWeakActive = false
local comfortTheWeakEndTime = 0
local bindingHealGroundActive = false
local bindingHealGroundEndTime = 0
local restitutionActive = false
local restitutionEndTime = 0
local sinsOfTheManyStacks = 0
local hallowedBlessingProc = false
local hallowedCloudActive = false
local divineFavorActive = false
local lightOfTheNaaruInactive = false
local resonantWordsActive = false
local resonantWordsEndTime = 0
local holyWordHarmonyActive = false
local holyWordHarmonyStacks = 0
local blessingOfThoughtActive = false
local blessingOfNaaruActive = false
local empyrealBlissActive = false
local empyrealBlissStacks = 0
local depthsOfInsanityActive = false

-- Constants
local HOLY_SPEC_ID = 257
local DEFAULT_AOE_THRESHOLD = 3
local LOW_HEALTH_THRESHOLD = 75 -- Percentage to consider a player as low health
local CRITICAL_HEALTH_THRESHOLD = 40 -- Percentage to consider a player as critical health
local APOTHEOSIS_DURATION = 20 -- seconds
local BOON_OF_THE_ASCENDED_DURATION = 10 -- seconds
local FLASH_CONCENTRATION_DURATION = 15 -- seconds
local DIVINE_WORD_DURATION = 15 -- seconds
local DESPERATE_PRAYER_DURATION = 10 -- seconds
local SANCTIFY_GROUND_DURATION = 8 -- seconds
local SYMBOL_OF_HOPE_DURATION = 12 -- seconds
local COMFORT_THE_WEAK_DURATION = 4 -- seconds
local BINDING_HEAL_GROUND_DURATION = 6 -- seconds
local RESTITUTION_DURATION = 8 -- seconds
local RESONANT_WORDS_DURATION = 10 -- seconds
local BASE_HEALING_RANGE = 40 -- yards
local HEAL_MANA_COST = 3
local FLASH_HEAL_MANA_COST = 7
local PRAYER_OF_HEALING_MANA_COST = 8
local RENEW_MANA_COST = 4
local GUARDIAN_SPIRIT_CD = 180 -- 3 minutes
local HOLY_WORD_SANCTIFY_CD = 60 -- 1 minute
local HOLY_WORD_SERENITY_CD = 60 -- 1 minute
local HOLY_WORD_CHASTISE_CD = 60 -- 1 minute

-- Initialize the Holy module
function Holy:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Holy Priest module initialized")
    
    return true
end

-- Register spell IDs
function Holy:RegisterSpells()
    -- Core healing abilities
    spells.HEAL = 2060
    spells.FLASH_HEAL = 2061
    spells.PRAYER_OF_HEALING = 596
    spells.RENEW = 139
    spells.PRAYER_OF_MENDING = 33076
    spells.CIRCLE_OF_HEALING = 204883
    spells.DIVINE_HYMN = 64843
    spells.HOLY_WORD_SERENITY = 2050
    spells.HOLY_WORD_SANCTIFY = 34861
    spells.GUARDIAN_SPIRIT = 47788
    spells.BINDING_HEAL = 32546
    spells.DESPERATE_PRAYER = 19236
    spells.POWER_WORD_SHIELD = 17
    
    -- Utility abilities
    spells.PURIFY = 527
    spells.MASS_DISPEL = 32375
    spells.LEAP_OF_FAITH = 73325
    spells.ANGELIC_FEATHER = 121536
    spells.FADE = 586
    spells.HOLY_WORD_CHASTISE = 88625
    spells.SYMBOL_OF_HOPE = 64901
    
    -- Damaging abilities
    spells.HOLY_FIRE = 14914
    spells.SMITE = 585
    spells.HOLY_NOVA = 132157
    
    -- Talents and passives
    spells.APOTHEOSIS = 200183
    spells.DIVINE_WORD = 372760
    spells.SURGE_OF_LIGHT = 109186
    spells.BENEDICTION = 193157
    spells.FLASH_CONCENTRATION = 336267
    spells.LIGHT_OF_THE_NAARU = 196985
    spells.COSMIC_RIPPLE = 238136
    spells.GUARDIAN_ANGEL = 200209
    spells.PERSEVERANCE = 235189
    spells.AFTERLIFE = 196707
    spells.ANGELIC_FEATHER = 121536
    spells.BODY_AND_SOUL = 64129
    spells.TRAIL_OF_LIGHT = 200128
    spells.ENLIGHTENMENT = 193155
    spells.MYSTICISM = 390998
    spells.RENEWED_FAITH = 341997
    spells.CIRCLE_OF_HEALING = 204883
    spells.HARMONIOUS_APPARATUS = 390994
    spells.RESONANT_WORDS = 372370
    spells.PRAYERS_OF_THE_VIRTUOUS = 390977
    spells.HALLOWED_GROUND = 391177
    spells.PRISMATIC_ECHOES = 390967
    spells.WORDS_OF_THE_PIOUS = 390933
    spells.REVELATION = 390786
    spells.DIVINE_SERVICE = 391233
    spells.BINDING_HEALS = 368276
    spells.EMPYREAL_BLISS = 373432
    spells.BREATH_OF_THE_DEVOUT = 373481
    spells.RESTITUTION = 391131
    spells.SACRED_REVERENCE = 372307
    spells.SANCTIFIED_PRAYERS = 196489
    spells.HOLY_ORATION = 391154
    spells.ANSWERED_PRAYERS = 391387
    spells.BLESSING_OF_THOUGHT = 390686
    spells.BLESSING_OF_NAARU = 390624
    spells.DEPTHS_OF_INSANITY = 391079
    spells.HOLY_WORD_HARMONY = 390601
    spells.HOLY_MENDING = 372370
    spells.RAPID_RECOVERY = 373483
    spells.EVERLASTING_LIGHT = 391161
    spells.PRAYER_CIRCLE = 373223
    spells.DIVINE_FAVOR = 393004
    
    -- War Within Season 2 specific
    spells.HEALING_CHORUS = 414689
    spells.HAND_OF_DELIVERANCE = 411209
    spells.ABSOLUTION = 424514
    spells.HEAVENLY_DISCERNMENT = 391237
    spells.BLESSED_RESTORATION = 404770
    spells.LIGHTWELL = 413758
    spells.HEALING_VIRTUES = 373012
    spells.BREATH_OF_HOPE = 401859

    -- Covenant abilities
    spells.BOON_OF_THE_ASCENDED = 325013
    spells.ASCENDED_BLAST = 325283
    spells.ASCENDED_NOVA = 325020
    spells.MINDGAMES = 323673
    spells.UNHOLY_NOVA = 324724
    spells.FAE_GUARDIANS = 327661
    
    -- Buff IDs
    spells.APOTHEOSIS_BUFF = 200183
    spells.DIVINE_WORD_BUFF = 372760
    spells.SURGE_OF_LIGHT_BUFF = 114255
    spells.FLASH_CONCENTRATION_BUFF = 336267
    spells.BOON_OF_THE_ASCENDED_BUFF = 325013
    spells.PRAYER_OF_MENDING_BUFF = 41635
    spells.GUARDIAN_SPIRIT_BUFF = 47788
    spells.DESPERATE_PRAYER_BUFF = 19236
    spells.HOLY_WORD_HARMONY_BUFF = 390615
    spells.DIVINE_FAVOR_BUFF = 393008
    spells.EMPYREAL_BLISS_BUFF = 373434
    spells.RESONANT_WORDS_BUFF = 372372
    spells.BLESSING_OF_THOUGHT_BUFF = 390687
    spells.BLESSING_OF_NAARU_BUFF = 390632
    spells.DEPTHS_OF_INSANITY_BUFF = 391095
    
    -- Debuff IDs
    spells.WEAKENED_SOUL_DEBUFF = 6788
    spells.HOLY_FIRE_DEBUFF = 14914
    spells.CENSURE_DEBUFF = 200199
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.APOTHEOSIS = spells.APOTHEOSIS_BUFF
    buffs.DIVINE_WORD = spells.DIVINE_WORD_BUFF
    buffs.SURGE_OF_LIGHT = spells.SURGE_OF_LIGHT_BUFF
    buffs.FLASH_CONCENTRATION = spells.FLASH_CONCENTRATION_BUFF
    buffs.BOON_OF_THE_ASCENDED = spells.BOON_OF_THE_ASCENDED_BUFF
    buffs.PRAYER_OF_MENDING = spells.PRAYER_OF_MENDING_BUFF
    buffs.GUARDIAN_SPIRIT = spells.GUARDIAN_SPIRIT_BUFF
    buffs.DESPERATE_PRAYER = spells.DESPERATE_PRAYER_BUFF
    buffs.HOLY_WORD_HARMONY = spells.HOLY_WORD_HARMONY_BUFF
    buffs.DIVINE_FAVOR = spells.DIVINE_FAVOR_BUFF
    buffs.EMPYREAL_BLISS = spells.EMPYREAL_BLISS_BUFF
    buffs.RESONANT_WORDS = spells.RESONANT_WORDS_BUFF
    buffs.BLESSING_OF_THOUGHT = spells.BLESSING_OF_THOUGHT_BUFF
    buffs.BLESSING_OF_NAARU = spells.BLESSING_OF_NAARU_BUFF
    buffs.DEPTHS_OF_INSANITY = spells.DEPTHS_OF_INSANITY_BUFF
    
    debuffs.WEAKENED_SOUL = spells.WEAKENED_SOUL_DEBUFF
    debuffs.HOLY_FIRE = spells.HOLY_FIRE_DEBUFF
    debuffs.CENSURE = spells.CENSURE_DEBUFF
    
    return true
end

-- Register variables to track
function Holy:RegisterVariables()
    -- Talent tracking
    talents.hasApotheosis = false
    talents.hasDivineWord = false
    talents.hasSurgeOfLight = false
    talents.hasBenediction = false
    talents.hasFlashConcentration = false
    talents.hasLightOfTheNaaru = false
    talents.hasCosmicRipple = false
    talents.hasGuardianAngel = false
    talents.hasPerseverance = false
    talents.hasAfterlife = false
    talents.hasAngelicFeather = false
    talents.hasBodyAndSoul = false
    talents.hasTrailOfLight = false
    talents.hasEnlightenment = false
    talents.hasMysticism = false
    talents.hasRenewedFaith = false
    talents.hasCircleOfHealing = false
    talents.hasHarmoniousApparatus = false
    talents.hasResonantWords = false
    talents.hasPrayersOfTheVirtuous = false
    talents.hasHallowedGround = false
    talents.hasPrismaticEchoes = false
    talents.hasWordsOfThePious = false
    talents.hasRevelation = false
    talents.hasDivineService = false
    talents.hasBindingHeals = false
    talents.hasEmpyrealBliss = false
    talents.hasBreathOfTheDevout = false
    talents.hasRestitution = false
    talents.hasSacredReverence = false
    talents.hasSanctifiedPrayers = false
    talents.hasHolyOration = false
    talents.hasAnsweredPrayers = false
    talents.hasBlessingOfThought = false
    talents.hasBlessingOfNaaru = false
    talents.hasDepthsOfInsanity = false
    talents.hasHolyWordHarmony = false
    talents.hasHolyMending = false
    talents.hasRapidRecovery = false
    talents.hasEverlastingLight = false
    talents.hasPrayerCircle = false
    talents.hasDivineFavor = false
    
    -- War Within Season 2 talents
    talents.hasHealingChorus = false
    talents.hasHandOfDeliverance = false
    talents.hasAbsolution = false
    talents.hasHeavenlyDiscernment = false
    talents.hasBlessedRestoration = false
    talents.hasLightwell = false
    talents.hasHealingVirtues = false
    talents.hasBreathOfHope = false
    
    -- Initialize mana
    currentMana = API.GetPlayerPower()
    
    return true
end

-- Register spec-specific settings
function Holy:RegisterSettings()
    ConfigRegistry:RegisterSettings("HolyPriest", {
        healingSettings = {
            healingStyle = {
                displayName = "Healing Style",
                description = "Overall approach to healing",
                type = "dropdown",
                options = {"Reactive", "Proactive", "Balanced", "Mana Efficient"},
                default = "Balanced"
            },
            targetSelectionMethod = {
                displayName = "Target Selection",
                description = "How to prioritize healing targets",
                type = "dropdown",
                options = {"Lowest Health", "Tank Priority", "Raid Role Priority", "Smart Selection"},
                default = "Smart Selection"
            },
            spellSelectionMethod = {
                displayName = "Spell Selection",
                description = "How to choose which healing spell to use",
                type = "dropdown",
                options = {"Highest Throughput", "Mana Efficient", "Situational", "Haste-Based"},
                default = "Situational"
            },
            manaManagement = {
                displayName = "Mana Management",
                description = "How to manage mana during an encounter",
                type = "dropdown",
                options = {"Conservative", "Balanced", "Aggressive", "Encounter-Based"},
                default = "Balanced"
            },
            lowHealthThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage to consider a player as low health",
                type = "slider",
                min = 50,
                max = 90,
                default = LOW_HEALTH_THRESHOLD
            },
            criticalHealthThreshold = {
                displayName = "Critical Health Threshold",
                description = "Health percentage to consider a player as critical health",
                type = "slider",
                min = 20,
                max = 60,
                default = CRITICAL_HEALTH_THRESHOLD
            }
        },
        
        spellSettings = {
            useHeal = {
                displayName = "Use Heal",
                description = "When to use Heal",
                type = "dropdown",
                options = {"Never", "Mana Conservation", "With Flash Concentration", "Always"},
                default = "With Flash Concentration"
            },
            useFlashHeal = {
                displayName = "Use Flash Heal",
                description = "When to use Flash Heal",
                type = "dropdown",
                options = {"Emergency Only", "Low Health", "With Surge of Light", "Freely"},
                default = "Low Health"
            },
            usePrayerOfHealing = {
                displayName = "Use Prayer of Healing",
                description = "When to use Prayer of Healing",
                type = "dropdown",
                options = {"Never", "Multiple Injured", "With Divine Word", "Liberally"},
                default = "Multiple Injured"
            },
            usePrayerOfHealingThreshold = {
                displayName = "Prayer of Healing Threshold",
                description = "Minimum injured allies to use Prayer of Healing",
                type = "slider",
                min = 3,
                max = 8,
                default = 3
            },
            useCircleOfHealing = {
                displayName = "Use Circle of Healing",
                description = "Automatically use Circle of Healing",
                type = "toggle",
                default = true
            },
            useCircleOfHealingThreshold = {
                displayName = "Circle of Healing Threshold",
                description = "Minimum injured allies to use Circle of Healing",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            usePrayerOfMending = {
                displayName = "Use Prayer of Mending",
                description = "Automatically use Prayer of Mending",
                type = "toggle",
                default = true
            },
            useBindingHeal = {
                displayName = "Use Binding Heal",
                description = "When to use Binding Heal",
                type = "dropdown",
                options = {"Never", "Dual Healing", "With Binding Heals Talent", "Preferred"},
                default = "Dual Healing"
            },
            useRenew = {
                displayName = "Use Renew",
                description = "When to use Renew",
                type = "dropdown",
                options = {"Never", "Tank Only", "Movement Only", "On Cooldown"},
                default = "Movement Only"
            }
        },
        
        cooldownSettings = {
            useHolyWordSerenity = {
                displayName = "Use Holy Word: Serenity",
                description = "Automatically use Holy Word: Serenity",
                type = "toggle",
                default = true
            },
            holyWordSerenityThreshold = {
                displayName = "Holy Word: Serenity Threshold",
                description = "Health percentage to use Holy Word: Serenity",
                type = "slider",
                min = 20,
                max = 70,
                default = 40
            },
            useHolyWordSanctify = {
                displayName = "Use Holy Word: Sanctify",
                description = "Automatically use Holy Word: Sanctify",
                type = "toggle",
                default = true
            },
            holyWordSanctifyThreshold = {
                displayName = "Holy Word: Sanctify Injured Count",
                description = "Minimum injured allies to use Holy Word: Sanctify",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useGuardianSpirit = {
                displayName = "Use Guardian Spirit",
                description = "Automatically use Guardian Spirit",
                type = "toggle",
                default = true
            },
            guardianSpiritThreshold = {
                displayName = "Guardian Spirit Threshold",
                description = "Health percentage to use Guardian Spirit",
                type = "slider",
                min = 10,
                max = 30,
                default = 20
            },
            useDivineHymn = {
                displayName = "Use Divine Hymn",
                description = "Automatically use Divine Hymn",
                type = "toggle",
                default = true
            },
            divineHymnThreshold = {
                displayName = "Divine Hymn Threshold",
                description = "Average raid health to use Divine Hymn",
                type = "slider",
                min = 40,
                max = 80,
                default = 60
            },
            divineHymnInjuredCount = {
                displayName = "Divine Hymn Injured Count",
                description = "Minimum injured allies to use Divine Hymn",
                type = "slider",
                min = 3,
                max = 10,
                default = 5
            }
        },
        
        defensiveSettings = {
            useDesperatePrayer = {
                displayName = "Use Desperate Prayer",
                description = "Automatically use Desperate Prayer",
                type = "toggle",
                default = true
            },
            desperatePrayerThreshold = {
                displayName = "Desperate Prayer Threshold",
                description = "Health percentage to use Desperate Prayer",
                type = "slider",
                min = 20,
                max = 80,
                default = 50
            },
            usePowerWordShield = {
                displayName = "Use Power Word: Shield",
                description = "Automatically use Power Word: Shield",
                type = "toggle",
                default = true
            },
            powerWordShieldThreshold = {
                displayName = "Power Word: Shield Threshold",
                description = "Health percentage to use Power Word: Shield",
                type = "slider",
                min = 30,
                max = 90,
                default = 70
            },
            useFade = {
                displayName = "Use Fade",
                description = "Automatically use Fade when taking damage",
                type = "toggle",
                default = true
            }
        },
        
        utilitySettings = {
            useAngFeatherMovement = {
                displayName = "Use Angelic Feather",
                description = "Automatically use Angelic Feather for movement",
                type = "toggle",
                default = true
            },
            useLeapOfFaith = {
                displayName = "Use Leap of Faith",
                description = "Automatically use Leap of Faith on endangered allies",
                type = "toggle",
                default = true
            },
            leapOfFaithThreshold = {
                displayName = "Leap of Faith Threshold",
                description = "Health percentage to use Leap of Faith",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            },
            usePurify = {
                displayName = "Use Purify",
                description = "Automatically use Purify to remove debuffs",
                type = "toggle",
                default = true
            },
            useMassDispel = {
                displayName = "Use Mass Dispel",
                description = "Automatically use Mass Dispel for group debuffs",
                type = "toggle",
                default = true
            },
            massDispelThreshold = {
                displayName = "Mass Dispel Threshold",
                description = "Minimum debuffed allies to use Mass Dispel",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            }
        },
        
        damageSettings = {
            useDps = {
                displayName = "Use DPS Abilities",
                description = "Use damage abilities when healing isn't needed",
                type = "toggle",
                default = true
            },
            useHolyFire = {
                displayName = "Use Holy Fire",
                description = "Automatically use Holy Fire",
                type = "toggle",
                default = true
            },
            useSmite = {
                displayName = "Use Smite",
                description = "Automatically use Smite",
                type = "toggle",
                default = true
            },
            useHolyNova = {
                displayName = "Use Holy Nova",
                description = "Automatically use Holy Nova for AoE damage",
                type = "toggle",
                default = true
            },
            holyNovaThreshold = {
                displayName = "Holy Nova Threshold",
                description = "Minimum enemies to use Holy Nova",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            useHolyWordChastise = {
                displayName = "Use Holy Word: Chastise",
                description = "Automatically use Holy Word: Chastise",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Apotheosis controls
            apotheosis = AAC.RegisterAbility(spells.APOTHEOSIS, {
                enabled = true,
                useDuringBurstOnly = true,
                minInjuredAllies = 4
            }),
            
            -- Divine Hymn controls
            divineHymn = AAC.RegisterAbility(spells.DIVINE_HYMN, {
                enabled = true,
                useDuringBurstOnly = false,
                minInjuredAllies = 5,
                minAverageHealthDeficit = 30
            }),
            
            -- Symbol of Hope controls
            symbolOfHope = AAC.RegisterAbility(spells.SYMBOL_OF_HOPE, {
                enabled = true,
                useDuringBurstOnly = false,
                minManaDeficit = 40
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
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        selfPlayerInCombat = true
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        selfPlayerInCombat = false
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
function Holy:UpdateTalentInfo()
    -- Check for important talents
    talents.hasApotheosis = API.HasTalent(spells.APOTHEOSIS)
    talents.hasDivineWord = API.HasTalent(spells.DIVINE_WORD)
    talents.hasSurgeOfLight = API.HasTalent(spells.SURGE_OF_LIGHT)
    talents.hasBenediction = API.HasTalent(spells.BENEDICTION)
    talents.hasFlashConcentration = API.HasTalent(spells.FLASH_CONCENTRATION)
    talents.hasLightOfTheNaaru = API.HasTalent(spells.LIGHT_OF_THE_NAARU)
    talents.hasCosmicRipple = API.HasTalent(spells.COSMIC_RIPPLE)
    talents.hasGuardianAngel = API.HasTalent(spells.GUARDIAN_ANGEL)
    talents.hasPerseverance = API.HasTalent(spells.PERSEVERANCE)
    talents.hasAfterlife = API.HasTalent(spells.AFTERLIFE)
    talents.hasAngelicFeather = API.HasTalent(spells.ANGELIC_FEATHER)
    talents.hasBodyAndSoul = API.HasTalent(spells.BODY_AND_SOUL)
    talents.hasTrailOfLight = API.HasTalent(spells.TRAIL_OF_LIGHT)
    talents.hasEnlightenment = API.HasTalent(spells.ENLIGHTENMENT)
    talents.hasMysticism = API.HasTalent(spells.MYSTICISM)
    talents.hasRenewedFaith = API.HasTalent(spells.RENEWED_FAITH)
    talents.hasCircleOfHealing = API.HasTalent(spells.CIRCLE_OF_HEALING)
    talents.hasHarmoniousApparatus = API.HasTalent(spells.HARMONIOUS_APPARATUS)
    talents.hasResonantWords = API.HasTalent(spells.RESONANT_WORDS)
    talents.hasPrayersOfTheVirtuous = API.HasTalent(spells.PRAYERS_OF_THE_VIRTUOUS)
    talents.hasHallowedGround = API.HasTalent(spells.HALLOWED_GROUND)
    talents.hasPrismaticEchoes = API.HasTalent(spells.PRISMATIC_ECHOES)
    talents.hasWordsOfThePious = API.HasTalent(spells.WORDS_OF_THE_PIOUS)
    talents.hasRevelation = API.HasTalent(spells.REVELATION)
    talents.hasDivineService = API.HasTalent(spells.DIVINE_SERVICE)
    talents.hasBindingHeals = API.HasTalent(spells.BINDING_HEALS)
    talents.hasEmpyrealBliss = API.HasTalent(spells.EMPYREAL_BLISS)
    talents.hasBreathOfTheDevout = API.HasTalent(spells.BREATH_OF_THE_DEVOUT)
    talents.hasRestitution = API.HasTalent(spells.RESTITUTION)
    talents.hasSacredReverence = API.HasTalent(spells.SACRED_REVERENCE)
    talents.hasSanctifiedPrayers = API.HasTalent(spells.SANCTIFIED_PRAYERS)
    talents.hasHolyOration = API.HasTalent(spells.HOLY_ORATION)
    talents.hasAnsweredPrayers = API.HasTalent(spells.ANSWERED_PRAYERS)
    talents.hasBlessingOfThought = API.HasTalent(spells.BLESSING_OF_THOUGHT)
    talents.hasBlessingOfNaaru = API.HasTalent(spells.BLESSING_OF_NAARU)
    talents.hasDepthsOfInsanity = API.HasTalent(spells.DEPTHS_OF_INSANITY)
    talents.hasHolyWordHarmony = API.HasTalent(spells.HOLY_WORD_HARMONY)
    talents.hasHolyMending = API.HasTalent(spells.HOLY_MENDING)
    talents.hasRapidRecovery = API.HasTalent(spells.RAPID_RECOVERY)
    talents.hasEverlastingLight = API.HasTalent(spells.EVERLASTING_LIGHT)
    talents.hasPrayerCircle = API.HasTalent(spells.PRAYER_CIRCLE)
    talents.hasDivineFavor = API.HasTalent(spells.DIVINE_FAVOR)
    
    -- War Within Season 2 talents
    talents.hasHealingChorus = API.HasTalent(spells.HEALING_CHORUS)
    talents.hasHandOfDeliverance = API.HasTalent(spells.HAND_OF_DELIVERANCE)
    talents.hasAbsolution = API.HasTalent(spells.ABSOLUTION)
    talents.hasHeavenlyDiscernment = API.HasTalent(spells.HEAVENLY_DISCERNMENT)
    talents.hasBlessedRestoration = API.HasTalent(spells.BLESSED_RESTORATION)
    talents.hasLightwell = API.HasTalent(spells.LIGHTWELL)
    talents.hasHealingVirtues = API.HasTalent(spells.HEALING_VIRTUES)
    talents.hasBreathOfHope = API.HasTalent(spells.BREATH_OF_HOPE)
    
    -- Set specialized variables based on talents
    if talents.hasLightOfTheNaaru then
        lightOfTheNaaruActive = true
    end
    
    if talents.hasDivineFavor then
        divineFavorActive = true
    end
    
    if talents.hasBlessingOfThought then
        blessingOfThoughtActive = true
    end
    
    if talents.hasBlessingOfNaaru then
        blessingOfNaaruActive = true
    end
    
    if talents.hasDepthsOfInsanity then
        depthsOfInsanityActive = true
    }
    
    if talents.hasEmpyrealBliss then
        empyrealBlissActive = true
    }
    
    API.PrintDebug("Holy Priest talents updated")
    
    return true
end

-- Update mana tracking
function Holy:UpdateMana()
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    return true
end

-- Handle combat log events
function Holy:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Apotheosis
            if spellID == buffs.APOTHEOSIS then
                apotheosisActive = true
                apotheosisEndTime = GetTime() + APOTHEOSIS_DURATION
                API.PrintDebug("Apotheosis activated")
            end
            
            -- Track Divine Word
            if spellID == buffs.DIVINE_WORD then
                divineWordActive = true
                divineWordEndTime = GetTime() + DIVINE_WORD_DURATION
                API.PrintDebug("Divine Word activated")
            end
            
            -- Track Surge of Light
            if spellID == buffs.SURGE_OF_LIGHT then
                surgeOfLightActive = true
                surgeOfLightStacks = select(4, API.GetBuffInfo("player", buffs.SURGE_OF_LIGHT)) or 1
                API.PrintDebug("Surge of Light activated: " .. tostring(surgeOfLightStacks) .. " stacks")
            end
            
            -- Track Flash Concentration
            if spellID == buffs.FLASH_CONCENTRATION then
                flashConcentrationActive = true
                flashConcentrationStacks = select(4, API.GetBuffInfo("player", buffs.FLASH_CONCENTRATION)) or 1
                flashConcentrationEndTime = GetTime() + FLASH_CONCENTRATION_DURATION
                API.PrintDebug("Flash Concentration active: " .. tostring(flashConcentrationStacks) .. " stacks")
            end
            
            -- Track Boon of the Ascended
            if spellID == buffs.BOON_OF_THE_ASCENDED then
                boonOfTheAscendedActive = true
                boonOfTheAscendedStacks = select(4, API.GetBuffInfo("player", buffs.BOON_OF_THE_ASCENDED)) or 0
                boonOfTheAscendedEndTime = GetTime() + BOON_OF_THE_ASCENDED_DURATION
                API.PrintDebug("Boon of the Ascended activated")
            end
            
            -- Track Desperate Prayer
            if spellID == buffs.DESPERATE_PRAYER then
                desperatePrayerActive = true
                desperatePrayerEndTime = GetTime() + DESPERATE_PRAYER_DURATION
                API.PrintDebug("Desperate Prayer activated")
            end
            
            -- Track Holy Word Harmony
            if spellID == buffs.HOLY_WORD_HARMONY then
                holyWordHarmonyActive = true
                holyWordHarmonyStacks = select(4, API.GetBuffInfo("player", buffs.HOLY_WORD_HARMONY)) or 0
                API.PrintDebug("Holy Word Harmony activated: " .. tostring(holyWordHarmonyStacks) .. " stacks")
            end
            
            -- Track Divine Favor
            if spellID == buffs.DIVINE_FAVOR then
                divineFavorActive = true
                API.PrintDebug("Divine Favor activated")
            end
            
            -- Track Empyreal Bliss
            if spellID == buffs.EMPYREAL_BLISS then
                empyrealBlissActive = true
                empyrealBlissStacks = select(4, API.GetBuffInfo("player", buffs.EMPYREAL_BLISS)) or 0
                API.PrintDebug("Empyreal Bliss active: " .. tostring(empyrealBlissStacks) .. " stacks")
            end
            
            -- Track Resonant Words
            if spellID == buffs.RESONANT_WORDS then
                resonantWordsActive = true
                resonantWordsEndTime = GetTime() + RESONANT_WORDS_DURATION
                API.PrintDebug("Resonant Words activated")
            end
            
            -- Track Blessing of Thought
            if spellID == buffs.BLESSING_OF_THOUGHT then
                blessingOfThoughtActive = true
                API.PrintDebug("Blessing of Thought activated")
            end
            
            -- Track Blessing of Naaru
            if spellID == buffs.BLESSING_OF_NAARU then
                blessingOfNaaruActive = true
                API.PrintDebug("Blessing of Naaru activated")
            end
            
            -- Track Depths of Insanity
            if spellID == buffs.DEPTHS_OF_INSANITY then
                depthsOfInsanityActive = true
                API.PrintDebug("Depths of Insanity activated")
            end
        end
        
        -- Track Weakened Soul debuff
        if spellID == debuffs.WEAKENED_SOUL and destGUID == API.GetPlayerGUID() then
            powerWordShieldWeak = true
            powerWordShieldWeakEndTime = select(6, API.GetDebuffInfo("player", debuffs.WEAKENED_SOUL)) or 0
            API.PrintDebug("Weakened Soul applied")
        end
        
        -- Track Guardian Spirit on targets
        if spellID == buffs.GUARDIAN_SPIRIT then
            guardianSpiritActive = true
            API.PrintDebug("Guardian Spirit activated")
        end
        
        -- Track Prayer of Mending active
        if spellID == buffs.PRAYER_OF_MENDING then
            prayerOfMendingActive = true
            prayerOfMendingChargesLeft = select(4, API.GetBuffInfo(destName, buffs.PRAYER_OF_MENDING)) or 0
            API.PrintDebug("Prayer of Mending active on " .. destName .. ": " .. tostring(prayerOfMendingChargesLeft) .. " charges")
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Apotheosis removal
            if spellID == buffs.APOTHEOSIS then
                apotheosisActive = false
                API.PrintDebug("Apotheosis faded")
            end
            
            -- Track Divine Word removal
            if spellID == buffs.DIVINE_WORD then
                divineWordActive = false
                API.PrintDebug("Divine Word faded")
            end
            
            -- Track Surge of Light removal
            if spellID == buffs.SURGE_OF_LIGHT then
                surgeOfLightActive = false
                surgeOfLightStacks = 0
                API.PrintDebug("Surge of Light consumed")
            end
            
            -- Track Flash Concentration removal
            if spellID == buffs.FLASH_CONCENTRATION then
                flashConcentrationActive = false
                flashConcentrationStacks = 0
                API.PrintDebug("Flash Concentration faded")
            end
            
            -- Track Boon of the Ascended removal
            if spellID == buffs.BOON_OF_THE_ASCENDED then
                boonOfTheAscendedActive = false
                boonOfTheAscendedStacks = 0
                API.PrintDebug("Boon of the Ascended faded")
            end
            
            -- Track Desperate Prayer removal
            if spellID == buffs.DESPERATE_PRAYER then
                desperatePrayerActive = false
                API.PrintDebug("Desperate Prayer faded")
            end
            
            -- Track Holy Word Harmony removal
            if spellID == buffs.HOLY_WORD_HARMONY then
                holyWordHarmonyActive = false
                holyWordHarmonyStacks = 0
                API.PrintDebug("Holy Word Harmony faded")
            end
            
            -- Track Divine Favor removal
            if spellID == buffs.DIVINE_FAVOR then
                divineFavorActive = false
                API.PrintDebug("Divine Favor faded")
            end
            
            -- Track Empyreal Bliss removal
            if spellID == buffs.EMPYREAL_BLISS then
                empyrealBlissActive = false
                empyrealBlissStacks = 0
                API.PrintDebug("Empyreal Bliss faded")
            end
            
            -- Track Resonant Words removal
            if spellID == buffs.RESONANT_WORDS then
                resonantWordsActive = false
                API.PrintDebug("Resonant Words faded")
            end
            
            -- Track Blessing of Thought removal
            if spellID == buffs.BLESSING_OF_THOUGHT then
                blessingOfThoughtActive = false
                API.PrintDebug("Blessing of Thought faded")
            end
            
            -- Track Blessing of Naaru removal
            if spellID == buffs.BLESSING_OF_NAARU then
                blessingOfNaaruActive = false
                API.PrintDebug("Blessing of Naaru faded")
            end
            
            -- Track Depths of Insanity removal
            if spellID == buffs.DEPTHS_OF_INSANITY then
                depthsOfInsanityActive = false
                API.PrintDebug("Depths of Insanity faded")
            end
        end
        
        -- Track Weakened Soul debuff removal
        if spellID == debuffs.WEAKENED_SOUL and destGUID == API.GetPlayerGUID() then
            powerWordShieldWeak = false
            API.PrintDebug("Weakened Soul faded")
        end
        
        -- Track Guardian Spirit removal
        if spellID == buffs.GUARDIAN_SPIRIT then
            guardianSpiritActive = false
            API.PrintDebug("Guardian Spirit faded")
        end
        
        -- Track Prayer of Mending removal
        if spellID == buffs.PRAYER_OF_MENDING then
            prayerOfMendingActive = false
            prayerOfMendingChargesLeft = 0
            API.PrintDebug("Prayer of Mending faded from " .. destName)
        end
    end
    
    -- Track Flash Concentration stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FLASH_CONCENTRATION and destGUID == API.GetPlayerGUID() then
        flashConcentrationStacks = select(4, API.GetBuffInfo("player", buffs.FLASH_CONCENTRATION)) or 0
        API.PrintDebug("Flash Concentration stacks: " .. tostring(flashConcentrationStacks))
    end
    
    -- Track Boon of the Ascended stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.BOON_OF_THE_ASCENDED and destGUID == API.GetPlayerGUID() then
        boonOfTheAscendedStacks = select(4, API.GetBuffInfo("player", buffs.BOON_OF_THE_ASCENDED)) or 0
        API.PrintDebug("Boon of the Ascended stacks: " .. tostring(boonOfTheAscendedStacks))
    end
    
    -- Track Holy Word Harmony stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.HOLY_WORD_HARMONY and destGUID == API.GetPlayerGUID() then
        holyWordHarmonyStacks = select(4, API.GetBuffInfo("player", buffs.HOLY_WORD_HARMONY)) or 0
        API.PrintDebug("Holy Word Harmony stacks: " .. tostring(holyWordHarmonyStacks))
    end
    
    -- Track Empyreal Bliss stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.EMPYREAL_BLISS and destGUID == API.GetPlayerGUID() then
        empyrealBlissStacks = select(4, API.GetBuffInfo("player", buffs.EMPYREAL_BLISS)) or 0
        API.PrintDebug("Empyreal Bliss stacks: " .. tostring(empyrealBlissStacks))
    end
    
    -- Track prayer of mending charges
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.PRAYER_OF_MENDING then
        prayerOfMendingChargesLeft = select(4, API.GetBuffInfo(destName, buffs.PRAYER_OF_MENDING)) or 0
        API.PrintDebug("Prayer of Mending charges on " .. destName .. ": " .. tostring(prayerOfMendingChargesLeft))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        -- Track Holy Word cooldowns
        if spellID == spells.HOLY_WORD_SANCTIFY then
            holyWordSanctifyOnCooldown = true
            holyWordSanctifyCooldownRemaining = HOLY_WORD_SANCTIFY_CD
            if talents.hasHolyOration then
                holyWordSanctifyCooldownRemaining = holyWordSanctifyCooldownRemaining * 0.8 -- 20% CDR from talent
            end
            API.PrintDebug("Holy Word: Sanctify cast")
        elseif spellID == spells.HOLY_WORD_SERENITY then
            holyWordSerenityOnCooldown = true
            holyWordSerenityCooldownRemaining = HOLY_WORD_SERENITY_CD
            if talents.hasHolyOration then
                holyWordSerenityCooldownRemaining = holyWordSerenityCooldownRemaining * 0.8 -- 20% CDR from talent
            end
            API.PrintDebug("Holy Word: Serenity cast")
        elseif spellID == spells.HOLY_WORD_CHASTISE then
            holyWordChastiseOnCooldown = true
            holyWordChastiseCooldownRemaining = HOLY_WORD_CHASTISE_CD
            if talents.hasHolyOration then
                holyWordChastiseCooldownRemaining = holyWordChastiseCooldownRemaining * 0.8 -- 20% CDR from talent
            end
            API.PrintDebug("Holy Word: Chastise cast")
        elseif spellID == spells.HEAL then
            -- Track for Flash Concentration stacks
            API.PrintDebug("Heal cast")
        elseif spellID == spells.FLASH_HEAL then
            -- Track for Surge of Light
            API.PrintDebug("Flash Heal cast")
        elseif spellID == spells.PRAYER_OF_HEALING then
            API.PrintDebug("Prayer of Healing cast")
        elseif spellID == spells.CIRCLE_OF_HEALING then
            healingCircleActive = true
            API.PrintDebug("Circle of Healing cast")
        elseif spellID == spells.GUARDIAN_SPIRIT then
            guardianSpiritActive = true
            guardianSpiritCooldown = GUARDIAN_SPIRIT_CD
            
            -- Apply Guardian Angel cooldown reduction if talented
            if talents.hasGuardianAngel then
                guardianSpiritCooldown = guardianSpiritCooldown * 0.7 -- 30% CDR
            end
            
            -- Set a timer to track when it ends
            C_Timer.After(guardianSpiritCooldown, function()
                guardianSpiritCooldown = 0
                API.PrintDebug("Guardian Spirit cooldown reset")
            end)
            
            API.PrintDebug("Guardian Spirit cast")
        elseif spellID == spells.PRAYER_OF_MENDING then
            prayerOfMendingActive = true
            prayerOfMendingChargesLeft = 5 -- Default charges (may be modified by talents)
            
            if talents.hasPrayersOfTheVirtuous then
                prayerOfMendingChargesLeft = 6 -- +1 from talent
            end
            
            API.PrintDebug("Prayer of Mending cast")
        elseif spellID == spells.APOTHEOSIS then
            apotheosisActive = true
            apotheosisEndTime = GetTime() + APOTHEOSIS_DURATION
            API.PrintDebug("Apotheosis cast")
        elseif spellID == spells.DIVINE_WORD then
            divineWordActive = true
            divineWordEndTime = GetTime() + DIVINE_WORD_DURATION
            API.PrintDebug("Divine Word cast")
        elseif spellID == spells.DESPERATE_PRAYER then
            desperatePrayerActive = true
            desperatePrayerEndTime = GetTime() + DESPERATE_PRAYER_DURATION
            API.PrintDebug("Desperate Prayer cast")
        elseif spellID == spells.SYMBOL_OF_HOPE then
            symbolOfHopeActive = true
            symbolOfHopeEndTime = GetTime() + SYMBOL_OF_HOPE_DURATION
            API.PrintDebug("Symbol of Hope cast")
        end
    end
    
    -- Track specific heal events to handle Harmonious Apparatus
    if talents.hasHarmoniousApparatus and (eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL") then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.HEAL or spellID == spells.FLASH_HEAL then
                -- Reduce Serenity cooldown
                if holyWordSerenityOnCooldown then
                    holyWordSerenityCooldownRemaining = math.max(0, holyWordSerenityCooldownRemaining - 1)
                    if holyWordSerenityCooldownRemaining == 0 then
                        holyWordSerenityOnCooldown = false
                        API.PrintDebug("Holy Word: Serenity cooldown reset by Harmonious Apparatus")
                    end
                end
            elseif spellID == spells.PRAYER_OF_HEALING then
                -- Reduce Sanctify cooldown
                if holyWordSanctifyOnCooldown then
                    holyWordSanctifyCooldownRemaining = math.max(0, holyWordSanctifyCooldownRemaining - 1)
                    if holyWordSanctifyCooldownRemaining == 0 then
                        holyWordSanctifyOnCooldown = false
                        API.PrintDebug("Holy Word: Sanctify cooldown reset by Harmonious Apparatus")
                    end
                end
            end
        end
    }
    
    return true
end

-- Update healing targets and health
function Holy:UpdateHealingTargets()
    -- Initialize variables
    tankHealth = 100
    lowestHealth = 100
    highestHealth = 100
    averageHealth = 100
    lowHealthAlliesCount = 0
    criticalHealthAlliesCount = 0
    
    -- First get setting thresholds
    local settings = ConfigRegistry:GetSettings("HolyPriest")
    local lowHealthThreshold = settings.healingSettings.lowHealthThreshold
    local criticalHealthThreshold = settings.healingSettings.criticalHealthThreshold
    
    -- Get party or raid size
    local inRaid = API.IsInRaid()
    local unitPrefix = inRaid and "raid" or "party"
    local unitCount = inRaid and API.GetRaidSize() or API.GetPartySize()
    
    -- Track total health percentages for averaging
    local totalHealthPercent = 0
    local totalUnits = 0
    
    -- Process each unit
    for i = 1, unitCount do
        local unit = unitPrefix .. i
        if API.UnitExists(unit) and API.UnitIsVisible(unit) then
            local healthPercent = API.GetUnitHealthPercent(unit)
            totalHealthPercent = totalHealthPercent + healthPercent
            totalUnits = totalUnits + 1
            
            -- Track lowest health
            if healthPercent < lowestHealth then
                lowestHealth = healthPercent
            end
            
            -- Track highest health
            if healthPercent > highestHealth then
                highestHealth = healthPercent
            end
            
            -- Track low health allies
            if healthPercent <= lowHealthThreshold then
                lowHealthAlliesCount = lowHealthAlliesCount + 1
            end
            
            -- Track critical health allies
            if healthPercent <= criticalHealthThreshold then
                criticalHealthAlliesCount = criticalHealthAlliesCount + 1
            end
            
            -- Track tank health
            if API.UnitIsTank(unit) and healthPercent < tankHealth then
                tankHealth = healthPercent
            end
        end
    end
    
    -- Also check player health
    local playerHealth = API.GetPlayerHealthPercent()
    totalHealthPercent = totalHealthPercent + playerHealth
    totalUnits = totalUnits + 1
    
    -- Track lowest health including player
    if playerHealth < lowestHealth then
        lowestHealth = playerHealth
    end
    
    -- Track highest health including player
    if playerHealth > highestHealth then
        highestHealth = playerHealth
    end
    
    -- Track low health including player
    if playerHealth <= lowHealthThreshold then
        lowHealthAlliesCount = lowHealthAlliesCount + 1
    end
    
    -- Track critical health including player
    if playerHealth <= criticalHealthThreshold then
        criticalHealthAlliesCount = criticalHealthAlliesCount + 1
    end
    
    -- Calculate average health
    averageHealth = totalHealthPercent / totalUnits
    
    -- Debug info
    API.PrintDebug("Healing info - Low: " .. lowestHealth .. "%, Avg: " .. averageHealth .. "%, Tank: " .. tankHealth .. "%, Low allies: " .. lowHealthAlliesCount .. ", Critical: " .. criticalHealthAlliesCount)
    
    return true
end

-- Main rotation function
function Holy:RunRotation()
    -- Check if we should be running Holy Priest logic
    if API.GetActiveSpecID() ~= HOLY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("HolyPriest")
    
    -- Update variables
    self:UpdateMana()
    self:UpdateHealingTargets()
    burstModeActive = settings.healingSettings.healingStyle == "Aggressive" or API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle dispel first (high priority)
    if self:HandleDispelMagic(settings) then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle emergency healing (highest priority)
    if self:HandleEmergencyHealing(settings) then
        return true
    end
    
    -- Handle cooldowns
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle normal healing
    if self:HandleNormalHealing(settings) then
        return true
    end
    
    -- Handle damage abilities
    if settings.damageSettings.useDps and self:HandleDamage(settings) then
        return true
    end
    
    return false
end

-- Handle dispel magic
function Holy:HandleDispelMagic(settings)
    -- Use Purify
    if settings.utilitySettings.usePurify and API.CanCast(spells.PURIFY) then
        local dispellableTarget = API.FindDispellableTarget({"Magic", "Disease"})
        if dispellableTarget then
            API.CastSpellOnUnit(spells.PURIFY, dispellableTarget)
            return true
        end
    end
    
    -- Use Mass Dispel
    if settings.utilitySettings.useMassDispel and API.CanCast(spells.MASS_DISPEL) then
        local dispellableCount = API.CountDispellableTargets({"Magic"})
        if dispellableCount >= settings.utilitySettings.massDispelThreshold then
            API.CastSpellAtCursor(spells.MASS_DISPEL)
            return true
        end
    end
    
    return false
end

-- Handle defensive abilities
function Holy:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Desperate Prayer
    if settings.defensiveSettings.useDesperatePrayer and
       playerHealth <= settings.defensiveSettings.desperatePrayerThreshold and
       not desperatePrayerActive and
       API.CanCast(spells.DESPERATE_PRAYER) then
        API.CastSpell(spells.DESPERATE_PRAYER)
        return true
    end
    
    -- Use Power Word: Shield
    if settings.defensiveSettings.usePowerWordShield and
       playerHealth <= settings.defensiveSettings.powerWordShieldThreshold and
       not powerWordShieldWeak and
       API.CanCast(spells.POWER_WORD_SHIELD) then
        API.CastSpellOnSelf(spells.POWER_WORD_SHIELD)
        return true
    end
    
    -- Use Fade when taking damage
    if settings.defensiveSettings.useFade and
       API.IsPlayerTakingDamage() and
       API.CanCast(spells.FADE) then
        API.CastSpell(spells.FADE)
        return true
    end
    
    return false
end

-- Handle emergency healing
function Holy:HandleEmergencyHealing(settings)
    -- Check for critical health players
    if criticalHealthAlliesCount > 0 || lowestHealth <= settings.healingSettings.criticalHealthThreshold then
        -- Use Guardian Spirit on very low health tank
        if settings.cooldownSettings.useGuardianSpirit and
           tankHealth <= settings.cooldownSettings.guardianSpiritThreshold and
           API.CanCast(spells.GUARDIAN_SPIRIT) then
            local tankUnit = API.FindLowestHealthTank()
            if tankUnit then
                API.CastSpellOnUnit(spells.GUARDIAN_SPIRIT, tankUnit)
                return true
            end
        end
        
        -- Use Holy Word: Serenity on critically low health target
        if settings.cooldownSettings.useHolyWordSerenity and
           not holyWordSerenityOnCooldown and
           API.CanCast(spells.HOLY_WORD_SERENITY) then
            local lowestUnit = API.FindLowestHealthTarget()
            if lowestUnit and API.GetUnitHealthPercent(lowestUnit) <= settings.cooldownSettings.holyWordSerenityThreshold then
                API.CastSpellOnUnit(spells.HOLY_WORD_SERENITY, lowestUnit)
                return true
            }
        end
        
        -- Use Flash Heal on critically low health target
        if API.CanCast(spells.FLASH_HEAL) then
            local lowestUnit = API.FindLowestHealthTarget()
            if lowestUnit and API.GetUnitHealthPercent(lowestUnit) <= settings.healingSettings.criticalHealthThreshold then
                API.CastSpellOnUnit(spells.FLASH_HEAL, lowestUnit)
                return true
            }
        end
    end
    
    -- Use Leap of Faith on endangered allies
    if settings.utilitySettings.useLeapOfFaith and API.CanCast(spells.LEAP_OF_FAITH) then
        local endangeredAlly = API.FindInDangerTarget()
        if endangeredAlly and API.GetUnitHealthPercent(endangeredAlly) <= settings.utilitySettings.leapOfFaithThreshold then
            API.CastSpellOnUnit(spells.LEAP_OF_FAITH, endangeredAlly)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Holy:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Use Divine Hymn
    if settings.cooldownSettings.useDivineHymn and
       averageHealth <= settings.cooldownSettings.divineHymnThreshold and
       lowHealthAlliesCount >= settings.cooldownSettings.divineHymnInjuredCount and
       API.CanCast(spells.DIVINE_HYMN) then
        API.CastSpell(spells.DIVINE_HYMN)
        return true
    }
    
    -- Use Apotheosis
    if talents.hasApotheosis and
       not apotheosisActive and
       burstModeActive and
       lowHealthAlliesCount >= settings.abilityControls.apotheosis.minInjuredAllies and
       API.CanCast(spells.APOTHEOSIS) then
        API.CastSpell(spells.APOTHEOSIS)
        return true
    }
    
    -- Use Divine Word
    if talents.hasDivineWord and
       not divineWordActive and
       lowHealthAlliesCount >= 3 and
       API.CanCast(spells.DIVINE_WORD) then
        API.CastSpell(spells.DIVINE_WORD)
        return true
    }
    
    -- Use Symbol of Hope
    if settings.abilityControls.symbolOfHope.enabled and
       API.GetPartyManaPercent() <= (100 - settings.abilityControls.symbolOfHope.minManaDeficit) and
       API.CanCast(spells.SYMBOL_OF_HOPE) then
        API.CastSpell(spells.SYMBOL_OF_HOPE)
        return true
    }
    
    return false
end

-- Handle normal healing
function Holy:HandleNormalHealing(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Use Holy Word: Sanctify for group healing
    if settings.cooldownSettings.useHolyWordSanctify and
       not holyWordSanctifyOnCooldown and
       lowHealthAlliesCount >= settings.cooldownSettings.holyWordSanctifyThreshold and
       API.CanCast(spells.HOLY_WORD_SANCTIFY) then
        API.CastSpellAtBestLocation(spells.HOLY_WORD_SANCTIFY, 12) -- 12 yard radius
        return true
    }
    
    -- Use Circle of Healing
    if talents.hasCircleOfHealing and
       settings.spellSettings.useCircleOfHealing and
       lowHealthAlliesCount >= settings.spellSettings.useCircleOfHealingThreshold and
       API.CanCast(spells.CIRCLE_OF_HEALING) then
        local bestTarget = API.FindBestAoEHealTarget(12) -- 12 yard radius
        if bestTarget then
            API.CastSpellOnUnit(spells.CIRCLE_OF_HEALING, bestTarget)
            return true
        }
    }
    
    -- Use Prayer of Healing
    if settings.spellSettings.usePrayerOfHealing != "Never" and
       lowHealthAlliesCount >= settings.spellSettings.usePrayerOfHealingThreshold and
       ((settings.spellSettings.usePrayerOfHealing == "Multiple Injured") ||
        (settings.spellSettings.usePrayerOfHealing == "With Divine Word" and divineWordActive) ||
        settings.spellSettings.usePrayerOfHealing == "Liberally") and
       API.CanCast(spells.PRAYER_OF_HEALING) then
        local bestTarget = API.FindBestHealingGroupMember()
        if bestTarget then
            API.CastSpellOnUnit(spells.PRAYER_OF_HEALING, bestTarget)
            return true
        }
    }
    
    -- Use Prayer of Mending
    if settings.spellSettings.usePrayerOfMending and
       (not prayerOfMendingActive || prayerOfMendingChargesLeft < 2) and
       API.CanCast(spells.PRAYER_OF_MENDING) then
        local bestTarget = API.FindTankToHeal() || API.FindBestHealTarget()
        if bestTarget then
            API.CastSpellOnUnit(spells.PRAYER_OF_MENDING, bestTarget)
            return true
        }
    }
    
    -- Use Renew based on settings
    if settings.spellSettings.useRenew != "Never" and API.CanCast(spells.RENEW) then
        -- Tank only
        if settings.spellSettings.useRenew == "Tank Only" then
            local tank = API.FindTankToHeal()
            if tank and not API.HasBuffOnUnit(tank, spells.RENEW) then
                API.CastSpellOnUnit(spells.RENEW, tank)
                return true
            }
        }
        -- Movement only
        else if settings.spellSettings.useRenew == "Movement Only" and API.IsPlayerMoving() then
            local target = API.FindBestHealTarget()
            if target and not API.HasBuffOnUnit(target, spells.RENEW) then
                API.CastSpellOnUnit(spells.RENEW, target)
                return true
            }
        }
        -- On cooldown
        else if settings.spellSettings.useRenew == "On Cooldown" then
            local target = API.FindBestHealTarget()
            if target and not API.HasBuffOnUnit(target, spells.RENEW) then
                API.CastSpellOnUnit(spells.RENEW, target)
                return true
            }
        }
    }
    
    -- Use Binding Heal based on settings
    if settings.spellSettings.useBindingHeal != "Never" and
       API.GetPlayerHealthPercent() < 85 and API.CanCast(spells.BINDING_HEAL) then
        
        local shouldUse = false
        
        -- Dual Healing - player and another are both injured
        if settings.spellSettings.useBindingHeal == "Dual Healing" and API.GetPlayerHealthPercent() < 80 then
            shouldUse = true
        }
        -- With Binding Heals talent
        else if settings.spellSettings.useBindingHeal == "With Binding Heals Talent" and talents.hasBindingHeals then
            shouldUse = true
        }
        -- Preferred
        else if settings.spellSettings.useBindingHeal == "Preferred" then
            shouldUse = true
        }
        
        if shouldUse then
            local target = API.FindLowestHealthTarget()
            if target then
                API.CastSpellOnUnit(spells.BINDING_HEAL, target)
                return true
            }
        }
    }
    
    -- Use Flash Heal based on settings
    if API.CanCast(spells.FLASH_HEAL) then
        local shouldUse = false
        local target = nil
        
        -- Emergency Only
        if settings.spellSettings.useFlashHeal == "Emergency Only" and criticalHealthAlliesCount > 0 then
            shouldUse = true
            target = API.FindLowestHealthTarget()
        }
        -- Low Health
        else if settings.spellSettings.useFlashHeal == "Low Health" and lowestHealth < 70 then
            shouldUse = true
            target = API.FindLowestHealthTarget()
        }
        -- With Surge of Light proc
        else if settings.spellSettings.useFlashHeal == "With Surge of Light" and surgeOfLightActive then
            shouldUse = true
            target = API.FindLowestHealthTarget()
        }
        -- Freely
        else if settings.spellSettings.useFlashHeal == "Freely" then
            shouldUse = true
            target = API.FindBestHealTarget()
        }
        
        if shouldUse and target then
            API.CastSpellOnUnit(spells.FLASH_HEAL, target)
            return true
        }
    }
    
    -- Use Heal based on settings
    if API.CanCast(spells.HEAL) then
        local shouldUse = false
        local target = nil
        
        -- Mana Conservation
        if settings.spellSettings.useHeal == "Mana Conservation" and currentMana < 50 then
            shouldUse = true
            target = API.FindBestHealTarget()
        }
        -- With Flash Concentration
        else if settings.spellSettings.useHeal == "With Flash Concentration" and flashConcentrationActive then
            shouldUse = true
            target = API.FindBestHealTarget()
        }
        -- Always
        else if settings.spellSettings.useHeal == "Always" then
            shouldUse = true
            target = API.FindBestHealTarget()
        }
        
        if shouldUse and target then
            API.CastSpellOnUnit(spells.HEAL, target)
            return true
        }
    }
    
    return false
end

-- Handle damage abilities
function Holy:HandleDamage(settings)
    -- Skip if low-health targets exist
    if lowHealthAlliesCount > 0 then
        return false
    }
    
    -- Use Holy Word: Chastise
    if settings.damageSettings.useHolyWordChastise and
       not holyWordChastiseOnCooldown and
       API.CanCast(spells.HOLY_WORD_CHASTISE) then
        API.CastSpell(spells.HOLY_WORD_CHASTISE)
        return true
    }
    
    -- Use Holy Fire
    if settings.damageSettings.useHolyFire and API.CanCast(spells.HOLY_FIRE) then
        API.CastSpell(spells.HOLY_FIRE)
        return true
    }
    
    -- Use Holy Nova for AoE
    if settings.damageSettings.useHolyNova and
       currentAoETargets >= settings.damageSettings.holyNovaThreshold and
       API.CanCast(spells.HOLY_NOVA) then
        API.CastSpell(spells.HOLY_NOVA)
        return true
    }
    
    -- Use Smite
    if settings.damageSettings.useSmite and API.CanCast(spells.SMITE) then
        API.CastSpell(spells.SMITE)
        return true
    }
    
    return false
end

-- Handle specialization change
function Holy:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    tankHealth = 100
    lowestHealth = 100
    highestHealth = 100
    averageHealth = 100
    lowHealthAlliesCount = 0
    criticalHealthAlliesCount = 0
    lightOfTheNaaruActive = false
    apotheosisActive = false
    apotheosisEndTime = 0
    boonOfTheAscendedActive = false
    boonOfTheAscendedStacks = 0
    boonOfTheAscendedEndTime = 0
    flashConcentrationActive = false
    flashConcentrationStacks = 0
    flashConcentrationEndTime = 0
    divineWordActive = false
    divineWordEndTime = 0
    surgeOfLightActive = false
    surgeOfLightStacks = 0
    selfPlayerInCombat = false
    powerWordShieldWeak = false
    powerWordShieldWeakEndTime = 0
    desperatePrayerEndTime = 0
    desperatePrayerActive = false
    currentMana = API.GetPlayerMana()
    maxMana = API.GetPlayerMaxMana()
    sanctifyGround = false
    sanctifyGroundEndTime = 0
    holyWordSanctifyOnCooldown = false
    holyWordSanctifyCooldownRemaining = 0
    holyWordChastiseOnCooldown = false
    holyWordChastiseCooldownRemaining = 0
    holyWordSerenityOnCooldown = false 
    holyWordSerenityCooldownRemaining = 0
    healingCircleActive = false
    guardianSpiritActive = false
    guardianSpiritCooldown = 0
    prayerOfMendingActive = false
    prayerOfMendingChargesLeft = 0
    symbolOfHopeActive = false
    symbolOfHopeEndTime = 0
    comfortTheWeakActive = false
    comfortTheWeakEndTime = 0
    bindingHealGroundActive = false
    bindingHealGroundEndTime = 0
    restitutionActive = false
    restitutionEndTime = 0
    sinsOfTheManyStacks = 0
    hallowedBlessingProc = false
    hallowedCloudActive = false
    divineFavorActive = false
    lightOfTheNaaruInactive = false
    resonantWordsActive = false
    resonantWordsEndTime = 0
    holyWordHarmonyActive = false
    holyWordHarmonyStacks = 0
    blessingOfThoughtActive = false
    blessingOfNaaruActive = false
    empyrealBlissActive = false
    empyrealBlissStacks = 0
    depthsOfInsanityActive = false
    
    API.PrintDebug("Holy Priest state reset on spec change")
    
    return true
end

-- Return the module for loading
return Holy