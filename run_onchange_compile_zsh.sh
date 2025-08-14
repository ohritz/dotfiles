#!/usr/bin/env zsh

# Compile zsh files for better performance
# This script is run by chezmoi when zsh files change

# Be resilient: don't exit on first error; treat unset vars as errors
unsetopt errexit 2>/dev/null || true
set -u

ZDOTDIR="${ZDOTDIR:-$HOME/.zsh}"

echo "Compiling zsh files for better performance..."

# Track compilation results
compiled_count=0
failed_count=0
skipped_count=0

# Function to safely compile a file with error handling
compile_file() {
    local file="$1"
    local file_type="$2"

    echo "  Attempting to compile: $file"

    # Skip files in __tests__ directories
    if [[ "$file" == *"__tests__"* ]]; then
        echo "    ⏭️  Skipped (test directory): $file"
        ((skipped_count++))
        return 0
    fi

    # Determine if file should be treated as a shell script
    local is_shell_script=false

    # Always compile rc and completion types
    if [[ "$file_type" == "rc" || "$file_type" == "completion" ]]; then
        is_shell_script=true
    # Autoloaded function and completion files (no extensions/shebangs required)
    elif [[ "$file" == */functions/* || "$file" == */completions/* ]]; then
        is_shell_script=true
    # Extension-based detection as a fallback
    elif [[ "$file" == *.zsh || "$file" == *.sh ]]; then
        is_shell_script=true
    else
        # Final fallback: executable with a shell shebang
        if [[ -x "$file" ]]; then
            local first_line
            first_line=$(head -n1 "$file" 2>/dev/null | tr -d '[:space:]')
            if [[ "$first_line" == '#!'* ]] && {
                [[ "$first_line" == *zsh* ]] || [[ "$first_line" == *bash* ]] || [[ "$first_line" == *" sh" ]] || [[ "$first_line" == *"/sh" ]]
            }; then
                is_shell_script=true
            fi
        fi
    fi

    if [[ "$is_shell_script" == "false" ]]; then
        echo "    ⏭️  Skipped (not a shell script): $file"
        ((skipped_count++))
        return 0
    fi

    # Try to compile the file
    if zcompile "$file" 2>/dev/null; then
        echo "    ✅ Compiled successfully: $file"
        ((compiled_count++))
    else
        echo "    ❌ Failed to compile: $file"
        ((failed_count++))
        # Don't exit on individual file failures
        return 0
    fi
}

# Compile main rc files (check both $ZDOTDIR and $HOME)
echo "📁 Processing main rc files..."
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    compile_file "$ZDOTDIR/.zshrc" "rc"
fi
if [[ -f "$HOME/.zshrc" && "$HOME/.zshrc" != "$ZDOTDIR/.zshrc" ]]; then
    compile_file "$HOME/.zshrc" "rc"
fi

if [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
    compile_file "$ZDOTDIR/.p10k.zsh" "rc"
fi
if [[ -f "$HOME/.p10k.zsh" && "$HOME/.p10k.zsh" != "$ZDOTDIR/.p10k.zsh" ]]; then
    compile_file "$HOME/.p10k.zsh" "rc"
fi

# Compile function files (recursively handle all subdirectories)
if [[ -d "$ZDOTDIR/functions" ]]; then
    echo "📁 Processing function files..."
    # Use find to robustly list files, excluding __tests__ and compiled zwc files
    while IFS= read -r -d '' func_file; do
        compile_file "$func_file" "function"
    done < <(find "$ZDOTDIR/functions" -type f -not -path '*/__tests__/*' -not -name '*.zwc' -print0)
fi

# Compile completion files
if [[ -d "$ZDOTDIR/completions" ]]; then
    echo "📁 Processing completion files..."
    while IFS= read -r -d '' comp_file; do
        compile_file "$comp_file" "completion"
    done < <(find "$ZDOTDIR/completions" -type f -name '_*' -not -name '*.zwc' -print0)
fi

# Summary
echo ""
echo "📊 Compilation Summary:"
echo "  ✅ Successfully compiled: $compiled_count files"
echo "  ❌ Failed to compile: $failed_count files"
echo "  ⏭️  Skipped: $skipped_count files"

if [[ $failed_count -gt 0 ]]; then
    echo "⚠️  Some files failed to compile, but this is usually not critical."
    echo "   Failed files may be test files or have syntax that doesn't compile."
fi

echo "Zsh compilation process complete!"
