import { describe, it, expect, beforeEach } from 'vitest'
import { NodeManager } from '../NodeManager'
import type { Node } from 'reactflow'

describe('NodeManager', () => {
  let manager: NodeManager

  beforeEach(() => {
    manager = new NodeManager()
  })

  describe('assignBlockId', () => {
    it('should assign unique blockId to new node', () => {
      const node1: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }
      const node2: Node = {
        id: 'node2',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      const blockId1 = manager.assignBlockId(node1)
      const blockId2 = manager.assignBlockId(node2)

      expect(blockId1).toBe('filter.spreadMax#1')
      expect(blockId2).toBe('filter.spreadMax#2')
      expect(blockId1).not.toBe(blockId2)
    })

    it('should assign different counters for different typeIds', () => {
      const node1: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }
      const node2: Node = {
        id: 'node2',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'trend.maRelation' }
      }
      const node3: Node = {
        id: 'node3',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      const blockId1 = manager.assignBlockId(node1)
      const blockId2 = manager.assignBlockId(node2)
      const blockId3 = manager.assignBlockId(node3)

      expect(blockId1).toBe('filter.spreadMax#1')
      expect(blockId2).toBe('trend.maRelation#1')
      expect(blockId3).toBe('filter.spreadMax#2')
    })

    it('should store blockId in node data', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      manager.assignBlockId(node)

      expect(node.data.blockId).toBe('filter.spreadMax#1')
    })

    it('should throw error if blockTypeId is missing', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: {}
      }

      expect(() => manager.assignBlockId(node)).toThrow('blockTypeId is required')
    })

    it('should throw error if node data is undefined', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: undefined
      }

      expect(() => manager.assignBlockId(node)).toThrow('blockTypeId is required')
    })
  })

  describe('getBlockId', () => {
    it('should return blockId for assigned node', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      manager.assignBlockId(node)
      const blockId = manager.getBlockId('node1')

      expect(blockId).toBe('filter.spreadMax#1')
    })

    it('should return undefined for unassigned node', () => {
      const blockId = manager.getBlockId('nonexistent')

      expect(blockId).toBeUndefined()
    })
  })

  describe('getAllBlockIds', () => {
    it('should return all assigned blockIds', () => {
      const node1: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }
      const node2: Node = {
        id: 'node2',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'trend.maRelation' }
      }

      manager.assignBlockId(node1)
      manager.assignBlockId(node2)

      const allBlockIds = manager.getAllBlockIds()

      expect(allBlockIds).toHaveLength(2)
      expect(allBlockIds).toContain('filter.spreadMax#1')
      expect(allBlockIds).toContain('trend.maRelation#1')
    })

    it('should return empty array when no blockIds assigned', () => {
      const allBlockIds = manager.getAllBlockIds()

      expect(allBlockIds).toHaveLength(0)
    })
  })

  describe('reset', () => {
    it('should clear all state', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      manager.assignBlockId(node)
      manager.reset()

      expect(manager.getBlockId('node1')).toBeUndefined()
      expect(manager.getAllBlockIds()).toHaveLength(0)
    })

    it('should reset counters', () => {
      const node1: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }
      const node2: Node = {
        id: 'node2',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      manager.assignBlockId(node1)
      manager.reset()
      manager.assignBlockId(node2)

      expect(node2.data.blockId).toBe('filter.spreadMax#1')
    })
  })

  describe('initializeFromNodes', () => {
    it('should initialize from nodes with existing blockIds', () => {
      const nodes: Node[] = [
        {
          id: 'node1',
          type: 'conditionNode',
          position: { x: 0, y: 0 },
          data: { blockTypeId: 'filter.spreadMax', blockId: 'filter.spreadMax#1' }
        },
        {
          id: 'node2',
          type: 'conditionNode',
          position: { x: 0, y: 0 },
          data: { blockTypeId: 'trend.maRelation', blockId: 'trend.maRelation#2' }
        }
      ]

      manager.initializeFromNodes(nodes)

      expect(manager.getBlockId('node1')).toBe('filter.spreadMax#1')
      expect(manager.getBlockId('node2')).toBe('trend.maRelation#2')
    })

    it('should update counters to highest existing value', () => {
      const nodes: Node[] = [
        {
          id: 'node1',
          type: 'conditionNode',
          position: { x: 0, y: 0 },
          data: { blockTypeId: 'filter.spreadMax', blockId: 'filter.spreadMax#3' }
        }
      ]

      manager.initializeFromNodes(nodes)

      const newNode: Node = {
        id: 'node2',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      manager.assignBlockId(newNode)

      expect(newNode.data.blockId).toBe('filter.spreadMax#4')
    })

    it('should skip non-condition nodes', () => {
      const nodes: Node[] = [
        {
          id: 'strategy1',
          type: 'strategyNode',
          position: { x: 0, y: 0 },
          data: {}
        },
        {
          id: 'node1',
          type: 'conditionNode',
          position: { x: 0, y: 0 },
          data: { blockTypeId: 'filter.spreadMax', blockId: 'filter.spreadMax#1' }
        }
      ]

      manager.initializeFromNodes(nodes)

      expect(manager.getBlockId('strategy1')).toBeUndefined()
      expect(manager.getBlockId('node1')).toBe('filter.spreadMax#1')
    })

    it('should skip nodes without blockId', () => {
      const nodes: Node[] = [
        {
          id: 'node1',
          type: 'conditionNode',
          position: { x: 0, y: 0 },
          data: { blockTypeId: 'filter.spreadMax' }
        }
      ]

      manager.initializeFromNodes(nodes)

      expect(manager.getBlockId('node1')).toBeUndefined()
    })

    it('should handle invalid blockId format gracefully', () => {
      const nodes: Node[] = [
        {
          id: 'node1',
          type: 'conditionNode',
          position: { x: 0, y: 0 },
          data: { blockTypeId: 'filter.spreadMax', blockId: 'invalid-format' }
        }
      ]

      expect(() => manager.initializeFromNodes(nodes)).not.toThrow()
      expect(manager.getBlockId('node1')).toBe('invalid-format')
    })
  })

  describe('blockId format', () => {
    it('should follow {typeId}#{counter} format', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'filter.spreadMax' }
      }

      const blockId = manager.assignBlockId(node)

      expect(blockId).toMatch(/^[a-zA-Z0-9._]+#\d+$/)
    })

    it('should handle complex typeIds with dots', () => {
      const node: Node = {
        id: 'node1',
        type: 'conditionNode',
        position: { x: 0, y: 0 },
        data: { blockTypeId: 'category.subcategory.blockName' }
      }

      const blockId = manager.assignBlockId(node)

      expect(blockId).toBe('category.subcategory.blockName#1')
    })
  })
})
