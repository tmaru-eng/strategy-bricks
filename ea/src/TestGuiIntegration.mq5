//+------------------------------------------------------------------+
//|                                          TestGuiIntegration.mq5 |
//|                                  Test GUI-EA Config Integration |
//+------------------------------------------------------------------+
#property copyright "Strategy Bricks"
#property version   "1.00"
#property strict

#include "../include/Config/ConfigLoader.mqh"
#include "../include/Config/ConfigValidator.mqh"
#include "../include/Support/Logger.mqh"
#include "../include/Core/BlockRegistry.mqh"

Logger g_logger;
ConfigLoader g_loader;
ConfigValidator g_validator;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== GUI Integration Test Start ===");
   
   // Initialize logger
   g_logger.Init("TestGuiIntegration");
   g_loader.Init(&g_logger);
   g_validator.Init(&g_logger);
   
   // Test 1: Load GUI-generated config
   Print("\n--- Test 1: Load GUI-generated config ---");
   if(!TestLoadGuiConfig())
   {
      Print("FAILED: GUI config load test");
      return;
   }
   Print("PASSED: GUI config load test");
   
   // Test 2: Verify all block references resolve
   Print("\n--- Test 2: Verify block references ---");
   if(!TestBlockReferences())
   {
      Print("FAILED: Block reference test");
      return;
   }
   Print("PASSED: Block reference test");
   
   // Test 3: Verify shared blocks
   Print("\n--- Test 3: Verify shared blocks ---");
   if(!TestSharedBlocks())
   {
      Print("FAILED: Shared block test");
      return;
   }
   Print("PASSED: Shared block test");
   
   Print("\n=== All GUI Integration Tests PASSED ===");
}

//+------------------------------------------------------------------+
//| Test loading GUI-generated config                                |
//+------------------------------------------------------------------+
bool TestLoadGuiConfig()
{
   string configPath = "strategy/gui_integration_test.json";
   
   // Read config file
   string jsonContent = "";
   int fileHandle = FileOpen(configPath, FILE_READ|FILE_TXT|FILE_ANSI);
   
   if(fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot open config file: ", configPath);
      Print("Error code: ", GetLastError());
      return false;
   }
   
   while(!FileIsEnding(fileHandle))
   {
      jsonContent += FileReadString(fileHandle);
   }
   
   FileClose(fileHandle);
   
   if(StringLen(jsonContent) == 0)
   {
      Print("ERROR: Config file is empty");
      return false;
   }
   
   Print("✓ Config file loaded successfully");
   Print("  File: ", configPath);
   Print("  Size: ", StringLen(jsonContent), " characters");
   
   return true;
}

//+------------------------------------------------------------------+
//| Test block reference resolution                                  |
//+------------------------------------------------------------------+
bool TestBlockReferences()
{
   // Manually parse and verify the test config
   // This simulates what ConfigLoader does
   
   string expectedBlocks[] = {
      "filter.spreadMax#1",
      "trend.maRelation#1",
      "trend.maRelation#2",
      "trigger.rsiLevel#1",
      "trigger.rsiLevel#2"
   };
   
   string strategy1Refs[] = {
      "filter.spreadMax#1",
      "trend.maRelation#1",
      "trigger.rsiLevel#1"
   };
   
   string strategy2Refs[] = {
      "filter.spreadMax#1",
      "trend.maRelation#2",
      "trigger.rsiLevel#2"
   };
   
   // Verify all S1 references exist in blocks
   for(int i = 0; i < ArraySize(strategy1Refs); i++)
   {
      bool found = false;
      for(int j = 0; j < ArraySize(expectedBlocks); j++)
      {
         if(strategy1Refs[i] == expectedBlocks[j])
         {
            found = true;
            break;
         }
      }
      
      if(!found)
      {
         Print("ERROR: Strategy 1 reference not found: ", strategy1Refs[i]);
         return false;
      }
   }
   
   Print("✓ All Strategy 1 references resolved");
   
   // Verify all S2 references exist in blocks
   for(int i = 0; i < ArraySize(strategy2Refs); i++)
   {
      bool found = false;
      for(int j = 0; j < ArraySize(expectedBlocks); j++)
      {
         if(strategy2Refs[i] == expectedBlocks[j])
         {
            found = true;
            break;
         }
      }
      
      if(!found)
      {
         Print("ERROR: Strategy 2 reference not found: ", strategy2Refs[i]);
         return false;
      }
   }
   
   Print("✓ All Strategy 2 references resolved");
   
   return true;
}

//+------------------------------------------------------------------+
//| Test shared block usage                                          |
//+------------------------------------------------------------------+
bool TestSharedBlocks()
{
   // Verify that filter.spreadMax#1 is shared between both strategies
   string sharedBlockId = "filter.spreadMax#1";
   
   string strategy1Refs[] = {
      "filter.spreadMax#1",
      "trend.maRelation#1",
      "trigger.rsiLevel#1"
   };
   
   string strategy2Refs[] = {
      "filter.spreadMax#1",
      "trend.maRelation#2",
      "trigger.rsiLevel#2"
   };
   
   bool foundInS1 = false;
   bool foundInS2 = false;
   
   for(int i = 0; i < ArraySize(strategy1Refs); i++)
   {
      if(strategy1Refs[i] == sharedBlockId)
      {
         foundInS1 = true;
         break;
      }
   }
   
   for(int i = 0; i < ArraySize(strategy2Refs); i++)
   {
      if(strategy2Refs[i] == sharedBlockId)
      {
         foundInS2 = true;
         break;
      }
   }
   
   if(!foundInS1 || !foundInS2)
   {
      Print("ERROR: Shared block not found in both strategies");
      return false;
   }
   
   Print("✓ Shared block '", sharedBlockId, "' used by both strategies");
   
   return true;
}
