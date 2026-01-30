#!/bin/bash

# Strategy Bricks EA - Automated Strategy Tester
# Run selected configs and summarize manual test steps

set -e

BOTTLE="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_DIR="$BOTTLE/drive_c/Program Files/MetaTrader 5"
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
TESTER_FILES="$MT5_DIR/Tester/Agent-127.0.0.1-3000/Files/strategy"

# Target configs
TEST_CONFIGS=(
    "active.json"
    "test_strategy_advanced.json"
    "test_strategy_all_blocks.json"
)

# Test period
START_DATE="2026.01.01"
END_DATE="2026.01.25"

# Results directory
RESULTS_DIR="ea/tests/results"
mkdir -p "$RESULTS_DIR"

# Summary file
SUMMARY_FILE="$RESULTS_DIR/test_summary_$(date +%Y%m%d_%H%M%S).txt"

echo "========================================" | tee "$SUMMARY_FILE"
echo "Strategy Bricks EA - Automated Test" | tee -a "$SUMMARY_FILE"
echo "Test Period: $START_DATE - $END_DATE" | tee -a "$SUMMARY_FILE"
echo "========================================" | tee -a "$SUMMARY_FILE"
echo "" | tee -a "$SUMMARY_FILE"

# Run configs
for config in "${TEST_CONFIGS[@]}"; do
    echo "----------------------------------------" | tee -a "$SUMMARY_FILE"
    echo "Testing: $config" | tee -a "$SUMMARY_FILE"
    echo "----------------------------------------" | tee -a "$SUMMARY_FILE"

    if [ ! -f "$TESTER_FILES/$config" ]; then
        echo "Config file not found: $config" | tee -a "$SUMMARY_FILE"
        echo "" | tee -a "$SUMMARY_FILE"
        continue
    fi

    cp "$TESTER_FILES/$config" "$TESTER_FILES/active.json"

    echo "Manual test required:" | tee -a "$SUMMARY_FILE"
    echo "  1. Open MT5 Strategy Tester" | tee -a "$SUMMARY_FILE"
    echo "  2. Select EA: StrategyBricks" | tee -a "$SUMMARY_FILE"
    echo "  3. Symbol: USDJPYm" | tee -a "$SUMMARY_FILE"
    echo "  4. Period: M1" | tee -a "$SUMMARY_FILE"
    echo "  5. Date range: $START_DATE - $END_DATE" | tee -a "$SUMMARY_FILE"
    echo "  6. Config: strategy/$config" | tee -a "$SUMMARY_FILE"
    echo "  7. Run test and check results" | tee -a "$SUMMARY_FILE"
    echo "" | tee -a "$SUMMARY_FILE"

    TESTER_LOG="$MT5_DIR/Tester/Agent-127.0.0.1-3000/logs/$(date +%Y%m%d).log"
    if [ -f "$TESTER_LOG" ]; then
        echo "Latest tester log entries:" | tee -a "$SUMMARY_FILE"
        tail -20 "$TESTER_LOG" | tee -a "$SUMMARY_FILE"
    fi

    echo "" | tee -a "$SUMMARY_FILE"
done

echo "========================================" | tee -a "$SUMMARY_FILE"
echo "Test Summary saved to: $SUMMARY_FILE" | tee -a "$SUMMARY_FILE"
echo "========================================" | tee -a "$SUMMARY_FILE"

cat << 'EOF' | tee -a "$SUMMARY_FILE"

## Test Result Verification

Checklist:
1. Initialization success (no error, config loaded, blocks OK)
2. Trades count (0 trades may indicate strict conditions)
3. Error logs (block/indicator/order errors)
4. Performance (time, memory)

Expected (rough):
- active.json: 1-10 trades
- test_strategy_advanced.json: 0-5 trades
- test_strategy_all_blocks.json: 0-3 trades

If trades are 0 but no errors, the run is still considered OK.
EOF

echo ""
echo "Test script completed"
echo "Summary: $SUMMARY_FILE"
