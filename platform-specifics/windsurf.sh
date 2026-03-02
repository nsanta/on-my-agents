#!/bin/bash
# Windsurf Platform Handler

platform_install() {
    local windsurf_dir="$PROJECT_ROOT/.windsurf"
    local agents_link_dir="$windsurf_dir/agents"
    
    # Create .windsurf directory
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
    
    log_success "    Configured Windsurf"
}
