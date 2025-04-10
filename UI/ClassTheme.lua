local addonName, WR = ...

-- ClassTheme module for class-specific UI styling
local ClassTheme = {}
WR.UI = WR.UI or {}
WR.UI.ClassTheme = ClassTheme

-- Class color definitions (RGB values)
local CLASS_COLORS = {
    WARRIOR = {r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E"},
    PALADIN = {r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA"},
    HUNTER = {r = 0.67, g = 0.83, b = 0.45, hex = "ABD473"},
    ROGUE = {r = 1.00, g = 0.96, b = 0.41, hex = "FFF569"},
    PRIEST = {r = 1.00, g = 1.00, b = 1.00, hex = "FFFFFF"},
    DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23, hex = "C41F3B"},
    SHAMAN = {r = 0.00, g = 0.44, b = 0.87, hex = "0070DE"},
    MAGE = {r = 0.41, g = 0.80, b = 0.94, hex = "69CCF0"},
    WARLOCK = {r = 0.58, g = 0.51, b = 0.79, hex = "9482C9"},
    MONK = {r = 0.00, g = 1.00, b = 0.59, hex = "00FF96"},
    DRUID = {r = 1.00, g = 0.49, b = 0.04, hex = "FF7D0A"},
    DEMONHUNTER = {r = 0.64, g = 0.19, b = 0.79, hex = "A330C9"},
    EVOKER = {r = 0.20, g = 0.58, b = 0.50, hex = "33937F"}
}

-- UI element types for theming
local ELEMENT_TYPES = {
    BACKGROUND = "background",
    BORDER = "border",
    HEADER = "header",
    BUTTON = "button",
    TEXT = "text",
    ICON = "icon",
    STATUSBAR = "statusbar"
}

-- Theme settings
local THEME_PRESETS = {
    LIGHT = "light",
    DARK = "dark",
    CLASSIC = "classic",
    MINIMAL = "minimal",
    VIBRANT = "vibrant"
}

-- Current player class
local playerClass
local currentTheme = THEME_PRESETS.DARK
local themeIntensity = 0.8 -- 0.0 to 1.0, how strong the class color influence is

-- Registry of themed elements
local themedElements = {}

-- Initialize the module
function ClassTheme:Initialize()
    -- Determine player class
    local _, class = UnitClass("player")
    playerClass = class
    
    -- Initialize with settings
    local savedTheme = WR.Config:Get("UI", "theme") or THEME_PRESETS.DARK
    local savedIntensity = WR.Config:Get("UI", "themeIntensity") or 0.8
    
    self:SetTheme(savedTheme, savedIntensity)
    
    WR:Debug("ClassTheme module initialized for class:", playerClass)
end

-- Get class color
function ClassTheme:GetClassColor(class, alpha)
    class = class or playerClass
    alpha = alpha or 1.0
    
    local color = CLASS_COLORS[class] or CLASS_COLORS.WARRIOR
    return {r = color.r, g = color.g, b = color.b, a = alpha, hex = color.hex}
end

-- Apply theme to a specific element type
function ClassTheme:GetElementColor(elementType, class, alpha)
    class = class or playerClass
    alpha = alpha or 1.0
    
    local classColor = self:GetClassColor(class)
    local baseColor = {r = 0, g = 0, b = 0, a = alpha}
    
    -- Adjust base color based on theme
    if currentTheme == THEME_PRESETS.LIGHT then
        baseColor = {r = 0.9, g = 0.9, b = 0.9, a = alpha}
    elseif currentTheme == THEME_PRESETS.DARK then
        baseColor = {r = 0.15, g = 0.15, b = 0.15, a = alpha}
    elseif currentTheme == THEME_PRESETS.CLASSIC then
        baseColor = {r = 0.3, g = 0.3, b = 0.3, a = alpha}
    elseif currentTheme == THEME_PRESETS.MINIMAL then
        baseColor = {r = 0.05, g = 0.05, b = 0.05, a = alpha}
    elseif currentTheme == THEME_PRESETS.VIBRANT then
        baseColor = {r = 0.2, g = 0.2, b = 0.2, a = alpha}
    end
    
    -- Adjust intensity based on element type
    local intensity = themeIntensity
    
    if elementType == ELEMENT_TYPES.BACKGROUND then
        intensity = themeIntensity * 0.4
    elseif elementType == ELEMENT_TYPES.BORDER then
        intensity = themeIntensity * 0.6
    elseif elementType == ELEMENT_TYPES.HEADER then
        intensity = themeIntensity * 0.7
    elseif elementType == ELEMENT_TYPES.BUTTON then
        intensity = themeIntensity * 0.5
    elseif elementType == ELEMENT_TYPES.TEXT then
        -- For text, we want to ensure readability
        if currentTheme == THEME_PRESETS.LIGHT then
            baseColor = {r = 0.1, g = 0.1, b = 0.1, a = alpha}
            intensity = themeIntensity * 0.5
        else
            baseColor = {r = 0.9, g = 0.9, b = 0.9, a = alpha}
            intensity = themeIntensity * 0.3
        end
    elseif elementType == ELEMENT_TYPES.ICON then
        intensity = themeIntensity * 0.2 -- Subtle tinting for icons
    elseif elementType == ELEMENT_TYPES.STATUSBAR then
        intensity = themeIntensity * 0.9 -- Strong class coloring for status bars
    end
    
    -- Blend colors based on intensity
    local blendedColor = {
        r = baseColor.r * (1 - intensity) + classColor.r * intensity,
        g = baseColor.g * (1 - intensity) + classColor.g * intensity,
        b = baseColor.b * (1 - intensity) + classColor.b * intensity,
        a = alpha
    }
    
    -- Special handling for vibrant theme
    if currentTheme == THEME_PRESETS.VIBRANT then
        -- Make colors more saturated
        local r, g, b = blendedColor.r, blendedColor.g, blendedColor.b
        local max = math.max(r, g, b)
        local min = math.min(r, g, b)
        local lightness = (max + min) / 2
        local saturation = 0
        
        if max ~= min then
            if lightness <= 0.5 then
                saturation = (max - min) / (max + min)
            else
                saturation = (max - min) / (2 - max - min)
            end
            
            -- Increase saturation
            saturation = math.min(1, saturation * 1.5)
            
            -- Apply increased saturation
            if lightness <= 0.5 then
                max = lightness * (1 + saturation)
                min = lightness * (1 - saturation)
            else
                max = lightness + (1 - lightness) * saturation
                min = lightness - lightness * saturation
            end
            
            -- Recalculate RGB
            if max == r and g >= b then
                g = (g - b) * (max - min) / (r - b) + min
                r = max
                b = min
            elseif max == r and g < b then
                b = (b - g) * (max - min) / (r - g) + min
                r = max
                g = min
            elseif max == g then
                r = (r - b) * (max - min) / (g - b) + min
                g = max
                b = min
            else -- max == b
                g = (g - r) * (max - min) / (b - r) + min
                b = max
                r = min
            end
            
            blendedColor.r = r
            blendedColor.g = g
            blendedColor.b = b
        end
    end
    
    -- Add hex code for convenience
    blendedColor.hex = self:RGBToHex(blendedColor.r, blendedColor.g, blendedColor.b)
    
    return blendedColor
end

-- Get class gradient colors
function ClassTheme:GetClassGradient(class, startAlpha, endAlpha)
    class = class or playerClass
    startAlpha = startAlpha or 1.0
    endAlpha = endAlpha or startAlpha
    
    local color = self:GetClassColor(class)
    
    -- Create gradient colors with varying brightness
    local gradientStart = {
        r = math.min(1, color.r * 1.2),
        g = math.min(1, color.g * 1.2),
        b = math.min(1, color.b * 1.2),
        a = startAlpha
    }
    
    local gradientEnd = {
        r = math.max(0, color.r * 0.8),
        g = math.max(0, color.g * 0.8),
        b = math.max(0, color.b * 0.8),
        a = endAlpha
    }
    
    -- Add hex codes
    gradientStart.hex = self:RGBToHex(gradientStart.r, gradientStart.g, gradientStart.b)
    gradientEnd.hex = self:RGBToHex(gradientEnd.r, gradientEnd.g, gradientEnd.b)
    
    return gradientStart, gradientEnd
end

-- Get a color palette based on class color
function ClassTheme:GetClassPalette(class, count)
    class = class or playerClass
    count = count or 5
    
    local baseColor = self:GetClassColor(class)
    local palette = {}
    
    -- Generate a palette with variations of the class color
    -- For count = 5, we'll do: darkest, dark, base, light, lightest
    local factor = 0.2
    
    for i = 1, count do
        local adjustment = (i - (count + 1) / 2) * factor
        
        -- Create color variation
        local color = {
            r = math.max(0, math.min(1, baseColor.r + adjustment)),
            g = math.max(0, math.min(1, baseColor.g + adjustment)),
            b = math.max(0, math.min(1, baseColor.b + adjustment)),
            a = 1.0
        }
        
        -- Add hex code
        color.hex = self:RGBToHex(color.r, color.g, color.b)
        
        table.insert(palette, color)
    end
    
    return palette
end

-- Create complementary colors to class color
function ClassTheme:GetComplementaryColors(class)
    class = class or playerClass
    local baseColor = self:GetClassColor(class)
    
    -- Convert RGB to HSL
    local r, g, b = baseColor.r, baseColor.g, baseColor.b
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l
    
    l = (max + min) / 2
    
    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        
        h = h / 6
    end
    
    -- Create complementary color (180° shift)
    local complementaryH = (h + 0.5) % 1
    
    -- Create triadic colors (120° shifts)
    local triadicH1 = (h + 1/3) % 1
    local triadicH2 = (h + 2/3) % 1
    
    -- Convert HSL to RGB function
    local function hslToRgb(h, s, l)
        local r, g, b
        
        if s == 0 then
            r, g, b = l, l, l -- achromatic
        else
            local function hue2rgb(p, q, t)
                if t < 0 then t = t + 1 end
                if t > 1 then t = t - 1 end
                if t < 1/6 then return p + (q - p) * 6 * t end
                if t < 1/2 then return q end
                if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
                return p
            end
            
            local q = l < 0.5 and l * (1 + s) or l + s - l * s
            local p = 2 * l - q
            
            r = hue2rgb(p, q, h + 1/3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1/3)
        end
        
        return r, g, b
    end
    
    -- Generate complementary color
    local cr, cg, cb = hslToRgb(complementaryH, s, l)
    local complementary = {
        r = cr, g = cg, b = cb, a = 1.0,
        hex = self:RGBToHex(cr, cg, cb)
    }
    
    -- Generate triadic colors
    local tr1r, tr1g, tr1b = hslToRgb(triadicH1, s, l)
    local triadic1 = {
        r = tr1r, g = tr1g, b = tr1b, a = 1.0,
        hex = self:RGBToHex(tr1r, tr1g, tr1b)
    }
    
    local tr2r, tr2g, tr2b = hslToRgb(triadicH2, s, l)
    local triadic2 = {
        r = tr2r, g = tr2g, b = tr2b, a = 1.0,
        hex = self:RGBToHex(tr2r, tr2g, tr2b)
    }
    
    return {
        base = baseColor,
        complementary = complementary,
        triadic1 = triadic1,
        triadic2 = triadic2
    }
end

-- Helper function to convert RGB to hex
function ClassTheme:RGBToHex(r, g, b)
    r = math.floor(r * 255 + 0.5)
    g = math.floor(g * 255 + 0.5)
    b = math.floor(b * 255 + 0.5)
    return string.format("%02X%02X%02X", r, g, b)
end

-- Helper function to convert hex to RGB
function ClassTheme:HexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x"..hex:sub(1,2)) / 255, 
           tonumber("0x"..hex:sub(3,4)) / 255, 
           tonumber("0x"..hex:sub(5,6)) / 255
end

-- Set theme and intensity
function ClassTheme:SetTheme(theme, intensity)
    if THEME_PRESETS[theme:upper()] then
        currentTheme = theme
    end
    
    if intensity and intensity >= 0 and intensity <= 1 then
        themeIntensity = intensity
    end
    
    -- Save settings
    WR.Config:Set("UI", currentTheme, "theme")
    WR.Config:Set("UI", themeIntensity, "themeIntensity")
    
    -- Update all themed elements
    self:UpdateThemedElements()
    
    WR:Debug("Theme set to:", currentTheme, "with intensity:", themeIntensity)
end

-- Apply theme to a frame
function ClassTheme:ApplyThemeToFrame(frame, options)
    if not frame then return end
    
    options = options or {}
    local elemType = options.type or ELEMENT_TYPES.BACKGROUND
    local class = options.class or playerClass
    local alpha = options.alpha or 1.0
    
    -- Get appropriate color
    local color = self:GetElementColor(elemType, class, alpha)
    
    -- Apply color based on frame type and element type
    if frame:IsObjectType("Frame") or frame:IsObjectType("Button") then
        if elemType == ELEMENT_TYPES.BACKGROUND then
            if frame.SetBackdrop then
                local backdrop = frame:GetBackdrop()
                if backdrop then
                    frame:SetBackdropColor(color.r, color.g, color.b, color.a)
                else
                    frame:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                        tile = true,
                        tileSize = 16
                    })
                    frame:SetBackdropColor(color.r, color.g, color.b, color.a)
                end
            end
        elseif elemType == ELEMENT_TYPES.BORDER then
            if frame.SetBackdrop then
                local backdrop = frame:GetBackdrop()
                if backdrop then
                    frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
                end
            end
        elseif elemType == ELEMENT_TYPES.BUTTON then
            if frame:IsObjectType("Button") then
                -- Only apply if no custom textures are set
                if not frame:GetNormalTexture() then
                    frame:SetNormalFontObject("GameFontNormal")
                    if frame.SetNormalTexture then
                        frame:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
                        local tex = frame:GetNormalTexture()
                        if tex then
                            tex:SetVertexColor(color.r, color.g, color.b, color.a)
                        end
                    end
                end
            end
        end
    elseif frame:IsObjectType("StatusBar") then
        frame:SetStatusBarColor(color.r, color.g, color.b, color.a)
    elseif frame:IsObjectType("Texture") then
        frame:SetVertexColor(color.r, color.g, color.b, color.a)
    elseif frame:IsObjectType("FontString") then
        frame:SetTextColor(color.r, color.g, color.b, color.a)
    end
    
    -- Register this element for theme updates
    table.insert(themedElements, {
        frame = frame,
        options = options
    })
    
    return color
end

-- Apply gradient theme to a texture
function ClassTheme:ApplyGradientTheme(texture, orientation, class, startAlpha, endAlpha)
    if not texture then return end
    
    class = class or playerClass
    orientation = orientation or "HORIZONTAL" -- or "VERTICAL"
    startAlpha = startAlpha or 1.0
    endAlpha = endAlpha or startAlpha
    
    -- Get gradient colors
    local startColor, endColor = self:GetClassGradient(class, startAlpha, endAlpha)
    
    -- Apply gradient
    texture:SetGradient(orientation, 
        CreateColor(startColor.r, startColor.g, startColor.b, startAlpha),
        CreateColor(endColor.r, endColor.g, endColor.b, endAlpha)
    )
    
    -- Register for theme updates
    table.insert(themedElements, {
        frame = texture,
        options = {
            type = "gradient",
            class = class,
            orientation = orientation,
            startAlpha = startAlpha,
            endAlpha = endAlpha
        }
    })
    
    return startColor, endColor
end

-- Update all themed elements
function ClassTheme:UpdateThemedElements()
    for _, element in ipairs(themedElements) do
        if element.frame and element.frame:IsShown() then
            local options = element.options
            
            if options.type == "gradient" then
                self:ApplyGradientTheme(
                    element.frame,
                    options.orientation,
                    options.class,
                    options.startAlpha,
                    options.endAlpha
                )
            else
                self:ApplyThemeToFrame(element.frame, options)
            end
        end
    end
end

-- Apply class theme to all main UI components
function ClassTheme:ApplyThemeToUI()
    -- Apply to Enhanced UI if available
    if WR.UI.Enhanced then
        if WR.UI.Enhanced.mainContainer then
            self:ApplyThemeToFrame(WR.UI.Enhanced.mainContainer, {type = ELEMENT_TYPES.BACKGROUND})
            
            if WR.UI.Enhanced.classColorBackground then
                self:ApplyThemeToFrame(WR.UI.Enhanced.classColorBackground, {type = ELEMENT_TYPES.STATUSBAR})
            end
            
            if WR.UI.Enhanced.topBar then
                self:ApplyThemeToFrame(WR.UI.Enhanced.topBar, {type = ELEMENT_TYPES.HEADER})
            end
            
            if WR.UI.Enhanced.titleText then
                self:ApplyThemeToFrame(WR.UI.Enhanced.titleText, {type = ELEMENT_TYPES.TEXT})
            end
            
            if WR.UI.Enhanced.rotationDisplay then
                self:ApplyThemeToFrame(WR.UI.Enhanced.rotationDisplay, {type = ELEMENT_TYPES.BACKGROUND})
            end
            
            if WR.UI.Enhanced.abilityQueue then
                self:ApplyThemeToFrame(WR.UI.Enhanced.abilityQueue, {type = ELEMENT_TYPES.BACKGROUND})
            end
            
            if WR.UI.Enhanced.statusBar then
                self:ApplyThemeToFrame(WR.UI.Enhanced.statusBar, {type = ELEMENT_TYPES.HEADER})
            end
            
            if WR.UI.Enhanced.castBar then
                self:ApplyThemeToFrame(WR.UI.Enhanced.castBar, {type = ELEMENT_TYPES.STATUSBAR})
            end
            
            -- Apply to buttons
            local buttons = {
                WR.UI.Enhanced.toggleButton,
                WR.UI.Enhanced.settingsButton,
                WR.UI.Enhanced.profileButton,
                WR.UI.Enhanced.modeButton
            }
            
            for _, button in ipairs(buttons) do
                if button then
                    self:ApplyThemeToFrame(button, {type = ELEMENT_TYPES.BUTTON})
                end
            end
        end
    end
    
    -- Apply to ClassHUD if available
    if WR.UI.ClassHUD then
        if WR.UI.ClassHUD.mainFrame then
            self:ApplyThemeToFrame(WR.UI.ClassHUD.mainFrame, {type = ELEMENT_TYPES.BACKGROUND})
            
            if WR.UI.ClassHUD.classBar then
                self:ApplyThemeToFrame(WR.UI.ClassHUD.classBar, {type = ELEMENT_TYPES.STATUSBAR})
            end
            
            -- Apply to resource bars
            if WR.UI.ClassHUD.resourceBars then
                for _, bar in pairs(WR.UI.ClassHUD.resourceBars) do
                    if bar.bar then
                        self:ApplyThemeToFrame(bar.bar, {type = ELEMENT_TYPES.STATUSBAR})
                    end
                end
            end
        end
    end
    
    -- Apply to SettingsUI if available
    if WR.UI.SettingsUI then
        if WR.UI.SettingsUI.mainFrame then
            self:ApplyThemeToFrame(WR.UI.SettingsUI.mainFrame, {type = ELEMENT_TYPES.BACKGROUND})
            
            if WR.UI.SettingsUI.titleText then
                self:ApplyThemeToFrame(WR.UI.SettingsUI.titleText, {type = ELEMENT_TYPES.TEXT})
            end
            
            if WR.UI.SettingsUI.categoryFrame then
                self:ApplyThemeToFrame(WR.UI.SettingsUI.categoryFrame, {type = ELEMENT_TYPES.BACKGROUND})
            end
            
            if WR.UI.SettingsUI.configFrame then
                self:ApplyThemeToFrame(WR.UI.SettingsUI.configFrame, {type = ELEMENT_TYPES.BACKGROUND})
            end
        end
    end
    
    -- Apply to ProfileUI if available
    if WR.UI.Profile then
        if WR.UI.Profile.profileFrame then
            self:ApplyThemeToFrame(WR.UI.Profile.profileFrame, {type = ELEMENT_TYPES.BACKGROUND})
        end
    end
end

-- Create a theme selector UI
function ClassTheme:CreateThemeSelector(parent)
    if not parent then return end
    
    -- Create the theme selector frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsThemeSelector", parent, "BackdropTemplate")
    frame:SetSize(300, 200)
    frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Theme Settings")
    
    -- Theme dropdown
    local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -50)
    dropdownLabel:SetText("Theme:")
    
    local dropdown = CreateFrame("Frame", "WindrunnerRotationsThemeDropdown", frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", dropdownLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, currentTheme:gsub("^%l", string.upper))
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for _, theme in pairs(THEME_PRESETS) do
            info.text = theme:gsub("^%l", string.upper)
            info.value = theme
            info.checked = (currentTheme == theme)
            info.func = function(self)
                UIDropDownMenu_SetText(dropdown, self.text)
                ClassTheme:SetTheme(self.value, themeIntensity)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    -- Intensity slider
    local sliderLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sliderLabel:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", 0, -20)
    sliderLabel:SetText("Color Intensity:")
    
    local slider = CreateFrame("Slider", "WindrunnerRotationsThemeSlider", frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", sliderLabel, "BOTTOMLEFT", 20, -10)
    slider:SetWidth(260)
    slider:SetHeight(16)
    slider:SetMinMaxValues(0, 100)
    slider:SetValue(themeIntensity * 100)
    slider:SetValueStep(5)
    slider:SetObeyStepOnDrag(true)
    
    -- Set labels
    _G[slider:GetName() .. "Low"]:SetText("Subtle")
    _G[slider:GetName() .. "High"]:SetText("Vibrant")
    _G[slider:GetName() .. "Text"]:SetText(themeIntensity * 100 .. "%")
    
    -- Set behavior
    slider:SetScript("OnValueChanged", function(self, value)
        local intensity = value / 100
        _G[self:GetName() .. "Text"]:SetText(value .. "%")
        ClassTheme:SetTheme(currentTheme, intensity)
    end)
    
    -- Theme preview
    local previewLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -20, -20)
    previewLabel:SetText("Preview:")
    
    -- Create preview color swatches
    local swatchSize = 20
    local swatchSpacing = 5
    local startX = 20
    local swatchY = -170
    
    local elementTypes = {
        ELEMENT_TYPES.BACKGROUND,
        ELEMENT_TYPES.BORDER,
        ELEMENT_TYPES.HEADER,
        ELEMENT_TYPES.BUTTON,
        ELEMENT_TYPES.STATUSBAR
    }
    
    for i, elemType in ipairs(elementTypes) do
        local swatch = frame:CreateTexture(nil, "ARTWORK")
        swatch:SetSize(swatchSize, swatchSize)
        swatch:SetPoint("TOPLEFT", frame, "TOPLEFT", startX + (i-1) * (swatchSize + swatchSpacing), swatchY)
        
        local color = self:GetElementColor(elemType)
        swatch:SetColorTexture(color.r, color.g, color.b, 1.0)
        
        -- Add a border
        local border = frame:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", swatch, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.5, 0.5, 0.5, 1.0)
        
        -- Add to themed elements for updates
        table.insert(themedElements, {
            frame = swatch,
            options = {
                type = elemType
            }
        })
        
        -- Create label
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", swatch, "BOTTOM", 0, -2)
        label:SetText(elemType:gsub("^%l", string.upper))
    end
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 22)
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    -- Apply theme to selector itself
    self:ApplyThemeToFrame(frame, {type = ELEMENT_TYPES.BACKGROUND})
    self:ApplyThemeToFrame(title, {type = ELEMENT_TYPES.TEXT})
    self:ApplyThemeToFrame(closeButton, {type = ELEMENT_TYPES.BUTTON})
    
    -- Hide by default
    frame:Hide()
    
    -- Add methods
    frame.Show = function(self)
        -- Update dropdown and slider values
        UIDropDownMenu_SetText(dropdown, currentTheme:gsub("^%l", string.upper))
        slider:SetValue(themeIntensity * 100)
        
        -- Show the frame
        getmetatable(self).__index.Show(self)
    end
    
    return frame
end

-- Initialize the module
ClassTheme:Initialize()

return ClassTheme