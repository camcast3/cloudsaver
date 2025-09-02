#!/usr/bin/env node

// CommonJS wrapper for pkg compatibility with ESM modules
const path = require('path');
const { fileURLToPath } = require('url');

// Import and run the ESM module
(async () => {
  try {
    // Import the ESM CLI module
    const cliPath = path.resolve(__dirname, 'dist', 'cli', 'index.js');
    await import(cliPath);
  } catch (error) {
    console.error('Error loading CLI module:', error);
    process.exit(1);
  }
})();
