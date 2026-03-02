/**
 * Claude Code Platform Handler
 * 
 * Configures BMAD agents for Claude Code IDE.
 */

const fs = require('fs-extra');
const path = require('node:path');

/**
 * Install agents for Claude Code
 */
async function install(options) {
  const { projectRoot, config, logger } = options;
  const chalk = require('chalk');

  try {
    logger.log(chalk.dim('  Configuring Claude Code...'));

    // Claude Code uses .claude directory
    const claudeDir = path.join(projectRoot, '.claude');
    const agentsDir = path.join(claudeDir, 'agents');
    
    if (!(await fs.pathExists(agentsDir))) {
      await fs.ensureDir(agentsDir);
    }

    // Create agent symlinks or copies for Claude Code
    const sourceAgentsDir = path.join(projectRoot, '_bmad/bmb/agents');
    if (await fs.pathExists(sourceAgentsDir)) {
      const agentFiles = await fs.readdir(sourceAgentsDir);
      
      for (const file of agentFiles) {
        if (file.endsWith('.md')) {
          const agentName = file.replace('.md', '');
          const targetPath = path.join(agentsDir, file);
          
          // Create symlink or copy
          if (!(await fs.pathExists(targetPath))) {
            await fs.copy(path.join(sourceAgentsDir, file), targetPath);
            logger.log(chalk.green(`    ✓ Linked agent: ${agentName}`));
          }
        }
      }
    }

    // Create claude.md settings if needed
    const claudeSettingsPath = path.join(claudeDir, 'settings.md');
    if (!(await fs.pathExists(claudeSettingsPath))) {
      await fs.writeFile(claudeSettingsPath, `# Claude Code Settings

## BMAD Agents
Agents are available in .claude/agents/

## Quick Commands
- /agents - List available agents
- /bmb - Run BMB workflows
`, 'utf-8');
    }

    return true;
  } catch (error) {
    logger.warn(chalk.yellow(`    Warning: ${error.message}`));
    return false;
  }
}

module.exports = { install };
