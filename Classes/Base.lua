local addonName, WR = ...

-- Base Class for all rotation implementations
local BaseClass = {}
WR.BaseClass = BaseClass

-- Spec data storage
BaseClass.Specs = {}

-- Base initialization function
function BaseClass:Initialize()
    self.spells = {}
    self.talents = {}
    self.buffs = {}
    self.debuffs = {}
    self.cooldowns = {}
    self.settings = {}
    self.aoeRotation = {}
    self.singleTargetRotation = {}
    self.defensiveRotation = {}
    self.interruptRotation = {}
    self.burstRotation = {}
    self.ccAbilities = {}
    self.dispelTypes = {}
    self.specialFunctions = {}
    self.resourceType = nil
    self.secondaryResourceType = nil
    
    -- Default settings
    self.settings = {
        enabled = true,
        useAoE = true,
        useDefensives = true,
        useCooldowns = false,
        useInterrupts = true,
        minAoETargets = 3, -- Minimum targets to switch to AoE rotation
        burstModeActive = false,
        burstKeyPressed = false,
        interruptPercentage = 70, -- Percentage chance to use interrupt
        defensiveHpThreshold = 50, -- HP percentage to use defensives
        dispelAllowed = true,
        saveResourcesForBurst = false,
        rotationType = "standard", -- standard, aoe, cleave, execute, etc.
    }
    
    -- Initialize class-specific data
    self:LoadClassData()
    
    WR:Debug("BaseClass initialized")
end

-- Load class-specific data (to be overridden by each class)
function BaseClass:LoadClassData()
    -- This function should be overridden by each class implementation
    -- It should load spell IDs, talent builds, etc.
end

-- Register a specialization
function BaseClass:RegisterSpec(specId, specName)
    self.Specs[specId] = {
        name = specName,
        enabled = true,
        spells = {},
        talents = {},
        rotation = {},
        aoeRotation = {},
        defensives = {},
        interrupts = {},
        cooldowns = {},
        dispels = {},
        utility = {},
    }
    
    return self.Specs[specId]
end

-- Load a specific specialization (called when player's spec changes)
function BaseClass:LoadSpec(specId)
    if not self.Specs[specId] then
        WR:Debug("Spec ID not found:", specId)
        return false
    end
    
    self.currentSpec = specId
    self.specData = self.Specs[specId]
    
    -- Load spec-specific data
    self:LoadSpecSpells(specId)
    self:LoadSpecTalents(specId)
    self:LoadSpecRotation(specId)
    
    WR:Debug("Loaded spec:", self.specData.name)
    return true
end

-- Load spells for a specific specialization
function BaseClass:LoadSpecSpells(specId)
    -- This function should be overridden by each class
    -- It should populate self.spells with spell IDs
end

-- Load talents for a specific specialization
function BaseClass:LoadSpecTalents(specId)
    -- Scan the player's selected talents
    -- This would need to be updated for different WoW versions
    self.talents = {}
    
    -- Function to check if a talent is selected
    local function IsTalentSelected(tier, column, specIndex)
        local selected = select(4, GetTalentInfo(tier, column, specIndex or 1))
        return selected
    end
    
    -- Scan each talent row and column
    for tier = 1, MAX_TALENT_TIERS do
        for column = 1, NUM_TALENT_COLUMNS do
            local talentID, name, texture, selected = GetTalentInfo(tier, column, 1)
            if selected then
                self.talents[tier] = {
                    id = talentID,
                    name = name,
                    column = column
                }
                WR:Debug("Talent selected:", name, "Tier:", tier, "Column:", column)
            end
        end
    end
end

-- Load rotation for a specific specialization
function BaseClass:LoadSpecRotation(specId)
    -- This function should be overridden by each class
    -- It should populate single target, AoE, and other rotations
end

-- Get resource amount (mana, rage, energy, etc.)
function BaseClass:GetResource()
    if not self.resourceType then return 0, 0 end
    
    local current = UnitPower("player", self.resourceType)
    local max = UnitPowerMax("player", self.resourceType)
    
    return current, max
end

-- Get resource percentage
function BaseClass:GetResourcePct()
    local current, max = self:GetResource()
    if max == 0 then return 0 end
    
    return (current / max) * 100
end

-- Get secondary resource (combo points, holy power, etc.)
function BaseClass:GetSecondaryResource()
    if not self.secondaryResourceType then return 0, 0 end
    
    local current = UnitPower("player", self.secondaryResourceType)
    local max = UnitPowerMax("player", self.secondaryResourceType)
    
    return current, max
end

-- Execute the rotation logic (main function called by the rotation engine)
function BaseClass:ExecuteRotation()
    -- Check if player is dead or in combat
    if UnitIsDeadOrGhost("player") then return nil end
    
    -- Basic checks before attempting any rotation
    if not self:PreRotationChecks() then return nil end
    
    local spell = nil
    
    -- Check for interrupts first if enabled
    if self.settings.useInterrupts then
        spell = self:HandleInterrupts()
        if spell then return spell end
    end
    
    -- Check for defensives if enabled and health is low
    if self.settings.useDefensives and UnitHealth("player") / UnitHealthMax("player") * 100 < self.settings.defensiveHpThreshold then
        spell = self:HandleDefensives()
        if spell then return spell end
    end
    
    -- Determine whether to use AoE or single target rotation
    local enemyCount = WR.Target:GetTargetCount(8) -- 8 yards default AoE radius
    
    -- Use AoE rotation if enough targets and AoE is enabled
    if self.settings.useAoE and enemyCount >= self.settings.minAoETargets then
        spell = self:ExecuteAoERotation()
    else
        spell = self:ExecuteSingleTargetRotation()
    end
    
    -- If no spell was selected, fall back to default actions
    if not spell then
        spell = self:GetDefaultAction()
    end
    
    return spell
end

-- Pre-rotation checks
function BaseClass:PreRotationChecks()
    -- Check if we're in combat or have a target
    if not UnitAffectingCombat("player") and not UnitExists("target") then
        return false
    end
    
    -- Check if we're able to cast (not stunned, silenced, etc.)
    if WR.API:IsPacified() or WR.API:IsSilenced() or WR.API:IsStunned() then
        return false
    end
    
    -- Class-specific checks
    return self:ClassSpecificChecks()
end

-- Class-specific pre-rotation checks (to be overridden)
function BaseClass:ClassSpecificChecks()
    -- Override for class-specific logic
    return true
end

-- Handle interrupts
function BaseClass:HandleInterrupts()
    -- Random check against interrupt percentage setting
    if math.random(100) > self.settings.interruptPercentage then
        return nil
    end
    
    -- Find interrupt target
    local interruptTarget = WR.Target:FindInterruptTarget()
    if not interruptTarget then return nil end
    
    -- Go through available interrupt abilities
    for _, interruptData in ipairs(self.interruptRotation) do
        local spellId = interruptData.spell
        
        -- Check if we have this interrupt spell
        if spellId and self.spells[spellId] then
            -- Check if spell is usable (not on cooldown, etc)
            if WR.API:IsSpellUsable(spellId) and not WR.Cooldown:IsOnCooldown(spellId) then
                -- Set target for interrupt
                WR.Target:SetTarget(interruptTarget)
                
                -- Return the interrupt spell
                return spellId
            end
        end
    end
    
    return nil
end

-- Handle defensives
function BaseClass:HandleDefensives()
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Go through available defensive abilities
    for _, defensiveData in ipairs(self.defensiveRotation) do
        local spellId = defensiveData.spell
        local threshold = defensiveData.threshold or self.settings.defensiveHpThreshold
        
        -- Check if our health is below the threshold for this defensive
        if healthPct <= threshold then
            -- Check if we have this defensive spell
            if spellId and self.spells[spellId] then
                -- Check if spell is usable (not on cooldown, etc)
                if WR.API:IsSpellUsable(spellId) and not WR.Cooldown:IsOnCooldown(spellId) then
                    -- Return the defensive spell
                    return spellId
                end
            end
        end
    end
    
    return nil
end

-- Execute single target rotation
function BaseClass:ExecuteSingleTargetRotation()
    -- Check if we should use cooldowns
    local useCooldowns = self.settings.useCooldowns or self.settings.burstModeActive
    
    -- Use burst rotation if cooldowns are allowed
    if useCooldowns and #self.burstRotation > 0 then
        local spell = self:ExecuteBurstRotation()
        if spell then return spell end
    end
    
    -- Go through the single target rotation
    for _, rotationEntry in ipairs(self.singleTargetRotation) do
        local spellId = rotationEntry.spell
        local condition = rotationEntry.condition
        
        -- Check if we have this spell
        if spellId and self.spells[spellId] then
            -- Check for conditions if provided
            if condition and type(condition) == "function" then
                if not condition(self) then
                    goto continue
                end
            end
            
            -- Check if spell is usable
            if WR.API:IsSpellUsable(spellId) and not WR.Cooldown:IsOnCooldown(spellId) then
                -- Check if target is in range
                if WR.API:IsSpellInRange(spellId, "target") then
                    return spellId
                end
            end
        end
        
        ::continue::
    end
    
    return nil
end

-- Execute AoE rotation
function BaseClass:ExecuteAoERotation()
    -- Similar to single target but using the AoE rotation
    for _, rotationEntry in ipairs(self.aoeRotation) do
        local spellId = rotationEntry.spell
        local condition = rotationEntry.condition
        
        -- Check if we have this spell
        if spellId and self.spells[spellId] then
            -- Check for conditions if provided
            if condition and type(condition) == "function" then
                if not condition(self) then
                    goto continue
                end
            end
            
            -- Check if spell is usable
            if WR.API:IsSpellUsable(spellId) and not WR.Cooldown:IsOnCooldown(spellId) then
                -- Check if target is in range
                if WR.API:IsSpellInRange(spellId, "target") then
                    return spellId
                end
            end
        end
        
        ::continue::
    end
    
    -- If no AoE spell is available, fall back to single target rotation
    return self:ExecuteSingleTargetRotation()
end

-- Execute burst/cooldown rotation
function BaseClass:ExecuteBurstRotation()
    for _, rotationEntry in ipairs(self.burstRotation) do
        local spellId = rotationEntry.spell
        local condition = rotationEntry.condition
        
        -- Check if we have this spell
        if spellId and self.spells[spellId] then
            -- Check for conditions if provided
            if condition and type(condition) == "function" then
                if not condition(self) then
                    goto continue
                end
            end
            
            -- Check if spell is usable
            if WR.API:IsSpellUsable(spellId) and not WR.Cooldown:IsOnCooldown(spellId) then
                -- Check if target is in range for targeted spells
                if not WR.API:IsSpellRequiresTarget(spellId) or WR.API:IsSpellInRange(spellId, "target") then
                    return spellId
                end
            end
        end
        
        ::continue::
    end
    
    return nil
end

-- Get default action when nothing else is available
function BaseClass:GetDefaultAction()
    -- This should be overridden for each class
    -- Default might be basic attack or something class-specific
    return nil
end

-- Check if a talent is selected
function BaseClass:HasTalent(talentName)
    for tier, talentData in pairs(self.talents) do
        if talentData.name == talentName then
            return true
        end
    end
    
    return false
end

-- Check if player has a buff
function BaseClass:HasBuff(buffSpellId, unit)
    unit = unit or "player"
    return WR.Auras:UnitHasAura(unit, buffSpellId, "HELPFUL")
end

-- Check if player has a buff with a minimum stack count
function BaseClass:HasBuffStack(buffSpellId, minStacks, unit)
    unit = unit or "player"
    local stacks = WR.Auras:GetAuraStacks(unit, buffSpellId, "HELPFUL")
    return stacks >= (minStacks or 1)
end

-- Get remaining time on a buff
function BaseClass:GetBuffRemaining(buffSpellId, unit)
    unit = unit or "player"
    return WR.Auras:GetAuraRemaining(unit, buffSpellId, "HELPFUL")
end

-- Check if target has a debuff
function BaseClass:HasDebuff(debuffSpellId, unit)
    unit = unit or "target"
    return WR.Auras:UnitHasAura(unit, debuffSpellId, "HARMFUL")
end

-- Check if target has a debuff with a minimum stack count
function BaseClass:HasDebuffStack(debuffSpellId, minStacks, unit)
    unit = unit or "target"
    local stacks = WR.Auras:GetAuraStacks(unit, debuffSpellId, "HARMFUL")
    return stacks >= (minStacks or 1)
end

-- Get remaining time on a debuff
function BaseClass:GetDebuffRemaining(debuffSpellId, unit)
    unit = unit or "target"
    return WR.Auras:GetAuraRemaining(unit, debuffSpellId, "HARMFUL")
end

-- Check if a spell is on cooldown
function BaseClass:SpellOnCooldown(spellId)
    return WR.Cooldown:IsOnCooldown(spellId)
end

-- Get remaining cooldown time
function BaseClass:GetSpellCooldown(spellId)
    return WR.Cooldown:GetCooldownRemaining(spellId)
end

-- Check if spell has charges available
function BaseClass:SpellHasCharges(spellId)
    local charges, maxCharges = WR.Cooldown:GetSpellCharges(spellId)
    return charges > 0
end

-- Get the number of charges for a spell
function BaseClass:GetSpellCharges(spellId)
    local charges, maxCharges = WR.Cooldown:GetSpellCharges(spellId)
    return charges, maxCharges
end

-- Check if player is in combat
function BaseClass:InCombat()
    return UnitAffectingCombat("player")
end

-- Get the player's current health percentage
function BaseClass:GetHealthPct()
    return UnitHealth("player") / UnitHealthMax("player") * 100
end

-- Get the target's current health percentage
function BaseClass:GetTargetHealthPct()
    if not UnitExists("target") then return 0 end
    return UnitHealth("target") / UnitHealthMax("target") * 100
end

-- Check if target is in execute range (typically below 20% health)
function BaseClass:TargetInExecuteRange(threshold)
    threshold = threshold or 20
    return self:GetTargetHealthPct() < threshold
end

-- Check if there are enough enemies nearby for AoE
function BaseClass:HasAoETargets()
    return WR.Target:GetTargetCount(8) >= self.settings.minAoETargets
end

-- Get the number of nearby enemies
function BaseClass:GetEnemyCount(range)
    range = range or 8
    return WR.Target:GetTargetCount(range)
end

-- Check if target is valid for attacking
function BaseClass:HasValidTarget()
    return WR.Target:HasValidTarget()
end

-- Set a setting value
function BaseClass:SetSetting(key, value)
    if self.settings[key] ~= nil then
        self.settings[key] = value
        WR:Debug("Setting", key, "set to", value)
        return true
    else
        WR:Debug("Setting", key, "not found")
        return false
    end
end

-- Get a setting value
function BaseClass:GetSetting(key)
    return self.settings[key]
end

-- Initialize the base class
BaseClass:Initialize()

return BaseClass