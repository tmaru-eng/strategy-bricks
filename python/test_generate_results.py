#!/usr/bin/env python3
"""
Unit tests for generate_results method

Tests Task 9.1: `generate_results`メソッドを実装
Validates Requirements 6.1, 6.2
"""

import unittest
import sys
import os
from datetime import datetime
from unittest.mock import patch, Mock
from io import StringIO
import json
import tempfile

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Mock MetaTrader5 before importing backtest_engine
sys.modules['MetaTrader5'] = Mock()

from backtest_engine import BacktestEngine


class TestGenerateResults(unittest.TestCase):
    """
    Test generate_results method
    
    Tests Task 9.1: 総トレード数、勝ちトレード数、負けトレード数の計算
                    勝率、総損益、平均トレード損益の計算
    Requirements: 6.1, 6.2
    """
    
    def setUp(self):
        """Set up test fixtures"""
        # Create temporary output file
        self.temp_output = tempfile.NamedTemporaryFile(
            mode='w', suffix='.json', delete=False
        )
        self.temp_output.close()
        
        self.engine = BacktestEngine(
            config_path="test_config.json",
            symbol="USDJPY",
            timeframe="M1",
            start_date=datetime(2024, 1, 1),
            end_date=datetime(2024, 3, 31),
            output_path=self.temp_output.name
        )
        
        # Create sample strategy config
        self.engine.strategy_config = {
            'meta': {
                'formatVersion': '1.0',
                'name': 'Test Strategy',
                'generatedBy': 'Test Suite',
                'generatedAt': '2024-01-26T10:00:00Z'
            },
            'globalGuards': {},
            'strategies': [],
            'blocks': []
        }
    
    def tearDown(self):
        """Clean up temporary files"""
        if os.path.exists(self.temp_output.name):
            os.unlink(self.temp_output.name)
    
    def test_generate_results_with_no_trades(self):
        """
        Test generate_results with no trades
        
        Validates Requirement 6.1: 総トレード数、勝ちトレード数、負けトレード数の計算
        """
        self.engine.trades = []
        
        with patch('sys.stdout', new=StringIO()) as fake_out:
            self.engine.generate_results()
            output = fake_out.getvalue()
        
        # Verify file was created
        self.assertTrue(os.path.exists(self.temp_output.name))
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify summary statistics
        self.assertEqual(results['summary']['totalTrades'], 0)
        self.assertEqual(results['summary']['winningTrades'], 0)
        self.assertEqual(results['summary']['losingTrades'], 0)
        self.assertEqual(results['summary']['winRate'], 0)
        self.assertEqual(results['summary']['totalProfitLoss'], 0)
        self.assertEqual(results['summary']['avgTradeProfitLoss'], 0)
        self.assertEqual(results['summary']['maxDrawdown'], 0)
        
        # Verify output message
        self.assertIn("総トレード数: 0", output)

    def test_generate_results_with_winning_trades(self):
        """
        Test generate_results with all winning trades
        
        Validates Requirement 6.1: 勝ちトレード数、勝率の計算
        """
        self.engine.trades = [
            {
                'entryTime': '2024-01-01T10:00:00',
                'entryPrice': 145.0,
                'exitTime': '2024-01-01T10:10:00',
                'exitPrice': 145.1,
                'positionSize': 1.0,
                'profitLoss': 0.1,
                'type': 'BUY'
            },
            {
                'entryTime': '2024-01-01T11:00:00',
                'entryPrice': 145.2,
                'exitTime': '2024-01-01T11:10:00',
                'exitPrice': 145.5,
                'positionSize': 1.0,
                'profitLoss': 0.3,
                'type': 'BUY'
            },
            {
                'entryTime': '2024-01-01T12:00:00',
                'entryPrice': 145.6,
                'exitTime': '2024-01-01T12:10:00',
                'exitPrice': 145.8,
                'positionSize': 1.0,
                'profitLoss': 0.2,
                'type': 'BUY'
            }
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify summary statistics
        self.assertEqual(results['summary']['totalTrades'], 3)
        self.assertEqual(results['summary']['winningTrades'], 3)
        self.assertEqual(results['summary']['losingTrades'], 0)
        self.assertEqual(results['summary']['winRate'], 100.0)
        self.assertAlmostEqual(results['summary']['totalProfitLoss'], 0.6, places=5)
        self.assertAlmostEqual(results['summary']['avgTradeProfitLoss'], 0.2, places=5)

    def test_generate_results_with_losing_trades(self):
        """
        Test generate_results with all losing trades
        
        Validates Requirement 6.1: 負けトレード数、勝率の計算
        """
        self.engine.trades = [
            {
                'entryTime': '2024-01-01T10:00:00',
                'entryPrice': 145.0,
                'exitTime': '2024-01-01T10:10:00',
                'exitPrice': 144.9,
                'positionSize': 1.0,
                'profitLoss': -0.1,
                'type': 'BUY'
            },
            {
                'entryTime': '2024-01-01T11:00:00',
                'entryPrice': 145.2,
                'exitTime': '2024-01-01T11:10:00',
                'exitPrice': 144.8,
                'positionSize': 1.0,
                'profitLoss': -0.4,
                'type': 'BUY'
            }
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify summary statistics
        self.assertEqual(results['summary']['totalTrades'], 2)
        self.assertEqual(results['summary']['winningTrades'], 0)
        self.assertEqual(results['summary']['losingTrades'], 2)
        self.assertEqual(results['summary']['winRate'], 0.0)
        self.assertAlmostEqual(results['summary']['totalProfitLoss'], -0.5, places=5)
        self.assertAlmostEqual(results['summary']['avgTradeProfitLoss'], -0.25, places=5)

    def test_generate_results_with_mixed_trades(self):
        """
        Test generate_results with mixed winning and losing trades
        
        Validates Requirement 6.1: 総トレード数、勝ちトレード数、負けトレード数、勝率の計算
        Validates Requirement 6.2: 総損益、平均トレード損益の計算
        """
        self.engine.trades = [
            {'profitLoss': 0.1, 'entryTime': '2024-01-01T10:00:00', 
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0, 
             'exitPrice': 145.1, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -0.2, 'entryTime': '2024-01-01T11:00:00',
             'exitTime': '2024-01-01T11:10:00', 'entryPrice': 145.2,
             'exitPrice': 145.0, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': 0.3, 'entryTime': '2024-01-01T12:00:00',
             'exitTime': '2024-01-01T12:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.3, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -0.15, 'entryTime': '2024-01-01T13:00:00',
             'exitTime': '2024-01-01T13:10:00', 'entryPrice': 145.3,
             'exitPrice': 145.15, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': 0.25, 'entryTime': '2024-01-01T14:00:00',
             'exitTime': '2024-01-01T14:10:00', 'entryPrice': 145.1,
             'exitPrice': 145.35, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify summary statistics
        self.assertEqual(results['summary']['totalTrades'], 5)
        self.assertEqual(results['summary']['winningTrades'], 3)
        self.assertEqual(results['summary']['losingTrades'], 2)
        self.assertAlmostEqual(results['summary']['winRate'], 60.0, places=2)
        
        # Total P/L: 0.1 - 0.2 + 0.3 - 0.15 + 0.25 = 0.3
        self.assertAlmostEqual(results['summary']['totalProfitLoss'], 0.3, places=5)
        
        # Average P/L: 0.3 / 5 = 0.06
        self.assertAlmostEqual(results['summary']['avgTradeProfitLoss'], 0.06, places=5)

    def test_generate_results_with_zero_profit_trades(self):
        """
        Test generate_results with zero profit/loss trades
        
        Validates edge case: trades with exactly 0 P/L
        """
        self.engine.trades = [
            {'profitLoss': 0.0, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.0, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': 0.1, 'entryTime': '2024-01-01T11:00:00',
             'exitTime': '2024-01-01T11:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.1, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -0.1, 'entryTime': '2024-01-01T12:00:00',
             'exitTime': '2024-01-01T12:10:00', 'entryPrice': 145.1,
             'exitPrice': 145.0, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Zero P/L trades are not counted as winning or losing
        self.assertEqual(results['summary']['totalTrades'], 3)
        self.assertEqual(results['summary']['winningTrades'], 1)
        self.assertEqual(results['summary']['losingTrades'], 1)
        self.assertAlmostEqual(results['summary']['winRate'], 33.33, places=2)
        self.assertAlmostEqual(results['summary']['totalProfitLoss'], 0.0, places=5)

    def test_generate_results_metadata(self):
        """
        Test that generate_results includes correct metadata
        
        Validates Requirement 6.5: メタデータを含む
        """
        self.engine.trades = [
            {'profitLoss': 0.1, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.1, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify metadata exists and has required fields
        self.assertIn('metadata', results)
        metadata = results['metadata']
        
        self.assertEqual(metadata['strategyName'], 'Test Strategy')
        self.assertEqual(metadata['symbol'], 'USDJPY')
        self.assertEqual(metadata['timeframe'], 'M1')
        self.assertEqual(metadata['startDate'], '2024-01-01T00:00:00')
        self.assertEqual(metadata['endDate'], '2024-03-31T00:00:00')
        self.assertIn('executionTimestamp', metadata)
        
        # Verify executionTimestamp is a valid ISO format
        datetime.fromisoformat(metadata['executionTimestamp'])
    
    def test_generate_results_trades_list(self):
        """
        Test that generate_results includes trades list
        
        Validates Requirement 6.3: すべてのトレード記録をシリアライズ
        """
        self.engine.trades = [
            {'profitLoss': 0.1, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.1, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -0.2, 'entryTime': '2024-01-01T11:00:00',
             'exitTime': '2024-01-01T11:10:00', 'entryPrice': 145.2,
             'exitPrice': 145.0, 'positionSize': 1.0, 'type': 'SELL'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify trades list
        self.assertIn('trades', results)
        self.assertEqual(len(results['trades']), 2)
        self.assertEqual(results['trades'], self.engine.trades)

    def test_generate_results_rounding(self):
        """
        Test that generate_results rounds values correctly
        
        Validates that statistics are rounded to appropriate precision
        """
        self.engine.trades = [
            {'profitLoss': 0.123456789, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.123456789, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': 0.987654321, 'entryTime': '2024-01-01T11:00:00',
             'exitTime': '2024-01-01T11:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.987654321, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -0.333333333, 'entryTime': '2024-01-01T12:00:00',
             'exitTime': '2024-01-01T12:10:00', 'entryPrice': 145.0,
             'exitPrice': 144.666666667, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify rounding (should be 5 decimal places for P/L, 2 for win rate)
        summary = results['summary']
        
        # Win rate should be rounded to 2 decimal places
        self.assertEqual(summary['winRate'], 66.67)
        
        # P/L values should be rounded to 5 decimal places
        # Total: 0.123456789 + 0.987654321 - 0.333333333 = 0.777777777
        self.assertEqual(summary['totalProfitLoss'], 0.77778)
        
        # Average: 0.777777777 / 3 = 0.259259259
        self.assertEqual(summary['avgTradeProfitLoss'], 0.25926)
    
    def test_generate_results_max_drawdown_integration(self):
        """
        Test that generate_results calls calculate_max_drawdown
        
        Validates Requirement 6.2: 最大ドローダウンを計算
        """
        self.engine.trades = [
            {'profitLoss': 10.0, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 155.0, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -5.0, 'entryTime': '2024-01-01T11:00:00',
             'exitTime': '2024-01-01T11:10:00', 'entryPrice': 155.0,
             'exitPrice': 150.0, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': 3.0, 'entryTime': '2024-01-01T12:00:00',
             'exitTime': '2024-01-01T12:10:00', 'entryPrice': 150.0,
             'exitPrice': 153.0, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -8.0, 'entryTime': '2024-01-01T13:00:00',
             'exitTime': '2024-01-01T13:10:00', 'entryPrice': 153.0,
             'exitPrice': 145.0, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Read and verify results
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Max drawdown should be calculated correctly
        # Cumulative: 10, 5, 8, 0
        # Peak: 10, 10, 10, 10
        # Drawdown: 0, 5, 2, 10
        # Max drawdown: 10
        self.assertEqual(results['summary']['maxDrawdown'], 10.0)

    def test_generate_results_output_format(self):
        """
        Test that generate_results creates valid JSON output
        
        Validates Requirement 6.3: 結果をJSONファイルにシリアライズ
        Validates Requirement 6.4: 予測可能な出力パスに保存
        """
        self.engine.trades = [
            {'profitLoss': 0.1, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.1, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.generate_results()
        
        # Verify file exists at expected path
        self.assertTrue(os.path.exists(self.temp_output.name))
        
        # Verify file contains valid JSON
        with open(self.temp_output.name, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        # Verify top-level structure
        self.assertIn('metadata', results)
        self.assertIn('summary', results)
        self.assertIn('trades', results)
        
        # Verify summary structure
        summary_keys = [
            'totalTrades', 'winningTrades', 'losingTrades', 'winRate',
            'totalProfitLoss', 'maxDrawdown', 'avgTradeProfitLoss'
        ]
        for key in summary_keys:
            self.assertIn(key, results['summary'])
    
    def test_generate_results_prints_summary(self):
        """
        Test that generate_results prints summary to stdout
        
        Validates that the method provides feedback
        """
        self.engine.trades = [
            {'profitLoss': 0.1, 'entryTime': '2024-01-01T10:00:00',
             'exitTime': '2024-01-01T10:10:00', 'entryPrice': 145.0,
             'exitPrice': 145.1, 'positionSize': 1.0, 'type': 'BUY'},
            {'profitLoss': -0.05, 'entryTime': '2024-01-01T11:00:00',
             'exitTime': '2024-01-01T11:10:00', 'entryPrice': 145.1,
             'exitPrice': 145.05, 'positionSize': 1.0, 'type': 'BUY'}
        ]
        
        with patch('sys.stdout', new=StringIO()) as fake_out:
            self.engine.generate_results()
            output = fake_out.getvalue()
        
        # Verify output contains summary information
        self.assertIn("結果を生成中", output)
        self.assertIn("結果を保存しました", output)
        self.assertIn("総トレード数: 2", output)
        self.assertIn("勝率:", output)
        self.assertIn("総損益:", output)
        self.assertIn("最大ドローダウン:", output)


if __name__ == '__main__':
    unittest.main()
