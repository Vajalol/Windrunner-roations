local addonName, WR = ...

-- DungeonIntelligence module for handling dungeon-specific logic
local DungeonIntelligence = {}
WR.DungeonIntelligence = DungeonIntelligence

-- Priority levels for reference
local PRIORITY_LOW = 1
local PRIORITY_MEDIUM = 2
local PRIORITY_HIGH = 3
local PRIORITY_CRITICAL = 4

-- Flags for enemy statuses
local STATUS_CASTING = 1
local STATUS_INTERRUPTIBLE = 2
local STATUS_DANGEROUS = 3
local STATUS_PRIORITY_TARGET = 4
local STATUS_AVOID = 5

-- Current dungeon information
DungeonIntelligence.currentDungeonId = nil
DungeonIntelligence.enemyData = {}
DungeonIntelligence.bossData = {}
DungeonIntelligence.priorityTargets = {}
DungeonIntelligence.affixes = {}
DungeonIntelligence.isInMythicPlus = false
DungeonIntelligence.trackedInterrupts = {}
DungeonIntelligence.avoidableMechanics = {}

-- M+ Affixes data
DungeonIntelligence.affixData = {
    [9] = {
        name = "Tyrannical",
        description = "Bosses have 30% more health and deal 15% increased damage.",
        isBossAffix = true
    },
    [10] = {
        name = "Fortified",
        description = "Non-boss enemies have 20% more health and deal 30% increased damage.",
        isTrashAffix = true
    },
    [3] = {
        name = "Volcanic",
        description = "While in combat, enemies periodically cause the ground beneath you to erupt in flame.",
        avoidance = true,
        groundEffect = true
    },
    [4] = {
        name = "Necrotic",
        description = "Enemy melee attacks apply a stacking debuff that reduces healing received and deals damage.",
        defensives = true,
        tankBuster = true
    },
    [6] = {
        name = "Raging",
        description = "Non-boss enemies enrage at low health, dealing 100% increased damage.",
        defensives = true,
        focusLow = true
    },
    [7] = {
        name = "Bolstering",
        description = "When any non-boss enemy dies, its death empowers nearby allies with 20% health and damage.",
        tacticalKills = true
    },
    [8] = {
        name = "Sanguine",
        description = "When slain, non-boss enemies leave behind a pool of blood that heals enemies and damages players.",
        groundEffect = true,
        mobPositioning = true
    },
    [11] = {
        name = "Bursting",
        description = "When slain, non-boss enemies explode, dealing damage over time to all players.",
        aoeHealing = true,
        staggerKills = true
    },
    [12] = {
        name = "Grievous",
        description = "When damaged below 90% health, players suffer increasing damage over time until healed above 90%.",
        aoeHealing = true
    },
    [13] = {
        name = "Explosive",
        description = "Enemies periodically summon Explosive Orbs that detonate if not destroyed.",
        targetPriority = true
    },
    [14] = {
        name = "Quaking",
        description = "Periodically, all players emit shockwaves that damage and interrupt nearby allies.",
        avoidance = true,
        spreadPositioning = true
    },
    [123] = {
        name = "Spiteful",
        description = "Defeated enemies spawn spiteful shades that pursue non-tank players.",
        defensives = true,
        kiting = true
    },
    [124] = {
        name = "Storming",
        description = "Enemies periodically summon damaging whirlwinds.",
        avoidance = true,
        groundEffect = true
    },
    [128] = {
        name = "Inspiring",
        description = "Certain enemies empower nearby allies with resolute, making them immune to crowd control effects.",
        priorityTargets = true
    },
    [134] = {
        name = "Entangling",
        description = "While in combat, periodically summon vines that entangle players.",
        dispels = true
    },
    [136] = {
        name = "Afflicted",
        description = "Creatures inflict additional diseases, poisons and curses throughout the dungeon.",
        dispels = true
    },
    [135] = {
        name = "Incorporeal",
        description = "While in combat, players periodically become Incorporeal, reducing damage and healing.",
        raidCds = true
    }
}

-- Initialize the module
function DungeonIntelligence:Initialize()
    self:RegisterEvents()
    WR:Debug("DungeonIntelligence module initialized")
    
    -- Create the frame for event handling
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
    
    -- Register for required events
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.frame:RegisterEvent("CHALLENGE_MODE_START")
    self.frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_START")
    self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- Initialize timers
    self.updateTimer = 0
    self.checkInterval = 0.5
end

-- Register events
function DungeonIntelligence:RegisterEvents()
    -- Register for additional events if needed
end

-- Event handler
function DungeonIntelligence:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:UpdateCurrentDungeon()
    elseif event == "CHALLENGE_MODE_START" then
        self.isInMythicPlus = true
        self:UpdateAffixes()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        self.isInMythicPlus = false
    elseif event == "UNIT_SPELLCAST_START" then
        local unit, _, spellID = ...
        if unit and UnitExists(unit) and UnitCanAttack("player", unit) then
            self:CheckInterruptibleSpell(unit, spellID)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:ProcessCombatEvent(CombatLogGetCurrentEventInfo())
    end
end

-- Process combat log events
function DungeonIntelligence:ProcessCombatEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName = ...
    
    -- Track enemy spawns
    if eventType == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
            self:HandleEnemyDeath(destGUID)
        end
    elseif eventType == "SPELL_CAST_START" then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
            self:HandleEnemyCast(sourceGUID, spellID, spellName)
        end
    elseif eventType == "SPELL_AURA_APPLIED" then
        if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 and bit.band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then
            self:HandleEnemyDebuff(sourceGUID, destGUID, spellID, spellName)
        end
    end
end

-- Update information about the current dungeon
function DungeonIntelligence:UpdateCurrentDungeon()
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    
    if instanceType == "party" and WR.Data.Dungeons[instanceID] then
        self.currentDungeonId = instanceID
        self:LoadDungeonData(instanceID)
        WR:Debug("Loaded dungeon data for:", WR.Data.Dungeons[instanceID].name)
    else
        self.currentDungeonId = nil
        self:ClearDungeonData()
    end
end

-- Load data for the specific dungeon
function DungeonIntelligence:LoadDungeonData(dungeonId)
    local dungeonData = WR.Data.Dungeons[dungeonId]
    if not dungeonData then return end
    
    -- Load the dungeon data into the module
    self.enemyData = dungeonData.enemies or {}
    self.bossData = dungeonData.bosses or {}
    self.trackedInterrupts = dungeonData.interrupts or {}
    self.avoidableMechanics = dungeonData.avoidable or {}
    
    -- Set up priority target list
    self.priorityTargets = {}
    for id, data in pairs(self.enemyData) do
        if data.priority and data.priority >= PRIORITY_HIGH then
            self.priorityTargets[id] = data.priority
        end
    end
    
    -- Check if we're in a M+ and update affixes
    if C_ChallengeMode.IsChallengeModeActive() then
        self.isInMythicPlus = true
        self:UpdateAffixes()
    else
        self.isInMythicPlus = false
        self.affixes = {}
    end
end

-- Clear dungeon-specific data
function DungeonIntelligence:ClearDungeonData()
    self.enemyData = {}
    self.bossData = {}
    self.priorityTargets = {}
    self.trackedInterrupts = {}
    self.avoidableMechanics = {}
    self.affixes = {}
    self.isInMythicPlus = false
end

-- Update M+ affixes
function DungeonIntelligence:UpdateAffixes()
    self.affixes = {}
    
    -- Get active affixes
    local affixIDs = C_MythicPlus.GetCurrentAffixes()
    if not affixIDs then return end
    
    for _, affixInfo in ipairs(affixIDs) do
        local affixID = affixInfo.id
        if self.affixData[affixID] then
            self.affixes[affixID] = self.affixData[affixID]
        end
    end
    
    WR:Debug("Updated M+ affixes:", table.concat(self:GetActiveAffixNames(), ", "))
end

-- Get names of active affixes
function DungeonIntelligence:GetActiveAffixNames()
    local names = {}
    for id, data in pairs(self.affixes) do
        table.insert(names, data.name)
    end
    return names
end

-- Check if a spell should be interrupted
function DungeonIntelligence:ShouldInterrupt(unit, spellID)
    if not unit or not UnitExists(unit) or not spellID then return false end
    
    -- Check if this is a priority interrupt
    local priority = self.trackedInterrupts[spellID]
    if priority then
        -- Return true for high or critical priority interrupts
        return priority >= PRIORITY_HIGH
    end
    
    -- Check boss-specific interrupts
    local npcID = self:GetNPCID(UnitGUID(unit))
    if npcID and self.bossData[npcID] and self.bossData[npcID].tactics and 
       self.bossData[npcID].tactics.interruptPriorities and 
       self.bossData[npcID].tactics.interruptPriorities[spellID] then
        local bossPriority = self.bossData[npcID].tactics.interruptPriorities[spellID]
        return bossPriority >= PRIORITY_HIGH
    end
    
    return false
end

-- Get the interrupt priority of a spell
function DungeonIntelligence:GetInterruptPriority(spellID)
    -- Check if this is a tracked interrupt
    if self.trackedInterrupts[spellID] then
        return self.trackedInterrupts[spellID]
    end
    
    -- If not explicitly tracked, check if it's a dangerous ability
    if self.avoidableMechanics[spellID] then
        return PRIORITY_HIGH
    end
    
    -- Default priority
    return PRIORITY_LOW
end

-- Check if an enemy is a priority target
function DungeonIntelligence:IsPriorityTarget(unit)
    if not unit or not UnitExists(unit) then return false end
    
    local npcID = self:GetNPCID(UnitGUID(unit))
    if not npcID then return false end
    
    -- Check if it's in our priority list
    if self.priorityTargets[npcID] then
        return true
    end
    
    -- Check if it's a boss
    if self.bossData[npcID] then
        return true
    end
    
    -- Check if it's an enemy with the Inspiring affix (when active)
    if self.affixes[128] and WR.Auras:UnitHasBuff(unit, 343502) then -- Inspiring affix buff
        return true
    end
    
    return false
end

-- Get the priority level of a target
function DungeonIntelligence:GetTargetPriority(unit)
    if not unit or not UnitExists(unit) then return PRIORITY_LOW end
    
    local npcID = self:GetNPCID(UnitGUID(unit))
    if not npcID then return PRIORITY_LOW end
    
    -- Check bosses first
    if self.bossData[npcID] then
        return PRIORITY_CRITICAL
    end
    
    -- Then check priority enemies
    if self.priorityTargets[npcID] then
        return self.priorityTargets[npcID]
    end
    
    -- Check for Inspiring mobs
    if self.affixes[128] and WR.Auras:UnitHasBuff(unit, 343502) then -- Inspiring affix buff
        return PRIORITY_HIGH
    end
    
    -- Check for Explosive affix orbs
    if self.affixes[13] and npcID == 120651 then -- Explosive Orb
        return PRIORITY_CRITICAL
    end
    
    -- Default priority
    return PRIORITY_LOW
end

-- Check if a spell should be avoided
function DungeonIntelligence:ShouldAvoid(spellID)
    if not spellID then return false end
    
    -- Check if this is a tracked avoidable mechanic
    if self.avoidableMechanics[spellID] then
        return true
    end
    
    return false
end

-- Handle tracking of enemy casts
function DungeonIntelligence:HandleEnemyCast(sourceGUID, spellID, spellName)
    if not sourceGUID or not spellID then return end
    
    local npcID = self:GetNPCID(sourceGUID)
    if not npcID then return end
    
    -- Check if this is an interrupt priority
    if self.trackedInterrupts[spellID] or 
       (self.bossData[npcID] and 
        self.bossData[npcID].tactics and 
        self.bossData[npcID].tactics.interruptPriorities and 
        self.bossData[npcID].tactics.interruptPriorities[spellID]) then
        
        -- Notify about high priority interrupt
        local priority = self.trackedInterrupts[spellID] or 
                         (self.bossData[npcID] and 
                          self.bossData[npcID].tactics and 
                          self.bossData[npcID].tactics.interruptPriorities and 
                          self.bossData[npcID].tactics.interruptPriorities[spellID])
        
        if priority >= PRIORITY_HIGH then
            WR:Debug("High priority interrupt detected:", spellName, "from", self:GetEnemyName(npcID))
            -- Signal to the rotation to prioritize interrupting
            WR.interruptPriority = priority
            WR.interruptTarget = sourceGUID
            WR.interruptSpellID = spellID
        end
    end
    
    -- Check if this is an avoidable mechanic
    if self.avoidableMechanics[spellID] then
        WR:Debug("Avoidable mechanic detected:", spellName, "from", self:GetEnemyName(npcID))
        -- Signal to defensive rotation
        WR.avoidMechanicActive = true
        WR.avoidMechanicSpellID = spellID
        WR.avoidMechanicSourceGUID = sourceGUID
    end
end

-- Handle enemy debuffs on players
function DungeonIntelligence:HandleEnemyDebuff(sourceGUID, destGUID, spellID, spellName)
    -- Handle specific debuffs that might need a reaction
    -- For example, Grievous Wound, Necrotic, etc.
    
    -- Check if this is part of an M+ affix
    if self.affixes[4] and spellID == 209858 then -- Necrotic
        -- Signal to defensive/healing rotation
        WR:Debug("Necrotic detected on player")
        WR.necroticActive = true
    elseif self.affixes[12] and spellID == 240559 then -- Grievous
        -- Signal to healing rotation
        WR:Debug("Grievous detected on player")
        WR.grievousActive = true
    end
end

-- Handle enemy death
function DungeonIntelligence:HandleEnemyDeath(destGUID)
    local npcID = self:GetNPCID(destGUID)
    if not npcID then return end
    
    -- Check for M+ affix reactions
    if self.affixes[7] then -- Bolstering
        WR:Debug("Enemy died with Bolstering active")
        -- Signal to avoid multi-pulls or prioritize even distribution of damage
        WR.bolsteringActive = true
    elseif self.affixes[8] then -- Sanguine
        WR:Debug("Enemy died with Sanguine active")
        -- Signal to move away from death location
        WR.sanguineActive = true
    elseif self.affixes[11] then -- Bursting
        WR:Debug("Enemy died with Bursting active")
        -- Signal for defensive/healing rotation
        WR.burstingActive = true
    elseif self.affixes[123] then -- Spiteful
        WR:Debug("Enemy died with Spiteful active")
        -- Signal for defensive reaction
        WR.spitefulActive = true
    end
end

-- Check if a spell from an enemy is interruptible
function DungeonIntelligence:CheckInterruptibleSpell(unit, spellID)
    if not unit or not UnitExists(unit) or not spellID then return end
    
    -- Decide if we should attempt to interrupt this spell
    if self:ShouldInterrupt(unit, spellID) then
        -- Get the caster's GUID
        local guid = UnitGUID(unit)
        local spellName = GetSpellInfo(spellID)
        
        WR:Debug("Interruptible spell detected:", spellName, "from", UnitName(unit))
        
        -- Signal to the rotation to prioritize interrupting
        WR.interruptPriority = self:GetInterruptPriority(spellID)
        WR.interruptTarget = guid
        WR.interruptSpellID = spellID
    end
end

-- Get NPCID from GUID
function DungeonIntelligence:GetNPCID(guid)
    if not guid then return nil end
    local type, _, _, _, _, npcID = strsplit("-", guid)
    if type ~= "Creature" and type ~= "Vehicle" then return nil end
    return tonumber(npcID)
end

-- Get enemy name from NPCID
function DungeonIntelligence:GetEnemyName(npcID)
    if not npcID then return "Unknown" end
    
    -- Check if it's a boss
    if self.bossData[npcID] then
        return self.bossData[npcID].name or "Unknown Boss"
    end
    
    -- Check if it's a tracked enemy
    if self.enemyData[npcID] then
        return self.enemyData[npcID].name or "Unknown Enemy"
    end
    
    return "Untracked Enemy"
end

-- Get boss tactics for the current target
function DungeonIntelligence:GetBossTactics(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    local npcID = self:GetNPCID(UnitGUID(unit))
    if not npcID or not self.bossData[npcID] then return nil end
    
    return self.bossData[npcID].tactics
end

-- Get enemy notes for a specific enemy
function DungeonIntelligence:GetEnemyNotes(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    local npcID = self:GetNPCID(UnitGUID(unit))
    if not npcID or not self.enemyData[npcID] then return nil end
    
    return self.enemyData[npcID].notes
end

-- Process current dungeon mechanics for current target
function DungeonIntelligence:ProcessCurrentTargetMechanics()
    if not self.currentDungeonId then return end
    
    local target = "target"
    if not UnitExists(target) then return end
    
    local npcID = self:GetNPCID(UnitGUID(target))
    if not npcID then return end
    
    -- Handle boss-specific mechanics
    if self.bossData[npcID] then
        local boss = self.bossData[npcID]
        local tactics = boss.tactics
        
        if tactics then
            -- Determine current boss phase
            local currentPhase = self:GetCurrentBossPhase(target, npcID)
            
            if currentPhase and tactics.phases and tactics.phases[currentPhase] then
                local phaseData = tactics.phases[currentPhase]
                
                -- Signal to rotation about special needs
                if phaseData.defensives then
                    WR.needDefensives = true
                end
                
                if phaseData.aoe then
                    WR.needAOE = true
                end
                
                if phaseData.burst then
                    WR.needBurst = true
                end
                
                -- Note: add more signals as needed
            end
        end
    end
    
    -- Handle priority enemy mechanics
    if self.enemyData[npcID] then
        local enemy = self.enemyData[npcID]
        
        -- Signal to rotation if this is a dangerous enemy
        if enemy.dangerous then
            WR.dangerousEnemyActive = true
        end
    end
end

-- Determine the current boss phase
function DungeonIntelligence:GetCurrentBossPhase(unit, npcID)
    if not unit or not UnitExists(unit) or not npcID then return "phase1" end
    
    -- For simplicity, we'll just use health percentage to determine phase
    -- In a real implementation, this would be more complex and boss-specific
    local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
    
    if healthPct <= 30 then
        return "phase3"
    elseif healthPct <= 60 then
        return "phase2"
    else
        return "phase1"
    end
end

-- Process current M+ affixes for rotation adjustments
function DungeonIntelligence:ProcessAffixAdjustments()
    if not self.isInMythicPlus then return end
    
    local adjustments = {}
    
    for affixID, affixData in pairs(self.affixes) do
        if affixID == 9 then -- Tyrannical
            adjustments.bossDefensives = true
            adjustments.bossDamageReduction = true
        elseif affixID == 10 then -- Fortified
            adjustments.trashDefensives = true
            adjustments.prioritizeCC = true
        elseif affixID == 3 then -- Volcanic
            adjustments.increasedMovement = true
        elseif affixID == 4 then -- Necrotic
            adjustments.tankKiting = true
            adjustments.tankDefensives = true
        elseif affixID == 6 then -- Raging
            adjustments.focusLowHealth = true
            adjustments.defOnRage = true
        elseif affixID == 7 then -- Bolstering
            adjustments.evenDamage = true
        elseif affixID == 8 then -- Sanguine
            adjustments.moveAfterKills = true
        elseif affixID == 11 then -- Bursting
            adjustments.defensiveAfterKills = true
            adjustments.staggerKills = true
        elseif affixID == 12 then -- Grievous
            adjustments.increasedSelfHealing = true
        elseif affixID == 13 then -- Explosive
            adjustments.targetOrbs = true
        elseif affixID == 14 then -- Quaking
            adjustments.spreadOut = true
            adjustments.reduceChanneling = true
        elseif affixID == 123 then -- Spiteful
            adjustments.defensiveAfterKills = true
            adjustments.kiteFromShades = true
        elseif affixID == 124 then -- Storming
            adjustments.increasedMovement = true
        elseif affixID == 128 then -- Inspiring
            adjustments.focusInspiring = true
        end
    end
    
    return adjustments
end

-- Get a list of enemy priority targets in the current pull
function DungeonIntelligence:GetPriorityTargetsInPull()
    local priorityUnits = {}
    
    -- Check all enemies in the current pull
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and self:IsPriorityTarget(unit) then
            local guid = UnitGUID(unit)
            local npcID = self:GetNPCID(guid)
            if npcID then
                table.insert(priorityUnits, {
                    unit = unit,
                    guid = guid,
                    npcID = npcID,
                    name = UnitName(unit),
                    priority = self:GetTargetPriority(unit)
                })
            end
        end
    end
    
    -- Sort by priority, highest first
    table.sort(priorityUnits, function(a, b) return a.priority > b.priority end)
    
    return priorityUnits
end

-- Get interrupt advice for the current situation
function DungeonIntelligence:GetInterruptAdvice()
    local advice = {
        shouldInterrupt = false,
        target = nil,
        priority = PRIORITY_LOW,
        spellID = nil
    }
    
    -- Check if there's an active interrupt priority
    if WR.interruptPriority and WR.interruptPriority >= PRIORITY_HIGH then
        advice.shouldInterrupt = true
        advice.priority = WR.interruptPriority
        advice.target = WR.interruptTarget
        advice.spellID = WR.interruptSpellID
        return advice
    end
    
    -- Scan for interruptible casts
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local spellName, _, _, startTime, endTime, _, _, notInterruptible, spellID = UnitCastingInfo(unit)
            
            if spellName and not notInterruptible and spellID then
                local priority = self:GetInterruptPriority(spellID)
                if priority > advice.priority then
                    advice.shouldInterrupt = true
                    advice.target = UnitGUID(unit)
                    advice.priority = priority
                    advice.spellID = spellID
                end
            end
        end
    end
    
    return advice
end

-- Get the best target for the current situation based on dungeon intelligence
function DungeonIntelligence:GetOptimalTarget()
    -- If we're not in a dungeon, return nil to use default targeting
    if not self.currentDungeonId then return nil end
    
    -- Get all priority targets in the current pull
    local priorityTargets = self:GetPriorityTargetsInPull()
    
    -- Check M+ specific targeting requirements
    local affixAdjustments = self:ProcessAffixAdjustments()
    
    -- If explosive affix is active, check for orbs
    if affixAdjustments and affixAdjustments.targetOrbs then
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) and self:GetNPCID(UnitGUID(unit)) == 120651 then
                return unit -- Return explosive orb unit
            end
        end
    end
    
    -- If inspiring affix is active, prioritize inspiring mobs
    if affixAdjustments and affixAdjustments.focusInspiring then
        for i = 1, 40 do
            local unit = "nameplate" .. i
            if UnitExists(unit) and UnitCanAttack("player", unit) and WR.Auras:UnitHasBuff(unit, 343502) then
                return unit -- Return inspiring unit
            end
        end
    end
    
    -- If there are priority targets, return the highest priority
    if #priorityTargets > 0 then
        return priorityTargets[1].unit
    end
    
    -- Otherwise return nil to use default targeting
    return nil
end

-- Check if AoE is needed based on current situation
function DungeonIntelligence:IsAoENeeded()
    local numEnemies = WR.Targeting:GetEnemyCount(10)
    
    -- Basic check for number of enemies
    if numEnemies >= 3 then
        return true
    end
    
    -- Check if we're on a boss with AoE phase
    local target = "target"
    if UnitExists(target) then
        local npcID = self:GetNPCID(UnitGUID(target))
        if npcID and self.bossData[npcID] then
            local boss = self.bossData[npcID]
            local tactics = boss.tactics
            
            if tactics then
                -- Determine current boss phase
                local currentPhase = self:GetCurrentBossPhase(target, npcID)
                
                if currentPhase and tactics.phases and tactics.phases[currentPhase] and tactics.phases[currentPhase].aoe then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Check if burst is needed based on current situation
function DungeonIntelligence:IsBurstNeeded()
    -- Check if we're on a boss with burst phase
    local target = "target"
    if UnitExists(target) then
        local npcID = self:GetNPCID(UnitGUID(target))
        if npcID and self.bossData[npcID] then
            local boss = self.bossData[npcID]
            local tactics = boss.tactics
            
            if tactics then
                -- Determine current boss phase
                local currentPhase = self:GetCurrentBossPhase(target, npcID)
                
                if currentPhase and tactics.phases and tactics.phases[currentPhase] and tactics.phases[currentPhase].burst then
                    return true
                end
            end
        end
    end
    
    -- Check if target is close to death and has an enrage mechanic
    if UnitExists(target) and UnitHealth(target) / UnitHealthMax(target) < 0.3 then
        if self.affixes[6] then -- Raging affix
            return true
        end
        
        local npcID = self:GetNPCID(UnitGUID(target))
        if npcID and self.enemyData[npcID] and self.enemyData[npcID].enragesAtLowHealth then
            return true
        end
    end
    
    return false
end

-- Update function called from the main addon update
function DungeonIntelligence:Update(elapsed)
    self.updateTimer = self.updateTimer + elapsed
    
    if self.updateTimer >= self.checkInterval then
        self.updateTimer = 0
        
        -- Process current target mechanics
        self:ProcessCurrentTargetMechanics()
        
        -- Reset flags
        WR.needDefensives = false
        WR.needAOE = self:IsAoENeeded()
        WR.needBurst = self:IsBurstNeeded()
        WR.dangerousEnemyActive = false
        
        -- Get and process interrupt advice
        local interruptAdvice = self:GetInterruptAdvice()
        if interruptAdvice.shouldInterrupt then
            WR.interruptPriority = interruptAdvice.priority
            WR.interruptTarget = interruptAdvice.target
            WR.interruptSpellID = interruptAdvice.spellID
        else
            WR.interruptPriority = PRIORITY_LOW
            WR.interruptTarget = nil
            WR.interruptSpellID = nil
        end
        
        -- Get optimal target
        local optimalTarget = self:GetOptimalTarget()
        if optimalTarget then
            -- Override targeting if needed
            WR.optimalTarget = optimalTarget
        else
            WR.optimalTarget = nil
        end
    end
end

-- Initialize the module
DungeonIntelligence:Initialize()

return DungeonIntelligence