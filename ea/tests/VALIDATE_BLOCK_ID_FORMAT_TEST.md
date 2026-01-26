# ValidateBlockIdFormat Function Test Documentation

## Overview

This document describes the implementation and testing of the `ValidateBlockIdFormat` function in the ConfigLoader, which validates that all blockIds follow the required format `{typeId}#{index}` where index is a numeric value.

## Implementation Details

### Location
- **File**: `ea/include/Config/ConfigLoader.mqh`
- **Function**: `ValidateBlockIdFormat(const Config &config)`
- **Helper Function**: `IsNumeric(const string &str)`

### Functionality

The `ValidateBlockIdFormat` function:

1. **Iterates through the blocks[] array** checking each blockId format
2. **Validates '#' separator presence** in each blockId
3. **Extracts the index part** (substring after '#')
4. **Verifies the index is numeric** using the IsNumeric helper function
5. **Logs detailed errors** when invalid formats are found:
   - The invalid blockId
   - The specific format violation (missing '#' or non-numeric index)
6. **Returns false** on validation failure, preventing config load
7. **Returns true** if all blockIds follow the correct format

### Helper Function: IsNumeric

The `IsNumeric` helper function:
- Takes a string as input
- Returns false if the string is empty
- Checks each character to ensure it's a digit (0-9)
- Returns true only if all characters are numeric

### Error Logging

When an invalid blockId format is detected:

**Missing '#' separator:**
```mql5
// Logger output (if logger is set)
m_logger.LogError("INVALID_BLOCK_ID_FORMAT", 
    "blockId 'filterSpreadMax1' does not contain '#' separator");

// Console output (always)
Print("ERROR: Invalid blockId format (missing '#'): filterSpreadMax1");
```

**Non-numeric index:**
```mql5
// Logger output (if logger is set)
m_logger.LogError("INVALID_BLOCK_ID_FORMAT", 
    "blockId 'filter.spreadMax#abc' has non-numeric index part 'abc'");

// Console output (always)
Print("ERROR: Invalid blockId format (non-numeric index): filter.spreadMax#abc");
```

### Integration

The validation is called in the `Load()` function after ValidateDuplicateBlockIds:

```mql5
// blockId重複の検証
if (!ValidateDuplicateBlockIds(config)) {
    // ... error handling
}

// blockId形式の検証
if (!ValidateBlockIdFormat(config)) {
    if (m_logger != NULL) {
        m_logger.LogError("CONFIG_VALIDATION_FAILED", "Invalid blockId format detected");
    }
    Print("ERROR: Config validation failed - invalid blockId format");
    return false;
}
```

## Test Files

### 1. Valid Configuration Test
- **File**: `ea/tests/test_single_blocks.json`
- **Purpose**: Verify that valid configurations with properly formatted blockIds pass validation
- **Expected Result**: Load succeeds

### 2. Invalid Configuration Test - Missing Separator
- **File**: `ea/tests/test_invalid_block_id_no_separator.json`
- **Purpose**: Verify that configurations with blockIds missing '#' separator fail validation
- **Content**: Contains a block with blockId `filterSpreadMax1` (no '#')
- **Expected Result**: Load fails with "missing '#' separator" error

### 3. Invalid Configuration Test - Non-Numeric Index
- **File**: `ea/tests/test_invalid_block_id_non_numeric.json`
- **Purpose**: Verify that configurations with non-numeric index parts fail validation
- **Content**: Contains a block with blockId `filter.spreadMax#abc`
- **Expected Result**: Load fails with "non-numeric index part" error

### 4. Test Script
- **File**: `ea/src/TestValidateBlockIdFormat.mq5`
- **Purpose**: Automated test script to verify ValidateBlockIdFormat function
- **Tests**:
  1. Valid configuration with properly formatted blockIds (should pass)
  2. Invalid configuration with missing '#' separator (should fail)
  3. Invalid configuration with non-numeric index (should fail)
  4. Configuration with multiple valid blockIds (should pass)

## Running the Tests

### Manual Testing

1. Copy test files to MT5 Files directory:
   ```
   MQL5/Files/StrategyBricks/test_single_blocks.json
   MQL5/Files/StrategyBricks/test_invalid_block_id_no_separator.json
   MQL5/Files/StrategyBricks/test_invalid_block_id_non_numeric.json
   ```

2. Compile the test script:
   - Open `TestValidateBlockIdFormat.mq5` in MetaEditor
   - Press F7 to compile

3. Run the test script:
   - In MT5, go to Navigator → Scripts
   - Drag `TestValidateBlockIdFormat` onto a chart
   - Check the Experts tab for test results

### Expected Output

```
=== Testing ValidateBlockIdFormat Function ===

--- Test 1: Valid Configuration (Proper Format) ---
ConfigLoader: Loaded X strategies, Y blocks
✓ Test 1 PASSED: Valid configuration with proper blockId format loaded successfully

--- Test 2: Invalid Configuration (Missing '#' Separator) ---
ERROR: Invalid blockId format (missing '#'): filterSpreadMax1
ERROR: Config validation failed - invalid blockId format
✓ Test 2 PASSED: Configuration with missing '#' separator correctly rejected

--- Test 3: Invalid Configuration (Non-Numeric Index) ---
ERROR: Invalid blockId format (non-numeric index): filter.spreadMax#abc
ERROR: Config validation failed - invalid blockId format
✓ Test 3 PASSED: Configuration with non-numeric index correctly rejected

--- Test 4: Configuration with Multiple Valid BlockIds ---
ConfigLoader: Loaded X strategies, Y blocks
✓ Test 4 PASSED: Configuration with multiple valid blockIds loaded successfully

=== Test Complete ===
```

## Requirements Validation

This implementation satisfies:

- **要件 3.1**: EAが設定を読み込む時、ConfigLoaderはすべてのblockId参照がblocks[]配列に存在することを検証する ✓
  - This includes ensuring blockIds follow the correct format for proper parsing
- **要件 4.1**: SystemはblockId形式を `{typeId}#{uniqueIndex}` と定義する（uniqueIndexは正の整数） ✓
  - EA-side validation ensures this format is enforced

## Design Compliance

The implementation follows the design specification in:
- `.kiro/specs/gui-ea-config-integration-fix/design.md`
- Section: "EA Runtime側のコンポーネント → 1. ConfigLoader（拡張）"
- Specifically implements the `ValidateBlockIdFormat` function as specified

## Valid BlockId Examples

The following blockId formats are **valid**:
- `filter.spreadMax#1`
- `trend.maRelation#2`
- `trigger.bbReentry#10`
- `filter.spreadMax#999`
- `a#1` (minimal valid format)

## Invalid BlockId Examples

The following blockId formats are **invalid**:
- `filterSpreadMax1` (missing '#' separator)
- `filter.spreadMax#abc` (non-numeric index)
- `filter.spreadMax#1.5` (decimal not allowed)
- `filter.spreadMax#-1` (negative not allowed)
- `filter.spreadMax#` (empty index)
- `#1` (empty typeId - technically passes this validation but would fail other checks)

## Algorithm Complexity

- **Time Complexity**: O(n × m) where n is the number of blocks and m is the average blockId length
  - For each block, we search for '#' and validate the index part
  - This is acceptable for typical config sizes (< 100 blocks)
- **Space Complexity**: O(m) where m is the maximum blockId length
  - StringSubstr creates a temporary string for the index part
  - No additional data structures needed

## Notes

- The function is called automatically during config loading
- No changes to existing code behavior for valid configurations
- Invalid configurations with malformed blockIds are now properly rejected
- The validation runs after duplicate detection but before the config is used
- Validation stops at the first invalid blockId found (fail-fast approach)
- The error message includes the specific format violation for debugging
- The IsNumeric helper function is reusable for other validation needs

## Edge Cases Handled

1. **Empty blockId**: Would fail at '#' search (hashPos < 0)
2. **Only '#' character**: Would fail at IsNumeric (empty string)
3. **Multiple '#' characters**: Only the first is used (e.g., `type#1#2` → index is `1#2`, fails IsNumeric)
4. **Leading zeros**: Accepted (e.g., `type#001` is valid)
5. **Very large numbers**: Accepted as long as they're numeric

---

**Implementation Date**: 2026-01-26
**Task**: 6.3 ValidateBlockIdFormat関数を実装
**Status**: ✓ Complete
