//+------------------------------------------------------------------+
//|                                               TriggerSARFlip.mqh |
//|      trigger.sarFlip - SAR反転                                   |
//+------------------------------------------------------------------+
#ifndef TRIGGERSARFLIP_MQH
#define TRIGGERSARFLIP_MQH

#include "../IBlock.mqh"

class CTriggerSARFlip : public CBlockBase {
private:
    double m_step;
    double m_maximum;
    int    m_handle;

public:
    CTriggerSARFlip(string blockId) : CBlockBase(blockId, "trigger.sarFlip") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_step = GetParamDouble(paramsJson, "step", 0.02);
        m_maximum = GetParamDouble(paramsJson, "maximum", 0.2);
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetSARHandle(ctx.market.symbol, EA_TIMEFRAME, m_step, m_maximum);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "SAR handle error");
            return;
        }

        double sar1 = ctx.cache.GetSARValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double sar2 = ctx.cache.GetSARValue(m_handle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        
        double close1 = ctx.market.close[0];
        // Need close2
        double c2b[]; ArraySetAsSeries(c2b, true);
        double close2 = 0;
        if(CopyClose(ctx.market.symbol, EA_TIMEFRAME, CONFIRMED_BAR_SHIFT+1, 1, c2b)>0) close2=c2b[0];

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        // Flip Bullish: Prev (SAR > Close), Curr (SAR < Close)
        if (sar2 > close2 && sar1 < close1) {
            pass = true;
            dir = DIRECTION_LONG;
        }
        // Flip Bearish: Prev (SAR < Close), Curr (SAR > Close)
        else if (sar2 < close2 && sar1 > close1) {
            pass = true;
            dir = DIRECTION_SHORT;
        }

        string reason = StringFormat("SAR Flip C1=%.3f S1=%.3f", close1, sar1);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
