------------------------------------------
-- WindrunnerRotations - Restoration Druid Module
-- Author: VortexQ8
------------------------------------------

local Restoration = {}
-- This will be assigned to addon.Classes.Druid.Restoration when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Druid

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local rejuvenationTargets = {}
local regrowthTargets = {}
local lifeblosomTargets = {}
local wildGrowthTargets = {}
local innervateActive = false
local soulOfTheForestActive = false
local clearcasting = false
local treeOfLifeActive = false
local incarnationActive = false
local convokeSpiritsCooldown = 120
local tranquilityCooldown = 180
local flourishCooldown = 60
local wildGrowthCooldown = 10
local swiftmendCooldown = 15
local ironbarkCooldown = 60
local healingTouchHealBoost = 1.0 -- Multiplier for healing
local regrowthHealBoost = 1.0 -- Multiplier for healing
local lastRaidFrameUpdate = 0
local raidScanInterval = 0.5
local lowHealthPlayers = {}
local partyHealthStatus = { 
    criticalCount = 0, -- < 30%
    lowCount = 0,      -- < 60%
    mediumCount = 0,   -- < 80%
    stableCount = 0,   -- >= 80%
    averageHealth = 100
}

-- Constants
local RESTORATION_SPEC_ID = 105
local DEFAULT_AOE_THRESHOLD = 3
local CRITICAL_HEALTH_THRESHOLD = 30
local LOW_HEALTH_THRESHOLD = 60
local MEDIUM_HEALTH_THRESHOLD = 80

-- Healing priority targets categorization
local TANK_PRIORITY = 1
local HEALER_PRIORITY = 2
local DPS_PRIORITY = 3

-- Initialize the Restoration module
function Restoration:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Restoration Druid module initialized")
    
    return true
end

-- Register spell IDs
function Restoration:RegisterSpells()
    -- Healing Spells
    spells.REJUVENATION = 774
    spells.REGROWTH = 8936
    spells.LIFEBLOOM = 33763
    spells.WILD_GROWTH = 48438
    spells.SWIFTMEND = 18562
    spells.HEALING_TOUCH = 5185
    spells.TRANQUILITY = 740
    spells.EFFLORESCENCE = 145205
    spells.FLOURISH = 197721
    spells.CENARION_WARD = 102351
    spells.IRONBARK = 102342
    spells.INNERVATE = 29166
    spells.NATURES_CURE = 88423
    spells.REBIRTH = 20484
    spells.NATURES_SWIFTNESS = 132158
    spells.OVERGROWTH = 203651
    spells.ADAPTIVE_SWARM = 325727
    spells.RENEWAL = 108238
    
    -- Offensive Spells
    spells.MOONFIRE = 8921
    spells.SUNFIRE = 93402
    spells.SOLAR_WRATH = 5176
    
    -- Utility Spells
    spells.TYPHOON = 132469
    spells.URSOLS_VORTEX = 102793
    spells.BARKSKIN = 22812
    spells.HIBERNATE = 2637
    spells.CYCLONE = 33786
    spells.ENTANGLING_ROOTS = 339
    
    -- Talent/Azerite Powers/Legendary
    spells.SOUL_OF_THE_FOREST = 158478
    spells.SOUL_OF_THE_FOREST_BUFF = 114108
    spells.GERMINATION = 155675
    spells.CULTIVATION = 200390
    spells.SPRING_BLOSSOMS = 207385
    spells.PHOTOSYNTHESIS = 274902
    spells.CONVOKE_THE_SPIRITS = 391528
    spells.TREE_OF_LIFE = 33891
    spells.INCARNATION_TREE_OF_LIFE = 33891
    spells.INCARNATION_BUFF = 117679
    spells.VISION_OF_UNENDING_GROWTH = 338832
    spells.POWER_OF_THE_ARCHDRUID = 189870
    spells.ABUNDANCE = 207383
    spells.FLOURISH_BUFF = 197721
    spells.CLEARCASTING = 16870
    spells.CLEARCASTING_BUFF = 16870
    
    -- Special Buffs/Debuffs
    spells.HARMONY = 100977  -- Mastery
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.REJUVENATION = spells.REJUVENATION
    buffs.REGROWTH = spells.REGROWTH
    buffs.LIFEBLOOM = spells.LIFEBLOOM
    buffs.WILD_GROWTH = spells.WILD_GROWTH
    buffs.CENARION_WARD = spells.CENARION_WARD
    buffs.SOUL_OF_THE_FOREST = spells.SOUL_OF_THE_FOREST_BUFF
    buffs.CLEARCASTING = spells.CLEARCASTING_BUFF
    buffs.ABUNDANCE = spells.ABUNDANCE
    buffs.NATURES_SWIFTNESS = spells.NATURES_SWIFTNESS
    buffs.INCARNATION = spells.INCARNATION_BUFF
    buffs.FLOURISH = spells.FLOURISH_BUFF
    buffs.INNERVATE = spells.INNERVATE
    
    debuffs.MOONFIRE = spells.MOONFIRE
    debuffs.SUNFIRE = spells.SUNFIRE
    
    return true
end

-- Register variables to track
function Restoration:RegisterVariables()
    -- Talent tracking
    talents.hasSoulOfTheForest = false
    talents.hasGermination = false
    talents.hasCultivation = false
    talents.hasSpringBlossoms = false
    talents.hasPhotosynthesis = false
    talents.hasAbundance = false
    talents.hasInnervateSelf = false
    talents.hasConvokeTheSpirits = false
    talents.hasTreeOfLife = false
    talents.hasIncarnation = false
    talents.hasCenarionWard = false
    talents.hasFlourish = false
    talents.hasEfflorescence = true -- Always considered available
    talents.hasAdaptiveSwarm = false
    talents.hasRenewal = false
    
    -- HoT tracking data
    self.healingTargets = {}
    
    return true
end

-- Register spec-specific settings
function Restoration:RegisterSettings()
    ConfigRegistry:RegisterSettings("RestorationDruid", {
        rotationSettings = {
            prioritizeHoTs = {
                displayName = "Prioritize HoTs",
                description = "Focus on HoT uptime over direct healing",
                type = "toggle",
                default = true
            },
            aggressiveCleansing = {
                displayName = "Aggressive Cleansing",
                description = "Dispel harmful effects quickly",
                type = "toggle",
                default = true
            },
            healingMode = {
                displayName = "Healing Mode",
                description = "Focus of the healing routine",
                type = "dropdown",
                options = {"Balanced", "Tank Focus", "Raid Healing", "Mana Conservation"},
                default = "Balanced"
            },
            useEfflorescenceOnTank = {
                displayName = "Efflorescence On Tank",
                description = "Place Efflorescence at tank's position",
                type = "toggle",
                default = true
            },
            lifebloominTanks = {
                displayName = "Lifebloom on Tanks",
                description = "Keep Lifebloom on tanks",
                type = "toggle",
                default = true
            },
            hotRefreshWindow = {
                displayName = "HoT Refresh Window",
                description = "Seconds before HoT expires to refresh",
                type = "slider",
                min = 1,
                max = 5,
                default = 3
            }
        },
        
        cooldownSettings = {
            useIronbark = {
                displayName = "Use Ironbark",
                description = "Automatically use Ironbark on low health targets",
                type = "toggle",
                default = true
            },
            ironbarkThreshold = {
                displayName = "Ironbark Health Threshold",
                description = "Health percentage to use Ironbark",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useTranquility = {
                displayName = "Use Tranquility",
                description = "Automatically use Tranquility for raid healing",
                type = "toggle",
                default = true
            },
            tranquilityThreshold = {
                displayName = "Tranquility Group Threshold",
                description = "Number of injured players to use Tranquility",
                type = "slider",
                min = 3,
                max = 10,
                default = 5
            },
            useConvoke = {
                displayName = "Use Convoke the Spirits",
                description = "Automatically use Convoke the Spirits",
                type = "toggle",
                default = true
            },
            convokeMode = {
                displayName = "Convoke Usage",
                description = "When to use Convoke the Spirits",
                type = "dropdown",
                options = {"Emergency Only", "On Cooldown", "With Incarnation"},
                default = "Emergency Only"
            },
            useTreeOfLife = {
                displayName = "Use Tree of Life/Incarnation",
                description = "Automatically use Tree of Life or Incarnation",
                type = "toggle",
                default = true
            },
            treeOfLifeThreshold = {
                displayName = "Tree of Life Group Threshold",
                description = "Number of injured players to use Tree of Life",
                type = "slider",
                min = 3,
                max = 10,
                default = 4
            }
        },
        
        offensiveSettings = {
            doDamageInDowntime = {
                displayName = "Do Damage During Downtime",
                description = "Cast offensive spells when healing not needed",
                type = "toggle",
                default = true
            },
            keepMoonfireUp = {
                displayName = "Keep Moonfire Up",
                description = "Maintain Moonfire on current target",
                type = "toggle",
                default = true
            },
            keepSunfireUp = {
                displayName = "Keep Sunfire Up",
                description = "Maintain Sunfire on current target",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            swiftmendUsage = {
                displayName = "Swiftmend Usage",
                description = "When to use Swiftmend",
                type = "dropdown",
                options = {"Emergency Only", "On Cooldown", "Soul of the Forest Proc"},
                default = "Emergency Only"
            },
            rejuvenationThreshold = {
                displayName = "Rejuvenation Health Threshold",
                description = "Health percentage to apply Rejuvenation",
                type = "slider",
                min = 70,
                max = 100,
                default = 90
            },
            regrowthThreshold = {
                displayName = "Regrowth Health Threshold",
                description = "Health percentage to cast Regrowth",
                type = "slider",
                min = 30,
                max = 90,
                default = 70
            },
            wildGrowthThreshold = {
                displayName = "Wild Growth Group Threshold",
                description = "Number of injured players to use Wild Growth",
                type = "slider",
                min = 2,
                max = 6,
                default = 3
            },
            innervateThreshold = {
                displayName = "Innervate Mana Threshold",
                description = "Mana percentage to use Innervate",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Wild Growth controls
            wildGrowth = AAC.RegisterAbility(spells.WILD_GROWTH, {
                enabled = true,
                minInjuredPlayers = 3,
                healthThreshold = 85
            }),
            
            -- Tranquility controls
            tranquility = AAC.RegisterAbility(spells.TRANQUILITY, {
                enabled = true,
                minInjuredPlayers = 5,
                healthThreshold = 60,
                emergencyOnly = false
            }),
            
            -- Ironbark controls
            ironbark = AAC.RegisterAbility(spells.IRONBARK, {
                enabled = true,
                targetPriority = "Tank",
                healthThreshold = 30
            })
        }
    })
    
    return true
end

-- Register for events 
function Restoration:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for unit events
    API.RegisterEvent("UNIT_HEALTH", function(unit) 
        self:UpdateUnitHealth(unit)
    end)
    
    API.RegisterEvent("UNIT_AURA", function(unit) 
        self:UpdateUnitAuras(unit)
    end)
    
    -- Register for group changes
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function() 
        self:ScanRaidFrames() 
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
function Restoration:UpdateTalentInfo()
    -- Check for important talents
    talents.hasSoulOfTheForest = API.HasTalent(spells.SOUL_OF_THE_FOREST)
    talents.hasGermination = API.HasTalent(spells.GERMINATION)
    talents.hasCultivation = API.HasTalent(spells.CULTIVATION)
    talents.hasSpringBlossoms = API.HasTalent(spells.SPRING_BLOSSOMS)
    talents.hasPhotosynthesis = API.HasTalent(spells.PHOTOSYNTHESIS)
    talents.hasAbundance = API.HasTalent(spells.ABUNDANCE)
    talents.hasInnervateSelf = API.HasTalent(spells.INNERVATE) -- This is always available but can be modified by talents
    talents.hasConvokeTheSpirits = API.HasTalent(spells.CONVOKE_THE_SPIRITS)
    talents.hasTreeOfLife = API.HasTalent(spells.TREE_OF_LIFE)
    talents.hasIncarnation = API.HasTalent(spells.INCARNATION_TREE_OF_LIFE)
    talents.hasCenarionWard = API.HasTalent(spells.CENARION_WARD)
    talents.hasFlourish = API.HasTalent(spells.FLOURISH)
    talents.hasAdaptiveSwarm = API.HasTalent(spells.ADAPTIVE_SWARM)
    talents.hasRenewal = API.HasTalent(spells.RENEWAL)
    
    API.PrintDebug("Restoration Druid talents updated")
    
    return true
end

-- Update a unit's health status
function Restoration:UpdateUnitHealth(unit)
    -- Only track party/raid members and player
    if not UnitExists(unit) or (not UnitInParty(unit) and unit ~= "player") then
        return false
    end
    
    local unitGUID = UnitGUID(unit)
    local healthPercent = API.GetUnitHealthPercent(unit)
    
    -- Initialize if needed
    if not self.healingTargets[unitGUID] then
        self.healingTargets[unitGUID] = {
            unit = unit,
            name = UnitName(unit),
            role = self:GetUnitRole(unit),
            healthPercent = healthPercent,
            hots = {
                rejuvenation = false,
                rejuvenationExpiration = 0,
                regrowth = false,
                regrowthExpiration = 0,
                lifebloom = false,
                lifebloomExpiration = 0,
                wildGrowth = false,
                wildGrowthExpiration = 0,
                cenarionWard = false,
                cenarionWardExpiration = 0
            }
        }
    else
        -- Update health
        self.healingTargets[unitGUID].healthPercent = healthPercent
    end
    
    -- Track if this is a low health player
    if healthPercent < LOW_HEALTH_THRESHOLD then
        if not API.TableContains(lowHealthPlayers, unitGUID) then
            table.insert(lowHealthPlayers, unitGUID)
        end
    else
        API.TableRemove(lowHealthPlayers, unitGUID)
    end
    
    return true
end

-- Update unit's HoT status
function Restoration:UpdateUnitAuras(unit)
    if not UnitExists(unit) or (not UnitInParty(unit) and unit ~= "player") then
        return false
    end
    
    local unitGUID = UnitGUID(unit)
    
    -- Initialize if needed
    if not self.healingTargets[unitGUID] then
        self:UpdateUnitHealth(unit)
    end
    
    -- Check for our HoTs
    local hots = self.healingTargets[unitGUID].hots
    
    -- Check for Rejuvenation
    hots.rejuvenation = false
    hots.rejuvenationExpiration = 0
    
    local name, _, _, _, _, expirationTime = API.GetUnitBuff(unit, spells.REJUVENATION)
    if name then
        hots.rejuvenation = true
        hots.rejuvenationExpiration = expirationTime
        
        -- Track all rejuvenation targets
        if not API.TableContains(rejuvenationTargets, unitGUID) then
            table.insert(rejuvenationTargets, unitGUID)
        end
    else
        API.TableRemove(rejuvenationTargets, unitGUID)
    end
    
    -- Check for Regrowth
    hots.regrowth = false
    hots.regrowthExpiration = 0
    
    name, _, _, _, _, expirationTime = API.GetUnitBuff(unit, spells.REGROWTH)
    if name then
        hots.regrowth = true
        hots.regrowthExpiration = expirationTime
        
        -- Track all regrowth targets
        if not API.TableContains(regrowthTargets, unitGUID) then
            table.insert(regrowthTargets, unitGUID)
        end
    else
        API.TableRemove(regrowthTargets, unitGUID)
    end
    
    -- Check for Lifebloom
    hots.lifebloom = false
    hots.lifebloomExpiration = 0
    
    name, _, _, _, _, expirationTime = API.GetUnitBuff(unit, spells.LIFEBLOOM)
    if name then
        hots.lifebloom = true
        hots.lifebloomExpiration = expirationTime
        
        -- Track all lifebloom targets
        if not API.TableContains(lifeblosomTargets, unitGUID) then
            table.insert(lifeblosomTargets, unitGUID)
        end
    else
        API.TableRemove(lifeblosomTargets, unitGUID)
    end
    
    -- Check for Wild Growth
    hots.wildGrowth = false
    hots.wildGrowthExpiration = 0
    
    name, _, _, _, _, expirationTime = API.GetUnitBuff(unit, spells.WILD_GROWTH)
    if name then
        hots.wildGrowth = true
        hots.wildGrowthExpiration = expirationTime
        
        -- Track all wild growth targets
        if not API.TableContains(wildGrowthTargets, unitGUID) then
            table.insert(wildGrowthTargets, unitGUID)
        end
    else
        API.TableRemove(wildGrowthTargets, unitGUID)
    end
    
    -- Check for Cenarion Ward
    if talents.hasCenarionWard then
        hots.cenarionWard = false
        hots.cenarionWardExpiration = 0
        
        name, _, _, _, _, expirationTime = API.GetUnitBuff(unit, spells.CENARION_WARD)
        if name then
            hots.cenarionWard = true
            hots.cenarionWardExpiration = expirationTime
        end
    end
    
    return true
end

-- Scan the raid frames for health status
function Restoration:ScanRaidFrames()
    local now = GetTime()
    if now - lastRaidFrameUpdate < raidScanInterval then
        return
    end
    
    -- Reset counters
    partyHealthStatus.criticalCount = 0
    partyHealthStatus.lowCount = 0
    partyHealthStatus.mediumCount = 0
    partyHealthStatus.stableCount = 0
    partyHealthStatus.averageHealth = 0
    
    local totalHealth = 0
    local playerCount = 0
    
    -- Iterate through party/raid units
    local units = API.GetGroupMembers()
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            self:UpdateUnitHealth(unit)
            self:UpdateUnitAuras(unit)
            
            local unitGUID = UnitGUID(unit)
            if self.healingTargets[unitGUID] then
                local healthPercent = self.healingTargets[unitGUID].healthPercent
                
                -- Categorize by health status
                if healthPercent < CRITICAL_HEALTH_THRESHOLD then
                    partyHealthStatus.criticalCount = partyHealthStatus.criticalCount + 1
                elseif healthPercent < LOW_HEALTH_THRESHOLD then
                    partyHealthStatus.lowCount = partyHealthStatus.lowCount + 1
                elseif healthPercent < MEDIUM_HEALTH_THRESHOLD then
                    partyHealthStatus.mediumCount = partyHealthStatus.mediumCount + 1
                else
                    partyHealthStatus.stableCount = partyHealthStatus.stableCount + 1
                end
                
                totalHealth = totalHealth + healthPercent
                playerCount = playerCount + 1
            end
        end
    end
    
    -- Calculate average health
    if playerCount > 0 then
        partyHealthStatus.averageHealth = totalHealth / playerCount
    else
        partyHealthStatus.averageHealth = 100
    end
    
    lastRaidFrameUpdate = now
    return true
end

-- Handle combat log events
function Restoration:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if sourceGUID == API.GetPlayerGUID() and destGUID == API.GetPlayerGUID() then
            -- Track Clearcasting
            if spellID == buffs.CLEARCASTING then
                clearcasting = true
                API.PrintDebug("Clearcasting proc activated")
            end
            
            -- Track Soul of the Forest
            if spellID == buffs.SOUL_OF_THE_FOREST then
                soulOfTheForestActive = true
                API.PrintDebug("Soul of the Forest active")
            end
            
            -- Track Tree of Life/Incarnation
            if spellID == buffs.INCARNATION then
                if talents.hasIncarnation then
                    incarnationActive = true
                    API.PrintDebug("Incarnation: Tree of Life active")
                else
                    treeOfLifeActive = true
                    API.PrintDebug("Tree of Life active")
                end
            end
            
            -- Track Innervate
            if spellID == buffs.INNERVATE then
                innervateActive = true
                API.PrintDebug("Innervate active")
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Clearcasting
            if spellID == buffs.CLEARCASTING then
                clearcasting = false
                API.PrintDebug("Clearcasting consumed")
            end
            
            -- Track Soul of the Forest
            if spellID == buffs.SOUL_OF_THE_FOREST then
                soulOfTheForestActive = false
                API.PrintDebug("Soul of the Forest faded")
            end
            
            -- Track Tree of Life/Incarnation
            if spellID == buffs.INCARNATION then
                incarnationActive = false
                treeOfLifeActive = false
                API.PrintDebug("Tree of Life/Incarnation faded")
            end
            
            -- Track Innervate
            if spellID == buffs.INNERVATE then
                innervateActive = false
                API.PrintDebug("Innervate faded")
            end
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        -- Track important cooldowns
        if spellID == spells.TRANQUILITY then
            tranquilityCooldown = 180
            C_Timer.After(180, function()
                tranquilityCooldown = 0
                API.PrintDebug("Tranquility ready")
            end)
        elseif spellID == spells.CONVOKE_THE_SPIRITS then
            convokeSpiritsCooldown = 120
            C_Timer.After(120, function()
                convokeSpiritsCooldown = 0
                API.PrintDebug("Convoke the Spirits ready")
            end)
        elseif spellID == spells.FLOURISH then
            flourishCooldown = 60
            C_Timer.After(60, function()
                flourishCooldown = 0
                API.PrintDebug("Flourish ready")
            end)
        elseif spellID == spells.WILD_GROWTH then
            wildGrowthCooldown = 10
            C_Timer.After(10, function()
                wildGrowthCooldown = 0
                API.PrintDebug("Wild Growth ready")
            end)
        elseif spellID == spells.SWIFTMEND then
            swiftmendCooldown = 15
            C_Timer.After(15, function()
                swiftmendCooldown = 0
                API.PrintDebug("Swiftmend ready")
            end)
        elseif spellID == spells.IRONBARK then
            ironbarkCooldown = 60
            C_Timer.After(60, function()
                ironbarkCooldown = 0
                API.PrintDebug("Ironbark ready")
            end)
        end
    end
    
    return true
end

-- Get a unit's role (tank, healer, dps)
function Restoration:GetUnitRole(unit)
    local role = UnitGroupRolesAssigned(unit)
    
    if role == "TANK" then
        return TANK_PRIORITY
    elseif role == "HEALER" then
        return HEALER_PRIORITY
    else
        return DPS_PRIORITY
    end
end

-- Find an appropriate healing target based on role and health
function Restoration:FindHealingTarget(healthThreshold, requireHot, excludeHot)
    local bestTarget = nil
    local lowestHealth = 100
    
    for guid, data in pairs(self.healingTargets) do
        local unitHealth = data.healthPercent
        
        if unitHealth <= healthThreshold then
            local validTarget = true
            
            -- Check if we require a HoT
            if requireHot then
                if requireHot == "rejuvenation" and not data.hots.rejuvenation then
                    validTarget = false
                elseif requireHot == "regrowth" and not data.hots.regrowth then
                    validTarget = false
                elseif requireHot == "any" and not (data.hots.rejuvenation or data.hots.regrowth or 
                                                  data.hots.lifebloom or data.hots.wildGrowth) then
                    validTarget = false
                end
            end
            
            -- Check if we should exclude targets with certain HoTs
            if excludeHot then
                if excludeHot == "rejuvenation" and data.hots.rejuvenation then
                    validTarget = false
                elseif excludeHot == "regrowth" and data.hots.regrowth then
                    validTarget = false
                elseif excludeHot == "wildGrowth" and data.hots.wildGrowth then
                    validTarget = false
                end
            end
            
            if validTarget and unitHealth < lowestHealth then
                bestTarget = data.unit
                lowestHealth = unitHealth
            end
        end
    end
    
    return bestTarget
end

-- Find a target for Lifebloom (prioritize tanks, then lowest health)
function Restoration:FindLifebloomTarget()
    local bestTarget = nil
    local bestPriority = 999
    local lowestHealth = 100
    
    for guid, data in pairs(self.healingTargets) do
        local role = data.role
        local health = data.healthPercent
        
        if not data.hots.lifebloom then
            if role < bestPriority or (role == bestPriority and health < lowestHealth) then
                bestTarget = data.unit
                bestPriority = role
                lowestHealth = health
            end
        end
    end
    
    return bestTarget
end

-- Count how many players need a specific type of healing
function Restoration:CountHealingNeeds(healthThreshold, requireHot, excludeHot)
    local count = 0
    
    for guid, data in pairs(self.healingTargets) do
        local unitHealth = data.healthPercent
        
        if unitHealth <= healthThreshold then
            local validTarget = true
            
            -- Check if we require a HoT
            if requireHot then
                if requireHot == "rejuvenation" and not data.hots.rejuvenation then
                    validTarget = false
                elseif requireHot == "regrowth" and not data.hots.regrowth then
                    validTarget = false
                elseif requireHot == "any" and not (data.hots.rejuvenation or data.hots.regrowth or 
                                                  data.hots.lifebloom or data.hots.wildGrowth) then
                    validTarget = false
                end
            end
            
            -- Check if we should exclude targets with certain HoTs
            if excludeHot then
                if excludeHot == "rejuvenation" and data.hots.rejuvenation then
                    validTarget = false
                elseif excludeHot == "regrowth" and data.hots.regrowth then
                    validTarget = false
                elseif excludeHot == "wildGrowth" and data.hots.wildGrowth then
                    validTarget = false
                end
            end
            
            if validTarget then
                count = count + 1
            end
        end
    end
    
    return count
end

-- Find a target that needs a HoT refresh
function Restoration:FindHotRefreshTarget(hotType, timeThreshold)
    local bestTarget = nil
    local shortestTime = 999
    
    for guid, data in pairs(self.healingTargets) do
        local remaining = 0
        local hasHot = false
        
        if hotType == "rejuvenation" then
            if data.hots.rejuvenation then
                hasHot = true
                remaining = data.hots.rejuvenationExpiration - GetTime()
            end
        elseif hotType == "regrowth" then
            if data.hots.regrowth then
                hasHot = true
                remaining = data.hots.regrowthExpiration - GetTime()
            end
        elseif hotType == "lifebloom" then
            if data.hots.lifebloom then
                hasHot = true
                remaining = data.hots.lifebloomExpiration - GetTime()
            end
        elseif hotType == "cenarionWard" then
            if data.hots.cenarionWard then
                hasHot = true
                remaining = data.hots.cenarionWardExpiration - GetTime()
            end
        end
        
        if hasHot and remaining < timeThreshold and remaining < shortestTime then
            bestTarget = data.unit
            shortestTime = remaining
        end
    end
    
    return bestTarget
end

-- Find a target for Swiftmend (has HoT and low health)
function Restoration:FindSwiftmendTarget()
    local bestTarget = nil
    local lowestHealth = 100
    
    for guid, data in pairs(self.healingTargets) do
        local unitHealth = data.healthPercent
        
        if (data.hots.rejuvenation or data.hots.regrowth) and unitHealth < lowestHealth then
            bestTarget = data.unit
            lowestHealth = unitHealth
        end
    end
    
    return bestTarget
end

-- Find a tank for special abilities
function Restoration:FindTankTarget()
    for guid, data in pairs(self.healingTargets) do
        if data.role == TANK_PRIORITY then
            return data.unit
        end
    end
    
    return nil
end

-- Get the unit with lowest health
function Restoration:GetLowestHealthUnit()
    local lowestHealth = 100
    local lowestUnit = nil
    
    for guid, data in pairs(self.healingTargets) do
        if data.healthPercent < lowestHealth then
            lowestHealth = data.healthPercent
            lowestUnit = data.unit
        end
    end
    
    return lowestUnit, lowestHealth
end

-- Main rotation function
function Restoration:RunRotation()
    -- Check if we should be running Restoration Druid logic
    if API.GetActiveSpecID() ~= RESTORATION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("RestorationDruid")
    
    -- Update raid/party status
    self:ScanRaidFrames()
    
    -- Update variables
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle dispels if needed
    if settings.rotationSettings.aggressiveCleansing and self:HandleDispels() then
        return true
    end
    
    -- Handle emergency healing first
    if self:HandleEmergencyHealing(settings) then
        return true
    end
    
    -- Handle cooldowns
    if self:HandleCooldowns(settings) then
        return true
    end
    
    -- Handle HoT maintenance
    if self:HandleHoTMaintenance(settings) then
        return true
    end
    
    -- Handle standard healing
    if self:HandleStandardHealing(settings) then
        return true
    end
    
    -- Handle offensive abilities in downtime
    if settings.offensiveSettings.doDamageInDowntime and self:HandleOffensiveAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle emergency healing situations
function Restoration:HandleEmergencyHealing(settings)
    -- Use Swiftmend on critically low health targets with HoTs
    if swiftmendCooldown <= 0 and API.CanCast(spells.SWIFTMEND) then
        local swiftmendTarget = self:FindSwiftmendTarget()
        
        if swiftmendTarget and API.GetUnitHealthPercent(swiftmendTarget) < CRITICAL_HEALTH_THRESHOLD then
            API.CastSpellOnUnit(spells.SWIFTMEND, swiftmendTarget)
            return true
        end
    end
    
    -- Use Nature's Swiftness + Regrowth for emergency healing
    if API.CanCast(spells.NATURES_SWIFTNESS) and API.CanCast(spells.REGROWTH) then
        local lowestUnit, lowestHealth = self:GetLowestHealthUnit()
        
        if lowestUnit and lowestHealth < CRITICAL_HEALTH_THRESHOLD then
            API.CastSpell(spells.NATURES_SWIFTNESS)
            nextCastOverride = spells.REGROWTH -- Set up next cast to be Regrowth
            return true
        end
    end
    
    -- Use Ironbark on low health tanks or other players
    if settings.cooldownSettings.useIronbark and 
       ironbarkCooldown <= 0 and 
       API.CanCast(spells.IRONBARK) then
        
        local ironbarkThreshold = settings.cooldownSettings.ironbarkThreshold
        local ironbarkTarget = nil
        
        if settings.abilityControls.ironbark.targetPriority == "Tank" then
            ironbarkTarget = self:FindTankTarget()
            if ironbarkTarget and API.GetUnitHealthPercent(ironbarkTarget) > ironbarkThreshold then
                ironbarkTarget = nil
            end
        end
        
        -- If no tank needs it or priority is different, find lowest health unit
        if not ironbarkTarget then
            ironbarkTarget = self:FindHealingTarget(ironbarkThreshold, nil, nil)
        end
        
        if ironbarkTarget then
            API.CastSpellOnUnit(spells.IRONBARK, ironbarkTarget)
            return true
        end
    end
    
    -- Use Cenarion Ward on tank
    if talents.hasCenarionWard and API.CanCast(spells.CENARION_WARD) then
        local tankTarget = self:FindTankTarget()
        
        if tankTarget and not self.healingTargets[UnitGUID(tankTarget)].hots.cenarionWard then
            API.CastSpellOnUnit(spells.CENARION_WARD, tankTarget)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Restoration:HandleCooldowns(settings)
    -- For multiple low health players, use Wild Growth
    if wildGrowthCooldown <= 0 and 
       API.CanCast(spells.WILD_GROWTH) and
       partyHealthStatus.lowCount >= settings.advancedSettings.wildGrowthThreshold then
        
        -- Find the best target for Wild Growth
        local wildGrowthTarget = self:FindHealingTarget(settings.abilityControls.wildGrowth.healthThreshold, nil, "wildGrowth")
        
        if wildGrowthTarget then
            API.CastSpellOnUnit(spells.WILD_GROWTH, wildGrowthTarget)
            return true
        end
    end
    
    -- Use Flourish to extend HoTs when many players have HoTs and need healing
    if talents.hasFlourish and 
       settings.cooldownSettings.useTranquility and
       flourishCooldown <= 0 and
       API.CanCast(spells.FLOURISH) and
       (partyHealthStatus.criticalCount + partyHealthStatus.lowCount) >= 3 and
       #rejuvenationTargets >= 3 then
        API.CastSpell(spells.FLOURISH)
        return true
    end
    
    -- Use Tranquility for emergency raid healing
    if settings.cooldownSettings.useTranquility and
       tranquilityCooldown <= 0 and
       API.CanCast(spells.TRANQUILITY) and
       (partyHealthStatus.criticalCount + partyHealthStatus.lowCount) >= 
       settings.cooldownSettings.tranquilityThreshold then
        API.CastSpell(spells.TRANQUILITY)
        return true
    end
    
    -- Use Tree of Life / Incarnation
    if (talents.hasTreeOfLife or talents.hasIncarnation) and 
       settings.cooldownSettings.useTreeOfLife and
       API.CanCast(spells.INCARNATION_TREE_OF_LIFE) and
       (partyHealthStatus.criticalCount + partyHealthStatus.lowCount) >= 
       settings.cooldownSettings.treeOfLifeThreshold then
        API.CastSpell(spells.INCARNATION_TREE_OF_LIFE)
        return true
    end
    
    -- Use Convoke the Spirits
    if talents.hasConvokeTheSpirits and 
       settings.cooldownSettings.useConvoke and
       convokeSpiritsCooldown <= 0 and
       API.CanCast(spells.CONVOKE_THE_SPIRITS) then
        
        local shouldUseConvoke = false
        
        if settings.cooldownSettings.convokeMode == "Emergency Only" then
            shouldUseConvoke = partyHealthStatus.criticalCount >= 2 or partyHealthStatus.averageHealth <= 50
        elseif settings.cooldownSettings.convokeMode == "On Cooldown" then
            shouldUseConvoke = true
        elseif settings.cooldownSettings.convokeMode == "With Incarnation" then
            shouldUseConvoke = incarnationActive or treeOfLifeActive
        end
        
        if shouldUseConvoke then
            API.CastSpell(spells.CONVOKE_THE_SPIRITS)
            return true
        end
    end
    
    -- Use Innervate on self if low on mana
    if talents.hasInnervateSelf and 
       API.GetPlayerManaPercent() <= settings.advancedSettings.innervateThreshold and
       API.CanCast(spells.INNERVATE) then
        API.CastSpellOnUnit(spells.INNERVATE, "player")
        return true
    end
    
    return false
end

-- Handle HoT maintenance
function Restoration:HandleHoTMaintenance(settings)
    local refreshWindow = settings.rotationSettings.hotRefreshWindow
    
    -- Keep Lifebloom on tank
    if settings.rotationSettings.lifebloominTanks and API.CanCast(spells.LIFEBLOOM) then
        -- Check for lifebloom that needs refreshing
        local lifeblooomRefreshTarget = self:FindHotRefreshTarget("lifebloom", refreshWindow)
        if lifeblooomRefreshTarget then
            API.CastSpellOnUnit(spells.LIFEBLOOM, lifeblooomRefreshTarget)
            return true
        end
        
        -- If no targets have lifebloom at all, find a tank
        if #lifeblosomTargets == 0 then
            local tankTarget = self:FindTankTarget()
            if tankTarget then
                API.CastSpellOnUnit(spells.LIFEBLOOM, tankTarget)
                return true
            end
        end
    end
    
    -- Refresh high priority Rejuvenations
    if settings.rotationSettings.prioritizeHoTs and API.CanCast(spells.REJUVENATION) then
        local rejuvRefreshTarget = self:FindHotRefreshTarget("rejuvenation", refreshWindow)
        if rejuvRefreshTarget and API.GetUnitHealthPercent(rejuvRefreshTarget) < settings.advancedSettings.rejuvenationThreshold then
            -- If we have germination, check if we should apply the second HoT
            if talents.hasGermination then
                -- Logic to check if target already has both HoTs would go here
                -- Since the game API makes this complex, we'll simplify for this implementation
            end
            
            API.CastSpellOnUnit(spells.REJUVENATION, rejuvRefreshTarget)
            return true
        end
    end
    
    -- Apply Rejuvenation to targets that need it
    if settings.rotationSettings.prioritizeHoTs and API.CanCast(spells.REJUVENATION) then
        local rejuvTarget = self:FindHealingTarget(settings.advancedSettings.rejuvenationThreshold, nil, "rejuvenation")
        if rejuvTarget then
            API.CastSpellOnUnit(spells.REJUVENATION, rejuvTarget)
            return true
        end
    end
    
    -- Refresh Cenarion Ward on tank
    if talents.hasCenarionWard and API.CanCast(spells.CENARION_WARD) then
        local cenarionRefreshTarget = self:FindHotRefreshTarget("cenarionWard", refreshWindow)
        if cenarionRefreshTarget then
            API.CastSpellOnUnit(spells.CENARION_WARD, cenarionRefreshTarget)
            return true
        end
    end
    
    return false
end

-- Handle standard healing
function Restoration:HandleStandardHealing(settings)
    -- Use Swiftmend based on settings
    if swiftmendCooldown <= 0 and API.CanCast(spells.SWIFTMEND) then
        local swiftmendTarget = nil
        
        if settings.advancedSettings.swiftmendUsage == "Emergency Only" then
            swiftmendTarget = self:FindSwiftmendTarget()
            if swiftmendTarget and API.GetUnitHealthPercent(swiftmendTarget) > LOW_HEALTH_THRESHOLD then
                swiftmendTarget = nil
            end
        elseif settings.advancedSettings.swiftmendUsage == "On Cooldown" then
            swiftmendTarget = self:FindSwiftmendTarget()
        elseif settings.advancedSettings.swiftmendUsage == "Soul of the Forest Proc" and talents.hasSoulOfTheForest then
            swiftmendTarget = self:FindSwiftmendTarget()
            if wildGrowthCooldown > 0 then
                swiftmendTarget = nil
            end
        end
        
        if swiftmendTarget then
            API.CastSpellOnUnit(spells.SWIFTMEND, swiftmendTarget)
            return true
        end
    end
    
    -- Use Regrowth on low health targets
    if API.CanCast(spells.REGROWTH) then
        local regrowthTarget = self:FindHealingTarget(settings.advancedSettings.regrowthThreshold, nil, nil)
        
        -- Prioritize Clearcasting procs
        if clearcasting then
            regrowthTarget = self:FindHealingTarget(90, nil, nil) -- Use with clearcasting even on higher health targets
        end
        
        if regrowthTarget then
            API.CastSpellOnUnit(spells.REGROWTH, regrowthTarget)
            return true
        end
    end
    
    -- Use Wild Growth when multiple targets need healing
    if wildGrowthCooldown <= 0 and 
       self:CountHealingNeeds(settings.abilityControls.wildGrowth.healthThreshold, nil, "wildGrowth") >= 
       settings.abilityControls.wildGrowth.minInjuredPlayers and
       API.CanCast(spells.WILD_GROWTH) then
        
        local wildGrowthTarget = self:FindHealingTarget(settings.abilityControls.wildGrowth.healthThreshold, nil, "wildGrowth")
        
        if wildGrowthTarget then
            API.CastSpellOnUnit(spells.WILD_GROWTH, wildGrowthTarget)
            return true
        end
    end
    
    -- Use Healing Touch for efficient healing
    if API.CanCast(spells.HEALING_TOUCH) then
        local healingTouchTarget = self:FindHealingTarget(80, nil, nil)
        
        if healingTouchTarget then
            API.CastSpellOnUnit(spells.HEALING_TOUCH, healingTouchTarget)
            return true
        end
    end
    
    -- Use Efflorescence if it's not already down
    if talents.hasEfflorescence and API.CanCast(spells.EFFLORESCENCE) then
        -- Logic for placing Efflorescence would go here
        -- Simplified for this implementation
        local efflorescenceTarget = nil
        
        if settings.rotationSettings.useEfflorescenceOnTank then
            efflorescenceTarget = self:FindTankTarget()
        end
        
        if not efflorescenceTarget then
            -- Place near the most grouped up players
            efflorescenceTarget = "player" -- Simplified
        end
        
        if efflorescenceTarget then
            API.CastSpellAtLocation(spells.EFFLORESCENCE, API.GetUnitPosition(efflorescenceTarget))
            return true
        end
    end
    
    return false
end

-- Handle offensive abilities during downtime
function Restoration:HandleOffensiveAbilities(settings)
    -- Maintain Moonfire on target
    if settings.offensiveSettings.keepMoonfireUp and API.CanCast(spells.MOONFIRE) then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and targetGUID ~= "" then
            local name = API.GetDebuffInfo(targetGUID, spells.MOONFIRE)
            
            if not name then
                API.CastSpell(spells.MOONFIRE)
                return true
            end
        end
    end
    
    -- Maintain Sunfire on target
    if settings.offensiveSettings.keepSunfireUp and API.CanCast(spells.SUNFIRE) then
        local targetGUID = API.GetTargetGUID()
        
        if targetGUID and targetGUID ~= "" then
            local name = API.GetDebuffInfo(targetGUID, spells.SUNFIRE)
            
            if not name then
                API.CastSpell(spells.SUNFIRE)
                return true
            end
        end
    end
    
    -- Cast Solar Wrath for damage during downtime
    if partyHealthStatus.averageHealth > 90 and API.CanCast(spells.SOLAR_WRATH) then
        API.CastSpell(spells.SOLAR_WRATH)
        return true
    end
    
    return false
end

-- Handle dispels
function Restoration:HandleDispels()
    if API.CanCast(spells.NATURES_CURE) then
        local dispelTarget = nil
        
        -- Logic to find a party member with a dispellable debuff would go here
        -- Simplified for this implementation
        
        if dispelTarget then
            API.CastSpellOnUnit(spells.NATURES_CURE, dispelTarget)
            return true
        end
    end
    
    return false
end

-- Handle specialization change
function Restoration:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    rejuvenationTargets = {}
    regrowthTargets = {}
    lifeblosomTargets = {}
    wildGrowthTargets = {}
    innervateActive = false
    soulOfTheForestActive = false
    clearcasting = false
    treeOfLifeActive = false
    incarnationActive = false
    convokeSpiritsCooldown = 0
    tranquilityCooldown = 0
    flourishCooldown = 0
    wildGrowthCooldown = 0
    swiftmendCooldown = 0
    ironbarkCooldown = 0
    
    -- Reset healing target data
    self.healingTargets = {}
    lowHealthPlayers = {}
    
    API.PrintDebug("Restoration Druid state reset on spec change")
    
    return true
end

-- Return the module for loading
return Restoration