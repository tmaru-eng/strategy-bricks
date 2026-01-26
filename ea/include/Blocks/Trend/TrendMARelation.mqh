//+------------------------------------------------------------------+
//|                                              TrendMARelation.mqh |
//|                                         Strategy Bricks EA MVP   |
//|            trend.maRelation - M1トレンド判定ブロック                 |
//+------------------------------------------------------------------+
#ifndef TRENDMARELATION_MQH
#define TRENDMARELATION_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| TrendMARelationクラス                                              |
//| M1の終値とMAの上下関係でトレンド判定                                  |
//+------------------------------------------------------------------+
class CTrendMARelation : public CBlockBase {
private:
    int            m_period;      // MA期間
    ENUM_MA_METHOD m_maType;      // MAタイプ
    string         m_relation;    // "closeAbove" | "closeBelow"
    int            m_handle;      // インジケータハンドル

public:
    //--- コンストラクタ
    CTrendMARelation(string blockId) : CBlockBase(blockId, "trend.maRelation") {
        m_period = 200;
        m_maType = MODE_EMA;
        m_relation = "closeAbove";
        m_handle = INVALID_HANDLE;
    }

    //--- デストラクタ
    virtual ~CTrendMARelation() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);

        m_period = GetParamInt(paramsJson, "period", 200);

        string maTypeStr = GetParamString(paramsJson, "maType", "EMA");
        m_maType = StringToMAMethod(maTypeStr);

        m_relation = GetParamString(paramsJson, "relation", "closeAbove");
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ハンドル取得（遅延生成）
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetMAHandle(ctx.market.symbol, EA_TIMEFRAME,
                                             m_period, 0, m_maType, PRICE_CLOSE);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "MA handle unavailable: period=" + IntegerToString(m_period));
            return;
        }

        // MA値取得（shift=1、確定足）
        double ma = ctx.cache.GetMAValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double close = ctx.market.close[0];  // Context内ではclose[0]がshift=1の終値

        // 判定
        bool pass = false;
        TradeDirection direction = DIRECTION_NEUTRAL;

        // "above"/"below"と"closeAbove"/"closeBelow"の両方に対応
        if (m_relation == "closeAbove" || m_relation == "above") {
            pass = (close > ma);
            direction = DIRECTION_LONG;
        } else if (m_relation == "closeBelow" || m_relation == "below") {
            pass = (close < ma);
            direction = DIRECTION_SHORT;
        }

        string reason = "Close[1]=" + DoubleToString(close, ctx.market.digits) +
                        " vs MA(" + IntegerToString(m_period) + ")[1]=" +
                        DoubleToString(ma, ctx.market.digits) +
                        " (" + m_relation + ")";

        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, direction, reason);
    }
};

#endif // TRENDMARELATION_MQH
