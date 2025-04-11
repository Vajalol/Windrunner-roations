------------------------------------------
-- WindrunnerRotations - Blood Death Knight Module
-- Author: VortexQ8
------------------------------------------

local Blood = {}
-- This will be assigned to addon.Classes.DeathKnight.Blood when loaded

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
local runePower = 0
local maxRunePower = 100
local bloodPlague = false
local bloodPlagueExpiration = 0
local marrowrendStack = 0
local boneshieldStack = 0
local runicPowerDump = 90
local deathStrikeHealing = 0
local runeTapped = {}
local deathAndDecayCooldown = 0
local dancingRuneWeaponActive = false
local vampiricBloodActive = false
local iceboundFortitudeActive = false
local antiMagicShellActive = false
local lichborneActive = false
local tombstoneBoneshieldStack = 0
local blooddrinkerChanneling = false
local gorefiendsActive = false
local crimsonScourgeBuff = false
local crimsonScourgeBone = false
local abominationLimbActive = false
local swarmsActive = false -- Swarming Mist
local raiseDead = false -- Ghoul summoned
local sacrificialPactReady = false -- Ghoul ready to be sacrificed
local deathsDueActive = false -- Death's Due ground effect
local deathsDueAmp = 0 -- Death's Due damage amp
local consumptionActive = false -- Consumption
local deathsCaressInfected = false -- Blood Plague from Death's Caress

-- Constants
local BLOOD_SPEC_ID = 250
local DEFAULT_AOE_THRESHOLD = 3
local BONESHIELD_MAX_STACK = 10
local CRIMSON_SCOURGE_REFRESH = 4
local HEMOSTASIS_MAX_STACK = 5
local RUNE_COUNT = 6
local BLOODDRINKER_CHANNEL_TIME = 3
local BLOODPLAGUE_REFRESH_TIME = 8
local MARROWREND_REFRESH_TIME = 6

-- Initialize the Blood module
function Blood:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Blood Death Knight module initialized")
    
    return true
end

-- Register spell IDs
function Blood:RegisterSpells()
    -- Core rotation abilities
    spells.HEART_STRIKE = 206930
    spells.MARROWREND = 195182
    spells.DEATH_STRIKE = 49998
    spells.BLOOD_BOIL = 50842
    spells.DEATH_AND_DECAY = 43265
    spells.CONSUMPTION = 274156
    spells.BLOODDRINKER = 206931
    spells.BLOOD_TAP = 221699
    spells.BONESTORM = 194844
    spells.TOMBSTONE = 219809
    spells.DEATHS_CARESS = 195292
    spells.RUNE_TAP = 194679
    spells.SACRIFICIAL_PACT = 327574
    
    -- Covenant abilities
    spells.SWARMING_MIST = 311648
    spells.ABOMINATION_LIMB = 315443
    spells.SHACKLE_THE_UNWORTHY = 312202
    spells.DEATHS_DUE = 324128
    
    -- Defensive cooldowns
    spells.DANCING_RUNE_WEAPON = 49028
    spells.VAMPIRIC_BLOOD = 55233
    spells.ICEBOUND_FORTITUDE = 48792
    spells.ANTI_MAGIC_SHELL = 48707
    spells.LICHBORNE = 49039
    spells.RAISE_DEAD = 46585
    
    -- Utility
    spells.DEATH_GRIP = 49576
    spells.GOREFIENDS_GRASP = 108199
    spells.WRAITH_WALK = 212552
    spells.DEATH_GATE = 50977
    spells.MIND_FREEZE = 47528
    spells.ASPHYXIATE = 221562
    spells.DEATHS_ADVANCE = 48265
    
    -- Talent and proc abilities
    spells.RELISH_IN_BLOOD = 317610
    spells.HEMOSTASIS = 273946
    spells.VORACIOUS = 273953
    spells.OSSUARY = 219786
    spells.RED_THIRST = 205723
    spells.RAPID_DECOMPOSITION = 194662
    spells.HEARTBREAKER = 221536
    spells.CRIMSON_SCOURGE = 81136
    spells.WILL_OF_THE_NECROPOLIS = 206967
    spells.MARK_OF_BLOOD = 206940
    spells.TIGHTENING_GRASP = 206970
    spells.GRIP_OF_THE_DEAD = 273952
    spells.FOUL_BULWARK = 206974
    
    -- Buff and debuff IDs
    spells.BLOOD_PLAGUE = 55078
    spells.BONE_SHIELD = 195181
    spells.DANCING_RUNE_WEAPON_BUFF = 81256
    spells.VAMPIRIC_BLOOD_BUFF = 55233
    spells.ICEBOUND_FORTITUDE_BUFF = 48792
    spells.ANTI_MAGIC_SHELL_BUFF = 48707
    spells.LICHBORNE_BUFF = 49039
    spells.CRIMSON_SCOURGE_BUFF = 81141
    spells.HEMOSTASIS_BUFF = 273947
    spells.OSSUARY_BUFF = 219788
    spells.VORACIOUS_BUFF = 274009
    spells.DEATHS_DUE_BUFF = 324165
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.BONE_SHIELD = spells.BONE_SHIELD
    buffs.DANCING_RUNE_WEAPON = spells.DANCING_RUNE_WEAPON_BUFF
    buffs.VAMPIRIC_BLOOD = spells.VAMPIRIC_BLOOD_BUFF
    buffs.ICEBOUND_FORTITUDE = spells.ICEBOUND_FORTITUDE_BUFF
    buffs.ANTI_MAGIC_SHELL = spells.ANTI_MAGIC_SHELL_BUFF
    buffs.LICHBORNE = spells.LICHBORNE_BUFF
    buffs.CRIMSON_SCOURGE = spells.CRIMSON_SCOURGE_BUFF
    buffs.HEMOSTASIS = spells.HEMOSTASIS_BUFF
    buffs.OSSUARY = spells.OSSUARY_BUFF
    buffs.VORACIOUS = spells.VORACIOUS_BUFF
    buffs.DEATHS_DUE = spells.DEATHS_DUE_BUFF
    
    debuffs.BLOOD_PLAGUE = spells.BLOOD_PLAGUE
    
    return true
end

-- Register variables to track
function Blood:RegisterVariables()
    -- Talent tracking
    talents.hasBlooddrinker = false
    talents.hasConvokeTheDamned = false -- Tier talent for adding extra strikes
    talents.hasBloodTap = false
    talents.hasBonestorm = false
    talents.hasTombstone = false
    talents.hasRedThirst = false 
    talents.hasRapidDecomposition = false
    talents.hasHeartbreaker = false
    talents.hasRelishInBlood = false
    talents.hasHemostasis = false
    talents.hasVoracious = false
    talents.hasWillOfTheNecropolis = false
    talents.hasMarkOfBlood = false
    talents.hasTighteningGrasp = false
    talents.hasGripOfTheDead = false
    talents.hasFoulBulwark = false
    talents.hasRunicAttenuation = false
    talents.hasConsumption = false
    talents.hasAsphyxiate = false
    
    -- Initialize rune tracker
    for i = 1, RUNE_COUNT do
        runeTapped[i] = false
    end
    
    return true
end

-- Register spec-specific settings
function Blood:RegisterSettings()
    ConfigRegistry:RegisterSettings("BloodDeathKnight", {
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
            bloodPlagueStrategy = {
                displayName = "Blood Plague Strategy",
                description = "How to maintain Blood Plague",
                type = "dropdown",
                options = {"On Single Target", "On All Targets", "Only via Blood Boil"},
                default = "On All Targets"
            },
            boneShieldStrategy = {
                displayName = "Bone Shield Strategy",
                description = "How to maintain Bone Shield",
                type = "dropdown",
                options = {"Keep at Max", "Refresh when Low", "Balance with Heartstrikes"},
                default = "Refresh when Low"
            },
            boneShieldThreshold = {
                displayName = "Bone Shield Refresh Threshold",
                description = "Bone Shield stacks to trigger Marrowrend",
                type = "slider",
                min = 1,
                max = 7,
                default = 5
            },
            deathStrikeMode = {
                displayName = "Death Strike Mode",
                description = "How to use Death Strike",
                type = "dropdown",
                options = {"Reactive", "Offensive", "Resource Dump"},
                default = "Reactive"
            },
            deathStrikeThreshold = {
                displayName = "Death Strike Health Threshold",
                description = "Health percentage to use Death Strike",
                type = "slider",
                min = 30,
                max = 90,
                default = 65
            }
        },
        
        defensiveSettings = {
            useVampiricBlood = {
                displayName = "Use Vampiric Blood",
                description = "Automatically use Vampiric Blood",
                type = "toggle",
                default = true
            },
            vampiricBloodThreshold = {
                displayName = "Vampiric Blood Threshold",
                description = "Health percentage to use Vampiric Blood",
                type = "slider",
                min = 20,
                max = 80,
                default = 40
            },
            useIceboundFortitude = {
                displayName = "Use Icebound Fortitude",
                description = "Automatically use Icebound Fortitude",
                type = "toggle",
                default = true
            },
            iceboundFortitudeThreshold = {
                displayName = "Icebound Fortitude Threshold",
                description = "Health percentage to use Icebound Fortitude",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useAntiMagicShell = {
                displayName = "Use Anti-Magic Shell",
                description = "Automatically use Anti-Magic Shell",
                type = "toggle",
                default = true
            },
            antiMagicShellThreshold = {
                displayName = "Anti-Magic Shell Threshold",
                description = "Health percentage to use Anti-Magic Shell",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useLichborne = {
                displayName = "Use Lichborne",
                description = "Automatically use Lichborne",
                type = "toggle",
                default = true
            },
            lichborneThreshold = {
                displayName = "Lichborne Threshold",
                description = "Health percentage to use Lichborne",
                type = "slider",
                min = 10,
                max = 50,
                default = 25
            },
            useRuneTap = {
                displayName = "Use Rune Tap",
                description = "Automatically use Rune Tap",
                type = "toggle",
                default = true
            },
            runeTapThreshold = {
                displayName = "Rune Tap Threshold",
                description = "Health percentage to use Rune Tap",
                type = "slider",
                min = 30,
                max = 90,
                default = 70
            }
        },
        
        offensiveSettings = {
            useDancingRuneWeapon = {
                displayName = "Use Dancing Rune Weapon",
                description = "Automatically use Dancing Rune Weapon",
                type = "toggle",
                default = true
            },
            useBlooddrinker = {
                displayName = "Use Blooddrinker",
                description = "Automatically use Blooddrinker when talented",
                type = "toggle",
                default = true
            },
            useBonestorm = {
                displayName = "Use Bonestorm",
                description = "Automatically use Bonestorm when talented",
                type = "toggle",
                default = true
            },
            bonestormRPThreshold = {
                displayName = "Bonestorm Runic Power",
                description = "Minimum Runic Power to use Bonestorm",
                type = "slider",
                min = 60,
                max = 100,
                default = 80
            },
            useTombstone = {
                displayName = "Use Tombstone",
                description = "Automatically use Tombstone when talented",
                type = "toggle",
                default = true
            },
            tombstoneBSThreshold = {
                displayName = "Tombstone Bone Shield",
                description = "Minimum Bone Shield stacks for Tombstone",
                type = "slider",
                min = 5,
                max = 10,
                default = 7
            },
            useSacrificialPact = {
                displayName = "Use Sacrificial Pact",
                description = "Automatically use Sacrificial Pact",
                type = "toggle",
                default = true
            },
            sacrificialPactThreshold = {
                displayName = "Sacrificial Pact Threshold",
                description = "Health percentage to use Sacrificial Pact",
                type = "slider",
                min = 10,
                max = 50,
                default = 40
            }
        },
        
        covenantSettings = {
            useSwarmingMist = {
                displayName = "Use Swarming Mist",
                description = "Automatically use Swarming Mist (Venthyr)",
                type = "toggle",
                default = true
            },
            useAbominationLimb = {
                displayName = "Use Abomination Limb",
                description = "Automatically use Abomination Limb (Necrolord)",
                type = "toggle",
                default = true
            },
            useShackleTheUnworthy = {
                displayName = "Use Shackle the Unworthy",
                description = "Automatically use Shackle the Unworthy (Kyrian)",
                type = "toggle",
                default = true
            },
            useDeathsDue = {
                displayName = "Use Death's Due",
                description = "Automatically use Death's Due (Night Fae)",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            runicPowerPooling = {
                displayName = "Runic Power Pooling",
                description = "Runic Power to pool before using Death Strike",
                type = "slider",
                min = 35,
                max = 80,
                default = 45
            },
            useBloodTap = {
                displayName = "Use Blood Tap",
                description = "When to use Blood Tap",
                type = "dropdown",
                options = {"On Cooldown", "For Marrowrend", "Resource Starved"},
                default = "Resource Starved"
            },
            useConsumption = {
                displayName = "Use Consumption",
                description = "When to use Consumption",
                type = "dropdown",
                options = {"Defensively", "Offensively", "On Cooldown"},
                default = "Offensively"
            },
            crimsonScourgeUsage = {
                displayName = "Crimson Scourge Usage",
                description = "How to use Crimson Scourge procs",
                type = "dropdown",
                options = {"Standard DnD", "Death's Due Only", "Only with 3+ targets"},
                default = "Standard DnD"
            },
            useHemostasis = {
                displayName = "Use Hemostasis",
                description = "How to utilize Hemostasis buff",
                type = "dropdown",
                options = {"Max Stacks", "Any Stacks", "Only When Needed"},
                default = "Max Stacks"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Dancing Rune Weapon controls
            dancingRuneWeapon = AAC.RegisterAbility(spells.DANCING_RUNE_WEAPON, {
                enabled = true,
                useDuringBurstOnly = true,
                minEnemies = 1
            }),
            
            -- Death and Decay controls
            deathAndDecay = AAC.RegisterAbility(spells.DEATH_AND_DECAY, {
                enabled = true,
                useWithCrimsonScourge = true,
                minEnemies = 1
            }),
            
            -- Bonestorm controls
            bonestorm = AAC.RegisterAbility(spells.BONESTORM, {
                enabled = true,
                minEnemies = 3,
                minRunicPower = 60
            })
        }
    })
    
    return true
end

-- Register for events 
function Blood:RegisterEvents()
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
        self:UpdateRuneStatus(runeIndex, isEnergize)
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initialize state
    self:UpdateRunicPower()
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    return true
end

-- Update talent information
function Blood:UpdateTalentInfo()
    -- Check for important talents
    talents.hasBlooddrinker = API.HasTalent(spells.BLOODDRINKER)
    talents.hasBloodTap = API.HasTalent(spells.BLOOD_TAP)
    talents.hasBonestorm = API.HasTalent(spells.BONESTORM)
    talents.hasTombstone = API.HasTalent(spells.TOMBSTONE)
    talents.hasRedThirst = API.HasTalent(spells.RED_THIRST) 
    talents.hasRapidDecomposition = API.HasTalent(spells.RAPID_DECOMPOSITION)
    talents.hasHeartbreaker = API.HasTalent(spells.HEARTBREAKER)
    talents.hasRelishInBlood = API.HasTalent(spells.RELISH_IN_BLOOD)
    talents.hasHemostasis = API.HasTalent(spells.HEMOSTASIS)
    talents.hasVoracious = API.HasTalent(spells.VORACIOUS)
    talents.hasWillOfTheNecropolis = API.HasTalent(spells.WILL_OF_THE_NECROPOLIS)
    talents.hasMarkOfBlood = API.HasTalent(spells.MARK_OF_BLOOD)
    talents.hasTighteningGrasp = API.HasTalent(spells.TIGHTENING_GRASP)
    talents.hasGripOfTheDead = API.HasTalent(spells.GRIP_OF_THE_DEAD)
    talents.hasFoulBulwark = API.HasTalent(spells.FOUL_BULWARK)
    talents.hasConsumption = API.HasTalent(spells.CONSUMPTION)
    talents.hasAsphyxiate = API.HasTalent(spells.ASPHYXIATE)
    
    API.PrintDebug("Blood Death Knight talents updated")
    
    return true
end

-- Update Runic Power tracking
function Blood:UpdateRunicPower()
    runePower = API.GetPlayerPower()
    return true
end

-- Update Rune status tracking
function Blood:UpdateRuneStatus(runeIndex, isEnergize)
    if runeIndex >= 1 and runeIndex <= RUNE_COUNT then
        runeTapped[runeIndex] = not isEnergize
    end
    return true
end

-- Count available runes
function Blood:GetAvailableRunes()
    local count = 0
    for i = 1, RUNE_COUNT do
        if not runeTapped[i] then
            count = count + 1
        end
    end
    return count
end

-- Update target data
function Blood:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Check for Blood Plague
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, spells.BLOOD_PLAGUE)
        if name then
            bloodPlague = true
            bloodPlagueExpiration = expiration
        else
            bloodPlague = false
            bloodPlagueExpiration = 0
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Blood AoE radius
    
    return true
end

-- Handle combat log events
function Blood:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Bone Shield
            if spellID == buffs.BONE_SHIELD then
                -- Initial application gives 6 stacks
                if not boneshieldStack or boneshieldStack == 0 then
                    boneshieldStack = 6
                end
                API.PrintDebug("Bone Shield active with " .. tostring(boneshieldStack) .. " stacks")
            end
            
            -- Track Dancing Rune Weapon
            if spellID == buffs.DANCING_RUNE_WEAPON then
                dancingRuneWeaponActive = true
                API.PrintDebug("Dancing Rune Weapon activated")
            end
            
            -- Track Vampiric Blood
            if spellID == buffs.VAMPIRIC_BLOOD then
                vampiricBloodActive = true
                API.PrintDebug("Vampiric Blood activated")
            end
            
            -- Track Icebound Fortitude
            if spellID == buffs.ICEBOUND_FORTITUDE then
                iceboundFortitudeActive = true
                API.PrintDebug("Icebound Fortitude activated")
            end
            
            -- Track Anti-Magic Shell
            if spellID == buffs.ANTI_MAGIC_SHELL then
                antiMagicShellActive = true
                API.PrintDebug("Anti-Magic Shell activated")
            end
            
            -- Track Lichborne
            if spellID == buffs.LICHBORNE then
                lichborneActive = true
                API.PrintDebug("Lichborne activated")
            end
            
            -- Track Crimson Scourge
            if spellID == buffs.CRIMSON_SCOURGE then
                crimsonScourgeBuff = true
                API.PrintDebug("Crimson Scourge proc")
            end
            
            -- Track Hemostasis
            if spellID == buffs.HEMOSTASIS then
                local stacks = select(4, API.GetBuffInfo("player", buffs.HEMOSTASIS)) or 0
                API.PrintDebug("Hemostasis stacks: " .. tostring(stacks))
            end
            
            -- Track Ossuary
            if spellID == buffs.OSSUARY then
                API.PrintDebug("Ossuary active")
            end
            
            -- Track Voracious
            if spellID == buffs.VORACIOUS then
                API.PrintDebug("Voracious healing increase")
            end
            
            -- Track Death's Due
            if spellID == buffs.DEATHS_DUE then
                deathsDueAmp = select(4, API.GetBuffInfo("player", buffs.DEATHS_DUE)) or 0
                API.PrintDebug("Death's Due damage amp: " .. tostring(deathsDueAmp) .. "%")
            end
        end
        
        -- Track debuffs on targets
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Track Blood Plague
            if spellID == debuffs.BLOOD_PLAGUE then
                bloodPlague = true
                bloodPlagueExpiration = select(6, API.GetDebuffInfo(targetGUID, debuffs.BLOOD_PLAGUE))
                API.PrintDebug("Blood Plague applied to target")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Dancing Rune Weapon
            if spellID == buffs.DANCING_RUNE_WEAPON then
                dancingRuneWeaponActive = false
                API.PrintDebug("Dancing Rune Weapon faded")
            end
            
            -- Track Vampiric Blood
            if spellID == buffs.VAMPIRIC_BLOOD then
                vampiricBloodActive = false
                API.PrintDebug("Vampiric Blood faded")
            end
            
            -- Track Icebound Fortitude
            if spellID == buffs.ICEBOUND_FORTITUDE then
                iceboundFortitudeActive = false
                API.PrintDebug("Icebound Fortitude faded")
            end
            
            -- Track Anti-Magic Shell
            if spellID == buffs.ANTI_MAGIC_SHELL then
                antiMagicShellActive = false
                API.PrintDebug("Anti-Magic Shell faded")
            end
            
            -- Track Lichborne
            if spellID == buffs.LICHBORNE then
                lichborneActive = false
                API.PrintDebug("Lichborne faded")
            end
            
            -- Track Crimson Scourge
            if spellID == buffs.CRIMSON_SCOURGE then
                crimsonScourgeBuff = false
                API.PrintDebug("Crimson Scourge consumed")
            end
            
            -- Track Death's Due
            if spellID == buffs.DEATHS_DUE then
                deathsDueAmp = 0
                API.PrintDebug("Death's Due amp faded")
            end
        end
        
        -- Track debuffs on targets
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Track Blood Plague
            if spellID == debuffs.BLOOD_PLAGUE then
                bloodPlague = false
                bloodPlagueExpiration = 0
                API.PrintDebug("Blood Plague faded from target")
            end
        end
    end
    
    -- Track Bone Shield stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
        boneshieldStack = select(4, API.GetBuffInfo("player", buffs.BONE_SHIELD)) or 0
        API.PrintDebug("Bone Shield stacks: " .. tostring(boneshieldStack))
    end
    
    -- Track Bone Shield stack consumption or fade
    if eventType == "SPELL_AURA_REMOVED_DOSE" and spellID == buffs.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
        boneshieldStack = select(4, API.GetBuffInfo("player", buffs.BONE_SHIELD)) or 0
        API.PrintDebug("Bone Shield stack consumed, " .. tostring(boneshieldStack) .. " remaining")
    end
    
    -- Track Bone Shield removal
    if eventType == "SPELL_AURA_REMOVED" and spellID == buffs.BONE_SHIELD and destGUID == API.GetPlayerGUID() then
        boneshieldStack = 0
        API.PrintDebug("Bone Shield faded completely")
    end
    
    -- Track important spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.DEATH_AND_DECAY or spellID == spells.DEATHS_DUE then
            deathAndDecayCooldown = 30 -- Standard cooldown
            
            if spellID == spells.DEATHS_DUE then
                deathsDueActive = true
                -- Start timer to track Death's Due ground effect duration
                C_Timer.After(10, function() -- 10 second duration
                    deathsDueActive = false
                end)
            end
            
            -- Crimson Scourge resets cooldown
            if crimsonScourgeBuff then
                deathAndDecayCooldown = 0
                crimsonScourgeBuff = false
            end
            
            API.PrintDebug("Death and Decay/Death's Due cast")
        elseif spellID == spells.MARROWREND then
            -- Marrowrend gives or refreshes Bone Shield
            if boneshieldStack == 0 then
                boneshieldStack = 6
            else
                boneshieldStack = math.min(BONESHIELD_MAX_STACK, boneshieldStack + 2)
            end
            
            API.PrintDebug("Marrowrend cast, Bone Shield now: " .. tostring(boneshieldStack))
        elseif spellID == spells.BLOOD_TAP then
            -- Blood Tap refreshes runes
            local availableRunes = self:GetAvailableRunes()
            API.PrintDebug("Blood Tap cast, available runes: " .. tostring(availableRunes + 1))
        elseif spellID == spells.BLOODDRINKER then
            blooddrinkerChanneling = true
            
            -- Set timer to track when channeling ends
            C_Timer.After(BLOODDRINKER_CHANNEL_TIME, function()
                blooddrinkerChanneling = false
            end)
            
            API.PrintDebug("Blooddrinker channeling")
        elseif spellID == spells.GOREFIENDS_GRASP then
            gorefiendsActive = true
            
            -- Set timer to track internal cooldown
            C_Timer.After(15, function() -- Approximate effect duration
                gorefiendsActive = false
            end)
            
            API.PrintDebug("Gorefiend's Grasp used")
        elseif spellID == spells.CONSUMPTION then
            consumptionActive = true
            
            -- Effect is immediate but track for rotation purposes
            C_Timer.After(1, function()
                consumptionActive = false
            end)
            
            API.PrintDebug("Consumption used")
        elseif spellID == spells.TOMBSTONE then
            -- Tombstone consumes Bone Shield stacks
            tombstoneBoneshieldStack = boneshieldStack
            boneshieldStack = 0
            
            API.PrintDebug("Tombstone consumed " .. tostring(tombstoneBoneshieldStack) .. " Bone Shield stacks")
        elseif spellID == spells.ABOMINATION_LIMB then
            abominationLimbActive = true
            
            -- Set timer to track duration
            C_Timer.After(12, function() -- 12 second duration
                abominationLimbActive = false
            end)
            
            API.PrintDebug("Abomination Limb active")
        elseif spellID == spells.SWARMING_MIST then
            swarmsActive = true
            
            -- Set timer to track duration
            C_Timer.After(8, function() -- 8 second duration
                swarmsActive = false
            end)
            
            API.PrintDebug("Swarming Mist active")
        elseif spellID == spells.RAISE_DEAD then
            raiseDead = true
            sacrificialPactReady = true
            
            API.PrintDebug("Ghoul summoned")
        elseif spellID == spells.SACRIFICIAL_PACT then
            raiseDead = false
            sacrificialPactReady = false
            
            API.PrintDebug("Ghoul sacrificed")
        end
    end
    
    -- Track important healing events
    if eventType == "SPELL_HEAL" and destGUID == API.GetPlayerGUID() and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.DEATH_STRIKE then
            deathStrikeHealing = select(4, ...)
            API.PrintDebug("Death Strike healed for " .. tostring(deathStrikeHealing))
        end
    end
    
    -- Track channel ends (might be interrupted)
    if eventType == "SPELL_CHANNEL_STOP" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.BLOODDRINKER then
            blooddrinkerChanneling = false
            API.PrintDebug("Blooddrinker channel ended")
        end
    end
    
    return true
end

-- Main rotation function
function Blood:RunRotation()
    -- Check if we should be running Blood Death Knight logic
    if API.GetActiveSpecID() ~= BLOOD_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Skip if Blooddrinker is channeling
    if blooddrinkerChanneling then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BloodDeathKnight")
    
    -- Update variables
    self:UpdateRunicPower()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
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
    
    -- Handle emergency defensives first
    if self:HandleEmergencyDefensives(settings) then
        return true
    end
    
    -- Handle Bone Shield maintenance
    if self:HandleBoneShield(settings) then
        return true
    end
    
    -- Handle cooldowns
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle health management
    if self:HandleHealthManagement(settings) then
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
function Blood:HandleInterrupts()
    -- Mind Freeze for interrupts
    if API.CanCast(spells.MIND_FREEZE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.MIND_FREEZE)
        return true
    end
    
    -- Asphyxiate as backup interrupt if talented
    if talents.hasAsphyxiate and 
       API.CanCast(spells.ASPHYXIATE) and 
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.ASPHYXIATE)
        return true
    end
    
    return false
end

-- Handle emergency defensive cooldowns
function Blood:HandleEmergencyDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Vampiric Blood for emergency
    if settings.defensiveSettings.useVampiricBlood and
       playerHealth <= settings.defensiveSettings.vampiricBloodThreshold and
       not vampiricBloodActive and
       API.CanCast(spells.VAMPIRIC_BLOOD) then
        API.CastSpell(spells.VAMPIRIC_BLOOD)
        return true
    end
    
    -- Use Icebound Fortitude for emergency
    if settings.defensiveSettings.useIceboundFortitude and
       playerHealth <= settings.defensiveSettings.iceboundFortitudeThreshold and
       not iceboundFortitudeActive and
       API.CanCast(spells.ICEBOUND_FORTITUDE) then
        API.CastSpell(spells.ICEBOUND_FORTITUDE)
        return true
    end
    
    -- Use Death Strike for emergency healing
    if playerHealth <= settings.rotationSettings.deathStrikeThreshold / 2 and
       runePower >= 45 and API.CanCast(spells.DEATH_STRIKE) then
        API.CastSpell(spells.DEATH_STRIKE)
        return true
    end
    
    -- Use Rune Tap for additional mitigation
    if settings.defensiveSettings.useRuneTap and
       playerHealth <= settings.defensiveSettings.runeTapThreshold and
       API.CanCast(spells.RUNE_TAP) then
        API.CastSpell(spells.RUNE_TAP)
        return true
    end
    
    -- Use Sacrificial Pact for emergency if ghoul is available
    if settings.offensiveSettings.useSacrificialPact and
       playerHealth <= settings.offensiveSettings.sacrificialPactThreshold and
       sacrificialPactReady and
       API.CanCast(spells.SACRIFICIAL_PACT) then
        API.CastSpell(spells.SACRIFICIAL_PACT)
        return true
    end
    
    return false
end

-- Handle Bone Shield maintenance
function Blood:HandleBoneShield(settings)
    -- Always prioritize maintaining Bone Shield
    local bsThreshold = settings.rotationSettings.boneShieldThreshold
    
    -- If we have no Bone Shield or it's below threshold and we have runes
    if boneshieldStack < bsThreshold and self:GetAvailableRunes() >= 2 and API.CanCast(spells.MARROWREND) then
        -- Check strategy
        if settings.rotationSettings.boneShieldStrategy == "Keep at Max" and boneshieldStack < BONESHIELD_MAX_STACK then
            API.CastSpell(spells.MARROWREND)
            return true
        elseif settings.rotationSettings.boneShieldStrategy == "Refresh when Low" and boneshieldStack < bsThreshold then
            API.CastSpell(spells.MARROWREND)
            return true
        elseif settings.rotationSettings.boneShieldStrategy == "Balance with Heartstrikes" and boneshieldStack < 4 then
            API.CastSpell(spells.MARROWREND)
            return true
        end
    end
    
    -- If we have no stacks at all, this is top priority
    if boneshieldStack == 0 and self:GetAvailableRunes() >= 2 and API.CanCast(spells.MARROWREND) then
        API.CastSpell(spells.MARROWREND)
        return true
    end
    
    return false
end

-- Handle health management
function Blood:HandleHealthManagement(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Anti-Magic Shell against magic damage
    if settings.defensiveSettings.useAntiMagicShell and
       playerHealth <= settings.defensiveSettings.antiMagicShellThreshold and
       not antiMagicShellActive and
       API.CanCast(spells.ANTI_MAGIC_SHELL) then
        API.CastSpell(spells.ANTI_MAGIC_SHELL)
        return true
    end
    
    -- Use Lichborne for additional survivability
    if settings.defensiveSettings.useLichborne and
       playerHealth <= settings.defensiveSettings.lichborneThreshold and
       not lichborneActive and
       API.CanCast(spells.LICHBORNE) then
        API.CastSpell(spells.LICHBORNE)
        return true
    end
    
    -- Use Death Strike based on settings
    if API.CanCast(spells.DEATH_STRIKE) then
        if settings.rotationSettings.deathStrikeMode == "Reactive" and
           playerHealth <= settings.rotationSettings.deathStrikeThreshold and
           runePower >= 45 then
            API.CastSpell(spells.DEATH_STRIKE)
            return true
        elseif settings.rotationSettings.deathStrikeMode == "Resource Dump" and
               runePower >= settings.advancedSettings.runicPowerPooling then
            API.CastSpell(spells.DEATH_STRIKE)
            return true
        end
    end
    
    -- Use Tombstone for a shield
    if talents.hasTombstone and
       settings.offensiveSettings.useTombstone and
       boneshieldStack >= settings.offensiveSettings.tombstoneBSThreshold and
       playerHealth <= settings.defensiveSettings.vampiricBloodThreshold and
       API.CanCast(spells.TOMBSTONE) then
        API.CastSpell(spells.TOMBSTONE)
        return true
    end
    
    -- Use Consumption for healing and damage
    if talents.hasConsumption and API.CanCast(spells.CONSUMPTION) then
        if settings.advancedSettings.useConsumption == "Defensively" and
           playerHealth <= settings.rotationSettings.deathStrikeThreshold then
            API.CastSpell(spells.CONSUMPTION)
            return true
        elseif settings.advancedSettings.useConsumption == "On Cooldown" then
            API.CastSpell(spells.CONSUMPTION)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Blood:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Dancing Rune Weapon
    if settings.offensiveSettings.useDancingRuneWeapon and
       settings.abilityControls.dancingRuneWeapon.enabled and
       currentAoETargets >= settings.abilityControls.dancingRuneWeapon.minEnemies and
       (not settings.abilityControls.dancingRuneWeapon.useDuringBurstOnly or burstModeActive) and
       API.CanCast(spells.DANCING_RUNE_WEAPON) then
        API.CastSpell(spells.DANCING_RUNE_WEAPON)
        return true
    end
    
    -- Use Bonestorm for AoE
    if talents.hasBonestorm and
       settings.offensiveSettings.useBonestorm and
       settings.abilityControls.bonestorm.enabled and
       currentAoETargets >= settings.abilityControls.bonestorm.minEnemies and
       runePower >= settings.abilityControls.bonestorm.minRunicPower and
       API.CanCast(spells.BONESTORM) then
        API.CastSpell(spells.BONESTORM)
        return true
    end
    
    -- Use Blood Tap
    if talents.hasBloodTap and API.CanCast(spells.BLOOD_TAP) then
        if settings.advancedSettings.useBloodTap == "On Cooldown" then
            API.CastSpell(spells.BLOOD_TAP)
            return true
        elseif settings.advancedSettings.useBloodTap == "For Marrowrend" and boneshieldStack < 5 then
            API.CastSpell(spells.BLOOD_TAP)
            return true
        elseif settings.advancedSettings.useBloodTap == "Resource Starved" and self:GetAvailableRunes() < 2 then
            API.CastSpell(spells.BLOOD_TAP)
            return true
        end
    end
    
    -- Use covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle Covenant abilities
function Blood:HandleCovenantAbilities(settings)
    -- Use Swarming Mist (Venthyr)
    if settings.covenantSettings.useSwarmingMist and
       API.CanCast(spells.SWARMING_MIST) then
        API.CastSpell(spells.SWARMING_MIST)
        return true
    end
    
    -- Use Abomination Limb (Necrolord)
    if settings.covenantSettings.useAbominationLimb and
       API.CanCast(spells.ABOMINATION_LIMB) then
        API.CastSpell(spells.ABOMINATION_LIMB)
        return true
    end
    
    -- Use Shackle the Unworthy (Kyrian)
    if settings.covenantSettings.useShackleTheUnworthy and
       API.CanCast(spells.SHACKLE_THE_UNWORTHY) then
        API.CastSpell(spells.SHACKLE_THE_UNWORTHY)
        return true
    end
    
    -- Use Death's Due (Night Fae) - replace Death and Decay
    if settings.covenantSettings.useDeathsDue and
       API.CanCast(spells.DEATHS_DUE) then
        
        -- Prioritize with Crimson Scourge proc
        if crimsonScourgeBuff then
            if settings.advancedSettings.crimsonScourgeUsage == "Death's Due Only" or
               settings.advancedSettings.crimsonScourgeUsage == "Standard DnD" then
                API.CastSpellAtCursor(spells.DEATHS_DUE)
                return true
            elseif settings.advancedSettings.crimsonScourgeUsage == "Only with 3+ targets" and
                   currentAoETargets >= 3 then
                API.CastSpellAtCursor(spells.DEATHS_DUE)
                return true
            end
        else
            API.CastSpellAtCursor(spells.DEATHS_DUE)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Blood:HandleAoERotation(settings)
    -- Apply Blood Plague through Death's Caress if needed and not present
    if settings.rotationSettings.bloodPlagueStrategy ~= "Only via Blood Boil" and
       not bloodPlague and API.CanCast(spells.DEATHS_CARESS) then
        API.CastSpell(spells.DEATHS_CARESS)
        return true
    end
    
    -- Apply Blood Plague to all targets through Blood Boil
    if API.CanCast(spells.BLOOD_BOIL) then
        API.CastSpell(spells.BLOOD_BOIL)
        return true
    end
    
    -- Use Death and Decay or Death's Due (whichever is available) for AoE
    if deathAndDecayCooldown <= 0 and 
       settings.abilityControls.deathAndDecay.enabled and
       currentAoETargets >= settings.abilityControls.deathAndDecay.minEnemies then
        
        if API.CanCast(spells.DEATHS_DUE) then
            API.CastSpellAtCursor(spells.DEATHS_DUE)
            return true
        elseif API.CanCast(spells.DEATH_AND_DECAY) then
            API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
            return true
        end
    end
    
    -- Use free Death and Decay from Crimson Scourge
    if crimsonScourgeBuff and 
       settings.abilityControls.deathAndDecay.useWithCrimsonScourge then
        
        if settings.advancedSettings.crimsonScourgeUsage ~= "Only with 3+ targets" or
           currentAoETargets >= 3 then
            if API.CanCast(spells.DEATHS_DUE) then
                API.CastSpellAtCursor(spells.DEATHS_DUE)
                return true
            elseif API.CanCast(spells.DEATH_AND_DECAY) then
                API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
                return true
            end
        end
    end
    
    -- Use Consumption for AoE damage
    if talents.hasConsumption and 
       API.CanCast(spells.CONSUMPTION) and
       settings.advancedSettings.useConsumption == "Offensively" then
        API.CastSpell(spells.CONSUMPTION)
        return true
    end
    
    -- Use Death Strike if needed for healing or dumping resources
    if API.CanCast(spells.DEATH_STRIKE) then
        if settings.rotationSettings.deathStrikeMode == "Offensive" or
           (settings.rotationSettings.deathStrikeMode == "Resource Dump" and 
            runePower >= settings.advancedSettings.runicPowerPooling) then
            API.CastSpell(spells.DEATH_STRIKE)
            return true
        end
    end
    
    -- Heart Strike inside DnD for extra targets if available
    if (deathsDueActive or API.PlayerIsInDND()) and API.CanCast(spells.HEART_STRIKE) and self:GetAvailableRunes() > 0 then
        API.CastSpell(spells.HEART_STRIKE)
        return true
    end
    
    -- Heart Strike as main filler
    if API.CanCast(spells.HEART_STRIKE) and self:GetAvailableRunes() > 0 then
        API.CastSpell(spells.HEART_STRIKE)
        return true
    end
    
    -- Use Blooddrinker as filler
    if talents.hasBlooddrinker and
       settings.offensiveSettings.useBlooddrinker and
       API.CanCast(spells.BLOODDRINKER) then
        API.CastSpell(spells.BLOODDRINKER)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Blood:HandleSingleTargetRotation(settings)
    -- Apply Blood Plague if not present
    if not bloodPlague then
        if API.CanCast(spells.DEATHS_CARESS) then
            API.CastSpell(spells.DEATHS_CARESS)
            return true
        elseif API.CanCast(spells.BLOOD_BOIL) then
            API.CastSpell(spells.BLOOD_BOIL)
            return true
        end
    end
    
    -- Refresh Blood Plague if needed
    if bloodPlague and bloodPlagueExpiration - GetTime() < BLOODPLAGUE_REFRESH_TIME then
        if API.CanCast(spells.BLOOD_BOIL) then
            API.CastSpell(spells.BLOOD_BOIL)
            return true
        end
    end
    
    -- Use Blooddrinker as priority if talented
    if talents.hasBlooddrinker and
       settings.offensiveSettings.useBlooddrinker and
       API.CanCast(spells.BLOODDRINKER) then
        API.CastSpell(spells.BLOODDRINKER)
        return true
    end
    
    -- Use Death and Decay / Death's Due for the buff or with Crimson Scourge
    if (deathAndDecayCooldown <= 0 or crimsonScourgeBuff) and 
       settings.abilityControls.deathAndDecay.enabled then
        
        if API.CanCast(spells.DEATHS_DUE) then
            API.CastSpellAtCursor(spells.DEATHS_DUE)
            return true
        elseif API.CanCast(spells.DEATH_AND_DECAY) then
            API.CastSpellAtCursor(spells.DEATH_AND_DECAY)
            return true
        end
    end
    
    -- Use Death Strike based on settings and resource availability
    if API.CanCast(spells.DEATH_STRIKE) then
        -- Use with Hemostasis stacks
        if talents.hasHemostasis then
            local hemostasisStacks = select(4, API.GetBuffInfo("player", buffs.HEMOSTASIS)) or 0
            
            if settings.advancedSettings.useHemostasis == "Max Stacks" and hemostasisStacks >= HEMOSTASIS_MAX_STACK then
                API.CastSpell(spells.DEATH_STRIKE)
                return true
            elseif settings.advancedSettings.useHemostasis == "Any Stacks" and hemostasisStacks > 0 then
                API.CastSpell(spells.DEATH_STRIKE)
                return true
            end
        end
        
        -- Otherwise check normal conditions
        if settings.rotationSettings.deathStrikeMode == "Offensive" or
           (settings.rotationSettings.deathStrikeMode == "Resource Dump" and 
            runePower >= settings.advancedSettings.runicPowerPooling) then
            API.CastSpell(spells.DEATH_STRIKE)
            return true
        end
    end
    
    -- Use Blood Boil to generate Crimson Scourge
    if API.CanCast(spells.BLOOD_BOIL) then
        API.CastSpell(spells.BLOOD_BOIL)
        return true
    end
    
    -- Heart Strike inside DnD for extra benefit
    if (deathsDueActive or API.PlayerIsInDND()) and API.CanCast(spells.HEART_STRIKE) and self:GetAvailableRunes() > 0 then
        API.CastSpell(spells.HEART_STRIKE)
        return true
    end
    
    -- Heart Strike as main filler
    if API.CanCast(spells.HEART_STRIKE) and self:GetAvailableRunes() > 0 then
        API.CastSpell(spells.HEART_STRIKE)
        return true
    end
    
    return false
end

-- Handle specialization change
function Blood:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    runePower = API.GetPlayerPower()
    maxRunePower = 100
    bloodPlague = false
    bloodPlagueExpiration = 0
    marrowrendStack = 0
    boneshieldStack = 0
    runicPowerDump = 90
    deathStrikeHealing = 0
    runeTapped = {}
    deathAndDecayCooldown = 0
    dancingRuneWeaponActive = false
    vampiricBloodActive = false
    iceboundFortitudeActive = false
    antiMagicShellActive = false
    lichborneActive = false
    tombstoneBoneshieldStack = 0
    blooddrinkerChanneling = false
    gorefiendsActive = false
    crimsonScourgeBuff = false
    crimsonScourgeBone = false
    abominationLimbActive = false
    swarmsActive = false
    raiseDead = false
    sacrificialPactReady = false
    deathsDueActive = false
    deathsDueAmp = 0
    consumptionActive = false
    deathsCaressInfected = false
    
    -- Initialize rune tracker
    for i = 1, RUNE_COUNT do
        runeTapped[i] = false
    end
    
    API.PrintDebug("Blood Death Knight state reset on spec change")
    
    return true
end

-- Return the module for loading
return Blood