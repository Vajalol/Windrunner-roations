-- ItemManager.lua
-- Handles trinket usage and consumables
local addonName, WR = ...
local ItemManager = {}
WR.ItemManager = ItemManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local trinketSlots = {13, 14}  -- Trinket slot IDs
local enableTrinketUsage = true
local enableAutomaticConsumables = true
local healthstoneThreshold = 30  -- % health to use healthstone
local healthPotionThreshold = 40  -- % health to use health potion
local manaPotionThreshold = 30  -- % mana to use mana potion
local combatPotionCooldown = {}  -- Tracks when we last used a combat potion
local consumableCooldowns = {}  -- Tracks when we last used various consumables
local COMBAT_POTION_MIN_INTERVAL = 120  -- Min seconds between combat potions
local HEALTH_POTION_MIN_INTERVAL = 30  -- Min seconds between health potions
local HEALTHSTONE_MIN_INTERVAL = 60  -- Min seconds between healthstones
local MANA_POTION_MIN_INTERVAL = 30  -- Min seconds between mana potions

-- Trinket evaluation variables
local trinketCooldowns = {}  -- Tracks when trinkets were last used
local trinketChargeCounts = {}  -- Tracks charges on trinkets
local lastTrinketUsed = 0  -- Timestamp when last trinket was used
local MIN_TRINKET_INTERVAL = 1.0  -- Min seconds between trinket uses

-- Consumable IDs
local combatPotionIds = {
    -- Current Expansion DPS potions (for TWW)
    191407, -- Elemental Potion of Ultimate Power (Primary stat)
    191383, -- Elemental Potion of Power (Secondaries)
    191389, -- Elemental Potion of Strength
    191393, -- Elemental Potion of Agility
    191395, -- Elemental Potion of Intellect
    191400, -- Potion of Shocking Disclosure
    -- Legacy DPS potions (older expansions)
    171270, -- Potion of Spectral Strength
    171275, -- Potion of Spectral Agility 
    171273, -- Potion of Spectral Intellect
    171274, -- Potion of Spectral Stamina
    -- More could be added based on player needs
}

local healthPotionIds = {
    -- Current Expansion health potions
    191378, -- Elemental Potion of Health
    191380, -- Healing Potion
    -- Legacy health potions
    171267, -- Spiritual Healing Potion
    169451, -- Abyssal Healing Potion
    152494, -- Coastal Healing Potion
    127834, -- Ancient Healing Potion
}

local manaPotionIds = {
    -- Current Expansion mana potions
    191385, -- Aerated Mana Potion 
    191386, -- Potion of the Hushed Zephyr
    -- Legacy mana potions
    171268, -- Spiritual Mana Potion
    152495, -- Coastal Mana Potion
    127835, -- Ancient Mana Potion
}

local healthstoneId = 5512 -- Healthstone ID

-- Initialize module
function ItemManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for item-related events
    API.RegisterEvent("UNIT_INVENTORY_CHANGED", function(unit)
        if unit == "player" then
            self:UpdateTrinketInfo()
        end
    end)
    
    API.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function(slot)
        if slot == 13 or slot == 14 then -- Trinket slots
            self:UpdateTrinketInfo()
        end
    end)
    
    -- Register for combat potion tracking
    API.RegisterEvent("UNIT_AURA", function(unit)
        if unit == "player" then
            self:CheckCombatPotionBuffs()
        end
    end)
    
    -- Initial trinket info update
    self:UpdateTrinketInfo()
    
    API.PrintDebug("Item Manager initialized")
    return true
end

-- Register settings
function ItemManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("ItemManager", {
        trinketSettings = {
            enableTrinketUsage = {
                displayName = "Use Trinkets",
                description = "Automatically use trinkets in combat",
                type = "toggle",
                default = true
            },
            useTrinket1 = {
                displayName = "Use Top Trinket",
                description = "Use the trinket in your top trinket slot",
                type = "toggle",
                default = true
            },
            useTrinket2 = {
                displayName = "Use Bottom Trinket",
                description = "Use the trinket in your bottom trinket slot",
                type = "toggle",
                default = true
            },
            useTrinketsWithCooldowns = {
                displayName = "Use With Cooldowns",
                description = "Use trinkets with major cooldowns",
                type = "toggle",
                default = true
            },
            saveTrinketForBurst = {
                displayName = "Save for Burst Windows",
                description = "Save DPS trinkets for burst windows",
                type = "toggle",
                default = true
            }
        },
        consumableSettings = {
            enableAutomaticConsumables = {
                displayName = "Auto Consumables",
                description = "Automatically use consumable items",
                type = "toggle",
                default = true
            },
            useCombatPotions = {
                displayName = "Combat Potions",
                description = "Use DPS/healing potions in combat",
                type = "toggle",
                default = true
            },
            useHealthPotions = {
                displayName = "Health Potions",
                description = "Use healing potions when low on health",
                type = "toggle",
                default = true
            },
            useManaPotions = {
                displayName = "Mana Potions",
                description = "Use mana potions when low on mana",
                type = "toggle",
                default = true
            },
            useHealthstone = {
                displayName = "Healthstones",
                description = "Use healthstones when low on health",
                type = "toggle",
                default = true
            },
            healthstoneThreshold = {
                displayName = "Healthstone Threshold",
                description = "Health % to use healthstone",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 30
            },
            healthPotionThreshold = {
                displayName = "Health Potion Threshold",
                description = "Health % to use health potion",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 40
            },
            manaPotionThreshold = {
                displayName = "Mana Potion Threshold",
                description = "Mana % to use mana potion",
                type = "slider",
                min = 10,
                max = 50,
                step = 5,
                default = 30
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("ItemManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function ItemManager:ApplySettings(settings)
    -- Apply trinket settings
    enableTrinketUsage = settings.trinketSettings.enableTrinketUsage
    
    -- Apply consumable settings
    enableAutomaticConsumables = settings.consumableSettings.enableAutomaticConsumables
    healthstoneThreshold = settings.consumableSettings.healthstoneThreshold
    healthPotionThreshold = settings.consumableSettings.healthPotionThreshold
    manaPotionThreshold = settings.consumableSettings.manaPotionThreshold
    
    API.PrintDebug("Item Manager settings applied")
end

-- Update settings from external source
function ItemManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enableTrinketUsage ~= nil then
        enableTrinketUsage = newSettings.enableTrinketUsage
    end
    
    if newSettings.enableAutomaticConsumables ~= nil then
        enableAutomaticConsumables = newSettings.enableAutomaticConsumables
    end
end

-- Update trinket information
function ItemManager:UpdateTrinketInfo()
    -- Clear existing data
    trinketCooldowns = {}
    trinketChargeCounts = {}
    
    -- Get trinket information
    for _, slotId in ipairs(trinketSlots) do
        local itemId = GetInventoryItemID("player", slotId)
        if itemId then
            local start, duration, enable = GetItemCooldown(itemId)
            if start and duration then
                trinketCooldowns[itemId] = {
                    start = start,
                    duration = duration,
                    remaining = start + duration - GetTime()
                }
            end
            
            -- Check for charges
            local charges, maxCharges, chargeStart, chargeDuration = GetItemCharges(itemId)
            if charges and maxCharges then
                trinketChargeCounts[itemId] = {
                    charges = charges,
                    maxCharges = maxCharges,
                    chargeStart = chargeStart,
                    chargeDuration = chargeDuration
                }
            end
        end
    end
end

-- Check if a trinket is usable
function ItemManager:IsTrinketUsable(itemId)
    if not itemId then return false end
    
    -- Check if the item exists and is ready
    local start, duration, enable = GetItemCooldown(itemId)
    if not enable or enable == 0 then return false end
    
    -- Check if the item is on cooldown
    if start and duration and start > 0 then
        local remaining = start + duration - GetTime()
        if remaining > 0 then return false end
    end
    
    -- Check if the item has charges
    local charges = GetItemCharges(itemId)
    if charges and charges <= 0 then return false end
    
    return true
end

-- Get trinket information for a specific slot
function ItemManager:GetTrinketInfo(slotId)
    if not slotId or (slotId ~= 13 and slotId ~= 14) then
        return nil
    end
    
    local itemId = GetInventoryItemID("player", slotId)
    if not itemId then
        return nil
    end
    
    local start, duration = GetItemCooldown(itemId)
    local charges = GetItemCharges(itemId)
    local itemName = GetItemInfo(itemId)
    
    return {
        id = itemId,
        name = itemName or "Unknown",
        slot = slotId,
        onCooldown = start and start > 0,
        cooldownRemaining = start and duration and (start + duration - GetTime()) or 0,
        charges = charges or 0
    }
end

-- Get all usable trinkets
function ItemManager:GetUsableTrinkets()
    local usableTrinkets = {}
    
    for _, slotId in ipairs(trinketSlots) do
        local itemId = GetInventoryItemID("player", slotId)
        if itemId and self:IsTrinketUsable(itemId) then
            local trinketInfo = self:GetTrinketInfo(slotId)
            if trinketInfo then
                table.insert(usableTrinkets, trinketInfo)
            end
        end
    end
    
    return usableTrinkets
end

-- Process trinkets based on combat state
function ItemManager.ProcessTrinkets(combatState)
    -- Skip if disabled
    if not enableTrinketUsage then
        return nil
    end
    
    -- Skip if not in combat
    if not combatState.inCombat then
        return nil
    end
    
    -- Skip if we recently used a trinket
    if GetTime() - lastTrinketUsed < MIN_TRINKET_INTERVAL then
        return nil
    end
    
    -- Get usable trinkets
    local usableTrinkets = ItemManager:GetUsableTrinkets()
    if #usableTrinkets == 0 then
        return nil
    end
    
    -- Choose a trinket to use based on situation
    local selectedTrinket = nil
    
    -- If we're in a burst window, prefer on-use DPS trinkets
    if combatState.burstWindow then
        for _, trinket in ipairs(usableTrinkets) do
            -- TODO: Add more sophisticated logic for determining DPS trinkets
            -- For now, just use any available trinket during burst
            selectedTrinket = trinket
            break
        end
    else
        -- If we're not in a burst window, use defensive trinkets if low health
        if combatState.health < 50 then
            -- Look for defensive trinkets first
            -- TODO: Add logic to identify defensive trinkets
        end
        
        -- If no defensive trinket selected and we're in execute range, use a DPS trinket
        if not selectedTrinket and combatState.executePhase then
            selectedTrinket = usableTrinkets[1] -- Just use the first available for now
        end
        
        -- If still no trinket selected and multiple enemies, use an AOE trinket
        if not selectedTrinket and combatState.enemyCount >= 3 then
            -- TODO: Add logic to identify AOE trinkets
            selectedTrinket = usableTrinkets[1] -- Just use the first available for now
        end
        
        -- If still no trinket selected and nothing else applies, just use the first one
        if not selectedTrinket then
            selectedTrinket = usableTrinkets[1]
        end
    end
    
    -- If we selected a trinket, use it
    if selectedTrinket then
        lastTrinketUsed = GetTime()
        
        return {
            id = selectedTrinket.id,
            target = "target" -- Most DPS trinkets target the enemy, could be smarter
        }
    end
    
    return nil
end

-- Check for existing combat potion buffs
function ItemManager:CheckCombatPotionBuffs()
    -- Implementation depends on the specific buffs from combat potions
    -- This would scan for known potion buff IDs and update the cooldown tracker
end

-- Process consumables based on combat state
function ItemManager.ProcessConsumables(combatState)
    -- Skip if disabled
    if not enableAutomaticConsumables then
        return nil
    end
    
    -- Handle health-based consumables first for emergency heals
    local currentTime = GetTime()
    
    -- Check for healthstone use
    if combatState.health <= healthstoneThreshold then
        -- Check if we have a healthstone and it's off cooldown
        if ItemManager:HasItem(healthstoneId) and 
           (not consumableCooldowns.healthstone or 
            currentTime - consumableCooldowns.healthstone > HEALTHSTONE_MIN_INTERVAL) then
            
            consumableCooldowns.healthstone = currentTime
            return {
                id = healthstoneId,
                target = "player"
            }
        end
    end
    
    -- Check for health potion use
    if combatState.health <= healthPotionThreshold then
        -- Check if we have a health potion and it's off cooldown
        local healthPotion = ItemManager:FindFirstUsableItem(healthPotionIds)
        if healthPotion and 
           (not consumableCooldowns.healthPotion or 
            currentTime - consumableCooldowns.healthPotion > HEALTH_POTION_MIN_INTERVAL) then
            
            consumableCooldowns.healthPotion = currentTime
            return {
                id = healthPotion,
                target = "player"
            }
        end
    end
    
    -- Check for mana potion use
    local playerClass = select(2, UnitClass("player"))
    local useMana = playerClass == "PRIEST" or 
                    playerClass == "MAGE" or 
                    playerClass == "WARLOCK" or 
                    playerClass == "DRUID" or 
                    playerClass == "SHAMAN" or 
                    playerClass == "MONK" or 
                    playerClass == "PALADIN" or
                    playerClass == "EVOKER"
    
    if useMana and combatState.resource <= manaPotionThreshold then
        -- Check if we have a mana potion and it's off cooldown
        local manaPotion = ItemManager:FindFirstUsableItem(manaPotionIds)
        if manaPotion and 
           (not consumableCooldowns.manaPotion or 
            currentTime - consumableCooldowns.manaPotion > MANA_POTION_MIN_INTERVAL) then
            
            consumableCooldowns.manaPotion = currentTime
            return {
                id = manaPotion,
                target = "player"
            }
        end
    end
    
    -- Check for combat potion use during burst window
    if combatState.burstWindow and combatState.inCombat then
        local combatPotion = ItemManager:FindFirstUsableItem(combatPotionIds)
        if combatPotion and 
           (not combatPotionCooldown.lastUsed or 
            currentTime - combatPotionCooldown.lastUsed > COMBAT_POTION_MIN_INTERVAL) then
            
            combatPotionCooldown.lastUsed = currentTime
            return {
                id = combatPotion,
                target = "player"
            }
        end
    end
    
    return nil
end

-- Check if player has a specific item
function ItemManager:HasItem(itemId)
    return GetItemCount(itemId, false, true) > 0
end

-- Find the first usable item from a list of item IDs
function ItemManager:FindFirstUsableItem(itemIds)
    for _, itemId in ipairs(itemIds) do
        if self:HasItem(itemId) and self:IsTrinketUsable(itemId) then
            return itemId
        end
    end
    return nil
end

-- Return module
return ItemManager