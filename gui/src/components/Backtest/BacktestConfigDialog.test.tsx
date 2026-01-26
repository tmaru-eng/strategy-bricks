import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { BacktestConfigDialog, validateBacktestConfig } from './BacktestConfigDialog'
import type { BacktestConfig } from '../../types/backtest'

describe('BacktestConfigDialog', () => {
  const mockOnClose = vi.fn()
  const mockOnSubmit = vi.fn()
  
  beforeEach(() => {
    mockOnClose.mockClear()
    mockOnSubmit.mockClear()
    localStorage.clear()
  })
  
  afterEach(() => {
    cleanup()
  })
  
  describe('validateBacktestConfig', () => {
    it('should reject empty symbol', () => {
      const config: BacktestConfig = {
        symbol: '',
        timeframe: 'M1',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-03-31')
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toContain('シンボルは必須です')
    })
    
    it('should reject whitespace-only symbol', () => {
      const config: BacktestConfig = {
        symbol: '   ',
        timeframe: 'M1',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-03-31')
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toContain('シンボルは必須です')
    })
    
    it('should reject empty timeframe', () => {
      const config: BacktestConfig = {
        symbol: 'USDJPY',
        timeframe: '',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-03-31')
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toContain('時間軸は必須です')
    })
    
    it('should reject end date before start date', () => {
      const config: BacktestConfig = {
        symbol: 'USDJPY',
        timeframe: 'M1',
        startDate: new Date('2024-03-31'),
        endDate: new Date('2024-01-01')
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toContain('開始日は終了日より前である必要があります')
    })
    
    it('should reject end date equal to start date', () => {
      const config: BacktestConfig = {
        symbol: 'USDJPY',
        timeframe: 'M1',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-01-01')
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toContain('開始日は終了日より前である必要があります')
    })
    
    it('should reject future end date', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 1)
      
      const config: BacktestConfig = {
        symbol: 'USDJPY',
        timeframe: 'M1',
        startDate: new Date('2024-01-01'),
        endDate: futureDate
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toContain('終了日は未来の日付にできません')
    })
    
    it('should accept valid configuration', () => {
      const config: BacktestConfig = {
        symbol: 'USDJPY',
        timeframe: 'M1',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-03-31')
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors).toHaveLength(0)
    })
    
    it('should return multiple errors for multiple issues', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 1)
      
      const config: BacktestConfig = {
        symbol: '',
        timeframe: '',
        startDate: new Date('2024-03-31'),
        endDate: futureDate
      }
      
      const errors = validateBacktestConfig(config)
      expect(errors.length).toBeGreaterThan(1)
      expect(errors).toContain('シンボルは必須です')
      expect(errors).toContain('時間軸は必須です')
    })
  })
  
  describe('Component Rendering', () => {
    it('should not render when isOpen is false', () => {
      render(
        <BacktestConfigDialog
          isOpen={false}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      expect(screen.queryByText('バックテスト設定')).not.toBeInTheDocument()
    })
    
    it('should render when isOpen is true', () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      expect(screen.getByText('バックテスト設定')).toBeInTheDocument()
    })
    
    it('should render with default values', () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      const timeframeSelect = screen.getByLabelText('時間軸') as HTMLSelectElement
      
      expect(symbolInput.value).toBe('USDJPY')
      expect(timeframeSelect.value).toBe('M1')
    })
    
    it('should render with lastConfig values', () => {
      const lastConfig: BacktestConfig = {
        symbol: 'EURUSD',
        timeframe: 'H1',
        startDate: new Date('2024-02-01'),
        endDate: new Date('2024-04-30')
      }
      
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
          lastConfig={lastConfig}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      const timeframeSelect = screen.getByLabelText('時間軸') as HTMLSelectElement
      
      expect(symbolInput.value).toBe('EURUSD')
      expect(timeframeSelect.value).toBe('H1')
    })
  })
  
  describe('User Interactions', () => {
    it('should call onClose when cancel button is clicked', () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      fireEvent.click(cancelButton)
      
      expect(mockOnClose).toHaveBeenCalledTimes(1)
    })
    
    it('should update symbol input', () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      fireEvent.change(symbolInput, { target: { value: 'GBPUSD' } })
      
      expect(symbolInput.value).toBe('GBPUSD')
    })
    
    it('should update timeframe select', () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const timeframeSelect = screen.getByLabelText('時間軸') as HTMLSelectElement
      fireEvent.change(timeframeSelect, { target: { value: 'H4' } })
      
      expect(timeframeSelect.value).toBe('H4')
    })
    
    it('should display validation errors on invalid submit', async () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      // Clear symbol to make it invalid
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      fireEvent.change(symbolInput, { target: { value: '' } })
      
      const submitButton = screen.getByRole('button', { name: '実行' })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(screen.getByText('シンボルは必須です')).toBeInTheDocument()
      })
      
      expect(mockOnSubmit).not.toHaveBeenCalled()
    })
    
    it('should call onSubmit with valid configuration', async () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      const timeframeSelect = screen.getByLabelText('時間軸') as HTMLSelectElement
      const startDateInput = screen.getByLabelText('開始日') as HTMLInputElement
      const endDateInput = screen.getByLabelText('終了日') as HTMLInputElement
      
      fireEvent.change(symbolInput, { target: { value: 'EURUSD' } })
      fireEvent.change(timeframeSelect, { target: { value: 'H1' } })
      fireEvent.change(startDateInput, { target: { value: '2024-01-01' } })
      fireEvent.change(endDateInput, { target: { value: '2024-03-31' } })
      
      const submitButton = screen.getByRole('button', { name: '実行' })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledTimes(1)
      })
      
      const submittedConfig = mockOnSubmit.mock.calls[0][0] as BacktestConfig
      expect(submittedConfig.symbol).toBe('EURUSD')
      expect(submittedConfig.timeframe).toBe('H1')
    })
    
    it('should trim whitespace from symbol', async () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      fireEvent.change(symbolInput, { target: { value: '  EURUSD  ' } })
      
      const submitButton = screen.getByRole('button', { name: '実行' })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledTimes(1)
      })
      
      const submittedConfig = mockOnSubmit.mock.calls[0][0] as BacktestConfig
      expect(submittedConfig.symbol).toBe('EURUSD')
    })
  })
  
  describe('LocalStorage Persistence', () => {
    it('should save configuration to localStorage on submit', async () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      fireEvent.change(symbolInput, { target: { value: 'GBPUSD' } })
      
      const submitButton = screen.getByRole('button', { name: '実行' })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalled()
      })
      
      const stored = localStorage.getItem('backtest-config')
      expect(stored).not.toBeNull()
      
      const parsed = JSON.parse(stored!)
      expect(parsed.symbol).toBe('GBPUSD')
    })
    
    it('should load configuration from localStorage on mount', () => {
      const savedConfig = {
        symbol: 'AUDUSD',
        timeframe: 'M15',
        startDate: new Date('2024-02-01').toISOString(),
        endDate: new Date('2024-04-30').toISOString()
      }
      
      localStorage.setItem('backtest-config', JSON.stringify(savedConfig))
      
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      const timeframeSelect = screen.getByLabelText('時間軸') as HTMLSelectElement
      
      expect(symbolInput.value).toBe('AUDUSD')
      expect(timeframeSelect.value).toBe('M15')
    })
    
    it('should prefer lastConfig over localStorage', () => {
      const savedConfig = {
        symbol: 'AUDUSD',
        timeframe: 'M15',
        startDate: new Date('2024-02-01').toISOString(),
        endDate: new Date('2024-04-30').toISOString()
      }
      
      localStorage.setItem('backtest-config', JSON.stringify(savedConfig))
      
      const lastConfig: BacktestConfig = {
        symbol: 'NZDUSD',
        timeframe: 'H4',
        startDate: new Date('2024-03-01'),
        endDate: new Date('2024-05-31')
      }
      
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
          lastConfig={lastConfig}
        />
      )
      
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      const timeframeSelect = screen.getByLabelText('時間軸') as HTMLSelectElement
      
      expect(symbolInput.value).toBe('NZDUSD')
      expect(timeframeSelect.value).toBe('H4')
    })
  })
  
  describe('Error Handling', () => {
    it('should clear errors when cancel is clicked', async () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      // Trigger validation error
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      fireEvent.change(symbolInput, { target: { value: '' } })
      
      const submitButton = screen.getByRole('button', { name: '実行' })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(screen.getByText('シンボルは必須です')).toBeInTheDocument()
      })
      
      // Click cancel
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      fireEvent.click(cancelButton)
      
      expect(mockOnClose).toHaveBeenCalled()
    })
    
    it('should clear errors on successful submit', async () => {
      render(
        <BacktestConfigDialog
          isOpen={true}
          onClose={mockOnClose}
          onSubmit={mockOnSubmit}
        />
      )
      
      // First, trigger an error
      const symbolInput = screen.getByLabelText('シンボル') as HTMLInputElement
      fireEvent.change(symbolInput, { target: { value: '' } })
      
      const submitButton = screen.getByRole('button', { name: '実行' })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(screen.getByText('シンボルは必須です')).toBeInTheDocument()
      })
      
      // Fix the error and submit again
      fireEvent.change(symbolInput, { target: { value: 'USDJPY' } })
      fireEvent.click(submitButton)
      
      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalled()
      })
      
      expect(screen.queryByText('シンボルは必須です')).not.toBeInTheDocument()
    })
  })
})
