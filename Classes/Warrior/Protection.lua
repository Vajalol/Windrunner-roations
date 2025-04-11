------------------------------------------
-- WindrunnerRotations - Protection Warrior Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Protection = {}
addon.Classes.Warrior.Protection = Protection

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
local currentAoETargets = 0
local defensivesNeeded = false
local ignoreRageRequirements = false

-- Constants
local PROT_SPEC_ID = 73
local RAGE_THRESHOLD_HIGH = 70
local RAGE_THRESHOLD_LOW = 30
local DEFAULT_AOE_THRESHOLD = 3
local REVENGE_PROC_BUFF = 5302 -- Buff ID for Revenge proc

-- Initialize the Protection module
function Protection:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Protection Warrior module initialized")
    
    return true
end

-- Register spell IDs
function Protection:RegisterSpells()
    -- Active abilities
    spells.DEVASTATE = 20243
    spells.SHIELD_SLAM = 23922
    spells.IGNORE_PAIN = 190456
    spells.SHIELD_BLOCK = 2565
    spells.THUNDER_CLAP = 6343
    spells.REVENGE = 6572
    spells.DEVASTATOR = 236279 -- Passive that replaces Devastate
    spells.LAST_STAND = 12975
    spells.DEMORALIZING_SHOUT = 1160
    spells.SHOCKWAVE = 46968
    spells.DRAGON_ROAR = 118000
    spells.AVATAR = 107574
    spells.SPELL_REFLECTION = 23920
    spells.SHIELD_WALL = 871
    spells.RAVAGER = 228920
    spells.IMPENDING_VICTORY = 202168
    
    -- Defensive/reactive abilities
    spells.INTERVENE = 3411
    spells.CHALLENGING_SHOUT = 1161
    spells.BERSERKER_RAGE = 18499
    
    -- Passives
    spells.SHIELD_BLOCK_BUFF = 132404
    spells.REVENGE_PROC = REVENGE_PROC_BUFF
    spells.AVATAR_BUFF = 107574
    spells.DEMORALIZING_SHOUT_DEBUFF = 1160
    spells.THUNDEROUS_ROAR_DEBUFF = 384318
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SHIELD_BLOCK = spells.SHIELD_BLOCK_BUFF
    buffs.REVENGE_PROC = spells.REVENGE_PROC
    buffs.LAST_STAND = spells.LAST_STAND
    buffs.AVATAR = spells.AVATAR_BUFF
    
    debuffs.DEMORALIZING_SHOUT = spells.DEMORALIZING_SHOUT_DEBUFF
    debuffs.THUNDEROUS_ROAR = spells.THUNDEROUS_ROAR_DEBUFF
    
    return true
end

-- Register variables to track
function Protection:RegisterVariables()
    -- Talent tracking
    talents.hasDevastator = false
    talents.hasImpendingVictory = false
    talents.hasDragonRoar = false
    talents.hasRavager = false
    talents.hasStormBolt = false
    talents.hasThunderousRoar = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Protection:RegisterSettings()
    ConfigRegistry:RegisterSettings("ProtectionWarrior", {
        rotationSettings = {
            mitigation = {
                displayName = "Mitigation Focus",
                description = "Prioritize defensive abilities over damage",
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
            ignorePayThreshold = {
                displayName = "Min Rage for Ignore Pain",
                description = "Minimum rage to cast Ignore Pain",
                type = "slider",
                min = 0,
                max = 80,
                default = 40
            },
            shieldBlockOverIgnorePain = {
                displayName = "Prioritize Shield Block",
                description = "Always prioritize Shield Block over Ignore Pain",
                type = "toggle",
                default = true
            },
            useRevengeProc = {
                displayName = "Only use Revenge with Proc",
                description = "Only use Revenge when it's free from proc",
                type = "toggle",
                default = false
            }
        },
        
        cooldownSettings = {
            useAvatar = {
                displayName = "Use Avatar",
                description = "Automatically use Avatar for damage and threat",
                type = "toggle",
                default = true
            },
            useDemoShout = {
                displayName = "Use Demoralizing Shout",
                description = "Automatically use Demoralizing Shout for damage reduction",
                type = "toggle",
                default = true
            },
            useLastStand = {
                displayName = "Use Last Stand",
                description = "Automatically use Last Stand as a defensive cooldown",
                type = "toggle",
                default = true
            },
            lastStandThreshold = {
                displayName = "Last Stand Health Threshold",
                description = "Health percentage to use Last Stand",
                type = "slider",
                min = 10,
                max = 50,
                default = 30
            },
            useShieldWall = {
                displayName = "Use Shield Wall",
                description = "Automatically use Shield Wall as emergency defensive",
                type = "toggle",
                default = true
            },
            shieldWallThreshold = {
                displayName = "Shield Wall Health Threshold",
                description = "Health percentage to use Shield Wall",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            }
        },
        
        advancedSettings = {
            maintainShieldBlock = {
                displayName = "Maintain Shield Block",
                description = "Try to always keep Shield Block active",
                type = "toggle",
                default = true
            },
            poolRageForDefensives = {
                displayName = "Pool Rage for Defensives",
                description = "Save rage for defensive abilities when health is low",
                type = "slider",
                min = 0,
                max = 100,
                default = 40 -- Health threshold to start pooling rage
            },
            useTClap = {
                displayName = "Use Thunder Clap on CD",
                description = "Use Thunder Clap on cooldown for single target",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Shockwave controls
            shockwave = AAC.RegisterAbility(spells.SHOCKWAVE, {
                enabled = true,
                minEnemies = 3,
                useToCCPriority = true,
                enemyHealthThreshold = 30
            }),
            
            -- Ravager controls
            ravager = AAC.RegisterAbility(spells.RAVAGER, {
                enabled = true,
                minEnemies = 2,
                placementMode = "BestClump"
            }),
            
            -- Dragon Roar controls
            dragonRoar = AAC.RegisterAbility(spells.DRAGON_ROAR, {
                enabled = true,
                minEnemies = 2
            })
        }
    })
    
    return true
end

-- Register for events 
function Protection:RegisterEvents()
    -- Register to track damage taken for defensive logic
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for health update events
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateDefensiveState() 
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
function Protection:UpdateTalentInfo()
    -- Check for important talents
    talents.hasDevastator = API.HasTalent(spells.DEVASTATOR)
    talents.hasImpendingVictory = API.HasTalent(spells.IMPENDING_VICTORY)
    talents.hasDragonRoar = API.HasTalent(spells.DRAGON_ROAR)
    talents.hasRavager = API.HasTalent(spells.RAVAGER)
    talents.hasStormBolt = API.HasTalent(Warrior.spells.STORM_BOLT)
    talents.hasThunderousRoar = API.HasTalent(Warrior.spells.THUNDEROUS_ROAR)
    
    API.PrintDebug("Protection Warrior talents updated")
    
    return true
end

-- Update target data
function Protection:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                thunderClap = false,
                thunderClapExpiration = 0,
                demoralizingShout = false,
                demoralizingShoutExpiration = 0,
                thunderousRoar = false,
                thunderousRoarExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Protection Warrior AoE range
    
    return true
end

-- Update defensive state based on health and incoming damage
function Protection:UpdateDefensiveState()
    local healthPercent = API.GetPlayerHealthPercent()
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    
    -- Set defensive state based on health percentage
    if healthPercent <= settings.advancedSettings.poolRageForDefensives then
        defensivesNeeded = true
    else
        defensivesNeeded = false
    end
    
    return true
end

-- Handle combat log events
function Protection:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track debuffs we apply to targets
    if sourceGUID == API.GetPlayerGUID() then
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Initialize target data if needed
            if destGUID ~= "" and not self.targetData[destGUID] then
                self:UpdateTargetData()
            end
            
            -- Track Thunder Clap debuff
            if spellID == spells.THUNDER_CLAP and self.targetData[destGUID] then
                self.targetData[destGUID].thunderClap = true
                self.targetData[destGUID].thunderClapExpiration = select(6, API.GetDebuffInfo(destGUID, spells.THUNDER_CLAP))
            end
            
            -- Track Demoralizing Shout debuff
            if spellID == spells.DEMORALIZING_SHOUT and self.targetData[destGUID] then
                self.targetData[destGUID].demoralizingShout = true
                self.targetData[destGUID].demoralizingShoutExpiration = select(6, API.GetDebuffInfo(destGUID, spells.DEMORALIZING_SHOUT))
            end
            
            -- Track Thunderous Roar debuff if talented
            if talents.hasThunderousRoar and spellID == Warrior.spells.THUNDEROUS_ROAR and self.targetData[destGUID] then
                self.targetData[destGUID].thunderousRoar = true
                self.targetData[destGUID].thunderousRoarExpiration = select(6, API.GetDebuffInfo(destGUID, Warrior.spells.THUNDEROUS_ROAR))
            end
        end
        
        -- Track debuff removals
        if eventType == "SPELL_AURA_REMOVED" then
            if destGUID ~= "" and self.targetData[destGUID] then
                -- Track Thunder Clap debuff removal
                if spellID == spells.THUNDER_CLAP then
                    self.targetData[destGUID].thunderClap = false
                end
                
                -- Track Demoralizing Shout debuff removal
                if spellID == spells.DEMORALIZING_SHOUT then
                    self.targetData[destGUID].demoralizingShout = false
                end
                
                -- Track Thunderous Roar debuff removal
                if talents.hasThunderousRoar and spellID == Warrior.spells.THUNDEROUS_ROAR then
                    self.targetData[destGUID].thunderousRoar = false
                end
            end
        end
    end
    
    -- Analyze incoming damage to better prioritize defensives
    if destGUID == API.GetPlayerGUID() and (eventType == "SPELL_DAMAGE" or eventType == "SWING_DAMAGE") then
        local damage = select(15, CombatLogGetCurrentEventInfo())
        local maxHealth = UnitHealthMax("player")
        
        -- If single hit takes more than 20% of max health, consider it a spike
        if damage and maxHealth and (damage / maxHealth) > 0.20 then
            defensivesNeeded = true
            ignoreRageRequirements = true -- Ignore rage requirements for defensives after a big hit
            
            -- Schedule reset of ignoreRageRequirements
            C_Timer.After(2, function()
                ignoreRageRequirements = false
            end)
        end
    end
    
    return true
end

-- Main rotation function
function Protection:RunRotation()
    -- Check if we should be running Protection Warrior logic
    if API.GetActiveSpecID() ~= PROT_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    
    -- Update variables
    self:UpdateTargetData()
    self:UpdateDefensiveState()
    local targetInRange = API.IsTargetInRange(5) -- Melee range check
    
    -- Handle next cast override if set
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Check if we need to use defensive abilities first
    if self:HandleDefensiveCooldowns() then
        return true
    end
    
    -- Manage mitigation abilities (Shield Block, Ignore Pain)
    if self:HandleActiveMitigation() then
        return true
    end
    
    -- Check for AoE or Single Target based on settings and enemy count
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation()
    else
        return self:HandleSingleTargetRotation()
    end
end

-- Handle defensive cooldown abilities
function Protection:HandleDefensiveCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    local healthPercent = API.GetPlayerHealthPercent()
    
    -- Use Shield Wall (major defensive cooldown)
    if settings.cooldownSettings.useShieldWall and 
       healthPercent <= settings.cooldownSettings.shieldWallThreshold and
       API.CanCast(spells.SHIELD_WALL) then
        API.CastSpell(spells.SHIELD_WALL)
        return true
    end
    
    -- Use Last Stand
    if settings.cooldownSettings.useLastStand and 
       healthPercent <= settings.cooldownSettings.lastStandThreshold and
       API.CanCast(spells.LAST_STAND) then
        API.CastSpell(spells.LAST_STAND)
        return true
    end
    
    -- Use Demoralizing Shout for damage reduction
    if settings.cooldownSettings.useDemoShout and 
       API.CanCast(spells.DEMORALIZING_SHOUT) and
       defensivesNeeded then
        API.CastSpell(spells.DEMORALIZING_SHOUT)
        return true
    end
    
    -- Use Avatar (damage/threat increase)
    if settings.cooldownSettings.useAvatar and 
       API.CanCast(spells.AVATAR) and
       ((currentAoETargets >= settings.rotationSettings.aoeThreshold) or -- high number of targets
        (not API.GetInCombatTime() or API.GetInCombatTime() < 5)) then -- beginning of combat
        API.CastSpell(spells.AVATAR)
        return true
    end
    
    return false
end

-- Handle active mitigation
function Protection:HandleActiveMitigation()
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    local playerRage = API.GetPlayerPower()
    
    -- Use Shield Block for physical damage mitigation
    if settings.advancedSettings.maintainShieldBlock and 
       not API.PlayerHasBuff(buffs.SHIELD_BLOCK) and
       API.CanCast(spells.SHIELD_BLOCK) and
       playerRage >= 30 then -- Shield Block costs 30 rage
        API.CastSpell(spells.SHIELD_BLOCK)
        return true
    end
    
    -- Use Ignore Pain for general damage mitigation
    if not settings.rotationSettings.shieldBlockOverIgnorePain or API.PlayerHasBuff(buffs.SHIELD_BLOCK) then
        -- Either Shield Block is prioritized and active, or we don't prioritize Shield Block
        local ignoreRagePainThreshold = settings.rotationSettings.ignorePayThreshold
        
        -- If we're in a defensive state, reduce the threshold
        if defensivesNeeded or ignoreRageRequirements then
            ignoreRagePainThreshold = math.max(ignoreRagePainThreshold - 20, 10) -- At least 10 rage required
        end
        
        if API.CanCast(spells.IGNORE_PAIN) and playerRage >= ignoreRagePainThreshold then
            API.CastSpell(spells.IGNORE_PAIN)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Protection:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    
    -- Use Thunderous Roar if talented
    if talents.hasThunderousRoar and API.CanCast(Warrior.spells.THUNDEROUS_ROAR) then
        API.CastSpell(Warrior.spells.THUNDEROUS_ROAR)
        return true
    end
    
    -- Use Ravager if talented
    if talents.hasRavager and 
       settings.abilityControls.ravager.enabled and
       currentAoETargets >= settings.abilityControls.ravager.minEnemies and
       API.CanCast(spells.RAVAGER) then
        
        if settings.abilityControls.ravager.placementMode == "BestClump" then
            -- Cast at best enemy clump
            API.CastSpellAtBestClump(spells.RAVAGER, 8)
        else
            -- Cast at cursor
            API.CastSpellAtCursor(spells.RAVAGER)
        end
        return true
    end
    
    -- Use Dragon Roar if talented
    if talents.hasDragonRoar and 
       settings.abilityControls.dragonRoar.enabled and
       currentAoETargets >= settings.abilityControls.dragonRoar.minEnemies and
       API.CanCast(spells.DRAGON_ROAR) then
        API.CastSpell(spells.DRAGON_ROAR)
        return true
    end
    
    -- Use Shockwave for AoE stun
    if settings.abilityControls.shockwave.enabled and
       currentAoETargets >= settings.abilityControls.shockwave.minEnemies and
       API.CanCast(spells.SHOCKWAVE) then
        API.CastSpell(spells.SHOCKWAVE)
        return true
    end
    
    -- Use Thunder Clap as primary AoE ability
    if API.CanCast(spells.THUNDER_CLAP) then
        API.CastSpell(spells.THUNDER_CLAP)
        return true
    end
    
    -- Use Revenge for AoE damage
    if API.CanCast(spells.REVENGE) then
        -- Check if we should only use Revenge when it procs
        if not settings.rotationSettings.useRevengeProc or API.PlayerHasBuff(buffs.REVENGE_PROC) then
            API.CastSpell(spells.REVENGE)
            return true
        end
    end
    
    -- Fallback to Shield Slam for rage generation
    if API.CanCast(spells.SHIELD_SLAM) then
        API.CastSpell(spells.SHIELD_SLAM)
        return true
    end
    
    -- Use Devastate/Devastator filler
    if not talents.hasDevastator and API.CanCast(spells.DEVASTATE) then
        API.CastSpell(spells.DEVASTATE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Protection:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("ProtectionWarrior")
    
    -- Check if target is in melee range
    if not API.IsTargetInRange(5) then
        return false
    end
    
    -- Prioritize Shield Slam for rage generation and damage
    if API.CanCast(spells.SHIELD_SLAM) then
        API.CastSpell(spells.SHIELD_SLAM)
        return true
    end
    
    -- Use Revenge when it procs (free and more damage)
    if API.CanCast(spells.REVENGE) and API.PlayerHasBuff(buffs.REVENGE_PROC) then
        API.CastSpell(spells.REVENGE)
        return true
    end
    
    -- Use Thunder Clap
    if settings.advancedSettings.useTClap and API.CanCast(spells.THUNDER_CLAP) then
        API.CastSpell(spells.THUNDER_CLAP)
        return true
    end
    
    -- Use Revenge if we have enough rage and not saving for defensives
    if API.CanCast(spells.REVENGE) and 
       (not settings.rotationSettings.useRevengeProc) and
       (not defensivesNeeded) then
        API.CastSpell(spells.REVENGE)
        return true
    end
    
    -- Use Devastate as filler if we don't have Devastator talent
    if not talents.hasDevastator and API.CanCast(spells.DEVASTATE) then
        API.CastSpell(spells.DEVASTATE)
        return true
    end
    
    -- If we have Devastator talent, it will automatically apply so we'll just auto-attack
    
    return false
end

-- Handle specialization change
function Protection:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    defensivesNeeded = false
    ignoreRageRequirements = false
    
    return true
end

-- Return the module for loading
return Protection