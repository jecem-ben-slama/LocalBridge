export interface FileNode {
  name: string;
  path: string;
  isDirectory: boolean;
  size?: number;
  lastModified?: number;
}
