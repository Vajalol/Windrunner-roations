------------------------------------------
-- WindrunnerRotations - Shadow Priest Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Shadow = {}
-- This will be assigned to addon.Classes.Priest.Shadow when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Priest

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentInsanity = 0
local maxInsanity = 100
local voidformActive = false
local voidformStacks = 0
local voidformEndTime = 0
local darkAscensionActive = false
local darkAscensionEndTime = 0
local shadowfiendActive = false
local shadowfiendEndTime = 0
local mindflayChanneling = false
local mindflayEndTime = 0
local mindSearChanneling = false
local mindSearEndTime = 0
local devouringPlagueActive = false
local devouringPlagueEndTime = 0
local shadowWordPainActive = false
local shadowWordPainEndTime = 0
local vampiricTouchActive = false
local vampiricTouchEndTime = 0
local darkThoughtsActive = false
local surgingDarknessStacks = 0
local surgingDarknessEndTime = 0
local deathspeakerActive = false
local deathspeakerEndTime = 0
local voidTorrentChanneling = false
local voidTorrentEndTime = 0
local hungryVoidActive = false
local mindDevourerActive = false
local shadowformActive = false
local surgeOfInsanityActive = false
local surgeOfInsanityEndTime = 0
local mentalDecayActive = false
local currentChannelSpell = 0
local dispersionActive = false
local dispersionEndTime = 0
local mindBlastCharges = 0
local mindBlastMaxCharges = 0
local mindbenderActive = false
local mindbenderEndTime = 0
local inMeleeRange = false
local inMindSpikeRange = false
local mindSpikeInsanity = false
local shadowCrashCharges = 0
local damnationActive = false
local damnationEndTime = 0
local psychicLinkStacks = 0
local unfurlingDarkness = false
local distortedReality = false
local idolOfYoggsaron = false
local echoingVoid = false
local voidEruption = false
local dissonantEchoes = false
local mindMelt = false
local reaperOfSouls = false
local insidious = false
local mindDevourer = false
local callToTheVoid = false
local psychicLink = false
local mindsEye = false
local shadowyApparitions = false
local tormentedSpirits = false
local shadowWordDeath = false
local massDispel = false
local powerInfusionCastable = false
local mindgamesActive = false
local mindgamesEndTime = 0

-- Constants
local SHADOW_SPEC_ID = 258
local DEFAULT_AOE_THRESHOLD = 3
local VOIDFORM_DURATION = 15 -- seconds (base duration)
local DARK_ASCENSION_DURATION = 20 -- seconds
local SHADOWFIEND_DURATION = 15 -- seconds
local MINDBENDER_DURATION = 15 -- seconds
local MINDFLAY_CHANNEL_TIME = 4.5 -- seconds (full channel)
local MINDSEAR_CHANNEL_TIME = 4.5 -- seconds (full channel)
local VOID_TORRENT_CHANNEL_TIME = 3 -- seconds
local MINDGAMES_DURATION = 5 -- seconds
local DEVOURING_PLAGUE_DURATION = 6 -- seconds
local SHADOW_WORD_PAIN_DURATION = 16 -- seconds
local VAMPIRIC_TOUCH_DURATION = 21 -- seconds
local SURGE_OF_INSANITY_DURATION = 10 -- seconds
local MINDSPIKE_INSANITY_GAIN = 6 -- Base insanity gain
local SHADOW_RANGE = 30 -- yards
local MELEE_RANGE = 5 -- yards

-- Initialize the Shadow module
function Shadow:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Shadow Priest module initialized")
    
    return true
end

-- Register spell IDs
function Shadow:RegisterSpells()
    -- Core rotational abilities
    spells.MIND_BLAST = 8092
    spells.MIND_FLAY = 15407
    spells.SHADOW_WORD_PAIN = 589
    spells.VAMPIRIC_TOUCH = 34914
    spells.DEVOURING_PLAGUE = 335467
    spells.VOID_ERUPTION = 228260
    spells.VOID_BOLT = 205448
    spells.SHADOW_WORD_DEATH = 32379
    spells.SHADOWFIEND = 34433
    spells.MIND_SEAR = 48045
    spells.DARK_ASCENSION = 391109
    spells.MIND_SPIKE = 73510
    spells.SHADOW_CRASH = 205385
    spells.VOID_TORRENT = 263165
    spells.MINDGAMES = 375901
    
    -- Core utilities
    spells.DISPEL_MAGIC = 528
    spells.MASS_DISPEL = 32375
    spells.LEAP_OF_FAITH = 73325
    spells.FADE = 586
    spells.PSYCHIC_SCREAM = 8122
    spells.SILENCE = 15487
    spells.VAMPIRIC_EMBRACE = 15286
    spells.MIND_CONTROL = 605
    spells.POWER_WORD_SHIELD = 17
    spells.DISPERSION = 47585
    spells.SHADOWFORM = 232698
    spells.DESPERATE_PRAYER = 19236
    spells.POWER_INFUSION = 10060
    
    -- Talents and passives
    spells.MINDBENDER = 200174
    spells.PSYCHIC_LINK = 199484
    spells.MISERY = 238558
    spells.SEARING_NIGHTMARE = 341385
    spells.INTANGIBILITY = 288733
    spells.DARK_VOID = 263346
    spells.UNFURLING_DARKNESS = 341273
    spells.DARK_THOUGHTS = 341207
    spells.SURGE_OF_DARKNESS = 87160
    spells.AUSPICIOUS_SPIRITS = 155271
    spells.SHADOWY_INSIGHT = 375888
    spells.FROM_DARKNESS_COMES_LIGHT = 390615
    spells.LAST_WORD = 263716
    spells.THROES_OF_PAIN = 377422
    spells.MIND_DEVOURER = 373202
    spells.PAIN_PERSISTS = 381318
    spells.TORMENTED_SPIRITS = 390388
    spells.VOID_CORRUPTION = 377166
    spells.DARK_EVANGELISM = 391095
    spells.DOMINANT_MIND = 205367
    spells.MIND_BOMB = 205369
    spells.SCREAMS_OF_THE_VOID = 375767
    spells.DEATHS_TORMENT = 391284
    spells.SHADOWFLAME_PRISM = 391239
    spells.INSIDIOUS_IRE = 373212
    spells.MIND_SPIKE_INSANITY = 407472
    spells.IDOL_OF_YOGGSARON = 373280
    spells.MINDS_EYE = 373221
    spells.DISTORTED_REALITY = 403339
    spells.SHADOWY_APPARITIONS = 341491
    spells.DEATH_SPEAKER = 392507
    spells.DEATHSPEAKER = 390617
    spells.DARK_REVERIES = 394963
    spells.THOUGHT_HARVESTER = 406788
    spells.DAMNATION = 341374
    spells.VOID_TENDRILS = 108920
    spells.DIVINE_STAR = 122121
    spells.HALO = 120644
    spells.TWIST_OF_FATE = 390972
    spells.MIND_MELT = 391090
    spells.MENTAL_DECAY = 375994
    spells.DISSONANT_ECHOES = 373221
    spells.CALL_TO_THE_VOID = 375767
    spells.REAPER_OF_SOULS = 408839
    spells.ECHOING_VOID = 391215
    spells.SURGING_DARKNESS = 391399
    
    -- War Within Season 2 specific
    spells.DARK_INFLATION = 404962
    spells.DARK_TEMPTATION = 407423
    spells.DEPTHS_OF_INSANITY = 391088
    spells.HEEDLESS_AGGRESSION = 405557
    spells.HUNGER_FOR_THE_VOID = 407549
    spells.SHADOW_TETHER = 404855
    spells.SPELL_ECHO = 373112
    spells.SURRENDER_TO_MADNESS = 319952
    spells.VOID_SPIRAL = 403295
    spells.VOID_SUMMONER = 405413
    spells.VOIDSPARK = 406767

    -- Covenant abilities (for reference, converted in WoW 10.0)
    spells.UNHOLY_NOVA = 324724
    spells.MINDGAMES = 375901
    spells.FAE_GUARDIANS = 327661
    
    -- Buff IDs
    spells.VOIDFORM_BUFF = 194249
    spells.DARK_ASCENSION_BUFF = 391109
    spells.SHADOWFORM_BUFF = 232698
    spells.DARK_THOUGHTS_BUFF = 341207
    spells.SURGE_OF_DARKNESS_BUFF = 87160
    spells.POWER_INFUSION_BUFF = 10060
    spells.POWER_WORD_SHIELD_BUFF = 17
    spells.DISPERSION_BUFF = 47585
    spells.UNFURLING_DARKNESS_BUFF = 341273
    spells.MIND_DEVOURER_BUFF = 373202
    spells.DEATHSPEAKER_BUFF = 390617
    spells.SURGE_OF_INSANITY_BUFF = 162448
    spells.MENTAL_DECAY_BUFF = 375994
    spells.SURGING_DARKNESS_BUFF = 391399
    
    -- Debuff IDs
    spells.SHADOW_WORD_PAIN_DEBUFF = 589
    spells.VAMPIRIC_TOUCH_DEBUFF = 34914
    spells.DEVOURING_PLAGUE_DEBUFF = 335467
    spells.MINDGAMES_DEBUFF = 375901
    spells.SHADOW_CRASH_DEBUFF = 205386
    spells.MIND_BOMB_DEBUFF = 226943
    spells.PSYCHIC_LINK_DEBUFF = 199484
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.VOIDFORM = spells.VOIDFORM_BUFF
    buffs.DARK_ASCENSION = spells.DARK_ASCENSION_BUFF
    buffs.SHADOWFORM = spells.SHADOWFORM_BUFF
    buffs.DARK_THOUGHTS = spells.DARK_THOUGHTS_BUFF
    buffs.SURGE_OF_DARKNESS = spells.SURGE_OF_DARKNESS_BUFF
    buffs.POWER_INFUSION = spells.POWER_INFUSION_BUFF
    buffs.POWER_WORD_SHIELD = spells.POWER_WORD_SHIELD_BUFF
    buffs.DISPERSION = spells.DISPERSION_BUFF
    buffs.UNFURLING_DARKNESS = spells.UNFURLING_DARKNESS_BUFF
    buffs.MIND_DEVOURER = spells.MIND_DEVOURER_BUFF
    buffs.DEATHSPEAKER = spells.DEATHSPEAKER_BUFF
    buffs.SURGE_OF_INSANITY = spells.SURGE_OF_INSANITY_BUFF
    buffs.MENTAL_DECAY = spells.MENTAL_DECAY_BUFF
    buffs.SURGING_DARKNESS = spells.SURGING_DARKNESS_BUFF
    
    debuffs.SHADOW_WORD_PAIN = spells.SHADOW_WORD_PAIN_DEBUFF
    debuffs.VAMPIRIC_TOUCH = spells.VAMPIRIC_TOUCH_DEBUFF
    debuffs.DEVOURING_PLAGUE = spells.DEVOURING_PLAGUE_DEBUFF
    debuffs.MINDGAMES = spells.MINDGAMES_DEBUFF
    debuffs.SHADOW_CRASH = spells.SHADOW_CRASH_DEBUFF
    debuffs.MIND_BOMB = spells.MIND_BOMB_DEBUFF
    debuffs.PSYCHIC_LINK = spells.PSYCHIC_LINK_DEBUFF
    
    return true
end

-- Register variables to track
function Shadow:RegisterVariables()
    -- Talent tracking
    talents.hasMindbender = false
    talents.hasPsychicLink = false
    talents.hasMisery = false
    talents.hasSearingNightmare = false
    talents.hasIntangibility = false
    talents.hasDarkVoid = false
    talents.hasUnfurlingDarkness = false
    talents.hasDarkThoughts = false
    talents.hasSurgeOfDarkness = false
    talents.hasAuspiciousSpirits = false
    talents.hasShadowyInsight = false
    talents.hasFromDarknessCL = false
    talents.hasLastWord = false
    talents.hasThroesOfPain = false
    talents.hasMindDevourer = false
    talents.hasPainPersists = false
    talents.hasTormentedSpirits = false
    talents.hasVoidCorruption = false
    talents.hasDarkEvangelism = false
    talents.hasDominantMind = false
    talents.hasMindBomb = false
    talents.hasScreamsOfTheVoid = false
    talents.hasDeathsTorment = false
    talents.hasShadowflamePrism = false
    talents.hasInsidiousIre = false
    talents.hasMindSpikeInsanity = false
    talents.hasIdolOfYoggsaron = false
    talents.hasMindsEye = false
    talents.hasDistortedReality = false
    talents.hasShadowyApparitions = false
    talents.hasDeathSpeaker = false
    talents.hasDarkReveries = false
    talents.hasThoughtHarvester = false
    talents.hasDamnation = false
    talents.hasVoidTendrils = false
    talents.hasDivineStar = false
    talents.hasHalo = false
    talents.hasTwistOfFate = false
    talents.hasMindMelt = false
    talents.hasMentalDecay = false
    talents.hasDissonantEchoes = false
    talents.hasCallToTheVoid = false
    talents.hasReaperOfSouls = false
    talents.hasEchoingVoid = false
    talents.hasSurgingDarkness = false
    talents.hasShadowWordDeath = false
    talents.hasDarkAscension = false
    talents.hasVoidTorrent = false
    
    -- War Within Season 2 talents
    talents.hasDarkInflation = false
    talents.hasDarkTemptation = false
    talents.hasDepthsOfInsanity = false
    talents.hasHeedlessAggression = false
    talents.hasHungerForTheVoid = false
    talents.hasShadowTether = false
    talents.hasSpellEcho = false
    talents.hasSurrenderToMadness = false
    talents.hasVoidSpiral = false
    talents.hasVoidSummoner = false
    talents.hasVoidspark = false
    
    -- Initialize insanity
    currentInsanity = API.GetPlayerPower()
    
    -- Initialize ability charges
    mindBlastCharges = API.GetSpellCharges(spells.MIND_BLAST) or 0
    mindBlastMaxCharges = API.GetSpellMaxCharges(spells.MIND_BLAST) or 1
    shadowCrashCharges = API.GetSpellCharges(spells.SHADOW_CRASH) or 0
    
    return true
end

-- Register spec-specific settings
function Shadow:RegisterSettings()
    ConfigRegistry:RegisterSettings("ShadowPriest", {
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
            dotManagement = {
                displayName = "DoT Management",
                description = "How to maintain Shadow Word: Pain and Vampiric Touch",
                type = "dropdown",
                options = {"Manual", "Refresh at 30%", "Refresh at 50%", "Always Refresh"},
                default = "Refresh at 30%"
            },
            useShadowCrash = {
                displayName = "Use Shadow Crash",
                description = "Automatically use Shadow Crash",
                type = "toggle",
                default = true
            },
            useShadowWordDeath = {
                displayName = "Use Shadow Word: Death",
                description = "Automatically use Shadow Word: Death on execute targets",
                type = "toggle",
                default = true
            },
            useMindSpikeWithIds = {
                displayName = "Use Mind Spike",
                description = "When to use Mind Spike with Idol of Yogg-Saron",
                type = "dropdown",
                options = {"On Cooldown", "For Insanity", "Never"},
                default = "For Insanity"
            }
        },
        
        defensiveSettings = {
            useDispersion = {
                displayName = "Use Dispersion",
                description = "Automatically use Dispersion",
                type = "toggle",
                default = true
            },
            dispersionThreshold = {
                displayName = "Dispersion Health Threshold",
                description = "Health percentage to use Dispersion",
                type = "slider",
                min = 10,
                max = 40,
                default = 20
            },
            useVampiricEmbrace = {
                displayName = "Use Vampiric Embrace",
                description = "Automatically use Vampiric Embrace",
                type = "toggle",
                default = true
            },
            vampiricEmbraceThreshold = {
                displayName = "Vampiric Embrace Health Threshold",
                description = "Health percentage to use Vampiric Embrace",
                type = "slider",
                min = 20,
                max = 70,
                default = 40
            },
            useFade = {
                displayName = "Use Fade",
                description = "Automatically use Fade when taking damage",
                type = "toggle",
                default = true
            },
            usePowerWordShield = {
                displayName = "Use Power Word: Shield",
                description = "Automatically use Power Word: Shield",
                type = "toggle",
                default = true
            },
            powerWordShieldThreshold = {
                displayName = "Power Word: Shield Health Threshold",
                description = "Health percentage to use Power Word: Shield",
                type = "slider",
                min = 50,
                max = 95,
                default = 80
            },
            useDesperatePrayer = {
                displayName = "Use Desperate Prayer",
                description = "Automatically use Desperate Prayer",
                type = "toggle",
                default = true
            },
            desperatePrayerThreshold = {
                displayName = "Desperate Prayer Health Threshold",
                description = "Health percentage to use Desperate Prayer",
                type = "slider",
                min = 20,
                max = 60,
                default = 40
            }
        },
        
        offensiveSettings = {
            useVoidEruption = {
                displayName = "Use Void Eruption",
                description = "Automatically use Void Eruption",
                type = "toggle",
                default = true
            },
            minInsanityForVoidform = {
                displayName = "Min Insanity for Voidform",
                description = "Minimum insanity to enter Voidform",
                type = "slider",
                min = 40,
                max = 100,
                default = 60
            },
            useDarkAscension = {
                displayName = "Use Dark Ascension",
                description = "Automatically use Dark Ascension when talented",
                type = "toggle",
                default = true
            },
            useShadowfiend = {
                displayName = "Use Shadowfiend",
                description = "Automatically use Shadowfiend",
                type = "toggle",
                default = true
            },
            useMindbender = {
                displayName = "Use Mindbender",
                description = "Automatically use Mindbender when talented",
                type = "toggle",
                default = true
            },
            usePowerInfusion = {
                displayName = "Use Power Infusion",
                description = "Automatically use Power Infusion",
                type = "toggle",
                default = true
            },
            powerInfusionSync = {
                displayName = "Power Infusion Sync",
                description = "When to sync Power Infusion with other cooldowns",
                type = "dropdown",
                options = {"With Voidform", "With Dark Ascension", "On Cooldown"},
                default = "With Voidform"
            },
            useVoidTorrent = {
                displayName = "Use Void Torrent",
                description = "Automatically use Void Torrent when talented",
                type = "toggle",
                default = true
            },
            voidTorrentUsage = {
                displayName = "Void Torrent Usage",
                description = "When to use Void Torrent",
                type = "dropdown",
                options = {"With Devouring Plague", "For Insanity", "On Cooldown"},
                default = "With Devouring Plague"
            },
            useMindgames = {
                displayName = "Use Mindgames",
                description = "Automatically use Mindgames",
                type = "toggle",
                default = true
            },
            mindgamesSync = {
                displayName = "Mindgames Sync",
                description = "When to sync Mindgames with other cooldowns",
                type = "dropdown",
                options = {"With Voidform", "On Cooldown", "With Voidform Extension"},
                default = "With Voidform"
            }
        },
        
        utilityCCSettings = {
            usePsychicScream = {
                displayName = "Use Psychic Scream",
                description = "Automatically use Psychic Scream",
                type = "toggle",
                default = true
            },
            psychicScreamThreshold = {
                displayName = "Psychic Scream Threshold",
                description = "Minimum number of enemies to use Psychic Scream",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            useSilence = {
                displayName = "Use Silence",
                description = "Automatically use Silence for interrupts",
                type = "toggle",
                default = true
            },
            useMindBomb = {
                displayName = "Use Mind Bomb",
                description = "Automatically use Mind Bomb when talented",
                type = "toggle",
                default = true
            },
            mindBombThreshold = {
                displayName = "Mind Bomb Threshold",
                description = "Minimum number of enemies to use Mind Bomb",
                type = "slider",
                min = 1,
                max = 5,
                default = 2
            },
            useVoidTendrils = {
                displayName = "Use Void Tendrils",
                description = "Automatically use Void Tendrils when talented",
                type = "toggle",
                default = true
            },
            voidTendrilsThreshold = {
                displayName = "Void Tendrils Threshold",
                description = "Minimum number of enemies to use Void Tendrils",
                type = "slider",
                min = 1,
                max = 5,
                default = 2
            }
        },
        
        advancedSettings = {
            channelClipping = {
                displayName = "Channel Clipping",
                description = "When to clip Mind Flay/Mind Sear channels",
                type = "dropdown",
                options = {"Never", "For Priority Abilities", "Aggressively"},
                default = "For Priority Abilities"
            },
            insanityManagement = {
                displayName = "Insanity Management",
                description = "How to manage insanity generation and spending",
                type = "dropdown",
                options = {"Conservative", "Balanced", "Aggressive"},
                default = "Balanced"
            },
            devouringPlagueThreshold = {
                displayName = "Devouring Plague Threshold",
                description = "Insanity threshold to cast Devouring Plague",
                type = "slider",
                min = 50,
                max = 90,
                default = 70
            },
            useDevouringPlagueSingle = {
                displayName = "Use Devouring Plague",
                description = "When to use Devouring Plague in single target",
                type = "dropdown",
                options = {"At Threshold", "On Cooldown", "With Mind Devourer"},
                default = "At Threshold"
            },
            useDevouringPlagueAoE = {
                displayName = "Use Devouring Plague in AoE",
                description = "When to use Devouring Plague in AoE",
                type = "dropdown",
                options = {"Never", "At Threshold", "To Spread Psychic Link"},
                default = "To Spread Psychic Link"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Void Eruption controls
            voidEruption = AAC.RegisterAbility(spells.VOID_ERUPTION, {
                enabled = true,
                useDuringBurstOnly = false,
                minDotTargets = 1
            }),
            
            -- Dark Ascension controls
            darkAscension = AAC.RegisterAbility(spells.DARK_ASCENSION, {
                enabled = true,
                useDuringBurstOnly = true,
                minInsanity = 40
            }),
            
            -- Power Infusion controls
            powerInfusion = AAC.RegisterAbility(spells.POWER_INFUSION, {
                enabled = true,
                useDuringVoidform = true,
                selfCast = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Shadow:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for insanity updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "INSANITY" then
            self:UpdateInsanity()
        end
    end)
    
    -- Register for spell channel updates
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleChannelStart(spellID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(unit, _, spellID) 
        if unit == "player" then
            self:HandleChannelStop(spellID)
        end
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
function Shadow:UpdateTalentInfo()
    -- Check for important talents
    talents.hasMindbender = API.HasTalent(spells.MINDBENDER)
    talents.hasPsychicLink = API.HasTalent(spells.PSYCHIC_LINK)
    talents.hasMisery = API.HasTalent(spells.MISERY)
    talents.hasSearingNightmare = API.HasTalent(spells.SEARING_NIGHTMARE)
    talents.hasIntangibility = API.HasTalent(spells.INTANGIBILITY)
    talents.hasDarkVoid = API.HasTalent(spells.DARK_VOID)
    talents.hasUnfurlingDarkness = API.HasTalent(spells.UNFURLING_DARKNESS)
    talents.hasDarkThoughts = API.HasTalent(spells.DARK_THOUGHTS)
    talents.hasSurgeOfDarkness = API.HasTalent(spells.SURGE_OF_DARKNESS)
    talents.hasAuspiciousSpirits = API.HasTalent(spells.AUSPICIOUS_SPIRITS)
    talents.hasShadowyInsight = API.HasTalent(spells.SHADOWY_INSIGHT)
    talents.hasFromDarknessCL = API.HasTalent(spells.FROM_DARKNESS_COMES_LIGHT)
    talents.hasLastWord = API.HasTalent(spells.LAST_WORD)
    talents.hasThroesOfPain = API.HasTalent(spells.THROES_OF_PAIN)
    talents.hasMindDevourer = API.HasTalent(spells.MIND_DEVOURER)
    talents.hasPainPersists = API.HasTalent(spells.PAIN_PERSISTS)
    talents.hasTormentedSpirits = API.HasTalent(spells.TORMENTED_SPIRITS)
    talents.hasVoidCorruption = API.HasTalent(spells.VOID_CORRUPTION)
    talents.hasDarkEvangelism = API.HasTalent(spells.DARK_EVANGELISM)
    talents.hasDominantMind = API.HasTalent(spells.DOMINANT_MIND)
    talents.hasMindBomb = API.HasTalent(spells.MIND_BOMB)
    talents.hasScreamsOfTheVoid = API.HasTalent(spells.SCREAMS_OF_THE_VOID)
    talents.hasDeathsTorment = API.HasTalent(spells.DEATHS_TORMENT)
    talents.hasShadowflamePrism = API.HasTalent(spells.SHADOWFLAME_PRISM)
    talents.hasInsidiousIre = API.HasTalent(spells.INSIDIOUS_IRE)
    talents.hasMindSpikeInsanity = API.HasTalent(spells.MIND_SPIKE_INSANITY)
    talents.hasIdolOfYoggsaron = API.HasTalent(spells.IDOL_OF_YOGGSARON)
    talents.hasMindsEye = API.HasTalent(spells.MINDS_EYE)
    talents.hasDistortedReality = API.HasTalent(spells.DISTORTED_REALITY)
    talents.hasShadowyApparitions = API.HasTalent(spells.SHADOWY_APPARITIONS)
    talents.hasDeathSpeaker = API.HasTalent(spells.DEATH_SPEAKER)
    talents.hasDarkReveries = API.HasTalent(spells.DARK_REVERIES)
    talents.hasThoughtHarvester = API.HasTalent(spells.THOUGHT_HARVESTER)
    talents.hasDamnation = API.HasTalent(spells.DAMNATION)
    talents.hasVoidTendrils = API.HasTalent(spells.VOID_TENDRILS)
    talents.hasDivineStar = API.HasTalent(spells.DIVINE_STAR)
    talents.hasHalo = API.HasTalent(spells.HALO)
    talents.hasTwistOfFate = API.HasTalent(spells.TWIST_OF_FATE)
    talents.hasMindMelt = API.HasTalent(spells.MIND_MELT)
    talents.hasMentalDecay = API.HasTalent(spells.MENTAL_DECAY)
    talents.hasDissonantEchoes = API.HasTalent(spells.DISSONANT_ECHOES)
    talents.hasCallToTheVoid = API.HasTalent(spells.CALL_TO_THE_VOID)
    talents.hasReaperOfSouls = API.HasTalent(spells.REAPER_OF_SOULS)
    talents.hasEchoingVoid = API.HasTalent(spells.ECHOING_VOID)
    talents.hasSurgingDarkness = API.HasTalent(spells.SURGING_DARKNESS)
    talents.hasShadowWordDeath = API.HasTalent(spells.SHADOW_WORD_DEATH)
    talents.hasDarkAscension = API.HasTalent(spells.DARK_ASCENSION)
    talents.hasVoidTorrent = API.HasTalent(spells.VOID_TORRENT)
    
    -- War Within Season 2 talents
    talents.hasDarkInflation = API.HasTalent(spells.DARK_INFLATION)
    talents.hasDarkTemptation = API.HasTalent(spells.DARK_TEMPTATION)
    talents.hasDepthsOfInsanity = API.HasTalent(spells.DEPTHS_OF_INSANITY)
    talents.hasHeedlessAggression = API.HasTalent(spells.HEEDLESS_AGGRESSION)
    talents.hasHungerForTheVoid = API.HasTalent(spells.HUNGER_FOR_THE_VOID)
    talents.hasShadowTether = API.HasTalent(spells.SHADOW_TETHER)
    talents.hasSpellEcho = API.HasTalent(spells.SPELL_ECHO)
    talents.hasSurrenderToMadness = API.HasTalent(spells.SURRENDER_TO_MADNESS)
    talents.hasVoidSpiral = API.HasTalent(spells.VOID_SPIRAL)
    talents.hasVoidSummoner = API.HasTalent(spells.VOID_SUMMONER)
    talents.hasVoidspark = API.HasTalent(spells.VOIDSPARK)
    
    -- Set specialized variables based on talents
    if talents.hasUnfurlingDarkness then
        unfurlingDarkness = true
    end
    
    if talents.hasDistortedReality then
        distortedReality = true
    end
    
    if talents.hasIdolOfYoggsaron then
        idolOfYoggsaron = true
    end
    
    if talents.hasEchoingVoid then
        echoingVoid = true
    end
    
    if talents.hasVoidEruption then
        voidEruption = true
    end
    
    if talents.hasDissonantEchoes then
        dissonantEchoes = true
    end
    
    if talents.hasMindMelt then
        mindMelt = true
    end
    
    if talents.hasReaperOfSouls then
        reaperOfSouls = true
    end
    
    if talents.hasInsidiousIre then
        insidious = true
    end
    
    if talents.hasMindDevourer then
        mindDevourer = true
    end
    
    if talents.hasCallToTheVoid then
        callToTheVoid = true
    end
    
    if talents.hasPsychicLink then
        psychicLink = true
    end
    
    if talents.hasMindsEye then
        mindsEye = true
    end
    
    if talents.hasShadowyApparitions then
        shadowyApparitions = true
    end
    
    if talents.hasTormentedSpirits then
        tormentedSpirits = true
    end
    
    if talents.hasShadowWordDeath then
        shadowWordDeath = true
    end
    
    if talents.hasMassDispel then
        massDispel = true
    end
    
    if talents.hasMindSpikeInsanity then
        mindSpikeInsanity = true
    end
    
    -- Update ability charges
    mindBlastCharges = API.GetSpellCharges(spells.MIND_BLAST) or 0
    mindBlastMaxCharges = API.GetSpellMaxCharges(spells.MIND_BLAST) or 1
    shadowCrashCharges = API.GetSpellCharges(spells.SHADOW_CRASH) or 0
    
    -- Check if Power Infusion is available
    powerInfusionCastable = API.CanCast(spells.POWER_INFUSION)
    
    API.PrintDebug("Shadow Priest talents updated")
    
    return true
end

-- Update insanity tracking
function Shadow:UpdateInsanity()
    currentInsanity = API.GetPlayerPower()
    return true
end

-- Handle channel start
function Shadow:HandleChannelStart(spellID)
    if spellID == spells.MIND_FLAY then
        mindflayChanneling = true
        mindflayEndTime = GetTime() + MINDFLAY_CHANNEL_TIME
        currentChannelSpell = spells.MIND_FLAY
        API.PrintDebug("Mind Flay channel started")
    elseif spellID == spells.MIND_SEAR then
        mindSearChanneling = true
        mindSearEndTime = GetTime() + MINDSEAR_CHANNEL_TIME
        currentChannelSpell = spells.MIND_SEAR
        API.PrintDebug("Mind Sear channel started")
    elseif spellID == spells.VOID_TORRENT then
        voidTorrentChanneling = true
        voidTorrentEndTime = GetTime() + VOID_TORRENT_CHANNEL_TIME
        currentChannelSpell = spells.VOID_TORRENT
        API.PrintDebug("Void Torrent channel started")
    end
    
    return true
end

-- Handle channel stop
function Shadow:HandleChannelStop(spellID)
    if spellID == spells.MIND_FLAY then
        mindflayChanneling = false
        API.PrintDebug("Mind Flay channel ended")
    elseif spellID == spells.MIND_SEAR then
        mindSearChanneling = false
        API.PrintDebug("Mind Sear channel ended")
    elseif spellID == spells.VOID_TORRENT then
        voidTorrentChanneling = false
        API.PrintDebug("Void Torrent channel ended")
    end
    
    currentChannelSpell = 0
    
    return true
end

-- Update target data
function Shadow:UpdateTargetData()
    -- Check if in range
    inMindSpikeRange = API.IsUnitInRange("target", SHADOW_RANGE)
    inMeleeRange = API.IsUnitInRange("target", MELEE_RANGE)
    
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Shadow Word: Pain
        local swpInfo = API.GetDebuffInfo(targetGUID, debuffs.SHADOW_WORD_PAIN)
        shadowWordPainActive = swpInfo ~= nil
        if shadowWordPainActive then
            shadowWordPainEndTime = select(6, swpInfo)
        else
            shadowWordPainEndTime = 0
        end
        
        -- Check for Vampiric Touch
        local vtInfo = API.GetDebuffInfo(targetGUID, debuffs.VAMPIRIC_TOUCH)
        vampiricTouchActive = vtInfo ~= nil
        if vampiricTouchActive then
            vampiricTouchEndTime = select(6, vtInfo)
        else
            vampiricTouchEndTime = 0
        end
        
        -- Check for Devouring Plague
        local dpInfo = API.GetDebuffInfo(targetGUID, debuffs.DEVOURING_PLAGUE)
        devouringPlagueActive = dpInfo ~= nil
        if devouringPlagueActive then
            devouringPlagueEndTime = select(6, dpInfo)
        else
            devouringPlagueEndTime = 0
        end
        
        -- Check for Mindgames
        local mgInfo = API.GetDebuffInfo(targetGUID, debuffs.MINDGAMES)
        mindgamesActive = mgInfo ~= nil
        if mindgamesActive then
            mindgamesEndTime = select(6, mgInfo)
        else
            mindgamesEndTime = 0
        end
        
        -- Check Psychic Link stacks
        if talents.hasPsychicLink then
            psychicLinkStacks = API.GetDebuffStacks(targetGUID, debuffs.PSYCHIC_LINK) or 0
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- AoE radius
    
    return true
end

-- Handle combat log events
function Shadow:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Voidform
            if spellID == buffs.VOIDFORM then
                voidformActive = true
                voidformStacks = select(4, API.GetBuffInfo("player", buffs.VOIDFORM)) or 1
                voidformEndTime = GetTime() + VOIDFORM_DURATION
                API.PrintDebug("Voidform activated")
            end
            
            -- Track Dark Ascension
            if spellID == buffs.DARK_ASCENSION then
                darkAscensionActive = true
                darkAscensionEndTime = GetTime() + DARK_ASCENSION_DURATION
                API.PrintDebug("Dark Ascension activated")
            end
            
            -- Track Shadowform
            if spellID == buffs.SHADOWFORM then
                shadowformActive = true
                API.PrintDebug("Shadowform activated")
            end
            
            -- Track Dark Thoughts
            if spellID == buffs.DARK_THOUGHTS then
                darkThoughtsActive = true
                API.PrintDebug("Dark Thoughts proc activated")
            end
            
            -- Track Surge of Darkness
            if spellID == buffs.SURGE_OF_DARKNESS then
                API.PrintDebug("Surge of Darkness activated")
            end
            
            -- Track Power Infusion
            if spellID == buffs.POWER_INFUSION then
                API.PrintDebug("Power Infusion activated")
            end
            
            -- Track defensive buffs
            if spellID == buffs.POWER_WORD_SHIELD then
                API.PrintDebug("Power Word: Shield activated")
            elseif spellID == buffs.DISPERSION then
                dispersionActive = true
                dispersionEndTime = GetTime() + 6 -- Dispersion lasts 6 seconds
                API.PrintDebug("Dispersion activated")
            end
            
            -- Track Unfurling Darkness
            if spellID == buffs.UNFURLING_DARKNESS then
                unfurlingDarkness = true
                API.PrintDebug("Unfurling Darkness proc activated")
            end
            
            -- Track Mind Devourer
            if spellID == buffs.MIND_DEVOURER then
                mindDevourerActive = true
                API.PrintDebug("Mind Devourer proc activated")
            end
            
            -- Track Deathspeaker
            if spellID == buffs.DEATHSPEAKER then
                deathspeakerActive = true
                deathspeakerEndTime = GetTime() + 15 -- approximate duration
                API.PrintDebug("Deathspeaker activated")
            end
            
            -- Track Surge of Insanity
            if spellID == buffs.SURGE_OF_INSANITY then
                surgeOfInsanityActive = true
                surgeOfInsanityEndTime = GetTime() + SURGE_OF_INSANITY_DURATION
                API.PrintDebug("Surge of Insanity activated")
            end
            
            -- Track Mental Decay
            if spellID == buffs.MENTAL_DECAY then
                mentalDecayActive = true
                API.PrintDebug("Mental Decay activated")
            end
            
            -- Track Surging Darkness
            if spellID == buffs.SURGING_DARKNESS then
                surgingDarknessStacks = select(4, API.GetBuffInfo("player", buffs.SURGING_DARKNESS)) or 1
                surgingDarknessEndTime = select(6, API.GetBuffInfo("player", buffs.SURGING_DARKNESS))
                API.PrintDebug("Surging Darkness stacks: " .. tostring(surgingDarknessStacks))
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buff removals
        if destGUID == API.GetPlayerGUID() then
            -- Track Voidform
            if spellID == buffs.VOIDFORM then
                voidformActive = false
                voidformStacks = 0
                API.PrintDebug("Voidform faded")
            end
            
            -- Track Dark Ascension
            if spellID == buffs.DARK_ASCENSION then
                darkAscensionActive = false
                API.PrintDebug("Dark Ascension faded")
            end
            
            -- Track Shadowform
            if spellID == buffs.SHADOWFORM then
                shadowformActive = false
                API.PrintDebug("Shadowform faded")
            end
            
            -- Track Dark Thoughts
            if spellID == buffs.DARK_THOUGHTS then
                darkThoughtsActive = false
                API.PrintDebug("Dark Thoughts proc consumed")
            end
            
            -- Track defensive buffs
            if spellID == buffs.DISPERSION then
                dispersionActive = false
                API.PrintDebug("Dispersion faded")
            end
            
            -- Track Unfurling Darkness
            if spellID == buffs.UNFURLING_DARKNESS then
                unfurlingDarkness = false
                API.PrintDebug("Unfurling Darkness proc consumed")
            end
            
            -- Track Mind Devourer
            if spellID == buffs.MIND_DEVOURER then
                mindDevourerActive = false
                API.PrintDebug("Mind Devourer proc consumed")
            end
            
            -- Track Deathspeaker
            if spellID == buffs.DEATHSPEAKER then
                deathspeakerActive = false
                API.PrintDebug("Deathspeaker faded")
            end
            
            -- Track Surge of Insanity
            if spellID == buffs.SURGE_OF_INSANITY then
                surgeOfInsanityActive = false
                API.PrintDebug("Surge of Insanity faded")
            end
            
            -- Track Mental Decay
            if spellID == buffs.MENTAL_DECAY then
                mentalDecayActive = false
                API.PrintDebug("Mental Decay faded")
            end
            
            -- Track Surging Darkness
            if spellID == buffs.SURGING_DARKNESS then
                surgingDarknessStacks = 0
                API.PrintDebug("Surging Darkness faded")
            end
        end
    end
    
    -- Track Voidform stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.VOIDFORM and destGUID == API.GetPlayerGUID() then
        voidformStacks = select(4, API.GetBuffInfo("player", buffs.VOIDFORM)) or 0
        API.PrintDebug("Voidform stacks: " .. tostring(voidformStacks))
    end
    
    -- Track Surging Darkness stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.SURGING_DARKNESS and destGUID == API.GetPlayerGUID() then
        surgingDarknessStacks = select(4, API.GetBuffInfo("player", buffs.SURGING_DARKNESS)) or 0
        API.PrintDebug("Surging Darkness stacks: " .. tostring(surgingDarknessStacks))
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.VOID_ERUPTION then
            voidformActive = true
            voidformStacks = 1
            voidformEndTime = GetTime() + VOIDFORM_DURATION
            API.PrintDebug("Void Eruption cast, entering Voidform")
        elseif spellID == spells.DARK_ASCENSION then
            darkAscensionActive = true
            darkAscensionEndTime = GetTime() + DARK_ASCENSION_DURATION
            API.PrintDebug("Dark Ascension cast")
        elseif spellID == spells.SHADOWFIEND then
            shadowfiendActive = true
            shadowfiendEndTime = GetTime() + SHADOWFIEND_DURATION
            API.PrintDebug("Shadowfiend cast")
        elseif spellID == spells.MINDBENDER then
            mindbenderActive = true
            mindbenderEndTime = GetTime() + MINDBENDER_DURATION
            API.PrintDebug("Mindbender cast")
        elseif spellID == spells.DEVOURING_PLAGUE then
            devouringPlagueActive = true
            devouringPlagueEndTime = GetTime() + DEVOURING_PLAGUE_DURATION
            API.PrintDebug("Devouring Plague cast")
        elseif spellID == spells.MIND_BLAST then
            mindBlastCharges = API.GetSpellCharges(spells.MIND_BLAST) or 0
            API.PrintDebug("Mind Blast cast, charges remaining: " .. tostring(mindBlastCharges))
        elseif spellID == spells.SHADOW_CRASH then
            shadowCrashCharges = API.GetSpellCharges(spells.SHADOW_CRASH) or 0
            API.PrintDebug("Shadow Crash cast, charges remaining: " .. tostring(shadowCrashCharges))
        elseif spellID == spells.DAMNATION then
            damnationActive = true
            damnationEndTime = GetTime() + 1 -- Short duration effect
            API.PrintDebug("Damnation cast")
        elseif spellID == spells.MINDGAMES then
            mindgamesActive = true
            mindgamesEndTime = GetTime() + MINDGAMES_DURATION
            API.PrintDebug("Mindgames cast")
        end
    end
    
    return true
end

-- Function to check if we should clip our current channel
function Shadow:ShouldClipChannel(settings)
    if currentChannelSpell == 0 then
        return true -- Not channeling anything
    end
    
    -- Always clip for Void Bolt/Eruption in Voidform, regardless of settings
    if (voidformActive and API.CanCast(spells.VOID_BOLT)) then
        return true
    end
    
    -- Don't clip for any ability if set to never clip
    if settings.advancedSettings.channelClipping == "Never" then
        return false
    end
    
    -- Clip aggressively for any ability if set
    if settings.advancedSettings.channelClipping == "Aggressively" then
        return true
    }
    
    -- Clip for priority abilities
    if settings.advancedSettings.channelClipping == "For Priority Abilities" then
        -- Clip for Mind Blast
        if API.CanCast(spells.MIND_BLAST) and mindBlastCharges > 0 then
            return true
        end
        
        -- Clip for Devouring Plague at high insanity
        if API.CanCast(spells.DEVOURING_PLAGUE) and currentInsanity >= settings.advancedSettings.devouringPlagueThreshold then
            return true
        end
        
        -- Clip for Shadow Word: Death on execute targets
        if shadowWordDeath and API.CanCast(spells.SHADOW_WORD_DEATH) and API.GetTargetHealthPercent() <= 20 then
            return true
        end
        
        -- Clip for Dark Thoughts proc
        if darkThoughtsActive then
            return true
        end
    }
    
    -- Don't clip for other abilities
    return false
end

-- Main rotation function
function Shadow:RunRotation()
    -- Check if we should be running Shadow Priest logic
    if API.GetActiveSpecID() ~= SHADOW_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling without permission to clip
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ShadowPriest")
    
    -- Update variables
    self:UpdateInsanity()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    self:UpdateTargetData() -- Makes sure we have current target information
    
    -- Check if we're channeling and shouldn't clip
    if (mindflayChanneling or mindSearChanneling or voidTorrentChanneling) and not self:ShouldClipChannel(settings) then
        return false
    end
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Maintain Shadowform if not in Voidform
    if not shadowformActive and not voidformActive and not dispersionActive and API.CanCast(spells.SHADOWFORM) then
        API.CastSpell(spells.SHADOWFORM)
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle defensive/emergency abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Check if in range
    if not inMindSpikeRange then
        return false
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle DoT maintenance
    if self:HandleDoTs(settings) then
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
function Shadow:HandleInterrupts()
    -- Only attempt to interrupt if in range
    if inMindSpikeRange and API.CanCast(spells.SILENCE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.SILENCE)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Shadow:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Dispersion
    if settings.defensiveSettings.useDispersion and
       playerHealth <= settings.defensiveSettings.dispersionThreshold and
       not dispersionActive and
       API.CanCast(spells.DISPERSION) then
        API.CastSpell(spells.DISPERSION)
        return true
    end
    
    -- Use Vampiric Embrace
    if settings.defensiveSettings.useVampiricEmbrace and
       playerHealth <= settings.defensiveSettings.vampiricEmbraceThreshold and
       API.CanCast(spells.VAMPIRIC_EMBRACE) then
        API.CastSpell(spells.VAMPIRIC_EMBRACE)
        return true
    end
    
    -- Use Power Word: Shield
    if settings.defensiveSettings.usePowerWordShield and
       playerHealth <= settings.defensiveSettings.powerWordShieldThreshold and
       API.CanCast(spells.POWER_WORD_SHIELD) then
        API.CastSpellOnSelf(spells.POWER_WORD_SHIELD)
        return true
    end
    
    -- Use Desperate Prayer
    if settings.defensiveSettings.useDesperatePrayer and
       playerHealth <= settings.defensiveSettings.desperatePrayerThreshold and
       API.CanCast(spells.DESPERATE_PRAYER) then
        API.CastSpell(spells.DESPERATE_PRAYER)
        return true
    end
    
    -- Use Fade when taking damage
    if settings.defensiveSettings.useFade and
       API.IsPlayerTakingDamage() and
       API.CanCast(spells.FADE) then
        API.CastSpell(spells.FADE)
        return true
    end
    
    return false
end

-- Handle cooldowns
function Shadow:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    }
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive and not API.IsInCombat() then
        return false
    }
    
    -- Void Eruption / Void Form
    if settings.offensiveSettings.useVoidEruption and
       settings.abilityControls.voidEruption.enabled and
       not voidformActive and 
       API.CanCast(spells.VOID_ERUPTION) and
       currentInsanity >= settings.offensiveSettings.minInsanityForVoidform then
        
        -- Check dot requirements
        if not settings.abilityControls.voidEruption.minDotTargets or
           (shadowWordPainActive and vampiricTouchActive) then
            API.CastSpell(spells.VOID_ERUPTION)
            return true
        end
    end
    
    -- Dark Ascension (alternative to Void Eruption)
    if talents.hasDarkAscension and
       settings.offensiveSettings.useDarkAscension and
       settings.abilityControls.darkAscension.enabled and
       not darkAscensionActive and not voidformActive and
       API.CanCast(spells.DARK_ASCENSION) and
       currentInsanity >= settings.abilityControls.darkAscension.minInsanity then
        
        -- Only use during burst if configured that way
        if not settings.abilityControls.darkAscension.useDuringBurstOnly or burstModeActive then
            API.CastSpell(spells.DARK_ASCENSION)
            return true
        end
    end
    
    -- Use Shadowfiend/Mindbender
    if talents.hasMindbender and settings.offensiveSettings.useMindbender and 
       not mindbenderActive and API.CanCast(spells.MINDBENDER) then
        API.CastSpell(spells.MINDBENDER)
        return true
    elseif settings.offensiveSettings.useShadowfiend and 
           not shadowfiendActive and not mindbenderActive and 
           API.CanCast(spells.SHADOWFIEND) then
        API.CastSpell(spells.SHADOWFIEND)
        return true
    end
    
    -- Use Power Infusion
    if settings.offensiveSettings.usePowerInfusion and
       settings.abilityControls.powerInfusion.enabled and
       powerInfusionCastable then
        
        -- Check syncing options
        local shouldUse = false
        
        if settings.offensiveSettings.powerInfusionSync == "With Voidform" then
            shouldUse = voidformActive
        elseif settings.offensiveSettings.powerInfusionSync == "With Dark Ascension" then
            shouldUse = darkAscensionActive
        else -- On Cooldown
            shouldUse = true
        end
        
        if shouldUse then
            -- Check if we should self-cast
            if settings.abilityControls.powerInfusion.selfCast then
                API.CastSpellOnSelf(spells.POWER_INFUSION)
            else
                API.CastSpell(spells.POWER_INFUSION)
            end
            return true
        end
    end
    
    -- Use Void Torrent
    if talents.hasVoidTorrent and
       settings.offensiveSettings.useVoidTorrent and
       not voidTorrentChanneling and
       API.CanCast(spells.VOID_TORRENT) then
        
        -- Check usage strategy
        if settings.offensiveSettings.voidTorrentUsage == "With Devouring Plague" and devouringPlagueActive then
            API.CastSpell(spells.VOID_TORRENT)
            return true
        elseif settings.offensiveSettings.voidTorrentUsage == "For Insanity" and currentInsanity < 30 then
            API.CastSpell(spells.VOID_TORRENT)
            return true
        elseif settings.offensiveSettings.voidTorrentUsage == "On Cooldown" then
            API.CastSpell(spells.VOID_TORRENT)
            return true
        end
    end
    
    -- Use Mindgames
    if settings.offensiveSettings.useMindgames and
       not mindgamesActive and
       API.CanCast(spells.MINDGAMES) then
        
        -- Check sync options
        local shouldUse = false
        
        if settings.offensiveSettings.mindgamesSync == "With Voidform" then
            shouldUse = voidformActive
        elseif settings.offensiveSettings.mindgamesSync == "With Voidform Extension" then
            shouldUse = voidformActive and voidformEndTime - GetTime() < 5
        else -- On Cooldown
            shouldUse = true
        end
        
        if shouldUse then
            API.CastSpell(spells.MINDGAMES)
            return true
        end
    end
    
    return false
end

-- Handle DoT maintenance
function Shadow:HandleDoTs(settings)
    -- Use Damnation if available (applies all DoTs at once)
    if talents.hasDamnation and API.CanCast(spells.DAMNATION) and
       (not shadowWordPainActive or not vampiricTouchActive) then
        API.CastSpell(spells.DAMNATION)
        return true
    end
    
    -- Calculate DoT refresh timers based on settings
    local swpRefreshTime = 0
    local vtRefreshTime = 0
    
    if settings.rotationSettings.dotManagement == "Refresh at 30%" then
        swpRefreshTime = SHADOW_WORD_PAIN_DURATION * 0.3
        vtRefreshTime = VAMPIRIC_TOUCH_DURATION * 0.3
    elseif settings.rotationSettings.dotManagement == "Refresh at 50%" then
        swpRefreshTime = SHADOW_WORD_PAIN_DURATION * 0.5
        vtRefreshTime = VAMPIRIC_TOUCH_DURATION * 0.5
    elseif settings.rotationSettings.dotManagement == "Always Refresh" then
        swpRefreshTime = SHADOW_WORD_PAIN_DURATION * 0.95
        vtRefreshTime = VAMPIRIC_TOUCH_DURATION * 0.95
    end
    
    -- Handle Misery talent (Shadow Word: Pain applies Vampiric Touch)
    if talents.hasMisery then
        -- If Misery, just keep track of Vampiric Touch (which applies both)
        if not vampiricTouchActive or (vampiricTouchEndTime - GetTime() < vtRefreshTime) then
            if API.CanCast(spells.VAMPIRIC_TOUCH) then
                API.CastSpell(spells.VAMPIRIC_TOUCH)
                return true
            end
        end
    else
        -- Otherwise maintain both DoTs separately
        -- Apply/refresh Shadow Word: Pain
        if settings.rotationSettings.dotManagement != "Manual" and
           (not shadowWordPainActive or (shadowWordPainEndTime - GetTime() < swpRefreshTime)) and
           API.CanCast(spells.SHADOW_WORD_PAIN) then
            API.CastSpell(spells.SHADOW_WORD_PAIN)
            return true
        end
        
        -- Apply/refresh Vampiric Touch
        if settings.rotationSettings.dotManagement != "Manual" and
           (not vampiricTouchActive or (vampiricTouchEndTime - GetTime() < vtRefreshTime)) and
           API.CanCast(spells.VAMPIRIC_TOUCH) then
            API.CastSpell(spells.VAMPIRIC_TOUCH)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Shadow:HandleAoERotation(settings)
    -- Use Void Bolt in Voidform (highest priority always)
    if voidformActive and API.CanCast(spells.VOID_BOLT) then
        API.CastSpell(spells.VOID_BOLT)
        return true
    end
    
    -- Use Shadow Crash if enabled
    if settings.rotationSettings.useShadowCrash and
       shadowCrashCharges > 0 and
       API.CanCast(spells.SHADOW_CRASH) then
        API.CastSpellAtBestLocation(spells.SHADOW_CRASH, 8) -- 8 yard radius
        return true
    end
    
    -- Use Devouring Plague in AoE according to settings
    if API.CanCast(spells.DEVOURING_PLAGUE) and currentInsanity >= settings.advancedSettings.devouringPlagueThreshold then
        if settings.advancedSettings.useDevouringPlagueAoE == "At Threshold" or
           (settings.advancedSettings.useDevouringPlagueAoE == "To Spread Psychic Link" and talents.hasPsychicLink) then
            API.CastSpell(spells.DEVOURING_PLAGUE)
            return true
        end
    end
    
    -- Use Mind Blast if Deathspeaker proc is active
    if deathspeakerActive and mindBlastCharges > 0 and API.CanCast(spells.MIND_BLAST) then
        API.CastSpell(spells.MIND_BLAST)
        return true
    end
    
    -- Use Mind Blast with charges for Insanity generation
    if mindBlastCharges > 0 and API.CanCast(spells.MIND_BLAST) then
        API.CastSpell(spells.MIND_BLAST)
        return true
    end
    
    -- Use Searing Nightmare if talented
    if talents.hasSearingNightmare and
       API.CanCast(spells.MIND_SEAR) and
       currentInsanity >= 30 and
       (not mindSearChanneling) then
        -- Start Mind Sear to use Searing Nightmare
        API.CastSpell(spells.MIND_SEAR)
        return true
    elseif talents.hasSearingNightmare and mindSearChanneling and currentInsanity >= 30 then
        -- Use Searing Nightmare during Mind Sear channel
        API.CastSpell(spells.SEARING_NIGHTMARE)
        return true
    end
    
    -- Use Shadow Word: Death in execute range
    if shadowWordDeath and
       settings.rotationSettings.useShadowWordDeath and
       API.GetTargetHealthPercent() <= 20 and
       API.CanCast(spells.SHADOW_WORD_DEATH) then
        API.CastSpell(spells.SHADOW_WORD_DEATH)
        return true
    end
    
    -- Use Dark Void for AoE instead of normal SW:P
    if talents.hasDarkVoid and API.CanCast(spells.DARK_VOID) then
        API.CastSpell(spells.DARK_VOID)
        return true
    end
    
    -- Use Mind Spike with Idol of Yogg-Saron in AoE
    if idolOfYoggsaron and
       API.CanCast(spells.MIND_SPIKE) and
       (settings.rotationSettings.useMindSpikeWithIds == "On Cooldown" || 
        (settings.rotationSettings.useMindSpikeWithIds == "For Insanity" && currentInsanity < 50)) then
        API.CastSpell(spells.MIND_SPIKE)
        return true
    end
    
    -- Use Mind Sear as main AoE filler
    if not mindSearChanneling and API.CanCast(spells.MIND_SEAR) then
        API.CastSpell(spells.MIND_SEAR)
        return true
    end
    
    -- Continue existing Mind Sear channel if already channeling
    return false
end

-- Handle Single Target rotation
function Shadow:HandleSingleTargetRotation(settings)
    -- Use Void Bolt in Voidform (highest priority always)
    if voidformActive and API.CanCast(spells.VOID_BOLT) then
        API.CastSpell(spells.VOID_BOLT)
        return true
    end
    
    -- Use Devouring Plague according to settings
    if API.CanCast(spells.DEVOURING_PLAGUE) and
       (currentInsanity >= settings.advancedSettings.devouringPlagueThreshold || 
        (mindDevourerActive && settings.advancedSettings.useDevouringPlagueSingle == "With Mind Devourer") ||
        (settings.advancedSettings.useDevouringPlagueSingle == "On Cooldown" && not devouringPlagueActive)) then
        API.CastSpell(spells.DEVOURING_PLAGUE)
        return true
    end
    
    -- Use Mind Blast with Dark Thoughts proc (highest priority after Void Bolt)
    if darkThoughtsActive and API.CanCast(spells.MIND_BLAST) then
        API.CastSpell(spells.MIND_BLAST)
        return true
    end
    
    -- Use Shadow Word: Death in execute range
    if shadowWordDeath and
       settings.rotationSettings.useShadowWordDeath and
       API.GetTargetHealthPercent() <= 20 and
       API.CanCast(spells.SHADOW_WORD_DEATH) then
        API.CastSpell(spells.SHADOW_WORD_DEATH)
        return true
    end
    
    -- Use Mind Blast for Insanity generation
    if mindBlastCharges > 0 and API.CanCast(spells.MIND_BLAST) then
        API.CastSpell(spells.MIND_BLAST)
        return true
    end
    
    -- Use Shadow Crash for single target if enabled
    if settings.rotationSettings.useShadowCrash and
       shadowCrashCharges > 0 and
       API.CanCast(spells.SHADOW_CRASH) then
        API.CastSpell(spells.SHADOW_CRASH)
        return true
    end
    
    -- Use Mind Spike with Idol of Yogg-Saron in single target
    if idolOfYoggsaron and
       API.CanCast(spells.MIND_SPIKE) and
       (settings.rotationSettings.useMindSpikeWithIds == "On Cooldown" || 
        (settings.rotationSettings.useMindSpikeWithIds == "For Insanity" && currentInsanity < 50)) then
        API.CastSpell(spells.MIND_SPIKE)
        return true
    end
    
    -- Use Mind Flay as filler
    if not mindflayChanneling and API.CanCast(spells.MIND_FLAY) then
        API.CastSpell(spells.MIND_FLAY)
        return true
    end
    
    -- Continue existing Mind Flay channel if already channeling
    return false
end

-- Handle specialization change
function Shadow:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentAoETargets = 0
    currentInsanity = API.GetPlayerPower()
    maxInsanity = 100
    voidformActive = false
    voidformStacks = 0
    voidformEndTime = 0
    darkAscensionActive = false
    darkAscensionEndTime = 0
    shadowfiendActive = false
    shadowfiendEndTime = 0
    mindflayChanneling = false
    mindflayEndTime = 0
    mindSearChanneling = false
    mindSearEndTime = 0
    devouringPlagueActive = false
    devouringPlagueEndTime = 0
    shadowWordPainActive = false
    shadowWordPainEndTime = 0
    vampiricTouchActive = false
    vampiricTouchEndTime = 0
    darkThoughtsActive = false
    surgingDarknessStacks = 0
    surgingDarknessEndTime = 0
    deathspeakerActive = false
    deathspeakerEndTime = 0
    voidTorrentChanneling = false
    voidTorrentEndTime = 0
    hungryVoidActive = false
    mindDevourerActive = false
    shadowformActive = false
    surgeOfInsanityActive = false
    surgeOfInsanityEndTime = 0
    mentalDecayActive = false
    currentChannelSpell = 0
    dispersionActive = false
    dispersionEndTime = 0
    mindBlastCharges = API.GetSpellCharges(spells.MIND_BLAST) or 0
    mindBlastMaxCharges = API.GetSpellMaxCharges(spells.MIND_BLAST) or 1
    mindbenderActive = false
    mindbenderEndTime = 0
    inMeleeRange = false
    inMindSpikeRange = false
    mindSpikeInsanity = false
    shadowCrashCharges = API.GetSpellCharges(spells.SHADOW_CRASH) or 0
    damnationActive = false
    damnationEndTime = 0
    psychicLinkStacks = 0
    unfurlingDarkness = false
    distortedReality = false
    idolOfYoggsaron = false
    echoingVoid = false
    voidEruption = false
    dissonantEchoes = false
    mindMelt = false
    reaperOfSouls = false
    insidious = false
    mindDevourer = false
    callToTheVoid = false
    psychicLink = false
    mindsEye = false
    shadowyApparitions = false
    tormentedSpirits = false
    shadowWordDeath = false
    massDispel = false
    powerInfusionCastable = false
    mindgamesActive = false
    mindgamesEndTime = 0
    
    API.PrintDebug("Shadow Priest state reset on spec change")
    
    return true
end

-- Return the module for loading
return Shadow