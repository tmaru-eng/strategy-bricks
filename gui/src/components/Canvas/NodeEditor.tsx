import React, { useCallback, useMemo } from 'react'
import ReactFlow, {
  addEdge,
  Background,
  Connection,
  Controls,
  Node,
  useReactFlow
} from 'reactflow'
import 'reactflow/dist/style.css'
import { useStateManager } from '../../store/useStateManager'
import { StrategyNode } from './nodes/StrategyNode'
import { RuleGroupNode } from './nodes/RuleGroupNode'
import { ConditionNode } from './nodes/ConditionNode'
import { ModelNode } from './nodes/ModelNode'

const nodeTypes = {
  strategyNode: StrategyNode,
  ruleGroupNode: RuleGroupNode,
  conditionNode: ConditionNode,
  modelNode: ModelNode
}

const isValidConnection = (connection: Connection, nodes: Node[]): boolean => {
  const source = nodes.find((node) => node.id === connection.source)
  const target = nodes.find((node) => node.id === connection.target)

  if (!source || !target) return false

  if (source.type === 'strategyNode' && target.type === 'ruleGroupNode') {
    return true
  }

  if (source.type === 'ruleGroupNode' && target.type === 'conditionNode') {
    return true
  }

  if (source.type === 'strategyNode' && target.type === 'modelNode') {
    return true
  }

  return false
}

export const NodeEditor: React.FC = () => {
  const {
    nodes,
    edges,
    updateNodes,
    updateEdges,
    onNodesChange,
    onEdgesChange,
    selectNode
  } = useStateManager()
  const { project } = useReactFlow()

  const onConnect = useCallback(
    (params: Connection) => {
      if (!isValidConnection(params, nodes)) {
        return
      }

      const nextEdges = addEdge(params, edges)
      updateEdges(nextEdges)
    },
    [edges, nodes, updateEdges]
  )

  const onDragOver = useCallback((event: React.DragEvent) => {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }, [])

  const onDrop = useCallback(
    (event: React.DragEvent) => {
      event.preventDefault()
      const reactFlowBounds = event.currentTarget.getBoundingClientRect()
      const payload = event.dataTransfer.getData('application/strategy-block')

      if (!payload) return

      let data: { typeId: string; displayName: string }
      try {
        data = JSON.parse(payload) as { typeId: string; displayName: string }
      } catch {
        console.error('Invalid drag payload:', payload)
        return
      }

      // Viewport projection
      const position = project({
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top
      })

      // Generate blockId: count existing blocks of same typeId and increment
      const existingBlocksOfType = nodes.filter(
        (n) => n.type === 'conditionNode' && n.data?.blockTypeId === data.typeId
      )
      const blockIndex = existingBlocksOfType.length + 1
      const blockId = `${data.typeId}#${blockIndex}`

      const newNode: Node = {
        id: `condition-${crypto.randomUUID()}`,
        type: 'conditionNode',
        position,
        data: {
          blockId: blockId,
          blockTypeId: data.typeId,
          displayName: data.displayName,
          params: {}
        }
      }

      const nextNodes = [...nodes, newNode]
      updateNodes(nextNodes)
    },
    [nodes, updateNodes, project]
  )

  const onNodeClick = useCallback(
    (_: React.MouseEvent, node: Node) => {
      selectNode(node.id)
    },
    [selectNode]
  )

  const defaultViewport = useMemo(() => ({ x: 0, y: 0, zoom: 1 }), [])

  return (
    <div className="node-editor">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onDrop={onDrop}
        onDragOver={onDragOver}
        onNodeClick={onNodeClick}
        fitView
        defaultViewport={defaultViewport}
        nodesDeletable={true}
        edgesDeletable={true}
        deleteKeyCode={['Backspace', 'Delete']}
      >
        <Background gap={22} size={1} />
        <Controls />
      </ReactFlow>
    </div>
  )
}
