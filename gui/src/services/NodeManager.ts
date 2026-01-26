import type { Node } from 'reactflow'

/**
 * NodeManager
 * 
 * Manages blockId assignment for condition nodes.
 * Each condition node receives a unique blockId when added to the canvas.
 * 
 * BlockId format: {typeId}#{uniqueCounter}
 * Example: "filter.spreadMax#1", "filter.spreadMax#2", "trend.maRelation#1"
 * 
 * Requirements:
 * - 1.1: Generate unique blockIds for all blocks
 * - 4.2: Assign blockId when node is added to canvas
 */
export class NodeManager {
  // Counter for each typeId to ensure unique blockIds
  private typeIdCounters: Map<string, number> = new Map()
  
  // Mapping from node ID to blockId
  private nodeBlockIdMap: Map<string, string> = new Map()

  /**
   * Assigns a unique blockId to a condition node.
   * 
   * @param node - The condition node to assign a blockId to
   * @returns The assigned blockId
   * @throws Error if blockTypeId is not set on the node
   */
  assignBlockId(node: Node): string {
    if (!node.data?.blockTypeId) {
      throw new Error('blockTypeId is required for condition nodes')
    }

    const typeId = node.data.blockTypeId as string
    const counter = this.getNextCounter(typeId)
    const blockId = `${typeId}#${counter}`

    // Store the blockId in the node data
    node.data.blockId = blockId
    
    // Store the mapping
    this.nodeBlockIdMap.set(node.id, blockId)

    return blockId
  }

  /**
   * Gets the blockId for a given node ID.
   * 
   * @param nodeId - The node ID to look up
   * @returns The blockId if found, undefined otherwise
   */
  getBlockId(nodeId: string): string | undefined {
    return this.nodeBlockIdMap.get(nodeId)
  }

  /**
   * Gets all assigned blockIds.
   * Useful for duplicate checking and validation.
   * 
   * @returns Array of all blockIds
   */
  getAllBlockIds(): string[] {
    return Array.from(this.nodeBlockIdMap.values())
  }

  /**
   * Gets the next counter value for a given typeId.
   * Increments the counter for that typeId.
   * 
   * @param typeId - The block type ID
   * @returns The next counter value
   */
  private getNextCounter(typeId: string): number {
    const current = this.typeIdCounters.get(typeId) || 0
    const next = current + 1
    this.typeIdCounters.set(typeId, next)
    return next
  }

  /**
   * Resets the NodeManager state.
   * Useful for testing or when loading a new canvas.
   */
  reset(): void {
    this.typeIdCounters.clear()
    this.nodeBlockIdMap.clear()
  }

  /**
   * Initializes the NodeManager from existing nodes.
   * This is useful when loading a saved canvas that already has blockIds assigned.
   * 
   * @param nodes - Array of nodes to initialize from
   */
  initializeFromNodes(nodes: Node[]): void {
    this.reset()
    
    nodes.forEach(node => {
      if (node.type === 'conditionNode' && node.data?.blockId) {
        const blockId = node.data.blockId as string
        this.nodeBlockIdMap.set(node.id, blockId)
        
        // Extract typeId and counter from blockId
        const hashIndex = blockId.indexOf('#')
        if (hashIndex > 0) {
          const typeId = blockId.substring(0, hashIndex)
          const counter = parseInt(blockId.substring(hashIndex + 1), 10)
          
          if (!isNaN(counter)) {
            // Update the counter to be at least as high as this blockId
            const currentCounter = this.typeIdCounters.get(typeId) || 0
            if (counter > currentCounter) {
              this.typeIdCounters.set(typeId, counter)
            }
          }
        }
      }
    })
  }
}
