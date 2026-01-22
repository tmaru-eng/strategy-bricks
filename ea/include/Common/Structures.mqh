//+------------------------------------------------------------------+
//|                                                  Structures.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|           共通構造体（Context, BlockResult, Config関連構造体）       |
//+------------------------------------------------------------------+
#ifndef STRUCTURES_MQH
#define STRUCTURES_MQH

#include "Enums.mqh"
#include "Constants.mqh"

//+------------------------------------------------------------------+
//| 市場情報構造体                                                     |
//+------------------------------------------------------------------+
struct MarketInfo {
    string symbol;              // シンボル名
    double ask;                 // 現在のASK価格
    double bid;                 // 現在のBID価格
    double spreadPips;          // スプレッド（pips）
    double point;               // 1ポイントの価格
    int    digits;              // 小数点桁数

    // 価格配列（shift=1の確定足、インデックス0がshift=1）
    double close[1];
    double high[1];
    double low[1];
    double open[1];

    // 初期化
    void Reset() {
        symbol = "";
        ask = 0;
        bid = 0;
        spreadPips = 0;
        point = 0;
        digits = 0;
        ArrayInitialize(close, 0);
        ArrayInitialize(high, 0);
        ArrayInitialize(low, 0);
        ArrayInitialize(open, 0);
    }
};

//+------------------------------------------------------------------+
//| 状態情報構造体                                                     |
//+------------------------------------------------------------------+
struct StateInfo {
    datetime barTime;           // 現在評価対象のバー時刻（M1）
    int      positionsTotal;    // 全ポジション数
    int      positionsBySymbol; // シンボル別ポジション数
    int      positionsLong;     // ロングポジション数
    int      positionsShort;    // ショートポジション数
    datetime lastEntryBarTime;  // 最後にエントリーしたバー時刻
    int      nanpinCount;       // 現在のナンピン段数

    // 初期化
    void Reset() {
        barTime = 0;
        positionsTotal = 0;
        positionsBySymbol = 0;
        positionsLong = 0;
        positionsShort = 0;
        lastEntryBarTime = 0;
        nanpinCount = 0;
    }
};

//+------------------------------------------------------------------+
//| ブロック評価結果構造体                                               |
//+------------------------------------------------------------------+
struct BlockResult {
    BlockStatus    status;      // 評価ステータス（必須）
    TradeDirection direction;   // 方向（必要なブロックのみ）
    string         reason;      // 理由（ログ用、必須）
    double         score;       // スコア（将来拡張用）

    // 拡張フィールド（lot/risk系ブロック用）
    double lotValue;            // ロット値（lot系ブロックが設定）
    double slPips;              // SLのpips（risk系ブロックが設定）
    double tpPips;              // TPのpips（risk系ブロックが設定）
    double slPrice;             // SL価格（絶対値指定時）
    double tpPrice;             // TP価格（絶対値指定時）

    // デフォルトコンストラクタ
    BlockResult() {
        status = BLOCK_STATUS_NEUTRAL;
        direction = DIRECTION_NEUTRAL;
        reason = "";
        score = 0.0;
        lotValue = 0.0;
        slPips = 0.0;
        tpPips = 0.0;
        slPrice = 0.0;
        tpPrice = 0.0;
    }

    // 基本コンストラクタ
    void Init(BlockStatus st, TradeDirection dir, string rsn) {
        status = st;
        direction = dir;
        reason = rsn;
        score = 0.0;
        lotValue = 0.0;
        slPips = 0.0;
        tpPips = 0.0;
        slPrice = 0.0;
        tpPrice = 0.0;
    }

    // スコア付きコンストラクタ
    void Init(BlockStatus st, TradeDirection dir, string rsn, double sc) {
        status = st;
        direction = dir;
        reason = rsn;
        score = sc;
        lotValue = 0.0;
        slPips = 0.0;
        tpPips = 0.0;
        slPrice = 0.0;
        tpPrice = 0.0;
    }
};

//+------------------------------------------------------------------+
//| 発注リクエスト構造体                                                |
//+------------------------------------------------------------------+
struct OrderRequest {
    string   symbol;            // シンボル
    TradeDirection direction;   // LONG or SHORT
    double   lot;               // ロット数
    double   slPrice;           // SL価格（0.0の場合はslPipsを使用）
    double   tpPrice;           // TP価格（0.0の場合はtpPipsを使用）
    double   slPips;            // SLのpips（slPriceが0.0の場合）
    double   tpPips;            // TPのpips（tpPriceが0.0の場合）
    long     magic;             // マジックナンバー
    string   comment;           // コメント
    datetime barTime;           // 評価対象のバー時刻（同一足禁止用）
    string   strategyId;        // Strategy ID

    // 初期化
    void Reset() {
        symbol = "";
        direction = DIRECTION_NEUTRAL;
        lot = 0;
        slPrice = 0;
        tpPrice = 0;
        slPips = 0;
        tpPips = 0;
        magic = EA_MAGIC_NUMBER;
        comment = EA_NAME;
        barTime = 0;
        strategyId = "";
    }
};

//+------------------------------------------------------------------+
//| 発注結果構造体                                                     |
//+------------------------------------------------------------------+
struct OrderResult {
    bool   success;             // 成功/失敗
    ulong  ticket;              // チケット番号（成功時のみ）
    int    retcode;             // リターンコード
    string comment;             // コメント
    string rejectReason;        // 拒否理由（失敗時）

    // 初期化
    void Reset() {
        success = false;
        ticket = 0;
        retcode = 0;
        comment = "";
        rejectReason = "";
    }
};

//+------------------------------------------------------------------+
//| セッション時間帯構造体                                              |
//+------------------------------------------------------------------+
struct TimeWindow {
    string start;               // 開始時刻 "07:00"
    string end;                 // 終了時刻 "14:59"
};

//+------------------------------------------------------------------+
//| セッション設定構造体                                                |
//+------------------------------------------------------------------+
struct SessionConfig {
    bool       enabled;
    TimeWindow windows[8];      // 最大8つの時間帯
    int        windowCount;
    bool       weekDays[7];     // 0=Sun, 1=Mon, ..., 6=Sat

    // 初期化
    void Reset() {
        enabled = false;
        windowCount = 0;
        for (int i = 0; i < 7; i++)
            weekDays[i] = true;
    }
};

//+------------------------------------------------------------------+
//| グローバルガード設定構造体                                          |
//+------------------------------------------------------------------+
struct GlobalGuardsConfig {
    string        timeframe;            // "M1"固定
    bool          useClosedBarOnly;     // true固定
    bool          noReentrySameBar;     // true固定
    int           maxPositionsTotal;    // 最大ポジション数（全体）
    int           maxPositionsPerSymbol;// 最大ポジション数（シンボル別）
    double        maxSpreadPips;        // 最大スプレッド（pips）
    SessionConfig session;              // セッション設定

    // 初期化
    void Reset() {
        timeframe = "M1";
        useClosedBarOnly = true;
        noReentrySameBar = true;
        maxPositionsTotal = DEFAULT_MAX_POSITIONS;
        maxPositionsPerSymbol = DEFAULT_MAX_POSITIONS;
        maxSpreadPips = DEFAULT_MAX_SPREAD_PIPS;
        session.Reset();
    }
};

//+------------------------------------------------------------------+
//| メタ情報構造体                                                     |
//+------------------------------------------------------------------+
struct MetaConfig {
    string formatVersion;       // 必須
    string name;                // 設定名
    string generatedBy;         // 生成元
    string generatedAt;         // 生成日時

    // 初期化
    void Reset() {
        formatVersion = "";
        name = "";
        generatedBy = "";
        generatedAt = "";
    }
};

//+------------------------------------------------------------------+
//| 条件参照構造体                                                     |
//+------------------------------------------------------------------+
struct ConditionRef {
    string blockId;             // ブロックID参照

    void Reset() {
        blockId = "";
    }
};

//+------------------------------------------------------------------+
//| ルールグループ構造体                                                |
//+------------------------------------------------------------------+
struct RuleGroup {
    string       id;                                // RuleGroup ID
    ConditionRef conditions[MAX_CONDITIONS];        // 条件配列
    int          conditionCount;                    // 条件数

    void Reset() {
        id = "";
        conditionCount = 0;
    }
};

//+------------------------------------------------------------------+
//| エントリー要件構造体                                                |
//+------------------------------------------------------------------+
struct EntryRequirement {
    RuleGroup ruleGroups[MAX_RULE_GROUPS];  // RuleGroup配列（OR）
    int       ruleGroupCount;               // RuleGroup数

    void Reset() {
        ruleGroupCount = 0;
    }
};

//+------------------------------------------------------------------+
//| モデル設定構造体（汎用）                                            |
//+------------------------------------------------------------------+
struct ModelConfig {
    string typeId;              // モデルタイプID
    // パラメータはJSON文字列として保持
    string paramsJson;

    // 個別パラメータ（頻繁に使用するものを直接保持）
    double lots;                // lot.fixed用
    double slPips;              // risk.fixedSLTP用
    double tpPips;              // risk.fixedSLTP用

    void Reset() {
        typeId = "";
        paramsJson = "";
        lots = DEFAULT_LOT;
        slPips = DEFAULT_SL_PIPS;
        tpPips = DEFAULT_TP_PIPS;
    }
};

//+------------------------------------------------------------------+
//| ブロック定義構造体                                                  |
//+------------------------------------------------------------------+
struct BlockDefinition {
    string id;                  // ブロックID（例: "filter.spreadMax#1"）
    string typeId;              // タイプID（例: "filter.spreadMax"）
    string paramsJson;          // パラメータJSON文字列

    void Reset() {
        id = "";
        typeId = "";
        paramsJson = "";
    }
};

//+------------------------------------------------------------------+
//| Strategy設定構造体                                                 |
//+------------------------------------------------------------------+
struct StrategyConfig {
    string           id;                    // Strategy ID
    string           name;                  // 名前
    bool             enabled;               // 有効/無効
    int              priority;              // 優先度
    ConflictPolicy   conflictPolicy;        // 競合解決ポリシー
    DirectionPolicy  directionPolicy;       // 方向ポリシー
    EntryRequirement entryRequirement;      // エントリー要件
    ModelConfig      lotModel;              // ロットモデル
    ModelConfig      riskModel;             // リスクモデル
    ModelConfig      exitModel;             // 出口モデル
    ModelConfig      nanpinModel;           // ナンピンモデル

    void Reset() {
        id = "";
        name = "";
        enabled = true;
        priority = 0;
        conflictPolicy = CONFLICT_FIRST_ONLY;
        directionPolicy = POLICY_BOTH;
        entryRequirement.Reset();
        lotModel.Reset();
        riskModel.Reset();
        exitModel.Reset();
        nanpinModel.Reset();
    }
};

//+------------------------------------------------------------------+
//| 設定全体構造体                                                     |
//+------------------------------------------------------------------+
struct Config {
    MetaConfig         meta;
    GlobalGuardsConfig globalGuards;
    StrategyConfig     strategies[MAX_STRATEGIES];
    int                strategyCount;
    BlockDefinition    blocks[MAX_BLOCKS];
    int                blockCount;

    void Reset() {
        meta.Reset();
        globalGuards.Reset();
        strategyCount = 0;
        blockCount = 0;
    }
};

#endif // STRUCTURES_MQH
