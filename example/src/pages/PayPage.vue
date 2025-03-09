<template>
  <q-page class="q-pa-md">
    <div class="row q-col-gutter-md">
      <!-- 道具商店 -->
      <div class="col-12 col-md-6">
        <q-card class="store-section">
          <q-card-section>
            <div class="text-h6">道具商店</div>
            <div class="text-subtitle2">购买游戏道具</div>
          </q-card-section>

          <!-- 道具列表 -->
          <q-card-section class="q-gutter-md">
            <q-card v-for="product in itemProducts" :key="product.productId" class="product-card">
              <q-card-section class="row items-center">
                <q-avatar size="72px" class="q-mr-md bg-grey-3">
                  <div v-html="getProductIcon(product.productId)" class="product-icon"></div>
                </q-avatar>
                <div class="col">
                  <div class="text-h6">{{ product.localizedTitle }}</div>
                  <div class="text-subtitle2">{{ product.localizedDescription }}</div>
                  <div class="text-subtitle1 q-mt-sm">价格: {{ product.localizedPrice }}</div>
                </div>
              </q-card-section>

              <q-card-actions align="right">
                <q-btn
                  flat
                  :loading="purchasing === product.productId"
                  :label="purchasing === product.productId ? '购买中...' : '购买'"
                  color="primary"
                  @click="purchase(product.productId)"
                >
                  <template v-slot:loading>
                    <q-spinner-dots />
                  </template>
                </q-btn>
              </q-card-actions>
            </q-card>
          </q-card-section>
        </q-card>
      </div>

      <!-- 会员订阅 -->
      <div class="col-12 col-md-6">
        <q-card class="store-section">
          <q-card-section>
            <div class="text-h6">会员订阅</div>
            <div class="text-subtitle2">解锁更多特权</div>
          </q-card-section>

          <!-- 当前订阅状态 -->
          <q-card-section v-if="currentSubscription" class="subscription-status">
            <div class="text-subtitle1">当前订阅: {{ currentSubscription.name }}</div>
            <div class="text-caption">到期时间: {{ formatDate(currentSubscription.expiryDate) }}</div>
          </q-card-section>

          <!-- 订阅列表 -->
          <q-card-section class="q-gutter-md">
            <q-card v-for="product in subscriptionProducts" :key="product.productId"
                   :class="['subscription-card', { 'popular': product.popular }]">
              <q-badge v-if="product.popular" color="primary" class="popular-badge">
                最受欢迎
              </q-badge>

              <q-card-section>
                <div class="text-h6">{{ product.localizedTitle }}</div>
                <div class="text-subtitle2">{{ product.localizedDescription }}</div>
                <div class="price-section">
                  <div class="text-h5">{{ product.localizedPrice }}</div>
                  <div class="text-caption">{{ getPeriodText(product.productId) }}</div>
                  <div class="text-caption">{{ calculateMonthlyPrice(product) }}</div>
                </div>

                <q-list dense class="q-mt-md">
                  <q-item v-for="(feature, index) in getFeatures(product.productId)"
                         :key="index" class="feature-item">
                    <q-item-section avatar>
                      <q-icon name="check" color="positive" />
                    </q-item-section>
                    <q-item-section>
                      <q-item-label>{{ feature }}</q-item-label>
                    </q-item-section>
                  </q-item>
                </q-list>
              </q-card-section>

              <q-card-actions align="center">
                <q-btn
                  :loading="purchasing === product.productId"
                  :label="purchasing === product.productId ? '订阅中...' : '立即订阅'"
                  color="primary"
                  class="full-width"
                  @click="purchase(product.productId)"
                >
                  <template v-slot:loading>
                    <q-spinner-dots />
                  </template>
                </q-btn>
              </q-card-actions>
            </q-card>
          </q-card-section>

          <!-- 订阅说明 -->
          <q-card-section class="subscription-info">
            <q-list dense>
              <q-item>
                <q-item-section avatar>
                  <q-icon name="info" color="info" />
                </q-item-section>
                <q-item-section>
                  <q-item-label>订阅会自动续费，可随时在 App Store 中取消</q-item-label>
                </q-item-section>
              </q-item>
              <q-item>
                <q-item-section avatar>
                  <q-icon name="info" color="info" />
                </q-item-section>
                <q-item-section>
                  <q-item-label>付款将在确认购买时从 iTunes 账户中扣除</q-item-label>
                </q-item-section>
              </q-item>
              <q-item>
                <q-item-section avatar>
                  <q-icon name="info" color="info" />
                </q-item-section>
                <q-item-section>
                  <q-item-label>订阅到期前 24 小时内将自动续费</q-item-label>
                </q-item-section>
              </q-item>
            </q-list>
          </q-card-section>

          <!-- 恢复购买按钮 -->
          <q-card-actions align="center">
            <q-btn
              flat
              :loading="restoring"
              label="恢复购买"
              color="primary"
              @click="restorePurchases"
            >
              <template v-slot:loading>
                <q-spinner-dots />
              </template>
            </q-btn>
          </q-card-actions>
        </q-card>
      </div>
    </div>

    <!-- 交易记录 -->
    <q-dialog v-model="showTransactions">
      <q-card style="min-width: 350px">
        <q-card-section>
          <div class="text-h6">交易记录</div>
        </q-card-section>

        <q-card-section class="q-pa-none">
          <q-list separator>
            <q-item v-for="tx in transactions" :key="tx.transactionId">
              <q-item-section>
                <q-item-label>{{ getProductTitle(tx.productId) }}</q-item-label>
                <q-item-label caption>交易ID: {{ tx.transactionId }}</q-item-label>
              </q-item-section>
            </q-item>
          </q-list>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="关闭" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- 全局消息提示 -->
    <q-dialog v-model="alert.show">
      <q-card>
        <q-card-section>
          <div class="text-h6">{{ alert.title }}</div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          {{ alert.message }}
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="确定" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useQuasar } from 'quasar'
import { OukekPayPlugin, type PurchaseState } from '@oukek/capacitor-pay'

// 类型定义
interface BaseConfig {
  productId: string
  type: string
  features: string[]
  icon: string
}

interface ItemConfig extends BaseConfig {
  type: 'consumable'
  virtualItemId: string
  amount: number
}

interface SubscriptionConfig extends BaseConfig {
  type: 'subscription'
  period: 'monthly' | 'quarterly' | 'yearly'
  popular: boolean
}

interface Product {
  productId: string
  price: string
  localizedPrice: string
  localizedTitle: string
  localizedDescription: string
}

interface ProductWithMeta extends Product {
  popular?: boolean
  type?: string
  virtualItemId?: string
  period?: 'monthly' | 'quarterly' | 'yearly'
  features?: string[]
  icon?: string
}

interface Transaction {
  productId: string
  transactionId: string
}

interface SubscriptionStatus {
  name: string
  expiryDate: string
  features: string[]
  status: 'active' | 'expired' | 'grace_period'
}

interface VerifyReceiptResponse {
  valid: boolean
  error?: string
  subscription?: SubscriptionStatus
  items?: Array<{
    virtualItemId: string
    amount: number
  }>
}

// SVG 图标配置
const ICONS = {
  coins: `<svg viewBox="0 0 24 24" width="24" height="24">
    <path fill="currentColor" d="M12,2A10,10 0 0,1 22,12A10,10 0 0,1 12,22A10,10 0 0,1 2,12A10,10 0 0,1 12,2M12,4A8,8 0 0,0 4,12A8,8 0 0,0 12,20A8,8 0 0,0 20,12A8,8 0 0,0 12,4M11,17V16H9V14H13V13H10A1,1 0 0,1 9,12V9A1,1 0 0,1 10,8H11V7H13V8H15V10H11V11H14A1,1 0 0,1 15,12V15A1,1 0 0,1 14,16H13V17H11Z" />
  </svg>`,
  diamonds: `<svg viewBox="0 0 24 24" width="24" height="24">
    <path fill="currentColor" d="M12,2L22,12L12,22L2,12L12,2M12,4.83L4.83,12L12,19.17L19.17,12L12,4.83Z" />
  </svg>`,
  vip: `<svg viewBox="0 0 24 24" width="24" height="24">
    <path fill="currentColor" d="M2,2H22V22H2V2M20,20V4H4V20H20M18,6H16V8H18V6M14,6H6V8H14V6M18,10H16V12H18V10M14,10H6V12H14V10M18,14H16V16H18V14M14,14H6V16H14V14M18,18H16V20H18V18M14,18H6V20H14V18Z" />
  </svg>`
}

const PRODUCTS_CONFIG = {
  items: [
    {
      productId: 'com.game.currency.small',
      type: 'consumable',
      virtualItemId: 'coins',
      amount: 1000,
      icon: ICONS.coins,
      features: ['获得1000金币']
    },
    {
      productId: 'com.game.currency.medium',
      type: 'consumable',
      virtualItemId: 'coins',
      amount: 3000,
      icon: ICONS.coins,
      features: ['获得3000金币', '额外赠送300金币']
    },
    {
      productId: 'com.game.currency.large',
      type: 'consumable',
      virtualItemId: 'coins',
      amount: 10000,
      icon: ICONS.coins,
      features: ['获得10000金币', '额外赠送1500金币']
    },
    {
      productId: 'com.game.diamond.small',
      type: 'consumable',
      virtualItemId: 'diamonds',
      amount: 60,
      icon: ICONS.diamonds,
      features: ['获得60钻石']
    },
    {
      productId: 'com.game.diamond.medium',
      type: 'consumable',
      virtualItemId: 'diamonds',
      amount: 300,
      icon: ICONS.diamonds,
      features: ['获得300钻石', '额外赠送30钻石']
    },
    {
      productId: 'com.game.diamond.large',
      type: 'consumable',
      virtualItemId: 'diamonds',
      amount: 980,
      icon: ICONS.diamonds,
      features: ['获得980钻石', '额外赠送150钻石']
    }
  ] as ItemConfig[],
  subscriptions: [
    {
      productId: 'com.app.vip.monthly',
      type: 'subscription',
      period: 'monthly',
      popular: false,
      icon: ICONS.vip,
      features: [
        '去除所有广告',
        '解锁高级功能',
        '专属月卡徽章',
        '每日登录奖励翻倍'
      ]
    },
    {
      productId: 'com.app.vip.quarterly',
      type: 'subscription',
      period: 'quarterly',
      popular: true,
      icon: ICONS.vip,
      features: [
        '去除所有广告',
        '解锁高级功能',
        '专属季卡徽章',
        '每日登录奖励翻倍',
        '专属季卡礼包',
        '解锁专属头像框'
      ]
    },
    {
      productId: 'com.app.vip.yearly',
      type: 'subscription',
      period: 'yearly',
      popular: false,
      icon: ICONS.vip,
      features: [
        '去除所有广告',
        '解锁高级功能',
        '专属年卡徽章',
        '每日登录奖励翻倍',
        '专属年卡礼包',
        '解锁专属头像框',
        '专属客服通道',
        '优先体验新功能'
      ]
    }
  ] as SubscriptionConfig[]
}

// 状态变量
const $q = useQuasar()
const loading = ref(false)
const error = ref('')
const purchasing = ref('')
const restoring = ref(false)
const showTransactions = ref(false)
const alert = ref({
  show: false,
  title: '',
  message: ''
})

// 商品列表
const products = ref<ProductWithMeta[]>([])
const transactions = ref<Transaction[]>([])
const currentSubscription = ref<SubscriptionStatus | null>(null)

// 计算属性：分类商品
const itemProducts = computed(() => {
  return products.value.filter(p =>
    PRODUCTS_CONFIG.items.some(item => item.productId === p.productId)
  ).map(p => {
    const config = PRODUCTS_CONFIG.items.find(item => item.productId === p.productId)
    if (config) {
      return {
        ...p,
        type: config.type,
        virtualItemId: config.virtualItemId,
        features: config.features,
        icon: config.icon
      }
    }
    return p
  })
})

const subscriptionProducts = computed(() => {
  return products.value.filter(p =>
    PRODUCTS_CONFIG.subscriptions.some(sub => sub.productId === p.productId)
  ).map(p => {
    const config = PRODUCTS_CONFIG.subscriptions.find(sub => sub.productId === p.productId)
    if (config) {
      return {
        ...p,
        type: config.type,
        period: config.period,
        popular: config.popular,
        features: config.features,
        icon: config.icon
      }
    }
    return p
  })
})

// 获取商品图标
const getProductIcon = (productId: string) => {
  const product = products.value.find(p => p.productId === productId)
  return product?.icon || ''
}

// 获取商品标题
const getProductTitle = (productId: string) => {
  return products.value.find(p => p.productId === productId)?.localizedTitle || productId
}

// 获取订阅周期文本
const getPeriodText = (productId: string) => {
  const config = PRODUCTS_CONFIG.subscriptions.find(s => s.productId === productId)
  if (!config) return ''

  switch (config.period) {
    case 'monthly': return '每月'
    case 'quarterly': return '每季度'
    case 'yearly': return '每年'
    default: return ''
  }
}

// 获取订阅特权列表
const getFeatures = (productId: string) => {
  const config = PRODUCTS_CONFIG.subscriptions.find(s => s.productId === productId)
  return config?.features || []
}

// 计算每月价格
const calculateMonthlyPrice = (product: ProductWithMeta) => {
  const price = parseFloat(product.price)
  const config = PRODUCTS_CONFIG.subscriptions.find(s => s.productId === product.productId)
  if (!config) return ''

  let monthlyPrice = price
  switch (config.period) {
    case 'quarterly':
      monthlyPrice = price / 3
      break
    case 'yearly':
      monthlyPrice = price / 12
      break
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

// 显示提示
const showAlert = (title: string, message: string) => {
  alert.value = {
    show: true,
    title,
    message
  }
}

// 初始化商品列表
const initProducts = async () => {
  loading.value = true
  error.value = ''

  try {
    const productIds = [
      ...PRODUCTS_CONFIG.items.map(item => item.productId),
      ...PRODUCTS_CONFIG.subscriptions.map(sub => sub.productId)
    ]

    const result = await OukekPayPlugin.getProducts({ productIds })
    products.value = result.products

    if (result.invalidProductIds.length > 0) {
      console.warn('无效的商品ID:', result.invalidProductIds)
      showAlert('警告', `部分商品未配置: ${result.invalidProductIds.join(', ')}`)
    }
  } catch (err) {
    error.value = '获取商品列表失败，请稍后重试'
    console.error('获取商品失败:', err)
    showAlert('错误', '获取商品列表失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

// 购买商品
const purchase = async (productId: string) => {
  if (purchasing.value) return

  purchasing.value = productId
  try {
    await OukekPayPlugin.purchase({ productId })
  } catch (err) {
    console.error('购买失败:', err)
    showAlert('错误', '购买失败，请重试')
  } finally {
    purchasing.value = ''
  }
}

// 恢复购买
const restorePurchases = async () => {
  if (restoring.value) return

  restoring.value = true
  try {
    await OukekPayPlugin.restorePurchases()
  } catch (err) {
    console.error('恢复购买失败:', err)
    showAlert('错误', '恢复购买失败，请重试')
  } finally {
    restoring.value = false
  }
}

// 处理购买状态
const handlePurchaseState = async (state: PurchaseState) => {
  switch (state.state) {
    case 'purchasing':
      $q.notify({
        type: 'ongoing',
        message: '正在处理购买...'
      })
      break

    case 'succeeded':
      $q.notify({
        type: 'positive',
        message: '购买成功！'
      })
      if (state.receipt) {
        await verifyReceipt(state.receipt, state.productId, state.transactionId)
      }
      break

    case 'failed':
      $q.notify({
        type: 'negative',
        message: `购买失败: ${state.error}`
      })
      break

    case 'cancelled':
      $q.notify({
        type: 'warning',
        message: '购买已取消'
      })
      break

    case 'restored':
      $q.notify({
        type: 'positive',
        message: '购买已恢复'
      })
      if (state.transactions) {
        transactions.value = state.transactions
        showTransactions.value = true
      }
      break

    case 'restoreFailed':
      $q.notify({
        type: 'negative',
        message: '恢复购买失败'
      })
      break

    case 'deferred':
      $q.notify({
        type: 'warning',
        message: '购买已延期'
      })
      break
  }
}

// 验证收据
const verifyReceipt = async (receipt: string, productId?: string, transactionId?: string) => {
  try {
    // 这里替换为你的服务器地址
    const response = await fetch('https://api.yourserver.com/verify-receipt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        receipt,
        productId,
        transactionId,
        platform: 'ios'
      })
    })

    const result = await response.json() as VerifyReceiptResponse

    if (result.valid) {
      // 更新用户物品或订阅状态
      if (result.subscription) {
        updateSubscriptionStatus(result.subscription)
      }
      if (result.items) {
        updateUserItems(result.items)
      }
    } else {
      console.error('收据验证失败:', result.error)
      showAlert('错误', '购买验证失败，请联系客服')
    }
  } catch (err) {
    console.error('验证收据失败:', err)
    showAlert('错误', '购买验证失败，请联系客服')
  }
}

// 更新订阅状态
const updateSubscriptionStatus = (subscription: SubscriptionStatus) => {
  currentSubscription.value = subscription
}

// 更新用户物品
interface VirtualItem {
  virtualItemId: string
  amount: number
}

const updateUserItems = (items: VirtualItem[]) => {
  // 这里实现更新用户物品的逻辑
  console.log('更新用户物品:', items)

  // 示例：显示获得的物品
  const itemNames = items.map(item => {
    const config = PRODUCTS_CONFIG.items.find(p => p.virtualItemId === item.virtualItemId)
    return `${item.amount}${config?.virtualItemId === 'coins' ? '金币' : '钻石'}`
  })

  if (itemNames.length > 0) {
    showAlert('恭喜', `你获得了: ${itemNames.join(', ')}`)
  }
}

// 设置购买监听器
const setupPurchaseListener = async () => {
  // eslint-disable-next-line @typescript-eslint/no-misused-promises
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

<style lang="scss" scoped>
.store-section {
  height: 100%;
}

.product-card {
  transition: transform 0.3s, box-shadow 0.3s;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
  }
}

.product-icon {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;

  :deep(svg) {
    width: 36px;
    height: 36px;
    color: var(--q-primary);
  }
}

.subscription-card {
  position: relative;
  transition: transform 0.3s, box-shadow 0.3s;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
  }

  &.popular {
    border: 2px solid var(--q-primary);
  }
}

.popular-badge {
  position: absolute;
  top: -12px;
  left: 50%;
  transform: translateX(-50%);
}

.price-section {
  text-align: center;
  margin: 1rem 0;
}

.feature-item {
  padding: 4px 0;
}

.subscription-info {
  background: #f8f9fa;
  border-radius: 8px;
  margin-top: 1rem;
}

.subscription-status {
  background: #e3f2fd;
  border-radius: 8px;
  margin-bottom: 1rem;
}
</style>
