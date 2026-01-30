#!/bin/bash
# MT5 Strategy Tester - Automated Test Runner with Result Collection

set -e

# Configuration
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
MT5_PATH="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5"
TERMINAL="$MT5_PATH/terminal64.exe"
CONFIG_DIR="$MT5_PATH/config"
LOG_DIR="$MT5_PATH/Tester/Agent-127.0.0.1-3000/logs"
RESULTS_DIR="ea/tests/results"

# Test configurations (name|description)
TESTS=(
    "test_single_blocks|Single Block Unit Tests (32 strategies)"
    "test_single_blocks_extra|Single Block Unit Tests (extra, 2 strategies)"
    "active|Basic Strategy Test (1 strategy)"
    "test_strategy_advanced|Advanced Strategy Test (3 strategies)"
    "test_strategy_all_blocks|All Blocks Comprehensive Test (4 strategies)"
)

# Test order
TEST_ORDER=("test_single_blocks" "test_single_blocks_extra" "active" "test_strategy_advanced" "test_strategy_all_blocks")

get_test_desc() {
    local test_name=$1
    for test in "${TESTS[@]}"; do
        local name="${test%%|*}"
        local desc="${test##*|}"
        if [ "$name" = "$test_name" ]; then
            echo "$desc"
            return
        fi
    done
    echo "Unknown test"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo ""
    echo "============================================================"
    echo "$1"
    echo "============================================================"
    echo ""
}

print_section() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

check_prerequisites() {
    print_section "Checking Prerequisites"

    # Check wine
    if [ ! -f "$WINE" ]; then
        echo -e "${RED}❌ Wine not found: $WINE${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Wine found${NC}"

    # Check MT5
    if [ ! -f "$TERMINAL" ]; then
        echo -e "${RED}❌ MT5 terminal not found: $TERMINAL${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ MT5 terminal found${NC}"

    # Check config directory
    if [ ! -d "$CONFIG_DIR" ]; then
        echo -e "${RED}❌ Config directory not found: $CONFIG_DIR${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Config directory found${NC}"

    # Check results directory
    mkdir -p "$RESULTS_DIR"
    echo -e "${GREEN}✅ Results directory ready${NC}"
}

run_test() {
    local test_name=$1
    local test_desc=$2
    local config_file="$CONFIG_DIR/tester_${test_name}.ini"

    print_section "Running: $test_desc"

    # Check config file
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Config file not found: $config_file${NC}"
        return 1
    fi
    echo -e "${BLUE}📄 Config: tester_${test_name}.ini${NC}"

    # Get current date for log file
    local log_date
    log_date=$(date +%Y%m%d)
    local log_file="$LOG_DIR/${log_date}.log"

    # Clear previous log if exists
    if [ -f "$log_file" ]; then
        echo -e "${YELLOW}⚠️  Clearing previous log${NC}"
        > "$log_file"
    fi

    # Run MT5 tester
    echo -e "${BLUE}🚀 Starting MT5 Strategy Tester...${NC}"

    # Run in background and wait
    WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5" \
    "$WINE" "$TERMINAL" /config:"$config_file" &

    local mt5_pid=$!
    echo -e "${BLUE}   Process ID: $mt5_pid${NC}"

    # Wait for test to complete (check log file for completion)
    echo -e "${BLUE}⏳ テスト完了を待機中...${NC}"
    local wait_count=0
    local max_wait=600  # 10 minutes max

    while [ $wait_count -lt $max_wait ]; do
        sleep 10
        wait_count=$((wait_count + 10))

        # Check if process is still running
        if ! ps -p $mt5_pid > /dev/null 2>&1; then
            echo -e "${GREEN}✅ MT5プロセスが終了しました${NC}"
            break
        fi

        # Check if log file exists and has content
        if [ -f "$log_file" ]; then
            local log_size
            log_size=$(wc -c < "$log_file" 2>/dev/null || echo "0")

            # Check for completion indicators
            if grep -q "test finished" "$log_file" 2>/dev/null || \
               grep -q "testing stopped" "$log_file" 2>/dev/null || \
               grep -q "test completed" "$log_file" 2>/dev/null; then
                echo -e "${GREEN}✅ テスト完了${NC}"
                break
            fi

            # Show progress with log size
            if [ $((wait_count % 60)) -eq 0 ]; then
                echo -e "${BLUE}   実行中... (${wait_count}秒経過, ログサイズ: ${log_size} bytes)${NC}"
            fi
        else
            # Show progress without log
            if [ $((wait_count % 60)) -eq 0 ]; then
                echo -e "${BLUE}   実行中... (${wait_count}秒経過)${NC}"
            fi
        fi
    done

    # Kill MT5 process if still running
    if ps -p $mt5_pid > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  MT5プロセスを停止中${NC}"
        kill $mt5_pid 2>/dev/null || true
        sleep 2
    fi

    # Wait a bit for files to be written
    sleep 3

    # Parse results
    parse_test_results "$test_name" "$log_file"
}

parse_test_results() {
    local test_name=$1
    local log_file=$2

    print_section "結果解析中: $test_name"

    if [ ! -f "$log_file" ]; then
        echo -e "${RED}❌ ログファイルが見つかりません: $log_file${NC}"
        return 1
    fi

    local log_size
    log_size=$(wc -c < "$log_file" 2>/dev/null || echo "0")
    echo -e "${BLUE}📄 ログファイルサイズ: $log_size bytes${NC}"

    if [ "$log_size" -eq 0 ]; then
        echo -e "${RED}❌ ログファイルが空です - テストが実行されていない可能性があります${NC}"
        return 1
    fi

    # Extract key information
    local initialized=false
    local blocks_loaded=0
    local strategies_loaded=0
    local errors=0

    # Check initialization
    if grep -q "Strategy Bricks EA initialized successfully" "$log_file" 2>/dev/null; then
        initialized=true
        echo -e "${GREEN}✅ EA初期化成功${NC}"
    else
        echo -e "${RED}❌ EA初期化失敗${NC}"
    fi

    # Extract blocks loaded
    blocks_loaded=$(grep -o "Preloaded [0-9]* blocks" "$log_file" 2>/dev/null | grep -o "[0-9]*" | head -1 || echo "0")
    echo -e "${BLUE}📦 ロード済みブロック数: $blocks_loaded${NC}"

    # Extract strategies loaded
    strategies_loaded=$(grep -o "Strategies: [0-9]*" "$log_file" 2>/dev/null | grep -o "[0-9]*" | head -1 || echo "0")
    echo -e "${BLUE}🎯 ロード済み戦略数: $strategies_loaded${NC}"

    # Count errors
    errors=$(grep -c "ERROR\|error" "$log_file" 2>/dev/null || echo "0")
    if [ $errors -gt 0 ]; then
        echo -e "${RED}❌ エラー検出: $errors 件${NC}"
        echo -e "${YELLOW}   最初のエラー:${NC}"
        grep "ERROR\|error" "$log_file" 2>/dev/null | head -3 | sed 's/^/   /'
    else
        echo -e "${GREEN}✅ エラーなし${NC}"
    fi

    # Trade count is derived from MT5 report
    echo -e "${BLUE}📊 取引回数: (MT5レポートを確認)${NC}"

    # Save results
    local result_file="$RESULTS_DIR/${test_name}_result.txt"
    {
        echo "テスト: $test_name"
        echo "日時: $(date)"
        echo "初期化: $initialized"
        echo "ロード済みブロック数: $blocks_loaded"
        echo "ロード済み戦略数: $strategies_loaded"
        echo "エラー数: $errors"
        echo ""
        echo "ログファイル: $log_file"
    } > "$result_file"

    echo -e "${GREEN}💾 結果保存: $result_file${NC}"
}

generate_summary_report() {
    print_section "Generating Summary Report"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="$RESULTS_DIR/test_report_${timestamp}.txt"

    {
        echo "============================================================"
        echo "Strategy Bricks EA - Automated Test Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================================"
        echo ""
        echo "Test Period: 2025.10.01 - 2025.12.31 (3 months)"
        echo "Symbol: USDJPYm"
        echo "Timeframe: M1"
        echo "Deposit: 1,000,000 JPY"
        echo "Leverage: 1:100"
        echo ""
        echo "------------------------------------------------------------"
        echo "Test Results Summary"
        echo "------------------------------------------------------------"
        echo ""

        for test_name in "${TEST_ORDER[@]}"; do
            local result_file="$RESULTS_DIR/${test_name}_result.txt"
            if [ -f "$result_file" ]; then
                cat "$result_file"
                echo ""
            fi
        done

        echo "------------------------------------------------------------"
        echo "Next Steps"
        echo "------------------------------------------------------------"
        echo ""
        echo "1. Review individual test results above"
        echo "2. Check MT5 Tester reports for trade details"
        echo "3. If trades = 0, review strategy conditions"
        echo "4. If errors found, check block implementations"
        echo "5. Re-run specific tests after fixes"
        echo ""
        echo "============================================================"
    } > "$report_file"

    echo -e "${GREEN}📊 Summary report generated: $report_file${NC}"
    echo ""
    cat "$report_file"
}

main() {
    print_header "MT5 Strategy Tester - Automated Test Runner"

    # Check if specific test requested
    if [ $# -eq 1 ]; then
        local test_name=$1
        local test_desc
        test_desc=$(get_test_desc "$test_name")

        if [ "$test_desc" != "Unknown test" ]; then
            check_prerequisites
            run_test "$test_name" "$test_desc"
            exit 0
        else
            echo -e "${RED}❌ Unknown test: $test_name${NC}"
            echo ""
            echo "Available tests:"
            for test in "${TESTS[@]}"; do
                local name="${test%%|*}"
                local desc="${test##*|}"
                echo "  - $name: $desc"
            done
            exit 1
        fi
    fi

    # Run all tests
    check_prerequisites

    for test_name in "${TEST_ORDER[@]}"; do
        local test_desc
        test_desc=$(get_test_desc "$test_name")
        run_test "$test_name" "$test_desc"
        echo ""
        sleep 3  # Brief pause between tests
    done

    # Generate summary
    generate_summary_report

    print_header "All Tests Completed"
    echo -e "${GREEN}✅ Test execution finished${NC}"
    echo -e "${BLUE}📁 Results directory: $RESULTS_DIR${NC}"
    echo ""
}

# Run main
main "$@"
