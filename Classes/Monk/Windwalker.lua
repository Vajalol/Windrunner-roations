------------------------------------------
-- WindrunnerRotations - Windwalker Monk Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Windwalker = {}
-- This will be assigned to addon.Classes.Monk.Windwalker when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Monk

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentChi = 0
local maxChi = 5
local currentEnergy = 100
local maxEnergy = 100
local comboStrike = false
local lastUsedAbility = nil
local tearOfMorningActive = false
local tearOfMorningEndTime = 0
local tearOfMorningStacks = 0
local hitComboActive = false
local hitComboEndTime = 0
local hitComboStacks = 0
local serenityActive = false
local serenityEndTime = 0
local stormEarthAndFireActive = false
local stormEarthAndFireEndTime = 0
local stormEarthAndFireCharges = 0
local stormEarthAndFireMaxCharges = 0
local evokersBoonActive = false
local evokersBoonEndTime = 0
local touchOfKarmaActive = false
local touchOfKarmaEndTime = 0
local dancingEmberActive = false
local dancingEmberEndTime = 0
local chiBurst = false
local chiWave = false
local invokeXuenActive = false
local invokeXuenEndTime = 0
local tigerPalmActive = false
local tigerPalmEndTime = 0
local blackoutKickActive = false
local blackoutKickEndTime = 0
local risingSunKickActive = false
local risingSunKickEndTime = 0
local fistOfTheWhiteTigerActive = false
local fistOfTheWhiteTigerEndTime = 0
local fistOfTheWhiteTiger = false
local spinningCraneKickActive = false
local spinningCraneKickEndTime = 0
local whirlingDragonPunchActive = false
local whirlingDragonPunchEndTime = 0
local strikeOfTheWindlordActive = false
local strikeOfTheWindlordEndTime = 0
local flyingSerpentKickActive = false
local flyingSerpentKickEndTime = 0
local faelineStompActive = false
local faelineStompEndTime = 0
local shadowboxingTreadsActive = false
local shadowboxingTreadsStacks = 0
local teachingsOfTheMonasteryActive = false
local teachingsOfTheMonasteryStacks = 0
local powerStrikesActive = false
local markOfTheCraneActive = false
local markOfTheCraneStacks = 0
local strengthOfSpiritActive = false
local strengthOfSpiritStacks = 0
local tigerLustActive = false
local tigerLustEndTime = 0
local fortifyingBrewActive = false
local fortifyingBrewEndTime = 0
local dampenHarmActive = false
local dampenHarmEndTime = 0
local touchOfDeathActive = false
local diffuseMagicActive = false
local diffuseMagicEndTime = 0
local invokeXuen = false
local serenity = false
local stormEarthAndFire = false
local shadowboxingTreads = false
local blackoutReinforcementActive = false
local blackoutReinforcementEndTime = 0
local blackoutReinforcementStacks = 0
local markOfTheCrane = false
local tigerPalm = false
local blackoutKick = false
local risingSunKick = false
local spinningCraneKick = false
local strikeOfTheWindlord = false
local fistsOfFury = false
local flyingSerpentKick = false
local whirlingDragonPunch = false
local touchOfDeath = false
local chiTorpedo = false
local fortifyingBrew = false
local dampenHarm = false
local diffuseMagic = false
local tigersTail = false
local tigersLust = false
local transcendence = false
local transcendenceTransfer = false
local detox = false
local legSweep = false
local paralysis = false
local pressurePoint = false
local xuentsBattlegear = false
local danceOfChiJi = false
local danceOfChiJiActive = false
local danceOfChiJiEndTime = 0
local skyreachExhaustion = false
local empyreanLegacy = false
local empyreanLegacyActive = false
local empyreanLegacyEndTime = 0
local faeline = false
local cracklingJadeLightning = false
local boneDustBrew = false
local boneDustBrewActive = false
local boneDustBrewEndTime = 0
local lastTigerPalm = 0
local lastBlackoutKick = 0
local lastRisingSunKick = 0
local lastFistOfTheWhiteTiger = 0
local lastSpinningCraneKick = 0
local lastStrikeOfTheWindlord = 0
local lastFistsOfFury = 0
local lastFlyingSerpentKick = 0
local lastWhirlingDragonPunch = 0
local lastTouchOfDeath = 0
local lastChiBurst = 0
local lastChiWave = 0
local lastStormEarthAndFire = 0
local lastSerenity = 0
local lastInvokeXuen = 0
local lastTouchOfKarma = 0
local lastFaeline = 0
local lastLegSweep = 0
local lastParalysis = 0
local lastDetox = 0
local lastTigerLust = 0
local lastFortifyingBrew = 0
local lastDampenHarm = 0
local lastDiffuseMagic = 0
local lastTranscendence = 0
local lastTranscendenceTransfer = 0
local lastBoneDustBrew = 0
local lastCracklingJadeLightning = 0
local playerHealth = 100
local targetHealth = 100
local activeEnemies = 0
local isInMelee = false
local meleeRange = 5 -- yards
local hasStackOfMark = {}

-- Constants
local WINDWALKER_SPEC_ID = 269
local SERENITY_DURATION = 12.0 -- seconds
local STORM_EARTH_AND_FIRE_DURATION = 15.0 -- seconds
local TOUCH_OF_KARMA_DURATION = 10.0 -- seconds
local TOUCH_OF_DEATH_COOLDOWN = 120.0 -- seconds
local INVOKE_XUEN_DURATION = 24.0 -- seconds
local TIGER_LUST_DURATION = 6.0 -- seconds
local FORTIFYING_BREW_DURATION = 15.0 -- seconds
local DAMPEN_HARM_DURATION = 10.0 -- seconds
local DIFFUSE_MAGIC_DURATION = 6.0 -- seconds
local DANCING_EMBER_DURATION = 15.0 -- seconds
local BLACKOUT_REINFORCEMENT_DURATION = 60.0 -- seconds
local DANCE_OF_CHIJI_DURATION = 15.0 -- seconds
local EMPYREAN_LEGACY_DURATION = 45.0 -- seconds
local BONE_DUST_BREW_DURATION = 10.0 -- seconds
local FAELINE_STOMP_DURATION = 30.0 -- seconds

-- Initialize the Windwalker module
function Windwalker:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Windwalker Monk module initialized")
    
    return true
end

-- Register spell IDs
function Windwalker:RegisterSpells()
    -- Core abilities
    spells.TIGER_PALM = 100780
    spells.BLACKOUT_KICK = 100784
    spells.RISING_SUN_KICK = 107428
    spells.FISTS_OF_FURY = 113656
    spells.SPINNING_CRANE_KICK = 101546
    spells.FLYING_SERPENT_KICK = 101545
    spells.TOUCH_OF_DEATH = 115080
    spells.STORM_EARTH_AND_FIRE = 137639
    spells.CRACKLING_JADE_LIGHTNING = 117952
    
    -- Talents and passives
    spells.COMBO_STRIKES = 115636
    spells.MASTERY_COMBO_STRIKES = 115636
    spells.EVOKERS_BOON = 415638
    spells.DANCE_OF_CHIJI = 325201
    spells.CHI_BURST = 123986
    spells.CHI_WAVE = 115098
    spells.TOUCH_OF_KARMA = 122470
    spells.FIST_OF_THE_WHITE_TIGER = 261947
    spells.HIT_COMBO = 196740
    spells.SERENITY = 152173
    spells.INVOKE_XUEN = 123904
    spells.WHIRLING_DRAGON_PUNCH = 152175
    spells.STRIKE_OF_THE_WINDLORD = 392983
    spells.SHADOWBOXING_TREADS = 392982
    spells.MARK_OF_THE_CRANE = 220357
    spells.TEACHINGS_OF_THE_MONASTERY = 116645
    spells.POWER_STRIKES = 121817
    spells.STRENGTH_OF_SPIRIT = 387276
    spells.CHI_TORPEDO = 115008
    spells.FORTIFYING_BREW = 243435
    spells.DAMPEN_HARM = 122278
    spells.DIFFUSE_MAGIC = 122783
    spells.TIGERS_TAIL = 264348
    spells.TIGERS_LUST = 116841
    spells.TRANSCENDENCE = 101643
    spells.TRANSCENDENCE_TRANSFER = 119996
    spells.DETOX = 218164
    spells.LEG_SWEEP = 119381
    spells.PARALYSIS = 115078
    spells.PRESSURE_POINT = 337482
    spells.XUENS_BATTLEGEAR = 392993
    spells.SKYREACH_EXHAUSTION = 393050
    spells.BLACKOUT_REINFORCEMENT = 424454
    spells.TEAR_OF_MORNING = 209042
    spells.EMPYREAN_LEGACY = 418361
    spells.FAELINE_STOMP = 388193
    spells.BONE_DUST_BREW = 386276
    
    -- War Within Season 2 specific
    spells.DANCING_EMBER = 397734
    
    -- Buff IDs
    spells.COMBO_STRIKES_BUFF = 115636
    spells.EVOKERS_BOON_BUFF = 415638
    spells.DANCE_OF_CHIJI_BUFF = 325201
    spells.TOUCH_OF_KARMA_BUFF = 122470
    spells.SERENITY_BUFF = 152173
    spells.STORM_EARTH_AND_FIRE_BUFF = 137639
    spells.HIT_COMBO_BUFF = 196741
    spells.TEACHINGS_OF_THE_MONASTERY_BUFF = 202090
    spells.POWER_STRIKES_BUFF = 129914
    spells.MARK_OF_THE_CRANE_BUFF = 228287
    spells.STRENGTH_OF_SPIRIT_BUFF = 387276
    spells.TIGERS_LUST_BUFF = 116841
    spells.FORTIFYING_BREW_BUFF = 243435
    spells.DAMPEN_HARM_BUFF = 122278
    spells.DIFFUSE_MAGIC_BUFF = 122783
    spells.DANCING_EMBER_BUFF = 397734
    spells.BLACKOUT_REINFORCEMENT_BUFF = 424454
    spells.TEAR_OF_MORNING_BUFF = 209042
    spells.EMPYREAN_LEGACY_BUFF = 418361
    spells.FAELINE_STOMP_BUFF = 388193
    spells.BONE_DUST_BREW_BUFF = 386276
    
    -- Debuff IDs
    spells.MYSTIC_TOUCH_DEBUFF = 113746
    spells.RECENTLY_USED_COMBO_STRIKE = 394945
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.COMBO_STRIKES = spells.COMBO_STRIKES_BUFF
    buffs.EVOKERS_BOON = spells.EVOKERS_BOON_BUFF
    buffs.DANCE_OF_CHIJI = spells.DANCE_OF_CHIJI_BUFF
    buffs.TOUCH_OF_KARMA = spells.TOUCH_OF_KARMA_BUFF
    buffs.SERENITY = spells.SERENITY_BUFF
    buffs.STORM_EARTH_AND_FIRE = spells.STORM_EARTH_AND_FIRE_BUFF
    buffs.HIT_COMBO = spells.HIT_COMBO_BUFF
    buffs.TEACHINGS_OF_THE_MONASTERY = spells.TEACHINGS_OF_THE_MONASTERY_BUFF
    buffs.POWER_STRIKES = spells.POWER_STRIKES_BUFF
    buffs.MARK_OF_THE_CRANE = spells.MARK_OF_THE_CRANE_BUFF
    buffs.STRENGTH_OF_SPIRIT = spells.STRENGTH_OF_SPIRIT_BUFF
    buffs.TIGERS_LUST = spells.TIGERS_LUST_BUFF
    buffs.FORTIFYING_BREW = spells.FORTIFYING_BREW_BUFF
    buffs.DAMPEN_HARM = spells.DAMPEN_HARM_BUFF
    buffs.DIFFUSE_MAGIC = spells.DIFFUSE_MAGIC_BUFF
    buffs.DANCING_EMBER = spells.DANCING_EMBER_BUFF
    buffs.BLACKOUT_REINFORCEMENT = spells.BLACKOUT_REINFORCEMENT_BUFF
    buffs.TEAR_OF_MORNING = spells.TEAR_OF_MORNING_BUFF
    buffs.EMPYREAN_LEGACY = spells.EMPYREAN_LEGACY_BUFF
    buffs.FAELINE_STOMP = spells.FAELINE_STOMP_BUFF
    buffs.BONE_DUST_BREW = spells.BONE_DUST_BREW_BUFF
    
    debuffs.MYSTIC_TOUCH = spells.MYSTIC_TOUCH_DEBUFF
    debuffs.RECENTLY_USED_COMBO_STRIKE = spells.RECENTLY_USED_COMBO_STRIKE
    
    return true
end

-- Register variables to track
function Windwalker:RegisterVariables()
    -- Talent tracking
    talents.hasTearOfMorning = false
    talents.hasHitCombo = false
    talents.hasSerenity = false
    talents.hasStormEarthAndFire = false
    talents.hasEvokersBoon = false
    talents.hasTouchOfKarma = false
    talents.hasDancingEmber = false
    talents.hasChiBurst = false
    talents.hasChiWave = false
    talents.hasInvokeXuen = false
    talents.hasFistOfTheWhiteTiger = false
    talents.hasSpinningCraneKick = false
    talents.hasWhirlingDragonPunch = false
    talents.hasStrikeOfTheWindlord = false
    talents.hasShadowboxingTreads = false
    talents.hasMarkOfTheCrane = false
    talents.hasTeachingsOfTheMonastery = false
    talents.hasPowerStrikes = false
    talents.hasStrengthOfSpirit = false
    talents.hasChiTorpedo = false
    talents.hasFortifyingBrew = false
    talents.hasDampenHarm = false
    talents.hasDiffuseMagic = false
    talents.hasTigersTail = false
    talents.hasTigersLust = false
    talents.hasTranscendence = false
    talents.hasDetox = false
    talents.hasLegSweep = false
    talents.hasParalysis = false
    talents.hasPressurePoint = false
    talents.hasXuentsBattlegear = false
    talents.hasDanceOfChiJi = false
    talents.hasSkyreachExhaustion = false
    talents.hasBlackoutReinforcement = false
    talents.hasEmpyreanLegacy = false
    talents.hasFaeline = false
    talents.hasBoneDustBrew = false
    
    -- Initialize resources
    currentChi = API.GetPlayerPower() or 0
    maxChi = 5 -- Default, could be higher with talents
    currentEnergy = API.GetPlayerEnergy() or 100
    maxEnergy = API.GetPlayerMaxEnergy() or 100
    
    -- Initialize Storm, Earth, and Fire charges
    if talents.hasStormEarthAndFire then
        stormEarthAndFireCharges, stormEarthAndFireMaxCharges = API.GetSpellCharges(spells.STORM_EARTH_AND_FIRE) or 0, 2
    end
    
    -- Initialize tracking for Marks
    hasStackOfMark = {}
    
    return true
end

-- Register spec-specific settings
function Windwalker:RegisterSettings()
    ConfigRegistry:RegisterSettings("WindwalkerMonk", {
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
            chiPooling = {
                displayName = "Chi Pooling",
                description = "Pool Chi for upcoming abilities",
                type = "toggle",
                default = true
            },
            chiPoolingThreshold = {
                displayName = "Chi Pooling Threshold",
                description = "Minimum Chi to maintain",
                type = "slider",
                min = 1,
                max = 4,
                default = 2
            },
            energyPooling = {
                displayName = "Energy Pooling",
                description = "Pool Energy for optimal ability usage",
                type = "toggle",
                default = true
            },
            energyPoolingThreshold = {
                displayName = "Energy Pooling Threshold",
                description = "Minimum Energy to maintain",
                type = "slider",
                min = 10,
                max = 80,
                default = 30
            },
            maintainComboStrikes = {
                displayName = "Maintain Combo Strikes",
                description = "Optimize rotation to maintain Combo Strikes",
                type = "toggle",
                default = true
            },
            maintainHitCombo = {
                displayName = "Maintain Hit Combo",
                description = "Optimize rotation to maintain Hit Combo stacks",
                type = "toggle",
                default = true
            },
            optimizeMarkOfTheCrane = {
                displayName = "Optimize Mark of the Crane",
                description = "Maintain Mark of the Crane on multiple targets",
                type = "toggle",
                default = true
            },
            optimizeMarkOfTheCraneThreshold = {
                displayName = "Mark of the Crane Target Threshold",
                description = "Minimum number of targets to maintain Mark of the Crane",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            fistsOfFuryStyle = {
                displayName = "Fists of Fury Usage",
                description = "How to use Fists of Fury",
                type = "dropdown",
                options = {"On Cooldown", "Chi Dump", "With Cooldowns", "Manual Only"},
                default = "On Cooldown"
            },
            touchOfDeathMode = {
                displayName = "Touch of Death Usage",
                description = "When to use Touch of Death",
                type = "dropdown",
                options = {"On Cooldown", "Execute Only", "Burst Only", "Manual Only"},
                default = "On Cooldown"
            }
        },
        
        serenitySettings = {
            useSerenity = {
                displayName = "Use Serenity",
                description = "Automatically use Serenity when talented",
                type = "toggle",
                default = true
            },
            serenityMode = {
                displayName = "Serenity Usage",
                description = "When to use Serenity",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "With Cooldowns"
            },
            prepareChi = {
                displayName = "Prepare Chi for Serenity",
                description = "Ensure high Chi before using Serenity",
                type = "toggle",
                default = true
            },
            serenityPriorityRSK = {
                displayName = "Prioritize RSK During Serenity",
                description = "Prioritize Rising Sun Kick during Serenity",
                type = "toggle",
                default = true
            },
            useStrikeOfTheWindlordDuringSerenity = {
                displayName = "Use SotW During Serenity",
                description = "Use Strike of the Windlord during Serenity",
                type = "toggle",
                default = true
            }
        },
        
        stormEarthAndFireSettings = {
            useSEF = {
                displayName = "Use Storm, Earth, and Fire",
                description = "Automatically use Storm, Earth, and Fire when talented",
                type = "toggle",
                default = true
            },
            sefMode = {
                displayName = "SEF Usage",
                description = "When to use Storm, Earth, and Fire",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "With Cooldowns"
            },
            prepareChi = {
                displayName = "Prepare Chi for SEF",
                description = "Ensure high Chi before using Storm, Earth, and Fire",
                type = "toggle",
                default = true
            },
            sefSaveCharge = {
                displayName = "Save One SEF Charge",
                description = "Always keep one charge of Storm, Earth, and Fire",
                type = "toggle",
                default = false
            }
        },
        
        cooldownSettings = {
            useInvokeXuen = {
                displayName = "Use Invoke Xuen",
                description = "Automatically use Invoke Xuen when talented",
                type = "toggle",
                default = true
            },
            invokeXuenMode = {
                displayName = "Invoke Xuen Usage",
                description = "When to use Invoke Xuen",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "Boss Only", "Manual Only"},
                default = "With Cooldowns"
            },
            useTouchOfKarma = {
                displayName = "Use Touch of Karma",
                description = "Automatically use Touch of Karma",
                type = "toggle",
                default = true
            },
            touchOfKarmaMode = {
                displayName = "Touch of Karma Usage",
                description = "When to use Touch of Karma",
                type = "dropdown",
                options = {"On Cooldown", "When Taking Damage", "For Damage Only", "Manual Only"},
                default = "When Taking Damage"
            },
            touchOfKarmaThreshold = {
                displayName = "Touch of Karma Health Threshold",
                description = "Health percentage to use Touch of Karma",
                type = "slider",
                min = 20,
                max = 90,
                default = 70
            },
            useBoneDustBrew = {
                displayName = "Use Bonedust Brew",
                description = "Automatically use Bonedust Brew when talented",
                type = "toggle",
                default = true
            },
            boneDustBrewMode = {
                displayName = "Bonedust Brew Usage",
                description = "When to use Bonedust Brew",
                type = "dropdown",
                options = {"On Cooldown", "With Cooldowns", "AoE Only", "Manual Only"},
                default = "With Cooldowns"
            },
            boneDustBrewAoEThreshold = {
                displayName = "Bonedust Brew AoE Target Threshold",
                description = "Minimum number of targets to use Bonedust Brew in AoE",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            }
        },
        
        defensiveSettings = {
            useFortifyingBrew = {
                displayName = "Use Fortifying Brew",
                description = "Automatically use Fortifying Brew",
                type = "toggle",
                default = true
            },
            fortifyingBrewThreshold = {
                displayName = "Fortifying Brew Health Threshold",
                description = "Health percentage to use Fortifying Brew",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useDampenHarm = {
                displayName = "Use Dampen Harm",
                description = "Automatically use Dampen Harm when talented",
                type = "toggle",
                default = true
            },
            dampenHarmThreshold = {
                displayName = "Dampen Harm Health Threshold",
                description = "Health percentage to use Dampen Harm",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useDiffuseMagic = {
                displayName = "Use Diffuse Magic",
                description = "Automatically use Diffuse Magic when talented",
                type = "toggle",
                default = true
            },
            diffuseMagicThreshold = {
                displayName = "Diffuse Magic Health Threshold",
                description = "Health percentage to use Diffuse Magic",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useTigersLust = {
                displayName = "Use Tiger's Lust",
                description = "Automatically use Tiger's Lust when talented",
                type = "toggle",
                default = true
            },
            tigersLustMode = {
                displayName = "Tiger's Lust Usage",
                description = "How to use Tiger's Lust",
                type = "dropdown",
                options = {"Self Only", "Group Members", "Manual Only"},
                default = "Self Only"
            }
        },
        
        utilitySettings = {
            useDetox = {
                displayName = "Use Detox",
                description = "Automatically Detox harmful effects",
                type = "toggle",
                default = true
            },
            useParalysis = {
                displayName = "Use Paralysis",
                description = "Automatically use Paralysis for crowd control",
                type = "toggle",
                default = true
            },
            useLegSweep = {
                displayName = "Use Leg Sweep",
                description = "Automatically use Leg Sweep for AoE stun",
                type = "toggle",
                default = true
            },
            legSweepMinTargets = {
                displayName = "Leg Sweep Min Targets",
                description = "Minimum number of targets to use Leg Sweep",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useTranscendence = {
                displayName = "Use Transcendence",
                description = "Automatically use Transcendence",
                type = "toggle",
                default = true
            },
            transcendenceMode = {
                displayName = "Transcendence Usage",
                description = "How to use Transcendence",
                type = "dropdown",
                options = {"Place on Cooldown", "Transfer When Low Health", "Manual Only"},
                default = "Manual Only"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Fists of Fury controls
            fistsOfFury = AAC.RegisterAbility(spells.FISTS_OF_FURY, {
                enabled = true,
                useDuringBurstOnly = false,
                minChi = 3,
                requireSerenity = false
            }),
            
            -- Rising Sun Kick controls
            risingSunKick = AAC.RegisterAbility(spells.RISING_SUN_KICK, {
                enabled = true,
                useDuringBurstOnly = false,
                minChi = 2,
                priorityDuringSerenity = true
            }),
            
            -- Spinning Crane Kick controls
            spinningCraneKick = AAC.RegisterAbility(spells.SPINNING_CRANE_KICK, {
                enabled = true,
                useDuringBurstOnly = false,
                minChi = 2,
                minTargets = 3,
                requireMarkOfTheCrane = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Windwalker:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for chi updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "CHI" then
            self:UpdateChi()
        end
    end)
    
    -- Register for energy updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "ENERGY" then
            self:UpdateEnergy()
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
    
    -- Register for SEF charge updates
    API.RegisterEvent("SPELL_UPDATE_CHARGES", function(spellID) 
        if spellID == spells.STORM_EARTH_AND_FIRE then
            self:UpdateSEFCharges()
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial SEF charges update
    if talents.hasStormEarthAndFire then
        self:UpdateSEFCharges()
    end
    
    return true
end

-- Update talent information
function Windwalker:UpdateTalentInfo()
    -- Check for important talents
    talents.hasTearOfMorning = API.HasTalent(spells.TEAR_OF_MORNING)
    talents.hasHitCombo = API.HasTalent(spells.HIT_COMBO)
    talents.hasSerenity = API.HasTalent(spells.SERENITY)
    talents.hasStormEarthAndFire = API.HasTalent(spells.STORM_EARTH_AND_FIRE)
    talents.hasEvokersBoon = API.HasTalent(spells.EVOKERS_BOON)
    talents.hasTouchOfKarma = API.HasTalent(spells.TOUCH_OF_KARMA)
    talents.hasDancingEmber = API.HasTalent(spells.DANCING_EMBER)
    talents.hasChiBurst = API.HasTalent(spells.CHI_BURST)
    talents.hasChiWave = API.HasTalent(spells.CHI_WAVE)
    talents.hasInvokeXuen = API.HasTalent(spells.INVOKE_XUEN)
    talents.hasFistOfTheWhiteTiger = API.HasTalent(spells.FIST_OF_THE_WHITE_TIGER)
    talents.hasSpinningCraneKick = API.HasTalent(spells.SPINNING_CRANE_KICK)
    talents.hasWhirlingDragonPunch = API.HasTalent(spells.WHIRLING_DRAGON_PUNCH)
    talents.hasStrikeOfTheWindlord = API.HasTalent(spells.STRIKE_OF_THE_WINDLORD)
    talents.hasShadowboxingTreads = API.HasTalent(spells.SHADOWBOXING_TREADS)
    talents.hasMarkOfTheCrane = API.HasTalent(spells.MARK_OF_THE_CRANE)
    talents.hasTeachingsOfTheMonastery = API.HasTalent(spells.TEACHINGS_OF_THE_MONASTERY)
    talents.hasPowerStrikes = API.HasTalent(spells.POWER_STRIKES)
    talents.hasStrengthOfSpirit = API.HasTalent(spells.STRENGTH_OF_SPIRIT)
    talents.hasChiTorpedo = API.HasTalent(spells.CHI_TORPEDO)
    talents.hasFortifyingBrew = API.HasTalent(spells.FORTIFYING_BREW)
    talents.hasDampenHarm = API.HasTalent(spells.DAMPEN_HARM)
    talents.hasDiffuseMagic = API.HasTalent(spells.DIFFUSE_MAGIC)
    talents.hasTigersTail = API.HasTalent(spells.TIGERS_TAIL)
    talents.hasTigersLust = API.HasTalent(spells.TIGERS_LUST)
    talents.hasTranscendence = API.HasTalent(spells.TRANSCENDENCE)
    talents.hasDetox = API.HasTalent(spells.DETOX)
    talents.hasLegSweep = API.HasTalent(spells.LEG_SWEEP)
    talents.hasParalysis = API.HasTalent(spells.PARALYSIS)
    talents.hasPressurePoint = API.HasTalent(spells.PRESSURE_POINT)
    talents.hasXuentsBattlegear = API.HasTalent(spells.XUENS_BATTLEGEAR)
    talents.hasDanceOfChiJi = API.HasTalent(spells.DANCE_OF_CHIJI)
    talents.hasSkyreachExhaustion = API.HasTalent(spells.SKYREACH_EXHAUSTION)
    talents.hasBlackoutReinforcement = API.HasTalent(spells.BLACKOUT_REINFORCEMENT)
    talents.hasEmpyreanLegacy = API.HasTalent(spells.EMPYREAN_LEGACY)
    talents.hasFaeline = API.HasTalent(spells.FAELINE_STOMP)
    talents.hasBoneDustBrew = API.HasTalent(spells.BONE_DUST_BREW)
    
    -- Set specialized variables based on talents
    if talents.hasTearOfMorning then
        tearOfMorning = true
    end
    
    if talents.hasHitCombo then
        hitCombo = true
    end
    
    if talents.hasSerenity then
        serenity = true
    end
    
    if talents.hasStormEarthAndFire then
        stormEarthAndFire = true
    end
    
    if talents.hasEvokersBoon then
        evokersBoon = true
    end
    
    if talents.hasTouchOfKarma then
        touchOfKarma = true
    end
    
    if talents.hasDancingEmber then
        dancingEmber = true
    end
    
    if talents.hasChiBurst then
        chiBurst = true
    end
    
    if talents.hasChiWave then
        chiWave = true
    end
    
    if talents.hasInvokeXuen then
        invokeXuen = true
    end
    
    if talents.hasFistOfTheWhiteTiger then
        fistOfTheWhiteTiger = true
    end
    
    if talents.hasSpinningCraneKick then
        spinningCraneKick = true
    end
    
    if talents.hasWhirlingDragonPunch then
        whirlingDragonPunch = true
    end
    
    if talents.hasStrikeOfTheWindlord then
        strikeOfTheWindlord = true
    end
    
    if talents.hasShadowboxingTreads then
        shadowboxingTreads = true
    end
    
    if talents.hasMarkOfTheCrane then
        markOfTheCrane = true
    end
    
    if talents.hasTeachingsOfTheMonastery then
        teachingsOfTheMonastery = true
    end
    
    if talents.hasPowerStrikes then
        powerStrikes = true
    end
    
    if talents.hasStrengthOfSpirit then
        strengthOfSpirit = true
    end
    
    if talents.hasChiTorpedo then
        chiTorpedo = true
    end
    
    if talents.hasFortifyingBrew then
        fortifyingBrew = true
    end
    
    if talents.hasDampenHarm then
        dampenHarm = true
    end
    
    if talents.hasDiffuseMagic then
        diffuseMagic = true
    end
    
    if talents.hasTigersTail then
        tigersTail = true
    end
    
    if talents.hasTigersLust then
        tigersLust = true
    end
    
    if talents.hasTranscendence then
        transcendence = true
    end
    
    if talents.hasDetox then
        detox = true
    end
    
    if talents.hasLegSweep then
        legSweep = true
    end
    
    if talents.hasParalysis then
        paralysis = true
    end
    
    if talents.hasPressurePoint then
        pressurePoint = true
    end
    
    if talents.hasXuentsBattlegear then
        xuentsBattlegear = true
    end
    
    if talents.hasDanceOfChiJi then
        danceOfChiJi = true
    end
    
    if talents.hasSkyreachExhaustion then
        skyreachExhaustion = true
    end
    
    if talents.hasBlackoutReinforcement then
        blackoutReinforcement = true
    end
    
    if talents.hasEmpyreanLegacy then
        empyreanLegacy = true
    end
    
    if talents.hasFaeline then
        faeline = true
    end
    
    if talents.hasBoneDustBrew then
        boneDustBrew = true
    end
    
    if API.IsSpellKnown(spells.TIGER_PALM) then
        tigerPalm = true
    end
    
    if API.IsSpellKnown(spells.BLACKOUT_KICK) then
        blackoutKick = true
    end
    
    if API.IsSpellKnown(spells.RISING_SUN_KICK) then
        risingSunKick = true
    end
    
    if API.IsSpellKnown(spells.SPINNING_CRANE_KICK) then
        spinningCraneKick = true
    end
    
    if API.IsSpellKnown(spells.STRIKE_OF_THE_WINDLORD) then
        strikeOfTheWindlord = true
    end
    
    if API.IsSpellKnown(spells.FISTS_OF_FURY) then
        fistsOfFury = true
    end
    
    if API.IsSpellKnown(spells.FLYING_SERPENT_KICK) then
        flyingSerpentKick = true
    end
    
    if API.IsSpellKnown(spells.TOUCH_OF_DEATH) then
        touchOfDeath = true
    end
    
    if API.IsSpellKnown(spells.CRACKLING_JADE_LIGHTNING) then
        cracklingJadeLightning = true
    end
    
    API.PrintDebug("Windwalker Monk talents updated")
    
    return true
end

-- Update chi tracking
function Windwalker:UpdateChi()
    currentChi = API.GetPlayerPower()
    return true
end

-- Update energy tracking
function Windwalker:UpdateEnergy()
    currentEnergy = API.GetPlayerEnergy()
    maxEnergy = API.GetPlayerMaxEnergy()
    return true
end

-- Update health tracking
function Windwalker:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update target health tracking
function Windwalker:UpdateTargetHealth()
    targetHealth = API.GetTargetHealthPercent()
    return true
end

-- Update Storm, Earth, and Fire charges
function Windwalker:UpdateSEFCharges()
    if talents.hasStormEarthAndFire then
        stormEarthAndFireCharges, stormEarthAndFireMaxCharges = API.GetSpellCharges(spells.STORM_EARTH_AND_FIRE)
    end
    return true
end

-- Update active enemy counts
function Windwalker:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Check if unit is in melee range
function Windwalker:IsInMeleeRange(unit)
    if not unit or not API.UnitExists(unit) then
        return false
    end
    
    return API.GetUnitDistance("player", unit) <= meleeRange
end

-- Check if ability would maintain combo strikes
function Windwalker:WouldMaintainComboStrikes(spellID)
    if not lastUsedAbility then
        return true -- First ability in sequence
    end
    
    return spellID ~= lastUsedAbility
end

-- Handle combat log events
function Windwalker:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Serenity application
            if spellID == buffs.SERENITY then
                serenityActive = true
                serenityEndTime = select(6, API.GetBuffInfo("player", buffs.SERENITY))
                API.PrintDebug("Serenity activated")
            end
            
            -- Track Storm, Earth, and Fire application
            if spellID == buffs.STORM_EARTH_AND_FIRE then
                stormEarthAndFireActive = true
                stormEarthAndFireEndTime = select(6, API.GetBuffInfo("player", buffs.STORM_EARTH_AND_FIRE))
                API.PrintDebug("Storm, Earth, and Fire activated")
            end
            
            -- Track Evoker's Boon application
            if spellID == buffs.EVOKERS_BOON then
                evokersBoonActive = true
                evokersBoonEndTime = select(6, API.GetBuffInfo("player", buffs.EVOKERS_BOON))
                API.PrintDebug("Evoker's Boon activated")
            end
            
            -- Track Touch of Karma application
            if spellID == buffs.TOUCH_OF_KARMA then
                touchOfKarmaActive = true
                touchOfKarmaEndTime = select(6, API.GetBuffInfo("player", buffs.TOUCH_OF_KARMA))
                API.PrintDebug("Touch of Karma activated")
            end
            
            -- Track Dancing Ember application
            if spellID == buffs.DANCING_EMBER then
                dancingEmberActive = true
                dancingEmberEndTime = select(6, API.GetBuffInfo("player", buffs.DANCING_EMBER))
                API.PrintDebug("Dancing Ember activated")
            end
            
            -- Track Tiger's Lust application
            if spellID == buffs.TIGERS_LUST then
                tigerLustActive = true
                tigerLustEndTime = select(6, API.GetBuffInfo("player", buffs.TIGERS_LUST))
                API.PrintDebug("Tiger's Lust activated")
            end
            
            -- Track Fortifying Brew application
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = true
                fortifyingBrewEndTime = select(6, API.GetBuffInfo("player", buffs.FORTIFYING_BREW))
                API.PrintDebug("Fortifying Brew activated")
            end
            
            -- Track Dampen Harm application
            if spellID == buffs.DAMPEN_HARM then
                dampenHarmActive = true
                dampenHarmEndTime = select(6, API.GetBuffInfo("player", buffs.DAMPEN_HARM))
                API.PrintDebug("Dampen Harm activated")
            end
            
            -- Track Diffuse Magic application
            if spellID == buffs.DIFFUSE_MAGIC then
                diffuseMagicActive = true
                diffuseMagicEndTime = select(6, API.GetBuffInfo("player", buffs.DIFFUSE_MAGIC))
                API.PrintDebug("Diffuse Magic activated")
            end
            
            -- Track Hit Combo application/stacks
            if spellID == buffs.HIT_COMBO then
                hitComboActive = true
                hitComboEndTime = GetTime() + 30 -- Arbitrary, depends on combat state
                hitComboStacks = select(4, API.GetBuffInfo("player", buffs.HIT_COMBO)) or 1
                API.PrintDebug("Hit Combo stacks: " .. tostring(hitComboStacks))
            end
            
            -- Track Teachings of the Monastery stacks
            if spellID == buffs.TEACHINGS_OF_THE_MONASTERY then
                teachingsOfTheMonasteryActive = true
                teachingsOfTheMonasteryStacks = select(4, API.GetBuffInfo("player", buffs.TEACHINGS_OF_THE_MONASTERY)) or 1
                API.PrintDebug("Teachings of the Monastery stacks: " .. tostring(teachingsOfTheMonasteryStacks))
            end
            
            -- Track Power Strikes buff
            if spellID == buffs.POWER_STRIKES then
                powerStrikesActive = true
                API.PrintDebug("Power Strikes activated")
            end
            
            -- Track Mark of the Crane application (for tracking by target)
            if spellID == buffs.MARK_OF_THE_CRANE and destGUID then
                markOfTheCraneActive = true
                markOfTheCraneStacks = (markOfTheCraneStacks or 0) + 1
                hasStackOfMark[destGUID] = true
                API.PrintDebug("Mark of the Crane applied to " .. destName)
            end
            
            -- Track Strength of Spirit stacks
            if spellID == buffs.STRENGTH_OF_SPIRIT then
                strengthOfSpiritActive = true
                strengthOfSpiritStacks = select(4, API.GetBuffInfo("player", buffs.STRENGTH_OF_SPIRIT)) or 1
                API.PrintDebug("Strength of Spirit stacks: " .. tostring(strengthOfSpiritStacks))
            end
            
            -- Track Blackout Reinforcement application
            if spellID == buffs.BLACKOUT_REINFORCEMENT then
                blackoutReinforcementActive = true
                blackoutReinforcementEndTime = select(6, API.GetBuffInfo("player", buffs.BLACKOUT_REINFORCEMENT))
                blackoutReinforcementStacks = select(4, API.GetBuffInfo("player", buffs.BLACKOUT_REINFORCEMENT)) or 1
                API.PrintDebug("Blackout Reinforcement activated: " .. tostring(blackoutReinforcementStacks) .. " stack(s)")
            end
            
            -- Track Tear of Morning application
            if spellID == buffs.TEAR_OF_MORNING then
                tearOfMorningActive = true
                tearOfMorningEndTime = select(6, API.GetBuffInfo("player", buffs.TEAR_OF_MORNING))
                tearOfMorningStacks = select(4, API.GetBuffInfo("player", buffs.TEAR_OF_MORNING)) or 1
                API.PrintDebug("Tear of Morning activated: " .. tostring(tearOfMorningStacks) .. " stack(s)")
            end
            
            -- Track Dance of Chi-Ji
            if spellID == buffs.DANCE_OF_CHIJI then
                danceOfChiJiActive = true
                danceOfChiJiEndTime = select(6, API.GetBuffInfo("player", buffs.DANCE_OF_CHIJI))
                API.PrintDebug("Dance of Chi-Ji activated")
            end
            
            -- Track Empyrean Legacy
            if spellID == buffs.EMPYREAN_LEGACY then
                empyreanLegacyActive = true
                empyreanLegacyEndTime = select(6, API.GetBuffInfo("player", buffs.EMPYREAN_LEGACY))
                API.PrintDebug("Empyrean Legacy activated")
            end
            
            -- Track Faeline Stomp
            if spellID == buffs.FAELINE_STOMP then
                faelineStompActive = true
                faelineStompEndTime = select(6, API.GetBuffInfo("player", buffs.FAELINE_STOMP))
                API.PrintDebug("Faeline Stomp activated")
            end
            
            -- Track Bone Dust Brew
            if spellID == buffs.BONE_DUST_BREW then
                boneDustBrewActive = true
                boneDustBrewEndTime = select(6, API.GetBuffInfo("player", buffs.BONE_DUST_BREW))
                API.PrintDebug("Bone Dust Brew activated")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Serenity removal
            if spellID == buffs.SERENITY then
                serenityActive = false
                API.PrintDebug("Serenity faded")
            end
            
            -- Track Storm, Earth, and Fire removal
            if spellID == buffs.STORM_EARTH_AND_FIRE then
                stormEarthAndFireActive = false
                API.PrintDebug("Storm, Earth, and Fire faded")
            end
            
            -- Track Evoker's Boon removal
            if spellID == buffs.EVOKERS_BOON then
                evokersBoonActive = false
                API.PrintDebug("Evoker's Boon faded")
            end
            
            -- Track Touch of Karma removal
            if spellID == buffs.TOUCH_OF_KARMA then
                touchOfKarmaActive = false
                API.PrintDebug("Touch of Karma faded")
            end
            
            -- Track Dancing Ember removal
            if spellID == buffs.DANCING_EMBER then
                dancingEmberActive = false
                API.PrintDebug("Dancing Ember faded")
            end
            
            -- Track Tiger's Lust removal
            if spellID == buffs.TIGERS_LUST then
                tigerLustActive = false
                API.PrintDebug("Tiger's Lust faded")
            end
            
            -- Track Fortifying Brew removal
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = false
                API.PrintDebug("Fortifying Brew faded")
            end
            
            -- Track Dampen Harm removal
            if spellID == buffs.DAMPEN_HARM then
                dampenHarmActive = false
                API.PrintDebug("Dampen Harm faded")
            end
            
            -- Track Diffuse Magic removal
            if spellID == buffs.DIFFUSE_MAGIC then
                diffuseMagicActive = false
                API.PrintDebug("Diffuse Magic faded")
            end
            
            -- Track Hit Combo removal
            if spellID == buffs.HIT_COMBO then
                hitComboActive = false
                hitComboStacks = 0
                API.PrintDebug("Hit Combo faded")
            end
            
            -- Track Teachings of the Monastery removal
            if spellID == buffs.TEACHINGS_OF_THE_MONASTERY then
                teachingsOfTheMonasteryActive = false
                teachingsOfTheMonasteryStacks = 0
                API.PrintDebug("Teachings of the Monastery faded")
            end
            
            -- Track Power Strikes removal
            if spellID == buffs.POWER_STRIKES then
                powerStrikesActive = false
                API.PrintDebug("Power Strikes faded")
            end
            
            -- Track Mark of the Crane removal
            if spellID == buffs.MARK_OF_THE_CRANE and destGUID then
                hasStackOfMark[destGUID] = nil
                markOfTheCraneStacks = markOfTheCraneStacks - 1
                if markOfTheCraneStacks <= 0 then
                    markOfTheCraneStacks = 0
                    markOfTheCraneActive = false
                end
                API.PrintDebug("Mark of the Crane removed from " .. destName)
            end
            
            -- Track Strength of Spirit removal
            if spellID == buffs.STRENGTH_OF_SPIRIT then
                strengthOfSpiritActive = false
                strengthOfSpiritStacks = 0
                API.PrintDebug("Strength of Spirit faded")
            end
            
            -- Track Blackout Reinforcement removal
            if spellID == buffs.BLACKOUT_REINFORCEMENT then
                blackoutReinforcementActive = false
                blackoutReinforcementStacks = 0
                API.PrintDebug("Blackout Reinforcement faded")
            end
            
            -- Track Tear of Morning removal
            if spellID == buffs.TEAR_OF_MORNING then
                tearOfMorningActive = false
                tearOfMorningStacks = 0
                API.PrintDebug("Tear of Morning faded")
            end
            
            -- Track Dance of Chi-Ji removal
            if spellID == buffs.DANCE_OF_CHIJI then
                danceOfChiJiActive = false
                API.PrintDebug("Dance of Chi-Ji faded")
            end
            
            -- Track Empyrean Legacy removal
            if spellID == buffs.EMPYREAN_LEGACY then
                empyreanLegacyActive = false
                API.PrintDebug("Empyrean Legacy faded")
            end
            
            -- Track Faeline Stomp removal
            if spellID == buffs.FAELINE_STOMP then
                faelineStompActive = false
                API.PrintDebug("Faeline Stomp faded")
            end
            
            -- Track Bone Dust Brew removal
            if spellID == buffs.BONE_DUST_BREW then
                boneDustBrewActive = false
                API.PrintDebug("Bone Dust Brew faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            -- Update last used ability for Combo Strikes tracking
            lastUsedAbility = spellID
            
            if spellID == spells.TIGER_PALM then
                lastTigerPalm = GetTime()
                tigerPalmActive = true
                tigerPalmEndTime = GetTime() + 10 -- Approximate effect duration
                API.PrintDebug("Tiger Palm cast")
            elseif spellID == spells.BLACKOUT_KICK then
                lastBlackoutKick = GetTime()
                blackoutKickActive = true
                blackoutKickEndTime = GetTime() + 5 -- Approximate effect duration
                API.PrintDebug("Blackout Kick cast")
            elseif spellID == spells.RISING_SUN_KICK then
                lastRisingSunKick = GetTime()
                risingSunKickActive = true
                risingSunKickEndTime = GetTime() + 12 -- Approximate debuff duration
                API.PrintDebug("Rising Sun Kick cast")
            elseif spellID == spells.FIST_OF_THE_WHITE_TIGER then
                lastFistOfTheWhiteTiger = GetTime()
                fistOfTheWhiteTigerActive = true
                fistOfTheWhiteTigerEndTime = GetTime() + 5 -- Approximate effect duration
                API.PrintDebug("Fist of the White Tiger cast")
            elseif spellID == spells.SPINNING_CRANE_KICK then
                lastSpinningCraneKick = GetTime()
                spinningCraneKickActive = true
                spinningCraneKickEndTime = GetTime() + 1.5 -- Duration of channel
                API.PrintDebug("Spinning Crane Kick cast")
            elseif spellID == spells.STRIKE_OF_THE_WINDLORD then
                lastStrikeOfTheWindlord = GetTime()
                strikeOfTheWindlordActive = true
                strikeOfTheWindlordEndTime = GetTime() + 1 -- Approximate effect duration
                API.PrintDebug("Strike of the Windlord cast")
            elseif spellID == spells.FISTS_OF_FURY then
                lastFistsOfFury = GetTime()
                API.PrintDebug("Fists of Fury cast")
            elseif spellID == spells.FLYING_SERPENT_KICK then
                lastFlyingSerpentKick = GetTime()
                flyingSerpentKickActive = true
                flyingSerpentKickEndTime = GetTime() + 2 -- Duration of the movement
                API.PrintDebug("Flying Serpent Kick cast")
            elseif spellID == spells.WHIRLING_DRAGON_PUNCH then
                lastWhirlingDragonPunch = GetTime()
                whirlingDragonPunchActive = true
                whirlingDragonPunchEndTime = GetTime() + 1 -- Duration of the ability
                API.PrintDebug("Whirling Dragon Punch cast")
            elseif spellID == spells.TOUCH_OF_DEATH then
                lastTouchOfDeath = GetTime()
                touchOfDeathActive = true
                API.PrintDebug("Touch of Death cast")
            elseif spellID == spells.CHI_BURST then
                lastChiBurst = GetTime()
                API.PrintDebug("Chi Burst cast")
            elseif spellID == spells.CHI_WAVE then
                lastChiWave = GetTime()
                API.PrintDebug("Chi Wave cast")
            elseif spellID == spells.STORM_EARTH_AND_FIRE then
                lastStormEarthAndFire = GetTime()
                stormEarthAndFireActive = true
                stormEarthAndFireEndTime = GetTime() + STORM_EARTH_AND_FIRE_DURATION
                API.PrintDebug("Storm, Earth, and Fire cast")
            elseif spellID == spells.SERENITY then
                lastSerenity = GetTime()
                serenityActive = true
                serenityEndTime = GetTime() + SERENITY_DURATION
                API.PrintDebug("Serenity cast")
            elseif spellID == spells.INVOKE_XUEN then
                lastInvokeXuen = GetTime()
                invokeXuenActive = true
                invokeXuenEndTime = GetTime() + INVOKE_XUEN_DURATION
                API.PrintDebug("Invoke Xuen cast")
            elseif spellID == spells.TOUCH_OF_KARMA then
                lastTouchOfKarma = GetTime()
                touchOfKarmaActive = true
                touchOfKarmaEndTime = GetTime() + TOUCH_OF_KARMA_DURATION
                API.PrintDebug("Touch of Karma cast")
            elseif spellID == spells.FAELINE_STOMP then
                lastFaeline = GetTime()
                faelineStompActive = true
                faelineStompEndTime = GetTime() + FAELINE_STOMP_DURATION
                API.PrintDebug("Faeline Stomp cast")
            elseif spellID == spells.LEG_SWEEP then
                lastLegSweep = GetTime()
                API.PrintDebug("Leg Sweep cast")
            elseif spellID == spells.PARALYSIS then
                lastParalysis = GetTime()
                API.PrintDebug("Paralysis cast")
            elseif spellID == spells.DETOX then
                lastDetox = GetTime()
                API.PrintDebug("Detox cast")
            elseif spellID == spells.TIGERS_LUST then
                lastTigerLust = GetTime()
                tigerLustActive = true
                tigerLustEndTime = GetTime() + TIGER_LUST_DURATION
                API.PrintDebug("Tiger's Lust cast")
            elseif spellID == spells.FORTIFYING_BREW then
                lastFortifyingBrew = GetTime()
                fortifyingBrewActive = true
                fortifyingBrewEndTime = GetTime() + FORTIFYING_BREW_DURATION
                API.PrintDebug("Fortifying Brew cast")
            elseif spellID == spells.DAMPEN_HARM then
                lastDampenHarm = GetTime()
                dampenHarmActive = true
                dampenHarmEndTime = GetTime() + DAMPEN_HARM_DURATION
                API.PrintDebug("Dampen Harm cast")
            elseif spellID == spells.DIFFUSE_MAGIC then
                lastDiffuseMagic = GetTime()
                diffuseMagicActive = true
                diffuseMagicEndTime = GetTime() + DIFFUSE_MAGIC_DURATION
                API.PrintDebug("Diffuse Magic cast")
            elseif spellID == spells.TRANSCENDENCE then
                lastTranscendence = GetTime()
                API.PrintDebug("Transcendence cast")
            elseif spellID == spells.TRANSCENDENCE_TRANSFER then
                lastTranscendenceTransfer = GetTime()
                API.PrintDebug("Transcendence Transfer cast")
            elseif spellID == spells.BONE_DUST_BREW then
                lastBoneDustBrew = GetTime()
                boneDustBrewActive = true
                boneDustBrewEndTime = GetTime() + BONE_DUST_BREW_DURATION
                API.PrintDebug("Bone Dust Brew cast")
            elseif spellID == spells.CRACKLING_JADE_LIGHTNING then
                lastCracklingJadeLightning = GetTime()
                API.PrintDebug("Crackling Jade Lightning cast")
            end
        end
    end
    
    return true
end

-- Main rotation function
function Windwalker:RunRotation()
    -- Check if we should be running Windwalker Monk logic
    if API.GetActiveSpecID() ~= WINDWALKER_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("WindwalkerMonk")
    
    -- Update variables
    self:UpdateChi()
    self:UpdateEnergy()
    self:UpdateEnemyCounts()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- If Storm, Earth, and Fire is talented, update charges
    if talents.hasStormEarthAndFire then
        self:UpdateSEFCharges()
    end
    
    -- Check if in melee range
    isInMelee = self:IsInMeleeRange("target")
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Check for valid target in combat
    if not API.UnitExists("target") or not API.IsUnitEnemy("target") then
        return false
    end
    
    -- Handle out of melee range situations
    if not isInMelee and self:HandleRanged(settings) then
        return true
    end
    
    -- Handle emergency situations
    if self:HandleEmergencies(settings) then
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle major cooldowns (Serenity, SEF, Xuen)
    if self:HandleMajorCooldowns(settings) then
        return true
    end
    
    -- Handle core rotation
    if activeEnemies >= settings.rotationSettings.aoeThreshold and settings.rotationSettings.aoeEnabled then
        return self:HandleAoE(settings)
    else
        return self:HandleSingleTarget(settings)
    end
end

-- Handle ranged options when out of melee
function Windwalker:HandleRanged(settings)
    -- Use Crackling Jade Lightning to maintain combat
    if cracklingJadeLightning and API.CanCast(spells.CRACKLING_JADE_LIGHTNING) and not API.IsMoving() then
        API.CastSpellOnUnit(spells.CRACKLING_JADE_LIGHTNING, "target")
        return true
    end
    
    -- Use Chi Burst at range
    if chiBurst and API.CanCast(spells.CHI_BURST) then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Use Chi Wave at range
    if chiWave and API.CanCast(spells.CHI_WAVE) then
        API.CastSpellOnUnit(spells.CHI_WAVE, "target")
        return true
    end
    
    -- Use Flying Serpent Kick to get back in melee
    if flyingSerpentKick and API.CanCast(spells.FLYING_SERPENT_KICK) and API.GetUnitDistance("player", "target") <= 20 then
        API.CastSpell(spells.FLYING_SERPENT_KICK)
        return true
    end
    
    return false
end

-- Handle emergency situations
function Windwalker:HandleEmergencies(settings)
    -- Use Touch of Karma in emergency or for damage if setting enabled
    if touchOfKarma and 
       settings.cooldownSettings.useTouchOfKarma and 
       API.CanCast(spells.TOUCH_OF_KARMA) then
        
        local shouldUseToK = false
        
        if settings.cooldownSettings.touchOfKarmaMode == "When Taking Damage" then
            shouldUseToK = playerHealth <= settings.cooldownSettings.touchOfKarmaThreshold
        elseif settings.cooldownSettings.touchOfKarmaMode == "For Damage Only" then
            shouldUseToK = burstModeActive
        elseif settings.cooldownSettings.touchOfKarmaMode == "On Cooldown" then
            shouldUseToK = true
        end
        
        if shouldUseToK then
            API.CastSpellOnUnit(spells.TOUCH_OF_KARMA, "target")
            return true
        end
    end
    
    -- Use Touch of Death as execute or on cooldown based on setting
    if touchOfDeath and API.CanCast(spells.TOUCH_OF_DEATH) then
        local shouldUseTD = false
        
        if settings.rotationSettings.touchOfDeathMode == "Execute Only" then
            shouldUseTD = targetHealth < 15
        elseif settings.rotationSettings.touchOfDeathMode == "On Cooldown" then
            shouldUseTD = true
        elseif settings.rotationSettings.touchOfDeathMode == "Burst Only" then
            shouldUseTD = burstModeActive
        end
        
        if shouldUseTD then
            API.CastSpellOnUnit(spells.TOUCH_OF_DEATH, "target")
            return true
        end
    end
    
    return false
end

-- Handle defensive cooldowns
function Windwalker:HandleDefensives(settings)
    -- Use Fortifying Brew when health is low
    if fortifyingBrew and 
       settings.defensiveSettings.useFortifyingBrew and 
       playerHealth <= settings.defensiveSettings.fortifyingBrewThreshold and 
       API.CanCast(spells.FORTIFYING_BREW) then
        API.CastSpell(spells.FORTIFYING_BREW)
        return true
    end
    
    -- Use Dampen Harm when health is low
    if dampenHarm and 
       settings.defensiveSettings.useDampenHarm and 
       playerHealth <= settings.defensiveSettings.dampenHarmThreshold and 
       API.CanCast(spells.DAMPEN_HARM) then
        API.CastSpell(spells.DAMPEN_HARM)
        return true
    end
    
    -- Use Diffuse Magic when health is low and taking magic damage
    if diffuseMagic and 
       settings.defensiveSettings.useDiffuseMagic and 
       playerHealth <= settings.defensiveSettings.diffuseMagicThreshold and 
       API.CanCast(spells.DIFFUSE_MAGIC) and
       API.IsTakingMagicDamage("player") then
        API.CastSpell(spells.DIFFUSE_MAGIC)
        return true
    end
    
    -- Use Tiger's Lust
    if tigersLust and 
       settings.defensiveSettings.useTigersLust and 
       settings.defensiveSettings.tigersLustMode ~= "Manual Only" and
       API.CanCast(spells.TIGERS_LUST) then
        
        if settings.defensiveSettings.tigersLustMode == "Self Only" and API.IsPlayerMovementImpaired() then
            API.CastSpellOnUnit(spells.TIGERS_LUST, "player")
            return true
        elseif settings.defensiveSettings.tigersLustMode == "Group Members" then
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitMovementImpaired(unit) then
                    API.CastSpellOnUnit(spells.TIGERS_LUST, unit)
                    return true
                end
            end
        end
    end
    
    -- Handle Detox (cleansing)
    if detox and 
       settings.utilitySettings.useDetox and 
       API.CanCast(spells.DETOX) then
        
        -- Check for dispellable debuffs on group members
        for i = 1, API.GetGroupSize() do
            local unit
            if API.IsInRaid() then
                unit = "raid" .. i
            else
                unit = i == 1 and "player" or "party" .. (i - 1)
            end
            
            if API.UnitExists(unit) and not API.UnitIsDead(unit) then
                -- Check for dispellable debuffs (poison, disease, magic)
                if API.CanDispelUnit(unit, "Poison") or API.CanDispelUnit(unit, "Disease") then
                    API.CastSpellOnUnit(spells.DETOX, unit)
                    return true
                end
            end
        end
    end
    
    -- Use Leg Sweep for AoE stun
    if legSweep and 
       settings.utilitySettings.useLegSweep and 
       API.CanCast(spells.LEG_SWEEP) and
       activeEnemies >= settings.utilitySettings.legSweepMinTargets then
        API.CastSpell(spells.LEG_SWEEP)
        return true
    end
    
    -- Use Paralysis for CC
    if paralysis and 
       settings.utilitySettings.useParalysis and 
       API.CanCast(spells.PARALYSIS) and
       API.ShouldCrowdControl("target") then
        API.CastSpellOnUnit(spells.PARALYSIS, "target")
        return true
    end
    
    -- Use Transcendence
    if transcendence and 
       settings.utilitySettings.useTranscendence and 
       settings.utilitySettings.transcendenceMode ~= "Manual Only" then
        
        if settings.utilitySettings.transcendenceMode == "Place on Cooldown" and API.CanCast(spells.TRANSCENDENCE) then
            API.CastSpell(spells.TRANSCENDENCE)
            return true
        elseif settings.utilitySettings.transcendenceMode == "Transfer When Low Health" and 
               playerHealth <= 35 and 
               API.CanCast(spells.TRANSCENDENCE_TRANSFER) then
            API.CastSpell(spells.TRANSCENDENCE_TRANSFER)
            return true
        end
    end
    
    return false
end

-- Handle major cooldowns (Serenity, SEF, Xuen)
function Windwalker:HandleMajorCooldowns(settings)
    -- Use Invoke Xuen
    if invokeXuen and 
       settings.cooldownSettings.useInvokeXuen and 
       settings.cooldownSettings.invokeXuenMode ~= "Manual Only" and
       API.CanCast(spells.INVOKE_XUEN) and
       isInMelee then
        
        local shouldUseXuen = false
        
        if settings.cooldownSettings.invokeXuenMode == "On Cooldown" then
            shouldUseXuen = true
        elseif settings.cooldownSettings.invokeXuenMode == "With Cooldowns" then
            shouldUseXuen = serenityActive or stormEarthAndFireActive or burstModeActive
        elseif settings.cooldownSettings.invokeXuenMode == "Boss Only" then
            shouldUseXuen = API.IsFightingBoss()
        end
        
        if shouldUseXuen then
            API.CastSpell(spells.INVOKE_XUEN)
            return true
        end
    end
    
    -- Use Serenity
    if serenity and 
       settings.serenitySettings.useSerenity and 
       settings.serenitySettings.serenityMode ~= "Manual Only" and
       API.CanCast(spells.SERENITY) and
       isInMelee then
        
        local shouldUseSerenity = false
        
        if settings.serenitySettings.serenityMode == "On Cooldown" then
            shouldUseSerenity = true
        elseif settings.serenitySettings.serenityMode == "With Cooldowns" then
            shouldUseSerenity = invokeXuenActive or burstModeActive
        elseif settings.serenitySettings.serenityMode == "Boss Only" then
            shouldUseSerenity = API.IsFightingBoss()
        end
        
        -- Check if we need to prepare Chi
        if settings.serenitySettings.prepareChi and currentChi < 2 then
            shouldUseSerenity = false
        end
        
        if shouldUseSerenity then
            API.CastSpell(spells.SERENITY)
            return true
        end
    end
    
    -- Use Storm, Earth, and Fire
    if stormEarthAndFire and 
       settings.stormEarthAndFireSettings.useSEF and 
       settings.stormEarthAndFireSettings.sefMode ~= "Manual Only" and
       API.CanCast(spells.STORM_EARTH_AND_FIRE) and
       isInMelee then
        
        local shouldUseSEF = false
        
        if settings.stormEarthAndFireSettings.sefMode == "On Cooldown" then
            shouldUseSEF = true
        elseif settings.stormEarthAndFireSettings.sefMode == "With Cooldowns" then
            shouldUseSEF = invokeXuenActive or burstModeActive
        elseif settings.stormEarthAndFireSettings.sefMode == "Boss Only" then
            shouldUseSEF = API.IsFightingBoss()
        end
        
        -- Check if we need to prepare Chi
        if settings.stormEarthAndFireSettings.prepareChi and currentChi < 2 then
            shouldUseSEF = false
        end
        
        -- Check if we should save a charge
        if settings.stormEarthAndFireSettings.sefSaveCharge and stormEarthAndFireCharges <= 1 then
            shouldUseSEF = false
        end
        
        if shouldUseSEF then
            API.CastSpell(spells.STORM_EARTH_AND_FIRE)
            return true
        end
    end
    
    -- Use Bonedust Brew
    if boneDustBrew and 
       settings.cooldownSettings.useBoneDustBrew and 
       settings.cooldownSettings.boneDustBrewMode ~= "Manual Only" and
       API.CanCast(spells.BONE_DUST_BREW) and
       isInMelee then
        
        local shouldUseBDB = false
        
        if settings.cooldownSettings.boneDustBrewMode == "On Cooldown" then
            shouldUseBDB = true
        elseif settings.cooldownSettings.boneDustBrewMode == "With Cooldowns" then
            shouldUseBDB = serenityActive or stormEarthAndFireActive or invokeXuenActive or burstModeActive
        elseif settings.cooldownSettings.boneDustBrewMode == "AoE Only" then
            shouldUseBDB = activeEnemies >= settings.cooldownSettings.boneDustBrewAoEThreshold
        end
        
        if shouldUseBDB then
            API.CastSpellOnUnit(spells.BONE_DUST_BREW, "target")
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Windwalker:HandleAoE(settings)
    local useComboStrikes = settings.rotationSettings.maintainComboStrikes

    -- If Dance of Chi-Ji proc is active, prioritize Spinning Crane Kick
    if danceOfChiJiActive and 
       spinningCraneKick and 
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       (currentChi >= 2 or serenityActive) then
        API.CastSpell(spells.SPINNING_CRANE_KICK)
        return true
    end
    
    -- Use Faeline Stomp in AoE
    if faeline and 
       API.CanCast(spells.FAELINE_STOMP) and
       not faelineStompActive and
       activeEnemies >= 3 then
        API.CastSpell(spells.FAELINE_STOMP)
        return true
    end
    
    -- Use Strike of the Windlord in AoE (if available and can maintain Combo Strikes)
    if strikeOfTheWindlord and 
       API.CanCast(spells.STRIKE_OF_THE_WINDLORD) and
       (currentChi >= 2 or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.STRIKE_OF_THE_WINDLORD)) then
        API.CastSpell(spells.STRIKE_OF_THE_WINDLORD)
        return true
    end
    
    -- Use Whirling Dragon Punch when available
    if whirlingDragonPunch and 
       API.CanCast(spells.WHIRLING_DRAGON_PUNCH) and
       !API.GetSpellCooldown(spells.RISING_SUN_KICK) > 0 and
       !API.GetSpellCooldown(spells.FISTS_OF_FURY) > 0 and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.WHIRLING_DRAGON_PUNCH)) then
        API.CastSpell(spells.WHIRLING_DRAGON_PUNCH)
        return true
    end
    
    -- Use Fists of Fury in AoE (if settings allow and can maintain Combo Strikes)
    if fistsOfFury and 
       API.CanCast(spells.FISTS_OF_FURY) and
       settings.abilityControls.fistsOfFury.enabled and
       (currentChi >= settings.abilityControls.fistsOfFury.minChi or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.FISTS_OF_FURY)) then
        
        local shouldUseFoF = true
        
        if settings.rotationSettings.fistsOfFuryStyle == "Manual Only" then
            shouldUseFoF = false
        elseif settings.rotationSettings.fistsOfFuryStyle == "With Cooldowns" then
            shouldUseFoF = serenityActive or stormEarthAndFireActive or invokeXuenActive
        end
        
        if shouldUseFoF then
            API.CastSpellOnUnit(spells.FISTS_OF_FURY, "target")
            return true
        end
    end
    
    -- Blackout Kick with Blackout Reinforcement proc
    if blackoutKick and 
       blackoutReinforcementActive and 
       API.CanCast(spells.BLACKOUT_KICK) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.BLACKOUT_KICK)) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Spinning Crane Kick if we have enough targets and Chi (or during Serenity)
    if spinningCraneKick and 
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       settings.abilityControls.spinningCraneKick.enabled and
       (currentChi >= settings.abilityControls.spinningCraneKick.minChi or serenityActive) and
       activeEnemies >= settings.abilityControls.spinningCraneKick.minTargets and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.SPINNING_CRANE_KICK)) then
        
        -- Check if we need marks first
        local hasEnoughMarks = true
        if settings.abilityControls.spinningCraneKick.requireMarkOfTheCrane then
            hasEnoughMarks = markOfTheCraneStacks >= 3
        end
        
        if hasEnoughMarks then
            API.CastSpell(spells.SPINNING_CRANE_KICK)
            return true
        end
    end
    
    -- Use Rising Sun Kick to apply debuff and maintain Combo Strikes
    if risingSunKick and 
       API.CanCast(spells.RISING_SUN_KICK) and
       settings.abilityControls.risingSunKick.enabled and
       (currentChi >= settings.abilityControls.risingSunKick.minChi or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.RISING_SUN_KICK)) then
        
        -- Always use during Serenity if set to prioritize
        if serenityActive and settings.abilityControls.risingSunKick.priorityDuringSerenity then
            API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
            return true
        else
            API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
            return true
        end
    end
    
    -- Apply Mark of the Crane to targets in AoE
    if tigerPalm and 
       API.CanCast(spells.TIGER_PALM) and
       currentChi < maxChi and
       settings.rotationSettings.optimizeMarkOfTheCrane and
       activeEnemies >= settings.rotationSettings.optimizeMarkOfTheCraneThreshold and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.TIGER_PALM)) then
        
        -- Check for the best target to apply Mark to
        for i = 1, activeEnemies do
            local unit = "nameplate" .. i
            if API.UnitExists(unit) and not hasStackOfMark[API.UnitGUID(unit)] then
                API.CastSpellOnUnit(spells.TIGER_PALM, unit)
                return true
            end
        end
    end
    
    -- Fist of the White Tiger for Chi generation in AoE
    if fistOfTheWhiteTiger and 
       API.CanCast(spells.FIST_OF_THE_WHITE_TIGER) and
       currentChi <= (maxChi - 3) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.FIST_OF_THE_WHITE_TIGER)) then
        API.CastSpellOnUnit(spells.FIST_OF_THE_WHITE_TIGER, "target")
        return true
    end
    
    -- Tiger Palm for Chi generation if not energy pooling
    if tigerPalm and 
       API.CanCast(spells.TIGER_PALM) and
       currentChi < maxChi and
       (!settings.rotationSettings.energyPooling or currentEnergy > settings.rotationSettings.energyPoolingThreshold) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.TIGER_PALM)) then
        API.CastSpellOnUnit(spells.TIGER_PALM, "target")
        return true
    end
    
    return false
end

-- Handle single target rotation
function Windwalker:HandleSingleTarget(settings)
    local useComboStrikes = settings.rotationSettings.maintainComboStrikes
    
    -- Use Strike of the Windlord (if available and can maintain Combo Strikes)
    if strikeOfTheWindlord and 
       API.CanCast(spells.STRIKE_OF_THE_WINDLORD) and
       (currentChi >= 2 or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.STRIKE_OF_THE_WINDLORD)) then
        
        -- Check if we should use during Serenity
        if serenityActive and not settings.serenitySettings.useStrikeOfTheWindlordDuringSerenity then
            -- Skip using it during Serenity if the setting is off
        else
            API.CastSpell(spells.STRIKE_OF_THE_WINDLORD)
            return true
        end
    end
    
    -- Use Fists of Fury (if settings allow and can maintain Combo Strikes)
    if fistsOfFury and 
       API.CanCast(spells.FISTS_OF_FURY) and
       settings.abilityControls.fistsOfFury.enabled and
       (currentChi >= settings.abilityControls.fistsOfFury.minChi or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.FISTS_OF_FURY)) then
        
        local shouldUseFoF = true
        
        if settings.rotationSettings.fistsOfFuryStyle == "Manual Only" then
            shouldUseFoF = false
        elseif settings.rotationSettings.fistsOfFuryStyle == "Chi Dump" then
            shouldUseFoF = currentChi >= 4 or serenityActive
        elseif settings.rotationSettings.fistsOfFuryStyle == "With Cooldowns" then
            shouldUseFoF = serenityActive or stormEarthAndFireActive or invokeXuenActive
        end
        
        if settings.abilityControls.fistsOfFury.requireSerenity and not serenityActive then
            shouldUseFoF = false
        end
        
        if shouldUseFoF then
            API.CastSpellOnUnit(spells.FISTS_OF_FURY, "target")
            return true
        end
    end
    
    -- Use Whirling Dragon Punch when available
    if whirlingDragonPunch and 
       API.CanCast(spells.WHIRLING_DRAGON_PUNCH) and
       API.GetSpellCooldown(spells.RISING_SUN_KICK) > 0 and
       API.GetSpellCooldown(spells.FISTS_OF_FURY) > 0 and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.WHIRLING_DRAGON_PUNCH)) then
        API.CastSpell(spells.WHIRLING_DRAGON_PUNCH)
        return true
    end
    
    -- Blackout Kick with Blackout Reinforcement proc
    if blackoutKick and 
       blackoutReinforcementActive and 
       API.CanCast(spells.BLACKOUT_KICK) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.BLACKOUT_KICK)) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Rising Sun Kick (prioritize during Serenity if settings say so)
    if risingSunKick and 
       API.CanCast(spells.RISING_SUN_KICK) and
       settings.abilityControls.risingSunKick.enabled and
       (currentChi >= settings.abilityControls.risingSunKick.minChi or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.RISING_SUN_KICK)) then
        
        -- Always use during Serenity if set to prioritize
        if serenityActive and settings.serenitySettings.serenityPriorityRSK then
            API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
            return true
        else
            API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
            return true
        end
    end
    
    -- Use Blackout Kick with free proc from Teachings of the Monastery or Chi spender
    if blackoutKick and 
       API.CanCast(spells.BLACKOUT_KICK) and
       ((teachingsOfTheMonasteryActive and teachingsOfTheMonasteryStacks >= 2) or currentChi >= 1 or serenityActive) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.BLACKOUT_KICK)) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Chi Burst if talented
    if chiBurst and API.CanCast(spells.CHI_BURST) and currentChi < maxChi - 1 then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Use Chi Wave if talented
    if chiWave and API.CanCast(spells.CHI_WAVE) and currentChi < maxChi - 1 then
        API.CastSpellOnUnit(spells.CHI_WAVE, "target")
        return true
    end
    
    -- Use Fist of the White Tiger for Chi generation
    if fistOfTheWhiteTiger and 
       API.CanCast(spells.FIST_OF_THE_WHITE_TIGER) and
       currentChi <= (maxChi - 3) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.FIST_OF_THE_WHITE_TIGER)) then
        API.CastSpellOnUnit(spells.FIST_OF_THE_WHITE_TIGER, "target")
        return true
    end
    
    -- Use Tiger Palm for Chi generation if not energy pooling
    if tigerPalm and 
       API.CanCast(spells.TIGER_PALM) and
       currentChi < maxChi and
       (!settings.rotationSettings.energyPooling or currentEnergy > settings.rotationSettings.energyPoolingThreshold) and
       (!useComboStrikes or self:WouldMaintainComboStrikes(spells.TIGER_PALM)) then
        API.CastSpellOnUnit(spells.TIGER_PALM, "target")
        return true
    end
    
    return false
end

-- Handle specialization change
function Windwalker:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentChi = 0
    maxChi = 5
    currentEnergy = 100
    maxEnergy = 100
    comboStrike = false
    lastUsedAbility = nil
    tearOfMorningActive = false
    tearOfMorningEndTime = 0
    tearOfMorningStacks = 0
    hitComboActive = false
    hitComboEndTime = 0
    hitComboStacks = 0
    serenityActive = false
    serenityEndTime = 0
    stormEarthAndFireActive = false
    stormEarthAndFireEndTime = 0
    stormEarthAndFireCharges = 0
    stormEarthAndFireMaxCharges = 0
    evokersBoonActive = false
    evokersBoonEndTime = 0
    touchOfKarmaActive = false
    touchOfKarmaEndTime = 0
    dancingEmberActive = false
    dancingEmberEndTime = 0
    chiBurst = false
    chiWave = false
    invokeXuenActive = false
    invokeXuenEndTime = 0
    tigerPalmActive = false
    tigerPalmEndTime = 0
    blackoutKickActive = false
    blackoutKickEndTime = 0
    risingSunKickActive = false
    risingSunKickEndTime = 0
    fistOfTheWhiteTigerActive = false
    fistOfTheWhiteTigerEndTime = 0
    fistOfTheWhiteTiger = false
    spinningCraneKickActive = false
    spinningCraneKickEndTime = 0
    whirlingDragonPunchActive = false
    whirlingDragonPunchEndTime = 0
    strikeOfTheWindlordActive = false
    strikeOfTheWindlordEndTime = 0
    flyingSerpentKickActive = false
    flyingSerpentKickEndTime = 0
    faelineStompActive = false
    faelineStompEndTime = 0
    shadowboxingTreadsActive = false
    shadowboxingTreadsStacks = 0
    teachingsOfTheMonasteryActive = false
    teachingsOfTheMonasteryStacks = 0
    powerStrikesActive = false
    markOfTheCraneActive = false
    markOfTheCraneStacks = 0
    strengthOfSpiritActive = false
    strengthOfSpiritStacks = 0
    tigerLustActive = false
    tigerLustEndTime = 0
    fortifyingBrewActive = false
    fortifyingBrewEndTime = 0
    dampenHarmActive = false
    dampenHarmEndTime = 0
    touchOfDeathActive = false
    diffuseMagicActive = false
    diffuseMagicEndTime = 0
    invokeXuen = false
    serenity = false
    stormEarthAndFire = false
    shadowboxingTreads = false
    blackoutReinforcementActive = false
    blackoutReinforcementEndTime = 0
    blackoutReinforcementStacks = 0
    markOfTheCrane = false
    tigerPalm = false
    blackoutKick = false
    risingSunKick = false
    spinningCraneKick = false
    strikeOfTheWindlord = false
    fistsOfFury = false
    flyingSerpentKick = false
    whirlingDragonPunch = false
    touchOfDeath = false
    chiTorpedo = false
    fortifyingBrew = false
    dampenHarm = false
    diffuseMagic = false
    tigersTail = false
    tigersLust = false
    transcendence = false
    transcendenceTransfer = false
    detox = false
    legSweep = false
    paralysis = false
    pressurePoint = false
    xuentsBattlegear = false
    danceOfChiJi = false
    danceOfChiJiActive = false
    danceOfChiJiEndTime = 0
    skyreachExhaustion = false
    empyreanLegacy = false
    empyreanLegacyActive = false
    empyreanLegacyEndTime = 0
    faeline = false
    cracklingJadeLightning = false
    boneDustBrew = false
    boneDustBrewActive = false
    boneDustBrewEndTime = 0
    lastTigerPalm = 0
    lastBlackoutKick = 0
    lastRisingSunKick = 0
    lastFistOfTheWhiteTiger = 0
    lastSpinningCraneKick = 0
    lastStrikeOfTheWindlord = 0
    lastFistsOfFury = 0
    lastFlyingSerpentKick = 0
    lastWhirlingDragonPunch = 0
    lastTouchOfDeath = 0
    lastChiBurst = 0
    lastChiWave = 0
    lastStormEarthAndFire = 0
    lastSerenity = 0
    lastInvokeXuen = 0
    lastTouchOfKarma = 0
    lastFaeline = 0
    lastLegSweep = 0
    lastParalysis = 0
    lastDetox = 0
    lastTigerLust = 0
    lastFortifyingBrew = 0
    lastDampenHarm = 0
    lastDiffuseMagic = 0
    lastTranscendence = 0
    lastTranscendenceTransfer = 0
    lastBoneDustBrew = 0
    lastCracklingJadeLightning = 0
    playerHealth = 100
    targetHealth = 100
    activeEnemies = 0
    isInMelee = false
    hasStackOfMark = {}
    
    API.PrintDebug("Windwalker Monk state reset on spec change")
    
    return true
end

-- Return the module for loading
return Windwalker