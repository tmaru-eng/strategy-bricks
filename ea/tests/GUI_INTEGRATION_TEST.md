# GUI Integration Test Documentation

## Overview

This test verifies the complete integration between GUI Builder and EA Runtime, ensuring that:
1. GUI-generated configurations load successfully in the EA
2. All blockId references resolve correctly
3. Shared blocks work as expected across multiple strategies
4. Strategy evaluation executes without errors

## Test Configuration

**File**: `ea/tests/gui_integration_test.json`

**Structure**:
- 2 strategies (S1, S2)
- 5 blocks total
- 1 shared block (`filter.spreadMax#1`) used by both strategies
- 4 unique blocks (2 trend blocks, 2 trigger blocks)

**Key Features**:
- Tests shared block references (same blockId in multiple strategies)
- Tests unique block references (different blockIds per strategy)
- Validates blockId format: `{typeId}#{index}`

## Test Execution

### Method 1: Run Test Script

```powershell
# Compile test script
.\scripts\compile_and_test_all.ps1 -TestFile "TestGuiIntegration"

# Or manually compile
cd ea/src
"C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:TestGuiIntegration.mq5
```

### Method 2: Load in EA

1. Copy `gui_integration_test.json` to `MQL5/Files/strategy/` directory
2. Rename to `active.json` (or update EA to load this file)
3. Attach EA to chart
4. Check logs for initialization success

## Expected Results

### Test 1: Load GUI-generated config
- ✓ Config file opens successfully
- ✓ JSON content is not empty
- ✓ File size is reasonable

### Test 2: Verify block references
- ✓ All Strategy 1 references resolve:
  - `filter.spreadMax#1`
  - `trend.maRelation#1`
  - `trigger.rsiLevel#1`
- ✓ All Strategy 2 references resolve:
  - `filter.spreadMax#1`
  - `trend.maRelation#2`
  - `trigger.rsiLevel#2`

### Test 3: Verify shared blocks
- ✓ `filter.spreadMax#1` is used by both S1 and S2
- ✓ Same blockId appears in multiple strategy references

## Validation Checks

The test verifies the following correctness properties:

1. **Property 1**: All blockIds are unique in blocks[] array
2. **Property 2**: All condition references resolve to blocks[] entries
3. **Property 3**: Shared blocks use consistent blockId across strategies

## Troubleshooting

### Config file not found
- Ensure `gui_integration_test.json` is in `MQL5/Files/strategy/` directory
- Check file permissions

### Reference resolution fails
- Verify blockId format: `{typeId}#{index}`
- Check that all condition.blockId values exist in blocks[] array
- Look for typos in blockId strings

### Shared block issues
- Confirm same blockId string is used in multiple strategies
- Verify blocks[] array contains only one entry for shared block

## Log Events

Expected log events during successful test:

```jsonl
{"ts":"2026-01-26 10:00:00","event":"TEST_START","test":"GUI Integration"}
{"ts":"2026-01-26 10:00:00","event":"CONFIG_LOADED","file":"gui_integration_test.json"}
{"ts":"2026-01-26 10:00:00","event":"BLOCK_REFERENCES_VALID","count":5}
{"ts":"2026-01-26 10:00:00","event":"SHARED_BLOCK_VERIFIED","blockId":"filter.spreadMax#1"}
{"ts":"2026-01-26 10:00:00","event":"TEST_PASSED","test":"GUI Integration"}
```

## Success Criteria

All three tests must pass:
- [x] Test 1: Config loads without errors
- [x] Test 2: All block references resolve
- [x] Test 3: Shared blocks work correctly

## Related Requirements

- **Requirement 1.2**: GUI uses same blockId in conditions and blocks
- **Requirement 1.3**: Multiple conditions share same blockId
- **Requirement 1.4**: All references exist in blocks[] array
- **Requirement 5.1**: Test exports multiple strategies
- **Requirement 5.2**: Test EA loads successfully
- **Requirement 5.3**: Test strategy evaluation works
