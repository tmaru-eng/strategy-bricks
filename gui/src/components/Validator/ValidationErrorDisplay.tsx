import React from 'react'
import type { ValidationError } from '../../services/Validator'

export interface ValidationErrorDisplayProps {
  errors: ValidationError[]
}

/**
 * ValidationErrorDisplay component displays validation errors visually.
 * 
 * Features:
 * - Displays error type, message, and location information
 * - Uses color-coded styling based on error type
 * - Shows empty state when no errors
 * 
 * Requirements: 2.3
 */
export const ValidationErrorDisplay: React.FC<ValidationErrorDisplayProps> = ({ errors }) => {
  if (errors.length === 0) {
    return null
  }

  return (
    <div className="validation-errors">
      <h3 className="validation-errors-title">設定エラー</h3>
      <ul className="validation-errors-list">
        {errors.map((error, index) => (
          <li key={index} className="validation-error-item">
            <div className="validation-error-header">
              <span className="validation-error-type">{error.type}</span>
            </div>
            <div className="validation-error-message">{error.message}</div>
            <div className="validation-error-location">
              <small>場所: {error.location}</small>
            </div>
          </li>
        ))}
      </ul>
    </div>
  )
}
