import { jest, describe, it, expect } from '@jest/globals';

// ESM-safe mock for winston to avoid file IO and simplify transports
await jest.unstable_mockModule('winston', () => {
  const logFn = jest.fn();
  return {
    __esModule: true,
    default: {
      createLogger: () => ({
        level: 'info',
        log: logFn,
        debug: logFn,
        verbose: logFn,
        info: logFn,
        warn: logFn,
        error: logFn,
        transports: [],
      }),
      format: {
        combine: jest.fn((...args) => args),
        colorize: jest.fn(() => (input: any) => input),
        timestamp: jest.fn(() => (input: any) => input),
        printf: jest.fn((fn: any) => fn),
      },
      transports: {
        Console: jest.fn(function(){ return {}; }),
        File: jest.fn(function(){ return {}; }),
      },
    },
  };
});

const { Logger, logger } = await import('../../../src/core/logger.js');

// Basic smoke tests to ensure logger methods don't throw

describe('Logger', () => {
  it('singleton returns same instance', () => {
    const a = Logger.getInstance();
    const b = Logger.getInstance();
    expect(a).toBe(b);
  });

  it('supports level reconfiguration', () => {
    const inst = Logger.getInstance();
    expect(() => inst.configure({ level: 'debug' })).not.toThrow();
  });

  it('exposes a default exported logger', () => {
    expect(logger).toBeDefined();
    expect(typeof (logger as any).info).toBe('function');
  });

  it('log methods execute without throwing', () => {
    const inst = Logger.getInstance();
    expect(() => inst.debug('debug msg', { a: 1 })).not.toThrow();
    expect(() => inst.info('info msg')).not.toThrow();
    expect(() => inst.warn('warn msg')).not.toThrow();
    expect(() => inst.error('error msg', new Error('boom'))).not.toThrow();
    expect(() => inst.fatal('fatal msg', new Error('boom'))).not.toThrow();
  });
});
