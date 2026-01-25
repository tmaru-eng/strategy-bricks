import { create } from 'zustand'
import {
  applyEdgeChanges,
  applyNodeChanges,
  type Edge,
  type EdgeChange,
  type Node,
  type NodeChange
} from 'reactflow'
import type { BlockCatalog } from '../models/catalog'
import defaultCatalog from '../resources/block_catalog.default.json'
import { exportConfig } from '../services/Exporter'
import { validateNodes, type ValidationIssue } from '../services/Validator'

type FlowState = {
  nodes: Node[]
  edges: Edge[]
  selectedNodeId: string | null
  validationIssues: ValidationIssue[]
  updateNodes: (nodes: Node[]) => void
  updateEdges: (edges: Edge[]) => void
  onNodesChange: (changes: NodeChange[]) => void
  onEdgesChange: (changes: EdgeChange[]) => void
  selectNode: (nodeId: string | null) => void
  addRuleGroup: () => void
  updateNodeData: (nodeId: string, data: Record<string, unknown>) => void
  runValidation: () => ValidationIssue[]
  exportCurrentConfig: (profileName: string) => Promise<{ ok: boolean; path?: string }>
}

type CatalogState = {
  catalog: BlockCatalog
}

const initialNodes: Node[] = [
  {
    id: 'strategy-1',
    type: 'strategyNode',
    position: { x: 80, y: 140 },
    data: {}
  },
  {
    id: 'rulegroup-1',
    type: 'ruleGroupNode',
    position: { x: 260, y: 140 },
    data: {}
  },
  {
    id: 'condition-1',
    type: 'conditionNode',
    position: { x: 500, y: 90 },
    data: {
      blockTypeId: 'filter.spreadMax',
      displayName: '最大スプレッド',
      params: {
        maxSpreadPips: 2
      }
    }
  },
  {
    id: 'condition-2',
    type: 'conditionNode',
    position: { x: 500, y: 180 },
    data: {
      blockTypeId: 'trend.maRelation',
      displayName: 'MA上下',
      params: {
        period: 20,
        maMethod: 'SMA',
        appliedPrice: 'CLOSE',
        relation: 'above'
      }
    }
  },
  {
    id: 'condition-3',
    type: 'conditionNode',
    position: { x: 500, y: 270 },
    data: {
      blockTypeId: 'trigger.bbReentry',
      displayName: 'ボリンジャー回帰',
      params: {
        period: 20,
        deviation: 2,
        appliedPrice: 'CLOSE'
      }
    }
  },
  {
    id: 'model-lot',
    type: 'modelNode',
    position: { x: 420, y: 60 },
    data: { label: 'ロットモデル' }
  },
  {
    id: 'model-risk',
    type: 'modelNode',
    position: { x: 420, y: 140 },
    data: { label: 'リスクモデル' }
  },
  {
    id: 'model-exit',
    type: 'modelNode',
    position: { x: 420, y: 220 },
    data: { label: 'エグジットモデル' }
  },
  {
    id: 'model-nanpin',
    type: 'modelNode',
    position: { x: 420, y: 300 },
    data: { label: 'ナンピンモデル' }
  }
]

const initialEdges: Edge[] = [
  { id: 'edge-strategy-rulegroup', source: 'strategy-1', target: 'rulegroup-1' },
  { id: 'edge-rulegroup-1', source: 'rulegroup-1', target: 'condition-1' },
  { id: 'edge-rulegroup-2', source: 'rulegroup-1', target: 'condition-2' },
  { id: 'edge-rulegroup-3', source: 'rulegroup-1', target: 'condition-3' },
  { id: 'edge-strategy-lot', source: 'strategy-1', target: 'model-lot' },
  { id: 'edge-strategy-risk', source: 'strategy-1', target: 'model-risk' },
  { id: 'edge-strategy-exit', source: 'strategy-1', target: 'model-exit' },
  { id: 'edge-strategy-nanpin', source: 'strategy-1', target: 'model-nanpin' }
]

export const useStateManager = create<CatalogState & FlowState>((set, get) => ({
  catalog: defaultCatalog as BlockCatalog,
  nodes: initialNodes,
  edges: initialEdges,
  selectedNodeId: null,
  validationIssues: [],
  updateNodes: (nodes) => set({ nodes }),
  updateEdges: (edges) => set({ edges }),
  onNodesChange: (changes) =>
    set((state) => ({ nodes: applyNodeChanges(changes, state.nodes) })),
  onEdgesChange: (changes) =>
    set((state) => ({ edges: applyEdgeChanges(changes, state.edges) })),
  selectNode: (nodeId) => set({ selectedNodeId: nodeId }),
  addRuleGroup: () => {
    const nodes = get().nodes
    const maxY =
      nodes.length > 0 ? Math.max(...nodes.map((node) => node.position.y)) : 100

    const nextNode: Node = {
      id: `rulegroup-${crypto.randomUUID()}`,
      type: 'ruleGroupNode',
      position: { x: 260, y: maxY + 200 },
      data: {}
    }
    set({ nodes: [...nodes, nextNode] })
  },
  updateNodeData: (nodeId, data) => {
    const nodes = get().nodes
    const nextNodes = nodes.map((node) => {
      if (node.id !== nodeId) return node
      return {
        ...node,
        data: {
          ...node.data,
          ...data
        }
      }
    })
    set({ nodes: nextNodes })
  },
  runValidation: () => {
    const nodes = get().nodes
    const catalog = get().catalog
    const issues = validateNodes(nodes, catalog)
    set({ validationIssues: issues })
    return issues
  },
  exportCurrentConfig: async (profileName) => {
    const nodes = get().nodes
    return exportConfig(profileName, nodes)
  }
}))
