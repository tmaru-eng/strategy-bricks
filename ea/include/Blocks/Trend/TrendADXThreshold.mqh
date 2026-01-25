//+------------------------------------------------------------------+
//|                                          TrendADXThreshold.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|      trend.adxThreshold - ADXトレンド強度判定                      |
//+------------------------------------------------------------------+
#ifndef TRENDADXTHRESHOLD_MQH
#define TRENDADXTHRESHOLD_MQH

#include "../IBlock.mqh"

class CTrendADXThreshold : public CBlockBase {
private:
    int    m_period;
    double m_minAdx;
    int    m_handle;

public:
    CTrendADXThreshold(string blockId) : CBlockBase(blockId, "trend.adxThreshold") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 14);
        m_minAdx = GetParamDouble(paramsJson, "minAdx", 25.0);
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetADXHandle(ctx.market.symbol, EA_TIMEFRAME, m_period);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "ADX handle error");
            return;
        }

        // Buffer 0: MAIN
        double adx = ctx.cache.GetADXValue(m_handle, 0, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        // Checking directional movement could be added (+DI vs -DI) but this block is just Threshold
        // To provide Direction info, we should check +DI vs -DI
        double pdi = ctx.cache.GetADXValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double mdi = ctx.cache.GetADXValue(m_handle, 2, CONFIRMED_BAR_SHIFT, ctx.state.barTime);

        bool pass = (adx >= m_minAdx);
        TradeDirection dir = DIRECTION_NEUTRAL;
        
        if (pass) {
            if (pdi > mdi) dir = DIRECTION_LONG;
            else if (mdi > pdi) dir = DIRECTION_SHORT;
        }

        string reason = StringFormat("ADX=%.2f (Min %.2f) +DI=%.2f -DI=%.2f", adx, m_minAdx, pdi, mdi);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
