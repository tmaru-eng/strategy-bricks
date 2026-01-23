//+------------------------------------------------------------------+
//|                                                     LotFixed.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                  lot.fixed - 固定ロットブロック                      |
//+------------------------------------------------------------------+
#ifndef LOTFIXED_MQH
#define LOTFIXED_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| LotFixedクラス                                                     |
//| 固定ロットを返す                                                    |
//+------------------------------------------------------------------+
class CLotFixed : public CBlockBase {
private:
    double m_lots;          // ロット数

public:
    //--- コンストラクタ
    CLotFixed(string blockId) : CBlockBase(blockId, "lot.fixed") {
        m_lots = DEFAULT_LOT;
    }

    //--- デストラクタ
    virtual ~CLotFixed() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_lots = GetParamDouble(paramsJson, "lots", DEFAULT_LOT);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ロット計算ブロックは特殊（PASSを返すが値を持つ）
        string reason = "Fixed lot: " + DoubleToString(m_lots, 2);

        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
        result.lotValue = m_lots;  // 拡張フィールドにロット値を設定
    }

    //+------------------------------------------------------------------+
    //| ロット値取得                                                       |
    //+------------------------------------------------------------------+
    double GetLots() const {
        return m_lots;
    }
};

#endif // LOTFIXED_MQH
