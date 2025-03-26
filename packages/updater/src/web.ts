import { WebPlugin } from '@capacitor/core';

import type { 
  OukekUpdater as OukekUpdaterPlugin,
} from './definitions';

export class OukekUpdaterWeb extends WebPlugin implements OukekUpdaterPlugin {

  constructor() {
    super();
  }

  getCurrentVersion(): Promise<{ version: string; build: string }> {
    return Promise.resolve({ version: '1.0.0', build: '1' });
  }

  getStoreVersion(): Promise<{ version: string; releaseNotes: string }> {
    return Promise.resolve({ version: '1.0.0', releaseNotes: '' });
  }

  openAppStore(): Promise<void> {
    return Promise.resolve();
  }
}