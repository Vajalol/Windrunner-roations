# WindrunnerRotations User Manual

## Introduction

Welcome to WindrunnerRotations, an advanced combat rotation optimization system for World of Warcraft: The War Within (Season 2). This addon dynamically generates intelligent spell casting strategies across all character classes and specializations, ensuring optimal performance in both raids and dungeons.

## Getting Started

### Installation

1. Download the latest version of WindrunnerRotations from [GitHub](https://github.com/VortexQ8/WindrunnerRotations) or [CurseForge](https://www.curseforge.com/wow/addons/windrunnerrotations)
2. Extract the downloaded file to your World of Warcraft `_retail_\Interface\AddOns` directory
3. Launch or reload World of Warcraft
4. Ensure the addon is enabled in your addon list

### Initial Setup

1. Type `/wr` in your chat window to open the main configuration panel
2. Under the "General" tab, ensure the addon is enabled
3. Select your class from the left sidebar
4. Configure your specialization-specific settings as needed

## Key Features

### Automatic Rotation Optimization

WindrunnerRotations continuously analyzes combat conditions and automatically selects the optimal abilities to use based on your current situation, resources, and cooldowns.

- **Dynamic Adaptation**: Adapts to your current target, surrounding enemies, and combat status
- **Resource Management**: Intelligently manages class resources like Mana, Rage, Energy, etc.
- **Cooldown Integration**: Optimal usage of important cooldowns and burst windows
- **Situational Awareness**: Makes smart decisions based on target health, your health, and other context

### Configuration and Customization

- **Class-specific Settings**: Detailed customization options for each specialization
- **Rotation Modes**: Switch between different rotation styles (AoE, Single-Target, Cleave)
- **Performance Tuning**: Adjust resource thresholds, ability priorities, and more
- **Keybinding Support**: Use the WoW key binding interface to set up activation keys

### Performance Tracking

- **Real-time Analysis**: Track your DPS/HPS, rotation efficiency, and resource usage
- **Combat Logs**: Detailed breakdown of performance after combat encounters
- **Suggestions**: Get intelligent recommendations to improve your performance

### Talent Loadout Integration

- **Recommended Loadouts**: Access curated talent builds from multiple sources
- **Import/Export**: Easily share and import talent configurations
- **Performance Analysis**: Compare your current talent build with recommended builds

## Basic Usage

### Starting the Rotation

1. Type `/wr toggle` to enable/disable the rotation
2. Alternatively, use the keybind you set in WoW's key binding interface

### Configuration Interface

Access the configuration interface with `/wr` or `/wrconfig`

- **General Tab**: Global addon settings and features
- **Class Tabs**: Class and specialization-specific settings
- **Combat Simulator**: Test and analyze rotation performance
- **Performance**: Configure performance tracking features
- **Profiles**: Manage configuration profiles

## Commands Reference

- `/wr` - Opens the main configuration panel
- `/wr toggle` - Toggles the rotation on/off
- `/wr help` - Shows help information
- `/wr status` - Displays current addon status
- `/wrconfig` - Opens the configuration panel
- `/wrsim` - Access the rotation simulator
- `/wrperf` - Access the performance tracker
- `/wrtalent` - Access the talent loadout manager

## Class Guides

Please refer to the individual class guides for detailed information on each specialization:

- [Death Knight Guide](./Classes/DeathKnight.md)
- [Demon Hunter Guide](./Classes/DemonHunter.md)
- [Druid Guide](./Classes/Druid.md)
- [Evoker Guide](./Classes/Evoker.md)
- [Hunter Guide](./Classes/Hunter.md)
- [Mage Guide](./Classes/Mage.md)
- [Monk Guide](./Classes/Monk.md)
- [Paladin Guide](./Classes/Paladin.md)
- [Priest Guide](./Classes/Priest.md)
- [Rogue Guide](./Classes/Rogue.md)
- [Shaman Guide](./Classes/Shaman.md)
- [Warlock Guide](./Classes/Warlock.md)
- [Warrior Guide](./Classes/Warrior.md)

## Advanced Features

### Rotation Simulator

The Rotation Simulator allows you to test your rotation in a controlled environment without actually playing the game. This is useful for comparing different talent builds, settings, and strategies.

1. Type `/wrsim` to access the simulator
2. Select your class and specialization
3. Set the simulation duration and parameters
4. Click "Start Simulation" to begin
5. Review the simulation report for DPS/HPS, rotation efficiency, and more

### Performance Tracker

The Performance Tracker provides detailed analytics on your actual in-game performance:

1. Type `/wrperf` to access the tracker
2. Enable the performance overlay during combat
3. After combat, review detailed statistics and suggestions
4. Use the `/wrperf report` command to see your last combat report

### Talent Loadout Manager

The Talent Loadout Manager helps you optimize your talent builds:

1. Type `/wrtalent` to access the manager
2. Use `/wrtalent recommended` to see recommended builds for your spec
3. Import builds with `/wrtalent import [string]`
4. Export your current build with `/wrtalent export`
5. Analyze your build with `/wrtalent analyze`

### Action Priority List (APL) System

The APL System allows advanced users to customize their rotation priority logic:

1. Access APL settings in your class/spec configuration
2. Create custom priority lists for different situations
3. Use conditions, variables, and functions to create complex logic
4. Test your APL in the simulator before using it in combat

## Troubleshooting

### Common Issues

1. **Rotation not working**: Ensure the addon is enabled and properly toggled on
2. **Poor performance**: Check your settings and make sure they match your gear and talent build
3. **Conflicts with other addons**: Disable other rotation addons to avoid conflicts
4. **Resource issues**: Adjust resource thresholds in your spec settings

### Getting Help

- Visit our [GitHub repository](https://github.com/VortexQ8/WindrunnerRotations) for the latest updates and issues
- Join our [Discord community](https://discord.gg/windrunnerrotations) for support
- Check the [FAQ section](./FAQ.md) for answers to common questions

## Credits

WindrunnerRotations is developed and maintained by VortexQ8 with contributions from the WoW theorycrafting community. Special thanks to all contributors and testers for their valuable input and feedback.

## License

WindrunnerRotations is released under the MIT License. See the LICENSE file for details.