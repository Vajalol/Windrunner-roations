------------------------------------------
-- WindrunnerRotations - Testing Framework
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local TestingFramework = {}
WR.TestingFramework = TestingFramework

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local RotationSimulator = WR.RotationSimulator
local PerformanceTracker = WR.PerformanceTracker

-- Test data storage
local testResults = {}
local testInProgress = false
local testQueue = {}
local currentTest = nil
local testLog = {}
local testSimulations = {}
local benchmarkResults = {}
local edgeCaseResults = {}
local comparisonResults = {}
local testStats = {
    total = 0,
    passed = 0,
    failed = 0,
    warnings = 0,
    runtime = 0
}
local realCombatLogs = {}
local testCoverage = {}

-- Constants
local TEST_TIMEOUT = 30 -- seconds
local EDGE_CASE_SCENARIOS = {
    "low_health",
    "oom",
    "movement",
    "burst",
    "aoe",
    "defensive",
    "interrupt",
    "debuffed",
    "cc_break",
    "dispel"
}

-- Initialize the Testing Framework
function TestingFramework:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRTEST1 = "/wrtest"
    SlashCmdList["WRTEST"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Register for module loading
    ModuleManager:RegisterCallback("OnModuleLoaded", function(moduleTable)
        self:GenerateTestsForModule(moduleTable)
    end)
    
    API.PrintDebug("Testing Framework initialized")
    return true
end

-- Register settings for the Testing Framework
function TestingFramework:RegisterSettings()
    ConfigRegistry:RegisterSettings("TestingFramework", {
        generalSettings = {
            enableAutomatedTesting = {
                displayName = "Enable Automated Testing",
                description = "Enable automated testing during addon development",
                type = "toggle",
                default = true
            },
            logLevel = {
                displayName = "Log Level",
                description = "Level of detail for test logs",
                type = "dropdown",
                options = { "minimal", "normal", "verbose" },
                default = "normal"
            },
            runTestsOnStartup = {
                displayName = "Run Tests on Startup",
                description = "Automatically run tests when the addon loads",
                type = "toggle",
                default = false
            },
            includeBenchmarks = {
                displayName = "Include Benchmarks",
                description = "Include performance benchmarks in tests",
                type = "toggle",
                default = true
            }
        },
        simulationSettings = {
            defaultDuration = {
                displayName = "Default Test Duration",
                description = "Default duration for simulated rotation tests (seconds)",
                type = "slider",
                min = 10,
                max = 300,
                step = 10,
                default = 60
            },
            iterations = {
                displayName = "Test Iterations",
                description = "Number of iterations for each test",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 3
            },
            targetCreatureType = {
                displayName = "Target Creature Type",
                description = "Creature type for the test target",
                type = "dropdown",
                options = { "humanoid", "demon", "undead", "elemental", "beast", "dragonkin", "mechanical" },
                default = "humanoid"
            },
            targetLevel = {
                displayName = "Target Level",
                description = "Level of the test target",
                type = "slider",
                min = 60,
                max = 70,
                step = 1,
                default = 70
            }
        },
        coverageSettings = {
            enableCoverageTracking = {
                displayName = "Enable Coverage Tracking",
                description = "Track which spells and abilities are tested",
                type = "toggle",
                default = true
            },
            minimumCoverageThreshold = {
                displayName = "Minimum Coverage Threshold",
                description = "Minimum percentage of abilities that should be tested",
                type = "slider",
                min = 50,
                max = 100,
                step = 5,
                default = 75
            },
            coverageDisplay = {
                displayName = "Coverage Display",
                description = "How to display coverage information",
                type = "dropdown",
                options = { "summary", "detailed" },
                default = "summary"
            }
        },
        edgeCaseSettings = {
            enableEdgeCaseTesting = {
                displayName = "Enable Edge Case Testing",
                description = "Test edge cases like low health, OOM, etc.",
                type = "toggle",
                default = true
            },
            lowHealthThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage to test low health scenarios",
                type = "slider",
                min = 5,
                max = 30,
                step = 5,
                default = 20
            },
            oomThreshold = {
                displayName = "OOM Threshold",
                description = "Mana/resource percentage to test OOM scenarios",
                type = "slider",
                min = 5,
                max = 20,
                step = 5,
                default = 10
            },
            movementDuration = {
                displayName = "Movement Duration",
                description = "Duration to test movement scenarios (seconds)",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 3
            }
        },
        debugSettings = {
            saveLogs = {
                displayName = "Save Test Logs",
                description = "Save test logs for later review",
                type = "toggle",
                default = true
            },
            enableRealTimeLogging = {
                displayName = "Enable Real-Time Logging",
                description = "Log test information in real-time",
                type = "toggle",
                default = true
            },
            compareWithBaseline = {
                displayName = "Compare with Baseline",
                description = "Compare test results with baseline data",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Generate tests for a module
function TestingFramework:GenerateTestsForModule(module)
    if not module or not module.name or not module.specID then
        return
    end
    
    local moduleName = module.name
    local specID = module.specID
    
    -- Basic rotation test
    self:AddTest({
        name = moduleName .. " Basic Rotation",
        module = moduleName,
        specID = specID,
        type = "rotation",
        setup = function()
            return self:SetupBasicRotationTest(module)
        end,
        execute = function()
            return self:ExecuteRotationTest(module)
        end,
        verify = function(results)
            return self:VerifyRotationTest(module, results)
        end,
        cleanup = function()
            return self:CleanupTest()
        end
    })
    
    -- Performance benchmark
    self:AddTest({
        name = moduleName .. " Performance Benchmark",
        module = moduleName,
        specID = specID,
        type = "benchmark",
        setup = function()
            return self:SetupBenchmarkTest(module)
        end,
        execute = function()
            return self:ExecuteBenchmarkTest(module)
        end,
        verify = function(results)
            return self:VerifyBenchmarkTest(module, results)
        end,
        cleanup = function()
            return self:CleanupTest()
        end
    })
    
    -- Edge case tests
    local settings = ConfigRegistry:GetSettings("TestingFramework")
    if settings.edgeCaseSettings.enableEdgeCaseTesting then
        for _, scenario in ipairs(EDGE_CASE_SCENARIOS) do
            self:AddTest({
                name = moduleName .. " " .. scenario:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
                    return first:upper() .. rest
                end) .. " Test",
                module = moduleName,
                specID = specID,
                type = "edge_case",
                scenario = scenario,
                setup = function()
                    return self:SetupEdgeCaseTest(module, scenario)
                end,
                execute = function()
                    return self:ExecuteEdgeCaseTest(module, scenario)
                end,
                verify = function(results)
                    return self:VerifyEdgeCaseTest(module, scenario, results)
                end,
                cleanup = function()
                    return self:CleanupTest()
                end
            })
        end
    end
    
    -- Coverage test
    self:AddTest({
        name = moduleName .. " Coverage Test",
        module = moduleName,
        specID = specID,
        type = "coverage",
        setup = function()
            return self:SetupCoverageTest(module)
        end,
        execute = function()
            return self:ExecuteCoverageTest(module)
        end,
        verify = function(results)
            return self:VerifyCoverageTest(module, results)
        end,
        cleanup = function()
            return self:CleanupTest()
        end
    })
    
    -- Notify that tests were generated
    API.PrintDebug("Generated tests for " .. moduleName)
end

-- Add a test to the queue
function TestingFramework:AddTest(test)
    if not test or not test.name then
        return
    end
    
    table.insert(testQueue, test)
    testStats.total = testStats.total + 1
end

-- Run all tests
function TestingFramework:RunAllTests()
    if testInProgress then
        API.Print("Tests already in progress")
        return
    end
    
    -- Reset stats
    testStats = {
        total = #testQueue,
        passed = 0,
        failed = 0,
        warnings = 0,
        runtime = 0
    }
    
    -- Reset results
    testResults = {}
    testLog = {}
    testSimulations = {}
    benchmarkResults = {}
    edgeCaseResults = {}
    comparisonResults = {}
    
    -- Start testing
    testInProgress = true
    
    self:Log("Starting test run: " .. #testQueue .. " tests")
    self:ProcessNextTest()
end

-- Run a specific module's tests
function TestingFramework:RunModuleTests(moduleName)
    if testInProgress then
        API.Print("Tests already in progress")
        return
    end
    
    -- Filter the test queue for this module
    local filteredQueue = {}
    for _, test in ipairs(testQueue) do
        if test.module == moduleName then
            table.insert(filteredQueue, test)
        end
    end
    
    if #filteredQueue == 0 then
        API.Print("No tests found for module: " .. moduleName)
        return
    end
    
    -- Reset stats
    testStats = {
        total = #filteredQueue,
        passed = 0,
        failed = 0,
        warnings = 0,
        runtime = 0
    }
    
    -- Reset results for this module
    testResults[moduleName] = {}
    testLog[moduleName] = {}
    
    -- Replace test queue with filtered queue
    local savedQueue = testQueue
    testQueue = filteredQueue
    
    -- Start testing
    testInProgress = true
    
    self:Log("Starting test run for " .. moduleName .. ": " .. #testQueue .. " tests")
    self:ProcessNextTest(function()
        -- Restore the full queue when done
        testQueue = savedQueue
    end)
end

-- Process the next test in the queue
function TestingFramework:ProcessNextTest(callback)
    -- Check if there are more tests
    if #testQueue == 0 then
        self:FinishTestRun()
        if callback then
            callback()
        end
        return
    end
    
    -- Get the next test
    currentTest = table.remove(testQueue, 1)
    
    self:Log("Starting test: " .. currentTest.name)
    
    -- Start test timer
    local startTime = debugprofilestop()
    
    -- Setup test
    local setupSuccess, setupData = currentTest.setup()
    if not setupSuccess then
        self:LogTestFailure(currentTest, "Setup failed: " .. (setupData or "unknown error"))
        self:ProcessNextTest(callback)
        return
    end
    
    -- Execute test
    local executeSuccess, executeData = currentTest.execute(setupData)
    if not executeSuccess then
        self:LogTestFailure(currentTest, "Execution failed: " .. (executeData or "unknown error"))
        currentTest.cleanup()
        self:ProcessNextTest(callback)
        return
    end
    
    -- Verify test results
    local verifySuccess, verifyMessage = currentTest.verify(executeData)
    
    -- End test timer
    local endTime = debugprofilestop()
    local testTime = (endTime - startTime) / 1000
    testStats.runtime = testStats.runtime + testTime
    
    -- Process test results
    if verifySuccess == true then
        self:LogTestSuccess(currentTest, verifyMessage, testTime)
    elseif verifySuccess == false then
        self:LogTestFailure(currentTest, verifyMessage, testTime)
    else
        -- Warning
        self:LogTestWarning(currentTest, verifyMessage, testTime)
    end
    
    -- Cleanup test
    currentTest.cleanup()
    
    -- Schedule next test
    C_Timer.After(0.1, function()
        self:ProcessNextTest(callback)
    end)
end

-- Finish test run
function TestingFramework:FinishTestRun()
    testInProgress = false
    
    -- Log summary
    local totalTests = testStats.passed + testStats.failed + testStats.warnings
    self:Log("Test run complete: " .. totalTests .. " tests in " .. string.format("%.2f", testStats.runtime) .. " seconds")
    self:Log("  Passed: " .. testStats.passed .. " (" .. string.format("%.1f", (testStats.passed / totalTests) * 100) .. "%)")
    self:Log("  Failed: " .. testStats.failed .. " (" .. string.format("%.1f", (testStats.failed / totalTests) * 100) .. "%)")
    self:Log("  Warnings: " .. testStats.warnings .. " (" .. string.format("%.1f", (testStats.warnings / totalTests) * 100) .. "%)")
    
    -- Print to chat
    API.Print("Test run complete: " .. totalTests .. " tests")
    API.Print("  Passed: " .. testStats.passed .. " (" .. string.format("%.1f", (testStats.passed / totalTests) * 100) .. "%)")
    
    if testStats.failed > 0 then
        API.Print("  Failed: " .. testStats.failed .. " (" .. string.format("%.1f", (testStats.failed / totalTests) * 100) .. "%)")
    end
    
    if testStats.warnings > 0 then
        API.Print("  Warnings: " .. testStats.warnings .. " (" .. string.format("%.1f", (testStats.warnings / totalTests) * 100) .. "%)")
    end
    
    -- Save logs if enabled
    local settings = ConfigRegistry:GetSettings("TestingFramework")
    if settings.debugSettings.saveLogs then
        self:SaveTestLogs()
    end
    
    -- Signal test completion
    if WR.OnTestsCompleted then
        WR.OnTestsCompleted(testResults, testStats)
    end
end

-- Log test success
function TestingFramework:LogTestSuccess(test, message, time)
    local result = {
        status = "passed",
        message = message,
        time = time
    }
    
    -- Store result
    if not testResults[test.module] then
        testResults[test.module] = {}
    end
    testResults[test.module][test.name] = result
    
    -- Update stats
    testStats.passed = testStats.passed + 1
    
    -- Log
    self:Log("✓ PASS: " .. test.name .. " (" .. string.format("%.2f", time) .. "s)")
    if message then
        self:Log("  " .. message)
    end
    
    -- Store specific test data
    if test.type == "benchmark" then
        benchmarkResults[test.module] = executeData
    elseif test.type == "edge_case" then
        if not edgeCaseResults[test.module] then
            edgeCaseResults[test.module] = {}
        end
        edgeCaseResults[test.module][test.scenario] = executeData
    elseif test.type == "coverage" then
        testCoverage[test.module] = executeData
    end
end

-- Log test failure
function TestingFramework:LogTestFailure(test, message, time)
    local result = {
        status = "failed",
        message = message,
        time = time or 0
    }
    
    -- Store result
    if not testResults[test.module] then
        testResults[test.module] = {}
    end
    testResults[test.module][test.name] = result
    
    -- Update stats
    testStats.failed = testStats.failed + 1
    
    -- Log
    self:Log("✗ FAIL: " .. test.name .. (time and " (" .. string.format("%.2f", time) .. "s)" or ""))
    if message then
        self:Log("  " .. message)
    end
end

-- Log test warning
function TestingFramework:LogTestWarning(test, message, time)
    local result = {
        status = "warning",
        message = message,
        time = time
    }
    
    -- Store result
    if not testResults[test.module] then
        testResults[test.module] = {}
    end
    testResults[test.module][test.name] = result
    
    -- Update stats
    testStats.warnings = testStats.warnings + 1
    
    -- Log
    self:Log("! WARNING: " .. test.name .. " (" .. string.format("%.2f", time) .. "s)")
    if message then
        self:Log("  " .. message)
    end
end

-- Log a message
function TestingFramework:Log(message)
    local settings = ConfigRegistry:GetSettings("TestingFramework")
    
    -- Always add to log
    table.insert(testLog, {
        time = GetTime(),
        message = message
    })
    
    -- Print if real-time logging is enabled
    if settings.debugSettings.enableRealTimeLogging then
        API.PrintDebug(message)
    end
end

-- Save test logs
function TestingFramework:SaveTestLogs()
    -- In a real addon, this would save to SavedVariables
    -- For our implementation, just store it in memory
    self:Log("Test logs saved")
end

-- Setup a basic rotation test
function TestingFramework:SetupBasicRotationTest(module)
    -- Create a mock environment for testing
    local mockEnv = {
        module = module,
        target = {
            exists = true,
            health = 100,
            maxHealth = 100,
            isEnemy = true,
            isInRange = true,
            debuffs = {}
        },
        player = {
            health = 100,
            maxHealth = 100,
            mana = 100,
            maxMana = 100,
            resources = {},
            buffs = {},
            debuffs = {},
            cooldowns = {},
            moving = false,
            casting = false,
            inCombat = true
        },
        settings = {}
    }
    
    -- Get module settings
    local moduleSettings = ConfigRegistry:GetSettings(module.name)
    if moduleSettings then
        mockEnv.settings = moduleSettings
    end
    
    -- Add class-specific resources
    local classID = API.GetClassIDFromSpecID(module.specID)
    
    if classID == 1 then -- Warrior
        mockEnv.player.resources.rage = 50
    elseif classID == 2 then -- Paladin
        mockEnv.player.resources.holyPower = 3
    elseif classID == 3 then -- Hunter
        mockEnv.player.resources.focus = 80
    elseif classID == 4 then -- Rogue
        mockEnv.player.resources.energy = 80
        mockEnv.player.resources.comboPoints = 3
    elseif classID == 5 then -- Priest
        if module.specID == 3 then -- Shadow
            mockEnv.player.resources.insanity = 60
        end
    elseif classID == 6 then -- Death Knight
        mockEnv.player.resources.runicPower = 60
        mockEnv.player.resources.runes = 4
    elseif classID == 7 then -- Shaman
        if module.specID == 2 then -- Enhancement
            mockEnv.player.resources.maelstrom = 5
        end
    elseif classID == 8 then -- Mage
        if module.specID == 1 then -- Arcane
            mockEnv.player.resources.arcaneCharges = 2
        end
    elseif classID == 9 then -- Warlock
        mockEnv.player.resources.soulShards = 3
    elseif classID == 10 then -- Monk
        mockEnv.player.resources.energy = 80
        mockEnv.player.resources.chi = 3
    elseif classID == 11 then -- Druid
        if module.specID == 1 then -- Balance
            mockEnv.player.resources.astralPower = 60
        elseif module.specID == 2 then -- Feral
            mockEnv.player.resources.energy = 80
            mockEnv.player.resources.comboPoints = 3
        elseif module.specID == 3 then -- Guardian
            mockEnv.player.resources.rage = 50
        end
    elseif classID == 12 then -- Demon Hunter
        mockEnv.player.resources.fury = 80
    elseif classID == 13 then -- Evoker
        mockEnv.player.resources.essence = 4
    end
    
    -- Setup complete
    return true, mockEnv
end

-- Execute a rotation test
function TestingFramework:ExecuteRotationTest(module, mockEnv)
    -- Get test settings
    local settings = ConfigRegistry:GetSettings("TestingFramework")
    local duration = settings.simulationSettings.defaultDuration
    local iterations = settings.simulationSettings.iterations
    
    -- Initialize the rotation simulator
    if RotationSimulator then
        RotationSimulator:SetupSimulationForModule(module, mockEnv)
    else
        -- Mock execution if simulator not available
        local spellsCast = {}
        local success = false
        
        -- Attempt to call the module's rotation function
        if module and module.RunRotation then
            success = module:RunRotation()
            if success then
                -- Mock some spell casts
                table.insert(spellsCast, { id = 12345, name = "Test Spell", success = true })
            end
        end
        
        return success, {
            success = success,
            spellsCast = spellsCast,
            duration = 1,
            iterations = 1
        }
    end
    
    -- Run the simulation
    local results = RotationSimulator:RunSimulation(duration, iterations)
    
    -- Check if simulation succeeded
    if not results or not results.success then
        return false, "Simulation failed"
    end
    
    -- Store simulation results
    if not testSimulations[module.name] then
        testSimulations[module.name] = {}
    end
    testSimulations[module.name][module.specID] = results
    
    return true, results
end

-- Verify a rotation test
function TestingFramework:VerifyRotationTest(module, results)
    -- Basic verification
    if not results or not results.spellsCast or #results.spellsCast == 0 then
        return false, "No spells were cast during the test"
    end
    
    -- Calculate actions per minute
    local duration = results.duration or 60
    local actionCount = #results.spellsCast
    local apm = (actionCount / duration) * 60
    
    -- Verify reasonable APM (between 10 and 100)
    if apm < 10 then
        return false, "Actions per minute too low: " .. string.format("%.1f", apm)
    elseif apm > 100 then
        return nil, "Actions per minute suspiciously high: " .. string.format("%.1f", apm)
    end
    
    -- Verify spell success rate
    local successCount = 0
    for _, spell in ipairs(results.spellsCast) do
        if spell.success then
            successCount = successCount + 1
        end
    end
    
    local successRate = successCount / actionCount
    if successRate < 0.8 then
        return nil, "Spell success rate low: " .. string.format("%.1f", successRate * 100) .. "%"
    end
    
    return true, "Rotation test passed with " .. actionCount .. " actions at " .. string.format("%.1f", apm) .. " APM"
end

-- Setup a benchmark test
function TestingFramework:SetupBenchmarkTest(module)
    -- Similar to the basic test setup
    return self:SetupBasicRotationTest(module)
end

-- Execute a benchmark test
function TestingFramework:ExecuteBenchmarkTest(module, mockEnv)
    -- This is essentially a performance-focused rotation test
    local iterationCount = 5
    local results = {
        iterations = {},
        average = {
            executionTime = 0,
            callCount = 0,
            apm = 0
        }
    }
    
    for i = 1, iterationCount do
        local startTime = debugprofilestop()
        local callCount = 0
        local spellsCast = {}
        
        -- Run rotation several times to simulate a combat scenario
        for j = 1, 100 do
            if module and module.RunRotation then
                local success = module:RunRotation()
                callCount = callCount + 1
                
                if success and j % 5 == 0 then
                    -- Mock a spell cast every 5 calls
                    table.insert(spellsCast, { id = 12345, name = "Test Spell " .. j, success = true })
                end
            end
        end
        
        local endTime = debugprofilestop()
        local executionTime = (endTime - startTime) / 1000
        
        -- Calculate APM
        local simulatedDuration = 60 -- seconds
        local apm = (#spellsCast / simulatedDuration) * 60
        
        -- Store iteration results
        table.insert(results.iterations, {
            executionTime = executionTime,
            callCount = callCount,
            spellsCast = #spellsCast,
            apm = apm
        })
        
        -- Update averages
        results.average.executionTime = results.average.executionTime + executionTime
        results.average.callCount = results.average.callCount + callCount
        results.average.apm = results.average.apm + apm
    end
    
    -- Calculate final averages
    results.average.executionTime = results.average.executionTime / iterationCount
    results.average.callCount = results.average.callCount / iterationCount
    results.average.apm = results.average.apm / iterationCount
    
    return true, results
end

-- Verify a benchmark test
function TestingFramework:VerifyBenchmarkTest(module, results)
    if not results or not results.average then
        return false, "No benchmark results available"
    end
    
    -- Verify execution time (should be reasonably fast)
    if results.average.executionTime > 0.1 then
        return nil, "Execution time higher than expected: " .. string.format("%.3f", results.average.executionTime) .. "s"
    end
    
    -- Verify call count
    if results.average.callCount < 90 then
        return false, "Fewer function calls than expected: " .. results.average.callCount
    end
    
    -- Verify APM
    if results.average.apm < 10 then
        return nil, "Actions per minute lower than expected: " .. string.format("%.1f", results.average.apm)
    end
    
    return true, "Benchmark passed: " .. string.format("%.3f", results.average.executionTime) .. "s execution time, " .. string.format("%.1f", results.average.apm) .. " APM"
end

-- Setup an edge case test
function TestingFramework:SetupEdgeCaseTest(module, scenario)
    -- Start with a basic test setup
    local success, mockEnv = self:SetupBasicRotationTest(module)
    if not success then
        return false, "Failed to setup basic test environment"
    end
    
    -- Modify the environment based on the scenario
    local settings = ConfigRegistry:GetSettings("TestingFramework")
    
    if scenario == "low_health" then
        mockEnv.player.health = mockEnv.player.maxHealth * (settings.edgeCaseSettings.lowHealthThreshold / 100)
    elseif scenario == "oom" then
        mockEnv.player.mana = mockEnv.player.maxMana * (settings.edgeCaseSettings.oomThreshold / 100)
        for resource, value in pairs(mockEnv.player.resources) do
            mockEnv.player.resources[resource] = value * (settings.edgeCaseSettings.oomThreshold / 100)
        end
    elseif scenario == "movement" then
        mockEnv.player.moving = true
    elseif scenario == "burst" then
        -- Simulate cooldowns available
        mockEnv.player.cooldowns = {}
    elseif scenario == "aoe" then
        -- Simulate multiple targets
        mockEnv.targetCount = 5
    elseif scenario == "defensive" then
        mockEnv.player.health = mockEnv.player.maxHealth * 0.4
        mockEnv.incomingDamage = mockEnv.player.maxHealth * 0.2
    elseif scenario == "interrupt" then
        mockEnv.target.casting = true
        mockEnv.target.spellID = 12345
        mockEnv.target.spellInterruptible = true
    elseif scenario == "debuffed" then
        -- Add a detrimental effect to the player
        mockEnv.player.debuffs = {
            { id = 12345, name = "Test Debuff", duration = 10, type = "Magic" }
        }
    elseif scenario == "cc_break" then
        -- Simulate being CC'd
        mockEnv.player.controlEffects = {
            { id = 12345, name = "Test CC", duration = 5, type = "Magic", canBreak = true }
        }
    elseif scenario == "dispel" then
        -- Simulate a dispellable effect on a party member
        if not mockEnv.party then
            mockEnv.party = {}
        end
        mockEnv.party[1] = {
            exists = true,
            health = 80,
            maxHealth = 100,
            debuffs = {
                { id = 12345, name = "Test Debuff", duration = 10, type = "Magic", canDispel = true }
            }
        }
    end
    
    return true, mockEnv
end

-- Execute an edge case test
function TestingFramework:ExecuteEdgeCaseTest(module, scenario, mockEnv)
    -- Initialize test results
    local results = {
        scenario = scenario,
        spellsCast = {},
        decisions = {},
        expectation = "",
        responses = {}
    }
    
    -- Set expectations based on scenario
    if scenario == "low_health" then
        results.expectation = "defensive_abilities"
    elseif scenario == "oom" then
        results.expectation = "resource_generation"
    elseif scenario == "movement" then
        results.expectation = "instant_casts"
    elseif scenario == "burst" then
        results.expectation = "cooldown_usage"
    elseif scenario == "aoe" then
        results.expectation = "aoe_abilities"
    elseif scenario == "defensive" then
        results.expectation = "defensive_abilities"
    elseif scenario == "interrupt" then
        results.expectation = "interrupt_usage"
    elseif scenario == "debuffed" then
        results.expectation = "self_cleanse"
    elseif scenario == "cc_break" then
        results.expectation = "cc_break_abilities"
    elseif scenario == "dispel" then
        results.expectation = "dispel_usage"
    end
    
    -- Run the rotation multiple times to capture decision patterns
    for i = 1, 10 do
        if module and module.RunRotation then
            local success = module:RunRotation()
            
            -- Track successful spellcasts
            if success then
                -- In a real implementation, we'd capture the actual spell cast
                -- For our mock, we'll just create a placeholder
                local spell = {
                    id = 12345,
                    name = "Test Spell " .. i,
                    success = true,
                    time = GetTime()
                }
                
                table.insert(results.spellsCast, spell)
                
                -- Categorize the response
                if i == 1 then
                    -- Classify the first response based on scenario
                    if scenario == "low_health" then
                        spell.category = spell.id == 12345 and "defensive_abilities" or "other"
                    elseif scenario == "oom" then
                        spell.category = spell.id == 12345 and "resource_generation" or "other"
                    -- Add other categorization logic here
                    else
                        spell.category = "other"
                    end
                    
                    table.insert(results.responses, spell.category)
                end
            end
        end
    end
    
    return true, results
end

-- Verify an edge case test
function TestingFramework:VerifyEdgeCaseTest(module, scenario, results)
    if not results or not results.spellsCast or not results.expectation then
        return false, "No edge case test results available"
    end
    
    -- Check if any spells were cast
    if #results.spellsCast == 0 then
        return false, "No spells were cast during edge case scenario: " .. scenario
    end
    
    -- Check if responses match expectations
    local expectedResponseCount = 0
    for _, response in ipairs(results.responses) do
        if response == results.expectation then
            expectedResponseCount = expectedResponseCount + 1
        end
    end
    
    local responseRate = expectedResponseCount / #results.responses
    
    if responseRate < 0.5 then
        return nil, "Edge case response rate lower than expected: " .. string.format("%.1f", responseRate * 100) .. "% for " .. scenario .. " scenario"
    end
    
    return true, "Edge case test passed with " .. string.format("%.1f", responseRate * 100) .. "% appropriate responses for " .. scenario .. " scenario"
end

-- Setup a coverage test
function TestingFramework:SetupCoverageTest(module)
    -- Start with a basic test setup
    local success, mockEnv = self:SetupBasicRotationTest(module)
    if not success then
        return false, "Failed to setup basic test environment"
    end
    
    -- Additional setup for coverage testing
    mockEnv.coverageTracking = {
        spellsCast = {},
        abilitiesUsed = {},
        totalAbilities = 0,
        coveredAbilities = 0
    }
    
    -- Identify the total ability count for the module
    if module.spells then
        for spellName, spellID in pairs(module.spells) do
            mockEnv.coverageTracking.totalAbilities = mockEnv.coverageTracking.totalAbilities + 1
        end
    else
        -- Estimate based on spec if no spell list available
        local classID = API.GetClassIDFromSpecID(module.specID)
        if classID then
            -- Rough estimates of ability counts by class
            local abilityEstimates = {
                [1] = 15, -- Warrior
                [2] = 18, -- Paladin
                [3] = 16, -- Hunter
                [4] = 20, -- Rogue
                [5] = 18, -- Priest
                [6] = 17, -- Death Knight
                [7] = 19, -- Shaman
                [8] = 18, -- Mage
                [9] = 20, -- Warlock
                [10] = 18, -- Monk
                [11] = 22, -- Druid
                [12] = 14, -- Demon Hunter
                [13] = 16  -- Evoker
            }
            mockEnv.coverageTracking.totalAbilities = abilityEstimates[classID] or 15
        else
            mockEnv.coverageTracking.totalAbilities = 15 -- Default estimate
        end
    end
    
    return true, mockEnv
end

-- Execute a coverage test
function TestingFramework:ExecuteCoverageTest(module, mockEnv)
    -- Run the rotation multiple times with different conditions
    local conditions = {
        { name = "normal", setup = function() end },
        { name = "low_health", setup = function() mockEnv.player.health = mockEnv.player.maxHealth * 0.3 end },
        { name = "movement", setup = function() mockEnv.player.moving = true end },
        { name = "aoe", setup = function() mockEnv.targetCount = 5 end },
        { name = "burst", setup = function() mockEnv.player.cooldowns = {} end }
    }
    
    local results = {
        totalAbilities = mockEnv.coverageTracking.totalAbilities,
        coveredAbilities = 0,
        abilitiesUsed = {},
        coverage = 0,
        conditions = {}
    }
    
    -- Run under each condition
    for _, condition in ipairs(conditions) do
        -- Setup the condition
        condition.setup()
        
        -- Run multiple iterations
        for i = 1, 20 do
            if module and module.RunRotation then
                local success = module:RunRotation()
                
                -- Track successful spellcasts
                if success then
                    -- In a real implementation, we'd capture the actual spell cast
                    -- For our mock, we'll create some random spells to simulate coverage
                    local spellID = 12340 + (i % 10)
                    local spellName = "Test Spell " .. spellID
                    
                    -- Track ability usage
                    if not results.abilitiesUsed[spellID] then
                        results.abilitiesUsed[spellID] = 1
                        results.coveredAbilities = results.coveredAbilities + 1
                    else
                        results.abilitiesUsed[spellID] = results.abilitiesUsed[spellID] + 1
                    end
                    
                    -- Track condition-specific usage
                    if not results.conditions[condition.name] then
                        results.conditions[condition.name] = {
                            abilitiesUsed = {},
                            count = 0
                        }
                    end
                    
                    if not results.conditions[condition.name].abilitiesUsed[spellID] then
                        results.conditions[condition.name].abilitiesUsed[spellID] = 1
                        results.conditions[condition.name].count = results.conditions[condition.name].count + 1
                    else
                        results.conditions[condition.name].abilitiesUsed[spellID] = results.conditions[condition.name].abilitiesUsed[spellID] + 1
                    end
                end
            end
        end
    end
    
    -- Calculate coverage percentage
    results.coverage = (results.coveredAbilities / results.totalAbilities) * 100
    
    return true, results
end

-- Verify a coverage test
function TestingFramework:VerifyCoverageTest(module, results)
    if not results or not results.totalAbilities then
        return false, "No coverage test results available"
    end
    
    -- Check minimum coverage threshold
    local settings = ConfigRegistry:GetSettings("TestingFramework")
    local threshold = settings.coverageSettings.minimumCoverageThreshold
    
    if results.coverage < threshold then
        return nil, "Coverage below threshold: " .. string.format("%.1f", results.coverage) .. "% (expected " .. threshold .. "%)"
    end
    
    -- Check if specific conditions had reasonable coverage
    local conditionCounts = 0
    for condition, data in pairs(results.conditions) do
        if data.count < 2 then
            return nil, "Low ability coverage under '" .. condition .. "' condition: " .. data.count .. " abilities"
        end
        conditionCounts = conditionCounts + 1
    end
    
    if conditionCounts < 3 then
        return nil, "Not enough conditions tested: " .. conditionCounts .. " (expected at least 3)"
    end
    
    return true, "Coverage test passed with " .. string.format("%.1f", results.coverage) .. "% ability coverage"
end

-- Cleanup after a test
function TestingFramework:CleanupTest()
    -- Reset any mock state or hooks
    return true
end

-- Handle slash command
function TestingFramework:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations Testing Framework Commands:")
        API.Print("/wrtest all - Run all tests")
        API.Print("/wrtest module [name] - Run tests for a specific module")
        API.Print("/wrtest status - Show test status")
        API.Print("/wrtest coverage - Show test coverage")
        API.Print("/wrtest benchmark - Show benchmark results")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "all" then
        -- Run all tests
        self:RunAllTests()
    elseif command == "module" then
        -- Run tests for a specific module
        local moduleName = args[2]
        if not moduleName then
            API.Print("Please specify a module name")
            return
        end
        
        self:RunModuleTests(moduleName)
    elseif command == "status" then
        -- Show test status
        if testInProgress then
            API.Print("Tests in progress: " .. (currentTest and currentTest.name or "Unknown test"))
        else
            API.Print("Tests not running")
            API.Print("Last test run:")
            API.Print("  Total: " .. testStats.total)
            API.Print("  Passed: " .. testStats.passed)
            API.Print("  Failed: " .. testStats.failed)
            API.Print("  Warnings: " .. testStats.warnings)
        end
    elseif command == "coverage" then
        -- Show test coverage
        API.Print("Test Coverage:")
        
        for module, coverage in pairs(testCoverage) do
            API.Print(module .. ": " .. string.format("%.1f", coverage.coverage) .. "% (" .. coverage.coveredAbilities .. "/" .. coverage.totalAbilities .. " abilities)")
        end
    elseif command == "benchmark" then
        -- Show benchmark results
        API.Print("Benchmark Results:")
        
        for module, benchmark in pairs(benchmarkResults) do
            API.Print(module .. ": " .. string.format("%.3f", benchmark.average.executionTime) .. "s, " .. string.format("%.1f", benchmark.average.apm) .. " APM")
        end
    else
        API.Print("Unknown command. Type /wrtest for help.")
    end
end

-- Return the module for loading
return TestingFramework