local addonName, WR = ...

-- GCD module - handles the Global Cooldown tracking and prediction
local GCD = {}
WR.GCD = GCD

-- Constants
local GCD_SPELL_ID = 61304 -- Global cooldown spell ID
local DEFAULT_GCD = 1.5 -- Default GCD duration in seconds
local MIN_GCD = 0.75 -- Minimum GCD duration with haste (750ms)

-- State
local state = {
    gcdStart = 0,
    gcdDuration = 0,
    gcdEnd = 0,
    hastePercent = 0,
    lastUpdate = 0,
    updateInterval = 0.05, -- Update GCD info every 50ms
    spellQueueWindow = 0.4, -- Default spell queue window in seconds
    inCast = false,
    castEnd = 0,
    castSpellID = nil,
    castInterruptible = false,
    globalLockoutEnd = 0,
}

-- Initialize the GCD module
function GCD:Initialize()
    -- Create a frame for OnUpdate event
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        GCD:OnUpdate(elapsed)
    end)
    
    -- Register for events
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:RegisterEvent("UNIT_SPELLCAST_START")
    frame:RegisterEvent("UNIT_SPELLCAST_STOP")
    frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("UNIT_SPELL_HASTE")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            GCD:UNIT_SPELLCAST_SUCCEEDED(...)
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            GCD:SPELL_UPDATE_COOLDOWN()
        elseif event == "UNIT_SPELL_HASTE" then
            GCD:UNIT_SPELL_HASTE(...)
        elseif event:find("UNIT_SPELLCAST") then
            GCD:HandleSpellCastEvent(event, ...)
        end
    end)
    
    -- Get the spell queue window from CVar
    state.spellQueueWindow = tonumber(GetCVar("SpellQueueWindow") or "400") / 1000
    
    -- Initialize haste value
    self:UpdateHastePercent()
    
    WR:Debug("GCD module initialized")
end

-- OnUpdate handler
function GCD:OnUpdate(elapsed)
    local now = GetTime()
    
    -- Don't update too frequently
    if now - state.lastUpdate < state.updateInterval then return end
    state.lastUpdate = now
    
    -- Update GCD information
    self:UpdateGCDInfo()
    
    -- Update casting information
    self:UpdateCastInfo()
end

-- Update GCD information
function GCD:UpdateGCDInfo()
    local start, duration = GetSpellCooldown(GCD_SPELL_ID)
    
    if start and duration and duration > 0 then
        state.gcdStart = start
        state.gcdDuration = duration
        state.gcdEnd = start + duration
    else
        -- No active GCD
        state.gcdStart = 0
        state.gcdDuration = 0
        state.gcdEnd = 0
    end
end

-- Update casting information
function GCD:UpdateCastInfo()
    local name, _, _, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo("player")
    
    if name then
        state.inCast = true
        state.castEnd = endTimeMS / 1000
        state.castInterruptible = not notInterruptible
        return
    end
    
    name, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player")
    
    if name then
        state.inCast = true
        state.castEnd = endTimeMS / 1000
        state.castInterruptible = true  -- Channels are always interruptible
        return
    end
    
    -- Not casting
    state.inCast = false
    state.castEnd = 0
    state.castInterruptible = false
end

-- Handle spell cast events
function GCD:HandleSpellCastEvent(event, unit, castGUID, spellID)
    if unit ~= "player" then return end
    
    if event == "UNIT_SPELLCAST_START" then
        state.castSpellID = spellID
        self:UpdateCastInfo()
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        state.castSpellID = nil
        self:UpdateCastInfo()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        state.castSpellID = spellID
        self:UpdateCastInfo()
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        self:UpdateCastInfo()
    end
end

-- Handle spell cast success events
function GCD:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
    if unit ~= "player" then return end
    
    -- Update the GCD information
    self:UpdateGCDInfo()
    
    -- Update the global lockout timestamp
    -- This represents the earliest time the next spell can be cast
    state.globalLockoutEnd = max(state.gcdEnd, state.castEnd)
end

-- Handle cooldown update events
function GCD:SPELL_UPDATE_COOLDOWN()
    self:UpdateGCDInfo()
end

-- Handle haste update events
function GCD:UNIT_SPELL_HASTE(unit)
    if unit ~= "player" then return end
    
    self:UpdateHastePercent()
end

-- Update the player's haste percentage
function GCD:UpdateHastePercent()
    state.hastePercent = GetHaste()
end

-- Calculate the GCD for a specific spell
function GCD:GetSpellGCD(spellID)
    -- Some spells have a fixed 1 second GCD regardless of haste
    local isFixedGCD = false
    
    -- TODO: Add a list of fixed GCD spells here
    local fixedGCDSpells = {
        -- Warrior
        [100] = true, -- Charge
        [6552] = true, -- Pummel
        
        -- Many more spells...
    }
    
    if fixedGCDSpells[spellID] then
        return 1.0
    end
    
    -- Most spells are affected by haste
    local gcd = DEFAULT_GCD / (1 + state.hastePercent / 100)
    
    -- GCD can't go below 0.75 seconds
    if gcd < MIN_GCD then
        gcd = MIN_GCD
    end
    
    return gcd
end

-- Get the current GCD remaining
function GCD:GetGCDRemaining()
    local now = GetTime()
    local remaining = state.gcdEnd - now
    
    if remaining < 0 then
        remaining = 0
    end
    
    return remaining
end

-- Get the total GCD duration
function GCD:GetGCDDuration()
    return state.gcdDuration
end

-- Get the global lockout end time
function GCD:GetGlobalLockoutEnd()
    return state.globalLockoutEnd
end

-- Get the spell queue window duration
function GCD:GetSpellQueueWindow()
    return state.spellQueueWindow
end

-- Check if we can queue a new spell
function GCD:CanQueueSpell()
    local now = GetTime()
    local lockoutRemaining = state.globalLockoutEnd - now
    
    -- Can queue if the lockout is ending within the spell queue window
    return lockoutRemaining <= state.spellQueueWindow and lockoutRemaining > 0
end

-- Check if we are currently casting
function GCD:IsCasting()
    return state.inCast
end

-- Get the current cast end time
function GCD:GetCastEnd()
    return state.castEnd
end

-- Get the current cast spell ID
function GCD:GetCastSpellID()
    return state.castSpellID
end

-- Check if the current cast is interruptible
function GCD:IsCastInterruptible()
    return state.castInterruptible
end

-- Initialize the GCD module
GCD:Initialize()