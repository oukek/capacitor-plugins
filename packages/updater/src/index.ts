import { registerPlugin } from '@capacitor/core';

import type { OukekUpdater as OukekUpdaterPlugin } from './definitions';

const OukekUpdater = registerPlugin<OukekUpdaterPlugin>('OukekUpdater', {
  web: () => import('./web').then((m) => new m.OukekUpdaterWeb()),
});

export * from './definitions';
export { OukekUpdater };
