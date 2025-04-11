------------------------------------------
-- WindrunnerRotations - Death Knight Class Module
-- Author: VortexQ8
------------------------------------------

-- Create base class node in addon table
local addonName, addon = ...
if not addon.Classes then addon.Classes = {} end
addon.Classes.DeathKnight = {}

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl

-- Constants
local DK_CLASS_ID = 6 -- WoW class ID for Death Knight

-- Initialize the class module
function addon.Classes.DeathKnight:Initialize()
    self:InitializeVariables()
    self:RegisterSpells()
    self:RegisterSettings()
    self:LoadSpecModules()
    
    -- Print initialization message for debugging
    API.PrintDebug("Death Knight module initialized")
    
    return true
end

-- Initialize class-wide variables
function addon.Classes.DeathKnight:InitializeVariables()
    self.specModules = {}
    self.activeSpec = API.GetActiveSpecID()
    
    -- Cache commonly used spell IDs 
    self.spells = {
        -- General Death Knight abilities
        DEATH_STRIKE = 49998,
        DEATH_GRIP = 49576,
        DEATH_AND_DECAY = 43265,
        ANTI_MAGIC_SHELL = 48707,
        ICEBOUND_FORTITUDE = 48792,
        MIND_FREEZE = 47528,
        RAISE_DEAD = 46584,
        DEATH_GATE = 50977,
        CONTROL_UNDEAD = 111673,
        PATH_OF_FROST = 3714,
        LICHBORNE = 49039,
        WRAITH_WALK = 212552,
        CHAINS_OF_ICE = 45524,
        DEATH_COIL = 47541,
        DARK_COMMAND = 56222,
        RAISE_ALLY = 61999,
        
        -- Covenant abilities (Shadowlands)
        SWARMING_MIST = 311648,
        SHACKLE_THE_UNWORTHY = 312202,
        ABOMINATION_LIMB = 315443,
        DEATHS_DUE = 324128
    }
    
    return true
end

-- Register spell effects and handlers
function addon.Classes.DeathKnight:RegisterSpells()
    -- Register general death knight spells for tracking
    API.RegisterSpell(self.spells.DEATH_STRIKE)
    API.RegisterSpell(self.spells.DEATH_GRIP)
    API.RegisterSpell(self.spells.DEATH_AND_DECAY)
    API.RegisterSpell(self.spells.ANTI_MAGIC_SHELL)
    API.RegisterSpell(self.spells.ICEBOUND_FORTITUDE)
    API.RegisterSpell(self.spells.MIND_FREEZE)
    API.RegisterSpell(self.spells.RAISE_DEAD)
    API.RegisterSpell(self.spells.DEATH_GATE)
    API.RegisterSpell(self.spells.CONTROL_UNDEAD)
    API.RegisterSpell(self.spells.PATH_OF_FROST)
    API.RegisterSpell(self.spells.LICHBORNE)
    API.RegisterSpell(self.spells.WRAITH_WALK)
    API.RegisterSpell(self.spells.CHAINS_OF_ICE)
    API.RegisterSpell(self.spells.DEATH_COIL)
    API.RegisterSpell(self.spells.DARK_COMMAND)
    API.RegisterSpell(self.spells.RAISE_ALLY)
    
    -- Register covenant abilities
    API.RegisterSpell(self.spells.SWARMING_MIST)
    API.RegisterSpell(self.spells.SHACKLE_THE_UNWORTHY)
    API.RegisterSpell(self.spells.ABOMINATION_LIMB)
    API.RegisterSpell(self.spells.DEATHS_DUE)
    
    return true
end

-- Register class-wide settings in the ConfigRegistry
function addon.Classes.DeathKnight:RegisterSettings()
    -- Class-wide settings group
    ConfigRegistry:RegisterSettings("DeathKnight", {
        generalSettings = {
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when in danger",
                type = "toggle",
                default = true
            },
            amsCooldownThreshold = {
                displayName = "AMS Health Threshold",
                description = "Health percentage to use Anti-Magic Shell",
                type = "slider",
                min = 1,
                max = 100,
                default = 75
            },
            ibfCooldownThreshold = {
                displayName = "IBF Health Threshold",
                description = "Health percentage to use Icebound Fortitude",
                type = "slider",
                min = 1,
                max = 100,
                default = 50
            },
            useTaunt = {
                displayName = "Use Dark Command",
                description = "Automatically taunt enemies when they target allies",
                type = "toggle",
                default = false
            },
            useAutoRaise = {
                displayName = "Auto Raise Dead",
                description = "Automatically summon ghoul when it expires",
                type = "toggle",
                default = true
            },
            useRaiseAlly = {
                displayName = "Auto Battle Rez",
                description = "Auto raise dead allies in combat",
                type = "toggle",
                default = false
            },
            raiseAllyPriority = {
                displayName = "Raise Ally Priority",
                description = "Prioritize which roles to resurrect first",
                type = "dropdown",
                options = {"Healer,Tank,DPS", "Tank,Healer,DPS", "DPS,Healer,Tank"},
                default = "Healer,Tank,DPS"
            },
            interruptEnabled = {
                displayName = "Enable Interrupts",
                description = "Automatically interrupt enemy spellcasting with Mind Freeze",
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
            -- Anti-Magic Shell controls
            antiMagicShell = AAC.RegisterAbility(self.spells.ANTI_MAGIC_SHELL, {
                enabled = true,
                healthThreshold = 75,
                magicDamageOnly = true
            }),
            
            -- Icebound Fortitude controls
            iceboundFortitude = AAC.RegisterAbility(self.spells.ICEBOUND_FORTITUDE, {
                enabled = true,
                healthThreshold = 50,
                enemyCountThreshold = 3
            }),
            
            -- Wraith Walk controls
            wraithWalk = AAC.RegisterAbility(self.spells.WRAITH_WALK, {
                enabled = true,
                useWhileRooted = true,
                minMovementTime = 2
            })
        }
    })
    
    return true
end

-- Load specialization modules
function addon.Classes.DeathKnight:LoadSpecModules()
    -- Define spec IDs for Death Knight
    local BLOOD_SPEC_ID = 250
    local FROST_SPEC_ID = 251
    local UNHOLY_SPEC_ID = 252
    
    -- Try to load each specialization module
    local specs = {
        [BLOOD_SPEC_ID] = "Blood",
        [FROST_SPEC_ID] = "Frost",
        [UNHOLY_SPEC_ID] = "Unholy"
    }
    
    -- Load the modules
    for specID, specName in pairs(specs) do
        -- Try to load and initialize the module
        local success, errorMsg = pcall(function()
            -- Require the spec module
            local specFile = string.format("Classes.DeathKnight.%s", specName)
            self.specModules[specID] = addon:RequireModule(specFile)
            
            -- Initialize if available
            if self.specModules[specID] and self.specModules[specID].Initialize then
                self.specModules[specID]:Initialize()
                API.PrintDebug("Loaded " .. specName .. " Death Knight module")
            end
        end)
        
        -- Log errors if module loading failed
        if not success then
            API.PrintError("Failed to load " .. specName .. " Death Knight module: " .. tostring(errorMsg))
        end
    end
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    return true
end

-- Handle specialization changes
function addon.Classes.DeathKnight:OnSpecializationChanged()
    local newSpecID = API.GetActiveSpecID()
    
    -- If spec changed, update active spec
    if newSpecID ~= self.activeSpec then
        API.PrintDebug("Death Knight specialization changed to: " .. tostring(newSpecID))
        self.activeSpec = newSpecID
        
        -- Call spec-specific handlers if they exist
        if self.specModules[newSpecID] and self.specModules[newSpecID].OnSpecializationChanged then
            self.specModules[newSpecID]:OnSpecializationChanged()
        end
    end
    
    return true
end

-- Main rotation function - delegates to the active spec
function addon.Classes.DeathKnight:RunRotation()
    -- Check if we are a death knight
    if API.GetPlayerClass() ~= DK_CLASS_ID then
        return false
    end
    
    -- Handle general death knight logic first (defensives, pets, etc.)
    self:HandleGeneralAbilities()
    
    -- Run the specialization-specific rotation
    local activeSpec = self.activeSpec
    if self.specModules[activeSpec] and self.specModules[activeSpec].RunRotation then
        return self.specModules[activeSpec]:RunRotation()
    end
    
    return false
end

-- Handle general death knight abilities used across all specs
function addon.Classes.DeathKnight:HandleGeneralAbilities()
    -- Skip if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("DeathKnight")
    
    -- Handle Raise Dead if pet is dead
    if settings.generalSettings.useAutoRaise and not API.PlayerHasPet() and API.CanCast(self.spells.RAISE_DEAD) then
        API.CastSpell(self.spells.RAISE_DEAD)
        return true
    end
    
    -- Handle defensive cooldowns
    if settings.generalSettings.useDefensives then
        local healthPct = API.GetPlayerHealthPercent()
        
        -- Use Anti-Magic Shell
        if healthPct <= settings.abilityControls.antiMagicShell.healthThreshold and
           API.CanCast(self.spells.ANTI_MAGIC_SHELL) then
            
            -- Check if we're taking magic damage if setting enabled
            if not settings.abilityControls.antiMagicShell.magicDamageOnly or API.IsTakingMagicDamage() then
                API.CastSpell(self.spells.ANTI_MAGIC_SHELL)
                return true
            end
        end
        
        -- Use Icebound Fortitude
        if healthPct <= settings.abilityControls.iceboundFortitude.healthThreshold and
           API.CanCast(self.spells.ICEBOUND_FORTITUDE) then
            
            -- Check if there are enough enemies around if threshold set
            local enemyCount = API.GetNearbyEnemiesCount(8)
            if enemyCount >= settings.abilityControls.iceboundFortitude.enemyCountThreshold or
               healthPct <= settings.abilityControls.iceboundFortitude.healthThreshold / 2 then
                API.CastSpell(self.spells.ICEBOUND_FORTITUDE)
                return true
            end
        end
    end
    
    -- Handle mobility with Wraith Walk
    if settings.abilityControls.wraithWalk.enabled and
       API.CanCast(self.spells.WRAITH_WALK) then
        
        -- Check if player has been moving for long enough
        if API.IsPlayerMoving() and 
           API.GetPlayerMovingTime() >= settings.abilityControls.wraithWalk.minMovementTime then
            API.CastSpell(self.spells.WRAITH_WALK)
            return true
        end
        
        -- Use while rooted if enabled
        if settings.abilityControls.wraithWalk.useWhileRooted and API.IsUnitRooted("player") then
            API.CastSpell(self.spells.WRAITH_WALK)
            return true
        end
    end
    
    -- Handle taunting
    if settings.generalSettings.useTaunt and API.CanCast(self.spells.DARK_COMMAND) then
        -- Find an enemy targeting a friendly player
        local targetToTaunt = API.GetUnitNeedingTaunt()
        if targetToTaunt then
            API.CastSpellOnUnit(self.spells.DARK_COMMAND, targetToTaunt)
            return true
        end
    end
    
    -- Handle Raise Ally for battle rez
    if settings.generalSettings.useRaiseAlly and 
       API.IsInCombat() and 
       API.CanCast(self.spells.RAISE_ALLY) then
        
        -- Find a dead player to resurrect based on priority
        local priorityOrder = {}
        
        -- Parse priority string
        for role in string.gmatch(settings.generalSettings.raiseAllyPriority, "([^,]+)") do
            table.insert(priorityOrder, role:trim():upper())
        end
        
        local targetToRez = nil
        
        -- Check each role in priority order
        for _, role in ipairs(priorityOrder) do
            local groupSize = API.GetGroupSize()
            
            for i = 1, groupSize do
                local unit = API.GetGroupUnitID(i)
                if unit and API.UnitIsDead(unit) and API.GetUnitRole(unit) == role then
                    targetToRez = unit
                    break
                end
            end
            
            if targetToRez then
                break
            end
        end
        
        -- Cast Raise Ally if we found a target
        if targetToRez then
            API.CastSpellOnUnit(self.spells.RAISE_ALLY, targetToRez)
            return true
        end
    end
    
    -- Handle interrupts
    if settings.generalSettings.interruptEnabled then
        -- Check if target is casting something interruptible
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and API.CanCast(self.spells.MIND_FREEZE) and 
           API.CanInterruptCurrentTarget() then
            
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
                    API.CastSpell(self.spells.MIND_FREEZE)
                    return true
                else
                    C_Timer.After(delayInterrupt/1000, function()
                        API.CastSpell(self.spells.MIND_FREEZE)
                    end)
                    return true
                end
            end
        end
    end
    
    return false
end

-- Register the class with the addon
addon:RegisterClass("DEATHKNIGHT", addon.Classes.DeathKnight)