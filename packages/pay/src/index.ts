import { registerPlugin } from '@capacitor/core';

import type { OukekPay as OukekPayPlugin } from './definitions';

const OukekPay = registerPlugin<OukekPayPlugin>('OukekPay', {
  web: () => import('./web').then(m => new m.OukekPayWeb()),
});

export * from './definitions';
export { OukekPay };
