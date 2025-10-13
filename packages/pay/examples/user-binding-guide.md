# 用户身份绑定完整指南

## 概述

本指南详细说明如何在 iOS 应用内购买中实现用户身份绑定，确保购买凭证与您的用户体系安全关联。

## 核心原理

### Apple 的设计理念
- **隐私保护**：Apple 不会将 Apple ID 与应用内用户账户自动关联
- **购买绑定**：购买默认绑定到 Apple ID，而非应用用户账户
- **开发者责任**：需要开发者主动实现用户身份绑定

### StoreKit 2 的解决方案
使用 `appAccountToken` 字段在购买时绑定用户身份：
- 格式：UUID
- 来源：应用在发起购买时提供
- 传递：包含在所有相关交易中
- 验证：后端可从交易凭证中提取并验证

## 实现流程

### 1. 前端实现

#### 1.1 发起购买时绑定用户
```typescript
import { OukekPay } from '@oukek/capacitor-pay';

// 生成用户UUID（推荐方式）
const generateUserUUID = (userId: string): string => {
  // 方式一：使用crypto.randomUUID()生成随机UUID
  const uuid = crypto.randomUUID();
  
  // 在数据库中保存 userId -> uuid 的映射关系
  saveUserUUIDMapping(userId, uuid);
  
  return uuid;
};

// 方式二：使用确定性UUID生成（基于用户ID）
const generateDeterministicUUID = (userId: string): string => {
  // 使用UUID v5 (基于SHA-1的命名空间UUID)
  // 注意：需要使用UUID库，如 'uuid' npm包
  const { v5: uuidv5 } = require('uuid');
  const namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // 标准命名空间
  return uuidv5(userId, namespace);
};

// 发起购买
const purchaseWithUser = async (productId: string, userId: string) => {
  try {
    // 生成或获取用户的UUID
    const appAccountToken = await getUserUUID(userId); // 从数据库获取或生成新的UUID
    
    await OukekPay.purchase({ 
      productId, 
      appAccountToken // 直接传入UUID格式的token
    });
  } catch (error) {
    console.error('Purchase failed:', error);
  }
};
```

#### 1.2 处理购买成功回调
```typescript
const setupPurchaseListener = async () => {
  await OukekPay.addListener('purchaseUpdated', async (state) => {
    if (state.state === 'succeeded') {
      console.log('购买成功，用户Token:', state.appAccountToken);
      
      // 发送到后端验证
      await verifyPurchase({
        transactionJWS: state.transactionJWS!,
        appAccountToken: state.appAccountToken, // 绑定的用户UUID
        productId: state.productId!,
        transactionId: state.transactionId!,
        userId: getCurrentUserId(), // 当前登录用户ID（可选，用于双重验证）
      });
    }
  });
};
```

### 2. iOS 插件实现

插件接收UUID格式的 `appAccountToken`：

```swift
// 获取可选的 appAccountToken
var appAccountToken: UUID? = nil
if let appAccountTokenString = call.getString("appAccountToken") {
    if let uuid = UUID(uuidString: appAccountTokenString) {
        appAccountToken = uuid
        print("[OukekPay] 使用提供的 appAccountToken: \(appAccountTokenString)")
    } else {
        call.reject("Invalid appAccountToken format. Must be a valid UUID string.")
        return
    }
}

// 调用购买方法
let result = try await Store.shared.purchase(productId, appAccountToken: appAccountToken)
```

### 3. 后端验证实现

#### 3.1 验证接口
```javascript
app.post('/api/iap/verify', async (req, res) => {
  const { 
    transactionJWS, 
    transactionId, 
    productId, 
    userId,           // 当前登录用户ID（可选）
    appAccountToken   // 购买时绑定的用户UUID（来自交易凭证）
  } = req.body;
  
  try {
    // 1. 验证交易真实性
    const verifyResult = await verifyTransactionWithApple(transactionId);
    if (!verifyResult.success) {
      return res.status(400).json({
        valid: false,
        error: 'Transaction verification failed'
      });
    }
    
    // 2. 解析交易数据
    const decodedTransaction = jwt.decode(verifyResult.data.signedTransactionInfo);
    
    // 3. 验证用户身份绑定
    const userVerification = await verifyUserBinding({
      appAccountToken,
      userId,
      transactionToken: decodedTransaction.appAccountToken
    });
    
    if (!userVerification.valid) {
      return res.status(400).json({
        valid: false,
        error: userVerification.error
      });
    }
    
    // 4. 处理购买逻辑
    await processPurchase({
      userId: userVerification.verifiedUserId,
      productId,
      transactionId,
      transactionData: decodedTransaction
    });
    
    res.json({
      valid: true,
      userId: userVerification.verifiedUserId
    });
    
  } catch (error) {
    res.status(500).json({
      valid: false,
      error: error.message
    });
  }
});
```

#### 3.2 用户身份验证逻辑
```javascript
async function verifyUserBinding({ appAccountToken, userId, transactionToken }) {
  // 验证交易中的 appAccountToken 与请求中的是否一致
  if (appAccountToken !== transactionToken) {
    return {
      valid: false,
      error: 'App account token mismatch'
    };
  }
  
  // 解析用户ID
  let verifiedUserId = null;
  
  if (appAccountToken) {
    // 从 appAccountToken 解析用户ID
    verifiedUserId = await parseUserIdFromToken(appAccountToken);
  }
  
  // 如果同时提供了 userId，进行双重验证
  if (userId && verifiedUserId && userId !== verifiedUserId) {
    return {
      valid: false,
      error: 'User ID and app account token mismatch'
    };
  }
  
  // 确定最终的用户ID
  const finalUserId = verifiedUserId || userId;
  
  if (!finalUserId) {
    return {
      valid: false,
      error: 'Unable to determine user identity'
    };
  }
  
  return {
    valid: true,
    verifiedUserId: finalUserId
  };
}
```

#### 3.3 用户UUID映射管理
```javascript
// 用户UUID映射表结构
// CREATE TABLE user_uuid_mappings (
//   id INT PRIMARY KEY AUTO_INCREMENT,
//   user_id VARCHAR(255) NOT NULL,
//   uuid VARCHAR(36) NOT NULL UNIQUE,
//   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//   INDEX idx_user_id (user_id),
//   INDEX idx_uuid (uuid)
// );

// 从UUID查找用户ID
async function parseUserIdFromToken(appAccountToken) {
  try {
    const result = await db.query(
      'SELECT user_id FROM user_uuid_mappings WHERE uuid = ?', 
      [appAccountToken]
    );
    
    return result.length > 0 ? result[0].user_id : null;
  } catch (error) {
    console.error('Failed to parse user ID from token:', error);
    return null;
  }
}

// 创建用户UUID映射
async function createUserUUIDMapping(userId, uuid) {
  try {
    await db.query(
      `INSERT INTO user_uuid_mappings (user_id, uuid) 
       VALUES (?, ?) 
       ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP`,
      [userId, uuid]
    );
  } catch (error) {
    console.error('Failed to create user UUID mapping:', error);
  }
}

// 获取或创建用户UUID
async function getUserUUID(userId) {
  try {
    // 先查找是否已存在
    const existing = await db.query(
      'SELECT uuid FROM user_uuid_mappings WHERE user_id = ?',
      [userId]
    );
    
    if (existing.length > 0) {
      return existing[0].uuid;
    }
    
    // 不存在则创建新的UUID
    const newUUID = crypto.randomUUID();
    await createUserUUIDMapping(userId, newUUID);
    return newUUID;
    
  } catch (error) {
    console.error('Failed to get user UUID:', error);
    throw error;
  }
}
```

## 安全优势

### 1. 防止凭证劫持
- **问题**：恶意用户截获他人的购买凭证
- **解决**：`appAccountToken` 在购买时就绑定了用户身份，无法被其他用户使用

### 2. 防止重放攻击
- **问题**：同一凭证被多次提交验证
- **解决**：后端记录已处理的交易，并验证用户身份一致性

### 3. 用户身份确认
- **问题**：无法确定购买者的真实身份
- **解决**：通过 `appAccountToken` 直接从交易凭证中获取用户身份

## 最佳实践

### 1. UUID生成策略
```typescript
// 推荐：为每个用户生成唯一的UUID并持久化存储
const getUserUUID = async (userId: string): Promise<string> => {
  // 从数据库或缓存中获取已存在的UUID
  let uuid = await getStoredUUID(userId);
  
  if (!uuid) {
    // 生成新的UUID并存储
    uuid = crypto.randomUUID();
    await storeUserUUID(userId, uuid);
  }
  
  return uuid;
};

// 避免：每次都生成新的UUID
// 这会导致同一用户的不同购买无法关联
```

### 2. 错误处理
```typescript
const purchaseWithRetry = async (productId: string, userId: string, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const appAccountToken = await getUserUUID(userId);
      await OukekPay.purchase({ productId, appAccountToken });
      return; // 成功则退出
    } catch (error) {
      console.error(`Purchase attempt ${i + 1} failed:`, error);
      if (i === maxRetries - 1) throw error; // 最后一次重试失败则抛出错误
      
      // 等待后重试
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
};
```

### 3. 数据库设计
```sql
-- 用户购买记录表
CREATE TABLE user_purchases (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id VARCHAR(255) NOT NULL,
  product_id VARCHAR(255) NOT NULL,
  transaction_id VARCHAR(255) UNIQUE NOT NULL,
  app_account_token VARCHAR(36),
  purchase_date TIMESTAMP NOT NULL,
  expiration_date TIMESTAMP NULL,
  status ENUM('verified', 'expired', 'refunded') DEFAULT 'verified',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_user_id (user_id),
  INDEX idx_transaction_id (transaction_id),
  INDEX idx_app_account_token (app_account_token)
);

-- 用户UUID映射表
CREATE TABLE user_uuid_mappings (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id VARCHAR(255) NOT NULL,
  uuid VARCHAR(36) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_user_id (user_id),
  UNIQUE KEY uk_uuid (uuid)
);
```

## 总结

通过使用 `appAccountToken` 机制，您可以：

1. **在购买时**：前端传入UUID格式的用户标识绑定到交易凭证
2. **在验证时**：直接从凭证中提取用户身份，无需依赖前端传递
3. **在安全上**：防止凭证被其他用户恶意使用
4. **在体验上**：用户无感知，开发者可控

**关键变更**：
- 前端需要传入 `appAccountToken`（UUID格式）而不是 `userId`
- 需要维护用户ID到UUID的映射关系
- 后端验证时通过UUID查找对应的用户ID

这样就实现了您要求的"支付成功的凭证里自带用户体系的用户id，后端可以直接从凭证里校验"的功能。