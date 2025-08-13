# Function Organization and Usage Guide
## Zsh Function Split Project - Complete Documentation

### 📋 **Overview**
This document describes the organization and usage of the 34 zsh functions that have been split from multi-function files into individual autoload-compatible files.

### 🏗️ **Directory Structure**
```
dot_zsh/functions/
├── git/                    # 7 functions (6 public, 1 private)
├── ssh/                    # 6 functions (3 public, 3 private)
├── prompt/                 # 2 functions (all public)
├── docker/                 # 2 functions (all public)
├── build/                  # 6 functions (5 public, 1 private)
├── kubernetes/             # 1 function (public)
├── aws/                    # 1 function (public)
├── ssl/                    # 2 functions (all public)
├── utils/                  # 5 functions (all public)
├── spinner/                # 2 functions (1 public, 1 private)
├── chat/                   # 1 function (public)
├── proxy/                  # 2 functions (all public)
└── __tests__/              # Test suites
    ├── run-tests.zsh       # Test runner (recommended)
    ├── quick-test.zsh      # Quick validation test
    ├── integration-test.zsh # Integration testing
    └── test-suite.zsh      # Comprehensive test suite
```

### 📊 **Function Inventory**

#### **Git Functions (7 functions)**
| Function | Type | Purpose | Dependencies |
|----------|------|---------|--------------|
| `git-remote-gone-ls` | Public | List branches with gone remotes | git, awk |
| `git-remote-gone-rm` | Public | Remove branches with gone remotes | git, awk, xargs |
| `git-co-task` | Public | Checkout branch by task ID | git, sed, awk |
| `git-worktree-add` | Public | Add git worktree | git |
| `git-worktree-rm` | Public | Remove git worktree | git, fzf, `_select-worktree` |
| `git-worktree-cd` | Public | Change to git worktree | git, fzf, `_select-worktree` |
| `_select-worktree` | Private | Helper for worktree selection | awk, column, fzf |

#### **SSH Functions (6 functions)**
| Function | Type | Purpose | Dependencies |
|----------|------|---------|--------------|
| `_ensure-ssh` | Private | Internal SSH relay management | socat, npiperelay.exe |
| `_maybe-ensure-ssh` | Private | Hook function (precmd) | git, `_ensure-ssh` |
| `kill-ssh-pipe` | Public | Kill SSH relay process | pkill |
| `check-ssh` | Public | Test SSH authentication | ssh |
| `prompt_my_ssh_relay_status` | Public | Powerlevel10k segment | p10k |

#### **Prompt Functions (2 functions)**
| Function | Type | Purpose | Dependencies |
|----------|------|---------|--------------|
| `set-prompt-message` | Public | Set prompt message (user API) | None |
| `prompt_my_message` | Public | Powerlevel10k segment | p10k |

#### **Build Tools Functions (6 functions)**
| Function | Type | Purpose | Dependencies |
|----------|------|---------|--------------|
| `_add-to-path` | Private | PATH management helper | None |
| `set-buildtools-ca` | Public | Set CA build tools path | `_add-to-path` |
| `set-buildtools-nemo` | Public | Set Nemo build tools path | `_add-to-path` |
| `unset-buildtools` | Public | Remove build tools from PATH | None |
| `fetch-tm-secret` | Public | Fetch TM secrets from S3 | aws, source |
| `upload-tm-secret` | Public | Upload TM secrets to S3 | aws, source |

#### **Other Function Categories**
- **Docker**: `reload-local-dev`, `prune-quay-images`
- **Kubernetes**: `kube-logout`
- **AWS**: `set-aws-region`
- **SSL**: `check-for-sql-server-cert`, `check-for-server-cert`
- **Utils**: `date-now-in-ms`, `date-from-unix-ms`, `conc`, `bathelp`, `help`
- **Spinner**: `spinner`, `_spinner`
- **Chat**: `chat-gpt`
- **Proxy**: `init-wsl-for-mitmproxy`, `unset-wsl-mitmproxy-settings`

### 🔧 **Autoload Configuration**

#### **Loading Order**
The functions are loaded in 4 phases to ensure proper dependencies:

1. **Phase 1: Environment Setup** (Early Loading)
   - SSH functions with hooks and global state
   - Build tools environment functions
   - AWS and proxy environment functions

2. **Phase 2: Core Utilities** (Early-Mid Loading)
   - Spinner functions (dependencies)
   - Git helper functions
   - Utility functions

3. **Phase 3: Tool-Specific Functions** (Mid Loading)
   - Git functions
   - SSH functions
   - Docker functions
   - Build tools functions
   - All other tool functions

4. **Phase 4: Prompt Integration** (Late Loading)
   - Prompt functions for Powerlevel10k integration

#### **Autoload Configuration File**
The autoload configuration is in `dot_zsh/load_functions.zsh` and includes:
- fpath configuration for all 12 directories
- autoload statements for all 34 functions
- Proper loading order for dependencies

### 🎯 **Naming Conventions**

#### **Powerlevel10k Prompt Segments**
- **NO underscore prefix** - Functions should NOT start with underscore
- **Use snake_case** - All underscores, no hyphens
- **Public functions** - Called by the prompt system

**Examples:**
```zsh
prompt_my_message()           # ✅ Correct
prompt_my_ssh_relay_status()  # ✅ Correct
_prompt-my-message()          # ❌ Incorrect
```

#### **Private Helper Functions**
- **Underscore prefix** - Functions start with underscore
- **Use kebab-case** - Hyphens for readability
- **Internal use only** - Called by other functions

**Examples:**
```zsh
_ensure-ssh()                 # ✅ Correct
_add-to-path()                # ✅ Correct
_select-worktree()            # ✅ Correct
```

#### **Public API Functions**
- **NO underscore prefix** - Functions do NOT start with underscore
- **Use kebab-case** - Hyphens for readability
- **User-callable** - Direct user commands

**Examples:**
```zsh
set-prompt-message()          # ✅ Correct
git-remote-gone-ls()          # ✅ Correct
check-ssh()                   # ✅ Correct
```

### 🚀 **Usage Examples**

#### **Git Functions**
```bash
# List branches with gone remotes
git-remote-gone-ls

# Remove branches with gone remotes
git-remote-gone-rm

# Checkout branch by task ID
git-co-task 12345

# Add worktree
git-worktree-add feature-branch

# Remove worktree (interactive)
git-worktree-rm

# Change to worktree (interactive)
git-worktree-cd
```

#### **Build Tools Functions**
```bash
# Set CA build tools
set-buildtools-ca

# Set Nemo build tools
set-buildtools-nemo

# Remove build tools from PATH
unset-buildtools

# Fetch TM secrets
fetch-tm-secret

# Upload TM secrets
upload-tm-secret
```

#### **Prompt Functions**
```bash
# Set prompt message
set-prompt-message "Warning: Build failed" warn
set-prompt-message "Info: Deployment successful" info
set-prompt-message "Error: Connection failed" error
```

#### **Utility Functions**
```bash
# Get current time in milliseconds
date-now-in-ms

# Convert Unix ms to date
date-from-unix-ms 1640995200000

# Run command concurrently
conc "echo 'task 1'" "echo 'task 2'" "echo 'task 3'"

# Show help with bat
bathelp git

# Show command help
help git
```

### 🔗 **Critical Integrations**

#### **SSH Hook Integration**
The `_maybe-ensure-ssh` function automatically registers a precmd hook that ensures SSH relay is running when in git repositories.

#### **Powerlevel10k Integration**
The prompt segment functions integrate with Powerlevel10k:
- `prompt_my_message` - Displays queued prompt messages
- `prompt_my_ssh_relay_status` - Shows SSH relay status

#### **Function Dependencies**
- SSL functions depend on `spinner`
- Git worktree functions depend on `_select-worktree`
- Build tools functions depend on `_add-to-path`

### 📋 **Testing**

#### **Test Suites Available**
- `dot_zsh/functions/__tests__/quick-test.zsh` - Quick validation test (recommended)
- `dot_zsh/functions/__tests__/integration-test.zsh` - Integration testing
- `dot_zsh/functions/__tests__/test-suite.zsh` - Comprehensive test suite
- `dot_zsh/functions/__tests__/run-tests.zsh` - Test runner (for advanced usage)

#### **Running Tests**
```bash
# Direct test execution (recommended)
./dot_zsh/functions/__tests__/quick-test.zsh         # Quick test
./dot_zsh/functions/__tests__/integration-test.zsh   # Integration test
./dot_zsh/functions/__tests__/test-suite.zsh         # Full test suite

# Using the test runner (from __tests__ directory)
cd dot_zsh/functions/__tests__ && ./run-tests.zsh quick
cd dot_zsh/functions/__tests__ && ./run-tests.zsh integration
cd dot_zsh/functions/__tests__ && ./run-tests.zsh full
```

### 🔄 **Migration from Old System**

#### **What Changed**
- **Before**: Multi-function files loaded via `source`
- **After**: Individual files loaded via `autoload`

#### **Benefits**
- **Faster Startup**: Functions loaded only when needed
- **Better Organization**: Clear separation of concerns
- **Easier Maintenance**: Individual files easier to edit
- **Improved Performance**: Reduced memory footprint

#### **Backward Compatibility**
- All function names preserved
- All functionality maintained
- No breaking changes to user interface

### 📚 **Technical Details**

For detailed technical information, see:
- `function-architecture-guide.md` - Complete architecture and design details
- `powerlevel10k-naming-requirements.md` - Powerlevel10k integration requirements
- `build-tools-improvements.md` - Build tools enhancement details

#### **Global Variables and State**
| Variable | Set By | Used By | Purpose |
|----------|--------|---------|---------|
| `OHR_SSH_RELAY_STATUS` | `_ensure-ssh` | `prompt_my_ssh_relay_status` | SSH relay status tracking |
| `SEEN_GIT_REPOS` | `_maybe-ensure-ssh` | `_maybe-ensure-ssh` | Track seen git repos per session |
| `OHR_PROMPT_MESSAGE` | `set-prompt-message` | `prompt_my_message` | Prompt message queue |
| `BUILD_TOOLS_PATH` | `set-buildtools-ca`, `set-buildtools-nemo` | PATH modification | Build tools location |
| `AWS_REGION` | `set-aws-region` | AWS CLI | AWS region setting |

#### **Environment Variables Required**
| Variable | Required By | Purpose |
|----------|-------------|---------|
| `STENA_PROJECTS_ROOT` | `set-buildtools-ca`, `set-buildtools-nemo` | Stena projects root |
| `TM_LOCAL_DEV_PATH` | `fetch-tm-secret`, `upload-tm-secret`, `reload-local-dev` | TM local dev path |
| `OPENAI_API_KEY` | `chat-gpt` | OpenAI API authentication |

#### **Function Dependencies**
- `git-worktree-rm` → `_select-worktree`
- `git-worktree-cd` → `_select-worktree`
- `spinner` → `_spinner`
- `check-for-sql-server-cert` → `spinner`
- `check-for-server-cert` → `spinner`
- `_maybe-ensure-ssh` → `_ensure-ssh`
- `set-buildtools-ca` → `_add-to-path`
- `set-buildtools-nemo` → `_add-to-path`

### ✅ **System Status**
- **✅ All 34 functions working correctly**
- **✅ Autoload system fully functional**
- **✅ Critical integrations verified**
- **✅ Performance optimized**
- **✅ Ready for production use**

**Last Updated**: Phase 6 completion
**Status**: ✅ Production Ready
