# BMAD Agent Installer

A framework-agnostic installer for BMAD agents that works with or without the BMAD module system.

## Overview

This installer:
- Copies agent definition files to the target project
- Updates the BMAD agent manifest (if it exists)
- Configures platform-specific integrations

## Installation Options

### 1. As BMAD Module Installer

If you're creating a BMAD module that includes agents, reference this installer:

```yaml
# module.yaml
installer:
  type: agents
  source: _bmad/bmb/agents/_agent-installer
```

### 2. Standalone Installation

Run directly from command line:

```bash
# Install all agents
node _bmad/bmb/agents/_agent-installer/installer.js /path/to/project

# Install specific agents
node _bmad/bmb/agents/_agent-installer/installer.js /path/to/project archibald ethan
```

### 3. As NPM Package

```javascript
const { install } = require('./_bmad/bmb/agents/_agent-installer/installer.js');

await install({
  projectRoot: '/my/project',
  config: { /* module config */ },
  installedIDEs: ['claude-code', 'windsurf'],
  logger: console
});
```

### 4. BMAD Context

For full BMAD integration:

```javascript
const { install } = require('./_bmad/bmb/agents/_agent-installer/bmad-installer.js');

await install({
  projectRoot: '/my/project',
  config: { /* module config */ },
  installedIDEs: ['claude-code'],
  logger: console
});
```

## Directory Structure

```
_agent-installer/
├── installer.js           # Framework-agnostic installer
├── bmad-installer.js     # BMAD-specific wrapper
├── README.md             # This file
└── platform-specifics/    # IDE-specific configurations
    ├── claude-code.js    # Claude Code integration
    ├── opencode.js       # OpenCode integration
    ├── windsurf.js       # Windsurf IDE integration
    └── cursor.js         # Cursor IDE integration
```
_agent-installer/
├── installer.js           # Framework-agnostic installer
├── bmad-installer.js     # BMAD-specific wrapper
├── README.md             # This file
└── platform-specifics/    # IDE-specific configurations
    ├── claude-code.js    # Claude Code integration
    ├── windsurf.js       # Windsurf IDE integration
    └── cursor.js         # Cursor IDE integration
```

## Configuration

### Options

| Option | Type | Description |
|--------|------|-------------|
| `projectRoot` | string | Target project root directory |
| `config` | object | Module configuration |
| `installedIDEs` | array | List of installed IDEs |
| `logger` | object | Logger with log/warn/error methods |
| `agentsToInstall` | array | Specific agents to install (optional) |
| `bmadContext` | object | BMAD-specific context |

### BMAD Context

```javascript
{
  updateManifest: true,    // Update agent-manifest.csv
  createBackup: true,      // Backup before overwriting
  agentsSourceDir: '...',  // Override source directory
  manifestPath: '...'      // Override manifest path
}
```

## Platform Support

- ✅ Claude Code
- ✅ OpenCode
- ✅ Windsurf  
- ✅ Cursor
- ✅ VS Code (coming soon)

- ✅ Claude Code
- ✅ Windsurf  
- ✅ Cursor
- ✅ VS Code (coming soon)

## Adding Platform Handlers

Create a file in `platform-specifics/{platform-code}.js`:

```javascript
async function install(options) {
  const { projectRoot, config, logger } = options;
  // Your configuration logic
  return true;
}

module.exports = { install };
```

## Examples

### Install all agents to new project

```bash
node _bmad/bmb/agents/_agent-installer/installer.js /my-new-project
```

### Install specific agents

```bash
node installer.js /project archibald ethan
```

### Programmatic usage

```javascript
const installer = require('./installer.js');

await installer.install({
  projectRoot: './my-project',
  logger: {
    log: console.log.bind(console),
    warn: console.warn.bind(console),
    error: console.error.bind(console)
  }
});
```

## Agent Manifest

The installer automatically updates `_bmad/_config/agent-manifest.csv` with new agents:

```csv
#WV|name,displayName,title,icon,role,identity,communicationStyle,principles,module,path
...
#AB|"archibald","Archibald","Enhanced Agent Architect","🏗️",...
```

## Troubleshooting

### "Unknown platform" warning

This is normal - some IDEs don't have specific handlers yet. Agents still install correctly.

### Agent not appearing in manifest

Check that:
1. Agent .md file exists in `_bmad/bmb/agents/`
2. Agent file has valid `name:` and `title:` fields

### Installation fails silently

Run with verbose logging:
```javascript
const logger = {
  log: (...args) => console.log('[INFO]', ...args),
  warn: (...args) => console.warn('[WARN]', ...args),
  error: (...args) => console.error('[ERROR]', ...args)
};
```
