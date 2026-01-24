import { _electron as electron } from '@playwright/test'
import { promises as fs } from 'fs'
import path from 'path'

const appRoot = path.resolve(process.cwd())
const outputDir = process.env.E2E_EXPORT_DIR || '/tmp/strategy-bricks-e2e'
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
await page.getByText('最大スプレッド').waitFor()

await page.getByRole('button', { name: 'エクスポート' }).click()

const activePath = path.join(outputDir, 'active.json')
const profilePath = path.join(outputDir, 'profiles', `${profileName}.json`)

const [activeJson, profileJson] = await Promise.all([
  fs.readFile(activePath, 'utf-8'),
  fs.readFile(profilePath, 'utf-8')
])

if (!activeJson.includes('"meta"') || !profileJson.includes('"meta"')) {
  throw new Error('Exported config missing meta field')
}

await app.close()
console.log(`E2E export OK: ${activePath}`)
