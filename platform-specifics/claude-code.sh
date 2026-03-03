#!/bin/bash
# Claude Code Platform Handler

platform_install() {
    local claude_dir="$PROJECT_ROOT/.claude"
    local agents_link_dir="$claude_dir/agents"
    
    # Create .claude directory
    mkdir -p "$agents_link_dir"
    
    # Check if bmad is present - if so, use dev agent instead of direct installation
    if [[ -d "$PROJECT_ROOT/_bmad" ]]; then
        log_dim "    BMAD detected - using dev agent loader"
    else
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
    fi
    
    # Create agent loader references for each agent if bmad is present
    if [[ -d "$PROJECT_ROOT/_bmad" ]]; then
        local bmad_agents_dir="$PROJECT_ROOT/_bmad/bmm/agents"
        if [[ -d "$bmad_agents_dir" ]]; then
            for agent_file in "$bmad_agents_dir"/*.md; do
                if [[ -f "$agent_file" ]]; then
                    local agent_name
                    agent_name=$(basename "$agent_file" .md)
                    local loader_target="$agents_link_dir/$agent_name.md"
                    
                    if [[ ! -f "$loader_target" ]]; then
                        cat > "$loader_target" << EOF
---
mode: all
description: '$agent_name agent'
---

You must fully embody this agent's persona and follow all activation instructions exactly as specified. NEVER break character until given an exit command.

<agent-activation CRITICAL="TRUE">
1. LOAD the FULL agent file from {project-root}/_bmad/bmm/agents/$agent_name.md
2. READ its entire contents - this contains the complete agent persona, menu, and instructions
3. FOLLOW every step in the <activation> section precisely
4. DISPLAY the welcome/greeting as instructed
5. PRESENT the numbered menu
6. WAIT for user input before proceeding
</agent-activation>
EOF
                        log_success "    Created $agent_name agent loader"
                    fi
                fi
            done
        fi
    fi
    
    # Create settings if needed
    if [[ ! -f "$claude_dir/settings.md" ]]; then
        cat > "$claude_dir/settings.md" << 'EOF'
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
