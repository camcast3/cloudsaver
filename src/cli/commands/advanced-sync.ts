import { Command } from 'commander';
import chalk from 'chalk';
import path from 'path';
import fs from 'fs-extra';
import { exec } from 'child_process';
import util from 'util';
import { logger } from '../../core/logger.js';
import { getConfigManager } from '../../core/config.js';
import { platformDetector } from '../../core/platform.js';
import { emulatorDetector } from '../../core/emulator.js';
import { Emulator } from '../../core/emulator.js';

// Promisify exec; allow tests to override via a setter
type ExecAsync = (command: string, options?: any) => Promise<{ stdout: string; stderr: string }>;
let execAsync: ExecAsync = util.promisify(exec);

// Test-only hook to override execAsync
export const __setExecAsyncForTests = (mock: ExecAsync) => {
  execAsync = mock;
};

// Helper function to check if rclone is installed
const isRcloneInstalled = async (): Promise<boolean> => {
  try {
    await execAsync('rclone --version');
    return true;
  } catch (error) {
    return false;
  }
};

// Function to handle syncing for a specific emulator
export const syncEmulator = async (
  emulator: Emulator, 
  direction: 'download' | 'upload', 
  options: any
): Promise<boolean> => {
  try {
    // Get configuration
    const configManager = await getConfigManager();
    const config = configManager.get();
    
    // Check if we have a configured cloud provider
    const provider = options.provider || config.cloudProvider;
    if (!provider) {
      console.log(chalk.red('❌ No cloud provider configured'));
      return false;
    }
    
    // Get the sync root directory
    const syncRoot = config.syncRoot;
    
    // Check if emulator has save paths
    if (!emulator.savePaths || emulator.savePaths.length === 0) {
      console.log(chalk.yellow(`⚠️ No save paths found for ${emulator.name}`));
      return false;
    }
    
    // Get first valid save path
    const savePath = emulator.savePaths.find(p => fs.existsSync(p));
    if (!savePath) {
      if (direction === 'upload') {
        console.log(chalk.yellow(`⚠️ No existing save path found for ${emulator.name}`));
        return false;
      } else {
        // For download, create the first path
        fs.ensureDirSync(emulator.savePaths[0]);
      }
    }
    
    const localPath = savePath || emulator.savePaths[0];
    const remotePath = `${provider}:${config.syncRoot}/${emulator.id}`;
    
    console.log(chalk.blue(`🔄 Syncing ${emulator.name} saves (${direction})...`));
    console.log(chalk.gray(`   Local path: ${localPath}`));
    console.log(chalk.gray(`   Remote path: ${remotePath}`));
    
    // Build the rclone command
    let rcloneCmd = ['rclone', 'sync'];
    
    if (options.dryRun) {
      rcloneCmd.push('--dry-run');
    }
    
    if (options.verbose) {
      rcloneCmd.push('--verbose');
    }
    
    // Set the source and destination based on direction
    if (direction === 'download') {
      // From remote to local
      rcloneCmd = [...rcloneCmd, remotePath, localPath];
    } else {
      // From local to remote
      rcloneCmd = [...rcloneCmd, localPath, remotePath];
    }
    
    // Execute the rclone command
    const cmdString = rcloneCmd.join(' ');
    console.log(chalk.gray(`   Running: ${cmdString}`));
    
    try {
      const { stdout, stderr } = await execAsync(cmdString, { timeout: 300000 }); // 5 minute timeout
      
      if (stderr && !options.dryRun) {
        console.log(chalk.yellow(`⚠️ Rclone warnings: ${stderr}`));
      }
      
      if (options.verbose) {
        console.log(chalk.gray(stdout));
      }
      
      console.log(chalk.green(`✅ Successfully ${direction === 'download' ? 'downloaded' : 'uploaded'} ${emulator.name} saves`));
      return true;
    } catch (error: any) {
      console.log(chalk.red(`❌ Failed to ${direction} ${emulator.name} saves: ${error.message}`));
      logger.error(`Failed to ${direction} ${emulator.name} saves`, error as Error);
      return false;
    }
  } catch (error: any) {
    console.log(chalk.red(`❌ Error during sync: ${error.message}`));
    logger.error('Error during sync', error as Error);
    return false;
  }
};

export const advancedSyncCommand = new Command('advanced-sync')
  .description('Advanced sync of emulator save files (similar to EmuDeck)')
  .option('--provider <name>', 'Cloud provider to use (optional if configured)')
  .option('--emulator <name>', 'Sync only a specific emulator')
  .option('--direction <direction>', 'Sync direction: "download" (cloud to local) or "upload" (local to cloud)', 'upload')
  .option('--dry-run', 'Show what would be synced without actually syncing')
  .option('--verbose', 'Display detailed output')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🔄 Starting advanced save sync process...'));
      
      // Check if rclone is installed
      if (!await isRcloneInstalled()) {
        console.log(chalk.red('❌ rclone is not installed'));
        console.log(chalk.yellow('Please install rclone first:'));
        console.log(chalk.yellow('  - Visit https://rclone.org/install/ for instructions'));
        console.log(chalk.yellow('  - Windows: Download from https://rclone.org/downloads/'));
        console.log(chalk.yellow('  - Linux/macOS: curl https://rclone.org/install.sh | sudo bash'));
        return;
      }
      
      // Get configuration
      const configManager = await getConfigManager();
      const config = configManager.get();
      
      // Check if we have a configured cloud provider
      let provider = options.provider || config.cloudProvider;
      if (!provider) {
        console.log(chalk.red('❌ No cloud provider configured'));
        console.log(chalk.yellow('Please configure a provider with:'));
        console.log(chalk.yellow('  cloudsaver config set cloudProvider <provider>'));
        return;
      }
      
      // Validate sync direction
      const direction = options.direction.toLowerCase();
      if (direction !== 'upload' && direction !== 'download') {
        console.log(chalk.red('❌ Invalid sync direction'));
        console.log(chalk.yellow('Valid directions are: "download" or "upload"'));
        return;
      }
      
      // Detect platform
      const platform = await platformDetector.detectPlatform();
      console.log(chalk.green(`✅ Detected platform: ${platform.name}`));
      
      // Detect emulators
      const emulatorsMap = await emulatorDetector.detectEmulators(platform);
      const emulators = Array.from(emulatorsMap.values());
      console.log(chalk.green(`✅ Detected ${emulators.length} emulator(s)`));
      
      // Filter emulators if specified
      let emulatorsToSync = emulators;
      if (options.emulator) {
        emulatorsToSync = emulators.filter((emu: Emulator) => 
          emu.id.toLowerCase() === options.emulator.toLowerCase() ||
          emu.name.toLowerCase() === options.emulator.toLowerCase()
        );
        
        if (emulatorsToSync.length === 0) {
          console.log(chalk.red(`❌ No emulator found matching "${options.emulator}"`));
          return;
        }
      }
      
      // Initialize summary counters
      let successCount = 0;
      let failCount = 0;
      
      // Sync each emulator
      for (const emulator of emulatorsToSync) {
        const success = await syncEmulator(emulator, direction as 'download' | 'upload', options);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }
      
      // Summary
      if (options.dryRun) {
        console.log(chalk.green(`\n✅ Dry run complete. Would sync ${emulatorsToSync.length} emulator(s)`));
      } else {
        console.log(chalk.green(`\n✅ Sync complete. Synced ${successCount}/${emulatorsToSync.length} emulator(s)`));
        if (failCount > 0) {
          console.log(chalk.yellow(`⚠️ ${failCount} emulator(s) failed to sync`));
        }
      }
      
      // Update last sync timestamp if we did an actual sync
      if (!options.dryRun && successCount > 0) {
        await configManager.set('lastSync', new Date().toISOString());
      }
      
    } catch (error: any) {
      console.log(chalk.red(`❌ Sync failed: ${error.message}`));
      logger.error('Sync failed', error as Error);
    }
  });
