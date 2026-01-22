//+------------------------------------------------------------------+
//|                                              FilterSpreadMax.mqh |
//|                                         Strategy Bricks EA MVP   |
//|            filter.spreadMax - スプレッドフィルタブロック             |
//+------------------------------------------------------------------+
#ifndef FILTERSPREADMAX_MQH
#define FILTERSPREADMAX_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| FilterSpreadMaxクラス                                              |
//| スプレッドが指定pips以下の時のみPASS                                  |
//+------------------------------------------------------------------+
class CFilterSpreadMax : public CBlockBase {
private:
    double m_maxSpreadPips;     // 最大スプレッド（pips）

public:
    //--- コンストラクタ
    CFilterSpreadMax(string blockId) : CBlockBase(blockId, "filter.spreadMax") {
        m_maxSpreadPips = DEFAULT_MAX_SPREAD_PIPS;
    }

    //--- デストラクタ
    virtual ~CFilterSpreadMax() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_maxSpreadPips = GetParamDouble(paramsJson, "maxSpreadPips", DEFAULT_MAX_SPREAD_PIPS);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        double currentSpread = ctx.market.spreadPips;
        bool pass = (currentSpread <= m_maxSpreadPips);

        string reason = "Spread=" + DoubleToString(currentSpread, 1) +
                        " pips (max=" + DoubleToString(m_maxSpreadPips, 1) + ")";

        result.Init(pass ? BLOCK_STATUS_PASS : BLOCK_STATUS_FAIL,
                   DIRECTION_NEUTRAL, reason);
    }
};

#endif // FILTERSPREADMAX_MQH
