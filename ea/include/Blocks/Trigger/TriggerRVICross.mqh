//+------------------------------------------------------------------+
//|                                              TriggerRVICross.mqh |
//+------------------------------------------------------------------+
#ifndef TRIGGERRVICROSS_MQH
#define TRIGGERRVICROSS_MQH

#include "../IBlock.mqh"

class CTriggerRVICross : public CBlockBase {
private:
    int    m_period;
    string m_direction;
    int    m_handle;

public:
    CTriggerRVICross(string blockId) : CBlockBase(blockId, "trigger.rviCross") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 10);
        m_direction = GetParamString(paramsJson, "direction", "golden");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetRVIHandle(ctx.market.symbol, EA_TIMEFRAME, m_period);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "RVI handle error");
            return;
        }

        // Buffer 0: Main, 1: Signal
        double m1 = ctx.cache.GetRVIValue(m_handle, 0, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double s1 = ctx.cache.GetRVIValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double m2 = ctx.cache.GetRVIValue(m_handle, 0, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        double s2 = ctx.cache.GetRVIValue(m_handle, 1, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_direction == "golden") {
            if (m2 <= s2 && m1 > s1) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else {
            if (m2 >= s2 && m1 < s1) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("RVI M=%.4f S=%.4f", m1, s1);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
