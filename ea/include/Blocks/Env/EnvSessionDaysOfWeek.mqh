//+------------------------------------------------------------------+
//|                                       EnvSessionDaysOfWeek.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|        filter.session.daysOfWeek - 曜日フィルタブロック            |
//+------------------------------------------------------------------+
#ifndef ENVSESSIONDAYSOFWEEK_MQH
#define ENVSESSIONDAYSOFWEEK_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| EnvSessionDaysOfWeekクラス                                         |
//| 指定曜日のみPASS                                                   |
//+------------------------------------------------------------------+
class CEnvSessionDaysOfWeek : public CBlockBase {
private:
    bool m_allowedDays[7];  // 曜日（0=Sun, 1=Mon, ..., 6=Sat）

    //+------------------------------------------------------------------+
    //| 曜日名取得                                                         |
    //+------------------------------------------------------------------+
    string GetDayName(int dow) {
        switch (dow) {
            case 0: return "Sun";
            case 1: return "Mon";
            case 2: return "Tue";
            case 3: return "Wed";
            case 4: return "Thu";
            case 5: return "Fri";
            case 6: return "Sat";
            default: return "Unknown";
        }
    }

public:
    //--- コンストラクタ
    CEnvSessionDaysOfWeek(string blockId) : CBlockBase(blockId, "filter.session.daysOfWeek") {
        // デフォルト：平日のみ許可（月〜金）
        m_allowedDays[0] = false; // Sun
        m_allowedDays[1] = true;  // Mon
        m_allowedDays[2] = true;  // Tue
        m_allowedDays[3] = true;  // Wed
        m_allowedDays[4] = true;  // Thu
        m_allowedDays[5] = true;  // Fri
        m_allowedDays[6] = false; // Sat
    }

    //--- デストラクタ
    virtual ~CEnvSessionDaysOfWeek() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        
        // 全曜日を一旦不許可にする
        for (int i = 0; i < 7; i++) {
            m_allowedDays[i] = false;
        }
        
        // days配列をパース
        // 例: "days":[1,2,3,4,5]
        int startPos = StringFind(paramsJson, "\"days\"");
        if (startPos >= 0) {
            int arrayStart = StringFind(paramsJson, "[", startPos);
            int arrayEnd = StringFind(paramsJson, "]", arrayStart);
            
            if (arrayStart >= 0 && arrayEnd > arrayStart) {
                string arrayStr = StringSubstr(paramsJson, arrayStart + 1, arrayEnd - arrayStart - 1);
                
                // カンマで分割して各曜日を設定
                string parts[];
                int count = StringSplit(arrayStr, ',', parts);
                
                for (int i = 0; i < count; i++) {
                    // 空白を削除
                    StringTrimLeft(parts[i]);
                    StringTrimRight(parts[i]);
                    
                    int day = (int)StringToInteger(parts[i]);
                    if (day >= 0 && day <= 6) {
                        m_allowedDays[day] = true;
                    }
                }
            }
        }
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);

        // 曜日チェック（MQL5: 0=Sunday, 1=Monday, ..., 6=Saturday）
        int dow = dt.day_of_week;
        
        if (m_allowedDays[dow]) {
            result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                       "Day allowed: " + GetDayName(dow));
        } else {
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Day not allowed: " + GetDayName(dow));
        }
    }
};

#endif // ENVSESSIONDAYSOFWEEK_MQH
