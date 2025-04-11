------------------------------------------
-- WindrunnerRotations - Frost Death Knight Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Frost = {}
-- This will be assigned to addon.Classes.DeathKnight.Frost when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local DeathKnight

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentRunicPower = 0
local maxRunicPower = 100
local currentRunes = 0
local maxRunes = 6
local killingMachineActive = false
local killingMachineEndTime = 0
local pillarOfFrostActive = false
local pillarOfFrostEndTime = 0
local breathOfSindragosaActive = false
local breathOfSindragosaEndTime = 0
local remorselessWinterActive = false
local remorselessWinterEndTime = 0
local iceCapActive = false
local iceCapStacks = 0
local iceCapEndTime = 0
local unholyStrengthActive = false
local unholyStrengthEndTime = 0
local frostFeverActive = false
local frostFeverEndTime = 0
local obliterationActive = false
local obliterationEndTime = 0
local icyTalonsActive = false
local icyTalonsStacks = 0
local icyTalonsEndTime = 0
local darkSuccorActive = false
local darkSuccorEndTime = 0
local empower1Active = false
local empower2Active = false
local empower3Active = false
local empowerRuneWeaponActive = false
local empowerRuneWeaponEndTime = 0
local chillStreakChargeable = false
local razoriceBuff = 0
local razoriceFrostweaponStacks = 0
local reaperBuff = false
local reaperEndTime = 0
local reaperBuffStacks = 0
local coldHeartStacks = 0
local coldHeartActive = false
local coldHeartEndTime = 0
local unholyBondActive = false
local glacialAdvanceStacks = 0
local furiousBlow = false
local frostStrike = false
local frostScythe = false
local frozenPulse = false
local inMeleeRange = false
local boneBound = false
local unleashed = false
local breathOfWinter = false
local rimedeath = false
local cleavingStrikesActive = false
local rime = false
local icecap = false
local obliteration = false
local glacialAdvance = false
local asphyxiate = false
local improvedDeathStrike = false
local freezingStrike = false
local snowblind = false
local improvedBreathOfSindragosa = false
local resonateAttacks = false
local iceFloes = false

-- Constants
local FROST_SPEC_ID = 251
local DEFAULT_AOE_THRESHOLD = 3
local PILLAR_OF_FROST_DURATION = 12 -- seconds
local REMORSELESS_WINTER_DURATION = 8 -- seconds
local UNHOLY_STRENGTH_DURATION = 15 -- seconds
local FROST_FEVER_DURATION = 24 -- seconds
local OBLITERATION_DURATION = 8 -- seconds
local EMPOWER_RUNE_WEAPON_DURATION = 20 -- seconds
local ICY_TALONS_DURATION = 6 -- seconds
local BREATH_OF_SINDRAGOSA_DURATION = 20 -- seconds (can end earlier due to resource)
local MELEE_RANGE = 5 -- yards

-- Initialize the Frost module
function Frost:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Frost Death Knight module initialized")
    
    return true
end

-- Register spell IDs
function Frost:RegisterSpells()
    -- Core rotational abilities
    spells.FROST_STRIKE = 49143
    spells.OBLITERATE = 49020
    spells.HOWLING_BLAST = 49184
    spells.REMORSELESS_WINTER = 196770
    spells.FROSTSCYTHE = 207230
    spells.GLACIAL_ADVANCE = 194913
    spells.PILLAR_OF_FROST = 51271
    spells.BREATH_OF_SINDRAGOSA = 152279
    spells.HORN_OF_WINTER = 57330
    spells.EMPOWER_RUNE_WEAPON = 47568
    spells.CHAINS_OF_ICE = 45524
    spells.DEATH_STRIKE = 49998
    spells.CHILL_STREAK = 305392
    spells.FROSTWYRMS_FURY = 279302
    
    -- Core utilities
    spells.ANTI_MAGIC_SHELL = 48707
    spells.ICEBOUND_FORTITUDE = 48792
    spells.DEATH_GRIP = 49576
    spells.WRAITH_WALK = 212552
    spells.DEATH_AND_DECAY = 43265
    spells.DEATH_GATE = 50977
    spells.PATH_OF_FROST = 3714
    spells.MIND_FREEZE = 47528
    spells.CONTROL_UNDEAD = 111673
    
    -- Talents and passives
    spells.KILLING_MACHINE = 51124
    spells.OBLITERATION = 281238
    spells.COLD_HEART = 281208
    spells.ICECAP = 207126
    spells.AVALANCHE = 207142
    spells.FROZEN_PULSE = 194909
    spells.MURDEROUS_EFFICIENCY = 207061
    spells.HORN_OF_WINTER = 57330
    spells.RUNIC_ATTENUATION = 207104
    spells.GATHERING_STORM = 194912
    spells.FROSTSCYTHE = 207230
    spells.GLACIAL_ADVANCE = 194913
    spells.FREEZING_FOG = 207060
    spells.ICY_TALONS = 194878
    spells.BREATH_OF_SINDRAGOSA = 152279
    spells.EVERFROST = 376938
    spells.BREATH_OF_WINTER = 389041
    spells.RIMEDEATH = 388178
    spells.CLEAVING_STRIKES = 316916
    spells.MIGHT_OF_THE_FROZEN_WASTES = 81333
    spells.UNLEASHED_FRENZY = 376905
    spells.ASPHYXIATE = 221562
    spells.BLINDING_SLEET = 207167
    spells.PERMAFROST = 207200
    spells.DEATH_PACT = 48743
    spells.SOUL_REAPER = 343294
    spells.IMPROVED_DEATH_STRIKE = 374277
    spells.FREEZING_STRIKE = 406263
    spells.SNOWBLIND = 374144
    spells.IMPROVED_BREATH_OF_SINDRAGOSA = 374311
    spells.RESONATE_ATTACKS = 374257
    spells.ICE_FLOES = 383300
    
    -- War Within Season 2 specific
    spells.ABSOLUTE_ZERO = 377047
    spells.BONEGRINDS_FRENZY = 377488
    spells.COLD_HEART_TALENT = 377047
    spells.FRIGID_EXECUTIONER = 377073
    spells.FUSILLADE = 377430
    spells.GLACIAL_MULTIPLIER = 374535
    spells.GLACIAL_FANG = 378588
    spells.MERCILESS_STRIKES = 374504
    spells.NOXIOUS_BLIGHT = 377591
    spells.RAGE_AMPLIFICATION = 377657
    spells.RAGE_EXTRACTOR = 377648
    spells.UNHOLY_BOND = 377468
    spells.FROZEN_HEART = 401011

    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.SWARMING_MIST = 311648
    spells.ABOMINATION_LIMB = 315443
    spells.SHACKLE_THE_UNWORTHY = 312202
    spells.DEATHS_DUE = 324128
    
    -- Buff IDs
    spells.KILLING_MACHINE_BUFF = 51124
    spells.PILLAR_OF_FROST_BUFF = 51271
    spells.BREATH_OF_SINDRAGOSA_BUFF = 152279
    spells.REMORSELESS_WINTER_BUFF = 196770
    spells.ICECAP_BUFF = 207126
    spells.UNHOLY_STRENGTH_BUFF = 53365
    spells.OBLITERATION_BUFF = 281238
    spells.ICY_TALONS_BUFF = 194879
    spells.DARK_SUCCOR_BUFF = 101568
    spells.EMPOWER_RUNE_WEAPON_BUFF = 47568
    spells.COLD_HEART_BUFF = 281209
    spells.UNLEASHED_FRENZY_BUFF = 376904
    spells.RAZORICE_BUFF = 51714
    spells.REAPER_BUFF = 253597
    spells.UNHOLY_BOND_BUFF = 377469
    
    -- Debuff IDs
    spells.FROST_FEVER_DEBUFF = 55095
    spells.RAZORICE_DEBUFF = 51714
    spells.MARK_OF_FYRALATH_DEBUFF = 414662
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.KILLING_MACHINE = spells.KILLING_MACHINE_BUFF
    buffs.PILLAR_OF_FROST = spells.PILLAR_OF_FROST_BUFF
    buffs.BREATH_OF_SINDRAGOSA = spells.BREATH_OF_SINDRAGOSA_BUFF
    buffs.REMORSELESS_WINTER = spells.REMORSELESS_WINTER_BUFF
    buffs.ICECAP = spells.ICECAP_BUFF
    buffs.UNHOLY_STRENGTH = spells.UNHOLY_STRENGTH_BUFF
    buffs.OBLITERATION = spells.OBLITERATION_BUFF
    buffs.ICY_TALONS = spells.ICY_TALONS_BUFF
    buffs.DARK_SUCCOR = spells.DARK_SUCCOR_BUFF
    buffs.EMPOWER_RUNE_WEAPON = spells.EMPOWER_RUNE_WEAPON_BUFF
    buffs.COLD_HEART = spells.COLD_HEART_BUFF
    buffs.UNLEASHED_FRENZY = spells.UNLEASHED_FRENZY_BUFF
    buffs.RAZORICE = spells.RAZORICE_BUFF
    buffs.REAPER = spells.REAPER_BUFF
    buffs.UNHOLY_BOND = spells.UNHOLY_BOND_BUFF
    
    debuffs.FROST_FEVER = spells.FROST_FEVER_DEBUFF
    debuffs.RAZORICE = spells.RAZORICE_DEBUFF
    debuffs.MARK_OF_FYRALATH = spells.MARK_OF_FYRALATH_DEBUFF
    
    return true
end

-- Register variables to track
function Frost:RegisterVariables()
    -- Talent tracking
    talents.hasKillingMachine = false
    talents.hasObliteration = false
    talents.hasColdHeart = false
    talents.hasIcecap = false
    talents.hasAvalanche = false
    talents.hasFrozenPulse = false
    talents.hasMurderousEfficiency = false
    talents.hasHornOfWinter = false
    talents.hasRunicAttenuation = false
    talents.hasGatheringStorm = false
    talents.hasFrostscythe = false
    talents.hasGlacialAdvance = false
    talents.hasFreezingFog = false
    talents.hasIcyTalons = false
    talents.hasBreathOfSindragosa = false
    talents.hasEverfrost = false
    talents.hasBreathOfWinter = false
    talents.hasRimedeath = false
    talents.hasCleavingStrikes = false
    talents.hasMightOfTheFrozenWastes = false
    talents.hasUnleashedFrenzy = false
    talents.hasAsphyxiate = false
    talents.hasBlindingSleet = false
    talents.hasPermafrost = false
    talents.hasDeathPact = false
    talents.hasSoulReaper = false
    talents.hasImprovedDeathStrike = false
    talents.hasFreezingStrike = false
    talents.hasSnowblind = false
    talents.hasImprovedBreathOfSindragosa = false
    talents.hasResonateAttacks = false
    talents.hasIceFloes = false
    
    -- War Within Season 2 talents
    talents.hasAbsoluteZero = false
    talents.hasBonegrindsFrenzy = false
    talents.hasColdHeartTalent = false
    talents.hasFrigidExecutioner = false
    talents.hasFusillade = false
    talents.hasGlacialMultiplier = false
    talents.hasGlacialFang = false
    talents.hasMercilessStrikes = false
    talents.hasNoxiousBlight = false
    talents.hasRageAmplification = false
    talents.hasRageExtractor = false
    talents.hasUnholyBond = false
    talents.hasFrozenHeart = false
    
    -- Initialize resources
    currentRunicPower = API.GetPlayerPower()
    currentRunes = API.GetPlayerRunes()
    
    return true
end

-- Register spec-specific settings
function Frost:RegisterSettings()
    ConfigRegistry:RegisterSettings("FrostDeathKnight", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst damage",
                type = "toggle",
                default = true
            },
            aoeEnabled = {
                displayName = "Enable AoE Rotation",
                description = "Use area damage abilities when multiple targets are present",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Target Threshold",
                description = "Minimum number of targets to use AoE abilities",
                type = "slider",
                min = 2,
                max = 8,
                default = DEFAULT_AOE_THRESHOLD
            },
            killingMachineStrategy = {
                displayName = "Killing Machine Strategy",
                description = "How to utilize Killing Machine procs",
                type = "dropdown",
                options = {"Always Obliterate", "Prioritize Frostscythe in AoE", "Always Frostscythe in AoE"},
                default = "Prioritize Frostscythe in AoE"
            },
            runePowerSavingThreshold = {
                displayName = "Runic Power Saving Threshold",
                description = "Runic Power to save during Breath of Sindragosa",
                type = "slider",
                min = 15,
                max = 60,
                default = 40
            },
            useRemorselessWinter = {
                displayName = "Use Remorseless Winter",
                description = "When to use Remorseless Winter",
                type = "dropdown",
                options = {"On Cooldown", "AoE Only", "Never"},
                default = "On Cooldown"
            },
            useChainsOfIce = {
                displayName = "Use Chains of Ice",
                description = "When to use Chains of Ice with Cold Heart",
                type = "dropdown",
                options = {"On Max Stacks", "With Pillar of Frost", "Manual Only"},
                default = "With Pillar of Frost"
            }
        },
        
        defensiveSettings = {
            useAntiMagicShell = {
                displayName = "Use Anti-Magic Shell",
                description = "Automatically use Anti-Magic Shell",
                type = "toggle",
                default = true
            },
            useIceboundFortitude = {
                displayName = "Use Icebound Fortitude",
                description = "Automatically use Icebound Fortitude",
                type = "toggle",
                default = true
            },
            iceboundFortitudeThreshold = {
                displayName = "Icebound Fortitude Health Threshold",
                description = "Health percentage to use Icebound Fortitude",
                type = "slider",
                min = 20,
                max = 80,
                default = 40
            },
            useDeathStrike = {
                displayName = "Use Death Strike",
                description = "Automatically use Death Strike for healing",
                type = "toggle",
                default = true
            },
            deathStrikeThreshold = {
                displayName = "Death Strike Health Threshold",
                description = "Health percentage to use Death Strike",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useDeathPact = {
                displayName = "Use Death Pact",
                description = "Automatically use Death Pact when talented",
                type = "toggle",
                default = true
            },
            deathPactThreshold = {
                displayName = "Death Pact Health Threshold",
                description = "Health percentage to use Death Pact",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            }
        },
        
        offensiveSettings = {
            usePillarOfFrost = {
                displayName = "Use Pillar of Frost",
                description = "Automatically use Pillar of Frost",
                type = "toggle",
                default = true
            },
            useObliteration = {
                displayName = "Use Obliteration",
                description = "Automatically use Obliteration when talented",
                type = "toggle",
                default = true
            },
            useBreathOfSindragosa = {
                displayName = "Use Breath of Sindragosa",
                description = "Automatically use Breath of Sindragosa when talented",
                type = "toggle",
                default = true
            },
            breathOfSindragosaStartThreshold = {
                displayName = "Breath of Sindragosa Start Threshold",
                description = "Runic Power to start Breath of Sindragosa",
                type = "slider",
                min = 60,
                max = 100,
                default = 80
            },
            useEmpowerRuneWeapon = {
                displayName = "Use Empower Rune Weapon",
                description = "When to use Empower Rune Weapon",
                type = "dropdown",
                options = {"On Cooldown", "With Pillar of Frost", "With BoS", "Emergency Only"},
                default = "With Pillar of Frost"
            },
            useHornOfWinter = {
                displayName = "Use Horn of Winter",
                description = "Automatically use Horn of Winter when talented",
                type = "toggle",
                default = true
            },
            useFrostwyrmsFury = {
                displayName = "Use Frostwyrm's Fury",
                description = "Automatically use Frostwyrm's Fury",
                type = "toggle",
                default = true
            },
            frostwyrmsFuryStrategy = {
                displayName = "Frostwyrm's Fury Strategy",
                description = "When to use Frostwyrm's Fury",
                type = "dropdown",
                options = {"With Pillar of Frost", "AoE Only", "On Cooldown"},
                default = "With Pillar of Frost"
            },
            useChillStreak = {
                displayName = "Use Chill Streak",
                description = "Automatically use Chill Streak when talented",
                type = "toggle",
                default = true
            },
            chillStreakMinTargets = {
                displayName = "Chill Streak Min Targets",
                description = "Minimum targets to use Chill Streak",
                type = "slider",
                min = 1,
                max = 6,
                default = 2
            }
        },
        
        utilitySettings = {
            useDeathGrip = {
                displayName = "Use Death Grip",
                description = "Automatically use Death Grip for utility",
                type = "toggle",
                default = true
            },
            useWraithWalk = {
                displayName = "Use Wraith Walk",
                description = "Automatically use Wraith Walk for mobility",
                type = "toggle",
                default = true
            },
            useDeathAndDecay = {
                displayName = "Use Death and Decay",
                description = "When to use Death and Decay",
                type = "dropdown",
                options = {"AoE Only", "Always", "Never"},
                default = "AoE Only"
            },
            useAsphyxiate = {
                displayName = "Use Asphyxiate",
                description = "Automatically use Asphyxiate when talented",
                type = "toggle",
                default = true
            },
            useBlindingSleet = {
                displayName = "Use Blinding Sleet",
                description = "Automatically use Blinding Sleet when talented",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            runicPowerPooling = {
                displayName = "Runic Power Pooling",
                description = "Save Runic Power for higher priority abilities",
                type = "toggle",
                default = true
            },
            minRunicPowerPool = {
                displayName = "Minimum Runic Power Pool",
                description = "Minimum Runic Power to maintain for Frost Strike",
                type = "slider",
                min = 0,
                max = 80,
                default = 30
            },
            maintainRuneBuffer = {
                displayName = "Maintain Rune Buffer",
                description = "Maintain this many runes as buffer",
                type = "slider",
                min = 0,
                max = 3,
                default = 1
            },
            delayKillingMachineConsumption = {
                displayName = "Delay Killing Machine",
                description = "Wait for more runes to use Killing Machine efficiently",
                type = "toggle",
                default = true
            },
            useObliterateOnlyWithRimes = {
                displayName = "Obliterate Only With Rime",
                description = "Prioritize Obliterate primarily when Rime is active",
                type = "toggle",
                default = false
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Pillar of Frost controls
            pillarOfFrost = AAC.RegisterAbility(spells.PILLAR_OF_FROST, {
                enabled = true,
                useDuringBurstOnly = false,
                minRunicPower = 30
            }),
            
            -- Breath of Sindragosa controls
            breathOfSindragosa = AAC.RegisterAbility(spells.BREATH_OF_SINDRAGOSA, {
                enabled = true,
                useDuringBurstOnly = true,
                minRunicPower = 80
            }),
            
            -- Obliteration controls
            obliteration = AAC.RegisterAbility(spells.OBLITERATION, {
                enabled = true,
                useDuringBurstOnly = true,
                useDuringPillarOfFrost = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Frost:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for runic power updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "RUNIC_POWER" then
            self:UpdateRunicPower()
        end
    end)
    
    -- Register for rune updates
    API.RegisterEvent("RUNE_POWER_UPDATE", function(runeIndex, isEnergize) 
        self:UpdateRunes()
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    return true
end

-- Update talent information
function Frost:UpdateTalentInfo()
    -- Check for important talents
    talents.hasKillingMachine = API.HasTalent(spells.KILLING_MACHINE)
    talents.hasObliteration = API.HasTalent(spells.OBLITERATION)
    talents.hasColdHeart = API.HasTalent(spells.COLD_HEART)
    talents.hasIcecap = API.HasTalent(spells.ICECAP)
    talents.hasAvalanche = API.HasTalent(spells.AVALANCHE)
    talents.hasFrozenPulse = API.HasTalent(spells.FROZEN_PULSE)
    talents.hasMurderousEfficiency = API.HasTalent(spells.MURDEROUS_EFFICIENCY)
    talents.hasHornOfWinter = API.HasTalent(spells.HORN_OF_WINTER)
    talents.hasRunicAttenuation = API.HasTalent(spells.RUNIC_ATTENUATION)
    talents.hasGatheringStorm = API.HasTalent(spells.GATHERING_STORM)
    talents.hasFrostscythe = API.HasTalent(spells.FROSTSCYTHE)
    talents.hasGlacialAdvance = API.HasTalent(spells.GLACIAL_ADVANCE)
    talents.hasFreezingFog = API.HasTalent(spells.FREEZING_FOG)
    talents.hasIcyTalons = API.HasTalent(spells.ICY_TALONS)
    talents.hasBreathOfSindragosa = API.HasTalent(spells.BREATH_OF_SINDRAGOSA)
    talents.hasEverfrost = API.HasTalent(spells.EVERFROST)
    talents.hasBreathOfWinter = API.HasTalent(spells.BREATH_OF_WINTER)
    talents.hasRimedeath = API.HasTalent(spells.RIMEDEATH)
    talents.hasCleavingStrikes = API.HasTalent(spells.CLEAVING_STRIKES)
    talents.hasMightOfTheFrozenWastes = API.HasTalent(spells.MIGHT_OF_THE_FROZEN_WASTES)
    talents.hasUnleashedFrenzy = API.HasTalent(spells.UNLEASHED_FRENZY)
    talents.hasAsphyxiate = API.HasTalent(spells.ASPHYXIATE)
    talents.hasBlindingSleet = API.HasTalent(spells.BLINDING_SLEET)
    talents.hasPermafrost = API.HasTalent(spells.PERMAFROST)
    talents.hasDeathPact = API.HasTalent(spells.DEATH_PACT)
    talents.hasSoulReaper = API.HasTalent(spells.SOUL_REAPER)
    talents.hasImprovedDeathStrike = API.HasTalent(spells.IMPROVED_DEATH_STRIKE)
    talents.hasFreezingStrike = API.HasTalent(spells.FREEZING_STRIKE)
    talents.hasSnowblind = API.HasTalent(spells.SNOWBLIND)
    talents.hasImprovedBreathOfSindragosa = API.HasTalent(spells.IMPROVED_BREATH_OF_SINDRAGOSA)
    talents.hasResonateAttacks = API.HasTalent(spells.RESONATE_ATTACKS)
    talents.hasIceFloes = API.HasTalent(spells.ICE_FLOES)
    
    -- War Within Season 2 talents
    talents.hasAbsoluteZero = API.HasTalent(spells.ABSOLUTE_ZERO)
    talents.hasBonegrindsFrenzy = API.HasTalent(spells.BONEGRINDS_FRENZY)
    talents.hasColdHeartTalent = API.HasTalent(spells.COLD_HEART_TALENT)
    talents.hasFrigidExecutioner = API.HasTalent(spells.FRIGID_EXECUTIONER)
    talents.hasFusillade = API.HasTalent(spells.FUSILLADE)
    talents.hasGlacialMultiplier = API.HasTalent(spells.GLACIAL_MULTIPLIER)
    talents.hasGlacialFang = API.HasTalent(spells.GLACIAL_FANG)
    talents.hasMercilessStrikes = API.HasTalent(spells.MERCILESS_STRIKES)
    talents.hasNoxiousBlight = API.HasTalent(spells.NOXIOUS_BLIGHT)
    talents.hasRageAmplification = API.HasTalent(spells.RAGE_AMPLIFICATION)
    talents.hasRageExtractor = API.HasTalent(spells.RAGE_EXTRACTOR)
    talents.hasUnholyBond = API.HasTalent(spells.UNHOLY_BOND)
    talents.hasFrozenHeart = API.HasTalent(spells.FROZEN_HEART)
    
    -- Set specialized variables based on talents
    if talents.hasFrozenPulse then
        frozenPulse = true
    end
    
    if talents.hasImprovedDeathStrike then
        improvedDeathStrike = true
    end
    
    if talents.hasFreezingStrike then
        freezingStrike = true
    end
    
    if talents.hasSnowblind then
        snowblind = true
    end
    
    if talents.hasImprovedBreathOfSindragosa then
        improvedBreathOfSindragosa = true
    end
    
    if talents.hasResonateAttacks then
        resonateAttacks = true
    end
    
    if talents.hasIceFloes then
        iceFloes = true
    end
    
    if talents.hasObliteration then
        obliteration = true
    end
    
    if talents.hasGlacialAdvance then
        glacialAdvance = true
    end
    
    if talents.hasAsphyxiate then
        asphyxiate = true
    end
    
    if talents.hasBreathOfWinter then
        breathOfWinter = true
    end
    
    if talents.hasRimedeath then
        rimedeath = true
    end
    
    if talents.hasCleavingStrikes then
        cleavingStrikesActive = true
    end
    
    if talents.hasUnleashedFrenzy then
        unleashed = true
    end
    
    if talents.hasIcecap then
        icecap = true
    end
    
    API.PrintDebug("Frost Death Knight talents updated")
    
    return true
end

-- Update runic power tracking
function Frost:UpdateRunicPower()
    currentRunicPower = API.GetPlayerPower()
    return true
end

-- Update runes tracking
function Frost:UpdateRunes()
    currentRunes = API.GetPlayerRunes()
    return true
end

-- Update target data
function Frost:UpdateTargetData()
    -- Check if in melee range
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Frost Fever
        local ffInfo = API.GetDebuffInfo(targetGUID, debuffs.FROST_FEVER)
        if ffInfo then
            frostFeverActive = true
            frostFeverEndTime = select(6, ffInfo)
        else
            frostFeverActive = false
            frostFeverEndTime = 0
        end
        
        -- Check for Razorice debuff
        local razoriceDInfo = API.GetDebuffInfo(targetGUID, debuffs.RAZORICE)
        if razoriceDInfo then
            razoriceBuff = select(4, razoriceDInfo) or 0
        else
            razoriceBuff = 0
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius
    
    return true
end

-- Handle combat log events
function Frost:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Killing Machine
            if spellID == buffs.KILLING_MACHINE then
                killingMachineActive = true
                killingMachineEndTime = select(6, API.GetBuffInfo("player", buffs.KILLING_MACHINE))
                API.PrintDebug("Killing Machine proc activated")
            end
            
            -- Track Pillar of Frost
            if spellID == buffs.PILLAR_OF_FROST then
                pillarOfFrostActive = true
                pillarOfFrostEndTime = select(6, API.GetBuffInfo("player", buffs.PILLAR_OF_FROST))
                API.PrintDebug("Pillar of Frost activated")
            end
            
            -- Track Breath of Sindragosa
            if spellID == buffs.BREATH_OF_SINDRAGOSA then
                breathOfSindragosaActive = true
                breathOfSindragosaEndTime = select(6, API.GetBuffInfo("player", buffs.BREATH_OF_SINDRAGOSA))
                API.PrintDebug("Breath of Sindragosa activated")
            end
            
            -- Track Remorseless Winter
            if spellID == buffs.REMORSELESS_WINTER then
                remorselessWinterActive = true
                remorselessWinterEndTime = select(6, API.GetBuffInfo("player", buffs.REMORSELESS_WINTER))
                API.PrintDebug("Remorseless Winter activated")
            end
            
            -- Track Icecap
            if spellID == buffs.ICECAP then
                iceCapActive = true
                iceCapStacks = select(4, API.GetBuffInfo("player", buffs.ICECAP)) or 1
                iceCapEndTime = select(6, API.GetBuffInfo("player", buffs.ICECAP))
                API.PrintDebug("Icecap activated: " .. tostring(iceCapStacks) .. " stacks")
            end
            
            -- Track Unholy Strength
            if spellID == buffs.UNHOLY_STRENGTH then
                unholyStrengthActive = true
                unholyStrengthEndTime = select(6, API.GetBuffInfo("player", buffs.UNHOLY_STRENGTH))
                API.PrintDebug("Unholy Strength activated")
            end
            
            -- Track Obliteration
            if spellID == buffs.OBLITERATION then
                obliterationActive = true
                obliterationEndTime = select(6, API.GetBuffInfo("player", buffs.OBLITERATION))
                API.PrintDebug("Obliteration activated")
            end
            
            -- Track Icy Talons
            if spellID == buffs.ICY_TALONS then
                icyTalonsActive = true
                icyTalonsStacks = select(4, API.GetBuffInfo("player", buffs.ICY_TALONS)) or 1
                icyTalonsEndTime = select(6, API.GetBuffInfo("player", buffs.ICY_TALONS))
                API.PrintDebug("Icy Talons activated: " .. tostring(icyTalonsStacks) .. " stacks")
            end
            
            -- Track Dark Succor
            if spellID == buffs.DARK_SUCCOR then
                darkSuccorActive = true
                darkSuccorEndTime = select(6, API.GetBuffInfo("player", buffs.DARK_SUCCOR))
                API.PrintDebug("Dark Succor activated")
            end
            
            -- Track Empower Rune Weapon
            if spellID == buffs.EMPOWER_RUNE_WEAPON then
                empowerRuneWeaponActive = true
                empowerRuneWeaponEndTime = select(6, API.GetBuffInfo("player", buffs.EMPOWER_RUNE_WEAPON))
                API.PrintDebug("Empower Rune Weapon activated")
            end
            
            -- Track Cold Heart
            if spellID == buffs.COLD_HEART then
                coldHeartActive = true
                coldHeartStacks = select(4, API.GetBuffInfo("player", buffs.COLD_HEART)) or 1
                coldHeartEndTime = select(6, API.GetBuffInfo("player", buffs.COLD_HEART))
                API.PrintDebug("Cold Heart stacks: " .. tostring(coldHeartStacks))
            end
            
            -- Track Unleashed Frenzy
            if spellID == buffs.UNLEASHED_FRENZY then
                unleashed = true
                API.PrintDebug("Unleashed Frenzy activated")
            end
            
            -- Track Razorice
            if spellID == buffs.RAZORICE then
                razoriceFrostweaponStacks = select(4, API.GetBuffInfo("player", buffs.RAZORICE)) or 0
                API.PrintDebug("Razorice weapon stacks: " .. tostring(razoriceFrostweaponStacks))
            end
            
            -- Track Reaper buff
            if spellID == buffs.REAPER then
                reaperBuff = true
                reaperBuffStacks = select(4, API.GetBuffInfo("player", buffs.REAPER)) or 1
                reaperEndTime = select(6, API.GetBuffInfo("player", buffs.REAPER))
                API.PrintDebug("Reaper buff activated: " .. tostring(reaperBuffStacks) .. " stacks")
            end
            
            -- Track Unholy Bond
            if spellID == buffs.UNHOLY_BOND then
                unholyBondActive = true
                API.PrintDebug("Unholy Bond activated")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Killing Machine
            if spellID == buffs.KILLING_MACHINE then
                killingMachineActive = false
                API.PrintDebug("Killing Machine consumed")
            end
            
            -- Track Pillar of Frost
            if spellID == buffs.PILLAR_OF_FROST then
                pillarOfFrostActive = false
                API.PrintDebug("Pillar of Frost faded")
            end
            
            -- Track Breath of Sindragosa
            if spellID == buffs.BREATH_OF_SINDRAGOSA then
                breathOfSindragosaActive = false
                API.PrintDebug("Breath of Sindragosa faded")
            end
            
            -- Track Remorseless Winter
            if spellID == buffs.REMORSELESS_WINTER then
                remorselessWinterActive = false
                API.PrintDebug("Remorseless Winter faded")
            end
            
            -- Track Icecap
            if spellID == buffs.ICECAP then
                iceCapActive = false
                iceCapStacks = 0
                API.PrintDebug("Icecap faded")
            end
            
            -- Track Unholy Strength
            if spellID == buffs.UNHOLY_STRENGTH then
                unholyStrengthActive = false
                API.PrintDebug("Unholy Strength faded")
            end
            
            -- Track Obliteration
            if spellID == buffs.OBLITERATION then
                obliterationActive = false
                API.PrintDebug("Obliteration faded")
            end
            
            -- Track Icy Talons
            if spellID == buffs.ICY_TALONS then
                icyTalonsActive = false
                icyTalonsStacks = 0
                API.PrintDebug("Icy Talons faded")
            end
            
            -- Track Dark Succor
            if spellID == buffs.DARK_SUCCOR then
                darkSuccorActive = false
                API.PrintDebug("Dark Succor faded")
            end
            
            -- Track Empower Rune Weapon
            if spellID == buffs.EMPOWER_RUNE_WEAPON then
                empowerRuneWeaponActive = false
                API.PrintDebug("Empower Rune Weapon faded")
            end
            
            -- Track Cold Heart
            if spellID == buffs.COLD_HEART then
                coldHeartActive = false
                coldHeartStacks = 0
                API.PrintDebug("Cold Heart faded")
            end
            
            -- Track Unleashed Frenzy
            if spellID == buffs.UNLEASHED_FRENZY then
                unleashed = false
                API.PrintDebug("Unleashed Frenzy faded")
            end
            
            -- Track Reaper buff
            if spellID == buffs.REAPER then
                reaperBuff = false
                reaperBuffStacks = 0
                API.PrintDebug("Reaper buff faded")
            end
            
            -- Track Unholy Bond
            if spellID == buffs.UNHOLY_BOND then
                unholyBondActive = false
                API.PrintDebug("Unholy Bond faded")
            end
        end
    end
    
    -- Track Icecap stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.ICECAP and destGUID == API.GetPlayerGUID() then
        iceCapStacks = select(4, API.GetBuffInfo("player", buffs.ICECAP)) or 0
        API.PrintDebug("Icecap stacks: " .. tostring(iceCapStacks))
    end
    
    -- Track Icy Talons stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.ICY_TALONS and destGUID == API.GetPlayerGUID() then
        icyTalonsStacks = select(4, API.GetBuffInfo("player", buffs.ICY_TALONS)) or 0
        API.PrintDebug("Icy Talons stacks: " .. tostring(icyTalonsStacks))
    end
    
    -- Track Cold Heart stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.COLD_HEART and destGUID == API.GetPlayerGUID() then
        coldHeartStacks = select(4, API.GetBuffInfo("player", buffs.COLD_HEART)) or 0
        coldHeartActive = true
        API.PrintDebug("Cold Heart stacks: " .. tostring(coldHeartStacks))
    end
    
    -- Track Reaper stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.REAPER and destGUID == API.GetPlayerGUID() then
        reaperBuffStacks = select(4, API.GetBuffInfo("player", buffs.REAPER)) or 0
        API.PrintDebug("Reaper stacks: " .. tostring(reaperBuffStacks))
    end
    
    -- Track Empower Rune Weapon charges
    if eventType == "SPELL_CAST_SUCCESS" and (spellID == spells.EMPOWER_RUNE_WEAPON) then
        empower1Active = true
        
        -- Track for charge management
        C_Timer.After(10, function()
            empower1Active = false
            API.PrintDebug("Empower tier 1 expired")
        end)
        
        C_Timer.After(15, function()
            empower2Active = false
            API.PrintDebug("Empower tier 2 expired")
        end)
        
        C_Timer.After(20, function()
            empower3Active = false
            API.PrintDebug("Empower tier 3 expired")
        end)
        
        API.PrintDebug("Empower Rune Weapon cast")
    end
    
    -- Track Pillar of Frost
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.PILLAR_OF_FROST then
        pillarOfFrostActive = true
        pillarOfFrostEndTime = GetTime() + PILLAR_OF_FROST_DURATION
        API.PrintDebug("Pillar of Frost cast")
    end
    
    -- Track Breath of Sindragosa
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.BREATH_OF_SINDRAGOSA then
        breathOfSindragosaActive = true
        breathOfSindragosaEndTime = GetTime() + BREATH_OF_SINDRAGOSA_DURATION -- Will end earlier if out of RP
        API.PrintDebug("Breath of Sindragosa cast")
    end
    
    -- Track Remorseless Winter
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.REMORSELESS_WINTER then
        remorselessWinterActive = true
        remorselessWinterEndTime = GetTime() + REMORSELESS_WINTER_DURATION
        API.PrintDebug("Remorseless Winter cast")
    end
    
    -- Track Obliteration
    if eventType == "SPELL_CAST_SUCCESS" and spellID == spells.OBLITERATION then
        obliterationActive = true
        obliterationEndTime = GetTime() + OBLITERATION_DURATION
        API.PrintDebug("Obliteration cast")
    end
    
    return true
end

-- Main rotation function
function Frost:RunRotation()
    -- Check if we should be running Frost Death Knight logic
    if API.GetActiveSpecID() ~= FROST_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FrostDeathKnight")
    
    -- Update variables
    self:UpdateRunicPower()
    self:UpdateRunes()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Check if in melee range
    if not inMeleeRange then
        -- Skip to ranged abilities if not in melee range
        return self:HandleRangedAbilities(settings)
    end
    
    -- Apply Frost Fever if not active
    if not frostFeverActive and API.CanCast(spells.HOWLING_BLAST) then
        API.CastSpell(spells.HOWLING_BLAST)
        return true
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Handle interrupts
function Frost:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMeleeRange and API.CanCast(spells.MIND_FREEZE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.MIND_FREEZE)
        return true
    end
    
    -- Asphyxiate as backup interrupt if talented
    if talents.hasAsphyxiate and not inMeleeRange and
       API.IsUnitInRange("target", 20) and API.CanCast(spells.ASPHYXIATE) and 
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.ASPHYXIATE)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Frost:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Anti-Magic Shell
    if settings.defensiveSettings.useAntiMagicShell and
       API.IsPlayerTakingMagicDamage() and
       API.CanCast(spells.ANTI_MAGIC_SHELL) then
        API.CastSpell(spells.ANTI_MAGIC_SHELL)
        return true
    end
    
    -- Use Icebound Fortitude
    if settings.defensiveSettings.useIceboundFortitude and
       playerHealth <= settings.defensiveSettings.iceboundFortitudeThreshold and
       API.CanCast(spells.ICEBOUND_FORTITUDE) then
        API.CastSpell(spells.ICEBOUND_FORTITUDE)
        return true
    end
    
    -- Use Death Strike for healing
    if settings.defensiveSettings.useDeathStrike and
       playerHealth <= settings.defensiveSettings.deathStrikeThreshold and
       currentRunicPower >= 35 and
       API.CanCast(spells.DEATH_STRIKE) then
        API.CastSpell(spells.DEATH_STRIKE)
        return true
    end
    
    -- Use Death Pact
    if talents.hasDeathPact and
       settings.defensiveSettings.useDeathPact and
       playerHealth <= settings.defensiveSettings.deathPactThreshold and
       API.CanCast(spells.DEATH_PACT) then
        API.CastSpell(spells.DEATH_PACT)
        return true
    end
    
    return false
end

-- Handle ranged abilities when not in melee range
function Frost:HandleRangedAbilities(settings)
    -- Apply Frost Fever with Howling Blast
    if not frostFeverActive and API.CanCast(spells.HOWLING_BLAST) then
        API.CastSpell(spells.HOWLING_BLAST)
        return true
    end
    
    -- Use Death Grip to pull target into melee range
    if settings.utilitySettings.useDeathGrip and
       API.CanCast(spells.DEATH_GRIP) then
        API.CastSpell(spells.DEATH_GRIP)
        return true
    end
    
    -- Use Chains of Ice with Cold Heart stacks
    if talents.hasColdHeart and
       coldHeartStacks > 10 and
       settings.rotationSettings.useChainsOfIce != "Manual Only" and
       API.CanCast(spells.CHAINS_OF_ICE) then
        API.CastSpell(spells.CHAINS_OF_ICE)
        return true
    end
    
    -- Use Howling Blast as ranged ability
    if API.CanCast(spells.HOWLING_BLAST) then
        API.CastSpell(spells.HOWLING_BLAST)
        return true
    end
    
    -- Use Glacial Advance as ranged ability if talented
    if talents.hasGlacialAdvance and API.CanCast(spells.GLACIAL_ADVANCE) then
        API.CastSpell(spells.GLACIAL_ADVANCE)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Frost:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive and not API.IsInCombat() then
        return false
    }
    
    -- Use Pillar of Frost
    if settings.offensiveSettings.usePillarOfFrost and
       settings.abilityControls.pillarOfFrost.enabled and
       not pillarOfFrostActive and
       API.CanCast(spells.PILLAR_OF_FROST) then
        
        if not settings.abilityControls.pillarOfFrost.useDuringBurstOnly or burstModeActive then
            if currentRunicPower >= settings.abilityControls.pillarOfFrost.minRunicPower then
                API.CastSpell(spells.PILLAR_OF_FROST)
                return true
            end
        end
    end
    
    -- Use Obliteration
    if talents.hasObliteration and
       settings.offensiveSettings.useObliteration and
       settings.abilityControls.obliteration.enabled and
       not obliterationActive and
       API.CanCast(spells.OBLITERATION) then
        
        -- Check if we should sync with Pillar of Frost
        if (not settings.abilityControls.obliteration.useDuringPillarOfFrost or pillarOfFrostActive) and
           (not settings.abilityControls.obliteration.useDuringBurstOnly or burstModeActive) then
            API.CastSpell(spells.OBLITERATION)
            return true
        end
    end
    
    -- Use Breath of Sindragosa
    if talents.hasBreathOfSindragosa and
       settings.offensiveSettings.useBreathOfSindragosa and
       settings.abilityControls.breathOfSindragosa.enabled and
       not breathOfSindragosaActive and
       API.CanCast(spells.BREATH_OF_SINDRAGOSA) then
        
        if not settings.abilityControls.breathOfSindragosa.useDuringBurstOnly or burstModeActive then
            if currentRunicPower >= settings.offensiveSettings.breathOfSindragosaStartThreshold then
                API.CastSpell(spells.BREATH_OF_SINDRAGOSA)
                return true
            end
        end
    end
    
    -- Use Empower Rune Weapon
    if settings.offensiveSettings.useEmpowerRuneWeapon and
       API.CanCast(spells.EMPOWER_RUNE_WEAPON) then
        
        local shouldUse = false
        
        if settings.offensiveSettings.useEmpowerRuneWeapon == "On Cooldown" then
            shouldUse = true
        elseif settings.offensiveSettings.useEmpowerRuneWeapon == "With Pillar of Frost" then
            shouldUse = pillarOfFrostActive
        elseif settings.offensiveSettings.useEmpowerRuneWeapon == "With BoS" then
            shouldUse = breathOfSindragosaActive
        elseif settings.offensiveSettings.useEmpowerRuneWeapon == "Emergency Only" then
            shouldUse = currentRunes <= 2
        end
        
        if shouldUse then
            API.CastSpell(spells.EMPOWER_RUNE_WEAPON)
            return true
        end
    end
    
    -- Use Horn of Winter
    if talents.hasHornOfWinter and
       settings.offensiveSettings.useHornOfWinter and
       (currentRunicPower < 70 or currentRunes < 3) and
       API.CanCast(spells.HORN_OF_WINTER) then
        API.CastSpell(spells.HORN_OF_WINTER)
        return true
    end
    
    -- Use Frostwyrm's Fury
    if settings.offensiveSettings.useFrostwyrmsFury and
       API.CanCast(spells.FROSTWYRMS_FURY) then
        
        local shouldUse = false
        
        if settings.offensiveSettings.frostwyrmsFuryStrategy == "With Pillar of Frost" then
            shouldUse = pillarOfFrostActive
        elseif settings.offensiveSettings.frostwyrmsFuryStrategy == "AoE Only" then
            shouldUse = currentAoETargets >= settings.rotationSettings.aoeThreshold
        else -- On Cooldown
            shouldUse = true
        end
        
        if shouldUse then
            API.CastSpellAtCursor(spells.FROSTWYRMS_FURY)
            return true
        end
    end
    
    -- Use Chill Streak
    if talents.hasChillStreak and
       settings.offensiveSettings.useChillStreak and
       currentAoETargets >= settings.offensiveSettings.chillStreakMinTargets and
       API.CanCast(spells.CHILL_STREAK) then
        API.CastSpell(spells.CHILL_STREAK)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Frost:HandleAoERotation(settings)
    -- Use Chains of Ice with Cold Heart during Pillar of Frost
    if talents.hasColdHeart and pillarOfFrostActive and coldHeartStacks >= 15 and
       settings.rotationSettings.useChainsOfIce == "With Pillar of Frost" and
       API.CanCast(spells.CHAINS_OF_ICE) then
        API.CastSpell(spells.CHAINS_OF_ICE)
        return true
    end
    
    -- Use Remorseless Winter
    if not remorselessWinterActive and
       (settings.rotationSettings.useRemorselessWinter == "On Cooldown" or 
        settings.rotationSettings.useRemorselessWinter == "AoE Only") and
       API.CanCast(spells.REMORSELESS_WINTER) then
        API.CastSpell(spells.REMORSELESS_WINTER)
        return true
    end
    
    -- Use Glacial Advance
    if talents.hasGlacialAdvance and API.CanCast(spells.GLACIAL_ADVANCE) then
        API.CastSpell(spells.GLACIAL_ADVANCE)
        return true
    end
    
    -- Use Frostscythe with Killing Machine in AoE
    if talents.hasFrostscythe and killingMachineActive and 
       API.CanCast(spells.FROSTSCYTHE) and
       (settings.rotationSettings.killingMachineStrategy == "Prioritize Frostscythe in AoE" or
        settings.rotationSettings.killingMachineStrategy == "Always Frostscythe in AoE") then
        API.CastSpell(spells.FROSTSCYTHE)
        return true
    end
    
    -- Use Death and Decay in AoE
    if settings.utilitySettings.useDeathAndDecay == "AoE Only" and
       API.CanCast(spells.DEATH_AND_DECAY) then
        API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
        return true
    end
    
    -- Use Frostscythe if talented in AoE
    if talents.hasFrostscythe and currentRunes >= 1 and API.CanCast(spells.FROSTSCYTHE) then
        API.CastSpell(spells.FROSTSCYTHE)
        return true
    end
    
    -- Use Howling Blast for AoE
    if currentRunes >= 1 and API.CanCast(spells.HOWLING_BLAST) then
        API.CastSpell(spells.HOWLING_BLAST)
        return true
    end
    
    -- Use Frost Strike to dump Runic Power
    if not breathOfSindragosaActive and
       currentRunicPower >= 25 and
       API.CanCast(spells.FROST_STRIKE) then
        API.CastSpell(spells.FROST_STRIKE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Frost:HandleSingleTargetRotation(settings)
    -- Use Chains of Ice with Cold Heart based on settings
    if talents.hasColdHeart and coldHeartStacks > 0 and API.CanCast(spells.CHAINS_OF_ICE) then
        if settings.rotationSettings.useChainsOfIce == "On Max Stacks" and coldHeartStacks >= 20 then
            API.CastSpell(spells.CHAINS_OF_ICE)
            return true
        elseif settings.rotationSettings.useChainsOfIce == "With Pillar of Frost" and 
               pillarOfFrostActive and coldHeartStacks >= 10 then
            API.CastSpell(spells.CHAINS_OF_ICE)
            return true
        end
    end
    
    -- Use Remorseless Winter
    if not remorselessWinterActive and settings.rotationSettings.useRemorselessWinter == "On Cooldown" and
       API.CanCast(spells.REMORSELESS_WINTER) then
        API.CastSpell(spells.REMORSELESS_WINTER)
        return true
    end
    
    -- Use Obliterate with Killing Machine
    if killingMachineActive and currentRunes >= 2 and
       settings.rotationSettings.killingMachineStrategy == "Always Obliterate" and
       API.CanCast(spells.OBLITERATE) then
        API.CastSpell(spells.OBLITERATE)
        return true
    end
    
    -- Maintain RP threshold for Breath of Sindragosa if active
    if breathOfSindragosaActive and currentRunicPower <= settings.rotationSettings.runePowerSavingThreshold then
        -- Prioritize rune generation if RP is getting low for BoS
        if currentRunes >= 2 and API.CanCast(spells.OBLITERATE) then
            API.CastSpell(spells.OBLITERATE)
            return true
        elseif API.CanCast(spells.HOWLING_BLAST) then
            API.CastSpell(spells.HOWLING_BLAST)
            return true
        end
        -- Skip spending RP to maintain Breath of Sindragosa
        return false
    end
    
    -- Use Frost Strike to prevent capping Runic Power
    if not breathOfSindragosaActive and
       (currentRunicPower >= 80 or
        (settings.advancedSettings.runicPowerPooling == false && currentRunicPower >= 25)) and
       API.CanCast(spells.FROST_STRIKE) then
        API.CastSpell(spells.FROST_STRIKE)
        return true
    end
    
    -- Use Obliterate
    if (currentRunes >= 2 or 
        (settings.advancedSettings.maintainRuneBuffer == 0 && currentRunes >= 1)) and
       API.CanCast(spells.OBLITERATE) then
        
        -- Only use Obliterate with Rime if setting is enabled
        if not settings.advancedSettings.useObliterateOnlyWithRimes or 
           (currentRunes > 3 || rimedeath) then
            API.CastSpell(spells.OBLITERATE)
            return true
        end
    end
    
    -- Use Howling Blast with Rime proc
    if rimedeath and API.CanCast(spells.HOWLING_BLAST) then
        API.CastSpell(spells.HOWLING_BLAST)
        return true
    end
    
    -- Use Frost Strike as a dump before hitting the minimum pool level
    if not breathOfSindragosaActive and
       currentRunicPower >= (settings.advancedSettings.runicPowerPooling and 
                            settings.advancedSettings.minRunicPowerPool or 25) and
       API.CanCast(spells.FROST_STRIKE) then
        API.CastSpell(spells.FROST_STRIKE)
        return true
    end
    
    -- Use Horn of Winter for resource generation if we're running low
    if talents.hasHornOfWinter and
       settings.offensiveSettings.useHornOfWinter and
       (currentRunicPower < 30 and currentRunes < 2) and
       API.CanCast(spells.HORN_OF_WINTER) then
        API.CastSpell(spells.HORN_OF_WINTER)
        return true
    end
    
    -- Use Death and Decay if configured to use always
    if settings.utilitySettings.useDeathAndDecay == "Always" and
       API.CanCast(spells.DEATH_AND_DECAY) then
        API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
        return true
    end
    
    -- Use Howling Blast as a filler
    if currentRunes >= 1 and API.CanCast(spells.HOWLING_BLAST) then
        API.CastSpell(spells.HOWLING_BLAST)
        return true
    end
    
    return false
end

-- Handle specialization change
function Frost:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentRunicPower = API.GetPlayerPower()
    maxRunicPower = 100
    currentRunes = API.GetPlayerRunes()
    maxRunes = 6
    killingMachineActive = false
    killingMachineEndTime = 0
    pillarOfFrostActive = false
    pillarOfFrostEndTime = 0
    breathOfSindragosaActive = false
    breathOfSindragosaEndTime = 0
    remorselessWinterActive = false
    remorselessWinterEndTime = 0
    iceCapActive = false
    iceCapStacks = 0
    iceCapEndTime = 0
    unholyStrengthActive = false
    unholyStrengthEndTime = 0
    frostFeverActive = false
    frostFeverEndTime = 0
    obliterationActive = false
    obliterationEndTime = 0
    icyTalonsActive = false
    icyTalonsStacks = 0
    icyTalonsEndTime = 0
    darkSuccorActive = false
    darkSuccorEndTime = 0
    empower1Active = false
    empower2Active = false
    empower3Active = false
    empowerRuneWeaponActive = false
    empowerRuneWeaponEndTime = 0
    chillStreakChargeable = false
    razoriceBuff = 0
    razoriceFrostweaponStacks = 0
    reaperBuff = false
    reaperEndTime = 0
    reaperBuffStacks = 0
    coldHeartStacks = 0
    coldHeartActive = false
    coldHeartEndTime = 0
    unholyBondActive = false
    glacialAdvanceStacks = 0
    furiousBlow = false
    frostStrike = false
    frostScythe = false
    frozenPulse = false
    inMeleeRange = false
    boneBound = false
    unleashed = false
    breathOfWinter = false
    rimedeath = false
    cleavingStrikesActive = false
    rime = false
    icecap = false
    obliteration = false
    glacialAdvance = false
    asphyxiate = false
    improvedDeathStrike = false
    freezingStrike = false
    snowblind = false
    improvedBreathOfSindragosa = false
    resonateAttacks = false
    iceFloes = false
    
    API.PrintDebug("Frost Death Knight state reset on spec change")
    
    return true
end

-- Return the module for loading
return Frost