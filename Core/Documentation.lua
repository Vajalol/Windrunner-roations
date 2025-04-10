local addonName, WR = ...

-- Documentation module for help and guides
local Documentation = {}
WR.Documentation = Documentation

-- Documentation categories
local CATEGORIES = {
    GETTING_STARTED = "Getting Started",
    INTERFACE = "User Interface",
    COMBAT = "Combat Rotations",
    CLASSES = "Class Guides",
    PROFILES = "Profiles & Settings",
    DUNGEONS = "Dungeon Intelligence",
    CUSTOMIZATION = "Customization",
    TROUBLESHOOTING = "Troubleshooting",
    ADVANCED = "Advanced Topics"
}

-- Documentation entries
local documentationData = {}

-- Initialize the module
function Documentation:Initialize()
    -- Create base documentation entries
    self:CreateBasicDocumentation()
    
    -- Create class-specific documentation
    self:CreateClassDocumentation()
    
    -- Create dungeon documentation
    self:CreateDungeonDocumentation()
    
    -- Create advanced documentation
    self:CreateAdvancedDocumentation()
    
    -- Create troubleshooting documentation
    self:CreateTroubleshootingDocumentation()
    
    WR:Debug("Documentation module initialized with", #self:GetAllEntries(), "entries")
end

-- Create basic documentation entries
function Documentation:CreateBasicDocumentation()
    -- Getting Started entries
    self:AddEntry({
        id = "introduction",
        title = "Introduction to Windrunner Rotations",
        category = CATEGORIES.GETTING_STARTED,
        content = [[
# Welcome to Windrunner Rotations

Windrunner Rotations is an advanced combat assistance addon for World of Warcraft that helps you maximize your performance by suggesting optimal ability usage based on your current situation, spec, talents, and environment.

## Key Features

* **Intelligent Rotations**: Advanced algorithms analyze your current situation to recommend the best abilities to use.
* **All Classes Supported**: Every class and specialization has customized rotations.
* **Dungeon Intelligence**: Special handling for dungeon mechanics and boss fights.
* **Beautiful Interface**: Clean, informative UI that shows you exactly what you need to know.
* **Customizable**: Tailor the addon to your preferences with extensive configuration options.
* **Profile System**: Save and share your settings between characters or with friends.

## Basic Usage

1. Open the main window with `/wr` or click the minimap icon.
2. Enable the rotation by clicking the "Enable" button.
3. Configure your preferences in the Settings panel.
4. Follow the suggested abilities that appear on your screen during combat.

Windrunner Rotations will now analyze your current situation and suggest abilities to use in combat. The addon works in the background, analyzing:

* Your class, spec, and talents
* Current resources and cooldowns
* Target health and debuffs
* Nearby enemies
* Dungeon and raid mechanics

## Getting Help

For additional help, see the other documentation sections or type `/wr help` in-game.
]],
        order = 1
    })
    
    self:AddEntry({
        id = "quickstart",
        title = "Quick Start Guide",
        category = CATEGORIES.GETTING_STARTED,
        content = [[
# Quick Start Guide

This guide will help you get up and running with Windrunner Rotations in just a few minutes.

## Step 1: Basic Setup

1. Type `/wr` to open the main interface
2. Click the "Enable" button to activate the rotation assistance
3. Make sure your specialization is correctly detected (shown at the top of the window)

## Step 2: Understanding the Interface

* **Main Display**: Shows the currently recommended ability
* **Queue Display**: Shows upcoming suggested abilities
* **Class HUD**: Displays class-specific resources and important buffs/debuffs
* **Settings**: Configure the addon to your preferences

## Step 3: Combat Testing

1. Find a target dummy or engage in simple combat
2. Watch the main display for ability recommendations
3. Use the recommended abilities to see how the rotation flows
4. Check how your resources are managed

## Step 4: Customization

1. Open Settings by clicking the gear icon
2. Adjust general settings like UI scale and position
3. Set class-specific options for your rotation
4. Configure dungeon-specific settings if you'll be running dungeons

## Step 5: Advanced Features

* Create and save profiles via the Profiles panel
* Enable Dungeon Intelligence for automatic mechanic handling
* Customize your UI with themes and animation options

That's it! You're ready to use Windrunner Rotations in your adventures. For more detailed information, check the other documentation sections.
]],
        order = 2
    })
    
    -- Interface entries
    self:AddEntry({
        id = "main_interface",
        title = "Main Interface",
        category = CATEGORIES.INTERFACE,
        content = [[
# Main Interface

The Windrunner Rotations main interface is designed to be intuitive and provide all the information you need at a glance.

## Main Window Components

* **Title Bar**: Shows addon name and your current spec
* **Ability Display**: The large central area showing the currently recommended ability
* **Ability Queue**: Smaller icons below showing upcoming suggested abilities
* **Status Bar**: Shows the current status and mode
* **Control Buttons**: 
  * Enable/Disable button
  * Settings button
  * Profiles button
  * Mode selection button

## Controls and Interaction

* **Dragging**: You can move the main window by clicking and dragging the title bar
* **Scaling**: Adjust the size through settings or with Shift+Mousewheel over the window
* **Keybindings**: You can set keybinds for enabling/disabling the rotation in the Key Bindings menu

## Display Modes

Windrunner Rotations offers several display modes:

* **Normal**: Standard display with all information
* **Minimal**: Reduced size showing only essential information
* **Combat Only**: Only visible during combat
* **Icon Only**: Shows only the ability icon without additional information

## Customization

The interface can be extensively customized:
* Colors and themes (including class-specific themes)
* Size and scale
* Position on screen
* Information density
* Animation effects

To access these options, click the Settings button on the main interface.
]],
        order = 1
    })
    
    self:AddEntry({
        id = "class_hud",
        title = "Class HUD",
        category = CATEGORIES.INTERFACE,
        content = [[
# Class HUD

The Class Heads-Up Display (HUD) is a specialized interface element that shows class-specific resources, cooldowns, and important buffs/debuffs.

## Key Features

* **Resource Tracking**: Displays your class resources (mana, rage, energy, etc.)
* **Cooldown Monitoring**: Shows the status of important cooldowns
* **Buff/Debuff Tracking**: Monitors crucial buffs and debuffs
* **Health Thresholds**: Indicates when defensive abilities should be used
* **Proc Alerts**: Visual notification when important abilities proc

## Class-Specific Elements

Each class has a customized HUD that displays the most relevant information:

* **Death Knight**: Runes and Runic Power
* **Demon Hunter**: Fury/Pain and special resources
* **Druid**: Forms, Combo Points, and form-specific resources
* **Evoker**: Essence and important cooldowns
* **Hunter**: Focus and pet information
* **Mage**: Arcane Charges, procs, and spell statuses
* **Monk**: Chi, Energy, and Stagger (for Brewmasters)
* **Paladin**: Holy Power and important auras
* **Priest**: Insanity (Shadow) or Holy/Discipline-specific metrics
* **Rogue**: Energy, Combo Points, and stealth status
* **Shaman**: Maelstrom and totems
* **Warlock**: Soul Shards and pet information
* **Warrior**: Rage and stance information

## Customization

The Class HUD can be customized through the Settings panel:
* Position and scale
* Display density
* Which elements to show/hide
* Color scheme
* Background transparency
]],
        order = 2
    })
    
    self:AddEntry({
        id = "settings_interface",
        title = "Settings Panel",
        category = CATEGORIES.INTERFACE,
        content = [[
# Settings Panel

The Settings Panel allows you to customize all aspects of Windrunner Rotations.

## Accessing Settings

* Click the gear icon on the main interface
* Type `/wr settings` in chat
* Use the Key Binding if you've set one

## Settings Categories

### General Settings
* UI scale and position
* Theme and visual style
* Animation effects
* Notification options
* Performance settings

### Rotation Settings
* Global cooldown (GCD) management
* Target switching behavior
* AoE thresholds
* Defensive ability usage
* Interrupt behavior

### Class Settings
* Class-specific rotation options
* Talent-specific settings
* Custom priority overrides
* Special ability usage rules

### Dungeon Settings
* Dungeon-specific behavior
* Boss encounter strategies
* Mythic+ affix handling
* Interrupt priorities

### UI Settings
* Main interface customization
* Class HUD configuration
* Tooltip information
* Combat text options

## Profiles Integration

All settings can be saved as profiles and shared between characters. Look for the "Profiles" tab to:
* Create new profiles
* Switch between existing profiles
* Import/Export profiles
* Set defaults per class or spec

## Advanced Options

The "Advanced" section contains settings for:
* Debugging tools
* Performance optimization
* Data collection settings
* Custom script integration
]],
        order = 3
    })
    
    -- Profiles entries
    self:AddEntry({
        id = "profile_system",
        title = "Profile System",
        category = CATEGORIES.PROFILES,
        content = [[
# Profile System

The Profile System allows you to save and manage different configurations for Windrunner Rotations.

## Profile Basics

Profiles store all your addon settings, including:
* UI configurations
* Rotation preferences
* Class-specific settings
* Keybindings
* Dungeon strategies

This allows you to:
* Use different setups for different content
* Share settings between characters
* Quickly switch between configurations
* Backup your settings

## Managing Profiles

### Creating a Profile
1. Open the Profile panel from the main interface
2. Click "New Profile"
3. Enter a name for your profile
4. Select which settings to include
5. Click "Create"

### Switching Profiles
1. Open the Profile panel
2. Select a profile from the list
3. Click "Activate"

### Copying Profiles
1. Select the source profile
2. Click "Copy"
3. Enter a name for the new profile
4. Click "Create"

### Deleting Profiles
1. Select the profile to delete
2. Click "Delete"
3. Confirm deletion

## Sharing Profiles

### Exporting a Profile
1. Select the profile to export
2. Click "Export"
3. A string will be generated - copy this to your clipboard
4. Share this string with others

### Importing a Profile
1. Click "Import"
2. Paste the profile string
3. Click "Import"
4. The profile will be added to your list

## Default Profiles

You can set different default profiles for:
* Each character
* Each specialization
* Different content types (PvE, PvP, M+)

To set a default:
1. Select the profile
2. Click "Set as Default"
3. Choose the default type
]],
        order = 1
    })
    
    -- Combat entries
    self:AddEntry({
        id = "combat_basics",
        title = "Combat Basics",
        category = CATEGORIES.COMBAT,
        content = [[
# Combat Basics

Understanding how Windrunner Rotations works in combat will help you get the most from the addon.

## How Ability Suggestions Work

Windrunner Rotations uses a sophisticated priority system to recommend abilities:

1. The addon constantly analyzes your situation, including:
   * Available abilities and cooldowns
   * Current resources
   * Target health and vulnerabilities
   * Number of nearby enemies
   * Dungeon/raid mechanics
   * Your talent build

2. Based on this analysis, it calculates the optimal ability to use next

3. This recommendation is displayed prominently in the main interface

4. Additional upcoming abilities are shown in the queue display

## Combat Modes

### Single Target
Optimized for fighting one enemy. Prioritizes:
* Maximum damage/healing on primary target
* Efficient resource usage
* Cooldown alignment

### AoE/Cleave
Automatically activates when multiple enemies are detected. Prioritizes:
* Area damage abilities
* Cleave effects
* Resource generation that scales with target count

### Burst Mode
Activated manually or automatically for important enemies. Prioritizes:
* Maximum burst damage/healing
* Using major cooldowns
* Sacrificing efficiency for immediate output

## Special Situations

### Movement
When you're moving, the rotation adapts to prioritize:
* Instant cast abilities
* Movement-enhancing abilities
* Resources that can be built while moving

### Low Health (You)
When your health is low, defensive recommendations are included:
* Self-healing abilities
* Damage reduction cooldowns
* Escape mechanisms

### Low Health (Target)
When a target is in execute range:
* Execute-type abilities are prioritized
* Resource spending may change

## Best Practices

* **Trust the system**: The calculations are complex and consider factors you might not immediately see
* **Be flexible**: Sometimes manual overrides are necessary for specific mechanics
* **Watch your resources**: The addon optimizes over time, which sometimes means pooling resources
* **Use cooldowns wisely**: Major cooldowns are suggested at optimal times, but you can override for specific fight timing
]],
        order = 1
    })
    
    self:AddEntry({
        id = "rotation_customization",
        title = "Customizing Rotations",
        category = CATEGORIES.COMBAT,
        content = [[
# Customizing Rotations

Windrunner Rotations allows extensive customization of combat rotations to match your playstyle.

## Basic Customization

### Priority Adjustments
In the class settings, you can adjust the priority of specific abilities:
* Increase priority to use an ability more often
* Decrease priority to use an ability less frequently
* Set to zero to exclude from rotation

### Cooldown Management
You can set how cooldowns are handled:
* Auto: The addon decides when to use cooldowns
* Manual: Cooldowns only suggested when you activate burst mode
* On Cooldown: Used as soon as available
* Pooled: Saved for specific situations

### AoE Thresholds
Set the number of targets needed before switching to AoE priority:
* Global setting affects all abilities
* Individual thresholds for specific abilities
* Can be tied to talent choices

## Advanced Customization

### Custom Conditions
For each ability, you can set custom conditions:
* Resource thresholds (only use with X amount of resource)
* Health percentage requirements (target or self)
* Buff/debuff presence requirements
* Combination conditions (AND/OR logic)

### Sequence Modifications
You can create custom action sequences:
* Forced ability chains
* Interrupt sequences
* Special opener sequences
* Defensive rotations

### Talent Integration
Rotations automatically adjust based on talents, but you can:
* Override automatic adjustments
* Create talent-specific priorities
* Disable/enable abilities based on talents

## Situation-Specific Customization

### Encounter Specific
Create customizations for specific bosses:
* Prioritize certain abilities during specific phases
* Save cooldowns for vulnerability phases
* Special interrupt handling

### Mythic+ Affixes
Adjust behavior based on current affixes:
* Custom handling for Necrotic, Bolstering, etc.
* Different AoE thresholds per affix
* Specialized defensive usage

## Saving and Sharing Customizations

All customizations can be saved in profiles:
* Export your custom setups to share
* Import optimized community rotations
* Create different profiles for different content

## Testing Customizations

Use the built-in simulation feature to test your changes:
* Compare DPS between different setups
* Visualize resource usage
* Identify potential issues before actual combat
]],
        order = 2
    })
    
    -- Customization entries
    self:AddEntry({
        id = "visual_customization",
        title = "Visual Customization",
        category = CATEGORIES.CUSTOMIZATION,
        content = [[
# Visual Customization

Windrunner Rotations offers extensive visual customization options to match your UI preferences.

## Theme Settings

### Color Themes
* **Class Colored**: Uses your class color as the primary theme color
* **Dark**: Dark background with light text
* **Light**: Light background with dark text
* **Minimal**: Transparent backgrounds with subtle highlighting
* **Vibrant**: High contrast and saturated colors

### Theme Intensity
Use the intensity slider to control how pronounced the theme colors are:
* Lower values create a more subtle look
* Higher values create a more distinctive appearance

### Custom Colors
You can customize individual UI elements:
* Backgrounds
* Borders
* Text
* Icons
* Highlights

## Layout Options

### Main Frame
* Adjustable size and scale
* Movable to any screen position
* Collapsible sections
* Rotation of elements (vertical or horizontal)

### Class HUD
* Multiple layout templates
* Adjustable opacity
* Show/hide individual elements
* Resource bar customization

### Ability Display
* Icon size and spacing
* Font styles and sizes
* Cooldown text display options
* Border styles

## Animation Settings

The AnimationSystem module provides numerous customization options:

### Ability Animations
* Proc highlighting effects
* Cooldown completion animations
* Recommended ability emphasis
* Queue transitions

### Transition Effects
* Panel sliding effects
* Fade transitions
* Scale effects
* Bounce and pulse options

### Performance Settings
* Animation density (low to high)
* Disable animations in combat
* Reduced animation mode for older computers

## Responsive Layout

The UI can adapt to different screen resolutions:
* Automatically resizes for your screen
* Custom scaling per resolution
* Alternative layouts for small screens
* Position memory for multiple monitor setups

## Accessibility Options

* High contrast mode
* Enlarged text option
* Extra visual cues
* Colorblind-friendly palette options

## Presets and Sharing

* Save visual setups as part of profiles
* Quick-switch between visual presets
* Export/import visual settings separately
* Reset to defaults option
]],
        order = 1
    })
}

-- Create class documentation
function Documentation:CreateClassDocumentation()
    -- Class documentation structure
    local classes = {
        {
            id = "deathknight",
            name = "Death Knight",
            specs = {
                {id = "blood", name = "Blood", role = "Tank"},
                {id = "frost", name = "Frost", role = "DPS"},
                {id = "unholy", name = "Unholy", role = "DPS"}
            }
        },
        {
            id = "demonhunter",
            name = "Demon Hunter",
            specs = {
                {id = "havoc", name = "Havoc", role = "DPS"},
                {id = "vengeance", name = "Vengeance", role = "Tank"}
            }
        },
        {
            id = "druid",
            name = "Druid",
            specs = {
                {id = "balance", name = "Balance", role = "DPS"},
                {id = "feral", name = "Feral", role = "DPS"},
                {id = "guardian", name = "Guardian", role = "Tank"},
                {id = "restoration", name = "Restoration", role = "Healer"}
            }
        },
        {
            id = "evoker",
            name = "Evoker",
            specs = {
                {id = "devastation", name = "Devastation", role = "DPS"},
                {id = "preservation", name = "Preservation", role = "Healer"},
                {id = "augmentation", name = "Augmentation", role = "DPS"}
            }
        },
        {
            id = "hunter",
            name = "Hunter",
            specs = {
                {id = "beastmastery", name = "Beast Mastery", role = "DPS"},
                {id = "marksmanship", name = "Marksmanship", role = "DPS"},
                {id = "survival", name = "Survival", role = "DPS"}
            }
        },
        {
            id = "mage",
            name = "Mage",
            specs = {
                {id = "arcane", name = "Arcane", role = "DPS"},
                {id = "fire", name = "Fire", role = "DPS"},
                {id = "frost", name = "Frost", role = "DPS"}
            }
        },
        {
            id = "monk",
            name = "Monk",
            specs = {
                {id = "brewmaster", name = "Brewmaster", role = "Tank"},
                {id = "mistweaver", name = "Mistweaver", role = "Healer"},
                {id = "windwalker", name = "Windwalker", role = "DPS"}
            }
        },
        {
            id = "paladin",
            name = "Paladin",
            specs = {
                {id = "holy", name = "Holy", role = "Healer"},
                {id = "protection", name = "Protection", role = "Tank"},
                {id = "retribution", name = "Retribution", role = "DPS"}
            }
        },
        {
            id = "priest",
            name = "Priest",
            specs = {
                {id = "discipline", name = "Discipline", role = "Healer"},
                {id = "holy", name = "Holy", role = "Healer"},
                {id = "shadow", name = "Shadow", role = "DPS"}
            }
        },
        {
            id = "rogue",
            name = "Rogue",
            specs = {
                {id = "assassination", name = "Assassination", role = "DPS"},
                {id = "outlaw", name = "Outlaw", role = "DPS"},
                {id = "subtlety", name = "Subtlety", role = "DPS"}
            }
        },
        {
            id = "shaman",
            name = "Shaman",
            specs = {
                {id = "elemental", name = "Elemental", role = "DPS"},
                {id = "enhancement", name = "Enhancement", role = "DPS"},
                {id = "restoration", name = "Restoration", role = "Healer"}
            }
        },
        {
            id = "warlock",
            name = "Warlock",
            specs = {
                {id = "affliction", name = "Affliction", role = "DPS"},
                {id = "demonology", name = "Demonology", role = "DPS"},
                {id = "destruction", name = "Destruction", role = "DPS"}
            }
        },
        {
            id = "warrior",
            name = "Warrior",
            specs = {
                {id = "arms", name = "Arms", role = "DPS"},
                {id = "fury", name = "Fury", role = "DPS"},
                {id = "protection", name = "Protection", role = "Tank"}
            }
        }
    }
    
    -- Create class overview entries
    for _, class in ipairs(classes) do
        -- Create class overview
        self:AddEntry({
            id = class.id .. "_overview",
            title = class.name .. " Overview",
            category = CATEGORIES.CLASSES,
            content = string.format([[
# %s Overview

This guide covers the key features and specializations of the %s class in Windrunner Rotations.

## Specializations

%s offers %d specializations:

%s

## Class-Specific Features

### Resources
%s

### Key Abilities
%s

### Recommended Settings
%s

## Getting Started

1. Ensure you have the correct specialization selected
2. Review your talents in-game to match the expected build
3. Configure any class-specific settings in the Settings panel
4. Review the specialization-specific documentation for detailed guidance

For specific guidance on each specialization, see the dedicated pages linked above.
            ]], 
            class.name, 
            class.name,
            class.name, 
            #class.specs,
            self:FormatSpecList(class.specs),
            self:GetClassResourceText(class.id),
            self:GetClassKeyAbilitiesText(class.id),
            self:GetClassRecommendedSettingsText(class.id)
            ),
            related = self:GetSpecIds(class.specs),
            order = 1
        })
        
        -- Create spec guides
        for _, spec in ipairs(class.specs) do
            self:AddEntry({
                id = class.id .. "_" .. spec.id,
                title = spec.name .. " " .. class.name,
                category = CATEGORIES.CLASSES,
                content = string.format([[
# %s %s Guide

This guide covers how to effectively use Windrunner Rotations with a %s %s in World of Warcraft.

## Role: %s

%s %s specializes in %s.

## Rotation Priorities

### Single Target
%s

### Multiple Targets (AoE)
%s

### Cooldown Usage
%s

## Important Abilities to Track

%s

## Tips and Tricks

%s

## Talent Build Considerations

%s

## Custom Settings

%s

## Common Issues

%s
                ]], 
                spec.name, 
                class.name,
                spec.name, 
                class.name,
                spec.role,
                spec.name,
                class.name,
                self:GetSpecRoleDescription(spec.role),
                self:GetSpecSingleTargetRotation(class.id, spec.id),
                self:GetSpecAoERotation(class.id, spec.id),
                self:GetSpecCooldownUsage(class.id, spec.id),
                self:GetSpecImportantAbilities(class.id, spec.id),
                self:GetSpecTipsAndTricks(class.id, spec.id),
                self:GetSpecTalentConsiderations(class.id, spec.id),
                self:GetSpecCustomSettings(class.id, spec.id),
                self:GetSpecCommonIssues(class.id, spec.id)
                ),
                related = {class.id .. "_overview"},
                order = 2
            })
        end
    end
end

-- Create dungeon documentation
function Documentation:CreateDungeonDocumentation()
    -- Placeholder for dungeon documentation
    self:AddEntry({
        id = "dungeon_intelligence_overview",
        title = "Dungeon Intelligence Overview",
        category = CATEGORIES.DUNGEONS,
        content = [[
# Dungeon Intelligence Overview

Windrunner Rotations includes a powerful Dungeon Intelligence system that adapts your rotation for specific dungeon mechanics and boss encounters.

## Key Features

* **Boss Awareness**: Adapts rotations for specific boss mechanics
* **Affix Handling**: Special handling for Mythic+ affixes
* **Phase Detection**: Recognizes boss phases and adjusts priorities
* **Interrupt Priorities**: Smart interrupt handling for important abilities
* **Defensive Recommendations**: Suggests defensive cooldowns for dangerous abilities
* **Mechanic Avoidance**: Prioritizes movement abilities during relevant mechanics

## How It Works

The Dungeon Intelligence system works by:

1. Detecting your current dungeon and boss encounter
2. Monitoring combat events for specific boss abilities and phases
3. Adjusting ability priorities based on the current situation
4. Providing special recommendations for mechanics

This happens automatically in the background, seamlessly integrating with the normal rotation.

## Configuration Options

You can customize how the Dungeon Intelligence system works:

* **Enable/Disable**: Turn the system on or off
* **Interrupt Handling**: Configure how interrupts are prioritized
* **Defensives**: Set health thresholds for defensive recommendations
* **Boss-Specific Settings**: Special options for certain encounters
* **Affix Sensitivity**: How much to adapt for different affixes

## Current Dungeon Coverage

Windrunner Rotations includes data for all current dungeons in the Mythic+ rotation, with detailed handling for:

* **Dawn of the Infinite**
* **Atal'Dazar**
* **Waycrest Manor**
* **Black Rook Hold**
* **The Everbloom**
* **Darkheart Thicket**
* **Throne of the Tides**
* **Blackroot Hold**

Each dungeon has customized handling for all boss encounters and important trash packs.

## Mythic+ Affix Support

Special handling is included for all Mythic+ affixes:

* **Seasonal Affixes**: Comprehensive support for current seasonal mechanics
* **Weekly Affixes**: Adaptation for all rotating affixes
* **Fortified/Tyrannical**: Different priorities based on the base affix

For detailed information on specific dungeons, see the individual dungeon guides.
]],
        order = 1
    })
    
    -- Add a dungeon-specific entry example
    self:AddEntry({
        id = "dawn_of_the_infinite",
        title = "Dawn of the Infinite",
        category = CATEGORIES.DUNGEONS,
        content = [[
# Dawn of the Infinite

Dawn of the Infinite is a complexed dungeon featuring time-based mechanics and multiple phases for each boss. This guide covers how Windrunner Rotations helps you navigate this dungeon.

## Chronoweaver Deios

### Phase 1: Timestream Leech
* Priority on interrupting **Infinite Bolt**
* Defensive recommendations during **Chroniclysm**
* Movement ability suggestions for **Time Sink**

### Phase 2: Temporal Collision
* AoE priority adjustments for adds
* Cooldown recommendations for burst phases
* Special handling of **Temporal Scar** debuff

## Manifested Timeways

### Important Mechanics
* Interrupt priority for **Time Beam**
* Defensive recommendations for **Temporal Strike**
* Movement priority during **Chrono Blast**

### Special Recommendations
* Burst cooldown timing for vulnerability phases
* Resource pooling before phase transitions
* AoE threshold adjustments based on add count

## Blight of Galakrond

### Phase Management
* Cooldown conservation during immune phases
* Priority targets during add spawns
* Special handling of **Corrupted Essence** debuff

### Trash Strategies
* Priority interrupts for dangerous casters
* Defensive recommendations for high-damage packs
* Cooldown usage optimization for efficient clearing

## Mythic+ Considerations

### Timer Optimization
* Cooldown planning for important pulls
* Suggested route waypoints
* Resource management between pulls

### Affix-Specific Adjustments
* **Sanguine**: Movement suggestions to avoid healing pools
* **Spiteful**: Target switching recommendations for shades
* **Storming**: Movement ability priorities during storms

For more detailed strategies on each boss and trash pack, use the in-game dungeon notes feature by typing `/wr dungeon notes`.
]],
        order = 2
    })
}

-- Create advanced documentation
function Documentation:CreateAdvancedDocumentation()
    -- Advanced documentation entries
    self:AddEntry({
        id = "advanced_customization",
        title = "Advanced Customization",
        category = CATEGORIES.ADVANCED,
        content = [[
# Advanced Customization

This guide covers advanced customization options for power users who want to tailor Windrunner Rotations to their exact specifications.

## Custom Action Sequences

You can create custom action sequences that override the normal priority system:

```lua
WR.CustomSequence = {
    {spellID = 12345, condition = "target.debuff(12345).remains < 3"},
    {spellID = 67890, condition = "player.buff(67890).down"},
    {spellID = 54321, condition = "player.resource > 80"}
}
```

These sequences can be:
* Permanently active
* Triggered by certain conditions
* Activated via keybinding
* Tied to specific encounters

## API Integration

Advanced users can access the Windrunner Rotations API:

```lua
-- Get the next recommended ability
local nextAbility = WR.API.GetNextAction()

-- Check if an ability is castable
local canCast = WR.API.CanCast(spellID)

-- Get cooldown information
local start, duration = WR.API.GetCooldown(spellID)

-- Access target information
local targetHealth = WR.API.UnitHP("target")
```

## Custom Condition Language

Create complex conditions using the built-in condition language:

```lua
-- Complex condition examples
"player.buff(12345).up & target.debuff(67890).remains < 3 & player.resource > 60"
"target.adds.count >= 3 & player.cooldown(12345).ready & !player.moving"
"target.health.pct < 30 | player.buff(12345).stack >= 3"
```

## Performance Tuning

Adjust how the engine operates:

* **Update Frequency**: How often rotations are calculated
* **Prediction Depth**: How far ahead to calculate
* **Simulation Intensity**: How detailed simulations should be
* **Cache Behavior**: How aggressively to cache results

## Advanced Profile Management

* Merge profiles selectively
* Schedule profile switches
* Create conditional profiles
* Develop meta-profiles

## Custom UI Frameworks

* Build entirely custom displays
* Integrate with other addons like WeakAuras
* Create specialized HUDs for specific content
* Develop audio cue systems

## Data Collection and Analysis

* Enable detailed performance tracking
* Export combat logs with rotation data
* Compare theoretical vs. actual performance
* Identify areas for improvement

## External Tool Integration

* Export settings to simulation tools
* Import optimized action priorities
* Synchronize with raid leadership tools
* Connect to community resources

Please note that some advanced features may require editing configuration files directly. Always back up your settings before making advanced changes.
]],
        order = 1
    })
}

-- Create troubleshooting documentation
function Documentation:CreateTroubleshootingDocumentation()
    -- Troubleshooting entries
    self:AddEntry({
        id = "common_issues",
        title = "Common Issues",
        category = CATEGORIES.TROUBLESHOOTING,
        content = [[
# Common Issues and Solutions

This guide helps you troubleshoot common issues with Windrunner Rotations.

## Rotation Not Working

### Symptoms
* No abilities are suggested
* The addon seems unresponsive
* Incorrect abilities are suggested

### Solutions
1. Check if the addon is enabled via `/wr toggle`
2. Verify that the correct specialization is detected
3. Make sure your talents match one of the supported builds
4. Reset the addon settings with `/wr reset`
5. Check for conflicts with other rotation addons

## Performance Issues

### Symptoms
* Frame rate drops when using the addon
* UI lag during combat
* Delayed ability suggestions

### Solutions
1. Reduce animation effects in settings
2. Lower the update frequency in advanced settings
3. Disable dungeon intelligence if not needed
4. Reduce the number of tracked auras
5. Use the optimization tool via `/wr optimize`

## UI Display Problems

### Symptoms
* UI elements are misaligned
* Text or icons are missing
* UI disappears during combat

### Solutions
1. Reset UI positions with `/wr resetui`
2. Check your UI scale settings
3. Verify that required media files are present
4. Disable other addons that might conflict
5. Restore default theme settings

## Incorrect Ability Suggestions

### Symptoms
* Suggestions don't match expected priority
* Critical abilities are missing
* Suggestions don't adapt to situation

### Solutions
1. Check your rotation customization settings
2. Verify talent compatibility
3. Reset class-specific settings
4. Make sure you have the latest version
5. Review class-specific documentation

## Profile Issues

### Symptoms
* Unable to save profiles
* Profiles not loading correctly
* Settings not saved between sessions

### Solutions
1. Repair your saved variables file
2. Use the profile recovery tool
3. Export your profile as backup
4. Reset profile system with `/wr resetprofiles`
5. Check account permissions for saving files

## Addon Conflicts

### Symptoms
* Error messages mentioning other addons
* Inconsistent behavior with certain addons
* Features stop working with specific addon combinations

### Solutions
1. Use the diagnostic tool to identify conflicts
2. Try disabling potential conflicting addons
3. Load Windrunner Rotations earlier in the load order
4. Check for shared libraries or frameworks
5. Update all addons to latest versions

## Diagnostic Tools

If you continue experiencing issues, use our built-in diagnostic tools:

1. Enable debugging mode: `/wr debug on`
2. Run diagnostics scan: `/wr diagnose`
3. Check error log: `/wr errors`
4. Generate diagnostic report: `/wr report`

If you need to contact support, include your diagnostic report for faster assistance.
]],
        order = 1
    })
    
    self:AddEntry({
        id = "diagnostic_tools",
        title = "Diagnostic Tools",
        category = CATEGORIES.TROUBLESHOOTING,
        content = [[
# Diagnostic Tools

Windrunner Rotations includes several diagnostic tools to help identify and fix issues.

## Basic Diagnostics

### Error Checking
Run a basic diagnostic scan to identify common issues:
```
/wr diagnose
```

This will check for:
* Missing files or components
* Configuration errors
* Addon conflicts
* Performance issues
* Database integrity

### Error Log
View recent errors and warnings:
```
/wr errors
```

This displays:
* Lua errors
* Warning messages
* System notifications
* Recent issues

### System Information
Generate a system report:
```
/wr sysinfo
```

This includes:
* WoW version and build
* Addon version
* System specifications
* Performance metrics
* Loaded modules

## Advanced Diagnostics

### Debug Mode
Enable debug logging for detailed information:
```
/wr debug on
```

This will:
* Output detailed logs to chat
* Track function calls
* Monitor performance
* Log decision-making process

Remember to turn it off when finished:
```
/wr debug off
```

### Performance Analysis
Run performance diagnostics:
```
/wr benchmark
```

This tests:
* Update frequency capabilities
* Memory usage
* CPU utilization
* Network impact

### Database Repair
Repair database issues:
```
/wr repair
```

This will:
* Check for database corruption
* Fix inconsistencies
* Restore missing defaults
* Optimize storage

## Reporting Issues

When reporting issues to developers, include:

1. **Diagnostic Report**
   Generate with `/wr report`

2. **Steps to Reproduce**
   Detailed steps to recreate the issue

3. **Environment Information**
   WoW version, other addons, etc.

4. **Screenshots or Videos**
   Visual evidence if applicable

5. **Recent Changes**
   Any changes made before the issue appeared

## Self-Repair Tools

### Reset Settings
Reset to default settings:
```
/wr reset
```

### Reset UI
Reset UI positions and scaling:
```
/wr resetui
```

### Rebuild Database
Completely rebuild the database:
```
/wr rebuild
```
Warning: This will delete all saved settings

### Clean Cache
Clear cached data:
```
/wr clearcache
```

### Profile Recovery
Recover from backup profiles:
```
/wr recoverprofiles
```

These tools should resolve most common issues. If problems persist, check our documentation or contact support.
]],
        order = 2
    })
}

-- Utility functions for generating documentation

-- Format a list of specs as Markdown
function Documentation:FormatSpecList(specs)
    local lines = {}
    for _, spec in ipairs(specs) do
        table.insert(lines, string.format("* **[%s](%s_%s)** - %s", spec.name, spec.id, "specialization", spec.role))
    end
    return table.concat(lines, "\n")
end

-- Get spec IDs for related entries
function Documentation:GetSpecIds(specs)
    local ids = {}
    for _, spec in ipairs(specs) do
        table.insert(ids, spec.id .. "_specialization")
    end
    return ids
end

-- Get class resource text
function Documentation:GetClassResourceText(classId)
    local resources = {
        deathknight = "Death Knights use **Runes** and **Runic Power** as their primary resources. The rotation optimizes rune usage and runic power generation/spending.",
        demonhunter = "Demon Hunters use **Fury** (Havoc) or **Pain** (Vengeance) as their primary resource. The rotation optimizes resource generation and spending phases.",
        druid = "Druids use different resources based on specialization: **Mana** (Balance/Restoration), **Energy and Combo Points** (Feral), or **Rage** (Guardian). The rotation handles form switching and resource management.",
        evoker = "Evokers use **Mana** and **Essence** as their primary resources. The rotation optimizes essence generation and spending while managing mana efficiency.",
        hunter = "Hunters use **Focus** as their primary resource. The rotation balances focus generation and spending for optimal output.",
        mage = "Mages primarily use **Mana** along with spec-specific resources like **Arcane Charges**. The rotation optimizes mana efficiency and secondary resource management.",
        monk = "Monks use **Energy** and **Chi** as their primary resources (Brewmaster/Windwalker) or **Mana** (Mistweaver). The rotation optimizes the conversion of energy to chi and chi spending.",
        paladin = "Paladins use **Mana** (Holy) or **Holy Power** (Protection/Retribution) as their primary resource. The rotation optimizes holy power generation and spending.",
        priest = "Priests use **Mana** (Holy/Discipline) or **Insanity** (Shadow) as their primary resource. The rotation optimizes resource management for each specialization.",
        rogue = "Rogues use **Energy** and **Combo Points** as their primary resources. The rotation optimizes the energy-to-combo-point conversion and finisher usage.",
        shaman = "Shamans use **Mana** (Restoration) or **Maelstrom** (Elemental/Enhancement) as their primary resource. The rotation optimizes resource generation and spending.",
        warlock = "Warlocks use **Mana** and **Soul Shards** as their primary resources. The rotation optimizes soul shard generation and spending while managing mana.",
        warrior = "Warriors use **Rage** as their primary resource. The rotation optimizes rage generation and spending for maximum efficiency."
    }
    
    return resources[classId] or "This class uses multiple resources that are managed by the rotation system."
end

-- Get class key abilities text
function Documentation:GetClassKeyAbilitiesText(classId)
    local abilities = {
        deathknight = "The rotation tracks Rune cooldowns, Death Knight presence, and important procs like Killing Machine and Crimson Scourge.",
        demonhunter = "The rotation manages Demon Hunter procs, Metamorphosis windows, and defensive abilities like Demon Spikes.",
        druid = "The rotation handles shapeshifting, tracks DoT durations, and manages Eclipse cycles for Balance and combo point finishers for Feral.",
        evoker = "The rotation manages Evoker's empowered abilities, tracks important buffs like Blessing of the Bronze, and optimizes essence usage.",
        hunter = "The rotation manages pet abilities, tracks Focus regeneration, and optimizes damage windows for abilities like Trueshot.",
        mage = "The rotation manages procs like Hot Streak and Fingers of Frost, tracks Arcane Charges, and optimizes burst windows for cooldowns.",
        monk = "The rotation tracks Brew charges, manages Chi generation and spending, and ensures optimal usage of abilities like Blackout Kick.",
        paladin = "The rotation tracks Holy Power generation, manages important buffs like Avenging Wrath, and ensures optimal usage of defensive abilities.",
        priest = "The rotation manages Shadow Priest's Voidform cycles, tracks DoT durations, and optimizes Atonement healing for Discipline.",
        rogue = "The rotation tracks combo points, manages energy pooling, and optimizes usage of core abilities like Roll the Bones and Shadow Dance.",
        shaman = "The rotation manages Maelstrom spending, tracks important procs like Lava Surge, and ensures optimal usage of totems.",
        warlock = "The rotation tracks DoT durations, manages Soul Shard generation, and optimizes usage of pet abilities and cooldowns.",
        warrior = "The rotation manages rage generation, tracks procs like Sudden Death, and ensures optimal usage of abilities like Shield Block and Execute."
    }
    
    return abilities[classId] or "The rotation system tracks cooldowns, resources, and procs specific to this class."
end

-- Get class recommended settings text
function Documentation:GetClassRecommendedSettingsText(classId)
    local settings = {
        deathknight = "For Death Knights, we recommend adjusting the Rune tracking display, configuring defensive thresholds, and setting up anti-magic zone usage for raid content.",
        demonhunter = "For Demon Hunters, we recommend customizing Demon Spikes thresholds, configuring Sigil placement preferences, and adjusting resource display options.",
        druid = "For Druids, we recommend setting up form-shifting preferences, configuring Convoke targets, and adjusting defensive cooldown thresholds for each form.",
        evoker = "For Evokers, we recommend customizing the Essence display, setting up Empowered ability preferences, and configuring defensive usage thresholds.",
        hunter = "For Hunters, we recommend configuring pet management settings, adjusting Aspect switching behavior, and setting up trap usage preferences.",
        mage = "For Mages, we recommend customizing the proc display, configuring Blink/Shimmer behavior, and setting up defensive cooldown automation.",
        monk = "For Monks, we recommend adjusting Stagger level display, configuring Roll/Chi Torpedo usage, and setting up defensive brew thresholds.",
        paladin = "For Paladins, we recommend configuring blessing targets, adjusting defensive cooldown thresholds, and setting up Holy Power usage preferences.",
        priest = "For Priests, we recommend setting up Voidform preferences, configuring barrier/Pain Suppression thresholds, and adjusting Power Word: Shield priorities.",
        rogue = "For Rogues, we recommend customizing stealth behavior, configuring Vanish usage, and setting up interrupt priorities for Kick.",
        shaman = "For Shamans, we recommend adjusting totem placement preferences, configuring Spirit Link usage, and setting up Earth/Wind/Fire Elemental automation.",
        warlock = "For Warlocks, we recommend configuring pet selection preferences, adjusting Soul Shard usage priorities, and setting up healthstone thresholds.",
        warrior = "For Warriors, we recommend customizing rage threshold displays, configuring charge behavior, and setting up defensive cooldown automation."
    }
    
    return settings[classId] or "We recommend reviewing the class-specific settings panel for options that match your playstyle and preferences."
end

-- Get spec role description
function Documentation:GetSpecRoleDescription(role)
    local descriptions = {
        Tank = "damage mitigation and threat generation, ensuring enemies are focused on you while maintaining survivability",
        DPS = "dealing maximum damage to enemies, using cooldowns effectively, and adapting to fight mechanics",
        Healer = "keeping the group alive through efficient healing, using cooldowns at appropriate times, and contributing to damage when possible"
    }
    
    return descriptions[role] or "performing its role efficiently in group content"
end

-- Get single target rotation text
function Documentation:GetSpecSingleTargetRotation(classId, specId)
    -- This would be tailored to each spec
    return "The single target rotation follows a priority system that adapts to your current resources, cooldowns, and target state. Key principles include maintaining important buffs/debuffs, using core abilities on cooldown, and spending resources efficiently."
end

-- Get AOE rotation text
function Documentation:GetSpecAoERotation(classId, specId)
    -- This would be tailored to each spec
    return "The AoE rotation automatically activates when multiple targets are detected. It prioritizes abilities that hit multiple targets, cleave effects, and efficient resource generation that scales with target count."
end

-- Get cooldown usage text
function Documentation:GetSpecCooldownUsage(classId, specId)
    -- This would be tailored to each spec
    return "Major cooldowns are used at optimal times based on the encounter. You can configure whether cooldowns are used automatically or manually activated. The rotation will suggest the best time to use major cooldowns based on fight phase, target health, and your resources."
end

-- Get important abilities text
function Documentation:GetSpecImportantAbilities(classId, specId)
    -- This would be tailored to each spec
    return "The rotation tracks several important abilities and status effects:\n\n* Core rotational abilities and their cooldowns\n* Resource generators and spenders\n* Defensive cooldowns and their optimal usage times\n* Procs and reactive abilities\n* Movement abilities for mechanics"
end

-- Get tips and tricks text
function Documentation:GetSpecTipsAndTricks(classId, specId)
    -- This would be tailored to each spec
    return "To get the most out of this specialization:\n\n* Pay attention to resource pooling suggestions before burst phases\n* Configure defensive thresholds based on your gear level\n* Use manual override for certain abilities in specific situations\n* Adjust AoE thresholds based on your talent build\n* Take advantage of the custom conditions for certain abilities"
end

-- Get talent considerations text
function Documentation:GetSpecTalentConsiderations(classId, specId)
    -- This would be tailored to each spec
    return "The rotation automatically adapts to your talent choices, but some talents have a bigger impact on the rotation than others:\n\n* Certain talents may change resource generation/spending patterns\n* Some talents add new abilities that are integrated into the priority\n* Passive talents are accounted for in damage/healing calculations\n* Talent synergies are considered for optimal ability ordering"
end

-- Get custom settings text
function Documentation:GetSpecCustomSettings(classId, specId)
    -- This would be tailored to each spec
    return "In the Settings panel, look for specialization-specific options:\n\n* Resource thresholds for key abilities\n* Cooldown management preferences\n* AoE target count thresholds\n* Defensive ability automation\n* Utility ability configuration"
end

-- Get common issues text
function Documentation:GetSpecCommonIssues(classId, specId)
    -- This would be tailored to each spec
    return "Some common issues with this specialization:\n\n* Ensure your talents match a supported build for optimal recommendations\n* Adjust resource thresholds if you notice over-capping\n* Configure defensive cooldown thresholds based on content difficulty\n* For certain talent builds, manually adjust priority of specific abilities\n* Check rotation mode settings for single target vs. multi-target content"
end

-- Add a documentation entry
function Documentation:AddEntry(entry)
    if not entry or not entry.id or not entry.title or not entry.category then
        WR:Debug("Invalid documentation entry")
        return
    end
    
    -- Check if entry already exists
    for i, existing in ipairs(documentationData) do
        if existing.id == entry.id then
            -- Update existing entry
            documentationData[i] = entry
            return
        end
    end
    
    -- Add new entry
    table.insert(documentationData, entry)
end

-- Get documentation entry by ID
function Documentation:GetEntry(id)
    if not id then return nil end
    
    for _, entry in ipairs(documentationData) do
        if entry.id == id then
            return entry
        end
    end
    
    return nil
end

-- Get all documentation entries
function Documentation:GetAllEntries()
    return documentationData
end

-- Get entries by category
function Documentation:GetEntriesByCategory(category)
    if not category then return {} end
    
    local entries = {}
    
    for _, entry in ipairs(documentationData) do
        if entry.category == category then
            table.insert(entries, entry)
        end
    end
    
    -- Sort by order if available
    table.sort(entries, function(a, b)
        return (a.order or 999) < (b.order or 999)
    end)
    
    return entries
end

-- Get all categories
function Documentation:GetCategories()
    return CATEGORIES
end

-- Search documentation
function Documentation:Search(query)
    if not query or query == "" then return {} end
    
    local results = {}
    query = query:lower()
    
    for _, entry in ipairs(documentationData) do
        if entry.title:lower():find(query) or 
           (entry.content and entry.content:lower():find(query)) then
            table.insert(results, entry)
        end
    end
    
    return results
end

-- Create the documentation UI
function Documentation:CreateDocumentationUI(parent)
    if not parent then return end
    
    -- Create main frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsDocumentation", parent, "BackdropTemplate")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Windrunner Rotations Documentation")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create search box
    local searchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -15)
    searchBox:SetAutoFocus(false)
    
    -- Create category list frame
    local categoryFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    categoryFrame:SetSize(200, frame:GetHeight() - 90)
    categoryFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -50)
    categoryFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    categoryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    -- Create category buttons
    local categoryButtons = {}
    local buttonHeight = 25
    local buttonY = -10
    
    local categories = {
        CATEGORIES.GETTING_STARTED,
        CATEGORIES.INTERFACE,
        CATEGORIES.COMBAT,
        CATEGORIES.CLASSES,
        CATEGORIES.PROFILES,
        CATEGORIES.DUNGEONS,
        CATEGORIES.CUSTOMIZATION,
        CATEGORIES.TROUBLESHOOTING,
        CATEGORIES.ADVANCED
    }
    
    for i, category in ipairs(categories) do
        local button = CreateFrame("Button", nil, categoryFrame)
        button:SetSize(180, buttonHeight)
        button:SetPoint("TOP", categoryFrame, "TOP", 0, buttonY - (i-1) * (buttonHeight + 5))
        button:SetText(category)
        button:SetNormalFontObject("GameFontNormal")
        button.category = category
        
        -- Create highlight texture
        local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create selected texture
        local selectedTexture = button:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        button.selectedTexture = selectedTexture
        
        button:SetScript("OnClick", function()
            -- Hide all selected textures
            for _, btn in ipairs(categoryButtons) do
                btn.selectedTexture:Hide()
            end
            
            -- Show this button's selected texture
            selectedTexture:Show()
            
            -- Show entries for this category
            Documentation:ShowCategory(category)
        end)
        
        table.insert(categoryButtons, button)
    end
    
    -- Create content frame
    local contentFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentFrame:SetSize(frame:GetWidth() - 240, frame:GetHeight() - 90)
    contentFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -50)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    -- Create entry list frame
    local entryListFrame = CreateFrame("Frame", nil, contentFrame)
    entryListFrame:SetSize(contentFrame:GetWidth() - 20, contentFrame:GetHeight())
    entryListFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    
    -- Create scroll frame for entries
    local entryScrollFrame = CreateFrame("ScrollFrame", nil, entryListFrame, "UIPanelScrollFrameTemplate")
    entryScrollFrame:SetSize(entryListFrame:GetWidth() - 30, entryListFrame:GetHeight() - 20)
    entryScrollFrame:SetPoint("TOPLEFT", entryListFrame, "TOPLEFT", 0, 0)
    
    local entryScrollChild = CreateFrame("Frame", nil, entryScrollFrame)
    entryScrollChild:SetSize(entryScrollFrame:GetWidth(), 1) -- Height will be set dynamically
    entryScrollFrame:SetScrollChild(entryScrollChild)
    
    -- Create documentation display frame
    local docFrame = CreateFrame("Frame", nil, contentFrame)
    docFrame:SetSize(contentFrame:GetWidth() - 20, contentFrame:GetHeight() - 20)
    docFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    docFrame:Hide()
    
    -- Create scroll frame for documentation
    local docScrollFrame = CreateFrame("ScrollFrame", nil, docFrame, "UIPanelScrollFrameTemplate")
    docScrollFrame:SetSize(docFrame:GetWidth() - 30, docFrame:GetHeight())
    docScrollFrame:SetPoint("TOPLEFT", docFrame, "TOPLEFT", 0, 0)
    
    local docScrollChild = CreateFrame("Frame", nil, docScrollFrame)
    docScrollChild:SetSize(docScrollFrame:GetWidth(), 1) -- Height will be set dynamically
    docScrollFrame:SetScrollChild(docScrollChild)
    
    -- Create back button
    local backButton = CreateFrame("Button", nil, docFrame, "UIPanelButtonTemplate")
    backButton:SetSize(80, 25)
    backButton:SetPoint("BOTTOMLEFT", docFrame, "BOTTOMLEFT", 0, 0)
    backButton:SetText("Back")
    backButton:Hide()
    
    backButton:SetScript("OnClick", function()
        -- Hide documentation display
        docFrame:Hide()
        backButton:Hide()
        
        -- Show entry list
        entryListFrame:Show()
    end)
    
    -- Function to show category
    function Documentation:ShowCategory(category)
        -- Clear entry list
        for i = entryScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, entryScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get entries for this category
        local entries = self:GetEntriesByCategory(category)
        
        -- Show entry list, hide doc display
        entryListFrame:Show()
        docFrame:Hide()
        backButton:Hide()
        
        if #entries == 0 then
            -- No entries message
            local noEntries = entryScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noEntries:SetPoint("TOP", entryScrollChild, "TOP", 0, -20)
            noEntries:SetText("No documentation entries for this category")
            
            entryScrollChild:SetHeight(50)
            return
        end
        
        -- Display entries
        local entryHeight = 60
        local totalHeight = 10
        
        for i, entry in ipairs(entries) do
            local entryFrame = CreateFrame("Button", nil, entryScrollChild)
            entryFrame:SetSize(entryScrollChild:GetWidth() - 20, entryHeight)
            entryFrame:SetPoint("TOPLEFT", entryScrollChild, "TOPLEFT", 10, -totalHeight)
            
            -- Create highlight texture
            local highlightTexture = entryFrame:CreateTexture(nil, "HIGHLIGHT")
            highlightTexture:SetAllPoints()
            highlightTexture:SetColorTexture(1, 1, 1, 0.2)
            
            -- Create title
            local entryTitle = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            entryTitle:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 5, -5)
            entryTitle:SetText(entry.title)
            
            -- Create divider
            local divider = entryFrame:CreateTexture(nil, "ARTWORK")
            divider:SetSize(entryFrame:GetWidth() - 10, 1)
            divider:SetPoint("TOPLEFT", entryTitle, "BOTTOMLEFT", 0, -5)
            divider:SetColorTexture(0.3, 0.3, 0.3, 0.6)
            
            -- Create preview
            local preview = entry.content:match("^(.-)\n") or "No preview available"
            preview = preview:gsub("#%s*", ""):sub(1, 100) -- Remove Markdown header and limit length
            
            local entryPreview = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            entryPreview:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -5)
            entryPreview:SetPoint("RIGHT", entryFrame, "RIGHT", -5, 0)
            entryPreview:SetText(preview .. "...")
            entryPreview:SetJustifyH("LEFT")
            
            -- Handle click
            entryFrame:SetScript("OnClick", function()
                Documentation:ShowDocumentation(entry)
            end)
            
            totalHeight = totalHeight + entryHeight + 10
        end
        
        entryScrollChild:SetHeight(math.max(totalHeight, entryScrollFrame:GetHeight()))
    end
    
    -- Function to show documentation
    function Documentation:ShowDocumentation(entry)
        if not entry then return end
        
        -- Hide entry list, show doc display
        entryListFrame:Hide()
        docFrame:Show()
        backButton:Show()
        
        -- Clear doc display
        for i = docScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, docScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Parse Markdown-like content
        local docContent = self:ParseMarkdown(entry.content, docScrollChild)
        
        -- Add related entries if available
        if entry.related and #entry.related > 0 then
            local relatedTitle = docScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            relatedTitle:SetPoint("TOPLEFT", docContent, "BOTTOMLEFT", 0, -20)
            relatedTitle:SetText("Related Topics")
            
            local relatedEntries = docScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            relatedEntries:SetPoint("TOPLEFT", relatedTitle, "BOTTOMLEFT", 10, -10)
            relatedEntries:SetPoint("RIGHT", docScrollChild, "RIGHT", -10, 0)
            
            local relatedText = ""
            for i, relatedId in ipairs(entry.related) do
                local relatedEntry = self:GetEntry(relatedId)
                if relatedEntry then
                    relatedText = relatedText .. "• " .. relatedEntry.title .. "\n"
                end
            end
            
            relatedEntries:SetText(relatedText)
            
            -- Adjust height to include related entries
            local _, relatedHeight = relatedEntries:GetFont()
            docScrollChild:SetHeight(docContent:GetHeight() + relatedTitle:GetHeight() + relatedEntries:GetStringHeight() + 50)
        else
            docScrollChild:SetHeight(docContent:GetHeight() + 20)
        end
    end
    
    -- Function to parse markdown-like content
    function Documentation:ParseMarkdown(markdown, parent)
        -- Create container for the content
        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(parent:GetWidth(), 100) -- Height will be adjusted
        container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        
        local currentY = 0
        local lines = self:SplitLines(markdown)
        local inCodeBlock = false
        local inList = false
        local listIndent = 0
        
        for i, line in ipairs(lines) do
            -- Check for code block
            if line:match("^```") then
                inCodeBlock = not inCodeBlock
                
                if inCodeBlock then
                    -- Start of code block
                    local codeFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
                    codeFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, currentY - 10)
                    codeFrame:SetPoint("RIGHT", container, "RIGHT", -10, 0)
                    codeFrame:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                        tile = true,
                        tileSize = 16,
                        edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }
                    })
                    codeFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
                    
                    -- Store for adding code content
                    container.currentCodeFrame = codeFrame
                    container.codeContent = ""
                else
                    -- End of code block
                    if container.currentCodeFrame and container.codeContent then
                        local codeText = container.currentCodeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        codeText:SetPoint("TOPLEFT", container.currentCodeFrame, "TOPLEFT", 10, -10)
                        codeText:SetPoint("RIGHT", container.currentCodeFrame, "RIGHT", -10, 0)
                        codeText:SetJustifyH("LEFT")
                        codeText:SetText(container.codeContent)
                        
                        -- Adjust code frame height
                        container.currentCodeFrame:SetHeight(codeText:GetStringHeight() + 20)
                        
                        -- Update current Y position
                        currentY = currentY - container.currentCodeFrame:GetHeight() - 10
                        
                        -- Clear code tracking
                        container.currentCodeFrame = nil
                        container.codeContent = nil
                    end
                end
            elseif inCodeBlock then
                -- Inside code block, add to code content
                if container.codeContent then
                    container.codeContent = container.codeContent .. line .. "\n"
                end
            else
                -- Regular markdown processing
                
                -- Check for headers
                local headerLevel, headerText = line:match("^(#+)%s*(.*)")
                if headerLevel and headerText then
                    local fontSize = "GameFontNormalLarge"
                    if #headerLevel == 2 then
                        fontSize = "GameFontNormalLarge"
                    elseif #headerLevel == 3 then
                        fontSize = "GameFontNormal"
                    elseif #headerLevel >= 4 then
                        fontSize = "GameFontNormalSmall"
                    end
                    
                    local header = container:CreateFontString(nil, "OVERLAY", fontSize)
                    header:SetPoint("TOPLEFT", container, "TOPLEFT", 5, currentY - 10)
                    header:SetPoint("RIGHT", container, "RIGHT", -5, 0)
                    header:SetJustifyH("LEFT")
                    header:SetText(headerText)
                    
                    -- Update current Y position
                    currentY = currentY - header:GetStringHeight() - 10
                    
                    -- Add divider for h1 and h2
                    if #headerLevel <= 2 then
                        local divider = container:CreateTexture(nil, "ARTWORK")
                        divider:SetSize(container:GetWidth() - 20, 1)
                        divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
                        divider:SetColorTexture(0.3, 0.3, 0.3, 0.6)
                        
                        currentY = currentY - 6
                    end
                    
                    -- Extra space after headers
                    currentY = currentY - 5
                    
                    -- End any list
                    inList = false
                elseif line:match("^%*%s") or line:match("^%-%s") or line:match("^%d+%.%s") then
                    -- List item
                    local listText = line:match("^%*%s(.*)") or line:match("^%-%s(.*)") or line:match("^%d+%.%s(.*)")
                    local indent = 15
                    
                    if not inList then
                        -- Start new list
                        inList = true
                        -- Add some space before list
                        currentY = currentY - 5
                    end
                    
                    local listItem = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    listItem:SetPoint("TOPLEFT", container, "TOPLEFT", indent, currentY - 5)
                    listItem:SetPoint("RIGHT", container, "RIGHT", -5, 0)
                    listItem:SetJustifyH("LEFT")
                    
                    -- Add bullet or number
                    local bullet = "• "
                    if line:match("^%d+%.") then
                        bullet = line:match("^(%d+%.)") .. " "
                    end
                    
                    listItem:SetText(bullet .. listText)
                    
                    -- Update current Y position
                    currentY = currentY - listItem:GetStringHeight() - 5
                elseif line:match("^>%s") then
                    -- Blockquote
                    local quoteText = line:match("^>%s(.*)")
                    
                    local quoteFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
                    quoteFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, currentY - 5)
                    quoteFrame:SetPoint("RIGHT", container, "RIGHT", -10, 0)
                    quoteFrame:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                        tile = true,
                        tileSize = 16,
                        edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }
                    })
                    quoteFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
                    
                    local quote = quoteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    quote:SetPoint("TOPLEFT", quoteFrame, "TOPLEFT", 10, -10)
                    quote:SetPoint("RIGHT", quoteFrame, "RIGHT", -10, 0)
                    quote:SetJustifyH("LEFT")
                    quote:SetText(quoteText)
                    
                    -- Adjust quote frame height
                    quoteFrame:SetHeight(quote:GetStringHeight() + 20)
                    
                    -- Update current Y position
                    currentY = currentY - quoteFrame:GetHeight() - 10
                elseif line:match("^%-%-%-+") then
                    -- Horizontal rule
                    local rule = container:CreateTexture(nil, "ARTWORK")
                    rule:SetSize(container:GetWidth() - 20, 1)
                    rule:SetPoint("TOPLEFT", container, "TOPLEFT", 10, currentY - 10)
                    rule:SetColorTexture(0.3, 0.3, 0.3, 0.6)
                    
                    -- Update current Y position
                    currentY = currentY - 20
                elseif line:trim() == "" then
                    -- Empty line
                    currentY = currentY - 10
                    
                    -- End any list
                    inList = false
                else
                    -- Regular paragraph
                    local paragraph = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    paragraph:SetPoint("TOPLEFT", container, "TOPLEFT", 10, currentY - 5)
                    paragraph:SetPoint("RIGHT", container, "RIGHT", -10, 0)
                    paragraph:SetJustifyH("LEFT")
                    paragraph:SetText(line)
                    
                    -- Update current Y position
                    currentY = currentY - paragraph:GetStringHeight() - 10
                    
                    -- End any list if this wasn't part of it
                    inList = false
                end
            end
        end
        
        -- Set final container height
        container:SetHeight(math.abs(currentY) + 20)
        
        return container
    end
    
    -- Helper function to split string into lines
    function Documentation:SplitLines(str)
        local lines = {}
        for line in str:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end
        return lines
    end
    
    -- Set up search box
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText():trim()
        if text == "" then
            -- If empty, show currently selected category
            for _, button in ipairs(categoryButtons) do
                if button.selectedTexture:IsShown() then
                    Documentation:ShowCategory(button.category)
                    return
                end
            end
            
            -- Default to first category if none selected
            if #categoryButtons > 0 then
                categoryButtons[1].selectedTexture:Show()
                Documentation:ShowCategory(categoryButtons[1].category)
            end
        else
            -- Search results
            Documentation:ShowSearchResults(text)
        end
    end)
    
    -- Function to show search results
    function Documentation:ShowSearchResults(query)
        -- Hide selected category indicators
        for _, button in ipairs(categoryButtons) do
            button.selectedTexture:Hide()
        end
        
        -- Clear entry list
        for i = entryScrollChild:GetNumChildren(), 1, -1 do
            local child = select(i, entryScrollChild:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get search results
        local results = self:Search(query)
        
        -- Show entry list, hide doc display
        entryListFrame:Show()
        docFrame:Hide()
        backButton:Hide()
        
        if #results == 0 then
            -- No results message
            local noResults = entryScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noResults:SetPoint("TOP", entryScrollChild, "TOP", 0, -20)
            noResults:SetText("No results found for: " .. query)
            
            entryScrollChild:SetHeight(50)
            return
        end
        
        -- Display results
        local entryHeight = 60
        local totalHeight = 10
        
        local resultsLabel = entryScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        resultsLabel:SetPoint("TOPLEFT", entryScrollChild, "TOPLEFT", 10, -totalHeight)
        resultsLabel:SetText("Search Results for: " .. query)
        
        totalHeight = totalHeight + resultsLabel:GetStringHeight() + 15
        
        for i, entry in ipairs(results) do
            local entryFrame = CreateFrame("Button", nil, entryScrollChild)
            entryFrame:SetSize(entryScrollChild:GetWidth() - 20, entryHeight)
            entryFrame:SetPoint("TOPLEFT", entryScrollChild, "TOPLEFT", 10, -totalHeight)
            
            -- Create highlight texture
            local highlightTexture = entryFrame:CreateTexture(nil, "HIGHLIGHT")
            highlightTexture:SetAllPoints()
            highlightTexture:SetColorTexture(1, 1, 1, 0.2)
            
            -- Create title
            local entryTitle = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            entryTitle:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 5, -5)
            entryTitle:SetText(entry.title)
            
            -- Create category
            local entryCategory = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            entryCategory:SetPoint("LEFT", entryTitle, "RIGHT", 10, 0)
            entryCategory:SetText("(" .. entry.category .. ")")
            entryCategory:SetTextColor(0.7, 0.7, 0.7)
            
            -- Create divider
            local divider = entryFrame:CreateTexture(nil, "ARTWORK")
            divider:SetSize(entryFrame:GetWidth() - 10, 1)
            divider:SetPoint("TOPLEFT", entryTitle, "BOTTOMLEFT", 0, -5)
            divider:SetColorTexture(0.3, 0.3, 0.3, 0.6)
            
            -- Create preview
            local preview = entry.content:match("^(.-)\n") or "No preview available"
            preview = preview:gsub("#%s*", ""):sub(1, 100) -- Remove Markdown header and limit length
            
            local entryPreview = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            entryPreview:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -5)
            entryPreview:SetPoint("RIGHT", entryFrame, "RIGHT", -5, 0)
            entryPreview:SetText(preview .. "...")
            entryPreview:SetJustifyH("LEFT")
            
            -- Handle click
            entryFrame:SetScript("OnClick", function()
                Documentation:ShowDocumentation(entry)
            end)
            
            totalHeight = totalHeight + entryHeight + 10
        end
        
        entryScrollChild:SetHeight(math.max(totalHeight, entryScrollFrame:GetHeight()))
    end
    
    -- Select first category by default
    if #categoryButtons > 0 then
        categoryButtons[1].selectedTexture:Show()
        Documentation:ShowCategory(categoryButtons[1].category)
    end
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Handle slash commands
function Documentation:HandleCommand(cmd)
    if not cmd or cmd == "" then
        -- Show documentation UI
        self:ShowDocumentationUI()
        return
    end
    
    local args = {}
    for arg in cmd:gmatch("%S+") do
        table.insert(args, arg:lower())
    end
    
    if args[1] == "search" or args[1] == "find" then
        -- Search documentation
        local query = cmd:match("^%S+%s+(.+)$")
        if query then
            self:ShowSearchResults(query)
        else
            WR:Print("Usage: /wr help search <query>")
        end
    elseif args[1] == "category" or args[1] == "cat" then
        -- Show category
        local category = cmd:match("^%S+%s+(.+)$")
        if category then
            self:ShowCategoryByName(category)
        else
            -- List categories
            WR:Print("Available categories:")
            for _, cat in pairs(CATEGORIES) do
                WR:Print("- " .. cat)
            end
        end
    else
        -- Try to find specific entry
        local entry = self:GetEntry(args[1])
        if entry then
            self:ShowDocumentation(entry)
        else
            -- Show documentation UI
            self:ShowDocumentationUI()
        end
    end
end

-- Show documentation UI
function Documentation:ShowDocumentationUI()
    -- Create UI if it doesn't exist
    if not self.ui then
        self.ui = self:CreateDocumentationUI(UIParent)
    end
    
    -- Show UI
    self.ui:Show()
end

-- Show search results
function Documentation:ShowSearchResults(query)
    -- Create UI if it doesn't exist
    if not self.ui then
        self.ui = self:CreateDocumentationUI(UIParent)
    end
    
    -- Show UI
    self.ui:Show()
    
    -- Perform search
    if self.ui.searchBox then
        self.ui.searchBox:SetText(query)
    end
end

-- Show category by name
function Documentation:ShowCategoryByName(categoryName)
    -- Create UI if it doesn't exist
    if not self.ui then
        self.ui = self:CreateDocumentationUI(UIParent)
    end
    
    -- Show UI
    self.ui:Show()
    
    -- Find category
    for key, value in pairs(CATEGORIES) do
        if value:lower() == categoryName:lower() then
            -- Find and click the corresponding button
            for _, button in ipairs(self.ui.categoryButtons or {}) do
                if button.category == value then
                    button:Click()
                    return
                end
            end
            
            -- Fallback if button not found
            self:ShowCategory(value)
            return
        end
    end
    
    -- Category not found
    WR:Print("Category not found: " .. categoryName)
    WR:Print("Available categories:")
    for _, cat in pairs(CATEGORIES) do
        WR:Print("- " .. cat)
    end
end

-- Initialize the module
Documentation:Initialize()

return Documentation