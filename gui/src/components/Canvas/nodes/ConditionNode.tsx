import React from 'react'
import { Handle, Position, NodeProps } from 'reactflow'

type ConditionData = {
  blockTypeId?: string
  displayName?: string
}

export const ConditionNode: React.FC<NodeProps<ConditionData>> = ({ data }) => {
  return (
    <div className="flow-node flow-node-condition">
      <div className="flow-title">条件</div>
      <div className="flow-subtitle">
        {data.displayName || data.blockTypeId || 'ブロックをドロップ'}
      </div>
      <Handle type="target" position={Position.Left} />
    </div>
  )
}
