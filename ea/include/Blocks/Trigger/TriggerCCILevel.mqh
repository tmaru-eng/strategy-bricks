//+------------------------------------------------------------------+
//|                                              TriggerCCILevel.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trigger.cciLevel                                            |
//+------------------------------------------------------------------+
#ifndef TRIGGERCCILEVEL_MQH
#define TRIGGERCCILEVEL_MQH

#include "../IBlock.mqh"

class CTriggerCCILevel : public CBlockBase {
private:
    int    m_period;
    double m_threshold;
    string m_mode;
    int    m_handle;

public:
    CTriggerCCILevel(string blockId) : CBlockBase(blockId, "trigger.cciLevel") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        m_threshold = GetParamDouble(paramsJson, "threshold", 100);
        m_mode = GetParamString(paramsJson, "mode", "overbought");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetCCIHandle(ctx.market.symbol, EA_TIMEFRAME, m_period, PRICE_CLOSE); // Simplified price
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "CCI handle error");
            return;
        }

        double v1 = ctx.cache.GetCCIValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double v2 = ctx.cache.GetCCIValue(m_handle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_mode == "overbought") { // Cross down below threshold
            if (v2 >= m_threshold && v1 < m_threshold) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        } else { // oversold (e.g. -100): Cross up above threshold
            if (v2 <= m_threshold && v1 > m_threshold) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        }

        string reason = StringFormat("CCI=%.2f Thr=%.2f", v1, m_threshold);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
