import winston from 'winston';
import path from 'path';
import fs from 'fs-extra';
import os from 'os';

// Log levels in order of increasing priority
const levels = {
  debug: 0,   // Detailed debugging information
  verbose: 1, // More detailed than info
  info: 2,    // Normal operation information
  warn: 3,    // Warning conditions
  error: 4,   // Error conditions
  fatal: 5    // Critical errors causing application exit
};

// Custom format for log messages
const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ level, message, timestamp, ...metadata }) => {
    let msg = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    // Add metadata if it exists and is not empty
    if (metadata && Object.keys(metadata).length > 0) {
      msg += ` | ${JSON.stringify(metadata)}`;
    }
    
    return msg;
  })
);

export class Logger {
  private static instance: Logger;
  private logger: winston.Logger;
  private logDir: string;
  
  private constructor(logLevel: string = 'info') {
    // Create logs directory if it doesn't exist
    this.logDir = path.join(os.homedir(), '.config', 'cloudsaver', 'logs');
    fs.ensureDirSync(this.logDir);
    
    // Create Winston logger
    this.logger = winston.createLogger({
      levels,
      level: logLevel,
      format: customFormat,
      defaultMeta: { service: 'cloudsaver' },
      transports: [
        // Log to console
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            customFormat
          )
        }),
        // Log to file with rotation
        new winston.transports.File({
          filename: path.join(this.logDir, 'error.log'),
          level: 'error',
          maxsize: 10485760, // 10MB
          maxFiles: 5,
        }),
        new winston.transports.File({
          filename: path.join(this.logDir, 'cloudsaver.log'),
          maxsize: 10485760, // 10MB
          maxFiles: 5,
        })
      ]
    });
  }
  
  // Singleton pattern
  public static getInstance(logLevel?: string): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger(logLevel);
    }
    return Logger.instance;
  }
  
  // Configure the logger
  public configure(options: { level?: string }): void {
    if (options.level) {
      this.logger.level = options.level;
    }
  }
  
  // Logging methods
  public debug(message: string, metadata?: any): void {
    this.logger.debug(message, metadata);
  }
  
  public verbose(message: string, metadata?: any): void {
    this.logger.verbose(message, metadata);
  }
  
  public info(message: string, metadata?: any): void {
    this.logger.info(message, metadata);
  }
  
  public warn(message: string, metadata?: any): void {
    this.logger.warn(message, metadata);
  }
  
  public error(message: string, error?: Error, metadata?: any): void {
    const errorData = error ? {
      name: error.name,
      message: error.message,
      stack: error.stack,
      ...metadata
    } : metadata;
    
    this.logger.error(message, errorData);
  }
  
  public fatal(message: string, error?: Error, metadata?: any): void {
    const errorData = error ? {
      name: error.name,
      message: error.message,
      stack: error.stack,
      ...metadata
    } : metadata;
    
    this.logger.log('fatal', message, errorData);
  }
  
  // Get log directory
  public getLogDir(): string {
    return this.logDir;
  }
}

// Export a default logger instance
export const logger = Logger.getInstance();