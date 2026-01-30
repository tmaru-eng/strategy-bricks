# 検証・運用スクリプト

このディレクトリには、Windows と macOS/Wine の MT5/GUI テスト手順を補助する
スクリプトと、補助的な Python ツールを格納しています。

## Windows（PowerShell）

- `prepare_mt5_test.ps1`：任意の設定ファイルを MT5 にコピーしてテスト準備
- `run_mt5_strategy_test.ps1`: MT5 Strategy Tester (supports `-ConfigPath`, `-ReportPath`, `-Portable`)
- `compile_and_test_all.ps1`: EA/設定/Include を配置してコンパイル → MT5起動まで
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

## 役割と実行確認

| スクリプト | 役割 | 想定OS | 実行確認 |
| --- | --- | --- | --- |
| `compile_and_test_all.ps1` | EA配置/コンパイル/MT5起動の一括補助 | Windows | 実行確認済み（コンパイル成功） |
| `prepare_mt5_test.ps1` | 設定ファイルの配置 | Windows | 未実行（手順内で使用） |
| `run_mt5_strategy_test.ps1` | Strategy Tester の起動補助 | Windows | 未実行（手順内で使用） |
| `run_gui_integration_flow.ps1` | GUI→バックテスト→Strategy Tester 連結 | Windows | 未実行（手順内で使用） |
| `run_gui_integration_suite.ps1` | 連結テストの一括実行 | Windows | 未実行（手順内で使用） |
| `run_gui_e2e_suite.ps1` | E2E生成 + 連結テスト一括 | Windows | 未実行（手順内で使用） |
| `run_mt5_tests.sh` | Wine用 Strategy Tester 一括 | macOS/Wine | Windows/WSLではCRLFで失敗、macOS側は未確認 |
| `run_mt5_tester.sh` | Wine用 Strategy Tester 起動 | macOS/Wine | Windows/WSLではCRLFで失敗、macOS側は未確認 |
| `run_strategy_tests.sh` | 手動テスト手順の記録補助 | macOS/Wine | Windows/WSLではCRLFで失敗、macOS側は未確認 |

## 出力先メモ

- GUI e2e 生成物: `$env:TEMP\strategy-bricks-e2e\`
- 一時生成物（バックテスト等）: `tmp/`（git 管理外）
- テスト結果レポート: `ea/tests/results/`（git 管理外）
