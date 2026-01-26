# Strategy Bricks - コンパイルとテスト手順

## 現在の状態

✅ GUIのe2eテストで3つの設定ファイルを生成済み
✅ MT5にファイルをコピー済み
❌ EAのコンパイルが必要

## 生成された設定ファイル

以下の3つのテストケースが生成されています：

1. **basic-strategy.json** - 基本戦略（スプレッド + MA + BB回帰）
2. **trend-only.json** - トレンドフィルタのみ
3. **multi-trigger.json** - 複数トリガー（BB + RSI）

ファイル場所：
- `C:\Users\ctake\AppData\Roaming\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Files\strategy\`

## 手順1: EAをコンパイル

### 方法A: MetaEditorで手動コンパイル（推奨）

1. MT5を起動
2. **F4キー** を押してMetaEditorを開く
3. ナビゲーター: `Experts\StrategyBricks\StrategyBricks.mq5` を開く
4. **F7キー** を押してコンパイル
5. 下部の「Errors」タブでエラーを確認
   - エラーがある場合: エラーメッセージをコピーして報告
   - エラーがない場合: 「0 error(s), 0 warning(s)」と表示される

### 方法B: コマンドラインでコンパイル

```powershell
# MetaEditorのパス
$metaeditor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"

# EAのパス
$eaPath = "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Experts\StrategyBricks\StrategyBricks.mq5"

# コンパイル実行
& $metaeditor /compile:"$eaPath" /log
```

## 手順2: ストラテジーテスターで実行

### 基本設定

1. MT5で **Ctrl+R** を押してStrategy Testerを開く
2. 以下を設定:
   - **EA**: `Experts\StrategyBricks\StrategyBricks`
   - **シンボル**: `USDJPYm` または `USDJPY`
   - **期間**: `M1`（1分足）
   - **日付**: `2025.10.01 - 2025.12.31`（3ヶ月）
   - **初期証拠金**: 1,000,000 JPY
   - **レバレッジ**: 1:100
   - **モデル**: Every tick（全ティック）

### テストケース1: basic-strategy.json

1. **入力パラメータ**タブをクリック
2. `InpConfigPath` を `strategy/basic-strategy.json` に変更
3. **スタート**ボタンをクリック
4. 結果を確認:
   - **結果**タブ: 取引履歴
   - **グラフ**タブ: 残高曲線
   - **レポート**タブ: 詳細統計

### テストケース2: trend-only.json

1. **入力パラメータ**タブで `InpConfigPath` を `strategy/trend-only.json` に変更
2. **スタート**ボタンをクリック
3. 結果を確認

### テストケース3: multi-trigger.json

1. **入力パラメータ**タブで `InpConfigPath` を `strategy/multi-trigger.json` に変更
2. **スタート**ボタンをクリック
3. 結果を確認

## 期待される結果

各テストケースで取引が発生することを確認します。

### 正常な場合

- **取引回数**: 1回以上
- **損益**: SL/TPが正しく機能している
- **ログ**: エラーなし

### 取引が0回の場合（問題あり）

以下を確認:

1. **エキスパートタブのログ**:
   - 初期化エラー: 設定ファイルが読み込めていない
   - ブロック評価エラー: ブロック実装に問題がある
   - スプレッド超過: `maxSpreadPips`を大きくする
   - セッション外: 時間帯設定を確認

2. **設定ファイルの内容**:
   ```powershell
   type "C:\Users\ctake\AppData\Roaming\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Files\strategy\basic-strategy.json"
   ```
   - `strategies`配列が空でないか
   - `blocks`配列にブロック定義があるか

3. **条件が厳しすぎる可能性**:
   - スプレッドフィルタ: `maxSpreadPips`を5.0に増やす
   - セッションフィルタ: 時間帯を24時間に設定
   - トレンドフィルタ: MA期間を短くする（20→10）

## トラブルシューティング

### コンパイルエラー: 'StrategyBricks/...' - cannot open the file

**原因**: インクルードファイルのパスが正しくない

**解決策**: ファイルが正しくコピーされているか確認
```powershell
Test-Path "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Include\StrategyBricks\Common\Constants.mqh"
```

### 初期化エラー: Config file not found

**原因**: 設定ファイルのパスが間違っている

**解決策**: 
1. ファイルが存在するか確認
2. 入力パラメータを確認: `InpConfigPath=strategy/basic-strategy.json`

### 取引が発生しない

**原因**: 条件が厳しすぎる、またはブロック実装の問題

**解決策**:
1. EA側のテストファイル`ea/tests/active.json`を使用
2. ログでブロック評価結果を確認
3. 単体ブロックテスト`ea/tests/test_single_blocks.json`を実行

## 次のステップ

取引が発生したら:

1. **取引回数を確認**: 期待通りの回数か
2. **損益を確認**: SL/TPが正しく機能しているか
3. **ログを確認**: ブロック評価が正しく行われているか
4. **パラメータを調整**: より良い結果を目指す

取引が発生しない場合:

1. **ログ分析**: どのブロックでFAILしているか
2. **パラメータ調整**: 条件を緩める
3. **ブロック実装確認**: コードレビュー
4. **EA側のテストファイルを使用**: `ea/tests/active.json`

## 参考コマンド

### 設定ファイルを確認
```powershell
type "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Files\strategy\basic-strategy.json"
```

### ログを確認
```powershell
Get-ChildItem "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Logs" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

### EA側のテストファイルをコピー
```powershell
Copy-Item "ea\tests\active.json" "$env:APPDATA\MetaQuotes\Terminal\082F53F5881F3D6022DF806C3D307B50\MQL5\Files\strategy\active.json" -Force
```
