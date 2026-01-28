# MT5 Strategy Tester 実行ガイド（Windows）

## 対象

Windows 環境で EA + strategy_config を実行し、動作確認するための手順です。  
Wine（macOS）での運用メモは末尾に記載しています。

## 1. MT5データフォルダを確認

1. MT5を起動  
2. メニュー: **ファイル > データフォルダを開く**  

以降のパス例は次を基準にします:

```
%APPDATA%\MetaQuotes\Terminal\<TERMINAL_ID>\
```

## 2. EAファイルを配置（初回のみ）

```powershell
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>"

# EA本体
$destEA = "$mt5Terminal\MQL5\Experts\StrategyBricks"
New-Item -ItemType Directory -Path $destEA -Force
Copy-Item "ea\src\StrategyBricks.mq5" $destEA -Force

# インクルード
$destInclude = "$mt5Terminal\MQL5\Include\StrategyBricks"
New-Item -ItemType Directory -Path $destInclude -Force
Copy-Item "ea\include\*" $destInclude -Recurse -Force
```

Note:
- If `-ReportPath` is omitted, the report is saved as `ea/tests/results/<config>.htm`.
- A block summary is generated alongside the report: `<config>_block_summary.txt/json`.

## 3. 設定ファイルを配置

### GUI生成物（E2E）

```powershell
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>"
Copy-Item "$env:TEMP\strategy-bricks-e2e\active.json" `
  "$mt5Terminal\MQL5\Files\strategy\active.json" -Force
```

### EAテスト用（標準セット）

```powershell
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>"
New-Item -ItemType Directory -Path "$mt5Terminal\MQL5\Files\strategy" -Force
Copy-Item "ea\tests\*.json" "$mt5Terminal\MQL5\Files\strategy\" -Force
```

### 補助スクリプト（Windows）

GUI 出力や任意パスの設定ファイルを使う場合は、以下のスクリプトが便利です。

```powershell
# GUI E2E → GUIバックテスト → Strategy Tester を一括実行
.\scripts\run_gui_e2e_suite.ps1 -Scenario recent-7d -SymbolBase USDJPY -Portable:$false

# 任意の設定で GUIバックテスト → Strategy Tester
.\scripts\run_gui_integration_flow.ps1 -ConfigPath "C:\path\to\strategy.json" -Portable:$false

# GUI e2e の出力を使って MT5 テスト準備
.\scripts\prepare_mt5_test.ps1 -ConfigPath "$env:TEMP\strategy-bricks-e2e\active.json"

# 既存のテスト設定（ea/tests）を使う
.\scripts\prepare_mt5_test.ps1 -ConfigFile "active.json"

# Strategy Tester を config で起動（実験的）
.\scripts\run_mt5_strategy_test.ps1 -ConfigPath "C:\path\to\active.json"
```

## 3.5 Strategy Tester をスクリプトで起動（実験的）

`scripts/run_mt5_strategy_test.ps1` を使うと、設定ファイルを渡して
Strategy Tester を自動実行できます。

```powershell
# 例: active.json を使って実行
.\scripts\run_mt5_strategy_test.ps1 -Portable:$false -ReportPath "tmp\backtest\mt5_report"

# 任意の設定ファイルを使う
.\scripts\run_mt5_strategy_test.ps1 -Portable:$false -ConfigPath "C:\path\to\strategy.json" -ReportPath "tmp\backtest\custom_report"
```

パラメータ:
- `-Portable:$false` : AppData 配下の MT5 データディレクトリを使用
- `-ReportPath` : レポート出力先。省略時は `ea/tests/results/<config>.htm`
- `-ConfigPath` : 任意の strategy_config.json を指定
- `-ExpertPath` : EA のパス（既定: `StrategyBricks\StrategyBricks`）

※ `/portable` で起動した MT5 はインストールディレクトリ配下をデータフォルダとして使います。  
　通常インストール環境では `-Portable:$false` を指定してください。

## 3.6 単体ブロックテスト

単体ブロックが **1ブロック=1戦略** で動くかを検証します。
`ea/tests/test_single_blocks.json` と `ea/tests/test_single_blocks_extra.json` を利用します。

```powershell
# 単体ブロック Strategy Tester 実行
.\scripts\run_mt5_strategy_test.ps1 -Portable:$false `
  -ConfigPath ".\ea\tests\test_single_blocks.json" `
  -ReportPath "tmp\backtest\single_block_report"

# Extra single-block tests (beyond MAX_STRATEGIES)
.\scripts\run_mt5_strategy_test.ps1 -Portable:$false `
  -ConfigPath ".\ea\tests\test_single_blocks_extra.json" `
  -ReportPath "tmp\backtest\single_block_extra_report"
```

結果の `Total trades` が 0 の場合は、条件やログを確認してください。

## 3.7 全ブロック網羅テスト

複数ブロックの組み合わせで動作するかを確認します。
`test_strategy_all_blocks.json` を使って網羅的に検証します。

```powershell
.\scripts\run_mt5_strategy_test.ps1 -Portable:$false `
  -ConfigPath ".\ea\tests\test_strategy_all_blocks.json" `
  -ReportPath "tmp\backtest\all_blocks_report"
```

`Total trades` が 0 の場合は、条件/期間/スプレッド等を見直してください。

## 4. EAをコンパイル

### 方法A: MetaEditorで手動コンパイル（推奨）

1. MT5で **F4** を押してMetaEditorを起動  
2. ナビゲーター: `Experts\StrategyBricks\StrategyBricks.mq5` を開く  
3. **F7** でコンパイル  

### 方法B: コマンドラインでコンパイル

```powershell
$metaeditor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
$eaPath = "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Experts\StrategyBricks\StrategyBricks.mq5"
& $metaeditor /compile:"$eaPath" /log
```

## 5. Strategy Tester 実行

1. MT5で **Ctrl+R** を押してStrategy Testerを開く  
2. 基本設定:
   - **EA**: `Experts\StrategyBricks\StrategyBricks.ex5`
   - **シンボル**: `USDJPYm` または `USDJPY`（ブローカー差あり）
   - **期間**: `M1`（1分足）
   - **日付**: `2025.10.01 - 2025.12.31`（3ヶ月）
   - **初期証拠金**: 1,000,000 JPY
   - **レバレッジ**: 1:100
   - **モデル**: Every tick（全ティック）
3. **入力パラメータ**タブ:
   - `InpConfigPath=strategy/<test_file>.json`
4. **スタート**をクリック

## 6. テストセット（推奨）

### EA標準テスト

| ファイル | 目的 | 期待 |
| --- | --- | --- |
| `test_single_blocks.json` | ブロック単体テスト | 50-200取引/戦略 |
| `test_single_blocks_extra.json` | Extra single-block tests | 1-20 trades/strategy |
| `active.json` | 基本動作テスト | 10-50取引 |
| `test_strategy_advanced.json` | 複合条件テスト | 3-30取引 |
| `test_strategy_all_blocks.json` | 全ブロック網羅 | 1-10取引 |

### GUI生成物（E2E）

| ファイル | 目的 |
| --- | --- |
| `basic-strategy.json` | スプレッド+MA+BB回帰 |
| `trend-only.json` | トレンドフィルタのみ |
| `multi-trigger.json` | 複数トリガー |

## 7. 判定基準

- **PASS**: 初期化成功・エラーなし・取引回数 > 0  
- **WARNING**: 初期化成功・エラーなし・取引回数 = 0  
- **FAIL**: 初期化失敗またはエラーあり  

## 8. トラブルシューティング

### コンパイルエラー: `StrategyBricks/... cannot open the file`
- `MQL5\Include\StrategyBricks\` 配下にファイルがあるか確認  
  ```powershell
  Test-Path "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Include\StrategyBricks\Common\Constants.mqh"
  ```

### 初期化エラー: `Config file not found`
- `MQL5\Files\strategy\` にファイルがあるか確認  
- `InpConfigPath` 先頭に `/` や `\\` を付けない

### Unknown block typeId
- GUI/EA契約の不一致（block_catalogとEA実装）  
- `docs/03_design/40_block_catalog_spec.md` と実装を確認

### 取引が発生しない
- 条件が厳しい可能性  
  - `maxSpreadPips` を緩める  
  - セッション制限を外す  
  - MA期間を短くする  
- 単体ブロックテストで原因を切り分け

## 9. ログ確認

- `MQL5/Logs` を確認  
  ```powershell
  Get-ChildItem "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>\MQL5\Logs" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  ```
- 詳細は `docs/04_operations/90_observability_and_testing.md`

## Wine（macOS）での実行メモ

Wine 環境でも Strategy Tester を運用する場合は、以下のスクリプトを使用します。
（MT5 の配置先はスクリプト内で定義されています）

```bash
# Wine 用のテスター設定ファイルを生成
python3 scripts/create_tester_configs.py

# テスト実行（全テスト）
bash scripts/run_mt5_tests.sh

# 単発テスト
bash scripts/run_mt5_tests.sh test_single_blocks
bash scripts/run_mt5_tests.sh test_single_blocks_extra
```

結果は `ea/tests/results/` に集約し、必要に応じて `scripts/record_test_results.py` で記録します。
