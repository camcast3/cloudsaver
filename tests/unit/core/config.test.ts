import { jest } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { ConfigManager, CloudSaverConfig, getConfigManager } from '../../../src/core/config.js';

// Mock fs-extra
jest.mock('fs-extra', () => ({
  ensureDirSync: jest.fn(),
}));

// Mock conf module
jest.mock('conf', () => {
  const mockConf = {
    get: jest.fn(),
    set: jest.fn(),
    store: {},
    clear: jest.fn(),
    path: '/mock/path/to/config',
  };
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => mockConf)
  };
});

// Mock logger
jest.mock('../../../src/core/logger.js', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  }
}));

describe('ConfigManager', () => {
  let configManager: ConfigManager;
  
  beforeEach(async () => {
    jest.clearAllMocks();
    configManager = await getConfigManager();
  });
  
  it('should be a singleton', async () => {
    const configManager1 = await getConfigManager();
    const configManager2 = await getConfigManager();
    expect(configManager1).toBe(configManager2);
  });
  
  describe('get', () => {
    it('should return default config when conf is not initialized', () => {
      // @ts-ignore - Mock private property
      configManager.conf = null;
      const config = configManager.get();
      expect(config).toEqual(expect.objectContaining({
        syncRoot: expect.any(String),
        logLevel: 'info',
        customPaths: {},
        emulatorPaths: {},
        scanDirs: [],
        ignoreDirs: [],
        autoSync: false,
      }));
    });
    
    it('should return the store when conf is initialized', () => {
      // @ts-ignore - Mock private property
      configManager.conf.store = { 
        syncRoot: '/test/path', 
        logLevel: 'debug',
        customPaths: { test: 'path' } 
      };
      const config = configManager.get();
      expect(config).toEqual({ 
        syncRoot: '/test/path', 
        logLevel: 'debug',
        customPaths: { test: 'path' } 
      });
    });
  });
  
  describe('getValue', () => {
    it('should return default value when conf is not initialized', () => {
      // @ts-ignore - Mock private property
      configManager.conf = null;
      const value = configManager.getValue('logLevel');
      expect(value).toBe('info');
    });
    
    it('should return specific config value when conf is initialized', () => {
      // @ts-ignore - Mock private property
      configManager.conf.get.mockReturnValueOnce('debug');
      const value = configManager.getValue('logLevel');
      expect(value).toBe('debug');
      // @ts-ignore - Mock private property
      expect(configManager.conf.get).toHaveBeenCalledWith('logLevel');
    });
    
    it('should handle errors and return default value', () => {
      // @ts-ignore - Mock private property
      configManager.conf.get.mockImplementationOnce(() => {
        throw new Error('Test error');
      });
      const value = configManager.getValue('logLevel');
      expect(value).toBe('info');
    });
  });
  
  describe('set', () => {
    it('should not set value when conf is not initialized', async () => {
      // @ts-ignore - Mock private property
      configManager.conf = null;
      await configManager.set('logLevel', 'debug');
      // We expect no error and no call to set
      // @ts-ignore - Mock private property
      expect(configManager.conf?.set).not.toHaveBeenCalled();
    });
    
    it('should set a specific config value when conf is initialized', async () => {
      await configManager.set('logLevel', 'debug');
      // @ts-ignore - Mock private property
      expect(configManager.conf.set).toHaveBeenCalledWith('logLevel', 'debug');
    });
    
    it('should handle errors when setting values', async () => {
      // @ts-ignore - Mock private property
      configManager.conf.set.mockImplementationOnce(() => {
        throw new Error('Test error');
      });
      
      await expect(configManager.set('logLevel', 'debug')).rejects.toThrow('Test error');
    });
  });
  
  describe('setMultiple', () => {
    it('should not set values when conf is not initialized', async () => {
      // @ts-ignore - Mock private property
      configManager.conf = null;
      await configManager.setMultiple({ logLevel: 'debug', autoSync: true });
      // We expect no error and no call to set
      // @ts-ignore - Mock private property
      expect(configManager.conf?.set).not.toHaveBeenCalled();
    });
    
    it('should set multiple config values when conf is initialized', async () => {
      await configManager.setMultiple({ logLevel: 'debug', autoSync: true });
      // @ts-ignore - Mock private property
      expect(configManager.conf.set).toHaveBeenCalledWith('logLevel', 'debug');
      // @ts-ignore - Mock private property
      expect(configManager.conf.set).toHaveBeenCalledWith('autoSync', true);
    });
  });
  
  describe('setValue', () => {
    it('should throw when conf is not initialized', () => {
      // @ts-ignore - Mock private property
      configManager.conf = null;
      expect(() => configManager.setValue('logLevel', 'debug')).toThrow('Configuration not initialized');
    });
    
    it('should validate and set a specific config value', () => {
      configManager.setValue('logLevel', 'debug');
      // @ts-ignore - Mock private property
      expect(configManager.conf.set).toHaveBeenCalledWith('logLevel', 'debug');
    });
    
    it('should throw on validation error', () => {
      expect(() => {
        // @ts-ignore - Intentionally passing invalid value for test
        configManager.setValue('logLevel', 'invalid-level');
      }).toThrow();
    });
  });
  
  describe('reset', () => {
    it('should throw when conf is not initialized', () => {
      // @ts-ignore - Mock private property
      configManager.conf = null;
      expect(() => configManager.reset()).toThrow('Configuration not initialized');
    });
    
    it('should clear the configuration', () => {
      configManager.reset();
      // @ts-ignore - Mock private property
      expect(configManager.conf.clear).toHaveBeenCalled();
    });
  });
  
  describe('getConfigDir', () => {
    it('should return the config directory', () => {
      // @ts-ignore - Mock private property
      configManager.configDir = '/test/config/dir';
      expect(configManager.getConfigDir()).toBe('/test/config/dir');
    });
  });
});
