-- WindrunnerRotations Test Suite
-- Load MockAPI for testing
local MockAPI = require("Tests.MockAPI")

-- Initialize the testing environment
local WR = MockAPI.Initialize()

-- Create global function for printing test headers
function TestHeader(title)
    print("\n" .. string.rep("=", 50))
    print("TESTING: " .. title)
    print(string.rep("=", 50))
end

-- Function to load a module for testing
function LoadModule(modulePath)
    local success, result = pcall(dofile, modulePath)
    if not success then
        print("ERROR loading module:", modulePath, result)
        return false
    end
    print("Successfully loaded module:", modulePath)
    return true
end

-- Start test suite
print("\n\n")
print(string.rep("*", 60))
print("     WINDRUNNER ROTATIONS TEST SUITE")
print("     Version: " .. WR.version)
print(string.rep("*", 60))
print("\n")

-- Test the GCD Module
TestHeader("GCD Module")
if LoadModule("Core/GCD.lua") then
    -- Test initialization
    print("GCD module exists:", WR.GCD ~= nil)
    
    -- Test methods
    if WR.GCD then
        print("Testing GCD methods:")
        
        -- Test GetGCDRemaining
        if WR.GCD.GetGCDRemaining then
            print("  GCD Remaining:", WR.GCD:GetGCDRemaining())
        else
            print("  GetGCDRemaining method not found")
        end
        
        -- Test GetGCDDuration
        if WR.GCD.GetGCDDuration then
            print("  GCD Duration:", WR.GCD:GetGCDDuration())
        else
            print("  GetGCDDuration method not found")
        end
        
        -- Test CanQueueSpell
        if WR.GCD.CanQueueSpell then
            print("  Can Queue Spell:", WR.GCD:CanQueueSpell())
        else
            print("  CanQueueSpell method not found")
        end
    end
end

-- Test the SpellQueue Module
TestHeader("SpellQueue Module")
if LoadModule("Core/SpellQueue.lua") then
    -- Test initialization
    print("SpellQueue module exists:", WR.Queue ~= nil)
    
    -- Test methods
    if WR.Queue then
        print("Testing SpellQueue methods:")
        
        -- Test QueueSpell
        if WR.Queue.QueueSpell then
            print("  Queuing spell:")
            WR.Queue:QueueSpell(1449, nil, 10) -- Arcane Explosion with high priority
            print("  Queue size:", WR.Queue:GetQueueSize())
        else
            print("  QueueSpell method not found")
        end
        
        -- Test GetQueue
        if WR.Queue.GetQueue then
            print("  Queue contents:")
            local queue = WR.Queue:GetQueue()
            for i, spell in ipairs(queue) do
                local name = GetSpellInfo(spell.spellId)
                print("    " .. i .. ". " .. name .. " (ID: " .. spell.spellId .. ") - Priority: " .. (spell.priority or "N/A"))
            end
        else
            print("  GetQueue method not found")
        end
        
        -- Test CastSpell
        if WR.Queue.CastSpell then
            print("  Direct casting:")
            WR.Queue:CastSpell(30451) -- Arcane Blast
        else
            print("  CastSpell method not found")
        end
    end
end

-- Test the Condition Module
TestHeader("Condition Module")
if LoadModule("Core/Condition.lua") then
    -- Test initialization
    print("Condition module exists:", WR.Condition ~= nil)
    
    -- Test methods
    if WR.Condition then
        print("Testing Condition methods:")
        
        -- Test AND/OR functions
        if WR.Condition.AND and WR.Condition.OR then
            print("  Creating test conditions:")
            local andCondition = WR.Condition:AND("target.exists", "player.health.percent.above", 50)
            local orCondition = WR.Condition:OR("target.debuff.active", "player.buff.active")
            print("  AND condition created:", type(andCondition))
            print("  OR condition created:", type(orCondition))
        else
            print("  Composite condition methods not found")
        end
        
        -- Test RegisterCondition
        if WR.Condition.RegisterCondition then
            print("  Registering test condition:")
            WR.Condition:RegisterCondition("test.always.true", function() return true end, "Always returns true")
            print("  Condition registered")
        else
            print("  RegisterCondition method not found")
        end
    end
end

-- Test the CombatAnalysis Module
TestHeader("CombatAnalysis Module")
if LoadModule("Core/CombatAnalysis.lua") then
    -- Test initialization
    print("CombatAnalysis module exists:", WR.CombatAnalysis ~= nil)
    
    -- Test methods
    if WR.CombatAnalysis then
        print("Testing CombatAnalysis methods:")
        
        -- Test StartCombat
        if WR.CombatAnalysis.StartCombat then
            print("  Starting test combat:")
            WR.CombatAnalysis:StartCombat()
            print("  Combat started")
            
            -- Simulate some events
            if WR.CombatAnalysis.ProcessSpellCastSucceeded then
                print("  Simulating combat events:")
                WR.CombatAnalysis:ProcessSpellCastSucceeded("player", "castGUID", 1449) -- Arcane Explosion
                WR.CombatAnalysis:ProcessSpellCastSucceeded("player", "castGUID", 30451) -- Arcane Blast
                print("  Events processed")
            end
            
            -- End combat
            if WR.CombatAnalysis.EndCombat then
                print("  Ending test combat:")
                WR.CombatAnalysis:EndCombat()
                print("  Combat ended")
            end
        else
            print("  StartCombat method not found")
        end
        
        -- Test GetEfficiency
        if WR.CombatAnalysis.GetEfficiency then
            print("  Combat efficiency:", WR.CombatAnalysis:GetEfficiency())
        else
            print("  GetEfficiency method not found")
        end
        
        -- Test GetSuggestions
        if WR.CombatAnalysis.GetSuggestions then
            print("  Combat suggestions:")
            local suggestions = WR.CombatAnalysis:GetSuggestions()
            for i, suggestion in ipairs(suggestions) do
                print("    " .. i .. ". " .. suggestion.text .. " (Severity: " .. suggestion.severity .. ")")
            end
        else
            print("  GetSuggestions method not found")
        end
    end
end

-- Test completed
print("\n" .. string.rep("-", 60))
print("WINDRUNNER ROTATIONS TEST SUITE COMPLETED")
print(string.rep("-", 60) .. "\n")