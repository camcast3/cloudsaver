import { jest, describe, it, beforeEach, afterEach, expect } from '@jest/globals';

// Mock core/config to avoid initializing real Conf or touching disk
jest.unstable_mockModule('../../../src/core/config.js', () => ({
  __esModule: true,
  getConfigManager: jest.fn(async () => ({
    get: () => ({
      emulatorPaths: {},
      scanDirs: [],
      ignoreDirs: [],
    }),
    getValue: () => undefined,
    set: jest.fn(),
    reset: jest.fn(),
  })),
}));

// Dynamically import after mocks are in place
const { configCommand } = await import('../../../src/cli/commands/config.js');

// Spy console
let logSpy: jest.SpiedFunction<typeof console.log>;

beforeEach(() => {
  logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
});

afterEach(() => {
  logSpy.mockRestore();
});

describe('configCommand CLI', () => {
  it('shows error on invalid key for get', async () => {
    await configCommand.parseAsync(['get', 'notAKey'], { from: 'user' });
    const out = logSpy.mock.calls.flat().join('\n');
    expect(out).toContain('Invalid configuration key');
  });

  it('shows error on invalid key for set', async () => {
    await configCommand.parseAsync(['set', 'notAKey', 'value'], { from: 'user' });
    const out = logSpy.mock.calls.flat().join('\n');
    expect(out).toContain('Invalid configuration key');
  });

  it('reset without --force warns and returns', async () => {
    await configCommand.parseAsync(['reset'], { from: 'user' });
    const out = logSpy.mock.calls.flat().join('\n');
    expect(out).toContain('This will reset all configuration');
  });
});
