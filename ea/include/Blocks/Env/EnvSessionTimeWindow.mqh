//+------------------------------------------------------------------+
//|                                          EnvSessionTimeWindow.mqh|
//|                                         Strategy Bricks EA MVP   |
//|          env.session.timeWindow - セッションフィルタブロック         |
//+------------------------------------------------------------------+
#ifndef ENVSESSIONTIMEWINDOW_MQH
#define ENVSESSIONTIMEWINDOW_MQH

#include "../IBlock.mqh"

//+------------------------------------------------------------------+
//| EnvSessionTimeWindowクラス                                         |
//| 指定時間帯・曜日のみPASS                                            |
//+------------------------------------------------------------------+
class CEnvSessionTimeWindow : public CBlockBase {
private:
    bool       m_useGlobal;         // globalGuards.sessionを使用
    bool       m_enabled;           // セッション有効
    TimeWindow m_windows[8];        // 時間帯
    int        m_windowCount;       // 時間帯数
    bool       m_weekDays[7];       // 曜日（0=Sun, 1=Mon, ..., 6=Sat）

    //+------------------------------------------------------------------+
    //| 時刻文字列を分に変換                                               |
    //+------------------------------------------------------------------+
    int ParseTimeToMinutes(string timeStr) {
        // "07:00" → 420
        int colonPos = StringFind(timeStr, ":");
        if (colonPos < 0) return 0;

        string hourStr = StringSubstr(timeStr, 0, colonPos);
        string minStr = StringSubstr(timeStr, colonPos + 1);

        return (int)StringToInteger(hourStr) * 60 + (int)StringToInteger(minStr);
    }

    //+------------------------------------------------------------------+
    //| 時間帯内かチェック                                                 |
    //+------------------------------------------------------------------+
    bool IsInWindow(int currentMinutes, int startMin, int endMin) {
        // 跨日対応（例: 23:00 - 02:00）
        if (endMin < startMin) {
            return (currentMinutes >= startMin || currentMinutes <= endMin);
        } else {
            return (currentMinutes >= startMin && currentMinutes <= endMin);
        }
    }

public:
    //--- コンストラクタ
    CEnvSessionTimeWindow(string blockId) : CBlockBase(blockId, "env.session.timeWindow") {
        m_useGlobal = true;
        m_enabled = false;
        m_windowCount = 0;
        for (int i = 0; i < 7; i++) {
            m_weekDays[i] = true;  // デフォルト：全曜日許可
        }
    }

    //--- デストラクタ
    virtual ~CEnvSessionTimeWindow() {}

    //--- パラメータ設定
    virtual void SetParams(string paramsJson) override {
        CBlockBase::SetParams(paramsJson);
        m_useGlobal = GetParamBool(paramsJson, "useGlobal", true);
        m_enabled = GetParamBool(paramsJson, "enabled", false);

        // useGlobalがfalseの場合、個別設定をパースする（将来拡張）
        // 現在はuseGlobal=trueを前提とし、globalGuardsから設定を取得
    }

    //+------------------------------------------------------------------+
    //| グローバルセッション設定を適用                                       |
    //+------------------------------------------------------------------+
    void ApplyGlobalSession(const SessionConfig &session) {
        m_enabled = session.enabled;
        m_windowCount = session.windowCount;
        for (int i = 0; i < m_windowCount; i++) {
            m_windows[i] = session.windows[i];
        }
        for (int i = 0; i < 7; i++) {
            m_weekDays[i] = session.weekDays[i];
        }
    }

    //+------------------------------------------------------------------+
    //| ブロック評価                                                       |
    //+------------------------------------------------------------------+
    virtual void Evaluate(const Context &ctx, BlockResult &result) override {
        // セッション無効の場合は常にPASS
        if (!m_enabled) {
            result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL, "Session filter disabled");
            return;
        }

        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);

        // 曜日チェック（MQL5: 0=Sunday）
        int dow = dt.day_of_week;
        if (!m_weekDays[dow]) {
            string dowName;
            switch (dow) {
                case 0: dowName = "Sun"; break;
                case 1: dowName = "Mon"; break;
                case 2: dowName = "Tue"; break;
                case 3: dowName = "Wed"; break;
                case 4: dowName = "Thu"; break;
                case 5: dowName = "Fri"; break;
                case 6: dowName = "Sat"; break;
            }
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Day of week not allowed: " + dowName);
            return;
        }

        // 時間帯チェック
        int currentMinutes = dt.hour * 60 + dt.min;
        bool inWindow = false;

        for (int i = 0; i < m_windowCount; i++) {
            int startMin = ParseTimeToMinutes(m_windows[i].start);
            int endMin = ParseTimeToMinutes(m_windows[i].end);

            if (IsInWindow(currentMinutes, startMin, endMin)) {
                inWindow = true;
                break;
            }
        }

        if (!inWindow && m_windowCount > 0) {
            string currentTime = StringFormat("%02d:%02d", dt.hour, dt.min);
            result.Init(BLOCK_STATUS_FAIL, DIRECTION_NEUTRAL,
                       "Outside session window: " + currentTime);
            return;
        }

        string currentTime = StringFormat("%02d:%02d", dt.hour, dt.min);
        result.Init(BLOCK_STATUS_PASS, DIRECTION_NEUTRAL,
                   "In session window: " + currentTime);
    }
};

#endif // ENVSESSIONTIMEWINDOW_MQH
