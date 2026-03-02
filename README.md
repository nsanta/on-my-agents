# BMAD Agent Installer

A pure bash installer for BMAD agents. No Node.js required.

## Quick Install

```bash
# Install to current directory
curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash

# Install to specific directory
curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s /path/to/project

# Install specific agents
curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s /path/to/project archibald ethan
```

## Clone & Run

```bash
git clone git@github.com:nsanta/on-my-agents.git
cd on-my-agents

# Install all agents
./install.sh /path/to/project

# Install specific agents
./install.sh /path/to/project archibald ethan
```

## Usage

```bash
./install.sh [project_root] [agents...]

# Install all agents to current directory
./install.sh .

# Install all agents to specific directory
./install.sh /my/project

# Install specific agents
./install.sh /my/project archibald ethan
```

## Directory Structure

```
on-my-agents/
├── install.sh              # Main installer (bash)
├── README.md               # This file
├── agents/                 # Place agent .md files here
└── platform-specifics/      # IDE-specific handlers
    ├── claude-code.sh     # Claude Code
    ├── opencode.sh        # OpenCode
    ├── windsurf.sh        # Windsurf
    └── cursor.sh          # Cursor
```

## Adding Agents

Place your agent `.md` files in the `agents/` directory:

```bash
cp /path/to/my-agent.md agents/
```

Then run the installer to distribute to projects.

## Platform Detection

The installer automatically detects platforms by checking for:
- `.claude/` directory → Claude Code
- `.opencode/` directory → OpenCode
- `.windsurf/` directory → Windsurf
- `.cursor/` directory → Cursor

You can also explicitly specify platforms:

```bash
./install.sh /project claude-code opencode
```

## Manual Platform Install

```bash
# Install for specific platform only
./install.sh /project opencode
```

## Requirements

- Bash 4.0+
- Standard Unix tools: `cp`, `mkdir`, `grep`, `sed`, `md5sum`

## What It Does

1. **Copies agent files** to `_bmad/bmb/agents/`
2. **Updates manifest** at `_bmad/_config/agent-manifest.csv`
3. **Configures platforms** by copying agents to IDE-specific directories

## Examples

### Install to new project

```bash
curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s ~/my-new-project
```

### CI/CD Usage

```bash
- name: Install BMAD Agents
  run: |
    curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s ${{ github.workspace }}
```

### Docker

```dockerfile
RUN curl -sL https://raw.githubusercontent.com/nsanta/on-my-agents/main/install.sh | bash -s /app
```
