import React from 'react'
import { ReactFlowProvider } from 'reactflow'
import { NodeEditor } from './NodeEditor'
import { useStateManager } from '../../store/useStateManager'

export const Canvas: React.FC = () => {
  const { addRuleGroup } = useStateManager()

  return (
    <div className="canvas-root">
      <div className="canvas-toolbar">
        <button className="btn" onClick={addRuleGroup}>
          ルールグループ追加
        </button>
      </div>
      <div className="canvas-stage">
        <ReactFlowProvider>
          <NodeEditor />
        </ReactFlowProvider>
      </div>
    </div>
  )
}
