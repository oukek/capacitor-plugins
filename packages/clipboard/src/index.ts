import { registerPlugin } from '@capacitor/core';

import type { OukekClipboard as OukekClipboardPlugin } from './definitions';

const OukekClipboard = registerPlugin<OukekClipboardPlugin>('OukekClipboard', {
  web: () => import('./web').then((m) => new m.OukekClipboardWeb()),
});

export * from './definitions';
export { OukekClipboard };
