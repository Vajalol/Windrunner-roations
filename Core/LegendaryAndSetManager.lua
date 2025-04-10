local addonName, WR = ...

-- LegendaryAndSetManager module for handling legendary items and set bonuses
local LegendaryAndSetManager = {}
WR.LegendaryAndSetManager = LegendaryAndSetManager

-- Import constants
local CLASS, SPEC
if WR.ClassKnowledge then
    CLASS = WR.ClassKnowledge.CLASS
    SPEC = WR.ClassKnowledge.SPEC
end

-- Local variables
local currentClass, currentSpec
local equippedLegendaries = {}
local activeTierSets = {}
local appliedModifications = {}
local scanInProgress = false

-- Database of legendary effects - This would be populated with a comprehensive database
-- of all legendary items for each class/spec in a real implementation
local legendaryEffects = {}

-- Database of tier set bonuses - This would be populated with a comprehensive database
-- of all tier set bonuses for each class/spec in a real implementation
local tierSetBonuses = {}

-- Constants
local SCAN_INTERVAL = 5 -- How often to scan for gear changes (seconds)
local TIER_SET_THRESHOLDS = {2, 4} -- Typical tier set bonus thresholds (2-piece, 4-piece)

-- Initialize the LegendaryAndSetManager
function LegendaryAndSetManager:Initialize()
    -- Import legendary and tier set effects from ClassKnowledge if available
    if WR.ClassKnowledge then
        if WR.ClassKnowledge.legendaryEffects then
            legendaryEffects = WR.ClassKnowledge.legendaryEffects
        end
        
        if WR.ClassKnowledge.tierSetBonuses then
            tierSetBonuses = WR.ClassKnowledge.tierSetBonuses
        end
    end
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("ITEM_UNLOCKED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            LegendaryAndSetManager:DetectClassAndSpec()
            LegendaryAndSetManager:ScanForGearEffects()
        elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "ITEM_UNLOCKED" then
            -- Use debounced scanning to avoid excessive scans when multiple items change
            if not scanInProgress then
                scanInProgress = true
                C_Timer.After(0.5, function()
                    LegendaryAndSetManager:ScanForGearEffects()
                    scanInProgress = false
                end)
            end
        end
    end)
    
    -- Set up periodic scans
    C_Timer.NewTicker(SCAN_INTERVAL, function()
        if not scanInProgress then
            scanInProgress = true
            LegendaryAndSetManager:ScanForGearEffects()
            scanInProgress = false
        end
    end)
    
    -- Initial detection
    self:DetectClassAndSpec()
    self:ScanForGearEffects()
    
    -- Integration with rotation enhancer
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RegisterLegendaryAndSetManager(self)
    end
    
    WR:Debug("LegendaryAndSetManager module initialized")
end

-- Detect player class and specialization
function LegendaryAndSetManager:DetectClassAndSpec()
    currentClass = select(2, UnitClass("player"))
    currentSpec = GetSpecialization()
    
    WR:Debug("Detected class: " .. currentClass .. ", spec: " .. (currentSpec or "None"))
end

-- Scan for legendary items and tier sets
function LegendaryAndSetManager:ScanForGearEffects()
    -- Clear previous data
    local previousLegendaries = CopyTable(equippedLegendaries)
    local previousTierSets = CopyTable(activeTierSets)
    
    equippedLegendaries = {}
    activeTierSets = {}
    
    -- Scan each equipment slot
    for i = 1, 19 do -- 19 equipment slots
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            -- Scan for legendary items
            self:ScanLegendaryItem(i, itemLink)
            
            -- Scan for tier set pieces
            self:ScanTierSetItem(i, itemLink)
        end
    end
    
    -- Check if anything changed
    local legendaryScanChanged = not self:AreTablesEqual(previousLegendaries, equippedLegendaries)
    local tierSetScanChanged = not self:AreTablesEqual(previousTierSets, activeTierSets)
    
    if legendaryScanChanged or tierSetScanChanged then
        -- Apply effects if changes detected
        self:ApplyGearEffects()
        
        -- Debug output
        if legendaryScanChanged then
            WR:Debug("Legendary scan changed - found " .. #equippedLegendaries .. " legendaries")
        end
        
        if tierSetScanChanged then
            local tierSetInfo = ""
            for setName, pieceCount in pairs(activeTierSets) do
                tierSetInfo = tierSetInfo .. setName .. " (" .. pieceCount .. " pieces), "
            end
            
            WR:Debug("Tier set scan changed - found " .. tierSetInfo)
        end
    end
end

-- Scan for legendary item
function LegendaryAndSetManager:ScanLegendaryItem(slotID, itemLink)
    if not itemLink then return end
    
    -- Get item ID and bonuses
    local itemID = GetItemInfoInstant(itemLink)
    if not itemID then return end
    
    -- In a real implementation, this would check the item quality and legendary powers
    -- For demonstration, we'll use a simple method to detect legendaries
    
    -- Check if this is a legendary item
    local _, _, itemRarity = GetItemInfo(itemLink)
    if itemRarity == 5 then -- 5 = Legendary rarity
        -- Extract legendary ID from bonuses
        local legendaryID = self:ExtractLegendaryIDFromBonuses(itemLink)
        
        -- Add to equipped legendaries
        table.insert(equippedLegendaries, {
            slot = slotID,
            itemID = itemID,
            legendaryID = legendaryID,
            name = C_Item.GetItemNameByID(itemID),
            link = itemLink
        })
        
        WR:Debug("Found legendary in slot " .. slotID .. ": " .. C_Item.GetItemNameByID(itemID))
    end
end

-- Extract legendary ID from item bonuses
function LegendaryAndSetManager:ExtractLegendaryIDFromBonuses(itemLink)
    -- In a real implementation, this would extract the bonus ID that identifies the specific legendary power
    -- For demonstration, we'll return a placeholder
    return 12345 -- Placeholder legendary ID
end

-- Scan for tier set item
function LegendaryAndSetManager:ScanTierSetItem(slotID, itemLink)
    if not itemLink then return end
    
    -- Get item ID
    local itemID = GetItemInfoInstant(itemLink)
    if not itemID then return end
    
    -- In a real implementation, this would check for tier set belonging
    -- For demonstration, we'll use a simple method to detect tier sets
    
    -- Extract set info
    local setInfo = self:ExtractSetInfo(itemLink)
    
    if setInfo and setInfo.name then
        -- Add to active tier sets
        if not activeTierSets[setInfo.name] then
            activeTierSets[setInfo.name] = 0
        end
        
        activeTierSets[setInfo.name] = activeTierSets[setInfo.name] + 1
        
        WR:Debug("Found tier piece in slot " .. slotID .. ": " .. setInfo.name .. 
                " (Total: " .. activeTierSets[setInfo.name] .. ")")
    end
end

-- Extract set info from item
function LegendaryAndSetManager:ExtractSetInfo(itemLink)
    -- In a real implementation, this would extract the set info
    -- For demonstration, we'll check the item name
    
    local itemName = C_Item.GetItemNameByID(itemLink)
    if not itemName then return nil end
    
    -- Check for tier set patterns in name
    if itemName:match("Mythic") or itemName:match("of the") then
        return {
            name = "T29", -- Placeholder tier set name
            id = 1234     -- Placeholder tier set ID
        }
    end
    
    return nil
end

-- Apply gear effects to rotation
function LegendaryAndSetManager:ApplyGearEffects()
    -- Clear previous modifications
    appliedModifications = {}
    
    -- Apply legendary effects
    for _, legendary in ipairs(equippedLegendaries) do
        self:ApplyLegendaryEffect(legendary)
    end
    
    -- Apply tier set bonuses
    for setName, pieceCount in pairs(activeTierSets) do
        self:ApplyTierSetBonuses(setName, pieceCount)
    end
    
    -- Notify rotation enhancer of changes
    if WR.RotationEnhancer then
        WR.RotationEnhancer:UpdateGearEffects({
            legendaries = equippedLegendaries,
            tierSets = activeTierSets,
            modifications = appliedModifications
        })
    end
    
    WR:Debug("Applied gear effects - " .. #appliedModifications .. " modifications")
}

-- Apply legendary effect
function LegendaryAndSetManager:ApplyLegendaryEffect(legendary)
    if not legendary or not legendary.legendaryID then return end
    
    -- Look up the legendary effect
    local effect = legendaryEffects[legendary.legendaryID]
    
    if not effect then
        WR:Debug("No effect found for legendary ID " .. legendary.legendaryID)
        return
    end
    
    -- Check if effect applies to current class/spec
    if effect.class ~= currentClass or (effect.spec and effect.spec ~= currentSpec) then
        WR:Debug("Legendary effect doesn't apply to current class/spec")
        return
    end
    
    -- Apply effect modifications
    if effect.priority_modifications then
        -- For demonstration, we'll add the modifications to the list
        table.insert(appliedModifications, {
            type = "legendary",
            source = legendary.name,
            effect = effect.effect,
            modifications = effect.priority_modifications
        })
        
        -- Apply to rotation if available
        if WR.Rotation then
            if effect.priority_modifications.increase then
                for _, spellName in ipairs(effect.priority_modifications.increase) do
                    WR.Rotation:AdjustSpellPriority(spellName, 1.2) -- Increase by 20%
                end
            end
            
            if effect.priority_modifications.decrease then
                for _, spellName in ipairs(effect.priority_modifications.decrease) do
                    WR.Rotation:AdjustSpellPriority(spellName, 0.8) -- Decrease by 20%
                end
            end
        end
        
        WR:Debug("Applied legendary effect: " .. effect.effect)
    end
    
    -- Apply special effects if any
    if effect.special_effect and type(effect.special_effect) == "function" then
        effect.special_effect()
        WR:Debug("Applied special legendary effect")
    end
}

-- Apply tier set bonuses
function LegendaryAndSetManager:ApplyTierSetBonuses(setName, pieceCount)
    if not setName or not pieceCount then return end
    
    -- Check for set bonus thresholds
    for _, threshold in ipairs(TIER_SET_THRESHOLDS) do
        if pieceCount >= threshold then
            -- Look up the tier set bonus
            local bonusKey = setName
            local bonus = tierSetBonuses[bonusKey] and tierSetBonuses[bonusKey][threshold]
            
            if not bonus then
                WR:Debug("No " .. threshold .. "-piece bonus found for set " .. setName)
                goto continue
            end
            
            -- Check if bonus applies to current class/spec
            if bonus.class ~= currentClass or (bonus.spec and bonus.spec ~= currentSpec) then
                WR:Debug("Tier set bonus doesn't apply to current class/spec")
                goto continue
            end
            
            -- Apply bonus modifications
            if bonus.priority_modifications then
                -- For demonstration, we'll add the modifications to the list
                table.insert(appliedModifications, {
                    type = "tier_set",
                    source = setName .. " " .. threshold .. "-piece",
                    effect = bonus.effect,
                    modifications = bonus.priority_modifications
                })
                
                -- Apply to rotation if available
                if WR.Rotation then
                    if bonus.priority_modifications.increase then
                        for _, spellName in ipairs(bonus.priority_modifications.increase) do
                            WR.Rotation:AdjustSpellPriority(spellName, 1.2) -- Increase by 20%
                        end
                    end
                    
                    if bonus.priority_modifications.decrease then
                        for _, spellName in ipairs(bonus.priority_modifications.decrease) do
                            WR.Rotation:AdjustSpellPriority(spellName, 0.8) -- Decrease by 20%
                        end
                    end
                end
                
                WR:Debug("Applied " .. threshold .. "-piece bonus: " .. bonus.effect)
            end
            
            -- Apply special effects if any
            if bonus.special_effect and type(bonus.special_effect) == "function" then
                bonus.special_effect()
                WR:Debug("Applied special tier set effect")
            end
        end
        
        ::continue::
    end
}

-- Get currently equipped legendaries
function LegendaryAndSetManager:GetEquippedLegendaries()
    return equippedLegendaries
end

-- Get active tier sets
function LegendaryAndSetManager:GetActiveTierSets()
    return activeTierSets
end

-- Get applied modifications
function LegendaryAndSetManager:GetAppliedModifications()
    return appliedModifications
end

-- Check if a specific legendary effect is active
function LegendaryAndSetManager:HasLegendaryEffect(legendaryID)
    for _, legendary in ipairs(equippedLegendaries) do
        if legendary.legendaryID == legendaryID then
            return true
        end
    end
    
    return false
end

-- Check if a specific tier set bonus is active
function LegendaryAndSetManager:HasTierSetBonus(setName, pieceCount)
    return activeTierSets[setName] and activeTierSets[setName] >= pieceCount
end

-- Get specific legendary effect
function LegendaryAndSetManager:GetLegendaryEffect(legendaryID)
    return legendaryEffects[legendaryID]
end

-- Get specific tier set bonus
function LegendaryAndSetManager:GetTierSetBonus(setName, pieceCount)
    return tierSetBonuses[setName] and tierSetBonuses[setName][pieceCount]
end

-- Force a gear scan
function LegendaryAndSetManager:ForceScan()
    self:ScanForGearEffects()
end

-- Helper function to compare tables
function LegendaryAndSetManager:AreTablesEqual(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end
    
    local t1Count, t2Count = 0, 0
    for k, v in pairs(t1) do
        t1Count = t1Count + 1
        if type(v) == "table" then
            if not self:AreTablesEqual(v, t2[k]) then
                return false
            end
        elseif v ~= t2[k] then
            return false
        end
    end
    
    for _ in pairs(t2) do
        t2Count = t2Count + 1
    end
    
    return t1Count == t2Count
end

-- Create a simple UI to view active legendary and tier set effects
function LegendaryAndSetManager:CreateEffectsUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsGearEffectsUI", parent, "BackdropTemplate")
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Gear Effects")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Legendaries", "Tier Sets", "Modifications"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -40)
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetText(tabName)
        
        -- Create highlight texture
        local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create selected texture
        local selectedTexture = tab:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        tab.selectedTexture = selectedTexture
        
        -- Create tab content frame
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 80)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
        content:Hide()
        
        -- Set up tab behavior
        tab:SetScript("OnClick", function()
            -- Hide all contents
            for _, contentFrame in ipairs(tabContents) do
                contentFrame:Hide()
            end
            
            -- Show this content
            content:Show()
            
            -- Update tab appearance
            for _, tabButton in ipairs(tabs) do
                tabButton.selectedTexture:Hide()
            end
            
            tab.selectedTexture:Show()
            
            -- Update content
            if tabName == "Legendaries" then
                LegendaryAndSetManager:UpdateLegendariesTab(content)
            elseif tabName == "Tier Sets" then
                LegendaryAndSetManager:UpdateTierSetsTab(content)
            elseif tabName == "Modifications" then
                LegendaryAndSetManager:UpdateModificationsTab(content)
            end
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Function to update legendaries tab
    function LegendaryAndSetManager:UpdateLegendariesTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add rescan button
        local rescanButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        rescanButton:SetSize(100, 24)
        rescanButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        rescanButton:SetText("Rescan")
        rescanButton:SetScript("OnClick", function()
            LegendaryAndSetManager:ForceScan()
            LegendaryAndSetManager:UpdateLegendariesTab(content)
        end)
        
        -- Header
        local headerText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        headerText:SetText("Equipped Legendaries")
        
        local y = -30
        
        if #equippedLegendaries == 0 then
            local noItemsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noItemsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            noItemsText:SetText("No legendary items detected")
            
            scrollChild:SetHeight(50)
            return
        end
        
        -- List legendaries
        for i, legendary in ipairs(equippedLegendaries) do
            local itemFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            itemFrame:SetSize(scrollChild:GetWidth() - 20, 80)
            itemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            itemFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            itemFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Item name
            local nameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 15, -15)
            nameText:SetText(legendary.name)
            
            -- Item slot
            local slotText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            slotText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            slotText:SetText("Slot: " .. self:GetSlotName(legendary.slot))
            
            -- Item effect
            local effect = self:GetLegendaryEffect(legendary.legendaryID)
            if effect then
                local effectText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                effectText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -5)
                effectText:SetText("Effect: " .. effect.effect)
                
                -- Priority modifications
                if effect.priority_modifications then
                    local modsY = -60
                    
                    if effect.priority_modifications.increase and #effect.priority_modifications.increase > 0 then
                        local increaseText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        increaseText:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 20, modsY)
                        increaseText:SetText("Increased Priority: " .. table.concat(effect.priority_modifications.increase, ", "))
                        increaseText:SetTextColor(0, 1, 0)
                        
                        modsY = modsY - 15
                    end
                    
                    if effect.priority_modifications.decrease and #effect.priority_modifications.decrease > 0 then
                        local decreaseText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        decreaseText:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 20, modsY)
                        decreaseText:SetText("Decreased Priority: " .. table.concat(effect.priority_modifications.decrease, ", "))
                        decreaseText:SetTextColor(1, 0.5, 0)
                        
                        modsY = modsY - 15
                    end
                    
                    -- Adjust frame height if needed
                    if modsY < -70 then
                        itemFrame:SetHeight(math.abs(modsY) + 20)
                    end
                end
            else
                local noEffectText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                noEffectText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -5)
                noEffectText:SetText("Effect: Unknown")
            end
            
            y = y - itemFrame:GetHeight() - 10
        }
        
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Function to update tier sets tab
    function LegendaryAndSetManager:UpdateTierSetsTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add rescan button
        local rescanButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        rescanButton:SetSize(100, 24)
        rescanButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        rescanButton:SetText("Rescan")
        rescanButton:SetScript("OnClick", function()
            LegendaryAndSetManager:ForceScan()
            LegendaryAndSetManager:UpdateTierSetsTab(content)
        end)
        
        -- Header
        local headerText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        headerText:SetText("Active Tier Sets")
        
        local y = -30
        
        local setCount = 0
        for _ in pairs(activeTierSets) do
            setCount = setCount + 1
        end
        
        if setCount == 0 then
            local noSetsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noSetsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            noSetsText:SetText("No tier sets detected")
            
            scrollChild:SetHeight(50)
            return
        end
        
        -- List tier sets
        for setName, pieceCount in pairs(activeTierSets) do
            local setFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            setFrame:SetSize(scrollChild:GetWidth() - 20, 120)
            setFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            setFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            setFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Set name
            local nameText = setFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("TOPLEFT", setFrame, "TOPLEFT", 15, -15)
            nameText:SetText(setName)
            
            -- Piece count
            local countText = setFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            countText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            countText:SetText("Pieces: " .. pieceCount)
            
            local bonusY = -50
            
            -- List active tier bonuses
            for _, threshold in ipairs(TIER_SET_THRESHOLDS) do
                if pieceCount >= threshold then
                    -- Look up the tier set bonus
                    local bonusKey = setName
                    local bonus = tierSetBonuses[bonusKey] and tierSetBonuses[bonusKey][threshold]
                    
                    if bonus then
                        local bonusText = setFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        bonusText:SetPoint("TOPLEFT", setFrame, "TOPLEFT", 15, bonusY)
                        bonusText:SetText(threshold .. "-piece bonus: " .. bonus.effect)
                        
                        bonusY = bonusY - 20
                        
                        -- Priority modifications
                        if bonus.priority_modifications then
                            if bonus.priority_modifications.increase and #bonus.priority_modifications.increase > 0 then
                                local increaseText = setFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                                increaseText:SetPoint("TOPLEFT", setFrame, "TOPLEFT", 20, bonusY)
                                increaseText:SetText("Increased Priority: " .. 
                                                    table.concat(bonus.priority_modifications.increase, ", "))
                                increaseText:SetTextColor(0, 1, 0)
                                
                                bonusY = bonusY - 15
                            end
                            
                            if bonus.priority_modifications.decrease and #bonus.priority_modifications.decrease > 0 then
                                local decreaseText = setFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                                decreaseText:SetPoint("TOPLEFT", setFrame, "TOPLEFT", 20, bonusY)
                                decreaseText:SetText("Decreased Priority: " .. 
                                                    table.concat(bonus.priority_modifications.decrease, ", "))
                                decreaseText:SetTextColor(1, 0.5, 0)
                                
                                bonusY = bonusY - 15
                            end
                        end
                    else
                        local noBonusText = setFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        noBonusText:SetPoint("TOPLEFT", setFrame, "TOPLEFT", 15, bonusY)
                        noBonusText:SetText(threshold .. "-piece bonus: Unknown effect")
                        
                        bonusY = bonusY - 20
                    end
                end
            }
            
            -- Adjust frame height
            setFrame:SetHeight(math.abs(bonusY) + 20)
            
            y = y - setFrame:GetHeight() - 10
        }
        
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Function to update modifications tab
    function LegendaryAndSetManager:UpdateModificationsTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add rescan button
        local rescanButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        rescanButton:SetSize(100, 24)
        rescanButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        rescanButton:SetText("Rescan")
        rescanButton:SetScript("OnClick", function()
            LegendaryAndSetManager:ForceScan()
            LegendaryAndSetManager:UpdateModificationsTab(content)
        end)
        
        -- Header
        local headerText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        headerText:SetText("Applied Rotation Modifications")
        
        local y = -30
        
        if #appliedModifications == 0 then
            local noModsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noModsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            noModsText:SetText("No rotation modifications applied")
            
            scrollChild:SetHeight(50)
            return
        end
        
        -- List modifications
        for i, mod in ipairs(appliedModifications) do
            local modFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            modFrame:SetSize(scrollChild:GetWidth() - 20, 100)
            modFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            modFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            modFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Mod source
            local sourceText = modFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sourceText:SetPoint("TOPLEFT", modFrame, "TOPLEFT", 15, -15)
            sourceText:SetText(mod.source .. " (" .. mod.type .. ")")
            
            -- Mod effect
            local effectText = modFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            effectText:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -5)
            effectText:SetText("Effect: " .. mod.effect)
            
            -- Modifications
            local modsY = -50
            
            if mod.modifications then
                if mod.modifications.increase and #mod.modifications.increase > 0 then
                    local increaseText = modFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    increaseText:SetPoint("TOPLEFT", modFrame, "TOPLEFT", 20, modsY)
                    increaseText:SetText("Increased Priority: " .. table.concat(mod.modifications.increase, ", "))
                    increaseText:SetTextColor(0, 1, 0)
                    
                    modsY = modsY - 15
                end
                
                if mod.modifications.decrease and #mod.modifications.decrease > 0 then
                    local decreaseText = modFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    decreaseText:SetPoint("TOPLEFT", modFrame, "TOPLEFT", 20, modsY)
                    decreaseText:SetText("Decreased Priority: " .. table.concat(mod.modifications.decrease, ", "))
                    decreaseText:SetTextColor(1, 0.5, 0)
                    
                    modsY = modsY - 15
                end
            end
            
            -- Adjust frame height
            modFrame:SetHeight(math.abs(modsY) + 20)
            
            y = y - modFrame:GetHeight() - 10
        }
        
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Update first tab content
    LegendaryAndSetManager:UpdateLegendariesTab(tabContents[1])
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Helper function to get slot name
function LegendaryAndSetManager:GetSlotName(slotID)
    local slotNames = {
        [1] = "Head",
        [2] = "Neck",
        [3] = "Shoulder",
        [4] = "Shirt",
        [5] = "Chest",
        [6] = "Waist",
        [7] = "Legs",
        [8] = "Feet",
        [9] = "Wrist",
        [10] = "Hands",
        [11] = "Finger 1",
        [12] = "Finger 2",
        [13] = "Trinket 1",
        [14] = "Trinket 2",
        [15] = "Back",
        [16] = "Main Hand",
        [17] = "Off Hand",
        [18] = "Ranged",
        [19] = "Tabard"
    }
    
    return slotNames[slotID] or "Unknown Slot"
end

-- Initialize the module
LegendaryAndSetManager:Initialize()

return LegendaryAndSetManager