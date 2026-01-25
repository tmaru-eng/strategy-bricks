//+------------------------------------------------------------------+
//|                                              TriggerRSILevel.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trigger.rsiLevel - RSIレベル判定                              |
//+------------------------------------------------------------------+
#ifndef TRIGGERRSILEVEL_MQH
#define TRIGGERRSILEVEL_MQH

#include "../IBlock.mqh"

class CTriggerRSILevel : public CBlockBase {
private:
    int    m_period;
    ENUM_APPLIED_PRICE m_appliedPrice;
    double m_threshold;
    string m_mode; // "overbought", "oversold"
    int    m_handle;

public:
    CTriggerRSILevel(string blockId) : CBlockBase(blockId, "trigger.rsiLevel") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        m_threshold = GetParamDouble(paramsJson, "threshold", 70);
        m_mode = GetParamString(paramsJson, "mode", "overbought");
        m_appliedPrice = PRICE_CLOSE; // Simply default or parse
        string p = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if(p=="OPEN") m_appliedPrice=PRICE_OPEN;
        // ... (simplified) ...
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetRSIHandle(ctx.market.symbol, EA_TIMEFRAME, m_period, m_appliedPrice);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "RSI handle error");
            return;
        }

        double rsi1 = ctx.cache.GetRSIValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double rsi2 = ctx.cache.GetRSIValue(m_handle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_mode == "overbought") {
            // Cross below threshold from above? Or just be above?
            // "Trigger" implies event. Let's assume Cross Below Threshold (Reversal signal)
            // Typically "Overbought" trigger means "Sell when returning from overbought".
            // So: RSI[2] >= Threshold and RSI[1] < Threshold -> Short
            if (rsi2 >= m_threshold && rsi1 < m_threshold) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        } else { // oversold
            // Cross above threshold from below -> Long
            if (rsi2 <= m_threshold && rsi1 > m_threshold) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        }

        string reason = StringFormat("RSI=%.2f Thr=%.2f", rsi1, m_threshold);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
