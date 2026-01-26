#!/usr/bin/env python3
"""
MT5テスト結果記録ツール
手動テスト実行後の結果を対話的に記録
"""

import json
from datetime import datetime
from pathlib import Path

RESULTS_DIR = Path("ea/tests/results")

TESTS = [
    {
        "name": "test_single_blocks",
        "description": "単体ブロックテスト (27戦略)",
        "expected_strategies": 27,
        "expected_trades": "50-200 (各戦略)"
    },
    {
        "name": "active",
        "description": "基本戦略テスト (1戦略)",
        "expected_strategies": 1,
        "expected_trades": "10-50"
    },
    {
        "name": "test_strategy_advanced",
        "description": "高度な戦略テスト (3戦略)",
        "expected_strategies": 3,
        "expected_trades": "5-30 (各戦略)"
    },
    {
        "name": "test_strategy_all_blocks",
        "description": "全ブロック網羅テスト (4戦略)",
        "expected_strategies": 4,
        "expected_trades": "3-20 (各戦略)"
    }
]


def get_input(prompt, default=None):
    """ユーザー入力を取得"""
    if default:
        prompt = f"{prompt} [{default}]: "
    else:
        prompt = f"{prompt}: "
    
    value = input(prompt).strip()
    return value if value else default


def get_yes_no(prompt):
    """Yes/No入力を取得"""
    while True:
        value = input(f"{prompt} (y/n): ").strip().lower()
        if value in ['y', 'yes', 'はい']:
            return True
        elif value in ['n', 'no', 'いいえ']:
            return False
        print("y または n を入力してください")


def record_test_result(test_info):
    """テスト結果を記録"""
    print("\n" + "=" * 60)
    print(f"テスト: {test_info['description']}")
    print("=" * 60)
    print(f"期待される戦略数: {test_info['expected_strategies']}")
    print(f"期待される取引回数: {test_info['expected_trades']}")
    print()
    
    result = {
        "test_name": test_info["name"],
        "description": test_info["description"],
        "timestamp": datetime.now().isoformat(),
        "expected_strategies": test_info["expected_strategies"],
        "expected_trades": test_info["expected_trades"]
    }
    
    # 初期化
    result["initialized"] = get_yes_no("EA初期化は成功しましたか？")
    
    if result["initialized"]:
        # ブロック数
        blocks = get_input("ロードされたブロック数", "0")
        result["blocks_loaded"] = int(blocks) if blocks.isdigit() else 0
        
        # 戦略数
        strategies = get_input("ロードされた戦略数", "0")
        result["strategies_loaded"] = int(strategies) if strategies.isdigit() else 0
        
        # 取引回数
        trades = get_input("総取引回数", "0")
        result["total_trades"] = int(trades) if trades.isdigit() else 0
        
        # エラー
        result["has_errors"] = get_yes_no("エラーがありましたか？")
        
        if result["has_errors"]:
            errors = get_input("エラーメッセージ (簡潔に)")
            result["error_message"] = errors
        
        # ステータス判定
        if result["has_errors"]:
            result["status"] = "FAIL"
        elif result["total_trades"] == 0:
            result["status"] = "WARNING"
        else:
            result["status"] = "PASS"
    else:
        result["status"] = "FAIL"
        result["blocks_loaded"] = 0
        result["strategies_loaded"] = 0
        result["total_trades"] = 0
        result["has_errors"] = True
        errors = get_input("初期化失敗の理由")
        result["error_message"] = errors
    
    # メモ
    notes = get_input("その他メモ (任意)", "")
    if notes:
        result["notes"] = notes
    
    return result


def generate_summary_report(results):
    """サマリーレポートを生成"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # テキストレポート
    report_file = RESULTS_DIR / f"manual_test_report_{timestamp}.txt"
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("=" * 60 + "\n")
        f.write("Strategy Bricks EA - 手動テスト結果レポート\n")
        f.write(f"作成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 60 + "\n\n")
        
        f.write("テスト期間: 2025.10.01 - 2025.12.31 (3ヶ月)\n")
        f.write("シンボル: USDJPYm\n")
        f.write("タイムフレーム: M1\n")
        f.write("証拠金: 1,000,000 JPY\n")
        f.write("レバレッジ: 1:100\n\n")
        
        f.write("-" * 60 + "\n")
        f.write("テスト結果サマリー\n")
        f.write("-" * 60 + "\n\n")
        
        pass_count = 0
        warning_count = 0
        fail_count = 0
        
        for result in results:
            status_icon = {
                "PASS": "✅",
                "WARNING": "⚠️",
                "FAIL": "❌"
            }.get(result["status"], "❓")
            
            f.write(f"{status_icon} {result['description']}\n")
            f.write(f"   ステータス: {result['status']}\n")
            f.write(f"   初期化: {'成功' if result['initialized'] else '失敗'}\n")
            f.write(f"   ブロック数: {result.get('blocks_loaded', 0)}\n")
            f.write(f"   戦略数: {result.get('strategies_loaded', 0)}\n")
            f.write(f"   取引回数: {result.get('total_trades', 0)}\n")
            
            if result.get('has_errors'):
                f.write(f"   エラー: {result.get('error_message', '不明')}\n")
            
            if result.get('notes'):
                f.write(f"   メモ: {result['notes']}\n")
            
            f.write("\n")
            
            # カウント
            if result["status"] == "PASS":
                pass_count += 1
            elif result["status"] == "WARNING":
                warning_count += 1
            elif result["status"] == "FAIL":
                fail_count += 1
        
        f.write("-" * 60 + "\n")
        f.write("総合評価\n")
        f.write("-" * 60 + "\n\n")
        f.write(f"✅ PASS: {pass_count} / {len(results)}\n")
        f.write(f"⚠️  WARNING: {warning_count} / {len(results)}\n")
        f.write(f"❌ FAIL: {fail_count} / {len(results)}\n\n")
        
        if fail_count > 0:
            f.write("【次のアクション】\n")
            f.write("1. 失敗したテストのログを確認\n")
            f.write("2. エラーメッセージから原因を特定\n")
            f.write("3. 該当ブロックの実装を修正\n")
            f.write("4. 再テスト実行\n\n")
        elif warning_count > 0:
            f.write("【次のアクション】\n")
            f.write("1. 取引が0回の戦略を確認\n")
            f.write("2. 戦略条件が厳しすぎないか検証\n")
            f.write("3. 必要に応じてパラメータ調整\n\n")
        else:
            f.write("【結果】\n")
            f.write("すべてのテストが成功しました！\n\n")
        
        f.write("=" * 60 + "\n")
    
    # JSONレポート
    json_file = RESULTS_DIR / f"manual_test_report_{timestamp}.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump({
            "timestamp": timestamp,
            "test_period": "2025.10.01 - 2025.12.31",
            "symbol": "USDJPYm",
            "timeframe": "M1",
            "results": results,
            "summary": {
                "pass": pass_count,
                "warning": warning_count,
                "fail": fail_count,
                "total": len(results)
            }
        }, f, indent=2, ensure_ascii=False)
    
    return report_file, json_file


def main():
    """メイン処理"""
    print("=" * 60)
    print("MT5 テスト結果記録ツール")
    print("=" * 60)
    print()
    print("手動でMT5ストラテジーテスターを実行した結果を記録します。")
    print("各テストについて質問に答えてください。")
    print()
    
    # 結果ディレクトリ作成
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    
    results = []
    
    for test_info in TESTS:
        if get_yes_no(f"\n{test_info['description']} を実行しましたか？"):
            result = record_test_result(test_info)
            results.append(result)
        else:
            print(f"スキップ: {test_info['description']}")
    
    if not results:
        print("\n記録する結果がありません。")
        return 0
    
    # レポート生成
    print("\n" + "=" * 60)
    print("レポート生成中...")
    print("=" * 60)
    
    report_file, json_file = generate_summary_report(results)
    
    print(f"\n✅ レポート生成完了:")
    print(f"   - {report_file}")
    print(f"   - {json_file}")
    print()
    
    # レポート表示
    with open(report_file, 'r', encoding='utf-8') as f:
        print(f.read())
    
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
