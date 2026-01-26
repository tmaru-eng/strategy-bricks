import React from 'react'
import { ReactFlowProvider } from 'reactflow'
import { NodeEditor } from './NodeEditor'
import { useStateManager } from '../../store/useStateManager'

export const Canvas: React.FC = () => {
  const { addRuleGroup, deleteSelectedNode, selectedNodeId } = useStateManager()

  return (
    <div className="canvas-root">
      <div className="canvas-toolbar">
        <button className="btn" onClick={addRuleGroup}>
          ルールグループ追加
        </button>
        <button 
          className="btn btn-danger" 
          onClick={deleteSelectedNode}
          disabled={!selectedNodeId}
          title="選択したノードを削除 (Delete/Backspaceキーでも削除可能)"
        >
          選択を削除
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
