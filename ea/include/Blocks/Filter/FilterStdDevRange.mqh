//+------------------------------------------------------------------+
//|                                          FilterStdDevRange.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|     filter.volatility.stddevRange - 標準偏差範囲フィルタ           |
//+------------------------------------------------------------------+
#ifndef FILTERSTDDEVRANGE_MQH
#define FILTERSTDDEVRANGE_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| FilterStdDevRangeクラス                                            |
//| 標準偏差が指定範囲内のときのみPASS                                   |
//+------------------------------------------------------------------+
class CFilterStdDevRange : public CBlockBase {
private:
    int    m_period;        // 標準偏差の期間
    int    m_maPeriod;      // MA期間
    int    m_maShift;       // MAシフト
    int    m_maMethod;      // MA計算方法
    int    m_appliedPrice;  // 適用価格
    double m_minStdDev;     // 最小標準偏差
    double m_maxStdDev;     // 最大標準偏差
    int    m_handle;        // インジケータハンドル

public:
    //--- コンストラクタ
    CFilterStdDevRange(string blockId) : CBlockBase(blockId, "filter.volatility.stddevRange") {
        m_period = 20;
        m_maPeriod = 20;
        m_maShift = 0;
        m_maMethod = MODE_SMA;
        m_appliedPrice = PRICE_CLOSE;
        m_minStdDev = 0.0;
        m_maxStdDev = 999999.0;
        m_handle = INVALID_HANDLE;
    }

    //--- デストラクタ
    virtual ~CFilterStdDevRange() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_period = GetParamInt(paramsJson, "period", 20);
        m_maPeriod = GetParamInt(paramsJson, "maPeriod", 20);
        m_maShift = GetParamInt(paramsJson, "maShift", 0);
        m_minStdDev = GetParamDouble(paramsJson, "min", 0.0);
        m_maxStdDev = GetParamDouble(paramsJson, "max", 999999.0);
        
        // maMethod
        string maMethodStr = GetParamString(paramsJson, "maMethod", "SMA");
        if (maMethodStr == "EMA") m_maMethod = MODE_EMA;
        else if (maMethodStr == "SMMA") m_maMethod = MODE_SMMA;
        else if (maMethodStr == "LWMA") m_maMethod = MODE_LWMA;
        else m_maMethod = MODE_SMA;
        
        // appliedPrice
        string appliedPriceStr = GetParamString(paramsJson, "appliedPrice", "CLOSE");
        if (appliedPriceStr == "OPEN") m_appliedPrice = PRICE_OPEN;
        else if (appliedPriceStr == "HIGH") m_appliedPrice = PRICE_HIGH;
        else if (appliedPriceStr == "LOW") m_appliedPrice = PRICE_LOW;
        else if (appliedPriceStr == "MEDIAN") m_appliedPrice = PRICE_MEDIAN;
        else if (appliedPriceStr == "TYPICAL") m_appliedPrice = PRICE_TYPICAL;
        else if (appliedPriceStr == "WEIGHTED") m_appliedPrice = PRICE_WEIGHTED;
        else m_appliedPrice = PRICE_CLOSE;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ハンドル取得
        if (m_handle == INVALID_HANDLE && ctx.cache != NULL) {
            m_handle = ctx.cache.GetStdDevHandle(
                ctx.market.symbol,
                EA_TIMEFRAME,
                m_maPeriod,
                m_maShift,
                (ENUM_MA_METHOD)m_maMethod,
                (ENUM_APPLIED_PRICE)m_appliedPrice
            );
        }
        
        if (m_handle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "StdDev handle error");
            return;
        }
        
        // 標準偏差値を取得
        double stddev = ctx.cache.GetStdDevValue(m_handle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        
        if (stddev == EMPTY_VALUE || stddev < 0) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "StdDev data not available");
            return;
        }
        
        // 範囲チェック
        if (stddev >= m_minStdDev && stddev <= m_maxStdDev) {
            result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                       StringFormat("StdDev in range: %.5f (%.5f-%.5f)",
                                   stddev, m_minStdDev, m_maxStdDev));
        } else {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       StringFormat("StdDev out of range: %.5f (%.5f-%.5f)",
                                   stddev, m_minStdDev, m_maxStdDev));
        }
    }
};

#endif // FILTERSTDDEVRANGE_MQH
