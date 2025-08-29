import { jest, describe, beforeEach, it, expect } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';

describe('ConfigManager', () => {
  let tempDir: string;
  let originalEnv: NodeJS.ProcessEnv;

  beforeEach(async () => {
    // Create isolated temp directory for each test
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'cloudsaver-config-unit-'));
    
    // Preserve original environment
    originalEnv = { ...process.env };
    
    // Set environment for config isolation
    process.env.APPDATA = path.join(tempDir, 'AppData', 'Roaming');
    process.env.HOME = tempDir;
    process.env.USERPROFILE = tempDir;
    process.env.XDG_CONFIG_HOME = path.join(tempDir, '.config');

    // Reset the ConfigManager singleton for isolated tests
    const { ConfigManager } = await import('../../../src/core/config.js');
    ConfigManager.__resetForTests();
  });

  afterEach(async () => {
    // Restore environment
    process.env = originalEnv;
    
    // Clean up temp directory
    try {
      await fs.remove(tempDir);
    } catch (error) {
      // Ignore cleanup errors in tests
    }
  });

  it('should get and set config values', async () => {
    const { getConfigManager } = await import('../../../src/core/config.js');
    const configManager = await getConfigManager();
    
    // Test getting default value
    const defaultLogLevel = configManager.getValue('logLevel');
    expect(defaultLogLevel).toBe('info');
    
    // Test setting a value
    await configManager.set('logLevel', 'debug');
    const updatedLogLevel = configManager.getValue('logLevel');
    expect(updatedLogLevel).toBe('debug');
  });

  it('should validate config values with schema', async () => {
    const { getConfigManager } = await import('../../../src/core/config.js');
    const configManager = await getConfigManager();
    
    // Test valid enum value
    await expect(configManager.set('logLevel', 'debug')).resolves.not.toThrow();
    
    // Test invalid enum value should throw
    await expect(configManager.set('logLevel', 'invalid-level' as any)).rejects.toThrow();
    
    // Test valid object structure
    await expect(configManager.set('emulatorPaths', { dolphin: ['/test/path'] })).resolves.not.toThrow();
    
    // Test invalid object structure should throw
    await expect(configManager.set('emulatorPaths', 'not an object' as any)).rejects.toThrow();
  });

  it('should handle multiple config values', async () => {
    const { getConfigManager } = await import('../../../src/core/config.js');
    const configManager = await getConfigManager();
    
    await configManager.setMultiple({
      logLevel: 'debug',
      autoSync: true
    });
    
    expect(configManager.getValue('logLevel')).toBe('debug');
    expect(configManager.getValue('autoSync')).toBe(true);
  });

  it('should return config directory', async () => {
    const { getConfigManager } = await import('../../../src/core/config.js');
    const configManager = await getConfigManager();
    
    const configDir = configManager.getConfigDir();
    expect(configDir).toContain('.config');
    expect(configDir).toContain('cloudsaver');
  });
});
