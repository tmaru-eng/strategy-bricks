//+------------------------------------------------------------------+
//|                                             TriggerMACDCross.mqh |
//|                                         Strategy Bricks EA MVP   |
//|      trigger.macdCross - MACDクロス                              |
//+------------------------------------------------------------------+
#ifndef TRIGGERMACDCROSS_MQH
#define TRIGGERMACDCROSS_MQH

#include "../IBlock.mqh"

class CTriggerMACDCross : public CBlockBase {
private:
    int    m_fastEma;
    int    m_slowEma;
    int    m_signal;
    ENUM_APPLIED_PRICE m_appliedPrice;
    string m_direction;
    int    m_handle;

public:
    CTriggerMACDCross(string blockId) : CBlockBase(blockId, "trigger.macdCross") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_fastEma = GetParamInt(paramsJson, "fastEma", 12);
        m_slowEma = GetParamInt(paramsJson, "slowEma", 26);
        m_signal = GetParamInt(paramsJson, "signal", 9);
        
        string pStr = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if (pStr=="OPEN") m_appliedPrice=PRICE_OPEN;
        else if (pStr=="LOW") m_appliedPrice=PRICE_LOW;
        else if (pStr=="HIGH") m_appliedPrice=PRICE_HIGH;
        else m_appliedPrice=PRICE_CLOSE;

        m_direction = GetParamString(paramsJson, "direction", "golden");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetMACDHandle(ctx.market.symbol, EA_TIMEFRAME, m_fastEma, m_slowEma, m_signal, m_appliedPrice);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "MACD handle error");
            return;
        }

        // Buffer 0: MAIN, 1: SIGNAL
        double main1 = ctx.cache.GetMACDValue(m_handle, 0, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double sig1  = ctx.cache.GetMACDValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double main2 = ctx.cache.GetMACDValue(m_handle, 0, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        double sig2  = ctx.cache.GetMACDValue(m_handle, 1, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_direction == "golden") { // Main crosses Signal Upward
            if (main2 <= sig2 && main1 > sig1) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else { // Dead: Main crosses Signal Downward
            if (main2 >= sig2 && main1 < sig1) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("MACD Main=%.5f Sig=%.5f", main1, sig1);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
