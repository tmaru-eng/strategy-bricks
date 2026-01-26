//+------------------------------------------------------------------+
//|                                        ExitWeekendClose.mqh      |
//|                                         Strategy Bricks EA MVP   |
//|                exit.weekendClose - 週末強制決済                    |
//+------------------------------------------------------------------+
#ifndef EXITWEEKENDCLOSE_MQH
#define EXITWEEKENDCLOSE_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| ExitWeekendCloseクラス                                             |
//| 週末指定時刻に全ポジションを強制決済                                 |
//+------------------------------------------------------------------+
class CExitWeekendClose : public CBlockBase {
private:
    int    m_dayOfWeek;      // 決済曜日（5=金曜日）
    string m_closeTime;      // 決済時刻（HH:MM）
    string m_warningTime;    // 警告時刻（HH:MM）
    int    m_closeMinutes;   // 決済時刻（分）
    int    m_warningMinutes; // 警告時刻（分）

    //+------------------------------------------------------------------+
    //| 時刻文字列を分に変換                                               |
    //+------------------------------------------------------------------+
    int ParseTimeToMinutes(string timeStr) {
        int colonPos = StringFind(timeStr, ":");
        if (colonPos < 0) return 0;
        
        string hourStr = StringSubstr(timeStr, 0, colonPos);
        string minStr = StringSubstr(timeStr, colonPos + 1);
        
        return (int)StringToInteger(hourStr) * 60 + (int)StringToInteger(minStr);
    }

public:
    //--- コンストラクタ
    CExitWeekendClose(string blockId) : CBlockBase(blockId, "exit.weekendClose") {
        m_dayOfWeek = 5;        // 金曜日
        m_closeTime = "22:30";
        m_warningTime = "22:00";
        m_closeMinutes = 0;
        m_warningMinutes = 0;
    }

    //--- デストラクタ
    virtual ~CExitWeekendClose() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_dayOfWeek = GetParamInt(paramsJson, "dayOfWeek", 5);
        m_closeTime = GetParamString(paramsJson, "closeTime", "22:30");
        m_warningTime = GetParamString(paramsJson, "warningTime", "22:00");
        
        m_closeMinutes = ParseTimeToMinutes(m_closeTime);
        m_warningMinutes = ParseTimeToMinutes(m_warningTime);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        
        int currentMinutes = dt.hour * 60 + dt.min;
        int dow = dt.day_of_week;
        
        // 決済曜日かチェック
        if (dow != m_dayOfWeek) {
            result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                       StringFormat("Not weekend close day (current: %d, target: %d)",
                                   dow, m_dayOfWeek));
            return;
        }
        
        // 決済時刻に達したかチェック
        if (currentMinutes >= m_closeMinutes) {
            result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                       StringFormat("Weekend close time reached: %s", m_closeTime));
            result.forceClose = true;
            return;
        }
        
        // 警告時刻に達したかチェック
        if (currentMinutes >= m_warningMinutes) {
            result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                       StringFormat("Weekend close warning: %s (close at %s)",
                                   m_warningTime, m_closeTime));
            result.closeWarning = true;
            return;
        }
        
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                   StringFormat("Weekend close scheduled: %s on day %d",
                               m_closeTime, m_dayOfWeek));
    }
};

#endif // EXITWEEKENDCLOSE_MQH
