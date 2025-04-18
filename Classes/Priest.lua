------------------------------------------
-- WindrunnerRotations - Priest Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local PriestModule = {}
WR.Priest = PriestModule

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local RotationManager = WR.RotationManager
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local AntiDetectionSystem = WR.AntiDetectionSystem
local PvPManager = WR.PvPManager

-- Priest constants
local CLASS_ID = 5 -- Priest class ID
local SPEC_DISCIPLINE = 256
local SPEC_HOLY = 257
local SPEC_SHADOW = 258

-- Current player data
local playerSpec = 0
local isEnabled = true
local inCombat = false

-- Spell IDs for Shadow Priest (The War Within, Season 2)
local SHADOW_SPELLS = {
    -- Core abilities
    MIND_BLAST = 8092,
    MIND_FLAY = 15407,
    SHADOW_WORD_PAIN = 589,
    VAMPIRIC_TOUCH = 34914,
    DEVOURING_PLAGUE = 335467,
    SHADOW_WORD_DEATH = 32379,
    VOID_ERUPTION = 228260,
    VOID_BOLT = 205448,
    MIND_SEAR = 48045,
    SHADOW_CRASH = 205385,
    
    -- Defensive & utility
    DISPERSION = 47585,
    FADE = 586,
    DESPERATE_PRAYER = 19236,
    SHADOW_MEND = 186263,
    MASS_DISPEL = 32375,
    POWER_WORD_SHIELD = 17,
    PSYCHIC_SCREAM = 8122,
    LEAP_OF_FAITH = 73325,
    
    -- Talents
    DARK_ASCENSION = 391109,
    VOID_TORRENT = 263165,
    MINDBENDER = 200174,
    SHADOWFIEND = 34433,
    DARK_VOID = 263346,
    PSYCHIC_HORROR = 64044,
    MIND_BOMB = 205369,
    MINDGAMES = 375901,
    SURGE_OF_DARKNESS = 87160,
    SEARING_NIGHTMARE = 341385,
    
    -- Misc
    POWER_WORD_FORTITUDE = 21562,
    SHADOW_FORM = 232698
}

-- Spell IDs for Discipline Priest
local DISCIPLINE_SPELLS = {
    -- Core abilities
    PENANCE = 47540,
    POWER_WORD_SHIELD = 17,
    POWER_WORD_RADIANCE = 194509,
    SHADOW_MEND = 186263,
    SCHISM = 214621,
    MINDGAMES = 375901,
    SHADOW_WORD_PAIN = 589,
    PURGE_THE_WICKED = 204197,
    SMITE = 585,
    
    -- Defensive & utility
    DESPERATE_PRAYER = 19236,
    PAIN_SUPPRESSION = 33206,
    LEAP_OF_FAITH = 73325,
    PSYCHIC_SCREAM = 8122,
    MASS_DISPEL = 32375,
    DISPEL_MAGIC = 528,
    RAPTURE = 47536,
    
    -- Talents
    POWER_WORD_BARRIER = 62618,
    DIVINE_STAR = 110744,
    HALO = 120517,
    EVANGELISM = 246287,
    SPIRIT_SHELL = 109964,
    MINDBENDER = 123040,
    SHADOWFIEND = 34433,
    
    -- Atonement
    ATONEMENT = 81749,
    
    -- Misc
    POWER_WORD_FORTITUDE = 21562
}

-- Spell IDs for Holy Priest
local HOLY_SPELLS = {
    -- Core abilities
    HEAL = 2050,
    FLASH_HEAL = 2061,
    PRAYER_OF_HEALING = 596,
    HOLY_WORD_SERENITY = 2050,
    HOLY_WORD_SANCTIFY = 34861,
    HOLY_WORD_CHASTISE = 88625,
    RENEW = 139,
    PRAYER_OF_MENDING = 33076,
    SMITE = 585,
    HOLY_FIRE = 14914,
    
    -- Defensive & utility
    DESPERATE_PRAYER = 19236,
    GUARDIAN_SPIRIT = 47788,
    LEAP_OF_FAITH = 73325,
    MASS_DISPEL = 32375,
    PURIFY = 527,
    PSYCHIC_SCREAM = 8122,
    
    -- Talents
    DIVINE_HYMN = 64843,
    DIVINE_STAR = 110744,
    HALO = 120517,
    CIRCLE_OF_HEALING = 204883,
    APOTHEOSIS = 200183,
    HOLY_WORD_SALVATION = 265202,
    SYMBOL_OF_HOPE = 64901,
    
    -- Misc
    POWER_WORD_FORTITUDE = 21562
}

-- Important buffs to track
local BUFFS = {
    VAMPIRIC_EMBRACE = 15286,
    POWER_WORD_SHIELD = 17,
    SHADOWFORM = 232698,
    VOIDFORM = 228264,
    SURGE_OF_DARKNESS = 87160,
    RENEW = 139,
    PRAYER_OF_MENDING = 41635,
    SURGE_OF_LIGHT = 114255,
    ATONEMENT = 194384,
    RAPTURE = 47536,
    DESPERATE_PRAYER = 19236,
    SPIRIT_SHELL = 109964,
    POWER_WORD_FORTITUDE = 21562,
    POWER_INFUSION = 10060,
    TWIST_OF_FATE = 390978
}

-- Important debuffs to track
local DEBUFFS = {
    SHADOW_WORD_PAIN = 589,
    VAMPIRIC_TOUCH = 34914,
    DEVOURING_PLAGUE = 335467,
    PURGE_THE_WICKED = 204213,
    SCHISM = 214621,
    WEAKENED_SOUL = 6788,
    MIND_SEAR = 48045
}

-- Initialize the Priest module
function PriestModule:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register rotations
    self:RegisterRotations()
    
    API.PrintDebug("Priest module initialized")
    return true
end

-- Register settings
function PriestModule:RegisterSettings()
    ConfigRegistry:RegisterSettings("Priest", {
        generalSettings = {
            enabled = {
                displayName = "Enable Priest Module",
                description = "Enable the Priest module for all specs",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when appropriate",
                type = "toggle",
                default = true
            },
            useInterrupts = {
                displayName = "Use Interrupts",
                description = "Automatically interrupt enemy casts when appropriate",
                type = "toggle",
                default = true
            },
            fortitudeCheck = {
                displayName = "Power Word: Fortitude Check",
                description = "Check for Power Word: Fortitude buff",
                type = "toggle",
                default = true
            }
        },
        shadowSettings = {
            priorityRotation = {
                displayName = "Priority Rotation",
                description = "Use priority-based rotation over strict sequence",
                type = "toggle",
                default = true
            },
            dotUptime = {
                displayName = "DoT Uptime Goal",
                description = "Minimum DoT uptime percentage to aim for",
                type = "slider",
                min = 80,
                max = 100,
                step = 5,
                default = 95
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets to switch to AoE rotation",
                type = "slider",
                min = 2,
                max = 5,
                step = 1,
                default = 3
            },
            useShadowCrash = {
                displayName = "Use Shadow Crash",
                description = "Use Shadow Crash in combat",
                type = "toggle",
                default = true
            },
            useVoidEruption = {
                displayName = "Use Void Eruption",
                description = "Use Void Eruption in combat",
                type = "toggle",
                default = true
            },
            useDarkAscension = {
                displayName = "Use Dark Ascension",
                description = "Use Dark Ascension in combat",
                type = "toggle",
                default = true
            },
            useMindbender = {
                displayName = "Use Mindbender/Shadowfiend",
                description = "Use Mindbender or Shadowfiend in combat",
                type = "toggle",
                default = true
            },
            useMindgames = {
                displayName = "Use Mindgames",
                description = "Use Mindgames in combat",
                type = "toggle",
                default = true
            }
        },
        disciplineSettings = {
            atonementCount = {
                displayName = "Atonement Count",
                description = "Number of Atonements to maintain",
                type = "slider",
                min = 1,
                max = 8,
                step = 1,
                default = 4
            },
            usePowerWordRadiance = {
                displayName = "Use Power Word: Radiance",
                description = "Use Power Word: Radiance to spread Atonement",
                type = "toggle",
                default = true
            },
            useDamageSpells = {
                displayName = "Use Damage Spells",
                description = "Use damage spells to heal through Atonement",
                type = "toggle",
                default = true
            },
            dotUptime = {
                displayName = "DoT Uptime Goal",
                description = "Minimum DoT uptime percentage to aim for",
                type = "slider",
                min = 80,
                max = 100,
                step = 5,
                default = 95
            },
            usePainSuppression = {
                displayName = "Use Pain Suppression",
                description = "Use Pain Suppression on low health targets",
                type = "toggle",
                default = true
            },
            painSuppressionThreshold = {
                displayName = "Pain Suppression Threshold",
                description = "Health percentage to use Pain Suppression",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 25
            },
            useSpiritShell = {
                displayName = "Use Spirit Shell",
                description = "Use Spirit Shell in combat",
                type = "toggle",
                default = true
            }
        },
        holySettings = {
            prioritizeHolyWords = {
                displayName = "Prioritize Holy Words",
                description = "Prioritize using Holy Words when available",
                type = "toggle",
                default = true
            },
            useRenew = {
                displayName = "Use Renew",
                description = "Use Renew on targets",
                type = "toggle",
                default = true
            },
            renewThreshold = {
                displayName = "Renew Health Threshold",
                description = "Health percentage to use Renew",
                type = "slider",
                min = 70,
                max = 100,
                step = 5,
                default = 90
            },
            useGuardianSpirit = {
                displayName = "Use Guardian Spirit",
                description = "Use Guardian Spirit on low health targets",
                type = "toggle",
                default = true
            },
            guardianSpiritThreshold = {
                displayName = "Guardian Spirit Threshold",
                description = "Health percentage to use Guardian Spirit",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 20
            },
            useDivineHymn = {
                displayName = "Use Divine Hymn",
                description = "Use Divine Hymn when multiple allies are injured",
                type = "toggle",
                default = true
            },
            divineHymnThreshold = {
                displayName = "Divine Hymn Threshold",
                description = "Number of injured allies to trigger Divine Hymn",
                type = "slider",
                min = 3,
                max = 5,
                step = 1,
                default = 4
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("Priest", function(settings)
        self:ApplySettings(settings)
    end)
}

-- Apply settings
function PriestModule:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enabled
}

-- Register events
function PriestModule:RegisterEvents()
    -- Register for specialization changed event
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for entering combat event
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        inCombat = true
    end)
    
    -- Register for leaving combat event
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        inCombat = false
    end)
    
    -- Update specialization on initialization
    self:OnSpecializationChanged()
}

-- On specialization changed
function PriestModule:OnSpecializationChanged()
    -- Get current spec ID
    playerSpec = API.GetActiveSpecID()
    
    API.PrintDebug("Priest specialization changed: " .. playerSpec)
    
    -- Ensure correct rotation is registered
    if playerSpec == SPEC_SHADOW then
        self:RegisterShadowRotation()
    elseif playerSpec == SPEC_DISCIPLINE then
        self:RegisterDisciplineRotation()
    elseif playerSpec == SPEC_HOLY then
        self:RegisterHolyRotation()
    end
}

-- Register rotations
function PriestModule:RegisterRotations()
    -- Register spec-specific rotations
    self:RegisterShadowRotation()
    self:RegisterDisciplineRotation()
    self:RegisterHolyRotation()
}

-- Register Shadow rotation
function PriestModule:RegisterShadowRotation()
    RotationManager:RegisterRotation("PriestShadow", {
        id = "PriestShadow",
        name = "Priest - Shadow",
        class = "PRIEST",
        spec = SPEC_SHADOW,
        level = 10,
        description = "Shadow Priest rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:ShadowRotation()
        end
    })
}

-- Register Discipline rotation
function PriestModule:RegisterDisciplineRotation()
    RotationManager:RegisterRotation("PriestDiscipline", {
        id = "PriestDiscipline",
        name = "Priest - Discipline",
        class = "PRIEST",
        spec = SPEC_DISCIPLINE,
        level = 10,
        description = "Discipline Priest rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:DisciplineRotation()
        end
    })
}

-- Register Holy rotation
function PriestModule:RegisterHolyRotation()
    RotationManager:RegisterRotation("PriestHoly", {
        id = "PriestHoly",
        name = "Priest - Holy",
        class = "PRIEST",
        spec = SPEC_HOLY,
        level = 10,
        description = "Holy Priest rotation for The War Within Season 2",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            return self:HolyRotation()
        end
    })
}

-- Shadow rotation
function PriestModule:ShadowRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Priest")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local insanity, maxInsanity, insanityPercent = API.GetUnitPower(player, Enum.PowerType.Insanity)
    local inExecutePhase = targetHealthPercent <= 20
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = settings.shadowSettings.aoeThreshold <= enemies
    local inVoidform = API.UnitHasBuff(player, BUFFS.VOIDFORM)
    
    -- Check for Shadowform
    if not API.UnitHasBuff(player, BUFFS.SHADOWFORM) and not inVoidform then
        return {
            type = "spell",
            id = SHADOW_SPELLS.SHADOW_FORM,
            target = player
        }
    end
    
    -- Power Word: Fortitude
    if settings.generalSettings.fortitudeCheck and not API.UnitHasBuff(player, BUFFS.POWER_WORD_FORTITUDE) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.POWER_WORD_FORTITUDE,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Desperate Prayer at low health
        if healthPercent < 50 and API.IsSpellKnown(SHADOW_SPELLS.DESPERATE_PRAYER) and API.IsSpellUsable(SHADOW_SPELLS.DESPERATE_PRAYER) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.DESPERATE_PRAYER,
                target = player
            }
        end
        
        -- Dispersion at critical health
        if healthPercent < 25 and API.IsSpellKnown(SHADOW_SPELLS.DISPERSION) and API.IsSpellUsable(SHADOW_SPELLS.DISPERSION) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.DISPERSION,
                target = player
            }
        end
        
        -- Power Word Shield when available
        if healthPercent < 90 and API.IsSpellKnown(SHADOW_SPELLS.POWER_WORD_SHIELD) and 
           API.IsSpellUsable(SHADOW_SPELLS.POWER_WORD_SHIELD) and not API.UnitHasDebuff(player, DEBUFFS.WEAKENED_SOUL) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.POWER_WORD_SHIELD,
                target = player
            }
        end
    end
    
    -- Offensive cooldowns
    if inCombat then
        -- Void Eruption when high insanity
        if settings.shadowSettings.useVoidEruption and not inVoidform and insanity >= 90 and
           API.IsSpellKnown(SHADOW_SPELLS.VOID_ERUPTION) and API.IsSpellUsable(SHADOW_SPELLS.VOID_ERUPTION) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.VOID_ERUPTION,
                target = target
            }
        end
        
        -- Dark Ascension alternative to Void Eruption
        if settings.shadowSettings.useDarkAscension and not inVoidform and
           API.IsSpellKnown(SHADOW_SPELLS.DARK_ASCENSION) and API.IsSpellUsable(SHADOW_SPELLS.DARK_ASCENSION) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.DARK_ASCENSION,
                target = target
            }
        end
        
        -- Mindbender/Shadowfiend for insanity generation
        if settings.shadowSettings.useMindbender then
            if API.IsSpellKnown(SHADOW_SPELLS.MINDBENDER) and API.IsSpellUsable(SHADOW_SPELLS.MINDBENDER) then
                return {
                    type = "spell",
                    id = SHADOW_SPELLS.MINDBENDER,
                    target = target
                }
            elseif API.IsSpellKnown(SHADOW_SPELLS.SHADOWFIEND) and API.IsSpellUsable(SHADOW_SPELLS.SHADOWFIEND) then
                return {
                    type = "spell",
                    id = SHADOW_SPELLS.SHADOWFIEND,
                    target = target
                }
            end
        end
        
        -- Mindgames for damage/healing
        if settings.shadowSettings.useMindgames and 
           API.IsSpellKnown(SHADOW_SPELLS.MINDGAMES) and API.IsSpellUsable(SHADOW_SPELLS.MINDGAMES) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.MINDGAMES,
                target = target
            }
        end
    end
    
    -- DoT maintenance
    if not API.UnitHasDebuff(target, DEBUFFS.SHADOW_WORD_PAIN) and
       API.IsSpellKnown(SHADOW_SPELLS.SHADOW_WORD_PAIN) and API.IsSpellUsable(SHADOW_SPELLS.SHADOW_WORD_PAIN) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.SHADOW_WORD_PAIN,
            target = target
        }
    end
    
    if not API.UnitHasDebuff(target, DEBUFFS.VAMPIRIC_TOUCH) and
       API.IsSpellKnown(SHADOW_SPELLS.VAMPIRIC_TOUCH) and API.IsSpellUsable(SHADOW_SPELLS.VAMPIRIC_TOUCH) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.VAMPIRIC_TOUCH,
            target = target
        }
    end
    
    -- Core rotation
    if inVoidform then
        -- In Voidform priority
        if API.IsSpellKnown(SHADOW_SPELLS.VOID_BOLT) and API.IsSpellUsable(SHADOW_SPELLS.VOID_BOLT) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.VOID_BOLT,
                target = target
            }
        end
    end
    
    -- Devouring Plague at high insanity
    if insanity >= 50 and API.IsSpellKnown(SHADOW_SPELLS.DEVOURING_PLAGUE) and API.IsSpellUsable(SHADOW_SPELLS.DEVOURING_PLAGUE) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.DEVOURING_PLAGUE,
            target = target
        }
    end
    
    -- Shadow Word: Death in execute phase
    if inExecutePhase and API.IsSpellKnown(SHADOW_SPELLS.SHADOW_WORD_DEATH) and API.IsSpellUsable(SHADOW_SPELLS.SHADOW_WORD_DEATH) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.SHADOW_WORD_DEATH,
            target = target
        }
    end
    
    -- Mind Blast for priority damage
    if API.IsSpellKnown(SHADOW_SPELLS.MIND_BLAST) and API.IsSpellUsable(SHADOW_SPELLS.MIND_BLAST) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.MIND_BLAST,
            target = target
        }
    end
    
    -- AoE rotation
    if aoeEnabled and enemies >= 3 then
        -- Shadow Crash for AoE
        if settings.shadowSettings.useShadowCrash and
           API.IsSpellKnown(SHADOW_SPELLS.SHADOW_CRASH) and API.IsSpellUsable(SHADOW_SPELLS.SHADOW_CRASH) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.SHADOW_CRASH,
                target = target
            }
        end
        
        -- Mind Sear for sustained AoE
        if API.IsSpellKnown(SHADOW_SPELLS.MIND_SEAR) and API.IsSpellUsable(SHADOW_SPELLS.MIND_SEAR) then
            return {
                type = "spell",
                id = SHADOW_SPELLS.MIND_SEAR,
                target = target
            }
        end
    end
    
    -- Mind Flay as filler
    if API.IsSpellKnown(SHADOW_SPELLS.MIND_FLAY) and API.IsSpellUsable(SHADOW_SPELLS.MIND_FLAY) then
        return {
            type = "spell",
            id = SHADOW_SPELLS.MIND_FLAY,
            target = target
        }
    end
    
    return nil
}

-- Discipline rotation
function PriestModule:DisciplineRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- Check if we have a target
    if not UnitExists(target) or not UnitCanAttack(player, target) or UnitIsDead(target) then
        -- Try to find a friendly target if no enemy target exists
        -- Implementation would need group scanning logic
        return nil
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Priest")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local targetHealth, targetMaxHealth, targetHealthPercent = API.GetUnitHealth(target)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(8)
    local aoeEnabled = enemies >= 3
    
    -- Power Word: Fortitude
    if settings.generalSettings.fortitudeCheck and not API.UnitHasBuff(player, BUFFS.POWER_WORD_FORTITUDE) then
        return {
            type = "spell",
            id = DISCIPLINE_SPELLS.POWER_WORD_FORTITUDE,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Desperate Prayer at low health
        if healthPercent < 50 and API.IsSpellKnown(DISCIPLINE_SPELLS.DESPERATE_PRAYER) and 
           API.IsSpellUsable(DISCIPLINE_SPELLS.DESPERATE_PRAYER) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.DESPERATE_PRAYER,
                target = player
            }
        end
        
        -- Pain Suppression on self at low health
        if settings.disciplineSettings.usePainSuppression and 
           healthPercent < settings.disciplineSettings.painSuppressionThreshold and
           API.IsSpellKnown(DISCIPLINE_SPELLS.PAIN_SUPPRESSION) and 
           API.IsSpellUsable(DISCIPLINE_SPELLS.PAIN_SUPPRESSION) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.PAIN_SUPPRESSION,
                target = player
            }
        end
    end
    
    -- Priority healing
    -- Logic for checking group members would go here
    
    -- Atonement maintenance
    if API.IsSpellKnown(DISCIPLINE_SPELLS.POWER_WORD_SHIELD) and 
       API.IsSpellUsable(DISCIPLINE_SPELLS.POWER_WORD_SHIELD) and
       not API.UnitHasBuff(player, BUFFS.ATONEMENT) and
       not API.UnitHasDebuff(player, DEBUFFS.WEAKENED_SOUL) then
        return {
            type = "spell",
            id = DISCIPLINE_SPELLS.POWER_WORD_SHIELD,
            target = player
        }
    end
    
    -- Offensive abilities for Atonement healing
    if settings.disciplineSettings.useDamageSpells and UnitCanAttack(player, target) then
        -- Schism when available
        if API.IsSpellKnown(DISCIPLINE_SPELLS.SCHISM) and API.IsSpellUsable(DISCIPLINE_SPELLS.SCHISM) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.SCHISM,
                target = target
            }
        end
        
        -- Mindgames for damage/healing
        if API.IsSpellKnown(DISCIPLINE_SPELLS.MINDGAMES) and API.IsSpellUsable(DISCIPLINE_SPELLS.MINDGAMES) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.MINDGAMES,
                target = target
            }
        end
        
        -- DoT maintenance
        if API.IsSpellKnown(DISCIPLINE_SPELLS.PURGE_THE_WICKED) and 
           API.IsSpellUsable(DISCIPLINE_SPELLS.PURGE_THE_WICKED) and
           not API.UnitHasDebuff(target, DEBUFFS.PURGE_THE_WICKED) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.PURGE_THE_WICKED,
                target = target
            }
        elseif API.IsSpellKnown(DISCIPLINE_SPELLS.SHADOW_WORD_PAIN) and 
               API.IsSpellUsable(DISCIPLINE_SPELLS.SHADOW_WORD_PAIN) and
               not API.UnitHasDebuff(target, DEBUFFS.SHADOW_WORD_PAIN) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.SHADOW_WORD_PAIN,
                target = target
            }
        end
        
        -- Penance for damage
        if API.IsSpellKnown(DISCIPLINE_SPELLS.PENANCE) and API.IsSpellUsable(DISCIPLINE_SPELLS.PENANCE) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.PENANCE,
                target = target
            }
        end
        
        -- Smite as filler
        if API.IsSpellKnown(DISCIPLINE_SPELLS.SMITE) and API.IsSpellUsable(DISCIPLINE_SPELLS.SMITE) then
            return {
                type = "spell",
                id = DISCIPLINE_SPELLS.SMITE,
                target = target
            }
        end
    end
    
    return nil
}

-- Holy rotation
function PriestModule:HolyRotation()
    -- Check if we should execute
    if not self:ShouldExecuteRotation() then
        return nil
    end
    
    -- Get player and target
    local player = "player"
    local target = "target"
    
    -- For healing specs, we prioritize healing allies over damaging enemies
    -- This would require a more sophisticated targeting system
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("Priest")
    
    -- Common Combat Variables
    local health, maxHealth, healthPercent = API.GetUnitHealth(player)
    local mana, maxMana, manaPercent = API.GetUnitPower(player, Enum.PowerType.Mana)
    local enemies = API.GetEnemyCount(8)
    
    -- Power Word: Fortitude
    if settings.generalSettings.fortitudeCheck and not API.UnitHasBuff(player, BUFFS.POWER_WORD_FORTITUDE) then
        return {
            type = "spell",
            id = HOLY_SPELLS.POWER_WORD_FORTITUDE,
            target = player
        }
    end
    
    -- Defensive abilities
    if settings.generalSettings.useDefensives then
        -- Desperate Prayer at low health
        if healthPercent < 50 and API.IsSpellKnown(HOLY_SPELLS.DESPERATE_PRAYER) and 
           API.IsSpellUsable(HOLY_SPELLS.DESPERATE_PRAYER) then
            return {
                type = "spell",
                id = HOLY_SPELLS.DESPERATE_PRAYER,
                target = player
            }
        end
        
        -- Guardian Spirit on self at critical health
        if settings.holySettings.useGuardianSpirit and 
           healthPercent < settings.holySettings.guardianSpiritThreshold and
           API.IsSpellKnown(HOLY_SPELLS.GUARDIAN_SPIRIT) and 
           API.IsSpellUsable(HOLY_SPELLS.GUARDIAN_SPIRIT) then
            return {
                type = "spell",
                id = HOLY_SPELLS.GUARDIAN_SPIRIT,
                target = player
            }
        end
    end
    
    -- If player health is low, prioritize healing self
    if healthPercent < 70 then
        -- Holy Word Serenity for big heal
        if API.IsSpellKnown(HOLY_SPELLS.HOLY_WORD_SERENITY) and API.IsSpellUsable(HOLY_SPELLS.HOLY_WORD_SERENITY) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_WORD_SERENITY,
                target = player
            }
        end
        
        -- Flash Heal for emergency healing
        if API.IsSpellKnown(HOLY_SPELLS.FLASH_HEAL) and API.IsSpellUsable(HOLY_SPELLS.FLASH_HEAL) then
            return {
                type = "spell",
                id = HOLY_SPELLS.FLASH_HEAL,
                target = player
            }
        end
    end
    
    -- Renew if enabled and needed
    if settings.holySettings.useRenew and healthPercent < settings.holySettings.renewThreshold and
       API.IsSpellKnown(HOLY_SPELLS.RENEW) and API.IsSpellUsable(HOLY_SPELLS.RENEW) and
       not API.UnitHasBuff(player, BUFFS.RENEW) then
        return {
            type = "spell",
            id = HOLY_SPELLS.RENEW,
            target = player
        }
    end
    
    -- If we have an enemy target, do some damage
    if UnitExists(target) and UnitCanAttack(player, target) and not UnitIsDead(target) then
        -- Holy Word: Chastise
        if API.IsSpellKnown(HOLY_SPELLS.HOLY_WORD_CHASTISE) and API.IsSpellUsable(HOLY_SPELLS.HOLY_WORD_CHASTISE) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_WORD_CHASTISE,
                target = target
            }
        end
        
        -- Holy Fire
        if API.IsSpellKnown(HOLY_SPELLS.HOLY_FIRE) and API.IsSpellUsable(HOLY_SPELLS.HOLY_FIRE) then
            return {
                type = "spell",
                id = HOLY_SPELLS.HOLY_FIRE,
                target = target
            }
        end
        
        -- Smite as filler
        if API.IsSpellKnown(HOLY_SPELLS.SMITE) and API.IsSpellUsable(HOLY_SPELLS.SMITE) then
            return {
                type = "spell",
                id = HOLY_SPELLS.SMITE,
                target = target
            }
        end
    end
    
    return nil
}

-- Should execute rotation
function PriestModule:ShouldExecuteRotation()
    if not isEnabled then
        return false
    end
    
    -- Check if player matches class
    local playerInfo = API.GetPlayerInfo()
    if playerInfo.class ~= "PRIEST" then
        return false
    end
    
    return true
}

-- Register for export
WR.Priest = PriestModule

return PriestModule