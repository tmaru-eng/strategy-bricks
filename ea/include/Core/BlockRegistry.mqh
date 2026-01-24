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

// MVPブロック
#include "../Blocks/Filter/FilterSpreadMax.mqh"
#include "../Blocks/Env/EnvSessionTimeWindow.mqh"
#include "../Blocks/Trend/TrendMARelation.mqh"
#include "../Blocks/Trigger/TriggerBBReentry.mqh"
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

        if (typeId == "filter.spreadMax") {
            block = new CFilterSpreadMax(blockId);
        }
        else if (typeId == "env.session.timeWindow") {
            CEnvSessionTimeWindow* sessionBlock = new CEnvSessionTimeWindow(blockId);
            // グローバルセッション設定を適用（NULLチェック追加）
            if (m_hasGlobalSession && sessionBlock != NULL) {
                sessionBlock.ApplyGlobalSession(m_globalSession);
            }
            block = sessionBlock;
        }
        else if (typeId == "trend.maRelation") {
            block = new CTrendMARelation(blockId);
        }
        else if (typeId == "trigger.bbReentry") {
            block = new CTriggerBBReentry(blockId);
        }
        else if (typeId == "lot.fixed") {
            block = new CLotFixed(blockId);
        }
        else if (typeId == "risk.fixedSLTP") {
            block = new CRiskFixedSLTP(blockId);
        }
        else if (typeId == "exit.none") {
            block = new CExitNone(blockId);
        }
        else if (typeId == "nanpin.off") {
            block = new CNanpinOff(blockId);
        }
        else {
            Print("ERROR: Unknown block typeId: ", typeId);
            return NULL;
        }

        // パラメータ設定
        if (block != NULL) {
            block.SetParams(paramsJson);
            // キャッシュに追加
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
