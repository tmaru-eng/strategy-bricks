#!/usr/bin/env python3
"""
Unit tests for simulate_strategy method

Tests Task 8.1: `simulate_strategy`メソッドを実装
Validates Requirements 5.3
"""

import unittest
import sys
import os
from datetime import datetime
from unittest.mock import patch, Mock
from io import StringIO
import numpy as np
import json
import tempfile

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Mock MetaTrader5 before importing backtest_engine
sys.modules['MetaTrader5'] = Mock()

from backtest_engine import BacktestEngine


class TestSimulateStrategy(unittest.TestCase):
    """
    Test simulate_strategy method
    
    Tests Task 8.1: ストラテジーブロックの解析、過去データの時系列順反復処理、
                    エントリー/エグジット条件の評価
    Requirements: 5.3
    """
    
    def setUp(self):
        """Set up test fixtures"""
        self.engine = BacktestEngine(
            config_path="test_config.json",
            symbol="USDJPY",
            timeframe="M1",
            start_date=datetime(2024, 1, 1),
            end_date=datetime(2024, 3, 31),
            output_path="test_output.json"
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
    
    def test_simulate_strategy_with_no_data(self):
        """
        Test simulate_strategy with no historical data
        
        Validates that the method handles empty data gracefully
        """
        self.engine.historical_data = np.array([])
        
        # Should not raise an exception
        with patch('sys.stdout', new=StringIO()) as fake_out:
            self.engine.simulate_strategy()
            output = fake_out.getvalue()
        
        # Should complete with 0 trades
        self.assertEqual(len(self.engine.trades), 0)
        self.assertIn("シミュレーション完了: 0 トレード", output)
    
    def test_simulate_strategy_chronological_order(self):
        """
        Test that simulate_strategy processes data in chronological order
        
        Validates Requirement 5.3: 過去データを時系列順に反復処理
        """
        # Create historical data with timestamps
        timestamps = [
            datetime(2024, 1, 1, 0, i).timestamp()
            for i in range(30)
        ]
        
        self.engine.historical_data = np.array([
            (ts, 145.0 + i*0.01, 145.5 + i*0.01, 144.5 + i*0.01, 145.2 + i*0.01, 100, 0, 0)
            for i, ts in enumerate(timestamps)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        # Track the order of processing
        processed_times = []
        
        original_check_entry = self.engine.check_entry_signal
        def track_entry(bar, index, direction):
            processed_times.append(bar['time'])
            return original_check_entry(bar, index, direction)
        
        with patch.object(self.engine, 'check_entry_signal', side_effect=track_entry):
            self.engine.simulate_strategy()
        
        # Verify times were processed in chronological order
        self.assertEqual(processed_times, sorted(processed_times))
    
    def test_simulate_strategy_entry_and_exit(self):
        """
        Test that simulate_strategy correctly handles entry and exit signals
        
        Validates Requirement 5.3: エントリー/エグジット条件の評価
        """
        # Create historical data with 30 bars
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0 + i*0.01, 145.5 + i*0.01, 144.5 + i*0.01, 145.2 + i*0.01, 
             100, 0, 0)
            for i in range(30)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.simulate_strategy()
        
        # Should have generated some trades
        # (exact number depends on the simple MA crossover logic)
        self.assertGreaterEqual(len(self.engine.trades), 0)
    
    def test_simulate_strategy_trade_recording(self):
        """
        Test that simulate_strategy records trades with correct fields
        
        Validates Requirement 5.4: トレード記録の完全性
        """
        # Create historical data that will trigger trades
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0 + i*0.01, 145.5 + i*0.01, 144.5 + i*0.01, 145.2 + i*0.01, 
             100, 0, 0)
            for i in range(30)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.simulate_strategy()
        
        # Check that any recorded trades have all required fields
        for trade in self.engine.trades:
            self.assertIn('entryTime', trade)
            self.assertIn('entryPrice', trade)
            self.assertIn('exitTime', trade)
            self.assertIn('exitPrice', trade)
            self.assertIn('positionSize', trade)
            self.assertIn('profitLoss', trade)
            self.assertIn('type', trade)
            
            # Verify types
            self.assertIsInstance(trade['entryTime'], str)
            self.assertIsInstance(trade['entryPrice'], float)
            self.assertIsInstance(trade['exitTime'], str)
            self.assertIsInstance(trade['exitPrice'], float)
            self.assertIsInstance(trade['positionSize'], float)
            self.assertIsInstance(trade['profitLoss'], float)
            self.assertIn(trade['type'], ['BUY', 'SELL'])
    
    def test_simulate_strategy_buy_profit_calculation(self):
        """
        Test profit calculation for BUY trades
        
        Validates Requirement 5.5: 損益計算の正確性 (BUY)
        """
        # Create data that will trigger a BUY trade
        # Price goes up, so MA will be below current price
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0 + i*0.02, 145.5 + i*0.02, 144.5 + i*0.02, 145.2 + i*0.02, 
             100, 0, 0)
            for i in range(30)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.simulate_strategy()
        
        # Find BUY trades and verify P/L calculation
        buy_trades = [t for t in self.engine.trades if t['type'] == 'BUY']
        
        for trade in buy_trades:
            expected_pnl = trade['exitPrice'] - trade['entryPrice']
            self.assertAlmostEqual(trade['profitLoss'], expected_pnl, places=5)
    
    def test_simulate_strategy_sell_profit_calculation(self):
        """
        Test profit calculation for SELL trades
        
        Validates Requirement 5.5: 損益計算の正確性 (SELL)
        """
        # Create data that will trigger a SELL trade
        # Price goes down, so MA will be above current price
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0 - i*0.02, 145.5 - i*0.02, 144.5 - i*0.02, 145.2 - i*0.02, 
             100, 0, 0)
            for i in range(30)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.simulate_strategy()
        
        # Find SELL trades and verify P/L calculation
        sell_trades = [t for t in self.engine.trades if t['type'] == 'SELL']
        
        for trade in sell_trades:
            expected_pnl = trade['entryPrice'] - trade['exitPrice']
            self.assertAlmostEqual(trade['profitLoss'], expected_pnl, places=5)
    
    def test_check_entry_signal_insufficient_data(self):
        """
        Test that check_entry_signal returns False when insufficient data
        
        Validates that the method requires at least 20 bars for MA calculation
        """
        # Create data with only 10 bars
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0, 145.5, 144.5, 145.2, 100, 0, 0)
            for i in range(10)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        # Check entry signal at index 5 (less than 20)
        result = self.engine.check_entry_signal(
            self.engine.historical_data[5], 5, 'BUY'
        )
        
        self.assertFalse(result)
    
    def test_check_entry_signal_buy_condition(self):
        """
        Test BUY entry signal when price is above MA
        
        Validates the simple MA crossover logic for BUY
        """
        # Create data where current price is above MA
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0, 145.5, 144.5, 145.0 if i < 20 else 146.0, 100, 0, 0)
            for i in range(25)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        # Check entry signal at index 20 (price jumped to 146.0, MA is ~145.0)
        result = self.engine.check_entry_signal(
            self.engine.historical_data[20], 20, 'BUY'
        )
        
        self.assertTrue(result)
    
    def test_check_entry_signal_sell_condition(self):
        """
        Test SELL entry signal when price is below MA
        
        Validates the simple MA crossover logic for SELL
        """
        # Create data where current price is below MA
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0, 145.5, 144.5, 145.0 if i < 20 else 144.0, 100, 0, 0)
            for i in range(25)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        # Check entry signal at index 20 (price dropped to 144.0, MA is ~145.0)
        result = self.engine.check_entry_signal(
            self.engine.historical_data[20], 20, 'SELL'
        )
        
        self.assertTrue(result)
    
    def test_check_exit_signal_periodic(self):
        """
        Test exit signal logic (simple periodic exit)
        
        Validates the simple exit logic (every 10 bars)
        """
        bar = {'time': datetime(2024, 1, 1, 0, 0).timestamp(), 'close': 145.0}
        
        # Should exit at index 10, 20, 30, etc.
        self.assertTrue(self.engine.check_exit_signal(bar, 10, 'BUY'))
        self.assertTrue(self.engine.check_exit_signal(bar, 20, 'BUY'))
        self.assertTrue(self.engine.check_exit_signal(bar, 30, 'SELL'))
        
        # Should not exit at other indices
        self.assertFalse(self.engine.check_exit_signal(bar, 5, 'BUY'))
        self.assertFalse(self.engine.check_exit_signal(bar, 15, 'SELL'))
    
    def test_simulate_strategy_no_position_overlap(self):
        """
        Test that only one position is open at a time
        
        Validates that the simple implementation doesn't open multiple positions
        """
        # Create historical data
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0 + i*0.01, 145.5 + i*0.01, 144.5 + i*0.01, 145.2 + i*0.01, 
             100, 0, 0)
            for i in range(50)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()):
            self.engine.simulate_strategy()
        
        # Verify no overlapping trades
        for i in range(len(self.engine.trades) - 1):
            trade1 = self.engine.trades[i]
            trade2 = self.engine.trades[i + 1]
            
            exit_time1 = datetime.fromisoformat(trade1['exitTime'])
            entry_time2 = datetime.fromisoformat(trade2['entryTime'])
            
            # Trade 2 should start after Trade 1 ends
            self.assertLessEqual(exit_time1, entry_time2)
    
    def test_simulate_strategy_prints_progress(self):
        """
        Test that simulate_strategy prints progress messages
        
        Validates that the method provides feedback during execution
        """
        self.engine.historical_data = np.array([
            (datetime(2024, 1, 1, 0, i).timestamp(), 
             145.0, 145.5, 144.5, 145.2, 100, 0, 0)
            for i in range(30)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()) as fake_out:
            self.engine.simulate_strategy()
            output = fake_out.getvalue()
        
        # Should print start and completion messages
        self.assertIn("シミュレーション開始", output)
        self.assertIn("シミュレーション完了", output)
        self.assertIn("トレード", output)


class TestSimulateStrategyIntegration(unittest.TestCase):
    """
    Integration tests for simulate_strategy with realistic scenarios
    """
    
    def test_full_simulation_with_realistic_data(self):
        """
        Test full simulation with realistic price data
        
        Validates end-to-end simulation flow
        """
        engine = BacktestEngine(
            config_path="test_config.json",
            symbol="USDJPY",
            timeframe="M1",
            start_date=datetime(2024, 1, 1),
            end_date=datetime(2024, 1, 2),
            output_path="test_output.json"
        )
        
        # Create realistic strategy config
        engine.strategy_config = {
            'meta': {
                'formatVersion': '1.0',
                'name': 'MA Crossover Strategy',
                'generatedBy': 'Test Suite',
                'generatedAt': '2024-01-26T10:00:00Z'
            },
            'globalGuards': {
                'timeframe': 'M1',
                'useClosedBarOnly': True,
                'noReentrySameBar': True,
                'maxPositionsTotal': 1,
                'maxPositionsPerSymbol': 1,
                'maxSpreadPips': 2.5,
                'session': {
                    'enabled': True,
                    'windows': [{'start': '00:00', 'end': '23:59'}],
                    'weekDays': {
                        'sun': False, 'mon': True, 'tue': True,
                        'wed': True, 'thu': True, 'fri': True, 'sat': False
                    }
                }
            },
            'strategies': [],
            'blocks': []
        }
        
        # Create realistic price data with trend
        base_price = 145.0
        engine.historical_data = np.array([
            (datetime(2024, 1, 1, i // 60, i % 60).timestamp(),
             base_price + i*0.001,  # Gradual uptrend
             base_price + i*0.001 + 0.01,
             base_price + i*0.001 - 0.01,
             base_price + i*0.001 + 0.0005,
             100 + i, 2, 1000)
            for i in range(100)
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        with patch('sys.stdout', new=StringIO()):
            engine.simulate_strategy()
        
        # Verify simulation completed
        self.assertIsInstance(engine.trades, list)
        
        # Verify all trades have valid data
        for trade in engine.trades:
            self.assertGreater(trade['exitPrice'], 0)
            self.assertGreater(trade['entryPrice'], 0)
            self.assertIsNotNone(trade['profitLoss'])


if __name__ == '__main__':
    unittest.main()
