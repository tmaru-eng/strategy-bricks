# 設計書: バックテストPython環境修正

## 概要

この設計は、バックテスト機能のPython環境検出エラーとGUIのデフォルト設定表示の問題を修正します。

**アーキテクチャの変更:**
- **従来**: 埋め込みPython (python.exe) を同梱し、Electronから直接実行
- **新方式**: PyInstallerでPythonスクリプトを.exeにコンパイルし、Electronからexeを実行

**主な変更点:**

1. **Pythonスクリプトのexe化**: PyInstallerで`backtest_engine.py`を`backtest_engine.exe`にコンパイル
2. **Environment_Checkerの簡素化**: Python環境チェックを削除し、exeの存在確認のみ
3. **BacktestConfigDialogの改善**: デフォルト値の表示と永続化を確実にする
4. **BacktestPanelの初期化**: 環境チェック結果の適切な表示
5. **ビルドプロセスの統合**: electron-builderでexeを同梱

## アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────┐
│                    Electron Application                      │
│                                                              │
│  ┌────────────────────┐         ┌──────────────────────┐   │
│  │ Environment        │         │ Backtest Process     │   │
│  │ Checker            │────────▶│ Manager              │   │
│  │                    │         │                      │   │
│  │ - Check exe exists │         │ - Spawn exe          │   │
│  └────────────────────┘         └──────────────────────┘   │
│           │                              │                  │
│           │                              │                  │
│           ▼                              ▼                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Backtest Engine exe Resolution               │   │
│  │                                                      │   │
│  │  開発: python/dist/backtest_engine.exe              │   │
│  │  本番: resources/python/backtest_engine.exe         │   │
│  └─────────────────────────────────────────────────────┘   │
│           │                                                 │
└───────────┼─────────────────────────────────────────────────┘
            │
            ▼
   ┌─────────────────┐
   │ backtest_engine │
   │ .exe            │
   │                 │
   │ - MT5内蔵       │
   │ - numpy内蔵     │
   │ - 単一実行可能  │
   └─────────────────┘
```

## 修正が必要なコンポーネント

### 1. EnvironmentChecker (gui/electron/main.ts)

**問題点:**
- 埋め込みPythonのパス解決が複雑
- Python環境チェックが不要に複雑
- MT5ライブラリのチェックが時間がかかる

**修正内容:**

```typescript
class EnvironmentChecker {
  /**
   * バックテストエンジンexeのパスを取得
   * 
   * 開発モード: <project-root>/python/dist/backtest_engine.exe
   * 本番モード: <app-path>/resources/python/backtest_engine.exe
   */
  private static getBacktestEngineExePath(): string | null {
    const isDev = !app.isPackaged
    
    if (isDev) {
      // 開発時: python/dist/backtest_engine.exe
      const devPath = join(__dirname, '..', '..', '..', 'python', 'dist', 'backtest_engine.exe')
      console.log('[EnvironmentChecker] Checking dev path:', devPath)
      console.log('[EnvironmentChecker] Dev path exists:', existsSync(devPath))
      
      if (existsSync(devPath)) {
        console.log('[EnvironmentChecker] Found backtest engine (dev):', devPath)
        return devPath
      }
    } else {
      // 本番時: resources/python/backtest_engine.exe
      const prodPath = join(process.resourcesPath, 'python', 'backtest_engine.exe')
      console.log('[EnvironmentChecker] Checking prod path:', prodPath)
      console.log('[EnvironmentChecker] Prod path exists:', existsSync(prodPath))
      
      if (existsSync(prodPath)) {
        console.log('[EnvironmentChecker] Found backtest engine (prod):', prodPath)
        return prodPath
      }
    }
    
    console.log('[EnvironmentChecker] Backtest engine not found')
    console.log('[EnvironmentChecker] __dirname:', __dirname)
    console.log('[EnvironmentChecker] app.isPackaged:', app.isPackaged)
    console.log('[EnvironmentChecker] process.resourcesPath:', process.resourcesPath)
    
    return null
  }

  /**
   * 環境をチェックしてバックテスト機能の可用性を判定
   */
  static async checkEnvironment(): Promise<EnvironmentCheckResult> {
    // キャッシュがあれば返す
    if (this.cachedResult) {
      return this.cachedResult
    }

    // OS検出
    const platform = os.platform()
    const isWindows = platform === 'win32'

    // Windows以外の場合は即座に無効化
    if (!isWindows) {
      this.cachedResult = {
        isWindows: false,
        backtestEnabled: false,
        message: 'バックテスト機能はWindowsでのみ利用可能です。'
      }
      return this.cachedResult
    }

    // バックテストエンジンexeをチェック
    const enginePath = this.getBacktestEngineExePath()
    
    if (!enginePath) {
      const isDev = !app.isPackaged
      const expectedPath = isDev 
        ? 'python/dist/backtest_engine.exe'
        : 'resources/python/backtest_engine.exe'
      
      this.cachedResult = {
        isWindows: true,
        backtestEnabled: false,
        message: `バックテストエンジンが見つかりません。\n\n期待されるパス: ${expectedPath}\n\n開発モードの場合:\n1. python ディレクトリに移動\n2. build-exe.ps1 を実行してexeをビルド`,
        debug: {
          enginePath: null,
          engineExists: false,
          checkedPaths: [expectedPath]
        }
      }
      return this.cachedResult
    }

    // exeが見つかった場合、簡単なテストを実行
    const isValid = await this.testBacktestEngine(enginePath)
    
    if (!isValid) {
      this.cachedResult = {
        isWindows: true,
        backtestEnabled: false,
        message: `バックテストエンジンが正しく動作しません。\n\nパス: ${enginePath}\n\nexeファイルが破損している可能性があります。`,
        debug: {
          enginePath,
          engineExists: true,
          checkedPaths: [enginePath]
        }
      }
      return this.cachedResult
    }

    // すべてのチェックが通過
    this.backtestEnginePath = enginePath
    this.cachedResult = {
      isWindows: true,
      backtestEnabled: true,
      message: 'バックテスト機能が利用可能です。',
      debug: {
        enginePath,
        engineExists: true,
        checkedPaths: [enginePath]
      }
    }
    return this.cachedResult
  }

  /**
   * バックテストエンジンexeをテスト
   */
  private static async testBacktestEngine(enginePath: string): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        const testProcess = execFile(enginePath, ['--help'], {
          windowsHide: true,
          timeout: 5000
        }, (error, stdout) => {
          if (!error && (stdout.includes('usage') || stdout.includes('Backtest'))) {
            resolve(true)
          } else {
            resolve(false)
          }
        })
        
        testProcess.on('error', () => resolve(false))
      } catch (error) {
        resolve(false)
      }
    })
  }
  
  private static backtestEnginePath: string = ''
  
  static getBacktestEnginePath(): string {
    return this.backtestEnginePath
  }
}
```

**EnvironmentCheckResultインターフェースの更新:**

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

### 2. BacktestProcessManager (gui/electron/main.ts)

**修正内容:**

```typescript
class BacktestProcessManager {
  async startBacktest(
    config: BacktestConfig,
    strategyConfigPath: string
  ): Promise<string> {
    console.log('[BacktestProcessManager] Starting backtest')

    // 既存プロセスがあればキャンセル
    if (this.currentProcess) {
      await this.cancelBacktest()
    }

    // 結果ファイルパスを生成
    const timestamp = Date.now()
    const isDev = !app.isPackaged
    const projectRoot = isDev 
      ? join(__dirname, '../../..') 
      : join(process.resourcesPath, '..')
    
    const resultsPath = join(projectRoot, 'ea', 'tests', `results_${timestamp}.json`)

    // 一時ファイルを登録
    this.currentStrategyPath = strategyConfigPath
    this.currentResultsPath = resultsPath
    ErrorHandler.registerTempFile(strategyConfigPath)
    ErrorHandler.registerTempFile(resultsPath)

    // バックテストエンジンexeのパスを取得
    const enginePath = EnvironmentChecker.getBacktestEnginePath()
    
    if (!enginePath) {
      throw new Error('バックテストエンジンが見つかりません')
    }

    // コマンドライン引数を構築
    const args = [
      '--config', strategyConfigPath,
      '--symbol', config.symbol,
      '--timeframe', config.timeframe,
      '--start', config.startDate.toISOString(),
      '--end', config.endDate.toISOString(),
      '--output', resultsPath
    ]

    console.log('[BacktestProcessManager] Engine path:', enginePath)
    console.log('[BacktestProcessManager] Args:', args)

    try {
      // exeを実行
      this.currentProcess = execFile(enginePath, args, {
        windowsHide: true,
        maxBuffer: 10 * 1024 * 1024 // 10MB
      }) as ChildProcess

      console.log('[BacktestProcessManager] Process spawned with PID:', this.currentProcess.pid)

      // タイムアウトを設定
      this.timeoutHandle = setTimeout(() => {
        this.handleTimeout()
      }, this.TIMEOUT_MS)

      // 標準出力/エラー出力をキャプチャ
      let stdout = ''
      let stderr = ''

      this.currentProcess.stdout?.on('data', (data) => {
        const output = data.toString()
        stdout += output
        console.log('[Backtest stdout]', output)
      })

      this.currentProcess.stderr?.on('data', (data) => {
        const output = data.toString()
        stderr += output
        console.error('[Backtest stderr]', output)
      })

      // プロセス終了を待機
      return new Promise((resolve, reject) => {
        this.currentProcess!.on('exit', (code, signal) => {
          console.log('[BacktestProcessManager] Process exited', { code, signal })

          if (this.timeoutHandle) {
            clearTimeout(this.timeoutHandle)
            this.timeoutHandle = null
          }

          this.currentProcess = null

          if (code === 0) {
            console.log('[BacktestProcessManager] Process completed successfully')
            ErrorHandler.unregisterTempFile(resultsPath)
            resolve(resultsPath)
          } else {
            console.error('[BacktestProcessManager] Process failed', {
              code,
              signal,
              stderr: stderr.trim()
            })

            let errorMessage = `Backtest failed with code ${code}`
            
            if (stderr.trim()) {
              const errorLines = stderr.trim().split('\n')
              const lastError = errorLines[errorLines.length - 1]
              errorMessage += `: ${lastError}`
            }

            reject(new Error(errorMessage))
          }
        })

        this.currentProcess!.on('error', (err) => {
          console.error('[BacktestProcessManager] Process error:', err)

          if (this.timeoutHandle) {
            clearTimeout(this.timeoutHandle)
            this.timeoutHandle = null
          }

          this.currentProcess = null
          reject(err)
        })
      })
    } catch (error) {
      console.error('[BacktestProcessManager] Failed to spawn process:', error)
      throw error
    }
  }
}
```

**問題点:**
- デフォルト値が正しく初期化されていない可能性
- ローカルストレージからの読み込みが失敗している可能性

**修正内容:**

```typescript
/**
 * デフォルトのバックテスト設定を生成する
 * 
 * @returns デフォルト設定（USDJPY, M1, 過去3ヶ月）
 */
function getDefaultConfig(): BacktestConfig {
  const endDate = new Date()
  const startDate = new Date()
  startDate.setMonth(startDate.getMonth() - 3)
  
  console.log('[BacktestConfigDialog] Generated default config:', {
    symbol: 'USDJPY',
    timeframe: 'M1',
    startDate: startDate.toISOString(),
    endDate: endDate.toISOString()
  })
  
  return {
    symbol: 'USDJPY',
    timeframe: 'M1',
    startDate,
    endDate
  }
}

/**
 * ローカルストレージから設定を読み込む
 */
function loadConfigFromStorage(): BacktestConfig | null {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    console.log('[BacktestConfigDialog] Loading config from storage:', stored)
    
    if (!stored) {
      console.log('[BacktestConfigDialog] No stored config found')
      return null
    }
    
    const parsed = JSON.parse(stored)
    
    // Date オブジェクトに変換
    const config = {
      ...parsed,
      startDate: new Date(parsed.startDate),
      endDate: new Date(parsed.endDate)
    }
    
    console.log('[BacktestConfigDialog] Loaded config from storage:', config)
    return config
  } catch (error) {
    console.error('[BacktestConfigDialog] Failed to load config from storage:', error)
    return null
  }
}

export const BacktestConfigDialog: React.FC<BacktestConfigDialogProps> = ({
  isOpen,
  onClose,
  onSubmit,
  lastConfig
}) => {
  // 初期化ロジックを改善
  const getInitialConfig = (): BacktestConfig => {
    console.log('[BacktestConfigDialog] Initializing config')
    console.log('[BacktestConfigDialog] lastConfig:', lastConfig)
    
    if (lastConfig) {
      console.log('[BacktestConfigDialog] Using lastConfig')
      return lastConfig
    }
    
    const storedConfig = loadConfigFromStorage()
    if (storedConfig) {
      console.log('[BacktestConfigDialog] Using stored config')
      return storedConfig
    }
    
    console.log('[BacktestConfigDialog] Using default config')
    return getDefaultConfig()
  }
  
  const initialConfig = getInitialConfig()
  
  const [symbol, setSymbol] = useState(initialConfig.symbol)
  const [timeframe, setTimeframe] = useState(initialConfig.timeframe)
  const [startDate, setStartDate] = useState(
    initialConfig.startDate.toISOString().split('T')[0]
  )
  const [endDate, setEndDate] = useState(
    initialConfig.endDate.toISOString().split('T')[0]
  )
  const [errors, setErrors] = useState<string[]>([])
  
  // ダイアログが開かれるたびに初期化
  useEffect(() => {
    if (isOpen) {
      console.log('[BacktestConfigDialog] Dialog opened, reinitializing')
      const config = getInitialConfig()
      setSymbol(config.symbol)
      setTimeframe(config.timeframe)
      setStartDate(config.startDate.toISOString().split('T')[0])
      setEndDate(config.endDate.toISOString().split('T')[0])
      setErrors([])
    }
  }, [isOpen])
  
  // ... 残りのコード ...
}
```

### 5. electron-builder設定

**新規ファイル: gui/electron-builder.config.js**

```javascript
/**
 * electron-builder設定
 * バックテストエンジンexeを同梱してパッケージ化
 */
module.exports = {
  appId: 'com.strategybricks.builder',
  productName: 'Strategy Bricks Builder',
  directories: {
    output: 'release',
    buildResources: 'build'
  },
  files: [
    'dist/**/*',
    'dist-electron/**/*',
    'package.json'
  ],
  extraResources: [
    {
      // バックテストエンジンexeを同梱
      from: '../python/dist',
      to: 'python',
      filter: ['backtest_engine.exe']
    },
    {
      // EA設定ファイル用ディレクトリ
      from: '../ea/tests',
      to: 'ea/tests',
      filter: ['*.json', '*.md']
    }
  ],
  win: {
    target: [
      {
        target: 'nsis',
        arch: ['x64']
      }
    ],
    icon: 'build/icon.ico'
  },
  nsis: {
    oneClick: false,
    allowToChangeInstallationDirectory: true,
    createDesktopShortcut: true,
    createStartMenuShortcut: true
  }
}
```

**package.jsonにビルドスクリプトを追加:**

```json
{
  "scripts": {
    "build": "electron-vite build",
    "build:python": "cd ../python && powershell -ExecutionPolicy Bypass -File build-exe.ps1",
    "build:win": "npm run build:python && npm run build && electron-builder --win",
    "build:dir": "npm run build:python && npm run build && electron-builder --dir"
  },
  "devDependencies": {
    "electron-builder": "^24.0.0"
  }
}
```

**問題点:**
- 環境チェック結果が適切に表示されていない可能性
- エラーメッセージが不明確

**修正内容:**

```typescript
export const BacktestPanel: React.FC = () => {
  const [envCheck, setEnvCheck] = useState<EnvironmentCheckResult | null>(null)
  const [isCheckingEnv, setIsCheckingEnv] = useState(true)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isRunning, setIsRunning] = useState(false)
  const [results, setResults] = useState<BacktestResults | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [elapsedTime, setElapsedTime] = useState(0)

  // 環境チェックを実行
  useEffect(() => {
    const checkEnvironment = async () => {
      console.log('[BacktestPanel] Checking environment')
      setIsCheckingEnv(true)
      
      try {
        const result = await window.backtestAPI.checkEnvironment()
        console.log('[BacktestPanel] Environment check result:', result)
        setEnvCheck(result)
      } catch (error) {
        console.error('[BacktestPanel] Environment check failed:', error)
        setEnvCheck({
          isWindows: false,
          pythonAvailable: false,
          mt5Available: false,
          backtestEnabled: false,
          message: '環境チェック中にエラーが発生しました。'
        })
      } finally {
        setIsCheckingEnv(false)
      }
    }

    checkEnvironment()
  }, [])

  // 環境チェック中の表示
  if (isCheckingEnv) {
    return (
      <div className="p-4">
        <div className="flex items-center gap-2">
          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
          <span>環境をチェック中...</span>
        </div>
      </div>
    )
  }

  // 環境チェック失敗時の表示
  if (!envCheck || !envCheck.backtestEnabled) {
    return (
      <div className="p-4">
        <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
          <h3 className="font-semibold text-yellow-800 mb-2">
            バックテスト機能が利用できません
          </h3>
          <p className="text-sm text-yellow-700 whitespace-pre-line">
            {envCheck?.message || 'Python環境が見つかりません。'}
          </p>
          
          {/* デバッグ情報 */}
          <details className="mt-4">
            <summary className="text-xs text-yellow-600 cursor-pointer">
              詳細情報
            </summary>
            <pre className="text-xs mt-2 bg-yellow-100 p-2 rounded overflow-auto">
              {JSON.stringify(envCheck, null, 2)}
            </pre>
          </details>
        </div>
      </div>
    )
  }

  // ... 残りのコード ...
}
```

### 4. PyInstallerビルドスクリプト

**新規ファイル: python/build-exe.ps1**

```powershell
# PyInstallerでbacktest_engine.pyをexe化するスクリプト

$ErrorActionPreference = "Stop"

Write-Host "=== バックテストエンジンのexe化 ===" -ForegroundColor Cyan
Write-Host ""

# 1. PyInstallerのインストール確認
Write-Host "[1/4] PyInstallerの確認..." -ForegroundColor Yellow
try {
    python -m pip show pyinstaller | Out-Null
    Write-Host "  ✓ PyInstallerがインストールされています" -ForegroundColor Green
} catch {
    Write-Host "  PyInstallerをインストール中..." -ForegroundColor Gray
    python -m pip install pyinstaller
    Write-Host "  ✓ PyInstallerをインストールしました" -ForegroundColor Green
}
Write-Host ""

# 2. 依存関係のインストール確認
Write-Host "[2/4] 依存関係の確認..." -ForegroundColor Yellow
python -m pip install -r requirements.txt
Write-Host "  ✓ 依存関係を確認しました" -ForegroundColor Green
Write-Host ""

# 3. PyInstallerでexe化
Write-Host "[3/4] exeをビルド中..." -ForegroundColor Yellow
Write-Host "  これには数分かかる場合があります..." -ForegroundColor Gray

$pyinstallerArgs = @(
    "--onefile",                          # 単一exeファイル
    "--console",                          # コンソールアプリ
    "--name=backtest_engine",             # 出力ファイル名
    "--distpath=dist",                    # 出力ディレクトリ
    "--workpath=build",                   # 作業ディレクトリ
    "--specpath=.",                       # specファイルの場所
    "--clean",                            # クリーンビルド
    "--noconfirm",                        # 確認なし
    "backtest_engine.py"                  # ソースファイル
)

python -m PyInstaller @pyinstallerArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ exeのビルドに成功しました" -ForegroundColor Green
} else {
    Write-Host "  ✗ exeのビルドに失敗しました" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 4. 検証
Write-Host "[4/4] exeの検証..." -ForegroundColor Yellow
$exePath = "dist\backtest_engine.exe"

if (Test-Path $exePath) {
    Write-Host "  ✓ exeファイルが生成されました: $exePath" -ForegroundColor Green
    
    # ファイルサイズを表示
    $fileSize = (Get-Item $exePath).Length / 1MB
    Write-Host "  ファイルサイズ: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    
    # --helpオプションでテスト
    Write-Host "  exeをテスト中..." -ForegroundColor Gray
    & $exePath --help | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ exeが正常に動作します" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ exeのテストに失敗しました" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ exeファイルが見つかりません" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "=== ビルド完了 ===" -ForegroundColor Green
Write-Host ""
Write-Host "生成されたexe: $exePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Yellow
Write-Host "  1. GUIアプリを起動してバックテスト機能をテスト" -ForegroundColor Gray
Write-Host "  2. 本番ビルド時にelectron-builderがexeを同梱" -ForegroundColor Gray
Write-Host ""
```

**新規ファイル: python/backtest_engine.spec (PyInstaller設定)**

```python
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['backtest_engine.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        'MetaTrader5',
        'numpy',
        'numpy.core._methods',
        'numpy.lib.format',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='backtest_engine',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
```

## データモデル

### EnvironmentCheckResult

```typescript
interface EnvironmentCheckResult {
  isWindows: boolean
  pythonAvailable: boolean
  mt5Available: boolean
  backtestEnabled: boolean
  message?: string
  // 追加: デバッグ情報
  debug?: {
    embeddedPythonPath: string | null
    embeddedPythonExists: boolean
    systemPythonCommand: string | null
    checkedPaths: string[]
  }
}
```

### BacktestConfig

```typescript
interface BacktestConfig {
  symbol: string        // デフォルト: "USDJPY"
  timeframe: string     // デフォルト: "M1"
  startDate: Date       // デフォルト: 3ヶ月前
  endDate: Date         // デフォルト: 今日
}
```

## 正確性プロパティ

### プロパティ1: 埋め込みPython優先検出

*任意の*アプリケーション起動時に、埋め込みPythonが存在する場合、システムPythonより優先して検出される

**検証: 要件 1.4**

### プロパティ2: デフォルト設定の一貫性

*任意の*バックテスト設定ダイアログの表示時に、デフォルト設定（USDJPY, M1, 過去3ヶ月）が表示される

**検証: 要件 3.1, 3.3**

### プロパティ3: 設定の永続化

*任意の*バックテスト実行後に、設定がローカルストレージに保存され、次回起動時に復元される

**検証: 要件 4.1, 4.2**

### プロパティ4: エラーメッセージの明確性

*任意の*Python環境エラー時に、エラーメッセージにチェックしたパスと解決手順が含まれる

**検証: 要件 2.1, 2.3, 2.4**

### プロパティ5: 環境チェックの信頼性

*任意の*Python環境チェック時に、タイムアウト（5秒）内に結果が返される

**検証: 要件 5.1**

## テスト戦略

### 単体テスト

1. **EnvironmentChecker.getEmbeddedPythonPath()**
   - 開発モードでのパス解決
   - 本番モードでのパス解決
   - ファイルが存在しない場合の処理

2. **BacktestConfigDialog デフォルト値**
   - デフォルト設定の生成
   - ローカルストレージからの読み込み
   - フォールバック処理

3. **設定の永続化**
   - ローカルストレージへの保存
   - ローカルストレージからの読み込み
   - 無効な設定の処理

### 統合テスト

1. **環境チェックフロー**
   - 埋め込みPython検出 → バックテスト有効化
   - 埋め込みPython不在 → システムPython検出
   - すべてのPython不在 → エラーメッセージ表示

2. **バックテスト設定フロー**
   - ダイアログ表示 → デフォルト値表示
   - 設定変更 → バックテスト実行 → 設定保存
   - アプリ再起動 → 保存された設定の復元

### 手動テスト

1. **埋め込みPythonのセットアップ**
   - `setup-embedded-python.ps1` 実行
   - `verify-embedded-python.ps1` 実行
   - アプリ起動 → バックテスト機能有効確認

2. **デフォルト設定の確認**
   - アプリ起動 → バックテストパネル表示
   - 「バックテスト実行」クリック → デフォルト値確認
   - 設定変更 → 実行 → アプリ再起動 → 保存された設定確認

## 実装順序

1. **PyInstallerビルドスクリプト作成** (python/build-exe.ps1, python/backtest_engine.spec)
   - PyInstallerでbacktest_engine.pyをexe化するスクリプト
   - PyInstaller設定ファイル（.spec）
   - requirements.txtにpyinstallerを追加

2. **EnvironmentChecker修正** (gui/electron/main.ts)
   - `getBacktestEngineExePath()` メソッドの実装
   - Python環境チェックを削除し、exeの存在確認のみに簡素化
   - エラーメッセージの改善
   - デバッグ情報の追加

3. **BacktestProcessManager修正** (gui/electron/main.ts)
   - Pythonコマンドの代わりにexeを実行するように変更
   - `EnvironmentChecker.getBacktestEnginePath()` を使用

4. **BacktestConfigDialog改善** (gui/src/components/Backtest/BacktestConfigDialog.tsx)
   - デフォルト設定の初期化ロジック改善
   - ローカルストレージの読み書きロジック改善
   - ログ出力の追加

5. **BacktestPanel初期化** (gui/src/components/Backtest/BacktestPanel.tsx)
   - 環境チェック結果の表示改善
   - エラーメッセージの表示改善
   - デバッグ情報の表示

6. **electron-builder設定** (gui/electron-builder.config.js, gui/package.json)
   - electron-builder設定ファイルの作成
   - package.jsonにビルドスクリプトとdevDependenciesを追加
   - バックテストエンジンexeを同梱する設定

7. **テスト実行**
   - Pythonスクリプトのexe化テスト
   - 開発モードでのexe実行テスト
   - 単体テスト実行
   - 統合テスト実行
   - パッケージ化テスト実行

8. **ドキュメント更新**
   - README更新（exeビルド手順、アプリビルド手順、トラブルシューティング）
   - PYTHON_EMBEDDING.md更新（PyInstallerの使用方法）

