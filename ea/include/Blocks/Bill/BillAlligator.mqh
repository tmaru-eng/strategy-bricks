//+------------------------------------------------------------------+
//|                                              BillAlligator.mqh   |
//|      bill.alligator - アリゲーター                                 |
//+------------------------------------------------------------------+
#ifndef BILLALLIGATOR_MQH
#define BILLALLIGATOR_MQH

#include "../IBlock.mqh"

class CBillAlligator : public CBlockBase {
private:
    int m_jawPeriod, m_jawShift;
    int m_teethPeriod, m_teethShift;
    int m_lipsPeriod, m_lipsShift;
    ENUM_MA_METHOD m_maMethod;
    ENUM_APPLIED_PRICE m_appliedPrice;
    string m_trend; // uptrend, downtrend
    int m_handle;

public:
    CBillAlligator(string blockId) : CBlockBase(blockId, "bill.alligator") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_jawPeriod = GetParamInt(paramsJson, "jawPeriod", 13);
        m_jawShift = 8; // Default shifts usually fixed or parameterized? JSON has no shift params. Using defaults.
        m_teethPeriod = GetParamInt(paramsJson, "teethPeriod", 8);
        m_teethShift = 5;
        m_lipsPeriod = GetParamInt(paramsJson, "lipsPeriod", 5);
        m_lipsShift = 3;
        
        string mStr = GetParamString(paramsJson, "maMethod", "SMMA");
        if(mStr=="EMA") m_maMethod=MODE_EMA;
        else if(mStr=="SMA") m_maMethod=MODE_SMA;
        else if(mStr=="LWMA") m_maMethod=MODE_LWMA;
        else m_maMethod=MODE_SMMA; 

        string pStr = GetParamString(paramsJson, "appliedPrice", "MEDIAN");
        if(pStr=="CLOSE") m_appliedPrice=PRICE_CLOSE;
        else if(pStr=="OPEN") m_appliedPrice=PRICE_OPEN;
        else if(pStr=="HIGH") m_appliedPrice=PRICE_HIGH;
        else if(pStr=="LOW") m_appliedPrice=PRICE_LOW;
        else m_appliedPrice=PRICE_MEDIAN;

        m_trend = GetParamString(paramsJson, "trend", "uptrend");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetAlligatorHandle(ctx.market.symbol, EA_TIMEFRAME, 
                m_jawPeriod, m_jawShift, m_teethPeriod, m_teethShift, m_lipsPeriod, m_lipsShift, 
                m_maMethod, m_appliedPrice);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Alligator handle error");
            return;
        }

        // Buffer 0: Jaw (Blue), 1: Teeth (Red), 2: Lips (Green)
        double jaw = ctx.cache.GetAlligatorValue(m_handle, 0, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double teeth = ctx.cache.GetAlligatorValue(m_handle, 1, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double lips = ctx.cache.GetAlligatorValue(m_handle, 2, CONFIRMED_BAR_SHIFT, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_trend == "uptrend") {
            // Lips > Teeth > Jaw (Green > Red > Blue)
            if (lips > teeth && teeth > jaw) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else {
            // Lips < Teeth < Jaw
            if (lips < teeth && teeth < jaw) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("L=%.3f T=%.3f J=%.3f", lips, teeth, jaw);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
