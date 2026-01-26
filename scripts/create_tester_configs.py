#!/usr/bin/env python3
"""
MT5 Strategy Tester Configuration Generator
ストラテジーテスター用の設定ファイルを生成
"""

import os
from pathlib import Path

MT5_BASE = Path.home() / "Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5"
CONFIG_DIR = MT5_BASE / "config"
TESTER_DIR = MT5_BASE / "Tester"

# テスト設定
TEST_CONFIGS = [
    {
        "name": "test_single_blocks",
        "config_file": "strategy/test_single_blocks.json",
        "description": "Single Block Unit Tests"
    },
    {
        "name": "active",
        "config_file": "strategy/active.json",
        "description": "Basic Strategy Test"
    },
    {
        "name": "test_strategy_advanced",
        "config_file": "strategy/test_strategy_advanced.json",
        "description": "Advanced Strategy Test"
    },
    {
        "name": "test_strategy_all_blocks",
        "config_file": "strategy/test_strategy_all_blocks.json",
        "description": "All Blocks Comprehensive Test"
    }
]

# ストラテジーテスター設定テンプレート
TESTER_INI_TEMPLATE = """[Tester]
Expert=Experts\\StrategyBricks\\StrategyBricks.ex5
ExpertParameters=InpConfigPath={config_file}
Symbol=USDJPYm
Period=1
Model=0
ExecutionMode=0
Optimization=0
OptimizationCriterion=0
FromDate=2025.10.01
ToDate=2025.12.31
ForwardMode=0
ForwardDate=2025.12.31
Report=tester_report_{name}
ReplaceReport=1
ShutdownTerminal=0
Deposit=1000000
Currency=JPY
Leverage=100
"""

def create_tester_configs():
    """ストラテジーテスター用の設定ファイルを生成"""
    
    print("=" * 60)
    print("MT5 Strategy Tester Configuration Generator")
    print("=" * 60)
    
    if not CONFIG_DIR.exists():
        print(f"\n❌ Config directory not found: {CONFIG_DIR}")
        return False
    
    print(f"\n✅ Config directory: {CONFIG_DIR}")
    
    # 各テスト用の設定ファイルを生成
    for test in TEST_CONFIGS:
        config_name = f"tester_{test['name']}.ini"
        config_path = CONFIG_DIR / config_name
        
        # 設定ファイル内容を生成
        config_content = TESTER_INI_TEMPLATE.format(
            config_file=test['config_file'],
            name=test['name']
        )
        
        # ファイルに書き込み
        with open(config_path, 'w', encoding='utf-8') as f:
            f.write(config_content)
        
        print(f"\n✅ Created: {config_name}")
        print(f"   Description: {test['description']}")
        print(f"   Config file: {test['config_file']}")
    
    print(f"\n{'=' * 60}")
    print("Configuration files created successfully!")
    print(f"{'=' * 60}")
    
    return True

def generate_run_script():
    """テスト実行スクリプトを生成"""
    
    script_path = Path("scripts/run_mt5_tester.sh")
    
    script_content = """#!/bin/bash
# MT5 Strategy Tester Automated Runner

MT5_PATH="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5"
TERMINAL="$MT5_PATH/terminal64.exe"

echo "============================================================"
echo "MT5 Strategy Tester - Automated Test Runner"
echo "============================================================"
echo ""

# テスト設定
TESTS=(
    "test_single_blocks:Single Block Unit Tests"
    "active:Basic Strategy Test"
    "test_strategy_advanced:Advanced Strategy Test"
    "test_strategy_all_blocks:All Blocks Comprehensive Test"
)

for test_info in "${TESTS[@]}"; do
    IFS=':' read -r test_name test_desc <<< "$test_info"
    
    echo "------------------------------------------------------------"
    echo "Running: $test_desc"
    echo "Config: tester_${test_name}.ini"
    echo "------------------------------------------------------------"
    
    # MT5をストラテジーテスターモードで起動
    # Note: Wineを使用している場合は wine コマンドが必要
    wine "$TERMINAL" /config:"$MT5_PATH/config/tester_${test_name}.ini" /tester
    
    # テスト完了を待つ
    echo "Test started. Waiting for completion..."
    sleep 5
    
    echo ""
done

echo "============================================================"
echo "All tests queued. Check MT5 Tester for results."
echo "============================================================"
"""
    
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    # 実行権限を付与
    os.chmod(script_path, 0o755)
    
    print(f"\n✅ Created run script: {script_path}")

def main():
    """メイン処理"""
    
    # 設定ファイル生成
    if create_tester_configs():
        # 実行スクリプト生成
        generate_run_script()
        
        print("\n" + "=" * 60)
        print("Next Steps:")
        print("=" * 60)
        print("\n1. Run tests:")
        print("   bash scripts/run_mt5_tester.sh")
        print("\n2. Or run individual test:")
        print("   wine \"$MT5_PATH/terminal64.exe\" /config:\"$MT5_PATH/config/tester_test_single_blocks.ini\" /tester")
        print("\n3. Check results in:")
        print("   $MT5_PATH/Tester/")
        print("\n" + "=" * 60)
        
        return 0
    else:
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
