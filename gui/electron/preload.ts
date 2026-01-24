import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('electron', {
  ping: async () => ipcRenderer.invoke('app:ping'),
  openCatalog: async () => ipcRenderer.invoke('catalog:open'),
  env: {
    isE2E: process.env.E2E === '1',
    profileName: process.env.E2E_PROFILE_NAME || 'e2e-profile'
  },
  exportConfig: async (payload: { profileName: string; content: string }) =>
    ipcRenderer.invoke('config:export', payload)
})
