------------------------------------------
-- WindrunnerRotations - Frost Mage Module
-- Author: VortexQ8
------------------------------------------

local Frost = {}
-- This will be assigned to addon.Classes.Mage.Frost when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Mage

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local fingerOfFrostProc = false
local brainFreezeProcActive = false
local wintersChillActive = false
local wintersChillStacks = 0
local icyVeinsActive = false
local frostbite = false
local targetFrozen = false
local castingFlurry = false
local splitFingersCount = 0

-- Constants
local FROST_SPEC_ID = 64
local DEFAULT_AOE_THRESHOLD = 3
local WINTERS_CHILL_MAX_STACKS = 2

-- Initialize the Frost module
function Frost:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Frost Mage module initialized")
    
    return true
end

-- Register spell IDs
function Frost:RegisterSpells()
    -- Primary abilities
    spells.FROSTBOLT = 116
    spells.ICE_LANCE = 30455
    spells.FLURRY = 44614
    spells.BLIZZARD = 190356
    spells.FROZEN_ORB = 84714
    spells.ICY_VEINS = 12472
    spells.COMET_STORM = 153595
    spells.CONE_OF_COLD = 120
    spells.EBONBOLT = 257537
    spells.GLACIAL_SPIKE = 199786
    spells.ICE_NOVA = 157997
    spells.RAY_OF_FROST = 205021
    spells.RUNE_OF_POWER = 116011
    spells.MIRROR_IMAGE = 55342
    spells.ARCANE_INTELLECT = 1459
    spells.SUMMON_WATER_ELEMENTAL = 31687
    spells.FREEZE = 33395
    
    -- Procs and buffs
    spells.BRAIN_FREEZE = 190446
    spells.BRAIN_FREEZE_PROC = 190447
    spells.FINGERS_OF_FROST = 112965
    spells.FINGERS_OF_FROST_PROC = 44544
    spells.ICE_FLOES = 108839
    spells.ICE_FLOES_BUFF = 108839
    spells.ICY_VEINS_BUFF = 12472
    spells.WINTERS_CHILL = 228358
    spells.SPLITTING_ICE = 56377
    spells.CHAIN_REACTION = 278309
    spells.CHAIN_REACTION_BUFF = 278310
    spells.THERMAL_VOID = 155149
    spells.GLACIAL_SPIKE_BUFF = 199844
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.BRAIN_FREEZE = spells.BRAIN_FREEZE_PROC
    buffs.FINGERS_OF_FROST = spells.FINGERS_OF_FROST_PROC
    buffs.ICE_FLOES = spells.ICE_FLOES_BUFF
    buffs.ICY_VEINS = spells.ICY_VEINS_BUFF
    buffs.CHAIN_REACTION = spells.CHAIN_REACTION_BUFF
    buffs.GLACIAL_SPIKE = spells.GLACIAL_SPIKE_BUFF
    
    debuffs.WINTERS_CHILL = spells.WINTERS_CHILL
    
    return true
end

-- Register variables to track
function Frost:RegisterVariables()
    -- Talent tracking
    talents.hasGlacialSpike = false
    talents.hasSplittingIce = false
    talents.hasCometStorm = false
    talents.hasIceNova = false
    talents.hasRayOfFrost = false
    talents.hasEbonbolt = false
    talents.hasThermalVoid = false
    talents.hasChainReaction = false
    talents.hasLonelyWinter = false
    talents.hasRuneOfPower = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Frost:RegisterSettings()
    ConfigRegistry:RegisterSettings("FrostMage", {
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
            flurryUsage = {
                displayName = "Flurry Usage",
                description = "When to use Flurry with Brain Freeze",
                type = "dropdown",
                options = {"Only after Frostbolt", "After Glacial Spike also", "Any time"},
                default = "After Glacial Spike also"
            },
            glacialSpikeUsage = {
                displayName = "Glacial Spike Usage",
                description = "When to use Glacial Spike",
                type = "dropdown",
                options = {"With Shatter only", "Always", "Only in Shatter Windows"},
                default = "With Shatter only"
            },
            useMovementAbilities = {
                displayName = "Use Movement Abilities",
                description = "Use Ice Floes and Shimmer to maintain DPS while moving",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useIcyVeins = {
                displayName = "Use Icy Veins",
                description = "Automatically use Icy Veins for burst damage",
                type = "toggle",
                default = true
            },
            useRuneOfPower = {
                displayName = "Use Rune of Power",
                description = "Automatically use Rune of Power when talented",
                type = "toggle",
                default = true
            },
            useMirrorImage = {
                displayName = "Use Mirror Image",
                description = "Automatically use Mirror Image for threat and damage",
                type = "toggle",
                default = true
            },
            useFrozenOrb = {
                displayName = "Use Frozen Orb",
                description = "Automatically use Frozen Orb",
                type = "toggle",
                default = true
            },
            frozenOrbUsage = {
                displayName = "Frozen Orb Usage",
                description = "When to use Frozen Orb",
                type = "dropdown",
                options = {"On Cooldown", "AoE Only", "During Icy Veins"},
                default = "On Cooldown"
            },
            useCometStorm = {
                displayName = "Use Comet Storm",
                description = "Automatically use Comet Storm when talented",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            poolFingersOfFrost = {
                displayName = "Pool Fingers of Frost",
                description = "Hold Fingers of Frost procs for Glacial Spike",
                type = "toggle",
                default = false
            },
            smartIceLance = {
                displayName = "Smart Ice Lance Usage",
                description = "Use Ice Lance with Splitting Ice for cleave",
                type = "toggle",
                default = true
            },
            holdProcsDuringMovement = {
                displayName = "Hold Procs During Movement",
                description = "Save procs for when movement is required",
                type = "toggle",
                default = false
            },
            maintainChainReaction = {
                displayName = "Maintain Chain Reaction",
                description = "Prioritize keeping Chain Reaction stacks active",
                type = "toggle",
                default = true
            },
            waitForRoP = {
                displayName = "Wait for Rune of Power",
                description = "Hold cooldowns for Rune of Power",
                type = "toggle",
                default = false
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Icy Veins controls
            icyVeins = AAC.RegisterAbility(spells.ICY_VEINS, {
                enabled = true,
                useDuringBurstOnly = true,
                minimumHealthPercent = 0
            }),
            
            -- Ray of Frost controls
            rayOfFrost = AAC.RegisterAbility(spells.RAY_OF_FROST, {
                enabled = true,
                useOnCooldown = false,
                requireFixedTarget = true
            }),
            
            -- Comet Storm controls
            cometStorm = AAC.RegisterAbility(spells.COMET_STORM, {
                enabled = true,
                minEnemies = 1,
                useWithOrb = true
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
    
    -- Register for cast changes
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit, castID, spellID) 
        if unit == "player" then
            self:HandleSpellcastStart(spellID) 
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, castID, spellID) 
        if unit == "player" then
            self:HandleSpellcastSuccess(spellID) 
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(unit, castID, spellID) 
        if unit == "player" then
            self:HandleSpellcastInterrupted(spellID) 
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
function Frost:UpdateTalentInfo()
    -- Check for important talents
    talents.hasGlacialSpike = API.HasTalent(spells.GLACIAL_SPIKE)
    talents.hasSplittingIce = API.HasTalent(spells.SPLITTING_ICE)
    talents.hasCometStorm = API.HasTalent(spells.COMET_STORM)
    talents.hasIceNova = API.HasTalent(spells.ICE_NOVA)
    talents.hasRayOfFrost = API.HasTalent(spells.RAY_OF_FROST)
    talents.hasEbonbolt = API.HasTalent(spells.EBONBOLT)
    talents.hasThermalVoid = API.HasTalent(spells.THERMAL_VOID)
    talents.hasChainReaction = API.HasTalent(spells.CHAIN_REACTION)
    talents.hasLonelyWinter = API.HasTalent(31755) -- Lonely Winter talent ID
    talents.hasRuneOfPower = API.HasTalent(spells.RUNE_OF_POWER)
    
    -- Set splitting ice count for cleave targets
    splitFingersCount = talents.hasSplittingIce and 2 or 1
    
    API.PrintDebug("Frost Mage talents updated")
    
    return true
end

-- Update target data
function Frost:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                wintersChillStacks = 0,
                wintersChillExpiration = 0,
                frozen = false,
                frozenExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Frost AoE radius
    
    return true
end

-- Handle combat log events
function Frost:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Brain Freeze proc
            if spellID == spells.BRAIN_FREEZE_PROC then
                brainFreezeProcActive = true
                API.PrintDebug("Brain Freeze proc activated")
            end
            
            -- Track Fingers of Frost proc
            if spellID == spells.FINGERS_OF_FROST_PROC then
                fingerOfFrostProc = true
                API.PrintDebug("Fingers of Frost proc activated")
            end
            
            -- Track Icy Veins
            if spellID == spells.ICY_VEINS_BUFF then
                icyVeinsActive = true
                API.PrintDebug("Icy Veins activated")
            end
            
            -- Track Glacial Spike buff
            if spellID == spells.GLACIAL_SPIKE_BUFF then
                API.PrintDebug("Glacial Spike ready")
            end
            
            -- Track Chain Reaction buff
            if spellID == spells.CHAIN_REACTION_BUFF then
                API.PrintDebug("Chain Reaction proc")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == spells.WINTERS_CHILL then
                self.targetData[destGUID].wintersChillStacks = 2 -- Always starts at 2 stacks
                self.targetData[destGUID].wintersChillExpiration = select(6, API.GetDebuffInfo(destGUID, spells.WINTERS_CHILL))
                
                -- Update for current target
                if destGUID == API.GetTargetGUID() then
                    wintersChillActive = true
                    wintersChillStacks = 2
                    API.PrintDebug("Winter's Chill applied to target: 2 stacks")
                end
            end
            
            -- Track frozen states (Frost Nova, Freeze, etc.)
            local frozenSpells = {122, 33395, 157997, 228600, 228358} -- Frost Nova, Water Elemental Freeze, Ice Nova, etc.
            for _, frozenSpellID in ipairs(frozenSpells) do
                if spellID == frozenSpellID then
                    self.targetData[destGUID].frozen = true
                    self.targetData[destGUID].frozenExpiration = select(6, API.GetDebuffInfo(destGUID, spellID))
                    
                    -- Update for current target
                    if destGUID == API.GetTargetGUID() then
                        targetFrozen = true
                        API.PrintDebug("Target is now frozen")
                    end
                    
                    break
                end
            end
        end
    end
    
    -- Track buff/debuff removals and stack changes
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Brain Freeze removal
            if spellID == spells.BRAIN_FREEZE_PROC then
                brainFreezeProcActive = false
                API.PrintDebug("Brain Freeze consumed")
            end
            
            -- Track Fingers of Frost removal
            if spellID == spells.FINGERS_OF_FROST_PROC then
                fingerOfFrostProc = false
                API.PrintDebug("Fingers of Frost consumed")
            end
            
            -- Track Icy Veins removal
            if spellID == spells.ICY_VEINS_BUFF then
                icyVeinsActive = false
                API.PrintDebug("Icy Veins faded")
            end
            
            -- Track Glacial Spike buff
            if spellID == spells.GLACIAL_SPIKE_BUFF then
                API.PrintDebug("Glacial Spike consumed")
            end
        end
        
        -- Track debuff removals from targets
        if self.targetData[destGUID] then
            if spellID == spells.WINTERS_CHILL then
                self.targetData[destGUID].wintersChillStacks = 0
                
                -- Update for current target
                if destGUID == API.GetTargetGUID() then
                    wintersChillActive = false
                    wintersChillStacks = 0
                    API.PrintDebug("Winter's Chill removed from target")
                end
            end
            
            -- Track frozen state removal
            local frozenSpells = {122, 33395, 157997, 228600, 228358} -- Frost Nova, Water Elemental Freeze, Ice Nova, etc.
            for _, frozenSpellID in ipairs(frozenSpells) do
                if spellID == frozenSpellID then
                    self.targetData[destGUID].frozen = false
                    
                    -- Update for current target
                    if destGUID == API.GetTargetGUID() then
                        targetFrozen = false
                        API.PrintDebug("Target is no longer frozen")
                    end
                    
                    break
                end
            end
        end
    end
    
    -- Track Winter's Chill stack removal
    if eventType == "SPELL_AURA_REMOVED_DOSE" then
        if spellID == spells.WINTERS_CHILL and self.targetData[destGUID] then
            self.targetData[destGUID].wintersChillStacks = select(4, API.GetDebuffInfo(destGUID, spells.WINTERS_CHILL)) or 0
            
            -- Update for current target
            if destGUID == API.GetTargetGUID() then
                wintersChillStacks = self.targetData[destGUID].wintersChillStacks
                API.PrintDebug("Winter's Chill stack consumed, remaining: " .. tostring(wintersChillStacks))
                
                if wintersChillStacks == 0 then
                    wintersChillActive = false
                end
            end
        end
    end
    
    -- Track important spell damage
    if eventType == "SPELL_DAMAGE" and sourceGUID == API.GetPlayerGUID() then
        -- Track Flurry (to reset castingFlurry flag for Brain Freeze sequence)
        if spellID == spells.FLURRY then
            castingFlurry = false
        end
    end
    
    return true
end

-- Handle spell cast start
function Frost:HandleSpellcastStart(spellID)
    -- Track when we're casting Flurry
    if spellID == spells.FLURRY then
        castingFlurry = true
        API.PrintDebug("Casting Flurry")
    end
    
    return true
end

-- Handle spell cast success
function Frost:HandleSpellcastSuccess(spellID)
    return true
end

-- Handle spell cast interrupted
function Frost:HandleSpellcastInterrupted(spellID)
    -- Reset casting flags when interrupted
    if spellID == spells.FLURRY then
        castingFlurry = false
    end
    
    return true
end

-- Main rotation function
function Frost:RunRotation()
    -- Check if we should be running Frost Mage logic
    if API.GetActiveSpecID() ~= FROST_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("FrostMage")
    
    -- Update variables
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    fingerOfFrostProc = API.PlayerHasBuff(buffs.FINGERS_OF_FROST)
    brainFreezeProcActive = API.PlayerHasBuff(buffs.BRAIN_FREEZE)
    
    -- Check for target frozen state
    local targetGUID = API.GetTargetGUID()
    if targetGUID and self.targetData[targetGUID] then
        targetFrozen = self.targetData[targetGUID].frozen
        wintersChillActive = self.targetData[targetGUID].wintersChillStacks > 0
        wintersChillStacks = self.targetData[targetGUID].wintersChillStacks
    end
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle movement if needed
    if API.IsPlayerMoving() and settings.rotationSettings.useMovementAbilities then
        if self:HandleMovement() then
            return true
        end
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

-- Handle movement abilities
function Frost:HandleMovement()
    local settings = ConfigRegistry:GetSettings("FrostMage")
    
    -- Use Ice Floes if available
    if API.HasSpell(spells.ICE_FLOES) and not API.PlayerHasBuff(buffs.ICE_FLOES) and API.CanCast(spells.ICE_FLOES) then
        API.CastSpell(spells.ICE_FLOES)
        return true
    end
    
    -- Use Fingers of Frost or Brain Freeze procs during movement
    if (fingerOfFrostProc or brainFreezeProcActive) and not settings.advancedSettings.holdProcsDuringMovement then
        -- Use Ice Lance with Fingers of Frost
        if fingerOfFrostProc and API.CanCast(spells.ICE_LANCE) then
            API.CastSpell(spells.ICE_LANCE)
            return true
        end
        
        -- Use Flurry with Brain Freeze
        if brainFreezeProcActive and API.CanCast(spells.FLURRY) then
            -- Check flurry usage settings
            if settings.rotationSettings.flurryUsage == "Any time" then
                API.CastSpell(spells.FLURRY)
                return true
            end
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Frost:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("FrostMage")
    
    -- Skip offensive cooldowns if not in burst mode and settings require burst mode
    if not burstModeActive and settings.abilityControls.icyVeins.useDuringBurstOnly then
        return false
    end
    
    -- Check if we should wait for Rune of Power
    local waitForRune = settings.advancedSettings.waitForRoP and 
                        talents.hasRuneOfPower and
                        settings.cooldownSettings.useRuneOfPower and
                        not API.PlayerHasBuff(Mage.spells.RUNE_OF_POWER) and
                        API.CanCast(Mage.spells.RUNE_OF_POWER)
    
    if waitForRune then
        -- Cast Rune of Power first
        API.CastSpell(Mage.spells.RUNE_OF_POWER)
        return true
    end
    
    -- Use Rune of Power
    if talents.hasRuneOfPower and 
       settings.cooldownSettings.useRuneOfPower and
       not API.PlayerHasBuff(Mage.spells.RUNE_OF_POWER) and
       not API.IsPlayerMoving() and
       API.CanCast(Mage.spells.RUNE_OF_POWER) then
        API.CastSpell(Mage.spells.RUNE_OF_POWER)
        return true
    end
    
    -- Use Icy Veins
    if settings.cooldownSettings.useIcyVeins and 
       settings.abilityControls.icyVeins.enabled and
       not icyVeinsActive and
       API.CanCast(spells.ICY_VEINS) then
        
        -- Check health threshold
        if API.GetTargetHealthPercent() >= settings.abilityControls.icyVeins.minimumHealthPercent then
            API.CastSpell(spells.ICY_VEINS)
            return true
        end
    end
    
    -- Use Mirror Image
    if settings.cooldownSettings.useMirrorImage and
       API.CanCast(Mage.spells.MIRROR_IMAGE) then
        API.CastSpell(Mage.spells.MIRROR_IMAGE)
        return true
    end
    
    -- Use Ray of Frost if talented
    if talents.hasRayOfFrost and 
       settings.abilityControls.rayOfFrost.enabled and
       API.CanCast(spells.RAY_OF_FROST) then
        
        -- Check if we need a fixed target
        if not settings.abilityControls.rayOfFrost.requireFixedTarget or not API.IsPlayerMoving() then
            -- Ideally use with shatter effects
            if targetFrozen or wintersChillActive or fingerOfFrostProc then
                API.CastSpell(spells.RAY_OF_FROST)
                return true
            elseif settings.abilityControls.rayOfFrost.useOnCooldown then
                API.CastSpell(spells.RAY_OF_FROST)
                return true
            end
        end
    end
    
    -- Use Frozen Orb
    if settings.cooldownSettings.useFrozenOrb and
       API.CanCast(spells.FROZEN_ORB) then
        
        local useOrb = false
        
        if settings.cooldownSettings.frozenOrbUsage == "On Cooldown" then
            useOrb = true
        elseif settings.cooldownSettings.frozenOrbUsage == "AoE Only" and currentAoETargets >= settings.rotationSettings.aoeThreshold then
            useOrb = true
        elseif settings.cooldownSettings.frozenOrbUsage == "During Icy Veins" and icyVeinsActive then
            useOrb = true
        end
        
        if useOrb then
            API.CastSpell(spells.FROZEN_ORB)
            return true
        end
    end
    
    -- Use Comet Storm if talented
    if talents.hasCometStorm and 
       settings.cooldownSettings.useCometStorm and
       settings.abilityControls.cometStorm.enabled and
       currentAoETargets >= settings.abilityControls.cometStorm.minEnemies and
       API.CanCast(spells.COMET_STORM) then
        
        -- Check if we want to use with Frozen Orb
        if not settings.abilityControls.cometStorm.useWithOrb or 
           API.GetSpellCooldownRemaining(spells.FROZEN_ORB) > 10 then
            API.CastSpell(spells.COMET_STORM)
            return true
        end
    end
    
    -- Use Ice Nova if talented
    if talents.hasIceNova and API.CanCast(spells.ICE_NOVA) then
        -- Use for added damage in AoE or with shatter
        if currentAoETargets >= settings.rotationSettings.aoeThreshold or targetFrozen or fingerOfFrostProc then
            API.CastSpell(spells.ICE_NOVA)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Frost:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("FrostMage")
    
    -- Use Blizzard for AoE
    if API.CanCast(spells.BLIZZARD) then
        API.CastSpellAtCursor(spells.BLIZZARD)
        return true
    end
    
    -- Use Ice Lance with Fingers of Frost (especially good with Splitting Ice)
    if fingerOfFrostProc and API.CanCast(spells.ICE_LANCE) then
        API.CastSpell(spells.ICE_LANCE)
        return true
    end
    
    -- Use Glacial Spike if talented and we have the buff
    if talents.hasGlacialSpike and 
       API.PlayerHasBuff(buffs.GLACIAL_SPIKE) and
       API.CanCast(spells.GLACIAL_SPIKE) then
        
        local useSpike = false
        
        if settings.rotationSettings.glacialSpikeUsage == "Always" then
            useSpike = true
        elseif settings.rotationSettings.glacialSpikeUsage == "With Shatter only" and (brainFreezeProcActive or targetFrozen) then
            useSpike = true
        elseif settings.rotationSettings.glacialSpikeUsage == "Only in Shatter Windows" and 
              (brainFreezeProcActive or targetFrozen or wintersChillActive) then
            useSpike = true
        end
        
        if useSpike then
            API.CastSpell(spells.GLACIAL_SPIKE)
            return true
        end
    end
    
    -- Use Ebonbolt if talented (generates Brain Freeze)
    if talents.hasEbonbolt and API.CanCast(spells.EBONBOLT) then
        API.CastSpell(spells.EBONBOLT)
        return true
    end
    
    -- Use Cone of Cold for AoE
    if API.CanCast(spells.CONE_OF_COLD) and currentAoETargets >= 3 then
        API.CastSpell(spells.CONE_OF_COLD)
        return true
    end
    
    -- Use Flurry with Brain Freeze
    if brainFreezeProcActive and API.CanCast(spells.FLURRY) then
        -- Check flurry usage settings
        local useFlurry = false
        
        if settings.rotationSettings.flurryUsage == "Any time" then
            useFlurry = true
        elseif settings.rotationSettings.flurryUsage == "Only after Frostbolt" then
            -- Only after Frostbolt logic would be handled by cast sequence detection
            useFlurry = false
        elseif settings.rotationSettings.flurryUsage == "After Glacial Spike also" and 
               API.GetLastSpell() == spells.GLACIAL_SPIKE then
            useFlurry = true
        end
        
        if useFlurry then
            API.CastSpell(spells.FLURRY)
            return true
        end
    end
    
    -- Use Frostbolt as filler
    if API.CanCast(spells.FROSTBOLT) then
        API.CastSpell(spells.FROSTBOLT)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Frost:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("FrostMage")
    
    -- Winter's Chill logic - if active, consume with Ice Lance
    if wintersChillActive and wintersChillStacks > 0 and API.CanCast(spells.ICE_LANCE) then
        API.CastSpell(spells.ICE_LANCE)
        return true
    end
    
    -- Fingers of Frost logic
    if fingerOfFrostProc and API.CanCast(spells.ICE_LANCE) then
        -- Check if we should pool Fingers of Frost for Glacial Spike
        if not settings.advancedSettings.poolFingersOfFrost or 
           not talents.hasGlacialSpike or 
           not API.PlayerHasBuff(buffs.GLACIAL_SPIKE) then
            
            -- Use Ice Lance with Fingers of Frost proc
            API.CastSpell(spells.ICE_LANCE)
            return true
        end
    end
    
    -- Use Glacial Spike if talented and we have the buff
    if talents.hasGlacialSpike and 
       API.PlayerHasBuff(buffs.GLACIAL_SPIKE) and
       API.CanCast(spells.GLACIAL_SPIKE) then
        
        local useSpike = false
        
        if settings.rotationSettings.glacialSpikeUsage == "Always" then
            useSpike = true
        elseif settings.rotationSettings.glacialSpikeUsage == "With Shatter only" and (brainFreezeProcActive or targetFrozen) then
            useSpike = true
        elseif settings.rotationSettings.glacialSpikeUsage == "Only in Shatter Windows" and 
              (brainFreezeProcActive or targetFrozen or wintersChillActive) then
            useSpike = true
        end
        
        if useSpike then
            API.CastSpell(spells.GLACIAL_SPIKE)
            return true
        end
    end
    
    -- Brain Freeze logic
    if brainFreezeProcActive and API.CanCast(spells.FLURRY) then
        -- Check flurry usage settings
        local useFlurry = false
        
        if settings.rotationSettings.flurryUsage == "Any time" then
            useFlurry = true
        elseif settings.rotationSettings.flurryUsage == "Only after Frostbolt" then
            -- Don't use Brain Freeze with Ice Lance/other non-Frostbolt casts
            local lastSpell = API.GetLastSpell()
            if lastSpell == spells.FROSTBOLT then
                useFlurry = true
            end
        elseif settings.rotationSettings.flurryUsage == "After Glacial Spike also" then
            local lastSpell = API.GetLastSpell()
            if lastSpell == spells.FROSTBOLT or lastSpell == spells.GLACIAL_SPIKE then
                useFlurry = true
            end
        end
        
        if useFlurry then
            API.CastSpell(spells.FLURRY)
            return true
        end
    end
    
    -- Use Ebonbolt if talented (generates Brain Freeze)
    if talents.hasEbonbolt and API.CanCast(spells.EBONBOLT) then
        API.CastSpell(spells.EBONBOLT)
        return true
    end
    
    -- Use Ice Lance if target is Frozen (from other sources like Frost Nova, etc.)
    if targetFrozen and API.CanCast(spells.ICE_LANCE) then
        API.CastSpell(spells.ICE_LANCE)
        return true
    end
    
    -- Use Ice Nova if talented
    if talents.hasIceNova and API.CanCast(spells.ICE_NOVA) then
        API.CastSpell(spells.ICE_NOVA)
        return true
    end
    
    -- Chain Reaction maintenance if talented
    if talents.hasChainReaction and 
       settings.advancedSettings.maintainChainReaction and
       not API.PlayerHasBuff(buffs.CHAIN_REACTION) and
       API.CanCast(spells.ICE_LANCE) then
        API.CastSpell(spells.ICE_LANCE)
        return true
    end
    
    -- Use Frostbolt as filler
    if API.CanCast(spells.FROSTBOLT) then
        API.CastSpell(spells.FROSTBOLT)
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
    fingerOfFrostProc = API.PlayerHasBuff(buffs.FINGERS_OF_FROST)
    brainFreezeProcActive = API.PlayerHasBuff(buffs.BRAIN_FREEZE)
    wintersChillActive = false
    wintersChillStacks = 0
    icyVeinsActive = API.PlayerHasBuff(buffs.ICY_VEINS)
    targetFrozen = false
    castingFlurry = false
    
    API.PrintDebug("Frost Mage state reset on spec change")
    
    return true
end

-- Return the module for loading
return Frost