import { describe, expect, it } from 'vitest'
import { validateNodes } from '../services/Validator'
import type { Node } from 'reactflow'

const catalog = {
  meta: { formatVersion: '1.0' },
  blocks: [
    {
      typeId: 'trend.maRelation',
      category: 'trend',
      displayName: 'MA上下',
      paramsSchema: {
        type: 'object',
        required: ['period'],
        properties: {
          period: { type: 'integer' }
        }
      }
    }
  ]
}

const createNode = (params?: Record<string, unknown>): Node => ({
  id: 'node-1',
  type: 'conditionNode',
  position: { x: 0, y: 0 },
  data: {
    blockTypeId: 'trend.maRelation',
    params: params ?? {}
  }
})

describe('validateNodes', () => {
  it('returns warning when catalog is missing', () => {
    const issues = validateNodes([], null)
    expect(issues).toHaveLength(1)
    expect(issues[0].type).toBe('warning')
  })

  it('returns error when required param is missing', () => {
    const issues = validateNodes([createNode()], catalog)
    expect(issues.some((issue) => issue.type === 'error')).toBe(true)
  })

  it('passes when required param is provided', () => {
    const issues = validateNodes([createNode({ period: 20 })], catalog)
    expect(issues.some((issue) => issue.type === 'error')).toBe(false)
  })
})
