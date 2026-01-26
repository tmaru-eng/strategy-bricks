#!/usr/bin/env python3
"""
Unit tests for fetch_historical_data method

Tests Task 7.1: `fetch_historical_data`メソッドを実装
Validates Requirements 4.3, 4.4
"""

import unittest
import sys
import os
from datetime import datetime
from unittest.mock import patch, Mock, MagicMock
from io import StringIO
import numpy as np

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Mock MetaTrader5 before importing backtest_engine
sys.modules['MetaTrader5'] = Mock()

from backtest_engine import BacktestEngine


class TestFetchHistoricalData(unittest.TestCase):
    """
    Test fetch_historical_data method
    
    Tests Task 7.1: 時間軸マッピング、MT5からのバーデータ取得、エラーハンドリング
    Requirements: 4.3, 4.4
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
    
    @patch('backtest_engine.mt5')
    def test_timeframe_mapping_m1(self, mock_mt5):
        """
        Test timeframe mapping for M1
        
        Validates Task 7.1: 時間軸マッピング（M1, M5, H1など）
        """
        # Mock successful data fetch
        mock_rates = np.array([
            (datetime(2024, 1, 1, 0, 0).timestamp(), 145.0, 145.5, 144.5, 145.2, 100, 0, 0),
            (datetime(2024, 1, 1, 0, 1).timestamp(), 145.2, 145.7, 145.0, 145.5, 120, 0, 0),
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        mock_mt5.copy_rates_range.return_value = mock_rates
        mock_mt5.TIMEFRAME_M1 = 1
        
        # Execute
        self.engine.timeframe = "M1"
        self.engine.fetch_historical_data()
        
        # Verify MT5 was called with correct timeframe constant
        mock_mt5.copy_rates_range.assert_called_once_with(
            "USDJPY",
            1,  # MT5.TIMEFRAME_M1
            self.engine.start_date,
            self.engine.end_date
        )
        
        # Verify data was stored
        self.assertIsNotNone(self.engine.historical_data)
        self.assertEqual(len(self.engine.historical_data), 2)
    
    @patch('backtest_engine.mt5')
    def test_timeframe_mapping_all_supported(self, mock_mt5):
        """
        Test all supported timeframe mappings
        
        Validates Task 7.1: 時間軸マッピング for M1, M5, M15, M30, H1, H4, D1
        """
        # Define MT5 timeframe constants
        mock_mt5.TIMEFRAME_M1 = 1
        mock_mt5.TIMEFRAME_M5 = 5
        mock_mt5.TIMEFRAME_M15 = 15
        mock_mt5.TIMEFRAME_M30 = 30
        mock_mt5.TIMEFRAME_H1 = 16385
        mock_mt5.TIMEFRAME_H4 = 16388
        mock_mt5.TIMEFRAME_D1 = 16408
        
        # Mock successful data fetch
        mock_rates = np.array([
            (datetime(2024, 1, 1, 0, 0).timestamp(), 145.0, 145.5, 144.5, 145.2, 100, 0, 0),
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        mock_mt5.copy_rates_range.return_value = mock_rates
        
        # Test each timeframe
        timeframes = {
            'M1': 1,
            'M5': 5,
            'M15': 15,
            'M30': 30,
            'H1': 16385,
            'H4': 16388,
            'D1': 16408
        }
        
        for tf_str, tf_const in timeframes.items():
            with self.subTest(timeframe=tf_str):
                self.engine.timeframe = tf_str
                mock_mt5.copy_rates_range.reset_mock()
                
                self.engine.fetch_historical_data()
                
                # Verify correct MT5 constant was used
                call_args = mock_mt5.copy_rates_range.call_args
                self.assertEqual(call_args[0][1], tf_const)
    
    @patch('backtest_engine.mt5')
    def test_unsupported_timeframe_raises_error(self, mock_mt5):
        """
        Test that unsupported timeframe raises ValueError
        
        Validates Task 7.1: エラーハンドリング for invalid timeframes
        """
        self.engine.timeframe = "M2"  # Unsupported timeframe
        
        with self.assertRaises(ValueError) as context:
            self.engine.fetch_historical_data()
        
        self.assertIn("サポートされていない時間軸", str(context.exception))
        self.assertIn("M2", str(context.exception))
    
    @patch('backtest_engine.mt5')
    def test_data_fetch_failure_none_result(self, mock_mt5):
        """
        Test error handling when MT5 returns None
        
        Validates Task 7.1: データ取得失敗時のエラーハンドリング
        Validates Requirement 4.4: 過去データが利用不可または不完全な時、説明的なエラーメッセージで終了
        """
        # Mock failed data fetch (returns None)
        mock_mt5.copy_rates_range.return_value = None
        mock_mt5.last_error.return_value = (1, "Data not available")
        mock_mt5.TIMEFRAME_M1 = 1
        
        self.engine.timeframe = "M1"
        
        with self.assertRaises(Exception) as context:
            self.engine.fetch_historical_data()
        
        error_msg = str(context.exception)
        self.assertIn("データ取得失敗", error_msg)
        self.assertIn("USDJPY", error_msg)
        self.assertIn("M1", error_msg)
    
    @patch('backtest_engine.mt5')
    def test_data_fetch_failure_empty_result(self, mock_mt5):
        """
        Test error handling when MT5 returns empty array
        
        Validates Task 7.1: データ取得失敗時のエラーハンドリング
        Validates Requirement 4.4
        """
        # Mock failed data fetch (returns empty array)
        mock_mt5.copy_rates_range.return_value = np.array([])
        mock_mt5.last_error.return_value = (1, "No data in range")
        mock_mt5.TIMEFRAME_M1 = 1
        
        self.engine.timeframe = "M1"
        
        with self.assertRaises(Exception) as context:
            self.engine.fetch_historical_data()
        
        error_msg = str(context.exception)
        self.assertIn("データ取得失敗", error_msg)
    
    @patch('backtest_engine.mt5')
    def test_data_range_validation_complete(self, mock_mt5):
        """
        Test data range validation when data is complete
        
        Validates Task 7.2: データ範囲検証を実装
        Validates Requirement 4.5: 取得したデータが要求された日付範囲をカバーしていることを検証
        """
        # Mock data that covers the full requested range
        start_ts = datetime(2024, 1, 1, 0, 0).timestamp()
        end_ts = datetime(2024, 3, 31, 23, 59).timestamp()
        
        mock_rates = np.array([
            (start_ts, 145.0, 145.5, 144.5, 145.2, 100, 0, 0),
            (end_ts, 145.5, 146.0, 145.0, 145.8, 120, 0, 0),
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        mock_mt5.copy_rates_range.return_value = mock_rates
        mock_mt5.TIMEFRAME_M1 = 1
        
        # Capture stdout to verify no warning
        with patch('sys.stdout', new=StringIO()) as fake_out:
            with patch('sys.stderr', new=StringIO()) as fake_err:
                self.engine.fetch_historical_data()
                
                stdout_output = fake_out.getvalue()
                stderr_output = fake_err.getvalue()
        
        # Verify data was stored
        self.assertIsNotNone(self.engine.historical_data)
        
        # Verify success message
        self.assertIn("過去データを取得しました", stdout_output)
        self.assertIn("2 バー", stdout_output)
        
        # Should not have incomplete data warning
        self.assertNotIn("データ範囲が不完全です", stderr_output)
    
    @patch('backtest_engine.mt5')
    def test_data_range_validation_incomplete_start(self, mock_mt5):
        """
        Test data range validation when start date is after requested
        
        Validates Task 7.2: 不完全なデータの警告
        Validates Requirement 4.5
        """
        # Mock data that starts later than requested
        # Requested: 2024-01-01, but data starts 2024-01-15
        actual_start_ts = datetime(2024, 1, 15, 0, 0).timestamp()
        end_ts = datetime(2024, 3, 31, 23, 59).timestamp()
        
        mock_rates = np.array([
            (actual_start_ts, 145.0, 145.5, 144.5, 145.2, 100, 0, 0),
            (end_ts, 145.5, 146.0, 145.0, 145.8, 120, 0, 0),
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        mock_mt5.copy_rates_range.return_value = mock_rates
        mock_mt5.TIMEFRAME_M1 = 1
        
        # Capture stderr to verify warning
        with patch('sys.stderr', new=StringIO()) as fake_err:
            self.engine.fetch_historical_data()
            
            stderr_output = fake_err.getvalue()
        
        # Verify warning was issued
        self.assertIn("警告: データ範囲が不完全です", stderr_output)
        self.assertIn("要求:", stderr_output)
        self.assertIn("取得:", stderr_output)
    
    @patch('backtest_engine.mt5')
    def test_data_range_validation_incomplete_end(self, mock_mt5):
        """
        Test data range validation when end date is before requested
        
        Validates Task 7.2: 不完全なデータの警告
        """
        # Mock data that ends earlier than requested
        # Requested: 2024-03-31, but data ends 2024-03-15
        start_ts = datetime(2024, 1, 1, 0, 0).timestamp()
        actual_end_ts = datetime(2024, 3, 15, 23, 59).timestamp()
        
        mock_rates = np.array([
            (start_ts, 145.0, 145.5, 144.5, 145.2, 100, 0, 0),
            (actual_end_ts, 145.5, 146.0, 145.0, 145.8, 120, 0, 0),
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        mock_mt5.copy_rates_range.return_value = mock_rates
        mock_mt5.TIMEFRAME_M1 = 1
        
        # Capture stderr to verify warning
        with patch('sys.stderr', new=StringIO()) as fake_err:
            self.engine.fetch_historical_data()
            
            stderr_output = fake_err.getvalue()
        
        # Verify warning was issued
        self.assertIn("警告: データ範囲が不完全です", stderr_output)
    
    @patch('backtest_engine.mt5')
    def test_successful_data_fetch_with_multiple_bars(self, mock_mt5):
        """
        Test successful data fetch with realistic bar data
        
        Validates Task 7.1: MT5からのバーデータ取得
        Validates Requirement 4.3: 指定されたシンボル、時間軸、日付範囲の過去データをリクエスト
        """
        # Mock realistic bar data
        mock_rates = np.array([
            (datetime(2024, 1, 1, 0, 0).timestamp(), 145.0, 145.5, 144.5, 145.2, 100, 2, 1000),
            (datetime(2024, 1, 1, 0, 1).timestamp(), 145.2, 145.7, 145.0, 145.5, 120, 2, 1200),
            (datetime(2024, 1, 1, 0, 2).timestamp(), 145.5, 145.8, 145.3, 145.6, 110, 2, 1100),
            (datetime(2024, 1, 1, 0, 3).timestamp(), 145.6, 145.9, 145.4, 145.7, 130, 2, 1300),
        ], dtype=[('time', 'i8'), ('open', 'f8'), ('high', 'f8'), ('low', 'f8'), 
                  ('close', 'f8'), ('tick_volume', 'i8'), ('spread', 'i4'), ('real_volume', 'i8')])
        
        mock_mt5.copy_rates_range.return_value = mock_rates
        mock_mt5.TIMEFRAME_M1 = 1
        
        # Execute
        with patch('sys.stdout', new=StringIO()) as fake_out:
            self.engine.fetch_historical_data()
            stdout_output = fake_out.getvalue()
        
        # Verify data was stored correctly
        self.assertIsNotNone(self.engine.historical_data)
        self.assertEqual(len(self.engine.historical_data), 4)
        
        # Verify success message includes bar count
        self.assertIn("過去データを取得しました: 4 バー", stdout_output)
        
        # Verify MT5 was called with correct parameters
        mock_mt5.copy_rates_range.assert_called_once_with(
            "USDJPY",
            1,
            self.engine.start_date,
            self.engine.end_date
        )


if __name__ == '__main__':
    unittest.main()
