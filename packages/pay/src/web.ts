import { WebPlugin, type PluginListenerHandle } from '@capacitor/core';

import type { OukekPay as OukekPayPlugin, GetProductsResult, PurchaseUpdatedState } from './definitions';

export class OukekPayWeb extends WebPlugin implements OukekPayPlugin {
  async getProducts(): Promise<GetProductsResult> {
    throw this.unimplemented('Not implemented on web.');
  }

  async purchase(): Promise<void> {
    throw this.unimplemented('Not implemented on web.');
  }

  async restorePurchases(): Promise<void> {
    throw this.unimplemented('Not implemented on web.');
  }

  override async addListener(
    eventName: 'purchaseUpdated',
    listenerFunc: (state: PurchaseUpdatedState) => void,
  ): Promise<PluginListenerHandle> {
    return super.addListener(eventName, listenerFunc);
  }

  override async removeAllListeners(): Promise<void> {
    await super.removeAllListeners();
  }
}
