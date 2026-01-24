import React from 'react'
import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from '../App'

window.matchMedia =
  window.matchMedia ||
  function matchMedia() {
    return {
      matches: false,
      addListener: () => {},
      removeListener: () => {}
    }
  }

describe('App integration', () => {
  it('renders palette with default catalog', () => {
    render(<App />)
    expect(screen.getByText('パレット')).toBeInTheDocument()
    expect(screen.getAllByText('最大スプレッド').length).toBeGreaterThan(0)
  })
})
