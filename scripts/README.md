# 検証・運用スクリプト

このディレクトリには、Windows と macOS/Wine の MT5/GUI テスト手順を補助する
スクリプトと、補助的な Python ツールを格納しています。

## Windows（PowerShell）

- `prepare_mt5_test.ps1`：任意の設定ファイルを MT5 にコピーしてテスト準備
- `run_mt5_strategy_test.ps1`: MT5 Strategy Tester (supports `-ConfigPath`, `-ReportPath`, `-Portable`)
- `run_gui_integration_flow.ps1`：GUIビルダー出力の設定を使って GUIバックテスト → Strategy Tester を連続実行
- `run_gui_integration_suite.ps1`：指定ディレクトリ内の設定をまとめて結合テスト（GUIバックテスト → Strategy Tester）
- `run_gui_e2e_suite.ps1`：Playwright E2E でシナリオ設定を生成し、結合テストを一括実行

## Python ツール

- `validate_test_configs.py`：標準テスト設定（`ea/tests/*.json`）の整合性チェック
- `record_test_results.py`：手動テスト結果の対話記録（`ea/tests/results/` に出力）
- `automated_tester.py`：Wine/macOS の手動テスト補助

## macOS/Wine

- `run_mt5_tests.sh`
- `run_mt5_tester.sh`
- `run_strategy_tests.sh`
- `create_tester_configs.py`

## 出力先メモ

- GUI e2e 生成物: `$env:TEMP\strategy-bricks-e2e\`
- 一時生成物（バックテスト等）: `tmp/`（git 管理外）
- テスト結果レポート: `ea/tests/results/`（git 管理外）
