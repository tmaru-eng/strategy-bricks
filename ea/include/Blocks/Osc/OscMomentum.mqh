//+------------------------------------------------------------------+
//|                                              OscMomentum.mqh     |
//|      osc.momentum                                                |
//+------------------------------------------------------------------+
#ifndef OSCMOMENTUM_MQH
#define OSCMOMENTUM_MQH

#include "../IBlock.mqh"

class COscMomentum : public CBlockBase {
private:
    int    m_period;
    ENUM_APPLIED_PRICE m_appliedPrice;
    string m_comparison; // above, below
    double m_threshold;
    int    m_handle;

public:
    COscMomentum(string blockId) : CBlockBase(blockId, "osc.momentum") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        string p = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if(p=="OPEN") m_appliedPrice=PRICE_OPEN;
        else if(p=="HIGH") m_appliedPrice=PRICE_HIGH;
        else if(p=="LOW") m_appliedPrice=PRICE_LOW;
        else m_appliedPrice=PRICE_CLOSE;

        m_comparison = GetParamString(paramsJson, "comparison", "above");
        m_threshold = GetParamDouble(paramsJson, "threshold", 100.0);
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetMomentumHandle(ctx.market.symbol, EA_TIMEFRAME, m_period, m_appliedPrice);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Momentum handle error");
            return;
        }

        double val = ctx.cache.GetMomentumValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        bool pass = false;

        if (m_comparison == "above") {
            if (val > m_threshold) pass = true;
        } else {
            if (val < m_threshold) pass = true;
        }

        string reason = StringFormat("Mom=%.2f Thr=%.2f", val, m_threshold);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, reason);
    }
};

#endif
