import React, { useMemo } from 'react'
import { useStateManager } from '../../store/useStateManager'
import { FormGenerator } from './FormGenerator'

export const PropertyPanel: React.FC = () => {
  const { catalog, nodes, selectedNodeId, updateNodeData } = useStateManager()
  const selectedNode = useMemo(
    () => nodes.find((node) => node.id === selectedNodeId) || null,
    [nodes, selectedNodeId]
  )

  if (!selectedNode || selectedNode.type !== 'conditionNode') {
    return <div className="panel-empty">条件ブロックを選択してください</div>
  }

  const blockTypeId = selectedNode.data?.blockTypeId as string | undefined
  if (!blockTypeId || !catalog) {
    return <div className="panel-empty">ブロック情報がありません</div>
  }

  const blockDefinition = catalog.blocks.find((block) => block.typeId === blockTypeId)
  if (!blockDefinition) {
    return <div className="panel-empty">ブロック定義が見つかりません</div>
  }

  const formData = (selectedNode.data?.params || {}) as Record<string, unknown>

  return (
    <div className="property-root">
      <div className="property-header">
        <div className="property-title">{blockDefinition.displayName}</div>
        <div className="property-type">{blockDefinition.typeId}</div>
        {blockDefinition.description && (
          <div className="property-description">{blockDefinition.description}</div>
        )}
      </div>

      <FormGenerator
        schema={blockDefinition.paramsSchema}
        formData={formData}
        onChange={(data) => updateNodeData(selectedNode.id, { params: data })}
      />
    </div>
  )
}
