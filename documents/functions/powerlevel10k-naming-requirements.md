# Powerlevel10k Prompt Segment Naming Requirements
## Critical Naming Convention for Prompt Integration

### 🚨 **Correct Naming Convention for Powerlevel10k:**

#### **✅ DO:**
- **NO underscore prefix** - Functions should NOT start with underscore
- **Use snake_case** - All underscores, no hyphens
- **Public functions** - These are called by the prompt system

#### **❌ DON'T:**
- **Underscore prefix** - Functions starting with `_` are NOT recognized
- **Kebab-case** - Functions with hyphens are NOT recognized
- **Private functions** - These are public functions called by Powerlevel10k

### 📝 **Examples:**

#### **✅ Correct Function Names:**
```zsh
prompt_my_message()           # ✅ Powerlevel10k will recognize this
prompt_my_ssh_relay_status()  # ✅ Powerlevel10k will recognize this
prompt_git_status()           # ✅ Powerlevel10k will recognize this
```

#### **❌ Incorrect Function Names:**
```zsh
_prompt-my-message()          # ❌ Powerlevel10k will NOT recognize this
_prompt_my_message()          # ❌ Powerlevel10k will NOT recognize this
prompt-my-message()           # ❌ Powerlevel10k will NOT recognize this
```

### 🏗️ **File Naming Convention:**

#### **✅ Correct File Names:**
```
dot_zsh/functions/prompt/
├── prompt_my_message              # ✅ Matches function name exactly
└── set-prompt-message             # ✅ Public API function (kebab-case OK)

dot_zsh/functions/ssh/
├── prompt_my_ssh_relay_status     # ✅ Matches function name exactly
└── _ensure-ssh                    # ✅ Private helper (underscore prefix OK)
```

### 🔧 **Autoload Configuration:**

#### **✅ Correct Autoload Statements:**
```zsh
# Prompt Functions (Powerlevel10k segments)
autoload -Uz prompt_my_message
autoload -Uz prompt_my_ssh_relay_status

# Public API Functions
autoload -Uz set-prompt-message

# Private Helper Functions
autoload -Uz _ensure-ssh
```

### 🎯 **Why This Matters:**

#### **Powerlevel10k Integration:**
1. **Function Discovery**: Powerlevel10k looks for functions without underscore prefix
2. **Segment Registration**: Functions must be public (not private)
3. **Naming Convention**: snake_case is the standard for prompt segments
4. **File Organization**: Files must match function names exactly

#### **Zsh Autoload Compatibility:**
1. **Private Functions**: Use underscore prefix (`_function-name`)
2. **Public Functions**: No underscore prefix (`function-name`)
3. **Prompt Segments**: Special case - public functions with snake_case

### 📋 **Current Implementation:**

#### **✅ Correctly Named Functions:**
- `prompt_my_message` - Powerlevel10k prompt segment
- `prompt_my_ssh_relay_status` - Powerlevel10k prompt segment
- `set-prompt-message` - Public API function (kebab-case OK)

#### **✅ Correctly Named Private Functions:**
- `_ensure-ssh` - Private helper function
- `_maybe-ensure-ssh` - Private hook function
- `_add-to-path` - Private helper function

### 🚀 **Usage Examples:**

#### **Powerlevel10k Configuration:**
```zsh
# In .p10k.zsh or prompt configuration
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  # ... other segments ...
  prompt_my_message
  prompt_my_ssh_relay_status
)
```

#### **Function Calls:**
```zsh
# Public API
set-prompt-message "Warning: Build failed" warn

# Prompt segments (called automatically by Powerlevel10k)
prompt_my_message        # Displays queued messages
prompt_my_ssh_relay_status  # Shows SSH relay status
```

### ✅ **Compliance Checklist:**

- [x] **Prompt segment functions** use snake_case (no hyphens)
- [x] **Prompt segment functions** have NO underscore prefix
- [x] **Private helper functions** use underscore prefix
- [x] **Public API functions** use kebab-case (no underscore prefix)
- [x] **File names** match function names exactly
- [x] **Autoload statements** use correct function names

### 📚 **References:**

- **Powerlevel10k Documentation**: Prompt segment functions must be public
- **Zsh Best Practices**: Private functions use underscore prefix
- **Autoload Convention**: File names must match function names

**Status**: ✅ Powerlevel10k Naming Requirements Documented and Implemented
