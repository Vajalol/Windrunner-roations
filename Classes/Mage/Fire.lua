------------------------------------------
-- WindrunnerRotations - Fire Mage Module
-- Author: VortexQ8
------------------------------------------

local Fire = {}
-- This will be assigned to addon.Classes.Mage.Fire when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Mage

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local heatingUp = false
local hotStreak = false
local combustionActive = false
local combustionEndTime = 0
local runeOfPowerActive = false
local runeOfPowerEndTime = 0
local iceFloes = 0
local fireBlastCharges = 0
local phoenixFlamesCharges = 0
local pyroclasmBuff = false
local pyroclasm_stacks = 0
local slipstream = false
local temporalWarp = false
local runeCooldown = 0
local firestarterActive = false -- Target above 90% health
local scorchedActive = false
local shiftingPowerChanneling = false
local disciplinesActive = false
local disciplinesStacks = 0
local fieryRushActive = false
local sunKingsActive = false
local sunKingsStacks = 0
local fevorActive = false
local meteorsActive = false
local chargedUpActive = false
local hyperActive = false
local hyperStacks = 0

-- Constants
local FIRE_SPEC_ID = 63
local DEFAULT_AOE_THRESHOLD = 3
local FIRESTARTER_THRESHOLD = 90 -- Target health percent threshold for Firestarter
local COMBUSTION_DURATION = 10 -- Base duration without talents
local RUNE_OF_POWER_DURATION = 12
local MAXIMUM_PHOENIX_CHARGES = 2
local MAXIMUM_FIREBLAST_CHARGES = 2
local ENHANCED_PYROTECHNICS_MAX_STACKS = 10
local KINDLING_CRIT_CDR = 1 -- Seconds reduced from Combustion on fireball crits
local MAX_DISCIPLINED_STACKS = 2
local SUN_KINGS_MAX_STACKS = 8
local HYPERTHREAD_MAX_STACKS = 3

-- Initialize the Fire module
function Fire:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Fire Mage module initialized")
    
    return true
end

-- Register spell IDs
function Fire:RegisterSpells()
    -- Main rotational abilities
    spells.FIREBALL = 133
    spells.PYROBLAST = 11366
    spells.FIRE_BLAST = 108853
    spells.PHOENIX_FLAMES = 257541
    spells.SCORCH = 2948
    spells.DRAGONS_BREATH = 31661
    spells.LIVING_BOMB = 44457
    spells.FLAMESTRIKE = 2120
    spells.BLAST_WAVE = 157981
    spells.COMBUSTION = 190319
    spells.RUNE_OF_POWER = 116011
    spells.METEOR = 153561
    spells.FLAME_PATCH = 205037
    spells.FLAME_ON = 205029
    
    -- Defensive and utility
    spells.ICE_BLOCK = 45438
    spells.FROST_NOVA = 122
    spells.COLD_SNAP = 235219
    spells.BLAZING_BARRIER = 235313
    spells.MIRROR_IMAGE = 55342
    spells.ICE_FLOES = 108839
    spells.TIME_WARP = 80353
    spells.COUNTERSPELL = 2139
    spells.BLINK = 1953
    spells.SHIMMER = 212653
    spells.SLOW_FALL = 130
    spells.INVISIBILITY = 66
    spells.GREATER_INVISIBILITY = 110959
    spells.REMOVE_CURSE = 475
    spells.SPELLSTEAL = 30449
    spells.ALTER_TIME = 342245
    
    -- Talents/Procs
    spells.HEATING_UP = 48107
    spells.HOT_STREAK = 48108
    spells.ENHANCED_PYROTECHNICS = 157642
    spells.KINDLING = 155148
    spells.PYROMANIAC = 205020
    spells.FIRESTARTER = 205026
    spells.PYROCLASM = 269650
    spells.SEARING_TOUCH = 269644
    spells.ALEXSTRASZAS_FURY = 235870
    spells.FROM_THE_ASHES = 342344
    spells.FRENETIC_SPEED = 236058
    spells.FEVERED_INCANTATION = 384283
    spells.SUN_KINGS_BLESSING = 383886
    spells.IMPROVED_SCORCH = 383604
    spells.WILDFIRE = 383489
    spells.MASTER_OF_ELEMENTS = 383534
    spells.CONTROLLED_DESTRUCTION = 383670
    spells.TEMPERED_FLAMES = 383659
    spells.IMPROVED_COMBUSTION = 383967
    spells.IMPROVED_FLAMESTRIKE = 383606
    spells.INCENDIARY_ERUPTIONS = 383844
    spells.TEMPORAL_VELOCITY = 383819
    spells.HYPERTHREAD_WRISTWRAPS = 383886
    
    -- Covenant abilities
    spells.MIRRORS_OF_TORMENT = 314793 -- Venthyr
    spells.DEATHBORNE = 324220 -- Necrolord
    spells.RADIANT_SPARK = 307443 -- Kyrian
    spells.SHIFTING_POWER = 314791 -- Night Fae
    
    -- Legendary effects
    spells.FIERY_RUSH = 333313 -- From Sun King's Blessing Legendary
    spells.DISCIPLINARY_COMMAND = 327365 -- Disciplinary Command legendary
    spells.TEMPORAL_WARP = 327351 -- Temporal Warp legendary
    spells.FEVERED_INCANTATION_BUFF = 333049 -- Fevered Incantation legendary
    spells.SUN_KINGS_BLESSING_BUFF = 333314 -- Sun King's Blessing legendary
    
    -- Buff and debuff IDs
    spells.COMBUSTION_BUFF = 190319
    spells.RUNE_OF_POWER_BUFF = 116014
    spells.HEATING_UP_BUFF = 48107
    spells.HOT_STREAK_BUFF = 48108
    spells.ENHANCED_PYROTECHNICS_BUFF = 157644
    spells.PYROCLASM_BUFF = 269651
    spells.ICE_FLOES_BUFF = 108839
    spells.IGNITE = 12654
    spells.CAUTERIZE = 86949
    spells.BLAZING_BARRIER_BUFF = 235313
    spells.FIRESTORM = 333097
    spells.MIRROR_IMAGE_BUFF = 55342
    spells.SLIPSTREAM_BUFF = 236457
    spells.FIERY_RUSH_BUFF = 333313
    spells.FEVERED_INCANTATION_BUFF = 333049
    spells.TEMPORAL_WARP_BUFF = 327351
    spells.SUN_KINGS_BLESSING_BUFF = 333314
    spells.FLAMES_OF_ALACRITY = 236059
    spells.DISCIPLINARY_COMMAND_BUFF = 327369
    spells.SCORCHED_DEBUFF = 22959
    spells.CHARRED_PASSIONS = 383638
    spells.CHARGED_UP = 384455
    spells.HYPERTHREAD = 383881
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.COMBUSTION = spells.COMBUSTION_BUFF
    buffs.RUNE_OF_POWER = spells.RUNE_OF_POWER_BUFF
    buffs.HEATING_UP = spells.HEATING_UP_BUFF
    buffs.HOT_STREAK = spells.HOT_STREAK_BUFF
    buffs.ENHANCED_PYROTECHNICS = spells.ENHANCED_PYROTECHNICS_BUFF
    buffs.PYROCLASM = spells.PYROCLASM_BUFF
    buffs.ICE_FLOES = spells.ICE_FLOES_BUFF
    buffs.BLAZING_BARRIER = spells.BLAZING_BARRIER_BUFF
    buffs.MIRROR_IMAGE = spells.MIRROR_IMAGE_BUFF
    buffs.FIERY_RUSH = spells.FIERY_RUSH_BUFF
    buffs.FEVERED_INCANTATION = spells.FEVERED_INCANTATION_BUFF
    buffs.SUN_KINGS_BLESSING = spells.SUN_KINGS_BLESSING_BUFF
    buffs.TEMPORAL_WARP = spells.TEMPORAL_WARP_BUFF
    buffs.SLIPSTREAM = spells.SLIPSTREAM_BUFF
    buffs.FLAMES_OF_ALACRITY = spells.FLAMES_OF_ALACRITY
    buffs.DISCIPLINARY_COMMAND = spells.DISCIPLINARY_COMMAND_BUFF
    buffs.CHARGED_UP = spells.CHARGED_UP
    buffs.HYPERTHREAD = spells.HYPERTHREAD
    
    debuffs.IGNITE = spells.IGNITE
    debuffs.LIVING_BOMB = spells.LIVING_BOMB
    debuffs.SCORCHED = spells.SCORCHED_DEBUFF
    
    return true
end

-- Register variables to track
function Fire:RegisterVariables()
    -- Talent tracking
    talents.hasRagingPyroclasm = false
    talents.hasPyromaniac = false
    talents.hasKindling = false
    talents.hasRuneOfPower = false
    talents.hasFirestarter = false
    talents.hasMeteor = false
    talents.hasLivingBomb = false
    talents.hasFlamePatch = false
    talents.hasFlameOn = false
    talents.hasAlexstraszasFury = false
    talents.hasFromTheAshes = false
    talents.hasFraneticSpeed = false
    talents.hasSearingTouch = false
    talents.hasPhoenixFlames = false
    talents.hasFeveredIncantation = false
    talents.hasSunKingsBlessing = false
    talents.hasImprovedScorch = false
    talents.hasWildfire = false
    talents.hasMasterOfElements = false
    talents.hasControlledDestruction = false
    talents.hasTemperedFlames = false
    talents.hasImprovedCombustion = false
    talents.hasImprovedFlamestrike = false
    talents.hasIncendiaryEruptions = false
    talents.hasTemporalVelocity = false
    talents.hasHyperthreadWristwraps = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Fire:RegisterSettings()
    ConfigRegistry:RegisterSettings("FireMage", {
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
            useHotStreakAoE = {
                displayName = "Use Hot Streak for AoE",
                description = "Use Hot Streak procs for Flamestrike in AoE",
                type = "toggle",
                default = true
            },
            useHardcast = {
                displayName = "Use Hardcast Pyroblast/Flamestrike",
                description = "Allow hardcasting Pyroblast or Flamestrike",
                type = "toggle",
                default = false
            },
            usePyroclasm = {
                displayName = "Use Pyroclasm",
                description = "Use Pyroclasm procs for Pyroblast",
                type = "toggle",
                default = true
            },
            useFireBlastInstead = {
                displayName = "Prioritize Fire Blast",
                description = "Use Fire Blast over Phoenix Flames for Hot Streak generation",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            useIceBlock = {
                displayName = "Use Ice Block",
                description = "Automatically use Ice Block when critical",
                type = "toggle",
                default = true
            },
            iceBlockThreshold = {
                displayName = "Ice Block Health Threshold",
                description = "Health percentage to use Ice Block",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            },
            useBlazingBarrier = {
                displayName = "Use Blazing Barrier",
                description = "Automatically use Blazing Barrier",
                type = "toggle",
                default = true
            },
            blazingBarrierThreshold = {
                displayName = "Blazing Barrier Health Threshold",
                description = "Health percentage to use Blazing Barrier",
                type = "slider",
                min = 50,
                max = 95,
                default = 80
            },
            useGreaterInvisibility = {
                displayName = "Use Greater Invisibility",
                description = "Automatically use Greater Invisibility in emergency",
                type = "toggle",
                default = true
            },
            greaterInvisibilityThreshold = {
                displayName = "Greater Invisibility Health Threshold",
                description = "Health percentage to use Greater Invisibility",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useAlterTime = {
                displayName = "Use Alter Time",
                description = "Automatically use Alter Time when health drops",
                type = "toggle",
                default = true
            },
            alterTimeThreshold = {
                displayName = "Alter Time Health Threshold",
                description = "Health percentage to use Alter Time",
                type = "slider",
                min = 30,
                max = 80,
                default = 50
            }
        },
        
        offensiveSettings = {
            useCombustion = {
                displayName = "Use Combustion",
                description = "Automatically use Combustion",
                type = "toggle",
                default = true
            },
            useRuneOfPower = {
                displayName = "Use Rune of Power",
                description = "Automatically use Rune of Power",
                type = "toggle",
                default = true
            },
            useMeteor = {
                displayName = "Use Meteor",
                description = "Automatically use Meteor",
                type = "toggle",
                default = true
            },
            useDragonsBreath = {
                displayName = "Use Dragon's Breath",
                description = "Automatically use Dragon's Breath",
                type = "toggle",
                default = true
            },
            useLivingBomb = {
                displayName = "Use Living Bomb",
                description = "Automatically use Living Bomb",
                type = "toggle",
                default = true
            },
            usePhoenixFlames = {
                displayName = "Use Phoenix Flames",
                description = "Automatically use Phoenix Flames",
                type = "toggle",
                default = true
            },
            useMirrorImage = {
                displayName = "Use Mirror Image",
                description = "Automatically use Mirror Image",
                type = "toggle",
                default = true
            }
        },
        
        covenantSettings = {
            useMirrorsOfTorment = {
                displayName = "Use Mirrors of Torment",
                description = "Automatically use Mirrors of Torment (Venthyr)",
                type = "toggle",
                default = true
            },
            useDeathborne = {
                displayName = "Use Deathborne",
                description = "Automatically use Deathborne (Necrolord)",
                type = "toggle",
                default = true
            },
            useRadiantSpark = {
                displayName = "Use Radiant Spark",
                description = "Automatically use Radiant Spark (Kyrian)",
                type = "toggle",
                default = true
            },
            useShiftingPower = {
                displayName = "Use Shifting Power",
                description = "Automatically use Shifting Power (Night Fae)",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            preserveFireBlastCharges = {
                displayName = "Preserve Fire Blast Charges",
                description = "Minimum Fire Blast charges to save for Combustion",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            preservePhoenixCharges = {
                displayName = "Preserve Phoenix Flames Charges",
                description = "Minimum Phoenix Flames charges to save for Combustion",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            useIceFloes = {
                displayName = "Use Ice Floes",
                description = "When to use Ice Floes when moving",
                type = "dropdown",
                options = {"Never", "During Combustion", "Always"},
                default = "During Combustion"
            },
            pyroclasmStacksToUse = {
                displayName = "Pyroclasm Stacks to Use",
                description = "Number of Pyroclasm stacks to trigger usage",
                type = "slider",
                min = 1,
                max = 2,
                default = 2
            },
            holdCombustion = {
                displayName = "Hold Combustion",
                description = "Save Combustion for when Rune of Power is ready",
                type = "toggle",
                default = true
            },
            useScorch = {
                displayName = "Use Scorch",
                description = "When to use Scorch",
                type = "dropdown",
                options = {"While Moving", "Execute Only", "Always Below 30%", "Never"},
                default = "While Moving"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Combustion controls
            combustion = AAC.RegisterAbility(spells.COMBUSTION, {
                enabled = true,
                useDuringBurstOnly = true,
                useWithRuneOfPower = true
            }),
            
            -- Rune of Power controls
            runeOfPower = AAC.RegisterAbility(spells.RUNE_OF_POWER, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithCombustion = true
            }),
            
            -- Meteor controls
            meteor = AAC.RegisterAbility(spells.METEOR, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithCombustion = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Fire:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
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
function Fire:UpdateTalentInfo()
    -- Check for important talents
    talents.hasRagingPyroclasm = API.HasTalent(spells.PYROCLASM)
    talents.hasPyromaniac = API.HasTalent(spells.PYROMANIAC)
    talents.hasKindling = API.HasTalent(spells.KINDLING)
    talents.hasRuneOfPower = API.HasTalent(spells.RUNE_OF_POWER)
    talents.hasFirestarter = API.HasTalent(spells.FIRESTARTER)
    talents.hasMeteor = API.HasTalent(spells.METEOR)
    talents.hasLivingBomb = API.HasTalent(spells.LIVING_BOMB)
    talents.hasFlamePatch = API.HasTalent(spells.FLAME_PATCH)
    talents.hasFlameOn = API.HasTalent(spells.FLAME_ON)
    talents.hasAlexstraszasFury = API.HasTalent(spells.ALEXSTRASZAS_FURY)
    talents.hasFromTheAshes = API.HasTalent(spells.FROM_THE_ASHES)
    talents.hasFraneticSpeed = API.HasTalent(spells.FRENETIC_SPEED)
    talents.hasSearingTouch = API.HasTalent(spells.SEARING_TOUCH)
    talents.hasPhoenixFlames = API.HasTalent(spells.PHOENIX_FLAMES)
    talents.hasFeveredIncantation = API.HasTalent(spells.FEVERED_INCANTATION)
    talents.hasSunKingsBlessing = API.HasTalent(spells.SUN_KINGS_BLESSING)
    talents.hasImprovedScorch = API.HasTalent(spells.IMPROVED_SCORCH)
    talents.hasWildfire = API.HasTalent(spells.WILDFIRE)
    talents.hasMasterOfElements = API.HasTalent(spells.MASTER_OF_ELEMENTS)
    talents.hasControlledDestruction = API.HasTalent(spells.CONTROLLED_DESTRUCTION)
    talents.hasTemperedFlames = API.HasTalent(spells.TEMPERED_FLAMES)
    talents.hasImprovedCombustion = API.HasTalent(spells.IMPROVED_COMBUSTION)
    talents.hasImprovedFlamestrike = API.HasTalent(spells.IMPROVED_FLAMESTRIKE)
    talents.hasIncendiaryEruptions = API.HasTalent(spells.INCENDIARY_ERUPTIONS)
    talents.hasTemporalVelocity = API.HasTalent(spells.TEMPORAL_VELOCITY)
    talents.hasHyperthreadWristwraps = API.HasTalent(spells.HYPERTHREAD_WRISTWRAPS)
    
    -- Adjust variables based on talents
    if talents.hasFlameOn then
        MAXIMUM_FIREBLAST_CHARGES = 3
    else
        MAXIMUM_FIREBLAST_CHARGES = 2
    end
    
    if talents.hasFromTheAshes then
        MAXIMUM_PHOENIX_CHARGES = 3
    else
        MAXIMUM_PHOENIX_CHARGES = 2
    end
    
    API.PrintDebug("Fire Mage talents updated")
    
    return true
end

-- Update target data
function Fire:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                ignite = false,
                igniteExpiration = 0,
                livingBomb = false,
                livingBombExpiration = 0,
                scorched = false,
                scorchedExpiration = 0
            }
        end
        
        -- Check for Ignite
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.IGNITE)
        if name then
            self.targetData[targetGUID].ignite = true
            self.targetData[targetGUID].igniteExpiration = expiration
        else
            self.targetData[targetGUID].ignite = false
            self.targetData[targetGUID].igniteExpiration = 0
        end
        
        -- Check for Living Bomb
        if talents.hasLivingBomb then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.LIVING_BOMB)
            if name then
                self.targetData[targetGUID].livingBomb = true
                self.targetData[targetGUID].livingBombExpiration = expiration
            else
                self.targetData[targetGUID].livingBomb = false
                self.targetData[targetGUID].livingBombExpiration = 0
            end
        end
        
        -- Check for Scorched
        if talents.hasImprovedScorch then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.SCORCHED_DEBUFF)
            if name then
                self.targetData[targetGUID].scorched = true
                self.targetData[targetGUID].scorchedExpiration = expiration
                scorchedActive = true
            else
                self.targetData[targetGUID].scorched = false
                self.targetData[targetGUID].scorchedExpiration = 0
                scorchedActive = false
            end
        end
        
        -- Check for Firestarter condition (target above 90% health)
        if talents.hasFirestarter then
            local health = API.GetTargetHealthPercent()
            firestarterActive = health >= FIRESTARTER_THRESHOLD
        else
            firestarterActive = false
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Fire Mage AoE radius
    
    return true
end

-- Handle combat log events
function Fire:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Heating Up
            if spellID == buffs.HEATING_UP then
                heatingUp = true
                API.PrintDebug("Heating Up activated")
            end
            
            -- Track Hot Streak
            if spellID == buffs.HOT_STREAK then
                hotStreak = true
                API.PrintDebug("Hot Streak activated")
            end
            
            -- Track Combustion
            if spellID == buffs.COMBUSTION then
                combustionActive = true
                combustionEndTime = GetTime() + COMBUSTION_DURATION
                API.PrintDebug("Combustion activated")
            end
            
            -- Track Rune of Power
            if spellID == buffs.RUNE_OF_POWER then
                runeOfPowerActive = true
                runeOfPowerEndTime = GetTime() + RUNE_OF_POWER_DURATION
                API.PrintDebug("Rune of Power activated")
            end
            
            -- Track Pyroclasm
            if spellID == buffs.PYROCLASM then
                pyroclasmBuff = true
                pyroclasm_stacks = select(4, API.GetBuffInfo("player", buffs.PYROCLASM)) or 0
                API.PrintDebug("Pyroclasm proc: " .. tostring(pyroclasm_stacks) .. " stacks")
            end
            
            -- Track Ice Floes
            if spellID == buffs.ICE_FLOES then
                iceFloes = iceFloes + 1
                API.PrintDebug("Ice Floes active: " .. tostring(iceFloes))
            end
            
            -- Track Slipstream
            if spellID == buffs.SLIPSTREAM then
                slipstream = true
                API.PrintDebug("Slipstream active")
            end
            
            -- Track Temporal Warp legendary
            if spellID == buffs.TEMPORAL_WARP then
                temporalWarp = true
                API.PrintDebug("Temporal Warp active")
            end
            
            -- Track Fiery Rush (Sun King's Blessing legendary)
            if spellID == buffs.FIERY_RUSH then
                fieryRushActive = true
                API.PrintDebug("Fiery Rush active")
            end
            
            -- Track Sun King's Blessing
            if spellID == buffs.SUN_KINGS_BLESSING then
                sunKingsActive = true
                sunKingsStacks = select(4, API.GetBuffInfo("player", buffs.SUN_KINGS_BLESSING)) or 0
                API.PrintDebug("Sun King's Blessing stacks: " .. tostring(sunKingsStacks))
            end
            
            -- Track Fevered Incantation
            if spellID == buffs.FEVERED_INCANTATION then
                fevorActive = true
                API.PrintDebug("Fevered Incantation active")
            end
            
            -- Track Disciplinary Command
            if spellID == buffs.DISCIPLINARY_COMMAND then
                disciplinesActive = true
                disciplinesStacks = select(4, API.GetBuffInfo("player", buffs.DISCIPLINARY_COMMAND)) or 0
                API.PrintDebug("Disciplinary Command stacks: " .. tostring(disciplinesStacks))
            end
            
            -- Track Charged Up
            if spellID == buffs.CHARGED_UP then
                chargedUpActive = true
                API.PrintDebug("Charged Up active")
            end
            
            -- Track Hyperthread
            if spellID == buffs.HYPERTHREAD then
                hyperActive = true
                hyperStacks = select(4, API.GetBuffInfo("player", buffs.HYPERTHREAD)) or 0
                API.PrintDebug("Hyperthread stacks: " .. tostring(hyperStacks))
            end
        end
        
        -- Track target debuffs
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Update target data for debuffs
            self:UpdateTargetData()
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Heating Up
            if spellID == buffs.HEATING_UP then
                heatingUp = false
                API.PrintDebug("Heating Up faded")
            end
            
            -- Track Hot Streak
            if spellID == buffs.HOT_STREAK then
                hotStreak = false
                API.PrintDebug("Hot Streak consumed")
            end
            
            -- Track Combustion
            if spellID == buffs.COMBUSTION then
                combustionActive = false
                API.PrintDebug("Combustion faded")
            end
            
            -- Track Rune of Power
            if spellID == buffs.RUNE_OF_POWER then
                runeOfPowerActive = false
                API.PrintDebug("Rune of Power faded")
            end
            
            -- Track Pyroclasm
            if spellID == buffs.PYROCLASM then
                pyroclasmBuff = false
                pyroclasm_stacks = 0
                API.PrintDebug("Pyroclasm consumed")
            end
            
            -- Track Ice Floes
            if spellID == buffs.ICE_FLOES then
                iceFloes = math.max(0, iceFloes - 1)
                API.PrintDebug("Ice Floes used: " .. tostring(iceFloes) .. " remaining")
            end
            
            -- Track Slipstream
            if spellID == buffs.SLIPSTREAM then
                slipstream = false
                API.PrintDebug("Slipstream faded")
            end
            
            -- Track Temporal Warp
            if spellID == buffs.TEMPORAL_WARP then
                temporalWarp = false
                API.PrintDebug("Temporal Warp faded")
            end
            
            -- Track Fiery Rush
            if spellID == buffs.FIERY_RUSH then
                fieryRushActive = false
                API.PrintDebug("Fiery Rush faded")
            end
            
            -- Track Sun King's Blessing
            if spellID == buffs.SUN_KINGS_BLESSING then
                sunKingsActive = false
                sunKingsStacks = 0
                API.PrintDebug("Sun King's Blessing faded")
            end
            
            -- Track Fevered Incantation
            if spellID == buffs.FEVERED_INCANTATION then
                fevorActive = false
                API.PrintDebug("Fevered Incantation faded")
            end
            
            -- Track Disciplinary Command
            if spellID == buffs.DISCIPLINARY_COMMAND then
                disciplinesActive = false
                disciplinesStacks = 0
                API.PrintDebug("Disciplinary Command faded")
            end
            
            -- Track Charged Up
            if spellID == buffs.CHARGED_UP then
                chargedUpActive = false
                API.PrintDebug("Charged Up faded")
            end
            
            -- Track Hyperthread
            if spellID == buffs.HYPERTHREAD then
                hyperActive = false
                hyperStacks = 0
                API.PrintDebug("Hyperthread faded")
            end
        end
        
        -- Track target debuffs
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Update target data for debuffs
            self:UpdateTargetData()
        end
    end
    
    -- Track Ice Floes charges
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.ICE_FLOES and sourceGUID == API.GetPlayerGUID() then
        iceFloes = iceFloes + 1
        API.PrintDebug("Ice Floes gained: " .. tostring(iceFloes) .. " total")
    end
    
    -- Track Fire Blast charges
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.FIRE_BLAST and sourceGUID == API.GetPlayerGUID() then
        fireBlastCharges = API.GetSpellCharges(spells.FIRE_BLAST) or 0
        API.PrintDebug("Fire Blast used, " .. tostring(fireBlastCharges) .. " charges remaining")
    end
    
    -- Track Phoenix Flames charges
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.PHOENIX_FLAMES and sourceGUID == API.GetPlayerGUID() then
        phoenixFlamesCharges = API.GetSpellCharges(spells.PHOENIX_FLAMES) or 0
        API.PrintDebug("Phoenix Flames used, " .. tostring(phoenixFlamesCharges) .. " charges remaining")
    end
    
    -- Track combustion and rune cooldowns
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.COMBUSTION then
            API.PrintDebug("Combustion used")
        elseif spellID == spells.RUNE_OF_POWER then
            runeCooldown = 45 -- Base cooldown
            API.PrintDebug("Rune of Power used, on cooldown")
        elseif spellID == spells.PYROBLAST then
            API.PrintDebug("Pyroblast cast")
        elseif spellID == spells.FLAMESTRIKE then
            API.PrintDebug("Flamestrike cast")
        elseif spellID == spells.SHIFTING_POWER then
            shiftingPowerChanneling = true
            
            -- Shifting Power reduces cooldowns over its duration, so we don't directly set variables
            -- Instead, we rely on periodic spell ticks to track the channel status
            
            API.PrintDebug("Shifting Power channel started")
        end
    end
    
    -- Track channeling
    if eventType == "SPELL_CHANNEL_START" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.SHIFTING_POWER then
            shiftingPowerChanneling = true
            API.PrintDebug("Shifting Power channel started")
        end
    end
    
    -- Track channel end
    if eventType == "SPELL_CHANNEL_STOP" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.SHIFTING_POWER then
            shiftingPowerChanneling = false
            API.PrintDebug("Shifting Power channel ended")
        end
    end
    
    -- Track periodic effects from Shifting Power
    if eventType == "SPELL_PERIODIC_DAMAGE" and spellID == spells.SHIFTING_POWER and sourceGUID == API.GetPlayerGUID() then
        -- Each tick of Shifting Power reduces cooldowns
        runeCooldown = math.max(0, runeCooldown - 3)
        
        if runeCooldown == 0 then
            API.PrintDebug("Rune of Power cooldown reset by Shifting Power")
        end
    end
    
    -- Track Hyperthread stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.HYPERTHREAD and destGUID == API.GetPlayerGUID() then
        hyperStacks = select(4, API.GetBuffInfo("player", buffs.HYPERTHREAD)) or 0
        API.PrintDebug("Hyperthread stacks: " .. tostring(hyperStacks))
    end
    
    -- Track Sun King's Blessing stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SUN_KINGS_BLESSING and destGUID == API.GetPlayerGUID() then
        sunKingsStacks = select(4, API.GetBuffInfo("player", buffs.SUN_KINGS_BLESSING)) or 0
        API.PrintDebug("Sun King's Blessing stacks: " .. tostring(sunKingsStacks))
    end
    
    -- Track Disciplinary Command stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.DISCIPLINARY_COMMAND and destGUID == API.GetPlayerGUID() then
        disciplinesStacks = select(4, API.GetBuffInfo("player", buffs.DISCIPLINARY_COMMAND)) or 0
        API.PrintDebug("Disciplinary Command stacks: " .. tostring(disciplinesStacks))
    end
    
    return true
end

-- Main rotation function
function Fire:RunRotation()
    -- Check if we should be running Fire Mage logic
    if API.GetActiveSpecID() ~= FIRE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() or shiftingPowerChanneling then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FireMage")
    
    -- Update variables
    fireBlastCharges = select(1, API.GetSpellCharges(spells.FIRE_BLAST)) or 0
    phoenixFlamesCharges = select(1, API.GetSpellCharges(spells.PHOENIX_FLAMES)) or 0
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
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
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle movement
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

-- Handle interrupts
function Fire:HandleInterrupts()
    -- Use Counterspell for interrupt
    if API.CanCast(spells.COUNTERSPELL) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.COUNTERSPELL)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Fire:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Ice Block for critical situations
    if settings.defensiveSettings.useIceBlock and
       playerHealth <= settings.defensiveSettings.iceBlockThreshold and
       API.CanCast(spells.ICE_BLOCK) then
        API.CastSpell(spells.ICE_BLOCK)
        return true
    end
    
    -- Greater Invisibility for damage reduction
    if settings.defensiveSettings.useGreaterInvisibility and
       playerHealth <= settings.defensiveSettings.greaterInvisibilityThreshold and
       API.CanCast(spells.GREATER_INVISIBILITY) then
        API.CastSpell(spells.GREATER_INVISIBILITY)
        return true
    end
    
    -- Alter Time to reset health
    if settings.defensiveSettings.useAlterTime and
       playerHealth <= settings.defensiveSettings.alterTimeThreshold and
       API.CanCast(spells.ALTER_TIME) then
        API.CastSpell(spells.ALTER_TIME)
        return true
    end
    
    -- Blazing Barrier for defense
    if settings.defensiveSettings.useBlazingBarrier and
       playerHealth <= settings.defensiveSettings.blazingBarrierThreshold and
       API.CanCast(spells.BLAZING_BARRIER) then
        API.CastSpell(spells.BLAZING_BARRIER)
        return true
    end
    
    return false
end

-- Handle movement
function Fire:HandleMovement(settings)
    -- Use Ice Floes if available
    if settings.advancedSettings.useIceFloes ~= "Never" and API.CanCast(spells.ICE_FLOES) then
        if settings.advancedSettings.useIceFloes == "Always" or
           (settings.advancedSettings.useIceFloes == "During Combustion" and combustionActive) then
            API.CastSpell(spells.ICE_FLOES)
            return true
        end
    end
    
    -- Instant cast options while moving
    
    -- Scorch can be cast while moving, but check settings first
    if settings.advancedSettings.useScorch == "While Moving" or
       (settings.advancedSettings.useScorch == "Always Below 30%" and API.GetTargetHealthPercent() <= 30) or
       (settings.advancedSettings.useScorch == "Execute Only" and API.GetTargetHealthPercent() <= 30 and talents.hasSearingTouch) then
        
        if API.CanCast(spells.SCORCH) then
            API.CastSpell(spells.SCORCH)
            return true
        end
    end
    
    -- Use Fire Blast to trigger Hot Streak if Heating Up is active
    if heatingUp and API.CanCast(spells.FIRE_BLAST) and
       (fireBlastCharges > settings.advancedSettings.preserveFireBlastCharges or combustionActive) then
        API.CastSpell(spells.FIRE_BLAST)
        return true
    end
    
    -- Use Phoenix Flames if available
    if talents.hasPhoenixFlames and settings.offensiveSettings.usePhoenixFlames and
       API.CanCast(spells.PHOENIX_FLAMES) and
       (phoenixFlamesCharges > settings.advancedSettings.preservePhoenixCharges or combustionActive) then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- If we have Hot Streak, use it for Pyroblast or Flamestrike
    if hotStreak and API.CanCast(spells.PYROBLAST) then
        if settings.rotationSettings.aoeEnabled and 
           currentAoETargets >= settings.rotationSettings.aoeThreshold and
           settings.rotationSettings.useHotStreakAoE then
            API.CastSpellAtCursor(spells.FLAMESTRIKE)
        else
            API.CastSpell(spells.PYROBLAST)
        end
        return true
    end
    
    -- Use Dragon's Breath if close to enemies
    if settings.offensiveSettings.useDragonsBreath and
       API.GetNearbyEnemiesCount(8) > 0 and  -- 8 yard range for Dragon's Breath
       API.CanCast(spells.DRAGONS_BREATH) then
        API.CastSpell(spells.DRAGONS_BREATH)
        return true
    end
    
    -- If we have Slipstream from Shifting Power, cast a Fireball
    if slipstream and API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Fire:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Use Mirror Image
    if settings.offensiveSettings.useMirrorImage and
       API.CanCast(spells.MIRROR_IMAGE) then
        API.CastSpell(spells.MIRROR_IMAGE)
        return true
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Rune of Power
    if talents.hasRuneOfPower and
       settings.offensiveSettings.useRuneOfPower and
       settings.abilityControls.runeOfPower.enabled and
       not runeOfPowerActive and 
       runeCooldown == 0 and
       API.CanCast(spells.RUNE_OF_POWER) then
        
        -- Check if we want to use with Combustion
        if not settings.abilityControls.runeOfPower.useWithCombustion or 
           (API.GetSpellCooldown(spells.COMBUSTION) < 2 and settings.offensiveSettings.useCombustion) then
            API.CastSpell(spells.RUNE_OF_POWER)
            return true
        end
    end
    
    -- Use Combustion
    if settings.offensiveSettings.useCombustion and
       settings.abilityControls.combustion.enabled and
       not combustionActive and
       API.CanCast(spells.COMBUSTION) then
        
        -- Check if we should wait for Rune of Power
        if not settings.advancedSettings.holdCombustion or not talents.hasRuneOfPower or runeOfPowerActive then
            API.CastSpell(spells.COMBUSTION)
            return true
        end
    end
    
    -- Use Meteor
    if talents.hasMeteor and
       settings.offensiveSettings.useMeteor and
       settings.abilityControls.meteor.enabled and
       API.CanCast(spells.METEOR) then
        
        -- Check if we want to use during Combustion
        if not settings.abilityControls.meteor.useWithCombustion or combustionActive then
            API.CastSpellAtCursor(spells.METEOR)
            return true
        end
    end
    
    -- Use covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Fire:HandleCovenantAbilities(settings)
    -- Use Mirrors of Torment (Venthyr)
    if settings.covenantSettings.useMirrorsOfTorment and
       API.CanCast(spells.MIRRORS_OF_TORMENT) then
        API.CastSpell(spells.MIRRORS_OF_TORMENT)
        return true
    end
    
    -- Use Deathborne (Necrolord)
    if settings.covenantSettings.useDeathborne and
       API.CanCast(spells.DEATHBORNE) then
        API.CastSpell(spells.DEATHBORNE)
        return true
    end
    
    -- Use Radiant Spark (Kyrian)
    if settings.covenantSettings.useRadiantSpark and
       API.CanCast(spells.RADIANT_SPARK) then
        API.CastSpell(spells.RADIANT_SPARK)
        return true
    end
    
    -- Use Shifting Power (Night Fae) - only if we have cooldowns to reduce
    if settings.covenantSettings.useShiftingPower and
       API.CanCast(spells.SHIFTING_POWER) and
       (API.GetSpellCooldown(spells.COMBUSTION) > 10 or
        (talents.hasRuneOfPower and runeCooldown > 10)) then
        API.CastSpell(spells.SHIFTING_POWER)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Fire:HandleAoERotation(settings)
    -- Use Hot Streak for Flamestrike
    if hotStreak and API.CanCast(spells.FLAMESTRIKE) and
       settings.rotationSettings.useHotStreakAoE then
        API.CastSpellAtCursor(spells.FLAMESTRIKE)
        return true
    end
    
    -- Use Dragon's Breath if in close range
    if settings.offensiveSettings.useDragonsBreath and
       API.GetNearbyEnemiesCount(8) > 0 and
       API.CanCast(spells.DRAGONS_BREATH) then
        API.CastSpell(spells.DRAGONS_BREATH)
        return true
    end
    
    -- Use Living Bomb if talented
    if talents.hasLivingBomb and
       settings.offensiveSettings.useLivingBomb and
       API.CanCast(spells.LIVING_BOMB) then
        -- Apply to current target if not present
        local targetGUID = API.GetTargetGUID()
        if targetGUID and not self.targetData[targetGUID].livingBomb then
            API.CastSpell(spells.LIVING_BOMB)
            return true
        end
    end
    
    -- Use Fire Blast to convert Heating Up to Hot Streak
    if heatingUp and API.CanCast(spells.FIRE_BLAST) and
       (fireBlastCharges > settings.advancedSettings.preserveFireBlastCharges or combustionActive) then
        API.CastSpell(spells.FIRE_BLAST)
        return true
    end
    
    -- Use Phoenix Flames if available
    if talents.hasPhoenixFlames and
       settings.offensiveSettings.usePhoenixFlames and
       API.CanCast(spells.PHOENIX_FLAMES) and
       (phoenixFlamesCharges > settings.advancedSettings.preservePhoenixCharges or combustionActive) then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- Hardcast Flamestrike if allowed and enough targets
    if settings.rotationSettings.useHardcast and
       currentAoETargets >= settings.rotationSettings.aoeThreshold + 1 and
       API.CanCast(spells.FLAMESTRIKE) then
        API.CastSpellAtCursor(spells.FLAMESTRIKE)
        return true
    end
    
    -- Use Fireball as filler
    if API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Fire:HandleSingleTargetRotation(settings)
    -- Use Hot Streak for Pyroblast
    if hotStreak and API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Use Pyroclasm procs if enabled
    if settings.rotationSettings.usePyroclasm and
       pyroclasmBuff and
       pyroclasm_stacks >= settings.advancedSettings.pyroclasmStacksToUse and
       API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Use Fire Blast to convert Heating Up to Hot Streak
    if heatingUp and
       API.CanCast(spells.FIRE_BLAST) and
       (fireBlastCharges > settings.advancedSettings.preserveFireBlastCharges or combustionActive) then
        -- Prioritize Fire Blast over Phoenix Flames if that setting is enabled
        if settings.rotationSettings.useFireBlastInstead or not talents.hasPhoenixFlames then
            API.CastSpell(spells.FIRE_BLAST)
            return true
        end
    end
    
    -- Use Phoenix Flames if available
    if talents.hasPhoenixFlames and
       settings.offensiveSettings.usePhoenixFlames and
       API.CanCast(spells.PHOENIX_FLAMES) and
       (phoenixFlamesCharges > settings.advancedSettings.preservePhoenixCharges or combustionActive) and
       (heatingUp or API.IsPlayerMoving()) then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- Use Scorch in execute range if talented with Searing Touch
    if talents.hasSearingTouch and
       API.GetTargetHealthPercent() <= 30 and
       API.CanCast(spells.SCORCH) then
        
        if settings.advancedSettings.useScorch != "Never" then
            API.CastSpell(spells.SCORCH)
            return true
        end
    end
    
    -- Use Dragon's Breath if in close range
    if settings.offensiveSettings.useDragonsBreath and
       API.GetNearbyEnemiesCount(8) > 0 and
       API.CanCast(spells.DRAGONS_BREATH) then
        API.CastSpell(spells.DRAGONS_BREATH)
        return true
    end
    
    -- Hardcast Pyroblast if using Sun King's Blessing with enough stacks
    if sunKingsActive and
       sunKingsStacks >= SUN_KINGS_MAX_STACKS and
       API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Hardcast Pyroblast with Firestarter talent (target above 90% health)
    if talents.hasFirestarter and
       firestarterActive and
       settings.rotationSettings.useHardcast and
       API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Use Fireball as main filler
    if API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Handle specialization change
function Fire:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    heatingUp = false
    hotStreak = false
    combustionActive = false
    combustionEndTime = 0
    runeOfPowerActive = false
    runeOfPowerEndTime = 0
    iceFloes = 0
    fireBlastCharges = API.GetSpellCharges(spells.FIRE_BLAST) or 0
    phoenixFlamesCharges = API.GetSpellCharges(spells.PHOENIX_FLAMES) or 0
    pyroclasmBuff = false
    pyroclasm_stacks = 0
    slipstream = false
    temporalWarp = false
    runeCooldown = 0
    firestarterActive = false
    scorchedActive = false
    shiftingPowerChanneling = false
    disciplinesActive = false
    disciplinesStacks = 0
    fieryRushActive = false
    sunKingsActive = false
    sunKingsStacks = 0
    fevorActive = false
    meteorsActive = false
    chargedUpActive = false
    hyperActive = false
    hyperStacks = 0
    
    API.PrintDebug("Fire Mage state reset on spec change")
    
    return true
end

-- Return the module for loading
return Fire