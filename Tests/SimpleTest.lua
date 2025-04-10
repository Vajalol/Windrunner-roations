-- Simple test for Windrunner Rotations
-- Initialize global namespace
_G.WR = {}
WR.version = "1.0.0"
WR.debugMode = true

-- Mock Debug function
WR.Debug = function(self, ...)
    if self.debugMode then
        print("[Debug]", ...)
    end
end

-- Mock essential WoW functions
_G.GetTime = function() return os.time() end
_G.GetHaste = function() return 20 end -- 20% haste
_G.GetSpellInfo = function(spellID) 
    local spells = {
        [1449] = {"Arcane Explosion", nil, "Interface\\Icons\\Spell_Nature_WispSplode", 1.5},
        [30451] = {"Arcane Blast", nil, "Interface\\Icons\\Spell_Arcane_Blast", 2.25},
    }
    
    if spells[spellID] then
        return unpack(spells[spellID])
    else
        return "Test Spell " .. spellID, nil, nil, 1.5
    end
end

-- Mock CreateFrame function
_G.CreateFrame = function() 
    return { 
        SetScript = function() end,
        RegisterEvent = function() end,
        Show = function() end,
        Hide = function() end
    } 
end

-- Mock API for testing
WR.API = {
    CastSpell = function(spellID, target)
        print("[Cast]", GetSpellInfo(spellID), "on", target or "no target")
        return true
    end,
    IsSpellCastable = function() return true end,
    UpdateUnitCache = function() end,
    ClearUnitCache = function() end
}

-- Mock Config
WR.Config = {
    Get = function() return true end,
    Set = function() end
}

-- Function to print test headers
local function TestHeader(title)
    print("\n" .. string.rep("=", 50))
    print("TESTING: " .. title)
    print(string.rep("=", 50))
end

-- Start testing
print("\n\n")
print(string.rep("*", 60))
print("     WINDRUNNER ROTATIONS SIMPLE TEST")
print("     Version: " .. WR.version)
print(string.rep("*", 60))
print("\n")

-- Load and test GCD module
TestHeader("GCD Module")
local success, result = pcall(dofile, "Core/GCD.lua")
if success then
    print("GCD module loaded successfully")
    
    if WR.GCD then
        print("GCD Remaining:", WR.GCD:GetGCDRemaining())
        print("GCD Duration:", WR.GCD:GetGCDDuration())
        print("Can Queue Spell:", WR.GCD:CanQueueSpell())
    else
        print("ERROR: GCD module not properly initialized")
    end
else
    print("ERROR loading GCD module:", result)
end

-- Load and test SpellQueue module
TestHeader("SpellQueue Module")
success, result = pcall(dofile, "Core/SpellQueue.lua")
if success then
    print("SpellQueue module loaded successfully")
    
    if WR.Queue then
        -- Queue a test spell
        print("Queuing test spell:")
        WR.Queue:QueueSpell(1449, nil, 10) -- Arcane Explosion with priority 10
        print("Queue size:", WR.Queue:GetQueueSize())
        
        -- Process the queue
        print("Processing queue:")
        WR.Queue:ProcessQueue()
    else
        print("ERROR: SpellQueue module not properly initialized")
    end
else
    print("ERROR loading SpellQueue module:", result)
end

-- Load and test Condition module
TestHeader("Condition Module")
success, result = pcall(dofile, "Core/Condition.lua")
if success then
    print("Condition module loaded successfully")
    
    if WR.Condition then
        -- Test condition creation
        print("Creating test conditions:")
        local condition1 = WR.Condition:RegisterCondition("test.always.true", 
            function() return true end, 
            "Test condition that always returns true")
        
        -- Test composite conditions
        local andCondition = WR.Condition:AND("test.always.true", "test.always.true")
        local orCondition = WR.Condition:OR("test.always.true", "test.always.true")
        local notCondition = WR.Condition:NOT("test.always.true")
        
        print("Conditions created successfully")
    else
        print("ERROR: Condition module not properly initialized")
    end
else
    print("ERROR loading Condition module:", result)
end

-- Test completed
print("\n" .. string.rep("-", 60))
print("SIMPLE TEST COMPLETED")
print(string.rep("-", 60) .. "\n")