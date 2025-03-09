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
  const result = await OukekPayPlugin.getProducts({ productIds });
  return result;
}

// App Store 返回的商品信息
interface Product {
  productId: string;
  price: string;
  localizedPrice: string;
  localizedTitle: string;
  localizedDescription: string;
}
```

## 2. 购买流程

### 2.1 发起购买

```typescript
// 前端发起购买
const purchase = async (productId: string) => {
  await OukekPayPlugin.purchase({ productId });
}
```

### 2.2 监听购买状态

```typescript
// 设置购买状态监听
const setupPurchaseListener = async () => {
  await OukekPayPlugin.addListener('purchaseUpdated', handlePurchaseState);
}

// 处理购买状态
const handlePurchaseState = async (state: PurchaseState) => {
  switch (state.state) {
    case 'succeeded':
      if (state.receipt) {
        await verifyPurchase(state.receipt, state.productId);
      }
      break;
    // ... 其他状态处理
  }
}
```

### 2.3 验证购买

```typescript
// 前端发送验证请求
const verifyPurchase = async (receipt: string, productId: string) => {
  const response = await fetch('https://api.yourserver.com/iap/verify', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_TOKEN'
    },
    body: JSON.stringify({
      receipt,
      productId,
      userId: 'current-user-id',
      platform: 'ios'
    })
  });
  return response.json();
}

// 后端验证接口请求格式
interface VerifyRequest {
  receipt: string;      // App Store 收据
  productId: string;    // 商品ID
  userId: string;       // 用户ID
  platform: 'ios';      // 平台
}

// 后端验证接口返回格式
interface VerifyResponse {
  valid: boolean;       // 验证是否成功
  error?: string;       // 错误信息
  transaction?: {
    transactionId: string;    // App Store 交易ID
    purchaseDate: string;     // 购买时间
    expiryDate?: string;      // 订阅过期时间（仅订阅商品）
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
    startDate: string;        // 开始时间
    expiryDate: string;       // 过期时间
    autoRenewing: boolean;    // 是否自动续订
    gracePeriodEndDate?: string;  // 宽限期结束时间
    features: string[];       // 包含的特权
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
    expiryDate: string;       // 过期时间
    autoRenewing: boolean;    // 是否自动续订
    gracePeriodEndDate?: string;  // 宽限期结束时间
    features: string[];       // 特权列表
  }[];
}
```

### 3.2 恢复购买

```typescript
// 前端发起恢复
const restorePurchases = async () => {
  await OukekPayPlugin.restorePurchases();
}

// 处理恢复状态
const handleRestoreState = async (state: PurchaseState) => {
  if (state.state === 'restored' && state.receipt) {
    await verifyRestore(state.receipt);
  }
}

// 验证恢复的购买
const verifyRestore = async (receipt: string) => {
  const response = await fetch('https://api.yourserver.com/iap/restore', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_TOKEN'
    },
    body: JSON.stringify({
      receipt,
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
    purchaseDate: string;
    // 订阅商品的额外信息
    subscription?: {
      status: 'active' | 'expired';
      expiryDate: string;
      features: string[];
    };
    // 消耗型商品的额外信息
    consumable?: {
      virtualItemId: string;
      amount: number;
    };
  }[];
}
```

## 4. 后端验证流程

后端需要实现以下关键功能：

1. **收据验证**
   - 将收据发送到 App Store 验证
   - 解析验证响应
   - 检查收据真实性
   - 检查商品ID匹配
   - 检查交易ID是否重复使用

2. **订阅管理**
   - 跟踪订阅状态
   - 处理续订通知
   - 处理退款情况
   - 管理宽限期
   - 处理订阅升级/降级

3. **数据存储**
   - 存储交易记录
   - 存储订阅状态
   - 存储用户权益
   - 记录收据信息

4. **通知处理**
   - 实现 App Store Server Notifications
   - 处理各种订阅事件
   - 更新用户状态

## 5. 注意事项

1. **安全性**
   - 所有验证必须在服务器端进行
   - 不要信任客户端数据
   - 使用 HTTPS 进行通信
   - 实现防重放机制

2. **订阅处理**
   - 正确处理各种订阅状态
   - 实现宽限期逻辑
   - 处理退款情况
   - 处理订阅升级/降级

3. **错误处理**
   - 实现重试机制
   - 记录详细日志
   - 提供用户友好的错误提示
   - 处理网络问题

4. **测试**
   - 使用沙盒环境测试
   - 测试各种购买场景
   - 测试异常情况
   - 测试恢复购买流程

## 6. 推荐实践

1. **缓存机制**
   - 缓存商品信息
   - 缓存订阅状态
   - 定期更新缓存

2. **用户体验**
   - 显示加载状态
   - 提供清晰的错误提示
   - 实现平滑的状态转换
   - 提供购买历史记录

3. **监控和日志**
   - 记录关键事件
   - 监控异常情况
   - 跟踪转化率
   - 分析用户行为

4. **合规性**
   - 遵守 App Store 政策
   - 提供明确的价格信息
   - 说明自动续订条款
   - 提供取消订阅说明 