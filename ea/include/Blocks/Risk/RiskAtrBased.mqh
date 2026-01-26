//+------------------------------------------------------------------+
//|                                            RiskAtrBased.mqh      |
//|                                         Strategy Bricks EA MVP   |
//|              risk.atrBased - ATRベースSL/TP設定                    |
//+------------------------------------------------------------------+
#ifndef RISKATRBASED_MQH
#define RISKATRBASED_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| RiskAtrBasedクラス                                                 |
//| ATR値に基づいてSL/TPを動的に設定                                    |
//+------------------------------------------------------------------+
class CRiskAtrBased : public CBlockBase {
private:
    int    m_atrPeriod;      // ATR期間
    int    m_atrTimeframe;   // ATR時間軸
    double m_atrRatio;       // ATR基本倍率
    double m_buyTpRatio;     // 買いTP倍率
    double m_buySlRatio;     // 買いSL倍率
    double m_sellTpRatio;    // 売りTP倍率
    double m_sellSlRatio;    // 売りSL倍率
    int    m_atrHandle;      // ATRハンドル

public:
    //--- コンストラクタ
    CRiskAtrBased(string blockId) : CBlockBase(blockId, "risk.atrBased") {
        m_atrPeriod = 100;
        m_atrTimeframe = PERIOD_H4;
        m_atrRatio = 5.0;
        m_buyTpRatio = 1.2;
        m_buySlRatio = 1.3;
        m_sellTpRatio = 1.2;
        m_sellSlRatio = 1.3;
        m_atrHandle = INVALID_HANDLE;
    }

    //--- デストラクタ
    virtual ~CRiskAtrBased() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_atrPeriod = GetParamInt(paramsJson, "atrPeriod", 100);
        m_atrRatio = GetParamDouble(paramsJson, "atrRatio", 5.0);
        m_buyTpRatio = GetParamDouble(paramsJson, "buyTpRatio", 1.2);
        m_buySlRatio = GetParamDouble(paramsJson, "buySlRatio", 1.3);
        m_sellTpRatio = GetParamDouble(paramsJson, "sellTpRatio", 1.2);
        m_sellSlRatio = GetParamDouble(paramsJson, "sellSlRatio", 1.3);
        
        // atrTimeframe
        string timeframeStr = GetParamString(paramsJson, "atrTimeframe", "H4");
        if (timeframeStr == "M1") m_atrTimeframe = PERIOD_M1;
        else if (timeframeStr == "M5") m_atrTimeframe = PERIOD_M5;
        else if (timeframeStr == "M15") m_atrTimeframe = PERIOD_M15;
        else if (timeframeStr == "M30") m_atrTimeframe = PERIOD_M30;
        else if (timeframeStr == "H1") m_atrTimeframe = PERIOD_H1;
        else if (timeframeStr == "H4") m_atrTimeframe = PERIOD_H4;
        else if (timeframeStr == "D1") m_atrTimeframe = PERIOD_D1;
        else m_atrTimeframe = PERIOD_H4;
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // ATRハンドル取得
        if (m_atrHandle == INVALID_HANDLE && ctx.cache != NULL) {
            m_atrHandle = ctx.cache.GetATRHandle(
                ctx.market.symbol,
                (ENUM_TIMEFRAMES)m_atrTimeframe,
                m_atrPeriod
            );
        }
        
        if (m_atrHandle == INVALID_HANDLE) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "ATR handle error");
            return;
        }
        
        // ATR値を取得
        double atr = ctx.cache.GetATRValue(m_atrHandle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
        
        if (atr == EMPTY_VALUE || atr <= 0) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "ATR data not available");
            return;
        }
        
        // ATR値をpipsに変換
        double pipValue = SymbolInfoDouble(ctx.market.symbol, SYMBOL_POINT);
        if (pipValue <= 0) {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Invalid pip value");
            return;
        }
        
        double atrPips = atr / (pipValue * 10.0);
        double basePips = atrPips * m_atrRatio;
        
        // SL/TPを計算
        double buyTp = basePips * m_buyTpRatio;
        double buySl = basePips * m_buySlRatio;
        double sellTp = basePips * m_sellTpRatio;
        double sellSl = basePips * m_sellSlRatio;
        
        string reason = StringFormat("ATR-based: ATR=%.1f pips, Base=%.1f pips, BuyTP=%.1f, BuySL=%.1f, SellTP=%.1f, SellSL=%.1f",
                                    atrPips, basePips, buyTp, buySl, sellTp, sellSl);
        
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
        result.buyTakeProfitPips = buyTp;
        result.buyStopLossPips = buySl;
        result.sellTakeProfitPips = sellTp;
        result.sellStopLossPips = sellSl;
    }
};

#endif // RISKATRBASED_MQH
