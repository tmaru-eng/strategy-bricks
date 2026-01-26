# ValidateDuplicateBlockIds Function Test Documentation

## Overview

This document describes the implementation and testing of the `ValidateDuplicateBlockIds` function in the ConfigLoader, which validates that all blockIds in the blocks array are unique (no duplicates).

## Implementation Details

### Location
- **File**: `ea/include/Config/ConfigLoader.mqh`
- **Function**: `ValidateDuplicateBlockIds(const Config &config)`

### Functionality

The `ValidateDuplicateBlockIds` function:

1. **Iterates through the blocks[] array** checking each blockId
2. **Compares each blockId** with all subsequent blockIds to detect duplicates
3. **Logs detailed errors** when duplicate blockIds are found:
   - The duplicate blockId
   - The indices where the duplicates were found
4. **Returns false** on validation failure (duplicate detected), preventing config load
5. **Returns true** if all blockIds are unique

### Error Logging

When a duplicate blockId is detected:

```mql5
// Logger output (if logger is set)
m_logger.LogError("DUPLICATE_BLOCK_ID", 
    "Duplicate blockId 'filter.spreadMax#1' found in blocks[] at indices 0 and 1");

// Console output (always)
Print("ERROR: Duplicate blockId detected: filter.spreadMax#1 at indices 0 and 1");
```

### Integration

The validation is called in the `Load()` function after ValidateBlockReferences:

```mql5
// blockId参照の検証
if (!ValidateBlockReferences(config)) {
    // ... error handling
}

// blockId重複の検証
if (!ValidateDuplicateBlockIds(config)) {
    if (m_logger != NULL) {
        m_logger.LogError("CONFIG_VALIDATION_FAILED", "Duplicate blockId detected");
    }
    Print("ERROR: Config validation failed - duplicate blockIds");
    return false;
}
```

## Test Files

### 1. Valid Configuration Test
- **File**: `ea/tests/test_single_blocks.json`
- **Purpose**: Verify that valid configurations with unique blockIds pass validation
- **Expected Result**: Load succeeds

### 2. Invalid Configuration Test
- **File**: `ea/tests/test_duplicate_block_ids.json`
- **Purpose**: Verify that configurations with duplicate blockIds fail validation
- **Content**: Contains two blocks with the same blockId `filter.spreadMax#1`
- **Expected Result**: Load fails with detailed error message

### 3. Test Script
- **File**: `ea/src/TestValidateDuplicateBlockIds.mq5`
- **Purpose**: Automated test script to verify ValidateDuplicateBlockIds function
- **Tests**:
  1. Valid configuration with unique blockIds (should pass)
  2. Invalid configuration with duplicate blockIds (should fail)
  3. Configuration with multiple unique blocks (should pass)

## Running the Tests

### Manual Testing

1. Copy test files to MT5 Files directory:
   ```
   MQL5/Files/StrategyBricks/test_single_blocks.json
   MQL5/Files/StrategyBricks/test_duplicate_block_ids.json
   MQL5/Files/StrategyBricks/test_strategy_advanced.json
   ```

2. Compile the test script:
   - Open `TestValidateDuplicateBlockIds.mq5` in MetaEditor
   - Press F7 to compile

3. Run the test script:
   - In MT5, go to Navigator → Scripts
   - Drag `TestValidateDuplicateBlockIds` onto a chart
   - Check the Experts tab for test results

### Expected Output

```
=== Testing ValidateDuplicateBlockIds Function ===

--- Test 1: Valid Configuration (Unique BlockIds) ---
ConfigLoader: Loaded X strategies, Y blocks
✓ Test 1 PASSED: Valid configuration with unique blockIds loaded successfully

--- Test 2: Invalid Configuration (Duplicate BlockIds) ---
ERROR: Duplicate blockId detected: filter.spreadMax#1 at indices 0 and 1
ERROR: Config validation failed - duplicate blockIds
✓ Test 2 PASSED: Configuration with duplicate blockIds correctly rejected

--- Test 3: Configuration with Multiple Unique Blocks ---
ConfigLoader: Loaded X strategies, Y blocks
✓ Test 3 PASSED: Configuration with multiple unique blocks loaded successfully

=== Test Complete ===
```

## Requirements Validation

This implementation satisfies:

- **要件 3.1**: EAが設定を読み込む時、ConfigLoaderはすべてのblockId参照がblocks[]配列に存在することを検証する ✓
  - This includes ensuring no duplicate blockIds exist, which would cause ambiguous references
- **要件 2.4**: Validatorはblocks[]配列内の重複blockIdを確認する ✓
  - EA-side equivalent of the GUI-side DuplicateBlockIdRule

## Design Compliance

The implementation follows the design specification in:
- `.kiro/specs/gui-ea-config-integration-fix/design.md`
- Section: "EA Runtime側のコンポーネント → 1. ConfigLoader（拡張）"
- Specifically implements the `ValidateDuplicateBlockIds` function as specified

## Algorithm Complexity

- **Time Complexity**: O(n²) where n is the number of blocks
  - For each block, we check all subsequent blocks
  - This is acceptable for typical config sizes (< 100 blocks)
- **Space Complexity**: O(1)
  - No additional data structures needed
  - Uses only loop variables

## Notes

- The function is called automatically during config loading
- No changes to existing code behavior for valid configurations
- Invalid configurations with duplicate blockIds are now properly rejected
- The validation runs after block parsing but before the config is used
- Duplicate detection stops at the first duplicate found (fail-fast approach)
- The error message includes both indices for debugging purposes

---

**Implementation Date**: 2026-01-26
**Task**: 6.2 ValidateDuplicateBlockIds関数を実装
**Status**: ✓ Complete
