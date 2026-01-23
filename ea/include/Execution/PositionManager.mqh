//+------------------------------------------------------------------+
//|                                             PositionManager.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                             ポジション管理クラス（副作用集約）         |
//+------------------------------------------------------------------+
#ifndef POSITIONMANAGER_MQH
#define POSITIONMANAGER_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "../Support/Logger.mqh"
#include "../Support/StateStore.mqh"
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//+------------------------------------------------------------------+
//| PositionManagerクラス                                              |
//| ポジション管理処理（トレール、建値、決済等）を集約                      |
//+------------------------------------------------------------------+
class CPositionManager {
private:
    Config         m_config;        // 設定（コピー）
    bool           m_hasConfig;     // 設定済みフラグ
    CLogger*       m_logger;        // ログ出力
    CStateStore*   m_stateStore;    // 状態管理
    CTrade         m_trade;         // MT5取引クラス
    CPositionInfo  m_position;      // ポジション情報クラス

public:
    //--- コンストラクタ
    CPositionManager() {
        m_hasConfig = false;
        m_config.Reset();
        m_logger = NULL;
        m_stateStore = NULL;
    }

    //--- デストラクタ
    ~CPositionManager() {}

    //--- 依存性注入
    void SetConfig(const Config &config) {
        m_config = config;
        m_hasConfig = true;
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
        m_trade.SetExpertMagicNumber(EA_MAGIC_NUMBER);
        m_trade.SetDeviationInPoints(ORDER_DEVIATION);
        Print("PositionManager: Initialized");
    }

    //+------------------------------------------------------------------+
    //| ポジション管理（新バー時のみ呼出）                                   |
    //+------------------------------------------------------------------+
    void ManagePositions() {
        // 全ポジションを走査
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;

            // マジックナンバーチェック
            if (PositionGetInteger(POSITION_MAGIC) != EA_MAGIC_NUMBER) continue;

            // シンボルチェック
            if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

            // MVP段階ではexitModel = "exit.none"のみサポート
            // 将来的にはStrategyに紐づくexitModelを適用
            // ApplyExitModel(ticket);

            // ナンピンモデル（Phase 4）
            // ApplyNanpinModel(ticket);
        }
    }

    //+------------------------------------------------------------------+
    //| ポジション数取得（全体）                                           |
    //+------------------------------------------------------------------+
    int GetTotalPositionCount() {
        int count = 0;
        for (int i = 0; i < PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;
            if (PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER) {
                count++;
            }
        }
        return count;
    }

    //+------------------------------------------------------------------+
    //| ポジション数取得（シンボル別）                                      |
    //+------------------------------------------------------------------+
    int GetSymbolPositionCount(string symbol) {
        int count = 0;
        for (int i = 0; i < PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;
            if (PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER &&
                PositionGetString(POSITION_SYMBOL) == symbol) {
                count++;
            }
        }
        return count;
    }

    //+------------------------------------------------------------------+
    //| ロングポジション数取得                                             |
    //+------------------------------------------------------------------+
    int GetLongPositionCount(string symbol) {
        int count = 0;
        for (int i = 0; i < PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;
            if (PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER &&
                PositionGetString(POSITION_SYMBOL) == symbol &&
                PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                count++;
            }
        }
        return count;
    }

    //+------------------------------------------------------------------+
    //| ショートポジション数取得                                            |
    //+------------------------------------------------------------------+
    int GetShortPositionCount(string symbol) {
        int count = 0;
        for (int i = 0; i < PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;
            if (PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER &&
                PositionGetString(POSITION_SYMBOL) == symbol &&
                PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                count++;
            }
        }
        return count;
    }

    //+------------------------------------------------------------------+
    //| ポジション制限チェック                                             |
    //+------------------------------------------------------------------+
    bool IsPositionLimitExceeded() {
        if (!m_hasConfig) return false;

        int totalPositions = GetTotalPositionCount();
        if (totalPositions >= m_config.globalGuards.maxPositionsTotal) {
            return true;
        }

        int symbolPositions = GetSymbolPositionCount(Symbol());
        if (symbolPositions >= m_config.globalGuards.maxPositionsPerSymbol) {
            return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| 状態情報を構築                                                     |
    //+------------------------------------------------------------------+
    void BuildStateInfo(StateInfo &state) {
        state.positionsTotal = GetTotalPositionCount();
        state.positionsBySymbol = GetSymbolPositionCount(Symbol());
        state.positionsLong = GetLongPositionCount(Symbol());
        state.positionsShort = GetShortPositionCount(Symbol());

        if (m_stateStore != NULL) {
            state.lastEntryBarTime = m_stateStore.GetLastEntryBarTime();
            state.nanpinCount = m_stateStore.GetNanpinCount();
        }
    }

    //+------------------------------------------------------------------+
    //| ExitModel適用（将来拡張）                                          |
    //+------------------------------------------------------------------+
    void ApplyExitModel(ulong ticket, const StrategyConfig &strategy) {
        if (strategy.exitModel.typeId == "exit.none") {
            // 何もしない
            return;
        }

        // exit.trailing（将来実装）
        // exit.breakeven（将来実装）
        // exit.avgProfit（将来実装）
        // exit.weekend（将来実装）
    }

    //+------------------------------------------------------------------+
    //| トレーリング適用（将来拡張）                                        |
    //+------------------------------------------------------------------+
    void ApplyTrailing(ulong ticket, double trailPips) {
        // 将来実装
        // if (m_logger != NULL) {
        //     m_logger.LogManagementAction("TRAILING", ticket,
        //         "Trail=" + DoubleToString(trailPips, 1) + " pips");
        // }
    }

    //+------------------------------------------------------------------+
    //| 建値移動適用（将来拡張）                                            |
    //+------------------------------------------------------------------+
    void ApplyBreakeven(ulong ticket, double triggerPips, double offsetPips) {
        // 将来実装
    }

    //+------------------------------------------------------------------+
    //| NanpinModel適用（Phase 4で実装）                                   |
    //+------------------------------------------------------------------+
    void ApplyNanpinModel(ulong ticket, const StrategyConfig &strategy) {
        if (strategy.nanpinModel.typeId == "nanpin.off") {
            // 何もしない
            return;
        }

        // ナンピン条件評価（将来実装）
        // 最大段数、逆行幅、シリーズ損切り等
    }

    //+------------------------------------------------------------------+
    //| ポジションをクローズ                                               |
    //+------------------------------------------------------------------+
    bool ClosePosition(ulong ticket, string reason) {
        if (!m_position.SelectByTicket(ticket)) {
            Print("PositionManager: Position not found - ", ticket);
            return false;
        }

        bool success = m_trade.PositionClose(ticket);

        if (success) {
            if (m_logger != NULL) {
                m_logger.LogManagementAction("CLOSE", ticket, reason);
            }
            Print("PositionManager: Position closed - ", ticket, " Reason: ", reason);
            return true;
        } else {
            Print("PositionManager: Failed to close position - ", ticket,
                  " Error: ", m_trade.ResultRetcode());
            return false;
        }
    }

    //+------------------------------------------------------------------+
    //| 全ポジションをクローズ（緊急用）                                     |
    //+------------------------------------------------------------------+
    void CloseAllPositions(string reason) {
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;

            if (PositionGetInteger(POSITION_MAGIC) == EA_MAGIC_NUMBER &&
                PositionGetString(POSITION_SYMBOL) == Symbol()) {
                ClosePosition(ticket, reason);
            }
        }
    }
};

#endif // POSITIONMANAGER_MQH
