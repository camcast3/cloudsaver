import { jest, describe, beforeEach, afterEach, it, expect } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import Conf from 'conf';
import { ConfigManager } from '../../src/core/config.js';

describe('config command negative paths', () => {
  let tempDir: string;
  let originalEnv: NodeJS.ProcessEnv;
  let testConf: Conf<any>;

  beforeEach(async () => {
    // Create isolated temp directory
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'cloudsaver-config-neg-'));
    
    // Preserve original environment
    originalEnv = { ...process.env };
    
    // Set environment for config isolation
    process.env.APPDATA = path.join(tempDir, 'AppData', 'Roaming');
    process.env.HOME = tempDir;
    process.env.USERPROFILE = tempDir;
    process.env.XDG_CONFIG_HOME = path.join(tempDir, '.config');
    
    // Ensure directories exist
    await fs.ensureDir(path.join(tempDir, 'AppData', 'Roaming'));
    await fs.ensureDir(path.join(tempDir, '.config'));
    
    // Create test conf instance
    testConf = new Conf({
      projectName: 'cloudsaver-test',
      schema: {
        syncRoot: { type: 'string', default: path.join(tempDir, '.cloudsaver') },
        logLevel: { type: 'string', default: 'info' },
        customPaths: { type: 'object', default: {} },
        emulatorPaths: { type: 'object', default: {} },
        scanDirs: { type: 'array', default: [], items: { type: 'string' } },
        ignoreDirs: { type: 'array', default: [], items: { type: 'string' } },
        autoSync: { type: 'boolean', default: false },
      }
    });
    
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(testConf);
  });

  afterEach(async () => {
    // Restore environment
    process.env = originalEnv;
    ConfigManager.__resetForTests();
    
    // Clean up temp directory
    try {
      await fs.remove(tempDir);
    } catch (error) {
      // Ignore cleanup errors in tests
    }
  });

  it('should handle invalid config key for ConfigManager set', async () => {
    const configManager = await ConfigManager.getInstance();
    
    // Test with invalid key - should throw due to schema validation
    await expect(
      configManager.set('nonExistentKey' as any, 'value')
    ).rejects.toThrow(/Invalid configuration key/);
  });

  it('should handle invalid config key for ConfigManager get', async () => {
    const configManager = await ConfigManager.getInstance();
    
    // Try to get with an invalid config key
    const result = configManager.getValue('nonExistentKey' as any);
    
    // Should return undefined for non-existent keys
    expect(result).toBeUndefined();
  });

  it('should handle invalid JSON structure for complex config values', async () => {
    const configManager = await ConfigManager.getInstance();
    
    // Try to set invalid structure for emulatorPaths (should be object)
    await expect(
      configManager.set('emulatorPaths', 'invalid string' as any)
    ).rejects.toThrow();
  });

  it('should validate enum values for logLevel', async () => {
    const configManager = await ConfigManager.getInstance();
    
    // Try to set invalid log level
    await expect(
      configManager.set('logLevel', 'invalid-level' as any)
    ).rejects.toThrow();
    
    // Valid log levels should work
    await expect(
      configManager.set('logLevel', 'debug')
    ).resolves.not.toThrow();
  });
});
