# 订阅购买示例

这个示例展示了如何在Vue3项目中实现会员订阅功能。

## 完整代码

```vue
<template>
  <div class="subscription-container">
    <h2>会员订阅</h2>
    
    <!-- 当前订阅状态 -->
    <div v-if="currentSubscription" class="current-subscription">
      <div class="subscription-status">
        <h3>当前订阅</h3>
        <p>{{ currentSubscription.name }}</p>
        <p class="expiry">到期时间: {{ formatDate(currentSubscription.expiryDate) }}</p>
      </div>
    </div>
    
    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>加载订阅信息中...</p>
    </div>
    
    <!-- 错误提示 -->
    <div v-if="error" class="error-message">
      {{ error }}
      <button @click="initProducts" class="retry-button">重试</button>
    </div>
    
    <!-- 订阅选项 -->
    <div v-if="!loading && !error" class="subscription-plans">
      <div 
        v-for="plan in subscriptionPlans" 
        :key="plan.productId"
        :class="['plan-card', { 'most-popular': plan.popular }]"
      >
        <div v-if="plan.popular" class="popular-badge">最受欢迎</div>
        <h3>{{ plan.localizedTitle }}</h3>
        <p class="description">{{ plan.localizedDescription }}</p>
        <div class="price-section">
          <div class="price">{{ plan.localizedPrice }}</div>
          <div class="period">{{ getPeriodText(plan.productId) }}</div>
          <div class="monthly-price">{{ calculateMonthlyPrice(plan) }}</div>
        </div>
        <ul class="features">
          <li v-for="(feature, index) in getFeatures(plan.productId)" 
              :key="index">
            {{ feature }}
          </li>
        </ul>
        <button 
          @click="subscribe(plan.productId)"
          :disabled="subscribing === plan.productId"
          class="subscribe-button"
        >
          {{ subscribing === plan.productId ? '订阅中...' : '立即订阅' }}
        </button>
      </div>
    </div>
    
    <!-- 订阅说明 -->
    <div class="subscription-info">
      <p>• 订阅会自动续费，可随时在 App Store 中取消</p>
      <p>• 付款将在确认购买时从 iTunes 账户中扣除</p>
      <p>• 订阅到期前 24 小时内将自动续费</p>
      <p>• 可以在购买后通过 App Store 管理订阅</p>
    </div>
    
    <!-- 状态提示 -->
    <div v-if="statusMessage" :class="['status-message', statusType]">
      {{ statusMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { OukekPayPlugin } from '@oukek/capacitor-pay'

// 状态变量
const loading = ref(false)
const error = ref('')
const subscribing = ref('')
const statusMessage = ref('')
const statusType = ref('')
const subscriptionPlans = ref<any[]>([])
const currentSubscription = ref<any>(null)

// 订阅产品ID
const SUBSCRIPTION_PRODUCTS = [
  'com.app.subscription.monthly',    // 月度会员 9.9
  'com.app.subscription.quarterly',  // 季度会员 27.9
  'com.app.subscription.yearly'      // 年度会员 108
]

// 订阅周期文本
const PERIOD_TEXT = {
  'com.app.subscription.monthly': '每月',
  'com.app.subscription.quarterly': '每3个月',
  'com.app.subscription.yearly': '每年'
}

// 订阅特权
const SUBSCRIPTION_FEATURES = {
  'com.app.subscription.monthly': [
    '✓ 去除所有广告',
    '✓ 解锁高级功能',
    '✓ 优先客服支持'
  ],
  'com.app.subscription.quarterly': [
    '✓ 去除所有广告',
    '✓ 解锁高级功能',
    '✓ 优先客服支持',
    '✓ 专属季卡徽章'
  ],
  'com.app.subscription.yearly': [
    '✓ 去除所有广告',
    '✓ 解锁高级功能',
    '✓ 优先客服支持',
    '✓ 专属年卡徽章',
    '✓ 独享年度礼包'
  ]
}

// 获取订阅周期文本
const getPeriodText = (productId: string) => {
  return PERIOD_TEXT[productId] || ''
}

// 获取订阅特权列表
const getFeatures = (productId: string) => {
  return SUBSCRIPTION_FEATURES[productId] || []
}

// 计算每月价格
const calculateMonthlyPrice = (plan: any) => {
  const price = parseFloat(plan.price)
  const productId = plan.productId
  let monthlyPrice = price
  
  if (productId === 'com.app.subscription.quarterly') {
    monthlyPrice = price / 3
  } else if (productId === 'com.app.subscription.yearly') {
    monthlyPrice = price / 12
  }
  
  return `约合每月 ¥${monthlyPrice.toFixed(2)}`
}

// 格式化日期
const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

// 初始化订阅产品
const initProducts = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const result = await OukekPayPlugin.getProducts({
      productIds: SUBSCRIPTION_PRODUCTS
    })
    
    // 添加额外信息到产品中
    subscriptionPlans.value = result.products.map(product => ({
      ...product,
      popular: product.productId === 'com.app.subscription.yearly'
    }))
    
    if (result.invalidProductIds.length > 0) {
      console.warn('无效的订阅产品:', result.invalidProductIds)
    }
    
    // 恢复已有订阅
    await restoreSubscription()
  } catch (err) {
    error.value = '获取订阅信息失败，请稍后重试'
    console.error('获取订阅产品失败:', err)
  } finally {
    loading.value = false
  }
}

// 订阅
const subscribe = async (productId: string) => {
  subscribing.value = productId
  statusMessage.value = ''
  statusType.value = ''
  
  try {
    await OukekPayPlugin.purchase({ productId })
  } catch (err) {
    showStatus('订阅失败，请重试', 'error')
    console.error('订阅失败:', err)
  } finally {
    subscribing.value = ''
  }
}

// 恢复订阅
const restoreSubscription = async () => {
  try {
    await OukekPayPlugin.restorePurchases()
  } catch (err) {
    console.error('恢复订阅失败:', err)
  }
}

// 显示状态消息
const showStatus = (message: string, type: 'success' | 'error' | 'info') => {
  statusMessage.value = message
  statusType.value = type
  
  setTimeout(() => {
    statusMessage.value = ''
    statusType.value = ''
  }, 3000)
}

// 处理购买状态
const handlePurchaseState = async (state: any) => {
  switch (state.state) {
    case 'purchasing':
      showStatus('正在处理订阅...', 'info')
      break
      
    case 'succeeded':
      showStatus('订阅成功！', 'success')
      if (state.receipt) {
        await verifySubscription(state.receipt)
      }
      break
      
    case 'failed':
      showStatus(`订阅失败: ${state.error}`, 'error')
      break
      
    case 'cancelled':
      showStatus('订阅已取消', 'info')
      break
      
    case 'restored':
      showStatus('订阅已恢复', 'success')
      if (state.receipt) {
        await verifySubscription(state.receipt)
      }
      break
      
    case 'restoreFailed':
      showStatus('恢复订阅失败', 'error')
      break
  }
}

// 验证订阅
const verifySubscription = async (receipt: string) => {
  try {
    const response = await fetch('https://api.yourserver.com/verify-subscription', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        receipt,
        userId: 'current-user-id',
        platform: 'ios'
      }),
    })
    
    const result = await response.json()
    
    if (result.valid) {
      // 更新订阅状态
      updateSubscriptionStatus(result.subscription)
    } else {
      console.error('订阅验证失败:', result.error)
      showStatus('订阅验证失败，请联系客服', 'error')
    }
  } catch (err) {
    console.error('验证订阅失败:', err)
    showStatus('订阅验证失败，请联系客服', 'error')
  }
}

// 更新订阅状态
const updateSubscriptionStatus = (subscription: any) => {
  currentSubscription.value = subscription
}

// 设置购买监听器
const setupPurchaseListener = async () => {
  await OukekPayPlugin.addListener('purchaseUpdated', handlePurchaseState)
}

// 组件挂载时初始化
onMounted(async () => {
  await initProducts()
  await setupPurchaseListener()
})

// 组件卸载时清理
onUnmounted(async () => {
  await OukekPayPlugin.removeAllListeners()
})
</script>

<style scoped>
.subscription-container {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.current-subscription {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 30px;
  text-align: center;
}

.subscription-status {
  color: #2c3e50;
}

.expiry {
  color: #666;
  font-size: 0.9em;
}

.loading {
  text-align: center;
  padding: 40px;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-message {
  text-align: center;
  color: #ff4444;
  padding: 20px;
}

.subscription-plans {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin: 30px 0;
}

.plan-card {
  position: relative;
  border: 1px solid #eee;
  border-radius: 12px;
  padding: 30px;
  text-align: center;
  background: white;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  transition: transform 0.3s, box-shadow 0.3s;
}

.plan-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
}

.most-popular {
  border: 2px solid #3498db;
}

.popular-badge {
  position: absolute;
  top: -12px;
  left: 50%;
  transform: translateX(-50%);
  background: #3498db;
  color: white;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 0.8em;
}

.price-section {
  margin: 20px 0;
}

.price {
  font-size: 2em;
  font-weight: bold;
  color: #2c3e50;
}

.period {
  color: #666;
  margin: 5px 0;
}

.monthly-price {
  font-size: 0.9em;
  color: #666;
}

.features {
  list-style: none;
  padding: 0;
  margin: 20px 0;
  text-align: left;
}

.features li {
  margin: 10px 0;
  color: #2c3e50;
}

.subscribe-button {
  width: 100%;
  background: #3498db;
  color: white;
  border: none;
  padding: 12px 0;
  border-radius: 6px;
  font-size: 1.1em;
  cursor: pointer;
  transition: background 0.3s;
}

.subscribe-button:hover:not(:disabled) {
  background: #2980b9;
}

.subscribe-button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.subscription-info {
  margin-top: 40px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.subscription-info p {
  color: #666;
  font-size: 0.9em;
  margin: 5px 0;
}

.status-message {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  padding: 15px 30px;
  border-radius: 6px;
  color: white;
  animation: fadeIn 0.3s ease;
  z-index: 1000;
}

.status-message.success {
  background: #2ecc71;
}

.status-message.error {
  background: #e74c3c;
}

.status-message.info {
  background: #3498db;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translate(-50%, 20px); }
  to { opacity: 1; transform: translate(-50%, 0); }
}

.retry-button {
  margin-left: 10px;
  padding: 5px 15px;
  border: none;
  background: #3498db;
  color: white;
  border-radius: 4px;
  cursor: pointer;
}

.retry-button:hover {
  background: #2980b9;
}
</style>
```

## 功能说明

1. **订阅计划展示**
   - 展示三种订阅计划（月度、季度、年度）
   - 显示每个计划的详细信息和特权
   - 突出显示推荐方案
   - 显示折算后的月均价格

2. **订阅管理**
   - 显示当前订阅状态
   - 支持订阅购买
   - 支持恢复购买
   - 自动续订管理

3. **状态处理**
   - 处理订阅过程中的各种状态
   - 显示友好的状态提示
   - 错误处理和重试机制

4. **UI/UX 特性**
   - 响应式布局
   - 加载动画
   - 状态反馈
   - 悬浮效果
   - 突出显示最受欢迎的方案

## 使用说明

1. 替换 `SUBSCRIPTION_PRODUCTS` 中的产品ID
2. 修改价格和周期信息
3. 实现 `verifySubscription` 中的服务器验证逻辑
4. 根据需要调整订阅特权列表

## 注意事项

1. 确保在App Store Connect中正确配置了自动续期订阅产品
2. 实现完整的收据验证服务器
3. 正确处理订阅状态变化
4. 提供清晰的订阅条款和取消说明
5. 注意处理订阅过期和续订场景
6. 保存和同步用户的订阅状态 