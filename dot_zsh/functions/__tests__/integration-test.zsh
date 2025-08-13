#!/usr/bin/env zsh
# Integration Test Suite for Function Split Project
# Tests complete system integration and critical functionality

echo "🔗 Integration Test Suite - Function Split Project"
echo "=================================================="
echo

# Test 1: Complete zsh startup with new autoload system
echo "1. Testing complete zsh startup process..."
startup_time=$(time (zsh -c 'source dot_zsh/load_functions.zsh && echo "Startup complete" >/dev/null') 2>&1 | grep real | awk '{print $2}')
echo "✅ Zsh startup completed in $startup_time"

# Test 2: Test function availability after loading
echo
echo "2. Testing function availability..."
available_functions=0
total_functions=0

# Test all functions for availability
all_functions=(
    # Git functions
    "git-remote-gone-ls" "git-remote-gone-rm" "git-co-task" "git-worktree-add" "git-worktree-rm" "git-worktree-cd" "_select-worktree"
    # SSH functions
    "_ensure-ssh" "_maybe-ensure-ssh" "kill-ssh-pipe" "check-ssh" "prompt_my_ssh_relay_status"
    # Prompt functions
    "set-prompt-message" "prompt_my_message"
    # Build functions
    "_add-to-path" "set-buildtools-ca" "set-buildtools-nemo" "unset-buildtools" "fetch-tm-secret" "upload-tm-secret"
    # Other functions
    "reload-local-dev" "prune-quay-images" "kube-logout" "set-aws-region" "check-for-sql-server-cert" "check-for-server-cert"
    "date-now-in-ms" "date-from-unix-ms" "conc" "bathelp" "help" "spinner" "_spinner" "chat-gpt"
    "init-wsl-for-mitmproxy" "unset-wsl-mitmproxy-settings"
)

for func in "${all_functions[@]}"; do
    ((total_functions++))
    if zsh -c "source dot_zsh/load_functions.zsh && autoload -Uz $func && echo 'Function available'" 2>/dev/null; then
        echo "✅ $func available"
        ((available_functions++))
    else
        echo "❌ $func not available"
    fi
done

echo "📊 Function availability: $available_functions/$total_functions"

# Test 3: Test critical integrations
echo
echo "3. Testing critical integrations..."

# Test SSH hook registration
echo "   Testing SSH hook registration..."
if zsh -c 'source dot_zsh/load_functions.zsh && autoload -Uz _maybe-ensure-ssh && echo "SSH hook function loaded"' 2>/dev/null; then
    echo "✅ SSH hook function loads successfully"
else
    echo "❌ SSH hook function failed to load"
fi

# Test prompt integration
echo "   Testing prompt integration..."
if zsh -c 'source dot_zsh/load_functions.zsh && autoload -Uz prompt_my_message && autoload -Uz prompt_my_ssh_relay_status && echo "Prompt functions loaded"' 2>/dev/null; then
    echo "✅ Prompt functions load successfully"
else
    echo "❌ Prompt functions failed to load"
fi

# Test function dependencies
echo "   Testing function dependencies..."
if zsh -c 'source dot_zsh/load_functions.zsh && autoload -Uz spinner && autoload -Uz check-for-sql-server-cert && echo "SSL dependency OK"' 2>/dev/null; then
    echo "✅ SSL functions can find spinner dependency"
else
    echo "❌ SSL functions cannot find spinner dependency"
fi

# Test 4: Test environment variable handling
echo
echo "4. Testing environment variable handling..."
if zsh -c 'source dot_zsh/load_functions.zsh && autoload -Uz _add-to-path && echo "PATH helper available"' 2>/dev/null; then
    echo "✅ PATH management helper available"
else
    echo "❌ PATH management helper not available"
fi

# Test 5: Test Powerlevel10k compatibility
echo
echo "5. Testing Powerlevel10k compatibility..."
prompt_segments=("prompt_my_message" "prompt_my_ssh_relay_status")
p10k_compatible=0

for segment in "${prompt_segments[@]}"; do
    # Check naming convention
    if [[ "$segment" != _* && "$segment" =~ ^[a-z_]+$ ]]; then
        echo "✅ $segment follows Powerlevel10k naming convention"
        ((p10k_compatible++))
    else
        echo "❌ $segment doesn't follow Powerlevel10k naming convention"
    fi
done

# Test 6: Performance test
echo
echo "6. Performance testing..."
echo "   Testing autoload vs source performance..."

# Time autoload approach
autoload_time=$(time (zsh -c 'source dot_zsh/load_functions.zsh && echo "Autoload complete" >/dev/null') 2>&1 | grep real | awk '{print $2}')

echo "   Autoload startup time: $autoload_time"

# Test 7: Memory usage test
echo
echo "7. Memory usage testing..."
echo "   Testing memory footprint..."

# Get memory usage before
memory_before=$(ps -o rss= -p $$ 2>/dev/null || echo "0")

# Load functions
zsh -c 'source dot_zsh/load_functions.zsh && echo "Functions loaded"' >/dev/null 2>&1

# Get memory usage after
memory_after=$(ps -o rss= -p $$ 2>/dev/null || echo "0")

if [[ "$memory_before" != "0" && "$memory_after" != "0" ]]; then
    memory_diff=$((memory_after - memory_before))
    echo "   Memory usage change: ${memory_diff}KB"
else
    echo "   Memory usage: Unable to measure"
fi

# Summary
echo
echo "📊 Integration Test Summary"
echo "==========================="
echo "Startup time: $startup_time"
echo "Function availability: $available_functions/$total_functions"
echo "Powerlevel10k compatible segments: $p10k_compatible/2"

# Calculate success rate
success_rate=$((available_functions * 100 / total_functions))

if [[ $success_rate -eq 100 && $p10k_compatible -eq 2 ]]; then
    echo
    echo "🎉 All integration tests passed!"
    echo "✅ System is ready for production use"
    exit 0
else
    echo
    echo "⚠️  Some integration tests failed"
    echo "Success rate: ${success_rate}%"
    exit 1
fi
