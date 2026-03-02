#!/bin/bash
# OpenCode Platform Handler

platform_install() {
    local opencode_dir="$PROJECT_ROOT/.opencode"
    local agents_link_dir="$opencode_dir/agents"
    
    # Create .opencode directory
    mkdir -p "$agents_link_dir"
    
    # Link/copy agents
    local source_agents="$PROJECT_ROOT/_bmad/bmb/agents"
    if [[ -d "$source_agents" ]]; then
        for agent_file in "$source_agents"/*.md; do
            if [[ -f "$agent_file" ]]; then
                local agent_name
                agent_name=$(basename "$agent_file")
                local target="$agents_link_dir/$agent_name"
                
                if [[ ! -f "$target" ]]; then
                    cp "$agent_file" "$target"
                    log_success "    Linked agent: ${agent_name%.md}"
                fi
            fi
        done
    fi
    
    # Create settings if needed
    if [[ ! -f "$opencode_dir/settings.md" ]]; then
        cat > "$opencode_dir/settings.md" << 'EOF'
# OpenCode Settings

## BMAD Agents
BMAD agents are available in:
- `_bmad/bmb/agents/` - Main agent definitions
- `.opencode/agents/` - IDE-specific agent copies

## Quick Access
- Agents are registered in `_bmad/_config/agent-manifest.csv`
- Use OpenCode's agent picker to select BMAD agents
EOF
        log_success "    Created OpenCode settings"
    fi
}
