local addonName, WR = ...

-- Mage Class Module
local Mage = {}
WR.Classes.MAGE = Mage

-- Specialization IDs
local ARCANE_SPEC = 62
local FIRE_SPEC = 63
local FROST_SPEC = 64

-- Mage spells
local SPELLS = {
    -- Shared
    ARCANE_INTELLECT = 1459,
    BLINK = 1953,
    COUNTERSPELL = 2139,
    FROST_NOVA = 122,
    ICE_BLOCK = 45438,
    POLYMORPH = 118,
    SLOW_FALL = 130,
    SPELLSTEAL = 30449,
    TIME_WARP = 80353,
    ALTER_TIME = 342245,
    
    -- Arcane
    ARCANE_BLAST = 30451,
    ARCANE_BARRAGE = 44425,
    ARCANE_MISSILES = 5143,
    ARCANE_EXPLOSION = 1449,
    ARCANE_POWER = 12042,
    PRESENCE_OF_MIND = 205025,
    EVOCATION = 12051,
    TOUCH_OF_THE_MAGI = 321507,
    RADIANT_SPARK = 376103,
    
    -- Fire
    FIREBALL = 133,
    FIRE_BLAST = 108853,
    PYROBLAST = 11366,
    FLAMESTRIKE = 2120,
    PHOENIX_FLAMES = 257541,
    SCORCH = 2948,
    COMBUSTION = 190319,
    DRAGONS_BREATH = 31661,
    
    -- Frost
    FROSTBOLT = 116,
    ICE_LANCE = 30455,
    FLURRY = 44614,
    FROZEN_ORB = 84714,
    BLIZZARD = 190356,
    ICY_VEINS = 12472,
    CONE_OF_COLD = 120,
    SUMMON_WATER_ELEMENTAL = 31687,
}

-- Buff IDs
local BUFFS = {
    -- Arcane
    ARCANE_POWER = 12042,
    CLEARCASTING = 263725,
    ARCANE_FAMILIAR = 210126,
    
    -- Fire
    COMBUSTION = 190319,
    HEATING_UP = 48107,
    HOT_STREAK = 48108,
    
    -- Frost
    ICY_VEINS = 12472,
    BRAIN_FREEZE = 190446,
    FINGERS_OF_FROST = 44544,
}

-- Debuff IDs
local DEBUFFS = {
    -- Arcane
    TOUCH_OF_THE_MAGI = 321507,
    RADIANT_SPARK = 376103,
    
    -- Fire
    IGNITE = 12654,
    
    -- Frost
    WINTERS_CHILL = 228358,
}

-- Arcane State
local arcaneState = {
    arcaneCharges = 0,
    clearcastingProc = false,
    touchOfTheMagi = false,
    radiantSpark = false,
    arcanePower = false,
    evocation = false,
    manaPct = 100,
}

-- Fire State
local fireState = {
    heatingUp = false,
    hotStreak = false,
    combustion = false,
    igniteActive = false,
}

-- Frost State
local frostState = {
    brainFreeze = false,
    fingersOfFrost = false,
    icyVeins = false,
    wintersChill = false,
    frozenTarget = false,
}

-- Initialize the Mage module
function Mage:Initialize()
    WR:Debug("Initializing Mage module")
    
    -- Register spell cast events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" then
                Mage:OnSpellCast(spellID)
            end
        elseif event == "UNIT_AURA" then
            local unit = ...
            if unit == "player" or unit == "target" then
                Mage:UpdateAuras(unit)
            end
        elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            Mage:UpdateTalents()
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            Mage:UpdateCooldowns()
        end
    end)
    
    -- Load the current specialization
    self:UpdateTalents()
    self:UpdateAuras("player")
    self:UpdateAuras("target")
}

-- Handle spell casts
function Mage:OnSpellCast(spellID)
    local specID = WR.currentSpec
    
    -- Update specialization-specific state
    if specID == ARCANE_SPEC then
        self:HandleArcaneSpellCast(spellID)
    elseif specID == FIRE_SPEC then
        self:HandleFireSpellCast(spellID)
    elseif specID == FROST_SPEC then
        self:HandleFrostSpellCast(spellID)
    end
end

-- Handle Arcane spell casts
function Mage:HandleArcaneSpellCast(spellID)
    -- Track Arcane Charges
    if spellID == SPELLS.ARCANE_BLAST then
        if arcaneState.arcaneCharges < 4 then
            arcaneState.arcaneCharges = arcaneState.arcaneCharges + 1
        end
    elseif spellID == SPELLS.ARCANE_BARRAGE then
        arcaneState.arcaneCharges = 0
    end
    
    -- Track major cooldowns
    if spellID == SPELLS.TOUCH_OF_THE_MAGI then
        arcaneState.touchOfTheMagi = true
    elseif spellID == SPELLS.RADIANT_SPARK then
        arcaneState.radiantSpark = true
    elseif spellID == SPELLS.ARCANE_POWER then
        arcaneState.arcanePower = true
    elseif spellID == SPELLS.EVOCATION then
        arcaneState.evocation = true
    end
end

-- Handle Fire spell casts
function Mage:HandleFireSpellCast(spellID)
    -- Clear Heating Up if we cast a non-crit spell
    if spellID == SPELLS.COMBUSTION then
        fireState.combustion = true
    end
    
    -- Reset Heating Up or Hot Streak after using it
    if spellID == SPELLS.PYROBLAST or spellID == SPELLS.FLAMESTRIKE then
        -- Hot Streak is consumed when Pyroblast/Flamestrike is cast
        if fireState.hotStreak then
            fireState.hotStreak = false
        end
    end
}

-- Handle Frost spell casts
function Mage:HandleFrostSpellCast(spellID)
    -- Track Frost procs usage
    if spellID == SPELLS.FLURRY and frostState.brainFreeze then
        frostState.brainFreeze = false
    elseif spellID == SPELLS.ICE_LANCE and frostState.fingersOfFrost then
        frostState.fingersOfFrost = false
    elseif spellID == SPELLS.ICY_VEINS then
        frostState.icyVeins = true
    elseif spellID == SPELLS.FROZEN_ORB then
        -- Frozen Orb can generate Fingers of Frost procs
    end
}

-- Update auras
function Mage:UpdateAuras(unit)
    local specID = WR.currentSpec
    
    if unit == "player" then
        -- Update Arcane auras
        if specID == ARCANE_SPEC then
            arcaneState.clearcastingProc = AuraUtil.FindAuraByID(BUFFS.CLEARCASTING, "player") ~= nil
            arcaneState.arcanePower = AuraUtil.FindAuraByID(BUFFS.ARCANE_POWER, "player") ~= nil
            arcaneState.arcaneCharges = UnitPower("player", Enum.PowerType.ArcaneCharges) or 0
            arcaneState.manaPct = UnitPower("player", Enum.PowerType.Mana) / UnitPowerMax("player", Enum.PowerType.Mana) * 100
        
        -- Update Fire auras
        elseif specID == FIRE_SPEC then
            fireState.heatingUp = AuraUtil.FindAuraByID(BUFFS.HEATING_UP, "player") ~= nil
            fireState.hotStreak = AuraUtil.FindAuraByID(BUFFS.HOT_STREAK, "player") ~= nil
            fireState.combustion = AuraUtil.FindAuraByID(BUFFS.COMBUSTION, "player") ~= nil
        
        -- Update Frost auras
        elseif specID == FROST_SPEC then
            frostState.brainFreeze = AuraUtil.FindAuraByID(BUFFS.BRAIN_FREEZE, "player") ~= nil
            frostState.fingersOfFrost = AuraUtil.FindAuraByID(BUFFS.FINGERS_OF_FROST, "player") ~= nil
            frostState.icyVeins = AuraUtil.FindAuraByID(BUFFS.ICY_VEINS, "player") ~= nil
        end
    end
    
    if unit == "target" then
        -- Update target debuffs based on spec
        if specID == ARCANE_SPEC then
            arcaneState.touchOfTheMagi = AuraUtil.FindAuraByID(DEBUFFS.TOUCH_OF_THE_MAGI, "target", "PLAYER|HARMFUL") ~= nil
            arcaneState.radiantSpark = AuraUtil.FindAuraByID(DEBUFFS.RADIANT_SPARK, "target", "PLAYER|HARMFUL") ~= nil
        
        elseif specID == FIRE_SPEC then
            fireState.igniteActive = AuraUtil.FindAuraByID(DEBUFFS.IGNITE, "target", "PLAYER|HARMFUL") ~= nil
        
        elseif specID == FROST_SPEC then
            frostState.wintersChill = AuraUtil.FindAuraByID(DEBUFFS.WINTERS_CHILL, "target", "PLAYER|HARMFUL") ~= nil
            
            -- Check if target is frozen (for Ice Lance bonus)
            local frozen = false
            local rootTypes = {"ROOT", "STUN", "FROZEN"}
            for i = 1, 40 do
                local _, _, _, debuffType = UnitDebuff("target", i)
                if debuffType and tContains(rootTypes, debuffType) then
                    frozen = true
                    break
                end
            end
            frostState.frozenTarget = frozen
        end
    end
end

-- Update talents
function Mage:UpdateTalents()
    WR:Debug("Updating Mage talents")
    
    -- Get current spec information
    local specID = GetSpecializationInfo(GetSpecialization())
    
    -- Load the appropriate rotation for the current spec
    self:LoadSpec(specID)
}

-- Update cooldowns
function Mage:UpdateCooldowns()
    -- Not critical for this implementation
end

-- Load a specific specialization rotation
function Mage:LoadSpec(specID)
    WR:Debug("Loading Mage spec: " .. (specID or "Unknown"))
    
    -- Clear any existing rotation
    WR.Rotation:RegisterRotationFunction(specID, nil)
    
    -- Register the appropriate rotation function
    if specID == ARCANE_SPEC then
        WR.Rotation:RegisterRotationFunction(specID, self.ArcaneRotation)
        WR:Debug("Registered Arcane Mage rotation")
    elseif specID == FIRE_SPEC then
        WR.Rotation:RegisterRotationFunction(specID, self.FireRotation)
        WR:Debug("Registered Fire Mage rotation")
    elseif specID == FROST_SPEC then
        WR.Rotation:RegisterRotationFunction(specID, self.FrostRotation)
        WR:Debug("Registered Frost Mage rotation")
    end
    
    -- Register utility functions
    WR.Rotation:RegisterPreCombatAction("MageBuffs", self.PreCombatAction)
    WR.Rotation:RegisterCombatAction("MageInterrupt", self.InterruptAction)
    WR.Rotation:RegisterCombatAction("MageDefensive", self.DefensiveAction)
}

-- Apply a profile
function Mage:ApplyProfile(profile)
    -- Implement profile application
    WR:Debug("Applying Mage profile: " .. (profile.name or "Unknown"))
    
    -- Here we would configure the rotation priorities based on the profile
    -- For now, just acknowledge the profile application
}

-- Pre-combat actions
function Mage.PreCombatAction()
    -- Check for Arcane Intellect
    local hasIntellect = AuraUtil.FindAuraByID(SPELLS.ARCANE_INTELLECT, "player")
    if not hasIntellect and WR.API:IsSpellCastable(SPELLS.ARCANE_INTELLECT) then
        WR:Debug("Casting Arcane Intellect")
        return WR.Queue:CastSpell(SPELLS.ARCANE_INTELLECT)
    end
    
    return false
end

-- Interrupt action
function Mage.InterruptAction()
    -- Only attempt to interrupt if enabled
    if not WR.Rotation:IsCombatActionEnabled("interrupts") then
        return false
    end
    
    -- Check if Counterspell is available
    if WR.Rotation:ShouldUseInterrupt() and WR.API:IsSpellCastable(SPELLS.COUNTERSPELL, "target") then
        WR:Debug("Casting Counterspell")
        return WR.Queue:CastSpell(SPELLS.COUNTERSPELL, "target")
    end
    
    return false
end

-- Defensive action
function Mage.DefensiveAction()
    -- Only attempt to use defensives if enabled
    if not WR.Rotation:IsCombatActionEnabled("defensives") then
        return false
    end
    
    local playerHealth = WR.API:UnitHealthPercent("player")
    
    -- Ice Block at very low health
    if playerHealth < 20 and WR.API:IsSpellCastable(SPELLS.ICE_BLOCK) then
        WR:Debug("Casting Ice Block (emergency)")
        return WR.Queue:CastSpell(SPELLS.ICE_BLOCK)
    end
    
    -- Alter Time for health recovery
    if playerHealth < 50 and WR.API:IsSpellCastable(SPELLS.ALTER_TIME) then
        WR:Debug("Casting Alter Time (defensive)")
        return WR.Queue:CastSpell(SPELLS.ALTER_TIME)
    end
    
    return false
end

-- ARCANE ROTATION
function Mage.ArcaneRotation(inCombat)
    -- If not in combat, try to buff up
    if not inCombat then
        -- Ensure Arcane Intellect is up
        local hasIntellect = AuraUtil.FindAuraByID(SPELLS.ARCANE_INTELLECT, "player")
        if not hasIntellect and WR.API:IsSpellCastable(SPELLS.ARCANE_INTELLECT) then
            WR:Debug("Casting Arcane Intellect")
            return WR.Queue:CastSpell(SPELLS.ARCANE_INTELLECT)
        end
        
        return false
    end
    
    -- Don't cast if player is currently casting or channeling
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    -- Check if we have a valid target
    if not WR.Target:HasValidTarget() then
        WR.Target:GetBestTarget(40)
        return false
    end
    
    -- Update Arcane state
    arcaneState.arcaneCharges = UnitPower("player", Enum.PowerType.ArcaneCharges) or 0
    arcaneState.manaPct = UnitPower("player", Enum.PowerType.Mana) / UnitPowerMax("player", Enum.PowerType.Mana) * 100
    arcaneState.clearcastingProc = AuraUtil.FindAuraByID(BUFFS.CLEARCASTING, "player") ~= nil
    arcaneState.touchOfTheMagi = AuraUtil.FindAuraByID(DEBUFFS.TOUCH_OF_THE_MAGI, "target", "PLAYER|HARMFUL") ~= nil
    arcaneState.radiantSpark = AuraUtil.FindAuraByID(DEBUFFS.RADIANT_SPARK, "target", "PLAYER|HARMFUL") ~= nil
    arcaneState.arcanePower = AuraUtil.FindAuraByID(BUFFS.ARCANE_POWER, "player") ~= nil
    
    -- Low mana, need to regen
    if arcaneState.manaPct < 15 and WR.API:IsSpellCastable(SPELLS.EVOCATION) then
        WR:Debug("Casting Evocation (low mana)")
        return WR.Queue:CastSpell(SPELLS.EVOCATION)
    end
    
    -- AOE rotation
    if WR.Rotation:ShouldUseAOE() and WR.Rotation:HasMultipleEnemies(3, 10) then
        return Mage.ArcaneAOERotation()
    end
    
    -- Cooldown phase - burst when available
    if WR.Rotation:ShouldUseCooldowns() then
        -- Touch of the Magi -> Radiant Spark -> Arcane Power sequence
        if WR.API:IsSpellCastable(SPELLS.TOUCH_OF_THE_MAGI) and 
           arcaneState.arcaneCharges >= 4 and
           not arcaneState.touchOfTheMagi then
            WR:Debug("Casting Touch of the Magi (cooldown)")
            return WR.Queue:CastSpell(SPELLS.TOUCH_OF_THE_MAGI, "target")
        end
        
        if arcaneState.touchOfTheMagi and 
           WR.API:IsSpellCastable(SPELLS.RADIANT_SPARK) and 
           not arcaneState.radiantSpark then
            WR:Debug("Casting Radiant Spark (cooldown)")
            return WR.Queue:CastSpell(SPELLS.RADIANT_SPARK, "target")
        end
        
        if arcaneState.touchOfTheMagi and arcaneState.radiantSpark and 
           WR.API:IsSpellCastable(SPELLS.ARCANE_POWER) and 
           not arcaneState.arcanePower then
            WR:Debug("Casting Arcane Power (cooldown)")
            return WR.Queue:CastSpell(SPELLS.ARCANE_POWER)
        end
    end
    
    -- Presence of Mind for quick Arcane Blasts during burst
    if (arcaneState.touchOfTheMagi or arcaneState.arcanePower) and 
       WR.API:IsSpellCastable(SPELLS.PRESENCE_OF_MIND) then
        WR:Debug("Casting Presence of Mind (burst)")
        return WR.Queue:CastSpell(SPELLS.PRESENCE_OF_MIND)
    end
    
    -- Use Arcane Missiles with Clearcasting proc
    if arcaneState.clearcastingProc and
       WR.API:IsSpellCastable(SPELLS.ARCANE_MISSILES) then
        WR:Debug("Casting Arcane Missiles (Clearcasting)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_MISSILES, "target")
    end
    
    -- Dump Arcane Charges with Arcane Barrage when Touch of the Magi is about to expire
    if arcaneState.touchOfTheMagi and WR.API:IsSpellCastable(SPELLS.ARCANE_BARRAGE) then
        local _, _, _, _, duration, expireTime = AuraUtil.FindAuraByID(DEBUFFS.TOUCH_OF_THE_MAGI, "target", "PLAYER|HARMFUL")
        if expireTime and (expireTime - GetTime()) < 1.5 then
            WR:Debug("Casting Arcane Barrage (TotM expiring)")
            return WR.Queue:CastSpell(SPELLS.ARCANE_BARRAGE, "target")
        end
    end
    
    -- Maintain rotation: Arcane Blast to build charges
    if arcaneState.arcaneCharges < 4 and WR.API:IsSpellCastable(SPELLS.ARCANE_BLAST) then
        WR:Debug("Casting Arcane Blast (build charges)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_BLAST, "target")
    end
    
    -- Arcane Barrage to dump charges when mana is getting low
    if arcaneState.arcaneCharges >= 4 and arcaneState.manaPct < 40 and 
       not arcaneState.touchOfTheMagi and not arcaneState.arcanePower and
       WR.API:IsSpellCastable(SPELLS.ARCANE_BARRAGE) then
        WR:Debug("Casting Arcane Barrage (conserve mana)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_BARRAGE, "target")
    end
    
    -- Continue casting Arcane Blast at 4 charges during burst phases
    if arcaneState.arcaneCharges >= 4 and (arcaneState.touchOfTheMagi or arcaneState.arcanePower) and
       WR.API:IsSpellCastable(SPELLS.ARCANE_BLAST) then
        WR:Debug("Casting Arcane Blast (burst)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_BLAST, "target")
    end
    
    -- Default to Arcane Blast if nothing else is better
    if WR.API:IsSpellCastable(SPELLS.ARCANE_BLAST) then
        WR:Debug("Casting Arcane Blast (default)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_BLAST, "target")
    end
    
    return false
end

-- Arcane AOE rotation
function Mage.ArcaneAOERotation()
    -- Touch of the Magi is great for AOE
    if WR.Rotation:ShouldUseCooldowns() and 
       WR.API:IsSpellCastable(SPELLS.TOUCH_OF_THE_MAGI) and
       not arcaneState.touchOfTheMagi then
        WR:Debug("Casting Touch of the Magi (AOE)")
        return WR.Queue:CastSpell(SPELLS.TOUCH_OF_THE_MAGI, "target")
    end
    
    -- AOE with Arcane Explosion
    if WR.API:IsSpellCastable(SPELLS.ARCANE_EXPLOSION) then
        WR:Debug("Casting Arcane Explosion (AOE)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_EXPLOSION)
    end
    
    return false
end

-- FIRE ROTATION
function Mage.FireRotation(inCombat)
    -- If not in combat, try to buff up
    if not inCombat then
        -- Ensure Arcane Intellect is up
        local hasIntellect = AuraUtil.FindAuraByID(SPELLS.ARCANE_INTELLECT, "player")
        if not hasIntellect and WR.API:IsSpellCastable(SPELLS.ARCANE_INTELLECT) then
            WR:Debug("Casting Arcane Intellect")
            return WR.Queue:CastSpell(SPELLS.ARCANE_INTELLECT)
        end
        
        return false
    end
    
    -- Don't cast if player is currently casting or channeling
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    -- Check if we have a valid target
    if not WR.Target:HasValidTarget() then
        WR.Target:GetBestTarget(40)
        return false
    end
    
    -- Update Fire state
    fireState.heatingUp = AuraUtil.FindAuraByID(BUFFS.HEATING_UP, "player") ~= nil
    fireState.hotStreak = AuraUtil.FindAuraByID(BUFFS.HOT_STREAK, "player") ~= nil
    fireState.combustion = AuraUtil.FindAuraByID(BUFFS.COMBUSTION, "player") ~= nil
    
    -- Combustion (main cooldown)
    if WR.Rotation:ShouldUseCooldowns() and 
       WR.API:IsSpellCastable(SPELLS.COMBUSTION) and
       not fireState.combustion then
        WR:Debug("Casting Combustion (cooldown)")
        return WR.Queue:CastSpell(SPELLS.COMBUSTION)
    end
    
    -- AOE rotation
    if WR.Rotation:ShouldUseAOE() and WR.Rotation:HasMultipleEnemies(3, 10) then
        return Mage.FireAOERotation()
    end
    
    -- Use Hot Streak procs
    if fireState.hotStreak and WR.API:IsSpellCastable(SPELLS.PYROBLAST) then
        WR:Debug("Casting Pyroblast (Hot Streak)")
        return WR.Queue:CastSpell(SPELLS.PYROBLAST, "target")
    end
    
    -- Use Fire Blast during Heating Up to convert to Hot Streak
    if fireState.heatingUp and WR.API:IsSpellCastable(SPELLS.FIRE_BLAST) then
        WR:Debug("Casting Fire Blast (convert Heating Up)")
        return WR.Queue:CastSpell(SPELLS.FIRE_BLAST, "target")
    end
    
    -- Use Phoenix Flames when available
    if WR.API:IsSpellCastable(SPELLS.PHOENIX_FLAMES) and 
       not fireState.heatingUp and not fireState.hotStreak then
        WR:Debug("Casting Phoenix Flames")
        return WR.Queue:CastSpell(SPELLS.PHOENIX_FLAMES, "target")
    end
    
    -- Use Dragon's Breath if target is close
    if WR.API:UnitDistance("target") < 10 and WR.API:IsSpellCastable(SPELLS.DRAGONS_BREATH) then
        WR:Debug("Casting Dragon's Breath (close range)")
        return WR.Queue:CastSpell(SPELLS.DRAGONS_BREATH)
    end
    
    -- Use Scorch when moving
    if WR.API:IsMoving() and WR.API:IsSpellCastable(SPELLS.SCORCH) then
        WR:Debug("Casting Scorch (movement)")
        return WR.Queue:CastSpell(SPELLS.SCORCH, "target")
    end
    
    -- Default to Fireball
    if WR.API:IsSpellCastable(SPELLS.FIREBALL) then
        WR:Debug("Casting Fireball (default)")
        return WR.Queue:CastSpell(SPELLS.FIREBALL, "target")
    end
    
    return false
end

-- Fire AOE rotation
function Mage.FireAOERotation()
    -- Use Hot Streak for Flamestrike instead of Pyroblast in AOE
    if fireState.hotStreak and WR.API:IsSpellCastable(SPELLS.FLAMESTRIKE) then
        WR:Debug("Casting Flamestrike (Hot Streak AOE)")
        return WR.Queue:CastSpell(SPELLS.FLAMESTRIKE, "target")
    end
    
    -- Fire Blast during Heating Up to get Hot Streak in AOE
    if fireState.heatingUp and WR.API:IsSpellCastable(SPELLS.FIRE_BLAST) then
        WR:Debug("Casting Fire Blast (convert Heating Up in AOE)")
        return WR.Queue:CastSpell(SPELLS.FIRE_BLAST, "target")
    end
    
    -- Phoenix Flames for AOE and to generate Heating Up
    if WR.API:IsSpellCastable(SPELLS.PHOENIX_FLAMES) then
        WR:Debug("Casting Phoenix Flames (AOE)")
        return WR.Queue:CastSpell(SPELLS.PHOENIX_FLAMES, "target")
    end
    
    -- Dragon's Breath for AOE damage and control
    if WR.API:IsSpellCastable(SPELLS.DRAGONS_BREATH) then
        WR:Debug("Casting Dragon's Breath (AOE)")
        return WR.Queue:CastSpell(SPELLS.DRAGONS_BREATH)
    end
    
    -- Flamestrike for AOE if we have lots of targets
    local targetCount = WR.Target:GetTargetCount(10)
    if targetCount >= 5 and WR.API:IsSpellCastable(SPELLS.FLAMESTRIKE) then
        WR:Debug("Casting Flamestrike (AOE)")
        return WR.Queue:CastSpell(SPELLS.FLAMESTRIKE, "target")
    end
    
    -- Fireball as default AOE filler
    if WR.API:IsSpellCastable(SPELLS.FIREBALL) then
        WR:Debug("Casting Fireball (AOE filler)")
        return WR.Queue:CastSpell(SPELLS.FIREBALL, "target")
    end
    
    return false
end

-- FROST ROTATION
function Mage.FrostRotation(inCombat)
    -- If not in combat, try to buff up
    if not inCombat then
        -- Ensure Arcane Intellect is up
        local hasIntellect = AuraUtil.FindAuraByID(SPELLS.ARCANE_INTELLECT, "player")
        if not hasIntellect and WR.API:IsSpellCastable(SPELLS.ARCANE_INTELLECT) then
            WR:Debug("Casting Arcane Intellect")
            return WR.Queue:CastSpell(SPELLS.ARCANE_INTELLECT)
        end
        
        -- Summon Water Elemental if not active
        if not UnitExists("pet") and WR.API:IsSpellCastable(SPELLS.SUMMON_WATER_ELEMENTAL) then
            WR:Debug("Casting Summon Water Elemental")
            return WR.Queue:CastSpell(SPELLS.SUMMON_WATER_ELEMENTAL)
        end
        
        return false
    end
    
    -- Don't cast if player is currently casting or channeling
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    -- Check if we have a valid target
    if not WR.Target:HasValidTarget() then
        WR.Target:GetBestTarget(40)
        return false
    end
    
    -- Update Frost state
    frostState.brainFreeze = AuraUtil.FindAuraByID(BUFFS.BRAIN_FREEZE, "player") ~= nil
    frostState.fingersOfFrost = AuraUtil.FindAuraByID(BUFFS.FINGERS_OF_FROST, "player") ~= nil
    frostState.icyVeins = AuraUtil.FindAuraByID(BUFFS.ICY_VEINS, "player") ~= nil
    frostState.wintersChill = AuraUtil.FindAuraByID(DEBUFFS.WINTERS_CHILL, "target", "PLAYER|HARMFUL") ~= nil
    
    -- Icy Veins (main cooldown)
    if WR.Rotation:ShouldUseCooldowns() and 
       WR.API:IsSpellCastable(SPELLS.ICY_VEINS) and
       not frostState.icyVeins then
        WR:Debug("Casting Icy Veins (cooldown)")
        return WR.Queue:CastSpell(SPELLS.ICY_VEINS)
    end
    
    -- Frozen Orb (secondary cooldown)
    if WR.Rotation:ShouldUseCooldowns() and WR.API:IsSpellCastable(SPELLS.FROZEN_ORB) then
        WR:Debug("Casting Frozen Orb (cooldown)")
        return WR.Queue:CastSpell(SPELLS.FROZEN_ORB, "target")
    end
    
    -- AOE rotation
    if WR.Rotation:ShouldUseAOE() and WR.Rotation:HasMultipleEnemies(3, 10) then
        return Mage.FrostAOERotation()
    end
    
    -- Brain Freeze proc for Flurry
    if frostState.brainFreeze and WR.API:IsSpellCastable(SPELLS.FLURRY) then
        WR:Debug("Casting Flurry (Brain Freeze)")
        return WR.Queue:CastSpell(SPELLS.FLURRY, "target")
    end
    
    -- Ice Lance with Fingers of Frost proc
    if frostState.fingersOfFrost and WR.API:IsSpellCastable(SPELLS.ICE_LANCE) then
        WR:Debug("Casting Ice Lance (Fingers of Frost)")
        return WR.Queue:CastSpell(SPELLS.ICE_LANCE, "target")
    end
    
    -- Ice Lance against Frozen targets
    if frostState.frozenTarget and WR.API:IsSpellCastable(SPELLS.ICE_LANCE) then
        WR:Debug("Casting Ice Lance (Frozen target)")
        return WR.Queue:CastSpell(SPELLS.ICE_LANCE, "target")
    end
    
    -- Ice Lance after Winter's Chill
    if frostState.wintersChill and WR.API:IsSpellCastable(SPELLS.ICE_LANCE) then
        WR:Debug("Casting Ice Lance (Winter's Chill)")
        return WR.Queue:CastSpell(SPELLS.ICE_LANCE, "target")
    end
    
    -- Default to Frostbolt
    if WR.API:IsSpellCastable(SPELLS.FROSTBOLT) then
        WR:Debug("Casting Frostbolt (default)")
        return WR.Queue:CastSpell(SPELLS.FROSTBOLT, "target")
    end
    
    return false
end

-- Frost AOE rotation
function Mage.FrostAOERotation()
    -- Blizzard for consistent AOE
    if WR.API:IsSpellCastable(SPELLS.BLIZZARD) then
        WR:Debug("Casting Blizzard (AOE)")
        return WR.Queue:CastSpell(SPELLS.BLIZZARD, "target")
    end
    
    -- Cone of Cold if enemies are close
    if WR.API:UnitDistance("target") < 10 and WR.API:IsSpellCastable(SPELLS.CONE_OF_COLD) then
        WR:Debug("Casting Cone of Cold (AOE)")
        return WR.Queue:CastSpell(SPELLS.CONE_OF_COLD)
    end
    
    -- Brain Freeze Flurry for AOE
    if frostState.brainFreeze and WR.API:IsSpellCastable(SPELLS.FLURRY) then
        WR:Debug("Casting Flurry (Brain Freeze AOE)")
        return WR.Queue:CastSpell(SPELLS.FLURRY, "target")
    end
    
    -- Ice Lance with Fingers of Frost in AOE
    if frostState.fingersOfFrost and WR.API:IsSpellCastable(SPELLS.ICE_LANCE) then
        WR:Debug("Casting Ice Lance (Fingers of Frost AOE)")
        return WR.Queue:CastSpell(SPELLS.ICE_LANCE, "target")
    end
    
    -- Default to Frostbolt in AOE
    if WR.API:IsSpellCastable(SPELLS.FROSTBOLT) then
        WR:Debug("Casting Frostbolt (AOE filler)")
        return WR.Queue:CastSpell(SPELLS.FROSTBOLT, "target")
    end
    
    return false
end

-- Initialize the module
Mage:Initialize()
