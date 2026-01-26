# バックテストエンジンexe化への移行ガイド

## 概要

PythonスクリプトをPyInstallerでexe化し、Electronからexeを実行する方式に変更します。

## 完了したタスク

1. ✅ `python/build-exe.ps1` - PyInstallerビルドスクリプト作成
2. ✅ `python/backtest_engine.spec` - PyInstaller設定ファイル作成
3. ✅ `python/requirements.txt` - pyinstallerを追加

## 次のステップ

### 1. Pythonスクリプトのexe化

```powershell
cd python
powershell -ExecutionPolicy Bypass -File build-exe.ps1
```

これにより `python/dist/backtest_engine.exe` が生成されます。

### 2. gui/electron/main.ts の修正

以下の変更が必要です：

#### EnvironmentCheckResultインターフェースの更新

```typescript
interface EnvironmentCheckResult {
  isWindows: boolean
  backtestEnabled: boolean
  message?: string
  debug?: {
    enginePath: string | null
    engineExists: boolean
    checkedPaths: string[]
  }
}
```

#### EnvironmentCheckerクラスの簡素化

- `getEmbeddedPythonPath()` → `getBacktestEngineExePath()` に変更
- `checkPython()` メソッドを削除
- `checkMT5Library()` メソッドを削除
- `testPythonCommand()` → `testBacktestEngine()` に変更
- `pythonCommand` → `backtestEnginePath` に変更
- `getPythonCommand()` → `getBacktestEnginePath()` に変更

#### BacktestProcessManagerの修正

`startBacktest()` メソッドで：

```typescript
// 変更前
let pythonCmd = EnvironmentChecker.getPythonCommand()
const args = [scriptPath, '--config', ...]
this.currentProcess = execFile(pythonCmd, args, {...})

// 変更後
const enginePath = EnvironmentChecker.getBacktestEnginePath()
if (!enginePath) {
  throw new Error('バックテストエンジンが見つかりません')
}
const args = ['--config', strategyConfigPath, '--symbol', ...]
this.currentProcess = execFile(enginePath, args, {...})
```

### 3. BacktestConfigDialogの改善

`gui/src/components/Backtest/BacktestConfigDialog.tsx` で：

- `getInitialConfig()` 関数を追加
- `useEffect` でダイアログ表示時に設定を再初期化
- ログ出力を追加

### 4. BacktestPanelの改善

`gui/src/components/Backtest/BacktestPanel.tsx` で：

- 環境チェック中の表示を追加
- エラーメッセージの表示を改善
- デバッグ情報の表示を追加

### 5. electron-builder設定

`gui/electron-builder.config.js` を作成：

```javascript
module.exports = {
  appId: 'com.strategybricks.builder',
  productName: 'Strategy Bricks Builder',
  extraResources: [
    {
      from: '../python/dist',
      to: 'python',
      filter: ['backtest_engine.exe']
    }
  ],
  win: {
    target: ['nsis']
  }
}
```

`gui/package.json` にスクリプトを追加：

```json
{
  "scripts": {
    "build:python": "cd ../python && powershell -ExecutionPolicy Bypass -File build-exe.ps1",
    "build:win": "npm run build:python && npm run build && electron-builder --win"
  },
  "devDependencies": {
    "electron-builder": "^24.0.0"
  }
}
```

## テスト手順

### 開発モードテスト

1. Pythonスクリプトをexe化
   ```powershell
   cd python
   powershell -ExecutionPolicy Bypass -File build-exe.ps1
   ```

2. GUIアプリを起動
   ```powershell
   cd gui
   npm run dev
   ```

3. バックテスト機能をテスト

### パッケージ化テスト

1. アプリをビルド
   ```powershell
   cd gui
   npm run build:win
   ```

2. `gui/release` からアプリを起動してテスト

## トラブルシューティング

### exeが見つからない

- 開発モード: `python/dist/backtest_engine.exe` が存在することを確認
- 本番モード: `resources/python/backtest_engine.exe` が存在することを確認

### exeが動作しない

```powershell
cd python\dist
.\backtest_engine.exe --help
```

でexeが正常に動作することを確認

### ビルドエラー

- PyInstallerがインストールされていることを確認: `python -m pip show pyinstaller`
- 依存関係がインストールされていることを確認: `python -m pip install -r requirements.txt`

