------------------------------------------
-- WindrunnerRotations - Elemental Shaman Module
-- Author: VortexQ8
------------------------------------------

local Elemental = {}
-- This will be assigned to addon.Classes.Shaman.Elemental when loaded

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
local currentMaelstrom = 0
local maxMaelstrom = 100
local lavaBurstCharges = 0
local haveLavaSurge = false
local earthShockReady = false
local earthquakeReady = false
local flameShockTargets = {}
local stormkeeperActive = false
local echoesOfGreatSundering = 0
local earthquakeCast = 0
local primordalWaveActive = false
local maelstromWeaponStacks = 0
local lastEarthquakeTime = 0
local icefuryActive = false
local fireElementalActive = false
local stormElementalActive = false
local ascendanceActive = false
local liquidMagmaTotemActive = false
local vesperTotemActive = false
local primordialWaveCount = 0 -- LvB empowered by Primordial Wave
local lightningBoltCasts = 0 -- For Master of the Elements

-- Constants
local ELEMENTAL_SPEC_ID = 262
local DEFAULT_AOE_THRESHOLD = 3
local EARTHQUAKE_MAELSTROM_COST = 60
local EARTH_SHOCK_MAELSTROM_COST = 60
local FLAMESHOCK_REFRESH_THRESHOLD = 5.4 -- Time (in seconds) to start flameshock refresh
local STORM_ELEMENTAL_DURATION = 30
local FIRE_ELEMENTAL_DURATION = 30
local ASCENDANCE_DURATION = 15

-- Initialize the Elemental module
function Elemental:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Elemental Shaman module initialized")
    
    return true
end

-- Register spell IDs
function Elemental:RegisterSpells()
    -- Main rotational abilities
    spells.LIGHTNING_BOLT = 188196
    spells.LAVA_BURST = 51505
    spells.EARTH_SHOCK = 8042
    spells.EARTHQUAKE = 61882
    spells.FLAME_SHOCK = 188389
    spells.CHAIN_LIGHTNING = 188443
    spells.FROST_SHOCK = 196840
    spells.ELEMENTAL_BLAST = 117014
    
    -- Cooldowns
    spells.FIRE_ELEMENTAL = 198067
    spells.STORM_ELEMENTAL = 192249
    spells.STORMKEEPER = 191634
    spells.ASCENDANCE = 114050
    spells.LIQUID_MAGMA_TOTEM = 192222
    spells.ICEFURY = 210714
    spells.CAPACITOR_TOTEM = 192058
    spells.EARTH_ELEMENTAL = 198103
    spells.TREMOR_TOTEM = 8143
    spells.WIND_SHEAR = 57994
    
    -- Covenant abilities
    spells.VESPER_TOTEM = 324386
    spells.PRIMORDIAL_WAVE = 326059
    spells.CHAIN_HARVEST = 320674
    spells.FAE_TRANSFUSION = 328923
    
    -- Defensive/Utility
    spells.ASTRAL_SHIFT = 108271
    spells.SPIRIT_WALK = 58875
    spells.THUNDERSTORM = 51490
    spells.SPIRITWALKERS_GRACE = 79206
    spells.PURGE = 370
    spells.ANCESTRAL_GUIDANCE = 108281
    spells.WIND_RUSH_TOTEM = 192077
    spells.EARTH_SHIELD = 974
    
    -- Procs and buffs
    spells.LAVA_SURGE = 77762
    spells.MASTER_OF_THE_ELEMENTS = 16166
    spells.MASTER_OF_THE_ELEMENTS_BUFF = 260734
    spells.STORMKEEPER_BUFF = 191634
    spells.ECHOES_OF_GREAT_SUNDERING = 336215
    spells.ECHOES_OF_GREAT_SUNDERING_BUFF = 336217
    spells.WINDSPEAKERS_LAVA_RESURGENCE = 336063
    spells.WINDSPEAKERS_LAVA_RESURGENCE_BUFF = 336065
    spells.ICEFURY_BUFF = 210714
    spells.ASCENDANCE_BUFF = 114050
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.LAVA_SURGE = spells.LAVA_SURGE
    buffs.MASTER_OF_THE_ELEMENTS = spells.MASTER_OF_THE_ELEMENTS_BUFF
    buffs.STORMKEEPER = spells.STORMKEEPER_BUFF
    buffs.ECHOES_OF_GREAT_SUNDERING = spells.ECHOES_OF_GREAT_SUNDERING_BUFF
    buffs.WINDSPEAKERS_LAVA_RESURGENCE = spells.WINDSPEAKERS_LAVA_RESURGENCE_BUFF
    buffs.ICEFURY = spells.ICEFURY_BUFF
    buffs.ASCENDANCE = spells.ASCENDANCE_BUFF
    
    debuffs.FLAME_SHOCK = spells.FLAME_SHOCK
    
    return true
end

-- Register variables to track
function Elemental:RegisterVariables()
    -- Talent tracking
    talents.hasElementalBlast = false
    talents.hasEchoesOfGreatSundering = false
    talents.hasStormkeeper = false
    talents.hasIcefury = false
    talents.hasStormElemental = false
    talents.hasMasterOfTheElements = false
    talents.hasLiquidMagmaTotem = false
    talents.hasAscendance = false
    talents.hasEcho = false
    talents.hasStaticDischarge = false
    talents.hasUnlimitedPower = false
    talents.hasNaturalOrder = false
    talents.hasPrimalElementalist = false
    talents.hasWindspeakersLavaResurgence = false
    talents.hasAncestralGuidance = false
    talents.hasSpiritWolves = false
    talents.hasEarthShield = false
    talents.hasFlowingWaters = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Elemental:RegisterSettings()
    ConfigRegistry:RegisterSettings("ElementalShaman", {
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
            maintainFlameShock = {
                displayName = "Maintain Flame Shock",
                description = "Keep Flame Shock active on targets",
                type = "toggle",
                default = true
            },
            flameShockMaxTargets = {
                displayName = "Flame Shock Max Targets",
                description = "Maximum targets to maintain Flame Shock on",
                type = "slider",
                min = 1, 
                max = 6,
                default = 3
            },
            useFrostShock = {
                displayName = "Use Frost Shock",
                description = "Use Frost Shock when moving",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useFireElemental = {
                displayName = "Use Fire Elemental",
                description = "Automatically use Fire Elemental",
                type = "toggle",
                default = true
            },
            useStormElemental = {
                displayName = "Use Storm Elemental",
                description = "Automatically use Storm Elemental when talented",
                type = "toggle",
                default = true
            },
            useStormkeeper = {
                displayName = "Use Stormkeeper",
                description = "Automatically use Stormkeeper when talented",
                type = "toggle",
                default = true
            },
            useAscendance = {
                displayName = "Use Ascendance",
                description = "Automatically use Ascendance when talented",
                type = "toggle",
                default = true
            },
            useIcefury = {
                displayName = "Use Icefury",
                description = "Automatically use Icefury when talented",
                type = "toggle",
                default = true
            },
            useLiquidMagmaTotem = {
                displayName = "Use Liquid Magma Totem",
                description = "Automatically use Liquid Magma Totem when talented",
                type = "toggle",
                default = true
            },
            useEarthElemental = {
                displayName = "Use Earth Elemental",
                description = "Automatically use Earth Elemental when low health",
                type = "toggle",
                default = true
            },
            staggerElementals = {
                displayName = "Stagger Elemental Cooldowns",
                description = "Don't use Fire and Storm elemental together",
                type = "toggle",
                default = true
            }
        },
        
        covenantSettings = {
            useVesperTotem = {
                displayName = "Use Vesper Totem",
                description = "Automatically use Vesper Totem (Kyrian)",
                type = "toggle",
                default = true
            },
            usePrimordialWave = {
                displayName = "Use Primordial Wave",
                description = "Automatically use Primordial Wave (Necrolord)",
                type = "toggle",
                default = true
            },
            useChainHarvest = {
                displayName = "Use Chain Harvest",
                description = "Automatically use Chain Harvest (Venthyr)",
                type = "toggle",
                default = true
            },
            useFaeTransfusion = {
                displayName = "Use Fae Transfusion",
                description = "Automatically use Fae Transfusion (Night Fae)",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            maelstromPooling = {
                displayName = "Maelstrom Pooling",
                description = "Maelstrom to pool for AoE situations",
                type = "slider",
                min = 0,
                max = 100,
                default = 80
            },
            useEarthShock = {
                displayName = "Use Earth Shock",
                description = "When to use Earth Shock",
                type = "dropdown",
                options = {"At Cap", "At Cost", "With Maelstrom Weapon"},
                default = "At Cost"
            },
            useElementalBlast = {
                displayName = "Use Elemental Blast",
                description = "When to use Elemental Blast",
                type = "dropdown",
                options = {"On Cooldown", "With Buffs", "Never"},
                default = "On Cooldown"
            },
            useStormkeeperForAoE = {
                displayName = "Stormkeeper for AoE",
                description = "Save Stormkeeper for AoE situations",
                type = "toggle",
                default = true
            },
            useEchoingShock = {
                displayName = "Use Echoing Shock",
                description = "When to use Echoing Shock",
                type = "dropdown",
                options = {"With Earthquake", "With Lava Burst", "With Lightning Bolt"},
                default = "With Earthquake"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Fire Elemental controls
            fireElemental = AAC.RegisterAbility(spells.FIRE_ELEMENTAL, {
                enabled = true,
                useDuringBurstOnly = true,
                minFightLengthRemaining = 0
            }),
            
            -- Liquid Magma Totem controls
            liquidMagmaTotem = AAC.RegisterAbility(spells.LIQUID_MAGMA_TOTEM, {
                enabled = true,
                minEnemies = 2,
                useWithFireElemental = true
            }),
            
            -- Stormkeeper controls
            stormkeeper = AAC.RegisterAbility(spells.STORMKEEPER, {
                enabled = true,
                useForAoEOnly = false,
                forceUsage = false
            })
        }
    })
    
    return true
end

-- Register for events 
function Elemental:RegisterEvents()
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
function Elemental:UpdateTalentInfo()
    -- Check for important talents
    talents.hasElementalBlast = API.HasTalent(spells.ELEMENTAL_BLAST)
    talents.hasEchoesOfGreatSundering = API.HasTalent(spells.ECHOES_OF_GREAT_SUNDERING)
    talents.hasStormkeeper = API.HasTalent(spells.STORMKEEPER)
    talents.hasIcefury = API.HasTalent(spells.ICEFURY)
    talents.hasStormElemental = API.HasTalent(spells.STORM_ELEMENTAL)
    talents.hasMasterOfTheElements = API.HasTalent(spells.MASTER_OF_THE_ELEMENTS)
    talents.hasLiquidMagmaTotem = API.HasTalent(spells.LIQUID_MAGMA_TOTEM)
    talents.hasAscendance = API.HasTalent(spells.ASCENDANCE)
    talents.hasWindspeakersLavaResurgence = API.HasTalent(spells.WINDSPEAKERS_LAVA_RESURGENCE)
    talents.hasAncestralGuidance = API.HasTalent(spells.ANCESTRAL_GUIDANCE)
    talents.hasEarthShield = API.HasTalent(spells.EARTH_SHIELD)
    
    API.PrintDebug("Elemental Shaman talents updated")
    
    return true
end

-- Update maelstrom tracking
function Elemental:UpdateMaelstrom()
    currentMaelstrom = API.GetPlayerPower()
    
    -- Update thresholds
    earthShockReady = (currentMaelstrom >= EARTH_SHOCK_MAELSTROM_COST)
    earthquakeReady = (currentMaelstrom >= EARTHQUAKE_MAELSTROM_COST)
    
    return true
end

-- Update target data
function Elemental:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                flameShock = false,
                flameShockExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Elemental AoE radius
    
    return true
end

-- Handle combat log events
function Elemental:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Lava Surge
            if spellID == buffs.LAVA_SURGE then
                haveLavaSurge = true
                API.PrintDebug("Lava Surge proc activated")
            end
            
            -- Track Master of the Elements
            if spellID == buffs.MASTER_OF_THE_ELEMENTS then
                API.PrintDebug("Master of the Elements activated")
            end
            
            -- Track Stormkeeper
            if spellID == buffs.STORMKEEPER then
                stormkeeperActive = true
                API.PrintDebug("Stormkeeper activated")
            end
            
            -- Track Echoes of Great Sundering
            if spellID == buffs.ECHOES_OF_GREAT_SUNDERING then
                echoesOfGreatSundering = API.GetBuffStacks(buffs.ECHOES_OF_GREAT_SUNDERING)
                API.PrintDebug("Echoes of Great Sundering: " .. tostring(echoesOfGreatSundering) .. " stacks")
            end
            
            -- Track Windspeaker's Lava Resurgence
            if spellID == buffs.WINDSPEAKERS_LAVA_RESURGENCE then
                primordalWaveActive = true
                API.PrintDebug("Windspeaker's Lava Resurgence activated")
            end
            
            -- Track Icefury
            if spellID == buffs.ICEFURY then
                icefuryActive = true
                API.PrintDebug("Icefury activated")
            end
            
            -- Track Ascendance
            if spellID == buffs.ASCENDANCE then
                ascendanceActive = true
                API.PrintDebug("Ascendance activated")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == debuffs.FLAME_SHOCK then
                self.targetData[destGUID].flameShock = true
                self.targetData[destGUID].flameShockExpiration = select(6, API.GetDebuffInfo(destGUID, debuffs.FLAME_SHOCK))
                
                -- Track Flame Shock targets
                if not API.TableContains(flameShockTargets, destGUID) then
                    table.insert(flameShockTargets, destGUID)
                end
                
                API.PrintDebug("Flame Shock applied to target")
            end
        end
    end
    
    -- Track buff/debuff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Lava Surge
            if spellID == buffs.LAVA_SURGE then
                haveLavaSurge = false
                API.PrintDebug("Lava Surge consumed")
            end
            
            -- Track Stormkeeper
            if spellID == buffs.STORMKEEPER then
                stormkeeperActive = false
                API.PrintDebug("Stormkeeper faded")
            end
            
            -- Track Echoes of Great Sundering
            if spellID == buffs.ECHOES_OF_GREAT_SUNDERING then
                echoesOfGreatSundering = 0
                API.PrintDebug("Echoes of Great Sundering faded")
            end
            
            -- Track Windspeaker's Lava Resurgence
            if spellID == buffs.WINDSPEAKERS_LAVA_RESURGENCE then
                primordalWaveActive = false
                API.PrintDebug("Windspeaker's Lava Resurgence faded")
            end
            
            -- Track Icefury
            if spellID == buffs.ICEFURY then
                icefuryActive = false
                API.PrintDebug("Icefury faded")
            end
            
            -- Track Ascendance
            if spellID == buffs.ASCENDANCE then
                ascendanceActive = false
                API.PrintDebug("Ascendance faded")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == debuffs.FLAME_SHOCK then
                self.targetData[destGUID].flameShock = false
                API.TableRemove(flameShockTargets, destGUID)
                API.PrintDebug("Flame Shock faded from target")
            end
        end
    end
    
    -- Track special buffs with stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" then
        if destGUID == API.GetPlayerGUID() then
            -- Track Echoes of Great Sundering stacks
            if spellID == buffs.ECHOES_OF_GREAT_SUNDERING then
                echoesOfGreatSundering = select(4, API.GetBuffInfo("player", buffs.ECHOES_OF_GREAT_SUNDERING))
                API.PrintDebug("Echoes of Great Sundering: " .. tostring(echoesOfGreatSundering) .. " stacks")
            end
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        -- Track spell cooldowns and active states
        if spellID == spells.FIRE_ELEMENTAL then
            fireElementalActive = true
            C_Timer.After(FIRE_ELEMENTAL_DURATION, function()
                fireElementalActive = false
            end)
        elseif spellID == spells.STORM_ELEMENTAL then
            stormElementalActive = true
            C_Timer.After(STORM_ELEMENTAL_DURATION, function()
                stormElementalActive = false
            end)
        elseif spellID == spells.ASCENDANCE then
            ascendanceActive = true
            C_Timer.After(ASCENDANCE_DURATION, function()
                ascendanceActive = false
            end)
        elseif spellID == spells.LIQUID_MAGMA_TOTEM then
            liquidMagmaTotemActive = true
            C_Timer.After(15, function() -- LMT lasts 15 seconds
                liquidMagmaTotemActive = false
            end)
        elseif spellID == spells.VESPER_TOTEM then
            vesperTotemActive = true
            C_Timer.After(30, function() -- Vesper lasts 30 seconds
                vesperTotemActive = false
            end)
        elseif spellID == spells.EARTHQUAKE then
            lastEarthquakeTime = GetTime()
            earthquakeCast = earthquakeCast + 1
        elseif spellID == spells.LIGHTNING_BOLT then
            lightningBoltCasts = lightningBoltCasts + 1
        elseif spellID == spells.PRIMORDIAL_WAVE then
            -- Track the Primordial Wave empowerment
            primordialWaveCount = 1 -- Next Lava Burst will be empowered
        elseif spellID == spells.LAVA_BURST then
            -- If this was a Primordial Wave empowered LvB, decrement the counter
            if primordialWaveCount > 0 then
                primordialWaveCount = primordialWaveCount - 1
            end
        end
    end
    
    return true
end

-- Main rotation function
function Elemental:RunRotation()
    -- Check if we should be running Elemental Shaman logic
    if API.GetActiveSpecID() ~= ELEMENTAL_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ElementalShaman")
    
    -- Update variables
    self:UpdateMaelstrom()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    lavaBurstCharges = API.GetSpellCharges(spells.LAVA_BURST) or 0
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle defensive abilities
    if settings.rotationSettings.useDefensives and self:HandleDefensives() then
        return true
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle movement if needed
    if API.IsPlayerMoving() and self:HandleMovement(settings) then
        return true
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle defensive abilities
function Elemental:HandleDefensives()
    -- Use Astral Shift if health is low
    if API.GetPlayerHealthPercent() <= 40 and API.CanCast(spells.ASTRAL_SHIFT) then
        API.CastSpell(spells.ASTRAL_SHIFT)
        return true
    end
    
    -- Use Earth Elemental if health is critical
    if API.GetPlayerHealthPercent() <= 20 and API.CanCast(spells.EARTH_ELEMENTAL) then
        API.CastSpell(spells.EARTH_ELEMENTAL)
        return true
    end
    
    -- Use Earth Shield if talented and not active
    if talents.hasEarthShield and not API.PlayerHasBuff(spells.EARTH_SHIELD) and API.CanCast(spells.EARTH_SHIELD) then
        API.CastSpellOnUnit(spells.EARTH_SHIELD, "player")
        return true
    end
    
    return false
end

-- Handle movement abilities/spells
function Elemental:HandleMovement(settings)
    -- Use Spiritwalker's Grace if available
    if API.CanCast(spells.SPIRITWALKERS_GRACE) then
        API.CastSpell(spells.SPIRITWALKERS_GRACE)
        return true
    end
    
    -- Cast instant Lava Burst if available
    if haveLavaSurge and API.CanCast(spells.LAVA_BURST) then
        API.CastSpell(spells.LAVA_BURST)
        return true
    end
    
    -- Use Frost Shock when moving if enabled
    if settings.rotationSettings.useFrostShock and API.CanCast(spells.FROST_SHOCK) then
        -- Prioritize Icefury empowerment
        if icefuryActive then
            API.CastSpell(spells.FROST_SHOCK)
            return true
        elseif currentMaelstrom >= 20 then
            API.CastSpell(spells.FROST_SHOCK)
            return true
        end
    end
    
    -- Refresh Flame Shock if needed
    if settings.rotationSettings.maintainFlameShock and API.CanCast(spells.FLAME_SHOCK) then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and targetGUID ~= "" and self.targetData[targetGUID] then
            if not self.targetData[targetGUID].flameShock or 
               (self.targetData[targetGUID].flameShockExpiration - GetTime() < FLAMESHOCK_REFRESH_THRESHOLD) then
                API.CastSpell(spells.FLAME_SHOCK)
                return true
            end
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Elemental:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Fire Elemental / Storm Elemental
    if not fireElementalActive and not stormElementalActive then
        if talents.hasStormElemental and 
           settings.cooldownSettings.useStormElemental and
           API.CanCast(spells.STORM_ELEMENTAL) then
            API.CastSpell(spells.STORM_ELEMENTAL)
            return true
        elseif settings.cooldownSettings.useFireElemental and
               API.CanCast(spells.FIRE_ELEMENTAL) then
            API.CastSpell(spells.FIRE_ELEMENTAL)
            return true
        end
    end
    
    -- Use Stormkeeper
    if talents.hasStormkeeper and
       settings.cooldownSettings.useStormkeeper and
       settings.abilityControls.stormkeeper.enabled and
       API.CanCast(spells.STORMKEEPER) then
        
        -- Check if we should save it for AoE
        if not settings.abilityControls.stormkeeper.useForAoEOnly or
           currentAoETargets >= settings.rotationSettings.aoeThreshold or
           settings.abilityControls.stormkeeper.forceUsage then
            API.CastSpell(spells.STORMKEEPER)
            return true
        end
    end
    
    -- Use Ascendance if talented
    if talents.hasAscendance and
       settings.cooldownSettings.useAscendance and
       not ascendanceActive and
       API.CanCast(spells.ASCENDANCE) then
        API.CastSpell(spells.ASCENDANCE)
        return true
    end
    
    -- Use Icefury if talented
    if talents.hasIcefury and
       settings.cooldownSettings.useIcefury and
       not icefuryActive and
       API.CanCast(spells.ICEFURY) then
        API.CastSpell(spells.ICEFURY)
        return true
    end
    
    -- Use Liquid Magma Totem if talented
    if talents.hasLiquidMagmaTotem and
       settings.cooldownSettings.useLiquidMagmaTotem and
       settings.abilityControls.liquidMagmaTotem.enabled and
       currentAoETargets >= settings.abilityControls.liquidMagmaTotem.minEnemies and
       API.CanCast(spells.LIQUID_MAGMA_TOTEM) then
        
        -- Check if we should use with Fire Elemental
        if not settings.abilityControls.liquidMagmaTotem.useWithFireElemental or
           fireElementalActive then
            API.CastSpellAtCursor(spells.LIQUID_MAGMA_TOTEM)
            return true
        end
    end
    
    -- Use Covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle Covenant abilities
function Elemental:HandleCovenantAbilities(settings)
    -- Use Vesper Totem (Kyrian)
    if settings.covenantSettings.useVesperTotem and
       API.CanCast(spells.VESPER_TOTEM) then
        API.CastSpellAtCursor(spells.VESPER_TOTEM)
        return true
    end
    
    -- Use Primordial Wave (Necrolord)
    if settings.covenantSettings.usePrimordialWave and
       API.CanCast(spells.PRIMORDIAL_WAVE) then
        local targetGUID = API.GetTargetGUID()
        
        -- Use it on a target without Flame Shock to maximize value
        if targetGUID and targetGUID ~= "" and
           (not self.targetData[targetGUID] or not self.targetData[targetGUID].flameShock) then
            API.CastSpell(spells.PRIMORDIAL_WAVE)
            return true
        else
            -- Just use it on current target
            API.CastSpell(spells.PRIMORDIAL_WAVE)
            return true
        end
    end
    
    -- Use Chain Harvest (Venthyr)
    if settings.covenantSettings.useChainHarvest and
       API.CanCast(spells.CHAIN_HARVEST) and
       (currentAoETargets >= 2 or burstModeActive) then
        API.CastSpell(spells.CHAIN_HARVEST)
        return true
    end
    
    -- Use Fae Transfusion (Night Fae)
    if settings.covenantSettings.useFaeTransfusion and
       API.CanCast(spells.FAE_TRANSFUSION) then
        API.CastSpell(spells.FAE_TRANSFUSION)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Elemental:HandleAoERotation(settings)
    -- Apply/refresh Flame Shock if maintenance is enabled
    if settings.rotationSettings.maintainFlameShock and API.CanCast(spells.FLAME_SHOCK) then
        -- Get max targets to maintain Flame Shock on
        local maxTargets = settings.rotationSettings.flameShockMaxTargets
        
        -- Only apply Flame Shock if we don't already have it on max targets
        if #flameShockTargets < maxTargets then
            -- Find a target without Flame Shock
            local targetGUID = API.GetTargetGUID()
            
            if targetGUID and targetGUID ~= "" and self.targetData[targetGUID] and 
               (not self.targetData[targetGUID].flameShock or 
                self.targetData[targetGUID].flameShockExpiration - GetTime() < FLAMESHOCK_REFRESH_THRESHOLD) then
                API.CastSpell(spells.FLAME_SHOCK)
                return true
            end
            
            -- Find another target without Flame Shock if current target already has it
            local enemies = API.GetAllEnemies(40)
            for _, guid in ipairs(enemies) do
                if not API.TableContains(flameShockTargets, guid) then
                    API.CastSpellOnGUID(spells.FLAME_SHOCK, guid)
                    return true
                end
            end
        end
    end
    
    -- Use Primordial Wave empowered Lava Burst with Flame Shock up
    if primordialWaveCount > 0 and API.CanCast(spells.LAVA_BURST) then
        API.CastSpell(spells.LAVA_BURST)
        return true
    end
    
    -- Use Earthquake with sufficient Maelstrom (priority when AoE)
    if earthquakeReady and API.CanCast(spells.EARTHQUAKE) then
        -- Always use Echo of Great Sundering
        if echoesOfGreatSundering > 0 then
            API.CastSpellAtCursor(spells.EARTHQUAKE)
            return true
        end
        
        -- Otherwise, use it normally
        if currentMaelstrom >= EARTHQUAKE_MAELSTROM_COST then
            API.CastSpellAtCursor(spells.EARTHQUAKE)
            return true
        end
    end
    
    -- Use Lava Burst if Surge proc is active
    if haveLavaSurge and API.CanCast(spells.LAVA_BURST) then
        API.CastSpell(spells.LAVA_BURST)
        return true
    end
    
    -- Use Lava Burst on targets with Flame Shock for Maelstrom generation
    if lavaBurstCharges > 0 and API.CanCast(spells.LAVA_BURST) then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and targetGUID ~= "" and 
           self.targetData[targetGUID] and self.targetData[targetGUID].flameShock then
            API.CastSpell(spells.LAVA_BURST)
            return true
        end
    end
    
    -- Use Elemental Blast if talented
    if talents.hasElementalBlast and 
       settings.advancedSettings.useElementalBlast ~= "Never" and
       API.CanCast(spells.ELEMENTAL_BLAST) then
        
        -- Use on cooldown
        if settings.advancedSettings.useElementalBlast == "On Cooldown" then
            API.CastSpell(spells.ELEMENTAL_BLAST)
            return true
        end
        
        -- Use with buffs (e.g., Stormkeeper)
        if settings.advancedSettings.useElementalBlast == "With Buffs" and stormkeeperActive then
            API.CastSpell(spells.ELEMENTAL_BLAST)
            return true
        end
    end
    
    -- Use Chain Lightning - main AoE filler
    if API.CanCast(spells.CHAIN_LIGHTNING) then
        -- Prioritize with Stormkeeper if active
        if stormkeeperActive then
            API.CastSpell(spells.CHAIN_LIGHTNING)
            return true
        end
        
        -- Otherwise, use it normally
        API.CastSpell(spells.CHAIN_LIGHTNING)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Elemental:HandleSingleTargetRotation(settings)
    -- Apply/refresh Flame Shock
    if settings.rotationSettings.maintainFlameShock and API.CanCast(spells.FLAME_SHOCK) then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and targetGUID ~= "" and self.targetData[targetGUID] and 
           (not self.targetData[targetGUID].flameShock or 
            self.targetData[targetGUID].flameShockExpiration - GetTime() < FLAMESHOCK_REFRESH_THRESHOLD) then
            API.CastSpell(spells.FLAME_SHOCK)
            return true
        end
    end
    
    -- Use Primordial Wave empowered Lava Burst with Flame Shock up
    if primordialWaveCount > 0 and API.CanCast(spells.LAVA_BURST) then
        API.CastSpell(spells.LAVA_BURST)
        return true
    end
    
    -- Use Earth Shock with sufficient Maelstrom
    if earthShockReady and API.CanCast(spells.EARTH_SHOCK) then
        -- Use at Maelstrom cap
        if settings.advancedSettings.useEarthShock == "At Cap" and currentMaelstrom >= maxMaelstrom - 10 then
            API.CastSpell(spells.EARTH_SHOCK)
            return true
        end
        
        -- Use at cost
        if settings.advancedSettings.useEarthShock == "At Cost" and currentMaelstrom >= EARTH_SHOCK_MAELSTROM_COST then
            API.CastSpell(spells.EARTH_SHOCK)
            return true
        end
    end
    
    -- Use Frost Shock with Icefury buff
    if icefuryActive and API.CanCast(spells.FROST_SHOCK) then
        API.CastSpell(spells.FROST_SHOCK)
        return true
    end
    
    -- Use Lava Burst if Surge proc is active
    if haveLavaSurge and API.CanCast(spells.LAVA_BURST) then
        API.CastSpell(spells.LAVA_BURST)
        return true
    end
    
    -- Use Lava Burst on targets with Flame Shock
    if lavaBurstCharges > 0 and API.CanCast(spells.LAVA_BURST) then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and targetGUID ~= "" and 
           self.targetData[targetGUID] and self.targetData[targetGUID].flameShock then
            API.CastSpell(spells.LAVA_BURST)
            return true
        end
    end
    
    -- Use Elemental Blast if talented
    if talents.hasElementalBlast and 
       settings.advancedSettings.useElementalBlast ~= "Never" and
       API.CanCast(spells.ELEMENTAL_BLAST) then
        
        -- Use on cooldown
        if settings.advancedSettings.useElementalBlast == "On Cooldown" then
            API.CastSpell(spells.ELEMENTAL_BLAST)
            return true
        end
        
        -- Use with buffs
        if settings.advancedSettings.useElementalBlast == "With Buffs" and 
           (stormkeeperActive or API.PlayerHasBuff(buffs.MASTER_OF_THE_ELEMENTS)) then
            API.CastSpell(spells.ELEMENTAL_BLAST)
            return true
        end
    end
    
    -- Use Lightning Bolt as filler
    if API.CanCast(spells.LIGHTNING_BOLT) then
        -- Prioritize with Stormkeeper if active
        if stormkeeperActive then
            API.CastSpell(spells.LIGHTNING_BOLT)
            return true
        end
        
        -- Otherwise, use it normally
        API.CastSpell(spells.LIGHTNING_BOLT)
        return true
    end
    
    return false
end

-- Handle specialization change
function Elemental:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentMaelstrom = API.GetPlayerPower()
    maxMaelstrom = 100
    lavaBurstCharges = API.GetSpellCharges(spells.LAVA_BURST) or 0
    haveLavaSurge = false
    earthShockReady = false
    earthquakeReady = false
    flameShockTargets = {}
    stormkeeperActive = false
    echoesOfGreatSundering = 0
    earthquakeCast = 0
    primordalWaveActive = false
    maelstromWeaponStacks = 0
    lastEarthquakeTime = 0
    icefuryActive = false
    fireElementalActive = false
    stormElementalActive = false
    ascendanceActive = false
    liquidMagmaTotemActive = false
    vesperTotemActive = false
    primordialWaveCount = 0
    lightningBoltCasts = 0
    
    API.PrintDebug("Elemental Shaman state reset on spec change")
    
    return true
end

-- Return the module for loading
return Elemental