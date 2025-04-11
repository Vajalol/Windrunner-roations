------------------------------------------
-- WindrunnerRotations - Fury Warrior Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Fury = {}
addon.Classes.Warrior.Fury = Fury

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local Warrior = addon.Classes.Warrior

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local enrageActive = false

-- Constants
local FURY_SPEC_ID = 72
local RAGE_THRESHOLD_HIGH = 80
local RAGE_THRESHOLD_LOW = 30
local DEFAULT_AOE_THRESHOLD = 3

-- Initialize the Fury module
function Fury:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Fury Warrior module initialized")
    
    return true
end

-- Register spell IDs
function Fury:RegisterSpells()
    -- Active abilities
    spells.BLOODTHIRST = 23881
    spells.RAGING_BLOW = 85288
    spells.RAMPAGE = 184367
    spells.EXECUTE = 5308
    spells.WHIRLWIND = 190411
    spells.ONSLAUGHT = 315720
    spells.CRUSHING_BLOW = 335097
    spells.SLAM = 1464
    spells.ODYN_FURY = 385059
    
    -- Cooldowns
    spells.RECKLESSNESS = 1719
    spells.ENRAGED_REGENERATION = 184364
    spells.SIEGEBREAKER = 280772
    
    -- Buffs/Procs
    spells.ENRAGE = 184362
    spells.WHIRLWIND_BUFF = 85739
    spells.RECKLESSNESS_BUFF = 1719
    spells.SUDDEN_DEATH = 280776
    spells.ENRAGED_REGENERATION_BUFF = 184364
    spells.SIEGEBREAKER_DEBUFF = 280773
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.ENRAGE = spells.ENRAGE
    buffs.WHIRLWIND_BUFF = spells.WHIRLWIND_BUFF
    buffs.RECKLESSNESS = spells.RECKLESSNESS_BUFF
    buffs.SUDDEN_DEATH = spells.SUDDEN_DEATH
    buffs.ENRAGED_REGENERATION = spells.ENRAGED_REGENERATION_BUFF
    
    debuffs.SIEGEBREAKER = spells.SIEGEBREAKER_DEBUFF
    
    return true
end

-- Register variables to track
function Fury:RegisterVariables()
    -- Talent tracking
    talents.hasOnslaught = false
    talents.hasCrushingBlow = false
    talents.hasSiegebreaker = false
    talents.hasSuddenDeath = false
    talents.hasMeatCleaver = false
    talents.hasFreshMeat = false
    talents.hasMassacre = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Fury:RegisterSettings()
    ConfigRegistry:RegisterSettings("FuryWarrior", {
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
            rampageThreshold = {
                displayName = "Rampage Rage Threshold",
                description = "Rage threshold to cast Rampage",
                type = "slider",
                min = 80,
                max = 100,
                default = 80
            },
            useWhirlwind = {
                displayName = "Use Whirlwind for Single Target",
                description = "Use Whirlwind in single target for Meat Cleaver buff",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useRecklessness = {
                displayName = "Use Recklessness",
                description = "Automatically use Recklessness for burst damage",
                type = "toggle",
                default = true
            },
            useSiegebreaker = {
                displayName = "Use Siegebreaker",
                description = "Automatically use Siegebreaker when available",
                type = "toggle",
                default = true
            },
            useEnragedRegeneration = {
                displayName = "Use Enraged Regeneration",
                description = "Automatically use Enraged Regeneration as a defensive",
                type = "toggle",
                default = true
            },
            enragedRegenThreshold = {
                displayName = "Enraged Regeneration Health Threshold",
                description = "Health percentage to use Enraged Regeneration",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            }
        },
        
        advancedSettings = {
            holdExecute = {
                displayName = "Hold Execute With Sudden Death",
                description = "Hold Execute procs for Recklessness windows",
                type = "toggle",
                default = false
            },
            whirlwindRefreshThreshold = {
                displayName = "Whirlwind Refresh Threshold",
                description = "Time remaining on Whirlwind buff to refresh it",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            enrageUptime = {
                displayName = "Prioritize Enrage Uptime",
                description = "Prioritize abilities that can trigger Enrage",
                type = "toggle",
                default = true
            },
            executeThreshold = {
                displayName = "Execute Health Threshold",
                description = "Target health percentage to use Execute (with Massacre)",
                type = "slider",
                min = 20,
                max = 35,
                default = 35
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Recklessness controls
            recklessness = AAC.RegisterAbility(spells.RECKLESSNESS, {
                enabled = true,
                useDuringBurstOnly = true,
                minimumHealthPercent = 0,
                useWithEnrage = true
            }),
            
            -- Siegebreaker controls
            siegebreaker = AAC.RegisterAbility(spells.SIEGEBREAKER, {
                enabled = true,
                useDuringBurstOnly = false,
                alignment = "Recklessness",
                alignmentOffset = 0
            }),
            
            -- Onslaught controls
            onslaught = AAC.RegisterAbility(spells.ONSLAUGHT, {
                enabled = true,
                useDuringEnrage = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Fury:RegisterEvents()
    -- Register for combat log events
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
function Fury:UpdateTalentInfo()
    -- Check for important talents
    talents.hasOnslaught = API.HasTalent(spells.ONSLAUGHT)
    talents.hasCrushingBlow = API.HasTalent(spells.CRUSHING_BLOW)
    talents.hasSiegebreaker = API.HasTalent(spells.SIEGEBREAKER)
    talents.hasSuddenDeath = API.HasTalent(spells.SUDDEN_DEATH)
    talents.hasMeatCleaver = API.HasTalent(spells.WHIRLWIND_BUFF) -- Meat Cleaver is flagged by Whirlwind buff ID
    talents.hasMassacre = false -- Would check actual talent ID here
    
    API.PrintDebug("Fury Warrior talents updated")
    
    return true
end

-- Update target data
function Fury:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                siegebreaker = false,
                siegebreakerExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Melee cleave range
    
    return true
end

-- Handle combat log events
function Fury:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only track events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track Enrage buff application
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        if spellID == spells.ENRAGE and destGUID == API.GetPlayerGUID() then
            enrageActive = true
        end
        
        -- Track Siegebreaker debuff
        if spellID == spells.SIEGEBREAKER_DEBUFF and self.targetData[destGUID] then
            self.targetData[destGUID].siegebreaker = true
            self.targetData[destGUID].siegebreakerExpiration = select(6, API.GetDebuffInfo(destGUID, spells.SIEGEBREAKER_DEBUFF))
        end
    end
    
    -- Track Enrage buff removal
    if eventType == "SPELL_AURA_REMOVED" then
        if spellID == spells.ENRAGE and destGUID == API.GetPlayerGUID() then
            enrageActive = false
        end
        
        -- Track Siegebreaker debuff removal
        if spellID == spells.SIEGEBREAKER_DEBUFF and self.targetData[destGUID] then
            self.targetData[destGUID].siegebreaker = false
        end
    end
    
    return true
end

-- Main rotation function
function Fury:RunRotation()
    -- Check if we should be running Fury Warrior logic
    if API.GetActiveSpecID() ~= FURY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FuryWarrior")
    
    -- Update variables
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    enrageActive = API.PlayerHasBuff(buffs.ENRAGE)
    
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
function Fury:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("FuryWarrior")
    
    -- Use Enraged Regeneration for defense
    if settings.cooldownSettings.useEnragedRegeneration and 
       API.GetPlayerHealthPercent() <= settings.cooldownSettings.enragedRegenThreshold and
       API.CanCast(spells.ENRAGED_REGENERATION) then
        API.CastSpell(spells.ENRAGED_REGENERATION)
        return true
    end
    
    -- Skip offensive cooldowns if not in burst mode and settings require burst mode
    if not burstModeActive and settings.abilityControls.recklessness.useDuringBurstOnly then
        return false
    end
    
    -- Use Siegebreaker
    if talents.hasSiegebreaker and 
       settings.cooldownSettings.useSiegebreaker and
       settings.abilityControls.siegebreaker.enabled and
       API.CanCast(spells.SIEGEBREAKER) then
        
        -- Check if we should align with Recklessness
        if settings.abilityControls.siegebreaker.alignment == "Recklessness" then
            local recklessnessCD = API.GetSpellCooldownRemaining(spells.RECKLESSNESS)
            
            -- Use Siegebreaker if Recklessness is active or about to come off cooldown
            if API.PlayerHasBuff(buffs.RECKLESSNESS) or 
               recklessnessCD <= settings.abilityControls.siegebreaker.alignmentOffset or
               recklessnessCD > 20 then -- Don't hold too long
                API.CastSpell(spells.SIEGEBREAKER)
                return true
            end
        else
            -- Use without alignment
            API.CastSpell(spells.SIEGEBREAKER)
            return true
        end
    end
    
    -- Use Recklessness for burst
    if settings.cooldownSettings.useRecklessness and 
       settings.abilityControls.recklessness.enabled and
       API.CanCast(spells.RECKLESSNESS) then
        
        -- Check if we need Enrage first
        if not settings.abilityControls.recklessness.useWithEnrage or enrageActive then
            -- Check health threshold
            if API.GetTargetHealthPercent() >= settings.abilityControls.recklessness.minimumHealthPercent then
                API.CastSpell(spells.RECKLESSNESS)
                return true
            end
        end
    end
    
    return false
end

-- Handle AoE rotation
function Fury:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("FuryWarrior")
    local playerRage = API.GetPlayerPower()
    
    -- Use Whirlwind to buff cleave abilities
    if talents.hasMeatCleaver and not API.PlayerHasBuff(buffs.WHIRLWIND_BUFF) and API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Refresh Whirlwind buff if it's about to expire
    if talents.hasMeatCleaver and 
       API.PlayerHasBuff(buffs.WHIRLWIND_BUFF) and
       API.GetPlayerBuffTimeRemaining(buffs.WHIRLWIND_BUFF) <= settings.advancedSettings.whirlwindRefreshThreshold and
       API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Use Rampage to trigger Enrage and spend rage
    if playerRage >= settings.rotationSettings.rampageThreshold and API.CanCast(spells.RAMPAGE) then
        API.CastSpell(spells.RAMPAGE)
        return true
    end
    
    -- Use Odyn's Fury if available (big AoE damage)
    if API.CanCast(spells.ODYN_FURY) then
        API.CastSpell(spells.ODYN_FURY)
        return true
    end
    
    -- Use Onslaught if talented during Enrage
    if talents.hasOnslaught and 
       settings.abilityControls.onslaught.enabled and
       API.CanCast(spells.ONSLAUGHT) then
        
        if not settings.abilityControls.onslaught.useDuringEnrage or enrageActive then
            API.CastSpell(spells.ONSLAUGHT)
            return true
        end
    end
    
    -- Execute in Execute range
    local executeThreshold = talents.hasMassacre and settings.advancedSettings.executeThreshold or 20
    if API.GetTargetHealthPercent() <= executeThreshold and API.CanCast(spells.EXECUTE) then
        -- Check for Sudden Death procs outside Execute range
        if API.PlayerHasBuff(buffs.SUDDEN_DEATH) or API.GetTargetHealthPercent() <= executeThreshold then
            -- Skip if we're holding Execute for Recklessness
            if not settings.advancedSettings.holdExecute or API.PlayerHasBuff(buffs.RECKLESSNESS) then
                API.CastSpell(spells.EXECUTE)
                return true
            end
        end
    end
    
    -- Use Bloodthirst to generate rage and potentially trigger Enrage
    if API.CanCast(spells.BLOODTHIRST) then
        API.CastSpell(spells.BLOODTHIRST)
        return true
    end
    
    -- Use Crushing Blow if talented
    if talents.hasCrushingBlow and API.CanCast(spells.CRUSHING_BLOW) then
        API.CastSpell(spells.CRUSHING_BLOW)
        return true
    end
    
    -- Use Raging Blow
    if API.CanCast(spells.RAGING_BLOW) then
        API.CastSpell(spells.RAGING_BLOW)
        return true
    end
    
    -- Use Whirlwind as filler for AoE
    if API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Use Slam as last resort
    if API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Fury:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("FuryWarrior")
    local playerRage = API.GetPlayerPower()
    
    -- Use Whirlwind to buff cleave abilities with Meat Cleaver talent
    if talents.hasMeatCleaver and 
       settings.rotationSettings.useWhirlwind and
       not API.PlayerHasBuff(buffs.WHIRLWIND_BUFF) and 
       API.CanCast(spells.WHIRLWIND) then
        API.CastSpell(spells.WHIRLWIND)
        return true
    end
    
    -- Use Rampage to trigger Enrage and spend rage
    if playerRage >= settings.rotationSettings.rampageThreshold and API.CanCast(spells.RAMPAGE) then
        API.CastSpell(spells.RAMPAGE)
        return true
    end
    
    -- Execute in Execute range
    local executeThreshold = talents.hasMassacre and settings.advancedSettings.executeThreshold or 20
    if API.GetTargetHealthPercent() <= executeThreshold and API.CanCast(spells.EXECUTE) then
        -- Check for Sudden Death procs outside Execute range
        if API.PlayerHasBuff(buffs.SUDDEN_DEATH) or API.GetTargetHealthPercent() <= executeThreshold then
            -- Skip if we're holding Execute for Recklessness
            if not settings.advancedSettings.holdExecute or API.PlayerHasBuff(buffs.RECKLESSNESS) then
                API.CastSpell(spells.EXECUTE)
                return true
            end
        end
    end
    
    -- Prioritize Bloodthirst if not Enraged and we care about Enrage uptime
    if settings.advancedSettings.enrageUptime and 
       not enrageActive and 
       API.CanCast(spells.BLOODTHIRST) then
        API.CastSpell(spells.BLOODTHIRST)
        return true
    end
    
    -- Use Onslaught if talented during Enrage
    if talents.hasOnslaught and 
       settings.abilityControls.onslaught.enabled and
       API.CanCast(spells.ONSLAUGHT) then
        
        if not settings.abilityControls.onslaught.useDuringEnrage or enrageActive then
            API.CastSpell(spells.ONSLAUGHT)
            return true
        end
    end
    
    -- Use Crushing Blow if talented
    if talents.hasCrushingBlow and API.CanCast(spells.CRUSHING_BLOW) then
        API.CastSpell(spells.CRUSHING_BLOW)
        return true
    end
    
    -- Use Raging Blow
    if API.CanCast(spells.RAGING_BLOW) then
        API.CastSpell(spells.RAGING_BLOW)
        return true
    end
    
    -- Use Bloodthirst
    if API.CanCast(spells.BLOODTHIRST) then
        API.CastSpell(spells.BLOODTHIRST)
        return true
    end
    
    -- Use Slam as filler
    if API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle specialization change
function Fury:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    enrageActive = false
    
    return true
end

-- Return the module for loading
return Fury