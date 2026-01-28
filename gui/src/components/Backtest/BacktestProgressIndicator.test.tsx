import { describe, it, expect, afterEach, vi } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { BacktestProgressIndicator } from './BacktestProgressIndicator'

describe('BacktestProgressIndicator', () => {
  afterEach(() => {
    cleanup()
  })
  
  describe('表示/非表示', () => {
    it('isRunning が false の場合は何も表示しない', () => {
      const { container } = render(
        <BacktestProgressIndicator
          isRunning={false}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      expect(container.firstChild).toBeNull()
    })
    
    it('isRunning が true の場合は進捗インジケーターを表示する', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      expect(screen.getByText('バックテスト実行中')).toBeInTheDocument()
      expect(screen.getByText('バックテストを実行しています。しばらくお待ちください...')).toBeInTheDocument()
    })
  })
  
  describe('経過時間の表示', () => {
    it('0秒の場合は "00:00" と表示する', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      expect(screen.getByText('00:00')).toBeInTheDocument()
    })
    
    it('30秒の場合は "00:30" と表示する', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={30}
          onCancel={() => {}}
        />
      )
      
      expect(screen.getByText('00:30')).toBeInTheDocument()
    })
    
    it('90秒の場合は "01:30" と表示する', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={90}
          onCancel={() => {}}
        />
      )
      
      expect(screen.getByText('01:30')).toBeInTheDocument()
    })
    
    it('3665秒（1時間1分5秒）の場合は "61:05" と表示する', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={3665}
          onCancel={() => {}}
        />
      )
      
      expect(screen.getByText('61:05')).toBeInTheDocument()
    })
  })
  
  describe('キャンセルボタン', () => {
    it('キャンセルボタンが表示される', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      expect(cancelButton).toBeInTheDocument()
      expect(cancelButton).not.toBeDisabled()
    })
    
    it('キャンセルボタンをクリックすると onCancel が呼ばれる', () => {
      const onCancel = vi.fn()
      
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={onCancel}
        />
      )
      
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      fireEvent.click(cancelButton)
      
      expect(onCancel).toHaveBeenCalledTimes(1)
    })
    
    it('キャンセルボタンをクリックすると "キャンセル中..." と表示される', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      fireEvent.click(cancelButton)
      
      expect(screen.getByRole('button', { name: 'キャンセル中...' })).toBeInTheDocument()
      expect(screen.getByText('バックテストをキャンセルしています...')).toBeInTheDocument()
    })
    
    it('キャンセル中はボタンが無効化される', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      fireEvent.click(cancelButton)
      
      const cancelingButton = screen.getByRole('button', { name: 'キャンセル中...' })
      expect(cancelingButton).toBeDisabled()
    })
  })
  
  describe('UI要素', () => {
    it('スピナーアイコンが表示される', () => {
      const { container } = render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      // スピナーアイコン（animate-spin クラスを持つ要素）を確認
      const spinner = container.querySelector('.animate-spin')
      expect(spinner).toBeInTheDocument()
    })
    
    it('プログレスバーが表示される', () => {
      const { container } = render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      // プログレスバー（animate-progress クラスを持つ要素）を確認
      const progressBar = container.querySelector('.animate-progress')
      expect(progressBar).toBeInTheDocument()
    })
    
    it('経過時間のラベルが表示される', () => {
      render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      expect(screen.getByText('経過時間:')).toBeInTheDocument()
    })
  })
  
  describe('状態のリセット', () => {
    it('isRunning が false になるとキャンセル状態がリセットされる', () => {
      const { rerender } = render(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      // キャンセルボタンをクリック
      const cancelButton = screen.getByRole('button', { name: 'キャンセル' })
      fireEvent.click(cancelButton)
      
      // キャンセル中の状態を確認
      expect(screen.getByRole('button', { name: 'キャンセル中...' })).toBeInTheDocument()
      
      // isRunning を false に変更
      rerender(
        <BacktestProgressIndicator
          isRunning={false}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      // コンポーネントが非表示になることを確認
      expect(screen.queryByText('バックテスト実行中')).not.toBeInTheDocument()
      
      // 再度 isRunning を true に変更
      rerender(
        <BacktestProgressIndicator
          isRunning={true}
          elapsedTime={0}
          onCancel={() => {}}
        />
      )
      
      // キャンセル状態がリセットされていることを確認
      expect(screen.getByRole('button', { name: 'キャンセル' })).toBeInTheDocument()
      expect(screen.queryByText('バックテストをキャンセルしています...')).not.toBeInTheDocument()
    })
  })
})
