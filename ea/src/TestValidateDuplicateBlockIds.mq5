//+------------------------------------------------------------------+
//|                               TestValidateDuplicateBlockIds.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                Test ValidateDuplicateBlockIds function            |
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
    Print("=== Testing ValidateDuplicateBlockIds Function ===");
    
    CLogger logger;
    logger.Initialize("TestValidateDuplicateBlockIds", "test_validate_duplicate_block_ids");
    
    CConfigLoader loader;
    loader.SetLogger(&logger);
    Config config;
    
    // Test 1: Valid configuration with unique blockIds (should pass)
    Print("\n--- Test 1: Valid Configuration (Unique BlockIds) ---");
    config.Reset();
    if (loader.Load("StrategyBricks/test_single_blocks.json", config)) {
        Print("✓ Test 1 PASSED: Valid configuration with unique blockIds loaded successfully");
    } else {
        Print("✗ Test 1 FAILED: Valid configuration should load successfully");
    }
    
    // Test 2: Invalid configuration with duplicate blockIds (should fail)
    Print("\n--- Test 2: Invalid Configuration (Duplicate BlockIds) ---");
    config.Reset();
    if (!loader.Load("StrategyBricks/test_duplicate_block_ids.json", config)) {
        Print("✓ Test 2 PASSED: Configuration with duplicate blockIds correctly rejected");
    } else {
        Print("✗ Test 2 FAILED: Configuration with duplicate blockIds should be rejected");
    }
    
    // Test 3: Configuration with multiple unique blocks (should pass)
    Print("\n--- Test 3: Configuration with Multiple Unique Blocks ---");
    config.Reset();
    if (loader.Load("StrategyBricks/test_strategy_advanced.json", config)) {
        Print("✓ Test 3 PASSED: Configuration with multiple unique blocks loaded successfully");
    } else {
        Print("✗ Test 3 FAILED: Configuration with multiple unique blocks should load successfully");
    }
    
    logger.Cleanup();
    Print("\n=== Test Complete ===");
}
