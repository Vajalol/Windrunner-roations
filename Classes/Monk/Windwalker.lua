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
local currentAoETargets = 0
local currentEnergy = 0
local maxEnergy = 100
local currentChi = 0
local maxChi = 5
local tigersFuryActive = false
local tigersFuryEndTime = 0
local hitComboActive = false
local hitComboStacks = 0
local powerStrikesActive = false
local serenityActive = false
local serenityEndTime = 0
local stormEarthAndFireActive = false
local stormEarthAndFireCharges = 0
local stormEarthAndFireEndTime = 0
local whirlingDragonPunchActive = false
local lastAbilityUsed = ""
local fistOfTheWhiteTigerActive = false
local transferThePowerActive = false
local transferThePowerStacks = 0
local danceOfChiJiActive = false
local danceOfChiJiEndTime = 0
local rushingJadeWindActive = false
local rushingJadeWindEndTime = 0
local powerStrikesNext = false
local blackoutKick = false
local tigerPalm = false
local risingSunKick = false
local fistOfFury = false
local spinningCraneKick = false
local strikeOfTheWindlord = false
local touchOfDeath = false
local explodingKeg = false
local fistOfTheWhiteTiger = false
local chiBurst = false
local chiWave = false
local invokeXuenTheWhiteTiger = false
local faeline = false
local faelineFriendlyActive = false
local faelineHostileActive = false
local bonneBuff = false
local skyreachExhaustion = false
local pressurePoint = false
local pressurePointEndTime = 0
local pressurePointCount = 0
local markOfTheCraneStacks = 0
local comboStrikes = false
local markOfTheCraneActive = false
local strengthOfSpirit = false
local shadowboxingTreads = false
local inMeleeRange = false
local teachingsOfTheMonasteryBuff = false
local teachingsOfTheMonasteryBuffStacks = 0
local resonantFlowActive = false
local inHandOfTheTiger = false
local fastFeetActive = false
local drinkerOfBlood = false
local reverseHarmActive = false
local reverseHarmEndTime = 0
local touchOfKarmaActive = false
local touchOfKarmaEndTime = 0
local fortifyingBrewActive = false
local fortifyingBrewEndTime = 0
local serenity = false
local invokeXuen = false
local bonedust = false
local chiExplosion = false
local zenSphere = false
local xuenActive = false
local xuenEndTime = 0
local skyTouch = false
local lastSpinner = {}

-- Constants
local WINDWALKER_SPEC_ID = 269
local DEFAULT_AOE_THRESHOLD = 3
local TIGERS_FURY_DURATION = 8 -- seconds
local SERENITY_DURATION = 12 -- seconds
local STORM_EARTH_FIRE_DURATION = 15 -- seconds
local WHIRLING_DRAGON_PUNCH_DURATION = 1 -- seconds
local DANCE_OF_CHIJI_DURATION = 15 -- seconds
local RUSHING_JADE_WIND_DURATION = 6 -- seconds
local PRESSURE_POINT_DURATION = 5 -- seconds
local XUEN_DURATION = 24 -- seconds
local REVERSE_HARM_DURATION = 6 -- seconds
local TOUCH_OF_KARMA_DURATION = 10 -- seconds
local FORTIFYING_BREW_DURATION = 15 -- seconds
local TEACHINGS_DURATION = 20 -- seconds
local MELEE_RANGE = 5 -- yards
local MAX_SPINNER_COUNT = 20

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
    -- Core rotational abilities
    spells.TIGER_PALM = 100780
    spells.BLACKOUT_KICK = 100784
    spells.RISING_SUN_KICK = 107428
    spells.FISTS_OF_FURY = 113656
    spells.SPINNING_CRANE_KICK = 101546
    spells.STRIKE_OF_THE_WINDLORD = 392983
    spells.FIST_OF_THE_WHITE_TIGER = 261947
    spells.CHI_WAVE = 115098
    spells.CHI_BURST = 123986
    spells.WHIRLING_DRAGON_PUNCH = 152175
    spells.FLYING_SERPENT_KICK = 101545
    spells.RUSHING_JADE_WIND = 116847
    spells.TOUCH_OF_DEATH = 115080
    spells.STORM_EARTH_AND_FIRE = 137639
    spells.SERENITY = 152173
    spells.INVOKE_XUEN = 123904
    spells.EXPLODING_KEG = 325153
    
    -- Core utilities
    spells.DETOX = 218164
    spells.LEG_SWEEP = 119381
    spells.PARALYSIS = 115078
    spells.PROVOKE = 115546
    spells.RING_OF_PEACE = 116844
    spells.ROLL = 109132
    spells.CHI_TORPEDO = 115008
    spells.TRANSCENDENCE = 101643
    spells.TRANSCENDENCE_TRANSFER = 119996
    spells.VIVIFY = 116670
    spells.RESUSCITATE = 115178
    spells.SPEAR_HAND_STRIKE = 116705
    spells.EXPEL_HARM = 322101
    spells.TOUCH_OF_KARMA = 122470
    spells.FORTIFYING_BREW = 115203
    spells.DIFFUSE_MAGIC = 122783
    spells.DAMPEN_HARM = 122278
    spells.DISABLE = 116095
    
    -- Talents and passives
    spells.HIT_COMBO = 196740
    spells.POWER_STRIKES = 121817
    spells.ASCENSION = 115396
    spells.CHI_EXPLOSION = 393056
    spells.DANCE_OF_CHIJI = 325201
    spells.SHADOWBOXING_TREADS = 392983
    spells.STRENGTH_OF_SPIRIT = 387276
    spells.MARK_OF_THE_CRANE = 220357
    spells.TEACHINGS_OF_THE_MONASTERY = 116645
    spells.COMBO_BREAKER = 137384
    spells.INVOKE_XUEN_THE_WHITE_TIGER = 123904
    spells.TRANSFER_THE_POWER = 195300
    spells.XUEN_BOND = 391383
    spells.SKYTOUCH = 405044
    spells.SPIRITUAL_FOCUS = 280197
    spells.CLOSE_TO_THE_HEART = 389684
    spells.AWAKENED_FAELINE = 387947
    spells.RESONANT_FISTS = 389578
    spells.MERIDIAN_STRIKES = 387042
    spells.RISING_STAR = 387038
    spells.POWER_OF_THE_WHITE_TIGER = 418089
    spells.CHI_HARMONY = 387025
    spells.BOUNTIFUL_BREW = 389686
    spells.DRINKING_HORN_COVER = 328454
    spells.DIZZYING_WINDS = 196742
    spells.ATTENUATION = 386941
    spells.BONEDUST_BREW = 386276
    spells.FAST_FEET = 388809
    spells.FEROCITY_OF_XUEN = 388674
    spells.FLASHING_FISTS = 388854
    spells.FORBIDDEN_TECHNIQUE = 387184
    spells.FURY_OF_XUEN = 396166
    spells.HARDENED_SOLES = 387258
    spells.INNER_PEACE = 387989
    spells.PRETENSE_OF_INSTABILITY = 393516
    spells.TOUCH_OF_STEEL = 418073
    spells.WIND_STORM = 417012
    spells.RESONANT_FLOW = 389579
    spells.HAND_OF_THE_TIGER = 388741
    spells.DRINKER_OF_BLOOD = 387219
    spells.REVERSE_HARM = 287771
    
    -- War Within Season 2 specific
    spells.ANCIENT_CONCORDANCE = 389684
    spells.FAELINE_HARMONY = 390148
    spells.FLASHING_FISTS = 388854
    spells.JADE_IGNITION = 392979
    spells.PATH_OF_THE_MONK = 392970
    spells.PRESSURE_POINT = 337482
    spells.SPIRIT_OF_THE_CRANE = 393039
    spells.SPITFIRE = 390617
    spells.THUNDERFIST = 392985
    spells.WALK_WITH_THE_OX = 387220
    spells.WHITE_TIGER_STATUE = 389684
    spells.ZEN_MEDITATION = 115176
    spells.ZEN_SPHERE = 124081
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.WEAPONS_OF_ORDER = 310454
    spells.FALLEN_ORDER = 326860
    spells.BONEDUST_BREW = 386276
    spells.FAELINE_STOMP = 388193
    
    -- Buff IDs
    spells.TIGERS_FURY_BUFF = 5217
    spells.HIT_COMBO_BUFF = 196741
    spells.POWER_STRIKES_BUFF = 129914
    spells.SERENITY_BUFF = 152173
    spells.STORM_EARTH_AND_FIRE_BUFF = 137639
    spells.TRANSFER_THE_POWER_BUFF = 195321
    spells.DANCE_OF_CHIJI_BUFF = 325202
    spells.RUSHING_JADE_WIND_BUFF = 116847
    spells.TEACHINGS_OF_THE_MONASTERY_BUFF = 202090
    spells.BLACKOUT_KICK_BUFF = 116768
    spells.COMBO_BREAKER_BUFF = 137384
    spells.PRESSURE_POINT_BUFF = 337482
    spells.MARK_OF_THE_CRANE_BUFF = 228287
    spells.BONEDUST_BREW_BUFF = 386276
    spells.XUEN_BUFF = 123904
    spells.RESONANT_FLOW_BUFF = 389579
    spells.REVERSE_HARM_BUFF = 342928
    spells.TOUCH_OF_KARMA_BUFF = 122470
    spells.FORTIFYING_BREW_BUFF = 120954
    
    -- Debuff IDs
    spells.SKYTOUCH_DEBUFF = 405045
    spells.FAELINED_STOMP_DEBUFF = 388207
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.TIGERS_FURY = spells.TIGERS_FURY_BUFF
    buffs.HIT_COMBO = spells.HIT_COMBO_BUFF
    buffs.POWER_STRIKES = spells.POWER_STRIKES_BUFF
    buffs.SERENITY = spells.SERENITY_BUFF
    buffs.STORM_EARTH_AND_FIRE = spells.STORM_EARTH_AND_FIRE_BUFF
    buffs.TRANSFER_THE_POWER = spells.TRANSFER_THE_POWER_BUFF
    buffs.DANCE_OF_CHIJI = spells.DANCE_OF_CHIJI_BUFF
    buffs.RUSHING_JADE_WIND = spells.RUSHING_JADE_WIND_BUFF
    buffs.TEACHINGS_OF_THE_MONASTERY = spells.TEACHINGS_OF_THE_MONASTERY_BUFF
    buffs.BLACKOUT_KICK = spells.BLACKOUT_KICK_BUFF
    buffs.COMBO_BREAKER = spells.COMBO_BREAKER_BUFF
    buffs.PRESSURE_POINT = spells.PRESSURE_POINT_BUFF
    buffs.MARK_OF_THE_CRANE = spells.MARK_OF_THE_CRANE_BUFF
    buffs.BONEDUST_BREW = spells.BONEDUST_BREW_BUFF
    buffs.XUEN = spells.XUEN_BUFF
    buffs.RESONANT_FLOW = spells.RESONANT_FLOW_BUFF
    buffs.REVERSE_HARM = spells.REVERSE_HARM_BUFF
    buffs.TOUCH_OF_KARMA = spells.TOUCH_OF_KARMA_BUFF
    buffs.FORTIFYING_BREW = spells.FORTIFYING_BREW_BUFF
    
    debuffs.SKYTOUCH = spells.SKYTOUCH_DEBUFF
    debuffs.FAELINED_STOMP = spells.FAELINED_STOMP_DEBUFF
    
    return true
end

-- Register variables to track
function Windwalker:RegisterVariables()
    -- Talent tracking
    talents.hasHitCombo = false
    talents.hasPowerStrikes = false
    talents.hasAscension = false
    talents.hasChiExplosion = false
    talents.hasDanceOfChiJi = false
    talents.hasShadowboxingTreads = false
    talents.hasStrengthOfSpirit = false
    talents.hasMarkOfTheCrane = false
    talents.hasTeachingsOfTheMonastery = false
    talents.hasComboBreaker = false
    talents.hasInvokeXuenTheWhiteTiger = false
    talents.hasTransferThePower = false
    talents.hasXuenBond = false
    talents.hasSkytouch = false
    talents.hasSpiritualFocus = false
    talents.hasCloseToTheHeart = false
    talents.hasAwakenedFaeline = false
    talents.hasResonantFists = false
    talents.hasMeridianStrikes = false
    talents.hasRisingStar = false
    talents.hasPowerOfTheWhiteTiger = false
    talents.hasChiHarmony = false
    talents.hasBountifulBrew = false
    talents.hasDrinkingHornCover = false
    talents.hasDizzyingWinds = false
    talents.hasAttenuation = false
    talents.hasBonedustBrew = false
    talents.hasFastFeet = false
    talents.hasFerocityOfXuen = false
    talents.hasFlashingFists = false
    talents.hasForbiddenTechnique = false
    talents.hasFuryOfXuen = false
    talents.hasHardenedSoles = false
    talents.hasInnerPeace = false
    talents.hasPretenseOfInstability = false
    talents.hasTouchOfSteel = false
    talents.hasWindStorm = false
    talents.hasResonantFlow = false
    talents.hasHandOfTheTiger = false
    talents.hasDrinkerOfBlood = false
    talents.hasReverseHarm = false
    
    -- War Within Season 2 talents
    talents.hasAncientConcordance = false
    talents.hasFaelineHarmony = false
    talents.hasFlashingFists = false
    talents.hasJadeIgnition = false
    talents.hasPathOfTheMonk = false
    talents.hasPressurePoint = false
    talents.hasSpiritOfTheCrane = false
    talents.hasSpitfire = false
    talents.hasThunderfist = false
    talents.hasWalkWithTheOx = false
    talents.hasWhiteTigerStatue = false
    talents.hasZenMeditation = false
    talents.hasZenSphere = false
    
    -- Initialize resources
    currentEnergy = API.GetPlayerPower()
    currentChi = API.GetPlayerComboPoints() or 0
    
    -- Initialize Storm, Earth and Fire charges
    stormEarthAndFireCharges = API.GetSpellCharges(spells.STORM_EARTH_AND_FIRE) or 0
    
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
                default = DEFAULT_AOE_THRESHOLD
            },
            maintainComboStrikes = {
                displayName = "Maintain Combo Strikes",
                description = "Prioritize not repeating abilities for Combo Strikes",
                type = "toggle",
                default = true
            },
            energyPooling = {
                displayName = "Energy Pooling",
                description = "Pool energy for priority abilities",
                type = "toggle",
                default = true
            },
            energyPoolingThreshold = {
                displayName = "Energy Pooling Threshold",
                description = "Minimum energy to maintain",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            },
            useStormEarthFire = {
                displayName = "Use Storm, Earth, and Fire",
                description = "Automatically use Storm, Earth, and Fire",
                type = "toggle",
                default = true
            },
            useSerenity = {
                displayName = "Use Serenity",
                description = "Automatically use Serenity when talented",
                type = "toggle",
                default = true
            },
            whirlingDragonPunchMode = {
                displayName = "Whirling Dragon Punch Usage",
                description = "When to use Whirling Dragon Punch",
                type = "dropdown",
                options = {"On Cooldown", "AoE Only", "Burst Only"},
                default = "On Cooldown"
            }
        },
        
        defensiveSettings = {
            useTouchOfKarma = {
                displayName = "Use Touch of Karma",
                description = "Automatically use Touch of Karma",
                type = "toggle",
                default = true
            },
            touchOfKarmaThreshold = {
                displayName = "Touch of Karma Health Threshold",
                description = "Health percentage to use Touch of Karma",
                type = "slider",
                min = 30,
                max = 90,
                default = 70
            },
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
                min = 20,
                max = 70,
                default = 40
            },
            useDiffuseMagic = {
                displayName = "Use Diffuse Magic",
                description = "Automatically use Diffuse Magic when taking magic damage",
                type = "toggle",
                default = true
            },
            useDampenHarm = {
                displayName = "Use Dampen Harm",
                description = "Automatically use Dampen Harm",
                type = "toggle",
                default = true
            },
            dampenHarmThreshold = {
                displayName = "Dampen Harm Health Threshold",
                description = "Health percentage to use Dampen Harm",
                type = "slider",
                min = 20,
                max = 70,
                default = 50
            },
            useExpelHarm = {
                displayName = "Use Expel Harm",
                description = "Automatically use Expel Harm for healing",
                type = "toggle",
                default = true
            },
            expelHarmThreshold = {
                displayName = "Expel Harm Health Threshold",
                description = "Health percentage to use Expel Harm",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            }
        },
        
        offensiveSettings = {
            useTouchOfDeath = {
                displayName = "Use Touch of Death",
                description = "Automatically use Touch of Death",
                type = "toggle",
                default = true
            },
            useInvokeXuen = {
                displayName = "Use Invoke Xuen",
                description = "Automatically use Invoke Xuen when talented",
                type = "toggle",
                default = true
            },
            useBonedustBrew = {
                displayName = "Use Bonedust Brew",
                description = "Automatically use Bonedust Brew when talented",
                type = "toggle",
                default = true
            },
            useExplodingKeg = {
                displayName = "Use Exploding Keg",
                description = "Automatically use Exploding Keg when talented",
                type = "toggle",
                default = true
            },
            explodingKegThreshold = {
                displayName = "Exploding Keg Min Targets",
                description = "Minimum targets to use Exploding Keg",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            },
            useChiWave = {
                displayName = "Use Chi Wave",
                description = "Automatically use Chi Wave when talented",
                type = "toggle",
                default = true
            },
            useChiBurst = {
                displayName = "Use Chi Burst",
                description = "Automatically use Chi Burst when talented",
                type = "toggle",
                default = true
            },
            chiBurstMinTargets = {
                displayName = "Chi Burst Min Targets",
                description = "Minimum targets to use Chi Burst",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            },
            useRushingJadeWind = {
                displayName = "Use Rushing Jade Wind",
                description = "Automatically use Rushing Jade Wind when talented",
                type = "toggle",
                default = true
            },
            rushingJadeWindMinTargets = {
                displayName = "Rushing Jade Wind Min Targets",
                description = "Minimum targets to use Rushing Jade Wind",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            }
        },
        
        utilitySettings = {
            useLegSweep = {
                displayName = "Use Leg Sweep",
                description = "Automatically use Leg Sweep for crowd control",
                type = "toggle",
                default = true
            },
            legSweepMinTargets = {
                displayName = "Leg Sweep Min Targets",
                description = "Minimum targets to use Leg Sweep",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useDetox = {
                displayName = "Use Detox",
                description = "Automatically use Detox to remove harmful effects",
                type = "toggle",
                default = true
            },
            useRingOfPeace = {
                displayName = "Use Ring of Peace",
                description = "Automatically use Ring of Peace",
                type = "toggle",
                default = true
            },
            useVivify = {
                displayName = "Use Vivify",
                description = "Automatically use Vivify for healing",
                type = "toggle",
                default = true
            },
            vivifyThreshold = {
                displayName = "Vivify Health Threshold",
                description = "Health percentage to use Vivify",
                type = "slider",
                min = 20,
                max = 70,
                default = 40
            }
        },
        
        cooldownSettings = {
            preferSerenity = {
                displayName = "Prefer Serenity",
                description = "Prefer Serenity over Storm, Earth, and Fire when both are available",
                type = "toggle",
                default = true
            },
            holdXuenForBurst = {
                displayName = "Hold Xuen for Burst",
                description = "Hold Invoke Xuen for Burst phase",
                type = "toggle",
                default = true
            },
            holdSefForBurst = {
                displayName = "Hold SEF for Burst",
                description = "Hold Storm, Earth, and Fire for Burst phase",
                type = "toggle",
                default = true
            },
            holdSerenityForBurst = {
                displayName = "Hold Serenity for Burst",
                description = "Hold Serenity for Burst phase",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Serenity controls
            serenity = AAC.RegisterAbility(spells.SERENITY, {
                enabled = true,
                useDuringBurstOnly = true,
                requireMarksOfMasteryStacks = 0,
                requireRSKAndFOFOnCooldown = false
            }),
            
            -- Storm, Earth, and Fire controls
            stormEarthFire = AAC.RegisterAbility(spells.STORM_EARTH_AND_FIRE, {
                enabled = true,
                useDuringBurstOnly = true,
                requireMarksOfMasteryStacks = 0,
                maxChargesBeforeBurst = 1
            }),
            
            -- Invoke Xuen controls
            invokeXuen = AAC.RegisterAbility(spells.INVOKE_XUEN, {
                enabled = true,
                useDuringBurstOnly = true,
                preferWithSerenity = true,
                preferWithSEF = false
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
    
    -- Register for energy updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "ENERGY" then
            self:UpdateEnergy()
        end
    end)
    
    -- Register for chi updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "CHI" then
            self:UpdateChi()
        end
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
function Windwalker:UpdateTalentInfo()
    -- Check for important talents
    talents.hasHitCombo = API.HasTalent(spells.HIT_COMBO)
    talents.hasPowerStrikes = API.HasTalent(spells.POWER_STRIKES)
    talents.hasAscension = API.HasTalent(spells.ASCENSION)
    talents.hasChiExplosion = API.HasTalent(spells.CHI_EXPLOSION)
    talents.hasDanceOfChiJi = API.HasTalent(spells.DANCE_OF_CHIJI)
    talents.hasShadowboxingTreads = API.HasTalent(spells.SHADOWBOXING_TREADS)
    talents.hasStrengthOfSpirit = API.HasTalent(spells.STRENGTH_OF_SPIRIT)
    talents.hasMarkOfTheCrane = API.HasTalent(spells.MARK_OF_THE_CRANE)
    talents.hasTeachingsOfTheMonastery = API.HasTalent(spells.TEACHINGS_OF_THE_MONASTERY)
    talents.hasComboBreaker = API.HasTalent(spells.COMBO_BREAKER)
    talents.hasInvokeXuenTheWhiteTiger = API.HasTalent(spells.INVOKE_XUEN_THE_WHITE_TIGER)
    talents.hasTransferThePower = API.HasTalent(spells.TRANSFER_THE_POWER)
    talents.hasXuenBond = API.HasTalent(spells.XUEN_BOND)
    talents.hasSkytouch = API.HasTalent(spells.SKYTOUCH)
    talents.hasSpiritualFocus = API.HasTalent(spells.SPIRITUAL_FOCUS)
    talents.hasCloseToTheHeart = API.HasTalent(spells.CLOSE_TO_THE_HEART)
    talents.hasAwakenedFaeline = API.HasTalent(spells.AWAKENED_FAELINE)
    talents.hasResonantFists = API.HasTalent(spells.RESONANT_FISTS)
    talents.hasMeridianStrikes = API.HasTalent(spells.MERIDIAN_STRIKES)
    talents.hasRisingStar = API.HasTalent(spells.RISING_STAR)
    talents.hasPowerOfTheWhiteTiger = API.HasTalent(spells.POWER_OF_THE_WHITE_TIGER)
    talents.hasChiHarmony = API.HasTalent(spells.CHI_HARMONY)
    talents.hasBountifulBrew = API.HasTalent(spells.BOUNTIFUL_BREW)
    talents.hasDrinkingHornCover = API.HasTalent(spells.DRINKING_HORN_COVER)
    talents.hasDizzyingWinds = API.HasTalent(spells.DIZZYING_WINDS)
    talents.hasAttenuation = API.HasTalent(spells.ATTENUATION)
    talents.hasBonedustBrew = API.HasTalent(spells.BONEDUST_BREW)
    talents.hasFastFeet = API.HasTalent(spells.FAST_FEET)
    talents.hasFerocityOfXuen = API.HasTalent(spells.FEROCITY_OF_XUEN)
    talents.hasFlashingFists = API.HasTalent(spells.FLASHING_FISTS)
    talents.hasForbiddenTechnique = API.HasTalent(spells.FORBIDDEN_TECHNIQUE)
    talents.hasFuryOfXuen = API.HasTalent(spells.FURY_OF_XUEN)
    talents.hasHardenedSoles = API.HasTalent(spells.HARDENED_SOLES)
    talents.hasInnerPeace = API.HasTalent(spells.INNER_PEACE)
    talents.hasPretenseOfInstability = API.HasTalent(spells.PRETENSE_OF_INSTABILITY)
    talents.hasTouchOfSteel = API.HasTalent(spells.TOUCH_OF_STEEL)
    talents.hasWindStorm = API.HasTalent(spells.WIND_STORM)
    talents.hasResonantFlow = API.HasTalent(spells.RESONANT_FLOW)
    talents.hasHandOfTheTiger = API.HasTalent(spells.HAND_OF_THE_TIGER)
    talents.hasDrinkerOfBlood = API.HasTalent(spells.DRINKER_OF_BLOOD)
    talents.hasReverseHarm = API.HasTalent(spells.REVERSE_HARM)
    
    -- War Within Season 2 talents
    talents.hasAncientConcordance = API.HasTalent(spells.ANCIENT_CONCORDANCE)
    talents.hasFaelineHarmony = API.HasTalent(spells.FAELINE_HARMONY)
    talents.hasFlashingFists = API.HasTalent(spells.FLASHING_FISTS)
    talents.hasJadeIgnition = API.HasTalent(spells.JADE_IGNITION)
    talents.hasPathOfTheMonk = API.HasTalent(spells.PATH_OF_THE_MONK)
    talents.hasPressurePoint = API.HasTalent(spells.PRESSURE_POINT)
    talents.hasSpiritOfTheCrane = API.HasTalent(spells.SPIRIT_OF_THE_CRANE)
    talents.hasSpitfire = API.HasTalent(spells.SPITFIRE)
    talents.hasThunderfist = API.HasTalent(spells.THUNDERFIST)
    talents.hasWalkWithTheOx = API.HasTalent(spells.WALK_WITH_THE_OX)
    talents.hasWhiteTigerStatue = API.HasTalent(spells.WHITE_TIGER_STATUE)
    talents.hasZenMeditation = API.HasTalent(spells.ZEN_MEDITATION)
    talents.hasZenSphere = API.HasTalent(spells.ZEN_SPHERE)
    
    -- Set specialized variables based on talents
    if talents.hasHitCombo then
        comboStrikes = true
    end
    
    if talents.hasShadowboxingTreads then
        shadowboxingTreads = true
    end
    
    if talents.hasStrengthOfSpirit then
        strengthOfSpirit = true
    end
    
    if talents.hasMarkOfTheCrane then
        markOfTheCraneActive = true
    end
    
    if talents.hasSerenity then
        serenity = true
    end
    
    if talents.hasInvokeXuenTheWhiteTiger then
        invokeXuen = true
    end
    
    if talents.hasBonedustBrew then
        bonedust = true
    end
    
    if talents.hasChiExplosion then
        chiExplosion = true
    end
    
    if talents.hasZenSphere then
        zenSphere = true
    end
    
    if talents.hasSkytouch then
        skyTouch = true
    end
    
    if API.IsSpellKnown(spells.BLACKOUT_KICK) then
        blackoutKick = true
    end
    
    if API.IsSpellKnown(spells.TIGER_PALM) then
        tigerPalm = true
    end
    
    if API.IsSpellKnown(spells.RISING_SUN_KICK) then
        risingSunKick = true
    end
    
    if API.IsSpellKnown(spells.FISTS_OF_FURY) then
        fistOfFury = true
    end
    
    if API.IsSpellKnown(spells.SPINNING_CRANE_KICK) then
        spinningCraneKick = true
    end
    
    if API.IsSpellKnown(spells.STRIKE_OF_THE_WINDLORD) then
        strikeOfTheWindlord = true
    end
    
    if API.IsSpellKnown(spells.TOUCH_OF_DEATH) then
        touchOfDeath = true
    end
    
    if API.IsSpellKnown(spells.EXPLODING_KEG) then
        explodingKeg = true
    end
    
    if API.IsSpellKnown(spells.FIST_OF_THE_WHITE_TIGER) then
        fistOfTheWhiteTiger = true
    end
    
    if API.IsSpellKnown(spells.CHI_BURST) then
        chiBurst = true
    end
    
    if API.IsSpellKnown(spells.CHI_WAVE) then
        chiWave = true
    end
    
    if talents.hasResonantFlow then
        resonantFlowActive = true
    end
    
    if talents.hasHandOfTheTiger then
        inHandOfTheTiger = true
    end
    
    if talents.hasFastFeet then
        fastFeetActive = true
    end
    
    if talents.hasDrinkerOfBlood then
        drinkerOfBlood = true
    end
    
    -- Initialize ability charges
    stormEarthAndFireCharges = API.GetSpellCharges(spells.STORM_EARTH_AND_FIRE) or 0
    
    -- Initialize chi max (default 5)
    if talents.hasAscension then
        maxChi = 6
    else
        maxChi = 5
    end
    
    -- Reset history of spinners
    if #lastSpinner > 0 then
        lastSpinner = {}
    end
    
    API.PrintDebug("Windwalker Monk talents updated")
    
    return true
end

-- Update energy tracking
function Windwalker:UpdateEnergy()
    currentEnergy = API.GetPlayerPower()
    return true
end

-- Update chi tracking
function Windwalker:UpdateChi()
    currentChi = API.GetPlayerComboPoints() or 0
    return true
end

-- Update target data
function Windwalker:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Mark of the Crane
        if markOfTheCraneActive then
            markOfTheCraneStacks = API.GetDebuffStacks(targetGUID, debuffs.MARK_OF_THE_CRANE) or 0
        end
        
        -- Check Skytouch debuff
        if skyTouch then
            local skytouchInfo = API.GetDebuffInfo(targetGUID, debuffs.SKYTOUCH)
            if skytouchInfo then
                -- Skytouch active on target
                API.PrintDebug("Skytouch active on target")
            end
        end
        
        -- Check Faeline Stomp debuff
        if faeline then
            local faelineInfo = API.GetDebuffInfo(targetGUID, debuffs.FAELINED_STOMP) 
            if faelineInfo then
                faelineHostileActive = true
            else
                faelineHostileActive = false
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius
    
    return true
end

-- Handle combat log events
function Windwalker:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Hit Combo
            if spellID == buffs.HIT_COMBO then
                hitComboActive = true
                hitComboStacks = select(4, API.GetBuffInfo("player", buffs.HIT_COMBO)) or 1
                API.PrintDebug("Hit Combo stacks: " .. tostring(hitComboStacks))
            end
            
            -- Track Power Strikes
            if spellID == buffs.POWER_STRIKES then
                powerStrikesActive = true
                powerStrikesNext = true
                API.PrintDebug("Power Strikes activated")
            end
            
            -- Track Serenity
            if spellID == buffs.SERENITY then
                serenityActive = true
                serenityEndTime = GetTime() + SERENITY_DURATION
                API.PrintDebug("Serenity activated")
            end
            
            -- Track Storm, Earth, and Fire
            if spellID == buffs.STORM_EARTH_AND_FIRE then
                stormEarthAndFireActive = true
                stormEarthAndFireEndTime = GetTime() + STORM_EARTH_FIRE_DURATION
                API.PrintDebug("Storm, Earth, and Fire activated")
            end
            
            -- Track Transfer the Power
            if spellID == buffs.TRANSFER_THE_POWER then
                transferThePowerActive = true
                transferThePowerStacks = select(4, API.GetBuffInfo("player", buffs.TRANSFER_THE_POWER)) or 1
                API.PrintDebug("Transfer the Power stacks: " .. tostring(transferThePowerStacks))
            end
            
            -- Track Dance of Chi-Ji
            if spellID == buffs.DANCE_OF_CHIJI then
                danceOfChiJiActive = true
                danceOfChiJiEndTime = GetTime() + DANCE_OF_CHIJI_DURATION
                API.PrintDebug("Dance of Chi-Ji activated")
            end
            
            -- Track Rushing Jade Wind
            if spellID == buffs.RUSHING_JADE_WIND then
                rushingJadeWindActive = true
                rushingJadeWindEndTime = GetTime() + RUSHING_JADE_WIND_DURATION
                API.PrintDebug("Rushing Jade Wind activated")
            end
            
            -- Track Teachings of the Monastery
            if spellID == buffs.TEACHINGS_OF_THE_MONASTERY then
                teachingsOfTheMonasteryBuff = true
                teachingsOfTheMonasteryBuffStacks = select(4, API.GetBuffInfo("player", buffs.TEACHINGS_OF_THE_MONASTERY)) or 1
                API.PrintDebug("Teachings of the Monastery stacks: " .. tostring(teachingsOfTheMonasteryBuffStacks))
            end
            
            -- Track Blackout Kick buff (free Blackout Kick)
            if spellID == buffs.BLACKOUT_KICK then
                API.PrintDebug("Blackout Kick! (free) activated")
            end
            
            -- Track Combo Breaker buff
            if spellID == buffs.COMBO_BREAKER then
                API.PrintDebug("Combo Breaker activated")
            end
            
            -- Track Pressure Point
            if spellID == buffs.PRESSURE_POINT then
                pressurePoint = true
                pressurePointEndTime = GetTime() + PRESSURE_POINT_DURATION
                pressurePointCount = select(4, API.GetBuffInfo("player", buffs.PRESSURE_POINT)) or 1
                API.PrintDebug("Pressure Point active, stacks: " .. tostring(pressurePointCount))
            end
            
            -- Track Bonedust Brew
            if spellID == buffs.BONEDUST_BREW then
                bonneBuff = true
                API.PrintDebug("Bonedust Brew activated")
            end
            
            -- Track Xuen
            if spellID == buffs.XUEN then
                xuenActive = true
                xuenEndTime = GetTime() + XUEN_DURATION
                API.PrintDebug("Xuen summoned")
            end
            
            -- Track Resonant Flow
            if spellID == buffs.RESONANT_FLOW then
                resonantFlowActive = true
                API.PrintDebug("Resonant Flow activated")
            end
            
            -- Track Reverse Harm
            if spellID == buffs.REVERSE_HARM then
                reverseHarmActive = true
                reverseHarmEndTime = GetTime() + REVERSE_HARM_DURATION
                API.PrintDebug("Reverse Harm activated")
            end
            
            -- Track Touch of Karma
            if spellID == buffs.TOUCH_OF_KARMA then
                touchOfKarmaActive = true
                touchOfKarmaEndTime = GetTime() + TOUCH_OF_KARMA_DURATION
                API.PrintDebug("Touch of Karma activated")
            end
            
            -- Track Fortifying Brew
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = true
                fortifyingBrewEndTime = GetTime() + FORTIFYING_BREW_DURATION
                API.PrintDebug("Fortifying Brew activated")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Hit Combo
            if spellID == buffs.HIT_COMBO then
                hitComboActive = false
                hitComboStacks = 0
                API.PrintDebug("Hit Combo reset")
            end
            
            -- Track Power Strikes
            if spellID == buffs.POWER_STRIKES then
                powerStrikesActive = false
                powerStrikesNext = false
                API.PrintDebug("Power Strikes consumed")
            end
            
            -- Track Serenity
            if spellID == buffs.SERENITY then
                serenityActive = false
                API.PrintDebug("Serenity faded")
            end
            
            -- Track Storm, Earth, and Fire
            if spellID == buffs.STORM_EARTH_AND_FIRE then
                stormEarthAndFireActive = false
                API.PrintDebug("Storm, Earth, and Fire faded")
            end
            
            -- Track Transfer the Power
            if spellID == buffs.TRANSFER_THE_POWER then
                transferThePowerActive = false
                transferThePowerStacks = 0
                API.PrintDebug("Transfer the Power faded")
            end
            
            -- Track Dance of Chi-Ji
            if spellID == buffs.DANCE_OF_CHIJI then
                danceOfChiJiActive = false
                API.PrintDebug("Dance of Chi-Ji faded")
            end
            
            -- Track Rushing Jade Wind
            if spellID == buffs.RUSHING_JADE_WIND then
                rushingJadeWindActive = false
                API.PrintDebug("Rushing Jade Wind faded")
            end
            
            -- Track Teachings of the Monastery
            if spellID == buffs.TEACHINGS_OF_THE_MONASTERY then
                teachingsOfTheMonasteryBuff = false
                teachingsOfTheMonasteryBuffStacks = 0
                API.PrintDebug("Teachings of the Monastery faded")
            end
            
            -- Track Pressure Point
            if spellID == buffs.PRESSURE_POINT then
                pressurePoint = false
                API.PrintDebug("Pressure Point faded")
            end
            
            -- Track Bonedust Brew
            if spellID == buffs.BONEDUST_BREW then
                bonneBuff = false
                API.PrintDebug("Bonedust Brew faded")
            end
            
            -- Track Xuen
            if spellID == buffs.XUEN then
                xuenActive = false
                API.PrintDebug("Xuen despawned")
            end
            
            -- Track Resonant Flow
            if spellID == buffs.RESONANT_FLOW then
                resonantFlowActive = false
                API.PrintDebug("Resonant Flow faded")
            end
            
            -- Track Reverse Harm
            if spellID == buffs.REVERSE_HARM then
                reverseHarmActive = false
                API.PrintDebug("Reverse Harm faded")
            end
            
            -- Track Touch of Karma
            if spellID == buffs.TOUCH_OF_KARMA then
                touchOfKarmaActive = false
                API.PrintDebug("Touch of Karma faded")
            end
            
            -- Track Fortifying Brew
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = false
                API.PrintDebug("Fortifying Brew faded")
            end
        end
    end
    
    -- Track Hit Combo stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.HIT_COMBO and destGUID == API.GetPlayerGUID() then
        hitComboStacks = select(4, API.GetBuffInfo("player", buffs.HIT_COMBO)) or 0
        API.PrintDebug("Hit Combo stacks: " .. tostring(hitComboStacks))
    end
    
    -- Track Transfer the Power stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.TRANSFER_THE_POWER and destGUID == API.GetPlayerGUID() then
        transferThePowerStacks = select(4, API.GetBuffInfo("player", buffs.TRANSFER_THE_POWER)) or 0
        API.PrintDebug("Transfer the Power stacks: " .. tostring(transferThePowerStacks))
    end
    
    -- Track Teachings of the Monastery stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.TEACHINGS_OF_THE_MONASTERY and destGUID == API.GetPlayerGUID() then
        teachingsOfTheMonasteryBuffStacks = select(4, API.GetBuffInfo("player", buffs.TEACHINGS_OF_THE_MONASTERY)) or 0
        API.PrintDebug("Teachings of the Monastery stacks: " .. tostring(teachingsOfTheMonasteryBuffStacks))
    end
    
    -- Track Pressure Point stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.PRESSURE_POINT and destGUID == API.GetPlayerGUID() then
        pressurePointCount = select(4, API.GetBuffInfo("player", buffs.PRESSURE_POINT)) or 0
        API.PrintDebug("Pressure Point stacks: " .. tostring(pressurePointCount))
    end
    
    -- Track spell casts for Combo Strikes
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.TIGER_PALM or
           spellID == spells.BLACKOUT_KICK or
           spellID == spells.RISING_SUN_KICK or
           spellID == spells.FISTS_OF_FURY or
           spellID == spells.SPINNING_CRANE_KICK or
           spellID == spells.STRIKE_OF_THE_WINDLORD or
           spellID == spells.CHI_BURST or
           spellID == spells.CHI_WAVE or
           spellID == spells.WHIRLING_DRAGON_PUNCH or
           spellID == spells.FIST_OF_THE_WHITE_TIGER then
            
            local thisCast = GetSpellInfo(spellID)
            
            if thisCast ~= nil then
                -- Save the current cast for Combo Strikes comparison
                lastAbilityUsed = thisCast
                
                -- Keep track of spinners for Spinning Crane Kick
                if spellID == spells.SPINNING_CRANE_KICK and markOfTheCraneActive then
                    API.PrintDebug("Tracking spinner: " .. thisCast)
                    
                    -- Add to lastSpinner table, tracking up to 5 different abilities to build stacks
                    local foundSpinner = false
                    for i, spinner in ipairs(lastSpinner) do
                        if spinner.name == thisCast then
                            foundSpinner = true
                            break
                        end
                    end
                    
                    if not foundSpinner and #lastSpinner < MAX_SPINNER_COUNT then
                        table.insert(lastSpinner, {name = thisCast, time = GetTime()})
                        API.PrintDebug("Added new spinner: " .. thisCast)
                    end
                end
            end
        end
        
        -- Track specific important spells
        if spellID == spells.RISING_SUN_KICK then
            API.PrintDebug("Rising Sun Kick cast")
        elseif spellID == spells.FISTS_OF_FURY then
            API.PrintDebug("Fists of Fury cast")
        elseif spellID == spells.STORM_EARTH_AND_FIRE then
            stormEarthAndFireCharges = API.GetSpellCharges(spells.STORM_EARTH_AND_FIRE) or 0
            stormEarthAndFireActive = true
            stormEarthAndFireEndTime = GetTime() + STORM_EARTH_FIRE_DURATION
            API.PrintDebug("Storm, Earth, and Fire cast, charges remaining: " .. tostring(stormEarthAndFireCharges))
        elseif spellID == spells.SERENITY then
            serenityActive = true
            serenityEndTime = GetTime() + SERENITY_DURATION
            API.PrintDebug("Serenity cast")
        elseif spellID == spells.STRIKE_OF_THE_WINDLORD then
            API.PrintDebug("Strike of the Windlord cast")
        elseif spellID == spells.INVOKE_XUEN then
            xuenActive = true
            xuenEndTime = GetTime() + XUEN_DURATION
            API.PrintDebug("Invoke Xuen cast")
        elseif spellID == spells.WHIRLING_DRAGON_PUNCH then
            whirlingDragonPunchActive = true
            -- Reset after a short duration
            C_Timer.After(WHIRLING_DRAGON_PUNCH_DURATION, function()
                whirlingDragonPunchActive = false
                API.PrintDebug("Whirling Dragon Punch completed")
            end)
            API.PrintDebug("Whirling Dragon Punch cast")
        elseif spellID == spells.TOUCH_OF_KARMA then
            touchOfKarmaActive = true
            touchOfKarmaEndTime = GetTime() + TOUCH_OF_KARMA_DURATION
            API.PrintDebug("Touch of Karma cast")
        elseif spellID == spells.FORTIFYING_BREW then
            fortifyingBrewActive = true
            fortifyingBrewEndTime = GetTime() + FORTIFYING_BREW_DURATION
            API.PrintDebug("Fortifying Brew cast")
        end
    end
    
    return true
end

-- Check next ability for Combo Strikes
function Windwalker:CheckComboStrikes(spellName)
    if not comboStrikes then
        return true
    end
    
    local name = GetSpellInfo(spellName)
    if name == nil then
        return true
    end
    
    return name ~= lastAbilityUsed
end

-- Calculate spinning crane kick targets for Mark of the Crane
function Windwalker:CalculateSCKTargets()
    if markOfTheCraneActive then
        -- Clean up expired spinners (older than 15 seconds)
        for i = #lastSpinner, 1, -1 do
            if GetTime() - lastSpinner[i].time > 15 then
                table.remove(lastSpinner, i)
            end
        end
        
        -- Count unique spinners
        local count = 0
        local spinners = {}
        for _, spinner in ipairs(lastSpinner) do
            if not spinners[spinner.name] then
                spinners[spinner.name] = true
                count = count + 1
            end
        end
        
        return count
    else
        return 1 -- Just return 1 if no Mark of the Crane
    end
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
    self:UpdateEnergy()
    self:UpdateChi()
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
    
    -- Skip if not in melee range and can't use ranged abilities
    if not inMeleeRange and not self:HandleRangedAbilities(settings) then
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
function Windwalker:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.SPEAR_HAND_STRIKE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.SPEAR_HAND_STRIKE)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Windwalker:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Touch of Karma
    if settings.defensiveSettings.useTouchOfKarma and
       playerHealth <= settings.defensiveSettings.touchOfKarmaThreshold and
       API.CanCast(spells.TOUCH_OF_KARMA) then
        API.CastSpell(spells.TOUCH_OF_KARMA)
        return true
    end
    
    -- Use Fortifying Brew
    if settings.defensiveSettings.useFortifyingBrew and
       playerHealth <= settings.defensiveSettings.fortifyingBrewThreshold and
       API.CanCast(spells.FORTIFYING_BREW) then
        API.CastSpell(spells.FORTIFYING_BREW)
        return true
    end
    
    -- Use Diffuse Magic
    if settings.defensiveSettings.useDiffuseMagic and
       API.IsPlayerTakingMagicDamage() and
       API.CanCast(spells.DIFFUSE_MAGIC) then
        API.CastSpell(spells.DIFFUSE_MAGIC)
        return true
    end
    
    -- Use Dampen Harm
    if settings.defensiveSettings.useDampenHarm and
       playerHealth <= settings.defensiveSettings.dampenHarmThreshold and
       API.CanCast(spells.DAMPEN_HARM) then
        API.CastSpell(spells.DAMPEN_HARM)
        return true
    end
    
    -- Use Expel Harm
    if settings.defensiveSettings.useExpelHarm and
       playerHealth <= settings.defensiveSettings.expelHarmThreshold and
       API.CanCast(spells.EXPEL_HARM) then
        API.CastSpell(spells.EXPEL_HARM)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Windwalker:HandleRangedAbilities(settings)
    -- Use Chi Burst
    if chiBurst and
       settings.offensiveSettings.useChiBurst and
       currentAoETargets >= settings.offensiveSettings.chiBurstMinTargets and
       API.CanCast(spells.CHI_BURST) and
       self:CheckComboStrikes(spells.CHI_BURST) then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Use Chi Wave
    if chiWave and
       settings.offensiveSettings.useChiWave and
       API.CanCast(spells.CHI_WAVE) and
       self:CheckComboStrikes(spells.CHI_WAVE) then
        API.CastSpell(spells.CHI_WAVE)
        return true
    end
    
    -- Use Flying Serpent Kick to get into melee range if needed
    if API.CanCast(spells.FLYING_SERPENT_KICK) and API.IsUnitInRange("target", 30) then
        API.CastSpell(spells.FLYING_SERPENT_KICK)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Windwalker:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in combat
    if not API.IsInCombat() then
        return false
    }
    
    -- Use Touch of Death
    if touchOfDeath and
       settings.offensiveSettings.useTouchOfDeath and
       API.CanCast(spells.TOUCH_OF_DEATH) then
        API.CastSpell(spells.TOUCH_OF_DEATH)
        return true
    end
    
    -- Use major cooldowns in the correct order depending on settings
    
    -- Invoke Xuen
    if invokeXuen and
       settings.offensiveSettings.useInvokeXuen and
       settings.abilityControls.invokeXuen.enabled and
       API.CanCast(spells.INVOKE_XUEN) and
       (not settings.cooldownSettings.holdXuenForBurst or burstModeActive) then
       
        -- Check if we want to sync with Serenity or SEF
        local shouldUse = false
        
        if settings.abilityControls.invokeXuen.preferWithSerenity and serenityActive then
            shouldUse = true
        elseif settings.abilityControls.invokeXuen.preferWithSEF and stormEarthAndFireActive then
            shouldUse = true
        elseif not settings.abilityControls.invokeXuen.preferWithSerenity and not settings.abilityControls.invokeXuen.preferWithSEF then
            shouldUse = true
        end
        
        if shouldUse and (not settings.abilityControls.invokeXuen.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.INVOKE_XUEN)
            return true
        end
    end
    
    -- Use Serenity
    if talents.hasSerenity and
       settings.rotationSettings.useSerenity and
       settings.abilityControls.serenity.enabled and
       API.CanCast(spells.SERENITY) and
       (not settings.cooldownSettings.holdSerenityForBurst or burstModeActive) then
       
        -- Check if we need Rising Sun Kick and Fists of Fury to be on cooldown
        local canUse = true
        if settings.abilityControls.serenity.requireRSKAndFOFOnCooldown then
            if API.GetSpellCooldown(spells.RISING_SUN_KICK) == 0 or API.GetSpellCooldown(spells.FISTS_OF_FURY) == 0 then
                canUse = false
            end
        end
        
        if canUse and (not settings.abilityControls.serenity.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.SERENITY)
            return true
        end
    end
    
    -- Use Storm, Earth, and Fire
    if settings.rotationSettings.useStormEarthFire and
       settings.abilityControls.stormEarthFire.enabled and
       stormEarthAndFireCharges > 0 and
       (not serenity or not settings.cooldownSettings.preferSerenity) and -- Prefer Serenity if available
       API.CanCast(spells.STORM_EARTH_AND_FIRE) and
       (not settings.cooldownSettings.holdSefForBurst or burstModeActive) then
       
        -- Check if we should reserve charges for burst
        local canUse = true
        if settings.abilityControls.stormEarthFire.useDuringBurstOnly and !burstModeActive and 
           stormEarthAndFireCharges <= settings.abilityControls.stormEarthFire.maxChargesBeforeBurst then
            canUse = false
        end
        
        if canUse then
            API.CastSpell(spells.STORM_EARTH_AND_FIRE)
            return true
        end
    end
    
    -- Use Bonedust Brew
    if bonedust and
       settings.offensiveSettings.useBonedustBrew and
       API.CanCast(spells.BONEDUST_BREW) then
        API.CastSpellAtCursor(spells.BONEDUST_BREW)
        return true
    end
    
    -- Use Exploding Keg
    if explodingKeg and
       settings.offensiveSettings.useExplodingKeg and
       currentAoETargets >= settings.offensiveSettings.explodingKegThreshold and
       API.CanCast(spells.EXPLODING_KEG) then
        API.CastSpellAtCursor(spells.EXPLODING_KEG)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Windwalker:HandleAoERotation(settings)
    -- Whirling Dragon Punch has high priority in AoE
    if API.IsSpellKnown(spells.WHIRLING_DRAGON_PUNCH) and
       (settings.rotationSettings.whirlingDragonPunchMode == "On Cooldown" or 
        settings.rotationSettings.whirlingDragonPunchMode == "AoE Only") and
       API.CanCast(spells.WHIRLING_DRAGON_PUNCH) and
       self:CheckComboStrikes(spells.WHIRLING_DRAGON_PUNCH) then
        API.CastSpell(spells.WHIRLING_DRAGON_PUNCH)
        return true
    end
    
    -- Use Rushing Jade Wind
    if talents.hasRushingJadeWind and
       settings.offensiveSettings.useRushingJadeWind and
       currentAoETargets >= settings.offensiveSettings.rushingJadeWindMinTargets and
       API.CanCast(spells.RUSHING_JADE_WIND) and
       self:CheckComboStrikes(spells.RUSHING_JADE_WIND) then
        API.CastSpell(spells.RUSHING_JADE_WIND)
        return true
    end
    
    -- Strike of the Windlord - high AoE priority
    if strikeOfTheWindlord and
       currentChi >= 2 and
       API.CanCast(spells.STRIKE_OF_THE_WINDLORD) and 
       self:CheckComboStrikes(spells.STRIKE_OF_THE_WINDLORD) then
        API.CastSpell(spells.STRIKE_OF_THE_WINDLORD)
        return true
    end
    
    -- Spinning Crane Kick if we have Dance of Chi-Ji proc
    if spinningCraneKick and
       danceOfChiJiActive and
       currentChi >= 2 and
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       self:CheckComboStrikes(spells.SPINNING_CRANE_KICK) then
        API.CastSpell(spells.SPINNING_CRANE_KICK)
        return true
    end
    
    -- Fists of Fury - major AoE ability
    if fistOfFury and
       currentChi >= 3 and
       API.CanCast(spells.FISTS_OF_FURY) and
       self:CheckComboStrikes(spells.FISTS_OF_FURY) then
        API.CastSpell(spells.FISTS_OF_FURY)
        return true
    end
    
    -- Chi Burst for AoE
    if chiBurst and
       settings.offensiveSettings.useChiBurst and
       currentAoETargets >= settings.offensiveSettings.chiBurstMinTargets and
       API.CanCast(spells.CHI_BURST) and
       self:CheckComboStrikes(spells.CHI_BURST) then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Rising Sun Kick is still important to use in AoE
    if risingSunKick and
       currentChi >= 2 and
       API.CanCast(spells.RISING_SUN_KICK) and
       self:CheckComboStrikes(spells.RISING_SUN_KICK) then
        API.CastSpell(spells.RISING_SUN_KICK)
        return true
    end
    
    -- Spinning Crane Kick for sustained AoE damage
    if spinningCraneKick and
       currentChi >= 2 and
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       self:CheckComboStrikes(spells.SPINNING_CRANE_KICK) then
        
        -- Calculate effectiveness of Spinning Crane Kick
        local sckTargets = self:CalculateSCKTargets()
        if sckTargets >= 2 or currentAoETargets >= 3 then
            API.CastSpell(spells.SPINNING_CRANE_KICK)
            return true
        end
    end
    
    -- Blackout Kick (with free proc) - maintain combo strikes
    if blackoutKick and
       API.PlayerHasBuff(buffs.BLACKOUT_KICK) and
       API.CanCast(spells.BLACKOUT_KICK) and
       self:CheckComboStrikes(spells.BLACKOUT_KICK) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Chi Wave can be useful in AoE
    if chiWave and
       settings.offensiveSettings.useChiWave and
       API.CanCast(spells.CHI_WAVE) and
       self:CheckComboStrikes(spells.CHI_WAVE) then
        API.CastSpell(spells.CHI_WAVE)
        return true
    end
    
    -- Fist of the White Tiger for Chi generation in AoE
    if fistOfTheWhiteTiger and
       currentChi <= maxChi - 3 and -- Room for Chi
       API.CanCast(spells.FIST_OF_THE_WHITE_TIGER) and
       self:CheckComboStrikes(spells.FIST_OF_THE_WHITE_TIGER) then
        API.CastSpell(spells.FIST_OF_THE_WHITE_TIGER)
        return true
    end
    
    -- Blackout Kick (regular usage)
    if blackoutKick and
       currentChi >= 1 and
       API.CanCast(spells.BLACKOUT_KICK) and
       self:CheckComboStrikes(spells.BLACKOUT_KICK) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Tiger Palm for Chi generation
    if tigerPalm and
       currentChi <= maxChi - 2 and -- Room for Chi
       currentEnergy >= 50 and
       API.CanCast(spells.TIGER_PALM) and
       self:CheckComboStrikes(spells.TIGER_PALM) then
        API.CastSpell(spells.TIGER_PALM)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Windwalker:HandleSingleTargetRotation(settings)
    -- Whirling Dragon Punch if available
    if API.IsSpellKnown(spells.WHIRLING_DRAGON_PUNCH) and
       (settings.rotationSettings.whirlingDragonPunchMode == "On Cooldown" || 
        (settings.rotationSettings.whirlingDragonPunchMode == "Burst Only" && burstModeActive)) and
       API.CanCast(spells.WHIRLING_DRAGON_PUNCH) and
       self:CheckComboStrikes(spells.WHIRLING_DRAGON_PUNCH) then
        API.CastSpell(spells.WHIRLING_DRAGON_PUNCH)
        return true
    end
    
    -- Strike of the Windlord - high priority
    if strikeOfTheWindlord and
       currentChi >= 2 and
       API.CanCast(spells.STRIKE_OF_THE_WINDLORD) and 
       self:CheckComboStrikes(spells.STRIKE_OF_THE_WINDLORD) then
        API.CastSpell(spells.STRIKE_OF_THE_WINDLORD)
        return true
    end
    
    -- Rising Sun Kick - high priority single target
    if risingSunKick and
       currentChi >= 2 and
       API.CanCast(spells.RISING_SUN_KICK) and
       self:CheckComboStrikes(spells.RISING_SUN_KICK) then
        API.CastSpell(spells.RISING_SUN_KICK)
        return true
    end
    
    -- Fists of Fury - major damage dealer
    if fistOfFury and
       currentChi >= 3 and
       API.CanCast(spells.FISTS_OF_FURY) and
       self:CheckComboStrikes(spells.FISTS_OF_FURY) then
        API.CastSpell(spells.FISTS_OF_FURY)
        return true
    end
    
    -- Spinning Crane Kick with Dance of Chi-Ji proc
    if spinningCraneKick and
       danceOfChiJiActive and
       currentChi >= 2 and
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       self:CheckComboStrikes(spells.SPINNING_CRANE_KICK) then
        API.CastSpell(spells.SPINNING_CRANE_KICK)
        return true
    end
    
    -- Blackout Kick (with free proc)
    if blackoutKick and
       API.PlayerHasBuff(buffs.BLACKOUT_KICK) and
       API.CanCast(spells.BLACKOUT_KICK) and
       self:CheckComboStrikes(spells.BLACKOUT_KICK) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Chi Wave
    if chiWave and
       settings.offensiveSettings.useChiWave and
       API.CanCast(spells.CHI_WAVE) and
       self:CheckComboStrikes(spells.CHI_WAVE) then
        API.CastSpell(spells.CHI_WAVE)
        return true
    end
    
    -- Chi Burst (single target)
    if chiBurst and
       settings.offensiveSettings.useChiBurst and
       API.CanCast(spells.CHI_BURST) and
       self:CheckComboStrikes(spells.CHI_BURST) then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Blackout Kick (regular usage)
    if blackoutKick and
       currentChi >= 1 and
       API.CanCast(spells.BLACKOUT_KICK) and
       self:CheckComboStrikes(spells.BLACKOUT_KICK) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Fist of the White Tiger for Chi generation
    if fistOfTheWhiteTiger and
       currentChi <= maxChi - 3 and -- Room for Chi
       API.CanCast(spells.FIST_OF_THE_WHITE_TIGER) and
       self:CheckComboStrikes(spells.FIST_OF_THE_WHITE_TIGER) then
        API.CastSpell(spells.FIST_OF_THE_WHITE_TIGER)
        return true
    end
    
    -- Tiger Palm for Chi generation
    if tigerPalm and
       currentChi <= maxChi - 2 and -- Room for Chi
       (not settings.rotationSettings.energyPooling || 
        currentEnergy >= settings.rotationSettings.energyPoolingThreshold) and
       API.CanCast(spells.TIGER_PALM) and
       self:CheckComboStrikes(spells.TIGER_PALM) then
        API.CastSpell(spells.TIGER_PALM)
        return true
    end
    
    -- Rushing Jade Wind
    if talents.hasRushingJadeWind and
       settings.offensiveSettings.useRushingJadeWind and
       API.CanCast(spells.RUSHING_JADE_WIND) and
       self:CheckComboStrikes(spells.RUSHING_JADE_WIND) then
        API.CastSpell(spells.RUSHING_JADE_WIND)
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
    currentAoETargets = 0
    currentEnergy = API.GetPlayerPower()
    maxEnergy = 100
    currentChi = API.GetPlayerComboPoints() or 0
    maxChi = 5
    tigersFuryActive = false
    tigersFuryEndTime = 0
    hitComboActive = false
    hitComboStacks = 0
    powerStrikesActive = false
    serenityActive = false
    serenityEndTime = 0
    stormEarthAndFireActive = false
    stormEarthAndFireCharges = 0
    stormEarthAndFireEndTime = 0
    whirlingDragonPunchActive = false
    lastAbilityUsed = ""
    fistOfTheWhiteTigerActive = false
    transferThePowerActive = false
    transferThePowerStacks = 0
    danceOfChiJiActive = false
    danceOfChiJiEndTime = 0
    rushingJadeWindActive = false
    rushingJadeWindEndTime = 0
    powerStrikesNext = false
    blackoutKick = false
    tigerPalm = false
    risingSunKick = false
    fistOfFury = false
    spinningCraneKick = false
    strikeOfTheWindlord = false
    touchOfDeath = false
    explodingKeg = false
    fistOfTheWhiteTiger = false
    chiBurst = false
    chiWave = false
    invokeXuenTheWhiteTiger = false
    faeline = false
    faelineFriendlyActive = false
    faelineHostileActive = false
    bonneBuff = false
    skyreachExhaustion = false
    pressurePoint = false
    pressurePointEndTime = 0
    pressurePointCount = 0
    markOfTheCraneStacks = 0
    comboStrikes = false
    markOfTheCraneActive = false
    strengthOfSpirit = false
    shadowboxingTreads = false
    inMeleeRange = false
    teachingsOfTheMonasteryBuff = false
    teachingsOfTheMonasteryBuffStacks = 0
    resonantFlowActive = false
    inHandOfTheTiger = false
    fastFeetActive = false
    drinkerOfBlood = false
    reverseHarmActive = false
    reverseHarmEndTime = 0
    touchOfKarmaActive = false
    touchOfKarmaEndTime = 0
    fortifyingBrewActive = false
    fortifyingBrewEndTime = 0
    serenity = false
    invokeXuen = false
    bonedust = false
    chiExplosion = false
    zenSphere = false
    xuenActive = false
    xuenEndTime = 0
    skyTouch = false
    lastSpinner = {}
    
    API.PrintDebug("Windwalker Monk state reset on spec change")
    
    return true
end

-- Return the module for loading
return Windwalker