------------------------------------------
-- WindrunnerRotations - Retribution Paladin Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Retribution = {}
-- This will be assigned to addon.Classes.Paladin.Retribution when loaded

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
local currentHolyPower = 0
local maxHolyPower = 5
local divineStormBuffActive = false
local divineStormBuffEndTime = 0
local divineStormBuffStacks = 0
local divinePurposeActive = false
local divinePurposeEndTime = 0
local avengingWrathActive = false
local avengingWrathEndTime = 0
local crusadeActive = false
local crusadeEndTime = 0
local crusadeStacks = 0
local executionSentenceActive = false
local executionSentenceEndTime = 0
local finalReckoningActive = false
local finalReckoningEndTime = 0
local seraphimActive = false
local seraphimEndTime = 0
local fistOfJusticeActive = false
local divineFavorActive = false
local divineFavorEndTime = 0
local divineResonanceActive = false
local divineResonanceEndTime = 0
local divineResonanceStacks = 0
local consecrationActive = false
local consecrationEndTime = 0
local finalVerdict = false
local divineTempest = false
local executionSentence = false
local finalReckoning = false
local holyAvenger = false
local seraphim = false
local crusade = false
local divinePurpose = false
local consecrationTalent = false
local wakeOfAshes = false
local empyreanPower = false
local empyreanPowerActive = false
local empyreanPowerEndTime = 0
local bladeOfJustice = false
local hammerOfWrath = false
local templarStrike = false
local divineStorm = false
local judgment = false
local justiceProc = false
local justiceStacks = 0
local wakeOfAshesCDR = false
local holyAvengerActive = false
local holyAvengerEndTime = 0
local divineToll = false
local divineArbiter = false
local divineArbiterActive = false
local divineTollActive = false
local axiomOfTheFinalWitness = false
local virtuousCommand = false
local virtuesFury = false
local relativeVirtue = false
local blessedScars = false
local holyAttendant = false
local luminousFaith = false
local imperativeOfLightActive = false
local crusaderAura = false
local selfSufferingServant = false
local vanguard = false
local trustedDefender = false
local layOnHands = false
local wordOfGlory = false
local flashOfLight = false
local senseUndead = false
local turnEvil = false
local cleansingLight = false
local hammerOfJustice = false
local rebuke = false
local blessingOfFreedom = false
local blessingOfProtection = false
local blessingOfSacrifice = false
local divineShield = false
local temptation = false
local lastTemperingFlare = 0
local temperingFlare = false
local vindication = false
local justiceJudgment = false
local ashenHallow = false
local ashenHallowActive = false
local lastCrusaderStrike = 0
local lastJudgment = 0
local lastBladeOfJustice = 0
local lastWakeOfAshes = 0
local lastDivineStorm = 0
local lastTemplarVerdict = 0
local lastAvengingWrath = 0
local lastExecutionSentence = 0
local lastFinalReckoning = 0
local lastCrusade = 0
local lastHammerOfWrath = 0
local lastHolyAvenger = 0
local lastSeraphim = 0
local lastDivineToll = 0
local lastAshenHallow = 0
local lastWordOfGlory = 0
local lastLayOnHands = 0
local lastFlashOfLight = 0
local lastDivineShield = 0
local lastBlessingOfProtection = 0
local lastBlessingOfFreedom = 0
local lastBlessingOfSacrifice = 0
local lastHammerOfJustice = 0
local lastRebuke = 0
local lastForbearance = 0
local targetInRange = false
local playerHealth = 100
local targetHealth = 100
local activeEnemies = 0
local isInMelee = false
local meleeRange = 5 -- yards
local worthyOfLight = false
local judgmentApplied = false

-- Constants
local RETRIBUTION_SPEC_ID = 70
local AVENGING_WRATH_DURATION = 20.0 -- seconds
local CRUSADE_DURATION = 25.0 -- seconds
local EXECUTION_SENTENCE_DURATION = 8.0 -- seconds
local FINAL_RECKONING_DURATION = 12.0 -- seconds
local SERAPHIM_DURATION = 15.0 -- seconds
local HOLY_AVENGER_DURATION = 20.0 -- seconds
local CONSECRATION_DURATION = 12.0 -- seconds
local DIVINE_PURPOSE_DURATION = 10.0 -- seconds
local EMPYREAN_POWER_DURATION = 15.0 -- seconds
local DIVINE_FAVOR_DURATION = 20.0 -- seconds
local DIVINE_RESONANCE_DURATION = 30.0 -- seconds
local ASHEN_HALLOW_DURATION = 30.0 -- seconds

-- Initialize the Retribution module
function Retribution:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Retribution Paladin module initialized")
    
    return true
end

-- Register spell IDs
function Retribution:RegisterSpells()
    -- Core damage abilities
    spells.CRUSADER_STRIKE = 35395
    spells.TEMPLAR_STRIKE = 407480
    spells.JUDGMENT = 20271
    spells.BLADE_OF_JUSTICE = 184575
    spells.DIVINE_STORM = 53385
    spells.TEMPLAR_VERDICT = 85256
    spells.FINAL_VERDICT = 383328
    spells.WAKE_OF_ASHES = 255937
    spells.HAMMER_OF_WRATH = 24275
    spells.CONSECRATION = 26573
    
    -- Core defensive abilities
    spells.SHIELD_OF_VENGEANCE = 184662
    spells.DIVINE_SHIELD = 642
    spells.BLESSING_OF_PROTECTION = 1022
    spells.WORD_OF_GLORY = 85673
    spells.LAY_ON_HANDS = 633
    spells.FLASH_OF_LIGHT = 19750
    
    -- Core utility abilities
    spells.HAMMER_OF_JUSTICE = 853
    spells.REBUKE = 96231
    spells.BLESSING_OF_FREEDOM = 1044
    spells.BLESSING_OF_SACRIFICE = 6940
    spells.DEVOTION_AURA = 465
    spells.CRUSADER_AURA = 32223
    spells.SENSE_UNDEAD = 5502
    spells.TURN_EVIL = 10326
    spells.CLEANSE_TOXINS = 213644
    
    -- Cooldowns
    spells.AVENGING_WRATH = 31884
    spells.CRUSADE = 231895
    spells.EXECUTION_SENTENCE = 343527
    spells.FINAL_RECKONING = 343721
    spells.HOLY_AVENGER = 105809
    spells.SERAPHIM = 152262
    spells.DIVINE_TOLL = 375576
    
    -- Talents and passives
    spells.DIVINE_PURPOSE = 223817
    spells.DIVINE_TEMPEST = 326732
    spells.EMPYREAN_POWER = 326732
    spells.CRUSADING_STRIKES = 383321
    spells.DIVINE_ARBITER = 384442
    spells.TEMPERING_FLARE = 367875
    spells.AXIOM_OF_THE_FINAL_WITNESS = 395641
    spells.VIRTUOUS_COMMAND = 391954
    spells.VIRTUES_FURY = 393898
    spells.VANGUARD = 383300
    spells.RELATIVE_VIRTUE = 386738
    spells.BLESSED_SCARS = 383312
    spells.HOLY_ATTENDANT = 384795
    spells.LUMINOUS_FAITH = 388081
    spells.IMPERATIVE_OF_LIGHT = 387170
    spells.FIST_OF_JUSTICE = 234299
    spells.SELF_SUFFERING_SERVANT = 378412
    spells.TRUSTED_DEFENDER = 383279
    spells.DIVINE_FAVOR = 210294
    spells.DIVINE_RESONANCE = 386738
    spells.TEMPTATION = 384376
    spells.VINDICATION = 207028
    spells.JUSTICE_JUDGMENT = 386834
    spells.ASHEN_HALLOW = 316958
    spells.WORTHY_OF_LIGHT = 396085
    
    -- War Within Season 2 specific
    spells.TEMPERING_FLARE_TALENT = 367875
    
    -- Buff IDs
    spells.DIVINE_STORM_BUFF = 326733
    spells.DIVINE_PURPOSE_BUFF = 223819
    spells.AVENGING_WRATH_BUFF = 31884
    spells.CRUSADE_BUFF = 231895
    spells.HOLY_AVENGER_BUFF = 105809
    spells.SERAPHIM_BUFF = 152262
    spells.EMPYREAN_POWER_BUFF = 326733
    spells.DIVINE_ARBITER_BUFF = 384442
    spells.DIVINE_FAVOR_BUFF = 210294
    spells.DIVINE_RESONANCE_BUFF = 386738
    spells.CONSECRATION_BUFF = 188370
    spells.WORTHY_OF_LIGHT_BUFF = 396085
    spells.ASHEN_HALLOW_BUFF = 316958
    
    -- Debuff IDs
    spells.JUDGMENT_DEBUFF = 197277
    spells.EXECUTION_SENTENCE_DEBUFF = 343527
    spells.FINAL_RECKONING_DEBUFF = 343721
    spells.FORBEARANCE_DEBUFF = 25771
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.DIVINE_STORM = spells.DIVINE_STORM_BUFF
    buffs.DIVINE_PURPOSE = spells.DIVINE_PURPOSE_BUFF
    buffs.AVENGING_WRATH = spells.AVENGING_WRATH_BUFF
    buffs.CRUSADE = spells.CRUSADE_BUFF
    buffs.HOLY_AVENGER = spells.HOLY_AVENGER_BUFF
    buffs.SERAPHIM = spells.SERAPHIM_BUFF
    buffs.EMPYREAN_POWER = spells.EMPYREAN_POWER_BUFF
    buffs.DIVINE_ARBITER = spells.DIVINE_ARBITER_BUFF
    buffs.DIVINE_FAVOR = spells.DIVINE_FAVOR_BUFF
    buffs.DIVINE_RESONANCE = spells.DIVINE_RESONANCE_BUFF
    buffs.CONSECRATION = spells.CONSECRATION_BUFF
    buffs.WORTHY_OF_LIGHT = spells.WORTHY_OF_LIGHT_BUFF
    buffs.ASHEN_HALLOW = spells.ASHEN_HALLOW_BUFF
    
    debuffs.JUDGMENT = spells.JUDGMENT_DEBUFF
    debuffs.EXECUTION_SENTENCE = spells.EXECUTION_SENTENCE_DEBUFF
    debuffs.FINAL_RECKONING = spells.FINAL_RECKONING_DEBUFF
    debuffs.FORBEARANCE = spells.FORBEARANCE_DEBUFF
    
    return true
end

-- Register variables to track
function Retribution:RegisterVariables()
    -- Talent tracking
    talents.hasFinalVerdict = false
    talents.hasDivineTempest = false
    talents.hasExecutionSentence = false
    talents.hasFinalReckoning = false
    talents.hasHolyAvenger = false
    talents.hasSeraphim = false
    talents.hasCrusade = false
    talents.hasDivinePurpose = false
    talents.hasConsecration = false
    talents.hasWakeOfAshes = false
    talents.hasEmpyreanPower = false
    talents.hasCrusadingStrikes = false
    talents.hasDivineArbiter = false
    talents.hasTemperingFlare = false
    talents.hasAxiomOfTheFinalWitness = false
    talents.hasVirtuousCommand = false
    talents.hasVirtuesFury = false
    talents.hasVanguard = false
    talents.hasRelativeVirtue = false
    talents.hasBlessedScars = false
    talents.hasHolyAttendant = false
    talents.hasLuminousFaith = false
    talents.hasImperativeOfLight = false
    talents.hasFistOfJustice = false
    talents.hasSelfSufferingServant = false
    talents.hasTrustedDefender = false
    talents.hasDivineFavor = false
    talents.hasDivineResonance = false
    talents.hasTemptation = false
    talents.hasVindication = false
    talents.hasJusticeJudgment = false
    talents.hasAshenHallow = false
    talents.hasWorthyOfLight = false
    talents.hasDivineToll = false
    
    -- Initialize holy power
    currentHolyPower = API.GetPlayerPower() or 0
    maxHolyPower = 5 -- Default, could be higher if talented
    
    -- Track if in melee range
    isInMelee = false
    
    return true
end

-- Register spec-specific settings
function Retribution:RegisterSettings()
    ConfigRegistry:RegisterSettings("RetributionPaladin", {
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
                default = 3
            },
            holyPowerPooling = {
                displayName = "Holy Power Pooling",
                description = "Pool Holy Power for optimal damage",
                type = "toggle",
                default = true
            },
            holyPowerPoolingThreshold = {
                displayName = "Holy Power Pooling Threshold",
                description = "Minimum Holy Power to maintain",
                type = "slider",
                min = 1,
                max = 4,
                default = 3
            },
            maintainConsecration = {
                displayName = "Maintain Consecration",
                description = "Always keep Consecration active",
                type = "toggle",
                default = false
            },
            manaThreshold = {
                displayName = "Mana Threshold",
                description = "Minimum mana percentage for casting Flash of Light",
                type = "slider",
                min = 10,
                max = 50,
                default = 20
            },
            judgmentPriorityTarget = {
                displayName = "Judgment Priority Target",
                description = "Which targets to prioritize with Judgment debuff",
                type = "dropdown",
                options = {"Main Target", "High Value Targets", "Low Health Target"},
                default = "Main Target"
            },
            hammerOfWrathMode = {
                displayName = "Hammer of Wrath Usage",
                description = "How to use Hammer of Wrath",
                type = "dropdown",
                options = {"Sub 20% HP Only", "During Cooldowns", "Always When Available"},
                default = "Always When Available"
            },
            wordOfGloryThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory on self",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            }
        },
        
        finisherSettings = {
            useTemplarVerdict = {
                displayName = "Use Templar Verdict",
                description = "Use Templar Verdict as a single target finisher",
                type = "toggle",
                default = true
            },
            useDivineStorm = {
                displayName = "Use Divine Storm",
                description = "Use Divine Storm as an AoE finisher",
                type = "toggle",
                default = true
            },
            divineStormThreshold = {
                displayName = "Divine Storm Target Threshold",
                description = "Minimum number of targets to use Divine Storm",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            divineStormWithEmpyreanPower = {
                displayName = "Divine Storm with Empyrean Power",
                description = "Use Divine Storm when Empyrean Power is active",
                type = "toggle",
                default = true
            },
            prioritizeDivineStormWithDivineTempest = {
                displayName = "Prioritize Divine Storm with Divine Tempest",
                description = "Prioritize Divine Storm over Templar Verdict when Divine Tempest is talented",
                type = "toggle",
                default = true
            },
            useWordOfGlory = {
                displayName = "Use Word of Glory",
                description = "Use Word of Glory as a healing finisher",
                type = "toggle",
                default = true
            },
            minHolyPowerForFinisher = {
                displayName = "Minimum Holy Power for Finisher",
                description = "Minimum Holy Power to use for damage finishers",
                type = "slider",
                min = 3,
                max = 5,
                default = 3
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
                options = {"On Cooldown", "With Other Cooldowns", "Boss Only", "Burst Only"},
                default = "With Other Cooldowns"
            },
            useCrusade = {
                displayName = "Use Crusade",
                description = "Automatically use Crusade when talented",
                type = "toggle",
                default = true
            },
            crusadeMode = {
                displayName = "Crusade Usage",
                description = "When to use Crusade",
                type = "dropdown",
                options = {"On Cooldown", "Boss Only", "Burst Only"},
                default = "Boss Only"
            },
            useExecutionSentence = {
                displayName = "Use Execution Sentence",
                description = "Automatically use Execution Sentence when talented",
                type = "toggle",
                default = true
            },
            executionSentenceMode = {
                displayName = "Execution Sentence Usage",
                description = "When to use Execution Sentence",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Single Target Only"},
                default = "With Cooldowns"
            },
            useFinalReckoning = {
                displayName = "Use Final Reckoning",
                description = "Automatically use Final Reckoning when talented",
                type = "toggle",
                default = true
            },
            finalReckoningMode = {
                displayName = "Final Reckoning Usage",
                description = "When to use Final Reckoning",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "With Templar Verdict"},
                default = "With Cooldowns"
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
                options = {"On Cooldown", "With Avenging Wrath", "With Crusade"},
                default = "With Avenging Wrath"
            },
            useSeraphim = {
                displayName = "Use Seraphim",
                description = "Automatically use Seraphim when talented",
                type = "toggle",
                default = true
            },
            seraphimMode = {
                displayName = "Seraphim Usage",
                description = "When to use Seraphim",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Pool Holy Power"},
                default = "With Cooldowns"
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
                options = {"On Cooldown", "Multiple Enemies", "For Holy Power", "Burst Only"},
                default = "For Holy Power"
            },
            divineTollThreshold = {
                displayName = "Divine Toll Holy Power Threshold",
                description = "Holy Power threshold to use Divine Toll",
                type = "slider",
                min = 0,
                max = 4,
                default = 1
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
                options = {"On Cooldown", "With Cooldowns", "AoE Only", "Burst Only"},
                default = "With Cooldowns"
            }
        },
        
        defensiveSettings = {
            useShieldOfVengeance = {
                displayName = "Use Shield of Vengeance",
                description = "Automatically use Shield of Vengeance",
                type = "toggle",
                default = true
            },
            shieldOfVengeanceMode = {
                displayName = "Shield of Vengeance Usage",
                description = "When to use Shield of Vengeance",
                type = "dropdown",
                options = {"On Cooldown", "When Taking Damage", "Boss Only"},
                default = "On Cooldown"
            },
            useLayOnHands = {
                displayName = "Use Lay on Hands",
                description = "Automatically use Lay on Hands",
                type = "toggle",
                default = true
            },
            layOnHandsThreshold = {
                displayName = "Lay on Hands Health Threshold",
                description = "Health percentage to use Lay on Hands on self",
                type = "slider",
                min = 5,
                max = 25,
                default = 15
            },
            useDivineShield = {
                displayName = "Use Divine Shield",
                description = "Automatically use Divine Shield in emergencies",
                type = "toggle",
                default = true
            },
            divineShieldThreshold = {
                displayName = "Divine Shield Health Threshold",
                description = "Health percentage to use Divine Shield",
                type = "slider",
                min = 5,
                max = 20,
                default = 10
            },
            useBlessingOfProtection = {
                displayName = "Use Blessing of Protection",
                description = "Automatically use Blessing of Protection",
                type = "toggle",
                default = true
            },
            blessingOfProtectionThreshold = {
                displayName = "Blessing of Protection Health Threshold",
                description = "Health percentage to use Blessing of Protection on ally",
                type = "slider",
                min = 5,
                max = 25,
                default = 15
            }
        },
        
        utilitySettings = {
            useFlashOfLight = {
                displayName = "Use Flash of Light",
                description = "Use Flash of Light for emergency healing",
                type = "toggle",
                default = true
            },
            flashOfLightThreshold = {
                displayName = "Flash of Light Health Threshold",
                description = "Health percentage to use Flash of Light",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            },
            useRebuke = {
                displayName = "Use Rebuke",
                description = "Automatically interrupt spellcasting",
                type = "toggle",
                default = true
            },
            useBlessingOfFreedom = {
                displayName = "Use Blessing of Freedom",
                description = "Automatically use Blessing of Freedom",
                type = "toggle",
                default = true
            },
            useCleanseToxins = {
                displayName = "Use Cleanse Toxins",
                description = "Automatically cleanse poisons and diseases",
                type = "toggle",
                default = true
            },
            useHammerOfJustice = {
                displayName = "Use Hammer of Justice",
                description = "Use Hammer of Justice for utility",
                type = "toggle",
                default = true
            },
            hammerOfJusticeMode = {
                displayName = "Hammer of Justice Usage",
                description = "When to use Hammer of Justice",
                type = "dropdown",
                options = {"Interrupt Only", "On Cooldown", "Manual Only"},
                default = "Interrupt Only"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Templar Verdict controls
            templarVerdict = AAC.RegisterAbility(spells.TEMPLAR_VERDICT, {
                enabled = true,
                useDuringBurstOnly = false,
                requireJudgment = true,
                prioritizeFinalReckoning = true
            }),
            
            -- Divine Storm controls
            divineStorm = AAC.RegisterAbility(spells.DIVINE_STORM, {
                enabled = true,
                useDuringBurstOnly = false,
                minEnemies = 3,
                requireEmpyreanPower = false
            }),
            
            -- Wake of Ashes controls
            wakeOfAshes = AAC.RegisterAbility(spells.WAKE_OF_ASHES, {
                enabled = true,
                useDuringBurstOnly = false,
                requireLowHolyPower = true,
                minEnemies = 1
            })
        }
    })
    
    return true
end

-- Register for events 
function Retribution:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
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
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    return true
end

-- Update talent information
function Retribution:UpdateTalentInfo()
    -- Check for important talents
    talents.hasFinalVerdict = API.HasTalent(spells.FINAL_VERDICT)
    talents.hasDivineTempest = API.HasTalent(spells.DIVINE_TEMPEST)
    talents.hasExecutionSentence = API.HasTalent(spells.EXECUTION_SENTENCE)
    talents.hasFinalReckoning = API.HasTalent(spells.FINAL_RECKONING)
    talents.hasHolyAvenger = API.HasTalent(spells.HOLY_AVENGER)
    talents.hasSeraphim = API.HasTalent(spells.SERAPHIM)
    talents.hasCrusade = API.HasTalent(spells.CRUSADE)
    talents.hasDivinePurpose = API.HasTalent(spells.DIVINE_PURPOSE)
    talents.hasConsecration = API.HasTalent(spells.CONSECRATION)
    talents.hasWakeOfAshes = API.HasTalent(spells.WAKE_OF_ASHES)
    talents.hasEmpyreanPower = API.HasTalent(spells.EMPYREAN_POWER)
    talents.hasCrusadingStrikes = API.HasTalent(spells.CRUSADING_STRIKES)
    talents.hasDivineArbiter = API.HasTalent(spells.DIVINE_ARBITER)
    talents.hasTemperingFlare = API.HasTalent(spells.TEMPERING_FLARE_TALENT)
    talents.hasAxiomOfTheFinalWitness = API.HasTalent(spells.AXIOM_OF_THE_FINAL_WITNESS)
    talents.hasVirtuousCommand = API.HasTalent(spells.VIRTUOUS_COMMAND)
    talents.hasVirtuesFury = API.HasTalent(spells.VIRTUES_FURY)
    talents.hasVanguard = API.HasTalent(spells.VANGUARD)
    talents.hasRelativeVirtue = API.HasTalent(spells.RELATIVE_VIRTUE)
    talents.hasBlessedScars = API.HasTalent(spells.BLESSED_SCARS)
    talents.hasHolyAttendant = API.HasTalent(spells.HOLY_ATTENDANT)
    talents.hasLuminousFaith = API.HasTalent(spells.LUMINOUS_FAITH)
    talents.hasImperativeOfLight = API.HasTalent(spells.IMPERATIVE_OF_LIGHT)
    talents.hasFistOfJustice = API.HasTalent(spells.FIST_OF_JUSTICE)
    talents.hasSelfSufferingServant = API.HasTalent(spells.SELF_SUFFERING_SERVANT)
    talents.hasTrustedDefender = API.HasTalent(spells.TRUSTED_DEFENDER)
    talents.hasDivineFavor = API.HasTalent(spells.DIVINE_FAVOR)
    talents.hasDivineResonance = API.HasTalent(spells.DIVINE_RESONANCE)
    talents.hasTemptation = API.HasTalent(spells.TEMPTATION)
    talents.hasVindication = API.HasTalent(spells.VINDICATION)
    talents.hasJusticeJudgment = API.HasTalent(spells.JUSTICE_JUDGMENT)
    talents.hasAshenHallow = API.HasTalent(spells.ASHEN_HALLOW)
    talents.hasWorthyOfLight = API.HasTalent(spells.WORTHY_OF_LIGHT)
    talents.hasDivineToll = API.HasTalent(spells.DIVINE_TOLL)
    
    -- Set specialized variables based on talents
    if talents.hasFinalVerdict then
        finalVerdict = true
    end
    
    if talents.hasDivineTempest then
        divineTempest = true
    end
    
    if talents.hasExecutionSentence then
        executionSentence = true
    end
    
    if talents.hasFinalReckoning then
        finalReckoning = true
    end
    
    if talents.hasHolyAvenger then
        holyAvenger = true
    end
    
    if talents.hasSeraphim then
        seraphim = true
    end
    
    if talents.hasCrusade then
        crusade = true
    end
    
    if talents.hasDivinePurpose then
        divinePurpose = true
        divinePurposeActive = API.UnitHasBuff("player", buffs.DIVINE_PURPOSE)
    end
    
    if talents.hasConsecration then
        consecrationTalent = true
    end
    
    if talents.hasWakeOfAshes then
        wakeOfAshes = true
    end
    
    if talents.hasEmpyreanPower then
        empyreanPower = true
        empyreanPowerActive = API.UnitHasBuff("player", buffs.EMPYREAN_POWER)
    end
    
    if talents.hasDivineArbiter then
        divineArbiter = true
    end
    
    if talents.hasTemperingFlare then
        temperingFlare = true
    end
    
    if talents.hasAxiomOfTheFinalWitness then
        axiomOfTheFinalWitness = true
    end
    
    if talents.hasVirtuousCommand then
        virtuousCommand = true
    end
    
    if talents.hasVirtuesFury then
        virtuesFury = true
    end
    
    if talents.hasVanguard then
        vanguard = true
    end
    
    if talents.hasRelativeVirtue then
        relativeVirtue = true
    end
    
    if talents.hasBlessedScars then
        blessedScars = true
    end
    
    if talents.hasHolyAttendant then
        holyAttendant = true
    end
    
    if talents.hasLuminousFaith then
        luminousFaith = true
    end
    
    if talents.hasImperativeOfLight then
        imperativeOfLightActive = true
    end
    
    if talents.hasFistOfJustice then
        fistOfJustice = true
    end
    
    if talents.hasSelfSufferingServant then
        selfSufferingServant = true
    end
    
    if talents.hasTrustedDefender then
        trustedDefender = true
    end
    
    if talents.hasDivineFavor then
        divineFavor = true
    end
    
    if talents.hasDivineResonance then
        divineResonance = true
    end
    
    if talents.hasTemptation then
        temptation = true
    end
    
    if talents.hasVindication then
        vindication = true
    end
    
    if talents.hasJusticeJudgment then
        justiceJudgment = true
    end
    
    if talents.hasAshenHallow then
        ashenHallow = true
    end
    
    if talents.hasWorthyOfLight then
        worthyOfLight = true
    end
    
    if talents.hasDivineToll then
        divineToll = true
    end
    
    if API.IsSpellKnown(spells.BLADE_OF_JUSTICE) then
        bladeOfJustice = true
    end
    
    if API.IsSpellKnown(spells.HAMMER_OF_WRATH) then
        hammerOfWrath = true
    end
    
    if API.IsSpellKnown(spells.TEMPLAR_STRIKE) then
        templarStrike = true
    elseif API.IsSpellKnown(spells.CRUSADER_STRIKE) then
        crusaderStrike = true
    end
    
    if API.IsSpellKnown(spells.DIVINE_STORM) then
        divineStorm = true
    end
    
    if API.IsSpellKnown(spells.JUDGMENT) then
        judgment = true
    end
    
    if API.IsSpellKnown(spells.LAY_ON_HANDS) then
        layOnHands = true
    end
    
    if API.IsSpellKnown(spells.WORD_OF_GLORY) then
        wordOfGlory = true
    end
    
    if API.IsSpellKnown(spells.FLASH_OF_LIGHT) then
        flashOfLight = true
    end
    
    if API.IsSpellKnown(spells.SENSE_UNDEAD) then
        senseUndead = true
    end
    
    if API.IsSpellKnown(spells.TURN_EVIL) then
        turnEvil = true
    end
    
    if API.IsSpellKnown(spells.CLEANSE_TOXINS) then
        cleansingLight = true
    end
    
    if API.IsSpellKnown(spells.HAMMER_OF_JUSTICE) then
        hammerOfJustice = true
    end
    
    if API.IsSpellKnown(spells.REBUKE) then
        rebuke = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_FREEDOM) then
        blessingOfFreedom = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_PROTECTION) then
        blessingOfProtection = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_SACRIFICE) then
        blessingOfSacrifice = true
    end
    
    if API.IsSpellKnown(spells.DIVINE_SHIELD) then
        divineShield = true
    end
    
    if API.IsSpellKnown(spells.CRUSADER_AURA) then
        crusaderAura = true
    end
    
    API.PrintDebug("Retribution Paladin talents updated")
    
    return true
end

-- Update Holy Power tracking
function Retribution:UpdateHolyPower()
    currentHolyPower = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Retribution:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Retribution:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update active enemy counts
function Retribution:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Check if unit is in melee range
function Retribution:IsInMeleeRange(unit)
    if not unit or not API.UnitExists(unit) then
        return false
    end
    
    return API.GetUnitDistance("player", unit) <= meleeRange
end

-- Handle combat log events
function Retribution:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Divine Storm buff application
            if spellID == buffs.DIVINE_STORM then
                divineStormBuffActive = true
                divineStormBuffEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_STORM))
                divineStormBuffStacks = select(4, API.GetBuffInfo("player", buffs.DIVINE_STORM)) or 1
                API.PrintDebug("Divine Storm buff activated: " .. tostring(divineStormBuffStacks) .. " stack(s)")
            end
            
            -- Divine Purpose application
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeActive = true
                divinePurposeEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_PURPOSE))
                API.PrintDebug("Divine Purpose activated")
            end
            
            -- Avenging Wrath application
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = true
                avengingWrathEndTime = select(6, API.GetBuffInfo("player", buffs.AVENGING_WRATH))
                API.PrintDebug("Avenging Wrath activated")
            end
            
            -- Crusade application
            if spellID == buffs.CRUSADE then
                crusadeActive = true
                crusadeEndTime = select(6, API.GetBuffInfo("player", buffs.CRUSADE))
                crusadeStacks = select(4, API.GetBuffInfo("player", buffs.CRUSADE)) or 1
                API.PrintDebug("Crusade activated: " .. tostring(crusadeStacks) .. " stack(s)")
            end
            
            -- Holy Avenger application
            if spellID == buffs.HOLY_AVENGER then
                holyAvengerActive = true
                holyAvengerEndTime = select(6, API.GetBuffInfo("player", buffs.HOLY_AVENGER))
                API.PrintDebug("Holy Avenger activated")
            end
            
            -- Seraphim application
            if spellID == buffs.SERAPHIM then
                seraphimActive = true
                seraphimEndTime = select(6, API.GetBuffInfo("player", buffs.SERAPHIM))
                API.PrintDebug("Seraphim activated")
            end
            
            -- Empyrean Power application
            if spellID == buffs.EMPYREAN_POWER then
                empyreanPowerActive = true
                empyreanPowerEndTime = select(6, API.GetBuffInfo("player", buffs.EMPYREAN_POWER))
                API.PrintDebug("Empyrean Power activated")
            end
            
            -- Divine Arbiter application
            if spellID == buffs.DIVINE_ARBITER then
                divineArbiterActive = true
                API.PrintDebug("Divine Arbiter activated")
            end
            
            -- Divine Favor application
            if spellID == buffs.DIVINE_FAVOR then
                divineFavorActive = true
                divineFavorEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_FAVOR))
                API.PrintDebug("Divine Favor activated")
            end
            
            -- Divine Resonance application
            if spellID == buffs.DIVINE_RESONANCE then
                divineResonanceActive = true
                divineResonanceEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_RESONANCE))
                divineResonanceStacks = select(4, API.GetBuffInfo("player", buffs.DIVINE_RESONANCE)) or 1
                API.PrintDebug("Divine Resonance activated: " .. tostring(divineResonanceStacks) .. " stack(s)")
            end
            
            -- Consecration application
            if spellID == buffs.CONSECRATION then
                consecrationActive = true
                consecrationEndTime = select(6, API.GetBuffInfo("player", buffs.CONSECRATION))
                API.PrintDebug("Consecration activated")
            end
            
            -- Worthy of Light application
            if spellID == buffs.WORTHY_OF_LIGHT then
                worthyOfLight = true
                API.PrintDebug("Worthy of Light activated")
            end
            
            -- Ashen Hallow application
            if spellID == buffs.ASHEN_HALLOW then
                ashenHallowActive = true
                API.PrintDebug("Ashen Hallow activated")
            end
            
            -- Forbearance application
            if spellID == debuffs.FORBEARANCE then
                lastForbearance = GetTime()
                API.PrintDebug("Forbearance applied to player")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Divine Storm buff removal
            if spellID == buffs.DIVINE_STORM then
                divineStormBuffActive = false
                divineStormBuffStacks = 0
                API.PrintDebug("Divine Storm buff faded")
            end
            
            -- Divine Purpose removal
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeActive = false
                API.PrintDebug("Divine Purpose faded")
            end
            
            -- Avenging Wrath removal
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = false
                API.PrintDebug("Avenging Wrath faded")
            end
            
            -- Crusade removal
            if spellID == buffs.CRUSADE then
                crusadeActive = false
                crusadeStacks = 0
                API.PrintDebug("Crusade faded")
            end
            
            -- Holy Avenger removal
            if spellID == buffs.HOLY_AVENGER then
                holyAvengerActive = false
                API.PrintDebug("Holy Avenger faded")
            end
            
            -- Seraphim removal
            if spellID == buffs.SERAPHIM then
                seraphimActive = false
                API.PrintDebug("Seraphim faded")
            end
            
            -- Empyrean Power removal
            if spellID == buffs.EMPYREAN_POWER then
                empyreanPowerActive = false
                API.PrintDebug("Empyrean Power faded")
            end
            
            -- Divine Arbiter removal
            if spellID == buffs.DIVINE_ARBITER then
                divineArbiterActive = false
                API.PrintDebug("Divine Arbiter faded")
            end
            
            -- Divine Favor removal
            if spellID == buffs.DIVINE_FAVOR then
                divineFavorActive = false
                API.PrintDebug("Divine Favor faded")
            end
            
            -- Divine Resonance removal
            if spellID == buffs.DIVINE_RESONANCE then
                divineResonanceActive = false
                divineResonanceStacks = 0
                API.PrintDebug("Divine Resonance faded")
            end
            
            -- Consecration removal
            if spellID == buffs.CONSECRATION then
                consecrationActive = false
                API.PrintDebug("Consecration faded")
            end
            
            -- Worthy of Light removal
            if spellID == buffs.WORTHY_OF_LIGHT then
                worthyOfLight = false
                API.PrintDebug("Worthy of Light faded")
            end
            
            -- Ashen Hallow removal
            if spellID == buffs.ASHEN_HALLOW then
                ashenHallowActive = false
                API.PrintDebug("Ashen Hallow faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            if spellID == spells.CRUSADER_STRIKE or spellID == spells.TEMPLAR_STRIKE then
                lastCrusaderStrike = GetTime()
                API.PrintDebug("Crusader Strike cast")
            elseif spellID == spells.JUDGMENT then
                lastJudgment = GetTime()
                API.PrintDebug("Judgment cast")
            elseif spellID == spells.BLADE_OF_JUSTICE then
                lastBladeOfJustice = GetTime()
                API.PrintDebug("Blade of Justice cast")
            elseif spellID == spells.WAKE_OF_ASHES then
                lastWakeOfAshes = GetTime()
                API.PrintDebug("Wake of Ashes cast")
            elseif spellID == spells.DIVINE_STORM then
                lastDivineStorm = GetTime()
                API.PrintDebug("Divine Storm cast")
            elseif spellID == spells.TEMPLAR_VERDICT or spellID == spells.FINAL_VERDICT then
                lastTemplarVerdict = GetTime()
                API.PrintDebug("Templar Verdict cast")
            elseif spellID == spells.AVENGING_WRATH then
                lastAvengingWrath = GetTime()
                avengingWrathActive = true
                avengingWrathEndTime = GetTime() + AVENGING_WRATH_DURATION
                API.PrintDebug("Avenging Wrath cast")
            elseif spellID == spells.EXECUTION_SENTENCE then
                lastExecutionSentence = GetTime()
                executionSentenceActive = true
                executionSentenceEndTime = GetTime() + EXECUTION_SENTENCE_DURATION
                API.PrintDebug("Execution Sentence cast")
            elseif spellID == spells.FINAL_RECKONING then
                lastFinalReckoning = GetTime()
                finalReckoningActive = true
                finalReckoningEndTime = GetTime() + FINAL_RECKONING_DURATION
                API.PrintDebug("Final Reckoning cast")
            elseif spellID == spells.CRUSADE then
                lastCrusade = GetTime()
                crusadeActive = true
                crusadeEndTime = GetTime() + CRUSADE_DURATION
                crusadeStacks = 1
                API.PrintDebug("Crusade cast")
            elseif spellID == spells.HAMMER_OF_WRATH then
                lastHammerOfWrath = GetTime()
                API.PrintDebug("Hammer of Wrath cast")
            elseif spellID == spells.HOLY_AVENGER then
                lastHolyAvenger = GetTime()
                holyAvengerActive = true
                holyAvengerEndTime = GetTime() + HOLY_AVENGER_DURATION
                API.PrintDebug("Holy Avenger cast")
            elseif spellID == spells.SERAPHIM then
                lastSeraphim = GetTime()
                seraphimActive = true
                seraphimEndTime = GetTime() + SERAPHIM_DURATION
                API.PrintDebug("Seraphim cast")
            elseif spellID == spells.DIVINE_TOLL then
                lastDivineToll = GetTime()
                divineTollActive = true
                API.PrintDebug("Divine Toll cast")
            elseif spellID == spells.ASHEN_HALLOW then
                lastAshenHallow = GetTime()
                ashenHallowActive = true
                API.PrintDebug("Ashen Hallow cast")
            elseif spellID == spells.WORD_OF_GLORY then
                lastWordOfGlory = GetTime()
                API.PrintDebug("Word of Glory cast")
            elseif spellID == spells.LAY_ON_HANDS then
                lastLayOnHands = GetTime()
                API.PrintDebug("Lay on Hands cast")
            elseif spellID == spells.FLASH_OF_LIGHT then
                lastFlashOfLight = GetTime()
                API.PrintDebug("Flash of Light cast")
            elseif spellID == spells.DIVINE_SHIELD then
                lastDivineShield = GetTime()
                API.PrintDebug("Divine Shield cast")
            elseif spellID == spells.BLESSING_OF_PROTECTION then
                lastBlessingOfProtection = GetTime()
                API.PrintDebug("Blessing of Protection cast")
            elseif spellID == spells.BLESSING_OF_FREEDOM then
                lastBlessingOfFreedom = GetTime()
                API.PrintDebug("Blessing of Freedom cast")
            elseif spellID == spells.BLESSING_OF_SACRIFICE then
                lastBlessingOfSacrifice = GetTime()
                API.PrintDebug("Blessing of Sacrifice cast")
            elseif spellID == spells.HAMMER_OF_JUSTICE then
                lastHammerOfJustice = GetTime()
                API.PrintDebug("Hammer of Justice cast")
            elseif spellID == spells.REBUKE then
                lastRebuke = GetTime()
                API.PrintDebug("Rebuke cast")
            elseif temperingFlare and spellID == spells.TEMPERING_FLARE_TALENT then
                lastTemperingFlare = GetTime()
                API.PrintDebug("Tempering Flare cast")
            end
        end
        
        -- Track judgment debuff application
        if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") and spellID == debuffs.JUDGMENT and destGUID then
            judgmentApplied = true
            API.PrintDebug("Judgment debuff applied to " .. destName)
        end
        
        -- Track judgment debuff removal
        if eventType == "SPELL_AURA_REMOVED" and spellID == debuffs.JUDGMENT and destGUID then
            judgmentApplied = false
            API.PrintDebug("Judgment debuff removed from " .. destName)
        end
        
        -- Track Execution Sentence debuff application
        if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") and spellID == debuffs.EXECUTION_SENTENCE and destGUID then
            executionSentenceActive = true
            executionSentenceEndTime = GetTime() + EXECUTION_SENTENCE_DURATION
            API.PrintDebug("Execution Sentence debuff applied to " .. destName)
        end
        
        -- Track Execution Sentence debuff removal
        if eventType == "SPELL_AURA_REMOVED" and spellID == debuffs.EXECUTION_SENTENCE and destGUID then
            executionSentenceActive = false
            API.PrintDebug("Execution Sentence debuff removed from " .. destName)
        end
        
        -- Track Final Reckoning debuff application
        if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") and spellID == debuffs.FINAL_RECKONING and destGUID then
            finalReckoningActive = true
            finalReckoningEndTime = GetTime() + FINAL_RECKONING_DURATION
            API.PrintDebug("Final Reckoning debuff applied to " .. destName)
        end
        
        -- Track Final Reckoning debuff removal
        if eventType == "SPELL_AURA_REMOVED" and spellID == debuffs.FINAL_RECKONING and destGUID then
            finalReckoningActive = false
            API.PrintDebug("Final Reckoning debuff removed from " .. destName)
        end
    end
    
    return true
end

-- Main rotation function
function Retribution:RunRotation()
    -- Check if we should be running Retribution Paladin logic
    if API.GetActiveSpecID() ~= RETRIBUTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("RetributionPaladin")
    
    -- Update variables
    self:UpdateHolyPower()
    self:UpdateEnemyCounts()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Check if in melee range
    targetInRange = API.IsUnitInRange("target", meleeRange)
    isInMelee = targetInRange
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle out of combat setup
    if not API.IsInCombat() then
        -- Check for aura and apply if needed
        if crusaderAura and not API.UnitHasBuff("player", spells.CRUSADER_AURA) and API.CanCast(spells.CRUSADER_AURA) then
            API.CastSpell(spells.CRUSADER_AURA)
            return true
        elseif not API.UnitHasBuff("player", spells.DEVOTION_AURA) and API.CanCast(spells.DEVOTION_AURA) then
            API.CastSpell(spells.DEVOTION_AURA)
            return true
        end
        
        -- No other actions needed out of combat
        return false
    end
    
    -- Handle emergency situations
    if self:HandleEmergencies(settings) then
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle offensive cooldowns
    if self:HandleOffensiveCooldowns(settings) then
        return true
    end
    
    -- Handle main rotation
    if activeEnemies >= settings.rotationSettings.aoeThreshold and settings.rotationSettings.aoeEnabled then
        return self:HandleAoE(settings)
    else
        return self:HandleSingleTarget(settings)
    end
end

-- Handle emergency situations
function Retribution:HandleEmergencies(settings)
    -- Lay on Hands for self
    if layOnHands and 
       settings.defensiveSettings.useLayOnHands and
       playerHealth <= settings.defensiveSettings.layOnHandsThreshold and
       API.CanCast(spells.LAY_ON_HANDS) and
       not API.UnitHasDebuff("player", debuffs.FORBEARANCE) then
        API.CastSpellOnUnit(spells.LAY_ON_HANDS, "player")
        return true
    end
    
    -- Divine Shield for emergency if we're about to die
    if divineShield and
       settings.defensiveSettings.useDivineShield and
       playerHealth <= settings.defensiveSettings.divineShieldThreshold and
       API.CanCast(spells.DIVINE_SHIELD) and
       not API.UnitHasDebuff("player", debuffs.FORBEARANCE) then
        API.CastSpell(spells.DIVINE_SHIELD)
        return true
    end
    
    -- Emergency Word of Glory with Divine Purpose proc
    if wordOfGlory and
       divinePurposeActive and
       playerHealth <= 35 and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    -- Word of Glory for healing
    if wordOfGlory and
       settings.finisherSettings.useWordOfGlory and
       playerHealth <= settings.rotationSettings.wordOfGloryThreshold and
       (currentHolyPower >= 3 or divinePurposeActive) and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    -- Flash of Light for emergency healing
    if flashOfLight and
       settings.utilitySettings.useFlashOfLight and
       playerHealth <= settings.utilitySettings.flashOfLightThreshold and
       API.GetPlayerManaPercentage() > settings.rotationSettings.manaThreshold and
       not API.IsInPvPCombat() and
       API.CanCast(spells.FLASH_OF_LIGHT) then
        API.CastSpellOnUnit(spells.FLASH_OF_LIGHT, "player")
        return true
    end
    
    return false
end

-- Handle interrupts
function Retribution:HandleInterrupts(settings)
    -- Skip if not in melee range
    if not isInMelee then
        return false
    end
    
    -- Use Rebuke for interrupting
    if rebuke and
       settings.utilitySettings.useRebuke and
       API.CanCast(spells.REBUKE) and
       API.IsUnitCasting("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.REBUKE, "target")
        return true
    end
    
    -- Use Hammer of Justice as a backup interrupt
    if hammerOfJustice and
       settings.utilitySettings.useHammerOfJustice and
       settings.utilitySettings.hammerOfJusticeMode == "Interrupt Only" and
       API.CanCast(spells.HAMMER_OF_JUSTICE) and
       API.IsUnitCasting("target") and
       not API.IsUnitStunned("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.HAMMER_OF_JUSTICE, "target")
        return true
    end
    
    -- Use Hammer of Justice generally if set to on cooldown
    if hammerOfJustice and
       settings.utilitySettings.useHammerOfJustice and
       settings.utilitySettings.hammerOfJusticeMode == "On Cooldown" and
       API.CanCast(spells.HAMMER_OF_JUSTICE) and
       not API.IsUnitStunned("target") then
        API.CastSpellOnUnit(spells.HAMMER_OF_JUSTICE, "target")
        return true
    end
    
    return false
end

-- Handle defensive cooldowns
function Retribution:HandleDefensives(settings)
    -- Use Shield of Vengeance
    if API.CanCast(spells.SHIELD_OF_VENGEANCE) and
       settings.defensiveSettings.useShieldOfVengeance then
        
        local shouldUseShield = false
        
        if settings.defensiveSettings.shieldOfVengeanceMode == "On Cooldown" then
            shouldUseShield = true
        elseif settings.defensiveSettings.shieldOfVengeanceMode == "When Taking Damage" then
            shouldUseShield = playerHealth < 90
        elseif settings.defensiveSettings.shieldOfVengeanceMode == "Boss Only" then
            shouldUseShield = API.IsFightingBoss()
        end
        
        if shouldUseShield then
            API.CastSpell(spells.SHIELD_OF_VENGEANCE)
            return true
        end
    end
    
    -- Use Blessing of Protection on ally
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
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) and not API.UnitIsTank(unit) and not API.UnitHasDebuff(unit, debuffs.FORBEARANCE) then
                local unitHealth = API.GetUnitHealthPercent(unit)
                
                if unitHealth <= settings.defensiveSettings.blessingOfProtectionThreshold and API.CanCast(spells.BLESSING_OF_PROTECTION) then
                    API.CastSpellOnUnit(spells.BLESSING_OF_PROTECTION, unit)
                    return true
                end
            end
        end
    end
    
    -- Use Blessing of Freedom
    if blessingOfFreedom and
       settings.utilitySettings.useBlessingOfFreedom and
       API.CanCast(spells.BLESSING_OF_FREEDOM) and
       (API.IsMovementImpaired("player") or API.HasDebuffType("player", "Snare")) then
        API.CastSpellOnUnit(spells.BLESSING_OF_FREEDOM, "player")
        return true
    end
    
    -- Use Cleanse Toxins
    if cleansingLight and 
       settings.utilitySettings.useCleanseToxins and
       API.CanCast(spells.CLEANSE_TOXINS) and
       (API.HasDebuffType("player", "Poison") or API.HasDebuffType("player", "Disease")) then
        API.CastSpellOnUnit(spells.CLEANSE_TOXINS, "player")
        return true
    end
    
    return false
end

-- Handle offensive cooldowns
function Retribution:HandleOffensiveCooldowns(settings)
    -- Skip if not in combat or no target
    if not API.IsInCombat() or not API.UnitExists("target") or not API.IsUnitEnemy("target") then
        return false
    end
    
    -- Use Seraphim
    if seraphim and
       settings.cooldownSettings.useSeraphim and
       not seraphimActive and
       currentHolyPower >= 3 and
       API.CanCast(spells.SERAPHIM) then
        
        local shouldUseSeraphim = false
        
        if settings.cooldownSettings.seraphimMode == "On Cooldown" then
            shouldUseSeraphim = true
        elseif settings.cooldownSettings.seraphimMode == "With Cooldowns" then
            shouldUseSeraphim = avengingWrathActive or crusadeActive
        elseif settings.cooldownSettings.seraphimMode == "Pool Holy Power" then
            shouldUseSeraphim = currentHolyPower >= 4
        end
        
        if shouldUseSeraphim then
            API.CastSpell(spells.SERAPHIM)
            return true
        end
    end
    
    -- Use Avenging Wrath
    if avengingWrath and
       settings.cooldownSettings.useAvengingWrath and
       not avengingWrathActive and
       not crusadeActive and -- Don't use if we have Crusade active
       API.CanCast(spells.AVENGING_WRATH) then
        
        local shouldUseAW = false
        
        if settings.cooldownSettings.avengingWrathMode == "On Cooldown" then
            shouldUseAW = true
        elseif settings.cooldownSettings.avengingWrathMode == "With Other Cooldowns" then
            shouldUseAW = finalReckoningActive or executionSentenceActive
        elseif settings.cooldownSettings.avengingWrathMode == "Boss Only" then
            shouldUseAW = API.IsFightingBoss()
        elseif settings.cooldownSettings.avengingWrathMode == "Burst Only" then
            shouldUseAW = burstModeActive
        end
        
        if shouldUseAW then
            API.CastSpell(spells.AVENGING_WRATH)
            return true
        end
    end
    
    -- Use Crusade (alternative to Avenging Wrath)
    if crusade and
       settings.cooldownSettings.useCrusade and
       not crusadeActive and
       not avengingWrathActive and -- Don't use if we have Avenging Wrath active
       API.CanCast(spells.CRUSADE) then
        
        local shouldUseCrusade = false
        
        if settings.cooldownSettings.crusadeMode == "On Cooldown" then
            shouldUseCrusade = true
        elseif settings.cooldownSettings.crusadeMode == "Boss Only" then
            shouldUseCrusade = API.IsFightingBoss()
        elseif settings.cooldownSettings.crusadeMode == "Burst Only" then
            shouldUseCrusade = burstModeActive
        end
        
        if shouldUseCrusade then
            API.CastSpell(spells.CRUSADE)
            return true
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
        elseif settings.cooldownSettings.holyAvengerMode == "With Crusade" then
            shouldUseHA = crusadeActive
        end
        
        if shouldUseHA then
            API.CastSpell(spells.HOLY_AVENGER)
            return true
        end
    end
    
    -- Use Final Reckoning
    if finalReckoning and
       settings.cooldownSettings.useFinalReckoning and
       not finalReckoningActive and
       API.CanCast(spells.FINAL_RECKONING) then
        
        local shouldUseFR = false
        
        if settings.cooldownSettings.finalReckoningMode == "On Cooldown" then
            shouldUseFR = true
        elseif settings.cooldownSettings.finalReckoningMode == "With Cooldowns" then
            shouldUseFR = avengingWrathActive or crusadeActive
        elseif settings.cooldownSettings.finalReckoningMode == "With Templar Verdict" then
            shouldUseFR = currentHolyPower >= 3
        end
        
        if shouldUseFR then
            API.CastSpell(spells.FINAL_RECKONING)
            return true
        end
    end
    
    -- Use Execution Sentence
    if executionSentence and
       settings.cooldownSettings.useExecutionSentence and
       not executionSentenceActive and
       API.CanCast(spells.EXECUTION_SENTENCE) then
        
        local shouldUseES = false
        
        if settings.cooldownSettings.executionSentenceMode == "On Cooldown" then
            shouldUseES = true
        elseif settings.cooldownSettings.executionSentenceMode == "With Cooldowns" then
            shouldUseES = avengingWrathActive or crusadeActive
        elseif settings.cooldownSettings.executionSentenceMode == "Single Target Only" then
            shouldUseES = activeEnemies <= 1
        end
        
        if shouldUseES then
            API.CastSpell(spells.EXECUTION_SENTENCE)
            return true
        end
    end
    
    -- Use Divine Toll
    if divineToll and
       settings.cooldownSettings.useDivineToll and
       API.CanCast(spells.DIVINE_TOLL) then
        
        local shouldUseDT = false
        
        if settings.cooldownSettings.divineTollMode == "On Cooldown" then
            shouldUseDT = true
        elseif settings.cooldownSettings.divineTollMode == "Multiple Enemies" then
            shouldUseDT = activeEnemies >= 3
        elseif settings.cooldownSettings.divineTollMode == "For Holy Power" then
            shouldUseDT = currentHolyPower <= settings.cooldownSettings.divineTollThreshold
        elseif settings.cooldownSettings.divineTollMode == "Burst Only" then
            shouldUseDT = burstModeActive
        end
        
        if shouldUseDT then
            API.CastSpell(spells.DIVINE_TOLL)
            return true
        end
    end
    
    -- Use Ashen Hallow
    if ashenHallow and
       settings.cooldownSettings.useAshenHallow and
       not ashenHallowActive and
       API.CanCast(spells.ASHEN_HALLOW) then
        
        local shouldUseAH = false
        
        if settings.cooldownSettings.ashenHallowMode == "On Cooldown" then
            shouldUseAH = true
        elseif settings.cooldownSettings.ashenHallowMode == "With Cooldowns" then
            shouldUseAH = avengingWrathActive or crusadeActive
        elseif settings.cooldownSettings.ashenHallowMode == "AoE Only" then
            shouldUseAH = activeEnemies >= 3
        elseif settings.cooldownSettings.ashenHallowMode == "Burst Only" then
            shouldUseAH = burstModeActive
        end
        
        if shouldUseAH then
            API.CastSpellAtBestLocation(spells.ASHEN_HALLOW)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Retribution:HandleAoE(settings)
    -- Use Wake of Ashes
    if wakeOfAshes and
       API.CanCast(spells.WAKE_OF_ASHES) and
       settings.abilityControls.wakeOfAshes.enabled and
       activeEnemies >= settings.abilityControls.wakeOfAshes.minEnemies then
        
        local shouldUseWoA = true
        
        if settings.abilityControls.wakeOfAshes.useDuringBurstOnly and not burstModeActive then
            shouldUseWoA = false
        end
        
        if settings.abilityControls.wakeOfAshes.requireLowHolyPower and currentHolyPower >= 3 then
            shouldUseWoA = false
        end
        
        if shouldUseWoA then
            API.CastSpell(spells.WAKE_OF_ASHES)
            return true
        end
    end
    
    -- Use Divine Storm as a finisher
    if divineStorm and
       settings.finisherSettings.useDivineStorm and
       (currentHolyPower >= settings.finisherSettings.minHolyPowerForFinisher or divinePurposeActive) and
       API.CanCast(spells.DIVINE_STORM) and
       settings.abilityControls.divineStorm.enabled then
        
        local shouldUseDivineStorm = activeEnemies >= settings.finisherSettings.divineStormThreshold
        
        -- Extra conditions for Divine Storm
        if settings.finisherSettings.divineStormWithEmpyreanPower and empyreanPowerActive then
            shouldUseDivineStorm = true
        end
        
        if divineTempest and settings.finisherSettings.prioritizeDivineStormWithDivineTempest then
            shouldUseDivineStorm = true
        end
        
        if settings.abilityControls.divineStorm.useDuringBurstOnly and not burstModeActive then
            shouldUseDivineStorm = false
        end
        
        if settings.abilityControls.divineStorm.minEnemies > activeEnemies then
            shouldUseDivineStorm = false
        end
        
        if settings.abilityControls.divineStorm.requireEmpyreanPower and not empyreanPowerActive then
            shouldUseDivineStorm = false
        end
        
        if shouldUseDivineStorm then
            API.CastSpell(spells.DIVINE_STORM)
            return true
        end
    end
    
    -- Maintain Consecration if talented
    if consecrationTalent and
       settings.rotationSettings.maintainConsecration and
       (not consecrationActive or consecrationEndTime - GetTime() < 1.5) and
       API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    -- Blade of Justice for Holy Power generation
    if bladeOfJustice and API.CanCast(spells.BLADE_OF_JUSTICE) then
        API.CastSpell(spells.BLADE_OF_JUSTICE)
        return true
    end
    
    -- Hammer of Wrath if available (target below 20% or Avenging Wrath/Crusade active)
    if hammerOfWrath and
       API.CanCast(spells.HAMMER_OF_WRATH) then
        
        local shouldUseHoW = false
        
        if settings.rotationSettings.hammerOfWrathMode == "Sub 20% HP Only" then
            shouldUseHoW = targetHealth < 20
        elseif settings.rotationSettings.hammerOfWrathMode == "During Cooldowns" then
            shouldUseHoW = (targetHealth < 20) or avengingWrathActive or crusadeActive
        elseif settings.rotationSettings.hammerOfWrathMode == "Always When Available" then
            shouldUseHoW = (targetHealth < 20) or avengingWrathActive or crusadeActive
        end
        
        if shouldUseHoW then
            API.CastSpell(spells.HAMMER_OF_WRATH)
            return true
        end
    end
    
    -- Judgment for Holy Power generation
    if judgment and API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Crusader Strike or Templar Strike for Holy Power generation
    if templarStrike and API.CanCast(spells.TEMPLAR_STRIKE) then
        API.CastSpell(spells.TEMPLAR_STRIKE)
        return true
    elseif crusaderStrike and API.CanCast(spells.CRUSADER_STRIKE) then
        API.CastSpell(spells.CRUSADER_STRIKE)
        return true
    end
    
    -- Consecration as a filler
    if consecrationTalent and API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle single target rotation
function Retribution:HandleSingleTarget(settings)
    -- Use Wake of Ashes for Holy Power
    if wakeOfAshes and
       API.CanCast(spells.WAKE_OF_ASHES) and
       settings.abilityControls.wakeOfAshes.enabled and
       currentHolyPower <= 2 then
        
        local shouldUseWoA = true
        
        if settings.abilityControls.wakeOfAshes.useDuringBurstOnly and not burstModeActive then
            shouldUseWoA = false
        end
        
        if shouldUseWoA then
            API.CastSpell(spells.WAKE_OF_ASHES)
            return true
        end
    end
    
    -- Use Templar Verdict or Final Verdict as a finisher
    if settings.finisherSettings.useTemplarVerdict and
       (currentHolyPower >= settings.finisherSettings.minHolyPowerForFinisher or divinePurposeActive) and
       settings.abilityControls.templarVerdict.enabled then
        
        local shouldUseTV = true
        
        -- Check if we require judgment debuff
        if settings.abilityControls.templarVerdict.requireJudgment and not judgmentApplied then
            shouldUseTV = false
        end
        
        -- Check if we prioritize Final Reckoning
        if settings.abilityControls.templarVerdict.prioritizeFinalReckoning and finalReckoningActive then
            shouldUseTV = true
        end
        
        -- Check if we should use during burst only
        if settings.abilityControls.templarVerdict.useDuringBurstOnly and not burstModeActive then
            shouldUseTV = false
        end
        
        -- If we should use Templar Verdict
        if shouldUseTV then
            -- Check if we should use Final Verdict instead
            if finalVerdict and API.CanCast(spells.FINAL_VERDICT) then
                API.CastSpell(spells.FINAL_VERDICT)
                return true
            elseif API.CanCast(spells.TEMPLAR_VERDICT) then
                API.CastSpell(spells.TEMPLAR_VERDICT)
                return true
            end
        end
    end
    
    -- Use Divine Storm with Empyrean Power
    if divineStorm and
       settings.finisherSettings.divineStormWithEmpyreanPower and
       empyreanPowerActive and
       API.CanCast(spells.DIVINE_STORM) then
        API.CastSpell(spells.DIVINE_STORM)
        return true
    end
    
    -- Blade of Justice for Holy Power generation
    if bladeOfJustice and API.CanCast(spells.BLADE_OF_JUSTICE) then
        API.CastSpell(spells.BLADE_OF_JUSTICE)
        return true
    end
    
    -- Judgment for Holy Power generation
    if judgment and API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Hammer of Wrath if available (target below 20% or Avenging Wrath/Crusade active)
    if hammerOfWrath and
       API.CanCast(spells.HAMMER_OF_WRATH) then
        
        local shouldUseHoW = false
        
        if settings.rotationSettings.hammerOfWrathMode == "Sub 20% HP Only" then
            shouldUseHoW = targetHealth < 20
        elseif settings.rotationSettings.hammerOfWrathMode == "During Cooldowns" then
            shouldUseHoW = (targetHealth < 20) or avengingWrathActive or crusadeActive
        elseif settings.rotationSettings.hammerOfWrathMode == "Always When Available" then
            shouldUseHoW = (targetHealth < 20) or avengingWrathActive or crusadeActive
        end
        
        if shouldUseHoW then
            API.CastSpell(spells.HAMMER_OF_WRATH)
            return true
        end
    end
    
    -- Templar Strike or Crusader Strike for Holy Power generation
    if templarStrike and API.CanCast(spells.TEMPLAR_STRIKE) then
        API.CastSpell(spells.TEMPLAR_STRIKE)
        return true
    elseif crusaderStrike and API.CanCast(spells.CRUSADER_STRIKE) then
        API.CastSpell(spells.CRUSADER_STRIKE)
        return true
    end
    
    -- Consecration as a filler if talented
    if consecrationTalent and 
       settings.rotationSettings.maintainConsecration and
       API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle specialization change
function Retribution:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentHolyPower = 0
    maxHolyPower = 5
    divineStormBuffActive = false
    divineStormBuffEndTime = 0
    divineStormBuffStacks = 0
    divinePurposeActive = false
    divinePurposeEndTime = 0
    avengingWrathActive = false
    avengingWrathEndTime = 0
    crusadeActive = false
    crusadeEndTime = 0
    crusadeStacks = 0
    executionSentenceActive = false
    executionSentenceEndTime = 0
    finalReckoningActive = false
    finalReckoningEndTime = 0
    seraphimActive = false
    seraphimEndTime = 0
    fistOfJusticeActive = false
    divineFavorActive = false
    divineFavorEndTime = 0
    divineResonanceActive = false
    divineResonanceEndTime = 0
    divineResonanceStacks = 0
    consecrationActive = false
    consecrationEndTime = 0
    empyreanPowerActive = false
    empyreanPowerEndTime = 0
    holyAvengerActive = false
    holyAvengerEndTime = 0
    divineArbiterActive = false
    divineTollActive = false
    ashenHallowActive = false
    lastCrusaderStrike = 0
    lastJudgment = 0
    lastBladeOfJustice = 0
    lastWakeOfAshes = 0
    lastDivineStorm = 0
    lastTemplarVerdict = 0
    lastAvengingWrath = 0
    lastExecutionSentence = 0
    lastFinalReckoning = 0
    lastCrusade = 0
    lastHammerOfWrath = 0
    lastHolyAvenger = 0
    lastSeraphim = 0
    lastDivineToll = 0
    lastAshenHallow = 0
    lastWordOfGlory = 0
    lastLayOnHands = 0
    lastFlashOfLight = 0
    lastDivineShield = 0
    lastBlessingOfProtection = 0
    lastBlessingOfFreedom = 0
    lastBlessingOfSacrifice = 0
    lastHammerOfJustice = 0
    lastRebuke = 0
    lastForbearance = 0
    lastTemperingFlare = 0
    targetInRange = false
    playerHealth = 100
    targetHealth = 100
    activeEnemies = 0
    isInMelee = false
    worthyOfLight = false
    judgmentApplied = false
    
    API.PrintDebug("Retribution Paladin state reset on spec change")
    
    return true
end

-- Return the module for loading
return Retribution