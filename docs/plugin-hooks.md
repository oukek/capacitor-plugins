# Capacitor 插件钩子

本文档详细介绍了 Capacitor 插件中可用的各种钩子及其使用方法。

## 钩子概述

插件钩子是在特定生命周期事件发生时执行的方法。Capacitor 提供了多个钩子点：

1. 初始化钩子
2. 生命周期钩子
3. 权限钩子
4. 事件钩子

## 初始化钩子

### load()

在插件初始化时调用。

```typescript
@Plugin({
    name: 'MyPlugin'
})
export class MyPlugin implements PluginInterface {
    async load() {
        // 执行初始化逻辑
        await this.initialize();
        console.log('Plugin loaded');
    }
}
```

### initialize()

用于执行异步初始化操作。

```typescript
private async initialize() {
    try {
        await this.checkPermissions();
        await this.loadConfiguration();
        await this.setupEventListeners();
    } catch (error) {
        console.error('初始化失败:', error);
    }
}
```

## 生命周期钩子

### addListener()

用于添加事件监听器。

```typescript
@Plugin({
    name: 'MyPlugin'
})
export class MyPlugin implements PluginInterface {
    @PluginMethod()
    addListener(eventName: string, callback: Function) {
        const listener = (event: any) => {
            callback(event);
        };
        
        // 存储监听器引用
        this.listeners[eventName] = listener;
        
        return {
            remove: () => {
                delete this.listeners[eventName];
            }
        };
    }
}
```

### removeListener()

用于移除事件监听器。

```typescript
@PluginMethod()
removeListener(eventName: string) {
    if (this.listeners[eventName]) {
        delete this.listeners[eventName];
        return true;
    }
    return false;
}
```

## 平台特定钩子

### iOS

```swift
@objc(MyPlugin)
public class MyPlugin: CAPPlugin {
    override public func load() {
        // 初始化代码
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc func handleAppDidBecomeActive() {
        // 处理应用程序激活事件
        notifyListeners("appActive", data: [:])
    }
    
    override public func applicationDidBecomeActive() {
        // 应用程序激活时的处理
    }
    
    override public func applicationWillResignActive() {
        // 应用程序即将进入后台时的处理
    }
}
```

### Android

```java
@NativePlugin
public class MyPlugin extends Plugin {
    @Override
    public void load() {
        // 初始化代码
    }
    
    @Override
    protected void handleOnStart() {
        // Activity onStart
        super.handleOnStart();
    }
    
    @Override
    protected void handleOnResume() {
        // Activity onResume
        super.handleOnResume();
    }
    
    @Override
    protected void handleOnPause() {
        // Activity onPause
        super.handleOnPause();
    }
}
```

## 权限钩子

### checkPermissions()

检查所需权限的状态。

```typescript
@Plugin({
    name: 'MyPlugin',
    permissions: {
        camera: {
            ios: "相机访问权限",
            android: "android.permission.CAMERA"
        }
    }
})
export class MyPlugin implements PluginInterface {
    @PluginMethod()
    async checkPermissions(): Promise<PermissionStatus> {
        return {
            camera: await this.getCameraPermissionStatus()
        };
    }
}
```

### requestPermissions()

请求所需的权限。

```typescript
@PluginMethod()
async requestPermissions(): Promise<PermissionStatus> {
    try {
        const status = await this.requestCameraPermission();
        return { camera: status };
    } catch (error) {
        throw new Error('权限请求失败');
    }
}
```

## 事件钩子

### notifyListeners()

向 JavaScript 发送事件。

```typescript
private sendUpdate(data: any) {
    this.notifyListeners('update', {
        data: data,
        timestamp: new Date().toISOString()
    });
}
```

### removeAllListeners()

移除所有事件监听器。

```typescript
@PluginMethod()
removeAllListeners() {
    this.listeners = {};
    return Promise.resolve();
}
```

## 状态管理钩子

### 保存状态

```typescript
private async saveState(state: any) {
    try {
        await this.setStorage('pluginState', JSON.stringify(state));
    } catch (error) {
        console.error('状态保存失败:', error);
    }
}
```

### 恢复状态

```typescript
private async restoreState(): Promise<any> {
    try {
        const state = await this.getStorage('pluginState');
        return state ? JSON.parse(state) : null;
    } catch (error) {
        console.error('状态恢复失败:', error);
        return null;
    }
}
```

## 最佳实践

### 1. 错误处理

```typescript
private handleError(error: Error, methodName: string) {
    console.error(`[${methodName}] 错误:`, error);
    this.notifyListeners('error', {
        method: methodName,
        message: error.message
    });
}
```

### 2. 资源清理

```typescript
private cleanup() {
    // 移除所有监听器
    this.removeAllListeners();
    
    // 清理其他资源
    this.disposeResources();
    
    // 重置状态
    this.resetState();
}
```

### 3. 性能优化

```typescript
private debounceEvent(eventName: string, data: any, delay: number = 300) {
    if (this.debounceTimers[eventName]) {
        clearTimeout(this.debounceTimers[eventName]);
    }
    
    this.debounceTimers[eventName] = setTimeout(() => {
        this.notifyListeners(eventName, data);
    }, delay);
}
```

## 调试技巧

### 1. 日志记录

```typescript
private log(level: string, message: string, data?: any) {
    if (this.config.debug) {
        console.log(`[${level}] ${message}`, data);
        this.notifyListeners('debug', {
            level,
            message,
            data
        });
    }
}
```

### 2. 状态追踪

```typescript
private trackState(action: string, prevState: any, nextState: any) {
    this.log('state', `${action}:`, {
        prev: prevState,
        next: nextState,
        diff: this.getStateDiff(prevState, nextState)
    });
}
```

## 常见问题

### 1. 钩子不触发

- 检查注册是否正确
- 验证事件名称
- 确认监听器是否活跃

### 2. 内存泄漏

- 及时移除监听器
- 清理定时器
- 释放资源

### 3. 性能问题

- 使用防抖/节流
- 优化事件处理
- 避免过度通知

## 下一步

- 查看完整的[插件示例](./examples.md)
- 了解[调试指南](./debugging.md)
- 探索[API 参考](./api-reference.md) 