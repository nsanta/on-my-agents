/**
 * OpenCode Platform Handler
 * 
 * Configures BMAD agents for OpenCode IDE.
 */

const fs = require('fs-extra');
const path = require('node:path');

/**
 * Install agents for OpenCode
 */
async function install(options) {
  const { projectRoot, config, logger } = options;
  const chalk = require('chalk');

  try {
    logger.log(chalk.dim('  Configuring OpenCode...'));

    // OpenCode uses .opencode directory
    const opencodeDir = path.join(projectRoot, '.opencode');
    const agentsDir = path.join(opencodeDir, 'agents');
    
    if (!(await fs.pathExists(agentsDir))) {
      await fs.ensureDir(agentsDir);
    }

    // Copy agent files to .opencode/agents/
    const sourceAgentsDir = path.join(projectRoot, '_bmad/bmb/agents');
    if (await fs.pathExists(sourceAgentsDir)) {
      const agentFiles = await fs.readdir(sourceAgentsDir);
      
      for (const file of agentFiles) {
        if (file.endsWith('.md')) {
          const agentName = file.replace('.md', '');
          const targetPath = path.join(agentsDir, file);
          
          if (!(await fs.pathExists(targetPath))) {
            await fs.copy(path.join(sourceAgentsDir, file), targetPath);
            logger.log(chalk.green(`    ✓ Linked agent: ${agentName}`));
          }
        }
      }
    }

    // Also ensure agents are in the BMAD location for OpenCode
    const bmadAgentsDir = path.join(projectRoot, '_bmad/bmb/agents');
    if (!(await fs.pathExists(bmadAgentsDir))) {
      await fs.ensureDir(bmadAgentsDir);
      
      // Copy from source if available
      if (await fs.pathExists(sourceAgentsDir)) {
        await fs.copy(sourceAgentsDir, bmadAgentsDir);
        logger.log(chalk.green(`    ✓ Copied agents to _bmad/bmb/agents/`));
      }
    }

    // Create OpenCode settings if needed
    const opencodeSettingsPath = path.join(opencodeDir, 'settings.md');
    if (!(await fs.pathExists(opencodeSettingsPath))) {
      await fs.writeFile(opencodeSettingsPath, `# OpenCode Settings

## BMAD Agents
BMAD agents are available in:
- \`_bmad/bmb/agents/\` - Main agent definitions
- \`.opencode/agents/\` - IDE-specific agent copies

## Quick Access
- Agents are registered in \`_bmad/_config/agent-manifest.csv\`
- Use OpenCode's agent picker to select BMAD agents

## BMAD Modules
- **BMB** - Agent & Module Builder
- **BMM** - Product & Project Management
`, 'utf-8');
      logger.log(chalk.green(`    ✓ Created OpenCode settings`));
    }

    return true;
  } catch (error) {
    logger.warn(chalk.yellow(`    Warning: ${error.message}`));
    return false;
  }
}

module.exports = { install };
