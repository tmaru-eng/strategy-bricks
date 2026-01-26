/// <reference types="vite/client" />

declare global {
  interface Window {
    electron: {
      ping: () => Promise<{ ok: boolean }>
      openCatalog: () => Promise<{ path: string; content: string } | null>
      env: {
        isE2E: boolean
        profileName: string
      }
      exportConfig: (payload: {
        profileName: string
        content: string
      }) => Promise<{ ok: boolean; path?: string }>
      saveStrategyConfig: (payload: {
        filename: string
        content: string
      }) => Promise<{ success: boolean; path?: string; error?: string }>
    }
    backtestAPI: {
      checkEnvironment: () => Promise<{
        isWindows: boolean
        pythonAvailable: boolean
        mt5Available: boolean
        backtestEnabled: boolean
        message?: string
      }>
      startBacktest: (
        config: {
          symbol: string
          timeframe: string
          startDate: Date | string
          endDate: Date | string
        },
        strategyPath: string
      ) => Promise<void>
      cancelBacktest: () => Promise<void>
      onBacktestProgress: (callback: (progress: any) => void) => void
      onBacktestComplete: (callback: (results: any) => void) => void
      onBacktestError: (callback: (error: string) => void) => void
      exportResults: (
        results: any,
        outputPath?: string
      ) => Promise<{ success: boolean; path?: string; canceled?: boolean }>
    }
  }
}

export {}
