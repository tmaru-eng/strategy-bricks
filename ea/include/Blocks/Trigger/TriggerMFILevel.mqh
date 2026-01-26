//+------------------------------------------------------------------+
//|                                              TriggerMFILevel.mqh |
//+------------------------------------------------------------------+
#ifndef TRIGGERMFILEVEL_MQH
#define TRIGGERMFILEVEL_MQH

#include "../IBlock.mqh"

class CTriggerMFILevel : public CBlockBase {
private:
    int    m_period;
    double m_threshold;
    ENUM_APPLIED_VOLUME m_volume;
    string m_mode;
    int    m_handle;

public:
    CTriggerMFILevel(string blockId) : CBlockBase(blockId, "trigger.mfiLevel") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        m_threshold = GetParamDouble(paramsJson, "threshold", 80);
        string v = GetParamString(paramsJson, "appliedVolume", "TICK");
        m_volume = (v=="REAL") ? VOLUME_REAL : VOLUME_TICK;
        m_mode = GetParamString(paramsJson, "mode", "overbought");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetMFIHandle(ctx.market.symbol, EA_TIMEFRAME, m_period, m_volume);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "MFI handle error");
            return;
        }

        double v1 = ctx.cache.GetMFIValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double v2 = ctx.cache.GetMFIValue(m_handle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_mode == "overbought") {
            if (v2 >= m_threshold && v1 < m_threshold) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        } else {
            if (v2 <= m_threshold && v1 > m_threshold) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        }

        string reason = StringFormat("MFI=%.2f Thr=%.2f", v1, m_threshold);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
