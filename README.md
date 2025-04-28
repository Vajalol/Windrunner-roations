# Windrunner Rotations

## Advanced Combat Optimization System for World of Warcraft (The War Within Season 2)

**Author:** VortexQ8  
**Version:** 1.3.0

## Overview

Windrunner Rotations is an advanced combat rotation optimization system for World of Warcraft that provides intelligent, adaptive spell casting strategies with comprehensive multi-class performance analysis. The addon delivers superior automation for optimal combat ability usage across all character classes and specializations.

## Features

- **Intelligent Rotation Optimization Engine**: Dynamically adjusts ability priorities based on combat conditions, resources, procs, and enemy state
- **Comprehensive Multi-Class Support**: Complete rotations for all 12 character classes with specialized modules for each specialization
- **Pet Management System**: Comprehensive pet control for Hunter, Warlock, Death Knight, and other pet classes
- **Movement Optimization System**: Automatic positioning and pathfinding to maximize performance in combat
- **Boss Mechanic Avoidance**: Detection and smart response to raid and dungeon boss mechanics
- **Line of Sight Verification**: Ensures targets are in line of sight before attempting spell casts
- **Rotation Control System**: Smart pause/resume with manual override detection and auto-resume logic
- **Dynamic Priority Queue System**: Intelligent priority-based decision making that adapts to combat conditions in real-time
- **Trinket & Consumable Automation**: Smart usage of trinkets, potions, and other consumables based on combat state
- **Racial Ability Integration**: Optimized automatic usage of racial abilities for each class and specialization
- **Group Buff Management**: Automatic tracking and casting of missing buffs on party and raid members
- **Intelligent Dispel System**: Automatic removal of harmful effects based on priority and tactical importance
- **Smart Target Switching**: Automatically switches to high-priority targets based on health, debuffs, and tactical importance
- **Advanced Interrupt System**: Intelligently interrupts enemy casts with priority-based decision making
- **Enemy Classification System**: Categorizes enemies by type and threat level with special handling for boss encounters
- **Smart Defensive Usage**: Monitors incoming damage and automatically uses defensive abilities based on threat assessment
- **Cursor-Targeted Ability Handling**: Optimal positioning of ground-targeted AoE and movement abilities
- **MouseOver Support**: Cast abilities on mouseover targets without switching from your current target
- **Encounter-Specific Logic**: Special handling for raid and dungeon boss mechanics

## Requirements

- World of Warcraft: The War Within (Season 2)
- [Tinkr Framework](https://tinkr.app) (API integration)

## File Structure and Functionality

### Core Files
- **Init.lua**: Initializes the addon, checks dependencies, and bootstrap the module system
- **Core/API.lua**: The central API providing all core functionality including cursor targeting, enemy classification, target switching, and defensive systems
- **Core/ConfigRegistry.lua**: Handles user configuration storage, loading and saving settings
- **Core/ModuleManager.lua**: Manages loading and registration of class modules and their specializations
- **Core/RotationManager.lua**: Controls the execution of rotation logic for each class/spec
- **Core/ErrorHandler.lua**: Sophisticated error catching and reporting system
- **Core/PerformanceManager.lua**: Optimizes addon performance with throttling and resource management
- **Core/VersionManager.lua**: Handles version checking and update notifications
- **Core/CombatAnalysis.lua**: Analyzes combat events and provides performance metrics
- **Core/AntiDetectionSystem.lua**: Ensures the addon remains compliant with Blizzard's automation policies
- **Core/PvPManager.lua**: Special handling for PvP-specific scenarios and abilities
- **Core/ItemManager.lua**: Handles intelligent trinket usage and consumable management
- **Core/RacialsManager.lua**: Manages automatic racial ability usage optimized for each class
- **Core/BuffManager.lua**: Provides group buff tracking and automatic missing buff casting
- **Core/DispelManager.lua**: Intelligent system for automatic dispelling of harmful effects
- **Core/PriorityQueue.lua**: Dynamic ability prioritization system that adapts to combat conditions
- **Core/PetManager.lua**: Handles comprehensive pet control for pet classes
- **Core/LineOfSightManager.lua**: Ensures targets are in line of sight before casting abilities
- **Core/MovementManager.lua**: Handles automated movement and optimal positioning
- **Core/BossMechanicManager.lua**: Detects and responds to specific raid and dungeon boss mechanics
- **Core/RotationControlManager.lua**: Smart system for pause/resume with manual override detection

### UI Files
- **UI/EnhancedConfigUI.lua**: The configuration interface for adjusting all rotation settings

### Class Rotation Files
- **Classes/DeathKnight.lua**: Blood, Frost, and Unholy rotation specializations
- **Classes/DemonHunter.lua**: Havoc and Vengeance rotation specializations
- **Classes/Druid.lua**: Balance, Feral, Guardian, and Restoration rotation specializations
- **Classes/Evoker.lua**: Devastation, Preservation, and Augmentation rotation specializations
- **Classes/Hunter.lua**: Beast Mastery, Marksmanship, and Survival rotation specializations
- **Classes/Mage.lua**: Arcane, Fire, and Frost rotation specializations
- **Classes/Monk.lua**: Brewmaster, Mistweaver, and Windwalker rotation specializations
- **Classes/Paladin.lua**: Holy, Protection, and Retribution rotation specializations
- **Classes/Priest.lua**: Discipline, Holy, and Shadow rotation specializations
- **Classes/Rogue.lua**: Assassination, Outlaw, and Subtlety rotation specializations
- **Classes/Shaman.lua**: Elemental, Enhancement, and Restoration rotation specializations
- **Classes/Warlock.lua**: Affliction, Demonology, and Destruction rotation specializations
- **Classes/Warrior.lua**: Arms, Fury, and Protection rotation specializations

## Key Systems Documentation

### Dynamic Priority Queue System
The priority queue system provides intelligent ability prioritization:
- Dynamically adjusts ability priorities based on combat conditions
- Adapts to changing resources, health, and enemy states
- Takes into account AoE vs single target scenarios
- Adjusts based on combat phases (opener, execute, burst windows)
- Provides optimal ability sequence based on priority calculations

Configure priority weights in the "Rotation" tab of the settings panel.

### Trinket and Consumable Automation
The ItemManager system intelligently handles:
- Automatic trinket usage based on cooldown alignment
- Smart consumable usage including potions, healthstones, and scrolls
- Equipment-specific optimizations for unique trinket effects
- Logic for saving DPS consumables for optimal burst windows
- Health-based defensive consumable usage

Customize thresholds in the "Consumables" tab of the settings panel.

### Racial Ability Integration
The RacialsManager provides:
- Race-specific ability optimization for each class
- Automatic usage of offensive racials during burst windows
- Health-threshold based defensive racial usage
- Intelligent timing of utility racial abilities
- Complete customization of racial ability usage

Configuration options available in the "Racials" section of class settings.

### Group Buff Management
The BuffManager system ensures:
- Automatic tracking of group and raid buffs
- Smart casting of missing buffs with priority system
- Class-specific buff handling for all buff types
- Role-specific buffs for tanks, healers, and DPS
- Configurable buff refreshing behavior

Adjust settings in the "Group Buffs" tab of the configuration panel.

### Auto-Dispel System
The DispelManager provides advanced dispel automation:
- Intelligent prioritization of harmful effects
- Role-based dispel targeting (prioritize tanks/healers)
- Debuff type filtering (magic, curse, poison, disease)
- Smart handling of special mechanics (don't dispel certain effects)
- Detection of high-priority debuffs that need immediate removal

Dispel settings can be configured in the "Dispel" tab of the settings panel.

### Target Switching System
The target switching system intelligently selects the optimal target based on:
- Priority score (calculated from multiple factors)
- Health percentage (with special handling for execute phase)
- Tactical importance (healers, boss enemies, etc.)
- Debuff status (preferring targets with your DoTs)
- Distance and accessibility

Usage is automatic, but can be configured in the UI settings panel.

### Interrupt Handling
The interrupt system prioritizes interrupts based on:
- Spell importance (healing > crowd control > damage)
- Time remaining on cast (prioritizing nearly complete casts)
- Target health (focusing on low health high-value targets)
- Cooldown availability of interrupt abilities

Configuration available per-spec in the "Interrupts" tab of the settings panel.

### Enemy Classification
Enemies are automatically classified by:
- Type: normal, elite, rare, boss, raidBoss, pvp, healer, highValue
- Priority: 0-100 scale (higher = more important)
- Status flags: isTanking, isCasting, isDangerous, inExecute
- Health & distance metrics
- Special handling for raid markers

### Smart Defensive System
The defensive system:
- Tracks incoming damage patterns in real-time
- Detects damage spikes that need immediate mitigation
- Calculates threat level based on health, recent damage, and combat situation
- Intelligently uses defensive cooldowns at optimal moments
- Adjusts based on encounter mechanics

Configure thresholds in the "Defensives" tab of the settings panel.

### Pet Management System
The PetManager provides comprehensive pet handling:
- Automatic pet summoning when missing or dead
- Smart usage of pet-specific offensive abilities
- Automatic pet defensive abilities when health is low
- Class-specific optimal pet selection
- Spec-aware pet ability prioritization

Configure pet management in the "Pets" tab of the settings panel.

### Movement Optimization System
The MovementManager handles position-based optimization:
- Automatic maintenance of optimal distance for your spec
- Smart pathing around obstacles and danger zones
- Role-specific positioning (melee behind, ranged at distance)
- Automatic use of movement-enhancing abilities
- Boss-specific positioning strategies

Adjust movement settings in the "Movement" tab of the settings panel.

### Boss Mechanic Avoidance System
The BossMechanicManager provides raid and dungeon mechanic handling:
- Automatic detection of dangerous ground effects
- Proactive defensive usage for unavoidable mechanics
- Mechanic-specific positioning adjustments
- Phase detection for multi-phase encounters
- Pre-programmed responses to specific boss abilities

Settings available in the "Boss Mechanics" section of the configuration.

### Line of Sight System
The LineOfSightManager ensures ability usage success:
- Verification of line of sight before ability usage
- Range checking for all abilities before suggesting them
- Smart ability substitution when primary abilities aren't usable
- Automatic repositioning when target isn't in line of sight
- Dynamic ability prioritization based on current positioning

### Rotation Control System
The RotationControlManager provides intelligent automation control:
- Automatic pause when player manually casts abilities
- Smart resume after manual input with configurable delay
- Automatic pause for important player activities (looting, talking to NPCs)
- Keybind to quickly pause/resume the rotation
- Context-aware mode switching based on combat situation

Configure pause/resume behavior in the "Control" section of settings.

### Encounter-Specific Logic
The addon includes special handling for raid and dungeon encounters:
- Phase detection for multi-phase fights
- Special ability usage during specific mechanics
- Automatic adjustments for encounter-specific requirements
- Pre-programmed strategies for major bosses

## Usage Guide

### Installation
1. Install Tinkr Framework from [tinkr.app](https://tinkr.app)
2. Extract the WindrunnerRotations folder to your WoW AddOns directory
3. Ensure both Tinkr and WindrunnerRotations are enabled in your addon list

### Configuration
1. Access the configuration panel with `/wr` or `/windrunner`
2. Navigate through the tabs for General, Class, Defensives, Interrupts, and Targeting settings
3. Class-specific settings are available in the Class tab
4. All settings are automatically saved per-character and per-specialization

### Class Module Usage
Each class module follows the same structure:
1. General settings for the class (resources, cooldowns)
2. Specialization-specific settings
3. AoE settings and thresholds
4. Defensive and utility configuration
5. PvP-specific adjustments

### Custom Tweaking
Advanced users can adjust custom variables in the "Advanced" section of each specialization, including:
- APL (Action Priority List) adjustments
- Custom talent builds support
- Cooldown usage behavior
- Encounter-specific optimizations

## Performance Optimization

The addon has been heavily optimized for minimal performance impact:
- Efficient event-based updates instead of continuous scanning
- Smart throttling of computation-heavy operations
- Minimal memory footprint with optimized caching
- Resource-adaptive processing that scales with your system's capabilities

## License

All rights reserved. © 2023-2025 VortexQ8