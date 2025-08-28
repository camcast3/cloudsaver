import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { z } from 'zod'; // Fixed import for zod
import { logger } from './logger.js';
import Conf from 'conf';

// Define configuration schema with Zod for validation
const configSchema = z.object({
  cloudProvider: z.string().optional(),
  syncRoot: z.string().default(path.join(os.homedir(), '.cloudsaver')),
  logLevel: z.enum(['debug', 'verbose', 'info', 'warn', 'error']).default('info'),
  customPaths: z.record(z.string(), z.string()).default({}),
  emulatorPaths: z.record(z.string(), z.array(z.string())).default({}),
  scanDirs: z.array(z.string()).default([]),
  ignoreDirs: z.array(z.string()).default([]),
  platform: z.enum(['emudeck', 'retropie', 'batocera', 'lakka', 'emulationstation', 'generic']).optional(),
  autoSync: z.boolean().default(false),
  lastSync: z.string().optional(),
});

// TypeScript type for our config
export type CloudSaverConfig = z.infer<typeof configSchema>;

// Default configuration
const defaultConfig: CloudSaverConfig = {
  syncRoot: path.join(os.homedir(), '.cloudsaver'),
  logLevel: 'info',
  customPaths: {},
  emulatorPaths: {},
  scanDirs: [],
  ignoreDirs: [],
  autoSync: false,
};

export class ConfigManager {
  private static instance: ConfigManager | null = null;
  private static testConf: any = null; // Test seam for injecting mock conf
  private conf: any;
  private configDir: string;
  
  private constructor() {
    this.configDir = path.join(os.homedir(), '.config', 'cloudsaver');
    
    // Ensure config directory exists
    fs.ensureDirSync(this.configDir);
    
    // Initialize configuration using dynamic import
    this.initializeConfig();
  }
  
  // Test-only hooks to override conf instance
  public static __setConfForTests(confInstance: any): void {
    ConfigManager.testConf = confInstance;
    if (ConfigManager.instance) {
      ConfigManager.instance.conf = confInstance;
    }
  }
  
  public static __resetForTests(): void {
    ConfigManager.instance = null as any;
    ConfigManager.testConf = null;
  }
  
  private async initializeConfig() {
    // If test conf is provided, use it instead
    if (ConfigManager.testConf) {
      this.conf = ConfigManager.testConf;
      return;
    }
    
    try {
      // Use static import instead of dynamic import
      this.conf = new Conf({
        projectName: 'cloudsaver',
        defaults: defaultConfig,
      });
      
      logger.debug('Configuration initialized', { 
        configPath: this.conf.path,
        defaults: defaultConfig 
      });
    } catch (error) {
      logger.error('Failed to initialize configuration', error as Error);
      throw error;
    }
  }
  
  // Singleton pattern
  public static async getInstance(): Promise<ConfigManager> {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
      await ConfigManager.instance.initializeConfig();
    }
    return ConfigManager.instance;
  }
  
  // Get entire config
  public get(): CloudSaverConfig {
    try {
      if (!this.conf) {
        logger.warn('Configuration not initialized yet');
        return defaultConfig;
      }
      
      const config = this.conf.store;
      logger.debug('Retrieved configuration', { config });
      return config;
    } catch (error) {
      logger.error('Failed to get configuration', error as Error);
      return defaultConfig;
    }
  }
  
  // Get a specific config value
  public getValue<K extends keyof CloudSaverConfig>(key: K): CloudSaverConfig[K] {
    try {
      if (!this.conf) {
        logger.warn(`Configuration not initialized yet, using default for ${String(key)}`);
        return defaultConfig[key];
      }
      
      const value = this.conf.get(key);
      logger.debug(`Retrieved config value for ${String(key)}`, { [key]: value });
      return value;
    } catch (error) {
      logger.error(`Failed to get value for ${String(key)}`, error as Error);
      return defaultConfig[key];
    }
  }
  
  // Set a config value
  public async set<K extends keyof CloudSaverConfig>(key: K, value: CloudSaverConfig[K]): Promise<void> {
    try {
      if (!this.conf) {
        logger.warn(`Configuration not initialized yet, can't set ${String(key)}`);
        return;
      }
      
      // Check if key exists in schema
      if (!(key in configSchema.shape)) {
        const error = new Error(`Invalid configuration key: ${String(key)}`);
        logger.error(`Invalid config key: ${String(key)}`, error);
        throw error;
      }
      
      // Validate with Zod schema before setting
      const partialConfig = { [key]: value } as unknown as Partial<CloudSaverConfig>;
      const partialSchema = z.object({ [key]: configSchema.shape[key] });
      partialSchema.parse(partialConfig);
      
      this.conf.set(key, value);
      logger.debug(`Set config value for ${String(key)}`, { [key]: value });
    } catch (error) {
      logger.error(`Failed to set value for ${String(key)}`, error as Error);
      throw error;
    }
  }
  
  // Set multiple config values at once
  public async setMultiple(values: Partial<CloudSaverConfig>): Promise<void> {
    try {
      if (!this.conf) {
        logger.warn(`Configuration not initialized yet, can't set multiple values`);
        return;
      }
      
      for (const [key, value] of Object.entries(values)) {
        this.conf.set(key, value);
      }
      
      logger.debug(`Set multiple config values`, values);
    } catch (error) {
      logger.error(`Failed to set multiple values`, error as Error);
      throw error;
    }
  }
  
  // Set a config value with validation
  public setValue<K extends keyof CloudSaverConfig>(
    key: K, 
    value: CloudSaverConfig[K]
  ): void {
    try {
      if (!this.conf) {
        logger.error(`Cannot set ${String(key)}: Configuration not initialized yet`);
        throw new Error('Configuration not initialized');
      }
      
      // Validate with Zod schema before setting
      const partialConfig = { [key]: value } as unknown as Partial<CloudSaverConfig>;
      const partialSchema = z.object({ [key]: configSchema.shape[key] });
      partialSchema.parse(partialConfig);
      
      this.conf.set(key, value);
      logger.debug(`Set config value for ${String(key)}`, { [key]: value });
    } catch (error) {
      logger.error(`Failed to set config value for ${String(key)}`, error as Error, { value });
      throw error;
    }
  }
  
  // Reset config to defaults
  public reset(): void {
    try {
      if (!this.conf) {
        logger.error('Cannot reset: Configuration not initialized yet');
        throw new Error('Configuration not initialized');
      }
      
      this.conf.clear();
      logger.info('Configuration reset to defaults');
    } catch (error) {
      logger.error('Failed to reset configuration', error as Error);
      throw error;
    }
  }
  
  // Get config directory
  public getConfigDir(): string {
    return this.configDir;
  }
}

// Export an initializer function for the config manager
export const getConfigManager = async () => {
  return ConfigManager.getInstance();
};

// Initialize the config manager immediately for simplicity
// This will be a Promise<ConfigManager>
export const configManagerPromise = ConfigManager.getInstance();
