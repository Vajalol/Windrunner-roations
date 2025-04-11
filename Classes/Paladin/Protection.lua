------------------------------------------
-- WindrunnerRotations - Protection Paladin Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Protection = {}
-- This will be assigned to addon.Classes.Paladin.Protection when loaded

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
local shieldOfTheRighteousCharges = 0
local shieldOfTheRighteousMaxCharges = 0
local shieldOfTheRighteousActive = false
local shieldOfTheRighteousEndTime = 0
local consecrationActive = false
local consecrationEndTime = 0
local divineTollActive = false
local avengingWrathActive = false
local avengingWrathEndTime = 0
local ardentDefenderActive = false
local ardentDefenderEndTime = 0
local guardianOfAncientKingsActive = false
local guardianOfAncientKingsEndTime = 0
local hammerOfJusticeOnCooldown = false
local blessingOfProtectionOnCooldown = false
local blessingOfSacrificeOnCooldown = false
local divineShieldActive = false
local divineShieldEndTime = 0
local sentinelActive = false
local sentinelEndTime = 0
local divinePurposeActive = false
local divinePurposeEndTime = 0
local lastAvengersShield = 0
local lastJudgment = 0
local lastShieldOfTheRighteous = 0
local lastWordOfGlory = 0
local lastHammerOfWrath = 0
local lastAvengingWrath = 0
local lastArdentDefender = 0
local lastGuardianOfAncientKings = 0
local lastConsecrateTime = 0
local lastDivineProtection = 0
local lastLayOnHands = 0
local lastSentinel = 0
local lastFinalStand = 0
local lastDivineToll = 0
local lastMomentOfGlory = 0
local lastDivineResonance = 0
local lastForbearance = 0
local targetInRange = false
local playerHealth = 100
local targetHealth = 100
local threatSituation = "LOW"
local activeEnemies = 0
local activeImportantEnemies = 0
local activeBossEnemies = 0
local isInMelee = false
local meleeRange = 5 -- yards
local judgmentApplied = false
local toweringShieldActive = false -- Season 2 trait
local toweringShieldEndTime = 0
local toweringShieldStacks = 0
local mightyDisplacer = false -- Season 2 trait
local mightyDisplacerActive = false
local mightyDisplacerEndTime = 0
local mightyDisplacerStacks = 0
local flaringResistanceTalent = false
local flaringResistanceActive = false
local flaringResistanceStacks = 0
local avengersShield = false
local judgment = false
local hammer = false
local consecrate = false
local shieldOfRighteous = false
local wordOfGlory = false
local blessedHammer = false
local holyShield = false
local firstShield = false
local divineProtection = false
local ardentDefender = false
local guardianOfAncientKings = false
local layOnHands = false
local momentOfGlory = false
local divineResonance = false
local rightBlindingLight = false
local finalStand = false
local divineToll = false
local hammerOfWrath = false
local crusaderStrike = false
local blessingOfProtection = false
local blessingOfSacrifice = false
local eyeOfTyr = false
local divinePurpose = false
local focusedBlessings = false
local bulwarkOfOrder = false
local bulwarkOfRighteous = false
local sentinel = false
local crusaderAura = false
local righteousProtector = false
local redoubt = false
local revitalizingShadow = false
local faithsArmor = false
local holySeal = false
local soloShield = false
local kingOfTheJungle = false
local resolute = false
local improvedDefense = false

-- Constants
local PROTECTION_SPEC_ID = 66
local SHIELD_OF_THE_RIGHTEOUS_DURATION = 4.5 -- seconds
local CONSECRATION_DURATION = 12.0 -- seconds
local AVENGING_WRATH_DURATION = 20.0 -- seconds
local ARDENT_DEFENDER_DURATION = 8.0 -- seconds
local GUARDIAN_OF_ANCIENT_KINGS_DURATION = 8.0 -- seconds
local DIVINE_SHIELD_DURATION = 8.0 -- seconds
local SENTINEL_DURATION = 8.0 -- seconds
local TOWERING_SHIELD_DURATION = 10.0 -- seconds
local MIGHTY_DISPLACER_DURATION = 8.0 -- seconds
local FLARING_RESISTANCE_DURATION = 15.0 -- seconds
local DIVINE_PURPOSE_DURATION = 10.0 -- seconds

-- Initialize the Protection module
function Protection:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Protection Paladin module initialized")
    
    return true
end

-- Register spell IDs
function Protection:RegisterSpells()
    -- Core rotational abilities
    spells.AVENGERS_SHIELD = 31935
    spells.JUDGMENT = 275779
    spells.HAMMER_OF_THE_RIGHTEOUS = 53595
    spells.BLESSED_HAMMER = 204019
    spells.CONSECRATION = 26573
    spells.SHIELD_OF_THE_RIGHTEOUS = 53600
    spells.WORD_OF_GLORY = 85673
    spells.HAMMER_OF_WRATH = 24275
    spells.CRUSADER_STRIKE = 35395
    
    -- Core defensive abilities
    spells.DIVINE_PROTECTION = 498
    spells.ARDENT_DEFENDER = 31850
    spells.GUARDIAN_OF_ANCIENT_KINGS = 86659
    spells.LAY_ON_HANDS = 633
    spells.DIVINE_SHIELD = 642
    spells.BLESSING_OF_PROTECTION = 1022
    spells.BLESSING_OF_SACRIFICE = 6940
    spells.AVENGING_WRATH = 31884
    spells.SENTINEL = 389539
    
    -- Core utility abilities
    spells.HAMMER_OF_JUSTICE = 853
    spells.REBUKE = 96231
    spells.DEVOTION_AURA = 465
    spells.CRUSADER_AURA = 32223
    spells.HAND_OF_RECKONING = 62124
    spells.CLEANSE_TOXINS = 213644
    spells.TURN_EVIL = 10326
    spells.FLASH_OF_LIGHT = 19750
    spells.BLINDING_LIGHT = 115750
    spells.FINAL_STAND = 204077
    spells.EYE_OF_TYR = 387174
    
    -- Talents and passives
    spells.DIVINE_PURPOSE = 223817
    spells.FOCUSED_BLESSINGS = 394302
    spells.BULWARK_OF_ORDER = 209389
    spells.BULWARK_OF_RIGHTEOUS_FURY = 386653
    spells.RIGHTEOUS_PROTECTOR = 204074
    spells.REDOUBT = 280373
    spells.REVITALIZING_SHADOW = 394025
    spells.FAITHS_ARMOR = 378424
    spells.HOLY_SHIELD = 152261
    spells.MOMENT_OF_GLORY = 327193
    spells.DIVINE_RESONANCE = 386738
    spells.RIGHTEOUS_BLINDING_LIGHT = 393843
    spells.RESOLUTE_DEFENDER = 385422
    spells.IMPROVED_CONSECRATION = 379434
    spells.FIRST_AVENGERS = 203776
    spells.KING_OF_THE_JUNGLE = 394729
    spells.RESOLUTE = 392931
    spells.IMPROVED_RIGHTEOUS_DEFENSE = 152262
    spells.HOLY_SEAL = 385795
    spells.SOLO_SHIELD = 387286
    
    -- War Within Season 2 specific
    spells.TOWERING_SHIELD = 452522
    spells.MIGHTY_DISPLACER = 414222
    spells.FLARING_RESISTANCE = 393840
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.DIVINE_TOLL = 375576
    
    -- Buff IDs
    spells.SHIELD_OF_THE_RIGHTEOUS_BUFF = 132403
    spells.CONSECRATION_BUFF = 188370
    spells.AVENGING_WRATH_BUFF = 31884
    spells.ARDENT_DEFENDER_BUFF = 31850
    spells.GUARDIAN_OF_ANCIENT_KINGS_BUFF = 86659
    spells.DIVINE_SHIELD_BUFF = 642
    spells.SENTINEL_BUFF = 389539
    spells.TOWERING_SHIELD_BUFF = 414227
    spells.MIGHTY_DISPLACER_BUFF = 414222
    spells.FLARING_RESISTANCE_BUFF = 393840
    spells.DIVINE_PURPOSE_BUFF = 223819
    
    -- Debuff IDs
    spells.HAMMER_OF_JUSTICE_DEBUFF = 853
    spells.JUDGMENT_DEBUFF = 197277
    spells.FORBEARANCE_DEBUFF = 25771
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SHIELD_OF_THE_RIGHTEOUS = spells.SHIELD_OF_THE_RIGHTEOUS_BUFF
    buffs.CONSECRATION = spells.CONSECRATION_BUFF
    buffs.AVENGING_WRATH = spells.AVENGING_WRATH_BUFF
    buffs.ARDENT_DEFENDER = spells.ARDENT_DEFENDER_BUFF
    buffs.GUARDIAN_OF_ANCIENT_KINGS = spells.GUARDIAN_OF_ANCIENT_KINGS_BUFF
    buffs.DIVINE_SHIELD = spells.DIVINE_SHIELD_BUFF
    buffs.SENTINEL = spells.SENTINEL_BUFF
    buffs.TOWERING_SHIELD = spells.TOWERING_SHIELD_BUFF
    buffs.MIGHTY_DISPLACER = spells.MIGHTY_DISPLACER_BUFF
    buffs.FLARING_RESISTANCE = spells.FLARING_RESISTANCE_BUFF
    buffs.DIVINE_PURPOSE = spells.DIVINE_PURPOSE_BUFF
    
    debuffs.HAMMER_OF_JUSTICE = spells.HAMMER_OF_JUSTICE_DEBUFF
    debuffs.JUDGMENT = spells.JUDGMENT_DEBUFF
    debuffs.FORBEARANCE = spells.FORBEARANCE_DEBUFF
    
    return true
end

-- Register variables to track
function Protection:RegisterVariables()
    -- Talent tracking
    talents.hasDivinePurpose = false
    talents.hasFocusedBlessings = false
    talents.hasBulwarkOfOrder = false
    talents.hasBulwarkOfRighteousFury = false
    talents.hasRighteousProtector = false
    talents.hasRedoubt = false
    talents.hasRevitalizingShadow = false
    talents.hasFaithsArmor = false
    talents.hasHolyShield = false
    talents.hasMomentOfGlory = false
    talents.hasDivineResonance = false
    talents.hasRighteousBlindingLight = false
    talents.hasResolute = false
    talents.hasImprovedConsecration = false
    talents.hasFirstAvengers = false
    talents.hasKingOfTheJungle = false
    talents.hasResoluteDefender = false
    talents.hasImprovedRighteousDefense = false
    talents.hasHolySeal = false
    talents.hasSoloShield = false
    talents.hasBlessedHammer = false
    talents.hasFinalStand = false
    talents.hasDivineToll = false
    talents.hasSentinel = false
    talents.hasToweringShield = false
    talents.hasMightyDisplacer = false
    talents.hasFlaringResistance = false
    
    -- Initialize holy power
    currentHolyPower = API.GetPlayerPower() or 0
    maxHolyPower = 5 -- Default, could be higher if talented
    
    -- Initialize Shield of the Righteous charges
    shieldOfTheRighteousCharges, shieldOfTheRighteousMaxCharges = API.GetSpellCharges(spells.SHIELD_OF_THE_RIGHTEOUS) or 0, 3
    
    -- Track if in melee range
    isInMelee = false
    
    return true
end

-- Register spec-specific settings
function Protection:RegisterSettings()
    ConfigRegistry:RegisterSettings("ProtectionPaladin", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst threat generation",
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
                description = "Pool Holy Power for Shield of the Righteous",
                type = "toggle",
                default = true
            },
            holyPowerPoolingThreshold = {
                displayName = "Holy Power Pooling Threshold",
                description = "Minimum Holy Power to maintain",
                type = "slider",
                min = 1,
                max = 4,
                default = 2
            },
            sotrOverlap = {
                displayName = "Allow SotR Overlap",
                description = "Allow Shield of the Righteous to overlap if needed",
                type = "toggle",
                default = true
            },
            maintainConsecration = {
                displayName = "Maintain Consecration",
                description = "Always keep Consecration active",
                type = "toggle",
                default = true
            },
            kiting = {
                displayName = "Enable Kiting Mode",
                description = "Prioritize kiting in dangerous situations",
                type = "toggle",
                default = false
            },
            defensiveCooldownMode = {
                displayName = "Defensive Cooldown Usage",
                description = "How to use defensive cooldowns",
                type = "dropdown",
                options = {"Conservative", "Balanced", "Aggressive", "Manual Only"},
                default = "Balanced"
            },
            wordOfGloryThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory on self",
                type = "slider",
                min = 10,
                max = 80,
                default = 40
            },
            wordOfGloryAllyThreshold = {
                displayName = "Word of Glory Ally Health Threshold",
                description = "Health percentage to use Word of Glory on ally",
                type = "slider",
                min = 10,
                max = 80,
                default = 30
            }
        },
        
        shieldOfRighteousSettings = {
            useSotROnCooldown = {
                displayName = "Use SotR On Cooldown",
                description = "Use Shield of the Righteous whenever charges are available",
                type = "toggle",
                default = false
            },
            minSotRCharges = {
                displayName = "Minimum SotR Charges",
                description = "Minimum charges to keep reserved",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            },
            emergencySotRThreshold = {
                displayName = "Emergency SotR Health Threshold",
                description = "Health percentage to use Shield of the Righteous regardless of charges",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            prioritizeSotROverWoG = {
                displayName = "Prioritize SotR Over WoG",
                description = "Use Shield of the Righteous over Word of Glory in most cases",
                type = "toggle",
                default = true
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
                options = {"On Cooldown", "Multiple Enemies", "Boss Only", "Burst Only"},
                default = "Multiple Enemies"
            },
            useArdentDefender = {
                displayName = "Use Ardent Defender",
                description = "Automatically use Ardent Defender",
                type = "toggle",
                default = true
            },
            ardentDefenderThreshold = {
                displayName = "Ardent Defender Health Threshold",
                description = "Health percentage to use Ardent Defender",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useGuardianOfAncientKings = {
                displayName = "Use Guardian of Ancient Kings",
                description = "Automatically use Guardian of Ancient Kings",
                type = "toggle",
                default = true
            },
            guardianOfAncientKingsThreshold = {
                displayName = "Guardian Health Threshold",
                description = "Health percentage to use Guardian of Ancient Kings",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useDivineProtection = {
                displayName = "Use Divine Protection",
                description = "Automatically use Divine Protection",
                type = "toggle",
                default = true
            },
            divineProtectionThreshold = {
                displayName = "Divine Protection Health Threshold",
                description = "Health percentage to use Divine Protection",
                type = "slider",
                min = 10,
                max = 80,
                default = 60
            },
            useSentinel = {
                displayName = "Use Sentinel",
                description = "Automatically use Sentinel when talented",
                type = "toggle",
                default = true
            },
            sentinelThreshold = {
                displayName = "Sentinel Health Threshold",
                description = "Health percentage to use Sentinel",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
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
                default = "Multiple Enemies"
            },
            divineTollThreshold = {
                displayName = "Divine Toll Holy Power Threshold",
                description = "Holy Power threshold to use Divine Toll",
                type = "slider",
                min = 0,
                max = 4,
                default = 1
            }
        },
        
        interruptSettings = {
            useInterrupts = {
                displayName = "Use Interrupts",
                description = "Automatically interrupt spellcasting",
                type = "toggle",
                default = true
            },
            useMindControl = {
                displayName = "Use Mind Control Breaks",
                description = "Use Blessing of Protection to break Mind Control",
                type = "toggle",
                default = true
            },
            useRebuke = {
                displayName = "Use Rebuke",
                description = "Use Rebuke to interrupt",
                type = "toggle",
                default = true
            },
            useHammerOfJustice = {
                displayName = "Use Hammer of Justice",
                description = "Use Hammer of Justice to interrupt",
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
        
        utilitySettings = {
            useCleanseToxins = {
                displayName = "Use Cleanse Toxins",
                description = "Automatically cleanse poisons and diseases",
                type = "toggle",
                default = true
            },
            useTurnEvil = {
                displayName = "Use Turn Evil",
                description = "Automatically use Turn Evil on Undead and Demons",
                type = "toggle",
                default = true
            },
            useFinalStand = {
                displayName = "Use Final Stand",
                description = "Automatically use Final Stand when talented",
                type = "toggle",
                default = true
            },
            finalStandMode = {
                displayName = "Final Stand Usage",
                description = "When to use Final Stand",
                type = "dropdown",
                options = {"Emergency Only", "Multiple Adds", "On Cooldown", "Manual Only"},
                default = "Multiple Adds"
            },
            finalStandThreshold = {
                displayName = "Final Stand Enemy Count",
                description = "Minimum number of enemies to use Final Stand",
                type = "slider",
                min = 2,
                max = 8,
                default = 3
            },
            useHandOfReckoning = {
                displayName = "Use Hand of Reckoning",
                description = "Automatically taunt enemies",
                type = "toggle",
                default = true
            },
            handOfReckoningMode = {
                displayName = "Hand of Reckoning Usage",
                description = "When to use Hand of Reckoning",
                type = "dropdown",
                options = {"Lost Aggro Only", "On Cooldown", "Manual Only"},
                default = "Lost Aggro Only"
            }
        },
        
        defensiveSettings = {
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
            layOnHandsAllyThreshold = {
                displayName = "Lay on Hands Ally Health Threshold",
                description = "Health percentage to use Lay on Hands on ally",
                type = "slider",
                min = 5,
                max = 25,
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
                max = 30,
                default = 15
            },
            useBlessingOfSacrifice = {
                displayName = "Use Blessing of Sacrifice",
                description = "Automatically use Blessing of Sacrifice",
                type = "toggle",
                default = true
            },
            blessingOfSacrificeThreshold = {
                displayName = "Blessing of Sacrifice Health Threshold",
                description = "Health percentage to use Blessing of Sacrifice on ally",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
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
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Shield of the Righteous controls
            shieldOfTheRighteous = AAC.RegisterAbility(spells.SHIELD_OF_THE_RIGHTEOUS, {
                enabled = true,
                useDuringBurstOnly = false,
                minCharges = 1,
                useForPhysicalDamage = true
            }),
            
            -- Word of Glory controls
            wordOfGlory = AAC.RegisterAbility(spells.WORD_OF_GLORY, {
                enabled = true,
                useDuringBurstOnly = false,
                preferSelfHealing = true,
                emergencyOnly = false
            }),
            
            -- Avenger's Shield controls
            avengersShield = AAC.RegisterAbility(spells.AVENGERS_SHIELD, {
                enabled = true,
                useDuringBurstOnly = false,
                interruptPriority = "High"
            })
        }
    })
    
    return true
end

-- Register for events 
function Protection:RegisterEvents()
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
    
    -- Register for Shield of the Righteous charge updates
    API.RegisterEvent("SPELL_UPDATE_CHARGES", function(spellID) 
        if spellID == spells.SHIELD_OF_THE_RIGHTEOUS then
            self:UpdateSotRCharges()
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
    
    -- Register for threat updates
    API.RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", function(unit) 
        if unit == "player" then
            self:UpdateThreatSituation()
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial Shield of the Righteous charges
    self:UpdateSotRCharges()
    
    return true
end

-- Update talent information
function Protection:UpdateTalentInfo()
    -- Check for important talents
    talents.hasDivinePurpose = API.HasTalent(spells.DIVINE_PURPOSE)
    talents.hasFocusedBlessings = API.HasTalent(spells.FOCUSED_BLESSINGS)
    talents.hasBulwarkOfOrder = API.HasTalent(spells.BULWARK_OF_ORDER)
    talents.hasBulwarkOfRighteousFury = API.HasTalent(spells.BULWARK_OF_RIGHTEOUS_FURY)
    talents.hasRighteousProtector = API.HasTalent(spells.RIGHTEOUS_PROTECTOR)
    talents.hasRedoubt = API.HasTalent(spells.REDOUBT)
    talents.hasRevitalizingShadow = API.HasTalent(spells.REVITALIZING_SHADOW)
    talents.hasFaithsArmor = API.HasTalent(spells.FAITHS_ARMOR)
    talents.hasHolyShield = API.HasTalent(spells.HOLY_SHIELD)
    talents.hasMomentOfGlory = API.HasTalent(spells.MOMENT_OF_GLORY)
    talents.hasDivineResonance = API.HasTalent(spells.DIVINE_RESONANCE)
    talents.hasRighteousBlindingLight = API.HasTalent(spells.RIGHTEOUS_BLINDING_LIGHT)
    talents.hasResolute = API.HasTalent(spells.RESOLUTE)
    talents.hasImprovedConsecration = API.HasTalent(spells.IMPROVED_CONSECRATION)
    talents.hasFirstAvengers = API.HasTalent(spells.FIRST_AVENGERS)
    talents.hasKingOfTheJungle = API.HasTalent(spells.KING_OF_THE_JUNGLE)
    talents.hasResoluteDefender = API.HasTalent(spells.RESOLUTE_DEFENDER)
    talents.hasImprovedRighteousDefense = API.HasTalent(spells.IMPROVED_RIGHTEOUS_DEFENSE)
    talents.hasHolySeal = API.HasTalent(spells.HOLY_SEAL)
    talents.hasSoloShield = API.HasTalent(spells.SOLO_SHIELD)
    talents.hasBlessedHammer = API.HasTalent(spells.BLESSED_HAMMER)
    talents.hasFinalStand = API.HasTalent(spells.FINAL_STAND)
    talents.hasDivineToll = API.HasTalent(spells.DIVINE_TOLL)
    talents.hasSentinel = API.HasTalent(spells.SENTINEL)
    talents.hasToweringShield = API.HasTalent(spells.TOWERING_SHIELD)
    talents.hasMightyDisplacer = API.HasTalent(spells.MIGHTY_DISPLACER)
    talents.hasFlaringResistance = API.HasTalent(spells.FLARING_RESISTANCE)
    
    -- Set specialized variables based on talents
    if talents.hasDivinePurpose then
        divinePurpose = true
        divinePurposeActive = API.UnitHasBuff("player", buffs.DIVINE_PURPOSE)
    end
    
    if talents.hasFocusedBlessings then
        focusedBlessings = true
    end
    
    if talents.hasBulwarkOfOrder then
        bulwarkOfOrder = true
    end
    
    if talents.hasBulwarkOfRighteousFury then
        bulwarkOfRighteous = true
    end
    
    if talents.hasRighteousProtector then
        righteousProtector = true
    end
    
    if talents.hasRedoubt then
        redoubt = true
    end
    
    if talents.hasRevitalizingShadow then
        revitalizingShadow = true
    end
    
    if talents.hasFaithsArmor then
        faithsArmor = true
    end
    
    if talents.hasHolyShield then
        holyShield = true
    end
    
    if talents.hasMomentOfGlory then
        momentOfGlory = true
    end
    
    if talents.hasDivineResonance then
        divineResonance = true
    end
    
    if talents.hasRighteousBlindingLight then
        rightBlindingLight = true
    end
    
    if talents.hasHolySeal then
        holySeal = true
    end
    
    if talents.hasSoloShield then
        soloShield = true
    end
    
    if talents.hasBlessedHammer then
        blessedHammer = true
    end
    
    if talents.hasFirstAvengers then
        firstShield = true
    end
    
    if talents.hasFinalStand then
        finalStand = true
    end
    
    if talents.hasDivineToll then
        divineToll = true
    end
    
    if talents.hasSentinel then
        sentinel = true
    end
    
    if talents.hasResolute then
        resolute = true
    end
    
    if talents.hasImprovedRighteousDefense then
        improvedDefense = true
    end
    
    if API.IsSpellKnown(spells.CRUSADER_AURA) then
        crusaderAura = true
    end
    
    if API.IsSpellKnown(spells.AVENGERS_SHIELD) then
        avengersShield = true
    end
    
    if API.IsSpellKnown(spells.JUDGMENT) then
        judgment = true
    end
    
    if API.IsSpellKnown(spells.HAMMER_OF_THE_RIGHTEOUS) then
        hammer = true
    end
    
    if API.IsSpellKnown(spells.CONSECRATION) then
        consecrate = true
    end
    
    if API.IsSpellKnown(spells.SHIELD_OF_THE_RIGHTEOUS) then
        shieldOfRighteous = true
    end
    
    if API.IsSpellKnown(spells.WORD_OF_GLORY) then
        wordOfGlory = true
    end
    
    if API.IsSpellKnown(spells.DIVINE_PROTECTION) then
        divineProtection = true
    end
    
    if API.IsSpellKnown(spells.ARDENT_DEFENDER) then
        ardentDefender = true
    end
    
    if API.IsSpellKnown(spells.GUARDIAN_OF_ANCIENT_KINGS) then
        guardianOfAncientKings = true
    end
    
    if API.IsSpellKnown(spells.LAY_ON_HANDS) then
        layOnHands = true
    end
    
    if API.IsSpellKnown(spells.HAMMER_OF_WRATH) then
        hammerOfWrath = true
    end
    
    if API.IsSpellKnown(spells.CRUSADER_STRIKE) then
        crusaderStrike = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_PROTECTION) then
        blessingOfProtection = true
    end
    
    if API.IsSpellKnown(spells.BLESSING_OF_SACRIFICE) then
        blessingOfSacrifice = true
    end
    
    if API.IsSpellKnown(spells.EYE_OF_TYR) then
        eyeOfTyr = true
    end
    
    if talents.hasToweringShield then
        toweringShieldActive = API.UnitHasBuff("player", buffs.TOWERING_SHIELD)
        toweringShieldStacks = select(4, API.GetBuffInfo("player", buffs.TOWERING_SHIELD)) or 0
    end
    
    if talents.hasMightyDisplacer then
        mightyDisplacer = true
        mightyDisplacerActive = API.UnitHasBuff("player", buffs.MIGHTY_DISPLACER)
        mightyDisplacerStacks = select(4, API.GetBuffInfo("player", buffs.MIGHTY_DISPLACER)) or 0
    end
    
    if talents.hasFlaringResistance then
        flaringResistanceTalent = true
        flaringResistanceActive = API.UnitHasBuff("player", buffs.FLARING_RESISTANCE)
        flaringResistanceStacks = select(4, API.GetBuffInfo("player", buffs.FLARING_RESISTANCE)) or 0
    end
    
    if talents.hasKingOfTheJungle then
        kingOfTheJungle = true
    end
    
    API.PrintDebug("Protection Paladin talents updated")
    
    return true
end

-- Update Holy Power tracking
function Protection:UpdateHolyPower()
    currentHolyPower = API.GetPlayerPower()
    return true
end

-- Update Shield of the Righteous charges
function Protection:UpdateSotRCharges()
    shieldOfTheRighteousCharges, shieldOfTheRighteousMaxCharges = API.GetSpellCharges(spells.SHIELD_OF_THE_RIGHTEOUS)
    
    -- Update Shield of the Righteous active status
    shieldOfTheRighteousActive = API.UnitHasBuff("player", buffs.SHIELD_OF_THE_RIGHTEOUS)
    if shieldOfTheRighteousActive then
        shieldOfTheRighteousEndTime = select(6, API.GetBuffInfo("player", buffs.SHIELD_OF_THE_RIGHTEOUS))
    end
    
    return true
end

-- Update health tracking
function Protection:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Protection:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update threat situation
function Protection:UpdateThreatSituation()
    -- Get current threat level for player
    local threatLevel = API.UnitThreatSituation("player")
    
    -- Convert threat level to string status
    if threatLevel == 0 then
        threatSituation = "LOW"
    elseif threatLevel == 1 then
        threatSituation = "MEDIUM"
    elseif threatLevel == 2 then
        threatSituation = "HIGH"
    elseif threatLevel == 3 then
        threatSituation = "TANK"
    else
        threatSituation = "UNKNOWN"
    end
    
    return true
end

-- Update active enemy counts
function Protection:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    activeImportantEnemies = API.GetImportantEnemyCount() or 0
    activeBossEnemies = API.GetBossEnemyCount() or 0
    return true
end

-- Check if unit is in melee range
function Protection:IsInMeleeRange(unit)
    if not unit or not API.UnitExists(unit) then
        return false
    end
    
    return API.GetUnitDistance("player", unit) <= meleeRange
end

-- Handle combat log events
function Protection:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Shield of the Righteous application
            if spellID == buffs.SHIELD_OF_THE_RIGHTEOUS then
                shieldOfTheRighteousActive = true
                shieldOfTheRighteousEndTime = select(6, API.GetBuffInfo("player", buffs.SHIELD_OF_THE_RIGHTEOUS))
                API.PrintDebug("Shield of the Righteous activated")
            end
            
            -- Consecration application
            if spellID == buffs.CONSECRATION then
                consecrationActive = true
                consecrationEndTime = select(6, API.GetBuffInfo("player", buffs.CONSECRATION))
                API.PrintDebug("Consecration activated")
            end
            
            -- Avenging Wrath application
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = true
                avengingWrathEndTime = select(6, API.GetBuffInfo("player", buffs.AVENGING_WRATH))
                API.PrintDebug("Avenging Wrath activated")
            end
            
            -- Ardent Defender application
            if spellID == buffs.ARDENT_DEFENDER then
                ardentDefenderActive = true
                ardentDefenderEndTime = select(6, API.GetBuffInfo("player", buffs.ARDENT_DEFENDER))
                API.PrintDebug("Ardent Defender activated")
            end
            
            -- Guardian of Ancient Kings application
            if spellID == buffs.GUARDIAN_OF_ANCIENT_KINGS then
                guardianOfAncientKingsActive = true
                guardianOfAncientKingsEndTime = select(6, API.GetBuffInfo("player", buffs.GUARDIAN_OF_ANCIENT_KINGS))
                API.PrintDebug("Guardian of Ancient Kings activated")
            end
            
            -- Divine Shield application
            if spellID == buffs.DIVINE_SHIELD then
                divineShieldActive = true
                divineShieldEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_SHIELD))
                API.PrintDebug("Divine Shield activated")
            end
            
            -- Sentinel application
            if spellID == buffs.SENTINEL then
                sentinelActive = true
                sentinelEndTime = select(6, API.GetBuffInfo("player", buffs.SENTINEL))
                API.PrintDebug("Sentinel activated")
            end
            
            -- Towering Shield application (Season 2 trait)
            if spellID == buffs.TOWERING_SHIELD then
                toweringShieldActive = true
                toweringShieldEndTime = select(6, API.GetBuffInfo("player", buffs.TOWERING_SHIELD))
                toweringShieldStacks = select(4, API.GetBuffInfo("player", buffs.TOWERING_SHIELD)) or 1
                API.PrintDebug("Towering Shield activated: " .. tostring(toweringShieldStacks) .. " stack(s)")
            end
            
            -- Mighty Displacer application (Season 2 trait)
            if spellID == buffs.MIGHTY_DISPLACER then
                mightyDisplacerActive = true
                mightyDisplacerEndTime = select(6, API.GetBuffInfo("player", buffs.MIGHTY_DISPLACER))
                mightyDisplacerStacks = select(4, API.GetBuffInfo("player", buffs.MIGHTY_DISPLACER)) or 1
                API.PrintDebug("Mighty Displacer activated: " .. tostring(mightyDisplacerStacks) .. " stack(s)")
            end
            
            -- Flaring Resistance application
            if spellID == buffs.FLARING_RESISTANCE then
                flaringResistanceActive = true
                flaringResistanceEndTime = select(6, API.GetBuffInfo("player", buffs.FLARING_RESISTANCE))
                flaringResistanceStacks = select(4, API.GetBuffInfo("player", buffs.FLARING_RESISTANCE)) or 1
                API.PrintDebug("Flaring Resistance activated: " .. tostring(flaringResistanceStacks) .. " stack(s)")
            end
            
            -- Divine Purpose application
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeActive = true
                divinePurposeEndTime = select(6, API.GetBuffInfo("player", buffs.DIVINE_PURPOSE))
                API.PrintDebug("Divine Purpose activated")
            end
            
            -- Forbearance application
            if spellID == debuffs.FORBEARANCE then
                lastForbearance = GetTime()
                API.PrintDebug("Forbearance applied to player")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Shield of the Righteous removal
            if spellID == buffs.SHIELD_OF_THE_RIGHTEOUS then
                shieldOfTheRighteousActive = false
                API.PrintDebug("Shield of the Righteous faded")
            end
            
            -- Consecration removal
            if spellID == buffs.CONSECRATION then
                consecrationActive = false
                API.PrintDebug("Consecration faded")
            end
            
            -- Avenging Wrath removal
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = false
                API.PrintDebug("Avenging Wrath faded")
            end
            
            -- Ardent Defender removal
            if spellID == buffs.ARDENT_DEFENDER then
                ardentDefenderActive = false
                API.PrintDebug("Ardent Defender faded")
            end
            
            -- Guardian of Ancient Kings removal
            if spellID == buffs.GUARDIAN_OF_ANCIENT_KINGS then
                guardianOfAncientKingsActive = false
                API.PrintDebug("Guardian of Ancient Kings faded")
            end
            
            -- Divine Shield removal
            if spellID == buffs.DIVINE_SHIELD then
                divineShieldActive = false
                API.PrintDebug("Divine Shield faded")
            end
            
            -- Sentinel removal
            if spellID == buffs.SENTINEL then
                sentinelActive = false
                API.PrintDebug("Sentinel faded")
            end
            
            -- Towering Shield removal
            if spellID == buffs.TOWERING_SHIELD then
                toweringShieldActive = false
                toweringShieldStacks = 0
                API.PrintDebug("Towering Shield faded")
            end
            
            -- Mighty Displacer removal
            if spellID == buffs.MIGHTY_DISPLACER then
                mightyDisplacerActive = false
                mightyDisplacerStacks = 0
                API.PrintDebug("Mighty Displacer faded")
            end
            
            -- Flaring Resistance removal
            if spellID == buffs.FLARING_RESISTANCE then
                flaringResistanceActive = false
                flaringResistanceStacks = 0
                API.PrintDebug("Flaring Resistance faded")
            end
            
            -- Divine Purpose removal
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeActive = false
                API.PrintDebug("Divine Purpose faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            if spellID == spells.AVENGERS_SHIELD then
                lastAvengersShield = GetTime()
                API.PrintDebug("Avenger's Shield cast")
            elseif spellID == spells.JUDGMENT then
                lastJudgment = GetTime()
                API.PrintDebug("Judgment cast")
            elseif spellID == spells.SHIELD_OF_THE_RIGHTEOUS then
                lastShieldOfTheRighteous = GetTime()
                API.PrintDebug("Shield of the Righteous cast")
            elseif spellID == spells.WORD_OF_GLORY then
                lastWordOfGlory = GetTime()
                API.PrintDebug("Word of Glory cast")
            elseif spellID == spells.HAMMER_OF_WRATH then
                lastHammerOfWrath = GetTime()
                API.PrintDebug("Hammer of Wrath cast")
            elseif spellID == spells.AVENGING_WRATH then
                lastAvengingWrath = GetTime()
                avengingWrathActive = true
                avengingWrathEndTime = GetTime() + AVENGING_WRATH_DURATION
                API.PrintDebug("Avenging Wrath cast")
            elseif spellID == spells.ARDENT_DEFENDER then
                lastArdentDefender = GetTime()
                ardentDefenderActive = true
                ardentDefenderEndTime = GetTime() + ARDENT_DEFENDER_DURATION
                API.PrintDebug("Ardent Defender cast")
            elseif spellID == spells.GUARDIAN_OF_ANCIENT_KINGS then
                lastGuardianOfAncientKings = GetTime()
                guardianOfAncientKingsActive = true
                guardianOfAncientKingsEndTime = GetTime() + GUARDIAN_OF_ANCIENT_KINGS_DURATION
                API.PrintDebug("Guardian of Ancient Kings cast")
            elseif spellID == spells.CONSECRATION then
                lastConsecrateTime = GetTime()
                consecrationActive = true
                consecrationEndTime = GetTime() + CONSECRATION_DURATION
                API.PrintDebug("Consecration cast")
            elseif spellID == spells.DIVINE_PROTECTION then
                lastDivineProtection = GetTime()
                API.PrintDebug("Divine Protection cast")
            elseif spellID == spells.LAY_ON_HANDS then
                lastLayOnHands = GetTime()
                API.PrintDebug("Lay on Hands cast")
            elseif spellID == spells.SENTINEL then
                lastSentinel = GetTime()
                sentinelActive = true
                sentinelEndTime = GetTime() + SENTINEL_DURATION
                API.PrintDebug("Sentinel cast")
            elseif spellID == spells.FINAL_STAND then
                lastFinalStand = GetTime()
                API.PrintDebug("Final Stand cast")
            elseif spellID == spells.DIVINE_TOLL then
                lastDivineToll = GetTime()
                divineTollActive = true
                API.PrintDebug("Divine Toll cast")
            elseif spellID == spells.MOMENT_OF_GLORY then
                lastMomentOfGlory = GetTime()
                API.PrintDebug("Moment of Glory cast")
            elseif spellID == spells.DIVINE_RESONANCE then
                lastDivineResonance = GetTime()
                API.PrintDebug("Divine Resonance cast")
            elseif spellID == spells.HAMMER_OF_JUSTICE then
                hammerOfJusticeOnCooldown = true
                API.PrintDebug("Hammer of Justice cast")
            elseif spellID == spells.BLESSING_OF_PROTECTION then
                blessingOfProtectionOnCooldown = true
                API.PrintDebug("Blessing of Protection cast")
            elseif spellID == spells.BLESSING_OF_SACRIFICE then
                blessingOfSacrificeOnCooldown = true
                API.PrintDebug("Blessing of Sacrifice cast")
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
    end
    
    return true
end

-- Main rotation function
function Protection:RunRotation()
    -- Check if we should be running Protection Paladin logic
    if API.GetActiveSpecID() ~= PROTECTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ProtectionPaladin")
    
    -- Update variables
    self:UpdateHolyPower()
    self:UpdateSotRCharges()
    self:UpdateHealth()
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
        -- If we have no aura up
        if not API.UnitHasBuff("player", spells.DEVOTION_AURA) and 
           not API.UnitHasBuff("player", spells.CRUSADER_AURA) and 
           API.CanCast(spells.DEVOTION_AURA) then
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
    
    -- Handle Shield of the Righteous usage
    if self:HandleShieldOfRighteous(settings) then
        return true
    end
    
    -- Handle Word of Glory usage
    if self:HandleWordOfGlory(settings) then
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
function Protection:HandleEmergencies(settings)
    -- Lay on Hands for self
    if layOnHands and 
       settings.defensiveSettings.useLayOnHands and
       playerHealth <= settings.defensiveSettings.layOnHandsThreshold and
       API.CanCast(spells.LAY_ON_HANDS) and
       not API.UnitHasDebuff("player", debuffs.FORBEARANCE) then
        API.CastSpellOnUnit(spells.LAY_ON_HANDS, "player")
        return true
    end
    
    -- Lay on Hands for ally
    if layOnHands and 
       settings.defensiveSettings.useLayOnHands then
        
        -- Find ally in critical condition
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) and not API.UnitHasDebuff(unit, debuffs.FORBEARANCE) then
                local unitHealth = API.GetUnitHealthPercent(unit)
                
                if unitHealth <= settings.defensiveSettings.layOnHandsAllyThreshold and API.CanCast(spells.LAY_ON_HANDS) then
                    API.CastSpellOnUnit(spells.LAY_ON_HANDS, unit)
                    return true
                end
            end
        end
    end
    
    -- Divine Shield for emergency if we're about to die
    if settings.defensiveSettings.useDivineShield and
       playerHealth <= settings.defensiveSettings.divineShieldThreshold and
       API.CanCast(spells.DIVINE_SHIELD) and
       not API.UnitHasDebuff("player", debuffs.FORBEARANCE) then
       
        -- Use with Final Stand if we have it to maintain aggro
        if finalStand and API.CanCast(spells.FINAL_STAND) then
            -- Cast Divine Shield first
            API.CastSpell(spells.DIVINE_SHIELD)
            nextCastOverride = spells.FINAL_STAND -- Queue up Final Stand
            return true
        else
            API.CastSpell(spells.DIVINE_SHIELD)
            return true
        end
    end
    
    -- Emergency Word of Glory with Divine Purpose proc
    if wordOfGlory and
       divinePurposeActive and
       playerHealth <= 35 and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    -- Emergency Shield of the Righteous
    if shieldOfRighteous and
       not shieldOfTheRighteousActive and
       playerHealth <= settings.shieldOfRighteousSettings.emergencySotRThreshold and
       (currentHolyPower >= 3 or divinePurposeActive) and
       API.CanCast(spells.SHIELD_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.SHIELD_OF_THE_RIGHTEOUS)
        return true
    end
    
    return false
end

-- Handle interrupts
function Protection:HandleInterrupts(settings)
    -- Skip if interrupt settings disabled
    if not settings.interruptSettings.useInterrupts then
        return false
    end
    
    -- Can't interrupt if nothing is in range
    if not isInMelee and not API.IsUnitInRange("target", 30) then
        return false
    end
    
    -- Use Rebuke for interrupting
    if settings.interruptSettings.useRebuke and
       API.CanCast(spells.REBUKE) and
       API.IsUnitCasting("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.REBUKE, "target")
        return true
    end
    
    -- Use Hammer of Justice as a backup interrupt
    if settings.interruptSettings.useHammerOfJustice and
       settings.interruptSettings.hammerOfJusticeMode == "Interrupt Only" and
       not hammerOfJusticeOnCooldown and
       API.CanCast(spells.HAMMER_OF_JUSTICE) and
       API.IsUnitCasting("target") and
       not API.IsUnitStunned("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.HAMMER_OF_JUSTICE, "target")
        return true
    end
    
    -- Use Hammer of Justice generally if set to on cooldown
    if settings.interruptSettings.useHammerOfJustice and
       settings.interruptSettings.hammerOfJusticeMode == "On Cooldown" and
       not hammerOfJusticeOnCooldown and
       API.CanCast(spells.HAMMER_OF_JUSTICE) and
       not API.IsUnitStunned("target") then
        API.CastSpellOnUnit(spells.HAMMER_OF_JUSTICE, "target")
        return true
    end
    
    -- Use Blinding Light for AOE interrupt if we have it
    if rightBlindingLight and
       API.CanCast(spells.BLINDING_LIGHT) and
       API.AreEnemiesCasting(8) and
       activeEnemies >= 3 then
        API.CastSpell(spells.BLINDING_LIGHT)
        return true
    end
    
    -- Break mind control on ally with Blessing of Protection
    if settings.interruptSettings.useMindControl and
       blessingOfProtection and
       not blessingOfProtectionOnCooldown and
       API.CanCast(spells.BLESSING_OF_PROTECTION) then
        
        local mindControlledAlly = API.GetMindControlledUnit()
        if mindControlledAlly then
            API.CastSpellOnUnit(spells.BLESSING_OF_PROTECTION, mindControlledAlly)
            return true
        end
    end
    
    return false
end

-- Handle defensive cooldowns
function Protection:HandleDefensives(settings)
    -- Use Guardian of Ancient Kings
    if guardianOfAncientKings and
       settings.cooldownSettings.useGuardianOfAncientKings and
       not guardianOfAncientKingsActive and
       playerHealth <= settings.cooldownSettings.guardianOfAncientKingsThreshold and
       API.CanCast(spells.GUARDIAN_OF_ANCIENT_KINGS) then
        API.CastSpell(spells.GUARDIAN_OF_ANCIENT_KINGS)
        return true
    end
    
    -- Use Ardent Defender
    if ardentDefender and
       settings.cooldownSettings.useArdentDefender and
       not ardentDefenderActive and
       playerHealth <= settings.cooldownSettings.ardentDefenderThreshold and
       API.CanCast(spells.ARDENT_DEFENDER) then
        API.CastSpell(spells.ARDENT_DEFENDER)
        return true
    end
    
    -- Use Divine Protection
    if divineProtection and
       settings.cooldownSettings.useDivineProtection and
       playerHealth <= settings.cooldownSettings.divineProtectionThreshold and
       API.CanCast(spells.DIVINE_PROTECTION) then
        API.CastSpell(spells.DIVINE_PROTECTION)
        return true
    end
    
    -- Use Sentinel
    if sentinel and
       settings.cooldownSettings.useSentinel and
       not sentinelActive and
       playerHealth <= settings.cooldownSettings.sentinelThreshold and
       API.CanCast(spells.SENTINEL) then
        API.CastSpell(spells.SENTINEL)
        return true
    end
    
    -- Use Blessing of Protection on ally
    if blessingOfProtection and
       settings.defensiveSettings.useBlessingOfProtection and
       not blessingOfProtectionOnCooldown then
        
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
    
    -- Use Blessing of Sacrifice on ally
    if blessingOfSacrifice and
       settings.defensiveSettings.useBlessingOfSacrifice and
       not blessingOfSacrificeOnCooldown and
       playerHealth > 60 then -- Only if we're reasonably healthy
        
        -- Find ally in trouble
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) and unit ~= "player" then
                local unitHealth = API.GetUnitHealthPercent(unit)
                
                if unitHealth <= settings.defensiveSettings.blessingOfSacrificeThreshold and API.CanCast(spells.BLESSING_OF_SACRIFICE) then
                    API.CastSpellOnUnit(spells.BLESSING_OF_SACRIFICE, unit)
                    return true
                end
            end
        end
    end
    
    -- Use Final Stand in emergency or with multiple adds
    if finalStand and
       settings.utilitySettings.useFinalStand and
       API.CanCast(spells.FINAL_STAND) then
        
        local shouldUseFinalStand = false
        
        if settings.utilitySettings.finalStandMode == "Emergency Only" then
            shouldUseFinalStand = playerHealth < 25
        elseif settings.utilitySettings.finalStandMode == "Multiple Adds" then
            shouldUseFinalStand = activeEnemies >= settings.utilitySettings.finalStandThreshold
        elseif settings.utilitySettings.finalStandMode == "On Cooldown" then
            shouldUseFinalStand = true
        end
        
        if shouldUseFinalStand then
            API.CastSpell(spells.FINAL_STAND)
            return true
        end
    end
    
    return false
end

-- Handle offensive cooldowns
function Protection:HandleOffensiveCooldowns(settings)
    -- Use Avenging Wrath
    if avengingWrath and
       settings.cooldownSettings.useAvengingWrath and
       not avengingWrathActive and
       API.CanCast(spells.AVENGING_WRATH) then
        
        local shouldUseAW = false
        
        if settings.cooldownSettings.avengingWrathMode == "On Cooldown" then
            shouldUseAW = true
        elseif settings.cooldownSettings.avengingWrathMode == "Multiple Enemies" then
            shouldUseAW = activeEnemies >= 3
        elseif settings.cooldownSettings.avengingWrathMode == "Boss Only" then
            shouldUseAW = activeBossEnemies > 0
        elseif settings.cooldownSettings.avengingWrathMode == "Burst Only" then
            shouldUseAW = burstModeActive
        end
        
        if shouldUseAW then
            API.CastSpell(spells.AVENGING_WRATH)
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
    
    -- Use Moment of Glory
    if momentOfGlory and API.CanCast(spells.MOMENT_OF_GLORY) then
        API.CastSpell(spells.MOMENT_OF_GLORY)
        return true
    end
    
    return false
end

-- Handle Shield of the Righteous usage
function Protection:HandleShieldOfRighteous(settings)
    -- Skip if no charges or already active
    if shieldOfTheRighteousCharges <= 0 and not divinePurposeActive then
        return false
    end
    
    -- Requirements to use Shield of the Righteous
    local canUse = (currentHolyPower >= 3 or divinePurposeActive) and API.CanCast(spells.SHIELD_OF_THE_RIGHTEOUS)
    if not canUse then
        return false
    end
    
    -- Check if we should use Shield of the Righteous
    local shouldUse = false
    
    -- Always use if specified
    if settings.shieldOfRighteousSettings.useSotROnCooldown then
        shouldUse = true
    end
    
    -- Use if not active or about to expire
    if not shieldOfTheRighteousActive or (shieldOfTheRighteousEndTime - GetTime() < 1.5) then
        shouldUse = true
    end
    
    -- If we allow overlap
    if settings.rotationSettings.sotrOverlap then
        shouldUse = true
    end
    
    -- Check if we have enough charges to spare
    if shieldOfTheRighteousCharges <= settings.shieldOfRighteousSettings.minSotRCharges and not divinePurposeActive then
        shouldUse = false
    end
    
    -- If the settings for AAC should override
    if settings.abilityControls.shieldOfTheRighteous.enabled then
        -- Check AAC conditions
        if settings.abilityControls.shieldOfTheRighteous.useDuringBurstOnly and not burstModeActive then
            shouldUse = false
        end
        
        if settings.abilityControls.shieldOfTheRighteous.minCharges > shieldOfTheRighteousCharges and not divinePurposeActive then
            shouldUse = false
        end
        
        -- If we're specifically trying to mitigate physical damage
        if settings.abilityControls.shieldOfTheRighteous.useForPhysicalDamage and API.IsFacingPhysicalDamage() then
            shouldUse = true
        end
    end
    
    -- Cast if we should use
    if shouldUse then
        API.CastSpell(spells.SHIELD_OF_THE_RIGHTEOUS)
        return true
    end
    
    return false
end

-- Handle Word of Glory usage
function Protection:HandleWordOfGlory(settings)
    -- Skip if not enough holy power
    if currentHolyPower < 3 and not divinePurposeActive then
        return false
    end
    
    -- Skip if we can't cast
    if not API.CanCast(spells.WORD_OF_GLORY) then
        return false
    end
    
    -- Check if we should prioritize SotR over WoG
    if settings.shieldOfRighteousSettings.prioritizeSotROverWoG and 
       API.CanCast(spells.SHIELD_OF_THE_RIGHTEOUS) and
       (not shieldOfTheRighteousActive or shieldOfTheRighteousEndTime - GetTime() < 2) and
       playerHealth > settings.rotationSettings.wordOfGloryThreshold + 15 then
        return false -- Skip WoG to use SotR instead
    end
    
    -- Emergency healing on self
    if playerHealth <= settings.rotationSettings.wordOfGloryThreshold then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    -- If configured to prefer self-healing
    if settings.abilityControls.wordOfGlory.preferSelfHealing and
       playerHealth <= settings.rotationSettings.wordOfGloryThreshold + 20 then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    -- Check for critically injured allies
    if not settings.abilityControls.wordOfGlory.emergencyOnly then
        -- Find ally in need
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) then
                local unitHealth = API.GetUnitHealthPercent(unit)
                
                if unitHealth <= settings.rotationSettings.wordOfGloryAllyThreshold then
                    API.CastSpellOnUnit(spells.WORD_OF_GLORY, unit)
                    return true
                end
            end
        end
    end
    
    -- If we have Divine Purpose, use Word of Glory even for less critical healing
    if divinePurposeActive then
        -- Find ally that could use healing
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) then
                local unitHealth = API.GetUnitHealthPercent(unit)
                
                if unitHealth <= settings.rotationSettings.wordOfGloryAllyThreshold + 20 then
                    API.CastSpellOnUnit(spells.WORD_OF_GLORY, unit)
                    return true
                end
            end
        end
        
        -- Use on self if everyone else is healthy, don't waste Divine Purpose
        if playerHealth < 95 then
            API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Protection:HandleAoE(settings)
    -- Maintain Consecration
    if consecrate and
       settings.rotationSettings.maintainConsecration and
       (not consecrationActive or consecrationEndTime - GetTime() < 2) and
       API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    -- Use Avenger's Shield with high priority
    if avengersShield and
       API.CanCast(spells.AVENGERS_SHIELD) and
       settings.abilityControls.avengersShield.enabled then
        API.CastSpell(spells.AVENGERS_SHIELD)
        return true
    end
    
    -- Use Blessed Hammer for AoE
    if blessedHammer and API.CanCast(spells.BLESSED_HAMMER) then
        API.CastSpell(spells.BLESSED_HAMMER)
        return true
    end
    
    -- Use Hammer of the Righteous for AoE if no Blessed Hammer
    if hammer and API.CanCast(spells.HAMMER_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.HAMMER_OF_THE_RIGHTEOUS)
        return true
    end
    
    -- Use Judgment to generate Holy Power
    if judgment and API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Use Hammer of Wrath if available (target below 20% or Avenging Wrath active)
    if hammerOfWrath and
       (targetHealth < 20 or avengingWrathActive) and
       API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    -- Use Consecration as a filler
    if consecrate and API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle single target rotation
function Protection:HandleSingleTarget(settings)
    -- Maintain Consecration
    if consecrate and
       settings.rotationSettings.maintainConsecration and
       (not consecrationActive or consecrationEndTime - GetTime() < 2) and
       API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    -- Use Avenger's Shield with high priority
    if avengersShield and
       API.CanCast(spells.AVENGERS_SHIELD) and
       settings.abilityControls.avengersShield.enabled then
        API.CastSpell(spells.AVENGERS_SHIELD)
        return true
    end
    
    -- Use Judgment to generate Holy Power
    if judgment and API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Use Hammer of Wrath if available (target below 20% or Avenging Wrath active)
    if hammerOfWrath and
       (targetHealth < 20 or avengingWrathActive) and
       API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    -- Use Blessed Hammer if talented
    if blessedHammer and API.CanCast(spells.BLESSED_HAMMER) then
        API.CastSpell(spells.BLESSED_HAMMER)
        return true
    end
    
    -- Use Hammer of the Righteous if not using Blessed Hammer
    if hammer and not blessedHammer and API.CanCast(spells.HAMMER_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.HAMMER_OF_THE_RIGHTEOUS)
        return true
    end
    
    -- Use Consecration as a filler
    if consecrate and API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    -- Use Crusader Strike as a last resort
    if crusaderStrike and API.CanCast(spells.CRUSADER_STRIKE) then
        API.CastSpell(spells.CRUSADER_STRIKE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Protection:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentHolyPower = 0
    maxHolyPower = 5
    shieldOfTheRighteousCharges = 0
    shieldOfTheRighteousMaxCharges = 0
    shieldOfTheRighteousActive = false
    shieldOfTheRighteousEndTime = 0
    consecrationActive = false
    consecrationEndTime = 0
    divineTollActive = false
    avengingWrathActive = false
    avengingWrathEndTime = 0
    ardentDefenderActive = false
    ardentDefenderEndTime = 0
    guardianOfAncientKingsActive = false
    guardianOfAncientKingsEndTime = 0
    hammerOfJusticeOnCooldown = false
    blessingOfProtectionOnCooldown = false
    blessingOfSacrificeOnCooldown = false
    divineShieldActive = false
    divineShieldEndTime = 0
    sentinelActive = false
    sentinelEndTime = 0
    divinePurposeActive = false
    divinePurposeEndTime = 0
    lastAvengersShield = 0
    lastJudgment = 0
    lastShieldOfTheRighteous = 0
    lastWordOfGlory = 0
    lastHammerOfWrath = 0
    lastAvengingWrath = 0
    lastArdentDefender = 0
    lastGuardianOfAncientKings = 0
    lastConsecrateTime = 0
    lastDivineProtection = 0
    lastLayOnHands = 0
    lastSentinel = 0
    lastFinalStand = 0
    lastDivineToll = 0
    lastMomentOfGlory = 0
    lastDivineResonance = 0
    lastForbearance = 0
    targetInRange = false
    playerHealth = 100
    targetHealth = 100
    threatSituation = "LOW"
    activeEnemies = 0
    activeImportantEnemies = 0
    activeBossEnemies = 0
    isInMelee = false
    judgmentApplied = false
    toweringShieldActive = false
    toweringShieldEndTime = 0
    toweringShieldStacks = 0
    mightyDisplacerActive = false
    mightyDisplacerEndTime = 0
    mightyDisplacerStacks = 0
    flaringResistanceActive = false
    flaringResistanceStacks = 0
    
    -- Update Shield of the Righteous charges
    self:UpdateSotRCharges()
    
    API.PrintDebug("Protection Paladin state reset on spec change")
    
    return true
end

-- Return the module for loading
return Protection