# iOS 应用内购买完整流程

本文档详细说明了iOS应用内购买的完整流程，包括前端实现和后端接口要求。

## 1. 初始化流程

### 1.1 获取商品配置

首先从后端获取商品配置信息，包括商品ID和类型等。

```typescript
// 前端请求
const getProductConfig = async () => {
  const response = await fetch('https://api.yourserver.com/iap/products', {
    method: 'GET',
    headers: {
      'Authorization': 'Bearer YOUR_TOKEN'
    }
  });
  return response.json();
}

// 后端返回数据格式
interface ProductConfig {
  consumables: {
    productId: string;      // App Store 商品 ID
    type: 'consumable';     // 消耗型商品
    virtualItemId: string;  // 对应的虚拟物品ID
    amount: number;         // 虚拟物品数量
  }[];
  subscriptions: {
    productId: string;     // App Store 商品 ID
    type: 'subscription';  // 订阅型商品
    period: 'monthly' | 'quarterly' | 'yearly';  // 订阅周期
    features: string[];    // 订阅包含的特权
  }[];
}

// 返回数据示例
{
  "consumables": [
    {
      "productId": "com.game.diamonds.100",
      "type": "consumable",
      "virtualItemId": "diamonds",
      "amount": 100
    }
  ],
  "subscriptions": [
    {
      "productId": "com.app.subscription.monthly",
      "type": "subscription",
      "period": "monthly",
      "features": ["no_ads", "premium_features"]
    }
  ]
}
```

### 1.2 获取商品信息

使用配置中的商品ID从App Store获取商品详情。

```typescript
// 使用 Capacitor Pay 插件获取商品信息
const getProducts = async (productIds: string[]) => {
  const result = await OukekPay.getProducts({ productIds });
  return result;
}

// App Store 返回的商品信息
interface Product {
  productId: string;
  price: number;           // 价格（数字形式）
  localizedPrice: string;  // 本地化价格（带货币符号）
  localizedTitle: string;  // 本地化标题
  localizedDescription: string;  // 本地化描述
}
```

## 2. 购买流程

### 2.1 发起购买

```typescript
// 前端发起购买
const purchase = async (productId: string) => {
  await OukekPay.purchase({ productId });
}
```

### 2.2 监听购买状态

```typescript
// 设置购买状态监听
const setupPurchaseListener = async () => {
  await OukekPay.addListener('purchaseUpdated', handlePurchaseState);
}

// 处理购买状态
const handlePurchaseState = async (state: PurchaseUpdatedState) => {
  switch (state.state) {
    case 'purchasing':
      // 正在购买中
      break;
    case 'succeeded':
      if (state.receipt) {
        // 购买成功，验证收据
        await verifyPurchase({
          receipt: state.receipt,
          productId: state.productId!,
          transactionId: state.transactionId!,
          originalTransactionId: state.originalTransactionId,
          purchaseDate: state.purchaseDate,
          expirationDate: state.expirationDate
        });
      }
      break;
    case 'failed':
      // 购买失败
      console.error(state.error);
      break;
    case 'cancelled':
      // 用户取消购买
      break;
    case 'deferred':
      // 等待批准（比如家长控制）
      break;
    case 'restored':
      // 恢复购买成功
      if (state.transactions) {
        await handleRestoredTransactions(state.transactions);
      }
      break;
  }
}
```

### 2.3 验证购买

```typescript
// 前端发送验证请求
interface VerifyPurchaseParams {
  receipt: string;
  productId: string;
  transactionId: string;
  originalTransactionId?: string;
  purchaseDate?: number;
  expirationDate?: number;
}

const verifyPurchase = async (params: VerifyPurchaseParams) => {
  const response = await fetch('https://api.yourserver.com/iap/verify', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_TOKEN'
    },
    body: JSON.stringify({
      ...params,
      userId: 'current-user-id',
      platform: 'ios'
    })
  });
  return response.json();
}

// 后端验证接口请求格式
interface VerifyRequest {
  receipt: string;              // App Store 收据
  productId: string;            // 商品ID
  transactionId: string;        // 交易ID
  originalTransactionId?: string; // 原始交易ID（订阅续期用）
  purchaseDate?: number;        // 购买时间戳
  expirationDate?: number;      // 过期时间戳（订阅商品）
  userId: string;               // 用户ID
  platform: 'ios';              // 平台
}

// 后端验证接口返回格式
interface VerifyResponse {
  valid: boolean;       // 验证是否成功
  error?: string;       // 错误信息
  transaction?: {
    transactionId: string;    // App Store 交易ID
    originalTransactionId?: string;  // 原始交易ID
    purchaseDate: number;     // 购买时间戳
    expirationDate?: number;  // 订阅过期时间戳
  };
  // 消耗型商品返回的虚拟物品信息
  items?: {
    virtualItemId: string;    // 虚拟物品ID
    amount: number;           // 数量
  }[];
  // 订阅商品返回的订阅信息
  subscription?: {
    status: 'active' | 'expired' | 'grace_period';  // 订阅状态
    productId: string;        // 商品ID
    startDate: number;        // 开始时间戳
    expiryDate: number;       // 过期时间戳
    autoRenewing: boolean;    // 是否自动续订
    gracePeriodEndDate?: number;  // 宽限期结束时间戳
    features: string[];       // 包含的特权
    isUpgraded: boolean;      // 是否已升级
  };
}
```

## 3. 订阅管理

### 3.1 获取当前订阅状态

```typescript
// 前端请求
const getSubscriptionStatus = async () => {
  const response = await fetch('https://api.yourserver.com/iap/subscription/status', {
    method: 'GET',
    headers: {
      'Authorization': 'Bearer YOUR_TOKEN'
    }
  });
  return response.json();
}

// 后端返回格式
interface SubscriptionStatus {
  hasActiveSubscription: boolean;  // 是否有活跃订阅
  subscriptions: {
    productId: string;        // 商品ID
    status: 'active' | 'expired' | 'grace_period';  // 状态
    expiryDate: number;       // 过期时间戳
    autoRenewing: boolean;    // 是否自动续订
    gracePeriodEndDate?: number;  // 宽限期结束时间戳
    features: string[];       // 特权列表
    isUpgraded: boolean;      // 是否已升级
  }[];
}
```

### 3.2 恢复购买

```typescript
// 前端发起恢复
const restorePurchases = async () => {
  await OukekPay.restorePurchases();
}

// 处理恢复的交易
const handleRestoredTransactions = async (transactions: { productId: string; transactionId: string }[]) => {
  // 向后端验证每个恢复的交易
  for (const transaction of transactions) {
    await verifyRestore(transaction);
  }
}

// 验证恢复的购买
const verifyRestore = async (transaction: { productId: string; transactionId: string }) => {
  const response = await fetch('https://api.yourserver.com/iap/restore', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_TOKEN'
    },
    body: JSON.stringify({
      ...transaction,
      userId: 'current-user-id',
      platform: 'ios'
    })
  });
  return response.json();
}

// 后端恢复接口返回格式
interface RestoreResponse {
  success: boolean;
  error?: string;
  restoredItems: {
    type: 'subscription' | 'consumable';
    productId: string;
    transactionId: string;
    purchaseDate: number;
    // 订阅商品的额外信息
    subscription?: {
      status: 'active' | 'expired';
      expiryDate: number;
      features: string[];
      isUpgraded: boolean;
    };
    // 消耗型商品的额外信息
    consumable?: {
      virtualItemId: string;
      amount: number;
    };
  }[];
}
```