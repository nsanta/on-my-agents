#!/bin/bash
# Claude Code Platform Handler

platform_install() {
    local opencode_dir="$PROJECT_ROOT/.claude"
    local agents_link_dir="$opencode_dir/agents"
    
    # Create .claude directory
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
# Claude Code Settings

## BMAD Agents
Agents are available in .claude/agents/

## Quick Commands
- /agents - List available agents
- /bmb - Run BMB workflows
EOF
        log_success "    Created Claude Code settings"
    fi
}
