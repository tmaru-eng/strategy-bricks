# GUI-Generated Config Testing Guide

## Overview

This guide describes how to test GUI-generated configuration files with the EA Runtime to verify the GUI-EA integration.

## Test Files

The following GUI-generated configs are available for testing:

1. **basic-strategy.json** - Basic strategy with 3 blocks (filter, trend, trigger)
2. **trend-only.json** - Trend-focused strategy
3. **multi-trigger.json** - Strategy with multiple triggers

## Prerequisites

1. MT5 installed
2. StrategyBricks EA compiled
3. GUI-generated configs copied to MT5 Files directory

## Quick Test Setup

Run the setup script:

```powershell
.\test-gui-configs.ps1
```

This will:
- Copy GUI-generated configs to MT5 Files/strategy directory
- Verify config structure
- Display testing instructions

## Manual Testing Steps

### Step 1: Open MT5 Strategy Tester

1. Launch MT5
2. Press `Ctrl+R` to open Strategy Tester

### Step 2: Configure Test

**EA Settings:**
- EA: `Experts\StrategyBricks\StrategyBricks`
- Symbol: `USDJPYm` (or any available symbol)
- Period: `M1`
- Date Range: `2025.10.01 - 2025.12.31`
- Deposit: `1,000,000 JPY`
- Leverage: `1:100`

**Input Parameters:**
- `InpConfigPath` = `strategy/basic-strategy.json` (or other test file)

### Step 3: Run Test

1. Click "Start" button
2. Wait for test to complete
3. Check results

### Step 4: Verify Results

**Success Criteria:**

1. **Initialization Success**
   - Check Experts tab for "CONFIG_LOADED" event
   - No "CONFIG_VALIDATION_FAILED" errors
   - No "UNRESOLVED_BLOCK_REFERENCE" errors

2. **Block Reference Resolution**
   - All blockIds in strategies match blocks[] array
   - No "DUPLICATE_BLOCK_ID" errors
   - No "INVALID_BLOCK_ID_FORMAT" errors

3. **Strategy Execution**
   - Trades are executed (count > 0)
   - No runtime errors in Experts tab

**Expected Behavior:**

- **basic-strategy.json**: Should execute trades based on spread filter, MA trend, and BB reentry trigger
- **trend-only.json**: Should execute trades based on trend conditions
- **multi-trigger.json**: Should execute trades with multiple trigger conditions

## Troubleshooting

### No Trades Executed

1. Check Experts tab for errors
2. Verify config file path is correct
3. Check if strategies are enabled in config
4. Verify symbol and timeframe match config requirements

### Config Load Failure

1. Check for validation errors in Experts tab:
   - `UNRESOLVED_BLOCK_REFERENCE`: blockId in strategy not found in blocks[]
   - `DUPLICATE_BLOCK_ID`: Same blockId appears multiple times in blocks[]
   - `INVALID_BLOCK_ID_FORMAT`: blockId doesn't follow `{typeId}#{index}` format

2. Verify config file structure:
   ```json
   {
     "meta": { ... },
     "globalGuards": { ... },
     "strategies": [
       {
         "entryRequirement": {
           "ruleGroups": [
             {
               "conditions": [
                 { "blockId": "filter.spreadMax#1" }
               ]
             }
           ]
         }
       }
     ],
     "blocks": [
       { "id": "filter.spreadMax#1", "typeId": "filter.spreadMax", "params": {...} }
     ]
   }
   ```

3. Verify blockId references:
   - All `conditions[].blockId` must exist in `blocks[].id`
   - blockIds must be unique
   - blockIds must follow format: `{typeId}#{index}`

## Test Results Documentation

After testing, document results in `ea/tests/results/` directory:

```
test_gui_config_YYYYMMDD_HHMMSS.txt
```

Include:
- Config file name
- Test date/time
- Initialization result (success/failure)
- Trade count
- Any errors or warnings
- Screenshots (optional)

## Automated Testing

For automated testing, use the test script:

```powershell
.\ea\src\TestGuiGeneratedConfigs.mq5
```

This script will:
1. Load each GUI-generated config
2. Verify blockId format
3. Verify block reference resolution
4. Report pass/fail for each config

## Integration Verification Checklist

- [ ] GUI E2E test passes (configs generated successfully)
- [ ] Configs copied to MT5 Files directory
- [ ] EA loads basic-strategy.json without errors
- [ ] EA loads trend-only.json without errors
- [ ] EA loads multi-trigger.json without errors
- [ ] All blockId references resolve correctly
- [ ] No validation errors in Experts tab
- [ ] Trades are executed (count > 0)
- [ ] Test results documented

## Next Steps

After successful testing:

1. Update task status in `.kiro/specs/gui-ea-config-integration-fix/tasks.md`
2. Document any issues found
3. Create bug reports for failures
4. Update integration documentation if needed
