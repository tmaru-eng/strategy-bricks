import type { Node } from 'reactflow'

export type ExportResult = {
  ok: boolean
  path?: string
}

const buildBlocks = (nodes: Node[]) => {
  const conditionNodes = nodes.filter((node) => node.type === 'conditionNode')
  return conditionNodes.map((node, index) => ({
    id: `${node.data?.blockTypeId || 'block'}#${index + 1}`,
    typeId: node.data?.blockTypeId || 'unknown',
    params: node.data?.params || {}
  }))
}

const buildConfig = (nodes: Node[], profileName: string) => {
  return {
    meta: {
      formatVersion: '1.0',
      name: profileName,
      generatedBy: 'GUI Builder',
      generatedAt: new Date().toISOString()
    },
    globalGuards: {},
    strategies: [],
    blocks: buildBlocks(nodes)
  }
}

export const exportConfig = async (profileName: string, nodes: Node[]): Promise<ExportResult> => {
  if (!window.electron?.exportConfig) {
    throw new Error('Electron bridge is not available')
  }

  const config = buildConfig(nodes, profileName)
  return window.electron.exportConfig({
    profileName,
    content: JSON.stringify(config, null, 2)
  })
}
