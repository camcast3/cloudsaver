import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { logger } from './logger.js';

// Define platform types
export type PlatformType = 'emudeck' | 'retropie' | 'batocera' | 'lakka' | 'emulationstation' | 'generic';

// Platform interface
export interface Platform {
  type: PlatformType;
  name: string;
  baseDir: string;
  romDir?: string;
  saveDir?: string;
}

export class PlatformDetector {
  // Detect the current platform
  public async detectPlatform(): Promise<Platform> {
    logger.debug('Starting platform detection');
    
    // Try to detect platforms in order of specificity
    const detectors: Array<() => Promise<Platform | null>> = [
      this.detectEmuDeck.bind(this),
      this.detectRetroPie.bind(this),
      this.detectBatocera.bind(this),
      this.detectLakka.bind(this),
      this.detectEmulationStation.bind(this)
    ];
    
    for (const detector of detectors) {
      const platform = await detector();
      if (platform) {
        logger.info(`Detected platform: ${platform.name}`, platform);
        return platform;
      }
    }
    
    // Fall back to generic platform
    logger.info('No specific platform detected, using generic configuration');
    return this.getGenericPlatform();
  }
  
  // EmuDeck detection
  private async detectEmuDeck(): Promise<Platform | null> {
    logger.debug('Checking for EmuDeck installation');
    
    // Possible EmuDeck installation paths - Linux and Windows
    const possiblePaths = [
      // Linux Steam Deck paths
      '/home/deck/emudeck',
      '/home/deck/.emudeck',
      // General Linux paths
      path.join(os.homedir(), 'emudeck'),
      path.join(os.homedir(), '.emudeck'),
      // Windows paths
      path.join(os.homedir(), 'EmuDeck'),
      path.join(os.homedir(), 'AppData', 'Roaming', 'EmuDeck'),
      path.join(os.homedir(), 'Documents', 'EmuDeck')
    ];
    
    // Windows-specific drives to check for Emulation folder
    if (os.platform() === 'win32') {
      const drivesToCheck = ['C:', 'D:', 'E:', 'F:'];
      for (const drive of drivesToCheck) {
        possiblePaths.push(path.join(drive, 'EmuDeck'));
      }
    }
    
    // Check for EmuDeck markers
    for (const basePath of possiblePaths) {
      try {
        if (await fs.pathExists(basePath)) {
          logger.debug(`Found potential EmuDeck directory: ${basePath}`);
          
          // On Windows, we should also check for Emulation folder as a strong indicator
          let emulationFolder = '';
          if (os.platform() === 'win32') {
            const drivesToCheck = ['E:', 'D:', 'C:'];
            for (const drive of drivesToCheck) {
              const emulationPath = path.join(drive, 'Emulation');
              if (await fs.pathExists(emulationPath)) {
                logger.debug(`Found Emulation directory: ${emulationPath}`);
                emulationFolder = emulationPath;
                break;
              }
            }
            
            // If we have both EmuDeck folder and Emulation folder, it's highly likely this is EmuDeck
            if (emulationFolder) {
              logger.info(`Detected EmuDeck on Windows with Emulation folder at ${emulationFolder}`);
              
              // For Windows, the actual "base directory" should be the Emulation folder
              const romDir = path.join(emulationFolder, 'roms');
              const saveDir = path.join(emulationFolder, 'saves');
              
              return {
                type: 'emudeck',
                name: 'EmuDeck (Windows)',
                baseDir: emulationFolder,
                romDir: await fs.pathExists(romDir) ? romDir : undefined,
                saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
              };
            }
          }
          
          // If we're here and on Windows but didn't find an Emulation folder, let's still check
          // for EmuDeck config files as a fallback
          if (os.platform() === 'win32') {
            const deckScriptPath = path.join(basePath, 'EmuDeck.ps1');
            const configExists = await fs.pathExists(deckScriptPath);
            
            if (configExists) {
              logger.info(`Detected EmuDeck on Windows at ${basePath} via EmuDeck.ps1`);
              
              // Try to find rom and save directories in common locations
              let romDir = path.join(os.homedir(), 'Emulation', 'roms');
              let saveDir = path.join(os.homedir(), 'Emulation', 'saves');
              
              // Fall back to C: drive if needed
              if (!(await fs.pathExists(romDir))) {
                romDir = 'C:\\Emulation\\roms';
              }
              
              if (!(await fs.pathExists(saveDir))) {
                saveDir = 'C:\\Emulation\\saves';
              }
              
              return {
                type: 'emudeck',
                name: 'EmuDeck (Windows)',
                baseDir: basePath,
                romDir: await fs.pathExists(romDir) ? romDir : undefined,
                saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
              };
            }
          }
          
          // Linux EmuDeck detection logic
          // Try to find the rom directory
          let romDir = path.join(basePath, 'roms');
          if (!(await fs.pathExists(romDir))) {
            romDir = path.join(os.homedir(), 'Emulation', 'roms');
          }
          
          // Try to find the saves directory
          let saveDir = path.join(os.homedir(), 'Emulation', 'saves');
          if (!(await fs.pathExists(saveDir))) {
            saveDir = path.join(os.homedir(), 'Emulation', 'storage');
          }
          
          return {
            type: 'emudeck',
            name: 'EmuDeck',
            baseDir: basePath,
            romDir: await fs.pathExists(romDir) ? romDir : undefined,
            saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
          };
        }
      } catch (error) {
        logger.debug(`Error checking EmuDeck path ${basePath}`, error);
      }
    }
    
    // Special case for Windows: If we didn't find EmuDeck folders but Emulation folder exists
    // with the expected structure, assume it's EmuDeck
    if (os.platform() === 'win32') {
      const drivesToCheck = ['E:', 'D:', 'C:'];
      for (const drive of drivesToCheck) {
        const emulationPath = path.join(drive, 'Emulation');
        try {
          if (await fs.pathExists(emulationPath)) {
            logger.debug(`Found Emulation directory at ${emulationPath}, checking for EmuDeck structure`);
            
            // Check for typical EmuDeck folders in the Emulation directory
            const emudeckFolders = ['roms', 'saves', 'tools', 'storage'];
            let matchCount = 0;
            
            for (const folder of emudeckFolders) {
              if (await fs.pathExists(path.join(emulationPath, folder))) {
                matchCount++;
              }
            }
            
            // If we have at least 2 of the expected folders, assume it's EmuDeck
            if (matchCount >= 2) {
              logger.info(`Detected EmuDeck by Emulation folder structure at ${emulationPath}`);
              
              const romDir = path.join(emulationPath, 'roms');
              const saveDir = path.join(emulationPath, 'saves');
              
              return {
                type: 'emudeck',
                name: 'EmuDeck (Windows)',
                baseDir: emulationPath,
                romDir: await fs.pathExists(romDir) ? romDir : undefined,
                saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
              };
            }
          }
        } catch (error) {
          logger.debug(`Error checking Emulation folder at ${emulationPath}`, error);
        }
      }
    }
    
    // Force EmuDeck if user has set an environment variable (useful for testing)
    if (process.env.FORCE_EMUDECK_PLATFORM) {
      logger.info('Forcing EmuDeck platform detection via environment variable');
      let baseDir = path.join(os.homedir(), 'Emulation');
      
      if (os.platform() === 'win32') {
        // On Windows, prefer E: drive if it exists
        const drives = ['E:', 'D:', 'C:'];
        for (const drive of drives) {
          const emulationPath = path.join(drive, 'Emulation');
          if (fs.existsSync(emulationPath)) {
            baseDir = emulationPath;
            break;
          }
        }
      }
      
      return {
        type: 'emudeck',
        name: 'EmuDeck (Forced)',
        baseDir,
        romDir: path.join(baseDir, 'roms'),
        saveDir: path.join(baseDir, 'saves')
      };
    }
    
    return null;
  }
  
  // RetroPie detection
  private async detectRetroPie(): Promise<Platform | null> {
    const possiblePaths = [
      '/opt/retropie',
      '/home/pi/RetroPie'
    ];
    
    for (const basePath of possiblePaths) {
      try {
        if (await fs.pathExists(basePath)) {
          const romDir = path.join(basePath, 'roms');
          const saveDir = path.join(os.homedir(), '.config', 'retroarch', 'saves');
          
          return {
            type: 'retropie',
            name: 'RetroPie',
            baseDir: basePath,
            romDir: await fs.pathExists(romDir) ? romDir : undefined,
            saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
          };
        }
      } catch (error) {
        logger.debug(`Error checking RetroPie path ${basePath}`, error);
      }
    }
    
    return null;
  }
  
  // Batocera detection
  private async detectBatocera(): Promise<Platform | null> {
    // Batocera-specific paths
    const possiblePaths = [
      '/userdata',
      '/usr/batocera'
    ];
    
    for (const basePath of possiblePaths) {
      try {
        if (await fs.pathExists(basePath)) {
          const romDir = path.join('/userdata', 'roms');
          const saveDir = path.join('/userdata', 'saves');
          
          return {
            type: 'batocera',
            name: 'Batocera',
            baseDir: basePath,
            romDir: await fs.pathExists(romDir) ? romDir : undefined,
            saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
          };
        }
      } catch (error) {
        logger.debug(`Error checking Batocera path ${basePath}`, error);
      }
    }
    
    return null;
  }
  
  // Lakka detection
  private async detectLakka(): Promise<Platform | null> {
    // Check for Lakka-specific files
    try {
      if (await fs.pathExists('/etc/lakka-version')) {
        const romDir = path.join('/storage', 'roms');
        const saveDir = path.join('/storage', 'savefiles');
        
        return {
          type: 'lakka',
          name: 'Lakka',
          baseDir: '/storage',
          romDir: await fs.pathExists(romDir) ? romDir : undefined,
          saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
        };
      }
    } catch (error) {
      logger.debug('Error checking Lakka platform', error);
    }
    
    return null;
  }
  
  // EmulationStation detection
  private async detectEmulationStation(): Promise<Platform | null> {
    const possiblePaths = [
      path.join(os.homedir(), '.emulationstation'),
      '/etc/emulationstation',
      'C:\\EmulationStation'
    ];
    
    for (const basePath of possiblePaths) {
      try {
        if (await fs.pathExists(basePath)) {
          // ES has different ROM paths based on platform
          let romDir: string | undefined;
          let saveDir: string | undefined;
          
          if (os.platform() === 'win32') {
            romDir = path.join('C:\\', 'ROMs');
            saveDir = path.join(os.homedir(), 'AppData', 'Roaming', 'RetroArch', 'saves');
          } else {
            romDir = path.join(os.homedir(), 'ROMs');
            saveDir = path.join(os.homedir(), '.config', 'retroarch', 'saves');
          }
          
          return {
            type: 'emulationstation',
            name: 'EmulationStation',
            baseDir: basePath,
            romDir: await fs.pathExists(romDir) ? romDir : undefined,
            saveDir: await fs.pathExists(saveDir) ? saveDir : undefined
          };
        }
      } catch (error) {
        logger.debug(`Error checking EmulationStation path ${basePath}`, error);
      }
    }
    
    return null;
  }
  
  // Generic fallback platform
  private getGenericPlatform(): Platform {
    let baseDir: string = '';
    let romDir: string | undefined;
    let saveDir: string | undefined;
    
    if (os.platform() === 'win32') {
      // Check common Windows emulation paths
      const possibleBaseDirs = [
        'E:\\Emulation',
        'E:\\Emulators',
        'D:\\Emulation',
        'D:\\Emulators',
        'C:\\Emulation',
        'C:\\Emulators',
        path.join(os.homedir(), 'Emulation'),
        path.join(os.homedir(), 'Emulators')
      ];
      
      let found = false;
      for (const dir of possibleBaseDirs) {
        try {
          if (fs.existsSync(dir)) {
            baseDir = dir;
            logger.debug(`Found Windows emulation directory: ${baseDir}`);
            
            // Check for roms directory
            const possibleRomDirs = [
              path.join(baseDir, 'roms'),
              path.join(baseDir, 'ROMs'),
              path.join(baseDir, 'games'),
              path.join(baseDir, 'Games')
            ];
            
            for (const romDirectory of possibleRomDirs) {
              if (fs.existsSync(romDirectory)) {
                romDir = romDirectory;
                logger.debug(`Found ROM directory: ${romDir}`);
                break;
              }
            }
            
            // Check for saves directory
            const possibleSaveDirs = [
              path.join(baseDir, 'saves'),
              path.join(baseDir, 'save'),
              path.join(baseDir, 'SaveData'),
              path.join(baseDir, 'SaveFiles'),
              path.join(baseDir, 'SaveGames'),
              path.join(baseDir, 'Saves')
            ];
            
            for (const saveDirectory of possibleSaveDirs) {
              if (fs.existsSync(saveDirectory)) {
                saveDir = saveDirectory;
                logger.debug(`Found save directory: ${saveDir}`);
                break;
              }
            }
            
            found = true;
            break;
          }
        } catch (error) {
          logger.debug(`Error checking emulation directory ${dir}`, error);
        }
      }
      
      // If no directory was found, use default
      if (!found) {
        baseDir = path.join(os.homedir(), 'Emulation');
        romDir = path.join(baseDir, 'ROMs');
        logger.debug(`No existing emulation directory found, defaulting to ${baseDir}`);
      }
    } else {
      baseDir = path.join(os.homedir(), '.local', 'share', 'cloudsaver');
      romDir = path.join(os.homedir(), 'ROMs');
      logger.debug(`Using generic Linux paths: ${baseDir}`);
    }
    
    return {
      type: 'generic',
      name: 'Generic Emulation Setup',
      baseDir,
      romDir,
      saveDir
    };
  }
}

// Create and export an instance for convenience
export const platformDetector = new PlatformDetector();
