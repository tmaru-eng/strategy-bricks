//+------------------------------------------------------------------+
//|                                                BlockRegistry.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                       ブロック登録・生成Factory                      |
//+------------------------------------------------------------------+
#ifndef BLOCKREGISTRY_MQH
#define BLOCKREGISTRY_MQH

#include "../Common/Constants.mqh"
#include "../Common/Structures.mqh"
#include "../Blocks/IBlock.mqh"

// Filter
#include "../Blocks/Filter/FilterSpreadMax.mqh"
#include "../Blocks/Filter/FilterAtrRange.mqh"

// Env
#include "../Blocks/Env/EnvSessionTimeWindow.mqh"

// Trend
#include "../Blocks/Trend/TrendMARelation.mqh"
#include "../Blocks/Trend/TrendMACross.mqh"
#include "../Blocks/Trend/TrendADXThreshold.mqh"
#include "../Blocks/Trend/TrendIchimokuCloud.mqh"
#include "../Blocks/Trend/TrendSARDirection.mqh"

// Trigger
#include "../Blocks/Trigger/TriggerBBReentry.mqh"
#include "../Blocks/Trigger/TriggerBBBreakout.mqh"
#include "../Blocks/Trigger/TriggerMACDCross.mqh"
#include "../Blocks/Trigger/TriggerStochCross.mqh"
#include "../Blocks/Trigger/TriggerRSILevel.mqh"
#include "../Blocks/Trigger/TriggerCCILevel.mqh"
#include "../Blocks/Trigger/TriggerSARFlip.mqh"
#include "../Blocks/Trigger/TriggerWPRLevel.mqh"
#include "../Blocks/Trigger/TriggerMFILevel.mqh"
#include "../Blocks/Trigger/TriggerRVICross.mqh"

// Osc
#include "../Blocks/Osc/OscMomentum.mqh"
#include "../Blocks/Osc/OscOsMA.mqh"

// Volume
#include "../Blocks/Volume/VolumeObvTrend.mqh"

// Bill
#include "../Blocks/Bill/BillFractals.mqh"
#include "../Blocks/Bill/BillAlligator.mqh"

// Lot/Risk/Exit/Nanpin
#include "../Blocks/Lot/LotFixed.mqh"
#include "../Blocks/Risk/RiskFixedSLTP.mqh"
#include "../Blocks/Exit/ExitNone.mqh"
#include "../Blocks/Nanpin/NanpinOff.mqh"

//+------------------------------------------------------------------+
//| ブロックキャッシュエントリ                                            |
//+------------------------------------------------------------------+
struct BlockCacheEntry {
    string  blockId;
    IBlock* block;
};

//+------------------------------------------------------------------+
//| BlockRegistryクラス                                                |
//| Factory Patternによるブロック生成・管理                              |
//+------------------------------------------------------------------+
class CBlockRegistry {
private:
    BlockCacheEntry m_cache[];      // ブロックキャッシュ
    int             m_cacheCount;   // キャッシュ数
    SessionConfig   m_globalSession;// グローバルセッション設定（コピー）
    bool            m_hasGlobalSession; // グローバルセッション設定済みフラグ

    //+------------------------------------------------------------------+
    //| キャッシュからブロックを検索                                        |
    //+------------------------------------------------------------------+
    IBlock* FindInCache(string blockId) {
        for (int i = 0; i < m_cacheCount; i++) {
            if (m_cache[i].blockId == blockId) {
                return m_cache[i].block;
            }
        }
        return NULL;
    }

    //+------------------------------------------------------------------+
    //| キャッシュにブロックを追加                                          |
    //+------------------------------------------------------------------+
    void AddToCache(string blockId, IBlock* block) {
        ArrayResize(m_cache, m_cacheCount + 1);
        m_cache[m_cacheCount].blockId = blockId;
        m_cache[m_cacheCount].block = block;
        m_cacheCount++;
    }

public:
    //--- コンストラクタ
    CBlockRegistry() {
        m_cacheCount = 0;
        m_hasGlobalSession = false;
        m_globalSession.Reset();
    }

    //--- デストラクタ
    ~CBlockRegistry() {
        Cleanup();
    }

    //+------------------------------------------------------------------+
    //| 初期化                                                            |
    //+------------------------------------------------------------------+
    void Initialize() {
        ArrayResize(m_cache, INITIAL_ARRAY_SIZE);
        m_cacheCount = 0;
        Print("BlockRegistry: Initialized");
    }

    //+------------------------------------------------------------------+
    //| クリーンアップ（全ブロック解放）                                     |
    //+------------------------------------------------------------------+
    void Cleanup() {
        for (int i = 0; i < m_cacheCount; i++) {
            if (m_cache[i].block != NULL) {
                delete m_cache[i].block;
                m_cache[i].block = NULL;
            }
        }
        ArrayResize(m_cache, 0);
        m_cacheCount = 0;
        Print("BlockRegistry: Cleanup completed");
    }

    //+------------------------------------------------------------------+
    //| グローバルセッション設定を設定                                       |
    //+------------------------------------------------------------------+
    void SetGlobalSession(const SessionConfig &session) {
        m_globalSession = session;
        m_hasGlobalSession = true;
    }

    //+------------------------------------------------------------------+
    //| ブロック生成（Factory Method）                                     |
    //+------------------------------------------------------------------+
    IBlock* CreateBlock(string blockId, string typeId, string paramsJson) {
        // キャッシュ検索
        IBlock* cached = FindInCache(blockId);
        if (cached != NULL) {
            return cached;
        }

        // 新規ブロック生成
        IBlock* block = NULL;

        if (typeId == "filter.spreadMax") block = new CFilterSpreadMax(blockId);
        else if (typeId == "filter.volatility.atrRange") block = new CFilterAtrRange(blockId);
        else if (typeId == "env.session.timeWindow" || typeId == "filter.session.timeWindow") { 
            // Support both old and new (filter category) naming for robustness? 
            // Catalog says "filter.session.timeWindow". Code might need update or alias.
            // Existing was "env.session.timeWindow". I'll support both.
            CEnvSessionTimeWindow* sessionBlock = new CEnvSessionTimeWindow(blockId);
            if (m_hasGlobalSession && sessionBlock != NULL) sessionBlock.ApplyGlobalSession(m_globalSession);
            block = sessionBlock;
        }
        // Trend
        else if (typeId == "trend.maRelation") block = new CTrendMARelation(blockId);
        else if (typeId == "trend.maCross") block = new CTrendMACross(blockId);
        else if (typeId == "trend.adxThreshold") block = new CTrendADXThreshold(blockId);
        else if (typeId == "trend.ichimokuCloud") block = new CTrendIchimokuCloud(blockId);
        else if (typeId == "trend.sarDirection") block = new CTrendSARDirection(blockId);
        // Trigger
        else if (typeId == "trigger.bbReentry") block = new CTriggerBBReentry(blockId);
        else if (typeId == "trigger.bbBreakout") block = new CTriggerBBBreakout(blockId);
        else if (typeId == "trigger.macdCross") block = new CTriggerMACDCross(blockId);
        else if (typeId == "trigger.stochCross") block = new CTriggerStochCross(blockId);
        else if (typeId == "trigger.rsiLevel") block = new CTriggerRSILevel(blockId);
        else if (typeId == "trigger.cciLevel") block = new CTriggerCCILevel(blockId);
        else if (typeId == "trigger.sarFlip") block = new CTriggerSARFlip(blockId);
        else if (typeId == "trigger.wprLevel") block = new CTriggerWPRLevel(blockId);
        else if (typeId == "trigger.mfiLevel") block = new CTriggerMFILevel(blockId);
        else if (typeId == "trigger.rviCross") block = new CTriggerRVICross(blockId);
        // Osc
        else if (typeId == "osc.momentum") block = new COscMomentum(blockId);
        else if (typeId == "osc.osma") block = new COscOsMA(blockId);
        // Volume
        else if (typeId == "volume.obvTrend") block = new CVolumeObvTrend(blockId);
        // Bill
        else if (typeId == "bill.fractals") block = new CBillFractals(blockId);
        else if (typeId == "bill.alligator") block = new CBillAlligator(blockId);
        // Models (Existing)
        else if (typeId == "lot.fixed") block = new CLotFixed(blockId);
        else if (typeId == "risk.fixedSLTP") block = new CRiskFixedSLTP(blockId);
        else if (typeId == "exit.none") block = new CExitNone(blockId);
        else if (typeId == "nanpin.off") block = new CNanpinOff(blockId);
        else {
            Print("ERROR: Unknown block typeId: ", typeId);
            return NULL;
        }

        // パラメータ設定
        if (block != NULL) {
            block.SetParams(paramsJson);
            AddToCache(blockId, block);
            Print("BlockRegistry: Created block - ", blockId, " (", typeId, ")");
        }

        return block;
    }

    //+------------------------------------------------------------------+
    //| 設定からブロックを取得（遅延生成）                                   |
    //+------------------------------------------------------------------+
    IBlock* GetBlock(const Config &config, string blockId) {
        // キャッシュ検索
        IBlock* cached = FindInCache(blockId);
        if (cached != NULL) {
            return cached;
        }

        // 設定からブロック定義を取得
        for (int i = 0; i < config.blockCount; i++) {
            if (config.blocks[i].id == blockId) {
                return CreateBlock(blockId, config.blocks[i].typeId,
                                  config.blocks[i].paramsJson);
            }
        }

        Print("ERROR: Block not found in config: ", blockId);
        return NULL;
    }

    //+------------------------------------------------------------------+
    //| ブロック数取得                                                     |
    //+------------------------------------------------------------------+
    int GetBlockCount() const {
        return m_cacheCount;
    }

    //+------------------------------------------------------------------+
    //| 全ブロックを事前生成                                               |
    //+------------------------------------------------------------------+
    bool PreloadBlocks(const Config &config) {
        for (int i = 0; i < config.blockCount; i++) {
            IBlock* block = CreateBlock(config.blocks[i].id,
                                        config.blocks[i].typeId,
                                        config.blocks[i].paramsJson);
            if (block == NULL) {
                Print("ERROR: Failed to preload block: ", config.blocks[i].id);
                return false;
            }
        }
        Print("BlockRegistry: Preloaded ", m_cacheCount, " blocks");
        return true;
    }
};

#endif // BLOCKREGISTRY_MQH
