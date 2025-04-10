local addonName, WR = ...

-- Rotation module - handles the core rotation logic
local Rotation = {}
WR.Rotation = Rotation

-- Constants
local MAX_ROTATION_FREQUENCY = 10 -- Max number of rotations per second
local MIN_ROTATION_INTERVAL = 0.01 -- Minimum interval between rotations in seconds

-- Rotation state
local state = {
    running = false,
    lastRun = 0,
    currentSpec = nil,
    rotationFunc = nil,
    updateFrame = nil,
    interval = 0.1, -- Default rotation interval (100ms)
    inCombat = false,
    preCombatActions = {},
    combatActions = {},
    postCombatActions = {},
}

-- Initialize the rotation system
function Rotation:Initialize()
    -- Create the update frame
    state.updateFrame = CreateFrame("Frame")
    state.updateFrame:Hide()
    
    -- Set up the OnUpdate script
    state.updateFrame:SetScript("OnUpdate", function(self, elapsed)
        Rotation:OnUpdate(elapsed)
    end)
    
    -- Register for combat events
    state.updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    state.updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    state.updateFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            state.inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            state.inCombat = false
        end
    end)
    
    -- Set the initial rotation interval
    self:SetRotationInterval(WR.Config:Get("rotationSpeed") / 1000)
    
    WR:Debug("Rotation system initialized")
end

-- Start the rotation
function Rotation:Start()
    if state.running then return end
    
    -- Check if we have a valid rotation function
    if not state.rotationFunc then
        WR:Debug("No rotation function available")
        return false
    end
    
    state.running = true
    state.updateFrame:Show()
    WR:Debug("Rotation started")
    
    return true
end

-- Stop the rotation
function Rotation:Stop()
    if not state.running then return end
    
    state.running = false
    state.updateFrame:Hide()
    WR:Debug("Rotation stopped")
    
    return true
end

-- Set the rotation interval
function Rotation:SetRotationInterval(seconds)
    seconds = tonumber(seconds) or 0.1
    
    -- Clamp to valid range
    if seconds < MIN_ROTATION_INTERVAL then
        seconds = MIN_ROTATION_INTERVAL
    elseif seconds > (1 / MAX_ROTATION_FREQUENCY) then
        seconds = 1 / MAX_ROTATION_FREQUENCY
    end
    
    state.interval = seconds
    WR:Debug("Rotation interval set to", seconds, "seconds")
    
    return true
end

-- Register a rotation function for a spec
function Rotation:RegisterRotationFunction(specID, func)
    if type(func) ~= "function" then
        WR:Debug("Invalid rotation function for spec", specID)
        return false
    end
    
    if specID == WR.currentSpec then
        state.rotationFunc = func
        WR:Debug("Registered rotation function for current spec", specID)
    end
    
    return true
end

-- Update the current rotation function when spec changes
function Rotation:UpdateRotationFunction(specID, func)
    if specID ~= WR.currentSpec then return false end
    
    if type(func) ~= "function" then
        WR:Debug("Invalid rotation function for spec", specID)
        return false
    end
    
    state.rotationFunc = func
    WR:Debug("Updated rotation function for spec", specID)
    
    return true
end

-- Register a pre-combat action
function Rotation:RegisterPreCombatAction(name, func)
    if type(func) ~= "function" then
        WR:Debug("Invalid pre-combat action function:", name)
        return false
    end
    
    state.preCombatActions[name] = func
    WR:Debug("Registered pre-combat action:", name)
    
    return true
end

-- Register a combat action
function Rotation:RegisterCombatAction(name, func)
    if type(func) ~= "function" then
        WR:Debug("Invalid combat action function:", name)
        return false
    end
    
    state.combatActions[name] = func
    WR:Debug("Registered combat action:", name)
    
    return true
end

-- Register a post-combat action
function Rotation:RegisterPostCombatAction(name, func)
    if type(func) ~= "function" then
        WR:Debug("Invalid post-combat action function:", name)
        return false
    end
    
    state.postCombatActions[name] = func
    WR:Debug("Registered post-combat action:", name)
    
    return true
end

-- OnUpdate handler - core rotation loop
function Rotation:OnUpdate(elapsed)
    if not state.running then return end
    
    local now = GetTime()
    if now - state.lastRun < state.interval then
        return -- Not time to run rotation yet
    end
    
    state.lastRun = now
    
    -- Update unit cache
    WR.API:UpdateUnitCache()
    
    -- Check if we're in combat
    local inCombat = WR.API:InCombat()
    
    -- Execute combat state transition if needed
    if inCombat ~= state.inCombat then
        state.inCombat = inCombat
    end
    
    -- Check if the rotation should pause
    if self:ShouldPauseRotation() then
        return
    end
    
    -- Execute the appropriate actions based on combat state
    if not inCombat then
        -- Pre-combat actions
        for name, func in pairs(state.preCombatActions) do
            if type(func) == "function" then
                local success, result = pcall(func)
                if not success then
                    WR:Debug("Error in pre-combat action", name, ":", result)
                end
            end
        end
    else
        -- Combat actions
        for name, func in pairs(state.combatActions) do
            if type(func) == "function" then
                local success, result = pcall(func)
                if not success then
                    WR:Debug("Error in combat action", name, ":", result)
                end
            end
        end
    end
    
    -- Execute the main rotation
    if state.rotationFunc then
        local success, result = pcall(state.rotationFunc, inCombat)
        if not success then
            WR:Debug("Error in rotation function:", result)
        end
    end
    
    -- Clean up unit cache
    WR.API:ClearUnitCache()
end

-- Check if the rotation should pause
function Rotation:ShouldPauseRotation()
    -- Check if player is dead
    if UnitIsDeadOrGhost("player") then
        return true
    end
    
    -- Check if player is mounted (and not in combat)
    if not WR.API:InCombat() and IsMounted() then
        return true
    end
    
    -- Check if player is eating/drinking
    local drinking = WR.API:UnitHasAura("player", "Drink")
    local eating = WR.API:UnitHasAura("player", "Food")
    if drinking or eating then
        return true
    end
    
    -- Check if player is in a cutscene
    if InCinematic() or MovieFrame:IsShown() then
        return true
    end
    
    -- Check if a dialog is open
    if StaticPopup1:IsShown() then
        return true
    end
    
    return false
end

-- Check if a specific combat action is enabled
function Rotation:IsCombatActionEnabled(name)
    -- Check global rotation enabled state
    if not WR.Config:Get("enabled") then
        return false
    end
    
    -- Check specific action types
    if name == "interrupts" then
        return WR.Config:Get("enableInterrupts")
    elseif name == "defensives" then
        return WR.Config:Get("enableDefensives")
    elseif name == "cooldowns" then
        return WR.Config:Get("enableCooldowns")
    elseif name == "aoe" then
        return WR.Config:Get("enableAOE")
    elseif name == "dungeonawareness" then
        return WR.Config:Get("enableDungeonAwareness")
    end
    
    -- Default to enabled for other actions
    return true
end

-- Get the current target's health percentage
function Rotation:GetTargetHealthPercent()
    return WR.API:UnitHealthPercent("target")
end

-- Check if there are multiple enemies nearby
function Rotation:HasMultipleEnemies(count, range)
    count = count or 2
    range = range or 8
    
    local enemyCount = 0
    local units = WR.API:GetUnits()
    
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and unit:GetDistance() <= range then
            enemyCount = enemyCount + 1
            if enemyCount >= count then
                return true
            end
        end
    end
    
    return false
end

-- Check if we should use AoE abilities
function Rotation:ShouldUseAOE()
    -- First check if AoE is enabled in settings
    if not self:IsCombatActionEnabled("aoe") then
        return false
    end
    
    -- Then check if there are multiple enemies
    return self:HasMultipleEnemies(2, 8)
end

-- Check if we should use interrupts
function Rotation:ShouldUseInterrupt()
    -- First check if interrupts are enabled in settings
    if not self:IsCombatActionEnabled("interrupts") then
        return false
    end
    
    -- Check if target is casting and can be interrupted
    local unit = WR.API:GetUnit("target")
    if unit and unit:Exists() and not unit:IsDead() and unit:IsEnemy() then
        return unit:IsCastingInterruptible()
    end
    
    return false
end

-- Check if we should use cooldowns
function Rotation:ShouldUseCooldowns()
    -- Check if cooldowns are enabled in settings
    return self:IsCombatActionEnabled("cooldowns")
end

-- Check if we should use defensive abilities
function Rotation:ShouldUseDefensives()
    -- Check if defensives are enabled in settings
    if not self:IsCombatActionEnabled("defensives") then
        return false
    end
    
    -- Check player health
    local healthPercent = WR.API:UnitHealthPercent("player")
    return healthPercent < 50
end
