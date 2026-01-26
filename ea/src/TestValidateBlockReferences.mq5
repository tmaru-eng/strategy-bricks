//+------------------------------------------------------------------+
//|                                  TestValidateBlockReferences.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                Test ValidateBlockReferences function              |
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
    Print("=== Testing ValidateBlockReferences Function ===");
    
    CLogger logger;
    logger.Initialize("TestValidateBlockReferences", "test_validate_block_refs");
    
    CConfigLoader loader;
    loader.SetLogger(&logger);
    Config config;
    
    // Test 1: Valid configuration (should pass)
    Print("\n--- Test 1: Valid Configuration ---");
    config.Reset();
    if (loader.Load("StrategyBricks/test_single_blocks.json", config)) {
        Print("✓ Test 1 PASSED: Valid configuration loaded successfully");
    } else {
        Print("✗ Test 1 FAILED: Valid configuration should load successfully");
    }
    
    // Test 2: Invalid configuration with unresolved block reference (should fail)
    Print("\n--- Test 2: Invalid Configuration (Unresolved Block Reference) ---");
    config.Reset();
    if (!loader.Load("StrategyBricks/test_invalid_block_references.json", config)) {
        Print("✓ Test 2 PASSED: Invalid configuration correctly rejected");
    } else {
        Print("✗ Test 2 FAILED: Invalid configuration should be rejected");
    }
    
    // Test 3: Configuration with shared blocks (should pass)
    Print("\n--- Test 3: Configuration with Shared Blocks ---");
    config.Reset();
    if (loader.Load("StrategyBricks/test_strategy_advanced.json", config)) {
        Print("✓ Test 3 PASSED: Configuration with shared blocks loaded successfully");
    } else {
        Print("✗ Test 3 FAILED: Configuration with shared blocks should load successfully");
    }
    
    logger.Cleanup();
    Print("\n=== Test Complete ===");
}
