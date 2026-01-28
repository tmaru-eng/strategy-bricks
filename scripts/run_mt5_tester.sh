#!/bin/bash
# MT5 Strategy Tester Automated Runner

MT5_PATH="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5"
TERMINAL="$MT5_PATH/terminal64.exe"

echo "============================================================"
echo "MT5 Strategy Tester - Automated Test Runner"
echo "============================================================"
echo ""

# テスト設定
TESTS=(
    "test_single_blocks:Single Block Unit Tests"
    "test_single_blocks_extra:Single Block Unit Tests (extra)"
    "active:Basic Strategy Test"
    "test_strategy_advanced:Advanced Strategy Test"
    "test_strategy_all_blocks:All Blocks Comprehensive Test"
)

for test_info in "${TESTS[@]}"; do
    IFS=':' read -r test_name test_desc <<< "$test_info"
    
    echo "------------------------------------------------------------"
    echo "Running: $test_desc"
    echo "Config: tester_${test_name}.ini"
    echo "------------------------------------------------------------"
    
    # MT5をストラテジーテスターモードで起動
    # Note: Wineを使用している場合は wine コマンドが必要
    wine "$TERMINAL" /config:"$MT5_PATH/config/tester_${test_name}.ini" /tester
    
    # テスト完了を待つ
    echo "Test started. Waiting for completion..."
    sleep 5
    
    echo ""
done

echo "============================================================"
echo "All tests queued. Check MT5 Tester for results."
echo "============================================================"
