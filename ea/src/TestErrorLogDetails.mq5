//+------------------------------------------------------------------+
//|                                           TestErrorLogDetails.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                           Task 7.2: Error Log Detail Verification |
//+------------------------------------------------------------------+
#property copyright "Strategy Bricks EA MVP"
#property version   "1.00"
#property strict

#include "../include/Config/ConfigLoader.mqh"
#include "../include/Support/Logger.mqh"

//+------------------------------------------------------------------+
//| Test: Verify error logs include detailed information             |
//+------------------------------------------------------------------+
void TestErrorLogDetails() {
    Print("=== Task 7.2: Error Log Detail Verification ===");
    Print("");
    
    // Initialize logger
    CLogger logger;
    if (!logger.Initialize("strategy/logs/test_error_details_")) {
        Print("ERROR: Failed to initialize logger");
        return;
    }
    
    // Initialize ConfigLoader
    CConfigLoader loader;
    loader.SetLogger(&logger);
    
    Print("--- Test 1: UNRESOLVED_BLOCK_REFERENCE ---");
    Print("Expected: Log should include blockId, strategy ID, and ruleGroup ID");
    Print("");
    
    // Create config with unresolved block reference
    Config config1;
    config1.Reset();
    
    // Add one block
    config1.blockCount = 1;
    config1.blocks[0].id = "filter.spreadMax#1";
    config1.blocks[0].typeId = "filter.spreadMax";
    
    // Add strategy with reference to non-existent block
    config1.strategyCount = 1;
    config1.strategies[0].id = "TestStrategy1";
    config1.strategies[0].entryRequirement.ruleGroupCount = 1;
    config1.strategies[0].entryRequirement.ruleGroups[0].id = "TestRuleGroup1";
    config1.strategies[0].entryRequirement.ruleGroups[0].conditionCount = 1;
    config1.strategies[0].entryRequirement.ruleGroups[0].conditions[0].blockId = "filter.spreadMax#999"; // Does not exist
    
    // Create test config file
    string testFile1 = "strategy/test_unresolved_ref.json";
    int handle1 = FileOpen(testFile1, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if (handle1 != INVALID_HANDLE) {
        FileWriteString(handle1, "{\n");
        FileWriteString(handle1, "  \"meta\": {\"formatVersion\": \"1.0\"},\n");
        FileWriteString(handle1, "  \"strategies\": [{\"id\": \"TestStrategy1\", \"entryRequirement\": {\"ruleGroups\": [{\"id\": \"TestRuleGroup1\", \"conditions\": [{\"blockId\": \"filter.spreadMax#999\"}]}]}}],\n");
        FileWriteString(handle1, "  \"blocks\": [{\"id\": \"filter.spreadMax#1\", \"typeId\": \"filter.spreadMax\", \"params\": {}}]\n");
        FileWriteString(handle1, "}\n");
        FileClose(handle1);
        
        Config testConfig1;
        bool result1 = loader.Load(testFile1, testConfig1);
        Print("Result: ", result1 ? "PASS (unexpected)" : "FAIL (expected)");
        Print("Check log file for: UNRESOLVED_BLOCK_REFERENCE with blockId='filter.spreadMax#999', Strategy='TestStrategy1', RuleGroup='TestRuleGroup1'");
        Print("");
        
        FileDelete(testFile1, FILE_COMMON);
    }
    
    Print("--- Test 2: DUPLICATE_BLOCK_ID ---");
    Print("Expected: Log should include blockId and array indices");
    Print("");
    
    // Create test config file with duplicate blockIds
    string testFile2 = "strategy/test_duplicate_blockid.json";
    int handle2 = FileOpen(testFile2, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if (handle2 != INVALID_HANDLE) {
        FileWriteString(handle2, "{\n");
        FileWriteString(handle2, "  \"meta\": {\"formatVersion\": \"1.0\"},\n");
        FileWriteString(handle2, "  \"strategies\": [],\n");
        FileWriteString(handle2, "  \"blocks\": [\n");
        FileWriteString(handle2, "    {\"id\": \"filter.spreadMax#1\", \"typeId\": \"filter.spreadMax\", \"params\": {}},\n");
        FileWriteString(handle2, "    {\"id\": \"trend.maRelation#1\", \"typeId\": \"trend.maRelation\", \"params\": {}},\n");
        FileWriteString(handle2, "    {\"id\": \"filter.spreadMax#1\", \"typeId\": \"filter.spreadMax\", \"params\": {}}\n");
        FileWriteString(handle2, "  ]\n");
        FileWriteString(handle2, "}\n");
        FileClose(handle2);
        
        Config testConfig2;
        bool result2 = loader.Load(testFile2, testConfig2);
        Print("Result: ", result2 ? "PASS (unexpected)" : "FAIL (expected)");
        Print("Check log file for: DUPLICATE_BLOCK_ID with blockId='filter.spreadMax#1' at indices 0 and 2");
        Print("");
        
        FileDelete(testFile2, FILE_COMMON);
    }
    
    Print("--- Test 3: INVALID_BLOCK_ID_FORMAT (missing separator) ---");
    Print("Expected: Log should include blockId and format error");
    Print("");
    
    // Create test config file with invalid blockId format (missing #)
    string testFile3 = "strategy/test_invalid_format_no_hash.json";
    int handle3 = FileOpen(testFile3, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if (handle3 != INVALID_HANDLE) {
        FileWriteString(handle3, "{\n");
        FileWriteString(handle3, "  \"meta\": {\"formatVersion\": \"1.0\"},\n");
        FileWriteString(handle3, "  \"strategies\": [],\n");
        FileWriteString(handle3, "  \"blocks\": [\n");
        FileWriteString(handle3, "    {\"id\": \"filter.spreadMax\", \"typeId\": \"filter.spreadMax\", \"params\": {}}\n");
        FileWriteString(handle3, "  ]\n");
        FileWriteString(handle3, "}\n");
        FileClose(handle3);
        
        Config testConfig3;
        bool result3 = loader.Load(testFile3, testConfig3);
        Print("Result: ", result3 ? "PASS (unexpected)" : "FAIL (expected)");
        Print("Check log file for: INVALID_BLOCK_ID_FORMAT with blockId='filter.spreadMax' (missing '#' separator)");
        Print("");
        
        FileDelete(testFile3, FILE_COMMON);
    }
    
    Print("--- Test 4: INVALID_BLOCK_ID_FORMAT (non-numeric index) ---");
    Print("Expected: Log should include blockId and invalid index part");
    Print("");
    
    // Create test config file with invalid blockId format (non-numeric index)
    string testFile4 = "strategy/test_invalid_format_non_numeric.json";
    int handle4 = FileOpen(testFile4, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if (handle4 != INVALID_HANDLE) {
        FileWriteString(handle4, "{\n");
        FileWriteString(handle4, "  \"meta\": {\"formatVersion\": \"1.0\"},\n");
        FileWriteString(handle4, "  \"strategies\": [],\n");
        FileWriteString(handle4, "  \"blocks\": [\n");
        FileWriteString(handle4, "    {\"id\": \"filter.spreadMax#abc\", \"typeId\": \"filter.spreadMax\", \"params\": {}}\n");
        FileWriteString(handle4, "  ]\n");
        FileWriteString(handle4, "}\n");
        FileClose(handle4);
        
        Config testConfig4;
        bool result4 = loader.Load(testFile4, testConfig4);
        Print("Result: ", result4 ? "PASS (unexpected)" : "FAIL (expected)");
        Print("Check log file for: INVALID_BLOCK_ID_FORMAT with blockId='filter.spreadMax#abc' (non-numeric index 'abc')");
        Print("");
        
        FileDelete(testFile4, FILE_COMMON);
    }
    
    Print("--- Test 5: Valid config (success case) ---");
    Print("Expected: Log should include CONFIG_LOADED with strategy and block counts");
    Print("");
    
    // Create valid test config file
    string testFile5 = "strategy/test_valid_config.json";
    int handle5 = FileOpen(testFile5, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    if (handle5 != INVALID_HANDLE) {
        FileWriteString(handle5, "{\n");
        FileWriteString(handle5, "  \"meta\": {\"formatVersion\": \"1.0\"},\n");
        FileWriteString(handle5, "  \"strategies\": [{\"id\": \"S1\", \"entryRequirement\": {\"ruleGroups\": [{\"id\": \"RG1\", \"conditions\": [{\"blockId\": \"filter.spreadMax#1\"}]}]}}],\n");
        FileWriteString(handle5, "  \"blocks\": [{\"id\": \"filter.spreadMax#1\", \"typeId\": \"filter.spreadMax\", \"params\": {}}]\n");
        FileWriteString(handle5, "}\n");
        FileClose(handle5);
        
        Config testConfig5;
        bool result5 = loader.Load(testFile5, testConfig5);
        Print("Result: ", result5 ? "PASS (expected)" : "FAIL (unexpected)");
        Print("Check log file for: CONFIG_LOADED with message 'Config loaded successfully: 1 strategies, 1 blocks'");
        Print("");
        
        FileDelete(testFile5, FILE_COMMON);
    }
    
    // Cleanup
    logger.Cleanup();
    
    Print("=== Test Complete ===");
    Print("");
    Print("VERIFICATION INSTRUCTIONS:");
    Print("1. Check the log file: MQL5/Files/strategy/logs/test_error_details_YYYYMMDD.jsonl");
    Print("2. Verify each error log is in JSONL format (single-line JSON)");
    Print("3. Verify UNRESOLVED_BLOCK_REFERENCE includes: blockId, strategy ID, ruleGroup ID");
    Print("4. Verify DUPLICATE_BLOCK_ID includes: blockId, array indices");
    Print("5. Verify INVALID_BLOCK_ID_FORMAT includes: blockId, format error details");
    Print("6. Verify CONFIG_LOADED includes: strategy count, block count");
    Print("");
    Print("Example expected log entries:");
    Print("{\"ts\":\"...\",\"event\":\"UNRESOLVED_BLOCK_REFERENCE\",\"level\":\"ERROR\",\"message\":\"blockId 'filter.spreadMax#999' not found in blocks[] (Strategy: TestStrategy1, RuleGroup: TestRuleGroup1)\"}");
    Print("{\"ts\":\"...\",\"event\":\"DUPLICATE_BLOCK_ID\",\"level\":\"ERROR\",\"message\":\"Duplicate blockId 'filter.spreadMax#1' found in blocks[] at indices 0 and 2\"}");
    Print("{\"ts\":\"...\",\"event\":\"INVALID_BLOCK_ID_FORMAT\",\"level\":\"ERROR\",\"message\":\"blockId 'filter.spreadMax' does not contain '#' separator\"}");
    Print("{\"ts\":\"...\",\"event\":\"INVALID_BLOCK_ID_FORMAT\",\"level\":\"ERROR\",\"message\":\"blockId 'filter.spreadMax#abc' has non-numeric index part 'abc'\"}");
    Print("{\"ts\":\"...\",\"event\":\"CONFIG_LOADED\",\"message\":\"Config loaded successfully: 1 strategies, 1 blocks\"}");
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
    TestErrorLogDetails();
}
