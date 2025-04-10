-- Modified GCD module for testing

-- GCD module - handles the Global Cooldown tracking and prediction
local GCD = {}
_G.WR.GCD = GCD

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
    -- In test environment, we don't create frame
    print("GCD module initialized (test environment)")
    state.spellQueueWindow = 0.4
    self:UpdateHastePercent()
end

-- Update GCD information
function GCD:UpdateGCDInfo()
    -- For testing, we'll just set some default values
    state.gcdStart = 0
    state.gcdDuration = 1.5 / (1 + state.hastePercent / 100)
    state.gcdEnd = GetTime() + state.gcdDuration * 0.5 -- 50% complete
end

-- Update the player's haste percentage
function GCD:UpdateHastePercent()
    state.hastePercent = GetHaste() or 0
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
    self:UpdateGCDInfo() -- For testing, we update each time
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

-- Initialize the module
GCD:Initialize()

return GCD