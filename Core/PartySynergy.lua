local addonName, WR = ...

-- PartySynergy module for coordinating with other party/raid members
local PartySynergy = {}
WR.PartySynergy = PartySynergy

-- Local references for performance
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName
local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local GetTime = GetTime
local select = select
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tremove = table.remove
local format = string.format
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local band = bit.band
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid

-- Module constants
local PREFIX = "WINDRUNNER"
local COOLDOWN_THRESHOLD = 90 -- Only track cooldowns of this duration or longer
local SYNC_INTERVAL = 5 -- Update interval in seconds
local UPDATE_FREQUENCY = 0.5 -- UI update frequency
local TANK_SWAP_THRESHOLD = 4 -- Number of stacks that suggest a tank swap
local BURST_VARIANCE = 0.1 -- Allow 10% variance in burst window alignment
local MESSAGE_TYPES = {
    HELLO = "HELLO",
    COOLDOWN = "CD",
    BURST = "BURST",
    BUFF = "BUFF",
    DEBUFF = "DEBUFF",
    TANK = "TANK",
    HEAL = "HEAL",
    VERSION = "VER",
    CONFIG = "CFG"
}

-- Module state variables
local isActive = false
local partyMembers = {}
local cooldownRegistry = {}
local buffRegistry = {}
local debuffRegistry = {}
local pendingBurstWindows = {}
local activeTankSwaps = {}
local healingAssignments = {}
local lastSyncTime = 0
local lastUpdateTime = 0
local addonVersions = {}
local commsEnabled = true
local lastProcessedMessageTime = {}

-- Settings
local settings = {
    enableCoordinatedBurst = true,
    enableCooldownTracking = true,
    enableBuffMonitoring = true,
    enableDebuffMonitoring = true,
    enableTankSwaps = true,
    enableHealingAssignments = true,
    cooldownMinDuration = 60,
    burstCooldownThreshold = 120,
    notifyPartyMembers = true,
    autoRespondToRequests = true,
    hideOfflinePlayers = true,
    enableAutomaticAssistance = true,
    showPartyIcons = true,
    showPartyFrames = true,
    partyFrameScale = 1.0,
    partyFramePosition = {x = 0, y = 0},
    burstWindowDuration = 15,
    tankSwapStacks = 2,
    priority = {
        burst = 1,
        tankSwap = 2,
        healingAssignment = 3,
        buffGap = 4
    }
}

-- Class cooldowns to track (class-specific major cooldowns)
local classCooldowns = {
    WARRIOR = {
        71 = { -- Arms
            {spellId = 107574, name = "Avatar", duration = 20, cooldown = 90},
            {spellId = 227847, name = "Bladestorm", duration = 6, cooldown = 90},
            {spellId = 262161, name = "Warbreaker", duration = 10, cooldown = 45}
        },
        72 = { -- Fury
            {spellId = 1719, name = "Recklessness", duration = 12, cooldown = 90},
            {spellId = 184364, name = "Enraged Regeneration", duration = 8, cooldown = 120}
        },
        73 = { -- Protection
            {spellId = 871, name = "Shield Wall", duration = 8, cooldown = 210},
            {spellId = 12975, name = "Last Stand", duration = 15, cooldown = 180},
            {spellId = 107574, name = "Avatar", duration = 20, cooldown = 90}
        }
    },
    PALADIN = {
        65 = { -- Holy
            {spellId = 31884, name = "Avenging Wrath", duration = 20, cooldown = 120},
            {spellId = 105809, name = "Holy Avenger", duration = 20, cooldown = 180},
            {spellId = 216331, name = "Avenging Crusader", duration = 12, cooldown = 60}
        },
        66 = { -- Protection
            {spellId = 31884, name = "Avenging Wrath", duration = 20, cooldown = 120},
            {spellId = 86659, name = "Guardian of Ancient Kings", duration = 8, cooldown = 300},
            {spellId = 204150, name = "Aegis of Light", duration = 6, cooldown = 180}
        },
        70 = { -- Retribution
            {spellId = 31884, name = "Avenging Wrath", duration = 20, cooldown = 120},
            {spellId = 231895, name = "Crusade", duration = 25, cooldown = 120},
            {spellId = 205191, name = "Eye for an Eye", duration = 10, cooldown = 60}
        }
    },
    HUNTER = {
        253 = { -- Beast Mastery
            {spellId = 193530, name = "Aspect of the Wild", duration = 20, cooldown = 120},
            {spellId = 19574, name = "Bestial Wrath", duration = 15, cooldown = 90},
            {spellId = 201430, name = "Stampede", duration = 12, cooldown = 180}
        },
        254 = { -- Marksmanship
            {spellId = 288613, name = "Trueshot", duration = 15, cooldown = 120},
            {spellId = 199483, name = "Camouflage", duration = 60, cooldown = 60},
            {spellId = 281195, name = "Survival of the Fittest", duration = 20, cooldown = 180}
        },
        255 = { -- Survival
            {spellId = 266779, name = "Coordinated Assault", duration = 20, cooldown = 120},
            {spellId = 187650, name = "Freezing Trap", duration = 30, cooldown = 30},
            {spellId = 186289, name = "Aspect of the Eagle", duration = 15, cooldown = 90}
        }
    },
    ROGUE = {
        259 = { -- Assassination
            {spellId = 79140, name = "Vendetta", duration = 20, cooldown = 120},
            {spellId = 1856, name = "Vanish", duration = 3, cooldown = 120},
            {spellId = 5277, name = "Evasion", duration = 10, cooldown = 120}
        },
        260 = { -- Outlaw
            {spellId = 13750, name = "Adrenaline Rush", duration = 20, cooldown = 180},
            {spellId = 51690, name = "Killing Spree", duration = 7, cooldown = 120},
            {spellId = 343142, name = "Dreadblades", duration = 10, cooldown = 90}
        },
        261 = { -- Subtlety
            {spellId = 121471, name = "Shadow Blades", duration = 20, cooldown = 180},
            {spellId = 31224, name = "Cloak of Shadows", duration = 5, cooldown = 120},
            {spellId = 185313, name = "Shadow Dance", duration = 8, cooldown = 60}
        }
    },
    PRIEST = {
        256 = { -- Discipline
            {spellId = 47536, name = "Rapture", duration = 8, cooldown = 90},
            {spellId = 62618, name = "Power Word: Barrier", duration = 10, cooldown = 180},
            {spellId = 109964, name = "Spirit Shell", duration = 10, cooldown = 60}
        },
        257 = { -- Holy
            {spellId = 64843, name = "Divine Hymn", duration = 8, cooldown = 180},
            {spellId = 265202, name = "Holy Word: Salvation", duration = 12, cooldown = 720},
            {spellId = 47788, name = "Guardian Spirit", duration = 10, cooldown = 180}
        },
        258 = { -- Shadow
            {spellId = 194249, name = "Voidform", duration = 15, cooldown = 90},
            {spellId = 228260, name = "Void Eruption", duration = 0, cooldown = 90},
            {spellId = 47585, name = "Dispersion", duration = 6, cooldown = 120}
        }
    },
    SHAMAN = {
        262 = { -- Elemental
            {spellId = 198067, name = "Fire Elemental", duration = 30, cooldown = 150},
            {spellId = 191634, name = "Stormkeeper", duration = 15, cooldown = 60},
            {spellId = 114050, name = "Ascendance", duration = 15, cooldown = 180}
        },
        263 = { -- Enhancement
            {spellId = 51533, name = "Feral Spirit", duration = 15, cooldown = 120},
            {spellId = 114051, name = "Ascendance", duration = 15, cooldown = 180},
            {spellId = 197214, name = "Sundering", duration = 0, cooldown = 40}
        },
        264 = { -- Restoration
            {spellId = 108280, name = "Healing Tide Totem", duration = 10, cooldown = 180},
            {spellId = 114052, name = "Ascendance", duration = 15, cooldown = 180},
            {spellId = 198838, name = "Earthen Wall Totem", duration = 15, cooldown = 60}
        }
    },
    MAGE = {
        62 = { -- Arcane
            {spellId = 12042, name = "Arcane Power", duration = 10, cooldown = 90},
            {spellId = 110960, name = "Greater Invisibility", duration = 20, cooldown = 120},
            {spellId = 55342, name = "Mirror Image", duration = 40, cooldown = 120}
        },
        63 = { -- Fire
            {spellId = 190319, name = "Combustion", duration = 10, cooldown = 120},
            {spellId = 55342, name = "Mirror Image", duration = 40, cooldown = 120},
            {spellId = 153561, name = "Meteor", duration = 0, cooldown = 45}
        },
        64 = { -- Frost
            {spellId = 12472, name = "Icy Veins", duration = 20, cooldown = 180},
            {spellId = 55342, name = "Mirror Image", duration = 40, cooldown = 120},
            {spellId = 257537, name = "Ebonbolt", duration = 0, cooldown = 45}
        }
    },
    WARLOCK = {
        265 = { -- Affliction
            {spellId = 205180, name = "Summon Darkglare", duration = 20, cooldown = 180},
            {spellId = 113860, name = "Dark Soul: Misery", duration = 20, cooldown = 120},
            {spellId = 108416, name = "Dark Pact", duration = 20, cooldown = 60}
        },
        266 = { -- Demonology
            {spellId = 265187, name = "Summon Demonic Tyrant", duration = 15, cooldown = 90},
            {spellId = 267171, name = "Demonic Strength", duration = 0, cooldown = 60},
            {spellId = 267217, name = "Nether Portal", duration = 20, cooldown = 180}
        },
        267 = { -- Destruction
            {spellId = 1122, name = "Summon Infernal", duration = 30, cooldown = 180},
            {spellId = 113858, name = "Dark Soul: Instability", duration = 20, cooldown = 120},
            {spellId = 5484, name = "Howl of Terror", duration = 0, cooldown = 40}
        }
    },
    MONK = {
        268 = { -- Brewmaster
            {spellId = 115203, name = "Fortifying Brew", duration = 15, cooldown = 420},
            {spellId = 115176, name = "Zen Meditation", duration = 8, cooldown = 300},
            {spellId = 132578, name = "Invoke Niuzao, the Black Ox", duration = 25, cooldown = 180}
        },
        269 = { -- Windwalker
            {spellId = 137639, name = "Storm, Earth, and Fire", duration = 15, cooldown = 90},
            {spellId = 123904, name = "Invoke Xuen, the White Tiger", duration = 24, cooldown = 120},
            {spellId = 152173, name = "Serenity", duration = 12, cooldown = 90}
        },
        270 = { -- Mistweaver
            {spellId = 115310, name = "Revival", duration = 0, cooldown = 180},
            {spellId = 322118, name = "Invoke Yu'lon, the Jade Serpent", duration = 25, cooldown = 180},
            {spellId = 198664, name = "Invoke Chi-Ji, the Red Crane", duration = 25, cooldown = 180}
        }
    },
    DRUID = {
        102 = { -- Balance
            {spellId = 194223, name = "Celestial Alignment", duration = 20, cooldown = 180},
            {spellId = 202770, name = "Fury of Elune", duration = 8, cooldown = 60},
            {spellId = 205636, name = "Force of Nature", duration = 10, cooldown = 60}
        },
        103 = { -- Feral
            {spellId = 106951, name = "Berserk", duration = 20, cooldown = 180},
            {spellId = 5217, name = "Tiger's Fury", duration = 10, cooldown = 30},
            {spellId = 319454, name = "Heart of the Wild", duration = 45, cooldown = 300}
        },
        104 = { -- Guardian
            {spellId = 61336, name = "Survival Instincts", duration = 6, cooldown = 180},
            {spellId = 22842, name = "Frenzied Regeneration", duration = 3, cooldown = 36},
            {spellId = 50334, name = "Berserk", duration = 15, cooldown = 180}
        },
        105 = { -- Restoration
            {spellId = 33891, name = "Incarnation: Tree of Life", duration = 30, cooldown = 180},
            {spellId = 740, name = "Tranquility", duration = 8, cooldown = 180},
            {spellId = 197721, name = "Flourish", duration = 8, cooldown = 90}
        }
    },
    DEMONHUNTER = {
        577 = { -- Havoc
            {spellId = 191427, name = "Metamorphosis", duration = 30, cooldown = 240},
            {spellId = 198589, name = "Blur", duration = 10, cooldown = 60},
            {spellId = 196718, name = "Darkness", duration = 8, cooldown = 300}
        },
        581 = { -- Vengeance
            {spellId = 187827, name = "Metamorphosis", duration = 15, cooldown = 180},
            {spellId = 204021, name = "Fiery Brand", duration = 10, cooldown = 60},
            {spellId = 263648, name = "Soul Barrier", duration = 12, cooldown = 30}
        }
    },
    DEATHKNIGHT = {
        250 = { -- Blood
            {spellId = 49028, name = "Dancing Rune Weapon", duration = 8, cooldown = 120},
            {spellId = 55233, name = "Vampiric Blood", duration = 10, cooldown = 90},
            {spellId = 48743, name = "Death Pact", duration = 15, cooldown = 120}
        },
        251 = { -- Frost
            {spellId = 47568, name = "Empower Rune Weapon", duration = 20, cooldown = 120},
            {spellId = 51271, name = "Pillar of Frost", duration = 12, cooldown = 60},
            {spellId = 207289, name = "Unholy Frenzy", duration = 12, cooldown = 75}
        },
        252 = { -- Unholy
            {spellId = 42650, name = "Army of the Dead", duration = 30, cooldown = 480},
            {spellId = 275699, name = "Apocalypse", duration = 0, cooldown = 90},
            {spellId = 63560, name = "Dark Transformation", duration = 15, cooldown = 60}
        }
    },
    EVOKER = {
        1467 = { -- Devastation
            {spellId = 375087, name = "Dragonrage", duration = 14, cooldown = 120},
            {spellId = 359073, name = "Eternity Surge", duration = 0, cooldown = 30},
            {spellId = 357210, name = "Deep Breath", duration = 0, cooldown = 120}
        },
        1468 = { -- Preservation
            {spellId = 363534, name = "Rewind", duration = 0, cooldown = 240},
            {spellId = 370960, name = "Emerald Communion", duration = 5, cooldown = 180},
            {spellId = 359816, name = "Dream Flight", duration = 0, cooldown = 120}
        },
        1473 = { -- Augmentation
            {spellId = 404977, name = "Spatial Paradox", duration = 0, cooldown = 180},
            {spellId = 403631, name = "Breath of Eons", duration = 10, cooldown = 120},
            {spellId = 374227, name = "Zephyr", duration = 0, cooldown = 120}
        }
    }
}

-- Important buffs to track for gaps
local importantBuffs = {
    -- Battle Shout (Warrior)
    {spellId = 6673, name = "Battle Shout", class = "WARRIOR", duration = 3600, type = "physical"},
    -- Power Word: Fortitude (Priest)
    {spellId = 21562, name = "Power Word: Fortitude", class = "PRIEST", duration = 3600, type = "stamina"},
    -- Arcane Intellect (Mage)
    {spellId = 1459, name = "Arcane Intellect", class = "MAGE", duration = 3600, type = "intellect"},
    -- Blessing of Might (Paladin)
    {spellId = 19740, name = "Blessing of Might", class = "PALADIN", duration = 3600, type = "attack_power"},
    -- Mark of the Wild (Druid)
    {spellId = 1126, name = "Mark of the Wild", class = "DRUID", duration = 3600, type = "stats"},
    -- Demon's Intellect (Warlock)
    {spellId = 285933, name = "Demon's Intellect", class = "WARLOCK", duration = 3600, type = "intellect"},
    -- Mystic Touch (Monk)
    {spellId = 113746, name = "Mystic Touch", class = "MONK", duration = 60, type = "debuff"},
    -- Chaos Brand (Demon Hunter)
    {spellId = 1490, name = "Chaos Brand", class = "DEMONHUNTER", duration = 60, type = "debuff"},
    -- Ebon Might (Evoker)
    {spellId = 395152, name = "Ebon Might", class = "EVOKER", duration = 10, type = "stats"}
}

-- Important raid debuffs to track
local raidDebuffs = {
    -- Weakness (Tank Swap mechanic)
    {spellId = 160065, name = "Weakness", stackLimit = 3, priority = "high", requiredAction = "TANK_SWAP"},
    -- Fixated (Tank mechanic)
    {spellId = 249016, name = "Fixated", stackLimit = 1, priority = "high", requiredAction = "KITE"},
    -- Bleeding (Healer mechanic)
    {spellId = 240211, name = "Bleeding", stackLimit = 0, priority = "medium", requiredAction = "HEAL"},
    -- Burning (Healer/DPS mechanic)
    {spellId = 226512, name = "Burning", stackLimit = 0, priority = "medium", requiredAction = "DISPEL"},
    -- Poisoned (Healer mechanic)
    {spellId = 241613, name = "Poisoned", stackLimit = 0, priority = "low", requiredAction = "HEAL"}
}

-- Role-specific cooldowns
local roleCooldowns = {
    TANK = {
        {spellId = 61336, name = "Survival Instincts", class = "DRUID", duration = 6, cooldown = 180},
        {spellId = 115203, name = "Fortifying Brew", class = "MONK", duration = 15, cooldown = 420},
        {spellId = 86659, name = "Guardian of Ancient Kings", class = "PALADIN", duration = 8, cooldown = 300},
        {spellId = 871, name = "Shield Wall", class = "WARRIOR", duration = 8, cooldown = 210},
        {spellId = 49028, name = "Dancing Rune Weapon", class = "DEATHKNIGHT", duration = 8, cooldown = 120},
        {spellId = 187827, name = "Metamorphosis", class = "DEMONHUNTER", duration = 15, cooldown = 180}
    },
    HEALER = {
        {spellId = 740, name = "Tranquility", class = "DRUID", duration = 8, cooldown = 180},
        {spellId = 115310, name = "Revival", class = "MONK", duration = 0, cooldown = 180},
        {spellId = 31884, name = "Avenging Wrath", class = "PALADIN", duration = 20, cooldown = 120},
        {spellId = 64843, name = "Divine Hymn", class = "PRIEST", duration = 8, cooldown = 180},
        {spellId = 108280, name = "Healing Tide Totem", class = "SHAMAN", duration = 10, cooldown = 180},
        {spellId = 363534, name = "Rewind", class = "EVOKER", duration = 0, cooldown = 240}
    },
    DPS = {
        -- Raid-wide defensive cooldowns from DPS
        {spellId = 51052, name = "Anti-Magic Zone", class = "DEATHKNIGHT", duration = 10, cooldown = 120},
        {spellId = 196718, name = "Darkness", class = "DEMONHUNTER", duration = 8, cooldown = 300},
        {spellId = 97462, name = "Rallying Cry", class = "WARRIOR", duration = 10, cooldown = 180},
        {spellId = 98008, name = "Spirit Link Totem", class = "SHAMAN", duration = 6, cooldown = 180},
        {spellId = 62618, name = "Power Word: Barrier", class = "PRIEST", duration = 10, cooldown = 180},
        {spellId = 31821, name = "Aura Mastery", class = "PALADIN", duration = 8, cooldown = 180}
    }
}

-- Initialize the module
function PartySynergy:Initialize()
    -- Create our communication channel
    RegisterAddonMessagePrefix(PREFIX)
    
    -- Load settings
    self:LoadSettings()
    
    -- Create UI elements
    self:CreateUI()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register with main addon
    self:RegisterWithAddon()
    
    -- Scan for active party/raid members
    self:ScanGroup()
    
    -- Initialize cooldown tracking
    self:InitializeCooldownTracking()
    
    WR:Debug("PartySynergy module initialized")
end

-- Load settings
function PartySynergy:LoadSettings()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.PartySynergy then
        for k, v in pairs(WindrunnerRotationsDB.PartySynergy) do
            if settings[k] ~= nil then
                settings[k] = v
            end
        end
    end
end

-- Save settings
function PartySynergy:SaveSettings()
    -- Initialize DB if needed
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.PartySynergy = settings
end

-- Apply settings
function PartySynergy:ApplySettings(newSettings)
    if not newSettings then return end
    
    for k, v in pairs(newSettings) do
        if settings[k] ~= nil then
            settings[k] = v
        end
    end
    
    -- Update UI based on new settings
    if self.frame then
        self:UpdateFrameVisibility()
    end
    
    -- Save changes
    self:SaveSettings()
end

-- Create UI elements
function PartySynergy:CreateUI()
    -- Main frame
    local frame = CreateFrame("Frame", "WRPartySynergyFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 180)
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.partyFramePosition.x, settings.partyFramePosition.y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) 
        if not self.isLocked then
            self:StartMoving() 
        end
    end)
    frame:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing() 
        -- Save position
        local x, y = self:GetCenter()
        local scale = UIParent:GetScale()
        settings.partyFramePosition.x = (x * scale) - (UIParent:GetWidth() * scale / 2)
        settings.partyFramePosition.y = (y * scale) - (UIParent:GetHeight() * scale / 2)
        PartySynergy:SaveSettings()
    end)
    frame:SetClampedToScreen(true)
    frame.isLocked = true
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Party Synergy")
    
    -- Party member frames container
    local memberContainer = CreateFrame("Frame", nil, frame)
    memberContainer:SetSize(280, 120)
    memberContainer:SetPoint("TOP", title, "BOTTOM", 0, -10)
    
    -- Member frames
    local memberFrames = {}
    for i = 1, 5 do
        local mFrame = CreateFrame("Frame", nil, memberContainer, "BackdropTemplate")
        mFrame:SetSize(50, 100)
        mFrame:SetPoint("LEFT", memberContainer, "LEFT", (i-1) * 55 + 5, 0)
        mFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        mFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        
        -- Class icon
        local classIcon = mFrame:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(24, 24)
        classIcon:SetPoint("TOP", mFrame, "TOP", 0, -5)
        classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        
        -- Name
        local name = mFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("TOP", classIcon, "BOTTOM", 0, -2)
        name:SetText("Empty")
        
        -- Role icon
        local roleIcon = mFrame:CreateTexture(nil, "ARTWORK")
        roleIcon:SetSize(16, 16)
        roleIcon:SetPoint("TOPRIGHT", mFrame, "TOPRIGHT", -5, -5)
        roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        roleIcon:SetTexCoord(GetTexCoordsForRole("DAMAGER"))
        
        -- Cooldown bars container
        local cooldownContainer = CreateFrame("Frame", nil, mFrame)
        cooldownContainer:SetSize(40, 50)
        cooldownContainer:SetPoint("TOP", name, "BOTTOM", 0, -5)
        
        -- Cooldown bars (3 max)
        local cooldownBars = {}
        for j = 1, 3 do
            local cdBar = CreateFrame("StatusBar", nil, cooldownContainer)
            cdBar:SetSize(40, 8)
            cdBar:SetPoint("TOP", cooldownContainer, "TOP", 0, -(j-1) * 10)
            cdBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            cdBar:SetStatusBarColor(0.7, 0.7, 0.7)
            cdBar:SetMinMaxValues(0, 1)
            cdBar:SetValue(0)
            
            -- Cooldown icon
            local cdIcon = cdBar:CreateTexture(nil, "OVERLAY")
            cdIcon:SetSize(8, 8)
            cdIcon:SetPoint("LEFT", cdBar, "LEFT", 0, 0)
            cdIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            
            -- Cooldown text
            local cdText = cdBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cdText:SetPoint("RIGHT", cdBar, "RIGHT", -2, 0)
            cdText:SetText("")
            
            cdBar.icon = cdIcon
            cdBar.text = cdText
            cdBar:Hide()
            
            cooldownBars[j] = cdBar
        end
        
        -- Status text
        local status = mFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("BOTTOM", mFrame, "BOTTOM", 0, 5)
        status:SetText("")
        
        -- Store references
        mFrame.classIcon = classIcon
        mFrame.name = name
        mFrame.roleIcon = roleIcon
        mFrame.cooldownBars = cooldownBars
        mFrame.status = status
        mFrame.memberId = nil
        mFrame:Hide()
        
        memberFrames[i] = mFrame
    end
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function() 
        frame:Hide() 
    end)
    
    -- Lock button
    local lockButton = CreateFrame("Button", nil, frame)
    lockButton:SetSize(16, 16)
    lockButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -4)
    lockButton:SetNormalTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up")
    lockButton:SetPushedTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Down" or "Interface\\Buttons\\LockButton-Unlocked-Down")
    lockButton:SetScript("OnClick", function(self)
        frame.isLocked = not frame.isLocked
        self:SetNormalTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up")
        self:SetPushedTexture(frame.isLocked and "Interface\\Buttons\\LockButton-Locked-Down" or "Interface\\Buttons\\LockButton-Unlocked-Down")
    end)
    
    -- Store frame references
    self.frame = frame
    self.memberFrames = memberFrames
    
    -- Initially hide the frame until needed
    frame:Hide()
end

-- Register events
function PartySynergy:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "GROUP_ROSTER_UPDATE" then
            PartySynergy:ScanGroup()
        elseif event == "PLAYER_ENTERING_WORLD" then
            PartySynergy:ScanGroup()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            PartySynergy:HandleSpellCast(unit, spellId)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            PartySynergy:ProcessCombatLog(CombatLogGetCurrentEventInfo())
        elseif event == "CHAT_MSG_ADDON" then
            local prefix, message, channel, sender = ...
            if prefix == PREFIX then
                PartySynergy:ProcessAddonMessage(message, sender)
            end
        end
    end)
    
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        PartySynergy:OnUpdate(elapsed)
    end)
    
    self.eventFrame = eventFrame
end

-- Scan for group members
function PartySynergy:ScanGroup()
    -- Clear current member list
    partyMembers = {}
    
    -- Always add player
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    local playerRole = UnitGroupRolesAssigned("player")
    local playerSpec = GetSpecialization()
    local playerSpecId = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    partyMembers[playerName] = {
        name = playerName,
        class = playerClass,
        role = playerRole,
        specId = playerSpecId,
        unit = "player",
        cooldowns = {},
        buffs = {},
        debuffs = {},
        isPlayer = true,
        isOnline = true,
        lastUpdate = GetTime()
    }
    
    -- Check if in a group
    if IsInGroup() then
        local groupSize = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        local unitPrefix = IsInRaid() and "raid" or "party"
        
        for i = 1, groupSize do
            local unit = unitPrefix .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                local role = UnitGroupRolesAssigned(unit)
                local isOnline = not UnitIsConnected(unit)
                
                if name then
                    partyMembers[name] = {
                        name = name,
                        class = class,
                        role = role,
                        unit = unit,
                        cooldowns = {},
                        buffs = {},
                        debuffs = {},
                        isPlayer = false,
                        isOnline = isOnline,
                        lastUpdate = GetTime()
                    }
                end
            end
        end
    end
    
    -- Send hello message to group
    self:SendHello()
    
    -- Update UI
    self:UpdateMemberFrames()
end

-- Initialize cooldown tracking
function PartySynergy:InitializeCooldownTracking()
    -- Reset registry
    cooldownRegistry = {}
    
    -- Get player class and spec
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecId = playerSpec and GetSpecializationInfo(playerSpec) or nil
    
    -- Register class cooldowns
    if playerClass and playerSpecId and classCooldowns[playerClass] and classCooldowns[playerClass][playerSpecId] then
        local cooldowns = classCooldowns[playerClass][playerSpecId]
        for _, cd in ipairs(cooldowns) do
            if cd.cooldown >= settings.cooldownMinDuration then
                cooldownRegistry[cd.spellId] = {
                    id = cd.spellId,
                    name = cd.name,
                    duration = cd.duration,
                    cooldown = cd.cooldown,
                    lastUsed = 0,
                    isAvailable = true,
                    endTime = 0,
                    isBurstCooldown = cd.cooldown >= settings.burstCooldownThreshold
                }
            end
        end
    end
    
    -- Register role cooldowns
    local playerRole = UnitGroupRolesAssigned("player")
    if playerRole and roleCooldowns[playerRole] then
        for _, cd in ipairs(roleCooldowns[playerRole]) do
            if cd.class == playerClass and cd.cooldown >= settings.cooldownMinDuration then
                cooldownRegistry[cd.spellId] = {
                    id = cd.spellId,
                    name = cd.name,
                    duration = cd.duration,
                    cooldown = cd.cooldown,
                    lastUsed = 0,
                    isAvailable = true,
                    endTime = 0,
                    isBurstCooldown = cd.cooldown >= settings.burstCooldownThreshold
                }
            end
        end
    end
end

-- Update member frames in UI
function PartySynergy:UpdateMemberFrames()
    if not self.frame or not self.memberFrames then return end
    
    -- Count active members
    local activeMemberCount = 0
    local membersByRole = {
        TANK = {},
        HEALER = {},
        DAMAGER = {},
        NONE = {}
    }
    
    -- Sort members by role
    for name, member in pairs(partyMembers) do
        if not settings.hideOfflinePlayers or member.isOnline then
            local role = member.role or "NONE"
            table.insert(membersByRole[role], member)
            activeMemberCount = activeMemberCount + 1
        end
    end
    
    -- Order: Tanks, Healers, DPS, None
    local orderedMembers = {}
    for _, member in ipairs(membersByRole["TANK"]) do
        table.insert(orderedMembers, member)
    end
    for _, member in ipairs(membersByRole["HEALER"]) do
        table.insert(orderedMembers, member)
    end
    for _, member in ipairs(membersByRole["DAMAGER"]) do
        table.insert(orderedMembers, member)
    end
    for _, member in ipairs(membersByRole["NONE"]) do
        table.insert(orderedMembers, member)
    end
    
    -- Update frames (maximum 5 frames)
    local maxFrames = math.min(5, #orderedMembers)
    for i = 1, maxFrames do
        local frame = self.memberFrames[i]
        local member = orderedMembers[i]
        
        if member then
            -- Set member info
            frame.memberId = member.name
            frame.name:SetText(member.name)
            
            -- Set class icon
            local classIcon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
            local iconCoords = CLASS_ICON_TCOORDS[member.class]
            if iconCoords then
                frame.classIcon:SetTexture(classIcon)
                frame.classIcon:SetTexCoord(unpack(iconCoords))
                
                -- Color name by class
                local classColor = RAID_CLASS_COLORS[member.class]
                if classColor then
                    frame.name:SetTextColor(classColor.r, classColor.g, classColor.b)
                end
            else
                frame.classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                frame.name:SetTextColor(1, 1, 1)
            end
            
            -- Set role icon
            local role = member.role or "NONE"
            frame.roleIcon:SetTexCoord(GetTexCoordsForRole(role))
            
            -- Update cooldown bars
            local cooldownCount = 0
            if member.cooldowns then
                for spellId, cooldown in pairs(member.cooldowns) do
                    cooldownCount = cooldownCount + 1
                    if cooldownCount <= 3 then
                        local bar = frame.cooldownBars[cooldownCount]
                        
                        -- Set cooldown icon
                        local _, _, icon = GetSpellInfo(spellId)
                        bar.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                        
                        -- Calculate remaining time
                        local currentTime = GetTime()
                        local endTime = cooldown.endTime or 0
                        local remaining = math.max(0, endTime - currentTime)
                        local total = cooldown.cooldown or 60
                        
                        if remaining > 0 then
                            bar:SetMinMaxValues(0, total)
                            bar:SetValue(total - remaining)
                            bar.text:SetText(math_floor(remaining))
                            
                            -- Color based on remaining time
                            local r, g, b = 1, 0.1, 0.1 -- Red
                            if remaining / total > 0.5 then
                                r, g, b = 0.1, 1, 0.1 -- Green
                            elseif remaining / total > 0.25 then
                                r, g, b = 1, 1, 0.1 -- Yellow
                            end
                            bar:SetStatusBarColor(r, g, b)
                        else
                            bar:SetValue(total)
                            bar.text:SetText("Ready")
                            bar:SetStatusBarColor(0.1, 1, 0.1) -- Green
                        end
                        
                        bar:Show()
                    end
                end
            end
            
            -- Hide unused cooldown bars
            for i = cooldownCount + 1, 3 do
                frame.cooldownBars[i]:Hide()
            end
            
            -- Update status text
            local status = ""
            if not member.isOnline then
                status = "|cFFFF0000Offline|r"
            elseif member.hasBurstReady then
                status = "|cFF00FF00Burst Ready|r"
            elseif member.needsBuff then
                status = "|cFFFFFF00Needs Buff|r"
            elseif member.needsTankSwap then
                status = "|cFFFF0000Swap!|r"
            elseif member.needsHealing then
                status = "|cFFFF9900Low Health|r"
            end
            frame.status:SetText(status)
            
            frame:Show()
        else
            frame:Hide()
        end
    end
    
    -- Hide unused frames
    for i = maxFrames + 1, 5 do
        self.memberFrames[i]:Hide()
    end
    
    -- Resize frame based on active members
    local height = 180
    if maxFrames <= 2 then
        height = 120
    end
    self.frame:SetHeight(height)
end

-- Update frame visibility
function PartySynergy:UpdateFrameVisibility()
    if not self.frame then return end
    
    if settings.showPartyFrames and IsInGroup() then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

-- Process spell cast
function PartySynergy:HandleSpellCast(unit, spellId)
    if not unit or not spellId then return end
    
    -- Check if this is a tracked cooldown
    if cooldownRegistry[spellId] then
        local cd = cooldownRegistry[spellId]
        local currentTime = GetTime()
        
        -- Update cooldown info
        cd.lastUsed = currentTime
        cd.isAvailable = false
        cd.endTime = currentTime + cd.cooldown
        
        -- Broadcast cooldown usage if in group
        if IsInGroup() and settings.notifyPartyMembers then
            self:SendCooldownUsage(spellId)
        end
        
        -- If this is a burst cooldown, update burst window
        if cd.isBurstCooldown then
            self:UpdateBurstWindow(spellId)
        end
    end
    
    -- Check if this is a buff spell
    for _, buff in ipairs(importantBuffs) do
        if buff.spellId == spellId then
            -- Update buff registry
            local unitName = UnitName(unit)
            if unitName then
                -- Apply buff to all party members for raid-wide buffs
                if buff.duration > 60 then -- Long duration = raid-wide
                    for name, member in pairs(partyMembers) do
                        if not member.buffs then member.buffs = {} end
                        member.buffs[buff.type] = {
                            id = buff.spellId,
                            name = buff.name,
                            endTime = GetTime() + buff.duration,
                            source = unitName
                        }
                    end
                end
                
                -- Broadcast buff application if in group
                if IsInGroup() and settings.notifyPartyMembers then
                    self:SendBuffApplication(spellId)
                end
            end
            break
        end
    end
end

-- Process combat log events
function PartySynergy:ProcessCombatLog(...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId = ...
    
    -- Only process events from or to party members
    local isSourcePartyMember = bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID) > 0
    local isDestPartyMember = bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID) > 0
    
    -- Handle different event types
    if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REFRESH" then
        -- Check for important debuffs (for tank swap mechanics)
        for _, debuff in ipairs(raidDebuffs) do
            if spellId == debuff.spellId and isDestPartyMember then
                local auraType = select(15, ...) -- Buff vs Debuff
                local stacks = 1
                if event == "SPELL_AURA_APPLIED_DOSE" then
                    stacks = select(16, ...) -- Get stacks
                end
                
                -- Update debuff tracking
                if partyMembers[destName] then
                    if not partyMembers[destName].debuffs then
                        partyMembers[destName].debuffs = {}
                    end
                    
                    partyMembers[destName].debuffs[debuff.spellId] = {
                        id = debuff.spellId,
                        name = debuff.name,
                        stacks = stacks,
                        timestamp = GetTime(),
                        requiredAction = debuff.requiredAction
                    }
                    
                    -- Check for tank swap if tank has high stacks
                    if partyMembers[destName].role == "TANK" and debuff.requiredAction == "TANK_SWAP" and stacks >= settings.tankSwapStacks then
                        self:SuggestTankSwap(destName, debuff.spellId)
                    end
                end
                
                break
            end
        end
    elseif event == "SPELL_AURA_REMOVED" then
        -- Remove debuff tracking
        for _, debuff in ipairs(raidDebuffs) do
            if spellId == debuff.spellId and isDestPartyMember then
                if partyMembers[destName] and partyMembers[destName].debuffs then
                    partyMembers[destName].debuffs[debuff.spellId] = nil
                end
                break
            end
        end
    elseif event == "SPELL_CAST_SUCCESS" then
        -- Track cooldown usage
        if isSourcePartyMember and not UnitIsUnit(sourceName, "player") then
            -- Check for tracked cooldowns from other party members
            for _, classTable in pairs(classCooldowns) do
                for _, specTable in pairs(classTable) do
                    for _, cd in ipairs(specTable) do
                        if cd.spellId == spellId then
                            if partyMembers[sourceName] then
                                if not partyMembers[sourceName].cooldowns then
                                    partyMembers[sourceName].cooldowns = {}
                                end
                                
                                partyMembers[sourceName].cooldowns[spellId] = {
                                    id = spellId,
                                    name = cd.name,
                                    duration = cd.duration,
                                    cooldown = cd.cooldown,
                                    lastUsed = GetTime(),
                                    endTime = GetTime() + cd.cooldown,
                                    isBurstCooldown = cd.cooldown >= settings.burstCooldownThreshold
                                }
                                
                                -- If this is a burst cooldown, check for burst window coordination
                                if cd.cooldown >= settings.burstCooldownThreshold then
                                    self:CheckBurstCoordination(sourceName, spellId)
                                end
                            end
                            break
                        end
                    end
                end
            end
            
            -- Check for role cooldowns
            for _, roleTable in pairs(roleCooldowns) do
                for _, cd in ipairs(roleTable) do
                    if cd.spellId == spellId then
                        if partyMembers[sourceName] then
                            if not partyMembers[sourceName].cooldowns then
                                partyMembers[sourceName].cooldowns = {}
                            end
                            
                            partyMembers[sourceName].cooldowns[spellId] = {
                                id = spellId,
                                name = cd.name,
                                duration = cd.duration,
                                cooldown = cd.cooldown,
                                lastUsed = GetTime(),
                                endTime = GetTime() + cd.cooldown
                            }
                        end
                        break
                    end
                end
            end
        end
    elseif event == "UNIT_DIED" then
        -- Clear debuffs for dead unit
        if isDestPartyMember and partyMembers[destName] then
            partyMembers[destName].debuffs = {}
        end
    end
end

-- Update burst window
function PartySynergy:UpdateBurstWindow(spellId)
    if not spellId then return end
    
    local playerName = UnitName("player")
    local currentTime = GetTime()
    
    -- Create a new burst window
    local burstWindow = {
        initiator = playerName,
        startTime = currentTime,
        endTime = currentTime + settings.burstWindowDuration,
        spellId = spellId,
        participants = {
            [playerName] = true
        }
    }
    
    -- Add to pending burst windows
    table.insert(pendingBurstWindows, burstWindow)
    
    -- Broadcast burst window to party
    if IsInGroup() and settings.notifyPartyMembers then
        self:SendBurstWindow(burstWindow)
    end
    
    -- Update UI
    partyMembers[playerName].hasBurstReady = false
    self:UpdateMemberFrames()
end

-- Check for burst coordination
function PartySynergy:CheckBurstCoordination(sourceName, spellId)
    if not settings.enableCoordinatedBurst then return end
    
    local currentTime = GetTime()
    
    -- Check if there's an active burst window
    for i, window in ipairs(pendingBurstWindows) do
        if currentTime <= window.endTime then
            -- This player used a burst ability during an active window
            window.participants[sourceName] = true
            
            -- Update UI
            if partyMembers[sourceName] then
                partyMembers[sourceName].hasBurstReady = false
            end
            self:UpdateMemberFrames()
            
            -- If we're the initiator, broadcast the updated participants
            if window.initiator == UnitName("player") and IsInGroup() and settings.notifyPartyMembers then
                self:SendBurstWindow(window)
            end
            
            return
        end
    end
    
    -- No active window, check if we should align with this player
    if settings.enableCoordinatedBurst and sourceName ~= UnitName("player") then
        local playerName = UnitName("player")
        
        -- Check if we have a ready burst cooldown
        local readyBurstCooldown = nil
        for id, cd in pairs(cooldownRegistry) do
            if cd.isBurstCooldown and cd.isAvailable then
                readyBurstCooldown = id
                break
            end
        end
        
        if readyBurstCooldown then
            -- Suggest using your burst with this player
            local message = format("%s used %s. Use your burst ability now for maximum effect!", sourceName, GetSpellLink(spellId))
            print("|cFF00FFFF[Windrunner Synergy]|r " .. message)
            
            -- Add visual indicator
            if partyMembers[playerName] then
                partyMembers[playerName].hasBurstReady = true
                self:UpdateMemberFrames()
            end
        end
    end
end

-- Suggest tank swap
function PartySynergy:SuggestTankSwap(targetName, debuffId)
    if not settings.enableTankSwaps then return end
    
    local playerName = UnitName("player")
    local playerRole = UnitGroupRolesAssigned("player")
    
    -- Find the other tank
    local otherTank = nil
    for name, member in pairs(partyMembers) do
        if name ~= targetName and member.role == "TANK" then
            otherTank = name
            break
        end
    end
    
    if not otherTank then return end
    
    -- Create tank swap alert
    local tankSwap = {
        targetTank = targetName,
        otherTank = otherTank,
        debuffId = debuffId,
        timestamp = GetTime()
    }
    
    -- Add to active tank swaps
    table.insert(activeTankSwaps, tankSwap)
    
    -- If we're one of the tanks, show alert
    if playerRole == "TANK" then
        local action = (playerName == otherTank) and "TAUNT NOW" or "SWAP INCOMING"
        local message = format("Tank Swap: %s has %d stacks of %s. %s!", targetName, partyMembers[targetName].debuffs[debuffId].stacks, GetSpellLink(debuffId), action)
        print("|cFFFF0000[Windrunner Synergy]|r " .. message)
        
        -- Add visual indicator
        if playerName == otherTank then
            partyMembers[playerName].needsTankSwap = true
            self:UpdateMemberFrames()
        end
    end
    
    -- Broadcast tank swap to party
    if IsInGroup() and settings.notifyPartyMembers then
        self:SendTankSwap(tankSwap)
    end
end

-- Check for buff gaps
function PartySynergy:CheckBuffGaps()
    if not settings.enableBuffMonitoring then return end
    
    local currentTime = GetTime()
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    
    -- Check what buffs the player can provide
    local playerBuffs = {}
    for _, buff in ipairs(importantBuffs) do
        if buff.class == playerClass then
            playerBuffs[buff.type] = buff
        end
    end
    
    -- Check for missing buffs in the party
    for name, member in pairs(partyMembers) do
        for buffType, buff in pairs(playerBuffs) do
            local hasBuff = false
            
            -- Check if member has this buff
            if member.buffs and member.buffs[buffType] then
                local buffInfo = member.buffs[buffType]
                if buffInfo.endTime > currentTime then
                    hasBuff = true
                end
            end
            
            -- If missing a buff we can provide, notify
            if not hasBuff and name ~= playerName then
                local message = format("%s is missing %s. Consider casting it!", name, GetSpellLink(buff.spellId))
                print("|cFFFFFF00[Windrunner Synergy]|r " .. message)
                
                -- Add visual indicator
                member.needsBuff = true
                self:UpdateMemberFrames()
                
                -- Only show one notification at a time
                return
            end
        end
    end
end

-- On update function
function PartySynergy:OnUpdate(elapsed)
    lastUpdateTime = lastUpdateTime + elapsed
    
    -- Only update at the specified frequency
    if lastUpdateTime >= UPDATE_FREQUENCY then
        -- Update cooldown states
        for id, cd in pairs(cooldownRegistry) do
            local currentTime = GetTime()
            if not cd.isAvailable and cd.endTime <= currentTime then
                cd.isAvailable = true
            end
        end
        
        -- Update UI
        self:UpdateMemberFrames()
        
        -- Check for buff gaps
        self:CheckBuffGaps()
        
        -- Sync with party if needed
        local timeSinceLastSync = GetTime() - lastSyncTime
        if IsInGroup() and timeSinceLastSync >= SYNC_INTERVAL then
            self:SyncWithParty()
            lastSyncTime = GetTime()
        end
        
        -- Clean up expired data
        self:CleanupExpiredData()
        
        lastUpdateTime = 0
    end
end

-- Cleanup expired data
function PartySynergy:CleanupExpiredData()
    local currentTime = GetTime()
    
    -- Clean up expired burst windows
    for i = #pendingBurstWindows, 1, -1 do
        if pendingBurstWindows[i].endTime < currentTime then
            table.remove(pendingBurstWindows, i)
        end
    end
    
    -- Clean up expired tank swaps
    for i = #activeTankSwaps, 1, -1 do
        if activeTankSwaps[i].timestamp + 30 < currentTime then
            table.remove(activeTankSwaps, i)
        end
    end
    
    -- Reset temporary indicators
    for name, member in pairs(partyMembers) do
        member.needsTankSwap = false
        member.needsBuff = false
        member.needsHealing = false
    end
}

-- Sync with party
function PartySynergy:SyncWithParty()
    if not IsInGroup() or not commsEnabled then return end
    
    -- Send hello message to ensure everyone has updated info
    self:SendHello()
    
    -- Share cooldown status
    for id, cd in pairs(cooldownRegistry) do
        if not cd.isAvailable then
            self:SendCooldownUsage(id)
        end
    end
}

-- Register with main addon
function PartySynergy:RegisterWithAddon()
    -- Register slash command
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("synergy", function(msg)
            self:HandleSlashCommand(msg)
        end)
    end
    
    -- Add to settings panel
    if WR.UI and WR.UI.AdvancedSettingsUI and WR.UI.AdvancedSettingsUI.AddSettings then
        WR.UI.AdvancedSettingsUI:AddSettings("Party Synergy", settings, function(newSettings)
            self:ApplySettings(newSettings)
        end)
    end
}

-- Handle slash command
function PartySynergy:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Toggle main UI
        if self.frame then
            if self.frame:IsShown() then
                self.frame:Hide()
            else
                self.frame:Show()
            end
        end
        return
    end
    
    local command, param = msg:match("^(%S+)%s*(.*)$")
    if not command then return end
    
    command = command:lower()
    
    if command == "show" or command == "hide" then
        if self.frame then
            self.frame:SetShown(command == "show")
        end
    elseif command == "reset" then
        -- Reset position
        if self.frame then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            settings.partyFramePosition = {x = 0, y = 0}
            self:SaveSettings()
        end
    elseif command == "scale" and param ~= "" then
        local scale = tonumber(param)
        if scale and scale >= 0.5 and scale <= 2.0 then
            settings.partyFrameScale = scale
            if self.frame then
                self.frame:SetScale(scale)
            end
            self:SaveSettings()
        end
    elseif command == "comms" then
        commsEnabled = not commsEnabled
        print("|cFF00FFFF[Windrunner Synergy]|r Communications " .. (commsEnabled and "ENABLED" or "DISABLED"))
    end
end

-- Send hello message to group
function PartySynergy:SendHello()
    if not IsInGroup() or not commsEnabled then return end
    
    local _, playerClass = UnitClass("player")
    local playerSpec = GetSpecialization()
    local playerSpecId = playerSpec and GetSpecializationInfo(playerSpec) or nil
    local playerRole = UnitGroupRolesAssigned("player")
    
    local message = string.format("%s:%s:%s:%s:%d:%s", 
        MESSAGE_TYPES.HELLO,
        UnitName("player"),
        playerClass,
        playerSpecId or "0",
        playerRole,
        WR.version or "1.0"
    )
    
    SendAddonMessage(PREFIX, message, IsInRaid() and "RAID" or "PARTY")
}

-- Send cooldown usage message
function PartySynergy:SendCooldownUsage(spellId)
    if not IsInGroup() or not commsEnabled then return end
    if not cooldownRegistry[spellId] then return end
    
    local cd = cooldownRegistry[spellId]
    local message = string.format("%s:%s:%d:%d:%d", 
        MESSAGE_TYPES.COOLDOWN,
        UnitName("player"),
        spellId,
        cd.cooldown,
        math.floor(cd.endTime)
    )
    
    SendAddonMessage(PREFIX, message, IsInRaid() and "RAID" or "PARTY")
}

-- Send buff application message
function PartySynergy:SendBuffApplication(spellId)
    if not IsInGroup() or not commsEnabled then return end
    
    -- Find buff info
    local buffInfo = nil
    for _, buff in ipairs(importantBuffs) do
        if buff.spellId == spellId then
            buffInfo = buff
            break
        end
    end
    
    if not buffInfo then return end
    
    local message = string.format("%s:%s:%d:%s:%d", 
        MESSAGE_TYPES.BUFF,
        UnitName("player"),
        spellId,
        buffInfo.type,
        math.floor(GetTime() + buffInfo.duration)
    )
    
    SendAddonMessage(PREFIX, message, IsInRaid() and "RAID" or "PARTY")
}

-- Send burst window message
function PartySynergy:SendBurstWindow(window)
    if not IsInGroup() or not commsEnabled then return end
    if not window then return end
    
    local participants = ""
    for name, _ in pairs(window.participants) do
        participants = participants .. name .. ","
    end
    
    local message = string.format("%s:%s:%d:%d:%d:%s", 
        MESSAGE_TYPES.BURST,
        window.initiator,
        window.spellId,
        math.floor(window.startTime),
        math.floor(window.endTime),
        participants
    )
    
    SendAddonMessage(PREFIX, message, IsInRaid() and "RAID" or "PARTY")
}

-- Send tank swap message
function PartySynergy:SendTankSwap(tankSwap)
    if not IsInGroup() or not commsEnabled then return end
    if not tankSwap then return end
    
    local message = string.format("%s:%s:%s:%d", 
        MESSAGE_TYPES.TANK,
        tankSwap.targetTank,
        tankSwap.otherTank,
        tankSwap.debuffId
    )
    
    SendAddonMessage(PREFIX, message, IsInRaid() and "RAID" or "PARTY")
}

-- Process addon message
function PartySynergy:ProcessAddonMessage(message, sender)
    if not commsEnabled or sender == UnitName("player") then return end
    
    -- Prevent message spam (only process one message per sender per second)
    local currentTime = GetTime()
    if lastProcessedMessageTime[sender] and currentTime - lastProcessedMessageTime[sender] < 1 then
        return
    end
    lastProcessedMessageTime[sender] = currentTime
    
    -- Parse message type
    local msgType, rest = string.match(message, "([^:]+):(.*)")
    if not msgType or not rest then return end
    
    if msgType == MESSAGE_TYPES.HELLO then
        -- Hello message: name:class:specId:role:version
        local name, class, specId, role, version = string.match(rest, "([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
        
        if name and class and specId and role and version then
            -- Update party member info
            if not partyMembers[name] then
                partyMembers[name] = {}
            end
            
            partyMembers[name].name = name
            partyMembers[name].class = class
            partyMembers[name].specId = tonumber(specId)
            partyMembers[name].role = role
            partyMembers[name].cooldowns = partyMembers[name].cooldowns or {}
            partyMembers[name].buffs = partyMembers[name].buffs or {}
            partyMembers[name].debuffs = partyMembers[name].debuffs or {}
            partyMembers[name].isPlayer = false
            partyMembers[name].lastUpdate = GetTime()
            
            -- Update addon version
            addonVersions[name] = version
            
            -- Update UI
            self:UpdateMemberFrames()
            
            -- Send response with our info if we're the target
            if settings.autoRespondToRequests then
                self:SendHello()
            end
        end
    elseif msgType == MESSAGE_TYPES.COOLDOWN then
        -- Cooldown message: name:spellId:cooldown:endTime
        local name, spellId, cooldown, endTime = string.match(rest, "([^:]+):([^:]+):([^:]+):([^:]+)")
        
        if name and spellId and cooldown and endTime then
            spellId = tonumber(spellId)
            cooldown = tonumber(cooldown)
            endTime = tonumber(endTime)
            
            -- Update cooldown info for party member
            if partyMembers[name] then
                if not partyMembers[name].cooldowns then
                    partyMembers[name].cooldowns = {}
                end
                
                -- Get spell name
                local spellName = GetSpellInfo(spellId) or "Unknown Spell"
                
                partyMembers[name].cooldowns[spellId] = {
                    id = spellId,
                    name = spellName,
                    cooldown = cooldown,
                    lastUsed = endTime - cooldown,
                    endTime = endTime,
                    isAvailable = endTime <= GetTime(),
                    isBurstCooldown = cooldown >= settings.burstCooldownThreshold
                }
                
                -- Update UI
                self:UpdateMemberFrames()
                
                -- If this is a burst cooldown, check for burst window coordination
                if cooldown >= settings.burstCooldownThreshold then
                    self:CheckBurstCoordination(name, spellId)
                end
            end
        end
    elseif msgType == MESSAGE_TYPES.BUFF then
        -- Buff message: name:spellId:type:endTime
        local name, spellId, buffType, endTime = string.match(rest, "([^:]+):([^:]+):([^:]+):([^:]+)")
        
        if name and spellId and buffType and endTime then
            spellId = tonumber(spellId)
            endTime = tonumber(endTime)
            
            -- Get spell name
            local spellName = GetSpellInfo(spellId) or "Unknown Buff"
            
            -- Apply buff to all party members for raid-wide buffs
            if endTime - GetTime() > 60 then -- Long duration = raid-wide
                for memberName, member in pairs(partyMembers) do
                    if not member.buffs then member.buffs = {} end
                    member.buffs[buffType] = {
                        id = spellId,
                        name = spellName,
                        endTime = endTime,
                        source = name
                    }
                end
            end
            
            -- Update UI
            self:UpdateMemberFrames()
        end
    elseif msgType == MESSAGE_TYPES.BURST then
        -- Burst message: initiator:spellId:startTime:endTime:participants
        local initiator, spellId, startTime, endTime, participants = string.match(rest, "([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
        
        if initiator and spellId and startTime and endTime and participants then
            spellId = tonumber(spellId)
            startTime = tonumber(startTime)
            endTime = tonumber(endTime)
            
            -- Check if we already have this burst window
            local existingWindow = nil
            for i, window in ipairs(pendingBurstWindows) do
                if window.initiator == initiator and window.startTime == startTime then
                    existingWindow = window
                    break
                end
            end
            
            -- Create or update burst window
            if existingWindow then
                -- Update participant list
                for name in string.gmatch(participants, "([^,]+),") do
                    existingWindow.participants[name] = true
                end
            else
                -- Create new burst window
                local newWindow = {
                    initiator = initiator,
                    spellId = spellId,
                    startTime = startTime,
                    endTime = endTime,
                    participants = {}
                }
                
                -- Add participants
                for name in string.gmatch(participants, "([^,]+),") do
                    newWindow.participants[name] = true
                end
                
                table.insert(pendingBurstWindows, newWindow)
            end
            
            -- Check if player should participate
            local playerName = UnitName("player")
            local playerRole = UnitGroupRolesAssigned("player")
            local currentTime = GetTime()
            
            if currentTime <= endTime and not existingWindow or not existingWindow.participants[playerName] then
                -- Check if we have a burst cooldown ready
                local readyBurstCooldown = nil
                for id, cd in pairs(cooldownRegistry) do
                    if cd.isBurstCooldown and cd.isAvailable then
                        readyBurstCooldown = id
                        break
                    end
                end
                
                if readyBurstCooldown and playerRole == "DAMAGER" then
                    -- Suggest joining burst window
                    local message = format("%s started a burst window with %s. Use your burst ability now for maximum effect!", initiator, GetSpellLink(spellId))
                    print("|cFF00FFFF[Windrunner Synergy]|r " .. message)
                    
                    -- Add visual indicator
                    if partyMembers[playerName] then
                        partyMembers[playerName].hasBurstReady = true
                        self:UpdateMemberFrames()
                    end
                end
            end
        end
    elseif msgType == MESSAGE_TYPES.TANK then
        -- Tank swap message: targetTank:otherTank:debuffId
        local targetTank, otherTank, debuffId = string.match(rest, "([^:]+):([^:]+):([^:]+)")
        
        if targetTank and otherTank and debuffId then
            debuffId = tonumber(debuffId)
            
            -- Create tank swap alert
            local tankSwap = {
                targetTank = targetTank,
                otherTank = otherTank,
                debuffId = debuffId,
                timestamp = GetTime()
            }
            
            -- Add to active tank swaps
            table.insert(activeTankSwaps, tankSwap)
            
            -- If we're the other tank, show alert
            local playerName = UnitName("player")
            local playerRole = UnitGroupRolesAssigned("player")
            
            if playerRole == "TANK" and playerName == otherTank then
                local message = format("Tank Swap: %s has high stacks of %s. TAUNT NOW!", targetTank, GetSpellLink(debuffId))
                print("|cFFFF0000[Windrunner Synergy]|r " .. message)
                
                -- Add visual indicator
                partyMembers[playerName].needsTankSwap = true
                self:UpdateMemberFrames()
            end
        end
    end
end

-- Activate module
function PartySynergy:Activate()
    if isActive then return end
    
    isActive = true
    
    -- Show UI
    if settings.showPartyFrames and IsInGroup() then
        self.frame:Show()
    end
    
    -- Scan group for initial setup
    self:ScanGroup()
    
    -- Initialize cooldown tracking
    self:InitializeCooldownTracking()
    
    print("|cFF00FFFF[Windrunner Rotations]|r Party Synergy activated")
}

-- Deactivate module
function PartySynergy:Deactivate()
    if not isActive then return end
    
    isActive = false
    
    -- Hide UI
    if self.frame then
        self.frame:Hide()
    end
    
    print("|cFF00FFFF[Windrunner Rotations]|r Party Synergy deactivated")
}

-- Toggle module
function PartySynergy:Toggle()
    if isActive then
        self:Deactivate()
    else
        self:Activate()
    end
end

-- Initialize the module
PartySynergy:Initialize()

return PartySynergy