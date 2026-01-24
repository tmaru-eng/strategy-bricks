export type CatalogCategory =
  | 'filter'
  | 'env'
  | 'trend'
  | 'trigger'
  | 'lot'
  | 'risk'
  | 'exit'
  | 'nanpin'
  | 'all'

export type BlockIOSpec = {
  direction?: string
  score?: string
}

export type BlockDefinition = {
  typeId: string
  category: CatalogCategory
  displayName: string
  description?: string
  paramsSchema: Record<string, unknown>
  io?: BlockIOSpec
  runtimeHints?: Record<string, unknown>
}

export type BlockCatalog = {
  meta: {
    formatVersion: string
  }
  blocks: BlockDefinition[]
}
