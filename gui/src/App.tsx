import React from 'react'
import { Palette } from './components/Palette/Palette'
import { Canvas } from './components/Canvas/Canvas'
import { PropertyPanel } from './components/Property/PropertyPanel'
import { ValidationPanel } from './components/Validator/ValidationPanel'
import { useStateManager } from './store/useStateManager'

const App: React.FC = () => {
  const { runValidation, exportCurrentConfig } = useStateManager()

  const handleExport = async () => {
    const issues = runValidation()
    if (issues.some((issue) => issue.type === 'error')) {
      return
    }

    const profileName = window.electron?.env?.isE2E
      ? window.electron.env.profileName
      : window.prompt('プロファイル名', 'active') || 'active'
    const result = await exportCurrentConfig(profileName)
    if (!result.ok) {
      window.alert('エクスポートがキャンセルされたか失敗しました。')
    }
  }

  return (
    <div className="app-shell">
      <header className="app-header">
        <div className="app-title">Strategy Bricks Builder</div>
        <div className="app-actions">
          <button className="btn">新規</button>
          <button className="btn">開く</button>
          <button className="btn">保存</button>
          <button className="btn" onClick={runValidation}>
            検証
          </button>
          <button className="btn btn-primary" onClick={handleExport}>
            エクスポート
          </button>
        </div>
      </header>

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
    </div>
  )
}

export default App
