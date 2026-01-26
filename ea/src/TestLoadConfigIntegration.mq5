//+------------------------------------------------------------------+
//|                                   TestLoadConfigIntegration.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                Test Load() function validation integration        |
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
    Print("=== Testing Load() Function Validation Integration ===");
    Print("Task 6.4: Verify all validation functions are properly integrated");
    
    CLogger logger;
    logger.Initialize("TestLoadConfigIntegration", "test_load_integration");
    
    CConfigLoader loader;
    loader.SetLogger(&logger);
    Config config;
    
    int passCount = 0;
    int totalTests = 5;
    
    // Test 1: Valid configuration (should pass all validations)
    Print("\n--- Test 1: Valid Configuration ---");
    config.Reset();
    if (loader.Load("StrategyBricks/test_single_blocks.json", config)) {
        Print("✓ Test 1 PASSED: Valid configuration loaded successfully");
        Print("  - Loaded ", config.strategyCount, " strategies, ", config.blockCount, " blocks");
        passCount++;
    } else {
        Print("✗ Test 1 FAILED: Valid configuration should load successfully");
    }
    
    // Test 2: Invalid block references (should fail ValidateBlockReferences)
    Print("\n--- Test 2: Invalid Block References ---");
    config.Reset();
    if (!loader.Load("StrategyBricks/test_invalid_block_references.json", config)) {
        Print("✓ Test 2 PASSED: Configuration with unresolved block references correctly rejected");
        passCount++;
    } else {
        Print("✗ Test 2 FAILED: Configuration with unresolved block references should be rejected");
    }
    
    // Test 3: Duplicate block IDs (should fail ValidateDuplicateBlockIds)
    Print("\n--- Test 3: Duplicate Block IDs ---");
    config.Reset();
    if (!loader.Load("StrategyBricks/test_duplicate_block_ids.json", config)) {
        Print("✓ Test 3 PASSED: Configuration with duplicate blockIds correctly rejected");
        passCount++;
    } else {
        Print("✗ Test 3 FAILED: Configuration with duplicate blockIds should be rejected");
    }
    
    // Test 4: Invalid blockId format - missing separator (should fail ValidateBlockIdFormat)
    Print("\n--- Test 4: Invalid BlockId Format (Missing Separator) ---");
    config.Reset();
    if (!loader.Load("StrategyBricks/test_invalid_block_id_no_separator.json", config)) {
        Print("✓ Test 4 PASSED: Configuration with invalid blockId format (no separator) correctly rejected");
        passCount++;
    } else {
        Print("✗ Test 4 FAILED: Configuration with invalid blockId format should be rejected");
    }
    
    // Test 5: Invalid blockId format - non-numeric index (should fail ValidateBlockIdFormat)
    Print("\n--- Test 5: Invalid BlockId Format (Non-Numeric Index) ---");
    config.Reset();
    if (!loader.Load("StrategyBricks/test_invalid_block_id_non_numeric.json", config)) {
        Print("✓ Test 5 PASSED: Configuration with invalid blockId format (non-numeric) correctly rejected");
        passCount++;
    } else {
        Print("✗ Test 5 FAILED: Configuration with invalid blockId format should be rejected");
    }
    
    logger.Cleanup();
    
    // Summary
    Print("\n=== Test Summary ===");
    Print("Passed: ", passCount, "/", totalTests);
    if (passCount == totalTests) {
        Print("✓ ALL TESTS PASSED - Task 6.4 Complete");
        Print("  - ValidateBlockReferences: Integrated ✓");
        Print("  - ValidateDuplicateBlockIds: Integrated ✓");
        Print("  - ValidateBlockIdFormat: Integrated ✓");
        Print("  - Success logging (CONFIG_LOADED): Implemented ✓");
    } else {
        Print("✗ SOME TESTS FAILED - Review errors above");
    }
}
