# 创建 Capacitor 插件

本指南将帮助你了解如何创建一个新的 Capacitor 插件。

## 创建新插件

要创建一个新的 Capacitor 插件，你可以使用以下命令：

```bash
npm init @capacitor/plugin
```

这个命令会引导你完成插件创建过程，包括：
- 设置插件名称
- 设置包名
- 选择支持的平台
- 配置其他选项

## 插件结构

一个典型的 Capacitor 插件包含以下文件结构：

```
my-plugin/
├── android/                    // Android 平台代码
├── ios/                       // iOS 平台代码
├── src/                       // TypeScript/JavaScript 代码
│   ├── definitions.ts         // 类型定义
│   ├── index.ts              // 主入口文件
│   └── web.ts                // Web 实现
├── package.json
└── README.md
```

## 实现插件接口

### 1. 定义插件接口

在 `src/definitions.ts` 中定义你的插件接口：

```typescript
export interface MyPluginPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  // 添加其他方法定义
}
```

### 2. 实现 Web 版本

在 `src/web.ts` 中实现 Web 平台的功能：

```typescript
import { WebPlugin } from '@capacitor/core';
import type { MyPluginPlugin } from './definitions';

export class MyPluginWeb extends WebPlugin implements MyPluginPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    return options;
  }
}
```

## 平台特定实现

### iOS 实现

在 iOS 平台上，你需要在 `ios/Plugin/Plugin.swift` 中实现原生功能：

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

### Android 实现

在 Android 平台上，你需要在 `android/src/main/java/.../Plugin.java` 中实现原生功能：

```java
@NativePlugin
public class MyPlugin extends Plugin {
    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value");
        JSObject ret = new JSObject();
        ret.put("value", value);
        call.resolve(ret);
    }
}
```

## 测试你的插件

1. 在插件目录中运行测试：
```bash
npm run test
```

2. 在示例应用中测试：
```bash
npm run build
cd example
npm run start
```

## 发布插件

1. 更新版本号：
```bash
npm version patch
```

2. 发布到 npm：
```bash
npm publish
```

## 最佳实践

1. **错误处理**
   - 始终提供有意义的错误消息
   - 使用适当的错误代码
   - 处理所有边缘情况

2. **文档**
   - 提供详细的 API 文档
   - 包含使用示例
   - 说明所有配置选项

3. **类型安全**
   - 使用 TypeScript 定义接口
   - 提供完整的类型定义
   - 验证所有输入参数

4. **平台兼容性**
   - 明确指出平台特定的功能
   - 提供优雅的降级方案
   - 测试所有支持的平台

## 常见问题

1. **插件不工作？**
   - 检查平台特定的设置
   - 验证权限配置
   - 查看控制台错误日志

2. **性能问题？**
   - 最小化原生桥接调用
   - 批处理操作
   - 使用适当的缓存策略

## 下一步

- 查看[插件工作流](./plugin-workflow.md)了解更多关于插件开发流程的信息
- 探索[方法类型](./method-types.md)以了解不同类型的插件方法
- 学习如何使用[配置值](./configuration-values.md)来自定义插件行为 