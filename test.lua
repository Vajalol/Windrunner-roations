-- Test Script for Windrunner Rotations
-- Create the addon namespace first
local addonName = "WindrunnerRotations"
WR = {}
_G[addonName] = WR

-- Set basic addon info
WR.version = "1.0.0"
WR.debugMode = true

-- Mock necessary functions before loading other files
_G.UnitClass = function() return "Mage", "MAGE" end
_G.GetSpecialization = function() return 1 end
_G.GetSpecializationInfo = function() return 62 end -- Arcane Mage
_G.UnitGUID = function() return "Player-1234" end
_G.UnitName = function() return "TestPlayer" end
_G.UnitLevel = function() return 70 end
_G.GetTime = function() return os.time() end
_G.CreateFrame = function() 
    return { 
        SetScript = function() end,
        RegisterEvent = function() end,
        Show = function() end,
        Hide = function() end
    } 
end
_G.CombatLogGetCurrentEventInfo = function() 
    return 0, "SPELL_CAST_SUCCESS", nil, "Player-1234", "TestPlayer", nil, nil, nil, nil, nil, nil, 1449, "Arcane Explosion", 1 
end
_G.GetSpellInfo = function(id) 
    return "Test Spell " .. id, nil, nil, nil, nil, nil, nil 
end
_G.SlashCmdList = {}
_G.UnitExists = function() return true end
_G.UnitHealthMax = function() return 100 end

print("Mock WoW API functions initialized")

-- Create a simple print wrapper to make output more readable
local function testPrint(message)
    print("------------------------------")
    print("[TEST] " .. message)
    print("------------------------------")
end

-- Test initialization
testPrint("Windrunner Rotations Test Script")
testPrint("Version: " .. WR.version)

-- Mock necessary functions for testing
if not _G.UnitClass then
    _G.UnitClass = function() return "Mage", "MAGE" end
    _G.GetSpecialization = function() return 1 end
    _G.GetSpecializationInfo = function() return 62 end -- Arcane Mage
    _G.UnitGUID = function() return "Player-1234" end
    _G.UnitName = function() return "TestPlayer" end
    _G.UnitLevel = function() return 70 end
    _G.GetTime = function() return os.time() end
    _G.CreateFrame = function() return { 
        SetScript = function() end,
        RegisterEvent = function() end,
        Show = function() end,
        Hide = function() end
    } end
    _G.CombatLogGetCurrentEventInfo = function() return 0, "SPELL_CAST_SUCCESS", nil, "Player-1234", "TestPlayer", nil, nil, nil, nil, nil, nil, 1449, "Arcane Explosion", 1 end
    _G.GetSpellInfo = function(id) return "Test Spell " .. id, nil, nil, nil, nil, nil, nil end
    _G.SlashCmdList = {}
    
    testPrint("Mock functions created")
end

-- Enable debug mode to see detailed output
WR.debugMode = true

-- Test core systems
testPrint("Testing GCD Module")
if WR.GCD then
    print("GCD module exists")
    if WR.GCD.GetGCDRemaining then
        print("GCD Remaining: " .. WR.GCD:GetGCDRemaining())
    end
else
    print("GCD module not found")
end

testPrint("Testing SpellQueue Module")
if WR.Queue then
    print("SpellQueue module exists")
    if WR.Queue.QueueSpell then
        print("Queuing test spell")
        WR.Queue:QueueSpell(1449, nil, 10) -- Arcane Explosion with high priority
        print("Queue size: " .. WR.Queue:GetQueueSize())
    end
else
    print("SpellQueue module not found")
end

testPrint("Testing Condition Module")
if WR.Condition then
    print("Condition module exists")
    if WR.Condition.Evaluate then
        print("Creating test condition expressions")
        local andCondition = WR.Condition:AND("target.exists", "player.health.percent.above", 50)
        local orCondition = WR.Condition:OR("target.debuff.active", "player.buff.active")
        print("Condition expressions created")
    end
else
    print("Condition module not found")
end

testPrint("Testing CombatAnalysis Module")
if WR.CombatAnalysis then
    print("CombatAnalysis module exists")
    if WR.CombatAnalysis.StartCombat then
        print("Starting test combat")
        WR.CombatAnalysis:StartCombat()
        
        -- Simulate some events
        print("Simulating combat events")
        WR.CombatAnalysis:ProcessSpellCastSucceeded("player", "castGUID", 1449) -- Arcane Explosion
        
        -- End combat
        print("Ending test combat")
        WR.CombatAnalysis:EndCombat()
        print("Combat efficiency: " .. WR.CombatAnalysis:GetEfficiency())
    end
else
    print("CombatAnalysis module not found")
end

testPrint("Testing Targeting Module")
if WR.Target then
    print("Targeting module exists")
    if WR.Target.HasValidTarget then
        print("Has valid target: " .. tostring(WR.Target:HasValidTarget()))
    end
else
    print("Targeting module not found")
end

testPrint("Testing Rotation Module")
if WR.Rotation then
    print("Rotation module exists")
    if WR.Rotation.Start then
        print("Attempting to start rotation")
        local result = WR.Rotation:Start()
        print("Start result: " .. tostring(result))
    end
else
    print("Rotation module not found")
end

testPrint("Test Complete")