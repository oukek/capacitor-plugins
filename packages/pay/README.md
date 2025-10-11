# @oukek/capacitor-pay

Capacitor 应用内购买插件

## 安装

```bash
npm install @oukek/capacitor-pay
npx cap sync
```

## 功能特点

- 支持 iOS 应用内购买（基于 StoreKit）
- 支持获取商品信息
- 支持购买商品
- 支持恢复购买
- 支持购买状态实时监听
- 优先提供 StoreKit 2 的 Transaction JWS 用于服务端验证（更安全）
- 提供 Base64 收据作为兼容字段（可选）

## API

### getProducts

获取商品信息列表。

```typescript
interface Product {
  productId: string;        // 商品ID
  price: number;            // 价格（数字）
  localizedPrice: string;   // 本地化价格
  localizedTitle: string;   // 本地化标题
  localizedDescription: string; // 本地化描述
}

interface GetProductsResult {
  products: Product[];
  invalidProductIds: string[];
}

getProducts(options: { 
  productIds: string[] 
}): Promise<GetProductsResult>
```

### purchase

购买指定商品。

```typescript
purchase(options: { 
  productId: string 
}): Promise<void>
```

### restorePurchases

恢复之前的购买。

```typescript
restorePurchases(): Promise<void>
```

### 购买状态监听

通过 `addListener` 监听购买状态变化。

```typescript
interface PurchaseUpdatedState {
  state: 'purchasing' | 'cancelled' | 'failed' | 'succeeded' | 'restored' | 'deferred';
  productId?: string;
  transactionId?: string;
  originalTransactionId?: string;
  purchaseDate?: number;
  expirationDate?: number;
  isUpgraded?: boolean;
  transactionJWS?: string; // StoreKit 2 的 JWS，推荐服务端验证
  receipt?: string;        // Base64 收据，可选，兼容旧服务端
  error?: string;
  transactions?: Array<{   // 仅在恢复购买时返回
    productId: string;
    transactionId: string;
    // iOS 端也会包含 transactionJWS（如果可用）
  }>;
}

addListener(
  'purchaseUpdated',
  (state: PurchaseUpdatedState) => void
): Promise<PluginListenerHandle>
```

## 使用示例

```typescript
import { OukekPay } from '@oukek/capacitor-pay';

// 获取商品列表
const getProducts = async () => {
  try {
    const result = await OukekPay.getProducts({
      productIds: ['10', '11', '12']
    });
    console.log('Products:', result.products);
    console.log('Invalid IDs:', result.invalidProductIds);
  } catch (error) {
    console.error('Failed to get products:', error);
  }
};

// 购买商品
const purchase = async (productId: string) => {
  try {
    await OukekPay.purchase({ productId });
  } catch (error) {
    console.error('Purchase failed:', error);
  }
};

// 监听购买状态（前端不做验证，只提交到后端）
const setupPurchaseListener = async () => {
  await OukekPay.addListener('purchaseUpdated', async (state) => {
    switch (state.state) {
      case 'purchasing':
        console.log('正在购买...');
        break;
      case 'succeeded':
        console.log('购买成功:', state);
        // 将交易信息提交到后端进行验证（优先使用 transactionJWS）
        await submitPurchaseForValidation({
          transactionJWS: state.transactionJWS,
          receipt: state.receipt, // 可选兼容字段
          productId: state.productId!,
          transactionId: state.transactionId!,
          originalTransactionId: state.originalTransactionId,
          purchaseDate: state.purchaseDate,
          expirationDate: state.expirationDate
        });
        break;
      case 'failed':
        console.error('购买失败:', state.error);
        break;
      case 'cancelled':
        console.log('购买已取消');
        break;
      case 'restored':
        console.log('购买已恢复:', state.transactions);
        // 将恢复的交易提交到后端进行批量验证
        if (state.transactions && state.transactions.length > 0) {
          await submitRestoredTransactionsForValidation(state.transactions.map(t => ({
            productId: t.productId,
            transactionId: t.transactionId,
            // iOS 端会包含 transactionJWS（如果可用）
            // @ts-expect-error: 兼容字段在运行时存在
            transactionJWS: (t as any).transactionJWS,
          }))
          );
        }
        break;
      case 'deferred':
        console.log('购买已延期');
        break;
    }
  });
};

// 恢复购买
const restore = async () => {
  try {
    await OukekPay.restorePurchases();
  } catch (error) {
    console.error('Restore failed:', error);
  }
};

// 清理监听器
const cleanup = async () => {
  await OukekPay.removeAllListeners();
};

// 提交到后端（示例，替换为你的接口）
const submitPurchaseForValidation = async (params: {
  transactionJWS?: string;
  receipt?: string;
  productId: string;
  transactionId: string;
  originalTransactionId?: string;
  purchaseDate?: number;
  expirationDate?: number;
}) => {
  // TODO: 调用后端 /iap/verify 接口
  console.log('提交验证', params);
};

const submitRestoredTransactionsForValidation = async (transactions: Array<{
  productId: string;
  transactionId: string;
  transactionJWS?: string;
}>) => {
  // TODO: 调用后端 /iap/restore 接口
  console.log('提交恢复验证', transactions);
};
```

## 注意事项

1. 所有购买验证应在服务端进行，前端只负责提交必要数据（优先使用 transactionJWS）
2. iOS 端购买成功后会始终返回 `transactionJWS`，`receipt` 为可选兼容字段
3. 恢复购买时每条交易也会包含 `transactionJWS`（如果可用）
4. 请确保在组件卸载时清理监听器
5. 如果你的后端仍使用旧的收据验证接口，可继续读取 `receipt` 字段，但建议尽快迁移到 JWS 验证

## 后端示例（Node.js + Axios）

- 推荐在服务端使用 Apple App Store Server API 进行交易验证，并通过 JWT 作为 Bearer 授权；该 API 返回以 JWS 签名的交易/订阅信息，更适合安全落地到后端。<mcreference link="https://developer.apple.com/documentation/appstoreserverapi" index="2">2</mcreference> <mcreference link="https://adapty.io/blog/validating-iap-with-app-store-server-api/" index="1">1</mcreference>
- 生产与沙盒的基础 URL 分别为 `https://api.storekit.itunes.apple.com/` 和 `https://api.storekit-sandbox.itunes.apple.com/`；如遇 `4040010 TransactionIdNotFoundError`，请切换到沙盒环境重试。<mcreference link="https://developer.apple.com/documentation/appstoreserverapi" index="2">2</mcreference>


### 4) 重要说明

- App Store Server API 是基于 REST 的服务端验证接口，响应使用 JWS 签名；你可以直接信任 API 返回的数据并结合业务做持久化与授权。<mcreference link="https://developer.apple.com/documentation/appstoreserverapi" index="2">2</mcreference> <mcreference link="https://adapty.io/blog/validating-iap-with-app-store-server-api/" index="1">1</mcreference>
- 如果你需要对 `signedTransactionInfo`（JWS）做离线校验，建议使用 Apple 提供的 Node.js 开源库（含证书链校验支持）以减少实现复杂度。<mcreference link="https://github.com/apple/app-store-server-library-node" index="3">3</mcreference> 
- 校验证书链时可参考 Apple 的 Root/中间证书，并验证 JWS `x5c` 证书链是否可信。<mcreference link="https://developer.apple.com/forums/thread/691464" index="4">4</mcreference>

### 5) 最简调用示例（无服务端框架）

- 下方示例仅展示如何生成 JWT 并直接用 axios 调用“Get Transaction Info”接口，无需搭配 Express 或定义路由。<mcreference link="https://developer.apple.com/documentation/appstoreserverapi" index="2">2</mcreference> <mcreference link="https://adapty.io/blog/validating-iap-with-app-store-server-api/" index="1">1</mcreference>

```js
const axios = require('axios');
const jwt = require('jsonwebtoken');

// 必填配置（来自 App Store Connect）
const issuerId = '你的IssuerId';
const keyId = '你的KeyId';
const bundleId = '你的BundleId';
const privateKey = `-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----`;

function createJWT() {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: issuerId,
    iat: now,
    exp: now + 5 * 60,
    aud: 'appstoreconnect-v1',
  };
  return jwt.sign(payload, privateKey, {
    algorithm: 'ES256',
    header: { kid: keyId },
  });
}

const PROD_BASE = 'https://api.storekit.itunes.apple.com';
const SANDBOX_BASE = 'https://api.storekit-sandbox.itunes.apple.com';

async function getTransactionInfo(transactionId) {
  const token = createJWT();
  const headers = { Authorization: `Bearer ${token}` };
  const path = `/inApps/v1/transactions/${transactionId}`;
  try {
    const res = await axios.get(`${PROD_BASE}${path}`, { headers });
    return { environment: 'PROD', data: res.data };
  } catch (err) {
    const code = err?.response?.data?.errorCode || err?.response?.status;
    if (String(code) === '4040010' || code === 404) {
      const res = await axios.get(`${SANDBOX_BASE}${path}`, { headers });
      return { environment: 'SANDBOX', data: res.data };
    }
    throw err;
  }
}

// 示例：校验一次购买
(async () => {
  const txId = '2000000...'; // 从前端提交
  const result = await getTransactionInfo(txId);
  console.log('环境:', result.environment);
  console.log('交易:', result.data);
})();

// 示例：批量校验恢复交易
async function verifyRestored(transactions) {
  const results = await Promise.all(
    transactions.map(async (t) => {
      try {
        return await getTransactionInfo(t.transactionId);
      } catch (e) {
        return { ok: false, error: e?.response?.data || e.message, echo: t };
      }
    })
  );
  console.log('恢复结果:', results);
}
```

- 如需对接到你的后端接口（例如 /iap/verify、/iap/restore），只需将上述调用封装到你的路由或服务方法中即可，无需额外改动。<mcreference link="https://developer.apple.com/documentation/appstoreserverapi" index="2">2</mcreference>