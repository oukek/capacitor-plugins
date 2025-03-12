# 单独购买道具示例

这个示例展示了如何在Vue3项目中实现单独道具的购买流程。

## 完整代码

```vue
<template>
  <div class="purchase-container">
    <h2>游戏道具商店</h2>
    
    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      加载商品信息中...
    </div>
    
    <!-- 错误提示 -->
    <div v-if="error" class="error">
      {{ error }}
      <button @click="initProducts">重试</button>
    </div>
    
    <!-- 商品列表 -->
    <div v-if="!loading && !error" class="products-grid">
      <div v-for="product in products" :key="product.productId" class="product-card">
        <div class="product-image">
          <img :src="getProductImage(product.productId)" :alt="product.localizedTitle">
        </div>
        <h3>{{ product.localizedTitle }}</h3>
        <p class="description">{{ product.localizedDescription }}</p>
        <div class="price">{{ product.localizedPrice }}</div>
        <button 
          @click="purchase(product.productId)"
          :disabled="purchasing === product.productId"
          class="purchase-button"
        >
          {{ purchasing === product.productId ? '购买中...' : '购买' }}
        </button>
      </div>
    </div>

    <!-- 购买结果提示 -->
    <div v-if="purchaseMessage" :class="['purchase-message', purchaseStatus]">
      {{ purchaseMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { OukekPay } from '@oukek/capacitor-pay'
import type { Product, PurchaseUpdatedState } from '@oukek/capacitor-pay'

// 商品列表
const products = ref<Product[]>([])
const loading = ref(false)
const error = ref('')
const purchasing = ref('')
const purchaseMessage = ref('')
const purchaseStatus = ref('')

// 商品ID列表
const PRODUCT_IDS = [
  'com.game.diamonds.100',  // 100钻石
  'com.game.coins.1000',    // 1000金币
  'com.game.energy.50'      // 50能量
]

// 商品图片映射
const PRODUCT_IMAGES: Record<string, string> = {
  'com.game.diamonds.100': '/assets/diamonds.png',
  'com.game.coins.1000': '/assets/coins.png',
  'com.game.energy.50': '/assets/energy.png'
}

// 获取商品图片
const getProductImage = (productId: string) => {
  return PRODUCT_IMAGES[productId] || '/assets/default.png'
}

// 初始化商品列表
const initProducts = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const result = await OukekPay.getProducts({
      productIds: PRODUCT_IDS
    })
    
    products.value = result.products
    
    if (result.invalidProductIds.length > 0) {
      console.warn('无效的商品ID:', result.invalidProductIds)
    }
  } catch (err) {
    error.value = '获取商品信息失败，请稍后重试'
    console.error('获取商品失败:', err)
  } finally {
    loading.value = false
  }
}

// 购买商品
const purchase = async (productId: string) => {
  purchasing.value = productId
  purchaseMessage.value = ''
  purchaseStatus.value = ''
  
  try {
    await OukekPay.purchase({ productId })
  } catch (err) {
    showPurchaseMessage('购买失败，请重试', 'error')
    console.error('购买失败:', err)
  } finally {
    purchasing.value = ''
  }
}

// 显示购买消息
const showPurchaseMessage = (message: string, status: 'success' | 'error' | 'info') => {
  purchaseMessage.value = message
  purchaseStatus.value = status
  
  // 3秒后清除消息
  setTimeout(() => {
    purchaseMessage.value = ''
    purchaseStatus.value = ''
  }, 3000)
}

// 处理购买状态
const handlePurchaseState = async (state: PurchaseUpdatedState) => {
  switch (state.state) {
    case 'purchasing':
      showPurchaseMessage('正在处理购买...', 'info')
      break
      
    case 'succeeded':
      showPurchaseMessage('购买成功！', 'success')
      // 发送收据到服务器进行验证
      if (state.receipt) {
        await verifyReceipt({
          receipt: state.receipt,
          productId: state.productId!,
          transactionId: state.transactionId!,
          purchaseDate: state.purchaseDate
        })
      }
      break
      
    case 'failed':
      showPurchaseMessage(`购买失败: ${state.error}`, 'error')
      break
      
    case 'cancelled':
      showPurchaseMessage('购买已取消', 'info')
      break
      
    case 'deferred':
      showPurchaseMessage('购买需要批准，请等待...', 'info')
      break
  }
}

// 验证收据
interface VerifyReceiptParams {
  receipt: string
  productId: string
  transactionId: string
  purchaseDate?: number
}

const verifyReceipt = async (params: VerifyReceiptParams) => {
  try {
    const response = await fetch('https://api.yourserver.com/verify-receipt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ 
        ...params,
        userId: 'current-user-id',
        platform: 'ios'
      }),
    })
    
    const result = await response.json()
    
    if (result.valid) {
      // 根据服务端返回的结果更新用户物品
      updateUserItems(result.items)
    } else {
      console.error('收据验证失败:', result.error)
      showPurchaseMessage('购买验证失败，请联系客服', 'error')
    }
  } catch (err) {
    console.error('验证收据失败:', err)
    showPurchaseMessage('购买验证失败，请联系客服', 'error')
  }
}

// 更新用户物品（示例）
interface VirtualItem {
  virtualItemId: string
  amount: number
}

const updateUserItems = (items: VirtualItem[]) => {
  // 这里实现更新用户物品的逻辑
  console.log('更新用户物品:', items)
}

// 设置购买监听器
const setupPurchaseListener = async () => {
  await OukekPay.addListener('purchaseUpdated', handlePurchaseState)
}

// 组件挂载时初始化
onMounted(async () => {
  await initProducts()
  await setupPurchaseListener()
})

// 组件卸载时清理
onUnmounted(async () => {
  await OukekPay.removeAllListeners()
})
</script>

<style scoped>
.purchase-container {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.loading, .error {
  text-align: center;
  padding: 20px;
  margin: 20px 0;
}

.error {
  color: #ff4444;
}

.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.product-card {
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.product-image {
  width: 100px;
  height: 100px;
  margin: 0 auto 15px;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.description {
  color: #666;
  margin: 10px 0;
}

.price {
  font-size: 1.2em;
  font-weight: bold;
  color: #42b983;
  margin: 10px 0;
}

.purchase-button {
  background: #42b983;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.purchase-button:hover {
  background: #3aa876;
}

.purchase-button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.purchase-message {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  padding: 10px 20px;
  border-radius: 4px;
  color: white;
  animation: fadeIn 0.3s ease-in-out;
}

.success {
  background: #42b983;
}

.error {
  background: #ff4444;
}

.info {
  background: #2196f3;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translate(-50%, 20px);
  }
  to {
    opacity: 1;
    transform: translate(-50%, 0);
  }
}
</style>
```

## 功能说明

1. **商品展示**
   - 展示3种不同的游戏道具商品
   - 每个商品包含图片、标题、描述和价格
   - 商品信息从App Store获取

2. **购买流程**
   - 点击购买按钮开始购买流程
   - 显示购买状态（购买中、成功、失败等）
   - 购买成功后自动验证收据
   - 收据验证成功后更新用户物品

3. **错误处理**
   - 处理商品加载失败
   - 处理购买失败
   - 处理收据验证失败
   - 提供重试机制

4. **UI/UX**
   - 响应式网格布局
   - 加载状态提示
   - 错误提示
   - 购买状态反馈
   - 优雅的动画效果

## 使用说明

1. 替换 `PRODUCT_IDS` 为你的实际商品ID
2. 替换 `PRODUCT_IMAGES` 中的图片路径
3. 实现 `verifyReceipt` 中的服务器验证逻辑
4. 实现 `updateUserItems` 中的物品更新逻辑

## 注意事项

1. 确保在App Store Connect中正确配置了商品
2. 收据验证应该在服务器端进行
3. 注意处理网络错误和重试逻辑
4. 保存交易记录用于后续查询
5. 注意清理监听器避免内存泄漏 