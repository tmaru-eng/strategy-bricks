# MT5 Strategy Tester - Execution Guide

## Overview

This guide explains how to execute automated tests for the Strategy Bricks EA using MT5's Strategy Tester via command line.

## Prerequisites

1. MT5 installed (macOS app with wine)
2. EA compiled: `ea/build/StrategyBricks.ex5`
3. Test configurations in MT5 Tester directory
4. Tester config files generated

## Test Configuration Files

Location: `$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/config/`

- `tester_test_single_blocks.ini` - 27 single-block unit tests
- `tester_active.ini` - Basic strategy test
- `tester_test_strategy_advanced.ini` - 3 advanced strategies
- `tester_test_strategy_all_blocks.ini` - 4 comprehensive strategies

## Execution Methods

### Method 1: Run All Tests (Recommended)

```bash
bash scripts/run_mt5_tests.sh
```

This will:
1. Execute all 4 test configurations sequentially
2. Collect logs from each test
3. Parse results (initialization, trades, errors)
4. Generate a comprehensive test report

### Method 2: Run Individual Test

```bash
bash scripts/run_mt5_tests.sh test_single_blocks
```

Available test names:
- `test_single_blocks`
- `active`
- `test_strategy_advanced`
- `test_strategy_all_blocks`

### Method 3: Manual Execution

```bash
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
MT5_PATH="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5"

"$WINE" "$MT5_PATH/terminal64.exe" /config:"$MT5_PATH/config/tester_test_single_blocks.ini"
```

## Test Parameters

All tests use the following parameters:

- **Symbol**: USDJPYm
- **Timeframe**: M1 (1 minute)
- **Period**: 2025.10.01 - 2025.12.31 (3 months)
- **Deposit**: 1,000,000 JPY
- **Leverage**: 1:100
- **Model**: Every tick (most accurate)

## Expected Results

### test_single_blocks.json (27 strategies)
- **Purpose**: Unit test each block individually
- **Expected Trades**: 50-200 per strategy
- **Pass Criteria**: Initialization success + No errors + Trades > 0
- **Failure Diagnosis**: If trades = 0, the specific block has issues

### active.json (1 strategy)
- **Purpose**: Basic functionality test
- **Expected Trades**: 10-50
- **Pass Criteria**: Initialization success + No errors + Trades > 0

### test_strategy_advanced.json (3 strategies)
- **Purpose**: Multi-block integration test
- **Expected Trades**: 5-30 per strategy
- **Pass Criteria**: Initialization success + No errors + Trades > 0

### test_strategy_all_blocks.json (4 strategies)
- **Purpose**: Comprehensive block coverage
- **Expected Trades**: 3-20 per strategy
- **Pass Criteria**: Initialization success + No errors + Trades > 0

## Result Interpretation

### ✅ PASS
- EA initialized successfully
- No errors in logs
- Trades executed (> 0)

### ⚠️ WARNING
- EA initialized successfully
- No errors in logs
- Zero trades (conditions too strict)

### ❌ FAIL
- Initialization failed
- Errors in logs
- Block loading failed

## Log Files

Logs are stored in:
```
$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/logs/
```

Log file format: `YYYYMMDD.log`

## Test Reports

Reports are generated in: `ea/tests/results/`

Format:
- `test_report_YYYYMMDD_HHMMSS.txt` - Human-readable report
- `test_report_YYYYMMDD_HHMMSS.json` - Machine-readable data

## Troubleshooting

### Issue: Zero trades in 3-month period

**Diagnosis Steps:**
1. Check if EA initialized successfully
2. Verify blocks loaded correctly
3. Check for errors in logs
4. Review strategy conditions (may be too strict)

**Solution:**
- If single block test fails: Fix that specific block
- If all tests fail: Check core EA logic
- If only complex strategies fail: Adjust strategy conditions

### Issue: Initialization failed

**Diagnosis Steps:**
1. Check config file path
2. Verify JSON syntax
3. Check block typeId matches registry
4. Review logs for specific error

**Solution:**
- Validate JSON with `scripts/validate_test_configs.py`
- Ensure all blocks are registered in `BlockRegistry.mqh`
- Check parameter types match block definitions

### Issue: Wine errors

**Diagnosis Steps:**
1. Verify wine path: `/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64`
2. Check MT5 installation
3. Verify file permissions

**Solution:**
- Reinstall MT5 if necessary
- Check wine version compatibility
- Ensure terminal64.exe is executable

## Performance Notes

- Each test takes approximately 2-5 minutes
- Total execution time: ~15-20 minutes for all tests
- Tests run sequentially to avoid conflicts
- MT5 terminal closes automatically after each test

## Next Steps After Testing

1. Review test report in `ea/tests/results/`
2. Identify failing tests
3. Fix issues in block implementations
4. Re-run specific tests to verify fixes
5. Update documentation if needed
