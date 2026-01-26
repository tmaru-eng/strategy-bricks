//+------------------------------------------------------------------+
//|                                                  ExitTrail.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|                   exit.trail - トレーリングストップ                |
//+------------------------------------------------------------------+
#ifndef EXITTRAIL_MQH
#define EXITTRAIL_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| ExitTrailクラス                                                    |
//| トレーリングストップによる決済管理                                    |
//+------------------------------------------------------------------+
class CExitTrail : public CBlockBase {
private:
    double m_startPips;      // トレール開始値（pips）
    double m_trailPips;      // トレール幅（pips）
    bool   m_useAtr;         // ATRベース設定を使用
    double m_atrRatio;       // ATR倍率
    int    m_atrPeriod;      // ATR期間
    int    m_atrHandle;      // ATRハンドル

public:
    //--- コンストラクタ
    CExitTrail(string blockId) : CBlockBase(blockId, "exit.trail") {
        m_startPips = 20.0;
        m_trailPips = 10.0;
        m_useAtr = false;
        m_atrRatio = 0.5;
        m_atrPeriod = 14;
        m_atrHandle = INVALID_HANDLE;
    }

    //--- デストラクタ
    virtual ~CExitTrail() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_startPips = GetParamDouble(paramsJson, "startPips", 20.0);
        m_trailPips = GetParamDouble(paramsJson, "trailPips", 10.0);
        m_useAtr = GetParamBool(paramsJson, "useAtr", false);
        m_atrRatio = GetParamDouble(paramsJson, "atrRatio", 0.5);
        m_atrPeriod = GetParamInt(paramsJson, "atrPeriod", 14);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // トレーリングストップはポジション管理で実行されるため、
        // このブロックは設定値を提供するのみ
        
        double startValue = m_startPips;
        double trailValue = m_trailPips;
        
        // ATRベース設定の場合
        if (m_useAtr) {
            if (m_atrHandle == INVALID_HANDLE && ctx.cache != NULL) {
                m_atrHandle = ctx.cache.GetATRHandle(
                    ctx.market.symbol,
                    EA_TIMEFRAME,
                    m_atrPeriod
                );
            }
            
            if (m_atrHandle != INVALID_HANDLE) {
                double atr = ctx.cache.GetATRValue(m_atrHandle, CONFIRMED_BAR_SHIFT, ctx.state.barTime);
                
                if (atr != EMPTY_VALUE && atr > 0) {
                    // ATR値をpipsに変換
                    double pipValue = SymbolInfoDouble(ctx.market.symbol, SYMBOL_POINT);
                    if (pipValue > 0) {
                        double atrPips = atr / (pipValue * 10.0);
                        startValue = atrPips * m_atrRatio;
                        trailValue = startValue * 0.5; // トレール幅は開始値の半分
                    }
                }
            }
        }
        
        string reason = StringFormat("Trail: Start=%.1f pips, Trail=%.1f pips%s",
                                    startValue, trailValue,
                                    m_useAtr ? " (ATR-based)" : "");
        
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, reason);
        result.trailStartPips = startValue;
        result.trailStopPips = trailValue;
    }
};

#endif // EXITTRAIL_MQH
