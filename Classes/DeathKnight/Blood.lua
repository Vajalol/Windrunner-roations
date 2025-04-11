------------------------------------------
-- WindrunnerRotations - Blood Death Knight Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Blood = {}
addon.Classes.DeathKnight.Blood = Blood

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local DeathKnight = addon.Classes.DeathKnight

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local emergencyMitigationNeeded = false
local currentAoETargets = 0
local boneShieldStacks = 0
local runicPower = 0
local maxRunicPower = 100
local activeRunes = 0
local bloodPlague = false
local deathAndDecayActive = false
local vampiricBloodActive = false
local dancingRuneWeaponActive = false
local redThirstActive = false
local tombstoneActive = false

-- Constants
local BLOOD_SPEC_ID = 250
local RUNIC_POWER_THRESHOLD = 80
local BONE_SHIELD_MIN_STACKS = 5
local DEFAULT_AOE_THRESHOLD = 3
local DEATHSTRIKE_MINIMUM_HEALTH = 70
local DEATHSTRIKE_EMERGENCY_HEALTH = 35

-- Initialize the Blood module
function Blood:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Blood Death Knight module initialized")
    
    return true
end

-- Register spell IDs
function Blood:RegisterSpells()
    -- Blood Abilities
    spells.BLOOD_BOIL = 50842
    spells.MARROWREND = 195182
    spells.HEART_STRIKE = 206930
    spells.DEATH_STRIKE = 49998
    spells.VAMPIRIC_BLOOD = 55233
    spells.DANCING_RUNE_WEAPON = 49028
    spells.TOMBSTONE = 219809
    spells.BONESTORM = 194844
    spells.CONSUMPTION = 274156
    spells.BLOODDRINKER = 206931
    spells.BLOOD_TAP = 221699
    spells.GOREFIENDS_GRASP = 108199
    spells.MARK_OF_BLOOD = 206940
    spells.RUNE_TAP = 194679
    spells.BLOOD_PLAGUE = 55078
    spells.RED_THIRST = 205723
    spells.RELISH_IN_BLOOD = 317610
    spells.HEMOSTASIS = 273946
    spells.OSSUARY = 219786
    spells.VORACIOUS = 273953
    
    -- Buffs/Procs
    spells.BONE_SHIELD = 195181
    spells.CRIMSON_SCOURGE = 81141
    spells.HEMOSTASIS_BUFF = 273947
    spells.OSSUARY_BUFF = 219788
    spells.VORACIOUS_BUFF = 274009
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.BONE_SHIELD = spells.BONE_SHIELD
    buffs.CRIMSON_SCOURGE = spells.CRIMSON_SCOURGE
    buffs.DANCING_RUNE_WEAPON = spells.DANCING_RUNE_WEAPON
    buffs.VAMPIRIC_BLOOD = spells.VAMPIRIC_BLOOD
    buffs.TOMBSTONE = spells.TOMBSTONE
    buffs.HEMOSTASIS = spells.HEMOSTASIS_BUFF
    buffs.OSSUARY = spells.OSSUARY_BUFF
    buffs.VORACIOUS = spells.VORACIOUS_BUFF
    
    debuffs.BLOOD_PLAGUE = spells.BLOOD_PLAGUE
    
    return true
end

-- Register variables to track
function Blood:RegisterVariables()
    -- Talent tracking
    talents.hasTombstone = false
    talents.hasBlooddrinker = false
    talents.hasBonestorm = false
    talents.hasConsumption = false
    talents.hasRedThirst = false
    talents.hasRelishInBlood = false
    talents.hasHemostasis = false
    talents.hasVoracious = false
    talents.hasOssuary = false
    talents.hasRuneTap = false
    talents.hasMarkOfBlood = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Blood:RegisterSettings()
    ConfigRegistry:RegisterSettings("BloodDeathKnight", {
        rotationSettings = {
            deathStrikePriority = {
                displayName = "Death Strike Usage",
                description = "When to use Death Strike during rotation",
                type = "dropdown",
                options = {"Optimal", "Defensive", "Offensive"},
                default = "Optimal"
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
            maintainBoneShield = {
                displayName = "Maintain Bone Shield",
                description = "Prioritize keeping Bone Shield active",
                type = "toggle",
                default = true
            },
            boneShieldMinimum = {
                displayName = "Bone Shield Minimum",
                description = "Minimum stacks of Bone Shield to maintain",
                type = "slider",
                min = 1,
                max = 10,
                default = BONE_SHIELD_MIN_STACKS
            },
            poolRunicPower = {
                displayName = "Pool Runic Power",
                description = "Save Runic Power for Death Strike when health is low",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useVampiricBlood = {
                displayName = "Use Vampiric Blood",
                description = "Automatically use Vampiric Blood when health is low",
                type = "toggle",
                default = true
            },
            vampiricBloodThreshold = {
                displayName = "Vampiric Blood Health Threshold",
                description = "Health percentage to use Vampiric Blood",
                type = "slider",
                min = 1,
                max = 100,
                default = 45
            },
            useDancingRuneWeapon = {
                displayName = "Use Dancing Rune Weapon",
                description = "Automatically use Dancing Rune Weapon",
                type = "toggle",
                default = true
            },
            dwrThreshold = {
                displayName = "Dancing Rune Weapon Usage",
                description = "When to use Dancing Rune Weapon",
                type = "dropdown",
                options = {"On Cooldown", "Emergency Only", "Boss Only"},
                default = "On Cooldown"
            },
            useBonestorm = {
                displayName = "Use Bonestorm",
                description = "Use Bonestorm for AoE damage when talented",
                type = "toggle",
                default = true
            },
            bonestormMinRP = {
                displayName = "Minimum RP for Bonestorm",
                description = "Minimum Runic Power to cast Bonestorm",
                type = "slider", 
                min = 50,
                max = 100,
                default = 60
            },
            useTombstone = {
                displayName = "Use Tombstone",
                description = "Use Tombstone as an emergency defensive",
                type = "toggle",
                default = true
            },
            tombstoneMinStacks = {
                displayName = "Minimum Bone Shield for Tombstone",
                description = "Minimum Bone Shield stacks to consume for Tombstone",
                type = "slider",
                min = 5,
                max = 10,
                default = 7
            }
        },
        
        advancedSettings = {
            mrrUsage = {
                displayName = "Marrowrend Usage",
                description = "When to cast Marrowrend to refresh Bone Shield",
                type = "dropdown", 
                options = {"Efficient", "Safe", "Paranoid"},
                default = "Efficient"
            },
            deathAndDecayUsage = {
                displayName = "Death and Decay Usage",
                description = "When to cast Death and Decay",
                type = "dropdown",
                options = {"AoE Only", "On Cooldown", "With Crimson Scourge Only"},
                default = "With Crimson Scourge Only"
            },
            useRuneTap = {
                displayName = "Use Rune Tap",
                description = "Use Rune Tap as an active mitigation",
                type = "toggle",
                default = true
            },
            runeTapThreshold = {
                displayName = "Rune Tap Health Threshold",
                description = "Health percentage to use Rune Tap",
                type = "slider",
                min = 1,
                max = 100,
                default = 50
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Gorefiend's Grasp controls
            gorefiend = AAC.RegisterAbility(spells.GOREFIENDS_GRASP, {
                enabled = true,
                minEnemies = 3,
                useOnCooldown = false
            }),
            
            -- Consumption controls
            consumption = AAC.RegisterAbility(spells.CONSUMPTION, {
                enabled = true,
                minEnemies = 1,
                healthThreshold = 85
            }),
            
            -- Mark of Blood controls
            markOfBlood = AAC.RegisterAbility(spells.MARK_OF_BLOOD, {
                enabled = true,
                healthThreshold = 70,
                onlyOnBosses = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Blood:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for rune/runic power updates
    API.RegisterEvent("RUNE_POWER_UPDATE", function() 
        self:UpdateRuneTracking() 
    end)
    
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "RUNIC_POWER" then
            self:UpdateRunicPower()
        end
    end)
    
    -- Register for health updates (for emergency detection)
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:CheckHealthState()
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
function Blood:UpdateTalentInfo()
    -- Check for important talents
    talents.hasTombstone = API.HasTalent(spells.TOMBSTONE)
    talents.hasBlooddrinker = API.HasTalent(spells.BLOODDRINKER)
    talents.hasBonestorm = API.HasTalent(spells.BONESTORM)
    talents.hasConsumption = API.HasTalent(spells.CONSUMPTION)
    talents.hasRedThirst = API.HasTalent(spells.RED_THIRST)
    talents.hasRelishInBlood = API.HasTalent(spells.RELISH_IN_BLOOD)
    talents.hasHemostasis = API.HasTalent(spells.HEMOSTASIS)
    talents.hasVoracious = API.HasTalent(spells.VORACIOUS)
    talents.hasOssuary = API.HasTalent(spells.OSSUARY)
    talents.hasRuneTap = API.HasTalent(spells.RUNE_TAP)
    talents.hasMarkOfBlood = API.HasTalent(spells.MARK_OF_BLOOD)
    
    API.PrintDebug("Blood Death Knight talents updated")
    
    return true
end

-- Update rune tracking
function Blood:UpdateRuneTracking()
    activeRunes = API.GetNumberOfActiveRunes()
    return true
end

-- Update runic power tracking
function Blood:UpdateRunicPower()
    runicPower = API.GetPlayerPower()
    
    -- Check if we have Ossuary buff (reduced Death Strike cost)
    if talents.hasOssuary and boneShieldStacks >= 5 then
        -- Reduce Death Strike cost in calculations
        maxRunicPower = maxRunicPower - 5
    end
    
    return true
end

-- Check health state for emergency detection
function Blood:CheckHealthState()
    local healthPct = API.GetPlayerHealthPercent()
    
    -- Check for emergency state
    if healthPct <= DEATHSTRIKE_EMERGENCY_HEALTH then
        emergencyMitigationNeeded = true
    else
        emergencyMitigationNeeded = false
    end
    
    return true
end

-- Update target data
function Blood:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                bloodPlague = false,
                bloodPlagueExpiration = 0,
                markOfBlood = false,
                markOfBloodExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Blood AoE radius
    
    -- Check if target has Blood Plague
    if targetGUID and self.targetData[targetGUID] then
        bloodPlague = self.targetData[targetGUID].bloodPlague
    else
        bloodPlague = false
    end
    
    return true
end

-- Handle combat log events
function Blood:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff/debuff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track Bone Shield buff and stacks
        if spellID == spells.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
            boneShieldStacks = select(4, UnitBuff("player", GetSpellInfo(spells.BONE_SHIELD)))
            API.PrintDebug("Bone Shield applied/refreshed: " .. tostring(boneShieldStacks) .. " stacks")
        end
        
        -- Track Vampiric Blood
        if spellID == spells.VAMPIRIC_BLOOD and destGUID == API.GetPlayerGUID() then
            vampiricBloodActive = true
        end
        
        -- Track Dancing Rune Weapon
        if spellID == spells.DANCING_RUNE_WEAPON and destGUID == API.GetPlayerGUID() then
            dancingRuneWeaponActive = true
        end
        
        -- Track Tombstone
        if spellID == spells.TOMBSTONE and destGUID == API.GetPlayerGUID() then
            tombstoneActive = true
        end
        
        -- Track Blood Plague on targets
        if spellID == spells.BLOOD_PLAGUE and self.targetData[destGUID] then
            self.targetData[destGUID].bloodPlague = true
            self.targetData[destGUID].bloodPlagueExpiration = select(6, API.GetDebuffInfo(destGUID, spells.BLOOD_PLAGUE))
            
            -- Update bloodPlague variable if this is our current target
            if destGUID == API.GetTargetGUID() then
                bloodPlague = true
            end
        end
        
        -- Track Mark of Blood on targets
        if spellID == spells.MARK_OF_BLOOD and self.targetData[destGUID] then
            self.targetData[destGUID].markOfBlood = true
            self.targetData[destGUID].markOfBloodExpiration = select(6, API.GetDebuffInfo(destGUID, spells.MARK_OF_BLOOD))
        end
    end
    
    -- Track buff/debuff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track Bone Shield removal
        if spellID == spells.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
            boneShieldStacks = 0
            API.PrintDebug("Bone Shield removed")
        end
        
        -- Track Vampiric Blood removal
        if spellID == spells.VAMPIRIC_BLOOD and destGUID == API.GetPlayerGUID() then
            vampiricBloodActive = false
        end
        
        -- Track Dancing Rune Weapon removal
        if spellID == spells.DANCING_RUNE_WEAPON and destGUID == API.GetPlayerGUID() then
            dancingRuneWeaponActive = false
        end
        
        -- Track Tombstone removal
        if spellID == spells.TOMBSTONE and destGUID == API.GetPlayerGUID() then
            tombstoneActive = false
        end
        
        -- Track Blood Plague removal from targets
        if spellID == spells.BLOOD_PLAGUE and self.targetData[destGUID] then
            self.targetData[destGUID].bloodPlague = false
            
            -- Update bloodPlague variable if this is our current target
            if destGUID == API.GetTargetGUID() then
                bloodPlague = false
            end
        end
        
        -- Track Mark of Blood removal from targets
        if spellID == spells.MARK_OF_BLOOD and self.targetData[destGUID] then
            self.targetData[destGUID].markOfBlood = false
        end
    end
    
    -- Track Bone Shield stack changes
    if eventType == "SPELL_AURA_APPLIED_DOSE" then
        if spellID == spells.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
            boneShieldStacks = select(4, UnitBuff("player", GetSpellInfo(spells.BONE_SHIELD)))
            API.PrintDebug("Bone Shield stack added: " .. tostring(boneShieldStacks) .. " stacks")
        end
    end
    
    if eventType == "SPELL_AURA_REMOVED_DOSE" then
        if spellID == spells.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
            boneShieldStacks = select(4, UnitBuff("player", GetSpellInfo(spells.BONE_SHIELD))) or 0
            API.PrintDebug("Bone Shield stack removed: " .. tostring(boneShieldStacks) .. " stacks remaining")
        end
    end
    
    -- Track Death and Decay cast
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == DeathKnight.spells.DEATH_AND_DECAY then
            deathAndDecayActive = true
            C_Timer.After(10, function() -- DnD lasts 10 seconds
                deathAndDecayActive = false
            end)
        end
    end
    
    return true
end

-- Main rotation function
function Blood:RunRotation()
    -- Check if we should be running Blood Death Knight logic
    if API.GetActiveSpecID() ~= BLOOD_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BloodDeathKnight")
    
    -- Update variables
    self:UpdateRunicPower()
    self:UpdateRuneTracking()
    self:CheckHealthState()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle emergency abilities first
    if emergencyMitigationNeeded and self:HandleEmergencyDefensives() then
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensiveCooldowns() then
        return true
    end
    
    -- Handle standard rotation
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation()
    else
        return self:HandleSingleTargetRotation()
    end
end

-- Handle emergency defensive abilities
function Blood:HandleEmergencyDefensives()
    local settings = ConfigRegistry:GetSettings("BloodDeathKnight")
    local healthPct = API.GetPlayerHealthPercent()
    
    -- Emergency Death Strike
    if runicPower >= 45 and API.CanCast(spells.DEATH_STRIKE) then
        API.CastSpell(spells.DEATH_STRIKE)
        return true
    end
    
    -- Use Vampiric Blood if not active
    if settings.cooldownSettings.useVampiricBlood and 
       not vampiricBloodActive and 
       API.CanCast(spells.VAMPIRIC_BLOOD) then
        API.CastSpell(spells.VAMPIRIC_BLOOD)
        return true
    end
    
    -- Use Tombstone if available and configured
    if talents.hasTombstone and 
       settings.cooldownSettings.useTombstone and 
       boneShieldStacks >= settings.cooldownSettings.tombstoneMinStacks and
       API.CanCast(spells.TOMBSTONE) then
        API.CastSpell(spells.TOMBSTONE)
        return true
    end
    
    -- Use Dancing Rune Weapon as emergency
    if settings.cooldownSettings.useDancingRuneWeapon and 
       (settings.cooldownSettings.dwrThreshold == "Emergency Only" or 
        settings.cooldownSettings.dwrThreshold == "On Cooldown") and
       API.CanCast(spells.DANCING_RUNE_WEAPON) then
        API.CastSpell(spells.DANCING_RUNE_WEAPON)
        return true
    end
    
    -- Use Rune Tap for immediate mitigation
    if talents.hasRuneTap and 
       settings.advancedSettings.useRuneTap and
       activeRunes >= 1 and
       API.CanCast(spells.RUNE_TAP) then
        API.CastSpell(spells.RUNE_TAP)
        return true
    end
    
    return false
end

-- Handle defensive cooldowns
function Blood:HandleDefensiveCooldowns()
    local settings = ConfigRegistry:GetSettings("BloodDeathKnight")
    local healthPct = API.GetPlayerHealthPercent()
    
    -- Use Vampiric Blood
    if settings.cooldownSettings.useVampiricBlood and 
       healthPct <= settings.cooldownSettings.vampiricBloodThreshold and
       not vampiricBloodActive and
       API.CanCast(spells.VAMPIRIC_BLOOD) then
        API.CastSpell(spells.VAMPIRIC_BLOOD)
        return true
    end
    
    -- Use Dancing Rune Weapon
    if settings.cooldownSettings.useDancingRuneWeapon and API.CanCast(spells.DANCING_RUNE_WEAPON) then
        local useDRW = false
        
        if settings.cooldownSettings.dwrThreshold == "On Cooldown" then
            useDRW = true
        elseif settings.cooldownSettings.dwrThreshold == "Emergency Only" and healthPct <= 50 then
            useDRW = true
        elseif settings.cooldownSettings.dwrThreshold == "Boss Only" and API.IsTargetBoss() then
            useDRW = true
        end
        
        if useDRW then
            API.CastSpell(spells.DANCING_RUNE_WEAPON)
            return true
        end
    end
    
    -- Use Tombstone for planned mitigation
    if talents.hasTombstone and 
       settings.cooldownSettings.useTombstone and
       healthPct <= 75 and
       boneShieldStacks >= settings.cooldownSettings.tombstoneMinStacks and
       API.CanCast(spells.TOMBSTONE) then
        API.CastSpell(spells.TOMBSTONE)
        return true
    end
    
    -- Use Mark of Blood on boss targets
    if talents.hasMarkOfBlood and 
       settings.abilityControls.markOfBlood.enabled and
       healthPct <= settings.abilityControls.markOfBlood.healthThreshold and
       API.CanCast(spells.MARK_OF_BLOOD) then
        
        -- Check if we should only use on bosses
        if not settings.abilityControls.markOfBlood.onlyOnBosses or API.IsTargetBoss() then
            local targetGUID = API.GetTargetGUID()
            
            -- Check if target already has Mark of Blood
            if targetGUID and self.targetData[targetGUID] and not self.targetData[targetGUID].markOfBlood then
                API.CastSpell(spells.MARK_OF_BLOOD)
                return true
            end
        end
    end
    
    -- Use Rune Tap for planned mitigation
    if talents.hasRuneTap and 
       settings.advancedSettings.useRuneTap and
       healthPct <= settings.advancedSettings.runeTapThreshold and
       activeRunes >= 1 and
       API.CanCast(spells.RUNE_TAP) then
        API.CastSpell(spells.RUNE_TAP)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Blood:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("BloodDeathKnight")
    
    -- Maintain Bone Shield
    if settings.rotationSettings.maintainBoneShield and 
       boneShieldStacks < settings.rotationSettings.boneShieldMinimum and
       activeRunes >= 2 and
       API.CanCast(spells.MARROWREND) then
        API.CastSpell(spells.MARROWREND)
        return true
    end
    
    -- Apply Blood Plague via Blood Boil
    if not bloodPlague and API.CanCast(spells.BLOOD_BOIL) then
        API.CastSpell(spells.BLOOD_BOIL)
        return true
    end
    
    -- Use Bonestorm if talented and enough RP
    if talents.hasBonestorm and
       settings.cooldownSettings.useBonestorm and
       runicPower >= settings.cooldownSettings.bonestormMinRP and
       API.CanCast(spells.BONESTORM) then
        API.CastSpell(spells.BONESTORM)
        return true
    end
    
    -- Use Consumption if talented
    if talents.hasConsumption and
       settings.abilityControls.consumption.enabled and
       currentAoETargets >= settings.abilityControls.consumption.minEnemies and
       API.GetPlayerHealthPercent() <= settings.abilityControls.consumption.healthThreshold and
       API.CanCast(spells.CONSUMPTION) then
        API.CastSpell(spells.CONSUMPTION)
        return true
    end
    
    -- Use Gorefiend's Grasp
    if settings.abilityControls.gorefiend.enabled and
       currentAoETargets >= settings.abilityControls.gorefiend.minEnemies and
       API.CanCast(spells.GOREFIENDS_GRASP) then
        
        if settings.abilityControls.gorefiend.useOnCooldown or 
           (not deathAndDecayActive and API.PlayerHasBuff(buffs.CRIMSON_SCOURGE)) then
            API.CastSpell(spells.GOREFIENDS_GRASP)
            return true
        end
    end
    
    -- Handle Death and Decay
    local shouldUseDnD = false
    
    if settings.advancedSettings.deathAndDecayUsage == "AoE Only" then
        shouldUseDnD = true
    elseif settings.advancedSettings.deathAndDecayUsage == "On Cooldown" then
        shouldUseDnD = true
    elseif settings.advancedSettings.deathAndDecayUsage == "With Crimson Scourge Only" and 
           API.PlayerHasBuff(buffs.CRIMSON_SCOURGE) then
        shouldUseDnD = true
    end
    
    if shouldUseDnD and 
       not deathAndDecayActive and 
       API.CanCast(DeathKnight.spells.DEATH_AND_DECAY) then
        API.CastSpellAtCursor(DeathKnight.spells.DEATH_AND_DECAY)
        return true
    end
    
    -- Use Death Strike based on settings and health
    local healthPct = API.GetPlayerHealthPercent()
    local deathStrikeThreshold = DEATHSTRIKE_MINIMUM_HEALTH
    
    if settings.rotationSettings.deathStrikePriority == "Defensive" then
        deathStrikeThreshold = deathStrikeThreshold + 10
    elseif settings.rotationSettings.deathStrikePriority == "Offensive" then
        deathStrikeThreshold = deathStrikeThreshold - 10
    end
    
    if (healthPct <= deathStrikeThreshold or runicPower >= RUNIC_POWER_THRESHOLD) and
       API.CanCast(spells.DEATH_STRIKE) then
        API.CastSpell(spells.DEATH_STRIKE)
        return true
    end
    
    -- Blood Boil for AoE damage and Blood Plague refresh
    if API.CanCast(spells.BLOOD_BOIL) then
        API.CastSpell(spells.BLOOD_BOIL)
        return true
    end
    
    -- Heart Strike for RP generation in DnD
    if activeRunes >= 1 and API.CanCast(spells.HEART_STRIKE) then
        API.CastSpell(spells.HEART_STRIKE)
        return true
    end
    
    -- Use Blooddrinker if talented
    if talents.hasBlooddrinker and API.CanCast(spells.BLOODDRINKER) then
        API.CastSpell(spells.BLOODDRINKER)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Blood:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("BloodDeathKnight")
    
    -- Maintain Bone Shield
    if settings.rotationSettings.maintainBoneShield then
        local minStacks = settings.rotationSettings.boneShieldMinimum
        local safetyBuffer = 0
        
        -- Adjust based on Marrowrend usage settings
        if settings.advancedSettings.mrrUsage == "Safe" then
            safetyBuffer = 1
        elseif settings.advancedSettings.mrrUsage == "Paranoid" then
            safetyBuffer = 2
        end
        
        if boneShieldStacks < (minStacks + safetyBuffer) and
           activeRunes >= 2 and
           API.CanCast(spells.MARROWREND) then
            API.CastSpell(spells.MARROWREND)
            return true
        end
    end
    
    -- Apply Blood Plague via Blood Boil
    if not bloodPlague and API.CanCast(spells.BLOOD_BOIL) then
        API.CastSpell(spells.BLOOD_BOIL)
        return true
    end
    
    -- Use Blooddrinker if talented
    if talents.hasBlooddrinker and API.CanCast(spells.BLOODDRINKER) then
        API.CastSpell(spells.BLOODDRINKER)
        return true
    end
    
    -- Use Consumption if talented
    if talents.hasConsumption and
       settings.abilityControls.consumption.enabled and
       API.GetPlayerHealthPercent() <= settings.abilityControls.consumption.healthThreshold and
       API.CanCast(spells.CONSUMPTION) then
        API.CastSpell(spells.CONSUMPTION)
        return true
    end
    
    -- Handle Death and Decay
    local shouldUseDnD = false
    
    if settings.advancedSettings.deathAndDecayUsage == "On Cooldown" then
        shouldUseDnD = true
    elseif settings.advancedSettings.deathAndDecayUsage == "With Crimson Scourge Only" and 
           API.PlayerHasBuff(buffs.CRIMSON_SCOURGE) then
        shouldUseDnD = true
    end
    
    if shouldUseDnD and 
       not deathAndDecayActive and 
       API.CanCast(DeathKnight.spells.DEATH_AND_DECAY) then
        API.CastSpellAtCursor(DeathKnight.spells.DEATH_AND_DECAY)
        return true
    end
    
    -- Use Death Strike based on settings and health
    local healthPct = API.GetPlayerHealthPercent()
    local deathStrikeThreshold = DEATHSTRIKE_MINIMUM_HEALTH
    
    if settings.rotationSettings.deathStrikePriority == "Defensive" then
        deathStrikeThreshold = deathStrikeThreshold + 10
    elseif settings.rotationSettings.deathStrikePriority == "Offensive" then
        deathStrikeThreshold = deathStrikeThreshold - 10
    end
    
    if (healthPct <= deathStrikeThreshold or runicPower >= RUNIC_POWER_THRESHOLD) and
       API.CanCast(spells.DEATH_STRIKE) then
        API.CastSpell(spells.DEATH_STRIKE)
        return true
    end
    
    -- Blood Boil for damage and Blood Plague refresh
    if API.CanCast(spells.BLOOD_BOIL) then
        API.CastSpell(spells.BLOOD_BOIL)
        return true
    end
    
    -- Heart Strike for RP generation
    if activeRunes >= 1 and API.CanCast(spells.HEART_STRIKE) then
        API.CastSpell(spells.HEART_STRIKE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Blood:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    emergencyMitigationNeeded = false
    boneShieldStacks = select(4, UnitBuff("player", GetSpellInfo(spells.BONE_SHIELD))) or 0
    runicPower = API.GetPlayerPower()
    vampiricBloodActive = API.PlayerHasBuff(buffs.VAMPIRIC_BLOOD)
    dancingRuneWeaponActive = API.PlayerHasBuff(buffs.DANCING_RUNE_WEAPON)
    tombstoneActive = API.PlayerHasBuff(buffs.TOMBSTONE)
    
    API.PrintDebug("Blood DK state reset on spec change")
    
    return true
end

-- Return the module for loading
return Blood