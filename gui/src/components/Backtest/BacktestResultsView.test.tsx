import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BacktestResultsView } from './BacktestResultsView'
import type { BacktestResults } from '../../types/backtest'

// 各テスト後にクリーンアップ
afterEach(() => {
  cleanup()
})

describe('BacktestResultsView', () => {
  const mockResults: BacktestResults = {
    metadata: {
      strategyName: 'Test Strategy',
      symbol: 'USDJPY',
      timeframe: 'M1',
      startDate: '2024-01-01T00:00:00Z',
      endDate: '2024-03-31T23:59:59Z',
      executionTimestamp: '2024-04-01T10:30:00Z'
    },
    summary: {
      totalTrades: 150,
      winningTrades: 90,
      losingTrades: 60,
      winRate: 60.0,
      totalProfitLoss: 125.50,
      maxDrawdown: 45.20,
      avgTradeProfitLoss: 0.84
    },
    trades: [
      {
        entryTime: '2024-01-01T10:00:00Z',
        entryPrice: 145.123,
        exitTime: '2024-01-01T10:15:00Z',
        exitPrice: 145.156,
        positionSize: 1.0,
        profitLoss: 0.033,
        type: 'BUY'
      },
      {
        entryTime: '2024-01-01T11:00:00Z',
        entryPrice: 145.200,
        exitTime: '2024-01-01T11:30:00Z',
        exitPrice: 145.150,
        positionSize: 1.0,
        profitLoss: -0.050,
        type: 'SELL'
      }
    ]
  }

  it('結果がnullの場合は何も表示しない', () => {
    const { container } = render(
      <BacktestResultsView results={null} error={null} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('エラーがある場合はエラーメッセージを表示する', () => {
    const errorMessage = 'MT5への接続に失敗しました'
    render(
      <BacktestResultsView results={null} error={errorMessage} />
    )
    
    expect(screen.getByText('バックテストエラー')).toBeInTheDocument()
    expect(screen.getByText(errorMessage)).toBeInTheDocument()
  })

  it('結果がある場合はパフォーマンス指標を表示する', () => {
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    // ヘッダー
    expect(screen.getByText('バックテスト結果')).toBeInTheDocument()
    
    // メタデータ
    expect(screen.getByText('Test Strategy')).toBeInTheDocument()
    expect(screen.getByText('USDJPY')).toBeInTheDocument()
    expect(screen.getByText('M1')).toBeInTheDocument()
    
    // パフォーマンス指標
    expect(screen.getByText('総トレード数')).toBeInTheDocument()
    expect(screen.getByText('150')).toBeInTheDocument()
    
    expect(screen.getByText('勝率')).toBeInTheDocument()
    expect(screen.getByText('60.00%')).toBeInTheDocument()
    
    expect(screen.getByText('総損益')).toBeInTheDocument()
    expect(screen.getByText('+125.50000')).toBeInTheDocument()
    
    expect(screen.getByText('最大ドローダウン')).toBeInTheDocument()
    expect(screen.getByText('45.20000')).toBeInTheDocument()
    
    expect(screen.getByText('平均トレード損益')).toBeInTheDocument()
    expect(screen.getByText('+0.84000')).toBeInTheDocument()
  })

  it('トレードリストを表示する', () => {
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    // トレード履歴ヘッダー
    const tradeHistoryHeaders = screen.getAllByText('トレード履歴')
    expect(tradeHistoryHeaders.length).toBeGreaterThan(0)
    
    // テーブルヘッダー
    expect(screen.getByText('タイプ')).toBeInTheDocument()
    expect(screen.getByText('エントリー時刻')).toBeInTheDocument()
    expect(screen.getByText('エントリー価格')).toBeInTheDocument()
    expect(screen.getByText('エグジット時刻')).toBeInTheDocument()
    expect(screen.getByText('エグジット価格')).toBeInTheDocument()
    expect(screen.getByText('ロット')).toBeInTheDocument()
    expect(screen.getByText('損益')).toBeInTheDocument()
    
    // トレードデータ
    expect(screen.getByText('BUY')).toBeInTheDocument()
    expect(screen.getByText('SELL')).toBeInTheDocument()
    expect(screen.getByText('145.12300')).toBeInTheDocument()
    expect(screen.getByText('145.15600')).toBeInTheDocument()
    expect(screen.getByText('+0.03300')).toBeInTheDocument()
    expect(screen.getAllByText('-0.05000')[0]).toBeInTheDocument()
  })

  it('トレードが0件の場合はメッセージを表示する', () => {
    const emptyResults: BacktestResults = {
      ...mockResults,
      trades: []
    }
    
    render(
      <BacktestResultsView results={emptyResults} error={null} />
    )
    
    expect(screen.getByText('トレードが記録されていません')).toBeInTheDocument()
  })

  it('エクスポートボタンをクリックするとonExportが呼ばれる', async () => {
    const user = userEvent.setup()
    const onExport = vi.fn()
    
    render(
      <BacktestResultsView results={mockResults} error={null} onExport={onExport} />
    )
    
    const exportButton = screen.getByText('結果をエクスポート')
    await user.click(exportButton)
    
    expect(onExport).toHaveBeenCalledTimes(1)
  })

  it('onExportが提供されていない場合はデフォルトのエクスポート処理を実行する', async () => {
    const user = userEvent.setup()
    
    // Mock window.backtestAPI
    const mockExportResults = vi.fn().mockResolvedValue({ success: true, path: '/path/to/file.json' })
    window.backtestAPI = {
      exportResults: mockExportResults
    } as any
    
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    const exportButton = screen.getByText('結果をエクスポート')
    await user.click(exportButton)
    
    expect(mockExportResults).toHaveBeenCalledWith(mockResults)
    
    // Clean up
    delete window.backtestAPI
  })

  it('エクスポート成功時に成功メッセージを表示する', async () => {
    const user = userEvent.setup()
    
    // Mock window.backtestAPI
    const mockExportResults = vi.fn().mockResolvedValue({ success: true, path: '/path/to/file.json' })
    window.backtestAPI = {
      exportResults: mockExportResults
    } as any
    
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    const exportButton = screen.getByText('結果をエクスポート')
    await user.click(exportButton)
    
    // Wait for success message
    expect(await screen.findByText('✓ エクスポート完了')).toBeInTheDocument()
    
    // Clean up
    delete window.backtestAPI
  })

  it('エクスポート失敗時にエラーメッセージを表示する', async () => {
    const user = userEvent.setup()
    
    // Mock window.backtestAPI
    const mockExportResults = vi.fn().mockRejectedValue(new Error('ファイルの書き込みに失敗しました'))
    window.backtestAPI = {
      exportResults: mockExportResults
    } as any
    
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    const exportButton = screen.getByText('結果をエクスポート')
    await user.click(exportButton)
    
    // Wait for error message
    expect(await screen.findByText(/ファイルの書き込みに失敗しました/)).toBeInTheDocument()
    
    // Clean up
    delete window.backtestAPI
  })

  it('エクスポート中はボタンが無効化される', async () => {
    const user = userEvent.setup()
    
    // Mock window.backtestAPI with a delayed response
    const mockExportResults = vi.fn().mockImplementation(() => 
      new Promise(resolve => setTimeout(() => resolve({ success: true }), 100))
    )
    window.backtestAPI = {
      exportResults: mockExportResults
    } as any
    
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    const exportButton = screen.getByText('結果をエクスポート')
    await user.click(exportButton)
    
    // Button should show "エクスポート中..." and be disabled
    expect(screen.getByText('エクスポート中...')).toBeInTheDocument()
    expect(exportButton).toBeDisabled()
    
    // Clean up
    delete window.backtestAPI
  })

  it('勝率が正しく表示される', () => {
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    // 勝率のパーセンテージ
    const winRates = screen.getAllByText('60.00%')
    expect(winRates.length).toBeGreaterThan(0)
    
    // 勝ち/負けの内訳
    expect(screen.getByText(/勝ち: 90 \/ 負け: 60/)).toBeInTheDocument()
  })

  it('損益の色が正しく適用される（プラスは緑、マイナスは赤）', () => {
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    // 総損益（プラス）
    const totalPnL = screen.getAllByText('+125.50000')[0]
    expect(totalPnL).toHaveClass('text-green-600')
    
    // 平均トレード損益（プラス）
    const avgPnL = screen.getAllByText('+0.84000')[0]
    expect(avgPnL).toHaveClass('text-green-600')
    
    // トレードの損益（マイナス）
    const negativePnL = screen.getAllByText('-0.05000')[0]
    expect(negativePnL).toHaveClass('text-red-600')
  })

  it('日時が読みやすい形式でフォーマットされる', () => {
    render(
      <BacktestResultsView results={mockResults} error={null} />
    )
    
    // 日時がISO形式ではなく、ローカライズされた形式で表示されることを確認
    // 実際の表示形式はブラウザのロケールに依存するため、
    // ISO形式の文字列が直接表示されていないことを確認
    expect(screen.queryByText('2024-01-01T10:00:00Z')).not.toBeInTheDocument()
    expect(screen.queryByText('2024-04-01T10:30:00Z')).not.toBeInTheDocument()
  })

  it('エッジケース: 勝率0%の場合', () => {
    const allLosingResults: BacktestResults = {
      ...mockResults,
      summary: {
        ...mockResults.summary,
        winningTrades: 0,
        losingTrades: 150,
        winRate: 0.0,
        totalProfitLoss: -500.0,
        avgTradeProfitLoss: -3.33
      }
    }
    
    render(
      <BacktestResultsView results={allLosingResults} error={null} />
    )
    
    expect(screen.getByText('0.00%')).toBeInTheDocument()
    expect(screen.getByText(/勝ち: 0 \/ 負け: 150/)).toBeInTheDocument()
  })

  it('エッジケース: 勝率100%の場合', () => {
    const allWinningResults: BacktestResults = {
      ...mockResults,
      summary: {
        ...mockResults.summary,
        winningTrades: 150,
        losingTrades: 0,
        winRate: 100.0,
        totalProfitLoss: 500.0,
        avgTradeProfitLoss: 3.33
      }
    }
    
    render(
      <BacktestResultsView results={allWinningResults} error={null} />
    )
    
    expect(screen.getByText('100.00%')).toBeInTheDocument()
    expect(screen.getByText(/勝ち: 150 \/ 負け: 0/)).toBeInTheDocument()
  })

  it('エッジケース: 損益が0の場合', () => {
    const breakEvenResults: BacktestResults = {
      ...mockResults,
      summary: {
        ...mockResults.summary,
        totalProfitLoss: 0.0,
        avgTradeProfitLoss: 0.0
      },
      trades: [
        {
          ...mockResults.trades[0],
          profitLoss: 0.0
        }
      ]
    }
    
    const { container } = render(
      <BacktestResultsView results={breakEvenResults} error={null} />
    )
    
    // 損益が0の場合は符号なしで表示される
    // 0.00000 という値が表示されていることを確認
    const content = container.textContent || ''
    expect(content).toContain('0.00000')
  })
})
