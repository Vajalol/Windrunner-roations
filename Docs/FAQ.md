# WindrunnerRotations - Frequently Asked Questions

## General Questions

### What is WindrunnerRotations?
WindrunnerRotations is an advanced combat rotation optimization system for World of Warcraft: The War Within (Season 2). It provides automated ability suggestions and optimizations for all character classes and specializations.

### Is this addon allowed by Blizzard?
Yes. WindrunnerRotations provides suggestions and can automate rotations based on your inputs, but it does not interact with the game client in a prohibited way. It follows Blizzard's addon policy by using only approved API functions and requiring player interaction.

### Which WoW expansions/versions are supported?
WindrunnerRotations is designed specifically for World of Warcraft: The War Within (Retail / WoW 11.0+). It may not function correctly in Classic versions or previous expansions.

### Does WindrunnerRotations support all classes and specializations?
Yes, WindrunnerRotations supports all 13 classes and all their specializations, including the latest Evoker class and the new Augmentation specialization.

### Can I use WindrunnerRotations alongside other rotation addons?
It's not recommended to use multiple rotation addons simultaneously as they can conflict with each other. We recommend disabling other rotation addons when using WindrunnerRotations.

## Setup and Configuration

### How do I install WindrunnerRotations?
Download the latest version from [GitHub](https://github.com/VortexQ8/WindrunnerRotations) or [CurseForge](https://www.curseforge.com/wow/addons/windrunnerrotations), then extract the files to your `World of Warcraft\_retail_\Interface\AddOns` directory.

### How do I open the configuration panel?
Type `/wr` or `/wrconfig` in your chat window to open the main configuration panel.

### How do I set up keybindings for WindrunnerRotations?
WindrunnerRotations integrates with WoW's key binding system. Open the Key Bindings menu (Escape > Key Bindings), go to the "AddOns" section, and find WindrunnerRotations to set your preferred keys.

### How can I switch between single-target and AoE rotations?
WindrunnerRotations automatically switches between single-target and AoE rotations based on the number of enemies detected. You can adjust the AoE threshold in your specialization settings.

### How do I configure specific class settings?
Open the configuration panel with `/wr`, select your class from the sidebar, then choose your specialization to access detailed settings.

## Features and Usage

### How does WindrunnerRotations know which abilities to use?
WindrunnerRotations uses a sophisticated priority system based on extensive theorycrafting, simulations, and real-world performance data. It considers your current resources, cooldowns, buffs/debuffs, and combat situation to make optimal ability suggestions.

### Can I customize the rotation priorities?
Yes, WindrunnerRotations offers several layers of customization:
1. Built-in settings for each specialization
2. Advanced Ability Control for fine-tuning specific abilities
3. Action Priority List (APL) system for creating custom priority logic

### What is the difference between the built-in rotations and the APL system?
The built-in rotations are pre-configured and optimized for general use, while the APL system allows you to create custom priority lists with your own logic and conditions.

### How do I use the Rotation Simulator?
Type `/wrsim` to access the simulator. Select your class and specialization, adjust the parameters, and click "Start Simulation." After the simulation completes, you'll receive a detailed report on the performance.

### How do I use the Performance Tracker?
Type `/wrperf` to access the Performance Tracker. You can enable the overlay during combat to see real-time performance metrics, and view detailed reports after combat ends.

### How do I use the Talent Loadout Manager?
Type `/wrtalent` to access the Talent Loadout Manager. You can import talent builds using strings, export your current build, and see recommended builds for your specialization.

## Troubleshooting

### The rotation isn't working at all. What should I check?
1. Ensure the addon is enabled in your addon list
2. Make sure the rotation is toggled on (default key or `/wr toggle`)
3. Check that you don't have conflicting addons
4. Verify you're in the correct specialization
5. Try reloading your UI (`/reload`)

### Why are some abilities not being used correctly?
1. Check your specialization settings to ensure the ability is enabled and configured correctly
2. Verify that your talent build matches the expected abilities
3. Some abilities have specific conditions (like resource thresholds) that must be met
4. Check if the ability is on cooldown or if you lack the necessary resources

### Why is my DPS/HPS lower than expected?
1. Check your gear, as the rotation is optimized for typical endgame gear
2. Verify your talents match recommended builds
3. Adjust resource thresholds and ability priorities in the settings
4. Run a simulation to identify potential issues
5. Check the Performance Tracker for specific suggestions

### The addon is causing lag or frame rate issues. How can I fix it?
1. Reduce the processing frequency in the general settings
2. Disable performance tracking features if not needed
3. Close the configuration UI during combat
4. Disable unnecessary debug options

### I found a bug. How do I report it?
Visit our [GitHub Issues page](https://github.com/VortexQ8/WindrunnerRotations/issues) to report bugs. Please include:
1. Detailed description of the issue
2. Steps to reproduce the problem
3. Your class, specialization, and talent build
4. Any error messages you received
5. Screenshots if applicable

## Advanced Features

### What is the APL (Action Priority List) system?
The APL system is an advanced feature that allows you to create custom priority lists for your rotation. It uses a syntax similar to SimulationCraft's APL to define conditions, actions, and priorities.

### How do I create a custom APL?
1. Open your specialization settings
2. Go to the APL tab
3. Click "Create New APL"
4. Define your conditions and actions using the APL syntax
5. Save and enable your custom APL

### Can I share APLs with other players?
Yes, you can export your APLs as strings and share them with other WindrunnerRotations users. They can import them through their APL settings page.

### What is the difference between the Rotation Simulator and real gameplay?
The Rotation Simulator provides a controlled environment to test rotations without variables like player reaction time, latency, and unexpected combat events. It's useful for comparing theoretical performance, but real gameplay will always have additional factors to consider.

### How can I contribute to WindrunnerRotations?
1. Join our community on [Discord](https://discord.gg/windrunnerrotations)
2. Report bugs and suggest features on [GitHub](https://github.com/VortexQ8/WindrunnerRotations)
3. If you're a developer, check out our [Developer Guide](./DeveloperGuide.md) to contribute code
4. Share your custom APLs and settings with the community

## Class-Specific Questions

### How does WindrunnerRotations handle tank specializations?
Tank specializations focus on survival, threat generation, and active mitigation rather than pure DPS. WindrunnerRotations balances defensive cooldowns, active mitigation abilities, and damage output to maintain optimal survivability while keeping sufficient threat.

### How does WindrunnerRotations handle healing specializations?
Healing specializations prioritize efficient healing, mana management, and smart target selection. The addon uses sophisticated logic to select the appropriate healing spells based on incoming damage patterns, target health percentages, and available resources.

### Does WindrunnerRotations support hybrid playstyles (e.g., DPS while healing)?
Yes, many specializations have settings to balance DPS and support capabilities. For example, healers can configure the addon to weave damage spells when healing isn't immediately required.

### How often are the rotations updated for new patches and balance changes?
We aim to update WindrunnerRotations within 1-2 weeks of major patch releases and balance changes. Minor updates happen more frequently to address bugs and optimize performance.

## Technical Questions

### Does WindrunnerRotations affect game performance?
WindrunnerRotations is designed to be lightweight, but like any addon, it uses some system resources. The impact is minimal for most systems, but users with lower-end computers can adjust settings to reduce processing frequency.

### How much memory does WindrunnerRotations use?
Typically, WindrunnerRotations uses 5-15MB of memory, depending on your enabled features and class modules.

### Can I use WindrunnerRotations with ElvUI or other UI overhauls?
Yes, WindrunnerRotations is compatible with most UI overhaul addons including ElvUI, Tukui, and others.

### Does WindrunnerRotations work with controller addons like ConsolePort?
Yes, WindrunnerRotations can be used alongside controller addons. You might need to adjust keybindings to match your controller setup.

### How does WindrunnerRotations detect enemy count for AoE situations?
WindrunnerRotations uses a combination of the game's nameplate system, combat log analysis, and targeted API functions to detect enemies around your character.

### Does WindrunnerRotations work in PvP?
WindrunnerRotations can be used in PvP, but it's primarily optimized for PvE content. PvP requires situational awareness and quick adaptation that automated systems can't always provide optimally.

## Miscellaneous

### Is WindrunnerRotations free to use?
Yes, WindrunnerRotations is completely free and open-source.

### Where can I find more help and support?
Join our [Discord community](https://discord.gg/windrunnerrotations) for help, suggestions, and discussions with other users and developers.

### Can I request a feature or improvement?
Absolutely! Please submit feature requests on our [GitHub Issues page](https://github.com/VortexQ8/WindrunnerRotations/issues) or discuss them in our Discord community.

### Does WindrunnerRotations collect any personal data?
No, WindrunnerRotations doesn't collect or transmit any personal data. All settings and configurations are stored locally on your computer.

### Who created WindrunnerRotations?
WindrunnerRotations was created by VortexQ8 with contributions from many talented developers and theorycrafters in the World of Warcraft community.