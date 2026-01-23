//+------------------------------------------------------------------+
//|                                                RiskFixedSLTP.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                risk.fixedSLTP - 固定SL/TPブロック                   |
//+------------------------------------------------------------------+
#ifndef RISKFIXEDSLTP_MQH
#define RISKFIXEDSLTP_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| RiskFixedSLTPクラス                                                |
//| 固定pipsのSL/TPを設定                                              |
//+------------------------------------------------------------------+
class CRiskFixedSLTP : public CBlockBase {
private:
    double m_slPips;        // SL（pips）
    double m_tpPips;        // TP（pips）

public:
    //--- コンストラクタ
    CRiskFixedSLTP(string blockId) : CBlockBase(blockId, "risk.fixedSLTP") {
        m_slPips = DEFAULT_SL_PIPS;
        m_tpPips = DEFAULT_TP_PIPS;
    }

    //--- デストラクタ
    virtual ~CRiskFixedSLTP() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_slPips = GetParamDouble(paramsJson, "slPips", DEFAULT_SL_PIPS);
        m_tpPips = GetParamDouble(paramsJson, "tpPips", DEFAULT_TP_PIPS);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // リスク計算ブロックは特殊（SL/TP値を持つ）
        string reason = "SL=" + DoubleToString(m_slPips, 1) +
                        " pips, TP=" + DoubleToString(m_tpPips, 1) + " pips";

        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
        result.slPips = m_slPips;   // 拡張フィールドにSL pipsを設定
        result.tpPips = m_tpPips;   // 拡張フィールドにTP pipsを設定
    }

    //+------------------------------------------------------------------+
    //| SL pips取得                                                       |
    //+------------------------------------------------------------------+
    double GetSLPips() const {
        return m_slPips;
    }

    //+------------------------------------------------------------------+
    //| TP pips取得                                                       |
    //+------------------------------------------------------------------+
    double GetTPPips() const {
        return m_tpPips;
    }
};

#endif // RISKFIXEDSLTP_MQH
