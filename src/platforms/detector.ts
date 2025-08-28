import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { exec } from 'child_process';
import util from 'util';
import { logger } from '../core/logger.js';

// Promisify exec
const execAsync = util.promisify(exec);

export enum PlatformType {
  EMUDECK = 'emudeck',
  RETROPIE = 'retropie',
  BATOCERA = 'batocera',
  LAKKA = 'lakka',
  EMULATIONSTATION = 'emulationstation',
  WINDOWS = 'windows',
  MACOS = 'macos',
  LINUX = 'linux',
  STEAMDECK = 'steamdeck',
  BAZZITE = 'bazzite',
  GENERIC = 'generic'
}

export interface Platform {
  type: PlatformType;
  isLinux: boolean;
  isWindows: boolean;
  isMacOS: boolean;
  isSteamOS: boolean;
  isBazzite: boolean;
  homeDir: string;
  documentsDir: string;
  configDir: string;
}

/**
 * Detect the current platform
 */
export async function detectPlatform(): Promise<Platform> {
  const platform = os.platform();
  const homeDir = os.homedir();
  let documentsDir = '';
  let configDir = '';
  
  const isLinux = platform === 'linux';
  const isWindows = platform === 'win32';
  const isMacOS = platform === 'darwin';
  
  // Set up documents directory based on platform
  if (isWindows) {
    documentsDir = path.join(homeDir, 'Documents');
  } else if (isMacOS) {
    documentsDir = path.join(homeDir, 'Documents');
  } else {
    documentsDir = homeDir;
  }
  
  // Set up config directory based on platform
  if (isWindows) {
    configDir = path.join(homeDir, 'AppData', 'Roaming', 'CloudSaver');
  } else if (isMacOS) {
    configDir = path.join(homeDir, 'Library', 'Application Support', 'CloudSaver');
  } else {
    configDir = path.join(homeDir, '.config', 'cloudsaver');
  }
  
  // Create config directory if it doesn't exist
  await fs.ensureDir(configDir);
  
  // Start with a generic platform type
  let type: PlatformType = PlatformType.GENERIC;
  let isSteamOS = false;
  let isBazzite = false;
  
  // Detect specific Linux distributions and environments
  if (isLinux) {
    // Check for SteamOS
    if (await fileExists('/etc/os-release')) {
      const osRelease = await fs.readFile('/etc/os-release', 'utf8');
      if (osRelease.includes('SteamOS')) {
        isSteamOS = true;
        type = PlatformType.STEAMDECK;
      }
      
      // Check for Bazzite
      if (osRelease.includes('Bazzite')) {
        isBazzite = true;
        type = PlatformType.BAZZITE;
      }
    }
    
    // Check for RetroPie
    if (await fileExists('/opt/retropie')) {
      type = PlatformType.RETROPIE;
    }
    
    // Check for Batocera
    if (await fileExists('/usr/batocera')) {
      type = PlatformType.BATOCERA;
    }
    
    // Check for Lakka
    if (await fileExists('/etc/lakka-version')) {
      type = PlatformType.LAKKA;
    }
    
    // Check for EmuDeck
    if (await fileExists(path.join(homeDir, 'emudeck'))) {
      type = PlatformType.EMUDECK;
    }
  } else if (isWindows) {
    // Check for EmulationStation on Windows
    if (await fileExists(path.join(homeDir, '.emulationstation'))) {
      type = PlatformType.EMULATIONSTATION;
    } else {
      type = PlatformType.WINDOWS;
    }
  } else if (isMacOS) {
    type = PlatformType.MACOS;
  }
  
  logger.debug(`Detected platform: ${type}`);
  
  return {
    type,
    isLinux,
    isWindows,
    isMacOS,
    isSteamOS,
    isBazzite,
    homeDir,
    documentsDir,
    configDir
  };
}

/**
 * Helper function to check if a file exists
 */
async function fileExists(file: string): Promise<boolean> {
  try {
    await fs.access(file, fs.constants.F_OK);
    return true;
  } catch (error) {
    return false;
  }
}

// Singleton platform detector instance
export const platformDetector = {
  platform: null as Platform | null,
  
  async detect(): Promise<Platform> {
    if (!this.platform) {
      this.platform = await detectPlatform();
    }
    return this.platform;
  },
  
  async getPlatform(): Promise<Platform> {
    return this.detect();
  }
};
