/**
 * バックテスト機能の型定義
 * 
 * このファイルは、GUIバックテスト統合機能で使用される
 * TypeScriptインターフェースを定義します。
 */

/**
 * バックテスト設定
 * 
 * ユーザーがバックテストを実行する際に指定するパラメータ
 */
export interface BacktestConfig {
  /** 取引シンボル（例: "USDJPY"） */
  symbol: string;
  
  /** 時間軸（例: "M1", "M5", "H1", "D1"） */
  timeframe: string;
  
  /** バックテスト開始日 */
  startDate: Date;
  
  /** バックテスト終了日 */
  endDate: Date;
}

/**
 * バックテスト結果のメタデータ
 */
export interface BacktestMetadata {
  /** ストラテジー名 */
  strategyName: string;
  
  /** 取引シンボル */
  symbol: string;
  
  /** 時間軸 */
  timeframe: string;
  
  /** バックテスト開始日（ISO形式） */
  startDate: string;
  
  /** バックテスト終了日（ISO形式） */
  endDate: string;
  
  /** 実行タイムスタンプ（ISO形式） */
  executionTimestamp: string;
}

/**
 * バックテスト結果のサマリー統計
 */
export interface BacktestSummary {
  /** 総トレード数 */
  totalTrades: number;
  
  /** 勝ちトレード数 */
  winningTrades: number;
  
  /** 負けトレード数 */
  losingTrades: number;
  
  /** 勝率（パーセンテージ） */
  winRate: number;
  
  /** 総損益 */
  totalProfitLoss: number;
  
  /** 最大ドローダウン */
  maxDrawdown: number;
  
  /** 平均トレード損益 */
  avgTradeProfitLoss: number;
}

/**
 * 個別トレード情報
 */
export interface Trade {
  /** エントリー時刻（ISO形式） */
  entryTime: string;
  
  /** エントリー価格 */
  entryPrice: number;
  
  /** エグジット時刻（ISO形式） */
  exitTime: string;
  
  /** エグジット価格 */
  exitPrice: number;
  
  /** ポジションサイズ */
  positionSize: number;
  
  /** 損益 */
  profitLoss: number;
  
  /** トレードタイプ */
  type: 'BUY' | 'SELL';
}

/**
 * バックテスト結果の完全な構造
 */
export interface BacktestResults {
  /** メタデータ */
  metadata: BacktestMetadata;
  
  /** サマリー統計 */
  summary: BacktestSummary;
  
  /** 個別トレードのリスト */
  trades: Trade[];
}

/**
 * ストラテジー設定（統一設定ファイルフォーマット）
 * 
 * 注意: これは簡略版です。完全な定義はCONFIG_SCHEMA.mdを参照してください。
 */
export interface StrategyConfig {
  /** メタデータ */
  meta: {
    formatVersion: string;
    name: string;
    generatedBy: string;
    generatedAt: string;
    description?: string;
    author?: string;
    tags?: string[];
  };
  
  /** グローバルガード設定 */
  globalGuards: {
    timeframe: string;
    useClosedBarOnly: boolean;
    noReentrySameBar: boolean;
    maxPositionsTotal: number;
    maxPositionsPerSymbol: number;
    maxSpreadPips: number;
    session: {
      enabled: boolean;
      windows: Array<{
        start: string;
        end: string;
      }>;
      weekDays: {
        sun: boolean;
        mon: boolean;
        tue: boolean;
        wed: boolean;
        thu: boolean;
        fri: boolean;
        sat: boolean;
      };
    };
  };
  
  /** ストラテジー定義の配列 */
  strategies: Array<{
    id: string;
    name: string;
    enabled: boolean;
    priority: number;
    conflictPolicy: string;
    directionPolicy: string;
    entryRequirement: {
      type: string;
      ruleGroups: Array<{
        id: string;
        type: string;
        conditions: Array<{
          blockId: string;
        }>;
      }>;
    };
    lotModel: {
      type: string;
      params: Record<string, any>;
    };
    riskModel: {
      type: string;
      params: Record<string, any>;
    };
    exitModel: {
      type: string;
      params: Record<string, any>;
    };
    nanpinModel: {
      type: string;
      params: Record<string, any>;
    };
  }>;
  
  /** ブロック定義の配列 */
  blocks: Array<{
    id: string;
    typeId: string;
    params: Record<string, any>;
  }>;
}

/**
 * バックテスト進捗情報
 */
export interface BacktestProgress {
  /** 実行中かどうか */
  isRunning: boolean;
  
  /** 経過時間（秒） */
  elapsedTime: number;
  
  /** 進捗メッセージ（オプション） */
  message?: string;
}

/**
 * バックテストエラー情報
 */
export interface BacktestError {
  /** エラーメッセージ */
  message: string;
  
  /** エラーコード（オプション） */
  code?: string;
  
  /** エラーの詳細（オプション） */
  details?: string;
}

/**
 * バックテストAPI（preload.tsで公開される）
 */
export interface BacktestAPI {
  /**
   * 環境チェックを実行
   * 
   * @returns 環境チェック結果
   */
  checkEnvironment: () => Promise<{
    isWindows: boolean;
    pythonAvailable: boolean;
    mt5Available: boolean;
    backtestEnabled: boolean;
    message?: string;
  }>;
  
  /**
   * バックテストを開始
   * 
   * @param config バックテスト設定
   * @param strategyPath ストラテジー設定ファイルのパス
   */
  startBacktest: (config: BacktestConfig, strategyPath: string) => Promise<void>;
  
  /**
   * 実行中のバックテストをキャンセル
   */
  cancelBacktest: () => Promise<void>;
  
  /**
   * バックテスト進捗イベントのリスナーを登録
   * 
   * @param callback 進捗情報を受け取るコールバック
   */
  onBacktestProgress: (callback: (progress: BacktestProgress) => void) => void;
  
  /**
   * バックテスト完了イベントのリスナーを登録
   * 
   * @param callback 結果を受け取るコールバック
   */
  onBacktestComplete: (callback: (results: BacktestResults) => void) => void;
  
  /**
   * バックテストエラーイベントのリスナーを登録
   * 
   * @param callback エラー情報を受け取るコールバック
   */
  onBacktestError: (callback: (error: BacktestError) => void) => void;
  
  /**
   * バックテスト結果をファイルにエクスポート
   * 
   * @param results バックテスト結果
   * @param outputPath 出力ファイルパス（省略時はファイル保存ダイアログを表示）
   * @returns エクスポート結果
   */
  exportResults: (results: BacktestResults, outputPath?: string) => Promise<{
    success: boolean;
    canceled?: boolean;
    path?: string;
  }>;
}

