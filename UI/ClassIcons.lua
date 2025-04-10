local addonName, WR = ...

-- Class Icons module - provides class and spec icons
WR.UI.ClassIcons = {}

-- Class icon paths
local CLASS_ICONS = {
    WARRIOR = "Interface\\Icons\\ClassIcon_Warrior",
    PALADIN = "Interface\\Icons\\ClassIcon_Paladin",
    HUNTER = "Interface\\Icons\\ClassIcon_Hunter",
    ROGUE = "Interface\\Icons\\ClassIcon_Rogue",
    PRIEST = "Interface\\Icons\\ClassIcon_Priest",
    DEATHKNIGHT = "Interface\\Icons\\ClassIcon_DeathKnight",
    SHAMAN = "Interface\\Icons\\ClassIcon_Shaman",
    MAGE = "Interface\\Icons\\ClassIcon_Mage",
    WARLOCK = "Interface\\Icons\\ClassIcon_Warlock",
    MONK = "Interface\\Icons\\ClassIcon_Monk",
    DRUID = "Interface\\Icons\\ClassIcon_Druid",
    DEMONHUNTER = "Interface\\Icons\\ClassIcon_DemonHunter",
    EVOKER = "Interface\\Icons\\ClassIcon_Evoker",
}

-- Spell icons for classes that need representation
local SPELL_ICONS = {
    -- Mage
    ARCANE = "Interface\\Icons\\Spell_Holy_MagicalSentry",
    FIRE = "Interface\\Icons\\Spell_Fire_FireBolt02",
    FROST_MAGE = "Interface\\Icons\\Spell_Frost_FrostBolt02",
    
    -- Hunter
    BEAST_MASTERY = "Interface\\Icons\\Ability_Hunter_BestialDiscipline",
    MARKSMANSHIP = "Interface\\Icons\\Ability_Hunter_FocusedAim",
    SURVIVAL = "Interface\\Icons\\Ability_Hunter_Camouflage",
    
    -- Warrior
    ARMS = "Interface\\Icons\\Ability_Warrior_SavageBlow",
    FURY = "Interface\\Icons\\Ability_Warrior_InnerRage",
    PROTECTION_WARRIOR = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    
    -- Demon Hunter
    HAVOC = "Interface\\Icons\\Ability_DemonHunter_Eyebeam",
    VENGEANCE = "Interface\\Icons\\Ability_DemonHunter_SpecDPS",

    -- Common abilities
    INTERRUPT = "Interface\\Icons\\Ability_Kick",
    DEFENSIVE = "Interface\\Icons\\Spell_Holy_ArdentDefender",
    COOLDOWN = "Interface\\Icons\\Spell_Nature_TimeStop",
    AOE = "Interface\\Icons\\Spell_Nature_Earthquake",
    UTILITY = "Interface\\Icons\\INV_Misc_EngGizmos_30",
}

-- Ability category icons
local CATEGORY_ICONS = {
    DAMAGE = "Interface\\Icons\\Ability_DualWield",
    INTERRUPT = "Interface\\Icons\\Ability_Kick",
    DEFENSIVE = "Interface\\Icons\\Spell_Holy_ArdentDefender",
    COOLDOWN = "Interface\\Icons\\Spell_Nature_TimeStop",
    AOE = "Interface\\Icons\\Spell_Nature_Earthquake",
    UTILITY = "Interface\\Icons\\INV_Misc_EngGizmos_30",
    MOVEMENT = "Interface\\Icons\\Ability_Rogue_Sprint",
    HEALING = "Interface\\Icons\\Spell_Holy_FlashHeal",
    CC = "Interface\\Icons\\Spell_Nature_Polymorph",
    BUFF = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings",
    DEBUFF = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
}

-- Get a class icon by class name
function WR.UI.ClassIcons.GetIconForClass(className)
    return CLASS_ICONS[className] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Get a spell icon by key
function WR.UI.ClassIcons.GetSpellIcon(key)
    return SPELL_ICONS[key] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Get a category icon by name
function WR.UI.ClassIcons.GetCategoryIcon(category)
    return CATEGORY_ICONS[category] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Get class color by class name
function WR.UI.ClassIcons.GetClassColorRGB(className)
    local colors = {
        WARRIOR = {0.78, 0.61, 0.43},
        PALADIN = {0.96, 0.55, 0.73},
        HUNTER = {0.67, 0.83, 0.45},
        ROGUE = {1.00, 0.96, 0.41},
        PRIEST = {1.00, 1.00, 1.00},
        DEATHKNIGHT = {0.77, 0.12, 0.23},
        SHAMAN = {0.00, 0.44, 0.87},
        MAGE = {0.41, 0.80, 0.94},
        WARLOCK = {0.58, 0.51, 0.79},
        MONK = {0.00, 1.00, 0.59},
        DRUID = {1.00, 0.49, 0.04},
        DEMONHUNTER = {0.64, 0.19, 0.79},
        EVOKER = {0.20, 0.58, 0.50},
    }
    
    return colors[className] or {1, 1, 1}
end

-- Get class color hex code by class name
function WR.UI.ClassIcons.GetClassColorHex(className)
    local colors = {
        WARRIOR = "C79C6E",
        PALADIN = "F58CBA",
        HUNTER = "ABD473",
        ROGUE = "FFF569",
        PRIEST = "FFFFFF",
        DEATHKNIGHT = "C41F3B",
        SHAMAN = "0070DE",
        MAGE = "69CCF0",
        WARLOCK = "9482C9",
        MONK = "00FF96",
        DRUID = "FF7D0A",
        DEMONHUNTER = "A330C9",
        EVOKER = "33937F",
    }
    
    return colors[className] or "FFFFFF"
end

-- Create a color gradient for abilities (common utility function)
function WR.UI.ClassIcons.CreateGradient(r1, g1, b1, r2, g2, b2, steps)
    steps = steps or 10
    local gradient = {}
    
    for i = 1, steps do
        local ratio = (i - 1) / (steps - 1)
        local r = r1 + (r2 - r1) * ratio
        local g = g1 + (g2 - g1) * ratio
        local b = b1 + (b2 - b1) * ratio
        
        gradient[i] = {r = r, g = g, b = b}
    end
    
    return gradient
end

-- Get spell icon for a specific spell ID (tries to use the actual icon if available)
function WR.UI.ClassIcons.GetIconForSpellID(spellID)
    if not spellID then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    
    -- Try to get the icon from the spell info
    local spellName, _, spellIcon = GetSpellInfo(spellID)
    if spellIcon then
        return spellIcon
    end
    
    -- Fallback to question mark
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Get item icon for a specific item ID
function WR.UI.ClassIcons.GetIconForItemID(itemID)
    if not itemID then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    
    -- Try to get the icon from the item info
    local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
    if itemIcon then
        return itemIcon
    end
    
    -- Fallback to question mark
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end
