# 后端支付验证集成指南

## 概述

iOS 应用内购买的安全验证必须在服务器端进行。本指南详细说明如何实现完整的支付验证流程。

## 整体架构

```
iOS App → 前端应用 → 后端服务器 → Apple App Store Server API
   ↓         ↓           ↓              ↓
获取凭证   发送凭证    验证支付        返回验证结果
```

## 1. 数据流向

### 1.1 支付成功后的数据流
```typescript
// iOS 端返回的数据结构
interface PurchaseData {
  productId: string;           // 商品ID
  transactionId: string;       // 交易ID  
  originalTransactionId: string; // 原始交易ID
  purchaseDate: number;        // 购买时间戳
  expirationDate?: number;     // 过期时间（订阅商品）
  isUpgraded: boolean;         // 是否升级
  transactionJWS: string;      // JWS 签名的交易数据（推荐）
  appAccountToken?: string;    // 绑定的用户ID（UUID格式）
  receiptData?: string;        // Base64 编码的收据数据（兼容）
}
```

### 1.2 前端发送给后端的数据
```typescript
interface VerifyPurchaseRequest {
  // 必需字段
  transactionJWS: string;      // 优先使用 JWS
  productId: string;
  transactionId: string;
  
  // 用户身份验证（二选一或同时使用）
  userId?: string;             // 当前登录用户ID
  appAccountToken?: string;    // 购买时绑定的用户ID（来自交易凭证）
  
  // 可选字段
  receiptData?: string;        // 兼容旧版本
  originalTransactionId?: string;
  purchaseDate?: number;
  expirationDate?: number;
  platform: 'ios';
}
```

## 2. 后端验证实现

### 2.1 推荐方案：使用 App Store Server API

#### 优势
- 更安全：基于 JWT 认证
- 更准确：直接从 Apple 获取最新状态
- 更完整：支持订阅状态查询、退款检测等

#### 实现步骤

**Step 1: 生成 JWT Token**
```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

// 从 App Store Connect 下载的私钥文件
const privateKey = fs.readFileSync('path/to/AuthKey_XXXXXXXXXX.p8');

function generateJWT() {
  const now = Math.floor(Date.now() / 1000);
  
  const payload = {
    iss: 'YOUR_ISSUER_ID',        // App Store Connect 中的 Issuer ID
    iat: now,                     // 签发时间
    exp: now + 3600,              // 过期时间（1小时）
    aud: 'appstoreconnect-v1',    // 固定值
    bid: 'com.yourapp.bundleid'   // 你的应用 Bundle ID
  };
  
  const header = {
    alg: 'ES256',
    kid: 'YOUR_KEY_ID',           // App Store Connect 中的 Key ID
    typ: 'JWT'
  };
  
  return jwt.sign(payload, privateKey, { 
    algorithm: 'ES256',
    header: header
  });
}
```

**Step 2: 验证交易**
```javascript
const axios = require('axios');

async function verifyTransaction(transactionId) {
  const jwtToken = generateJWT();
  const isProduction = process.env.NODE_ENV === 'production';
  
  // 生产环境和沙盒环境的 URL
  const baseURL = isProduction 
    ? 'https://api.storekit.itunes.apple.com'
    : 'https://api.storekit-sandbox.itunes.apple.com';
  
  try {
    const response = await axios.get(
      `${baseURL}/inApps/v1/transactions/${transactionId}`,
      {
        headers: {
          'Authorization': `Bearer ${jwtToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    return {
      success: true,
      data: response.data
    };
  } catch (error) {
    if (error.response?.status === 404 && !isProduction) {
      // 如果是沙盒环境404，尝试生产环境
      return verifyTransaction(transactionId, true);
    }
    
    return {
      success: false,
      error: error.response?.data || error.message
    };
  }
}
```

**Step 3: 验证接口实现**
```javascript
// Express.js 示例
app.post('/api/iap/verify', async (req, res) => {
  const { transactionJWS, transactionId, productId, userId, appAccountToken } = req.body;
  
  try {
    // 1. 验证交易
    const verifyResult = await verifyTransaction(transactionId);
    
    if (!verifyResult.success) {
      return res.status(400).json({
        valid: false,
        error: 'Transaction verification failed'
      });
    }
    
    // 2. 解析交易数据
    const transactionInfo = verifyResult.data.signedTransactionInfo;
    // 注意：signedTransactionInfo 是 JWS 格式，需要解码
    const decodedTransaction = jwt.decode(transactionInfo);
    
    // 3. 验证商品ID匹配
    if (decodedTransaction.productId !== productId) {
      return res.status(400).json({
        valid: false,
        error: 'Product ID mismatch'
      });
    }
    
    // 4. 用户身份验证（重要安全检查）
    let verifiedUserId = userId;
    
    if (appAccountToken) {
      // 如果交易包含 appAccountToken，验证是否匹配
      if (decodedTransaction.appAccountToken !== appAccountToken) {
        return res.status(400).json({
          valid: false,
          error: 'App account token mismatch'
        });
      }
      
      // 从 appAccountToken 解析用户ID（如果使用了命名空间UUID）
      const tokenUserId = parseUserIdFromToken(appAccountToken);
      if (tokenUserId && userId && tokenUserId !== userId) {
        return res.status(400).json({
          valid: false,
          error: 'User ID and app account token mismatch'
        });
      }
      
      verifiedUserId = tokenUserId || userId;
    }
    
    if (!verifiedUserId) {
      return res.status(400).json({
        valid: false,
        error: 'Unable to determine user identity'
      });
    }
    
    // 5. 检查交易是否已处理过
    const existingTransaction = await db.findTransaction(transactionId);
    if (existingTransaction) {
      // 验证是否是同一用户
      if (existingTransaction.userId !== verifiedUserId) {
        return res.status(400).json({
          valid: false,
          error: 'Transaction belongs to different user'
        });
      }
      
      return res.json({
        valid: true,
        message: 'Transaction already processed'
      });
    }
    
    // 6. 更新用户状态
    await updateUserPurchase({
      userId: verifiedUserId,
      productId,
      transactionId,
      purchaseDate: decodedTransaction.purchaseDate,
      expirationDate: decodedTransaction.expiresDate
    });
    
    // 7. 记录交易
    await db.saveTransaction({
      transactionId,
      userId: verifiedUserId,
      productId,
      appAccountToken,
      status: 'verified',
      purchaseDate: decodedTransaction.purchaseDate
    });
    
    res.json({
      valid: true,
      transaction: {
        transactionId,
        productId,
        purchaseDate: decodedTransaction.purchaseDate,
        expirationDate: decodedTransaction.expiresDate
      }
    });
    
  } catch (error) {
    console.error('Verify purchase error:', error);
    res.status(500).json({
      valid: false,
      error: 'Internal server error'
    });
  }
});
```

### 2.2 兼容方案：收据验证

如果暂时无法使用 App Store Server API，可以使用传统的收据验证：

```javascript
async function verifyReceipt(receiptData) {
  const isProduction = process.env.NODE_ENV === 'production';
  const verifyURL = isProduction
    ? 'https://buy.itunes.apple.com/verifyReceipt'
    : 'https://sandbox.itunes.apple.com/verifyReceipt';
  
  const requestBody = {
    'receipt-data': receiptData,
    'password': 'YOUR_SHARED_SECRET', // App Store Connect 中的共享密钥
    'exclude-old-transactions': true
  };
  
  try {
    const response = await axios.post(verifyURL, requestBody);
    return response.data;
  } catch (error) {
    throw new Error('Receipt verification failed');
  }
}
```

## 3. 订阅状态管理

### 3.1 检查订阅状态
```javascript
async function checkSubscriptionStatus(originalTransactionId) {
  const jwtToken = generateJWT();
  const baseURL = process.env.NODE_ENV === 'production'
    ? 'https://api.storekit.itunes.apple.com'
    : 'https://api.storekit-sandbox.itunes.apple.com';
  
  try {
    const response = await axios.get(
      `${baseURL}/inApps/v1/subscriptions/${originalTransactionId}`,
      {
        headers: {
          'Authorization': `Bearer ${jwtToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    return response.data;
  } catch (error) {
    throw new Error('Subscription status check failed');
  }
}
```

### 3.2 处理订阅续期和取消
```javascript
// 定期检查订阅状态的任务
async function updateSubscriptionStatuses() {
  const activeSubscriptions = await db.getActiveSubscriptions();
  
  for (const subscription of activeSubscriptions) {
    try {
      const status = await checkSubscriptionStatus(subscription.originalTransactionId);
      
      // 更新订阅状态
      await db.updateSubscription(subscription.userId, {
        status: status.data[0].lastTransactions[0].status,
        expirationDate: status.data[0].lastTransactions[0].expiresDate
      });
    } catch (error) {
      console.error(`Failed to update subscription ${subscription.id}:`, error);
    }
  }
}

// 每小时执行一次
setInterval(updateSubscriptionStatuses, 60 * 60 * 1000);
```

## 4. 恢复购买处理

```javascript
app.post('/api/iap/restore', async (req, res) => {
  const { transactions, userId } = req.body;
  const restoredItems = [];
  
  for (const transaction of transactions) {
    try {
      // 验证每个交易
      const verifyResult = await verifyTransaction(transaction.transactionId);
      
      if (verifyResult.success) {
        // 恢复用户的购买/订阅
        await restoreUserPurchase(userId, transaction);
        restoredItems.push({
          productId: transaction.productId,
          transactionId: transaction.transactionId,
          status: 'restored'
        });
      }
    } catch (error) {
      console.error(`Failed to restore transaction ${transaction.transactionId}:`, error);
    }
  }
  
  res.json({
    success: true,
    restoredItems
  });
});
```

## 4. 用户身份解析工具函数

```javascript
// 解析 appAccountToken 中的用户ID（如果使用了命名空间UUID）
function parseUserIdFromToken(appAccountToken) {
  try {
    // 如果直接使用用户ID作为UUID（需要是有效的UUID格式）
    if (isValidUUID(appAccountToken)) {
      // 这里可以实现你的UUID到用户ID的映射逻辑
      // 例如：从数据库查询UUID对应的用户ID
      return lookupUserIdByUUID(appAccountToken);
    }
    
    // 如果使用了命名空间UUID，可能需要反向解析
    // 注意：UUID v5 是单向的，无法直接反向解析
    // 建议在数据库中维护 UUID -> 用户ID 的映射关系
    
    return null;
  } catch (error) {
    console.error('Failed to parse user ID from token:', error);
    return null;
  }
}

function isValidUUID(str) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(str);
}

async function lookupUserIdByUUID(uuid) {
  // 从数据库查询UUID对应的用户ID
  const result = await db.query('SELECT user_id FROM user_tokens WHERE uuid = ?', [uuid]);
  return result.length > 0 ? result[0].user_id : null;
}

// 创建用户UUID映射（在用户购买时调用）
async function createUserUUIDMapping(userId, uuid) {
  await db.query(
    'INSERT INTO user_tokens (user_id, uuid, created_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE updated_at = NOW()',
    [userId, uuid]
  );
}
```

## 5. 安全注意事项

1. **永远不要在客户端验证支付**
2. **使用 HTTPS 传输所有数据**
3. **验证用户身份**：确保只有登录用户才能提交验证请求
4. **防重复处理**：检查交易ID是否已处理过
5. **记录所有交易**：便于审计和问题排查
6. **定期同步状态**：特别是订阅状态
7. **处理边缘情况**：网络错误、Apple 服务不可用等

## 6. 测试建议

1. **沙盒测试**：使用 App Store Connect 创建的测试账号
2. **生产测试**：小范围真实用户测试
3. **边缘情况测试**：网络中断、重复请求等
4. **性能测试**：高并发验证请求

## 7. 监控和日志

```javascript
// 记录关键操作
function logPurchaseEvent(event, data) {
  console.log(`[IAP] ${event}:`, {
    timestamp: new Date().toISOString(),
    ...data
  });
  
  // 发送到监控系统
  // monitoring.track('iap_event', { event, ...data });
}

// 使用示例
logPurchaseEvent('purchase_verified', {
  userId,
  productId,
  transactionId,
  amount: product.price
});
```

这样的架构确保了支付验证的安全性和可靠性，同时为你的应用提供了完整的购买和订阅管理能力。