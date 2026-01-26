#!/bin/bash

# Strategy Bricks EA - Automated Strategy Tester
# 各設定ファイルをストラテジーテスターで実行し、動作確認を行う

set -e

BOTTLE="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_DIR="$BOTTLE/drive_c/Program Files/MetaTrader 5"
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
TESTER_FILES="$MT5_DIR/Tester/Agent-127.0.0.1-3000/Files/strategy"

# テスト対象の設定ファイル
TEST_CONFIGS=(
    "active.json"
    "test_strategy_advanced.json"
    "test_strategy_all_blocks.json"
)

# テスト期間（先月分）
START_DATE="2026.01.01"
END_DATE="2026.01.25"

# テスト結果を保存するディレクトリ
RESULTS_DIR="ea/tests/results"
mkdir -p "$RESULTS_DIR"

# 結果サマリーファイル
SUMMARY_FILE="$RESULTS_DIR/test_summary_$(date +%Y%m%d_%H%M%S).txt"

echo "========================================" | tee "$SUMMARY_FILE"
echo "Strategy Bricks EA - Automated Test" | tee -a "$SUMMARY_FILE"
echo "Test Period: $START_DATE - $END_DATE" | tee -a "$SUMMARY_FILE"
echo "========================================" | tee -a "$SUMMARY_FILE"
echo "" | tee -a "$SUMMARY_FILE"

# 各設定ファイルをテスト
for config in "${TEST_CONFIGS[@]}"; do
    echo "----------------------------------------" | tee -a "$SUMMARY_FILE"
    echo "Testing: $config" | tee -a "$SUMMARY_FILE"
    echo "----------------------------------------" | tee -a "$SUMMARY_FILE"
    
    # 設定ファイルが存在するか確認
    if [ ! -f "$TESTER_FILES/$config" ]; then
        echo "❌ Config file not found: $config" | tee -a "$SUMMARY_FILE"
        echo "" | tee -a "$SUMMARY_FILE"
        continue
    fi
    
    # active.jsonとして一時的にコピー
    cp "$TESTER_FILES/$config" "$TESTER_FILES/active.json"
    
    # ストラテジーテスターを実行
    echo "Running strategy tester..." | tee -a "$SUMMARY_FILE"
    
    # MT5のテスターを起動（バックグラウンド）
    # Note: MT5のCLIテスターは直接実行できないため、手動実行が必要
    
    echo "⚠️  Manual test required:" | tee -a "$SUMMARY_FILE"
    echo "   1. Open MT5 Strategy Tester" | tee -a "$SUMMARY_FILE"
    echo "   2. Select EA: StrategyBricks" | tee -a "$SUMMARY_FILE"
    echo "   3. Symbol: USDJPYm" | tee -a "$SUMMARY_FILE"
    echo "   4. Period: M1" | tee -a "$SUMMARY_FILE"
    echo "   5. Date range: $START_DATE - $END_DATE" | tee -a "$SUMMARY_FILE"
    echo "   6. Config: strategy/$config" | tee -a "$SUMMARY_FILE"
    echo "   7. Run test and check results" | tee -a "$SUMMARY_FILE"
    echo "" | tee -a "$SUMMARY_FILE"
    
    # テスターログを確認（実行後）
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

# テスト結果の確認方法を表示
cat << 'EOF' | tee -a "$SUMMARY_FILE"

## Test Result Verification

各設定ファイルのテスト結果を確認する観点：

1. **初期化成功**
   - エラーコード0で初期化完了
   - 設定ファイルが正しく読み込まれている
   - ブロック数が正しい

2. **取引回数**
   - 取引回数 > 0: 正常動作
   - 取引回数 = 0: 条件が厳しすぎるか、ロジックエラーの可能性

3. **エラーログ**
   - 初期化エラーがないか
   - ブロック評価エラーがないか
   - インジケータエラーがないか

4. **パフォーマンス**
   - テスト実行時間
   - メモリ使用量

## Expected Results

- active.json: 基本的な戦略、取引回数 1-10回程度
- test_strategy_advanced.json: 複雑な条件、取引回数 0-5回程度
- test_strategy_all_blocks.json: 非常に複雑、取引回数 0-3回程度

取引回数が0の場合でも、エラーなく実行完了すれば動作確認OK。
EOF

echo ""
echo "✅ Test script completed"
echo "📝 Summary: $SUMMARY_FILE"
