import { WebPlugin } from '@capacitor/core';

import type { OukekClipboard as OukekClipboardPlugin } from './definitions';

export class OukekClipboardWeb extends WebPlugin implements OukekClipboardPlugin {
  constructor() {
    super();
  }
}
