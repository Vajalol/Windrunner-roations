------------------------------------------
-- WindrunnerRotations - Monk Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local MonkModule = {}
WR.Monk = MonkModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Monk constants
local CLASS_ID = 10 -- Monk class ID
local SPEC_BREWMASTER = 268
local SPEC_MISTWEAVER = 270
local SPEC_WINDWALKER = 269

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Brewmaster Monk (The War Within, Season 2)
local BREWMASTER_SPELLS = {
    -- Core abilities
    KEG_SMASH = 121253,
    BLACKOUT_KICK = 205523,
    TIGER_PALM = 100780,
    BREATH_OF_FIRE = 115181,
    RUSHING_JADE_WIND = 116847,
    CELESTIAL_BREW = 322507,
    PURIFYING_BREW = 119582,
    PROVOKE = 115546,
    CLASH = 324312,
    ZEN_MEDITATION = 115176,
    FORTIFYING_BREW = 115203,
    
    -- Defensive & utility
    EXPEL_HARM = 322101,
    GUARD = 115295,
    SPEAR_HAND_STRIKE = 116705,
    LEG_SWEEP = 119381,
    PARALYSIS = 115078,
    RING_OF_PEACE = 116844,
    TRANSCENDENCE = 101643,
    TRANSCENDENCE_TRANSFER = 119996,
    
    -- Talents
    INVOKE_NIUZAO_THE_BLACK_OX = 132578,
    CHI_WAVE = 115098,
    CHI_BURST = 123986,
    SUMMON_BLACK_OX_STATUE = 115315,
    BLACKOUT_COMBO = 196736,
    HIGH_TOLERANCE = 196737,
    SPECIAL_DELIVERY = 196730,
    BOB_AND_WEAVE = 280515,
    
    -- Misc
    DETOX = 218164,
    VIVIFY = 116670,
    ZEN_FLIGHT = 125883,
    ROLL = 109132,
    CHI_TORPEDO = 115008,
    TIGERS_LUST = 116841
}

-- Spell IDs for Mistweaver Monk
local MISTWEAVER_SPELLS = {
    -- Core abilities
    SOOTHING_MIST = 115175,
    ENVELOPING_MIST = 124682,
    VIVIFY = 116670,
    RENEWING_MIST = 115151,
    REVIVAL = 115310,
    ESSENCE_FONT = 191837,
    LIFE_COCOON = 116849,
    THUNDER_FOCUS_TEA = 116680,
    RISING_SUN_KICK = 107428,
    TIGERS_LUST = 116841,
    
    -- Defensive & utility
    FORTIFYING_BREW = 243435,
    SPEAR_HAND_STRIKE = 116705,
    LEG_SWEEP = 119381,
    PARALYSIS = 115078,
    RING_OF_PEACE = 116844,
    TRANSCENDENCE = 101643,
    TRANSCENDENCE_TRANSFER = 119996,
    
    -- Talents
    INVOKE_YULON_THE_JADE_SERPENT = 322118,
    INVOKE_CHI_JI_THE_RED_CRANE = 325197,
    CHI_WAVE = 115098,
    CHI_BURST = 123986,
    MANA_TEA = 197908,
    SUMMON_JADE_SERPENT_STATUE = 115313,
    REFRESHING_JADE_WIND = 196725,
    SONG_OF_CHI_JI = 198898,
    FOCUSED_THUNDER = 197895,
    LIFECYCLES = 197915,
    UPWELLING = 274963,
    
    -- Misc
    DETOX = 115450,
    REAWAKEN = 212051,
    ZEN_FLIGHT = 125883,
    ROLL = 109132,
    CHI_TORPEDO = 115008,
    CRACKLING_JADE_LIGHTNING = 117952
}

-- Spell IDs for Windwalker Monk
local WINDWALKER_SPELLS = {
    -- Core abilities
    TIGER_PALM = 100780,
    RISING_SUN_KICK = 107428,
    BLACKOUT_KICK = 100784,
    FISTS_OF_FURY = 113656,
    SPINNING_CRANE_KICK = 101546,
    WHIRLING_DRAGON_PUNCH = 152175,
    TOUCH_OF_DEATH = 115080,
    TOUCH_OF_KARMA = 122470,
    TIGEREYE_BREW = 247483,
    STORM_EARTH_AND_FIRE = 137639,
    SERENITY = 152173,
    
    -- Defensive & utility
    FORTIFYING_BREW = 243435,
    SPEAR_HAND_STRIKE = 116705,
    LEG_SWEEP = 119381,
    PARALYSIS = 115078,
    RING_OF_PEACE = 116844,
    TRANSCENDENCE = 101643,
    TRANSCENDENCE_TRANSFER = 119996,
    TIGEREYE_BREW = 116740,
    
    -- Talents
    INVOKE_XUEN_THE_WHITE_TIGER = 123904,
    CHI_WAVE = 115098,
    CHI_BURST = 123986,
    FIST_OF_THE_WHITE_TIGER = 261947,
    RUSHING_JADE_WIND = 116847,
    DANCE_OF_CHI_JI = 325201,
    HIT_COMBO = 196740,
    MARK_OF_THE_CRANE = 220357,
    
    -- Misc
    DETOX = 218164,
    VIVIFY = 116670,
    ZEN_FLIGHT = 125883,
    ROLL = 109132,
    CHI_TORPEDO = 115008,
    FLYING_SERPENT_KICK = 101545,
    TIGERS_LUST = 116841,
    CRACKLING_JADE_LIGHTNING = 117952
}

-- Important buffs to track
local BUFFS = {
    BLACKOUT_COMBO = 228563,
    RUSHING_JADE_WIND = 116847,
    CELESTIAL_BREW = 322507,
    PURIFIED_CHI = 325092,
    HIGH_TOLERANCE = 196737,
    FORTIFYING_BREW = 115203,
    IRONSKIN_BREW = 215479,
    STAGGER = 124255,
    ZEN_MEDITATION = 115176,
    
    SOOTHING_MIST = 115175,
    ENVELOPING_MIST = 124682,
    RENEWING_MIST = 119611,
    ESSENCE_FONT = 191837,
    LIFE_COCOON = 116849,
    THUNDER_FOCUS_TEA = 116680,
    MANA_TEA = 197908,
    
    STORM_EARTH_AND_FIRE = 137639,
    SERENITY = 152173,
    TOUCH_OF_KARMA = 125174,
    HIT_COMBO = 196741,
    COMBO_BREAKER = 116768,
    TOUCH_OF_DEATH = 115080,
    DANCE_OF_CHI_JI = 325202,
    TIGEREYE_BREW = 247483,
    WHIRLING_DRAGON_PUNCH = 152175,
    MARK_OF_THE_CRANE = 228287
}

-- Important debuffs to track
local DEBUFFS = {
    KEG_SMASH = 121253,
    BREATH_OF_FIRE = 123725,
    MYSTIC_TOUCH = 113746,
    LEG_SWEEP = 119381,
    PARALYSIS = 115078,
    FLYING_SERPENT_KICK = 123586,
    RING_OF_PEACE = 116844
}

-- Initialize the Monk module
function MonkModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Monk module initialized")
    return true
end

-- Register settings
function MonkModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Monk", {
        generalSettings = {
            enabled = {
                displayName = "Enable Monk Module",
                description = "Enable the Monk module for all specs",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when appropriate",
                type = "toggle",
                default = true
            },
            useInterrupts = {
                displayName = "Use Interrupts",
                description = "Automatically interrupt enemy casts when appropriate",
                type = "toggle",
                default = true
            },
            useMovementAbilities = {
                displayName = "Use Movement Abilities",
                description = "Automatically use Roll or Chi Torpedo to move",
                type = "toggle",
                default = true
            },
            useTranscendence = {
                displayName = "Use Transcendence",
                description = "Automatically use Transcendence and Transfer in combat",
                type = "toggle",
                default = false
            },
            useDetox = {
                displayName = "Use Detox",
                description = "Automatically dispel harmful effects",
                type = "toggle",
                default = true
            }
        },
        brewmasterSettings = {
            useNiuzao = {
                displayName = "Use Niuzao",
                description = "Use Invoke Niuzao, the Black Ox on cooldown",
                type = "toggle",
                default = true
            },
            purifyingBrewMode = {
                displayName = "Purifying Brew Usage",
                description = "How to use Purifying Brew",
                type = "dropdown",
                options = {"Heavy Stagger Only", "Moderate+ Stagger", "Any Stagger"},
                default = "Moderate+ Stagger"
            },
            celestialBrewThreshold = {
                displayName = "Celestial Brew Health Threshold",
                description = "Health percentage to use Celestial Brew",
                type = "slider",
                min = 20,
                max = 90,
                step = 5,
                default = 70
            },
            useFortifyingBrew = {
                displayName = "Use Fortifying Brew",
                description = "Use Fortifying Brew at low health",
                type = "toggle",
                default = true
            },
            fortifyingBrewThreshold = {
                displayName = "Fortifying Brew Health Threshold",
                description = "Health percentage to use Fortifying Brew",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 35
            },
            useZenMeditation = {
                displayName = "Use Zen Meditation",
                description = "Use Zen Meditation when taking heavy damage",
                type = "toggle",
                default = true
            },
            kegSmashPriority = {
                displayName = "Keg Smash Priority",
                description = "Prioritize Keg Smash over other abilities",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        },
        mistWeaverSettings = {
            useEssenceFont = {
                displayName = "Use Essence Font",
                description = "Use Essence Font for group healing",
                type = "toggle",
                default = true
            },
            essenceFontThreshold = {
                displayName = "Essence Font Injured Count",
                description = "Minimum injured party members to use Essence Font",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            useSoothingMist = {
                displayName = "Use Soothing Mist",
                description = "Use Soothing Mist for sustained healing",
                type = "toggle",
                default = true
            },
            envelopingMistThreshold = {
                displayName = "Enveloping Mist Health Threshold",
                description = "Health percentage to use Enveloping Mist",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 60
            },
            useLifeCocoon = {
                displayName = "Use Life Cocoon",
                description = "Use Life Cocoon on low health targets",
                type = "toggle",
                default = true
            },
            lifeCocooonThreshold = {
                displayName = "Life Cocoon Health Threshold",
                description = "Health percentage to use Life Cocoon",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            },
            useRevival = {
                displayName = "Use Revival",
                description = "Use Revival for major group healing",
                type = "toggle",
                default = true
            },
            revivalThreshold = {
                displayName = "Revival Group Health Threshold",
                description = "Average group health percentage to use Revival",
                type = "slider",
                min = 10,
                max = 70,
                step = 5,
                default = 40
            },
            jadeSerpentMode = {
                displayName = "Jade Serpent Usage",
                description = "When to use Yu'lon or Chi-Ji",
                type = "dropdown",
                options = {"On Cooldown", "With Essence Font", "Emergency Only"},
                default = "With Essence Font"
            },
            useManaTea = {
                displayName = "Use Mana Tea",
                description = "Use Mana Tea when mana is low",
                type = "toggle",
                default = true
            },
            manaTeaThreshold = {
                displayName = "Mana Tea Threshold",
                description = "Mana percentage to use Mana Tea",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            }
        },
        windwalkerSettings = {
            useInvokeXuen = {
                displayName = "Use Invoke Xuen",
                description = "Use Invoke Xuen, the White Tiger on cooldown",
                type = "toggle",
                default = true
            },
            useTouchOfDeath = {
                displayName = "Use Touch of Death",
                description = "Use Touch of Death on cooldown",
                type = "toggle",
                default = true
            },
            useTouchOfKarma = {
                displayName = "Use Touch of Karma",
                description = "Use Touch of Karma at low health",
                type = "toggle",
                default = true
            },
            touchOfKarmaThreshold = {
                displayName = "Touch of Karma Health Threshold",
                description = "Health percentage to use Touch of Karma",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 60
            },
            useSerenity = {
                displayName = "Use Serenity",
                description = "Use Serenity on cooldown if talented",
                type = "toggle",
                default = true
            },
            useStormEarthFire = {
                displayName = "Use Storm, Earth and Fire",
                description = "Use Storm, Earth and Fire on cooldown if talented",
                type = "toggle",
                default = true
            },
            comboStrikeTracking = {
                displayName = "Track Combo Strikes",
                description = "Prioritize abilities to maintain Hit Combo",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Monk", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function MonkModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
end

-- Register events
function MonkModule:RegisterEvents()
    -- Register for specialization changed event
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for entering combat event
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        inCombat = true
    end)
    
    -- Register for leaving combat event
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        inCombat = false
    end)
    
    -- Update specialization on initialization
    self:OnSpecializationChanged()
end

-- On specialization changed
function MonkModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Monk specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_BREWMASTER then
        self:RegisterBrewmasterRotation()
    elseif playerSpec == SPEC_MISTWEAVER then
        self:RegisterMistweaverRotation()
    elseif playerSpec == SPEC_WINDWALKER then
        self:RegisterWindwalkerRotation()
    end
end

-- Register rotations
function MonkModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterBrewmasterRotation()
    self:RegisterMistweaverRotation()
    self:RegisterWindwalkerRotation()
end

-- Register Brewmaster rotation
function MonkModule:RegisterBrewmasterRotation()
    RotationManager:RegisterRotation("MonkBrewmaster", {
        id = "MonkBrewmaster",
        name = "Monk - Brewmaster",
        class = "MONK",
        spec = SPEC_BREWMASTER,
        level = 10,
        description = "Brewmaster Monk rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:BrewmasterRotation()
        end
    })
end

-- Register Mistweaver rotation
function MonkModule:RegisterMistweaverRotation()
    RotationManager:RegisterRotation("MonkMistweaver", {
        id = "MonkMistweaver",
        name = "Monk - Mistweaver",
        class = "MONK",
        spec = SPEC_MISTWEAVER,
        level = 10,
        description = "Mistweaver Monk rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:MistweaverRotation()
        end
    })
end

-- Register Windwalker rotation
function MonkModule:RegisterWindwalkerRotation()
    RotationManager:RegisterRotation("MonkWindwalker", {
        id = "MonkWindwalker",
        name = "Monk - Windwalker",
        class = "MONK",
        spec = SPEC_WINDWALKER,
        level = 10,
        description = "Windwalker Monk rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:WindwalkerRotation()
        end
    })
end

-- Brewmaster rotation
function MonkModule:BrewmasterRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Monk")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local energy = API.GetUnitPower(player, Enum.PowerType.Energy)
    local chi = API.GetUnitPower(player, Enum.PowerType.Chi)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.brewmasterSettings.aoeThreshold <= enemies
    local hasBlackoutCombo = API.UnitHasBuff(player, BUFFS.BLACKOUT_COMBO)
    local hasFortifyingBrew = API.UnitHasBuff(player, BUFFS.FORTIFYING_BREW)
    local hasCelestialBrew = API.UnitHasBuff(player, BUFFS.CELESTIAL_BREW)
    local hasPurifiedChi = API.UnitHasBuff(player, BUFFS.PURIFIED_CHI)
    local hasRushingJadeWind = API.UnitHasBuff(player, BUFFS.RUSHING_JADE_WIND)
    local hasZenMeditation = API.UnitHasBuff(player, BUFFS.ZEN_MEDITATION)
    local targetHasKegSmash = API.UnitHasDebuff(target, DEBUFFS.KEG_SMASH)
    local targetHasBreathOfFire = API.UnitHasDebuff(target, DEBUFFS.BREATH_OF_FIRE)
    
    -- Get stagger level
    local staggerLight, staggerModerate, staggerHeavy = API.GetStaggerLevel(player)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(BREWMASTER_SPELLS.SPEAR_HAND_STRIKE) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.SPEAR_HAND_STRIKE) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.SPEAR_HAND_STRIKE,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Purifying Brew based on stagger level
        if API.IsSpellKnown(BREWMASTER_SPELLS.PURIFYING_BREW) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.PURIFYING_BREW) then
            local shouldPurify = false
            
            if settings.brewmasterSettings.purifyingBrewMode == "Heavy Stagger Only" then
                shouldPurify = staggerHeavy
            elseif settings.brewmasterSettings.purifyingBrewMode == "Moderate+ Stagger" then
                shouldPurify = staggerHeavy or staggerModerate
            elseif settings.brewmasterSettings.purifyingBrewMode == "Any Stagger" then
                shouldPurify = staggerHeavy or staggerModerate or staggerLight
            end
            
            if shouldPurify then
                return {
                    type = "spell",
                    id = BREWMASTER_SPELLS.PURIFYING_BREW,
                    target = player
                }
            end
        end
        
        -- Celestial Brew for shielding
        if healthPercent <= settings.brewmasterSettings.celestialBrewThreshold and
           API.IsSpellKnown(BREWMASTER_SPELLS.CELESTIAL_BREW) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.CELESTIAL_BREW) then
            return {
                type = "spell",
                id = BREWMASTER_SPELLS.CELESTIAL_BREW,
                target = player
            }
        end
        
        -- Fortifying Brew at low health
        if settings.brewmasterSettings.useFortifyingBrew and
           healthPercent <= settings.brewmasterSettings.fortifyingBrewThreshold and
           API.IsSpellKnown(BREWMASTER_SPELLS.FORTIFYING_BREW) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.FORTIFYING_BREW) then
            return {
                type = "spell",
                id = BREWMASTER_SPELLS.FORTIFYING_BREW,
                target = player
            }
        end
        
        -- Zen Meditation during heavy damage periods
        if settings.brewmasterSettings.useZenMeditation and
           healthPercent < 50 and
           API.IsSpellKnown(BREWMASTER_SPELLS.ZEN_MEDITATION) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.ZEN_MEDITATION) then
            return {
                type = "spell",
                id = BREWMASTER_SPELLS.ZEN_MEDITATION,
                target = player
            }
        end
        
        -- Expel Harm at low health
        if healthPercent < 70 and
           API.IsSpellKnown(BREWMASTER_SPELLS.EXPEL_HARM) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.EXPEL_HARM) and
           energy >= 15 then
            return {
                type = "spell",
                id = BREWMASTER_SPELLS.EXPEL_HARM,
                target = player
            }
        end
        
        -- Guard if talented
        if healthPercent < 80 and
           API.IsSpellKnown(BREWMASTER_SPELLS.GUARD) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.GUARD) then
            return {
                type = "spell",
                id = BREWMASTER_SPELLS.GUARD,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Invoke Niuzao
        if settings.brewmasterSettings.useNiuzao and
           API.IsSpellKnown(BREWMASTER_SPELLS.INVOKE_NIUZAO_THE_BLACK_OX) and 
           API.IsSpellUsable(BREWMASTER_SPELLS.INVOKE_NIUZAO_THE_BLACK_OX) then
            return {
                type = "spell",
                id = BREWMASTER_SPELLS.INVOKE_NIUZAO_THE_BLACK_OX,
                target = player
            }
        end
    end
    
    -- Core rotation
    -- Keg Smash on cooldown if prioritized
    if settings.brewmasterSettings.kegSmashPriority and
       API.IsSpellKnown(BREWMASTER_SPELLS.KEG_SMASH) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.KEG_SMASH) and
       energy >= 40 then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.KEG_SMASH,
            target = target
        }
    end
    
    -- Blackout Kick with Blackout Combo
    if hasBlackoutCombo and
       API.IsSpellKnown(BREWMASTER_SPELLS.BLACKOUT_KICK) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.BLACKOUT_KICK) and
       energy >= 25 then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.BLACKOUT_KICK,
            target = target
        }
    end
    
    -- Breath of Fire if Keg Smash is applied
    if targetHasKegSmash and
       API.IsSpellKnown(BREWMASTER_SPELLS.BREATH_OF_FIRE) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.BREATH_OF_FIRE) and
       energy >= 30 then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.BREATH_OF_FIRE,
            target = target
        }
    end
    
    -- Rushing Jade Wind for AoE
    if aoeEnabled and
       API.IsSpellKnown(BREWMASTER_SPELLS.RUSHING_JADE_WIND) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.RUSHING_JADE_WIND) and
       not hasRushingJadeWind and
       energy >= 25 then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.RUSHING_JADE_WIND,
            target = player
        }
    end
    
    -- Chi Wave or Chi Burst if talented
    if API.IsSpellKnown(BREWMASTER_SPELLS.CHI_WAVE) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.CHI_WAVE) then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.CHI_WAVE,
            target = target
        }
    end
    
    if API.IsSpellKnown(BREWMASTER_SPELLS.CHI_BURST) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.CHI_BURST) then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.CHI_BURST,
            target = target
        }
    end
    
    -- Keg Smash if not prioritized earlier
    if not settings.brewmasterSettings.kegSmashPriority and
       API.IsSpellKnown(BREWMASTER_SPELLS.KEG_SMASH) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.KEG_SMASH) and
       energy >= 40 then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.KEG_SMASH,
            target = target
        }
    end
    
    -- Blackout Kick
    if API.IsSpellKnown(BREWMASTER_SPELLS.BLACKOUT_KICK) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.BLACKOUT_KICK) and
       energy >= 25 then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.BLACKOUT_KICK,
            target = target
        }
    end
    
    -- Tiger Palm filler
    if energy >= 50 and
       API.IsSpellKnown(BREWMASTER_SPELLS.TIGER_PALM) and 
       API.IsSpellUsable(BREWMASTER_SPELLS.TIGER_PALM) then
        return {
            type = "spell",
            id = BREWMASTER_SPELLS.TIGER_PALM,
            target = target
        }
    end
    
    return nil
end

-- Mistweaver rotation
function MonkModule:MistweaverRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    local lowestAlly = self:GetLowestHealthAlly()
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Monk")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local injuredAllies = self:GetInjuredAlliesCount(80)
    local averageGroupHealth = self:GetAverageGroupHealth()
    
    -- Target specific variables
    local lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = 100, 100, 100
    
    if lowestAlly and UnitExists(lowestAlly) then
        lowestAllyHealth, lowestAllyMaxHealth, lowestAllyHealthPercent = API.GetUnitHealth(lowestAlly)
    end
    
    -- Buff tracking
    local hasSoothingMist = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.SOOTHING_MIST)
    local hasEnvelopingMist = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.ENVELOPING_MIST)
    local hasRenewingMist = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.RENEWING_MIST)
    local hasLifeCocoon = lowestAlly and API.UnitHasBuff(lowestAlly, BUFFS.LIFE_COCOON)
    local hasThunderFocusTea = API.UnitHasBuff(player, BUFFS.THUNDER_FOCUS_TEA)
    local hasManaTea = API.UnitHasBuff(player, BUFFS.MANA_TEA)
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(MISTWEAVER_SPELLS.SPEAR_HAND_STRIKE) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.SPEAR_HAND_STRIKE) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.SPEAR_HAND_STRIKE,
            target = target
        }
    end
    
    -- Dispel harmful magic/poison effects
    if settings.generalSettings.useDetox and
       API.IsSpellKnown(MISTWEAVER_SPELLS.DETOX) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.DETOX) and
       API.HasDispellableDebuff(lowestAlly or player, "Magic", "Poison") then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.DETOX,
            target = lowestAlly or player
        }
    end
    
    -- Emergency cooldowns
    -- Revival for group healing
    if settings.mistWeaverSettings.useRevival and
       averageGroupHealth <= settings.mistWeaverSettings.revivalThreshold and
       API.IsSpellKnown(MISTWEAVER_SPELLS.REVIVAL) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.REVIVAL) then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.REVIVAL,
            target = player
        }
    end
    
    -- Life Cocoon for critical target
    if settings.mistWeaverSettings.useLifeCocoon and
       lowestAlly and lowestAllyHealthPercent <= settings.mistWeaverSettings.lifeCocooonThreshold and
       API.IsSpellKnown(MISTWEAVER_SPELLS.LIFE_COCOON) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.LIFE_COCOON) then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.LIFE_COCOON,
            target = lowestAlly
        }
    end
    
    -- Group healing with Essence Font
    if settings.mistWeaverSettings.useEssenceFont and
       injuredAllies >= settings.mistWeaverSettings.essenceFontThreshold and
       API.IsSpellKnown(MISTWEAVER_SPELLS.ESSENCE_FONT) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.ESSENCE_FONT) then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.ESSENCE_FONT,
            target = player
        }
    end
    
    -- Invoke Yu'lon or Chi-Ji based on settings
    if API.IsSpellKnown(MISTWEAVER_SPELLS.INVOKE_YULON_THE_JADE_SERPENT) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.INVOKE_YULON_THE_JADE_SERPENT) then
        local useCelestial = false
        
        if settings.mistWeaverSettings.jadeSerpentMode == "On Cooldown" then
            useCelestial = true
        elseif settings.mistWeaverSettings.jadeSerpentMode == "With Essence Font" then
            useCelestial = injuredAllies >= settings.mistWeaverSettings.essenceFontThreshold
        elseif settings.mistWeaverSettings.jadeSerpentMode == "Emergency Only" then
            useCelestial = averageGroupHealth <= 50
        end
        
        if useCelestial then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.INVOKE_YULON_THE_JADE_SERPENT,
                target = player
            }
        end
    end
    
    if API.IsSpellKnown(MISTWEAVER_SPELLS.INVOKE_CHI_JI_THE_RED_CRANE) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.INVOKE_CHI_JI_THE_RED_CRANE) then
        local useCelestial = false
        
        if settings.mistWeaverSettings.jadeSerpentMode == "On Cooldown" then
            useCelestial = true
        elseif settings.mistWeaverSettings.jadeSerpentMode == "With Essence Font" then
            useCelestial = injuredAllies >= settings.mistWeaverSettings.essenceFontThreshold
        elseif settings.mistWeaverSettings.jadeSerpentMode == "Emergency Only" then
            useCelestial = averageGroupHealth <= 50
        end
        
        if useCelestial then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.INVOKE_CHI_JI_THE_RED_CRANE,
                target = player
            }
        end
    end
    
    -- Mana Tea when mana is low
    if settings.mistWeaverSettings.useManaTea and
       manaPercent <= settings.mistWeaverSettings.manaTeaThreshold and
       API.IsSpellKnown(MISTWEAVER_SPELLS.MANA_TEA) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.MANA_TEA) then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.MANA_TEA,
            target = player
        }
    end
    
    -- Thunder Focus Tea
    if API.IsSpellKnown(MISTWEAVER_SPELLS.THUNDER_FOCUS_TEA) and 
       API.IsSpellUsable(MISTWEAVER_SPELLS.THUNDER_FOCUS_TEA) and
       lowestAllyHealthPercent < 70 then
        return {
            type = "spell",
            id = MISTWEAVER_SPELLS.THUNDER_FOCUS_TEA,
            target = player
        }
    end
    
    -- Single target healing
    if lowestAlly then
        -- Renewing Mist on cooldown
        if not hasRenewingMist and
           API.IsSpellKnown(MISTWEAVER_SPELLS.RENEWING_MIST) and 
           API.IsSpellUsable(MISTWEAVER_SPELLS.RENEWING_MIST) then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.RENEWING_MIST,
                target = lowestAlly
            }
        end
        
        -- Start Soothing Mist channel
        if settings.mistWeaverSettings.useSoothingMist and
           not hasSoothingMist and
           lowestAllyHealthPercent < 85 and
           API.IsSpellKnown(MISTWEAVER_SPELLS.SOOTHING_MIST) and 
           API.IsSpellUsable(MISTWEAVER_SPELLS.SOOTHING_MIST) then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.SOOTHING_MIST,
                target = lowestAlly
            }
        end
        
        -- Enveloping Mist with Thunder Focus Tea or on low health
        if (hasThunderFocusTea or lowestAllyHealthPercent <= settings.mistWeaverSettings.envelopingMistThreshold) and
           not hasEnvelopingMist and
           API.IsSpellKnown(MISTWEAVER_SPELLS.ENVELOPING_MIST) and 
           API.IsSpellUsable(MISTWEAVER_SPELLS.ENVELOPING_MIST) then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.ENVELOPING_MIST,
                target = lowestAlly
            }
        end
        
        -- Vivify for moderate healing
        if lowestAllyHealthPercent < 75 and
           API.IsSpellKnown(MISTWEAVER_SPELLS.VIVIFY) and 
           API.IsSpellUsable(MISTWEAVER_SPELLS.VIVIFY) then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.VIVIFY,
                target = lowestAlly
            }
        end
    end
    
    -- DPS abilities when healing is not required
    if UnitExists(target) and UnitCanAttack(player, target) and not UnitIsDead(target) and averageGroupHealth > 85 then
        -- Rising Sun Kick
        if API.IsSpellKnown(MISTWEAVER_SPELLS.RISING_SUN_KICK) and 
           API.IsSpellUsable(MISTWEAVER_SPELLS.RISING_SUN_KICK) then
            return {
                type = "spell",
                id = MISTWEAVER_SPELLS.RISING_SUN_KICK,
                target = target
            }
        end
        
        -- Tiger Palm
        if API.IsSpellKnown(WINDWALKER_SPELLS.TIGER_PALM) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.TIGER_PALM) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.TIGER_PALM,
                target = target
            }
        end
    end
    
    return nil
end

-- Windwalker rotation
function MonkModule:WindwalkerRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Monk")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local energy = API.GetUnitPower(player, Enum.PowerType.Energy)
    local chi = API.GetUnitPower(player, Enum.PowerType.Chi)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.windwalkerSettings.aoeThreshold <= enemies
    
    -- Buff tracking
    local lastUsedAbility = self:GetLastUsedAbility()
    local hasStormEarthFire = API.UnitHasBuff(player, BUFFS.STORM_EARTH_AND_FIRE)
    local hasSerenity = API.UnitHasBuff(player, BUFFS.SERENITY)
    local hasTouchOfKarma = API.UnitHasBuff(player, BUFFS.TOUCH_OF_KARMA)
    local hasDanceOfChiJi = API.UnitHasBuff(player, BUFFS.DANCE_OF_CHI_JI)
    local hitComboStacks = 0
    
    if settings.windwalkerSettings.comboStrikeTracking and API.IsSpellKnown(WINDWALKER_SPELLS.HIT_COMBO) then
        hitComboStacks = API.GetBuffStacks(player, BUFFS.HIT_COMBO)
    end
    
    -- Interrupt if needed
    if settings.generalSettings.useInterrupts and
       API.IsSpellKnown(WINDWALKER_SPELLS.SPEAR_HAND_STRIKE) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.SPEAR_HAND_STRIKE) and
       API.ShouldInterrupt(target) then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.SPEAR_HAND_STRIKE,
            target = target
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Touch of Karma for defense
        if settings.windwalkerSettings.useTouchOfKarma and
           healthPercent <= settings.windwalkerSettings.touchOfKarmaThreshold and
           API.IsSpellKnown(WINDWALKER_SPELLS.TOUCH_OF_KARMA) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.TOUCH_OF_KARMA) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.TOUCH_OF_KARMA,
                target = target
            }
        end
        
        -- Fortifying Brew at low health
        if healthPercent < 40 and
           API.IsSpellKnown(WINDWALKER_SPELLS.FORTIFYING_BREW) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.FORTIFYING_BREW) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.FORTIFYING_BREW,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Invoke Xuen
        if settings.windwalkerSettings.useInvokeXuen and
           API.IsSpellKnown(WINDWALKER_SPELLS.INVOKE_XUEN_THE_WHITE_TIGER) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.INVOKE_XUEN_THE_WHITE_TIGER) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.INVOKE_XUEN_THE_WHITE_TIGER,
                target = player
            }
        end
        
        -- Serenity 
        if settings.windwalkerSettings.useSerenity and
           not hasStormEarthFire and
           API.IsSpellKnown(WINDWALKER_SPELLS.SERENITY) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.SERENITY) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.SERENITY,
                target = player
            }
        end
        
        -- Storm, Earth, and Fire
        if settings.windwalkerSettings.useStormEarthFire and
           not hasSerenity and not hasStormEarthFire and
           API.IsSpellKnown(WINDWALKER_SPELLS.STORM_EARTH_AND_FIRE) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.STORM_EARTH_AND_FIRE) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.STORM_EARTH_AND_FIRE,
                target = player
            }
        end
        
        -- Touch of Death
        if settings.windwalkerSettings.useTouchOfDeath and
           API.IsSpellKnown(WINDWALKER_SPELLS.TOUCH_OF_DEATH) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.TOUCH_OF_DEATH) then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.TOUCH_OF_DEATH,
                target = target
            }
        end
    end
    
    -- Core rotation considering Combo Strikes
    
    -- Whirling Dragon Punch if available
    if API.IsSpellKnown(WINDWALKER_SPELLS.WHIRLING_DRAGON_PUNCH) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.WHIRLING_DRAGON_PUNCH) and
       lastUsedAbility ~= WINDWALKER_SPELLS.WHIRLING_DRAGON_PUNCH then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.WHIRLING_DRAGON_PUNCH,
            target = target
        }
    end
    
    -- AoE rotation
    if aoeEnabled then
        -- Spinning Crane Kick with Dance of Chi-Ji
        if hasDanceOfChiJi and
           API.IsSpellKnown(WINDWALKER_SPELLS.SPINNING_CRANE_KICK) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.SPINNING_CRANE_KICK) and
           chi >= 2 and
           lastUsedAbility ~= WINDWALKER_SPELLS.SPINNING_CRANE_KICK then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.SPINNING_CRANE_KICK,
                target = player
            }
        end
        
        -- Rushing Jade Wind if talented
        if API.IsSpellKnown(WINDWALKER_SPELLS.RUSHING_JADE_WIND) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.RUSHING_JADE_WIND) and
           chi >= 1 and
           lastUsedAbility ~= WINDWALKER_SPELLS.RUSHING_JADE_WIND then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.RUSHING_JADE_WIND,
                target = player
            }
        end
        
        -- Spinning Crane Kick for AoE
        if enemies >= 3 and
           API.IsSpellKnown(WINDWALKER_SPELLS.SPINNING_CRANE_KICK) and 
           API.IsSpellUsable(WINDWALKER_SPELLS.SPINNING_CRANE_KICK) and
           chi >= 2 and
           lastUsedAbility ~= WINDWALKER_SPELLS.SPINNING_CRANE_KICK then
            return {
                type = "spell",
                id = WINDWALKER_SPELLS.SPINNING_CRANE_KICK,
                target = player
            }
        end
    end
    
    -- Fists of Fury
    if API.IsSpellKnown(WINDWALKER_SPELLS.FISTS_OF_FURY) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.FISTS_OF_FURY) and
       chi >= 3 and
       lastUsedAbility ~= WINDWALKER_SPELLS.FISTS_OF_FURY then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.FISTS_OF_FURY,
            target = target
        }
    end
    
    -- Rising Sun Kick
    if API.IsSpellKnown(WINDWALKER_SPELLS.RISING_SUN_KICK) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.RISING_SUN_KICK) and
       chi >= 2 and
       lastUsedAbility ~= WINDWALKER_SPELLS.RISING_SUN_KICK then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.RISING_SUN_KICK,
            target = target
        }
    end
    
    -- Fist of the White Tiger if talented
    if API.IsSpellKnown(WINDWALKER_SPELLS.FIST_OF_THE_WHITE_TIGER) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.FIST_OF_THE_WHITE_TIGER) and
       chi <= 3 and
       energy >= 40 and
       lastUsedAbility ~= WINDWALKER_SPELLS.FIST_OF_THE_WHITE_TIGER then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.FIST_OF_THE_WHITE_TIGER,
            target = target
        }
    end
    
    -- Chi Wave or Chi Burst if talented
    if API.IsSpellKnown(WINDWALKER_SPELLS.CHI_WAVE) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.CHI_WAVE) and
       lastUsedAbility ~= WINDWALKER_SPELLS.CHI_WAVE then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.CHI_WAVE,
            target = target
        }
    end
    
    if API.IsSpellKnown(WINDWALKER_SPELLS.CHI_BURST) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.CHI_BURST) and
       lastUsedAbility ~= WINDWALKER_SPELLS.CHI_BURST then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.CHI_BURST,
            target = player
        }
    end
    
    -- Blackout Kick with procs
    if API.IsSpellKnown(WINDWALKER_SPELLS.BLACKOUT_KICK) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.BLACKOUT_KICK) and
       chi >= 1 and
       lastUsedAbility ~= WINDWALKER_SPELLS.BLACKOUT_KICK then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.BLACKOUT_KICK,
            target = target
        }
    end
    
    -- Tiger Palm as filler
    if API.IsSpellKnown(WINDWALKER_SPELLS.TIGER_PALM) and 
       API.IsSpellUsable(WINDWALKER_SPELLS.TIGER_PALM) and
       chi <= 4 and
       energy >= 50 and
       lastUsedAbility ~= WINDWALKER_SPELLS.TIGER_PALM then
        return {
            type = "spell",
            id = WINDWALKER_SPELLS.TIGER_PALM,
            target = target
        }
    end
    
    return nil
end

-- Get lowest health ally
function MonkModule:GetLowestHealthAlly()
    local lowestUnit = nil
    local lowestHealth = 100
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < lowestHealth then
                lowestHealth = healthPercent
                lowestUnit = unit
            end
        end
    end
    
    -- Check player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    if playerHealthPercent < lowestHealth then
        lowestHealth = playerHealthPercent
        lowestUnit = "player"
    end
    
    return lowestUnit
end

-- Get injured allies count
function MonkModule:GetInjuredAlliesCount(threshold)
    local count = 0
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < threshold then
                count = count + 1
            end
        end
    end
    
    -- Include player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    if playerHealthPercent < threshold then
        count = count + 1
    end
    
    return count
end

-- Get average group health
function MonkModule:GetAverageGroupHealth()
    local totalHealth = 0
    local count = 0
    
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDead(unit) then
            local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
            totalHealth = totalHealth + healthPercent
            count = count + 1
        end
    end
    
    -- Include player
    local playerHealth, playerMaxHealth, playerHealthPercent = API.GetUnitHealth("player")
    totalHealth = totalHealth + playerHealthPercent
    count = count + 1
    
    return count > 0 and (totalHealth / count) or 100
end

-- Get stagger level
function API.GetStaggerLevel(unit)
    -- Try to use Tinkr's API if available
    if API.IsTinkrLoaded() and Tinkr.Unit and Tinkr.Unit[unit] then
        -- Assuming Tinkr has some stagger APIs
        return Tinkr.Unit[unit]:HasStaggerState("light"), 
               Tinkr.Unit[unit]:HasStaggerState("moderate"), 
               Tinkr.Unit[unit]:HasStaggerState("heavy")
    end
    
    -- Fallback using WoW API
    local light = UnitDebuff(unit, "Light Stagger")
    local moderate = UnitDebuff(unit, "Moderate Stagger")
    local heavy = UnitDebuff(unit, "Heavy Stagger")
    
    return light ~= nil, moderate ~= nil, heavy ~= nil
end

-- Check for dispellable debuffs
function API.HasDispellableDebuff(unit, ...)
    local debuffTypes = {...}
    
    -- Basic implementation - this would be expanded in a real addon
    for i = 1, 40 do
        local name, _, _, debuffType, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        if name and debuffType then
            for _, type in ipairs(debuffTypes) do
                if type == debuffType then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Get the last used ability for Combo Strikes
function MonkModule:GetLastUsedAbility()
    -- In a real implementation, this would track actual last used ability
    -- For our mock implementation, we'll return 0, which won't match any spell ID
    return 0
end

-- Should execute rotation
function MonkModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "MONK" then
        return false
    end
    
    return true
end

-- Register for export
WR.Monk = MonkModule

return MonkModule