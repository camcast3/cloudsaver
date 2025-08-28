import { Command } from 'commander';
import chalk from 'chalk';
import { logger } from '../../core/logger.js';
import { getConfigManager, CloudSaverConfig } from '../../core/config.js';

export const configCommand = new Command('config')
  .description('Manage configuration settings');

// Get configuration
configCommand
  .command('get')
  .description('Get configuration value(s)')
  .argument('[key]', 'Configuration key to get (omit to get all)')
  .action(async (key?: string) => {
    try {
      const configManager = await getConfigManager();
      
      if (!key) {
        // Get all config
        const config = configManager.get();
        console.log(chalk.blue('📝 Current Configuration:'));
        for (const [configKey, value] of Object.entries(config)) {
          console.log(`${chalk.green(configKey)}: ${formatValue(value)}`);
        }
      } else {
        // Get specific key
        if (isValidConfigKey(key)) {
          const value = configManager.getValue(key as keyof CloudSaverConfig);
          console.log(`${chalk.green(key)}: ${formatValue(value)}`);
        } else {
          console.log(chalk.red(`❌ Invalid configuration key: ${key}`));
          showValidKeys();
        }
      }
    } catch (error: any) {
      console.log(chalk.red(`❌ Failed to get configuration: ${error.message}`));
      logger.error('Failed to get configuration', error as Error);
    }
  });

// Set configuration
configCommand
  .command('set')
  .description('Set configuration value')
  .argument('<key>', 'Configuration key to set')
  .argument('<value>', 'Value to set')
  .action(async (key, value) => {
    try {
      const configManager = await getConfigManager();
      
      if (!isValidConfigKey(key)) {
        console.log(chalk.red(`❌ Invalid configuration key: ${key}`));
        showValidKeys();
        return;
      }
      
      // Parse the value appropriately based on key
      const parsedValue = parseValueForKey(key as keyof CloudSaverConfig, value);
      
      // Set the value
      await configManager.set(key as keyof CloudSaverConfig, parsedValue);
      console.log(chalk.green(`✅ Successfully set ${key} to ${formatValue(parsedValue)}`));
      
    } catch (error: any) {
      console.log(chalk.red(`❌ Failed to set configuration: ${error.message}`));
      logger.error('Failed to set configuration', error as Error);
    }
  });

// Reset configuration
configCommand
  .command('reset')
  .description('Reset configuration to defaults')
  .option('--force', 'Force reset without confirmation')
  .action(async (options) => {
    try {
      if (!options.force) {
        console.log(chalk.yellow('⚠️  This will reset all configuration to default values.'));
        console.log(chalk.yellow('Run with --force to confirm.'));
        return;
      }
      
      const configManager = await getConfigManager();
      configManager.reset();
      console.log(chalk.green('✅ Configuration reset to defaults'));
      
    } catch (error: any) {
      console.log(chalk.red(`❌ Failed to reset configuration: ${error.message}`));
      logger.error('Failed to reset configuration', error as Error);
    }
  });

// Utility functions
function isValidConfigKey(key: string): boolean {
  const validKeys = [
    'cloudProvider',
    'syncRoot',
    'logLevel',
    'customPaths',
    'emulatorPaths',
    'scanDirs',
    'ignoreDirs',
    'platform',
    'autoSync',
    'lastSync'
  ];
  return validKeys.includes(key);
}

function showValidKeys(): void {
  console.log(chalk.yellow('Valid configuration keys:'));
  console.log('  cloudProvider - Cloud storage provider name');
  console.log('  syncRoot      - Root directory for sync operations');
  console.log('  logLevel      - Logging level (debug, verbose, info, warn, error)');
  console.log('  customPaths   - Custom paths for syncing');
  console.log('  emulatorPaths - Custom emulator paths');
  console.log('  scanDirs      - Directories to scan for save files');
  console.log('  ignoreDirs    - Directories to ignore during scan');
  console.log('  platform      - Emulation platform type');
  console.log('  autoSync      - Whether to enable automatic sync');
}

function formatValue(value: any): string {
  if (value === undefined || value === null) {
    return chalk.italic('(not set)');
  } else if (typeof value === 'object') {
    return JSON.stringify(value, null, 2);
  } else if (typeof value === 'boolean') {
    return value ? chalk.green('true') : chalk.red('false');
  } else {
    return String(value);
  }
}

function parseValueForKey(key: keyof CloudSaverConfig, value: string): any {
  switch (key) {
    case 'autoSync':
      return value.toLowerCase() === 'true';
    case 'customPaths':
    case 'emulatorPaths':
    case 'scanDirs':
    case 'ignoreDirs':
      try {
        return JSON.parse(value);
      } catch (e) {
        throw new Error(`Invalid JSON format for ${key}`);
      }
    case 'logLevel':
      if (!['debug', 'verbose', 'info', 'warn', 'error'].includes(value)) {
        throw new Error('Invalid log level. Must be one of: debug, verbose, info, warn, error');
      }
      return value;
    case 'platform':
      if (!['emudeck', 'retropie', 'batocera', 'lakka', 'emulationstation', 'generic'].includes(value)) {
        throw new Error('Invalid platform. Must be one of: emudeck, retropie, batocera, lakka, emulationstation, generic');
      }
      return value;
    default:
      return value;
  }
}
