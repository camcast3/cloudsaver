import { jest, describe, beforeEach, afterEach, it, expect } from '@jest/globals';
import fs from 'fs-extra';
import path from 'path';
import os from 'os';

describe('advanced-sync command e2e', () => {
  let tempDir: string;
  let mockExecAsync: jest.MockedFunction<any>;
  let originalEnv: NodeJS.ProcessEnv;

  beforeEach(async () => {
    // Create isolated temp directory
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'cloudsaver-adv-sync-e2e-'));
    
    // Preserve original environment
    originalEnv = { ...process.env };
    
    // Set environment for config isolation
    process.env.APPDATA = path.join(tempDir, 'AppData', 'Roaming');
    process.env.HOME = tempDir;
    process.env.USERPROFILE = tempDir;
    process.env.XDG_CONFIG_HOME = path.join(tempDir, '.config');

    // Setup mock execAsync
    mockExecAsync = jest.fn().mockResolvedValue({ stdout: 'rclone success', stderr: '' });
  });

  afterEach(async () => {
    // Restore environment
    process.env = originalEnv;
    
    // Clean up temp directory
    try {
      await fs.remove(tempDir);
    } catch (error) {
      // Ignore cleanup errors in tests
    }
  });

  it('should run sync workflow with mocked rclone execution', async () => {
    const { syncEmulator, __setExecAsyncForTests } = await import('../../src/cli/commands/advanced-sync.js');
    
    // Inject mock execAsync
    __setExecAsyncForTests(mockExecAsync);
    
    // Setup test directories
    const localSaveDir = path.join(tempDir, 'saves');
    const cloudDir = path.join(tempDir, 'cloud');
    await fs.ensureDir(localSaveDir);
    await fs.ensureDir(cloudDir);
    
    // Create test save file
    await fs.writeFile(path.join(localSaveDir, 'test-save.dat'), 'test data');
    
    // Setup test config via actual config manager
    const { getConfigManager } = await import('../../src/core/config.js');
    const configManager = await getConfigManager();
    await configManager.set('cloudProvider', 'test-remote');
    await configManager.set('syncRoot', cloudDir);

    // Test upload
    await syncEmulator('Test Emulator', localSaveDir, 'upload');
    
    expect(mockExecAsync).toHaveBeenCalledWith(
      expect.stringContaining('rclone sync')
    );
    expect(mockExecAsync).toHaveBeenCalledWith(
      expect.stringMatching(/test-remote.*test-emulator/)
    );
    
    // Test download  
    mockExecAsync.mockClear();
    await syncEmulator('Test Emulator', localSaveDir, 'download');
    
    expect(mockExecAsync).toHaveBeenCalledWith(
      expect.stringContaining('rclone sync')
    );
    expect(mockExecAsync).toHaveBeenCalledWith(
      expect.stringMatching(/test-remote.*test-emulator/)
    );
  });

  it('should handle rclone command failure gracefully', async () => {
    const { syncEmulator, __setExecAsyncForTests } = await import('../../src/cli/commands/advanced-sync.js');
    
    // Setup mock execAsync to fail
    mockExecAsync = jest.fn().mockRejectedValue(new Error('Command failed'));
    __setExecAsyncForTests(mockExecAsync);
    
    // Setup test directories
    const localSaveDir = path.join(tempDir, 'saves');
    await fs.ensureDir(localSaveDir);
    
    // Setup config
    const { getConfigManager } = await import('../../src/core/config.js');
    const configManager = await getConfigManager();
    await configManager.set('cloudProvider', 'test-remote');
    await configManager.set('syncRoot', path.join(tempDir, 'cloud'));
    
    // Expect the sync to handle errors gracefully (not throw)
    await expect(syncEmulator('Test Emulator', localSaveDir, 'upload')).resolves.not.toThrow();
    
    expect(mockExecAsync).toHaveBeenCalled();
  });
});
