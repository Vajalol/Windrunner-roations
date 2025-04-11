------------------------------------------
-- WindrunnerRotations - Mistweaver Monk Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Mistweaver = {}
-- This will be assigned to addon.Classes.Monk.Mistweaver when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Monk

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentMana = 100
local currentChi = 0
local maxChi = 5
local currentEnergy = 100
local maxEnergy = 100
local hasTeachingsOfTheMistweaver = false
local renewingMistActive = false
local renewingMistCount = 0
local renewingMistEndTime = 0
local lifeCycleActive = false
local lifeCycleMana = false
local lifeCycleViv = false
local lifeCycleEndTime = 0
local manaTea = false
local manaTeaActive = false
local manaTeaEndTime = 0
local invokeChi = false
local invokeChiActive = false
local invokeChiEndTime = 0
local soothingMist = false
local soothingMistActive = false
local soothingMistEndTime = 0
local enveloping = false
local envelopingActive = false
local envelopingMistEndTime = 0
local envelopingBreathActive = false
local envelopingBreathEndTime = 0
local essenceFont = false
local essenceFontActive = false
local essenceFontEndTime = 0
local thunderFocusTea = false
local thunderFocusTeaActive = false
local thunderFocusTeaEndTime = 0
local thunderFocusTeaStacks = 0
local focusedThunderActive = false
local focusedThunderStacks = 0
local focusedThunderEndTime = 0
local revival = false
local zenPulse = false
local surgeOfMist = false
local surgeOfMistActive = false
local surgeOfMistEndTime = 0
local surgeOfMistStacks = 0
local refreshingJadeWind = false
local refreshingJadeWindActive = false
local refreshingJadeWindEndTime = 0
local faeline = false
local faelineActive = false
local faelineEndTime = 0
local ancientConcordance = false
local ancientConcordanceActive = false
local ancientConcordanceEndTime = 0
local ancientConcordanceStacks = 0
local shaohaosLesson = false
local shaohaoLessonActive = false
local shaohaoLessonEndTime = 0
local shaohaoLessonStacks = 0
local restoralMist = false
local restoralMistActive = false
local restoralMistEndTime = 0
local restoral = false
local restoralActive = false
local restoralEndTime = 0
local invokeYulon = false
local invokeYulonActive = false
local invokeYulonEndTime = 0
local invokeYulonJadeBond = false
local steamyMist = false
local risingSunKickActive = false
local risingSunKickEndTime = 0
local blackoutKickActive = false
local blackoutKickEndTime = 0
local spinningCraneKickActive = false
local spinningCraneKickEndTime = 0
local tigerPalm = false
local risingSunKick = false
local blackoutKick = false
local touchOfDeath = false
local spinningCraneKick = false
local unison = false
local unisonActive = false
local unisonEndTime = 0
local unisonStacks = 0
local vividClarityActive = false
local vividClarityEndTime = 0
local jadeBond = false
local jadeBondActive = false
local jadeBondEndTime = 0
local celestialBreath = false
local celestialBreathActive = false
local celestialBreathEndTime = 0
local yulon = false
local chiJi = false
local invokeChiJi = false
local invokeChiJiActive = false
local invokeChiJiEndTime = 0
local chiCocoon = false
local chiCocoonActive = false
local chiCocoonEndTime = 0
local dampenHarm = false
local dampenHarmActive = false
local dampenHarmEndTime = 0
local fortifyingBrew = false
local fortifyingBrewActive = false
local fortifyingBrewEndTime = 0
local diffuseMagic = false
local diffuseMagicActive = false
local diffuseMagicEndTime = 0
local paralysis = false
local legSweep = false
local flyingSerpentKick = false
local tigersLust = false
local detox = false
local transcendence = false
local transcendenceTransfer = false
local cloudedFocus = false
local cloudedFocusActive = false
local cloudedFocusEndTime = 0
local cloudedFocusStacks = 0
local vivaciousVivification = false
local teaOfPlenty = false
local awakeningUnison = false
local profoundRebuttal = false
local lastEnveloping = 0
local lastRenewing = 0
local lastVivify = 0
local lastEssenceFont = 0
local lastLifeCocoon = 0
local lastRevival = 0
local lastThunderFocusTea = 0
local lastManaTea = 0
local lastZenPulse = 0
local lastRefreshingJadeWind = 0
local lastInvokeYulon = 0
local lastInvokeChiJi = 0
local lastSurgeOfMist = 0
local lastRestoralMist = 0
local lastRestoral = 0
local lastFaeTransfusion = 0
local lastFaeline = 0
local lastTigerPalm = 0
local lastRisingSunKick = 0
local lastBlackoutKick = 0
local lastTouchOfDeath = 0
local lastSpinningCraneKick = 0
local lastInvokeChi = 0
local lastDetox = 0
local lastParalysis = 0
local lastLegSweep = 0
local lastFlyingSerpentKick = 0
local lastTigersLust = 0
local lastTranscendence = 0
local lastTranscendenceTransfer = 0
local playerHealth = 100
local activeEnemies = 0
local meleeRange = 5
local isInMelee = false

-- Constants
local MISTWEAVER_SPEC_ID = 270
local SOOTHING_MIST_DURATION = 8.0 -- seconds
local RENEWING_MIST_DURATION = 20.0 -- seconds
local ENVELOPING_MIST_DURATION = 6.0 -- seconds
local ENVELOPING_BREATH_DURATION = 6.0 -- seconds
local ESSENCE_FONT_DURATION = 8.0 -- seconds
local THUNDER_FOCUS_TEA_DURATION = 30.0 -- seconds
local LIFE_CYCLE_DURATION = 15.0 -- seconds
local MANA_TEA_DURATION = 10.0 -- seconds
local INVOKE_CHI_DURATION = 30.0 -- seconds
local INVOKE_YULON_DURATION = 25.0 -- seconds
local INVOKE_CHIJI_DURATION = 25.0 -- seconds
local VIVID_CLARITY_DURATION = 5.0 -- seconds
local JADE_BOND_DURATION = 10.0 -- seconds
local CELESTIAL_BREATH_DURATION = 8.0 -- seconds
local CHI_COCOON_DURATION = 12.0 -- seconds
local DAMPEN_HARM_DURATION = 10.0 -- seconds
local FORTIFYING_BREW_DURATION = 15.0 -- seconds
local DIFFUSE_MAGIC_DURATION = 6.0 -- seconds
local UNISON_DURATION = 10.0 -- seconds
local REFRESHING_JADE_WIND_DURATION = 15.0 -- seconds
local ANCIENT_CONCORDANCE_DURATION = 12.0 -- seconds
local SURGE_OF_MIST_DURATION = 15.0 -- seconds
local SHAOHAOS_LESSON_DURATION = 30.0 -- seconds
local RESTORAL_MIST_DURATION = 8.0 -- seconds
local RESTORAL_DURATION = 8.0 -- seconds
local FAELINE_DURATION = 12.0 -- seconds
local CLOUDED_FOCUS_DURATION = 20.0 -- seconds

-- Initialize the Mistweaver module
function Mistweaver:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Mistweaver Monk module initialized")
    
    return true
end

-- Register spell IDs
function Mistweaver:RegisterSpells()
    -- Core healing abilities
    spells.SOOTHING_MIST = 115175
    spells.ENVELOPING_MIST = 124682
    spells.RENEWING_MIST = 115151
    spells.VIVIFY = 116670
    spells.LIFE_COCOON = 116849
    spells.ESSENCE_FONT = 191837
    spells.REVIVAL = 115310
    spells.THUNDER_FOCUS_TEA = 116680
    spells.ZEN_PULSE = 124081
    spells.RESTORAL = 388615
    spells.INVOKE_YULON = 322118
    spells.INVOKE_CHIJI = 325197
    spells.ENVELOPING_BREATH = 343655
    spells.MANA_TEA = 197908
    spells.REFRESHING_JADE_WIND = 196725
    spells.GUST_OF_MISTS = 191837
    spells.SHAOHAOS_LESSON = 387997
    spells.RESTORAL_MIST = 388615
    
    -- Core Monk universal abilities
    spells.TIGER_PALM = 100780
    spells.BLACKOUT_KICK = 100784
    spells.RISING_SUN_KICK = 107428
    spells.SPINNING_CRANE_KICK = 101546
    spells.TOUCH_OF_DEATH = 115080
    spells.CHI_BURST = 123986
    spells.CHI_WAVE = 115098
    spells.DETOX = 115450
    spells.PARALYSIS = 115078
    spells.LEG_SWEEP = 119381
    spells.FLYING_SERPENT_KICK = 101545
    spells.TRANSCENDENCE = 101643
    spells.TRANSCENDENCE_TRANSFER = 119996
    spells.FORTIFYING_BREW = 243435
    spells.DAMPEN_HARM = 122278
    spells.DIFFUSE_MAGIC = 122783
    spells.TIGERS_LUST = 116841
    
    -- Talents and passives
    spells.INVOKE_CHI_JI = 325197
    spells.JADE_BOND = 388470
    spells.VIVID_CLARITY = 387765
    spells.MIST_WRAP = 197900
    spells.TEACHINGS_OF_THE_MONASTERY = 116645
    spells.LIFECYCLES = 197915
    spells.ENVELOPING_BREATH = 343655
    spells.SPIRIT_OF_THE_CRANE = 210802
    spells.MANA_TEA = 197908
    spells.FOCUSED_THUNDER = 197895
    spells.RISING_MIST = 274909
    spells.SONG_OF_CHIJI = 198898
    spells.JADE_SERPENT_STATUE = 115313
    spells.ANCIENT_CONCORDANCE = 389391
    spells.SURGE_OF_MIST = 394132
    spells.FAELINE_STOMP = 388193
    spells.STEAMY_MIST = 395285
    spells.CLOUDED_FOCUS = 387512
    spells.VIVACIOUS_VIVIFICATION = 388812
    spells.TEA_OF_PLENTY = 388518
    spells.AWAKENING_UNISON = 388544
    spells.PROFOUND_REBUTTAL = 392910
    spells.UNISON = 394094

    -- War Within Season 2 specific
    spells.CELESTIAL_BREATH = 388779
    
    -- Buff IDs
    spells.SOOTHING_MIST_BUFF = 115175
    spells.RENEWING_MIST_BUFF = 119611
    spells.ENVELOPING_MIST_BUFF = 124682
    spells.ESSENCE_FONT_BUFF = 191837
    spells.THUNDER_FOCUS_TEA_BUFF = 116680
    spells.TEACHINGS_OF_THE_MONASTERY_BUFF = 202090
    spells.LIFECYCLES_VIVIFY_BUFF = 197916
    spells.LIFECYCLES_ENVELOPING_MIST_BUFF = 197919
    spells.MANA_TEA_BUFF = 197908
    spells.INVOKE_CHI_JI_BUFF = 343820
    spells.ENVELOPING_BREATH_BUFF = 343655
    spells.FOCUSED_THUNDER_BUFF = 197895
    spells.VIVID_CLARITY_BUFF = 387765
    spells.JADE_BOND_BUFF = 388470
    spells.CELESTIAL_BREATH_BUFF = 388779
    spells.LIFE_COCOON_BUFF = 116849
    spells.DAMPEN_HARM_BUFF = 122278
    spells.FORTIFYING_BREW_BUFF = 243435
    spells.DIFFUSE_MAGIC_BUFF = 122783
    spells.UNISON_BUFF = 394094
    spells.REFRESHING_JADE_WIND_BUFF = 196725
    spells.ANCIENT_CONCORDANCE_BUFF = 389391
    spells.SURGE_OF_MIST_BUFF = 394132
    spells.SHAOHAOS_LESSON_BUFF = 387997
    spells.RESTORAL_MIST_BUFF = 388615
    spells.RESTORAL_BUFF = 388615
    spells.FAELINE_STOMP_BUFF = 388193
    spells.CLOUDED_FOCUS_BUFF = 387512
    
    -- Debuff IDs
    spells.MYSTIC_TOUCH_DEBUFF = 113746
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SOOTHING_MIST = spells.SOOTHING_MIST_BUFF
    buffs.RENEWING_MIST = spells.RENEWING_MIST_BUFF
    buffs.ENVELOPING_MIST = spells.ENVELOPING_MIST_BUFF
    buffs.ESSENCE_FONT = spells.ESSENCE_FONT_BUFF
    buffs.THUNDER_FOCUS_TEA = spells.THUNDER_FOCUS_TEA_BUFF
    buffs.TEACHINGS_OF_THE_MONASTERY = spells.TEACHINGS_OF_THE_MONASTERY_BUFF
    buffs.LIFECYCLES_VIVIFY = spells.LIFECYCLES_VIVIFY_BUFF
    buffs.LIFECYCLES_ENVELOPING_MIST = spells.LIFECYCLES_ENVELOPING_MIST_BUFF
    buffs.MANA_TEA = spells.MANA_TEA_BUFF
    buffs.INVOKE_CHI_JI = spells.INVOKE_CHI_JI_BUFF
    buffs.ENVELOPING_BREATH = spells.ENVELOPING_BREATH_BUFF
    buffs.FOCUSED_THUNDER = spells.FOCUSED_THUNDER_BUFF
    buffs.VIVID_CLARITY = spells.VIVID_CLARITY_BUFF
    buffs.JADE_BOND = spells.JADE_BOND_BUFF
    buffs.CELESTIAL_BREATH = spells.CELESTIAL_BREATH_BUFF
    buffs.LIFE_COCOON = spells.LIFE_COCOON_BUFF
    buffs.DAMPEN_HARM = spells.DAMPEN_HARM_BUFF
    buffs.FORTIFYING_BREW = spells.FORTIFYING_BREW_BUFF
    buffs.DIFFUSE_MAGIC = spells.DIFFUSE_MAGIC_BUFF
    buffs.UNISON = spells.UNISON_BUFF
    buffs.REFRESHING_JADE_WIND = spells.REFRESHING_JADE_WIND_BUFF
    buffs.ANCIENT_CONCORDANCE = spells.ANCIENT_CONCORDANCE_BUFF
    buffs.SURGE_OF_MIST = spells.SURGE_OF_MIST_BUFF
    buffs.SHAOHAOS_LESSON = spells.SHAOHAOS_LESSON_BUFF
    buffs.RESTORAL_MIST = spells.RESTORAL_MIST_BUFF
    buffs.RESTORAL = spells.RESTORAL_BUFF
    buffs.FAELINE_STOMP = spells.FAELINE_STOMP_BUFF
    buffs.CLOUDED_FOCUS = spells.CLOUDED_FOCUS_BUFF
    
    debuffs.MYSTIC_TOUCH = spells.MYSTIC_TOUCH_DEBUFF
    
    return true
end

-- Register variables to track
function Mistweaver:RegisterVariables()
    -- Talent tracking
    talents.hasTeachingsOfTheMistweaver = false
    talents.hasLifeCycles = false
    talents.hasMistWrap = false
    talents.hasSpiritOfTheCrane = false
    talents.hasManaTea = false
    talents.hasFocusedThunder = false
    talents.hasRisingMist = false
    talents.hasSongOfChiJi = false
    talents.hasJadeSerpentStatue = false
    talents.hasAncientConcordance = false
    talents.hasSurgeOfMist = false
    talents.hasFaelineStomp = false
    talents.hasSteamyMist = false
    talents.hasCloudedFocus = false
    talents.hasVivaciousVivification = false
    talents.hasTeaOfPlenty = false
    talents.hasAwakeningUnison = false
    talents.hasProfoundRebuttal = false
    talents.hasInvokeYulon = false
    talents.hasInvokeChiJi = false
    talents.hasJadeBond = false
    talents.hasVividClarity = false
    talents.hasCelestialBreath = false
    talents.hasUnison = false
    talents.hasEnvelopingBreath = false
    talents.hasRefreshingJadeWind = false
    talents.hasShaohaosLesson = false
    talents.hasRestoralMist = false
    talents.hasRestoral = false
    talents.hasChiBurst = false
    talents.hasChiWave = false
    talents.hasDampenHarm = false
    talents.hasDiffuseMagic = false
    talents.hasTigersLust = false
    
    -- Initialize resources
    currentMana = API.GetPlayerManaPercentage() or 100
    currentChi = API.GetPlayerPower() or 0
    currentEnergy = API.GetPlayerEnergy() or 100
    
    -- Initialize other state variables
    soothingMistActive = false
    
    return true
end

-- Register spec-specific settings
function Mistweaver:RegisterSettings()
    ConfigRegistry:RegisterSettings("MistweaverMonk", {
        rotationSettings = {
            burstEnabled = {
                displayName = "Enable Burst Mode",
                description = "Use cooldowns and focus on burst healing",
                type = "toggle",
                default = true
            },
            manaManagement = {
                displayName = "Mana Management",
                description = "Optimize rotation for mana efficiency",
                type = "toggle",
                default = true
            },
            manaThreshold = {
                displayName = "Mana Threshold",
                description = "Minimum mana percentage to use expensive spells",
                type = "slider",
                min = 5,
                max = 50,
                default = 20
            },
            fistweaving = {
                displayName = "Enable Fistweaving",
                description = "Weave damaging abilities into healing rotation",
                type = "toggle",
                default = true
            },
            fistManaThreshold = {
                displayName = "Fistweaving Mana Threshold",
                description = "Minimum mana percentage to start fistweaving",
                type = "slider",
                min = 10,
                max = 80,
                default = 50
            },
            autoStatue = {
                displayName = "Auto Place Jade Serpent Statue",
                description = "Automatically place Jade Serpent Statue",
                type = "toggle",
                default = true
            },
            useDetox = {
                displayName = "Use Detox",
                description = "Automatically Detox harmful effects",
                type = "toggle",
                default = true
            },
            healingStyle = {
                displayName = "Healing Style",
                description = "Preferred healing style",
                type = "dropdown",
                options = {"Mana Efficient", "Throughput Focused", "Balanced"},
                default = "Balanced"
            },
            preventOverhealing = {
                displayName = "Prevent Overhealing",
                description = "Try to minimize overhealing",
                type = "toggle",
                default = true
            },
            maintainSoothingMist = {
                displayName = "Maintain Soothing Mist",
                description = "Keep Soothing Mist active on most injured ally",
                type = "toggle",
                default = false
            },
            renewingMistOnCooldown = {
                displayName = "Renewing Mist on Cooldown",
                description = "Use Renewing Mist whenever available",
                type = "toggle",
                default = true
            },
            renewingMistThreshold = {
                displayName = "Renewing Mist Health Threshold",
                description = "Health percentage to use Renewing Mist",
                type = "slider",
                min = 50,
                max = 100,
                default = 90
            },
            vivifyThreshold = {
                displayName = "Vivify Health Threshold",
                description = "Health percentage to use Vivify",
                type = "slider",
                min = 30,
                max = 90,
                default = 75
            },
            envelopingMistThreshold = {
                displayName = "Enveloping Mist Health Threshold",
                description = "Health percentage to use Enveloping Mist",
                type = "slider",
                min = 10,
                max = 80,
                default = 60
            }
        },
        
        thunderFocusTeaSettings = {
            useTFT = {
                displayName = "Use Thunder Focus Tea",
                description = "Automatically use Thunder Focus Tea",
                type = "toggle",
                default = true
            },
            tftPreference = {
                displayName = "TFT Preference",
                description = "Preferred spell to empower with Thunder Focus Tea",
                type = "dropdown",
                options = {"Vivify", "Renewing Mist", "Enveloping Mist", "Rising Sun Kick", "Smart Selection"},
                default = "Smart Selection"
            },
            tftVivifyThreshold = {
                displayName = "TFT Vivify Injured Count",
                description = "Minimum number of injured allies to use TFT Vivify",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            tftEnvelopingThreshold = {
                displayName = "TFT Enveloping Health Threshold",
                description = "Health percentage to use TFT Enveloping Mist",
                type = "slider",
                min = 10,
                max = 70,
                default = 50
            },
            tftRisingThreshold = {
                displayName = "TFT Rising Sun Kick Threshold",
                description = "Renewing Mist count to use TFT Rising Sun Kick",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            }
        },
        
        cooldownSettings = {
            useRevival = {
                displayName = "Use Revival",
                description = "Automatically use Revival",
                type = "toggle",
                default = true
            },
            revivalMode = {
                displayName = "Revival Usage",
                description = "When to use Revival",
                type = "dropdown",
                options = {"Emergency Only", "Injured Count", "Boss Only", "Manual Only"},
                default = "Injured Count"
            },
            revivalInjuredCount = {
                displayName = "Revival Injured Count",
                description = "Minimum number of injured allies to use Revival",
                type = "slider",
                min = 3,
                max = 10,
                default = 5
            },
            revivalHealthThreshold = {
                displayName = "Revival Health Threshold",
                description = "Health percentage to consider an ally injured for Revival",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useEssenceFont = {
                displayName = "Use Essence Font",
                description = "Automatically use Essence Font",
                type = "toggle",
                default = true
            },
            essenceFontMode = {
                displayName = "Essence Font Usage",
                description = "When to use Essence Font",
                type = "dropdown",
                options = {"Injured Count", "On Cooldown", "Manual Only"},
                default = "Injured Count"
            },
            essenceFontInjuredCount = {
                displayName = "Essence Font Injured Count",
                description = "Minimum number of injured allies to use Essence Font",
                type = "slider",
                min = 3,
                max = 8,
                default = 4
            },
            essenceFontThreshold = {
                displayName = "Essence Font Health Threshold",
                description = "Health percentage to consider an ally injured for Essence Font",
                type = "slider",
                min = 30,
                max = 90,
                default = 80
            },
            useInvokeYulon = {
                displayName = "Use Invoke Yu'lon",
                description = "Automatically use Invoke Yu'lon when talented",
                type = "toggle",
                default = true
            },
            invokeYulonMode = {
                displayName = "Invoke Yu'lon Usage",
                description = "When to use Invoke Yu'lon",
                type = "dropdown",
                options = {"Injured Count", "On Cooldown", "Burst Only", "Manual Only"},
                default = "Injured Count"
            },
            invokeYulonInjuredCount = {
                displayName = "Invoke Yu'lon Injured Count",
                description = "Minimum number of injured allies to use Invoke Yu'lon",
                type = "slider",
                min = 3,
                max = 10,
                default = 4
            },
            useInvokeChiJi = {
                displayName = "Use Invoke Chi-Ji",
                description = "Automatically use Invoke Chi-Ji when talented",
                type = "toggle",
                default = true
            },
            invokeChiJiMode = {
                displayName = "Invoke Chi-Ji Usage",
                description = "When to use Invoke Chi-Ji",
                type = "dropdown",
                options = {"Injured Count", "On Cooldown", "Burst Only", "Manual Only"},
                default = "Injured Count"
            },
            invokeChiJiInjuredCount = {
                displayName = "Invoke Chi-Ji Injured Count",
                description = "Minimum number of injured allies to use Invoke Chi-Ji",
                type = "slider",
                min = 3,
                max = 10,
                default = 4
            },
            useManaTea = {
                displayName = "Use Mana Tea",
                description = "Automatically use Mana Tea when talented",
                type = "toggle",
                default = true
            },
            manaTeaMode = {
                displayName = "Mana Tea Usage",
                description = "When to use Mana Tea",
                type = "dropdown",
                options = {"Low Mana", "Injured Count", "Burst Only", "Manual Only"},
                default = "Low Mana"
            },
            manaTeaThreshold = {
                displayName = "Mana Tea Mana Threshold",
                description = "Mana percentage to use Mana Tea",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useLifeCocoon = {
                displayName = "Use Life Cocoon",
                description = "Automatically use Life Cocoon",
                type = "toggle",
                default = true
            },
            lifeCocoonMode = {
                displayName = "Life Cocoon Usage",
                description = "How to use Life Cocoon",
                type = "dropdown",
                options = {"Tank Priority", "Lowest Health", "Smart Selection", "Manual Only"},
                default = "Smart Selection"
            },
            lifeCocoonThreshold = {
                displayName = "Life Cocoon Health Threshold",
                description = "Health percentage to use Life Cocoon",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            }
        },
        
        defensiveSettings = {
            useFortifyingBrew = {
                displayName = "Use Fortifying Brew",
                description = "Automatically use Fortifying Brew",
                type = "toggle",
                default = true
            },
            fortifyingBrewThreshold = {
                displayName = "Fortifying Brew Health Threshold",
                description = "Health percentage to use Fortifying Brew",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useDampenHarm = {
                displayName = "Use Dampen Harm",
                description = "Automatically use Dampen Harm when talented",
                type = "toggle",
                default = true
            },
            dampenHarmThreshold = {
                displayName = "Dampen Harm Health Threshold",
                description = "Health percentage to use Dampen Harm",
                type = "slider",
                min = 10,
                max = 60,
                default = 35
            },
            useDiffuseMagic = {
                displayName = "Use Diffuse Magic",
                description = "Automatically use Diffuse Magic when talented",
                type = "toggle",
                default = true
            },
            diffuseMagicThreshold = {
                displayName = "Diffuse Magic Health Threshold",
                description = "Health percentage to use Diffuse Magic",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useTigersLust = {
                displayName = "Use Tiger's Lust",
                description = "Automatically use Tiger's Lust when talented",
                type = "toggle",
                default = true
            },
            tigersLustMode = {
                displayName = "Tiger's Lust Usage",
                description = "How to use Tiger's Lust",
                type = "dropdown",
                options = {"Self Only", "Group Members", "Manual Only"},
                default = "Self Only"
            }
        },
        
        utilitySettings = {
            useParalysis = {
                displayName = "Use Paralysis",
                description = "Automatically use Paralysis for crowd control",
                type = "toggle",
                default = true
            },
            useLegSweep = {
                displayName = "Use Leg Sweep",
                description = "Automatically use Leg Sweep for AoE stun",
                type = "toggle",
                default = true
            },
            legSweepMinTargets = {
                displayName = "Leg Sweep Min Targets",
                description = "Minimum number of targets to use Leg Sweep",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            useTranscendence = {
                displayName = "Use Transcendence",
                description = "Automatically use Transcendence",
                type = "toggle",
                default = true
            },
            transcendenceMode = {
                displayName = "Transcendence Usage",
                description = "How to use Transcendence",
                type = "dropdown",
                options = {"Place on Cooldown", "Transfer When Low Health", "Manual Only"},
                default = "Manual Only"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Vivify controls
            vivify = AAC.RegisterAbility(spells.VIVIFY, {
                enabled = true,
                useDuringBurstOnly = false,
                requireReachableTarget = true,
                minMana = 20
            }),
            
            -- Essence Font controls
            essenceFont = AAC.RegisterAbility(spells.ESSENCE_FONT, {
                enabled = true,
                useDuringBurstOnly = false,
                minInjuredAllies = 3,
                minMana = 30
            }),
            
            -- Revival controls
            revival = AAC.RegisterAbility(spells.REVIVAL, {
                enabled = true,
                useDuringBurstOnly = false,
                minInjuredAllies = 4,
                emergencyOnly = false
            })
        }
    })
    
    return true
end

-- Register for events 
function Mistweaver:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for mana updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "MANA" then
            self:UpdateMana()
        end
    end)
    
    -- Register for energy updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "ENERGY" then
            self:UpdateEnergy()
        end
    end)
    
    -- Register for chi updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "CHI" then
            self:UpdateChi()
        end
    end)
    
    -- Register for health updates
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        if unit == "player" then
            self:UpdateHealth()
        end
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
function Mistweaver:UpdateTalentInfo()
    -- Check for important talents
    talents.hasTeachingsOfTheMistweaver = API.HasTalent(spells.TEACHINGS_OF_THE_MONASTERY)
    talents.hasLifeCycles = API.HasTalent(spells.LIFECYCLES)
    talents.hasMistWrap = API.HasTalent(spells.MIST_WRAP)
    talents.hasSpiritOfTheCrane = API.HasTalent(spells.SPIRIT_OF_THE_CRANE)
    talents.hasManaTea = API.HasTalent(spells.MANA_TEA)
    talents.hasFocusedThunder = API.HasTalent(spells.FOCUSED_THUNDER)
    talents.hasRisingMist = API.HasTalent(spells.RISING_MIST)
    talents.hasSongOfChiJi = API.HasTalent(spells.SONG_OF_CHIJI)
    talents.hasJadeSerpentStatue = API.HasTalent(spells.JADE_SERPENT_STATUE)
    talents.hasAncientConcordance = API.HasTalent(spells.ANCIENT_CONCORDANCE)
    talents.hasSurgeOfMist = API.HasTalent(spells.SURGE_OF_MIST)
    talents.hasFaelineStomp = API.HasTalent(spells.FAELINE_STOMP)
    talents.hasSteamyMist = API.HasTalent(spells.STEAMY_MIST)
    talents.hasCloudedFocus = API.HasTalent(spells.CLOUDED_FOCUS)
    talents.hasVivaciousVivification = API.HasTalent(spells.VIVACIOUS_VIVIFICATION)
    talents.hasTeaOfPlenty = API.HasTalent(spells.TEA_OF_PLENTY)
    talents.hasAwakeningUnison = API.HasTalent(spells.AWAKENING_UNISON)
    talents.hasProfoundRebuttal = API.HasTalent(spells.PROFOUND_REBUTTAL)
    talents.hasInvokeYulon = API.HasTalent(spells.INVOKE_YULON)
    talents.hasInvokeChiJi = API.HasTalent(spells.INVOKE_CHI_JI)
    talents.hasJadeBond = API.HasTalent(spells.JADE_BOND)
    talents.hasVividClarity = API.HasTalent(spells.VIVID_CLARITY)
    talents.hasCelestialBreath = API.HasTalent(spells.CELESTIAL_BREATH)
    talents.hasUnison = API.HasTalent(spells.UNISON)
    talents.hasEnvelopingBreath = API.HasTalent(spells.ENVELOPING_BREATH)
    talents.hasRefreshingJadeWind = API.HasTalent(spells.REFRESHING_JADE_WIND)
    talents.hasShaohaosLesson = API.HasTalent(spells.SHAOHAOS_LESSON)
    talents.hasRestoralMist = API.HasTalent(spells.RESTORAL_MIST)
    talents.hasRestoral = API.HasTalent(spells.RESTORAL)
    talents.hasChiBurst = API.HasTalent(spells.CHI_BURST)
    talents.hasChiWave = API.HasTalent(spells.CHI_WAVE)
    talents.hasDampenHarm = API.HasTalent(spells.DAMPEN_HARM)
    talents.hasDiffuseMagic = API.HasTalent(spells.DIFFUSE_MAGIC)
    talents.hasTigersLust = API.HasTalent(spells.TIGERS_LUST)
    
    -- Set specialized variables based on talents
    if talents.hasTeachingsOfTheMistweaver then
        hasTeachingsOfTheMistweaver = true
    end
    
    if talents.hasLifeCycles then
        lifeCycle = true
    end
    
    if talents.hasManaTea then
        manaTea = true
    end
    
    if talents.hasFocusedThunder then
        focusedThunder = true
    end
    
    if talents.hasInvokeYulon then
        invokeYulon = true
        yulon = true
    end
    
    if talents.hasInvokeChiJi then
        invokeChiJi = true
        chiJi = true
    end
    
    if talents.hasJadeBond then
        jadeBond = true
        if talents.hasInvokeYulon then
            invokeYulonJadeBond = true
        end
    end
    
    if talents.hasCelestialBreath then
        celestialBreath = true
    end
    
    if talents.hasSteamyMist then
        steamyMist = true
    end
    
    if talents.hasVividClarity then
        vividClarity = true
    end
    
    if talents.hasEnvelopingBreath then
        envelopingBreath = true
    end
    
    if talents.hasRefreshingJadeWind then
        refreshingJadeWind = true
    end
    
    if talents.hasShaohaosLesson then
        shaohaosLesson = true
    end
    
    if talents.hasRestoralMist then
        restoralMist = true
    end
    
    if talents.hasRestoral then
        restoral = true
    end
    
    if talents.hasCloudedFocus then
        cloudedFocus = true
    end
    
    if talents.hasVivaciousVivification then
        vivaciousVivification = true
    end
    
    if talents.hasTeaOfPlenty then
        teaOfPlenty = true
    end
    
    if talents.hasAwakeningUnison then
        awakeningUnison = true
    end
    
    if talents.hasProfoundRebuttal then
        profoundRebuttal = true
    end
    
    if talents.hasUnison then
        unison = true
    end
    
    if talents.hasFaelineStomp then
        faeline = true
    end
    
    if talents.hasAncientConcordance then
        ancientConcordance = true
    end
    
    if talents.hasSurgeOfMist then
        surgeOfMist = true
    end
    
    if talents.hasInvokeChi then
        invokeChi = true
    end
    
    if talents.hasZenPulse then
        zenPulse = true
    end
    
    if API.IsSpellKnown(spells.ESSENCE_FONT) then
        essenceFont = true
    end
    
    if API.IsSpellKnown(spells.THUNDER_FOCUS_TEA) then
        thunderFocusTea = true
    end
    
    if API.IsSpellKnown(spells.ENVELOPING_MIST) then
        enveloping = true
    end
    
    if API.IsSpellKnown(spells.SOOTHING_MIST) then
        soothingMist = true
    end
    
    if API.IsSpellKnown(spells.TIGER_PALM) then
        tigerPalm = true
    end
    
    if API.IsSpellKnown(spells.RISING_SUN_KICK) then
        risingSunKick = true
    end
    
    if API.IsSpellKnown(spells.BLACKOUT_KICK) then
        blackoutKick = true
    end
    
    if API.IsSpellKnown(spells.TOUCH_OF_DEATH) then
        touchOfDeath = true
    end
    
    if API.IsSpellKnown(spells.SPINNING_CRANE_KICK) then
        spinningCraneKick = true
    end
    
    if API.IsSpellKnown(spells.LIFE_COCOON) then
        chiCocoon = true
    end
    
    if API.IsSpellKnown(spells.FORTIFYING_BREW) then
        fortifyingBrew = true
    end
    
    if API.IsSpellKnown(spells.REVIVAL) then
        revival = true
    end
    
    if API.IsSpellKnown(spells.PARALYSIS) then
        paralysis = true
    end
    
    if API.IsSpellKnown(spells.LEG_SWEEP) then
        legSweep = true
    end
    
    if API.IsSpellKnown(spells.FLYING_SERPENT_KICK) then
        flyingSerpentKick = true
    end
    
    if API.IsSpellKnown(spells.TRANSCENDENCE) then
        transcendence = true
    end
    
    if API.IsSpellKnown(spells.TRANSCENDENCE_TRANSFER) then
        transcendenceTransfer = true
    end
    
    if API.IsSpellKnown(spells.DETOX) then
        detox = true
    end
    
    API.PrintDebug("Mistweaver Monk talents updated")
    
    return true
end

-- Update mana tracking
function Mistweaver:UpdateMana()
    currentMana = API.GetPlayerManaPercentage()
    return true
end

-- Update energy tracking
function Mistweaver:UpdateEnergy()
    currentEnergy = API.GetPlayerEnergy()
    maxEnergy = API.GetPlayerMaxEnergy()
    return true
end

-- Update chi tracking
function Mistweaver:UpdateChi()
    currentChi = API.GetPlayerPower()
    return true
end

-- Update health tracking
function Mistweaver:UpdateHealth()
    playerHealth = API.GetPlayerHealthPercent()
    return true
end

-- Update active enemy counts
function Mistweaver:UpdateEnemyCounts()
    activeEnemies = API.GetEnemyCount() or 0
    return true
end

-- Handle combat log events
function Mistweaver:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track player events (casts, buffs, etc.)
    if sourceGUID == API.GetPlayerGUID() then
        -- Track buff applications
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            -- Track Soothing Mist application
            if spellID == buffs.SOOTHING_MIST then
                soothingMistActive = true
                soothingMistEndTime = GetTime() + SOOTHING_MIST_DURATION
                API.PrintDebug("Soothing Mist activated")
            end
            
            -- Track Renewing Mist application
            if spellID == buffs.RENEWING_MIST then
                renewingMistActive = true
                renewingMistEndTime = GetTime() + RENEWING_MIST_DURATION
                renewingMistCount = renewingMistCount + 1
                API.PrintDebug("Renewing Mist activated, count: " .. renewingMistCount)
            end
            
            -- Track Enveloping Mist application
            if spellID == buffs.ENVELOPING_MIST then
                envelopingActive = true
                envelopingMistEndTime = GetTime() + ENVELOPING_MIST_DURATION
                API.PrintDebug("Enveloping Mist activated")
            end
            
            -- Track Enveloping Breath application
            if spellID == buffs.ENVELOPING_BREATH then
                envelopingBreathActive = true
                envelopingBreathEndTime = GetTime() + ENVELOPING_BREATH_DURATION
                API.PrintDebug("Enveloping Breath activated")
            end
            
            -- Track Essence Font application
            if spellID == buffs.ESSENCE_FONT then
                essenceFontActive = true
                essenceFontEndTime = GetTime() + ESSENCE_FONT_DURATION
                API.PrintDebug("Essence Font activated")
            end
            
            -- Track Thunder Focus Tea application
            if spellID == buffs.THUNDER_FOCUS_TEA then
                thunderFocusTeaActive = true
                thunderFocusTeaEndTime = GetTime() + THUNDER_FOCUS_TEA_DURATION
                thunderFocusTeaStacks = select(4, API.GetBuffInfo("player", buffs.THUNDER_FOCUS_TEA)) or 1
                API.PrintDebug("Thunder Focus Tea activated: " .. tostring(thunderFocusTeaStacks) .. " stack(s)")
            end
            
            -- Track Focused Thunder application
            if spellID == buffs.FOCUSED_THUNDER then
                focusedThunderActive = true
                focusedThunderEndTime = GetTime() + THUNDER_FOCUS_TEA_DURATION
                focusedThunderStacks = select(4, API.GetBuffInfo("player", buffs.FOCUSED_THUNDER)) or 1
                API.PrintDebug("Focused Thunder activated: " .. tostring(focusedThunderStacks) .. " stack(s)")
            end
            
            -- Track Teachings of the Monastery application
            if spellID == buffs.TEACHINGS_OF_THE_MONASTERY then
                API.PrintDebug("Teachings of the Monastery buff applied")
            end
            
            -- Track Lifecycles Vivify buff application
            if spellID == buffs.LIFECYCLES_VIVIFY then
                lifeCycleActive = true
                lifeCycleViv = true
                lifeCycleMana = false
                lifeCycleEndTime = GetTime() + LIFE_CYCLE_DURATION
                API.PrintDebug("Lifecycles (Vivify) activated")
            end
            
            -- Track Lifecycles Enveloping Mist buff application
            if spellID == buffs.LIFECYCLES_ENVELOPING_MIST then
                lifeCycleActive = true
                lifeCycleViv = false
                lifeCycleMana = true
                lifeCycleEndTime = GetTime() + LIFE_CYCLE_DURATION
                API.PrintDebug("Lifecycles (Enveloping Mist) activated")
            end
            
            -- Track Mana Tea application
            if spellID == buffs.MANA_TEA then
                manaTeaActive = true
                manaTeaEndTime = GetTime() + MANA_TEA_DURATION
                API.PrintDebug("Mana Tea activated")
            end
            
            -- Track Invoke Chi-Ji application
            if spellID == buffs.INVOKE_CHI_JI then
                invokeChiJiActive = true
                invokeChiJiEndTime = GetTime() + INVOKE_CHIJI_DURATION
                API.PrintDebug("Invoke Chi-Ji activated")
            end
            
            -- Track Vivid Clarity application
            if spellID == buffs.VIVID_CLARITY then
                vividClarityActive = true
                vividClarityEndTime = GetTime() + VIVID_CLARITY_DURATION
                API.PrintDebug("Vivid Clarity activated")
            end
            
            -- Track Jade Bond application
            if spellID == buffs.JADE_BOND then
                jadeBondActive = true
                jadeBondEndTime = GetTime() + JADE_BOND_DURATION
                API.PrintDebug("Jade Bond activated")
            end
            
            -- Track Celestial Breath application
            if spellID == buffs.CELESTIAL_BREATH then
                celestialBreathActive = true
                celestialBreathEndTime = GetTime() + CELESTIAL_BREATH_DURATION
                API.PrintDebug("Celestial Breath activated")
            end
            
            -- Track Dampen Harm application
            if spellID == buffs.DAMPEN_HARM then
                dampenHarmActive = true
                dampenHarmEndTime = GetTime() + DAMPEN_HARM_DURATION
                API.PrintDebug("Dampen Harm activated")
            end
            
            -- Track Fortifying Brew application
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = true
                fortifyingBrewEndTime = GetTime() + FORTIFYING_BREW_DURATION
                API.PrintDebug("Fortifying Brew activated")
            end
            
            -- Track Diffuse Magic application
            if spellID == buffs.DIFFUSE_MAGIC then
                diffuseMagicActive = true
                diffuseMagicEndTime = GetTime() + DIFFUSE_MAGIC_DURATION
                API.PrintDebug("Diffuse Magic activated")
            end
            
            -- Track Unison application
            if spellID == buffs.UNISON then
                unisonActive = true
                unisonEndTime = GetTime() + UNISON_DURATION
                unisonStacks = select(4, API.GetBuffInfo("player", buffs.UNISON)) or 1
                API.PrintDebug("Unison activated: " .. tostring(unisonStacks) .. " stack(s)")
            end
            
            -- Track Refreshing Jade Wind application
            if spellID == buffs.REFRESHING_JADE_WIND then
                refreshingJadeWindActive = true
                refreshingJadeWindEndTime = GetTime() + REFRESHING_JADE_WIND_DURATION
                API.PrintDebug("Refreshing Jade Wind activated")
            end
            
            -- Track Ancient Concordance application
            if spellID == buffs.ANCIENT_CONCORDANCE then
                ancientConcordanceActive = true
                ancientConcordanceEndTime = GetTime() + ANCIENT_CONCORDANCE_DURATION
                ancientConcordanceStacks = select(4, API.GetBuffInfo("player", buffs.ANCIENT_CONCORDANCE)) or 1
                API.PrintDebug("Ancient Concordance activated: " .. tostring(ancientConcordanceStacks) .. " stack(s)")
            end
            
            -- Track Surge of Mist application
            if spellID == buffs.SURGE_OF_MIST then
                surgeOfMistActive = true
                surgeOfMistEndTime = GetTime() + SURGE_OF_MIST_DURATION
                surgeOfMistStacks = select(4, API.GetBuffInfo("player", buffs.SURGE_OF_MIST)) or 1
                API.PrintDebug("Surge of Mist activated: " .. tostring(surgeOfMistStacks) .. " stack(s)")
            end
            
            -- Track Shaohaos Lesson application
            if spellID == buffs.SHAOHAOS_LESSON then
                shaohaoLessonActive = true
                shaohaoLessonEndTime = GetTime() + SHAOHAOS_LESSON_DURATION
                shaohaoLessonStacks = select(4, API.GetBuffInfo("player", buffs.SHAOHAOS_LESSON)) or 1
                API.PrintDebug("Shaohaos Lesson activated: " .. tostring(shaohaoLessonStacks) .. " stack(s)")
            end
            
            -- Track Restoral Mist application
            if spellID == buffs.RESTORAL_MIST then
                restoralMistActive = true
                restoralMistEndTime = GetTime() + RESTORAL_MIST_DURATION
                API.PrintDebug("Restoral Mist activated")
            end
            
            -- Track Restoral application
            if spellID == buffs.RESTORAL then
                restoralActive = true
                restoralEndTime = GetTime() + RESTORAL_DURATION
                API.PrintDebug("Restoral activated")
            end
            
            -- Track Faeline application
            if spellID == buffs.FAELINE_STOMP then
                faelineActive = true
                faelineEndTime = GetTime() + FAELINE_DURATION
                API.PrintDebug("Faeline activated")
            end
            
            -- Track Clouded Focus application
            if spellID == buffs.CLOUDED_FOCUS then
                cloudedFocusActive = true
                cloudedFocusEndTime = GetTime() + CLOUDED_FOCUS_DURATION
                cloudedFocusStacks = select(4, API.GetBuffInfo("player", buffs.CLOUDED_FOCUS)) or 1
                API.PrintDebug("Clouded Focus activated: " .. tostring(cloudedFocusStacks) .. " stack(s)")
            end
        end
        
        -- Track buff removals
        if eventType == "SPELL_AURA_REMOVED" then
            -- Track Soothing Mist removal
            if spellID == buffs.SOOTHING_MIST then
                soothingMistActive = false
                API.PrintDebug("Soothing Mist faded")
            end
            
            -- Track Renewing Mist removal
            if spellID == buffs.RENEWING_MIST then
                renewingMistCount = renewingMistCount - 1
                if renewingMistCount <= 0 then
                    renewingMistCount = 0
                    renewingMistActive = false
                end
                API.PrintDebug("Renewing Mist faded, count: " .. renewingMistCount)
            end
            
            -- Track Enveloping Mist removal
            if spellID == buffs.ENVELOPING_MIST then
                envelopingActive = false
                API.PrintDebug("Enveloping Mist faded")
            end
            
            -- Track Enveloping Breath removal
            if spellID == buffs.ENVELOPING_BREATH then
                envelopingBreathActive = false
                API.PrintDebug("Enveloping Breath faded")
            end
            
            -- Track Essence Font removal
            if spellID == buffs.ESSENCE_FONT then
                essenceFontActive = false
                API.PrintDebug("Essence Font faded")
            end
            
            -- Track Thunder Focus Tea removal
            if spellID == buffs.THUNDER_FOCUS_TEA then
                thunderFocusTeaActive = false
                thunderFocusTeaStacks = 0
                API.PrintDebug("Thunder Focus Tea faded")
            end
            
            -- Track Focused Thunder removal
            if spellID == buffs.FOCUSED_THUNDER then
                focusedThunderActive = false
                focusedThunderStacks = 0
                API.PrintDebug("Focused Thunder faded")
            end
            
            -- Track Lifecycles Vivify buff removal
            if spellID == buffs.LIFECYCLES_VIVIFY then
                if not API.UnitHasBuff("player", buffs.LIFECYCLES_ENVELOPING_MIST) then
                    lifeCycleActive = false
                end
                lifeCycleViv = false
                API.PrintDebug("Lifecycles (Vivify) faded")
            end
            
            -- Track Lifecycles Enveloping Mist buff removal
            if spellID == buffs.LIFECYCLES_ENVELOPING_MIST then
                if not API.UnitHasBuff("player", buffs.LIFECYCLES_VIVIFY) then
                    lifeCycleActive = false
                end
                lifeCycleMana = false
                API.PrintDebug("Lifecycles (Enveloping Mist) faded")
            end
            
            -- Track Mana Tea removal
            if spellID == buffs.MANA_TEA then
                manaTeaActive = false
                API.PrintDebug("Mana Tea faded")
            end
            
            -- Track Invoke Chi-Ji removal
            if spellID == buffs.INVOKE_CHI_JI then
                invokeChiJiActive = false
                API.PrintDebug("Invoke Chi-Ji faded")
            end
            
            -- Track Vivid Clarity removal
            if spellID == buffs.VIVID_CLARITY then
                vividClarityActive = false
                API.PrintDebug("Vivid Clarity faded")
            end
            
            -- Track Jade Bond removal
            if spellID == buffs.JADE_BOND then
                jadeBondActive = false
                API.PrintDebug("Jade Bond faded")
            end
            
            -- Track Celestial Breath removal
            if spellID == buffs.CELESTIAL_BREATH then
                celestialBreathActive = false
                API.PrintDebug("Celestial Breath faded")
            end
            
            -- Track Dampen Harm removal
            if spellID == buffs.DAMPEN_HARM then
                dampenHarmActive = false
                API.PrintDebug("Dampen Harm faded")
            end
            
            -- Track Fortifying Brew removal
            if spellID == buffs.FORTIFYING_BREW then
                fortifyingBrewActive = false
                API.PrintDebug("Fortifying Brew faded")
            end
            
            -- Track Diffuse Magic removal
            if spellID == buffs.DIFFUSE_MAGIC then
                diffuseMagicActive = false
                API.PrintDebug("Diffuse Magic faded")
            end
            
            -- Track Unison removal
            if spellID == buffs.UNISON then
                unisonActive = false
                unisonStacks = 0
                API.PrintDebug("Unison faded")
            end
            
            -- Track Refreshing Jade Wind removal
            if spellID == buffs.REFRESHING_JADE_WIND then
                refreshingJadeWindActive = false
                API.PrintDebug("Refreshing Jade Wind faded")
            end
            
            -- Track Ancient Concordance removal
            if spellID == buffs.ANCIENT_CONCORDANCE then
                ancientConcordanceActive = false
                ancientConcordanceStacks = 0
                API.PrintDebug("Ancient Concordance faded")
            end
            
            -- Track Surge of Mist removal
            if spellID == buffs.SURGE_OF_MIST then
                surgeOfMistActive = false
                surgeOfMistStacks = 0
                API.PrintDebug("Surge of Mist faded")
            end
            
            -- Track Shaohaos Lesson removal
            if spellID == buffs.SHAOHAOS_LESSON then
                shaohaoLessonActive = false
                shaohaoLessonStacks = 0
                API.PrintDebug("Shaohaos Lesson faded")
            end
            
            -- Track Restoral Mist removal
            if spellID == buffs.RESTORAL_MIST then
                restoralMistActive = false
                API.PrintDebug("Restoral Mist faded")
            end
            
            -- Track Restoral removal
            if spellID == buffs.RESTORAL then
                restoralActive = false
                API.PrintDebug("Restoral faded")
            end
            
            -- Track Faeline removal
            if spellID == buffs.FAELINE_STOMP then
                faelineActive = false
                API.PrintDebug("Faeline faded")
            end
            
            -- Track Clouded Focus removal
            if spellID == buffs.CLOUDED_FOCUS then
                cloudedFocusActive = false
                cloudedFocusStacks = 0
                API.PrintDebug("Clouded Focus faded")
            end
        end
        
        -- Track spell casts
        if eventType == "SPELL_CAST_SUCCESS" then
            if spellID == spells.ENVELOPING_MIST then
                lastEnveloping = GetTime()
                API.PrintDebug("Enveloping Mist cast")
            elseif spellID == spells.RENEWING_MIST then
                lastRenewing = GetTime()
                API.PrintDebug("Renewing Mist cast")
            elseif spellID == spells.VIVIFY then
                lastVivify = GetTime()
                API.PrintDebug("Vivify cast")
            elseif spellID == spells.ESSENCE_FONT then
                lastEssenceFont = GetTime()
                API.PrintDebug("Essence Font cast")
            elseif spellID == spells.LIFE_COCOON then
                lastLifeCocoon = GetTime()
                API.PrintDebug("Life Cocoon cast")
            elseif spellID == spells.REVIVAL then
                lastRevival = GetTime()
                API.PrintDebug("Revival cast")
            elseif spellID == spells.THUNDER_FOCUS_TEA then
                lastThunderFocusTea = GetTime()
                API.PrintDebug("Thunder Focus Tea cast")
            elseif spellID == spells.MANA_TEA then
                lastManaTea = GetTime()
                manaTeaActive = true
                manaTeaEndTime = GetTime() + MANA_TEA_DURATION
                API.PrintDebug("Mana Tea cast")
            elseif spellID == spells.ZEN_PULSE then
                lastZenPulse = GetTime()
                API.PrintDebug("Zen Pulse cast")
            elseif spellID == spells.REFRESHING_JADE_WIND then
                lastRefreshingJadeWind = GetTime()
                refreshingJadeWindActive = true
                refreshingJadeWindEndTime = GetTime() + REFRESHING_JADE_WIND_DURATION
                API.PrintDebug("Refreshing Jade Wind cast")
            elseif spellID == spells.INVOKE_YULON then
                lastInvokeYulon = GetTime()
                invokeYulonActive = true
                invokeYulonEndTime = GetTime() + INVOKE_YULON_DURATION
                API.PrintDebug("Invoke Yu'lon cast")
            elseif spellID == spells.INVOKE_CHIJI then
                lastInvokeChiJi = GetTime()
                invokeChiJiActive = true
                invokeChiJiEndTime = GetTime() + INVOKE_CHIJI_DURATION
                API.PrintDebug("Invoke Chi-Ji cast")
            elseif spellID == spells.SURGE_OF_MIST then
                lastSurgeOfMist = GetTime()
                API.PrintDebug("Surge of Mist cast")
            elseif spellID == spells.RESTORAL_MIST then
                lastRestoralMist = GetTime()
                API.PrintDebug("Restoral Mist cast")
            elseif spellID == spells.RESTORAL then
                lastRestoral = GetTime()
                API.PrintDebug("Restoral cast")
            elseif spellID == spells.FAELINE_STOMP then
                lastFaeline = GetTime()
                faelineActive = true
                faelineEndTime = GetTime() + FAELINE_DURATION
                API.PrintDebug("Faeline Stomp cast")
            elseif spellID == spells.TIGER_PALM then
                lastTigerPalm = GetTime()
                API.PrintDebug("Tiger Palm cast")
            elseif spellID == spells.RISING_SUN_KICK then
                lastRisingSunKick = GetTime()
                risingSunKickActive = true
                risingSunKickEndTime = GetTime() + 12 -- approximate debuff duration
                API.PrintDebug("Rising Sun Kick cast")
            elseif spellID == spells.BLACKOUT_KICK then
                lastBlackoutKick = GetTime()
                blackoutKickActive = true
                blackoutKickEndTime = GetTime() + 5 -- approximate effect duration
                API.PrintDebug("Blackout Kick cast")
            elseif spellID == spells.TOUCH_OF_DEATH then
                lastTouchOfDeath = GetTime()
                API.PrintDebug("Touch of Death cast")
            elseif spellID == spells.SPINNING_CRANE_KICK then
                lastSpinningCraneKick = GetTime()
                spinningCraneKickActive = true
                spinningCraneKickEndTime = GetTime() + 1.5 -- duration of channel
                API.PrintDebug("Spinning Crane Kick cast")
            elseif spellID == spells.DETOX then
                lastDetox = GetTime()
                API.PrintDebug("Detox cast")
            elseif spellID == spells.PARALYSIS then
                lastParalysis = GetTime()
                API.PrintDebug("Paralysis cast")
            elseif spellID == spells.LEG_SWEEP then
                lastLegSweep = GetTime()
                API.PrintDebug("Leg Sweep cast")
            elseif spellID == spells.FLYING_SERPENT_KICK then
                lastFlyingSerpentKick = GetTime()
                API.PrintDebug("Flying Serpent Kick cast")
            elseif spellID == spells.TIGERS_LUST then
                lastTigersLust = GetTime()
                API.PrintDebug("Tiger's Lust cast")
            elseif spellID == spells.TRANSCENDENCE then
                lastTranscendence = GetTime()
                API.PrintDebug("Transcendence cast")
            elseif spellID == spells.TRANSCENDENCE_TRANSFER then
                lastTranscendenceTransfer = GetTime()
                API.PrintDebug("Transcendence Transfer cast")
            elseif spellID == spells.INVOKE_CHI_JI then
                lastInvokeChi = GetTime()
                invokeChiActive = true
                invokeChiEndTime = GetTime() + INVOKE_CHI_DURATION
                API.PrintDebug("Invoke Chi cast")
            end
        end
    end
    
    -- Handle healing done to track various effects
    if eventType == "SPELL_HEAL" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.ENVELOPING_MIST or 
           spellID == spells.VIVIFY or
           spellID == spells.RENEWING_MIST then
            -- Track healing for various buffs/effects if needed
        end
    end
    
    return true
end

-- Main rotation function
function Mistweaver:RunRotation()
    -- Check if we should be running Mistweaver Monk logic
    if API.GetActiveSpecID() ~= MISTWEAVER_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("MistweaverMonk")
    
    -- Update variables
    self:UpdateMana()
    self:UpdateChi()
    self:UpdateEnergy()
    self:UpdateEnemyCounts()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Check if in melee range
    isInMelee = self:IsInMeleeRange("target")
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle out of combat actions
    if not API.IsInCombat() then
        return self:HandleOutOfCombat(settings)
    end
    
    -- Handle emergency situations
    if self:HandleEmergencies(settings) then
        return true
    end
    
    -- Handle cleansing with Detox
    if self:HandleDetox(settings) then
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle major healing cooldowns
    if self:HandleHealingCooldowns(settings) then
        return true
    end
    
    -- Handle Thunder Focus Tea usage
    if self:HandleThunderFocusTea(settings) then
        return true
    end
    
    -- Handle normal healing rotation
    if self:HandleHealing(settings) then
        return true
    end
    
    -- Handle fistweaving (if enabled and appropriate)
    if settings.rotationSettings.fistweaving and 
       currentMana <= settings.rotationSettings.fistManaThreshold and 
       self:HandleFistweaving(settings) then
        return true
    end
    
    return false
end

-- Check if unit is in melee range
function Mistweaver:IsInMeleeRange(unit)
    if not unit or not API.UnitExists(unit) then
        return false
    end
    
    return API.GetUnitDistance("player", unit) <= meleeRange
end

-- Handle out-of-combat actions
function Mistweaver:HandleOutOfCombat(settings)
    -- Apply Jade Serpent Statue if talented and enabled
    if talents.hasJadeSerpentStatue and settings.rotationSettings.autoStatue and API.CanCast(spells.JADE_SERPENT_STATUE) then
        API.CastSpellAtBestLocation(spells.JADE_SERPENT_STATUE)
        return true
    end
    
    -- Use Renewing Mist on cooldown if enabled
    if settings.rotationSettings.renewingMistOnCooldown and API.CanCast(spells.RENEWING_MIST) then
        local target = API.GetLowestHealthGroupMember()
        if target and API.GetUnitHealthPercent(target) < settings.rotationSettings.renewingMistThreshold then
            API.CastSpellOnUnit(spells.RENEWING_MIST, target)
            return true
        end
    end
    
    return false
end

-- Handle emergency situations
function Mistweaver:HandleEmergencies(settings)
    -- Use Life Cocoon on critically low allies
    if chiCocoon and settings.cooldownSettings.useLifeCocoon and API.CanCast(spells.LIFE_COCOON) then
        local target = nil
        local targetHealth = 100
        
        if settings.cooldownSettings.lifeCocoonMode == "Tank Priority" then
            -- Find lowest tank
            local lowestTank = API.GetLowestHealthTank()
            if lowestTank and API.GetUnitHealthPercent(lowestTank) <= settings.cooldownSettings.lifeCocoonThreshold then
                target = lowestTank
                targetHealth = API.GetUnitHealthPercent(lowestTank)
            end
        elseif settings.cooldownSettings.lifeCocoonMode == "Lowest Health" then
            -- Find lowest health ally
            local lowestAlly = API.GetLowestHealthGroupMember()
            if lowestAlly and API.GetUnitHealthPercent(lowestAlly) <= settings.cooldownSettings.lifeCocoonThreshold then
                target = lowestAlly
                targetHealth = API.GetUnitHealthPercent(lowestAlly)
            end
        elseif settings.cooldownSettings.lifeCocoonMode == "Smart Selection" then
            -- Smart logic - prioritize tanks but consider all allies
            local lowestTank = API.GetLowestHealthTank()
            local lowestAlly = API.GetLowestHealthGroupMember()
            
            if lowestTank and API.GetUnitHealthPercent(lowestTank) <= settings.cooldownSettings.lifeCocoonThreshold then
                target = lowestTank
                targetHealth = API.GetUnitHealthPercent(lowestTank)
            elseif lowestAlly and API.GetUnitHealthPercent(lowestAlly) <= settings.cooldownSettings.lifeCocoonThreshold - 10 then
                -- Only use on non-tank if they're very low (10% lower than threshold)
                target = lowestAlly
                targetHealth = API.GetUnitHealthPercent(lowestAlly)
            end
        end
        
        if target and targetHealth <= settings.cooldownSettings.lifeCocoonThreshold then
            API.CastSpellOnUnit(spells.LIFE_COCOON, target)
            return true
        end
    end
    
    -- Use Revival in critical situations
    if revival and 
       settings.cooldownSettings.useRevival and 
       settings.cooldownSettings.revivalMode == "Emergency Only" and
       settings.abilityControls.revival.emergencyOnly and
       API.CanCast(spells.REVIVAL) then
        
        local criticalCount = API.GetInjuredGroupMembersCount(30) -- Hard-coded 30% for emergency
        
        if criticalCount >= 3 then -- At least 3 critical members for emergency
            API.CastSpell(spells.REVIVAL)
            return true
        end
    end
    
    -- Emergency Healing - Surge of Mist Enveloping Mist
    if surgeOfMistActive and enveloping and API.CanCast(spells.ENVELOPING_MIST) then
        local lowestTarget = API.GetLowestHealthGroupMember()
        if lowestTarget and API.GetUnitHealthPercent(lowestTarget) < 40 then -- Emergency threshold
            API.CastSpellOnUnit(spells.ENVELOPING_MIST, lowestTarget)
            return true
        end
    end
    
    return false
end

-- Handle Detox (cleansing)
function Mistweaver:HandleDetox(settings)
    if not detox or not settings.rotationSettings.useDetox or not API.CanCast(spells.DETOX) then
        return false
    end
    
    -- Check for dispellable debuffs on group members
    for i = 1, API.GetGroupSize() do
        local unit
        if API.IsInRaid() then
            unit = "raid" .. i
        else
            unit = i == 1 and "player" or "party" .. (i - 1)
        end
        
        if API.UnitExists(unit) and not API.UnitIsDead(unit) then
            -- Check for dispellable debuffs (poison, disease, magic)
            if API.CanDispelUnit(unit, "Poison") or API.CanDispelUnit(unit, "Disease") then
                API.CastSpellOnUnit(spells.DETOX, unit)
                return true
            end
        end
    end
    
    return false
end

-- Handle defensive abilities
function Mistweaver:HandleDefensives(settings)
    -- Use Fortifying Brew when health is low
    if fortifyingBrew and 
       settings.defensiveSettings.useFortifyingBrew and 
       playerHealth <= settings.defensiveSettings.fortifyingBrewThreshold and 
       API.CanCast(spells.FORTIFYING_BREW) then
        API.CastSpell(spells.FORTIFYING_BREW)
        return true
    end
    
    -- Use Dampen Harm when health is low
    if dampenHarm and 
       settings.defensiveSettings.useDampenHarm and 
       playerHealth <= settings.defensiveSettings.dampenHarmThreshold and 
       API.CanCast(spells.DAMPEN_HARM) then
        API.CastSpell(spells.DAMPEN_HARM)
        return true
    end
    
    -- Use Diffuse Magic when health is low and taking magic damage
    if diffuseMagic and 
       settings.defensiveSettings.useDiffuseMagic and 
       playerHealth <= settings.defensiveSettings.diffuseMagicThreshold and 
       API.CanCast(spells.DIFFUSE_MAGIC) and
       API.IsTakingMagicDamage("player") then
        API.CastSpell(spells.DIFFUSE_MAGIC)
        return true
    end
    
    -- Use Tiger's Lust
    if tigersLust and 
       settings.defensiveSettings.useTigersLust and 
       settings.defensiveSettings.tigersLustMode ~= "Manual Only" and
       API.CanCast(spells.TIGERS_LUST) then
        
        if settings.defensiveSettings.tigersLustMode == "Self Only" and API.IsPlayerMovementImpaired() then
            API.CastSpellOnUnit(spells.TIGERS_LUST, "player")
            return true
        elseif settings.defensiveSettings.tigersLustMode == "Group Members" then
            for i = 1, API.GetGroupSize() do
                local unit
                if API.IsInRaid() then
                    unit = "raid" .. i
                else
                    unit = i == 1 and "player" or "party" .. (i - 1)
                end
                
                if API.UnitExists(unit) and not API.UnitIsDead(unit) and API.IsUnitMovementImpaired(unit) then
                    API.CastSpellOnUnit(spells.TIGERS_LUST, unit)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle major healing cooldowns
function Mistweaver:HandleHealingCooldowns(settings)
    -- Use Revival
    if revival and 
       settings.cooldownSettings.useRevival and 
       settings.cooldownSettings.revivalMode ~= "Manual Only" and
       settings.abilityControls.revival.enabled and
       API.CanCast(spells.REVIVAL) then
        
        local shouldUseRevival = false
        local injuredCount = API.GetInjuredGroupMembersCount(settings.cooldownSettings.revivalHealthThreshold)
        
        if settings.cooldownSettings.revivalMode == "Injured Count" then
            shouldUseRevival = injuredCount >= settings.cooldownSettings.revivalInjuredCount
        elseif settings.cooldownSettings.revivalMode == "Boss Only" then
            shouldUseRevival = API.IsFightingBoss() and injuredCount >= 3
        end
        
        if settings.abilityControls.revival.minInjuredAllies > 0 then
            shouldUseRevival = shouldUseRevival and injuredCount >= settings.abilityControls.revival.minInjuredAllies
        end
        
        if settings.abilityControls.revival.useDuringBurstOnly then
            shouldUseRevival = shouldUseRevival and burstModeActive
        end
        
        if shouldUseRevival then
            API.CastSpell(spells.REVIVAL)
            return true
        end
    end
    
    -- Use Essence Font
    if essenceFont and 
       settings.cooldownSettings.useEssenceFont and 
       settings.cooldownSettings.essenceFontMode ~= "Manual Only" and
       settings.abilityControls.essenceFont.enabled and
       API.CanCast(spells.ESSENCE_FONT) then
        
        local shouldUseEssenceFont = false
        local injuredCount = API.GetInjuredGroupMembersCount(settings.cooldownSettings.essenceFontThreshold)
        
        if settings.cooldownSettings.essenceFontMode == "Injured Count" then
            shouldUseEssenceFont = injuredCount >= settings.cooldownSettings.essenceFontInjuredCount
        elseif settings.cooldownSettings.essenceFontMode == "On Cooldown" then
            shouldUseEssenceFont = true
        end
        
        if settings.abilityControls.essenceFont.minInjuredAllies > 0 then
            shouldUseEssenceFont = shouldUseEssenceFont and injuredCount >= settings.abilityControls.essenceFont.minInjuredAllies
        end
        
        if settings.abilityControls.essenceFont.useDuringBurstOnly then
            shouldUseEssenceFont = shouldUseEssenceFont and burstModeActive
        end
        
        if settings.abilityControls.essenceFont.minMana > 0 then
            shouldUseEssenceFont = shouldUseEssenceFont and currentMana > settings.abilityControls.essenceFont.minMana
        end
        
        if shouldUseEssenceFont then
            API.CastSpell(spells.ESSENCE_FONT)
            return true
        end
    end
    
    -- Use Invoke Yu'lon
    if invokeYulon and 
       settings.cooldownSettings.useInvokeYulon and 
       settings.cooldownSettings.invokeYulonMode ~= "Manual Only" and
       API.CanCast(spells.INVOKE_YULON) then
        
        local shouldUseYulon = false
        local injuredCount = API.GetInjuredGroupMembersCount(75) -- Default threshold for Yulon
        
        if settings.cooldownSettings.invokeYulonMode == "Injured Count" then
            shouldUseYulon = injuredCount >= settings.cooldownSettings.invokeYulonInjuredCount
        elseif settings.cooldownSettings.invokeYulonMode == "On Cooldown" then
            shouldUseYulon = true
        elseif settings.cooldownSettings.invokeYulonMode == "Burst Only" then
            shouldUseYulon = burstModeActive
        end
        
        if shouldUseYulon then
            API.CastSpell(spells.INVOKE_YULON)
            return true
        end
    end
    
    -- Use Invoke Chi-Ji
    if invokeChiJi and 
       settings.cooldownSettings.useInvokeChiJi and 
       settings.cooldownSettings.invokeChiJiMode ~= "Manual Only" and
       API.CanCast(spells.INVOKE_CHIJI) then
        
        local shouldUseChiJi = false
        local injuredCount = API.GetInjuredGroupMembersCount(75) -- Default threshold for Chi-Ji
        
        if settings.cooldownSettings.invokeChiJiMode == "Injured Count" then
            shouldUseChiJi = injuredCount >= settings.cooldownSettings.invokeChiJiInjuredCount
        elseif settings.cooldownSettings.invokeChiJiMode == "On Cooldown" then
            shouldUseChiJi = true
        elseif settings.cooldownSettings.invokeChiJiMode == "Burst Only" then
            shouldUseChiJi = burstModeActive
        end
        
        if shouldUseChiJi then
            API.CastSpell(spells.INVOKE_CHIJI)
            return true
        end
    end
    
    -- Use Mana Tea
    if manaTea and 
       settings.cooldownSettings.useManaTea and 
       settings.cooldownSettings.manaTeaMode ~= "Manual Only" and
       API.CanCast(spells.MANA_TEA) then
        
        local shouldUseManaTea = false
        
        if settings.cooldownSettings.manaTeaMode == "Low Mana" then
            shouldUseManaTea = currentMana <= settings.cooldownSettings.manaTeaThreshold
        elseif settings.cooldownSettings.manaTeaMode == "Injured Count" then
            local injuredCount = API.GetInjuredGroupMembersCount(70)
            shouldUseManaTea = injuredCount >= 3 and currentMana < 70 -- General threshold
        elseif settings.cooldownSettings.manaTeaMode == "Burst Only" then
            shouldUseManaTea = burstModeActive and currentMana < 80
        end
        
        if shouldUseManaTea then
            API.CastSpell(spells.MANA_TEA)
            return true
        end
    end
    
    return false
end

-- Handle Thunder Focus Tea usage
function Mistweaver:HandleThunderFocusTea(settings)
    if not thunderFocusTea or 
       not settings.thunderFocusTeaSettings.useTFT or 
       not API.CanCast(spells.THUNDER_FOCUS_TEA) then
        return false
    end
    
    -- Determine if we should use Thunder Focus Tea based on situation
    local shouldUseTFT = false
    local plannedTFTSpell = nil
    
    if settings.thunderFocusTeaSettings.tftPreference == "Vivify" then
        local injuredCount = API.GetInjuredGroupMembersCount(settings.rotationSettings.vivifyThreshold)
        shouldUseTFT = injuredCount >= settings.thunderFocusTeaSettings.tftVivifyThreshold
        plannedTFTSpell = spells.VIVIFY
    elseif settings.thunderFocusTeaSettings.tftPreference == "Renewing Mist" then
        shouldUseTFT = true -- Always good for spreading
        plannedTFTSpell = spells.RENEWING_MIST
    elseif settings.thunderFocusTeaSettings.tftPreference == "Enveloping Mist" then
        local lowestUnit = API.GetLowestHealthGroupMember()
        shouldUseTFT = lowestUnit and API.GetUnitHealthPercent(lowestUnit) <= settings.thunderFocusTeaSettings.tftEnvelopingThreshold
        plannedTFTSpell = spells.ENVELOPING_MIST
    elseif settings.thunderFocusTeaSettings.tftPreference == "Rising Sun Kick" and talents.hasRisingMist then
        shouldUseTFT = renewingMistCount >= settings.thunderFocusTeaSettings.tftRisingThreshold
        plannedTFTSpell = spells.RISING_SUN_KICK
    elseif settings.thunderFocusTeaSettings.tftPreference == "Smart Selection" then
        -- Make a smart choice based on situation
        local lowestHealthPercent = 100
        local lowestUnit = nil
        
        -- Check for critically low target for Enveloping Mist
        local lowestMember = API.GetLowestHealthGroupMember()
        if lowestMember then
            lowestHealthPercent = API.GetUnitHealthPercent(lowestMember)
            lowestUnit = lowestMember
        end
        
        if lowestHealthPercent <= settings.thunderFocusTeaSettings.tftEnvelopingThreshold and API.CanCast(spells.ENVELOPING_MIST) then
            shouldUseTFT = true
            plannedTFTSpell = spells.ENVELOPING_MIST
        elseif talents.hasRisingMist and renewingMistCount >= settings.thunderFocusTeaSettings.tftRisingThreshold and API.CanCast(spells.RISING_SUN_KICK) then
            shouldUseTFT = true
            plannedTFTSpell = spells.RISING_SUN_KICK
        elseif API.GetInjuredGroupMembersCount(settings.rotationSettings.vivifyThreshold) >= settings.thunderFocusTeaSettings.tftVivifyThreshold and API.CanCast(spells.VIVIFY) then
            shouldUseTFT = true
            plannedTFTSpell = spells.VIVIFY
        elseif API.CanCast(spells.RENEWING_MIST) then
            shouldUseTFT = true
            plannedTFTSpell = spells.RENEWING_MIST
        end
    end
    
    -- Use Thunder Focus Tea if appropriate
    if shouldUseTFT then
        API.CastSpell(spells.THUNDER_FOCUS_TEA)
        
        -- Queue the follow-up spell if needed and available
        if plannedTFTSpell and API.CanCast(plannedTFTSpell) then
            nextCastOverride = plannedTFTSpell
        end
        
        return true
    end
    
    return false
end

-- Handle normal healing rotation
function Mistweaver:HandleHealing(settings)
    -- Use Renewing Mist on cooldown if enabled
    if API.CanCast(spells.RENEWING_MIST) and settings.rotationSettings.renewingMistOnCooldown then
        local target = API.GetLowestHealthGroupMember()
        
        -- Skip if target already has Renewing Mist
        if target and not API.UnitHasBuff(target, buffs.RENEWING_MIST) and 
           API.GetUnitHealthPercent(target) < settings.rotationSettings.renewingMistThreshold then
            
            -- If Thunder Focus Tea is active, preferred spell is Renewing Mist
            if thunderFocusTeaActive and 
               (settings.thunderFocusTeaSettings.tftPreference == "Renewing Mist" or
                settings.thunderFocusTeaSettings.tftPreference == "Smart Selection") then
                API.CastSpellOnUnit(spells.RENEWING_MIST, target)
                return true
            elseif not thunderFocusTeaActive then
                API.CastSpellOnUnit(spells.RENEWING_MIST, target)
                return true
            end
        end
    end
    
    -- Use Chi Burst if talented
    if talents.hasChiBurst and API.CanCast(spells.CHI_BURST) and API.GetInjuredGroupMembersInFront(80) >= 2 then
        API.CastSpell(spells.CHI_BURST)
        return true
    end
    
    -- Use Chi Wave if talented
    if talents.hasChiWave and API.CanCast(spells.CHI_WAVE) then
        local target = API.GetLowestHealthGroupMember()
        if target and API.GetUnitHealthPercent(target) < 90 then
            API.CastSpellOnUnit(spells.CHI_WAVE, target)
            return true
        elseif API.UnitExists("target") and API.IsUnitEnemy("target") then
            API.CastSpellOnUnit(spells.CHI_WAVE, "target")
            return true
        end
    end
    
    -- Apply/maintain Soothing Mist if setting enabled
    if soothingMist and 
       settings.rotationSettings.maintainSoothingMist and 
       not soothingMistActive and
       API.CanCast(spells.SOOTHING_MIST) then
        local target = API.GetLowestHealthGroupMember()
        if target and API.GetUnitHealthPercent(target) < 90 then
            API.CastSpellOnUnit(spells.SOOTHING_MIST, target)
            return true
        end
    end
    
    -- Use Enveloping Mist on critically low target
    if enveloping and API.CanCast(spells.ENVELOPING_MIST) then
        local target = API.GetLowestHealthGroupMember()
        
        if target and API.GetUnitHealthPercent(target) <= settings.rotationSettings.envelopingMistThreshold and
           not API.UnitHasBuff(target, buffs.ENVELOPING_MIST) then
            
            -- If Surge of Mist is active, prioritize using it
            if surgeOfMistActive then
                API.CastSpellOnUnit(spells.ENVELOPING_MIST, target)
                return true
            end
            
            -- If Thunder Focus Tea is active, preferred spell is Enveloping Mist
            if thunderFocusTeaActive and 
               (settings.thunderFocusTeaSettings.tftPreference == "Enveloping Mist" or
                settings.thunderFocusTeaSettings.tftPreference == "Smart Selection") then
                API.CastSpellOnUnit(spells.ENVELOPING_MIST, target)
                return true
            end
            
            -- Check mana management and cast accordingly
            if not settings.rotationSettings.manaManagement or 
               currentMana > settings.rotationSettings.manaThreshold or
               (lifeCycleActive and lifeCycleMana) then
                API.CastSpellOnUnit(spells.ENVELOPING_MIST, target)
                return true
            end
        end
    end
    
    -- Use Vivify for efficient group healing
    if API.CanCast(spells.VIVIFY) and
       settings.abilityControls.vivify.enabled then
        
        local target = API.GetLowestHealthGroupMember()
        
        if target and API.GetUnitHealthPercent(target) <= settings.rotationSettings.vivifyThreshold then
            -- Check mana requirements
            local canCastVivify = true
            
            if settings.abilityControls.vivify.minMana > 0 and currentMana < settings.abilityControls.vivify.minMana then
                canCastVivify = false
            end
            
            if settings.abilityControls.vivify.useDuringBurstOnly and not burstModeActive then
                canCastVivify = false
            end
            
            if settings.abilityControls.vivify.requireReachableTarget and not API.IsUnitInRange(target, 40) then
                canCastVivify = false
            end
            
            -- Check mana management setting
            if settings.rotationSettings.manaManagement and currentMana < settings.rotationSettings.manaThreshold and 
               not (thunderFocusTeaActive or lifeCycleActive and lifeCycleViv) then
                canCastVivify = false
            end
            
            -- Thunder Focus Tea + Vivify combo if appropriate
            if thunderFocusTeaActive and 
               (settings.thunderFocusTeaSettings.tftPreference == "Vivify" or
                settings.thunderFocusTeaSettings.tftPreference == "Smart Selection") then
                canCastVivify = true
            end
            
            if canCastVivify then
                API.CastSpellOnUnit(spells.VIVIFY, target)
                return true
            end
        end
    end
    
    -- Use Zen Pulse if talented and useful
    if zenPulse and API.CanCast(spells.ZEN_PULSE) then
        local target = API.GetUnitWithHostileNearby()
        if target and API.GetUnitHealthPercent(target) < 90 then
            API.CastSpellOnUnit(spells.ZEN_PULSE, target)
            return true
        end
    end
    
    -- Use Refreshing Jade Wind in AoE situations
    if refreshingJadeWind and 
       not refreshingJadeWindActive and
       API.CanCast(spells.REFRESHING_JADE_WIND) and 
       API.GetInjuredGroupMembersInRange(90, 10) >= 3 then -- Within 10 yards, below 90%
        API.CastSpell(spells.REFRESHING_JADE_WIND)
        return true
    end
    
    -- Use Restoral if talented and appropriate
    if restoral and API.CanCast(spells.RESTORAL) and API.GetInjuredGroupMembersCount(60) >= 3 then
        API.CastSpell(spells.RESTORAL)
        return true
    end
    
    -- Use Faeline Stomp if talented
    if faeline and not faelineActive and API.CanCast(spells.FAELINE_STOMP) then
        API.CastSpellAtBestLocation(spells.FAELINE_STOMP)
        return true
    end
    
    return false
end

-- Handle fistweaving rotation
function Mistweaver:HandleFistweaving(settings)
    -- Only fistweave if enabled and we're in melee range
    if not settings.rotationSettings.fistweaving or not isInMelee then
        return false
    end
    
    -- Use Rising Sun Kick to extend Renewing Mist with Rising Mist talent
    if risingSunKick and 
       talents.hasRisingMist and 
       renewingMistCount >= 2 and
       API.CanCast(spells.RISING_SUN_KICK) then
        
        -- If Thunder Focus Tea is active, preferred spell is Rising Sun Kick
        if thunderFocusTeaActive and 
           (settings.thunderFocusTeaSettings.tftPreference == "Rising Sun Kick" or
            settings.thunderFocusTeaSettings.tftPreference == "Smart Selection") then
            API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
            return true
        else
            API.CastSpellOnUnit(spells.RISING_SUN_KICK, "target")
            return true
        end
    end
    
    -- Use Blackout Kick to reduce Rising Sun Kick cooldown and generate Chi
    if blackoutKick and API.CanCast(spells.BLACKOUT_KICK) then
        API.CastSpellOnUnit(spells.BLACKOUT_KICK, "target")
        return true
    end
    
    -- Use Tiger Palm to generate Chi
    if tigerPalm and API.CanCast(spells.TIGER_PALM) then
        API.CastSpellOnUnit(spells.TIGER_PALM, "target")
        return true
    end
    
    -- Use Touch of Death if available and target is below 15% health
    if touchOfDeath and
       API.CanCast(spells.TOUCH_OF_DEATH) and
       API.GetTargetHealthPercent() < 15 then
        API.CastSpellOnUnit(spells.TOUCH_OF_DEATH, "target")
        return true
    end
    
    -- Use Spinning Crane Kick in AoE situations
    if spinningCraneKick and
       API.CanCast(spells.SPINNING_CRANE_KICK) and
       activeEnemies >= 3 then
        API.CastSpell(spells.SPINNING_CRANE_KICK)
        return true
    end
    
    return false
end

-- Handle specialization change
function Mistweaver:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentMana = 100
    currentChi = 0
    maxChi = 5
    currentEnergy = 100
    maxEnergy = 100
    hasTeachingsOfTheMistweaver = false
    renewingMistActive = false
    renewingMistCount = 0
    renewingMistEndTime = 0
    lifeCycleActive = false
    lifeCycleMana = false
    lifeCycleViv = false
    lifeCycleEndTime = 0
    manaTea = false
    manaTeaActive = false
    manaTeaEndTime = 0
    invokeChi = false
    invokeChiActive = false
    invokeChiEndTime = 0
    soothingMist = false
    soothingMistActive = false
    soothingMistEndTime = 0
    enveloping = false
    envelopingActive = false
    envelopingMistEndTime = 0
    envelopingBreathActive = false
    envelopingBreathEndTime = 0
    essenceFont = false
    essenceFontActive = false
    essenceFontEndTime = 0
    thunderFocusTea = false
    thunderFocusTeaActive = false
    thunderFocusTeaEndTime = 0
    thunderFocusTeaStacks = 0
    focusedThunderActive = false
    focusedThunderStacks = 0
    focusedThunderEndTime = 0
    revival = false
    zenPulse = false
    surgeOfMist = false
    surgeOfMistActive = false
    surgeOfMistEndTime = 0
    surgeOfMistStacks = 0
    refreshingJadeWind = false
    refreshingJadeWindActive = false
    refreshingJadeWindEndTime = 0
    faeline = false
    faelineActive = false
    faelineEndTime = 0
    ancientConcordance = false
    ancientConcordanceActive = false
    ancientConcordanceEndTime = 0
    ancientConcordanceStacks = 0
    shaohaosLesson = false
    shaohaoLessonActive = false
    shaohaoLessonEndTime = 0
    shaohaoLessonStacks = 0
    restoralMist = false
    restoralMistActive = false
    restoralMistEndTime = 0
    restoral = false
    restoralActive = false
    restoralEndTime = 0
    invokeYulon = false
    invokeYulonActive = false
    invokeYulonEndTime = 0
    invokeYulonJadeBond = false
    steamyMist = false
    risingSunKickActive = false
    risingSunKickEndTime = 0
    blackoutKickActive = false
    blackoutKickEndTime = 0
    spinningCraneKickActive = false
    spinningCraneKickEndTime = 0
    tigerPalm = false
    risingSunKick = false
    blackoutKick = false
    touchOfDeath = false
    spinningCraneKick = false
    unison = false
    unisonActive = false
    unisonEndTime = 0
    unisonStacks = 0
    vividClarityActive = false
    vividClarityEndTime = 0
    jadeBond = false
    jadeBondActive = false
    jadeBondEndTime = 0
    celestialBreath = false
    celestialBreathActive = false
    celestialBreathEndTime = 0
    yulon = false
    chiJi = false
    invokeChiJi = false
    invokeChiJiActive = false
    invokeChiJiEndTime = 0
    chiCocoon = false
    chiCocoonActive = false
    chiCocoonEndTime = 0
    dampenHarm = false
    dampenHarmActive = false
    dampenHarmEndTime = 0
    fortifyingBrew = false
    fortifyingBrewActive = false
    fortifyingBrewEndTime = 0
    diffuseMagic = false
    diffuseMagicActive = false
    diffuseMagicEndTime = 0
    paralysis = false
    legSweep = false
    flyingSerpentKick = false
    tigersLust = false
    detox = false
    transcendence = false
    transcendenceTransfer = false
    cloudedFocus = false
    cloudedFocusActive = false
    cloudedFocusEndTime = 0
    cloudedFocusStacks = 0
    vivaciousVivification = false
    teaOfPlenty = false
    awakeningUnison = false
    profoundRebuttal = false
    lastEnveloping = 0
    lastRenewing = 0
    lastVivify = 0
    lastEssenceFont = 0
    lastLifeCocoon = 0
    lastRevival = 0
    lastThunderFocusTea = 0
    lastManaTea = 0
    lastZenPulse = 0
    lastRefreshingJadeWind = 0
    lastInvokeYulon = 0
    lastInvokeChiJi = 0
    lastSurgeOfMist = 0
    lastRestoralMist = 0
    lastRestoral = 0
    lastFaeTransfusion = 0
    lastFaeline = 0
    lastTigerPalm = 0
    lastRisingSunKick = 0
    lastBlackoutKick = 0
    lastTouchOfDeath = 0
    lastSpinningCraneKick = 0
    lastInvokeChi = 0
    lastDetox = 0
    lastParalysis = 0
    lastLegSweep = 0
    lastFlyingSerpentKick = 0
    lastTigersLust = 0
    lastTranscendence = 0
    lastTranscendenceTransfer = 0
    playerHealth = 100
    activeEnemies = 0
    isInMelee = false
    
    API.PrintDebug("Mistweaver Monk state reset on spec change")
    
    return true
end

-- Return the module for loading
return Mistweaver