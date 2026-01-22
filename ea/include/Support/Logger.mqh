//+------------------------------------------------------------------+
//|                                                      Logger.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                           JSONL形式ログ出力クラス                   |
//+------------------------------------------------------------------+
#ifndef LOGGER_MQH
#define LOGGER_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"

//+------------------------------------------------------------------+
//| Loggerクラス                                                       |
//+------------------------------------------------------------------+
class CLogger {
private:
    int      m_fileHandle;      // ログファイルハンドル
    string   m_logPath;         // ログファイルパス
    bool     m_initialized;     // 初期化済みフラグ
    string   m_currentDate;     // 現在の日付（ローテーション用）

    //--- JSON文字列エスケープ
    string EscapeJSON(string str) {
        string result = str;
        StringReplace(result, "\\", "\\\\");
        StringReplace(result, "\"", "\\\"");
        StringReplace(result, "\n", "\\n");
        StringReplace(result, "\r", "\\r");
        StringReplace(result, "\t", "\\t");
        return result;
    }

    //--- 行出力
    void WriteLine(string line) {
        if (m_fileHandle != INVALID_HANDLE) {
            FileWriteString(m_fileHandle, line + "\n");
            FileFlush(m_fileHandle);
        }
        // Expertログにも出力（デバッグ用）
        Print(line);
    }

    //--- 日付チェック（日次ローテーション）
    bool CheckDateRotation() {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        string date = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);

        if (date != m_currentDate) {
            // 日付が変わったらファイルを再オープン
            Cleanup();
            return Initialize(LOG_PATH_PREFIX);
        }
        return true;
    }

    //--- タイムスタンプ取得
    string GetTimestamp() {
        return TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
    }

public:
    //--- コンストラクタ
    CLogger() {
        m_fileHandle = INVALID_HANDLE;
        m_logPath = "";
        m_initialized = false;
        m_currentDate = "";
    }

    //--- デストラクタ
    ~CLogger() {
        Cleanup();
    }

    //--- 初期化
    bool Initialize(string logPathPrefix) {
        if (m_initialized) {
            return true;
        }

        // 日次ローテーション
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        m_currentDate = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);
        m_logPath = logPathPrefix + m_currentDate + LOG_FILE_EXTENSION;

        // ディレクトリ作成（存在しない場合）
        string dir = "strategy/logs";
        if (!FileIsExist(dir, FILE_COMMON)) {
            FolderCreate(dir);
        }

        // ファイルオープン（追記モード）
        m_fileHandle = FileOpen(m_logPath, FILE_WRITE | FILE_READ | FILE_TXT | FILE_SHARE_READ);
        if (m_fileHandle == INVALID_HANDLE) {
            Print("ERROR: Cannot open log file: ", m_logPath, " Error: ", GetLastError());
            m_initialized = false;
            return false;
        }

        // ファイル末尾に移動
        FileSeek(m_fileHandle, 0, SEEK_END);
        m_initialized = true;
        return true;
    }

    //--- クリーンアップ
    void Cleanup() {
        if (m_fileHandle != INVALID_HANDLE) {
            FileClose(m_fileHandle);
            m_fileHandle = INVALID_HANDLE;
        }
        m_initialized = false;
    }

    //--- 初期化済みかチェック
    bool IsInitialized() const {
        return m_initialized;
    }

    //+------------------------------------------------------------------+
    //| 設定読込結果ログ                                                   |
    //+------------------------------------------------------------------+
    void LogConfigLoaded(bool success, string version, int strategyCount, int blockCount) {
        CheckDateRotation();
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"CONFIG_LOADED\"," +
            "\"success\":" + (success ? "true" : "false") + "," +
            "\"version\":\"" + EscapeJSON(version) + "\"," +
            "\"strategyCount\":" + IntegerToString(strategyCount) + "," +
            "\"blockCount\":" + IntegerToString(blockCount) +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| 新バー評価開始ログ                                                 |
    //+------------------------------------------------------------------+
    void LogBarEvalStart(datetime barTime) {
        CheckDateRotation();
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"BAR_EVAL_START\"," +
            "\"symbol\":\"" + Symbol() + "\"," +
            "\"barTimeM1\":\"" + TimeToString(barTime, TIME_DATE | TIME_MINUTES) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| Strategy評価結果ログ                                               |
    //+------------------------------------------------------------------+
    void LogStrategyEval(string strategyId, bool adopted, string reason) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"STRATEGY_EVAL\"," +
            "\"strategyId\":\"" + EscapeJSON(strategyId) + "\"," +
            "\"adopted\":" + (adopted ? "true" : "false") + "," +
            "\"reason\":\"" + EscapeJSON(reason) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| RuleGroup評価結果ログ                                              |
    //+------------------------------------------------------------------+
    void LogRuleGroupEval(string ruleGroupId, bool matched) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"RULEGROUP_EVAL\"," +
            "\"ruleGroupId\":\"" + EscapeJSON(ruleGroupId) + "\"," +
            "\"matched\":" + (matched ? "true" : "false") +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| ブロック評価結果ログ                                               |
    //+------------------------------------------------------------------+
    void LogBlockEval(string blockId, string typeId, const BlockResult &result) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"BLOCK_EVAL\"," +
            "\"blockId\":\"" + EscapeJSON(blockId) + "\"," +
            "\"typeId\":\"" + EscapeJSON(typeId) + "\"," +
            "\"status\":\"" + BlockStatusToString(result.status) + "\"," +
            "\"reason\":\"" + EscapeJSON(result.reason) + "\"";

        // directionが有効な場合のみ追加
        if (result.direction != DIRECTION_NEUTRAL) {
            json += ",\"direction\":\"" + DirectionToString(result.direction) + "\"";
        }

        // scoreが有効な場合のみ追加
        if (result.score != 0.0) {
            json += ",\"score\":" + DoubleToString(result.score, 2);
        }

        json += "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| 発注試行ログ                                                       |
    //+------------------------------------------------------------------+
    void LogOrderAttempt(const OrderRequest &request) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"ORDER_ATTEMPT\"," +
            "\"symbol\":\"" + EscapeJSON(request.symbol) + "\"," +
            "\"direction\":\"" + DirectionToString(request.direction) + "\"," +
            "\"lot\":" + DoubleToString(request.lot, 2) + "," +
            "\"slPips\":" + DoubleToString(request.slPips, 1) + "," +
            "\"tpPips\":" + DoubleToString(request.tpPips, 1) + "," +
            "\"strategyId\":\"" + EscapeJSON(request.strategyId) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| 発注結果ログ                                                       |
    //+------------------------------------------------------------------+
    void LogOrderResult(bool success, ulong ticket, string reason) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"ORDER_RESULT\"," +
            "\"success\":" + (success ? "true" : "false") + "," +
            "\"ticket\":" + IntegerToString(ticket) + "," +
            "\"reason\":\"" + EscapeJSON(reason) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| 発注拒否ログ                                                       |
    //+------------------------------------------------------------------+
    void LogOrderReject(string rejectType, string reason) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"ORDER_REJECT\"," +
            "\"rejectType\":\"" + EscapeJSON(rejectType) + "\"," +
            "\"reason\":\"" + EscapeJSON(reason) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| 管理アクションログ                                                 |
    //+------------------------------------------------------------------+
    void LogManagementAction(string actionType, ulong ticket, string detail) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"MANAGEMENT_ACTION\"," +
            "\"actionType\":\"" + EscapeJSON(actionType) + "\"," +
            "\"ticket\":" + IntegerToString(ticket) + "," +
            "\"detail\":\"" + EscapeJSON(detail) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| ナンピンアクションログ                                              |
    //+------------------------------------------------------------------+
    void LogNanpinAction(string actionType, ulong ticket, int count, string detail) {
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"NANPIN_ACTION\"," +
            "\"actionType\":\"" + EscapeJSON(actionType) + "\"," +
            "\"ticket\":" + IntegerToString(ticket) + "," +
            "\"count\":" + IntegerToString(count) + "," +
            "\"detail\":\"" + EscapeJSON(detail) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| 一般情報ログ                                                       |
    //+------------------------------------------------------------------+
    void LogInfo(string eventName, string message) {
        CheckDateRotation();
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"" + EscapeJSON(eventName) + "\"," +
            "\"message\":\"" + EscapeJSON(message) + "\"" +
            "}";
        WriteLine(json);
    }

    //+------------------------------------------------------------------+
    //| エラーログ                                                        |
    //+------------------------------------------------------------------+
    void LogError(string eventName, string message) {
        CheckDateRotation();
        string json = "{" +
            "\"ts\":\"" + GetTimestamp() + "\"," +
            "\"event\":\"" + EscapeJSON(eventName) + "\"," +
            "\"level\":\"ERROR\"," +
            "\"message\":\"" + EscapeJSON(message) + "\"" +
            "}";
        WriteLine(json);

        // Expertログにも強調出力
        Print("[ERROR] ", eventName, ": ", message);
    }
};

#endif // LOGGER_MQH
