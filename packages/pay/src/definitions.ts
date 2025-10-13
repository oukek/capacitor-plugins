import type { PluginListenerHandle } from '@capacitor/core';

export interface OukekPay {
  /**
   * 获取商品信息
   * @param options 包含商品 ID 列表的选项
   */
  getProducts(options: { productIds: string[] }): Promise<GetProductsResult>;

  /**
   * 购买商品
   * @param options 包含商品 ID 和可选用户 ID 的选项
   */
  purchase(options: { productId: string; appAccountToken?: string }): Promise<void>;

  /**
   * 恢复购买
   */
  restorePurchases(): Promise<void>;

  /**
   * 添加事件监听器
   * @param eventName 事件名称
   * @param listenerFunc 监听器函数
   */
  addListener(
    eventName: 'purchaseUpdated',
    listenerFunc: (state: PurchaseUpdatedState) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * 移除所有事件监听器
   */
  removeAllListeners(): Promise<void>;
}

export interface Product {
  /** 商品 ID */
  productId: string;
  /** 价格（数字形式） */
  price: number;
  /** 本地化价格（带货币符号） */
  localizedPrice: string;
  /** 本地化标题 */
  localizedTitle: string;
  /** 本地化描述 */
  localizedDescription: string;
}

export interface GetProductsResult {
  /** 商品列表 */
  products: Product[];
  /** 无效的商品 ID 列表 */
  invalidProductIds: string[];
}

export interface PurchaseUpdatedState {
  /** 购买状态 */
  state: 'purchasing' | 'succeeded' | 'failed' | 'restored' | 'cancelled' | 'deferred';
  /** 商品 ID */
  productId?: string;
  /** 交易 ID */
  transactionId?: string;
  /** 原始交易 ID */
  originalTransactionId?: string;
  /** 购买日期（时间戳） */
  purchaseDate?: number;
  /** 过期日期（时间戳） */
  expirationDate?: number;
  /** 是否已升级 */
  isUpgraded?: boolean;
  /** 交易 JWS（推荐用于后端验证） */
  transactionJWS?: string;
  /** 用户账户令牌（绑定的用户ID） */
  appAccountToken?: string;
  /** 收据数据（兼容字段） */
  receipt?: string;
  /** 错误信息 */
  error?: string;
  /** 恢复的交易列表 */
  transactions?: {
    productId: string;
    transactionId: string;
  }[];
}
