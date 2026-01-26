//+------------------------------------------------------------------+
//|                                            LotRiskPercent.mqh    |
//|                                         Strategy Bricks EA MVP   |
//|              lot.riskPercent - 資金割合ベースロット計算             |
//+------------------------------------------------------------------+
#ifndef LOTRISKPERCENT_MQH
#define LOTRISKPERCENT_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| LotRiskPercentクラス                                               |
//| 口座残高または証拠金の指定割合でロット数を計算                        |
//+------------------------------------------------------------------+
class CLotRiskPercent : public CBlockBase {
private:
    double m_riskPercent;    // リスク割合 (%)
    bool   m_useMarginFree;  // 証拠金ベース（false=残高ベース）
    double m_minLot;         // 最小ロット
    double m_maxLot;         // 最大ロット

public:
    //--- コンストラクタ
    CLotRiskPercent(string blockId) : CBlockBase(blockId, "lot.riskPercent") {
        m_riskPercent = 1.0;
        m_useMarginFree = false;
        m_minLot = 0.01;
        m_maxLot = 100.0;
    }

    //--- デストラクタ
    virtual ~CLotRiskPercent() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_riskPercent = GetParamDouble(paramsJson, "riskPercent", 1.0);
        m_useMarginFree = GetParamBool(paramsJson, "useMarginFree", false);
        m_minLot = GetParamDouble(paramsJson, "minLot", 0.01);
        m_maxLot = GetParamDouble(paramsJson, "maxLot", 100.0);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // 口座情報取得
        double accountValue;
        if (m_useMarginFree) {
            accountValue = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
        } else {
            accountValue = AccountInfoDouble(ACCOUNT_BALANCE);
        }
        
        if (accountValue <= 0) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Invalid account value");
            return;
        }
        
        // リスク金額を計算
        double riskAmount = accountValue * (m_riskPercent / 100.0);
        
        // シンボル情報取得
        double tickValue = SymbolInfoDouble(ctx.market.symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(ctx.market.symbol, SYMBOL_TRADE_TICK_SIZE);
        double minLot = SymbolInfoDouble(ctx.market.symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(ctx.market.symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(ctx.market.symbol, SYMBOL_VOLUME_STEP);
        
        if (tickValue <= 0 || tickSize <= 0) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Invalid symbol info");
            return;
        }
        
        // 1ロットあたりの価値を計算（簡易版：100,000通貨単位と仮定）
        double lotValue = 100000.0 * tickValue / tickSize;
        
        // ロット数を計算
        double calculatedLot = riskAmount / lotValue;
        
        // ロットステップに丸める
        calculatedLot = MathFloor(calculatedLot / lotStep) * lotStep;
        
        // 制限を適用
        if (calculatedLot < minLot) calculatedLot = minLot;
        if (calculatedLot > maxLot) calculatedLot = maxLot;
        if (calculatedLot < m_minLot) calculatedLot = m_minLot;
        if (calculatedLot > m_maxLot) calculatedLot = m_maxLot;
        
        // 結果を設定（lotSizeフィールドに格納）
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                   StringFormat("Lot: %.2f (Risk: %.1f%% of %.2f)",
                               calculatedLot, m_riskPercent, accountValue));
        result.lotSize = calculatedLot;
    }
};

#endif // LOTRISKPERCENT_MQH
