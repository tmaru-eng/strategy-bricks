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

    //+------------------------------------------------------------------+
    //| Strategy必須フィールド検証（ヘルパー関数 - const参照）              |
    //+------------------------------------------------------------------+
    bool ValidateStrategyRequiredFields(const StrategyConfig &strat, int index) {
        if (strat.id == "") {
            SetError("strategies[" + IntegerToString(index) + "].id is required");
            return false;
        }

        if (strat.entryRequirement.ruleGroupCount == 0) {
            SetError("strategies[" + IntegerToString(index) +
                    "].entryRequirement.ruleGroups[] is empty");
            return false;
        }

        if (strat.lotModel.typeId == "") {
            SetError("strategies[" + IntegerToString(index) + "].lotModel.type is required");
            return false;
        }

        if (strat.riskModel.typeId == "") {
            SetError("strategies[" + IntegerToString(index) + "].riskModel.type is required");
            return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| RuleGroup内のブロック参照検証（ヘルパー関数 - const参照）           |
    //+------------------------------------------------------------------+
    bool ValidateRuleGroupBlockRefs(const RuleGroup &rg, const Config &config,
                                     const string &stratId) {
        for (int k = 0; k < rg.conditionCount; k++) {
            string blockId = rg.conditions[k].blockId;

            if (!IsBlockIdExists(config, blockId)) {
                SetError("Block not found: " + blockId +
                        " (referenced in " + stratId + "." + rg.id + ")");
                return false;
            }
        }
        return true;
    }

    //+------------------------------------------------------------------+
    //| Strategy内のブロック参照検証（ヘルパー関数 - const参照）            |
    //+------------------------------------------------------------------+
    bool ValidateStrategyBlockRefs(const StrategyConfig &strat, const Config &config) {
        for (int j = 0; j < strat.entryRequirement.ruleGroupCount; j++) {
            if (!ValidateRuleGroupBlockRefs(strat.entryRequirement.ruleGroups[j],
                                            config, strat.id)) {
                return false;
            }
        }
        return true;
    }

    //+------------------------------------------------------------------+
    //| Strategyモデルパラメータ検証（ヘルパー関数 - const参照）            |
    //+------------------------------------------------------------------+
    bool ValidateStrategyModelParams(const StrategyConfig &strat, int index) {
        // ロット値
        if (strat.lotModel.typeId == "lot.fixed" && strat.lotModel.lots <= 0) {
            SetError("strategies[" + IntegerToString(index) +
                    "].lotModel.params.lots must be > 0");
            return false;
        }

        // SL/TP値
        if (strat.riskModel.typeId == "risk.fixedSLTP") {
            if (strat.riskModel.slPips < 0) {
                SetError("strategies[" + IntegerToString(index) +
                        "].riskModel.params.slPips must be >= 0");
                return false;
            }
            if (strat.riskModel.tpPips < 0) {
                SetError("strategies[" + IntegerToString(index) +
                        "].riskModel.params.tpPips must be >= 0");
                return false;
            }
        }

        return true;
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

        // 各Strategyの必須フィールドチェック（ヘルパー関数経由でconst参照）
        for (int i = 0; i < config.strategyCount; i++) {
            if (!ValidateStrategyRequiredFields(config.strategies[i], i)) {
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
            if (!ValidateStrategyBlockRefs(config.strategies[i], config)) {
                return false;
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
        // Keep in sync with BlockRegistry supported typeIds.
        string validTypes[] = {
            "filter.spreadMax",
            "filter.volatility.atrRange",
            "filter.volatility.stddevRange",
            "env.session.timeWindow",
            "filter.session.timeWindow",
            "filter.session.daysOfWeek",
            "trend.maRelation",
            "trend.maCross",
            "trend.adxThreshold",
            "trend.ichimokuCloud",
            "trend.sarDirection",
            "trigger.bbReentry",
            "trigger.bbBreakout",
            "trigger.macdCross",
            "trigger.stochCross",
            "trigger.rsiLevel",
            "trigger.cciLevel",
            "trigger.sarFlip",
            "trigger.wprLevel",
            "trigger.mfiLevel",
            "trigger.rviCross",
            "osc.momentum",
            "osc.osma",
            "osc.forceIndex",
            "volume.obvTrend",
            "bill.fractals",
            "bill.alligator",
            // Models (non-blocks but included for completeness)
            "lot.fixed",
            "lot.riskPercent",
            "risk.fixedSLTP",
            "risk.atrBased",
            "exit.none",
            "exit.trail",
            "exit.breakEven",
            "exit.weekendClose",
            "nanpin.off",
            "nanpin.fixed"
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

        // 各Strategyのモデルパラメータチェック（ヘルパー関数経由でconst参照）
        for (int i = 0; i < config.strategyCount; i++) {
            if (!ValidateStrategyModelParams(config.strategies[i], i)) {
                return false;
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
