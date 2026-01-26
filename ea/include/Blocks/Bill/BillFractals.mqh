//+------------------------------------------------------------------+
//|                                              BillFractals.mqh    |
//|      bill.fractals - フラクタルブレイク                            |
//+------------------------------------------------------------------+
#ifndef BILLFRACTALS_MQH
#define BILLFRACTALS_MQH

#include "../IBlock.mqh"

class CBillFractals : public CBlockBase {
private:
    string m_direction; // up, down
    int    m_handle;

public:
    CBillFractals(string blockId) : CBlockBase(blockId, "bill.fractals") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_direction = GetParamString(paramsJson, "direction", "up");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetFractalsHandle(ctx.market.symbol, EA_TIMEFRAME);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "Fractals handle error");
            return;
        }

        // Buffer 0: UPPER, 1: LOWER
        // Fractals appear on bar N-2 usually. `iFractals` logic depends on implementation.
        // Usually, buffer has value at the peak/valley bar, EMPTY_VALUE otherwise.
        
        // Strategy: Look for latest fractal in recent history (e.g. last 10 bars) and check breakout?
        // Or simpler: Is the current close breaking the latest fractal level?
        // MVP: Search last 10 bars for a fractal.
        
        double level = 0.0;
        int foundIndex = -1;
        
        int bufferIndex = (m_direction == "up") ? 0 : 1;
        
        for (int i = CONFIRMED_BAR_SHIFT; i < CONFIRMED_BAR_SHIFT + 10; i++) {
            // Get correct barTime for each historical bar to ensure proper caching
            datetime barTime = iTime(ctx.market.symbol, EA_TIMEFRAME, i);
            if (barTime == 0) continue; // Skip if barTime is invalid
            
            double val = ctx.cache.GetFractalsValue(m_handle, bufferIndex, i, barTime);
            
            if (val != EMPTY_VALUE && val != 0) {
                level = val;
                foundIndex = i;
                break;
            }
        }

        if (foundIndex == -1) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "No recent fractal found");
            return;
        }

        double close = ctx.market.close[0];
        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_direction == "up") {
            // Breakout Up: Close > Upper Fractal
            if (close > level) {
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else {
            // Breakout Down: Close < Lower Fractal
            if (close < level) {
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("Close=%.5f Frac(idx%d)=%.5f", close, foundIndex, level);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
