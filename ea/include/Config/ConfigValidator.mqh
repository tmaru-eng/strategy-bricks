//+------------------------------------------------------------------+
//|                                             ConfigValidator.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                                 設定検証クラス                      |
//+------------------------------------------------------------------+
#ifndef CONFIGVALIDATOR_MQH
#define CONFIGVALIDATOR_MQH

#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structures.mqh"
#include "../Support/Logger.mqh"

//+------------------------------------------------------------------+
//| ConfigValidatorクラス                                              |
//+------------------------------------------------------------------+
class CConfigValidator {
private:
    CLogger* m_logger;
    string   m_lastError;

    //+------------------------------------------------------------------+
    //| エラー設定                                                        |
    //+------------------------------------------------------------------+
    void SetError(string error) {
        m_lastError = error;
        if (m_logger != NULL) {
            m_logger.LogError("CONFIG_ERROR", error);
        }
        Print("CONFIG_ERROR: ", error);
    }

public:
    //--- コンストラクタ
    CConfigValidator() {
        m_logger = NULL;
        m_lastError = "";
    }

    //--- ロガー設定
    void SetLogger(CLogger *logger) {
        m_logger = logger;
    }

    //--- 最後のエラー取得
    string GetLastError() const {
        return m_lastError;
    }

    //+------------------------------------------------------------------+
    //| formatVersionチェック                                             |
    //+------------------------------------------------------------------+
    bool ValidateFormatVersion(const Config &config) {
        string version = config.meta.formatVersion;

        if (version == "") {
            SetError("meta.formatVersion is required");
            return false;
        }

        // サポート範囲チェック（現在は1.0のみ）
        if (version != FORMAT_VERSION_MIN) {
            SetError("Unsupported formatVersion: " + version +
                    " (Supported: " + FORMAT_VERSION_MIN + ")");
            return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| 必須フィールドチェック                                             |
    //+------------------------------------------------------------------+
    bool ValidateRequiredFields(const Config &config) {
        // globalGuards必須チェック
        if (config.globalGuards.timeframe != "M1") {
            SetError("globalGuards.timeframe must be M1");
            return false;
        }

        if (!config.globalGuards.useClosedBarOnly) {
            SetError("globalGuards.useClosedBarOnly must be true");
            return false;
        }

        if (!config.globalGuards.noReentrySameBar) {
            SetError("globalGuards.noReentrySameBar must be true");
            return false;
        }

        // strategies[]必須チェック
        if (config.strategyCount == 0) {
            SetError("strategies[] is empty");
            return false;
        }

        // 各Strategyの必須フィールドチェック
        for (int i = 0; i < config.strategyCount; i++) {
            StrategyConfig strat = config.strategies[i];  // ローカルコピー

            if (strat.id == "") {
                SetError("strategies[" + IntegerToString(i) + "].id is required");
                return false;
            }

            if (strat.entryRequirement.ruleGroupCount == 0) {
                SetError("strategies[" + IntegerToString(i) +
                        "].entryRequirement.ruleGroups[] is empty");
                return false;
            }

            // lotModel必須チェック
            if (strat.lotModel.typeId == "") {
                SetError("strategies[" + IntegerToString(i) + "].lotModel.type is required");
                return false;
            }

            // riskModel必須チェック
            if (strat.riskModel.typeId == "") {
                SetError("strategies[" + IntegerToString(i) + "].riskModel.type is required");
                return false;
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| ブロック参照チェック                                               |
    //+------------------------------------------------------------------+
    bool ValidateBlockReferences(const Config &config) {
        // 各Strategyのconditionsが参照するblockIdが存在するか確認
        for (int i = 0; i < config.strategyCount; i++) {
            StrategyConfig strat = config.strategies[i];  // ローカルコピー

            for (int j = 0; j < strat.entryRequirement.ruleGroupCount; j++) {
                RuleGroup rg = strat.entryRequirement.ruleGroups[j];  // ローカルコピー

                for (int k = 0; k < rg.conditionCount; k++) {
                    string blockId = rg.conditions[k].blockId;

                    if (!IsBlockIdExists(config, blockId)) {
                        SetError("Block not found: " + blockId +
                                " (referenced in " + strat.id + "." + rg.id + ")");
                        return false;
                    }
                }
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| ブロックID存在チェック                                             |
    //+------------------------------------------------------------------+
    bool IsBlockIdExists(const Config &config, string blockId) {
        for (int i = 0; i < config.blockCount; i++) {
            if (config.blocks[i].id == blockId) {
                return true;
            }
        }
        return false;
    }

    //+------------------------------------------------------------------+
    //| ブロックtypeIdの検証（MVPブロックのみ）                              |
    //+------------------------------------------------------------------+
    bool ValidateBlockTypes(const Config &config) {
        // MVPで対応するブロックtypeId
        string validTypes[] = {
            "filter.spreadMax",
            "env.session.timeWindow",
            "trend.maRelation",
            "trigger.bbReentry",
            "lot.fixed",
            "risk.fixedSLTP",
            "exit.none",
            "nanpin.off"
        };

        for (int i = 0; i < config.blockCount; i++) {
            string typeId = config.blocks[i].typeId;
            bool found = false;

            for (int j = 0; j < ArraySize(validTypes); j++) {
                if (typeId == validTypes[j]) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                SetError("Unknown block typeId: " + typeId +
                        " (blockId: " + config.blocks[i].id + ")");
                return false;
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| 設定値の範囲チェック                                               |
    //+------------------------------------------------------------------+
    bool ValidateValueRanges(const Config &config) {
        // maxPositionsTotal
        if (config.globalGuards.maxPositionsTotal < 1) {
            SetError("globalGuards.maxPositionsTotal must be >= 1");
            return false;
        }

        // maxPositionsPerSymbol
        if (config.globalGuards.maxPositionsPerSymbol < 1) {
            SetError("globalGuards.maxPositionsPerSymbol must be >= 1");
            return false;
        }

        // maxSpreadPips
        if (config.globalGuards.maxSpreadPips < 0) {
            SetError("globalGuards.maxSpreadPips must be >= 0");
            return false;
        }

        // 各Strategyのモデルパラメータチェック
        for (int i = 0; i < config.strategyCount; i++) {
            StrategyConfig strat = config.strategies[i];  // ローカルコピー

            // ロット値
            if (strat.lotModel.typeId == "lot.fixed" && strat.lotModel.lots <= 0) {
                SetError("strategies[" + IntegerToString(i) +
                        "].lotModel.params.lots must be > 0");
                return false;
            }

            // SL/TP値
            if (strat.riskModel.typeId == "risk.fixedSLTP") {
                if (strat.riskModel.slPips < 0) {
                    SetError("strategies[" + IntegerToString(i) +
                            "].riskModel.params.slPips must be >= 0");
                    return false;
                }
                if (strat.riskModel.tpPips < 0) {
                    SetError("strategies[" + IntegerToString(i) +
                            "].riskModel.params.tpPips must be >= 0");
                    return false;
                }
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| 全検証実行                                                        |
    //+------------------------------------------------------------------+
    bool Validate(const Config &config) {
        m_lastError = "";

        // 1. formatVersionチェック
        if (!ValidateFormatVersion(config)) {
            return false;
        }

        // 2. 必須フィールドチェック
        if (!ValidateRequiredFields(config)) {
            return false;
        }

        // 3. ブロック参照チェック
        if (!ValidateBlockReferences(config)) {
            return false;
        }

        // 4. ブロックtypeIdの検証
        if (!ValidateBlockTypes(config)) {
            return false;
        }

        // 5. 設定値の範囲チェック
        if (!ValidateValueRanges(config)) {
            return false;
        }

        Print("ConfigValidator: Validation passed");
        return true;
    }
};

#endif // CONFIGVALIDATOR_MQH
