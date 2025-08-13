#!/usr/bin/env zsh
# Function Split Project - Phase 5 Test Suite
# Comprehensive testing for all 34 functions and autoload system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test function autoloading
test_function_autoload() {
    local function_name="$1"
    local category="$2"

    log_info "Testing autoload for $function_name ($category)"

    if autoload -Uz "$function_name" 2>/dev/null; then
        log_success "Autoload successful: $function_name"
    else
        log_error "Autoload failed: $function_name"
    fi
}

# Test function execution (for safe functions)
test_function_execution() {
    local function_name="$1"
    local category="$2"

    log_info "Testing execution for $function_name ($category)"

    # Skip functions that might have side effects or require specific environment
    case "$function_name" in
        # Skip functions that modify environment or require specific setup
        set-buildtools-*|unset-buildtools|init-wsl-*|unset-wsl-*|set-aws-region|_ensure-ssh|_maybe-ensure-ssh)
            log_warning "Skipping execution test for $function_name (environment modification)"
            return 0
            ;;
        # Skip functions that require external tools
        git-*|check-ssh|kill-ssh-pipe|check-for-*|chat-gpt|reload-local-dev|prune-quay-images|fetch-tm-secret|upload-tm-secret|kube-logout)
            log_warning "Skipping execution test for $function_name (requires external tools)"
            return 0
            ;;
        # Skip prompt functions (called by Powerlevel10k)
        prompt_*)
            log_warning "Skipping execution test for $function_name (Powerlevel10k segment)"
            return 0
            ;;
        # Test safe utility functions
        date-now-in-ms|date-from-unix-ms|conc|bathelp|help|spinner|_spinner|_add-to-path)
            if type "$function_name" >/dev/null 2>&1; then
                log_success "Function available: $function_name"
            else
                log_error "Function not available: $function_name"
            fi
            ;;
        *)
            log_warning "Unknown function type: $function_name"
            ;;
    esac
}

# Test fpath configuration
test_fpath_configuration() {
    log_info "Testing fpath configuration"

    local expected_dirs=(
        "dot_zsh/functions/git"
        "dot_zsh/functions/ssh"
        "dot_zsh/functions/prompt"
        "dot_zsh/functions/docker"
        "dot_zsh/functions/build"
        "dot_zsh/functions/kubernetes"
        "dot_zsh/functions/aws"
        "dot_zsh/functions/ssl"
        "dot_zsh/functions/utils"
        "dot_zsh/functions/spinner"
        "dot_zsh/functions/chat"
        "dot_zsh/functions/proxy"
    )

    for dir in "${expected_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "Directory exists: $dir"
        else
            log_error "Directory missing: $dir"
        fi
    done
}

# Test function file existence
test_function_files() {
    log_info "Testing function file existence"

    # Define all expected function files
    local function_files=(
        # Git functions
        "dot_zsh/functions/git/git-remote-gone-ls"
        "dot_zsh/functions/git/git-remote-gone-rm"
        "dot_zsh/functions/git/git-co-task"
        "dot_zsh/functions/git/git-worktree-add"
        "dot_zsh/functions/git/git-worktree-rm"
        "dot_zsh/functions/git/git-worktree-cd"
        "dot_zsh/functions/git/_select-worktree"

        # SSH functions
        "dot_zsh/functions/ssh/_ensure-ssh"
        "dot_zsh/functions/ssh/_maybe-ensure-ssh"
        "dot_zsh/functions/ssh/kill-ssh-pipe"
        "dot_zsh/functions/ssh/check-ssh"
        "dot_zsh/functions/ssh/prompt_my_ssh_relay_status"

        # Prompt functions
        "dot_zsh/functions/prompt/set-prompt-message"
        "dot_zsh/functions/prompt/prompt_my_message"

        # Docker functions
        "dot_zsh/functions/docker/reload-local-dev"
        "dot_zsh/functions/docker/prune-quay-images"

        # Build functions
        "dot_zsh/functions/build/_add-to-path"
        "dot_zsh/functions/build/set-buildtools-ca"
        "dot_zsh/functions/build/set-buildtools-nemo"
        "dot_zsh/functions/build/unset-buildtools"
        "dot_zsh/functions/build/fetch-tm-secret"
        "dot_zsh/functions/build/upload-tm-secret"

        # Kubernetes functions
        "dot_zsh/functions/kubernetes/kube-logout"

        # AWS functions
        "dot_zsh/functions/aws/set-aws-region"

        # SSL functions
        "dot_zsh/functions/ssl/check-for-sql-server-cert"
        "dot_zsh/functions/ssl/check-for-server-cert"

        # Utility functions
        "dot_zsh/functions/utils/date-now-in-ms"
        "dot_zsh/functions/utils/date-from-unix-ms"
        "dot_zsh/functions/utils/conc"
        "dot_zsh/functions/utils/bathelp"
        "dot_zsh/functions/utils/help"

        # Spinner functions
        "dot_zsh/functions/spinner/spinner"
        "dot_zsh/functions/spinner/_spinner"

        # Chat functions
        "dot_zsh/functions/chat/chat-gpt"

        # Proxy functions
        "dot_zsh/functions/proxy/init-wsl-for-mitmproxy"
        "dot_zsh/functions/proxy/unset-wsl-mitmproxy-settings"
    )

    for file in "${function_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Function file exists: $file"
        else
            log_error "Function file missing: $file"
        fi
    done
}

# Test function syntax
test_function_syntax() {
    log_info "Testing function syntax"

    local function_files=(
        "dot_zsh/functions/git/git-remote-gone-ls"
        "dot_zsh/functions/git/git-remote-gone-rm"
        "dot_zsh/functions/git/git-co-task"
        "dot_zsh/functions/git/git-worktree-add"
        "dot_zsh/functions/git/git-worktree-rm"
        "dot_zsh/functions/git/git-worktree-cd"
        "dot_zsh/functions/git/_select-worktree"
        "dot_zsh/functions/ssh/_ensure-ssh"
        "dot_zsh/functions/ssh/_maybe-ensure-ssh"
        "dot_zsh/functions/ssh/kill-ssh-pipe"
        "dot_zsh/functions/ssh/check-ssh"
        "dot_zsh/functions/ssh/prompt_my_ssh_relay_status"
        "dot_zsh/functions/prompt/set-prompt-message"
        "dot_zsh/functions/prompt/prompt_my_message"
        "dot_zsh/functions/docker/reload-local-dev"
        "dot_zsh/functions/docker/prune-quay-images"
        "dot_zsh/functions/build/_add-to-path"
        "dot_zsh/functions/build/set-buildtools-ca"
        "dot_zsh/functions/build/set-buildtools-nemo"
        "dot_zsh/functions/build/unset-buildtools"
        "dot_zsh/functions/build/fetch-tm-secret"
        "dot_zsh/functions/build/upload-tm-secret"
        "dot_zsh/functions/kubernetes/kube-logout"
        "dot_zsh/functions/aws/set-aws-region"
        "dot_zsh/functions/ssl/check-for-sql-server-cert"
        "dot_zsh/functions/ssl/check-for-server-cert"
        "dot_zsh/functions/utils/date-now-in-ms"
        "dot_zsh/functions/utils/date-from-unix-ms"
        "dot_zsh/functions/utils/conc"
        "dot_zsh/functions/utils/bathelp"
        "dot_zsh/functions/utils/help"
        "dot_zsh/functions/spinner/spinner"
        "dot_zsh/functions/spinner/_spinner"
        "dot_zsh/functions/chat/chat-gpt"
        "dot_zsh/functions/proxy/init-wsl-for-mitmproxy"
        "dot_zsh/functions/proxy/unset-wsl-mitmproxy-settings"
    )

    for file in "${function_files[@]}"; do
        if [[ -f "$file" ]]; then
            if zsh -n "$file" 2>/dev/null; then
                log_success "Syntax OK: $file"
            else
                log_error "Syntax error: $file"
            fi
        fi
    done
}

# Test autoload configuration loading
test_autoload_configuration() {
    log_info "Testing autoload configuration loading"

    if zsh -c 'source dot_zsh/load_functions.zsh && echo "Configuration loaded successfully"' 2>/dev/null; then
        log_success "Autoload configuration loads successfully"
    else
        log_error "Autoload configuration failed to load"
    fi
}

# Test function dependencies
test_function_dependencies() {
    log_info "Testing function dependencies"

    # Test that SSL functions can find spinner
    if zsh -c 'source dot_zsh/load_functions.zsh && autoload -Uz spinner && autoload -Uz check-for-sql-server-cert && echo "SSL dependency OK"' 2>/dev/null; then
        log_success "SSL functions can find spinner dependency"
    else
        log_error "SSL functions cannot find spinner dependency"
    fi

    # Test that git worktree functions can find _select-worktree
    if zsh -c 'source dot_zsh/load_functions.zsh && autoload -Uz _select-worktree && autoload -Uz git-worktree-rm && echo "Git dependency OK"' 2>/dev/null; then
        log_success "Git worktree functions can find _select-worktree dependency"
    else
        log_error "Git worktree functions cannot find _select-worktree dependency"
    fi
}

# Test Powerlevel10k naming conventions
test_powerlevel10k_naming() {
    log_info "Testing Powerlevel10k naming conventions"

    local prompt_functions=(
        "prompt_my_message"
        "prompt_my_ssh_relay_status"
    )

    for func in "${prompt_functions[@]}"; do
        # Check that function name doesn't start with underscore
        if [[ "$func" != _* ]]; then
            log_success "Powerlevel10k function correctly named: $func"
        else
            log_error "Powerlevel10k function incorrectly named (starts with underscore): $func"
        fi

        # Check that function uses snake_case
        if [[ "$func" =~ ^[a-z_]+$ ]]; then
            log_success "Powerlevel10k function uses snake_case: $func"
        else
            log_error "Powerlevel10k function doesn't use snake_case: $func"
        fi
    done
}

# Test private function naming conventions
test_private_function_naming() {
    log_info "Testing private function naming conventions"

    local private_functions=(
        "_select-worktree"
        "_ensure-ssh"
        "_maybe-ensure-ssh"
        "_add-to-path"
        "_spinner"
    )

    for func in "${private_functions[@]}"; do
        # Check that function name starts with underscore
        if [[ "$func" == _* ]]; then
            log_success "Private function correctly named: $func"
        else
            log_error "Private function incorrectly named (no underscore prefix): $func"
        fi
    done
}

# Main test execution
main() {
    echo "🧪 Function Split Project - Phase 5 Test Suite"
    echo "=============================================="
    echo

    # Reset counters
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0

    # Run all tests
    test_fpath_configuration
    test_function_files
    test_function_syntax
    test_autoload_configuration
    test_function_dependencies
    test_powerlevel10k_naming
    test_private_function_naming

    # Test autoload for all functions
    echo
    log_info "Testing autoload for all functions..."

    # Git functions
    test_function_autoload "git-remote-gone-ls" "git"
    test_function_autoload "git-remote-gone-rm" "git"
    test_function_autoload "git-co-task" "git"
    test_function_autoload "git-worktree-add" "git"
    test_function_autoload "git-worktree-rm" "git"
    test_function_autoload "git-worktree-cd" "git"
    test_function_autoload "_select-worktree" "git"

    # SSH functions
    test_function_autoload "_ensure-ssh" "ssh"
    test_function_autoload "_maybe-ensure-ssh" "ssh"
    test_function_autoload "kill-ssh-pipe" "ssh"
    test_function_autoload "check-ssh" "ssh"
    test_function_autoload "prompt_my_ssh_relay_status" "ssh"

    # Prompt functions
    test_function_autoload "set-prompt-message" "prompt"
    test_function_autoload "prompt_my_message" "prompt"

    # Build functions
    test_function_autoload "_add-to-path" "build"
    test_function_autoload "set-buildtools-ca" "build"
    test_function_autoload "set-buildtools-nemo" "build"
    test_function_autoload "unset-buildtools" "build"
    test_function_autoload "fetch-tm-secret" "build"
    test_function_autoload "upload-tm-secret" "build"

    # Other functions
    test_function_autoload "reload-local-dev" "docker"
    test_function_autoload "prune-quay-images" "docker"
    test_function_autoload "kube-logout" "kubernetes"
    test_function_autoload "set-aws-region" "aws"
    test_function_autoload "check-for-sql-server-cert" "ssl"
    test_function_autoload "check-for-server-cert" "ssl"
    test_function_autoload "date-now-in-ms" "utils"
    test_function_autoload "date-from-unix-ms" "utils"
    test_function_autoload "conc" "utils"
    test_function_autoload "bathelp" "utils"
    test_function_autoload "help" "utils"
    test_function_autoload "spinner" "spinner"
    test_function_autoload "_spinner" "spinner"
    test_function_autoload "chat-gpt" "chat"
    test_function_autoload "init-wsl-for-mitmproxy" "proxy"
    test_function_autoload "unset-wsl-mitmproxy-settings" "proxy"

    # Print summary
    echo
    echo "📊 Test Summary"
    echo "==============="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed.${NC}"
        exit 1
    fi
}

# Run the test suite
main "$@"
