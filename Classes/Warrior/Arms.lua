------------------------------------------
-- WindrunnerRotations - Arms Warrior Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Arms = {}
addon.Classes.Warrior.Arms = Arms

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
local sweepingStrikesActive = false

-- Constants
local ARMS_SPEC_ID = 71
local RAGE_THRESHOLD_HIGH = 70
local RAGE_THRESHOLD_LOW = 30
local DEFAULT_AOE_THRESHOLD = 3

-- Initialize the Arms module
function Arms:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Arms Warrior module initialized")
    
    return true
end

-- Register spell IDs
function Arms:RegisterSpells()
    -- Active abilities
    spells.MORTAL_STRIKE = 12294
    spells.OVERPOWER = 7384
    spells.EXECUTE = 163201
    spells.SLAM = 1464
    spells.CLEAVE = 845
    spells.WHIRLWIND = 1680
    spells.SWEEPING_STRIKES = 260708
    spells.BLADESTORM = 227847
    spells.COLOSSUS_SMASH = 167105
    spells.WARBREAKER = 262161
    spells.SKULLSPLITTER = 260643
    spells.REND = 772
    
    -- Cooldowns
    spells.AVATAR = 107574
    spells.DIE_BY_THE_SWORD = 118038
    spells.SHARPEN_BLADE = 198817
    
    -- Buffs/Procs
    spells.SUDDEN_DEATH = 52437
    spells.OVERPOWER_BUFF = 7384
    spells.SWEEPING_STRIKES_BUFF = 260708
    spells.DEADLY_CALM = 262228
    spells.BLADESTORM_BUFF = 227847
    spells.DIE_BY_THE_SWORD_BUFF = 118038
    spells.AVATAR_BUFF = 107574
    
    -- Debuffs
    spells.COLOSSUS_SMASH_DEBUFF = 208086
    spells.DEEP_WOUNDS = 262115
    spells.REND_DEBUFF = 772
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SUDDEN_DEATH = spells.SUDDEN_DEATH
    buffs.OVERPOWER = spells.OVERPOWER_BUFF
    buffs.SWEEPING_STRIKES = spells.SWEEPING_STRIKES_BUFF
    buffs.DEADLY_CALM = spells.DEADLY_CALM
    buffs.BLADESTORM = spells.BLADESTORM_BUFF
    buffs.DIE_BY_THE_SWORD = spells.DIE_BY_THE_SWORD_BUFF
    buffs.AVATAR = spells.AVATAR_BUFF
    
    debuffs.COLOSSUS_SMASH = spells.COLOSSUS_SMASH_DEBUFF
    debuffs.DEEP_WOUNDS = spells.DEEP_WOUNDS
    debuffs.REND = spells.REND_DEBUFF
    
    return true
end

-- Register variables to track
function Arms:RegisterVariables()
    -- Talent tracking
    talents.hasRend = false
    talents.hasWarbreaker = false
    talents.hasCleave = false
    talents.hasSkullsplitter = false
    talents.hasDeadlyCalm = false
    talents.hasMassacre = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Arms:RegisterSettings()
    ConfigRegistry:RegisterSettings("ArmsWarrior", {
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
            maintainDeepWounds = {
                displayName = "Maintain Deep Wounds",
                description = "Prioritize keeping Deep Wounds applied",
                type = "toggle",
                default = true
            },
            useRend = {
                displayName = "Use Rend",
                description = "Maintain Rend on the target",
                type = "toggle",
                default = true
            },
            useSlam = {
                displayName = "Use Slam",
                description = "Use Slam as rage dump",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useAvatar = {
                displayName = "Use Avatar",
                description = "Automatically use Avatar for damage boost",
                type = "toggle",
                default = true
            },
            useBladestorm = {
                displayName = "Use Bladestorm",
                description = "Automatically use Bladestorm for AoE damage",
                type = "toggle",
                default = true
            },
            bladestormMinTargets = {
                displayName = "Bladestorm Minimum Targets",
                description = "Minimum number of targets to use Bladestorm",
                type = "slider",
                min = 1,
                max = 8,
                default = 3
            },
            useDieByTheSword = {
                displayName = "Use Die By The Sword",
                description = "Automatically use Die By The Sword as defensive",
                type = "toggle",
                default = true
            },
            dieByTheSwordThreshold = {
                displayName = "Die By The Sword Health Threshold",
                description = "Health percentage to use Die By The Sword",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            }
        },
        
        advancedSettings = {
            holdOverpower = {
                displayName = "Stack Overpower",
                description = "Stack Overpower for increased damage",
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
            },
            holdMortalStrike = {
                displayName = "Hold Mortal Strike",
                description = "Hold Mortal Strike for Colossus Smash windows",
                type = "toggle",
                default = false
            },
            poolRage = {
                displayName = "Pool Rage Threshold",
                description = "Pool rage above this threshold for Execute phase",
                type = "slider",
                min = 50,
                max = 100,
                default = 70
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Avatar controls
            avatar = AAC.RegisterAbility(spells.AVATAR, {
                enabled = true,
                useDuringBurstOnly = true,
                alignment = "ColossusSmash",
                alignmentOffset = 0
            }),
            
            -- Sweeping Strikes controls
            sweepingStrikes = AAC.RegisterAbility(spells.SWEEPING_STRIKES, {
                enabled = true,
                minEnemies = 2
            }),
            
            -- Colossus Smash/Warbreaker controls
            colossusSmash = AAC.RegisterAbility(spells.COLOSSUS_SMASH, {
                enabled = true,
                useDuringBurstOnly = false,
                useDuringExecute = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Arms:RegisterEvents()
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
function Arms:UpdateTalentInfo()
    -- Check for important talents
    talents.hasRend = API.HasTalent(spells.REND)
    talents.hasWarbreaker = API.HasTalent(spells.WARBREAKER)
    talents.hasCleave = API.HasTalent(spells.CLEAVE)
    talents.hasSkullsplitter = API.HasTalent(spells.SKULLSPLITTER)
    talents.hasDeadlyCalm = API.HasTalent(spells.DEADLY_CALM)
    talents.hasMassacre = false -- Would check actual talent ID here
    
    API.PrintDebug("Arms Warrior talents updated")
    
    return true
end

-- Update target data
function Arms:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                deepWounds = false,
                deepWoundsExpiration = 0,
                colossusSmash = false,
                colossusSmashExpiration = 0,
                rend = false,
                rendExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Melee cleave range
    
    return true
end

-- Handle combat log events
function Arms:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only track events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track Sweeping Strikes activation
        if spellID == spells.SWEEPING_STRIKES_BUFF and destGUID == API.GetPlayerGUID() then
            sweepingStrikesActive = true
        end
        
        -- Track debuff application to targets
        if self.targetData[destGUID] then
            -- Deep Wounds application
            if spellID == spells.DEEP_WOUNDS then
                self.targetData[destGUID].deepWounds = true
                self.targetData[destGUID].deepWoundsExpiration = select(6, API.GetDebuffInfo(destGUID, spells.DEEP_WOUNDS))
            end
            
            -- Colossus Smash debuff application
            if spellID == spells.COLOSSUS_SMASH_DEBUFF then
                self.targetData[destGUID].colossusSmash = true
                self.targetData[destGUID].colossusSmashExpiration = select(6, API.GetDebuffInfo(destGUID, spells.COLOSSUS_SMASH_DEBUFF))
            end
            
            -- Rend debuff application
            if talents.hasRend and spellID == spells.REND_DEBUFF then
                self.targetData[destGUID].rend = true
                self.targetData[destGUID].rendExpiration = select(6, API.GetDebuffInfo(destGUID, spells.REND_DEBUFF))
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track Sweeping Strikes deactivation
        if spellID == spells.SWEEPING_STRIKES_BUFF and destGUID == API.GetPlayerGUID() then
            sweepingStrikesActive = false
        end
        
        -- Track debuff removals from targets
        if self.targetData[destGUID] then
            -- Deep Wounds removal
            if spellID == spells.DEEP_WOUNDS then
                self.targetData[destGUID].deepWounds = false
            end
            
            -- Colossus Smash debuff removal
            if spellID == spells.COLOSSUS_SMASH_DEBUFF then
                self.targetData[destGUID].colossusSmash = false
            end
            
            -- Rend debuff removal
            if talents.hasRend and spellID == spells.REND_DEBUFF then
                self.targetData[destGUID].rend = false
            end
        end
    end
    
    return true
end

-- Main rotation function
function Arms:RunRotation()
    -- Check if we should be running Arms Warrior logic
    if API.GetActiveSpecID() ~= ARMS_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ArmsWarrior")
    
    -- Update variables
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    sweepingStrikesActive = API.PlayerHasBuff(buffs.SWEEPING_STRIKES)
    
    -- Skip if player is in Bladestorm
    if API.PlayerHasBuff(buffs.BLADESTORM) then
        return false
    end
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle defensive cooldowns first
    if self:HandleDefensives() then
        return true
    end
    
    -- Handle offensive cooldowns
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

-- Handle defensive abilities
function Arms:HandleDefensives()
    local settings = ConfigRegistry:GetSettings("ArmsWarrior")
    
    -- Use Die By The Sword
    if settings.cooldownSettings.useDieByTheSword and
       API.GetPlayerHealthPercent() <= settings.cooldownSettings.dieByTheSwordThreshold and
       API.CanCast(spells.DIE_BY_THE_SWORD) then
        API.CastSpell(spells.DIE_BY_THE_SWORD)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Arms:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("ArmsWarrior")
    local targetGUID = API.GetTargetGUID()
    local hasColossusSmashDebuff = targetGUID and self.targetData[targetGUID] and self.targetData[targetGUID].colossusSmash
    
    -- Use Sweeping Strikes for AoE
    if settings.abilityControls.sweepingStrikes.enabled and
       currentAoETargets >= settings.abilityControls.sweepingStrikes.minEnemies and
       API.CanCast(spells.SWEEPING_STRIKES) then
        API.CastSpell(spells.SWEEPING_STRIKES)
        return true
    end
    
    -- Skip offensive cooldowns if not in burst mode and settings require burst mode
    if not burstModeActive and settings.abilityControls.avatar.useDuringBurstOnly then
        return false
    end
    
    -- Use Bladestorm for AoE
    if settings.cooldownSettings.useBladestorm and
       currentAoETargets >= settings.cooldownSettings.bladestormMinTargets and
       API.CanCast(spells.BLADESTORM) then
        
        -- Ideally use Bladestorm during Colossus Smash
        if hasColossusSmashDebuff or currentAoETargets >= settings.cooldownSettings.bladestormMinTargets + 2 then
            API.CastSpell(spells.BLADESTORM)
            return true
        end
    end
    
    -- Apply Colossus Smash or Warbreaker
    if settings.abilityControls.colossusSmash.enabled and
       not hasColossusSmashDebuff then
        
        -- Check if target is in execute range and settings prevent Colossus Smash during execute
        local executeThreshold = talents.hasMassacre and settings.advancedSettings.executeThreshold or 20
        local inExecuteRange = API.GetTargetHealthPercent() <= executeThreshold
        
        if settings.abilityControls.colossusSmash.useDuringExecute or not inExecuteRange then
            -- Use Warbreaker if talented, Colossus Smash otherwise
            if talents.hasWarbreaker and API.CanCast(spells.WARBREAKER) then
                API.CastSpell(spells.WARBREAKER)
                return true
            elseif API.CanCast(spells.COLOSSUS_SMASH) then
                API.CastSpell(spells.COLOSSUS_SMASH)
                return true
            end
        end
    end
    
    -- Use Avatar aligned with Colossus Smash if possible
    if settings.cooldownSettings.useAvatar and 
       settings.abilityControls.avatar.enabled and
       API.CanCast(spells.AVATAR) then
        
        if settings.abilityControls.avatar.alignment == "ColossusSmash" then
            -- Use Avatar if Colossus Smash is active or about to be used
            if hasColossusSmashDebuff or 
               API.IsSpellReady(spells.COLOSSUS_SMASH) or 
               (talents.hasWarbreaker and API.IsSpellReady(spells.WARBREAKER)) then
                API.CastSpell(spells.AVATAR)
                return true
            end
        else
            -- Use Avatar without specific alignment
            API.CastSpell(spells.AVATAR)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Arms:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("ArmsWarrior")
    local playerRage = API.GetPlayerPower()
    local targetGUID = API.GetTargetGUID()
    local hasColossusSmashDebuff = targetGUID and self.targetData[targetGUID] and self.targetData[targetGUID].colossusSmash
    
    -- Use Cleave for AoE
    if talents.hasCleave and playerRage >= 20 and API.CanCast(spells.CLEAVE) then
        API.CastSpell(spells.CLEAVE)
        return true
    end
    
    -- Apply Rend if talented and not already applied
    if talents.hasRend and 
       settings.rotationSettings.useRend and 
       API.CanCast(spells.REND) and 
       targetGUID and self.targetData[targetGUID] and 
       (not self.targetData[targetGUID].rend or 
        self.targetData[targetGUID].rendExpiration - GetTime() < 3) then
        API.CastSpell(spells.REND)
        return true
    end
    
    -- Use Whirlwind for AoE
    if API.CanCast(spells.WHIRLWIND) then
        -- Only check rage during Sweeping Strikes to conserve rage
        if not sweepingStrikesActive or (sweepingStrikesActive and playerRage >= 30) then
            API.CastSpell(spells.WHIRLWIND)
            return true
        end
    end
    
    -- Execute in Execute range
    local executeThreshold = talents.hasMassacre and settings.advancedSettings.executeThreshold or 20
    if API.GetTargetHealthPercent() <= executeThreshold and API.CanCast(spells.EXECUTE) then
        -- Also check for Sudden Death procs outside Execute range
        if API.PlayerHasBuff(buffs.SUDDEN_DEATH) or API.GetTargetHealthPercent() <= executeThreshold then
            API.CastSpell(spells.EXECUTE)
            return true
        end
    end
    
    -- Keep Mortal Strike for Deep Wounds
    if settings.rotationSettings.maintainDeepWounds and
       API.CanCast(spells.MORTAL_STRIKE) and 
       targetGUID and self.targetData[targetGUID] and
       (not self.targetData[targetGUID].deepWounds or 
        self.targetData[targetGUID].deepWoundsExpiration - GetTime() < 3) then
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    end
    
    -- Use Overpower to generate rage and buff next Mortal Strike/Execute
    if API.CanCast(spells.OVERPOWER) then
        API.CastSpell(spells.OVERPOWER)
        return true
    end
    
    -- Use Mortal Strike if not holding it
    if not settings.advancedSettings.holdMortalStrike and API.CanCast(spells.MORTAL_STRIKE) then
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    end
    
    -- Use Skullsplitter for rage generation if talented
    if talents.hasSkullsplitter and playerRage < 40 and API.CanCast(spells.SKULLSPLITTER) then
        API.CastSpell(spells.SKULLSPLITTER)
        return true
    end
    
    -- Use Slam if enabled and have enough rage
    if settings.rotationSettings.useSlam and playerRage >= 20 and API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Arms:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("ArmsWarrior")
    local playerRage = API.GetPlayerPower()
    local targetGUID = API.GetTargetGUID()
    local hasColossusSmashDebuff = targetGUID and self.targetData[targetGUID] and self.targetData[targetGUID].colossusSmash
    
    -- Apply Rend if talented and not already applied
    if talents.hasRend and 
       settings.rotationSettings.useRend and 
       API.CanCast(spells.REND) and 
       targetGUID and self.targetData[targetGUID] and 
       (not self.targetData[targetGUID].rend or 
        self.targetData[targetGUID].rendExpiration - GetTime() < 3) then
        API.CastSpell(spells.REND)
        return true
    end
    
    -- Execute in Execute range
    local executeThreshold = talents.hasMassacre and settings.advancedSettings.executeThreshold or 20
    if API.GetTargetHealthPercent() <= executeThreshold and API.CanCast(spells.EXECUTE) then
        -- Also check for Sudden Death procs outside Execute range
        if API.PlayerHasBuff(buffs.SUDDEN_DEATH) or API.GetTargetHealthPercent() <= executeThreshold then
            API.CastSpell(spells.EXECUTE)
            return true
        end
    end
    
    -- Keep Mortal Strike for Deep Wounds
    if settings.rotationSettings.maintainDeepWounds and
       API.CanCast(spells.MORTAL_STRIKE) and 
       targetGUID and self.targetData[targetGUID] and
       (not self.targetData[targetGUID].deepWounds or 
        self.targetData[targetGUID].deepWoundsExpiration - GetTime() < 3) then
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    end
    
    -- Use Skullsplitter for rage generation if talented
    if talents.hasSkullsplitter and playerRage < 40 and API.CanCast(spells.SKULLSPLITTER) then
        API.CastSpell(spells.SKULLSPLITTER)
        return true
    end
    
    -- Stack Overpower if desired
    if settings.advancedSettings.holdOverpower and 
       API.GetPlayerBuffStacks(buffs.OVERPOWER) < 2 and 
       API.CanCast(spells.OVERPOWER) then
        API.CastSpell(spells.OVERPOWER)
        return true
    end
    
    -- Use Mortal Strike if not holding it
    if not settings.advancedSettings.holdMortalStrike and API.CanCast(spells.MORTAL_STRIKE) then
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    elseif settings.advancedSettings.holdMortalStrike and hasColossusSmashDebuff and API.CanCast(spells.MORTAL_STRIKE) then
        -- Use Mortal Strike during Colossus Smash window even if holding it
        API.CastSpell(spells.MORTAL_STRIKE)
        return true
    end
    
    -- Use Overpower to generate rage and buff next MS
    if API.CanCast(spells.OVERPOWER) then
        API.CastSpell(spells.OVERPOWER)
        return true
    end
    
    -- Pool rage for execute phase if target is close to execute threshold
    local poolRage = settings.advancedSettings.poolRage
    local targetHealth = API.GetTargetHealthPercent()
    -- Pool rage if target is within 10% of execute range
    local shouldPoolRage = targetHealth <= executeThreshold + 10 and targetHealth > executeThreshold
    
    -- Use Slam if enabled and have enough rage (and not pooling)
    if settings.rotationSettings.useSlam and 
       playerRage >= 20 and 
       (not shouldPoolRage or playerRage > poolRage) and
       API.CanCast(spells.SLAM) then
        API.CastSpell(spells.SLAM)
        return true
    end
    
    return false
end

-- Handle specialization change
function Arms:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    sweepingStrikesActive = false
    
    return true
end

-- Return the module for loading
return Arms