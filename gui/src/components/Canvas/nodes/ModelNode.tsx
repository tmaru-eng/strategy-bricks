import React from 'react'
import { Handle, Position, NodeProps } from 'reactflow'

type ModelData = {
  label: string
}

export const ModelNode: React.FC<NodeProps<ModelData>> = ({ data }) => {
  return (
    <div className="flow-node flow-node-model">
      <div className="flow-title">{data.label}</div>
      <div className="flow-subtitle">モデルをドロップ</div>
      <Handle type="target" position={Position.Left} />
    </div>
  )
}
