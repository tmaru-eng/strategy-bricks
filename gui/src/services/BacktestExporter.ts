/**
 * バックテスト用ストラテジー設定エクスポートサービス
 * 
 * このサービスは、現在のストラテジー設定をJSONファイルにエクスポートし、
 * Pythonバックテストエンジンで使用できるようにします。
 * 
 * 要件: 2.1, 2.2, 2.4
 */

import type { Node, Edge } from 'reactflow'
import {
  BlockIdReferenceRule,
  DuplicateBlockIdRule,
  BlockIdFormatRule,
  type ValidationError,
  type StrategyConfig
} from './Validator'

/**
 * ストラテジー設定エクスポート結果
 */
export interface StrategyExportResult {
  /** エクスポート成功フラグ */
  success: boolean
  
  /** エクスポートされたファイルのパス */
  filePath?: string
  
  /** 検証エラー（ある場合） */
  validationErrors?: ValidationError[]
  
  /** エラーメッセージ（ある場合） */
  errorMessage?: string
}

/**
 * ブロック配列を構築
 */
const buildBlocks = (nodes: Node[]) => {
  const conditionNodes = nodes.filter((node) => node.type === 'conditionNode')
  return conditionNodes.map((node) => ({
    id: node.data?.blockId || '',
    typeId: node.data?.blockTypeId || 'unknown',
    params: node.data?.params || {}
  }))
}

/**
 * ストラテジー配列を構築
 */
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

/**
 * ストラテジー設定オブジェクトを構築
 */
const buildConfig = (nodes: Node[], edges: Edge[], strategyName: string): StrategyConfig => {
  return {
    meta: {
      formatVersion: '1.0',
      name: strategyName,
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
        weekDays: { 
          sun: false, 
          mon: true, 
          tue: true, 
          wed: true, 
          thu: true, 
          fri: true, 
          sat: false 
        }
      }
    },
    strategies: buildStrategies(nodes, edges),
    blocks: buildBlocks(nodes)
  }
}

/**
 * ストラテジー設定を検証
 * 
 * @param config ストラテジー設定
 * @returns 検証エラーの配列
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
 * 必須フィールドの検証
 * 
 * ストラテジー設定が必須フィールド（strategyName, blocks）を
 * 含んでいることを確認します。
 * 
 * @param config ストラテジー設定
 * @returns エラーメッセージの配列
 */
const validateRequiredFields = (config: StrategyConfig): string[] => {
  const errors: string[] = []
  
  if (!config.meta?.name || config.meta.name.trim() === '') {
    errors.push('ストラテジー名は必須です')
  }
  
  if (!config.strategies || config.strategies.length === 0) {
    errors.push('少なくとも1つのストラテジーが必要です')
  }
  
  if (!config.blocks || config.blocks.length === 0) {
    errors.push('少なくとも1つのブロックが必要です')
  }
  
  return errors
}

/**
 * 一意のファイル名を生成
 * 
 * フォーマット: strategy_<timestamp>.json
 * 
 * @returns ファイル名
 */
const generateUniqueFilename = (): string => {
  const timestamp = Date.now()
  return `strategy_${timestamp}.json`
}

/**
 * 現在のストラテジー設定をバックテスト用にエクスポート
 * 
 * この関数は以下を実行します：
 * 1. 現在のノードとエッジからストラテジー設定を構築
 * 2. 設定を検証（必須フィールド、ブロック参照、重複ID、ID形式）
 * 3. 一意のファイル名を生成（strategy_<timestamp>.json）
 * 4. ea/tests/ ディレクトリに保存
 * 5. ファイルパスを返す
 * 
 * @param nodes ReactFlowノード配列
 * @param edges ReactFlowエッジ配列
 * @param strategyName ストラテジー名（オプション、デフォルト: "Backtest Strategy"）
 * @returns エクスポート結果
 * 
 * 要件: 2.1, 2.2, 2.4
 */
export const exportStrategyForBacktest = async (
  nodes: Node[],
  edges: Edge[],
  strategyName: string = 'Backtest Strategy'
): Promise<StrategyExportResult> => {
  console.log('[BacktestExporter] Starting export...', { 
    nodeCount: nodes.length, 
    edgeCount: edges.length,
    strategyName
  })
  
  try {
    // 1. ストラテジー設定を構築
    const config = buildConfig(nodes, edges, strategyName)
    console.log('[BacktestExporter] Config built:', JSON.stringify(config, null, 2))
    
    // 2. 必須フィールドを検証
    const requiredFieldErrors = validateRequiredFields(config)
    if (requiredFieldErrors.length > 0) {
      console.error('[BacktestExporter] Required field validation failed:', requiredFieldErrors)
      return {
        success: false,
        errorMessage: requiredFieldErrors.join(', ')
      }
    }
    
    // 3. 設定を検証
    const validationErrors = validateConfig(config)
    if (validationErrors.length > 0) {
      console.error('[BacktestExporter] Validation failed:', validationErrors)
      return {
        success: false,
        validationErrors
      }
    }
    
    console.log('[BacktestExporter] Validation passed')
    
    // 4. 一意のファイル名を生成
    const filename = generateUniqueFilename()
    console.log('[BacktestExporter] Generated filename:', filename)
    
    // 5. Electronブリッジを使用してファイルを保存
    if (!window.electron?.saveStrategyConfig) {
      throw new Error('Electron bridge is not available')
    }
    
    const result = await window.electron.saveStrategyConfig({
      filename,
      content: JSON.stringify(config, null, 2)
    })
    
    if (!result.success) {
      throw new Error(result.error || 'Failed to save strategy config')
    }
    
    console.log('[BacktestExporter] Export successful:', result.path)
    
    return {
      success: true,
      filePath: result.path
    }
    
  } catch (error) {
    console.error('[BacktestExporter] Export failed:', error)
    return {
      success: false,
      errorMessage: error instanceof Error ? error.message : 'Unknown error occurred'
    }
  }
}
