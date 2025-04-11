------------------------------------------
-- WindrunnerRotations - Guardian Druid Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Guardian = {}
-- This will be assigned to addon.Classes.Druid.Guardian when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Druid

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentRage = 0
local maxRage = 100
local ironfurActive = false
local ironfurEndTime = 0
local ironfurStacks = 0
local frenziedRegenActive = false
local frenziedRegenEndTime = 0
local frenziedRegenStacks = 0
local barkskinActive = false
local barkskinEndTime = 0
local survivalInstinctsActive = false
local survivalInstinctsEndTime = 0
local survivalInstinctsStacks = 0
local bristlingFurActive = false
local bristlingFurEndTime = 0
local incarnationActive = false
local incarnationEndTime = 0
local incapacitatingRoarActive = false
local incapacitatingRoarEndTime = 0
local berserkActive = false
local berserkEndTime = 0
local pulverizeActive = {}
local pulverizeEndTime = {}
local thrashActive = {}
local thrashEndTime = {}
local thrashStacks = {}
local moonfire = {}
local moonfireEndTime = {}
local bloodfrenzy = {}
local bloodfrenzyEndTime = {}
local rageOfTheSleeper = false
local rageOfTheSleeperEndTime = 0
local toughAsBarkskin = false
local toughAsBarkskinEndTime = 0
local galacticGuardianProc = false
local galacticGuardianEndTime = 0
local goredByActive = false
local goredByEndTime = 0
local lastMangle = 0
local lastThrash = 0
local lastMoonfire = 0
local inBearForm = false
local inCatForm = false
local inTravelForm = false
local inMoonkinForm = false
local playerHealth = 100
local playerHealthPercent = 100
local inMeleeRange = false
local thrashDuration = 15
local thrashReady = false
local mangle = false
local swipe = false
local thrash = false
local moonfire = false
local maul = false
local pulverize = false
local incarnationGuardian = false
local berserk = false
local bristlingFur = false
local galacticGuardian = false
local soulOfTheForest = false
local incarnationTalented = false
local earthwarden = false
local guardianOfElune = false
local survivalInstincts = false
local incapacitatingRoar = false
local renewSteel = false
local wrathOfNature = false
local strengthOfTheWild = false
local reinforcedFur = false
local fightingStyle = false
local bloodletting = false
local evergreen = false
local thorns = false
local grovel = false
local visceralTear = false
local regenGrowth = false
local layeredMane = false
local layeredManeTalented = false
local goryFur = false
local goryFurTalented = false
local twoForms = false
local typhoon = false
local massEntanglement = false
local ursolsVortex = false
local vineTangle = false
local ironBark = false
local leapingCharge = false
local wildCharge = false

-- Constants
local GUARDIAN_SPEC_ID = 104
local DEFAULT_AOE_THRESHOLD = 3
local IRONFUR_DURATION = 7 -- seconds
local FRENZIED_REGEN_DURATION = 3 -- seconds
local BARKSKIN_DURATION = 12 -- seconds
local SURVIVAL_INSTINCTS_DURATION = 6 -- seconds
local BRISTLING_FUR_DURATION = 8 -- seconds
local INCARNATION_DURATION = 30 -- seconds
local BERSERK_DURATION = 15 -- seconds
local INCAPACITATING_ROAR_DURATION = 3 -- seconds
local THRASH_DURATION = 15 -- seconds (base)
local PULVERIZE_DURATION = 10 -- seconds
local MOONFIRE_DURATION = 16 -- seconds (base)
local RAGE_OF_THE_SLEEPER_DURATION = 10 -- seconds
local MELEE_RANGE = 5 -- yards

-- Initialize the Guardian module
function Guardian:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Guardian Druid module initialized")
    
    return true
end

-- Register spell IDs
function Guardian:RegisterSpells()
    -- Core rotational abilities
    spells.MANGLE = 33917
    spells.THRASH = 77758
    spells.SWIPE = 213771
    spells.MOONFIRE = 8921
    spells.MAUL = 6807
    spells.PULVERIZE = 80313
    spells.IRONFUR = 192081
    spells.FRENZIED_REGENERATION = 22842
    spells.BERSERK = 50334
    spells.INCARNATION_GUARDIAN_OF_URSOC = 102558
    
    -- Core utilities and defensives
    spells.BARKSKIN = 22812
    spells.SURVIVAL_INSTINCTS = 61336
    spells.BRISTLING_FUR = 155835
    spells.INCAPACITATING_ROAR = 99
    spells.GROWL = 6795
    spells.SKULL_BASH = 106839
    spells.STAMPEDING_ROAR = 106898
    spells.REMOVE_CORRUPTION = 2782
    spells.REBIRTH = 20484
    spells.SOOTHE = 2908
    spells.HIBERNATE = 2637
    
    -- Bear form and other forms
    spells.BEAR_FORM = 5487
    spells.CAT_FORM = 768
    spells.TRAVEL_FORM = 783
    spells.MOONKIN_FORM = 197625
    
    -- Talents and passives
    spells.URSOCS_FURY = 377350
    spells.SOUL_OF_THE_FOREST = 158477
    spells.GALACTIC_GUARDIAN = 203964
    spells.GUARDIAN_OF_ELUNE = 155578
    spells.EARTHWARDEN = 203974
    spells.SURVIVAL_OF_THE_FITTEST = 203965
    spells.REND_AND_TEAR = 204053
    spells.LUNAR_BEAM = 204066
    spells.RAGE_OF_THE_SLEEPER = 200851
    spells.TOOTH_AND_CLAW = 135288
    spells.BRAMBLES = 203953
    spells.BLOOD_FRENZY = 203962
    spells.REINFORCED_FUR = 393618
    spells.GORY_FUR = 200854
    spells.LAYERED_MANE = 279552
    spells.URSINE_ADEPT = 300321
    spells.GORE = 210706
    spells.SHREDDED_ARMOR = 390772
    spells.SAVAGE_DEFENSE = 372016
    spells.MATTED_FUR = 385786
    spells.IRON_BARK = 392175
    spells.FELINE_SWIFTNESS = 131768
    spells.CENARION_WARD = 102351
    spells.WILD_CHARGE = 102401
    spells.TIGER_DASH = 252216
    spells.RENEWAL = 108238
    spells.TYPHOON = 132469
    spells.MASS_ENTANGLEMENT = 102359
    spells.URSOLS_VORTEX = 102793
    spells.NURTURING_INSTINCT = 33873
    spells.INNERVATE = 29166
    spells.FIGHTING_STYLE = 378986
    spells.BLOODLETTING = 391055
    spells.EVERGREEN = 392301
    spells.THORNS = 305497
    spells.GROVEL = 389038
    spells.VISCERAL_TEAR = 377623
    spells.VERDANT_HEART = 377779
    spells.LEAPING_CHARGE = 370846
    spells.VINE_TANGLE = 385786
    
    -- War Within Season 2 specific
    spells.RENEW_STEEL = 393996
    spells.WRATH_OF_NATURE = 393706
    spells.STRENGTH_OF_THE_WILD = 391201
    spells.REGEN_GROWTH = 393619
    spells.TWO_FORMS = 394013
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.ADAPTIVE_SWARM = 325727
    spells.CONVOKE_THE_SPIRITS = 323764
    spells.RAVENOUS_FRENZY = 323546
    spells.KINDRED_SPIRITS = 326434
    
    -- Buff IDs
    spells.IRONFUR_BUFF = 192081
    spells.FRENZIED_REGEN_BUFF = 22842
    spells.BARKSKIN_BUFF = 22812
    spells.SURVIVAL_INSTINCTS_BUFF = 61336
    spells.BRISTLING_FUR_BUFF = 155835
    spells.INCARNATION_GUARDIAN_BUFF = 102558
    spells.BERSERK_BUFF = 50334
    spells.GALACTIC_GUARDIAN_BUFF = 213708
    spells.GUARDIAN_OF_ELUNE_BUFF = 213680
    spells.EARTHWARDEN_BUFF = 203975
    spells.RAGE_OF_THE_SLEEPER_BUFF = 200851
    spells.TOOTH_AND_CLAW_BUFF = 135286
    spells.GORE_BUFF = 93622
    spells.BEAR_FORM_BUFF = 5487
    spells.CENARION_WARD_BUFF = 102351
    spells.GORY_FUR_BUFF = 201671
    spells.THORNS_BUFF = 305496
    
    -- Debuff IDs
    spells.MOONFIRE_DEBUFF = 164812
    spells.THRASH_DEBUFF = 192090
    spells.PULVERIZE_DEBUFF = 80313
    spells.INCAPACITATING_ROAR_DEBUFF = 99
    spells.TOOTH_AND_CLAW_DEBUFF = 135601
    spells.BLOOD_FRENZY_DEBUFF = 203961
    spells.SHREDDED_ARMOR_DEBUFF = 390768
    spells.VISCERAL_TEAR_DEBUFF = 377623
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.IRONFUR = spells.IRONFUR_BUFF
    buffs.FRENZIED_REGEN = spells.FRENZIED_REGEN_BUFF
    buffs.BARKSKIN = spells.BARKSKIN_BUFF
    buffs.SURVIVAL_INSTINCTS = spells.SURVIVAL_INSTINCTS_BUFF
    buffs.BRISTLING_FUR = spells.BRISTLING_FUR_BUFF
    buffs.INCARNATION_GUARDIAN = spells.INCARNATION_GUARDIAN_BUFF
    buffs.BERSERK = spells.BERSERK_BUFF
    buffs.GALACTIC_GUARDIAN = spells.GALACTIC_GUARDIAN_BUFF
    buffs.GUARDIAN_OF_ELUNE = spells.GUARDIAN_OF_ELUNE_BUFF
    buffs.EARTHWARDEN = spells.EARTHWARDEN_BUFF
    buffs.RAGE_OF_THE_SLEEPER = spells.RAGE_OF_THE_SLEEPER_BUFF
    buffs.TOOTH_AND_CLAW = spells.TOOTH_AND_CLAW_BUFF
    buffs.GORE = spells.GORE_BUFF
    buffs.BEAR_FORM = spells.BEAR_FORM_BUFF
    buffs.CENARION_WARD = spells.CENARION_WARD_BUFF
    buffs.GORY_FUR = spells.GORY_FUR_BUFF
    buffs.THORNS = spells.THORNS_BUFF
    
    debuffs.MOONFIRE = spells.MOONFIRE_DEBUFF
    debuffs.THRASH = spells.THRASH_DEBUFF
    debuffs.PULVERIZE = spells.PULVERIZE_DEBUFF
    debuffs.INCAPACITATING_ROAR = spells.INCAPACITATING_ROAR_DEBUFF
    debuffs.TOOTH_AND_CLAW = spells.TOOTH_AND_CLAW_DEBUFF
    debuffs.BLOOD_FRENZY = spells.BLOOD_FRENZY_DEBUFF
    debuffs.SHREDDED_ARMOR = spells.SHREDDED_ARMOR_DEBUFF
    debuffs.VISCERAL_TEAR = spells.VISCERAL_TEAR_DEBUFF
    
    return true
end

-- Register variables to track
function Guardian:RegisterVariables()
    -- Talent tracking
    talents.hasUrsocsFury = false
    talents.hasSoulOfTheForest = false
    talents.hasGalacticGuardian = false
    talents.hasGuardianOfElune = false
    talents.hasEarthwarden = false
    talents.hasSurvivalOfTheFittest = false
    talents.hasRendAndTear = false
    talents.hasLunarBeam = false
    talents.hasRageOfTheSleeper = false
    talents.hasToothAndClaw = false
    talents.hasBrambles = false
    talents.hasBloodFrenzy = false
    talents.hasReinforcedFur = false
    talents.hasGoryFur = false
    talents.hasLayeredMane = false
    talents.hasUrsineAdept = false
    talents.hasGore = false
    talents.hasShredderArmor = false
    talents.hasSavageDefense = false
    talents.hasMattedFur = false
    talents.hasIronBark = false
    talents.hasFelineSwiftness = false
    talents.hasCenarionWard = false
    talents.hasWildCharge = false
    talents.hasTigerDash = false
    talents.hasRenewal = false
    talents.hasTyphoon = false
    talents.hasMassEntanglement = false
    talents.hasUrsolsVortex = false
    talents.hasNurturingInstinct = false
    talents.hasInnervate = false
    talents.hasPulverize = false
    talents.hasIncarnationGuardianOfUrsoc = false
    talents.hasBerserk = false
    talents.hasBristlingFur = false
    talents.hasIncapacitatingRoar = false
    talents.hasFightingStyle = false
    talents.hasBloodletting = false
    talents.hasEvergreen = false
    talents.hasThorns = false
    talents.hasGrovel = false
    talents.hasVisceralTear = false
    talents.hasVerdantHeart = false
    talents.hasLeapingCharge = false
    talents.hasVineTangle = false
    
    -- War Within Season 2 talents
    talents.hasRenewSteel = false
    talents.hasWrathOfNature = false
    talents.hasStrengthOfTheWild = false
    talents.hasRegenGrowth = false
    talents.hasTwoForms = false
    
    -- Initialize rage
    currentRage = API.GetPlayerPower()
    
    -- Check for Bear Form
    inBearForm = API.GetShapeshiftForm() == 1 -- Bear Form is index 1
    
    -- Initialize tracking tables
    thrashActive = {}
    thrashEndTime = {}
    thrashStacks = {}
    pulverizeActive = {}
    pulverizeEndTime = {}
    moonfire = {}
    moonfireEndTime = {}
    bloodfrenzy = {}
    bloodfrenzyEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Guardian:RegisterSettings()
    ConfigRegistry:RegisterSettings("GuardianDruid", {
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
            ragePooling = {
                displayName = "Rage Pooling",
                description = "Pool rage for defensive abilities",
                type = "toggle",
                default = true
            },
            ragePoolingThreshold = {
                displayName = "Rage Pooling Threshold",
                description = "Minimum rage to maintain",
                type = "slider",
                min = 10,
                max = 80,
                default = 40
            },
            useBearForm = {
                displayName = "Use Bear Form",
                description = "Automatically use Bear Form when needed",
                type = "toggle",
                default = true
            },
            moonfireRefreshThreshold = {
                displayName = "Moonfire Refresh Threshold",
                description = "Seconds remaining to refresh Moonfire",
                type = "slider",
                min = 1,
                max = 8,
                default = 4
            },
            maulUsage = {
                displayName = "Maul Usage",
                description = "When to use Maul",
                type = "dropdown",
                options = {"Never", "On High Rage", "Offensive Only", "Always"},
                default = "On High Rage"
            },
            maulMinRage = {
                displayName = "Maul Minimum Rage",
                description = "Minimum rage to use Maul",
                type = "slider",
                min = 40,
                max = 90,
                default = 70
            },
            pulverizeEnabled = {
                displayName = "Use Pulverize",
                description = "Automatically use Pulverize when talented",
                type = "toggle",
                default = true
            },
            pulverizeThresholdStacks = {
                displayName = "Pulverize Threshold Stacks",
                description = "Minimum Thrash stacks to use Pulverize",
                type = "slider",
                min = 1,
                max = 3,
                default = 3
            }
        },
        
        defensiveSettings = {
            useIronfur = {
                displayName = "Use Ironfur",
                description = "Automatically use Ironfur",
                type = "toggle",
                default = true
            },
            ironfurMinRage = {
                displayName = "Ironfur Minimum Rage",
                description = "Minimum rage to use Ironfur",
                type = "slider",
                min = 30,
                max = 80,
                default = 40
            },
            ironfurMaxStacks = {
                displayName = "Ironfur Maximum Stacks",
                description = "Maximum stacks to maintain for Ironfur",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            },
            useFrenziedRegen = {
                displayName = "Use Frenzied Regeneration",
                description = "Automatically use Frenzied Regeneration",
                type = "toggle",
                default = true
            },
            frenziedRegenThreshold = {
                displayName = "Frenzied Regen Health Threshold",
                description = "Health percentage to use Frenzied Regeneration",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            frenziedRegenMinRage = {
                displayName = "Frenzied Regen Minimum Rage",
                description = "Minimum rage to use Frenzied Regeneration",
                type = "slider",
                min = 10,
                max = 50,
                default = 25
            },
            useBarkskin = {
                displayName = "Use Barkskin",
                description = "Automatically use Barkskin",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 20,
                max = 80,
                default = 50
            },
            useSurvivalInstincts = {
                displayName = "Use Survival Instincts",
                description = "Automatically use Survival Instincts",
                type = "toggle",
                default = true
            },
            survivalInstinctsThreshold = {
                displayName = "Survival Instincts Health Threshold",
                description = "Health percentage to use Survival Instincts",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useBristlingFur = {
                displayName = "Use Bristling Fur",
                description = "Automatically use Bristling Fur when talented",
                type = "toggle",
                default = true
            },
            bristlingFurThreshold = {
                displayName = "Bristling Fur Rage Threshold",
                description = "Maximum rage to use Bristling Fur",
                type = "slider",
                min = 10,
                max = 80,
                default = 40
            }
        },
        
        cooldownSettings = {
            useIncarnation = {
                displayName = "Use Incarnation",
                description = "Automatically use Incarnation when talented",
                type = "toggle",
                default = true
            },
            incarnationMode = {
                displayName = "Incarnation Usage",
                description = "When to use Incarnation",
                type = "dropdown",
                options = {"On Cooldown", "With Defensives", "Burst Only"},
                default = "On Cooldown"
            },
            useBerserk = {
                displayName = "Use Berserk",
                description = "Automatically use Berserk when talented",
                type = "toggle",
                default = true
            },
            berserkMode = {
                displayName = "Berserk Usage",
                description = "When to use Berserk",
                type = "dropdown",
                options = {"On Cooldown", "With Defensives", "Burst Only"},
                default = "On Cooldown"
            },
            useRageOfTheSleeper = {
                displayName = "Use Rage of the Sleeper",
                description = "Automatically use Rage of the Sleeper when talented",
                type = "toggle",
                default = true
            },
            rageOfTheSleeperMode = {
                displayName = "Rage of the Sleeper Usage",
                description = "When to use Rage of the Sleeper",
                type = "dropdown",
                options = {"On Cooldown", "With Defensives", "Burst Only"},
                default = "On Cooldown"
            },
            useLunarBeam = {
                displayName = "Use Lunar Beam",
                description = "Automatically use Lunar Beam when talented",
                type = "toggle",
                default = true
            },
            lunarBeamThreshold = {
                displayName = "Lunar Beam Health Threshold",
                description = "Health percentage to use Lunar Beam for healing",
                type = "slider",
                min = 20,
                max = 80,
                default = 70
            },
            useIncapacitatingRoar = {
                displayName = "Use Incapacitating Roar",
                description = "Automatically use Incapacitating Roar when talented",
                type = "toggle",
                default = true
            },
            incapacitatingRoarMinTargets = {
                displayName = "Incapacitating Roar Min Targets",
                description = "Minimum targets to use Incapacitating Roar",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            }
        },
        
        utilitySettings = {
            useSkullBash = {
                displayName = "Use Skull Bash",
                description = "Automatically interrupt with Skull Bash",
                type = "toggle",
                default = true
            },
            useTyphoon = {
                displayName = "Use Typhoon",
                description = "Automatically use Typhoon when talented",
                type = "toggle",
                default = true
            },
            typhoonMinTargets = {
                displayName = "Typhoon Min Targets",
                description = "Minimum targets to use Typhoon",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useMassEntanglement = {
                displayName = "Use Mass Entanglement",
                description = "Automatically use Mass Entanglement when talented",
                type = "toggle",
                default = true
            },
            massEntanglementMinTargets = {
                displayName = "Mass Entanglement Min Targets",
                description = "Minimum targets to use Mass Entanglement",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useStampedingRoar = {
                displayName = "Use Stampeding Roar",
                description = "Automatically use Stampeding Roar for movement",
                type = "toggle",
                default = true
            },
            useSoothe = {
                displayName = "Use Soothe",
                description = "Automatically use Soothe to remove enrage effects",
                type = "toggle",
                default = true
            },
            useRebirth = {
                displayName = "Use Rebirth",
                description = "Automatically use Rebirth in combat",
                type = "toggle",
                default = false
            },
            rebirthTarget = {
                displayName = "Rebirth Target",
                description = "Who to target with Rebirth",
                type = "dropdown",
                options = {"Tank", "Healer", "DPS", "Manual Only"},
                default = "Healer"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Ironfur controls
            ironfur = AAC.RegisterAbility(spells.IRONFUR, {
                enabled = true,
                useDuringBurstOnly = false,
                preferStacking = true,
                physicalDamageThreshold = 20
            }),
            
            -- Survival Instincts controls
            survivalInstincts = AAC.RegisterAbility(spells.SURVIVAL_INSTINCTS, {
                enabled = true,
                useDuringBurstOnly = false,
                minHealthPercent = 20,
                maxHealthPercent = 50
            }),
            
            -- Frenzied Regeneration controls
            frenziedRegen = AAC.RegisterAbility(spells.FRENZIED_REGENERATION, {
                enabled = true,
                useDuringBurstOnly = false,
                usePreemptively = true,
                healthThresholdOffset = 10
            })
        }
    })
    
    return true
end

-- Register for events 
function Guardian:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for rage updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "RAGE" then
            self:UpdateRage()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        end
    end)
    
    -- Register for form changes
    API.RegisterEvent("UPDATE_SHAPESHIFT_FORM", function() 
        self:UpdateShapeshiftForm() 
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
    
    -- Initial shapeshift form check
    self:UpdateShapeshiftForm()
    
    return true
end

-- Update talent information
function Guardian:UpdateTalentInfo()
    -- Check for important talents
    talents.hasUrsocsFury = API.HasTalent(spells.URSOCS_FURY)
    talents.hasSoulOfTheForest = API.HasTalent(spells.SOUL_OF_THE_FOREST)
    talents.hasGalacticGuardian = API.HasTalent(spells.GALACTIC_GUARDIAN)
    talents.hasGuardianOfElune = API.HasTalent(spells.GUARDIAN_OF_ELUNE)
    talents.hasEarthwarden = API.HasTalent(spells.EARTHWARDEN)
    talents.hasSurvivalOfTheFittest = API.HasTalent(spells.SURVIVAL_OF_THE_FITTEST)
    talents.hasRendAndTear = API.HasTalent(spells.REND_AND_TEAR)
    talents.hasLunarBeam = API.HasTalent(spells.LUNAR_BEAM)
    talents.hasRageOfTheSleeper = API.HasTalent(spells.RAGE_OF_THE_SLEEPER)
    talents.hasToothAndClaw = API.HasTalent(spells.TOOTH_AND_CLAW)
    talents.hasBrambles = API.HasTalent(spells.BRAMBLES)
    talents.hasBloodFrenzy = API.HasTalent(spells.BLOOD_FRENZY)
    talents.hasReinforcedFur = API.HasTalent(spells.REINFORCED_FUR)
    talents.hasGoryFur = API.HasTalent(spells.GORY_FUR)
    talents.hasLayeredMane = API.HasTalent(spells.LAYERED_MANE)
    talents.hasUrsineAdept = API.HasTalent(spells.URSINE_ADEPT)
    talents.hasGore = API.HasTalent(spells.GORE)
    talents.hasShredderArmor = API.HasTalent(spells.SHREDDED_ARMOR)
    talents.hasSavageDefense = API.HasTalent(spells.SAVAGE_DEFENSE)
    talents.hasMattedFur = API.HasTalent(spells.MATTED_FUR)
    talents.hasIronBark = API.HasTalent(spells.IRON_BARK)
    talents.hasFelineSwiftness = API.HasTalent(spells.FELINE_SWIFTNESS)
    talents.hasCenarionWard = API.HasTalent(spells.CENARION_WARD)
    talents.hasWildCharge = API.HasTalent(spells.WILD_CHARGE)
    talents.hasTigerDash = API.HasTalent(spells.TIGER_DASH)
    talents.hasRenewal = API.HasTalent(spells.RENEWAL)
    talents.hasTyphoon = API.HasTalent(spells.TYPHOON)
    talents.hasMassEntanglement = API.HasTalent(spells.MASS_ENTANGLEMENT)
    talents.hasUrsolsVortex = API.HasTalent(spells.URSOLS_VORTEX)
    talents.hasNurturingInstinct = API.HasTalent(spells.NURTURING_INSTINCT)
    talents.hasInnervate = API.HasTalent(spells.INNERVATE)
    talents.hasPulverize = API.HasTalent(spells.PULVERIZE)
    talents.hasIncarnationGuardianOfUrsoc = API.HasTalent(spells.INCARNATION_GUARDIAN_OF_URSOC)
    talents.hasBerserk = API.HasTalent(spells.BERSERK)
    talents.hasBristlingFur = API.HasTalent(spells.BRISTLING_FUR)
    talents.hasIncapacitatingRoar = API.HasTalent(spells.INCAPACITATING_ROAR)
    talents.hasFightingStyle = API.HasTalent(spells.FIGHTING_STYLE)
    talents.hasBloodletting = API.HasTalent(spells.BLOODLETTING)
    talents.hasEvergreen = API.HasTalent(spells.EVERGREEN)
    talents.hasThorns = API.HasTalent(spells.THORNS)
    talents.hasGrovel = API.HasTalent(spells.GROVEL)
    talents.hasVisceralTear = API.HasTalent(spells.VISCERAL_TEAR)
    talents.hasVerdantHeart = API.HasTalent(spells.VERDANT_HEART)
    talents.hasLeapingCharge = API.HasTalent(spells.LEAPING_CHARGE)
    talents.hasVineTangle = API.HasTalent(spells.VINE_TANGLE)
    
    -- War Within Season 2 talents
    talents.hasRenewSteel = API.HasTalent(spells.RENEW_STEEL)
    talents.hasWrathOfNature = API.HasTalent(spells.WRATH_OF_NATURE)
    talents.hasStrengthOfTheWild = API.HasTalent(spells.STRENGTH_OF_THE_WILD)
    talents.hasRegenGrowth = API.HasTalent(spells.REGEN_GROWTH)
    talents.hasTwoForms = API.HasTalent(spells.TWO_FORMS)
    
    -- Set specialized variables based on talents
    if API.IsSpellKnown(spells.MANGLE) then
        mangle = true
    end
    
    if API.IsSpellKnown(spells.SWIPE) then
        swipe = true
    end
    
    if API.IsSpellKnown(spells.THRASH) then
        thrash = true
    end
    
    if API.IsSpellKnown(spells.MOONFIRE) then
        moonfire = true
    end
    
    if API.IsSpellKnown(spells.MAUL) then
        maul = true
    end
    
    if talents.hasPulverize then
        pulverize = true
    end
    
    if talents.hasIncarnationGuardianOfUrsoc then
        incarnationGuardian = true
        incarnationTalented = true
    end
    
    if talents.hasBerserk then
        berserk = true
    end
    
    if talents.hasBristlingFur then
        bristlingFur = true
    end
    
    if talents.hasGalacticGuardian then
        galacticGuardian = true
    end
    
    if talents.hasSoulOfTheForest then
        soulOfTheForest = true
    end
    
    if talents.hasEarthwarden then
        earthwarden = true
    end
    
    if talents.hasGuardianOfElune then
        guardianOfElune = true
    end
    
    if API.IsSpellKnown(spells.SURVIVAL_INSTINCTS) then
        survivalInstincts = true
    end
    
    if talents.hasIncapacitatingRoar then
        incapacitatingRoar = true
    end
    
    if talents.hasRenewSteel then
        renewSteel = true
    end
    
    if talents.hasWrathOfNature then
        wrathOfNature = true
    end
    
    if talents.hasStrengthOfTheWild then
        strengthOfTheWild = true
    end
    
    if talents.hasReinforcedFur then
        reinforcedFur = true
    end
    
    if talents.hasFightingStyle then
        fightingStyle = true
    end
    
    if talents.hasBloodletting then
        bloodletting = true
    end
    
    if talents.hasEvergreen then
        evergreen = true
    end
    
    if talents.hasThorns then
        thorns = true
    end
    
    if talents.hasGrovel then
        grovel = true
    end
    
    if talents.hasVisceralTear then
        visceralTear = true
    end
    
    if talents.hasRegenGrowth then
        regenGrowth = true
    end
    
    if talents.hasLayeredMane then
        layeredMane = true
        layeredManeTalented = true
    end
    
    if talents.hasGoryFur then
        goryFur = true
        goryFurTalented = true
    end
    
    if talents.hasTwoForms then
        twoForms = true
    end
    
    if talents.hasTyphoon then
        typhoon = true
    end
    
    if talents.hasMassEntanglement then
        massEntanglement = true
    end
    
    if talents.hasUrsolsVortex then
        ursolsVortex = true
    end
    
    if talents.hasVineTangle then
        vineTangle = true
    end
    
    if talents.hasIronBark then
        ironBark = true
    end
    
    if talents.hasLeapingCharge then
        leapingCharge = true
    end
    
    if talents.hasWildCharge then
        wildCharge = true
    end
    
    API.PrintDebug("Guardian Druid talents updated")
    
    return true
end

-- Update rage tracking
function Guardian:UpdateRage()
    currentRage = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Guardian:UpdateHealth()
    local previousHealth = playerHealth
    playerHealth = API.GetPlayerHealth()
    playerHealthPercent = API.GetPlayerHealthPercent()
    return true
end

-- Update shapeshift form
function Guardian:UpdateShapeshiftForm()
    local form = API.GetShapeshiftForm()
    
    inBearForm = (form == 1) -- Bear Form is index 1
    inCatForm = (form == 2) -- Cat Form is index 2
    inTravelForm = (form == 3) -- Travel Form is index 3
    inMoonkinForm = (form == 4) -- Moonkin Form is index 4 (if talented)
    
    return true
end

-- Update target data
function Guardian:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Thrash
        local thrashInfo = API.GetDebuffInfo(targetGUID, debuffs.THRASH)
        if thrashInfo then
            thrashActive[targetGUID] = true
            thrashEndTime[targetGUID] = select(6, thrashInfo)
            thrashStacks[targetGUID] = select(4, thrashInfo) or 1
        else
            thrashActive[targetGUID] = false
            thrashEndTime[targetGUID] = 0
            thrashStacks[targetGUID] = 0
        end
        
        -- Check for Pulverize
        if pulverize then
            local pulverizeInfo = API.GetDebuffInfo(targetGUID, debuffs.PULVERIZE)
            if pulverizeInfo then
                pulverizeActive[targetGUID] = true
                pulverizeEndTime[targetGUID] = select(6, pulverizeInfo)
            else
                pulverizeActive[targetGUID] = false
                pulverizeEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Moonfire
        local moonfireInfo = API.GetDebuffInfo(targetGUID, debuffs.MOONFIRE)
        if moonfireInfo then
            moonfire[targetGUID] = true
            moonfireEndTime[targetGUID] = select(6, moonfireInfo)
        else
            moonfire[targetGUID] = false
            moonfireEndTime[targetGUID] = 0
        end
        
        -- Check for Blood Frenzy
        if talents.hasBloodFrenzy then
            local bloodfrenzyInfo = API.GetDebuffInfo(targetGUID, debuffs.BLOOD_FRENZY)
            if bloodfrenzyInfo then
                bloodfrenzy[targetGUID] = true
                bloodfrenzyEndTime[targetGUID] = select(6, bloodfrenzyInfo)
            else
                bloodfrenzy[targetGUID] = false
                bloodfrenzyEndTime[targetGUID] = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Thrash radius
    
    -- Check if Thrash is ready (for special optimization with charges etc)
    thrashReady = API.GetSpellCooldown(spells.THRASH) == 0
    
    return true
end

-- Handle combat log events
function Guardian:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Ironfur
            if spellID == buffs.IRONFUR then
                ironfurActive = true
                ironfurStacks = select(4, API.GetBuffInfo("player", buffs.IRONFUR)) or 1
                ironfurEndTime = select(6, API.GetBuffInfo("player", buffs.IRONFUR))
                API.PrintDebug("Ironfur activated: " .. tostring(ironfurStacks) .. " stacks")
            end
            
            -- Track Frenzied Regeneration
            if spellID == buffs.FRENZIED_REGEN then
                frenziedRegenActive = true
                frenziedRegenStacks = select(4, API.GetBuffInfo("player", buffs.FRENZIED_REGEN)) or 1
                frenziedRegenEndTime = GetTime() + FRENZIED_REGEN_DURATION
                API.PrintDebug("Frenzied Regeneration activated")
            end
            
            -- Track Barkskin
            if spellID == buffs.BARKSKIN then
                barkskinActive = true
                barkskinEndTime = GetTime() + BARKSKIN_DURATION
                API.PrintDebug("Barkskin activated")
            end
            
            -- Track Survival Instincts
            if spellID == buffs.SURVIVAL_INSTINCTS then
                survivalInstinctsActive = true
                survivalInstinctsStacks = select(4, API.GetBuffInfo("player", buffs.SURVIVAL_INSTINCTS)) or 1
                survivalInstinctsEndTime = GetTime() + SURVIVAL_INSTINCTS_DURATION
                API.PrintDebug("Survival Instincts activated")
            end
            
            -- Track Bristling Fur
            if spellID == buffs.BRISTLING_FUR then
                bristlingFurActive = true
                bristlingFurEndTime = GetTime() + BRISTLING_FUR_DURATION
                API.PrintDebug("Bristling Fur activated")
            end
            
            -- Track Incarnation: Guardian of Ursoc
            if spellID == buffs.INCARNATION_GUARDIAN then
                incarnationActive = true
                incarnationEndTime = GetTime() + INCARNATION_DURATION
                API.PrintDebug("Incarnation: Guardian of Ursoc activated")
            end
            
            -- Track Berserk
            if spellID == buffs.BERSERK then
                berserkActive = true
                berserkEndTime = GetTime() + BERSERK_DURATION
                API.PrintDebug("Berserk activated")
            end
            
            -- Track Galactic Guardian proc
            if spellID == buffs.GALACTIC_GUARDIAN then
                galacticGuardianProc = true
                galacticGuardianEndTime = select(6, API.GetBuffInfo("player", buffs.GALACTIC_GUARDIAN))
                API.PrintDebug("Galactic Guardian proc activated")
            end
            
            -- Track Guardian of Elune
            if spellID == buffs.GUARDIAN_OF_ELUNE then
                API.PrintDebug("Guardian of Elune activated")
            end
            
            -- Track Earthwarden
            if spellID == buffs.EARTHWARDEN then
                API.PrintDebug("Earthwarden activated")
            end
            
            -- Track Rage of the Sleeper
            if spellID == buffs.RAGE_OF_THE_SLEEPER then
                rageOfTheSleeper = true
                rageOfTheSleeperEndTime = GetTime() + RAGE_OF_THE_SLEEPER_DURATION
                API.PrintDebug("Rage of the Sleeper activated")
            end
            
            -- Track Gore proc
            if spellID == buffs.GORE then
                API.PrintDebug("Gore proc activated")
            end
            
            -- Track Gory Fur proc
            if spellID == buffs.GORY_FUR then
                API.PrintDebug("Gory Fur activated")
            end
            
            -- Track Thorns
            if spellID == buffs.THORNS then
                API.PrintDebug("Thorns activated")
            end
        end
        
        -- Track debuff applications
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Thrash
            if spellID == debuffs.THRASH then
                thrashActive[destGUID] = true
                thrashEndTime[destGUID] = GetTime() + THRASH_DURATION
                thrashStacks[destGUID] = select(4, API.GetDebuffInfo(destGUID, debuffs.THRASH)) or 1
                API.PrintDebug("Thrash applied to " .. destName .. " (" .. tostring(thrashStacks[destGUID]) .. " stacks)")
            end
            
            -- Track Pulverize
            if spellID == debuffs.PULVERIZE then
                pulverizeActive[destGUID] = true
                pulverizeEndTime[destGUID] = GetTime() + PULVERIZE_DURATION
                API.PrintDebug("Pulverize applied to " .. destName)
            end
            
            -- Track Moonfire
            if spellID == debuffs.MOONFIRE then
                moonfire[destGUID] = true
                moonfireEndTime[destGUID] = GetTime() + MOONFIRE_DURATION
                API.PrintDebug("Moonfire applied to " .. destName)
            end
            
            -- Track Incapacitating Roar
            if spellID == debuffs.INCAPACITATING_ROAR then
                incapacitatingRoarActive = true
                incapacitatingRoarEndTime = GetTime() + INCAPACITATING_ROAR_DURATION
                API.PrintDebug("Incapacitating Roar applied to " .. destName)
            end
            
            -- Track Blood Frenzy
            if spellID == debuffs.BLOOD_FRENZY then
                bloodfrenzy[destGUID] = true
                bloodfrenzyEndTime[destGUID] = select(6, API.GetDebuffInfo(destGUID, debuffs.BLOOD_FRENZY))
                API.PrintDebug("Blood Frenzy applied to " .. destName)
            end
            
            -- Track Visceral Tear
            if spellID == debuffs.VISCERAL_TEAR then
                API.PrintDebug("Visceral Tear applied to " .. destName)
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Ironfur
            if spellID == buffs.IRONFUR then
                ironfurActive = false
                ironfurStacks = 0
                API.PrintDebug("Ironfur faded")
            end
            
            -- Track Frenzied Regeneration
            if spellID == buffs.FRENZIED_REGEN then
                frenziedRegenActive = false
                frenziedRegenStacks = 0
                API.PrintDebug("Frenzied Regeneration faded")
            end
            
            -- Track Barkskin
            if spellID == buffs.BARKSKIN then
                barkskinActive = false
                API.PrintDebug("Barkskin faded")
            end
            
            -- Track Survival Instincts
            if spellID == buffs.SURVIVAL_INSTINCTS then
                survivalInstinctsActive = false
                survivalInstinctsStacks = 0
                API.PrintDebug("Survival Instincts faded")
            end
            
            -- Track Bristling Fur
            if spellID == buffs.BRISTLING_FUR then
                bristlingFurActive = false
                API.PrintDebug("Bristling Fur faded")
            end
            
            -- Track Incarnation: Guardian of Ursoc
            if spellID == buffs.INCARNATION_GUARDIAN then
                incarnationActive = false
                API.PrintDebug("Incarnation: Guardian of Ursoc faded")
            end
            
            -- Track Berserk
            if spellID == buffs.BERSERK then
                berserkActive = false
                API.PrintDebug("Berserk faded")
            end
            
            -- Track Galactic Guardian proc
            if spellID == buffs.GALACTIC_GUARDIAN then
                galacticGuardianProc = false
                API.PrintDebug("Galactic Guardian proc consumed")
            end
            
            -- Track Rage of the Sleeper
            if spellID == buffs.RAGE_OF_THE_SLEEPER then
                rageOfTheSleeper = false
                API.PrintDebug("Rage of the Sleeper faded")
            end
        end
        
        -- Track debuff removals
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Thrash
            if spellID == debuffs.THRASH and thrashActive[destGUID] then
                thrashActive[destGUID] = false
                thrashStacks[destGUID] = 0
                API.PrintDebug("Thrash faded from " .. destName)
            end
            
            -- Track Pulverize
            if spellID == debuffs.PULVERIZE and pulverizeActive[destGUID] then
                pulverizeActive[destGUID] = false
                API.PrintDebug("Pulverize faded from " .. destName)
            end
            
            -- Track Moonfire
            if spellID == debuffs.MOONFIRE and moonfire[destGUID] then
                moonfire[destGUID] = false
                API.PrintDebug("Moonfire faded from " .. destName)
            end
            
            -- Track Incapacitating Roar
            if spellID == debuffs.INCAPACITATING_ROAR then
                incapacitatingRoarActive = false
                API.PrintDebug("Incapacitating Roar faded from " .. destName)
            end
            
            -- Track Blood Frenzy
            if spellID == debuffs.BLOOD_FRENZY and bloodfrenzy[destGUID] then
                bloodfrenzy[destGUID] = false
                API.PrintDebug("Blood Frenzy faded from " .. destName)
            end
        end
    end
    
    -- Track Ironfur stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.IRONFUR and destGUID == API.GetPlayerGUID() then
        ironfurStacks = select(4, API.GetBuffInfo("player", buffs.IRONFUR)) or 0
        ironfurEndTime = select(6, API.GetBuffInfo("player", buffs.IRONFUR))
        API.PrintDebug("Ironfur stacks: " .. tostring(ironfurStacks))
    end
    
    -- Track Frenzied Regeneration stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FRENZIED_REGEN and destGUID == API.GetPlayerGUID() then
        frenziedRegenStacks = select(4, API.GetBuffInfo("player", buffs.FRENZIED_REGEN)) or 0
        API.PrintDebug("Frenzied Regeneration stacks: " .. tostring(frenziedRegenStacks))
    end
    
    -- Track Survival Instincts stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SURVIVAL_INSTINCTS and destGUID == API.GetPlayerGUID() then
        survivalInstinctsStacks = select(4, API.GetBuffInfo("player", buffs.SURVIVAL_INSTINCTS)) or 0
        API.PrintDebug("Survival Instincts stacks: " .. tostring(survivalInstinctsStacks))
    end
    
    -- Track Thrash stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == debuffs.THRASH then
        thrashStacks[destGUID] = select(4, API.GetDebuffInfo(destGUID, debuffs.THRASH)) or 0
        API.PrintDebug("Thrash stacks on " .. destName .. ": " .. tostring(thrashStacks[destGUID]))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.MANGLE then
                lastMangle = GetTime()
                API.PrintDebug("Mangle cast")
            elseif spellID == spells.THRASH then
                lastThrash = GetTime()
                API.PrintDebug("Thrash cast")
            elseif spellID == spells.MOONFIRE then
                lastMoonfire = GetTime()
                API.PrintDebug("Moonfire cast")
            elseif spellID == spells.MAUL then
                API.PrintDebug("Maul cast")
            elseif spellID == spells.PULVERIZE then
                -- Thrash stacks are consumed on Pulverize, update tracking
                local targetGUID = API.GetTargetGUID()
                if targetGUID then
                    thrashStacks[targetGUID] = 0
                    API.PrintDebug("Pulverize cast, consumed Thrash stacks")
                end
            elseif spellID == spells.IRONFUR then
                ironfurActive = true
                ironfurStacks = (ironfurStacks or 0) + 1
                ironfurEndTime = GetTime() + IRONFUR_DURATION
                API.PrintDebug("Ironfur cast, stacks: " .. tostring(ironfurStacks))
            elseif spellID == spells.FRENZIED_REGENERATION then
                frenziedRegenActive = true
                frenziedRegenStacks = (frenziedRegenStacks or 0) + 1
                frenziedRegenEndTime = GetTime() + FRENZIED_REGEN_DURATION
                API.PrintDebug("Frenzied Regeneration cast")
            elseif spellID == spells.BARKSKIN then
                barkskinActive = true
                barkskinEndTime = GetTime() + BARKSKIN_DURATION
                API.PrintDebug("Barkskin cast")
            elseif spellID == spells.SURVIVAL_INSTINCTS then
                survivalInstinctsActive = true
                survivalInstinctsStacks = (survivalInstinctsStacks or 0) + 1
                survivalInstinctsEndTime = GetTime() + SURVIVAL_INSTINCTS_DURATION
                API.PrintDebug("Survival Instincts cast")
            elseif spellID == spells.BRISTLING_FUR then
                bristlingFurActive = true
                bristlingFurEndTime = GetTime() + BRISTLING_FUR_DURATION
                API.PrintDebug("Bristling Fur cast")
            elseif spellID == spells.INCARNATION_GUARDIAN_OF_URSOC then
                incarnationActive = true
                incarnationEndTime = GetTime() + INCARNATION_DURATION
                API.PrintDebug("Incarnation: Guardian of Ursoc cast")
            elseif spellID == spells.BERSERK then
                berserkActive = true
                berserkEndTime = GetTime() + BERSERK_DURATION
                API.PrintDebug("Berserk cast")
            elseif spellID == spells.INCAPACITATING_ROAR then
                incapacitatingRoarActive = true
                incapacitatingRoarEndTime = GetTime() + INCAPACITATING_ROAR_DURATION
                API.PrintDebug("Incapacitating Roar cast")
            elseif spellID == spells.RAGE_OF_THE_SLEEPER then
                rageOfTheSleeper = true
                rageOfTheSleeperEndTime = GetTime() + RAGE_OF_THE_SLEEPER_DURATION
                API.PrintDebug("Rage of the Sleeper cast")
            end
        end
    end
    
    return true
end

-- Main rotation function
function Guardian:RunRotation()
    -- Check if we should be running Guardian Druid logic
    if API.GetActiveSpecID() ~= GUARDIAN_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("GuardianDruid")
    
    -- Update variables
    self:UpdateRage()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Make sure we're in Bear Form for tanking
    if settings.rotationSettings.useBearForm and not inBearForm and API.CanCast(spells.BEAR_FORM) then
        API.CastSpell(spells.BEAR_FORM)
        return true
    end
    
    -- Skip if not in Bear Form
    if not inBearForm then
        return false
    end
    
    -- Handle interrupts
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Skip if not in melee range
    if not inMeleeRange then
        -- Handle ranged abilities if not in melee range
        return self:HandleRangedAbilities(settings)
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
function Guardian:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.SKULL_BASH) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.SKULL_BASH)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Guardian:HandleDefensives(settings)
    -- Calculate incoming damage over the next few seconds
    local incomingDamage = API.GetIncomingDamage(4) -- Check damage in next 4 seconds
    
    -- Use Barkskin
    if settings.defensiveSettings.useBarkskin and
       not barkskinActive and
       playerHealthPercent <= settings.defensiveSettings.barkskinThreshold and
       API.CanCast(spells.BARKSKIN) then
        API.CastSpell(spells.BARKSKIN)
        return true
    end
    
    -- Use Survival Instincts
    if survivalInstincts and
       settings.defensiveSettings.useSurvivalInstincts and
       not survivalInstinctsActive and
       settings.abilityControls.survivalInstincts.enabled and
       playerHealthPercent <= settings.defensiveSettings.survivalInstinctsThreshold and
       API.CanCast(spells.SURVIVAL_INSTINCTS) then
        
        -- Check ability control settings
        if playerHealthPercent <= settings.abilityControls.survivalInstincts.minHealthPercent or
           playerHealthPercent >= settings.abilityControls.survivalInstincts.maxHealthPercent then
            API.CastSpell(spells.SURVIVAL_INSTINCTS)
            return true
        end
    end
    
    -- Use Frenzied Regeneration
    if settings.defensiveSettings.useFrenziedRegen and
       settings.abilityControls.frenziedRegen.enabled and
       playerHealthPercent <= settings.defensiveSettings.frenziedRegenThreshold and
       currentRage >= settings.defensiveSettings.frenziedRegenMinRage and
       API.CanCast(spells.FRENZIED_REGENERATION) then
        
        -- Apply offset if using preemptively
        local effectiveThreshold = settings.defensiveSettings.frenziedRegenThreshold
        if settings.abilityControls.frenziedRegen.usePreemptively then
            effectiveThreshold = effectiveThreshold + settings.abilityControls.frenziedRegen.healthThresholdOffset
        end
        
        if playerHealthPercent <= effectiveThreshold then
            API.CastSpell(spells.FRENZIED_REGENERATION)
            return true
        end
    end
    
    -- Use Ironfur
    if settings.defensiveSettings.useIronfur and
       settings.abilityControls.ironfur.enabled and
       ironfurStacks < settings.defensiveSettings.ironfurMaxStacks and
       currentRage >= settings.defensiveSettings.ironfurMinRage and
       API.CanCast(spells.IRONFUR) then
        
        -- Check whether to stack Ironfur
        if ironfurStacks > 0 and not settings.abilityControls.ironfur.preferStacking then
            -- Don't stack if we don't want to
            return false
        end
        
        if incomingDamage >= settings.abilityControls.ironfur.physicalDamageThreshold or
           API.IsFacingPhysicalDamage() then
            API.CastSpell(spells.IRONFUR)
            return true
        end
    end
    
    -- Use Bristling Fur
    if bristlingFur and
       settings.defensiveSettings.useBristlingFur and
       not bristlingFurActive and
       currentRage <= settings.defensiveSettings.bristlingFurThreshold and
       API.CanCast(spells.BRISTLING_FUR) then
        API.CastSpell(spells.BRISTLING_FUR)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Guardian:HandleRangedAbilities(settings)
    -- Use Moonfire with Galactic Guardian proc
    if moonfire and
       galacticGuardianProc and
       API.CanCast(spells.MOONFIRE) then
        API.CastSpell(spells.MOONFIRE)
        return true
    end
    
    -- Use regular Moonfire if not in melee range
    if moonfire and API.CanCast(spells.MOONFIRE) then
        -- Get target GUID
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and (not moonfire[targetGUID] or 
                          (moonfire[targetGUID] and 
                           moonfireEndTime[targetGUID] - GetTime() < settings.rotationSettings.moonfireRefreshThreshold)) then
            API.CastSpell(spells.MOONFIRE)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Guardian:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Incarnation: Guardian of Ursoc
    if incarnationGuardian and
       settings.cooldownSettings.useIncarnation and
       not incarnationActive and
       API.CanCast(spells.INCARNATION_GUARDIAN_OF_URSOC) then
        
        local shouldUseIncarnation = false
        
        if settings.cooldownSettings.incarnationMode == "On Cooldown" then
            shouldUseIncarnation = true
        elseif settings.cooldownSettings.incarnationMode == "With Defensives" then
            shouldUseIncarnation = barkskinActive or survivalInstinctsActive
        elseif settings.cooldownSettings.incarnationMode == "Burst Only" then
            shouldUseIncarnation = burstModeActive
        end
        
        if shouldUseIncarnation then
            API.CastSpell(spells.INCARNATION_GUARDIAN_OF_URSOC)
            return true
        end
    end
    
    -- Use Berserk
    if berserk and
       settings.cooldownSettings.useBerserk and
       not berserkActive and
       API.CanCast(spells.BERSERK) then
        
        local shouldUseBerserk = false
        
        if settings.cooldownSettings.berserkMode == "On Cooldown" then
            shouldUseBerserk = true
        elseif settings.cooldownSettings.berserkMode == "With Defensives" then
            shouldUseBerserk = barkskinActive or survivalInstinctsActive
        elseif settings.cooldownSettings.berserkMode == "Burst Only" then
            shouldUseBerserk = burstModeActive
        end
        
        if shouldUseBerserk then
            API.CastSpell(spells.BERSERK)
            return true
        end
    end
    
    -- Use Rage of the Sleeper
    if talents.hasRageOfTheSleeper and
       settings.cooldownSettings.useRageOfTheSleeper and
       not rageOfTheSleeper and
       API.CanCast(spells.RAGE_OF_THE_SLEEPER) then
        
        local shouldUseRageOfTheSleeper = false
        
        if settings.cooldownSettings.rageOfTheSleeperMode == "On Cooldown" then
            shouldUseRageOfTheSleeper = true
        elseif settings.cooldownSettings.rageOfTheSleeperMode == "With Defensives" then
            shouldUseRageOfTheSleeper = barkskinActive or survivalInstinctsActive
        elseif settings.cooldownSettings.rageOfTheSleeperMode == "Burst Only" then
            shouldUseRageOfTheSleeper = burstModeActive
        end
        
        if shouldUseRageOfTheSleeper then
            API.CastSpell(spells.RAGE_OF_THE_SLEEPER)
            return true
        end
    end
    
    -- Use Incapacitating Roar
    if incapacitatingRoar and
       settings.cooldownSettings.useIncapacitatingRoar and
       currentAoETargets >= settings.cooldownSettings.incapacitatingRoarMinTargets and
       API.CanCast(spells.INCAPACITATING_ROAR) then
        API.CastSpell(spells.INCAPACITATING_ROAR)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Guardian:HandleAoERotation(settings)
    -- Use Thrash first for AoE damage
    if thrash and thrashReady and API.CanCast(spells.THRASH) then
        API.CastSpell(spells.THRASH)
        return true
    end
    
    -- Use Mangle if available
    if mangle and API.CanCast(spells.MANGLE) then
        API.CastSpell(spells.MANGLE)
        return true
    end
    
    -- Use Moonfire with Galactic Guardian proc
    if moonfire and
       galacticGuardianProc and
       API.CanCast(spells.MOONFIRE) then
        API.CastSpell(spells.MOONFIRE)
        return true
    end
    
    -- Use Swipe for AoE damage
    if swipe and API.CanCast(spells.SWIPE) then
        API.CastSpell(spells.SWIPE)
        return true
    end
    
    -- Use Pulverize if target has 3 stacks of Thrash
    if pulverize and
       settings.rotationSettings.pulverizeEnabled then
        
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and
           thrashStacks[targetGUID] and
           thrashStacks[targetGUID] >= settings.rotationSettings.pulverizeThresholdStacks and
           API.CanCast(spells.PULVERIZE) then
            API.CastSpell(spells.PULVERIZE)
            return true
        end
    end
    
    -- Use Maul if we have excess rage and settings allow
    if maul and
       currentRage >= settings.rotationSettings.maulMinRage and
       API.CanCast(spells.MAUL) then
        
        local shouldUseMaul = false
        
        if settings.rotationSettings.maulUsage == "Always" then
            shouldUseMaul = true
        elseif settings.rotationSettings.maulUsage == "On High Rage" then
            shouldUseMaul = currentRage > settings.rotationSettings.maulMinRage
        elseif settings.rotationSettings.maulUsage == "Offensive Only" then
            shouldUseMaul = not API.IsFacingPhysicalDamage() and ironfurStacks >= 1
        end
        
        if shouldUseMaul and
           (not settings.rotationSettings.ragePooling or
            currentRage > settings.rotationSettings.ragePoolingThreshold) then
            API.CastSpell(spells.MAUL)
            return true
        end
    end
    
    return false
end

-- Handle Single Target rotation
function Guardian:HandleSingleTargetRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Use Mangle first for rage generation
    if mangle and API.CanCast(spells.MANGLE) then
        API.CastSpell(spells.MANGLE)
        return true
    end
    
    -- Use Thrash to apply bleed and build up stacks
    if thrash and thrashReady and API.CanCast(spells.THRASH) then
        API.CastSpell(spells.THRASH)
        return true
    end
    
    -- Use Moonfire with Galactic Guardian proc
    if moonfire and
       galacticGuardianProc and
       API.CanCast(spells.MOONFIRE) then
        API.CastSpell(spells.MOONFIRE)
        return true
    end
    
    -- Maintain Moonfire
    if moonfire and API.CanCast(spells.MOONFIRE) then
        if targetGUID and (not moonfire[targetGUID] or 
                          (moonfire[targetGUID] and 
                           moonfireEndTime[targetGUID] - GetTime() < settings.rotationSettings.moonfireRefreshThreshold)) then
            API.CastSpell(spells.MOONFIRE)
            return true
        end
    end
    
    -- Use Pulverize if target has 3 stacks of Thrash
    if pulverize and
       settings.rotationSettings.pulverizeEnabled then
        
        if targetGUID and
           thrashStacks[targetGUID] and
           thrashStacks[targetGUID] >= settings.rotationSettings.pulverizeThresholdStacks and
           API.CanCast(spells.PULVERIZE) then
            API.CastSpell(spells.PULVERIZE)
            return true
        end
    end
    
    -- Use Maul if we have excess rage and settings allow
    if maul and
       currentRage >= settings.rotationSettings.maulMinRage and
       API.CanCast(spells.MAUL) then
        
        local shouldUseMaul = false
        
        if settings.rotationSettings.maulUsage == "Always" then
            shouldUseMaul = true
        elseif settings.rotationSettings.maulUsage == "On High Rage" then
            shouldUseMaul = currentRage > settings.rotationSettings.maulMinRage
        elseif settings.rotationSettings.maulUsage == "Offensive Only" then
            shouldUseMaul = not API.IsFacingPhysicalDamage() and ironfurStacks >= 1
        end
        
        if shouldUseMaul and
           (not settings.rotationSettings.ragePooling or
            currentRage > settings.rotationSettings.ragePoolingThreshold) then
            API.CastSpell(spells.MAUL)
            return true
        end
    end
    
    -- Use Swipe as a filler
    if swipe and API.CanCast(spells.SWIPE) then
        API.CastSpell(spells.SWIPE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Guardian:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentRage = 0
    maxRage = 100
    ironfurActive = false
    ironfurEndTime = 0
    ironfurStacks = 0
    frenziedRegenActive = false
    frenziedRegenEndTime = 0
    frenziedRegenStacks = 0
    barkskinActive = false
    barkskinEndTime = 0
    survivalInstinctsActive = false
    survivalInstinctsEndTime = 0
    survivalInstinctsStacks = 0
    bristlingFurActive = false
    bristlingFurEndTime = 0
    incarnationActive = false
    incarnationEndTime = 0
    incapacitatingRoarActive = false
    incapacitatingRoarEndTime = 0
    berserkActive = false
    berserkEndTime = 0
    pulverizeActive = {}
    pulverizeEndTime = {}
    thrashActive = {}
    thrashEndTime = {}
    thrashStacks = {}
    moonfire = {}
    moonfireEndTime = {}
    bloodfrenzy = {}
    bloodfrenzyEndTime = {}
    rageOfTheSleeper = false
    rageOfTheSleeperEndTime = 0
    toughAsBarkskin = false
    toughAsBarkskinEndTime = 0
    galacticGuardianProc = false
    galacticGuardianEndTime = 0
    goredByActive = false
    goredByEndTime = 0
    lastMangle = 0
    lastThrash = 0
    lastMoonfire = 0
    inBearForm = false
    inCatForm = false
    inTravelForm = false
    inMoonkinForm = false
    playerHealth = 100
    playerHealthPercent = 100
    inMeleeRange = false
    thrashDuration = 15
    thrashReady = false
    mangle = false
    swipe = false
    thrash = false
    moonfire = false
    maul = false
    pulverize = false
    incarnationGuardian = false
    berserk = false
    bristlingFur = false
    galacticGuardian = false
    soulOfTheForest = false
    incarnationTalented = false
    earthwarden = false
    guardianOfElune = false
    survivalInstincts = false
    incapacitatingRoar = false
    renewSteel = false
    wrathOfNature = false
    strengthOfTheWild = false
    reinforcedFur = false
    fightingStyle = false
    bloodletting = false
    evergreen = false
    thorns = false
    grovel = false
    visceralTear = false
    regenGrowth = false
    layeredMane = false
    layeredManeTalented = false
    goryFur = false
    goryFurTalented = false
    twoForms = false
    typhoon = false
    massEntanglement = false
    ursolsVortex = false
    vineTangle = false
    ironBark = false
    leapingCharge = false
    wildCharge = false
    
    -- Update shapeshift form
    self:UpdateShapeshiftForm()
    
    API.PrintDebug("Guardian Druid state reset on spec change")
    
    return true
end

-- Return the module for loading
return Guardian