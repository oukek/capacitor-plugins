import { WebPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';

import type { OukekPay, PurchaseState } from './definitions';

export class OukekPayWeb extends WebPlugin implements OukekPay {
  async getProducts(options: { productIds: string[] }): Promise<{
    products: {
      productId: string;
      price: string;
      localizedPrice: string;
      localizedTitle: string;
      localizedDescription: string;
    }[];
    invalidProductIds: string[];
  }> {
    console.warn('getProducts is not implemented on web');
    return {
      products: [],
      invalidProductIds: options.productIds,
    };
  }

  async purchase(options: { productId: string }): Promise<void> {
    console.warn(`purchase is not implemented on web: ${options.productId}`);
  }

  async restorePurchases(): Promise<void> {
    console.warn('restorePurchases is not implemented on web');
  }

  async addListener(
    eventName: 'purchaseUpdated',
    listenerFunc: (state: PurchaseState) => void,
  ): Promise<PluginListenerHandle> {
    return super.addListener(eventName, listenerFunc);
  }

  async removeAllListeners(): Promise<void> {
    return super.removeAllListeners();
  }
}
