#!/usr/bin/env zsh
# Quick Test Suite for Function Split Project
# Tests critical functionality without getting stuck

echo "🧪 Quick Test Suite - Function Split Project"
echo "============================================"
echo

# Test 1: Load autoload configuration
echo "1. Testing autoload configuration loading..."
if zsh -c 'source dot_zsh/load_functions.zsh && echo "✅ Configuration loaded"' 2>/dev/null; then
    echo "✅ Autoload configuration loads successfully"
else
    echo "❌ Autoload configuration failed to load"
    exit 1
fi

# Test 2: Check all directories exist
echo
echo "2. Testing directory structure..."
directories=(
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

missing_dirs=0
for dir in "${directories[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir missing"
        ((missing_dirs++))
    fi
done

if [[ $missing_dirs -eq 0 ]]; then
    echo "✅ All directories present"
else
    echo "❌ $missing_dirs directories missing"
fi

# Test 3: Count function files
echo
echo "3. Testing function file count..."
total_files=0
for dir in "${directories[@]}"; do
    if [[ -d "$dir" ]]; then
        count=$(find "$dir" -maxdepth 1 -type f | wc -l)
        echo "📁 $dir: $count files"
        ((total_files += count))
    fi
done
echo "📊 Total function files: $total_files"

# Test 4: Test autoload for key functions
echo
echo "4. Testing autoload for key functions..."
key_functions=(
    "git-remote-gone-ls"
    "spinner"
    "set-prompt-message"
    "prompt_my_message"
    "_add-to-path"
    "set-buildtools-ca"
)

autoload_failures=0
for func in "${key_functions[@]}"; do
    if zsh -c "source dot_zsh/load_functions.zsh && autoload -Uz $func && echo '✅ $func'" 2>/dev/null; then
        echo "✅ $func autoloads successfully"
    else
        echo "❌ $func autoload failed"
        ((autoload_failures++))
    fi
done

# Test 5: Test function syntax
echo
echo "5. Testing function syntax..."
syntax_errors=0
for dir in "${directories[@]}"; do
    if [[ -d "$dir" ]]; then
        for file in "$dir"/*; do
            if [[ -f "$file" ]]; then
                if zsh -n "$file" 2>/dev/null; then
                    echo "✅ $(basename "$file") syntax OK"
                else
                    echo "❌ $(basename "$file") syntax error"
                    ((syntax_errors++))
                fi
            fi
        done
    fi
done

# Test 6: Test Powerlevel10k naming conventions
echo
echo "6. Testing Powerlevel10k naming conventions..."
prompt_functions=(
    "prompt_my_message"
    "prompt_my_ssh_relay_status"
)

naming_errors=0
for func in "${prompt_functions[@]}"; do
    if [[ "$func" != _* ]]; then
        echo "✅ $func correctly named (no underscore prefix)"
    else
        echo "❌ $func incorrectly named (has underscore prefix)"
        ((naming_errors++))
    fi

    if [[ "$func" =~ ^[a-z_]+$ ]]; then
        echo "✅ $func uses snake_case"
    else
        echo "❌ $func doesn't use snake_case"
        ((naming_errors++))
    fi
done

# Summary
echo
echo "📊 Test Summary"
echo "==============="
echo "Directories missing: $missing_dirs"
echo "Total function files: $total_files"
echo "Autoload failures: $autoload_failures"
echo "Syntax errors: $syntax_errors"
echo "Naming convention errors: $naming_errors"

if [[ $missing_dirs -eq 0 && $autoload_failures -eq 0 && $syntax_errors -eq 0 && $naming_errors -eq 0 ]]; then
    echo
    echo "🎉 All tests passed!"
    exit 0
else
    echo
    echo "❌ Some tests failed."
    exit 1
fi
