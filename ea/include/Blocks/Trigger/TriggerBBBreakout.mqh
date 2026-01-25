//+------------------------------------------------------------------+
//|                                            TriggerBBBreakout.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trigger.bbBreakout - ボリンジャーバンドブレイク                 |
//+------------------------------------------------------------------+
#ifndef TRIGGERBBBREAKOUT_MQH
#define TRIGGERBBBREAKOUT_MQH

#include "../IBlock.mqh"

class CTriggerBBBreakout : public CBlockBase {
private:
    int    m_period;
    double m_deviation;
    int    m_bandsShift;
    ENUM_APPLIED_PRICE m_appliedPrice;
    string m_side; // "upper", "lower"
    int    m_handle;

public:
    CTriggerBBBreakout(string blockId) : CBlockBase(blockId, "trigger.bbBreakout") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 20);
        m_deviation = GetParamDouble(paramsJson, "deviation", 2.0);
        m_bandsShift = GetParamInt(paramsJson, "bandsShift", 0);
        m_side = GetParamString(paramsJson, "direction", "upper"); // JSON uses "direction"

        string priceStr = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if (priceStr == "OPEN") m_appliedPrice = PRICE_OPEN;
        else if (priceStr == "HIGH") m_appliedPrice = PRICE_HIGH;
        else if (priceStr == "LOW") m_appliedPrice = PRICE_LOW;
        else m_appliedPrice = PRICE_CLOSE;
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetBBHandle(ctx.market.symbol, EA_TIMEFRAME, m_period, m_bandsShift, m_deviation, m_appliedPrice);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "BB handle error");
            return;
        }

        // Check for breakout: Previous close inside, Current close outside
        // Or simple state: Current close outside? Usually triggers are events.
        // Assuming confirmation on closed bar (shift=1).
        // Breakout event: Close[2] inside/below, Close[1] outside/above.
        
        double upper1 = ctx.cache.GetBBValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double lower1 = ctx.cache.GetBBValue(m_handle, 2, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double upper2 = ctx.cache.GetBBValue(m_handle, 1, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        double lower2 = ctx.cache.GetBBValue(m_handle, 2, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        double close1 = ctx.market.close[0]; // shift=1
        double close2Buffer[];
        if (!ctx.cache.CopyBufferSafe(0 /*price*/, 0, CONFIRMED_BAR_SHIFT + 1, 1, close2Buffer)) {
             // Fallback for price copy? Using CopyClose directly.
             // Actually ctx should provide history access helper?
             // Using direct CopyClose for now as in previous block.
        }
        // Direct CopyClose
        double close2 = 0.0;
        double c2b[]; ArraySetAsSeries(c2b, true);
        if (CopyClose(ctx.market.symbol, EA_TIMEFRAME, CONFIRMED_BAR_SHIFT + 1, 1, c2b) > 0) close2 = c2b[0];

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_side == "upper") {
            // Breakout UP: Close[2] <= Upper[2] AND Close[1] > Upper[1]
            if (close2 <= upper2 && close1 > upper1) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else {
            // Breakout DOWN: Close[2] >= Lower[2] AND Close[1] < Lower[1]
            if (close2 >= lower2 && close1 < lower1) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("Close[1]=%.3f BB[%s][1]=%.3f", close1, m_side, (m_side=="upper"?upper1:lower1));
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
