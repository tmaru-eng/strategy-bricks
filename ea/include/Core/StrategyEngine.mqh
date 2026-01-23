//+------------------------------------------------------------------+
//|                                               StrategyEngine.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                              戦略評価エンジン                        |
//+------------------------------------------------------------------+
#ifndef STRATEGYENGINE_MQH
#define STRATEGYENGINE_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "CompositeEvaluator.mqh"
#include "../Execution/OrderExecutor.mqh"
#include "../Execution/PositionManager.mqh"
#include "../Support/Logger.mqh"
#include "../Support/StateStore.mqh"

//+------------------------------------------------------------------+
//| StrategyEngineクラス                                               |
//| 戦略の評価と実行制御を行う中核クラス                                   |
//+------------------------------------------------------------------+
class CStrategyEngine {
private:
    Config              m_config;           // 設定（コピー）
    bool                m_hasConfig;        // 設定済みフラグ
    CCompositeEvaluator* m_evaluator;       // 複合評価器
    COrderExecutor*     m_executor;         // 発注実行
    CPositionManager*   m_positionManager;  // ポジション管理
    CLogger*            m_logger;           // ロガー
    CStateStore*        m_stateStore;       // 状態管理

    // ソート済みStrategy配列
    int                 m_sortedIndices[];
    int                 m_sortedCount;

    //+------------------------------------------------------------------+
    //| Strategyをpriority順にソート（降順）                                |
    //+------------------------------------------------------------------+
    void SortStrategies() {
        if (!m_hasConfig) return;

        ArrayResize(m_sortedIndices, m_config.strategyCount);
        m_sortedCount = m_config.strategyCount;

        // インデックスを初期化
        for (int i = 0; i < m_sortedCount; i++) {
            m_sortedIndices[i] = i;
        }

        // バブルソート（priority降順）
        for (int i = 0; i < m_sortedCount - 1; i++) {
            for (int j = 0; j < m_sortedCount - 1 - i; j++) {
                int idx1 = m_sortedIndices[j];
                int idx2 = m_sortedIndices[j + 1];

                if (m_config.strategies[idx1].priority <
                    m_config.strategies[idx2].priority) {
                    // スワップ
                    int temp = m_sortedIndices[j];
                    m_sortedIndices[j] = m_sortedIndices[j + 1];
                    m_sortedIndices[j + 1] = temp;
                }
            }
        }

        Print("StrategyEngine: Sorted ", m_sortedCount, " strategies by priority");
    }

    //+------------------------------------------------------------------+
    //| directionPolicyチェック                                           |
    //+------------------------------------------------------------------+
    bool CheckDirectionPolicy(DirectionPolicy policy, TradeDirection direction) {
        if (policy == POLICY_BOTH) return true;
        if (policy == POLICY_LONG_ONLY && direction == DIRECTION_LONG) return true;
        if (policy == POLICY_SHORT_ONLY && direction == DIRECTION_SHORT) return true;
        return false;
    }

public:
    //--- コンストラクタ
    CStrategyEngine() {
        m_hasConfig = false;
        m_config.Reset();
        m_evaluator = NULL;
        m_executor = NULL;
        m_positionManager = NULL;
        m_logger = NULL;
        m_stateStore = NULL;
        m_sortedCount = 0;
    }

    //--- デストラクタ
    ~CStrategyEngine() {}

    //--- 依存性注入
    void SetConfig(const Config &config) {
        m_config = config;
        m_hasConfig = true;
        SortStrategies();
    }

    void SetCompositeEvaluator(CCompositeEvaluator* evaluator) {
        m_evaluator = evaluator;
    }

    void SetOrderExecutor(COrderExecutor* executor) {
        m_executor = executor;
    }

    void SetPositionManager(CPositionManager* positionManager) {
        m_positionManager = positionManager;
    }

    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }

    void SetStateStore(CStateStore* stateStore) {
        m_stateStore = stateStore;
    }

    //+------------------------------------------------------------------+
    //| 初期化                                                            |
    //+------------------------------------------------------------------+
    void Initialize() {
        SortStrategies();
        Print("StrategyEngine: Initialized");
    }

    //+------------------------------------------------------------------+
    //| 戦略評価（メインループ）                                            |
    //+------------------------------------------------------------------+
    void EvaluateStrategies(datetime currentBarTime) {
        if (!m_hasConfig || m_evaluator == NULL) {
            Print("ERROR: StrategyEngine - Config or Evaluator not set");
            return;
        }

        // Context構築
        Context ctx;
        m_evaluator.BuildContext(ctx);
        ctx.state.barTime = currentBarTime;

        // ポジション情報を追加
        if (m_positionManager != NULL) {
            m_positionManager.BuildStateInfo(ctx.state);
        }

        // priority降順で評価
        for (int i = 0; i < m_sortedCount; i++) {
            int idx = m_sortedIndices[i];
            StrategyConfig strat = m_config.strategies[idx];  // ローカルコピー

            // enabled確認
            if (!strat.enabled) {
                if (m_logger != NULL) {
                    m_logger.LogStrategyEval(strat.id, false, "disabled");
                }
                continue;
            }

            // OR評価（RuleGroup）
            bool success = m_evaluator.EvaluateOR(strat.entryRequirement, ctx);

            if (success) {
                // 方向取得
                TradeDirection direction = m_evaluator.GetLastDirection();

                // directionPolicyチェック
                if (!CheckDirectionPolicy(strat.directionPolicy, direction)) {
                    if (m_logger != NULL) {
                        m_logger.LogStrategyEval(strat.id, false,
                            "direction mismatch: " + DirectionToString(direction));
                    }
                    continue;
                }

                // Strategy成立
                if (m_logger != NULL) {
                    m_logger.LogStrategyEval(strat.id, true, "adopted");
                }

                // エントリー実行
                ExecuteStrategy(strat, ctx, direction, currentBarTime);

                // conflictPolicyチェック
                if (strat.conflictPolicy == CONFLICT_FIRST_ONLY) {
                    // firstOnlyなら終了
                    break;
                }
            } else {
                // Strategy不成立
                if (m_logger != NULL) {
                    m_logger.LogStrategyEval(strat.id, false, "not matched");
                }
            }
        }
    }

    //+------------------------------------------------------------------+
    //| Strategy実行（エントリー）                                          |
    //+------------------------------------------------------------------+
    void ExecuteStrategy(StrategyConfig &strat, const Context &ctx,
                         TradeDirection direction, datetime barTime) {
        if (m_executor == NULL) {
            Print("ERROR: StrategyEngine - Executor not set");
            return;
        }

        // ロット取得（lotModelまたは評価結果から）
        double lot = m_evaluator.GetLastLot();
        if (lot <= 0) {
            lot = strat.lotModel.lots;
        }
        if (lot <= 0) {
            lot = DEFAULT_LOT;
        }

        // SL/TP取得（riskModelまたは評価結果から）
        double slPips = m_evaluator.GetLastSlPips();
        if (slPips <= 0) {
            slPips = strat.riskModel.slPips;
        }
        if (slPips <= 0) {
            slPips = DEFAULT_SL_PIPS;
        }

        double tpPips = m_evaluator.GetLastTpPips();
        if (tpPips <= 0) {
            tpPips = strat.riskModel.tpPips;
        }
        if (tpPips <= 0) {
            tpPips = DEFAULT_TP_PIPS;
        }

        // 発注リクエスト構築
        OrderRequest request;
        request.Reset();
        request.symbol = Symbol();
        request.direction = direction;
        request.lot = lot;
        request.slPips = slPips;
        request.tpPips = tpPips;
        request.magic = EA_MAGIC_NUMBER;
        request.comment = EA_NAME + " " + strat.id;
        request.barTime = barTime;
        request.strategyId = strat.id;

        // 発注実行
        OrderResult result;
        m_executor.Execute(request, result);
    }
};

#endif // STRATEGYENGINE_MQH
