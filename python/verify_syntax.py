#!/usr/bin/env python3
"""
Simple syntax verification script
"""
import sys
import py_compile

files_to_check = [
    'backtest_engine.py',
    'test_backtest_engine_basic.py'
]

print("Checking Python syntax...")
all_ok = True

for filename in files_to_check:
    try:
        py_compile.compile(filename, doraise=True)
        print(f"[OK] {filename} - Syntax OK")
    except py_compile.PyCompileError as e:
        print(f"[ERROR] {filename} - Syntax Error:")
        print(f"  {e}")
        all_ok = False

if all_ok:
    print("\n[OK] All files have valid Python syntax")
    sys.exit(0)
else:
    print("\n[ERROR] Some files have syntax errors")
    sys.exit(1)
