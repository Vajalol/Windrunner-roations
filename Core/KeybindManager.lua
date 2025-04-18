------------------------------------------
-- WindrunnerRotations - Keybind Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local KeybindManager = {}
WR.KeybindManager = KeybindManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local OneButtonMode = WR.OneButtonMode

-- Data storage
local keyBindings = {}
local registeredBindings = {}
local keybindCategories = {}
local lastKeyPress = 0
local keyPressThreshold = 0.15 -- Time in seconds to prevent key spamming
local keyToggleState = {}
local macroStorage = {}
local customBindingSet = "Default"
local bindingSets = {}
local bindingPrefix = "WINDRUNNERROTATIONS_"
local activeBindingMode = "normal"
local keybindFrame = nil
local keyGrabActive = false
local bindingsLoaded = false
local importExportFormat = 1.0
local keySequences = {}
local keySequenceActive = false
local keySequenceStep = 1
local keySequenceTimer = 0
local keySequenceTimeout = 1.0 -- Time for key sequence to reset
local keyCallback = {}
local KEY_MODIFIERS = {"SHIFT", "CTRL", "ALT"}
local KEY_MOUSE_BUTTONS = {"BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5"}

-- Binding types
local BIND_TYPE_ABILITY = "ability"
local BIND_TYPE_MACRO = "macro"
local BIND_TYPE_TOGGLE = "toggle"
local BIND_TYPE_TARGETING = "targeting"
local BIND_TYPE_SEQUENCE = "sequence"
local BIND_TYPE_ONE_BUTTON = "onebutton"

-- Binding modes
local BIND_MODE_NORMAL = "normal"
local BIND_MODE_COMBAT = "combat"
local BIND_MODE_STEALTH = "stealth"
local BIND_MODE_AOE = "aoe"
local BIND_MODE_DEFENSIVE = "defensive"
local BIND_MODE_BURST = "burst"

-- Initialize the Keybind Manager
function KeybindManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize keybind categories
    self:InitializeKeybindCategories()
    
    -- Initialize binding sets
    self:InitializeBindingSets()
    
    -- Load saved bindings
    self:LoadBindings()
    
    API.PrintDebug("Keybind Manager initialized")
    return true
end

-- Register settings
function KeybindManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("KeybindManager", {
        generalSettings = {
            enableCustomBindings = {
                displayName = "Enable Custom Keybinds",
                description = "Use custom keybinds for WindrunnerRotations",
                type = "toggle",
                default = true
            },
            keyPressThreshold = {
                displayName = "Key Press Threshold",
                description = "Minimum time between key presses (seconds)",
                type = "slider",
                min = 0.05,
                max = 0.5,
                step = 0.05,
                default = 0.15
            },
            activeBindingSet = {
                displayName = "Active Binding Set",
                description = "The current active binding set",
                type = "dropdown",
                options = {"Default", "PvE", "PvP", "Custom1", "Custom2"},
                default = "Default"
            },
            enableKeySequences = {
                displayName = "Enable Key Sequences",
                description = "Allow key sequences (press multiple keys in order)",
                type = "toggle",
                default = true
            },
            sequenceTimeout = {
                displayName = "Sequence Timeout",
                description = "Time before a key sequence resets (seconds)",
                type = "slider",
                min = 0.5,
                max = 3.0,
                step = 0.5,
                default = 1.0
            }
        },
        bindingBehavior = {
            prioritizeGameBindings = {
                displayName = "Prioritize Game Bindings",
                description = "Game keybinds take priority over addon keybinds",
                type = "toggle",
                default = false
            },
            shareBindings = {
                displayName = "Share Bindings Between Characters",
                description = "Use the same bindings for all characters",
                type = "toggle",
                default = false
            },
            bindingsPerSpec = {
                displayName = "Spec-Specific Bindings",
                description = "Use different bindings per specialization",
                type = "toggle",
                default = true
            },
            bindModifierKeys = {
                displayName = "Bind Modifier Keys",
                description = "Allow binding Shift, Ctrl, and Alt as primary keys",
                type = "toggle",
                default = false
            },
            bindingCooldown = {
                displayName = "Binding Cooldown",
                description = "Show cooldown swipe on keybind buttons",
                type = "toggle",
                default = true
            }
        },
        bindingModes = {
            enableBindingModes = {
                displayName = "Enable Binding Modes",
                description = "Allow different bindings based on combat state",
                type = "toggle",
                default = true
            },
            combatModeToggle = {
                displayName = "Combat Mode Toggle",
                description = "Key to toggle combat mode bindings",
                type = "keybind",
                default = ""
            },
            aoeModeToggle = {
                displayName = "AoE Mode Toggle",
                description = "Key to toggle AoE mode bindings",
                type = "keybind",
                default = ""
            },
            defensiveModeToggle = {
                displayName = "Defensive Mode Toggle",
                description = "Key to toggle defensive mode bindings",
                type = "keybind",
                default = ""
            },
            burstModeToggle = {
                displayName = "Burst Mode Toggle",
                description = "Key to toggle burst mode bindings",
                type = "keybind",
                default = ""
            },
            stealthModeToggle = {
                displayName = "Stealth Mode Toggle",
                description = "Key to toggle stealth mode bindings",
                type = "keybind",
                default = ""
            }
        },
        advancedSettings = {
            keybindAnimations = {
                displayName = "Keybind Animations",
                description = "Show animations when keybinds are pressed",
                type = "toggle",
                default = true
            },
            keybindSounds = {
                displayName = "Keybind Sounds",
                description = "Play sounds when keybinds are pressed",
                type = "toggle",
                default = true
            },
            debugKeybindEvents = {
                displayName = "Debug Keybind Events",
                description = "Show debug messages for keybind events",
                type = "toggle",
                default = false
            },
            clearAllBindings = {
                displayName = "Clear All Bindings",
                description = "Reset all keybindings to default",
                type = "button",
                func = function() KeybindManager:ClearAllBindings() end
            }
        }
    })
end

-- Register for events
function KeybindManager:RegisterEvents()
    -- Register for UI events
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:OnPlayerEnteringWorld()
    end)
    
    -- Register for spec change
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnLeaveCombat()
    end)
    
    -- Register for stealth events
    API.RegisterEvent("UPDATE_STEALTH", function()
        self:OnStealthUpdate()
    end)
    
    -- Register for keybinding changes
    API.RegisterEvent("UPDATE_BINDINGS", function()
        self:OnBindingsChanged()
    end)
    
    -- Set up key press handler
    self:SetupKeyHandler()
}

-- Initialize keybind categories
function KeybindManager:InitializeKeybindCategories()
    keybindCategories = {
        general = {
            name = "General",
            description = "General rotation controls and toggles",
            bindings = {}
        },
        abilities = {
            name = "Abilities",
            description = "Class and spec specific abilities",
            bindings = {}
        },
        targeting = {
            name = "Targeting",
            description = "Target selection and focusing",
            bindings = {}
        },
        movement = {
            name = "Movement",
            description = "Movement and positioning abilities",
            bindings = {}
        },
        defensive = {
            name = "Defensive",
            description = "Defensive and survival abilities",
            bindings = {}
        },
        utility = {
            name = "Utility",
            description = "Utility and miscellaneous abilities",
            bindings = {}
        },
        onebutton = {
            name = "One-Button Mode",
            description = "One-button rotation bindings",
            bindings = {}
        },
        macros = {
            name = "Custom Macros",
            description = "User-defined custom macros",
            bindings = {}
        }
    }
}

-- Initialize binding sets
function KeybindManager:InitializeBindingSets()
    bindingSets = {
        ["Default"] = {
            name = "Default",
            description = "Default keybinding set",
            bindings = {}
        },
        ["PvE"] = {
            name = "PvE",
            description = "PvE-focused keybinding set",
            bindings = {}
        },
        ["PvP"] = {
            name = "PvP",
            description = "PvP-focused keybinding set",
            bindings = {}
        },
        ["Custom1"] = {
            name = "Custom 1",
            description = "Custom keybinding set 1",
            bindings = {}
        },
        ["Custom2"] = {
            name = "Custom 2",
            description = "Custom keybinding set 2",
            bindings = {}
        }
    }
    
    -- Set active binding set from settings
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    customBindingSet = settings.generalSettings.activeBindingSet
}

-- Setup key handler
function KeybindManager:SetupKeyHandler()
    -- Create hidden frame for key input
    if not keybindFrame then
        keybindFrame = CreateFrame("Frame", "WindrunnerRotationsKeybindFrame", UIParent)
        keybindFrame:SetScript("OnKeyDown", function(self, key)
            KeybindManager:OnKeyPress(key, true)
        end)
        keybindFrame:SetScript("OnKeyUp", function(self, key)
            KeybindManager:OnKeyPress(key, false)
        end)
        keybindFrame:SetPropagateKeyboardInput(true)
        keybindFrame:EnableKeyboard(true)
        
        -- Allow clicking
        keybindFrame:EnableMouse(true)
        keybindFrame:RegisterForClicks("AnyDown", "AnyUp")
        
        for _, button in ipairs(KEY_MOUSE_BUTTONS) do
            keybindFrame:SetScript("OnClick", function(self, mouseButton)
                KeybindManager:OnMouseClick(mouseButton)
            end)
        end
    end
}

-- On player entering world
function KeybindManager:OnPlayerEnteringWorld()
    -- Reload settings
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    keyPressThreshold = settings.generalSettings.keyPressThreshold
    customBindingSet = settings.generalSettings.activeBindingSet
    keySequenceTimeout = settings.generalSettings.sequenceTimeout
    
    -- Check binding mode based on player state
    self:UpdateBindingMode()
    
    -- Register default bindings if none exist
    if not bindingsLoaded then
        self:RegisterDefaultBindings()
        bindingsLoaded = true
    end
}

-- On specialization changed
function KeybindManager:OnSpecializationChanged()
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    -- If spec-specific bindings are enabled, load them
    if settings.bindingBehavior.bindingsPerSpec then
        self:LoadBindings()
    end
    
    -- Register default bindings for this spec if needed
    self:RegisterSpecBindings()
}

-- On enter combat
function KeybindManager:OnEnterCombat()
    -- Update binding mode if we're using combat mode
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    if settings.bindingModes.enableBindingModes then
        activeBindingMode = BIND_MODE_COMBAT
    end
}

-- On leave combat
function KeybindManager:OnLeaveCombat()
    -- Update binding mode if we're using combat mode
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    if settings.bindingModes.enableBindingModes then
        activeBindingMode = BIND_MODE_NORMAL
    end
}

-- On stealth update
function KeybindManager:OnStealthUpdate()
    -- Update binding mode if stealth changed
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    if settings.bindingModes.enableBindingModes then
        if IsStealthed() then
            activeBindingMode = BIND_MODE_STEALTH
        else
            activeBindingMode = UnitAffectingCombat("player") and BIND_MODE_COMBAT or BIND_MODE_NORMAL
        end
    end
}

-- On bindings changed
function KeybindManager:OnBindingsChanged()
    -- Refresh our binding state
    self:LoadBindings()
}

-- On key press
function KeybindManager:OnKeyPress(key, isDown)
    local now = GetTime()
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    -- Skip if custom bindings are disabled
    if not settings.generalSettings.enableCustomBindings then
        return
    end
    
    -- If key grabbing active, handle it specially
    if keyGrabActive then
        self:HandleKeyGrab(key, isDown)
        return
    end
    
    -- Skip if this is a key up event (we only care about key down)
    if not isDown then
        return
    end
    
    -- Check for modifier keys
    local modifierKey = false
    for _, modifier in ipairs(KEY_MODIFIERS) do
        if key == modifier then
            modifierKey = true
            break
        end
    end
    
    -- Skip if this is a modifier key press and we don't allow binding modifiers
    if modifierKey and not settings.bindingBehavior.bindModifierKeys then
        return
    end
    
    -- Get active modifiers
    local modifiers = self:GetActiveModifiers()
    
    -- Build key combination
    local keyCombination = self:BuildKeyCombination(key, modifiers)
    
    -- Check for mode toggle keys
    if settings.bindingModes.enableBindingModes then
        if keyCombination == settings.bindingModes.combatModeToggle then
            self:ToggleBindingMode(BIND_MODE_COMBAT)
            return
        elseif keyCombination == settings.bindingModes.aoeModeToggle then
            self:ToggleBindingMode(BIND_MODE_AOE)
            return
        elseif keyCombination == settings.bindingModes.defensiveModeToggle then
            self:ToggleBindingMode(BIND_MODE_DEFENSIVE)
            return
        elseif keyCombination == settings.bindingModes.burstModeToggle then
            self:ToggleBindingMode(BIND_MODE_BURST)
            return
        elseif keyCombination == settings.bindingModes.stealthModeToggle then
            self:ToggleBindingMode(BIND_MODE_STEALTH)
            return
        end
    end
    
    -- Check for key sequences
    if settings.generalSettings.enableKeySequences then
        -- Update key sequence timer
        if now - keySequenceTimer > keySequenceTimeout then
            keySequenceActive = false
            keySequenceStep = 1
        end
        
        -- Update the timer
        keySequenceTimer = now
        
        -- Check for an active sequence
        if keySequenceActive then
            self:HandleKeySequence(keyCombination)
            return
        end
        
        -- Check if this key starts a sequence
        if self:CheckForKeySequence(keyCombination) then
            keySequenceActive = true
            keySequenceStep = 2 -- We've already processed step 1
            return
        end
    end
    
    -- Check for registered bindings
    local binding = self:GetBindingForKey(keyCombination)
    
    if binding then
        -- Check if enough time has passed since last press
        if now - lastKeyPress >= keyPressThreshold then
            self:ExecuteBinding(binding)
            lastKeyPress = now
            return
        end
    end
}

-- On mouse click
function KeybindManager:OnMouseClick(button)
    -- Handle mouse button same as key press
    self:OnKeyPress(button, true)
}

-- Update binding mode
function KeybindManager:UpdateBindingMode()
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    if not settings.bindingModes.enableBindingModes then
        activeBindingMode = BIND_MODE_NORMAL
        return
    end
    
    -- Determine binding mode based on player state
    if IsStealthed() then
        activeBindingMode = BIND_MODE_STEALTH
    elseif UnitAffectingCombat("player") then
        activeBindingMode = BIND_MODE_COMBAT
    else
        activeBindingMode = BIND_MODE_NORMAL
    end
}

-- Toggle binding mode
function KeybindManager:ToggleBindingMode(mode)
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    if not settings.bindingModes.enableBindingModes then
        return
    end
    
    -- Toggle the requested mode
    if activeBindingMode == mode then
        -- Toggle off, return to normal/combat based on state
        if UnitAffectingCombat("player") then
            activeBindingMode = BIND_MODE_COMBAT
        else
            activeBindingMode = BIND_MODE_NORMAL
        end
    else
        -- Toggle on
        activeBindingMode = mode
    end
    
    -- Notify of mode change
    API.PrintMessage("Binding mode changed to: " .. activeBindingMode)
}

-- Get active modifiers
function KeybindManager:GetActiveModifiers()
    local modifiers = {}
    
    if IsShiftKeyDown() then
        table.insert(modifiers, "SHIFT")
    end
    
    if IsControlKeyDown() then
        table.insert(modifiers, "CTRL")
    end
    
    if IsAltKeyDown() then
        table.insert(modifiers, "ALT")
    end
    
    return modifiers
end

-- Build key combination
function KeybindManager:BuildKeyCombination(key, modifiers)
    -- Start with the key
    local combination = key
    
    -- Add modifiers in a consistent order
    if tContains(modifiers, "SHIFT") then
        combination = "SHIFT-" .. combination
    end
    
    if tContains(modifiers, "CTRL") then
        combination = "CTRL-" .. combination
    end
    
    if tContains(modifiers, "ALT") then
        combination = "ALT-" .. combination
    end
    
    return combination
end

-- Get binding for key
function KeybindManager:GetBindingForKey(keyCombination)
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    -- First check current binding mode
    if settings.bindingModes.enableBindingModes and activeBindingMode ~= BIND_MODE_NORMAL then
        -- Check mode-specific bindings
        local modeBindings = registeredBindings[activeBindingMode]
        if modeBindings and modeBindings[keyCombination] then
            return modeBindings[keyCombination]
        end
    end
    
    -- Check normal bindings
    local normalBindings = registeredBindings[BIND_MODE_NORMAL]
    if normalBindings and normalBindings[keyCombination] then
        return normalBindings[keyCombination]
    end
    
    return nil
end

-- Execute binding
function KeybindManager:ExecuteBinding(binding)
    -- Debug output
    if ConfigRegistry:GetSettings("KeybindManager").advancedSettings.debugKeybindEvents then
        API.PrintDebug("Executing binding: " .. binding.name)
    end
    
    -- Check binding type
    if binding.type == BIND_TYPE_ABILITY then
        self:ExecuteAbilityBinding(binding)
    elseif binding.type == BIND_TYPE_MACRO then
        self:ExecuteMacroBinding(binding)
    elseif binding.type == BIND_TYPE_TOGGLE then
        self:ExecuteToggleBinding(binding)
    elseif binding.type == BIND_TYPE_TARGETING then
        self:ExecuteTargetingBinding(binding)
    elseif binding.type == BIND_TYPE_SEQUENCE then
        self:ExecuteSequenceBinding(binding)
    elseif binding.type == BIND_TYPE_ONE_BUTTON then
        self:ExecuteOneButtonBinding(binding)
    end
    
    -- Play keybind sound if enabled
    if ConfigRegistry:GetSettings("KeybindManager").advancedSettings.keybindSounds then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    
    -- Call any registered callbacks
    if binding.id and keyCallback[binding.id] then
        keyCallback[binding.id](binding)
    end
}

-- Execute ability binding
function KeybindManager:ExecuteAbilityBinding(binding)
    -- Execute the spell
    if binding.spell then
        local spellName = GetSpellInfo(binding.spell)
        if spellName then
            -- Check if we need a target
            if binding.requiresTarget and (not UnitExists("target") or UnitIsDead("target")) then
                API.PrintMessage("Ability requires a valid target")
                return
            end
            
            -- Execute the spell
            if binding.target then
                CastSpellByName(spellName, binding.target)
            else
                CastSpellByName(spellName)
            end
        else
            API.PrintMessage("Spell not found: " .. binding.spell)
        end
    end
end

-- Execute macro binding
function KeybindManager:ExecuteMacroBinding(binding)
    -- Execute the macro
    if binding.macro then
        -- Run the macro text
        RunMacroText(binding.macro)
    elseif binding.macroName then
        -- Run the saved macro
        RunMacro(binding.macroName)
    end
end

-- Execute toggle binding
function KeybindManager:ExecuteToggleBinding(binding)
    -- Execute the toggle
    if binding.toggle then
        -- Check if the toggle exists
        if WR[binding.toggle] then
            -- Call the toggle function if it exists
            if WR[binding.toggle].Toggle then
                local state = WR[binding.toggle]:Toggle()
                API.PrintMessage(binding.name .. " " .. (state and "Enabled" or "Disabled"))
            end
        else
            -- Simple toggle state
            local currentState = keyToggleState[binding.toggle] or false
            keyToggleState[binding.toggle] = not currentState
            API.PrintMessage(binding.name .. " " .. (keyToggleState[binding.toggle] and "Enabled" or "Disabled"))
        end
    end
}

-- Execute targeting binding
function KeybindManager:ExecuteTargetingBinding(binding)
    -- Execute the targeting action
    if binding.action == "target_nearest" then
        TargetNearestEnemy()
    elseif binding.action == "target_nearest_friend" then
        TargetNearestFriend()
    elseif binding.action == "target_focus" then
        if UnitExists("focus") then
            TargetUnit("focus")
        end
    elseif binding.action == "set_focus" then
        if UnitExists("target") then
            FocusUnit("target")
        end
    elseif binding.action == "target_previous" then
        TargetLastTarget()
    elseif binding.action == "clear_target" then
        ClearTarget()
    elseif binding.action == "target_by_name" and binding.name then
        TargetByName(binding.name, true)
    elseif binding.action == "target_auto" and WR.AutoTargeting then
        -- Use AutoTargeting if available
        if WR.AutoTargeting.FindAndSetTarget then
            WR.AutoTargeting:FindAndSetTarget()
        end
    elseif binding.action == "target_mouseover" then
        if UnitExists("mouseover") then
            TargetUnit("mouseover")
        end
    end
end

-- Execute sequence binding
function KeybindManager:ExecuteSequenceBinding(binding)
    -- Execute the sequence one step at a time
    if binding.sequence and binding.sequence[1] then
        -- Find the current binding to execute
        local currentBind = binding.sequence[1]
        
        -- Execute the first binding in the sequence
        self:ExecuteBinding(currentBind)
        
        -- If there are more bindings in the sequence, shift the sequence
        if #binding.sequence > 1 then
            -- Remove the first binding
            table.remove(binding.sequence, 1)
            
            -- Add it to the end
            table.insert(binding.sequence, currentBind)
        end
    end
}

-- Execute one-button binding
function KeybindManager:ExecuteOneButtonBinding(binding)
    -- Use OneButtonMode if available
    if OneButtonMode and OneButtonMode.ExecuteOneButtonAction then
        OneButtonMode:ExecuteOneButtonAction(binding.action, binding.target, binding.options)
    else
        API.PrintMessage("One-Button Mode not available")
    end
}

-- Handle key grab
function KeybindManager:HandleKeyGrab(key, isDown)
    -- Only process key down events for key grabbing
    if not isDown then
        return
    end
    
    -- Don't grab modifier keys
    if key == "SHIFT" or key == "CTRL" or key == "ALT" then
        return
    end
    
    -- Get active modifiers
    local modifiers = self:GetActiveModifiers()
    
    -- Build key combination
    local keyCombination = self:BuildKeyCombination(key, modifiers)
    
    -- Callback function with the grabbed key
    if keyGrabActive and keyGrabActive.callback then
        keyGrabActive.callback(keyCombination)
    end
    
    -- Reset key grabbing
    keyGrabActive = false
    
    -- Re-enable normal keyboard propagation
    keybindFrame:SetPropagateKeyboardInput(true)
}

-- Handle key sequence
function KeybindManager:HandleKeySequence(keyCombination)
    -- Check for active sequences
    for _, sequence in pairs(keySequences) do
        -- Check if this key matches the next step
        if sequence.keys[keySequenceStep] == keyCombination then
            -- If we've reached the end of the sequence, execute it
            if keySequenceStep >= #sequence.keys then
                self:ExecuteBinding(sequence.binding)
                
                -- Reset sequence state
                keySequenceActive = false
                keySequenceStep = 1
                return true
            else
                -- Move to next step
                keySequenceStep = keySequenceStep + 1
                return true
            end
        end
    end
    
    -- No match found, reset sequence
    keySequenceActive = false
    keySequenceStep = 1
    return false
}

-- Check for key sequence
function KeybindManager:CheckForKeySequence(keyCombination)
    -- Check if this key starts any sequence
    for _, sequence in pairs(keySequences) do
        if sequence.keys[1] == keyCombination then
            return true
        end
    end
    
    return false
}

-- Start key grab
function KeybindManager:StartKeyGrab(callback, prompt)
    keyGrabActive = {
        callback = callback,
        prompt = prompt or "Press a key to bind"
    }
    
    -- Disable normal keyboard propagation during key grabbing
    keybindFrame:SetPropagateKeyboardInput(false)
    
    -- Give the frame focus
    keybindFrame:EnableKeyboard(true)
    
    -- Display prompt
    API.PrintMessage(keyGrabActive.prompt)
}

-- Stop key grab
function KeybindManager:StopKeyGrab()
    keyGrabActive = false
    
    -- Re-enable normal keyboard propagation
    keybindFrame:SetPropagateKeyboardInput(true)
}

-- Load bindings
function KeybindManager:LoadBindings()
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    -- Clear registered bindings
    registeredBindings = {}
    
    -- Initialize binding modes
    registeredBindings[BIND_MODE_NORMAL] = {}
    registeredBindings[BIND_MODE_COMBAT] = {}
    registeredBindings[BIND_MODE_STEALTH] = {}
    registeredBindings[BIND_MODE_AOE] = {}
    registeredBindings[BIND_MODE_DEFENSIVE] = {}
    registeredBindings[BIND_MODE_BURST] = {}
    
    -- Load character-specific or account-wide bindings
    local bindingScope = settings.bindingBehavior.shareBindings and "account" or "character"
    
    -- Load spec-specific bindings if enabled
    local specSuffix = ""
    if settings.bindingBehavior.bindingsPerSpec then
        local currentSpec = API.GetActiveSpecID()
        specSuffix = "_" .. (currentSpec or "1")
    end
    
    -- Determine binding set to use
    local activeSet = customBindingSet or "Default"
    
    -- Load from saved variables (would normally load from actual SavedVariables)
    local savedBindings = bindingSets[activeSet].bindings
    
    -- Register the bindings
    if savedBindings then
        for mode, modeBindings in pairs(savedBindings) do
            for key, binding in pairs(modeBindings) do
                -- Make sure the mode exists
                if not registeredBindings[mode] then
                    registeredBindings[mode] = {}
                end
                
                -- Register the binding
                registeredBindings[mode][key] = binding
            end
        end
    end
    
    -- Load default bindings if none found
    if not next(registeredBindings[BIND_MODE_NORMAL]) then
        self:RegisterDefaultBindings()
    end
    
    -- Load spec-specific bindings
    self:RegisterSpecBindings()
}

-- Save bindings
function KeybindManager:SaveBindings()
    local settings = ConfigRegistry:GetSettings("KeybindManager")
    
    -- Determine binding set to use
    local activeSet = customBindingSet or "Default"
    
    -- Save bindings for current set
    bindingSets[activeSet].bindings = registeredBindings
    
    -- In a real addon, we would update SavedVariables here
    API.PrintMessage("Keybindings saved")
}

-- Register binding
function KeybindManager:RegisterBinding(binding, key, mode)
    -- Skip if invalid binding
    if not binding or not binding.id or not key then
        return false
    end
    
    -- Default to normal mode
    mode = mode or BIND_MODE_NORMAL
    
    -- Make sure the mode exists
    if not registeredBindings[mode] then
        registeredBindings[mode] = {}
    end
    
    -- Register the binding
    registeredBindings[mode][key] = binding
    
    -- Add to appropriate category
    if binding.category and keybindCategories[binding.category] then
        keybindCategories[binding.category].bindings[binding.id] = binding
    else
        -- Default to general category
        keybindCategories.general.bindings[binding.id] = binding
    end
    
    return true
end

-- Register default bindings
function KeybindManager:RegisterDefaultBindings()
    -- Register general bindings
    self:RegisterBinding({
        id = "toggle_auto_targeting",
        name = "Toggle Auto Targeting",
        description = "Toggle automatic targeting on/off",
        type = BIND_TYPE_TOGGLE,
        toggle = "AutoTargeting",
        category = "general"
    }, "CTRL-T", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "toggle_interrupt",
        name = "Toggle Interrupts",
        description = "Toggle automatic interrupting on/off",
        type = BIND_TYPE_TOGGLE,
        toggle = "InterruptManager",
        category = "general"
    }, "CTRL-I", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "toggle_aoe",
        name = "Toggle AoE Mode",
        description = "Toggle AoE rotation mode on/off",
        type = BIND_TYPE_TOGGLE,
        toggle = "aoeMode",
        category = "general"
    }, "CTRL-X", BIND_MODE_NORMAL)
    
    -- Register targeting bindings
    self:RegisterBinding({
        id = "target_nearest",
        name = "Target Nearest Enemy",
        description = "Target the nearest enemy",
        type = BIND_TYPE_TARGETING,
        action = "target_nearest",
        category = "targeting"
    }, "TAB", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "target_nearest_friend",
        name = "Target Nearest Friend",
        description = "Target the nearest friendly unit",
        type = BIND_TYPE_TARGETING,
        action = "target_nearest_friend",
        category = "targeting"
    }, "CTRL-TAB", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "auto_target",
        name = "Smart Target",
        description = "Use smart targeting to find the best target",
        type = BIND_TYPE_TARGETING,
        action = "target_auto",
        category = "targeting"
    }, "SHIFT-TAB", BIND_MODE_NORMAL)
    
    -- Register one-button mode bindings
    self:RegisterBinding({
        id = "onebutton_main",
        name = "One-Button Main",
        description = "Execute main One-Button rotation",
        type = BIND_TYPE_ONE_BUTTON,
        action = "main",
        category = "onebutton"
    }, "F1", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "onebutton_aoe",
        name = "One-Button AoE",
        description = "Execute AoE One-Button rotation",
        type = BIND_TYPE_ONE_BUTTON,
        action = "aoe",
        category = "onebutton"
    }, "F2", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "onebutton_defensive",
        name = "One-Button Defensive",
        description = "Execute defensive One-Button rotation",
        type = BIND_TYPE_ONE_BUTTON,
        action = "defensive",
        category = "onebutton"
    }, "F3", BIND_MODE_NORMAL)
    
    -- Register common movement/utility keybinds
    self:RegisterBinding({
        id = "movement_forward",
        name = "Move Forward",
        description = "Move character forward",
        type = BIND_TYPE_MACRO,
        macro = "/run MoveForwardStart() C_Timer.After(0.1, MoveForwardStop)",
        category = "movement"
    }, "W", BIND_MODE_NORMAL)
    
    -- Register macro keybinds
    self:RegisterBinding({
        id = "macro_focus_interrupt",
        name = "Interrupt Focus",
        description = "Interrupt focus target if casting",
        type = BIND_TYPE_MACRO,
        macro = "/stopcasting\n/cast [@focus,harm,nodead][] Counterspell",
        category = "macros"
    }, "SHIFT-I", BIND_MODE_NORMAL)
}

-- Register spec bindings
function KeybindManager:RegisterSpecBindings()
    -- Get player spec
    local _, playerClass = UnitClass("player")
    local currentSpec = API.GetActiveSpecID()
    
    if not playerClass or not currentSpec then
        return
    end
    
    -- Register class/spec-specific bindings
    if playerClass == "MAGE" then
        if currentSpec == 1 then  -- Arcane
            self:RegisterArcaneSpecBindings()
        elseif currentSpec == 2 then  -- Fire
            self:RegisterFireSpecBindings()
        elseif currentSpec == 3 then  -- Frost
            self:RegisterFrostSpecBindings()
        end
    elseif playerClass == "WARRIOR" then
        if currentSpec == 1 then  -- Arms
            self:RegisterArmsSpecBindings()
        elseif currentSpec == 2 then  -- Fury
            self:RegisterFurySpecBindings()
        elseif currentSpec == 3 then  -- Protection
            self:RegisterProtWarSpecBindings()
        end
    elseif playerClass == "PALADIN" then
        if currentSpec == 1 then  -- Holy
            self:RegisterHolyPalSpecBindings()
        elseif currentSpec == 2 then  -- Protection
            self:RegisterProtPalSpecBindings()
        elseif currentSpec == 3 then  -- Retribution
            self:RegisterRetSpecBindings()
        end
    elseif playerClass == "PRIEST" then
        if currentSpec == 1 then  -- Discipline
            self:RegisterDiscSpecBindings()
        elseif currentSpec == 2 then  -- Holy
            self:RegisterHolyPriestSpecBindings()
        elseif currentSpec == 3 then  -- Shadow
            self:RegisterShadowSpecBindings()
        end
    end
    
    -- Other classes would be implemented similarly
}

-- Register Arcane mage bindings
function KeybindManager:RegisterArcaneSpecBindings()
    -- Core rotation abilities
    self:RegisterBinding({
        id = "arcane_blast",
        name = "Arcane Blast",
        description = "Cast Arcane Blast",
        type = BIND_TYPE_ABILITY,
        spell = 30451,
        requiresTarget = true,
        category = "abilities"
    }, "1", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "arcane_barrage",
        name = "Arcane Barrage",
        description = "Cast Arcane Barrage",
        type = BIND_TYPE_ABILITY,
        spell = 44425,
        requiresTarget = true,
        category = "abilities"
    }, "2", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "arcane_missiles",
        name = "Arcane Missiles",
        description = "Cast Arcane Missiles",
        type = BIND_TYPE_ABILITY,
        spell = 5143,
        requiresTarget = true,
        category = "abilities"
    }, "3", BIND_MODE_NORMAL)
    
    -- Cooldowns
    self:RegisterBinding({
        id = "arcane_power",
        name = "Arcane Power",
        description = "Cast Arcane Power",
        type = BIND_TYPE_ABILITY,
        spell = 12042,
        category = "abilities"
    }, "4", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "presence_of_mind",
        name = "Presence of Mind",
        description = "Cast Presence of Mind",
        type = BIND_TYPE_ABILITY,
        spell = 205025,
        category = "abilities"
    }, "5", BIND_MODE_NORMAL)
    
    -- AoE
    self:RegisterBinding({
        id = "arcane_explosion",
        name = "Arcane Explosion",
        description = "Cast Arcane Explosion",
        type = BIND_TYPE_ABILITY,
        spell = 1449,
        category = "abilities"
    }, "1", BIND_MODE_AOE)
    
    -- Defensive
    self:RegisterBinding({
        id = "ice_block",
        name = "Ice Block",
        description = "Cast Ice Block",
        type = BIND_TYPE_ABILITY,
        spell = 45438,
        category = "defensive"
    }, "1", BIND_MODE_DEFENSIVE)
}

-- Register Fire mage bindings
function KeybindManager:RegisterFireSpecBindings()
    -- Core rotation abilities
    self:RegisterBinding({
        id = "fireball",
        name = "Fireball",
        description = "Cast Fireball",
        type = BIND_TYPE_ABILITY,
        spell = 133,
        requiresTarget = true,
        category = "abilities"
    }, "1", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "fire_blast",
        name = "Fire Blast",
        description = "Cast Fire Blast",
        type = BIND_TYPE_ABILITY,
        spell = 108853,
        requiresTarget = true,
        category = "abilities"
    }, "2", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "pyroblast",
        name = "Pyroblast",
        description = "Cast Pyroblast",
        type = BIND_TYPE_ABILITY,
        spell = 11366,
        requiresTarget = true,
        category = "abilities"
    }, "3", BIND_MODE_NORMAL)
    
    -- Cooldowns
    self:RegisterBinding({
        id = "combustion",
        name = "Combustion",
        description = "Cast Combustion",
        type = BIND_TYPE_ABILITY,
        spell = 190319,
        category = "abilities"
    }, "4", BIND_MODE_NORMAL)
    
    -- AoE
    self:RegisterBinding({
        id = "flamestrike",
        name = "Flamestrike",
        description = "Cast Flamestrike",
        type = BIND_TYPE_ABILITY,
        spell = 2120,
        category = "abilities"
    }, "1", BIND_MODE_AOE)
    
    -- Defensive
    self:RegisterBinding({
        id = "ice_block",
        name = "Ice Block",
        description = "Cast Ice Block",
        type = BIND_TYPE_ABILITY,
        spell = 45438,
        category = "defensive"
    }, "1", BIND_MODE_DEFENSIVE)
}

-- Register Frost mage bindings
function KeybindManager:RegisterFrostSpecBindings()
    -- Core rotation abilities
    self:RegisterBinding({
        id = "frostbolt",
        name = "Frostbolt",
        description = "Cast Frostbolt",
        type = BIND_TYPE_ABILITY,
        spell = 116,
        requiresTarget = true,
        category = "abilities"
    }, "1", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "ice_lance",
        name = "Ice Lance",
        description = "Cast Ice Lance",
        type = BIND_TYPE_ABILITY,
        spell = 30455,
        requiresTarget = true,
        category = "abilities"
    }, "2", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "flurry",
        name = "Flurry",
        description = "Cast Flurry",
        type = BIND_TYPE_ABILITY,
        spell = 44614,
        requiresTarget = true,
        category = "abilities"
    }, "3", BIND_MODE_NORMAL)
    
    -- Cooldowns
    self:RegisterBinding({
        id = "icy_veins",
        name = "Icy Veins",
        description = "Cast Icy Veins",
        type = BIND_TYPE_ABILITY,
        spell = 12472,
        category = "abilities"
    }, "4", BIND_MODE_NORMAL)
    
    -- AoE
    self:RegisterBinding({
        id = "blizzard",
        name = "Blizzard",
        description = "Cast Blizzard",
        type = BIND_TYPE_ABILITY,
        spell = 190356,
        category = "abilities"
    }, "1", BIND_MODE_AOE)
    
    -- Defensive
    self:RegisterBinding({
        id = "ice_block",
        name = "Ice Block",
        description = "Cast Ice Block",
        type = BIND_TYPE_ABILITY,
        spell = 45438,
        category = "defensive"
    }, "1", BIND_MODE_DEFENSIVE)
}

-- Register Arms warrior bindings
function KeybindManager:RegisterArmsSpecBindings()
    -- Core rotation abilities
    self:RegisterBinding({
        id = "mortal_strike",
        name = "Mortal Strike",
        description = "Cast Mortal Strike",
        type = BIND_TYPE_ABILITY,
        spell = 12294,
        requiresTarget = true,
        category = "abilities"
    }, "1", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "slam",
        name = "Slam",
        description = "Cast Slam",
        type = BIND_TYPE_ABILITY,
        spell = 1464,
        requiresTarget = true,
        category = "abilities"
    }, "2", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "execute",
        name = "Execute",
        description = "Cast Execute",
        type = BIND_TYPE_ABILITY,
        spell = 163201,
        requiresTarget = true,
        category = "abilities"
    }, "3", BIND_MODE_NORMAL)
    
    -- Cooldowns
    self:RegisterBinding({
        id = "colossus_smash",
        name = "Colossus Smash",
        description = "Cast Colossus Smash",
        type = BIND_TYPE_ABILITY,
        spell = 167105,
        requiresTarget = true,
        category = "abilities"
    }, "4", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "avatar",
        name = "Avatar",
        description = "Cast Avatar",
        type = BIND_TYPE_ABILITY,
        spell = 107574,
        category = "abilities"
    }, "5", BIND_MODE_NORMAL)
    
    -- AoE
    self:RegisterBinding({
        id = "bladestorm",
        name = "Bladestorm",
        description = "Cast Bladestorm",
        type = BIND_TYPE_ABILITY,
        spell = 227847,
        category = "abilities"
    }, "1", BIND_MODE_AOE)
    
    self:RegisterBinding({
        id = "cleave",
        name = "Cleave",
        description = "Cast Cleave",
        type = BIND_TYPE_ABILITY,
        spell = 845,
        requiresTarget = true,
        category = "abilities"
    }, "2", BIND_MODE_AOE)
    
    -- Defensive
    self:RegisterBinding({
        id = "die_by_the_sword",
        name = "Die by the Sword",
        description = "Cast Die by the Sword",
        type = BIND_TYPE_ABILITY,
        spell = 118038,
        category = "defensive"
    }, "1", BIND_MODE_DEFENSIVE)
}

-- Register Fury warrior bindings
function KeybindManager:RegisterFurySpecBindings()
    -- Core rotation abilities
    self:RegisterBinding({
        id = "bloodthirst",
        name = "Bloodthirst",
        description = "Cast Bloodthirst",
        type = BIND_TYPE_ABILITY,
        spell = 23881,
        requiresTarget = true,
        category = "abilities"
    }, "1", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "raging_blow",
        name = "Raging Blow",
        description = "Cast Raging Blow",
        type = BIND_TYPE_ABILITY,
        spell = 85288,
        requiresTarget = true,
        category = "abilities"
    }, "2", BIND_MODE_NORMAL)
    
    self:RegisterBinding({
        id = "rampage",
        name = "Rampage",
        description = "Cast Rampage",
        type = BIND_TYPE_ABILITY,
        spell = 184367,
        requiresTarget = true,
        category = "abilities"
    }, "3", BIND_MODE_NORMAL)
    
    -- Cooldowns
    self:RegisterBinding({
        id = "recklessness",
        name = "Recklessness",
        description = "Cast Recklessness",
        type = BIND_TYPE_ABILITY,
        spell = 1719,
        category = "abilities"
    }, "4", BIND_MODE_NORMAL)
    
    -- AoE
    self:RegisterBinding({
        id = "whirlwind",
        name = "Whirlwind",
        description = "Cast Whirlwind",
        type = BIND_TYPE_ABILITY,
        spell = 190411,
        category = "abilities"
    }, "1", BIND_MODE_AOE)
    
    -- Defensive
    self:RegisterBinding({
        id = "enraged_regeneration",
        name = "Enraged Regeneration",
        description = "Cast Enraged Regeneration",
        type = BIND_TYPE_ABILITY,
        spell = 184364,
        category = "defensive"
    }, "1", BIND_MODE_DEFENSIVE)
}

-- Other spec binding functions would be implemented similarly

-- Clear all bindings
function KeybindManager:ClearAllBindings()
    -- Clear registered bindings
    registeredBindings = {}
    
    -- Initialize binding modes
    registeredBindings[BIND_MODE_NORMAL] = {}
    registeredBindings[BIND_MODE_COMBAT] = {}
    registeredBindings[BIND_MODE_STEALTH] = {}
    registeredBindings[BIND_MODE_AOE] = {}
    registeredBindings[BIND_MODE_DEFENSIVE] = {}
    registeredBindings[BIND_MODE_BURST] = {}
    
    -- Clear binding sets
    for set, _ in pairs(bindingSets) do
        bindingSets[set].bindings = {}
    end
    
    -- Save the cleared bindings
    self:SaveBindings()
    
    -- Register default bindings
    self:RegisterDefaultBindings()
    
    -- Register spec bindings
    self:RegisterSpecBindings()
    
    API.PrintMessage("All keybindings have been reset to default")
}

-- Import bindings
function KeybindManager:ImportBindings(importString)
    -- Verify import string
    if not importString or importString == "" then
        API.PrintMessage("Invalid import string")
        return false
    end
    
    -- In a real addon, we would decode the import string here
    -- For this example, we'll just show the process
    
    -- Decode the string
    local success, decodedData = pcall(function() 
        -- This would be a real decode function
        return {
            format = importExportFormat,
            bindings = {}
        }
    end)
    
    if not success or not decodedData then
        API.PrintMessage("Failed to decode import string")
        return false
    end
    
    -- Check format version
    if decodedData.format ~= importExportFormat then
        API.PrintMessage("Incompatible binding format version")
        return false
    end
    
    -- Backup current bindings
    local backupBindings = {}
    for mode, modeBindings in pairs(registeredBindings) do
        backupBindings[mode] = {}
        for key, binding in pairs(modeBindings) do
            backupBindings[mode][key] = binding
        end
    end
    
    -- Clear current bindings
    for mode, _ in pairs(registeredBindings) do
        registeredBindings[mode] = {}
    end
    
    -- Import new bindings
    for mode, modeBindings in pairs(decodedData.bindings) do
        if not registeredBindings[mode] then
            registeredBindings[mode] = {}
        end
        
        for key, binding in pairs(modeBindings) do
            registeredBindings[mode][key] = binding
        end
    end
    
    -- Save the imported bindings
    self:SaveBindings()
    
    API.PrintMessage("Keybindings imported successfully")
    return true
end

-- Export bindings
function KeybindManager:ExportBindings()
    -- Create export data
    local exportData = {
        format = importExportFormat,
        bindings = registeredBindings,
        metadata = {
            class = select(2, UnitClass("player")),
            spec = API.GetActiveSpecID(),
            version = "1.0", -- Add-on version
            date = date("%Y-%m-%d %H:%M:%S")
        }
    }
    
    -- In a real addon, we would encode this data to a string
    -- For this example, we'll just return the table
    return exportData
}

-- Register key sequence
function KeybindManager:RegisterKeySequence(id, keys, binding)
    if not id or not keys or #keys < 2 or not binding then
        return false
    end
    
    keySequences[id] = {
        keys = keys,
        binding = binding
    }
    
    return true
}

-- Register key callback
function KeybindManager:RegisterKeyCallback(bindingID, callback)
    if not bindingID or not callback then
        return false
    end
    
    keyCallback[bindingID] = callback
    return true
}

-- Get keybind categories
function KeybindManager:GetKeybindCategories()
    return keybindCategories
end

-- Get binding for action
function KeybindManager:GetBindingForAction(action, type)
    -- Find a binding that matches the action and type
    for mode, modeBindings in pairs(registeredBindings) do
        for key, binding in pairs(modeBindings) do
            if binding.type == type and (
               (binding.action and binding.action == action) or
               (binding.spell and binding.spell == action) or
               (binding.toggle and binding.toggle == action)
            ) then
                return key, mode
            end
        end
    end
    
    return nil
}

-- Get bindings for mode
function KeybindManager:GetBindingsForMode(mode)
    mode = mode or activeBindingMode
    return registeredBindings[mode] or {}
end

-- Get binding sets
function KeybindManager:GetBindingSets()
    return bindingSets
end

-- Set active binding set
function KeybindManager:SetActiveBindingSet(set)
    if bindingSets[set] then
        customBindingSet = set
        
        -- Update setting
        local settings = ConfigRegistry:GetSettings("KeybindManager")
        settings.generalSettings.activeBindingSet = set
        
        -- Load bindings for this set
        self:LoadBindings()
        
        API.PrintMessage("Active binding set changed to: " .. set)
        return true
    end
    
    return false
end

-- Get active binding mode
function KeybindManager:GetActiveBindingMode()
    return activeBindingMode
end

-- Return the module
return KeybindManager