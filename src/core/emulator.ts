import fs from 'fs-extra';
import path from 'path';
import { glob } from 'glob';
import { logger } from './logger.js';
import { Platform, PlatformType } from './platform.js';

// Emulator interface
export interface Emulator {
  id: string;
  name: string;
  savePaths: string[];
  saveExtensions: string[];
  statePaths?: string[];
  stateExtensions?: string[];
  configPaths?: string[];
}

// Base emulator configurations
const emulatorConfigs: Record<string, Omit<Emulator, 'savePaths'> & { 
  defaultPaths: Record<PlatformType, string[]>
}> = {
  retroarch: {
    id: 'retroarch',
    name: 'RetroArch',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/retroarch/saves',
        '~/.var/app/org.libretro.RetroArch/config/retroarch/saves',
        'E:/Emulation/saves/retroarch/saves',
        'D:/Emulation/saves/retroarch/saves',
        'C:/Emulation/saves/retroarch/saves',
        'E:/Emulation/saves/RetroArch/saves',
        'D:/Emulation/saves/RetroArch/saves',
        'C:/Emulation/saves/RetroArch/saves'
      ],
      retropie: [
        '~/.config/retroarch/saves'
      ],
      batocera: [
        '/userdata/saves/retroarch'
      ],
      lakka: [
        '/storage/savefiles'
      ],
      emulationstation: [
        '~/.config/retroarch/saves',
        '~/AppData/Roaming/RetroArch/saves'
      ],
      generic: [
        '~/.config/retroarch/saves',
        '~/AppData/Roaming/RetroArch/saves',
        'E:/Emulation/saves/retroarch',
        'D:/Emulation/saves/retroarch',
        'C:/Emulation/saves/retroarch',
        'E:/Emulation/SaveData/retroarch',
        'E:/Emulation/retroarch/saves'
      ]
    },
    saveExtensions: ['.srm', '.sav', '.bsv', '.fs', '.ram', '.dsv'],
    stateExtensions: ['.state', '.save', '.sstate', '.rst', '.ss', '.auto'],
    configPaths: ['~/.config/retroarch/retroarch.cfg']
  },
  
  dolphin: {
    id: 'dolphin',
    name: 'Dolphin',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/dolphin/Wii',
        '~/Emulation/saves/dolphin/GC',
        '~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC',
        '~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/Wii',
        'E:/Emulation/saves/dolphin/Wii',
        'E:/Emulation/saves/dolphin/GC',
        'D:/Emulation/saves/dolphin/Wii',
        'D:/Emulation/saves/dolphin/GC',
        'C:/Emulation/saves/dolphin/Wii',
        'C:/Emulation/saves/dolphin/GC'
      ],
      retropie: [
        '~/.config/dolphin-emu/GC',
        '~/.config/dolphin-emu/Wii'
      ],
      batocera: [
        '/userdata/saves/dolphin'
      ],
      lakka: [
        '/storage/dolphin/User/GC',
        '/storage/dolphin/User/Wii'
      ],
      emulationstation: [
        '~/.config/dolphin-emu/GC',
        '~/.config/dolphin-emu/Wii',
        '~/Documents/Dolphin Emulator/GC',
        '~/Documents/Dolphin Emulator/Wii'
      ],
      generic: [
        '~/.config/dolphin-emu/GC',
        '~/.config/dolphin-emu/Wii',
        '~/Documents/Dolphin Emulator/GC',
        '~/Documents/Dolphin Emulator/Wii',
        'E:/Emulation/saves/dolphin',
        'E:/Emulation/saves/dolphin/GC',
        'E:/Emulation/saves/dolphin/Wii',
        'E:/Emulation/dolphin/User/GC',
        'E:/Emulation/dolphin/User/Wii'
      ]
    },
    saveExtensions: ['.gci', '.sav', '.dat', '.raw', '.bin'],
    stateExtensions: ['.s##', '.gcs', '.gci']
  },
  
  pcsx2: {
    id: 'pcsx2',
    name: 'PCSX2',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/pcsx2/memcards',
        '~/.var/app/net.pcsx2.PCSX2/config/PCSX2/memcards',
        'E:/Emulation/saves/pcsx2/memcards',
        'D:/Emulation/saves/pcsx2/memcards',
        'C:/Emulation/saves/pcsx2/memcards',
        'E:/Emulation/saves/PCSX2/memcards',
        'D:/Emulation/saves/PCSX2/memcards',
        'C:/Emulation/saves/PCSX2/memcards',
        'E:/Emulation/saves/pcsx2/saves',
        'D:/Emulation/saves/pcsx2/saves',
        'C:/Emulation/saves/pcsx2/saves'
      ],
      retropie: [
        '~/.config/PCSX2/memcards'
      ],
      batocera: [
        '/userdata/saves/pcsx2'
      ],
      lakka: [
        '/storage/pcsx2/memcards'
      ],
      emulationstation: [
        '~/.config/PCSX2/memcards',
        '~/Documents/PCSX2/memcards'
      ],
      generic: [
        '~/.config/PCSX2/memcards',
        '~/Documents/PCSX2/memcards',
        'E:/Emulation/saves/pcsx2',
        'E:/Emulation/saves/pcsx2/memcards',
        'E:/Emulation/PCSX2/memcards'
      ]
    },
    saveExtensions: ['.ps2', '.mcd', '.mcr', '.mc'],
    stateExtensions: ['.p2s', '.ps2state'],
    configPaths: ['~/.config/PCSX2/PCSX2.ini']
  },
  
  rpcs3: {
    id: 'rpcs3',
    name: 'RPCS3',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/rpcs3/saves',
        '~/.var/app/net.rpcs3.RPCS3/config/rpcs3/saves',
        'E:/Emulation/saves/rpcs3/saves',
        'D:/Emulation/saves/rpcs3/saves',
        'C:/Emulation/saves/rpcs3/saves',
        'E:/Emulation/saves/RPCS3/saves',
        'D:/Emulation/saves/RPCS3/saves',
        'C:/Emulation/saves/RPCS3/saves',
        'E:/Emulation/RPCS3/dev_hdd0/home',
        'D:/Emulation/RPCS3/dev_hdd0/home',
        'C:/Emulation/RPCS3/dev_hdd0/home'
      ],
      retropie: [
        '~/.config/rpcs3/saves'
      ],
      batocera: [
        '/userdata/saves/rpcs3'
      ],
      lakka: [
        '/storage/rpcs3/saves'
      ],
      emulationstation: [
        '~/.config/rpcs3/saves',
        '~/Documents/RPCS3/saves'
      ],
      generic: [
        '~/.config/rpcs3/saves',
        '~/Documents/RPCS3/saves',
        'E:/Emulation/saves/rpcs3',
        'E:/Emulation/RPCS3/saves',
        'E:/Emulation/RPCS3/dev_hdd0/home'
      ]
    },
    saveExtensions: ['.bin', '.dat', '.sav'],
    stateExtensions: ['.dat', '.bin'],
    configPaths: ['~/.config/rpcs3/config.yml']
  },
  
  yuzu: {
    id: 'yuzu',
    name: 'Yuzu',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/yuzu/nand/user/save',
        '~/.var/app/org.yuzu_emu.yuzu/data/yuzu/nand/user/save',
        'E:/Emulation/saves/yuzu/nand/user/save',
        'D:/Emulation/saves/yuzu/nand/user/save',
        'C:/Emulation/saves/yuzu/nand/user/save',
        'E:/Emulation/saves/Yuzu/nand/user/save',
        'D:/Emulation/saves/Yuzu/nand/user/save',
        'C:/Emulation/saves/Yuzu/nand/user/save',
        'E:/Emulation/yuzu/user/save',
        'D:/Emulation/yuzu/user/save',
        'C:/Emulation/yuzu/user/save',
        'E:/Emulation/saves/yuzu/saves',
        'D:/Emulation/saves/yuzu/saves',
        'C:/Emulation/saves/yuzu/saves'
      ],
      retropie: [
        '~/.local/share/yuzu/nand/user/save'
      ],
      batocera: [
        '/userdata/saves/yuzu'
      ],
      lakka: [
        '/storage/yuzu/saves'
      ],
      emulationstation: [
        '~/.local/share/yuzu/nand/user/save',
        '~/AppData/Roaming/yuzu/nand/user/save'
      ],
      generic: [
        '~/.local/share/yuzu/nand/user/save',
        '~/AppData/Roaming/yuzu/nand/user/save',
        'E:/Emulation/saves/yuzu',
        'E:/Emulation/yuzu/user/save',
        'E:/Emulation/yuzu/nand/user/save'
      ]
    },
    saveExtensions: ['.bin', '.dat', '.sav'],
    stateExtensions: ['.dat'],
    configPaths: ['~/.config/yuzu/config.ini']
  },
  
  cemu: {
    id: 'cemu',
    name: 'Cemu',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/Cemu/saves',
        'E:/Emulation/saves/Cemu/saves',
        'D:/Emulation/saves/Cemu/saves',
        'C:/Emulation/saves/Cemu/saves',
        'E:/Emulation/saves/cemu/saves',
        'D:/Emulation/saves/cemu/saves',
        'C:/Emulation/saves/cemu/saves'
      ],
      retropie: [
        '~/.local/share/Cemu/saves'
      ],
      batocera: [
        '/userdata/saves/cemu'
      ],
      lakka: [
        '/storage/cemu/saves'
      ],
      emulationstation: [
        '~/.local/share/Cemu/saves',
        '~/Documents/Cemu/saves'
      ],
      generic: [
        '~/.local/share/Cemu/saves',
        '~/Documents/Cemu/saves',
        'E:/Emulation/saves/Cemu',
        'E:/Emulation/Cemu/saves'
      ]
    },
    saveExtensions: ['.bin', '.dat', '.sav', '.srm'],
    stateExtensions: ['.sav', '.save'],
    configPaths: ['~/.config/Cemu/settings.xml']
  },
  
  duckstation: {
    id: 'duckstation',
    name: 'DuckStation',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/duckstation/saves',
        'E:/Emulation/saves/duckstation/saves',
        'D:/Emulation/saves/duckstation/saves',
        'C:/Emulation/saves/duckstation/saves'
      ],
      retropie: [
        '~/.local/share/duckstation/saves'
      ],
      batocera: [
        '/userdata/saves/duckstation'
      ],
      lakka: [
        '/storage/duckstation/saves'
      ],
      emulationstation: [
        '~/.local/share/duckstation/saves',
        '~/Documents/DuckStation/saves'
      ],
      generic: [
        '~/.local/share/duckstation/saves',
        '~/Documents/DuckStation/saves',
        'E:/Emulation/saves/duckstation',
        'E:/Emulation/DuckStation/saves'
      ]
    },
    saveExtensions: ['.mcd', '.mcr', '.mc', '.srm', '.sav'],
    stateExtensions: ['.sav'],
    configPaths: ['~/.config/duckstation/settings.ini']
  },
  
  ppsspp: {
    id: 'ppsspp',
    name: 'PPSSPP',
    defaultPaths: {
      emudeck: [
        '~/Emulation/saves/ppsspp/saves',
        'E:/Emulation/saves/ppsspp/saves',
        'D:/Emulation/saves/ppsspp/saves',
        'C:/Emulation/saves/ppsspp/saves',
        'E:/Emulation/saves/PPSSPP/saves',
        'D:/Emulation/saves/PPSSPP/saves',
        'C:/Emulation/saves/PPSSPP/saves'
      ],
      retropie: [
        '~/.config/ppsspp/PSP/SAVEDATA'
      ],
      batocera: [
        '/userdata/saves/ppsspp'
      ],
      lakka: [
        '/storage/ppsspp/PSP/SAVEDATA'
      ],
      emulationstation: [
        '~/.config/ppsspp/PSP/SAVEDATA',
        '~/Documents/PPSSPP/PSP/SAVEDATA'
      ],
      generic: [
        '~/.config/ppsspp/PSP/SAVEDATA',
        '~/Documents/PPSSPP/PSP/SAVEDATA',
        'E:/Emulation/saves/ppsspp',
        'E:/Emulation/PPSSPP/PSP/SAVEDATA'
      ]
    },
    saveExtensions: ['.bin', '.sav', '.dat'],
    stateExtensions: ['.ppst', '.sav'],
    configPaths: ['~/.config/ppsspp/ppsspp.ini']
  }
};

export class EmulatorDetector {
  private emulators: Map<string, Emulator> = new Map();
  
  // Expand path with tilde to absolute path
  private expandPath(inputPath: string): string {
    if (inputPath.startsWith('~/')) {
      return path.join(process.env.HOME || process.env.USERPROFILE || '', inputPath.slice(2));
    }
    return inputPath;
  }
  
  // Detect available emulators based on platform
  public async detectEmulators(platform: Platform): Promise<Map<string, Emulator>> {
    logger.info(`Detecting emulators for platform: ${platform.name}`);
    this.emulators.clear();
    
    // Special handling for EmuDeck on Windows
    if (platform.type === 'emudeck' && platform.baseDir.includes(':\\')) {
      logger.debug('Scanning EmuDeck directories on Windows');
      
      // First check the saves directory which should contain all emulator folders
      if (platform.saveDir) {
        await this.scanCustomDirectories(platform.saveDir);
      }
      
      // Also check the base directory
      await this.scanCustomDirectories(platform.baseDir);
      
      // Check other common directories
      const emulatorDir = path.join(platform.baseDir, 'emulators');
      if (await fs.pathExists(emulatorDir)) {
        logger.debug(`Found emulators directory: ${emulatorDir}`);
        await this.scanCustomDirectories(emulatorDir);
      }
    }
    // Add custom paths for Windows drives if it exists
    else if (platform.type === 'generic' && platform.baseDir.includes(':\\')) {
      logger.debug('Scanning custom directories in Windows drives');
      await this.scanCustomDirectories(platform.baseDir);
      
      // Check other potential drives
      const drivesToCheck = ['E:', 'D:', 'C:'];
      for (const drive of drivesToCheck) {
        if (platform.baseDir.indexOf(drive) === -1) { // If not the current drive
          const potentialPath = `${drive}\\Emulation`;
          if (await fs.pathExists(potentialPath)) {
            logger.debug(`Found additional Emulation directory: ${potentialPath}`);
            await this.scanCustomDirectories(potentialPath);
          }
        }
      }
    }
    
    for (const [id, config] of Object.entries(emulatorConfigs)) {
      try {
        // Get default paths for this platform type
        const defaultPaths = config.defaultPaths[platform.type] || config.defaultPaths.generic;
        
        // Expand all paths and check if they exist
        const existingPaths: string[] = [];
        
        for (const savePath of defaultPaths) {
          const expandedPath = this.expandPath(savePath);
          try {
            if (await fs.pathExists(expandedPath)) {
              existingPaths.push(expandedPath);
              logger.debug(`Found save path for ${id}: ${expandedPath}`);
            }
          } catch (error) {
            logger.debug(`Error checking path ${expandedPath} for ${id}`, error as Error);
          }
        }
        
        // If we found at least one existing save path, add the emulator
        if (existingPaths.length > 0) {
          const emulator: Emulator = {
            ...config,
            savePaths: existingPaths
          };
          this.emulators.set(id, emulator);
          logger.info(`Detected emulator: ${emulator.name}`);
        } else {
          logger.debug(`Emulator ${id} not detected (no save paths found)`);
        }
      } catch (error) {
        logger.error(`Error detecting emulator ${id}`, error as Error);
      }
    }
    
    return this.emulators;
  }
  
  // Get all detected emulators
  public getEmulators(): Map<string, Emulator> {
    return this.emulators;
  }
  
  // Get a specific emulator by ID
  public getEmulator(id: string): Emulator | undefined {
    return this.emulators.get(id);
  }
  
  // Find save files for a specific emulator
  public async findSaveFiles(emulator: Emulator): Promise<string[]> {
    const saveFiles: string[] = [];
    
    for (const savePath of emulator.savePaths) {
      try {
        // Create patterns for each extension
        const patterns = emulator.saveExtensions.map(ext => 
          path.join(savePath, `**/*${ext}`)
        );
        
        // Find files matching patterns
        for (const pattern of patterns) {
          const files = await glob(pattern, { nodir: true, dot: true });
          saveFiles.push(...files);
        }
      } catch (error) {
        logger.error(`Error finding save files for ${emulator.name} in ${savePath}`, error as Error);
      }
    }
    
    logger.info(`Found ${saveFiles.length} save files for ${emulator.name}`);
    return saveFiles;
  }
  
  // Scan custom directories for emulator saves
  private async scanCustomDirectories(baseDir: string): Promise<void> {
    logger.info(`Scanning custom directory: ${baseDir}`);
    
    // Common subdirectories to check
    const subDirs = [
      'saves',
      'save',
      'SaveData',
      'SaveFiles',
      'SaveGames',
      'Emulators'
    ];
    
    // EmuDeck specific - directly scan each emulator's save directory
    const emulationSavesPath = path.join(baseDir, 'saves');
    if (await fs.pathExists(emulationSavesPath)) {
      logger.debug(`Found EmuDeck-style saves directory: ${emulationSavesPath}`);
      
      try {
        // Get all subdirectories (each emulator has its own folder)
        const entries = await fs.readdir(emulationSavesPath, { withFileTypes: true });
        
        for (const entry of entries) {
          if (entry.isDirectory()) {
            const emulatorName = entry.name.toLowerCase();
            const emulatorPath = path.join(emulationSavesPath, entry.name);
            
            // Check for common subdirectories like "saves", "states", etc.
            try {
              const subEntries = await fs.readdir(emulatorPath, { withFileTypes: true });
              for (const subEntry of subEntries) {
                if (subEntry.isDirectory()) {
                  const subDirName = subEntry.name.toLowerCase();
                  if (['save', 'saves', 'savegames', 'memcards'].includes(subDirName)) {
                    const savePath = path.join(emulatorPath, subEntry.name);
                    logger.debug(`Found save subdirectory for ${emulatorName}: ${savePath}`);
                    
                    // Add to known emulators if we find a match
                    for (const [id, config] of Object.entries(emulatorConfigs)) {
                      if (emulatorName.includes(id.toLowerCase())) {
                        logger.debug(`Found custom path for ${id}: ${savePath}`);
                        
                        // Add to config's default paths for emudeck platform
                        if (!config.defaultPaths.emudeck.includes(savePath)) {
                          config.defaultPaths.emudeck.push(savePath);
                        }
                        
                        // Also add the parent directory as some saves might be directly in the emulator folder
                        if (!config.defaultPaths.emudeck.includes(emulatorPath)) {
                          config.defaultPaths.emudeck.push(emulatorPath);
                        }
                      }
                    }
                  }
                }
              }
            } catch (subError) {
              logger.debug(`Error scanning subdirectories of ${emulatorPath}`, subError as Error);
            }
            
            // Also add directly if the name matches one of our emulators
            for (const [id, config] of Object.entries(emulatorConfigs)) {
              if (emulatorName.includes(id.toLowerCase())) {
                logger.debug(`Found custom path for ${id}: ${emulatorPath}`);
                
                // Add to config's default paths for emudeck platform
                if (!config.defaultPaths.emudeck.includes(emulatorPath)) {
                  config.defaultPaths.emudeck.push(emulatorPath);
                }
              }
            }
          }
        }
      } catch (error) {
        logger.error(`Error scanning emulation saves directory: ${emulationSavesPath}`, error as Error);
      }
    }
    
    // Generic subdirectory scan
    for (const subDir of subDirs) {
      const fullPath = path.join(baseDir, subDir);
      
      try {
        if (await fs.pathExists(fullPath)) {
          logger.debug(`Found custom save directory: ${fullPath}`);
          
          // Look for emulator-specific folders
          const entries = await fs.readdir(fullPath, { withFileTypes: true });
          
          for (const entry of entries) {
            if (entry.isDirectory()) {
              const emulatorName = entry.name.toLowerCase();
              const emulatorPath = path.join(fullPath, entry.name);
              
              // Add to known emulators if we find a match
              for (const [id, config] of Object.entries(emulatorConfigs)) {
                if (emulatorName.includes(id.toLowerCase())) {
                  logger.debug(`Found custom path for ${id}: ${emulatorPath}`);
                  
                  // Add to config's default paths for generic platform
                  if (!config.defaultPaths.generic.includes(emulatorPath)) {
                    config.defaultPaths.generic.push(emulatorPath);
                  }
                }
              }
            }
          }
        }
      } catch (error) {
        logger.error(`Error scanning custom directory: ${fullPath}`, error as Error);
      }
    }
    
    // Also scan the root directory for potential save folders
    try {
      if (await fs.pathExists(baseDir)) {
        const entries = await fs.readdir(baseDir, { withFileTypes: true });
        
        for (const entry of entries) {
          if (entry.isDirectory()) {
            const dirName = entry.name.toLowerCase();
            const dirPath = path.join(baseDir, entry.name);
            
            // Check if directory name contains emulator names
            for (const [id, config] of Object.entries(emulatorConfigs)) {
              if (dirName.includes(id.toLowerCase())) {
                logger.debug(`Found potential emulator directory: ${dirPath}`);
                
                // Add the directory and potential save subdirectories
                if (!config.defaultPaths.generic.includes(dirPath)) {
                  config.defaultPaths.generic.push(dirPath);
                }
                
                // Check for save subdirectories
                try {
                  const subEntries = await fs.readdir(dirPath, { withFileTypes: true });
                  for (const subEntry of subEntries) {
                    if (subEntry.isDirectory()) {
                      const subDirName = subEntry.name.toLowerCase();
                      if (['save', 'saves', 'savegames', 'savedata'].some(term => subDirName.includes(term))) {
                        const savePath = path.join(dirPath, subEntry.name);
                        logger.debug(`Found save directory for ${id}: ${savePath}`);
                        
                        if (!config.defaultPaths.generic.includes(savePath)) {
                          config.defaultPaths.generic.push(savePath);
                        }
                      }
                    }
                  }
                } catch (subError) {
                  logger.debug(`Error scanning subdirectories of ${dirPath}`, subError as Error);
                }
              }
            }
          }
        }
      }
    } catch (error) {
      logger.error(`Error scanning root directory: ${baseDir}`, error as Error);
    }
  }
  
  // Deep scan for save files in a directory regardless of emulator
  public async deepScanDirectory(directory: string): Promise<Map<string, string[]>> {
    const results = new Map<string, string[]>();
    
    logger.info(`Deep scanning directory: ${directory}`);
    
    try {
      // Combine all emulator extensions to scan for
      const allExtensions = new Set<string>();
      for (const config of Object.values(emulatorConfigs)) {
        config.saveExtensions.forEach(ext => allExtensions.add(ext));
      }
      
      // Convert set to array
      const extensions = Array.from(allExtensions);
      
      // Create pattern to match any save file
      const patterns = extensions.map(ext => path.join(directory, `**/*${ext}`));
      
      // Find all save files
      for (const pattern of patterns) {
        const files = await glob(pattern, { nodir: true, dot: true });
        
        // Categorize files by emulator based on extension
        for (const file of files) {
          const ext = path.extname(file).toLowerCase();
          
          // Find which emulator this file might belong to
          for (const [id, config] of Object.entries(emulatorConfigs)) {
            if (config.saveExtensions.includes(ext)) {
              // Add to results
              if (!results.has(id)) {
                results.set(id, []);
              }
              results.get(id)!.push(file);
              break;
            }
          }
        }
      }
      
      // Log results
      for (const [id, files] of results.entries()) {
        logger.info(`Found ${files.length} potential save files for ${id}`);
      }
      
      return results;
    } catch (error) {
      logger.error(`Error deep scanning directory: ${directory}`, error as Error);
      return results;
    }
  }
}

// Create and export an instance for convenience
export const emulatorDetector = new EmulatorDetector();
