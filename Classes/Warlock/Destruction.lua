------------------------------------------
-- WindrunnerRotations - Destruction Warlock Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Destruction = {}
addon.Classes.Warlock.Destruction = Destruction

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
local havocActive = false
local havocTarget = nil
local inflowActive = false
local backdraftStacks = 0
local immolateTargets = {}
local conflagCharges = 0
local infernalActive = false
local darkglareActive = false

-- Constants
local DESTRUCTION_SPEC_ID = 267
local SOUL_SHARD_THRESHOLD = 4
local DEFAULT_AOE_THRESHOLD = 3
local IMMOLATE_REFRESH_THRESHOLD = 5 -- Time (in seconds) to start immolate refresh

-- Initialize the Destruction module
function Destruction:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Destruction Warlock module initialized")
    
    return true
end

-- Register spell IDs
function Destruction:RegisterSpells()
    -- Destruction Abilities
    spells.CHAOS_BOLT = 116858
    spells.INCINERATE = 29722
    spells.IMMOLATE = 348
    spells.CONFLAGRATE = 17962
    spells.RAIN_OF_FIRE = 5740
    spells.HAVOC = 80240
    spells.CHANNEL_DEMONFIRE = 196447
    spells.CATACLYSM = 152108
    spells.SHADOWBURN = 17877
    spells.SOUL_FIRE = 6353
    spells.DARK_SOUL_INSTABILITY = 113858
    spells.SUMMON_INFERNAL = 1122
    spells.GRIMOIRE_OF_SACRIFICE = 108503
    spells.FIRE_AND_BRIMSTONE = 196408
    spells.INTERNAL_COMBUSTION = 266134
    spells.REVERSE_ENTROPY = 205148
    spells.ERADICATION = 196412
    spells.ROARING_BLAZE = 205184
    
    -- Procs/Buffs
    spells.BACKDRAFT = 196406
    spells.BACKDRAFT_BUFF = 117828
    spells.ERADICATION_DEBUFF = 196414
    spells.HAVOC_BUFF = 80240
    spells.INFERNAL_BUFF = 1122
    spells.DARK_SOUL_INSTABILITY_BUFF = 113858
    spells.INFLOW = 273521
    spells.INFLOW_BUFF = 273525
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.BACKDRAFT = spells.BACKDRAFT_BUFF
    buffs.HAVOC = spells.HAVOC_BUFF
    buffs.INFERNAL = spells.INFERNAL_BUFF
    buffs.DARK_SOUL_INSTABILITY = spells.DARK_SOUL_INSTABILITY_BUFF
    buffs.INFLOW = spells.INFLOW_BUFF
    
    debuffs.IMMOLATE = spells.IMMOLATE
    debuffs.ERADICATION = spells.ERADICATION_DEBUFF
    debuffs.HAVOC = spells.HAVOC_BUFF
    
    return true
end

-- Register variables to track
function Destruction:RegisterVariables()
    -- Talent tracking
    talents.hasChannelDemonfire = false
    talents.hasCataclysm = false
    talents.hasShadowburn = false
    talents.hasSoulFire = false
    talents.hasDarkSoulInstability = false
    talents.hasFireAndBrimstone = false
    talents.hasInternalCombustion = false
    talents.hasReverseEntropy = false
    talents.hasEradication = false
    talents.hasRoaringBlaze = false
    talents.hasGrimoireOfSacrifice = false
    talents.hasInflow = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Destruction:RegisterSettings()
    ConfigRegistry:RegisterSettings("DestructionWarlock", {
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
            useHavoc = {
                displayName = "Use Havoc",
                description = "Use Havoc for cleave damage",
                type = "toggle",
                default = true
            },
            useCataclysm = {
                displayName = "Use Cataclysm",
                description = "Use Cataclysm when talented",
                type = "toggle",
                default = true
            },
            multidotEnabled = {
                displayName = "Enable Multidotting",
                description = "Apply Immolate to multiple targets",
                type = "toggle",
                default = true
            },
            primaryDotTarget = {
                displayName = "Primary DoT Target",
                description = "Which target to prioritize for Immolate",
                type = "dropdown",
                options = {"Target", "Focus", "Highest Health", "Lowest Health"},
                default = "Target"
            }
        },
        
        cooldownSettings = {
            useDarkSoul = {
                displayName = "Use Dark Soul: Instability",
                description = "Automatically use Dark Soul: Instability for burst",
                type = "toggle",
                default = true
            },
            useInfernal = {
                displayName = "Use Summon Infernal",
                description = "Automatically summon Infernal",
                type = "toggle",
                default = true
            },
            useChannelDemonfire = {
                displayName = "Use Channel Demonfire",
                description = "Use Channel Demonfire when talented",
                type = "toggle",
                default = true
            },
            infernalWithDarkSoul = {
                displayName = "Align Infernal with Dark Soul",
                description = "Only use Infernal with Dark Soul active",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            maxImmolateTargets = {
                displayName = "Max Immolate Targets",
                description = "Maximum targets to apply Immolate to (0 = all)",
                type = "slider",
                min = 0,
                max = 10,
                default = 0
            },
            holdCharges = {
                displayName = "Hold Conflagrate Charges",
                description = "Minimum Conflagrate charges to keep available",
                type = "slider",
                min = 0,
                max = 2,
                default = 1
            },
            poolShards = {
                displayName = "Pool Soul Shards",
                description = "Save Soul Shards for burst or havoc",
                type = "toggle",
                default = true
            },
            minShardsForChaos = {
                displayName = "Min Shards for Chaos Bolt",
                description = "Minimum Soul Shards to cast Chaos Bolt",
                type = "slider",
                min = 1,
                max = 5,
                default = 2
            },
            useBackdraft = {
                displayName = "Use Backdraft",
                description = "Use Backdraft procs efficiently",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Havoc controls
            havoc = AAC.RegisterAbility(spells.HAVOC, {
                enabled = true,
                targetPriority = "Highest Health",
                useDuringBurstOnly = false
            }),
            
            -- Cataclysm controls
            cataclysm = AAC.RegisterAbility(spells.CATACLYSM, {
                enabled = true,
                minEnemies = 3,
                useWithInfernal = true
            }),
            
            -- Channel Demonfire controls
            channelDemonfire = AAC.RegisterAbility(spells.CHANNEL_DEMONFIRE, {
                enabled = true,
                minImmolateTargets = 1,
                useOnCooldown = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Destruction:RegisterEvents()
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
function Destruction:UpdateTalentInfo()
    -- Check for important talents
    talents.hasChannelDemonfire = API.HasTalent(spells.CHANNEL_DEMONFIRE)
    talents.hasCataclysm = API.HasTalent(spells.CATACLYSM)
    talents.hasShadowburn = API.HasTalent(spells.SHADOWBURN)
    talents.hasSoulFire = API.HasTalent(spells.SOUL_FIRE)
    talents.hasDarkSoulInstability = API.HasTalent(spells.DARK_SOUL_INSTABILITY)
    talents.hasFireAndBrimstone = API.HasTalent(spells.FIRE_AND_BRIMSTONE)
    talents.hasInternalCombustion = API.HasTalent(spells.INTERNAL_COMBUSTION)
    talents.hasReverseEntropy = API.HasTalent(spells.REVERSE_ENTROPY)
    talents.hasEradication = API.HasTalent(spells.ERADICATION)
    talents.hasRoaringBlaze = API.HasTalent(spells.ROARING_BLAZE)
    talents.hasGrimoireOfSacrifice = API.HasTalent(spells.GRIMOIRE_OF_SACRIFICE)
    talents.hasInflow = API.HasTalent(spells.INFLOW)
    
    API.PrintDebug("Destruction Warlock talents updated")
    
    return true
end

-- Update soul shard tracking
function Destruction:UpdateSoulShards()
    currentSoulShards = API.GetPlayerPower()
    return true
end

-- Update target data
function Destruction:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                immolate = false,
                immolateExpiration = 0,
                havoc = false,
                havocExpiration = 0,
                eradication = false,
                eradicationExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Destruction AoE radius
    
    -- Update immolate target tracker
    local validTargets = API.GetAllEnemies(40) -- Get all enemies within 40 yards
    
    immolateTargets = {}
    
    for _, targetGUID in ipairs(validTargets) do
        if self.targetData[targetGUID] and self.targetData[targetGUID].immolate then
            table.insert(immolateTargets, targetGUID)
        end
    end
    
    -- Update Havoc tracking
    havocActive = false
    havocTarget = nil
    
    for _, targetGUID in ipairs(validTargets) do
        if self.targetData[targetGUID] and self.targetData[targetGUID].havoc then
            havocActive = true
            havocTarget = targetGUID
            break
        end
    end
    
    return true
end

-- Handle combat log events
function Destruction:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Backdraft buff
            if spellID == spells.BACKDRAFT_BUFF then
                backdraftStacks = 3 -- Backdraft gives 3 stacks
                API.PrintDebug("Backdraft activated: 3 stacks")
            end
            
            -- Track Inflow buff
            if spellID == spells.INFLOW_BUFF then
                inflowActive = true
                API.PrintDebug("Inflow activated")
            end
            
            -- Track Dark Soul: Instability
            if spellID == spells.DARK_SOUL_INSTABILITY_BUFF then
                API.PrintDebug("Dark Soul: Instability activated")
            end
            
            -- Track Infernal summon
            if spellID == spells.INFERNAL_BUFF then
                infernalActive = true
                API.PrintDebug("Infernal summoned")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == spells.IMMOLATE then
                self.targetData[destGUID].immolate = true
                self.targetData[destGUID].immolateExpiration = select(6, API.GetDebuffInfo(destGUID, spells.IMMOLATE))
                if not API.TableContains(immolateTargets, destGUID) then
                    table.insert(immolateTargets, destGUID)
                end
            elseif spellID == spells.HAVOC_BUFF then
                self.targetData[destGUID].havoc = true
                self.targetData[destGUID].havocExpiration = select(6, API.GetDebuffInfo(destGUID, spells.HAVOC_BUFF))
                havocActive = true
                havocTarget = destGUID
            elseif spellID == spells.ERADICATION_DEBUFF then
                self.targetData[destGUID].eradication = true
                self.targetData[destGUID].eradicationExpiration = select(6, API.GetDebuffInfo(destGUID, spells.ERADICATION_DEBUFF))
            end
        end
    end
    
    -- Track buff/debuff removals and stack changes
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Backdraft buff removal
            if spellID == spells.BACKDRAFT_BUFF then
                backdraftStacks = 0
                API.PrintDebug("Backdraft faded")
            end
            
            -- Track Inflow buff removal
            if spellID == spells.INFLOW_BUFF then
                inflowActive = false
                API.PrintDebug("Inflow faded")
            end
            
            -- Track Dark Soul: Instability removal
            if spellID == spells.DARK_SOUL_INSTABILITY_BUFF then
                API.PrintDebug("Dark Soul: Instability faded")
            end
            
            -- Track Infernal despawn
            if spellID == spells.INFERNAL_BUFF then
                infernalActive = false
                API.PrintDebug("Infernal despawned")
            end
        end
        
        -- Track debuff removals from targets
        if self.targetData[destGUID] then
            if spellID == spells.IMMOLATE then
                self.targetData[destGUID].immolate = false
                API.TableRemove(immolateTargets, destGUID)
            elseif spellID == spells.HAVOC_BUFF then
                self.targetData[destGUID].havoc = false
                if havocTarget == destGUID then
                    havocActive = false
                    havocTarget = nil
                end
            elseif spellID == spells.ERADICATION_DEBUFF then
                self.targetData[destGUID].eradication = false
            end
        end
    end
    
    -- Track Backdraft stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" then
        if spellID == spells.BACKDRAFT_BUFF and destGUID == API.GetPlayerGUID() then
            backdraftStacks = select(4, UnitBuff("player", GetSpellInfo(spells.BACKDRAFT_BUFF)))
            API.PrintDebug("Backdraft now at " .. tostring(backdraftStacks) .. " stacks")
        end
    end
    
    if eventType == "SPELL_AURA_REMOVED_DOSE" then
        if spellID == spells.BACKDRAFT_BUFF and destGUID == API.GetPlayerGUID() then
            backdraftStacks = select(4, UnitBuff("player", GetSpellInfo(spells.BACKDRAFT_BUFF))) or 0
            API.PrintDebug("Backdraft used, now at " .. tostring(backdraftStacks) .. " stacks")
        end
    end
    
    -- Track important spell casts
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.CONFLAGRATE then
            conflagCharges = API.GetSpellCharges(spells.CONFLAGRATE) or 0
            API.PrintDebug("Conflagrate used, charges remaining: " .. tostring(conflagCharges))
        elseif spellID == spells.SUMMON_INFERNAL then
            infernalActive = true
            C_Timer.After(30, function() -- Infernal lasts 30 seconds
                infernalActive = false
            end)
        end
    end
    
    return true
end

-- Main rotation function
function Destruction:RunRotation()
    -- Check if we should be running Destruction Warlock logic
    if API.GetActiveSpecID() ~= DESTRUCTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("DestructionWarlock")
    
    -- Update variables
    self:UpdateSoulShards()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    conflagCharges = API.GetSpellCharges(spells.CONFLAGRATE) or 0
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
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
function Destruction:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("DestructionWarlock")
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Dark Soul: Instability
    if talents.hasDarkSoulInstability and 
       settings.cooldownSettings.useDarkSoul and
       API.CanCast(spells.DARK_SOUL_INSTABILITY) then
        API.CastSpell(spells.DARK_SOUL_INSTABILITY)
        return true
    end
    
    -- Use Summon Infernal
    if settings.cooldownSettings.useInfernal and
       API.CanCast(spells.SUMMON_INFERNAL) then
        
        -- Check if we need to align with Dark Soul
        if not settings.cooldownSettings.infernalWithDarkSoul or
           API.PlayerHasBuff(buffs.DARK_SOUL_INSTABILITY) or
           not talents.hasDarkSoulInstability then
            API.CastSpellAtCursor(spells.SUMMON_INFERNAL)
            return true
        end
    end
    
    -- Use Cataclysm if talented
    if talents.hasCataclysm and 
       settings.rotationSettings.useCataclysm and
       settings.abilityControls.cataclysm.enabled and
       currentAoETargets >= settings.abilityControls.cataclysm.minEnemies and
       API.CanCast(spells.CATACLYSM) then
        
        -- Check if we should align with Infernal
        if not settings.abilityControls.cataclysm.useWithInfernal or infernalActive then
            API.CastSpellAtCursor(spells.CATACLYSM)
            return true
        end
    end
    
    -- Use Channel Demonfire if talented
    if talents.hasChannelDemonfire and 
       settings.cooldownSettings.useChannelDemonfire and
       settings.abilityControls.channelDemonfire.enabled and
       #immolateTargets >= settings.abilityControls.channelDemonfire.minImmolateTargets and
       API.CanCast(spells.CHANNEL_DEMONFIRE) then
        
        if settings.abilityControls.channelDemonfire.useOnCooldown then
            API.CastSpell(spells.CHANNEL_DEMONFIRE)
            return true
        end
    end
    
    -- Use Soul Fire if talented (as a cooldown during burst)
    if talents.hasSoulFire and API.CanCast(spells.SOUL_FIRE) then
        API.CastSpell(spells.SOUL_FIRE)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Destruction:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("DestructionWarlock")
    
    -- Apply Havoc if not active
    if settings.rotationSettings.useHavoc and
       not havocActive and
       API.CanCast(spells.HAVOC) and
       currentAoETargets > 1 then
        
        -- Find best target for Havoc based on priority setting
        local mainTarget = API.GetTargetGUID()
        local havocTarget = nil
        
        if settings.abilityControls.havoc.targetPriority == "Highest Health" then
            havocTarget = API.GetHighestHealthEnemy(40, mainTarget) -- Exclude main target
        elseif settings.abilityControls.havoc.targetPriority == "Lowest Health" then
            havocTarget = API.GetLowestHealthEnemy(40, mainTarget) -- Exclude main target
        else
            -- Find any valid target that isn't the main target
            local enemies = API.GetAllEnemies(40)
            for _, guid in ipairs(enemies) do
                if guid ~= mainTarget then
                    havocTarget = guid
                    break
                end
            end
        end
        
        if havocTarget then
            API.CastSpellOnGUID(spells.HAVOC, havocTarget)
            return true
        end
    end
    
    -- Apply Immolate if multidotting is enabled
    if settings.rotationSettings.multidotEnabled then
        -- Get all valid targets
        local validTargets = API.GetAllEnemies(40)
        local maxImmolateTargets = settings.advancedSettings.maxImmolateTargets
        
        -- Limit targets if configured
        if maxImmolateTargets > 0 and #validTargets > maxImmolateTargets then
            validTargets = API.GetSubTable(validTargets, 1, maxImmolateTargets)
        end
        
        -- For each target, apply Immolate as needed
        for _, targetGUID in ipairs(validTargets) do
            if not API.TableContains(immolateTargets, targetGUID) or
               (self.targetData[targetGUID] and 
                self.targetData[targetGUID].immolate and
                self.targetData[targetGUID].immolateExpiration - GetTime() < IMMOLATE_REFRESH_THRESHOLD) then
                
                if API.CanCast(spells.IMMOLATE) then
                    API.CastSpellOnGUID(spells.IMMOLATE, targetGUID)
                    return true
                end
            end
        end
    end
    
    -- Use Rain of Fire for AoE
    if currentSoulShards >= 3 and API.CanCast(spells.RAIN_OF_FIRE) then
        API.CastSpellAtCursor(spells.RAIN_OF_FIRE)
        return true
    end
    
    -- Use Chaos Bolt with Havoc for cleave
    if havocActive and 
       currentSoulShards >= settings.advancedSettings.minShardsForChaos and
       API.CanCast(spells.CHAOS_BOLT) then
        API.CastSpell(spells.CHAOS_BOLT)
        return true
    end
    
    -- Use Conflagrate to generate shards, especially with Roaring Blaze
    if API.CanCast(spells.CONFLAGRATE) and 
       conflagCharges > settings.advancedSettings.holdCharges then
        API.CastSpell(spells.CONFLAGRATE)
        return true
    end
    
    -- Use Incinerate for shard generation and damage
    if API.CanCast(spells.INCINERATE) then
        -- Use Backdraft procs if available
        if backdraftStacks > 0 and settings.advancedSettings.useBackdraft then
            API.PrintDebug("Using Incinerate with Backdraft")
        end
        API.CastSpell(spells.INCINERATE)
        return true
    end
    
    -- Use Shadowburn if talented (especially with Fire and Brimstone)
    if talents.hasShadowburn and
       API.CanCast(spells.SHADOWBURN) and
       currentSoulShards >= 1 then
        API.CastSpell(spells.SHADOWBURN)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Destruction:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("DestructionWarlock")
    local targetGUID = API.GetTargetGUID()
    
    if not targetGUID or targetGUID == "" then
        return false
    end
    
    -- Initialize target data if needed
    if not self.targetData[targetGUID] then
        self:UpdateTargetData()
    end
    
    -- Apply Immolate if not present or needs refresh
    if (not self.targetData[targetGUID].immolate or
        self.targetData[targetGUID].immolateExpiration - GetTime() < IMMOLATE_REFRESH_THRESHOLD) and
       API.CanCast(spells.IMMOLATE) then
        API.CastSpell(spells.IMMOLATE)
        return true
    end
    
    -- Apply Havoc to secondary target if available
    if settings.rotationSettings.useHavoc and
       not havocActive and
       API.CanCast(spells.HAVOC) and
       API.GetNumEnemies(40) > 1 then
        
        local secondaryTarget = nil
        local enemies = API.GetAllEnemies(40)
        for _, guid in ipairs(enemies) do
            if guid ~= targetGUID then
                secondaryTarget = guid
                break
            end
        end
        
        if secondaryTarget then
            API.CastSpellOnGUID(spells.HAVOC, secondaryTarget)
            return true
        end
    end
    
    -- Use Conflagrate to generate Backdraft and Soul Shards
    if API.CanCast(spells.CONFLAGRATE) and conflagCharges > settings.advancedSettings.holdCharges then
        -- Additional logic for Roaring Blaze if talented
        if talents.hasRoaringBlaze and self.targetData[targetGUID].immolate then
            -- Prioritize Conflagrate with Roaring Blaze when Immolate is active
            API.PrintDebug("Using Conflagrate with Roaring Blaze")
        end
        
        API.CastSpell(spells.CONFLAGRATE)
        return true
    end
    
    -- Use Chaos Bolt if we have enough shards or for Eradication
    local shouldUseChaos = false
    
    -- Always use with Eradication if it's about to expire
    if talents.hasEradication and 
       self.targetData[targetGUID].eradication and
       self.targetData[targetGUID].eradicationExpiration - GetTime() < 2 then
        shouldUseChaos = true
    end
    
    -- Use if we have enough shards and not pooling or during Havoc
    if currentSoulShards >= settings.advancedSettings.minShardsForChaos and
       (not settings.advancedSettings.poolShards or 
        currentSoulShards >= SOUL_SHARD_THRESHOLD or
        havocActive or
        infernalActive or
        API.PlayerHasBuff(buffs.DARK_SOUL_INSTABILITY)) then
        shouldUseChaos = true
    end
    
    if shouldUseChaos and API.CanCast(spells.CHAOS_BOLT) then
        API.CastSpell(spells.CHAOS_BOLT)
        return true
    end
    
    -- Use Channel Demonfire if talented
    if talents.hasChannelDemonfire and 
       settings.cooldownSettings.useChannelDemonfire and
       self.targetData[targetGUID].immolate and
       API.CanCast(spells.CHANNEL_DEMONFIRE) then
        API.CastSpell(spells.CHANNEL_DEMONFIRE)
        return true
    end
    
    -- Use Shadowburn if talented and target is low health
    if talents.hasShadowburn and
       API.GetTargetHealthPercent() <= 20 and
       API.CanCast(spells.SHADOWBURN) and
       currentSoulShards >= 1 then
        API.CastSpell(spells.SHADOWBURN)
        return true
    end
    
    -- Use Soul Fire if talented
    if talents.hasSoulFire and API.CanCast(spells.SOUL_FIRE) then
        API.CastSpell(spells.SOUL_FIRE)
        return true
    end
    
    -- Use Incinerate as filler
    if API.CanCast(spells.INCINERATE) then
        -- Use Backdraft procs if available
        if backdraftStacks > 0 and settings.advancedSettings.useBackdraft then
            API.PrintDebug("Using Incinerate with Backdraft")
        end
        API.CastSpell(spells.INCINERATE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Destruction:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentSoulShards = API.GetPlayerPower()
    havocActive = false
    havocTarget = nil
    inflowActive = false
    backdraftStacks = API.PlayerHasBuff(buffs.BACKDRAFT) and 3 or 0
    conflagCharges = API.GetSpellCharges(spells.CONFLAGRATE) or 0
    infernalActive = false
    
    API.PrintDebug("Destruction Warlock state reset on spec change")
    
    return true
end

-- Return the module for loading
return Destruction