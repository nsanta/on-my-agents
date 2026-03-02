#!/bin/bash
#
# BMAD Agent Installer
# Pure bash installer for BMAD agents
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s /path/to/project
#   curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s - archibald ethan
#
# Examples:
#   ./install.sh /path/to/project              # Install all agents
#   ./install.sh /path/to/project archibald    # Install specific agent
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m' # No Color

# GitHub repository
REPO_OWNER="nsanta"
REPO_NAME="on-my-agents"
REPO_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default project root is current directory
PROJECT_ROOT="${1:-.}"
shift || true

# Agents to install (default: all)
AGENTS_TO_INSTALL=("$@")

# Temp directory for downloaded files
TEMP_DIR=""

# Logging functions
log_info() { echo -e "${BLUE}📦${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_dim() { echo -e "${DIM}$1${NC}"; }

# Cleanup function
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Download agents from GitHub
download_agents() {
    TEMP_DIR=$(mktemp -d)
    
    log_info "Downloading agents from GitHub..."
    
    # Download agent files
    for agent in archibald ethan mira; do
        local url="$REPO_URL/agents/$agent.md"
        local file="$TEMP_DIR/$agent.md"
        
        if curl -sL "$url" -o "$file" 2>/dev/null; then
            if [[ -s "$file" ]]; then
                log_dim "  Downloaded: $agent.md"
            else
                rm -f "$file"
            fi
        fi
    done
    
    echo "$TEMP_DIR"
}

# Get list of available agents
get_available_agents() {
    local agents_dir="$SCRIPT_DIR/agents"
    
    # If local agents directory doesn't exist or is empty, download from GitHub
    if [[ ! -d "$agents_dir" ]] || [[ -z "$(ls -A "$agents_dir"/*.md 2>/dev/null)" ]]; then
        log_dim "  No local agents found, checking GitHub..."
        agents_dir=$(download_agents)
    fi
    
    if [[ ! -d "$agents_dir" ]]; then
        echo ""
        return
    fi
    
    for file in "$agents_dir"/*.md; do
        if [[ -f "$file" ]]; then
            basename "$file" .md
        fi
    done
}

# Get source directory (local or temp)
get_source_dir() {
    local agents_dir="$SCRIPT_DIR/agents"
    
    if [[ -d "$agents_dir" ]] && [[ -n "$(ls -A "$agents_dir"/*.md 2>/dev/null)" ]]; then
        echo "$agents_dir"
    else
        download_agents
    fi
}

# Install a single agent
install_agent() {
    local agent_name="$1"
    local source_dir
    source_dir=$(get_source_dir)
    local target_dir="$PROJECT_ROOT/_bmad/bmb/agents"
    
    local source_file="$source_dir/${agent_name}.md"
    local target_file="$target_dir/${agent_name}.md"
    
    # Check if source exists
    if [[ ! -f "$source_file" ]]; then
        log_warn "Agent '$agent_name' not found"
        return 1
    fi
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Check if already exists
    if [[ -f "$target_file" ]]; then
        log_dim "  Agent '$agent_name' already exists, skipping"
        return 0
    fi
    
    # Copy agent file
    cp "$source_file" "$target_file"
    log_success "Installed agent: $agent_name"
    return 0
}

# Update agent manifest CSV
update_manifest() {
    local manifest="$PROJECT_ROOT/_bmad/_config/agent-manifest.csv"
    local agents_dir="$PROJECT_ROOT/_bmad/bmb/agents"
    
    # Create manifest directory if needed
    mkdir -p "$(dirname "$manifest")"
    
    # Create header if manifest doesn't exist
    if [[ ! -f "$manifest" ]]; then
        echo '#WV|name,displayName,title,icon,role,identity,communicationStyle,principles,module,path' > "$manifest"
        log_dim "  Created new manifest"
    fi
    
    # Get list of installed agents
    local installed_agents=()
    while IFS= read -r agent; do
        installed_agents+=("$agent")
    done < <(ls -1 "$agents_dir"/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/.md$//' || true)
    
    if [[ ${#installed_agents[@]} -eq 0 ]]; then
        log_dim "  No agents to add to manifest"
        return 0
    fi
    
    # Check which agents are already in manifest
    for agent in "${installed_agents[@]}"; do
        if ! grep -q "^[^#].*,\"$agent\"," "$manifest" 2>/dev/null; then
            # Generate manifest entry
            local entry
            entry=$(generate_manifest_entry "$agent")
            echo "$entry" >> "$manifest"
            log_dim "  Added '$agent' to manifest"
        fi
    done
    
    log_success "Updated manifest"
}

# Generate manifest entry from agent file
generate_manifest_entry() {
    local agent_name="$1"
    local agent_file="$PROJECT_ROOT/_bmad/bmb/agents/${agent_name}.md"
    
    # Extract metadata from agent file
    local name title icon
    name=$(grep -E '^\s*name:' "$agent_file" 2>/dev/null | sed 's/.*name:\s*"\?\([^"]*\)\"?.*/\1/' | head -1)
    title=$(grep -E '^\s*title:' "$agent_file" 2>/dev/null | sed 's/.*title:\s*"\?\([^"]*\)\"?.*/\1/' | head -1)
    icon=$(grep -E '^\s*icon:' "$agent_file" 2>/dev/null | sed 's/.*icon:\s*"\?\([^"]*\)\"?.*/\1/' | head -1)
    
    # Defaults
    name="${name:-$agent_name}"
    title="${title:-Agent}"
    icon="${icon:-🤖}"
    
    # Generate hash prefix
    local hash
    hash="#$(echo "$agent_name" | md5sum | head -c2 | tr '[:lower:]' '[:upper:]')"
    
    echo "$hash|\"$agent_name\",\"$name\",\"$title\",\"$icon\",\"Agent\",\"Agent definition in $agent_name.md\",\"Direct and efficient.\",\"- Follow BMAD patterns\",\"bmb\",\"_bmad/bmb/agents/$agent_name.md\""
}

# Download platform script from GitHub
download_platform_script() {
    local platform="$1"
    local temp_script="$TEMP_DIR/${platform}.sh"
    local url="$REPO_URL/platform-specifics/${platform}.sh"
    
    if [[ -n "$TEMP_DIR" ]]; then
        curl -sL "$url" -o "$temp_script" 2>/dev/null
        if [[ -s "$temp_script" ]]; then
            echo "$temp_script"
        fi
    fi
}

# Install platform-specific configuration
install_platform() {
    local platform="$1"
    local platform_script="$SCRIPT_DIR/platform-specifics/${platform}.sh"
    
    # Try local first, then download
    if [[ ! -f "$platform_script" ]]; then
        platform_script=$(download_platform_script "$platform")
    fi
    
    if [[ -f "$platform_script" ]]; then
        log_info "Configuring for $platform..."
        source "$platform_script"
        if declare -f platform_install >/dev/null 2>&1; then
            platform_install
        fi
    fi
}

# Main installation
main() {
    log_info "BMAD Agent Installer"
    log_dim "  Project: $PROJECT_ROOT"
    echo ""
    
    # Resolve project path
    PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
    
    # Get agents to install
    if [[ ${#AGENTS_TO_INSTALL[@]} -eq 0 ]]; then
        mapfile -t AGENTS_TO_INSTALL < <(get_available_agents)
        log_info "Installing all agents (${#AGENTS_TO_INSTALL[@]})"
    else
        log_info "Installing ${#AGENTS_TO_INSTALL[@]} agent(s)"
    fi
    
    if [[ ${#AGENTS_TO_INSTALL[@]} -eq 0 ]]; then
        log_warn "No agents found to install"
        exit 0
    fi
    
    echo ""
    
    # Install each agent
    local installed=0
    for agent in "${AGENTS_TO_INSTALL[@]}"; do
        if install_agent "$agent"; then
            ((installed++))
        fi
    done
    
    echo ""
    
    # Update manifest
    if [[ -d "$PROJECT_ROOT/_bmad" ]]; then
        update_manifest
    else
        log_dim "  BMAD not found, skipping manifest update"
    fi
    
    echo ""
    
    # Detect and install for platforms
    local platforms=()
    
    if [[ -d "$PROJECT_ROOT/.claude" ]] || [[ -n "$CLAUDE_CODE" ]]; then
        platforms+=("claude-code")
    fi
    
    if [[ -d "$PROJECT_ROOT/.opencode" ]] || [[ -n "$OPENCODE" ]]; then
        platforms+=("opencode")
    fi
    
    if [[ -d "$PROJECT_ROOT/.windsurf" ]] || [[ -n "$WINDSURF" ]]; then
        platforms+=("windsurf")
    fi
    
    if [[ -d "$PROJECT_ROOT/.cursor" ]] || [[ -n "$CURSOR" ]]; then
        platforms+=("cursor")
    fi
    
    # Install platforms from CLI args
    for arg in "$@"; do
        case "$arg" in
            claude-code|opencode|windsurf|cursor)
                if [[ ! " ${platforms[*]} " =~ " $arg " ]]; then
                    platforms+=("$arg")
                fi
                ;;
        esac
    done
    
    # Install each platform
    if [[ ${#platforms[@]} -gt 0 ]]; then
        for platform in "${platforms[@]}"; do
            install_platform "$platform"
        done
    fi
    
    echo ""
    log_success "Installed $installed agent(s) successfully"
}

# Run main
main "$@"
