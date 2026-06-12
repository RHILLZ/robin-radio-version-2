import { Directory, File, Paths } from 'expo-file-system';

/**
 * Thin wrapper around the expo-file-system (SDK 56+) File/Directory API.
 * Keeping all filesystem IO behind this module lets services stay pure
 * enough to unit test with an in-memory mock of this file.
 */

export function readTextFile(name: string): string | null {
  try {
    const file = new File(Paths.cache, name);
    if (!file.exists) return null;
    return file.textSync();
  } catch {
    return null;
  }
}

export function writeTextFile(name: string, contents: string): boolean {
  try {
    const file = new File(Paths.cache, name);
    file.write(contents);
    return true;
  } catch {
    return false;
  }
}

export function deleteFile(name: string): void {
  try {
    const file = new File(Paths.cache, name);
    if (file.exists) file.delete();
  } catch {
    // best-effort
  }
}

export function ensureDir(name: string): void {
  try {
    const dir = new Directory(Paths.cache, name);
    if (!dir.exists) dir.create();
  } catch {
    // best-effort
  }
}

export function deleteDir(name: string): void {
  try {
    const dir = new Directory(Paths.cache, name);
    if (dir.exists) dir.delete();
  } catch {
    // best-effort
  }
}

export function fileExists(dirName: string, fileName: string): boolean {
  try {
    return new File(Paths.cache, dirName, fileName).exists;
  } catch {
    return false;
  }
}

export function fileUri(dirName: string, fileName: string): string {
  return new File(Paths.cache, dirName, fileName).uri;
}

export function fileSize(dirName: string, fileName: string): number {
  try {
    const file = new File(Paths.cache, dirName, fileName);
    return file.exists ? (file.size ?? 0) : 0;
  } catch {
    return 0;
  }
}

export function deleteFileIn(dirName: string, fileName: string): void {
  try {
    const file = new File(Paths.cache, dirName, fileName);
    if (file.exists) file.delete();
  } catch {
    // best-effort
  }
}

/**
 * Downloads `url` into `dirName/fileName`. Returns the local file URI, or
 * null when the download failed. Any partial file is cleaned up.
 */
export async function downloadFile(
  url: string,
  dirName: string,
  fileName: string,
): Promise<string | null> {
  try {
    ensureDir(dirName);
    const destination = new File(Paths.cache, dirName, fileName);
    if (destination.exists) destination.delete();
    const output = await File.downloadFileAsync(url, destination);
    return output.exists ? output.uri : null;
  } catch {
    deleteFileIn(dirName, fileName);
    return null;
  }
}
