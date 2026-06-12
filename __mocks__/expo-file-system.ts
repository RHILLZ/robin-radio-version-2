/**
 * In-memory Jest mock of the expo-file-system (SDK 56) File/Directory API —
 * just enough surface for src/lib/fs.ts.
 */

const files = new Map<string, string>();
const dirs = new Set<string>();

type Segment = string | { path: string };

function join(segments: Segment[]): string {
  return segments
    .map((s) => (typeof s === 'string' ? s : s.path))
    .join('/')
    .replace(/\/+/g, '/');
}

export class File {
  path: string;

  constructor(...segments: Segment[]) {
    this.path = join(segments);
  }

  get exists(): boolean {
    return files.has(this.path);
  }

  get size(): number {
    return files.get(this.path)?.length ?? 0;
  }

  get uri(): string {
    return `file:///${this.path}`;
  }

  create(): void {
    if (files.has(this.path)) throw new Error(`File already exists: ${this.path}`);
    files.set(this.path, '');
  }

  write(contents: string): void {
    files.set(this.path, String(contents));
  }

  textSync(): string {
    const value = files.get(this.path);
    if (value === undefined) throw new Error(`ENOENT: ${this.path}`);
    return value;
  }

  delete(): void {
    if (!files.has(this.path)) throw new Error(`ENOENT: ${this.path}`);
    files.delete(this.path);
  }

  static downloadFileAsync = jest.fn(async (url: string, destination: File) => {
    files.set(destination.path, `downloaded:${url}`);
    return destination;
  });
}

export class Directory {
  path: string;

  constructor(...segments: Segment[]) {
    this.path = join(segments);
  }

  get exists(): boolean {
    return dirs.has(this.path);
  }

  create(): void {
    dirs.add(this.path);
  }

  delete(): void {
    dirs.delete(this.path);
    const prefix = `${this.path}/`;
    for (const key of [...files.keys()]) {
      if (key.startsWith(prefix)) files.delete(key);
    }
  }
}

export const Paths = {
  cache: new Directory('cache'),
  document: new Directory('document'),
};

/** Test helpers (not part of the real API). */
export function __reset(): void {
  files.clear();
  dirs.clear();
  File.downloadFileAsync.mockClear();
}

export function __setFile(path: string, contents: string): void {
  files.set(path, contents);
}

export function __getFile(path: string): string | undefined {
  return files.get(path);
}
