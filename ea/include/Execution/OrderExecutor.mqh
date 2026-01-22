//+------------------------------------------------------------------+
//|                                                OrderExecutor.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                               発注処理クラス（副作用集約）            |
//+------------------------------------------------------------------+
#ifndef ORDEREXECUTOR_MQH
#define ORDEREXECUTOR_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "../Support/Logger.mqh"
#include "../Support/StateStore.mqh"
#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| OrderExecutorクラス                                                |
//| 発注処理を集約し、同一足再エントリー禁止等のガードを実装                 |
//+------------------------------------------------------------------+
class COrderExecutor {
private:
    CStateStore* m_stateStore;      // 状態管理
    CLogger*     m_logger;          // ログ出力
    CTrade       m_trade;           // MT5取引クラス

    //+------------------------------------------------------------------+
    //| pips→価格変換                                                     |
    //+------------------------------------------------------------------+
    double PipsToPrice(string symbol, double pips) {
        // JPYペアの判定
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

        // 通常は10ポイント=1pips（5桁/3桁ブローカー）
        // 4桁/2桁ブローカーの場合は1ポイント=1pips
        double multiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;

        return pips * point * multiplier;
    }

    //+------------------------------------------------------------------+
    //| SL価格計算                                                        |
    //+------------------------------------------------------------------+
    double CalculateSLPrice(string symbol, double entryPrice, TradeDirection direction, double slPips) {
        if (slPips <= 0) return 0.0;

        double distance = PipsToPrice(symbol, slPips);

        if (direction == DIRECTION_LONG) {
            return entryPrice - distance;
        } else {
            return entryPrice + distance;
        }
    }

    //+------------------------------------------------------------------+
    //| TP価格計算                                                        |
    //+------------------------------------------------------------------+
    double CalculateTPPrice(string symbol, double entryPrice, TradeDirection direction, double tpPips) {
        if (tpPips <= 0) return 0.0;

        double distance = PipsToPrice(symbol, tpPips);

        if (direction == DIRECTION_LONG) {
            return entryPrice + distance;
        } else {
            return entryPrice - distance;
        }
    }

    //+------------------------------------------------------------------+
    //| ロット検証                                                        |
    //+------------------------------------------------------------------+
    bool ValidateLot(string symbol, double lot, string &reason) {
        double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

        if (lot < minLot) {
            reason = "Lot too small: " + DoubleToString(lot, 2) +
                    " (min=" + DoubleToString(minLot, 2) + ")";
            return false;
        }

        if (lot > maxLot) {
            reason = "Lot too large: " + DoubleToString(lot, 2) +
                    " (max=" + DoubleToString(maxLot, 2) + ")";
            return false;
        }

        // ロットステップ検証
        double remainder = MathMod(lot - minLot, lotStep);
        if (remainder > 0.0000001) {
            // ロットを正規化
            lot = MathFloor((lot - minLot) / lotStep) * lotStep + minLot;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| SL/TP検証                                                        |
    //+------------------------------------------------------------------+
    bool ValidateSLTP(string symbol, double price, double sl, double tp,
                      TradeDirection direction, string &reason) {
        int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double minDistance = stopsLevel * point;

        // SL距離チェック
        if (sl != 0.0 && MathAbs(price - sl) < minDistance) {
            reason = "SL too close: " + DoubleToString(sl, 5) +
                    " (min distance=" + DoubleToString(minDistance, 5) + ")";
            return false;
        }

        // TP距離チェック
        if (tp != 0.0 && MathAbs(price - tp) < minDistance) {
            reason = "TP too close: " + DoubleToString(tp, 5) +
                    " (min distance=" + DoubleToString(minDistance, 5) + ")";
            return false;
        }

        // SL方向チェック
        if (direction == DIRECTION_LONG && sl != 0.0 && sl >= price) {
            reason = "Invalid SL for LONG: SL=" + DoubleToString(sl, 5) +
                    " >= Entry=" + DoubleToString(price, 5);
            return false;
        }

        if (direction == DIRECTION_SHORT && sl != 0.0 && sl <= price) {
            reason = "Invalid SL for SHORT: SL=" + DoubleToString(sl, 5) +
                    " <= Entry=" + DoubleToString(price, 5);
            return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| 価格の正規化                                                       |
    //+------------------------------------------------------------------+
    double NormalizePrice(string symbol, double price) {
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        return NormalizeDouble(price, digits);
    }

public:
    //--- コンストラクタ
    COrderExecutor() {
        m_stateStore = NULL;
        m_logger = NULL;
    }

    //--- デストラクタ
    ~COrderExecutor() {}

    //--- 依存性注入
    void SetStateStore(CStateStore* stateStore) {
        m_stateStore = stateStore;
    }

    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }

    //+------------------------------------------------------------------+
    //| 初期化                                                            |
    //+------------------------------------------------------------------+
    void Initialize() {
        m_trade.SetExpertMagicNumber(EA_MAGIC_NUMBER);
        m_trade.SetDeviationInPoints(ORDER_DEVIATION);
        m_trade.SetTypeFilling(ORDER_FILL_POLICY);
        Print("OrderExecutor: Initialized");
    }

    //+------------------------------------------------------------------+
    //| 発注実行（同期）                                                   |
    //+------------------------------------------------------------------+
    bool Execute(const OrderRequest &request, OrderResult &result) {
        result.Reset();

        // ログ：発注試行
        if (m_logger != NULL) {
            m_logger.LogOrderAttempt(request);
        }

        // 1. 同一足再エントリーチェック（第二ガード）
        if (m_stateStore != NULL) {
            if (m_stateStore.IsSameBarAsLastEntry(request.barTime)) {
                string rejectReason = "Same bar re-entry is prohibited";
                if (m_logger != NULL) {
                    m_logger.LogOrderReject("SAME_BAR_REENTRY", rejectReason);
                }
                result.rejectReason = rejectReason;
                return false;
            }
        }

        // 2. ロット検証
        string reason;
        double lot = request.lot;
        if (!ValidateLot(request.symbol, lot, reason)) {
            if (m_logger != NULL) {
                m_logger.LogOrderReject("INVALID_LOT", reason);
            }
            result.rejectReason = reason;
            return false;
        }

        // 3. エントリー価格取得
        double entryPrice;
        if (request.direction == DIRECTION_LONG) {
            entryPrice = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        } else {
            entryPrice = SymbolInfoDouble(request.symbol, SYMBOL_BID);
        }

        // 4. SL/TP価格計算
        double slPrice = (request.slPrice != 0.0) ? request.slPrice :
                        CalculateSLPrice(request.symbol, entryPrice, request.direction, request.slPips);
        double tpPrice = (request.tpPrice != 0.0) ? request.tpPrice :
                        CalculateTPPrice(request.symbol, entryPrice, request.direction, request.tpPips);

        // 価格の正規化
        slPrice = NormalizePrice(request.symbol, slPrice);
        tpPrice = NormalizePrice(request.symbol, tpPrice);

        // 5. SL/TP検証
        if (!ValidateSLTP(request.symbol, entryPrice, slPrice, tpPrice, request.direction, reason)) {
            if (m_logger != NULL) {
                m_logger.LogOrderReject("INVALID_SLTP", reason);
            }
            result.rejectReason = reason;
            return false;
        }

        // 6. 発注実行
        bool success;
        if (request.direction == DIRECTION_LONG) {
            success = m_trade.Buy(lot, request.symbol, 0.0, slPrice, tpPrice, request.comment);
        } else {
            success = m_trade.Sell(lot, request.symbol, 0.0, slPrice, tpPrice, request.comment);
        }

        // 7. 結果処理
        uint retcode = m_trade.ResultRetcode();
        result.retcode = (int)retcode;
        result.ticket = m_trade.ResultOrder();
        result.comment = m_trade.ResultComment();

        if (success && retcode == TRADE_RETCODE_DONE) {
            // 成功：lastEntryBarTime更新
            if (m_stateStore != NULL) {
                m_stateStore.SetLastEntryBarTime(request.barTime);
            }
            result.success = true;
            if (m_logger != NULL) {
                m_logger.LogOrderResult(true, result.ticket, "");
            }
            Print("OrderExecutor: Order placed successfully - Ticket=", result.ticket,
                  " Lot=", lot, " SL=", slPrice, " TP=", tpPrice);
            return true;
        } else {
            // 失敗：理由ログ
            string failReason = "RetCode: " + IntegerToString(retcode) +
                               ", Comment: " + result.comment;
            result.rejectReason = failReason;
            if (m_logger != NULL) {
                m_logger.LogOrderResult(false, 0, failReason);
            }
            Print("OrderExecutor: Order failed - ", failReason);
            return false;
        }
    }
};

#endif // ORDEREXECUTOR_MQH
