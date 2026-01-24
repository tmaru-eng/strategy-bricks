import { app, BrowserWindow, dialog, ipcMain } from 'electron'
import { mkdir, readFile, writeFile } from 'fs/promises'
import { join } from 'path'

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
  })
  ipcMain.handle('config:export', async (_event, payload) => {
    const isE2E = process.env.E2E === '1'
    let outputDir = process.env.E2E_EXPORT_DIR

    if (!outputDir) {
      if (isE2E) {
        outputDir = '/tmp/strategy-bricks-e2e'
      } else {
        const result = await dialog.showOpenDialog({
          title: 'Select output directory',
          properties: ['openDirectory', 'createDirectory']
        })

        if (result.canceled || result.filePaths.length === 0) {
          return { ok: false }
        }

        outputDir = result.filePaths[0]
      }
    }

    const profilesDir = join(outputDir, 'profiles')
    const profileName = payload?.profileName || 'active'
    const content = payload?.content || '{}'

    await mkdir(profilesDir, { recursive: true })
    await writeFile(join(profilesDir, `${profileName}.json`), content, 'utf-8')
    await writeFile(join(outputDir, 'active.json'), content, 'utf-8')

    return { ok: true, path: outputDir }
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
