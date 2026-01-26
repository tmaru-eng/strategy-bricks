#!/usr/bin/env python3
"""
Basic unit tests for BacktestEngine class structure

Tests the basic structure, initialization, and argument parsing
without requiring MT5 connection.
"""

import unittest
import sys
import os
from datetime import datetime
from unittest.mock import patch, MagicMock, Mock
import json
import tempfile
from io import StringIO

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from backtest_engine import BacktestEngine, main


class TestBacktestEngineBasicStructure(unittest.TestCase):
    """Test basic structure of BacktestEngine class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config_path = "test_config.json"
        self.symbol = "USDJPY"
        self.timeframe = "M1"
        self.start_date = datetime(2024, 1, 1)
        self.end_date = datetime(2024, 3, 31)
        self.output_path = "test_output.json"
    
    def test_initialization(self):
        """Test that BacktestEngine initializes correctly"""
        engine = BacktestEngine(
            config_path=self.config_path,
            symbol=self.symbol,
            timeframe=self.timeframe,
            start_date=self.start_date,
            end_date=self.end_date,
            output_path=self.output_path
        )
        
        # Verify all attributes are set correctly
        self.assertEqual(engine.config_path, self.config_path)
        self.assertEqual(engine.symbol, self.symbol)
        self.assertEqual(engine.timeframe, self.timeframe)
        self.assertEqual(engine.start_date, self.start_date)
        self.assertEqual(engine.end_date, self.end_date)
        self.assertEqual(engine.output_path, self.output_path)
        self.assertIsNone(engine.strategy_config)
        self.assertIsNone(engine.historical_data)
        self.assertEqual(engine.trades, [])
    
    def test_has_required_methods(self):
        """Test that BacktestEngine has all required methods"""
        engine = BacktestEngine(
            config_path=self.config_path,
            symbol=self.symbol,
            timeframe=self.timeframe,
            start_date=self.start_date,
            end_date=self.end_date,
            output_path=self.output_path
        )
        
        # Check that all required methods exist
        self.assertTrue(hasattr(engine, 'run'))
        self.assertTrue(hasattr(engine, 'initialize_mt5'))
        self.assertTrue(hasattr(engine, 'load_strategy_config'))
        self.assertTrue(hasattr(engine, 'fetch_historical_data'))
        self.assertTrue(hasattr(engine, 'simulate_strategy'))
        self.assertTrue(hasattr(engine, 'generate_results'))
        self.assertTrue(hasattr(engine, 'calculate_max_drawdown'))
        self.assertTrue(hasattr(engine, 'check_entry_signal'))
        self.assertTrue(hasattr(engine, 'check_exit_signal'))
    
    def test_load_strategy_config_with_valid_file(self):
        """
        Test loading a valid strategy config file
        
        Tests Task 6.3: ストラテジー設定の読み込みと解析を実装
        Validates Requirements 5.1, 5.2
        """
        # Create a temporary config file with all required fields
        config_data = {
            'meta': {
                'formatVersion': '1.0',
                'name': 'Test Strategy',
                'generatedBy': 'Test Suite',
                'generatedAt': '2024-01-26T10:00:00Z'
            },
            'globalGuards': {
                'timeframe': 'M1',
                'useClosedBarOnly': True,
                'noReentrySameBar': True,
                'maxPositionsTotal': 5,
                'maxPositionsPerSymbol': 3,
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
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config_data, f)
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            # Load the config
            engine.load_strategy_config()
            
            # Verify config was loaded
            self.assertIsNotNone(engine.strategy_config)
            self.assertEqual(engine.strategy_config['meta']['name'], 'Test Strategy')
            self.assertEqual(engine.strategy_config['meta']['formatVersion'], '1.0')
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_load_strategy_config_missing_file(self):
        """Test loading a non-existent config file raises exception"""
        engine = BacktestEngine(
            config_path="nonexistent.json",
            symbol=self.symbol,
            timeframe=self.timeframe,
            start_date=self.start_date,
            end_date=self.end_date,
            output_path=self.output_path
        )
        
        with self.assertRaises(Exception) as context:
            engine.load_strategy_config()
        
        self.assertIn("設定ファイルが見つかりません", str(context.exception))
    
    def test_load_strategy_config_invalid_json(self):
        """Test loading invalid JSON raises exception"""
        # Create a temporary file with invalid JSON
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write("{ invalid json }")
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            with self.assertRaises(Exception) as context:
                engine.load_strategy_config()
            
            self.assertIn("無効なJSON形式", str(context.exception))
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_load_strategy_config_missing_required_fields(self):
        """
        Test loading config with missing required fields raises exception
        
        Tests Task 6.3: 必須フィールドのチェック
        Validates Requirement 5.2: 設定が不正または無効な場合は終了
        """
        # Test missing 'meta'
        config_data = {
            'globalGuards': {},
            'strategies': [],
            'blocks': []
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config_data, f)
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            with self.assertRaises(ValueError) as context:
                engine.load_strategy_config()
            
            self.assertIn("必須フィールドが見つかりません", str(context.exception))
            self.assertIn("meta", str(context.exception))
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_load_strategy_config_missing_globalGuards(self):
        """
        Test loading config with missing globalGuards field
        
        Tests Task 6.3: globalGuards必須フィールドのチェック
        """
        config_data = {
            'meta': {
                'formatVersion': '1.0',
                'name': 'Test Strategy',
                'generatedBy': 'Test',
                'generatedAt': '2024-01-26T10:00:00Z'
            },
            'strategies': [],
            'blocks': []
            # Missing 'globalGuards'
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config_data, f)
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            with self.assertRaises(ValueError) as context:
                engine.load_strategy_config()
            
            self.assertIn("必須フィールドが見つかりません", str(context.exception))
            self.assertIn("globalGuards", str(context.exception))
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_load_strategy_config_missing_meta_subfields(self):
        """
        Test loading config with missing meta sub-fields
        
        Tests Task 6.3: meta必須サブフィールドのチェック
        """
        # Missing formatVersion, generatedBy, generatedAt
        config_data = {
            'meta': {
                'name': 'Test Strategy'
                # Missing: formatVersion, generatedBy, generatedAt
            },
            'globalGuards': {},
            'strategies': [],
            'blocks': []
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config_data, f)
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            with self.assertRaises(ValueError) as context:
                engine.load_strategy_config()
            
            error_msg = str(context.exception)
            self.assertIn("必須フィールドが見つかりません", error_msg)
            self.assertIn("meta.formatVersion", error_msg)
            self.assertIn("meta.generatedBy", error_msg)
            self.assertIn("meta.generatedAt", error_msg)
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_load_strategy_config_unsupported_format_version(self):
        """
        Test loading config with unsupported format version shows warning
        
        Tests Task 6.3: フォーマットバージョンの検証
        """
        config_data = {
            'meta': {
                'formatVersion': '2.0',  # Unsupported version
                'name': 'Test Strategy',
                'generatedBy': 'Test',
                'generatedAt': '2024-01-26T10:00:00Z'
            },
            'globalGuards': {},
            'strategies': [],
            'blocks': []
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config_data, f)
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            # Capture stderr to check for warning
            with patch('sys.stderr', new=StringIO()) as fake_err:
                engine.load_strategy_config()
                error_output = fake_err.getvalue()
            
            # Should load successfully but show warning
            self.assertIsNotNone(engine.strategy_config)
            self.assertIn("サポートされていないフォーマットバージョン", error_output)
            self.assertIn("2.0", error_output)
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_load_strategy_config_multiple_missing_fields(self):
        """
        Test loading config with multiple missing required fields
        
        Tests Task 6.3: 複数の必須フィールドが欠落している場合
        """
        # Missing strategies and blocks
        config_data = {
            'meta': {
                'formatVersion': '1.0',
                'name': 'Test Strategy',
                'generatedBy': 'Test',
                'generatedAt': '2024-01-26T10:00:00Z'
            },
            'globalGuards': {}
            # Missing 'strategies' and 'blocks'
        }
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(config_data, f)
            temp_config_path = f.name
        
        try:
            engine = BacktestEngine(
                config_path=temp_config_path,
                symbol=self.symbol,
                timeframe=self.timeframe,
                start_date=self.start_date,
                end_date=self.end_date,
                output_path=self.output_path
            )
            
            with self.assertRaises(ValueError) as context:
                engine.load_strategy_config()
            
            error_msg = str(context.exception)
            self.assertIn("必須フィールドが見つかりません", error_msg)
            self.assertIn("strategies", error_msg)
            self.assertIn("blocks", error_msg)
            
        finally:
            # Clean up
            os.unlink(temp_config_path)
    
    def test_calculate_max_drawdown_empty_trades(self):
        """Test max drawdown calculation with no trades"""
        engine = BacktestEngine(
            config_path=self.config_path,
            symbol=self.symbol,
            timeframe=self.timeframe,
            start_date=self.start_date,
            end_date=self.end_date,
            output_path=self.output_path
        )
        
        max_dd = engine.calculate_max_drawdown()
        self.assertEqual(max_dd, 0.0)
    
    def test_calculate_max_drawdown_with_trades(self):
        """Test max drawdown calculation with sample trades"""
        engine = BacktestEngine(
            config_path=self.config_path,
            symbol=self.symbol,
            timeframe=self.timeframe,
            start_date=self.start_date,
            end_date=self.end_date,
            output_path=self.output_path
        )
        
        # Add sample trades: +10, -5, +3, -8
        engine.trades = [
            {'profitLoss': 10.0},
            {'profitLoss': -5.0},
            {'profitLoss': 3.0},
            {'profitLoss': -8.0}
        ]
        
        # Cumulative: 10, 5, 8, 0
        # Peak: 10, 10, 10, 10
        # Drawdown: 0, 5, 2, 10
        # Max drawdown should be 10
        max_dd = engine.calculate_max_drawdown()
        self.assertEqual(max_dd, 10.0)


class TestArgumentParsing(unittest.TestCase):
    """Test command-line argument parsing"""
    
    @patch('backtest_engine.BacktestEngine')
    def test_main_with_valid_arguments(self, mock_engine_class):
        """Test main function with valid command-line arguments"""
        # Mock the engine instance
        mock_engine = MagicMock()
        mock_engine_class.return_value = mock_engine
        
        # Simulate command-line arguments
        test_args = [
            'backtest_engine.py',
            '--config', 'test_config.json',
            '--symbol', 'USDJPY',
            '--timeframe', 'M1',
            '--start', '2024-01-01T00:00:00Z',
            '--end', '2024-03-31T23:59:59Z',
            '--output', 'test_output.json'
        ]
        
        with patch.object(sys, 'argv', test_args):
            main()
        
        # Verify engine was created with correct arguments
        mock_engine_class.assert_called_once()
        call_args = mock_engine_class.call_args
        
        self.assertEqual(call_args.kwargs['config_path'], 'test_config.json')
        self.assertEqual(call_args.kwargs['symbol'], 'USDJPY')
        self.assertEqual(call_args.kwargs['timeframe'], 'M1')
        self.assertEqual(call_args.kwargs['output_path'], 'test_output.json')
        
        # Verify run was called
        mock_engine.run.assert_called_once()
    
    def test_main_with_invalid_date_format(self):
        """Test main function with invalid date format"""
        test_args = [
            'backtest_engine.py',
            '--config', 'test_config.json',
            '--symbol', 'USDJPY',
            '--timeframe', 'M1',
            '--start', 'invalid-date',
            '--end', '2024-03-31T23:59:59Z',
            '--output', 'test_output.json'
        ]
        
        with patch.object(sys, 'argv', test_args):
            with self.assertRaises(SystemExit) as context:
                main()
            
            # Should exit with error code 1
            self.assertEqual(context.exception.code, 1)


class TestMT5Initialization(unittest.TestCase):
    """
    Test MT5 initialization and connection error handling
    
    Tests for Task 6.2: MT5ライブラリの初期化と接続を実装
    Requirements: 4.1, 4.2
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
    def test_initialize_mt5_success(self, mock_mt5):
        """
        Test successful MT5 initialization
        
        Validates Requirement 4.1: MT5ライブラリへの接続を初期化
        """
        # Mock successful initialization
        mock_mt5.initialize.return_value = True
        mock_mt5.version.return_value = (500, 3456, '01 Jan 2024')
        
        # Mock terminal info
        mock_terminal_info = Mock()
        mock_terminal_info.name = "MetaTrader 5"
        mock_terminal_info.build = 3456
        mock_mt5.terminal_info.return_value = mock_terminal_info
        
        # Capture stdout
        with patch('sys.stdout', new=StringIO()) as fake_out:
            result = self.engine.initialize_mt5()
        
        # Verify initialization was called
        mock_mt5.initialize.assert_called_once()
        
        # Verify success
        self.assertTrue(result)
        
        # Verify version was retrieved
        mock_mt5.version.assert_called_once()
        
        # Verify success message was printed
        output = fake_out.getvalue()
        self.assertIn("MT5初期化成功", output)
        self.assertIn("バージョン", output)
    
    @patch('backtest_engine.mt5')
    def test_initialize_mt5_failure_with_error_code(self, mock_mt5):
        """
        Test MT5 initialization failure with error code
        
        Validates Requirement 4.2: 接続失敗時に説明的なエラーメッセージで終了
        """
        # Mock failed initialization
        mock_mt5.initialize.return_value = False
        mock_mt5.last_error.return_value = (1, "Terminal not running")
        
        # Capture stderr
        with patch('sys.stderr', new=StringIO()) as fake_err:
            result = self.engine.initialize_mt5()
        
        # Verify initialization was attempted
        mock_mt5.initialize.assert_called_once()
        
        # Verify failure
        self.assertFalse(result)
        
        # Verify error was retrieved
        mock_mt5.last_error.assert_called_once()
        
        # Verify error message was printed to stderr
        error_output = fake_err.getvalue()
        self.assertIn("MT5初期化失敗", error_output)
        self.assertIn("エラーコード 1", error_output)
        self.assertIn("Terminal not running", error_output)
        self.assertIn("MT5ターミナルが起動していることを確認してください", error_output)
    
    @patch('backtest_engine.mt5')
    def test_initialize_mt5_failure_without_error_details(self, mock_mt5):
        """
        Test MT5 initialization failure without detailed error information
        
        Validates Requirement 4.2: エラーハンドリングの堅牢性
        """
        # Mock failed initialization with no error details
        mock_mt5.initialize.return_value = False
        mock_mt5.last_error.return_value = None
        
        # Capture stderr
        with patch('sys.stderr', new=StringIO()) as fake_err:
            result = self.engine.initialize_mt5()
        
        # Verify failure
        self.assertFalse(result)
        
        # Verify error message handles missing error details gracefully
        error_output = fake_err.getvalue()
        self.assertIn("MT5初期化失敗", error_output)
        self.assertIn("Unknown", error_output)
    
    @patch('backtest_engine.mt5')
    def test_initialize_mt5_success_without_terminal_info(self, mock_mt5):
        """
        Test successful MT5 initialization when terminal info is unavailable
        
        Validates robustness of initialization process
        """
        # Mock successful initialization but no terminal info
        mock_mt5.initialize.return_value = True
        mock_mt5.version.return_value = (500, 3456, '01 Jan 2024')
        mock_mt5.terminal_info.return_value = None
        
        # Capture stdout
        with patch('sys.stdout', new=StringIO()) as fake_out:
            result = self.engine.initialize_mt5()
        
        # Verify success
        self.assertTrue(result)
        
        # Verify success message was printed (without terminal details)
        output = fake_out.getvalue()
        self.assertIn("MT5初期化成功", output)
        self.assertIn("バージョン", output)
    
    @patch('backtest_engine.mt5')
    def test_run_exits_on_mt5_initialization_failure(self, mock_mt5):
        """
        Test that run() method exits when MT5 initialization fails
        
        Validates Requirement 4.2: システムは接続失敗時に終了する
        """
        # Mock failed initialization
        mock_mt5.initialize.return_value = False
        mock_mt5.last_error.return_value = (1, "Connection failed")
        mock_mt5.shutdown = Mock()
        
        # Capture stderr
        with patch('sys.stderr', new=StringIO()):
            with self.assertRaises(SystemExit) as context:
                self.engine.run()
        
        # Verify exit code is 1 (error)
        self.assertEqual(context.exception.code, 1)
        
        # Verify MT5 shutdown was called
        mock_mt5.shutdown.assert_called()


if __name__ == '__main__':
    unittest.main()
