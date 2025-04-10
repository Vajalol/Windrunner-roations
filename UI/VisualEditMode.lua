local addonName, WR = ...

-- VisualEditMode module for visual, direct manipulation of UI elements
local VisualEditMode = {}
WR.UI.VisualEditMode = VisualEditMode

-- Local references for performance
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
local math_floor = math.floor
local math_abs = math.abs
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove

-- Module state variables
local isActive = false
local registeredFrames = {}
local selectedFrames = {}
local activeFrame = nil
local dragStart = {x = 0, y = 0}
local startPos = {x = 0, y = 0}
local gridSize = 10
local gridEnabled = true
local magnet = 5
local magnetEnabled = true
local editOverlay
local controlPanel
local resizeHandles = {}
local multiSelect = false
local dragMode = "move" -- "move", "resize", "rotate"
local snapLines = {}
local HANDLE_SIZE = 10
local storedPositions = {}
local clipboard = {}
local actionHistory = {}
local historyIndex = 0
local MAX_HISTORY = 100
local clipboard = nil
local magnetPoints = {}
local guides = {
    horizontal = {},
    vertical = {}
}

-- Resize handle positions
local HANDLE_POSITIONS = {
    topleft = {anchor = "TOPLEFT", cursor = "RESIZE", xFactor = -1, yFactor = 1},
    topright = {anchor = "TOPRIGHT", cursor = "RESIZE", xFactor = 1, yFactor = 1},
    bottomleft = {anchor = "BOTTOMLEFT", cursor = "RESIZE", xFactor = -1, yFactor = -1},
    bottomright = {anchor = "BOTTOMRIGHT", cursor = "RESIZE", xFactor = 1, yFactor = -1},
    top = {anchor = "TOP", cursor = "RESIZE", xFactor = 0, yFactor = 1},
    bottom = {anchor = "BOTTOM", cursor = "RESIZE", xFactor = 0, yFactor = -1},
    left = {anchor = "LEFT", cursor = "RESIZE", xFactor = -1, yFactor = 0},
    right = {anchor = "RIGHT", cursor = "RESIZE", xFactor = 1, yFactor = 0}
}

-- Settings
local settings = {
    gridSize = 10,
    gridEnabled = true,
    magnetEnabled = true,
    magnetDistance = 5,
    showGuides = true,
    showOverlay = true,
    showControls = true,
    lockUnselected = true,
    showFrameInfo = true,
    undoLevels = 20,
    useClassColors = true
}

-- Initialize the module
function VisualEditMode:Initialize()
    -- Create editing overlay
    self:CreateEditOverlay()
    
    -- Create control panel
    self:CreateControlPanel()
    
    -- Load settings
    self:LoadSettings()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register with the main addon
    self:RegisterWithAddon()
    
    WR:Debug("VisualEditMode module initialized")
end

-- Load settings
function VisualEditMode:LoadSettings()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.VisualEditMode then
        for k, v in pairs(WindrunnerRotationsDB.VisualEditMode) do
            if settings[k] ~= nil then
                settings[k] = v
            end
        end
        
        -- Apply loaded settings
        gridSize = settings.gridSize
        gridEnabled = settings.gridEnabled
        magnetEnabled = settings.magnetEnabled
        magnet = settings.magnetDistance
    end
end

-- Save settings
function VisualEditMode:SaveSettings()
    -- Initialize DB if needed
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.VisualEditMode = settings
end

-- Register events
function VisualEditMode:RegisterEvents()
    -- Nothing to register currently
end

-- Create edit overlay
function VisualEditMode:CreateEditOverlay()
    -- Main overlay frame
    editOverlay = CreateFrame("Frame", "WRVisualEditModeOverlay", UIParent)
    editOverlay:SetFrameStrata("TOOLTIP")
    editOverlay:SetAllPoints()
    editOverlay:Hide()
    
    -- Grid lines
    editOverlay.gridLines = {}
    
    -- Selection box for multi-select
    editOverlay.selectionBox = CreateFrame("Frame", nil, editOverlay, "BackdropTemplate")
    editOverlay.selectionBox:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    editOverlay.selectionBox:SetBackdropBorderColor(0.7, 0.7, 1.0, 1.0)
    editOverlay.selectionBox:SetFrameStrata("DIALOG")
    editOverlay.selectionBox:SetFrameLevel(10)
    editOverlay.selectionBox:Hide()
    
    -- Selection box fill
    editOverlay.selectionBox.fill = editOverlay.selectionBox:CreateTexture(nil, "BACKGROUND")
    editOverlay.selectionBox.fill:SetAllPoints()
    editOverlay.selectionBox.fill:SetColorTexture(0.3, 0.3, 0.8, 0.2)
    
    -- Mouse handlers for selection box
    editOverlay:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Start selection box
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x = x / scale
            y = y / scale
            
            self.selectionStart = {x = x, y = y}
            self.selecting = true
            
            -- Clear selection if not holding shift
            if not IsShiftKeyDown() then
                VisualEditMode:ClearSelection()
            end
            
            -- Show selection box
            self.selectionBox:ClearAllPoints()
            self.selectionBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
            self.selectionBox:SetSize(1, 1)
            self.selectionBox:Show()
        elseif button == "RightButton" then
            -- Show context menu
            VisualEditMode:ShowContextMenu()
        end
    end)
    
    editOverlay:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.selecting then
            -- End selection
            self.selecting = false
            self.selectionBox:Hide()
            
            -- Select frames inside the box
            VisualEditMode:SelectFramesInBox(self.selectionBox)
        end
    end)
    
    editOverlay:SetScript("OnUpdate", function(self, elapsed)
        if self.selecting and self.selectionStart then
            -- Update selection box
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x = x / scale
            y = y / scale
            
            local left = math.min(self.selectionStart.x, x)
            local right = math.max(self.selectionStart.x, x)
            local bottom = math.min(self.selectionStart.y, y)
            local top = math.max(self.selectionStart.y, y)
            
            self.selectionBox:ClearAllPoints()
            self.selectionBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            self.selectionBox:SetSize(right - left, top - bottom)
        end
    end)
    
    -- Create snap lines
    for i = 1, 4 do
        local line = editOverlay:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(0, 1, 0, 0.4) -- Green for snap lines
        line:SetSize(1, 1) -- Will be resized when used
        line:Hide()
        tinsert(snapLines, line)
    end
    
    -- Create guide lines
    for i = 1, 5 do
        -- Horizontal guides
        local hLine = editOverlay:CreateTexture(nil, "BACKGROUND")
        hLine:SetColorTexture(0.8, 0.1, 0.1, 0.4) -- Red for guides
        hLine:SetHeight(1)
        hLine:SetWidth(UIParent:GetWidth())
        hLine:Hide()
        tinsert(guides.horizontal, hLine)
        
        -- Vertical guides
        local vLine = editOverlay:CreateTexture(nil, "BACKGROUND")
        vLine:SetColorTexture(0.1, 0.1, 0.8, 0.4) -- Blue for guides
        vLine:SetWidth(1)
        vLine:SetHeight(UIParent:GetHeight())
        vLine:Hide()
        tinsert(guides.vertical, vLine)
    end
end

-- Create control panel
function VisualEditMode:CreateControlPanel()
    -- Main control panel frame
    controlPanel = CreateFrame("Frame", "WRVisualEditModeControls", UIParent, "BackdropTemplate")
    controlPanel:SetSize(250, 300)
    controlPanel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -100)
    controlPanel:SetFrameStrata("DIALOG")
    controlPanel:SetMovable(true)
    controlPanel:SetClampedToScreen(true)
    controlPanel:EnableMouse(true)
    controlPanel:RegisterForDrag("LeftButton")
    controlPanel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    controlPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    controlPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    controlPanel:Hide()
    
    -- Title text
    local title = controlPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", controlPanel, "TOP", 0, -15)
    title:SetText("Visual Edit Mode")
    
    -- Selected frame text
    local selectedText = controlPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    selectedText:SetText("No frame selected")
    controlPanel.selectedText = selectedText
    
    -- Grid controls
    local gridLabel = controlPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gridLabel:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", 20, -50)
    gridLabel:SetText("Grid Size:")
    
    local gridSlider = CreateFrame("Slider", "WRVisualEditModeGridSlider", controlPanel, "OptionsSliderTemplate")
    gridSlider:SetWidth(180)
    gridSlider:SetHeight(20)
    gridSlider:SetPoint("TOP", gridLabel, "BOTTOM", 0, -10)
    gridSlider:SetMinMaxValues(1, 50)
    gridSlider:SetValueStep(1)
    gridSlider:SetObeyStepOnDrag(true)
    gridSlider:SetValue(gridSize)
    gridSlider.Low:SetText("1")
    gridSlider.High:SetText("50")
    gridSlider:SetScript("OnValueChanged", function(self, value)
        gridSize = value
        settings.gridSize = value
        VisualEditMode:SaveSettings()
        
        -- Update grid display
        if gridEnabled and editOverlay:IsVisible() then
            VisualEditMode:UpdateGrid()
        end
    end)
    
    -- Grid enable checkbox
    local gridCheck = CreateFrame("CheckButton", "WRVisualEditModeGridCheck", controlPanel, "UICheckButtonTemplate")
    gridCheck:SetPoint("TOPLEFT", gridSlider, "BOTTOMLEFT", -10, -10)
    gridCheck.text:SetText("Enable Grid")
    gridCheck:SetChecked(gridEnabled)
    gridCheck:SetScript("OnClick", function(self)
        gridEnabled = self:GetChecked()
        settings.gridEnabled = gridEnabled
        VisualEditMode:SaveSettings()
        
        -- Update grid display
        if editOverlay:IsVisible() then
            VisualEditMode:UpdateGrid()
        end
    end)
    
    -- Magnet controls
    local magnetLabel = controlPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    magnetLabel:SetPoint("TOPLEFT", gridCheck, "BOTTOMLEFT", 10, -10)
    magnetLabel:SetText("Magnet Distance:")
    
    local magnetSlider = CreateFrame("Slider", "WRVisualEditModeMagnetSlider", controlPanel, "OptionsSliderTemplate")
    magnetSlider:SetWidth(180)
    magnetSlider:SetHeight(20)
    magnetSlider:SetPoint("TOP", magnetLabel, "BOTTOM", 0, -10)
    magnetSlider:SetMinMaxValues(1, 20)
    magnetSlider:SetValueStep(1)
    magnetSlider:SetObeyStepOnDrag(true)
    magnetSlider:SetValue(magnet)
    magnetSlider.Low:SetText("1")
    magnetSlider.High:SetText("20")
    magnetSlider:SetScript("OnValueChanged", function(self, value)
        magnet = value
        settings.magnetDistance = value
        VisualEditMode:SaveSettings()
    end)
    
    -- Magnet enable checkbox
    local magnetCheck = CreateFrame("CheckButton", "WRVisualEditModeMagnetCheck", controlPanel, "UICheckButtonTemplate")
    magnetCheck:SetPoint("TOPLEFT", magnetSlider, "BOTTOMLEFT", -10, -10)
    magnetCheck.text:SetText("Enable Magnet")
    magnetCheck:SetChecked(magnetEnabled)
    magnetCheck:SetScript("OnClick", function(self)
        magnetEnabled = self:GetChecked()
        settings.magnetEnabled = magnetEnabled
        VisualEditMode:SaveSettings()
    end)
    
    -- Guide checkbox
    local guideCheck = CreateFrame("CheckButton", "WRVisualEditModeGuideCheck", controlPanel, "UICheckButtonTemplate")
    guideCheck:SetPoint("TOPLEFT", magnetCheck, "BOTTOMLEFT", 0, -10)
    guideCheck.text:SetText("Show Guides")
    guideCheck:SetChecked(settings.showGuides)
    guideCheck:SetScript("OnClick", function(self)
        settings.showGuides = self:GetChecked()
        VisualEditMode:SaveSettings()
        
        -- Update guide visibility
        VisualEditMode:UpdateGuideVisibility()
    end)
    
    -- Lock unselected checkbox
    local lockCheck = CreateFrame("CheckButton", "WRVisualEditModeLockCheck", controlPanel, "UICheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", guideCheck, "BOTTOMLEFT", 0, -10)
    lockCheck.text:SetText("Lock Unselected Frames")
    lockCheck:SetChecked(settings.lockUnselected)
    lockCheck:SetScript("OnClick", function(self)
        settings.lockUnselected = self:GetChecked()
        VisualEditMode:SaveSettings()
        
        -- Update frame locking
        VisualEditMode:UpdateFrameLocking()
    end)
    
    -- Buttons row
    local closeButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 25)
    closeButton:SetPoint("BOTTOMRIGHT", controlPanel, "BOTTOMRIGHT", -20, 20)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        VisualEditMode:Deactivate()
    end)
    
    local resetButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    resetButton:SetSize(80, 25)
    resetButton:SetPoint("RIGHT", closeButton, "LEFT", -10, 0)
    resetButton:SetText("Reset")
    resetButton:SetScript("OnClick", function()
        -- Show confirmation dialog
        StaticPopupDialogs["WR_RESET_LAYOUT_CONFIRM"] = {
            text = "Reset all frame positions to default?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                VisualEditMode:ResetAllFrames()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("WR_RESET_LAYOUT_CONFIRM")
    end)
    
    -- Undo/Redo buttons
    local undoButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    undoButton:SetSize(60, 25)
    undoButton:SetPoint("BOTTOMLEFT", controlPanel, "BOTTOMLEFT", 20, 20)
    undoButton:SetText("Undo")
    undoButton:SetScript("OnClick", function()
        VisualEditMode:Undo()
    end)
    
    local redoButton = CreateFrame("Button", nil, controlPanel, "UIPanelButtonTemplate")
    redoButton:SetSize(60, 25)
    redoButton:SetPoint("LEFT", undoButton, "RIGHT", 10, 0)
    redoButton:SetText("Redo")
    redoButton:SetScript("OnClick", function()
        VisualEditMode:Redo()
    end)
    
    -- Store references
    controlPanel.undoButton = undoButton
    controlPanel.redoButton = redoButton
}

-- Create frame overlay for a draggable frame
function VisualEditMode:CreateFrameOverlay(frame)
    if frame.editOverlay then
        return frame.editOverlay
    end
    
    -- Create overlay frame
    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    overlay:SetAllPoints(frame)
    overlay.targetFrame = frame
    overlay:Hide()
    
    -- Background texture
    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.8, 0.3)
    overlay.background = bg
    
    -- Border
    overlay:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    overlay:SetBackdropBorderColor(0.5, 0.5, 1.0, 1.0)
    
    -- Frame info text
    local infoText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOP", overlay, "TOP", 0, 15)
    infoText:SetTextColor(1, 1, 1, 1)
    overlay.infoText = infoText
    
    -- Handle dragging
    overlay:SetMovable(true)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    
    overlay:SetScript("OnDragStart", function(self)
        if not activeFrame then
            -- Save initial position for all selected frames
            for _, selectedFrame in pairs(selectedFrames) do
                local frameOverlay = selectedFrame.editOverlay
                if frameOverlay then
                    local point, relativeTo, relativePoint, xOfs, yOfs = selectedFrame:GetPoint()
                    frameOverlay.startPoint = {point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs}
                end
            end
            
            -- Start tracking cursor for the active frame
            local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
            dragStart.x, dragStart.y = GetCursorPosition()
            startPos.x, startPos.y = xOfs, yOfs
            
            activeFrame = frame
            dragMode = "move"
            
            -- Record initial state for undo
            VisualEditMode:RecordAction("move", selectedFrames)
        end
    end)
    
    overlay:SetScript("OnDragStop", function(self)
        if activeFrame == frame then
            activeFrame = nil
            
            -- Hide snap lines
            for _, line in ipairs(snapLines) do
                line:Hide()
            end
            
            -- Update frame info
            self:UpdateFrameInfo()
            
            -- Save positions
            VisualEditMode:SaveFramePositions()
        end
    end)
    
    overlay:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Select this frame
            VisualEditMode:SelectFrame(frame)
        elseif button == "RightButton" then
            -- Show context menu
            VisualEditMode:ShowContextMenu(frame)
        end
    end)
    
    -- Method to update frame info text
    function overlay:UpdateFrameInfo()
        local width, height = frame:GetSize()
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        local name = frame:GetName() or "Unnamed"
        
        local infoString = name .. "\n" .. 
                          math_floor(width + 0.5) .. "x" .. math_floor(height + 0.5) .. "\n" ..
                          "Pos: " .. math_floor(xOfs + 0.5) .. "," .. math_floor(yOfs + 0.5)
        
        self.infoText:SetText(infoString)
    end
    
    -- Create resize handles
    overlay.resizeHandles = {}
    
    for position, info in pairs(HANDLE_POSITIONS) do
        local handle = CreateFrame("Frame", nil, overlay)
        handle:SetSize(HANDLE_SIZE, HANDLE_SIZE)
        handle:SetPoint(info.anchor, overlay, info.anchor, info.xFactor * 2, info.yFactor * 2)
        handle:SetFrameLevel(overlay:GetFrameLevel() + 1)
        
        -- Background
        local bg = handle:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 0.8)
        
        -- Border
        handle:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        handle:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Make it draggable
        handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")
        
        handle.position = position
        handle.xFactor = info.xFactor
        handle.yFactor = info.yFactor
        
        handle:SetScript("OnDragStart", function(self)
            if not activeFrame then
                -- Save initial position and size
                local width, height = frame:GetSize()
                overlay.startSize = {width = width, height = height}
                
                local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
                overlay.startPoint = {point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs}
                
                dragStart.x, dragStart.y = GetCursorPosition()
                activeFrame = frame
                dragMode = "resize"
                
                -- Record initial state for undo
                VisualEditMode:RecordAction("resize", {frame})
            end
        end)
        
        handle:SetScript("OnDragStop", function(self)
            if activeFrame == frame then
                activeFrame = nil
                
                -- Update frame info
                overlay:UpdateFrameInfo()
                
                -- Save positions
                VisualEditMode:SaveFramePositions()
            end
        end)
        
        handle:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 1, 0, 1) -- Highlight on hover
        end)
        
        handle:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0, 0, 0, 1)
        end)
        
        overlay.resizeHandles[position] = handle
    end
    
    frame.editOverlay = overlay
    return overlay
end

-- Register a frame for edit mode
function VisualEditMode:RegisterFrame(frame, category)
    if not frame or not frame.SetPoint or not frame.GetPoint then
        return false
    end
    
    -- Check if already registered
    for _, regFrame in ipairs(registeredFrames) do
        if regFrame.frame == frame then
            return true
        end
    end
    
    -- Store the original SetPoint method
    if not frame._originalSetPoint then
        frame._originalSetPoint = frame.SetPoint
        frame.SetPoint = function(self, ...)
            -- Call original SetPoint
            self._originalSetPoint(self, ...)
            
            -- Update overlay if it exists and is visible
            if self.editOverlay and self.editOverlay:IsVisible() then
                self.editOverlay:ClearAllPoints()
                self.editOverlay:SetAllPoints(self)
                self.editOverlay:UpdateFrameInfo()
            end
        end
    end
    
    -- Create frame overlay
    self:CreateFrameOverlay(frame)
    
    -- Register frame
    tinsert(registeredFrames, {
        frame = frame,
        category = category or "Default"
    })
    
    return true
end

-- Unregister a frame
function VisualEditMode:UnregisterFrame(frame)
    for i, regFrame in ipairs(registeredFrames) do
        if regFrame.frame == frame then
            -- Remove from registered frames
            tremove(registeredFrames, i)
            
            -- Remove from selected frames
            self:UnselectFrame(frame)
            
            -- Destroy overlay
            if frame.editOverlay then
                frame.editOverlay:Hide()
                frame.editOverlay = nil
            end
            
            -- Restore original SetPoint
            if frame._originalSetPoint then
                frame.SetPoint = frame._originalSetPoint
                frame._originalSetPoint = nil
            end
            
            return true
        end
    end
    
    return false
end

-- Activate edit mode
function VisualEditMode:Activate()
    if isActive then return end
    
    isActive = true
    
    -- Show edit overlay
    editOverlay:Show()
    
    -- Show control panel
    controlPanel:Show()
    
    -- Update grid
    self:UpdateGrid()
    
    -- Show all registered frames
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        
        -- Store current position
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        storedPositions[frame] = {point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs}
        
        -- Make frame interactive
        frame:SetMovable(true)
        frame:EnableMouse(true)
    end
    
    -- Update frame locking
    self:UpdateFrameLocking()
    
    -- Clear selection
    self:ClearSelection()
    
    -- Clear history
    actionHistory = {}
    historyIndex = 0
    
    -- Set up magnetization points
    self:UpdateMagnetPoints()
    
    -- Announce activation
    print("Windrunner Rotations: Visual Edit Mode activated. Drag frames to reposition them.")
    print("Right-click for additional options. Close with the Edit Mode panel.")
end

-- Deactivate edit mode
function VisualEditMode:Deactivate()
    if not isActive then return end
    
    isActive = false
    
    -- Hide edit overlay
    editOverlay:Hide()
    
    -- Hide control panel
    controlPanel:Hide()
    
    -- Hide all frame overlays
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        if frame.editOverlay then
            frame.editOverlay:Hide()
        end
    end
    
    -- Clear selection
    self:ClearSelection()
    
    -- Save settings
    self:SaveSettings()
    
    -- Save frame positions
    self:SaveFramePositions()
    
    -- Announce deactivation
    print("Windrunner Rotations: Visual Edit Mode deactivated. Frame positions saved.")
end

-- Toggle edit mode
function VisualEditMode:Toggle()
    if isActive then
        self:Deactivate()
    else
        self:Activate()
    end
end

-- Select a frame
function VisualEditMode:SelectFrame(frame)
    -- Skip if frame is not registered
    local isRegistered = false
    for _, regFrame in ipairs(registeredFrames) do
        if regFrame.frame == frame then
            isRegistered = true
            break
        end
    end
    
    if not isRegistered then
        return
    end
    
    -- If not holding shift, clear current selection
    if not IsShiftKeyDown() then
        self:ClearSelection()
    end
    
    -- Check if already selected
    for _, selected in pairs(selectedFrames) do
        if selected == frame then
            return -- Already selected
        end
    end
    
    -- Add to selection
    tinsert(selectedFrames, frame)
    
    -- Show frame overlay
    if frame.editOverlay then
        frame.editOverlay:Show()
        frame.editOverlay:UpdateFrameInfo()
    end
    
    -- Update selection text
    self:UpdateSelectionText()
    
    -- Update frame locking
    self:UpdateFrameLocking()
}

-- Unselect a frame
function VisualEditMode:UnselectFrame(frame)
    for i, selected in ipairs(selectedFrames) do
        if selected == frame then
            -- Remove from selection
            tremove(selectedFrames, i)
            
            -- Hide frame overlay
            if frame.editOverlay then
                frame.editOverlay:Hide()
            end
            
            -- Update selection text
            self:UpdateSelectionText()
            
            -- Update frame locking
            self:UpdateFrameLocking()
            
            return
        end
    end
end

-- Clear all frame selections
function VisualEditMode:ClearSelection()
    -- Hide all frame overlays
    for _, selected in ipairs(selectedFrames) do
        if selected.editOverlay then
            selected.editOverlay:Hide()
        end
    end
    
    -- Clear selection
    selectedFrames = {}
    
    -- Update selection text
    self:UpdateSelectionText()
    
    -- Update frame locking
    self:UpdateFrameLocking()
}

-- Select frames inside a selection box
function VisualEditMode:SelectFramesInBox(selectionBox)
    local left, bottom = selectionBox:GetLeft(), selectionBox:GetBottom()
    local right, top = selectionBox:GetRight(), selectionBox:GetTop()
    
    -- Loop through all registered frames
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        
        -- Get frame position
        local frameLeft, frameBottom = frame:GetLeft(), frame:GetBottom()
        local frameRight, frameTop = frame:GetRight(), frame:GetTop()
        
        -- Check if frame is inside selection box
        if frameLeft >= left and frameRight <= right and
           frameBottom >= bottom and frameTop <= top then
            self:SelectFrame(frame)
        end
    end
}

-- Update grid display
function VisualEditMode:UpdateGrid()
    -- Clear existing grid lines
    for _, line in ipairs(editOverlay.gridLines) do
        line:Hide()
    end
    
    if not gridEnabled then
        return
    end
    
    -- Calculate number of lines needed
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    local numHorizontalLines = math.ceil(screenHeight / gridSize)
    local numVerticalLines = math.ceil(screenWidth / gridSize)
    local totalLines = numHorizontalLines + numVerticalLines
    
    -- Create lines if needed
    while #editOverlay.gridLines < totalLines do
        local line = editOverlay:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(0.5, 0.5, 0.5, 0.3)
        line:Hide()
        tinsert(editOverlay.gridLines, line)
    end
    
    -- Position horizontal grid lines
    for i = 1, numHorizontalLines do
        local line = editOverlay.gridLines[i]
        line:SetSize(screenWidth, 1)
        line:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, i * gridSize)
        line:Show()
    end
    
    -- Position vertical grid lines
    for i = 1, numVerticalLines do
        local line = editOverlay.gridLines[i + numHorizontalLines]
        line:SetSize(1, screenHeight)
        line:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", i * gridSize, 0)
        line:Show()
    end
}

-- Update guide visibility
function VisualEditMode:UpdateGuideVisibility()
    for _, guide in ipairs(guides.horizontal) do
        guide:SetShown(settings.showGuides)
    end
    
    for _, guide in ipairs(guides.vertical) do
        guide:SetShown(settings.showGuides)
    end
}

-- Update frame locking
function VisualEditMode:UpdateFrameLocking()
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        local isSelected = false
        
        -- Check if frame is selected
        for _, selected in ipairs(selectedFrames) do
            if selected == frame then
                isSelected = true
                break
            end
        end
        
        -- Update frame movability based on selection and settings
        if settings.lockUnselected and not isSelected then
            frame:SetMovable(false)
        else
            frame:SetMovable(true)
        end
    end
}

-- Update selection text in control panel
function VisualEditMode:UpdateSelectionText()
    if not controlPanel then return end
    
    if #selectedFrames == 0 then
        controlPanel.selectedText:SetText("No frame selected")
    elseif #selectedFrames == 1 then
        local frame = selectedFrames[1]
        local name = frame:GetName() or "Unnamed"
        controlPanel.selectedText:SetText("Selected: " .. name)
    else
        controlPanel.selectedText:SetText("Selected: " .. #selectedFrames .. " frames")
    end
end

-- Process frame movement
function VisualEditMode:ProcessFrameMovement()
    if not activeFrame or dragMode ~= "move" then return end
    
    -- Get cursor position
    local curX, curY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    
    -- Calculate offset
    local deltaX = (curX - dragStart.x) / scale
    local deltaY = (curY - dragStart.y) / scale
    
    -- Calculate new position
    local newX = startPos.x + deltaX
    local newY = startPos.y + deltaY
    
    -- Apply grid snapping if enabled
    if gridEnabled then
        newX = math_floor(newX / gridSize + 0.5) * gridSize
        newY = math_floor(newY / gridSize + 0.5) * gridSize
    end
    
    -- Apply magnetization if enabled
    local snapX, snapY = newX, newY
    
    if magnetEnabled then
        snapX, snapY = self:ApplyMagnetization(newX, newY)
        newX, newY = snapX, snapY
    end
    
    -- Apply position to all selected frames
    for _, frame in ipairs(selectedFrames) do
        if frame.editOverlay and frame.editOverlay.startPoint then
            local offsetX = newX - startPos.x
            local offsetY = newY - startPos.y
            
            local startPoint = frame.editOverlay.startPoint
            local xOfs = startPoint.xOfs + offsetX
            local yOfs = startPoint.yOfs + offsetY
            
            frame:ClearAllPoints()
            frame:SetPoint(startPoint.point, startPoint.relativeTo, startPoint.relativePoint, xOfs, yOfs)
        end
    end
}

-- Process frame resizing
function VisualEditMode:ProcessFrameResizing()
    if not activeFrame or dragMode ~= "resize" then return end
    
    local overlay = activeFrame.editOverlay
    if not overlay or not overlay.startSize then return end
    
    -- Get cursor position
    local curX, curY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    
    -- Calculate offset
    local deltaX = (curX - dragStart.x) / scale
    local deltaY = (curY - dragStart.y) / scale
    
    -- Determine which handle is being dragged
    local handle = nil
    for position, handleFrame in pairs(overlay.resizeHandles) do
        if GetMouseFocus() == handleFrame then
            handle = handleFrame
            break
        end
    end
    
    if not handle then return end
    
    -- Calculate new size
    local newWidth = overlay.startSize.width
    local newHeight = overlay.startSize.height
    local newX = overlay.startPoint.xOfs
    local newY = overlay.startPoint.yOfs
    
    -- Adjust size and position based on the handle being dragged
    if handle.xFactor ~= 0 then
        newWidth = overlay.startSize.width + deltaX * handle.xFactor
        
        -- If left side, adjust position too
        if handle.xFactor < 0 then
            newX = overlay.startPoint.xOfs + deltaX
        end
    end
    
    if handle.yFactor ~= 0 then
        newHeight = overlay.startSize.height + deltaY * handle.yFactor
        
        -- If bottom side, adjust position too
        if handle.yFactor < 0 then
            newY = overlay.startPoint.yOfs + deltaY
        end
    end
    
    -- Apply grid snapping if enabled
    if gridEnabled then
        newWidth = math_floor(newWidth / gridSize + 0.5) * gridSize
        newHeight = math_floor(newHeight / gridSize + 0.5) * gridSize
        newX = math_floor(newX / gridSize + 0.5) * gridSize
        newY = math_floor(newY / gridSize + 0.5) * gridSize
    end
    
    -- Apply size and position
    activeFrame:SetSize(math.max(10, newWidth), math.max(10, newHeight))
    activeFrame:ClearAllPoints()
    activeFrame:SetPoint(overlay.startPoint.point, overlay.startPoint.relativeTo, overlay.startPoint.relativePoint, newX, newY)
    
    -- Update frame info
    if overlay.UpdateFrameInfo then
        overlay:UpdateFrameInfo()
    end
}

-- Apply magnetization to a position
function VisualEditMode:ApplyMagnetization(x, y)
    -- Skip if no magnet points
    if #magnetPoints == 0 then
        return x, y
    end
    
    -- Track the closest snap points
    local closestX = {dist = magnet + 1, point = nil}
    local closestY = {dist = magnet + 1, point = nil}
    
    -- Check each magnet point
    for _, point in ipairs(magnetPoints) do
        -- X-axis snapping
        local distX = math_abs(point.x - x)
        if distX < closestX.dist then
            closestX.dist = distX
            closestX.point = point.x
        end
        
        -- Y-axis snapping
        local distY = math_abs(point.y - y)
        if distY < closestY.dist then
            closestY.dist = distY
            closestY.point = point.y
        end
    end
    
    -- Apply snapping and show snap lines
    for i, line in ipairs(snapLines) do
        line:Hide()
    end
    
    -- Apply X-axis snapping if within range
    if closestX.dist <= magnet then
        x = closestX.point
        
        -- Show vertical snap line
        local line = snapLines[1]
        line:SetWidth(1)
        line:SetHeight(UIParent:GetHeight())
        line:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, 0)
        line:Show()
    end
    
    -- Apply Y-axis snapping if within range
    if closestY.dist <= magnet then
        y = closestY.point
        
        -- Show horizontal snap line
        local line = snapLines[2]
        line:SetHeight(1)
        line:SetWidth(UIParent:GetWidth())
        line:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, y)
        line:Show()
    end
    
    return x, y
end

-- Update magnetization points based on registered frames
function VisualEditMode:UpdateMagnetPoints()
    magnetPoints = {}
    
    -- Add screen edges and center
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    tinsert(magnetPoints, {x = 0, y = 0}) -- Bottom-left
    tinsert(magnetPoints, {x = screenWidth, y = 0}) -- Bottom-right
    tinsert(magnetPoints, {x = 0, y = screenHeight}) -- Top-left
    tinsert(magnetPoints, {x = screenWidth, y = screenHeight}) -- Top-right
    tinsert(magnetPoints, {x = screenWidth/2, y = screenHeight/2}) -- Center
    tinsert(magnetPoints, {x = screenWidth/2, y = 0}) -- Bottom center
    tinsert(magnetPoints, {x = screenWidth/2, y = screenHeight}) -- Top center
    tinsert(magnetPoints, {x = 0, y = screenHeight/2}) -- Left center
    tinsert(magnetPoints, {x = screenWidth, y = screenHeight/2}) -- Right center
    
    -- Add registered frame edges and centers (except for selected frames)
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        local isSelected = false
        
        -- Skip selected frames
        for _, selected in ipairs(selectedFrames) do
            if selected == frame then
                isSelected = true
                break
            end
        end
        
        if not isSelected then
            local left, bottom = frame:GetLeft(), frame:GetBottom()
            local right, top = frame:GetRight(), frame:GetTop()
            local centerX, centerY = frame:GetCenter()
            
            if left and bottom and right and top and centerX and centerY then
                tinsert(magnetPoints, {x = left, y = bottom}) -- Bottom-left
                tinsert(magnetPoints, {x = right, y = bottom}) -- Bottom-right
                tinsert(magnetPoints, {x = left, y = top}) -- Top-left
                tinsert(magnetPoints, {x = right, y = top}) -- Top-right
                tinsert(magnetPoints, {x = centerX, y = centerY}) -- Center
                tinsert(magnetPoints, {x = centerX, y = bottom}) -- Bottom center
                tinsert(magnetPoints, {x = centerX, y = top}) -- Top center
                tinsert(magnetPoints, {x = left, y = centerY}) -- Left center
                tinsert(magnetPoints, {x = right, y = centerY}) -- Right center
            end
        end
    end
}

-- Save frame positions
function VisualEditMode:SaveFramePositions()
    -- Get current profile name
    local profileName = "Default"
    if WR.Config and WR.Config.GetCurrentProfile then
        profileName = WR.Config:GetCurrentProfile()
    end
    
    -- Initialize frame positions table
    if not WindrunnerRotationsDB.FramePositions then
        WindrunnerRotationsDB.FramePositions = {}
    end
    
    if not WindrunnerRotationsDB.FramePositions[profileName] then
        WindrunnerRotationsDB.FramePositions[profileName] = {}
    end
    
    -- Save positions for all registered frames
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        local name = frame:GetName()
        
        -- Only save frames with names
        if name then
            local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
            local width, height = frame:GetSize()
            
            -- Convert relativeTo to name if it's a frame
            local relativeToName = nil
            if relativeTo and relativeTo.GetName then
                relativeToName = relativeTo:GetName()
            end
            
            -- Store position data
            WindrunnerRotationsDB.FramePositions[profileName][name] = {
                point = point,
                relativeTo = relativeToName,
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs,
                width = width,
                height = height
            }
        end
    end
}

-- Load frame positions
function VisualEditMode:LoadFramePositions()
    -- Get current profile name
    local profileName = "Default"
    if WR.Config and WR.Config.GetCurrentProfile then
        profileName = WR.Config:GetCurrentProfile()
    end
    
    -- Check if positions exist
    if not WindrunnerRotationsDB or 
       not WindrunnerRotationsDB.FramePositions or 
       not WindrunnerRotationsDB.FramePositions[profileName] then
        return
    end
    
    -- Apply saved positions
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        local name = frame:GetName()
        
        -- Only load frames with names
        if name and WindrunnerRotationsDB.FramePositions[profileName][name] then
            local posData = WindrunnerRotationsDB.FramePositions[profileName][name]
            
            -- Get relativeTo by name
            local relativeTo = posData.relativeTo and _G[posData.relativeTo] or UIParent
            
            -- Apply position
            frame:ClearAllPoints()
            frame:SetPoint(posData.point, relativeTo, posData.relativePoint, posData.xOfs, posData.yOfs)
            
            -- Apply size if stored
            if posData.width and posData.height then
                frame:SetSize(posData.width, posData.height)
            end
        end
    end
end

-- Reset frame positions to default
function VisualEditMode:ResetAllFrames()
    for _, regFrame in ipairs(registeredFrames) do
        local frame = regFrame.frame
        
        -- Skip if no stored default position
        if not storedPositions[frame] then
            -- Try to center frame if no default
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        else
            -- Restore to default position
            local pos = storedPositions[frame]
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
        end
    end
    
    -- Update magnet points
    self:UpdateMagnetPoints()
}

-- Show context menu
function VisualEditMode:ShowContextMenu(frame)
    -- Clear any existing context menu
    if self.contextMenu then
        self.contextMenu:Hide()
    end
    
    -- Create context menu
    local menu = CreateFrame("Frame", "WRVisualEditModeContextMenu", UIParent, "BackdropTemplate")
    menu:SetSize(150, 200)
    menu:SetFrameStrata("DIALOG")
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Position menu at cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale, y/scale)
    
    -- Menu items
    local itemHeight = 20
    local items = {}
    local numItems = 0
    
    -- If frame is provided, show frame-specific options
    if frame then
        -- Center Frame option
        local centerItem = CreateFrame("Button", nil, menu)
        centerItem:SetSize(140, itemHeight)
        centerItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
        centerItem:SetText("Center Frame")
        centerItem:SetNormalFontObject("GameFontNormal")
        centerItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        centerItem:SetScript("OnClick", function()
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            menu:Hide()
        end)
        tinsert(items, centerItem)
        numItems = numItems + 1
        
        -- Reset Frame option
        local resetItem = CreateFrame("Button", nil, menu)
        resetItem:SetSize(140, itemHeight)
        resetItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
        resetItem:SetText("Reset Frame")
        resetItem:SetNormalFontObject("GameFontNormal")
        resetItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        resetItem:SetScript("OnClick", function()
            if storedPositions[frame] then
                local pos = storedPositions[frame]
                frame:ClearAllPoints()
                frame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
            end
            menu:Hide()
        end)
        tinsert(items, resetItem)
        numItems = numItems + 1
        
        -- Copy Frame option
        local copyItem = CreateFrame("Button", nil, menu)
        copyItem:SetSize(140, itemHeight)
        copyItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
        copyItem:SetText("Copy Frame")
        copyItem:SetNormalFontObject("GameFontNormal")
        copyItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        copyItem:SetScript("OnClick", function()
            -- Store frame data in clipboard
            clipboard = {
                width = frame:GetWidth(),
                height = frame:GetHeight(),
                point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
            }
            menu:Hide()
        end)
        tinsert(items, copyItem)
        numItems = numItems + 1
        
        -- Paste Frame option (only if clipboard has data)
        if clipboard then
            local pasteItem = CreateFrame("Button", nil, menu)
            pasteItem:SetSize(140, itemHeight)
            pasteItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
            pasteItem:SetText("Paste Frame")
            pasteItem:SetNormalFontObject("GameFontNormal")
            pasteItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            pasteItem:SetScript("OnClick", function()
                -- Apply clipboard data
                frame:SetSize(clipboard.width, clipboard.height)
                frame:ClearAllPoints()
                frame:SetPoint(clipboard.point, clipboard.relativeTo, clipboard.relativePoint, clipboard.xOfs, clipboard.yOfs)
                menu:Hide()
            end)
            tinsert(items, pasteItem)
            numItems = numItems + 1
        end
        
        -- Separator
        local separator = menu:CreateTexture(nil, "OVERLAY")
        separator:SetSize(140, 1)
        separator:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight - 2)
        separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        numItems = numItems + 0.5
    end
    
    -- Add general menu items
    
    -- Grid Settings option
    local gridItem = CreateFrame("Button", nil, menu)
    gridItem:SetSize(140, itemHeight)
    gridItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
    gridItem:SetText("Grid Settings")
    gridItem:SetNormalFontObject("GameFontNormal")
    gridItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    gridItem:SetScript("OnClick", function()
        -- Toggle grid
        gridEnabled = not gridEnabled
        settings.gridEnabled = gridEnabled
        
        -- Update UI
        self:UpdateGrid()
        
        -- Close menu
        menu:Hide()
    end)
    tinsert(items, gridItem)
    numItems = numItems + 1
    
    -- Magnet Settings option
    local magnetItem = CreateFrame("Button", nil, menu)
    magnetItem:SetSize(140, itemHeight)
    magnetItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
    magnetItem:SetText("Toggle Magnet")
    magnetItem:SetNormalFontObject("GameFontNormal")
    magnetItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    magnetItem:SetScript("OnClick", function()
        -- Toggle magnet
        magnetEnabled = not magnetEnabled
        settings.magnetEnabled = magnetEnabled
        
        -- Close menu
        menu:Hide()
    end)
    tinsert(items, magnetItem)
    numItems = numItems + 1
    
    -- Close Edit Mode option
    local closeItem = CreateFrame("Button", nil, menu)
    closeItem:SetSize(140, itemHeight)
    closeItem:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - numItems * itemHeight)
    closeItem:SetText("Close Edit Mode")
    closeItem:SetNormalFontObject("GameFontNormal")
    closeItem:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    closeItem:SetScript("OnClick", function()
        menu:Hide()
        self:Deactivate()
    end)
    tinsert(items, closeItem)
    numItems = numItems + 1
    
    -- Resize menu to fit items
    menu:SetHeight(10 + numItems * itemHeight)
    
    -- Set up hiding behavior
    menu:SetScript("OnLeave", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x = x / scale
        y = y / scale
        
        -- Get menu bounds
        local left, bottom = self:GetLeft(), self:GetBottom()
        local right, top = self:GetRight(), self:GetTop()
        
        -- Hide if cursor is outside menu
        if x < left or x > right or y < bottom or y > top then
            self:Hide()
        end
    end)
    
    for _, item in ipairs(items) do
        item:SetScript("OnEnter", function(self)
            -- Keep menu open while hovering items
            menu.isHovered = true
        end)
        
        item:SetScript("OnLeave", function(self)
            menu.isHovered = false
            
            -- Check if cursor is outside menu
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            x = x / scale
            y = y / scale
            
            -- Get menu bounds
            local left, bottom = menu:GetLeft(), menu:GetBottom()
            local right, top = menu:GetRight(), menu:GetTop()
            
            -- Hide if cursor is outside menu
            if x < left or x > right or y < bottom or y > top then
                menu:Hide()
            end
        end)
    end
    
    -- Store menu and show it
    self.contextMenu = menu
    menu:Show()
end

-- Record an action for undo/redo
function VisualEditMode:RecordAction(actionType, frames)
    -- Clear redo history if we're adding a new action in the middle
    while #actionHistory > historyIndex do
        table.remove(actionHistory)
    end
    
    -- Create new action
    local action = {
        type = actionType,
        frames = {},
        timestamp = GetTime()
    }
    
    -- Store frame data
    for _, frame in ipairs(frames) do
        local frameData = {
            frame = frame,
            width = frame:GetWidth(),
            height = frame:GetHeight()
        }
        
        -- Get point data
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        frameData.point = point
        frameData.relativeTo = relativeTo
        frameData.relativePoint = relativePoint
        frameData.xOfs = xOfs
        frameData.yOfs = yOfs
        
        table.insert(action.frames, frameData)
    end
    
    -- Add to history
    table.insert(actionHistory, action)
    historyIndex = #actionHistory
    
    -- Limit history size
    if #actionHistory > settings.undoLevels then
        table.remove(actionHistory, 1)
        historyIndex = #actionHistory
    end
    
    -- Update UI
    self:UpdateHistoryButtons()
}

-- Undo the last action
function VisualEditMode:Undo()
    if historyIndex < 1 then
        return
    end
    
    local action = actionHistory[historyIndex]
    historyIndex = historyIndex - 1
    
    -- Apply previous state
    for _, frameData in ipairs(action.frames) do
        frameData.frame:ClearAllPoints()
        frameData.frame:SetPoint(frameData.point, frameData.relativeTo, frameData.relativePoint, frameData.xOfs, frameData.yOfs)
        frameData.frame:SetSize(frameData.width, frameData.height)
        
        -- Update overlay
        if frameData.frame.editOverlay then
            frameData.frame.editOverlay:ClearAllPoints()
            frameData.frame.editOverlay:SetAllPoints(frameData.frame)
            if frameData.frame.editOverlay.UpdateFrameInfo then
                frameData.frame.editOverlay:UpdateFrameInfo()
            end
        end
    end
    
    -- Update UI
    self:UpdateHistoryButtons()
}

-- Redo the last undone action
function VisualEditMode:Redo()
    if historyIndex >= #actionHistory then
        return
    end
    
    historyIndex = historyIndex + 1
    local action = actionHistory[historyIndex]
    
    -- Apply next state
    for _, frameData in ipairs(action.frames) do
        frameData.frame:ClearAllPoints()
        frameData.frame:SetPoint(frameData.point, frameData.relativeTo, frameData.relativePoint, frameData.xOfs, frameData.yOfs)
        frameData.frame:SetSize(frameData.width, frameData.height)
        
        -- Update overlay
        if frameData.frame.editOverlay then
            frameData.frame.editOverlay:ClearAllPoints()
            frameData.frame.editOverlay:SetAllPoints(frameData.frame)
            if frameData.frame.editOverlay.UpdateFrameInfo then
                frameData.frame.editOverlay:UpdateFrameInfo()
            end
        end
    end
    
    -- Update UI
    self:UpdateHistoryButtons()
}

-- Update undo/redo button state
function VisualEditMode:UpdateHistoryButtons()
    if not controlPanel then return end
    
    -- Update undo button
    controlPanel.undoButton:SetEnabled(historyIndex > 0)
    
    -- Update redo button
    controlPanel.redoButton:SetEnabled(historyIndex < #actionHistory)
}

-- Main update function
function VisualEditMode:OnUpdate(elapsed)
    if not isActive then return end
    
    -- Process frame movement
    if activeFrame and dragMode == "move" then
        self:ProcessFrameMovement()
    elseif activeFrame and dragMode == "resize" then
        self:ProcessFrameResizing()
    end
}

-- Register with the main addon
function VisualEditMode:RegisterWithAddon()
    -- Set up update handler
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        VisualEditMode:OnUpdate(elapsed)
    end)
    
    -- Register slash command
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("editmode", function(msg)
            self:HandleSlashCommand(msg)
        end)
    end
    
    -- Add to settings panel
    if WR.UI and WR.UI.AdvancedSettingsUI then
        WR.UI.AdvancedSettingsUI:AddButton("Edit Mode", function()
            self:Toggle()
        end)
    end
}

-- Handle slash command
function VisualEditMode:HandleSlashCommand(msg)
    if not msg or msg == "" then
        self:Toggle()
        return
    end
    
    local command = msg:match("^(%S+)")
    if not command then
        self:Toggle()
        return
    end
    
    command = command:lower()
    
    if command == "toggle" then
        self:Toggle()
    elseif command == "on" or command == "enable" then
        self:Activate()
    elseif command == "off" or command == "disable" then
        self:Deactivate()
    elseif command == "grid" then
        gridEnabled = not gridEnabled
        settings.gridEnabled = gridEnabled
        self:UpdateGrid()
        print("Windrunner Rotations: Grid " .. (gridEnabled and "enabled" or "disabled"))
    elseif command == "magnet" then
        magnetEnabled = not magnetEnabled
        settings.magnetEnabled = magnetEnabled
        print("Windrunner Rotations: Magnet " .. (magnetEnabled and "enabled" or "disabled"))
    elseif command == "reset" then
        self:ResetAllFrames()
    elseif command == "save" then
        self:SaveFramePositions()
        print("Windrunner Rotations: Frame positions saved")
    elseif command == "load" then
        self:LoadFramePositions()
        print("Windrunner Rotations: Frame positions loaded")
    else
        print("Windrunner Rotations Visual Edit Mode commands:")
        print("  /editmode - Toggle edit mode")
        print("  /editmode on/off - Enable/disable edit mode")
        print("  /editmode grid - Toggle grid")
        print("  /editmode magnet - Toggle magnetization")
        print("  /editmode reset - Reset all frames to default positions")
        print("  /editmode save - Save frame positions")
        print("  /editmode load - Load frame positions")
    end
end

-- Initialize the module
VisualEditMode:Initialize()

return VisualEditMode