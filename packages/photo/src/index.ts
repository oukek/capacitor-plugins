import { registerPlugin } from '@capacitor/core';

import type { OukekPhoto as OukekPhotoPlugin } from './definitions';

const OukekPhoto = registerPlugin<OukekPhotoPlugin>('OukekPhoto', {
  web: () => import('./web').then((m) => new m.PhotoPluginWeb()),
});

export * from './definitions';
export { OukekPhoto };
