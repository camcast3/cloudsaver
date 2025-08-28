import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { exec } from 'child_process';
import util from 'util';
import { logger } from '../core/logger.js';
import { getConfigManager } from '../core/config.js';

// Promisify exec
const execAsync = util.promisify(exec);

/**
 * RClone configuration manager
 */
export class RCloneManager {
  private configPath: string;
  
  constructor() {
    // rclone config is typically stored in ~/.config/rclone/rclone.conf
    this.configPath = path.join(os.homedir(), '.config', 'rclone', 'rclone.conf');
    
    // For Windows, the path is different
    if (os.platform() === 'win32') {
      this.configPath = path.join(os.homedir(), 'AppData', 'Roaming', 'rclone', 'rclone.conf');
    }
  }
  
  /**
   * Check if rclone is installed
   */
  async isInstalled(): Promise<boolean> {
    try {
      await execAsync('rclone version');
      return true;
    } catch (error) {
      return false;
    }
  }
  
  /**
   * Install rclone on the current platform
   */
  async install(): Promise<boolean> {
    try {
      const platform = os.platform();
      
      if (platform === 'linux') {
        // Try to install rclone using the package manager
        try {
          logger.info('Attempting to install rclone via package manager...');
          
          // Check for apt (Debian, Ubuntu)
          await execAsync('which apt').then(async () => {
            await execAsync('sudo apt update && sudo apt install -y rclone');
          }).catch(async () => {
            // Check for dnf (Fedora, RHEL)
            await execAsync('which dnf').then(async () => {
              await execAsync('sudo dnf install -y rclone');
            }).catch(async () => {
              // Check for pacman (Arch)
              await execAsync('which pacman').then(async () => {
                await execAsync('sudo pacman -S --noconfirm rclone');
              }).catch(async () => {
                throw new Error('Unable to detect a supported package manager');
              });
            });
          });
          
          return await this.isInstalled();
        } catch (error) {
          logger.error('Failed to install rclone via package manager', error as Error);
          
          // Fallback to direct download
          logger.info('Falling back to direct download...');
          await execAsync('curl https://rclone.org/install.sh | sudo bash');
          return await this.isInstalled();
        }
      } else if (platform === 'darwin') {
        // Install via Homebrew on macOS
        try {
          await execAsync('brew install rclone');
          return await this.isInstalled();
        } catch (error) {
          logger.error('Failed to install rclone via Homebrew', error as Error);
          return false;
        }
      } else if (platform === 'win32') {
        // Can't automatically install on Windows
        logger.info('Please install rclone from https://rclone.org/downloads/');
        return false;
      }
      
      return false;
    } catch (error) {
      logger.error('Failed to install rclone', error as Error);
      return false;
    }
  }
  
  /**
   * Get list of configured remotes
   */
  async listRemotes(): Promise<string[]> {
    try {
      const { stdout } = await execAsync('rclone listremotes');
      return stdout.split('\n')
        .map(line => line.trim())
        .filter(line => line.length > 0)
        .map(line => line.replace(':', ''));
    } catch (error) {
      logger.error('Failed to list rclone remotes', error as Error);
      return [];
    }
  }
  
  /**
   * Test a remote connection
   */
  async testRemote(remoteName: string): Promise<boolean> {
    try {
      await execAsync(`rclone lsd ${remoteName}:`);
      return true;
    } catch (error) {
      logger.error(`Failed to test remote ${remoteName}`, error as Error);
      return false;
    }
  }
  
  /**
   * Sync files between local and remote
   */
  async sync(
    source: string, 
    destination: string, 
    options: {
      dryRun?: boolean;
      verbose?: boolean;
      logFile?: string;
    } = {}
  ): Promise<boolean> {
    try {
      let command = `rclone sync "${source}" "${destination}" --progress`;
      
      if (options.dryRun) {
        command += ' --dry-run';
      }
      
      if (options.verbose) {
        command += ' -v';
      }
      
      if (options.logFile) {
        command += ` --log-file="${options.logFile}"`;
      }
      
      logger.debug(`Running rclone command: ${command}`);
      const { stdout, stderr } = await execAsync(command);
      
      if (stderr && stderr.includes('ERROR')) {
        logger.error(`rclone sync error: ${stderr}`);
        return false;
      }
      
      logger.debug(`rclone sync output: ${stdout}`);
      return true;
    } catch (error) {
      logger.error('Failed to sync with rclone', error as Error);
      return false;
    }
  }
  
  /**
   * Configure a new remote
   * Note: This is interactive and requires user input,
   * so it's better to guide users to run 'rclone config' manually
   */
  async configureNewRemote(): Promise<void> {
    logger.info('To configure a new rclone remote, please run:');
    logger.info('rclone config');
    logger.info('Then follow the interactive prompts');
  }
}

// Singleton instance
export const rcloneManager = new RCloneManager();
