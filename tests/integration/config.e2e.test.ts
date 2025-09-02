import { jest, describe, it, beforeAll, afterAll, beforeEach, afterEach, expect } from '@jest/globals';
import os from 'os';
import path from 'path';
import fs from 'fs-extra';
import Conf from 'conf';
import { ConfigManager } from '../../src/core/config.js';

let tmpRoot: string;
let consoleSpy: jest.SpiedFunction<typeof console.log>;
let testConf: Conf<any>;
let configManager: ConfigManager;
const stripAnsi = (s: string) => s.replace(/\u001b\[[0-9;]*m/g, '');

beforeAll(async () => {
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'cloudsaver-config-e2e-'));
  const appData = path.join(tmpRoot, 'AppData', 'Roaming');
  const homeDir = tmpRoot;
  const xdg = path.join(tmpRoot, 'xdg');
  await fs.ensureDir(appData);
  await fs.ensureDir(xdg);

  process.env.APPDATA = appData;        // Windows conf location
  process.env.HOME = homeDir;           // posix homedir
  process.env.USERPROFILE = homeDir;    // windows homedir
  process.env.XDG_CONFIG_HOME = xdg;    // posix conf location
  
  // Create test configuration with the isolated directory
  testConf = new Conf({
    projectName: 'cloudsaver',
    schema: {
      syncRoot: { type: 'string', default: path.join(homeDir, '.cloudsaver') },
      logLevel: { type: 'string', default: 'info' },
      customPaths: { type: 'object', default: {} },
      emulatorPaths: { type: 'object', default: {} },
      scanDirs: { type: 'array', default: [], items: { type: 'string' } },
      ignoreDirs: { type: 'array', default: [], items: { type: 'string' } },
      autoSync: { type: 'boolean', default: false },
    }
  });
});

afterAll(async () => {
  ConfigManager.__resetForTests();
  try { await fs.remove(tmpRoot); } catch {}
});

beforeEach(async () => {
  consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
  ConfigManager.__setConfForTests(testConf);
  configManager = await ConfigManager.getInstance();
});

afterEach(() => {
  consoleSpy.mockRestore();
});

describe('Config E2E Tests', () => {
  it('should persist configuration changes', async () => {
    // Set a value
    await configManager.set('autoSync', true);
    expect(configManager.getValue('autoSync')).toBe(true);

    // Create new manager instance and verify persistence
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(testConf);
    const newManager = await ConfigManager.getInstance();
    expect(newManager.getValue('autoSync')).toBe(true);
  });

  it('should handle reset operation', async () => {
    // Set some values
    await configManager.set('autoSync', true);
    await configManager.set('logLevel', 'debug');
    
    // Reset and verify defaults
    configManager.reset();
    expect(configManager.getValue('autoSync')).toBe(false);
    expect(configManager.getValue('logLevel')).toBe('info');
  });
});
