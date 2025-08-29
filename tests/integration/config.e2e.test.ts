import { jest, describe, it, beforeAll, afterAll, beforeEach, afterEach, expect } from '@jest/globals';
import os from 'os';
import path from 'path';
import fs from 'fs-extra';

let tmpRoot: string;
let consoleSpy: jest.SpiedFunction<typeof console.log>;
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
});

afterAll(async () => {
  try { await fs.remove(tmpRoot); } catch {}
});

beforeEach(() => {
  consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
});

afterEach(() => {
  consoleSpy.mockRestore();
});

describe('config command e2e', () => {
  it('set/get persists values end-to-end', async () => {
    // Use test seam to control Conf instance
    const mockConf = {
      get: jest.fn((key?: string) => {
        if (key === 'autoSync') return false;
        if (!key) return { autoSync: false, logLevel: 'info' };
        return undefined;
      }),
      set: jest.fn(),
      store: { autoSync: false },
      clear: jest.fn(),
      path: path.join(tmpRoot, 'config.json'),
    };

    const { ConfigManager } = await import('../../src/core/config.js');
    ConfigManager.__resetForTests();
    ConfigManager.__setConfForTests(mockConf);

    const { configCommand } = await import('../../src/cli/commands/config.js');

    // Set values (focus on autoSync which is a boolean toggle)
    consoleSpy.mockClear();
    await configCommand.parseAsync(['set', 'autoSync', 'true'], { from: 'user' });
    let out = stripAnsi(consoleSpy.mock.calls.flat().join('\n'));
    expect(out).toMatch(/Successfully set autoSync/i);
    expect(mockConf.set).toHaveBeenCalledWith('autoSync', true);

    // Get all - update mock to return new value
    consoleSpy.mockClear();
    mockConf.get.mockReturnValue({ autoSync: true, logLevel: 'info' });
    await configCommand.parseAsync(['get'], { from: 'user' });
    out = stripAnsi(consoleSpy.mock.calls.flat().join('\n'));
    expect(out).toContain('autoSync');
  });
});
