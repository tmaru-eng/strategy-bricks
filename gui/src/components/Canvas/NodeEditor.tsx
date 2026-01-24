import React, { useCallback, useMemo, useEffect } from 'react'
import ReactFlow, {
  addEdge,
  Background,
  Connection,
  Controls,
  Node,
  useEdgesState,
  useNodesState
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
  const { nodes: storedNodes, edges: storedEdges, updateNodes, updateEdges, selectNode } =
    useStateManager()
  const [nodes, setNodes, onNodesChange] = useNodesState(storedNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(storedEdges)

  useEffect(() => {
    updateNodes(nodes)
  }, [nodes, updateNodes])

  useEffect(() => {
    updateEdges(edges)
  }, [edges, updateEdges])

  const onConnect = useCallback(
    (params: Connection) => {
      if (!isValidConnection(params, nodes)) {
        return
      }

      const nextEdges = addEdge(params, edges)
      setEdges(nextEdges)
      updateEdges(nextEdges)
    },
    [edges, nodes, setEdges, updateEdges]
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

      const data = JSON.parse(payload) as { typeId: string; displayName: string }

      const position = {
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top
      }

      const newNode: Node = {
        id: `condition-${Date.now()}`,
        type: 'conditionNode',
        position,
        data: {
          blockTypeId: data.typeId,
          displayName: data.displayName,
          params: {}
        }
      }

      const nextNodes = [...nodes, newNode]
      setNodes(nextNodes)
      updateNodes(nextNodes)
    },
    [nodes, setNodes, updateNodes]
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
      >
        <Background gap={22} size={1} />
        <Controls />
      </ReactFlow>
    </div>
  )
}
