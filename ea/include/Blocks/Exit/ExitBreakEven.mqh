//+------------------------------------------------------------------+
//|                                             ExitBreakEven.mqh    |
//|                                         Strategy Bricks EA MVP   |
//|                  exit.breakEven - 建値決済                        |
//+------------------------------------------------------------------+
#ifndef EXITBREAKEVEN_MQH
#define EXITBREAKEVEN_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| ExitBreakEvenクラス                                                |
//| 指定pips利益で建値にSLを移動                                        |
//+------------------------------------------------------------------+
class CExitBreakEven : public CBlockBase {
private:
    double m_triggerPips;    // 建値移動トリガー（pips）
    double m_offsetPips;     // 建値からのオフセット（pips）
    int    m_limitPositions; // 建値決済を実行する最大ポジション数
    bool   m_partialClose;   // 一部ポジションを残すか
    int    m_keepPositions;  // 残すポジション数

public:
    //--- コンストラクタ
    CExitBreakEven(string blockId) : CBlockBase(blockId, "exit.breakEven") {
        m_triggerPips = 20.0;
        m_offsetPips = 0.0;
        m_limitPositions = 0; // 0=無制限
        m_partialClose = false;
        m_keepPositions = 1;
    }

    //--- デストラクタ
    virtual ~CExitBreakEven() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_triggerPips = GetParamDouble(paramsJson, "triggerPips", 20.0);
        m_offsetPips = GetParamDouble(paramsJson, "offsetPips", 0.0);
        m_limitPositions = GetParamInt(paramsJson, "limitPositions", 0);
        m_partialClose = GetParamBool(paramsJson, "partialClose", false);
        m_keepPositions = GetParamInt(paramsJson, "keepPositions", 1);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // 建値決済はポジション管理で実行されるため、
        // このブロックは設定値を提供するのみ
        
        string reason = StringFormat("BreakEven: Trigger=%.1f pips, Offset=%.1f pips",
                                    m_triggerPips, m_offsetPips);
        
        if (m_limitPositions > 0) {
            reason += StringFormat(", MaxPos=%d", m_limitPositions);
        }
        
        if (m_partialClose) {
            reason += StringFormat(", Keep=%d", m_keepPositions);
        }
        
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
        result.breakEvenTriggerPips = m_triggerPips;
        result.breakEvenOffsetPips = m_offsetPips;
    }
};

#endif // EXITBREAKEVEN_MQH
