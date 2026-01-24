import React from 'react'
import { Handle, Position } from 'reactflow'

export const StrategyNode: React.FC = () => {
  return (
    <div className="flow-node flow-node-strategy">
      <div className="flow-title">ストラテジー</div>
      <div className="flow-subtitle">エントリー + モデル</div>
      <Handle type="source" position={Position.Right} />
    </div>
  )
}
