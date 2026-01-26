import React, { useState } from 'react'
import type { Node } from 'reactflow'
import { Palette } from './components/Palette/Palette'
import { Canvas } from './components/Canvas/Canvas'
import { PropertyPanel } from './components/Property/PropertyPanel'
import { ValidationPanel } from './components/Validator/ValidationPanel'
import { ValidationErrorDisplay } from './components/Validator/ValidationErrorDisplay'
import { BacktestPanel } from './components/Backtest/BacktestPanel'
import { useStateManager } from './store/useStateManager'
import type { ValidationError } from './services/Validator'

const App: React.FC = () => {
  const { runValidation, exportCurrentConfig, updateNodes, updateEdges, nodes, edges } = useStateManager()
  const [exportErrors, setExportErrors] = useState<ValidationError[]>([])
  const [activeTab, setActiveTab] = useState<'builder' | 'backtest'>('builder')

  const handleNew = () => {
    if (nodes.length > 0 || edges.length > 0) {
      const confirmed = window.confirm('現在の設定をクリアしますか？保存していない変更は失われます。')
      if (!confirmed) return
    }
    
    // Reset to initial state with default nodes (single strategy node)
    const initialNodes: Node[] = [
      {
        id: 'strategy-1',
        type: 'strategyNode',
        position: { x: 50, y: 200 },
        data: {}
      }
    ]
    updateNodes(initialNodes)
    updateEdges([])
    setExportErrors([])
    console.log('[App] New configuration created')
  }

  const handleOpen = async () => {
    try {
      const result = await window.electron?.dialog?.showOpenDialog({
        title: '設定ファイルを開く',
        filters: [
          { name: 'JSON Files', extensions: ['json'] },
          { name: 'All Files', extensions: ['*'] }
        ],
        properties: ['openFile']
      })

      if (result?.canceled || !result?.filePaths?.[0]) {
        console.log('[App] Open dialog canceled')
        return
      }

      const filePath = result.filePaths[0]
      console.log('[App] Opening file:', filePath)

      const content = await window.electron?.fs?.readFile(filePath)
      if (!content) {
        window.alert('ファイルの読み込みに失敗しました')
        return
      }

      const config = JSON.parse(content)
      
      // TODO: Convert config to nodes/edges format
      // For now, just show a message
      window.alert('設定ファイルの読み込み機能は実装中です')
      console.log('[App] Loaded config:', config)
    } catch (error) {
      console.error('[App] Failed to open file:', error)
      window.alert(`ファイルを開けませんでした: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  const handleSave = async () => {
    try {
      const result = await window.electron?.dialog?.showSaveDialog({
        title: '設定ファイルを保存',
        defaultPath: 'strategy.json',
        filters: [
          { name: 'JSON Files', extensions: ['json'] },
          { name: 'All Files', extensions: ['*'] }
        ]
      })

      if (result?.canceled || !result?.filePath) {
        console.log('[App] Save dialog canceled')
        return
      }

      const filePath = result.filePath
      console.log('[App] Saving to file:', filePath)

      // Export current configuration
      const config = {
        nodes,
        edges,
        version: '1.0',
        timestamp: new Date().toISOString()
      }

      await window.electron?.fs?.writeFile(filePath, JSON.stringify(config, null, 2))
      console.log('[App] File saved successfully')
      window.alert('設定ファイルを保存しました')
    } catch (error) {
      console.error('[App] Failed to save file:', error)
      window.alert(`ファイルの保存に失敗しました: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  const handleExport = async () => {
    console.log('[App] Export button clicked')
    
    // Clear previous export errors
    setExportErrors([])
    
    const issues = runValidation()
    console.log('[App] Validation issues:', JSON.stringify(issues, null, 2))
    
    if (issues.some((issue) => issue.type === 'error')) {
      console.log('[App] Validation failed, aborting export')
      console.log('[App] Error issues:', issues.filter(i => i.type === 'error'))
      return
    }

    const profileName = window.electron?.env?.isE2E
      ? window.electron.env.profileName
      : window.prompt('プロファイル名', 'active') || 'active'
    
    console.log('[App] Profile name:', profileName)
    
    try {
      const result = await exportCurrentConfig(profileName)
      console.log('[App] Export result:', result)
      
      if (!result.ok) {
        if (result.errors && result.errors.length > 0) {
          // Display validation errors from export
          console.error('[App] Export validation failed:', result.errors)
          setExportErrors(result.errors)
          window.alert('エクスポート検証に失敗しました。詳細はエラー表示を確認してください。')
        } else {
          window.alert('エクスポートがキャンセルされたか失敗しました。')
        }
      } else {
        // Clear errors on successful export
        setExportErrors([])
      }
    } catch (error) {
      console.error('[App] エクスポートに失敗しました:', error)
      window.alert(`エクスポートに失敗しました: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  return (
    <div className="app-shell">
      <header className="app-header">
        <div className="app-title">Strategy Bricks Builder</div>
        <div className="app-tabs">
          <button 
            className={`tab-button ${activeTab === 'builder' ? 'active' : ''}`}
            onClick={() => setActiveTab('builder')}
          >
            ビルダー
          </button>
          <button 
            className={`tab-button ${activeTab === 'backtest' ? 'active' : ''}`}
            onClick={() => setActiveTab('backtest')}
          >
            バックテスト
          </button>
        </div>
        <div className="app-actions">
          <button className="btn" onClick={handleNew}>新規</button>
          <button className="btn" onClick={handleOpen}>開く</button>
          <button className="btn" onClick={handleSave}>保存</button>
          <button className="btn" onClick={runValidation}>
            検証
          </button>
          <button className="btn btn-primary" onClick={handleExport}>
            エクスポート
          </button>
        </div>
      </header>

      {/* Display export validation errors */}
      {exportErrors.length > 0 && (
        <div className="export-errors-container">
          <ValidationErrorDisplay errors={exportErrors} />
        </div>
      )}

      {activeTab === 'builder' ? (
        <>
          <div className="app-body">
            <aside className="panel panel-left">
              <div className="panel-title">パレット</div>
              <div className="panel-content">
                <Palette />
              </div>
            </aside>

            <main className="panel panel-center">
              <div className="panel-title">キャンバス</div>
              <div className="panel-content">
                <Canvas />
              </div>
            </main>

            <aside className="panel panel-right">
              <div className="panel-title">プロパティ</div>
              <div className="panel-content">
                <PropertyPanel />
              </div>
            </aside>
          </div>

          <footer className="panel panel-bottom">
            <div className="panel-title">検証結果</div>
            <div className="panel-content">
              <ValidationPanel />
            </div>
          </footer>
        </>
      ) : (
        <div className="app-body-full">
          <BacktestPanel />
        </div>
      )}
    </div>
  )
}

export default App
