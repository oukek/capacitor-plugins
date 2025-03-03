import { registerPlugin } from '@capacitor/core';

import type { OukekPhoto } from './definitions';

const OukekPhotoPlugin = registerPlugin<OukekPhoto>('OukekPhoto', {
  web: () => import('./web').then((m) => new m.PhotoPluginWeb()),
});

export * from './definitions';
export { OukekPhotoPlugin };
