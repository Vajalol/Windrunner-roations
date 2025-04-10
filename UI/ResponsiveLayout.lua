local addonName, WR = ...

-- ResponsiveLayout module for creating adaptive UI layouts
local ResponsiveLayout = {}
WR.UI = WR.UI or {}
WR.UI.ResponsiveLayout = ResponsiveLayout

-- Screen size breakpoints
local BREAKPOINTS = {
    XS = 1024,  -- Extra small screens
    S = 1280,   -- Small screens
    M = 1600,   -- Medium screens
    L = 1920,   -- Large screens
    XL = 2560   -- Extra large screens
}

-- Current screen size information
local screenWidth, screenHeight
local currentBreakpoint

-- Frame registry for responsive frames
local responsiveFrames = {}

-- Initialize the module
function ResponsiveLayout:Initialize()
    -- Get initial screen dimensions
    self:UpdateScreenDimensions()
    
    -- Create event frame for screen size changes
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        -- Update dimensions and apply responsive layouts
        ResponsiveLayout:UpdateScreenDimensions()
        ResponsiveLayout:ApplyResponsiveLayouts()
    end)
    
    self.eventFrame = eventFrame
    
    WR:Debug("ResponsiveLayout module initialized")
end

-- Update screen dimensions
function ResponsiveLayout:UpdateScreenDimensions()
    screenWidth, screenHeight = GetPhysicalScreenSize()
    
    -- Determine current breakpoint
    if screenWidth <= BREAKPOINTS.XS then
        currentBreakpoint = "XS"
    elseif screenWidth <= BREAKPOINTS.S then
        currentBreakpoint = "S"
    elseif screenWidth <= BREAKPOINTS.M then
        currentBreakpoint = "M"
    elseif screenWidth <= BREAKPOINTS.L then
        currentBreakpoint = "L"
    else
        currentBreakpoint = "XL"
    end
    
    WR:Debug("Screen size updated:", screenWidth, "x", screenHeight, "Breakpoint:", currentBreakpoint)
end

-- Register a frame for responsive layout
function ResponsiveLayout:RegisterFrame(frame, layouts, defaultLayout)
    if not frame or not layouts then return end
    
    -- Store the frame and its layouts
    responsiveFrames[frame] = {
        layouts = layouts,
        defaultLayout = defaultLayout or "M"
    }
    
    -- Apply initial layout
    self:ApplyLayoutToFrame(frame)
end

-- Apply the appropriate layout to a registered frame
function ResponsiveLayout:ApplyLayoutToFrame(frame)
    if not responsiveFrames[frame] then return end
    
    local frameData = responsiveFrames[frame]
    local layout = frameData.layouts[currentBreakpoint] or frameData.layouts[frameData.defaultLayout]
    
    if not layout then return end
    
    -- Apply the layout
    self:ApplyLayout(frame, layout)
end

-- Apply a layout configuration to a frame
function ResponsiveLayout:ApplyLayout(frame, layout)
    if not frame or not layout then return end
    
    -- Apply size
    if layout.width and layout.height then
        frame:SetSize(layout.width, layout.height)
    elseif layout.width then
        frame:SetWidth(layout.width)
    elseif layout.height then
        frame:SetHeight(layout.height)
    end
    
    -- Apply position
    if layout.position then
        frame:ClearAllPoints()
        
        if type(layout.position) == "table" and layout.position.point then
            frame:SetPoint(
                layout.position.point,
                layout.position.relativeTo or UIParent,
                layout.position.relativePoint or layout.position.point,
                layout.position.x or 0,
                layout.position.y or 0
            )
        end
    end
    
    -- Apply scale
    if layout.scale then
        frame:SetScale(layout.scale)
    end
    
    -- Apply alpha
    if layout.alpha then
        frame:SetAlpha(layout.alpha)
    end
    
    -- Apply custom function
    if layout.applyFunc and type(layout.applyFunc) == "function" then
        layout.applyFunc(frame)
    end
    
    -- Apply to child frames if specified
    if layout.children then
        for childName, childLayout in pairs(layout.children) do
            local childFrame = _G[childName]
            if not childFrame and frame[childName] then
                childFrame = frame[childName]
            end
            
            if childFrame then
                self:ApplyLayout(childFrame, childLayout)
            end
        end
    end
end

-- Apply responsive layouts to all registered frames
function ResponsiveLayout:ApplyResponsiveLayouts()
    for frame, _ in pairs(responsiveFrames) do
        if frame:IsShown() then
            self:ApplyLayoutToFrame(frame)
        end
    end
end

-- Create a responsive frame with layouts for different screen sizes
function ResponsiveLayout:CreateResponsiveFrame(name, parent, template, layouts, defaultLayout)
    -- Create the frame
    local frame = CreateFrame("Frame", name, parent, template)
    
    -- Register it for responsive layout
    self:RegisterFrame(frame, layouts, defaultLayout)
    
    return frame
end

-- Create a responsive button with layouts for different screen sizes
function ResponsiveLayout:CreateResponsiveButton(name, parent, template, layouts, defaultLayout)
    -- Create the button
    local button = CreateFrame("Button", name, parent, template)
    
    -- Register it for responsive layout
    self:RegisterFrame(button, layouts, defaultLayout)
    
    return button
end

-- Create responsive layouts for the main UI frames
function ResponsiveLayout:SetupMainUI()
    -- Main frame layouts for different screen sizes
    local mainFrameLayouts = {
        XS = {
            width = 280,
            height = 420,
            scale = 0.9,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        S = {
            width = 320,
            height = 450,
            scale = 0.95,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        M = {
            width = 350,
            height = 480,
            scale = 1.0,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        L = {
            width = 380,
            height = 510,
            scale = 1.05,
            position = {
                point = "CENTER",
                x = 150,
                y = 0
            }
        },
        XL = {
            width = 420,
            height = 550,
            scale = 1.1,
            position = {
                point = "CENTER",
                x = 300,
                y = 0
            }
        }
    }
    
    -- Class HUD layouts for different screen sizes
    local classHUDLayouts = {
        XS = {
            width = 220,
            height = 140,
            scale = 0.9,
            position = {
                point = "CENTER",
                x = 0,
                y = -180
            }
        },
        S = {
            width = 250,
            height = 150,
            scale = 0.95,
            position = {
                point = "CENTER",
                x = 0,
                y = -190
            }
        },
        M = {
            width = 280,
            height = 160,
            scale = 1.0,
            position = {
                point = "CENTER",
                x = 0,
                y = -200
            }
        },
        L = {
            width = 310,
            height = 170,
            scale = 1.05,
            position = {
                point = "CENTER",
                x = 150,
                y = -210
            }
        },
        XL = {
            width = 340,
            height = 180,
            scale = 1.1,
            position = {
                point = "CENTER",
                x = 300,
                y = -220
            }
        }
    }
    
    -- Settings UI layouts for different screen sizes
    local settingsUILayouts = {
        XS = {
            width = 600,
            height = 450,
            scale = 0.9,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        S = {
            width = 620,
            height = 470,
            scale = 0.95,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        M = {
            width = 650,
            height = 500,
            scale = 1.0,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        L = {
            width = 680,
            height = 530,
            scale = 1.05,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        },
        XL = {
            width = 720,
            height = 560,
            scale = 1.1,
            position = {
                point = "CENTER",
                x = 0,
                y = 0
            }
        }
    }
    
    -- Register main frames if they exist
    if WR.UI.Enhanced and WR.UI.Enhanced.mainContainer then
        self:RegisterFrame(WR.UI.Enhanced.mainContainer, mainFrameLayouts)
    end
    
    if WR.UI.ClassHUD and WR.UI.ClassHUD.mainFrame then
        self:RegisterFrame(WR.UI.ClassHUD.mainFrame, classHUDLayouts)
    end
    
    if WR.UI.SettingsUI and WR.UI.SettingsUI.mainFrame then
        self:RegisterFrame(WR.UI.SettingsUI.mainFrame, settingsUILayouts)
    end
    
    -- Apply the layouts
    self:ApplyResponsiveLayouts()
end

-- Create a grid system for layouts
function ResponsiveLayout:CreateGrid(parent, rows, columns, cellWidth, cellHeight, spacing)
    if not parent then return {} end
    
    local grid = {}
    local xOffset, yOffset = 0, 0
    
    for row = 1, rows do
        grid[row] = {}
        for col = 1, columns do
            -- Create cell frame
            local cell = CreateFrame("Frame", nil, parent)
            cell:SetSize(cellWidth, cellHeight)
            cell:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -yOffset)
            
            -- Store in grid
            grid[row][col] = cell
            
            -- Update x position for next cell
            xOffset = xOffset + cellWidth + spacing
        end
        -- Reset x position and update y position for next row
        xOffset = 0
        yOffset = yOffset + cellHeight + spacing
    end
    
    return grid
end

-- Add responsive behavior to an existing frame
function ResponsiveLayout:MakeFrameResponsive(frame, config)
    if not frame or not config then return end
    
    -- Default responsive behavior
    frame:HookScript("OnSizeChanged", function(self, width, height)
        -- Handle size change based on config
        if config.onSizeChanged then
            config.onSizeChanged(self, width, height)
        end
        
        -- Auto-resize child frames if specified
        if config.autoResizeChildren then
            for _, childName in ipairs(config.autoResizeChildren) do
                local child = self[childName]
                if child then
                    if config.childSizeRatio then
                        local ratio = config.childSizeRatio[childName] or {w = 1, h = 1}
                        child:SetSize(width * ratio.w, height * ratio.h)
                    end
                end
            end
        end
    end)
    
    -- Handle screen size breakpoint changes
    table.insert(responsiveFrames, {
        frame = frame,
        config = config
    })
end

-- Get current screen dimensions and breakpoint
function ResponsiveLayout:GetScreenInfo()
    return {
        width = screenWidth,
        height = screenHeight,
        breakpoint = currentBreakpoint
    }
end

-- Initialize module
ResponsiveLayout:Initialize()

return ResponsiveLayout