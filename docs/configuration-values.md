# Capacitor 插件配置值

本文档详细介绍了如何在 Capacitor 插件中使用和管理配置值。

## 配置值概述

配置值允许你为插件设置默认行为和选项，可以在以下位置定义：

1. 默认配置
2. 全局配置
3. 实例配置
4. 运行时配置

## 配置定义

### TypeScript 配置接口

```typescript
export interface PluginConfig {
    // 必需的配置项
    apiKey: string;
    
    // 可选的配置项
    debug?: boolean;
    timeout?: number;
    
    // 嵌套配置
    api?: {
        endpoint: string;
        version: string;
    };
}
```

### 默认配置

```typescript
const defaultConfig: PluginConfig = {
    apiKey: '',
    debug: false,
    timeout: 30000,
    api: {
        endpoint: 'https://api.example.com',
        version: 'v1'
    }
};
```

## 配置使用

### 1. 插件级别配置

```typescript
@Plugin({
    name: 'MyPlugin',
    platforms: ['ios', 'android'],
    config: {
        apiKey: '',
        debug: false
    }
})
export class MyPlugin implements PluginInterface {
    // 插件实现
}
```

### 2. 应用级别配置

在 `capacitor.config.json` 中：

```json
{
    "plugins": {
        "MyPlugin": {
            "apiKey": "your-api-key",
            "debug": true,
            "api": {
                "endpoint": "https://api.myapp.com",
                "version": "v2"
            }
        }
    }
}
```

### 3. 运行时配置

```typescript
import { Plugins } from '@capacitor/core';
const { MyPlugin } = Plugins;

// 设置配置
await MyPlugin.setConfig({
    apiKey: 'new-api-key',
    debug: true
});

// 获取配置
const config = await MyPlugin.getConfig();
```

## 配置访问

### 在插件中访问配置

```typescript
@Plugin({
    name: 'MyPlugin'
})
export class MyPlugin implements PluginInterface {
    private config: PluginConfig;

    async load() {
        // 获取配置
        this.config = await this.getConfig();
    }

    @PluginMethod()
    async doSomething() {
        if (this.config.debug) {
            console.log('Debug mode enabled');
        }
        
        // 使用配置值
        const response = await fetch(this.config.api.endpoint);
    }
}
```

### 平台特定配置

#### iOS

```swift
@objc(MyPlugin)
public class MyPlugin: CAPPlugin {
    override public func load() {
        // 获取配置值
        let apiKey = getConfigValue("apiKey") as? String ?? ""
        let debug = getConfigValue("debug") as? Bool ?? false
        
        // 使用配置
        if debug {
            print("Debug mode enabled")
        }
    }
}
```

#### Android

```java
@NativePlugin
public class MyPlugin extends Plugin {
    @Override
    public void load() {
        // 获取配置值
        String apiKey = getConfig().getString("apiKey", "");
        boolean debug = getConfig().getBoolean("debug", false);
        
        // 使用配置
        if (debug) {
            Log.d("MyPlugin", "Debug mode enabled");
        }
    }
}
```

## 配置验证

### 验证必需的配置

```typescript
class ConfigurationError extends Error {
    constructor(message: string) {
        super(message);
        this.name = 'ConfigurationError';
    }
}

function validateConfig(config: PluginConfig) {
    if (!config.apiKey) {
        throw new ConfigurationError('API key is required');
    }
    
    if (config.timeout && config.timeout < 0) {
        throw new ConfigurationError('Timeout must be positive');
    }
}
```

### 配置合并

```typescript
function mergeConfig(
    defaultConfig: PluginConfig,
    userConfig: Partial<PluginConfig>
): PluginConfig {
    return {
        ...defaultConfig,
        ...userConfig,
        api: {
            ...defaultConfig.api,
            ...userConfig.api
        }
    };
}
```

## 配置最佳实践

### 1. 配置命名

- 使用描述性名称
- 遵循命名约定
- 使用合适的类型

```typescript
interface WellNamedConfig {
    // 好的命名
    maxRetryAttempts: number;
    requestTimeoutMs: number;
    enableDebugLogging: boolean;
    
    // 避免的命名
    timeout: number;      // 不够具体
    x: boolean;          // 不描述性
    flag: boolean;       // 太模糊
}
```

### 2. 类型安全

```typescript
// 使用枚举限制可能的值
enum LogLevel {
    DEBUG = 'debug',
    INFO = 'info',
    WARN = 'warn',
    ERROR = 'error'
}

interface TypeSafeConfig {
    logLevel: LogLevel;
    maxItems: number;
    allowedDomains: string[];
}
```

### 3. 文档化

```typescript
/**
 * 插件配置接口
 * @property {string} apiKey - API 密钥，用于认证
 * @property {boolean} [debug] - 是否启用调试模式
 * @property {number} [timeout] - 请求超时时间（毫秒）
 */
interface DocumentedConfig {
    apiKey: string;
    debug?: boolean;
    timeout?: number;
}
```

### 4. 版本控制

```typescript
interface ConfigV1 {
    // v1 配置
}

interface ConfigV2 extends ConfigV1 {
    // v2 新增配置
    newFeature: boolean;
}

function migrateConfig(oldConfig: ConfigV1): ConfigV2 {
    return {
        ...oldConfig,
        newFeature: false // 默认值
    };
}
```

## 安全考虑

### 1. 敏感信息处理

```typescript
interface SecureConfig {
    // 避免在日志中暴露
    apiKey: string;
    
    // 非敏感配置
    debug: boolean;
}

function logConfig(config: SecureConfig) {
    console.log('Config:', {
        ...config,
        apiKey: '***' // 隐藏敏感信息
    });
}
```

### 2. 配置验证

```typescript
function validateSecureConfig(config: SecureConfig) {
    // 验证 API 密钥格式
    if (!/^[A-Za-z0-9]{32}$/.test(config.apiKey)) {
        throw new Error('Invalid API key format');
    }
    
    // 验证其他安全相关配置
}
```

## 故障排除

### 常见问题

1. 配置未加载
   - 检查配置文件位置
   - 验证 JSON 格式
   - 确认配置名称正确

2. 类型错误
   - 检查类型定义
   - 验证配置值类型
   - 使用类型断言

3. 配置冲突
   - 检查配置优先级
   - 验证合并逻辑
   - 解决命名冲突

## 下一步

- 了解[插件钩子](./plugin-hooks.md)的使用
- 探索完整的[插件示例](./examples.md)
- 查看[调试指南](./debugging.md) 