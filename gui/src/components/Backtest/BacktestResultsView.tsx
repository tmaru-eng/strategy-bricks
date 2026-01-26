import React from 'react'
import type { BacktestResults } from '../../types/backtest'

interface BacktestResultsViewProps {
  /** バックテスト結果（null の場合は結果なし） */
  results: BacktestResults | null
  
  /** エラーメッセージ（null の場合はエラーなし） */
  error: string | null
  
  /** エクスポートボタンのクリックハンドラー（オプション） */
  onExport?: () => void
}

/**
 * 数値を指定された小数点以下桁数でフォーマットする
 * 
 * @param value 数値
 * @param decimals 小数点以下の桁数
 * @returns フォーマットされた文字列
 */
function formatNumber(value: number, decimals: number = 2): string {
  return value.toFixed(decimals)
}

/**
 * ISO形式の日時文字列を読みやすい形式にフォーマットする
 * 
 * @param isoString ISO形式の日時文字列
 * @returns フォーマットされた日時文字列
 */
function formatDateTime(isoString: string): string {
  try {
    const date = new Date(isoString)
    return date.toLocaleString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  } catch (error) {
    return isoString
  }
}

/**
 * 損益の値に応じて色クラスを返す
 * 
 * @param profitLoss 損益
 * @returns Tailwind CSSの色クラス
 */
function getProfitLossColorClass(profitLoss: number): string {
  if (profitLoss > 0) return 'text-green-600'
  if (profitLoss < 0) return 'text-red-600'
  return 'text-gray-600'
}

/**
 * バックテスト結果表示コンポーネント
 * 
 * バックテスト実行後の結果を表示します。
 * 
 * 機能:
 * - 結果JSONの解析と表示
 * - パフォーマンス指標の表示（総トレード数、勝率、総損益、最大ドローダウン）
 * - トレードリストの表示（タイムスタンプ、価格、損益）
 * - エラーメッセージの表示
 * - 結果のエクスポート機能（ファイル保存ダイアログ付き）
 * 
 * 要件: 7.1, 7.2, 7.3, 7.4, 7.5
 */
export const BacktestResultsView: React.FC<BacktestResultsViewProps> = ({
  results,
  error,
  onExport
}) => {
  const [isExporting, setIsExporting] = React.useState(false)
  const [exportError, setExportError] = React.useState<string | null>(null)
  const [exportSuccess, setExportSuccess] = React.useState(false)
  
  /**
   * エクスポートボタンのクリックハンドラー
   * 
   * カスタムハンドラーが提供されている場合はそれを使用し、
   * そうでない場合はデフォルトのエクスポート処理を実行します。
   */
  const handleExport = async () => {
    // カスタムハンドラーが提供されている場合はそれを使用
    if (onExport) {
      onExport()
      return
    }
    
    // デフォルトのエクスポート処理
    if (!results || !window.backtestAPI) {
      return
    }
    
    setIsExporting(true)
    setExportError(null)
    setExportSuccess(false)
    
    try {
      // outputPathを省略してファイル保存ダイアログを表示
      const result = await window.backtestAPI.exportResults(results)
      
      if (result.canceled) {
        console.log('[BacktestResultsView] Export canceled by user')
      } else if (result.success) {
        console.log('[BacktestResultsView] Export successful:', result.path)
        setExportSuccess(true)
        
        // 3秒後に成功メッセージを非表示
        setTimeout(() => setExportSuccess(false), 3000)
      }
    } catch (error) {
      console.error('[BacktestResultsView] Export failed:', error)
      setExportError(error instanceof Error ? error.message : 'エクスポートに失敗しました')
    } finally {
      setIsExporting(false)
    }
  }
  
  // エラーがある場合はエラーメッセージを表示
  if (error) {
    return (
      <div className="p-6 bg-white rounded-lg shadow">
        <h2 className="text-xl font-bold mb-4 text-red-600">バックテストエラー</h2>
        <div className="p-4 bg-red-100 border border-red-400 rounded">
          <p className="text-red-700">{error}</p>
        </div>
      </div>
    )
  }
  
  // 結果がない場合は何も表示しない
  if (!results) {
    return null
  }
  
  const { metadata, summary, trades } = results
  
  return (
    <div className="p-6 bg-white rounded-lg shadow">
      {/* ヘッダー */}
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">バックテスト結果</h2>
        <div className="flex items-center gap-3">
          {/* エクスポート成功メッセージ */}
          {exportSuccess && (
            <span className="text-sm text-green-600 font-medium">
              ✓ エクスポート完了
            </span>
          )}
          
          {/* エクスポートエラーメッセージ */}
          {exportError && (
            <span className="text-sm text-red-600 font-medium">
              ✗ {exportError}
            </span>
          )}
          
          {/* エクスポートボタン */}
          <button
            onClick={handleExport}
            disabled={isExporting}
            className={`px-4 py-2 rounded transition-colors ${
              isExporting
                ? 'bg-gray-400 text-white cursor-not-allowed'
                : 'bg-blue-600 text-white hover:bg-blue-700'
            }`}
          >
            {isExporting ? 'エクスポート中...' : '結果をエクスポート'}
          </button>
        </div>
      </div>
      
      {/* メタデータ */}
      <div className="mb-6 p-4 bg-gray-50 rounded">
        <h3 className="text-lg font-semibold mb-2">基本情報</h3>
        <div className="grid grid-cols-2 gap-2 text-sm">
          <div>
            <span className="font-medium">ストラテジー名:</span>{' '}
            <span>{metadata.strategyName}</span>
          </div>
          <div>
            <span className="font-medium">シンボル:</span>{' '}
            <span>{metadata.symbol}</span>
          </div>
          <div>
            <span className="font-medium">時間軸:</span>{' '}
            <span>{metadata.timeframe}</span>
          </div>
          <div>
            <span className="font-medium">実行日時:</span>{' '}
            <span>{formatDateTime(metadata.executionTimestamp)}</span>
          </div>
          <div>
            <span className="font-medium">開始日:</span>{' '}
            <span>{formatDateTime(metadata.startDate)}</span>
          </div>
          <div>
            <span className="font-medium">終了日:</span>{' '}
            <span>{formatDateTime(metadata.endDate)}</span>
          </div>
        </div>
      </div>
      
      {/* パフォーマンス指標 */}
      <div className="mb-6">
        <h3 className="text-lg font-semibold mb-3">パフォーマンス指標</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* 総トレード数 */}
          <div className="p-4 bg-blue-50 rounded border border-blue-200">
            <div className="text-sm text-gray-600 mb-1">総トレード数</div>
            <div className="text-2xl font-bold text-blue-600">
              {summary.totalTrades}
            </div>
          </div>
          
          {/* 勝率 */}
          <div className="p-4 bg-green-50 rounded border border-green-200">
            <div className="text-sm text-gray-600 mb-1">勝率</div>
            <div className="text-2xl font-bold text-green-600">
              {formatNumber(summary.winRate, 2)}%
            </div>
            <div className="text-xs text-gray-500 mt-1">
              勝ち: {summary.winningTrades} / 負け: {summary.losingTrades}
            </div>
          </div>
          
          {/* 総損益 */}
          <div className={`p-4 rounded border ${
            summary.totalProfitLoss >= 0 
              ? 'bg-green-50 border-green-200' 
              : 'bg-red-50 border-red-200'
          }`}>
            <div className="text-sm text-gray-600 mb-1">総損益</div>
            <div className={`text-2xl font-bold ${getProfitLossColorClass(summary.totalProfitLoss)}`}>
              {summary.totalProfitLoss >= 0 ? '+' : ''}{formatNumber(summary.totalProfitLoss, 5)}
            </div>
          </div>
          
          {/* 最大ドローダウン */}
          <div className="p-4 bg-red-50 rounded border border-red-200">
            <div className="text-sm text-gray-600 mb-1">最大ドローダウン</div>
            <div className="text-2xl font-bold text-red-600">
              {formatNumber(summary.maxDrawdown, 5)}
            </div>
          </div>
          
          {/* 平均トレード損益 */}
          <div className="p-4 bg-gray-50 rounded border border-gray-200 md:col-span-2">
            <div className="text-sm text-gray-600 mb-1">平均トレード損益</div>
            <div className={`text-2xl font-bold ${getProfitLossColorClass(summary.avgTradeProfitLoss)}`}>
              {summary.avgTradeProfitLoss >= 0 ? '+' : ''}{formatNumber(summary.avgTradeProfitLoss, 5)}
            </div>
          </div>
        </div>
      </div>
      
      {/* トレードリスト */}
      <div>
        <h3 className="text-lg font-semibold mb-3">トレード履歴</h3>
        
        {trades.length === 0 ? (
          <div className="p-4 bg-gray-50 rounded text-center text-gray-500">
            トレードが記録されていません
          </div>
        ) : (
          <div className="overflow-x-auto">
            <div className="max-h-96 overflow-y-auto border border-gray-200 rounded">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50 sticky top-0">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      #
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      タイプ
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      エントリー時刻
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      エントリー価格
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      エグジット時刻
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      エグジット価格
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      ロット
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      損益
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {trades.map((trade, index) => (
                    <tr key={index} className="hover:bg-gray-50">
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                        {index + 1}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm">
                        <span className={`px-2 py-1 rounded text-xs font-semibold ${
                          trade.type === 'BUY' 
                            ? 'bg-blue-100 text-blue-800' 
                            : 'bg-orange-100 text-orange-800'
                        }`}>
                          {trade.type}
                        </span>
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                        {formatDateTime(trade.entryTime)}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                        {formatNumber(trade.entryPrice, 5)}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                        {formatDateTime(trade.exitTime)}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                        {formatNumber(trade.exitPrice, 5)}
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                        {formatNumber(trade.positionSize, 2)}
                      </td>
                      <td className={`px-4 py-3 whitespace-nowrap text-sm font-semibold ${
                        getProfitLossColorClass(trade.profitLoss)
                      }`}>
                        {trade.profitLoss >= 0 ? '+' : ''}{formatNumber(trade.profitLoss, 5)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
