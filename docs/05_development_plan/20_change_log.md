# 変更ログ（実装メモ）

本ドキュメントは、散在していた修正メモを統合したものです。  
**運用・手順は `docs/04_operations` を正**とします。

## 2026-01-26: Backtest / GUI修正

### Backtest機能

- backtestエンジンをexe化（`python/build-exe.ps1`、`python/backtest_engine.spec`）
- Electron側でexeパスを検出（開発: `python/dist/backtest_engine.exe` / 本番: `resources/python/backtest_engine.exe`）
- 環境チェックとエラーメッセージ整備
- BacktestパネルのUI改善（環境チェック中の表示/エラー表示）

### Backtest実行時のエクスポート挙動修正

- `buildStrategyConfig()` を追加し、バックテスト実行時に保存ダイアログを出さない
- `exportConfig()` と用途を分離（ユーザー保存時のみダイアログ）

### GUI Canvas / File Ops

- ReactFlowキャンバスの高さを明示し、ノード描画を安定化
- 新規/開く/保存ボタンのハンドラを追加
- IPC経由でファイルダイアログ/読み書きを提供

### GUIレイアウト/カテゴリ色

- 初期ノード配置の改善（視認性向上）
- `volume` / `bill` / `osc` カテゴリの色定義を追加
- 新規作成時のレイアウトを統一
