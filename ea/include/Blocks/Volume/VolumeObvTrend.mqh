//+------------------------------------------------------------------+
//|                                             VolumeObvTrend.mqh   |
//|      volume.obvTrend                                             |
//+------------------------------------------------------------------+
#ifndef VOLUMEOBVTREND_MQH
#define VOLUMEOBVTREND_MQH

#include "../IBlock.mqh"

class CVolumeObvTrend : public CBlockBase {
private:
    ENUM_APPLIED_VOLUME m_volume;
    string m_direction; // up, down
    int    m_handle;

public:
    CVolumeObvTrend(string blockId) : CBlockBase(blockId, "volume.obvTrend") {
        m_handle = INVALID_HANDLE;
    }

    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        string v = GetParamString(paramsJson, "appliedVolume", "TICK");
        m_volume = (v=="REAL") ? VOLUME_REAL : VOLUME_TICK;
        m_direction = GetParamString(paramsJson, "direction", "up");
    }

    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetOBVHandle(ctx.market.symbol, EA_TIMEFRAME, m_volume);
        }

        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL, "OBV handle error");
            return;
        }

        double obv1 = ctx.cache.GetOBVValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        double obv2 = ctx.cache.GetOBVValue(m_handle, CONFIRMED_BAR_SHIFT + 1, ctx.state.barTime);

        bool pass = false;
        TradeDirection dir = DIRECTION_NEUTRAL;

        if (m_direction == "up") {
            if (obv1 > obv2) { // OBV Rising
                pass = true;
                dir = DIRECTION_LONG;
            }
        } else {
            if (obv1 < obv2) { // OBV Falling
                pass = true;
                dir = DIRECTION_SHORT;
            }
        }

        string reason = StringFormat("OBV1=%.0f OBV2=%.0f", obv1, obv2);
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL, dir, reason);
    }
};

#endif
