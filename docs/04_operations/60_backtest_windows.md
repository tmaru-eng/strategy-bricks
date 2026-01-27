# バックテスト（Windowsのみ）

## 位置づけ

GUIからバックテストエンジンを起動し、結果JSONを取得する導線です。  
**非Windowsは未対応**のため、UIは環境チェックで無効化されます。

## 前提

- Windows + MT5インストール済み（起動・ログイン済み）
- backtest_engine.exe が配置済み
  - 開発: `python/dist/backtest_engine.exe`
  - 本番: `resources/python/backtest_engine.exe`（配布アプリ内）
- Builderでstrategy_configを生成できること

## exe準備（開発）

1. backtest_engine.exe を生成  
   ```powershell
   cd python
   powershell -ExecutionPolicy Bypass -File build-exe.ps1
   ```
2. `python/dist/backtest_engine.exe` の存在を確認

## 実行手順（GUI）

1. GUI起動（開発なら `cd gui; npm run dev`）
2. Backtestパネルを開く
3. 環境チェックが `OK` になることを確認
4. シンボル/時間足/期間を入力
5. 実行 → 完了

## 結果ファイル

- 開発: `<repo_root>/ea/tests/results_<timestamp>.json`
- パッケージ: `<app_root>/ea/tests/results_<timestamp>.json`
- GUIのエクスポート機能で任意パスへ保存可能

## トラブルシューティング

### エラー: 「バックテストエンジンが見つかりません」
- 開発: `python/dist/backtest_engine.exe`
- 本番: `resources/python/backtest_engine.exe`

### エラー: 「バックテストプロセスの起動に失敗しました」
- exeが起動できるか確認  
  ```powershell
  .\python\dist\backtest_engine.exe --help
  ```

### エラー: 「MT5初期化失敗」
- MT5を起動し、口座ログイン済みか確認

### エラー: 「データ取得失敗」
- MT5側で対象シンボルのヒストリカルデータを更新

## 実行I/F（参考）

- 引数: `--config`, `--symbol`, `--timeframe`, `--start`, `--end`, `--output`
