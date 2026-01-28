#!/usr/bin/env python3
"""
Strategy Bricks EA - Test Configuration Validator
テスト設定ファイルの妥当性を検証する
"""

import json
import sys
from pathlib import Path

# BlockRegistryに登録されているブロックタイプ
REGISTERED_BLOCKS = {
    # Filter
    "filter.spreadMax",
    "filter.volatility.atrRange",
    "filter.volatility.stddevRange",
    "filter.session.timeWindow",
    "filter.session.daysOfWeek",
    # Env (legacy support)
    "env.session.timeWindow",  # Alias for filter.session.timeWindow
    # Trend
    "trend.maRelation",
    "trend.maCross",
    "trend.adxThreshold",
    "trend.ichimokuCloud",
    "trend.sarDirection",
    # Trigger
    "trigger.bbReentry",
    "trigger.bbBreakout",
    "trigger.macdCross",
    "trigger.stochCross",
    "trigger.rsiLevel",
    "trigger.cciLevel",
    "trigger.sarFlip",
    "trigger.wprLevel",
    "trigger.mfiLevel",
    "trigger.rviCross",
    # Osc
    "osc.momentum",
    "osc.osma",
    "osc.forceIndex",
    # Volume
    "volume.obvTrend",
    # Bill
    "bill.fractals",
    "bill.alligator",
    # Models
    "lot.fixed",
    "lot.riskPercent",
    "risk.fixedSLTP",
    "risk.atrBased",
    "exit.none",
    "exit.trail",
    "exit.breakEven",
    "exit.weekendClose",
    "nanpin.off",
    "nanpin.fixed",
}

def validate_config(filepath):
    """設定ファイルを検証"""
    print(f"\n{'='*60}")
    print(f"Validating: {filepath.name}")
    print(f"{'='*60}")
    
    errors = []
    warnings = []
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: JSON Parse Error: {e}")
        return False
    except Exception as e:
        print(f"ERROR: File Read Error: {e}")
        return False
    
    # メタ情報確認
    meta = data.get('meta', {})
    print(f"\nMeta Information:")
    print(f"  Format Version: {meta.get('formatVersion', 'N/A')}")
    print(f"  Name: {meta.get('name', 'N/A')}")
    
    # 戦略確認
    strategies = data.get('strategies', [])
    print(f"\nStrategies: {len(strategies)}")
    
    if len(strategies) == 0:
        errors.append("No strategies defined")
    
    for i, strat in enumerate(strategies, 1):
        strat_id = strat.get('id', f'strategy_{i}')
        print(f"\n  {i}. {strat_id}")
        print(f"     Enabled: {strat.get('enabled', False)}")
        print(f"     Direction: {strat.get('directionPolicy', 'N/A')}")
        
        # エントリー条件確認
        entry_req = strat.get('entryRequirement', {})
        rule_groups = entry_req.get('ruleGroups', [])
        
        total_conditions = 0
        for rg in rule_groups:
            conditions = rg.get('conditions', [])
            total_conditions += len(conditions)
        
        print(f"     Conditions: {total_conditions}")
        
        # モデル確認
        lot_model = strat.get('lotModel', {})
        risk_model = strat.get('riskModel', {})
        exit_model = strat.get('exitModel', {})
        nanpin_model = strat.get('nanpinModel', {})
        
        print(f"     Lot: {lot_model.get('type', 'N/A')}")
        print(f"     Risk: {risk_model.get('type', 'N/A')}")
        print(f"     Exit: {exit_model.get('type', 'N/A')}")
        print(f"     Nanpin: {nanpin_model.get('type', 'N/A')}")
        
        # モデルタイプ検証
        for model_name, model in [
            ('lotModel', lot_model),
            ('riskModel', risk_model),
            ('exitModel', exit_model),
            ('nanpinModel', nanpin_model)
        ]:
            model_type = model.get('type')
            if model_type and model_type not in REGISTERED_BLOCKS:
                errors.append(f"Strategy '{strat_id}': Unknown {model_name} type '{model_type}'")
    
    # ブロック確認
    blocks = data.get('blocks', [])
    print(f"\nBlocks: {len(blocks)}")
    
    if len(blocks) == 0:
        warnings.append("No blocks defined")
    
    block_ids = set()
    for i, block in enumerate(blocks, 1):
        block_id = block.get('id', f'block_{i}')
        type_id = block.get('typeId', 'N/A')
        
        # 重複ID確認
        if block_id in block_ids:
            errors.append(f"Duplicate block ID: {block_id}")
        block_ids.add(block_id)
        
        # typeId検証
        if type_id not in REGISTERED_BLOCKS:
            errors.append(f"Block '{block_id}': Unknown typeId '{type_id}'")
        
        print(f"  {i:2d}. {block_id:40s} ({type_id})")
    
    # 参照整合性確認
    print(f"\nReference Validation:")
    referenced_blocks = set()
    
    for strat in strategies:
        entry_req = strat.get('entryRequirement', {})
        rule_groups = entry_req.get('ruleGroups', [])
        
        for rg in rule_groups:
            conditions = rg.get('conditions', [])
            for cond in conditions:
                block_id = cond.get('blockId')
                if block_id:
                    referenced_blocks.add(block_id)
    
    # 未定義ブロック参照確認
    undefined_blocks = referenced_blocks - block_ids
    if undefined_blocks:
        for block_id in undefined_blocks:
            errors.append(f"Referenced but not defined: {block_id}")
    
    # 未使用ブロック確認
    unused_blocks = block_ids - referenced_blocks
    if unused_blocks:
        for block_id in unused_blocks:
            warnings.append(f"Defined but not used: {block_id}")
    
    print(f"  Referenced blocks: {len(referenced_blocks)}")
    print(f"  Defined blocks: {len(block_ids)}")
    print(f"  Undefined references: {len(undefined_blocks)}")
    print(f"  Unused blocks: {len(unused_blocks)}")
    
    # 結果表示
    print(f"\n{'='*60}")
    if errors:
        print(f"VALIDATION FAILED")
        print(f"\nErrors ({len(errors)}):")
        for error in errors:
            print(f"  - {error}")
    else:
        print(f"VALIDATION PASSED")
    
    if warnings:
        print(f"\nWarnings ({len(warnings)}):")
        for warning in warnings:
            print(f"  - {warning}")
    
    print(f"{'='*60}\n")
    
    return len(errors) == 0


def main():
    """メイン処理"""
    test_dir = Path("ea/tests")
    
    test_files = [
        test_dir / "active.json",
        test_dir / "test_single_blocks.json",
        test_dir / "test_single_blocks_extra.json",
        test_dir / "test_strategy_advanced.json",
        test_dir / "test_strategy_all_blocks.json",
    ]
    
    print("Strategy Bricks EA - Test Configuration Validator")
    print("="*60)
    
    all_valid = True
    for test_file in test_files:
        if not test_file.exists():
            print(f"\nERROR: File not found: {test_file}")
            all_valid = False
            continue
        
        if not validate_config(test_file):
            all_valid = False
    
    # 最終結果
    print("\n" + "="*60)
    if all_valid:
        print("ALL CONFIGURATIONS VALID")
        print("="*60)
        return 0
    else:
        print("SOME CONFIGURATIONS HAVE ERRORS")
        print("="*60)
        return 1


if __name__ == "__main__":
    sys.exit(main())
