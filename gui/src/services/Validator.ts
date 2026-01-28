import type { Node } from 'reactflow'
import type { BlockCatalog } from '../models/catalog'

export type ValidationIssue = {
  type: 'error' | 'warning'
  message: string
  nodeId?: string
}

export type ValidationError = {
  type: string
  message: string
  location: string
}

export type StrategyConfig = {
  meta: {
    formatVersion: string
    name: string
    generatedBy: string
    generatedAt: string
  }
  globalGuards?: Record<string, unknown>
  strategies: Array<{
    id: string
    name: string
    entryRequirement: {
      type: string
      ruleGroups: Array<{
        id: string
        type: string
        conditions: Array<{
          blockId: string
        }>
      }>
    }
  }>
  blocks: Array<{
    id: string
    typeId: string
    params: Record<string, unknown>
  }>
}

export interface ValidationRule {
  name: string
  validate(config: StrategyConfig): ValidationError[]
}

/**
 * BlockIdReferenceRule validates that all condition.blockId references
 * exist in the blocks[] array.
 * 
 * Validates: Requirements 2.1
 */
export class BlockIdReferenceRule implements ValidationRule {
  name = 'BlockIdReferenceRule'

  validate(config: StrategyConfig): ValidationError[] {
    const blockIds = new Set(config.blocks.map(b => b.id))
    const errors: ValidationError[] = []

    for (const strategy of config.strategies) {
      for (const ruleGroup of strategy.entryRequirement.ruleGroups) {
        for (const condition of ruleGroup.conditions) {
          if (!blockIds.has(condition.blockId)) {
            errors.push({
              type: 'UNRESOLVED_BLOCK_REFERENCE',
              message: `blockId "${condition.blockId}" が blocks[] に存在しません`,
              location: `strategies[${strategy.id}].ruleGroups[${ruleGroup.id}]`
            })
          }
        }
      }
    }

    return errors
  }
}

/**
 * DuplicateBlockIdRule validates that all blockIds in the blocks[] array are unique.
 * 
 * Validates: Requirements 2.4
 */
export class DuplicateBlockIdRule implements ValidationRule {
  name = 'DuplicateBlockIdRule'

  validate(config: StrategyConfig): ValidationError[] {
    const seen = new Map<string, number>()
    const errors: ValidationError[] = []

    // Count occurrences of each blockId
    for (const block of config.blocks) {
      const count = seen.get(block.id) || 0
      seen.set(block.id, count + 1)
    }

    // Report duplicates
    for (const [blockId, count] of seen.entries()) {
      if (count > 1) {
        errors.push({
          type: 'DUPLICATE_BLOCK_ID',
          message: `blockId "${blockId}" が ${count} 回出現しています`,
          location: 'blocks[]'
        })
      }
    }

    return errors
  }
}

/**
 * BlockIdFormatRule validates that all blockIds follow the {typeId}#{index} format.
 * 
 * Validates: Requirements 4.1
 */
export class BlockIdFormatRule implements ValidationRule {
  name = 'BlockIdFormatRule'

  validate(config: StrategyConfig): ValidationError[] {
    const errors: ValidationError[] = []
    // Pattern: {typeId}#{index} where typeId can contain alphanumeric, dots, and underscores
    // and index is a positive integer
    const pattern = /^[a-zA-Z0-9._]+#\d+$/

    for (const block of config.blocks) {
      if (!pattern.test(block.id)) {
        errors.push({
          type: 'INVALID_BLOCK_ID_FORMAT',
          message: `blockId "${block.id}" が形式 "{typeId}#{index}" に従っていません`,
          location: `blocks[${block.id}]`
        })
      }
    }

    return errors
  }
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
    const requiredFields =
      'required' in blockDef.paramsSchema && Array.isArray(blockDef.paramsSchema.required)
        ? (blockDef.paramsSchema.required as string[])
        : undefined
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
