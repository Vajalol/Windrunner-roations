# Evoker Class Guide - WindrunnerRotations

## Overview

The Evoker is a versatile hero class introduced in Dragonflight, capable of ranged damage dealing (Devastation), healing (Preservation), and support (Augmentation). This guide covers all three specializations and explains how WindrunnerRotations optimizes your gameplay with each spec.

## Specializations

### Devastation (DPS)

Devastation Evokers are ranged spellcasters who wield the destructive powers of the red and blue dragonflights, focusing on fire and arcane damage. Their unique Empowered spells mechanic allows for charging abilities for greater effect.

### Preservation (Healer)

Preservation Evokers harness the life-giving magic of the green dragonflight to heal and protect allies. They utilize Empowered healing spells and various damage mitigation abilities to keep their group alive.

### Augmentation (Support DPS)

Augmentation Evokers tap into the bronze dragonflight's temporal magic to enhance their allies' capabilities while dealing damage themselves. They focus on providing powerful buffs and utility while maintaining respectable personal damage output.

## Key Resources and Mechanics

### Essence

Essence is the Evoker's primary resource, used for most abilities. It has the following characteristics:
- Maximum of 6 Essence
- Regenerates over time (approximately 1 Essence every 5 seconds)
- Some abilities generate Essence (like Living Flame)
- Main spenders include Azure Strike, Fire Breath, and various empowered spells

### Empowered Spells

Empowered spells are unique to Evokers, allowing you to charge the spell for greater effect:
- Hold the key to empower, release to cast
- Four empowerment levels (including no empowerment)
- Longer cast time with higher empowerment
- WindrunnerRotations automatically determines optimal empowerment levels

## Devastation Specialization

### Strengths
- Strong burst damage with cooldowns
- Good AoE capabilities
- Unique Empowered spell mechanic
- Solid raid utility

### Weaknesses
- Limited mobility during casting
- Requires planning for Empowered spells
- Resource management can be challenging

### Core Abilities

| Ability | Description | Usage |
|---------|-------------|-------|
| Living Flame | Single target damage/healing, generates Essence | Filler and Essence generator |
| Fire Breath | Empowered frontal cone damage | Primary AoE and Empowered spender |
| Azure Strike | Direct damage, consumes Essence | Primary single-target spender |
| Disintegrate | Channeled single-target damage | Used for sustained damage |
| Eternity Surge | Empowered line AoE damage | Major cooldown for multiple targets |
| Deep Breath | Large AoE damage from above | Major cooldown for AoE situations |
| Dragonrage | Major cooldown increasing damage | Used during burst windows |
| Fire Quake | Empowered AoE damage and DoT | AoE damage with DoT component |
| Pyre | Instant targeted AoE | Used for mobile AoE damage |

### Talent Priorities

Key talents that WindrunnerRotations optimizes for:
- Catalytic Recovery (Essence generation)
- Power Swell (Essence generation)
- Tyranny (Dragonrage enhancement)
- Eternality (improves Eternity Surge)
- Arcane Vigor (critical strike buff)
- Scintillation (Essence generation)
- Causality (improves Fire Breath)

### Rotation Strategy

WindrunnerRotations implements the following rotation priorities for Devastation:

#### Cooldowns
1. Dragonrage during burst phases
2. Tip the Scales before major Empowered spells
3. Fire/Storm/Emerald Devastation when available

#### Single Target
1. Maintain Essence Burst and other procs
2. Azure Strike as main Essence spender
3. Living Flame as filler/generator
4. Disintegrate when available
5. Empowered Fire Breath at optimal times
6. Shattering Star during Dragonrage

#### AoE Rotation
1. Empowered Fire Breath at high empower level
2. Fire Quake for multiple targets
3. Pyre during movement
4. Deep Breath when available
5. Azure Strike as Essence dump

### Configuration Options

In WindrunnerRotations, you can configure:
- Empowerment levels for each Empowered spell
- Essence management threshold
- Cooldown usage strategy
- AoE detection threshold
- Tip the Scales usage priority

## Preservation Specialization

### Strengths
- Strong burst healing
- Unique Empowered healing spells
- Good damage mitigation
- Versatile healing toolkit

### Weaknesses
- Healing over time management
- Positioning for Empowered spells
- Resource management

### Core Abilities

| Ability | Description | Usage |
|---------|-------------|-------|
| Living Flame | Single target damage/healing | Filler healing and DPS |
| Emerald Breath | Empowered cone healing with HoT | Primary group healing |
| Dream Breath | Empowered cone healing with DR | Used for damage reduction |
| Reversion | Empowered targeted healing | Single target healing |
| Spiritbloom | Empowered multi-target healing | Burst multi-target healing |
| Verdant Embrace | Targeted healing with HoT | Used on tanks or injured allies |
| Echo | Shield on low health targets | Automatic when targets get low |
| Time Dilation | Extends HoTs on target | Used to extend key HoTs |
| Rewind | Emergency healing cooldown | Used on critically low health targets |

### Talent Priorities

Key talents that WindrunnerRotations optimizes for:
- Spark of Life (Living Flame healing boost)
- Resonating Sphere (Echo enhancement)
- Lifebind (healing increase)
- Renewal (HoT enhancement)
- Temporal Anomaly (Cooldown reduction chance)
- Innate Resolve (Damage reduction)
- Emerald Communion (Mana regeneration)

### Rotation Strategy

WindrunnerRotations implements the following rotation priorities for Preservation:

#### Cooldowns
1. Tip the Scales for emergency empowered healing
2. Rewind for critically low health targets
3. Emerald Communion for mana regeneration
4. Time Dilation to extend HoTs on tanks

#### Single Target Healing
1. Verdant Embrace on tanks and injured targets
2. Reversion for efficient direct healing
3. Living Flame for light healing and Essence generation
4. Echo automatically applied to low health targets

#### Group Healing
1. Emerald Breath for group healing with HoTs
2. Dream Breath for group healing with DR
3. Spiritbloom for burst group healing
4. Chain Heal in specific situations

### Configuration Options

In WindrunnerRotations, you can configure:
- Health thresholds for different healing priorities
- Empowerment levels for each Empowered spell
- Cooldown usage strategy
- Essence management threshold
- HoT maintenance priority

## Augmentation Specialization

### Strengths
- Unique support capabilities
- Strong group buffs
- Good personal damage
- Versatile utility toolkit

### Weaknesses
- Complex optimization
- Team coordination dependent
- Buff maintenance

### Core Abilities

| Ability | Description | Usage |
|---------|-------------|-------|
| Living Flame | Single target damage/healing | Filler damage and Essence generator |
| Fire Breath | Empowered frontal cone damage | Primary AoE damage |
| Azure Strike | Direct damage, consumes Essence | Primary single-target spender |
| Disintegrate | Channeled single-target damage | Used for sustained damage |
| Ebon Might | Grants strength/agility/intellect | Applied to primary damage dealers |
| Breath of Eons | Group-wide haste buff | Used during burst windows |
| Prescience | Target damage and critical strike buff | Applied to top DPS |
| Source of Magic | Increases target's mana regen | Applied to healers |
| Time Spiral | Group-wide cooldown reduction | Used during burst phases |
| Bronze Flight | Group-wide movement speed | Used for mobility phases |

### Talent Priorities

Key talents that WindrunnerRotations optimizes for:
- Temporal Compression (Time Spiral enhancement)
- Eventide (improves Ebon Might)
- Font of Magic (Cooldown reduction)
- Blistering Scales (damage enhancement)
- Even Hand (buff extension)
- Timeless Magic (extends buff durations)
- Infernium (Fire Breath enhancement)

### Rotation Strategy

WindrunnerRotations implements the following rotation priorities for Augmentation:

#### Buffs Management
1. Ebon Might on top DPS (prioritizing melee)
2. Prescience on top DPS (or tanks if no better targets)
3. Source of Magic on healers
4. Breath of Eons during burst windows
5. Time Spiral during major cooldowns

#### Damage Rotation
1. Keep Nether Tempest active on primary target
2. Azure Strike as main Essence spender
3. Living Flame as filler/generator
4. Disintegrate when available
5. Empowered Fire Breath for multiple targets
6. Upheaval for additional damage

### Configuration Options

In WindrunnerRotations, you can configure:
- Buff priority targets (melee vs. ranged)
- Empowerment levels for each Empowered spell
- Essence management threshold
- Cooldown usage strategy
- AoE detection threshold

## Best-in-Slot Gear and Stats

### Devastation

**Stat Priority**:
1. Intellect
2. Haste (to comfort level, ~20-30%)
3. Critical Strike
4. Mastery
5. Versatility

**Best Enchants and Gems**:
- Enchant Chest: Writ of Critical Strike
- Enchant Boots: Writ of Speed
- Enchant Weapon: Sophic Devotion
- Gems: Quick Ysemerald

### Preservation

**Stat Priority**:
1. Intellect
2. Haste (to comfort level, ~15-25%)
3. Mastery
4. Critical Strike
5. Versatility

**Best Enchants and Gems**:
- Enchant Chest: Writ of Mastery
- Enchant Boots: Writ of Speed
- Enchant Weapon: Sophic Devotion
- Gems: Quick Ysemerald / Keen Ysemerald

### Augmentation

**Stat Priority**:
1. Intellect
2. Haste
3. Critical Strike
4. Versatility
5. Mastery

**Best Enchants and Gems**:
- Enchant Chest: Writ of Critical Strike
- Enchant Boots: Writ of Speed
- Enchant Weapon: Sophic Devotion
- Gems: Quick Ysemerald

## Raid and Dungeon Tips

### Raid Tips
- Use Blessing of the Bronze for pre-pull preparation
- Time your Dragonrage (Devastation) or major cooldowns with raid damage phases
- Coordinate Time Dilation (Preservation) with other healers' cooldowns
- Position carefully for Empowered cone spells
- Use defensive abilities like Obsidian Scales proactively
- Coordinate Breath of Eons and Time Spiral (Augmentation) with raid cooldowns

### Mythic+ Tips
- Use Cauterizing Flame to dispel Curses, Poisons, and Diseases
- Save Tip the Scales for critical moments
- Use Oppressing Roar to control enemy spell casts
- Utilize Rescue to save allies from dangerous mechanics
- Time Dream Flight (Preservation) for heavy damage phases
- Apply Ebon Might and Prescience (Augmentation) strategically based on pull size

## WindrunnerRotations Key Bindings

To get the most out of WindrunnerRotations on your Evoker, configure these recommended keybindings:

- Toggle Main Rotation: Bound to a convenient key
- AoE Mode Toggle: For manually switching to AoE priorities
- Cooldown Mode Toggle: To control major cooldown usage
- Manual Empowerment Override: For situations requiring manual control
- Pause Rotation: For moments requiring full manual control

## Macro Recommendations

### All Specs
```
#showtooltip
/cast [@cursor] Hover
```

```
#showtooltip
/cast [@mouseover,help,nodead][@player] Rescue
```

### Devastation
```
#showtooltip
/cast [mod:shift,@cursor] Fire Quake; Dragonrage
```

### Preservation
```
#showtooltip
/cast [@mouseover,help,nodead][@player] Reversion
```

```
#showtooltip
/cast [@mouseover,help,nodead][@player] Verdant Embrace
```

### Augmentation
```
#showtooltip
/cast [@mouseover,help,nodead][@player] Ebon Might
```

```
#showtooltip
/cast [@mouseover,help,nodead][@player] Prescience
```

## Troubleshooting

### Common Issues

**Empowered Spells Not Casting Correctly**:
- Check your latency; high latency can affect Empowered spell release timing
- Adjust the empowerment level settings in the WindrunnerRotations configuration
- Ensure you're not moving when releasing the spell, as this can cancel casting

**Resource Management Problems**:
- Adjust the Essence conservation threshold in settings
- Enable "Conservative" Essence management for more generator usage
- Check your Haste levels; low Haste can affect Essence regeneration

**Buff Application Issues (Augmentation)**:
- Verify target priority settings
- Check range to targets; many buffs have limited range
- Adjust buff refresh thresholds in settings

### Class-Specific Settings

For optimal performance, make these adjustments in the WindrunnerRotations configuration:

- **Empowerment Settings**: Set your preferred empowerment levels or use "Situational" for adaptive empowerment
- **Target Detection**: Configure the AoE target threshold to match your content (3-4 for M+, 5+ for raids)
- **Cooldown Management**: Choose between on-cooldown usage or saving for specific scenarios
- **Buff Priorities**: For Augmentation, set your preferred targets for each buff
- **Healing Thresholds**: For Preservation, adjust health percentage thresholds for different healing priorities

## Conclusion

The Evoker offers three distinct playstyles with unique mechanics not found on other classes. WindrunnerRotations helps you master these mechanics by automating the optimal usage of abilities while giving you control over key strategic decisions.

For further assistance, refer to the main [User Manual](../UserManual.md) or join our community Discord for class-specific discussions and the latest optimizations.