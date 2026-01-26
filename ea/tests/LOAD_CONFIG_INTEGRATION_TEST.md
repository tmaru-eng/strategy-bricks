# LoadConfig Function Integration Test Documentation

## Overview

This document describes the completion of Task 6.4: LoadConfig関数を修正. The Load() function in ConfigLoader has been successfully modified to integrate all three validation functions with appropriate error handling and success logging.

## Implementation Details

### Location
- **File**: `ea/include/Config/ConfigLoader.mqh`
- **Function**: `Load(string path, Config &config)`

### Integration Summary

The Load() function now performs the following validation sequence after JSON parsing:

1. **Parse JSON configuration** (meta, globalGuards, strategies, blocks)
2. **Validate block references** - Call `ValidateBlockReferences(config)`
   - Ensures all condition.blockId references exist in blocks[]
   - Logs "UNRESOLVED_BLOCK_REFERENCE" error if validation fails
3. **Validate duplicate blockIds** - Call `ValidateDuplicateBlockIds(config)`
   - Ensures no duplicate blockIds exist in blocks[]
   - Logs "DUPLICATE_BLOCK_ID" error if validation fails
4. **Validate blockId format** - Call `ValidateBlockIdFormat(config)`
   - Ensures all blockIds follow `{typeId}#{index}` format
   - Logs "INVALID_BLOCK_ID_FORMAT" error if validation fails
5. **Log success** - If all validations pass
   - Logs "CONFIG_LOADED" event with success message
   - Returns true

### Code Implementation

```mql5
bool Load(string path, Config &config) {
    // ... (file reading and JSON parsing code)
    
    // blockId参照の検証
    if (!ValidateBlockReferences(config)) {
        if (m_logger != NULL) {
            m_logger.LogError("CONFIG_VALIDATION_FAILED", "Block reference validation failed");
        }
        Print("ERROR: Config validation failed - unresolved block references");
        return false;
    }

    // blockId重複の検証
    if (!ValidateDuplicateBlockIds(config)) {
        if (m_logger != NULL) {
            m_logger.LogError("CONFIG_VALIDATION_FAILED", "Duplicate blockId detected");
        }
        Print("ERROR: Config validation failed - duplicate blockIds");
        return false;
    }

    // blockId形式の検証
    if (!ValidateBlockIdFormat(config)) {
        if (m_logger != NULL) {
            m_logger.LogError("CONFIG_VALIDATION_FAILED", "Invalid blockId format detected");
        }
        Print("ERROR: Config validation failed - invalid blockId format");
        return false;
    }

    // 成功時のログ記録
    if (m_logger != NULL) {
        string successMsg = StringFormat(
            "Config loaded successfully: %d strategies, %d blocks",
            config.strategyCount, config.blockCount
        );
        m_logger.LogInfo("CONFIG_LOADED", successMsg);
    }
    
    Print("ConfigLoader: Loaded ", config.strategyCount, " strategies, ",
          config.blockCount, " blocks");
    return true;
}
```

## Error Handling

### Validation Failure Behavior

When any validation fails:
1. **Error is logged** to the logger (if available) with specific error event
2. **Error is printed** to console with descriptive message
3. **Function returns false** immediately (fail-fast approach)
4. **Config is not used** - prevents EA from running with invalid configuration

### Success Behavior

When all validations pass:
1. **Success is logged** to the logger with "CONFIG_LOADED" event
2. **Success is printed** to console with strategy and block counts
3. **Function returns true** - EA can proceed with initialization

## Log Events

The Load() function now generates the following log events:

### Error Events
- `CONFIG_ERROR` - File not found or cannot be opened
- `CONFIG_VALIDATION_FAILED` - Generic validation failure
- `UNRESOLVED_BLOCK_REFERENCE` - Specific blockId reference not found
- `DUPLICATE_BLOCK_ID` - Duplicate blockId detected
- `INVALID_BLOCK_ID_FORMAT` - BlockId format violation

### Success Events
- `CONFIG_LOADED` - Configuration loaded and validated successfully

### Example Log Output (JSONL format)

**Success:**
```jsonl
{"ts":"2026-01-26 10:00:00","level":"INFO","event":"CONFIG_LOADED","message":"Config loaded successfully: 27 strategies, 27 blocks"}
```

**Failure (Unresolved Reference):**
```jsonl
{"ts":"2026-01-26 10:00:00","level":"ERROR","event":"UNRESOLVED_BLOCK_REFERENCE","message":"blockId 'trend.maRelation#999' not found in blocks[] (Strategy: S1, RuleGroup: RG1)"}
{"ts":"2026-01-26 10:00:00","level":"ERROR","event":"CONFIG_VALIDATION_FAILED","message":"Block reference validation failed"}
```

**Failure (Duplicate BlockId):**
```jsonl
{"ts":"2026-01-26 10:00:00","level":"ERROR","event":"DUPLICATE_BLOCK_ID","message":"Duplicate blockId 'filter.spreadMax#1' found in blocks[] at indices 0 and 1"}
{"ts":"2026-01-26 10:00:00","level":"ERROR","event":"CONFIG_VALIDATION_FAILED","message":"Duplicate blockId detected"}
```

**Failure (Invalid Format):**
```jsonl
{"ts":"2026-01-26 10:00:00","level":"ERROR","event":"INVALID_BLOCK_ID_FORMAT","message":"blockId 'filterSpreadMax1' does not contain '#' separator"}
{"ts":"2026-01-26 10:00:00","level":"ERROR","event":"CONFIG_VALIDATION_FAILED","message":"Invalid blockId format detected"}
```

## Test Files

### Integration Test Script
- **File**: `ea/src/TestLoadConfigIntegration.mq5`
- **Purpose**: Comprehensive test of Load() function validation integration
- **Tests**:
  1. Valid configuration (should pass all validations)
  2. Invalid block references (should fail ValidateBlockReferences)
  3. Duplicate block IDs (should fail ValidateDuplicateBlockIds)
  4. Invalid blockId format - missing separator (should fail ValidateBlockIdFormat)
  5. Invalid blockId format - non-numeric index (should fail ValidateBlockIdFormat)

### Test Data Files
- `ea/tests/test_single_blocks.json` - Valid configuration
- `ea/tests/test_invalid_block_references.json` - Unresolved block reference
- `ea/tests/test_duplicate_block_ids.json` - Duplicate blockIds
- `ea/tests/test_invalid_block_id_no_separator.json` - Missing '#' separator
- `ea/tests/test_invalid_block_id_non_numeric.json` - Non-numeric index

## Running the Tests

### Compile the Test Script

1. Open MetaEditor
2. Open `ea/src/TestLoadConfigIntegration.mq5`
3. Press F7 to compile

### Run the Test Script

1. In MT5, go to Navigator → Scripts
2. Drag `TestLoadConfigIntegration` onto a chart
3. Check the Experts tab for test results

### Expected Output

```
=== Testing Load() Function Validation Integration ===
Task 6.4: Verify all validation functions are properly integrated

--- Test 1: Valid Configuration ---
ConfigLoader: Loaded 27 strategies, 27 blocks
✓ Test 1 PASSED: Valid configuration loaded successfully
  - Loaded 27 strategies, 27 blocks

--- Test 2: Invalid Block References ---
ERROR: Unresolved block reference: trend.maRelation#999 in Strategy: S1, RuleGroup: RG1
ERROR: Config validation failed - unresolved block references
✓ Test 2 PASSED: Configuration with unresolved block references correctly rejected

--- Test 3: Duplicate Block IDs ---
ERROR: Duplicate blockId detected: filter.spreadMax#1 at indices 0 and 1
ERROR: Config validation failed - duplicate blockIds
✓ Test 3 PASSED: Configuration with duplicate blockIds correctly rejected

--- Test 4: Invalid BlockId Format (Missing Separator) ---
ERROR: Invalid blockId format (missing '#'): filterSpreadMax1
ERROR: Config validation failed - invalid blockId format
✓ Test 4 PASSED: Configuration with invalid blockId format (no separator) correctly rejected

--- Test 5: Invalid BlockId Format (Non-Numeric Index) ---
ERROR: Invalid blockId format (non-numeric index): filter.spreadMax#abc
ERROR: Config validation failed - invalid blockId format
✓ Test 5 PASSED: Configuration with invalid blockId format (non-numeric) correctly rejected

=== Test Summary ===
Passed: 5/5
✓ ALL TESTS PASSED - Task 6.4 Complete
  - ValidateBlockReferences: Integrated ✓
  - ValidateDuplicateBlockIds: Integrated ✓
  - ValidateBlockIdFormat: Integrated ✓
  - Success logging (CONFIG_LOADED): Implemented ✓
```

## Requirements Validation

This implementation satisfies:

- **要件 3.1**: EAが設定を読み込む時、ConfigLoaderはすべてのblockId参照がblocks[]配列に存在することを検証する ✓
  - Implemented via ValidateBlockReferences() integration
  
- **要件 3.2**: blockId参照が欠落している時、ConfigLoaderは説明的なエラーをログに記録し、初期化を拒否する ✓
  - All validation failures log detailed errors and return false
  - Success is logged with CONFIG_LOADED event

## Design Compliance

The implementation follows the design specification in:
- `.kiro/specs/gui-ea-config-integration-fix/design.md`
- Section: "EA Runtime側のコンポーネント → 1. ConfigLoader（拡張）"
- Specifically implements the Load() function integration as specified

## Integration with EA Initialization

The Load() function is called during EA initialization (OnInit):

```mql5
int OnInit() {
    // ConfigLoader初期化
    ConfigLoader loader(&logger);
    Config config;
    
    // 設定読み込み
    if (!loader.Load("strategy/active.json", config)) {
        // 初期化失敗
        logger.LogError("INIT_FAILED", "Failed to load config");
        return INIT_FAILED;  // ← EA initialization fails
    }
    
    // 正常初期化
    logger.LogInfo("INIT_SUCCESS", "EA initialized successfully");
    return INIT_SUCCEEDED;
}
```

When Load() returns false due to validation failure:
- EA initialization fails with `INIT_FAILED`
- EA does not start trading
- User sees error in Experts tab
- Logs contain detailed error information for debugging

## Benefits

This integration provides:

1. **Early Error Detection** - Invalid configurations are caught at load time, not during trading
2. **Detailed Error Messages** - Specific validation failures are logged with context
3. **Fail-Safe Behavior** - EA refuses to start with invalid configuration
4. **Debugging Support** - Logs provide clear information for troubleshooting
5. **Requirements Compliance** - Satisfies all acceptance criteria for 要件 3.1 and 3.2

## Related Tasks

- ✓ Task 6.1: ValidateBlockReferences関数を実装
- ✓ Task 6.2: ValidateDuplicateBlockIds関数を実装
- ✓ Task 6.3: ValidateBlockIdFormat関数を実装
- ✓ Task 6.4: LoadConfig関数を修正 (This task)

## Next Steps

After completing Task 6.4, the next tasks are:
- Task 6.5: ConfigLoaderのユニットテストを作成 (Optional)
- Task 7.1: 新しいログイベントを追加 (Already complete via validation functions)
- Task 7.2: エラーログに詳細情報を含める (Already complete via validation functions)

---

**Implementation Date**: 2026-01-26
**Task**: 6.4 LoadConfig関数を修正
**Status**: ✓ Complete
