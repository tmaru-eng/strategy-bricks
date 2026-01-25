//+------------------------------------------------------------------+
//|                                            TrendSARDirection.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trend.sarDirection - パラボリックSAR方向判定                   |
//+------------------------------------------------------------------+
#ifndef TRENDSARDIRECTION_MQH
#define TRENDSARDIRECTION_MQH

#include "../IBlock.mqh"

class CTrendSARDirection : public CBlockBase {
private:
    double m_step;
    double m_maximum;
    string m_direction; // bullish, bearish
    int    m_handle;

public:
    CTrendSARDirection(string blockId) : CBlockBase(blockId, "trend.sarDirection") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_step = GetParamDouble(paramsJson, "step", 0.02);
        m_maximum = GetParamDouble(paramsJson, "maximum", 0.2);
        m_direction = GetParamString(paramsJson, "direction", "bullish");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetSARHandle(ctx.market.symbol, EA_TIMEFRAME, m_step, m_maximum);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "SAR handle error");
            return;
        }

        double sar = ctx.cache.GetSARValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double close = ctx.market.close[0];

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_direction == "bullish") {
            if (close > sar) { // SAR below price = Bullish
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else { // bearish
            if (close < sar) { // SAR above price = Bearish
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("Close=%.5f SAR=%.5f (%s)", close, sar, pass ? "Match" : "NoMatch");
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
