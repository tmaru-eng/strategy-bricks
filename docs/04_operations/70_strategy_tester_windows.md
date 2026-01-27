# MT5 Strategy Tester 実行ガイド（Windows）

## 対象

Windows環境で EA + strategy_config を実行し、動作確認するための手順です。  
**非Windowsは未対応**（既存のmacOS/Wine手順はサポート外）。

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
