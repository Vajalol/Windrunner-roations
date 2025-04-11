------------------------------------------
-- WindrunnerRotations - Brewmaster Monk Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Brewmaster = {}
-- This will be assigned to addon.Classes.Monk.Brewmaster when loaded

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
local staggerLevel = "none" -- none, light, moderate, heavy
local staggerPercentage = 0
local tigerPalmCount = 0
local blackoutKickActive = false
local blackoutKickEndTime = 0
local blackoutComboActive = false
local celestialBrewCharges = 0
local celestialBrewMaxCharges = 0
local purifyingBrewCharges = 0
local purifyingBrewMaxCharges = 0
local explodingKegOnCooldown = false
local explodingKegCooldownRemaining = 0
local spinningCraneKickActive = false
local weaponsOfOrderActive = false
local weaponsOfOrderEndTime = 0
local fallenOrderActive = false
local fallenOrderEndTime = 0
local boneDustBrewActive = false
local boneDustBrewEndTime = 0
local callToArmsActive = false
local charredPassionsActive = false
local charredPassionsStacks = 0
local invokeNiuzaoActivated = false
local invokeNiuzaoEndTime = 0
local faelineStompOnCooldown = false
local faelineResonance = false
local lastBrewUsed = 0
local lastBrewTime = 0
local lastPurifyTime = 0
local celestialFlamesStacks = 0
local kegSmashCharges = 0
local breathOfFireOnCooldown = false
local breathOfFireEndTime = 0
local charredPassionsCooldownRemaining = 0
local rushingJadeWindActive = false
local rushingJadeWindEndTime = 0
local shuffleActive = false
local shuffleEndTime = 0
local fortifyingIngredientsActive = false
local fortifyingIngredientsStacks = 0
local staggeredHits = 0
local zensphereActive = false
local detoxEnergy = false
local sleepingShadow = false
local scaleSadness = false
local touchOfDeath = false
local touchOfKarma = false
local callOfTheOx = false
local dampenHarmActive = false
local dampenHarmEndTime = 0
local dampenHarmStacks = 0
local dampenHarmMaxStacks = 0
local fortifyingBrewActive = false
local fortifyingBrewEndTime = 0
local lightBrewingActive = false
local giftsOfTheOxActive = false
local giftsOfTheOxCount = 0
local hitComboActive = false
local hitComboStacks = 0
local hitComboEndTime = 0
local zenMeditationActive = false
local inMeleeRange = false
local inMeleeDamageRange = false

-- Constants
local BREWMASTER_SPEC_ID = 268
local DEFAULT_AOE_THRESHOLD = 3
local MELEE_RANGE = 5 -- Typical melee range in yards
local LIGHT_STAGGER_THRESHOLD = 30 -- Percentage threshold for light stagger
local MODERATE_STAGGER_THRESHOLD = 60 -- Percentage threshold for moderate stagger
local HEAVY_STAGGER_THRESHOLD = 80 -- Percentage threshold for heavy stagger
local FORTIFYING_BREW_DURATION = 15 -- seconds
local ZEN_MEDITATION_DURATION = 8 -- seconds
local DAMPEN_HARM_DURATION = 10 -- seconds
local SHUFFLE_DURATION = 15 -- seconds
local BLACKOUT_COMBO_DURATION = 15 -- seconds
local RUSHING_JADE_WIND_DURATION = 9 -- seconds
local WEAPONS_OF_ORDER_DURATION = 30 -- seconds
local FALLEN_ORDER_DURATION = 24 -- seconds
local BONE_DUST_BREW_DURATION = 10 -- seconds
local INVOKE_NIUZAO_DURATION = 25 -- seconds
local KEG_SMASH_COOLDOWN = 8 -- seconds
local BREATH_OF_FIRE_COOLDOWN = 15 -- seconds
local EXPLODING_KEG_COOLDOWN = 60 -- seconds
local TIGER_PALM_COST = 25 -- Energy cost
local BLACKOUT_KICK_COST = 0 -- No Energy cost in Brewmaster
local KEG_SMASH_COST = 40 -- Energy cost
local SPINNING_CRANE_KICK_COST = 15 -- Energy cost

-- Initialize the Brewmaster module
function Brewmaster:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Brewmaster Monk module initialized")
    
    return true
end

-- Register spell IDs
function Brewmaster:RegisterSpells()
    -- Core rotational abilities
    spells.TIGER_PALM = 100780
    spells.BLACKOUT_KICK = 205523
    spells.KEG_SMASH = 121253
    spells.BREATH_OF_FIRE = 115181
    spells.SPINNING_CRANE_KICK = 101546
    spells.RUSHING_JADE_WIND = 116847
    spells.EXPLODING_KEG = 325153
    spells.CHI_BURST = 123986
    spells.CHI_WAVE = 115098
    
    -- Defensive abilities
    spells.PURIFYING_BREW = 119582
    spells.CELESTIAL_BREW = 322507
    spells.FORTIFYING_BREW = 115203
    spells.ZEN_MEDITATION = 115176
    spells.DAMPEN_HARM = 122278
    spells.EXPEL_HARM = 322101
    spells.HEALING_ELIXIR = 122281
    
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
    spells.CLASH = 324312
    spells.SPEAR_HAND_STRIKE = 116705
    
    -- Talents and passives
    spells.BLACKOUT_COMBO = 196736
    spells.LIGHT_BREWING = 325093
    spells.BLACK_OX_BREW = 115399
    spells.SUMMON_BLACK_OX_STATUE = 115315
    spells.INVOKE_NIUZAO = 132578
    spells.SPECIAL_DELIVERY = 196730
    spells.HIGH_TOLERANCE = 196737
    spells.CELESTIAL_FLAMES = 325177
    spells.SHUFFLE = 215479
    spells.STAGGER = 115069
    spells.PURIFIED_CHI = 325092
    spells.GIFT_OF_THE_OX = 124502
    spells.CELESTIAL_FORTUNE = 216519
    spells.CHARRED_PASSIONS = 386965
    spells.PRESS_THE_ADVANTAGE = 418359
    spells.TOUCH_OF_DEATH = 115080
    spells.TOUCH_OF_KARMA = 122470
    spells.CALL_TO_ARMS = 397251
    spells.IMPROVED_INVOKE_NIUZAO = 322740
    spells.QUICK_SIP = 388812
    spells.GRACE_OF_THE_CRANE = 388811
    spells.CALL_OF_THE_OX = 388809
    spells.CELESTIAL_HARMONY = 388995
    spells.ELUSIVE_FOOTWORK = 387046
    spells.BOB_AND_WEAVE = 387048
    spells.ATTENUATION = 386941
    spells.IMPROVED_CELESTIAL_BREW = 322510
    spells.STRENGTH_OF_SPIRIT = 387276
    spells.HIT_COMBO = 196741
    spells.MIGHTY_POUR = 387181
    spells.FUNDAMENTAL_OBSERVATION = 387044
    spells.PRETENSE_OF_INSTABILITY = 393516
    spells.IMPROVED_PURIFYING_BREW = 343743
    spells.FORTIFYING_INGREDIENTS = 405417
    spells.STAGGERED_HITS = 418359
    spells.NIMBLE_BREW = 213664
    spells.FACE_PALM = 389942
    spells.ZEN_MEDITATION_TALENT = 115176
    spells.ESCAPE_FROM_REALITY = 394110
    spells.GENEROUS_POUR = 389575
    spells.SLEEPY_SHADOW = 394093
    spells.SCALE_SADNESS = 405274
    spells.IMPROVED_BREATH_OF_FIRE = 322964
    spells.SALSALABIMS_STRENGTH = 387239
    spells.WALK_WITH_THE_OX = 387220
    spells.ADMONISHMENT = 207025
    
    -- War Within Season 2 specific
    spells.RUSHING_TIGER_PALM = 387621
    spells.FLURRY_OF_FISTS = 405039
    spells.FLUIDITY_OF_MOTION = 387230
    spells.FAELINE_STOMP = 388193
    spells.SHADOWBOXING_TREADS = 387638

    -- Covenant abilities (for reference, may not be current)
    spells.WEAPONS_OF_ORDER = 310454
    spells.FALLEN_ORDER = 326860
    spells.BONEDUST_BREW = 386276
    spells.FAELINE_STOMP = 327104
    
    -- Buff IDs
    spells.SHUFFLE_BUFF = 215479
    spells.BLACKOUT_COMBO_BUFF = 228563
    spells.RUSHING_JADE_WIND_BUFF = 116847
    spells.WEAPONS_OF_ORDER_BUFF = 310454
    spells.FALLEN_ORDER_BUFF = 326860
    spells.BONEDUST_BREW_BUFF = 386276
    spells.LIGHT_STAGGER_BUFF = 124275
    spells.MODERATE_STAGGER_BUFF = 124274
    spells.HEAVY_STAGGER_BUFF = 124273
    spells.FORTIFYING_BREW_BUFF = 115203
    spells.ZEN_MEDITATION_BUFF = 115176
    spells.DAMPEN_HARM_BUFF = 122278
    spells.CELESTIAL_FLAMES_BUFF = 325190
    spells.CELESTIAL_FORTUNE_BUFF = 216519
    spells.CHARRED_PASSIONS_BUFF = 386963
    spells.INVOKE_NIUZAO_BUFF = 132578
    spells.GIFTS_OF_THE_OX_BUFF = 124502
    spells.HIT_COMBO_BUFF = 196741
    spells.FAELINE_STOMP_BUFF = 388193
    spells.FORTIFYING_INGREDIENTS_BUFF = 405417
    
    -- Debuff IDs
    spells.KEG_SMASH_DEBUFF = 121253
    spells.BREATH_OF_FIRE_DEBUFF = 123725
    spells.EXPLODING_KEG_DEBUFF = 325153
    spells.CLASH_DEBUFF = 324312
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SHUFFLE = spells.SHUFFLE_BUFF
    buffs.BLACKOUT_COMBO = spells.BLACKOUT_COMBO_BUFF
    buffs.RUSHING_JADE_WIND = spells.RUSHING_JADE_WIND_BUFF
    buffs.WEAPONS_OF_ORDER = spells.WEAPONS_OF_ORDER_BUFF
    buffs.FALLEN_ORDER = spells.FALLEN_ORDER_BUFF
    buffs.BONEDUST_BREW = spells.BONEDUST_BREW_BUFF
    buffs.LIGHT_STAGGER = spells.LIGHT_STAGGER_BUFF
    buffs.MODERATE_STAGGER = spells.MODERATE_STAGGER_BUFF
    buffs.HEAVY_STAGGER = spells.HEAVY_STAGGER_BUFF
    buffs.FORTIFYING_BREW = spells.FORTIFYING_BREW_BUFF
    buffs.ZEN_MEDITATION = spells.ZEN_MEDITATION_BUFF
    buffs.DAMPEN_HARM = spells.DAMPEN_HARM_BUFF
    buffs.CELESTIAL_FLAMES = spells.CELESTIAL_FLAMES_BUFF
    buffs.CELESTIAL_FORTUNE = spells.CELESTIAL_FORTUNE_BUFF
    buffs.CHARRED_PASSIONS = spells.CHARRED_PASSIONS_BUFF
    buffs.INVOKE_NIUZAO = spells.INVOKE_NIUZAO_BUFF
    buffs.GIFTS_OF_THE_OX = spells.GIFTS_OF_THE_OX_BUFF
    buffs.HIT_COMBO = spells.HIT_COMBO_BUFF
    buffs.FAELINE_STOMP = spells.FAELINE_STOMP_BUFF
    buffs.FORTIFYING_INGREDIENTS = spells.FORTIFYING_INGREDIENTS_BUFF
    
    debuffs.KEG_SMASH = spells.KEG_SMASH_DEBUFF
    debuffs.BREATH_OF_FIRE = spells.BREATH_OF_FIRE_DEBUFF
    debuffs.EXPLODING_KEG = spells.EXPLODING_KEG_DEBUFF
    debuffs.CLASH = spells.CLASH_DEBUFF
    
    return true
end

-- Register variables to track
function Brewmaster:RegisterVariables()
    -- Talent tracking
    talents.hasBlackoutCombo = false
    talents.hasLightBrewing = false
    talents.hasBlackOxBrew = false
    talents.hasSummonBlackOxStatue = false
    talents.hasInvokeNiuzao = false
    talents.hasSpecialDelivery = false
    talents.hasHighTolerance = false
    talents.hasCelestialFlames = false
    talents.hasPurifiedChi = false
    talents.hasCelestialFortune = false
    talents.hasCharredPassions = false
    talents.hasPressTheAdvantage = false
    talents.hasTouchOfDeath = false
    talents.hasTouchOfKarma = false
    talents.hasCallToArms = false
    talents.hasImprovedInvokeNiuzao = false
    talents.hasQuickSip = false
    talents.hasGraceOfTheCrane = false
    talents.hasCallOfTheOx = false
    talents.hasCelestialHarmony = false
    talents.hasElusiveFootwork = false
    talents.hasBobAndWeave = false
    talents.hasAttenuation = false
    talents.hasImprovedCelestialBrew = false
    talents.hasStrengthOfSpirit = false
    talents.hasHitCombo = false
    talents.hasMightyPour = false
    talents.hasFundamentalObservation = false
    talents.hasPretenseOfInstability = false
    talents.hasImprovedPurifyingBrew = false
    talents.hasFortifyingIngredients = false
    talents.hasStaggeredHits = false
    talents.hasNimbleBrew = false
    talents.hasFacePalm = false
    talents.hasZenMeditation = false
    talents.hasEscapeFromReality = false
    talents.hasGenerousPour = false
    talents.hasSleepyShadow = false
    talents.hasScaleSadness = false
    talents.hasImprovedBreathOfFire = false
    talents.hasSalsalabimStrength = false
    talents.hasWalkWithTheOx = false
    talents.hasAdmonishment = false
    talents.hasRushingTigerPalm = false
    talents.hasFlurryOfFists = false
    talents.hasFluidityOfMotion = false
    talents.hasFaelineStomp = false
    talents.hasShadowboxingTreads = false
    
    -- Initialize resources
    currentEnergy = API.GetPlayerPower()
    currentChi = API.GetPlayerComboPoints() or 0
    
    -- Initialize brew charges
    celestialBrewCharges = API.GetSpellCharges(spells.CELESTIAL_BREW) or 0
    celestialBrewMaxCharges = API.GetSpellMaxCharges(spells.CELESTIAL_BREW) or 1
    purifyingBrewCharges = API.GetSpellCharges(spells.PURIFYING_BREW) or 0
    purifyingBrewMaxCharges = API.GetSpellMaxCharges(spells.PURIFYING_BREW) or 2
    
    -- Initialize ability charges
    kegSmashCharges = API.GetSpellCharges(spells.KEG_SMASH) or 0
    
    return true
end

-- Register spec-specific settings
function Brewmaster:RegisterSettings()
    ConfigRegistry:RegisterSettings("BrewmasterMonk", {
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
            kegSmashPriority = {
                displayName = "Keg Smash Priority",
                description = "How to prioritize Keg Smash",
                type = "dropdown",
                options = {"On Cooldown", "When Available", "With Blackout Combo"},
                default = "On Cooldown"
            },
            breathOfFirePriority = {
                displayName = "Breath of Fire Priority",
                description = "How to prioritize Breath of Fire",
                type = "dropdown",
                options = {"On Cooldown", "After Keg Smash", "With Blackout Combo"},
                default = "After Keg Smash"
            },
            useBlackoutKick = {
                displayName = "Use Blackout Kick",
                description = "When to use Blackout Kick",
                type = "dropdown",
                options = {"High Priority", "Low Priority", "For Shuffle Only"},
                default = "High Priority"
            },
            useRushingJadeWind = {
                displayName = "Use Rushing Jade Wind",
                description = "Automatically use Rushing Jade Wind when talented",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            purifyingBrewStrategy = {
                displayName = "Purifying Brew Strategy",
                description = "When to use Purifying Brew",
                type = "dropdown",
                options = {"Light Stagger", "Moderate Stagger", "Heavy Stagger Only", "Smart Management"},
                default = "Smart Management"
            },
            celestialBrewStrategy = {
                displayName = "Celestial Brew Strategy",
                description = "When to use Celestial Brew",
                type = "dropdown",
                options = {"On Cooldown", "With Purifying Buff", "Emergency Only"},
                default = "With Purifying Buff"
            },
            purifyingBrewThreshold = {
                displayName = "Purifying Brew Stagger Threshold",
                description = "Stagger percentage to use Purifying Brew",
                type = "slider",
                min = 10,
                max = 100,
                default = 60
            },
            celestialBrewThreshold = {
                displayName = "Celestial Brew Health Threshold",
                description = "Health percentage to use Celestial Brew",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            minCelestialBrewStacks = {
                displayName = "Min Celestial Brew Stacks",
                description = "Minimum Purified Chi stacks to use Celestial Brew",
                type = "slider",
                min = 0,
                max = 10,
                default = 2
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
                max = 60,
                default = 35
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
                min = 20,
                max = 70,
                default = 40
            },
            useExpelHarm = {
                displayName = "Use Expel Harm",
                description = "Automatically use Expel Harm",
                type = "toggle",
                default = true
            },
            expelHarmThreshold = {
                displayName = "Expel Harm Health Threshold",
                description = "Health percentage to use Expel Harm",
                type = "slider",
                min = 30,
                max = 80,
                default = 65
            },
            expelHarmOrbCount = {
                displayName = "Expel Harm Orb Count",
                description = "Minimum Gift of the Ox orbs to use Expel Harm",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            }
        },
        
        offensiveSettings = {
            useInvokeNiuzao = {
                displayName = "Use Invoke Niuzao",
                description = "Automatically use Invoke Niuzao when talented",
                type = "toggle",
                default = true
            },
            useBlackOxBrew = {
                displayName = "Use Black Ox Brew",
                description = "Automatically use Black Ox Brew when talented",
                type = "toggle",
                default = true
            },
            blackOxBrewChargesThreshold = {
                displayName = "Black Ox Brew Charges",
                description = "Maximum brew charges to use Black Ox Brew",
                type = "slider",
                min = 0,
                max = 3,
                default = 0
            },
            useExplodingKeg = {
                displayName = "Use Exploding Keg",
                description = "Automatically use Exploding Keg when talented",
                type = "toggle",
                default = true
            },
            explodingKegThreshold = {
                displayName = "Exploding Keg Target Count",
                description = "Minimum targets to use Exploding Keg",
                type = "slider",
                min = 1,
                max = 6,
                default = 3
            },
            useTouchOfDeath = {
                displayName = "Use Touch of Death",
                description = "Automatically use Touch of Death when talented",
                type = "toggle",
                default = true
            },
            useTouchOfKarma = {
                displayName = "Use Touch of Karma",
                description = "Automatically use Touch of Karma when talented",
                type = "toggle",
                default = true
            },
            touchOfKarmaThreshold = {
                displayName = "Touch of Karma Health Threshold",
                description = "Health percentage to use Touch of Karma",
                type = "slider",
                min = 30,
                max = 80,
                default = 60
            }
        },
        
        covenantSettings = {
            useWeaponsOfOrder = {
                displayName = "Use Weapons of Order",
                description = "Automatically use Weapons of Order",
                type = "toggle",
                default = true
            },
            useFallenOrder = {
                displayName = "Use Fallen Order",
                description = "Automatically use Fallen Order",
                type = "toggle",
                default = true
            },
            useBoneDustBrew = {
                displayName = "Use Bonedust Brew",
                description = "Automatically use Bonedust Brew",
                type = "toggle",
                default = true
            },
            boneDustBrewTargetCount = {
                displayName = "Bonedust Brew Target Count",
                description = "Minimum targets to use Bonedust Brew",
                type = "slider",
                min = 1,
                max = 6,
                default = 2
            },
            useFaelineStomp = {
                displayName = "Use Faeline Stomp",
                description = "Automatically use Faeline Stomp",
                type = "toggle",
                default = true
            }
        },
        
        utilitySettings = {
            useDetox = {
                displayName = "Use Detox",
                description = "Automatically use Detox to remove debuffs",
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
                description = "Minimum targets to use Leg Sweep",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useRingOfPeace = {
                displayName = "Use Ring of Peace",
                description = "Automatically use Ring of Peace when talented",
                type = "toggle",
                default = true
            },
            ringOfPeaceStrategy = {
                displayName = "Ring of Peace Strategy",
                description = "How to use Ring of Peace",
                type = "dropdown",
                options = {"Defensive", "Offensive", "Manual Only"},
                default = "Defensive"
            },
            useRoll = {
                displayName = "Use Roll",
                description = "Automatically use Roll for movement",
                type = "toggle",
                default = false
            },
            useVivify = {
                displayName = "Use Vivify",
                description = "Automatically use Vivify for emergency healing",
                type = "toggle",
                default = true
            },
            vivifyThreshold = {
                displayName = "Vivify Health Threshold",
                description = "Health percentage to use Vivify",
                type = "slider",
                min = 20,
                max = 60,
                default = 40
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Invoke Niuzao controls
            invokeNiuzao = AAC.RegisterAbility(spells.INVOKE_NIUZAO, {
                enabled = true,
                useDuringBurstOnly = true,
                minTargets = 1
            }),
            
            -- Fortifying Brew controls
            fortifyingBrew = AAC.RegisterAbility(spells.FORTIFYING_BREW, {
                enabled = true,
                useDuringEmergency = true,
                minHealthThreshold = 40
            }),
            
            -- Weapons of Order controls
            weaponsOfOrder = AAC.RegisterAbility(spells.WEAPONS_OF_ORDER, {
                enabled = true,
                useDuringBurstOnly = false,
                minTargets = 1
            })
        }
    })
    
    return true
end

-- Register for events 
function Brewmaster:RegisterEvents()
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
    
    -- Register for Chi updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "CHI" then
            self:UpdateChi()
        end
    end)
    
    -- Register for stagger updates
    API.RegisterEvent("UNIT_AURA", function(unit) 
        if unit == "player" then
            self:UpdateStagger()
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
function Brewmaster:UpdateTalentInfo()
    -- Check for important talents
    talents.hasBlackoutCombo = API.HasTalent(spells.BLACKOUT_COMBO)
    talents.hasLightBrewing = API.HasTalent(spells.LIGHT_BREWING)
    talents.hasBlackOxBrew = API.HasTalent(spells.BLACK_OX_BREW)
    talents.hasSummonBlackOxStatue = API.HasTalent(spells.SUMMON_BLACK_OX_STATUE)
    talents.hasInvokeNiuzao = API.HasTalent(spells.INVOKE_NIUZAO)
    talents.hasSpecialDelivery = API.HasTalent(spells.SPECIAL_DELIVERY)
    talents.hasHighTolerance = API.HasTalent(spells.HIGH_TOLERANCE)
    talents.hasCelestialFlames = API.HasTalent(spells.CELESTIAL_FLAMES)
    talents.hasPurifiedChi = API.HasTalent(spells.PURIFIED_CHI)
    talents.hasCelestialFortune = API.HasTalent(spells.CELESTIAL_FORTUNE)
    talents.hasCharredPassions = API.HasTalent(spells.CHARRED_PASSIONS)
    talents.hasPressTheAdvantage = API.HasTalent(spells.PRESS_THE_ADVANTAGE)
    talents.hasTouchOfDeath = API.HasTalent(spells.TOUCH_OF_DEATH)
    talents.hasTouchOfKarma = API.HasTalent(spells.TOUCH_OF_KARMA)
    talents.hasCallToArms = API.HasTalent(spells.CALL_TO_ARMS)
    talents.hasImprovedInvokeNiuzao = API.HasTalent(spells.IMPROVED_INVOKE_NIUZAO)
    talents.hasQuickSip = API.HasTalent(spells.QUICK_SIP)
    talents.hasGraceOfTheCrane = API.HasTalent(spells.GRACE_OF_THE_CRANE)
    talents.hasCallOfTheOx = API.HasTalent(spells.CALL_OF_THE_OX)
    talents.hasCelestialHarmony = API.HasTalent(spells.CELESTIAL_HARMONY)
    talents.hasElusiveFootwork = API.HasTalent(spells.ELUSIVE_FOOTWORK)
    talents.hasBobAndWeave = API.HasTalent(spells.BOB_AND_WEAVE)
    talents.hasAttenuation = API.HasTalent(spells.ATTENUATION)
    talents.hasImprovedCelestialBrew = API.HasTalent(spells.IMPROVED_CELESTIAL_BREW)
    talents.hasStrengthOfSpirit = API.HasTalent(spells.STRENGTH_OF_SPIRIT)
    talents.hasHitCombo = API.HasTalent(spells.HIT_COMBO)
    talents.hasMightyPour = API.HasTalent(spells.MIGHTY_POUR)
    talents.hasFundamentalObservation = API.HasTalent(spells.FUNDAMENTAL_OBSERVATION)
    talents.hasPretenseOfInstability = API.HasTalent(spells.PRETENSE_OF_INSTABILITY)
    talents.hasImprovedPurifyingBrew = API.HasTalent(spells.IMPROVED_PURIFYING_BREW)
    talents.hasFortifyingIngredients = API.HasTalent(spells.FORTIFYING_INGREDIENTS)
    talents.hasStaggeredHits = API.HasTalent(spells.STAGGERED_HITS)
    talents.hasNimbleBrew = API.HasTalent(spells.NIMBLE_BREW)
    talents.hasFacePalm = API.HasTalent(spells.FACE_PALM)
    talents.hasZenMeditation = API.HasTalent(spells.ZEN_MEDITATION_TALENT)
    talents.hasEscapeFromReality = API.HasTalent(spells.ESCAPE_FROM_REALITY)
    talents.hasGenerousPour = API.HasTalent(spells.GENEROUS_POUR)
    talents.hasSleepyShadow = API.HasTalent(spells.SLEEPY_SHADOW)
    talents.hasScaleSadness = API.HasTalent(spells.SCALE_SADNESS)
    talents.hasImprovedBreathOfFire = API.HasTalent(spells.IMPROVED_BREATH_OF_FIRE)
    talents.hasSalsalabimStrength = API.HasTalent(spells.SALSALABIMS_STRENGTH)
    talents.hasWalkWithTheOx = API.HasTalent(spells.WALK_WITH_THE_OX)
    talents.hasAdmonishment = API.HasTalent(spells.ADMONISHMENT)
    talents.hasRushingTigerPalm = API.HasTalent(spells.RUSHING_TIGER_PALM)
    talents.hasFlurryOfFists = API.HasTalent(spells.FLURRY_OF_FISTS)
    talents.hasFluidityOfMotion = API.HasTalent(spells.FLUIDITY_OF_MOTION)
    talents.hasFaelineStomp = API.HasTalent(spells.FAELINE_STOMP)
    talents.hasShadowboxingTreads = API.HasTalent(spells.SHADOWBOXING_TREADS)
    
    -- Set specialized variables based on talents
    if talents.hasLightBrewing then
        lightBrewingActive = true
    end
    
    if talents.hasTouchOfDeath then
        touchOfDeath = true
    }
    
    if talents.hasTouchOfKarma then
        touchOfKarma = true
    }
    
    if talents.hasCallOfTheOx then
        callOfTheOx = true
    }
    
    if talents.hasSleepyShadow then
        sleepingShadow = true
    }
    
    if talents.hasScaleSadness then
        scaleSadness = true
    }
    
    if talents.hasDetoxEnergy then
        detoxEnergy = true
    }
    
    -- Update brew charges
    celestialBrewCharges = API.GetSpellCharges(spells.CELESTIAL_BREW) or 0
    purifyingBrewCharges = API.GetSpellCharges(spells.PURIFYING_BREW) or 0
    
    API.PrintDebug("Brewmaster Monk talents updated")
    
    return true
end

-- Update energy tracking
function Brewmaster:UpdateEnergy()
    currentEnergy = API.GetPlayerPower()
    return true
end

-- Update chi tracking
function Brewmaster:UpdateChi()
    currentChi = API.GetPlayerComboPoints() or 0
    return true
end

-- Update stagger information
function Brewmaster:UpdateStagger()
    -- Check stagger buff types
    local hasLightStagger = API.PlayerHasBuff(buffs.LIGHT_STAGGER)
    local hasModerateStagger = API.PlayerHasBuff(buffs.MODERATE_STAGGER)
    local hasHeavyStagger = API.PlayerHasBuff(buffs.HEAVY_STAGGER)
    
    -- Determine stagger level
    if hasHeavyStagger then
        staggerLevel = "heavy"
        staggerPercentage = 100
    elseif hasModerateStagger then
        staggerLevel = "moderate"
        staggerPercentage = 60
    elseif hasLightStagger then
        staggerLevel = "light"
        staggerPercentage = 30
    else
        staggerLevel = "none"
        staggerPercentage = 0
    end
    
    -- Check for Shuffle buff
    local shuffleInfo = API.GetBuffInfo("player", buffs.SHUFFLE)
    if shuffleInfo then
        shuffleActive = true
        shuffleEndTime = select(6, shuffleInfo)
    else
        shuffleActive = false
        shuffleEndTime = 0
    end
    
    -- Check for Fortifying Ingredients
    if talents.hasFortifyingIngredients then
        local fiInfo = API.GetBuffInfo("player", buffs.FORTIFYING_INGREDIENTS)
        if fiInfo then
            fortifyingIngredientsActive = true
            fortifyingIngredientsStacks = select(4, fiInfo) or 0
        else
            fortifyingIngredientsActive = false
            fortifyingIngredientsStacks = 0
        end
    end
    
    -- Check for Dampen Harm
    if talents.hasDampenHarm then
        local dhInfo = API.GetBuffInfo("player", buffs.DAMPEN_HARM)
        if dhInfo then
            dampenHarmActive = true
            dampenHarmEndTime = select(6, dhInfo)
            dampenHarmStacks = select(4, dhInfo) or 0
        else
            dampenHarmActive = false
            dampenHarmEndTime = 0
            dampenHarmStacks = 0
        end
    end
    
    -- Check for Fortifying Brew
    local fbInfo = API.GetBuffInfo("player", buffs.FORTIFYING_BREW)
    if fbInfo then
        fortifyingBrewActive = true
        fortifyingBrewEndTime = select(6, fbInfo)
    else
        fortifyingBrewActive = false
        fortifyingBrewEndTime = 0
    end
    
    -- Check for Zen Meditation
    if talents.hasZenMeditation then
        local zmInfo = API.GetBuffInfo("player", buffs.ZEN_MEDITATION)
        if zmInfo then
            zenMeditationActive = true
        else
            zenMeditationActive = false
        end
    end
    
    -- Update Gifts of the Ox count
    if talents.hasGiftsOfTheOx then
        giftsOfTheOxCount = API.CountActiveOrbs() or 0
        giftsOfTheOxActive = giftsOfTheOxCount > 0
    end
    
    -- Update Hit Combo status
    if talents.hasHitCombo then
        local hcInfo = API.GetBuffInfo("player", buffs.HIT_COMBO)
        if hcInfo then
            hitComboActive = true
            hitComboStacks = select(4, hcInfo) or 0
            hitComboEndTime = select(6, hcInfo)
        else
            hitComboActive = false
            hitComboStacks = 0
            hitComboEndTime = 0
        end
    end
    
    -- Update Celestial Flames stacks
    if talents.hasCelestialFlames then
        local cfInfo = API.GetBuffInfo("player", buffs.CELESTIAL_FLAMES)
        if cfInfo then
            celestialFlamesStacks = select(4, cfInfo) or 0
        else
            celestialFlamesStacks = 0
        end
    end
    
    return true
end

-- Update target data
function Brewmaster:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    inMeleeDamageRange = inMeleeRange
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Keg Smash debuff
        local kegSmashInfo = API.GetDebuffInfo(targetGUID, debuffs.KEG_SMASH)
        local kegSmashActive = kegSmashInfo ~= nil
        
        -- Check for Breath of Fire debuff
        local breathOfFireInfo = API.GetDebuffInfo(targetGUID, debuffs.BREATH_OF_FIRE)
        local breathOfFireActive = breathOfFireInfo ~= nil
        
        -- Check for Exploding Keg debuff
        local explodingKegInfo = API.GetDebuffInfo(targetGUID, debuffs.EXPLODING_KEG)
        local explodingKegActive = explodingKegInfo ~= nil
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius (typically a bit bigger for tanks)
    
    return true
end

-- Handle combat log events
function Brewmaster:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Blackout Combo
            if spellID == buffs.BLACKOUT_COMBO then
                blackoutKickActive = true
                blackoutKickEndTime = GetTime() + BLACKOUT_COMBO_DURATION
                blackoutComboActive = true
                API.PrintDebug("Blackout Combo activated")
            end
            
            -- Track Rushing Jade Wind
            if spellID == buffs.RUSHING_JADE_WIND then
                rushingJadeWindActive = true
                rushingJadeWindEndTime = GetTime() + RUSHING_JADE_WIND_DURATION
                API.PrintDebug("Rushing Jade Wind activated")
            end
            
            -- Track Weapons of Order
            if spellID == buffs.WEAPONS_OF_ORDER then
                weaponsOfOrderActive = true
                weaponsOfOrderEndTime = GetTime() + WEAPONS_OF_ORDER_DURATION
                API.PrintDebug("Weapons of Order activated")
            end
            
            -- Track Fallen Order
            if spellID == buffs.FALLEN_ORDER then
                fallenOrderActive = true
                fallenOrderEndTime = GetTime() + FALLEN_ORDER_DURATION
                API.PrintDebug("Fallen Order activated")
            end
            
            -- Track Bonedust Brew
            if spellID == buffs.BONEDUST_BREW then
                boneDustBrewActive = true
                boneDustBrewEndTime = GetTime() + BONE_DUST_BREW_DURATION
                API.PrintDebug("Bonedust Brew activated")
            end
            
            -- Track Shuffle
            if spellID == buffs.SHUFFLE then
                shuffleActive = true
                shuffleEndTime = GetTime() + SHUFFLE_DURATION
                API.PrintDebug("Shuffle activated")
            end
            
            -- Track Charred Passions
            if spellID == buffs.CHARRED_PASSIONS then
                charredPassionsActive = true
                charredPassionsStacks = select(4, API.GetBuffInfo("player", buffs.CHARRED_PASSIONS)) or 1
                API.PrintDebug("Charred Passions activated: " .. tostring(charredPassionsStacks) .. " stacks")
            end
            
            -- Track Invoke Niuzao
            if spellID == buffs.INVOKE_NIUZAO then
                invokeNiuzaoActivated = true
                invokeNiuzaoEndTime = GetTime() + INVOKE_NIUZAO_DURATION
                API.PrintDebug("Invoke Niuzao activated")
            end
            
            -- Track Faeline Stomp
            if spellID == buffs.FAELINE_STOMP then
                faelineResonance = true
                API.PrintDebug("Faeline Stomp resonance activated")
            end
            
            -- Track Fortifying Ingredients
            if spellID == buffs.FORTIFYING_INGREDIENTS then
                fortifyingIngredientsActive = true
                fortifyingIngredientsStacks = select(4, API.GetBuffInfo("player", buffs.FORTIFYING_INGREDIENTS)) or 1
                API.PrintDebug("Fortifying Ingredients activated: " .. tostring(fortifyingIngredientsStacks) .. " stacks")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Blackout Combo removal
            if spellID == buffs.BLACKOUT_COMBO then
                blackoutKickActive = false
                blackoutComboActive = false
                API.PrintDebug("Blackout Combo faded")
            end
            
            -- Track Rushing Jade Wind removal
            if spellID == buffs.RUSHING_JADE_WIND then
                rushingJadeWindActive = false
                API.PrintDebug("Rushing Jade Wind faded")
            end
            
            -- Track Weapons of Order removal
            if spellID == buffs.WEAPONS_OF_ORDER then
                weaponsOfOrderActive = false
                API.PrintDebug("Weapons of Order faded")
            end
            
            -- Track Fallen Order removal
            if spellID == buffs.FALLEN_ORDER then
                fallenOrderActive = false
                API.PrintDebug("Fallen Order faded")
            end
            
            -- Track Bonedust Brew removal
            if spellID == buffs.BONEDUST_BREW then
                boneDustBrewActive = false
                API.PrintDebug("Bonedust Brew faded")
            end
            
            -- Track Shuffle removal
            if spellID == buffs.SHUFFLE then
                shuffleActive = false
                API.PrintDebug("Shuffle faded")
            end
            
            -- Track Charred Passions removal
            if spellID == buffs.CHARRED_PASSIONS then
                charredPassionsActive = false
                charredPassionsStacks = 0
                API.PrintDebug("Charred Passions faded")
            end
            
            -- Track Invoke Niuzao removal
            if spellID == buffs.INVOKE_NIUZAO then
                invokeNiuzaoActivated = false
                API.PrintDebug("Invoke Niuzao faded")
            end
            
            -- Track Faeline Stomp removal
            if spellID == buffs.FAELINE_STOMP then
                faelineResonance = false
                API.PrintDebug("Faeline Stomp resonance faded")
            end
            
            -- Track Fortifying Ingredients removal
            if spellID == buffs.FORTIFYING_INGREDIENTS then
                fortifyingIngredientsActive = false
                fortifyingIngredientsStacks = 0
                API.PrintDebug("Fortifying Ingredients faded")
            end
        end
    end
    
    -- Track Charred Passions stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.CHARRED_PASSIONS and destGUID == API.GetPlayerGUID() then
        charredPassionsStacks = select(4, API.GetBuffInfo("player", buffs.CHARRED_PASSIONS)) or 0
        API.PrintDebug("Charred Passions stacks: " .. tostring(charredPassionsStacks))
    end
    
    -- Track Fortifying Ingredients stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FORTIFYING_INGREDIENTS and destGUID == API.GetPlayerGUID() then
        fortifyingIngredientsStacks = select(4, API.GetBuffInfo("player", buffs.FORTIFYING_INGREDIENTS)) or 0
        API.PrintDebug("Fortifying Ingredients stacks: " .. tostring(fortifyingIngredientsStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        -- Track Tiger Palm casts for potential Face Palm procs
        if spellID == spells.TIGER_PALM then
            tigerPalmCount = tigerPalmCount + 1
            API.PrintDebug("Tiger Palm cast, count: " .. tostring(tigerPalmCount))
        elseif spellID == spells.BLACKOUT_KICK then
            API.PrintDebug("Blackout Kick cast")
        elseif spellID == spells.KEG_SMASH then
            kegSmashCharges = API.GetSpellCharges(spells.KEG_SMASH) or 0
            API.PrintDebug("Keg Smash cast, charges: " .. tostring(kegSmashCharges))
        elseif spellID == spells.BREATH_OF_FIRE then
            breathOfFireOnCooldown = true
            breathOfFireEndTime = GetTime() + BREATH_OF_FIRE_COOLDOWN
            -- Reset breathOfFireOnCooldown after cooldown duration
            C_Timer.After(BREATH_OF_FIRE_COOLDOWN, function()
                breathOfFireOnCooldown = false
                API.PrintDebug("Breath of Fire cooldown reset")
            end)
            API.PrintDebug("Breath of Fire cast")
        elseif spellID == spells.EXPLODING_KEG then
            explodingKegOnCooldown = true
            explodingKegCooldownRemaining = EXPLODING_KEG_COOLDOWN
            
            -- Reset explodingKegOnCooldown after cooldown duration
            C_Timer.After(EXPLODING_KEG_COOLDOWN, function()
                explodingKegOnCooldown = false
                API.PrintDebug("Exploding Keg cooldown reset")
            end)
            
            API.PrintDebug("Exploding Keg cast")
        elseif spellID == spells.SPINNING_CRANE_KICK then
            spinningCraneKickActive = true
            
            -- Reset spinningCraneKickActive after duration
            C_Timer.After(1.5, function() -- approximate duration
                spinningCraneKickActive = false
                API.PrintDebug("Spinning Crane Kick finished")
            end)
            
            API.PrintDebug("Spinning Crane Kick cast")
        elseif spellID == spells.RUSHING_JADE_WIND then
            rushingJadeWindActive = true
            rushingJadeWindEndTime = GetTime() + RUSHING_JADE_WIND_DURATION
            API.PrintDebug("Rushing Jade Wind cast")
        elseif spellID == spells.PURIFYING_BREW then
            lastPurifyTime = GetTime()
            purifyingBrewCharges = API.GetSpellCharges(spells.PURIFYING_BREW) or 0
            lastBrewUsed = spells.PURIFYING_BREW
            lastBrewTime = GetTime()
            API.PrintDebug("Purifying Brew cast, charges remaining: " .. tostring(purifyingBrewCharges))
        elseif spellID == spells.CELESTIAL_BREW then
            celestialBrewCharges = API.GetSpellCharges(spells.CELESTIAL_BREW) or 0
            lastBrewUsed = spells.CELESTIAL_BREW
            lastBrewTime = GetTime()
            API.PrintDebug("Celestial Brew cast, charges remaining: " .. tostring(celestialBrewCharges))
        elseif spellID == spells.BLACK_OX_BREW then
            -- Reset brew cooldowns
            purifyingBrewCharges = API.GetSpellMaxCharges(spells.PURIFYING_BREW) or 3
            celestialBrewCharges = API.GetSpellMaxCharges(spells.CELESTIAL_BREW) or 1
            lastBrewUsed = spells.BLACK_OX_BREW
            lastBrewTime = GetTime()
            API.PrintDebug("Black Ox Brew cast, reset brew charges")
        elseif spellID == spells.INVOKE_NIUZAO then
            invokeNiuzaoActivated = true
            invokeNiuzaoEndTime = GetTime() + INVOKE_NIUZAO_DURATION
            API.PrintDebug("Invoke Niuzao cast")
        elseif spellID == spells.WEAPONS_OF_ORDER then
            weaponsOfOrderActive = true
            weaponsOfOrderEndTime = GetTime() + WEAPONS_OF_ORDER_DURATION
            API.PrintDebug("Weapons of Order cast")
        elseif spellID == spells.FALLEN_ORDER then
            fallenOrderActive = true
            fallenOrderEndTime = GetTime() + FALLEN_ORDER_DURATION
            API.PrintDebug("Fallen Order cast")
        elseif spellID == spells.BONEDUST_BREW then
            boneDustBrewActive = true
            boneDustBrewEndTime = GetTime() + BONE_DUST_BREW_DURATION
            API.PrintDebug("Bonedust Brew cast")
        elseif spellID == spells.FAELINE_STOMP then
            faelineStompOnCooldown = true
            faelineResonance = true
            
            -- Reset faelineStompOnCooldown after cooldown duration (30s)
            C_Timer.After(30, function()
                faelineStompOnCooldown = false
                API.PrintDebug("Faeline Stomp cooldown reset")
            end)
            
            API.PrintDebug("Faeline Stomp cast")
        end
    end
    
    return true
end

-- Main rotation function
function Brewmaster:RunRotation()
    -- Check if we should be running Brewmaster Monk logic
    if API.GetActiveSpecID() ~= BREWMASTER_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() or spinningCraneKickActive then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BrewmasterMonk")
    
    -- Update variables
    self:UpdateEnergy()
    self:UpdateChi()
    self:UpdateStagger()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle interrupts first (high priority)
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle purifying and defensive brews next (high priority)
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle GCD offensive abilities
    if self:HandleOffensives(settings) then
        return true
    end
    
    -- Check if in melee range for main rotation
    if not inMeleeRange then
        -- Skip rest of rotation if not in range
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
function Brewmaster:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.SPEAR_HAND_STRIKE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.SPEAR_HAND_STRIKE)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Brewmaster:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Handle Purifying Brew first to clear stagger
    if API.CanCast(spells.PURIFYING_BREW) and purifyingBrewCharges > 0 then
        local shouldPurify = false
        
        -- Check different strategies
        if settings.defensiveSettings.purifyingBrewStrategy == "Light Stagger" then
            shouldPurify = staggerLevel != "none"
        elseif settings.defensiveSettings.purifyingBrewStrategy == "Moderate Stagger" then
            shouldPurify = staggerLevel == "moderate" or staggerLevel == "heavy"
        elseif settings.defensiveSettings.purifyingBrewStrategy == "Heavy Stagger Only" then
            shouldPurify = staggerLevel == "heavy"
        else -- Smart Management
            -- Consider health percentage and stagger level
            if staggerLevel == "heavy" then
                shouldPurify = true
            elseif staggerLevel == "moderate" and playerHealth < 70 then
                shouldPurify = true
            elseif staggerLevel == "light" and playerHealth < 50 then
                shouldPurify = true
            end
            
            -- Check if we have stagger above threshold percentage
            if staggerPercentage >= settings.defensiveSettings.purifyingBrewThreshold then
                shouldPurify = true
            end
            
            -- Save at least one charge for emergencies if health is ok
            if purifyingBrewCharges == 1 and playerHealth > 60 and staggerLevel != "heavy" then
                shouldPurify = false
            end
        end
        
        if shouldPurify then
            API.CastSpell(spells.PURIFYING_BREW)
            return true
        end
    end
    
    -- Use Celestial Brew for mitigation
    if API.CanCast(spells.CELESTIAL_BREW) and celestialBrewCharges > 0 then
        local shouldUseCelestialBrew = false
        
        -- Check different strategies
        if settings.defensiveSettings.celestialBrewStrategy == "On Cooldown" then
            shouldUseCelestialBrew = true
        elseif settings.defensiveSettings.celestialBrewStrategy == "With Purifying Buff" then
            -- Check if we have enough Purified Chi stacks
            shouldUseCelestialBrew = talents.hasPurifiedChi and GetTime() - lastPurifyTime < 6 and 
                                    playerHealth <= settings.defensiveSettings.celestialBrewThreshold
        else -- Emergency Only
            shouldUseCelestialBrew = playerHealth <= settings.defensiveSettings.celestialBrewThreshold
        end
        
        if shouldUseCelestialBrew then
            API.CastSpell(spells.CELESTIAL_BREW)
            return true
        end
    end
    
    -- Use Fortifying Brew
    if settings.defensiveSettings.useFortifyingBrew and
       playerHealth <= settings.defensiveSettings.fortifyingBrewThreshold and
       not fortifyingBrewActive and
       API.CanCast(spells.FORTIFYING_BREW) then
        API.CastSpell(spells.FORTIFYING_BREW)
        return true
    end
    
    -- Use Dampen Harm
    if talents.hasDampenHarm and
       settings.defensiveSettings.useDampenHarm and
       playerHealth <= settings.defensiveSettings.dampenHarmThreshold and
       not dampenHarmActive and
       API.CanCast(spells.DAMPEN_HARM) then
        API.CastSpell(spells.DAMPEN_HARM)
        return true
    end
    
    -- Use Expel Harm
    if settings.defensiveSettings.useExpelHarm and
       playerHealth <= settings.defensiveSettings.expelHarmThreshold and
       giftsOfTheOxCount >= settings.defensiveSettings.expelHarmOrbCount and
       API.CanCast(spells.EXPEL_HARM) then
        API.CastSpell(spells.EXPEL_HARM)
        return true
    end
    
    -- Use Vivify for emergency healing
    if settings.utilitySettings.useVivify and
       playerHealth <= settings.utilitySettings.vivifyThreshold and
       currentEnergy >= 30 and -- Approximate energy cost
       API.CanCast(spells.VIVIFY) then
        API.CastSpellOnSelf(spells.VIVIFY)
        return true
    end
    
    -- Use Black Ox Brew to refresh brews
    if talents.hasBlackOxBrew and
       settings.offensiveSettings.useBlackOxBrew and
       purifyingBrewCharges <= settings.offensiveSettings.blackOxBrewChargesThreshold and
       celestialBrewCharges == 0 and
       API.CanCast(spells.BLACK_OX_BREW) then
        API.CastSpell(spells.BLACK_OX_BREW)
        return true
    end
    
    return false
end

-- Handle GCD offensive abilities
function Brewmaster:HandleOffensives(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive and not API.IsInCombat() then
        return false
    }

    -- Use Weapons of Order
    if settings.covenantSettings.useWeaponsOfOrder and
       settings.abilityControls.weaponsOfOrder.enabled and
       not weaponsOfOrderActive and
       API.CanCast(spells.WEAPONS_OF_ORDER) then
        
        -- Use if enough targets or in burst mode
        if currentAoETargets >= settings.abilityControls.weaponsOfOrder.minTargets or burstModeActive then
            API.CastSpell(spells.WEAPONS_OF_ORDER)
            return true
        end
    end
    
    -- Use Invoke Niuzao
    if talents.hasInvokeNiuzao and
       settings.offensiveSettings.useInvokeNiuzao and
       settings.abilityControls.invokeNiuzao.enabled and
       not invokeNiuzaoActivated and
       API.CanCast(spells.INVOKE_NIUZAO) then
        
        -- Use if enough targets or in burst mode
        if currentAoETargets >= settings.abilityControls.invokeNiuzao.minTargets or 
           (burstModeActive and settings.abilityControls.invokeNiuzao.useDuringBurstOnly) then
            API.CastSpell(spells.INVOKE_NIUZAO)
            return true
        end
    end
    
    -- Use Fallen Order
    if settings.covenantSettings.useFallenOrder and
       not fallenOrderActive and
       API.CanCast(spells.FALLEN_ORDER) then
        API.CastSpell(spells.FALLEN_ORDER)
        return true
    end
    
    -- Use Bonedust Brew
    if settings.covenantSettings.useBoneDustBrew and
       not boneDustBrewActive and
       API.CanCast(spells.BONEDUST_BREW) then
        
        -- Check if enough targets
        if currentAoETargets >= settings.covenantSettings.boneDustBrewTargetCount then
            API.CastSpellAtBestLocation(spells.BONEDUST_BREW, 8) -- 8 yard radius
            return true
        end
    end
    
    -- Use Exploding Keg
    if settings.offensiveSettings.useExplodingKeg and
       not explodingKegOnCooldown and
       currentAoETargets >= settings.offensiveSettings.explodingKegThreshold and
       API.CanCast(spells.EXPLODING_KEG) then
        API.CastSpellAtBestLocation(spells.EXPLODING_KEG, 8) -- 8 yard radius
        return true
    end
    
    -- Use Touch of Death
    if touchOfDeath and
       settings.offensiveSettings.useTouchOfDeath and
       API.CanCast(spells.TOUCH_OF_DEATH) then
        local canUseTouchOfDeath = API.CanUseTouchOfDeath("target")
        if canUseTouchOfDeath then
            API.CastSpell(spells.TOUCH_OF_DEATH)
            return true
        end
    end
    
    -- Use Touch of Karma
    if touchOfKarma and
       settings.offensiveSettings.useTouchOfKarma and
       API.GetPlayerHealthPercent() <= settings.offensiveSettings.touchOfKarmaThreshold and
       API.CanCast(spells.TOUCH_OF_KARMA) then
        API.CastSpell(spells.TOUCH_OF_KARMA)
        return true
    end
    
    -- Use Faeline Stomp
    if talents.hasFaelineStomp and
       settings.covenantSettings.useFaelineStomp and
       not faelineStompOnCooldown and
       API.CanCast(spells.FAELINE_STOMP) then
        API.CastSpellAtCursor(spells.FAELINE_STOMP)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Brewmaster:HandleAoERotation(settings)
    -- Use Keg Smash first if available (AoE threat generation and damage)
    if API.CanCast(spells.KEG_SMASH) and 
       (settings.rotationSettings.kegSmashPriority == "On Cooldown" || 
        (settings.rotationSettings.kegSmashPriority == "With Blackout Combo" && blackoutComboActive)) then
        API.CastSpell(spells.KEG_SMASH)
        return true
    end
    
    -- Use Rushing Jade Wind if talented and enabled
    if talents.hasRushingJadeWind and
       settings.rotationSettings.useRushingJadeWind and
       not rushingJadeWindActive and
       API.CanCast(spells.RUSHING_JADE_WIND) then
        API.CastSpell(spells.RUSHING_JADE_WIND)
        return true
    end
    
    -- Use Breath of Fire if available (AoE damage and mitigation)
    if API.CanCast(spells.BREATH_OF_FIRE) and
       (settings.rotationSettings.breathOfFirePriority == "On Cooldown" || 
        settings.rotationSettings.breathOfFirePriority == "After Keg Smash" ||
        (settings.rotationSettings.breathOfFirePriority == "With Blackout Combo" && blackoutComboActive)) then
        API.CastSpell(spells.BREATH_OF_FIRE)
        return true
    end
    
    -- Use Spinning Crane Kick for AoE damage and hit combo stacks
    if API.CanCast(spells.SPINNING_CRANE_KICK) and currentEnergy >= SPINNING_CRANE_KICK_COST then
        API.CastSpell(spells.SPINNING_CRANE_KICK)
        return true
    end
    
    -- Use Blackout Kick for shuffle extension if needed
    if API.CanCast(spells.BLACKOUT_KICK) and
       (settings.rotationSettings.useBlackoutKick == "High Priority" || 
        (settings.rotationSettings.useBlackoutKick == "For Shuffle Only" && shuffleEndTime - GetTime() < 3)) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Use Keg Smash as filler if available
    if API.CanCast(spells.KEG_SMASH) then
        API.CastSpell(spells.KEG_SMASH)
        return true
    end
    
    -- Use Tiger Palm if nothing else is available
    if API.CanCast(spells.TIGER_PALM) and currentEnergy >= TIGER_PALM_COST then
        API.CastSpell(spells.TIGER_PALM)
        return true
    }
    
    return false
end

-- Handle Single Target rotation
function Brewmaster:HandleSingleTargetRotation(settings)
    -- Use Keg Smash if available
    if API.CanCast(spells.KEG_SMASH) and
       (settings.rotationSettings.kegSmashPriority == "On Cooldown" || 
        settings.rotationSettings.kegSmashPriority == "When Available" ||
        (settings.rotationSettings.kegSmashPriority == "With Blackout Combo" && blackoutComboActive)) then
        API.CastSpell(spells.KEG_SMASH)
        return true
    end
    
    -- Use Blackout Kick for shuffle maintenance
    if API.CanCast(spells.BLACKOUT_KICK) and 
       (settings.rotationSettings.useBlackoutKick == "High Priority" || 
        (settings.rotationSettings.useBlackoutKick == "For Shuffle Only" && shuffleEndTime - GetTime() < 5)) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Use Breath of Fire
    if API.CanCast(spells.BREATH_OF_FIRE) and
       (settings.rotationSettings.breathOfFirePriority == "On Cooldown" || 
        settings.rotationSettings.breathOfFirePriority == "After Keg Smash" ||
        (settings.rotationSettings.breathOfFirePriority == "With Blackout Combo" && blackoutComboActive)) then
        API.CastSpell(spells.BREATH_OF_FIRE)
        return true
    end
    
    -- Use Rushing Jade Wind if talented
    if talents.hasRushingJadeWind and
       settings.rotationSettings.useRushingJadeWind and
       not rushingJadeWindActive and
       API.CanCast(spells.RUSHING_JADE_WIND) then
        API.CastSpell(spells.RUSHING_JADE_WIND)
        return true
    end
    
    -- Use Blackout Kick to maintain Hit Combo
    if talents.hasHitCombo and API.CanCast(spells.BLACKOUT_KICK) and 
       (hitComboEndTime - GetTime() < 2 || not hitComboActive) then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    end
    
    -- Use Tiger Palm as filler
    if API.CanCast(spells.TIGER_PALM) and currentEnergy >= TIGER_PALM_COST then
        API.CastSpell(spells.TIGER_PALM)
        return true
    }
    
    -- Use Blackout Kick as filler
    if API.CanCast(spells.BLACKOUT_KICK) and settings.rotationSettings.useBlackoutKick != "For Shuffle Only" then
        API.CastSpell(spells.BLACKOUT_KICK)
        return true
    }
    
    return false
end

-- Handle specialization change
function Brewmaster:OnSpecializationChanged()
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
    staggerLevel = "none"
    staggerPercentage = 0
    tigerPalmCount = 0
    blackoutKickActive = false
    blackoutKickEndTime = 0
    blackoutComboActive = false
    celestialBrewCharges = API.GetSpellCharges(spells.CELESTIAL_BREW) or 0
    celestialBrewMaxCharges = API.GetSpellMaxCharges(spells.CELESTIAL_BREW) or 1
    purifyingBrewCharges = API.GetSpellCharges(spells.PURIFYING_BREW) or 0
    purifyingBrewMaxCharges = API.GetSpellMaxCharges(spells.PURIFYING_BREW) or 2
    explodingKegOnCooldown = false
    explodingKegCooldownRemaining = 0
    spinningCraneKickActive = false
    weaponsOfOrderActive = false
    weaponsOfOrderEndTime = 0
    fallenOrderActive = false
    fallenOrderEndTime = 0
    boneDustBrewActive = false
    boneDustBrewEndTime = 0
    callToArmsActive = false
    charredPassionsActive = false
    charredPassionsStacks = 0
    invokeNiuzaoActivated = false
    invokeNiuzaoEndTime = 0
    faelineStompOnCooldown = false
    faelineResonance = false
    lastBrewUsed = 0
    lastBrewTime = 0
    lastPurifyTime = 0
    celestialFlamesStacks = 0
    kegSmashCharges = API.GetSpellCharges(spells.KEG_SMASH) or 0
    breathOfFireOnCooldown = false
    breathOfFireEndTime = 0
    charredPassionsCooldownRemaining = 0
    rushingJadeWindActive = false
    rushingJadeWindEndTime = 0
    shuffleActive = false
    shuffleEndTime = 0
    fortifyingIngredientsActive = false
    fortifyingIngredientsStacks = 0
    staggeredHits = 0
    zensphereActive = false
    detoxEnergy = false
    sleepingShadow = false
    scaleSadness = false
    touchOfDeath = false
    touchOfKarma = false
    callOfTheOx = false
    dampenHarmActive = false
    dampenHarmEndTime = 0
    dampenHarmStacks = 0
    dampenHarmMaxStacks = 0
    fortifyingBrewActive = false
    fortifyingBrewEndTime = 0
    lightBrewingActive = false
    giftsOfTheOxActive = false
    giftsOfTheOxCount = 0
    hitComboActive = false
    hitComboStacks = 0
    hitComboEndTime = 0
    zenMeditationActive = false
    inMeleeRange = false
    inMeleeDamageRange = false
    
    API.PrintDebug("Brewmaster Monk state reset on spec change")
    
    return true
end

-- Return the module for loading
return Brewmaster