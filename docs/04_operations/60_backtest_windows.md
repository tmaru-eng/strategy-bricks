# バックテスト（Windowsのみ）

## 位置づけ

GUIからバックテストエンジンを起動し、結果JSONを取得する導線です。  
**現状は Windows のみ対応**で、Wine/macOS では UI が無効化されます。

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

- 開発: `<repo_root>/ea/tests/<configBase>_results.json`
- パッケージ: `<app_root>/ea/tests/<configBase>_results.json`
- `configBase` は GUI が保存した設定ファイル名（例: `strategy_<timestamp>.json`）の拡張子を除いたもの
- GUIのエクスポート機能で任意パスへ保存可能
- これらは一時生成物のため、リポジトリにはコミットしない

## 設定ファイルのバックテスト（CLI）

GUIで出力した `active.json` などを、バックテストエンジンに直接渡して実行できます。
**バックテストエンジン自体は Windows のみ対応**です。
一時生成物は `tmp/` 配下に出力する運用を推奨します（git 管理外）。

### Python で実行（開発）

```powershell
$repoRoot = (Resolve-Path .)
$outDir = Join-Path $repoRoot "tmp\backtest"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

python\backtest_engine.py `
  --config "C:\path\to\active.json" `
  --symbol USDJPY `
  --timeframe M1 `
  --start 2024-01-01T00:00:00Z `
  --end 2024-01-31T23:59:59Z `
  --output (Join-Path $outDir "results_$(Get-Date -Format yyyyMMdd_HHmmss).json")
```

### exe で実行（開発）

```powershell
.\python\dist\backtest_engine.exe `
  --config "C:\path\to\active.json" `
  --symbol USDJPY `
  --timeframe M1 `
  --start 2024-01-01T00:00:00Z `
  --end 2024-01-31T23:59:59Z `
  --output ".\tmp\backtest\results_$(Get-Date -Format yyyyMMdd_HHmmss).json"
```

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
