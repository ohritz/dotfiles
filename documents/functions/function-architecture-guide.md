# Function Architecture Guide
## Technical Design and Implementation Details

### 🏗️ **Architecture Overview**

The function system is designed around Zsh's autoload mechanism, providing lazy loading, clear organization, and optimal performance. Functions are organized into logical categories with proper dependency management.

### 📁 **Directory Organization Strategy**

#### **Category-Based Organization**
Functions are grouped by purpose and domain:
- **git/**: Git workflow and repository management
- **ssh/**: SSH connection and relay management
- **prompt/**: Powerlevel10k prompt integration
- **build/**: Build tools and environment management
- **docker/**: Docker container management
- **kubernetes/**: Kubernetes cluster operations
- **aws/**: AWS cloud operations
- **ssl/**: SSL/TLS certificate validation
- **utils/**: General utility functions
- **spinner/**: Progress indication and user feedback
- **chat/**: AI/LLM integration
- **proxy/**: Network proxy configuration

#### **File Naming Strategy**
- **One function per file**: Enables autoload and clear organization
- **Function name matches filename**: Required for autoload discovery
- **Descriptive names**: Clear indication of function purpose

### 🔧 **Autoload Configuration Design**

#### **fpath Configuration**
```zsh
fpath=(
    "${ZDOTDIR}/functions/git"
    "${ZDOTDIR}/functions/ssh"
    "${ZDOTDIR}/functions/prompt"
    "${ZDOTDIR}/functions/docker"
    "${ZDOTDIR}/functions/build"
    "${ZDOTDIR}/functions/kubernetes"
    "${ZDOTDIR}/functions/aws"
    "${ZDOTDIR}/functions/ssl"
    "${ZDOTDIR}/functions/utils"
    "${ZDOTDIR}/functions/spinner"
    "${ZDOTDIR}/functions/chat"
    "${ZDOTDIR}/functions/proxy"
    $fpath
)
```

#### **Loading Phase Strategy**
Functions are loaded in phases to manage dependencies:

1. **Phase 1: Environment Setup** - Global state and hooks
2. **Phase 2: Core Utilities** - Foundation functions
3. **Phase 3: Tool-Specific** - Main functionality
4. **Phase 4: Prompt Integration** - UI integration

### 🎯 **Naming Convention Architecture**

#### **Function Visibility Patterns**
- **Public Functions**: No underscore prefix, user-callable
- **Private Functions**: Underscore prefix, internal use only
- **Prompt Segments**: Special case - public with snake_case

#### **Naming Convention Matrix**
| Function Type | Prefix | Case Style | Example | Purpose |
|---------------|--------|------------|---------|---------|
| Public API | None | kebab-case | `set-prompt-message` | User commands |
| Private Helper | `_` | kebab-case | `_add-to-path` | Internal functions |
| Prompt Segment | None | snake_case | `prompt_my_message` | Powerlevel10k |

### 🔗 **Dependency Management**

#### **Function Dependencies**
```
git-worktree-rm → _select-worktree
git-worktree-cd → _select-worktree
spinner → _spinner
check-for-sql-server-cert → spinner
check-for-server-cert → spinner
_maybe-ensure-ssh → _ensure-ssh
set-buildtools-ca → _add-to-path
set-buildtools-nemo → _add-to-path
```

#### **External Dependencies**
- **Git functions**: git, awk, sed, fzf
- **SSH functions**: socat, npiperelay.exe, pkill, ssh
- **SSL functions**: nmap, openssl
- **Build functions**: aws CLI
- **Chat functions**: curl, jq, highlight

### 🌐 **Global State Management**

#### **Environment Variables Set**
| Variable | Purpose | Set By | Used By |
|----------|---------|--------|---------|
| `OHR_SSH_RELAY_STATUS` | SSH relay status | `_ensure-ssh` | `prompt_my_ssh_relay_status` |
| `SEEN_GIT_REPOS` | Git repo tracking | `_maybe-ensure-ssh` | `_maybe-ensure-ssh` |
| `OHR_PROMPT_MESSAGE` | Prompt message queue | `set-prompt-message` | `prompt_my_message` |
| `BUILD_TOOLS_PATH` | Build tools location | `set-buildtools-*` | PATH modification |
| `AWS_REGION` | AWS region setting | `set-aws-region` | AWS CLI |

#### **Environment Variables Required**
| Variable | Purpose | Required By |
|----------|---------|-------------|
| `STENA_PROJECTS_ROOT` | Stena projects root | Build tools functions |
| `TM_LOCAL_DEV_PATH` | TM local dev path | TM secret functions |
| `OPENAI_API_KEY` | OpenAI API auth | Chat functions |

### 🔄 **Hook Integration Architecture**

#### **SSH Hook System**
```zsh
# Automatic hook registration in _maybe-ensure-ssh
add-zsh-hook precmd _maybe-ensure-ssh
```

#### **Hook Behavior**
- **Trigger**: Before each prompt (precmd)
- **Condition**: Only in git repositories
- **Action**: Ensure SSH relay is running
- **State**: Track seen repositories to avoid repeated checks

### 🎨 **Prompt Integration Architecture**

#### **Powerlevel10k Integration**
- **Segment Functions**: Public functions with snake_case
- **Message Queue**: Global array for message storage
- **Status Display**: Real-time status in prompt

#### **Prompt Message System**
```zsh
# Message types: info, warn, error
set-prompt-message "Build failed" error
set-prompt-message "Deployment successful" info
```

### 🛠️ **Build Tools Architecture**

#### **PATH Management Strategy**
- **Prepend to PATH**: Build tools found first
- **Deduplication**: Remove existing entries before adding
- **Validation**: Check environment variables and directories
- **Cleanup**: Generic unset function for any build tools

#### **Helper Function Design**
```zsh
_add-to-path() {
  # Validation
  # Deduplication
  # Position-based addition (prepend/append)
  # Error handling
}
```

### 🧪 **Testing Architecture**

#### **Test Organization**
- **Location**: `dot_zsh/functions/__tests__/`
- **Runner**: `run-tests.zsh` with command-line interface
- **Suites**: Quick, integration, and comprehensive tests

#### **Test Categories**
- **Autoload Configuration**: Verify loading system
- **Function Syntax**: Validate zsh syntax
- **Naming Conventions**: Check naming compliance
- **Integration**: Test critical integrations
- **Performance**: Measure startup and runtime

### 📊 **Performance Characteristics**

#### **Startup Performance**
- **Lazy Loading**: Functions loaded only when needed
- **Reduced Memory**: Smaller initial memory footprint
- **Faster Startup**: No source overhead for unused functions

#### **Runtime Performance**
- **Efficient Discovery**: fpath-based function discovery
- **Minimal Overhead**: Autoload has minimal runtime cost
- **Optimized Dependencies**: Proper loading order

### 🔒 **Security Considerations**

#### **Function Isolation**
- **Private Functions**: Internal helpers not exposed
- **Input Validation**: Proper parameter checking
- **Error Handling**: Graceful failure modes

#### **Environment Security**
- **Variable Validation**: Check required environment variables
- **Path Validation**: Verify directory existence
- **Permission Checks**: Validate file permissions where needed

### 🔄 **Migration Strategy**

#### **Backward Compatibility**
- **Function Names**: Preserved for user scripts
- **API Interface**: No breaking changes
- **Behavior**: Identical functionality

#### **Benefits Achieved**
- **Performance**: Faster startup and reduced memory
- **Maintainability**: Easier to edit individual functions
- **Organization**: Clear separation of concerns
- **Scalability**: Easy to add new functions

### 📚 **Best Practices**

#### **Function Design**
- **Single Responsibility**: One clear purpose per function
- **Error Handling**: Proper validation and error messages
- **Documentation**: Clear comments explaining purpose
- **Dependencies**: Minimal external dependencies

#### **File Organization**
- **Logical Grouping**: Related functions in same directory
- **Consistent Naming**: Follow established conventions
- **Clear Structure**: Easy to navigate and understand

#### **Integration Patterns**
- **Hook Registration**: Automatic when appropriate
- **Global State**: Minimal and well-documented
- **Prompt Integration**: Follow Powerlevel10k conventions

**Status**: ✅ Architecture Complete and Documented
