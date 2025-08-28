import { Command } from 'commander';
import chalk from 'chalk';
import path from 'path';
import fs from 'fs-extra';
import { logger } from '../../core/logger.js';
import { platformDetector } from '../../core/platform.js';
import { emulatorDetector } from '../../core/emulator.js';

export const detectCommand = new Command('detect')
  .description('Detect emulation platforms and emulators')
  .option('--save-files', 'Also detect save files (may take longer)')
  .option('--deep-scan <dir>', 'Perform a deep scan of a specific directory for save files')
  .option('--platform <type>', 'Force a specific platform type (emudeck, retropie, batocera, lakka, emulationstation, generic)')
  .action(async (options) => {
    try {
      console.log(chalk.blue('🔍 Detecting emulation setup...'));
      
      // Set environment variable if platform is specified
      if (options.platform) {
        const validPlatforms = ['emudeck', 'retropie', 'batocera', 'lakka', 'emulationstation', 'generic'];
        if (validPlatforms.includes(options.platform.toLowerCase())) {
          process.env.FORCE_EMUDECK_PLATFORM = options.platform === 'emudeck' ? 'true' : '';
          console.log(chalk.yellow(`ℹ️  Forcing platform type: ${options.platform}`));
        } else {
          console.log(chalk.red(`❌ Invalid platform type: ${options.platform}`));
          console.log(`   Valid types are: ${validPlatforms.join(', ')}`);
          return;
        }
      }
      
      // Detect platform
      const platform = await platformDetector.detectPlatform();
      console.log(chalk.green(`✅ Detected platform: ${chalk.bold(platform.name)}`));
      
      if (platform.baseDir) {
        console.log(`   Base directory: ${platform.baseDir}`);
      }
      
      if (platform.romDir) {
        console.log(`   ROM directory: ${platform.romDir}`);
      }
      
      if (platform.saveDir) {
        console.log(`   Save directory: ${platform.saveDir}`);
      }
      
      // Check if we should do a deep scan of a specific directory
      if (options.deepScan) {
        console.log(chalk.blue(`\n🔍 Performing deep scan of: ${options.deepScan}`));
        
        // Verify the directory exists
        try {
          if (await fs.pathExists(options.deepScan)) {
            const scanResults = await emulatorDetector.deepScanDirectory(options.deepScan);
            
            if (scanResults.size === 0) {
              console.log(chalk.yellow('⚠️  No save files found in deep scan'));
            } else {
              console.log(chalk.green(`✅ Deep scan found save files for ${scanResults.size} emulators:`));
              
              for (const [id, files] of scanResults.entries()) {
                console.log(`\n   ${chalk.bold(id)}: ${files.length} save files`);
                
                // Show the first few
                const samplesToShow = Math.min(3, files.length);
                for (let i = 0; i < samplesToShow; i++) {
                  console.log(`     - ${path.basename(files[i])}`);
                }
                
                if (files.length > samplesToShow) {
                  console.log(`     - ...and ${files.length - samplesToShow} more`);
                }
              }
            }
          } else {
            console.log(chalk.yellow(`⚠️  Directory not found: ${options.deepScan}`));
          }
        } catch (error) {
          logger.error(`Error deep scanning directory: ${options.deepScan}`, error as Error);
          console.error(chalk.red('❌ Error during deep scan:'), (error as Error).message);
        }
      } else {
        // Standard emulator detection
        console.log(chalk.blue('\n🎮 Detecting emulators...'));
        const emulators = await emulatorDetector.detectEmulators(platform);
        
        if (emulators.size === 0) {
          console.log(chalk.yellow('⚠️  No emulators detected'));
        } else {
          console.log(chalk.green(`✅ Detected ${emulators.size} emulators:`));
          
          for (const [id, emulator] of emulators) {
            console.log(`\n   ${chalk.bold(emulator.name)}`);
            console.log(`   Save paths:`);
            
            for (const savePath of emulator.savePaths) {
              console.log(`     - ${savePath}`);
            }
            
            // Optionally detect save files
            if (options.saveFiles) {
              const saveFiles = await emulatorDetector.findSaveFiles(emulator);
              if (saveFiles.length > 0) {
                console.log(`   Found ${saveFiles.length} save files`);
                
                // Show the first few
                const samplesToShow = Math.min(3, saveFiles.length);
                for (let i = 0; i < samplesToShow; i++) {
                  console.log(`     - ${path.basename(saveFiles[i])}`);
                }
                
                if (saveFiles.length > samplesToShow) {
                  console.log(`     - ...and ${saveFiles.length - samplesToShow} more`);
                }
              } else {
                console.log(chalk.yellow(`   No save files found`));
              }
            }
          }
        }
      }
      
      console.log(chalk.blue('\n🔄 Detection complete'));
    } catch (error) {
      logger.error('Error detecting emulation setup', error as Error);
      console.error(chalk.red('❌ Error:'), (error as Error).message);
    }
  });
