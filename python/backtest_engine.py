#!/usr/bin/env python3
"""
Strategy Bricks Backtest Engine

このモジュールは、Strategy Bricks GUIビルダーで作成されたストラテジー設定を
MetaTrader5の過去データに対してバックテストするためのエンジンです。

使用方法:
    python backtest_engine.py --config <path> --symbol <symbol> --timeframe <tf> 
                              --start <date> --end <date> --output <path>

例:
    python backtest_engine.py --config ../ea/tests/strategy_123.json 
                              --symbol USDJPY --timeframe M1 
                              --start 2024-01-01T00:00:00Z --end 2024-03-31T23:59:59Z
                              --output ../tmp/backtest/results_123.json
"""

import argparse
import json
import sys
from datetime import datetime
from typing import List, Dict, Any, Optional

try:
    import MetaTrader5 as mt5
except ImportError:
    print("エラー: MetaTrader5ライブラリがインストールされていません", file=sys.stderr)
    print("インストール方法: pip install MetaTrader5", file=sys.stderr)
    sys.exit(1)


class BacktestEngine:
    """バックテストエンジンのメインクラス"""
    
    def __init__(
        self,
        config_path: str,
        symbol: str,
        timeframe: str,
        start_date: datetime,
        end_date: datetime,
        output_path: str
    ):
        """
        バックテストエンジンを初期化
        
        Args:
            config_path: ストラテジー設定JSONファイルのパス
            symbol: 取引シンボル（例: USDJPY）
            timeframe: 時間軸（例: M1）
            start_date: バックテスト開始日時
            end_date: バックテスト終了日時
            output_path: 結果出力JSONファイルのパス
        """
        self.config_path = config_path
        self.symbol = symbol
        self.timeframe = timeframe
        self.start_date = start_date
        self.end_date = end_date
        self.output_path = output_path
        self.strategy_config: Optional[Dict[str, Any]] = None
        self.historical_data: Optional[Any] = None
        self.trades: List[Dict[str, Any]] = []
        
    def run(self) -> None:
        """バックテスト実行のメインフロー"""
        try:
            print(f"バックテスト開始: {self.symbol} {self.timeframe}")
            print(f"期間: {self.start_date} - {self.end_date}")
            
            # 1. MT5初期化
            if not self.initialize_mt5():
                raise Exception("MT5初期化に失敗しました")
            
            # 2. ストラテジー設定を読み込み
            self.load_strategy_config()
            
            # 3. 過去データを取得
            self.fetch_historical_data()
            
            # 4. バックテストシミュレーションを実行
            self.simulate_strategy()
            
            # 5. 結果を生成
            self.generate_results()
            
            # 6. クリーンアップ
            mt5.shutdown()
            
            print("バックテスト完了")
            
        except Exception as e:
            print(f"エラー: {str(e)}", file=sys.stderr)
            mt5.shutdown()
            sys.exit(1)
    
    def initialize_mt5(self) -> bool:
        """
        MT5ライブラリを初期化
        
        MT5ターミナルへの接続を確立します。接続が失敗した場合は、
        詳細なエラー情報を標準エラー出力に出力します。
        
        Returns:
            初期化が成功した場合True、失敗した場合False
            
        Note:
            要件 4.1, 4.2 を満たします：
            - MT5ライブラリへの接続を初期化
            - 接続失敗時に説明的なエラーメッセージを出力
        """
        if not mt5.initialize():
            error = mt5.last_error()
            error_code = error[0] if error and len(error) > 0 else 'Unknown'
            error_msg = error[1] if error and len(error) > 1 else 'Unknown error'
            
            print(
                f"MT5初期化失敗: エラーコード {error_code} - {error_msg}",
                file=sys.stderr
            )
            print(
                "MT5ターミナルが起動していることを確認してください。",
                file=sys.stderr
            )
            return False
        
        version = mt5.version()
        terminal_info = mt5.terminal_info()
        
        if terminal_info:
            print(f"MT5初期化成功: バージョン {version}")
            print(f"ターミナル: {terminal_info.name}, ビルド {terminal_info.build}")
            if getattr(terminal_info, "connected", True) is False:
                print(
                    "Warning: MT5 terminal is not connected. Please log in and ensure the terminal is online.",
                    file=sys.stderr
                )
        else:
            print(f"MT5初期化成功: バージョン {version}")
        
        return True
    
    def load_strategy_config(self) -> None:
        """
        ストラテジー設定JSONを読み込み
        
        設定ファイルを読み込み、必須フィールドの存在を検証します。
        CONFIG_SCHEMA.mdで定義されたスキーマに準拠している必要があります。
        
        Raises:
            Exception: ファイルが見つからない場合
            Exception: JSON形式が無効な場合
            ValueError: 必須フィールドが欠落している場合
            
        Note:
            要件 5.1, 5.2 を満たします：
            - ストラテジー設定JSONファイルを解析してロジックとパラメータを抽出
            - 設定が不正または無効な場合は説明的なエラーメッセージで終了
        """
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                self.strategy_config = json.load(f)
            
            print(f"ストラテジー設定を読み込みました: {self.config_path}")
            
            # 必須フィールドを検証（CONFIG_SCHEMA.md セクション10.1に準拠）
            required_fields = ['meta', 'globalGuards', 'strategies', 'blocks']
            missing_fields = []
            
            for field in required_fields:
                if field not in self.strategy_config:
                    missing_fields.append(field)
            
            if missing_fields:
                raise ValueError(
                    f"必須フィールドが見つかりません: {', '.join(missing_fields)}"
                )
            
            # metaの必須サブフィールドを検証
            meta = self.strategy_config.get('meta', {})
            required_meta_fields = ['formatVersion', 'name', 'generatedBy', 'generatedAt']
            missing_meta_fields = []
            
            for field in required_meta_fields:
                if field not in meta:
                    missing_meta_fields.append(f"meta.{field}")
            
            if missing_meta_fields:
                raise ValueError(
                    f"必須フィールドが見つかりません: {', '.join(missing_meta_fields)}"
                )
            
            # フォーマットバージョンを検証
            format_version = meta.get('formatVersion')
            if format_version != '1.0':
                print(
                    f"警告: サポートされていないフォーマットバージョン: {format_version}. "
                    f"サポートされているバージョン: 1.0",
                    file=sys.stderr
                )
            
            strategy_name = meta.get('name', 'Unknown')
            print(f"ストラテジー名: {strategy_name}")
            print(f"フォーマットバージョン: {format_version}")
            print(f"生成元: {meta.get('generatedBy', 'Unknown')}")
                    
        except FileNotFoundError:
            raise Exception(f"設定ファイルが見つかりません: {self.config_path}")
        except json.JSONDecodeError as e:
            raise Exception(f"無効なJSON形式: {str(e)}")
    
    def fetch_historical_data(self) -> None:
        """MT5から過去データを取得"""
        # 時間軸をMT5定数に変換
        timeframe_map = {
            'M1': mt5.TIMEFRAME_M1,
            'M5': mt5.TIMEFRAME_M5,
            'M15': mt5.TIMEFRAME_M15,
            'M30': mt5.TIMEFRAME_M30,
            'H1': mt5.TIMEFRAME_H1,
            'H4': mt5.TIMEFRAME_H4,
            'D1': mt5.TIMEFRAME_D1
        }
        
        mt5_timeframe = timeframe_map.get(self.timeframe)
        if mt5_timeframe is None:
            raise ValueError(f"サポートされていない時間軸: {self.timeframe}")

        requested_symbol = self.symbol
        symbol_info = mt5.symbol_info(requested_symbol)
        if symbol_info is None:
            candidates = [
                s.name
                for s in (mt5.symbols_get() or [])
                if s.name.lower().startswith(requested_symbol.lower())
            ]
            if candidates:
                lower_map = {c.lower(): c for c in candidates}
                if requested_symbol.lower() in lower_map:
                    selected = lower_map[requested_symbol.lower()]
                else:
                    candidates_sorted = sorted(candidates, key=lambda c: (len(c), c.lower()))
                    selected = candidates_sorted[0]
                self.symbol = selected
                symbol_info = mt5.symbol_info(self.symbol)
                preview = ", ".join(candidates[:5])
                more = "" if len(candidates) <= 5 else f" (+{len(candidates) - 5} more)"
                print(
                    f"Warning: Symbol not found: {requested_symbol}. Using {self.symbol}. Candidates: {preview}{more}",
                    file=sys.stderr,
                )
            else:
                raise Exception(f"Symbol not found: {requested_symbol}. No similar symbols found.")
        if not symbol_info or not symbol_info.visible:
            if not mt5.symbol_select(self.symbol, True):
                error = mt5.last_error()
                raise Exception(f"Failed to select symbol: {self.symbol}. Error: {error}")

        
        # バーデータを取得
        print(f"過去データを取得中...")
        rates = mt5.copy_rates_range(
            self.symbol,
            mt5_timeframe,
            self.start_date,
            self.end_date
        )
        
        if rates is None or len(rates) == 0:
            error = mt5.last_error()
            raise Exception(
                f"データ取得失敗: {self.symbol} {self.timeframe} "
                f"{self.start_date} - {self.end_date}. エラー: {error}"
            )
        
        self.historical_data = rates
        print(f"過去データを取得しました: {len(rates)} バー")
        
        # データ範囲を検証
        # タイムゾーン情報を保持してdatetimeに変換
        from datetime import timezone
        first_time = datetime.fromtimestamp(rates[0]['time'], tz=timezone.utc)
        last_time = datetime.fromtimestamp(rates[-1]['time'], tz=timezone.utc)
        
        print(f"データ範囲: {first_time} - {last_time}")
        
        if first_time > self.start_date or last_time < self.end_date:
            print(
                f"警告: データ範囲が不完全です。"
                f"要求: {self.start_date} - {self.end_date}, "
                f"取得: {first_time} - {last_time}",
                file=sys.stderr
            )
    
    def simulate_strategy(self) -> None:
        """
        ストラテジーロジックをシミュレート
        
        注意: これは簡易的な実装です。実際のストラテジーブロックの評価は
        将来のタスクで実装されます。
        """
        print("シミュレーション開始...")
        
        # 簡易的なシミュレーションロジック
        # 実際の実装では、ブロックベースのロジックを評価する必要があります
        position = None  # None, 'BUY', 'SELL'
        entry_price = 0.0
        entry_time = None
        
        from datetime import timezone
        
        for i, bar in enumerate(self.historical_data):
            current_time = datetime.fromtimestamp(bar['time'], tz=timezone.utc)
            current_price = bar['close']
            
            # エントリー条件を評価（簡易版）
            if position is None:
                # エントリーシグナルをチェック
                if self.check_entry_signal(bar, i, 'BUY'):
                    position = 'BUY'
                    entry_price = current_price
                    entry_time = current_time
                    
                elif self.check_entry_signal(bar, i, 'SELL'):
                    position = 'SELL'
                    entry_price = current_price
                    entry_time = current_time
            
            # エグジット条件を評価
            elif position is not None:
                if self.check_exit_signal(bar, i, position):
                    exit_price = current_price
                    exit_time = current_time
                    
                    # 損益を計算
                    if position == 'BUY':
                        pnl = exit_price - entry_price
                    else:  # SELL
                        pnl = entry_price - exit_price
                    
                    # トレードを記録
                    self.trades.append({
                        'entryTime': entry_time.isoformat(),
                        'entryPrice': float(entry_price),
                        'exitTime': exit_time.isoformat(),
                        'exitPrice': float(exit_price),
                        'positionSize': 1.0,  # 簡略化のため固定
                        'profitLoss': float(pnl),
                        'type': position
                    })
                    
                    # ポジションをクローズ
                    position = None
        
        print(f"シミュレーション完了: {len(self.trades)} トレード")
    
    def check_entry_signal(self, bar: Dict, index: int, direction: str) -> bool:
        """
        エントリーシグナルをチェック（簡易版）
        
        注意: これは簡易的な実装です。実際のストラテジーブロックの評価は
        将来のタスクで実装されます。
        
        Args:
            bar: 現在のバーデータ
            index: バーのインデックス
            direction: 'BUY' または 'SELL'
            
        Returns:
            エントリーシグナルがある場合True
        """
        # 実際の実装では、strategy_configのブロックを評価
        # ここでは簡易的なロジックを使用
        
        # 例: 単純な移動平均クロスオーバー
        if index < 20:
            return False
        
        # 過去20バーの平均を計算
        recent_bars = self.historical_data[index-20:index]
        avg_price = sum(float(b['close']) for b in recent_bars) / len(recent_bars)
        
        if direction == 'BUY':
            return float(bar['close']) > avg_price
        else:  # SELL
            return float(bar['close']) < avg_price
    
    def check_exit_signal(self, bar: Dict, index: int, position: str) -> bool:
        """
        エグジットシグナルをチェック（簡易版）
        
        注意: これは簡易的な実装です。実際のストラテジーブロックの評価は
        将来のタスクで実装されます。
        
        Args:
            bar: 現在のバーデータ
            index: バーのインデックス
            position: 'BUY' または 'SELL'
            
        Returns:
            エグジットシグナルがある場合True
        """
        # 実際の実装では、strategy_configのブロックを評価
        # ここでは簡易的なロジックを使用
        
        # 例: 10バー後に自動クローズ
        return index % 10 == 0
    
    def generate_results(self) -> None:
        """バックテスト結果を生成してJSONファイルに保存"""
        print("結果を生成中...")
        
        # 統計を計算
        total_trades = len(self.trades)
        winning_trades = sum(1 for t in self.trades if t['profitLoss'] > 0)
        losing_trades = sum(1 for t in self.trades if t['profitLoss'] < 0)
        win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0
        
        total_pnl = sum(t['profitLoss'] for t in self.trades)
        avg_pnl = total_pnl / total_trades if total_trades > 0 else 0
        
        # 最大ドローダウンを計算
        max_drawdown = self.calculate_max_drawdown()
        
        # 結果オブジェクトを構築
        results = {
            'metadata': {
                'strategyName': self.strategy_config.get('meta', {}).get('name', 'Unknown'),
                'symbol': self.symbol,
                'timeframe': self.timeframe,
                'startDate': self.start_date.isoformat(),
                'endDate': self.end_date.isoformat(),
                'executionTimestamp': datetime.now().isoformat()
            },
            'summary': {
                'totalTrades': total_trades,
                'winningTrades': winning_trades,
                'losingTrades': losing_trades,
                'winRate': round(win_rate, 2),
                'totalProfitLoss': round(total_pnl, 5),
                'maxDrawdown': round(max_drawdown, 5),
                'avgTradeProfitLoss': round(avg_pnl, 5)
            },
            'trades': self.trades
        }
        
        # JSONファイルに書き込み
        with open(self.output_path, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        print(f"結果を保存しました: {self.output_path}")
        print(f"総トレード数: {total_trades}")
        print(f"勝率: {win_rate:.2f}%")
        print(f"総損益: {total_pnl:.5f}")
        print(f"最大ドローダウン: {max_drawdown:.5f}")
    
    def calculate_max_drawdown(self) -> float:
        """
        最大ドローダウンを計算
        
        Returns:
            最大ドローダウン値
        """
        if not self.trades:
            return 0.0
        
        cumulative_pnl = 0.0
        peak = 0.0
        max_dd = 0.0
        
        for trade in self.trades:
            cumulative_pnl += trade['profitLoss']
            
            if cumulative_pnl > peak:
                peak = cumulative_pnl
            
            drawdown = peak - cumulative_pnl
            if drawdown > max_dd:
                max_dd = drawdown
        
        return max_dd


def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(
        description='Strategy Bricks Backtest Engine',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
例:
  python backtest_engine.py --config ../ea/tests/strategy_123.json \\
                            --symbol USDJPY --timeframe M1 \\
                            --start 2024-01-01T00:00:00Z \\
                            --end 2024-03-31T23:59:59Z \\
                            --output ../ea/tests/results_123.json
        """
    )
    
    parser.add_argument(
        '--config',
        required=True,
        help='ストラテジー設定JSONファイルパス'
    )
    parser.add_argument(
        '--symbol',
        required=True,
        help='シンボル（例: USDJPY）'
    )
    parser.add_argument(
        '--timeframe',
        required=True,
        help='時間軸（例: M1, M5, H1, D1）'
    )
    parser.add_argument(
        '--start',
        required=True,
        help='開始日（ISO形式: 2024-01-01T00:00:00Z）'
    )
    parser.add_argument(
        '--end',
        required=True,
        help='終了日（ISO形式: 2024-03-31T23:59:59Z）'
    )
    parser.add_argument(
        '--output',
        required=True,
        help='結果出力パス'
    )
    
    args = parser.parse_args()
    
    # 日付を解析
    try:
        start_date = datetime.fromisoformat(args.start.replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(args.end.replace('Z', '+00:00'))
    except ValueError as e:
        print(f"エラー: 日付形式が無効です: {e}", file=sys.stderr)
        sys.exit(1)
    
    # バックテストエンジンを実行
    engine = BacktestEngine(
        config_path=args.config,
        symbol=args.symbol,
        timeframe=args.timeframe,
        start_date=start_date,
        end_date=end_date,
        output_path=args.output
    )
    
    engine.run()


if __name__ == '__main__':
    main()
