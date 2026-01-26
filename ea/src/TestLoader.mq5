//+------------------------------------------------------------------+
//|                                               TestLoader.mq5     |
//|                                         Strategy Bricks EA MVP   |
//|      Verify Config Loading and Block Instantiation                 |
//+------------------------------------------------------------------+
#property copyright "Strategy Bricks Team"
#property version   "1.00"
#property script_show_inputs

#include "../include/Config/ConfigLoader.mqh"
#include "../include/Core/BlockRegistry.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== Starting Config Loader Test ===");

    string fileName = "StrategyBricks/comprehensive_test.json"; // Relative to MQL5/Files
    
    // Ensure the file exists (user needs to place it manually in real scenario, 
    // here we assume it's copied to Files folder by CI/Build step)
    
    CConfigLoader loader;
    Config config;
    
    // Initialize config
    config.Reset();
    
    // Load
    if (!loader.Load(fileName, config)) {
        Print("FAILED to load config file: ", fileName);
        return;
    }
    
    Print("SUCCESS: Loaded config");
    Print("  Format Version: ", config.meta.formatVersion);
    Print("  Strategy Count: ", config.strategyCount);
    Print("  Block Count:    ", config.blockCount);
    
    // Verify Block Registry Instantiation
    CBlockRegistry registry;
    registry.Initialize();
    registry.SetGlobalSession(config.globalGuards.session);
    
    Print("--- Instantiating Blocks ---");
    if (registry.PreloadBlocks(config)) {
        Print("SUCCESS: All blocks instantiated successfully.");
        Print("Total Registry Blocks: ", registry.GetBlockCount());
    } else {
        Print("FAILED: Block instantiation failed.");
    }
    
    // Check specific blocks
    for(int i=0; i<config.blockCount; i++) {
        IBlock* block = registry.GetBlock(config, config.blocks[i].id);
        if (block != NULL) {
            Print("  Block [", config.blocks[i].id, "] Type: ", config.blocks[i].typeId, " -> OK");
        } else {
            Print("  Block [", config.blocks[i].id, "] Type: ", config.blocks[i].typeId, " -> FAILED");
        }
    }
    
    registry.Cleanup();
    Print("=== Test Complete ===");
}
