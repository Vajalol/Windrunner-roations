------------------------------------------
-- WindrunnerRotations - Fire Mage Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Fire = {}
addon.Classes.Mage.Fire = Fire

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local Mage = addon.Classes.Mage

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local combustionPhase = false
local cleaveTargetsCount = 0

-- Constants
local FIRE_SPEC_ID = 63

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
    -- Damage spells
    spells.FIREBALL = 133
    spells.PYROBLAST = 11366
    spells.FIRE_BLAST = 108853
    spells.PHOENIX_FLAMES = 257541
    spells.FLAMESTRIKE = 2120
    spells.DRAGONS_BREATH = 31661
    spells.SCORCH = 2948
    spells.LIVING_BOMB = 44457
    
    -- Cooldowns
    spells.COMBUSTION = 190319
    spells.RUNE_OF_POWER = 116011
    spells.MIRROR_IMAGE = 55342
    
    -- Talents/Passives
    spells.IGNITE = 12654
    spells.HEATING_UP = 48107
    spells.HOT_STREAK = 48108
    spells.KINDLING = 155148
    spells.PYROCLASM = 269650
    spells.PYROCLASM_BUFF = 269651
    spells.SEARING_TOUCH = 269644
    
    -- Legendary Effects
    spells.SUN_KINGS_BLESSING = 333313
    spells.SUN_KINGS_BLESSING_BUFF = 333314
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.COMBUSTION = spells.COMBUSTION
    buffs.HEATING_UP = spells.HEATING_UP
    buffs.HOT_STREAK = spells.HOT_STREAK
    buffs.PYROCLASM = spells.PYROCLASM_BUFF
    buffs.SUN_KINGS_BLESSING = spells.SUN_KINGS_BLESSING_BUFF
    buffs.RUNE_OF_POWER = spells.RUNE_OF_POWER
    
    debuffs.IGNITE = spells.IGNITE
    debuffs.LIVING_BOMB = spells.LIVING_BOMB
    
    return true
end

-- Register variables to track
function Fire:RegisterVariables()
    -- Talent tracking
    talents.hasKindling = false
    talents.hasPyroclasm = false
    talents.hasSearingTouch = false
    talents.hasRuneOfPower = false
    talents.hasLivingBomb = false
    talents.hasPhoenixFlames = false
    
    -- Legendary item tracking
    talents.hasSunKingsBlessing = false
    
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
                default = 3
            },
            useScorch = {
                displayName = "Use Scorch Execute",
                description = "Use Scorch when target is below 30% health with Searing Touch talent",
                type = "toggle",
                default = true
            },
            holdHotStreak = {
                displayName = "Hold Hot Streak During Combustion",
                description = "Hold Hot Streak procs for Fire Blast windows during Combustion",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useCombustion = {
                displayName = "Use Combustion",
                description = "Automatically use Combustion for burst damage",
                type = "toggle",
                default = true
            },
            combustionWithRune = {
                displayName = "Combustion with Rune of Power",
                description = "Only use Combustion when standing in Rune of Power",
                type = "toggle",
                default = true
            },
            saveFireBlasts = {
                displayName = "Save Fire Blast for Combustion",
                description = "Save Fire Blast charges for Combustion phase",
                type = "toggle",
                default = true
            },
            minFireBlastCharges = {
                displayName = "Minimum Fire Blast Charges",
                description = "Minimum Fire Blast charges to save for Combustion",
                type = "slider",
                min = 0,
                max = 3,
                default = 2
            }
        },
        
        advancedSettings = {
            hardcastPyroblast = {
                displayName = "Hard-cast Pyroblast",
                description = "Hard-cast Pyroblast when Pyroclasm buff is active",
                type = "toggle",
                default = true
            },
            usePrecastPyroblast = {
                displayName = "Pre-cast Pyroblast on Pull",
                description = "Use Pyroblast as a pre-cast spell when pulling",
                type = "toggle",
                default = true
            },
            scorchHealthThreshold = {
                displayName = "Scorch Health Threshold",
                description = "Enemy health percentage to start using Scorch with Searing Touch",
                type = "slider",
                min = 10,
                max = 35, 
                default = 30
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Combustion controls
            combustion = AAC.RegisterAbility(spells.COMBUSTION, {
                enabled = true,
                useDuringBurstOnly = true,
                minimumHealthPercent = 0
            }),
            
            -- Rune of Power controls
            runeOfPower = AAC.RegisterAbility(spells.RUNE_OF_POWER, {
                enabled = true,
                useDuringBurstOnly = false,
                useWithCombustion = true
            }),
            
            -- Mirror Image controls
            mirrorImage = AAC.RegisterAbility(spells.MIRROR_IMAGE, {
                enabled = true,
                useDuringBurstOnly = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Fire:RegisterEvents()
    -- Register for combat log events to track critical strikes
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
    talents.hasKindling = API.HasTalent(spells.KINDLING)
    talents.hasPyroclasm = API.HasTalent(spells.PYROCLASM)
    talents.hasSearingTouch = API.HasTalent(spells.SEARING_TOUCH)
    -- Other talents would be checked here with similar API calls
    
    -- Check for legendary effects
    talents.hasSunKingsBlessing = API.HasLegendaryEffect(spells.SUN_KINGS_BLESSING)
    
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
                igniteStack = 0,
                igniteExpiration = 0,
                livingBomb = false,
                livingBombExpiration = 0,
                lastCritTime = 0
            }
        end
    end
    
    return true
end

-- Handle combat log events
function Fire:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return
    end
    
    -- Track critical hits for Heating Up/Hot Streak logic
    if eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
        local _, _, _, _, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
        
        -- Initialize target data if needed
        if not self.targetData[destGUID] then
            self:UpdateTargetData()
        end
        
        -- Track critical hit time for this target
        if critical and self.targetData[destGUID] then
            self.targetData[destGUID].lastCritTime = timestamp
        end
        
        -- Special handling for Ignite
        if spellID == spells.IGNITE then
            if self.targetData[destGUID] then
                -- Update Ignite tracking
                self.targetData[destGUID].igniteStack = select(15, API.GetDebuffInfo(destGUID, spells.IGNITE))
                self.targetData[destGUID].igniteExpiration = select(6, API.GetDebuffInfo(destGUID, spells.IGNITE))
            end
        end
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track Living Bomb on target
        if spellID == spells.LIVING_BOMB and self.targetData[destGUID] then
            self.targetData[destGUID].livingBomb = true
            self.targetData[destGUID].livingBombExpiration = select(6, API.GetDebuffInfo(destGUID, spells.LIVING_BOMB))
        end
        
        -- Track Combustion phase
        if spellID == spells.COMBUSTION and destGUID == API.GetPlayerGUID() then
            combustionPhase = true
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track Living Bomb removal
        if spellID == spells.LIVING_BOMB and self.targetData[destGUID] then
            self.targetData[destGUID].livingBomb = false
        end
        
        -- Track Combustion phase end
        if spellID == spells.COMBUSTION and destGUID == API.GetPlayerGUID() then
            combustionPhase = false
        end
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
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FireMage")
    
    -- Update variables
    cleaveTargetsCount = API.GetNearbyEnemiesCount(8) -- Count enemies in 8yd radius for Flamestrike
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
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
    if settings.rotationSettings.aoeEnabled and cleaveTargetsCount >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation()
    else
        return self:HandleSingleTargetRotation()
    end
end

-- Handle cooldown abilities
function Fire:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("FireMage")
    
    -- Skip cooldowns if not in burst mode and settings require burst mode
    if not burstModeActive and settings.abilityControls.combustion.useDuringBurstOnly then
        return false
    end
    
    -- Use Rune of Power
    if talents.hasRuneOfPower and settings.abilityControls.runeOfPower.enabled then
        -- Only use Rune if player is not moving
        if not API.IsPlayerMoving() and API.CanCast(spells.RUNE_OF_POWER) then
            -- Check if we should save for Combustion
            local savingForCombustion = settings.abilityControls.runeOfPower.useWithCombustion and 
                                       settings.cooldownSettings.useCombustion and
                                       API.GetSpellCooldownRemaining(spells.COMBUSTION) < 10
            
            if not savingForCombustion then
                API.CastSpell(spells.RUNE_OF_POWER)
                return true
            end
        end
    end
    
    -- Use Mirror Image
    if settings.abilityControls.mirrorImage.enabled and 
       (not settings.abilityControls.mirrorImage.useDuringBurstOnly or burstModeActive) and
       API.CanCast(spells.MIRROR_IMAGE) then
        API.CastSpell(spells.MIRROR_IMAGE)
        return true
    end
    
    -- Use Combustion
    if settings.cooldownSettings.useCombustion and settings.abilityControls.combustion.enabled and
       API.CanCast(spells.COMBUSTION) then
        -- Check for Rune of Power requirement
        local runeConditionMet = not settings.cooldownSettings.combustionWithRune or 
                                API.PlayerHasBuff(spells.RUNE_OF_POWER)
        
        -- Check for min health requirement
        local healthConditionMet = API.GetTargetHealthPercent() >= settings.abilityControls.combustion.minimumHealthPercent
        
        -- Check for burst mode requirement
        local burstConditionMet = not settings.abilityControls.combustion.useDuringBurstOnly or burstModeActive
        
        if runeConditionMet and healthConditionMet and burstConditionMet then
            API.CastSpell(spells.COMBUSTION)
            combustionPhase = true
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Fire:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("FireMage")
    
    -- Use Hot Streak procs on Flamestrike
    if API.PlayerHasBuff(buffs.HOT_STREAK) then
        if API.CanCast(spells.FLAMESTRIKE) then
            API.CastSpellAtCursor(spells.FLAMESTRIKE)
            return true
        end
    end
    
    -- Use Fire Blast to convert Heating Up to Hot Streak
    if API.PlayerHasBuff(buffs.HEATING_UP) and not API.PlayerHasBuff(buffs.HOT_STREAK) then
        -- Check if we should save Fire Blast for Combustion
        local shouldSaveFireBlast = settings.cooldownSettings.saveFireBlasts and
                                   not combustionPhase and
                                   API.GetSpellCharges(spells.FIRE_BLAST) <= settings.cooldownSettings.minFireBlastCharges
        
        if not shouldSaveFireBlast and API.CanCast(spells.FIRE_BLAST) then
            API.CastSpell(spells.FIRE_BLAST)
            return true
        end
    end
    
    -- Use Phoenix Flames for cleave and Hot Streak generation
    if talents.hasPhoenixFlames and API.CanCast(spells.PHOENIX_FLAMES) then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- Use Living Bomb if available and not already applied
    if talents.hasLivingBomb and API.CanCast(spells.LIVING_BOMB) then
        local targetGUID = API.GetTargetGUID()
        if targetGUID and self.targetData[targetGUID] and not self.targetData[targetGUID].livingBomb then
            API.CastSpell(spells.LIVING_BOMB)
            return true
        end
    end
    
    -- Use Dragon's Breath if in range
    if API.IsSpellInRange(spells.DRAGONS_BREATH) and API.CanCast(spells.DRAGONS_BREATH) then
        API.CastSpell(spells.DRAGONS_BREATH)
        return true
    end
    
    -- Default to Fireball for AoE when nothing else is available
    if API.CanCast(spells.FIREBALL) then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Fire:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("FireMage")
    
    -- Get target health percentage
    local targetHealthPct = API.GetTargetHealthPercent()
    
    -- Execute phase logic with Searing Touch
    local executePhase = talents.hasSearingTouch and 
                         targetHealthPct <= settings.advancedSettings.scorchHealthThreshold and
                         settings.rotationSettings.useScorch
    
    -- Use Hot Streak procs
    if API.PlayerHasBuff(buffs.HOT_STREAK) then
        -- Check if we should hold Hot Streak during Combustion
        local shouldHold = settings.rotationSettings.holdHotStreak and 
                          combustionPhase and
                          API.GetSpellCharges(spells.FIRE_BLAST) == 0
        
        if not shouldHold and API.CanCast(spells.PYROBLAST) then
            API.CastSpell(spells.PYROBLAST)
            return true
        end
    end
    
    -- Use Pyroclasm procs for hard-cast Pyroblasts
    if settings.advancedSettings.hardcastPyroblast and 
       API.PlayerHasBuff(buffs.PYROCLASM) and
       not API.IsPlayerMoving() and
       API.CanCast(spells.PYROBLAST) then
        API.CastSpell(spells.PYROBLAST)
        return true
    end
    
    -- Use Fire Blast to convert Heating Up to Hot Streak
    if API.PlayerHasBuff(buffs.HEATING_UP) and not API.PlayerHasBuff(buffs.HOT_STREAK) then
        -- Check if we should save Fire Blast for Combustion
        local shouldSaveFireBlast = settings.cooldownSettings.saveFireBlasts and
                                   not combustionPhase and
                                   API.GetSpellCharges(spells.FIRE_BLAST) <= settings.cooldownSettings.minFireBlastCharges
        
        if not shouldSaveFireBlast and API.CanCast(spells.FIRE_BLAST) then
            API.CastSpell(spells.FIRE_BLAST)
            return true
        end
    end
    
    -- Use Phoenix Flames for Hot Streak generation
    if talents.hasPhoenixFlames and
       not API.PlayerHasBuff(buffs.HOT_STREAK) and
       API.CanCast(spells.PHOENIX_FLAMES) then
        API.CastSpell(spells.PHOENIX_FLAMES)
        return true
    end
    
    -- Use Scorch in execute phase if Searing Touch is talented
    if executePhase and API.CanCast(spells.SCORCH) then
        API.CastSpell(spells.SCORCH)
        return true
    end
    
    -- Default to Fireball
    if API.CanCast(spells.FIREBALL) and not API.IsPlayerMoving() then
        API.CastSpell(spells.FIREBALL)
        return true
    end
    
    -- Movement filler - Scorch
    if API.IsPlayerMoving() and API.CanCast(spells.SCORCH) then
        API.CastSpell(spells.SCORCH)
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
    combustionPhase = false
    
    return true
end

-- Return the module for loading
return Fire