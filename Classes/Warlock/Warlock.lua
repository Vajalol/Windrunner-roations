------------------------------------------
-- WindrunnerRotations - Warlock Class Module
-- Author: VortexQ8
------------------------------------------

-- Create base class node in addon table
local addonName, addon = ...
if not addon.Classes then addon.Classes = {} end
addon.Classes.Warlock = {}

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl

-- Constants
local WARLOCK_CLASS_ID = 9 -- WoW class ID for Warlock

-- Initialize the class module
function addon.Classes.Warlock:Initialize()
    self:InitializeVariables()
    self:RegisterSpells()
    self:RegisterSettings()
    self:LoadSpecModules()
    
    -- Print initialization message for debugging
    API.PrintDebug("Warlock module initialized")
    
    return true
end

-- Initialize class-wide variables
function addon.Classes.Warlock:InitializeVariables()
    self.specModules = {}
    self.activeSpec = API.GetActiveSpecID()
    
    -- Cache commonly used spell IDs 
    self.spells = {
        -- General Warlock abilities
        CORRUPTION = 172,
        FEAR = 5782,
        CREATE_HEALTHSTONE = 6201,
        UNENDING_RESOLVE = 104773,
        DARK_PACT = 108416,
        SHADOWFURY = 30283,
        CURSE_OF_WEAKNESS = 702,
        CURSE_OF_TONGUES = 1714,
        CURSE_OF_EXHAUSTION = 334275,
        BANISH = 710,
        SUBJUGATE_DEMON = 1098,
        DEMONIC_GATEWAY = 111771,
        DEMONIC_CIRCLE = 48018,
        DEMONIC_CIRCLE_TELEPORT = 48020,
        BURNING_RUSH = 111400,
        DRAIN_LIFE = 234153,
        MORTAL_COIL = 6789,
        HOWL_OF_TERROR = 5484,
        SUMMON_IMP = 688,
        SUMMON_VOIDWALKER = 697,
        SUMMON_FELHUNTER = 691,
        SUMMON_SUCCUBUS = 712,
        HEALTHSTONE = 5512,
        UNENDING_BREATH = 5697,
        RITUAL_OF_SUMMONING = 698,
        SOULSTONE = 20707,
        
        -- Covenant abilities (Shadowlands)
        SOUL_ROT = 325640,
        DECIMATING_BOLT = 325289,
        SCOURING_TITHE = 312321,
        IMPENDING_CATASTROPHE = 321792
    }
    
    return true
end

-- Register spell effects and handlers
function addon.Classes.Warlock:RegisterSpells()
    -- Register general warlock spells for tracking
    API.RegisterSpell(self.spells.CORRUPTION)
    API.RegisterSpell(self.spells.FEAR)
    API.RegisterSpell(self.spells.CREATE_HEALTHSTONE)
    API.RegisterSpell(self.spells.UNENDING_RESOLVE)
    API.RegisterSpell(self.spells.DARK_PACT)
    API.RegisterSpell(self.spells.SHADOWFURY)
    API.RegisterSpell(self.spells.CURSE_OF_WEAKNESS)
    API.RegisterSpell(self.spells.CURSE_OF_TONGUES)
    API.RegisterSpell(self.spells.CURSE_OF_EXHAUSTION)
    API.RegisterSpell(self.spells.BANISH)
    API.RegisterSpell(self.spells.SUBJUGATE_DEMON)
    API.RegisterSpell(self.spells.DEMONIC_GATEWAY)
    API.RegisterSpell(self.spells.DEMONIC_CIRCLE)
    API.RegisterSpell(self.spells.DEMONIC_CIRCLE_TELEPORT)
    API.RegisterSpell(self.spells.BURNING_RUSH)
    API.RegisterSpell(self.spells.DRAIN_LIFE)
    API.RegisterSpell(self.spells.MORTAL_COIL)
    API.RegisterSpell(self.spells.HOWL_OF_TERROR)
    API.RegisterSpell(self.spells.SUMMON_IMP)
    API.RegisterSpell(self.spells.SUMMON_VOIDWALKER)
    API.RegisterSpell(self.spells.SUMMON_FELHUNTER)
    API.RegisterSpell(self.spells.SUMMON_SUCCUBUS)
    API.RegisterSpell(self.spells.HEALTHSTONE)
    API.RegisterSpell(self.spells.UNENDING_BREATH)
    API.RegisterSpell(self.spells.RITUAL_OF_SUMMONING)
    API.RegisterSpell(self.spells.SOULSTONE)
    
    -- Register covenant abilities
    API.RegisterSpell(self.spells.SOUL_ROT)
    API.RegisterSpell(self.spells.DECIMATING_BOLT)
    API.RegisterSpell(self.spells.SCOURING_TITHE)
    API.RegisterSpell(self.spells.IMPENDING_CATASTROPHE)
    
    return true
end

-- Register class-wide settings in the ConfigRegistry
function addon.Classes.Warlock:RegisterSettings()
    -- Class-wide settings group
    ConfigRegistry:RegisterSettings("Warlock", {
        generalSettings = {
            useSoulstone = {
                displayName = "Auto Soulstone",
                description = "Automatically use Soulstone on party members",
                type = "toggle",
                default = true
            },
            soulstoneTarget = {
                displayName = "Soulstone Target",
                description = "Who to prioritize for Soulstone",
                type = "dropdown",
                options = {"Healer", "Tank", "Self", "Random DPS"},
                default = "Healer"
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when in danger",
                type = "toggle",
                default = true
            },
            unendingResolveThreshold = {
                displayName = "Unending Resolve Threshold",
                description = "Health percentage to use Unending Resolve",
                type = "slider",
                min = 1,
                max = 100,
                default = 40
            },
            darkPactThreshold = {
                displayName = "Dark Pact Threshold",
                description = "Health percentage to use Dark Pact",
                type = "slider",
                min = 1,
                max = 100,
                default = 60
            },
            useHealthstone = {
                displayName = "Use Healthstone",
                description = "Automatically use Healthstone when health is low",
                type = "toggle",
                default = true
            },
            healthstoneThreshold = {
                displayName = "Healthstone Threshold",
                description = "Health percentage to use Healthstone",
                type = "slider",
                min = 1,
                max = 100,
                default = 30
            },
            maintainDefensiveCircle = {
                displayName = "Maintain Demonic Circle",
                description = "Automatically maintain Demonic Circle",
                type = "toggle",
                default = true
            },
            autoPetSummon = {
                displayName = "Auto Pet Summon",
                description = "Automatically summon your preferred demon",
                type = "toggle",
                default = true
            },
            preferredPet = {
                displayName = "Preferred Pet Type",
                description = "Your preferred demon pet",
                type = "dropdown",
                options = {"Imp", "Voidwalker", "Felhunter", "Succubus", "Spec Default"},
                default = "Spec Default"
            },
            interruptEnabled = {
                displayName = "Enable Interrupts",
                description = "Automatically interrupt with Spell Lock / Optical Blast",
                type = "toggle",
                default = true
            },
            interruptDelay = {
                displayName = "Interrupt Delay",
                description = "Random delay for interrupt (milliseconds)",
                type = "slider",
                min = 0,
                max = 1000,
                default = 200
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Shadowfury controls
            shadowfury = AAC.RegisterAbility(self.spells.SHADOWFURY, {
                enabled = true,
                minEnemies = 2,
                maxDistance = 30
            }),
            
            -- Fear controls
            fear = AAC.RegisterAbility(self.spells.FEAR, {
                enabled = true,
                useForEmergencyOnly = true,
                healthThreshold = 35
            }),
            
            -- Curse management
            curses = {
                useCurseOfWeakness = {
                    displayName = "Use Curse of Weakness",
                    description = "Apply Curse of Weakness on melee enemies",
                    type = "toggle",
                    default = true
                },
                useCurseOfTongues = {
                    displayName = "Use Curse of Tongues",
                    description = "Apply Curse of Tongues on casting enemies",
                    type = "toggle",
                    default = true
                },
                useCurseOfExhaustion = {
                    displayName = "Use Curse of Exhaustion",
                    description = "Apply Curse of Exhaustion on moving enemies",
                    type = "toggle",
                    default = true
                }
            }
        }
    })
    
    return true
end

-- Load specialization modules
function addon.Classes.Warlock:LoadSpecModules()
    -- Define spec IDs for Warlock
    local AFFLICTION_SPEC_ID = 265
    local DEMONOLOGY_SPEC_ID = 266
    local DESTRUCTION_SPEC_ID = 267
    
    -- Try to load each specialization module
    local specs = {
        [AFFLICTION_SPEC_ID] = "Affliction",
        [DEMONOLOGY_SPEC_ID] = "Demonology",
        [DESTRUCTION_SPEC_ID] = "Destruction"
    }
    
    -- Load the modules
    for specID, specName in pairs(specs) do
        -- Try to load and initialize the module
        local success, errorMsg = pcall(function()
            -- Require the spec module
            local specFile = string.format("Classes.Warlock.%s", specName)
            self.specModules[specID] = addon:RequireModule(specFile)
            
            -- Initialize if available
            if self.specModules[specID] and self.specModules[specID].Initialize then
                self.specModules[specID]:Initialize()
                API.PrintDebug("Loaded " .. specName .. " Warlock module")
            end
        end)
        
        -- Log errors if module loading failed
        if not success then
            API.PrintError("Failed to load " .. specName .. " Warlock module: " .. tostring(errorMsg))
        end
    end
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    return true
end

-- Handle specialization changes
function addon.Classes.Warlock:OnSpecializationChanged()
    local newSpecID = API.GetActiveSpecID()
    
    -- If spec changed, update active spec
    if newSpecID ~= self.activeSpec then
        API.PrintDebug("Warlock specialization changed to: " .. tostring(newSpecID))
        self.activeSpec = newSpecID
        
        -- Call spec-specific handlers if they exist
        if self.specModules[newSpecID] and self.specModules[newSpecID].OnSpecializationChanged then
            self.specModules[newSpecID]:OnSpecializationChanged()
        end
    end
    
    return true
end

-- Main rotation function - delegates to the active spec
function addon.Classes.Warlock:RunRotation()
    -- Check if we are a warlock
    if API.GetPlayerClass() ~= WARLOCK_CLASS_ID then
        return false
    end
    
    -- Handle general warlock logic first (defensives, pets, etc.)
    self:HandleGeneralAbilities()
    
    -- Run the specialization-specific rotation
    local activeSpec = self.activeSpec
    if self.specModules[activeSpec] and self.specModules[activeSpec].RunRotation then
        return self.specModules[activeSpec]:RunRotation()
    end
    
    return false
end

-- Handle general warlock abilities used across all specs
function addon.Classes.Warlock:HandleGeneralAbilities()
    -- Skip if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("Warlock")
    
    -- Handle Pet Summoning
    if settings.generalSettings.autoPetSummon and not API.PlayerHasPet() then
        local summonSpell = nil
        
        -- Determine which pet to summon
        if settings.generalSettings.preferredPet == "Imp" then
            summonSpell = self.spells.SUMMON_IMP
        elseif settings.generalSettings.preferredPet == "Voidwalker" then
            summonSpell = self.spells.SUMMON_VOIDWALKER
        elseif settings.generalSettings.preferredPet == "Felhunter" then
            summonSpell = self.spells.SUMMON_FELHUNTER
        elseif settings.generalSettings.preferredPet == "Succubus" then
            summonSpell = self.spells.SUMMON_SUCCUBUS
        else
            -- Spec Default pet logic
            local specID = self.activeSpec
            if specID == 265 then -- Affliction
                summonSpell = self.spells.SUMMON_FELHUNTER -- For interrupt
            elseif specID == 266 then -- Demonology
                summonSpell = self.spells.SUMMON_FELHUNTER -- For interrupt
            elseif specID == 267 then -- Destruction
                summonSpell = self.spells.SUMMON_IMP -- For bonus damage
            end
        end
        
        -- Summon the appropriate pet
        if summonSpell and API.CanCast(summonSpell) then
            API.CastSpell(summonSpell)
            return true
        end
    end
    
    -- Handle Defensive Abilities
    if settings.generalSettings.useDefensives then
        local healthPct = API.GetPlayerHealthPercent()
        
        -- Use Healthstone
        if settings.generalSettings.useHealthstone and 
           healthPct <= settings.generalSettings.healthstoneThreshold and
           API.CanUseItem(self.spells.HEALTHSTONE) then
            API.UseItem(self.spells.HEALTHSTONE)
            return true
        end
        
        -- Use Unending Resolve
        if healthPct <= settings.generalSettings.unendingResolveThreshold and
           API.CanCast(self.spells.UNENDING_RESOLVE) then
            API.CastSpell(self.spells.UNENDING_RESOLVE)
            return true
        end
        
        -- Use Dark Pact
        if healthPct <= settings.generalSettings.darkPactThreshold and
           API.HasTalent(self.spells.DARK_PACT) and
           API.CanCast(self.spells.DARK_PACT) then
            API.CastSpell(self.spells.DARK_PACT)
            return true
        end
        
        -- Use Fear for emergency CC
        if settings.abilityControls.fear.enabled and
           settings.abilityControls.fear.useForEmergencyOnly and
           healthPct <= settings.abilityControls.fear.healthThreshold and
           API.CanCast(self.spells.FEAR) and 
           not API.IsTargetCC() and 
           API.IsHostileTarget() then
            API.CastSpell(self.spells.FEAR)
            return true
        end
    end
    
    -- Maintain Demonic Circle
    if settings.generalSettings.maintainDefensiveCircle and
       not API.PlayerHasBuff(self.spells.DEMONIC_CIRCLE) and
       API.CanCast(self.spells.DEMONIC_CIRCLE) and
       not API.IsPlayerMoving() then
        API.CastSpell(self.spells.DEMONIC_CIRCLE)
        return true
    end
    
    -- Handle Shadowfury for CC
    if settings.abilityControls.shadowfury.enabled and
       API.CanCast(self.spells.SHADOWFURY) then
        
        local nearbyEnemies = API.GetNearbyEnemiesCount(10)
        if nearbyEnemies >= settings.abilityControls.shadowfury.minEnemies then
            API.CastSpellAtCursor(self.spells.SHADOWFURY)
            return true
        end
    end
    
    -- Handle Soulstone application
    if settings.generalSettings.useSoulstone and
       API.CanCast(self.spells.SOULSTONE) and
       not API.IsInCombat() then
        
        local targetToSoulstone = nil
        local targetRole = settings.generalSettings.soulstoneTarget
        
        -- Find the appropriate target based on role priority
        if targetRole == "Self" then
            targetToSoulstone = "player"
        else
            local groupSize = API.GetGroupSize()
            
            for i = 1, groupSize do
                local unit = API.GetGroupUnitID(i)
                local role = API.GetUnitRole(unit)
                
                if (targetRole == "Healer" and role == "HEALER") or
                   (targetRole == "Tank" and role == "TANK") or
                   (targetRole == "Random DPS" and role == "DAMAGER") then
                    if not API.UnitHasBuff(unit, self.spells.SOULSTONE) then
                        targetToSoulstone = unit
                        break
                    end
                end
            end
        end
        
        -- Apply Soulstone if we found a valid target
        if targetToSoulstone and not API.UnitHasBuff(targetToSoulstone, self.spells.SOULSTONE) then
            API.CastSpellOnUnit(self.spells.SOULSTONE, targetToSoulstone)
            return true
        end
    end
    
    -- Handle interrupts if Felhunter is active
    if settings.generalSettings.interruptEnabled and
       API.PlayerHasPet() and
       (API.GetPetType() == "Felhunter" or API.GetPetType() == "Imp") then
        
        -- Check if target is casting something interruptible
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and API.CanInterruptCurrentTarget() then
            local interruptSpell = API.GetPetType() == "Felhunter" and "Spell Lock" or "Optical Blast"
            
            -- Check if spell should be interrupted
            local shouldInterrupt, delayInterrupt = AAC.ShouldInterrupt(
                targetSpell,
                0 -- No minimum priority, interrupt everything
            )
            
            -- Add user configured delay
            delayInterrupt = delayInterrupt + math.random(0, settings.generalSettings.interruptDelay)
            
            if shouldInterrupt then
                -- Delay interrupt based on settings
                local timeLeft = targetCastEnd - GetTime()
                
                -- Make sure we don't delay too much
                delayInterrupt = math.min(delayInterrupt, (timeLeft - 0.1) * 1000)
                
                if delayInterrupt <= 0 then
                    API.CastPetSpell(interruptSpell)
                    return true
                else
                    C_Timer.After(delayInterrupt/1000, function()
                        API.CastPetSpell(interruptSpell)
                    end)
                    return true
                end
            end
        end
    end
    
    -- Handle curse applications
    local curseSettings = settings.abilityControls.curses
    local targetGUID = API.GetTargetGUID()
    
    if targetGUID and API.IsHostileTarget() then
        -- Check if target is a caster for Curse of Tongues
        if curseSettings.useCurseOfTongues and
           API.IsTargetCaster() and
           not API.UnitHasCurse(targetGUID) and
           API.CanCast(self.spells.CURSE_OF_TONGUES) then
            API.CastSpell(self.spells.CURSE_OF_TONGUES)
            return true
        end
        
        -- Check if target is melee for Curse of Weakness
        if curseSettings.useCurseOfWeakness and
           API.IsTargetMelee() and
           not API.UnitHasCurse(targetGUID) and
           API.CanCast(self.spells.CURSE_OF_WEAKNESS) then
            API.CastSpell(self.spells.CURSE_OF_WEAKNESS)
            return true
        end
        
        -- Check if target is moving for Curse of Exhaustion
        if curseSettings.useCurseOfExhaustion and
           API.IsTargetMoving() and
           not API.UnitHasCurse(targetGUID) and
           API.CanCast(self.spells.CURSE_OF_EXHAUSTION) then
            API.CastSpell(self.spells.CURSE_OF_EXHAUSTION)
            return true
        end
    end
    
    return false
end

-- Register the class with the addon
addon:RegisterClass("WARLOCK", addon.Classes.Warlock)