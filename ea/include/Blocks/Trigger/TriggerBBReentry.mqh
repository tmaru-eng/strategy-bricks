//+------------------------------------------------------------------+
//|                                             TriggerBBReentry.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trigger.bbReentry - ボリンジャーバンド回帰トリガーブロック        |
//+------------------------------------------------------------------+
#ifndef TRIGGERBBREENTRY_MQH
#define TRIGGERBBREENTRY_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| TriggerBBReentryクラス                                             |
//| 確定足で外→内回帰をトリガーとする                                     |
//+------------------------------------------------------------------+
class CTriggerBBReentry : public CBlockBase {
private:
    int    m_period;        // BB期間
    double m_deviation;     // 偏差
    string m_side;          // "lowerToInside" | "upperToInside"
    int    m_handle;        // インジケータハンドル

public:
    //--- コンストラクタ
    CTriggerBBReentry(string blockId) : CBlockBase(blockId, "trigger.bbReentry") {
        m_period = 20;
        m_deviation = 2.0;
        m_side = "lowerToInside";
        m_handle = INVALID_HANDLE;
    }

    //--- デストラクタ
    virtual ~CTriggerBBReentry() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);

        m_period = GetParamInt(paramsJson, "period", 20);
        m_deviation = GetParamDouble(paramsJson, "deviation", 2.0);
        m_side = GetParamString(paramsJson, "side", "lowerToInside");
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // BBハンドル取得（遅延生成）
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetBBHandle(ctx.market.symbol, EA_TIMEFRAME,
                                             m_period, 0, m_deviation, PRICE_CLOSE);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "BB handle unavailable: period=" + IntegerToString(m_period));
            return;
        }

        // BB値取得（buffer: 0=middle, 1=upper, 2=lower）
        // shift=1（現在の確定足）とshift=2（1つ前の確定足）
        double upper1 = ctx.cache.GetBBValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double lower1 = ctx.cache.GetBBValue(m_handle, 2, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double upper2 = ctx.cache.GetBBValue(m_handle, 1, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        double lower2 = ctx.cache.GetBBValue(m_handle, 2, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        // 終値取得（shift=1, shift=2）
        double close1 = ctx.market.close[0];  // shift=1

        // shift=2の終値を取得
        double close2Buffer[];
        ArraySetAsSeries(close2Buffer, true);
        if (CopyClose(ctx.market.symbol, EA_TIMEFRAME, CONFIRMED_BAR_SHIFT + 1, 1, close2Buffer) <= 0) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Failed to get close[2]");
            return;
        }
        double close2 = close2Buffer[0];

        // 回帰判定
        bool pass = false;
        TradeDirection direction = DIRECTION_NEUTRAL;
        string sideDesc = "";

        if (m_side == "lowerToInside") {
            // 前足が下限外、現足が内側 → ロングシグナル
            if (close2 < lower2 && close1 >= lower1) {
                pass = true;
                direction = DIRECTION_LONG;
                sideDesc = "lower reentry";
            }
        } else if (m_side == "upperToInside") {
            // 前足が上限外、現足が内側 → ショートシグナル
            if (close2 > upper2 && close1 <= upper1) {
                pass = true;
                direction = DIRECTION_SHORT;
                sideDesc = "upper reentry";
            }
        }

        string reason = "BB(" + IntegerToString(m_period) + "," +
                        DoubleToString(m_deviation, 1) + "): " +
                        "close[2]=" + DoubleToString(close2, ctx.market.digits) +
                        ", close[1]=" + DoubleToString(close1, ctx.market.digits);

        if (m_side == "lowerToInside") {
            reason += ", lower[2]=" + DoubleToString(lower2, ctx.market.digits) +
                      ", lower[1]=" + DoubleToString(lower1, ctx.market.digits);
        } else {
            reason += ", upper[2]=" + DoubleToString(upper2, ctx.market.digits) +
                      ", upper[1]=" + DoubleToString(upper1, ctx.market.digits);
        }

        reason += " (" + m_side + ")";

        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, direction, reason);
    }
};

#endif // TRIGGERBBREENTRY_MQH
