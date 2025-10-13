import { registerPlugin } from '@capacitor/core';

import type { OukekCalendar as OukekCalendarPlugin } from './definitions';

const OukekCalendar = registerPlugin<OukekCalendarPlugin>('OukekCalendar', {
  web: () => import('./web').then((m) => new m.OukekCalendarWeb()),
});

export * from './definitions';
export { OukekCalendar };
