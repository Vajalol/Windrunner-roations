local addonName, WR = ...

-- Hunter Class Module
local Hunter = {}
WR.Classes.HUNTER = Hunter

-- Specialization IDs
local BEAST_MASTERY_SPEC = 253
local MARKSMANSHIP_SPEC = 254
local SURVIVAL_SPEC = 255

-- Hunter spells
local SPELLS = {
    -- Shared
    ASPECT_OF_THE_WILD = 193530,
    ASPECT_OF_THE_TURTLE = 186265,
    DISENGAGE = 781,
    FEIGN_DEATH = 5384,
    FLARE = 1543,
    HUNTERS_MARK = 257284,
    MEND_PET = 136,
    MISDIRECTION = 34477,
    REVIVE_PET = 982,
    TRANQUILIZING_SHOT = 19801,
    FREEZING_TRAP = 187650,
    TAR_TRAP = 187698,
    WING_CLIP = 195645,
    COUNTER_SHOT = 147362,
    EXHILARATION = 109304,
    BINDING_SHOT = 109248,
    CONCUSSIVE_SHOT = 5116,
    
    -- Beast Mastery
    KILL_COMMAND = 34026,
    BARBED_SHOT = 217200,
    BESTIAL_WRATH = 19574,
    COBRA_SHOT = 193455,
    CALL_OF_THE_WILD = 359844,
    DIRE_BEAST = 120679,
    BEAST_CLEAVE = 115939,
    STAMPEDE = 201430,
    
    -- Marksmanship
    AIMED_SHOT = 19434,
    ARCANE_SHOT = 185358,
    RAPID_FIRE = 257044,
    STEADY_SHOT = 56641,
    TRUESHOT = 288613,
    VOLLEY = 260243,
    EXPLOSIVE_SHOT = 212431,
    KILL_SHOT = 53351,
    TRICK_SHOTS = 257621,
    MULTI_SHOT = 257620,
    
    -- Survival
    WILDFIRE_BOMB = 259495,
    RAPTOR_STRIKE = 186270,
    MONGOOSE_BITE = 259387,
    CARVE = 187708,
    HARPOON = 190925,
    COORDINATED_ASSAULT = 360952,
    FLANKING_STRIKE = 269751,
    CHAKRAMS = 259391,
    BUTCHERY = 212436,
    SERPENT_STING = 259491,
}

-- Buff IDs
local BUFFS = {
    -- Shared
    HUNTERS_MARK = 257284,
    ASPECT_OF_THE_WILD = 193530,
    ASPECT_OF_THE_TURTLE = 186265,
    
    -- Beast Mastery
    BEAST_CLEAVE = 268877,
    BESTIAL_WRATH = 19574,
    FRENZY = 272790,
    DIRE_BEAST = 120694,
    
    -- Marksmanship
    TRUESHOT = 288613,
    LOCK_AND_LOAD = 194594,
    PRECISE_SHOTS = 260242,
    TRICK_SHOTS = 257622,
    
    -- Survival
    COORDINATED_ASSAULT = 360952,
    MONGOOSE_FURY = 259388,
    TIP_OF_THE_SPEAR = 260286,
    VIPERS_VENOM = 268552,
}

-- Debuff IDs
local DEBUFFS = {
    -- Shared
    HUNTERS_MARK = 257284,
    
    -- Beast Mastery
    -- (mostly relies on pet attacks)
    
    -- Marksmanship
    -- (mostly focuses on direct damage)
    
    -- Survival
    SERPENT_STING = 259491,
    INTERNAL_BLEEDING = 270343,
    WILDFIRE_BOMB = 269747,
    SHRAPNEL_BOMB = 270339,
    PHEROMONE_BOMB = 270332,
    VOLATILE_BOMB = 271049,
}

-- Beast Mastery State
local bmState = {
    barbedShotCharges = 0,
    barbedShotRecharge = 0,
    frenzyStacks = 0,
    frenzyRemaining = 0,
    bestialWrathActive = false,
    bestialWrathRemaining = 0,
    beastCleaveActive = false,
    beastCleaveRemaining = 0,
    killCommandCharges = 0,
    killCommandRecharge = 0,
    aspectOfTheWildActive = false,
    focusPct = 100,
    petActive = false,
}

-- Marksmanship State
local mmState = {
    aimedShotCharges = 0,
    lockAndLoadActive = false,
    preciseShotsActive = false,
    trueshotActive = false,
    trickShotsActive = false,
    focusPct = 100,
}

-- Survival State
local svState = {
    mongooseBiteActive = false,
    mongooseFuryStacks = 0,
    mongooseFuryRemaining = 0,
    coordinatedAssaultActive = false,
    serpentStingActive = false,
    serpentStingRemaining = 0,
    wildfireBombCharges = 0,
    tipOfTheSpearStacks = 0,
    focusPct = 100,
}

-- Initialize the Hunter module
function Hunter:Initialize()
    WR:Debug("Initializing Hunter module")
    
    -- Register spell cast events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("UNIT_POWER_FREQUENT")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("UNIT_PET")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" then
                Hunter:OnSpellCast(spellID)
            end
        elseif event == "UNIT_AURA" then
            local unit = ...
            if unit == "player" or unit == "target" or unit == "pet" then
                Hunter:UpdateAuras(unit)
            end
        elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            Hunter:UpdateTalents()
        elseif event == "UNIT_POWER_FREQUENT" then
            local unit, powerType = ...
            if unit == "player" and powerType == "FOCUS" then
                Hunter:UpdateFocus()
            end
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            Hunter:UpdateCooldowns()
        elseif event == "UNIT_PET" then
            local unit = ...
            if unit == "player" then
                Hunter:UpdatePet()
            end
        end
    end)
    
    -- Load the current specialization
    self:UpdateTalents()
    self:UpdateAuras("player")
    self:UpdateAuras("target")
    self:UpdateAuras("pet")
    self:UpdateFocus()
    self:UpdateCooldowns()
    self:UpdatePet()
}

-- Update focus
function Hunter:UpdateFocus()
    local focus = UnitPower("player", Enum.PowerType.Focus)
    local maxFocus = UnitPowerMax("player", Enum.PowerType.Focus)
    local focusPct = (focus / maxFocus) * 100
    
    -- Update spec-specific state
    local specID = WR.currentSpec
    if specID == BEAST_MASTERY_SPEC then
        bmState.focusPct = focusPct
    elseif specID == MARKSMANSHIP_SPEC then
        mmState.focusPct = focusPct
    elseif specID == SURVIVAL_SPEC then
        svState.focusPct = focusPct
    end
}

-- Update pet status
function Hunter:UpdatePet()
    local petActive = UnitExists("pet") and not UnitIsDead("pet")
    
    -- Update pet status in BM state (most important for this spec)
    bmState.petActive = petActive
}

-- Handle spell casts
function Hunter:OnSpellCast(spellID)
    local specID = WR.currentSpec
    
    -- Update specialization-specific state
    if specID == BEAST_MASTERY_SPEC then
        self:HandleBeastMasterySpellCast(spellID)
    elseif specID == MARKSMANSHIP_SPEC then
        self:HandleMarksmanshipSpellCast(spellID)
    elseif specID == SURVIVAL_SPEC then
        self:HandleSurvivalSpellCast(spellID)
    end
}

-- Handle Beast Mastery spell casts
function Hunter:HandleBeastMasterySpellCast(spellID)
    -- Track Beast Cleave application
    if spellID == SPELLS.MULTI_SHOT then
        bmState.beastCleaveActive = true
        -- Beast Cleave lasts 4 seconds after Multi-Shot
        bmState.beastCleaveRemaining = 4
    elseif spellID == SPELLS.BESTIAL_WRATH then
        bmState.bestialWrathActive = true
        -- Bestial Wrath lasts 15 seconds
        bmState.bestialWrathRemaining = 15
    elseif spellID == SPELLS.BARBED_SHOT then
        -- Barbed Shot refreshes Frenzy and reduces Bestial Wrath CD
        -- This is tracked via auras, but we can decrement charges here
        if bmState.barbedShotCharges > 0 then
            bmState.barbedShotCharges = bmState.barbedShotCharges - 1
        end
    elseif spellID == SPELLS.KILL_COMMAND then
        -- Track Kill Command charges
        if bmState.killCommandCharges > 0 then
            bmState.killCommandCharges = bmState.killCommandCharges - 1
        end
    end
}

-- Handle Marksmanship spell casts
function Hunter:HandleMarksmanshipSpellCast(spellID)
    -- Track Aimed Shot charges
    if spellID == SPELLS.AIMED_SHOT then
        if mmState.aimedShotCharges > 0 then
            mmState.aimedShotCharges = mmState.aimedShotCharges - 1
        end
        -- Using Aimed Shot consumes Precise Shots
        mmState.preciseShotsActive = false
    elseif spellID == SPELLS.ARCANE_SHOT or spellID == SPELLS.MULTI_SHOT then
        -- Using Arcane Shot or Multi-Shot consumes Precise Shots
        mmState.preciseShotsActive = false
    elseif spellID == SPELLS.TRUESHOT then
        mmState.trueshotActive = true
    elseif spellID == SPELLS.MULTI_SHOT then
        -- Multi-Shot activates Trick Shots
        mmState.trickShotsActive = true
    end
}

-- Handle Survival spell casts
function Hunter:HandleSurvivalSpellCast(spellID)
    -- Track Mongoose Bite stacks
    if spellID == SPELLS.MONGOOSE_BITE then
        svState.mongooseBiteActive = true
        if svState.mongooseFuryStacks < 5 then
            svState.mongooseFuryStacks = svState.mongooseFuryStacks + 1
        end
        svState.mongooseFuryRemaining = 14 -- Mongoose Fury lasts 14 seconds
    elseif spellID == SPELLS.WILDFIRE_BOMB then
        if svState.wildfireBombCharges > 0 then
            svState.wildfireBombCharges = svState.wildfireBombCharges - 1
        end
    elseif spellID == SPELLS.COORDINATED_ASSAULT then
        svState.coordinatedAssaultActive = true
    elseif spellID == SPELLS.SERPENT_STING then
        svState.serpentStingActive = true
        svState.serpentStingRemaining = 18 -- Serpent Sting lasts 18 seconds
    elseif spellID == SPELLS.RAPTOR_STRIKE or spellID == SPELLS.CARVE then
        -- Increases Tip of the Spear stacks
        if svState.tipOfTheSpearStacks < 3 then
            svState.tipOfTheSpearStacks = svState.tipOfTheSpearStacks + 1
        end
    end
}

-- Update auras
function Hunter:UpdateAuras(unit)
    local specID = WR.currentSpec
    
    if unit == "player" then
        if specID == BEAST_MASTERY_SPEC then
            -- Update Beast Mastery auras
            bmState.bestialWrathActive = AuraUtil.FindAuraByID(BUFFS.BESTIAL_WRATH, "player") ~= nil
            bmState.aspectOfTheWildActive = AuraUtil.FindAuraByID(BUFFS.ASPECT_OF_THE_WILD, "player") ~= nil
            
            -- Get Bestial Wrath remaining duration
            local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByID(BUFFS.BESTIAL_WRATH, "player")
            if expirationTime then
                bmState.bestialWrathRemaining = expirationTime - GetTime()
            else
                bmState.bestialWrathRemaining = 0
            end
        elseif specID == MARKSMANSHIP_SPEC then
            -- Update Marksmanship auras
            mmState.lockAndLoadActive = AuraUtil.FindAuraByID(BUFFS.LOCK_AND_LOAD, "player") ~= nil
            mmState.preciseShotsActive = AuraUtil.FindAuraByID(BUFFS.PRECISE_SHOTS, "player") ~= nil
            mmState.trueshotActive = AuraUtil.FindAuraByID(BUFFS.TRUESHOT, "player") ~= nil
            mmState.trickShotsActive = AuraUtil.FindAuraByID(BUFFS.TRICK_SHOTS, "player") ~= nil
        elseif specID == SURVIVAL_SPEC then
            -- Update Survival auras
            svState.coordinatedAssaultActive = AuraUtil.FindAuraByID(BUFFS.COORDINATED_ASSAULT, "player") ~= nil
            
            -- Update Mongoose Fury
            local mongooseFury = AuraUtil.FindAuraByID(BUFFS.MONGOOSE_FURY, "player")
            if mongooseFury then
                svState.mongooseBiteActive = true
                svState.mongooseFuryStacks = select(3, AuraUtil.FindAuraByID(BUFFS.MONGOOSE_FURY, "player")) or 0
                local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByID(BUFFS.MONGOOSE_FURY, "player")
                if expirationTime then
                    svState.mongooseFuryRemaining = expirationTime - GetTime()
                else
                    svState.mongooseFuryRemaining = 0
                end
            else
                svState.mongooseBiteActive = false
                svState.mongooseFuryStacks = 0
                svState.mongooseFuryRemaining = 0
            end
            
            -- Update Tip of the Spear
            svState.tipOfTheSpearStacks = select(3, AuraUtil.FindAuraByID(BUFFS.TIP_OF_THE_SPEAR, "player")) or 0
        end
    end
    
    if unit == "pet" and specID == BEAST_MASTERY_SPEC then
        -- Update Beast Mastery pet auras
        local frenzy = AuraUtil.FindAuraByID(BUFFS.FRENZY, "pet")
        if frenzy then
            bmState.frenzyStacks = select(3, AuraUtil.FindAuraByID(BUFFS.FRENZY, "pet")) or 0
            local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByID(BUFFS.FRENZY, "pet")
            if expirationTime then
                bmState.frenzyRemaining = expirationTime - GetTime()
            else
                bmState.frenzyRemaining = 0
            end
        else
            bmState.frenzyStacks = 0
            bmState.frenzyRemaining = 0
        end
        
        -- Update Beast Cleave on pet
        bmState.beastCleaveActive = AuraUtil.FindAuraByID(BUFFS.BEAST_CLEAVE, "pet") ~= nil
        local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByID(BUFFS.BEAST_CLEAVE, "pet")
        if expirationTime then
            bmState.beastCleaveRemaining = expirationTime - GetTime()
        else
            bmState.beastCleaveRemaining = 0
        end
    end
    
    if unit == "target" then
        -- Update target debuffs based on spec
        if specID == BEAST_MASTERY_SPEC then
            -- Beast Mastery primarily uses pet attacks rather than debuffs
        elseif specID == MARKSMANSHIP_SPEC then
            -- Marksmanship primarily uses direct damage rather than debuffs
        elseif specID == SURVIVAL_SPEC then
            svState.serpentStingActive = AuraUtil.FindAuraByID(DEBUFFS.SERPENT_STING, "target", "PLAYER|HARMFUL") ~= nil
            
            -- Get Serpent Sting remaining duration
            local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByID(DEBUFFS.SERPENT_STING, "target", "PLAYER|HARMFUL")
            if expirationTime then
                svState.serpentStingRemaining = expirationTime - GetTime()
            else
                svState.serpentStingRemaining = 0
            end
        end
    end
}

-- Update cooldowns
function Hunter:UpdateCooldowns()
    local specID = WR.currentSpec
    
    if specID == BEAST_MASTERY_SPEC then
        -- Update Barbed Shot charges
        local charges, maxCharges, startTime, duration = GetSpellCharges(SPELLS.BARBED_SHOT)
        if charges then
            bmState.barbedShotCharges = charges
            
            -- Calculate time until next charge
            if charges < maxCharges then
                bmState.barbedShotRecharge = (startTime + duration) - GetTime()
            else
                bmState.barbedShotRecharge = 0
            end
        else
            -- Fallback if GetSpellCharges fails
            bmState.barbedShotCharges = 0
            bmState.barbedShotRecharge = 0
        end
        
        -- Update Kill Command charges
        local kcCharges, kcMaxCharges, kcStartTime, kcDuration = GetSpellCharges(SPELLS.KILL_COMMAND)
        if kcCharges then
            bmState.killCommandCharges = kcCharges
            
            -- Calculate time until next charge
            if kcCharges < kcMaxCharges then
                bmState.killCommandRecharge = (kcStartTime + kcDuration) - GetTime()
            else
                bmState.killCommandRecharge = 0
            end
        else
            -- Fallback if GetSpellCharges fails
            bmState.killCommandCharges = 0
            bmState.killCommandRecharge = 0
        end
    elseif specID == MARKSMANSHIP_SPEC then
        -- Update Aimed Shot charges
        local charges, maxCharges, startTime, duration = GetSpellCharges(SPELLS.AIMED_SHOT)
        if charges then
            mmState.aimedShotCharges = charges
        else
            mmState.aimedShotCharges = 0
        end
    elseif specID == SURVIVAL_SPEC then
        -- Update Wildfire Bomb charges
        local charges, maxCharges, startTime, duration = GetSpellCharges(SPELLS.WILDFIRE_BOMB)
        if charges then
            svState.wildfireBombCharges = charges
        else
            svState.wildfireBombCharges = 0
        end
    end
}

-- Update talents
function Hunter:UpdateTalents()
    WR:Debug("Updating Hunter talents")
    
    -- Get current spec information
    local specID = GetSpecializationInfo(GetSpecialization())
    
    -- Load the appropriate rotation for the current spec
    self:LoadSpec(specID)
}

-- Load a specific specialization rotation
function Hunter:LoadSpec(specID)
    WR:Debug("Loading Hunter spec: " .. (specID or "Unknown"))
    
    -- Clear any existing rotation
    WR.Rotation:RegisterRotationFunction(specID, nil)
    
    -- Register the appropriate rotation function
    if specID == BEAST_MASTERY_SPEC then
        WR.Rotation:RegisterRotationFunction(specID, self.BeastMasteryRotation)
        WR:Debug("Registered Beast Mastery Hunter rotation")
    elseif specID == MARKSMANSHIP_SPEC then
        WR.Rotation:RegisterRotationFunction(specID, self.MarksmanshipRotation)
        WR:Debug("Registered Marksmanship Hunter rotation")
    elseif specID == SURVIVAL_SPEC then
        WR.Rotation:RegisterRotationFunction(specID, self.SurvivalRotation)
        WR:Debug("Registered Survival Hunter rotation")
    end
    
    -- Register utility functions
    WR.Rotation:RegisterPreCombatAction("HunterPet", self.PreCombatAction)
    WR.Rotation:RegisterCombatAction("HunterInterrupt", self.InterruptAction)
    WR.Rotation:RegisterCombatAction("HunterDefensive", self.DefensiveAction)
    WR.Rotation:RegisterCombatAction("HunterMisdirect", self.MisdirectAction)
}

-- Apply a profile
function Hunter:ApplyProfile(profile)
    -- Implement profile application
    WR:Debug("Applying Hunter profile: " .. (profile.name or "Unknown"))
    
    -- Here we would configure the rotation priorities based on the profile
    -- For now, just acknowledge the profile application
}

-- Pre-combat actions
function Hunter.PreCombatAction()
    -- Revive pet if it's dead
    if UnitIsDead("pet") and WR.API:IsSpellCastable(SPELLS.REVIVE_PET) then
        WR:Debug("Casting Revive Pet")
        return WR.Queue:CastSpell(SPELLS.REVIVE_PET)
    end
    
    -- Call pet if we don't have one
    if not UnitExists("pet") and WR.API:IsSpellCastable(SPELLS.CALL_PET) then
        WR:Debug("Calling Pet")
        return WR.Queue:CastSpell(SPELLS.CALL_PET)
    end
    
    -- Mend pet if it's alive but hurt
    if UnitExists("pet") and not UnitIsDead("pet") and 
       WR.API:UnitHealthPercent("pet") < 80 and 
       WR.API:IsSpellCastable(SPELLS.MEND_PET) then
        WR:Debug("Casting Mend Pet")
        return WR.Queue:CastSpell(SPELLS.MEND_PET)
    end
    
    return false
end

-- Interrupt action
function Hunter.InterruptAction()
    -- Only attempt to interrupt if enabled
    if not WR.Rotation:IsCombatActionEnabled("interrupts") then
        return false
    end
    
    -- Check if Counter Shot is available
    if WR.Rotation:ShouldUseInterrupt() and WR.API:IsSpellCastable(SPELLS.COUNTER_SHOT, "target") then
        WR:Debug("Casting Counter Shot")
        return WR.Queue:CastSpell(SPELLS.COUNTER_SHOT, "target")
    end
    
    return false
end

-- Defensive action
function Hunter.DefensiveAction()
    -- Only attempt to use defensives if enabled
    if not WR.Rotation:IsCombatActionEnabled("defensives") then
        return false
    end
    
    local playerHealth = WR.API:UnitHealthPercent("player")
    
    -- Aspect of the Turtle at very low health
    if playerHealth < 20 and WR.API:IsSpellCastable(SPELLS.ASPECT_OF_THE_TURTLE) then
        WR:Debug("Casting Aspect of the Turtle (emergency)")
        return WR.Queue:CastSpell(SPELLS.ASPECT_OF_THE_TURTLE)
    end
    
    -- Exhilaration for health recovery
    if playerHealth < 40 and WR.API:IsSpellCastable(SPELLS.EXHILARATION) then
        WR:Debug("Casting Exhilaration (defensive)")
        return WR.Queue:CastSpell(SPELLS.EXHILARATION)
    end
    
    -- Feign Death to drop combat in emergency
    if playerHealth < 15 and WR.API:IsSpellCastable(SPELLS.FEIGN_DEATH) then
        WR:Debug("Casting Feign Death (emergency)")
        return WR.Queue:CastSpell(SPELLS.FEIGN_DEATH)
    end
    
    return false
end

-- Misdirect action
function Hunter.MisdirectAction()
    -- Check if we should misdirect to the tank
    if not WR.API:UnitHasAura("player", SPELLS.MISDIRECTION) and 
       WR.API:IsSpellCastable(SPELLS.MISDIRECTION) then
        
        -- Find a tank to misdirect to
        local tankUnit = nil
        
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local unit = "raid" .. i
                if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" and
                   not UnitIsDead(unit) and UnitIsConnected(unit) and
                   UnitIsVisible(unit) then
                    tankUnit = unit
                    break
                end
            end
        elseif IsInGroup() then
            for i = 1, GetNumGroupMembers() - 1 do
                local unit = "party" .. i
                if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" and
                   not UnitIsDead(unit) and UnitIsConnected(unit) and
                   UnitIsVisible(unit) then
                    tankUnit = unit
                    break
                end
            end
        end
        
        -- Misdirect to tank or pet if no tank found
        if tankUnit then
            WR:Debug("Casting Misdirection on tank")
            return WR.Queue:CastSpell(SPELLS.MISDIRECTION, tankUnit)
        elseif UnitExists("pet") and not UnitIsDead("pet") then
            WR:Debug("Casting Misdirection on pet")
            return WR.Queue:CastSpell(SPELLS.MISDIRECTION, "pet")
        end
    end
    
    return false
end

-- BEAST MASTERY ROTATION
function Hunter.BeastMasteryRotation(inCombat)
    -- If not in combat, try to buff up
    if not inCombat then
        -- Revive pet if it's dead
        if UnitIsDead("pet") and WR.API:IsSpellCastable(SPELLS.REVIVE_PET) then
            WR:Debug("Casting Revive Pet")
            return WR.Queue:CastSpell(SPELLS.REVIVE_PET)
        end
        
        -- Mend pet if it's alive but hurt
        if UnitExists("pet") and not UnitIsDead("pet") and 
           WR.API:UnitHealthPercent("pet") < 80 and 
           WR.API:IsSpellCastable(SPELLS.MEND_PET) then
            WR:Debug("Casting Mend Pet")
            return WR.Queue:CastSpell(SPELLS.MEND_PET)
        end
        
        return false
    end
    
    -- Don't cast if player is currently casting
    if UnitCastingInfo("player") then
        return false
    end
    
    -- Check if we have a valid target
    if not WR.Target:HasValidTarget() then
        WR.Target:GetBestTarget(40)
        return false
    end
    
    -- Check if pet is dead - try to resurrect
    if not bmState.petActive and WR.API:IsSpellCastable(SPELLS.REVIVE_PET) then
        WR:Debug("Casting Revive Pet (emergency)")
        return WR.Queue:CastSpell(SPELLS.REVIVE_PET)
    end
    
    -- Update BM state information
    Hunter:UpdateFocus()
    Hunter:UpdateCooldowns()
    Hunter:UpdateAuras("player")
    Hunter:UpdateAuras("pet")
    Hunter:UpdateAuras("target")
    
    -- AOE rotation
    if WR.Rotation:ShouldUseAOE() and WR.Rotation:HasMultipleEnemies(3, 10) then
        return Hunter.BeastMasteryAOERotation()
    end
    
    -- Cooldown phase - burst when available
    if WR.Rotation:ShouldUseCooldowns() then
        -- Bestial Wrath
        if WR.API:IsSpellCastable(SPELLS.BESTIAL_WRATH) and 
           not bmState.bestialWrathActive then
            WR:Debug("Casting Bestial Wrath (cooldown)")
            return WR.Queue:CastSpell(SPELLS.BESTIAL_WRATH)
        end
        
        -- Aspect of the Wild
        if WR.API:IsSpellCastable(SPELLS.ASPECT_OF_THE_WILD) and 
           bmState.bestialWrathActive and
           not bmState.aspectOfTheWildActive then
            WR:Debug("Casting Aspect of the Wild (cooldown)")
            return WR.Queue:CastSpell(SPELLS.ASPECT_OF_THE_WILD)
        end
    end
    
    -- Barbed Shot priority when Frenzy needs refreshing
    if WR.API:IsSpellCastable(SPELLS.BARBED_SHOT) and 
       (bmState.frenzyRemaining < 2 or bmState.barbedShotCharges == 2) then
        WR:Debug("Casting Barbed Shot (maintain Frenzy)")
        return WR.Queue:CastSpell(SPELLS.BARBED_SHOT, "target")
    end
    
    -- Kill Command when available
    if WR.API:IsSpellCastable(SPELLS.KILL_COMMAND) and 
       bmState.killCommandCharges > 0 then
        WR:Debug("Casting Kill Command")
        return WR.Queue:CastSpell(SPELLS.KILL_COMMAND, "target")
    end
    
    -- Barbed Shot to reduce Bestial Wrath cooldown
    if WR.API:IsSpellCastable(SPELLS.BARBED_SHOT) and 
       bmState.barbedShotCharges > 0 and
       not bmState.bestialWrathActive then
        WR:Debug("Casting Barbed Shot (reduce Bestial Wrath CD)")
        return WR.Queue:CastSpell(SPELLS.BARBED_SHOT, "target")
    end
    
    -- Cobra Shot when focus is high
    if WR.API:IsSpellCastable(SPELLS.COBRA_SHOT) and 
       (bmState.focusPct > 70 or bmState.killCommandCharges == 0) then
        WR:Debug("Casting Cobra Shot")
        return WR.Queue:CastSpell(SPELLS.COBRA_SHOT, "target")
    end
    
    return false
end

-- Beast Mastery AOE rotation
function Hunter.BeastMasteryAOERotation()
    -- Maintain Beast Cleave
    if bmState.beastCleaveRemaining < 2 and 
       WR.API:IsSpellCastable(SPELLS.MULTI_SHOT) then
        WR:Debug("Casting Multi-Shot (maintain Beast Cleave)")
        return WR.Queue:CastSpell(SPELLS.MULTI_SHOT, "target")
    end
    
    -- Barbed Shot priority when Frenzy needs refreshing
    if WR.API:IsSpellCastable(SPELLS.BARBED_SHOT) and 
       (bmState.frenzyRemaining < 2 or bmState.barbedShotCharges == 2) then
        WR:Debug("Casting Barbed Shot (maintain Frenzy in AOE)")
        return WR.Queue:CastSpell(SPELLS.BARBED_SHOT, "target")
    end
    
    -- Bestial Wrath for AOE burst
    if WR.Rotation:ShouldUseCooldowns() and
       WR.API:IsSpellCastable(SPELLS.BESTIAL_WRATH) and 
       not bmState.bestialWrathActive then
        WR:Debug("Casting Bestial Wrath (AOE burst)")
        return WR.Queue:CastSpell(SPELLS.BESTIAL_WRATH)
    end
    
    -- Kill Command when available in AOE
    if WR.API:IsSpellCastable(SPELLS.KILL_COMMAND) and 
       bmState.killCommandCharges > 0 then
        WR:Debug("Casting Kill Command (AOE)")
        return WR.Queue:CastSpell(SPELLS.KILL_COMMAND, "target")
    end
    
    -- Multi-Shot for AOE damage
    if WR.API:IsSpellCastable(SPELLS.MULTI_SHOT) and
       WR.Target:GetTargetCount(10) >= 3 and
       bmState.focusPct > 50 then
        WR:Debug("Casting Multi-Shot (AOE damage)")
        return WR.Queue:CastSpell(SPELLS.MULTI_SHOT, "target")
    end
    
    -- Cobra Shot to spend excess Focus
    if WR.API:IsSpellCastable(SPELLS.COBRA_SHOT) and 
       bmState.focusPct > 80 then
        WR:Debug("Casting Cobra Shot (AOE focus dump)")
        return WR.Queue:CastSpell(SPELLS.COBRA_SHOT, "target")
    end
    
    return false
end

-- MARKSMANSHIP ROTATION
function Hunter.MarksmanshipRotation(inCombat)
    -- If not in combat, try to buff up
    if not inCombat then
        return false
    end
    
    -- Don't cast if player is currently casting
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    -- Check if we have a valid target
    if not WR.Target:HasValidTarget() then
        WR.Target:GetBestTarget(40)
        return false
    end
    
    -- Update MM state information
    Hunter:UpdateFocus()
    Hunter:UpdateCooldowns()
    Hunter:UpdateAuras("player")
    Hunter:UpdateAuras("target")
    
    -- AOE rotation
    if WR.Rotation:ShouldUseAOE() and WR.Rotation:HasMultipleEnemies(3, 10) then
        return Hunter.MarksmanshipAOERotation()
    end
    
    -- Cooldown phase - burst when available
    if WR.Rotation:ShouldUseCooldowns() then
        -- Trueshot
        if WR.API:IsSpellCastable(SPELLS.TRUESHOT) and 
           not mmState.trueshotActive then
            WR:Debug("Casting Trueshot (cooldown)")
            return WR.Queue:CastSpell(SPELLS.TRUESHOT)
        end
    end
    
    -- Kill Shot if target is below 20% health
    if WR.API:IsSpellCastable(SPELLS.KILL_SHOT) and
       WR.Rotation:GetTargetHealthPercent() < 20 then
        WR:Debug("Casting Kill Shot (execute)")
        return WR.Queue:CastSpell(SPELLS.KILL_SHOT, "target")
    end
    
    -- Use Aimed Shot with Lock and Load proc
    if mmState.lockAndLoadActive and WR.API:IsSpellCastable(SPELLS.AIMED_SHOT) then
        WR:Debug("Casting Aimed Shot (Lock and Load)")
        return WR.Queue:CastSpell(SPELLS.AIMED_SHOT, "target")
    end
    
    -- Use Arcane Shot with Precise Shots proc
    if mmState.preciseShotsActive and WR.API:IsSpellCastable(SPELLS.ARCANE_SHOT) then
        WR:Debug("Casting Arcane Shot (Precise Shots)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_SHOT, "target")
    end
    
    -- Use Aimed Shot if we have enough focus and charges
    if WR.API:IsSpellCastable(SPELLS.AIMED_SHOT) and
       mmState.aimedShotCharges > 0 and
       mmState.focusPct > 60 and
       not WR.API:IsMoving() then
        WR:Debug("Casting Aimed Shot")
        return WR.Queue:CastSpell(SPELLS.AIMED_SHOT, "target")
    end
    
    -- Use Rapid Fire for focus and damage
    if WR.API:IsSpellCastable(SPELLS.RAPID_FIRE) then
        WR:Debug("Casting Rapid Fire")
        return WR.Queue:CastSpell(SPELLS.RAPID_FIRE, "target")
    end
    
    -- Use Arcane Shot as a filler
    if WR.API:IsSpellCastable(SPELLS.ARCANE_SHOT) and
       mmState.focusPct > 40 then
        WR:Debug("Casting Arcane Shot (filler)")
        return WR.Queue:CastSpell(SPELLS.ARCANE_SHOT, "target")
    end
    
    -- Use Steady Shot to generate focus
    if WR.API:IsSpellCastable(SPELLS.STEADY_SHOT) then
        WR:Debug("Casting Steady Shot (focus generation)")
        return WR.Queue:CastSpell(SPELLS.STEADY_SHOT, "target")
    end
    
    return false
end

-- Marksmanship AOE rotation
function Hunter.MarksmanshipAOERotation()
    -- Trick Shots setup with Multi-Shot
    if not mmState.trickShotsActive and
       WR.API:IsSpellCastable(SPELLS.MULTI_SHOT) then
        WR:Debug("Casting Multi-Shot (setup Trick Shots)")
        return WR.Queue:CastSpell(SPELLS.MULTI_SHOT, "target")
    end
    
    -- Trueshot for AOE burst
    if WR.Rotation:ShouldUseCooldowns() and
       WR.API:IsSpellCastable(SPELLS.TRUESHOT) and 
       not mmState.trueshotActive then
        WR:Debug("Casting Trueshot (AOE burst)")
        return WR.Queue:CastSpell(SPELLS.TRUESHOT)
    end
    
    -- Volley if talented
    if WR.Rotation:ShouldUseCooldowns() and
       WR.API:IsSpellCastable(SPELLS.VOLLEY) then
        WR:Debug("Casting Volley (AOE)")
        return WR.Queue:CastSpell(SPELLS.VOLLEY, "target")
    end
    
    -- Aimed Shot with Trick Shots buff
    if mmState.trickShotsActive and
       WR.API:IsSpellCastable(SPELLS.AIMED_SHOT) and
       mmState.aimedShotCharges > 0 and
       mmState.focusPct > 50 and
       not WR.API:IsMoving() then
        WR:Debug("Casting Aimed Shot (Trick Shots)")
        return WR.Queue:CastSpell(SPELLS.AIMED_SHOT, "target")
    end
    
    -- Rapid Fire with Trick Shots
    if mmState.trickShotsActive and
       WR.API:IsSpellCastable(SPELLS.RAPID_FIRE) then
        WR:Debug("Casting Rapid Fire (AOE)")
        return WR.Queue:CastSpell(SPELLS.RAPID_FIRE, "target")
    end
    
    -- Multi-Shot for AOE damage and to maintain Trick Shots
    if WR.API:IsSpellCastable(SPELLS.MULTI_SHOT) and
       (mmState.focusPct > 40 or not mmState.trickShotsActive) then
        WR:Debug("Casting Multi-Shot (AOE damage)")
        return WR.Queue:CastSpell(SPELLS.MULTI_SHOT, "target")
    end
    
    -- Steady Shot to generate focus in AOE
    if WR.API:IsSpellCastable(SPELLS.STEADY_SHOT) and
       mmState.focusPct < 30 then
        WR:Debug("Casting Steady Shot (AOE focus generation)")
        return WR.Queue:CastSpell(SPELLS.STEADY_SHOT, "target")
    end
    
    return false
end

-- SURVIVAL ROTATION
function Hunter.SurvivalRotation(inCombat)
    -- If not in combat, try to buff up
    if not inCombat then
        -- Revive pet if it's dead
        if UnitIsDead("pet") and WR.API:IsSpellCastable(SPELLS.REVIVE_PET) then
            WR:Debug("Casting Revive Pet")
            return WR.Queue:CastSpell(SPELLS.REVIVE_PET)
        end
        
        -- Mend pet if it's alive but hurt
        if UnitExists("pet") and not UnitIsDead("pet") and 
           WR.API:UnitHealthPercent("pet") < 80 and 
           WR.API:IsSpellCastable(SPELLS.MEND_PET) then
            WR:Debug("Casting Mend Pet")
            return WR.Queue:CastSpell(SPELLS.MEND_PET)
        end
        
        return false
    end
    
    -- Don't cast if player is currently casting
    if UnitCastingInfo("player") then
        return false
    end
    
    -- Check if we have a valid target
    if not WR.Target:HasValidTarget() then
        WR.Target:GetBestTarget(40)
        return false
    end
    
    -- Check if we're in melee range for most abilities
    local inMeleeRange = WR.API:UnitDistance("target") <= 5
    
    -- If not in melee range, try to get there
    if not inMeleeRange then
        -- Use Harpoon to close distance if available
        if WR.API:IsSpellCastable(SPELLS.HARPOON) and
           WR.API:UnitDistance("target") < 30 then
            WR:Debug("Casting Harpoon (gap closer)")
            return WR.Queue:CastSpell(SPELLS.HARPOON, "target")
        end
        
        -- Use Serpent Sting at range if not applied
        if not svState.serpentStingActive and
           WR.API:IsSpellCastable(SPELLS.SERPENT_STING) then
            WR:Debug("Casting Serpent Sting (range)")
            return WR.Queue:CastSpell(SPELLS.SERPENT_STING, "target")
        end
        
        -- Use Wildfire Bomb at range
        if WR.API:IsSpellCastable(SPELLS.WILDFIRE_BOMB) and
           svState.wildfireBombCharges > 0 then
            WR:Debug("Casting Wildfire Bomb (range)")
            return WR.Queue:CastSpell(SPELLS.WILDFIRE_BOMB, "target")
        end
        
        return false
    }
    
    -- Update Survival state information
    Hunter:UpdateFocus()
    Hunter:UpdateCooldowns()
    Hunter:UpdateAuras("player")
    Hunter:UpdateAuras("target")
    
    -- AOE rotation
    if WR.Rotation:ShouldUseAOE() and WR.Rotation:HasMultipleEnemies(3, 5) then
        return Hunter.SurvivalAOERotation()
    end
    
    -- Cooldown phase - burst when available
    if WR.Rotation:ShouldUseCooldowns() then
        -- Coordinated Assault
        if WR.API:IsSpellCastable(SPELLS.COORDINATED_ASSAULT) and 
           not svState.coordinatedAssaultActive then
            WR:Debug("Casting Coordinated Assault (cooldown)")
            return WR.Queue:CastSpell(SPELLS.COORDINATED_ASSAULT)
        end
    end
    
    -- Maintain Serpent Sting
    if (not svState.serpentStingActive or svState.serpentStingRemaining < 3) and
       WR.API:IsSpellCastable(SPELLS.SERPENT_STING) then
        WR:Debug("Casting Serpent Sting (maintain)")
        return WR.Queue:CastSpell(SPELLS.SERPENT_STING, "target")
    end
    
    -- Kill Command on cooldown
    if WR.API:IsSpellCastable(SPELLS.KILL_COMMAND) then
        WR:Debug("Casting Kill Command")
        return WR.Queue:CastSpell(SPELLS.KILL_COMMAND, "target")
    end
    
    -- Wildfire Bomb
    if WR.API:IsSpellCastable(SPELLS.WILDFIRE_BOMB) and
       svState.wildfireBombCharges > 0 then
        WR:Debug("Casting Wildfire Bomb")
        return WR.Queue:CastSpell(SPELLS.WILDFIRE_BOMB, "target")
    end
    
    -- Mongoose Bite if talented, prioritize during Mongoose Fury
    if svState.mongooseBiteActive and
       WR.API:IsSpellCastable(SPELLS.MONGOOSE_BITE) then
        WR:Debug("Casting Mongoose Bite")
        return WR.Queue:CastSpell(SPELLS.MONGOOSE_BITE, "target")
    end
    
    -- Raptor Strike as default melee attack
    if WR.API:IsSpellCastable(SPELLS.RAPTOR_STRIKE) then
        WR:Debug("Casting Raptor Strike")
        return WR.Queue:CastSpell(SPELLS.RAPTOR_STRIKE, "target")
    end
    
    return false
end

-- Survival AOE rotation
function Hunter.SurvivalAOERotation()
    -- Wildfire Bomb for AOE
    if WR.API:IsSpellCastable(SPELLS.WILDFIRE_BOMB) and
       svState.wildfireBombCharges > 0 then
        WR:Debug("Casting Wildfire Bomb (AOE)")
        return WR.Queue:CastSpell(SPELLS.WILDFIRE_BOMB, "target")
    end
    
    -- Coordinated Assault for AOE burst
    if WR.Rotation:ShouldUseCooldowns() and
       WR.API:IsSpellCastable(SPELLS.COORDINATED_ASSAULT) and 
       not svState.coordinatedAssaultActive then
        WR:Debug("Casting Coordinated Assault (AOE)")
        return WR.Queue:CastSpell(SPELLS.COORDINATED_ASSAULT)
    end
    
    -- Butchery if talented
    if WR.API:IsSpellCastable(SPELLS.BUTCHERY) then
        WR:Debug("Casting Butchery (AOE)")
        return WR.Queue:CastSpell(SPELLS.BUTCHERY)
    end
    
    -- Carve for AOE damage
    if WR.API:IsSpellCastable(SPELLS.CARVE) then
        WR:Debug("Casting Carve (AOE)")
        return WR.Queue:CastSpell(SPELLS.CARVE)
    end
    
    -- Kill Command in AOE
    if WR.API:IsSpellCastable(SPELLS.KILL_COMMAND) then
        WR:Debug("Casting Kill Command (AOE)")
        return WR.Queue:CastSpell(SPELLS.KILL_COMMAND, "target")
    end
    
    -- Serpent Sting on multiple targets
    if WR.API:IsSpellCastable(SPELLS.SERPENT_STING) and
       not svState.serpentStingActive then
        WR:Debug("Casting Serpent Sting (AOE)")
        return WR.Queue:CastSpell(SPELLS.SERPENT_STING, "target")
    end
    
    -- Mongoose Bite for AOE
    if svState.mongooseBiteActive and
       WR.API:IsSpellCastable(SPELLS.MONGOOSE_BITE) then
        WR:Debug("Casting Mongoose Bite (AOE)")
        return WR.Queue:CastSpell(SPELLS.MONGOOSE_BITE, "target")
    end
    
    -- Raptor Strike as AOE filler
    if WR.API:IsSpellCastable(SPELLS.RAPTOR_STRIKE) then
        WR:Debug("Casting Raptor Strike (AOE)")
        return WR.Queue:CastSpell(SPELLS.RAPTOR_STRIKE, "target")
    end
    
    return false
end

-- Initialize the module
Hunter:Initialize()
