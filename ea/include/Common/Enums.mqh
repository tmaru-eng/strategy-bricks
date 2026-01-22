//+------------------------------------------------------------------+
//|                                                      Enums.mqh   |
//|                                         Strategy Bricks EA MVP   |
//|                       列挙型（BlockStatus, Direction, LogEvent等）  |
//+------------------------------------------------------------------+
#ifndef ENUMS_MQH
#define ENUMS_MQH

//+------------------------------------------------------------------+
//| ブロック評価ステータス                                               |
//+------------------------------------------------------------------+
enum BlockStatus {
    BLOCK_STATUS_PASS,      // 条件成立（エントリー許可）
    BLOCK_STATUS_FAIL,      // 条件不成立（エントリー拒否）
    BLOCK_STATUS_NEUTRAL    // 判定なし（将来拡張用）
};

//+------------------------------------------------------------------+
//| 方向                                                              |
//+------------------------------------------------------------------+
enum TradeDirection {
    DIRECTION_LONG,         // ロング方向
    DIRECTION_SHORT,        // ショート方向
    DIRECTION_NEUTRAL       // 方向なし
};

//+------------------------------------------------------------------+
//| 方向ポリシー                                                       |
//+------------------------------------------------------------------+
enum DirectionPolicy {
    POLICY_LONG_ONLY,       // ロングのみ
    POLICY_SHORT_ONLY,      // ショートのみ
    POLICY_BOTH             // 両方向
};

//+------------------------------------------------------------------+
//| 競合解決ポリシー                                                   |
//+------------------------------------------------------------------+
enum ConflictPolicy {
    CONFLICT_FIRST_ONLY,    // 最初にマッチしたStrategyのみ
    CONFLICT_BEST_SCORE,    // スコア最高のStrategy（将来拡張）
    CONFLICT_ALL            // 全てのマッチしたStrategy（将来拡張）
};

//+------------------------------------------------------------------+
//| ログイベント種別                                                   |
//+------------------------------------------------------------------+
enum LogEvent {
    LOG_INIT_START,         // 初期化開始
    LOG_CONFIG_LOADED,      // 設定読込完了
    LOG_CONFIG_ERROR,       // 設定エラー
    LOG_BAR_EVAL_START,     // 新バー評価開始
    LOG_STRATEGY_EVAL,      // Strategy評価結果
    LOG_RULEGROUP_EVAL,     // RuleGroup評価結果
    LOG_BLOCK_EVAL,         // ブロック評価結果
    LOG_ORDER_ATTEMPT,      // 発注試行
    LOG_ORDER_RESULT,       // 発注結果
    LOG_ORDER_REJECT,       // 発注拒否
    LOG_MANAGEMENT_ACTION,  // 管理アクション
    LOG_NANPIN_ACTION,      // ナンピンアクション
    LOG_INDICATOR_ERROR,    // インジケータエラー
    LOG_LIMIT_EXCEEDED,     // ポジション制限超過
    LOG_DEINIT,             // 終了処理
    LOG_INFO,               // 一般情報
    LOG_ERROR               // エラー
};

//+------------------------------------------------------------------+
//| 発注拒否理由                                                       |
//+------------------------------------------------------------------+
enum OrderRejectType {
    REJECT_SAME_BAR_REENTRY,    // 同一足再エントリー
    REJECT_INVALID_LOT,         // 無効なロット
    REJECT_INVALID_SLTP,        // 無効なSL/TP
    REJECT_SPREAD_TOO_HIGH,     // スプレッド超過
    REJECT_POSITION_LIMIT,      // ポジション制限
    REJECT_OUTSIDE_SESSION,     // セッション外
    REJECT_BROKER_ERROR,        // ブローカーエラー
    REJECT_INSUFFICIENT_MARGIN  // 証拠金不足
};

//+------------------------------------------------------------------+
//| MAタイプ文字列変換                                                  |
//+------------------------------------------------------------------+
ENUM_MA_METHOD StringToMAMethod(string maType) {
    if (maType == "SMA" || maType == "sma")
        return MODE_SMA;
    if (maType == "EMA" || maType == "ema")
        return MODE_EMA;
    if (maType == "SMMA" || maType == "smma")
        return MODE_SMMA;
    if (maType == "LWMA" || maType == "lwma")
        return MODE_LWMA;
    // デフォルト
    return MODE_EMA;
}

//+------------------------------------------------------------------+
//| MAタイプを文字列に変換                                              |
//+------------------------------------------------------------------+
string MAMethodToString(ENUM_MA_METHOD maType) {
    switch (maType) {
        case MODE_SMA:  return "SMA";
        case MODE_EMA:  return "EMA";
        case MODE_SMMA: return "SMMA";
        case MODE_LWMA: return "LWMA";
        default:        return "EMA";
    }
}

//+------------------------------------------------------------------+
//| BlockStatusを文字列に変換                                          |
//+------------------------------------------------------------------+
string BlockStatusToString(BlockStatus status) {
    switch (status) {
        case BLOCK_STATUS_PASS:    return "PASS";
        case BLOCK_STATUS_FAIL:    return "FAIL";
        case BLOCK_STATUS_NEUTRAL: return "NEUTRAL";
        default:                   return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| TradeDirectionを文字列に変換                                        |
//+------------------------------------------------------------------+
string DirectionToString(TradeDirection direction) {
    switch (direction) {
        case DIRECTION_LONG:    return "LONG";
        case DIRECTION_SHORT:   return "SHORT";
        case DIRECTION_NEUTRAL: return "NEUTRAL";
        default:                return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| LogEventを文字列に変換                                             |
//+------------------------------------------------------------------+
string LogEventToString(LogEvent event) {
    switch (event) {
        case LOG_INIT_START:        return "INIT_START";
        case LOG_CONFIG_LOADED:     return "CONFIG_LOADED";
        case LOG_CONFIG_ERROR:      return "CONFIG_ERROR";
        case LOG_BAR_EVAL_START:    return "BAR_EVAL_START";
        case LOG_STRATEGY_EVAL:     return "STRATEGY_EVAL";
        case LOG_RULEGROUP_EVAL:    return "RULEGROUP_EVAL";
        case LOG_BLOCK_EVAL:        return "BLOCK_EVAL";
        case LOG_ORDER_ATTEMPT:     return "ORDER_ATTEMPT";
        case LOG_ORDER_RESULT:      return "ORDER_RESULT";
        case LOG_ORDER_REJECT:      return "ORDER_REJECT";
        case LOG_MANAGEMENT_ACTION: return "MANAGEMENT_ACTION";
        case LOG_NANPIN_ACTION:     return "NANPIN_ACTION";
        case LOG_INDICATOR_ERROR:   return "INDICATOR_ERROR";
        case LOG_LIMIT_EXCEEDED:    return "LIMIT_EXCEEDED";
        case LOG_DEINIT:            return "DEINIT";
        case LOG_INFO:              return "INFO";
        case LOG_ERROR:             return "ERROR";
        default:                    return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| OrderRejectTypeを文字列に変換                                       |
//+------------------------------------------------------------------+
string RejectTypeToString(OrderRejectType rejectType) {
    switch (rejectType) {
        case REJECT_SAME_BAR_REENTRY:   return "SAME_BAR_REENTRY";
        case REJECT_INVALID_LOT:        return "INVALID_LOT";
        case REJECT_INVALID_SLTP:       return "INVALID_SLTP";
        case REJECT_SPREAD_TOO_HIGH:    return "SPREAD_TOO_HIGH";
        case REJECT_POSITION_LIMIT:     return "POSITION_LIMIT";
        case REJECT_OUTSIDE_SESSION:    return "OUTSIDE_SESSION";
        case REJECT_BROKER_ERROR:       return "BROKER_ERROR";
        case REJECT_INSUFFICIENT_MARGIN: return "INSUFFICIENT_MARGIN";
        default:                        return "UNKNOWN";
    }
}

#endif // ENUMS_MQH
