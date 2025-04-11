------------------------------------------
-- WindrunnerRotations - Balance Druid Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Balance = {}
-- This will be assigned to addon.Classes.Druid.Balance when loaded

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
local currentAstralPower = 0
local maxAstralPower = 100
local eclipseActive = false
local eclipseSolar = false
local eclipseLunar = false
local eclipseEndTime = 0
local incarnationActive = false
local incarnationEndTime = 0
local celestialAlignmentActive = false
local celestialAlignmentEndTime = 0
local starfallActive = false
local starfallEndTime = 0
local starlordActive = false
local starlordStacks = 0
local starlordEndTime = 0
local onethsActive = false
local onethsEndTime = 0
local onethsClearcastingActive = false
local onethsPercProc = false
local moonkinFormActive = false
local sunfireActive = {}
local sunfireEndTime = {}
local moonfireActive = {}
local moonfireEndTime = {}
local stellarFlareActive = {}
local stellarFlareEndTime = {}
local starSurgeCount = 0
local starsurgeAstralSpender = true
local furyOfElune = false
local furyOfEluneActive = false
local furyOfEluneEndTime = 0
local convokeCooldown = false
local fullMoonCount = 0
local forceOfNature = false
local treeOfLifeFormActive = false
local powerInfusionActive = false
local powerInfusionEndTime = 0
local shiftPowerActive = false
local shiftPowerEndTime = 0
local shiftPowerDuration = 0
local sunKingBlessingEndTime = 0
local sunKingBlessingActive = false
local oneWithNatureActive = false
local oneWithNatureEndTime = 0
local oneWithNatureStacks = 0
local umbralIntensity = false
local umbralIntensityStacks = 0
local umbralIntensityEndTime = 0
local solstice = false
local solsticeStacks = 0
local solsticeEndTime = 0
local touchOfElune = false
local touchOfEluneStacks = 0
local touchOfEluneEndTime = 0
local frenziedRegen = false
local frenziedRegenActive = false
local frenziedRegenEndTime = 0
local inRange = false
local isMoving = false
local starsurge = false
local starfire = false
local wrath = false
local sunfire = false
local moonfire = false
local stellarFlare = false
local starfall = false
local newMoon = false
local halfMoon = false
local fullMoon = false
local shootingStars = false
local celestialAlignment = false
local incarnationChosen = false
local balanceOfAll = false
local solarbeam = false
local natures_wrath = false
local twin_moons = false
local stellarDrift = false
local soul_of_the_forest = false
local starlord = false
local stellar_inspiration = false
local natures_balance = false
local astral_communion = false
local force_of_nature = false
local warrior_of_elune = false
local oneths_clear_vision = false
local oneths_perception = false
local power_of_goldrinn = false
local primordial_arcanic_pulsar = false
local orbital_strike = false
local starweavers_weft = false
local tireless_pursuit = false
local starfall_eclipse = false
local convoke_the_spirits = false
local well_honed_instincts = false
local killer_instinct = false
local elunes_guidance = false
local orbit_breaker = false
local denizen_of_the_dream = false
local fury_of_elune = false
local balance_of_all_things = false
local radiant_moonlight = false
local arcanic_pulsar = false
local solstice_alignment = false
local touch_the_cosmos = false
local inMeleeRange = false
local playerHealth = 100

-- Constants
local BALANCE_SPEC_ID = 102
local DEFAULT_AOE_THRESHOLD = 3
local ECLIPSE_DURATION = 15 -- seconds
local INCARNATION_DURATION = 30 -- seconds
local CELESTIAL_ALIGNMENT_DURATION = 20 -- seconds
local STARFALL_DURATION = 8 -- seconds
local STARLORD_DURATION = 15 -- seconds (base)
local ONETHS_DURATION = 12 -- seconds
local SUNFIRE_DURATION = 18 -- seconds (base)
local MOONFIRE_DURATION = 22 -- seconds (base)
local STELLAR_FLARE_DURATION = 24 -- seconds (base)
local POWER_INFUSION_DURATION = 20 -- seconds
local FURY_OF_ELUNE_DURATION = 8 -- seconds
local FRENZIED_REGEN_DURATION = 8 -- seconds
local MELEE_RANGE = 5 -- yards
local STARFIRE_RANGE = 40 -- yards
local MAX_ASTRAL_POWER = 100

-- Initialize the Balance module
function Balance:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Balance Druid module initialized")
    
    return true
end

-- Register spell IDs
function Balance:RegisterSpells()
    -- Core rotational abilities
    spells.WRATH = 190984
    spells.STARFIRE = 194153
    spells.MOONFIRE = 8921
    spells.SUNFIRE = 93402
    spells.STARSURGE = 78674
    spells.STARFALL = 191034
    spells.STELLAR_FLARE = 202347
    spells.NEW_MOON = 274281
    spells.HALF_MOON = 274282
    spells.FULL_MOON = 274283
    spells.FURY_OF_ELUNE = 202770
    spells.FORCE_OF_NATURE = 205636
    spells.CELESTIAL_ALIGNMENT = 194223
    spells.INCARNATION_CHOSEN_OF_ELUNE = 102560
    spells.WARRIOR_OF_ELUNE = 202425
    spells.CONVOKE_THE_SPIRITS = 323764
    
    -- Core utilities
    spells.MOONKIN_FORM = 24858
    spells.TRAVEL_FORM = 783
    spells.CAT_FORM = 768
    spells.BEAR_FORM = 5487
    spells.DASH = 1850
    spells.STAMPEDING_ROAR = 106898
    spells.WILD_CHARGE = 102401
    spells.TYPHOON = 132469
    spells.URSOLS_VORTEX = 102793
    spells.MIGHTY_BASH = 5211
    spells.ENTANGLING_ROOTS = 339
    spells.HIBERNATE = 2637
    spells.CYCLONE = 33786
    spells.REBIRTH = 20484
    spells.REMOVE_CORRUPTION = 2782
    spells.NATURES_CURE = 88423
    spells.BARKSKIN = 22812
    spells.INNERVATE = 29166
    spells.RENEWAL = 108238
    spells.MASS_ENTANGLEMENT = 102359
    spells.SOLAR_BEAM = 78675
    
    -- Core defensives and healing
    spells.REGROWTH = 8936
    spells.SWIFTMEND = 18562
    spells.FRENZIED_REGENERATION = 22842
    spells.NATURE_SPELLS = 16886
    
    -- Talents and passives
    spells.ECLIPSE = 79577
    spells.ECLIPSE_SOLAR = 48517
    spells.ECLIPSE_LUNAR = 48518
    spells.ASTRAL_COMMUNION = 202359
    spells.STARLORD = 202345
    spells.STELLAR_DRIFT = 202354
    spells.SHOOTING_STARS = 202342
    spells.SOUL_OF_THE_FOREST = 114107
    spells.STELLAR_INSPIRATION = 384922
    spells.NATURES_BALANCE = 202430
    spells.TWIN_MOONS = 279620
    spells.BALANCE_OF_ALL_THINGS = 339942
    spells.ORBITAL_STRIKE = 390378
    spells.STARWEAVERS_WEFT = 393940
    spells.TIRELESS_PURSUIT = 377801
    spells.WELL_HONED_INSTINCTS = 377847
    spells.KILLER_INSTINCT = 108299
    spells.ELUNES_GUIDANCE = 393991
    spells.ORBIT_BREAKER = 383197
    spells.POWER_OF_GOLDRINN = 394046
    spells.ONETHS_CLEAR_VISION = 390348
    spells.ONETHS_PERCEPTION = 394103
    spells.PRIMORDIAL_ARCANIC_PULSAR = 384276
    spells.DENIZEN_OF_THE_DREAM = 394048
    spells.RADIANT_MOONLIGHT = 394121
    spells.SOLSTICE_ALIGNMENT = 394115
    spells.TOUCH_THE_COSMOS = 394414
    
    -- War Within Season 2 specific
    spells.IMPROVED_STARFALL = 393944
    spells.ARCANIC_PULSAR = 393960
    spells.ASTRAL_SMOLDER = 394058
    spells.CONVOKING_STARS = 391951
    spells.COSMIC_RAPIDITY = 395526
    spells.FUNGAL_GROWTH = 81281
    spells.GALACTIC_GUARDIAN = 390378
    spells.GERMINATION = 155675
    spells.HEART_OF_THE_WILD = 319454
    spells.IMPROVED_SOLAR_BEAM = 328778
    spells.INCESSANT_TEMPEST = 387273
    spells.ONE_WITH_NATURE = 393371
    spells.PROTECTOR_OF_THE_PACK = 378986
    spells.UMBRAL_INTENSITY = 383192
    
    -- Buff IDs
    spells.MOONKIN_FORM_BUFF = 24858
    spells.STARLORD_BUFF = 279709
    spells.ONETHS_CLEAR_VISION_BUFF = 390354
    spells.ONETHS_PERCEPTION_BUFF = 394106
    spells.POWER_OF_GOLDRINN_BUFF = 394049
    spells.ECLIPSE_SOLAR_BUFF = 48517
    spells.ECLIPSE_LUNAR_BUFF = 48518
    spells.INCARNATION_CHOSEN_OF_ELUNE_BUFF = 102560
    spells.CELESTIAL_ALIGNMENT_BUFF = 194223
    spells.WARRIOR_OF_ELUNE_BUFF = 202425
    spells.STARFALL_BUFF = 191034
    spells.ONE_WITH_NATURE_BUFF = 393372
    spells.UMBRAL_INTENSITY_BUFF = 393944
    spells.SOLSTICE_BUFF = 343648
    spells.TOUCH_OF_ELUNE_BUFF = 394414
    spells.FRENZIED_REGENERATION_BUFF = 22842
    
    -- Debuff IDs
    spells.MOONFIRE_DEBUFF = 164812
    spells.SUNFIRE_DEBUFF = 164815
    spells.STELLAR_FLARE_DEBUFF = 202347
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.MOONKIN_FORM = spells.MOONKIN_FORM_BUFF
    buffs.STARLORD = spells.STARLORD_BUFF
    buffs.ONETHS_CLEAR_VISION = spells.ONETHS_CLEAR_VISION_BUFF
    buffs.ONETHS_PERCEPTION = spells.ONETHS_PERCEPTION_BUFF
    buffs.POWER_OF_GOLDRINN = spells.POWER_OF_GOLDRINN_BUFF
    buffs.ECLIPSE_SOLAR = spells.ECLIPSE_SOLAR_BUFF
    buffs.ECLIPSE_LUNAR = spells.ECLIPSE_LUNAR_BUFF
    buffs.INCARNATION_CHOSEN_OF_ELUNE = spells.INCARNATION_CHOSEN_OF_ELUNE_BUFF
    buffs.CELESTIAL_ALIGNMENT = spells.CELESTIAL_ALIGNMENT_BUFF
    buffs.WARRIOR_OF_ELUNE = spells.WARRIOR_OF_ELUNE_BUFF
    buffs.STARFALL = spells.STARFALL_BUFF
    buffs.ONE_WITH_NATURE = spells.ONE_WITH_NATURE_BUFF
    buffs.UMBRAL_INTENSITY = spells.UMBRAL_INTENSITY_BUFF
    buffs.SOLSTICE = spells.SOLSTICE_BUFF
    buffs.TOUCH_OF_ELUNE = spells.TOUCH_OF_ELUNE_BUFF
    buffs.FRENZIED_REGENERATION = spells.FRENZIED_REGENERATION_BUFF
    
    debuffs.MOONFIRE = spells.MOONFIRE_DEBUFF
    debuffs.SUNFIRE = spells.SUNFIRE_DEBUFF
    debuffs.STELLAR_FLARE = spells.STELLAR_FLARE_DEBUFF
    
    return true
end

-- Register variables to track
function Balance:RegisterVariables()
    -- Talent tracking
    talents.hasEclipse = false
    talents.hasAstralCommunion = false
    talents.hasStarlord = false
    talents.hasStellarDrift = false
    talents.hasShootingStars = false
    talents.hasSoulOfTheForest = false
    talents.hasStellarInspiration = false
    talents.hasNaturesBalance = false
    talents.hasTwinMoons = false
    talents.hasBalanceOfAllThings = false
    talents.hasOrbitalStrike = false
    talents.hasStarweaversWeft = false
    talents.hasTirelessPursuit = false
    talents.hasWellHonedInstincts = false
    talents.hasKillerInstinct = false
    talents.hasElunesGuidance = false
    talents.hasOrbitBreaker = false
    talents.hasPowerOfGoldrinn = false
    talents.hasOnethsClearVision = false
    talents.hasOnethsPerception = false
    talents.hasPrimordialArcanicPulsar = false
    talents.hasDenizenOfTheDream = false
    talents.hasRadiantMoonlight = false
    talents.hasSolsticeAlignment = false
    talents.hasTouchTheCosmos = false
    talents.hasWarriorOfElune = false
    talents.hasForceOfNature = false
    talents.hasFuryOfElune = false
    talents.hasConvokeTheSpirits = false
    talents.hasIncarnationChosenOfElune = false
    talents.hasCelestialAlignment = false
    talents.hasStellarFlare = false
    talents.hasStarfall = false
    
    -- War Within Season 2 talents
    talents.hasImprovedStarfall = false
    talents.hasArcanicPulsar = false
    talents.hasAstralSmolder = false
    talents.hasConvokingStars = false
    talents.hasCosmicRapidity = false
    talents.hasFungalGrowth = false
    talents.hasGalacticGuardian = false
    talents.hasGermination = false
    talents.hasHeartOfTheWild = false
    talents.hasImprovedSolarBeam = false
    talents.hasIncessantTempest = false
    talents.hasOneWithNature = false
    talents.hasProtectorOfThePack = false
    talents.hasUmbralIntensity = false
    
    -- Initialize resources
    currentAstralPower = API.GetPlayerPower()
    
    -- Initialize DoT tracking
    sunfireActive = {}
    sunfireEndTime = {}
    moonfireActive = {}
    moonfireEndTime = {}
    stellarFlareActive = {}
    stellarFlareEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Balance:RegisterSettings()
    ConfigRegistry:RegisterSettings("BalanceDruid", {
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
            astralPowerPooling = {
                displayName = "Astral Power Pooling",
                description = "Pool Astral Power for important abilities",
                type = "toggle",
                default = true
            },
            astralPowerPoolingThreshold = {
                displayName = "Astral Power Pooling Threshold",
                description = "Minimum Astral Power to maintain",
                type = "slider",
                min = 20,
                max = 70,
                default = 50
            },
            dotRefreshPandemic = {
                displayName = "DoT Refresh Pandemic Window",
                description = "Refresh DoTs when time left is below Pandemic window",
                type = "toggle",
                default = true
            },
            useMoonkinForm = {
                displayName = "Use Moonkin Form",
                description = "Automatically use Moonkin Form",
                type = "toggle",
                default = true
            },
            eclipseStrategy = {
                displayName = "Eclipse Strategy",
                description = "How to optimize Eclipse uptime",
                type = "dropdown",
                options = {"Maximize Uptime", "Cycle Between Both", "Favor Lunar", "Favor Solar"},
                default = "Maximize Uptime"
            },
            useNewMoon = {
                displayName = "Use New/Half/Full Moon",
                description = "Automatically use Moon spells when talented",
                type = "toggle",
                default = true
            },
            moonUsage = {
                displayName = "Moon Usage",
                description = "When to use Moon spells",
                type = "dropdown",
                options = {"On Cooldown", "With Eclipse", "AoE Only"},
                default = "With Eclipse"
            }
        },
        
        cooldownSettings = {
            useCelestialAlignment = {
                displayName = "Use Celestial Alignment",
                description = "Automatically use Celestial Alignment",
                type = "toggle",
                default = true
            },
            useIncarnation = {
                displayName = "Use Incarnation",
                description = "Automatically use Incarnation when talented",
                type = "toggle",
                default = true
            },
            celestialUsage = {
                displayName = "Celestial Alignment Usage",
                description = "When to use Celestial Alignment",
                type = "dropdown",
                options = {"On Cooldown", "With Fury of Elune", "With Convoke", "Burst Only"},
                default = "On Cooldown"
            },
            useFuryOfElune = {
                displayName = "Use Fury of Elune",
                description = "Automatically use Fury of Elune when talented",
                type = "toggle",
                default = true
            },
            furyOfEluneUsage = {
                displayName = "Fury of Elune Usage",
                description = "When to use Fury of Elune",
                type = "dropdown",
                options = {"On Cooldown", "With Eclipse", "With Celestial Alignment", "AoE Only"},
                default = "With Eclipse"
            },
            useForceOfNature = {
                displayName = "Use Force of Nature",
                description = "Automatically use Force of Nature when talented",
                type = "toggle",
                default = true
            },
            forceOfNatureUsage = {
                displayName = "Force of Nature Usage",
                description = "When to use Force of Nature",
                type = "dropdown",
                options = {"On Cooldown", "With Eclipse", "AoE Only"},
                default = "On Cooldown"
            },
            useConvoke = {
                displayName = "Use Convoke the Spirits",
                description = "Automatically use Convoke the Spirits when talented",
                type = "toggle",
                default = true
            },
            convokeUsage = {
                displayName = "Convoke Usage",
                description = "When to use Convoke the Spirits",
                type = "dropdown",
                options = {"With Celestial Alignment", "On Cooldown", "With Eclipse"},
                default = "With Celestial Alignment"
            },
            useWarriorOfElune = {
                displayName = "Use Warrior of Elune",
                description = "Automatically use Warrior of Elune when talented",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
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
                default = 60
            },
            useFrenziedRegeneration = {
                displayName = "Use Frenzied Regeneration",
                description = "Automatically use Frenzied Regeneration (Bear)",
                type = "toggle",
                default = true
            },
            frenziedRegenThreshold = {
                displayName = "Frenzied Regen Health Threshold",
                description = "Health percentage to use Frenzied Regeneration",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useRenewal = {
                displayName = "Use Renewal",
                description = "Automatically use Renewal when talented",
                type = "toggle",
                default = true
            },
            renewalThreshold = {
                displayName = "Renewal Health Threshold",
                description = "Health percentage to use Renewal",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useRegrowth = {
                displayName = "Use Regrowth",
                description = "Automatically use Regrowth for healing",
                type = "toggle",
                default = true
            },
            regrowthThreshold = {
                displayName = "Regrowth Health Threshold",
                description = "Health percentage to use Regrowth",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            }
        },
        
        utilitySettings = {
            useSolarBeam = {
                displayName = "Use Solar Beam",
                description = "Automatically use Solar Beam for interrupts",
                type = "toggle",
                default = true
            },
            useTyphoon = {
                displayName = "Use Typhoon",
                description = "Automatically use Typhoon for knockback",
                type = "toggle",
                default = true
            },
            typhoonMode = {
                displayName = "Typhoon Usage",
                description = "When to use Typhoon",
                type = "dropdown",
                options = {"Defensive Only", "On Cooldown", "Manual Only"},
                default = "Defensive Only"
            },
            useUrsol = {
                displayName = "Use Ursol's Vortex",
                description = "Automatically use Ursol's Vortex",
                type = "toggle",
                default = true
            },
            ursolsVortexMode = {
                displayName = "Ursol's Vortex Usage",
                description = "When to use Ursol's Vortex",
                type = "dropdown",
                options = {"AoE Only", "Defensive Only", "Manual Only"},
                default = "Defensive Only"
            },
            useRoots = {
                displayName = "Use Entangling Roots",
                description = "Automatically use Entangling Roots",
                type = "toggle",
                default = true
            },
            useMightyBash = {
                displayName = "Use Mighty Bash",
                description = "Automatically use Mighty Bash",
                type = "toggle",
                default = true
            },
            useMassEntanglement = {
                displayName = "Use Mass Entanglement",
                description = "Automatically use Mass Entanglement when talented",
                type = "toggle",
                default = true
            }
        },
        
        dotSettings = {
            useMoonfire = {
                displayName = "Use Moonfire",
                description = "Automatically maintain Moonfire",
                type = "toggle",
                default = true
            },
            useSunfire = {
                displayName = "Use Sunfire",
                description = "Automatically maintain Sunfire",
                type = "toggle",
                default = true
            },
            useStellarFlare = {
                displayName = "Use Stellar Flare",
                description = "Automatically maintain Stellar Flare when talented",
                type = "toggle",
                default = true
            },
            sunfireAoEThreshold = {
                displayName = "Sunfire AoE Threshold",
                description = "Minimum targets to use Sunfire in AoE mode",
                type = "slider",
                min = 1,
                max = 5,
                default = 2
            },
            moonfireAoEThreshold = {
                displayName = "Moonfire AoE Threshold",
                description = "Minimum targets to apply Moonfire in AoE mode",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            stellarFlareAoEThreshold = {
                displayName = "Stellar Flare AoE Threshold",
                description = "Minimum targets to apply Stellar Flare in AoE mode",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Celestial Alignment/Incarnation controls
            celestialAlignment = AAC.RegisterAbility(spells.CELESTIAL_ALIGNMENT, {
                enabled = true,
                useDuringBurstOnly = false,
                requireEclipse = true,
                useWithFuryOfElune = false
            }),
            
            -- Starfall controls
            starfall = AAC.RegisterAbility(spells.STARFALL, {
                enabled = true,
                useDuringBurstOnly = false,
                minTargets = 2,
                minAstralPower = 50
            }),
            
            -- Starsurge controls
            starsurge = AAC.RegisterAbility(spells.STARSURGE, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithEclipseOnly = true,
                capAtMaxStarlord = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Balance:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for astral power updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "LUNAR_POWER" then
            self:UpdateAstralPower()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        end
    end)
    
    -- Register for player movement events
    API.RegisterEvent("PLAYER_STARTED_MOVING", function() 
        self:HandleMovementStart()
    end)
    
    API.RegisterEvent("PLAYER_STOPPED_MOVING", function() 
        self:HandleMovementStop()
    end)
    
    -- Register for form change events
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
    
    -- Initial form check
    self:UpdateShapeshiftForm()
    
    return true
end

-- Update talent information
function Balance:UpdateTalentInfo()
    -- Check for important talents
    talents.hasEclipse = true -- Eclipse is baseline now
    talents.hasAstralCommunion = API.HasTalent(spells.ASTRAL_COMMUNION)
    talents.hasStarlord = API.HasTalent(spells.STARLORD)
    talents.hasStellarDrift = API.HasTalent(spells.STELLAR_DRIFT)
    talents.hasShootingStars = API.HasTalent(spells.SHOOTING_STARS)
    talents.hasSoulOfTheForest = API.HasTalent(spells.SOUL_OF_THE_FOREST)
    talents.hasStellarInspiration = API.HasTalent(spells.STELLAR_INSPIRATION)
    talents.hasNaturesBalance = API.HasTalent(spells.NATURES_BALANCE)
    talents.hasTwinMoons = API.HasTalent(spells.TWIN_MOONS)
    talents.hasBalanceOfAllThings = API.HasTalent(spells.BALANCE_OF_ALL_THINGS)
    talents.hasOrbitalStrike = API.HasTalent(spells.ORBITAL_STRIKE)
    talents.hasStarweaversWeft = API.HasTalent(spells.STARWEAVERS_WEFT)
    talents.hasTirelessPursuit = API.HasTalent(spells.TIRELESS_PURSUIT)
    talents.hasWellHonedInstincts = API.HasTalent(spells.WELL_HONED_INSTINCTS)
    talents.hasKillerInstinct = API.HasTalent(spells.KILLER_INSTINCT)
    talents.hasElunesGuidance = API.HasTalent(spells.ELUNES_GUIDANCE)
    talents.hasOrbitBreaker = API.HasTalent(spells.ORBIT_BREAKER)
    talents.hasPowerOfGoldrinn = API.HasTalent(spells.POWER_OF_GOLDRINN)
    talents.hasOnethsClearVision = API.HasTalent(spells.ONETHS_CLEAR_VISION)
    talents.hasOnethsPerception = API.HasTalent(spells.ONETHS_PERCEPTION)
    talents.hasPrimordialArcanicPulsar = API.HasTalent(spells.PRIMORDIAL_ARCANIC_PULSAR)
    talents.hasDenizenOfTheDream = API.HasTalent(spells.DENIZEN_OF_THE_DREAM)
    talents.hasRadiantMoonlight = API.HasTalent(spells.RADIANT_MOONLIGHT)
    talents.hasSolsticeAlignment = API.HasTalent(spells.SOLSTICE_ALIGNMENT)
    talents.hasTouchTheCosmos = API.HasTalent(spells.TOUCH_THE_COSMOS)
    talents.hasWarriorOfElune = API.HasTalent(spells.WARRIOR_OF_ELUNE)
    talents.hasForceOfNature = API.HasTalent(spells.FORCE_OF_NATURE)
    talents.hasFuryOfElune = API.HasTalent(spells.FURY_OF_ELUNE)
    talents.hasConvokeTheSpirits = API.HasTalent(spells.CONVOKE_THE_SPIRITS)
    talents.hasIncarnationChosenOfElune = API.HasTalent(spells.INCARNATION_CHOSEN_OF_ELUNE)
    talents.hasCelestialAlignment = API.HasTalent(spells.CELESTIAL_ALIGNMENT)
    talents.hasStellarFlare = API.HasTalent(spells.STELLAR_FLARE)
    talents.hasStarfall = API.HasTalent(spells.STARFALL)
    
    -- War Within Season 2 talents
    talents.hasImprovedStarfall = API.HasTalent(spells.IMPROVED_STARFALL)
    talents.hasArcanicPulsar = API.HasTalent(spells.ARCANIC_PULSAR)
    talents.hasAstralSmolder = API.HasTalent(spells.ASTRAL_SMOLDER)
    talents.hasConvokingStars = API.HasTalent(spells.CONVOKING_STARS)
    talents.hasCosmicRapidity = API.HasTalent(spells.COSMIC_RAPIDITY)
    talents.hasFungalGrowth = API.HasTalent(spells.FUNGAL_GROWTH)
    talents.hasGalacticGuardian = API.HasTalent(spells.GALACTIC_GUARDIAN)
    talents.hasGermination = API.HasTalent(spells.GERMINATION)
    talents.hasHeartOfTheWild = API.HasTalent(spells.HEART_OF_THE_WILD)
    talents.hasImprovedSolarBeam = API.HasTalent(spells.IMPROVED_SOLAR_BEAM)
    talents.hasIncessantTempest = API.HasTalent(spells.INCESSANT_TEMPEST)
    talents.hasOneWithNature = API.HasTalent(spells.ONE_WITH_NATURE)
    talents.hasProtectorOfThePack = API.HasTalent(spells.PROTECTOR_OF_THE_PACK)
    talents.hasUmbralIntensity = API.HasTalent(spells.UMBRAL_INTENSITY)
    
    -- Set specialized variables based on talents
    if talents.hasShootingStars then
        shootingStars = true
    end
    
    if talents.hasCelestialAlignment then
        celestialAlignment = true
    end
    
    if talents.hasIncarnationChosenOfElune then
        incarnationChosen = true
    end
    
    if talents.hasBalanceOfAllThings then
        balanceOfAll = true
    end
    
    if API.IsSpellKnown(spells.SOLAR_BEAM) then
        solarbeam = true
    end
    
    if API.IsSpellKnown(spells.WRATH) then
        wrath = true
    end
    
    if API.IsSpellKnown(spells.STARFIRE) then
        starfire = true
    end
    
    if API.IsSpellKnown(spells.STARSURGE) then
        starsurge = true
    end
    
    if API.IsSpellKnown(spells.MOONFIRE) then
        moonfire = true
    end
    
    if API.IsSpellKnown(spells.SUNFIRE) then
        sunfire = true
    end
    
    if talents.hasStellarFlare then
        stellarFlare = true
    end
    
    if talents.hasStarfall then
        starfall = true
    end
    
    if talents.hasTwinMoons then
        twin_moons = true
    end
    
    if talents.hasStellarDrift then
        stellarDrift = true
    end
    
    if talents.hasSoulOfTheForest then
        soul_of_the_forest = true
    end
    
    if talents.hasStarlord then
        starlord = true
    end
    
    if talents.hasStellarInspiration then
        stellar_inspiration = true
    end
    
    if talents.hasNaturesBalance then
        natures_balance = true
    end
    
    if talents.hasAstralCommunion then
        astral_communion = true
    end
    
    if talents.hasForceOfNature then
        force_of_nature = true
    end
    
    if talents.hasWarriorOfElune then
        warrior_of_elune = true
    end
    
    if talents.hasOnethsClearVision then
        oneths_clear_vision = true
    end
    
    if talents.hasOnethsPerception then
        oneths_perception = true
    end
    
    if talents.hasPowerOfGoldrinn then
        power_of_goldrinn = true
    end
    
    if talents.hasPrimordialArcanicPulsar then
        primordial_arcanic_pulsar = true
    end
    
    if talents.hasOrbitalStrike then
        orbital_strike = true
    end
    
    if talents.hasStarweaversWeft then
        starweavers_weft = true
    end
    
    if talents.hasTirelessPursuit then
        tireless_pursuit = true
    end
    
    if talents.hasConvokeTheSpirits then
        convoke_the_spirits = true
    end
    
    if talents.hasWellHonedInstincts then
        well_honed_instincts = true
    end
    
    if talents.hasKillerInstinct then
        killer_instinct = true
    end
    
    if talents.hasElunesGuidance then
        elunes_guidance = true
    end
    
    if talents.hasOrbitBreaker then
        orbit_breaker = true
    end
    
    if talents.hasDenizenOfTheDream then
        denizen_of_the_dream = true
    end
    
    if talents.hasFuryOfElune then
        fury_of_elune = true
    end
    
    if talents.hasBalanceOfAllThings then
        balance_of_all_things = true
    end
    
    if talents.hasRadiantMoonlight then
        radiant_moonlight = true
    end
    
    if talents.hasArcanicPulsar then
        arcanic_pulsar = true
    end
    
    if talents.hasSolsticeAlignment then
        solstice_alignment = true
    end
    
    if talents.hasTouchTheCosmos then
        touch_the_cosmos = true
    end
    
    if talents.hasUmbralIntensity then
        umbralIntensity = true
    end
    
    if API.IsSpellKnown(spells.FRENZIED_REGENERATION) then
        frenziedRegen = true
    end
    
    API.PrintDebug("Balance Druid talents updated")
    
    return true
end

-- Update astral power tracking
function Balance:UpdateAstralPower()
    currentAstralPower = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Balance:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Handle player start moving
function Balance:HandleMovementStart()
    isMoving = true
    return true
end

-- Handle player stop moving
function Balance:HandleMovementStop()
    isMoving = false
    return true
end

-- Update shapeshift form
function Balance:UpdateShapeshiftForm()
    -- Check for Moonkin Form
    moonkinFormActive = API.GetShapeshiftForm() == 4 -- Moonkin Form is index 4
    
    -- Check for Tree of Life Form
    treeOfLifeFormActive = API.GetShapeshiftForm() == 5 -- Tree of Life is index 5
    
    return true
end

-- Update target data
function Balance:UpdateTargetData()
    -- Check if in range for Starfire
    inRange = API.IsSpellInRange(spells.STARFIRE, "target")
    
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Moonfire
        local moonfireInfo = API.GetDebuffInfo(targetGUID, debuffs.MOONFIRE)
        if moonfireInfo then
            moonfireActive[targetGUID] = true
            moonfireEndTime[targetGUID] = select(6, moonfireInfo)
        else
            moonfireActive[targetGUID] = false
            moonfireEndTime[targetGUID] = 0
        end
        
        -- Check for Sunfire
        local sunfireInfo = API.GetDebuffInfo(targetGUID, debuffs.SUNFIRE)
        if sunfireInfo then
            sunfireActive[targetGUID] = true
            sunfireEndTime[targetGUID] = select(6, sunfireInfo)
        else
            sunfireActive[targetGUID] = false
            sunfireEndTime[targetGUID] = 0
        end
        
        -- Check for Stellar Flare
        if stellarFlare then
            local stellarFlareInfo = API.GetDebuffInfo(targetGUID, debuffs.STELLAR_FLARE)
            if stellarFlareInfo then
                stellarFlareActive[targetGUID] = true
                stellarFlareEndTime[targetGUID] = select(6, stellarFlareInfo)
            else
                stellarFlareActive[targetGUID] = false
                stellarFlareEndTime[targetGUID] = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Starfall radius
    
    return true
end

-- Calculate DoT pandemic refresh window
function Balance:GetPandemicTime(duration)
    return duration * 0.3 -- 30% of full duration
end

-- Handle combat log events
function Balance:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from this player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Eclipse Solar
            if spellID == buffs.ECLIPSE_SOLAR then
                eclipseActive = true
                eclipseSolar = true
                eclipseLunar = false
                eclipseEndTime = GetTime() + ECLIPSE_DURATION
                API.PrintDebug("Eclipse Solar activated")
            end
            
            -- Track Eclipse Lunar
            if spellID == buffs.ECLIPSE_LUNAR then
                eclipseActive = true
                eclipseSolar = false
                eclipseLunar = true
                eclipseEndTime = GetTime() + ECLIPSE_DURATION
                API.PrintDebug("Eclipse Lunar activated")
            end
            
            -- Track Incarnation: Chosen of Elune
            if spellID == buffs.INCARNATION_CHOSEN_OF_ELUNE then
                incarnationActive = true
                incarnationEndTime = GetTime() + INCARNATION_DURATION
                -- Incarnation applies Celestial Alignment benefit as well
                celestialAlignmentActive = true
                celestialAlignmentEndTime = GetTime() + INCARNATION_DURATION
                API.PrintDebug("Incarnation: Chosen of Elune activated")
            end
            
            -- Track Celestial Alignment
            if spellID == buffs.CELESTIAL_ALIGNMENT then
                celestialAlignmentActive = true
                celestialAlignmentEndTime = GetTime() + CELESTIAL_ALIGNMENT_DURATION
                API.PrintDebug("Celestial Alignment activated")
            end
            
            -- Track Starlord
            if spellID == buffs.STARLORD then
                starlordActive = true
                starlordStacks = select(4, API.GetBuffInfo("player", buffs.STARLORD)) or 1
                starlordEndTime = select(6, API.GetBuffInfo("player", buffs.STARLORD))
                API.PrintDebug("Starlord activated: " .. tostring(starlordStacks) .. " stacks")
            end
            
            -- Track Starfall
            if spellID == buffs.STARFALL then
                starfallActive = true
                starfallEndTime = GetTime() + STARFALL_DURATION
                API.PrintDebug("Starfall activated")
            end
            
            -- Track Oneth's Clear Vision
            if spellID == buffs.ONETHS_CLEAR_VISION then
                onethsActive = true
                onethsClearcastingActive = true
                onethsEndTime = GetTime() + ONETHS_DURATION
                API.PrintDebug("Oneth's Clear Vision activated")
            end
            
            -- Track Oneth's Perception
            if spellID == buffs.ONETHS_PERCEPTION then
                onethsActive = true
                onethsPercProc = true
                onethsEndTime = GetTime() + ONETHS_DURATION
                API.PrintDebug("Oneth's Perception activated")
            end
            
            -- Track Power of Goldrinn
            if spellID == buffs.POWER_OF_GOLDRINN then
                API.PrintDebug("Power of Goldrinn activated")
            end
            
            -- Track Warrior of Elune
            if spellID == buffs.WARRIOR_OF_ELUNE then
                API.PrintDebug("Warrior of Elune activated")
            end
            
            -- Track One With Nature
            if spellID == buffs.ONE_WITH_NATURE then
                oneWithNatureActive = true
                oneWithNatureStacks = select(4, API.GetBuffInfo("player", buffs.ONE_WITH_NATURE)) or 1
                oneWithNatureEndTime = select(6, API.GetBuffInfo("player", buffs.ONE_WITH_NATURE))
                API.PrintDebug("One With Nature activated: " .. tostring(oneWithNatureStacks) .. " stacks")
            end
            
            -- Track Umbral Intensity
            if spellID == buffs.UMBRAL_INTENSITY then
                umbralIntensity = true
                umbralIntensityStacks = select(4, API.GetBuffInfo("player", buffs.UMBRAL_INTENSITY)) or 1
                umbralIntensityEndTime = select(6, API.GetBuffInfo("player", buffs.UMBRAL_INTENSITY))
                API.PrintDebug("Umbral Intensity activated: " .. tostring(umbralIntensityStacks) .. " stacks")
            end
            
            -- Track Solstice
            if spellID == buffs.SOLSTICE then
                solstice = true
                solsticeStacks = select(4, API.GetBuffInfo("player", buffs.SOLSTICE)) or 1
                solsticeEndTime = select(6, API.GetBuffInfo("player", buffs.SOLSTICE))
                API.PrintDebug("Solstice activated: " .. tostring(solsticeStacks) .. " stacks")
            end
            
            -- Track Touch of Elune
            if spellID == buffs.TOUCH_OF_ELUNE then
                touchOfElune = true
                touchOfEluneStacks = select(4, API.GetBuffInfo("player", buffs.TOUCH_OF_ELUNE)) or 1
                touchOfEluneEndTime = select(6, API.GetBuffInfo("player", buffs.TOUCH_OF_ELUNE))
                API.PrintDebug("Touch of Elune activated: " .. tostring(touchOfEluneStacks) .. " stacks")
            end
            
            -- Track Frenzied Regeneration
            if spellID == buffs.FRENZIED_REGENERATION then
                frenziedRegenActive = true
                frenziedRegenEndTime = GetTime() + FRENZIED_REGEN_DURATION
                API.PrintDebug("Frenzied Regeneration activated")
            end
        end
        
        -- Track DoTs on any target
        if moonfireActive[destGUID] ~= nil then
            if spellID == debuffs.MOONFIRE then
                moonfireActive[destGUID] = true
                moonfireEndTime[destGUID] = select(6, API.GetDebuffInfo(destName, debuffs.MOONFIRE))
                API.PrintDebug("Moonfire applied to " .. destName)
            elseif spellID == debuffs.SUNFIRE then
                sunfireActive[destGUID] = true
                sunfireEndTime[destGUID] = select(6, API.GetDebuffInfo(destName, debuffs.SUNFIRE))
                API.PrintDebug("Sunfire applied to " .. destName)
            elseif spellID == debuffs.STELLAR_FLARE and stellarFlare then
                stellarFlareActive[destGUID] = true
                stellarFlareEndTime[destGUID] = select(6, API.GetDebuffInfo(destName, debuffs.STELLAR_FLARE))
                API.PrintDebug("Stellar Flare applied to " .. destName)
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Eclipse Solar
            if spellID == buffs.ECLIPSE_SOLAR then
                eclipseActive = false
                eclipseSolar = false
                API.PrintDebug("Eclipse Solar faded")
            end
            
            -- Track Eclipse Lunar
            if spellID == buffs.ECLIPSE_LUNAR then
                eclipseActive = false
                eclipseLunar = false
                API.PrintDebug("Eclipse Lunar faded")
            end
            
            -- Track Incarnation: Chosen of Elune
            if spellID == buffs.INCARNATION_CHOSEN_OF_ELUNE then
                incarnationActive = false
                API.PrintDebug("Incarnation: Chosen of Elune faded")
            end
            
            -- Track Celestial Alignment
            if spellID == buffs.CELESTIAL_ALIGNMENT then
                celestialAlignmentActive = false
                API.PrintDebug("Celestial Alignment faded")
            end
            
            -- Track Starlord
            if spellID == buffs.STARLORD then
                starlordActive = false
                starlordStacks = 0
                API.PrintDebug("Starlord faded")
            end
            
            -- Track Starfall
            if spellID == buffs.STARFALL then
                starfallActive = false
                API.PrintDebug("Starfall faded")
            end
            
            -- Track Oneth's Clear Vision
            if spellID == buffs.ONETHS_CLEAR_VISION then
                onethsActive = false
                onethsClearcastingActive = false
                API.PrintDebug("Oneth's Clear Vision faded")
            end
            
            -- Track Oneth's Perception
            if spellID == buffs.ONETHS_PERCEPTION then
                onethsActive = false
                onethsPercProc = false
                API.PrintDebug("Oneth's Perception faded")
            end
            
            -- Track One With Nature
            if spellID == buffs.ONE_WITH_NATURE then
                oneWithNatureActive = false
                oneWithNatureStacks = 0
                API.PrintDebug("One With Nature faded")
            end
            
            -- Track Umbral Intensity
            if spellID == buffs.UMBRAL_INTENSITY then
                umbralIntensity = false
                umbralIntensityStacks = 0
                API.PrintDebug("Umbral Intensity faded")
            end
            
            -- Track Solstice
            if spellID == buffs.SOLSTICE then
                solstice = false
                solsticeStacks = 0
                API.PrintDebug("Solstice faded")
            end
            
            -- Track Touch of Elune
            if spellID == buffs.TOUCH_OF_ELUNE then
                touchOfElune = false
                touchOfEluneStacks = 0
                API.PrintDebug("Touch of Elune faded")
            end
            
            -- Track Frenzied Regeneration
            if spellID == buffs.FRENZIED_REGENERATION then
                frenziedRegenActive = false
                API.PrintDebug("Frenzied Regeneration faded")
            end
        end
        
        -- Track DoT removals
        if moonfireActive[destGUID] ~= nil then
            if spellID == debuffs.MOONFIRE then
                moonfireActive[destGUID] = false
                moonfireEndTime[destGUID] = 0
                API.PrintDebug("Moonfire faded from " .. destName)
            elseif spellID == debuffs.SUNFIRE then
                sunfireActive[destGUID] = false
                sunfireEndTime[destGUID] = 0
                API.PrintDebug("Sunfire faded from " .. destName)
            elseif spellID == debuffs.STELLAR_FLARE then
                stellarFlareActive[destGUID] = false
                stellarFlareEndTime[destGUID] = 0
                API.PrintDebug("Stellar Flare faded from " .. destName)
            end
        end
    end
    
    -- Track Starlord stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.STARLORD and destGUID == API.GetPlayerGUID() then
        starlordStacks = select(4, API.GetBuffInfo("player", buffs.STARLORD)) or 0
        API.PrintDebug("Starlord stacks: " .. tostring(starlordStacks))
    end
    
    -- Track One With Nature stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.ONE_WITH_NATURE and destGUID == API.GetPlayerGUID() then
        oneWithNatureStacks = select(4, API.GetBuffInfo("player", buffs.ONE_WITH_NATURE)) or 0
        API.PrintDebug("One With Nature stacks: " .. tostring(oneWithNatureStacks))
    end
    
    -- Track Umbral Intensity stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.UMBRAL_INTENSITY and destGUID == API.GetPlayerGUID() then
        umbralIntensityStacks = select(4, API.GetBuffInfo("player", buffs.UMBRAL_INTENSITY)) or 0
        API.PrintDebug("Umbral Intensity stacks: " .. tostring(umbralIntensityStacks))
    end
    
    -- Track Solstice stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SOLSTICE and destGUID == API.GetPlayerGUID() then
        solsticeStacks = select(4, API.GetBuffInfo("player", buffs.SOLSTICE)) or 0
        API.PrintDebug("Solstice stacks: " .. tostring(solsticeStacks))
    end
    
    -- Track Touch of Elune stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.TOUCH_OF_ELUNE and destGUID == API.GetPlayerGUID() then
        touchOfEluneStacks = select(4, API.GetBuffInfo("player", buffs.TOUCH_OF_ELUNE)) or 0
        API.PrintDebug("Touch of Elune stacks: " .. tostring(touchOfEluneStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.WRATH then
            API.PrintDebug("Wrath cast")
        elseif spellID == spells.STARFIRE then
            API.PrintDebug("Starfire cast")
        elseif spellID == spells.STARSURGE then
            starSurgeCount = starSurgeCount + 1
            API.PrintDebug("Starsurge cast, count: " .. tostring(starSurgeCount))
        elseif spellID == spells.STARFALL then
            starfallActive = true
            starfallEndTime = GetTime() + STARFALL_DURATION
            API.PrintDebug("Starfall cast")
        elseif spellID == spells.CELESTIAL_ALIGNMENT then
            celestialAlignmentActive = true
            celestialAlignmentEndTime = GetTime() + CELESTIAL_ALIGNMENT_DURATION
            API.PrintDebug("Celestial Alignment cast")
        elseif spellID == spells.INCARNATION_CHOSEN_OF_ELUNE then
            incarnationActive = true
            incarnationEndTime = GetTime() + INCARNATION_DURATION
            -- Incarnation applies Celestial Alignment benefit as well
            celestialAlignmentActive = true
            celestialAlignmentEndTime = GetTime() + INCARNATION_DURATION
            API.PrintDebug("Incarnation: Chosen of Elune cast")
        elseif spellID == spells.FURY_OF_ELUNE then
            furyOfEluneActive = true
            furyOfEluneEndTime = GetTime() + FURY_OF_ELUNE_DURATION
            API.PrintDebug("Fury of Elune cast")
        elseif spellID == spells.CONVOKE_THE_SPIRITS then
            API.PrintDebug("Convoke the Spirits cast")
        elseif spellID == spells.FORCE_OF_NATURE then
            API.PrintDebug("Force of Nature cast")
        elseif spellID == spells.WARRIOR_OF_ELUNE then
            API.PrintDebug("Warrior of Elune cast")
        elseif spellID == spells.NEW_MOON then
            fullMoonCount = 1 -- Next is Half Moon
            API.PrintDebug("New Moon cast")
        elseif spellID == spells.HALF_MOON then
            fullMoonCount = 2 -- Next is Full Moon
            API.PrintDebug("Half Moon cast")
        elseif spellID == spells.FULL_MOON then
            fullMoonCount = 0 -- Next is New Moon
            API.PrintDebug("Full Moon cast")
        elseif spellID == spells.MOONKIN_FORM then
            moonkinFormActive = true
            API.PrintDebug("Moonkin Form cast")
        elseif spellID == spells.FRENZIED_REGENERATION then
            frenziedRegenActive = true
            frenziedRegenEndTime = GetTime() + FRENZIED_REGEN_DURATION
            API.PrintDebug("Frenzied Regeneration cast")
        end
    end
    
    return true
end

-- Main rotation function
function Balance:RunRotation()
    -- Check if we should be running Balance Druid logic
    if API.GetActiveSpecID() ~= BALANCE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BalanceDruid")
    
    -- Update variables
    self:UpdateAstralPower()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Make sure we're in Moonkin Form
    if settings.rotationSettings.useMoonkinForm and 
       not moonkinFormActive and 
       API.CanCast(spells.MOONKIN_FORM) then
        API.CastSpell(spells.MOONKIN_FORM)
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Skip if not in range
    if not inRange then
        return false
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Apply DoTs before anything else
    if self:HandleDots(settings) then
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
function Balance:HandleInterrupts(settings)
    -- Only attempt to interrupt if in range and user has enabled
    if solarbeam and
       settings.utilitySettings.useSolarBeam and
       API.CanCast(spells.SOLAR_BEAM) and
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.SOLAR_BEAM)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Balance:HandleDefensives(settings)
    -- Use Barkskin
    if settings.defensiveSettings.useBarkskin and
       playerHealth <= settings.defensiveSettings.barkskinThreshold and
       API.CanCast(spells.BARKSKIN) then
        API.CastSpell(spells.BARKSKIN)
        return true
    end
    
    -- Use Frenzied Regeneration in Bear Form
    if frenziedRegen and
       settings.defensiveSettings.useFrenziedRegeneration and
       playerHealth <= settings.defensiveSettings.frenziedRegenThreshold and
       API.GetShapeshiftForm() == 1 and -- Bear Form
       API.CanCast(spells.FRENZIED_REGENERATION) then
        API.CastSpell(spells.FRENZIED_REGENERATION)
        return true
    end
    
    -- Use Renewal
    if settings.defensiveSettings.useRenewal and
       API.HasTalent(spells.RENEWAL) and
       playerHealth <= settings.defensiveSettings.renewalThreshold and
       API.CanCast(spells.RENEWAL) then
        API.CastSpell(spells.RENEWAL)
        return true
    end
    
    -- Use Regrowth
    if settings.defensiveSettings.useRegrowth and
       playerHealth <= settings.defensiveSettings.regrowthThreshold and
       API.CanCast(spells.REGROWTH) then
        API.CastSpellOnUnit(spells.REGROWTH, "player")
        return true
    end
    
    return false
end

-- Handle DoTs
function Balance:HandleDots(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if not targetGUID or targetGUID == "" then
        return false
    end
    
    -- Calculate pandemic windows
    local moonfirePandemic = self:GetPandemicTime(MOONFIRE_DURATION)
    local sunfirePandemic = self:GetPandemicTime(SUNFIRE_DURATION)
    local stellarFlarePandemic = self:GetPandemicTime(STELLAR_FLARE_DURATION)
    
    -- Maintain Moonfire
    if moonfire and
       settings.dotSettings.useMoonfire and
       (not moonfireActive[targetGUID] or 
        (moonfireActive[targetGUID] and 
         moonfireEndTime[targetGUID] - GetTime() < moonfirePandemic)) and
       API.CanCast(spells.MOONFIRE) then
        API.CastSpell(spells.MOONFIRE)
        return true
    end
    
    -- Maintain Sunfire
    if sunfire and
       settings.dotSettings.useSunfire and
       (not sunfireActive[targetGUID] or 
        (sunfireActive[targetGUID] and 
         sunfireEndTime[targetGUID] - GetTime() < sunfirePandemic)) and
       API.CanCast(spells.SUNFIRE) then
        API.CastSpell(spells.SUNFIRE)
        return true
    end
    
    -- Maintain Stellar Flare
    if stellarFlare and
       settings.dotSettings.useStellarFlare and
       (currentAoETargets < settings.dotSettings.stellarFlareAoEThreshold) and
       (not stellarFlareActive[targetGUID] or 
        (stellarFlareActive[targetGUID] and 
         stellarFlareEndTime[targetGUID] - GetTime() < stellarFlarePandemic)) and
       API.CanCast(spells.STELLAR_FLARE) then
        API.CastSpell(spells.STELLAR_FLARE)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Balance:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Incarnation: Chosen of Elune
    if incarnationChosen and
       settings.cooldownSettings.useIncarnation and
       not incarnationActive and 
       not celestialAlignmentActive and
       API.CanCast(spells.INCARNATION_CHOSEN_OF_ELUNE) then
        
        local shouldUseIncarnation = false
        
        if settings.cooldownSettings.celestialUsage == "On Cooldown" then
            shouldUseIncarnation = true
        elseif settings.cooldownSettings.celestialUsage == "With Fury of Elune" and talents.hasFuryOfElune then
            shouldUseIncarnation = API.GetSpellCooldown(spells.FURY_OF_ELUNE) < 3
        elseif settings.cooldownSettings.celestialUsage == "With Convoke" and talents.hasConvokeTheSpirits then
            shouldUseIncarnation = API.GetSpellCooldown(spells.CONVOKE_THE_SPIRITS) < 3
        elseif settings.cooldownSettings.celestialUsage == "Burst Only" then
            shouldUseIncarnation = burstModeActive
        end
        
        if shouldUseIncarnation then
            API.CastSpell(spells.INCARNATION_CHOSEN_OF_ELUNE)
            return true
        end
    end
    
    -- Use Celestial Alignment
    if celestialAlignment and
       settings.cooldownSettings.useCelestialAlignment and
       not celestialAlignmentActive and 
       not incarnationActive and
       API.CanCast(spells.CELESTIAL_ALIGNMENT) then
        
        local shouldUseCelestial = false
        
        if settings.cooldownSettings.celestialUsage == "On Cooldown" then
            shouldUseCelestial = true
        elseif settings.cooldownSettings.celestialUsage == "With Fury of Elune" and talents.hasFuryOfElune then
            shouldUseCelestial = API.GetSpellCooldown(spells.FURY_OF_ELUNE) < 3
        elseif settings.cooldownSettings.celestialUsage == "With Convoke" and talents.hasConvokeTheSpirits then
            shouldUseCelestial = API.GetSpellCooldown(spells.CONVOKE_THE_SPIRITS) < 3
        elseif settings.cooldownSettings.celestialUsage == "Burst Only" then
            shouldUseCelestial = burstModeActive
        end
        
        if shouldUseCelestial then
            API.CastSpell(spells.CELESTIAL_ALIGNMENT)
            return true
        end
    end
    
    -- Use Fury of Elune
    if fury_of_elune and
       settings.cooldownSettings.useFuryOfElune and
       not furyOfEluneActive and
       API.CanCast(spells.FURY_OF_ELUNE) then
        
        local shouldUseFuryOfElune = false
        
        if settings.cooldownSettings.furyOfEluneUsage == "On Cooldown" then
            shouldUseFuryOfElune = true
        elseif settings.cooldownSettings.furyOfEluneUsage == "With Eclipse" then
            shouldUseFuryOfElune = eclipseActive
        elseif settings.cooldownSettings.furyOfEluneUsage == "With Celestial Alignment" then
            shouldUseFuryOfElune = celestialAlignmentActive or incarnationActive
        elseif settings.cooldownSettings.furyOfEluneUsage == "AoE Only" then
            shouldUseFuryOfElune = currentAoETargets >= settings.rotationSettings.aoeThreshold
        end
        
        if shouldUseFuryOfElune then
            API.CastSpellAtTarget(spells.FURY_OF_ELUNE)
            return true
        end
    end
    
    -- Use Force of Nature
    if force_of_nature and
       settings.cooldownSettings.useForceOfNature and
       API.CanCast(spells.FORCE_OF_NATURE) then
        
        local shouldUseForceOfNature = false
        
        if settings.cooldownSettings.forceOfNatureUsage == "On Cooldown" then
            shouldUseForceOfNature = true
        elseif settings.cooldownSettings.forceOfNatureUsage == "With Eclipse" then
            shouldUseForceOfNature = eclipseActive
        elseif settings.cooldownSettings.forceOfNatureUsage == "AoE Only" then
            shouldUseForceOfNature = currentAoETargets >= settings.rotationSettings.aoeThreshold
        end
        
        if shouldUseForceOfNature then
            API.CastSpellAtTarget(spells.FORCE_OF_NATURE)
            return true
        end
    end
    
    -- Use Convoke the Spirits
    if convoke_the_spirits and
       settings.cooldownSettings.useConvoke and
       API.CanCast(spells.CONVOKE_THE_SPIRITS) then
        
        local shouldUseConvoke = false
        
        if settings.cooldownSettings.convokeUsage == "With Celestial Alignment" then
            shouldUseConvoke = celestialAlignmentActive or incarnationActive
        elseif settings.cooldownSettings.convokeUsage == "On Cooldown" then
            shouldUseConvoke = true
        elseif settings.cooldownSettings.convokeUsage == "With Eclipse" then
            shouldUseConvoke = eclipseActive
        end
        
        if shouldUseConvoke then
            API.CastSpell(spells.CONVOKE_THE_SPIRITS)
            return true
        end
    end
    
    -- Use Warrior of Elune
    if warrior_of_elune and
       settings.cooldownSettings.useWarriorOfElune and
       API.CanCast(spells.WARRIOR_OF_ELUNE) then
        API.CastSpell(spells.WARRIOR_OF_ELUNE)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Balance:HandleAoERotation(settings)
    -- Use Starfall
    if starfall and
       settings.abilityControls.starfall.enabled and
       not starfallActive and
       currentAstralPower >= settings.abilityControls.starfall.minAstralPower and
       currentAoETargets >= settings.abilityControls.starfall.minTargets and
       API.CanCast(spells.STARFALL) and
       (not settings.abilityControls.starfall.useDuringBurstOnly or burstModeActive) then
        API.CastSpell(spells.STARFALL)
        return true
    end
    
    -- Check for Moon spell rotation if talented and enabled
    if talents.hasRadiantMoonlight and
       settings.rotationSettings.useNewMoon and
       (settings.rotationSettings.moonUsage == "AoE Only" or 
        settings.rotationSettings.moonUsage == "On Cooldown" or 
        (settings.rotationSettings.moonUsage == "With Eclipse" and eclipseActive)) then
        
        if fullMoonCount == 0 and API.CanCast(spells.NEW_MOON) then
            API.CastSpellOnTarget(spells.NEW_MOON)
            return true
        elseif fullMoonCount == 1 and API.CanCast(spells.HALF_MOON) then
            API.CastSpellOnTarget(spells.HALF_MOON)
            return true
        elseif fullMoonCount == 2 and API.CanCast(spells.FULL_MOON) then
            API.CastSpellOnTarget(spells.FULL_MOON)
            return true
        end
    end
    
    -- Utilize Oneth's procs if available
    if onethsClearcastingActive and API.CanCast(spells.STARFALL) then
        API.CastSpell(spells.STARFALL)
        return true
    elseif onethsPercProc and API.CanCast(spells.STARSURGE) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    -- Use Starsurge if enough AP and in Eclipse for ST damage
    if starsurge and
       settings.abilityControls.starsurge.enabled and
       currentAstralPower >= 40 and
       API.CanCast(spells.STARSURGE) and 
       (not settings.abilityControls.starsurge.useWithEclipseOnly or eclipseActive) and
       (not settings.abilityControls.starsurge.capAtMaxStarlord or starlordStacks < 3) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    -- Use Starfire during Eclipse Lunar or if we have no Eclipse in AoE
    if starfire and
       (eclipseLunar or celestialAlignmentActive or incarnationActive or not eclipseActive) and
       API.CanCast(spells.STARFIRE) then
        API.CastSpell(spells.STARFIRE)
        return true
    end
    
    -- Use Wrath during Eclipse Solar if we're not using Starfire
    if wrath and
       eclipseSolar and
       not eclipseLunar and
       not celestialAlignmentActive and
       not incarnationActive and
       API.CanCast(spells.WRATH) then
        API.CastSpell(spells.WRATH)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Balance:HandleSingleTargetRotation(settings)
    -- Utilize Oneth's procs if available
    if onethsClearcastingActive and API.CanCast(spells.STARFALL) then
        API.CastSpell(spells.STARFALL)
        return true
    elseif onethsPercProc and API.CanCast(spells.STARSURGE) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    -- Use Starsurge if enough AP and in Eclipse
    if starsurge and
       settings.abilityControls.starsurge.enabled and
       currentAstralPower >= 40 and 
       (not settings.astralPowerPooling || 
        currentAstralPower > settings.astralPowerPoolingThreshold) and
       API.CanCast(spells.STARSURGE) and 
       (not settings.abilityControls.starsurge.useWithEclipseOnly or eclipseActive) and
       (not settings.abilityControls.starsurge.capAtMaxStarlord or starlordStacks < 3) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    -- Check for Moon spell rotation if talented and enabled
    if talents.hasRadiantMoonlight and
       settings.rotationSettings.useNewMoon and
       (settings.rotationSettings.moonUsage == "On Cooldown" or 
        (settings.rotationSettings.moonUsage == "With Eclipse" and eclipseActive)) then
        
        if fullMoonCount == 0 and API.CanCast(spells.NEW_MOON) then
            API.CastSpellOnTarget(spells.NEW_MOON)
            return true
        elseif fullMoonCount == 1 and API.CanCast(spells.HALF_MOON) then
            API.CastSpellOnTarget(spells.HALF_MOON)
            return true
        elseif fullMoonCount == 2 and API.CanCast(spells.FULL_MOON) then
            API.CastSpellOnTarget(spells.FULL_MOON)
            return true
        end
    end
    
    -- Use Starfire during Eclipse Lunar, if moving with Stellar Drift, or with Warrior of Elune
    if starfire and
       (eclipseLunar or celestialAlignmentActive or incarnationActive or 
       (isMoving and talents.hasStellarDrift and starfallActive) or 
       API.PlayerHasBuff(buffs.WARRIOR_OF_ELUNE)) and
       API.CanCast(spells.STARFIRE) then
        API.CastSpell(spells.STARFIRE)
        return true
    end
    
    -- Use Wrath during Eclipse Solar or if we're not in any Eclipse
    if wrath and
       (eclipseSolar or not eclipseActive) and
       not eclipseLunar and
       not celestialAlignmentActive and
       not incarnationActive and
       API.CanCast(spells.WRATH) then
        API.CastSpell(spells.WRATH)
        return true
    end
    
    return false
end

-- Handle specialization change
function Balance:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentAstralPower = 0
    maxAstralPower = 100
    eclipseActive = false
    eclipseSolar = false
    eclipseLunar = false
    eclipseEndTime = 0
    incarnationActive = false
    incarnationEndTime = 0
    celestialAlignmentActive = false
    celestialAlignmentEndTime = 0
    starfallActive = false
    starfallEndTime = 0
    starlordActive = false
    starlordStacks = 0
    starlordEndTime = 0
    onethsActive = false
    onethsEndTime = 0
    onethsClearcastingActive = false
    onethsPercProc = false
    moonkinFormActive = false
    sunfireActive = {}
    sunfireEndTime = {}
    moonfireActive = {}
    moonfireEndTime = {}
    stellarFlareActive = {}
    stellarFlareEndTime = {}
    starSurgeCount = 0
    starsurgeAstralSpender = true
    furyOfElune = false
    furyOfEluneActive = false
    furyOfEluneEndTime = 0
    convokeCooldown = false
    fullMoonCount = 0
    forceOfNature = false
    treeOfLifeFormActive = false
    powerInfusionActive = false
    powerInfusionEndTime = 0
    shiftPowerActive = false
    shiftPowerEndTime = 0
    shiftPowerDuration = 0
    sunKingBlessingEndTime = 0
    sunKingBlessingActive = false
    oneWithNatureActive = false
    oneWithNatureEndTime = 0
    oneWithNatureStacks = 0
    umbralIntensity = false
    umbralIntensityStacks = 0
    umbralIntensityEndTime = 0
    solstice = false
    solsticeStacks = 0
    solsticeEndTime = 0
    touchOfElune = false
    touchOfEluneStacks = 0
    touchOfEluneEndTime = 0
    frenziedRegen = false
    frenziedRegenActive = false
    frenziedRegenEndTime = 0
    inRange = false
    isMoving = false
    starsurge = false
    starfire = false
    wrath = false
    sunfire = false
    moonfire = false
    stellarFlare = false
    starfall = false
    newMoon = false
    halfMoon = false
    fullMoon = false
    shootingStars = false
    celestialAlignment = false
    incarnationChosen = false
    balanceOfAll = false
    solarbeam = false
    natures_wrath = false
    twin_moons = false
    stellarDrift = false
    soul_of_the_forest = false
    starlord = false
    stellar_inspiration = false
    natures_balance = false
    astral_communion = false
    force_of_nature = false
    warrior_of_elune = false
    oneths_clear_vision = false
    oneths_perception = false
    power_of_goldrinn = false
    primordial_arcanic_pulsar = false
    orbital_strike = false
    starweavers_weft = false
    tireless_pursuit = false
    starfall_eclipse = false
    convoke_the_spirits = false
    well_honed_instincts = false
    killer_instinct = false
    elunes_guidance = false
    orbit_breaker = false
    denizen_of_the_dream = false
    fury_of_elune = false
    balance_of_all_things = false
    radiant_moonlight = false
    arcanic_pulsar = false
    solstice_alignment = false
    touch_the_cosmos = false
    inMeleeRange = false
    playerHealth = 100
    
    API.PrintDebug("Balance Druid state reset on spec change")
    
    return true
end

-- Return the module for loading
return Balance