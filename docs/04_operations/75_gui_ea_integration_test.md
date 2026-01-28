# GUI-EA 統合テスト（Windows）

## 目的

GUI Builderが生成する `blockId` と EA側の参照整合性を検証します。  
`{typeId}#{index}` 形式の一致、参照解決、重複排除が主目的です。

## テスト資材

- 設定ファイル: `ea/tests/gui_integration_test.json`
- スクリプト: `ea/src/TestGuiIntegration.mq5`
- 生成物検証: `ea/src/TestGuiGeneratedConfigs.mq5`
- 補助スクリプト:
  - `scripts/run_gui_integration_flow.ps1`
  - `scripts/run_gui_integration_suite.ps1`
  - `scripts/run_gui_e2e_suite.ps1`
  - `scripts/compile-gui-test.ps1`
- 仕様: `docs/03_design/45_interface_contracts.md`

## 実行方法

### 方法A: スクリプト実行

1. MetaEditorで `ea/src/TestGuiIntegration.mq5` をコンパイル  
2. MT5を起動  
3. ナビゲーター > スクリプト > TestGuiIntegration をチャートへドラッグ

### 方法B: EAで読み込み

```powershell
$mt5Terminal = "$env:APPDATA\MetaQuotes\Terminal\<TERMINAL_ID>"
Copy-Item "ea\tests\gui_integration_test.json" `
  "$mt5Terminal\MQL5\Files\strategy\active.json" -Force
```

1. EAをチャートにアタッチ  
2. 入力パラメータ: `InpConfigPath=strategy/active.json`

## 期待される結果

- Config load 成功
- blockId参照が全て解決
- 重複なし
- 形式違反なし

例（Expertsログ）:
```
CONFIG_LOADED: gui_integration_test.json
BLOCK_REFERENCES_VALID: count=...
SHARED_BLOCK_VERIFIED: filter.spreadMax#1
```

## トラブルシューティング

### エラー: Config file not found
- `MQL5/Files/strategy/` にコピーされているか確認

### エラー: Block reference not found
- `conditions[].blockId` と `blocks[].id` が完全一致しているか確認

### エラー: Duplicate blockId detected
- `blocks[]` に重複がないか確認

### エラー: Invalid blockId format
- 形式が `{typeId}#{index}` になっているか確認
