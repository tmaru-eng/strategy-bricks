import React from 'react'
import { useStateManager } from '../../store/useStateManager'

export const ValidationPanel: React.FC = () => {
  const { validationIssues, selectNode } = useStateManager()

  if (validationIssues.length === 0) {
    return <div className="panel-empty">まだ検証していません</div>
  }

  return (
    <div className="validation-root">
      {validationIssues.map((issue, index) => (
        <button
          key={`${issue.message}-${index}`}
          className={`validation-item ${issue.type}`}
          onClick={() => issue.nodeId && selectNode(issue.nodeId)}
          type="button"
        >
          <span className="validation-dot" />
          <span className="validation-message">{issue.message}</span>
        </button>
      ))}
    </div>
  )
}
