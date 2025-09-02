import { Command } from 'commander';
import { logger } from '../../core/logger.js';

export const helloCommand = new Command('hello')
  .description('Test command to verify setup is working')
  .option('--name <name>', 'Name to greet')
  .action((options) => {
    const name = options.name || 'World';
    logger.info(`Hello command executed`, { name });
    console.log(`Hello, ${name}! CloudSaver is working.`);
  });