------------------------------------------
-- WindrunnerRotations - Mage Base Module
-- Author: VortexQ8
------------------------------------------

local Mage = {}
-- We'll set this on the addon at the end of the file

-- This will be set when the file is loaded in our test environment
local API

-- Cache spell IDs
Mage.spells = {
    -- Common Mage spells
    ARCANE_INTELLECT = 1459,
    BLINK = 1953,
    SHIMMER = 212653,
    COUNTERSPELL = 2139,
    MIRROR_IMAGE = 55342,
    ARCANE_EXPLOSION = 1449,
    TIME_WARP = 80353,
    FROST_NOVA = 122,
    ICE_BARRIER = 11426,
    ICE_BLOCK = 45438,
    RUNE_OF_POWER = 116011,
    SPELLSTEAL = 30449,
    SLOW_FALL = 130,
    CONJURE_REFRESHMENT = 190336,
    REMOVE_CURSE = 475,
    
    -- Covenant abilities
    DEATHBORNE = 324220, -- Necrolord
    MIRRORS_OF_TORMENT = 314793, -- Venthyr
    SHIFTING_POWER = 314791, -- Night Fae
    RADIANT_SPARK = 307443, -- Kyrian
    
    -- Defensive
    ALTER_TIME = 108978,
    GREATER_INVISIBILITY = 110959
}

-- Initialize the Mage base module
function Mage:Initialize()
    -- Register common Mage spells
    for _, spellID in pairs(self.spells) do
        API.RegisterSpell(spellID)
    end
    
    API.PrintDebug("Mage base module initialized")
    return true
end

-- Handle defensive and utility abilities common to all specs
function Mage:HandleDefensives()
    -- Use Ice Block when critically low health
    if API.GetPlayerHealthPercent() <= 20 and API.CanCast(self.spells.ICE_BLOCK) then
        API.CastSpell(self.spells.ICE_BLOCK)
        return true
    end
    
    -- Use Ice Barrier if available
    if API.GetPlayerHealthPercent() <= 90 and API.CanCast(self.spells.ICE_BARRIER) then
        API.CastSpell(self.spells.ICE_BARRIER)
        return true
    end
    
    -- Use Greater Invisibility if in danger
    if API.GetPlayerHealthPercent() <= 30 and API.CanCast(self.spells.GREATER_INVISIBILITY) then
        API.CastSpell(self.spells.GREATER_INVISIBILITY)
        return true
    end
    
    return false
end

-- Handle movement abilities
function Mage:HandleMovement()
    -- Use Shimmer/Blink when needed
    if API.IsPlayerMoving() then
        if API.HasSpell(self.spells.SHIMMER) and API.CanCast(self.spells.SHIMMER) then
            API.CastSpell(self.spells.SHIMMER)
            return true
        elseif API.CanCast(self.spells.BLINK) then
            API.CastSpell(self.spells.BLINK)
            return true
        end
    end
    
    return false
end

-- Return the module
return Mage