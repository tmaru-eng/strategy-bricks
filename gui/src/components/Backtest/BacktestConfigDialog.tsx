import React, { useState, useEffect } from 'react'
import type { BacktestConfig } from '../../types/backtest'

interface BacktestConfigDialogProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (config: BacktestConfig) => void
  lastConfig?: BacktestConfig
}

/**
 * バックテスト設定を検証する
 * 
 * @param config バックテスト設定
 * @returns エラーメッセージの配列（エラーがない場合は空配列）
 */
export function validateBacktestConfig(config: BacktestConfig): string[] {
  const errors: string[] = []
  
  if (!config.symbol || config.symbol.trim() === '') {
    errors.push('シンボルは必須です')
  }
  
  if (!config.timeframe) {
    errors.push('時間軸は必須です')
  }
  
  if (config.startDate >= config.endDate) {
    errors.push('開始日は終了日より前である必要があります')
  }
  
  if (config.endDate > new Date()) {
    errors.push('終了日は未来の日付にできません')
  }
  
  return errors
}

/**
 * デフォルトのバックテスト設定を生成する
 * 
 * @returns デフォルト設定（USDJPYm, M1, 過去7日間）
 */
function getDefaultConfig(): BacktestConfig {
  const endDate = new Date()
  // 過去7日間（データが確実に存在する範囲）
  const startDate = new Date(endDate.getTime() - (7 * 24 * 60 * 60 * 1000))
  
  console.log('[BacktestConfigDialog] Generated default config:', {
    symbol: 'USDJPYm',
    timeframe: 'M1',
    startDate: startDate.toISOString(),
    endDate: endDate.toISOString()
  })
  
  return {
    symbol: 'USDJPYm',
    timeframe: 'M1',
    startDate,
    endDate
  }
}

/**
 * ローカルストレージのキー
 */
const STORAGE_KEY = 'backtest-config'

/**
 * ローカルストレージから設定を読み込む
 */
function loadConfigFromStorage(): BacktestConfig | null {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    console.log('[BacktestConfigDialog] Loading config from storage:', stored)
    
    if (!stored) {
      console.log('[BacktestConfigDialog] No stored config found')
      return null
    }
    
    const parsed = JSON.parse(stored)
    
    // Date オブジェクトに変換
    const config = {
      ...parsed,
      startDate: new Date(parsed.startDate),
      endDate: new Date(parsed.endDate)
    }
    
    const now = new Date()
    
    // 検証: 終了日が未来の場合は無効な設定として扱う
    if (config.endDate > now) {
      console.log('[BacktestConfigDialog] Stored config has future end date, ignoring and clearing')
      localStorage.removeItem(STORAGE_KEY)
      return null
    }
    
    // 検証: 開始日が終了日より後の場合は無効な設定として扱う
    if (config.startDate >= config.endDate) {
      console.log('[BacktestConfigDialog] Stored config has invalid date range, ignoring and clearing')
      localStorage.removeItem(STORAGE_KEY)
      return null
    }
    
    // 検証: 設定が30日以上古い場合は無効として扱う（データが存在しない可能性が高い）
    const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000))
    if (config.endDate < thirtyDaysAgo) {
      console.log('[BacktestConfigDialog] Stored config is too old (>30 days), ignoring and clearing')
      localStorage.removeItem(STORAGE_KEY)
      return null
    }
    
    console.log('[BacktestConfigDialog] Loaded config from storage:', config)
    return config
  } catch (error) {
    console.error('[BacktestConfigDialog] Failed to load config from storage:', error)
    localStorage.removeItem(STORAGE_KEY)
    return null
  }
}

/**
 * ローカルストレージに設定を保存する
 */
function saveConfigToStorage(config: BacktestConfig): void {
  try {
    const serialized = JSON.stringify(config)
    localStorage.setItem(STORAGE_KEY, serialized)
    console.log('[BacktestConfigDialog] Saved config to storage:', serialized)
  } catch (error) {
    console.error('[BacktestConfigDialog] Failed to save config to storage:', error)
  }
}

/**
 * バックテスト設定ダイアログコンポーネント
 * 
 * ユーザーがバックテストパラメータ（シンボル、時間軸、日付範囲）を
 * 入力するためのダイアログを表示します。
 * 
 * 機能:
 * - デフォルト値の設定（USDJPY, M1, 過去3ヶ月）
 * - 入力値の検証
 * - ローカルストレージへの設定永続化
 */
export const BacktestConfigDialog: React.FC<BacktestConfigDialogProps> = ({
  isOpen,
  onClose,
  onSubmit,
  lastConfig
}) => {
  // 初期化ロジックを改善
  const getInitialConfig = (): BacktestConfig => {
    console.log('[BacktestConfigDialog] Initializing config')
    console.log('[BacktestConfigDialog] lastConfig:', lastConfig)
    
    if (lastConfig) {
      console.log('[BacktestConfigDialog] Using lastConfig')
      return lastConfig
    }
    
    const storedConfig = loadConfigFromStorage()
    if (storedConfig) {
      console.log('[BacktestConfigDialog] Using stored config')
      return storedConfig
    }
    
    console.log('[BacktestConfigDialog] Using default config')
    return getDefaultConfig()
  }
  
  const initialConfig = getInitialConfig()
  
  const [symbol, setSymbol] = useState(initialConfig.symbol)
  const [timeframe, setTimeframe] = useState(initialConfig.timeframe)
  const [startDate, setStartDate] = useState(
    initialConfig.startDate.toISOString().split('T')[0]
  )
  const [endDate, setEndDate] = useState(
    initialConfig.endDate.toISOString().split('T')[0]
  )
  const [errors, setErrors] = useState<string[]>([])
  
  // ダイアログが開かれるたびに初期化
  useEffect(() => {
    if (isOpen) {
      console.log('[BacktestConfigDialog] Dialog opened, reinitializing')
      const config = getInitialConfig()
      setSymbol(config.symbol)
      setTimeframe(config.timeframe)
      setStartDate(config.startDate.toISOString().split('T')[0])
      setEndDate(config.endDate.toISOString().split('T')[0])
      setErrors([])
    }
  }, [isOpen])
  
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    const config: BacktestConfig = {
      symbol: symbol.trim(),
      timeframe,
      startDate: new Date(startDate),
      endDate: new Date(endDate)
    }
    
    console.log('[BacktestConfigDialog] Submitting config:', config)
    
    // 検証
    const validationErrors = validateBacktestConfig(config)
    if (validationErrors.length > 0) {
      console.log('[BacktestConfigDialog] Validation errors:', validationErrors)
      setErrors(validationErrors)
      return
    }
    
    // ローカルストレージに保存
    saveConfigToStorage(config)
    
    // エラーをクリア
    setErrors([])
    
    // 親コンポーネントに通知
    onSubmit(config)
  }
  
  const handleCancel = () => {
    setErrors([])
    onClose()
  }
  
  if (!isOpen) return null
  
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
        <h2 className="text-xl font-bold mb-4">バックテスト設定</h2>
        
        {/* エラー表示 */}
        {errors.length > 0 && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 rounded">
            <ul className="list-disc list-inside text-red-700 text-sm">
              {errors.map((error, index) => (
                <li key={index}>{error}</li>
              ))}
            </ul>
          </div>
        )}
        
        <form onSubmit={handleSubmit}>
          {/* シンボル */}
          <div className="mb-4">
            <label htmlFor="symbol" className="block text-sm font-medium mb-1">
              シンボル
            </label>
            <input
              id="symbol"
              type="text"
              value={symbol}
              onChange={(e) => setSymbol(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="USDJPYm"
            />
          </div>
          
          {/* 時間軸 */}
          <div className="mb-4">
            <label htmlFor="timeframe" className="block text-sm font-medium mb-1">
              時間軸
            </label>
            <select
              id="timeframe"
              value={timeframe}
              onChange={(e) => setTimeframe(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="M1">M1 (1分)</option>
              <option value="M5">M5 (5分)</option>
              <option value="M15">M15 (15分)</option>
              <option value="M30">M30 (30分)</option>
              <option value="H1">H1 (1時間)</option>
              <option value="H4">H4 (4時間)</option>
              <option value="D1">D1 (日足)</option>
            </select>
          </div>
          
          {/* 開始日 */}
          <div className="mb-4">
            <label htmlFor="startDate" className="block text-sm font-medium mb-1">
              開始日
            </label>
            <input
              id="startDate"
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          {/* 終了日 */}
          <div className="mb-4">
            <label htmlFor="endDate" className="block text-sm font-medium mb-1">
              終了日
            </label>
            <input
              id="endDate"
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          {/* ボタン */}
          <div className="flex justify-end gap-2 mt-6">
            <button
              type="button"
              onClick={handleCancel}
              className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-100"
            >
              キャンセル
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              実行
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
