import { jest, describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { helloCommand } from '../../../src/cli/commands/hello.js';

describe('helloCommand', () => {
  let logSpy: any;

  beforeEach(() => {
    logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    logSpy.mockRestore();
  });

  it('prints greeting with provided name', async () => {
    await helloCommand.parseAsync(['--name', 'Tester'], { from: 'user' });
    expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('Hello, Tester!'));
  });

  it('prints default greeting when name is omitted', async () => {
    await helloCommand.parseAsync([], { from: 'user' });
    expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('Hello, World!'));
  });
});
