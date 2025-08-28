import { Command } from 'commander';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { logger } from '../../core/logger.js';
import { ConfigManager } from '../../core/config.js';
import { emulatorDetector } from '../../core/emulator.js';
import { platformDetector } from '../../core/platform.js';

export const pathsCommand = new Command('paths')
  .description('Manage emulator save paths')
  .addCommand(
    new Command('add')
      .description('Add a custom save path for an emulator')
      .argument('<emulator>', 'The emulator ID (e.g., retroarch, dolphin, pcsx2)')
      .argument('<path>', 'The path to the save directory')
      .action(async (emulatorId, savePath) => {
        try {
          console.log(chalk.blue(`🔍 Adding custom path for ${chalk.bold(emulatorId)}...`));
          
          // Expand relative paths and tilde
          if (savePath.startsWith('~')) {
            savePath = path.join(os.homedir(), savePath.slice(1));
          }
          
          savePath = path.resolve(savePath);
          
          // Check if the path exists
          if (!await fs.pathExists(savePath)) {
            console.log(chalk.yellow(`⚠️  Warning: Path does not exist: ${savePath}`));
            console.log(`   Creating directory...`);
            await fs.ensureDir(savePath);
          }
          
          // Get config manager
          const configManager = await ConfigManager.getInstance();
          const config = configManager.get();
          
          // Add or update the path
          if (!config.emulatorPaths[emulatorId]) {
            config.emulatorPaths[emulatorId] = [];
          }
          
          // Check if path already exists
          if (!config.emulatorPaths[emulatorId].includes(savePath)) {
            config.emulatorPaths[emulatorId].push(savePath);
            await configManager.set('emulatorPaths', config.emulatorPaths);
            console.log(chalk.green(`✅ Added path for ${chalk.bold(emulatorId)}: ${savePath}`));
          } else {
            console.log(chalk.yellow(`⚠️  Path already exists for ${chalk.bold(emulatorId)}: ${savePath}`));
          }
        } catch (error) {
          logger.error(`Error adding custom path`, error as Error);
          console.error(chalk.red('❌ Error:'), (error as Error).message);
        }
      })
  )
  .addCommand(
    new Command('remove')
      .description('Remove a custom save path for an emulator')
      .argument('<emulator>', 'The emulator ID (e.g., retroarch, dolphin, pcsx2)')
      .argument('<path>', 'The path to remove')
      .action(async (emulatorId, savePath) => {
        try {
          console.log(chalk.blue(`🔍 Removing path for ${chalk.bold(emulatorId)}...`));
          
          // Expand relative paths and tilde
          if (savePath.startsWith('~')) {
            savePath = path.join(os.homedir(), savePath.slice(1));
          }
          
          savePath = path.resolve(savePath);
          
          // Get config manager
          const configManager = await ConfigManager.getInstance();
          const config = configManager.get();
          
          // Check if we have paths for this emulator
          if (!config.emulatorPaths[emulatorId] || !config.emulatorPaths[emulatorId].includes(savePath)) {
            console.log(chalk.yellow(`⚠️  Path not found for ${chalk.bold(emulatorId)}: ${savePath}`));
            return;
          }
          
          // Remove the path
          config.emulatorPaths[emulatorId] = config.emulatorPaths[emulatorId].filter(p => p !== savePath);
          
          // Remove the emulator entry if no paths left
          if (config.emulatorPaths[emulatorId].length === 0) {
            delete config.emulatorPaths[emulatorId];
          }
          
          await configManager.set('emulatorPaths', config.emulatorPaths);
          console.log(chalk.green(`✅ Removed path for ${chalk.bold(emulatorId)}: ${savePath}`));
        } catch (error) {
          logger.error(`Error removing custom path`, error as Error);
          console.error(chalk.red('❌ Error:'), (error as Error).message);
        }
      })
  )
  .addCommand(
    new Command('list')
      .description('List all configured save paths')
      .action(async () => {
        try {
          console.log(chalk.blue(`🔍 Listing configured save paths...`));
          
          // Get config manager
          const configManager = await ConfigManager.getInstance();
          const config = configManager.get();
          
          // Check if we have any paths configured
          if (Object.keys(config.emulatorPaths).length === 0) {
            console.log(chalk.yellow(`⚠️  No custom paths configured`));
            console.log(`   Use '${chalk.bold('cloudsaver paths add <emulator> <path>')}' to add a path`);
            return;
          }
          
          // Display all paths
          for (const [emulatorId, paths] of Object.entries(config.emulatorPaths)) {
            console.log(chalk.green(`${chalk.bold(emulatorId)}:`));
            
            for (const savePath of paths) {
              const exists = await fs.pathExists(savePath);
              if (exists) {
                console.log(`   - ${savePath}`);
              } else {
                console.log(`   - ${savePath} ${chalk.yellow('(not found)')}`);
              }
            }
          }
        } catch (error) {
          logger.error(`Error listing custom paths`, error as Error);
          console.error(chalk.red('❌ Error:'), (error as Error).message);
        }
      })
  )
  .addCommand(
    new Command('scan-dir')
      .description('Add a directory to scan for save files')
      .argument('<directory>', 'The directory to scan')
      .action(async (directory) => {
        try {
          console.log(chalk.blue(`🔍 Adding scan directory: ${chalk.bold(directory)}...`));
          
          // Expand relative paths and tilde
          if (directory.startsWith('~')) {
            directory = path.join(os.homedir(), directory.slice(1));
          }
          
          directory = path.resolve(directory);
          
          // Check if the path exists
          if (!await fs.pathExists(directory)) {
            console.log(chalk.yellow(`⚠️  Warning: Directory does not exist: ${directory}`));
            console.log(`   Creating directory...`);
            await fs.ensureDir(directory);
          }
          
          // Get config manager
          const configManager = await ConfigManager.getInstance();
          const config = configManager.get();
          
          // Add the directory if it doesn't already exist
          if (!config.scanDirs.includes(directory)) {
            config.scanDirs.push(directory);
            await configManager.set('scanDirs', config.scanDirs);
            console.log(chalk.green(`✅ Added scan directory: ${directory}`));
          } else {
            console.log(chalk.yellow(`⚠️  Directory already in scan list: ${directory}`));
          }
        } catch (error) {
          logger.error(`Error adding scan directory`, error as Error);
          console.error(chalk.red('❌ Error:'), (error as Error).message);
        }
      })
  )
  .addCommand(
    new Command('ignore-dir')
      .description('Add a directory to ignore when scanning')
      .argument('<directory>', 'The directory to ignore')
      .action(async (directory) => {
        try {
          console.log(chalk.blue(`🔍 Adding ignore directory: ${chalk.bold(directory)}...`));
          
          // Expand relative paths and tilde
          if (directory.startsWith('~')) {
            directory = path.join(os.homedir(), directory.slice(1));
          }
          
          directory = path.resolve(directory);
          
          // Get config manager
          const configManager = await ConfigManager.getInstance();
          const config = configManager.get();
          
          // Add the directory if it doesn't already exist
          if (!config.ignoreDirs.includes(directory)) {
            config.ignoreDirs.push(directory);
            await configManager.set('ignoreDirs', config.ignoreDirs);
            console.log(chalk.green(`✅ Added ignore directory: ${directory}`));
          } else {
            console.log(chalk.yellow(`⚠️  Directory already in ignore list: ${directory}`));
          }
        } catch (error) {
          logger.error(`Error adding ignore directory`, error as Error);
          console.error(chalk.red('❌ Error:'), (error as Error).message);
        }
      })
  )
  .addCommand(
    new Command('auto-detect')
      .description('Auto-detect and add save paths')
      .option('--add', 'Add detected paths to configuration')
      .option('--platform <type>', 'Force platform type for detection')
      .action(async (options) => {
        try {
          console.log(chalk.blue(`🔍 Auto-detecting save paths...`));
          
          // Set platform if specified
          if (options.platform) {
            process.env.FORCE_EMUDECK_PLATFORM = options.platform === 'emudeck' ? 'true' : '';
          }
          
          // Detect platform
          const platform = await platformDetector.detectPlatform();
          console.log(chalk.green(`✅ Detected platform: ${chalk.bold(platform.name)}`));
          
          // Detect emulators
          console.log(chalk.blue(`\n🎮 Detecting emulators...`));
          const emulators = await emulatorDetector.detectEmulators(platform);
          
          if (emulators.size === 0) {
            console.log(chalk.yellow(`⚠️  No emulators detected`));
            return;
          }
          
          // Get config if we're adding paths
          let configManager, config;
          if (options.add) {
            configManager = await ConfigManager.getInstance();
            config = configManager.get();
            
            // Set the platform in config
            await configManager.set('platform', platform.type);
          }
          
          // Display detected emulators and save paths
          console.log(chalk.green(`✅ Detected ${emulators.size} emulators:`));
          
          for (const [id, emulator] of emulators) {
            console.log(`\n   ${chalk.bold(emulator.name)}`);
            console.log(`   Save paths:`);
            
            for (const savePath of emulator.savePaths) {
              console.log(`     - ${savePath}`);
            }
            
            // Add to config if requested
            if (options.add && configManager && config) {
              if (!config.emulatorPaths[id]) {
                config.emulatorPaths[id] = [];
              }
              
              for (const savePath of emulator.savePaths) {
                if (!config.emulatorPaths[id].includes(savePath)) {
                  config.emulatorPaths[id].push(savePath);
                }
              }
            }
          }
          
          // Save changes to config
          if (options.add && configManager) {
            await configManager.set('emulatorPaths', config!.emulatorPaths);
            console.log(chalk.green(`\n✅ Added detected paths to configuration`));
          }
        } catch (error) {
          logger.error(`Error auto-detecting save paths`, error as Error);
          console.error(chalk.red('❌ Error:'), (error as Error).message);
        }
      })
  );
