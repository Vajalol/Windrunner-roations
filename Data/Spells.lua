local addonName, WR = ...

-- Spells data module - stores spell information and utilities
WR.Data.Spells = {}

-- Spell categories
local SPELL_CATEGORIES = {
    DAMAGE = "Damage",
    HEAL = "Healing",
    BUFF = "Buff",
    DEBUFF = "Debuff",
    COOLDOWN = "Cooldown",
    UTILITY = "Utility",
    INTERRUPT = "Interrupt",
    DEFENSIVE = "Defensive",
    MOBILITY = "Mobility",
    CC = "Crowd Control",
    PURGE = "Purge",
    DISPEL = "Dispel",
    TAUNT = "Taunt",
    OFFENSIVE_DISPEL = "Offensive Dispel",
    COVENANT = "Covenant",
    LEGENDARY = "Legendary Effect"
}

-- Spell data structure
local SPELLS = {
    -- Global spells/items
    GLOBAL = {
        HEALTHSTONE = {
            id = 5512,
            name = "Healthstone",
            category = SPELL_CATEGORIES.HEAL,
            isItem = true,
        },
        PHIAL_OF_SERENITY = {
            id = 177278,
            name = "Phial of Serenity",
            category = SPELL_CATEGORIES.HEAL,
            isItem = true,
        },
    },
    
    -- Mage spells
    MAGE = {
        -- General Mage spells
        ARCANE_INTELLECT = {
            id = 1459,
            name = "Arcane Intellect",
            category = SPELL_CATEGORIES.BUFF,
            duration = 3600,
            isRaid = true,
        },
        BLINK = {
            id = 1953,
            name = "Blink",
            category = SPELL_CATEGORIES.MOBILITY,
            cooldown = 15,
        },
        COUNTERSPELL = {
            id = 2139,
            name = "Counterspell",
            category = SPELL_CATEGORIES.INTERRUPT,
            cooldown = 24,
        },
        FROST_NOVA = {
            id = 122,
            name = "Frost Nova",
            category = SPELL_CATEGORIES.CC,
            cooldown = 30,
            duration = 8,
        },
        ICE_BLOCK = {
            id = 45438,
            name = "Ice Block",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 240,
            duration = 10,
        },
        POLYMORPH = {
            id = 118,
            name = "Polymorph",
            category = SPELL_CATEGORIES.CC,
            cooldown = 0,
            duration = 60,
        },
        SPELLSTEAL = {
            id = 30449,
            name = "Spellsteal",
            category = SPELL_CATEGORIES.OFFENSIVE_DISPEL,
            cooldown = 0,
        },
        
        -- Arcane spells
        ARCANE_BLAST = {
            id = 30451,
            name = "Arcane Blast",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        ARCANE_BARRAGE = {
            id = 44425,
            name = "Arcane Barrage",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 3,
        },
        ARCANE_MISSILES = {
            id = 5143,
            name = "Arcane Missiles",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
            channeled = true,
        },
        ARCANE_POWER = {
            id = 12042,
            name = "Arcane Power",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 120,
            duration = 10,
        },
        TOUCH_OF_THE_MAGI = {
            id = 321507,
            name = "Touch of the Magi",
            category = SPELL_CATEGORIES.DEBUFF,
            cooldown = 45,
            duration = 8,
        },
        
        -- Fire spells
        FIREBALL = {
            id = 133,
            name = "Fireball",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        FIRE_BLAST = {
            id = 108853,
            name = "Fire Blast",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 14,
            charges = 2,
        },
        PYROBLAST = {
            id = 11366,
            name = "Pyroblast",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        COMBUSTION = {
            id = 190319,
            name = "Combustion",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 120,
            duration = 10,
        },
        
        -- Frost spells
        FROSTBOLT = {
            id = 116,
            name = "Frostbolt",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        ICE_LANCE = {
            id = 30455,
            name = "Ice Lance",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        ICY_VEINS = {
            id = 12472,
            name = "Icy Veins",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 180,
            duration = 20,
        },
        FROZEN_ORB = {
            id = 84714,
            name = "Frozen Orb",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 60,
        },
    },
    
    -- Hunter spells
    HUNTER = {
        -- General Hunter spells
        MISDIRECTION = {
            id = 34477,
            name = "Misdirection",
            category = SPELL_CATEGORIES.UTILITY,
            cooldown = 30,
            duration = 8,
        },
        FEIGN_DEATH = {
            id = 5384,
            name = "Feign Death",
            category = SPELL_CATEGORIES.UTILITY,
            cooldown = 30,
            duration = 360,
        },
        ASPECT_OF_THE_TURTLE = {
            id = 186265,
            name = "Aspect of the Turtle",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 180,
            duration = 8,
        },
        EXHILARATION = {
            id = 109304,
            name = "Exhilaration",
            category = SPELL_CATEGORIES.HEAL,
            cooldown = 120,
        },
        COUNTER_SHOT = {
            id = 147362,
            name = "Counter Shot",
            category = SPELL_CATEGORIES.INTERRUPT,
            cooldown = 24,
        },
        
        -- Beast Mastery spells
        KILL_COMMAND = {
            id = 34026,
            name = "Kill Command",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 7.5,
        },
        BESTIAL_WRATH = {
            id = 19574,
            name = "Bestial Wrath",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 90,
            duration = 15,
        },
        BARBED_SHOT = {
            id = 217200,
            name = "Barbed Shot",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 12,
            charges = 2,
            duration = 8,
        },
        
        -- Marksmanship spells
        AIMED_SHOT = {
            id = 19434,
            name = "Aimed Shot",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 12,
            charges = 2,
        },
        TRUESHOT = {
            id = 288613,
            name = "Trueshot",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 120,
            duration = 15,
        },
        RAPID_FIRE = {
            id = 257044,
            name = "Rapid Fire",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 20,
            channeled = true,
        },
        
        -- Survival spells
        WILDFIRE_BOMB = {
            id = 259495,
            name = "Wildfire Bomb",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 18,
            charges = 1,
        },
        COORDINATED_ASSAULT = {
            id = 360952,
            name = "Coordinated Assault",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 120,
            duration = 20,
        },
        CARVE = {
            id = 187708,
            name = "Carve",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 6,
        },
    },
    
    -- Warrior spells
    WARRIOR = {
        -- General Warrior spells
        BATTLE_SHOUT = {
            id = 6673,
            name = "Battle Shout",
            category = SPELL_CATEGORIES.BUFF,
            duration = 3600,
            isRaid = true,
        },
        CHARGE = {
            id = 100,
            name = "Charge",
            category = SPELL_CATEGORIES.MOBILITY,
            cooldown = 20,
            charges = 1,
        },
        PUMMEL = {
            id = 6552,
            name = "Pummel",
            category = SPELL_CATEGORIES.INTERRUPT,
            cooldown = 15,
        },
        RALLYING_CRY = {
            id = 97462,
            name = "Rallying Cry",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 180,
            duration = 10,
            isRaid = true,
        },
        
        -- Arms spells
        MORTAL_STRIKE = {
            id = 12294,
            name = "Mortal Strike",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 6,
        },
        COLOSSUS_SMASH = {
            id = 167105,
            name = "Colossus Smash",
            category = SPELL_CATEGORIES.DEBUFF,
            cooldown = 45,
            duration = 10,
        },
        BLADESTORM_ARMS = {
            id = 227847,
            name = "Bladestorm",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 90,
            duration = 6,
            channeled = true,
        },
        
        -- Fury spells
        RAGING_BLOW = {
            id = 85288,
            name = "Raging Blow",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 8,
            charges = 2,
        },
        RAMPAGE = {
            id = 184367,
            name = "Rampage",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        RECKLESSNESS = {
            id = 1719,
            name = "Recklessness",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 90,
            duration = 10,
        },
        
        -- Protection spells
        SHIELD_SLAM = {
            id = 23922,
            name = "Shield Slam",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 9,
        },
        SHIELD_BLOCK = {
            id = 2565,
            name = "Shield Block",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 16,
            charges = 2,
            duration = 6,
        },
        SHIELD_WALL = {
            id = 871,
            name = "Shield Wall",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 240,
            duration = 8,
        },
    },
    
    -- Demon Hunter spells
    DEMONHUNTER = {
        -- General Demon Hunter spells
        FEL_RUSH = {
            id = 195072,
            name = "Fel Rush",
            category = SPELL_CATEGORIES.MOBILITY,
            cooldown = 10,
            charges = 2,
        },
        DISRUPT = {
            id = 183752,
            name = "Disrupt",
            category = SPELL_CATEGORIES.INTERRUPT,
            cooldown = 15,
        },
        CHAOS_NOVA = {
            id = 179057,
            name = "Chaos Nova",
            category = SPELL_CATEGORIES.CC,
            cooldown = 60,
            duration = 2,
        },
        IMMOLATION_AURA = {
            id = 258920,
            name = "Immolation Aura",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 15,
            duration = 6,
        },
        
        -- Havoc spells
        CHAOS_STRIKE = {
            id = 162794,
            name = "Chaos Strike",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        EYE_BEAM = {
            id = 198013,
            name = "Eye Beam",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 30,
            channeled = true,
        },
        METAMORPHOSIS_HAVOC = {
            id = 191427,
            name = "Metamorphosis",
            category = SPELL_CATEGORIES.COOLDOWN,
            cooldown = 240,
            duration = 30,
        },
        BLADE_DANCE = {
            id = 188499,
            name = "Blade Dance",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 9,
            duration = 1,
        },
        
        -- Vengeance spells
        SOUL_CLEAVE = {
            id = 228477,
            name = "Soul Cleave",
            category = SPELL_CATEGORIES.DAMAGE,
            cooldown = 0,
        },
        DEMON_SPIKES = {
            id = 203720,
            name = "Demon Spikes",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 20,
            charges = 2,
            duration = 6,
        },
        FIERY_BRAND = {
            id = 204021,
            name = "Fiery Brand",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 60,
            duration = 8,
        },
        METAMORPHOSIS_VENGEANCE = {
            id = 187827,
            name = "Metamorphosis",
            category = SPELL_CATEGORIES.DEFENSIVE,
            cooldown = 180,
            duration = 15,
        },
    },
    
    -- Important dungeon spells to track/interrupt
    DUNGEON = {
        -- Crucial dungeon spells to interrupt
        MENDING_RAPIDS = {
            id = 374066,
            name = "Mending Rapids",
            category = SPELL_CATEGORIES.HEAL,
            interruptPriority = 100,
        },
        MYSTIC_BLAST = {
            id = 371007,
            name = "Mystic Blast",
            category = SPELL_CATEGORIES.DAMAGE,
            interruptPriority = 90,
        },
        HEXTRICK_TOTEM = {
            id = 385353,
            name = "Hextrick Totem",
            category = SPELL_CATEGORIES.UTILITY,
            interruptPriority = 95,
        },
        HEALING_WAVE = {
            id = 394037,
            name = "Healing Wave",
            category = SPELL_CATEGORIES.HEAL,
            interruptPriority = 100,
        },
        DEATH_BOLT = {
            id = 368954,
            name = "Death Bolt",
            category = SPELL_CATEGORIES.DAMAGE,
            interruptPriority = 85,
        },
    }
}

-- Initialize the spells database
function WR.Data.Spells:Initialize()
    -- Simplified structure for quicker access
    self.SpellData = {}
    self.Categories = SPELL_CATEGORIES
    self.PrioritySpells = {}
    
    -- Format the data for our addon
    for className, classSpells in pairs(SPELLS) do
        if className == "DUNGEON" then
            -- Process dungeon-specific spells
            for spellName, spellData in pairs(classSpells) do
                -- Add to priority interrupt list if applicable
                if spellData.interruptPriority and spellData.interruptPriority > 0 then
                    self.PrioritySpells[spellData.id] = {
                        name = spellData.name,
                        priority = spellData.interruptPriority
                    }
                end
                
                -- Add to main spell database
                self.SpellData[spellData.id] = spellData
            end
        else
            -- Process class spells
            for spellName, spellData in pairs(classSpells) do
                self.SpellData[spellData.id] = spellData
            end
        end
    end
    
    WR:Debug("Spells data initialized")
end

-- Get spell data by ID
function WR.Data.Spells:GetSpellByID(spellID)
    return self.SpellData[spellID]
end

-- Get spell data by name (slower, requires iteration)
function WR.Data.Spells:GetSpellByName(spellName)
    for id, spellData in pairs(self.SpellData) do
        if spellData.name == spellName then
            return spellData
        end
    end
    return nil
end

-- Get all interrupt priority spells
function WR.Data.Spells:GetInterruptPrioritySpells()
    return self.PrioritySpells
end

-- Get if a spell should be interrupted with high priority
function WR.Data.Spells:GetInterruptPriority(spellID)
    if self.PrioritySpells[spellID] then
        return self.PrioritySpells[spellID].priority
    end
    return 0
end

-- Check if an item is usable
function WR.Data.Spells:IsItemUsable(itemID)
    return IsUsableItem(itemID)
end

-- Check if an item is on cooldown
function WR.Data.Spells:GetItemCooldown(itemID)
    local start, duration, enabled = GetItemCooldown(itemID)
    if start and duration then
        local cooldownRemaining = start + duration - GetTime()
        return cooldownRemaining > 0 and cooldownRemaining or 0, enabled == 1
    end
    return 0, false
end

-- Get information about a spell aura
function WR.Data.Spells:GetAuraInfo(spellID, unit, filter)
    unit = unit or "player"
    
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, 
          isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, 
          nameplateShowAll, timeMod, value1, value2, value3 = AuraUtil.FindAuraByID(spellID, unit, filter)
    
    if name then
        local remaining = expirationTime and expirationTime > 0 and (expirationTime - GetTime()) or 0
        
        return {
            name = name,
            icon = icon,
            count = count or 0,
            debuffType = debuffType,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
            remaining = remaining,
            unitCaster = unitCaster,
            isStealable = isStealable,
            spellId = spellId,
            value1 = value1,
            value2 = value2,
            value3 = value3
        }
    end
    
    return nil
end

-- Initialize the spells data
WR.Data.Spells:Initialize()
