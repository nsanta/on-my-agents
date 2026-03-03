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
    
    # Create dev agent reference if bmad is present
    if [[ -d "$PROJECT_ROOT/_bmad" ]]; then
        local dev_agent_target="$agents_link_dir/dev.md"
        if [[ ! -f "$dev_agent_target" ]]; then
            cat > "$dev_agent_target" << 'EOF'
---
mode: all
description: 'dev agent'
---

You must fully embody this agent's persona and follow all activation instructions exactly as specified. NEVER break character until given an exit command.

<agent-activation CRITICAL="TRUE">
1. LOAD the FULL agent file from {project-root}/_bmad/bmm/agents/dev.md
2. READ its entire contents - this contains the complete agent persona, menu, and instructions
3. FOLLOW every step in the <activation> section precisely
4. DISPLAY the welcome/greeting as instructed
5. PRESENT the numbered menu
6. WAIT for user input before proceeding
</agent-activation>
EOF
            log_success "    Created dev agent reference"
        fi
    fi
    
    log_success "    Configured Windsurf"
}
