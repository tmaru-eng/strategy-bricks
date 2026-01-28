/// <reference types="vite/client" />

import type { BacktestAPI } from './types/backtest'

declare global {
  interface Window {
    electron?: {
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
      dialog: {
        showOpenDialog: (options: unknown) => Promise<{ canceled: boolean; filePaths: string[] }>
        showSaveDialog: (options: unknown) => Promise<{ canceled: boolean; filePath?: string }>
      }
      fs: {
        readFile: (filePath: string) => Promise<string>
        writeFile: (filePath: string, content: string) => Promise<void>
      }
    }
    backtestAPI?: BacktestAPI
  }
}

export {}
