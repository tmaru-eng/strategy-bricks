//+------------------------------------------------------------------+
//|                                                  OscOsMA.mqh     |
//|      osc.osma - Moving Average of Oscillator                     |
//+------------------------------------------------------------------+
#ifndef OSCOSMA_MQH
#define OSCOSMA_MQH

#include "../IBlock.mqh"

class COscOsMA : public CBlockBase {
private:
    int    m_fastEma;
    int    m_slowEma;
    int    m_signal;
    ENUM_APPLIED_PRICE m_appliedPrice;
    string m_comparison; // aboveZero, belowZero
    int    m_handle;

public:
    COscOsMA(string blockId) : CBlockBase(blockId, "osc.osma") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_fastEma = GetParamInt(paramsJson, "fastEma", 12);
        m_slowEma = GetParamInt(paramsJson, "slowEma", 26);
        m_signal = GetParamInt(paramsJson, "signal", 9);
        
        string p = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if(p=="OPEN") m_appliedPrice=PRICE_OPEN;
        else m_appliedPrice=PRICE_CLOSE;

        m_comparison = GetParamString(paramsJson, "comparison", "aboveZero");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetOsMAHandle(ctx.market.symbol, EA_TIMEFRAME, m_fastEma, m_slowEma, m_signal, m_appliedPrice);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "OsMA handle error");
            return;
        }

        double val = ctx.cache.GetOsMAValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        bool pass = false;

        if (m_comparison == "aboveZero") {
            if (val > 0) pass = true;
        } else {
            if (val < 0) pass = true;
        }

        string reason = StringFormat("OsMA=%.5f", val);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, reason);
    }
};

#endif
