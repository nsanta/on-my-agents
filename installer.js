/**
 * BMAD Agent Installer
 * 
 * Framework-agnostic installer for BMAD agents.
 * Works with or without BMAD module system.
 * 
 * @param {Object} options - Installation options
 * @param {string} options.projectRoot - The root directory of the target project
 * @param {Object} options.config - Module configuration (optional)
 * @param {Array<string>} options.installedIDEs - Array of IDE codes that were installed
 * @param {Object} options.logger - Logger instance for output
 * @param {Object} options.bmadContext - BMAD-specific context (optional)
 * @returns {Promise<boolean>} - Success status
 */
async function install(options) {
  const { 
    projectRoot, 
    config = {}, 
    installedIDEs = [], 
    logger, 
    bmadContext = null,
    agentsToInstall = null // Optional: specify which agents to install
  } = options;

  const chalk = await import('chalk').then(m => m.default || m);
  const fs = await import('fs-extra');
  const path = await import('node:path');

  const AGENT_SOURCE_DIR = bmadContext?.agentsSourceDir || path.join(__dirname, '../agents');
  const AGENT_MANIFEST_PATH = bmadContext?.manifestPath || path.join(projectRoot, '_bmad/_config/agent-manifest.csv');

  try {
    logger?.log?.(chalk.blue('📦 Installing BMAD Agents...'));

    // Get list of agents to install
    const availableAgents = await getAvailableAgents(AGENT_SOURCE_DIR, fs, path);
    const targetAgents = agentsToInstall || availableAgents;
    
    logger?.log?.(chalk.cyan(`Found ${targetAgents.length} agent(s) to install`));

    // Install each agent
    let installedCount = 0;
    for (const agent of targetAgents) {
      const installed = await installAgent({
        agent,
        projectRoot,
        sourceDir: AGENT_SOURCE_DIR,
        fs,
        path,
        chalk,
        logger
      });
      
      if (installed) installedCount++;
    }

    // Update agent manifest if it exists
    if (bmadContext?.updateManifest !== false) {
      await updateAgentManifest({
        agents: targetAgents,
        manifestPath: AGENT_MANIFEST_PATH,
        fs,
        path,
        chalk,
        logger,
        projectRoot
      });
    }

    // Run IDE-specific configurations
    if (installedIDEs.length > 0) {
      logger?.log?.(chalk.cyan(`Configuring agents for IDEs: ${installedIDEs.join(', ')}`));
      for (const ide of installedIDEs) {
        await configureForIDE(ide, { projectRoot, config, logger, fs, path, chalk, bmadContext });
      }
    }

    logger?.log?.(chalk.green(`✓ Installed ${installedCount}/${targetAgents.length} agents successfully`));
    return installedCount > 0;
    
  } catch (error) {
    logger?.error?.(chalk.red(`Error installing agents: ${error.message}`));
    return false;
  }
}

/**
 * Get list of available agents from source directory
 */
async function getAvailableAgents(sourceDir, fs, path) {
  if (!(await fs.pathExists(sourceDir))) {
    return [];
  }

  const entries = await fs.readdir(sourceDir, { withFileTypes: true });
  return entries
    .filter(entry => entry.isFile() && entry.name.endsWith('.md'))
    .map(entry => entry.name.replace('.md', ''));
}

/**
 * Install a single agent
 */
async function installAgent({ agent, projectRoot, sourceDir, fs, path, chalk, logger }) {
  const sourcePath = path.join(sourceDir, `${agent}.md`);
  const targetDir = path.join(projectRoot, '_bmad/bmb/agents');
  const targetPath = path.join(targetDir, `${agent}.md`);

  try {
    // Ensure target directory exists
    if (!(await fs.pathExists(targetDir))) {
      await fs.ensureDir(targetDir);
      logger?.log?.(chalk.yellow(`Created directory: _bmad/bmb/agents/`));
    }

    // Check if agent already exists
    if (await fs.pathExists(targetPath)) {
      logger?.log?.(chalk.dim(`  Agent '${agent}' already exists, skipping`));
      return true; // Consider existing as success
    }

    // Copy agent file
    await fs.copy(sourcePath, targetPath);
    logger?.log?.(chalk.green(`  ✓ Installed agent: ${agent}`));
    return true;
    
  } catch (error) {
    logger?.warn?.(chalk.yellow(`  ⚠ Failed to install agent '${agent}': ${error.message}`));
    return false;
  }
}

/**
 * Update agent manifest CSV
 */
async function updateAgentManifest({ agents, manifestPath, fs, path, chalk, logger, projectRoot }) {
  try {
    // Ensure manifest directory exists
    const manifestDir = path.dirname(manifestPath);
    if (!(await fs.pathExists(manifestDir))) {
      await fs.ensureDir(manifestDir);
    }

    // Read existing manifest or create new one
    let manifestContent = '';
    if (await fs.pathExists(manifestPath)) {
      manifestContent = await fs.readFile(manifestPath, 'utf-8');
    } else {
      // Create basic header
      manifestContent = '#WV|name,displayName,title,icon,role,identity,communicationStyle,principles,module,path\n';
    }

    // Parse existing entries to avoid duplicates
    const existingAgents = parseManifestAgents(manifestContent);
    const newAgents = [];

    for (const agent of agents) {
      if (!existingAgents.includes(agent)) {
        newAgents.push(agent);
      }
    }

    if (newAgents.length === 0) {
      logger?.log?.(chalk.dim('  All agents already registered in manifest'));
      return;
    }

    // Add new agents to manifest
    const agentEntries = await Promise.all(
      newAgents.map(async (agent) => {
        const agentPath = path.join(projectRoot, '_bmad/bmb/agents', `${agent}.md`);
        const agentContent = await fs.readFile(agentPath, 'utf-8');
        return formatAgentEntry(agent, agentContent);
      })
    );

    manifestContent += agentEntries.join('\n');
    await fs.writeFile(manifestPath, manifestContent, 'utf-8');
    logger?.log?.(chalk.green(`  ✓ Updated manifest with ${newAgents.length} new agent(s)`));
    
  } catch (error) {
    logger?.warn?.(chalk.yellow(`  ⚠ Could not update manifest: ${error.message}`));
  }
}

/**
 * Parse agent names from manifest content
 */
function parseManifestAgents(manifestContent) {
  const agents = [];
  const lines = manifestContent.split('\n');
  
  for (const line of lines) {
    // Skip header and empty lines
    if (line.startsWith('#') || !line.trim()) continue;
    
    // Parse CSV - first field is agent name
    const match = line.match(/^"?([^",]+)"?/);
    if (match) {
      agents.push(match[1]);
    }
  }
  
  return agents;
}

/**
 * Format agent entry for manifest
 */
async function formatAgentEntry(agentName, agentContent) {
  // Extract metadata from agent file
  const nameMatch = agentContent.match(/name:\s*"([^"]+)"/) || [null, agentName];
  const titleMatch = agentContent.match(/title:\s*"([^"]+)"/) || [null, 'Agent'];
  const iconMatch = agentContent.match(/icon:\s*"([^"]+)"/) || [null, '🤖'];
  
  // Generate hash prefix (simplified)
  const hash = generateHash(agentName);
  
  return `${hash}|"${agentName}","${nameMatch[1]}","${titleMatch[1]}","${iconMatch[1]}","Agent","Agent definition in ${agentName}.md","Direct and efficient.","- Follow BMAD patterns","bmb","_bmad/bmb/agents/${agentName}.md"`;
}

/**
 * Generate simple hash for CSV line
 */
function generateHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0;
  }
  // Convert to positive and take first 2 chars
  return '#' + Math.abs(hash).toString(36).substring(0, 2).toUpperCase();
}

/**
 * Configure agents for specific IDE
 */
async function configureForIDE(ide, { projectRoot, config, logger, fs, path, chalk, bmadContext }) {
  const platformCodes = bmadContext?.platformCodes;
  
  // Validate platform if codes available
  if (platformCodes && !platformCodes.isValidPlatform(ide)) {
    logger?.warn?.(chalk.yellow(`  Unknown platform: '${ide}'. Skipping.`));
    return;
  }

  const platformSpecificPath = path.join(__dirname, 'platform-specifics', `${ide}.js`);

  try {
    if (await fs.pathExists(platformSpecificPath)) {
      const platformHandler = await import(platformSpecificPath);
      if (typeof platformHandler.install === 'function') {
        await platformHandler.install({ projectRoot, config, logger });
        logger?.log?.(chalk.green(`  ✓ Configured agents for ${ide}`));
      }
    }
  } catch (error) {
    logger?.warn?.(chalk.yellow(`  Warning: Could not configure ${ide}: ${error.message}`));
  }
}

/**
 * Standalone usage - can be run directly with node
 */
if (require.main === module) {
  const args = process.argv.slice(2);
  
  // Simple CLI interface
  const projectRoot = args[0] || process.cwd();
  const agents = args.slice(1);
  
  const logger = {
    log: (...args) => console.log(...args),
    warn: (...args) => console.warn(...args),
    error: (...args) => console.error(...args)
  };
  
  install({
    projectRoot,
    agentsToInstall: agents.length > 0 ? agents : null,
    logger
  }).then(success => {
    process.exit(success ? 0 : 1);
  });
}

module.exports = { install };
