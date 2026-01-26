//+------------------------------------------------------------------+
//|                                    TestValidateBlockIdFormat.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                           ValidateBlockIdFormat関数のテスト         |
//+------------------------------------------------------------------+
#property copyright "Strategy Bricks EA MVP"
#property link      ""
#property version   "1.00"
#property script_show_inputs

#include "../include/Config/ConfigLoader.mqh"
#include "../include/Support/Logger.mqh"

//+------------------------------------------------------------------+
//| スクリプトプログラム開始関数                                          |
//+------------------------------------------------------------------+
void OnStart() {
    Print("=== Testing ValidateBlockIdFormat Function ===");
    Print("");
    
    // ロガー初期化
    CLogger logger;
    logger.Init("TestValidateBlockIdFormat", "M1");
    
    // ConfigLoader初期化
    CConfigLoader loader;
    loader.SetLogger(&logger);
    
    bool allTestsPassed = true;
    
    // Test 1: 有効な設定（正しい形式のblockId）
    Print("--- Test 1: Valid Configuration (Proper Format) ---");
    {
        Config config;
        bool result = loader.Load("StrategyBricks/test_single_blocks.json", config);
        
        if (result) {
            Print("✓ Test 1 PASSED: Valid configuration with proper blockId format loaded successfully");
        } else {
            Print("✗ Test 1 FAILED: Valid configuration should have loaded");
            allTestsPassed = false;
        }
    }
    Print("");
    
    // Test 2: 無効な設定（'#'セパレータなし）
    Print("--- Test 2: Invalid Configuration (Missing '#' Separator) ---");
    {
        Config config;
        bool result = loader.Load("StrategyBricks/test_invalid_block_id_no_separator.json", config);
        
        if (!result) {
            Print("✓ Test 2 PASSED: Configuration with missing '#' separator correctly rejected");
        } else {
            Print("✗ Test 2 FAILED: Configuration with missing '#' separator should have been rejected");
            allTestsPassed = false;
        }
    }
    Print("");
    
    // Test 3: 無効な設定（非数値インデックス）
    Print("--- Test 3: Invalid Configuration (Non-Numeric Index) ---");
    {
        Config config;
        bool result = loader.Load("StrategyBricks/test_invalid_block_id_non_numeric.json", config);
        
        if (!result) {
            Print("✓ Test 3 PASSED: Configuration with non-numeric index correctly rejected");
        } else {
            Print("✗ Test 3 FAILED: Configuration with non-numeric index should have been rejected");
            allTestsPassed = false;
        }
    }
    Print("");
    
    // Test 4: 有効な設定（複数の正しい形式のblockId）
    Print("--- Test 4: Configuration with Multiple Valid BlockIds ---");
    {
        Config config;
        bool result = loader.Load("StrategyBricks/test_strategy_advanced.json", config);
        
        if (result) {
            Print("✓ Test 4 PASSED: Configuration with multiple valid blockIds loaded successfully");
        } else {
            Print("✗ Test 4 FAILED: Configuration with multiple valid blockIds should have loaded");
            allTestsPassed = false;
        }
    }
    Print("");
    
    // 最終結果
    Print("=== Test Complete ===");
    if (allTestsPassed) {
        Print("✓ ALL TESTS PASSED");
    } else {
        Print("✗ SOME TESTS FAILED");
    }
}
//+------------------------------------------------------------------+
