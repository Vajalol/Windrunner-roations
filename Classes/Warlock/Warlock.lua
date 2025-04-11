------------------------------------------
-- WindrunnerRotations - Warlock Base Module
-- Author: VortexQ8
------------------------------------------

local Warlock = {}
-- We'll set this on the addon at the end of the file

-- This will be set when the file is loaded in our test environment
local API

-- Cache spell IDs
Warlock.spells = {
    -- Common Warlock spells
    HEALTHSTONE = 5512,
    SOULSTONE = 20707,
    CREATE_HEALTHSTONE = 6201,
    CREATE_SOULSTONE = 20707,
    DARK_PACT = 108416,
    UNENDING_RESOLVE = 104773,
    DEMONIC_GATEWAY = 111771,
    DEMONIC_CIRCLE = 48018,
    DEMONIC_CIRCLE_TELEPORT = 48020,
    BURNING_RUSH = 111400,
    SOUL_ROT = 325640, -- Covenant ability (Night Fae)
    SCOURING_TITHE = 312321, -- Covenant ability (Kyrian)
    DECIMATING_BOLT = 325289, -- Covenant ability (Necrolord)
    IMPENDING_CATASTROPHE = 321792, -- Covenant ability (Venthyr)
    
    -- Pet-related
    SUMMON_IMP = 688,
    SUMMON_VOIDWALKER = 697,
    SUMMON_FELHUNTER = 691,
    SUMMON_SUCCUBUS = 712,
    SUMMON_FELGUARD = 30146,
    
    -- General damage
    SHADOWFURY = 30283,
    MORTAL_COIL = 6789,
    FEAR = 5782,
    BANISH = 710,
    CURSE_OF_WEAKNESS = 702,
    CURSE_OF_TONGUES = 1714,
    CURSE_OF_EXHAUSTION = 334275,
    
    -- Common resources
    DRAIN_LIFE = 234153,
    HEALTH_FUNNEL = 755
}

-- Initialize the Warlock base module
function Warlock:Initialize()
    -- Register common Warlock spells
    for _, spellID in pairs(self.spells) do
        API.RegisterSpell(spellID)
    end
    
    API.PrintDebug("Warlock base module initialized")
    return true
end

-- Handle defensive and utility abilities common to all specs
function Warlock:HandleDefensives()
    -- Use Unending Resolve when low health
    if API.GetPlayerHealthPercent() <= 30 and API.CanCast(self.spells.UNENDING_RESOLVE) then
        API.CastSpell(self.spells.UNENDING_RESOLVE)
        return true
    end
    
    -- Use Dark Pact if talented and health is below 60%
    if API.GetPlayerHealthPercent() <= 60 and API.HasTalent(self.spells.DARK_PACT) and API.CanCast(self.spells.DARK_PACT) then
        API.CastSpell(self.spells.DARK_PACT)
        return true
    end
    
    -- Use Drain Life if health is very low
    if API.GetPlayerHealthPercent() <= 25 and API.CanCast(self.spells.DRAIN_LIFE) then
        API.CastSpell(self.spells.DRAIN_LIFE)
        return true
    end
    
    return false
end

-- Return the module
return Warlock