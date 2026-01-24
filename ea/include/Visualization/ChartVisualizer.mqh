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
#include "../Common/Structures.mqh"
#include "../Indicators/IndicatorCache.mqh"
#include "../Support/JsonFormatter.mqh"

#define DIRECTION_MISMATCH_PREFIX "direction mismatch:"

struct PanelLine {
    string text;
    color lineColor;
};

//+------------------------------------------------------------------+
//| ChartVisualizerクラス                                              |
//| 評価条件とシグナルをチャート上にリアルタイム表示                      |
//+------------------------------------------------------------------+
class CChartVisualizer {
private:
    enum {
        MAX_PANEL_LINES = 60,
        PANEL_FONT_WIDTH_NUMERATOR = 8,   // MS Gothic width approximation
        PANEL_FONT_WIDTH_DENOMINATOR = 9
    };
    VisualConfig        m_config;         // 可視化設定
    CObjectNameManager  m_nameManager;    // オブジェクト名管理
    CIndicatorCache*    m_cache;          // インジケータキャッシュ参照
    long                m_chartId;        // チャートID
    bool                m_initialized;    // 初期化済みフラグ
    EvalVisualInfo      m_lastEvalInfo;   // 最後の評価情報
    int                 m_lastPanelLineCount;  // 最後に描画した行数（削除用）

    //+------------------------------------------------------------------+
    //| 表示用ラベル変換                                                  |
    //+------------------------------------------------------------------+
    string DirectionToJapanese(TradeDirection direction) {
        switch (direction) {
            case DIRECTION_LONG:    return "買い";
            case DIRECTION_SHORT:   return "売り";
            case DIRECTION_NEUTRAL: return "なし";
            default:                return "不明";
        }
    }

    string BlockStatusToJapanese(BlockStatus status) {
        switch (status) {
            case BLOCK_STATUS_PASS:    return "通過";
            case BLOCK_STATUS_FAIL:    return "失敗";
            case BLOCK_STATUS_NEUTRAL: return "未評価";
            default:                   return "不明";
        }
    }

    string TranslateStrategyReason(const string &reason) {
        if (reason == "") return "";
        if (reason == "disabled") return "無効";
        if (reason == "not matched") return "未成立";
        if (reason == "adopted") return "採用";
        if (StringFind(reason, DIRECTION_MISMATCH_PREFIX) == 0) {
            string dirStr = StringSubstr(reason, StringLen(DIRECTION_MISMATCH_PREFIX));
            StringTrimLeft(dirStr);
            StringTrimRight(dirStr);
            string dirLabel = "不明";
            if (dirStr == DirectionToString(DIRECTION_LONG)) {
                dirLabel = "買い";
            } else if (dirStr == DirectionToString(DIRECTION_SHORT)) {
                dirLabel = "売り";
            }
            return "方向不一致: " + dirLabel;
        }
        return reason;
    }

    string TranslateBlockReason(const string &reason) {
        if (reason == "") return "";
        if (StringFind(reason, "未評価") == 0) return reason;
        return reason;
    }

    string BlockStatusTag(const BlockVisualInfo &block) {
        if (block.status == BLOCK_STATUS_PASS) return "[OK]";
        if (block.status == BLOCK_STATUS_FAIL) return "[NG]";
        if (block.status == BLOCK_STATUS_NEUTRAL) {
            if (StringFind(block.reason, "未評価") == 0) return "[SKIP]";
            return "[--]";
        }
        return "[--]";
    }

    int MeasureLineWidth(const string &text) {
        int length = StringLen(text);
        int width = 0;
        for (int i = 0; i < length; i++) {
            int code = StringGetCharacter(text, i);
            if (code > 255) {
                width += 2;
            } else {
                width += 1;
            }
        }
        return width;
    }

    void AppendPanelLine(PanelLine &lines[], int &lineCount, const string &text, color lineColor) {
        ArrayResize(lines, lineCount + 1);
        lines[lineCount].text = text;
        lines[lineCount].lineColor = lineColor;
        lineCount++;
    }

    string BuildPanelTextFromLines(const PanelLine &lines[], int lineCount) {
        string text = "";
        for (int i = 0; i < lineCount; i++) {
            text += lines[i].text;
            if (i < lineCount - 1) {
                text += "\n";
            }
        }
        return text;
    }

    int BuildPanelLinesFromText(const string &text, PanelLine &lines[]) {
        string rawLines[];
        int lineCount = StringSplit(text, '\n', rawLines);
        if (lineCount <= 0) {
            ArrayResize(lines, 1);
            lines[0].text = text;
            lines[0].lineColor = m_config.panelTextColor;
            return 1;
        }
        ArrayResize(lines, lineCount);
        for (int i = 0; i < lineCount; i++) {
            lines[i].text = rawLines[i];
            lines[i].lineColor = m_config.panelTextColor;
        }
        return lineCount;
    }

    void AppendStatusPanelLines(const EvalVisualInfo &info, PanelLine &lines[], int &lineCount) {
        AppendPanelLine(lines, lineCount, "【Strategy Bricks】", m_config.panelTextColor);
        AppendPanelLine(lines, lineCount, "  シンボル: " + Symbol() + " / M1", m_config.panelTextColor);
        string barTimeLine = "  バー時刻: ";
        if (info.barTime > 0) {
            barTimeLine += TimeToString(info.barTime, TIME_DATE | TIME_MINUTES);
        } else {
            barTimeLine += "-";
        }
        AppendPanelLine(lines, lineCount, barTimeLine, m_config.panelTextColor);

        AppendPanelLine(lines, lineCount, "---", m_config.panelTextColor);
        AppendPanelLine(lines, lineCount, "【ガード】", m_config.panelTextColor);
        string spreadStatus = info.spreadOk ? "OK" : "NG";
        AppendPanelLine(
            lines,
            lineCount,
            "  スプレッド: " + DoubleToString(info.spreadPips, 1) + " pips [" + spreadStatus + "]",
            info.spreadOk ? m_config.passColor : m_config.failColor
        );
        string posLimitStatus = info.positionLimitOk ? "OK" : "NG";
        AppendPanelLine(
            lines,
            lineCount,
            "  ポジション制限: [" + posLimitStatus + "]",
            info.positionLimitOk ? m_config.passColor : m_config.failColor
        );
        AppendPanelLine(lines, lineCount, "  保有数: " + IntegerToString(PositionsTotal()), m_config.panelTextColor);

        AppendPanelLine(lines, lineCount, "---", m_config.panelTextColor);
        AppendPanelLine(lines, lineCount, "【シグナル】", m_config.panelTextColor);
        if (info.signalGenerated) {
            string dir = DirectionToJapanese(info.signalDirection);
            AppendPanelLine(lines, lineCount, "  シグナル: " + dir, m_config.panelTextColor);
            AppendPanelLine(lines, lineCount, "  採用戦略: " + info.adoptedStrategyId, m_config.panelTextColor);
        } else {
            AppendPanelLine(lines, lineCount, "  シグナル: なし", m_config.panelTextColor);
        }

        AppendPanelLine(lines, lineCount, "---", m_config.panelTextColor);
        AppendPanelLine(lines, lineCount, "【戦略評価】", m_config.panelTextColor);
        int matchedCount = 0;
        for (int i = 0; i < info.strategyCount; i++) {
            if (info.strategies[i].matched) {
                matchedCount++;
            }
        }
        AppendPanelLine(
            lines,
            lineCount,
            "  評価数: " + IntegerToString(info.strategyCount) +
            " (成立 " + IntegerToString(matchedCount) +
            " / 不成立 " + IntegerToString(info.strategyCount - matchedCount) + ")",
            m_config.panelTextColor
        );

        int displayCount = MathMin(info.strategyCount, MAX_VISUAL_STRATEGIES);
        for (int i = 0; i < displayCount; i++) {
            StrategyVisualInfo strat = info.strategies[i];
            string status = strat.matched ? "成立" : "不成立";
            string direction = strat.matched ? " (" + DirectionToJapanese(strat.direction) + ")" : "";
            string label = strat.strategyId;
            if (strat.strategyName != "") {
                label += " (" + strat.strategyName + ")";
            }
            string reasonSuffix = "";
            if (strat.reason != "") {
                string reasonLabel = TranslateStrategyReason(strat.reason);
                if (reasonLabel != "" && (strat.matched || reasonLabel != "未成立")) {
                    reasonSuffix = " / " + reasonLabel;
                }
            }
            AppendPanelLine(
                lines,
                lineCount,
                "  - " + label + ": " + status + direction + reasonSuffix,
                strat.matched ? m_config.passColor : m_config.failColor
            );
        }

        if (info.strategyCount > MAX_VISUAL_STRATEGIES) {
            AppendPanelLine(
                lines,
                lineCount,
                "  ... 他 " + IntegerToString(info.strategyCount - MAX_VISUAL_STRATEGIES) + " 件",
                m_config.panelTextColor
            );
        }
    }

    void AppendBlockDetailLines(const EvalVisualInfo &info, PanelLine &lines[], int &lineCount) {
        AppendPanelLine(lines, lineCount, "【条件詳細】", m_config.panelTextColor);

        int stratDisplayCount = MathMin(info.strategyCount, MAX_VISUAL_STRATEGIES);
        for (int s = 0; s < stratDisplayCount; s++) {
            StrategyVisualInfo strat = info.strategies[s];
            string stratLabel = strat.strategyId;
            if (strat.strategyName != "") {
                stratLabel += " (" + strat.strategyName + ")";
            }
            string stratStatus = strat.matched ? "成立" : "不成立";
            string stratDirection = strat.matched ? " (" + DirectionToJapanese(strat.direction) + ")" : "";
            string stratReason = "";
            if (strat.reason != "") {
                string reasonLabel = TranslateStrategyReason(strat.reason);
                if (reasonLabel != "" && (strat.matched || reasonLabel != "未成立")) {
                    stratReason = " / " + reasonLabel;
                }
            }
            AppendPanelLine(
                lines,
                lineCount,
                "  [" + stratLabel + "] " + stratStatus + stratDirection + stratReason,
                strat.matched ? m_config.passColor : m_config.failColor
            );

            int blockDisplayCount = MathMin(strat.blockResultCount, MAX_VISUAL_BLOCKS_PER_STRATEGY);
            int passCount = 0;
            int failCount = 0;
            int skipCount = 0;
            for (int b = 0; b < blockDisplayCount; b++) {
                BlockVisualInfo block = strat.blockResults[b];
                if (block.status == BLOCK_STATUS_PASS) {
                    passCount++;
                } else if (block.status == BLOCK_STATUS_FAIL) {
                    failCount++;
                } else {
                    skipCount++;
                }
            }

            if (blockDisplayCount > 0) {
                string countLine = "    条件: 通過 " + IntegerToString(passCount) +
                                   " / 失敗 " + IntegerToString(failCount) +
                                   " / 未評価 " + IntegerToString(skipCount);
                if (strat.blockResultCount > blockDisplayCount) {
                    countLine += " (表示 " + IntegerToString(blockDisplayCount) +
                                 "/" + IntegerToString(strat.blockResultCount) + ")";
                }
                AppendPanelLine(lines, lineCount, countLine, m_config.panelTextColor);

                for (int b = 0; b < blockDisplayCount; b++) {
                    BlockVisualInfo block = strat.blockResults[b];
                    string tag = BlockStatusTag(block);
                    string line = "    " + tag + " " + block.typeId;
                    if (block.blockId != "") {
                        line += " (" + block.blockId + ")";
                    }
                    string reason = TranslateBlockReason(block.reason);
                    if (reason != "") {
                        line += " - " + reason;
                    }
                    color lineColor = m_config.panelTextColor;
                    if (block.status == BLOCK_STATUS_PASS) {
                        lineColor = m_config.passColor;
                    } else if (block.status == BLOCK_STATUS_FAIL) {
                        lineColor = m_config.failColor;
                    }
                    AppendPanelLine(lines, lineCount, line, lineColor);
                }
            } else {
                AppendPanelLine(lines, lineCount, "    条件: なし", m_config.panelTextColor);
            }
            AppendPanelLine(lines, lineCount, "", m_config.panelTextColor);
        }
    }

    //+------------------------------------------------------------------+
    //| パネル幅を計算（行配列から計算）                                    |
    //+------------------------------------------------------------------+
    int CalculatePanelWidthFromLines(const string &lines[], int lineCount) {
        // 固定幅が指定されていればそれを使用
        if (m_config.panelWidth > 0) {
            return m_config.panelWidth;
        }

        int maxLength = 0;
        int actualCount = MathMin(lineCount, ArraySize(lines));
        for (int i = 0; i < actualCount; i++) {
            int len = MeasureLineWidth(lines[i]);
            if (len > maxLength) {
                maxLength = len;
            }
        }

        // フォントサイズに基づいて幅を計算（等幅フォント想定）
        int charWidth = (m_config.panelFontSize * PANEL_FONT_WIDTH_NUMERATOR) / PANEL_FONT_WIDTH_DENOMINATOR;
        if (charWidth < 1) {
            charWidth = 1;
        }
        int width = maxLength * charWidth + m_config.panelPaddingX * 2 + charWidth;

        return width;
    }

    int CalculatePanelWidthFromPanelLines(const PanelLine &lines[], int lineCount) {
        // 固定幅が指定されていればそれを使用
        if (m_config.panelWidth > 0) {
            return m_config.panelWidth;
        }

        int maxLength = 0;
        int actualCount = MathMin(lineCount, ArraySize(lines));
        for (int i = 0; i < actualCount; i++) {
            int len = MeasureLineWidth(lines[i].text);
            if (len > maxLength) {
                maxLength = len;
            }
        }

        // フォントサイズに基づいて幅を計算（等幅フォント想定）
        int charWidth = (m_config.panelFontSize * PANEL_FONT_WIDTH_NUMERATOR) / PANEL_FONT_WIDTH_DENOMINATOR;
        if (charWidth < 1) {
            charWidth = 1;
        }
        int width = maxLength * charWidth + m_config.panelPaddingX * 2 + charWidth;

        return width;
    }

    //+------------------------------------------------------------------+
    //| パネル幅を計算                                                     |
    //+------------------------------------------------------------------+
    int CalculatePanelWidth(const string &text) {
        string lines[];
        int lineCount = StringSplit(text, '\n', lines);
        return CalculatePanelWidthFromLines(lines, lineCount);
    }

    //+------------------------------------------------------------------+
    //| パネル高さを計算                                                   |
    //+------------------------------------------------------------------+
    int CalculatePanelHeight(int lineCount) {
        return lineCount * m_config.panelLineHeight + m_config.panelPaddingY * 2;
    }

    //+------------------------------------------------------------------+
    //| パネル背景を描画                                                   |
    //+------------------------------------------------------------------+
    bool DrawPanelBackground(int width, int height) {
        string name = m_nameManager.GetPanelBackgroundName();

        // 既存オブジェクト削除
        ObjectDelete(m_chartId, name);

        // 背景矩形作成
        if (!ObjectCreate(m_chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
            Print("ChartVisualizer: Failed to create panel background: ", GetLastError());
            return false;
        }

        // 位置とサイズ設定
        ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_config.panelX);
        ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_config.panelY);
        ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);

        // 色と透明度設定
        int alpha = m_config.panelBgAlpha;
        if (alpha < 0) {
            alpha = 0;
        } else if (alpha > 255) {
            alpha = 255;
        }
        color bgColor = ColorToARGB(m_config.panelBgColor, (uchar)alpha);
        ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_COLOR, m_config.panelBorderColor);
        ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);

        // 表示設定
        ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, m_config.panelCorner);
        ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);  // 前面に表示
        ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);

        return true;
    }

    //+------------------------------------------------------------------+
    //| パネルテキスト行を描画                                             |
    //+------------------------------------------------------------------+
    bool DrawPanelTextLine(int row, const string &lineText, color textColor) {
        string name = m_nameManager.GetPanelTextLineName(row);

        if (ObjectFind(m_chartId, name) < 0) {
            // ラベル作成
            if (!ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0)) {
                Print("ChartVisualizer: Failed to create panel text line ", row, ": ", GetLastError());
                return false;
            }
        }

        // 位置設定
        int xPos = m_config.panelX + m_config.panelPaddingX;
        int yPos = m_config.panelY + m_config.panelPaddingY + row * m_config.panelLineHeight;
        ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, xPos);
        ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, yPos);

        // テキスト設定
        ObjectSetString(m_chartId, name, OBJPROP_TEXT, lineText);
        ObjectSetString(m_chartId, name, OBJPROP_FONT, m_config.panelFontName);
        ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, m_config.panelFontSize);
        ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, textColor);

        // 表示設定
        ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, m_config.panelCorner);
        ObjectSetInteger(m_chartId, name, OBJPROP_ANCHOR, m_config.panelAnchor);
        ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);

        return true;
    }

    //+------------------------------------------------------------------+
    //| パネル全体を描画                                                   |
    //+------------------------------------------------------------------+
    bool DrawPanelObject(PanelLine &lines[], int lineCount) {
        // 行数制限
        if (lineCount > MAX_PANEL_LINES) {
            int omitted = lineCount - (MAX_PANEL_LINES - 1);
            ArrayResize(lines, MAX_PANEL_LINES);
            lines[MAX_PANEL_LINES - 1].text = "... 表示上限 " + IntegerToString(MAX_PANEL_LINES) +
                                              " 行 / 省略 " + IntegerToString(omitted) + " 行";
            lines[MAX_PANEL_LINES - 1].lineColor = m_config.panelTextColor;
            lineCount = MAX_PANEL_LINES;
        }

        // パネル幅・高さを計算
        int width = CalculatePanelWidthFromPanelLines(lines, lineCount);
        int height = CalculatePanelHeight(lineCount);

        // 背景描画
        if (!DrawPanelBackground(width, height)) {
            return false;
        }

        // テキスト行描画
        for (int i = 0; i < lineCount; i++) {
            DrawPanelTextLine(i, lines[i].text, lines[i].lineColor);
        }

        // 余剰分の古い行を削除
        for (int i = lineCount; i < m_lastPanelLineCount; i++) {
            string name = m_nameManager.GetPanelTextLineName(i);
            ObjectDelete(m_chartId, name);
        }

        // 描画した行数を記録
        m_lastPanelLineCount = lineCount;

        return true;
    }

public:
    //--- コンストラクタ
    CChartVisualizer() {
        m_config.Reset();
        m_cache = NULL;
        m_chartId = 0;
        m_initialized = false;
        m_lastEvalInfo.Reset();
        m_lastPanelLineCount = 0;
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
        m_lastPanelLineCount = 0;
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
        ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, false);  // 矢印は表示する

        // 古い矢印を削除
        m_nameManager.TrimOldArrows(m_chartId, m_config.maxArrowHistory);

        return true;
    }

    //+------------------------------------------------------------------+
    //| 状態パネルを更新（Object/Comment()切り替え）                        |
    //+------------------------------------------------------------------+
    void UpdateStatusPanel(const EvalVisualInfo &info) {
        if (!m_initialized || !m_config.enabled || !m_config.showStatusPanel) {
            return;
        }

        PanelLine lines[];
        int lineCount = 0;
        AppendStatusPanelLines(info, lines, lineCount);

        // ブロック詳細も追加
        if (m_config.showBlockDetails) {
            AppendPanelLine(lines, lineCount, "---", m_config.panelTextColor);
            AppendBlockDetailLines(info, lines, lineCount);
        }

        // Object表示 or Comment表示
        if (m_config.usePanelObject) {
            // Object表示
            DrawPanelObject(lines, lineCount);
            Comment("");  // Comment()をクリア
        } else {
            // Comment表示
            string panelText = BuildPanelTextFromLines(lines, lineCount);
            Comment(panelText);
            // パネルObjectを削除
            m_nameManager.DeleteAllPanelObjects(m_chartId);
            m_lastPanelLineCount = 0;
        }
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
            // 価格取得（shift=1の確定足）- EA_TIMEFRAMEを使用して一貫性を保つ
            double price = iClose(Symbol(), EA_TIMEFRAME, 1);
            if (info.signalDirection == DIRECTION_SHORT) {
                price = iHigh(Symbol(), EA_TIMEFRAME, 1);  // SELLは高値の上
            } else {
                price = iLow(Symbol(), EA_TIMEFRAME, 1);   // BUYは安値の下
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
        ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, false);  // インジケータラインは表示する

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
                ObjectSetInteger(m_chartId, nameUpper, OBJPROP_HIDDEN, false);  // BBバンドは表示する
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
                ObjectSetInteger(m_chartId, nameMiddle, OBJPROP_HIDDEN, false);  // BBバンドは表示する
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
                ObjectSetInteger(m_chartId, nameLower, OBJPROP_HIDDEN, false);  // BBバンドは表示する
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

    //+------------------------------------------------------------------+
    //| 初期化完了メッセージを生成                                        |
    //+------------------------------------------------------------------+
    string BuildInitializationReport(const Config &config, bool showBlockDetails) {
        string initMsg = "";
        initMsg += "【Strategy Bricks EA】\n";
        initMsg += "バージョン: " + EA_VERSION + "\n";
        initMsg += "シンボル: " + Symbol() + " / M1\n";
        initMsg += "設定: " + config.meta.name + " (v" + config.meta.formatVersion + ")\n";
        if (config.meta.generatedBy != "" || config.meta.generatedAt != "") {
            string generated = config.meta.generatedBy;
            if (generated != "" && config.meta.generatedAt != "") {
                generated += " @ ";
            }
            generated += config.meta.generatedAt;
            initMsg += "生成: " + generated + "\n";
        }
        initMsg += "戦略数: " + IntegerToString(config.strategyCount) + "\n";
        initMsg += "ブロック数: " + IntegerToString(config.blockCount) + "\n";

        initMsg += "---\n";
        initMsg += "【ガード設定】\n";
        initMsg += "時間足: " + config.globalGuards.timeframe + "\n";
        initMsg += "確定足のみ: " + (config.globalGuards.useClosedBarOnly ? "はい" : "いいえ") + "\n";
        initMsg += "同一足再エントリー: " + (config.globalGuards.noReentrySameBar ? "禁止" : "許可") + "\n";
        initMsg += "最大ポジション: 合計 " + IntegerToString(config.globalGuards.maxPositionsTotal) +
                   ", シンボル " + IntegerToString(config.globalGuards.maxPositionsPerSymbol) + "\n";
        initMsg += "最大スプレッド: " + DoubleToString(config.globalGuards.maxSpreadPips, 1) + " pips\n";
        if (config.globalGuards.session.enabled) {
            initMsg += "セッション: 有効\n";
            if (config.globalGuards.session.windowCount > 0) {
                string windows = "";
                for (int i = 0; i < config.globalGuards.session.windowCount; i++) {
                    if (i > 0) {
                        windows += ", ";
                    }
                    windows += config.globalGuards.session.windows[i].start +
                               "-" + config.globalGuards.session.windows[i].end;
                }
                initMsg += "  時間帯: " + windows + "\n";
            }
        } else {
            initMsg += "セッション: 無効\n";
        }

        if (showBlockDetails && config.blockCount > 0) {
            initMsg += "---\n";
            initMsg += "【ブロック詳細】\n";
            CJsonFormatter formatter;
            for (int i = 0; i < config.blockCount; i++) {
                BlockDefinition block = config.blocks[i];
                initMsg += "- [" + IntegerToString(i + 1) + "] " + block.typeId +
                           " (" + block.id + ")\n";
                if (block.paramsJson != "") {
                    string params = formatter.FormatParamsJsonForDisplay(block.paramsJson);
                    StringReplace(params, "\n", "\n      ");
                    initMsg += "    パラメータ:\n";
                    initMsg += "      " + params + "\n";
                }
            }
        }

        initMsg += "---\n";
        initMsg += "状態: 初期化完了\n";
        initMsg += "ティック待ち...\n";

        return initMsg;
    }

    //+------------------------------------------------------------------+
    //| 任意のテキストを表示（Object/Comment切り替え対応）                   |
    //+------------------------------------------------------------------+
    void DisplayText(const string &text) {
        if (!m_initialized || !m_config.enabled) {
            return;
        }

        // Object表示 or Comment表示
        if (m_config.usePanelObject) {
            // Object表示
            PanelLine lines[];
            int lineCount = BuildPanelLinesFromText(text, lines);
            DrawPanelObject(lines, lineCount);
            Comment("");  // Comment()をクリア
        } else {
            // Comment表示
            Comment(text);
        }

        // チャート更新
        ChartRedraw(m_chartId);
    }
};

#endif // CHARTVISUALIZER_MQH
