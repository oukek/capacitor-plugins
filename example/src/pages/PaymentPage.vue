<template>
  <div class="q-pa-md payment-container">
    <h2 class="text-h4 q-mb-md">支付测试</h2>

    <!-- 加载状态 -->
    <div v-if="loading" class="q-pa-lg flex flex-center">
      <q-spinner size="3em" color="primary" />
      <span class="q-ml-sm">加载商品信息中...</span>
    </div>

    <!-- 错误提示 -->
    <div v-if="error" class="error-message q-mb-md">
      <q-banner rounded class="bg-red-1 text-red">
        {{ error }}
        <template v-slot:action>
          <q-btn flat color="primary" label="重试" @click="initProducts" />
        </template>
      </q-banner>
    </div>

    <!-- 消耗型商品 -->
    <div v-if="!loading && !error" class="q-mb-xl">
      <h3 class="text-h5 q-mb-md">消耗型商品</h3>
      <div class="row q-col-gutter-md">
        <div class="col-12 col-sm-6 col-md-4" v-for="product in consumableProducts" :key="product.productId">
          <q-card class="product-card">
            <q-card-section class="bg-primary text-white text-center">
              <div class="text-h6">{{ product.localizedTitle }}</div>
            </q-card-section>
            <q-card-section>
              <div class="text-body2">{{ product.localizedDescription }}</div>
            </q-card-section>
            <q-card-section class="text-center q-pt-none">
              <div class="text-h5 text-primary q-mb-md">{{ product.localizedPrice }}</div>
              <q-btn
                color="primary"
                :loading="purchasing === product.productId"
                @click="purchase(product.productId)">
                {{ purchasing === product.productId ? '购买中...' : '购买' }}
              </q-btn>
            </q-card-section>
          </q-card>
        </div>
      </div>
    </div>

    <!-- 订阅商品 -->
    <div v-if="!loading && !error" class="q-mb-xl">
      <h3 class="text-h5 q-mb-md">会员订阅</h3>

      <!-- 当前订阅状态 -->
      <div v-if="currentSubscription" class="q-mb-md">
        <q-card class="bg-blue-1">
          <q-card-section>
            <div class="text-h6">当前订阅</div>
            <div class="text-subtitle2">{{ currentSubscription.name }}</div>
            <div>到期时间: {{ formatDate(currentSubscription.expiryDate) }}</div>
            <div v-if="currentSubscription.isUpgraded" class="text-positive">
              已升级到更高等级会员
            </div>
          </q-card-section>
        </q-card>
      </div>

      <div class="row q-col-gutter-md">
        <div class="col-12 col-sm-6 col-md-4" v-for="plan in subscriptionProducts" :key="plan.productId">
          <q-card class="product-card" :class="{'border-primary': plan.popular}">
            <q-badge v-if="plan.popular" color="orange" class="absolute-top-right q-ma-sm">
              最受欢迎
            </q-badge>
            <q-card-section class="bg-teal text-white text-center">
              <div class="text-h6">{{ plan.localizedTitle }}</div>
            </q-card-section>
            <q-card-section>
              <div class="text-body2">{{ plan.localizedDescription }}</div>
            </q-card-section>
            <q-card-section>
              <ul class="features q-pl-md">
                <li v-for="(feature, index) in getFeatures(plan.productId)" :key="index">
                  {{ feature }}
                </li>
              </ul>
            </q-card-section>
            <q-card-section class="text-center">
              <div class="text-h5 text-teal q-mb-sm">{{ plan.localizedPrice }}</div>
              <div class="text-caption q-mb-md">{{ calculateMonthlyPrice(plan) }}</div>
              <q-btn
                color="teal"
                :loading="purchasing === plan.productId"
                @click="subscribe(plan.productId)">
                {{ purchasing === plan.productId ? '订阅中...' : '立即订阅' }}
              </q-btn>
            </q-card-section>
          </q-card>
        </div>
      </div>

      <!-- 恢复购买按钮 -->
      <div class="text-center q-mt-lg">
        <q-btn outline color="primary" label="恢复购买" @click="restoreSubscription" :loading="restoring" />
      </div>

      <!-- 订阅说明 -->
      <div class="subscription-info q-pa-md q-mt-md bg-grey-2 rounded-borders text-grey-8">
        <p class="text-caption q-mb-xs">• 订阅会自动续费，可随时在 App Store 中取消</p>
        <p class="text-caption q-mb-xs">• 付款将在确认购买时从 iTunes 账户中扣除</p>
        <p class="text-caption q-mb-xs">• 订阅到期前 24 小时内将自动续费</p>
        <p class="text-caption q-mb-none">• 可以在购买后通过 App Store 管理订阅</p>
      </div>
    </div>

    <!-- 购买历史记录 -->
    <div v-if="!loading && !error && purchaseHistory.length > 0" class="q-mt-xl">
      <h3 class="text-h5 q-mb-md">购买历史</h3>

      <q-table
        :rows="purchaseHistory"
        :columns="historyColumns"
        row-key="transactionId"
        dense
        flat
        bordered
        class="history-table"
        :pagination="{ rowsPerPage: 5 }"
      >
        <template v-slot:body-cell-productId="props">
          <q-td :props="props">
            {{ getProductName(props.value) }}
          </q-td>
        </template>

        <template v-slot:body-cell-purchaseDate="props">
          <q-td :props="props">
            {{ formatDateTime(props.value) }}
          </q-td>
        </template>

        <template v-slot:body-cell-expirationDate="props">
          <q-td :props="props">
            {{ props.value ? formatDateTime(props.value) : '不适用' }}
          </q-td>
        </template>

        <template v-slot:body-cell-receipt="props">
          <q-td :props="props">
            <q-btn
              v-if="props.value"
              dense
              flat
              color="primary"
              icon="visibility"
              size="sm"
              @click="showReceipt(props.value)"
            />
            <span v-else>无收据</span>
          </q-td>
        </template>
      </q-table>

      <div class="text-center q-mt-md">
        <q-btn outline color="negative" label="清除购买历史" @click="confirmClearHistory" />
      </div>
    </div>

    <!-- 状态提示 -->
    <q-dialog v-model="showStatusDialog">
      <q-card>
        <q-card-section :class="statusDialogColor">
          <div class="text-h6">{{ statusDialogTitle }}</div>
        </q-card-section>
        <q-card-section>
          <div>{{ statusDialogMessage }}</div>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat label="确定" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- 收据弹窗 -->
    <q-dialog v-model="showReceiptDialog">
      <q-card style="width: 700px; max-width: 90vw">
        <q-card-section class="bg-primary text-white">
          <div class="text-h6">购买收据</div>
        </q-card-section>
        <q-card-section class="receipt-content">
          <q-input
            v-model="receiptContent"
            type="textarea"
            readonly
            filled
            autogrow
          />
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat label="关闭" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- 确认对话框 -->
    <q-dialog v-model="showConfirmDialog">
      <q-card>
        <q-card-section class="bg-warning text-white">
          <div class="text-h6">确认操作</div>
        </q-card-section>
        <q-card-section>
          <p>确定要清除所有购买历史记录吗？此操作不可恢复。</p>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat label="取消" color="primary" v-close-popup />
          <q-btn flat label="确定" color="negative" @click="clearPurchaseHistory" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { OukekPay } from '@oukek/capacitor-pay'
import type { Product, PurchaseUpdatedState } from '@oukek/capacitor-pay'

// 兼容扩展类型：增加 transactionJWS（服务端验证优先使用）
 type PurchaseUpdatedStateWithJWS = PurchaseUpdatedState & { transactionJWS?: string }
 // 恢复交易扩展类型：包含 transactionJWS
 type RestoredTxWithJWS = { productId: string; transactionId: string; transactionJWS?: string }

// 本地存储键名
const STORAGE_KEYS = {
  SUBSCRIPTION: 'app_subscription_status',
  PURCHASE_HISTORY: 'app_purchase_history'
}

interface Subscription {
  name: string
  expiryDate: number
  isUpgraded: boolean
}

// 定义购买记录接口
interface PurchaseRecord {
  productId: string
  transactionId: string
  purchaseDate: number
  receipt?: string | undefined
  expirationDate?: number | undefined
}

// 定义包含popular属性的Product扩展类型
interface ProductWithPopular extends Product {
  popular: boolean;
}

// 状态变量
const loading = ref(false)
const error = ref('')
const purchasing = ref('')
const restoring = ref(false)
const showStatusDialog = ref(false)
const statusDialogTitle = ref('')
const statusDialogMessage = ref('')
const statusDialogColor = ref('bg-primary text-white')
const showReceiptDialog = ref(false)
const receiptContent = ref('')
const showConfirmDialog = ref(false)

const consumableProducts = ref<Product[]>([])
const subscriptionProducts = ref<ProductWithPopular[]>([])
const currentSubscription = ref<Subscription | null>(null)
const purchaseHistory = ref<PurchaseRecord[]>([])

// 购买历史表格列定义
const historyColumns = [
  {
    name: 'productId',
    required: true,
    label: '商品',
    align: 'left' as const,
    field: 'productId',
    sortable: true
  },
  {
    name: 'transactionId',
    required: true,
    label: '交易ID',
    align: 'left' as const,
    field: 'transactionId'
  },
  {
    name: 'purchaseDate',
    required: true,
    label: '购买时间',
    align: 'left' as const,
    field: 'purchaseDate',
    sortable: true
  },
  {
    name: 'expirationDate',
    required: false,
    label: '过期时间',
    align: 'left' as const,
    field: 'expirationDate',
    sortable: true
  },
  {
    name: 'receipt',
    required: false,
    label: '收据',
    align: 'center' as const,
    field: 'receipt'
  }
]

// 商品ID
const CONSUMABLE_PRODUCT_IDS = [
  '20', // 上传文档，28元
]

// 订阅产品ID
const SUBSCRIPTION_PRODUCT_IDS = [
  '10',    // 月度会员 99元
  '11',  // 季度会员 268元
  '12'      // 年度会员 699元
]

// 本地存储的商品信息 (实际中通常由后端提供)
// TODO: 这部分应该从后端API获取
const LOCAL_PRODUCTS: Record<string, Product> = {
  '20': {
    productId: '20',
    price: 28,
    localizedPrice: '¥28.00',
    localizedTitle: '上传文档',
    localizedDescription: '购买后可上传一篇文档进行分析'
  },
  '10': {
    productId: '10',
    price: 99,
    localizedPrice: '¥99.00',
    localizedTitle: '月度会员',
    localizedDescription: '每月订阅，解锁所有高级功能'
  },
  '11': {
    productId: '11',
    price: 268,
    localizedPrice: '¥268.00',
    localizedTitle: '季度会员',
    localizedDescription: '每季度订阅，优惠价格，解锁所有高级功能'
  },
  '12': {
    productId: '12',
    price: 699,
    localizedPrice: '¥699.00',
    localizedTitle: '年度会员',
    localizedDescription: '每年订阅，最佳性价比，解锁所有高级功能'
  }
}

// 获取商品名称
const getProductName = (productId: string) => {
  const product = LOCAL_PRODUCTS[productId]
  return product ? product.localizedTitle : productId
}

// 订阅特权
// TODO: 这部分应该从后端API获取
const SUBSCRIPTION_FEATURES: Record<string, string[]> = {
  '10': [
    '✓ 无限上传文档',
    '✓ 优先分析处理',
    '✓ 高级AI分析功能'
  ],
  '11': [
    '✓ 无限上传文档',
    '✓ 优先分析处理',
    '✓ 高级AI分析功能',
    '✓ 10% 额外积分奖励'
  ],
  '12': [
    '✓ 无限上传文档',
    '✓ 优先分析处理',
    '✓ 高级AI分析功能',
    '✓ 20% 额外积分奖励',
    '✓ 专属年度会员标识'
  ]
}

// 获取订阅特权列表
const getFeatures = (productId: string) => {
  return SUBSCRIPTION_FEATURES[productId] || []
}

// 计算每月价格
const calculateMonthlyPrice = (plan: Product) => {
  const price = plan.price
  const productId = plan.productId
  let monthlyPrice = price

  if (productId === '11') {
    monthlyPrice = price / 3
  } else if (productId === '12') {
    monthlyPrice = price / 12
  }

  return `约合每月 ¥${monthlyPrice.toFixed(2)}`
}

// 格式化日期
const formatDate = (timestamp: number) => {
  return new Date(timestamp).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

// 格式化日期和时间
const formatDateTime = (timestamp: number) => {
  return new Date(timestamp).toLocaleString('zh-CN', {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 从本地存储读取数据
const loadFromLocalStorage = () => {
  try {
    // 读取订阅状态
    const savedSubscription = localStorage.getItem(STORAGE_KEYS.SUBSCRIPTION)
    if (savedSubscription) {
      const parsed = JSON.parse(savedSubscription)
      // 检查订阅是否过期
      if (parsed.expiryDate > Date.now()) {
        currentSubscription.value = parsed
      } else {
        // 如果订阅已过期，清除存储
        localStorage.removeItem(STORAGE_KEYS.SUBSCRIPTION)
      }
    }

    // 读取购买历史
    const savedHistory = localStorage.getItem(STORAGE_KEYS.PURCHASE_HISTORY)
    if (savedHistory) {
      purchaseHistory.value = JSON.parse(savedHistory)
    }
  } catch (error) {
    console.error('读取本地存储失败:', error)
  }
}

// 已由服务端验证返回后统一更新本地存储（示例不直接调用保存方法）

// 已由服务端验证返回后统一更新本地购买记录（示例中不在前端直接写入）

// 显示收据内容
const showReceipt = (receipt: string) => {
  receiptContent.value = receipt
  showReceiptDialog.value = true
}

// 确认清除历史
const confirmClearHistory = () => {
  showConfirmDialog.value = true
}

// 清除购买历史
const clearPurchaseHistory = () => {
  purchaseHistory.value = []
  localStorage.removeItem(STORAGE_KEYS.PURCHASE_HISTORY)
}

// 模拟获取商品信息
// TODO: 替换为真实的OukekPay.getProducts调用
const initProducts = async () => {
  loading.value = true
  error.value = ''

  try {
    // 模拟延迟
    await new Promise(resolve => setTimeout(resolve, 800))

    // 模拟获取商品，确保所有ID都有对应的商品
    consumableProducts.value = CONSUMABLE_PRODUCT_IDS
      .map(id => LOCAL_PRODUCTS[id])
      .filter((product): product is Product => !!product)

    // 订阅商品添加额外信息
    subscriptionProducts.value = SUBSCRIPTION_PRODUCT_IDS
      .map(id => {
        const product = LOCAL_PRODUCTS[id]
        if (product) {
          return {
            ...product,
            popular: id === '12'
          }
        }
        return undefined
      })
      .filter((product): product is ProductWithPopular => !!product)

    // 从本地存储加载数据
    loadFromLocalStorage()

    /* 实际代码应该类似这样:
    const result = await OukekPay.getProducts({
      productIds: [...CONSUMABLE_PRODUCT_IDS, ...SUBSCRIPTION_PRODUCT_IDS]
    })
    consumableProducts.value = result.products.filter(p => CONSUMABLE_PRODUCT_IDS.includes(p.productId))
    subscriptionProducts.value = result.products
      .filter(p => SUBSCRIPTION_PRODUCT_IDS.includes(p.productId))
      .map(product => ({
        ...product,
        popular: product.productId === 'yearly_member'
      }))
    */
  } catch (err) {
    error.value = '获取商品信息失败，请稍后重试'
    console.error('获取商品失败:', err)
  } finally {
    loading.value = false
  }
}

// 购买消耗型商品
const purchase = async (productId: string) => {
  purchasing.value = productId

  try {
    // TODO: 替换为真实的OukekPay.purchase调用
    await OukekPay.purchase({ productId })

    // 注意：购买结果会通过事件监听器收到，这里不需要显示结果
  } catch (err) {
    showStatus('错误', '购买失败，请重试', 'negative')
    console.error('购买失败:', err)
  } finally {
    purchasing.value = ''
  }
}

// 订阅会员
const subscribe = async (productId: string) => {
  purchasing.value = productId

  try {
    // TODO: 替换为真实的OukekPay.purchase调用
    await OukekPay.purchase({ productId })

    // 注意：购买结果会通过事件监听器收到，这里不需要显示结果
  } catch (err) {
    showStatus('错误', '订阅失败，请重试', 'negative')
    console.error('订阅失败:', err)
  } finally {
    purchasing.value = ''
  }
}

// 恢复购买
const restoreSubscription = async () => {
  restoring.value = true

  try {
    await OukekPay.restorePurchases()
    showStatus('提示', '正在恢复购买，请稍候...', 'info')
  } catch (err) {
    showStatus('错误', '恢复购买失败', 'negative')
    console.error('恢复购买失败:', err)
  } finally {
    restoring.value = false
  }
}

// 显示状态对话框
const showStatus = (title: string, message: string, type: 'positive' | 'negative' | 'info') => {
  statusDialogTitle.value = title
  statusDialogMessage.value = message

  switch (type) {
    case 'positive':
      statusDialogColor.value = 'bg-positive text-white'
      break
    case 'negative':
      statusDialogColor.value = 'bg-negative text-white'
      break
    case 'info':
    default:
      statusDialogColor.value = 'bg-info text-white'
      break
  }

  showStatusDialog.value = true
}

// 提交购买到后端进行验证（仅示例，实际应调用后端API）
const submitPurchaseForValidation = async (params: {
  transactionJWS?: string | undefined
  receipt?: string | undefined
  productId: string
  transactionId: string
  originalTransactionId?: string | undefined
  purchaseDate?: number | undefined
  expirationDate?: number | undefined
}) => {
  console.log('提交购买到后端验证:', params)
  // TODO: 调用后端接口，例如：
  // await fetch('/your-server/iap/verify', {
  //   method: 'POST',
  //   headers: { 'Content-Type': 'application/json' },
  //   body: JSON.stringify({
  //     transactionJWS: params.transactionJWS, // 推荐
  //     receipt: params.receipt,               // 兼容字段，可选
  //     productId: params.productId,
  //     transactionId: params.transactionId,
  //     originalTransactionId: params.originalTransactionId,
  //     purchaseDate: params.purchaseDate,
  //     expirationDate: params.expirationDate
  //   })
  // })
  // const result = await response.json()
  // TODO: 根据后端返回更新本地状态（购买历史、订阅状态等）
}

// 提交恢复的交易到后端进行验证（仅示例）
const submitRestoredTransactionsForValidation = async (transactions: Array<{
  productId: string
  transactionId: string
  transactionJWS?: string | undefined
  originalTransactionId?: string | undefined
  purchaseDate?: number | undefined
  expirationDate?: number | undefined
}>) => {
  console.log('提交恢复交易到后端验证:', transactions)
  // TODO: 调用后端接口批量验证恢复的交易
  // 例如：
  // await fetch('/your-server/iap/restore', {
  //   method: 'POST',
  //   headers: { 'Content-Type': 'application/json' },
  //   body: JSON.stringify({ transactions })
  // })
  // TODO: 根据后端返回更新本地订阅状态与历史记录
}

// 处理购买状态
const handlePurchaseState = async (state: PurchaseUpdatedState) => {
  console.log('购买状态更新:', state)

  switch (state.state) {
    case 'purchasing':
      showStatus('提示', '正在处理购买...', 'info')
      break

    case 'succeeded':
      showStatus('成功', '购买成功，已提交验证！', 'positive')

      try {
        const jws = (state as PurchaseUpdatedStateWithJWS).transactionJWS
        await submitPurchaseForValidation({
          transactionJWS: jws,                 // 推荐：服务端使用JWS验证
          receipt: state.receipt ?? undefined, // 兼容旧服务端，可选
          productId: state.productId!,
          transactionId: state.transactionId!,
          originalTransactionId: state.originalTransactionId ?? undefined,
          purchaseDate: state.purchaseDate ?? undefined,
          expirationDate: state.expirationDate ?? undefined
        })
      } catch (err) {
        console.error('提交验证失败:', err)
        showStatus('错误', '购买验证提交失败，请稍后重试', 'negative')
      }
      break

    case 'failed':
      showStatus('错误', `购买失败: ${state.error || '未知错误'}`, 'negative')
      break

    case 'cancelled':
      showStatus('提示', '购买已取消', 'info')
      break

    case 'deferred':
      showStatus('提示', '购买需要批准，请等待...', 'info')
      break

    case 'restored':
      showStatus('成功', '购买已恢复，已提交验证', 'positive')

      if (state.transactions && state.transactions.length > 0) {
        try {
          await submitRestoredTransactionsForValidation(
            (state.transactions as RestoredTxWithJWS[]).map(t => ({
              productId: t.productId,
              transactionId: t.transactionId,
              transactionJWS: t.transactionJWS,
            }))
          )
        } catch (err) {
          console.error('提交恢复交易验证失败:', err)
          showStatus('错误', '恢复购买验证提交失败，请稍后重试', 'negative')
        }
      }
      break
  }
}

// 设置购买监听器
const setupPurchaseListener = async () => {
  await OukekPay.addListener('purchaseUpdated', handlePurchaseState)
}

// 组件挂载时初始化
onMounted(async () => {
  await setupPurchaseListener()
  await initProducts()
})

// 组件卸载时清理
onUnmounted(async () => {
  await OukekPay.removeAllListeners()
})
</script>

<style scoped>
.payment-container {
  max-width: 1200px;
  margin: 0 auto;
}

.product-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: all 0.3s ease;
}

.product-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.border-primary {
  border: 2px solid var(--q-primary);
}

.features {
  margin: 0;
  padding-left: 20px;
}

.features li {
  margin-bottom: 8px;
}

.subscription-info {
  border-radius: 4px;
}
</style>
