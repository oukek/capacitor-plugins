import { registerPlugin } from '@capacitor/core';

import type { OukekPay } from './definitions';

const OukekPayPlugin = registerPlugin<OukekPay>('OukekPay', {
  web: () => import('./web').then((m) => new m.OukekPayWeb()),
});

export * from './definitions';
export { OukekPayPlugin };
