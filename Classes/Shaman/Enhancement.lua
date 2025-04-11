------------------------------------------
-- WindrunnerRotations - Enhancement Shaman Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Enhancement = {}
-- This will be assigned to addon.Classes.Shaman.Enhancement when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Shaman

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentMainhandEnchant = nil
local currentOffhandEnchant = nil
local currentMaelstrom = 0
local maxMaelstrom = 10
local feral_spiritActive = false
local feral_spiritEndTime = 0
local crashLightningActive = false
local crashLightningEndTime = 0
local ascendanceActive = false
local ascendanceEndTime = 0
local earthShieldActive = false
local earthShieldEndTime = 0
local earthenSpikeActive = {}
local earthenSpikeEndTime = {}
local flameShockActive = {}
local flameShockEndTime = {}
local frostShockActive = {}
local frostShockEndTime = {}
local stormstrikeResets = 0
local maelstromWeaponStacks = 0
local maelstromWeaponEndTime = 0
local hotHandActive = false
local hotHandEndTime = 0
local stormbringerActive = false
local stormbringerEndTime = 0
local windstrikeActive = false
local iceStrikeActive = false
local iceStrikeEndTime = 0
local primordialWaveActive = false
local primordialWaveEndTime = 0
local elementalSpiritWolfUptime = 0
local elementalSpiritWolfStacks = 0
local lightningShieldActive = false
local lightningShieldEndTime = 0
local lightningShieldOverchargeStacks = 0
local doomWindsActive = false
local doomWindsEndTime = 0
local elementalBlastActive = false
local elementalBlastEndTime = 0
local refreshableLashingFlames = false
local forcefulWindsActive = false
local forcefulWindsEndTime = 0
local forcefulWindsStacks = 0
local crashingStorms = false
local alphaWolf = false
local elementalSpirits = false
local elementalAssault = false
local windFury = false
local sundering = false
local stormflurry = false
local fireNova = false
local hotHand = false
local lavaLash = false
local feralSpirit = false
local primalPrimordial = false
local legacyOfTheFrostWitch = false
local witchDoctorsWolf = false
local flurryOfFists = false
local maelstromWeaponChainheal = false
local thunderousPaws = false
local astralShift = false
local spiritWalk = false
local ancestralGuidance = false
local healingStream = false
local swirlingCurrents = false
local inMeleeRange = false
local playerHealth = 100

-- Constants
local ENHANCEMENT_SPEC_ID = 263
local DEFAULT_AOE_THRESHOLD = 3
local FERAL_SPIRIT_DURATION = 15 -- seconds
local CRASH_LIGHTNING_DURATION = 10 -- seconds (buff duration)
local ASCENDANCE_DURATION = 15 -- seconds
local FLAME_SHOCK_DURATION = 18 -- seconds (base)
local FROST_SHOCK_DURATION = 6 -- seconds
local EARTHEN_SPIKE_DURATION = 10 -- seconds
local ELEMENTAL_BLAST_DURATION = 10 -- seconds
local HOT_HAND_DURATION = 10 -- seconds
local STORMBRINGER_DURATION = 12 -- seconds
local ICE_STRIKE_DURATION = 6 -- seconds
local PRIMORDIAL_WAVE_DURATION = 20 -- seconds
local LIGHTNING_SHIELD_DURATION = 1800 -- seconds (30 minutes)
local DOOM_WINDS_DURATION = 8 -- seconds
local FORCEFUL_WINDS_DURATION = 12 -- seconds
local EARTH_SHIELD_DURATION = 600 -- seconds (10 minutes)
local MELEE_RANGE = 5 -- yards

-- Initialize the Enhancement module
function Enhancement:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Enhancement Shaman module initialized")
    
    return true
end

-- Register spell IDs
function Enhancement:RegisterSpells()
    -- Core rotational abilities
    spells.STORMSTRIKE = 17364
    spells.CRASH_LIGHTNING = 187874
    spells.LAVA_LASH = 60103
    spells.WINDFURY_WEAPON = 33757
    spells.FLAMETONGUE_WEAPON = 318038
    spells.WINDFURY_TOTEM = 8512
    spells.FROST_SHOCK = 196840
    spells.FLAME_SHOCK = 188389
    spells.FERAL_SPIRIT = 51533
    spells.LIGHTNING_BOLT = 188196
    spells.CHAIN_LIGHTNING = 188443
    spells.ASCENDANCE = 114051
    spells.WINDSTRIKE = 115356
    spells.SUNDERING = 197214
    spells.EARTHEN_SPIKE = 188089
    spells.ELEMENTAL_BLAST = 117014
    
    -- Core utilities
    spells.ASTRAL_SHIFT = 108271
    spells.SPIRIT_WALK = 58875
    spells.WIND_SHEAR = 57994
    spells.HEX = 51514
    spells.CAPACITOR_TOTEM = 192058
    spells.EARTHBIND_TOTEM = 2484
    spells.TREMOR_TOTEM = 8143
    spells.EARTH_ELEMENTAL = 198103
    spells.ANCESTRAL_GUIDANCE = 108281
    spells.HEALING_STREAM_TOTEM = 5394
    spells.PURGE = 370
    
    -- Core defensives and healing
    spells.LIGHTNING_SHIELD = 192106
    spells.EARTH_SHIELD = 974
    spells.HEALING_SURGE = 8004
    spells.CHAIN_HEAL = 1064
    
    -- Talents and passives
    spells.MAELSTROM_WEAPON = 187880
    spells.STORMBRINGER = 201845
    spells.HOT_HAND = 201900
    spells.HAILSTORM = 334195
    spells.STORMFLURRY = 344357
    spells.FIRE_NOVA = 333974
    spells.ICE_STRIKE = 342240
    spells.WINDFURY = 33757
    spells.LIGHTNING_SHIELD_OVERCHARGE = 319930
    spells.SPIRIT_WOLVES = 51533
    spells.ELEMENTAL_SPIRITS = 262624
    spells.ALPHA_WOLF = 198434
    spells.DOOM_WINDS = 384352
    spells.ELEMENTAL_ASSAULT = 210853
    spells.LASHING_FLAMES = 334046
    spells.FORCEFUL_WINDS = 262647
    spells.PRIMORDIAL_WAVE = 375982
    spells.WOLVES_CLOTHING = 390386
    spells.THORIMS_INVOCATION = 384444
    spells.SWIRLING_MAELSTROM = 384359
    spells.IMPROVED_MAELSTROM_WEAPON = 383303
    spells.STATIC_ACCUMULATION = 384143
    spells.LEGACY_OF_THE_FROST_WITCH = 384450
    spells.ELEMENTAL_SPIRITS = 262624
    spells.UNLEASH_FLAME = 165462
    spells.TEMPEST = 381867
    spells.CRASHING_STORMS = 334308
    spells.PRIMAL_LAVA_ACTUATORS = 408024
    spells.IMPROVED_FLAMETONGUE_WEAPON = 382027
    spells.IMPROVED_LIGHTNING_SHIELD = 381936
    spells.IMPROVED_WINDFURY_TOTEM = 382215
    spells.WITCH_DOCTORS_WOLF_BONES = 394651
    spells.FLURRY_OF_FISTS = 394945
    spells.SWIRLING_CURRENTS = 378094
    spells.THUNDEROUS_PAWS = 378075
    spells.NATURES_GUARDIAN = 30884
    spells.ANCESTRAL_WOLF_AFFINITY = 382197
    spells.PURGING_RITES = 393984
    
    -- War Within Season 2 specific
    spells.SPIRIT_WOLVES_DURATION = 383010
    spells.PRIMAL_PRIMORDIAL = 386474
    spells.MAELSTROM_WEAPON_CHAIN_HEAL = 381726
    spells.STORMBLAST = 319930
    spells.CONVERGING_STORMS = 384363
    spells.FERAL_LUNGE = -1 -- Placeholder
    
    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.CHAIN_HARVEST = 320674
    spells.VESPER_TOTEM = 324386
    spells.PRIMORDIAL_WAVE = 375982
    spells.FAEUNIO = 323547
    
    -- Buff IDs
    spells.CRASH_LIGHTNING_BUFF = 187878
    spells.MAELSTROM_WEAPON_BUFF = 344179
    spells.STORMBRINGER_BUFF = 201846
    spells.HOT_HAND_BUFF = 215785
    spells.ELEMENTAL_BLAST_BUFF = 118522
    spells.LIGHTNING_SHIELD_BUFF = 192106
    spells.LIGHTNING_SHIELD_OVERCHARGE_BUFF = 319930
    spells.WINDFURY_TOTEM_BUFF = 327942
    spells.FERAL_SPIRIT_BUFF = 333957
    spells.ASCENDANCE_BUFF = 114051
    spells.PRIMORDIAL_WAVE_BUFF = 327164
    spells.FORCEFUL_WINDS_BUFF = 262652
    spells.LASHING_FLAMES_BUFF = 334168
    spells.EARTH_SHIELD_BUFF = 974
    spells.DOOM_WINDS_BUFF = 384352
    
    -- Debuff IDs
    spells.FLAME_SHOCK_DEBUFF = 188389
    spells.FROST_SHOCK_DEBUFF = 196840
    spells.EARTHEN_SPIKE_DEBUFF = 188089
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        if spellID > 0 then -- Skip placeholders
            API.RegisterSpell(spellID)
        end
    end
    
    -- Define aura tracking
    buffs.CRASH_LIGHTNING = spells.CRASH_LIGHTNING_BUFF
    buffs.MAELSTROM_WEAPON = spells.MAELSTROM_WEAPON_BUFF
    buffs.STORMBRINGER = spells.STORMBRINGER_BUFF
    buffs.HOT_HAND = spells.HOT_HAND_BUFF
    buffs.ELEMENTAL_BLAST = spells.ELEMENTAL_BLAST_BUFF
    buffs.LIGHTNING_SHIELD = spells.LIGHTNING_SHIELD_BUFF
    buffs.LIGHTNING_SHIELD_OVERCHARGE = spells.LIGHTNING_SHIELD_OVERCHARGE_BUFF
    buffs.WINDFURY_TOTEM = spells.WINDFURY_TOTEM_BUFF
    buffs.FERAL_SPIRIT = spells.FERAL_SPIRIT_BUFF
    buffs.ASCENDANCE = spells.ASCENDANCE_BUFF
    buffs.PRIMORDIAL_WAVE = spells.PRIMORDIAL_WAVE_BUFF
    buffs.FORCEFUL_WINDS = spells.FORCEFUL_WINDS_BUFF
    buffs.LASHING_FLAMES = spells.LASHING_FLAMES_BUFF
    buffs.EARTH_SHIELD = spells.EARTH_SHIELD_BUFF
    buffs.DOOM_WINDS = spells.DOOM_WINDS_BUFF
    
    debuffs.FLAME_SHOCK = spells.FLAME_SHOCK_DEBUFF
    debuffs.FROST_SHOCK = spells.FROST_SHOCK_DEBUFF
    debuffs.EARTHEN_SPIKE = spells.EARTHEN_SPIKE_DEBUFF
    
    return true
end

-- Register variables to track
function Enhancement:RegisterVariables()
    -- Talent tracking
    talents.hasStormbringer = false
    talents.hasHotHand = false
    talents.hasHailstorm = false
    talents.hasStormflurry = false
    talents.hasFireNova = false
    talents.hasIceStrike = false
    talents.hasWindfury = false
    talents.hasLightningShieldOvercharge = false
    talents.hasSpiritWolves = false
    talents.hasElementalSpirits = false
    talents.hasAlphaWolf = false
    talents.hasDoomWinds = false
    talents.hasElementalAssault = false
    talents.hasLashingFlames = false
    talents.hasForcefulWinds = false
    talents.hasPrimordialWave = false
    talents.hasWolvesClothing = false
    talents.hasTHorimsInvocation = false
    talents.hasSwirlingMaelstrom = false
    talents.hasImprovedMaelstromWeapon = false
    talents.hasStaticAccumulation = false
    talents.hasLegacyOfTheFrostWitch = false
    talents.hasElementalSpirits = false
    talents.hasUnleashFlame = false
    talents.hasTempest = false
    talents.hasCrashingStorms = false
    talents.hasPrimalLavaActuators = false
    talents.hasImprovedFlametongueWeapon = false
    talents.hasImprovedLightningShield = false
    talents.hasImprovedWindfuryTotem = false
    talents.hasWitchDoctorsWolfBones = false
    talents.hasFlurryOfFists = false
    talents.hasSwirlingCurrents = false
    talents.hasThunderousPaws = false
    talents.hasNaturesGuardian = false
    talents.hasAncestralWolfAffinity = false
    talents.hasPurgingRites = false
    
    -- War Within Season 2 talents
    talents.hasSpiritWolvesDuration = false
    talents.hasPrimalPrimordial = false
    talents.hasMaelstromWeaponChainHeal = false
    talents.hasStormblast = false
    talents.hasConvergingStorms = false
    
    -- Initialize weapon enchants
    currentMainhandEnchant = API.GetWeaponEnchant("main", true)
    currentOffhandEnchant = API.GetWeaponEnchant("off", true)
    
    -- Initialize tracking tables
    flameShockActive = {}
    flameShockEndTime = {}
    frostShockActive = {}
    frostShockEndTime = {}
    earthenSpikeActive = {}
    earthenSpikeEndTime = {}
    
    return true
end

-- Register spec-specific settings
function Enhancement:RegisterSettings()
    ConfigRegistry:RegisterSettings("EnhancementShaman", {
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
            autoWeaponEnchants = {
                displayName = "Auto Weapon Enchants",
                description = "Automatically apply weapon enchants",
                type = "toggle",
                default = true
            },
            maintainWindfuryTotem = {
                displayName = "Maintain Windfury Totem",
                description = "Automatically keep Windfury Totem up",
                type = "toggle",
                default = true
            },
            flameShockAoELimit = {
                displayName = "Flame Shock Target Limit",
                description = "Maximum targets to apply Flame Shock in AoE",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            },
            flameShockRefreshThreshold = {
                displayName = "Flame Shock Refresh Threshold",
                description = "Seconds remaining to refresh Flame Shock",
                type = "slider",
                min = 1,
                max = 8,
                default = 6
            },
            useFeralSpirit = {
                displayName = "Use Feral Spirit",
                description = "Automatically use Feral Spirit",
                type = "toggle",
                default = true
            },
            maelstromWeaponDump = {
                displayName = "Maelstrom Weapon Stack Dump",
                description = "Stacks of Maelstrom Weapon to use spells at",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            },
            lightningBoltMinStacks = {
                displayName = "Lightning Bolt Min MW Stacks",
                description = "Minimum Maelstrom Weapon stacks to cast Lightning Bolt",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            },
            chainLightningMinStacks = {
                displayName = "Chain Lightning Min MW Stacks",
                description = "Minimum Maelstrom Weapon stacks to cast Chain Lightning",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            }
        },
        
        cooldownSettings = {
            useAscendance = {
                displayName = "Use Ascendance",
                description = "Automatically use Ascendance",
                type = "toggle",
                default = true
            },
            ascendanceMode = {
                displayName = "Ascendance Usage",
                description = "When to use Ascendance",
                type = "dropdown",
                options = {"On Cooldown", "With Feral Spirit", "Burst Only"},
                default = "On Cooldown"
            },
            useDoomWinds = {
                displayName = "Use Doom Winds",
                description = "Automatically use Doom Winds when talented",
                type = "toggle",
                default = true
            },
            doomWindsMode = {
                displayName = "Doom Winds Usage",
                description = "When to use Doom Winds",
                type = "dropdown",
                options = {"On Cooldown", "With Ascendance", "Burst Only"},
                default = "On Cooldown"
            },
            useSundering = {
                displayName = "Use Sundering",
                description = "Automatically use Sundering when talented",
                type = "toggle",
                default = true
            },
            sunderingMinTargets = {
                displayName = "Sundering Min Targets",
                description = "Minimum targets to use Sundering",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            useEarthenSpike = {
                displayName = "Use Earthen Spike",
                description = "Automatically use Earthen Spike when talented",
                type = "toggle",
                default = true
            },
            useElementalBlast = {
                displayName = "Use Elemental Blast",
                description = "Automatically use Elemental Blast when talented",
                type = "toggle",
                default = true
            },
            elementalBlastMinStacks = {
                displayName = "Elemental Blast Min MW Stacks",
                description = "Minimum Maelstrom Weapon stacks to cast Elemental Blast",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            }
        },
        
        defensiveSettings = {
            useAstralShift = {
                displayName = "Use Astral Shift",
                description = "Automatically use Astral Shift",
                type = "toggle",
                default = true
            },
            astralShiftThreshold = {
                displayName = "Astral Shift Health Threshold",
                description = "Health percentage to use Astral Shift",
                type = "slider",
                min = 20,
                max = 80,
                default = 50
            },
            useEarthShield = {
                displayName = "Use Earth Shield",
                description = "Automatically maintain Earth Shield on self",
                type = "toggle",
                default = true
            },
            useLightningShield = {
                displayName = "Use Lightning Shield",
                description = "Automatically maintain Lightning Shield",
                type = "toggle",
                default = true
            },
            useSpiritWalk = {
                displayName = "Use Spirit Walk",
                description = "Automatically use Spirit Walk for movement",
                type = "toggle",
                default = true
            },
            useHealingSurge = {
                displayName = "Use Healing Surge",
                description = "Automatically use Healing Surge for healing",
                type = "toggle",
                default = true
            },
            healingSurgeThreshold = {
                displayName = "Healing Surge Health Threshold",
                description = "Health percentage to use Healing Surge",
                type = "slider",
                min = 20,
                max = 80,
                default = 35
            },
            healingSurgeMinStacks = {
                displayName = "Healing Surge Min MW Stacks",
                description = "Minimum Maelstrom Weapon stacks to cast Healing Surge",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            },
            useChainHeal = {
                displayName = "Use Chain Heal",
                description = "Automatically use Chain Heal for group healing",
                type = "toggle",
                default = true
            },
            chainHealThreshold = {
                displayName = "Chain Heal Health Threshold",
                description = "Health percentage to use Chain Heal",
                type = "slider",
                min = 20,
                max = 80,
                default = 50
            },
            chainHealMinStacks = {
                displayName = "Chain Heal Min MW Stacks",
                description = "Minimum Maelstrom Weapon stacks to cast Chain Heal",
                type = "slider",
                min = 1,
                max = 10,
                default = 5
            },
            useAncestralGuidance = {
                displayName = "Use Ancestral Guidance",
                description = "Automatically use Ancestral Guidance when talented",
                type = "toggle",
                default = true
            },
            ancestralGuidanceThreshold = {
                displayName = "Ancestral Guidance Health Threshold",
                description = "Health percentage to use Ancestral Guidance",
                type = "slider",
                min = 20,
                max = 80,
                default = 40
            }
        },
        
        utilitySettings = {
            useWindShear = {
                displayName = "Use Wind Shear",
                description = "Automatically use Wind Shear for interrupts",
                type = "toggle",
                default = true
            },
            useCapacitorTotem = {
                displayName = "Use Capacitor Totem",
                description = "Automatically use Capacitor Totem for AoE stun",
                type = "toggle",
                default = true
            },
            capacitorTotemMinTargets = {
                displayName = "Capacitor Totem Min Targets",
                description = "Minimum targets to use Capacitor Totem",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useEarthbindTotem = {
                displayName = "Use Earthbind Totem",
                description = "Automatically use Earthbind Totem for AoE slow",
                type = "toggle",
                default = true
            },
            useTremorTotem = {
                displayName = "Use Tremor Totem",
                description = "Automatically use Tremor Totem against fears",
                type = "toggle",
                default = true
            },
            useEarthElemental = {
                displayName = "Use Earth Elemental",
                description = "Automatically use Earth Elemental",
                type = "toggle",
                default = true
            },
            earthElementalMode = {
                displayName = "Earth Elemental Usage",
                description = "When to use Earth Elemental",
                type = "dropdown",
                options = {"Emergency Only", "On Cooldown", "Manual Only"},
                default = "Emergency Only"
            },
            useHealingStreamTotem = {
                displayName = "Use Healing Stream Totem",
                description = "Automatically use Healing Stream Totem",
                type = "toggle",
                default = true
            },
            healingStreamThreshold = {
                displayName = "Healing Stream Health Threshold",
                description = "Health percentage to use Healing Stream Totem",
                type = "slider",
                min = 20,
                max = 90,
                default = 70
            },
            usePurge = {
                displayName = "Use Purge",
                description = "Automatically use Purge on enemies",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Ascendance controls
            ascendance = AAC.RegisterAbility(spells.ASCENDANCE, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithFeralSpirit = false,
                requireCrashLightning = false
            }),
            
            -- Feral Spirit controls
            feralSpirit = AAC.RegisterAbility(spells.FERAL_SPIRIT, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithAscendance = false,
                useInAOE = true
            }),
            
            -- Doom Winds controls
            doomWinds = AAC.RegisterAbility(spells.DOOM_WINDS, {
                enabled = true,
                useDuringBurstOnly = false,
                prioritizeOverAscendance = false,
                minTargets = 1
            })
        }
    })
    
    return true
end

-- Register for events 
function Enhancement:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for maelstrom updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "MAELSTROM" then
            self:UpdateMaelstrom()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        end
    end)
    
    -- Register for weapon enchant updates
    API.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function() 
        self:UpdateWeaponEnchants() 
    end)
    
    API.RegisterEvent("ENCHANT_APPLIED", function()
        self:UpdateWeaponEnchants()
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
    
    -- Initial weapon enchant check
    self:UpdateWeaponEnchants()
    
    return true
end

-- Update talent information
function Enhancement:UpdateTalentInfo()
    -- Check for important talents
    talents.hasStormbringer = API.HasTalent(spells.STORMBRINGER)
    talents.hasHotHand = API.HasTalent(spells.HOT_HAND)
    talents.hasHailstorm = API.HasTalent(spells.HAILSTORM)
    talents.hasStormflurry = API.HasTalent(spells.STORMFLURRY)
    talents.hasFireNova = API.HasTalent(spells.FIRE_NOVA)
    talents.hasIceStrike = API.HasTalent(spells.ICE_STRIKE)
    talents.hasWindfury = API.HasTalent(spells.WINDFURY)
    talents.hasLightningShieldOvercharge = API.HasTalent(spells.LIGHTNING_SHIELD_OVERCHARGE)
    talents.hasSpiritWolves = API.HasTalent(spells.SPIRIT_WOLVES)
    talents.hasElementalSpirits = API.HasTalent(spells.ELEMENTAL_SPIRITS)
    talents.hasAlphaWolf = API.HasTalent(spells.ALPHA_WOLF)
    talents.hasDoomWinds = API.HasTalent(spells.DOOM_WINDS)
    talents.hasElementalAssault = API.HasTalent(spells.ELEMENTAL_ASSAULT)
    talents.hasLashingFlames = API.HasTalent(spells.LASHING_FLAMES)
    talents.hasForcefulWinds = API.HasTalent(spells.FORCEFUL_WINDS)
    talents.hasPrimordialWave = API.HasTalent(spells.PRIMORDIAL_WAVE)
    talents.hasWolvesClothing = API.HasTalent(spells.WOLVES_CLOTHING)
    talents.hasTHorimsInvocation = API.HasTalent(spells.THORIMS_INVOCATION)
    talents.hasSwirlingMaelstrom = API.HasTalent(spells.SWIRLING_MAELSTROM)
    talents.hasImprovedMaelstromWeapon = API.HasTalent(spells.IMPROVED_MAELSTROM_WEAPON)
    talents.hasStaticAccumulation = API.HasTalent(spells.STATIC_ACCUMULATION)
    talents.hasLegacyOfTheFrostWitch = API.HasTalent(spells.LEGACY_OF_THE_FROST_WITCH)
    talents.hasElementalSpirits = API.HasTalent(spells.ELEMENTAL_SPIRITS)
    talents.hasUnleashFlame = API.HasTalent(spells.UNLEASH_FLAME)
    talents.hasTempest = API.HasTalent(spells.TEMPEST)
    talents.hasCrashingStorms = API.HasTalent(spells.CRASHING_STORMS)
    talents.hasPrimalLavaActuators = API.HasTalent(spells.PRIMAL_LAVA_ACTUATORS)
    talents.hasImprovedFlametongueWeapon = API.HasTalent(spells.IMPROVED_FLAMETONGUE_WEAPON)
    talents.hasImprovedLightningShield = API.HasTalent(spells.IMPROVED_LIGHTNING_SHIELD)
    talents.hasImprovedWindfuryTotem = API.HasTalent(spells.IMPROVED_WINDFURY_TOTEM)
    talents.hasWitchDoctorsWolfBones = API.HasTalent(spells.WITCH_DOCTORS_WOLF_BONES)
    talents.hasFlurryOfFists = API.HasTalent(spells.FLURRY_OF_FISTS)
    talents.hasSwirlingCurrents = API.HasTalent(spells.SWIRLING_CURRENTS)
    talents.hasThunderousPaws = API.HasTalent(spells.THUNDEROUS_PAWS)
    talents.hasNaturesGuardian = API.HasTalent(spells.NATURES_GUARDIAN)
    talents.hasAncestralWolfAffinity = API.HasTalent(spells.ANCESTRAL_WOLF_AFFINITY)
    talents.hasPurgingRites = API.HasTalent(spells.PURGING_RITES)
    
    -- War Within Season 2 talents
    talents.hasSpiritWolvesDuration = API.HasTalent(spells.SPIRIT_WOLVES_DURATION)
    talents.hasPrimalPrimordial = API.HasTalent(spells.PRIMAL_PRIMORDIAL)
    talents.hasMaelstromWeaponChainHeal = API.HasTalent(spells.MAELSTROM_WEAPON_CHAIN_HEAL)
    talents.hasStormblast = API.HasTalent(spells.STORMBLAST)
    talents.hasConvergingStorms = API.HasTalent(spells.CONVERGING_STORMS)
    
    -- Set specialized variables based on talents
    if talents.hasCrashingStorms then
        crashingStorms = true
    end
    
    if talents.hasAlphaWolf then
        alphaWolf = true
    end
    
    if talents.hasElementalSpirits then
        elementalSpirits = true
    end
    
    if talents.hasElementalAssault then
        elementalAssault = true
    end
    
    if talents.hasWindfury then
        windFury = true
    end
    
    if API.IsSpellKnown(spells.SUNDERING) then
        sundering = true
    end
    
    if talents.hasStormflurry then
        stormflurry = true
    end
    
    if talents.hasFireNova then
        fireNova = true
    end
    
    if talents.hasHotHand then
        hotHand = true
    end
    
    if API.IsSpellKnown(spells.LAVA_LASH) then
        lavaLash = true
    end
    
    if API.IsSpellKnown(spells.FERAL_SPIRIT) then
        feralSpirit = true
    end
    
    if talents.hasPrimalPrimordial then
        primalPrimordial = true
    end
    
    if talents.hasLegacyOfTheFrostWitch then
        legacyOfTheFrostWitch = true
    end
    
    if talents.hasWitchDoctorsWolfBones then
        witchDoctorsWolf = true
    end
    
    if talents.hasFlurryOfFists then
        flurryOfFists = true
    end
    
    if talents.hasMaelstromWeaponChainHeal then
        maelstromWeaponChainheal = true
    end
    
    if talents.hasThunderousPaws then
        thunderousPaws = true
    end
    
    if API.IsSpellKnown(spells.ASTRAL_SHIFT) then
        astralShift = true
    end
    
    if API.IsSpellKnown(spells.SPIRIT_WALK) then
        spiritWalk = true
    end
    
    if talents.hasAncestralGuidance then
        ancestralGuidance = true
    end
    
    if API.IsSpellKnown(spells.HEALING_STREAM_TOTEM) then
        healingStream = true
    end
    
    if talents.hasSwirlingCurrents then
        swirlingCurrents = true
    end
    
    API.PrintDebug("Enhancement Shaman talents updated")
    
    return true
end

-- Update Maelstrom tracking
function Enhancement:UpdateMaelstrom()
    currentMaelstrom = API.GetPlayerPower()
    maelstromWeaponStacks = select(4, API.GetBuffInfo("player", buffs.MAELSTROM_WEAPON)) or 0
    
    if maelstromWeaponStacks > 0 then
        maelstromWeaponEndTime = select(6, API.GetBuffInfo("player", buffs.MAELSTROM_WEAPON))
    else
        maelstromWeaponEndTime = 0
    end
    
    return true
end

-- Update health tracking
function Enhancement:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update weapon enchants
function Enhancement:UpdateWeaponEnchants()
    currentMainhandEnchant = API.GetWeaponEnchant("main", true)
    currentOffhandEnchant = API.GetWeaponEnchant("off", true)
    return true
end

-- Update target data
function Enhancement:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Flame Shock
        local flameShockInfo = API.GetDebuffInfo(targetGUID, debuffs.FLAME_SHOCK)
        if flameShockInfo then
            flameShockActive[targetGUID] = true
            flameShockEndTime[targetGUID] = select(6, flameShockInfo)
        else
            flameShockActive[targetGUID] = false
            flameShockEndTime[targetGUID] = 0
        end
        
        -- Check for Frost Shock
        local frostShockInfo = API.GetDebuffInfo(targetGUID, debuffs.FROST_SHOCK)
        if frostShockInfo then
            frostShockActive[targetGUID] = true
            frostShockEndTime[targetGUID] = select(6, frostShockInfo)
        else
            frostShockActive[targetGUID] = false
            frostShockEndTime[targetGUID] = 0
        end
        
        -- Check for Earthen Spike
        if talents.hasEarthenSpike then
            local earthenSpikeInfo = API.GetDebuffInfo(targetGUID, debuffs.EARTHEN_SPIKE)
            if earthenSpikeInfo then
                earthenSpikeActive[targetGUID] = true
                earthenSpikeEndTime[targetGUID] = select(6, earthenSpikeInfo)
            else
                earthenSpikeActive[targetGUID] = false
                earthenSpikeEndTime[targetGUID] = 0
            end
        end
        
        -- Check for Lashing Flames refresh opportunity
        if talents.hasLashingFlames and flameShockActive[targetGUID] then
            local remainingDuration = flameShockEndTime[targetGUID] - GetTime()
            refreshableLashingFlames = remainingDuration < FLAME_SHOCK_DURATION * 0.3 -- 30% time remaining
        else
            refreshableLashingFlames = false
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Crash Lightning radius
    
    return true
end

-- Handle combat log events
function Enhancement:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Crash Lightning
            if spellID == buffs.CRASH_LIGHTNING then
                crashLightningActive = true
                crashLightningEndTime = GetTime() + CRASH_LIGHTNING_DURATION
                API.PrintDebug("Crash Lightning buff activated")
            end
            
            -- Track Stormbringer
            if spellID == buffs.STORMBRINGER then
                stormbringerActive = true
                stormbringerEndTime = GetTime() + STORMBRINGER_DURATION
                stormstrikeResets = stormstrikeResets + 1
                API.PrintDebug("Stormbringer proc activated")
            end
            
            -- Track Hot Hand
            if spellID == buffs.HOT_HAND then
                hotHandActive = true
                hotHandEndTime = GetTime() + HOT_HAND_DURATION
                API.PrintDebug("Hot Hand proc activated")
            end
            
            -- Track Maelstrom Weapon stacks
            if spellID == buffs.MAELSTROM_WEAPON then
                maelstromWeaponStacks = select(4, API.GetBuffInfo("player", buffs.MAELSTROM_WEAPON)) or 1
                maelstromWeaponEndTime = select(6, API.GetBuffInfo("player", buffs.MAELSTROM_WEAPON))
                API.PrintDebug("Maelstrom Weapon: " .. tostring(maelstromWeaponStacks) .. " stacks")
            end
            
            -- Track Elemental Blast
            if spellID == buffs.ELEMENTAL_BLAST then
                elementalBlastActive = true
                elementalBlastEndTime = GetTime() + ELEMENTAL_BLAST_DURATION
                API.PrintDebug("Elemental Blast activated")
            end
            
            -- Track Lightning Shield
            if spellID == buffs.LIGHTNING_SHIELD then
                lightningShieldActive = true
                lightningShieldEndTime = GetTime() + LIGHTNING_SHIELD_DURATION
                API.PrintDebug("Lightning Shield activated")
            end
            
            -- Track Lightning Shield Overcharge
            if spellID == buffs.LIGHTNING_SHIELD_OVERCHARGE then
                lightningShieldOverchargeStacks = select(4, API.GetBuffInfo("player", buffs.LIGHTNING_SHIELD_OVERCHARGE)) or 1
                API.PrintDebug("Lightning Shield Overcharge: " .. tostring(lightningShieldOverchargeStacks) .. " stacks")
            end
            
            -- Track Feral Spirit
            if spellID == buffs.FERAL_SPIRIT then
                feral_spiritActive = true
                feral_spiritEndTime = GetTime() + FERAL_SPIRIT_DURATION
                API.PrintDebug("Feral Spirit activated")
            end
            
            -- Track Ascendance
            if spellID == buffs.ASCENDANCE then
                ascendanceActive = true
                ascendanceEndTime = GetTime() + ASCENDANCE_DURATION
                API.PrintDebug("Ascendance activated")
            end
            
            -- Track Primordial Wave
            if spellID == buffs.PRIMORDIAL_WAVE then
                primordialWaveActive = true
                primordialWaveEndTime = GetTime() + PRIMORDIAL_WAVE_DURATION
                API.PrintDebug("Primordial Wave activated")
            end
            
            -- Track Forceful Winds
            if spellID == buffs.FORCEFUL_WINDS then
                forcefulWindsActive = true
                forcefulWindsStacks = select(4, API.GetBuffInfo("player", buffs.FORCEFUL_WINDS)) or 1
                forcefulWindsEndTime = select(6, API.GetBuffInfo("player", buffs.FORCEFUL_WINDS))
                API.PrintDebug("Forceful Winds activated: " .. tostring(forcefulWindsStacks) .. " stacks")
            end
            
            -- Track Earth Shield
            if spellID == buffs.EARTH_SHIELD then
                earthShieldActive = true
                earthShieldEndTime = GetTime() + EARTH_SHIELD_DURATION
                API.PrintDebug("Earth Shield activated")
            end
            
            -- Track Doom Winds
            if spellID == buffs.DOOM_WINDS then
                doomWindsActive = true
                doomWindsEndTime = GetTime() + DOOM_WINDS_DURATION
                API.PrintDebug("Doom Winds activated")
            end
        end
        
        -- Track debuff applications on any target
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Flame Shock
            if spellID == debuffs.FLAME_SHOCK then
                flameShockActive[destGUID] = true
                flameShockEndTime[destGUID] = GetTime() + FLAME_SHOCK_DURATION
                API.PrintDebug("Flame Shock applied to " .. destName)
            end
            
            -- Track Frost Shock
            if spellID == debuffs.FROST_SHOCK then
                frostShockActive[destGUID] = true
                frostShockEndTime[destGUID] = GetTime() + FROST_SHOCK_DURATION
                API.PrintDebug("Frost Shock applied to " .. destName)
            end
            
            -- Track Earthen Spike
            if spellID == debuffs.EARTHEN_SPIKE then
                earthenSpikeActive[destGUID] = true
                earthenSpikeEndTime[destGUID] = GetTime() + EARTHEN_SPIKE_DURATION
                API.PrintDebug("Earthen Spike applied to " .. destName)
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Crash Lightning
            if spellID == buffs.CRASH_LIGHTNING then
                crashLightningActive = false
                API.PrintDebug("Crash Lightning faded")
            end
            
            -- Track Stormbringer
            if spellID == buffs.STORMBRINGER then
                stormbringerActive = false
                API.PrintDebug("Stormbringer faded")
            end
            
            -- Track Hot Hand
            if spellID == buffs.HOT_HAND then
                hotHandActive = false
                API.PrintDebug("Hot Hand faded")
            end
            
            -- Track Maelstrom Weapon
            if spellID == buffs.MAELSTROM_WEAPON then
                maelstromWeaponStacks = 0
                maelstromWeaponEndTime = 0
                API.PrintDebug("Maelstrom Weapon faded")
            end
            
            -- Track Elemental Blast
            if spellID == buffs.ELEMENTAL_BLAST then
                elementalBlastActive = false
                API.PrintDebug("Elemental Blast faded")
            end
            
            -- Track Lightning Shield
            if spellID == buffs.LIGHTNING_SHIELD then
                lightningShieldActive = false
                API.PrintDebug("Lightning Shield faded")
            end
            
            -- Track Feral Spirit
            if spellID == buffs.FERAL_SPIRIT then
                feral_spiritActive = false
                API.PrintDebug("Feral Spirit faded")
            end
            
            -- Track Ascendance
            if spellID == buffs.ASCENDANCE then
                ascendanceActive = false
                windstrikeActive = false
                API.PrintDebug("Ascendance faded")
            end
            
            -- Track Primordial Wave
            if spellID == buffs.PRIMORDIAL_WAVE then
                primordialWaveActive = false
                API.PrintDebug("Primordial Wave faded")
            end
            
            -- Track Forceful Winds
            if spellID == buffs.FORCEFUL_WINDS then
                forcefulWindsActive = false
                forcefulWindsStacks = 0
                API.PrintDebug("Forceful Winds faded")
            end
            
            -- Track Earth Shield
            if spellID == buffs.EARTH_SHIELD then
                earthShieldActive = false
                API.PrintDebug("Earth Shield faded")
            end
            
            -- Track Doom Winds
            if spellID == buffs.DOOM_WINDS then
                doomWindsActive = false
                API.PrintDebug("Doom Winds faded")
            end
        end
        
        -- Track debuff removals
        if sourceGUID == API.GetPlayerGUID() then
            -- Track Flame Shock
            if spellID == debuffs.FLAME_SHOCK and flameShockActive[destGUID] then
                flameShockActive[destGUID] = false
                flameShockEndTime[destGUID] = 0
                API.PrintDebug("Flame Shock faded from " .. destName)
            end
            
            -- Track Frost Shock
            if spellID == debuffs.FROST_SHOCK and frostShockActive[destGUID] then
                frostShockActive[destGUID] = false
                frostShockEndTime[destGUID] = 0
                API.PrintDebug("Frost Shock faded from " .. destName)
            end
            
            -- Track Earthen Spike
            if spellID == debuffs.EARTHEN_SPIKE and earthenSpikeActive[destGUID] then
                earthenSpikeActive[destGUID] = false
                earthenSpikeEndTime[destGUID] = 0
                API.PrintDebug("Earthen Spike faded from " .. destName)
            end
        end
    end
    
    -- Track Maelstrom Weapon stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.MAELSTROM_WEAPON and destGUID == API.GetPlayerGUID() then
        maelstromWeaponStacks = select(4, API.GetBuffInfo("player", buffs.MAELSTROM_WEAPON)) or 0
        maelstromWeaponEndTime = select(6, API.GetBuffInfo("player", buffs.MAELSTROM_WEAPON))
        API.PrintDebug("Maelstrom Weapon stacks: " .. tostring(maelstromWeaponStacks))
    end
    
    -- Track Lightning Shield Overcharge stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.LIGHTNING_SHIELD_OVERCHARGE and destGUID == API.GetPlayerGUID() then
        lightningShieldOverchargeStacks = select(4, API.GetBuffInfo("player", buffs.LIGHTNING_SHIELD_OVERCHARGE)) or 0
        API.PrintDebug("Lightning Shield Overcharge stacks: " .. tostring(lightningShieldOverchargeStacks))
    end
    
    -- Track Forceful Winds stacks gain
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FORCEFUL_WINDS and destGUID == API.GetPlayerGUID() then
        forcefulWindsStacks = select(4, API.GetBuffInfo("player", buffs.FORCEFUL_WINDS)) or 0
        API.PrintDebug("Forceful Winds stacks: " .. tostring(forcefulWindsStacks))
    end
    
    -- Track Elemental Spirit Wolf stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.FERAL_SPIRIT and destGUID == API.GetPlayerGUID() then
        elementalSpiritWolfStacks = select(4, API.GetBuffInfo("player", buffs.FERAL_SPIRIT)) or 0
        elementalSpiritWolfUptime = select(6, API.GetBuffInfo("player", buffs.FERAL_SPIRIT))
        API.PrintDebug("Elemental Spirit Wolf stacks: " .. tostring(elementalSpiritWolfStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if sourceGUID == API.GetPlayerGUID() then
            if spellID == spells.STORMSTRIKE then
                API.PrintDebug("Stormstrike cast")
            elseif spellID == spells.WINDSTRIKE then
                API.PrintDebug("Windstrike cast")
                windstrikeActive = true
            elseif spellID == spells.CRASH_LIGHTNING then
                crashLightningActive = true
                crashLightningEndTime = GetTime() + CRASH_LIGHTNING_DURATION
                API.PrintDebug("Crash Lightning cast")
            elseif spellID == spells.LAVA_LASH then
                API.PrintDebug("Lava Lash cast")
            elseif spellID == spells.WINDFURY_WEAPON then
                API.PrintDebug("Windfury Weapon applied")
            elseif spellID == spells.FLAMETONGUE_WEAPON then
                API.PrintDebug("Flametongue Weapon applied")
            elseif spellID == spells.WINDFURY_TOTEM then
                API.PrintDebug("Windfury Totem cast")
            elseif spellID == spells.FROST_SHOCK then
                API.PrintDebug("Frost Shock cast")
            elseif spellID == spells.FLAME_SHOCK then
                -- Update flame shock tracking in the next combat event
                API.PrintDebug("Flame Shock cast")
            elseif spellID == spells.FERAL_SPIRIT then
                feral_spiritActive = true
                feral_spiritEndTime = GetTime() + FERAL_SPIRIT_DURATION
                API.PrintDebug("Feral Spirit cast")
            elseif spellID == spells.LIGHTNING_BOLT then
                API.PrintDebug("Lightning Bolt cast")
            elseif spellID == spells.CHAIN_LIGHTNING then
                API.PrintDebug("Chain Lightning cast")
            elseif spellID == spells.ASCENDANCE then
                ascendanceActive = true
                ascendanceEndTime = GetTime() + ASCENDANCE_DURATION
                windstrikeActive = true
                API.PrintDebug("Ascendance cast")
            elseif spellID == spells.SUNDERING then
                API.PrintDebug("Sundering cast")
            elseif spellID == spells.EARTHEN_SPIKE then
                -- Update earthen spike tracking in the next combat event
                API.PrintDebug("Earthen Spike cast")
            elseif spellID == spells.ELEMENTAL_BLAST then
                elementalBlastActive = true
                elementalBlastEndTime = GetTime() + ELEMENTAL_BLAST_DURATION
                API.PrintDebug("Elemental Blast cast")
            elseif spellID == spells.LIGHTNING_SHIELD then
                lightningShieldActive = true
                lightningShieldEndTime = GetTime() + LIGHTNING_SHIELD_DURATION
                API.PrintDebug("Lightning Shield cast")
            elseif spellID == spells.EARTH_SHIELD then
                earthShieldActive = true
                earthShieldEndTime = GetTime() + EARTH_SHIELD_DURATION
                API.PrintDebug("Earth Shield cast")
            elseif spellID == spells.PRIMORDIAL_WAVE then
                primordialWaveActive = true
                primordialWaveEndTime = GetTime() + PRIMORDIAL_WAVE_DURATION
                API.PrintDebug("Primordial Wave cast")
            elseif spellID == spells.ICE_STRIKE then
                iceStrikeActive = true
                iceStrikeEndTime = GetTime() + ICE_STRIKE_DURATION
                API.PrintDebug("Ice Strike cast")
            elseif spellID == spells.DOOM_WINDS then
                doomWindsActive = true
                doomWindsEndTime = GetTime() + DOOM_WINDS_DURATION
                API.PrintDebug("Doom Winds cast")
            elseif spellID == spells.FIRE_NOVA then
                API.PrintDebug("Fire Nova cast")
            end
        end
    end
    
    -- Check for special reset events like Stormflurry procs
    if eventType == "SPELL_DAMAGE" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.STORMSTRIKE or spellID == spells.WINDSTRIKE then
            if talents.hasStormflurry then
                -- Stormflurry has a chance to reset Stormstrike
                local stormflurryRoll = math.random(100)
                if stormflurryRoll <= 25 then -- 25% chance for Stormflurry
                    stormstrikeResets = stormstrikeResets + 1
                    API.PrintDebug("Stormflurry proc")
                end
            end
        end
    end
    
    return true
end

-- Main rotation function
function Enhancement:RunRotation()
    -- Check if we should be running Enhancement Shaman logic
    if API.GetActiveSpecID() ~= ENHANCEMENT_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("EnhancementShaman")
    
    -- Update variables
    self:UpdateMaelstrom()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Maintain weapon enchants
    if settings.rotationSettings.autoWeaponEnchants then
        -- Apply Windfury to mainhand if missing
        if not currentMainhandEnchant and API.CanCast(spells.WINDFURY_WEAPON) then
            API.CastSpell(spells.WINDFURY_WEAPON)
            return true
        end
        
        -- Apply Flametongue to offhand if missing
        if not currentOffhandEnchant and API.CanCast(spells.FLAMETONGUE_WEAPON) then
            API.CastSpell(spells.FLAMETONGUE_WEAPON)
            return true
        end
    end
    
    -- Maintain Windfury Totem
    if settings.rotationSettings.maintainWindfuryTotem and 
       not API.GroupHasBuff(buffs.WINDFURY_TOTEM) and
       API.CanCast(spells.WINDFURY_TOTEM) then
        API.CastSpell(spells.WINDFURY_TOTEM)
        return true
    end
    
    -- Maintain Lightning Shield
    if settings.defensiveSettings.useLightningShield and
       not lightningShieldActive and
       API.CanCast(spells.LIGHTNING_SHIELD) then
        API.CastSpell(spells.LIGHTNING_SHIELD)
        return true
    end
    
    -- Maintain Earth Shield
    if settings.defensiveSettings.useEarthShield and
       not earthShieldActive and
       API.CanCast(spells.EARTH_SHIELD) then
        API.CastSpellOnUnit(spells.EARTH_SHIELD, "player")
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
    
    -- Skip if not in melee range and no ranged options
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
function Enhancement:HandleInterrupts(settings)
    -- Use Wind Shear for interrupts
    if settings.utilitySettings.useWindShear and
       API.CanCast(spells.WIND_SHEAR) and
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.WIND_SHEAR)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Enhancement:HandleDefensives(settings)
    -- Use Astral Shift
    if astralShift and
       settings.defensiveSettings.useAstralShift and
       playerHealth <= settings.defensiveSettings.astralShiftThreshold and
       API.CanCast(spells.ASTRAL_SHIFT) then
        API.CastSpell(spells.ASTRAL_SHIFT)
        return true
    end
    
    -- Use Healing Surge for emergency healing
    if settings.defensiveSettings.useHealingSurge and
       playerHealth <= settings.defensiveSettings.healingSurgeThreshold and
       maelstromWeaponStacks >= settings.defensiveSettings.healingSurgeMinStacks and
       API.CanCast(spells.HEALING_SURGE) then
        API.CastSpellOnUnit(spells.HEALING_SURGE, "player")
        return true
    end
    
    -- Use Chain Heal for group healing
    if settings.defensiveSettings.useChainHeal and
       maelstromWeaponChainheal and
       API.GetLowestGroupMemberHealth() <= settings.defensiveSettings.chainHealThreshold and
       maelstromWeaponStacks >= settings.defensiveSettings.chainHealMinStacks and
       API.CanCast(spells.CHAIN_HEAL) then
        API.CastSpellOnUnit(spells.CHAIN_HEAL, API.GetLowestGroupMember())
        return true
    end
    
    -- Use Ancestral Guidance
    if ancestralGuidance and
       settings.defensiveSettings.useAncestralGuidance and
       playerHealth <= settings.defensiveSettings.ancestralGuidanceThreshold and
       API.CanCast(spells.ANCESTRAL_GUIDANCE) then
        API.CastSpell(spells.ANCESTRAL_GUIDANCE)
        return true
    end
    
    -- Use Healing Stream Totem
    if healingStream and
       settings.utilitySettings.useHealingStreamTotem and
       playerHealth <= settings.utilitySettings.healingStreamThreshold and
       API.CanCast(spells.HEALING_STREAM_TOTEM) then
        API.CastSpell(spells.HEALING_STREAM_TOTEM)
        return true
    end
    
    -- Use Spirit Walk to break roots/slows
    if spiritWalk and
       settings.defensiveSettings.useSpiritWalk and
       API.IsPlayerRooted() and
       API.CanCast(spells.SPIRIT_WALK) then
        API.CastSpell(spells.SPIRIT_WALK)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Enhancement:HandleRangedAbilities(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Apply Flame Shock if needed
    if targetGUID and 
       (not flameShockActive[targetGUID] or 
        (flameShockActive[targetGUID] and 
         flameShockEndTime[targetGUID] - GetTime() < settings.rotationSettings.flameShockRefreshThreshold)) and
       API.CanCast(spells.FLAME_SHOCK) then
        API.CastSpell(spells.FLAME_SHOCK)
        return true
    end
    
    -- Use Frost Shock for damage at range
    if API.CanCast(spells.FROST_SHOCK) then
        API.CastSpell(spells.FROST_SHOCK)
        return true
    end
    
    -- Use Lightning Bolt with Maelstrom Weapon stacks
    if maelstromWeaponStacks >= settings.rotationSettings.lightningBoltMinStacks and
       API.CanCast(spells.LIGHTNING_BOLT) then
        API.CastSpell(spells.LIGHTNING_BOLT)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Enhancement:HandleCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode or not in combat
    if not API.IsInCombat() then
        return false
    end
    
    -- Use Feral Spirit
    if feralSpirit and
       settings.rotationSettings.useFeralSpirit and
       not feral_spiritActive and
       settings.abilityControls.feralSpirit.enabled and
       API.CanCast(spells.FERAL_SPIRIT) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.feralSpirit.useDuringBurstOnly or burstModeActive then
            -- Check if should use with Ascendance
            if not settings.abilityControls.feralSpirit.useWithAscendance or ascendanceActive then
                -- Check if can be used in AoE
                if settings.abilityControls.feralSpirit.useInAOE or currentAoETargets < settings.rotationSettings.aoeThreshold then
                    API.CastSpell(spells.FERAL_SPIRIT)
                    return true
                end
            end
        end
    end
    
    -- Use Ascendance
    if API.HasTalent(spells.ASCENDANCE) and
       settings.cooldownSettings.useAscendance and
       not ascendanceActive and
       settings.abilityControls.ascendance.enabled and
       API.CanCast(spells.ASCENDANCE) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.ascendance.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseAscendance = false
            
            if settings.cooldownSettings.ascendanceMode == "On Cooldown" then
                shouldUseAscendance = true
            elseif settings.cooldownSettings.ascendanceMode == "With Feral Spirit" then
                shouldUseAscendance = feral_spiritActive
            elseif settings.cooldownSettings.ascendanceMode == "Burst Only" then
                shouldUseAscendance = burstModeActive
            end
            
            if settings.abilityControls.ascendance.requireCrashLightning and not crashLightningActive then
                shouldUseAscendance = false
            end
            
            if shouldUseAscendance then
                API.CastSpell(spells.ASCENDANCE)
                return true
            end
        end
    end
    
    -- Use Doom Winds
    if talents.hasDoomWinds and
       settings.cooldownSettings.useDoomWinds and
       not doomWindsActive and
       settings.abilityControls.doomWinds.enabled and
       API.CanCast(spells.DOOM_WINDS) then
        
        -- Check if should only use during burst
        if not settings.abilityControls.doomWinds.useDuringBurstOnly or burstModeActive then
            -- Check additional requirements
            local shouldUseDoomWinds = false
            
            if settings.cooldownSettings.doomWindsMode == "On Cooldown" then
                shouldUseDoomWinds = true
            elseif settings.cooldownSettings.doomWindsMode == "With Ascendance" then
                shouldUseDoomWinds = ascendanceActive
            elseif settings.cooldownSettings.doomWindsMode == "Burst Only" then
                shouldUseDoomWinds = burstModeActive
            end
            
            if currentAoETargets < settings.abilityControls.doomWinds.minTargets then
                shouldUseDoomWinds = false
            end
            
            if shouldUseDoomWinds then
                -- Check if we should prioritize Doom Winds over Ascendance
                if settings.abilityControls.doomWinds.prioritizeOverAscendance and 
                   API.GetSpellCooldown(spells.ASCENDANCE) < 10 then
                    -- Save for Ascendance
                    return false
                end
                
                API.CastSpell(spells.DOOM_WINDS)
                return true
            end
        end
    end
    
    -- Use Primordial Wave if talented
    if talents.hasPrimordialWave and
       not primordialWaveActive and
       API.CanCast(spells.PRIMORDIAL_WAVE) then
        API.CastSpellAtTarget(spells.PRIMORDIAL_WAVE)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Enhancement:HandleAoERotation(settings)
    -- Apply Flame Shock to multiple targets
    if currentAoETargets <= settings.rotationSettings.flameShockAoELimit then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and 
           (not flameShockActive[targetGUID] or 
            (flameShockActive[targetGUID] and 
             flameShockEndTime[targetGUID] - GetTime() < settings.rotationSettings.flameShockRefreshThreshold)) and
           API.CanCast(spells.FLAME_SHOCK) then
            API.CastSpell(spells.FLAME_SHOCK)
            return true
        end
    end
    
    -- Use Sundering for AoE damage and control
    if sundering and
       settings.cooldownSettings.useSundering and
       currentAoETargets >= settings.cooldownSettings.sunderingMinTargets and
       API.CanCast(spells.SUNDERING) then
        API.CastSpellInFrontOfPlayer(spells.SUNDERING)
        return true
    end
    
    -- Use Crash Lightning for AoE damage and buff
    if API.CanCast(spells.CRASH_LIGHTNING) then
        API.CastSpell(spells.CRASH_LIGHTNING)
        return true
    end
    
    -- Use Chain Lightning with Maelstrom Weapon stacks
    if maelstromWeaponStacks >= settings.rotationSettings.chainLightningMinStacks and
       API.CanCast(spells.CHAIN_LIGHTNING) then
        API.CastSpell(spells.CHAIN_LIGHTNING)
        return true
    end
    
    -- Use Fire Nova if talented and Flame Shock is active on any target
    if fireNova and
       API.CanCast(spells.FIRE_NOVA) and
       self:HasFlameShockActive() then
        API.CastSpell(spells.FIRE_NOVA)
        return true
    end
    
    -- Use Ice Strike if talented
    if talents.hasIceStrike and
       API.CanCast(spells.ICE_STRIKE) then
        API.CastSpell(spells.ICE_STRIKE)
        return true
    end
    
    -- Use Stormstrike/Windstrike for AoE benefit after Crash Lightning
    if crashLightningActive then
        if ascendanceActive and API.CanCast(spells.WINDSTRIKE) then
            API.CastSpell(spells.WINDSTRIKE)
            return true
        elseif API.CanCast(spells.STORMSTRIKE) then
            API.CastSpell(spells.STORMSTRIKE)
            return true
        end
    end
    
    -- Use Lava Lash for AoE spread of Flame Shock
    if lavaLash and API.CanCast(spells.LAVA_LASH) then
        API.CastSpell(spells.LAVA_LASH)
        return true
    end
    
    -- Use Frost Shock for AoE damage with Hailstorm
    if talents.hasHailstorm and API.CanCast(spells.FROST_SHOCK) then
        API.CastSpell(spells.FROST_SHOCK)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Enhancement:HandleSingleTargetRotation(settings)
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    -- Apply Flame Shock if needed
    if targetGUID and 
       (not flameShockActive[targetGUID] or 
        (flameShockActive[targetGUID] and 
         flameShockEndTime[targetGUID] - GetTime() < settings.rotationSettings.flameShockRefreshThreshold)) and
       API.CanCast(spells.FLAME_SHOCK) then
        API.CastSpell(spells.FLAME_SHOCK)
        return true
    end
    
    -- Use Earthen Spike if talented
    if talents.hasEarthenSpike and
       settings.cooldownSettings.useEarthenSpike and
       API.CanCast(spells.EARTHEN_SPIKE) then
        API.CastSpell(spells.EARTHEN_SPIKE)
        return true
    end
    
    -- Use Elemental Blast if talented
    if talents.hasElementalBlast and
       settings.cooldownSettings.useElementalBlast and
       maelstromWeaponStacks >= settings.cooldownSettings.elementalBlastMinStacks and
       API.CanCast(spells.ELEMENTAL_BLAST) then
        API.CastSpell(spells.ELEMENTAL_BLAST)
        return true
    end
    
    -- Use Stormstrike/Windstrike
    if ascendanceActive and API.CanCast(spells.WINDSTRIKE) then
        API.CastSpell(spells.WINDSTRIKE)
        return true
    elseif API.CanCast(spells.STORMSTRIKE) then
        API.CastSpell(spells.STORMSTRIKE)
        return true
    end
    
    -- Use Crash Lightning for buff even in single target
    if not crashLightningActive and API.CanCast(spells.CRASH_LIGHTNING) then
        API.CastSpell(spells.CRASH_LIGHTNING)
        return true
    end
    
    -- Use Lava Lash, prioritize with Hot Hand active
    if lavaLash and
       (hotHandActive or API.CanCast(spells.LAVA_LASH)) then
        API.CastSpell(spells.LAVA_LASH)
        return true
    end
    
    -- Use Ice Strike if talented
    if talents.hasIceStrike and
       API.CanCast(spells.ICE_STRIKE) then
        API.CastSpell(spells.ICE_STRIKE)
        return true
    end
    
    -- Use Frost Shock with Hailstorm
    if talents.hasHailstorm and API.CanCast(spells.FROST_SHOCK) then
        API.CastSpell(spells.FROST_SHOCK)
        return true
    end
    
    -- Use Lightning Bolt as filler with Maelstrom Weapon stacks
    if maelstromWeaponStacks >= settings.rotationSettings.lightningBoltMinStacks and
       API.CanCast(spells.LIGHTNING_BOLT) then
        API.CastSpell(spells.LIGHTNING_BOLT)
        return true
    end
    
    -- Use Frost Shock as a filler
    if API.CanCast(spells.FROST_SHOCK) then
        API.CastSpell(spells.FROST_SHOCK)
        return true
    end
    
    return false
end

-- Check if Flame Shock is active on any target
function Enhancement:HasFlameShockActive()
    for guid, active in pairs(flameShockActive) do
        if active and flameShockEndTime[guid] > GetTime() then
            return true
        end
    end
    return false
end

-- Handle specialization change
function Enhancement:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentMainhandEnchant = nil
    currentOffhandEnchant = nil
    currentMaelstrom = 0
    maxMaelstrom = 10
    feral_spiritActive = false
    feral_spiritEndTime = 0
    crashLightningActive = false
    crashLightningEndTime = 0
    ascendanceActive = false
    ascendanceEndTime = 0
    earthShieldActive = false
    earthShieldEndTime = 0
    earthenSpikeActive = {}
    earthenSpikeEndTime = {}
    flameShockActive = {}
    flameShockEndTime = {}
    frostShockActive = {}
    frostShockEndTime = {}
    stormstrikeResets = 0
    maelstromWeaponStacks = 0
    maelstromWeaponEndTime = 0
    hotHandActive = false
    hotHandEndTime = 0
    stormbringerActive = false
    stormbringerEndTime = 0
    windstrikeActive = false
    iceStrikeActive = false
    iceStrikeEndTime = 0
    primordialWaveActive = false
    primordialWaveEndTime = 0
    elementalSpiritWolfUptime = 0
    elementalSpiritWolfStacks = 0
    lightningShieldActive = false
    lightningShieldEndTime = 0
    lightningShieldOverchargeStacks = 0
    doomWindsActive = false
    doomWindsEndTime = 0
    elementalBlastActive = false
    elementalBlastEndTime = 0
    refreshableLashingFlames = false
    forcefulWindsActive = false
    forcefulWindsEndTime = 0
    forcefulWindsStacks = 0
    crashingStorms = false
    alphaWolf = false
    elementalSpirits = false
    elementalAssault = false
    windFury = false
    sundering = false
    stormflurry = false
    fireNova = false
    hotHand = false
    lavaLash = false
    feralSpirit = false
    primalPrimordial = false
    legacyOfTheFrostWitch = false
    witchDoctorsWolf = false
    flurryOfFists = false
    maelstromWeaponChainheal = false
    thunderousPaws = false
    astralShift = false
    spiritWalk = false
    ancestralGuidance = false
    healingStream = false
    swirlingCurrents = false
    inMeleeRange = false
    playerHealth = 100
    
    API.PrintDebug("Enhancement Shaman state reset on spec change")
    
    return true
end

-- Return the module for loading
return Enhancement