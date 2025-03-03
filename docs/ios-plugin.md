# iOS 插件开发指南

本文档详细介绍了如何为 Capacitor 开发 iOS 插件。

## 环境设置

### 前提条件

- macOS 操作系统
- Xcode 12 或更高版本
- CocoaPods
- Node.js 和 npm

### 开发工具

- Xcode：主要的 iOS 开发 IDE
- Swift：推荐的开发语言
- CocoaPods：依赖管理工具

## 插件结构

iOS 插件的标准目录结构：

```
ios/
├── Plugin/
│   ├── Plugin.swift           // 主要插件实现
│   ├── Plugin.m              // Objective-C 桥接
│   └── Plugin.h              // 头文件
├── PluginTests/              // 单元测试
└── Podfile                   // CocoaPods 配置
```

## 插件实现

### 1. 基本结构

```swift
@objc(MyPlugin)
public class MyPlugin: CAPPlugin {
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": value
        ])
    }
}
```

### 2. 方法装饰器

- `@objc`: 暴露方法给 Objective-C 运行时
- `@objc(MyPlugin)`: 指定 Objective-C 类名
- `@available`: 指定 iOS 版本兼容性

### 3. 参数处理

```swift
// 获取参数
let value = call.getString("value")
let number = call.getInt("number")
let flag = call.getBool("flag")
let object = call.getObject("object")
let array = call.getArray("array")

// 可选参数处理
if let value = call.getString("value") {
    // 处理值存在的情况
} else {
    // 处理值不存在的情况
}
```

### 4. 返回结果

```swift
// 成功响应
call.resolve([
    "value": result
])

// 错误响应
call.reject("错误信息", "错误代码", error)
```

## 高级特性

### 1. 权限处理

```swift
// 请求权限
func requestPermission(_ call: CAPPluginCall) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
            call.resolve()
        } else {
            call.reject("未授予权限")
        }
    }
}
```

### 2. 后台任务

```swift
// 注册后台任务
@objc func startBackgroundTask(_ call: CAPPluginCall) {
    let taskID = UIApplication.shared.beginBackgroundTask {
        // 清理代码
    }
    
    // 执行后台任务
    DispatchQueue.global(qos: .background).async {
        // 异步任务
        UIApplication.shared.endBackgroundTask(taskID)
    }
}
```

### 3. 事件监听

```swift
// 发送事件到 JavaScript
self.notifyListeners("eventName", data: [
    "key": "value"
])

// 移除监听器
self.removeAllListeners()
```

## 最佳实践

### 1. 错误处理

```swift
enum PluginError: Error {
    case invalidInput
    case networkError
    case unknown
}

func handleError(_ error: PluginError, _ call: CAPPluginCall) {
    switch error {
    case .invalidInput:
        call.reject("无效输入")
    case .networkError:
        call.reject("网络错误")
    case .unknown:
        call.reject("未知错误")
    }
}
```

### 2. 线程管理

```swift
// 主线程执行 UI 操作
DispatchQueue.main.async {
    // UI 更新代码
}

// 后台线程执行耗时操作
DispatchQueue.global(qos: .background).async {
    // 耗时操作
    DispatchQueue.main.async {
        // 更新 UI
    }
}
```

### 3. 内存管理

```swift
// 使用 weak self 避免循环引用
weak var weakSelf = self
someOperation { [weak self] result in
    guard let self = self else { return }
    // 处理结果
}
```

## 调试技巧

### 1. 日志记录

```swift
// 使用 print 进行基本日志记录
print("Debug: \(message)")

// 使用 os_log 进行高级日志记录
import os.log
os_log("Error: %@", log: .default, type: .error, errorMessage)
```

### 2. 断点调试

- 使用 Xcode 断点
- 使用 LLDB 调试命令
- 检查变量状态

### 3. 性能分析

- 使用 Instruments 进行性能分析
- 监控内存使用
- 检查 CPU 使用率

## 测试

### 1. 单元测试

```swift
import XCTest
@testable import Plugin

class PluginTests: XCTestCase {
    var plugin: MyPlugin!
    
    override func setUp() {
        super.setUp()
        plugin = MyPlugin()
    }
    
    func testEcho() {
        // 测试代码
    }
}
```

### 2. 集成测试

- 测试与 Capacitor 框架的集成
- 测试与其他插件的交互
- 测试真机环境

## 发布和维护

### 1. 版本控制

- 遵循语义化版本
- 更新 podspec 文件
- 更新文档

### 2. 发布检查清单

- 运行所有测试
- 检查兼容性
- 更新示例代码
- 更新 README

## 常见问题

### 1. 权限问题

- 确保在 Info.plist 中添加必要的权限描述
- 正确处理权限请求回调
- 提供用户友好的权限说明

### 2. 内存问题

- 避免循环引用
- 及时释放资源
- 使用 Instruments 检测内存泄漏

### 3. 线程问题

- UI 操作在主线程执行
- 耗时操作在后台线程执行
- 正确处理异步回调

## 下一步

- 了解[方法类型](./method-types.md)的使用方式
- 探索[配置值](./configuration-values.md)的管理
- 学习[插件钩子](./plugin-hooks.md)的应用 