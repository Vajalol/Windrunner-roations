------------------------------------------
-- WindrunnerRotations - Protection Paladin Module
-- Author: VortexQ8
------------------------------------------

local Protection = {}
-- This will be assigned to addon.Classes.Paladin.Protection when loaded

-- These will be set when the file is loaded in our test environment
local API
local ConfigRegistry
local AAC
local Paladin

-- Cache frequently accessed data
local spells = {}
local talents = {}
local buffs = {}
local debuffs = {}

-- State tracking variables
local nextCastOverride = nil
local burstModeActive = false
local currentAoETargets = 0
local currentHolyPower = 0
local maxHolyPower = 5
local shieldOfRighteousBuff = false
local shieldOfRighteousCharges = 0
local avengingWrathActive = false
local hammerOfWrathAvailable = false
local lastWordTargets = {}
local consecrationActive = false
local consecrationTimeRemaining = 0
local divineTollAvailable = true
local lastShieldOfRighteous = 0
local shiningLightStacks = 0
local bulwarkOfRighteousGlory = false -- Sentinel legendary
local ardentDefenderActive = false
local guardianOfAncientKingsActive = false
local divineProtectionActive = false
local eyeOfTyrActive = false
local divinePurposeBuff = false
local momentOfGloryBuff = false
local sentenceActive = false -- Final Sentence debuff from Execution Sentence
local battleAvengersHand = 0 -- Charges for Hand of Reckoning from talented
local bastion = false -- Bastion of Light

-- Constants
local PROTECTION_SPEC_ID = 66
local DEFAULT_AOE_THRESHOLD = 3
local EXECUTE_THRESHOLD = 20 -- Health percent to enable Hammer of Wrath
local CONSECRATION_DURATION = 12
local SOR_DURATION = 4.5

-- Initialize the Protection module
function Protection:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Protection Paladin module initialized")
    
    return true
end

-- Register spell IDs
function Protection:RegisterSpells()
    -- Core abilities
    spells.SHIELD_OF_THE_RIGHTEOUS = 53600
    spells.AVENGERS_SHIELD = 31935
    spells.JUDGMENT = 275779
    spells.HAMMER_OF_THE_RIGHTEOUS = 53595
    spells.BLESSED_HAMMER = 204019
    spells.CONSECRATION = 26573
    spells.HAMMER_OF_WRATH = 24275
    spells.WORD_OF_GLORY = 85673
    spells.DIVINE_TOLL = 375576
    spells.HOLY_SHIELD = 152261
    spells.HAND_OF_RECKONING = 62124
    
    -- Defensive cooldowns
    spells.GUARDIAN_OF_ANCIENT_KINGS = 86659
    spells.ARDENT_DEFENDER = 31850
    spells.DIVINE_SHIELD = 642
    spells.LAY_ON_HANDS = 633
    spells.BLESSING_OF_PROTECTION = 1022
    spells.BLESSING_OF_SACRIFICE = 6940
    spells.BLESSING_OF_FREEDOM = 1044
    spells.DIVINE_STEED = 190784
    spells.DIVINE_PROTECTION = 498
    spells.EYE_OF_TYR = 387174
    
    -- Offensive cooldowns
    spells.AVENGING_WRATH = 31884
    spells.MOMENT_OF_GLORY = 327193
    spells.SERAPHIM = 152262
    spells.SENTINEL = 389539 -- Sentinel talent
    spells.EXECUTION_SENTENCE = 343527
    spells.FINAL_SENTENCE = 383328 -- Debuff from Execution Sentence
    
    -- Utility
    spells.REBUKE = 96231
    spells.CLEANSE_TOXINS = 213644
    spells.FLASH_OF_LIGHT = 19750
    spells.BASTION_OF_LIGHT = 378974
    
    -- Talent and legendary effects
    spells.RIGHTEOUS_PROTECTOR = 204074
    spells.REDOUBT = 280373
    spells.CRUSADERS_JUDGMENT = 204023
    spells.FIRST_AVENGER = 203776
    spells.BULWARK_OF_RIGHTEOUS_FURY = 337681 -- Legendary effect
    spells.THE_MAGISTRATES_JUDGMENT = 337682 -- Legendary effect
    spells.SHINING_LIGHT = 327510
    spells.DIVINE_PURPOSE = 223817
    spells.HOLY_AVENGER = 105809
    spells.FINAL_STAND = 204077
    spells.BLESSING_OF_SPELLWARDING = 204018
    spells.LAST_DEFENDER = 203791
    
    -- Buffs and procs
    spells.SHIELD_OF_THE_RIGHTEOUS_BUFF = 132403
    spells.AVENGING_WRATH_BUFF = 31884
    spells.ARDENT_DEFENDER_BUFF = 31850
    spells.GUARDIAN_OF_ANCIENT_KINGS_BUFF = 86659
    spells.DIVINE_PURPOSE_BUFF = 223819
    spells.MOMENT_OF_GLORY_BUFF = 327193
    spells.SHINING_LIGHT_BUFF = 327510
    spells.BULWARK_OF_RIGHTEOUS_GLORY = 337848 -- Sentinel legendary buff
    spells.DIVINE_PROTECTION_BUFF = 498
    spells.EYE_OF_TYR_DEBUFF = 209202
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.SHIELD_OF_THE_RIGHTEOUS = spells.SHIELD_OF_THE_RIGHTEOUS_BUFF
    buffs.AVENGING_WRATH = spells.AVENGING_WRATH_BUFF
    buffs.ARDENT_DEFENDER = spells.ARDENT_DEFENDER_BUFF
    buffs.GUARDIAN_OF_ANCIENT_KINGS = spells.GUARDIAN_OF_ANCIENT_KINGS_BUFF
    buffs.DIVINE_PURPOSE = spells.DIVINE_PURPOSE_BUFF
    buffs.MOMENT_OF_GLORY = spells.MOMENT_OF_GLORY_BUFF
    buffs.SHINING_LIGHT = spells.SHINING_LIGHT_BUFF
    buffs.BULWARK_OF_RIGHTEOUS_GLORY = spells.BULWARK_OF_RIGHTEOUS_GLORY
    buffs.DIVINE_PROTECTION = spells.DIVINE_PROTECTION_BUFF
    
    debuffs.EYE_OF_TYR = spells.EYE_OF_TYR_DEBUFF
    debuffs.FINAL_SENTENCE = spells.FINAL_SENTENCE
    
    return true
end

-- Register variables to track
function Protection:RegisterVariables()
    -- Talent tracking
    talents.hasBlessedHammer = false
    talents.hasHolyShield = false
    talents.hasRighteousProtector = false
    talents.hasRedoubt = false
    talents.hasCrusadersJudgment = false
    talents.hasFirstAvenger = false
    talents.hasDivinePurpose = false
    talents.hasSeraphim = false
    talents.hasHolyAvenger = false
    talents.hasFinalStand = false
    talents.hasBlessingOfSpellwarding = false
    talents.hasLastDefender = false
    talents.hasMomentOfGlory = false
    talents.hasEyeOfTyr = false
    talents.hasDivineToll = false
    talents.hasExecutionSentence = false
    talents.hasRighteousFury = false -- Talent for extra SotR efficacy
    talents.hasBastion = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Protection:RegisterSettings()
    ConfigRegistry:RegisterSettings("ProtectionPaladin", {
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
            useTaunt = {
                displayName = "Use Taunt",
                description = "Automatically taunt when losing threat",
                type = "toggle",
                default = true
            },
            sotrMode = {
                displayName = "Shield of the Righteous Mode",
                description = "How to use Shield of the Righteous",
                type = "dropdown",
                options = {"Defensive Priority", "Maximum Uptime", "Holy Power Dump"},
                default = "Defensive Priority"
            },
            wordOfGloryThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory (0 to disable)",
                type = "slider",
                min = 0,
                max = 100,
                default = 65
            },
            shiningLightPriority = {
                displayName = "Prioritize Shining Light",
                description = "Prioritize using Word of Glory with Shining Light stacks",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            useArdentDefender = {
                displayName = "Use Ardent Defender",
                description = "Automatically use Ardent Defender",
                type = "toggle",
                default = true
            },
            ardentDefenderThreshold = {
                displayName = "Ardent Defender Threshold",
                description = "Health percentage to use Ardent Defender",
                type = "slider",
                min = 10,
                max = 60,
                default = 30
            },
            useGuardianOfAncientKings = {
                displayName = "Use Guardian of Ancient Kings",
                description = "Automatically use Guardian of Ancient Kings",
                type = "toggle",
                default = true
            },
            guardianOfAncientKingsThreshold = {
                displayName = "Guardian of Ancient Kings Threshold",
                description = "Health percentage to use Guardian of Ancient Kings",
                type = "slider",
                min = 10,
                max = 50,
                default = 25
            },
            useDivineProtection = {
                displayName = "Use Divine Protection",
                description = "Automatically use Divine Protection",
                type = "toggle",
                default = true
            },
            divineProtectionThreshold = {
                displayName = "Divine Protection Threshold",
                description = "Health percentage to use Divine Protection",
                type = "slider",
                min = 20,
                max = 80,
                default = 60
            },
            useEyeOfTyr = {
                displayName = "Use Eye of Tyr",
                description = "Automatically use Eye of Tyr",
                type = "toggle",
                default = true
            },
            eyeOfTyrThreshold = {
                displayName = "Eye of Tyr Threshold",
                description = "Health percentage to use Eye of Tyr",
                type = "slider",
                min = 20,
                max = 80,
                default = 50
            },
            useLayOnHandsEmergency = {
                displayName = "Use Lay on Hands Emergency",
                description = "Use Lay on Hands at critical health",
                type = "toggle",
                default = true
            },
            layOnHandsThreshold = {
                displayName = "Lay on Hands Threshold",
                description = "Health percentage to use Lay on Hands",
                type = "slider",
                min = 5,
                max = 30,
                default = 15
            }
        },
        
        offensiveSettings = {
            useAvengingWrath = {
                displayName = "Use Avenging Wrath",
                description = "Automatically use Avenging Wrath",
                type = "toggle",
                default = true
            },
            useMomentOfGlory = {
                displayName = "Use Moment of Glory",
                description = "Automatically use Moment of Glory",
                type = "toggle",
                default = true
            },
            useSeraphim = {
                displayName = "Use Seraphim",
                description = "Automatically use Seraphim when talented",
                type = "toggle",
                default = true
            },
            useDivineToll = {
                displayName = "Use Divine Toll",
                description = "Automatically use Divine Toll",
                type = "toggle",
                default = true
            },
            useExecutionSentence = {
                displayName = "Use Execution Sentence",
                description = "Automatically use Execution Sentence",
                type = "toggle",
                default = true
            }
        },
        
        advancedSettings = {
            minHolyPowerSpenders = {
                displayName = "Minimum Holy Power for Spenders",
                description = "Minimum Holy Power to use spenders (except procs)",
                type = "slider",
                min = 2,
                max = 5,
                default = 3
            },
            consecrationPriority = {
                displayName = "Consecration Priority",
                description = "Priority for maintaining Consecration",
                type = "dropdown",
                options = {"Always", "During Combat", "Low Priority"},
                default = "Always"
            },
            saveCooldownsForBurst = {
                displayName = "Save Cooldowns for Burst",
                description = "Hold offensive cooldowns for burst phases",
                type = "toggle",
                default = false
            },
            bastionThreshold = {
                displayName = "Bastion of Light Threshold",
                description = "Health percentage to use Bastion of Light",
                type = "slider",
                min = 10,
                max = 70,
                default = 40
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Shield of the Righteous controls
            shieldOfTheRighteous = AAC.RegisterAbility(spells.SHIELD_OF_THE_RIGHTEOUS, {
                enabled = true,
                useWithBastion = false,
                minActiveTime = 2 -- Minimum seconds of SotR remaining before refreshing
            }),
            
            -- Avenger's Shield controls
            avengersShield = AAC.RegisterAbility(spells.AVENGERS_SHIELD, {
                enabled = true,
                priorityInterrupt = true,
                useWithMomentOfGlory = true
            }),
            
            -- Seraphim controls
            seraphim = AAC.RegisterAbility(spells.SERAPHIM, {
                enabled = true,
                minHolyPower = 3,
                useWithAvengingWrath = true
            })
        }
    })
    
    return true
end

-- Register for events 
function Protection:RegisterEvents()
    -- Register for combat log events to track procs and buffs
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(...) 
        self:HandleCombatLogEvent(...) 
    end)
    
    -- Register for holy power updates
    API.RegisterEvent("UNIT_POWER_FREQUENT", function(unit, powerType) 
        if unit == "player" and powerType == "HOLY_POWER" then
            self:UpdateHolyPower()
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
function Protection:UpdateTalentInfo()
    -- Check for important talents
    talents.hasBlessedHammer = API.HasTalent(spells.BLESSED_HAMMER)
    talents.hasHolyShield = API.HasTalent(spells.HOLY_SHIELD)
    talents.hasRighteousProtector = API.HasTalent(spells.RIGHTEOUS_PROTECTOR)
    talents.hasRedoubt = API.HasTalent(spells.REDOUBT)
    talents.hasCrusadersJudgment = API.HasTalent(spells.CRUSADERS_JUDGMENT)
    talents.hasFirstAvenger = API.HasTalent(spells.FIRST_AVENGER)
    talents.hasDivinePurpose = API.HasTalent(spells.DIVINE_PURPOSE)
    talents.hasSeraphim = API.HasTalent(spells.SERAPHIM)
    talents.hasHolyAvenger = API.HasTalent(spells.HOLY_AVENGER)
    talents.hasFinalStand = API.HasTalent(spells.FINAL_STAND)
    talents.hasBlessingOfSpellwarding = API.HasTalent(spells.BLESSING_OF_SPELLWARDING)
    talents.hasLastDefender = API.HasTalent(spells.LAST_DEFENDER)
    talents.hasMomentOfGlory = API.HasTalent(spells.MOMENT_OF_GLORY)
    talents.hasEyeOfTyr = API.HasTalent(spells.EYE_OF_TYR)
    talents.hasDivineToll = API.HasTalent(spells.DIVINE_TOLL)
    talents.hasExecutionSentence = API.HasTalent(spells.EXECUTION_SENTENCE)
    talents.hasBastion = API.HasTalent(spells.BASTION_OF_LIGHT)
    
    API.PrintDebug("Protection Paladin talents updated")
    
    return true
end

-- Update holy power tracking
function Protection:UpdateHolyPower()
    currentHolyPower = API.GetPlayerPower()
    return true
end

-- Update target data
function Protection:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                eyeOfTyr = false,
                eyeOfTyrExpiration = 0,
                finalSentence = false,
                finalSentenceExpiration = 0
            }
        end
    end
    
    -- Update execute phase tracking (Hammer of Wrath)
    if API.GetTargetHealthPercent() <= EXECUTE_THRESHOLD then
        hammerOfWrathAvailable = true
    else
        hammerOfWrathAvailable = false
    end
    
    -- Update AoE targets count
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Protection AoE radius
    
    return true
end

-- Handle combat log events
function Protection:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Shield of the Righteous
            if spellID == buffs.SHIELD_OF_THE_RIGHTEOUS then
                shieldOfRighteousBuff = true
                -- Extend the duration for legendary effect
                lastShieldOfRighteous = GetTime()
                API.PrintDebug("Shield of the Righteous activated")
            end
            
            -- Track Avenging Wrath
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = true
                API.PrintDebug("Avenging Wrath activated")
            end
            
            -- Track Ardent Defender
            if spellID == buffs.ARDENT_DEFENDER then
                ardentDefenderActive = true
                API.PrintDebug("Ardent Defender activated")
            end
            
            -- Track Guardian of Ancient Kings
            if spellID == buffs.GUARDIAN_OF_ANCIENT_KINGS then
                guardianOfAncientKingsActive = true
                API.PrintDebug("Guardian of Ancient Kings activated")
            end
            
            -- Track Divine Purpose
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeBuff = true
                API.PrintDebug("Divine Purpose proc")
            end
            
            -- Track Moment of Glory
            if spellID == buffs.MOMENT_OF_GLORY then
                momentOfGloryBuff = true
                API.PrintDebug("Moment of Glory activated")
            end
            
            -- Track Shining Light
            if spellID == buffs.SHINING_LIGHT then
                shiningLightStacks = 5 -- Full stacks
                API.PrintDebug("Shining Light full stacks")
            end
            
            -- Track Bulwark of Righteous Glory (Sentinel legendary)
            if spellID == buffs.BULWARK_OF_RIGHTEOUS_GLORY then
                bulwarkOfRighteousGlory = true
                API.PrintDebug("Bulwark of Righteous Glory activated")
            end
            
            -- Track Divine Protection
            if spellID == buffs.DIVINE_PROTECTION then
                divineProtectionActive = true
                API.PrintDebug("Divine Protection activated")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            -- Track Eye of Tyr 
            if spellID == debuffs.EYE_OF_TYR then
                self.targetData[destGUID].eyeOfTyr = true
                self.targetData[destGUID].eyeOfTyrExpiration = select(6, API.GetDebuffInfo(destGUID, debuffs.EYE_OF_TYR))
                
                if destGUID == API.GetTargetGUID() then
                    eyeOfTyrActive = true
                    API.PrintDebug("Eye of Tyr applied to target")
                end
            end
            
            -- Track Final Sentence (Execution Sentence)
            if spellID == debuffs.FINAL_SENTENCE then
                self.targetData[destGUID].finalSentence = true
                self.targetData[destGUID].finalSentenceExpiration = select(6, API.GetDebuffInfo(destGUID, debuffs.FINAL_SENTENCE))
                
                if destGUID == API.GetTargetGUID() then
                    sentenceActive = true
                    API.PrintDebug("Final Sentence applied to target")
                end
            end
        end
    end
    
    -- Track buff removals
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Shield of the Righteous
            if spellID == buffs.SHIELD_OF_THE_RIGHTEOUS then
                shieldOfRighteousBuff = false
                API.PrintDebug("Shield of the Righteous faded")
            end
            
            -- Track Avenging Wrath
            if spellID == buffs.AVENGING_WRATH then
                avengingWrathActive = false
                API.PrintDebug("Avenging Wrath faded")
            end
            
            -- Track Ardent Defender
            if spellID == buffs.ARDENT_DEFENDER then
                ardentDefenderActive = false
                API.PrintDebug("Ardent Defender faded")
            end
            
            -- Track Guardian of Ancient Kings
            if spellID == buffs.GUARDIAN_OF_ANCIENT_KINGS then
                guardianOfAncientKingsActive = false
                API.PrintDebug("Guardian of Ancient Kings faded")
            end
            
            -- Track Divine Purpose
            if spellID == buffs.DIVINE_PURPOSE then
                divinePurposeBuff = false
                API.PrintDebug("Divine Purpose consumed")
            end
            
            -- Track Moment of Glory
            if spellID == buffs.MOMENT_OF_GLORY then
                momentOfGloryBuff = false
                API.PrintDebug("Moment of Glory faded")
            end
            
            -- Track Shining Light
            if spellID == buffs.SHINING_LIGHT then
                shiningLightStacks = 0
                API.PrintDebug("Shining Light consumed")
            end
            
            -- Track Bulwark of Righteous Glory
            if spellID == buffs.BULWARK_OF_RIGHTEOUS_GLORY then
                bulwarkOfRighteousGlory = false
                API.PrintDebug("Bulwark of Righteous Glory faded")
            end
            
            -- Track Divine Protection
            if spellID == buffs.DIVINE_PROTECTION then
                divineProtectionActive = false
                API.PrintDebug("Divine Protection faded")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            -- Track Eye of Tyr
            if spellID == debuffs.EYE_OF_TYR then
                self.targetData[destGUID].eyeOfTyr = false
                
                if destGUID == API.GetTargetGUID() then
                    eyeOfTyrActive = false
                    API.PrintDebug("Eye of Tyr faded from target")
                end
            end
            
            -- Track Final Sentence
            if spellID == debuffs.FINAL_SENTENCE then
                self.targetData[destGUID].finalSentence = false
                
                if destGUID == API.GetTargetGUID() then
                    sentenceActive = false
                    API.PrintDebug("Final Sentence faded from target")
                end
            end
        end
    end
    
    -- Track spell casts
    if eventType == "SPELL_CAST_SUCCESS" and sourceGUID == API.GetPlayerGUID() then
        -- Track Shield of the Righteous casts
        if spellID == spells.SHIELD_OF_THE_RIGHTEOUS then
            shieldOfRighteousBuff = true
            lastShieldOfRighteous = GetTime()
            API.PrintDebug("Shield of the Righteous cast")
        elseif spellID == spells.CONSECRATION then
            consecrationActive = true
            consecrationTimeRemaining = CONSECRATION_DURATION
            
            -- Set a timer to track consecration expiration
            C_Timer.After(CONSECRATION_DURATION, function()
                consecrationActive = false
                API.PrintDebug("Consecration expired")
            end)
            
            API.PrintDebug("Consecration cast")
        elseif spellID == spells.DIVINE_TOLL then
            divineTollAvailable = false
            
            -- Set a timer to track Divine Toll cooldown
            C_Timer.After(60, function() -- 60 second cooldown
                divineTollAvailable = true
                API.PrintDebug("Divine Toll available")
            end)
        elseif spellID == spells.BASTION_OF_LIGHT then
            bastion = true
            
            -- Set a timer to track Bastion of Light fading (duration of effect)
            C_Timer.After(10, function() -- Approximate effect duration
                bastion = false
            end)
        elseif spellID == spells.SHIELD_OF_THE_RIGHTEOUS and shiningLightStacks < 5 then
            -- Increment Shining Light stacks (up to 5)
            shiningLightStacks = math.min(5, shiningLightStacks + 1)
            API.PrintDebug("Shining Light stacks: " .. tostring(shiningLightStacks))
        end
    end
    
    -- Track Shield of the Righteous charges
    if eventType == "SPELL_CHARGE_GAINED" and spellID == spells.SHIELD_OF_THE_RIGHTEOUS then
        shieldOfRighteousCharges = select(1, API.GetSpellCharges(spells.SHIELD_OF_THE_RIGHTEOUS)) or 0
        API.PrintDebug("Shield of the Righteous charge gained: " .. tostring(shieldOfRighteousCharges))
    end
    
    -- Track Shield of the Righteous charge usage
    if eventType == "SPELL_CHARGE_SPENT" and spellID == spells.SHIELD_OF_THE_RIGHTEOUS then
        shieldOfRighteousCharges = select(1, API.GetSpellCharges(spells.SHIELD_OF_THE_RIGHTEOUS)) or 0
        API.PrintDebug("Shield of the Righteous charge spent: " .. tostring(shieldOfRighteousCharges))
    end
    
    return true
end

-- Main rotation function
function Protection:RunRotation()
    -- Check if we should be running Protection Paladin logic
    if API.GetActiveSpecID() ~= PROTECTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("ProtectionPaladin")
    
    -- Update variables
    self:UpdateHolyPower()
    self:UpdateShieldOfRighteousStatus()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle emergency defensives first
    if self:HandleEmergencyDefensives(settings) then
        return true
    end
    
    -- Handle interrupts
    if self:HandleInterrupts() then
        return true
    end
    
    -- Handle Shield of the Righteous
    if self:HandleShieldOfRighteous(settings) then
        return true
    end
    
    -- Handle Word of Glory
    if self:HandleWordOfGlory(settings) then
        return true
    end
    
    -- Handle defensive cooldowns
    if self:HandleDefensiveCooldowns(settings) then
        return true
    end
    
    -- Handle offensive cooldowns
    if self:HandleOffensiveCooldowns(settings) then
        return true
    end
    
    -- Handle rotational abilities
    if settings.rotationSettings.aoeEnabled and currentAoETargets >= settings.rotationSettings.aoeThreshold then
        return self:HandleAoERotation(settings)
    else
        return self:HandleSingleTargetRotation(settings)
    end
end

-- Update Shield of the Righteous status
function Protection:UpdateShieldOfRighteousStatus()
    shieldOfRighteousCharges = select(1, API.GetSpellCharges(spells.SHIELD_OF_THE_RIGHTEOUS)) or 0
    
    if shieldOfRighteousBuff then
        local timeElapsed = GetTime() - lastShieldOfRighteous
        
        if timeElapsed > SOR_DURATION then
            shieldOfRighteousBuff = false
        end
    end
    
    return true
end

-- Handle emergency defensive cooldowns
function Protection:HandleEmergencyDefensives(settings)
    -- Use Ardent Defender for emergency
    if settings.defensiveSettings.useArdentDefender and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.ardentDefenderThreshold and
       not ardentDefenderActive and
       API.CanCast(spells.ARDENT_DEFENDER) then
        API.CastSpell(spells.ARDENT_DEFENDER)
        return true
    end
    
    -- Use Guardian of Ancient Kings for emergency
    if settings.defensiveSettings.useGuardianOfAncientKings and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.guardianOfAncientKingsThreshold and
       not guardianOfAncientKingsActive and
       API.CanCast(spells.GUARDIAN_OF_ANCIENT_KINGS) then
        API.CastSpell(spells.GUARDIAN_OF_ANCIENT_KINGS)
        return true
    end
    
    -- Use Bastion of Light for emergency (if talented)
    if talents.hasBastion and
       API.GetPlayerHealthPercent() <= settings.advancedSettings.bastionThreshold and
       not bastion and
       API.CanCast(spells.BASTION_OF_LIGHT) then
        API.CastSpell(spells.BASTION_OF_LIGHT)
        return true
    end
    
    -- Use Lay on Hands for critical health
    if settings.defensiveSettings.useLayOnHandsEmergency and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.layOnHandsThreshold and
       API.CanCast(spells.LAY_ON_HANDS) then
        API.CastSpellOnUnit(spells.LAY_ON_HANDS, "player")
        return true
    end
    
    return false
end

-- Handle interrupts
function Protection:HandleInterrupts()
    -- Use Avenger's Shield for interrupt if prioritized
    if settings.abilityControls.avengersShield.priorityInterrupt and
       API.CanCast(spells.AVENGERS_SHIELD) and
       API.TargetIsSpellCastable() then
        API.CastSpell(spells.AVENGERS_SHIELD)
        return true
    end
    
    -- Use Rebuke for interrupt
    if API.CanCast(spells.REBUKE) and API.TargetIsSpellCastable() then
        API.CastSpell(spells.REBUKE)
        return true
    end
    
    return false
end

-- Handle Shield of the Righteous usage
function Protection:HandleShieldOfRighteous(settings)
    -- Check if we should use SotR
    local shouldUseSotR = false
    
    -- With Divine Purpose proc, always use it
    if divinePurposeBuff and API.CanCast(spells.SHIELD_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.SHIELD_OF_THE_RIGHTEOUS)
        return true
    end
    
    -- Need Holy Power to use SotR
    if currentHolyPower < 3 and not bastion then
        return false
    end
    
    if settings.rotationSettings.sotrMode == "Defensive Priority" then
        -- Use SotR defensively - when buff is down or about to expire
        if not shieldOfRighteousBuff or 
           (GetTime() - lastShieldOfRighteous) > (SOR_DURATION - settings.abilityControls.shieldOfTheRighteous.minActiveTime) then
            shouldUseSotR = true
        end
    elseif settings.rotationSettings.sotrMode == "Maximum Uptime" then
        -- Always keep SotR up
        if not shieldOfRighteousBuff then
            shouldUseSotR = true
        end
    elseif settings.rotationSettings.sotrMode == "Holy Power Dump" then
        -- Use when at high Holy Power
        if currentHolyPower >= 4 or bastion then
            shouldUseSotR = true
        end
    end
    
    -- Don't use if using Bastion of Light but setting disallows
    if bastion and not settings.abilityControls.shieldOfTheRighteous.useWithBastion then
        shouldUseSotR = false
    end
    
    if shouldUseSotR and API.CanCast(spells.SHIELD_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.SHIELD_OF_THE_RIGHTEOUS)
        return true
    end
    
    return false
end

-- Handle Word of Glory usage
function Protection:HandleWordOfGlory(settings)
    -- Skip if threshold is 0 (disabled)
    if settings.rotationSettings.wordOfGloryThreshold <= 0 then
        return false
    end
    
    -- Check if we should use Word of Glory
    local shouldUseWoG = false
    local playerHealthPercent = API.GetPlayerHealthPercent()
    
    -- With Divine Purpose proc, use it at higher threshold
    if divinePurposeBuff and 
       playerHealthPercent <= settings.rotationSettings.wordOfGloryThreshold + 10 and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    -- With Shining Light stacks, use at higher threshold if prioritized
    if shiningLightStacks >= 5 and settings.rotationSettings.shiningLightPriority then
        if playerHealthPercent <= settings.rotationSettings.wordOfGloryThreshold + 15 and
           API.CanCast(spells.WORD_OF_GLORY) then
            API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
            return true
        end
    end
    
    -- Need Holy Power to use WoG and below threshold
    if currentHolyPower >= 3 and playerHealthPercent <= settings.rotationSettings.wordOfGloryThreshold then
        shouldUseWoG = true
    end
    
    if shouldUseWoG and API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpellOnUnit(spells.WORD_OF_GLORY, "player")
        return true
    end
    
    return false
end

-- Handle defensive cooldowns
function Protection:HandleDefensiveCooldowns(settings)
    -- Use Divine Protection
    if settings.defensiveSettings.useDivineProtection and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.divineProtectionThreshold and
       not divineProtectionActive and
       API.CanCast(spells.DIVINE_PROTECTION) then
        API.CastSpell(spells.DIVINE_PROTECTION)
        return true
    end
    
    -- Use Eye of Tyr
    if talents.hasEyeOfTyr and
       settings.defensiveSettings.useEyeOfTyr and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.eyeOfTyrThreshold and
       not eyeOfTyrActive and
       API.CanCast(spells.EYE_OF_TYR) then
        API.CastSpell(spells.EYE_OF_TYR)
        return true
    end
    
    return false
end

-- Handle offensive cooldowns
function Protection:HandleOffensiveCooldowns(settings)
    -- Skip offensive cooldowns if not in burst mode and save cooldowns is enabled
    if not burstModeActive and settings.advancedSettings.saveCooldownsForBurst then
        return false
    end
    
    -- Use Avenging Wrath
    if settings.offensiveSettings.useAvengingWrath and
       API.CanCast(spells.AVENGING_WRATH) and
       not avengingWrathActive then
        API.CastSpell(spells.AVENGING_WRATH)
        return true
    end
    
    -- Use Moment of Glory
    if talents.hasMomentOfGlory and
       settings.offensiveSettings.useMomentOfGlory and
       API.CanCast(spells.MOMENT_OF_GLORY) and
       not momentOfGloryBuff then
        API.CastSpell(spells.MOMENT_OF_GLORY)
        return true
    end
    
    -- Use Seraphim
    if talents.hasSeraphim and
       settings.offensiveSettings.useSeraphim and
       settings.abilityControls.seraphim.enabled and
       currentHolyPower >= settings.abilityControls.seraphim.minHolyPower and
       API.CanCast(spells.SERAPHIM) then
        
        -- Check if we should align with Avenging Wrath
        if not settings.abilityControls.seraphim.useWithAvengingWrath or
           avengingWrathActive then
            API.CastSpell(spells.SERAPHIM)
            return true
        end
    end
    
    -- Use Divine Toll
    if talents.hasDivineToll and
       settings.offensiveSettings.useDivineToll and
       divineTollAvailable and
       API.CanCast(spells.DIVINE_TOLL) then
        API.CastSpell(spells.DIVINE_TOLL)
        return true
    end
    
    -- Use Execution Sentence
    if talents.hasExecutionSentence and
       settings.offensiveSettings.useExecutionSentence and
       not sentenceActive and
       API.CanCast(spells.EXECUTION_SENTENCE) then
        API.CastSpell(spells.EXECUTION_SENTENCE)
        return true
    end
    
    return false
end

-- Handle AoE rotation
function Protection:HandleAoERotation(settings)
    -- Cast Avenger's Shield - high priority for AoE
    if API.CanCast(spells.AVENGERS_SHIELD) then
        -- Prioritize with Moment of Glory if setting enabled
        if momentOfGloryBuff and settings.abilityControls.avengersShield.useWithMomentOfGlory then
            API.PrintDebug("Using Avenger's Shield with Moment of Glory")
        end
        
        API.CastSpell(spells.AVENGERS_SHIELD)
        return true
    end
    
    -- Cast Judgment
    if API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Cast Consecration if not active or about to expire
    if not consecrationActive and API.CanCast(spells.CONSECRATION) then
        if settings.advancedSettings.consecrationPriority == "Always" or
           settings.advancedSettings.consecrationPriority == "During Combat" then
            API.CastSpell(spells.CONSECRATION)
            return true
        end
    end
    
    -- Cast Hammer of Wrath if available (execute phase)
    if hammerOfWrathAvailable and API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    -- Cast Blessed Hammer if talented, otherwise Hammer of the Righteous
    if talents.hasBlessedHammer and API.CanCast(spells.BLESSED_HAMMER) then
        API.CastSpell(spells.BLESSED_HAMMER)
        return true
    elseif API.CanCast(spells.HAMMER_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.HAMMER_OF_THE_RIGHTEOUS)
        return true
    end
    
    -- Use Consecration as filler
    if API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Protection:HandleSingleTargetRotation(settings)
    -- Cast Avenger's Shield
    if API.CanCast(spells.AVENGERS_SHIELD) then
        API.CastSpell(spells.AVENGERS_SHIELD)
        return true
    end
    
    -- Cast Judgment
    if API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Cast Hammer of Wrath if available (execute phase)
    if hammerOfWrathAvailable and API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    -- Cast Blessed Hammer if talented, otherwise Hammer of the Righteous
    if talents.hasBlessedHammer and API.CanCast(spells.BLESSED_HAMMER) then
        API.CastSpell(spells.BLESSED_HAMMER)
        return true
    elseif API.CanCast(spells.HAMMER_OF_THE_RIGHTEOUS) then
        API.CastSpell(spells.HAMMER_OF_THE_RIGHTEOUS)
        return true
    end
    
    -- Cast Consecration if not active
    if not consecrationActive and API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle specialization change
function Protection:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentHolyPower = API.GetPlayerPower()
    shieldOfRighteousBuff = false
    shieldOfRighteousCharges = API.GetSpellCharges(spells.SHIELD_OF_THE_RIGHTEOUS) or 0
    avengingWrathActive = false
    hammerOfWrathAvailable = false
    lastWordTargets = {}
    consecrationActive = false
    consecrationTimeRemaining = 0
    divineTollAvailable = true
    lastShieldOfRighteous = 0
    shiningLightStacks = 0
    bulwarkOfRighteousGlory = false
    ardentDefenderActive = false
    guardianOfAncientKingsActive = false
    divineProtectionActive = false
    eyeOfTyrActive = false
    divinePurposeBuff = false
    momentOfGloryBuff = false
    sentenceActive = false
    battleAvengersHand = 0
    bastion = false
    
    API.PrintDebug("Protection Paladin state reset on spec change")
    
    return true
end

-- Return the module for loading
return Protection