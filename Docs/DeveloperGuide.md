# WindrunnerRotations Developer Guide

## Introduction

This guide is intended for developers who want to contribute to WindrunnerRotations or create their own class modules. It covers the architecture, API, and best practices for developing within the WindrunnerRotations framework.

## Architecture Overview

WindrunnerRotations is built with a modular architecture to support all WoW classes and specializations. The core components are:

1. **Core Framework** - Provides API, event handling, and module management
2. **Class Modules** - Implements specific class/specialization rotations
3. **Utility Systems** - Supporting features like simulation, configuration, and performance tracking

### Directory Structure

```
WindrunnerRotations/
├── Classes/             # Class-specific modules
│   ├── DeathKnight/     # Class-specific directory
│   │   ├── Blood.lua
│   │   ├── Frost.lua
│   │   └── Unholy.lua
│   ├── Demon Hunter/
│   └── ...
├── Core/                # Core systems
│   ├── API.lua          # Core API functions
│   ├── AdvancedAbilityControl.lua
│   ├── ConfigurationRegistry.lua
│   ├── ConfigurationUI.lua
│   ├── ModuleManager.lua
│   ├── PerformanceTracker.lua
│   ├── RotationSimulator.lua
│   └── TalentLoadout.lua
├── Docs/               # Documentation
├── Media/              # Icons, textures, etc.
├── Init.lua            # Addon initialization
├── Config.lua          # Default configuration
└── WindrunnerRotations.toc  # TOC file
```

## Core API Reference

The Core API provides functions for module developers to interact with the game environment and WindrunnerRotations systems.

### API Namespaces

- `WR.API` - Core functions for rotation development
- `WR.ConfigRegistry` - Configuration system
- `WR.ModuleManager` - Module registration and management
- `WR.RotationSimulator` - Rotation simulation system
- `WR.PerformanceTracker` - Performance tracking system
- `WR.ConfigurationUI` - UI configuration system
- `WR.TalentLoadout` - Talent loadout management

### Essential API Functions

```lua
-- Player Information
API.GetPlayerClass()            -- Returns player class name
API.GetPlayerClassID()          -- Returns player class ID
API.GetActiveSpecID()           -- Returns active specialization ID
API.GetPlayerLevel()            -- Returns player level
API.GetPlayerHealthPercent()    -- Returns player health percentage

-- Target Information
API.UnitExists(unit)            -- Check if unit exists
API.IsUnitEnemy(unit)           -- Check if unit is an enemy
API.GetTargetHealthPercent()    -- Returns target health percentage
API.IsUnitInRange(unit, range)  -- Check if unit is in range

-- Combat State
API.IsPlayerInCombat()          -- Check if player is in combat
API.IsPlayerMoving()            -- Check if player is moving
API.IsFalling()                 -- Check if player is falling
API.GetCombatTime()             -- Get time in current combat

-- Spell Casting
API.CanCast(spellID)            -- Check if spell can be cast
API.CastSpell(spellID)          -- Cast spell by ID
API.CastSpellOnUnit(spellID, unit) -- Cast spell on specific unit
API.GetSpellCooldown(spellID)   -- Get spell cooldown remaining
API.IsSpellKnown(spellID)       -- Check if spell is known
API.HasBuff(unit, buffID)       -- Check if unit has buff
API.HasDebuff(unit, debuffID)   -- Check if unit has debuff
API.IsPlayerCasting()           -- Check if player is casting
API.GetSpellInfo(spellID)       -- Get spell info

-- Resource Management
API.GetPlayerManaPercentage()   -- Get player mana percentage
API.GetPowerResource(resource)  -- Get resource amount (rage, energy, etc.)
API.GetComboPoints()            -- Get current combo points
API.GetRunes()                  -- Get available runes
API.GetArcaneCharges()          -- Get arcane charges

-- Debug and Utility
API.Print(message)              -- Print message to chat
API.PrintDebug(message)         -- Print debug message
API.RegisterEvent(event, callback) -- Register event handler
API.GenerateUniqueID()          -- Generate unique ID
```

## Creating a Class Module

Each specialization requires its own module file. Here's the structure of a typical module:

```lua
local addonName, WR = ...
local SpecName = {}

-- These will be set when the file is loaded
local API
local ConfigRegistry
local AAC
local ClassName

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local stateVars = {}

-- Initialize the module
function SpecName:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("SpecName module initialized")
    return true
end

-- Register spell IDs
function SpecName:RegisterSpells()
    -- Core abilities
    spells.SPELL_NAME = 12345
    -- Register all spells with API tracking
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define buff tracking
    buffs.BUFF_NAME = spells.BUFF_ID
    
    return true
end

-- Register variables to track
function SpecName:RegisterVariables()
    -- Initialize variables
    return true
end

-- Register spec-specific settings
function SpecName:RegisterSettings()
    ConfigRegistry:RegisterSettings("SpecName", {
        -- Settings structure
    })
    return true
end

-- Register for events 
function SpecName:RegisterEvents()
    -- Register event handlers
    return true
end

-- Main rotation function
function SpecName:RunRotation()
    -- Check if we should be running this spec
    if API.GetActiveSpecID() ~= SPEC_ID then
        return false
    end
    
    -- Skip if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("SpecName")
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts(settings) then
        return true
    end
    
    -- Handle AoE vs Single Target
    if self:ShouldUseAoE(settings) then
        return self:HandleAoE(settings)
    else
        return self:HandleSingleTarget(settings)
    end
end

-- Helper functions for specific aspects of the rotation
function SpecName:HandleDefensives(settings)
    -- Implement defensive logic
    return false
end

function SpecName:HandleInterrupts(settings)
    -- Implement interrupt logic
    return false
end

function SpecName:HandleAoE(settings)
    -- Implement AoE rotation
    return false
end

function SpecName:HandleSingleTarget(settings)
    -- Implement single target rotation
    return false
end

function SpecName:OnSpecializationChanged()
    -- Handle spec change
    return true
end

-- Return the module for loading
return SpecName
```

## Best Practices

### Performance Optimization

1. **Cache Frequently Used Data**: Cache spell IDs, talent info, and other static data
2. **Minimize Function Calls**: Reduce the number of function calls, especially within tight loops
3. **Use Local Variables**: Local variables are faster than globals
4. **Optimize Condition Checks**: Order conditions to fail fast and avoid unnecessary checks

```lua
-- Good
if cheap_condition and expensive_condition then end

-- Bad
if expensive_condition and cheap_condition then end
```

### Spell Rotation Logic

1. **Prioritize Important Abilities**: Order abilities by importance, not cooldown or damage
2. **Consider Resource Management**: Balance resource generation and spending
3. **Handle Edge Cases**: Account for situations like movement, low health, etc.
4. **Use Configuration Options**: Allow users to customize important aspects

### Code Organization

1. **Modular Functions**: Split rotation logic into focused functions
2. **Consistent Naming**: Use consistent naming conventions
3. **Comment Complex Logic**: Explain non-obvious logic
4. **State Tracking**: Keep track of important state variables

## Advanced API Usage

### Advanced Ability Control

The Advanced Ability Control (AAC) system allows for complex conditions and priority handling:

```lua
-- Register ability with AAC
ConfigRegistry:RegisterSettings("SpecName", {
    abilityControls = {
        spellName = AAC.RegisterAbility(spells.SPELL_ID, {
            enabled = true,
            useDuringBurstOnly = false,
            minTargets = 3,
            healthThreshold = 50
        })
    }
})

-- Use in rotation
if settings.abilityControls.spellName.enabled and
   (activeEnemies >= settings.abilityControls.spellName.minTargets) and
   API.CanCast(spells.SPELL_ID) then
    API.CastSpell(spells.SPELL_ID)
    return true
end
```

### Configuration Registry

The Configuration Registry manages settings across the addon:

```lua
-- Register settings schema
ConfigRegistry:RegisterSettings("ModuleName", {
    categoryName = {
        settingName = {
            displayName = "User-friendly Name",
            description = "Description of the setting",
            type = "toggle", -- toggle, slider, dropdown, etc.
            default = true
        }
    }
})

-- Access settings
local settings = ConfigRegistry:GetSettings("ModuleName")
local value = settings.categoryName.settingName

-- Change setting
ConfigRegistry:SetSettingValue("ModuleName", "categoryName.settingName", newValue)
```

### Performance Tracker Integration

Integration with the Performance Tracker for detailed statistics:

```lua
-- Report ability usage
WR.PerformanceTracker:TrackAbilityUsage(spellID, success, damage)

-- Report resource usage
WR.PerformanceTracker:TrackResourceUsage(resourceType, amount)

-- Custom metrics
WR.PerformanceTracker:TrackCustomMetric("keyName", value)
```

## Testing Your Module

### Using the Simulator

1. Initialize the simulator with your module:
```lua
WR.RotationSimulator:SetupSimulationForModule(yourModule)
```

2. Run a simulation:
```lua
WR.RotationSimulator:StartSimulation(300) -- 300 second simulation
```

3. Get simulation results:
```lua
local results = WR.RotationSimulator:GetResults()
```

### Debugging

1. Use the debug print function:
```lua
API.PrintDebug("Variable value: " .. tostring(value))
```

2. Log ability usage:
```lua
API.PrintDebug("Cast " .. spellName .. ", result: " .. tostring(success))
```

3. Enable detailed logging in settings

## Contributing to WindrunnerRotations

1. **Fork the Repository**: Create your own fork on GitHub
2. **Create a Branch**: Make your changes in a feature branch
3. **Follow Coding Standards**: Adhere to the project's Lua style guide
4. **Test Thoroughly**: Test your changes on multiple specs and scenarios
5. **Submit a Pull Request**: Include detailed descriptions of your changes

## Additional Resources

- [Lua Programming Guide](https://www.lua.org/pil/contents.html)
- [World of Warcraft API Reference](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [WindrunnerRotations GitHub](https://github.com/VortexQ8/WindrunnerRotations)

## License

WindrunnerRotations is released under the MIT License. See the LICENSE file for details.