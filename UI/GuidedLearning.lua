local addonName, WR = ...

-- GuidedLearning module for interactive tutorials and guidance
local GuidedLearning = {}
WR.UI.GuidedLearning = GuidedLearning

-- Local references for performance
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
local PlaySound = PlaySound
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local min = math.min
local max = math.max

-- Module state variables
local isActive = false
local currentTutorial = nil
local currentStep = 1
local tutorialFrame
local tutorialSteps = {}
local registeredElements = {}
local highlightedElement = nil
local highlightBox
local arrowTexture
local completedTutorials = {}
local tutorialHistory = {}
local HIGHLIGHT_PADDING = 5
local ARROW_SIZE = 32
local tutorials = {}
local arrowDirections = {
    UP = 0,
    RIGHT = 1.57,
    DOWN = 3.14,
    LEFT = 4.71
}

-- Initialize the module
function GuidedLearning:Initialize()
    -- Create tutorial frame
    self:CreateTutorialFrame()
    
    -- Create highlight box
    self:CreateHighlightBox()
    
    -- Define tutorials
    self:DefineTutorials()
    
    -- Load completed tutorials
    self:LoadCompletedTutorials()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register with the main addon
    self:RegisterWithAddon()
    
    WR:Debug("GuidedLearning module initialized")
end

-- Create tutorial frame
function GuidedLearning:CreateTutorialFrame()
    -- Main tutorial frame
    tutorialFrame = CreateFrame("Frame", "WRGuidedLearningFrame", UIParent, "BackdropTemplate")
    tutorialFrame:SetSize(400, 200)
    tutorialFrame:SetFrameStrata("DIALOG")
    tutorialFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    tutorialFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    tutorialFrame:SetMovable(true)
    tutorialFrame:EnableMouse(true)
    tutorialFrame:RegisterForDrag("LeftButton")
    tutorialFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    tutorialFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    tutorialFrame:SetClampedToScreen(true)
    tutorialFrame:Hide()
    
    -- Tutorial title
    local title = tutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", tutorialFrame, "TOP", 0, -20)
    title:SetText("Tutorial")
    tutorialFrame.title = title
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, tutorialFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", tutorialFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        GuidedLearning:EndTutorial()
    end)
    
    -- Tutorial text
    local text = tutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 20, -20)
    text:SetPoint("BOTTOMRIGHT", tutorialFrame, "BOTTOMRIGHT", -20, 60)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText("Welcome to the guided tutorial system!")
    tutorialFrame.text = text
    
    -- Step indicator
    local stepText = tutorialFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stepText:SetPoint("BOTTOMLEFT", tutorialFrame, "BOTTOMLEFT", 20, 15)
    stepText:SetText("Step 1/5")
    tutorialFrame.stepText = stepText
    
    -- Previous button
    local prevButton = CreateFrame("Button", nil, tutorialFrame, "UIPanelButtonTemplate")
    prevButton:SetSize(80, 25)
    prevButton:SetPoint("BOTTOMLEFT", tutorialFrame, "BOTTOMLEFT", 20, 35)
    prevButton:SetText("< Previous")
    prevButton:SetScript("OnClick", function()
        GuidedLearning:PreviousStep()
    end)
    tutorialFrame.prevButton = prevButton
    
    -- Next button
    local nextButton = CreateFrame("Button", nil, tutorialFrame, "UIPanelButtonTemplate")
    nextButton:SetSize(80, 25)
    nextButton:SetPoint("BOTTOMRIGHT", tutorialFrame, "BOTTOMRIGHT", -20, 35)
    nextButton:SetText("Next >")
    nextButton:SetScript("OnClick", function()
        GuidedLearning:NextStep()
    end)
    tutorialFrame.nextButton = nextButton
    
    -- Step indicator dots
    tutorialFrame.dots = {}
    for i = 1, 10 do
        local dot = tutorialFrame:CreateTexture(nil, "OVERLAY")
        dot:SetSize(10, 10)
        dot:SetTexture("Interface\\COMMON\\Indicator-Gray")
        dot:SetPoint("BOTTOM", tutorialFrame, "BOTTOM", (i - 5.5) * 12, 15)
        dot:Hide()
        tutorialFrame.dots[i] = dot
    end
end

-- Create highlight box
function GuidedLearning:CreateHighlightBox()
    -- Highlight box
    highlightBox = CreateFrame("Frame", "WRGuidedLearningHighlight", UIParent)
    highlightBox:SetFrameStrata("DIALOG")
    highlightBox:EnableMouse(false)
    highlightBox:Hide()
    
    -- Border texture
    local border = highlightBox:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
    border:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    highlightBox.border = border
    
    -- Pulse animation
    local animGroup = highlightBox:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")
    
    local alpha = animGroup:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.3)
    alpha:SetToAlpha(0.7)
    alpha:SetDuration(0.8)
    alpha:SetSmoothing("IN_OUT")
    
    local alpha2 = animGroup:CreateAnimation("Alpha")
    alpha2:SetFromAlpha(0.7)
    alpha2:SetToAlpha(0.3)
    alpha2:SetDuration(0.8)
    alpha2:SetSmoothing("IN_OUT")
    alpha2:SetStartDelay(0.8)
    
    animGroup:Play()
    highlightBox.animGroup = animGroup
    
    -- Arrow texture
    arrowTexture = UIParent:CreateTexture("WRGuidedLearningArrow", "OVERLAY")
    arrowTexture:SetTexture("Interface\\TUTORIALFRAME\\UI-TutorialFrame-GuideCursor")
    arrowTexture:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrowTexture:Hide()
    
    -- Arrow animation
    local arrowAnimGroup = CreateFrame("Frame"):CreateAnimationGroup()
    arrowAnimGroup:SetLooping("REPEAT")
    
    local translation = arrowAnimGroup:CreateAnimation("Translation")
    translation:SetOffset(0, 10)
    translation:SetDuration(0.6)
    translation:SetSmoothing("IN_OUT")
    
    local translation2 = arrowAnimGroup:CreateAnimation("Translation")
    translation2:SetOffset(0, -10)
    translation2:SetDuration(0.6)
    translation2:SetSmoothing("IN_OUT")
    translation2:SetStartDelay(0.6)
    
    arrowAnimGroup:Play()
    arrowTexture.animGroup = arrowAnimGroup
end

-- Define tutorials
function GuidedLearning:DefineTutorials()
    -- Main UI Tutorial
    tutorials.mainUI = {
        id = "mainUI",
        name = "Getting Started",
        description = "Learn the basics of the Windrunner Rotations addon.",
        steps = {
            {
                text = "Welcome to Windrunner Rotations! This tutorial will guide you through the basics of using this advanced rotation addon.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            },
            {
                text = "This is the main UI of the addon. Here you can toggle various features and access all settings.",
                elementId = "mainFrame",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "The toggle button lets you quickly enable or disable the rotation system.",
                elementId = "toggleButton",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "You can open the settings panel to customize all aspects of the addon.",
                elementId = "settingsButton",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "That's it for the basic UI! Try opening the Advanced Settings panel to explore more options.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            }
        }
    }
    
    -- Advanced Settings Tutorial
    tutorials.advancedSettings = {
        id = "advancedSettings",
        name = "Advanced Settings",
        description = "Learn about the comprehensive settings panel.",
        steps = {
            {
                text = "The Advanced Settings panel gives you fine-grained control over every aspect of the addon.",
                elementId = "settingsFrame",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "Use these tabs to navigate between different categories of settings.",
                elementId = "settingsTabs",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "In the General tab, you can adjust global settings like UI scale, theme, and color options.",
                elementId = "generalTab",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "The Rotation tab lets you customize how the automation behaves, including targeting and ability usage.",
                elementId = "rotationTab",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "The UI tabs let you customize how information is displayed, from class resources to predicted resource changes.",
                elementId = "classUITab",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "The Profiles tab allows you to save different configurations for different situations.",
                elementId = "profilesTab",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "Don't forget to save your changes when you're done configuring the addon!",
                elementId = "saveButton",
                highlight = true,
                arrowDirection = "UP"
            }
        }
    }
    
    -- Visual Edit Mode Tutorial
    tutorials.visualEdit = {
        id = "visualEdit",
        name = "Visual Edit Mode",
        description = "Learn how to visually customize your UI layout.",
        steps = {
            {
                text = "Welcome to the Visual Edit Mode! This powerful feature lets you customize the position and size of all UI elements.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            },
            {
                text = "This is the Edit Mode control panel. Here you can adjust grid settings and access other layout tools.",
                elementId = "editModePanel",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "Click and drag any UI element to move it around. Notice how the grid helps you align elements precisely.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            },
            {
                text = "Use these resize handles to change the size of a selected element.",
                elementId = "resizeHandles",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "The Grid Size slider adjusts how fine or coarse the alignment grid is.",
                elementId = "gridSlider",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "Enable or disable the magnet feature, which helps snap elements to each other.",
                elementId = "magnetCheck",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "Right-click on any element to access additional options like centering or resetting its position.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            },
            {
                text = "When you're done, click Save to store your layout changes.",
                elementId = "saveEditButton",
                highlight = true,
                arrowDirection = "UP"
            }
        }
    }
    
    -- Class UI Tutorial
    tutorials.classUI = {
        id = "classUI",
        name = "Class UI Features",
        description = "Explore the class-specific visualization features.",
        steps = {
            {
                text = "The Class UI provides specialized visualizations for your character's resources and abilities.",
                elementId = "classUIFrame",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "This area shows your class-specific resources like Combo Points, Runes, or Arcane Charges.",
                elementId = "resourceDisplay",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "The DoT/HoT tracker shows the remaining duration of your damage or healing over time effects.",
                elementId = "dotTracker",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "Important procs and ability alerts will appear here with visual and audio cues.",
                elementId = "procDisplay",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "The spell queue shows the next few abilities the system recommends using.",
                elementId = "spellQueue",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "You can customize every aspect of this display in the Advanced Settings panel.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            }
        }
    }
    
    -- Resource Forecast Tutorial
    tutorials.resourceForecast = {
        id = "resourceForecast",
        name = "Resource Forecasting",
        description = "Learn about predicting and visualizing resource changes.",
        steps = {
            {
                text = "The Resource Forecast shows you a prediction of how your resources will change over time.",
                elementId = "forecastFrame",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "This timeline shows your predicted resource levels for the next few seconds.",
                elementId = "resourceTimeline",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "These markers indicate when ability usage will affect your resources.",
                elementId = "abilityMarkers",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "The history section shows your recent resource changes for comparison.",
                elementId = "resourceHistory",
                highlight = true,
                arrowDirection = "LEFT"
            },
            {
                text = "This sophisticated system helps you plan ahead and optimize your resource usage!",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            }
        }
    }
    
    -- Machine Learning Tutorial
    tutorials.machineLearning = {
        id = "machineLearning",
        name = "Machine Learning System",
        description = "Discover how the addon learns and adapts to your gameplay.",
        steps = {
            {
                text = "The Machine Learning system is one of the most powerful features of Windrunner Rotations. It learns from your gameplay and adapts over time.",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            },
            {
                text = "Data collection is enabled by default and anonymously tracks your combat performance.",
                elementId = "mlSettings",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "As you play, the system identifies successful patterns and incorporates them into future recommendations.",
                elementId = "mlPatterns",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "The learning rate determines how quickly the system adapts to new information.",
                elementId = "learningRate",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "You can balance between global patterns (what works for everyone) and personal patterns (what works for you).",
                elementId = "modelPriority",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "Over time, your rotations will become increasingly tailored to your specific playstyle and situations!",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            }
        }
    }
    
    -- PvP System Tutorial
    tutorials.pvpSystem = {
        id = "pvpSystem",
        name = "PvP Features",
        description = "Learn about the specialized PvP optimization features.",
        steps = {
            {
                text = "The PvP System provides specialized features for player-vs-player combat scenarios.",
                elementId = "pvpFrame",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "Enemy tracking displays important information about your opponents, including cooldowns.",
                elementId = "enemyTracking",
                highlight = true,
                arrowDirection = "RIGHT"
            },
            {
                text = "Diminishing returns tracking helps you optimize crowd control timing.",
                elementId = "drTracking",
                highlight = true,
                arrowDirection = "DOWN"
            },
            {
                text = "Target priority suggestions help you focus on the most important targets in team fights.",
                elementId = "targetPriority",
                highlight = true,
                arrowDirection = "LEFT"
            },
            {
                text = "Defensive recommendations will suggest when to use your defensive abilities based on threat assessment.",
                elementId = "defensiveDisplay",
                highlight = true,
                arrowDirection = "UP"
            },
            {
                text = "These PvP optimizations give you a significant advantage in arenas and battlegrounds!",
                elementId = nil,
                highlight = false,
                arrowDirection = nil
            }
        }
    }
}

-- Load completed tutorials
function GuidedLearning:LoadCompletedTutorials()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.CompletedTutorials then
        completedTutorials = WindrunnerRotationsDB.CompletedTutorials
    else
        completedTutorials = {}
    end
end

-- Save completed tutorials
function GuidedLearning:SaveCompletedTutorials()
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.CompletedTutorials = completedTutorials
end

-- Register events
function GuidedLearning:RegisterEvents()
    -- Nothing to register currently
end

-- Start a tutorial
function GuidedLearning:StartTutorial(tutorialId)
    if not tutorials[tutorialId] then
        print("Windrunner Rotations: Tutorial '" .. tutorialId .. "' not found.")
        return false
    end
    
    -- End any current tutorial
    if isActive then
        self:EndTutorial()
    end
    
    -- Set active tutorial
    currentTutorial = tutorials[tutorialId]
    currentStep = 1
    isActive = true
    
    -- Initialize tutorial frame
    tutorialFrame.title:SetText(currentTutorial.name)
    self:UpdateTutorialStep()
    
    -- Show tutorial frame
    tutorialFrame:Show()
    
    -- Add to history
    table.insert(tutorialHistory, {
        id = tutorialId,
        timestamp = time()
    })
    
    return true
end

-- End current tutorial
function GuidedLearning:EndTutorial(markCompleted)
    if not isActive then return end
    
    -- Hide tutorial frame
    tutorialFrame:Hide()
    
    -- Hide highlight
    highlightBox:Hide()
    arrowTexture:Hide()
    
    -- Reset state
    isActive = false
    
    -- Mark as completed if requested and not already completed
    if markCompleted and currentTutorial and not completedTutorials[currentTutorial.id] then
        completedTutorials[currentTutorial.id] = time()
        self:SaveCompletedTutorials()
    end
    
    currentTutorial = nil
    currentStep = 1
end

-- Show next step
function GuidedLearning:NextStep()
    if not isActive or not currentTutorial then return end
    
    if currentStep < #currentTutorial.steps then
        currentStep = currentStep + 1
        self:UpdateTutorialStep()
        PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN)
    else
        -- This was the last step
        self:EndTutorial(true)
        PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE)
    end
end

-- Show previous step
function GuidedLearning:PreviousStep()
    if not isActive or not currentTutorial then return end
    
    if currentStep > 1 then
        currentStep = currentStep - 1
        self:UpdateTutorialStep()
        PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN)
    end
end

-- Update tutorial UI for current step
function GuidedLearning:UpdateTutorialStep()
    if not isActive or not currentTutorial then return end
    
    local step = currentTutorial.steps[currentStep]
    if not step then return end
    
    -- Update text
    tutorialFrame.text:SetText(step.text)
    
    -- Update step indicator
    tutorialFrame.stepText:SetText("Step " .. currentStep .. "/" .. #currentTutorial.steps)
    
    -- Update step dots
    for i, dot in ipairs(tutorialFrame.dots) do
        if i <= #currentTutorial.steps then
            dot:Show()
            if i == currentStep then
                dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
                dot:SetSize(12, 12)
            else
                dot:SetTexture("Interface\\COMMON\\Indicator-Gray")
                dot:SetSize(10, 10)
            end
        else
            dot:Hide()
        end
    end
    
    -- Update navigation buttons
    tutorialFrame.prevButton:SetEnabled(currentStep > 1)
    
    if currentStep == #currentTutorial.steps then
        tutorialFrame.nextButton:SetText("Finish")
    else
        tutorialFrame.nextButton:SetText("Next >")
    end
    
    -- Clear current highlight
    highlightBox:Hide()
    arrowTexture:Hide()
    
    -- Add highlight if needed
    if step.highlight and step.elementId then
        self:HighlightElement(step.elementId, step.arrowDirection)
    end
    
    -- Position tutorial frame if we're highlighting an element
    if step.highlight and step.elementId and highlightedElement then
        self:PositionTutorialFrame(highlightedElement)
    else
        -- Default position in center of screen
        tutorialFrame:ClearAllPoints()
        tutorialFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- Register an element for tutorials
function GuidedLearning:RegisterElement(elementId, element)
    if not elementId or not element then return end
    
    registeredElements[elementId] = element
    return true
end

-- Unregister an element
function GuidedLearning:UnregisterElement(elementId)
    if not elementId then return end
    
    registeredElements[elementId] = nil
    return true
end

-- Highlight an element
function GuidedLearning:HighlightElement(elementId, arrowDirection)
    -- Find the element
    local element = registeredElements[elementId]
    if not element then return false end
    
    -- Get element dimensions and position
    local scale = element:GetEffectiveScale()
    local width = element:GetWidth() * scale
    local height = element:GetHeight() * scale
    
    local x, y = element:GetCenter()
    if not x or not y then return false end
    
    x = x * scale
    y = y * scale
    
    -- Position highlight box
    highlightBox:ClearAllPoints()
    highlightBox:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    highlightBox:SetSize(width + HIGHLIGHT_PADDING * 2, height + HIGHLIGHT_PADDING * 2)
    highlightBox:Show()
    
    -- Store highlighted element
    highlightedElement = element
    
    -- Position arrow if direction provided
    if arrowDirection then
        local direction = arrowDirections[arrowDirection:upper()]
        if not direction then direction = 0 end
        
        arrowTexture:SetRotation(direction)
        
        -- Position arrow based on direction
        arrowTexture:ClearAllPoints()
        
        if arrowDirection:upper() == "UP" then
            arrowTexture:SetPoint("BOTTOM", highlightBox, "TOP", 0, 5)
        elseif arrowDirection:upper() == "DOWN" then
            arrowTexture:SetPoint("TOP", highlightBox, "BOTTOM", 0, -5)
        elseif arrowDirection:upper() == "LEFT" then
            arrowTexture:SetPoint("RIGHT", highlightBox, "LEFT", -5, 0)
        elseif arrowDirection:upper() == "RIGHT" then
            arrowTexture:SetPoint("LEFT", highlightBox, "RIGHT", 5, 0)
        end
        
        arrowTexture:Show()
    end
    
    return true
end

-- Position tutorial frame relative to highlighted element
function GuidedLearning:PositionTutorialFrame(element)
    if not element then return end
    
    -- Get screen dimensions
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    -- Get element position
    local eScale = element:GetEffectiveScale()
    local ex, ey = element:GetCenter()
    if not ex or not ey then return end
    
    ex = ex * eScale
    ey = ey * eScale
    
    -- Get element dimensions
    local eWidth = element:GetWidth() * eScale
    local eHeight = element:GetHeight() * eScale
    
    -- Determine best position for tutorial frame
    tutorialFrame:ClearAllPoints()
    
    -- Try to position on right side first
    if ex + eWidth/2 + tutorialFrame:GetWidth() + 20 < screenWidth then
        tutorialFrame:SetPoint("LEFT", UIParent, "BOTTOMLEFT", ex + eWidth/2 + 20, ey)
    -- Try left side
    elseif ex - eWidth/2 - tutorialFrame:GetWidth() - 20 > 0 then
        tutorialFrame:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", ex - eWidth/2 - 20, ey)
    -- Try above
    elseif ey + eHeight/2 + tutorialFrame:GetHeight() + 20 < screenHeight then
        tutorialFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", ex, ey + eHeight/2 + 20)
    -- Try below
    elseif ey - eHeight/2 - tutorialFrame:GetHeight() - 20 > 0 then
        tutorialFrame:SetPoint("TOP", UIParent, "BOTTOMLEFT", ex, ey - eHeight/2 - 20)
    -- Fallback to center
    else
        tutorialFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- Check if a tutorial has been completed
function GuidedLearning:IsTutorialCompleted(tutorialId)
    return completedTutorials[tutorialId] ~= nil
end

-- Reset completion status of a tutorial
function GuidedLearning:ResetTutorial(tutorialId)
    if tutorialId == "all" then
        completedTutorials = {}
    else
        completedTutorials[tutorialId] = nil
    end
    
    self:SaveCompletedTutorials()
    return true
end

-- Get list of all tutorials
function GuidedLearning:GetTutorialList()
    local list = {}
    
    for id, tutorial in pairs(tutorials) do
        table.insert(list, {
            id = id,
            name = tutorial.name,
            description = tutorial.description,
            steps = #tutorial.steps,
            completed = self:IsTutorialCompleted(id)
        })
    end
    
    return list
end

-- Show tutorial selection menu
function GuidedLearning:ShowTutorialMenu()
    -- Create menu frame if it doesn't exist
    if not self.menuFrame then
        local menu = CreateFrame("Frame", "WRGuidedLearningMenu", UIParent, "BackdropTemplate")
        menu:SetSize(400, 500)
        menu:SetPoint("CENTER")
        menu:SetFrameStrata("DIALOG")
        menu:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        menu:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        menu:SetMovable(true)
        menu:EnableMouse(true)
        menu:RegisterForDrag("LeftButton")
        menu:SetScript("OnDragStart", function(self) self:StartMoving() end)
        menu:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        menu:SetClampedToScreen(true)
        
        -- Title
        local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", menu, "TOP", 0, -20)
        title:SetText("Windrunner Rotations Tutorials")
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -5, -5)
        
        -- Scrollframe for tutorials
        local scrollFrame = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", menu, "TOPLEFT", 20, -60)
        scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -35, 70)
        
        local scrollChild = CreateFrame("Frame")
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:SetSize(scrollFrame:GetWidth(), 800) -- Will be adjusted based on content
        
        -- Reset all button
        local resetButton = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        resetButton:SetSize(120, 25)
        resetButton:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 20, 20)
        resetButton:SetText("Reset All")
        resetButton:SetScript("OnClick", function()
            StaticPopupDialogs["WR_RESET_TUTORIALS_CONFIRM"] = {
                text = "Are you sure you want to reset all tutorial completion status?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    GuidedLearning:ResetTutorial("all")
                    GuidedLearning:UpdateTutorialMenu()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("WR_RESET_TUTORIALS_CONFIRM")
        end)
        
        -- Close button
        local closeMenuButton = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        closeMenuButton:SetSize(80, 25)
        closeMenuButton:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -20, 20)
        closeMenuButton:SetText("Close")
        closeMenuButton:SetScript("OnClick", function()
            menu:Hide()
        end)
        
        -- Store references
        self.menuFrame = menu
        self.menuScrollChild = scrollChild
    end
    
    -- Update tutorial list
    self:UpdateTutorialMenu()
    
    -- Show menu
    self.menuFrame:Show()
end

-- Update tutorial menu content
function GuidedLearning:UpdateTutorialMenu()
    local scrollChild = self.menuScrollChild
    if not scrollChild then return end
    
    -- Clear existing buttons
    for _, child in pairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Get tutorial list
    local tutorialList = self:GetTutorialList()
    
    -- Create tutorial buttons
    local buttonHeight = 80
    local totalHeight = 0
    
    for i, info in ipairs(tutorialList) do
        local button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
        button:SetSize(scrollChild:GetWidth() - 20, buttonHeight)
        button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10 - (i-1) * (buttonHeight + 10))
        
        -- Button backdrop
        button:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Button highlight
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        -- Tutorial name
        local name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("TOPLEFT", button, "TOPLEFT", 15, -10)
        name:SetText(info.name)
        
        -- Completion status
        local status = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("TOPRIGHT", button, "TOPRIGHT", -15, -10)
        if info.completed then
            status:SetText("|cFF00FF00Completed|r")
        else
            status:SetText("|cFFFFFFFFNot completed|r")
        end
        
        -- Description
        local desc = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
        desc:SetPoint("RIGHT", button, "RIGHT", -15, 0)
        desc:SetJustifyH("LEFT")
        desc:SetText(info.description)
        
        -- Steps
        local steps = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        steps:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 15, 10)
        steps:SetText(info.steps .. " steps")
        
        -- Start button
        local startButton = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
        startButton:SetSize(80, 22)
        startButton:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -15, 8)
        startButton:SetText(info.completed and "Restart" or "Start")
        startButton:SetScript("OnClick", function()
            GuidedLearning:StartTutorial(info.id)
            self.menuFrame:Hide()
        end)
        
        -- Reset button (if completed)
        if info.completed then
            local resetButton = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
            resetButton:SetSize(60, 22)
            resetButton:SetPoint("RIGHT", startButton, "LEFT", -5, 0)
            resetButton:SetText("Reset")
            resetButton:SetScript("OnClick", function()
                GuidedLearning:ResetTutorial(info.id)
                GuidedLearning:UpdateTutorialMenu()
            end)
        end
        
        totalHeight = totalHeight + buttonHeight + 10
    end
    
    -- Adjust scrollChild height
    scrollChild:SetHeight(max(totalHeight + 20, self.menuFrame:GetHeight() - 130))
end

-- Register with main addon
function GuidedLearning:RegisterWithAddon()
    -- Register slash command
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("tutorial", function(msg)
            self:HandleSlashCommand(msg)
        end)
    end
    
    -- Add to settings panel
    if WR.UI and WR.UI.AdvancedSettingsUI then
        WR.UI.AdvancedSettingsUI:AddButton("Tutorials", function()
            self:ShowTutorialMenu()
        end)
    end
}

-- Handle slash command
function GuidedLearning:HandleSlashCommand(msg)
    if not msg or msg == "" then
        self:ShowTutorialMenu()
        return
    end
    
    local command, param = msg:match("^(%S+)%s*(.*)$")
    if not command then
        self:ShowTutorialMenu()
        return
    end
    
    command = command:lower()
    
    if command == "start" and param ~= "" then
        -- Start specific tutorial
        self:StartTutorial(param)
    elseif command == "list" then
        -- List available tutorials
        print("Available Windrunner Rotations tutorials:")
        for id, tutorial in pairs(tutorials) do
            local status = self:IsTutorialCompleted(id) and "|cFF00FF00(Completed)|r" or ""
            print("  - " .. tutorial.name .. " (" .. id .. ") " .. status)
        end
    elseif command == "reset" and param ~= "" then
        -- Reset specific tutorial or all
        self:ResetTutorial(param)
        print("Tutorial reset: " .. param)
    else
        -- Show help
        print("Windrunner Rotations Tutorial commands:")
        print("  /tutorial - Show tutorial menu")
        print("  /tutorial start <id> - Start specific tutorial")
        print("  /tutorial list - List available tutorials")
        print("  /tutorial reset <id|all> - Reset tutorial completion status")
    end
end

-- Check for first-time use and suggest tutorial
function GuidedLearning:CheckFirstTimeUse()
    if not WindrunnerRotationsDB or not WindrunnerRotationsDB.CompletedTutorials then
        -- First time use, suggest main tutorial
        C_Timer.After(2, function()
            StaticPopupDialogs["WR_FIRST_TIME_TUTORIAL"] = {
                text = "Welcome to Windrunner Rotations! Would you like to view a tutorial to learn the basics?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    GuidedLearning:StartTutorial("mainUI")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("WR_FIRST_TIME_TUTORIAL")
        end)
    end
end

-- Initialize the module
GuidedLearning:Initialize()

return GuidedLearning