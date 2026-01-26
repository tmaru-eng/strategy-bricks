import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ValidationErrorDisplay } from '../ValidationErrorDisplay'
import type { ValidationError } from '../../../services/Validator'

describe('ValidationErrorDisplay', () => {
  it('should render nothing when errors array is empty', () => {
    const { container } = render(<ValidationErrorDisplay errors={[]} />)
    expect(container.firstChild).toBeNull()
  })

  it('should display error type, message, and location', () => {
    const errors: ValidationError[] = [
      {
        type: 'UNRESOLVED_BLOCK_REFERENCE',
        message: 'blockId "filter.spreadMax#1" が blocks[] に存在しません',
        location: 'strategies[S1].ruleGroups[RG1]'
      }
    ]

    render(<ValidationErrorDisplay errors={errors} />)

    // Check title
    expect(screen.getByText('設定エラー')).toBeInTheDocument()

    // Check error type
    expect(screen.getByText('UNRESOLVED_BLOCK_REFERENCE')).toBeInTheDocument()

    // Check error message
    expect(screen.getByText('blockId "filter.spreadMax#1" が blocks[] に存在しません')).toBeInTheDocument()

    // Check location
    expect(screen.getByText(/場所: strategies\[S1\]\.ruleGroups\[RG1\]/)).toBeInTheDocument()
  })

  it('should display multiple errors', () => {
    const errors: ValidationError[] = [
      {
        type: 'UNRESOLVED_BLOCK_REFERENCE',
        message: 'blockId "filter.spreadMax#1" が blocks[] に存在しません',
        location: 'strategies[S1].ruleGroups[RG1]'
      },
      {
        type: 'DUPLICATE_BLOCK_ID',
        message: 'blockId "trend.maRelation#1" が 2 回出現しています',
        location: 'blocks[]'
      },
      {
        type: 'INVALID_BLOCK_ID_FORMAT',
        message: 'blockId "invalid" が形式 "{typeId}#{index}" に従っていません',
        location: 'blocks[invalid]'
      }
    ]

    const { container } = render(<ValidationErrorDisplay errors={errors} />)

    // Check all error types are displayed
    const errorTypes = container.querySelectorAll('.validation-error-type')
    expect(errorTypes).toHaveLength(3)
    expect(errorTypes[0].textContent).toBe('UNRESOLVED_BLOCK_REFERENCE')
    expect(errorTypes[1].textContent).toBe('DUPLICATE_BLOCK_ID')
    expect(errorTypes[2].textContent).toBe('INVALID_BLOCK_ID_FORMAT')

    // Check all messages are displayed
    const errorMessages = container.querySelectorAll('.validation-error-message')
    expect(errorMessages).toHaveLength(3)
    expect(errorMessages[0].textContent).toBe('blockId "filter.spreadMax#1" が blocks[] に存在しません')
    expect(errorMessages[1].textContent).toBe('blockId "trend.maRelation#1" が 2 回出現しています')
    expect(errorMessages[2].textContent).toBe('blockId "invalid" が形式 "{typeId}#{index}" に従っていません')
  })

  it('should render error items with correct structure', () => {
    const errors: ValidationError[] = [
      {
        type: 'UNRESOLVED_BLOCK_REFERENCE',
        message: 'Test error message',
        location: 'test.location'
      }
    ]

    const { container } = render(<ValidationErrorDisplay errors={errors} />)

    // Check structure
    expect(container.querySelector('.validation-errors')).toBeInTheDocument()
    expect(container.querySelector('.validation-errors-title')).toBeInTheDocument()
    expect(container.querySelector('.validation-errors-list')).toBeInTheDocument()
    expect(container.querySelector('.validation-error-item')).toBeInTheDocument()
    expect(container.querySelector('.validation-error-header')).toBeInTheDocument()
    expect(container.querySelector('.validation-error-type')).toBeInTheDocument()
    expect(container.querySelector('.validation-error-message')).toBeInTheDocument()
    expect(container.querySelector('.validation-error-location')).toBeInTheDocument()
  })
})
