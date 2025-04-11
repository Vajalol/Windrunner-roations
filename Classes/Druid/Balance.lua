------------------------------------------
-- WindrunnerRotations - Balance Druid Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Balance = {}
addon.Classes.Druid.Balance = Balance

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local Druid = addon.Classes.Druid

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local eclipseActive = false
local lunarEclipse = false
local solarEclipse = false
local astralPower = 0
local maxAstralPower = 100
local inMoonkinForm = false

-- Constants
local BALANCE_SPEC_ID = 102
local ASTRAL_POWER_THRESHOLD = 90
local DEFAULT_AOE_THRESHOLD = 3
local CAST_SEQUENCE_STATE = 0

-- Initialize the Balance module
function Balance:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Balance Druid module initialized")
    
    return true
end

-- Register spell IDs
function Balance:RegisterSpells()
    -- Balance Abilities
    spells.STARSURGE = 78674
    spells.STARFALL = 191034
    spells.CELESTIAL_ALIGNMENT = 194223
    spells.INCARNATION = 102560
    spells.SOLAR_BEAM = 78675
    spells.SOLAR_WRATH = 190984
    spells.LUNAR_STRIKE = 194153
    spells.MOONFIRE = 8921
    spells.SUNFIRE = 93402
    spells.STELLAR_FLARE = 202347
    spells.FURY_OF_ELUNE = 202770
    spells.NEW_MOON = 274281
    spells.HALF_MOON = 274282
    spells.FULL_MOON = 274283
    spells.FORCE_OF_NATURE = 205636
    spells.WARRIOR_OF_ELUNE = 202425
    spells.ONETH_CLEAR_VISION = 338825
    spells.ONETH_STARFALL_BUFF = 339797
    spells.RAVENOUS_FRENZY = 323546
    spells.CONVOKE_THE_SPIRITS = 323764
    
    -- Eclipse States
    spells.ECLIPSE_SOLAR = 48517
    spells.ECLIPSE_LUNAR = 48518
    spells.WRATH_ECLIPSE_MARKER = 48517
    spells.STARFIRE_ECLIPSE_MARKER = 48518
    
    -- Forms
    spells.MOONKIN_FORM = 24858
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.ECLIPSE_SOLAR = spells.ECLIPSE_SOLAR
    buffs.ECLIPSE_LUNAR = spells.ECLIPSE_LUNAR
    buffs.CELESTIAL_ALIGNMENT = spells.CELESTIAL_ALIGNMENT
    buffs.INCARNATION = spells.INCARNATION
    buffs.WARRIOR_OF_ELUNE = spells.WARRIOR_OF_ELUNE
    buffs.ONETH_CLEAR_VISION = spells.ONETH_CLEAR_VISION
    buffs.ONETH_STARFALL_BUFF = spells.ONETH_STARFALL_BUFF
    buffs.MOONKIN_FORM = spells.MOONKIN_FORM
    buffs.RAVENOUS_FRENZY = spells.RAVENOUS_FRENZY
    
    debuffs.MOONFIRE = spells.MOONFIRE
    debuffs.SUNFIRE = spells.SUNFIRE
    debuffs.STELLAR_FLARE = spells.STELLAR_FLARE
    
    return true
end

-- Register variables to track
function Balance:RegisterVariables()
    -- Talent tracking
    talents.hasStellarFlare = false
    talents.hasIncarnation = false
    talents.hasForceOfNature = false
    talents.hasFuryOfElune = false
    talents.hasStellarDrift = false
    talents.hasNewMoon = false
    talents.hasWarriorOfElune = false
    talents.hasSoulOfTheForest = false
    
    -- Legendary tracking
    talents.hasOnethsClearVision = false
    talents.hasBalanceCelestialInfusion = false
    
    -- Target state tracking
    self.targetData = {}
    
    -- Cast sequence tracking
    self.castSequence = {
        state = CAST_SEQUENCE_STATE,
        wrathCount = 0,
        lunarStrikeCount = 0
    }
    
    return true
end

-- Register spec-specific settings
function Balance:RegisterSettings()
    ConfigRegistry:RegisterSettings("BalanceDruid", {
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
            maintainDots = {
                displayName = "Maintain DoTs",
                description = "Keep Moonfire and Sunfire active on targets",
                type = "toggle",
                default = true
            },
            useStellarFlare = {
                displayName = "Use Stellar Flare",
                description = "Maintain Stellar Flare DoT when talented",
                type = "toggle",
                default = true
            },
            astralPowerThreshold = {
                displayName = "Astral Power Threshold",
                description = "Threshold to spend Astral Power on Starsurge/Starfall",
                type = "slider",
                min = 30,
                max = 100,
                default = ASTRAL_POWER_THRESHOLD
            }
        },
        
        cooldownSettings = {
            useCelestialAlignment = {
                displayName = "Use Celestial Alignment",
                description = "Automatically use Celestial Alignment / Incarnation",
                type = "toggle",
                default = true
            },
            useForceOfNature = {
                displayName = "Use Force of Nature",
                description = "Automatically summon Treants when talented",
                type = "toggle",
                default = true
            },
            useFuryOfElune = {
                displayName = "Use Fury of Elune",
                description = "Automatically use Fury of Elune when talented",
                type = "toggle",
                default = true
            },
            holdCooldowns = {
                displayName = "Hold Cooldowns for Eclipse",
                description = "Only use major cooldowns during Eclipse phases",
                type = "toggle",
                default = true
            },
            useConvoke = {
                displayName = "Use Convoke the Spirits",
                description = "Automatically use Convoke the Spirits (if covenant)",
                type = "toggle",
                default = true
            },
            convokeWithCelestial = {
                displayName = "Convoke with Celestial Alignment",
                description = "Only use Convoke during Celestial Alignment/Incarnation",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            preferredEclipse = {
                displayName = "Preferred Eclipse",
                description = "Prefer a specific Eclipse if possible",
                type = "dropdown",
                options = {"None", "Solar", "Lunar", "Both Equally"},
                default = "None"
            },
            saveAstralPower = {
                displayName = "Save Astral Power for AoE",
                description = "Save Astral Power for Starfall in AoE situations",
                type = "toggle",
                default = true
            },
            cancelStarfall = {
                displayName = "Cancel Starfall for ST",
                description = "Cancel Starfall if target count drops below threshold",
                type = "toggle",
                default = false
            },
            useSolarBeam = {
                displayName = "Use Solar Beam",
                description = "Automatically interrupt with Solar Beam",
                type = "toggle",
                default = true
            },
            dotCount = {
                displayName = "DoT Target Cap",
                description = "Maximum targets to apply DoTs to (0 = all)",
                type = "slider",
                min = 0,
                max = 10,
                default = 5
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Celestial Alignment controls
            celestialAlignment = AAC.RegisterAbility(spells.CELESTIAL_ALIGNMENT, {
                enabled = true,
                useDuringBurstOnly = true,
                minimumHealthPercent = 0
            }),
            
            -- Fury of Elune controls
            furyOfElune = AAC.RegisterAbility(spells.FURY_OF_ELUNE, {
                enabled = true,
                minEnemies = 1,
                useOnCooldown = false,
                useWithConvoke = true
            }),
            
            -- Force of Nature controls
            forceOfNature = AAC.RegisterAbility(spells.FORCE_OF_NATURE, {
                enabled = true,
                useOnCooldown = true,
                useWithCelestial = false
            })
        }
    })
    
    return true
end

-- Register for events 
function Balance:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for Eclipse triggers
    API.RegisterEvent("ECLIPSE_DIRECTION_CHANGE", function(direction) 
        self:HandleEclipseChange(direction) 
    end)
    
    -- Register for Astral Power updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "LUNAR_POWER" then
            self:UpdateAstralPower()
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
function Balance:UpdateTalentInfo()
    -- Check for important talents
    talents.hasStellarFlare = API.HasTalent(spells.STELLAR_FLARE)
    talents.hasIncarnation = API.HasTalent(spells.INCARNATION)
    talents.hasForceOfNature = API.HasTalent(spells.FORCE_OF_NATURE)
    talents.hasFuryOfElune = API.HasTalent(spells.FURY_OF_ELUNE)
    talents.hasNewMoon = API.HasTalent(spells.NEW_MOON)
    talents.hasWarriorOfElune = API.HasTalent(spells.WARRIOR_OF_ELUNE)
    
    -- Check for legendary effects
    talents.hasOnethsClearVision = API.HasLegendaryEffect(spells.ONETH_CLEAR_VISION)
    
    API.PrintDebug("Balance Druid talents updated")
    
    return true
end

-- Update target data
function Balance:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                moonfire = false,
                moonfireExpiration = 0,
                sunfire = false,
                sunfireExpiration = 0,
                stellarFlare = false,
                stellarFlareExpiration = 0
            }
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Balance AoE radius
    
    return true
end

-- Update Astral Power tracking
function Balance:UpdateAstralPower()
    astralPower = API.GetPlayerPower()
    return true
end

-- Handle Eclipse state changes
function Balance:HandleEclipseChange(direction)
    -- Direction: 0 = neutral, 1 = lunar, 2 = solar
    if direction == 1 then
        self.castSequence.wrathCount = 0
        self.castSequence.state = 1 -- Cast Wrath for Lunar Eclipse
    elseif direction == 2 then
        self.castSequence.lunarStrikeCount = 0
        self.castSequence.state = 2 -- Cast Lunar Strike for Solar Eclipse
    else
        self.castSequence.state = 0 -- Neutral state
    end
    
    API.PrintDebug("Eclipse direction changed to: " .. tostring(direction))
    return true
end

-- Handle combat log events
function Balance:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track Eclipse states
        if spellID == spells.ECLIPSE_LUNAR and sourceGUID == API.GetPlayerGUID() then
            lunarEclipse = true
            eclipseActive = true
            API.PrintDebug("Lunar Eclipse activated")
        elseif spellID == spells.ECLIPSE_SOLAR and sourceGUID == API.GetPlayerGUID() then
            solarEclipse = true
            eclipseActive = true
            API.PrintDebug("Solar Eclipse activated")
        elseif spellID == spells.CELESTIAL_ALIGNMENT and sourceGUID == API.GetPlayerGUID() then
            lunarEclipse = true
            solarEclipse = true
            eclipseActive = true
            API.PrintDebug("Celestial Alignment activated")
        elseif spellID == spells.INCARNATION and sourceGUID == API.GetPlayerGUID() then
            lunarEclipse = true
            solarEclipse = true
            eclipseActive = true
            API.PrintDebug("Incarnation activated")
        elseif spellID == spells.MOONKIN_FORM and sourceGUID == API.GetPlayerGUID() then
            inMoonkinForm = true
        end
        
        -- Track DoT applications
        if destGUID and self.targetData[destGUID] then
            if spellID == spells.MOONFIRE then
                self.targetData[destGUID].moonfire = true
                self.targetData[destGUID].moonfireExpiration = select(6, API.GetDebuffInfo(destGUID, spells.MOONFIRE))
            elseif spellID == spells.SUNFIRE then
                self.targetData[destGUID].sunfire = true
                self.targetData[destGUID].sunfireExpiration = select(6, API.GetDebuffInfo(destGUID, spells.SUNFIRE))
            elseif spellID == spells.STELLAR_FLARE then
                self.targetData[destGUID].stellarFlare = true
                self.targetData[destGUID].stellarFlareExpiration = select(6, API.GetDebuffInfo(destGUID, spells.STELLAR_FLARE))
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track Eclipse states
        if spellID == spells.ECLIPSE_LUNAR and sourceGUID == API.GetPlayerGUID() then
            lunarEclipse = false
            if not solarEclipse then
                eclipseActive = false
            end
            API.PrintDebug("Lunar Eclipse faded")
        elseif spellID == spells.ECLIPSE_SOLAR and sourceGUID == API.GetPlayerGUID() then
            solarEclipse = false
            if not lunarEclipse then
                eclipseActive = false
            end
            API.PrintDebug("Solar Eclipse faded")
        elseif spellID == spells.CELESTIAL_ALIGNMENT and sourceGUID == API.GetPlayerGUID() then
            -- Only remove eclipses if Incarnation isn't active
            if not API.PlayerHasBuff(buffs.INCARNATION) then
                lunarEclipse = false
                solarEclipse = false
                eclipseActive = false
            end
            API.PrintDebug("Celestial Alignment faded")
        elseif spellID == spells.INCARNATION and sourceGUID == API.GetPlayerGUID() then
            -- Only remove eclipses if Celestial Alignment isn't active
            if not API.PlayerHasBuff(buffs.CELESTIAL_ALIGNMENT) then
                lunarEclipse = false
                solarEclipse = false
                eclipseActive = false
            end
            API.PrintDebug("Incarnation faded")
        elseif spellID == spells.MOONKIN_FORM and sourceGUID == API.GetPlayerGUID() then
            inMoonkinForm = false
        end
        
        -- Track DoT removals
        if destGUID and self.targetData[destGUID] then
            if spellID == spells.MOONFIRE then
                self.targetData[destGUID].moonfire = false
            elseif spellID == spells.SUNFIRE then
                self.targetData[destGUID].sunfire = false
            elseif spellID == spells.STELLAR_FLARE then
                self.targetData[destGUID].stellarFlare = false
            end
        end
    end
    
    -- Track spell casts for Eclipse sequence
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.SOLAR_WRATH then
            self.castSequence.wrathCount = self.castSequence.wrathCount + 1
        elseif spellID == spells.LUNAR_STRIKE then
            self.castSequence.lunarStrikeCount = self.castSequence.lunarStrikeCount + 1
        end
    end
    
    return true
end

-- Main rotation function
function Balance:RunRotation()
    -- Check if we should be running Balance Druid logic
    if API.GetActiveSpecID() ~= BALANCE_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BalanceDruid")
    
    -- Update variables
    self:UpdateAstralPower()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Ensure we're in Moonkin Form
    if not inMoonkinForm and API.CanCast(spells.MOONKIN_FORM) then
        API.CastSpell(spells.MOONKIN_FORM)
        return true
    end
    
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
    
    -- Handle interrupts
    if settings.advancedSettings.useSolarBeam and API.CanCast(spells.SOLAR_BEAM) then
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and targetCastEnd - GetTime() < 0.5 then
            API.CastSpell(spells.SOLAR_BEAM)
            return true
        end
    end
    
    -- Check for AoE or Single Target
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation()
    else
        return self:HandleSingleTargetRotation()
    end
end

-- Handle cooldown abilities
function Balance:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("BalanceDruid")
    
    -- Skip offensive cooldowns if not in burst mode and settings require burst mode
    if not burstModeActive and settings.abilityControls.celestialAlignment.useDuringBurstOnly then
        return false
    end
    
    -- Use Warrior of Elune
    if talents.hasWarriorOfElune and API.CanCast(spells.WARRIOR_OF_ELUNE) then
        API.CastSpell(spells.WARRIOR_OF_ELUNE)
        return true
    end
    
    -- Use Celestial Alignment or Incarnation
    if settings.cooldownSettings.useCelestialAlignment and 
       settings.abilityControls.celestialAlignment.enabled and 
       not eclipseActive then
        
        local alignmentSpell = talents.hasIncarnation and spells.INCARNATION or spells.CELESTIAL_ALIGNMENT
        
        if API.CanCast(alignmentSpell) and 
           API.GetTargetHealthPercent() >= settings.abilityControls.celestialAlignment.minimumHealthPercent then
            API.CastSpell(alignmentSpell)
            return true
        end
    end
    
    -- Use Force of Nature if talented
    if talents.hasForceOfNature and 
       settings.cooldownSettings.useForceOfNature and
       settings.abilityControls.forceOfNature.enabled and
       API.CanCast(spells.FORCE_OF_NATURE) then
        
        -- Check if we should align with Celestial Alignment
        if not settings.abilityControls.forceOfNature.useWithCelestial or
           API.PlayerHasBuff(buffs.CELESTIAL_ALIGNMENT) or
           API.PlayerHasBuff(buffs.INCARNATION) then
            API.CastSpell(spells.FORCE_OF_NATURE)
            return true
        end
    end
    
    -- Use Fury of Elune if talented
    if talents.hasFuryOfElune and 
       settings.cooldownSettings.useFuryOfElune and
       settings.abilityControls.furyOfElune.enabled and
       currentAoETargets >= settings.abilityControls.furyOfElune.minEnemies and
       API.CanCast(spells.FURY_OF_ELUNE) then
        
        -- Cast at cursor or target
        API.CastSpellAtCursor(spells.FURY_OF_ELUNE)
        return true
    end
    
    -- Use Convoke the Spirits
    if settings.cooldownSettings.useConvoke and API.CanCast(spells.CONVOKE_THE_SPIRITS) then
        -- Check if we need to align with Celestial Alignment
        if not settings.cooldownSettings.convokeWithCelestial or
           API.PlayerHasBuff(buffs.CELESTIAL_ALIGNMENT) or
           API.PlayerHasBuff(buffs.INCARNATION) then
            API.CastSpell(spells.CONVOKE_THE_SPIRITS)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Balance:HandleAoERotation()
    local settings = ConfigRegistry:GetSettings("BalanceDruid")
    
    -- Apply DoTs if needed
    if settings.rotationSettings.maintainDots then
        -- Get cap on number of targets to DoT
        local dotCap = settings.advancedSettings.dotCount
        local dottedTargets = 0
        
        -- Apply DoTs on multiple targets if there's a cap
        if dotCap > 0 then
            -- Count currently dotted targets
            for _, data in pairs(self.targetData) do
                if data.moonfire and data.sunfire and (not talents.hasStellarFlare or data.stellarFlare) then
                    dottedTargets = dottedTargets + 1
                end
            end
        end
        
        -- Apply to target if below cap or no cap
        if dotCap == 0 or dottedTargets < dotCap then
            local targetGUID = API.GetTargetGUID()
            
            if targetGUID and self.targetData[targetGUID] then
                -- Apply Moonfire if needed
                if not self.targetData[targetGUID].moonfire or
                   self.targetData[targetGUID].moonfireExpiration - GetTime() < 3 then
                    if API.CanCast(spells.MOONFIRE) then
                        API.CastSpell(spells.MOONFIRE)
                        return true
                    end
                end
                
                -- Apply Sunfire if needed
                if not self.targetData[targetGUID].sunfire or
                   self.targetData[targetGUID].sunfireExpiration - GetTime() < 3 then
                    if API.CanCast(spells.SUNFIRE) then
                        API.CastSpell(spells.SUNFIRE)
                        return true
                    end
                end
                
                -- Apply Stellar Flare if talented and enabled
                if talents.hasStellarFlare and settings.rotationSettings.useStellarFlare and
                   (not self.targetData[targetGUID].stellarFlare or
                   self.targetData[targetGUID].stellarFlareExpiration - GetTime() < 3) then
                    if API.CanCast(spells.STELLAR_FLARE) then
                        API.CastSpell(spells.STELLAR_FLARE)
                        return true
                    end
                end
            end
        end
    end
    
    -- Use Starfall with Astral Power if we have enough
    local shouldUseStarfall = astralPower >= settings.rotationSettings.astralPowerThreshold
    
    -- Check for Oneth's Clear Vision proc
    if talents.hasOnethsClearVision and API.PlayerHasBuff(buffs.ONETH_CLEAR_VISION) then
        shouldUseStarfall = true
    end
    
    if shouldUseStarfall and API.CanCast(spells.STARFALL) then
        API.CastSpellAtCursor(spells.STARFALL)
        return true
    end
    
    -- Handle Eclipse building and usage
    if not eclipseActive then
        -- No Eclipse active, build toward it
        if self.castSequence.state == 1 then
            -- Cast Wrath to get Lunar Eclipse
            if API.CanCast(spells.SOLAR_WRATH) then
                API.CastSpell(spells.SOLAR_WRATH)
                return true
            end
        elseif self.castSequence.state == 2 then
            -- Cast Lunar Strike to get Solar Eclipse
            if API.CanCast(spells.LUNAR_STRIKE) then
                API.CastSpell(spells.LUNAR_STRIKE)
                return true
            end
        else
            -- Neutral state, prefer AoE spells
            if API.CanCast(spells.LUNAR_STRIKE) then
                API.CastSpell(spells.LUNAR_STRIKE)
                return true
            end
        end
    else
        -- In Eclipse, use best spells
        if lunarEclipse then
            -- Lunar Eclipse active, Lunar Strike is empowered
            if API.CanCast(spells.LUNAR_STRIKE) then
                API.CastSpell(spells.LUNAR_STRIKE)
                return true
            end
        end
        
        if solarEclipse then
            -- Solar Eclipse active, Solar Wrath is empowered
            if API.CanCast(spells.SOLAR_WRATH) then
                API.CastSpell(spells.SOLAR_WRATH)
                return true
            end
        end
    end
    
    -- Use New Moon cycle if talented
    if talents.hasNewMoon then
        if API.CanCast(spells.NEW_MOON) then
            API.CastSpell(spells.NEW_MOON)
            return true
        elseif API.CanCast(spells.HALF_MOON) then
            API.CastSpell(spells.HALF_MOON)
            return true
        elseif API.CanCast(spells.FULL_MOON) then
            API.CastSpell(spells.FULL_MOON)
            return true
        end
    end
    
    -- Default to Solar Wrath as filler
    if API.CanCast(spells.SOLAR_WRATH) then
        API.CastSpell(spells.SOLAR_WRATH)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Balance:HandleSingleTargetRotation()
    local settings = ConfigRegistry:GetSettings("BalanceDruid")
    
    -- Apply DoTs if needed
    if settings.rotationSettings.maintainDots then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and self.targetData[targetGUID] then
            -- Apply Moonfire if needed
            if not self.targetData[targetGUID].moonfire or
               self.targetData[targetGUID].moonfireExpiration - GetTime() < 3 then
                if API.CanCast(spells.MOONFIRE) then
                    API.CastSpell(spells.MOONFIRE)
                    return true
                end
            end
            
            -- Apply Sunfire if needed
            if not self.targetData[targetGUID].sunfire or
               self.targetData[targetGUID].sunfireExpiration - GetTime() < 3 then
                if API.CanCast(spells.SUNFIRE) then
                    API.CastSpell(spells.SUNFIRE)
                    return true
                end
            end
            
            -- Apply Stellar Flare if talented and enabled
            if talents.hasStellarFlare and settings.rotationSettings.useStellarFlare and
               (not self.targetData[targetGUID].stellarFlare or
               self.targetData[targetGUID].stellarFlareExpiration - GetTime() < 3) then
                if API.CanCast(spells.STELLAR_FLARE) then
                    API.CastSpell(spells.STELLAR_FLARE)
                    return true
                end
            end
        end
    end
    
    -- Use Starsurge with Astral Power if we have enough
    local shouldUseStarsurge = astralPower >= settings.rotationSettings.astralPowerThreshold
    
    -- Check for Oneth's Clear Vision proc
    if talents.hasOnethsClearVision and API.PlayerHasBuff(buffs.ONETH_CLEAR_VISION) then
        shouldUseStarsurge = true
    end
    
    if shouldUseStarsurge and API.CanCast(spells.STARSURGE) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    -- Handle Eclipse building and usage
    if not eclipseActive then
        -- No Eclipse active, build toward it
        if self.castSequence.state == 1 then
            -- Cast Wrath to get Lunar Eclipse
            if API.CanCast(spells.SOLAR_WRATH) then
                API.CastSpell(spells.SOLAR_WRATH)
                return true
            end
        elseif self.castSequence.state == 2 then
            -- Cast Lunar Strike to get Solar Eclipse
            if API.CanCast(spells.LUNAR_STRIKE) then
                API.CastSpell(spells.LUNAR_STRIKE)
                return true
            end
        else
            -- Neutral state, prefer Wrath for single target
            if API.CanCast(spells.SOLAR_WRATH) then
                API.CastSpell(spells.SOLAR_WRATH)
                return true
            end
        end
    else
        -- In Eclipse, use best spells
        if lunarEclipse and solarEclipse then
            -- Both Eclipses active, Wrath is better for single target
            if API.CanCast(spells.SOLAR_WRATH) then
                API.CastSpell(spells.SOLAR_WRATH)
                return true
            end
        elseif lunarEclipse then
            -- Lunar Eclipse active, still prefer Wrath for single target usually
            if settings.advancedSettings.preferredEclipse == "Lunar" then
                -- User prefers Lunar Strike
                if API.CanCast(spells.LUNAR_STRIKE) then
                    API.CastSpell(spells.LUNAR_STRIKE)
                    return true
                end
            else
                -- Default to Wrath
                if API.CanCast(spells.SOLAR_WRATH) then
                    API.CastSpell(spells.SOLAR_WRATH)
                    return true
                end
            end
        elseif solarEclipse then
            -- Solar Eclipse active, Solar Wrath is empowered
            if API.CanCast(spells.SOLAR_WRATH) then
                API.CastSpell(spells.SOLAR_WRATH)
                return true
            end
        end
    end
    
    -- Use New Moon cycle if talented
    if talents.hasNewMoon then
        if API.CanCast(spells.NEW_MOON) then
            API.CastSpell(spells.NEW_MOON)
            return true
        elseif API.CanCast(spells.HALF_MOON) then
            API.CastSpell(spells.HALF_MOON)
            return true
        elseif API.CanCast(spells.FULL_MOON) then
            API.CastSpell(spells.FULL_MOON)
            return true
        end
    end
    
    -- Default to Solar Wrath as filler
    if API.CanCast(spells.SOLAR_WRATH) then
        API.CastSpell(spells.SOLAR_WRATH)
        return true
    end
    
    return false
end

-- Handle specialization change
function Balance:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    eclipseActive = false
    lunarEclipse = false
    solarEclipse = false
    astralPower = API.GetPlayerPower()
    inMoonkinForm = API.PlayerHasBuff(spells.MOONKIN_FORM)
    
    -- Reset cast sequence
    self.castSequence = {
        state = CAST_SEQUENCE_STATE,
        wrathCount = 0,
        lunarStrikeCount = 0
    }
    
    return true
end

-- Return the module for loading
return Balance