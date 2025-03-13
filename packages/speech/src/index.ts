import { registerPlugin } from '@capacitor/core';

import type { OukekSpeech as OukekSpeechPlugin } from './definitions';

const OukekSpeech = registerPlugin<OukekSpeechPlugin>('OukekSpeech', {
  web: () => import('./web').then((m) => new m.OukekSpeechWeb()),
});

export * from './definitions';
export { OukekSpeech };
