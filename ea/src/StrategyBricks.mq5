//+------------------------------------------------------------------+
//|                                               StrategyBricks.mq5 |
//|                                         Strategy Bricks EA MVP   |
//|                          JSON設定駆動型MT5エキスパートアドバイザー     |
//+------------------------------------------------------------------+
#property copyright "Strategy Bricks"
#property link      "https://github.com/strategy-bricks"
#property version   "1.00"
#property description "Strategy Bricks - JSON設定駆動型EA"
#property description "M1新バー時のみ評価、確定足（shift=1）基準"
#property strict

//+------------------------------------------------------------------+
//| インクルード                                                        |
//+------------------------------------------------------------------+
#include "../include/Common/Constants.mqh"
#include "../include/Common/Enums.mqh"
#include "../include/Common/Structures.mqh"

#include "../include/Support/Logger.mqh"
#include "../include/Support/StateStore.mqh"
#include "../include/Support/JsonParser.mqh"

#include "../include/Config/ConfigLoader.mqh"
#include "../include/Config/ConfigValidator.mqh"

#include "../include/Indicators/IndicatorCache.mqh"

#include "../include/Blocks/IBlock.mqh"
#include "../include/Core/BlockRegistry.mqh"

#include "../include/Execution/OrderExecutor.mqh"
#include "../include/Execution/PositionManager.mqh"

#include "../include/Core/NewBarDetector.mqh"
#include "../include/Core/CompositeEvaluator.mqh"
#include "../include/Core/StrategyEngine.mqh"

//+------------------------------------------------------------------+
//| 入力パラメータ                                                      |
//+------------------------------------------------------------------+
input string InpConfigPath = "strategy/active.json";   // 設定ファイルパス
input bool   InpEnableLogging = true;                  // ログ出力有効

//+------------------------------------------------------------------+
//| グローバル変数                                                      |
//+------------------------------------------------------------------+
Config              g_config;               // 設定
CLogger             g_logger;               // ロガー
CStateStore         g_stateStore;           // 状態管理
CConfigLoader       g_configLoader;         // 設定読込
CConfigValidator    g_configValidator;      // 設定検証
CIndicatorCache     g_indicatorCache;       // インジケータキャッシュ
CBlockRegistry      g_blockRegistry;        // ブロックレジストリ
CNewBarDetector     g_newBarDetector;       // 新バー検知
CCompositeEvaluator g_evaluator;            // 複合評価器
CStrategyEngine     g_strategyEngine;       // 戦略エンジン
COrderExecutor      g_orderExecutor;        // 発注実行
CPositionManager    g_positionManager;      // ポジション管理

bool                g_initialized = false;  // 初期化成功フラグ

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    Print("=== Strategy Bricks EA MVP v", EA_VERSION, " ===");
    Print("Symbol: ", Symbol(), " Timeframe: M1");

    //--- ロガー初期化
    if (InpEnableLogging) {
        if (!g_logger.Initialize(LOG_PATH_PREFIX)) {
            Print("WARNING: Logger initialization failed, logging disabled");
        }
    }
    g_logger.LogInfo("INIT_START", "Strategy Bricks EA starting...");

    //--- 設定読込
    g_configLoader.SetLogger(&g_logger);
    if (!g_configLoader.Load(InpConfigPath, g_config)) {
        g_logger.LogError("CONFIG_ERROR", "Failed to load config: " + InpConfigPath);
        return INIT_FAILED;
    }

    //--- 設定検証
    g_configValidator.SetLogger(&g_logger);
    if (!g_configValidator.Validate(g_config)) {
        g_logger.LogError("CONFIG_ERROR", "Config validation failed: " +
                         g_configValidator.GetLastError());
        return INIT_FAILED;
    }

    //--- ログ：設定読込成功
    g_logger.LogConfigLoaded(true, g_config.meta.formatVersion,
                            g_config.strategyCount, g_config.blockCount);

    //--- 状態管理初期化
    g_stateStore.Initialize();

    //--- インジケータキャッシュ初期化
    g_indicatorCache.Initialize();
    g_indicatorCache.SetLogger(&g_logger);

    //--- ブロックレジストリ初期化
    g_blockRegistry.Initialize();
    g_blockRegistry.SetGlobalSession(g_config.globalGuards.session);

    //--- ブロック事前生成
    if (!g_blockRegistry.PreloadBlocks(g_config)) {
        g_logger.LogError("BLOCK_ERROR", "Failed to preload blocks");
        return INIT_FAILED;
    }

    //--- 複合評価器初期化
    g_evaluator.SetConfig(g_config);
    g_evaluator.SetBlockRegistry(&g_blockRegistry);
    g_evaluator.SetIndicatorCache(&g_indicatorCache);
    g_evaluator.SetLogger(&g_logger);

    //--- 発注実行初期化
    g_orderExecutor.SetStateStore(&g_stateStore);
    g_orderExecutor.SetLogger(&g_logger);
    g_orderExecutor.Initialize();

    //--- ポジション管理初期化
    g_positionManager.SetConfig(g_config);
    g_positionManager.SetLogger(&g_logger);
    g_positionManager.SetStateStore(&g_stateStore);
    g_positionManager.Initialize();

    //--- 戦略エンジン初期化
    g_strategyEngine.SetConfig(g_config);
    g_strategyEngine.SetCompositeEvaluator(&g_evaluator);
    g_strategyEngine.SetOrderExecutor(&g_orderExecutor);
    g_strategyEngine.SetPositionManager(&g_positionManager);
    g_strategyEngine.SetLogger(&g_logger);
    g_strategyEngine.SetStateStore(&g_stateStore);
    g_strategyEngine.Initialize();

    //--- 新バー検知初期化
    g_newBarDetector.Initialize();

    g_initialized = true;
    g_logger.LogInfo("INIT_COMPLETE", "Strategy Bricks EA initialized successfully");
    Print("Strategy Bricks EA initialized successfully");
    Print("Config: ", g_config.meta.name, " (v", g_config.meta.formatVersion, ")");
    Print("Strategies: ", g_config.strategyCount, ", Blocks: ", g_config.blockCount);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    g_logger.LogInfo("DEINIT", "Deinit reason: " + IntegerToString(reason));

    //--- 状態永続化
    g_stateStore.Persist();

    //--- インジケータキャッシュ解放
    g_indicatorCache.Cleanup();

    //--- ブロックレジストリ解放
    g_blockRegistry.Cleanup();

    //--- ロガー解放
    g_logger.Cleanup();

    Print("Strategy Bricks EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick() {
    //--- 初期化失敗時は何もしない
    if (!g_initialized) {
        return;
    }

    //--- 新バー検知
    bool isNewBar = g_newBarDetector.IsNewBar();

    if (isNewBar) {
        datetime barTime = g_newBarDetector.GetCurrentBarTime();

        //--- ログ：新バー評価開始
        g_logger.LogBarEvalStart(barTime);

        //--- インジケータ値キャッシュクリア
        g_indicatorCache.ClearValueCache();

        //--- ポジション制限チェック
        if (g_positionManager.IsPositionLimitExceeded()) {
            g_logger.LogInfo("LIMIT_EXCEEDED", "Position limit exceeded, entry skipped");
            //--- 管理のみ実施
            g_positionManager.ManagePositions();
            return;
        }

        //--- スプレッドチェック（グローバルガード）
        double spreadPips = CalculateSpreadPips(Symbol());

        if (spreadPips > g_config.globalGuards.maxSpreadPips) {
            g_logger.LogInfo("SPREAD_EXCEEDED",
                "Spread=" + DoubleToString(spreadPips, 1) +
                " pips > max=" + DoubleToString(g_config.globalGuards.maxSpreadPips, 1));
            //--- 管理のみ実施
            g_positionManager.ManagePositions();
            return;
        }

        //--- 戦略評価（エントリー判定）
        g_strategyEngine.EvaluateStrategies(barTime);

        //--- ポジション管理（新バー時のみ - 設計決定A1）
        g_positionManager.ManagePositions();
    }

    //--- 状態永続化（毎Tickでは重いので、新バー時のみ）
    if (isNewBar) {
        g_stateStore.Persist();
    }
}

//+------------------------------------------------------------------+
//| トレード関数                                                        |
//+------------------------------------------------------------------+
void OnTrade() {
    // 取引イベント発生時の処理（必要に応じて実装）
}

//+------------------------------------------------------------------+
//| タイマーイベント                                                     |
//+------------------------------------------------------------------+
void OnTimer() {
    // タイマーイベント処理（必要に応じて実装）
}
//+------------------------------------------------------------------+
