local addonName, WR = ...

-- Test class rotations
print("Testing Mage class rotations")

-- Mock crucial functions if we're in test mode
if not UnitClass then
    -- Mock UnitClass to return Mage
    UnitClass = function() return "Mage", "MAGE" end
    
    -- Mock spell knowledge
    IsSpellKnown = function(spellId) return true end
    
    -- Mock specs
    GetSpecialization = function() return 1 end -- Arcane = 1, Fire = 2, Frost = 3
    GetSpecializationInfo = function(index)
        if index == 1 then return 62 -- Arcane 
        elseif index == 2 then return 63 -- Fire
        elseif index == 3 then return 64 -- Frost
        else return nil end
    end
    
    -- Mock unit existence and targeting
    UnitExists = function() return true end
    UnitIsDead = function() return false end
    UnitIsDeadOrGhost = function() return false end
    UnitCanAttack = function() return true end
    UnitHealth = function() return 80 end
    UnitHealthMax = function() return 100 end
    UnitPower = function(unit, powerType) 
        if powerType == Enum.PowerType.Mana then
            return 80 -- 80% mana
        elseif powerType == Enum.PowerType.ArcaneCharges then
            return 3 -- 3 arcane charges
        else
            return 0
        end
    end
    UnitPowerMax = function() return 100 end
    UnitAffectingCombat = function() return true end
end

-- Helper function to dump tables
local function dumptable(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep("  ", indent) .. tostring(k) .. ":")
            dumptable(v, indent + 1)
        else
            print(string.rep("  ", indent) .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

-- Load the Mage class
if WR.Classes and WR.Classes.MAGE then
    local mage = WR.Classes.MAGE
    
    -- Test each specialization
    print("--- Testing Arcane Mage ---")
    local result = mage:LoadSpec(62) -- Arcane
    if result then
        -- Print spells
        print("Arcane Mage spells:")
        for name, id in pairs(mage.spells) do
            print("  " .. name .. ": " .. id)
        end
        
        -- Test rotation logic
        print("Rotation results:")
        local spellToCast = mage:ExecuteRotation()
        if spellToCast then
            print("  Would cast: " .. GetSpellInfo(spellToCast) .. " (ID: " .. spellToCast .. ")")
        else
            print("  No spell to cast")
        end
        
        -- Test AoE rotation
        print("AoE rotation results:")
        mage.settings.useAoE = true
        -- Override GetTargetCount to simulate 4 targets
        local originalGetTargetCount = WR.Target.GetTargetCount
        WR.Target.GetTargetCount = function() return 4 end
        
        local aoeSpellToCast = mage:ExecuteRotation()
        if aoeSpellToCast then
            print("  Would cast AoE: " .. GetSpellInfo(aoeSpellToCast) .. " (ID: " .. aoeSpellToCast .. ")")
        else
            print("  No AoE spell to cast")
        end
        
        -- Restore original function
        WR.Target.GetTargetCount = originalGetTargetCount
    else
        print("  Failed to load Arcane spec")
    end
    
    print("--- Testing Fire Mage ---")
    result = mage:LoadSpec(63) -- Fire
    if result then
        print("Fire Mage spells:")
        for name, id in pairs(mage.spells) do
            print("  " .. name .. ": " .. id)
        end
        
        -- Test rotation logic
        print("Rotation results:")
        local spellToCast = mage:ExecuteRotation()
        if spellToCast then
            print("  Would cast: " .. GetSpellInfo(spellToCast) .. " (ID: " .. spellToCast .. ")")
        else
            print("  No spell to cast")
        end
    else
        print("  Failed to load Fire spec")
    end
    
    print("--- Testing Frost Mage ---")
    result = mage:LoadSpec(64) -- Frost
    if result then
        print("Frost Mage spells:")
        for name, id in pairs(mage.spells) do
            print("  " .. name .. ": " .. id)
        end
        
        -- Test rotation logic
        print("Rotation results:")
        local spellToCast = mage:ExecuteRotation()
        if spellToCast then
            print("  Would cast: " .. GetSpellInfo(spellToCast) .. " (ID: " .. spellToCast .. ")")
        else
            print("  No spell to cast")
        end
    else
        print("  Failed to load Frost spec")
    end
else
    print("Mage class module not found!")
end

print("Test completed")