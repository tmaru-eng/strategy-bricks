import type { Node, Edge } from 'reactflow'
import {
  BlockIdReferenceRule,
  DuplicateBlockIdRule,
  BlockIdFormatRule,
  type ValidationError,
  type StrategyConfig
} from './Validator'

export type ExportResult = {
  ok: boolean
  path?: string
  errors?: ValidationError[]
}

const buildBlocks = (nodes: Node[]) => {
  const conditionNodes = nodes.filter((node) => node.type === 'conditionNode')
  return conditionNodes.map((node) => ({
    id: node.data?.blockId || '',
    typeId: node.data?.blockTypeId || 'unknown',
    params: node.data?.params || {}
  }))
}

const buildStrategies = (nodes: Node[], edges: Edge[]) => {
  const strategyNodes = nodes.filter((node) => node.type === 'strategyNode')
  const ruleGroupNodes = nodes.filter((node) => node.type === 'ruleGroupNode')
  const conditionNodes = nodes.filter((node) => node.type === 'conditionNode')
  
  return strategyNodes.map((strategyNode, index) => {
    // このStrategyに接続されているRuleGroupを取得
    const connectedRuleGroups = edges
      .filter((edge) => edge.source === strategyNode.id && ruleGroupNodes.some(rg => rg.id === edge.target))
      .map((edge) => ruleGroupNodes.find(rg => rg.id === edge.target))
      .filter((rg): rg is Node => rg !== undefined)
    
    // 各RuleGroupに接続されているConditionを取得
    const ruleGroups = connectedRuleGroups.map((ruleGroup) => {
      const connectedConditions = edges
        .filter((edge) => edge.source === ruleGroup.id && conditionNodes.some(c => c.id === edge.target))
        .map((edge) => conditionNodes.find(c => c.id === edge.target))
        .filter((c): c is Node => c !== undefined)
      
      return {
        id: ruleGroup.id,
        type: 'AND' as const,
        conditions: connectedConditions.map((condition) => ({
          blockId: condition.data?.blockId || ''
        }))
      }
    })
    
    return {
      id: `S${index + 1}`,
      name: strategyNode.data?.name || `Strategy ${index + 1}`,
      enabled: true,
      priority: 10,
      conflictPolicy: 'firstOnly',
      directionPolicy: 'both',
      entryRequirement: {
        type: 'OR' as const,
        ruleGroups
      },
      lotModel: { type: 'lot.fixed', params: { lots: 0.1 } },
      riskModel: { type: 'risk.fixedSLTP', params: { slPips: 30, tpPips: 30 } },
      exitModel: { type: 'exit.none', params: {} },
      nanpinModel: { type: 'nanpin.off', params: {} }
    }
  })
}

const buildConfig = (nodes: Node[], edges: Edge[], profileName: string) => {
  return {
    meta: {
      formatVersion: '1.0',
      name: profileName,
      generatedBy: 'GUI Builder',
      generatedAt: new Date().toISOString()
    },
    globalGuards: {
      timeframe: 'M1',
      useClosedBarOnly: true,
      noReentrySameBar: true,
      maxPositionsTotal: 1,
      maxPositionsPerSymbol: 1,
      maxSpreadPips: 30.0,
      session: {
        enabled: true,
        windows: [
          { start: '07:00', end: '14:59' },
          { start: '15:03', end: '23:00' }
        ],
        weekDays: { sun: false, mon: true, tue: true, wed: true, thu: true, fri: true, sat: false }
      }
    },
    strategies: buildStrategies(nodes, edges),
    blocks: buildBlocks(nodes)
  }
}

export const exportConfig = async (profileName: string, nodes: Node[], edges: Edge[]): Promise<ExportResult> => {
  console.log('[Exporter] Starting export...', { profileName, nodeCount: nodes.length, edgeCount: edges.length })
  
  if (!window.electron?.exportConfig) {
    console.error('[Exporter] Electron bridge is not available')
    return Promise.reject(new Error('Electron bridge is not available'))
  }

  const config = buildConfig(nodes, edges, profileName)
  console.log('[Exporter] Config built:', JSON.stringify(config, null, 2))
  
  // Validate the config before exporting
  console.log('[Exporter] Running validation...')
  const validationErrors = validateConfig(config as StrategyConfig)
  
  if (validationErrors.length > 0) {
    console.error('[Exporter] Validation failed:', validationErrors)
    return {
      ok: false,
      errors: validationErrors
    }
  }
  
  console.log('[Exporter] Validation passed')
  
  const result = await window.electron.exportConfig({
    profileName,
    content: JSON.stringify(config, null, 2)
  })
  
  console.log('[Exporter] Export result:', result)
  return result
}

/**
 * Validates the strategy config using all validation rules.
 * 
 * Validates:
 * - BlockIdReferenceRule: All condition.blockId references exist in blocks[]
 * - DuplicateBlockIdRule: All blockIds in blocks[] are unique
 * - BlockIdFormatRule: All blockIds follow {typeId}#{index} format
 * 
 * Requirements: 2.1, 2.4, 4.1
 */
const validateConfig = (config: StrategyConfig): ValidationError[] => {
  const rules = [
    new BlockIdReferenceRule(),
    new DuplicateBlockIdRule(),
    new BlockIdFormatRule()
  ]
  
  const errors: ValidationError[] = []
  
  for (const rule of rules) {
    const ruleErrors = rule.validate(config)
    errors.push(...ruleErrors)
  }
  
  return errors
}

/**
 * ビルダーの状態からストラテジー設定オブジェクトを生成する（ファイル保存なし）
 * バックテスト用に使用
 * 
 * @param profileName プロファイル名
 * @param nodes ノード配列
 * @param edges エッジ配列
 * @returns ストラテジー設定オブジェクト
 */
export const buildStrategyConfig = (profileName: string, nodes: Node[], edges: Edge[]) => {
  console.log('[Exporter] Building strategy config...', { profileName, nodeCount: nodes.length, edgeCount: edges.length })
  
  const config = buildConfig(nodes, edges, profileName)
  console.log('[Exporter] Config built:', JSON.stringify(config, null, 2))
  
  return config
}
