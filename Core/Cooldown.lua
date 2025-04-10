local addonName, WR = ...

-- Cooldown module - handles tracking and management of cooldowns
local Cooldown = {}
WR.Cooldown = Cooldown

-- State
local state = {
    activeCooldowns = {}, -- Active cooldowns: {spellId = {startTime, duration, charges, maxCharges}}
    chargedAbilities = {}, -- Abilities with charges: {spellId = {charges, maxCharges, chargeStart, chargeDuration, lastUpdate}}
    playerBuffs = {}, -- Active player buffs: {spellId = {expirationTime, duration, stacks}}
    targetDebuffs = {}, -- Active target debuffs: {spellId = {expirationTime, duration, stacks}}
    spellHistory = {}, -- History of spell usage: {spellId = {lastCast, count}}
    cooldownTriggers = {}, -- Spell effects that trigger other cooldowns: {triggerSpellId = {{spellId, duration}}}
    cooldownReductions = {}, -- CDs that reduce other CDs: {reducerSpellId = {{spellId, amount}}}
    lastUpdate = 0,
    updateInterval = 0.1, -- Update cooldowns every 100ms
    unitCacheDuration = 0.2, -- Cache unit buffs/debuffs for 200ms
    unitCache = {}, -- Cache unit auras: {unit = {lastUpdate, buffs = {}, debuffs = {}}}
}

-- Initialize the cooldown system
function Cooldown:Initialize()
    -- Create a frame for OnUpdate event
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        Cooldown:OnUpdate(elapsed)
    end)
    
    -- Register for events
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("SPELL_UPDATE_CHARGES")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" then
            Cooldown:UpdateAllCooldowns()
        elseif event == "SPELL_UPDATE_CHARGES" then
            Cooldown:UpdateAllCharges()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            Cooldown:UNIT_SPELLCAST_SUCCEEDED(...)
        elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            Cooldown:UpdateClassSpecificData()
        end
    end)
    
    -- Initialize class-specific cooldown data
    self:UpdateClassSpecificData()
    
    WR:Debug("Cooldown system initialized")
end

-- Update class-specific cooldown data based on spec and talents
function Cooldown:UpdateClassSpecificData()
    -- This would be populated dynamically based on the player's class and talents
    -- For now, we'll just initialize empty tables
    state.cooldownTriggers = {}
    state.cooldownReductions = {}
    
    -- Register class-specific cooldown interactions
    self:RegisterClassCooldownData()
end

-- Register class-specific cooldown interactions (would be expanded per class)
function Cooldown:RegisterClassCooldownData()
    local playerClass, _ = UnitClass("player")
    
    if playerClass == "MAGE" then
        -- Mage example: Time Warp triggers cooldown on Bloodlust, Heroism, etc.
        self:RegisterCooldownTrigger(80353, 57724, 600) -- Time Warp triggers Satiated (600 seconds)
        
        -- Icy Veins benefits from cooldown reduction via Thermal Void talent
        -- ... more mage-specific logic
        
    elseif playerClass == "WARRIOR" then
        -- Warrior example: Avatar reduces Recklessness cooldown when talented
        -- ... warrior-specific logic
        
    elseif playerClass == "HUNTER" then
        -- Hunter example: Trueshot and effects
        -- ... hunter-specific logic
        
    elseif playerClass == "PRIEST" then
        -- Priest example: Power Infusion cooldown handling
        -- ... priest-specific logic
    end
    
    -- This method would be expanded with class-specific logic
end

-- Register a spell that triggers a cooldown on another spell
function Cooldown:RegisterCooldownTrigger(triggerSpellId, affectedSpellId, duration)
    if not state.cooldownTriggers[triggerSpellId] then
        state.cooldownTriggers[triggerSpellId] = {}
    end
    
    table.insert(state.cooldownTriggers[triggerSpellId], {
        spellId = affectedSpellId,
        duration = duration
    })
    
    WR:Debug("Registered cooldown trigger:", GetSpellInfo(triggerSpellId), "->", GetSpellInfo(affectedSpellId), "for", duration, "sec")
end

-- Register a spell that reduces cooldowns of other spells
function Cooldown:RegisterCooldownReduction(reducerSpellId, affectedSpellId, amount)
    if not state.cooldownReductions[reducerSpellId] then
        state.cooldownReductions[reducerSpellId] = {}
    end
    
    table.insert(state.cooldownReductions[reducerSpellId], {
        spellId = affectedSpellId,
        amount = amount
    })
    
    WR:Debug("Registered cooldown reduction:", GetSpellInfo(reducerSpellId), "->", GetSpellInfo(affectedSpellId), "by", amount, "sec")
end

-- OnUpdate handler
function Cooldown:OnUpdate(elapsed)
    local now = GetTime()
    
    -- Don't update too frequently
    if now - state.lastUpdate < state.updateInterval then return end
    state.lastUpdate = now
    
    -- Update active cooldowns
    for spellId, cooldownData in pairs(state.activeCooldowns) do
        -- Update the cooldown time remaining
        local start, duration = GetSpellCooldown(spellId)
        
        if start > 0 and duration > 0 then
            -- Cooldown is active
            cooldownData.startTime = start
            cooldownData.duration = duration
        else
            -- Cooldown is finished
            state.activeCooldowns[spellId] = nil
        end
    end
    
    -- Update charged abilities
    for spellId, chargeData in pairs(state.chargedAbilities) do
        -- Update charge information
        local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellId)
        
        if charges then
            chargeData.charges = charges
            chargeData.maxCharges = maxCharges
            chargeData.chargeStart = chargeStart
            chargeData.chargeDuration = chargeDuration
            chargeData.lastUpdate = now
        end
    end
    
    -- Clean up unit cache
    for unit, cacheData in pairs(state.unitCache) do
        if now - cacheData.lastUpdate > state.unitCacheDuration then
            state.unitCache[unit] = nil
        end
    end
end

-- Handle spell cast success events
function Cooldown:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellId)
    if unit ~= "player" then return end
    
    -- Record spell usage in history
    if not state.spellHistory[spellId] then
        state.spellHistory[spellId] = {
            lastCast = GetTime(),
            count = 1
        }
    else
        state.spellHistory[spellId].lastCast = GetTime()
        state.spellHistory[spellId].count = state.spellHistory[spellId].count + 1
    end
    
    -- Check if this spell triggers cooldowns on other spells
    if state.cooldownTriggers[spellId] then
        for _, trigger in ipairs(state.cooldownTriggers[spellId]) do
            -- Set cooldown on the affected spell
            self:StartCooldown(trigger.spellId, trigger.duration)
        end
    end
    
    -- Check if this spell reduces cooldowns on other spells
    if state.cooldownReductions[spellId] then
        for _, reduction in ipairs(state.cooldownReductions[spellId]) do
            -- Reduce cooldown on the affected spell
            self:ReduceCooldown(reduction.spellId, reduction.amount)
        end
    end
end

-- Update all cooldowns
function Cooldown:UpdateAllCooldowns()
    -- This could be expanded to scan for cooldowns of important spells
    -- For now, we'll rely on catching cooldowns through spell cast events
end

-- Update all spell charges
function Cooldown:UpdateAllCharges()
    -- This could be expanded to scan for charges of important spells
    -- For now, we'll rely on capturing charges through spell cast events
end

-- Start tracking a cooldown
function Cooldown:StartTracking(spellId)
    if not spellId or not GetSpellInfo(spellId) then
        return false
    end
    
    -- Check if the spell has charges
    local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellId)
    
    if charges then
        -- This is a charged ability
        state.chargedAbilities[spellId] = {
            charges = charges,
            maxCharges = maxCharges,
            chargeStart = chargeStart,
            chargeDuration = chargeDuration,
            lastUpdate = GetTime()
        }
    else
        -- Regular cooldown
        local start, duration = GetSpellCooldown(spellId)
        
        if start > 0 and duration > 0 then
            -- Cooldown is active
            state.activeCooldowns[spellId] = {
                startTime = start,
                duration = duration,
                charges = 0,
                maxCharges = 0
            }
        end
    end
    
    return true
end

-- Stop tracking a cooldown
function Cooldown:StopTracking(spellId)
    if not spellId then return false end
    
    state.activeCooldowns[spellId] = nil
    state.chargedAbilities[spellId] = nil
    
    return true
end

-- Manually start a cooldown (for abilities that trigger cooldowns on others)
function Cooldown:StartCooldown(spellId, duration)
    if not spellId or not GetSpellInfo(spellId) then
        return false
    end
    
    -- Create a custom cooldown entry
    state.activeCooldowns[spellId] = {
        startTime = GetTime(),
        duration = duration,
        charges = 0,
        maxCharges = 0
    }
    
    return true
end

-- Reduce a cooldown
function Cooldown:ReduceCooldown(spellId, amount)
    if not spellId or not GetSpellInfo(spellId) then
        return false
    end
    
    -- Check if we're tracking this cooldown
    if state.activeCooldowns[spellId] then
        local cdData = state.activeCooldowns[spellId]
        local remainingTime = (cdData.startTime + cdData.duration) - GetTime()
        
        if remainingTime > amount then
            -- Reduce the cooldown
            cdData.duration = cdData.duration - amount
        else
            -- Cooldown is finished
            state.activeCooldowns[spellId] = nil
        end
        
        return true
    end
    
    -- Check if it's a charged ability
    if state.chargedAbilities[spellId] then
        -- Reducing cooldown of charged abilities is more complex
        -- This would need to be implemented based on game mechanics
        
        return true
    end
    
    return false
end

-- Get cooldown info for a spell
function Cooldown:GetCooldownInfo(spellId)
    if not spellId then return nil end
    
    -- Check charged abilities first
    if state.chargedAbilities[spellId] then
        local chargeData = state.chargedAbilities[spellId]
        local charges = chargeData.charges
        local maxCharges = chargeData.maxCharges
        local chargeStart = chargeData.chargeStart
        local chargeDuration = chargeData.chargeDuration
        
        -- Calculate time until next charge
        local chargeTimeRemaining = 0
        if chargeStart and chargeDuration and charges < maxCharges then
            chargeTimeRemaining = (chargeStart + chargeDuration) - GetTime()
            if chargeTimeRemaining < 0 then chargeTimeRemaining = 0 end
        end
        
        return {
            onCooldown = charges < maxCharges,
            charges = charges,
            maxCharges = maxCharges,
            timeRemaining = chargeTimeRemaining,
            duration = chargeDuration
        }
    end
    
    -- Check regular cooldowns
    if state.activeCooldowns[spellId] then
        local cdData = state.activeCooldowns[spellId]
        local timeRemaining = (cdData.startTime + cdData.duration) - GetTime()
        
        if timeRemaining < 0 then timeRemaining = 0 end
        
        return {
            onCooldown = timeRemaining > 0,
            charges = 0,
            maxCharges = 0,
            timeRemaining = timeRemaining,
            duration = cdData.duration
        }
    end
    
    -- Not actively tracking this spell, get current info
    local start, duration, enabled = GetSpellCooldown(spellId)
    
    if start and duration then
        local timeRemaining = (start + duration) - GetTime()
        if timeRemaining < 0 then timeRemaining = 0 end
        
        return {
            onCooldown = (start > 0 and duration > 0),
            charges = 0,
            maxCharges = 0,
            timeRemaining = timeRemaining,
            duration = duration
        }
    end
    
    return nil
end

-- Check if a spell is on cooldown
function Cooldown:IsOnCooldown(spellId)
    local info = self:GetCooldownInfo(spellId)
    
    if info then
        if info.charges and info.charges > 0 then
            -- Spell has charges available
            return false
        end
        
        return info.onCooldown
    end
    
    -- Default to direct query if we're not tracking this spell
    local start, duration, enabled = GetSpellCooldown(spellId)
    return start > 0 and duration > 0
end

-- Get time remaining on cooldown
function Cooldown:GetCooldownRemaining(spellId)
    local info = self:GetCooldownInfo(spellId)
    
    if info then
        return info.timeRemaining
    end
    
    -- Default to direct query if we're not tracking this spell
    local start, duration = GetSpellCooldown(spellId)
    
    if start and duration then
        local remaining = (start + duration) - GetTime()
        if remaining < 0 then remaining = 0 end
        return remaining
    end
    
    return 0
end

-- Get spell charges
function Cooldown:GetSpellCharges(spellId)
    local info = self:GetCooldownInfo(spellId)
    
    if info and info.maxCharges > 0 then
        return info.charges, info.maxCharges
    end
    
    -- Default to direct query if we're not tracking this spell
    local charges, maxCharges = GetSpellCharges(spellId)
    return charges or 0, maxCharges or 0
end

-- Initialize the module
Cooldown:Initialize()

return Cooldown