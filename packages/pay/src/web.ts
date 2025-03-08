import { WebPlugin } from '@capacitor/core';

import type { OukekPayPlugin, PurchaseState } from './definitions';

export class OukekPayWeb extends WebPlugin implements OukekPayPlugin {
  async getProducts(options: { productIds: string[] }): Promise<{
    products: Array<{
      productId: string;
      price: string;
      localizedPrice: string;
      localizedTitle: string;
      localizedDescription: string;
    }>;
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
  ) {
    return super.addListener(eventName, listenerFunc);
  }

  async removeAllListeners(): Promise<void> {
    return super.removeAllListeners();
  }
}
