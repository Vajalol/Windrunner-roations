-- WindrunnerRotations Module Tests
-- Initialize global environment

-- Create WR global object
WR = {
    version = "1.0.0",
    debugMode = true,
    Debug = function(self, ...)
        if self.debugMode then
            print("[Debug]", ...)
        end
    end
}

-- Mock essential WoW functions
_G.GetTime = function() return os.time() end
_G.GetHaste = function() return 20 end -- 20% haste
_G.GetSpellInfo = function(spellID) 
    local spells = {
        [1449] = {"Arcane Explosion", nil, "Interface\\Icons\\Spell_Nature_WispSplode", 1.5},
        [30451] = {"Arcane Blast", nil, "Interface\\Icons\\Spell_Arcane_Blast", 2.25},
        [5143] = {"Arcane Missiles", nil, "Interface\\Icons\\Spell_Nature_StarFall", 2.5},
        [44425] = {"Arcane Barrage", nil, "Interface\\Icons\\Ability_Mage_ArcaneBarrage", 1.5},
        [12051] = {"Evocation", nil, "Interface\\Icons\\Spell_Nature_Purge", 6},
        [2139] = {"Counterspell", nil, "Interface\\Icons\\Spell_Frost_IceShock", 0.5},
    }
    
    if spells[spellID] then
        return unpack(spells[spellID])
    else
        return "Test Spell " .. spellID, nil, nil, 1.5
    end
end

-- Mock API for testing
WR.API = {
    CastSpell = function(spellID, target)
        print("[Cast]", GetSpellInfo(spellID), "on", target or "no target")
        return true
    end,
    IsSpellCastable = function() return true end,
    UpdateUnitCache = function() end,
    ClearUnitCache = function() end,
    UnitHealthPercent = function() return 80 end,
    UnitDistance = function() return 5 end,
    InCombat = function() return false end
}

-- Mock Config
WR.Config = {
    Get = function() return true end,
    Set = function() end
}

-- Helper functions
local function TestHeader(title)
    print("\n" .. string.rep("=", 50))
    print("TESTING: " .. title)
    print(string.rep("=", 50))
end

local function TestStep(description)
    print("\n--> " .. description)
end

-- Start test suite
print("\n\n")
print(string.rep("*", 60))
print("     WINDRUNNER ROTATIONS MODULE TESTS")
print("     Version: " .. WR.version)
print(string.rep("*", 60))
print("\n")

-- Test GCD module
TestHeader("GCD Module")
local GCD = require("Tests.TestModules.GCD")

if WR.GCD then
    TestStep("Testing GCD methods")
    print("GCD Remaining:", WR.GCD:GetGCDRemaining())
    print("GCD Duration:", WR.GCD:GetGCDDuration())
    print("Can Queue Spell:", WR.GCD:CanQueueSpell())
    print("Spell GCD for Arcane Blast:", WR.GCD:GetSpellGCD(30451))
    print("Spell GCD for Pummel:", WR.GCD:GetSpellGCD(6552))
else
    print("ERROR: GCD module not properly initialized")
end

-- Test SpellQueue module
TestHeader("SpellQueue Module")
local SpellQueue = require("Tests.TestModules.SpellQueue")

if WR.Queue then
    TestStep("Testing basic queue operations")
    -- Clear the queue first
    WR.Queue:ClearQueue()
    print("Initial Queue Size:", WR.Queue:GetQueueSize())
    
    -- Queue some spells with different priorities
    WR.Queue:QueueSpell(30451, nil, 10) -- Arcane Blast with high priority
    WR.Queue:QueueSpell(1449, nil, 5)   -- Arcane Explosion with medium priority
    WR.Queue:QueueSpell(5143, nil, 8)   -- Arcane Missiles with high-medium priority
    
    print("Queue Size After Adding Spells:", WR.Queue:GetQueueSize())
    
    TestStep("Testing queue processing")
    -- Process the queue (should cast highest priority spell - Arcane Blast)
    WR.Queue:ProcessQueue()
    
    print("Queue Size After Processing:", WR.Queue:GetQueueSize())
    
    TestStep("Testing direct casting")
    -- Test direct cast
    WR.Queue:CastSpell(12051) -- Evocation
    
    TestStep("Testing spell prediction")
    -- Test prediction
    local prediction = WR.Queue:GetCurrentPrediction()
    if prediction then
        print("Predicted next spell:", GetSpellInfo(prediction))
    else
        print("No prediction available (normal for limited history)")
    end
    
    -- Queue more spells to test patterns
    for i = 1, 10 do
        -- Alternate between a few spells to create a pattern
        if i % 3 == 0 then
            WR.Queue:CastSpell(30451) -- Arcane Blast
        elseif i % 3 == 1 then
            WR.Queue:CastSpell(5143) -- Arcane Missiles
        else
            WR.Queue:CastSpell(44425) -- Arcane Barrage
        end
    end
    
    -- Check prediction after creating pattern
    prediction = WR.Queue:GetCurrentPrediction()
    if prediction then
        print("Predicted next spell after pattern:", GetSpellInfo(prediction))
    else
        print("No prediction available")
    end
else
    print("ERROR: SpellQueue module not properly initialized")
end

-- Test Condition module
TestHeader("Condition Module")
local Condition = require("Tests.TestModules.Condition")

if WR.Condition then
    TestStep("Testing basic conditions")
    
    -- Test predefined conditions
    print("Always true condition:", WR.Condition:Evaluate("test.always.true"))
    print("Always false condition:", WR.Condition:Evaluate("test.always.false"))
    print("Compare condition (10 > 5):", WR.Condition:Evaluate("test.compare", 10, 5, ">"))
    print("Compare condition (5 == 5):", WR.Condition:Evaluate("test.compare", 5, 5, "=="))
    
    TestStep("Testing composite conditions")
    
    -- Create and evaluate composite conditions
    local andCondition = WR.Condition:AND("test.always.true", "test.always.true")
    local orCondition = WR.Condition:OR("test.always.true", "test.always.false")
    local notCondition = WR.Condition:NOT("test.always.true")
    local complexCondition = WR.Condition:AND(
        "test.always.true",
        WR.Condition:OR(
            "test.always.false",
            WR.Condition:NOT("test.always.false")
        )
    )
    
    print("AND condition (true AND true):", WR.Condition:EvaluateExpression(andCondition))
    print("OR condition (true OR false):", WR.Condition:EvaluateExpression(orCondition))
    print("NOT condition (NOT true):", WR.Condition:EvaluateExpression(notCondition))
    print("Complex condition (true AND (false OR (NOT false))):", 
          WR.Condition:EvaluateExpression(complexCondition))
    
    TestStep("Testing custom conditions")
    
    -- Register a custom condition
    WR.Condition:RegisterCustomCondition("custom.random", 
        function(threshold) 
            return math.random() > (threshold or 0.5)
        end,
        "Custom condition that returns random result based on threshold")
    
    -- Test custom condition
    print("Custom random condition (threshold 0.2):", WR.Condition:Evaluate("custom.random", 0.2))
    print("Custom random condition (threshold 0.8):", WR.Condition:Evaluate("custom.random", 0.8))
    
    -- Check evaluation count
    print("Total condition evaluations:", WR.Condition:GetEvaluationCount())
else
    print("ERROR: Condition module not properly initialized")
end

-- Integration test with all modules
TestHeader("Integration of GCD, SpellQueue, and Condition")
if WR.GCD and WR.Queue and WR.Condition then
    TestStep("Testing condition-based spell queuing")
    
    -- Clear the queue
    WR.Queue:ClearQueue()
    
    -- Create condition-based spell queue
    local conditions = {
        function() return WR.Condition:Evaluate("test.always.true") end
    }
    
    -- Queue spells with conditions
    WR.Queue:QueueSpell(30451, nil, 10, conditions) -- Arcane Blast with conditions
    WR.Queue:QueueSpell(2139, nil, 20, {
        function() return WR.Condition:Evaluate("test.always.false") end
    }) -- Counterspell with failing condition
    
    -- Process the queue - should only cast Arcane Blast
    print("Processing queue with condition-based spells:")
    WR.Queue:ProcessQueue()
    
    -- Check if we're still on GCD
    print("GCD Remaining after cast:", WR.GCD:GetGCDRemaining())
    
    -- Try to process again - should not cast anything if GCD is active
    WR.Queue:ProcessQueue()
end

-- Test completed
print("\n" .. string.rep("-", 60))
print("MODULE TESTS COMPLETED")
print(string.rep("-", 60) .. "\n")