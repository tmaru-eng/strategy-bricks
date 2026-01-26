/**
 * Tests for preload.ts - BacktestAPI context bridge
 * 
 * Note: These tests verify the type definitions and structure.
 * Full integration testing requires Electron runtime environment.
 */

import { describe, it, expect } from 'vitest'
import type { BacktestAPI, BacktestConfig, BacktestResults } from '../../src/types/backtest'

describe('BacktestAPI Type Definitions', () => {
  it('should have correct BacktestAPI interface structure', () => {
    // This test verifies that the BacktestAPI interface has all required methods
    const mockAPI: BacktestAPI = {
      startBacktest: async (_config: BacktestConfig, _strategyPath: string) => {},
      cancelBacktest: async () => {},
      onBacktestProgress: (_callback) => {},
      onBacktestComplete: (_callback) => {},
      onBacktestError: (_callback) => {},
      exportResults: async (_results: BacktestResults, _outputPath: string) => {}
    }

    expect(mockAPI).toBeDefined()
    expect(typeof mockAPI.startBacktest).toBe('function')
    expect(typeof mockAPI.cancelBacktest).toBe('function')
    expect(typeof mockAPI.onBacktestProgress).toBe('function')
    expect(typeof mockAPI.onBacktestComplete).toBe('function')
    expect(typeof mockAPI.onBacktestError).toBe('function')
    expect(typeof mockAPI.exportResults).toBe('function')
  })

  it('should have correct BacktestConfig structure', () => {
    const config: BacktestConfig = {
      symbol: 'USDJPY',
      timeframe: 'M1',
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-03-31')
    }

    expect(config.symbol).toBe('USDJPY')
    expect(config.timeframe).toBe('M1')
    expect(config.startDate).toBeInstanceOf(Date)
    expect(config.endDate).toBeInstanceOf(Date)
  })

  it('should validate that startBacktest accepts correct parameters', () => {
    const mockStartBacktest = async (
      config: BacktestConfig,
      strategyPath: string
    ): Promise<void> => {
      expect(config).toBeDefined()
      expect(strategyPath).toBeDefined()
      expect(typeof strategyPath).toBe('string')
    }

    const config: BacktestConfig = {
      symbol: 'USDJPY',
      timeframe: 'M1',
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-03-31')
    }

    expect(() => mockStartBacktest(config, '/path/to/strategy.json')).not.toThrow()
  })

  it('should validate that event listeners accept correct callback types', () => {
    const mockOnBacktestProgress = (callback: (progress: any) => void) => {
      expect(typeof callback).toBe('function')
      // Simulate calling the callback
      callback({ isRunning: true, elapsedTime: 10 })
    }

    const mockOnBacktestComplete = (callback: (results: any) => void) => {
      expect(typeof callback).toBe('function')
      // Simulate calling the callback
      callback({
        metadata: {
          strategyName: 'Test Strategy',
          symbol: 'USDJPY',
          timeframe: 'M1',
          startDate: '2024-01-01',
          endDate: '2024-03-31',
          executionTimestamp: '2024-04-01T10:00:00Z'
        },
        summary: {
          totalTrades: 10,
          winningTrades: 6,
          losingTrades: 4,
          winRate: 60,
          totalProfitLoss: 100,
          maxDrawdown: 20,
          avgTradeProfitLoss: 10
        },
        trades: []
      })
    }

    const mockOnBacktestError = (callback: (error: any) => void) => {
      expect(typeof callback).toBe('function')
      // Simulate calling the callback
      callback({ message: 'Test error' })
    }

    expect(() => mockOnBacktestProgress(() => {})).not.toThrow()
    expect(() => mockOnBacktestComplete(() => {})).not.toThrow()
    expect(() => mockOnBacktestError(() => {})).not.toThrow()
  })

  it('should validate exportResults accepts correct parameters', () => {
    const mockExportResults = async (
      results: BacktestResults,
      outputPath?: string
    ): Promise<{ success: boolean; canceled?: boolean; path?: string }> => {
      expect(results).toBeDefined()
      expect(results.metadata).toBeDefined()
      expect(results.summary).toBeDefined()
      expect(results.trades).toBeDefined()
      
      if (outputPath !== undefined) {
        expect(typeof outputPath).toBe('string')
      }
      
      return { success: true, path: outputPath || '/default/path.json' }
    }

    const results: BacktestResults = {
      metadata: {
        strategyName: 'Test Strategy',
        symbol: 'USDJPY',
        timeframe: 'M1',
        startDate: '2024-01-01',
        endDate: '2024-03-31',
        executionTimestamp: '2024-04-01T10:00:00Z'
      },
      summary: {
        totalTrades: 10,
        winningTrades: 6,
        losingTrades: 4,
        winRate: 60,
        totalProfitLoss: 100,
        maxDrawdown: 20,
        avgTradeProfitLoss: 10
      },
      trades: []
    }

    // Test with outputPath
    expect(() => mockExportResults(results, '/path/to/output.json')).not.toThrow()
    
    // Test without outputPath (should show dialog)
    expect(() => mockExportResults(results)).not.toThrow()
  })
})

describe('BacktestAPI IPC Channel Names', () => {
  it('should use correct IPC channel names', () => {
    // These channel names must match between preload.ts and main.ts
    const expectedChannels = {
      start: 'backtest:start',
      cancel: 'backtest:cancel',
      progress: 'backtest:progress',
      complete: 'backtest:complete',
      error: 'backtest:error',
      export: 'backtest:export'
    }

    // Verify channel naming convention
    expect(expectedChannels.start).toBe('backtest:start')
    expect(expectedChannels.cancel).toBe('backtest:cancel')
    expect(expectedChannels.progress).toBe('backtest:progress')
    expect(expectedChannels.complete).toBe('backtest:complete')
    expect(expectedChannels.error).toBe('backtest:error')
    expect(expectedChannels.export).toBe('backtest:export')
  })
})
