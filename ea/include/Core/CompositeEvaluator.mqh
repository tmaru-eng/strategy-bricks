//+------------------------------------------------------------------+
//|                                           CompositeEvaluator.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                            OR/AND短絡評価クラス                      |
//+------------------------------------------------------------------+
#ifndef COMPOSITEEVALUATOR_MQH
#define COMPOSITEEVALUATOR_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "../Blocks/IBlock.mqh"
#include "BlockRegistry.mqh"
#include "../Indicators/IndicatorCache.mqh"
#include "../Support/Logger.mqh"
#include "../Visualization/VisualConfig.mqh"

//+------------------------------------------------------------------+
//| CompositeEvaluatorクラス                                           |
//| DNF形式（枠がOR、ルール内がAND）のOR/AND短絡評価                      |
//+------------------------------------------------------------------+
class CCompositeEvaluator {
private:
    Config           m_config;          // 設定（コピー）
    bool             m_hasConfig;       // 設定済みフラグ
    CBlockRegistry*  m_registry;        // ブロックレジストリ
    CIndicatorCache* m_cache;           // インジケータキャッシュ
    CLogger*         m_logger;          // ロガー

    TradeDirection   m_lastDirection;   // 最後に検出された方向
    double           m_lastLot;         // 最後のロット値
    double           m_lastSlPips;      // 最後のSL pips
    double           m_lastTpPips;      // 最後のTP pips

    // 可視化用ブロック評価結果
    // 注: 固定サイズ配列。MAX_VISUAL_BLOCKS_PER_STRATEGY個を超えるブロックがある場合は警告が出力される
    // MAX_VISUAL_BLOCKS_PER_STRATEGYはVisualConfig.mqhで定義
    BlockVisualInfo  m_blockResults[MAX_VISUAL_BLOCKS_PER_STRATEGY];// ブロック評価結果保存
    int              m_blockResultCount;// ブロック評価結果数

    //+------------------------------------------------------------------+
    //| ブロックIDからtypeIdを取得                                         |
    //+------------------------------------------------------------------+
    string LookupBlockTypeId(const string &blockId) {
        if (!m_hasConfig) return "unknown";
        for (int i = 0; i < m_config.blockCount; i++) {
            if (m_config.blocks[i].id == blockId) {
                return m_config.blocks[i].typeId;
            }
        }
        return "unknown";
    }

    //+------------------------------------------------------------------+
    //| 未評価ブロックを可視化用に保存                                      |
    //+------------------------------------------------------------------+
    void SaveSkippedBlockResult(const string &blockId, const string &reason) {
        BlockResult skipped;
        skipped.Init(BLOCK_STATUS_NEUTRAL, DIRECTION_NEUTRAL, reason);
        SaveBlockResult(blockId, LookupBlockTypeId(blockId), skipped);
    }

    //+------------------------------------------------------------------+
    //| OR短絡で未評価となったRuleGroupを保存                               |
    //+------------------------------------------------------------------+
    void AppendSkippedRuleGroups(const EntryRequirement &requirement, int startIndex,
                                 const string &reason) {
        for (int rg = startIndex; rg < requirement.ruleGroupCount; rg++) {
            RuleGroup skipGroup = requirement.ruleGroups[rg];
            for (int c = 0; c < skipGroup.conditionCount; c++) {
                SaveSkippedBlockResult(skipGroup.conditions[c].blockId, reason);
            }
        }
    }

public:
    //--- コンストラクタ
    CCompositeEvaluator() {
        m_hasConfig = false;
        m_config.Reset();
        m_registry = NULL;
        m_cache = NULL;
        m_logger = NULL;
        m_blockResultCount = 0;
        ResetLastValues();
    }

    //--- デストラクタ
    ~CCompositeEvaluator() {}

    //--- 依存性注入
    void SetConfig(const Config &config) {
        m_config = config;
        m_hasConfig = true;
    }

    void SetBlockRegistry(CBlockRegistry* registry) {
        m_registry = registry;
    }

    void SetIndicatorCache(CIndicatorCache* cache) {
        m_cache = cache;
    }

    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }

    //+------------------------------------------------------------------+
    //| 最後の評価値をリセット                                             |
    //+------------------------------------------------------------------+
    void ResetLastValues() {
        m_lastDirection = DIRECTION_NEUTRAL;
        m_lastLot = 0;
        m_lastSlPips = 0;
        m_lastTpPips = 0;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価結果をリセット                                          |
    //+------------------------------------------------------------------+
    void ResetBlockResults() {
        m_blockResultCount = 0;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価結果を保存                                              |
    //+------------------------------------------------------------------+
    void SaveBlockResult(string blockId, string typeId, const BlockResult &result) {
        if (m_blockResultCount >= MAX_VISUAL_BLOCKS_PER_STRATEGY) {
            // 最大数を超えた場合は警告を出力
            Print("WARNING: CompositeEvaluator - Block result storage full (",
                  MAX_VISUAL_BLOCKS_PER_STRATEGY, "). Additional results will be truncated.");
            return;
        }

        m_blockResults[m_blockResultCount].blockId = blockId;
        m_blockResults[m_blockResultCount].typeId = typeId;
        m_blockResults[m_blockResultCount].status = result.status;
        m_blockResults[m_blockResultCount].reason = result.reason;
        m_blockResultCount++;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価結果を取得                                              |
    //+------------------------------------------------------------------+
    int GetBlockResults(BlockVisualInfo &results[]) {
        ArrayResize(results, m_blockResultCount);
        for (int i = 0; i < m_blockResultCount; i++) {
            results[i] = m_blockResults[i];
        }
        return m_blockResultCount;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価結果数を取得                                            |
    //+------------------------------------------------------------------+
    int GetBlockResultCount() const {
        return m_blockResultCount;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価結果を個別取得                                          |
    //+------------------------------------------------------------------+
    bool GetBlockResult(int index, BlockVisualInfo &info) {
        if (index < 0 || index >= m_blockResultCount) return false;
        info = m_blockResults[index];
        return true;
    }

    //+------------------------------------------------------------------+
    //| Context構築                                                       |
    //+------------------------------------------------------------------+
    void BuildContext(Context &ctx) {
        ctx.Reset();

        // Market情報
        ctx.market.symbol = Symbol();
        ctx.market.ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        ctx.market.bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        ctx.market.point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        ctx.market.digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

        // スプレッド計算（pips）- ユーティリティ関数使用
        ctx.market.spreadPips = CalculateSpreadPips(Symbol());

        // 価格配列（shift=1の確定足）
        double closeBuffer[], highBuffer[], lowBuffer[], openBuffer[];
        ArraySetAsSeries(closeBuffer, true);
        ArraySetAsSeries(highBuffer, true);
        ArraySetAsSeries(lowBuffer, true);
        ArraySetAsSeries(openBuffer, true);

        CopyClose(Symbol(), EA_TIMEFRAME, CONFIRMED_BAR_SHIFT, 1, closeBuffer);
        CopyHigh(Symbol(), EA_TIMEFRAME, CONFIRMED_BAR_SHIFT, 1, highBuffer);
        CopyLow(Symbol(), EA_TIMEFRAME, CONFIRMED_BAR_SHIFT, 1, lowBuffer);
        CopyOpen(Symbol(), EA_TIMEFRAME, CONFIRMED_BAR_SHIFT, 1, openBuffer);

        if (ArraySize(closeBuffer) > 0) ctx.market.close[0] = closeBuffer[0];
        if (ArraySize(highBuffer) > 0)  ctx.market.high[0] = highBuffer[0];
        if (ArraySize(lowBuffer) > 0)   ctx.market.low[0] = lowBuffer[0];
        if (ArraySize(openBuffer) > 0)  ctx.market.open[0] = openBuffer[0];

        // State情報
        ctx.state.barTime = iTime(Symbol(), EA_TIMEFRAME, 0);
        ctx.state.positionsTotal = PositionsTotal();

        // IndicatorCache参照
        ctx.cache = m_cache;
    }

    //+------------------------------------------------------------------+
    //| OR評価（短絡評価）                                                 |
    //| EntryRequirement = OR(ruleGroups)                                |
    //+------------------------------------------------------------------+
    bool EvaluateOR(const EntryRequirement &requirement, const Context &ctx) {
        ResetLastValues();
        ResetBlockResults();  // ブロック結果もリセット

        for (int i = 0; i < requirement.ruleGroupCount; i++) {
            RuleGroup rg = requirement.ruleGroups[i];  // ローカルコピー

            if (m_logger != NULL) {
                m_logger.LogInfo("RULEGROUP_EVAL_START", "RuleGroup: " + rg.id);
            }

            // AND評価
            bool success = EvaluateAND(rg, ctx);

            if (m_logger != NULL) {
                m_logger.LogRuleGroupEval(rg.id, success);
            }

            if (success) {
                // 未評価のRuleGroupを可視化用に記録（短絡評価の説明用）
                AppendSkippedRuleGroups(requirement, i + 1, "未評価 (短絡OR)");
                // 成立：ORなので即座にtrue（短絡評価）
                return true;
            }
        }

        // 全て不成立
        return false;
    }

    //+------------------------------------------------------------------+
    //| AND評価（短絡評価）                                                |
    //| ruleGroup = AND(conditions)                                      |
    //+------------------------------------------------------------------+
    bool EvaluateAND(const RuleGroup &ruleGroup, const Context &ctx) {
        for (int i = 0; i < ruleGroup.conditionCount; i++) {
            ConditionRef cond = ruleGroup.conditions[i];  // ローカルコピー

            // ブロック評価
            BlockResult result;
            if (!EvaluateBlock(cond.blockId, ctx, result)) {
                SaveBlockResult(cond.blockId, LookupBlockTypeId(cond.blockId), result);
                for (int j = i + 1; j < ruleGroup.conditionCount; j++) {
                    SaveSkippedBlockResult(ruleGroup.conditions[j].blockId, "未評価 (評価失敗)");
                }
                return false;  // ブロック取得失敗
            }

            // ログ
            if (m_logger != NULL && m_hasConfig) {
                IBlock* block = m_registry.GetBlock(m_config, cond.blockId);
                string typeId = (block != NULL) ? block.GetTypeId() : "unknown";
                m_logger.LogBlockEval(cond.blockId, typeId, result);
            }

            if (result.status == BLOCK_STATUS_FAIL) {
                for (int j = i + 1; j < ruleGroup.conditionCount; j++) {
                    SaveSkippedBlockResult(ruleGroup.conditions[j].blockId, "未評価 (短絡AND)");
                }
                // 失敗：ANDなので即座にfalse（短絡評価）
                return false;
            }

            // 方向を更新（DIRECTION_NEUTRAL以外なら）
            if (result.direction != DIRECTION_NEUTRAL) {
                m_lastDirection = result.direction;
            }

            // lot/risk値を更新（設定されていれば）
            if (result.lotValue > 0) {
                m_lastLot = result.lotValue;
            }
            if (result.slPips > 0) {
                m_lastSlPips = result.slPips;
            }
            if (result.tpPips > 0) {
                m_lastTpPips = result.tpPips;
            }
        }

        // 全てPASS
        return true;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    bool EvaluateBlock(string blockId, const Context &ctx, BlockResult &result) {
        if (m_registry == NULL || !m_hasConfig) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Registry or Config not set");
            return false;
        }

        // ブロック取得
        IBlock* block = m_registry.GetBlock(m_config, blockId);
        if (block == NULL) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Block not found: " + blockId);
            return false;
        }

        // 評価実行（パラメータはSetParams経由でブロックに事前設定済み）
        block.Evaluate(ctx, result);

        // 可視化用に結果を保存
        SaveBlockResult(blockId, block.GetTypeId(), result);

        return true;
    }

    //+------------------------------------------------------------------+
    //| 最後に検出された方向を取得                                          |
    //+------------------------------------------------------------------+
    TradeDirection GetLastDirection() const {
        return m_lastDirection;
    }

    //+------------------------------------------------------------------+
    //| 最後のロット値を取得                                               |
    //+------------------------------------------------------------------+
    double GetLastLot() const {
        return m_lastLot;
    }

    //+------------------------------------------------------------------+
    //| 最後のSL pipsを取得                                                |
    //+------------------------------------------------------------------+
    double GetLastSlPips() const {
        return m_lastSlPips;
    }

    //+------------------------------------------------------------------+
    //| 最後のTP pipsを取得                                                |
    //+------------------------------------------------------------------+
    double GetLastTpPips() const {
        return m_lastTpPips;
    }
};

#endif // COMPOSITEEVALUATOR_MQH
