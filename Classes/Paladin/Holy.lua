------------------------------------------
-- WindrunnerRotations - Holy Paladin Module
-- Author: VortexQ8
------------------------------------------

local addonName, addon = ...
local Holy = {}
addon.Classes.Paladin.Holy = Holy

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl
local Paladin = addon.Classes.Paladin

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local emergencyHealing = false
local beaconTarget = nil
local lowHealthUnits = {}
local healingRainLocation = nil
local targetToHeal = nil

-- Constants
local HOLY_SPEC_ID = 65
local LIGHT_OF_DAWN_TARGETS = 5
local HOLY_POWER_MAX = 5
local DEFAULT_CRITICAL_HEALTH = 35
local DEFAULT_LOW_HEALTH = 65

-- Initialize the Holy module
function Holy:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Holy Paladin module initialized")
    
    return true
end

-- Register spell IDs
function Holy:RegisterSpells()
    -- Healing spells
    spells.HOLY_SHOCK = 20473
    spells.WORD_OF_GLORY = 85673
    spells.LIGHT_OF_DAWN = 85222
    spells.HOLY_LIGHT = 82326
    spells.FLASH_OF_LIGHT = 19750
    spells.BESTOW_FAITH = 223306
    spells.LIGHT_OF_THE_MARTYR = 183998
    spells.HOLY_PRISM = 114165
    
    -- Utility/Defensive
    spells.BEACON_OF_LIGHT = 53563
    spells.BEACON_OF_FAITH = 156910
    spells.BEACON_OF_VIRTUE = 200025
    spells.DIVINE_PROTECTION = 498
    spells.BLESSING_OF_SACRIFICE = 6940
    spells.AURA_MASTERY = 31821
    spells.AVENGING_WRATH = 31884
    spells.HOLY_AVENGER = 105809
    spells.DIVINE_FAVOR = 210294
    spells.RULE_OF_LAW = 214202
    
    -- DPS
    spells.CRUSADER_STRIKE = 35395
    spells.JUDGMENT = 275773
    spells.CONSECRATION = 26573
    spells.HAMMER_OF_WRATH = 24275
    
    -- Buffs/Procs
    spells.INFUSION_OF_LIGHT = 54149
    spells.GLIMMER_OF_LIGHT = 287280
    spells.DIVINE_PURPOSE = 223817
    spells.AVENGING_WRATH_BUFF = 31884
    spells.DIVINE_FAVOR_BUFF = 210294
    spells.RULE_OF_LAW_BUFF = 214202
    spells.HOLY_AVENGER_BUFF = 105809
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.INFUSION_OF_LIGHT = spells.INFUSION_OF_LIGHT
    buffs.GLIMMER_OF_LIGHT = spells.GLIMMER_OF_LIGHT
    buffs.DIVINE_PURPOSE = spells.DIVINE_PURPOSE
    buffs.AVENGING_WRATH = spells.AVENGING_WRATH_BUFF
    buffs.DIVINE_FAVOR = spells.DIVINE_FAVOR_BUFF
    buffs.RULE_OF_LAW = spells.RULE_OF_LAW_BUFF
    buffs.HOLY_AVENGER = spells.HOLY_AVENGER_BUFF
    
    return true
end

-- Register variables to track
function Holy:RegisterVariables()
    -- Talent tracking
    talents.hasGlimmerOfLight = false
    talents.hasBeaconOfFaith = false
    talents.hasBeaconOfVirtue = false
    talents.hasBestowFaith = false
    talents.hasHolyPrism = false
    talents.hasHolyAvenger = false
    talents.hasDivinePurpose = false
    talents.hasRuleOfLaw = false
    
    -- Group member state tracking
    self.raidHealth = {}
    self.beaconTargets = {}
    self.glimmerTargets = {}
    
    return true
end

-- Register spec-specific settings
function Holy:RegisterSettings()
    ConfigRegistry:RegisterSettings("HolyPaladin", {
        rotationSettings = {
            healingStyle = {
                displayName = "Healing Style",
                description = "Balance focus between tank and raid healing",
                type = "dropdown",
                options = {"Balanced", "Tank Focus", "Raid Focus"},
                default = "Balanced"
            },
            useDPS = {
                displayName = "Use DPS Abilities",
                description = "Use damage abilities when healing not needed",
                type = "toggle",
                default = true
            },
            criticalHealth = {
                displayName = "Critical Health Threshold",
                description = "Health percentage considered critical for emergency healing",
                type = "slider",
                min = 10,
                max = 50,
                default = DEFAULT_CRITICAL_HEALTH
            },
            lowHealth = {
                displayName = "Low Health Threshold",
                description = "Health percentage considered low for priority healing",
                type = "slider",
                min = 50,
                max = 90,
                default = DEFAULT_LOW_HEALTH
            },
            useWordOfGlory = {
                displayName = "Word of Glory Usage",
                description = "How to use Word of Glory holy power spender",
                type = "dropdown",
                options = {"Critical Only", "On Cooldown", "Efficient"},
                default = "Efficient"
            },
            focusTank = {
                displayName = "Focus Tank",
                description = "Prioritize tank healing over other targets",
                type = "toggle",
                default = true
            }
        },
        
        cooldownSettings = {
            useAvengingWrath = {
                displayName = "Use Avenging Wrath",
                description = "Automatically use Avenging Wrath for healing boost",
                type = "toggle",
                default = true
            },
            useHolyAvenger = {
                displayName = "Use Holy Avenger",
                description = "Automatically use Holy Avenger for holy power generation",
                type = "toggle",
                default = true
            },
            useDivineFavor = {
                displayName = "Use Divine Favor",
                description = "Automatically use Divine Favor for critical healing",
                type = "toggle",
                default = true
            },
            useAuraMastery = {
                displayName = "Use Aura Mastery",
                description = "Automatically use Aura Mastery for damage reduction",
                type = "toggle",
                default = true
            },
            auraMasteryThreshold = {
                displayName = "Aura Mastery Threshold",
                description = "Use Aura Mastery when this many raid members are below critical health",
                type = "slider",
                min = 3,
                max = 10,
                default = 5
            },
            avengingWrathThreshold = {
                displayName = "Avenging Wrath Threshold",
                description = "Use Avenging Wrath when this many raid members are below low health",
                type = "slider",
                min = 3,
                max = 10,
                default = 5
            }
        },
        
        beaconSettings = {
            autoBeacon = {
                displayName = "Auto Beacon of Light",
                description = "Automatically apply Beacon of Light to main tank",
                type = "toggle",
                default = true
            },
            autoBeaconFaith = {
                displayName = "Auto Beacon of Faith",
                description = "Automatically apply Beacon of Faith to off-tank",
                type = "toggle",
                default = true
            },
            beaconOfVirtueThreshold = {
                displayName = "Beacon of Virtue Threshold",
                description = "Use Beacon of Virtue when this many raid members are below low health",
                type = "slider",
                min = 3,
                max = 6,
                default = 3
            }
        },
        
        advancedSettings = {
            holyShockPriority = {
                displayName = "Holy Shock Priority",
                description = "Always use Holy Shock as priority spell",
                type = "toggle",
                default = true
            },
            saveHolyPower = {
                displayName = "Save Holy Power",
                description = "Save holy power for Light of Dawn during AoE healing",
                type = "toggle",
                default = true
            },
            minHolyPowerSpend = {
                displayName = "Min Holy Power to Spend",
                description = "Minimum holy power to spend on healing spells",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            },
            useRuleOfLaw = {
                displayName = "Use Rule of Law",
                description = "Use Rule of Law to extend healing range",
                type = "toggle",
                default = true
            },
            ruleOfLawThreshold = {
                displayName = "Rule of Law Threshold",
                description = "Use Rule of Law when target is this far away (yards)",
                type = "slider",
                min = 20,
                max = 40,
                default = 30
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Light of Dawn controls
            lightOfDawn = AAC.RegisterAbility(spells.LIGHT_OF_DAWN, {
                enabled = true,
                minTargets = 3,
                healthThreshold = 80
            }),
            
            -- Holy Prism controls
            holyPrism = AAC.RegisterAbility(spells.HOLY_PRISM, {
                enabled = true,
                minTargets = 3,
                healthThreshold = 70,
                useOnCooldown = false
            }),
            
            -- Beacon of Virtue controls
            beaconOfVirtue = AAC.RegisterAbility(spells.BEACON_OF_VIRTUE, {
                enabled = true,
                minTargets = 3,
                healthThreshold = 60
            })
        }
    })
    
    return true
end

-- Register for events 
function Holy:RegisterEvents()
    -- Register to track group member health
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        self:UpdateUnitHealth(unit) 
    end)
    
    -- Register for combat log events to track healing and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for group roster updates
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function() 
        self:UpdateRaidRoster() 
    end)
    
    -- Register for talent update events
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function() 
        self:UpdateTalentInfo() 
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial raid roster update
    self:UpdateRaidRoster()
    
    return true
end

-- Update talent information
function Holy:UpdateTalentInfo()
    -- Check for important talents
    talents.hasGlimmerOfLight = API.HasTalent(spells.GLIMMER_OF_LIGHT)
    talents.hasBeaconOfFaith = API.HasTalent(spells.BEACON_OF_FAITH)
    talents.hasBeaconOfVirtue = API.HasTalent(spells.BEACON_OF_VIRTUE)
    talents.hasBestowFaith = API.HasTalent(spells.BESTOW_FAITH)
    talents.hasHolyPrism = API.HasTalent(spells.HOLY_PRISM)
    talents.hasHolyAvenger = API.HasTalent(spells.HOLY_AVENGER)
    talents.hasDivinePurpose = API.HasTalent(spells.DIVINE_PURPOSE)
    talents.hasRuleOfLaw = API.HasTalent(spells.RULE_OF_LAW)
    
    API.PrintDebug("Holy Paladin talents updated")
    
    return true
end

-- Update raid roster and initialize health tracking
function Holy:UpdateRaidRoster()
    -- Clear existing data
    self.raidHealth = {}
    
    -- Build new data structure
    local groupSize = API.GetGroupSize()
    for i = 1, groupSize do
        local unit = API.GetGroupUnitID(i)
        if unit then
            self.raidHealth[unit] = {
                name = API.GetUnitName(unit),
                health = API.GetUnitHealthPercent(unit),
                role = API.GetUnitRole(unit),
                beaconOfLight = API.UnitHasBuff(unit, spells.BEACON_OF_LIGHT),
                beaconOfFaith = API.UnitHasBuff(unit, spells.BEACON_OF_FAITH),
                glimmerOfLight = API.UnitHasBuff(unit, spells.GLIMMER_OF_LIGHT),
                isMainTank = API.IsMainTank(unit),
                isOffTank = API.IsOffTank(unit),
                distance = API.GetUnitDistance(unit) or 999
            }
        end
    end
    
    -- Add player to tracking
    self.raidHealth["player"] = {
        name = API.GetUnitName("player"),
        health = API.GetPlayerHealthPercent(),
        role = "HEALER",
        beaconOfLight = false,
        beaconOfFaith = false,
        glimmerOfLight = API.PlayerHasBuff(spells.GLIMMER_OF_LIGHT),
        isMainTank = false,
        isOffTank = false,
        distance = 0
    }
    
    -- Update Beacon targets tracking
    self:UpdateBeaconTargets()
    
    return true
end

-- Update beacon targets tracking
function Holy:UpdateBeaconTargets()
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    self.beaconTargets = {}
    self.glimmerTargets = {}
    
    -- Find units with beacons and glimmers
    for unit, data in pairs(self.raidHealth) do
        if data.beaconOfLight then
            table.insert(self.beaconTargets, unit)
        end
        
        if data.beaconOfFaith then
            table.insert(self.beaconTargets, unit)
        end
        
        if data.glimmerOfLight then
            table.insert(self.glimmerTargets, unit)
        end
    end
    
    -- Check if we should auto-apply beacons
    if settings.beaconSettings.autoBeacon or settings.beaconSettings.autoBeaconFaith then
        -- Find main tank and off-tank
        local mainTank, offTank = nil, nil
        
        for unit, data in pairs(self.raidHealth) do
            if data.isMainTank then
                mainTank = unit
            elseif data.isOffTank then
                offTank = unit
            end
        end
        
        -- Apply Beacon of Light to main tank if needed
        if settings.beaconSettings.autoBeacon and
           mainTank and not self.raidHealth[mainTank].beaconOfLight then
            nextCastOverride = {spell = spells.BEACON_OF_LIGHT, target = mainTank}
            API.PrintDebug("Setting Beacon of Light on main tank: " .. self.raidHealth[mainTank].name)
        end
        
        -- Apply Beacon of Faith to off-tank if talented and needed
        if settings.beaconSettings.autoBeaconFaith and
           talents.hasBeaconOfFaith and
           offTank and not self.raidHealth[offTank].beaconOfFaith then
            nextCastOverride = {spell = spells.BEACON_OF_FAITH, target = offTank}
            API.PrintDebug("Setting Beacon of Faith on off-tank: " .. self.raidHealth[offTank].name)
        end
    end
    
    return true
end

-- Update unit health tracking
function Holy:UpdateUnitHealth(unit)
    if not unit or not self.raidHealth[unit] then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    
    -- Update stored health value
    local newHealth = API.GetUnitHealthPercent(unit)
    local oldHealth = self.raidHealth[unit].health
    self.raidHealth[unit].health = newHealth
    
    -- Update distance
    self.raidHealth[unit].distance = API.GetUnitDistance(unit) or 999
    
    -- Check for critical or low health
    if newHealth <= settings.rotationSettings.criticalHealth and oldHealth > settings.rotationSettings.criticalHealth then
        -- Unit has fallen below critical health threshold
        emergencyHealing = true
        targetToHeal = unit
        API.PrintDebug(self.raidHealth[unit].name .. " is at critical health: " .. newHealth .. "%")
    elseif newHealth <= settings.rotationSettings.lowHealth and oldHealth > settings.rotationSettings.lowHealth then
        -- Unit has fallen below low health threshold
        if not emergencyHealing then
            targetToHeal = unit
        end
        API.PrintDebug(self.raidHealth[unit].name .. " is at low health: " .. newHealth .. "%")
    end
    
    return true
end

-- Handle combat log events
function Holy:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only track events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track Beacon of Light application
        if spellID == spells.BEACON_OF_LIGHT then
            local unitID = API.GUIDToUnitID(destGUID)
            if unitID and self.raidHealth[unitID] then
                self.raidHealth[unitID].beaconOfLight = true
                self:UpdateBeaconTargets()
            end
        end
        
        -- Track Beacon of Faith application
        if spellID == spells.BEACON_OF_FAITH then
            local unitID = API.GUIDToUnitID(destGUID)
            if unitID and self.raidHealth[unitID] then
                self.raidHealth[unitID].beaconOfFaith = true
                self:UpdateBeaconTargets()
            end
        end
        
        -- Track Glimmer of Light application
        if spellID == spells.GLIMMER_OF_LIGHT then
            local unitID = API.GUIDToUnitID(destGUID)
            if unitID and self.raidHealth[unitID] then
                self.raidHealth[unitID].glimmerOfLight = true
                self:UpdateBeaconTargets()
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track Beacon of Light removal
        if spellID == spells.BEACON_OF_LIGHT then
            local unitID = API.GUIDToUnitID(destGUID)
            if unitID and self.raidHealth[unitID] then
                self.raidHealth[unitID].beaconOfLight = false
                self:UpdateBeaconTargets()
            end
        end
        
        -- Track Beacon of Faith removal
        if spellID == spells.BEACON_OF_FAITH then
            local unitID = API.GUIDToUnitID(destGUID)
            if unitID and self.raidHealth[unitID] then
                self.raidHealth[unitID].beaconOfFaith = false
                self:UpdateBeaconTargets()
            end
        end
        
        -- Track Glimmer of Light removal
        if spellID == spells.GLIMMER_OF_LIGHT then
            local unitID = API.GUIDToUnitID(destGUID)
            if unitID and self.raidHealth[unitID] then
                self.raidHealth[unitID].glimmerOfLight = false
                self:UpdateBeaconTargets()
            end
        end
    end
    
    -- Track healing done to analyze efficiency
    if eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL" then
        -- Could add logic here to track healing metrics
    end
    
    return true
end

-- Main rotation function
function Holy:RunRotation()
    -- Check if we should be running Holy Paladin logic
    if API.GetActiveSpecID() ~= HOLY_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    
    -- Handle next cast override (e.g., setting beacons)
    if nextCastOverride and API.CanCast(nextCastOverride.spell) then
        local castData = nextCastOverride
        nextCastOverride = nil
        API.CastSpellOnUnit(castData.spell, castData.target)
        return true
    end
    
    -- Determine current healing situation
    self:UpdateHealingState()
    
    -- Handle cooldowns based on situation
    if self:HandleCooldowns() then
        return true
    end
    
    -- Handle emergency healing
    if emergencyHealing then
        if self:HandleEmergencyHealing() then
            return true
        end
    end
    
    -- Handle normal healing rotation
    if self:HandleNormalHealing() then
        return true
    end
    
    -- If no healing is needed and DPS is enabled, do DPS rotation
    if settings.rotationSettings.useDPS then
        return self:HandleDPSRotation()
    end
    
    return false
end

-- Update healing state information
function Holy:UpdateHealingState()
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    
    -- Reset emergency flag
    emergencyHealing = false
    
    -- Count low and critical health units
    local lowHealthCount = 0
    local criticalHealthCount = 0
    lowHealthUnits = {}
    
    for unit, data in pairs(self.raidHealth) do
        -- Update distance first
        data.distance = API.GetUnitDistance(unit) or 999
        
        -- Check health thresholds
        if data.health <= settings.rotationSettings.criticalHealth then
            criticalHealthCount = criticalHealthCount + 1
            emergencyHealing = true
            table.insert(lowHealthUnits, unit)
            
            -- Set target to heal if not already set
            if not targetToHeal or self.raidHealth[targetToHeal].health > data.health then
                targetToHeal = unit
            end
        elseif data.health <= settings.rotationSettings.lowHealth then
            lowHealthCount = lowHealthCount + 1
            table.insert(lowHealthUnits, unit)
            
            -- Set target to heal if not already in emergency and target not set or has higher health
            if not emergencyHealing and 
               (not targetToHeal or self.raidHealth[targetToHeal].health > data.health) then
                targetToHeal = unit
            end
        end
    end
    
    -- Special handling for tank focus
    if settings.rotationSettings.focusTank then
        for unit, data in pairs(self.raidHealth) do
            if (data.isMainTank or data.isOffTank) and data.health < 90 then
                -- Prioritize tanks that need healing
                if not emergencyHealing or 
                   (self.raidHealth[targetToHeal] and 
                    not self.raidHealth[targetToHeal].isMainTank and 
                    not self.raidHealth[targetToHeal].isOffTank) then
                    targetToHeal = unit
                end
            end
        end
    end
    
    -- If still no target to heal, find lowest health unit
    if not targetToHeal then
        local lowestHealth = 100
        for unit, data in pairs(self.raidHealth) do
            if data.health < lowestHealth and data.health < 95 then
                lowestHealth = data.health
                targetToHeal = unit
            end
        end
    end
    
    return true
end

-- Handle healing cooldowns
function Holy:HandleCooldowns()
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    
    -- Count critical and low health units
    local criticalCount = 0
    local lowHealthCount = 0
    
    for unit, data in pairs(self.raidHealth) do
        if data.health <= settings.rotationSettings.criticalHealth then
            criticalCount = criticalCount + 1
        elseif data.health <= settings.rotationSettings.lowHealth then
            lowHealthCount = lowHealthCount + 1
        end
    end
    
    -- Check if we should use Aura Mastery
    if settings.cooldownSettings.useAuraMastery and 
       criticalCount >= settings.cooldownSettings.auraMasteryThreshold and
       API.CanCast(spells.AURA_MASTERY) then
        API.CastSpell(spells.AURA_MASTERY)
        return true
    end
    
    -- Check if we should use Avenging Wrath
    if settings.cooldownSettings.useAvengingWrath and 
       (lowHealthCount + criticalCount) >= settings.cooldownSettings.avengingWrathThreshold and
       API.CanCast(spells.AVENGING_WRATH) then
        API.CastSpell(spells.AVENGING_WRATH)
        return true
    end
    
    -- Check if we should use Holy Avenger
    if settings.cooldownSettings.useHolyAvenger and
       talents.hasHolyAvenger and
       criticalCount > 0 and
       API.CanCast(spells.HOLY_AVENGER) then
        API.CastSpell(spells.HOLY_AVENGER)
        return true
    end
    
    -- Check if we should use Divine Favor
    if settings.cooldownSettings.useDivineFavor and
       talents.hasDivineFavor and
       criticalCount > 0 and
       API.CanCast(spells.DIVINE_FAVOR) then
        API.CastSpell(spells.DIVINE_FAVOR)
        return true
    end
    
    -- Check if we should use Rule of Law
    if settings.advancedSettings.useRuleOfLaw and
       talents.hasRuleOfLaw and
       not API.PlayerHasBuff(buffs.RULE_OF_LAW) and
       targetToHeal and 
       self.raidHealth[targetToHeal].distance >= settings.advancedSettings.ruleOfLawThreshold and
       API.CanCast(spells.RULE_OF_LAW) then
        API.CastSpell(spells.RULE_OF_LAW)
        return true
    end
    
    return false
end

-- Handle emergency healing
function Holy:HandleEmergencyHealing()
    if not targetToHeal then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    
    -- Check if target is in range for healing
    if self.raidHealth[targetToHeal].distance > 40 then
        -- Try to find another target in range
        local closestUnit = nil
        local closestDistance = 40
        
        for unit, data in pairs(self.raidHealth) do
            if data.health <= settings.rotationSettings.criticalHealth and data.distance < closestDistance then
                closestUnit = unit
                closestDistance = data.distance
            end
        end
        
        if closestUnit then
            targetToHeal = closestUnit
        else
            -- No valid target in range
            return false
        end
    end
    
    -- Holy Shock - highest priority emergency heal
    if API.CanCast(spells.HOLY_SHOCK) then
        API.CastSpellOnUnit(spells.HOLY_SHOCK, targetToHeal)
        return true
    end
    
    -- Word of Glory - use if we have holy power
    local holyPower = API.GetPlayerPower()
    if API.CanCast(spells.WORD_OF_GLORY) and
       (holyPower >= 3 or API.PlayerHasBuff(buffs.DIVINE_PURPOSE)) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, targetToHeal)
        return true
    end
    
    -- Light of the Martyr - emergency filler (costs your health)
    if API.CanCast(spells.LIGHT_OF_THE_MARTYR) and API.GetPlayerHealthPercent() > 50 then
        API.CastSpellOnUnit(spells.LIGHT_OF_THE_MARTYR, targetToHeal)
        return true
    end
    
    -- Flash of Light - fast but expensive heal
    if API.CanCast(spells.FLASH_OF_LIGHT) then
        -- Use with Infusion of Light proc when possible
        API.CastSpellOnUnit(spells.FLASH_OF_LIGHT, targetToHeal)
        return true
    end
    
    return false
end

-- Handle normal healing rotation
function Holy:HandleNormalHealing()
    local settings = ConfigRegistry:GetSettings("HolyPaladin")
    local holyPower = API.GetPlayerPower()
    
    -- Check if we should use AoE healing
    local aoeHealingNeeded = #lowHealthUnits >= 3
    
    -- Check for Beacon of Virtue if talented and needed
    if talents.hasBeaconOfVirtue and 
       settings.abilityControls.beaconOfVirtue.enabled and
       #lowHealthUnits >= settings.abilityControls.beaconOfVirtue.minTargets and
       API.CanCast(spells.BEACON_OF_VIRTUE) then
        
        -- Find the best target for Beacon of Virtue (that will hit the most low health allies)
        local bestTarget = self:FindBestAoETarget(settings.abilityControls.beaconOfVirtue.healthThreshold, 30)
        if bestTarget then
            API.CastSpellOnUnit(spells.BEACON_OF_VIRTUE, bestTarget)
            return true
        end
    end
    
    -- Check for Holy Prism if talented
    if talents.hasHolyPrism and 
       settings.abilityControls.holyPrism.enabled and
       API.CanCast(spells.HOLY_PRISM) then
        
        if aoeHealingNeeded or settings.abilityControls.holyPrism.useOnCooldown then
            -- Find best target for Holy Prism
            local bestTarget = self:FindBestAoETarget(settings.abilityControls.holyPrism.healthThreshold, 15)
            if bestTarget then
                API.CastSpellOnUnit(spells.HOLY_PRISM, bestTarget)
                return true
            end
            
            -- If no good friendly target, can use on hostile target
            if API.GetTargetReaction() == "hostile" then
                API.CastSpell(spells.HOLY_PRISM)
                return true
            end
        end
    end
    
    -- Holy Shock should always be used when available
    if settings.advancedSettings.holyShockPriority and API.CanCast(spells.HOLY_SHOCK) then
        if targetToHeal then
            API.CastSpellOnUnit(spells.HOLY_SHOCK, targetToHeal)
            return true
        end
    end
    
    -- Use Light of Dawn for AoE healing
    if aoeHealingNeeded and
       settings.abilityControls.lightOfDawn.enabled and
       API.CanCast(spells.LIGHT_OF_DAWN) and
       (holyPower >= settings.advancedSettings.minHolyPowerSpend or 
        API.PlayerHasBuff(buffs.DIVINE_PURPOSE)) then
        
        -- Find the direction with most injured allies
        local bestDirection = self:FindBestLightOfDawnDirection(settings.abilityControls.lightOfDawn.healthThreshold)
        if bestDirection then
            -- Face that direction and cast
            API.SetPlayerFacing(bestDirection)
            API.CastSpell(spells.LIGHT_OF_DAWN)
            return true
        end
    end
    
    -- Use Word of Glory based on settings
    if API.CanCast(spells.WORD_OF_GLORY) then
        local wordOfGloryUsage = settings.rotationSettings.useWordOfGlory
        
        if (wordOfGloryUsage == "On Cooldown" and holyPower >= settings.advancedSettings.minHolyPowerSpend) or
           (wordOfGloryUsage == "Efficient" and holyPower >= 4) or
           API.PlayerHasBuff(buffs.DIVINE_PURPOSE) then
            
            if targetToHeal then
                API.CastSpellOnUnit(spells.WORD_OF_GLORY, targetToHeal)
                return true
            end
        end
    end
    
    -- Bestow Faith on tank if talented
    if talents.hasBestowFaith and API.CanCast(spells.BESTOW_FAITH) then
        -- Find a tank to cast it on
        for unit, data in pairs(self.raidHealth) do
            if (data.isMainTank or data.isOffTank) and data.health < 95 then
                API.CastSpellOnUnit(spells.BESTOW_FAITH, unit)
                return true
            end
        end
        
        -- If no tank needs healing, cast on targetToHeal
        if targetToHeal then
            API.CastSpellOnUnit(spells.BESTOW_FAITH, targetToHeal)
            return true
        end
    end
    
    -- Holy Shock if not already used
    if API.CanCast(spells.HOLY_SHOCK) and targetToHeal then
        API.CastSpellOnUnit(spells.HOLY_SHOCK, targetToHeal)
        return true
    end
    
    -- Manage Glimmer of Light if talented
    if talents.hasGlimmerOfLight and targetToHeal then
        -- Check if target already has Glimmer
        if not self.raidHealth[targetToHeal].glimmerOfLight and API.CanCast(spells.HOLY_SHOCK) then
            API.CastSpellOnUnit(spells.HOLY_SHOCK, targetToHeal)
            return true
        end
    end
    
    -- Use Flash of Light or Holy Light based on situation
    if targetToHeal and self.raidHealth[targetToHeal].health < 90 then
        if API.PlayerHasBuff(buffs.INFUSION_OF_LIGHT) and API.CanCast(spells.FLASH_OF_LIGHT) then
            -- Use Flash of Light with Infusion of Light proc
            API.CastSpellOnUnit(spells.FLASH_OF_LIGHT, targetToHeal)
            return true
        elseif self.raidHealth[targetToHeal].health < 75 and API.CanCast(spells.FLASH_OF_LIGHT) then
            -- Use Flash of Light for faster healing on lower health targets
            API.CastSpellOnUnit(spells.FLASH_OF_LIGHT, targetToHeal)
            return true
        elseif API.CanCast(spells.HOLY_LIGHT) then
            -- Use Holy Light as efficient filler heal
            API.CastSpellOnUnit(spells.HOLY_LIGHT, targetToHeal)
            return true
        end
    end
    
    return false
end

-- Handle DPS rotation when healing not needed
function Holy:HandleDPSRotation()
    local holyPower = API.GetPlayerPower()
    
    -- Only DPS if no urgent healing needed
    if targetToHeal and self.raidHealth[targetToHeal].health < 80 then
        return false
    end
    
    -- Generate Holy Power
    
    -- Crusader Strike
    if API.CanCast(spells.CRUSADER_STRIKE) and API.IsSpellInRange(spells.CRUSADER_STRIKE) then
        API.CastSpell(spells.CRUSADER_STRIKE)
        return true
    end
    
    -- Judgment
    if API.CanCast(spells.JUDGMENT) and API.IsSpellInRange(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Holy Shock (on enemy)
    if API.CanCast(spells.HOLY_SHOCK) and API.IsSpellInRange(spells.HOLY_SHOCK) then
        API.CastSpell(spells.HOLY_SHOCK)
        return true
    end
    
    -- Consecration
    if API.CanCast(spells.CONSECRATION) and API.IsSpellInRange(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    -- Hammer of Wrath (if target is below 20%)
    if API.GetTargetHealthPercent() <= 20 and API.CanCast(spells.HAMMER_OF_WRATH) and API.IsSpellInRange(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    return false
end

-- Find the best target for AoE healing spells
function Holy:FindBestAoETarget(healthThreshold, radius)
    local bestTarget = nil
    local maxAffected = 0
    
    for centerUnit, centerData in pairs(self.raidHealth) do
        -- Skip units too far away
        if centerData.distance > 40 then
            goto continue
        end
        
        local affectedCount = 0
        
        -- Count how many low health units would be in range of this potential center
        for unit, data in pairs(self.raidHealth) do
            if data.health <= healthThreshold and API.GetUnitDistance(centerUnit, unit) <= radius then
                affectedCount = affectedCount + 1
            end
        end
        
        if affectedCount > maxAffected then
            maxAffected = affectedCount
            bestTarget = centerUnit
        end
        
        ::continue::
    end
    
    return bestTarget
end

-- Find the best direction to face for Light of Dawn
function Holy:FindBestLightOfDawnDirection(healthThreshold)
    -- Light of Dawn hits in a 110-degree cone in front of the player
    -- We'll check different directions to find the best one
    
    local bestDirection = nil
    local maxAffected = 0
    
    -- Check 8 directions around the player
    for angle = 0, 315, 45 do
        local affectedCount = 0
        
        -- Raycast to find units in this direction
        for unit, data in pairs(self.raidHealth) do
            if data.health <= healthThreshold and data.distance <= 40 then
                -- Check if unit is in this cone (simplified check)
                local unitAngle = API.GetRelativeUnitAngle(unit) or 0
                local angleDiff = math.abs((angle - unitAngle) % 360)
                if angleDiff <= 55 or angleDiff >= 305 then -- 110-degree cone
                    affectedCount = affectedCount + 1
                end
            end
        end
        
        if affectedCount > maxAffected then
            maxAffected = affectedCount
            bestDirection = angle
        end
    end
    
    return bestDirection
end

-- Handle specialization change
function Holy:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    emergencyHealing = false
    targetToHeal = nil
    
    -- Update raid information
    self:UpdateRaidRoster()
    
    return true
end

-- Return the module for loading
return Holy