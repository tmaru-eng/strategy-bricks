import { app, BrowserWindow, dialog, ipcMain } from 'electron'
import { mkdir, readFile, writeFile, unlink, readdir } from 'fs/promises'
import { basename, join } from 'path'
import { spawn, execFile, ChildProcess } from 'child_process'
import { existsSync } from 'fs'
import * as os from 'os'

/**
 * バックテスト設定インターフェース
 */
interface BacktestConfig {
  symbol: string
  timeframe: string
  startDate: Date
  endDate: Date
}

/**
 * 環境チェック結果インターフェース
 */
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

/**
 * エラーカテゴリ
 * 要件: 10.1, 10.2
 */
enum ErrorCategory {
  CONFIGURATION = 'configuration',
  ENVIRONMENT = 'environment',
  RUNTIME = 'runtime',
  PARSING = 'parsing'
}

/**
 * 環境チェッククラス
 * 
 * 要件: 9.1, 9.5
 * - 起動時のOS検出
 * - バックテストエンジンexeの可用性チェック
 */
class EnvironmentChecker {
  private static cachedResult: EnvironmentCheckResult | null = null
  private static backtestEnginePath: string = ''
  
  /**
   * バックテストエンジンexeのパスを取得
   * 
   * 開発モード: <project-root>/python/dist/backtest_engine.exe
   * 本番モード: <app-path>/resources/python/backtest_engine.exe
   * 
   * @returns バックテストエンジンexeのパス（存在しない場合はnull）
   */
  private static getBacktestEngineExePath(): string | null {
    const isDev = !app.isPackaged
    
    if (isDev) {
      // 開発時: python/dist/backtest_engine.exe
      // __dirname は gui/dist-electron なので、2つ上がプロジェクトルート
      const devPath = join(__dirname, '..', '..', 'python', 'dist', 'backtest_engine.exe')
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
   * 
   * 要件: 9.1, 9.5
   * @returns 環境チェック結果
   */
  static async checkEnvironment(): Promise<EnvironmentCheckResult> {
    // キャッシュがあれば返す
    if (this.cachedResult) {
      console.log('[EnvironmentChecker] Returning cached result:', this.cachedResult)
      return this.cachedResult
    }

    console.log('[EnvironmentChecker] Starting environment check')

    // OS検出 (要件: 9.1)
    const platform = os.platform()
    const isWindows = platform === 'win32'
    const isDev = !app.isPackaged
    
    console.log('[EnvironmentChecker] OS detected:', {
      platform,
      isWindows,
      arch: os.arch(),
      release: os.release()
    })

    // Windows以外の場合は即座に無効化 (要件: 9.3)
    if (!isWindows) {
      this.cachedResult = {
        isWindows: false,
        backtestEnabled: false,
        message: 'バックテスト機能はWindowsでのみ利用可能です。'
      }
      console.log('[EnvironmentChecker] Non-Windows platform detected, backtest disabled')
      return this.cachedResult
    }

    // バックテストエンジンexeをチェック
    const enginePath = this.getBacktestEngineExePath()
    
    if (!enginePath) {
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
      console.log('[EnvironmentChecker] Backtest engine not found, backtest disabled')
      return this.cachedResult
    }

    // exeが見つかった場合、簡単なテストを実行
    // 開発モードではテストをスキップ（MT5が必要なため）
    const isValid = isDev ? true : await this.testBacktestEngine(enginePath)
    
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
      console.log('[EnvironmentChecker] Backtest engine test failed, backtest disabled')
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
    console.log('[EnvironmentChecker] All checks passed, backtest enabled')
    return this.cachedResult
  }

  /**
   * バックテストエンジンexeをテスト
   * 
   * @param enginePath テストするexeのパス
   * @returns 有効な場合はtrue
   */
  private static async testBacktestEngine(enginePath: string): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        console.log('[EnvironmentChecker] Testing backtest engine:', enginePath)
        
        const testProcess = execFile(enginePath, ['--help'], {
          windowsHide: true,
          timeout: 5000
        }, (error, stdout) => {
          if (!error && (stdout.includes('usage') || stdout.includes('Backtest') || stdout.includes('backtest'))) {
            console.log('[EnvironmentChecker] Backtest engine test passed')
            resolve(true)
          } else {
            console.log('[EnvironmentChecker] Backtest engine test failed:', { 
              error: error?.message, 
              stdout: stdout.substring(0, 200) 
            })
            resolve(false)
          }
        })
        
        testProcess.on('error', (error) => {
          console.log('[EnvironmentChecker] Backtest engine spawn error:', error.message)
          resolve(false)
        })
      } catch (error) {
        console.log('[EnvironmentChecker] Backtest engine test exception:', error)
        resolve(false)
      }
    })
  }
  
  /**
   * バックテストエンジンexeのパスを取得
   */
  static getBacktestEnginePath(): string {
    return this.backtestEnginePath
  }

  /**
   * キャッシュをクリア（テスト用）
   */
  static clearCache(): void {
    this.cachedResult = null
    this.backtestEnginePath = ''
    console.log('[EnvironmentChecker] Cache cleared')
  }
}

/**
 * エラーハンドリングクラス
 * 
 * 要件: 10.1, 10.2, 10.3
 * - エラーの詳細なログ記録
 * - ユーザーフレンドリーなエラーメッセージの生成
 * - 一時ファイルのクリーンアップ
 */
class ErrorHandler {
  private static tempFiles: Set<string> = new Set()

  /**
   * 一時ファイルを登録
   */
  static registerTempFile(filePath: string): void {
    this.tempFiles.add(filePath)
    console.log(`[ErrorHandler] Registered temp file: ${filePath}`)
  }

  /**
   * 一時ファイルの登録を解除
   */
  static unregisterTempFile(filePath: string): void {
    this.tempFiles.delete(filePath)
    console.log(`[ErrorHandler] Unregistered temp file: ${filePath}`)
  }

  /**
   * バックテストエラーを処理
   * 
   * @param error エラーオブジェクト
   * @param context エラーが発生したコンテキスト
   * @returns ユーザーフレンドリーなエラーメッセージ
   */
  static handleBacktestError(error: Error, context: string): string {
    // 詳細なエラーをログに記録
    console.error(`[Backtest Error - ${context}]`, {
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString()
    })

    // エラーカテゴリを判定
    const category = this.categorizeError(error)
    console.log(`[ErrorHandler] Error category: ${category}`)

    // ユーザーフレンドリーなメッセージを生成
    const userMessage = this.generateUserMessage(error, category)

    // クリーンアップを実行
    this.cleanup().catch(cleanupError => {
      console.error('[ErrorHandler] Cleanup failed:', cleanupError)
    })

    return userMessage
  }

  /**
   * エラーをカテゴリに分類
   */
  private static categorizeError(error: Error): ErrorCategory {
    const message = error.message.toLowerCase()

    if (message.includes('mt5') || message.includes('metatrader')) {
      return ErrorCategory.RUNTIME
    } else if (message.includes('timeout')) {
      return ErrorCategory.RUNTIME
    } else if (message.includes('data') || message.includes('fetch')) {
      return ErrorCategory.RUNTIME
    } else if (message.includes('config') || message.includes('invalid')) {
      return ErrorCategory.CONFIGURATION
    } else if (message.includes('python') || message.includes('spawn')) {
      return ErrorCategory.ENVIRONMENT
    } else if (message.includes('json') || message.includes('parse')) {
      return ErrorCategory.PARSING
    } else {
      return ErrorCategory.RUNTIME
    }
  }

  /**
   * ユーザーフレンドリーなエラーメッセージを生成
   */
  private static generateUserMessage(error: Error, category: ErrorCategory): string {
    const message = error.message

    switch (category) {
      case ErrorCategory.CONFIGURATION:
        if (message.includes('symbol')) {
          return 'シンボルが無効です。有効な通貨ペア（例: USDJPY）を入力してください。'
        } else if (message.includes('date')) {
          return '日付範囲が無効です。開始日が終了日より前であることを確認してください。'
        } else if (message.includes('config')) {
          return 'ストラテジー設定が無効です。設定を確認してください。'
        }
        return `設定エラー: ${message}`

      case ErrorCategory.ENVIRONMENT:
        if (message.includes('python')) {
          return 'Python環境が見つかりません。Pythonがインストールされていることを確認してください。'
        } else if (message.includes('spawn')) {
          return 'バックテストプロセスの起動に失敗しました。システム環境を確認してください。'
        }
        return `環境エラー: ${message}`

      case ErrorCategory.RUNTIME:
        if (message.includes('mt5') || message.includes('metatrader')) {
          return 'MetaTrader5への接続に失敗しました。MT5ターミナルが起動していることを確認してください。'
        } else if (message.includes('timeout')) {
          return 'バックテストがタイムアウトしました。日付範囲を短くするか、後でもう一度お試しください。'
        } else if (message.includes('data') || message.includes('fetch')) {
          return '過去データの取得に失敗しました。シンボルと日付範囲を確認してください。'
        } else if (message.includes('connection')) {
          return 'ネットワーク接続エラーが発生しました。接続を確認してください。'
        }
        return `実行時エラー: ${message}`

      case ErrorCategory.PARSING:
        if (message.includes('json')) {
          return 'ファイルの解析に失敗しました。ファイル形式が正しいことを確認してください。'
        }
        return `解析エラー: ${message}`

      default:
        return `予期しないエラーが発生しました: ${message}`
    }
  }

  /**
   * 一時ファイルをクリーンアップ
   * 
   * 要件: 10.3
   */
  static async cleanup(): Promise<void> {
    console.log(`[ErrorHandler] Starting cleanup of ${this.tempFiles.size} temp files`)

    const cleanupPromises: Promise<void>[] = []

    for (const filePath of this.tempFiles) {
      cleanupPromises.push(
        this.deleteTempFile(filePath)
      )
    }

    await Promise.allSettled(cleanupPromises)

    this.tempFiles.clear()
    console.log('[ErrorHandler] Cleanup completed')
  }

  /**
   * 一時ファイルを削除
   */
  private static async deleteTempFile(filePath: string): Promise<void> {
    try {
      if (existsSync(filePath)) {
        await unlink(filePath)
        console.log(`[ErrorHandler] Deleted temp file: ${filePath}`)
      } else {
        console.log(`[ErrorHandler] Temp file not found (already deleted?): ${filePath}`)
      }
    } catch (error) {
      console.error(`[ErrorHandler] Failed to delete temp file ${filePath}:`, error)
    }
  }

  /**
   * 古い一時ファイルをクリーンアップ
   * 
   * @param directory クリーンアップするディレクトリ
   * @param maxAgeMs 最大経過時間（ミリ秒）
   */
  static async cleanupOldTempFiles(directory: string, maxAgeMs: number = 24 * 60 * 60 * 1000): Promise<void> {
    try {
      if (!existsSync(directory)) {
        return
      }

      const files = await readdir(directory, { withFileTypes: true })
      const now = Date.now()

      for (const file of files) {
        if (file.isFile() && (file.name.startsWith('strategy_') || file.name.startsWith('results_'))) {
          const filePath = join(directory, file.name)
          
          try {
            // ファイル名からタイムスタンプを抽出
            const match = file.name.match(/_(\\d+)\\.json$/)
            if (match) {
              const timestamp = parseInt(match[1], 10)
              const age = now - timestamp

              if (age > maxAgeMs) {
                await unlink(filePath)
                console.log(`[ErrorHandler] Deleted old temp file: ${filePath} (age: ${Math.round(age / 1000 / 60)} minutes)`)
              }
            }
          } catch (error) {
            console.error(`[ErrorHandler] Failed to process file ${filePath}:`, error)
          }
        }
      }
    } catch (error) {
      console.error(`[ErrorHandler] Failed to cleanup old temp files in ${directory}:`, error)
    }
  }
}

/**
 * Pythonバックテストプロセスを管理するクラス
 * 
 * 要件: 3.1, 3.2, 3.4, 10.1, 10.2, 10.3
 * - Pythonプロセスの起動
 * - コマンドライン引数の構築
 * - 標準出力/エラー出力のキャプチャ
 * - エラーハンドリングとロギング
 * - 一時ファイルのクリーンアップ
 */
class BacktestProcessManager {
  private currentProcess: ChildProcess | null = null
  private readonly TIMEOUT_MS = 5 * 60 * 1000 // 5分
  private timeoutHandle: NodeJS.Timeout | null = null
  private currentStrategyPath: string | null = null
  private currentResultsPath: string | null = null

  /**
   * バックテストを開始
   * 
   * @param config バックテスト設定
   * @param strategyConfigPath ストラテジー設定ファイルのパス
   * @returns 結果ファイルのパス
   */
  async startBacktest(
    config: BacktestConfig,
    strategyConfigPath: string
  ): Promise<string> {
    console.log('[BacktestProcessManager] Starting backtest', {
      config,
      strategyConfigPath,
      timestamp: new Date().toISOString()
    })

    // 既存プロセスがあればキャンセル
    if (this.currentProcess) {
      console.log('[BacktestProcessManager] Cancelling existing process')
      await this.cancelBacktest()
    }

    // 結果ファイルパスを生成
    const timestamp = Date.now()
    const isDev = !app.isPackaged
    const projectRoot = isDev 
      ? join(__dirname, '../../..') 
      : join(process.resourcesPath, '..')
    
    const resultsPath = join(
      projectRoot,
      'ea',
      'tests',
      `results_${timestamp}.json`
    )

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
            // 成功時は結果ファイルの登録を解除（削除しない）
            ErrorHandler.unregisterTempFile(resultsPath)
            resolve(resultsPath)
          } else {
            console.error('[BacktestProcessManager] Process failed', {
              code,
              signal,
              stderr: stderr.trim()
            })

            // 失敗時のエラーメッセージを構築
            let errorMessage = `Backtest failed with code ${code}`
            
            if (stderr.trim()) {
              // stderrから有用なエラー情報を抽出
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

  /**
   * 実行中のバックテストをキャンセル
   * 
   * 要件: 8.3, 10.3
   */
  async cancelBacktest(): Promise<void> {
    console.log('[BacktestProcessManager] Cancelling backtest')

    if (this.currentProcess) {
      console.log('[BacktestProcessManager] Killing process with PID:', this.currentProcess.pid)
      this.currentProcess.kill('SIGTERM')
      this.currentProcess = null
    }

    if (this.timeoutHandle) {
      clearTimeout(this.timeoutHandle)
      this.timeoutHandle = null
    }

    // 一時ファイルをクリーンアップ
    await ErrorHandler.cleanup()

    this.currentStrategyPath = null
    this.currentResultsPath = null

    console.log('[BacktestProcessManager] Cancellation completed')
  }

  /**
   * タイムアウト処理
   * 
   * 要件: 3.5
   */
  private handleTimeout(): void {
    console.error('[BacktestProcessManager] Timeout exceeded (5 minutes)')
    this.cancelBacktest().catch(error => {
      console.error('[BacktestProcessManager] Error during timeout cancellation:', error)
    })
  }
}

const sanitizeProfileName = (name: string): string => {
  const base = basename(name)
  const sanitized = base.replace(/[^a-zA-Z0-9._-]/g, '_')
  return sanitized.length > 0 ? sanitized : 'active'
}

const createWindow = () => {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 960,
    minHeight: 600,
    backgroundColor: '#f4f3f0',
    webPreferences: {
      preload: join(__dirname, 'preload.js')
    }
  })

  if (process.env.ELECTRON_RENDERER_URL) {
    win.loadURL(process.env.ELECTRON_RENDERER_URL)
  } else {
    win.loadFile(join(__dirname, '../dist/index.html'))
  }
}

// Initialize BacktestProcessManager
const backtestManager = new BacktestProcessManager()

app.whenReady().then(async () => {
  createWindow()

  // Check environment on startup (要件: 9.1, 9.5)
  console.log('[Main] Checking environment on startup')
  const envCheck = await EnvironmentChecker.checkEnvironment()
  console.log('[Main] Environment check result:', envCheck)

  // Cleanup old temporary files on startup
  // 要件: 10.3
  const isDev = !app.isPackaged
  const projectRoot = isDev 
    ? join(__dirname, '../../..') 
    : join(process.resourcesPath, '..')
  const testsDir = join(projectRoot, 'ea', 'tests')
  
  ErrorHandler.cleanupOldTempFiles(testsDir, 24 * 60 * 60 * 1000).catch(error => {
    console.error('[Main] Failed to cleanup old temp files:', error)
  })

  ipcMain.handle('app:ping', () => ({ ok: true }))
  
  // Generic dialog handlers
  ipcMain.handle('dialog:showOpen', async (_event, options) => {
    try {
      const result = await dialog.showOpenDialog(options)
      return result
    } catch (error) {
      console.error('[Main] Error showing open dialog:', error)
      throw error
    }
  })
  
  ipcMain.handle('dialog:showSave', async (_event, options) => {
    try {
      const result = await dialog.showSaveDialog(options)
      return result
    } catch (error) {
      console.error('[Main] Error showing save dialog:', error)
      throw error
    }
  })
  
  // Generic file system handlers
  ipcMain.handle('fs:readFile', async (_event, filePath) => {
    try {
      const content = await readFile(filePath, 'utf-8')
      return content
    } catch (error) {
      console.error('[Main] Error reading file:', error)
      throw error
    }
  })
  
  ipcMain.handle('fs:writeFile', async (_event, filePath, content) => {
    try {
      await writeFile(filePath, content, 'utf-8')
      return { success: true }
    } catch (error) {
      console.error('[Main] Error writing file:', error)
      throw error
    }
  })
  
  // Environment check IPC handler
  // Validates: Requirements 9.1, 9.5
  ipcMain.handle('backtest:checkEnvironment', async () => {
    try {
      console.log('[Main] Environment check requested')
      const result = await EnvironmentChecker.checkEnvironment()
      console.log('[Main] Environment check result:', result)
      return result
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error))
      console.error('[Main] Environment check error:', err)
      
      // Return a safe default result on error
      return {
        isWindows: false,
        pythonAvailable: false,
        mt5Available: false,
        backtestEnabled: false,
        message: `環境チェック中にエラーが発生しました: ${err.message}`
      }
    }
  })
  
  ipcMain.handle('catalog:open', async () => {
    try {
      const result = await dialog.showOpenDialog({
        title: 'Open block_catalog.json',
        properties: ['openFile'],
        filters: [{ name: 'JSON', extensions: ['json'] }]
      })

      if (result.canceled || result.filePaths.length === 0) {
        return null
      }

      const filePath = result.filePaths[0]
      const content = await readFile(filePath, 'utf-8')
      return { path: filePath, content }
    } catch (error) {
      throw new Error(error instanceof Error ? error.message : String(error))
    }
  })
  
  // Backtest IPC handlers
  // Validates: Requirements 3.1, 3.2, 3.4, 3.5, 8.3, 10.1, 10.2, 10.3
  ipcMain.handle('backtest:start', async (event, config, strategyPath) => {
    try {
      console.log('[Main] Starting backtest:', { config, strategyPath })
      
      // Convert date strings to Date objects if needed
      const backtestConfig = {
        ...config,
        startDate: typeof config.startDate === 'string' ? new Date(config.startDate) : config.startDate,
        endDate: typeof config.endDate === 'string' ? new Date(config.endDate) : config.endDate
      }
      
      const resultsPath = await backtestManager.startBacktest(backtestConfig, strategyPath)
      
      // Read results file
      const resultsJson = await readFile(resultsPath, 'utf-8')
      const results = JSON.parse(resultsJson)
      
      // Send results to renderer
      event.sender.send('backtest:complete', results)
      
      console.log('[Main] Backtest completed successfully')
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error))
      console.error('[Main] Backtest error:', err)
      
      // Use ErrorHandler to generate user-friendly message
      const userMessage = ErrorHandler.handleBacktestError(err, 'backtest:start')
      
      // Send error to renderer
      event.sender.send('backtest:error', userMessage)
    }
  })
  
  ipcMain.handle('backtest:cancel', async () => {
    try {
      console.log('[Main] Cancelling backtest')
      await backtestManager.cancelBacktest()
      console.log('[Main] Backtest cancelled successfully')
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error))
      console.error('[Main] Error cancelling backtest:', err)
      
      // Use ErrorHandler for cancellation errors
      const userMessage = ErrorHandler.handleBacktestError(err, 'backtest:cancel')
      throw new Error(userMessage)
    }
  })
  
  ipcMain.handle('backtest:export', async (_event, results, outputPath) => {
    try {
      // If no output path is provided, show save dialog
      let finalOutputPath = outputPath
      
      if (!finalOutputPath) {
        const result = await dialog.showSaveDialog({
          title: 'バックテスト結果をエクスポート',
          defaultPath: `backtest_results_${Date.now()}.json`,
          filters: [
            { name: 'JSON Files', extensions: ['json'] },
            { name: 'All Files', extensions: ['*'] }
          ]
        })
        
        if (result.canceled || !result.filePath) {
          console.log('[Main] Export canceled by user')
          return { success: false, canceled: true }
        }
        
        finalOutputPath = result.filePath
      }
      
      console.log('[Main] Exporting backtest results to:', finalOutputPath)
      await writeFile(finalOutputPath, JSON.stringify(results, null, 2), 'utf-8')
      console.log('[Main] Results exported successfully')
      
      return { success: true, path: finalOutputPath }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error))
      console.error('[Main] Error exporting results:', err)
      
      // Use ErrorHandler for export errors
      const userMessage = ErrorHandler.handleBacktestError(err, 'backtest:export')
      throw new Error(userMessage)
    }
  })
  ipcMain.handle('config:export', async (_event, payload) => {
    try {
      const isE2E = process.env.E2E === '1'
      let outputDir = process.env.E2E_EXPORT_DIR

      if (!outputDir) {
        if (isE2E) {
          throw new Error('E2E export directory is not set')
        }

        const result = await dialog.showOpenDialog({
          title: 'Select output directory',
          properties: ['openDirectory', 'createDirectory']
        })

        if (result.canceled || result.filePaths.length === 0) {
          return { ok: false }
        }

        outputDir = result.filePaths[0]
      }

      const profilesDir = join(outputDir, 'profiles')
      const profileName = sanitizeProfileName(payload?.profileName || 'active')
      const content = payload?.content || '{}'

      await mkdir(profilesDir, { recursive: true })
      await writeFile(join(profilesDir, `${profileName}.json`), content, 'utf-8')
      await writeFile(join(outputDir, 'active.json'), content, 'utf-8')

      return { ok: true, path: outputDir }
    } catch (error) {
      throw new Error(error instanceof Error ? error.message : String(error))
    }
  })

  ipcMain.handle('strategy:save', async (_event, payload) => {
    try {
      const filename = payload?.filename || `strategy_${Date.now()}.json`
      const content = payload?.content || '{}'

      // ea/tests/ ディレクトリのパスを取得
      // 開発時: プロジェクトルート/ea/tests/
      // 本番時: app.asar の外側のプロジェクトルート/ea/tests/
      const isDev = !app.isPackaged
      const projectRoot = isDev 
        ? join(__dirname, '../../..') 
        : join(process.resourcesPath, '..')
      
      const testsDir = join(projectRoot, 'ea', 'tests')
      const filePath = join(testsDir, filename)

      // ディレクトリが存在しない場合は作成
      await mkdir(testsDir, { recursive: true })

      // ファイルを保存
      await writeFile(filePath, content, 'utf-8')

      console.log(`[Main] Strategy config saved: ${filePath}`)

      return { success: true, path: filePath }
    } catch (error) {
      console.error('[Main] Failed to save strategy config:', error)
      return { 
        success: false, 
        error: error instanceof Error ? error.message : String(error) 
      }
    }
  })

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})
