import { _electron as electron } from '@playwright/test'
import { promises as fs } from 'fs'
import os from 'os'
import path from 'path'

const appRoot = path.resolve(process.cwd())
const outputDir =
  process.env.E2E_EXPORT_DIR || path.join(os.tmpdir(), 'strategy-bricks-e2e')
const profileName = process.env.E2E_PROFILE_NAME || 'e2e-profile'

await fs.rm(outputDir, { recursive: true, force: true })

const app = await electron.launch({
  args: [appRoot],
  env: {
    ...process.env,
    E2E: '1',
    E2E_EXPORT_DIR: outputDir,
    E2E_PROFILE_NAME: profileName
  }
})

const page = await app.firstWindow()

await page.getByText('パレット').waitFor()
await page.locator('.palette-name', { hasText: '最大スプレッド' }).first().waitFor()

await page.getByRole('button', { name: 'エクスポート' }).click()

const activePath = path.join(outputDir, 'active.json')
const profilePath = path.join(outputDir, 'profiles', `${profileName}.json`)

const waitForFile = async (filePath, timeoutMs = 5000) => {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    try {
      await fs.access(filePath)
      return
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 100))
    }
  }
  throw new Error(`Timeout waiting for file: ${filePath}`)
}

await waitForFile(activePath)
await waitForFile(profilePath)

const [activeJson, profileJson] = await Promise.all([
  fs.readFile(activePath, 'utf-8'),
  fs.readFile(profilePath, 'utf-8')
])

const activeParsed = JSON.parse(activeJson)
const profileParsed = JSON.parse(profileJson)

if (!activeParsed.meta || !profileParsed.meta) {
  throw new Error('Exported config missing meta field')
}

await app.close()
console.log(`E2E export OK: ${activePath}`)
