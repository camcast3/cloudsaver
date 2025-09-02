import { jest, describe, it, beforeAll, afterAll, beforeEach, afterEach, expect } from '@jest/globals';
import path from 'path';
import os from 'os';
import fs from 'fs-extra';

let tmpRoot: string;
let consoleSpy: jest.SpiedFunction<typeof console.log>;
const stripAnsi = (s: string) => s.replace(/\u001b\[[0-9;]*m/g, '');

beforeAll(async () => {
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'cloudsaver-paths-e2e-'));
  const homeDir = tmpRoot;
  const appData = path.join(tmpRoot, 'AppData', 'Roaming');
  const xdg = path.join(tmpRoot, 'xdg');
  await fs.ensureDir(appData);
  await fs.ensureDir(xdg);

  process.env.APPDATA = appData;
  process.env.HOME = homeDir;
  process.env.USERPROFILE = homeDir;
  process.env.XDG_CONFIG_HOME = xdg;
});

afterAll(async () => { try { await fs.remove(tmpRoot); } catch {} });

beforeEach(() => { consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {}); });
afterEach(() => { consoleSpy?.mockRestore(); });

describe('paths command e2e', () => {
  it('add/list/remove paths updates config', async () => {
    // isolate module registry to ensure clean ConfigManager instance with our env
    let pathsCommand: any;
    await jest.isolateModulesAsync(async () => {
      ({ pathsCommand } = await import('../../src/cli/commands/paths.js'));
    });
    const testDir = path.join(tmpRoot, 'saves');

    // Ensure starting clean
    await pathsCommand.parseAsync(['list'], { from: 'user' });

    // Add
    await pathsCommand.parseAsync(['add', 'dolphin', testDir], { from: 'user' });
    consoleSpy.mockClear();
    await pathsCommand.parseAsync(['list'], { from: 'user' });
  let out = stripAnsi(consoleSpy.mock.calls.flat().join('\n'));
  expect(out).toMatch(/dolphin:/);

    // Remove
    consoleSpy.mockClear();
    await pathsCommand.parseAsync(['remove', 'dolphin', testDir], { from: 'user' });
    await pathsCommand.parseAsync(['list'], { from: 'user' });
  out = stripAnsi(consoleSpy.mock.calls.flat().join('\n'));
  // After remove, either the emulator section is gone or list is empty
  expect(out).toMatch(/No custom paths configured|^\s*$/m);
  });
});
