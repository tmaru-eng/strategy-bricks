# Strategy Bricks テスト実行ガイド

## 概要

このガイドでは、GUIで生成した設定ファイルをMT5のストラテジーテスターで実行する手順を説明します。

## 前提条件

- MT5がインストールされていること
- Node.js環境が整っていること（GUIビルド用）

## 手順

### 1. GUIで設定ファイルを生成

```bash
cd gui
npm install  # 初回のみ
npm run e2e  # E2Eテストを実行して設定ファイルを生成
```

生成されたファイル:
- `%TEMP%\strategy-bricks-e2e\active.json`
- `%TEMP%\strategy-bricks-e2e\profiles\e2e-profile.json`

### 2. 設定ファイルをMT5にコピー

```powershell
# MT5のFilesディレクトリにコピー
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50"
Copy-Item "$env:TEMP\strategy-bricks-e2e\active.json" "$mt5Terminal\MQL5\Files\strategy\active.json" -Force
```

### 3. EA側のソースコードをMT5にコピー（初回のみ）

```powershell
# EAソースコード
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50"
$destEA = "$mt5Terminal\MQL5\Experts\StrategyBricks"
New-Item -ItemType Directory -Path $destEA -Force
Copy-Item "ea\src\StrategyBricks.mq5" $destEA -Force

# インクルードファイル
$destInclude = "$mt5Terminal\MQL5\Include\StrategyBricks"
New-Item -ItemType Directory -Path $destInclude -Force
Copy-Item "ea\include\*" $destInclude -Recurse -Force
```

### 4. MT5でEAをコンパイル

1. MT5を起動
2. メニュー: ツール > MetaQuotes言語エディタ（MetaEditor）
3. ナビゲーター: Experts > StrategyBricks > StrategyBricks.mq5 を開く
4. F7キーを押してコンパイル
5. コンパイルエラーがないことを確認

### 5. ストラテジーテスターで実行

1. MT5のメニュー: 表示 > ストラテジーテスター（Ctrl+R）
2. 設定:
   - **EA**: `Experts\StrategyBricks\StrategyBricks.ex5`
   - **シンボル**: `USDJPYm` または `USDJPY`
   - **期間**: `M1`（1分足）
   - **日付**: `2025.10.01 - 2025.12.31`（3ヶ月）
   - **初期証拠金**: 1,000,000 JPY
   - **レバレッジ**: 1:100
3. **入力パラメータ**タブ:
   - `InpConfigPath`: `strategy/active.json`
4. **スタート**ボタンをクリック

### 6. 結果の確認

#### 取引が発生した場合（正常）

- **結果**タブ: 取引履歴が表示される
- **グラフ**タブ: 残高曲線が表示される
- **レポート**タブ: 詳細な統計情報

#### 取引が0回の場合（問題あり）

以下を確認:

1. **ログを確認**:
   - エキスパートタブでエラーメッセージを確認
   - 初期化エラー: 設定ファイルが読み込めていない
   - ブロック評価エラー: ブロック実装に問題がある

2. **設定ファイルを確認**:
   ```powershell
   type "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Files\strategy\active.json"
   ```
   - `strategies`配列が空でないか
   - `blocks`配列にブロック定義があるか
   - パラメータが正しいか

3. **ブロック実装を確認**:
   - `ea/include/Blocks/`以下のブロック実装
   - `BlockRegistry.mqh`にブロックが登録されているか

4. **条件が厳しすぎる可能性**:
   - スプレッドフィルタ: `maxSpreadPips`を大きくする
   - セッションフィルタ: 時間帯を広げる
   - トレンドフィルタ: MA期間を調整する

## トラブルシューティング

### コンパイルエラー

**エラー**: `'StrategyBricks/...' - cannot open the file`

**解決策**: インクルードファイルのパスを確認
```mql5
// StrategyBricks.mq5の先頭
#include <StrategyBricks/Core/StrategyEngine.mqh>
```

### 初期化エラー

**エラー**: `Config file not found: strategy/active.json`

**解決策**: 
1. ファイルパスを確認: `MQL5/Files/strategy/active.json`
2. 入力パラメータを確認: `InpConfigPath=strategy/active.json`

### 取引が発生しない

**原因1**: 条件が厳しすぎる

**解決策**: 
- EA側のテストファイル`ea/tests/active.json`を使用
- より緩い条件でテスト

**原因2**: ブロック実装の問題

**解決策**:
- ログでブロック評価結果を確認
- 単体ブロックテスト`ea/tests/test_single_blocks.json`を実行

## 次のステップ

取引が発生したら:

1. **取引回数を確認**: 期待通りの回数か
2. **損益を確認**: SL/TPが正しく機能しているか
3. **ログを確認**: ブロック評価が正しく行われているか
4. **パラメータを調整**: より良い結果を目指す

取引が発生しない場合:

1. **単体ブロックテスト**: `ea/tests/test_single_blocks.json`
2. **ログ分析**: どのブロックでFAILしているか
3. **パラメータ調整**: 条件を緩める
4. **ブロック実装確認**: コードレビュー

## 参考資料

- `ea/tests/README.md`: EA側のテスト戦略
- `docs/04_operations/80_testing.md`: テスト計画
- `docs/03_design/30_config_spec.md`: 設定ファイル仕様
- `docs/03_design/40_block_catalog_spec.md`: ブロックカタログ仕様

---

## GUI-EA統合テスト（v1.1追加）

### 概要

GUI BuilderとEA Runtime間のblockId参照整合性を検証する統合テストです。

### テスト目的

1. GUIが生成した設定ファイルをEAが正常に読み込めることを確認
2. すべてのblockId参照が解決できることを確認
3. 共有ブロックが正しく機能することを確認

### テスト設定ファイル

**ファイル**: `ea/tests/gui_integration_test.json`

**特徴**:
- 2つのstrategy（S1, S2）
- 5つのブロック
- 1つの共有ブロック（`filter.spreadMax#1`）
- 4つの固有ブロック

### 実行方法

#### Method 1: テストスクリプトを実行

```powershell
# テストスクリプトをコンパイル
cd ea/src
"C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:TestGuiIntegration.mq5

# MT5でスクリプトを実行
# 1. MT5を起動
# 2. ナビゲーター > スクリプト > TestGuiIntegration
# 3. チャートにドラッグ&ドロップ
```

#### Method 2: EAで読み込み

```powershell
# 設定ファイルをコピー
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50"
Copy-Item "ea\tests\gui_integration_test.json" "$mt5Terminal\MQL5\Files\strategy\active.json" -Force

# EAをチャートにアタッチ
# 入力パラメータ: InpConfigPath=strategy/active.json
```

### 期待される結果

#### Test 1: Config file load
```
✓ Config file loaded successfully
  File: strategy/gui_integration_test.json
  Size: XXXX characters
```

#### Test 2: Block references
```
✓ All Strategy 1 references resolved
  - filter.spreadMax#1
  - trend.maRelation#1
  - trigger.rsiLevel#1

✓ All Strategy 2 references resolved
  - filter.spreadMax#1
  - trend.maRelation#2
  - trigger.rsiLevel#2
```

#### Test 3: Shared blocks
```
✓ Shared block 'filter.spreadMax#1' used by both strategies
```

### トラブルシューティング

#### エラー: Config file not found

**原因**: 設定ファイルが正しい場所にない

**解決策**:
```powershell
# ファイルの存在確認
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50"
Test-Path "$mt5Terminal\MQL5\Files\strategy\gui_integration_test.json"

# ファイルをコピー
Copy-Item "ea\tests\gui_integration_test.json" "$mt5Terminal\MQL5\Files\strategy\" -Force
```

#### エラー: Block reference not found

**原因**: blockId参照が解決できない

**解決策**:
1. 設定ファイルを確認:
   ```powershell
   type "$mt5Terminal\MQL5\Files\strategy\gui_integration_test.json" | Select-String "blockId"
   ```
2. blocks[]配列にすべてのblockIdが存在することを確認
3. condition.blockIdとblocks[].idが完全一致することを確認（大文字小文字、スペース等）

#### エラー: Duplicate blockId detected

**原因**: blocks[]配列に重複したblockIdが存在

**解決策**:
1. 設定ファイルを確認:
   ```powershell
   type "$mt5Terminal\MQL5\Files\strategy\gui_integration_test.json" | Select-String '"id":'
   ```
2. 重複するblockIdを削除または名前を変更

#### エラー: Invalid blockId format

**原因**: blockIdが`{typeId}#{index}`形式に従っていない

**解決策**:
1. blockIdに`#`セパレータが含まれているか確認
2. `#`の後が数値であることを確認
3. 正しい形式の例: `filter.spreadMax#1`, `trend.maRelation#2`

### 検証ログイベント

成功時のログ:
```jsonl
{"ts":"2026-01-26 10:00:00","event":"CONFIG_LOADED","file":"gui_integration_test.json","strategyCount":2,"blockCount":5}
{"ts":"2026-01-26 10:00:00","event":"BLOCK_REFERENCES_VALID","count":5}
{"ts":"2026-01-26 10:00:00","event":"SHARED_BLOCK_VERIFIED","blockId":"filter.spreadMax#1","strategyCount":2}
```

失敗時のログ:
```jsonl
{"ts":"2026-01-26 10:00:00","event":"CONFIG_VALIDATION_FAILED","reason":"Block reference validation failed"}
{"ts":"2026-01-26 10:00:00","event":"UNRESOLVED_BLOCK_REFERENCE","blockId":"filter.spreadMax#2","strategy":"S1","ruleGroup":"RG1"}
{"ts":"2026-01-26 10:00:00","event":"DUPLICATE_BLOCK_ID","blockId":"filter.spreadMax#1","count":2}
{"ts":"2026-01-26 10:00:00","event":"INVALID_BLOCK_ID_FORMAT","blockId":"filter.spreadMax","reason":"Missing '#' separator"}
```

### 関連ドキュメント

- `ea/tests/GUI_INTEGRATION_TEST.md`: 詳細なテスト仕様
- `docs/03_design/45_interface_contracts.md`: blockId割り当てルール
- `docs/03_design/30_config_spec.md`: blockId形式仕様
- `.kiro/specs/gui-ea-config-integration-fix/`: 統合修正の仕様書
