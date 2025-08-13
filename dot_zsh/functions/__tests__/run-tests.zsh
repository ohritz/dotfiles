#!/usr/bin/env zsh
# Test Runner for Function Split Project
# Run all tests or specific test suites

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Function Split Project - Test Runner${NC}"
echo "=============================================="
echo

# Function to run a test suite
run_test() {
    local test_name="$1"
    local test_file="$2"

    echo -e "${BLUE}Running $test_name...${NC}"
    echo "----------------------------------------------"

    if [[ -f "$test_file" ]]; then
        if ./"$test_file"; then
            echo -e "${GREEN}✅ $test_name passed${NC}"
            echo
            return 0
        else
            echo -e "❌ $test_name failed"
            echo
            return 1
        fi
    else
        echo "❌ Test file not found: $test_file"
        echo
        return 1
    fi
}

# Parse command line arguments
case "${1:-all}" in
    "quick"|"q")
        run_test "Quick Test Suite" "quick-test.zsh"
        ;;
    "integration"|"i")
        run_test "Integration Test Suite" "integration-test.zsh"
        ;;
    "full"|"f")
        run_test "Full Test Suite" "test-suite.zsh"
        ;;
    "all"|"a")
        echo "Running all test suites..."
        echo

        # Run quick test first
        if run_test "Quick Test Suite" "quick-test.zsh"; then
            # Run integration test
            if run_test "Integration Test Suite" "integration-test.zsh"; then
                # Run full test suite
                run_test "Full Test Suite" "test-suite.zsh"
            fi
        fi
        ;;
    "help"|"h"|"-h"|"--help")
        echo "Usage: $0 [test_type]"
        echo
        echo "Test types:"
        echo "  quick, q      - Run quick validation test"
        echo "  integration, i - Run integration test"
        echo "  full, f       - Run comprehensive test suite"
        echo "  all, a        - Run all tests (default)"
        echo "  help, h       - Show this help"
        echo
        echo "Examples:"
        echo "  $0 quick      - Run quick test only"
        echo "  $0 integration - Run integration test only"
        echo "  $0            - Run all tests"
        ;;
    *)
        echo "Unknown test type: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Test runner completed!${NC}"
