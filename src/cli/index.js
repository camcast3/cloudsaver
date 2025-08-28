import { Command } from 'commander';
import { logger } from '../core/logger.js';
import { helloCommand } from './commands/hello.js';
import { detectCommand } from './commands/detect.js';

// Initialize the CLI
const program = new Command()
  .name('cloudsaver')
  .description('Universal Emulation Save Sync')
  .version('0.1.0');

// Global options
program
  .option('-v, --verbose', 'Enable verbose output')
  .option('--debug', 'Enable debug output (more detailed than verbose)')
  .option('--dry-run', 'Show what would happen without making changes')
  .hook('preAction', (thisCommand) => {
    // Configure logger based on verbosity
    if (thisCommand.opts().debug) {
      logger.configure({ level: 'debug' });
      logger.debug('Debug mode enabled');
    } else if (thisCommand.opts().verbose) {
      logger.configure({ level: 'verbose' });
      logger.verbose('Verbose mode enabled');
    }
    
    // Log command execution
    const command = thisCommand.args[0] || 'default';
    const options = thisCommand.opts();
    logger.info(`Executing command: ${command}`, { options });
  });

// Register commands
program.addCommand(helloCommand);
program.addCommand(detectCommand);

// Error handling for the entire program
program.exitOverride();
try {
  // Parse and execute
  program.parse();
} catch (error) {
  const err = error;
  if (err.code === 'commander.helpDisplayed' || err.code === 'commander.version') {
    process.exit(0);
  }
  
  logger.error('Command execution failed', error);
  console.error('Error:', error.message || String(error));
  process.exit(1);
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason) => {
  logger.fatal('Unhandled promise rejection', reason);
  console.error('Fatal error:', reason);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.fatal('Uncaught exception', error);
  console.error('Fatal error:', error.message);
  process.exit(1);
});