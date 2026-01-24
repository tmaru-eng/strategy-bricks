import React, { useMemo, useState } from 'react'
import type { BlockDefinition, CatalogCategory } from '../../models/catalog'
import { useStateManager } from '../../store/useStateManager'

const categoryLabels: { id: CatalogCategory; label: string }[] = [
  { id: 'all', label: '全て' },
  { id: 'filter', label: 'フィルタ' },
  { id: 'env', label: '環境' },
  { id: 'trend', label: 'トレンド' },
  { id: 'trigger', label: 'トリガー' },
  { id: 'lot', label: 'ロット' },
  { id: 'risk', label: 'リスク' },
  { id: 'exit', label: 'エグジット' },
  { id: 'nanpin', label: 'ナンピン' }
]

export const Palette: React.FC = () => {
  const { catalog } = useStateManager()
  const [selectedCategory, setSelectedCategory] = useState<CatalogCategory>('all')
  const [searchTerm, setSearchTerm] = useState('')

  const blocksByCategory = useMemo(() => {
    if (!catalog) return {}

    const grouped: Record<string, BlockDefinition[]> = {}
    for (const block of catalog.blocks) {
      const category = block.category || 'all'
      if (!grouped[category]) {
        grouped[category] = []
      }
      grouped[category].push(block)
    }

    return grouped
  }, [catalog])

  const filteredBlocks = useMemo(() => {
    if (!catalog) return []

    let blocks =
      selectedCategory === 'all'
        ? catalog.blocks
        : blocksByCategory[selectedCategory] || []

    if (searchTerm.trim()) {
      const needle = searchTerm.toLowerCase()
      blocks = blocks.filter(
        (block) =>
          block.displayName.toLowerCase().includes(needle) ||
          block.typeId.toLowerCase().includes(needle)
      )
    }

    return blocks
  }, [catalog, selectedCategory, searchTerm, blocksByCategory])

  if (!catalog) {
    return <div className="palette-empty">カタログが利用できません</div>
  }

  return (
    <div className="palette-root">
      <div className="palette-tabs">
        {categoryLabels.map((category) => (
          <button
            key={category.id}
            className={`palette-tab${
              selectedCategory === category.id ? ' is-active' : ''
            } category-${category.id}`}
            onClick={() => setSelectedCategory(category.id)}
          >
            {category.label}
          </button>
        ))}
      </div>

      <input
        className="palette-search"
        type="text"
        placeholder="ブロックを検索"
        value={searchTerm}
        onChange={(event) => setSearchTerm(event.target.value)}
      />

      <div className="palette-list">
        {filteredBlocks.map((block) => (
          <div
            key={block.typeId}
            className={`palette-item category-${block.category}`}
            draggable
            onDragStart={(event) => {
              event.dataTransfer.setData(
                'application/strategy-block',
                JSON.stringify({
                  typeId: block.typeId,
                  displayName: block.displayName
                })
              )
              event.dataTransfer.effectAllowed = 'move'
            }}
          >
            <div className="palette-name">{block.displayName}</div>
            <div className="palette-type">{block.typeId}</div>
          </div>
        ))}

        {filteredBlocks.length === 0 && (
          <div className="palette-empty">一致するブロックがありません</div>
        )}
      </div>
    </div>
  )
}
