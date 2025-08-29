import { jest, describe, beforeAll, afterAll, expect, test, beforeEach } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';
import { Emulator } from '../../../src/core/emulator.js';
import { getConfigManager } from '../../../src/core/config.js';
import { syncEmulator, __setExecAsyncForTests } from '../../../src/cli/commands/advanced-sync.js';

// Jest mock for execAsync injection
const mockExecAsync = jest.fn() as jest.Mock<any>;

// Mock emulator for testing
const mockEmulator: Emulator = {
  id: 'test-emulator',
  name: 'Test Emulator',
  savePaths: [path.join(os.tmpdir(), 'cloudsaver-test-saves')],
  saveExtensions: ['.sav', '.dat'],
  statePaths: [path.join(os.tmpdir(), 'cloudsaver-test-states')],
  stateExtensions: ['.state'],
  configPaths: [path.join(os.tmpdir(), 'cloudsaver-test-config')],
};

beforeAll(async () => {
  // Create test directories
  await fs.ensureDir(mockEmulator.savePaths[0]);
  await fs.ensureDir(mockEmulator.statePaths![0]);
  await fs.ensureDir(mockEmulator.configPaths![0]);

  // Create test files
  await fs.writeFile(path.join(mockEmulator.savePaths[0], 'game1.sav'), 'test save data');
  await fs.writeFile(path.join(mockEmulator.savePaths[0], 'game2.dat'), 'test dat data');
  await fs.writeFile(path.join(mockEmulator.statePaths![0], 'game1.state'), 'test state data');

  // Configure sync settings
  const configManager = await getConfigManager();
  await configManager.set('cloudProvider', 'test-remote');
  await configManager.set('syncRoot', path.join(os.tmpdir(), 'cloudsaver-test-cloud'));
});

afterAll(async () => {
  // Clean up test directories
  await fs.remove(mockEmulator.savePaths[0]);
  await fs.remove(mockEmulator.statePaths![0]);
  await fs.remove(mockEmulator.configPaths![0]);

  // Clean up cloud directory
  const configManager = await getConfigManager();
  const config = configManager.get();
  await fs.remove(config.syncRoot);
});

beforeEach(() => {
  jest.clearAllMocks();
  mockExecAsync.mockReset();
  __setExecAsyncForTests(((cmd: string) => mockExecAsync(cmd)) as any);
});

describe('Advanced Sync Command', () => {
  test('Should sync emulator saves for upload', async () => {
    mockExecAsync.mockResolvedValue({ stdout: 'Success', stderr: '' } as any);

    const result = await syncEmulator(mockEmulator, 'upload', {
      provider: 'test-remote',
      dryRun: true,
    });
    expect(result).toBe(true);
  });

  test('Should sync emulator saves for download', async () => {
    mockExecAsync.mockResolvedValue({ stdout: 'Success', stderr: '' } as any);

    const result = await syncEmulator(mockEmulator, 'download', {
      provider: 'test-remote',
      dryRun: true,
    });
    expect(result).toBe(true);
  });

  test('Should handle sync failure gracefully', async () => {
    mockExecAsync.mockRejectedValue(new Error('Command failed'));

    const result = await syncEmulator(mockEmulator, 'upload', {
      provider: 'test-remote',
      dryRun: true,
    });
    expect(result).toBe(false);
  });
});
