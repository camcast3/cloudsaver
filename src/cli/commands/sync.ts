import { Command } from 'commander';
import chalk from 'chalk';
import path from 'path';
import fs from 'fs-extra';
import { logger } from '../../core/logger.js';
import { getConfigManager } from '../../core/config.js';
import { platformDetector } from '../../core/platform.js';
import { emulatorDetector } from '../../core/emulator.js';
import { Emulator } from '../../core/emulator.js';

export const syncCommand = new Command('sync')
  .description('Sync emulator save files with the cloud')
  .option('--provider <name>', 'Cloud provider to use (optional if configured)')
  .option('--emulator <name>', 'Sync only a specific emulator')
  .option('--dry-run', 'Show what would be synced without actually syncing')
  .option('--force', 'Force sync even if no changes detected')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🔄 Starting save sync process...'));
      
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
      
      // Initialize the provider
      console.log(chalk.blue(`🔄 Initializing provider: ${provider}`));
      // TODO: Implement provider initialization based on the selected provider
      
      // For each emulator, sync save files
      let totalFiles = 0;
      let syncedFiles = 0;
      
      for (const emulator of emulatorsToSync) {
        console.log(chalk.blue(`\n🔄 Syncing ${emulator.name} save files...`));
        
        // Check for save files
        const saveFiles = [];
        for (const savePath of emulator.savePaths) {
          if (fs.existsSync(savePath)) {
            const files = await fs.readdir(savePath);
            for (const file of files) {
              const filePath = path.join(savePath, file);
              const stats = await fs.stat(filePath);
              
              if (stats.isFile()) {
                const matchesExtension = emulator.saveExtensions.some((ext: string) => 
                  file.toLowerCase().endsWith(ext.toLowerCase())
                );
                
                if (matchesExtension) {
                  saveFiles.push({
                    path: filePath,
                    relativePath: path.relative(savePath, filePath),
                    size: stats.size,
                    mtime: stats.mtime
                  });
                }
              }
            }
          }
        }
        
        totalFiles += saveFiles.length;
        
        if (saveFiles.length === 0) {
          console.log(chalk.yellow(`  No save files found for ${emulator.name}`));
          continue;
        }
        
        console.log(chalk.green(`  Found ${saveFiles.length} save files`));
        
        // In dry-run mode, just display what would be synced
        if (options.dryRun) {
          console.log(chalk.yellow('  Dry run - no files will be synced'));
          for (const file of saveFiles) {
            console.log(`  Would sync: ${file.relativePath} (${formatBytes(file.size)})`);
          }
          continue;
        }
        
        // Perform actual sync here
        for (const file of saveFiles) {
          try {
            // TODO: Replace this with actual cloud provider sync logic
            console.log(`  Syncing: ${file.relativePath} (${formatBytes(file.size)})`);
            
            // Simulate sync with a small delay
            await new Promise(resolve => setTimeout(resolve, 100));
            
            syncedFiles++;
          } catch (error: any) {
            console.log(chalk.red(`  ❌ Failed to sync ${file.relativePath}: ${error.message}`));
            logger.error(`Failed to sync file: ${file.path}`, error as Error);
          }
        }
      }
      
      // Summary
      if (options.dryRun) {
        console.log(chalk.green(`\n✅ Dry run complete. Would sync ${totalFiles} files`));
      } else {
        console.log(chalk.green(`\n✅ Sync complete. Synced ${syncedFiles}/${totalFiles} files`));
      }
      
      // Update last sync timestamp
      if (!options.dryRun && syncedFiles > 0) {
        await configManager.set('lastSync', new Date().toISOString());
      }
      
    } catch (error: any) {
      console.log(chalk.red(`❌ Sync failed: ${error.message}`));
      logger.error('Sync failed', error as Error);
    }
  });

// Helper function to format bytes
function formatBytes(bytes: number, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}
