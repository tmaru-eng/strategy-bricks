/// <reference types="vite/client" />

declare global {
  interface Window {
    electron: {
      ping: () => Promise<{ ok: boolean }>
      openCatalog: () => Promise<{ path: string; content: string } | null>
      env: {
        isE2E: boolean
        profileName: string
      }
      exportConfig: (payload: {
        profileName: string
        content: string
      }) => Promise<{ ok: boolean; path?: string }>
    }
  }
}

export {}
