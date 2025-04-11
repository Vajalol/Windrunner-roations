------------------------------------------
-- WindrunnerRotations - Affliction Warlock Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Affliction = {}
addon.Classes.Warlock.Affliction = Affliction

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local Warlock = addon.Classes.Warlock

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentSoulShards = 0
local maxSoulShards = 5
local seedTargets = {}
local agonyTargets = {}
local corruptionTargets = {}
local unstableAfflictionTargets = {}
local siphonLifeTargets = {}
local phantomSingularityActive = false
local darkglareActive = false
local nightfallProc = false
local inevitableDemiseStacks = 0
local maleficRaptureQueued = false

-- Constants
local AFFLICTION_SPEC_ID = 265
local SOUL_SHARD_THRESHOLD = 4
local DEFAULT_AOE_THRESHOLD = 3
local DOT_REFRESH_THRESHOLD = 3 -- Time (in seconds) to start dot refresh

-- Initialize the Affliction module
function Affliction:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Affliction Warlock module initialized")
    
    return true
end

-- Register spell IDs
function Affliction:RegisterSpells()
    -- Affliction Abilities
    spells.AGONY = 980
    spells.CORRUPTION = 172
    spells.UNSTABLE_AFFLICTION = 316099
    spells.MALEFIC_RAPTURE = 324536
    spells.SEED_OF_CORRUPTION = 27243
    spells.DRAIN_SOUL = 198590
    spells.SHADOW_BOLT = 686
    spells.HAUNT = 48181
    spells.PHANTOM_SINGULARITY = 205179
    spells.VILE_TAINT = 278350
    spells.DARK_SOUL_MISERY = 113860
    spells.SIPHON_LIFE = 63106
    spells.GRIMOIRE_OF_SACRIFICE = 108503
    spells.SUMMON_DARKGLARE = 205180
    spells.DRAIN_LIFE = 234153
    
    -- Procs/Buffs
    spells.NIGHTFALL = 108558
    spells.NIGHTFALL_PROC = 264571
    spells.INEVITABLE_DEMISE = 334319
    spells.INEVITABLE_DEMISE_BUFF = 334320
    spells.MALEFIC_WRATH = 337125 -- Legendary buff
    spells.DARK_SOUL_MISERY_BUFF = 113860
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.NIGHTFALL = spells.NIGHTFALL_PROC
    buffs.INEVITABLE_DEMISE = spells.INEVITABLE_DEMISE_BUFF
    buffs.MALEFIC_WRATH = spells.MALEFIC_WRATH
    buffs.DARK_SOUL_MISERY = spells.DARK_SOUL_MISERY_BUFF
    
    debuffs.AGONY = spells.AGONY
    debuffs.CORRUPTION = spells.CORRUPTION
    debuffs.UNSTABLE_AFFLICTION = spells.UNSTABLE_AFFLICTION
    debuffs.PHANTOM_SINGULARITY = spells.PHANTOM_SINGULARITY
    debuffs.VILE_TAINT = spells.VILE_TAINT
    debuffs.HAUNT = spells.HAUNT
    debuffs.SEED_OF_CORRUPTION = spells.SEED_OF_CORRUPTION
    debuffs.SIPHON_LIFE = spells.SIPHON_LIFE
    
    return true
end

-- Register variables to track
function Affliction:RegisterVariables()
    -- Talent tracking
    talents.hasHaunt = false
    talents.hasPhantomSingularity = false
    talents.hasVileTaint = false
    talents.hasSiphonLife = false
    talents.hasDrainSoul = false
    talents.hasNightfall = false
    talents.hasInevitableDemise = false
    talents.hasDarkSoulMisery = false
    talents.hasGrimoireOfSacrifice = false
    
    -- Legendary tracking
    talents.hasMaleficWrath = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Affliction:RegisterSettings()
    ConfigRegistry:RegisterSettings("AfflictionWarlock", {
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
            useHaunt = {
                displayName = "Use Haunt",
                description = "Use Haunt on cooldown when talented",
                type = "toggle",
                default = true
            },
            useVileTaint = {
                displayName = "Use Vile Taint",
                description = "Use Vile Taint for AoE damage when talented",
                type = "toggle",
                default = true
            },
            multidotEnabled = {
                displayName = "Enable Multidotting",
                description = "Apply DoTs to multiple targets",
                type = "toggle",
                default = true
            },
            seedOfCorruptionEnabled = {
                displayName = "Use Seed of Corruption",
                description = "Use Seed of Corruption for AoE damage",
                type = "toggle",
                default = true
            },
            primaryDotTarget = {
                displayName = "Primary DoT Target",
                description = "Which target to prioritize for DoTs",
                type = "dropdown",
                options = {"Target", "Focus", "Highest Health", "Lowest Health"},
                default = "Target"
            }
        },
        
        cooldownSettings = {
            useDarkSoul = {
                displayName = "Use Dark Soul: Misery",
                description = "Automatically use Dark Soul: Misery for burst",
                type = "toggle",
                default = true
            },
            useDarkglare = {
                displayName = "Use Summon Darkglare",
                description = "Automatically summon Darkglare",
                type = "toggle",
                default = true
            },
            usePhantomSingularity = {
                displayName = "Use Phantom Singularity",
                description = "Use Phantom Singularity when talented",
                type = "toggle",
                default = true
            },
            darkglareWithDarkSoul = {
                displayName = "Align Darkglare with Dark Soul",
                description = "Only use Darkglare with Dark Soul active",
                type = "toggle",
                default = true
            },
            soulRotWithDarkglare = {
                displayName = "Align Soul Rot with Darkglare",
                description = "Only use Soul Rot with Darkglare active",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            maxDotsPerTarget = {
                displayName = "Max DoTs Per Target",
                description = "Maximum DoTs to apply per target (0 = all)",
                type = "slider",
                min = 0,
                max = 5,
                default = 0
            },
            maxDotTargets = {
                displayName = "Max DoT Targets",
                description = "Maximum targets to apply DoTs to (0 = all)",
                type = "slider",
                min = 0,
                max = 10,
                default = 0
            },
            maleficRaptureShards = {
                displayName = "Malefic Rapture Shards",
                description = "Minimum soul shards to cast Malefic Rapture",
                type = "slider",
                min = 1,
                max = 5,
                default = 1
            },
            holdShardsForBurst = {
                displayName = "Hold Shards for Burst",
                description = "Save Soul Shards for burst phases",
                type = "toggle",
                default = false
            },
            drainLifeEmergency = {
                displayName = "Emergency Drain Life",
                description = "Use Drain Life as emergency heal",
                type = "toggle",
                default = true
            },
            drainLifeThreshold = {
                displayName = "Drain Life Threshold",
                description = "Health percentage to use Drain Life",
                type = "slider",
                min = 1,
                max = 50,
                default = 30
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Phantom Singularity controls
            phantomSingularity = AAC.RegisterAbility(spells.PHANTOM_SINGULARITY, {
                enabled = true,
                minEnemies = 1,
                useDuringBurstOnly = false
            }),
            
            -- Vile Taint controls
            vileTaint = AAC.RegisterAbility(spells.VILE_TAINT, {
                enabled = true,
                minEnemies = 3,
                useWithDarkglare = true
            }),
            
            -- Haunt controls
            haunt = AAC.RegisterAbility(spells.HAUNT, {
                enabled = true,
                targetPriority = "Highest Health",
                useWithDarkglare = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Affliction:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for soul shard updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "SOUL_SHARDS" then
            self:UpdateSoulShards()
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
function Affliction:UpdateTalentInfo()
    -- Check for important talents
    talents.hasHaunt = API.HasTalent(spells.HAUNT)
    talents.hasPhantomSingularity = API.HasTalent(spells.PHANTOM_SINGULARITY)
    talents.hasVileTaint = API.HasTalent(spells.VILE_TAINT)
    talents.hasSiphonLife = API.HasTalent(spells.SIPHON_LIFE)
    talents.hasDrainSoul = API.HasTalent(spells.DRAIN_SOUL)
    talents.hasNightfall = API.HasTalent(spells.NIGHTFALL)
    talents.hasInevitableDemise = API.HasTalent(spells.INEVITABLE_DEMISE)
    talents.hasDarkSoulMisery = API.HasTalent(spells.DARK_SOUL_MISERY)
    talents.hasGrimoireOfSacrifice = API.HasTalent(spells.GRIMOIRE_OF_SACRIFICE)
    
    -- Check for legendary effects
    talents.hasMaleficWrath = API.HasLegendaryEffect(spells.MALEFIC_WRATH)
    
    API.PrintDebug("Affliction Warlock talents updated")
    
    return true
end

-- Update soul shard tracking
function Affliction:UpdateSoulShards()
    currentSoulShards = API.GetPlayerPower()
    return true
end

-- Update target data
function Affliction:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                agony = false,
                agonyExpiration = 0,
                corruption = false,
                corruptionExpiration = 0,
                unstableAffliction = false,
                unstableAfflictionExpiration = 0,
                phantomSingularity = false,
                phantomSingularityExpiration = 0,
                vileTaint = false,
                vileTaintExpiration = 0,
                seedOfCorruption = false,
                seedOfCorruptionExpiration = 0,
                siphonLife = false,
                siphonLifeExpiration = 0,
                haunt = false,
                hauntExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Affliction AoE radius
    
    -- Update DoT target count trackers
    local validTargets = API.GetAllEnemies(40) -- Get all enemies within 40 yards
    
    agonyTargets = {}
    corruptionTargets = {}
    unstableAfflictionTargets = {}
    siphonLifeTargets = {}
    seedTargets = {}
    
    for _, targetGUID in ipairs(validTargets) do
        if self.targetData[targetGUID] then
            if self.targetData[targetGUID].agony then
                table.insert(agonyTargets, targetGUID)
            end
            
            if self.targetData[targetGUID].corruption then
                table.insert(corruptionTargets, targetGUID)
            end
            
            if self.targetData[targetGUID].unstableAffliction then
                table.insert(unstableAfflictionTargets, targetGUID)
            end
            
            if self.targetData[targetGUID].siphonLife then
                table.insert(siphonLifeTargets, targetGUID)
            end
            
            if self.targetData[targetGUID].seedOfCorruption then
                table.insert(seedTargets, targetGUID)
            end
        end
    end
    
    return true
end

-- Handle combat log events
function Affliction:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Nightfall proc
            if spellID == spells.NIGHTFALL_PROC then
                nightfallProc = true
                API.PrintDebug("Nightfall proc activated")
            end
            
            -- Track Inevitable Demise stacks
            if spellID == spells.INEVITABLE_DEMISE_BUFF then
                inevitableDemiseStacks = select(4, UnitBuff("player", GetSpellInfo(spells.INEVITABLE_DEMISE_BUFF)))
                API.PrintDebug("Inevitable Demise stacks: " .. tostring(inevitableDemiseStacks))
            end
            
            -- Track Dark Soul: Misery
            if spellID == spells.DARK_SOUL_MISERY_BUFF then
                API.PrintDebug("Dark Soul: Misery activated")
            end
        end
        
        -- Track DoT applications on targets
        if self.targetData[destGUID] then
            if spellID == spells.AGONY then
                self.targetData[destGUID].agony = true
                self.targetData[destGUID].agonyExpiration = select(6, API.GetDebuffInfo(destGUID, spells.AGONY))
                if not API.TableContains(agonyTargets, destGUID) then
                    table.insert(agonyTargets, destGUID)
                end
            elseif spellID == spells.CORRUPTION then
                self.targetData[destGUID].corruption = true
                self.targetData[destGUID].corruptionExpiration = select(6, API.GetDebuffInfo(destGUID, spells.CORRUPTION))
                if not API.TableContains(corruptionTargets, destGUID) then
                    table.insert(corruptionTargets, destGUID)
                end
            elseif spellID == spells.UNSTABLE_AFFLICTION then
                self.targetData[destGUID].unstableAffliction = true
                self.targetData[destGUID].unstableAfflictionExpiration = select(6, API.GetDebuffInfo(destGUID, spells.UNSTABLE_AFFLICTION))
                if not API.TableContains(unstableAfflictionTargets, destGUID) then
                    table.insert(unstableAfflictionTargets, destGUID)
                end
            elseif spellID == spells.PHANTOM_SINGULARITY then
                self.targetData[destGUID].phantomSingularity = true
                self.targetData[destGUID].phantomSingularityExpiration = select(6, API.GetDebuffInfo(destGUID, spells.PHANTOM_SINGULARITY))
                phantomSingularityActive = true
            elseif spellID == spells.VILE_TAINT then
                self.targetData[destGUID].vileTaint = true
                self.targetData[destGUID].vileTaintExpiration = select(6, API.GetDebuffInfo(destGUID, spells.VILE_TAINT))
            elseif spellID == spells.SEED_OF_CORRUPTION then
                self.targetData[destGUID].seedOfCorruption = true
                self.targetData[destGUID].seedOfCorruptionExpiration = select(6, API.GetDebuffInfo(destGUID, spells.SEED_OF_CORRUPTION))
                if not API.TableContains(seedTargets, destGUID) then
                    table.insert(seedTargets, destGUID)
                end
            elseif spellID == spells.SIPHON_LIFE then
                self.targetData[destGUID].siphonLife = true
                self.targetData[destGUID].siphonLifeExpiration = select(6, API.GetDebuffInfo(destGUID, spells.SIPHON_LIFE))
                if not API.TableContains(siphonLifeTargets, destGUID) then
                    table.insert(siphonLifeTargets, destGUID)
                end
            elseif spellID == spells.HAUNT then
                self.targetData[destGUID].haunt = true
                self.targetData[destGUID].hauntExpiration = select(6, API.GetDebuffInfo(destGUID, spells.HAUNT))
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Nightfall proc
            if spellID == spells.NIGHTFALL_PROC then
                nightfallProc = false
                API.PrintDebug("Nightfall proc faded")
            end
            
            -- Track Inevitable Demise buff
            if spellID == spells.INEVITABLE_DEMISE_BUFF then
                inevitableDemiseStacks = 0
                API.PrintDebug("Inevitable Demise faded")
            end
            
            -- Track Dark Soul: Misery
            if spellID == spells.DARK_SOUL_MISERY_BUFF then
                API.PrintDebug("Dark Soul: Misery faded")
            end
        end
        
        -- Track DoT removals from targets
        if self.targetData[destGUID] then
            if spellID == spells.AGONY then
                self.targetData[destGUID].agony = false
                API.TableRemove(agonyTargets, destGUID)
            elseif spellID == spells.CORRUPTION then
                self.targetData[destGUID].corruption = false
                API.TableRemove(corruptionTargets, destGUID)
            elseif spellID == spells.UNSTABLE_AFFLICTION then
                self.targetData[destGUID].unstableAffliction = false
                API.TableRemove(unstableAfflictionTargets, destGUID)
            elseif spellID == spells.PHANTOM_SINGULARITY then
                self.targetData[destGUID].phantomSingularity = false
                phantomSingularityActive = false
            elseif spellID == spells.VILE_TAINT then
                self.targetData[destGUID].vileTaint = false
            elseif spellID == spells.SEED_OF_CORRUPTION then
                self.targetData[destGUID].seedOfCorruption = false
                API.TableRemove(seedTargets, destGUID)
            elseif spellID == spells.SIPHON_LIFE then
                self.targetData[destGUID].siphonLife = false
                API.TableRemove(siphonLifeTargets, destGUID)
            elseif spellID == spells.HAUNT then
                self.targetData[destGUID].haunt = false
            end
        end
    end
    
    -- Track important ability casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.SUMMON_DARKGLARE then
            darkglareActive = true
            C_Timer.After(20, function() -- Darkglare lasts 20 seconds
                darkglareActive = false
            end)
            API.PrintDebug("Darkglare summoned")
        elseif spellID == spells.MALEFIC_RAPTURE then
            maleficRaptureQueued = false
        end
    end
    
    return true
end

-- Main rotation function
function Affliction:RunRotation()
    -- Check if we should be running Affliction Warlock logic
    if API.GetActiveSpecID() ~= AFFLICTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("AfflictionWarlock")
    
    -- Update variables
    self:UpdateSoulShards()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle emergency healing
    if settings.advancedSettings.drainLifeEmergency and
       API.GetPlayerHealthPercent() <= settings.advancedSettings.drainLifeThreshold and
       API.CanCast(spells.DRAIN_LIFE) then
        API.CastSpell(spells.DRAIN_LIFE)
        return true
    end
    
    -- Handle Malefic Rapture queue if set
    if maleficRaptureQueued and API.CanCast(spells.MALEFIC_RAPTURE) then
        API.CastSpell(spells.MALEFIC_RAPTURE)
        maleficRaptureQueued = false
        return true
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns() then
        return true
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation()
    else
        return self:HandleSingleTargetRotation()
    end
end

-- Handle cooldown abilities
function Affliction:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("AfflictionWarlock")
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Dark Soul: Misery
    if talents.hasDarkSoulMisery and 
       settings.cooldownSettings.useDarkSoul and
       API.CanCast(spells.DARK_SOUL_MISERY) then
        API.CastSpell(spells.DARK_SOUL_MISERY)
        return true
    end
    
    -- Use Summon Darkglare
    if settings.cooldownSettings.useDarkglare and 
       API.CanCast(spells.SUMMON_DARKGLARE) then
        
        -- Check if we need to align with Dark Soul
        if not settings.cooldownSettings.darkglareWithDarkSoul or
           API.PlayerHasBuff(buffs.DARK_SOUL_MISERY) or
           not talents.hasDarkSoulMisery then
            API.CastSpell(spells.SUMMON_DARKGLARE)
            return true
        end
    end
    
    -- Use Phantom Singularity
    if talents.hasPhantomSingularity and 
       settings.cooldownSettings.usePhantomSingularity and
       settings.abilityControls.phantomSingularity.enabled and
       currentAoETargets >= settings.abilityControls.phantomSingularity.minEnemies and
       API.CanCast(spells.PHANTOM_SINGULARITY) then
        
        -- Check if we should only use during burst
        if not settings.abilityControls.phantomSingularity.useDuringBurstOnly or burstModeActive then
            API.CastSpell(spells.PHANTOM_SINGULARITY)
            return true
        end
    end
    
    -- Use Vile Taint
    if talents.hasVileTaint and 
       settings.rotationSettings.useVileTaint and
       settings.abilityControls.vileTaint.enabled and
       currentAoETargets >= settings.abilityControls.vileTaint.minEnemies and
       API.CanCast(spells.VILE_TAINT) then
        
        -- Check if we should align with Darkglare
        if not settings.abilityControls.vileTaint.useWithDarkglare or darkglareActive then
            API.CastSpellAtCursor(spells.VILE_TAINT)
            return true
        end
    end
    
    -- Use Haunt
    if talents.hasHaunt and 
       settings.rotationSettings.useHaunt and
       settings.abilityControls.haunt.enabled and
       API.CanCast(spells.HAUNT) then
        
        -- Check if we should align with Darkglare
        if not settings.abilityControls.haunt.useWithDarkglare or darkglareActive then
            -- Find best target for Haunt based on priority setting
            local targetGUID = API.GetTargetGUID()
            
            if settings.abilityControls.haunt.targetPriority == "Highest Health" then
                targetGUID = API.GetHighestHealthEnemy(40)
            elseif settings.abilityControls.haunt.targetPriority == "Lowest Health" then
                targetGUID = API.GetLowestHealthEnemy(40)
            end
            
            if targetGUID and targetGUID ~= "" then
                API.CastSpellOnGUID(spells.HAUNT, targetGUID)
                return true
            else
                API.CastSpell(spells.HAUNT)
                return true
            end
        end
    end
    
    -- Use Soul Rot (Covenant)
    local soulRot = Warlock.spells.SOUL_ROT
    if API.HasSpell(soulRot) and API.CanCast(soulRot) then
        -- Check if we should align with Darkglare
        if not settings.cooldownSettings.soulRotWithDarkglare or darkglareActive then
            API.CastSpell(soulRot)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Affliction:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("AfflictionWarlock")
    
    -- Apply DoTs if multidotting is enabled
    if settings.rotationSettings.multidotEnabled then
        -- Get all valid targets
        local validTargets = API.GetAllEnemies(40)
        local maxDotTargets = settings.advancedSettings.maxDotTargets
        
        -- Limit targets if configured
        if maxDotTargets > 0 and #validTargets > maxDotTargets then
            validTargets = API.GetSubTable(validTargets, 1, maxDotTargets)
        end
        
        -- For each target, apply DoTs as needed
        for _, targetGUID in ipairs(validTargets) do
            -- Apply Seed of Corruption for AoE spread
            if settings.rotationSettings.seedOfCorruptionEnabled and
               (not API.TableContains(seedTargets, targetGUID) or
                (self.targetData[targetGUID] and 
                 self.targetData[targetGUID].seedOfCorruption and
                 self.targetData[targetGUID].seedOfCorruptionExpiration - GetTime() < DOT_REFRESH_THRESHOLD)) and
               API.CanCast(spells.SEED_OF_CORRUPTION) and
               currentSoulShards >= 1 then
                API.CastSpellOnGUID(spells.SEED_OF_CORRUPTION, targetGUID)
                return true
            end
            
            -- Apply Agony
            if (not API.TableContains(agonyTargets, targetGUID) or
                (self.targetData[targetGUID] and 
                 self.targetData[targetGUID].agony and
                 self.targetData[targetGUID].agonyExpiration - GetTime() < DOT_REFRESH_THRESHOLD)) and
               API.CanCast(spells.AGONY) then
                API.CastSpellOnGUID(spells.AGONY, targetGUID)
                return true
            end
            
            -- Apply Corruption
            if (not API.TableContains(corruptionTargets, targetGUID) or
                (self.targetData[targetGUID] and 
                 self.targetData[targetGUID].corruption and
                 self.targetData[targetGUID].corruptionExpiration - GetTime() < DOT_REFRESH_THRESHOLD)) and
               API.CanCast(spells.CORRUPTION) then
                API.CastSpellOnGUID(spells.CORRUPTION, targetGUID)
                return true
            end
            
            -- Apply Siphon Life if talented and DoTs are not capped
            if talents.hasSiphonLife and
               (not API.TableContains(siphonLifeTargets, targetGUID) or
                (self.targetData[targetGUID] and 
                 self.targetData[targetGUID].siphonLife and
                 self.targetData[targetGUID].siphonLifeExpiration - GetTime() < DOT_REFRESH_THRESHOLD)) and
               API.CanCast(spells.SIPHON_LIFE) then
                
                -- Check max DoTs per target
                local maxDotsPerTarget = settings.advancedSettings.maxDotsPerTarget
                if maxDotsPerTarget == 0 or self:CountDotsOnTarget(targetGUID) < maxDotsPerTarget then
                    API.CastSpellOnGUID(spells.SIPHON_LIFE, targetGUID)
                    return true
                end
            end
        end
    end
    
    -- Use Malefic Rapture for AoE burst
    if currentSoulShards >= settings.advancedSettings.maleficRaptureShards and 
       API.CanCast(spells.MALEFIC_RAPTURE) then
        
        -- Check if we should save shards for burst
        if not settings.advancedSettings.holdShardsForBurst or 
           burstModeActive or 
           currentSoulShards >= SOUL_SHARD_THRESHOLD then
            API.CastSpell(spells.MALEFIC_RAPTURE)
            return true
        end
    end
    
    -- Use Drain Soul/Shadow Bolt as filler
    if talents.hasDrainSoul and API.CanCast(spells.DRAIN_SOUL) then
        -- Use Drain Soul if talented
        API.CastSpell(spells.DRAIN_SOUL)
        return true
    elseif API.CanCast(spells.SHADOW_BOLT) then
        -- Use Shadow Bolt otherwise
        if nightfallProc then
            -- Prioritize using Nightfall proc
            API.PrintDebug("Using Shadow Bolt with Nightfall proc")
        end
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Affliction:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("AfflictionWarlock")
    local targetGUID = API.GetTargetGUID()
    
    if not targetGUID or targetGUID == "" then
        return false
    end
    
    -- Initialize target data if needed
    if not self.targetData[targetGUID] then
        self:UpdateTargetData()
    end
    
    -- Apply DoTs to primary target
    
    -- Apply Agony
    if (not self.targetData[targetGUID].agony or
        self.targetData[targetGUID].agonyExpiration - GetTime() < DOT_REFRESH_THRESHOLD) and
       API.CanCast(spells.AGONY) then
        API.CastSpell(spells.AGONY)
        return true
    end
    
    -- Apply Corruption
    if (not self.targetData[targetGUID].corruption or
        self.targetData[targetGUID].corruptionExpiration - GetTime() < DOT_REFRESH_THRESHOLD) and
       API.CanCast(spells.CORRUPTION) then
        API.CastSpell(spells.CORRUPTION)
        return true
    end
    
    -- Apply Unstable Affliction
    if (not self.targetData[targetGUID].unstableAffliction or
        self.targetData[targetGUID].unstableAfflictionExpiration - GetTime() < DOT_REFRESH_THRESHOLD) and
       API.CanCast(spells.UNSTABLE_AFFLICTION) and
       currentSoulShards >= 1 then
        API.CastSpell(spells.UNSTABLE_AFFLICTION)
        return true
    end
    
    -- Apply Siphon Life if talented
    if talents.hasSiphonLife and
       (not self.targetData[targetGUID].siphonLife or
        self.targetData[targetGUID].siphonLifeExpiration - GetTime() < DOT_REFRESH_THRESHOLD) and
       API.CanCast(spells.SIPHON_LIFE) then
        API.CastSpell(spells.SIPHON_LIFE)
        return true
    end
    
    -- Use Phantom Singularity if talented
    if talents.hasPhantomSingularity and 
       settings.cooldownSettings.usePhantomSingularity and
       (not self.targetData[targetGUID].phantomSingularity) and
       API.CanCast(spells.PHANTOM_SINGULARITY) then
        API.CastSpell(spells.PHANTOM_SINGULARITY)
        return true
    end
    
    -- Use Vile Taint if talented
    if talents.hasVileTaint and 
       settings.rotationSettings.useVileTaint and
       (not self.targetData[targetGUID].vileTaint) and
       API.CanCast(spells.VILE_TAINT) and
       currentSoulShards >= 1 then
        API.CastSpellAtCursor(spells.VILE_TAINT)
        return true
    end
    
    -- Use Haunt if talented
    if talents.hasHaunt and
       settings.rotationSettings.useHaunt and
       (not self.targetData[targetGUID].haunt) and
       API.CanCast(spells.HAUNT) and
       currentSoulShards >= 1 then
        API.CastSpell(spells.HAUNT)
        return true
    end
    
    -- Use Malefic Rapture for damage
    if currentSoulShards >= settings.advancedSettings.maleficRaptureShards and 
       API.CanCast(spells.MALEFIC_RAPTURE) then
        
        -- Check if we should save shards for burst
        if not settings.advancedSettings.holdShardsForBurst or 
           burstModeActive or 
           currentSoulShards >= SOUL_SHARD_THRESHOLD then
            
            -- Use Malefic Rapture
            API.CastSpell(spells.MALEFIC_RAPTURE)
            return true
        end
    end
    
    -- Use Drain Life with Inevitable Demise stacks
    if talents.hasInevitableDemise and 
       inevitableDemiseStacks >= 50 and
       API.CanCast(spells.DRAIN_LIFE) then
        API.CastSpell(spells.DRAIN_LIFE)
        return true
    end
    
    -- Use Drain Soul/Shadow Bolt as filler
    if talents.hasDrainSoul and API.CanCast(spells.DRAIN_SOUL) then
        -- Use Drain Soul if talented
        API.CastSpell(spells.DRAIN_SOUL)
        return true
    elseif API.CanCast(spells.SHADOW_BOLT) then
        -- Use Shadow Bolt otherwise
        if nightfallProc then
            -- Prioritize using Nightfall proc
            API.PrintDebug("Using Shadow Bolt with Nightfall proc")
        end
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    return false
end

-- Count DoTs on a target
function Affliction:CountDotsOnTarget(targetGUID)
    if not self.targetData[targetGUID] then
        return 0
    end
    
    local count = 0
    
    if self.targetData[targetGUID].agony then count = count + 1 end
    if self.targetData[targetGUID].corruption then count = count + 1 end
    if self.targetData[targetGUID].unstableAffliction then count = count + 1 end
    if self.targetData[targetGUID].siphonLife then count = count + 1 end
    
    return count
end

-- Handle specialization change
function Affliction:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentSoulShards = API.GetPlayerPower()
    phantomSingularityActive = false
    darkglareActive = false
    nightfallProc = false
    inevitableDemiseStacks = 0
    maleficRaptureQueued = false
    
    API.PrintDebug("Affliction Warlock state reset on spec change")
    
    return true
end

-- Return the module for loading
return Affliction