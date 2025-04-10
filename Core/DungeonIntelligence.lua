local addonName, WR = ...

-- Dungeon Intelligence module - advanced knowledge about dungeon mechanics and priorities
local DungeonIntelligence = {}
WR.DungeonIntelligence = DungeonIntelligence

-- State
local state = {
    currentDungeon = nil,
    currentZoneID = nil,
    enableDungeonIntelligence = true,
    dungeonData = {},
    importantNPCs = {},
    bossEncounters = {},
    dungeonMechanics = {},
    interruptPriorities = {},
    avoidanceAreas = {},
    instantKillAbilities = {},
    priorityDispels = {},
    priorityTargets = {},
    patrollingEnemies = {},
    dangerousAffixes = {},
    mythicPlusTimers = {},
    currentBossFight = nil,
    activeFeatures = {
        targetPriority = true,
        interruptPriority = true,
        dispelPriority = true,
        avoidance = true,
        patrolWarning = true,
        tacticalAdvice = true
    }
}

-- Initialize the module
function DungeonIntelligence:Initialize()
    -- Load saved variables
    state.enableDungeonIntelligence = WR.Config:Get("enableDungeonIntelligence", true)
    state.activeFeatures.targetPriority = WR.Config:Get("targetPriorityEnabled", true)
    state.activeFeatures.interruptPriority = WR.Config:Get("interruptPriorityEnabled", true)
    state.activeFeatures.dispelPriority = WR.Config:Get("dispelPriorityEnabled", true)
    state.activeFeatures.avoidance = WR.Config:Get("avoidanceEnabled", true)
    state.activeFeatures.patrolWarning = WR.Config:Get("patrolWarningEnabled", true)
    state.activeFeatures.tacticalAdvice = WR.Config:Get("tacticalAdviceEnabled", true)
    
    -- Create frame for receiving events
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("CHALLENGE_MODE_START")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_END")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            DungeonIntelligence:UpdateCurrentDungeon()
        elseif event == "CHALLENGE_MODE_START" then
            DungeonIntelligence:OnMythicPlusStart(...)
        elseif event == "ENCOUNTER_START" then
            DungeonIntelligence:OnEncounterStart(...)
        elseif event == "ENCOUNTER_END" then
            DungeonIntelligence:OnEncounterEnd(...)
        end
    end)
    
    -- Load dungeon data
    self:LoadDungeonData()
    
    -- Check if we're already in a dungeon
    self:UpdateCurrentDungeon()
    
    WR:Debug("Dungeon Intelligence module initialized")
end

-- Update the current dungeon based on the player's location
function DungeonIntelligence:UpdateCurrentDungeon()
    local zoneID = C_Map.GetBestMapForUnit("player")
    if not zoneID then return end
    
    -- Check if the zone ID changed
    if zoneID == state.currentZoneID then return end
    
    state.currentZoneID = zoneID
    state.currentDungeon = nil
    
    -- Check if we're in a known dungeon
    for dungeonName, dungeonInfo in pairs(state.dungeonData) do
        for _, mapID in ipairs(dungeonInfo.mapIDs) do
            if mapID == zoneID then
                state.currentDungeon = dungeonName
                WR:Debug("Detected dungeon:", dungeonName)
                
                -- Load the specific dungeon data
                self:LoadCurrentDungeonData()
                return
            end
        end
    end
    
    WR:Debug("No dungeon detected for zone ID:", zoneID)
end

-- On Mythic+ start
function DungeonIntelligence:OnMythicPlusStart(challengeMapID)
    if not state.currentDungeon then return end
    
    WR:Debug("Mythic+ started:", state.currentDungeon)
    
    -- Record the start time for the timer
    if state.mythicPlusTimers[state.currentDungeon] then
        state.mythicPlusTimers[state.currentDungeon].startTime = GetTime()
        state.mythicPlusTimers[state.currentDungeon].isActive = true
    end
    
    -- Apply any special handling for the current affix combination
    self:ProcessMythicPlusAffixes()
end

-- On boss encounter start
function DungeonIntelligence:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    if not state.currentDungeon then return end
    
    WR:Debug("Boss encounter started:", encounterName)
    
    -- Find and store the current boss fight data
    for _, boss in ipairs(state.bossEncounters) do
        if boss.encounterID == encounterID then
            state.currentBossFight = boss
            
            -- Adjust rotations based on this specific boss fight
            self:AdjustForBossFight(boss)
            break
        end
    end
end

-- On boss encounter end
function DungeonIntelligence:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if not state.currentDungeon then return end
    
    WR:Debug("Boss encounter ended:", encounterName, success == 1 and "Success" or "Failed")
    
    -- Clear any boss-specific adjustments
    state.currentBossFight = nil
    
    -- Reset rotations to normal
    self:ResetBossFightAdjustments()
end

-- Load the dungeon data for all supported dungeons
function DungeonIntelligence:LoadDungeonData()
    -- The War Within Season 2 Dungeons (Example data - would be populated with actual dungeon data)
    state.dungeonData = {
        ["Dawn of the Infinite: Galakrond's Fall"] = {
            mapIDs = {2579},
            bosses = {
                "Chronikar",
                "Manifested Timeways",
                "Blight of Galakrond",
                "Iridikron the Stonescaled",
                "Tyr, the Infinite Keeper",
            },
            timer = 39 * 60, -- 39 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["Dawn of the Infinite: Murozond's Rise"] = {
            mapIDs = {2580},
            bosses = {
                "Chrono-Lord Deios",
                "Manifested Timeways",
                "Andantenormu",
                "Morchie",
                "Time-Lost Battlefield",
                "Chrono-Lord Deios",
            },
            timer = 39 * 60, -- 39 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["Waycrest Manor"] = {
            mapIDs = {1862},
            bosses = {
                "Heartsbane Triad",
                "Soulbound Goliath",
                "Raal the Gluttonous",
                "Lord and Lady Waycrest",
                "Gorak Tul",
            },
            timer = 38 * 60, -- 38 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["Black Rook Hold"] = {
            mapIDs = {1501},
            bosses = {
                "The Amalgam of Souls",
                "Illysanna Ravencrest",
                "Smashspite the Hateful",
                "Lord Kur'talos Ravencrest",
            },
            timer = 40 * 60, -- 40 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["Atal'Dazar"] = {
            mapIDs = {1763},
            bosses = {
                "Priestess Alun'za",
                "Vol'kaal",
                "Rezan",
                "Yazma",
            },
            timer = 30 * 60, -- 30 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["Darkheart Thicket"] = {
            mapIDs = {1466},
            bosses = {
                "Archdruid Glaidalis",
                "Oakheart",
                "Dresaron",
                "Shade of Xavius",
            },
            timer = 30 * 60, -- 30 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["The Everbloom"] = {
            mapIDs = {1279},
            bosses = {
                "Witherbark",
                "Ancient Protectors",
                "Archmage Sol",
                "Xeri'tac",
                "Yalnu",
            },
            timer = 30 * 60, -- 30 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
        ["Throne of the Tides"] = {
            mapIDs = {1043},
            bosses = {
                "Lady Naz'jar",
                "Commander Ulthok, the Festering Prince",
                "Mindbender Ghur'sha",
                "Ozumat",
            },
            timer = 33 * 60, -- 33 minutes
            covenant = nil   -- No dungeon-specific covenant
        },
    }
    
    -- Initialize timers for all dungeons
    for dungeonName, _ in pairs(state.dungeonData) do
        state.mythicPlusTimers[dungeonName] = {
            startTime = 0,
            isActive = false
        }
    end

    -- Load specific data for War Within season 2 (this would be more extensive in actual implementation)
    self:LoadWarWithinSeason2Data()
end

-- Load War Within Season 2 specific data
function DungeonIntelligence:LoadWarWithinSeason2Data()
    -- Example of specific dungeon data - in a real implementation, this would contain comprehensive data
    
    -- Key enemies that should be prioritized in targeting
    state.importantNPCs = {
        -- Dawn of the Infinite: Galakrond's Fall
        [206068] = { name = "Infinite Timeslicer", priority = 90, note = "High priority kill target, dangerous cleave" },
        [206139] = { name = "Infinite Chronoweaver", priority = 95, note = "High priority interrupt target, time warp" },
        
        -- Waycrest Manor
        [131677] = { name = "Heartsbane Runeweaver", priority = 85, note = "Priority interrupt target" },
        [135329] = { name = "Matron Bryndle", priority = 90, note = "Casts Soul Manipulation, high priority" },
        
        -- Black Rook Hold
        [98280] = { name = "Risen Arcanist", priority = 90, note = "Casts powerful AoE, interrupt priority" },
        [98275] = { name = "Risen Companion", priority = 30, note = "Low priority add" },
        
        -- Atal'Dazar
        [122971] = { name = "Dazar'ai Augur", priority = 85, note = "Powerful healer, high priority" },
        [125977] = { name = "Reanimation Totem", priority = 100, note = "Highest priority, destroys immediately" },
        
        -- Darkheart Thicket
        [95771] = { name = "Dreadsoul Ruiner", priority = 80, note = "Casts Fear, interrupt priority" },
        [100531] = { name = "Bloodtainted Fury", priority = 85, note = "AoE damage, high priority" },
        
        -- The Everbloom
        [81820] = { name = "Everbloom Naturalist", priority = 80, note = "Healer, high priority" },
        [81985] = { name = "Everbloom Tender", priority = 90, note = "Priority interrupt target" },
        
        -- Throne of the Tides
        [40577] = { name = "Naz'jar Oracle", priority = 85, note = "Healer, high priority" },
        [40788] = { name = "Minion of Ghur'sha", priority = 90, note = "Dangerous, high priority" }
    }
    
    -- Critical spells to interrupt
    state.interruptPriorities = {
        -- Dawn of the Infinite
        [413013] = { name = "Chronoburst", priority = 95, note = "Must interrupt, heavy damage" },
        [412505] = { name = "Temporal Strike", priority = 90, note = "High priority, slows time" },
        
        -- Waycrest Manor
        [263943] = { name = "Etch", priority = 90, note = "Must interrupt, heavy damage" },
        [263891] = { name = "Grasping Thorns", priority = 85, note = "CC ability, interrupt if possible" },
        
        -- Black Rook Hold
        [200248] = { name = "Arcane Blitz", priority = 90, note = "Heavy magic damage, interrupt" },
        [197974] = { name = "Bonecrushing Strike", priority = 85, note = "Physical damage, interrupt if possible" },
        
        -- Atal'Dazar
        [253517] = { name = "Mending Word", priority = 95, note = "Healing spell, must interrupt" },
        [253544] = { name = "Bwonsamdi's Mantle", priority = 90, note = "Damage buff, high priority interrupt" },
        
        -- Darkheart Thicket
        [200658] = { name = "Star Shower", priority = 90, note = "AoE damage, high priority" },
        [204667] = { name = "Nightmare Bolt", priority = 95, note = "Heavy single target damage, must interrupt" },
        
        -- The Everbloom
        [169839] = { name = "Pyroblast", priority = 90, note = "Heavy fire damage, high priority" },
        [164965] = { name = "Choking Vines", priority = 95, note = "CC effect, must interrupt" },
        
        -- Throne of the Tides
        [76813] = { name = "Bubbling Surge", priority = 95, note = "AoE damage + knockback, must interrupt" },
        [75992] = { name = "Lightning Surge", priority = 90, note = "Magic damage, high priority interrupt" }
    }
    
    -- Boss encounters with specific mechanics
    state.bossEncounters = {
        {
            encounterID = 2673,
            name = "Chronikar",
            dungeon = "Dawn of the Infinite: Galakrond's Fall",
            mechanics = {
                {
                    id = "temporal_barrage",
                    name = "Temporal Barrage",
                    description = "Avoid the telegraphed barrage zones",
                    type = "AVOID_AREA"
                },
                {
                    id = "infinite_annihilation",
                    name = "Infinite Annihilation",
                    description = "Dispel this debuff immediately",
                    type = "PRIORITY_DISPEL"
                }
            },
            priority_targets = {
                { id = 198933, name = "Infinite Keeper", priority = 90 }
            }
        },
        {
            encounterID = 2666,
            name = "Tyr, the Infinite Keeper",
            dungeon = "Dawn of the Infinite: Galakrond's Fall",
            mechanics = {
                {
                    id = "titanic_blow",
                    name = "Titanic Blow",
                    description = "Tank swap or use defensive cooldown",
                    type = "TANK_SWAP"
                },
                {
                    id = "divine_matrix",
                    name = "Divine Matrix",
                    description = "Spread out to avoid chain damage",
                    type = "SPREAD"
                }
            }
        },
        {
            encounterID = 2677,
            name = "Lord and Lady Waycrest",
            dungeon = "Waycrest Manor",
            mechanics = {
                {
                    id = "virulent_pathogen",
                    name = "Virulent Pathogen",
                    description = "Disease that should be dispelled",
                    type = "PRIORITY_DISPEL"
                },
                {
                    id = "discordant_cadenza",
                    name = "Discordant Cadenza",
                    description = "Interrupt this cast priority",
                    type = "PRIORITY_INTERRUPT"
                }
            },
            priority_targets = {
                { id = 131527, name = "Lord Waycrest", priority = 80 },
                { id = 131545, name = "Lady Waycrest", priority = 100 }
            }
        }
        -- Additional boss encounters would be defined here
    }
    
    -- Dangerous areas to avoid
    state.avoidanceAreas = {
        {
            dungeonID = "Dawn of the Infinite: Galakrond's Fall",
            areas = {
                {
                    id = "time_sink",
                    name = "Time Sink",
                    description = "Slowing pool on the ground, avoid standing in it",
                    visual_id = 123456 -- Visual ID for detection
                },
                {
                    id = "chronoburst_aoe",
                    name = "Chronoburst AoE",
                    description = "Telegraphed explosion, move out quickly",
                    visual_id = 123457
                }
            }
        },
        {
            dungeonID = "Waycrest Manor",
            areas = {
                {
                    id = "rotten_expulsion",
                    name = "Rotten Expulsion",
                    description = "Poison pool, avoid standing in it",
                    visual_id = 123458
                },
                {
                    id = "soul_harvest",
                    name = "Soul Harvest",
                    description = "Soul extraction channel, move away",
                    visual_id = 123459
                }
            }
        }
        -- Other dungeons' avoidance areas would be defined here
    }
    
    -- Abilities that can result in instant death if not handled properly
    state.instantKillAbilities = {
        [410904] = { name = "Infinite Annihilation", description = "Move away from affected player" },
        [260512] = { name = "Soul Harvest", description = "Break the channel immediately" }
        -- More abilities would be listed here
    }
    
    -- Priority dispels by dungeon
    state.priorityDispels = {
        ["Dawn of the Infinite: Galakrond's Fall"] = {
            [410905] = { name = "Chronal Detonation", priority = 95, type = "Magic" },
            [413208] = { name = "Time Stasis", priority = 90, type = "Magic" }
        },
        ["Waycrest Manor"] = {
            [260900] = { name = "Soul Manipulation", priority = 95, type = "Magic" },
            [263891] = { name = "Grasping Thorns", priority = 90, type = "Magic" }
        }
        -- Other dungeons' priority dispels would be defined here
    }
    
    -- Patrolling enemies to be aware of
    state.patrollingEnemies = {
        ["Dawn of the Infinite: Galakrond's Fall"] = {
            { id = 206147, name = "Infinite Riftweaver", patrol_path = "Central area", danger_level = "High" },
            { id = 206069, name = "Infinite Slayer", patrol_path = "Side corridors", danger_level = "Medium" }
        },
        ["Waycrest Manor"] = {
            { id = 131812, name = "Heartsbane Soulcharmer", patrol_path = "Upper halls", danger_level = "High" },
            { id = 135474, name = "Thistle Acolyte", patrol_path = "Garden area", danger_level = "Medium" }
        }
        -- Other dungeons' patrolling enemies would be defined here
    }
    
    -- Dangerous affixes to be aware of
    state.dangerousAffixes = {
        [10] = { name = "Fortified", advice = "Focus on efficient AoE for trash packs" },
        [11] = { name = "Tyrannical", advice = "Save cooldowns for boss fights" },
        [12] = { name = "Grievous", advice = "Prioritize healing when players drop below 90% health" },
        [123] = { name = "Spiteful", advice = "Kite the shades when they spawn on trash deaths" },
        [124] = { name = "Storming", advice = "Watch for tornados in melee range, move out" },
        [135] = { name = "Afflicted", advice = "Move away from group when debuffed" }
        -- Other affixes would be defined here
    }
end

-- Load data specific to the current dungeon
function DungeonIntelligence:LoadCurrentDungeonData()
    if not state.currentDungeon then return end
    
    WR:Debug("Loading data for dungeon:", state.currentDungeon)
    
    -- This would load more specific data for the current dungeon
    -- For demonstration, we're using the general data already loaded
end

-- Get NPC priority for the targeting system
function DungeonIntelligence:GetEnemyPriority(npcID)
    if not state.enableDungeonIntelligence or not state.activeFeatures.targetPriority then
        return nil
    end
    
    if not npcID or not state.importantNPCs[npcID] then
        return nil
    end
    
    return state.importantNPCs[npcID].priority
end

-- Get interrupt priority for a spell
function DungeonIntelligence:GetInterruptPriority(spellID)
    if not state.enableDungeonIntelligence or not state.activeFeatures.interruptPriority then
        return nil
    end
    
    if not spellID or not state.interruptPriorities[spellID] then
        return nil
    end
    
    return state.interruptPriorities[spellID].priority
end

-- Get dispel priority for a spell
function DungeonIntelligence:GetDispelPriority(spellID)
    if not state.enableDungeonIntelligence or not state.activeFeatures.dispelPriority then
        return nil
    end
    
    if not spellID or not state.currentDungeon or not state.priorityDispels[state.currentDungeon] then
        return nil
    end
    
    local dispelInfo = state.priorityDispels[state.currentDungeon][spellID]
    if not dispelInfo then
        return nil
    end
    
    return dispelInfo.priority
end

-- Check if a position is in a dangerous area
function DungeonIntelligence:IsPositionDangerous(x, y, z)
    if not state.enableDungeonIntelligence or not state.activeFeatures.avoidance then
        return false
    end
    
    if not state.currentDungeon then
        return false
    end
    
    -- This would involve more complex spatial calculations
    -- For demonstration, we're simply returning false
    return false
end

-- Process current Mythic+ affixes
function DungeonIntelligence:ProcessMythicPlusAffixes()
    -- Get active affixes
    local activeAffixes = C_MythicPlus.GetCurrentAffixes()
    if not activeAffixes then return end
    
    WR:Debug("Processing Mythic+ affixes")
    
    -- Adjust behavior based on affixes
    for _, affixInfo in ipairs(activeAffixes) do
        local affixID = affixInfo.id
        
        if state.dangerousAffixes[affixID] then
            local affixName = state.dangerousAffixes[affixID].name
            local advice = state.dangerousAffixes[affixID].advice
            
            WR:Debug("Active affix:", affixName, "-", advice)
            
            -- Make specific adjustments based on afflixes
            if affixID == 10 then -- Fortified
                -- Adjust for Fortified: prioritize AoE
                if WR.Rotation then
                    WR.Rotation:AdjustForAffix("fortified")
                end
            elseif affixID == 11 then -- Tyrannical
                -- Adjust for Tyrannical: focus on boss damage
                if WR.Rotation then
                    WR.Rotation:AdjustForAffix("tyrannical")
                end
            elseif affixID == 12 then -- Grievous
                -- Adjust for Grievous: prioritize healing/self-healing
                if WR.Rotation then
                    WR.Rotation:AdjustForAffix("grievous")
                end
            end
            -- More affix handling would be added here
        end
    end
end

-- Adjust rotation for a specific boss fight
function DungeonIntelligence:AdjustForBossFight(boss)
    if not WR.Rotation then return end
    
    WR:Debug("Adjusting rotation for boss:", boss.name)
    
    -- Example specific adjustments
    if boss.name == "Chronikar" then
        -- Adjust for Chronikar: increase movement, prepare for high damage
        WR.Rotation:AdjustForBoss("chronikar")
    elseif boss.name == "Tyr, the Infinite Keeper" then
        -- Adjust for Tyr: tank swap mechanic, spread requirement
        WR.Rotation:AdjustForBoss("tyr")
    elseif boss.name == "Lord and Lady Waycrest" then
        -- Adjust for Lord and Lady Waycrest: priority switching, dispel focus
        WR.Rotation:AdjustForBoss("waycrest")
    end
    
    -- Apply any priority target adjustments
    if boss.priority_targets then
        for _, target in ipairs(boss.priority_targets) do
            state.priorityTargets[target.id] = target.priority
        end
    end
end

-- Reset adjustments made for boss fights
function DungeonIntelligence:ResetBossFightAdjustments()
    if not WR.Rotation then return end
    
    WR:Debug("Resetting boss fight adjustments")
    
    WR.Rotation:ResetBossAdjustments()
    
    -- Clear any priority targets
    wipe(state.priorityTargets)
end

-- Get a list of priority interrupt spell IDs
function DungeonIntelligence:GetInterruptPrioritySpells()
    local result = {}
    
    for spellID, data in pairs(state.interruptPriorities) do
        result[spellID] = data.priority
    end
    
    return result
end

-- Get a list of priority dispel spell IDs for the current dungeon
function DungeonIntelligence:GetDispelPrioritySpells()
    if not state.currentDungeon or not state.priorityDispels[state.currentDungeon] then
        return {}
    end
    
    local result = {}
    
    for spellID, data in pairs(state.priorityDispels[state.currentDungeon]) do
        result[spellID] = data.priority
    end
    
    return result
end

-- Get a table of patrolling enemies for the current dungeon
function DungeonIntelligence:GetPatrollingEnemies()
    if not state.currentDungeon or not state.patrollingEnemies[state.currentDungeon] then
        return {}
    end
    
    return state.patrollingEnemies[state.currentDungeon]
end

-- Check if a specific NPC is patrolling in the current dungeon
function DungeonIntelligence:IsPatrollingEnemy(npcID)
    if not state.enableDungeonIntelligence or not state.activeFeatures.patrolWarning then
        return false
    end
    
    if not state.currentDungeon or not state.patrollingEnemies[state.currentDungeon] then
        return false
    end
    
    for _, patrol in ipairs(state.patrollingEnemies[state.currentDungeon]) do
        if patrol.id == npcID then
            return true
        end
    end
    
    return false
end

-- Get information about the current mythic+ run
function DungeonIntelligence:GetMythicPlusInfo()
    if not state.currentDungeon then
        return nil
    end
    
    -- Get the current timer info
    local timerInfo = state.mythicPlusTimers[state.currentDungeon]
    if not timerInfo or not timerInfo.isActive then
        return nil
    end
    
    local now = GetTime()
    local elapsed = now - timerInfo.startTime
    local totalTime = state.dungeonData[state.currentDungeon].timer
    local remaining = totalTime - elapsed
    
    -- Calculate timing thresholds
    local threeChestTime = totalTime * 0.6 -- 60% of the timer
    local twoChestTime = totalTime * 0.8 -- 80% of the timer
    local oneChestTime = totalTime -- 100% of the timer
    
    local chestLevel = 0
    if elapsed <= threeChestTime then
        chestLevel = 3
    elseif elapsed <= twoChestTime then
        chestLevel = 2
    elseif elapsed <= oneChestTime then
        chestLevel = 1
    end
    
    return {
        dungeonName = state.currentDungeon,
        timeElapsed = elapsed,
        timeRemaining = remaining,
        totalTime = totalTime,
        chestLevel = chestLevel,
        threeChestTimeRemaining = threeChestTime - elapsed,
        twoChestTimeRemaining = twoChestTime - elapsed,
        oneChestTimeRemaining = oneChestTime - elapsed
    }
end

-- Enable or disable the dungeon intelligence module
function DungeonIntelligence:SetEnabled(enabled)
    state.enableDungeonIntelligence = enabled
    WR.Config:Set("enableDungeonIntelligence", enabled)
    
    WR:Debug("Dungeon Intelligence", enabled and "enabled" or "disabled")
end

-- Check if the module is enabled
function DungeonIntelligence:IsEnabled()
    return state.enableDungeonIntelligence
end

-- Enable or disable a specific feature
function DungeonIntelligence:SetFeatureEnabled(feature, enabled)
    if state.activeFeatures[feature] ~= nil then
        state.activeFeatures[feature] = enabled
        WR.Config:Set(feature .. "Enabled", enabled)
        
        WR:Debug("Feature", feature, enabled and "enabled" or "disabled")
        return true
    end
    
    return false
end

-- Check if a specific feature is enabled
function DungeonIntelligence:IsFeatureEnabled(feature)
    return state.activeFeatures[feature] or false
end

-- Get the current dungeon name
function DungeonIntelligence:GetCurrentDungeon()
    return state.currentDungeon
end

-- Get boss encounter data for the current dungeon
function DungeonIntelligence:GetBossEncountersForCurrentDungeon()
    if not state.currentDungeon then
        return {}
    end
    
    local result = {}
    
    for _, boss in ipairs(state.bossEncounters) do
        if boss.dungeon == state.currentDungeon then
            table.insert(result, boss)
        end
    end
    
    return result
end

-- Get data about dangerous zones in the current dungeon
function DungeonIntelligence:GetDangerousAreasForCurrentDungeon()
    if not state.currentDungeon then
        return {}
    end
    
    for _, areaInfo in ipairs(state.avoidanceAreas) do
        if areaInfo.dungeonID == state.currentDungeon then
            return areaInfo.areas
        end
    end
    
    return {}
end

-- Initialize the module
DungeonIntelligence:Initialize()

return DungeonIntelligence