import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from '../App'

window.matchMedia =
  window.matchMedia ||
  function matchMedia() {
    return {
      matches: false,
      media: '',
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false
    }
  }

describe('App integration', () => {
  it('renders palette with default catalog', () => {
    render(<App />)
    expect(screen.getByText('パレット')).toBeInTheDocument()
    expect(screen.getAllByText('最大スプレッド').length).toBeGreaterThan(0)
  })

  it('renders filter blocks', () => {
    render(<App />)
    expect(screen.getAllByText(/最大スプレッド/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/ATR範囲/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/標準偏差範囲/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/曜日フィルタ/).length).toBeGreaterThan(0)
  })

  it('renders lot blocks', () => {
    render(<App />)
    expect(screen.getAllByText(/固定ロット/).length).toBeGreaterThan(0)
  })

  it('renders exit blocks', () => {
    render(<App />)
    expect(screen.getAllByText(/トレーリング/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/建値/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/週末/).length).toBeGreaterThan(0)
  })

  it('renders category tabs', () => {
    render(<App />)
    expect(screen.getAllByText('フィルタ').length).toBeGreaterThan(0)
    expect(screen.getAllByText('トレンド').length).toBeGreaterThan(0)
    expect(screen.getAllByText('トリガー').length).toBeGreaterThan(0)
    expect(screen.getAllByText('ロット').length).toBeGreaterThan(0)
    expect(screen.getAllByText('リスク').length).toBeGreaterThan(0)
    expect(screen.getAllByText('エグジット').length).toBeGreaterThan(0)
    expect(screen.getAllByText('ナンピン').length).toBeGreaterThan(0)
  })
})
