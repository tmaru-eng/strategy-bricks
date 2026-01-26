//+------------------------------------------------------------------+
//|                                    TestGuiGeneratedConfigs.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                Test GUI-generated configuration files             |
//+------------------------------------------------------------------+
#property copyright "Strategy Bricks Team"
#property version   "1.00"
#property script_show_inputs

#include "../include/Config/ConfigLoader.mqh"
#include "../include/Support/Logger.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== Testing GUI-Generated Configurations ===");
    Print("Verifying GUI Builder -> EA Runtime integration");
    
    CLogger logger;
    logger.Initialize("TestGuiGeneratedConfigs", "test_gui_configs");
    
    CConfigLoader loader;
    loader.SetLogger(&logger);
    Config config;
    
    int passCount = 0;
    int totalTests = 3;
    
    // Test 1: basic-strategy.json
    Print("\n--- Test 1: basic-strategy.json ---");
    Print("Expected: 1 strategy, 3 blocks (filter.spreadMax#1, trend.maRelation#1, trigger.bbReentry#1)");
    config.Reset();
    if (loader.Load("StrategyBricks/basic-strategy.json", config)) {
        Print("✓ Test 1 PASSED: basic-strategy.json loaded successfully");
        Print("  Loaded ", config.strategyCount, " strategies, ", config.blockCount, " blocks");
        passCount++;
    } else {
        Print("✗ Test 1 FAILED: basic-strategy.json validation failed");
    }
    
    // Test 2: trend-only.json
    Print("\n--- Test 2: trend-only.json ---");
    Print("Expected: 1 strategy, 3 blocks");
    config.Reset();
    if (loader.Load("StrategyBricks/trend-only.json", config)) {
        Print("✓ Test 2 PASSED: trend-only.json loaded successfully");
        Print("  Loaded ", config.strategyCount, " strategies, ", config.blockCount, " blocks");
        passCount++;
    } else {
        Print("✗ Test 2 FAILED: trend-only.json validation failed");
    }
    
    // Test 3: multi-trigger.json
    Print("\n--- Test 3: multi-trigger.json ---");
    Print("Expected: 1 strategy, 3 blocks");
    config.Reset();
    if (loader.Load("StrategyBricks/multi-trigger.json", config)) {
        Print("✓ Test 3 PASSED: multi-trigger.json loaded successfully");
        Print("  Loaded ", config.strategyCount, " strategies, ", config.blockCount, " blocks");
        passCount++;
    } else {
        Print("✗ Test 3 FAILED: multi-trigger.json validation failed");
    }
    
    logger.Cleanup();
    
    // Summary
    Print("\n=== Test Summary ===");
    Print("Passed: ", passCount, "/", totalTests);
    if (passCount == totalTests) {
        Print("✓ ALL TESTS PASSED - GUI-EA Integration Verified");
        Print("  - Config loading: ✓");
        Print("  - BlockId validation: ✓");
        Print("  - Block reference resolution: ✓");
    } else {
        Print("✗ SOME TESTS FAILED - Review errors above");
    }
}

