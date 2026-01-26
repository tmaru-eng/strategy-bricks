import { describe, it, expect } from 'vitest'
import { 
  BlockIdReferenceRule, 
  DuplicateBlockIdRule, 
  BlockIdFormatRule,
  type StrategyConfig 
} from '../Validator'

describe('BlockIdReferenceRule', () => {
  it('should pass validation when all blockId references exist in blocks array', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [
        {
          id: 'S1',
          name: 'Strategy 1',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG1',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#1' },
                  { blockId: 'trend.maRelation#1' }
                ]
              }
            ]
          }
        }
      ],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'trend.maRelation#1', typeId: 'trend.maRelation', params: {} }
      ]
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should detect unresolved block reference', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [
        {
          id: 'S1',
          name: 'Strategy 1',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG1',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#1' },
                  { blockId: 'trend.maRelation#999' } // This doesn't exist
                ]
              }
            ]
          }
        }
      ],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }
      ]
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('UNRESOLVED_BLOCK_REFERENCE')
    expect(errors[0].message).toContain('trend.maRelation#999')
    expect(errors[0].message).toContain('blocks[] に存在しません')
    expect(errors[0].location).toContain('strategies[S1]')
    expect(errors[0].location).toContain('ruleGroups[RG1]')
  })

  it('should detect multiple unresolved block references', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [
        {
          id: 'S1',
          name: 'Strategy 1',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG1',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#999' }, // Missing
                  { blockId: 'trend.maRelation#999' } // Missing
                ]
              }
            ]
          }
        }
      ],
      blocks: []
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(2)
    expect(errors[0].type).toBe('UNRESOLVED_BLOCK_REFERENCE')
    expect(errors[1].type).toBe('UNRESOLVED_BLOCK_REFERENCE')
  })

  it('should validate across multiple strategies and rule groups', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [
        {
          id: 'S1',
          name: 'Strategy 1',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG1',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#1' }
                ]
              },
              {
                id: 'RG2',
                type: 'AND',
                conditions: [
                  { blockId: 'trend.maRelation#999' } // Missing
                ]
              }
            ]
          }
        },
        {
          id: 'S2',
          name: 'Strategy 2',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG3',
                type: 'AND',
                conditions: [
                  { blockId: 'trigger.bbReentry#999' } // Missing
                ]
              }
            ]
          }
        }
      ],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }
      ]
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(2)
    expect(errors[0].message).toContain('trend.maRelation#999')
    expect(errors[0].location).toContain('strategies[S1]')
    expect(errors[0].location).toContain('ruleGroups[RG2]')
    expect(errors[1].message).toContain('trigger.bbReentry#999')
    expect(errors[1].location).toContain('strategies[S2]')
    expect(errors[1].location).toContain('ruleGroups[RG3]')
  })

  it('should handle shared blocks correctly', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [
        {
          id: 'S1',
          name: 'Strategy 1',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG1',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#1' },
                  { blockId: 'trend.maRelation#1' }
                ]
              },
              {
                id: 'RG2',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#1' }, // Shared block
                  { blockId: 'trend.maRelation#2' }
                ]
              }
            ]
          }
        }
      ],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'trend.maRelation#1', typeId: 'trend.maRelation', params: {} },
        { id: 'trend.maRelation#2', typeId: 'trend.maRelation', params: {} }
      ]
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should handle empty strategies array', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }
      ]
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should handle empty blocks array', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [
        {
          id: 'S1',
          name: 'Strategy 1',
          entryRequirement: {
            type: 'OR',
            ruleGroups: [
              {
                id: 'RG1',
                type: 'AND',
                conditions: [
                  { blockId: 'filter.spreadMax#1' }
                ]
              }
            ]
          }
        }
      ],
      blocks: []
    }

    const rule = new BlockIdReferenceRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('UNRESOLVED_BLOCK_REFERENCE')
  })
})

describe('DuplicateBlockIdRule', () => {
  it('should pass validation when all blockIds are unique', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'filter.spreadMax#2', typeId: 'filter.spreadMax', params: {} },
        { id: 'trend.maRelation#1', typeId: 'trend.maRelation', params: {} }
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should detect duplicate blockId', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} } // Duplicate
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('DUPLICATE_BLOCK_ID')
    expect(errors[0].message).toContain('filter.spreadMax#1')
    expect(errors[0].message).toContain('2 回出現しています')
    expect(errors[0].location).toBe('blocks[]')
  })

  it('should detect multiple duplicate blockIds', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }, // Duplicate
        { id: 'trend.maRelation#1', typeId: 'trend.maRelation', params: {} },
        { id: 'trend.maRelation#1', typeId: 'trend.maRelation', params: {} }, // Duplicate
        { id: 'trend.maRelation#1', typeId: 'trend.maRelation', params: {} }  // Triplicate
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(2)
    expect(errors[0].type).toBe('DUPLICATE_BLOCK_ID')
    expect(errors[0].message).toContain('filter.spreadMax#1')
    expect(errors[0].message).toContain('2 回出現しています')
    expect(errors[1].type).toBe('DUPLICATE_BLOCK_ID')
    expect(errors[1].message).toContain('trend.maRelation#1')
    expect(errors[1].message).toContain('3 回出現しています')
  })

  it('should report correct count for triplicates', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].message).toContain('3 回出現しています')
  })

  it('should handle empty blocks array', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: []
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should handle single block', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should detect duplicates with different typeIds', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'filter.spreadMax#1', typeId: 'trend.maRelation', params: {} } // Same id, different typeId
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('DUPLICATE_BLOCK_ID')
    expect(errors[0].message).toContain('filter.spreadMax#1')
  })

  it('should detect duplicates with different params', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: { maxSpreadPips: 2.0 } },
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: { maxSpreadPips: 3.0 } } // Same id, different params
      ]
    }

    const rule = new DuplicateBlockIdRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('DUPLICATE_BLOCK_ID')
    expect(errors[0].message).toContain('filter.spreadMax#1')
  })
})

describe('BlockIdFormatRule', () => {
  it('should pass validation when all blockIds follow the correct format', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} },
        { id: 'trend.maRelation#2', typeId: 'trend.maRelation', params: {} },
        { id: 'trigger.bbReentry#123', typeId: 'trigger.bbReentry', params: {} },
        { id: 'simple#1', typeId: 'simple', params: {} },
        { id: 'with_underscore#99', typeId: 'with_underscore', params: {} }
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should detect blockId without hash separator', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax1', typeId: 'filter.spreadMax', params: {} } // Missing #
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter.spreadMax1')
    expect(errors[0].message).toContain('形式 "{typeId}#{index}" に従っていません')
    expect(errors[0].location).toBe('blocks[filter.spreadMax1]')
  })

  it('should detect blockId with non-numeric index', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#abc', typeId: 'filter.spreadMax', params: {} } // Non-numeric index
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter.spreadMax#abc')
  })

  it('should detect blockId with empty typeId', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: '#1', typeId: 'filter.spreadMax', params: {} } // Empty typeId
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('#1')
  })

  it('should detect blockId with empty index', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#', typeId: 'filter.spreadMax', params: {} } // Empty index
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter.spreadMax#')
  })

  it('should detect blockId with negative index', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#-1', typeId: 'filter.spreadMax', params: {} } // Negative index
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter.spreadMax#-1')
  })

  it('should detect blockId with decimal index', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1.5', typeId: 'filter.spreadMax', params: {} } // Decimal index
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter.spreadMax#1.5')
  })

  it('should detect blockId with special characters in typeId', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter@spreadMax#1', typeId: 'filter@spreadMax', params: {} }, // @ not allowed
        { id: 'filter-spreadMax#1', typeId: 'filter-spreadMax', params: {} }  // - not allowed
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(2)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter@spreadMax#1')
    expect(errors[1].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[1].message).toContain('filter-spreadMax#1')
  })

  it('should detect multiple invalid blockIds', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1', typeId: 'filter.spreadMax', params: {} }, // Valid
        { id: 'trend.maRelation', typeId: 'trend.maRelation', params: {} },   // Missing #
        { id: 'trigger.bbReentry#abc', typeId: 'trigger.bbReentry', params: {} }, // Non-numeric
        { id: '#5', typeId: 'simple', params: {} }  // Empty typeId
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(3)
    expect(errors[0].message).toContain('trend.maRelation')
    expect(errors[1].message).toContain('trigger.bbReentry#abc')
    expect(errors[2].message).toContain('#5')
  })

  it('should handle empty blocks array', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: []
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should accept blockId with zero index', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#0', typeId: 'filter.spreadMax', params: {} } // Zero is valid
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should accept blockId with large index', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#999999', typeId: 'filter.spreadMax', params: {} } // Large index
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should accept blockId with multiple dots in typeId', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'category.subcategory.blockName#1', typeId: 'category.subcategory.blockName', params: {} }
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should accept blockId with underscores in typeId', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter_spread_max#1', typeId: 'filter_spread_max', params: {} }
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(0)
  })

  it('should detect blockId with multiple hash separators', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spreadMax#1#2', typeId: 'filter.spreadMax', params: {} } // Multiple #
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(1)
    expect(errors[0].type).toBe('INVALID_BLOCK_ID_FORMAT')
    expect(errors[0].message).toContain('filter.spreadMax#1#2')
  })

  it('should detect blockId with spaces', () => {
    const config: StrategyConfig = {
      meta: {
        formatVersion: '1.0',
        name: 'test',
        generatedBy: 'test',
        generatedAt: '2024-01-01T00:00:00Z'
      },
      strategies: [],
      blocks: [
        { id: 'filter.spread Max#1', typeId: 'filter.spreadMax', params: {} }, // Space in typeId
        { id: 'filter.spreadMax# 1', typeId: 'filter.spreadMax', params: {} }  // Space in index
      ]
    }

    const rule = new BlockIdFormatRule()
    const errors = rule.validate(config)

    expect(errors).toHaveLength(2)
    expect(errors[0].message).toContain('filter.spread Max#1')
    expect(errors[1].message).toContain('filter.spreadMax# 1')
  })
})
