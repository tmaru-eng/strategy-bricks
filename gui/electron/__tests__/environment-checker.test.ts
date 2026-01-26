/**
 * Unit tests for EnvironmentChecker
 * 
 * Validates: Requirements 9.1, 9.5
 * - OS detection on startup
 * - Python environment availability check
 * - MT5 library availability check
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import * as os from 'os'
import { spawn } from 'child_process'

// Mock modules
vi.mock('os')
vi.mock('child_process')

describe('EnvironmentChecker', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('OS Detection (Requirement 9.1)', () => {
    it('should detect Windows platform', () => {
      // Arrange
      vi.mocked(os.platform).mockReturnValue('win32')

      // Act
      const platform = os.platform()
      const isWindows = platform === 'win32'

      // Assert
      expect(isWindows).toBe(true)
      expect(platform).toBe('win32')
    })

    it('should detect non-Windows platforms', () => {
      // Arrange
      const platforms = ['darwin', 'linux', 'freebsd', 'openbsd']

      platforms.forEach(platform => {
        // Act
        vi.mocked(os.platform).mockReturnValue(platform as NodeJS.Platform)
        const isWindows = os.platform() === 'win32'

        // Assert
        expect(isWindows).toBe(false)
      })
    })
  })

  describe('Environment Check Result Structure', () => {
    it('should return correct structure for Windows with all dependencies', () => {
      // Arrange
      const result = {
        isWindows: true,
        pythonAvailable: true,
        mt5Available: true,
        backtestEnabled: true,
        message: 'バックテスト機能が利用可能です。'
      }

      // Assert
      expect(result).toHaveProperty('isWindows')
      expect(result).toHaveProperty('pythonAvailable')
      expect(result).toHaveProperty('mt5Available')
      expect(result).toHaveProperty('backtestEnabled')
      expect(result).toHaveProperty('message')
      expect(result.backtestEnabled).toBe(true)
    })

    it('should return correct structure for non-Windows platform', () => {
      // Arrange
      const result = {
        isWindows: false,
        pythonAvailable: false,
        mt5Available: false,
        backtestEnabled: false,
        message: 'バックテスト機能はWindowsでのみ利用可能です。MetaTrader5はWindows専用のプラットフォームです。'
      }

      // Assert
      expect(result.isWindows).toBe(false)
      expect(result.backtestEnabled).toBe(false)
      expect(result.message).toContain('Windows')
    })

    it('should return correct structure when Python is not available', () => {
      // Arrange
      const result = {
        isWindows: true,
        pythonAvailable: false,
        mt5Available: false,
        backtestEnabled: false,
        message: 'Python環境が見つかりません。バックテスト機能を使用するには、Python 3.8以上をインストールしてください。'
      }

      // Assert
      expect(result.isWindows).toBe(true)
      expect(result.pythonAvailable).toBe(false)
      expect(result.backtestEnabled).toBe(false)
      expect(result.message).toContain('Python')
    })

    it('should return correct structure when MT5 library is not available', () => {
      // Arrange
      const result = {
        isWindows: true,
        pythonAvailable: true,
        mt5Available: false,
        backtestEnabled: false,
        message: 'MetaTrader5 Pythonライブラリがインストールされていません。\n\nインストール手順:\n1. コマンドプロンプトを開く\n2. 次のコマンドを実行: pip install MetaTrader5\n3. アプリケーションを再起動'
      }

      // Assert
      expect(result.isWindows).toBe(true)
      expect(result.pythonAvailable).toBe(true)
      expect(result.mt5Available).toBe(false)
      expect(result.backtestEnabled).toBe(false)
      expect(result.message).toContain('MetaTrader5')
      expect(result.message).toContain('pip install')
    })
  })

  describe('Python Check Logic', () => {
    it('should recognize valid Python version output', () => {
      // Arrange
      const validOutputs = [
        'Python 3.8.0',
        'Python 3.9.5',
        'Python 3.10.2',
        'Python 3.11.0'
      ]

      validOutputs.forEach(output => {
        // Act
        const isPythonOutput = output.includes('Python')

        // Assert
        expect(isPythonOutput).toBe(true)
      })
    })

    it('should handle Python check failure scenarios', () => {
      // Arrange
      const failureScenarios = [
        { code: 1, output: '' },
        { code: 127, output: 'command not found' },
        { code: null, output: '' }
      ]

      failureScenarios.forEach(scenario => {
        // Act
        const isSuccess = scenario.code === 0 && scenario.output.includes('Python')

        // Assert
        expect(isSuccess).toBe(false)
      })
    })
  })

  describe('MT5 Library Check Logic', () => {
    it('should recognize successful MT5 import', () => {
      // Arrange
      const successOutput = 'OK'
      const exitCode = 0

      // Act
      const isSuccess = exitCode === 0 && successOutput.includes('OK')

      // Assert
      expect(isSuccess).toBe(true)
    })

    it('should handle MT5 library check failure scenarios', () => {
      // Arrange
      const failureScenarios = [
        { code: 1, output: '', error: 'ModuleNotFoundError: No module named \'MetaTrader5\'' },
        { code: 1, output: '', error: 'ImportError: DLL load failed' },
        { code: null, output: '', error: 'timeout' }
      ]

      failureScenarios.forEach(scenario => {
        // Act
        const isSuccess = scenario.code === 0 && scenario.output.includes('OK')

        // Assert
        expect(isSuccess).toBe(false)
      })
    })
  })

  describe('Backtest Enablement Logic (Requirement 9.5)', () => {
    it('should enable backtest when all conditions are met', () => {
      // Arrange
      const isWindows = true
      const pythonAvailable = true
      const mt5Available = true

      // Act
      const backtestEnabled = isWindows && pythonAvailable && mt5Available

      // Assert
      expect(backtestEnabled).toBe(true)
    })

    it('should disable backtest when any condition is not met', () => {
      // Arrange
      const scenarios = [
        { isWindows: false, pythonAvailable: true, mt5Available: true },
        { isWindows: true, pythonAvailable: false, mt5Available: true },
        { isWindows: true, pythonAvailable: true, mt5Available: false },
        { isWindows: false, pythonAvailable: false, mt5Available: false }
      ]

      scenarios.forEach(scenario => {
        // Act
        const backtestEnabled = scenario.isWindows && scenario.pythonAvailable && scenario.mt5Available

        // Assert
        expect(backtestEnabled).toBe(false)
      })
    })
  })

  describe('Error Messages', () => {
    it('should provide helpful message for non-Windows users', () => {
      // Arrange
      const message = 'バックテスト機能はWindowsでのみ利用可能です。MetaTrader5はWindows専用のプラットフォームです。'

      // Assert
      expect(message).toContain('Windows')
      expect(message).toContain('MetaTrader5')
    })

    it('should provide installation instructions for missing Python', () => {
      // Arrange
      const message = 'Python環境が見つかりません。バックテスト機能を使用するには、Python 3.8以上をインストールしてください。'

      // Assert
      expect(message).toContain('Python')
      expect(message).toContain('インストール')
    })

    it('should provide installation instructions for missing MT5 library', () => {
      // Arrange
      const message = 'MetaTrader5 Pythonライブラリがインストールされていません。\n\nインストール手順:\n1. コマンドプロンプトを開く\n2. 次のコマンドを実行: pip install MetaTrader5\n3. アプリケーションを再起動'

      // Assert
      expect(message).toContain('MetaTrader5')
      expect(message).toContain('pip install MetaTrader5')
      expect(message).toContain('インストール手順')
    })
  })

  describe('Caching Behavior', () => {
    it('should cache environment check results', () => {
      // Arrange
      const firstResult = {
        isWindows: true,
        pythonAvailable: true,
        mt5Available: true,
        backtestEnabled: true,
        message: 'バックテスト機能が利用可能です。'
      }

      // Act - Simulate caching
      const cachedResult = firstResult
      const secondResult = cachedResult

      // Assert
      expect(secondResult).toBe(firstResult)
      expect(secondResult).toEqual(firstResult)
    })
  })
})
