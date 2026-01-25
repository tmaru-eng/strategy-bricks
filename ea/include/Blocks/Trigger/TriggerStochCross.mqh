//+------------------------------------------------------------------+
//|                                             TriggerStochCross.mqh|
//|                                         Strategy Bricks EA MVP   |
//|      trigger.stochCross - ストキャスティクスクロス                 |
//+------------------------------------------------------------------+
#ifndef TRIGGERSTOCHCROSS_MQH
#define TRIGGERSTOCHCROSS_MQH

#include "../IBlock.mqh"

class CTriggerStochCross : public CBlockBase {
private:
    int    m_kPeriod;
    int    m_dPeriod;
    int    m_slowing;
    ENUM_MA_METHOD m_maMethod;
    ENUM_STO_PRICE m_priceField;
    string m_direction;
    int    m_handle;

public:
    CTriggerStochCross(string blockId) : CBlockBase(blockId, "trigger.stochCross") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_kPeriod = GetParamInt(paramsJson, "kPeriod", 5);
        m_dPeriod = GetParamInt(paramsJson, "dPeriod", 3);
        m_slowing = GetParamInt(paramsJson, "slowing", 3);
        
        string mStr = GetParamString(paramsJson, "maMethod", "SMA");
        m_maMethod = (mStr=="EMA") ? MODE_EMA : MODE_SMA;

        string pStr = GetParamString(paramsJson, "priceField", "LOWHIGH");
        m_priceField = (pStr=="CLOSECLOSE") ? STO_CLOSECLOSE : STO_LOWHIGH;

        m_direction = GetParamString(paramsJson, "direction", "golden");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetStochHandle(ctx.market.symbol, EA_TIMEFRAME, m_kPeriod, m_dPeriod, m_slowing, m_maMethod, m_priceField);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Stoch handle error");
            return;
        }

        // Buffer 0: MAIN, 1: SIGNAL
        double k1 = ctx.cache.GetStochValue(m_handle, 0, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double d1 = ctx.cache.GetStochValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double k2 = ctx.cache.GetStochValue(m_handle, 0, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        double d2 = ctx.cache.GetStochValue(m_handle, 1, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_direction == "golden") {
            if (k2 <= d2 && k1 > d1) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else {
            if (k2 >= d2 && k1 < d1) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("Stoch K=%.2f D=%.2f", k1, d1);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
