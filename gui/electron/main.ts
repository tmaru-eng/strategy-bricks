import { app, BrowserWindow, dialog, ipcMain } from 'electron'
import { mkdir, readFile, writeFile } from 'fs/promises'
import { basename, join } from 'path'

const sanitizeProfileName = (name: string): string => {
  const base = basename(name)
  const sanitized = base.replace(/[^a-zA-Z0-9._-]/g, '_')
  return sanitized.length > 0 ? sanitized : 'active'
}

const createWindow = () => {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 960,
    minHeight: 600,
    backgroundColor: '#f4f3f0',
    webPreferences: {
      preload: join(__dirname, 'preload.js')
    }
  })

  if (process.env.ELECTRON_RENDERER_URL) {
    win.loadURL(process.env.ELECTRON_RENDERER_URL)
  } else {
    win.loadFile(join(__dirname, '../dist/index.html'))
  }
}

app.whenReady().then(() => {
  createWindow()

  ipcMain.handle('app:ping', () => ({ ok: true }))
  ipcMain.handle('catalog:open', async () => {
    try {
      const result = await dialog.showOpenDialog({
        title: 'Open block_catalog.json',
        properties: ['openFile'],
        filters: [{ name: 'JSON', extensions: ['json'] }]
      })

      if (result.canceled || result.filePaths.length === 0) {
        return null
      }

      const filePath = result.filePaths[0]
      const content = await readFile(filePath, 'utf-8')
      return { path: filePath, content }
    } catch (error) {
      throw new Error(error instanceof Error ? error.message : String(error))
    }
  })
  ipcMain.handle('config:export', async (_event, payload) => {
    try {
      const isE2E = process.env.E2E === '1'
      let outputDir = process.env.E2E_EXPORT_DIR

      if (!outputDir) {
        if (isE2E) {
          throw new Error('E2E export directory is not set')
        }

        const result = await dialog.showOpenDialog({
          title: 'Select output directory',
          properties: ['openDirectory', 'createDirectory']
        })

        if (result.canceled || result.filePaths.length === 0) {
          return { ok: false }
        }

        outputDir = result.filePaths[0]
      }

      const profilesDir = join(outputDir, 'profiles')
      const profileName = sanitizeProfileName(payload?.profileName || 'active')
      const content = payload?.content || '{}'

      await mkdir(profilesDir, { recursive: true })
      await writeFile(join(profilesDir, `${profileName}.json`), content, 'utf-8')
      await writeFile(join(outputDir, 'active.json'), content, 'utf-8')

      return { ok: true, path: outputDir }
    } catch (error) {
      throw new Error(error instanceof Error ? error.message : String(error))
    }
  })

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})
