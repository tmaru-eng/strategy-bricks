//+------------------------------------------------------------------+
//|                                                 ConfigLoader.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                           JSON設定読み込みクラス                    |
//+------------------------------------------------------------------+
#ifndef CONFIGLOADER_MQH
#define CONFIGLOADER_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "../Support/JsonParser.mqh"
#include "../Support/Logger.mqh"

//+------------------------------------------------------------------+
//| ConfigLoaderクラス                                                 |
//+------------------------------------------------------------------+
class CConfigLoader {
private:
    CJsonParser m_parser;
    CLogger*    m_logger;

    //+------------------------------------------------------------------+
    //| メタ情報の解析                                                     |
    //+------------------------------------------------------------------+
    bool ParseMeta(string metaJson, MetaConfig &meta) {
        CJsonObject obj;
        obj.SetJson(metaJson);

        meta.formatVersion = obj.GetString("formatVersion", "");
        meta.name = obj.GetString("name", "");
        meta.generatedBy = obj.GetString("generatedBy", "");
        meta.generatedAt = obj.GetString("generatedAt", "");

        return (meta.formatVersion != "");
    }

    //+------------------------------------------------------------------+
    //| セッション設定の解析                                                |
    //+------------------------------------------------------------------+
    bool ParseSession(string sessionJson, SessionConfig &session) {
        CJsonObject obj;
        obj.SetJson(sessionJson);

        session.enabled = obj.GetBool("enabled", false);

        // windows配列の解析
        string windowsJson = obj.ExtractArray("windows");
        if (windowsJson != "") {
            m_parser.SetJson(windowsJson);
            int count = m_parser.GetArrayLength(windowsJson);
            session.windowCount = MathMin(count, 8);

            for (int i = 0; i < session.windowCount; i++) {
                string windowJson = m_parser.ExtractArrayElement(windowsJson, i);
                CJsonObject windowObj;
                windowObj.SetJson(windowJson);
                session.windows[i].start = windowObj.GetString("start", "00:00");
                session.windows[i].end = windowObj.GetString("end", "23:59");
            }
        }

        // weekDays解析
        string weekDaysJson = obj.ExtractObject("weekDays");
        if (weekDaysJson != "") {
            CJsonObject wdObj;
            wdObj.SetJson(weekDaysJson);
            session.weekDays[0] = wdObj.GetBool("sun", false);  // Sunday
            session.weekDays[1] = wdObj.GetBool("mon", true);
            session.weekDays[2] = wdObj.GetBool("tue", true);
            session.weekDays[3] = wdObj.GetBool("wed", true);
            session.weekDays[4] = wdObj.GetBool("thu", true);
            session.weekDays[5] = wdObj.GetBool("fri", true);
            session.weekDays[6] = wdObj.GetBool("sat", false);  // Saturday
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| グローバルガード設定の解析                                          |
    //+------------------------------------------------------------------+
    bool ParseGlobalGuards(string guardsJson, GlobalGuardsConfig &guards) {
        CJsonObject obj;
        obj.SetJson(guardsJson);

        guards.timeframe = obj.GetString("timeframe", "M1");
        guards.useClosedBarOnly = obj.GetBool("useClosedBarOnly", true);
        guards.noReentrySameBar = obj.GetBool("noReentrySameBar", true);
        guards.maxPositionsTotal = obj.GetInt("maxPositionsTotal", DEFAULT_MAX_POSITIONS);
        guards.maxPositionsPerSymbol = obj.GetInt("maxPositionsPerSymbol", DEFAULT_MAX_POSITIONS);
        guards.maxSpreadPips = obj.GetDouble("maxSpreadPips", DEFAULT_MAX_SPREAD_PIPS);

        // セッション設定
        string sessionJson = obj.ExtractObject("session");
        if (sessionJson != "") {
            ParseSession(sessionJson, guards.session);
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| モデル設定の解析                                                   |
    //+------------------------------------------------------------------+
    bool ParseModel(string modelJson, ModelConfig &model) {
        CJsonObject obj;
        obj.SetJson(modelJson);

        model.typeId = obj.GetString("type", "");
        model.paramsJson = obj.ExtractObject("params");

        // 頻繁に使用するパラメータを直接解析
        if (model.paramsJson != "") {
            CJsonObject paramsObj;
            paramsObj.SetJson(model.paramsJson);
            model.lots = paramsObj.GetDouble("lots", DEFAULT_LOT);
            model.slPips = paramsObj.GetDouble("slPips", DEFAULT_SL_PIPS);
            model.tpPips = paramsObj.GetDouble("tpPips", DEFAULT_TP_PIPS);
        }

        return (model.typeId != "");
    }

    //+------------------------------------------------------------------+
    //| エントリー要件の解析                                                |
    //+------------------------------------------------------------------+
    bool ParseEntryRequirement(string reqJson, EntryRequirement &requirement) {
        CJsonObject obj;
        obj.SetJson(reqJson);

        // ruleGroups配列の解析
        string ruleGroupsJson = obj.ExtractArray("ruleGroups");
        if (ruleGroupsJson == "") {
            return false;
        }

        m_parser.SetJson(ruleGroupsJson);
        int count = m_parser.GetArrayLength(ruleGroupsJson);
        requirement.ruleGroupCount = MathMin(count, MAX_RULE_GROUPS);

        for (int i = 0; i < requirement.ruleGroupCount; i++) {
            string rgJson = m_parser.ExtractArrayElement(ruleGroupsJson, i);
            CJsonObject rgObj;
            rgObj.SetJson(rgJson);

            requirement.ruleGroups[i].id = rgObj.GetString("id", "RG" + IntegerToString(i));

            // conditions配列の解析
            string conditionsJson = rgObj.ExtractArray("conditions");
            if (conditionsJson != "") {
                CJsonParser condParser;
                condParser.SetJson(conditionsJson);
                int condCount = condParser.GetArrayLength(conditionsJson);
                requirement.ruleGroups[i].conditionCount = MathMin(condCount, MAX_CONDITIONS);

                for (int j = 0; j < requirement.ruleGroups[i].conditionCount; j++) {
                    string condJson = condParser.ExtractArrayElement(conditionsJson, j);
                    CJsonObject condObj;
                    condObj.SetJson(condJson);
                    requirement.ruleGroups[i].conditions[j].blockId = condObj.GetString("blockId", "");
                }
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| Strategy設定の解析                                                 |
    //+------------------------------------------------------------------+
    bool ParseStrategy(string strategyJson, StrategyConfig &strategy) {
        CJsonObject obj;
        obj.SetJson(strategyJson);

        strategy.id = obj.GetString("id", "");
        strategy.name = obj.GetString("name", "");
        strategy.enabled = obj.GetBool("enabled", true);
        strategy.priority = obj.GetInt("priority", 0);

        // conflictPolicy
        string conflictPolicyStr = obj.GetString("conflictPolicy", "firstOnly");
        if (conflictPolicyStr == "firstOnly")
            strategy.conflictPolicy = CONFLICT_FIRST_ONLY;
        else if (conflictPolicyStr == "bestScore")
            strategy.conflictPolicy = CONFLICT_BEST_SCORE;
        else if (conflictPolicyStr == "all")
            strategy.conflictPolicy = CONFLICT_ALL;

        // directionPolicy
        string directionPolicyStr = obj.GetString("directionPolicy", "both");
        if (directionPolicyStr == "longOnly")
            strategy.directionPolicy = POLICY_LONG_ONLY;
        else if (directionPolicyStr == "shortOnly")
            strategy.directionPolicy = POLICY_SHORT_ONLY;
        else
            strategy.directionPolicy = POLICY_BOTH;

        // entryRequirement
        string entryReqJson = obj.ExtractObject("entryRequirement");
        if (entryReqJson != "") {
            ParseEntryRequirement(entryReqJson, strategy.entryRequirement);
        }

        // モデル設定
        string lotModelJson = obj.ExtractObject("lotModel");
        if (lotModelJson != "") {
            ParseModel(lotModelJson, strategy.lotModel);
        }

        string riskModelJson = obj.ExtractObject("riskModel");
        if (riskModelJson != "") {
            ParseModel(riskModelJson, strategy.riskModel);
        }

        string exitModelJson = obj.ExtractObject("exitModel");
        if (exitModelJson != "") {
            ParseModel(exitModelJson, strategy.exitModel);
        }

        string nanpinModelJson = obj.ExtractObject("nanpinModel");
        if (nanpinModelJson != "") {
            ParseModel(nanpinModelJson, strategy.nanpinModel);
        }

        return (strategy.id != "");
    }

    //+------------------------------------------------------------------+
    //| ブロック定義の解析                                                 |
    //+------------------------------------------------------------------+
    bool ParseBlock(string blockJson, BlockDefinition &block) {
        CJsonObject obj;
        obj.SetJson(blockJson);

        block.id = obj.GetString("id", "");
        block.typeId = obj.GetString("typeId", "");
        block.paramsJson = obj.ExtractObject("params");

        return (block.id != "" && block.typeId != "");
    }

public:
    //--- コンストラクタ
    CConfigLoader() {
        m_logger = NULL;
    }

    //--- ロガー設定
    void SetLogger(CLogger *logger) {
        m_logger = logger;
    }

    //+------------------------------------------------------------------+
    //| 設定ファイル読込                                                   |
    //+------------------------------------------------------------------+
    bool Load(string path, Config &config) {
        config.Reset();

        // ファイル存在確認
        if (!FileIsExist(path)) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_ERROR", "File not found: " + path);
            }
            Print("ERROR: Config file not found: ", path);
            return false;
        }

        // ファイル読込
        int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
        if (handle == INVALID_HANDLE) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_ERROR", "Cannot open file: " + path);
            }
            Print("ERROR: Cannot open config file: ", path, " Error: ", GetLastError());
            return false;
        }

        string jsonContent = "";
        while (!FileIsEnding(handle)) {
            jsonContent += FileReadString(handle) + "\n";
        }
        FileClose(handle);

        // JSON全体をパーサーに設定
        m_parser.SetJson(jsonContent);

        // meta解析
        string metaJson = m_parser.ExtractObject("meta");
        if (metaJson == "") {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_ERROR", "meta section not found");
            }
            return false;
        }
        if (!ParseMeta(metaJson, config.meta)) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_ERROR", "Failed to parse meta section");
            }
            return false;
        }

        // globalGuards解析
        m_parser.SetJson(jsonContent);
        string guardsJson = m_parser.ExtractObject("globalGuards");
        if (guardsJson != "") {
            ParseGlobalGuards(guardsJson, config.globalGuards);
        }

        // strategies解析
        m_parser.SetJson(jsonContent);
        string strategiesJson = m_parser.ExtractArray("strategies");
        if (strategiesJson != "") {
            int count = m_parser.GetArrayLength(strategiesJson);
            config.strategyCount = MathMin(count, MAX_STRATEGIES);

            for (int i = 0; i < config.strategyCount; i++) {
                string strategyJson = m_parser.ExtractArrayElement(strategiesJson, i);
                ParseStrategy(strategyJson, config.strategies[i]);
            }
        }

        // blocks解析
        m_parser.SetJson(jsonContent);
        string blocksJson = m_parser.ExtractArray("blocks");
        if (blocksJson != "") {
            int count = m_parser.GetArrayLength(blocksJson);
            config.blockCount = MathMin(count, MAX_BLOCKS);

            for (int i = 0; i < config.blockCount; i++) {
                string blockJson = m_parser.ExtractArrayElement(blocksJson, i);
                ParseBlock(blockJson, config.blocks[i]);
            }
        }

        Print("ConfigLoader: Loaded ", config.strategyCount, " strategies, ",
              config.blockCount, " blocks");
        return true;
    }

    //+------------------------------------------------------------------+
    //| ブロック定義を取得（ID指定）                                        |
    //+------------------------------------------------------------------+
    bool GetBlockDefinition(const Config &config, string blockId, BlockDefinition &block) {
        for (int i = 0; i < config.blockCount; i++) {
            if (config.blocks[i].id == blockId) {
                block = config.blocks[i];
                return true;
            }
        }
        return false;
    }
};

#endif // CONFIGLOADER_MQH
