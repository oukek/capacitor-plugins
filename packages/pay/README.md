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
- 自动处理收据验证

## API

### getProducts

获取商品信息列表。

```typescript
interface Product {
  productId: string;        // 商品ID
  price: string;           // 价格
  localizedPrice: string;  // 本地化价格
  localizedTitle: string;  // 本地化标题
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
interface PurchaseState {
  state: 'purchasing' | 'cancelled' | 'failed' | 'succeeded' | 'restored' | 'restoreFailed' | 'deferred';
  productId?: string;
  transactionId?: string;
  receipt?: string;        // base64 编码的收据数据
  error?: string;
  transactions?: Array<{   // 仅在恢复购买时返回
    productId: string;
    transactionId: string;
  }>;
}

addListener(
  'purchaseUpdated',
  (state: PurchaseState) => void
): Promise<PluginListenerHandle>
```

## 使用示例

```typescript
import { OukekPayPlugin } from '@oukek/capacitor-pay';

// 获取商品列表
const getProducts = async () => {
  try {
    const result = await OukekPayPlugin.getProducts({
      productIds: ['com.example.product1', 'com.example.product2']
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
    await OukekPayPlugin.purchase({ productId });
  } catch (error) {
    console.error('Purchase failed:', error);
  }
};

// 监听购买状态
const setupPurchaseListener = async () => {
  await OukekPayPlugin.addListener('purchaseUpdated', (state) => {
    switch (state.state) {
      case 'purchasing':
        console.log('正在购买...');
        break;
      case 'succeeded':
        console.log('购买成功:', state);
        // 在这里处理收据验证
        if (state.receipt) {
          verifyReceipt(state.receipt);
        }
        break;
      case 'failed':
        console.error('购买失败:', state.error);
        break;
      case 'cancelled':
        console.log('购买已取消');
        break;
      case 'restored':
        console.log('购买已恢复:', state.transactions);
        break;
      case 'restoreFailed':
        console.error('恢复购买失败:', state.error);
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
    await OukekPayPlugin.restorePurchases();
  } catch (error) {
    console.error('Restore failed:', error);
  }
};

// 清理监听器
const cleanup = async () => {
  await OukekPayPlugin.removeAllListeners();
};

// 收据验证示例
const verifyReceipt = async (receipt: string) => {
  try {
    const response = await fetch('your-server/verify-receipt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ receipt }),
    });
    const result = await response.json();
    if (result.valid) {
      // 处理验证成功的逻辑
    }
  } catch (error) {
    console.error('Receipt verification failed:', error);
  }
};
```

## 注意事项

1. iOS 端使用了 [DYFStore](https://github.com/dgynfi/DYFStore) 库进行 StoreKit 的封装
2. 收据验证建议在服务端进行，以确保安全性
3. 购买成功后会自动获取并返回 base64 编码的收据数据
4. 恢复购买会返回所有已恢复的交易信息
5. 请确保在组件卸载时清理监听器