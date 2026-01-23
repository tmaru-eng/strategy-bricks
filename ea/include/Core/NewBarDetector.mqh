//+------------------------------------------------------------------+
//|                                               NewBarDetector.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                              M1新バー検知クラス                      |
//+------------------------------------------------------------------+
#ifndef NEWBARDETECTOR_MQH
#define NEWBARDETECTOR_MQH

#include "../Common/Constants.mqh"

//+------------------------------------------------------------------+
//| NewBarDetectorクラス                                               |
//| M1新バー検知（第一ガード）                                           |
//+------------------------------------------------------------------+
class CNewBarDetector {
private:
    datetime m_lastBarTime;     // 前回バー時刻
    bool     m_isNewBar;        // 新バーフラグ

public:
    //--- コンストラクタ
    CNewBarDetector() {
        m_lastBarTime = 0;
        m_isNewBar = false;
    }

    //--- デストラクタ
    ~CNewBarDetector() {}

    //+------------------------------------------------------------------+
    //| 初期化                                                            |
    //+------------------------------------------------------------------+
    void Initialize() {
        m_lastBarTime = iTime(Symbol(), EA_TIMEFRAME, 0);
        m_isNewBar = false;
        Print("NewBarDetector: Initialized, lastBarTime=",
              TimeToString(m_lastBarTime, TIME_DATE | TIME_MINUTES));
    }

    //+------------------------------------------------------------------+
    //| 新バー検知                                                        |
    //+------------------------------------------------------------------+
    bool IsNewBar() {
        // M1の現在バー時刻を取得
        datetime currentBarTime = iTime(Symbol(), EA_TIMEFRAME, 0);

        // エラーチェック
        if (currentBarTime == 0) {
            Print("ERROR: NewBarDetector - iTime failed");
            m_isNewBar = false;
            return false;
        }

        // 前回と比較
        if (currentBarTime != m_lastBarTime) {
            m_lastBarTime = currentBarTime;
            m_isNewBar = true;
            return true;  // 新バー
        }

        m_isNewBar = false;
        return false;  // 同一バー
    }

    //+------------------------------------------------------------------+
    //| 現在のバー時刻取得                                                 |
    //+------------------------------------------------------------------+
    datetime GetCurrentBarTime() const {
        return m_lastBarTime;
    }

    //+------------------------------------------------------------------+
    //| 新バーフラグ取得                                                   |
    //+------------------------------------------------------------------+
    bool WasNewBar() const {
        return m_isNewBar;
    }

    //+------------------------------------------------------------------+
    //| バー時刻を強制更新（テスト用）                                       |
    //+------------------------------------------------------------------+
    void ForceUpdate(datetime barTime) {
        m_lastBarTime = barTime;
    }
};

#endif // NEWBARDETECTOR_MQH
