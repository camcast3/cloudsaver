import { jest, describe, it, beforeAll, afterAll, beforeEach, afterEach, expect } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';

let tmpRoot: string;
let consoleSpy: jest.SpiedFunction<typeof console.log>;

beforeAll(async () => {
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'cloudsaver-detect-e2e-'));
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

describe('detect command e2e (with mocks)', () => {
  it('prints platform and emulator summary using mocked detectors', async () => {
    // ESM-safe mocks
    await jest.unstable_mockModule('../../src/core/platform.js', () => ({
      __esModule: true,
      platformDetector: {
        detectPlatform: jest.fn(async () => ({ name: 'MockOS', type: 'generic', baseDir: tmpRoot })),
      },
    }));

    await jest.unstable_mockModule('../../src/core/emulator.js', () => ({
      __esModule: true,
      emulatorDetector: {
        detectEmulators: jest.fn(async () => new Map([
          ['retroarch', { id: 'retroarch', name: 'RetroArch', savePaths: [path.join(tmpRoot, 'retro', 'saves')] }],
        ])),
        deepScanDirectory: jest.fn(async () => new Map([
          ['retroarch', [path.join(tmpRoot, 'retro', 'saves', 'file1.srm')]],
        ])),
      },
    }));

    let detectCommand: any;
    await jest.isolateModulesAsync(async () => {
      ({ detectCommand } = await import('../../src/cli/commands/detect.js'));
    });

    // Basic run
    await detectCommand.parseAsync([], { from: 'user' });
    let out = consoleSpy.mock.calls.flat().join('\n');
    expect(out).toContain('Detected platform:');
    expect(out).toContain('Detected 1 emulators');

    // Deep scan
    consoleSpy.mockClear();
    await detectCommand.parseAsync(['--deep-scan', tmpRoot], { from: 'user' });
    out = consoleSpy.mock.calls.flat().join('\n');
    expect(out).toContain('Deep scan found save files for');
  });
});
