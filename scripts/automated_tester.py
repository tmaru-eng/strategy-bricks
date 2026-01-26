#!/usr/bin/env python3
"""
Strategy Bricks EA - Automated Strategy Tester
MT5のストラテジーテスターを自動実行し、結果を収集する
"""

import os
import sys
import time
import json
import subprocess
from pathlib import Path
from datetime import datetime

# 設定
BOTTLE_PATH = Path.home() / "Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_DIR = BOTTLE_PATH / "drive_c/Program Files/MetaTrader 5"
TESTER_DIR = MT5_DIR / "Tester"
TESTER_FILES = TESTER_DIR / "Agent-127.0.0.1-3000/Files/strategy"
RESULTS_DIR = Path("ea/tests/results")

# テスト設定
TEST_CONFIGS = [
    "active.json",
    "test_single_blocks.json",
    "test_strategy_advanced.json",
    "test_strategy_all_blocks.json"
]

TEST_PARAMS = {
    "symbol": "USDJPYm",
    "timeframe": "M1",
    "start_date": "2025.10.01",
    "end_date": "2025.12.31",
    "deposit": 1000000,
    "leverage": 100
}


def create_results_dir():
    """結果ディレクトリを作成"""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    print(f"✅ Results directory: {RESULTS_DIR}")


def check_config_files():
    """設定ファイルの存在確認"""
    print("\n📋 Checking configuration files...")
    missing = []
    for config in TEST_CONFIGS:
        config_path = TESTER_FILES / config
        if config_path.exists():
            size = config_path.stat().st_size
            print(f"  ✅ {config} ({size} bytes)")
        else:
            print(f"  ❌ {config} (NOT FOUND)")
            missing.append(config)
    
    if missing:
        print(f"\n⚠️  Missing config files: {', '.join(missing)}")
        return False
    return True


def parse_tester_log(log_path):
    """テスターログを解析"""
    if not log_path.exists():
        return None
    
    result = {
        "initialized": False,
        "trades": 0,
        "errors": [],
        "warnings": [],
        "blocks_loaded": 0,
        "strategies_loaded": 0
    }
    
    try:
        with open(log_path, 'r', encoding='utf-16-le', errors='ignore') as f:
            content = f.read()
            
            # 初期化成功を確認
            if "Strategy Bricks EA initialized successfully" in content:
                result["initialized"] = True
            
            # ブロック数を抽出
            if "Preloaded" in content:
                for line in content.split('\n'):
                    if "Preloaded" in line and "blocks" in line:
                        try:
                            result["blocks_loaded"] = int(line.split("Preloaded")[1].split("blocks")[0].strip())
                        except:
                            pass
            
            # 戦略数を抽出
            if "Strategies:" in content:
                for line in content.split('\n'):
                    if "Strategies:" in line:
                        try:
                            result["strategies_loaded"] = int(line.split("Strategies:")[1].split(",")[0].strip())
                        except:
                            pass
            
            # エラーを抽出
            for line in content.split('\n'):
                if "ERROR" in line or "error" in line:
                    result["errors"].append(line.strip())
                if "WARNING" in line or "warning" in line:
                    result["warnings"].append(line.strip())
    
    except Exception as e:
        print(f"  ⚠️  Error parsing log: {e}")
    
    return result


def generate_test_report(results):
    """テスト結果レポートを生成"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = RESULTS_DIR / f"test_report_{timestamp}.txt"
    json_file = RESULTS_DIR / f"test_report_{timestamp}.json"
    
    # テキストレポート
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("=" * 60 + "\n")
        f.write("Strategy Bricks EA - Automated Test Report\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 60 + "\n\n")
        
        f.write(f"Test Period: {TEST_PARAMS['start_date']} - {TEST_PARAMS['end_date']}\n")
        f.write(f"Symbol: {TEST_PARAMS['symbol']}\n")
        f.write(f"Timeframe: {TEST_PARAMS['timeframe']}\n")
        f.write(f"Initial Deposit: {TEST_PARAMS['deposit']} JPY\n")
        f.write(f"Leverage: 1:{TEST_PARAMS['leverage']}\n\n")
        
        f.write("-" * 60 + "\n")
        f.write("Test Results Summary\n")
        f.write("-" * 60 + "\n\n")
        
        for config_name, result in results.items():
            f.write(f"📄 {config_name}\n")
            f.write(f"  Status: {'✅ PASS' if result['initialized'] else '❌ FAIL'}\n")
            f.write(f"  Initialized: {result['initialized']}\n")
            f.write(f"  Blocks Loaded: {result['blocks_loaded']}\n")
            f.write(f"  Strategies Loaded: {result['strategies_loaded']}\n")
            f.write(f"  Trades: {result['trades']}\n")
            f.write(f"  Errors: {len(result['errors'])}\n")
            f.write(f"  Warnings: {len(result['warnings'])}\n")
            
            if result['errors']:
                f.write(f"\n  ⚠️  Errors:\n")
                for error in result['errors'][:5]:  # 最初の5件のみ
                    f.write(f"    - {error}\n")
            
            f.write("\n")
        
        f.write("-" * 60 + "\n")
        f.write("Verification Criteria\n")
        f.write("-" * 60 + "\n\n")
        f.write("✅ PASS: 初期化成功 + エラーなし + 取引回数 > 0\n")
        f.write("⚠️  WARNING: 初期化成功 + 取引回数0 (条件が厳しすぎる可能性)\n")
        f.write("❌ FAIL: 初期化失敗 or エラーあり\n\n")
        f.write("注: 3ヶ月のテスト期間で取引0回は条件見直しが必要\n\n")
        
        f.write("=" * 60 + "\n")
    
    # JSONレポート
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump({
            "timestamp": timestamp,
            "test_params": TEST_PARAMS,
            "results": results
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n📊 Test report generated:")
    print(f"  - {report_file}")
    print(f"  - {json_file}")
    
    return report_file


def print_manual_instructions():
    """手動テスト手順を表示"""
    print("\n" + "=" * 60)
    print("Manual Testing Instructions")
    print("=" * 60)
    print("\nMT5のストラテジーテスターは自動化が困難なため、")
    print("以下の手順で手動テストを実行してください：\n")
    
    for i, config in enumerate(TEST_CONFIGS, 1):
        print(f"{i}. {config} のテスト:")
        print(f"   a. MT5を起動")
        print(f"   b. ツール > ストラテジーテスター を開く")
        print(f"   c. EA: Experts\\StrategyBricks\\StrategyBricks.ex5")
        print(f"   d. シンボル: {TEST_PARAMS['symbol']}")
        print(f"   e. 期間: {TEST_PARAMS['timeframe']}")
        print(f"   f. 日付: {TEST_PARAMS['start_date']} - {TEST_PARAMS['end_date']}")
        print(f"   g. 入力パラメータ: InpConfigPath=strategy/{config}")
        print(f"   h. テスト開始")
        print(f"   i. 結果を確認:")
        print(f"      - 初期化: 成功/失敗")
        print(f"      - 取引回数: 記録")
        print(f"      - エラー: 有無")
        print()
    
    print("=" * 60)
    print("\n各テストの期待結果:")
    print(f"  - {TEST_CONFIGS[0]}: 基本戦略、取引 10-50回")
    print(f"  - {TEST_CONFIGS[1]}: 単体ブロックテスト、取引 50-200回 (27戦略)")
    print(f"  - {TEST_CONFIGS[2]}: 高度な戦略、取引 5-30回")
    print(f"  - {TEST_CONFIGS[3]}: 全ブロック、取引 3-20回")
    print("\n3ヶ月のテスト期間で取引が0回の場合は条件が厳しすぎる可能性があります")
    print("単体ブロックテストで取引が発生しない場合は、そのブロックに問題がある可能性があります")
    print("=" * 60)


def main():
    """メイン処理"""
    print("=" * 60)
    print("Strategy Bricks EA - Automated Strategy Tester")
    print("=" * 60)
    
    # 結果ディレクトリ作成
    create_results_dir()
    
    # 設定ファイル確認
    if not check_config_files():
        print("\n❌ Some configuration files are missing.")
        print("Please ensure all test config files are in:")
        print(f"  {TESTER_FILES}")
        return 1
    
    # 手動テスト手順を表示
    print_manual_instructions()
    
    # テスト結果の雛形を作成
    results = {}
    for config in TEST_CONFIGS:
        results[config] = {
            "initialized": False,
            "trades": 0,
            "errors": [],
            "warnings": [],
            "blocks_loaded": 0,
            "strategies_loaded": 0
        }
    
    # レポート生成（手動入力用のテンプレート）
    report_file = generate_test_report(results)
    
    print(f"\n✅ Test preparation completed")
    print(f"\n📝 After manual testing, update the results in:")
    print(f"   {report_file}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
