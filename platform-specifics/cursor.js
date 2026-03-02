/**
 * Cursor Platform Handler
 * 
 * Configures BMAD agents for Cursor IDE.
 */

const fs = require('fs-extra');
const path = require('node:path');

/**
 * Install agents for Cursor
 */
async function install(options) {
  const { projectRoot, config, logger } = options;
  const chalk = require('chalk');

  try {
    logger.log(chalk.dim('  Configuring Cursor...'));

    // Cursor uses .cursor directory
    const cursorDir = path.join(projectRoot, '.cursor');
    const agentsDir = path.join(cursorDir, 'agents');
    
    if (!(await fs.pathExists(agentsDir))) {
      await fs.ensureDir(agentsDir);
    }

    // Copy agent files
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

    return true;
  } catch (error) {
    logger.warn(chalk.yellow(`    Warning: ${error.message}`));
    return false;
  }
}

module.exports = { install };
