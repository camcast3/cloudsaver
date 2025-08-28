import fs from 'fs-extra';
import path from 'path';
import os from 'os';

// Test configuration setup
export const TEST_CONFIG = {
  // Test paths
  TEMP_DIR: path.join(os.tmpdir(), 'cloudsaver-tests'),
  SAVES_DIR: path.join(os.tmpdir(), 'cloudsaver-tests', 'saves'),
  CLOUD_DIR: path.join(os.tmpdir(), 'cloudsaver-tests', 'cloud'),
  CONFIG_DIR: path.join(os.tmpdir(), 'cloudsaver-tests', 'config'),
  
  // Test data
  EMULATORS: {
    retroarch: {
      id: 'retroarch',
      name: 'RetroArch',
      savePaths: [path.join(os.tmpdir(), 'cloudsaver-tests', 'saves', 'retroarch')],
      saveExtensions: ['.srm', '.sav', '.bsv'],
    },
    dolphin: {
      id: 'dolphin',
      name: 'Dolphin',
      savePaths: [path.join(os.tmpdir(), 'cloudsaver-tests', 'saves', 'dolphin')],
      saveExtensions: ['.gci', '.sav', '.dat'],
    }
  },
  
  // Mock cloud provider
  CLOUD_PROVIDER: 'test-remote',
};

/**
 * Set up test environment
 */
export async function setupTestEnvironment(): Promise<void> {
  // Create test directories
  await fs.ensureDir(TEST_CONFIG.TEMP_DIR);
  await fs.ensureDir(TEST_CONFIG.SAVES_DIR);
  await fs.ensureDir(TEST_CONFIG.CLOUD_DIR);
  await fs.ensureDir(TEST_CONFIG.CONFIG_DIR);
  
  // Create emulator save directories
  await fs.ensureDir(TEST_CONFIG.EMULATORS.retroarch.savePaths[0]);
  await fs.ensureDir(TEST_CONFIG.EMULATORS.dolphin.savePaths[0]);
  
  // Create some test save files
  await fs.writeFile(
    path.join(TEST_CONFIG.EMULATORS.retroarch.savePaths[0], 'game1.srm'),
    'test retroarch save data'
  );
  
  await fs.writeFile(
    path.join(TEST_CONFIG.EMULATORS.dolphin.savePaths[0], 'game1.gci'),
    'test dolphin save data'
  );
}

/**
 * Clean up test environment
 */
export async function cleanupTestEnvironment(): Promise<void> {
  await fs.remove(TEST_CONFIG.TEMP_DIR);
}

/**
 * Generate test configuration
 */
export async function generateTestConfig(): Promise<void> {
  const configFile = path.join(TEST_CONFIG.CONFIG_DIR, 'config.json');
  
  const config = {
    cloudProvider: TEST_CONFIG.CLOUD_PROVIDER,
    syncRoot: TEST_CONFIG.CLOUD_DIR,
    lastSync: new Date().toISOString(),
  };
  
  await fs.writeJson(configFile, config, { spaces: 2 });
}
