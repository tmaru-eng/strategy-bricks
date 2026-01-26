# ValidateBlockReferences Function Test Documentation

## Overview

This document describes the implementation and testing of the `ValidateBlockReferences` function in the ConfigLoader, which validates that all blockId references in strategy conditions exist in the blocks array.

## Implementation Details

### Location
- **File**: `ea/include/Config/ConfigLoader.mqh`
- **Function**: `ValidateBlockReferences(const Config &config)`
- **Helper Function**: `ArrayContains(const string &arr[], int size, const string &value)`

### Functionality

The `ValidateBlockReferences` function:

1. **Builds a blockId set** from the `blocks[]` array
2. **Iterates through all strategies** and their rule groups
3. **Checks each condition's blockId** against the blockId set
4. **Logs detailed errors** when unresolved references are found:
   - The missing blockId
   - The strategy ID where the reference was found
   - The rule group ID where the reference was found
5. **Returns false** on validation failure, preventing config load
6. **Returns true** if all references are valid

### Error Logging

When an unresolved block reference is detected:

```mql5
// Logger output (if logger is set)
m_logger.LogError("UNRESOLVED_BLOCK_REFERENCE", 
    "blockId 'trend.maRelation#999' not found in blocks[] (Strategy: S1, RuleGroup: RG1)");

// Console output (always)
Print("ERROR: Unresolved block reference: trend.maRelation#999 in Strategy: S1, RuleGroup: RG1");
```

### Integration

The validation is called in the `Load()` function after parsing blocks:

```mql5
// blocks解析
// ... (block parsing code)

// blockId参照の検証
if (!ValidateBlockReferences(config)) {
    if (m_logger != NULL) {
        m_logger.LogError("CONFIG_VALIDATION_FAILED", "Block reference validation failed");
    }
    Print("ERROR: Config validation failed - unresolved block references");
    return false;
}
```

## Test Files

### 1. Valid Configuration Test
- **File**: `ea/tests/test_single_blocks.json`
- **Purpose**: Verify that valid configurations pass validation
- **Expected Result**: Load succeeds

### 2. Invalid Configuration Test
- **File**: `ea/tests/test_invalid_block_references.json`
- **Purpose**: Verify that configurations with unresolved block references fail validation
- **Content**: Contains a strategy referencing `trend.maRelation#999` which doesn't exist in blocks[]
- **Expected Result**: Load fails with detailed error message

### 3. Test Script
- **File**: `ea/src/TestValidateBlockReferences.mq5`
- **Purpose**: Automated test script to verify ValidateBlockReferences function
- **Tests**:
  1. Valid configuration (should pass)
  2. Invalid configuration with unresolved reference (should fail)
  3. Configuration with shared blocks (should pass)

## Running the Tests

### Manual Testing

1. Copy test files to MT5 Files directory:
   ```
   MQL5/Files/StrategyBricks/test_single_blocks.json
   MQL5/Files/StrategyBricks/test_invalid_block_references.json
   MQL5/Files/StrategyBricks/test_strategy_advanced.json
   ```

2. Compile the test script:
   - Open `TestValidateBlockReferences.mq5` in MetaEditor
   - Press F7 to compile

3. Run the test script:
   - In MT5, go to Navigator → Scripts
   - Drag `TestValidateBlockReferences` onto a chart
   - Check the Experts tab for test results

### Expected Output

```
=== Testing ValidateBlockReferences Function ===

--- Test 1: Valid Configuration ---
ConfigLoader: Loaded 27 strategies, 27 blocks
✓ Test 1 PASSED: Valid configuration loaded successfully

--- Test 2: Invalid Configuration (Unresolved Block Reference) ---
ERROR: Unresolved block reference: trend.maRelation#999 in Strategy: S1, RuleGroup: RG1
ERROR: Config validation failed - unresolved block references
✓ Test 2 PASSED: Invalid configuration correctly rejected

--- Test 3: Configuration with Shared Blocks ---
ConfigLoader: Loaded X strategies, Y blocks
✓ Test 3 PASSED: Configuration with shared blocks loaded successfully

=== Test Complete ===
```

## Requirements Validation

This implementation satisfies:

- **要件 3.1**: EAが設定を読み込む時、ConfigLoaderはすべてのblockId参照がblocks[]配列に存在することを検証する ✓
- **要件 3.2**: blockId参照が欠落している時、ConfigLoaderは説明的なエラーをログに記録し、初期化を拒否する ✓

## Design Compliance

The implementation follows the design specification in:
- `.kiro/specs/gui-ea-config-integration-fix/design.md`
- Section: "EA Runtime側のコンポーネント → 1. ConfigLoader（拡張）"

## Notes

- The function is called automatically during config loading
- No changes to existing code behavior for valid configurations
- Invalid configurations are now properly rejected with detailed error messages
- The validation adds minimal performance overhead (linear scan of blocks and conditions)

---

**Implementation Date**: 2026-01-26
**Task**: 6.1 ValidateBlockReferences関数を実装
**Status**: ✓ Complete
