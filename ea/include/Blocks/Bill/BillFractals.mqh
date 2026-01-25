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
            double val = ctx.cache.GetFractalsValue(m_handle, bufferIndex, i, 0); // barTime=0 to skip strict caching check or use approximate
            // Actually GetValueCommon expects specific barTime for caching key. If we iterate, we might not have barTime for historical bars in state easily.
            // Using direct CopyBuffer is safer for loop search to avoid cache pollution with misses.
            // But we need barTime for cache key.
            // Let's use direct CopyBuffer here or just accept cache misses.
            // The `GetFractalsValue` uses `GetValueCommon`.
            // We can pass `0` as barTime, but then cache key is `V_handle_buf_idx`.
            // If we access `i` relative to current, barTime changes every bar.
            // Actually, `GetValueCommon` uses `index` in key? No, `index`. So `V_..._index`.
            // If `index` is shift, it shifts every new bar. Caching by shift is valid only for that specific bar moment.
            // `IndicatorCache` uses `barTime` in `ValueCacheEntry` to invalidate old cache?
            // Yes: `if (m_values[i].key == key && m_values[i].barTime == barTime)`. 
            // So `GetFractalsValue` requires correct `barTime` for that index `i`.
            // We don't have historical bar times easily here without CopyTime.
            
            // To simplify: Breakout of *previously confirmed* fractal.
            // Standard Fractal is confirmed at index 2 (closed).
            // Let's just check if index 2 IS a fractal, and use that as signal?
            // "Fractal" block usually means "Wait for Fractal formation" or "Breakout of Fractal".
            // Description says "フラクタルブレイク".
            // Logic: Close > Last Upper Fractal.
            
            // We need to find the last fractal level.
            double valBuf[];
            if (CopyBuffer(m_handle, bufferIndex, i, 1, valBuf) > 0) {
                if (valBuf[0] != EMPTY_VALUE && valBuf[0] != 0) {
                    level = valBuf[0];
                    foundIndex = i;
                    break;
                }
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
