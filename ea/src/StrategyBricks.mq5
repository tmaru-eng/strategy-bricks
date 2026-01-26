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
#include <StrategyBricks/Common/Constants.mqh>
#include <StrategyBricks/Common/Enums.mqh>
#include <StrategyBricks/Common/Structures.mqh>

#include <StrategyBricks/Support/Logger.mqh>
#include <StrategyBricks/Support/StateStore.mqh>
#include <StrategyBricks/Support/JsonParser.mqh>
#include <StrategyBricks/Support/JsonFormatter.mqh>

#include <StrategyBricks/Config/ConfigLoader.mqh>
#include <StrategyBricks/Config/ConfigValidator.mqh>

#include <StrategyBricks/Indicators/IndicatorCache.mqh>

#include <StrategyBricks/Blocks/IBlock.mqh>
#include <StrategyBricks/Core/BlockRegistry.mqh>

#include <StrategyBricks/Execution/OrderExecutor.mqh>
#include <StrategyBricks/Execution/PositionManager.mqh>

#include <StrategyBricks/Core/NewBarDetector.mqh>
#include <StrategyBricks/Core/CompositeEvaluator.mqh>
#include <StrategyBricks/Core/StrategyEngine.mqh>
#include <StrategyBricks/Visualization/ChartVisualizer.mqh>

//+------------------------------------------------------------------+
//| 入力パラメータ                                                      |
//+------------------------------------------------------------------+
input string InpConfigPath = "strategy/active.json";   // 設定ファイルパス
input bool   InpEnableLogging = true;                  // ログ出力有効
input bool   InpEnableVisualization = true;            // チャート可視化有効
input bool   InpShowSignalArrows = true;               // シグナル矢印表示
input bool   InpShowStatusPanel = true;                // 状態パネル表示
input bool   InpShowBlockDetails = true;               // ブロック詳細表示
input int    InpMaxArrowHistory = 100;                 // シグナル矢印最大保持数

// パネルObject表示設定
input bool   InpUsePanelObject = true;                 // Objectでパネル表示
input color  InpPanelBgColor = C'18,18,18';            // パネル背景色
input color  InpPanelBorderColor = C'90,90,90';        // パネル枠線色
input int    InpPanelBgAlpha = 255;                    // 背景透明度（0-255）
input color  InpPanelTextColor = C'235,235,235';       // パネルテキスト色
input string InpPanelFontName = "MS Gothic";           // フォント名
input int    InpPanelFontSize = 10;                    // フォントサイズ
input int    InpPanelX = 10;                           // パネルX座標
input int    InpPanelY = 30;                           // パネルY座標
input int    InpPanelWidth = 0;                        // パネル幅（0=自動）

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
CChartVisualizer    g_visualizer;           // チャート可視化

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

    //--- チャート可視化初期化
    if (InpEnableVisualization) {
        VisualConfig visConfig;
        visConfig.Reset();
        visConfig.enabled = true;
        visConfig.showSignalArrows = InpShowSignalArrows;
        visConfig.showStatusPanel = InpShowStatusPanel;
        visConfig.showBlockDetails = InpShowBlockDetails;
        visConfig.maxArrowHistory = InpMaxArrowHistory;

        // パネルObject表示設定
        visConfig.usePanelObject = InpUsePanelObject;
        visConfig.panelBgColor = InpPanelBgColor;
        visConfig.panelBorderColor = InpPanelBorderColor;
        visConfig.panelBgAlpha = InpPanelBgAlpha;
        visConfig.panelTextColor = InpPanelTextColor;
        visConfig.panelFontName = InpPanelFontName;
        visConfig.panelFontSize = InpPanelFontSize;
        visConfig.panelX = InpPanelX;
        visConfig.panelY = InpPanelY;
        visConfig.panelWidth = InpPanelWidth;

        g_visualizer.Initialize(visConfig, &g_indicatorCache);
        g_logger.LogInfo("VISUALIZER_INIT", "Chart visualizer initialized");
    }

    g_initialized = true;
    g_logger.LogInfo("INIT_COMPLETE", "Strategy Bricks EA initialized successfully");
    Print("Strategy Bricks EA initialized successfully");
    Print("Config: ", g_config.meta.name, " (v", g_config.meta.formatVersion, ")");
    Print("Strategies: ", g_config.strategyCount, ", Blocks: ", g_config.blockCount);

    //--- 初期化完了メッセージを表示（閉場中でも確認可能）
    if (InpEnableVisualization && InpShowStatusPanel) {
        string initMsg = g_visualizer.BuildInitializationReport(g_config, InpShowBlockDetails);
        g_visualizer.DisplayText(initMsg);
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    g_logger.LogInfo("DEINIT", "Deinit reason: " + IntegerToString(reason));

    //--- チャート可視化クリーンアップ
    g_visualizer.Cleanup();

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
            //--- 可視化用：ポジション制限超過を記録
            g_strategyEngine.SetPositionLimitExceeded();
            if (InpEnableVisualization) {
                g_visualizer.Update(g_strategyEngine.GetLastEvalInfo());
            }
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
            //--- 可視化用：スプレッド超過を記録
            g_strategyEngine.SetSpreadExceeded(spreadPips);
            if (InpEnableVisualization) {
                g_visualizer.Update(g_strategyEngine.GetLastEvalInfo());
            }
            //--- 管理のみ実施
            g_positionManager.ManagePositions();
            return;
        }

        //--- 戦略評価（エントリー判定）
        g_strategyEngine.EvaluateStrategies(barTime);

        //--- チャート可視化更新
        if (InpEnableVisualization) {
            g_visualizer.Update(g_strategyEngine.GetLastEvalInfo());
        }

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
