//+------------------------------------------------------------------+
//|                                             ChartVisualizer.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                                チャート可視化メインクラス           |
//+------------------------------------------------------------------+
#ifndef CHARTVISUALIZER_MQH
#define CHARTVISUALIZER_MQH

#include "VisualConfig.mqh"
#include "ObjectNameManager.mqh"
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Indicators/IndicatorCache.mqh"

//+------------------------------------------------------------------+
//| ChartVisualizerクラス                                              |
//| 評価条件とシグナルをチャート上にリアルタイム表示                      |
//+------------------------------------------------------------------+
class CChartVisualizer {
private:
    VisualConfig        m_config;         // 可視化設定
    CObjectNameManager  m_nameManager;    // オブジェクト名管理
    CIndicatorCache*    m_cache;          // インジケータキャッシュ参照
    long                m_chartId;        // チャートID
    bool                m_initialized;    // 初期化済みフラグ
    EvalVisualInfo      m_lastEvalInfo;   // 最後の評価情報

    //+------------------------------------------------------------------+
    //| 状態パネルのテキストを生成                                          |
    //+------------------------------------------------------------------+
    string BuildStatusPanelText(const EvalVisualInfo &info) {
        string text = "";

        // ヘッダー
        text += "=== Strategy Bricks ===\n";

        // バー時刻
        text += "Bar: " + TimeToString(info.barTime, TIME_DATE | TIME_MINUTES) + "\n";

        // スプレッド
        string spreadStatus = info.spreadOk ? "OK" : "NG";
        text += "Spread: " + DoubleToString(info.spreadPips, 1) + " pips [" + spreadStatus + "]\n";

        // ポジション制限
        string posLimitStatus = info.positionLimitOk ? "OK" : "NG";
        text += "Position Limit: [" + posLimitStatus + "]\n";

        // セパレータ
        text += "---\n";

        // シグナル状態
        if (info.signalGenerated) {
            string dir = DirectionToString(info.signalDirection);
            text += "Signal: " + dir + " (" + info.adoptedStrategyId + ")\n";
        } else {
            text += "Signal: NONE\n";
        }

        // Strategy評価結果
        text += "---\n";
        text += "Strategies Evaluated: " + IntegerToString(info.strategyCount) + "\n";

        for (int i = 0; i < info.strategyCount && i < 8; i++) {
            string matched = info.strategies[i].matched ? "MATCH" : "---";
            text += "  " + info.strategies[i].strategyId + ": " + matched + "\n";
        }

        return text;
    }

    //+------------------------------------------------------------------+
    //| ブロック詳細パネルテキストを生成                                    |
    //+------------------------------------------------------------------+
    string BuildBlockDetailText(const EvalVisualInfo &info) {
        string text = "";

        // 各Strategyのブロック評価結果
        for (int s = 0; s < info.strategyCount && s < 4; s++) {
            text += "[" + info.strategies[s].strategyId + "]\n";

            for (int b = 0; b < info.strategies[s].blockResultCount && b < 8; b++) {
                BlockVisualInfo block = info.strategies[s].blockResults[b];
                string status = BlockStatusToString(block.status);
                text += "  " + block.typeId + ": " + status + "\n";
            }
            text += "\n";
        }

        return text;
    }

public:
    //--- コンストラクタ
    CChartVisualizer() {
        m_config.Reset();
        m_cache = NULL;
        m_chartId = 0;
        m_initialized = false;
        m_lastEvalInfo.Reset();
    }

    //--- デストラクタ
    ~CChartVisualizer() {
        Cleanup();
    }

    //+------------------------------------------------------------------+
    //| 初期化                                                            |
    //+------------------------------------------------------------------+
    bool Initialize(const VisualConfig &config, CIndicatorCache* cache = NULL) {
        m_config = config;
        m_cache = cache;
        m_chartId = ChartID();
        m_lastEvalInfo.Reset();

        if (!m_config.enabled) {
            m_initialized = false;
            return true;  // 無効だが正常終了
        }

        m_initialized = true;
        Print("ChartVisualizer: Initialized");
        return true;
    }

    //+------------------------------------------------------------------+
    //| クリーンアップ                                                     |
    //+------------------------------------------------------------------+
    void Cleanup() {
        if (m_chartId > 0) {
            int deleted = m_nameManager.DeleteAllVisualizationObjects(m_chartId);
            Print("ChartVisualizer: Cleaned up ", deleted, " objects");
            ChartRedraw(m_chartId);
        }
        Comment("");  // Comment表示クリア
        m_initialized = false;
    }

    //+------------------------------------------------------------------+
    //| 有効/無効切り替え                                                  |
    //+------------------------------------------------------------------+
    void SetEnabled(bool enabled) {
        m_config.enabled = enabled;
        if (!enabled) {
            Cleanup();
        }
    }

    //+------------------------------------------------------------------+
    //| 設定取得                                                          |
    //+------------------------------------------------------------------+
    VisualConfig GetConfig() const {
        return m_config;
    }

    //+------------------------------------------------------------------+
    //| シグナル矢印を描画                                                 |
    //+------------------------------------------------------------------+
    bool DrawSignalArrow(datetime time, double price, TradeDirection direction) {
        if (!m_initialized || !m_config.enabled || !m_config.showSignalArrows) {
            return false;
        }

        bool isBuy = (direction == DIRECTION_LONG);
        string name = m_nameManager.GetArrowName(time, isBuy);

        // オブジェクトタイプ決定
        ENUM_OBJECT arrowType = isBuy ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;

        // 既存オブジェクト削除
        ObjectDelete(m_chartId, name);

        // 矢印作成
        if (!ObjectCreate(m_chartId, name, arrowType, 0, time, price)) {
            Print("ChartVisualizer: Failed to create arrow object: ", GetLastError());
            return false;
        }

        // 色設定
        color arrowColor = isBuy ? m_config.arrowBuyColor : m_config.arrowSellColor;
        ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, arrowColor);
        ObjectSetInteger(m_chartId, name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);

        // 古い矢印を削除
        m_nameManager.TrimOldArrows(m_chartId, m_config.maxArrowHistory);

        return true;
    }

    //+------------------------------------------------------------------+
    //| 状態パネルを更新（Comment()使用）                                   |
    //+------------------------------------------------------------------+
    void UpdateStatusPanel(const EvalVisualInfo &info) {
        if (!m_initialized || !m_config.enabled || !m_config.showStatusPanel) {
            return;
        }

        string panelText = BuildStatusPanelText(info);

        // ブロック詳細も追加
        if (m_config.showBlockDetails) {
            panelText += "---\n";
            panelText += BuildBlockDetailText(info);
        }

        Comment(panelText);
    }

    //+------------------------------------------------------------------+
    //| 評価情報を更新して表示を更新                                        |
    //+------------------------------------------------------------------+
    void Update(const EvalVisualInfo &info) {
        if (!m_initialized || !m_config.enabled) {
            return;
        }

        m_lastEvalInfo = info;

        // 状態パネル更新
        UpdateStatusPanel(info);

        // シグナル矢印描画（シグナル発生時のみ）
        if (info.signalGenerated) {
            // 価格取得（shift=1の確定足）
            double price = iClose(Symbol(), PERIOD_M1, 1);
            if (info.signalDirection == DIRECTION_SHORT) {
                price = iHigh(Symbol(), PERIOD_M1, 1);  // SELLは高値の上
            } else {
                price = iLow(Symbol(), PERIOD_M1, 1);   // BUYは安値の下
            }
            DrawSignalArrow(info.barTime, price, info.signalDirection);
        }

        // チャート更新
        ChartRedraw(m_chartId);
    }

    //+------------------------------------------------------------------+
    //| MAラインを描画                                                     |
    //| 注: 現在の実装では使用しない（IndicatorCacheのAPI互換性のため）         |
    //+------------------------------------------------------------------+
    bool DrawMALine(int period, ENUM_MA_METHOD maType, int count = 100) {
        if (!m_initialized || !m_config.enabled || !m_config.showIndicatorLines) {
            return false;
        }

        if (m_cache == NULL) {
            return false;
        }

        string symbol = Symbol();
        datetime barTime = iTime(symbol, EA_TIMEFRAME, 0);

        // ハンドル取得
        int handle = m_cache.GetMAHandle(symbol, EA_TIMEFRAME, period, 0, maType, PRICE_CLOSE);
        if (handle == INVALID_HANDLE) {
            return false;
        }

        string name = m_nameManager.GetMALineName(period, MAMethodToString(maType));

        // 既存ライン削除
        ObjectDelete(m_chartId, name);

        // トレンドラインとして描画（簡易版：直近2点のみ）
        double ma1 = m_cache.GetMAValue(handle, 1, barTime);
        double ma2 = m_cache.GetMAValue(handle, 2, barTime);

        if (ma1 == 0 || ma2 == 0) {
            return false;
        }

        datetime time1 = iTime(symbol, EA_TIMEFRAME, 1);
        datetime time2 = iTime(symbol, EA_TIMEFRAME, 2);

        if (!ObjectCreate(m_chartId, name, OBJ_TREND, 0, time2, ma2, time1, ma1)) {
            return false;
        }

        ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(m_chartId, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(m_chartId, name, OBJPROP_RAY_RIGHT, true);
        ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);

        return true;
    }

    //+------------------------------------------------------------------+
    //| BBバンドを描画                                                     |
    //| 注: 現在の実装では使用しない（IndicatorCacheのAPI互換性のため）         |
    //+------------------------------------------------------------------+
    bool DrawBBBands(int period, double deviation) {
        if (!m_initialized || !m_config.enabled || !m_config.showIndicatorLines) {
            return false;
        }

        if (m_cache == NULL) {
            return false;
        }

        string symbol = Symbol();
        datetime barTime = iTime(symbol, EA_TIMEFRAME, 0);

        // ハンドル取得
        int handle = m_cache.GetBBHandle(symbol, EA_TIMEFRAME, period, 0, deviation, PRICE_CLOSE);
        if (handle == INVALID_HANDLE) {
            return false;
        }

        // 上中下バンドを取得 (bufferIndex: 0=middle, 1=upper, 2=lower)
        double upper1 = m_cache.GetBBValue(handle, 1, 1, barTime);
        double upper2 = m_cache.GetBBValue(handle, 1, 2, barTime);
        double middle1 = m_cache.GetBBValue(handle, 0, 1, barTime);
        double middle2 = m_cache.GetBBValue(handle, 0, 2, barTime);
        double lower1 = m_cache.GetBBValue(handle, 2, 1, barTime);
        double lower2 = m_cache.GetBBValue(handle, 2, 2, barTime);

        datetime time1 = iTime(symbol, EA_TIMEFRAME, 1);
        datetime time2 = iTime(symbol, EA_TIMEFRAME, 2);

        // 上バンドライン
        string nameUpper = m_nameManager.GetBBLineName(period, deviation, "UPPER");
        ObjectDelete(m_chartId, nameUpper);
        if (upper1 > 0 && upper2 > 0) {
            if (ObjectCreate(m_chartId, nameUpper, OBJ_TREND, 0, time2, upper2, time1, upper1)) {
                ObjectSetInteger(m_chartId, nameUpper, OBJPROP_COLOR, clrMagenta);
                ObjectSetInteger(m_chartId, nameUpper, OBJPROP_WIDTH, 1);
                ObjectSetInteger(m_chartId, nameUpper, OBJPROP_RAY_RIGHT, true);
                ObjectSetInteger(m_chartId, nameUpper, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(m_chartId, nameUpper, OBJPROP_HIDDEN, true);
            }
        }

        // 中央ライン
        string nameMiddle = m_nameManager.GetBBLineName(period, deviation, "MIDDLE");
        ObjectDelete(m_chartId, nameMiddle);
        if (middle1 > 0 && middle2 > 0) {
            if (ObjectCreate(m_chartId, nameMiddle, OBJ_TREND, 0, time2, middle2, time1, middle1)) {
                ObjectSetInteger(m_chartId, nameMiddle, OBJPROP_COLOR, clrCyan);
                ObjectSetInteger(m_chartId, nameMiddle, OBJPROP_WIDTH, 1);
                ObjectSetInteger(m_chartId, nameMiddle, OBJPROP_RAY_RIGHT, true);
                ObjectSetInteger(m_chartId, nameMiddle, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(m_chartId, nameMiddle, OBJPROP_HIDDEN, true);
            }
        }

        // 下バンドライン
        string nameLower = m_nameManager.GetBBLineName(period, deviation, "LOWER");
        ObjectDelete(m_chartId, nameLower);
        if (lower1 > 0 && lower2 > 0) {
            if (ObjectCreate(m_chartId, nameLower, OBJ_TREND, 0, time2, lower2, time1, lower1)) {
                ObjectSetInteger(m_chartId, nameLower, OBJPROP_COLOR, clrMagenta);
                ObjectSetInteger(m_chartId, nameLower, OBJPROP_WIDTH, 1);
                ObjectSetInteger(m_chartId, nameLower, OBJPROP_RAY_RIGHT, true);
                ObjectSetInteger(m_chartId, nameLower, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(m_chartId, nameLower, OBJPROP_HIDDEN, true);
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| 最後の評価情報を取得                                               |
    //+------------------------------------------------------------------+
    EvalVisualInfo GetLastEvalInfo() const {
        return m_lastEvalInfo;
    }

    //+------------------------------------------------------------------+
    //| 初期化済みか確認                                                   |
    //+------------------------------------------------------------------+
    bool IsInitialized() const {
        return m_initialized;
    }
};

#endif // CHARTVISUALIZER_MQH
