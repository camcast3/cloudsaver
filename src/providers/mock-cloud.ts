import fs from 'fs-extra';
import path from 'path';
import { logger } from '../core/logger.js';

/**
 * Mock cloud provider for testing
 * This simulates cloud operations without actually connecting to any service
 */
export class MockCloudProvider {
  private localDir: string;
  private cloudDir: string;
  
  constructor(localDir: string, cloudDir: string) {
    this.localDir = localDir;
    this.cloudDir = cloudDir;
  }
  
  /**
   * Simulate uploading a file to the cloud
   */
  async uploadFile(sourcePath: string, remotePath: string): Promise<boolean> {
    try {
      const cloudPath = path.join(this.cloudDir, remotePath);
      await fs.ensureDir(path.dirname(cloudPath));
      await fs.copy(sourcePath, cloudPath);
      return true;
    } catch (error) {
      logger.error('Error uploading file', error as Error);
      return false;
    }
  }
  
  /**
   * Simulate downloading a file from the cloud
   */
  async downloadFile(remotePath: string, localPath: string): Promise<boolean> {
    try {
      const cloudPath = path.join(this.cloudDir, remotePath);
      if (await fs.pathExists(cloudPath)) {
        await fs.ensureDir(path.dirname(localPath));
        await fs.copy(cloudPath, localPath);
        return true;
      }
      return false;
    } catch (error) {
      logger.error('Error downloading file', error as Error);
      return false;
    }
  }
  
  /**
   * Simulate listing files in the cloud
   */
  async listFiles(remotePath: string = ''): Promise<string[]> {
    try {
      const cloudPath = path.join(this.cloudDir, remotePath);
      if (await fs.pathExists(cloudPath)) {
        const files = await fs.readdir(cloudPath);
        return files;
      }
      return [];
    } catch (error) {
      logger.error('Error listing files', error as Error);
      return [];
    }
  }
  
  /**
   * Simulate checking if a file exists in the cloud
   */
  async fileExists(remotePath: string): Promise<boolean> {
    try {
      const cloudPath = path.join(this.cloudDir, remotePath);
      return await fs.pathExists(cloudPath);
    } catch (error) {
      logger.error('Error checking if file exists', error as Error);
      return false;
    }
  }
  
  /**
   * Simulate deleting a file from the cloud
   */
  async deleteFile(remotePath: string): Promise<boolean> {
    try {
      const cloudPath = path.join(this.cloudDir, remotePath);
      if (await fs.pathExists(cloudPath)) {
        await fs.remove(cloudPath);
        return true;
      }
      return false;
    } catch (error) {
      logger.error('Error deleting file', error as Error);
      return false;
    }
  }
  
  /**
   * Simulate getting file metadata
   */
  async getFileMetadata(remotePath: string): Promise<{ size: number; modifiedTime: Date } | null> {
    try {
      const cloudPath = path.join(this.cloudDir, remotePath);
      if (await fs.pathExists(cloudPath)) {
        const stats = await fs.stat(cloudPath);
        return {
          size: stats.size,
          modifiedTime: stats.mtime
        };
      }
      return null;
    } catch (error) {
      logger.error('Error getting file metadata', error as Error);
      return null;
    }
  }
}
