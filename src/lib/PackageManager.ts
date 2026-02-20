// src/lib/PackageManager.ts
// @ts-ignore
import { mergeTars } from '../../friscy-bundle/overlay.js';

export interface PackageInfo {
  id: string;
  name: string;
  description: string;
  size: string;
  url: string;
}

interface PackageManifest {
  version: number;
  packages: PackageInfo[];
}

const PACKAGES_DIR = 'aeon-packages';

async function getPackagesDir(): Promise<FileSystemDirectoryHandle> {
  const root = await navigator.storage.getDirectory();
  return root.getDirectoryHandle(PACKAGES_DIR, { create: true });
}

export class PackageManager {
  private manifest: PackageManifest | null = null;
  private installedIds: Set<string> = new Set();

  async loadManifest(url = '/packages/manifest.json'): Promise<PackageInfo[]> {
    const resp = await fetch(url);
    if (!resp.ok) throw new Error(`Failed to fetch manifest: ${resp.status}`);
    this.manifest = await resp.json();
    await this.scanInstalled();
    return this.manifest!.packages;
  }

  private async scanInstalled(): Promise<void> {
    this.installedIds.clear();
    try {
      const dir = await getPackagesDir();
      for await (const [name] of dir as any) {
        if (name.endsWith('.tar')) {
          this.installedIds.add(name.replace('.tar', ''));
        }
      }
    } catch {
      // No packages dir yet
    }
  }

  isInstalled(id: string): boolean {
    return this.installedIds.has(id);
  }

  async install(pkg: PackageInfo): Promise<void> {
    const resp = await fetch(pkg.url);
    if (!resp.ok) throw new Error(`Failed to download ${pkg.id}: ${resp.status}`);

    let tarData: ArrayBuffer;
    // Decompress if gzipped
    if (pkg.url.endsWith('.gz') && typeof DecompressionStream !== 'undefined') {
      const decompressed = new Response(
        resp.body!.pipeThrough(new DecompressionStream('gzip'))
      );
      tarData = await decompressed.arrayBuffer();
    } else {
      tarData = await resp.arrayBuffer();
    }

    // Store in OPFS
    const dir = await getPackagesDir();
    const fileHandle = await dir.getFileHandle(`${pkg.id}.tar`, { create: true });
    const writable = await fileHandle.createWritable();
    await writable.write(tarData);
    await writable.close();

    this.installedIds.add(pkg.id);
    console.log(`[packages] Installed ${pkg.id} (${(tarData.byteLength / 1024).toFixed(1)}KB)`);
  }

  async uninstall(id: string): Promise<void> {
    const dir = await getPackagesDir();
    try {
      await dir.removeEntry(`${id}.tar`);
    } catch {
      // Already gone
    }
    this.installedIds.delete(id);
  }

  /**
   * Apply all installed package layers on top of the base rootfs tar.
   * Returns the merged tar with all package files layered in.
   */
  async applyLayers(baseTar: ArrayBuffer): Promise<ArrayBuffer> {
    let result = baseTar;
    const dir = await getPackagesDir();

    for (const id of this.installedIds) {
      try {
        const fileHandle = await dir.getFileHandle(`${id}.tar`);
        const file = await fileHandle.getFile();
        const pkgTar = await file.arrayBuffer();
        const merged: Uint8Array = mergeTars(result, pkgTar);
        result = merged.buffer as ArrayBuffer;
        console.log(`[packages] Layered ${id}`);
      } catch (e) {
        console.warn(`[packages] Failed to layer ${id}:`, e);
      }
    }

    return result;
  }

  getInstalledIds(): string[] {
    return Array.from(this.installedIds);
  }
}
