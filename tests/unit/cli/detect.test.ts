import { jest, describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { detectCommand } from '../../../src/cli/commands/detect.js';

describe('detectCommand', () => {
  let logSpy: any;

  beforeEach(() => {
    logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    logSpy.mockRestore();
  });

  it('rejects invalid platform types', async () => {
    await detectCommand.parseAsync(['--platform', 'not-a-platform'], { from: 'user' });
    const calls = logSpy.mock.calls.flat().join('\n');
    expect(calls).toContain('Invalid platform type');
  });
});
