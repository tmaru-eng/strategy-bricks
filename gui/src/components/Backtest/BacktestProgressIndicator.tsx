import React, { useEffect, useState } from 'react'

interface BacktestProgressIndicatorProps {
  /** バックテストが実行中かどうか */
  isRunning: boolean
  
  /** 経過時間（秒） */
  elapsedTime: number
  
  /** キャンセルボタンのクリックハンドラー */
  onCancel: () => void
}

/**
 * 秒数を "MM:SS" 形式にフォーマットする
 * 
 * @param seconds 秒数
 * @returns フォーマットされた時間文字列
 */
function formatElapsedTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`
}

/**
 * バックテスト進捗インジケーターコンポーネント
 * 
 * バックテスト実行中の進捗を表示します。
 * 
 * 機能:
 * - 進捗インジケーターの表示/非表示
 * - 経過時間の表示
 * - キャンセルボタン
 * 
 * 要件: 8.1, 8.2, 8.5
 */
export const BacktestProgressIndicator: React.FC<BacktestProgressIndicatorProps> = ({
  isRunning,
  elapsedTime,
  onCancel
}) => {
  const [isCanceling, setIsCanceling] = useState(false)
  
  // コンポーネントがアンマウントされたときにキャンセル状態をリセット
  useEffect(() => {
    if (!isRunning) {
      setIsCanceling(false)
    }
  }, [isRunning])
  
  /**
   * キャンセルボタンのクリックハンドラー
   */
  const handleCancel = () => {
    setIsCanceling(true)
    onCancel()
  }
  
  // 実行中でない場合は何も表示しない
  if (!isRunning) {
    return null
  }
  
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
        {/* ヘッダー */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold">バックテスト実行中</h2>
          {/* スピナーアイコン */}
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        </div>
        
        {/* 進捗メッセージ */}
        <div className="mb-6">
          <p className="text-gray-600 mb-2">
            バックテストを実行しています。しばらくお待ちください...
          </p>
          
          {/* 経過時間 */}
          <div className="flex items-center justify-between p-3 bg-blue-50 rounded border border-blue-200">
            <span className="text-sm font-medium text-gray-700">経過時間:</span>
            <span className="text-lg font-mono font-bold text-blue-600">
              {formatElapsedTime(elapsedTime)}
            </span>
          </div>
        </div>
        
        {/* プログレスバー（インデターミネート） */}
        <div className="mb-6">
          <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
            <div className="h-full bg-blue-600 rounded-full animate-progress"></div>
          </div>
        </div>
        
        {/* キャンセルボタン */}
        <div className="flex justify-end">
          <button
            onClick={handleCancel}
            disabled={isCanceling}
            className={`px-4 py-2 rounded transition-colors ${
              isCanceling
                ? 'bg-gray-400 text-white cursor-not-allowed'
                : 'bg-red-600 text-white hover:bg-red-700'
            }`}
          >
            {isCanceling ? 'キャンセル中...' : 'キャンセル'}
          </button>
        </div>
        
        {/* キャンセル中のメッセージ */}
        {isCanceling && (
          <div className="mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded">
            <p className="text-sm text-yellow-800">
              バックテストをキャンセルしています...
            </p>
          </div>
        )}
      </div>
      
      {/* カスタムアニメーション用のスタイル */}
      <style>{`
        @keyframes progress {
          0% {
            transform: translateX(-100%);
          }
          100% {
            transform: translateX(400%);
          }
        }
        
        .animate-progress {
          width: 25%;
          animation: progress 1.5s ease-in-out infinite;
        }
      `}</style>
    </div>
  )
}
