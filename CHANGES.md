# Windrunner Rotations - Change Log

## Version 1.3.0 (April 29, 2025)

### Major Features Added
- **Pet Management System**: Comprehensive pet control for classes like Hunter, Warlock, and Death Knight
- **Movement Optimization**: Automatic pathfinding and player positioning during combat
- **Boss Mechanic Avoidance**: Detection and response to specific raid and dungeon boss mechanics
- **Line of Sight Verification**: Ensures targets are visible before attempting ability usage
- **Rotation Pause/Resume Logic**: Smart detection of manual player control with automatic resuming

### Advanced Automation
- Added full auto-follow capability with contextual decision making
- Implemented dynamic crowd control priorities in multi-target situations
- Created advanced targeting filters with line of sight and distance checks
- Added sophisticated path planning for complex movement scenarios
- Integrated dungeon and raid boss ability detection for proactive defensive usage

## Version 1.2.0 (April 28, 2025)

### Major Features Added
- **Trinket Automation System**: Added intelligent trinket usage based on combat conditions and cooldown phases
- **Consumable Manager**: Implemented automatic potion, healthstone and other consumable usage based on combat state
- **Priority Queue System**: Created dynamic ability prioritization system with adaptive decision making
- **Racials Integration**: Added automatic racial ability usage optimized for each class and specialization
- **Group Buff Tracking**: Implemented comprehensive buff tracking with automatic casting of missing buffs
- **Auto-Dispel System**: Added intelligent dispelling of harmful effects with priority-based decision making

### System Improvements
- Updated RotationManager with comprehensive combat state tracking
- Improved decision making with deep combat state analysis
- Enhanced resource-based ability prioritization
- Added better AoE vs. single-target transition logic

## Version 1.1.0 (April 22, 2025)

### Major Features Added
- **MouseOver Targeting System**: Added comprehensive mouseover support for all healing, offensive, and utility abilities
- **Target Switching AI**: Implemented intelligent target switching based on priority, health, and battlefield conditions
- **Interrupt Management System**: Added sophisticated interrupt handling with priority-based decision making
- **Enemy Classification Framework**: Created comprehensive enemy classification and prioritization system
- **Encounter-Specific Logic**: Added boss encounter detection with phase-aware ability usage
- **Smart Defensive System**: Implemented damage tracking and intelligent defensive cooldown usage
- **Cursor-Targeted Ability Handling**: Added optimal positioning for ground-targeted and leap abilities

### Class Module Improvements
- Updated all class modules with spec-specific optimizations
- Improved resource management across all classes
- Enhanced AoE vs single-target decision making
- Added raid buff and debuff tracking

### Technical Improvements
- Enhanced Tinkr API integration with proper version validation
- Implemented protected function calls for secure execution
- Added cursor-targeted ability handling to match Phoenix Rotations
- Improved error handling and combat logging

### UI Enhancements
- Added tabbed interface for easier navigation
- Implemented responsive design for all UI components
- Enhanced slash command functionality

## Version 1.0.0 (March 15, 2025)

### Initial Release
- Core engine framework and foundation
- Basic class modules for all 12 classes
- Fundamental rotation logic
- Basic configuration UI
- Tinkr API integration