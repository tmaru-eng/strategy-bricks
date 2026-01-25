//+------------------------------------------------------------------+
//|                                           TrendIchimokuCloud.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trend.ichimokuCloud - 一目均衡表（雲）判定                     |
//+------------------------------------------------------------------+
#ifndef TRENDICHIMOKUCLOUD_MQH
#define TRENDICHIMOKUCLOUD_MQH

#include "../IBlock.mqh"

class CTrendIchimokuCloud : public CBlockBase {
private:
    int    m_tenkan;
    int    m_kijun;
    int    m_senkouB;
    string m_position; // above, inside, below
    int    m_handle;

public:
    CTrendIchimokuCloud(string blockId) : CBlockBase(blockId, "trend.ichimokuCloud") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_tenkan = GetParamInt(paramsJson, "tenkan", 9);
        m_kijun = GetParamInt(paramsJson, "kijun", 26);
        m_senkouB = GetParamInt(paramsJson, "senkouB", 52);
        m_position = GetParamString(paramsJson, "position", "above");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetIchimokuHandle(ctx.market.symbol, EA_TIMEFRAME, m_tenkan, m_kijun, m_senkouB);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Ichimoku handle error");
            return;
        }

        // Buffer 2: Senkou A, 3: Senkou B
        double spanA = ctx.cache.GetIchimokuValue(m_handle, 2, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double spanB = ctx.cache.GetIchimokuValue(m_handle, 3, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double close = ctx.market.close[0]; // shift=1 from Context

        double cloudTop = MathMax(spanA, spanB);
        double cloudBottom = MathMin(spanA, spanB);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_position == "above") {
            if (close > cloudTop) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else if (m_position == "below") {
            if (close < cloudBottom) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        } else { // inside
            if (close >= cloudBottom && close <= cloudTop) {
                pass = true;
                // direction ambiguous inside cloud, keep neutral or use context?
                // keeping neutral for now
            }
        }

        string reason = StringFormat("Close=%.3f Cloud[%.3f, %.3f]", close, cloudBottom, cloudTop);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
