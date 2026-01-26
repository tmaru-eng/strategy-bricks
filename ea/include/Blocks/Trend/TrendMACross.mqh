//+------------------------------------------------------------------+
//|                                               TrendMACross.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|      trend.maCross - MAクロス判定                                  |
//+------------------------------------------------------------------+
#ifndef TRENDMACROSS_MQH
#define TRENDMACROSS_MQH

#include "../IBlock.mqh"

class CTrendMACross : public CBlockBase {
private:
    int    m_fastPeriod;
    int    m_slowPeriod;
    ENUM_MA_METHOD m_maMethod;
    ENUM_APPLIED_PRICE m_appliedPrice;
    string m_direction; // "golden" or "dead"
    int    m_fastHandle;
    int    m_slowHandle;

public:
    CTrendMACross(string blockId) : CBlockBase(blockId, "trend.maCross") {
        m_fastHandle = INVALID_HANDLE;
        m_slowHandle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_fastPeriod = GetParamInt(paramsJson, "fastPeriod", 5);
        m_slowPeriod = GetParamInt(paramsJson, "slowPeriod", 20);
        
        string methodStr = GetParamString(paramsJson, "maMethod", "EMA");
        if (methodStr == "SMA") m_maMethod = MODE_SMA;
        else if (methodStr == "SMMA") m_maMethod = MODE_SMMA;
        else if (methodStr == "LWMA") m_maMethod = MODE_LWMA;
        else m_maMethod = MODE_EMA;

        string priceStr = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if (priceStr == "OPEN") m_appliedPrice = PRICE_OPEN;
        else if (priceStr == "HIGH") m_appliedPrice = PRICE_HIGH;
        else if (priceStr == "LOW") m_appliedPrice = PRICE_LOW;
        else m_appliedPrice = PRICE_CLOSE;

        m_direction = GetParamString(paramsJson, "direction", "golden");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_fastHandle == INVALID_HANDLE && ctx.cache != NULL) {
            m_fastHandle = ctx.cache.GetMAHandle(ctx.market.symbol, EA_TIMEFRAME, m_fastPeriod, 0, m_maMethod, m_appliedPrice);
            m_slowHandle = ctx.cache.GetMAHandle(ctx.market.symbol, EA_TIMEFRAME, m_slowPeriod, 0, m_maMethod, m_appliedPrice);
        }

        if (m_fastHandle == INVALID_HANDLE || m_slowHandle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "MA handle error");
            return;
        }

        double fast1 = ctx.cache.GetMAValue(m_fastHandle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double slow1 = ctx.cache.GetMAValue(m_slowHandle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double fast2 = ctx.cache.GetMAValue(m_fastHandle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);
        double slow2 = ctx.cache.GetMAValue(m_slowHandle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        // Golden Cross: Fast crosses Slow upward (Prev: Fast < Slow, Curr: Fast > Slow)
        // Note: For cleaner logic, we check relation. 
        // Golden Cross means current state implies UP trend start.
        // Actually, if it's a "Trend" block (not Trigger), it usually means "Is in Golden Cross state" (Fast > Slow).
        // But description said "MA Cross", implying the event or the state.
        // Usually, Trend blocks check state (Fast > Slow), Trigger blocks check the cross event (Just crossed).
        // Given category "trend", I will implement STATE check (Fast > Slow for golden, Fast < Slow for dead).
        // Wait, the params have "direction". If "golden", it returns PASS if Fast > Slow?
        // Let's assume it passes if the condition is met.
        // If it's a Trend block, returning DIRECTION_LONG for Golden and SHORT for Dead makes sense ONLY if the user selects that intent.
        // But the param "direction" suggests we are filtering for a specific state.
        
        string reason = "";
        
        if (m_direction == "golden") {
            // Golden Cross State: Fast > Slow
            if (fast1 > slow1) {
                pass = true;
                dir = DIRECTION_LONG;
                reason = "Golden(Fast>Slow)";
            } else {
                reason = "No Golden";
            }
        } else {
            // Dead Cross State: Fast < Slow
            if (fast1 < slow1) {
                pass = true;
                dir = DIRECTION_SHORT;
                reason = "Dead(Fast<Slow)";
            } else {
                reason = "No Dead";
            }
        }
        
        reason += StringFormat(" F=%.5f S=%.5f", fast1, slow1);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
