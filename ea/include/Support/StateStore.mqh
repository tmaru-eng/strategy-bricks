//+------------------------------------------------------------------+
//|                                                   StateStore.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                     状態管理クラス（lastEntryBarTime等）            |
//+------------------------------------------------------------------+
#ifndef STATESTORE_MQH
#define STATESTORE_MQH

#include "../Common/Constants.mqh"

//+------------------------------------------------------------------+
//| StateStoreクラス                                                   |
//| EA内の状態を一元管理し、グローバル変数で永続化                         |
//+------------------------------------------------------------------+
class CStateStore {
private:
    datetime m_lastEntryBarTime;    // 最後にエントリーしたバー時刻
    int      m_nanpinCount;         // 現在のナンピン段数（Phase 4）
    bool     m_initialized;         // 初期化済みフラグ

    // グローバル変数プレフィックス
    string   m_prefix;

    //--- グローバル変数名を生成
    string GetVarName(string suffix) {
        return m_prefix + "_" + Symbol() + "_" + suffix;
    }

public:
    //--- コンストラクタ
    CStateStore() {
        m_lastEntryBarTime = 0;
        m_nanpinCount = 0;
        m_initialized = false;
        m_prefix = "SB";  // Strategy Bricks
    }

    //--- デストラクタ
    ~CStateStore() {
        // 終了時に状態を永続化
        Persist();
    }

    //+------------------------------------------------------------------+
    //| 初期化（OnInit時に呼出、グローバル変数から復元）                     |
    //+------------------------------------------------------------------+
    void Initialize() {
        if (m_initialized) {
            return;
        }

        // lastEntryBarTimeの復元
        string varName = GetVarName("lastEntryBarTime");
        if (GlobalVariableCheck(varName)) {
            m_lastEntryBarTime = (datetime)GlobalVariableGet(varName);
            Print("StateStore: Restored lastEntryBarTime=",
                  TimeToString(m_lastEntryBarTime, TIME_DATE | TIME_MINUTES));
        } else {
            m_lastEntryBarTime = 0;
        }

        // nanpinCountの復元（Phase 4用）
        varName = GetVarName("nanpinCount");
        if (GlobalVariableCheck(varName)) {
            m_nanpinCount = (int)GlobalVariableGet(varName);
            Print("StateStore: Restored nanpinCount=", m_nanpinCount);
        } else {
            m_nanpinCount = 0;
        }

        m_initialized = true;
        Print("StateStore: Initialized for ", Symbol());
    }

    //+------------------------------------------------------------------+
    //| 永続化（状態をグローバル変数に保存）                                 |
    //+------------------------------------------------------------------+
    void Persist() {
        if (!m_initialized) {
            return;
        }

        // lastEntryBarTimeの永続化
        string varName = GetVarName("lastEntryBarTime");
        GlobalVariableSet(varName, (double)m_lastEntryBarTime);

        // nanpinCountの永続化（Phase 4用）
        varName = GetVarName("nanpinCount");
        GlobalVariableSet(varName, (double)m_nanpinCount);
    }

    //+------------------------------------------------------------------+
    //| 状態リセット（テスト用）                                           |
    //+------------------------------------------------------------------+
    void Reset() {
        m_lastEntryBarTime = 0;
        m_nanpinCount = 0;

        // グローバル変数も削除
        string varName = GetVarName("lastEntryBarTime");
        if (GlobalVariableCheck(varName)) {
            GlobalVariableDel(varName);
        }

        varName = GetVarName("nanpinCount");
        if (GlobalVariableCheck(varName)) {
            GlobalVariableDel(varName);
        }

        Print("StateStore: Reset completed");
    }

    //+------------------------------------------------------------------+
    //| lastEntryBarTime取得                                              |
    //+------------------------------------------------------------------+
    datetime GetLastEntryBarTime() const {
        return m_lastEntryBarTime;
    }

    //+------------------------------------------------------------------+
    //| lastEntryBarTime設定                                              |
    //+------------------------------------------------------------------+
    void SetLastEntryBarTime(datetime barTime) {
        m_lastEntryBarTime = barTime;
        // 即座に永続化
        string varName = GetVarName("lastEntryBarTime");
        GlobalVariableSet(varName, (double)m_lastEntryBarTime);
    }

    //+------------------------------------------------------------------+
    //| 同一足チェック（第二ガード）                                        |
    //+------------------------------------------------------------------+
    bool IsSameBarAsLastEntry(datetime currentBarTime) const {
        return (currentBarTime == m_lastEntryBarTime && m_lastEntryBarTime != 0);
    }

    //+------------------------------------------------------------------+
    //| nanpinCount取得（Phase 4用）                                       |
    //+------------------------------------------------------------------+
    int GetNanpinCount() const {
        return m_nanpinCount;
    }

    //+------------------------------------------------------------------+
    //| nanpinCount設定（Phase 4用）                                       |
    //+------------------------------------------------------------------+
    void SetNanpinCount(int count) {
        m_nanpinCount = count;
        string varName = GetVarName("nanpinCount");
        GlobalVariableSet(varName, (double)m_nanpinCount);
    }

    //+------------------------------------------------------------------+
    //| nanpinCountインクリメント（Phase 4用）                              |
    //+------------------------------------------------------------------+
    void IncrementNanpinCount() {
        m_nanpinCount++;
        string varName = GetVarName("nanpinCount");
        GlobalVariableSet(varName, (double)m_nanpinCount);
    }

    //+------------------------------------------------------------------+
    //| nanpinCountリセット（Phase 4用）                                    |
    //+------------------------------------------------------------------+
    void ResetNanpinCount() {
        m_nanpinCount = 0;
        string varName = GetVarName("nanpinCount");
        GlobalVariableSet(varName, (double)m_nanpinCount);
    }

    //+------------------------------------------------------------------+
    //| 初期化済みチェック                                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const {
        return m_initialized;
    }
};

#endif // STATESTORE_MQH
