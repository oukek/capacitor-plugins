import type { PluginListenerHandle } from '@capacitor/core';

export interface OukekPay {
}

export interface OukekPayPlugin {
  /**
   * 获取商品列表
   * @param options 商品ID列表
   */
  getProducts(options: { productIds: string[] }): Promise<{
    products: Array<{
      productId: string;
      price: string;
      localizedPrice: string;
      localizedTitle: string;
      localizedDescription: string;
    }>;
    invalidProductIds: string[];
  }>;

  /**
   * 购买商品
   * @param options 商品ID
   */
  purchase(options: { productId: string }): Promise<void>;

  /**
   * 恢复购买
   */
  restorePurchases(): Promise<void>;

  /**
   * 添加购买状态监听器
   * @param eventName 事件名称
   * @param listenerFunc 监听函数
   */
  addListener(
    eventName: 'purchaseUpdated',
    listenerFunc: (state: PurchaseState) => void
  ): Promise<PluginListenerHandle>;

  /**
   * 移除购买状态监听器
   * @param eventName 事件名称
   * @param listenerFunc 监听函数
   */
  removeAllListeners(): Promise<void>;
}

export interface PurchaseState {
  state: 'purchasing' | 'cancelled' | 'failed' | 'succeeded' | 'restored' | 'restoreFailed' | 'deferred';
  productId?: string;
  transactionId?: string;
  receipt?: string;
  error?: string;
  transactions?: Array<{
    productId: string;
    transactionId: string;
  }>;
}
