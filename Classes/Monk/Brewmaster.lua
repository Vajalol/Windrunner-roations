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
local currentChi = 0
local maxChi = 5
local currentEnergy = 100
local maxEnergy = 100
local staggerPercentage = 0
local heavyStaggerThreshold = 60
local moderateStaggerThreshold = 30
local ironskinBrewActive = false
local ironskinBrewEndTime = 0
local ironskinBrewCharges = 0
local ironskinBrewMaxCharges = 0
local purifyingBrewActive = false
local purifyingBrewCharges = 0
local purifyingBrewMaxCharges = 0
local zensphereBrewActive = false
local zensphereBrewEndTime = 0
local celestialBrewActive = false
local celestialBrewEndTime = 0
local blackoutKickActive = false
local blackoutKickEndTime = 0
local kensingTea = false
local kensingTeaActive = false
local kensingTeaEndTime = 0
local invokeNiuzaoActive = false
local invokeNiuzaoEndTime = 0
local breathOfFireActive = false
local breathOfFireEndTime = 0
local blackoutComboActive = false
local blackoutComboEndTime = 0
local shuffleActive = false
local shuffleEndTime = 0
local fortifyingBrewActive = false
local fortifyingBrewEndTime = 0
local zenMeditation = false
local zenMeditationActive = false
local zenMeditationEndTime = 0
local boneDustBrew = false
local boneDustBrewActive = false
local boneDustBrewEndTime = 0
local weaponsOfOrder = false
local weaponsOfOrderActive = false
local weaponsOfOrderEndTime = 0
local charredPassions = false
local charredPassionsActive = false
local charredPassionsEndTime = 0
local charredPassionsStacks = 0
local blackoutCombo = false
local highTolerance = false
local highToleranceStacks = 0
local highToleranceActive = false
local celestialFlamesActive = false
local celestialFlamesEndTime = 0
local explodingKeg = false
local explodingKegActive = false
local explodingKegEndTime = 0
local rushingJadeWind = false
local rushingJadeWindActive = false
local rushingJadeWindEndTime = 0
local summonWhiteTigerStatue = false
local summonWhiteTigerStatueActive = false
local summonWhiteTigerStatueEndTime = 0
local dampenHarm = false
local dampenHarmActive = false
local dampenHarmEndTime = 0
local diffuseMagic = false
local diffuseMagicActive = false
local diffuseMagicEndTime = 0
local invokeNiuzao = false
local chiBurst = false
local chiWave = false
local smite = false
local smiteActive = false
local smiteEndTime = 0
local spinningCraneKick = false
local spinningCraneKickActive = false
local spinningCraneKickEndTime = 0
local tigerPalm = false
local blackoutKick = false
local risingSunKick = false
local keeperOfTheFlame = false
local keeperOfTheFlameActive = false
local keeperOfTheFlameStacks = 0
local breathOfFire = false
local kevEye = false
local kevEyeActive = false
local kevEyeEndTime = 0
local celestialBrew = false
local purifyingBrew = false
local expelHarm = false
local legSweep = false
local paralysis = false
local provoke = false
local spearHandStrike = false
local detox = false
local vivify = false
local transcendence = false
local transcendenceTransfer = false
local rollOut = false
local pressurePoint = false
local drinkingHornCover = false
local touchOfDeath = false
local specialDelivery = false
local specialDeliveryActive = false
local specialDeliveryEndTime = 0
local niuzaosMysteryActive = false
local niuzaosMysteryEndTime = 0
local lastKegSmash = 0
local lastTigerPalm = 0
local lastBreathOfFire = 0
local lastRushingJadeWind = 0
local lastSpinningCraneKick = 0
local lastRisingSunKick = 0
local lastBlackoutKick = 0
local lastCelestialBrew = 0
local lastPurifyingBrew = 0
local lastExpelHarm = 0
local lastZenMeditation = 0
local lastTouchOfDeath = 0
local lastBoneDustBrew = 0
local lastWeaponsOfOrder = 0
local lastExplodingKeg = 0
local lastChiBurst = 0
local lastChiWave = 0
local lastInvokeNiuzao = 0
local lastDampenHarm = 0
local lastDiffuseMagic = 0
local lastLegSweep = 0
local lastParalysis = 0
local lastDetox = 0
local lastVivify = 0
local lastTranscendence = 0
local lastTranscendenceTransfer = 0
local playerHealth = 100
local activeEnemies = 0
local isInMelee = false
local meleeRange = 5 -- yards

-- Constants
local BREWMASTER_SPEC_ID = 268
local FORT_BREW_DURATION = 15.0 -- seconds
local SHUFFLE_BASE_DURATION = 15.0 -- seconds
local ZEN_MEDITATION_DURATION = 8.0 -- seconds
local INVOKE_NIUZAO_DURATION = 25.0 -- seconds
local KEV_EYE_DURATION = 6.0 -- seconds (from Purifying Brew)
local CELESTIAL_BREW_DURATION = 8.0 -- seconds
local DAMPEN_HARM_DURATION = 10.0 -- seconds
local DIFFUSE_MAGIC_DURATION = 6.0 -- seconds
local BREATH_OF_FIRE_DURATION = 12.0 -- seconds
local CHARRED_PASSIONS_DURATION = 6.0 -- seconds
local BLACKOUT_COMBO_DURATION = 15.0 -- seconds
local EXPLODING_KEG_DURATION = 3.0 -- seconds
local WEAPONS_OF_ORDER_DURATION = 30.0 -- seconds
local BONE_DUST_BREW_DURATION = 10.0 -- seconds
local RUSHING_JADE_WIND_DURATION = 6.0 -- seconds
local WHITE_TIGER_STATUE_DURATION = 30.0 -- seconds
local SPECIAL_DELIVERY_DURATION = 5.0 -- seconds
local NIUZAOS_MYSTERY_DURATION = 10.0 -- seconds (placeholder)

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
    -- Core abilities
    spells.KEG_SMASH = 121253
    spells.TIGER_PALM = 100780
    spells.BLACKOUT_KICK = 205523
    spells.BREATH_OF_FIRE = 115181
    spells.PURIFYING_BREW = 119582
    spells.CELESTIAL_BREW = 322507
    spells.IRONSKIN_BREW = 115308 -- Legacy, now merged with Purifying Brew
    spells.EXPEL_HARM = 322101
    spells.RUSHING_JADE_WIND = 116847
    spells.SPINNING_CRANE_KICK = 101546
    spells.RISING_SUN_KICK = 107428
    
    -- Major defensives and cooldowns
    spells.FORTIFYING_BREW = 115203
    spells.ZEN_MEDITATION = 115176
    spells.DAMPEN_HARM = 122278
    spells.DIFFUSE_MAGIC = 122783
    spells.TOUCH_OF_DEATH = 115080
    spells.INVOKE_NIUZAO = 132578
    
    -- Covenant/Soul Bind abilities (now talents in Dragonflight)
    spells.WEAPONS_OF_ORDER = 387184
    spells.BONE_DUST_BREW = 386276
    
    -- Utility abilities
    spells.SPEAR_HAND_STRIKE = 116705
    spells.PROVOKE = 115546
    spells.LEG_SWEEP = 119381
    spells.PARALYSIS = 115078
    spells.DETOX = 218164
    spells.VIVIFY = 116670
    spells.TRANSCENDENCE = 101643
    spells.TRANSCENDENCE_TRANSFER = 119996
    spells.ROLL = 109132
    spells.CHI_TORPEDO = 115008
    spells.EXPLODING_KEG = 325153
    spells.SUMMON_WHITE_TIGER_STATUE = 388686
    
    -- Talents and passives
    spells.SHUFFLE = 215479
    spells.CELESTIAL_FLAMES = 387571
    spells.BLACKOUT_COMBO = 196736
    spells.HIGH_TOLERANCE = 196737
    spells.SPECIAL_DELIVERY = 196730
    spells.KENSING_TEA = 387440
    spells.SMITE = 387700
    spells.KEV_EYE = 395414
    spells.CHI_BURST = 123986
    spells.CHI_WAVE = 115098
    spells.ROLL_OUT = 328732
    spells.PRESSURE_POINT = 337482
    spells.DRINKING_HORN_COVER = 391370
    spells.KEEPER_OF_THE_FLAME = 387041
    spells.CHARRED_PASSIONS = 386963
    spells.NIUZAOS_MYSTERY = 388814
    
    -- War Within Season 2 specific
    spells.ZENSPHERE_BREW = 388854
    
    -- Buff IDs
    spells.SHUFFLE_BUFF = 215479
    spells.IRONSKIN_BREW_BUFF = 215479 -- Now Shuffle in Dragonflight
    spells.CELESTIAL_BREW_BUFF = 322507
    spells.ZENSPHERE_BREW_BUFF = 388854
    spells.FORTIFYING_BREW_BUFF = 115203
    spells.ZEN_MEDITATION_BUFF = 115176
    spells.BLACKOUT_COMBO_BUFF = 228563
    spells.KENSING_TEA_BUFF = 387440
    spells.CHARRED_PASSIONS_BUFF = 386963
    spells.RUSHING_JADE_WIND_BUFF = 116847
    spells.WEAPONS_OF_ORDER_BUFF = 387184
    spells.EXPLODING_KEG_BUFF = 325153
    spells.CELESTIAL_FLAMES_BUFF = 387571
    spells.DAMPEN_HARM_BUFF = 122278
    spells.DIFFUSE_MAGIC_BUFF = 122783
    spells.BONE_DUST_BREW_BUFF = 386276
    spells.INVOKE_NIUZAO_BUFF = 132578
    spells.KEV_EYE_BUFF = 395414
    spells.HIGH_TOLERANCE_BUFF = 196737
    spells.KEEPER_OF_THE_FLAME_BUFF = 387041
    spells.SPECIAL_DELIVERY_BUFF = 196730
    spells.NIUZAOS_MYSTERY_BUFF = 388814
    
    -- Debuff IDs
    spells.BREATH_OF_FIRE_DOT = 123725
    spells.KEG_SMASH_DEBUFF = 121253
    spells.MYSTIC_TOUCH_DEBUFF = 113746
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SHUFFLE = spells.SHUFFLE_BUFF
    buffs.FORTIFYING_BREW = spells.FORTIFYING_BREW_BUFF
    buffs.ZEN_MEDITATION = spells.ZEN_MEDITATION_BUFF
    buffs.CELESTIAL_BREW = spells.CELESTIAL_BREW_BUFF
    buffs.ZENSPHERE_BREW = spells.ZENSPHERE_BREW_BUFF
    buffs.BLACKOUT_COMBO = spells.BLACKOUT_COMBO_BUFF
    buffs.KENSING_TEA = spells.KENSING_TEA_BUFF
    buffs.CHARRED_PASSIONS = spells.CHARRED_PASSIONS_BUFF
    buffs.RUSHING_JADE_WIND = spells.RUSHING_JADE_WIND_BUFF
    buffs.WEAPONS_OF_ORDER = spells.WEAPONS_OF_ORDER_BUFF
    buffs.EXPLODING_KEG = spells.EXPLODING_KEG_BUFF
    buffs.CELESTIAL_FLAMES = spells.CELESTIAL_FLAMES_BUFF
    buffs.DAMPEN_HARM = spells.DAMPEN_HARM_BUFF
    buffs.DIFFUSE_MAGIC = spells.DIFFUSE_MAGIC_BUFF
    buffs.BONE_DUST_BREW = spells.BONE_DUST_BREW_BUFF
    buffs.INVOKE_NIUZAO = spells.INVOKE_NIUZAO_BUFF
    buffs.KEV_EYE = spells.KEV_EYE_BUFF
    buffs.HIGH_TOLERANCE = spells.HIGH_TOLERANCE_BUFF
    buffs.KEEPER_OF_THE_FLAME = spells.KEEPER_OF_THE_FLAME_BUFF
    buffs.SPECIAL_DELIVERY = spells.SPECIAL_DELIVERY_BUFF
    buffs.NIUZAOS_MYSTERY = spells.NIUZAOS_MYSTERY_BUFF
    
    debuffs.BREATH_OF_FIRE = spells.BREATH_OF_FIRE_DOT
    debuffs.KEG_SMASH = spells.KEG_SMASH_DEBUFF
    debuffs.MYSTIC_TOUCH = spells.MYSTIC_TOUCH_DEBUFF
    
    return true
end

-- Register variables to track
function Brewmaster:RegisterVariables()
    -- Talent tracking
    talents.hasBlackoutCombo = false
    talents.hasHighTolerance = false
    talents.hasZenMeditation = false
    talents.hasSpecialDelivery = false
    talents.hasExplodingKeg = false
    talents.hasInvokeNiuzao = false
    talents.hasKensingTea = false
    talents.hasSmite = false
    talents.hasKevEye = false
    talents.hasRushingJadeWind = false
    talents.hasChiBurst = false
    talents.hasChiWave = false
    talents.hasDampenHarm = false
    talents.hasDiffuseMagic = false
    talents.hasSummonWhiteTigerStatue = false
    talents.hasRollOut = false
    talents.hasPressurePoint = false
    talents.hasDrinkingHornCover = false
    talents.hasCharredPassions = false
    talents.hasKeeperOfTheFlame = false
    talents.hasWeaponsOfOrder = false
    talents.hasBoneDustBrew = false
    talents.hasNiuzaosMystery = false
    
    -- Initialize resources
    currentChi = API.GetPlayerPower() or 0
    maxChi = 5 -- Default, could be higher with talents
    currentEnergy = API.GetPlayerEnergy() or 100
    maxEnergy = API.GetPlayerMaxEnergy() or 100
    
    -- Initialize brew charges
    purifyingBrewCharges, purifyingBrewMaxCharges = API.GetSpellCharges(spells.PURIFYING_BREW) or 0, 3
    
    return true
end

-- Register spec-specific settings
function Brewmaster:RegisterSettings()
    ConfigRegistry:RegisterSettings("BrewmasterMonk", {
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
            maintainShuffle = {
                displayName = "Maintain Shuffle",
                description = "Always keep Shuffle active",
                type = "toggle",
                default = true
            },
            shuffleThreshold = {
                displayName = "Shuffle Threshold",
                description = "Minimum time remaining on Shuffle to refresh (seconds)",
                type = "slider",
                min = 1,
                max = 8,
                default = 4
            },
            kegSmashPriority = {
                displayName = "Keg Smash Priority",
                description = "Prioritize using Keg Smash when available",
                type = "toggle",
                default = true
            },
            breathOfFireMode = {
                displayName = "Breath of Fire Usage",
                description = "When to use Breath of Fire",
                type = "dropdown",
                options = {"On Cooldown", "Only with Keg Smash Debuff", "With Keeper of Flame Stacks", "Manual Only"},
                default = "Only with Keg Smash Debuff"
            },
            blackoutKickWithCombo = {
                displayName = "Blackout Kick with Combo",
                description = "Prioritize Blackout Kick when Blackout Combo is active",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            purifyingBrewEnabled = {
                displayName = "Use Purifying Brew",
                description = "Automatically use Purifying Brew",
                type = "toggle",
                default = true
            },
            purifyingBrewMode = {
                displayName = "Purifying Brew Usage",
                description = "When to use Purifying Brew",
                type = "dropdown",
                options = {"Moderate/Heavy Stagger", "Heavy Stagger Only", "Based on Health", "Manual Only"},
                default = "Moderate/Heavy Stagger"
            },
            purifyingBrewHealthThreshold = {
                displayName = "Purifying Brew Health Threshold",
                description = "Health percentage to trigger Purifying Brew in Health mode",
                type = "slider",
                min = 10,
                max = 70,
                default = 50
            },
            celestialBrewEnabled = {
                displayName = "Use Celestial Brew",
                description = "Automatically use Celestial Brew",
                type = "toggle",
                default = true
            },
            celestialBrewMode = {
                displayName = "Celestial Brew Usage",
                description = "When to use Celestial Brew",
                type = "dropdown",
                options = {"On Cooldown", "Based on Health", "After Purifying Brew", "Manual Only"},
                default = "Based on Health"
            },
            celestialBrewHealthThreshold = {
                displayName = "Celestial Brew Health Threshold",
                description = "Health percentage to use Celestial Brew",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            fortifyingBrewEnabled = {
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
            expelHarmEnabled = {
                displayName = "Use Expel Harm",
                description = "Automatically use Expel Harm",
                type = "toggle",
                default = true
            },
            expelHarmThreshold = {
                displayName = "Expel Harm Health Threshold",
                description = "Health percentage to use Expel Harm",
                type = "slider",
                min = 20,
                max = 90,
                default = 70
            },
            zenMeditationEnabled = {
                displayName = "Use Zen Meditation",
                description = "Automatically use Zen Meditation",
                type = "toggle",
                default = true
            },
            zenMeditationThreshold = {
                displayName = "Zen Meditation Health Threshold",
                description = "Health percentage to use Zen Meditation",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            dampenHarmEnabled = {
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
                default = 40
            },
            diffuseMagicEnabled = {
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
            }
        },
        
        cooldownSettings = {
            invokeNiuzaoEnabled = {
                displayName = "Use Invoke Niuzao",
                description = "Automatically use Invoke Niuzao when talented",
                type = "toggle",
                default = true
            },
            invokeNiuzaoMode = {
                displayName = "Invoke Niuzao Usage",
                description = "When to use Invoke Niuzao",
                type = "dropdown",
                options = {"On Cooldown", "With Other Cooldowns", "Boss Only", "Manual Only"},
                default = "With Other Cooldowns"
            },
            touchOfDeathEnabled = {
                displayName = "Use Touch of Death",
                description = "Automatically use Touch of Death",
                type = "toggle",
                default = true
            },
            boneDustBrewEnabled = {
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
            weaponsOfOrderEnabled = {
                displayName = "Use Weapons of Order",
                description = "Automatically use Weapons of Order when talented",
                type = "toggle",
                default = true
            },
            weaponsOfOrderMode = {
                displayName = "Weapons of Order Usage",
                description = "When to use Weapons of Order",
                type = "dropdown",
                options = {"On Cooldown", "With Other Cooldowns", "Boss Only", "Manual Only"},
                default = "With Other Cooldowns"
            },
            explodingKegEnabled = {
                displayName = "Use Exploding Keg",
                description = "Automatically use Exploding Keg when talented",
                type = "toggle",
                default = true
            },
            explodingKegMode = {
                displayName = "Exploding Keg Usage",
                description = "When to use Exploding Keg",
                type = "dropdown",
                options = {"On Cooldown", "AoE Only", "With Cooldowns", "Manual Only"},
                default = "AoE Only"
            },
            kensingTeaEnabled = {
                displayName = "Use Kensing Tea",
                description = "Automatically use Kensing Tea when talented",
                type = "toggle",
                default = true
            },
            rushingJadeWindEnabled = {
                displayName = "Use Rushing Jade Wind",
                description = "Automatically use Rushing Jade Wind when talented",
                type = "toggle",
                default = true
            },
            rushingJadeWindAoEThreshold = {
                displayName = "Rushing Jade Wind Target Threshold",
                description = "Minimum number of targets to use Rushing Jade Wind",
                type = "slider",
                min = 1,
                max = 6,
                default = 2
            }
        },
        
        interruptSettings = {
            useSpearHandStrike = {
                displayName = "Use Spear Hand Strike",
                description = "Automatically interrupt spellcasting",
                type = "toggle",
                default = true
            },
            useLegSweep = {
                displayName = "Use Leg Sweep",
                description = "Use Leg Sweep for AoE stun",
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
            useParalysis = {
                displayName = "Use Paralysis",
                description = "Use Paralysis for crowd control",
                type = "toggle",
                default = true
            }
        },
        
        utilitySettings = {
            useDetox = {
                displayName = "Use Detox",
                description = "Automatically Detox harmful effects",
                type = "toggle",
                default = true
            },
            useVivify = {
                displayName = "Use Vivify",
                description = "Use Vivify for emergency healing",
                type = "toggle",
                default = true
            },
            vivifyThreshold = {
                displayName = "Vivify Health Threshold",
                description = "Health percentage to use Vivify",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
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
            },
            summonWhiteTigerStatueEnabled = {
                displayName = "Use White Tiger Statue",
                description = "Automatically use White Tiger Statue when talented",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Keg Smash controls
            kegSmash = AAC.RegisterAbility(spells.KEG_SMASH, {
                enabled = true,
                useDuringBurstOnly = false,
                prioritizeWithBlackoutCombo = true,
                saveChargeForAdd = false
            }),
            
            -- Breath of Fire controls
            breathOfFire = AAC.RegisterAbility(spells.BREATH_OF_FIRE, {
                enabled = true,
                useDuringBurstOnly = false,
                requireKegSmashDebuff = true,
                minimumKeeperStacks = 0
            }),
            
            -- Purifying Brew controls
            purifyingBrew = AAC.RegisterAbility(spells.PURIFYING_BREW, {
                enabled = true,
                useDuringBurstOnly = false,
                heavyStaggerOnly = false,
                minHealthPercent = 0,
                saveCharges = 1
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
        end
    end)
    
    -- Register for stagger updates
    API.RegisterEvent("UNIT_AURA", function(unit) 
        if unit == "player" then
            self:UpdateStagger()
        end
    end)
    
    -- Register for Purifying Brew charge updates
    API.RegisterEvent("SPELL_UPDATE_CHARGES", function(spellID) 
        if spellID == spells.PURIFYING_BREW then
            self:UpdateBrewCharges()
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial brew charges update
    self:UpdateBrewCharges()
    
    -- Initial stagger update
    self:UpdateStagger()
    
    return true
end

-- Update talent information
function Brewmaster:UpdateTalentInfo()
    -- Check for important talents
    talents.hasBlackoutCombo = API.HasTalent(spells.BLACKOUT_COMBO)
    talents.hasHighTolerance = API.HasTalent(spells.HIGH_TOLERANCE)
    talents.hasZenMeditation = API.HasTalent(spells.ZEN_MEDITATION)
    talents.hasSpecialDelivery = API.HasTalent(spells.SPECIAL_DELIVERY)
    talents.hasExplodingKeg = API.HasTalent(spells.EXPLODING_KEG)
    talents.hasInvokeNiuzao = API.HasTalent(spells.INVOKE_NIUZAO)
    talents.hasKensingTea = API.HasTalent(spells.KENSING_TEA)
    talents.hasSmite = API.HasTalent(spells.SMITE)
    talents.hasKevEye = API.HasTalent(spells.KEV_EYE)
    talents.hasRushingJadeWind = API.HasTalent(spells.RUSHING_JADE_WIND)
    talents.hasChiBurst = API.HasTalent(spells.CHI_BURST)
    talents.hasChiWave = API.HasTalent(spells.CHI_WAVE)
    talents.hasDampenHarm = API.HasTalent(spells.DAMPEN_HARM)
    talents.hasDiffuseMagic = API.HasTalent(spells.DIFFUSE_MAGIC)
    talents.hasSummonWhiteTigerStatue = API.HasTalent(spells.SUMMON_WHITE_TIGER_STATUE)
    talents.hasRollOut = API.HasTalent(spells.ROLL_OUT)
    talents.hasPressurePoint = API.HasTalent(spells.PRESSURE_POINT)
    talents.hasDrinkingHornCover = API.HasTalent(spells.DRINKING_HORN_COVER)
    talents.hasCharredPassions = API.HasTalent(spells.CHARRED_PASSIONS)
    talents.hasKeeperOfTheFlame = API.HasTalent(spells.KEEPER_OF_THE_FLAME)
    talents.hasWeaponsOfOrder = API.HasTalent(spells.WEAPONS_OF_ORDER)
    talents.hasBoneDustBrew = API.HasTalent(spells.BONE_DUST_BREW)
    talents.hasNiuzaosMystery = API.HasTalent(spells.NIUZAOS_MYSTERY)
    
    -- Set specialized variables based on talents
    if talents.hasBlackoutCombo then
        blackoutCombo = true
    end
    
    if talents.hasHighTolerance then
        highTolerance = true
    end
    
    if talents.hasZenMeditation then
        zenMeditation = true
    end
    
    if talents.hasSpecialDelivery then
        specialDelivery = true
    end
    
    if talents.hasExplodingKeg then
        explodingKeg = true
    end
    
    if talents.hasInvokeNiuzao then
        invokeNiuzao = true
    end
    
    if talents.hasKensingTea then
        kensingTea = true
    end
    
    if talents.hasSmite then
        smite = true
    end
    
    if talents.hasKevEye then
        kevEye = true
    end
    
    if talents.hasRushingJadeWind then
        rushingJadeWind = true
    end
    
    if talents.hasChiBurst then
        chiBurst = true
    end
    
    if talents.hasChiWave then
        chiWave = true
    end
    
    if talents.hasDampenHarm then
        dampenHarm = true
    end
    
    if talents.hasDiffuseMagic then
        diffuseMagic = true
    end
    
    if talents.hasSummonWhiteTigerStatue then
        summonWhiteTigerStatue = true
    end
    
    if talents.hasRollOut then
        rollOut = true
    end
    
    if talents.hasPressurePoint then
        pressurePoint = true
    end
    
    if talents.hasDrinkingHornCover then
        drinkingHornCover = true
    end
    
    if talents.hasCharredPassions then
        charredPassions = true
    end
    
    if talents.hasKeeperOfTheFlame then
        keeperOfTheFlame = true
    end
    
    if talents.hasWeaponsOfOrder then
        weaponsOfOrder = true
    end
    
    if talents.hasBoneDustBrew then
        boneDustBrew = true
    end
    
    if API.IsSpellKnown(spells.KEG_SMASH) then
        kegSmash = true
    end
    
    if API.IsSpellKnown(spells.TIGER_PALM) then
        tigerPalm = true
    end
    
    if API.IsSpellKnown(spells.BLACKOUT_KICK) then
        blackoutKick = true
    end
    
    if API.IsSpellKnown(spells.BREATH_OF_FIRE) then
        breathOfFire = true
    end
    
    if API.IsSpellKnown(spells.CELESTIAL_BREW) then
        celestialBrew = true
    end
    
    if API.IsSpellKnown(spells.PURIFYING_BREW) then
        purifyingBrew = true
    end
    
    if API.IsSpellKnown(spells.EXPEL_HARM) then
        expelHarm = true
    end
    
    if API.IsSpellKnown(spells.SPINNING_CRANE_KICK) then
        spinningCraneKick = true
    end
    
    if API.IsSpellKnown(spells.RISING_SUN_KICK) then
        risingSunKick = true
    end
    
    if API.IsSpellKnown(spells.TOUCH_OF_DEATH) then
        touchOfDeath = true
    end
    
    if API.IsSpellKnown(spells.PROVOKE) then
        provoke = true
    end
    
    if API.IsSpellKnown(spells.SPEAR_HAND_STRIKE) then
        spearHandStrike = true
    end
    
    if API.IsSpellKnown(spells.LEG_SWEEP) then
        legSweep = true
    end
    
    if API.IsSpellKnown(spells.PARALYSIS) then
        paralysis = true
    end
    
    if API.IsSpellKnown(spells.DETOX) then
        detox = true
    end
    
    if API.IsSpellKnown(spells.VIVIFY) then
        vivify = true
    end
    
    if API.IsSpellKnown(spells.TRANSCENDENCE) then
        transcendence = true
    end
    
    if API.IsSpellKnown(spells.TRANSCENDENCE_TRANSFER) then
        transcendenceTransfer = true
    end
    
    API.PrintDebug("Brewmaster Monk talents updated")
    
    return true
end

-- Update chi tracking
function Brewmaster:UpdateChi()
    currentChi = API.GetPlayerPower()
    return true
end

-- Update energy tracking
function Brewmaster:UpdateEnergy()
    currentEnergy = API.GetPlayerEnergy()
    maxEnergy = API.GetPlayerMaxEnergy()
    return true
end

-- Update health tracking
function Brewmaster:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update stagger tracking
function Brewmaster:UpdateStagger()
    staggerPercentage = API.GetStaggerPercent() or 0
    
    -- Check if we have Shuffle (formerly Ironskin Brew)
    shuffleActive = API.UnitHasBuff("player", buffs.SHUFFLE)
    if shuffleActive then
        shuffleEndTime = select(6, API.GetBuffInfo("player", buffs.SHUFFLE))
    end
    
    -- Check for Celestial Brew
    celestialBrewActive = API.UnitHasBuff("player", buffs.CELESTIAL_BREW)
    if celestialBrewActive then
        celestialBrewEndTime = select(6, API.GetBuffInfo("player", buffs.CELESTIAL_BREW))
    end
    
    -- Check if we have Fortifying Brew
    fortifyingBrewActive = API.UnitHasBuff("player", buffs.FORTIFYING_BREW)
    if fortifyingBrewActive then
        fortifyingBrewEndTime = select(6, API.GetBuffInfo("player", buffs.FORTIFYING_BREW))
    end
    
    -- Zen Meditation
    zenMeditationActive = API.UnitHasBuff("player", buffs.ZEN_MEDITATION)
    if zenMeditationActive then
        zenMeditationEndTime = select(6, API.GetBuffInfo("player", buffs.ZEN_MEDITATION))
    end
    
    -- Check for High Tolerance stacks
    if highTolerance then
        highToleranceActive = true
        if staggerPercentage >= moderateStaggerThreshold then
            highToleranceStacks = 1
            if staggerPercentage >= heavyStaggerThreshold then
                highToleranceStacks = 2
            end
        else
            highToleranceStacks = 0
            highToleranceActive = false
        end
    end
    
    -- Other buffs
    blackoutComboActive = API.UnitHasBuff("player", buffs.BLACKOUT_COMBO)
    if blackoutComboActive then
        blackoutComboEndTime = select(6, API.GetBuffInfo("player", buffs.BLACKOUT_COMBO))
    end
    
    return true
end

-- Update brew charges
function Brewmaster:UpdateBrewCharges()
    purifyingBrewCharges, purifyingBrewMaxCharges = API.GetSpellCharges(spells.PURIFYING_BREW)
    return true
end

-- Update active enemy counts
function Brewmaster:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Check if unit is in melee range
function Brewmaster:IsInMeleeRange(unit)
    if not unit or not API.UnitExists(unit) then
        return false
    end
    
    return API.GetUnitDistance("player", unit) <= meleeRange
end

-- Handle combat log events
function Brewmaster:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Shuffle (formerly Ironskin Brew) application
            if spellID == buffs.SHUFFLE then
                shuffleActive = true
                shuffleEndTime = select(6, API.GetBuffInfo("player", buffs.SHUFFLE))
                API.PrintDebug("Shuffle activated")
            end
            
            -- Track Celestial Brew application
            if spellID == buffs.CELESTIAL_BREW then
                celestialBrewActive = true
                celestialBrewEndTime = select(6, API.GetBuffInfo("player", buffs.CELESTIAL_BREW))
                API.PrintDebug("Celestial Brew activated")
            end
            
            -- Track Zensphere Brew application
            if spellID == buffs.ZENSPHERE_BREW then
                zensphereBrewActive = true
                zensphereBrewEndTime = select(6, API.GetBuffInfo("player", buffs.ZENSPHERE_BREW))
                API.PrintDebug("Zensphere Brew activated")
            end
            
            -- Track Fortifying Brew application
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = true
                fortifyingBrewEndTime = select(6, API.GetBuffInfo("player", buffs.FORTIFYING_BREW))
                API.PrintDebug("Fortifying Brew activated")
            end
            
            -- Track Zen Meditation application
            if spellID == buffs.ZEN_MEDITATION then
                zenMeditationActive = true
                zenMeditationEndTime = select(6, API.GetBuffInfo("player", buffs.ZEN_MEDITATION))
                API.PrintDebug("Zen Meditation activated")
            end
            
            -- Track Blackout Combo application
            if spellID == buffs.BLACKOUT_COMBO then
                blackoutComboActive = true
                blackoutComboEndTime = select(6, API.GetBuffInfo("player", buffs.BLACKOUT_COMBO))
                API.PrintDebug("Blackout Combo activated")
            end
            
            -- Track Kensing Tea application
            if spellID == buffs.KENSING_TEA then
                kensingTeaActive = true
                kensingTeaEndTime = select(6, API.GetBuffInfo("player", buffs.KENSING_TEA))
                API.PrintDebug("Kensing Tea activated")
            end
            
            -- Track Charred Passions application
            if spellID == buffs.CHARRED_PASSIONS then
                charredPassionsActive = true
                charredPassionsEndTime = select(6, API.GetBuffInfo("player", buffs.CHARRED_PASSIONS))
                charredPassionsStacks = select(4, API.GetBuffInfo("player", buffs.CHARRED_PASSIONS)) or 1
                API.PrintDebug("Charred Passions activated: " .. tostring(charredPassionsStacks) .. " stack(s)")
            end
            
            -- Track Rushing Jade Wind application
            if spellID == buffs.RUSHING_JADE_WIND then
                rushingJadeWindActive = true
                rushingJadeWindEndTime = select(6, API.GetBuffInfo("player", buffs.RUSHING_JADE_WIND))
                API.PrintDebug("Rushing Jade Wind activated")
            end
            
            -- Track Weapons of Order application
            if spellID == buffs.WEAPONS_OF_ORDER then
                weaponsOfOrderActive = true
                weaponsOfOrderEndTime = select(6, API.GetBuffInfo("player", buffs.WEAPONS_OF_ORDER))
                API.PrintDebug("Weapons of Order activated")
            end
            
            -- Track Exploding Keg application
            if spellID == buffs.EXPLODING_KEG then
                explodingKegActive = true
                explodingKegEndTime = select(6, API.GetBuffInfo("player", buffs.EXPLODING_KEG))
                API.PrintDebug("Exploding Keg activated")
            end
            
            -- Track Celestial Flames application
            if spellID == buffs.CELESTIAL_FLAMES then
                celestialFlamesActive = true
                celestialFlamesEndTime = select(6, API.GetBuffInfo("player", buffs.CELESTIAL_FLAMES))
                API.PrintDebug("Celestial Flames activated")
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
            
            -- Track Bone Dust Brew application
            if spellID == buffs.BONE_DUST_BREW then
                boneDustBrewActive = true
                boneDustBrewEndTime = select(6, API.GetBuffInfo("player", buffs.BONE_DUST_BREW))
                API.PrintDebug("Bone Dust Brew activated")
            end
            
            -- Track Invoke Niuzao application
            if spellID == buffs.INVOKE_NIUZAO then
                invokeNiuzaoActive = true
                invokeNiuzaoEndTime = select(6, API.GetBuffInfo("player", buffs.INVOKE_NIUZAO))
                API.PrintDebug("Invoke Niuzao activated")
            end
            
            -- Track Kev Eye application
            if spellID == buffs.KEV_EYE then
                kevEyeActive = true
                kevEyeEndTime = select(6, API.GetBuffInfo("player", buffs.KEV_EYE))
                API.PrintDebug("Kev Eye activated")
            end
            
            -- Track Keeper of the Flame application
            if spellID == buffs.KEEPER_OF_THE_FLAME then
                keeperOfTheFlameActive = true
                keeperOfTheFlameStacks = select(4, API.GetBuffInfo("player", buffs.KEEPER_OF_THE_FLAME)) or 1
                API.PrintDebug("Keeper of the Flame activated: " .. tostring(keeperOfTheFlameStacks) .. " stack(s)")
            end
            
            -- Track Special Delivery application
            if spellID == buffs.SPECIAL_DELIVERY then
                specialDeliveryActive = true
                specialDeliveryEndTime = select(6, API.GetBuffInfo("player", buffs.SPECIAL_DELIVERY))
                API.PrintDebug("Special Delivery activated")
            end
            
            -- Track Niuzao's Mystery application
            if spellID == buffs.NIUZAOS_MYSTERY then
                niuzaosMysteryActive = true
                niuzaosMysteryEndTime = select(6, API.GetBuffInfo("player", buffs.NIUZAOS_MYSTERY))
                API.PrintDebug("Niuzao's Mystery activated")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Shuffle (formerly Ironskin Brew) removal
            if spellID == buffs.SHUFFLE then
                shuffleActive = false
                API.PrintDebug("Shuffle faded")
            end
            
            -- Track Celestial Brew removal
            if spellID == buffs.CELESTIAL_BREW then
                celestialBrewActive = false
                API.PrintDebug("Celestial Brew faded")
            end
            
            -- Track Zensphere Brew removal
            if spellID == buffs.ZENSPHERE_BREW then
                zensphereBrewActive = false
                API.PrintDebug("Zensphere Brew faded")
            end
            
            -- Track Fortifying Brew removal
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = false
                API.PrintDebug("Fortifying Brew faded")
            end
            
            -- Track Zen Meditation removal
            if spellID == buffs.ZEN_MEDITATION then
                zenMeditationActive = false
                API.PrintDebug("Zen Meditation faded")
            end
            
            -- Track Blackout Combo removal
            if spellID == buffs.BLACKOUT_COMBO then
                blackoutComboActive = false
                API.PrintDebug("Blackout Combo faded")
            end
            
            -- Track Kensing Tea removal
            if spellID == buffs.KENSING_TEA then
                kensingTeaActive = false
                API.PrintDebug("Kensing Tea faded")
            end
            
            -- Track Charred Passions removal
            if spellID == buffs.CHARRED_PASSIONS then
                charredPassionsActive = false
                charredPassionsStacks = 0
                API.PrintDebug("Charred Passions faded")
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
            
            -- Track Exploding Keg removal
            if spellID == buffs.EXPLODING_KEG then
                explodingKegActive = false
                API.PrintDebug("Exploding Keg faded")
            end
            
            -- Track Celestial Flames removal
            if spellID == buffs.CELESTIAL_FLAMES then
                celestialFlamesActive = false
                API.PrintDebug("Celestial Flames faded")
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
            
            -- Track Bone Dust Brew removal
            if spellID == buffs.BONE_DUST_BREW then
                boneDustBrewActive = false
                API.PrintDebug("Bone Dust Brew faded")
            end
            
            -- Track Invoke Niuzao removal
            if spellID == buffs.INVOKE_NIUZAO then
                invokeNiuzaoActive = false
                API.PrintDebug("Invoke Niuzao faded")
            end
            
            -- Track Kev Eye removal
            if spellID == buffs.KEV_EYE then
                kevEyeActive = false
                API.PrintDebug("Kev Eye faded")
            end
            
            -- Track Keeper of the Flame removal
            if spellID == buffs.KEEPER_OF_THE_FLAME then
                keeperOfTheFlameActive = false
                keeperOfTheFlameStacks = 0
                API.PrintDebug("Keeper of the Flame faded")
            end
            
            -- Track Special Delivery removal
            if spellID == buffs.SPECIAL_DELIVERY then
                specialDeliveryActive = false
                API.PrintDebug("Special Delivery faded")
            end
            
            -- Track Niuzao's Mystery removal
            if spellID == buffs.NIUZAOS_MYSTERY then
                niuzaosMysteryActive = false
                API.PrintDebug("Niuzao's Mystery faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            if spellID == spells.KEG_SMASH then
                lastKegSmash = GetTime()
                API.PrintDebug("Keg Smash cast")
            elseif spellID == spells.TIGER_PALM then
                lastTigerPalm = GetTime()
                API.PrintDebug("Tiger Palm cast")
            elseif spellID == spells.BREATH_OF_FIRE then
                lastBreathOfFire = GetTime()
                breathOfFireActive = true
                breathOfFireEndTime = GetTime() + BREATH_OF_FIRE_DURATION
                API.PrintDebug("Breath of Fire cast")
            elseif spellID == spells.RUSHING_JADE_WIND then
                lastRushingJadeWind = GetTime()
                rushingJadeWindActive = true
                rushingJadeWindEndTime = GetTime() + RUSHING_JADE_WIND_DURATION
                API.PrintDebug("Rushing Jade Wind cast")
            elseif spellID == spells.SPINNING_CRANE_KICK then
                lastSpinningCraneKick = GetTime()
                spinningCraneKickActive = true
                spinningCraneKickEndTime = GetTime() + 1.5 -- Duration of channel
                API.PrintDebug("Spinning Crane Kick cast")
            elseif spellID == spells.RISING_SUN_KICK then
                lastRisingSunKick = GetTime()
                API.PrintDebug("Rising Sun Kick cast")
            elseif spellID == spells.BLACKOUT_KICK then
                lastBlackoutKick = GetTime()
                blackoutKickActive = true
                blackoutKickEndTime = GetTime() + 1 -- Approximate duration
                API.PrintDebug("Blackout Kick cast")
            elseif spellID == spells.CELESTIAL_BREW then
                lastCelestialBrew = GetTime()
                celestialBrewActive = true
                celestialBrewEndTime = GetTime() + CELESTIAL_BREW_DURATION
                API.PrintDebug("Celestial Brew cast")
            elseif spellID == spells.PURIFYING_BREW then
                lastPurifyingBrew = GetTime()
                purifyingBrewActive = true
                API.PrintDebug("Purifying Brew cast")
            elseif spellID == spells.EXPEL_HARM then
                lastExpelHarm = GetTime()
                API.PrintDebug("Expel Harm cast")
            elseif spellID == spells.ZEN_MEDITATION then
                lastZenMeditation = GetTime()
                zenMeditationActive = true
                zenMeditationEndTime = GetTime() + ZEN_MEDITATION_DURATION
                API.PrintDebug("Zen Meditation cast")
            elseif spellID == spells.TOUCH_OF_DEATH then
                lastTouchOfDeath = GetTime()
                API.PrintDebug("Touch of Death cast")
            elseif spellID == spells.BONE_DUST_BREW then
                lastBoneDustBrew = GetTime()
                boneDustBrewActive = true
                boneDustBrewEndTime = GetTime() + BONE_DUST_BREW_DURATION
                API.PrintDebug("Bone Dust Brew cast")
            elseif spellID == spells.WEAPONS_OF_ORDER then
                lastWeaponsOfOrder = GetTime()
                weaponsOfOrderActive = true
                weaponsOfOrderEndTime = GetTime() + WEAPONS_OF_ORDER_DURATION
                API.PrintDebug("Weapons of Order cast")
            elseif spellID == spells.EXPLODING_KEG then
                lastExplodingKeg = GetTime()
                explodingKegActive = true
                explodingKegEndTime = GetTime() + EXPLODING_KEG_DURATION
                API.PrintDebug("Exploding Keg cast")
            elseif spellID == spells.CHI_BURST then
                lastChiBurst = GetTime()
                API.PrintDebug("Chi Burst cast")
            elseif spellID == spells.CHI_WAVE then
                lastChiWave = GetTime()
                API.PrintDebug("Chi Wave cast")
            elseif spellID == spells.INVOKE_NIUZAO then
                lastInvokeNiuzao = GetTime()
                invokeNiuzaoActive = true
                invokeNiuzaoEndTime = GetTime() + INVOKE_NIUZAO_DURATION
                API.PrintDebug("Invoke Niuzao cast")
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
            elseif spellID == spells.LEG_SWEEP then
                lastLegSweep = GetTime()
                API.PrintDebug("Leg Sweep cast")
            elseif spellID == spells.PARALYSIS then
                lastParalysis = GetTime()
                API.PrintDebug("Paralysis cast")
            elseif spellID == spells.DETOX then
                lastDetox = GetTime()
                API.PrintDebug("Detox cast")
            elseif spellID == spells.VIVIFY then
                lastVivify = GetTime()
                API.PrintDebug("Vivify cast")
            elseif spellID == spells.TRANSCENDENCE then
                lastTranscendence = GetTime()
                API.PrintDebug("Transcendence cast")
            elseif spellID == spells.TRANSCENDENCE_TRANSFER then
                lastTranscendenceTransfer = GetTime()
                API.PrintDebug("Transcendence Transfer cast")
            end
        end
        
        -- Track debuff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Breath of Fire DoT application
            if spellID == debuffs.BREATH_OF_FIRE and destGUID then
                API.PrintDebug("Breath of Fire DoT applied to " .. destName)
            end
            
            -- Track Keg Smash debuff application
            if spellID == debuffs.KEG_SMASH and destGUID then
                API.PrintDebug("Keg Smash debuff applied to " .. destName)
            end
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
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BrewmasterMonk")
    
    -- Update variables
    self:UpdateChi()
    self:UpdateEnergy()
    self:UpdateStagger()
    self:UpdateEnemyCounts()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Check if in melee range
    isInMelee = self:IsInMeleeRange("target")
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle stagger situations first
    if self:HandleStagger(settings) then
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle major cooldowns (Niuzao, Weapons of Order, etc.)
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

-- Handle stagger situations
function Brewmaster:HandleStagger(settings)
    -- Use Purifying Brew to clear stagger
    if purifyingBrew and 
       settings.defensiveSettings.purifyingBrewEnabled and 
       settings.defensiveSettings.purifyingBrewMode ~= "Manual Only" and
       settings.abilityControls.purifyingBrew.enabled and
       API.CanCast(spells.PURIFYING_BREW) then
        
        local shouldPurify = false
        
        if settings.defensiveSettings.purifyingBrewMode == "Moderate/Heavy Stagger" then
            shouldPurify = staggerPercentage >= moderateStaggerThreshold
        elseif settings.defensiveSettings.purifyingBrewMode == "Heavy Stagger Only" then
            shouldPurify = staggerPercentage >= heavyStaggerThreshold
        elseif settings.defensiveSettings.purifyingBrewMode == "Based on Health" then
            shouldPurify = playerHealth <= settings.defensiveSettings.purifyingBrewHealthThreshold and staggerPercentage >= 20
        end
        
        -- Check AAC settings
        if settings.abilityControls.purifyingBrew.heavyStaggerOnly and staggerPercentage < heavyStaggerThreshold then
            shouldPurify = false
        end
        
        if settings.abilityControls.purifyingBrew.minHealthPercent > 0 and playerHealth > settings.abilityControls.purifyingBrew.minHealthPercent then
            shouldPurify = false
        end
        
        if settings.abilityControls.purifyingBrew.saveCharges > 0 and purifyingBrewCharges <= settings.abilityControls.purifyingBrew.saveCharges then
            shouldPurify = false
        end
        
        if settings.abilityControls.purifyingBrew.useDuringBurstOnly and not burstModeActive then
            shouldPurify = false
        end
        
        -- Use Purifying Brew if criteria met
        if shouldPurify then
            API.CastSpell(spells.PURIFYING_BREW)
            return true
        end
    end
    
    -- Use Celestial Brew for mitigation
    if celestialBrew and 
       settings.defensiveSettings.celestialBrewEnabled and 
       settings.defensiveSettings.celestialBrewMode ~= "Manual Only" and
       API.CanCast(spells.CELESTIAL_BREW) then
        
        local shouldUseCelestialBrew = false
        
        if settings.defensiveSettings.celestialBrewMode == "On Cooldown" then
            shouldUseCelestialBrew = true
        elseif settings.defensiveSettings.celestialBrewMode == "Based on Health" then
            shouldUseCelestialBrew = playerHealth <= settings.defensiveSettings.celestialBrewHealthThreshold
        elseif settings.defensiveSettings.celestialBrewMode == "After Purifying Brew" then
            shouldUseCelestialBrew = GetTime() - lastPurifyingBrew < 3
        end
        
        if shouldUseCelestialBrew then
            API.CastSpell(spells.CELESTIAL_BREW)
            return true
        end
    end
    
    -- Use Expel Harm for healing
    if expelHarm and 
       settings.defensiveSettings.expelHarmEnabled and
       playerHealth <= settings.defensiveSettings.expelHarmThreshold and
       API.CanCast(spells.EXPEL_HARM) then
        API.CastSpell(spells.EXPEL_HARM)
        return true
    end
    
    -- Maintain Shuffle (formerly Ironskin Brew)
    if settings.rotationSettings.maintainShuffle and
       (not shuffleActive or (shuffleEndTime - GetTime() < settings.rotationSettings.shuffleThreshold)) then
        
        -- Refresh Shuffle with Keg Smash + Blackout Combo
        if blackoutCombo and blackoutComboActive and API.CanCast(spells.KEG_SMASH) then
            API.CastSpellOnUnit(spells.KEG_SMASH, "target")
            return true
        end
        
        -- Refresh Shuffle with Tiger Palm + Blackout Combo
        if blackoutCombo and blackoutComboActive and API.CanCast(spells.TIGER_PALM) then
            API.CastSpellOnUnit(spells.TIGER_PALM, "target")
            return true
        end
    end
    
    return false
end

-- Handle defensive cooldowns
function Brewmaster:HandleDefensives(settings)
    -- Use Fortifying Brew for major damage reduction
    if fortifyingBrew and 
       settings.defensiveSettings.fortifyingBrewEnabled and 
       playerHealth <= settings.defensiveSettings.fortifyingBrewThreshold and 
       API.CanCast(spells.FORTIFYING_BREW) then
        API.CastSpell(spells.FORTIFYING_BREW)
        return true
    end
    
    -- Use Zen Meditation for major damage reduction
    if zenMeditation and 
       settings.defensiveSettings.zenMeditationEnabled and 
       playerHealth <= settings.defensiveSettings.zenMeditationThreshold and 
       API.CanCast(spells.ZEN_MEDITATION) and
       not API.IsPlayerMoving() then
        API.CastSpell(spells.ZEN_MEDITATION)
        return true
    end
    
    -- Use Dampen Harm
    if dampenHarm and 
       settings.defensiveSettings.dampenHarmEnabled and 
       playerHealth <= settings.defensiveSettings.dampenHarmThreshold and 
       API.CanCast(spells.DAMPEN_HARM) then
        API.CastSpell(spells.DAMPEN_HARM)
        return true
    end
    
    -- Use Diffuse Magic when taking magic damage
    if diffuseMagic and 
       settings.defensiveSettings.diffuseMagicEnabled and 
       playerHealth <= settings.defensiveSettings.diffuseMagicThreshold and 
       API.CanCast(spells.DIFFUSE_MAGIC) and
       API.IsTakingMagicDamage("player") then
        API.CastSpell(spells.DIFFUSE_MAGIC)
        return true
    end
    
    return false
end

-- Handle interrupts and utility
function Brewmaster:HandleInterrupts(settings)
    -- Use Spear Hand Strike to interrupt
    if spearHandStrike and 
       settings.interruptSettings.useSpearHandStrike and 
       API.CanCast(spells.SPEAR_HAND_STRIKE) and
       API.IsUnitCasting("target") and
       API.CanBeInterrupted("target") then
        API.CastSpellOnUnit(spells.SPEAR_HAND_STRIKE, "target")
        return true
    end
    
    -- Use Leg Sweep for AoE stun
    if legSweep and 
       settings.interruptSettings.useLegSweep and 
       API.CanCast(spells.LEG_SWEEP) and
       activeEnemies >= settings.interruptSettings.legSweepMinTargets then
        API.CastSpell(spells.LEG_SWEEP)
        return true
    end
    
    -- Use Paralysis for CC
    if paralysis and 
       settings.interruptSettings.useParalysis and 
       API.CanCast(spells.PARALYSIS) and
       API.ShouldCrowdControl("target") then
        API.CastSpellOnUnit(spells.PARALYSIS, "target")
        return true
    end
    
    -- Use Detox to cleanse
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
    
    -- Use Vivify for emergency healing
    if vivify and 
       settings.utilitySettings.useVivify and 
       playerHealth <= settings.utilitySettings.vivifyThreshold and
       API.CanCast(spells.VIVIFY) and
       not API.IsInPvPCombat() then
        API.CastSpellOnUnit(spells.VIVIFY, "player")
        return true
    end
    
    -- Use Transcendence
    if transcendence and 
       settings.utilitySettings.useTranscendence and 
       settings.utilitySettings.transcendenceMode ~= "Manual Only" and
       ((settings.utilitySettings.transcendenceMode == "Place on Cooldown" and API.CanCast(spells.TRANSCENDENCE)) or
        (settings.utilitySettings.transcendenceMode == "Transfer When Low Health" and playerHealth <= 30 and API.CanCast(spells.TRANSCENDENCE_TRANSFER))) then
        
        if settings.utilitySettings.transcendenceMode == "Place on Cooldown" then
            API.CastSpell(spells.TRANSCENDENCE)
            return true
        elseif settings.utilitySettings.transcendenceMode == "Transfer When Low Health" then
            API.CastSpell(spells.TRANSCENDENCE_TRANSFER)
            return true
        end
    end
    
    -- Use White Tiger Statue
    if summonWhiteTigerStatue and 
       settings.utilitySettings.summonWhiteTigerStatueEnabled and 
       API.CanCast(spells.SUMMON_WHITE_TIGER_STATUE) and
       not summonWhiteTigerStatueActive then
        API.CastSpellAtBestLocation(spells.SUMMON_WHITE_TIGER_STATUE)
        return true
    end
    
    return false
end

-- Handle major cooldowns
function Brewmaster:HandleMajorCooldowns(settings)
    -- Use Invoke Niuzao
    if invokeNiuzao and 
       settings.cooldownSettings.invokeNiuzaoEnabled and 
       settings.cooldownSettings.invokeNiuzaoMode ~= "Manual Only" and
       API.CanCast(spells.INVOKE_NIUZAO) then
        
        local shouldUseNiuzao = false
        
        if settings.cooldownSettings.invokeNiuzaoMode == "On Cooldown" then
            shouldUseNiuzao = true
        elseif settings.cooldownSettings.invokeNiuzaoMode == "With Other Cooldowns" then
            shouldUseNiuzao = weaponsOfOrderActive or fortifyingBrewActive or burstModeActive
        elseif settings.cooldownSettings.invokeNiuzaoMode == "Boss Only" then
            shouldUseNiuzao = API.IsFightingBoss()
        end
        
        if shouldUseNiuzao then
            API.CastSpell(spells.INVOKE_NIUZAO)
            return true
        end
    end
    
    -- Use Touch of Death
    if touchOfDeath and 
       settings.cooldownSettings.touchOfDeathEnabled and 
       API.CanCast(spells.TOUCH_OF_DEATH) then
        API.CastSpellOnUnit(spells.TOUCH_OF_DEATH, "target")
        return true
    end
    
    -- Use Weapons of Order
    if weaponsOfOrder and 
       settings.cooldownSettings.weaponsOfOrderEnabled and 
       settings.cooldownSettings.weaponsOfOrderMode ~= "Manual Only" and
       API.CanCast(spells.WEAPONS_OF_ORDER) then
        
        local shouldUseWoO = false
        
        if settings.cooldownSettings.weaponsOfOrderMode == "On Cooldown" then
            shouldUseWoO = true
        elseif settings.cooldownSettings.weaponsOfOrderMode == "With Other Cooldowns" then
            shouldUseWoO = invokeNiuzaoActive or fortifyingBrewActive or burstModeActive
        elseif settings.cooldownSettings.weaponsOfOrderMode == "Boss Only" then
            shouldUseWoO = API.IsFightingBoss()
        end
        
        if shouldUseWoO then
            API.CastSpell(spells.WEAPONS_OF_ORDER)
            return true
        end
    end
    
    -- Use Bone Dust Brew
    if boneDustBrew and 
       settings.cooldownSettings.boneDustBrewEnabled and 
       settings.cooldownSettings.boneDustBrewMode ~= "Manual Only" and
       API.CanCast(spells.BONE_DUST_BREW) then
        
        local shouldUseBDB = false
        
        if settings.cooldownSettings.boneDustBrewMode == "On Cooldown" then
            shouldUseBDB = true
        elseif settings.cooldownSettings.boneDustBrewMode == "With Cooldowns" then
            shouldUseBDB = invokeNiuzaoActive or weaponsOfOrderActive or burstModeActive
        elseif settings.cooldownSettings.boneDustBrewMode == "AoE Only" then
            shouldUseBDB = activeEnemies >= 3
        end
        
        if shouldUseBDB then
            API.CastSpellOnUnit(spells.BONE_DUST_BREW, "target")
            return true
        end
    end
    
    -- Use Exploding Keg
    if explodingKeg and 
       settings.cooldownSettings.explodingKegEnabled and 
       settings.cooldownSettings.explodingKegMode ~= "Manual Only" and
       API.CanCast(spells.EXPLODING_KEG) then
        
        local shouldUseEK = false
        
        if settings.cooldownSettings.explodingKegMode == "On Cooldown" then
            shouldUseEK = true
        elseif settings.cooldownSettings.explodingKegMode == "AoE Only" then
            shouldUseEK = activeEnemies >= 3
        elseif settings.cooldownSettings.explodingKegMode == "With Cooldowns" then
            shouldUseEK = invokeNiuzaoActive or weaponsOfOrderActive or burstModeActive
        end
        
        if shouldUseEK then
            API.CastSpellAtBestLocation(spells.EXPLODING_KEG)
            return true
        end
    end
    
    -- Use Kensing Tea
    if kensingTea and 
       settings.cooldownSettings.kensingTeaEnabled and 
       API.CanCast(spells.KENSING_TEA) then
        API.CastSpell(spells.KENSING_TEA)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Brewmaster:HandleAoE(settings)
    -- Use Rushing Jade Wind
    if rushingJadeWind and 
       settings.cooldownSettings.rushingJadeWindEnabled and 
       not rushingJadeWindActive and
       activeEnemies >= settings.cooldownSettings.rushingJadeWindAoEThreshold and
       API.CanCast(spells.RUSHING_JADE_WIND) then
        API.CastSpell(spells.RUSHING_JADE_WIND)
        return true
    end
    
    -- Use Keg Smash
    if API.CanCast(spells.KEG_SMASH) and
       settings.abilityControls.kegSmash.enabled and
       settings.rotationSettings.kegSmashPriority then
        
        local shouldUseKegSmash = true
        
        -- Check if we're saving for Blackout Combo
        if blackoutCombo and settings.abilityControls.kegSmash.prioritizeWithBlackoutCombo and not blackoutComboActive then
            shouldUseKegSmash = false
        end
        
        if settings.abilityControls.kegSmash.useDuringBurstOnly and not burstModeActive then
            shouldUseKegSmash = false
        end
        
        if shouldUseKegSmash then
            API.CastSpellOnUnit(spells.KEG_SMASH, "target")
            return true
        end
    end
    
    -- Use Breath of Fire
    if breathOfFire and
       API.CanCast(spells.BREATH_OF_FIRE) and
       settings.abilityControls.breathOfFire.enabled then
        
        local shouldUseBoF = true
        
        if settings.rotationSettings.breathOfFireMode == "Only with Keg Smash Debuff" then
            shouldUseBoF = API.UnitHasDebuff("target", debuffs.KEG_SMASH)
        elseif settings.rotationSettings.breathOfFireMode == "With Keeper of Flame Stacks" then
            shouldUseBoF = keeperOfTheFlameActive and keeperOfTheFlameStacks >= settings.abilityControls.breathOfFire.minimumKeeperStacks
        elseif settings.rotationSettings.breathOfFireMode == "Manual Only" then
            shouldUseBoF = false
        end
        
        if settings.abilityControls.breathOfFire.requireKegSmashDebuff and not API.UnitHasDebuff("target", debuffs.KEG_SMASH) then
            shouldUseBoF = false
        end
        
        if settings.abilityControls.breathOfFire.useDuringBurstOnly and not burstModeActive then
            shouldUseBoF = false
        end
        
        if shouldUseBoF then
            API.CastSpell(spells.BREATH_OF_FIRE)
            return true
        end
    end
    
    -- Use Blackout Kick with Blackout Combo talent
    if blackoutKick and
       blackoutCombo and
       blackoutComboActive and
       settings.rotationSettings.blackoutKickWithCombo and
       API.CanCast(spells.BLACKOUT_KICK) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Spinning Crane Kick for AoE damage
    if spinningCraneKick and
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       activeEnemies >= 3 and
       (not settings.rotationSettings.energyPooling or currentEnergy > settings.rotationSettings.energyPoolingThreshold + 30) then
        API.CastSpell(spells.SPINNING_CRANE_KICK)
        return true
    end
    
    -- Use Chi Burst if talented
    if chiBurst and
       API.CanCast(spells.CHI_BURST) and
       activeEnemies >= 3 then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Use Rising Sun Kick
    if risingSunKick and API.CanCast(spells.RISING_SUN_KICK) then
        API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
        return true
    end
    
    -- Use Tiger Palm for Chi generation
    if tigerPalm and
       API.CanCast(spells.TIGER_PALM) and
       (not settings.rotationSettings.energyPooling or currentEnergy > settings.rotationSettings.energyPoolingThreshold) then
        API.CastSpellOnUnit(spells.TIGER_PALM, "target")
        return true
    end
    
    return false
end

-- Handle single target rotation
function Brewmaster:HandleSingleTarget(settings)
    -- Use Keg Smash
    if API.CanCast(spells.KEG_SMASH) and
       settings.abilityControls.kegSmash.enabled and
       settings.rotationSettings.kegSmashPriority then
        
        local shouldUseKegSmash = true
        
        -- Check if we're saving for Blackout Combo
        if blackoutCombo and settings.abilityControls.kegSmash.prioritizeWithBlackoutCombo and not blackoutComboActive then
            shouldUseKegSmash = false
        end
        
        if settings.abilityControls.kegSmash.useDuringBurstOnly and not burstModeActive then
            shouldUseKegSmash = false
        end
        
        if shouldUseKegSmash then
            API.CastSpellOnUnit(spells.KEG_SMASH, "target")
            return true
        end
    end
    
    -- Use Blackout Kick with Blackout Combo talent
    if blackoutKick and
       blackoutCombo and
       blackoutComboActive and
       settings.rotationSettings.blackoutKickWithCombo and
       API.CanCast(spells.BLACKOUT_KICK) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Breath of Fire
    if breathOfFire and
       API.CanCast(spells.BREATH_OF_FIRE) and
       settings.abilityControls.breathOfFire.enabled then
        
        local shouldUseBoF = true
        
        if settings.rotationSettings.breathOfFireMode == "Only with Keg Smash Debuff" then
            shouldUseBoF = API.UnitHasDebuff("target", debuffs.KEG_SMASH)
        elseif settings.rotationSettings.breathOfFireMode == "With Keeper of Flame Stacks" then
            shouldUseBoF = keeperOfTheFlameActive and keeperOfTheFlameStacks >= settings.abilityControls.breathOfFire.minimumKeeperStacks
        elseif settings.rotationSettings.breathOfFireMode == "Manual Only" then
            shouldUseBoF = false
        end
        
        if settings.abilityControls.breathOfFire.requireKegSmashDebuff and not API.UnitHasDebuff("target", debuffs.KEG_SMASH) then
            shouldUseBoF = false
        end
        
        if settings.abilityControls.breathOfFire.useDuringBurstOnly and not burstModeActive then
            shouldUseBoF = false
        end
        
        if shouldUseBoF then
            API.CastSpell(spells.BREATH_OF_FIRE)
            return true
        end
    end
    
    -- Use Chi Wave if talented
    if chiWave and API.CanCast(spells.CHI_WAVE) then
        API.CastSpellOnUnit(spells.CHI_WAVE, "target")
        return true
    end
    
    -- Use Rushing Jade Wind in single target for DPS if talented
    if rushingJadeWind and 
       settings.cooldownSettings.rushingJadeWindEnabled and 
       not rushingJadeWindActive and
       API.CanCast(spells.RUSHING_JADE_WIND) then
        API.CastSpell(spells.RUSHING_JADE_WIND)
        return true
    end
    
    -- Use Rising Sun Kick
    if risingSunKick and API.CanCast(spells.RISING_SUN_KICK) then
        API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
        return true
    end
    
    -- Use Blackout Kick
    if blackoutKick and API.CanCast(spells.BLACKOUT_KICK) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Tiger Palm for Chi generation and filler
    if tigerPalm and
       API.CanCast(spells.TIGER_PALM) and
       (not settings.rotationSettings.energyPooling or currentEnergy > settings.rotationSettings.energyPoolingThreshold) then
        API.CastSpellOnUnit(spells.TIGER_PALM, "target")
        return true
    end
    
    return false
end

-- Handle specialization change
function Brewmaster:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentChi = 0
    maxChi = 5
    currentEnergy = 100
    maxEnergy = 100
    staggerPercentage = 0
    heavyStaggerThreshold = 60
    moderateStaggerThreshold = 30
    ironskinBrewActive = false
    ironskinBrewEndTime = 0
    ironskinBrewCharges = 0
    ironskinBrewMaxCharges = 0
    purifyingBrewActive = false
    purifyingBrewCharges = 0
    purifyingBrewMaxCharges = 0
    zensphereBrewActive = false
    zensphereBrewEndTime = 0
    celestialBrewActive = false
    celestialBrewEndTime = 0
    blackoutKickActive = false
    blackoutKickEndTime = 0
    kensingTea = false
    kensingTeaActive = false
    kensingTeaEndTime = 0
    invokeNiuzaoActive = false
    invokeNiuzaoEndTime = 0
    breathOfFireActive = false
    breathOfFireEndTime = 0
    blackoutComboActive = false
    blackoutComboEndTime = 0
    shuffleActive = false
    shuffleEndTime = 0
    fortifyingBrewActive = false
    fortifyingBrewEndTime = 0
    zenMeditation = false
    zenMeditationActive = false
    zenMeditationEndTime = 0
    boneDustBrew = false
    boneDustBrewActive = false
    boneDustBrewEndTime = 0
    weaponsOfOrder = false
    weaponsOfOrderActive = false
    weaponsOfOrderEndTime = 0
    charredPassions = false
    charredPassionsActive = false
    charredPassionsEndTime = 0
    charredPassionsStacks = 0
    blackoutCombo = false
    highTolerance = false
    highToleranceStacks = 0
    highToleranceActive = false
    celestialFlamesActive = false
    celestialFlamesEndTime = 0
    explodingKeg = false
    explodingKegActive = false
    explodingKegEndTime = 0
    rushingJadeWind = false
    rushingJadeWindActive = false
    rushingJadeWindEndTime = 0
    summonWhiteTigerStatue = false
    summonWhiteTigerStatueActive = false
    summonWhiteTigerStatueEndTime = 0
    dampenHarm = false
    dampenHarmActive = false
    dampenHarmEndTime = 0
    diffuseMagic = false
    diffuseMagicActive = false
    diffuseMagicEndTime = 0
    invokeNiuzao = false
    chiBurst = false
    chiWave = false
    smite = false
    smiteActive = false
    smiteEndTime = 0
    spinningCraneKick = false
    spinningCraneKickActive = false
    spinningCraneKickEndTime = 0
    tigerPalm = false
    blackoutKick = false
    risingSunKick = false
    keeperOfTheFlame = false
    keeperOfTheFlameActive = false
    keeperOfTheFlameStacks = 0
    breathOfFire = false
    kevEye = false
    kevEyeActive = false
    kevEyeEndTime = 0
    celestialBrew = false
    purifyingBrew = false
    expelHarm = false
    legSweep = false
    paralysis = false
    provoke = false
    spearHandStrike = false
    detox = false
    vivify = false
    transcendence = false
    transcendenceTransfer = false
    rollOut = false
    pressurePoint = false
    drinkingHornCover = false
    touchOfDeath = false
    specialDelivery = false
    specialDeliveryActive = false
    specialDeliveryEndTime = 0
    niuzaosMysteryActive = false
    niuzaosMysteryEndTime = 0
    lastKegSmash = 0
    lastTigerPalm = 0
    lastBreathOfFire = 0
    lastRushingJadeWind = 0
    lastSpinningCraneKick = 0
    lastRisingSunKick = 0
    lastBlackoutKick = 0
    lastCelestialBrew = 0
    lastPurifyingBrew = 0
    lastExpelHarm = 0
    lastZenMeditation = 0
    lastTouchOfDeath = 0
    lastBoneDustBrew = 0
    lastWeaponsOfOrder = 0
    lastExplodingKeg = 0
    lastChiBurst = 0
    lastChiWave = 0
    lastInvokeNiuzao = 0
    lastDampenHarm = 0
    lastDiffuseMagic = 0
    lastLegSweep = 0
    lastParalysis = 0
    lastDetox = 0
    lastVivify = 0
    lastTranscendence = 0
    lastTranscendenceTransfer = 0
    playerHealth = 100
    activeEnemies = 0
    isInMelee = false
    
    API.PrintDebug("Brewmaster Monk state reset on spec change")
    
    return true
end

-- Return the module for loading
return Brewmaster