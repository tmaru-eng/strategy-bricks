import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electron', {
  ping: async () => ipcRenderer.invoke('app:ping'),
  openCatalog: async () => ipcRenderer.invoke('catalog:open'),
  env: {
    isE2E: process.env.E2E === '1',
    profileName: process.env.E2E_PROFILE_NAME || 'e2e-profile'
  },
  exportConfig: async (payload: { profileName: string; content: string }) =>
    ipcRenderer.invoke('config:export', payload),
  saveStrategyConfig: async (payload: { filename: string; content: string }) =>
    ipcRenderer.invoke('strategy:save', payload),
  dialog: {
    showOpenDialog: async (options: any) => ipcRenderer.invoke('dialog:showOpen', options),
    showSaveDialog: async (options: any) => ipcRenderer.invoke('dialog:showSave', options)
  },
  fs: {
    readFile: async (filePath: string) => ipcRenderer.invoke('fs:readFile', filePath),
    writeFile: async (filePath: string, content: string) => ipcRenderer.invoke('fs:writeFile', filePath, content)
  }
})

// BacktestAPI - IPC context bridge for backtest functionality
// Validates: Requirements 3.1, 9.1, 9.5
contextBridge.exposeInMainWorld('backtestAPI', {
  /**
   * Check the environment for backtest availability
   * Validates: Requirements 9.1, 9.5
   * @returns Environment check result with OS, Python, and MT5 availability
   */
  checkEnvironment: () =>
    ipcRenderer.invoke('backtest:checkEnvironment'),

  /**
   * Start a backtest with the given configuration and strategy file
   * @param config Backtest configuration (symbol, timeframe, date range)
   * @param strategyPath Path to the strategy configuration JSON file
   */
  startBacktest: (config: any, strategyPath: string) =>
    ipcRenderer.invoke('backtest:start', config, strategyPath),

  /**
   * Cancel the currently running backtest
   */
  cancelBacktest: () =>
    ipcRenderer.invoke('backtest:cancel'),

  /**
   * Register a listener for backtest progress updates
   * @param callback Function to call when progress is updated
   */
  onBacktestProgress: (callback: (progress: any) => void) => {
    ipcRenderer.on('backtest:progress', (_event, progress) => callback(progress))
  },

  /**
   * Register a listener for backtest completion
   * @param callback Function to call when backtest completes successfully
   */
  onBacktestComplete: (callback: (results: any) => void) => {
    ipcRenderer.on('backtest:complete', (_event, results) => callback(results))
  },

  /**
   * Register a listener for backtest errors
   * @param callback Function to call when an error occurs
   */
  onBacktestError: (callback: (error: string | { message: string; code?: string; details?: string }) => void) => {
    ipcRenderer.on('backtest:error', (_event, error) => callback(error))
  },

  /**
   * Export backtest results to a file
   * @param results Backtest results object
   * @param outputPath Path where the results should be saved (optional - shows save dialog if not provided)
   * @returns Export result with success status and file path
   */
  exportResults: (results: any, outputPath?: string) =>
    ipcRenderer.invoke('backtest:export', results, outputPath)
})
