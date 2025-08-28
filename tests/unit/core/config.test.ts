import { jest, describe, beforeEach, it, expect } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { ConfigManager, CloudSaverConfig, getConfigManager } from '../../../src/core/config.js';
import * as logger from '../../../src/core/logger.js';

// Mock fs-extra
jest.mock('fs-extra');

// Create a mock Conf implementation
const mockStore = {
  syncRoot: '/test/path',
  logLevel: 'info',
  customPaths: {},
};

const mockConfInstance = {
  get: jest.fn((key?: string) => key ? mockStore[key as keyof typeof mockStore] : mockStore),
  set: jest.fn(),
  store: mockStore,
  clear: jest.fn(),
  path: '/mock/path/to/config',
};

// Mock the conf module
jest.mock('conf', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => mockConfInstance)
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
    it('should return the config from the store', () => {
      const config = configManager.get();
      expect(config).toBeDefined();
      expect(mockConfInstance.get).toHaveBeenCalled();
    });
  });
  
  describe('getValue', () => {
    it('should return a specific config value', () => {
      mockConfInstance.get.mockReturnValueOnce('debug');
      const value = configManager.getValue('logLevel');
      expect(value).toBe('debug');
      expect(mockConfInstance.get).toHaveBeenCalledWith('logLevel');
    });
  });
  
  describe('set', () => {
    it('should set a specific config value', async () => {
      await configManager.set('logLevel', 'debug');
      expect(mockConfInstance.set).toHaveBeenCalledWith('logLevel', 'debug');
    });
  });
  
  describe('setMultiple', () => {
    it('should set multiple config values', async () => {
      await configManager.setMultiple({ logLevel: 'debug', autoSync: true });
      expect(mockConfInstance.set).toHaveBeenCalledWith('logLevel', 'debug');
      expect(mockConfInstance.set).toHaveBeenCalledWith('autoSync', true);
    });
  });
  
  describe('getConfigDir', () => {
    it('should return the config directory', () => {
      const configDir = configManager.getConfigDir();
      expect(configDir).toBeDefined();
      expect(typeof configDir).toBe('string');
    });
  });
});
