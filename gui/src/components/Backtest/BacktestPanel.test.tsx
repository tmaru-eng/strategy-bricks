import React from 'react'
import { render, screen, waitFor, fireEvent, cleanup } from '@testing-library/react'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { BacktestPanel } from './BacktestPanel'
import type { BacktestResults } from '../../types/backtest'

/**
 * BacktestPanel コンポーネントのテスト
 * 
 * プラットフォーム固有のUI状態を検証します。
 * 
 * 要件: 9.2, 9.3, 9.4
 */

// モックのBacktest API
interface MockBacktestAPI {
  checkEnvironment: ReturnType<typeof vi.fn>
  startBacktest: ReturnType<typeof vi.fn>
  cancelBacktest: ReturnType<typeof vi.fn>
  onBacktestComplete: ReturnType<typeof vi.fn>
  onBacktestError: ReturnType<typeof vi.fn>
  exportResults: ReturnType<typeof vi.fn>
}

let mockBacktestAPI: MockBacktestAPI

// window.backtestAPI をモック
beforeEach(() => {
  mockBacktestAPI = {
    checkEnvironment: vi.fn(),
    startBacktest: vi.fn(),
    cancelBacktest: vi.fn(),
    onBacktestComplete: vi.fn(),
    onBacktestError: vi.fn(),
    exportResults: vi.fn()
  }
  
  // @ts-ignore
  window.backtestAPI = mockBacktestAPI
})

afterEach(() => {
  cleanup()
  // @ts-ignore
  delete window.backtestAPI
  vi.clearAllMocks()
})

describe('BacktestPanel - Environment Check', () => {
  /**
   * 要件 9.2: Windows + MT5利用可能 → バックテスト機能を有効化
   */
  it('should enable backtest features when Windows and MT5 are available', async () => {
    // Windows + MT5 利用可能な環境をモック
    mockBacktestAPI.checkEnvironment.mockResolvedValue({
      isWindows: true,
      pythonAvailable: true,
      mt5Available: true,
      backtestEnabled: true,
      message: 'バックテスト機能が利用可能です。'
    })
    
    render(<BacktestPanel />)
    
    // 環境チェック中の表示を確認
    expect(screen.getByText('環境をチェック中...')).toBeInTheDocument()
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(mockBacktestAPI.checkEnvironment).toHaveBeenCalled()
    })
    
    // バックテスト機能が有効化されていることを確認
    await waitFor(() => {
      expect(screen.getByText('バックテスト機能')).toBeInTheDocument()
      expect(screen.getByText('バックテスト実行')).toBeInTheDocument()
      expect(screen.getByText('バックテスト機能が利用可能です')).toBeInTheDocument()
    })
    
    // バックテスト実行ボタンが有効であることを確認
    const runButton = screen.getByText('バックテスト実行')
    expect(runButton).not.toBeDisabled()
  })
  
  /**
   * 要件 9.3: 非Windows → 機能を無効化し、プラットフォームメッセージを表示
   */
  it('should disable backtest and show platform message on non-Windows', async () => {
    // 非Windows環境をモック
    mockBacktestAPI.checkEnvironment.mockResolvedValue({
      isWindows: false,
      pythonAvailable: false,
      mt5Available: false,
      backtestEnabled: false,
      message: 'バックテスト機能はWindowsでのみ利用可能です。\nMetaTrader5はWindows専用のプラットフォームです。'
    })
    
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(mockBacktestAPI.checkEnvironment).toHaveBeenCalled()
    })
    
    // プラットフォーム制限メッセージが表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('プラットフォーム制限')).toBeInTheDocument()
      expect(screen.getByText(/バックテスト機能はWindowsでのみ利用可能です/)).toBeInTheDocument()
    })
    
    // バックテスト実行ボタンが表示されないことを確認
    expect(screen.queryByText('バックテスト実行')).not.toBeInTheDocument()
    
    // 環境詳細が表示されることを確認
    expect(screen.getByText('✗ Windows以外')).toBeInTheDocument()
    expect(screen.getByText('✗ 利用不可')).toBeInTheDocument()
  })
  
  /**
   * 要件 9.4: MT5未インストール → インストール手順を表示
   */
  it('should show installation instructions when MT5 is not installed', async () => {
    // Windows だが MT5 未インストールの環境をモック
    mockBacktestAPI.checkEnvironment.mockResolvedValue({
      isWindows: true,
      pythonAvailable: true,
      mt5Available: false,
      backtestEnabled: false,
      message: 'MetaTrader5 Pythonライブラリがインストールされていません。\n\nインストール手順:\n1. コマンドプロンプトを開く\n2. 次のコマンドを実行: pip install MetaTrader5\n3. アプリケーションを再起動'
    })
    
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(mockBacktestAPI.checkEnvironment).toHaveBeenCalled()
    })
    
    // インストール手順が表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('セットアップが必要です')).toBeInTheDocument()
      expect(screen.getByText(/MetaTrader5 Pythonライブラリがインストールされていません/)).toBeInTheDocument()
      expect(screen.getByText(/pip install MetaTrader5/)).toBeInTheDocument()
    })
    
    // バックテスト実行ボタンが表示されないことを確認
    expect(screen.queryByText('バックテスト実行')).not.toBeInTheDocument()
    
    // 環境詳細が表示されることを確認
    expect(screen.getByText('✓ Windows')).toBeInTheDocument()
    expect(screen.getByText('✓ 利用可能')).toBeInTheDocument()
    expect(screen.getByText('✗ 未インストール')).toBeInTheDocument()
  })
  
  it('should show environment details for all check results', async () => {
    // Windows + Python OK だが MT5 NG の環境をモック
    mockBacktestAPI.checkEnvironment.mockResolvedValue({
      isWindows: true,
      pythonAvailable: true,
      mt5Available: false,
      backtestEnabled: false,
      message: 'MT5ライブラリが必要です。'
    })
    
    render(<BacktestPanel />)
    
    await waitFor(() => {
      expect(mockBacktestAPI.checkEnvironment).toHaveBeenCalled()
    })
    
    // 環境詳細が正しく表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('OS:')).toBeInTheDocument()
      expect(screen.getByText('✓ Windows')).toBeInTheDocument()
      
      expect(screen.getByText('Python:')).toBeInTheDocument()
      expect(screen.getByText('✓ 利用可能')).toBeInTheDocument()
      
      expect(screen.getByText('MT5ライブラリ:')).toBeInTheDocument()
      expect(screen.getByText('✗ 未インストール')).toBeInTheDocument()
    })
  })
  
  it('should handle environment check failure gracefully', async () => {
    // 環境チェック失敗をモック
    mockBacktestAPI.checkEnvironment.mockRejectedValue(new Error('Check failed'))
    
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(mockBacktestAPI.checkEnvironment).toHaveBeenCalled()
    })
    
    // エラーメッセージが表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('環境チェックに失敗しました。')).toBeInTheDocument()
    })
  })
  
  it('should handle missing backtestAPI gracefully', async () => {
    // backtestAPI を削除
    // @ts-ignore
    delete window.backtestAPI
    
    render(<BacktestPanel />)
    
    // エラーメッセージが表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('Backtest APIが利用できません。')).toBeInTheDocument()
    })
  })
})

describe('BacktestPanel - Backtest Execution', () => {
  beforeEach(async () => {
    // バックテスト機能が有効な環境をモック
    mockBacktestAPI.checkEnvironment.mockResolvedValue({
      isWindows: true,
      pythonAvailable: true,
      mt5Available: true,
      backtestEnabled: true,
      message: 'バックテスト機能が利用可能です。'
    })
  })
  
  it('should open config dialog when run button is clicked', async () => {
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(screen.getByText('バックテスト実行')).toBeInTheDocument()
    })
    
    // バックテスト実行ボタンをクリック
    const runButton = screen.getByText('バックテスト実行')
    fireEvent.click(runButton)
    
    // 設定ダイアログが開くことを確認
    await waitFor(() => {
      expect(screen.getByText('バックテスト設定')).toBeInTheDocument()
    })
  })
  
  it('should disable run button while backtest is running', async () => {
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(screen.getByText('バックテスト実行')).toBeInTheDocument()
    })
    
    // バックテスト実行ボタンをクリック
    const runButton = screen.getByText('バックテスト実行')
    fireEvent.click(runButton)
    
    // 設定ダイアログで実行
    await waitFor(() => {
      expect(screen.getByText('バックテスト設定')).toBeInTheDocument()
    })
    
    // 設定を送信（実行ボタンをクリック）
    const submitButton = screen.getByRole('button', { name: '実行' })
    fireEvent.click(submitButton)
    
    // バックテスト実行中はボタンが無効化されることを確認
    await waitFor(() => {
      const disabledButton = screen.getByText('バックテスト実行')
      expect(disabledButton).toBeDisabled()
    })
  })
  
  it('should display results when backtest completes', async () => {
    const mockResults: BacktestResults = {
      metadata: {
        strategyName: 'Test Strategy',
        symbol: 'USDJPY',
        timeframe: 'M1',
        startDate: '2024-01-01T00:00:00Z',
        endDate: '2024-03-31T23:59:59Z',
        executionTimestamp: '2024-04-01T10:00:00Z'
      },
      summary: {
        totalTrades: 100,
        winningTrades: 60,
        losingTrades: 40,
        winRate: 60.0,
        totalProfitLoss: 125.50,
        maxDrawdown: 45.20,
        avgTradeProfitLoss: 1.255
      },
      trades: []
    }
    
    // onBacktestComplete コールバックをキャプチャ
    let completeCallback: ((results: BacktestResults) => void) | null = null
    mockBacktestAPI.onBacktestComplete.mockImplementation((callback) => {
      completeCallback = callback
    })
    
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(screen.getByText('バックテスト実行')).toBeInTheDocument()
    })
    
    // コールバックが登録されたことを確認
    expect(completeCallback).not.toBeNull()
    
    // バックテスト完了をシミュレート
    if (completeCallback) {
      completeCallback(mockResults)
    }
    
    // 結果が表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('バックテスト結果')).toBeInTheDocument()
      expect(screen.getByText('Test Strategy')).toBeInTheDocument()
      expect(screen.getByText('60.00%')).toBeInTheDocument()
    })
  })
  
  it('should display error when backtest fails', async () => {
    const mockError = {
      message: 'MT5接続に失敗しました。'
    }
    
    // onBacktestError コールバックをキャプチャ
    let errorCallback: ((error: { message: string }) => void) | null = null
    mockBacktestAPI.onBacktestError.mockImplementation((callback) => {
      errorCallback = callback
    })
    
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(screen.getByText('バックテスト実行')).toBeInTheDocument()
    })
    
    // コールバックが登録されたことを確認
    expect(errorCallback).not.toBeNull()
    
    // バックテストエラーをシミュレート
    if (errorCallback) {
      errorCallback(mockError)
    }
    
    // エラーが表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('バックテストエラー')).toBeInTheDocument()
      expect(screen.getByText('MT5接続に失敗しました。')).toBeInTheDocument()
    })
  })
})

describe('BacktestPanel - Re-check Environment', () => {
  it('should provide re-check button when backtest is disabled', async () => {
    // MT5 未インストールの環境をモック
    mockBacktestAPI.checkEnvironment.mockResolvedValue({
      isWindows: true,
      pythonAvailable: true,
      mt5Available: false,
      backtestEnabled: false,
      message: 'MT5ライブラリが必要です。'
    })
    
    // window.location.reload をモック
    const reloadMock = vi.fn()
    Object.defineProperty(window, 'location', {
      value: { reload: reloadMock },
      writable: true
    })
    
    render(<BacktestPanel />)
    
    // 環境チェック完了を待機
    await waitFor(() => {
      expect(screen.getByText('セットアップが必要です')).toBeInTheDocument()
    })
    
    // 再チェックボタンが表示されることを確認
    const recheckButton = screen.getByText('環境を再チェック')
    expect(recheckButton).toBeInTheDocument()
    
    // 再チェックボタンをクリック
    fireEvent.click(recheckButton)
    
    // ページがリロードされることを確認
    expect(reloadMock).toHaveBeenCalled()
  })
})
