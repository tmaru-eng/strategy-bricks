//+------------------------------------------------------------------+
//|                                             FilterAtrRange.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|      filter.volatility.atrRange - ATR範囲フィルタ                  |
//+------------------------------------------------------------------+
#ifndef FILTERATRRANGE_MQH
#define FILTERATRRANGE_MQH

#include "../IBlock.mqh"

class CFilterAtrRange : public CBlockBase {
private:
    int    m_period;
    double m_minAtr;
    double m_maxAtr;
    int    m_handle;

public:
    CFilterAtrRange(string blockId) : CBlockBase(blockId, "filter.volatility.atrRange") {
        m_period = 14;
        m_minAtr = 0;
        m_maxAtr = 100;
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        m_minAtr = GetParamDouble(paramsJson, "minAtr", 0);
        m_maxAtr = GetParamDouble(paramsJson, "maxAtr", 100);
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetATRHandle(ctx.market.symbol, EA_TIMEFRAME, m_period);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "ATR handle error");
            return;
        }

        double atr = ctx.cache.GetATRValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        
        bool pass = (atr >= m_minAtr && atr <= m_maxAtr);
        string reason = StringFormat("ATR(14)=%.5f Range[%.5f, %.5f]", atr, m_minAtr, m_maxAtr);
        
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, reason);
    }
};

#endif
