------------------------------------------
-- WindrunnerRotations - Retribution Paladin Module
-- Author: VortexQ8
------------------------------------------

local Retribution = {}
-- This will be assigned to addon.Classes.Paladin.Retribution when loaded

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
local avengerActive = false
local crusadeActive = false
local crusadeStacks = 0
local executionSentenceActive = false
local wakeOfAshesAvailable = true
local durationExecutionSentence = 0
local lastExecutionSentenceTime = 0
local consecrationActive = false
local hammerOfWrathAvailable = false
local finalVerdictBuff = false
local divinePurposeBuff = false
local empyreanPowerBuff = false
local exorcismStacks = 0
local divineTollAvailable = true

-- Constants
local RETRIBUTION_SPEC_ID = 70
local DEFAULT_AOE_THRESHOLD = 3
local EXECUTE_THRESHOLD = 20 -- Health percent to enable Hammer of Wrath

-- Initialize the Retribution module
function Retribution:Initialize()
    self:RegisterSpells()
    self:RegisterVariables()
    self:RegisterSettings()
    self:RegisterEvents()
    
    API.PrintDebug("Retribution Paladin module initialized")
    
    return true
end

-- Register spell IDs
function Retribution:RegisterSpells()
    -- Retribution Core Abilities
    spells.CRUSADER_STRIKE = 35395
    spells.BLADE_OF_JUSTICE = 184575
    spells.JUDGMENT = 20271
    spells.TEMPLAR_STRIKE = 255937
    spells.TEMPLARS_VERDICT = 85256
    spells.DIVINE_STORM = 53385
    spells.WAKE_OF_ASHES = 255937
    spells.HAMMER_OF_WRATH = 24275
    spells.AVENGING_WRATH = 31884
    spells.DIVINE_PURPOSE = 223817
    spells.EXECUTION_SENTENCE = 343527
    spells.FINAL_RECKONING = 343721
    spells.SERAPHIM = 152262
    spells.CONSECRATION = 26573
    spells.REBUKE = 96231
    spells.SHIELD_OF_VENGEANCE = 184662
    spells.WORD_OF_GLORY = 85673
    spells.JUSTICARS_VENGEANCE = 215661
    spells.HOLY_AVENGER = 105809
    spells.CRUSADE = 231895
    spells.FINAL_VERDICT = 336872
    spells.DIVINE_TOLL = 375576
    spells.EMPYREAN_POWER = 326732
    spells.EMPYREAN_POWER_BUFF = 326733
    spells.VANQUISHERS_HAMMER = 328204
    spells.EXORCISM = 383185
    
    -- Buffs and procs
    spells.AVENGING_WRATH_BUFF = 31884
    spells.DIVINE_PURPOSE_BUFF = 223819
    spells.CRUSADE_BUFF = 231895
    spells.FINAL_VERDICT_BUFF = 337228
    spells.VANQUISHERS_HAMMER_BUFF = 328204
    spells.HOLY_AVENGER_BUFF = 105809
    
    -- Register all spells with the API tracking system
    for spellName, spellID in pairs(spells) do
        API.RegisterSpell(spellID)
    end
    
    -- Define aura tracking
    buffs.AVENGING_WRATH = spells.AVENGING_WRATH_BUFF
    buffs.DIVINE_PURPOSE = spells.DIVINE_PURPOSE_BUFF
    buffs.CRUSADE = spells.CRUSADE_BUFF
    buffs.FINAL_VERDICT = spells.FINAL_VERDICT_BUFF
    buffs.VANQUISHERS_HAMMER = spells.VANQUISHERS_HAMMER_BUFF
    buffs.HOLY_AVENGER = spells.HOLY_AVENGER_BUFF
    buffs.EMPYREAN_POWER = spells.EMPYREAN_POWER_BUFF
    
    -- Debuffs
    debuffs.EXECUTION_SENTENCE = spells.EXECUTION_SENTENCE
    debuffs.FINAL_RECKONING = spells.FINAL_RECKONING
    
    return true
end

-- Register variables to track
function Retribution:RegisterVariables()
    -- Talent tracking
    talents.hasHolyAvenger = false
    talents.hasCrusade = false
    talents.hasExecutionSentence = false
    talents.hasFinalReckoning = false
    talents.hasSeraphim = false
    talents.hasFinalVerdict = false
    talents.hasDivinePurpose = false
    talents.hasVanquishersHammer = false
    talents.hasWakeOfAshes = false
    talents.hasEmpyreanPower = false
    talents.hasExorcism = false
    talents.hasDivineToll = false
    
    -- Target state tracking
    self.targetData = {}
    
    return true
end

-- Register spec-specific settings
function Retribution:RegisterSettings()
    ConfigRegistry:RegisterSettings("RetributionPaladin", {
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
            useWOG = {
                displayName = "Use Word of Glory",
                description = "Use Word of Glory for self-healing",
                type = "toggle",
                default = true
            },
            WOGThreshold = {
                displayName = "Word of Glory Health Threshold",
                description = "Health percentage to use Word of Glory",
                type = "slider",
                min = 10,
                max = 90,
                default = 40
            },
            prioritizeDivinePurpose = {
                displayName = "Prioritize Divine Purpose",
                description = "Use Divine Purpose procs immediately",
                type = "toggle",
                default = true
            },
            holyPowerGenMode = {
                displayName = "Holy Power Generation",
                description = "Method of Holy Power generation",
                type = "dropdown",
                options = {"Balanced", "Prioritize AoE", "Maximize Single Target"},
                default = "Balanced"
            }
        },
        
        cooldownSettings = {
            useAvengingWrath = {
                displayName = "Use Avenging Wrath",
                description = "Automatically use Avenging Wrath for burst",
                type = "toggle",
                default = true
            },
            useCrusade = {
                displayName = "Use Crusade",
                description = "Automatically use Crusade when talented",
                type = "toggle",
                default = true
            },
            useFinalReckoning = {
                displayName = "Use Final Reckoning",
                description = "Use Final Reckoning when talented",
                type = "toggle",
                default = true
            },
            useExecutionSentence = {
                displayName = "Use Execution Sentence",
                description = "Use Execution Sentence when talented",
                type = "toggle",
                default = true
            },
            useSeraphim = {
                displayName = "Use Seraphim",
                description = "Use Seraphim when talented",
                type = "toggle",
                default = true
            },
            useHolyAvenger = {
                displayName = "Use Holy Avenger",
                description = "Use Holy Avenger when talented",
                type = "toggle",
                default = true
            },
            useDivineToll = {
                displayName = "Use Divine Toll",
                description = "Use Divine Toll when talented",
                type = "toggle",
                default = true
            },
            alignSeraphimWithBurst = {
                displayName = "Align Seraphim with Burst",
                description = "Only use Seraphim during burst windows",
                type = "toggle",
                default = true
            }
        },
        
        defensiveSettings = {
            useShieldOfVengeance = {
                displayName = "Use Shield of Vengeance",
                description = "Automatically use Shield of Vengeance",
                type = "toggle",
                default = true
            },
            shieldOfVengeanceThreshold = {
                displayName = "Shield of Vengeance Health",
                description = "Health percentage to use Shield of Vengeance",
                type = "slider",
                min = 10,
                max = 90,
                default = 70
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
            holdHolyPowerForBurst = {
                displayName = "Hold Holy Power for Burst",
                description = "Save Holy Power during burst cooldown preparation",
                type = "toggle",
                default = false
            },
            finishersBeforeBurst = {
                displayName = "Builders before Burst",
                description = "Use Holy Power generators before burst",
                type = "toggle",
                default = true
            },
            finishersPerBurst = {
                displayName = "Finishers per Burst",
                description = "Target number of finishers during burst",
                type = "slider",
                min = 3,
                max = 10,
                default = 5
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Final Reckoning controls
            finalReckoning = AAC.RegisterAbility(spells.FINAL_RECKONING, {
                enabled = true,
                minHolyPower = 3,
                useWithAvenging = true
            }),
            
            -- Wake of Ashes controls
            wakeOfAshes = AAC.RegisterAbility(spells.WAKE_OF_ASHES, {
                enabled = true,
                minEnemies = 1,
                maxHolyPower = 2 -- Use when at 2 or less Holy Power
            }),
            
            -- Execution Sentence controls
            executionSentence = AAC.RegisterAbility(spells.EXECUTION_SENTENCE, {
                enabled = true,
                useWithAvenging = true,
                minHolyPower = 3
            })
        }
    })
    
    return true
end

-- Register for events 
function Retribution:RegisterEvents()
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
function Retribution:UpdateTalentInfo()
    -- Check for important talents
    talents.hasHolyAvenger = API.HasTalent(spells.HOLY_AVENGER)
    talents.hasCrusade = API.HasTalent(spells.CRUSADE)
    talents.hasExecutionSentence = API.HasTalent(spells.EXECUTION_SENTENCE)
    talents.hasFinalReckoning = API.HasTalent(spells.FINAL_RECKONING)
    talents.hasSeraphim = API.HasTalent(spells.SERAPHIM)
    talents.hasFinalVerdict = API.HasTalent(spells.FINAL_VERDICT)
    talents.hasDivinePurpose = API.HasTalent(spells.DIVINE_PURPOSE)
    talents.hasVanquishersHammer = API.HasTalent(spells.VANQUISHERS_HAMMER)
    talents.hasWakeOfAshes = API.HasTalent(spells.WAKE_OF_ASHES)
    talents.hasEmpyreanPower = API.HasTalent(spells.EMPYREAN_POWER)
    talents.hasExorcism = API.HasTalent(spells.EXORCISM)
    talents.hasDivineToll = API.HasTalent(spells.DIVINE_TOLL)
    
    API.PrintDebug("Retribution Paladin talents updated")
    
    return true
end

-- Update holy power tracking
function Retribution:UpdateHolyPower()
    currentHolyPower = API.GetPlayerPower()
    return true
end

-- Update target data
function Retribution:UpdateTargetData()
    -- Get target GUID
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and targetGUID ~= "" then
        -- Initialize target data if needed
        if not self.targetData[targetGUID] then
            self.targetData[targetGUID] = {
                executionSentence = false,
                executionSentenceExpiration = 0,
                finalReckoning = false,
                finalReckoningExpiration = 0
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
    currentAoETargets = API.GetNearbyEnemiesCount(8) -- Retribution AoE radius
    
    return true
end

-- Handle combat log events
function Retribution:HandleCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Only process events from the player
    if sourceGUID ~= API.GetPlayerGUID() then
        return false
    end
    
    -- Track buff applications
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Avenging Wrath
            if spellID == spells.AVENGING_WRATH_BUFF then
                avengerActive = true
                API.PrintDebug("Avenging Wrath activated")
            end
            
            -- Track Crusade
            if spellID == spells.CRUSADE_BUFF then
                crusadeActive = true
                crusadeStacks = 1
                API.PrintDebug("Crusade activated")
            end
            
            -- Track Divine Purpose
            if spellID == spells.DIVINE_PURPOSE_BUFF then
                divinePurposeBuff = true
                API.PrintDebug("Divine Purpose proc")
            end
            
            -- Track Final Verdict
            if spellID == spells.FINAL_VERDICT_BUFF then
                finalVerdictBuff = true
                API.PrintDebug("Final Verdict buff applied")
            end
            
            -- Track Empyrean Power
            if spellID == spells.EMPYREAN_POWER_BUFF then
                empyreanPowerBuff = true
                API.PrintDebug("Empyrean Power proc")
            end
            
            -- Track Holy Avenger
            if spellID == spells.HOLY_AVENGER_BUFF then
                API.PrintDebug("Holy Avenger activated")
            end
            
            -- Track Consecration
            if spellID == spells.CONSECRATION then
                consecrationActive = true
                API.PrintDebug("Consecration active")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == spells.EXECUTION_SENTENCE then
                self.targetData[destGUID].executionSentence = true
                self.targetData[destGUID].executionSentenceExpiration = select(6, API.GetDebuffInfo(destGUID, spells.EXECUTION_SENTENCE))
                
                if destGUID == API.GetTargetGUID() then
                    executionSentenceActive = true
                    lastExecutionSentenceTime = GetTime()
                    durationExecutionSentence = self.targetData[destGUID].executionSentenceExpiration - GetTime()
                    API.PrintDebug("Execution Sentence applied to target")
                end
            elseif spellID == spells.FINAL_RECKONING then
                self.targetData[destGUID].finalReckoning = true
                self.targetData[destGUID].finalReckoningExpiration = select(6, API.GetDebuffInfo(destGUID, spells.FINAL_RECKONING))
                
                if destGUID == API.GetTargetGUID() then
                    API.PrintDebug("Final Reckoning applied to target")
                end
            end
        end
    end
    
    -- Track buffs/debuffs removal
    if eventType == "SPELL_AURA_REMOVED" then
        -- Track player buffs
        if destGUID == API.GetPlayerGUID() then
            -- Track Avenging Wrath
            if spellID == spells.AVENGING_WRATH_BUFF then
                avengerActive = false
                API.PrintDebug("Avenging Wrath faded")
            end
            
            -- Track Crusade
            if spellID == spells.CRUSADE_BUFF then
                crusadeActive = false
                crusadeStacks = 0
                API.PrintDebug("Crusade faded")
            end
            
            -- Track Divine Purpose
            if spellID == spells.DIVINE_PURPOSE_BUFF then
                divinePurposeBuff = false
                API.PrintDebug("Divine Purpose consumed")
            end
            
            -- Track Final Verdict
            if spellID == spells.FINAL_VERDICT_BUFF then
                finalVerdictBuff = false
                API.PrintDebug("Final Verdict buff faded")
            end
            
            -- Track Empyrean Power
            if spellID == spells.EMPYREAN_POWER_BUFF then
                empyreanPowerBuff = false
                API.PrintDebug("Empyrean Power consumed")
            end
            
            -- Track Consecration
            if spellID == spells.CONSECRATION then
                consecrationActive = false
                API.PrintDebug("Consecration faded")
            end
        end
        
        -- Track debuffs on targets
        if self.targetData[destGUID] then
            if spellID == spells.EXECUTION_SENTENCE then
                self.targetData[destGUID].executionSentence = false
                
                if destGUID == API.GetTargetGUID() then
                    executionSentenceActive = false
                    API.PrintDebug("Execution Sentence faded from target")
                end
            elseif spellID == spells.FINAL_RECKONING then
                self.targetData[destGUID].finalReckoning = false
                
                if destGUID == API.GetTargetGUID() then
                    API.PrintDebug("Final Reckoning faded from target")
                end
            end
        end
    end
    
    -- Track Crusade stacks
    if eventType == "SPELL_AURA_APPLIED_DOSE" and spellID == spells.CRUSADE_BUFF and destGUID == API.GetPlayerGUID() then
        crusadeStacks = select(4, UnitBuff("player", GetSpellInfo(spells.CRUSADE_BUFF))) or 0
        API.PrintDebug("Crusade stacks: " .. tostring(crusadeStacks))
    end
    
    -- Track ability cooldowns
    if eventType == "SPELL_CAST_SUCCESS" then
        if spellID == spells.WAKE_OF_ASHES then
            wakeOfAshesAvailable = false
            C_Timer.After(45, function() -- Wake of Ashes cooldown
                wakeOfAshesAvailable = true
                API.PrintDebug("Wake of Ashes available")
            end)
        elseif spellID == spells.DIVINE_TOLL then
            divineTollAvailable = false
            C_Timer.After(60, function() -- Divine Toll cooldown
                divineTollAvailable = true
                API.PrintDebug("Divine Toll available")
            end)
        elseif spellID == spells.EXORCISM then
            exorcismStacks = 3 -- Typically grants 3 stacks
            API.PrintDebug("Exorcism used, 3 stacks available")
        elseif spellID == spells.EXECUTION_SENTENCE then
            executionSentenceActive = true
            lastExecutionSentenceTime = GetTime()
        end
    end
    
    -- Track Exorcism usage
    if eventType == "SPELL_DAMAGE" and spellID == spells.BLADE_OF_JUSTICE then
        if exorcismStacks > 0 then
            exorcismStacks = exorcismStacks - 1
            API.PrintDebug("Exorcism stack consumed, " .. tostring(exorcismStacks) .. " remaining")
        end
    end
    
    return true
end

-- Main rotation function
function Retribution:RunRotation()
    -- Check if we should be running Retribution Paladin logic
    if API.GetActiveSpecID() ~= RETRIBUTION_SPEC_ID then
        return false
    end
    
    -- Skip rotation if player is casting
    if API.IsPlayerCasting() then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("RetributionPaladin")
    
    -- Update variables
    self:UpdateHolyPower()
    burstModeActive = settings.rotationSettings.burstEnabled and API.ShouldUseBurst()
    
    -- Handle next cast override
    if nextCastOverride and API.CanCast(nextCastOverride) then
        local spell = nextCastOverride
        nextCastOverride = nil
        API.CastSpell(spell)
        return true
    end
    
    -- Handle defensive abilities
    if self:HandleDefensives(settings) then
        return true
    end
    
    -- Handle self-healing
    if settings.rotationSettings.useWOG and 
       API.GetPlayerHealthPercent() <= settings.rotationSettings.WOGThreshold and
       (currentHolyPower >= 3 or divinePurposeBuff) and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpell(spells.WORD_OF_GLORY)
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

-- Handle defensive abilities
function Retribution:HandleDefensives(settings)
    -- Use Shield of Vengeance
    if settings.defensiveSettings.useShieldOfVengeance and
       API.GetPlayerHealthPercent() <= settings.defensiveSettings.shieldOfVengeanceThreshold and
       API.CanCast(spells.SHIELD_OF_VENGEANCE) then
        API.CastSpell(spells.SHIELD_OF_VENGEANCE)
        return true
    end
    
    -- Use Word of Glory for defensive healing
    if settings.rotationSettings.useWOG and
       API.GetPlayerHealthPercent() <= settings.rotationSettings.WOGThreshold and
       (currentHolyPower >= 3 or divinePurposeBuff) and
       API.CanCast(spells.WORD_OF_GLORY) then
        API.CastSpell(spells.WORD_OF_GLORY)
        return true
    end
    
    return false
end

-- Handle cooldown abilities
function Retribution:HandleCooldowns(settings)
    -- Skip if GCD is not ready
    if not API.IsGCDReady() then
        return false
    end
    
    -- Skip offensive cooldowns if not in burst mode, except for certain abilities
    if not burstModeActive and not settings.advancedSettings.finishersBeforeBurst then
        return false
    end
    
    -- Check if we should use Seraphim
    if talents.hasSeraphim and 
       settings.cooldownSettings.useSeraphim and
       currentHolyPower >= 3 and
       API.CanCast(spells.SERAPHIM) then
        
        if not settings.cooldownSettings.alignSeraphimWithBurst or burstModeActive then
            API.CastSpell(spells.SERAPHIM)
            return true
        end
    end
    
    -- Use Avenging Wrath/Crusade for burst
    if burstModeActive then
        if talents.hasCrusade and 
           settings.cooldownSettings.useCrusade and
           API.CanCast(spells.CRUSADE) then
            API.CastSpell(spells.CRUSADE)
            return true
        elseif settings.cooldownSettings.useAvengingWrath and
               API.CanCast(spells.AVENGING_WRATH) then
            API.CastSpell(spells.AVENGING_WRATH)
            return true
        end
    end
    
    -- Use Holy Avenger
    if talents.hasHolyAvenger and 
       settings.cooldownSettings.useHolyAvenger and
       burstModeActive and
       API.CanCast(spells.HOLY_AVENGER) then
        API.CastSpell(spells.HOLY_AVENGER)
        return true
    end
    
    -- Use Final Reckoning
    if talents.hasFinalReckoning and 
       settings.cooldownSettings.useFinalReckoning and
       settings.abilityControls.finalReckoning.enabled and
       currentHolyPower >= settings.abilityControls.finalReckoning.minHolyPower and
       API.CanCast(spells.FINAL_RECKONING) then
        
        if not settings.abilityControls.finalReckoning.useWithAvenging or 
           avengerActive or crusadeActive then
            API.CastSpellAtCursor(spells.FINAL_RECKONING)
            return true
        end
    end
    
    -- Use Divine Toll
    if talents.hasDivineToll and 
       settings.cooldownSettings.useDivineToll and
       divineTollAvailable and
       API.CanCast(spells.DIVINE_TOLL) then
        
        if burstModeActive or currentHolyPower <= 2 then
            API.CastSpell(spells.DIVINE_TOLL)
            return true
        end
    end
    
    -- Use Execution Sentence
    if talents.hasExecutionSentence and
       settings.cooldownSettings.useExecutionSentence and
       settings.abilityControls.executionSentence.enabled and
       currentHolyPower >= settings.abilityControls.executionSentence.minHolyPower and
       API.CanCast(spells.EXECUTION_SENTENCE) then
        
        if not settings.abilityControls.executionSentence.useWithAvenging or 
           avengerActive or crusadeActive then
            API.CastSpell(spells.EXECUTION_SENTENCE)
            return true
        end
    end
    
    return false
end

-- Handle AoE rotation
function Retribution:HandleAoERotation(settings)
    -- Use Divine Storm with Divine Purpose proc
    if divinePurposeBuff and API.CanCast(spells.DIVINE_STORM) then
        API.CastSpell(spells.DIVINE_STORM)
        return true
    end
    
    -- Use Divine Storm with Empyrean Power proc
    if empyreanPowerBuff and API.CanCast(spells.DIVINE_STORM) then
        API.CastSpell(spells.DIVINE_STORM)
        return true
    end
    
    -- Use Wake of Ashes for AoE damage and Holy Power generation
    if talents.hasWakeOfAshes and
       settings.abilityControls.wakeOfAshes.enabled and
       wakeOfAshesAvailable and 
       currentHolyPower <= settings.abilityControls.wakeOfAshes.maxHolyPower and
       currentAoETargets >= settings.abilityControls.wakeOfAshes.minEnemies and
       API.CanCast(spells.WAKE_OF_ASHES) then
        API.CastSpell(spells.WAKE_OF_ASHES)
        return true
    end
    
    -- Use Divine Storm when at sufficient Holy Power
    if currentHolyPower >= settings.advancedSettings.minHolyPowerSpenders and
       API.CanCast(spells.DIVINE_STORM) then
        -- Don't hold Holy Power during burst or if we're at max
        if not settings.advancedSettings.holdHolyPowerForBurst or
           burstModeActive or currentHolyPower >= maxHolyPower then
            API.CastSpell(spells.DIVINE_STORM)
            return true
        end
    end
    
    -- Use Final Verdict for AoE when talented
    if talents.hasFinalVerdict and 
       currentHolyPower >= settings.advancedSettings.minHolyPowerSpenders and
       not finalVerdictBuff and
       API.CanCast(spells.FINAL_VERDICT) then
        API.CastSpell(spells.FINAL_VERDICT)
        return true
    end
    
    -- Use Blade of Justice/Templar Strike for Holy Power generation
    if API.CanCast(spells.BLADE_OF_JUSTICE) then
        API.CastSpell(spells.BLADE_OF_JUSTICE)
        return true
    end
    
    -- Use Vanquisher's Hammer if talented
    if talents.hasVanquishersHammer and API.CanCast(spells.VANQUISHERS_HAMMER) then
        API.CastSpell(spells.VANQUISHERS_HAMMER)
        return true
    end
    
    -- Use Hammer of Wrath if target is in execute range
    if hammerOfWrathAvailable and API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    -- Use Judgment for Holy Power generation
    if API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Use Crusader Strike for Holy Power generation
    if API.CanCast(spells.CRUSADER_STRIKE) then
        API.CastSpell(spells.CRUSADER_STRIKE)
        return true
    end
    
    -- Use Consecration if needed
    if not consecrationActive and API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle Single Target rotation
function Retribution:HandleSingleTargetRotation(settings)
    -- Use Templar's Verdict with Divine Purpose proc
    if divinePurposeBuff and 
       (not settings.rotationSettings.prioritizeDivinePurpose or not API.CanCast(spells.EXECUTION_SENTENCE)) and
       API.CanCast(spells.TEMPLARS_VERDICT) then
        API.CastSpell(spells.TEMPLARS_VERDICT)
        return true
    end
    
    -- Use Wake of Ashes for Holy Power generation
    if talents.hasWakeOfAshes and
       settings.abilityControls.wakeOfAshes.enabled and
       wakeOfAshesAvailable and 
       currentHolyPower <= settings.abilityControls.wakeOfAshes.maxHolyPower and
       API.CanCast(spells.WAKE_OF_ASHES) then
        API.CastSpell(spells.WAKE_OF_ASHES)
        return true
    end
    
    -- Use Execution Sentence for single target damage
    if talents.hasExecutionSentence and
       settings.cooldownSettings.useExecutionSentence and
       currentHolyPower >= settings.abilityControls.executionSentence.minHolyPower and 
       not executionSentenceActive and
       (burstModeActive or avengerActive or crusadeActive) and
       API.CanCast(spells.EXECUTION_SENTENCE) then
        API.CastSpell(spells.EXECUTION_SENTENCE)
        return true
    end
    
    -- Use Templar's Verdict with Empyrean Power proc
    if empyreanPowerBuff and API.CanCast(spells.TEMPLARS_VERDICT) then
        if talents.hasFinalVerdict and not finalVerdictBuff then
            API.CastSpell(spells.FINAL_VERDICT)
        else
            API.CastSpell(spells.TEMPLARS_VERDICT)
        end
        return true
    end
    
    -- Use Final Verdict when talented
    if talents.hasFinalVerdict and 
       currentHolyPower >= settings.advancedSettings.minHolyPowerSpenders and
       not finalVerdictBuff and
       API.CanCast(spells.FINAL_VERDICT) then
        API.CastSpell(spells.FINAL_VERDICT)
        return true
    end
    
    -- Use Templar's Verdict when at sufficient Holy Power
    if currentHolyPower >= settings.advancedSettings.minHolyPowerSpenders and
       API.CanCast(spells.TEMPLARS_VERDICT) then
        -- Don't hold Holy Power during burst or if we're at max
        if not settings.advancedSettings.holdHolyPowerForBurst or
           burstModeActive or currentHolyPower >= maxHolyPower then
            API.CastSpell(spells.TEMPLARS_VERDICT)
            return true
        end
    end
    
    -- Use Blade of Justice for Holy Power generation (prioritize)
    if API.CanCast(spells.BLADE_OF_JUSTICE) then
        API.CastSpell(spells.BLADE_OF_JUSTICE)
        return true
    end
    
    -- Use Hammer of Wrath if target is in execute range
    if hammerOfWrathAvailable and API.CanCast(spells.HAMMER_OF_WRATH) then
        API.CastSpell(spells.HAMMER_OF_WRATH)
        return true
    end
    
    -- Use Vanquisher's Hammer if talented
    if talents.hasVanquishersHammer and API.CanCast(spells.VANQUISHERS_HAMMER) then
        API.CastSpell(spells.VANQUISHERS_HAMMER)
        return true
    end
    
    -- Use Judgment for Holy Power generation
    if API.CanCast(spells.JUDGMENT) then
        API.CastSpell(spells.JUDGMENT)
        return true
    end
    
    -- Use Crusader Strike for Holy Power generation
    if API.CanCast(spells.CRUSADER_STRIKE) then
        API.CastSpell(spells.CRUSADER_STRIKE)
        return true
    end
    
    -- Use Consecration if needed and not active
    if not consecrationActive and API.CanCast(spells.CONSECRATION) then
        API.CastSpell(spells.CONSECRATION)
        return true
    end
    
    return false
end

-- Handle specialization change
function Retribution:OnSpecializationChanged()
    -- Update talent information
    self:UpdateTalentInfo()
    
    -- Reset state variables
    nextCastOverride = nil
    burstModeActive = false
    currentHolyPower = API.GetPlayerPower()
    avengerActive = false
    crusadeActive = false
    crusadeStacks = 0
    executionSentenceActive = false
    wakeOfAshesAvailable = true
    durationExecutionSentence = 0
    lastExecutionSentenceTime = 0
    consecrationActive = false
    hammerOfWrathAvailable = false
    finalVerdictBuff = false
    divinePurposeBuff = false
    empyreanPowerBuff = false
    exorcismStacks = 0
    divineTollAvailable = true
    
    API.PrintDebug("Retribution Paladin state reset on spec change")
    
    return true
end

-- Return the module for loading
return Retribution