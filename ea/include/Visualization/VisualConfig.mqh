//+------------------------------------------------------------------+
//|                                                 VisualConfig.mqh |
//|                                         Strategy Bricks EA MVP   |
//|                                     可視化設定・情報構造体         |
//+------------------------------------------------------------------+
#ifndef VISUALCONFIG_MQH
#define VISUALCONFIG_MQH

#include "../Common/Enums.mqh"

//+------------------------------------------------------------------+
//| 可視化設定構造体                                                   |
//+------------------------------------------------------------------+
struct VisualConfig {
    bool    enabled;              // 可視化有効/無効
    bool    showSignalArrows;     // シグナル矢印表示
    bool    showStatusPanel;      // 状態パネル表示
    bool    showBlockDetails;     // ブロック詳細表示
    bool    showIndicatorLines;   // インジケータライン表示
    int     maxArrowHistory;      // シグナル矢印最大保持数
    color   arrowBuyColor;        // 買い矢印の色
    color   arrowSellColor;       // 売り矢印の色
    color   panelTextColor;       // パネルテキスト色
    color   passColor;            // PASS状態の色
    color   failColor;            // FAIL状態の色
    int     panelFontSize;        // パネルフォントサイズ
    int     panelX;               // パネルX座標
    int     panelY;               // パネルY座標

    // デフォルト値で初期化
    void Reset() {
        enabled = true;
        showSignalArrows = true;
        showStatusPanel = true;
        showBlockDetails = true;
        showIndicatorLines = true;
        maxArrowHistory = 100;
        arrowBuyColor = clrDodgerBlue;
        arrowSellColor = clrOrangeRed;
        panelTextColor = clrWhite;
        passColor = clrLime;
        failColor = clrRed;
        panelFontSize = 9;
        panelX = 10;
        panelY = 30;
    }

    // コンストラクタ
    VisualConfig() {
        Reset();
    }
};

//+------------------------------------------------------------------+
//| ブロック可視化情報構造体                                            |
//+------------------------------------------------------------------+
struct BlockVisualInfo {
    string      blockId;          // ブロックID
    string      typeId;           // タイプID
    BlockStatus status;           // 評価結果
    string      reason;           // 理由文字列

    void Reset() {
        blockId = "";
        typeId = "";
        status = BLOCK_STATUS_NEUTRAL;
        reason = "";
    }
};

//+------------------------------------------------------------------+
//| Strategy可視化情報構造体                                            |
//+------------------------------------------------------------------+
struct StrategyVisualInfo {
    string         strategyId;            // Strategy ID
    string         strategyName;          // Strategy名
    bool           matched;               // 成立したか
    TradeDirection direction;             // 成立した方向
    string         reason;                // 理由（不成立時の原因等）
    BlockVisualInfo blockResults[32];     // ブロック評価結果（最大32個）
    int            blockResultCount;      // ブロック評価結果数

    void Reset() {
        strategyId = "";
        strategyName = "";
        matched = false;
        direction = DIRECTION_NEUTRAL;
        reason = "";
        blockResultCount = 0;
    }

    // ブロック結果を追加
    bool AddBlockResult(const BlockVisualInfo &info) {
        if (blockResultCount >= 32) return false;
        blockResults[blockResultCount] = info;
        blockResultCount++;
        return true;
    }
};

//+------------------------------------------------------------------+
//| 評価情報構造体（新バー毎の評価結果全体）                              |
//+------------------------------------------------------------------+
struct EvalVisualInfo {
    datetime           barTime;           // 評価対象バー時刻
    double             spreadPips;        // スプレッド（pips）
    bool               spreadOk;          // スプレッドチェック結果
    bool               positionLimitOk;   // ポジション制限チェック結果
    StrategyVisualInfo strategies[16];    // Strategy評価結果（最大16個）
    int                strategyCount;     // Strategy評価数
    bool               signalGenerated;   // シグナル発生したか
    TradeDirection     signalDirection;   // シグナル方向
    string             adoptedStrategyId; // 採用されたStrategy ID

    void Reset() {
        barTime = 0;
        spreadPips = 0;
        spreadOk = true;
        positionLimitOk = true;
        strategyCount = 0;
        signalGenerated = false;
        signalDirection = DIRECTION_NEUTRAL;
        adoptedStrategyId = "";
    }

    // Strategy結果を追加
    bool AddStrategyResult(const StrategyVisualInfo &info) {
        if (strategyCount >= 16) return false;
        strategies[strategyCount] = info;
        strategyCount++;
        return true;
    }
};

#endif // VISUALCONFIG_MQH
