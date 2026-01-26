# ブロック個別テスト - 実行状況

## 現在の状況

### ✅ 完了した作業

1. **ブロック個別テスト用設定ファイルの作成**
   - `block-test-spread-only.json` - スプレッドフィルターのみ
   - `block-test-ma-trend.json` - MAトレンドフィルターのみ
   - `block-test-bb-trigger.json` - BBリエントリートリガーのみ

2. **ファイルのコピー**
   - すべてのファイルがMT5 Tester Agentディレクトリにコピー済み
   - パス: `C:\Users\ctake\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\Agent-127.0.0.1-3000\Files\strategy\`

3. **GUI生成設定ファイルのテスト**
   - `basic-strategy.json` - 3つのブロックを組み合わせ → **取引0回**
   - `trend-only.json` - トレンドフィルターのみ → **取引0回**
   - `multi-trigger.json` - 複数トリガー → **取引0回**

### 🔍 問題の特定

GUI生成の設定ファイルでは、すべてのテストで取引が0回でした。原因を特定するため、各ブロックを個別にテストする必要があります。

---

## 📋 次のステップ: MT5でブロックテストを実行

### テスト1: スプレッドフィルターのみ（最も緩い条件）

**目的:** EAの基本動作とファイル読み込みを確認

**設定:**
```
InpConfigPath = strategy/block-test-spread-only.json
```

**期待結果:**
- ✅ 初期化成功
- ✅ ブロック1個読み込み成功
- ✅ **多数の取引が発生**（スプレッド50pips以下という緩い条件）

**もし取引が0回なら:**
- EAの初期化に問題がある
- ファイルパスが間違っている
- セッション設定に問題がある

---

### テスト2: MAトレンドフィルターのみ

**目的:** MAロジックの動作を確認

**設定:**
```
InpConfigPath = strategy/block-test-ma-trend.json
```

**期待結果:**
- ✅ 初期化成功
- ✅ ブロック1個読み込み成功
- ⚠️ **中程度の取引が発生**（価格がMA(20)より上の時のみ）

**もし取引が0回なら:**
- MAロジックに問題がある
- パラメータ設定が厳しすぎる
- MA計算に問題がある

---

### テスト3: BBリエントリートリガーのみ

**目的:** BBロジックの動作を確認

**設定:**
```
InpConfigPath = strategy/block-test-bb-trigger.json
```

**期待結果:**
- ✅ 初期化成功
- ✅ ブロック1個読み込み成功
- ⚠️ **少数の取引が発生**（BB下限からの回帰という厳しい条件）

**もし取引が0回なら:**
- BBロジックに問題がある
- パラメータ設定が厳しすぎる
- BB計算に問題がある

---

## 🎯 MT5 Strategy Tester 設定

### ファイル配置の重要事項

**MT5 Strategy Testerでテストを実行する前に、設定ファイルを正しい場所にコピーしてください:**

```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\Common\Files\strategy\
```

**理由:** EAは `FILE_COMMON` フラグを使用してファイルを読み込むため、`Terminal\Common\Files\` ディレクトリが使用されます。

**コピーコマンド:**
```powershell
$commonFiles = "$env:APPDATA\MetaQuotes\Terminal\Common\Files\strategy"
if (-not (Test-Path $commonFiles)) { New-Item -ItemType Directory -Path $commonFiles -Force }
Copy-Item ea\tests\block-test-*.json $commonFiles\
```

---

### 共通設定

| 項目 | 設定値 |
|------|--------|
| EA | `StrategyBricks` |
| Symbol | `USDJPYm` |
| Period | `M1` |
| Date | `2026.01.01 - 2026.01.25` (約1ヶ月) |
| Deposit | `1,000,000 JPY` |
| Leverage | `1:100` |
| Optimization | `Disabled` |

### テスト実行手順

1. MT5を開く
2. `Ctrl+R` でStrategy Testerを開く
3. 上記の共通設定を入力
4. **Inputs** タブで `InpConfigPath` を設定
5. **Start** ボタンをクリック
6. **Experts** タブでログを確認
7. **Results** タブで取引回数を確認

---

## 📊 結果の記録

### Test 1: block-test-spread-only.json

- [ ] 実行済み
- 初期化: ⬜ 成功 / ⬜ 失敗
- ブロック読み込み: ⬜ 1個 / ⬜ 0個
- 取引回数: _____ 回
- 備考: _____________________

### Test 2: block-test-ma-trend.json

- [ ] 実行済み
- 初期化: ⬜ 成功 / ⬜ 失敗
- ブロック読み込み: ⬜ 1個 / ⬜ 0個
- 取引回数: _____ 回
- 備考: _____________________

### Test 3: block-test-bb-trigger.json

- [ ] 実行済み
- 初期化: ⬜ 成功 / ⬜ 失敗
- ブロック読み込み: ⬜ 1個 / ⬜ 0個
- 取引回数: _____ 回
- 備考: _____________________

---

## 🔧 トラブルシューティング

### すべてのテストで取引が0回の場合

1. **Expertsタブを確認:**
   - `INIT_START` イベントが出力されているか
   - `CONFIG_LOADED` イベントが出力されているか
   - `BLOCK_CREATED` イベントが出力されているか
   - エラーメッセージがないか

2. **ファイルパスを確認:**
   - `InpConfigPath` が `strategy/block-test-spread-only.json` になっているか
   - ファイルが正しい場所にコピーされているか

3. **セッション設定を確認:**
   - `session.enabled` が `false` になっているか（ブロックテストでは無効）
   - 時間帯制限がないか

### スプレッドテストのみ成功、他が失敗の場合

- MAまたはBBのブロックロジックに問題がある
- パラメータを調整する必要がある
- ブロックの実装を確認する必要がある

---

## 📝 次のアクション

1. **まず `block-test-spread-only.json` をテスト**
   - これが成功すれば、EAの基本動作は正常
   - これが失敗すれば、EA初期化に問題がある

2. **結果に応じて次のテストを実行**
   - スプレッドテスト成功 → MAテストとBBテストを実行
   - スプレッドテスト失敗 → EA初期化を調査

3. **問題のあるブロックを特定**
   - 取引が0回のブロックを調査
   - ログで `BLOCK_EVAL` イベントを確認
   - `FAIL` の理由を分析

4. **GUI統合テストに戻る**
   - すべてのブロックが正常に動作することを確認後
   - GUI生成の設定ファイルで再テスト

---

## 📂 関連ファイル

- `ea/tests/BLOCK_TEST_README.md` - ブロックテストの詳細説明
- `ea/tests/MT5_FILE_LOCATIONS.md` - **MT5ファイル配置ガイド（重要）**
- `ea/tests/block-test-spread-only.json` - スプレッドフィルターテスト
- `ea/tests/block-test-ma-trend.json` - MAトレンドテスト
- `ea/tests/block-test-bb-trigger.json` - BBトリガーテスト
- `ea/tests/basic-strategy.json` - GUI生成設定（参考）

---

## 📍 ファイル配置の重要事項

**MT5 Strategy Testerでテストを実行する前に:**

設定ファイルを以下の場所にコピーしてください:
```
C:\Users\{USERNAME}\AppData\Roaming\MetaQuotes\Terminal\Common\Files\strategy\
```

詳細は `ea/tests/MT5_FILE_LOCATIONS.md` を参照してください。

