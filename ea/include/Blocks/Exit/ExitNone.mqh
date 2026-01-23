//+------------------------------------------------------------------+
//|                                                     ExitNone.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                     exit.none - 出口なしブロック                    |
//+------------------------------------------------------------------+
#ifndef EXITNONE_MQH
#define EXITNONE_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| ExitNoneクラス                                                     |
//| 出口管理なし（SL/TPのみで決済）                                       |
//+------------------------------------------------------------------+
class CExitNone : public CBlockBase {
public:
    //--- コンストラクタ
    CExitNone(string blockId) : CBlockBase(blockId, "exit.none") {
    }

    //--- デストラクタ
    virtual ~CExitNone() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        // exit.noneにはパラメータなし
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // 出口管理なしは常にPASS（何もしない）
        string reason = "No exit management (SL/TP only)";

        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
    }
};

#endif // EXITNONE_MQH
