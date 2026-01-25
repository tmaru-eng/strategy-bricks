//+------------------------------------------------------------------+
//|                                              TriggerWPRLevel.mqh |
//+------------------------------------------------------------------+
#ifndef TRIGGERWPRLEVEL_MQH
#define TRIGGERWPRLEVEL_MQH

#include "../IBlock.mqh"

class CTriggerWPRLevel : public CBlockBase {
private:
    int    m_period;
    double m_threshold;
    string m_mode;
    int    m_handle;

public:
    CTriggerWPRLevel(string blockId) : CBlockBase(blockId, "trigger.wprLevel") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        m_threshold = GetParamDouble(paramsJson, "threshold", -20.0);
        m_mode = GetParamString(paramsJson, "mode", "overbought");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetWPRHandle(ctx.market.symbol, EA_TIMEFRAME, m_period);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "WPR handle error");
            return;
        }

        double v1 = ctx.cache.GetWPRValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double v2 = ctx.cache.GetWPRValue(m_handle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_mode == "overbought") { // e.g. -20. Cross down (-10 -> -30)
            if (v2 > m_threshold && v1 <= m_threshold) { // Note: WPR uses > for "closer to 0"
                pass = true;
                dir = DIRECTION_SHORT;
            }
        } else { // oversold e.g. -80. Cross up (-90 -> -70)
            if (v2 < m_threshold && v1 >= m_threshold) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        }

        string reason = StringFormat("WPR=%.2f Thr=%.2f", v1, m_threshold);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
