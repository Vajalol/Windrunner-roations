------------------------------------------
-- WindrunnerRotations - Demonology Warlock Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Demonology = {}
addon.Classes.Warlock.Demonology = Demonology

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local Warlock = addon.Classes.Warlock

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentSoulShards = 0
local maxSoulShards = 5
local demonsActive = 0
local tyrantActive = false
local dreadstalkersActive = false
local felguardActive = true
local vilefiendActive = false
local handOfGuldanCharges = 0

-- Constants
local DEMONOLOGY_SPEC_ID = 266
local SOUL_SHARD_THRESHOLD = 4
local DEFAULT_AOE_THRESHOLD = 3
local MAX_DEMONS_TRACKED = 10
local DREADSTALKER_DURATION = 12
local VILEFIEND_DURATION = 15
local TYRANT_DURATION = 15
local GRIMOIRE_FELGUARD_DURATION = 15

-- Initialize the Demonology module
function Demonology:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Demonology Warlock module initialized")
    
    return true
end

-- Register spell IDs
function Demonology:RegisterSpells()
    -- Demonology Abilities
    spells.CALL_DREADSTALKERS = 104316
    spells.SUMMON_DEMONIC_TYRANT = 265187
    spells.HAND_OF_GULDAN = 105174
    spells.DEMONBOLT = 264178
    spells.SOUL_STRIKE = 264057
    spells.SHADOW_BOLT = 686
    spells.FELSTORM = 89751
    spells.DEMONIC_STRENGTH = 267171
    spells.BILESCOURGE_BOMBERS = 267211
    spells.POWER_SIPHON = 264130
    spells.IMPLOSION = 196277
    spells.DOOM = 603
    spells.SUMMON_VILEFIEND = 264119
    spells.GRIMOIRE_FELGUARD = 111898
    spells.NETHER_PORTAL = 267217
    spells.DEMONIC_CONSUMPTION = 267215
    spells.SUMMON_DEMONIC_TYRANT_BUFF = 265273
    
    -- Procs/Buffs
    spells.DEMONIC_CORE = 264173
    spells.DEMONIC_CORE_BUFF = 264173
    spells.POWER_SIPHON_BUFF = 264173
    spells.NETHER_PORTAL_BUFF = 267218
    spells.FROM_THE_SHADOWS = 267170
    spells.FROM_THE_SHADOWS_DEBUFF = 267172
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.DEMONIC_CORE = spells.DEMONIC_CORE_BUFF
    buffs.NETHER_PORTAL = spells.NETHER_PORTAL_BUFF
    buffs.POWER_SIPHON = spells.POWER_SIPHON_BUFF
    buffs.SUMMON_DEMONIC_TYRANT = spells.SUMMON_DEMONIC_TYRANT_BUFF
    
    debuffs.DOOM = spells.DOOM
    debuffs.FROM_THE_SHADOWS = spells.FROM_THE_SHADOWS_DEBUFF
    
    return true
end

-- Register variables to track
function Demonology:RegisterVariables()
    -- Talent tracking
    talents.hasDemonicConsumption = false
    talents.hasDoom = false
    talents.hasDemonicStrength = false
    talents.hasBilescourgeBombers = false
    talents.hasSummonVilefiend = false
    talents.hasGrimoireFelguard = false
    talents.hasNetherPortal = false
    talents.hasPowerSiphon = false
    talents.hasSoulStrike = false
    talents.hasFromTheShadows = false
    
    -- Target state tracking
    self.targetData = {}
    
    -- Demon tracking
    self.activeDemons = {}
    
    return true
end

-- Register spec-specific settings
function Demonology:RegisterSettings()
    ConfigRegistry:RegisterSettings("DemonologyWarlock", {
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
            useDoom = {
                displayName = "Use Doom",
                description = "Maintain Doom on targets when talented",
                type = "toggle",
                default = true
            },
            impsForImplosion = {
                displayName = "Imps for Implosion",
                description = "Minimum imps to use Implosion",
                type = "slider",
                min = 2,
                max = 10,
                default = 3
            },
            useImplosion = {
                displayName = "Use Implosion",
                description = "Use Implosion for AoE damage",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useDemonicTyrant = {
                displayName = "Use Summon Demonic Tyrant",
                description = "Automatically summon Demonic Tyrant",
                type = "toggle",
                default = true
            },
            tyrantMode = {
                displayName = "Tyrant Usage",
                description = "When to use Demonic Tyrant",
                type = "dropdown",
                options = {"Max Demons", "On Cooldown", "With Core Demons"},
                default = "With Core Demons"
            },
            useDemonicStrength = {
                displayName = "Use Demonic Strength",
                description = "Use Demonic Strength when talented",
                type = "toggle",
                default = true
            },
            useGrimoireFelguard = {
                displayName = "Use Grimoire: Felguard",
                description = "Use Grimoire: Felguard when talented",
                type = "toggle",
                default = true
            },
            useSummonVilefiend = {
                displayName = "Use Summon Vilefiend",
                description = "Use Summon Vilefiend when talented",
                type = "toggle",
                default = true
            },
            useBilescourgeBombers = {
                displayName = "Use Bilescourge Bombers",
                description = "Use Bilescourge Bombers when talented",
                type = "toggle",
                default = true
            },
            useNetherPortal = {
                displayName = "Use Nether Portal",
                description = "Use Nether Portal when talented",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            maxHandOfGuldanShards = {
                displayName = "Max Hand of Gul'dan Shards",
                description = "Maximum Soul Shards to spend on Hand of Gul'dan",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            },
            minHandOfGuldanShards = {
                displayName = "Min Hand of Gul'dan Shards",
                description = "Minimum Soul Shards to spend on Hand of Gul'dan",
                type = "slider",
                min = 1,
                max = 3,
                default = 1
            },
            holdDemonicCoreDuringBurst = {
                displayName = "Hold Demonic Core for Burst",
                description = "Save Demonic Core procs for burst windows",
                type = "toggle",
                default = false
            },
            holdShardsForTyrant = {
                displayName = "Hold Shards for Tyrant",
                description = "Save Soul Shards for Demonic Tyrant setup",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Demonic Tyrant controls
            demonicTyrant = AAC.RegisterAbility(spells.SUMMON_DEMONIC_TYRANT, {
                enabled = true,
                minDemons = 3,
                requireDreadstalkers = true,
                requireVilefiend = false
            }),
            
            -- Bilescourge Bombers controls
            bilescourgeBombers = AAC.RegisterAbility(spells.BILESCOURGE_BOMBERS, {
                enabled = true,
                minEnemies = 3,
                useOnCooldown = false
            }),
            
            -- Power Siphon controls
            powerSiphon = AAC.RegisterAbility(spells.POWER_SIPHON, {
                enabled = true,
                minImps = 2,
                saveDuringBurst = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Demonology:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for soul shard updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "SOUL_SHARDS" then
            self:UpdateSoulShards()
        end
    end)
    
    -- Register for target change events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function() 
        self:UpdateTargetData() 
    end)
    
    -- Register for pet events
    API.RegisterEvent("UNIT_PET", function(unit) 
        if unit == "player" then
            self:UpdateDemonStatus()
        end
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial demon status check
    self:UpdateDemonStatus()
    
    return true
end

-- Update talent information
function Demonology:UpdateTalentInfo()
    -- Check for important talents
    talents.hasDemonicConsumption = API.HasTalent(spells.DEMONIC_CONSUMPTION)
    talents.hasDoom = API.HasTalent(spells.DOOM)
    talents.hasDemonicStrength = API.HasTalent(spells.DEMONIC_STRENGTH)
    talents.hasBilescourgeBombers = API.HasTalent(spells.BILESCOURGE_BOMBERS)
    talents.hasSummonVilefiend = API.HasTalent(spells.SUMMON_VILEFIEND)
    talents.hasGrimoireFelguard = API.HasTalent(spells.GRIMOIRE_FELGUARD)
    talents.hasNetherPortal = API.HasTalent(spells.NETHER_PORTAL)
    talents.hasPowerSiphon = API.HasTalent(spells.POWER_SIPHON)
    talents.hasSoulStrike = API.HasTalent(spells.SOUL_STRIKE)
    talents.hasFromTheShadows = API.HasTalent(spells.FROM_THE_SHADOWS)
    
    API.PrintDebug("Demonology Warlock talents updated")
    
    return true
end

-- Update soul shard tracking
function Demonology:UpdateSoulShards()
    currentSoulShards = API.GetPlayerPower()
    handOfGuldanCharges = math.min(currentSoulShards, 3) -- Max 3 charges
    return true
end

-- Update demon status
function Demonology:UpdateDemonStatus()
    -- Reset count
    demonsActive = 0
    
    -- Check for felguard
    felguardActive = API.GetPetType() == "Felguard"
    
    -- Count active demons from tracker
    for demonID, demonData in pairs(self.activeDemons) do
        if demonData.expiration > GetTime() then
            demonsActive = demonsActive + 1
        else
            -- Remove expired demon
            self.activeDemons[demonID] = nil
        end
    end
    
    -- Check for special demons
    dreadstalkersActive = false
    vilefiendActive = false
    
    for _, demonData in pairs(self.activeDemons) do
        if demonData.type == "Dreadstalker" and demonData.expiration > GetTime() then
            dreadstalkersActive = true
        elseif demonData.type == "Vilefiend" and demonData.expiration > GetTime() then
            vilefiendActive = true
        end
    end
    
    return true
end

-- Update target data
function Demonology:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                doom = false,
                doomExpiration = 0,
                fromTheShadows = false,
                fromTheShadowsExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(10) -- Demonology AoE radius
    
    return true
end

-- Handle combat log events
function Demonology:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Demonic Core buff
            if spellID == spells.DEMONIC_CORE_BUFF then
                API.PrintDebug("Demonic Core proc activated")
            end
            
            -- Track Nether Portal
            if spellID == spells.NETHER_PORTAL_BUFF then
                API.PrintDebug("Nether Portal activated")
            end
            
            -- Track Demonic Tyrant buff
            if spellID == spells.SUMMON_DEMONIC_TYRANT_BUFF then
                tyrantActive = true
                API.PrintDebug("Demonic Tyrant activated")
                
                -- Extend demon durations
                local currentTime = GetTime()
                for demonID, demonData in pairs(self.activeDemons) do
                    demonData.expiration = demonData.expiration + 15 -- Extend by 15 seconds
                    API.PrintDebug("Extended " .. demonData.type .. " duration to " .. 
                                  tostring(math.floor(demonData.expiration - currentTime)) .. " seconds")
                end
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == spells.DOOM then
                self.targetData[destGUID].doom = true
                self.targetData[destGUID].doomExpiration = select(6, API.GetDebuffInfo(destGUID, spells.DOOM))
            elseif spellID == spells.FROM_THE_SHADOWS_DEBUFF then
                self.targetData[destGUID].fromTheShadows = true
                self.targetData[destGUID].fromTheShadowsExpiration = select(6, API.GetDebuffInfo(destGUID, spells.FROM_THE_SHADOWS_DEBUFF))
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Demonic Core removal
            if spellID == spells.DEMONIC_CORE_BUFF then
                API.PrintDebug("Demonic Core consumed")
            end
            
            -- Track Nether Portal removal
            if spellID == spells.NETHER_PORTAL_BUFF then
                API.PrintDebug("Nether Portal faded")
            end
            
            -- Track Demonic Tyrant removal
            if spellID == spells.SUMMON_DEMONIC_TYRANT_BUFF then
                tyrantActive = false
                API.PrintDebug("Demonic Tyrant faded")
            end
        end
        
        -- Track debuff removals from targets
        if self.targetData[destGUID] then
            if spellID == spells.DOOM then
                self.targetData[destGUID].doom = false
            elseif spellID == spells.FROM_THE_SHADOWS_DEBUFF then
                self.targetData[destGUID].fromTheShadows = false
            end
        end
    end
    
    -- Track summon events
    if eventType == "SPELL_SUMMON" and sourceGUID == API.GetPlayerGUID() then
        local demonType = "Unknown"
        local duration = 0
        
        -- Identify demon type and duration
        if spellID == spells.CALL_DREADSTALKERS then
            demonType = "Dreadstalker"
            duration = DREADSTALKER_DURATION
            dreadstalkersActive = true
        elseif spellID == spells.SUMMON_VILEFIEND then
            demonType = "Vilefiend"
            duration = VILEFIEND_DURATION
            vilefiendActive = true
        elseif spellID == spells.GRIMOIRE_FELGUARD then
            demonType = "GrimoireFelguard"
            duration = GRIMOIRE_FELGUARD_DURATION
        elseif spellID == spells.HAND_OF_GULDAN then
            demonType = "Imp"
            duration = 20 -- Imp duration
        elseif spellID == spells.SUMMON_DEMONIC_TYRANT then
            demonType = "DemonicTyrant"
            duration = TYRANT_DURATION
            tyrantActive = true
        end
        
        -- Add demon to tracking
        if duration > 0 then
            -- Generate unique ID for this demon
            local demonID = tostring(destGUID) .. tostring(GetTime())
            self.activeDemons[demonID] = {
                type = demonType,
                guid = destGUID,
                expiration = GetTime() + duration
            }
            
            demonsActive = demonsActive + 1
            
            API.PrintDebug("Summoned " .. demonType .. ", total demons: " .. tostring(demonsActive))
            
            -- Limit tracked demons to prevent memory issues
            if demonsActive > MAX_DEMONS_TRACKED then
                -- Find oldest demon to remove
                local oldestTime = GetTime() + 3600 -- Far in the future
                local oldestID = nil
                
                for id, data in pairs(self.activeDemons) do
                    if data.expiration < oldestTime then
                        oldestTime = data.expiration
                        oldestID = id
                    end
                end
                
                -- Remove oldest
                if oldestID then
                    self.activeDemons[oldestID] = nil
                    demonsActive = demonsActive - 1
                end
            end
        end
    end
    
    -- Track important spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.HAND_OF_GULDAN then
            -- Update Soul Shard count after casting
            self:UpdateSoulShards()
        elseif spellID == spells.IMPLOSION then
            -- Reset imp count after Implosion
            local impCount = 0
            for id, data in pairs(self.activeDemons) do
                if data.type == "Imp" then
                    self.activeDemons[id] = nil
                    impCount = impCount + 1
                end
            end
            demonsActive = demonsActive - impCount
            API.PrintDebug("Imploded " .. tostring(impCount) .. " imps")
        end
    end
    
    return true
end

-- Main rotation function
function Demonology:RunRotation()
    -- Check if we should be running Demonology Warlock logic
    if API.GetActiveSpecID() ~= DEMONOLOGY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("DemonologyWarlock")
    
    -- Update variables
    self:UpdateSoulShards()
    self:UpdateDemonStatus()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle cooldowns first
    if self:HandleCooldowns() then
        return true
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation()
    else
        return self:HandleSingleTargetRotation()
    end
end

-- Handle cooldown abilities
function Demonology:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("DemonologyWarlock")
    
    -- Use Nether Portal if talented
    if talents.hasNetherPortal and 
       settings.cooldownSettings.useNetherPortal and
       burstModeActive and 
       currentSoulShards >= 1 and
       API.CanCast(spells.NETHER_PORTAL) then
        API.CastSpell(spells.NETHER_PORTAL)
        return true
    end
    
    -- Use Grimoire: Felguard if talented
    if talents.hasGrimoireFelguard and 
       settings.cooldownSettings.useGrimoireFelguard and
       burstModeActive and 
       currentSoulShards >= 1 and
       API.CanCast(spells.GRIMOIRE_FELGUARD) then
        API.CastSpell(spells.GRIMOIRE_FELGUARD)
        return true
    end
    
    -- Use Demonic Strength if talented
    if talents.hasDemonicStrength and 
       settings.cooldownSettings.useDemonicStrength and
       felguardActive and
       API.CanCast(spells.DEMONIC_STRENGTH) then
        API.CastSpell(spells.DEMONIC_STRENGTH)
        return true
    end
    
    -- Use Bilescourge Bombers if talented
    if talents.hasBilescourgeBombers and 
       settings.cooldownSettings.useBilescourgeBombers and
       settings.abilityControls.bilescourgeBombers.enabled and
       currentAoETargets >= settings.abilityControls.bilescourgeBombers.minEnemies and
       API.CanCast(spells.BILESCOURGE_BOMBERS) then
        
        if settings.abilityControls.bilescourgeBombers.useOnCooldown or burstModeActive then
            API.CastSpellAtCursor(spells.BILESCOURGE_BOMBERS)
            return true
        end
    end
    
    -- Use Summon Vilefiend if talented
    if talents.hasSummonVilefiend and 
       settings.cooldownSettings.useSummonVilefiend and
       currentSoulShards >= 1 and
       API.CanCast(spells.SUMMON_VILEFIEND) then
        API.CastSpell(spells.SUMMON_VILEFIEND)
        return true
    end
    
    -- Use Summon Demonic Tyrant based on settings
    if settings.cooldownSettings.useDemonicTyrant and 
       settings.abilityControls.demonicTyrant.enabled and
       API.CanCast(spells.SUMMON_DEMONIC_TYRANT) then
        
        local shouldUseTyrant = false
        
        if settings.cooldownSettings.tyrantMode == "On Cooldown" then
            shouldUseTyrant = true
        elseif settings.cooldownSettings.tyrantMode == "Max Demons" then
            shouldUseTyrant = demonsActive >= settings.abilityControls.demonicTyrant.minDemons
        elseif settings.cooldownSettings.tyrantMode == "With Core Demons" then
            if (not settings.abilityControls.demonicTyrant.requireDreadstalkers or dreadstalkersActive) and
               (not settings.abilityControls.demonicTyrant.requireVilefiend or vilefiendActive) and
               demonsActive >= settings.abilityControls.demonicTyrant.minDemons then
                shouldUseTyrant = true
            end
        end
        
        if shouldUseTyrant then
            API.CastSpell(spells.SUMMON_DEMONIC_TYRANT)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Demonology:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("DemonologyWarlock")
    
    -- Apply Doom if talented
    if talents.hasDoom and settings.rotationSettings.useDoom then
        -- Get all valid targets
        local validTargets = API.GetAllEnemies(40)
        
        -- Apply Doom to targets if needed
        for _, targetGUID in ipairs(validTargets) do
            if not self.targetData[targetGUID] or 
               not self.targetData[targetGUID].doom or
               self.targetData[targetGUID].doomExpiration - GetTime() < 5 then
                
                if API.CanCast(spells.DOOM) then
                    API.CastSpellOnGUID(spells.DOOM, targetGUID)
                    return true
                end
            end
        end
    end
    
    -- Use Implosion if we have enough imps
    if settings.rotationSettings.useImplosion then
        local impCount = 0
        for _, demonData in pairs(self.activeDemons) do
            if demonData.type == "Imp" and demonData.expiration > GetTime() then
                impCount = impCount + 1
            end
        end
        
        if impCount >= settings.rotationSettings.impsForImplosion and API.CanCast(spells.IMPLOSION) then
            API.CastSpell(spells.IMPLOSION)
            return true
        end
    end
    
    -- Use Call Dreadstalkers if not active
    if not dreadstalkersActive and 
       currentSoulShards >= 2 and 
       API.CanCast(spells.CALL_DREADSTALKERS) then
        API.CastSpell(spells.CALL_DREADSTALKERS)
        return true
    end
    
    -- Use Hand of Gul'dan with maximum shards if possible
    local handShards = math.min(currentSoulShards, settings.advancedSettings.maxHandOfGuldanShards)
    
    -- Adjust shard usage based on settings
    if settings.advancedSettings.holdShardsForTyrant and 
       not tyrantActive and 
       not dreadstalkersActive and
       API.GetSpellCooldownRemaining(spells.SUMMON_DEMONIC_TYRANT) < 10 then
        -- Hold shards for upcoming Tyrant
        handShards = math.min(handShards, settings.advancedSettings.minHandOfGuldanShards)
    end
    
    if handShards >= settings.advancedSettings.minHandOfGuldanShards and 
       API.CanCast(spells.HAND_OF_GULDAN) then
        API.CastSpellAtCursor(spells.HAND_OF_GULDAN)
        return true
    end
    
    -- Use Soul Strike if talented
    if talents.hasSoulStrike and 
       felguardActive and 
       API.CanCast(spells.SOUL_STRIKE) then
        API.CastSpell(spells.SOUL_STRIKE)
        return true
    end
    
    -- Use Power Siphon if talented and we have imps
    if talents.hasPowerSiphon and 
       settings.abilityControls.powerSiphon.enabled then
        
        local impCount = 0
        for _, demonData in pairs(self.activeDemons) do
            if demonData.type == "Imp" and demonData.expiration > GetTime() then
                impCount = impCount + 1
            end
        end
        
        if impCount >= settings.abilityControls.powerSiphon.minImps and 
           API.CanCast(spells.POWER_SIPHON) and
           (not settings.abilityControls.powerSiphon.saveDuringBurst or not burstModeActive) then
            API.CastSpell(spells.POWER_SIPHON)
            return true
        end
    end
    
    -- Use Demonbolt with Demonic Core procs
    if API.PlayerHasBuff(buffs.DEMONIC_CORE) and API.CanCast(spells.DEMONBOLT) then
        -- Check if we should hold Demonic Core for burst
        if not settings.advancedSettings.holdDemonicCoreDuringBurst or 
           burstModeActive or 
           API.GetBuffStacks(buffs.DEMONIC_CORE) >= 3 then
            API.CastSpell(spells.DEMONBOLT)
            return true
        end
    end
    
    -- Use Shadow Bolt as filler
    if API.CanCast(spells.SHADOW_BOLT) then
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Demonology:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("DemonologyWarlock")
    local targetGUID = API.GetTargetGUID()
    
    if not targetGUID or targetGUID == "" then
        return false
    end
    
    -- Initialize target data if needed
    if not self.targetData[targetGUID] then
        self:UpdateTargetData()
    end
    
    -- Apply Doom if talented
    if talents.hasDoom and 
       settings.rotationSettings.useDoom and
       (not self.targetData[targetGUID].doom or
        self.targetData[targetGUID].doomExpiration - GetTime() < 5) and
       API.CanCast(spells.DOOM) then
        API.CastSpell(spells.DOOM)
        return true
    end
    
    -- Use Call Dreadstalkers if not active
    if not dreadstalkersActive and 
       currentSoulShards >= 2 and 
       API.CanCast(spells.CALL_DREADSTALKERS) then
        API.CastSpell(spells.CALL_DREADSTALKERS)
        return true
    end
    
    -- Use Summon Vilefiend if talented and not already active
    if talents.hasSummonVilefiend and 
       settings.cooldownSettings.useSummonVilefiend and
       not vilefiendActive and
       currentSoulShards >= 1 and
       API.CanCast(spells.SUMMON_VILEFIEND) then
        API.CastSpell(spells.SUMMON_VILEFIEND)
        return true
    end
    
    -- Use Hand of Gul'dan with appropriate shards
    local handShards = math.min(currentSoulShards, settings.advancedSettings.maxHandOfGuldanShards)
    
    -- Adjust shard usage based on settings
    if settings.advancedSettings.holdShardsForTyrant and 
       not tyrantActive and 
       not dreadstalkersActive and
       API.GetSpellCooldownRemaining(spells.SUMMON_DEMONIC_TYRANT) < 10 then
        -- Hold shards for upcoming Tyrant
        handShards = math.min(handShards, settings.advancedSettings.minHandOfGuldanShards)
    end
    
    if handShards >= settings.advancedSettings.minHandOfGuldanShards and 
       API.CanCast(spells.HAND_OF_GULDAN) then
        API.CastSpell(spells.HAND_OF_GULDAN)
        return true
    end
    
    -- Use Soul Strike if talented
    if talents.hasSoulStrike and 
       felguardActive and 
       API.CanCast(spells.SOUL_STRIKE) then
        API.CastSpell(spells.SOUL_STRIKE)
        return true
    end
    
    -- Use Power Siphon if talented and we have imps
    if talents.hasPowerSiphon and 
       settings.abilityControls.powerSiphon.enabled then
        
        local impCount = 0
        for _, demonData in pairs(self.activeDemons) do
            if demonData.type == "Imp" and demonData.expiration > GetTime() then
                impCount = impCount + 1
            end
        end
        
        if impCount >= settings.abilityControls.powerSiphon.minImps and 
           API.CanCast(spells.POWER_SIPHON) and
           (not settings.abilityControls.powerSiphon.saveDuringBurst or not burstModeActive) then
            API.CastSpell(spells.POWER_SIPHON)
            return true
        end
    end
    
    -- Use Demonbolt with Demonic Core procs
    if API.PlayerHasBuff(buffs.DEMONIC_CORE) and API.CanCast(spells.DEMONBOLT) then
        -- Check if we should hold Demonic Core for burst
        if not settings.advancedSettings.holdDemonicCoreDuringBurst or 
           burstModeActive or 
           API.GetBuffStacks(buffs.DEMONIC_CORE) >= 3 then
            API.CastSpell(spells.DEMONBOLT)
            return true
        end
    end
    
    -- Use Shadow Bolt as filler
    if API.CanCast(spells.SHADOW_BOLT) then
        API.CastSpell(spells.SHADOW_BOLT)
        return true
    end
    
    return false
end

-- Handle specialization change
function Demonology:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentSoulShards = API.GetPlayerPower()
    demonsActive = 0
    tyrantActive = false
    dreadstalkersActive = false
    vilefiendActive = false
    
    -- Clear demon tracking
    self.activeDemons = {}
    
    -- Check current pet
    felguardActive = API.GetPetType() == "Felguard"
    
    API.PrintDebug("Demonology Warlock state reset on spec change")
    
    return true
end

-- Return the module for loading
return Demonology