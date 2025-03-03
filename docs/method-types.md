# Capacitor 插件方法类型

本文档详细介绍了 Capacitor 插件中可用的不同方法类型及其使用场景。

## 方法类型概述

Capacitor 插件支持以下主要方法类型：

1. 同步方法
2. 异步方法
3. 事件监听器
4. 回调方法

## 同步方法

### 定义

同步方法立即返回结果，适用于快速、简单的操作。

```typescript
@PluginMethod()
sync echo(options: { value: string }): Promise<{ value: string }> {
    return Promise.resolve({ value: options.value });
}
```

### 使用场景

- 简单的数据转换
- 本地计算
- 配置读取
- 状态检查

### 最佳实践

- 避免耗时操作
- 保持操作简单
- 处理所有可能的错误
- 提供类型定义

## 异步方法

### 定义

异步方法用于处理需要时间完成的操作。

```typescript
@PluginMethod()
async getLocation(): Promise<{ latitude: number; longitude: number }> {
    return new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                resolve({
                    latitude: position.coords.latitude,
                    longitude: position.coords.longitude
                });
            },
            (error) => reject(error)
        );
    });
}
```

### 使用场景

- 网络请求
- 文件操作
- 数据库查询
- 硬件访问

### 最佳实践

- 正确处理异步错误
- 提供进度更新
- 实现超时机制
- 考虑取消操作

## 事件监听器

### 定义

事件监听器用于持续监听和响应事件。

```typescript
@PluginMethod()
addListener(eventName: string, callback: Function) {
    const listener = this.listeners[eventName] = (event: any) => {
        callback(event);
    };
    return {
        remove: () => {
            delete this.listeners[eventName];
        }
    };
}
```

### 使用场景

- 传感器数据监听
- 网络状态变化
- 位置更新
- 实时数据流

### 最佳实践

- 提供清理机制
- 避免内存泄漏
- 控制事件频率
- 处理监听器异常

## 回调方法

### 定义

回调方法用于处理需要多次响应的操作。

```typescript
@PluginMethod()
startProcess(options: { 
    onProgress: (progress: number) => void,
    onComplete: () => void 
}) {
    let progress = 0;
    const interval = setInterval(() => {
        progress += 10;
        options.onProgress(progress);
        if (progress >= 100) {
            clearInterval(interval);
            options.onComplete();
        }
    }, 1000);
}
```

### 使用场景

- 文件上传进度
- 下载进度
- 长时间处理
- 分步操作

### 最佳实践

- 提供进度更新
- 允许取消操作
- 处理错误情况
- 清理资源

## 平台特定方法

### iOS 示例

```swift
@objc func myMethod(_ call: CAPPluginCall) {
    guard let value = call.getString("value") else {
        call.reject("Value is required")
        return
    }
    
    // 平台特定实现
    call.resolve([
        "result": "iOS specific result"
    ])
}
```

### Android 示例

```java
@PluginMethod
public void myMethod(PluginCall call) {
    String value = call.getString("value");
    if (value == null) {
        call.reject("Value is required");
        return;
    }
    
    // 平台特定实现
    JSObject ret = new JSObject();
    ret.put("result", "Android specific result");
    call.resolve(ret);
}
```

## 方法参数处理

### 参数验证

```typescript
interface MethodOptions {
    required: string;
    optional?: number;
}

@PluginMethod()
async validateMethod(options: MethodOptions) {
    if (!options.required) {
        throw new Error('Required parameter missing');
    }
    
    const optionalValue = options.optional ?? 0;
    // 继续处理
}
```

### 类型转换

```typescript
@PluginMethod()
async convertTypes(options: any) {
    const number = parseInt(options.numberString, 10);
    const boolean = Boolean(options.boolValue);
    const array = Array.isArray(options.arrayData) ? options.arrayData : [];
    
    return { number, boolean, array };
}
```

## 错误处理

### 错误类型

```typescript
enum PluginError {
    INVALID_PARAMETER = 'INVALID_PARAMETER',
    NETWORK_ERROR = 'NETWORK_ERROR',
    PERMISSION_DENIED = 'PERMISSION_DENIED'
}

interface ErrorResponse {
    code: PluginError;
    message: string;
    details?: any;
}
```

### 错误处理示例

```typescript
@PluginMethod()
async handleErrors(options: any): Promise<void> {
    try {
        // 可能抛出错误的代码
        if (!options.valid) {
            throw new Error('Invalid options');
        }
    } catch (error) {
        throw {
            code: PluginError.INVALID_PARAMETER,
            message: error.message,
            details: error
        };
    }
}
```

## 最佳实践总结

1. 方法命名
   - 使用清晰的动词开头
   - 表明操作的目的
   - 遵循平台命名约定

2. 参数设计
   - 使用明确的类型定义
   - 提供合理的默认值
   - 验证必要参数

3. 返回值
   - 保持一致的格式
   - 包含必要的状态信息
   - 提供详细的错误信息

4. 文档
   - 详细的参数说明
   - 返回值格式
   - 使用示例
   - 错误处理说明

## 下一步

- 了解[配置值](./configuration-values.md)的使用
- 探索[插件钩子](./plugin-hooks.md)的应用
- 查看完整的[插件示例](./examples.md) 