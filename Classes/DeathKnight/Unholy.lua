------------------------------------------
-- WindrunnerRotations - Unholy Death Knight Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Unholy = {}
-- This will be assigned to addon.Classes.DeathKnight.Unholy when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local DeathKnight

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentRunicPower = 0
local maxRunicPower = 100
local festeringWoundCount = 0
local festeringWoundMaxed = false -- Target has max FW stacks
local virusesActive = false
local virusesTargets = 0
local festeringWoundTargets = 0
local deathAndDecayActive = false
local deathAndDecayRemaining = 0
local abominationLimbActive = false
local darkTransformationActive = false
local darkTransformationRemaining = 0
local unholyAssaultActive = false
local apocalypseOnCooldown = false
local apocalypseCooldownRemaining = 0
local armyOfTheDeadOnCooldown = false
local armyOfTheDeadCooldownRemaining = 0
local ghoulActive = false
local ghoulSummonedTime = 0
local currentRunes = 0
local bloodPlague = false -- This is actually Virulent Plague for Unholy
local dndBuffActive = false
local unholyBlight = false
local abominationLimbOnCooldown = false
local armyOfTheDamnedProc = false
local suddenDoomProc = false
local runeForgeBearerActivated = false
local unholyGroundActive = false
local corruptedClawsActive = false
local unholyPact = false
local corpsesProliferated = false
local inMeleeRange = false
local petActive = false
local deathsPromiseProcActive = false
local magusOfTheDeadActive = false
local reanimatedStacks = 0
local festeringWoundStacks = 0
local eruptingPostulesStacks = 0
local pestilenceVictims = 0
local infectedClawsActive = false
local coilOfDevastation = false
local harbingerOfDoomActive = false
local pestilentPustulesActive = false
local deathRotProc = false

-- Constants
local UNHOLY_SPEC_ID = 252
local DEFAULT_AOE_THRESHOLD = 3
local FESTERING_WOUND_MAX_STACKS = 6 -- Maximum stacks per target
local DARK_TRANSFORMATION_DURATION = 15
local DARK_TRANSFORMATION_COOLDOWN = 60
local APOCALYPSE_COOLDOWN = 90
local ARMY_OF_THE_DEAD_COOLDOWN = 480
local DEATH_AND_DECAY_DURATION = 10
local DEATH_AND_DECAY_COOLDOWN = 30
local DEATH_COIL_COST = 40
local EPIDEMIC_COST = 30
local OUTBREAK_RANGE = 30 -- In yards
local UNHOLY_BLIGHT_RANGE = 10 -- In yards
local ARMY_OF_THE_DEAD_CAST_TIME = 5 -- In seconds
local SCOURGE_STRIKE_RANGE = 5 -- Melee range in yards
local SOUL_REAPER_EXECUTE_PCT = 35 -- Target health percent for Soul Reaper bonus damage

-- Initialize the Unholy module
function Unholy:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Unholy Death Knight module initialized")
    
    return true
end

-- Register spell IDs
function Unholy:RegisterSpells()
    -- Core rotational abilities
    spells.SCOURGE_STRIKE = 55090
    spells.FESTERING_STRIKE = 85948
    spells.DEATH_COIL = 47541
    spells.EPIDEMIC = 207317
    spells.OUTBREAK = 77575
    spells.UNHOLY_BLIGHT = 115989
    spells.DEATH_AND_DECAY = 43265
    spells.CLAWING_SHADOWS = 207311
    spells.SOUL_REAPER = 343294
    spells.DARK_TRANSFORMATION = 63560
    spells.APOCALYPSE = 275699
    spells.ARMY_OF_THE_DEAD = 42650
    spells.SUMMON_GARGOYLE = 49206
    spells.RAISE_DEAD = 46585
    spells.SACRIFICIAL_PACT = 327574
    
    -- Covenant abilities (some converted to regular abilities in War Within)
    spells.SWARMING_MIST = 311648
    spells.ABOMINATION_LIMB = 383269
    spells.SHACKLE_THE_UNWORTHY = 312202
    spells.DEATHS_DUE = 324128
    
    -- Utility/Defensive
    spells.DEATH_STRIKE = 49998
    spells.ANTI_MAGIC_SHELL = 48707
    spells.ICEBOUND_FORTITUDE = 48792
    spells.LICHBORNE = 49039
    spells.DEATH_PACT = 48743
    spells.ASPHYXIATE = 221562
    spells.MIND_FREEZE = 47528
    spells.CHAINS_OF_ICE = 45524
    spells.DEATH_GRIP = 49576
    spells.DEATH_GATE = 50977
    spells.DEATHS_ADVANCE = 48265
    spells.WRAITH_WALK = 212552
    
    -- Talents and passives
    spells.INFECTED_CLAWS = 207272
    spells.VIRULENT_PLAGUE = 191587
    spells.PESTILENCE = 277234
    spells.UNHOLY_ASSAULT = 207289
    spells.MORBIDITY = 377580
    spells.ALL_WILL_SERVE = 194916
    spells.BURSTING_SORES = 207264
    spells.EBON_FEVER = 207269
    spells.FEASTING_STRIKES = 390161
    spells.FESTERMIGHT = 377590
    spells.HARBINGER_OF_DOOM = 276023
    spells.INFECTED_CLAWS = 207272
    spells.PLAGUEBRINGER = 390175
    spells.ROTTEN_TOUCH = 390275
    spells.SUDDEN_DOOM = 49530
    spells.UNHOLY_BOND = 390259
    spells.UNHOLY_ENDURANCE = 63560
    spells.SUMMON_GARGOYLE = 49206
    spells.ARMY_OF_THE_DAMNED = 276837
    spells.DARK_TRANSFORMATION = 63560
    spells.GHOULISH_FRENZY = 377587
    spells.COMMANDER_OF_THE_DEAD = 390259
    spells.ETERNAL_AGONY = 390268
    spells.FESTERING_WOUND = 194310 -- The debuff applied to targets
    spells.RUNIC_CORRUPTION = 51460
    spells.SCOURGE_OF_WORLDS = 191747
    spells.VILE_CONTAGION = 390279
    spells.DEFILE = 152280
    spells.SUPERSTRAIN = 390283
    spells.COIL_OF_DEVASTATION = 390270
    spells.IMPROVED_DEATH_COIL = 377373
    spells.UNHOLY_AURA = 377440
    spells.EPIDEMIC = 207317
    spells.MORBID_STRIKES = 377442
    spells.NECROTIC_AURA = 377580
    spells.RAISE_ABOMINATION = 288853
    spells.DEATHS_CERTAINTY = 377019
    spells.PESTILENT_PUSTULES = 194917
    spells.IMPROVED_FESTERING_WOUND = 377578
    spells.IMPROVED_UNHOLY_AURA = 389672
    spells.ASSIMILATION = 374383
    spells.IMPROVED_DEATH_STRIKE = 374277
    spells.DEATHS_REACH = 276079
    spells.CLEAVING_STRIKES = 316916
    spells.UNHOLY_GROUND = 374265
    spells.RUNE_MASTERY = 374574
    spells.BLOOD_SCENT = 374030
    spells.CLENCHING_GRASP = 389679
    spells.PROLIFERATING_PUSTULES = 377537
    spells.DEATH_ROT = 377539
    spells.VIGOR_OF_NIGHT = 377532
    spells.MAGUS_OF_THE_DEAD = 390196
    spells.REANIMATION = 210128
    
    -- War Within specific talents and abilities
    spells.RUNEFORGEBEARER_FLAMES = 411755
    spells.CORRUPTED_CLAWS = 212468
    spells.DEATH_KNIGHT_UNHOLY_DEATH_AND_DECAY_BUFF = 188290
    spells.DEATHS_PROMISE = 378848
    spells.PLAGUES_STRIKE = 377537
    spells.SOUL_REAPER = 343294
    spells.FESTERING_DOOM = 377570
    spells.FESTERMIGHT = 377590
    spells.FESTERING_TELERGY = 390268
    spells.GHOULISH_FRENZY = 377587
    spells.WOUND_SPENDER = 376997
    spells.ERUPTING_POSTULES = 394566

    -- Legendary effects
    spells.DEADLIEST_COIL = 324128
    spells.FRENZIED_MONSTROSITY = 334888
    spells.DEATHS_CERTAINTY = 377019
    
    -- Buff IDs
    spells.DARK_TRANSFORMATION_BUFF = 63560
    spells.SUDDEN_DOOM_BUFF = 81340
    spells.UNHOLY_ASSAULT_BUFF = 207289
    spells.DEATH_AND_DECAY_BUFF = 188290
    spells.RUNIC_CORRUPTION_BUFF = 51460
    spells.UNHOLY_GROUND_BUFF = 374265
    spells.CORRUPTED_CLAWS_BUFF = 212468
    spells.UNHOLY_PACT_BUFF = 319230
    spells.ARMY_OF_THE_DAMNED_BUFF = 276837
    spells.HARBINGER_OF_DOOM_BUFF = 276023
    spells.MAGUS_OF_THE_DEAD_BUFF = 390196
    spells.DEATHS_PROMISE_BUFF = 378848
    spells.REANIMATION_BUFF = 210128
    spells.UNHOLY_BLIGHT_BUFF = 115989
    spells.ERUPTING_POSTULES_BUFF = 394566
    spells.PLAGUEBRINGER_BUFF = 390175
    spells.DEATH_ROT_BUFF = 377539
    spells.PESTILENT_PUSTULES_BUFF = 194917
    
    -- Debuff IDs
    spells.FESTERING_WOUND_DEBUFF = 194310
    spells.VIRULENT_PLAGUE_DEBUFF = 191587
    spells.UNHOLY_BLIGHT_DEBUFF = 115994
    spells.SOUL_REAPER_DEBUFF = 343294
    spells.CLENCHING_GRASP_DEBUFF = 389680
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.DARK_TRANSFORMATION = spells.DARK_TRANSFORMATION_BUFF
    buffs.SUDDEN_DOOM = spells.SUDDEN_DOOM_BUFF
    buffs.UNHOLY_ASSAULT = spells.UNHOLY_ASSAULT_BUFF
    buffs.DEATH_AND_DECAY = spells.DEATH_AND_DECAY_BUFF
    buffs.RUNIC_CORRUPTION = spells.RUNIC_CORRUPTION_BUFF
    buffs.UNHOLY_GROUND = spells.UNHOLY_GROUND_BUFF
    buffs.CORRUPTED_CLAWS = spells.CORRUPTED_CLAWS_BUFF
    buffs.UNHOLY_PACT = spells.UNHOLY_PACT_BUFF
    buffs.ARMY_OF_THE_DAMNED = spells.ARMY_OF_THE_DAMNED_BUFF
    buffs.HARBINGER_OF_DOOM = spells.HARBINGER_OF_DOOM_BUFF
    buffs.MAGUS_OF_THE_DEAD = spells.MAGUS_OF_THE_DEAD_BUFF
    buffs.DEATHS_PROMISE = spells.DEATHS_PROMISE_BUFF
    buffs.REANIMATION = spells.REANIMATION_BUFF
    buffs.UNHOLY_BLIGHT = spells.UNHOLY_BLIGHT_BUFF
    buffs.ERUPTING_POSTULES = spells.ERUPTING_POSTULES_BUFF
    buffs.PLAGUEBRINGER = spells.PLAGUEBRINGER_BUFF
    buffs.DEATH_ROT = spells.DEATH_ROT_BUFF
    buffs.PESTILENT_PUSTULES = spells.PESTILENT_PUSTULES_BUFF
    
    debuffs.FESTERING_WOUND = spells.FESTERING_WOUND_DEBUFF
    debuffs.VIRULENT_PLAGUE = spells.VIRULENT_PLAGUE_DEBUFF
    debuffs.UNHOLY_BLIGHT = spells.UNHOLY_BLIGHT_DEBUFF
    debuffs.SOUL_REAPER = spells.SOUL_REAPER_DEBUFF
    debuffs.CLENCHING_GRASP = spells.CLENCHING_GRASP_DEBUFF
    
    return true
end

-- Register variables to track
function Unholy:RegisterVariables()
    -- Talent tracking
    talents.hasClawingShadows = false
    talents.hasSoulReaper = false
    talents.hasUnholyBlight = false
    talents.hasInfectedClaws = false
    talents.hasPestilence = false
    talents.hasUnholyAssault = false
    talents.hasMorbidity = false
    talents.hasAllWillServe = false
    talents.hasBurstingSores = false
    talents.hasEbonFever = false
    talents.hasFeastingStrikes = false
    talents.hasFestermight = false
    talents.hasHarbingerOfDoom = false
    talents.hasInfectedClaws = false
    talents.hasPlaguebringer = false
    talents.hasRottenTouch = false
    talents.hasSuddenDoom = false
    talents.hasUnholyBond = false
    talents.hasUnholyEndurance = false
    talents.hasSummonGargoyle = false
    talents.hasArmyOfTheDamned = false
    talents.hasGhoulishFrenzy = false
    talents.hasCommanderOfTheDead = false
    talents.hasEternalAgony = false
    talents.hasScourgeOfWorlds = false
    talents.hasVileContagion = false
    talents.hasDefile = false
    talents.hasSuperstrain = false
    talents.hasCoilOfDevastation = false
    talents.hasImprovedDeathCoil = false
    talents.hasImprovedEpidemic = false
    talents.hasUnholyAura = false
    talents.hasMorbidStrikes = false
    talents.hasNecroticAura = false
    talents.hasRaiseAbomination = false
    talents.hasDeathsCertainty = false
    talents.hasPestilentPustules = false
    talents.hasImprovedFesteringWound = false
    talents.hasImprovedUnholyAura = false
    talents.hasAssimilation = false
    talents.hasImprovedDeathStrike = false
    talents.hasDeathsReach = false
    talents.hasCleavingStrikes = false
    talents.hasUnholyGround = false
    talents.hasRuneMastery = false
    talents.hasBloodScent = false
    talents.hasClenchingGrasp = false
    talents.hasProliferatingPustules = false
    talents.hasDeathRot = false
    talents.hasVigorOfNight = false
    talents.hasMagusOfTheDead = false
    talents.hasReanimation = false
    talents.hasAbominationLimb = false
    talents.hasRuneforgeBearerFlames = false
    talents.hasCorruptedClaws = false
    talents.hasDeathsPromise = false
    talents.hasPlaguebringer = false
    talents.hasFesteringDoom = false
    talents.hasFestermight = false
    talents.hasFesteringTelergy = false
    talents.hasGhoulishFrenzy = false
    talents.hasWoundSpender = false
    talents.hasEruptingPostules = false
    
    -- Target state tracking
    self.targetData = {}
    
    -- Initialize runic power
    currentRunicPower = API.GetPlayerPower()
    
    return true
end

-- Register spec-specific settings
function Unholy:RegisterSettings()
    ConfigRegistry:RegisterSettings("UnholyDeathKnight", {
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
            maintainVirulentPlague = {
                displayName = "Maintain Virulent Plague",
                description = "Keep Virulent Plague active on targets",
                type = "toggle",
                default = true
            },
            useEpidemic = {
                displayName = "Use Epidemic",
                description = "Use Epidemic for multi-target instead of Death Coil",
                type = "toggle",
                default = true
            },
            festeringWoundThreshold = {
                displayName = "Festering Wound Threshold",
                description = "Minimum Festering Wounds to pop with Scourge Strike",
                type = "slider",
                min = 1,
                max = 6,
                default = 4
            }
        },
        
        defensiveSettings = {
            useAntiMagicShell = {
                displayName = "Use Anti-Magic Shell",
                description = "Automatically use Anti-Magic Shell",
                type = "toggle",
                default = true
            },
            antiMagicShellThreshold = {
                displayName = "Anti-Magic Shell Threshold",
                description = "Health percentage to use Anti-Magic Shell",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useIceboundFortitude = {
                displayName = "Use Icebound Fortitude",
                description = "Automatically use Icebound Fortitude",
                type = "toggle",
                default = true
            },
            iceboundFortitudeThreshold = {
                displayName = "Icebound Fortitude Threshold",
                description = "Health percentage to use Icebound Fortitude",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useDeathPact = {
                displayName = "Use Death Pact",
                description = "Automatically use Death Pact when talented",
                type = "toggle",
                default = true
            },
            deathPactThreshold = {
                displayName = "Death Pact Threshold",
                description = "Health percentage to use Death Pact",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            useDeathStrike = {
                displayName = "Use Death Strike",
                description = "Automatically use Death Strike for healing",
                type = "toggle",
                default = true
            },
            deathStrikeThreshold = {
                displayName = "Death Strike Threshold",
                description = "Health percentage to use Death Strike",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useSacrificialPact = {
                displayName = "Use Sacrificial Pact",
                description = "Automatically use Sacrificial Pact for emergency healing",
                type = "toggle",
                default = true
            },
            sacrificialPactThreshold = {
                displayName = "Sacrificial Pact Threshold",
                description = "Health percentage to use Sacrificial Pact",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            }
        },
        
        offensiveSettings = {
            useDarkTransformation = {
                displayName = "Use Dark Transformation",
                description = "Automatically use Dark Transformation",
                type = "toggle",
                default = true
            },
            useApocalypse = {
                displayName = "Use Apocalypse",
                description = "Automatically use Apocalypse",
                type = "toggle",
                default = true
            },
            apocalypseFWThreshold = {
                displayName = "Apocalypse FW Threshold",
                description = "Minimum Festering Wounds for Apocalypse",
                type = "slider",
                min = 4,
                max = 6,
                default = 4
            },
            useArmyOfTheDead = {
                displayName = "Use Army of the Dead",
                description = "Automatically use Army of the Dead",
                type = "toggle",
                default = true
            },
            useUnholyBlight = {
                displayName = "Use Unholy Blight",
                description = "Automatically use Unholy Blight when talented",
                type = "toggle",
                default = true
            },
            useUnholyAssault = {
                displayName = "Use Unholy Assault",
                description = "Automatically use Unholy Assault when talented",
                type = "toggle",
                default = true
            },
            useSummonGargoyle = {
                displayName = "Use Summon Gargoyle",
                description = "Automatically use Summon Gargoyle when talented",
                type = "toggle",
                default = true
            },
            useSoulReaper = {
                displayName = "Use Soul Reaper",
                description = "Automatically use Soul Reaper when talented",
                type = "toggle",
                default = true
            }
        },
        
        abominationLimbSettings = {
            useAbominationLimb = {
                displayName = "Use Abomination Limb",
                description = "Automatically use Abomination Limb",
                type = "toggle",
                default = true
            },
            abominationLimbSync = {
                displayName = "Sync with Apocalypse",
                description = "Use Abomination Limb with Apocalypse",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            swarmingMistUsage = {
                displayName = "Swarming Mist Usage",
                description = "How to use Swarming Mist",
                type = "dropdown",
                options = {"On Cooldown", "For Resources", "With Cooldowns"},
                default = "With Cooldowns"
            },
            deathAndDecayUsage = {
                displayName = "Death and Decay Usage",
                description = "When to use Death and Decay",
                type = "dropdown",
                options = {"Always", "Only in AoE", "Only with Unholy Ground", "Never"},
                default = "Only in AoE"
            },
            reserveRunicPower = {
                displayName = "Reserve Runic Power",
                description = "Minimum Runic Power to maintain",
                type = "slider",
                min = 0,
                max = 60,
                default = 30
            },
            poolForGargoyle = {
                displayName = "Pool for Gargoyle",
                description = "Pool resources before Summon Gargoyle",
                type = "toggle",
                default = true
            },
            runicPowerThresholdDeathCoil = {
                displayName = "Death Coil RP Threshold",
                description = "Runic Power to use Death Coil",
                type = "slider",
                min = DEATH_COIL_COST,
                max = 100,
                default = 80
            },
            clenchingGraspMaxTargets = {
                displayName = "Clenching Grasp Targets",
                description = "Maximum targets to apply Clenching Grasp",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Apocalypse controls
            apocalypse = AAC.RegisterAbility(spells.APOCALYPSE, {
                enabled = true,
                useDuringBurstOnly = false,
                minWounds = 4
            }),
            
            -- Army of the Dead controls
            armyOfTheDead = AAC.RegisterAbility(spells.ARMY_OF_THE_DEAD, {
                enabled = true,
                useDuringBurstOnly = true,
                safetyMargin = 15 -- How much health % to have before channeling
            }),
            
            -- Dark Transformation controls
            darkTransformation = AAC.RegisterAbility(spells.DARK_TRANSFORMATION, {
                enabled = true,
                useWithApocalypse = true,
                holdForBurst = false
            })
        }
    })
    
    return true
end

-- Register for events 
function Unholy:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for runic power updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "RUNIC_POWER" then
            self:UpdateRunicPower()
        end
    end)
    
    -- Register for rune updates
    API.RegisterEvent("RUNE_POWER_UPDATE", function(runeIndex, isEnergize) 
        self:UpdateRuneStatus()
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Register for pet presence events
    API.RegisterEvent("UNIT_PET", function(unit) 
        if unit == "player" then
            self:UpdatePetStatus()
        end
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial pet status check
    self:UpdatePetStatus()
    
    return true
end

-- Update talent information
function Unholy:UpdateTalentInfo()
    -- Check for important talents
    talents.hasClawingShadows = API.HasTalent(spells.CLAWING_SHADOWS)
    talents.hasSoulReaper = API.HasTalent(spells.SOUL_REAPER)
    talents.hasUnholyBlight = API.HasTalent(spells.UNHOLY_BLIGHT)
    talents.hasInfectedClaws = API.HasTalent(spells.INFECTED_CLAWS)
    talents.hasPestilence = API.HasTalent(spells.PESTILENCE)
    talents.hasUnholyAssault = API.HasTalent(spells.UNHOLY_ASSAULT)
    talents.hasMorbidity = API.HasTalent(spells.MORBIDITY)
    talents.hasAllWillServe = API.HasTalent(spells.ALL_WILL_SERVE)
    talents.hasBurstingSores = API.HasTalent(spells.BURSTING_SORES)
    talents.hasEbonFever = API.HasTalent(spells.EBON_FEVER)
    talents.hasFeastingStrikes = API.HasTalent(spells.FEASTING_STRIKES)
    talents.hasFestermight = API.HasTalent(spells.FESTERMIGHT)
    talents.hasHarbingerOfDoom = API.HasTalent(spells.HARBINGER_OF_DOOM)
    talents.hasInfectedClaws = API.HasTalent(spells.INFECTED_CLAWS)
    talents.hasPlaguebringer = API.HasTalent(spells.PLAGUEBRINGER)
    talents.hasRottenTouch = API.HasTalent(spells.ROTTEN_TOUCH)
    talents.hasSuddenDoom = API.HasTalent(spells.SUDDEN_DOOM)
    talents.hasUnholyBond = API.HasTalent(spells.UNHOLY_BOND)
    talents.hasUnholyEndurance = API.HasTalent(spells.UNHOLY_ENDURANCE)
    talents.hasSummonGargoyle = API.HasTalent(spells.SUMMON_GARGOYLE)
    talents.hasArmyOfTheDamned = API.HasTalent(spells.ARMY_OF_THE_DAMNED)
    talents.hasGhoulishFrenzy = API.HasTalent(spells.GHOULISH_FRENZY)
    talents.hasCommanderOfTheDead = API.HasTalent(spells.COMMANDER_OF_THE_DEAD)
    talents.hasEternalAgony = API.HasTalent(spells.ETERNAL_AGONY)
    talents.hasScourgeOfWorlds = API.HasTalent(spells.SCOURGE_OF_WORLDS)
    talents.hasVileContagion = API.HasTalent(spells.VILE_CONTAGION)
    talents.hasDefile = API.HasTalent(spells.DEFILE)
    talents.hasSuperstrain = API.HasTalent(spells.SUPERSTRAIN)
    talents.hasCoilOfDevastation = API.HasTalent(spells.COIL_OF_DEVASTATION)
    talents.hasImprovedDeathCoil = API.HasTalent(spells.IMPROVED_DEATH_COIL)
    talents.hasUnholyAura = API.HasTalent(spells.UNHOLY_AURA)
    talents.hasMorbidStrikes = API.HasTalent(spells.MORBID_STRIKES)
    talents.hasNecroticAura = API.HasTalent(spells.NECROTIC_AURA)
    talents.hasRaiseAbomination = API.HasTalent(spells.RAISE_ABOMINATION)
    talents.hasDeathsCertainty = API.HasTalent(spells.DEATHS_CERTAINTY)
    talents.hasPestilentPustules = API.HasTalent(spells.PESTILENT_PUSTULES)
    talents.hasImprovedFesteringWound = API.HasTalent(spells.IMPROVED_FESTERING_WOUND)
    talents.hasImprovedUnholyAura = API.HasTalent(spells.IMPROVED_UNHOLY_AURA)
    talents.hasAssimilation = API.HasTalent(spells.ASSIMILATION)
    talents.hasImprovedDeathStrike = API.HasTalent(spells.IMPROVED_DEATH_STRIKE)
    talents.hasDeathsReach = API.HasTalent(spells.DEATHS_REACH)
    talents.hasCleavingStrikes = API.HasTalent(spells.CLEAVING_STRIKES)
    talents.hasUnholyGround = API.HasTalent(spells.UNHOLY_GROUND)
    talents.hasRuneMastery = API.HasTalent(spells.RUNE_MASTERY)
    talents.hasBloodScent = API.HasTalent(spells.BLOOD_SCENT)
    talents.hasClenchingGrasp = API.HasTalent(spells.CLENCHING_GRASP)
    talents.hasProliferatingPustules = API.HasTalent(spells.PROLIFERATING_PUSTULES)
    talents.hasDeathRot = API.HasTalent(spells.DEATH_ROT)
    talents.hasVigorOfNight = API.HasTalent(spells.VIGOR_OF_NIGHT)
    talents.hasMagusOfTheDead = API.HasTalent(spells.MAGUS_OF_THE_DEAD)
    talents.hasReanimation = API.HasTalent(spells.REANIMATION)
    talents.hasAbominationLimb = API.HasTalent(spells.ABOMINATION_LIMB)
    talents.hasRuneforgeBearerFlames = API.HasTalent(spells.RUNEFORGEBEARER_FLAMES)
    talents.hasCorruptedClaws = API.HasTalent(spells.CORRUPTED_CLAWS)
    talents.hasDeathsPromise = API.HasTalent(spells.DEATHS_PROMISE)
    talents.hasPlaguebringer = API.HasTalent(spells.PLAGUEBRINGER)
    talents.hasFesteringDoom = API.HasTalent(spells.FESTERING_DOOM)
    talents.hasFestermight = API.HasTalent(spells.FESTERMIGHT)
    talents.hasFesteringTelergy = API.HasTalent(spells.FESTERING_TELERGY)
    talents.hasGhoulishFrenzy = API.HasTalent(spells.GHOULISH_FRENZY)
    talents.hasWoundSpender = API.HasTalent(spells.WOUND_SPENDER)
    talents.hasEruptingPostules = API.HasTalent(spells.ERUPTING_POSTULES)

    API.PrintDebug("Unholy Death Knight talents updated")
    
    return true
end

-- Update runic power tracking
function Unholy:UpdateRunicPower()
    currentRunicPower = API.GetPlayerPower()
    return true
end

-- Update rune status
function Unholy:UpdateRuneStatus()
    currentRunes = API.GetAvailableRunes() or 0
    return true
end

-- Update pet status
function Unholy:UpdatePetStatus()
    petActive = API.HasActivePet()
    
    -- If we have no pet, summon one
    if not petActive and API.CanCast(spells.RAISE_DEAD) then
        ghoulActive = false
        ghoulSummonedTime = 0
    end
    
    return true
end

-- Update target data
function Unholy:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", SCOURGE_STRIKE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                festeringWounds = 0,
                virulentPlague = false,
                virulentPlagueExpiration = 0,
                soulReaper = false,
                soulReaperExpiration = 0
            }
        end
        
        -- Check for Festering Wounds
        festeringWoundStacks = API.GetDebuffStacks(targetGUID, debuffs.FESTERING_WOUND) or 0
        festeringWoundCount = festeringWoundStacks
        festeringWoundMaxed = festeringWoundCount >= FESTERING_WOUND_MAX_STACKS
        self.targetData[targetGUID].festeringWounds = festeringWoundCount
        
        -- Check for Virulent Plague (Blood Plague for Unholy)
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.VIRULENT_PLAGUE)
        if name then
            self.targetData[targetGUID].virulentPlague = true
            self.targetData[targetGUID].virulentPlagueExpiration = expiration
            bloodPlague = true -- Using this for consistency with API expectations
        else
            self.targetData[targetGUID].virulentPlague = false
            self.targetData[targetGUID].virulentPlagueExpiration = 0
            bloodPlague = false
        end
        
        -- Check for Soul Reaper
        if talents.hasSoulReaper then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.SOUL_REAPER)
            if name then
                self.targetData[targetGUID].soulReaper = true
                self.targetData[targetGUID].soulReaperExpiration = expiration
            else
                self.targetData[targetGUID].soulReaper = false
                self.targetData[targetGUID].soulReaperExpiration = 0
            end
        end
    end
    
    -- Count how many targets have Festering Wounds - needed for AoE decisions
    festeringWoundTargets = 0
    for _, targetData in pairs(self.targetData) do
        if targetData.festeringWounds > 0 then
            festeringWoundTargets = festeringWoundTargets + 1
        end
    end
    
    -- Count how many targets have Virulent Plague
    virusesTargets = 0
    for _, targetData in pairs(self.targetData) do
        if targetData.virulentPlague then
            virusesTargets = virusesTargets + 1
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Unholy AoE radius
    
    return true
end

-- Handle combat log events
function Unholy:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Dark Transformation
            if spellID == buffs.DARK_TRANSFORMATION then
                darkTransformationActive = true
                darkTransformationRemaining = DARK_TRANSFORMATION_DURATION
                API.PrintDebug("Dark Transformation activated")
            end
            
            -- Track Unholy Assault
            if spellID == buffs.UNHOLY_ASSAULT then
                unholyAssaultActive = true
                API.PrintDebug("Unholy Assault activated")
            end
            
            -- Track Death and Decay
            if spellID == buffs.DEATH_AND_DECAY then
                deathAndDecayActive = true
                deathAndDecayRemaining = DEATH_AND_DECAY_DURATION
                dndBuffActive = true
                API.PrintDebug("Death and Decay activated")
            end
            
            -- Track Runic Corruption
            if spellID == buffs.RUNIC_CORRUPTION then
                API.PrintDebug("Runic Corruption activated")
            end
            
            -- Track Unholy Ground
            if spellID == buffs.UNHOLY_GROUND then
                unholyGroundActive = true
                API.PrintDebug("Unholy Ground activated")
            end
            
            -- Track Corrupted Claws
            if spellID == buffs.CORRUPTED_CLAWS then
                corruptedClawsActive = true
                API.PrintDebug("Corrupted Claws activated")
            end
            
            -- Track Unholy Pact
            if spellID == buffs.UNHOLY_PACT then
                unholyPact = true
                API.PrintDebug("Unholy Pact activated")
            end
            
            -- Track Army of the Damned
            if spellID == buffs.ARMY_OF_THE_DAMNED then
                armyOfTheDamnedProc = true
                API.PrintDebug("Army of the Damned proc activated")
            end
            
            -- Track Sudden Doom
            if spellID == buffs.SUDDEN_DOOM then
                suddenDoomProc = true
                API.PrintDebug("Sudden Doom proc activated")
            end
            
            -- Track Harbinger of Doom
            if spellID == buffs.HARBINGER_OF_DOOM then
                harbingerOfDoomActive = true
                API.PrintDebug("Harbinger of Doom activated")
            end
            
            -- Track Magus of the Dead
            if spellID == buffs.MAGUS_OF_THE_DEAD then
                magusOfTheDeadActive = true
                API.PrintDebug("Magus of the Dead activated")
            end
            
            -- Track Death's Promise
            if spellID == buffs.DEATHS_PROMISE then
                deathsPromiseProcActive = true
                API.PrintDebug("Death's Promise activated")
            end
            
            -- Track Reanimation
            if spellID == buffs.REANIMATION then
                reanimatedStacks = select(4, API.GetBuffInfo("player", buffs.REANIMATION)) or 0
                API.PrintDebug("Reanimation stacks: " .. tostring(reanimatedStacks))
            end
            
            -- Track Unholy Blight
            if spellID == buffs.UNHOLY_BLIGHT then
                unholyBlight = true
                API.PrintDebug("Unholy Blight activated")
            end
            
            -- Track Erupting Postules
            if spellID == buffs.ERUPTING_POSTULES then
                eruptingPostulesStacks = select(4, API.GetBuffInfo("player", buffs.ERUPTING_POSTULES)) or 0
                API.PrintDebug("Erupting Postules stacks: " .. tostring(eruptingPostulesStacks))
            end
            
            -- Track Plaguebringer
            if spellID == buffs.PLAGUEBRINGER then
                API.PrintDebug("Plaguebringer activated")
            end
            
            -- Track Death Rot
            if spellID == buffs.DEATH_ROT then
                deathRotProc = true
                API.PrintDebug("Death Rot proc activated")
            end
            
            -- Track Pestilent Pustules
            if spellID == buffs.PESTILENT_PUSTULES then
                pestilentPustulesActive = true
                API.PrintDebug("Pestilent Pustules activated")
            end
        end
        
        -- Track target debuffs
        -- Update target data when debuffs change
        self:UpdateTargetData()
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Dark Transformation
            if spellID == buffs.DARK_TRANSFORMATION then
                darkTransformationActive = false
                darkTransformationRemaining = 0
                API.PrintDebug("Dark Transformation faded")
            end
            
            -- Track Unholy Assault
            if spellID == buffs.UNHOLY_ASSAULT then
                unholyAssaultActive = false
                API.PrintDebug("Unholy Assault faded")
            end
            
            -- Track Death and Decay
            if spellID == buffs.DEATH_AND_DECAY then
                deathAndDecayActive = false
                deathAndDecayRemaining = 0
                dndBuffActive = false
                API.PrintDebug("Death and Decay faded")
            end
            
            -- Track Unholy Ground
            if spellID == buffs.UNHOLY_GROUND then
                unholyGroundActive = false
                API.PrintDebug("Unholy Ground faded")
            end
            
            -- Track Corrupted Claws
            if spellID == buffs.CORRUPTED_CLAWS then
                corruptedClawsActive = false
                API.PrintDebug("Corrupted Claws faded")
            end
            
            -- Track Unholy Pact
            if spellID == buffs.UNHOLY_PACT then
                unholyPact = false
                API.PrintDebug("Unholy Pact faded")
            end
            
            -- Track Army of the Damned
            if spellID == buffs.ARMY_OF_THE_DAMNED then
                armyOfTheDamnedProc = false
                API.PrintDebug("Army of the Damned proc faded")
            end
            
            -- Track Sudden Doom
            if spellID == buffs.SUDDEN_DOOM then
                suddenDoomProc = false
                API.PrintDebug("Sudden Doom proc consumed")
            end
            
            -- Track Harbinger of Doom
            if spellID == buffs.HARBINGER_OF_DOOM then
                harbingerOfDoomActive = false
                API.PrintDebug("Harbinger of Doom faded")
            end
            
            -- Track Magus of the Dead
            if spellID == buffs.MAGUS_OF_THE_DEAD then
                magusOfTheDeadActive = false
                API.PrintDebug("Magus of the Dead faded")
            end
            
            -- Track Death's Promise
            if spellID == buffs.DEATHS_PROMISE then
                deathsPromiseProcActive = false
                API.PrintDebug("Death's Promise faded")
            end
            
            -- Track Unholy Blight
            if spellID == buffs.UNHOLY_BLIGHT then
                unholyBlight = false
                API.PrintDebug("Unholy Blight faded")
            end
            
            -- Track Death Rot
            if spellID == buffs.DEATH_ROT then
                deathRotProc = false
                API.PrintDebug("Death Rot faded")
            end
            
            -- Track Pestilent Pustules
            if spellID == buffs.PESTILENT_PUSTULES then
                pestilentPustulesActive = false
                API.PrintDebug("Pestilent Pustules faded")
            end
        end
        
        -- Track target debuffs
        -- Update target data when debuffs change
        self:UpdateTargetData()
    end
    
    -- Track Reanimation stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.REANIMATION and destGUID == API.GetPlayerGUID() then
        reanimatedStacks = select(4, API.GetBuffInfo("player", buffs.REANIMATION)) or 0
        API.PrintDebug("Reanimation stacks: " .. tostring(reanimatedStacks))
    end
    
    -- Track Erupting Postules stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.ERUPTING_POSTULES and destGUID == API.GetPlayerGUID() then
        eruptingPostulesStacks = select(4, API.GetBuffInfo("player", buffs.ERUPTING_POSTULES)) or 0
        API.PrintDebug("Erupting Postules stacks: " .. tostring(eruptingPostulesStacks))
    end
    
    -- Track Festering Wound applications
    if eventType == "SPELL_AURA_APPLIED" and spellID == debuffs.FESTERING_WOUND then
        self:UpdateTargetData() -- Update target data to get new stacks
        API.PrintDebug("Festering Wound applied to " .. destName)
    end
    
    -- Track Festering Wound stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == debuffs.FESTERING_WOUND then
        self:UpdateTargetData() -- Update target data to get new stacks
        API.PrintDebug("Festering Wound stack added to " .. destName)
    end
    
    -- Track Festering Wound bursting
    if eventType == "SPELL_AURA_REMOVED" and spellID == debuffs.FESTERING_WOUND then
        self:UpdateTargetData() -- Update target data
        API.PrintDebug("Festering Wound consumed from " .. destName)
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.APOCALYPSE then
            apocalypseOnCooldown = true
            apocalypseCooldownRemaining = APOCALYPSE_COOLDOWN
            API.PrintDebug("Apocalypse cast, on cooldown for " .. tostring(APOCALYPSE_COOLDOWN) .. "s")
        elseif spellID == spells.ARMY_OF_THE_DEAD then
            armyOfTheDeadOnCooldown = true
            armyOfTheDeadCooldownRemaining = ARMY_OF_THE_DEAD_COOLDOWN
            API.PrintDebug("Army of the Dead cast, on cooldown for " .. tostring(ARMY_OF_THE_DEAD_COOLDOWN) .. "s")
        elseif spellID == spells.DARK_TRANSFORMATION then
            API.PrintDebug("Dark Transformation cast")
        elseif spellID == spells.DEATH_AND_DECAY or spellID == spells.DEFILE then
            deathAndDecayActive = true
            deathAndDecayRemaining = DEATH_AND_DECAY_DURATION
            API.PrintDebug("Death and Decay/Defile cast")
        elseif spellID == spells.ABOMINATION_LIMB then
            abominationLimbActive = true
            abominationLimbOnCooldown = true
            -- Set timer to track when it ends
            C_Timer.After(12, function() -- Abomination Limb lasts 12 seconds
                abominationLimbActive = false
                API.PrintDebug("Abomination Limb effect ended")
            end)
            API.PrintDebug("Abomination Limb cast")
        elseif spellID == spells.UNHOLY_ASSAULT then
            unholyAssaultActive = true
            API.PrintDebug("Unholy Assault cast")
        elseif spellID == spells.UNHOLY_BLIGHT then
            unholyBlight = true
            API.PrintDebug("Unholy Blight cast")
        elseif spellID == spells.RAISE_DEAD then
            ghoulActive = true
            ghoulSummonedTime = GetTime()
            API.PrintDebug("Ghoul summoned")
        elseif spellID == spells.RUNEFORGEBEARER_FLAMES then
            runeForgeBearerActivated = true
            API.PrintDebug("RuneforgeBearer Flames activated")
        elseif spellID == spells.SACRIFICIAL_PACT then
            ghoulActive = false
            API.PrintDebug("Ghoul sacrificed")
        end
    end
    
    -- Track death of targets with Festering Wounds for Corpses Proliferated
    if eventType == "UNIT_DIED" and self.targetData[destGUID] and self.targetData[destGUID].festeringWounds > 0 then
        -- Only count this if we have Proliferating Pustules talented
        if talents.hasProliferatingPustules then
            corpsesProliferated = true
            pestilenceVictims = pestilenceVictims + 1
            -- Reset counter after a while
            C_Timer.After(5, function()
                corpsesProliferated = false
                pestilenceVictims = 0
            end)
            API.PrintDebug("Target died with Festering Wounds, Pestilence triggered")
        end
    end
    
    return true
end

-- Main rotation function
function Unholy:RunRotation()
    -- Check if we should be running Unholy Death Knight logic
    if API.GetActiveSpecID() ~= UNHOLY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("UnholyDeathKnight")
    
    -- Update variables
    self:UpdateRunicPower()
    self:UpdateRuneStatus()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Summon pet if we don't have one
    if not petActive and API.CanCast(spells.RAISE_DEAD) then
        API.CastSpell(spells.RAISE_DEAD)
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
    
    -- Maintain Virulent Plague
    if settings.rotationSettings.maintainVirulentPlague and
       not bloodPlague and
       (API.CanCast(spells.OUTBREAK) or 
       (talents.hasUnholyBlight and API.CanCast(spells.UNHOLY_BLIGHT))) then
        
        -- If we have Unholy Blight and it's enabled, use it
        if talents.hasUnholyBlight and 
           settings.offensiveSettings.useUnholyBlight and
           API.CanCast(spells.UNHOLY_BLIGHT) and
           API.IsUnitInRange("target", UNHOLY_BLIGHT_RANGE) then
            API.CastSpell(spells.UNHOLY_BLIGHT)
            return true
        end
        
        -- Otherwise use Outbreak
        if API.CanCast(spells.OUTBREAK) and API.IsUnitInRange("target", OUTBREAK_RANGE) then
            API.CastSpell(spells.OUTBREAK)
            return true
        end
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Check if we're in melee range
    if not inMeleeRange then
        -- Handle ranged abilities if not in melee range
        if self:HandleRangeRotation(settings) then
            return true
        end
        
        -- Skip rest of rotation if not in range and no ranged abilities are available
        return false
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Unholy:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.MIND_FREEZE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.MIND_FREEZE)
        return true
    end
    
    -- Use Asphyxiate as backup interrupt if talented
    if API.IsUnitInRange("target", 20) and
       talents.hasAsphyxiate and
       API.CanCast(spells.ASPHYXIATE) and 
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.ASPHYXIATE)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Unholy:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Anti-Magic Shell
    if settings.defensiveSettings.useAntiMagicShell and
       playerHealth <= settings.defensiveSettings.antiMagicShellThreshold and
       API.CanCast(spells.ANTI_MAGIC_SHELL) then
        API.CastSpell(spells.ANTI_MAGIC_SHELL)
        return true
    end
    
    -- Use Icebound Fortitude
    if settings.defensiveSettings.useIceboundFortitude and
       playerHealth <= settings.defensiveSettings.iceboundFortitudeThreshold and
       API.CanCast(spells.ICEBOUND_FORTITUDE) then
        API.CastSpell(spells.ICEBOUND_FORTITUDE)
        return true
    end
    
    -- Use Death Pact if talented
    if settings.defensiveSettings.useDeathPact and
       playerHealth <= settings.defensiveSettings.deathPactThreshold and
       API.CanCast(spells.DEATH_PACT) then
        API.CastSpell(spells.DEATH_PACT)
        return true
    end
    
    -- Use Death Strike
    if settings.defensiveSettings.useDeathStrike and
       playerHealth <= settings.defensiveSettings.deathStrikeThreshold and
       currentRunicPower >= 45 and
       API.CanCast(spells.DEATH_STRIKE) and
       inMeleeRange then
        API.CastSpell(spells.DEATH_STRIKE)
        return true
    end
    
    -- Use Sacrificial Pact in emergency
    if settings.defensiveSettings.useSacrificialPact and
       playerHealth <= settings.defensiveSettings.sacrificialPactThreshold and
       petActive and
       API.CanCast(spells.SACRIFICIAL_PACT) then
        API.CastSpell(spells.SACRIFICIAL_PACT)
        return true
    end
    
    return false
end

-- Handle abilities when out of melee range
function Unholy:HandleRangeRotation(settings)
    -- Apply Chains of Ice if talented with Clenching Grasp
    if talents.hasClenchingGrasp and
       API.IsUnitInRange("target", 30) and
       API.CanCast(spells.CHAINS_OF_ICE) then
        
        -- Check if we should apply to more targets
        if currentAoETargets <= settings.advancedSettings.clenchingGraspMaxTargets then
            API.CastSpell(spells.CHAINS_OF_ICE)
            return true
        end
    end
    
    -- Keep Virulent Plague up with Outbreak
    if settings.rotationSettings.maintainVirulentPlague and
       not bloodPlague and
       API.IsUnitInRange("target", OUTBREAK_RANGE) and
       API.CanCast(spells.OUTBREAK) then
        API.CastSpell(spells.OUTBREAK)
        return true
    end
    
    -- Use Death Coil to spend runic power
    if currentRunicPower >= settings.advancedSettings.runicPowerThresholdDeathCoil and
       API.CanCast(spells.DEATH_COIL) then
        API.CastSpell(spells.DEATH_COIL)
        return true
    end
    
    -- Use Death Coil with Sudden Doom proc
    if suddenDoomProc and API.CanCast(spells.DEATH_COIL) then
        API.CastSpell(spells.DEATH_COIL)
        return true
    end
    
    -- Use Death Grip to pull target into range
    if API.IsUnitInRange("target", 30) and API.CanCast(spells.DEATH_GRIP) then
        API.CastSpell(spells.DEATH_GRIP)
        return true
    end
    
    -- Use wraith walk to get in range
    if API.CanCast(spells.WRAITH_WALK) then
        API.CastSpell(spells.WRAITH_WALK)
        return true
    end
    
    -- Use Death's Advance to get in range
    if API.CanCast(spells.DEATHS_ADVANCE) then
        API.CastSpell(spells.DEATHS_ADVANCE)
        return true
    }
    
    return false
end

-- Handle cooldown abilities
function Unholy:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive and not suddenDoomProc then
        -- Still use some abilities even without burst
        -- Use Dark Transformation if not holding for burst
        if petActive and
           settings.offensiveSettings.useDarkTransformation and
           settings.abilityControls.darkTransformation.enabled and
           not darkTransformationActive and
           not settings.abilityControls.darkTransformation.holdForBurst and
           API.CanCast(spells.DARK_TRANSFORMATION) then
            API.CastSpell(spells.DARK_TRANSFORMATION)
            return true
        end
        
        return false
    end
    
    -- Army of the Dead - precast for boss fights
    if settings.offensiveSettings.useArmyOfTheDead and
       settings.abilityControls.armyOfTheDead.enabled and
       not armyOfTheDeadOnCooldown and
       API.CanCast(spells.ARMY_OF_THE_DEAD) and
       API.GetPlayerHealthPercent() > settings.abilityControls.armyOfTheDead.safetyMargin then
        API.CastSpell(spells.ARMY_OF_THE_DEAD)
        return true
    end
    
    -- Dark Transformation
    if petActive and
       settings.offensiveSettings.useDarkTransformation and
       settings.abilityControls.darkTransformation.enabled and
       not darkTransformationActive and
       API.CanCast(spells.DARK_TRANSFORMATION) then
        
        -- Check if we want to use with Apocalypse
        if not settings.abilityControls.darkTransformation.useWithApocalypse or 
           apocalypseOnCooldown or API.GetSpellCooldownRemaining(spells.APOCALYPSE) > 10 then
            API.CastSpell(spells.DARK_TRANSFORMATION)
            return true
        end
    end
    
    -- Unholy Assault
    if talents.hasUnholyAssault and
       settings.offensiveSettings.useUnholyAssault and
       petActive and
       API.CanCast(spells.UNHOLY_ASSAULT) then
        API.CastSpell(spells.UNHOLY_ASSAULT)
        return true
    end
    
    -- Summon Gargoyle
    if talents.hasSummonGargoyle and
       settings.offensiveSettings.useSummonGargoyle and
       API.CanCast(spells.SUMMON_GARGOYLE) then
        API.CastSpell(spells.SUMMON_GARGOYLE)
        return true
    end
    
    -- Abomination Limb
    if talents.hasAbominationLimb and
       settings.abominationLimbSettings.useAbominationLimb and
       API.CanCast(spells.ABOMINATION_LIMB) then
        
        -- Check if we want to sync with Apocalypse
        if not settings.abominationLimbSettings.abominationLimbSync or 
           apocalypseOnCooldown or API.GetSpellCooldownRemaining(spells.APOCALYPSE) > 10 then
            API.CastSpell(spells.ABOMINATION_LIMB)
            return true
        end
    end
    
    -- Apocalypse - Use after we have enough Festering Wounds
    if settings.offensiveSettings.useApocalypse and
       settings.abilityControls.apocalypse.enabled and
       not apocalypseOnCooldown and
       festeringWoundCount >= settings.offensiveSettings.apocalypseFWThreshold and
       API.CanCast(spells.APOCALYPSE) then
        API.CastSpell(spells.APOCALYPSE)
        return true
    end
    
    -- Handle other covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Unholy:HandleCovenantAbilities(settings)
    -- Swarming Mist
    if API.CanCast(spells.SWARMING_MIST) then
        if settings.advancedSettings.swarmingMistUsage == "On Cooldown" or
           (settings.advancedSettings.swarmingMistUsage == "For Resources" and currentRunicPower < 50) or
           (settings.advancedSettings.swarmingMistUsage == "With Cooldowns" and burstModeActive) then
            API.CastSpell(spells.SWARMING_MIST)
            return true
        end
    end
    
    -- Shackle the Unworthy
    if API.CanCast(spells.SHACKLE_THE_UNWORTHY) then
        API.CastSpell(spells.SHACKLE_THE_UNWORTHY)
        return true
    end
    
    -- Death's Due - replaces Death and Decay with more damage
    if API.CanCast(spells.DEATHS_DUE) then
        if settings.advancedSettings.deathAndDecayUsage == "Always" or
           (settings.advancedSettings.deathAndDecayUsage == "Only in AoE" and currentAoETargets >= DEFAULT_AOE_THRESHOLD) or
           (settings.advancedSettings.deathAndDecayUsage == "Only with Unholy Ground" and talents.hasUnholyGround) then
            API.CastSpellAtCursor(spells.DEATHS_DUE)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Unholy:HandleAoERotation(settings)
    -- Soul Reaper on execute phase targets
    if talents.hasSoulReaper and
       settings.offensiveSettings.useSoulReaper and
       API.GetTargetHealthPercent() <= SOUL_REAPER_EXECUTE_PCT and
       API.CanCast(spells.SOUL_REAPER) then
        API.CastSpell(spells.SOUL_REAPER)
        return true
    end
    
    -- Epidemic for AoE damage
    if settings.rotationSettings.useEpidemic and
       currentRunicPower >= EPIDEMIC_COST and
       virusesTargets >= 2 and
       API.CanCast(spells.EPIDEMIC) then
        API.CastSpell(spells.EPIDEMIC)
        return true
    end
    
    -- Death and Decay / Defile for AoE
    if not deathAndDecayActive and
       currentRunes >= 1 and
       (API.CanCast(spells.DEATH_AND_DECAY) or (talents.hasDefile and API.CanCast(spells.DEFILE))) then
        
        -- Consider settings when deciding to use DnD
        if settings.advancedSettings.deathAndDecayUsage == "Always" or
           settings.advancedSettings.deathAndDecayUsage == "Only in AoE" or
           (settings.advancedSettings.deathAndDecayUsage == "Only with Unholy Ground" and talents.hasUnholyGround) then
            
            if talents.hasDefile and API.CanCast(spells.DEFILE) then
                API.CastSpellAtCursor(spells.DEFILE)
                return true
            else
                API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
                return true
            end
        end
    end
    
    -- Apply Festering Wounds to multiple targets with Festering Strike
    if currentRunes >= 2 and
       festeringWoundTargets < currentAoETargets and
       festeringWoundCount < settings.rotationSettings.festeringWoundThreshold and
       API.CanCast(spells.FESTERING_STRIKE) then
        API.CastSpell(spells.FESTERING_STRIKE)
        return true
    end
    
    -- Pop Festering Wounds with Scourge Strike/Clawing Shadows in DnD
    if (deathAndDecayActive or unholyGroundActive) and
       festeringWoundCount > 0 and
       currentRunes >= 1 then
        
        if talents.hasClawingShadows and API.CanCast(spells.CLAWING_SHADOWS) then
            API.CastSpell(spells.CLAWING_SHADOWS)
            return true
        elseif API.CanCast(spells.SCOURGE_STRIKE) then
            API.CastSpell(spells.SCOURGE_STRIKE)
            return true
        end
    end
    
    -- Use Festering Strike to apply wounds if we need more
    if currentRunes >= 2 and
       festeringWoundCount < settings.rotationSettings.festeringWoundThreshold and
       API.CanCast(spells.FESTERING_STRIKE) then
        API.CastSpell(spells.FESTERING_STRIKE)
        return true
    end
    
    -- Use Death Coil for spending runic power
    if currentRunicPower >= DEATH_COIL_COST and API.CanCast(spells.DEATH_COIL) then
        -- If Epidemic is enabled and there are enough plagued targets, save RP for Epidemic
        if settings.rotationSettings.useEpidemic and
           virusesTargets >= 2 and
           currentRunicPower < DEATH_COIL_COST + EPIDEMIC_COST then
            -- Skip Death Coil to save for Epidemic
        else
            API.CastSpell(spells.DEATH_COIL)
            return true
        end
    end
    
    -- Use Scourge Strike/Clawing Shadows as a filler
    if currentRunes >= 1 then
        if talents.hasClawingShadows and API.CanCast(spells.CLAWING_SHADOWS) then
            API.CastSpell(spells.CLAWING_SHADOWS)
            return true
        elseif API.CanCast(spells.SCOURGE_STRIKE) then
            API.CastSpell(spells.SCOURGE_STRIKE)
            return true
        end
    end
    
    return false
end

-- Handle Single Target rotation
function Unholy:HandleSingleTargetRotation(settings)
    -- Use Soul Reaper on execute phase targets
    if talents.hasSoulReaper and
       settings.offensiveSettings.useSoulReaper and
       API.GetTargetHealthPercent() <= SOUL_REAPER_EXECUTE_PCT and
       API.CanCast(spells.SOUL_REAPER) then
        API.CastSpell(spells.SOUL_REAPER)
        return true
    end
    
    -- Use Death Coil with Sudden Doom proc
    if suddenDoomProc and API.CanCast(spells.DEATH_COIL) then
        API.CastSpell(spells.DEATH_COIL)
        return true
    end
    
    -- Death and Decay for Unholy Ground or other benefits
    if not deathAndDecayActive and
       currentRunes >= 1 and
       (API.CanCast(spells.DEATH_AND_DECAY) or (talents.hasDefile and API.CanCast(spells.DEFILE))) then
        
        -- Consider settings
        if settings.advancedSettings.deathAndDecayUsage == "Always" or
           (settings.advancedSettings.deathAndDecayUsage == "Only with Unholy Ground" and talents.hasUnholyGround) then
            
            if talents.hasDefile and API.CanCast(spells.DEFILE) then
                API.CastSpellAtCursor(spells.DEFILE)
                return true
            else
                API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
                return true
            end
        end
    end
    
    -- Use Death Coil to dump runic power
    if currentRunicPower >= settings.advancedSettings.runicPowerThresholdDeathCoil and
       API.CanCast(spells.DEATH_COIL) then
        -- Skip if saving RP for something special
        if not (talents.hasSummonGargoyle and
                settings.advancedSettings.poolForGargoyle and
                not API.GetSpellCooldownRemaining(spells.SUMMON_GARGOYLE) > 10 and
                currentRunicPower < 90) then
            API.CastSpell(spells.DEATH_COIL)
            return true
        end
    end
    
    -- Apply Festering Wounds with Festering Strike
    if currentRunes >= 2 and
       festeringWoundCount < settings.rotationSettings.festeringWoundThreshold and
       API.CanCast(spells.FESTERING_STRIKE) then
        API.CastSpell(spells.FESTERING_STRIKE)
        return true
    end
    
    -- Burst Festering Wounds with Scourge Strike/Clawing Shadows
    if festeringWoundCount >= settings.rotationSettings.festeringWoundThreshold and
       currentRunes >= 1 then
        
        if talents.hasClawingShadows and API.CanCast(spells.CLAWING_SHADOWS) then
            API.CastSpell(spells.CLAWING_SHADOWS)
            return true
        elseif API.CanCast(spells.SCOURGE_STRIKE) then
            API.CastSpell(spells.SCOURGE_STRIKE)
            return true
        end
    end
    
    -- Use Death Coil as a filler
    if currentRunicPower >= DEATH_COIL_COST and
       currentRunicPower >= settings.advancedSettings.reserveRunicPower and
       API.CanCast(spells.DEATH_COIL) then
        API.CastSpell(spells.DEATH_COIL)
        return true
    end
    
    -- Use any available runes on Scourge Strike/Clawing Shadows as a filler
    if currentRunes >= 1 then
        if talents.hasClawingShadows and API.CanCast(spells.CLAWING_SHADOWS) then
            API.CastSpell(spells.CLAWING_SHADOWS)
            return true
        elseif API.CanCast(spells.SCOURGE_STRIKE) then
            API.CastSpell(spells.SCOURGE_STRIKE)
            return true
        end
    end
    
    return false
end

-- Handle specialization change
function Unholy:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentRunicPower = API.GetPlayerPower()
    maxRunicPower = 100
    festeringWoundCount = 0
    festeringWoundMaxed = false
    virusesActive = false
    virusesTargets = 0
    festeringWoundTargets = 0
    deathAndDecayActive = false
    deathAndDecayRemaining = 0
    abominationLimbActive = false
    darkTransformationActive = false
    darkTransformationRemaining = 0
    unholyAssaultActive = false
    apocalypseOnCooldown = false
    apocalypseCooldownRemaining = 0
    armyOfTheDeadOnCooldown = false
    armyOfTheDeadCooldownRemaining = 0
    ghoulActive = false
    ghoulSummonedTime = 0
    currentRunes = 0
    bloodPlague = false
    dndBuffActive = false
    unholyBlight = false
    abominationLimbOnCooldown = false
    armyOfTheDamnedProc = false
    suddenDoomProc = false
    runeForgeBearerActivated = false
    unholyGroundActive = false
    corruptedClawsActive = false
    unholyPact = false
    corpsesProliferated = false
    inMeleeRange = false
    petActive = API.HasActivePet()
    deathsPromiseProcActive = false
    magusOfTheDeadActive = false
    reanimatedStacks = 0
    festeringWoundStacks = 0
    eruptingPostulesStacks = 0
    pestilenceVictims = 0
    infectedClawsActive = false
    coilOfDevastation = false
    harbingerOfDoomActive = false
    pestilentPustulesActive = false
    deathRotProc = false
    
    -- Clear target data
    self.targetData = {}
    
    API.PrintDebug("Unholy Death Knight state reset on spec change")
    
    return true
end

-- Return the module for loading
return Unholy