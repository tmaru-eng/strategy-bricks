# MT5 ストラテジーテスター - クイックスタートガイド

## 問題: "File not found: strategy/active.json"

このエラーが出る場合、以下を確認してください。

## 解決方法

### 1. ファイルの存在確認

```bash
ls -la "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/"
```

ファイルが存在しない場合：

```bash
# テスト設定ファイルをコピー
cp ea/tests/*.json "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/"
```

### 2. MT5ストラテジーテスターでの設定

#### ステップ1: MT5を起動

```bash
open "/Applications/MetaTrader 5.app"
```

#### ステップ2: ストラテジーテスターを開く

- メニュー: **表示** → **ストラテジーテスター**
- または: `Ctrl+R` (Windows) / `Cmd+R` (Mac)

#### ステップ3: 基本設定

| 項目 | 設定値 |
|------|--------|
| **エキスパートアドバイザ** | `Experts\StrategyBricks\StrategyBricks.ex5` |
| **シンボル** | `USDJPYm` |
| **期間** | `M1` |
| **日付** | `2025.10.01` - `2025.12.31` |
| **モデル** | `全ティック` |
| **最適化** | オフ |

#### ステップ4: エキスパート設定

1. **「エキスパート設定」ボタンをクリック**
2. **「入力」タブを選択**
3. **`InpConfigPath`** を探す
4. 値を以下のいずれかに設定：
   - `strategy/active.json` ← 基本テスト
   - `strategy/test_single_blocks.json` ← 単体ブロックテスト
   - `strategy/test_strategy_advanced.json` ← 高度な戦略
   - `strategy/test_strategy_all_blocks.json` ← 全ブロック

**重要**: パスの先頭に `/` や `\` を付けないでください

#### ステップ5: テスト開始

1. **「スタート」ボタンをクリック**
2. テスト実行を待つ（3-5分）
3. 結果を確認

## テスト結果の確認

### ジャーナルタブ

ストラテジーテスター下部の「ジャーナル」タブで以下を確認：

✅ **成功の場合**:
```
Strategy Bricks EA initialized successfully
Preloaded XX blocks
Strategies: XX
```

❌ **失敗の場合**:
```
File not found: strategy/active.json
Failed to load config
```

### 結果タブ

- **取引回数**: 0より大きい
- **損益**: 表示される
- **グラフ**: 資産曲線が表示される

## トラブルシューティング

### エラー: "File not found"

**原因**: 設定ファイルがテスターディレクトリにない

**解決**:
```bash
# ファイルをコピー
cp ea/tests/active.json "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/"

# 確認
ls -la "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/Files/strategy/active.json"
```

### エラー: "Unknown block typeId"

**原因**: ブロックがBlockRegistryに登録されていない

**解決**: `ea/include/Core/BlockRegistry.mqh` を確認

### 取引回数が0

**原因**: 
1. 戦略条件が厳しすぎる
2. テスト期間が短すぎる
3. ブロックが正しく動作していない

**解決**:
1. `test_single_blocks.json` で単体テスト実行
2. テスト期間を2025.10.01-12.31（3ヶ月）に設定
3. ジャーナルでエラーを確認

## 推奨テスト順序

### 1. まず基本テスト

```
設定: strategy/active.json
期待: 10-50回の取引
目的: 基本動作確認
```

### 2. 単体ブロックテスト

```
設定: strategy/test_single_blocks.json
期待: 各ブロックで50-200回の取引
目的: 問題のあるブロックを特定
```

### 3. 高度な戦略テスト

```
設定: strategy/test_strategy_advanced.json
期待: 5-30回の取引
目的: 複雑な条件の動作確認
```

### 4. 全ブロック網羅テスト

```
設定: strategy/test_strategy_all_blocks.json
期待: 3-20回の取引
目的: 全機能の統合確認
```

## テスト結果の記録

テスト完了後、結果を記録：

```bash
python3 scripts/record_test_results.py
```

対話形式で質問に答えると、自動的にレポートが生成されます。

## よくある質問

### Q: テストに時間がかかりすぎる

A: モデルを「始値のみ」に変更すると高速化できますが、精度は下がります。
   正確なテストには「全ティック」を使用してください。

### Q: 複数のエージェントでテストできる？

A: はい。Agent-127.0.0.1-3001, 3002 などのディレクトリにも設定ファイルをコピーすれば、
   並列でテストできます。

### Q: 過去のテスト結果を見たい

A: `ea/tests/results/` ディレクトリに保存されています。

## 次のステップ

1. ✅ 基本テスト実行
2. ✅ 結果記録
3. ❌ 失敗したテストの原因調査
4. 🔧 ブロック実装の修正
5. 🔄 再テスト

詳細なガイド: `docs/04_operations/MT5_MANUAL_TEST_GUIDE.md`
