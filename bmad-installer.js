/**
 * BMAD Agent Module Installer
 * 
 * BMAD-specific wrapper for the agent installer.
 * Provides integration with BMAD module system.
 * 
 * Usage:
 *   const { install } = require('./bmad-installer');
 *   await install({ projectRoot, config, installedIDEs, logger });
 */

const path = require('node:path');
const fs = require('fs-extra');

/**
 * Create BMAD-context-aware installer
 * @param {Object} bmadContext - BMAD-specific context
 * @returns {Function} Installer function
 */
function createBMADInstaller(bmadContext = {}) {
  return async function install(options) {
    const { projectRoot, config = {}, installedIDEs = [], logger } = options;
    
    // Load platform codes if available
    let platformCodes = null;
    try {
      platformCodes = require(path.join(__dirname, '../../../../tools/cli/lib/platform-codes'));
    } catch (e) {
      // Platform codes not available - will skip IDE-specific config
    }

    // Build full context for agent installer
    const fullContext = {
      ...bmadContext,
      platformCodes,
      manifestPath: path.join(projectRoot, '_bmad/_config/agent-manifest.csv'),
      agentsSourceDir: bmadContext.agentsSourceDir || path.join(__dirname, '../agents')
    };

    // Load BMAD config if available
    let bmadConfig = {};
    try {
      const configPath = path.join(projectRoot, '_bmad/bmb/config.yaml');
      if (await fs.pathExists(configPath)) {
        const yaml = require('js-yaml');
        const configContent = await fs.readFile(configPath, 'utf-8');
        bmadConfig = yaml.load(configContent) || {};
      }
    } catch (e) {
      // Config not available - use provided config
      bmadConfig = config;
    }

    // Merge configs
    const mergedConfig = { ...bmadConfig, ...config };

    // Call the main installer
    const mainInstaller = require('./installer');
    return mainInstaller.install({
      projectRoot,
      config: mergedConfig,
      installedIDEs,
      logger,
      bmadContext: fullContext
    });
  };
}

// Default export - create installer with default BMAD context
const install = createBMADInstaller({
  updateManifest: true,
  createBackup: true
});

// Also export the factory for customization
module.exports = { 
  install,
  createBMADInstaller,
  // Re-export from main installer
  agentInstaller: require('./installer')
};
