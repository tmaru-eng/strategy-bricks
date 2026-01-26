import { _electron as electron } from '@playwright/test'
import { promises as fs } from 'fs'
import os from 'os'
import path from 'path'

const appRoot = path.resolve(process.cwd())
const outputDir =
  process.env.E2E_EXPORT_DIR || path.join(os.tmpdir(), 'strategy-bricks-e2e')

await fs.rm(outputDir, { recursive: true, force: true })

// テストケース定義
const testCases = [
  {
    name: 'basic-strategy',
    description: '基本戦略（スプレッド + MA + BB回帰）',
    // デフォルトの初期ノードを使用
    setupNodes: null
  },
  {
    name: 'trend-only',
    description: 'トレンドフィルタのみ',
    setupNodes: async (page) => {
      // 既存のノードをクリアして、トレンドブロックのみ配置
      // 実装は後で追加
    }
  },
  {
    name: 'multi-trigger',
    description: '複数トリガー（BB + RSI）',
    setupNodes: async (page) => {
      // 複数のトリガーブロックを配置
      // 実装は後で追加
    }
  }
]

console.log('=== GUI E2E Test - Multiple Configs ===')
console.log(`Output directory: ${outputDir}`)
console.log(`Test cases: ${testCases.length}`)
console.log('')

const results = []

for (const testCase of testCases) {
  console.log(`\n--- Test Case: ${testCase.name} ---`)
  console.log(`Description: ${testCase.description}`)
  
  const app = await electron.launch({
    args: [appRoot],
    env: {
      ...process.env,
      E2E: '1',
      E2E_EXPORT_DIR: outputDir,
      E2E_PROFILE_NAME: testCase.name
    }
  })

  const page = await app.firstWindow()

  // コンソールログを取得
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      console.log(`[Browser Error] ${msg.text()}`)
    }
  })

  try {
    console.log('Waiting for palette...')
    await page.getByText('パレット').waitFor({ timeout: 10000 })
    console.log('Palette loaded')

    await page.locator('.palette-name', { hasText: '最大スプレッド' }).first().waitFor()
    console.log('Block catalog loaded')

    // カスタムノード配置（指定されている場合）
    if (testCase.setupNodes) {
      console.log('Setting up custom nodes...')
      await testCase.setupNodes(page)
    }

    // エクスポート実行
    console.log('Clicking export button...')
    const exportButton = page.getByRole('button', { name: 'エクスポート' })
    await exportButton.click({ timeout: 5000 })
    console.log('Export button clicked')

    // ファイル生成を待機
    console.log('Waiting for files...')
    const activePath = path.join(outputDir, 'active.json')
    const profilePath = path.join(outputDir, 'profiles', `${testCase.name}.json`)

    const waitForFile = async (filePath, timeoutMs = 5000) => {
      const start = Date.now()
      while (Date.now() - start < timeoutMs) {
        try {
          await fs.access(filePath)
          return true
        } catch {
          await new Promise((resolve) => setTimeout(resolve, 100))
        }
      }
      return false
    }

    const activeExists = await waitForFile(activePath)
    const profileExists = await waitForFile(profilePath)

    if (!activeExists || !profileExists) {
      throw new Error('Files not created')
    }

    // ファイル内容を検証
    const profileJson = await fs.readFile(profilePath, 'utf-8')
    const config = JSON.parse(profileJson)

    if (!config.meta || !config.strategies || !config.blocks) {
      throw new Error('Invalid config structure')
    }

    // テストケース用のファイル名でコピー
    const testCasePath = path.join(outputDir, `${testCase.name}.json`)
    await fs.copyFile(profilePath, testCasePath)

    console.log(`✓ Success: ${testCase.name}.json`)
    console.log(`  Strategies: ${config.strategies.length}`)
    console.log(`  Blocks: ${config.blocks.length}`)

    results.push({
      name: testCase.name,
      success: true,
      strategies: config.strategies.length,
      blocks: config.blocks.length
    })

  } catch (error) {
    console.error(`✗ Failed: ${testCase.name}`)
    console.error(`  Error: ${error.message}`)
    
    results.push({
      name: testCase.name,
      success: false,
      error: error.message
    })
  } finally {
    await app.close()
  }
}

// 結果サマリー
console.log('\n=== Test Results ===')
console.log(`Total: ${results.length}`)
console.log(`Success: ${results.filter(r => r.success).length}`)
console.log(`Failed: ${results.filter(r => !r.success).length}`)
console.log('')

results.forEach(result => {
  const status = result.success ? '✓' : '✗'
  console.log(`${status} ${result.name}`)
  if (result.success) {
    console.log(`  Strategies: ${result.strategies}, Blocks: ${result.blocks}`)
  } else {
    console.log(`  Error: ${result.error}`)
  }
})

console.log('')
console.log(`Output directory: ${outputDir}`)

// 失敗があれば終了コード1
if (results.some(r => !r.success)) {
  process.exit(1)
}
