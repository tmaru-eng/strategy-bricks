import type { Node } from 'reactflow'
import type { BlockCatalog } from '../models/catalog'

export type ValidationIssue = {
  type: 'error' | 'warning'
  message: string
  nodeId?: string
}

const isConditionNode = (node: Node) => node.type === 'conditionNode'

export const validateNodes = (nodes: Node[], catalog: BlockCatalog | null): ValidationIssue[] => {
  const issues: ValidationIssue[] = []

  if (!catalog) {
    return [
      {
        type: 'warning',
        message: 'カタログが読み込まれていません'
      }
    ]
  }

  const conditionNodes = nodes.filter(isConditionNode)
  if (conditionNodes.length === 0) {
    issues.push({
      type: 'warning',
      message: '条件ブロックが配置されていません'
    })
  }

  conditionNodes.forEach((node) => {
    const blockTypeId = node.data?.blockTypeId as string | undefined
    if (!blockTypeId) {
      issues.push({
        type: 'error',
        message: '条件ノードにブロック種別が設定されていません',
        nodeId: node.id
      })
      return
    }

    const blockDef = catalog.blocks.find((block) => block.typeId === blockTypeId)
    if (!blockDef) {
      issues.push({
        type: 'error',
        message: `ブロック定義が見つかりません: ${blockTypeId}`,
        nodeId: node.id
      })
      return
    }

    const params = (node.data?.params || {}) as Record<string, unknown>
    const requiredFields = (blockDef.paramsSchema as { required?: string[] })?.required
    if (requiredFields) {
      requiredFields.forEach((field) => {
        if (params[field] === undefined) {
          issues.push({
            type: 'error',
            message: `必須パラメータ '${field}' が未設定です`,
            nodeId: node.id
          })
        }
      })
    }
  })

  return issues
}
