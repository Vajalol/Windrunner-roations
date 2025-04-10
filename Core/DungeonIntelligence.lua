local addonName, WR = ...

-- DungeonIntelligence module for handling dungeon-specific tactics
local DungeonIntelligence = {}
WR.DungeonIntelligence = DungeonIntelligence

-- Current dungeon info
DungeonIntelligence.currentDungeon = nil
DungeonIntelligence.currentBoss = nil
DungeonIntelligence.inMythicPlus = false
DungeonIntelligence.mythicPlusLevel = 0
DungeonIntelligence.mythicPlusAffixes = {}
DungeonIntelligence.enemyPriorities = {}
DungeonIntelligence.interruptPriorities = {}
DungeonIntelligence.avoidableMechanics = {}
DungeonIntelligence.tactics = {}

-- Dungeon difficulty constants
local DUNGEON_DIFFICULTY_NORMAL = 1
local DUNGEON_DIFFICULTY_HEROIC = 2
local DUNGEON_DIFFICULTY_MYTHIC = 23
local DUNGEON_DIFFICULTY_MYTHIC_PLUS = 8

-- Mythic Plus affix IDs
local AFFIX_TYRANNICAL = 9
local AFFIX_FORTIFIED = 10
local AFFIX_INSPIRING = 122
local AFFIX_SANGUINE = 8
local AFFIX_VOLCANIC = 3
local AFFIX_GRIEVOUS = 12
local AFFIX_RAGING = 6
local AFFIX_NECROTIC = 4
local AFFIX_BOLSTERING = 7
local AFFIX_SKITTISH = 2
local AFFIX_EXPLOSIVE = 13
local AFFIX_QUAKING = 14
local AFFIX_BURSTING = 11
local AFFIX_STORMING = 124
local AFFIX_SPITEFUL = 123
local AFFIX_THUNDERING = 132
local AFFIX_ENTANGLING = 134
local AFFIX_AFFLICTED = 136
local AFFIX_INCORPOREAL = 135

-- Enemy types
local ENEMY_TYPE_NORMAL = 1
local ENEMY_TYPE_ELITE = 2
local ENEMY_TYPE_MINIBOSS = 3
local ENEMY_TYPE_BOSS = 4

-- Priority levels
local PRIORITY_LOW = 1
local PRIORITY_MEDIUM = 2
local PRIORITY_HIGH = 3
local PRIORITY_CRITICAL = 4

-- Initialize the module
function DungeonIntelligence:Initialize()
    -- Register callback for when targets change
    WR.Target:RegisterCallback("TargetChanged", function(targetInfo)
        self:OnTargetChanged(targetInfo)
    end)
    
    -- Load dungeon data
    self:LoadDungeonData()
    
    -- Initialize the current dungeon
    self:UpdateCurrentDungeon()
    
    WR:Debug("DungeonIntelligence module initialized")
end

-- Load dungeon data from the data store
function DungeonIntelligence:LoadDungeonData()
    if not WR.Data or not WR.Data.Dungeons then
        WR:Debug("Dungeon data not available")
        return
    end
    
    -- Process dungeon data to create lookup tables
    for dungeonId, dungeonData in pairs(WR.Data.Dungeons) do
        -- Process enemy priorities
        if dungeonData.enemies then
            for enemyId, enemyData in pairs(dungeonData.enemies) do
                self.enemyPriorities[enemyId] = enemyData.priority or PRIORITY_MEDIUM
            end
        end
        
        -- Process interrupt priorities
        if dungeonData.interrupts then
            for spellId, priority in pairs(dungeonData.interrupts) do
                self.interruptPriorities[spellId] = priority
            end
        end
        
        -- Process avoidable mechanics
        if dungeonData.avoidable then
            for mechId, mechData in pairs(dungeonData.avoidable) do
                self.avoidableMechanics[mechId] = mechData
            end
        end
        
        -- Process boss tactics
        if dungeonData.bosses then
            for bossId, bossData in pairs(dungeonData.bosses) do
                if bossData.tactics then
                    self.tactics[bossId] = bossData.tactics
                end
            end
        end
    end
    
    WR:Debug("Loaded dungeon data: ", #self.enemyPriorities, " enemies, ", 
             #self.interruptPriorities, " interrupt priorities, ",
             #self.avoidableMechanics, " avoidable mechanics, ",
             #self.tactics, " boss tactics")
end

-- Update the current dungeon information
function DungeonIntelligence:UpdateCurrentDungeon()
    -- Get current map ID and instance info
    local mapID = C_Map.GetBestMapForUnit("player")
    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, 
          instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
          
    -- Check if we're in a dungeon
    if instanceType ~= "party" then
        self.currentDungeon = nil
        self.inMythicPlus = false
        self.mythicPlusLevel = 0
        self.mythicPlusAffixes = {}
        return
    end
    
    -- Set current dungeon information
    self.currentDungeon = {
        id = instanceID,
        name = name,
        mapID = mapID,
        difficulty = difficultyID
    }
    
    -- Check if we're in a Mythic+ dungeon
    if difficultyID == DUNGEON_DIFFICULTY_MYTHIC_PLUS then
        self.inMythicPlus = true
        
        -- Get Mythic+ level
        local mythicPlusLevel = C_ChallengeMode.GetActiveKeystoneInfo()
        self.mythicPlusLevel = mythicPlusLevel or 0
        
        -- Get active affixes
        self.mythicPlusAffixes = {}
        local affixes = C_MythicPlus.GetCurrentAffixes()
        if affixes then
            for _, affixInfo in ipairs(affixes) do
                table.insert(self.mythicPlusAffixes, affixInfo.id)
            end
        end
        
        -- Adjust tactical decisions based on Mythic+ level and affixes
        self:AdjustForMythicPlus()
    else
        self.inMythicPlus = false
        self.mythicPlusLevel = 0
        self.mythicPlusAffixes = {}
    end
    
    WR:Debug("Updated current dungeon: ", name, " (", instanceID, "), Mythic+: ", 
             self.inMythicPlus, ", Level: ", self.mythicPlusLevel)
             
    -- Broadcast dungeon update event
    WR:TriggerEvent("DUNGEON_CHANGED", self.currentDungeon)
end

-- Adjust tactical decisions based on Mythic+ level and affixes
function DungeonIntelligence:AdjustForMythicPlus()
    -- Increase priority of certain mechanics based on affixes
    if self:HasAffix(AFFIX_TYRANNICAL) then
        -- Increase priority of boss mechanics
        self:AdjustBossMechanicPriorities(1)
    end
    
    if self:HasAffix(AFFIX_FORTIFIED) then
        -- Increase priority of trash mechanics
        self:AdjustTrashMechanicPriorities(1)
    end
    
    if self:HasAffix(AFFIX_INSPIRING) then
        -- Mark inspired mobs as non-interruptible but higher priority targets
        self:HandleInspiringAffix()
    end
    
    if self:HasAffix(AFFIX_EXPLOSIVE) then
        -- Add explosive orbs as high priority targets
        self:HandleExplosiveAffix()
    end
    
    -- Other affix adjustments would be implemented here
end

-- Increase boss mechanic priorities
function DungeonIntelligence:AdjustBossMechanicPriorities(increase)
    -- Iterate through available boss mechanics and increase their priority
    for mechId, mechData in pairs(self.avoidableMechanics) do
        if mechData.isBossMechanic then
            mechData.priority = math.min(PRIORITY_CRITICAL, (mechData.priority or PRIORITY_MEDIUM) + increase)
        end
    end
end

-- Increase trash mechanic priorities
function DungeonIntelligence:AdjustTrashMechanicPriorities(increase)
    -- Iterate through available trash mechanics and increase their priority
    for mechId, mechData in pairs(self.avoidableMechanics) do
        if not mechData.isBossMechanic then
            mechData.priority = math.min(PRIORITY_CRITICAL, (mechData.priority or PRIORITY_MEDIUM) + increase)
        end
    end
end

-- Handle Inspiring affix by marking mobs and adjusting priorities
function DungeonIntelligence:HandleInspiringAffix()
    -- Logic to detect mobs with the Inspiring buff
    -- And adjust tactics accordingly
    -- This would interact with the real-time combat scanning
end

-- Handle Explosive affix by adding orbs as high priority targets
function DungeonIntelligence:HandleExplosiveAffix()
    -- Add explosive orbs to the priority target list
    self.enemyPriorities[120651] = PRIORITY_CRITICAL  -- Explosive ID
end

-- Check if a specific affix is active
function DungeonIntelligence:HasAffix(affixID)
    for _, activeAffixId in ipairs(self.mythicPlusAffixes) do
        if activeAffixId == affixID then
            return true
        end
    end
    return false
end

-- React to target changes
function DungeonIntelligence:OnTargetChanged(targetInfo)
    if not targetInfo or not targetInfo.guid then return end
    
    local unitGUID = targetInfo.guid
    local unitID = targetInfo.id or "target"
    
    -- Get NPC ID from GUID
    local _, _, _, _, _, npcID = strsplit("-", unitGUID)
    npcID = tonumber(npcID)
    
    if not npcID then return end
    
    -- Check if this is a boss
    if self:IsBoss(npcID) then
        self.currentBoss = npcID
        self:LoadBossTactics(npcID)
    else
        -- Check if this is a priority target
        local priority = self:GetEnemyPriority(npcID)
        if priority >= PRIORITY_HIGH then
            -- Mark as high priority target
            WR:Debug("High priority target detected: ", UnitName(unitID), " (", npcID, ")")
        end
        
        -- Check for interrupt priorities
        self:ScanForInterruptPriorities(unitID)
    end
end

-- Check if the NPC is a dungeon boss
function DungeonIntelligence:IsBoss(npcID)
    if not self.currentDungeon or not WR.Data.Dungeons[self.currentDungeon.id] then
        return false
    end
    
    local dungeonData = WR.Data.Dungeons[self.currentDungeon.id]
    if not dungeonData.bosses then return false end
    
    for bossId, _ in pairs(dungeonData.bosses) do
        if bossId == npcID then
            return true
        end
    end
    
    return false
end

-- Load specific tactics for a boss
function DungeonIntelligence:LoadBossTactics(bossID)
    if not self.tactics[bossID] then return end
    
    local bossTactics = self.tactics[bossID]
    
    -- Apply tactics to rotation system
    if bossTactics.prioritySpells then
        for spellId, priority in pairs(bossTactics.prioritySpells) do
            WR.Rotation:ModifySpellPriority(spellId, priority)
        end
    end
    
    if bossTactics.avoidancePhases then
        for phaseId, phaseData in pairs(bossTactics.avoidancePhases) do
            -- Set up phase detection and avoidance logic
            -- This would involve registering for combat events
        end
    end
    
    if bossTactics.interruptPriorities then
        for spellId, priority in pairs(bossTactics.interruptPriorities) do
            self.interruptPriorities[spellId] = priority
        end
    end
    
    WR:Debug("Loaded tactics for boss: ", bossID)
    
    -- Broadcast boss update event
    WR:TriggerEvent("BOSS_CHANGED", bossID)
end

-- Scan a unit for castable abilities that should be interrupted
function DungeonIntelligence:ScanForInterruptPriorities(unitID)
    if not UnitCanAttack("player", unitID) then return end
    
    -- Check if the unit is casting
    local name, _, _, startTime, endTime, _, _, notInterruptible, spellId = UnitCastingInfo(unitID)
    
    if spellId and not notInterruptible then
        local priority = self:GetInterruptPriority(spellId)
        if priority >= PRIORITY_HIGH then
            -- Add to interrupt queue with priority
            WR.Rotation:AddInterruptTarget(unitID, spellId, priority)
        end
    end
    
    -- Also check for channeled spells
    name, _, _, startTime, endTime, _, notInterruptible, spellId = UnitChannelInfo(unitID)
    
    if spellId and not notInterruptible then
        local priority = self:GetInterruptPriority(spellId)
        if priority >= PRIORITY_HIGH then
            -- Add to interrupt queue with priority
            WR.Rotation:AddInterruptTarget(unitID, spellId, priority)
        end
    end
end

-- Get the priority of an enemy
function DungeonIntelligence:GetEnemyPriority(npcID)
    return self.enemyPriorities[npcID] or PRIORITY_MEDIUM
end

-- Get the priority of interrupting a spell
function DungeonIntelligence:GetInterruptPriority(spellId)
    return self.interruptPriorities[spellId] or PRIORITY_MEDIUM
end

-- Check for avoidable mechanics
function DungeonIntelligence:CheckAvoidableMechanics()
    -- This would scan for void zones, GTFO triggers, etc.
    -- And trigger movement commands if needed
    
    -- For example, checking for fire on the ground:
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("player", i)
        if spellId and self.avoidableMechanics[spellId] then
            local mechanic = self.avoidableMechanics[spellId]
            if mechanic.priority >= PRIORITY_HIGH then
                -- Trigger avoidance behavior
                WR:Debug("High priority avoidable mechanic detected: ", spellId)
                WR.Rotation:TriggerAvoidance(mechanic)
                return true
            end
        end
    end
    
    return false
end

-- Get enemy forces count for current pull (for M+ route planning)
function DungeonIntelligence:GetCurrentPullForces()
    if not self.inMythicPlus then return 0 end
    
    -- In a real addon, this would use the actual M+ enemy forces data
    local forces = 0
    for unit in WR.Target:IterateEnemies() do
        local guid = UnitGUID(unit)
        if guid then
            local _, _, _, _, _, npcID = strsplit("-", guid)
            npcID = tonumber(npcID)
            
            -- Get enemy forces value from data
            if npcID and WR.Data.Dungeons[self.currentDungeon.id] and 
               WR.Data.Dungeons[self.currentDungeon.id].enemyForces and
               WR.Data.Dungeons[self.currentDungeon.id].enemyForces[npcID] then
                forces = forces + WR.Data.Dungeons[self.currentDungeon.id].enemyForces[npcID]
            end
        end
    end
    
    return forces
end

-- Adjust rotation based on current dungeon conditions
function DungeonIntelligence:GetDungeonRotationAdjustments()
    local adjustments = {
        useDefensives = false,
        prioritizeAOE = false,
        prioritizeSingleTarget = false,
        useBurstCooldowns = false,
    }
    
    -- Check if we're in combat with a boss
    if self.currentBoss and UnitExists("boss1") then
        adjustments.useBurstCooldowns = true
        
        -- Check boss health percentage for burst windows
        local bossHealth = UnitHealth("boss1") / UnitHealthMax("boss1") * 100
        
        -- Common timing for burst cooldowns
        if bossHealth < 30 or (bossHealth > 80 and bossHealth < 95) then
            adjustments.useBurstCooldowns = true
        end
        
        -- Check for specific boss mechanics
        if self.tactics[self.currentBoss] then
            local phase = self:GetCurrentBossPhase()
            if phase and self.tactics[self.currentBoss].phases and 
               self.tactics[self.currentBoss].phases[phase] then
                local phaseData = self.tactics[self.currentBoss].phases[phase]
                
                -- Apply phase-specific adjustments
                if phaseData.aoe then
                    adjustments.prioritizeAOE = true
                end
                
                if phaseData.defensives then
                    adjustments.useDefensives = true
                end
                
                if phaseData.burst then
                    adjustments.useBurstCooldowns = true
                end
            end
        end
    else
        -- For trash packs, check enemy count
        local enemyCount = WR.Target:GetEnemyCount(10)
        
        if enemyCount >= 4 then
            adjustments.prioritizeAOE = true
        else
            adjustments.prioritizeSingleTarget = true
        end
        
        -- If in Mythic+, check affixes
        if self.inMythicPlus then
            if self:HasAffix(AFFIX_RAGING) and 
               self:HasLowHealthEnemy(35) then
                adjustments.useDefensives = true
            end
            
            if self:HasAffix(AFFIX_NECROTIC) and 
               self:GetNecroticStacks() > 15 then
                adjustments.useDefensives = true
            end
            
            -- Additional affix-specific adjustments
        end
    end
    
    return adjustments
end

-- Get the current boss phase
function DungeonIntelligence:GetCurrentBossPhase()
    if not self.currentBoss then return nil end
    
    -- This would normally use boss health, DBM/BW events, or other indicators
    -- For demo purposes, just use boss health percentage
    if UnitExists("boss1") then
        local bossHealth = UnitHealth("boss1") / UnitHealthMax("boss1") * 100
        
        if bossHealth < 30 then
            return "phase3"
        elseif bossHealth < 60 then
            return "phase2"
        else
            return "phase1"
        end
    end
    
    return nil
end

-- Check if there's a low health enemy
function DungeonIntelligence:HasLowHealthEnemy(threshold)
    for unit in WR.Target:IterateEnemies() do
        if UnitExists(unit) and UnitHealth(unit) / UnitHealthMax(unit) * 100 < threshold then
            return true
        end
    end
    return false
end

-- Get current Necrotic stacks
function DungeonIntelligence:GetNecroticStacks()
    for i = 1, 40 do
        local name, _, count, _, _, _, _, _, _, spellId = UnitDebuff("player", i)
        if spellId == 209858 then -- Necrotic Wound
            return count or 0
        end
    end
    return 0
end

-- Return the module
return DungeonIntelligence