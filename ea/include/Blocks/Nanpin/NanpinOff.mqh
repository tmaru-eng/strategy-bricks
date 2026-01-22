//+------------------------------------------------------------------+
//|                                                    NanpinOff.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                    nanpin.off - ナンピン無効ブロック                 |
//+------------------------------------------------------------------+
#ifndef NANPINOFF_MQH
#define NANPINOFF_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| NanpinOffクラス                                                    |
//| ナンピン（分割エントリー）無効                                        |
//+------------------------------------------------------------------+
class CNanpinOff : public CBlockBase {
public:
    //--- コンストラクタ
    CNanpinOff(string blockId) : CBlockBase(blockId, "nanpin.off") {
    }

    //--- デストラクタ
    virtual ~CNanpinOff() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        // nanpin.offにはパラメータなし
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ナンピン無効は常にPASS（追加エントリーしない）
        string reason = "Nanpin disabled";

        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
    }
};

#endif // NANPINOFF_MQH
