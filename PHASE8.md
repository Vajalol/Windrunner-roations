# Phase 8: Enhanced Class Rotation System

## Overview

Phase 8 of Windrunner Rotations delivers a comprehensive class optimization system that dramatically improves rotation quality through deep class knowledge integration, intelligent build analysis, and adaptive resource management. This system enables fully automatic and sophisticated rotations that adapt to each player's specific class, spec, talents, gear, and playstyle preferences.

## Core Components

### 1. Class Knowledge Database (`Core/ClassKnowledge.lua`)

A comprehensive theorycrafting database containing detailed information for all classes and specs:

- **Spell Database**: Complete catalog of all abilities with IDs, icons, and categorization
- **Priority Systems**: Situation-specific rotation priorities (single-target, AoE, execute, movement)
- **Talent Build Templates**: Optimized builds with descriptions and rotation modifications
- **Special Mechanics**: Class-specific mechanics implementations and tracking
- **Resources Management**: Resource-specific handling and optimization

The knowledge database serves as the foundation for intelligent decision-making throughout the addon.

### 2. Build Analysis System (`Core/BuildAnalyzer.lua`)

An intelligent build detection and analysis system that:

- **Detects Player Builds**: Automatically scans and identifies the player's talent selections
- **Matches Template Builds**: Compares against known optimal builds and calculates similarity
- **Analyzes Strengths/Weaknesses**: Identifies strong points and potential improvements
- **Provides Recommendations**: Suggests talent changes to optimize performance
- **Visualizes Build Data**: Offers UI to explore build details and comparisons

This allows the rotation system to adapt to the player's specific talent choices and playstyle.

### 3. Resource Optimization (`Core/ResourceOptimizer.lua`)

A sophisticated resource management system that:

- **Optimizes Resource Usage**: Dynamically adjusts ability priorities based on resource levels
- **Adapts to Situations**: Uses different resource strategies for different combat scenarios
- **Prevents Overcapping**: Ensures resources aren't wasted by overcapping
- **Manages Multiple Resources**: Handles classes with multiple resource types (e.g., Energy + Combo Points)
- **Predicts Resource Levels**: Forecasts future resource availability for smarter decisions

Each class and spec receives specialized resource handling tailored to its unique mechanics.

### 4. Legendary & Tier Set Integration (`Core/LegendaryAndSetManager.lua`)

A gear integration system that:

- **Detects Equipped Legendaries**: Identifies legendary items and their effects
- **Monitors Tier Set Bonuses**: Tracks active tier set bonuses
- **Adjusts Rotations**: Modifies ability priorities based on legendary and set bonus effects
- **Visualizes Gear Effects**: Provides UI to see how gear affects rotation

This ensures rotation recommendations account for powerful gear effects that can significantly alter optimal ability usage.

### 5. Playstyle Profiles (`Core/PlaystyleManager.lua`)

A customization system offering different playstyle options:

- **Beginner Profile**: Simplified rotation with fewer buttons and forgiving timing
- **Standard Profile**: Balanced approach suitable for most content
- **Advanced Profile**: Complex, min-maxed rotation for experienced players
- **Custom Profile**: User-defined settings for complete personalization
- **Content-Specific Profiles**: Specialized profiles for different content types

This allows players of all skill levels to benefit from the addon while maintaining appropriate complexity.

### 6. Encounter Intelligence (`Core/EncounterManager.lua`)

A system that provides boss-specific optimizations:

- **Boss Mechanic Detection**: Identifies active boss mechanics
- **Phase Detection**: Tracks boss fight phases
- **Rotation Adjustments**: Modifies priorities based on encounter specifics
- **Mythic+ Dungeon Support**: Special handling for Mythic+ affixes and mechanics
- **Defensive Recommendations**: Suggests defensive cooldown usage during dangerous mechanics

This ensures the rotation adapts to the specific demands of each encounter.

## Implementation Highlights

### Fully Integrated System

All components work together to create a cohesive system:

1. **ClassKnowledge** provides the foundational data
2. **BuildAnalyzer** examines the player's specific build
3. **ResourceOptimizer** manages resources based on class/spec
4. **LegendaryAndSetManager** adjusts for gear effects
5. **PlaystyleManager** applies the user's preferred complexity
6. **EncounterManager** further adjusts for specific fight mechanics

### Example: Frost Mage Optimization

For a Frost Mage, the system:

1. Loads detailed Frost Mage spell data and priorities
2. Detects the player's talent build (e.g., Glacial Cascade vs. Thermal Void)
3. Applies Frost-specific resource management focusing on Brain Freeze and Fingers of Frost procs
4. Identifies legendaries like Cold Front and their effect on rotation
5. Applies playstyle profile (e.g., Beginner simplifies Shatter combo timing)
6. Makes encounter-specific adjustments (e.g., saving Frozen Orb for add phases)

The result is a rotation that feels like it was hand-crafted specifically for that player's exact character and situation.

### Enhanced User Interface

The system includes comprehensive UI components:

- **Build Analysis UI**: Displays build information, template matching, and recommendations
- **Gear Effects UI**: Shows legendary and tier set effects on rotation
- **Playstyle UI**: Allows selection and customization of playstyle profiles
- **Encounter UI**: Displays current encounter data and active adjustments

## Benefits Over Competing Addons

This enhanced class rotation system offers several advantages:

1. **Deeper Class Knowledge**: Incorporates more detailed theorycrafting information
2. **Build-Specific Adaptations**: Adjusts more intelligently to talent choices
3. **Gear Integration**: More sophisticated handling of legendary effects and tier sets
4. **Customizable Complexity**: Allows users to choose their preferred level of complexity
5. **Encounter Optimizations**: More sophisticated boss-specific adjustments
6. **Holistic System**: All components work together seamlessly rather than as separate systems

## Technical Achievement

The Phase 8 Enhanced Class Rotation System represents a significant technical achievement, with:

- Comprehensive spell databases for all classes and specs
- Sophisticated decision-making algorithms
- Dynamic priority modifications based on multiple factors
- Deep integration between all addon components
- User-friendly visualization and customization tools

This creates a fully automatic rotation system that rivals the quality of manual play while being more accessible and adaptable than competing addons.