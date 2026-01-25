import type { BlockCatalog, BlockDefinition } from '../models/catalog'

export type CatalogLoadResult = {
  path: string
  catalog: BlockCatalog
}

const validateCatalog = (catalog: BlockCatalog): void => {
  if (!catalog.meta?.formatVersion) {
    throw new Error('meta.formatVersion が必要です')
  }

  if (!Array.isArray(catalog.blocks)) {
    throw new Error('blocks は配列である必要があります')
  }

  catalog.blocks.forEach((block: BlockDefinition) => {
    if (!block.typeId || !block.category || !block.displayName) {
      throw new Error(`無効なブロック定義: ${block.typeId || 'unknown'}`)
    }
    if (!block.paramsSchema) {
      throw new Error(`paramsSchema が必要です: ${block.typeId}`)
    }
  })
}

export const openCatalog = async (): Promise<CatalogLoadResult> => {
  if (!window.electron?.openCatalog) {
    throw new Error('Electron ブリッジが利用できません')
  }

  const result = await window.electron.openCatalog()
  if (!result) {
    throw new Error('カタログの選択がキャンセルされました')
  }

  let parsed: BlockCatalog
  try {
    parsed = JSON.parse(result.content) as BlockCatalog
  } catch (e) {
    throw new Error('カタログのJSONパースに失敗しました')
  }
  validateCatalog(parsed)

  return {
    path: result.path,
    catalog: parsed
  }
}
