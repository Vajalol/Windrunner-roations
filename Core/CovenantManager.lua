------------------------------------------
-- WindrunnerRotations - Covenant Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local CovenantManager = {}
WR.CovenantManager = CovenantManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Data storage
local playerRace = nil
local playerCovenant = nil
local playerCovenantID = nil
local playerSoulbind = nil
local playerSoulbindID = nil
local covenantAbilities = {}
local racialAbilities = {}
local COVENANT_KYRIAN = 1
local COVENANT_VENTHYR = 2
local COVENANT_NIGHTFAE = 3
local COVENANT_NECROLORD = 4
local covenantNames = {
    [COVENANT_KYRIAN] = "Kyrian",
    [COVENANT_VENTHYR] = "Venthyr",
    [COVENANT_NIGHTFAE] = "Night Fae",
    [COVENANT_NECROLORD] = "Necrolord"
}
local forceCovenantForTests = false

-- Initialize the Covenant Manager
function CovenantManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize covenant data
    self:InitializeCovenantData()
    
    -- Initialize racial data
    self:InitializeRacialData()
    
    -- Update player info
    self:UpdatePlayerInfo()
    
    API.PrintDebug("Covenant Manager initialized")
    return true
end

-- Register settings
function CovenantManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("CovenantManager", {
        generalSettings = {
            enableCovenantAbilities = {
                displayName = "Enable Covenant Abilities",
                description = "Use covenant abilities in rotation",
                type = "toggle",
                default = true
            },
            enableRacialAbilities = {
                displayName = "Enable Racial Abilities",
                description = "Use racial abilities in rotation",
                type = "toggle",
                default = true
            },
            forceCovenantForTesting = {
                displayName = "Force Covenant (Testing)",
                description = "Force a specific covenant for testing purposes",
                type = "dropdown",
                options = {"None", "Kyrian", "Venthyr", "Night Fae", "Necrolord"},
                default = "None"
            }
        },
        covenantSettings = {
            covenantAbilityPriority = {
                displayName = "Covenant Ability Priority",
                description = "Priority for covenant abilities (higher = use more often)",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            },
            classAbilityPriority = {
                displayName = "Class Covenant Ability Priority",
                description = "Priority for class-specific covenant abilities",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 7
            },
            useSoulbindPotency = {
                displayName = "Use Soulbind Potency",
                description = "Take into account soulbind potency conduits",
                type = "toggle",
                default = true
            }
        },
        racialSettings = {
            racialAbilityPriority = {
                displayName = "Racial Ability Priority",
                description = "Priority for racial abilities (higher = use more often)",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 4
            },
            useOffensiveRacials = {
                displayName = "Use Offensive Racials",
                description = "Use offensive racial abilities",
                type = "toggle",
                default = true
            },
            useDefensiveRacials = {
                displayName = "Use Defensive Racials",
                description = "Use defensive racial abilities",
                type = "toggle",
                default = true
            },
            useUtilityRacials = {
                displayName = "Use Utility Racials",
                description = "Use utility racial abilities",
                type = "toggle",
                default = true
            }
        },
        advancedSettings = {
            covenantCooldownAlignment = {
                displayName = "Covenant Cooldown Alignment",
                description = "Align covenant ability cooldowns with major class cooldowns",
                type = "toggle",
                default = true
            },
            racialCooldownAlignment = {
                displayName = "Racial Cooldown Alignment",
                description = "Align racial ability cooldowns with major class cooldowns",
                type = "toggle",
                default = true
            },
            covenantResourceThreshold = {
                displayName = "Covenant Resource Threshold",
                description = "Resource threshold for covenant abilities (if applicable)",
                type = "slider",
                min = 0,
                max = 100,
                step = 5,
                default = 50
            }
        }
    })
end

-- Register for events
function CovenantManager:RegisterEvents()
    -- Register for covenant change
    API.RegisterEvent("COVENANT_CHOSEN", function()
        self:UpdatePlayerInfo()
    end)
    
    -- Register for soulbind change
    API.RegisterEvent("SOULBIND_ACTIVATED", function()
        self:UpdatePlayerSoulbindInfo()
    end)
    
    -- Register for conduit change
    API.RegisterEvent("SOULBIND_CONDUIT_INSTALLED", function()
        self:UpdatePlayerConduitInfo()
    end)
    
    -- Register for talent change
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function()
        self:UpdateAbilityModifiers()
    end)
    
    -- Register for level change
    API.RegisterEvent("PLAYER_LEVEL_UP", function()
        self:UpdatePlayerInfo()
    end)
}

-- Update player info
function CovenantManager:UpdatePlayerInfo()
    -- Get player race
    local _, race = UnitRace("player")
    playerRace = race
    
    -- Get player covenant
    self:UpdatePlayerCovenantInfo()
    
    -- Get player soulbind
    self:UpdatePlayerSoulbindInfo()
    
    -- Update ability modifiers
    self:UpdateAbilityModifiers()
}

-- Update player covenant info
function CovenantManager:UpdatePlayerCovenantInfo()
    local settings = ConfigRegistry:GetSettings("CovenantManager")
    
    -- Check if we're forcing a covenant for testing
    local forceCovenant = settings.generalSettings.forceCovenantForTesting
    
    if forceCovenant and forceCovenant ~= "None" then
        -- Use the forced covenant
        playerCovenant = forceCovenant
        
        -- Set the covenant ID
        if forceCovenant == "Kyrian" then
            playerCovenantID = COVENANT_KYRIAN
        elseif forceCovenant == "Venthyr" then
            playerCovenantID = COVENANT_VENTHYR
        elseif forceCovenant == "Night Fae" then
            playerCovenantID = COVENANT_NIGHTFAE
        elseif forceCovenant == "Necrolord" then
            playerCovenantID = COVENANT_NECROLORD
        end
        
        API.PrintDebug("Forcing covenant: " .. forceCovenant)
    else
        -- Get covenant from WoW API
        playerCovenantID = C_Covenants and C_Covenants.GetActiveCovenantID() or nil
        
        if playerCovenantID and playerCovenantID > 0 and covenantNames[playerCovenantID] then
            playerCovenant = covenantNames[playerCovenantID]
            API.PrintDebug("Detected covenant: " .. playerCovenant)
        else
            playerCovenant = nil
            playerCovenantID = nil
            API.PrintDebug("No covenant detected")
        end
    end
}

-- Update player soulbind info
function CovenantManager:UpdatePlayerSoulbindInfo()
    -- Get soulbind from WoW API
    playerSoulbindID = C_Soulbinds and C_Soulbinds.GetActiveSoulbindID() or nil
    
    if playerSoulbindID and playerSoulbindID > 0 then
        local soulbindData = C_Soulbinds.GetSoulbindData(playerSoulbindID)
        if soulbindData then
            playerSoulbind = soulbindData.name
            API.PrintDebug("Detected soulbind: " .. playerSoulbind)
        else
            playerSoulbind = nil
        end
    else
        playerSoulbind = nil
        playerSoulbindID = nil
        API.PrintDebug("No soulbind detected")
    end
    
    -- Update conduits
    self:UpdatePlayerConduitInfo()
}

-- Update player conduit info
function CovenantManager:UpdatePlayerConduitInfo()
    -- This would get conduit information
    -- For implementation simplicity, we'll just print a debug message
    
    if playerSoulbindID then
        API.PrintDebug("Updating conduit info for soulbind: " .. (playerSoulbind or "Unknown"))
        
        -- Get installed conduits
        if C_Soulbinds and C_Soulbinds.GetConduits then
            local conduits = C_Soulbinds.GetConduits(Enum.SoulbindConduitType.Potency)
            
            if conduits and #conduits > 0 then
                for _, conduit in ipairs(conduits) do
                    API.PrintDebug("Found conduit: " .. conduit.conduitID .. " at rank " .. conduit.conduitRank)
                end
            else
                API.PrintDebug("No potency conduits found")
            end
        end
    end
}

-- Update ability modifiers
function CovenantManager:UpdateAbilityModifiers()
    -- This would update ability modifiers based on talents, conduits, etc.
    -- For implementation simplicity, we'll just print a debug message
    
    API.PrintDebug("Updating ability modifiers for race: " .. (playerRace or "Unknown") .. ", covenant: " .. (playerCovenant or "None"))
    
    -- Check if we have covenant abilities for this class
    local className = select(2, UnitClass("player"))
    
    if className and playerCovenantID then
        local classCovenantAbilities = self:GetClassCovenantAbilities(className, playerCovenantID)
        
        if classCovenantAbilities and #classCovenantAbilities > 0 then
            API.PrintDebug("Found " .. #classCovenantAbilities .. " covenant abilities for " .. className)
        else
            API.PrintDebug("No covenant abilities found for " .. className)
        end
    end
}

-- Initialize covenant data
function CovenantManager:InitializeCovenantData()
    -- General covenant signature abilities (for all classes)
    covenantAbilities.signature = {
        [COVENANT_KYRIAN] = {
            id = 324739,
            name = "Summon Steward",
            cooldown = 300,
            resource = nil,
            category = "utility"
        },
        [COVENANT_VENTHYR] = {
            id = 300728,
            name = "Door of Shadows",
            cooldown = 60,
            resource = nil,
            category = "utility"
        },
        [COVENANT_NIGHTFAE] = {
            id = 310143,
            name = "Soulshape",
            cooldown = 30,
            resource = nil,
            category = "utility"
        },
        [COVENANT_NECROLORD] = {
            id = 324631,
            name = "Fleshcraft",
            cooldown = 120,
            resource = nil,
            category = "defensive"
        }
    }
    
    -- Class-specific covenant abilities
    covenantAbilities.class = {}
    
    -- Death Knight
    covenantAbilities.class["DEATHKNIGHT"] = {
        [COVENANT_KYRIAN] = {id = 312202, name = "Shackle the Unworthy", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 311648, name = "Swarming Mist", cooldown = 60, resource = 10, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 324128, name = "Death's Due", cooldown = 30, resource = 10, category = "damage"},
        [COVENANT_NECROLORD] = {id = 315443, name = "Abomination Limb", cooldown = 120, resource = nil, category = "damage"}
    }
    
    -- Demon Hunter
    covenantAbilities.class["DEMONHUNTER"] = {
        [COVENANT_KYRIAN] = {id = 306830, name = "Elysian Decree", cooldown = 60, resource = 10, category = "damage"},
        [COVENANT_VENTHYR] = {id = 317009, name = "Sinful Brand", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 323639, name = "The Hunt", cooldown = 90, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 329554, name = "Fodder to the Flame", cooldown = 120, resource = nil, category = "damage"}
    }
    
    -- Druid
    covenantAbilities.class["DRUID"] = {
        [COVENANT_KYRIAN] = {id = 326434, name = "Kindred Spirits", cooldown = 60, resource = nil, category = "utility"},
        [COVENANT_VENTHYR] = {id = 323546, name = "Ravenous Frenzy", cooldown = 180, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 323764, name = "Convoke the Spirits", cooldown = 120, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 325727, name = "Adaptive Swarm", cooldown = 25, resource = nil, category = "damage"}
    }
    
    -- Hunter
    covenantAbilities.class["HUNTER"] = {
        [COVENANT_KYRIAN] = {id = 308491, name = "Resonating Arrow", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 324149, name = "Flayed Shot", cooldown = 30, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 328231, name = "Wild Spirits", cooldown = 120, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 325028, name = "Death Chakram", cooldown = 45, resource = nil, category = "damage"}
    }
    
    -- Mage
    covenantAbilities.class["MAGE"] = {
        [COVENANT_KYRIAN] = {id = 307443, name = "Radiant Spark", cooldown = 30, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 314793, name = "Mirrors of Torment", cooldown = 90, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 314791, name = "Shifting Power", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 324220, name = "Deathborne", cooldown = 180, resource = nil, category = "damage"}
    }
    
    -- Monk
    covenantAbilities.class["MONK"] = {
        [COVENANT_KYRIAN] = {id = 310454, name = "Weapons of Order", cooldown = 120, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 326860, name = "Fallen Order", cooldown = 180, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 327104, name = "Faeline Stomp", cooldown = 30, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 325216, name = "Bonedust Brew", cooldown = 60, resource = nil, category = "damage"}
    }
    
    -- Paladin
    covenantAbilities.class["PALADIN"] = {
        [COVENANT_KYRIAN] = {id = 304971, name = "Divine Toll", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 316958, name = "Ashen Hallow", cooldown = 240, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 328282, name = "Blessing of the Seasons", cooldown = 45, resource = nil, category = "utility"},
        [COVENANT_NECROLORD] = {id = 328204, name = "Vanquisher's Hammer", cooldown = 30, resource = 1, category = "damage"}
    }
    
    -- Priest
    covenantAbilities.class["PRIEST"] = {
        [COVENANT_KYRIAN] = {id = 325013, name = "Boon of the Ascended", cooldown = 180, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 323673, name = "Mindgames", cooldown = 45, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 327661, name = "Fae Guardians", cooldown = 90, resource = nil, category = "utility"},
        [COVENANT_NECROLORD] = {id = 324724, name = "Unholy Nova", cooldown = 60, resource = nil, category = "damage"}
    }
    
    -- Rogue
    covenantAbilities.class["ROGUE"] = {
        [COVENANT_KYRIAN] = {id = 328547, name = "Echoing Reprimand", cooldown = 45, resource = 10, category = "damage"},
        [COVENANT_VENTHYR] = {id = 323654, name = "Flagellation", cooldown = 90, resource = 10, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 328305, name = "Sepsis", cooldown = 90, resource = 10, category = "damage"},
        [COVENANT_NECROLORD] = {id = 328305, name = "Serrated Bone Spike", cooldown = 30, resource = nil, category = "damage"}
    }
    
    -- Shaman
    covenantAbilities.class["SHAMAN"] = {
        [COVENANT_KYRIAN] = {id = 324386, name = "Vesper Totem", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 320674, name = "Chain Harvest", cooldown = 90, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 328923, name = "Fae Transfusion", cooldown = 120, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 326059, name = "Primordial Wave", cooldown = 45, resource = nil, category = "damage"}
    }
    
    -- Warlock
    covenantAbilities.class["WARLOCK"] = {
        [COVENANT_KYRIAN] = {id = 312321, name = "Scouring Tithe", cooldown = 40, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 321792, name = "Impending Catastrophe", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 325640, name = "Soul Rot", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 325289, name = "Decimating Bolt", cooldown = 45, resource = nil, category = "damage"}
    }
    
    -- Warrior
    covenantAbilities.class["WARRIOR"] = {
        [COVENANT_KYRIAN] = {id = 307865, name = "Spear of Bastion", cooldown = 60, resource = nil, category = "damage"},
        [COVENANT_VENTHYR] = {id = 317349, name = "Condemn", cooldown = 6, resource = 10, category = "damage"},
        [COVENANT_NIGHTFAE] = {id = 325886, name = "Ancient Aftershock", cooldown = 90, resource = nil, category = "damage"},
        [COVENANT_NECROLORD] = {id = 324143, name = "Conqueror's Banner", cooldown = 120, resource = nil, category = "damage"}
    }
    
    -- Evoker (added in Dragonflight)
    covenantAbilities.class["EVOKER"] = {
        -- Evokers didn't exist during covenants, but we'll add placeholder entries for code consistency
        [COVENANT_KYRIAN] = {id = 0, name = "None", cooldown = 0, resource = nil, category = "none"},
        [COVENANT_VENTHYR] = {id = 0, name = "None", cooldown = 0, resource = nil, category = "none"},
        [COVENANT_NIGHTFAE] = {id = 0, name = "None", cooldown = 0, resource = nil, category = "none"},
        [COVENANT_NECROLORD] = {id = 0, name = "None", cooldown = 0, resource = nil, category = "none"}
    }
}

-- Initialize racial data
function CovenantManager:InitializeRacialData()
    -- Alliance Racials
    racialAbilities["Human"] = {
        {id = 59752, name = "Every Man for Himself", cooldown = 180, category = "defensive", description = "Removes all stun effects."}
    }
    
    racialAbilities["Dwarf"] = {
        {id = 20594, name = "Stoneform", cooldown = 120, category = "defensive", description = "Removes poison, disease, curse, magic, bleed effects and reduces damage taken."}
    }
    
    racialAbilities["NightElf"] = {
        {id = 58984, name = "Shadowmeld", cooldown = 120, category = "utility", description = "Activate to slip into the shadows, reducing the chance for enemies to detect your presence."}
    }
    
    racialAbilities["Gnome"] = {
        {id = 20589, name = "Escape Artist", cooldown = 60, category = "utility", description = "Escape the effects of any immobilization or movement speed reduction effect."}
    }
    
    racialAbilities["Draenei"] = {
        {id = 59545, name = "Gift of the Naaru", cooldown = 180, category = "healing", description = "Heals the target."}
    }
    
    racialAbilities["Worgen"] = {
        {id = 68992, name = "Darkflight", cooldown = 120, category = "utility", description = "Activating this racial ability will activate your Running Wild ability, increasing movement speed."},
        {id = 68975, name = "Aberration", cooldown = 0, category = "passive", description = "Reduces the duration of Curse and Disease effects by 10%."},
        {id = 87840, name = "Running Wild", cooldown = 0, category = "passive", description = "Drop to all fours to run as fast as a mount."}
    }
    
    racialAbilities["VoidElf"] = {
        {id = 256948, name = "Spatial Rift", cooldown = 180, category = "utility", description = "Tear a rift in space. Reactivate this ability to teleport through the rift."}
    }
    
    racialAbilities["LightforgedDraenei"] = {
        {id = 255647, name = "Light's Judgment", cooldown = 150, category = "damage", description = "Call down a strike of Holy energy, dealing damage to enemies within 5 yards."}
    }
    
    racialAbilities["DarkIronDwarf"] = {
        {id = 265221, name = "Fireblood", cooldown = 120, category = "defensive", description = "Removes all poison, disease, curse, magic, and bleed effects and increases your primary stat."}
    }
    
    racialAbilities["KulTiran"] = {
        {id = 287712, name = "Haymaker", cooldown = 150, category = "utility", description = "Winds up, then unleashes a mighty punch knocking an enemy target back."}
    }
    
    racialAbilities["Mechagnome"] = {
        {id = 312924, name = "Combat Analysis", cooldown = 120, category = "offensive", description = "Your Cybernetic Augments analyze your opponent during combat, increasing primary stat by 60 and stacking up to 2 times."}
    }
    
    -- Horde Racials
    racialAbilities["Orc"] = {
        {id = 20572, name = "Blood Fury", cooldown = 120, category = "offensive", description = "Increases attack power and spell power."}
    }
    
    racialAbilities["Undead"] = {
        {id = 7744, name = "Will of the Forsaken", cooldown = 180, category = "defensive", description = "Removes any Charm, Fear and Sleep effect."},
        {id = 20577, name = "Cannibalize", cooldown = 120, category = "healing", description = "When activated, regenerates 7% of total health every 2 sec for 10 sec."}
    }
    
    racialAbilities["Tauren"] = {
        {id = 20549, name = "War Stomp", cooldown = 90, category = "utility", description = "Stuns up to 5 enemies within 8 yards for 2 sec."}
    }
    
    racialAbilities["Troll"] = {
        {id = 26297, name = "Berserking", cooldown = 180, category = "offensive", description = "Increases your haste by 15% for 10 sec."}
    }
    
    racialAbilities["BloodElf"] = {
        {id = 28730, name = "Arcane Torrent", cooldown = 90, category = "utility", description = "Removes 1 beneficial effect from all enemies within 8 yards and restores resource."}
    }
    
    racialAbilities["Goblin"] = {
        {id = 69070, name = "Rocket Jump", cooldown = 90, category = "utility", description = "Activates your rocket belt to jump forward."}
    }
    
    racialAbilities["Nightborne"] = {
        {id = 260364, name = "Arcane Pulse", cooldown = 180, category = "offensive", description = "Deals 1,544 Arcane damage to nearby enemies and reduces their movement speed by 50%."}
    }
    
    racialAbilities["HighmountainTauren"] = {
        {id = 255654, name = "Bull Rush", cooldown = 120, category = "utility", description = "Charges forward for 1 sec, knocking enemies down for 0.5 sec."}
    }
    
    racialAbilities["MagharOrc"] = {
        {id = 274738, name = "Ancestral Call", cooldown = 120, category = "offensive", description = "Invoke the spirits of your ancestors, granting you their power. Increases primary stat."}
    }
    
    racialAbilities["ZandalariTroll"] = {
        {id = 291944, name = "Regeneratin'", cooldown = 150, category = "healing", description = "Regenerate 1.5% of your maximum health every 1 sec for 6 sec."}
    }
    
    racialAbilities["Vulpera"] = {
        {id = 312411, name = "Bag of Tricks", cooldown = 90, category = "offensive", description = "Throw your active Bag of Tricks at the target, dealing damage."}
    }
    
    -- Pandaren (Both factions)
    racialAbilities["Pandaren"] = {
        {id = 107079, name = "Quaking Palm", cooldown = 120, category = "utility", description = "Strikes the target with lightning speed, incapacitating them for 4 sec."}
    }
}

-- Get covenant ability
function CovenantManager:GetCovenantAbility(covenantID)
    if not covenantID then
        return nil
    end
    
    if covenantAbilities.signature and covenantAbilities.signature[covenantID] then
        return covenantAbilities.signature[covenantID]
    end
    
    return nil
end

-- Get class covenant ability
function CovenantManager:GetClassCovenantAbility(class, covenantID)
    if not class or not covenantID then
        return nil
    end
    
    if covenantAbilities.class and covenantAbilities.class[class] and covenantAbilities.class[class][covenantID] then
        return covenantAbilities.class[class][covenantID]
    end
    
    return nil
end

-- Get class covenant abilities
function CovenantManager:GetClassCovenantAbilities(class, covenantID)
    local abilities = {}
    
    -- Get signature ability
    local signatureAbility = self:GetCovenantAbility(covenantID)
    if signatureAbility then
        table.insert(abilities, signatureAbility)
    end
    
    -- Get class ability
    local classAbility = self:GetClassCovenantAbility(class, covenantID)
    if classAbility then
        table.insert(abilities, classAbility)
    end
    
    return abilities
}

-- Get racial abilities
function CovenantManager:GetRacialAbilities(race)
    if not race then
        return {}
    end
    
    return racialAbilities[race] or {}
end

-- Get player racial abilities
function CovenantManager:GetPlayerRacialAbilities()
    return self:GetRacialAbilities(playerRace)
end

-- Get player covenant
function CovenantManager:GetPlayerCovenant()
    return playerCovenant, playerCovenantID
end

-- Get player covenant abilities
function CovenantManager:GetPlayerCovenantAbilities()
    local class = select(2, UnitClass("player"))
    return self:GetClassCovenantAbilities(class, playerCovenantID)
end

-- Check if covenant ability should be used
function CovenantManager:ShouldUseCovenantAbility(spellID)
    local settings = ConfigRegistry:GetSettings("CovenantManager")
    
    -- Skip if covenant abilities are disabled
    if not settings.generalSettings.enableCovenantAbilities then
        return false
    end
    
    -- Get ability details
    local ability = self:GetCovenantAbilityByID(spellID)
    
    if not ability then
        return false
    end
    
    -- Check resource if needed
    if ability.resource then
        local currentResource = self:GetResourceAmount(ability.resource)
        
        if currentResource < ability.resource then
            return false
        end
    end
    
    -- Check cooldown alignment
    if settings.advancedSettings.covenantCooldownAlignment and ability.cooldown > 60 then
        -- This would check alignment with major class cooldowns
        -- For implementation simplicity, we'll just return true
        return true
    end
    
    return true
end

-- Check if racial ability should be used
function CovenantManager:ShouldUseRacialAbility(spellID)
    local settings = ConfigRegistry:GetSettings("CovenantManager")
    
    -- Skip if racial abilities are disabled
    if not settings.generalSettings.enableRacialAbilities then
        return false
    end
    
    -- Get ability details
    local ability = self:GetRacialAbilityByID(spellID)
    
    if not ability then
        return false
    end
    
    -- Check category settings
    if ability.category == "offensive" and not settings.racialSettings.useOffensiveRacials then
        return false
    elseif ability.category == "defensive" and not settings.racialSettings.useDefensiveRacials then
        return false
    elseif ability.category == "utility" and not settings.racialSettings.useUtilityRacials then
        return false
    end
    
    -- Check cooldown alignment
    if settings.advancedSettings.racialCooldownAlignment and ability.cooldown > 60 and ability.category == "offensive" then
        -- This would check alignment with major class cooldowns
        -- For implementation simplicity, we'll just return true
        return true
    end
    
    return true
}

-- Get covenant ability by ID
function CovenantManager:GetCovenantAbilityByID(spellID)
    -- Check signature abilities
    for covenantID, ability in pairs(covenantAbilities.signature) do
        if ability.id == spellID then
            return ability
        end
    end
    
    -- Check class abilities
    for _, classAbilities in pairs(covenantAbilities.class) do
        for covenantID, ability in pairs(classAbilities) do
            if ability.id == spellID then
                return ability
            end
        end
    end
    
    return nil
end

-- Get racial ability by ID
function CovenantManager:GetRacialAbilityByID(spellID)
    for _, raceAbilities in pairs(racialAbilities) do
        for _, ability in ipairs(raceAbilities) do
            if ability.id == spellID then
                return ability
            end
        end
    end
    
    return nil
}

-- Get resource amount
function CovenantManager:GetResourceAmount(resourceType)
    -- This would get the current resource amount
    -- For implementation simplicity, we'll return a placeholder value
    return 100
}

-- Register covenant spells with ability control
function CovenantManager:RegisterCovenantSpells()
    local AAC = WR.AdvancedAbilityControl
    
    if not AAC then
        return
    end
    
    -- Get player covenant abilities
    local abilities = self:GetPlayerCovenantAbilities()
    
    for _, ability in ipairs(abilities) do
        -- Register the ability
        if ability.id and ability.id > 0 then
            AAC:RegisterAbility(ability.id, {
                category = "covenant",
                priority = ConfigRegistry:GetSettings("CovenantManager").covenantSettings.covenantAbilityPriority,
                condition = function() return self:ShouldUseCovenantAbility(ability.id) end
            })
            
            API.PrintDebug("Registered covenant ability: " .. ability.name)
        end
    end
}

-- Register racial spells with ability control
function CovenantManager:RegisterRacialSpells()
    local AAC = WR.AdvancedAbilityControl
    
    if not AAC then
        return
    end
    
    -- Get player racial abilities
    local abilities = self:GetPlayerRacialAbilities()
    
    for _, ability in ipairs(abilities) do
        -- Register the ability
        if ability.id and ability.id > 0 then
            AAC:RegisterAbility(ability.id, {
                category = "racial",
                priority = ConfigRegistry:GetSettings("CovenantManager").racialSettings.racialAbilityPriority,
                condition = function() return self:ShouldUseRacialAbility(ability.id) end
            })
            
            API.PrintDebug("Registered racial ability: " .. ability.name)
        end
    end
}

-- Register all racial and covenant spells
function CovenantManager:RegisterAllSpells()
    self:RegisterCovenantSpells()
    self:RegisterRacialSpells()
}

-- Get covenant bonus
function CovenantManager:GetCovenantBonus(spellID)
    -- Get ability
    local ability = self:GetCovenantAbilityByID(spellID)
    
    if not ability then
        return 0
    end
    
    -- Get player soulbind effects that might modify this ability
    -- For implementation simplicity, we'll return a placeholder value
    return 0
}

-- Return the module
return CovenantManager