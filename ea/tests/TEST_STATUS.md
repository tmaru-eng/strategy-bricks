# テスト実行状況

## 現在の状態

### ファイル配置: ✅ 完了

すべてのテスト設定ファイルがテスターディレクトリに配置済み：

```
✅ active.json (2.7KB)
✅ test_single_blocks.json (25KB)
✅ test_strategy_advanced.json (8KB)
✅ test_strategy_all_blocks.json (11KB)
```

### EA コンパイル: ✅ 完了

```
✅ StrategyBricks.ex5 (227KB)
✅ 36ブロック実装済み
✅ BlockRegistry登録済み
```

### テスト実行: 🔄 進行中

#### 実行済みテスト

**2026-01-26 11:20 - active.json (手動実行)**

- ❌ **失敗**: File not found エラー
- **原因**: テスト期間が 2026.01.01-01.25 に設定されていた
- **対応**: 正しい期間（2025.10.01-12.31）で再実行が必要

## 次のアクション

### 1. テスト期間を修正して再実行

MT5ストラテジーテスターで以下を設定：

```
日付: 2025.10.01 - 2025.12.31 (3ヶ月)
```

**重要**: 2026年ではなく2025年です！

### 2. 推奨テスト順序

```
1️⃣ active.json
   - 期待: 10-50回の取引
   - 目的: 基本動作確認

2️⃣ test_single_blocks.json
   - 期待: 各ブロックで50-200回の取引
   - 目的: 問題のあるブロックを特定

3️⃣ test_strategy_advanced.json
   - 期待: 5-30回の取引
   - 目的: 複雑な条件の動作確認

4️⃣ test_strategy_all_blocks.json
   - 期待: 3-20回の取引
   - 目的: 全機能の統合確認
```

### 3. 結果記録

各テスト完了後：

```bash
python3 scripts/record_test_results.py
```

## クイックスタート

```bash
# 1. MT5起動
open "/Applications/MetaTrader 5.app"

# 2. ストラテジーテスター設定
#    - EA: Experts\StrategyBricks\StrategyBricks.ex5
#    - シンボル: USDJPYm
#    - 期間: M1
#    - 日付: 2025.10.01 - 2025.12.31 ← 重要！
#    - InpConfigPath: strategy/active.json

# 3. スタートボタンをクリック

# 4. 結果確認
#    - ジャーナルタブ: 初期化成功を確認
#    - 結果タブ: 取引回数を確認

# 5. 結果記録
python3 scripts/record_test_results.py
```

## 確認事項

### テスト実行前

- [ ] MT5が起動している
- [ ] ストラテジーテスターが開いている
- [ ] 日付が **2025.10.01 - 2025.12.31** に設定されている
- [ ] InpConfigPath が正しく設定されている

### テスト実行中

- [ ] ジャーナルに "Strategy Bricks EA initialized successfully" が表示される
- [ ] エラーメッセージがない
- [ ] プログレスバーが進んでいる

### テスト完了後

- [ ] 取引回数が0より大きい
- [ ] 結果タブにデータが表示される
- [ ] エラーがない

## トラブルシューティング

### "File not found" エラー

```bash
# ファイルの存在確認
ls -la "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/"

# ファイルが無い場合はコピー
cp ea/tests/*.json "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/"
```

### 取引回数が0

1. **単体ブロックテストを実行** (`test_single_blocks.json`)
2. **ジャーナルでエラーを確認**
3. **テスト期間を確認** (2025年になっているか)

## ドキュメント

- 📖 **クイックスタート**: `docs/04_operations/MT5_QUICK_START.md`
- 📖 **詳細ガイド**: `docs/04_operations/MT5_MANUAL_TEST_GUIDE.md`
- 📖 **テスト戦略**: `docs/04_operations/80_testing.md`

## 更新履歴

- 2026-01-26 11:20: 初回テスト実行（期間設定ミス）
- 2026-01-26 11:30: テスト期間修正が必要と判明
