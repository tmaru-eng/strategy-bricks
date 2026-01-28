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

    //+------------------------------------------------------------------+
    //| blockId参照の検証                                                  |
    //| すべてのcondition.blockIdがblocks[]に存在することを確認              |
    //+------------------------------------------------------------------+
    bool ValidateBlockReferences(const Config &config) {
        // blocks[]からblockIdセットを構築
        string blockIds[];
        ArrayResize(blockIds, config.blockCount);
        for (int i = 0; i < config.blockCount; i++) {
            blockIds[i] = config.blocks[i].id;
        }

        // すべてのstrategyのconditionを検証
        for (int s = 0; s < config.strategyCount; s++) {
            const StrategyConfig strategy = config.strategies[s];
            const EntryRequirement req = strategy.entryRequirement;

            for (int rg = 0; rg < req.ruleGroupCount; rg++) {
                const RuleGroup ruleGroup = req.ruleGroups[rg];

                for (int c = 0; c < ruleGroup.conditionCount; c++) {
                    string blockId = ruleGroup.conditions[c].blockId;

                    // blockIdが存在するか確認
                    if (!ArrayContains(blockIds, config.blockCount, blockId)) {
                        if (m_logger != NULL) {
                            string errorMsg = StringFormat(
                                "blockId '%s' not found in blocks[] (Strategy: %s, RuleGroup: %s)",
                                blockId, strategy.id, ruleGroup.id
                            );
                            m_logger.LogError("UNRESOLVED_BLOCK_REFERENCE", errorMsg);
                        }
                        Print("ERROR: Unresolved block reference: ", blockId,
                              " in Strategy: ", strategy.id, ", RuleGroup: ", ruleGroup.id);
                        return false;
                    }
                }
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| 配列に要素が含まれるか確認                                          |
    //+------------------------------------------------------------------+
    bool ArrayContains(const string &arr[], int size, const string &value) {
        for (int i = 0; i < size; i++) {
            if (arr[i] == value) return true;
        }
        return false;
    }

    //+------------------------------------------------------------------+
    //| blockId重複の検証                                                  |
    //| blocks[]配列内の重複blockIdを検出                                   |
    //+------------------------------------------------------------------+
    bool ValidateDuplicateBlockIds(const Config &config) {
        // blocks[]配列内の重複をチェック
        for (int i = 0; i < config.blockCount; i++) {
            string blockId = config.blocks[i].id;
            
            // 同じblockIdが他に存在するか確認
            for (int j = i + 1; j < config.blockCount; j++) {
                if (config.blocks[j].id == blockId) {
                    // 重複を検出 - 詳細にログ出力
                    if (m_logger != NULL) {
                        string errorMsg = StringFormat(
                            "Duplicate blockId '%s' found in blocks[] at indices %d and %d",
                            blockId, i, j
                        );
                        m_logger.LogError("DUPLICATE_BLOCK_ID", errorMsg);
                    }
                    Print("ERROR: Duplicate blockId detected: ", blockId,
                          " at indices ", i, " and ", j);
                    return false;
                }
            }
        }
        
        return true;
    }

    //+------------------------------------------------------------------+
    //| 文字列が数値か確認                                                  |
    //+------------------------------------------------------------------+
    bool IsNumeric(const string &str) {
        int len = StringLen(str);
        if (len == 0) return false;
        
        for (int i = 0; i < len; i++) {
            ushort ch = StringGetCharacter(str, i);
            if (ch < '0' || ch > '9') return false;
        }
        return true;
    }

    //+------------------------------------------------------------------+
    //| blockId形式の検証                                                  |
    //| blockIdが{typeId}#{index}形式に従うことを検証                       |
    //+------------------------------------------------------------------+
    bool ValidateBlockIdFormat(const Config &config) {
        for (int i = 0; i < config.blockCount; i++) {
            string blockId = config.blocks[i].id;
            
            // 形式チェック: {typeId}#{index}
            int hashPos = StringFind(blockId, "#");
            if (hashPos < 0) {
                // '#'セパレータが見つからない
                if (m_logger != NULL) {
                    string errorMsg = StringFormat(
                        "blockId '%s' does not contain '#' separator",
                        blockId
                    );
                    m_logger.LogError("INVALID_BLOCK_ID_FORMAT", errorMsg);
                }
                Print("ERROR: Invalid blockId format (missing '#'): ", blockId);
                return false;
            }
            
            // インデックス部分が数値か確認
            string indexPart = StringSubstr(blockId, hashPos + 1);
            if (!IsNumeric(indexPart)) {
                // インデックス部分が数値でない
                if (m_logger != NULL) {
                    string errorMsg = StringFormat(
                        "blockId '%s' has non-numeric index part '%s'",
                        blockId, indexPart
                    );
                    m_logger.LogError("INVALID_BLOCK_ID_FORMAT", errorMsg);
                }
                Print("ERROR: Invalid blockId format (non-numeric index): ", blockId);
                return false;
            }
        }
        
        return true;
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

        // ファイル存在確認（FILE_COMMONフラグを追加してテスター対応）
        if (!FileIsExist(path, FILE_COMMON)) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_ERROR", "File not found: " + path);
            }
            Print("ERROR: Config file not found: ", path);
            return false;
        }

        // ファイル読込（FILE_COMMONフラグを追加してテスター対応）
        int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
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

        // globalGuards解析（m_parserは286行目で設定済み）
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

        // blockId参照の検証
        if (!ValidateBlockReferences(config)) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_VALIDATION_FAILED", "Block reference validation failed");
            }
            Print("ERROR: Config validation failed - unresolved block references");
            return false;
        }

        // blockId重複の検証
        if (!ValidateDuplicateBlockIds(config)) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_VALIDATION_FAILED", "Duplicate blockId detected");
            }
            Print("ERROR: Config validation failed - duplicate blockIds");
            return false;
        }

        // blockId形式の検証
        if (!ValidateBlockIdFormat(config)) {
            if (m_logger != NULL) {
                m_logger.LogError("CONFIG_VALIDATION_FAILED", "Invalid blockId format detected");
            }
            Print("ERROR: Config validation failed - invalid blockId format");
            return false;
        }

        // 成功時のログ記録
        if (m_logger != NULL) {
            string successMsg = StringFormat(
                "Config loaded successfully: %d strategies, %d blocks",
                config.strategyCount, config.blockCount
            );
            m_logger.LogInfo("CONFIG_LOADED", successMsg);
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
