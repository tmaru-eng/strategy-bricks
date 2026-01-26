//+------------------------------------------------------------------+
//|                                              OscForceIndex.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|                osc.forceIndex - Force Indexオシレーター            |
//+------------------------------------------------------------------+
#ifndef OSCFORCEINDEX_MQH
#define OSCFORCEINDEX_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| OscForceIndexクラス                                                |
//| Force Indexの値を判定                                              |
//+------------------------------------------------------------------+
class COscForceIndex : public CBlockBase {
private:
    int    m_maPeriod;      // MA期間
    int    m_maMethod;      // MA計算方法
    int    m_appliedVolume; // 適用出来高
    string m_comparison;    // above/below
    double m_threshold;     // 閾値
    int    m_handle;        // インジケータハンドル

public:
    //--- コンストラクタ
    COscForceIndex(string blockId) : CBlockBase(blockId, "osc.forceIndex") {
        m_maPeriod = 13;
        m_maMethod = MODE_SMA;
        m_appliedVolume = VOLUME_TICK;
        m_comparison = "above";
        m_threshold = 0.0;
        m_handle = INVALID_HANDLE;
    }

    //--- デストラクタ
    virtual ~COscForceIndex() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_maPeriod = GetParamInt(paramsJson, "maPeriod", 13);
        m_threshold = GetParamDouble(paramsJson, "threshold", 0.0);
        m_comparison = GetParamString(paramsJson, "comparison", "above");
        
        // maMethod
        string maMethodStr = GetParamString(paramsJson, "maMethod", "SMA");
        if (maMethodStr == "EMA") m_maMethod = MODE_EMA;
        else if (maMethodStr == "SMMA") m_maMethod = MODE_SMMA;
        else if (maMethodStr == "LWMA") m_maMethod = MODE_LWMA;
        else m_maMethod = MODE_SMA;
        
        // appliedVolume
        string appliedVolumeStr = GetParamString(paramsJson, "appliedVolume", "TICK");
        if (appliedVolumeStr == "REAL") m_appliedVolume = VOLUME_REAL;
        else m_appliedVolume = VOLUME_TICK;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ハンドル取得
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetForceHandle(
                ctx.market.symbol,
                EA_TIMEFRAME,
                m_maPeriod,
                (ENUM_MA_METHOD)m_maMethod,
                (ENUM_APPLIED_VOLUME)m_appliedVolume
            );
        }
        
        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Force Index handle error");
            return;
        }
        
        // Force Index値を取得
        double forceValue = ctx.cache.GetForceValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        
        if (forceValue == EMPTY_VALUE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Force Index data not available");
            return;
        }
        
        // 比較判定
        bool pass = false;
        if (m_comparison == "above") {
            pass = (forceValue > m_threshold);
        } else if (m_comparison == "below") {
            pass = (forceValue < m_threshold);
        }
        
        string reason = StringFormat("Force(%.5f) %s %.5f",
                                    forceValue, m_comparison, m_threshold);
        
        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL,
                   DIRECTION_NEUTRAL, reason);
    }
};

#endif // OSCFORCEINDEX_MQH
