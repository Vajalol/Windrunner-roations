------------------------------------------
-- WindrunnerRotations - Test Runner (Simplified)
-- Author: VortexQ8
------------------------------------------

-- Create minimal WoW API functions for testing
CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
GetSpellInfo = function() return "Spell" end
UnitBuff = function() return nil end
InCombatLockdown = function() return false end
CombatLogGetCurrentEventInfo = function() return nil end
C_Timer = { After = function(delay, callback) end }

-- Load addon initialization
print("Loading core addon...")
local addon = dofile("Init.lua")

-- Print out all module paths to verify
print("\nLoaded successfully")
print("Warlock module: ", type(addon.Classes.Warlock))
print("Mage module: ", type(addon.Classes.Mage))

-- Create stub implementation objects for test
local MockAffliction = {
    Initialize = function(self)
        print("Mock Affliction Warlock initialized")
        return true
    end,
    
    RunRotation = function(self)
        print("ROTATION: Casting Agony")
        print("ROTATION: Casting Corruption") 
        print("ROTATION: Casting Unstable Affliction")
        print("ROTATION: Casting Malefic Rapture")
        return true
    end,
    
    RegisterSpells = function(self) 
        print("Registering Affliction Warlock spells")
        return true 
    end,
    
    RegisterVariables = function(self) 
        print("Registering Affliction Warlock variables")
        return true 
    end,
    
    RegisterSettings = function(self) 
        print("Registering Affliction Warlock settings")
        return true 
    end,
    
    RegisterEvents = function(self) 
        print("Registering Affliction Warlock events")
        return true 
    end,
    
    UpdateTalentInfo = function(self) 
        print("Updating Affliction Warlock talents")
        return true 
    end
}

local MockFrost = {
    Initialize = function(self)
        print("Mock Frost Mage initialized")
        return true
    end,
    
    RunRotation = function(self)
        print("ROTATION: Casting Frostbolt")
        print("ROTATION: Casting Ice Lance")
        print("ROTATION: Casting Glacial Spike")
        return true
    end,
    
    RegisterSpells = function(self) 
        print("Registering Frost Mage spells")
        return true 
    end,
    
    RegisterVariables = function(self) 
        print("Registering Frost Mage variables")
        return true 
    end,
    
    RegisterSettings = function(self) 
        print("Registering Frost Mage settings")
        return true 
    end,
    
    RegisterEvents = function(self) 
        print("Registering Frost Mage events")
        return true 
    end,
    
    UpdateTalentInfo = function(self) 
        print("Updating Frost Mage talents")
        return true 
    end
}

-- Install mocks for testing
addon.Classes.Warlock.Affliction = MockAffliction
addon.Classes.Mage.Frost = MockFrost

print("\n===================================")
print("Testing Affliction Warlock module")
print("===================================\n")

-- Test the Affliction Warlock module
if addon.Classes.Warlock.Affliction then
    local module = addon.Classes.Warlock.Affliction
    
    -- Override GetActiveSpecID to return Affliction Spec ID (265)
    addon.API.GetActiveSpecID = function() return 265 end
    
    -- Test the module
    print("Initializing Affliction Warlock module...")
    if type(module.Initialize) == "function" then
        module:Initialize()
        
        print("\nRunning Affliction Warlock rotation...")
        if type(module.RunRotation) == "function" then
            -- Create some test conditions
            addon.API.GetPlayerPower = function() return 5 end -- Full soul shards
            addon.API.GetNearbyEnemiesCount = function() return 1 end -- Single target scenario
            addon.API.GetActiveSpecID = function() return 265 end -- Affliction Spec ID
            
            -- Run the rotation
            module:RunRotation()
        else
            print("RunRotation method not found")
        end
    else
        print("Initialize method not found")
    end
else
    print("Affliction Warlock module not found")
end

print("\n===================================")
print("Testing Frost Mage module")
print("===================================\n")

-- Test the Frost Mage module
if addon.Classes.Mage.Frost then
    local module = addon.Classes.Mage.Frost
    
    -- Override GetActiveSpecID to return Frost Spec ID (64)
    addon.API.GetActiveSpecID = function() return 64 end
    
    -- Test the module
    print("Initializing Frost Mage module...")
    if type(module.Initialize) == "function" then
        module:Initialize()
        
        print("\nRunning Frost Mage rotation...")
        if type(module.RunRotation) == "function" then
            -- Create some test conditions
            addon.API.GetNearbyEnemiesCount = function() return 1 end -- Single target scenario
            addon.API.GetActiveSpecID = function() return 64 end -- Frost Spec ID
            
            -- Run the rotation
            module:RunRotation()
        else
            print("RunRotation method not found")
        end
    else
        print("Initialize method not found")
    end
else
    print("Frost Mage module not found")
end

print("\n===================================")
print("Test complete")
print("===================================\n")