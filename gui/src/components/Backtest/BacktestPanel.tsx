import React, { useState, useEffect } from 'react'
import {
  BacktestConfigDialog,
  BacktestProgressIndicator,
  BacktestResultsView
} from './index'
import type { BacktestConfig, BacktestResults } from '../../types/backtest'
import { useStateManager } from '../../store/useStateManager'

/**
 * 環境チェック結果の型定義
 */
interface EnvironmentCheckResult {
  isWindows: boolean
  backtestEnabled: boolean
  message?: string
  debug?: {
    enginePath: string | null
    engineExists: boolean
    checkedPaths: string[]
  }
}

/**
 * バックテストパネルコンポーネント
 * 
 * プラットフォーム固有のUI状態を管理し、環境に応じてバックテスト機能を
 * 有効化/無効化します。
 * 
 * 機能:
 * - 環境チェック（OS、Python、MT5ライブラリ）
 * - Windows + MT5利用可能: バックテスト機能を有効化
 * - 非Windows: 機能を無効化し、プラットフォームメッセージを表示
 * - MT5未インストール: インストール手順を表示
 * 
 * 要件: 9.2, 9.3, 9.4
 */
export const BacktestPanel: React.FC = () => {
  // 環境チェック状態
  const [envCheck, setEnvCheck] = useState<EnvironmentCheckResult | null>(null)
  const [isCheckingEnv, setIsCheckingEnv] = useState(true)
  
  // バックテスト状態
  const [isConfigDialogOpen, setIsConfigDialogOpen] = useState(false)
  const [isRunning, setIsRunning] = useState(false)
  const [elapsedTime, setElapsedTime] = useState(0)
  const [results, setResults] = useState<BacktestResults | null>(null)
  const [error, setError] = useState<string | null>(null)
  
  // 環境チェックを実行
  useEffect(() => {
    const checkEnvironment = async () => {
      console.log('[BacktestPanel] Checking environment')
      setIsCheckingEnv(true)
      
      if (!window.backtestAPI) {
        setEnvCheck({
          isWindows: false,
          backtestEnabled: false,
          message: 'Backtest APIが利用できません。'
        })
        setIsCheckingEnv(false)
        return
      }
      
      try {
        const result = await window.backtestAPI.checkEnvironment()
        console.log('[BacktestPanel] Environment check result:', result)
        setEnvCheck(result)
      } catch (err) {
        console.error('[BacktestPanel] Environment check failed:', err)
        setEnvCheck({
          isWindows: false,
          backtestEnabled: false,
          message: '環境チェックに失敗しました。'
        })
      } finally {
        setIsCheckingEnv(false)
      }
    }
    
    checkEnvironment()
  }, [])
  
  // 経過時間タイマー
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null
    
    if (isRunning) {
      interval = setInterval(() => {
        setElapsedTime(prev => prev + 1)
      }, 1000)
    } else {
      setElapsedTime(0)
    }
    
    return () => {
      if (interval) {
        clearInterval(interval)
      }
    }
  }, [isRunning])
  
  // IPCイベントリスナーを登録
  useEffect(() => {
    if (!window.backtestAPI) {
      return
    }
    
    // バックテスト完了イベント
    window.backtestAPI.onBacktestComplete((backtestResults) => {
      console.log('[BacktestPanel] Backtest completed:', backtestResults)
      setIsRunning(false)
      setResults(backtestResults)
      setError(null)
    })
    
    // バックテストエラーイベント
    window.backtestAPI.onBacktestError((backtestError) => {
      console.error('[BacktestPanel] Backtest error:', backtestError)
      setIsRunning(false)
      // backtestError can be either a BacktestError object or a string
      const errorMessage = typeof backtestError === 'string' 
        ? backtestError 
        : (backtestError.message || 'バックテストでエラーが発生しました。')
      setError(errorMessage)
      setResults(null)
    })
  }, [])
  
  /**
   * バックテスト開始ハンドラー
   */
  const handleStartBacktest = async (config: BacktestConfig) => {
    if (!window.backtestAPI) {
      setError('Backtest APIが利用できません。')
      return
    }
    
    if (!window.electron?.saveStrategyConfig) {
      setError('Strategy config save APIが利用できません。')
      return
    }
    
    try {
      // ストラテジー設定をエクスポート
      console.log('[BacktestPanel] Exporting strategy config for backtest')
      
      // ビルダーの状態を取得
      const { nodes, edges } = useStateManager.getState()
      
      // ビルダーが空かどうかをチェック（ストラテジーノードとルールグループノードのみの場合は空とみなす）
      const hasConditions = nodes.some(node => node.type === 'conditionNode')
      
      let strategyConfig
      
      if (!hasConditions) {
        // ビルダーが空の場合はデフォルト設定を使用
        console.log('[BacktestPanel] Builder is empty, using default strategy config')
        strategyConfig = {
          meta: {
            formatVersion: '1.0',
            name: 'デフォルトストラテジー',
            generatedBy: 'GUI Builder (Default)',
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
          strategies: [
            {
              id: 'S1',
              name: 'デフォルトストラテジー',
              enabled: true,
              priority: 10,
              conflictPolicy: 'firstOnly',
              directionPolicy: 'both',
              entryRequirement: {
                type: 'OR',
                ruleGroups: [
                  {
                    id: 'rulegroup-1',
                    type: 'AND',
                    conditions: [
                      { blockId: 'filter.spreadMax#1' },
                      { blockId: 'trend.maRelation#1' }
                    ]
                  }
                ]
              },
              lotModel: { type: 'lot.fixed', params: { lots: 0.1 } },
              riskModel: { type: 'risk.fixedSLTP', params: { slPips: 30, tpPips: 30 } },
              exitModel: { type: 'exit.none', params: {} },
              nanpinModel: { type: 'nanpin.off', params: {} }
            }
          ],
          blocks: [
            {
              id: 'filter.spreadMax#1',
              typeId: 'filter.spreadMax',
              params: { maxSpreadPips: 30 }
            },
            {
              id: 'trend.maRelation#1',
              typeId: 'trend.maRelation',
              params: {
                period: 20,
                maMethod: 'SMA',
                appliedPrice: 'CLOSE',
                relation: 'above'
              }
            }
          ]
        }
      } else {
        // ビルダーの設定を使用
        console.log('[BacktestPanel] Using builder strategy config')
        const { buildStrategyConfig } = await import('../../services/Exporter')
        strategyConfig = buildStrategyConfig('Backtest Strategy', nodes, edges)
      }
      
      // ストラテジー設定を保存
      const timestamp = Date.now()
      const filename = `strategy_${timestamp}.json`
      const saveResult = await window.electron.saveStrategyConfig({
        filename,
        content: JSON.stringify(strategyConfig, null, 2)
      })
      
      if (!saveResult.success) {
        throw new Error(saveResult.error || 'ストラテジー設定の保存に失敗しました')
      }
      
      console.log('[BacktestPanel] Strategy config saved:', saveResult.path)
      
      // バックテスト開始
      setIsRunning(true)
      setError(null)
      setResults(null)
      setIsConfigDialogOpen(false)
      
      console.log('[BacktestPanel] Starting backtest with config:', config)
      await window.backtestAPI.startBacktest(config, saveResult.path!)
    } catch (err) {
      console.error('[BacktestPanel] Failed to start backtest:', err)
      setIsRunning(false)
      setError(err instanceof Error ? err.message : 'バックテストの開始に失敗しました。')
    }
  }
  
  /**
   * バックテストキャンセルハンドラー
   */
  const handleCancelBacktest = async () => {
    if (!window.backtestAPI) {
      return
    }
    
    try {
      console.log('[BacktestPanel] Canceling backtest')
      await window.backtestAPI.cancelBacktest()
      setIsRunning(false)
      setError('バックテストがキャンセルされました。')
    } catch (err) {
      console.error('[BacktestPanel] Failed to cancel backtest:', err)
    }
  }
  
  // 環境チェック中
  if (isCheckingEnv) {
    return (
      <div className="p-6 bg-white rounded-lg shadow">
        <div className="flex items-center justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mr-3"></div>
          <span className="text-gray-600">環境をチェック中...</span>
        </div>
      </div>
    )
  }
  
  // 環境チェック失敗またはバックテスト無効
  if (!envCheck || !envCheck.backtestEnabled) {
    return (
      <div className="p-6 bg-white rounded-lg shadow">
        <h2 className="text-xl font-bold mb-4">バックテスト機能</h2>
        
        {/* プラットフォームメッセージ */}
        <div className={`p-4 rounded border ${
          envCheck?.isWindows 
            ? 'bg-yellow-50 border-yellow-400' 
            : 'bg-blue-50 border-blue-400'
        }`}>
          <div className="flex items-start">
            <div className="flex-shrink-0">
              {envCheck?.isWindows ? (
                // Windows だがエンジン未ビルド
                <svg className="h-6 w-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              ) : (
                // 非 Windows
                <svg className="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              )}
            </div>
            <div className="ml-3 flex-1">
              <h3 className={`text-sm font-medium ${
                envCheck?.isWindows ? 'text-yellow-800' : 'text-blue-800'
              }`}>
                {envCheck?.isWindows ? 'セットアップが必要です' : 'プラットフォーム制限'}
              </h3>
              <div className={`mt-2 text-sm ${
                envCheck?.isWindows ? 'text-yellow-700' : 'text-blue-700'
              }`}>
                <p className="whitespace-pre-line">{envCheck?.message || 'バックテスト機能が利用できません。'}</p>
              </div>
              
              {/* デバッグ情報 */}
              {envCheck?.debug && (
                <details className="mt-4">
                  <summary className="text-xs text-gray-600 cursor-pointer hover:text-gray-800">
                    詳細情報
                  </summary>
                  <div className="mt-2 text-xs text-gray-600 space-y-1 bg-gray-50 p-2 rounded">
                    <div className="flex items-center">
                      <span className="font-medium w-32">OS:</span>
                      <span className={envCheck.isWindows ? 'text-green-600' : 'text-red-600'}>
                        {envCheck.isWindows ? '✓ Windows' : '✗ Windows以外'}
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span className="font-medium w-32">エンジンパス:</span>
                      <span className={envCheck.debug.engineExists ? 'text-green-600' : 'text-red-600'}>
                        {envCheck.debug.enginePath || 'なし'}
                      </span>
                    </div>
                    <div className="flex items-center">
                      <span className="font-medium w-32">エンジン存在:</span>
                      <span className={envCheck.debug.engineExists ? 'text-green-600' : 'text-red-600'}>
                        {envCheck.debug.engineExists ? '✓ あり' : '✗ なし'}
                      </span>
                    </div>
                    <div className="mt-2">
                      <span className="font-medium">チェックしたパス:</span>
                      <ul className="list-disc list-inside ml-4 mt-1">
                        {envCheck.debug.checkedPaths.map((path, idx) => (
                          <li key={idx} className="text-gray-500">{path}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </details>
              )}
            </div>
          </div>
        </div>
        
        {/* 再チェックボタン */}
        <div className="mt-4 flex justify-end">
          <button
            onClick={() => {
              setIsCheckingEnv(true)
              window.location.reload()
            }}
            className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
          >
            環境を再チェック
          </button>
        </div>
      </div>
    )
  }
  
  // バックテスト機能が有効
  return (
    <div className="space-y-6">
      {/* ヘッダー */}
      <div className="p-6 bg-white rounded-lg shadow">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold">バックテスト機能</h2>
            <p className="text-sm text-gray-600 mt-1">
              ストラテジーを過去データでテストします
            </p>
          </div>
          <button
            onClick={() => setIsConfigDialogOpen(true)}
            disabled={isRunning}
            className={`px-6 py-3 rounded font-semibold transition-colors ${
              isRunning
                ? 'bg-gray-400 text-white cursor-not-allowed'
                : 'bg-blue-600 text-white hover:bg-blue-700'
            }`}
          >
            バックテスト実行
          </button>
        </div>
        
        {/* 環境ステータス */}
        <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded">
          <div className="flex items-center text-sm text-green-800">
            <svg className="h-5 w-5 text-green-600 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="font-medium">バックテスト機能が利用可能です</span>
          </div>
        </div>
      </div>
      
      {/* 設定ダイアログ */}
      <BacktestConfigDialog
        isOpen={isConfigDialogOpen}
        onClose={() => setIsConfigDialogOpen(false)}
        onSubmit={handleStartBacktest}
      />
      
      {/* 進捗インジケーター */}
      <BacktestProgressIndicator
        isRunning={isRunning}
        elapsedTime={elapsedTime}
        onCancel={handleCancelBacktest}
      />
      
      {/* 結果表示 */}
      {(results || error) && (
        <BacktestResultsView
          results={results}
          error={error}
        />
      )}
    </div>
  )
}
