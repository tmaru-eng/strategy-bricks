import React from 'react'
import { Handle, Position } from 'reactflow'

export const RuleGroupNode: React.FC = () => {
  return (
    <div className="flow-node flow-node-rulegroup">
      <div className="flow-title">ルールグループ</div>
      <div className="flow-subtitle">AND 条件</div>
      <Handle type="target" position={Position.Left} />
      <Handle type="source" position={Position.Right} />
    </div>
  )
}
