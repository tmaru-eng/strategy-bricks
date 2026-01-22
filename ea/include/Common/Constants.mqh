//+------------------------------------------------------------------+
//|                                                   Constants.mqh  |
//|                                         Strategy Bricks EA MVP   |
//|                          定数定義（マジックナンバー、ファイルパス等）    |
//+------------------------------------------------------------------+
#ifndef CONSTANTS_MQH
#define CONSTANTS_MQH

//--- EA識別子
#define EA_NAME                    "Strategy Bricks"
#define EA_VERSION                 "1.0.0"
#define EA_MAGIC_NUMBER            20260122

//--- 設定ファイルパス
#define CONFIG_DEFAULT_PATH        "strategy/active.json"
#define LOG_PATH_PREFIX            "strategy/logs/strategy_"
#define LOG_FILE_EXTENSION         ".jsonl"

//--- サポートするformatVersion
#define FORMAT_VERSION_MIN         "1.0"
#define FORMAT_VERSION_MAX         "1.0"

//--- タイムフレーム（M1固定）
#define EA_TIMEFRAME               PERIOD_M1

//--- 確定足のshift
#define CONFIRMED_BAR_SHIFT        1

//--- 発注パラメータ
#define ORDER_DEVIATION            5       // スリッページ許容（ポイント）
#define ORDER_FILL_POLICY          ORDER_FILLING_IOC

//--- ログローテーション
#define LOG_FLUSH_INTERVAL         1       // 即時フラッシュ

//--- 配列の初期サイズ
#define INITIAL_ARRAY_SIZE         16
#define MAX_STRATEGIES             32
#define MAX_BLOCKS                 128
#define MAX_RULE_GROUPS            16
#define MAX_CONDITIONS             32

//--- pips計算用
#define PIPS_MULTIPLIER_JPY        100.0   // JPYペア: 1pips = 0.01
#define PIPS_MULTIPLIER_OTHER      10000.0 // 他ペア: 1pips = 0.0001

//--- デフォルト値
#define DEFAULT_LOT                0.1
#define DEFAULT_SL_PIPS            30.0
#define DEFAULT_TP_PIPS            30.0
#define DEFAULT_MAX_SPREAD_PIPS    2.0
#define DEFAULT_MAX_POSITIONS      1

//--- エラーコード
#define ERR_CONFIG_NOT_FOUND       10001
#define ERR_CONFIG_PARSE_FAILED    10002
#define ERR_CONFIG_INVALID_VERSION 10003
#define ERR_CONFIG_VALIDATION      10004
#define ERR_BLOCK_NOT_FOUND        10005
#define ERR_INDICATOR_FAILED       10006

#endif // CONSTANTS_MQH
