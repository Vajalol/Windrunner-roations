------------------------------------------
-- WindrunnerRotations - Balance Druid Module
-- Author: VortexQ8
------------------------------------------

local Balance = {}
-- This will be assigned to addon.Classes.Druid.Balance when loaded

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
local currentAstralPower = 0
local maxAstralPower = 100
local eclipseState = "NONE" -- NONE, SOLAR, LUNAR
local eclipseTimeRemaining = 0
local sunfireActive = false
local sunfireExpiration = 0
local moonfireActive = false
local moonfireExpiration = 0
local stellarFlareActive = false
local stellarFlareExpiration = 0
local starfallActive = false
local starfallTimeRemaining = 0
local starsurgeStacks = 0
local onethsActive = false
local onethsTimeRemaining = 0
local celestialAlignmentActive = false
local celestialAlignmentTimeRemaining = 0
local incarnationActive = false
local incarnationTimeRemaining = 0
local starlordStacks = 0
local starlordTimeRemaining = 0
local lunarEclipseCounter = 0
local solarEclipseCounter = 0
local furyOfElune = false
local orbitalStrike = false
local umbralIntensity = 0
local primordialArcanicPulsar = 0
local starweaversWarp = false
local starweaversWeft = false
local touchOfEclipse = false
local ravenousFrenzy = false
local moonkinForm = false
local kindredSpiritsActive = false
local fallenOrderActive = false
local boatActive = false
local surgeActive = false
local wildSurge = false
local solsticeActive = false
local balanceOfAllThingsLunar = 0
local balanceOfAllThingsSolar = 0

-- Constants
local BALANCE_SPEC_ID = 102
local DEFAULT_AOE_THRESHOLD = 3
local SUNFIRE_REFRESH_THRESHOLD = 5.4 -- Time (in seconds) to start sunfire refresh
local MOONFIRE_REFRESH_THRESHOLD = 6.6 -- Time (in seconds) to start moonfire refresh
local STELLAR_FLARE_REFRESH_THRESHOLD = 5.4 -- Time (in seconds) to start stellar flare refresh
local ECLIPSE_DURATION = 15
local CELESTIAL_ALIGNMENT_DURATION = 20
local INCARNATION_DURATION = 30
local STARFALL_DURATION = 8
local STARLORD_DURATION = 15
local BALANCE_OF_ALL_THINGS_DURATION = 8
local SOLAR_ECLIPSE_WRATH_COUNT = 3
local LUNAR_ECLIPSE_STARFIRE_COUNT = 2

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
    -- Main rotational abilities
    spells.WRATH = 190984
    spells.STARFIRE = 194153
    spells.STARSURGE = 78674
    spells.STARFALL = 191034
    spells.MOONFIRE = 8921
    spells.SUNFIRE = 93402
    spells.STELLAR_FLARE = 202347
    spells.FURY_OF_ELUNE = 202770
    spells.NEW_MOON = 274281
    spells.HALF_MOON = 274282
    spells.FULL_MOON = 274283
    spells.FORCE_OF_NATURE = 205636
    spells.CELESTIAL_ALIGNMENT = 194223
    spells.INCARNATION_CHOSEN_OF_ELUNE = 102560
    spells.ONETH_CLEAR_VISION = 339797
    
    -- Utility/Defensive
    spells.MOONKIN_FORM = 197625
    spells.BARKSKIN = 22812
    spells.RENEWAL = 108238
    spells.WILD_CHARGE = 102401
    spells.TYPHOON = 132469
    spells.URSOLS_VORTEX = 102793
    spells.MIGHTY_BASH = 5211
    spells.MASS_ENTANGLEMENT = 102359
    spells.HIBERNATE = 2637
    spells.SOOTHE = 2908
    spells.REBIRTH = 20484
    spells.CYCLONE = 33786
    spells.INNERVATE = 29166
    spells.CONVOKE_THE_SPIRITS = 323764
    spells.SOLSTICE = 343648
    spells.WARRIOR_OF_ELUNE = 202425
    spells.HEART_OF_THE_WILD = 319454
    
    -- Talents & Procs
    spells.TWIN_MOONS = 279620
    spells.SOUL_OF_THE_FOREST = 114107
    spells.STARLORD = 202345
    spells.STELLAR_DRIFT = 202354
    spells.NATURES_BALANCE = 202430
    spells.SHOOTING_STARS = 202342
    spells.BALANCE_OF_ALL_THINGS = 339942
    spells.PRIMORDIAL_ARCANIC_PULSAR = 338668
    spells.ORBITAL_STRIKE = 390378
    spells.UMBRAL_INTENSITY = 383197
    spells.STARWEAVERS_WARP = 393940
    spells.STARWEAVERS_WEFT = 393942
    spells.TOUCH_OF_THE_COSMOS = 394414
    spells.ASTRAL_COMMUNION = 202359
    spells.STELLAR_INSPIRATION = 394047
    spells.CELESTIAL_INFUSION = 387283
    spells.IMPROVED_STARFALL = 393922
    spells.IMPROVED_STARSURGE = 393934
    spells.WILD_SURGES = 405647
    
    -- Covenant abilities
    spells.KINDRED_SPIRITS = 326434
    spells.RAVENOUS_FRENZY = 323546
    spells.EMPOWER_BOND = 326462
    
    -- Buff IDs
    spells.ECLIPSE_SOLAR = 48517
    spells.ECLIPSE_LUNAR = 48518
    spells.CELESTIAL_ALIGNMENT_BUFF = 194223
    spells.INCARNATION_CHOSEN_OF_ELUNE_BUFF = 102560
    spells.STARLORD_BUFF = 279709
    spells.ONETHS_CLEAR_VISION_BUFF = 339797
    spells.ONETHS_PERCEPTION_BUFF = 339800
    spells.OWLKIN_FRENZY = 157228
    spells.WARRIOR_OF_ELUNE_BUFF = 202425
    spells.STARWEAVER_BUFF = 393942
    spells.TOUCH_OF_THE_COSMOS_BUFF = 394414
    spells.HEART_OF_THE_WILD_BUFF = 108291
    spells.MOMENT_OF_CLARITY = 236068
    spells.BALANCE_OF_ALL_THINGS_ARCANE_BUFF = 339946
    spells.BALANCE_OF_ALL_THINGS_NATURE_BUFF = 339943
    spells.STARFALL_BUFF = 191034
    spells.MOONKIN_FORM_BUFF = 24858
    spells.RAVENOUS_FRENZY_BUFF = 323546
    spells.KINDRED_EMPOWERMENT_BUFF = 327022
    spells.SOLSTICE_BUFF = 343648
    
    -- Debuff IDs
    spells.MOONFIRE_DEBUFF = 164812
    spells.SUNFIRE_DEBUFF = 164815
    spells.STELLAR_FLARE_DEBUFF = 202347
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.ECLIPSE_SOLAR = spells.ECLIPSE_SOLAR
    buffs.ECLIPSE_LUNAR = spells.ECLIPSE_LUNAR
    buffs.CELESTIAL_ALIGNMENT = spells.CELESTIAL_ALIGNMENT_BUFF
    buffs.INCARNATION = spells.INCARNATION_CHOSEN_OF_ELUNE_BUFF
    buffs.STARLORD = spells.STARLORD_BUFF
    buffs.ONETHS_CLEAR_VISION = spells.ONETHS_CLEAR_VISION_BUFF
    buffs.ONETHS_PERCEPTION = spells.ONETHS_PERCEPTION_BUFF
    buffs.OWLKIN_FRENZY = spells.OWLKIN_FRENZY
    buffs.WARRIOR_OF_ELUNE = spells.WARRIOR_OF_ELUNE_BUFF
    buffs.STARWEAVER = spells.STARWEAVER_BUFF
    buffs.TOUCH_OF_THE_COSMOS = spells.TOUCH_OF_THE_COSMOS_BUFF
    buffs.HEART_OF_THE_WILD = spells.HEART_OF_THE_WILD_BUFF
    buffs.MOMENT_OF_CLARITY = spells.MOMENT_OF_CLARITY
    buffs.BALANCE_OF_ALL_THINGS_ARCANE = spells.BALANCE_OF_ALL_THINGS_ARCANE_BUFF
    buffs.BALANCE_OF_ALL_THINGS_NATURE = spells.BALANCE_OF_ALL_THINGS_NATURE_BUFF
    buffs.STARFALL = spells.STARFALL_BUFF
    buffs.MOONKIN_FORM = spells.MOONKIN_FORM_BUFF
    buffs.RAVENOUS_FRENZY = spells.RAVENOUS_FRENZY_BUFF
    buffs.KINDRED_EMPOWERMENT = spells.KINDRED_EMPOWERMENT_BUFF
    buffs.SOLSTICE = spells.SOLSTICE_BUFF
    
    debuffs.MOONFIRE = spells.MOONFIRE_DEBUFF
    debuffs.SUNFIRE = spells.SUNFIRE_DEBUFF
    debuffs.STELLAR_FLARE = spells.STELLAR_FLARE_DEBUFF
    
    return true
end

-- Register variables to track
function Balance:RegisterVariables()
    -- Talent tracking
    talents.hasTwinMoons = false
    talents.hasSoulOfTheForest = false
    talents.hasStarlord = false
    talents.hasStellarDrift = false
    talents.hasNaturesBalance = false
    talents.hasShootingStars = false
    talents.hasBalanceOfAllThings = false
    talents.hasPrimordialArcanicPulsar = false
    talents.hasOrbitalStrike = false
    talents.hasUmbralIntensity = false
    talents.hasStarweaversWarp = false
    talents.hasStarweaversWeft = false
    talents.hasTouchOfTheCosmos = false
    talents.hasAstralCommunion = false
    talents.hasStellarInspiration = false
    talents.hasCelestialInfusion = false
    talents.hasImprovedStarfall = false
    talents.hasImprovedStarsurge = false
    talents.hasWildSurges = false
    talents.hasIncarnation = false
    talents.hasFuryOfElune = false
    talents.hasNewMoon = false
    talents.hasForceOfNature = false
    talents.hasStellarFlare = false
    talents.hasWarriorOfElune = false
    talents.hasSolstice = false
    
    -- Target state tracking
    self.targetData = {}
    
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
            useMoonkinForm = {
                displayName = "Use Moonkin Form",
                description = "Stay in Moonkin Form during combat",
                type = "toggle",
                default = true
            },
            maintainMoonfire = {
                displayName = "Maintain Moonfire",
                description = "Keep Moonfire active on targets",
                type = "toggle",
                default = true
            },
            maintainSunfire = {
                displayName = "Maintain Sunfire",
                description = "Keep Sunfire active on targets",
                type = "toggle",
                default = true
            },
            maintainStellarFlare = {
                displayName = "Maintain Stellar Flare",
                description = "Keep Stellar Flare active on targets",
                type = "toggle",
                default = true
            },
            starfallBehavior = {
                displayName = "Starfall Behavior",
                description = "When to cast Starfall over Starsurge",
                type = "dropdown",
                options = {"Never", "AoE Only", "Always with Stellar Drift", "Always in AoE"},
                default = "AoE Only"
            }
        },
        
        defensiveSettings = {
            useBarkskin = {
                displayName = "Use Barkskin",
                description = "Automatically use Barkskin",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useRenewal = {
                displayName = "Use Renewal",
                description = "Automatically use Renewal when talented",
                type = "toggle",
                default = true
            },
            renewalThreshold = {
                displayName = "Renewal Health Threshold",
                description = "Health percentage to use Renewal",
                type = "slider",
                min = 10,
                max = 60,
                default = 40
            },
            useBearForm = {
                displayName = "Use Bear Form",
                description = "Switch to Bear Form when critical",
                type = "toggle",
                default = true
            },
            bearFormThreshold = {
                displayName = "Bear Form Health Threshold",
                description = "Health percentage to switch to Bear Form",
                type = "slider",
                min = 10,
                max = 30,
                default = 20
            }
        },
        
        offensiveSettings = {
            useCelestialAlignment = {
                displayName = "Use Celestial Alignment",
                description = "Automatically use Celestial Alignment or Incarnation",
                type = "toggle",
                default = true
            },
            useFuryOfElune = {
                displayName = "Use Fury of Elune",
                description = "Automatically use Fury of Elune when talented",
                type = "toggle",
                default = true
            },
            useForceOfNature = {
                displayName = "Use Force of Nature",
                description = "Automatically use Force of Nature when talented",
                type = "toggle",
                default = true
            },
            useWarriorOfElune = {
                displayName = "Use Warrior of Elune",
                description = "Automatically use Warrior of Elune when talented",
                type = "toggle",
                default = true
            },
            useMoonSpells = {
                displayName = "Use Moon Spells",
                description = "Automatically use New/Half/Full Moon when talented",
                type = "toggle",
                default = true
            },
            useSolstice = {
                displayName = "Use Solstice",
                description = "Automatically use Solstice when talented",
                type = "toggle",
                default = true
            }
        },
        
        covenantSettings = {
            useRavenousFrenzy = {
                displayName = "Use Ravenous Frenzy",
                description = "Automatically use Ravenous Frenzy (Venthyr)",
                type = "toggle",
                default = true
            },
            useConvokeTheSpirits = {
                displayName = "Use Convoke the Spirits",
                description = "Automatically use Convoke the Spirits (Night Fae)",
                type = "toggle",
                default = true
            },
            useKindredSpirits = {
                displayName = "Use Kindred Spirits",
                description = "Automatically use Kindred Spirits (Kyrian)",
                type = "toggle",
                default = true
            },
            useEmpowerBond = {
                displayName = "Use Empower Bond",
                description = "Automatically use Empower Bond (Kyrian)",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            eclipseStrategy = {
                displayName = "Eclipse Strategy",
                description = "How to prioritize Eclipse states",
                type = "dropdown",
                options = {"Balance Both", "Prioritize Lunar", "Prioritize Solar", "Adaptive"},
                default = "Balance Both"
            },
            poolForStarsurge = {
                displayName = "Pool for Starsurge",
                description = "Save Astral Power for Starsurge",
                type = "toggle",
                default = true
            },
            astralPowerPoolThreshold = {
                displayName = "Astral Power Pool Threshold",
                description = "Astral Power to pool before using Starsurge",
                type = "slider",
                min = 30,
                max = 90,
                default = 50
            },
            dotRefreshThreshold = {
                displayName = "DoT Refresh Threshold",
                description = "Seconds remaining to refresh DoTs",
                type = "slider",
                min = 3,
                max = 8,
                default = 5
            },
            useStarlordStacks = {
                displayName = "Starlord Stack Behavior",
                description = "How to manage Starlord stacks",
                type = "dropdown",
                options = {"Maintain Max Stacks", "Ignore Stacks", "Build During Burst"},
                default = "Maintain Max Stacks"
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Celestial Alignment controls
            celestialAlignment = AAC.RegisterAbility(spells.CELESTIAL_ALIGNMENT, {
                enabled = true,
                useDuringBurstOnly = true,
                useWithEclipse = true
            }),
            
            -- Starfall controls
            starfall = AAC.RegisterAbility(spells.STARFALL, {
                enabled = true,
                minEnemies = DEFAULT_AOE_THRESHOLD,
                replaceStarsurge = true
            }),
            
            -- Fury of Elune controls
            furyOfElune = AAC.RegisterAbility(spells.FURY_OF_ELUNE, {
                enabled = true,
                useWithCelestialAlignment = true,
                minEnemies = 1
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
    
    -- Register for astral power updates
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
    
    -- Register for form change events
    API.RegisterEvent("UPDATE_SHAPESHIFT_FORM", function() 
        self:UpdateShapeshiftForm()
    end)
    
    -- Initial talent info update
    self:UpdateTalentInfo()
    
    -- Initial shapeshift form check
    self:UpdateShapeshiftForm()
    
    return true
end

-- Update talent information
function Balance:UpdateTalentInfo()
    -- Check for important talents
    talents.hasTwinMoons = API.HasTalent(spells.TWIN_MOONS)
    talents.hasSoulOfTheForest = API.HasTalent(spells.SOUL_OF_THE_FOREST)
    talents.hasStarlord = API.HasTalent(spells.STARLORD)
    talents.hasStellarDrift = API.HasTalent(spells.STELLAR_DRIFT)
    talents.hasNaturesBalance = API.HasTalent(spells.NATURES_BALANCE)
    talents.hasShootingStars = API.HasTalent(spells.SHOOTING_STARS)
    talents.hasBalanceOfAllThings = API.HasTalent(spells.BALANCE_OF_ALL_THINGS)
    talents.hasPrimordialArcanicPulsar = API.HasTalent(spells.PRIMORDIAL_ARCANIC_PULSAR)
    talents.hasOrbitalStrike = API.HasTalent(spells.ORBITAL_STRIKE)
    talents.hasUmbralIntensity = API.HasTalent(spells.UMBRAL_INTENSITY)
    talents.hasStarweaversWarp = API.HasTalent(spells.STARWEAVERS_WARP)
    talents.hasStarweaversWeft = API.HasTalent(spells.STARWEAVERS_WEFT)
    talents.hasTouchOfTheCosmos = API.HasTalent(spells.TOUCH_OF_THE_COSMOS)
    talents.hasAstralCommunion = API.HasTalent(spells.ASTRAL_COMMUNION)
    talents.hasStellarInspiration = API.HasTalent(spells.STELLAR_INSPIRATION)
    talents.hasCelestialInfusion = API.HasTalent(spells.CELESTIAL_INFUSION)
    talents.hasImprovedStarfall = API.HasTalent(spells.IMPROVED_STARFALL)
    talents.hasImprovedStarsurge = API.HasTalent(spells.IMPROVED_STARSURGE)
    talents.hasWildSurges = API.HasTalent(spells.WILD_SURGES)
    talents.hasIncarnation = API.HasTalent(spells.INCARNATION_CHOSEN_OF_ELUNE)
    talents.hasFuryOfElune = API.HasTalent(spells.FURY_OF_ELUNE)
    talents.hasNewMoon = API.HasTalent(spells.NEW_MOON)
    talents.hasForceOfNature = API.HasTalent(spells.FORCE_OF_NATURE)
    talents.hasStellarFlare = API.HasTalent(spells.STELLAR_FLARE)
    talents.hasWarriorOfElune = API.HasTalent(spells.WARRIOR_OF_ELUNE)
    talents.hasSolstice = API.HasTalent(spells.SOLSTICE)
    
    API.PrintDebug("Balance Druid talents updated")
    
    return true
end

-- Update astral power tracking
function Balance:UpdateAstralPower()
    currentAstralPower = API.GetPlayerPower()
    return true
end

-- Update shapeshift form tracking
function Balance:UpdateShapeshiftForm()
    moonkinForm = API.PlayerHasBuff(buffs.MOONKIN_FORM)
    return true
end

-- Update eclipse counters
function Balance:UpdateEclipseCounters(spell)
    -- Skip if we're in any Eclipse state or Celestial Alignment/Incarnation
    if eclipseState ~= "NONE" or celestialAlignmentActive or incarnationActive then
        return
    end
    
    if spell == spells.WRATH then
        solarEclipseCounter = solarEclipseCounter + 1
        
        -- Check if we've reached the threshold for Lunar Eclipse
        if solarEclipseCounter >= SOLAR_ECLIPSE_WRATH_COUNT then
            eclipseState = "LUNAR"
            eclipseTimeRemaining = ECLIPSE_DURATION
            solarEclipseCounter = 0
            lunarEclipseCounter = 0
            
            API.PrintDebug("Entered Lunar Eclipse")
        end
    elseif spell == spells.STARFIRE then
        lunarEclipseCounter = lunarEclipseCounter + 1
        
        -- Check if we've reached the threshold for Solar Eclipse
        if lunarEclipseCounter >= LUNAR_ECLIPSE_STARFIRE_COUNT then
            eclipseState = "SOLAR"
            eclipseTimeRemaining = ECLIPSE_DURATION
            solarEclipseCounter = 0
            lunarEclipseCounter = 0
            
            API.PrintDebug("Entered Solar Eclipse")
        end
    end
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
        
        -- Check for Moonfire
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.MOONFIRE)
        if name then
            self.targetData[targetGUID].moonfire = true
            self.targetData[targetGUID].moonfireExpiration = expiration
            moonfireActive = true
            moonfireExpiration = expiration
        else
            self.targetData[targetGUID].moonfire = false
            self.targetData[targetGUID].moonfireExpiration = 0
            moonfireActive = false
            moonfireExpiration = 0
        end
        
        -- Check for Sunfire
        local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.SUNFIRE)
        if name then
            self.targetData[targetGUID].sunfire = true
            self.targetData[targetGUID].sunfireExpiration = expiration
            sunfireActive = true
            sunfireExpiration = expiration
        else
            self.targetData[targetGUID].sunfire = false
            self.targetData[targetGUID].sunfireExpiration = 0
            sunfireActive = false
            sunfireExpiration = 0
        end
        
        -- Check for Stellar Flare
        if talents.hasStellarFlare then
            local name, _, _, _, _, expiration = API.GetDebuffInfo(targetGUID, debuffs.STELLAR_FLARE)
            if name then
                self.targetData[targetGUID].stellarFlare = true
                self.targetData[targetGUID].stellarFlareExpiration = expiration
                stellarFlareActive = true
                stellarFlareExpiration = expiration
            else
                self.targetData[targetGUID].stellarFlare = false
                self.targetData[targetGUID].stellarFlareExpiration = 0
                stellarFlareActive = false
                stellarFlareExpiration = 0
            end
        end
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(40) -- Balance Druid has long range AoE
    
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
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Eclipse states
            if spellID == buffs.ECLIPSE_SOLAR then
                eclipseState = "SOLAR"
                eclipseTimeRemaining = ECLIPSE_DURATION
                API.PrintDebug("Solar Eclipse activated")
            elseif spellID == buffs.ECLIPSE_LUNAR then
                eclipseState = "LUNAR"
                eclipseTimeRemaining = ECLIPSE_DURATION
                API.PrintDebug("Lunar Eclipse activated")
            end
            
            -- Track Celestial Alignment
            if spellID == buffs.CELESTIAL_ALIGNMENT then
                celestialAlignmentActive = true
                celestialAlignmentTimeRemaining = CELESTIAL_ALIGNMENT_DURATION
                eclipseState = "BOTH" -- Both eclipses active during CA
                API.PrintDebug("Celestial Alignment activated")
            end
            
            -- Track Incarnation
            if spellID == buffs.INCARNATION then
                incarnationActive = true
                incarnationTimeRemaining = INCARNATION_DURATION
                eclipseState = "BOTH" -- Both eclipses active during Incarnation
                API.PrintDebug("Incarnation activated")
            end
            
            -- Track Starlord
            if spellID == buffs.STARLORD then
                starlordStacks = select(4, API.GetBuffInfo("player", buffs.STARLORD)) or 0
                starlordTimeRemaining = STARLORD_DURATION
                API.PrintDebug("Starlord stacks: " .. tostring(starlordStacks))
            end
            
            -- Track Oneth's Clear Vision (Legendary proc)
            if spellID == buffs.ONETHS_CLEAR_VISION then
                onethsActive = true
                onethsTimeRemaining = select(6, API.GetBuffInfo("player", buffs.ONETHS_CLEAR_VISION)) - GetTime()
                API.PrintDebug("Oneth's Clear Vision activated")
            end
            
            -- Track Warrior of Elune
            if spellID == buffs.WARRIOR_OF_ELUNE then
                API.PrintDebug("Warrior of Elune activated")
            end
            
            -- Track Starweaver buff
            if spellID == buffs.STARWEAVER then
                if talents.hasStarweaversWarp then
                    starweaversWarp = true
                    API.PrintDebug("Starweaver's Warp activated")
                end
                
                if talents.hasStarweaversWeft then
                    starweaversWeft = true
                    API.PrintDebug("Starweaver's Weft activated")
                end
            end
            
            -- Track Touch of the Cosmos
            if spellID == buffs.TOUCH_OF_THE_COSMOS then
                touchOfEclipse = true
                API.PrintDebug("Touch of the Cosmos activated")
            end
            
            -- Track Ravenous Frenzy
            if spellID == buffs.RAVENOUS_FRENZY then
                ravenousFrenzy = true
                API.PrintDebug("Ravenous Frenzy activated")
            end
            
            -- Track Moonkin Form
            if spellID == buffs.MOONKIN_FORM then
                moonkinForm = true
                API.PrintDebug("Moonkin Form activated")
            end
            
            -- Track Kindred Empowerment
            if spellID == buffs.KINDRED_EMPOWERMENT then
                kindredSpiritsActive = true
                API.PrintDebug("Kindred Empowerment activated")
            end
            
            -- Track Balance of All Things
            if spellID == buffs.BALANCE_OF_ALL_THINGS_ARCANE then
                balanceOfAllThingsLunar = select(4, API.GetBuffInfo("player", buffs.BALANCE_OF_ALL_THINGS_ARCANE)) or 0
                API.PrintDebug("Balance of All Things (Lunar) stacks: " .. tostring(balanceOfAllThingsLunar))
            elseif spellID == buffs.BALANCE_OF_ALL_THINGS_NATURE then
                balanceOfAllThingsSolar = select(4, API.GetBuffInfo("player", buffs.BALANCE_OF_ALL_THINGS_NATURE)) or 0
                API.PrintDebug("Balance of All Things (Solar) stacks: " .. tostring(balanceOfAllThingsSolar))
            end
            
            -- Track Starfall
            if spellID == buffs.STARFALL then
                starfallActive = true
                starfallTimeRemaining = STARFALL_DURATION
                API.PrintDebug("Starfall activated")
            end
            
            -- Track Solstice
            if spellID == buffs.SOLSTICE then
                solsticeActive = true
                API.PrintDebug("Solstice activated")
            end
        end
        
        -- Track target debuffs
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Update target data for debuffs
            self:UpdateTargetData()
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Eclipse states
            if spellID == buffs.ECLIPSE_SOLAR or spellID == buffs.ECLIPSE_LUNAR then
                if not celestialAlignmentActive and not incarnationActive then
                    eclipseState = "NONE"
                    eclipseTimeRemaining = 0
                    API.PrintDebug("Eclipse faded")
                end
            end
            
            -- Track Celestial Alignment
            if spellID == buffs.CELESTIAL_ALIGNMENT then
                celestialAlignmentActive = false
                celestialAlignmentTimeRemaining = 0
                
                -- Check if we should also reset Eclipse state
                if not incarnationActive then
                    eclipseState = "NONE"
                end
                
                API.PrintDebug("Celestial Alignment faded")
            end
            
            -- Track Incarnation
            if spellID == buffs.INCARNATION then
                incarnationActive = false
                incarnationTimeRemaining = 0
                
                -- Check if we should also reset Eclipse state
                if not celestialAlignmentActive then
                    eclipseState = "NONE"
                end
                
                API.PrintDebug("Incarnation faded")
            end
            
            -- Track Starlord
            if spellID == buffs.STARLORD then
                starlordStacks = 0
                starlordTimeRemaining = 0
                API.PrintDebug("Starlord faded")
            end
            
            -- Track Oneth's Clear Vision
            if spellID == buffs.ONETHS_CLEAR_VISION then
                onethsActive = false
                onethsTimeRemaining = 0
                API.PrintDebug("Oneth's Clear Vision faded")
            end
            
            -- Track Starweaver buff
            if spellID == buffs.STARWEAVER then
                starweaversWarp = false
                starweaversWeft = false
                API.PrintDebug("Starweaver's effects faded")
            end
            
            -- Track Touch of the Cosmos
            if spellID == buffs.TOUCH_OF_THE_COSMOS then
                touchOfEclipse = false
                API.PrintDebug("Touch of the Cosmos faded")
            end
            
            -- Track Ravenous Frenzy
            if spellID == buffs.RAVENOUS_FRENZY then
                ravenousFrenzy = false
                API.PrintDebug("Ravenous Frenzy faded")
            end
            
            -- Track Moonkin Form
            if spellID == buffs.MOONKIN_FORM then
                moonkinForm = false
                API.PrintDebug("Moonkin Form faded")
            end
            
            -- Track Kindred Empowerment
            if spellID == buffs.KINDRED_EMPOWERMENT then
                kindredSpiritsActive = false
                API.PrintDebug("Kindred Empowerment faded")
            end
            
            -- Track Balance of All Things
            if spellID == buffs.BALANCE_OF_ALL_THINGS_ARCANE then
                balanceOfAllThingsLunar = 0
                API.PrintDebug("Balance of All Things (Lunar) faded")
            elseif spellID == buffs.BALANCE_OF_ALL_THINGS_NATURE then
                balanceOfAllThingsSolar = 0
                API.PrintDebug("Balance of All Things (Solar) faded")
            end
            
            -- Track Starfall
            if spellID == buffs.STARFALL then
                starfallActive = false
                starfallTimeRemaining = 0
                API.PrintDebug("Starfall faded")
            end
            
            -- Track Solstice
            if spellID == buffs.SOLSTICE then
                solsticeActive = false
                API.PrintDebug("Solstice faded")
            end
        end
        
        -- Track target debuffs
        local targetGUID = API.GetTargetGUID()
        if destGUID == targetGUID then
            -- Update target data for debuffs
            self:UpdateTargetData()
        end
    end
    
    -- Track Starlord stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == buffs.STARLORD and destGUID == API.GetPlayerGUID() then
        starlordStacks = select(4, API.GetBuffInfo("player", buffs.STARLORD)) or 0
        starlordTimeRemaining = STARLORD_DURATION
        API.PrintDebug("Starlord stacks: " .. tostring(starlordStacks))
    end
    
    -- Track spell casts to update Eclipse
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        if spellID == spells.WRATH or spellID == spells.STARFIRE then
            self:UpdateEclipseCounters(spellID)
        end
        
        -- Track important cooldowns
        if spellID == spells.CELESTIAL_ALIGNMENT then
            API.PrintDebug("Celestial Alignment used")
        elseif spellID == spells.INCARNATION_CHOSEN_OF_ELUNE then
            API.PrintDebug("Incarnation used")
        elseif spellID == spells.STARFALL then
            API.PrintDebug("Starfall cast")
        elseif spellID == spells.STARSURGE then
            API.PrintDebug("Starsurge cast")
        elseif spellID == spells.WARRIOR_OF_ELUNE then
            API.PrintDebug("Warrior of Elune used")
        elseif spellID == spells.FURY_OF_ELUNE then
            furyOfElune = true
            
            -- Set a timer to track when it ends
            C_Timer.After(8, function() -- Fury of Elune lasts 8 seconds
                furyOfElune = false
                API.PrintDebug("Fury of Elune ended")
            end)
            
            API.PrintDebug("Fury of Elune used")
        elseif spellID == spells.FORCE_OF_NATURE then
            API.PrintDebug("Force of Nature used")
        elseif spellID == spells.CONVOKE_THE_SPIRITS then
            API.PrintDebug("Convoke the Spirits used")
        end
    end
    
    -- Track Balance of All Things stack applications
    if eventType == "SPELL_AURA_APPLIED_DOSE" then
        if spellID == buffs.BALANCE_OF_ALL_THINGS_ARCANE and destGUID == API.GetPlayerGUID() then
            balanceOfAllThingsLunar = select(4, API.GetBuffInfo("player", buffs.BALANCE_OF_ALL_THINGS_ARCANE)) or 0
            API.PrintDebug("Balance of All Things (Lunar) stacks: " .. tostring(balanceOfAllThingsLunar))
        elseif spellID == buffs.BALANCE_OF_ALL_THINGS_NATURE and destGUID == API.GetPlayerGUID() then
            balanceOfAllThingsSolar = select(4, API.GetBuffInfo("player", buffs.BALANCE_OF_ALL_THINGS_NATURE)) or 0
            API.PrintDebug("Balance of All Things (Solar) stacks: " .. tostring(balanceOfAllThingsSolar))
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
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("BalanceDruid")
    
    -- Update variables
    self:UpdateAstralPower()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Enter Moonkin Form if not already in it
    if settings.rotationSettings.useMoonkinForm and not moonkinForm and API.CanCast(spells.MOONKIN_FORM) then
        API.CastSpell(spells.MOONKIN_FORM)
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
    
    -- Handle DoT maintenance
    if self:HandleDoTMaintenance(settings) then
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
function Balance:HandleInterrupts()
    -- Use Solar Beam for interrupt
    if API.CanCast(spells.SOLAR_BEAM) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.SOLAR_BEAM)
        return true
    end
    
    return false
end

-- Handle defensive abilities
function Balance:HandleDefensives(settings)
    local playerHealth = API.GetPlayerHealthPercent()
    
    -- Use Barkskin
    if settings.defensiveSettings.useBarkskin and
       playerHealth <= settings.defensiveSettings.barkskinThreshold and
       API.CanCast(spells.BARKSKIN) then
        API.CastSpell(spells.BARKSKIN)
        return true
    end
    
    -- Use Renewal if talented
    if talents.hasRenewal and
       settings.defensiveSettings.useRenewal and
       playerHealth <= settings.defensiveSettings.renewalThreshold and
       API.CanCast(spells.RENEWAL) then
        API.CastSpell(spells.RENEWAL)
        return true
    end
    
    -- Use Bear Form when critically low
    if settings.defensiveSettings.useBearForm and
       playerHealth <= settings.defensiveSettings.bearFormThreshold and
       API.CanCast(spells.BEAR_FORM) then
        API.CastSpell(spells.BEAR_FORM)
        return true
    end
    
    return false
end

-- Handle DoT maintenance
function Balance:HandleDoTMaintenance(settings)
    -- Apply/refresh Moonfire
    if settings.rotationSettings.maintainMoonfire and API.CanCast(spells.MOONFIRE) then
        if not moonfireActive or (moonfireExpiration - GetTime() < settings.advancedSettings.dotRefreshThreshold) then
            API.CastSpell(spells.MOONFIRE)
            return true
        end
    end
    
    -- Apply/refresh Sunfire
    if settings.rotationSettings.maintainSunfire and API.CanCast(spells.SUNFIRE) then
        if not sunfireActive or (sunfireExpiration - GetTime() < settings.advancedSettings.dotRefreshThreshold) then
            API.CastSpell(spells.SUNFIRE)
            return true
        end
    end
    
    -- Apply/refresh Stellar Flare if talented
    if talents.hasStellarFlare and
       settings.rotationSettings.maintainStellarFlare and
       API.CanCast(spells.STELLAR_FLARE) then
        if not stellarFlareActive or (stellarFlareExpiration - GetTime() < settings.advancedSettings.dotRefreshThreshold) then
            API.CastSpell(spells.STELLAR_FLARE)
            return true
        end
    end
    
    return false
end

-- Handle cooldown abilities
function Balance:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode
    if not burstModeActive then
        return false
    end
    
    -- Use Celestial Alignment / Incarnation
    if settings.offensiveSettings.useCelestialAlignment and
       settings.abilityControls.celestialAlignment.enabled and
       not celestialAlignmentActive and not incarnationActive and
       eclipseState ~= "NONE" then
        
        if talents.hasIncarnation and API.CanCast(spells.INCARNATION_CHOSEN_OF_ELUNE) then
            API.CastSpell(spells.INCARNATION_CHOSEN_OF_ELUNE)
            return true
        elseif API.CanCast(spells.CELESTIAL_ALIGNMENT) then
            API.CastSpell(spells.CELESTIAL_ALIGNMENT)
            return true
        end
    end
    
    -- Use Warrior of Elune
    if talents.hasWarriorOfElune and
       settings.offensiveSettings.useWarriorOfElune and
       API.CanCast(spells.WARRIOR_OF_ELUNE) then
        API.CastSpell(spells.WARRIOR_OF_ELUNE)
        return true
    end
    
    -- Use Force of Nature
    if talents.hasForceOfNature and
       settings.offensiveSettings.useForceOfNature and
       API.CanCast(spells.FORCE_OF_NATURE) then
        API.CastSpell(spells.FORCE_OF_NATURE)
        return true
    end
    
    -- Use Fury of Elune
    if talents.hasFuryOfElune and
       settings.offensiveSettings.useFuryOfElune and
       settings.abilityControls.furyOfElune.enabled and
       API.CanCast(spells.FURY_OF_ELUNE) then
        
        -- Check if we want to use with Celestial Alignment
        if not settings.abilityControls.furyOfElune.useWithCelestialAlignment or 
           celestialAlignmentActive or incarnationActive then
            API.CastSpellAtCursor(spells.FURY_OF_ELUNE)
            return true
        end
    end
    
    -- Use Solstice
    if talents.hasSolstice and
       settings.offensiveSettings.useSolstice and
       not solsticeActive and
       API.CanCast(spells.SOLSTICE) then
        API.CastSpell(spells.SOLSTICE)
        return true
    end
    
    -- Use Covenant abilities
    if self:HandleCovenantAbilities(settings) then
        return true
    end
    
    return false
end

-- Handle covenant abilities
function Balance:HandleCovenantAbilities(settings)
    -- Use Ravenous Frenzy (Venthyr)
    if settings.covenantSettings.useRavenousFrenzy and
       API.CanCast(spells.RAVENOUS_FRENZY) then
        API.CastSpell(spells.RAVENOUS_FRENZY)
        return true
    end
    
    -- Use Convoke the Spirits (Night Fae)
    if settings.covenantSettings.useConvokeTheSpirits and
       API.CanCast(spells.CONVOKE_THE_SPIRITS) then
        -- Best used during Eclipse/Celestial Alignment
        if eclipseState ~= "NONE" or celestialAlignmentActive or incarnationActive then
            API.CastSpell(spells.CONVOKE_THE_SPIRITS)
            return true
        end
    end
    
    -- Use Kindred Spirits (Kyrian)
    if settings.covenantSettings.useKindredSpirits and
       API.CanCast(spells.KINDRED_SPIRITS) then
        API.CastSpell(spells.KINDRED_SPIRITS)
        return true
    end
    
    -- Use Empower Bond (Kyrian)
    if settings.covenantSettings.useEmpowerBond and
       API.CanCast(spells.EMPOWER_BOND) then
        API.CastSpell(spells.EMPOWER_BOND)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Balance:HandleAoERotation(settings)
    -- Handle Starfall
    local shouldUseStarfall = false
    
    if settings.rotationSettings.starfallBehavior == "AoE Only" then
        shouldUseStarfall = true
    elseif settings.rotationSettings.starfallBehavior == "Always with Stellar Drift" and talents.hasStellarDrift then
        shouldUseStarfall = true
    elseif settings.rotationSettings.starfallBehavior == "Always in AoE" then
        shouldUseStarfall = true
    end
    
    -- Cast Starfall if conditions are met and not already active
    if shouldUseStarfall and
       not starfallActive and
       currentAstralPower >= 50 and
       API.CanCast(spells.STARFALL) then
        API.CastSpellAtCursor(spells.STARFALL)
        return true
    end
    
    -- Use New Moon / Half Moon / Full Moon if talented
    if talents.hasNewMoon and
       settings.offensiveSettings.useMoonSpells and
       API.CanCast(spells.NEW_MOON) then
        API.CastSpellAtCursor(spells.NEW_MOON)
        return true
    elseif talents.hasNewMoon and
           settings.offensiveSettings.useMoonSpells and
           API.CanCast(spells.HALF_MOON) then
        API.CastSpellAtCursor(spells.HALF_MOON)
        return true
    elseif talents.hasNewMoon and
           settings.offensiveSettings.useMoonSpells and
           API.CanCast(spells.FULL_MOON) then
        API.CastSpellAtCursor(spells.FULL_MOON)
        return true
    end
    
    -- Use Starsurge if we have Oneth's Clear Vision proc
    if onethsActive and API.CanCast(spells.STARSURGE) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    -- Use Starfire in Lunar Eclipse or Celestial Alignment/Incarnation
    if (eclipseState == "LUNAR" or eclipseState == "BOTH") and API.CanCast(spells.STARFIRE) then
        API.CastSpell(spells.STARFIRE)
        return true
    end
    
    -- Use Wrath in Solar Eclipse
    if eclipseState == "SOLAR" and API.CanCast(spells.WRATH) then
        API.CastSpell(spells.WRATH)
        return true
    end
    
    -- If no Eclipse is active, cast Wrath to work toward Lunar Eclipse
    if eclipseState == "NONE" and API.CanCast(spells.WRATH) then
        API.CastSpell(spells.WRATH)
        return true
    end
    
    -- Use Starsurge as a filler
    if currentAstralPower >= 40 and API.CanCast(spells.STARSURGE) then
        API.CastSpell(spells.STARSURGE)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Balance:HandleSingleTargetRotation(settings)
    -- Use Starsurge to spend Astral Power
    if (currentAstralPower >= settings.advancedSettings.astralPowerPoolThreshold or currentAstralPower >= 90) and
       API.CanCast(spells.STARSURGE) then
        
        -- Check Starlord management if talented
        if talents.hasStarlord and settings.advancedSettings.useStarlordStacks == "Maintain Max Stacks" then
            -- If stacks are about to fall off, or we're not at max stacks, use Starsurge
            if starlordTimeRemaining < 3 or starlordStacks < 3 then
                API.CastSpell(spells.STARSURGE)
                return true
            end
        else
            -- No Starlord, or we're ignoring stack management
            API.CastSpell(spells.STARSURGE)
            return true
        end
    end
    
    -- Use New Moon / Half Moon / Full Moon if talented
    if talents.hasNewMoon and
       settings.offensiveSettings.useMoonSpells and
       API.CanCast(spells.NEW_MOON) then
        API.CastSpell(spells.NEW_MOON)
        return true
    elseif talents.hasNewMoon and
           settings.offensiveSettings.useMoonSpells and
           API.CanCast(spells.HALF_MOON) then
        API.CastSpell(spells.HALF_MOON)
        return true
    elseif talents.hasNewMoon and
           settings.offensiveSettings.useMoonSpells and
           API.CanCast(spells.FULL_MOON) then
        API.CastSpell(spells.FULL_MOON)
        return true
    end
    
    -- Use Starfire in Lunar Eclipse or Celestial Alignment/Incarnation
    if (eclipseState == "LUNAR" or eclipseState == "BOTH") and API.CanCast(spells.STARFIRE) then
        API.CastSpell(spells.STARFIRE)
        return true
    end
    
    -- Use Wrath in Solar Eclipse
    if eclipseState == "SOLAR" and API.CanCast(spells.WRATH) then
        API.CastSpell(spells.WRATH)
        return true
    end
    
    -- If no Eclipse is active, use spells to trigger Eclipse based on strategy
    if eclipseState == "NONE" then
        if settings.advancedSettings.eclipseStrategy == "Prioritize Lunar" then
            -- Cast Wrath to get Lunar Eclipse
            if API.CanCast(spells.WRATH) then
                API.CastSpell(spells.WRATH)
                return true
            end
        elseif settings.advancedSettings.eclipseStrategy == "Prioritize Solar" then
            -- Cast Starfire to get Solar Eclipse
            if API.CanCast(spells.STARFIRE) then
                API.CastSpell(spells.STARFIRE)
                return true
            end
        elseif settings.advancedSettings.eclipseStrategy == "Adaptive" then
            -- Choose based on encounter (single target = Lunar, multi-target = Solar)
            if currentAoETargets > 1 then
                if API.CanCast(spells.STARFIRE) then
                    API.CastSpell(spells.STARFIRE)
                    return true
                end
            else
                if API.CanCast(spells.WRATH) then
                    API.CastSpell(spells.WRATH)
                    return true
                end
            end
        else -- Balance Both
            -- Alternate between both Eclipses
            if solarEclipseCounter < SOLAR_ECLIPSE_WRATH_COUNT and API.CanCast(spells.WRATH) then
                API.CastSpell(spells.WRATH)
                return true
            elseif API.CanCast(spells.STARFIRE) then
                API.CastSpell(spells.STARFIRE)
                return true
            end
        end
    end
    
    -- Default to Wrath if nothing else to cast
    if API.CanCast(spells.WRATH) then
        API.CastSpell(spells.WRATH)
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
    currentAstralPower = API.GetPlayerPower()
    maxAstralPower = 100
    eclipseState = "NONE"
    eclipseTimeRemaining = 0
    sunfireActive = false
    sunfireExpiration = 0
    moonfireActive = false
    moonfireExpiration = 0
    stellarFlareActive = false
    stellarFlareExpiration = 0
    starfallActive = false
    starfallTimeRemaining = 0
    starsurgeStacks = 0
    onethsActive = false
    onethsTimeRemaining = 0
    celestialAlignmentActive = false
    celestialAlignmentTimeRemaining = 0
    incarnationActive = false
    incarnationTimeRemaining = 0
    starlordStacks = 0
    starlordTimeRemaining = 0
    lunarEclipseCounter = 0
    solarEclipseCounter = 0
    furyOfElune = false
    orbitalStrike = false
    umbralIntensity = 0
    primordialArcanicPulsar = 0
    starweaversWarp = false
    starweaversWeft = false
    touchOfEclipse = false
    ravenousFrenzy = false
    moonkinForm = API.PlayerHasBuff(buffs.MOONKIN_FORM)
    kindredSpiritsActive = false
    fallenOrderActive = false
    boatActive = false
    surgeActive = false
    wildSurge = false
    solsticeActive = false
    balanceOfAllThingsLunar = 0
    balanceOfAllThingsSolar = 0
    
    API.PrintDebug("Balance Druid state reset on spec change")
    
    return true
end

-- Return the module for loading
return Balance