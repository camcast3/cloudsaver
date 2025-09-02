import path from 'path';
import fs from 'fs-extra';
import { logger } from '../core/logger.js';
import { Emulator } from '../core/emulator.js';

// Dolphin emulator implementation
export class DolphinEmulator implements Emulator {
  id = 'dolphin';
  name = 'Dolphin';
  savePaths: string[] = [];
  saveExtensions = ['.sav', '.gci', '.dat', '.raw', '.bin'];
  statePaths?: string[] = [];
  stateExtensions?: string[] = ['.s##', '.state'];
  configPaths?: string[] = [];
  
  constructor(detectedPaths: string[]) {
    this.savePaths = detectedPaths;
    logger.debug(`Initialized Dolphin emulator with save paths: ${this.savePaths.join(', ')}`);
  }
  
  /**
   * Gets the save directory structure for Dolphin
   * Dolphin has GC and Wii saves in different formats and locations
   */
  getSaveFileStructure() {
    const structure = {
      gamecube: {
        path: path.join('GC', 'Card A'),
        extensions: ['.gci'],
      },
      wii: {
        path: path.join('Wii', 'title'),
        extensions: ['.bin', '.dat'],
      }
    };
    
    return structure;
  }
  
  /**
   * Get a list of all save files
   */
  async getAllSaveFiles(): Promise<string[]> {
    const files: string[] = [];
    
    for (const savePath of this.savePaths) {
      if (await fs.pathExists(savePath)) {
        // For GameCube saves
        const gcPath = path.join(savePath, 'GC', 'Card A');
        if (await fs.pathExists(gcPath)) {
          const gcFiles = await fs.readdir(gcPath);
          files.push(...gcFiles.filter(f => f.endsWith('.gci')).map(f => path.join(gcPath, f)));
        }
        
        // For Wii saves (more complex structure)
        const wiiPath = path.join(savePath, 'Wii', 'title');
        if (await fs.pathExists(wiiPath)) {
          // Recursively find all Wii save files
          const wiiFiles = await this.findFilesRecursively(wiiPath, ['.bin', '.dat']);
          files.push(...wiiFiles);
        }
      }
    }
    
    return files;
  }
  
  /**
   * Helper method to recursively find files with specific extensions
   */
  private async findFilesRecursively(dir: string, extensions: string[]): Promise<string[]> {
    const files: string[] = [];
    
    try {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
          const subDirFiles = await this.findFilesRecursively(fullPath, extensions);
          files.push(...subDirFiles);
        } else if (entry.isFile() && extensions.some(ext => entry.name.endsWith(ext))) {
          files.push(fullPath);
        }
      }
    } catch (error) {
      logger.error(`Error reading directory ${dir}:`, error as Error);
    }
    
    return files;
  }
}
