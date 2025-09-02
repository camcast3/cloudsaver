import { jest, describe, beforeEach, afterEach, it, expect } from '@jest/globals';
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

    await fs.ensureDir(process.env.APPDATA);
    await fs.ensureDir(path.join(tempDir, '.config'));
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
    // Create a mock conf instance
    const mockConf = {
      get: jest.fn((key) => {
        if (key === 'logLevel') return 'info';
        return undefined;
      }),
      set: jest.fn(),
      store: { logLevel: 'info' },
      clear: jest.fn(),
      path: path.join(tempDir, 'config.json')
    };

    const { ConfigManager } = await import('../../../src/core/config.js');
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(mockConf);
    
    const configManager = await ConfigManager.getInstance();
    
    // Test getting default value
    const defaultLogLevel = configManager.getValue('logLevel');
    expect(defaultLogLevel).toBe('info');
    expect(mockConf.get).toHaveBeenCalledWith('logLevel');
    
    // Test setting a value
    await configManager.set('logLevel', 'debug');
    expect(mockConf.set).toHaveBeenCalledWith('logLevel', 'debug');
  });

  it('should validate config persistence with test seam', async () => {
    const mockConf = {
      get: jest.fn((key) => {
        if (key === 'emulatorPaths') return { dolphin: ['/test/path'] };
        return undefined;
      }),
      set: jest.fn(),
      store: { emulatorPaths: { dolphin: ['/test/path'] } },
      clear: jest.fn(),
      path: path.join(tempDir, 'config.json')
    };

    const { ConfigManager } = await import('../../../src/core/config.js');
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(mockConf);
    
    const configManager = await ConfigManager.getInstance();
    
    // Test setting emulator paths
    await configManager.set('emulatorPaths', { dolphin: ['/test/path'] });
    expect(mockConf.set).toHaveBeenCalledWith('emulatorPaths', { dolphin: ['/test/path'] });
  });

  it('should handle setMultiple operation', async () => {
    const mockConf = {
      get: jest.fn(),
      set: jest.fn(),
      store: {},
      clear: jest.fn(),
      path: path.join(tempDir, 'config.json')
    };

    const { ConfigManager } = await import('../../../src/core/config.js');
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(mockConf);
    
    const configManager = await ConfigManager.getInstance();
    
    // Test setting multiple values
    await configManager.setMultiple({ logLevel: 'debug', autoSync: true });
    expect(mockConf.set).toHaveBeenCalledWith('logLevel', 'debug');
    expect(mockConf.set).toHaveBeenCalledWith('autoSync', true);
  });

  it('should handle reset operation', async () => {
    const mockConf = {
      get: jest.fn(),
      set: jest.fn(),
      store: {},
      clear: jest.fn(),
      path: path.join(tempDir, 'config.json')
    };

    const { ConfigManager } = await import('../../../src/core/config.js');
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(mockConf);
    
    const configManager = await ConfigManager.getInstance();
    
    // Test reset
    configManager.reset();
    expect(mockConf.clear).toHaveBeenCalled();
  });
});
