local addonName, WR = ...

-- Animation System module
local AnimationSystem = {}
WR.UI = WR.UI or {}
WR.UI.AnimationSystem = AnimationSystem

-- Animation types
local ANIMATION_TYPES = {
    FADE_IN = "fadeIn",
    FADE_OUT = "fadeOut",
    SCALE_UP = "scaleUp",
    SCALE_DOWN = "scaleDown",
    SLIDE_IN_TOP = "slideInTop",
    SLIDE_IN_BOTTOM = "slideInBottom",
    SLIDE_IN_LEFT = "slideInLeft",
    SLIDE_IN_RIGHT = "slideInRight",
    SLIDE_OUT_TOP = "slideOutTop",
    SLIDE_OUT_BOTTOM = "slideOutBottom",
    SLIDE_OUT_LEFT = "slideOutLeft",
    SLIDE_OUT_RIGHT = "slideOutRight",
    PULSE = "pulse",
    FLASH = "flash",
    BOUNCE = "bounce",
    ROTATE = "rotate",
    COLOR_SHIFT = "colorShift"
}

-- Animation presets
local ANIMATION_PRESETS = {
    SMOOTH = "smooth",
    QUICK = "quick",
    ELASTIC = "elastic",
    BOUNCE = "bounce"
}

-- Smoothing types
local SMOOTHING_TYPES = {
    IN = "IN",
    OUT = "OUT",
    IN_OUT = "IN_OUT"
}

-- Animation registry to keep track of all animations
local animationRegistry = {}

-- Initialize the animation system
function AnimationSystem:Initialize()
    WR:Debug("Animation System initialized")
end

-- Create an animation group for a frame
function AnimationSystem:CreateAnimationGroup(frame, name, looping)
    if not frame then return nil end
    
    -- Create the animation group
    local group = frame:CreateAnimationGroup(name)
    
    -- Set looping behavior if specified
    if looping then
        if looping == "REPEAT" or looping == "BOUNCE" then
            group:SetLooping(looping)
        else
            group:SetLooping("NONE")
        end
    end
    
    -- Add to registry
    local id = name or "AnimGroup_" .. math.random(1000, 9999)
    animationRegistry[id] = group
    
    return group, id
end

-- Add a fade animation to a group
function AnimationSystem:AddFadeAnimation(group, fromAlpha, toAlpha, duration, delay, smoothType)
    if not group then return nil end
    
    local animation = group:CreateAnimation("Alpha")
    animation:SetFromAlpha(fromAlpha or 0)
    animation:SetToAlpha(toAlpha or 1)
    animation:SetDuration(duration or 0.3)
    
    if delay and delay > 0 then
        animation:SetStartDelay(delay)
    end
    
    if smoothType then
        animation:SetSmoothing(smoothType)
    end
    
    return animation
end

-- Add a scale animation to a group
function AnimationSystem:AddScaleAnimation(group, fromScaleX, fromScaleY, toScaleX, toScaleY, duration, delay, smoothType, originPoint, originX, originY)
    if not group then return nil end
    
    local animation = group:CreateAnimation("Scale")
    animation:SetScaleFrom(fromScaleX or 1, fromScaleY or 1)
    animation:SetScaleTo(toScaleX or 1, toScaleY or 1)
    animation:SetDuration(duration or 0.3)
    
    if delay and delay > 0 then
        animation:SetStartDelay(delay)
    end
    
    if smoothType then
        animation:SetSmoothing(smoothType)
    end
    
    if originPoint then
        animation:SetOrigin(originPoint, originX or 0, originY or 0)
    end
    
    return animation
end

-- Add a translation animation to a group
function AnimationSystem:AddTranslationAnimation(group, offsetX, offsetY, duration, delay, smoothType)
    if not group then return nil end
    
    local animation = group:CreateAnimation("Translation")
    animation:SetOffset(offsetX or 0, offsetY or 0)
    animation:SetDuration(duration or 0.3)
    
    if delay and delay > 0 then
        animation:SetStartDelay(delay)
    end
    
    if smoothType then
        animation:SetSmoothing(smoothType)
    end
    
    return animation
end

-- Add a rotation animation to a group
function AnimationSystem:AddRotationAnimation(group, rotation, duration, delay, smoothType, originPoint, originX, originY)
    if not group then return nil end
    
    local animation = group:CreateAnimation("Rotation")
    animation:SetDegrees(rotation or 360)
    animation:SetDuration(duration or 0.3)
    
    if delay and delay > 0 then
        animation:SetStartDelay(delay)
    end
    
    if smoothType then
        animation:SetSmoothing(smoothType)
    end
    
    if originPoint then
        animation:SetOrigin(originPoint, originX or 0, originY or 0)
    end
    
    return animation
end

-- Create a fade in animation preset
function AnimationSystem:CreateFadeIn(frame, duration, delay, callback)
    if not frame then return nil end
    
    -- Hide the frame first
    frame:SetAlpha(0)
    frame:Show()
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "FadeIn_" .. tostring(frame))
    
    -- Add the fade animation
    self:AddFadeAnimation(group, 0, 1, duration or 0.3, delay, SMOOTHING_TYPES.OUT)
    
    -- Set callback
    if callback then
        group:SetScript("OnFinished", callback)
    end
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a fade out animation preset
function AnimationSystem:CreateFadeOut(frame, duration, delay, callback)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "FadeOut_" .. tostring(frame))
    
    -- Add the fade animation
    self:AddFadeAnimation(group, 1, 0, duration or 0.3, delay, SMOOTHING_TYPES.IN)
    
    -- Set callback
    if not callback then
        callback = function() frame:Hide() end
    end
    
    group:SetScript("OnFinished", callback)
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a scale up animation preset
function AnimationSystem:CreateScaleUp(frame, duration, delay, callback)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "ScaleUp_" .. tostring(frame))
    
    -- Add the scale animation
    self:AddScaleAnimation(group, 0.5, 0.5, 1, 1, duration or 0.3, delay, SMOOTHING_TYPES.OUT, "CENTER", 0, 0)
    
    -- Set callback
    if callback then
        group:SetScript("OnFinished", callback)
    end
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a scale down animation preset
function AnimationSystem:CreateScaleDown(frame, duration, delay, callback)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "ScaleDown_" .. tostring(frame))
    
    -- Add the scale animation
    self:AddScaleAnimation(group, 1, 1, 0.5, 0.5, duration or 0.3, delay, SMOOTHING_TYPES.IN, "CENTER", 0, 0)
    
    -- Set callback
    if callback then
        group:SetScript("OnFinished", callback)
    end
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a slide in animation preset
function AnimationSystem:CreateSlideIn(frame, direction, distance, duration, delay, callback)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "SlideIn_" .. tostring(frame))
    
    -- Initial position
    local offsetX, offsetY = 0, 0
    
    if direction == "TOP" then
        offsetY = distance or 100
    elseif direction == "BOTTOM" then
        offsetY = -distance or -100
    elseif direction == "LEFT" then
        offsetX = -distance or -100
    elseif direction == "RIGHT" then
        offsetX = distance or 100
    end
    
    -- Position the frame offscreen
    frame:SetPoint("CENTER", offsetX, offsetY)
    
    -- Add the translation animation
    self:AddTranslationAnimation(group, -offsetX, -offsetY, duration or 0.3, delay, SMOOTHING_TYPES.OUT)
    
    -- Set callback
    if callback then
        group:SetScript("OnFinished", callback)
    end
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a slide out animation preset
function AnimationSystem:CreateSlideOut(frame, direction, distance, duration, delay, callback)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "SlideOut_" .. tostring(frame))
    
    -- Calculate offset
    local offsetX, offsetY = 0, 0
    
    if direction == "TOP" then
        offsetY = distance or 100
    elseif direction == "BOTTOM" then
        offsetY = -distance or -100
    elseif direction == "LEFT" then
        offsetX = -distance or -100
    elseif direction == "RIGHT" then
        offsetX = distance or 100
    end
    
    -- Add the translation animation
    self:AddTranslationAnimation(group, offsetX, offsetY, duration or 0.3, delay, SMOOTHING_TYPES.IN)
    
    -- Set callback
    if not callback then
        callback = function() frame:Hide() end
    end
    
    group:SetScript("OnFinished", callback)
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a pulse animation preset
function AnimationSystem:CreatePulse(frame, magnitude, duration, delay, looping)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "Pulse_" .. tostring(frame), looping or "BOUNCE")
    
    -- Add the scale animation
    self:AddScaleAnimation(group, 1, 1, magnitude or 1.2, magnitude or 1.2, duration or 0.5, delay, SMOOTHING_TYPES.IN_OUT, "CENTER", 0, 0)
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a flash animation preset
function AnimationSystem:CreateFlash(frame, duration, delay, looping, r, g, b, a)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "Flash_" .. tostring(frame), looping or "REPEAT")
    
    -- Create flash texture if it doesn't exist
    if not frame.flashTexture then
        frame.flashTexture = frame:CreateTexture(nil, "OVERLAY")
        frame.flashTexture:SetAllPoints(frame)
        frame.flashTexture:SetColorTexture(r or 1, g or 1, b or 1, a or 0.4)
        frame.flashTexture:SetBlendMode("ADD")
        frame.flashTexture:SetAlpha(0)
    end
    
    -- Add the fade animations
    local fadeIn = self:AddFadeAnimation(group, 0, 1, (duration or 0.6) / 2, delay, SMOOTHING_TYPES.IN)
    local fadeOut = self:AddFadeAnimation(group, 1, 0, (duration or 0.6) / 2, (duration or 0.6) / 2, SMOOTHING_TYPES.OUT)
    
    fadeIn:SetChildKey("flashTexture")
    fadeOut:SetChildKey("flashTexture")
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a bounce animation preset
function AnimationSystem:CreateBounce(frame, height, duration, delay, looping)
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "Bounce_" .. tostring(frame), looping or "REPEAT")
    
    -- Add the translation animations
    local up = self:AddTranslationAnimation(group, 0, -(height or 10), (duration or 0.6) / 2, delay, SMOOTHING_TYPES.OUT)
    local down = self:AddTranslationAnimation(group, 0, (height or 10), (duration or 0.6) / 2, (duration or 0.6) / 2, SMOOTHING_TYPES.IN)
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Create a color shift animation preset
function AnimationSystem:CreateColorShift(texture, fromR, fromG, fromB, fromA, toR, toG, toB, toA, duration, delay, callback)
    if not texture then return nil end
    
    -- Get the parent frame
    local frame = texture:GetParent()
    if not frame then return nil end
    
    -- Create animation group
    local group = self:CreateAnimationGroup(frame, "ColorShift_" .. tostring(texture))
    
    -- Store the original color
    texture.originalColor = {texture:GetVertexColor()}
    
    -- Add the animation steps
    local totalSteps = 20
    local stepDuration = (duration or 0.5) / totalSteps
    
    for i = 1, totalSteps do
        local progress = i / totalSteps
        local r = fromR + (toR - fromR) * progress
        local g = fromG + (toG - fromG) * progress
        local b = fromB + (toB - fromB) * progress
        local a = fromA + (toA - fromA) * progress
        
        local anim = group:CreateAnimation("Animation")
        anim:SetDuration(stepDuration)
        anim:SetOrder(i)
        
        if i > 1 then
            anim:SetStartDelay(0)
        else
            anim:SetStartDelay(delay or 0)
        end
        
        anim:SetScript("OnUpdate", function(self, elapsed)
            texture:SetVertexColor(r, g, b, a)
        end)
    end
    
    -- Set callback
    if callback then
        group:SetScript("OnFinished", callback)
    else
        group:SetScript("OnFinished", function()
            if texture.originalColor then
                texture:SetVertexColor(unpack(texture.originalColor))
            end
        end)
    end
    
    -- Play the animation
    group:Play()
    
    return group
end

-- Stop all animations for a frame
function AnimationSystem:StopAnimations(frame)
    if not frame then return end
    
    -- Stop all animation groups for this frame
    local animationGroups = {frame:GetAnimationGroups()}
    for _, group in ipairs(animationGroups) do
        group:Stop()
    end
end

-- Chain multiple animations together
function AnimationSystem:ChainAnimations(frame, animations, callback)
    if not frame or not animations or #animations == 0 then return end
    
    local currentIndex = 1
    local function playNextAnimation()
        if currentIndex <= #animations then
            local anim = animations[currentIndex]
            local group
            
            if anim.type == ANIMATION_TYPES.FADE_IN then
                group = self:CreateFadeIn(frame, anim.duration, anim.delay)
            elseif anim.type == ANIMATION_TYPES.FADE_OUT then
                -- Don't hide the frame at the end if there are more animations
                local hideCallback = currentIndex == #animations and function() frame:Hide() end or nil
                group = self:CreateFadeOut(frame, anim.duration, anim.delay, hideCallback)
            elseif anim.type == ANIMATION_TYPES.SCALE_UP then
                group = self:CreateScaleUp(frame, anim.duration, anim.delay)
            elseif anim.type == ANIMATION_TYPES.SCALE_DOWN then
                group = self:CreateScaleDown(frame, anim.duration, anim.delay)
            elseif anim.type == ANIMATION_TYPES.SLIDE_IN_TOP then
                group = self:CreateSlideIn(frame, "TOP", anim.distance, anim.duration, anim.delay)
            elseif anim.type == ANIMATION_TYPES.SLIDE_IN_BOTTOM then
                group = self:CreateSlideIn(frame, "BOTTOM", anim.distance, anim.duration, anim.delay)
            elseif anim.type == ANIMATION_TYPES.SLIDE_IN_LEFT then
                group = self:CreateSlideIn(frame, "LEFT", anim.distance, anim.duration, anim.delay)
            elseif anim.type == ANIMATION_TYPES.SLIDE_IN_RIGHT then
                group = self:CreateSlideIn(frame, "RIGHT", anim.distance, anim.duration, anim.delay)
            end
            
            -- Set up callback for next animation
            if group then
                group:SetScript("OnFinished", function()
                    currentIndex = currentIndex + 1
                    playNextAnimation()
                end)
            else
                -- If animation creation failed, move to next
                currentIndex = currentIndex + 1
                playNextAnimation()
            end
        else
            -- All animations complete
            if callback then
                callback()
            end
        end
    end
    
    -- Start the chain
    playNextAnimation()
end

-- Create UI transition animations
function AnimationSystem:CreateUITransition(fromFrame, toFrame, transitionType, duration, callback)
    if not fromFrame or not toFrame then return end
    
    -- Hide destination frame initially
    toFrame:SetAlpha(0)
    toFrame:Show()
    
    if transitionType == "fade" then
        -- Fade out the current frame
        self:CreateFadeOut(fromFrame, duration or 0.3, 0, function()
            fromFrame:Hide()
            -- Fade in the new frame
            self:CreateFadeIn(toFrame, duration or 0.3, 0, callback)
        end)
    elseif transitionType == "slide" then
        -- Slide out the current frame to the left
        self:CreateSlideOut(fromFrame, "LEFT", 100, duration or 0.3, 0, function()
            fromFrame:Hide()
            -- Slide in the new frame from the right
            self:CreateSlideIn(toFrame, "RIGHT", 100, duration or 0.3, 0, callback)
        end)
    elseif transitionType == "scale" then
        -- Scale down the current frame
        self:CreateScaleDown(fromFrame, duration or 0.3, 0, function()
            fromFrame:Hide()
            -- Scale up the new frame
            self:CreateScaleUp(toFrame, duration or 0.3, 0, callback)
        end)
    end
end

-- Apply a preset animation to a frame
function AnimationSystem:ApplyPreset(frame, preset, callback)
    if not frame or not preset then return nil end
    
    local group
    
    if preset == "fadeIn" then
        group = self:CreateFadeIn(frame, 0.3, 0, callback)
    elseif preset == "fadeOut" then
        group = self:CreateFadeOut(frame, 0.3, 0, callback)
    elseif preset == "popIn" then
        -- Combined scale and fade
        frame:SetAlpha(0)
        frame:SetScale(0.5)
        frame:Show()
        
        group = self:CreateAnimationGroup(frame, "PopIn_" .. tostring(frame))
        self:AddFadeAnimation(group, 0, 1, 0.3, 0, SMOOTHING_TYPES.OUT)
        self:AddScaleAnimation(group, 0.5, 0.5, 1, 1, 0.3, 0, SMOOTHING_TYPES.OUT, "CENTER", 0, 0)
        
        if callback then
            group:SetScript("OnFinished", callback)
        end
        
        group:Play()
    elseif preset == "popOut" then
        -- Combined scale and fade
        group = self:CreateAnimationGroup(frame, "PopOut_" .. tostring(frame))
        self:AddFadeAnimation(group, 1, 0, 0.3, 0, SMOOTHING_TYPES.IN)
        self:AddScaleAnimation(group, 1, 1, 0.5, 0.5, 0.3, 0, SMOOTHING_TYPES.IN, "CENTER", 0, 0)
        
        if not callback then
            callback = function() frame:Hide() end
        end
        
        group:SetScript("OnFinished", callback)
        
        group:Play()
    elseif preset == "pulse" then
        group = self:CreatePulse(frame, 1.1, 0.5, 0, "BOUNCE")
    elseif preset == "flash" then
        group = self:CreateFlash(frame, 0.6, 0, "REPEAT")
    elseif preset == "bounce" then
        group = self:CreateBounce(frame, 5, 0.6, 0, "REPEAT")
    end
    
    return group
end

-- Add a button click animation
function AnimationSystem:AddButtonClickAnimation(button)
    if not button then return end
    
    -- Store original scale
    button.originalScale = button:GetScale()
    
    button:HookScript("OnMouseDown", function(self)
        -- Scale down slightly when clicked
        self:SetScale(self.originalScale * 0.95)
    end)
    
    button:HookScript("OnMouseUp", function(self)
        -- Restore original scale
        self:SetScale(self.originalScale)
    end)
    
    button:HookScript("OnShow", function(self)
        -- Ensure scale is reset when button is shown
        self:SetScale(self.originalScale)
    end)
end

-- Add hover highlight animation to a frame
function AnimationSystem:AddHoverAnimation(frame, r, g, b, a)
    if not frame then return end
    
    -- Create highlight texture if it doesn't exist
    if not frame.highlightTexture then
        frame.highlightTexture = frame:CreateTexture(nil, "HIGHLIGHT")
        frame.highlightTexture:SetAllPoints(frame)
        frame.highlightTexture:SetColorTexture(r or 1, g or 1, b or 1, a or 0.3)
        frame.highlightTexture:SetBlendMode("ADD")
        frame.highlightTexture:Hide()
    end
    
    -- Hook mouse events
    frame:HookScript("OnEnter", function(self)
        -- Create pulse for highlight
        if not self.hoverAnimGroup then
            self.hoverAnimGroup = AnimationSystem:CreateAnimationGroup(self, "HoverAnim_" .. tostring(self), "BOUNCE")
            AnimationSystem:AddFadeAnimation(self.hoverAnimGroup, 0, a or 0.3, 0.3, 0, SMOOTHING_TYPES.IN_OUT)
            self.hoverAnimGroup:SetScript("OnUpdate", function()
                self.highlightTexture:Show()
            end)
        end
        
        self.hoverAnimGroup:Play()
    end)
    
    frame:HookScript("OnLeave", function(self)
        if self.hoverAnimGroup then
            self.hoverAnimGroup:Stop()
            self.highlightTexture:Hide()
        end
    end)
end

-- Initialize the module
AnimationSystem:Initialize()

return AnimationSystem