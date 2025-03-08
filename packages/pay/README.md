# @oukek/capacitor-pay

Capacitor plugin for in-app purchases

## Install

```bash
npm install @oukek/capacitor-pay
npx cap sync
```

## API

<docgen-index>



</docgen-index>

## Example

### Vue 3 组件示例

```vue
<template>
  <div>
    <div v-for="product in products" :key="product.productId">
      <h3>{{ product.localizedTitle }}</h3>
      <p>{{ product.localizedDescription }}</p>
      <button @click="purchase(product.productId)">
        购买 ({{ product.localizedPrice }})
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { OukekPay } from '@oukek/capacitor-pay'

const products = ref([])
let purchaseListener: any = null

// 初始化商品列表
const initProducts = async () => {
  try {
    const result = await OukekPay.getProducts({
      productIds: ['your_product_id_1', 'your_product_id_2']
    })
    products.value = result.products
  } catch (error) {
    console.error('Failed to get products:', error)
  }
}

// 购买商品
const purchase = async (productId: string) => {
  try {
    await OukekPay.purchase({ productId })
  } catch (error) {
    console.error('Purchase failed:', error)
  }
}

// 监听购买状态
const setupPurchaseListener = async () => {
  purchaseListener = await OukekPay.addListener('purchaseUpdated', (state) => {
    switch (state.state) {
      case 'succeeded':
        console.log('Purchase succeeded:', state)
        // 在这里处理购买成功的逻辑
        // 比如发送收据到服务器进行验证
        if (state.receipt) {
          verifyReceipt(state.receipt)
        }
        break
      case 'failed':
        console.error('Purchase failed:', state.error)
        break
      case 'cancelled':
        console.log('Purchase cancelled')
        break
    }
  })
}

// 恢复购买
const restorePurchases = async () => {
  try {
    await OukekPay.restorePurchases()
  } catch (error) {
    console.error('Restore failed:', error)
  }
}

// 验证收据（示例）
const verifyReceipt = async (receipt: string) => {
  try {
    // 发送收据到你的服务器进行验证
    const response = await fetch('your-server/verify-receipt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ receipt }),
    })
    const result = await response.json()
    if (result.valid) {
      // 处理验证成功的逻辑
    }
  } catch (error) {
    console.error('Receipt verification failed:', error)
  }
}

onMounted(async () => {
  await initProducts()
  await setupPurchaseListener()
})

onUnmounted(async () => {
  await OukekPay.removeAllListeners()
})
</script>
```

## API 详细说明

### getProducts

```typescript
getProducts(options: { productIds: string[] }) => Promise<{
  products: Array<{
    productId: string;
    price: string;
    localizedPrice: string;
    localizedTitle: string;
    localizedDescription: string;
  }>;
  invalidProductIds: string[];
}>
```

### purchase

```typescript
purchase(options: { productId: string }) => Promise<void>
```

### restorePurchases

```typescript
restorePurchases() => Promise<void>
```

### addListener

```typescript
addListener(
  eventName: 'purchaseUpdated',
  listenerFunc: (state: PurchaseState) => void
) => Promise<PluginListenerHandle>
```

### PurchaseState

```typescript
interface PurchaseState {
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
```