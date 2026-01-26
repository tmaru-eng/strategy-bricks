//+------------------------------------------------------------------+
//|                                              NanpinFixed.mqh     |
//|                                         Strategy Bricks EA MVP   |
//|                 nanpin.fixed - 固定間隔ナンピン                    |
//+------------------------------------------------------------------+
#ifndef NANPINFIXED_MQH
#define NANPINFIXED_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| NanpinFixedクラス                                                  |
//| 固定pips間隔でナンピン（追加エントリー）                             |
//+------------------------------------------------------------------+
class CNanpinFixed : public CBlockBase {
private:
    double m_intervalPips;      // ナンピン間隔（pips）
    int    m_maxCount;          // 最大ナンピン回数
    int    m_lotAdjustMethod;   // ロット調整方法（0:固定, 1:倍々, 2:初期ロット追加）
    double m_fixedIncrement;    // 固定ロット増加量
    int    m_multiplier;        // 倍々の倍率

public:
    //--- コンストラクタ
    CNanpinFixed(string blockId) : CBlockBase(blockId, "nanpin.fixed") {
        m_intervalPips = 10.0;
        m_maxCount = 5;
        m_lotAdjustMethod = 0;
        m_fixedIncrement = 0.01;
        m_multiplier = 2;
    }

    //--- デストラクタ
    virtual ~CNanpinFixed() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_intervalPips = GetParamDouble(paramsJson, "intervalPips", 10.0);
        m_maxCount = GetParamInt(paramsJson, "maxCount", 5);
        m_lotAdjustMethod = GetParamInt(paramsJson, "lotAdjustMethod", 0);
        m_fixedIncrement = GetParamDouble(paramsJson, "fixedIncrement", 0.01);
        m_multiplier = GetParamInt(paramsJson, "multiplier", 2);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ナンピン設定を提供
        string methodStr;
        switch (m_lotAdjustMethod) {
            case 0: methodStr = "Fixed"; break;
            case 1: methodStr = "Double"; break;
            case 2: methodStr = "AddInitial"; break;
            default: methodStr = "Unknown"; break;
        }
        
        string reason = StringFormat("Nanpin: Interval=%.1f pips, MaxCount=%d, Method=%s",
                                    m_intervalPips, m_maxCount, methodStr);
        
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
        result.nanpinEnabled = true;
        result.nanpinIntervalPips = m_intervalPips;
        result.nanpinMaxCount = m_maxCount;
        result.nanpinLotAdjustMethod = m_lotAdjustMethod;
    }
};

#endif // NANPINFIXED_MQH
