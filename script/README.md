# 插件开发工具

本目录包含用于 Capacitor 插件开发的辅助工具。

## 创建新插件

使用 `create-plugin.js` 脚本可以基于模板快速创建新的插件。

### 使用方法

```bash
# 运行交互式创建插件脚本
node script/create-plugin.js
```

或者：

```bash
# 直接执行脚本
./script/create-plugin.js
```

### 交互式输入

脚本运行后会提示您输入：

1. **插件名称**：使用短横线分隔命名方式 (kebab-case)，例如 `my-plugin`、`device-info` 等
2. **插件描述**：对插件功能的简短描述，将自动更新到 README.md 和 package.json 中

### 脚本功能

1. 将 `pluginTpl` 目录复制到 `packages/[插件名]` 目录
2. 根据提供的插件名称，替换所有文件内容中的名称引用
3. 重命名包含 `Clipboard` 的文件和目录
4. 使用提供的描述更新 README.md 和 package.json 文件
5. 在根目录的 README.md 文件的「插件列表」部分添加新插件信息，以表格形式展示（包含名称、描述和版本号）

### 表格转换功能

脚本会自动检测根目录的 README.md 文件中「插件列表」部分的格式：

- 如果已经是表格格式，则直接添加新行
- 如果是旧的列表格式，则会自动转换为表格格式，并保留所有现有插件信息
- 表格包含三列：插件名称、描述和版本号

### 示例

运行脚本后：

```
请输入插件名称 (例如 my-plugin): device-info
请输入插件描述: 用于获取设备信息的 Capacitor 插件
```

将会：
- 创建 `packages/device-info` 目录
- 替换所有 `clipboard` 为 `device-info`
- 替换所有 `Clipboard` 为 `DeviceInfo`
- 替换所有 `OukekClipboard` 为 `OukekDeviceInfo`
- 替换所有 `OukekCapacitorClipboard` 为 `OukekCapacitorDeviceInfo`
- 重命名相关文件和目录
- 更新 README.md 和 package.json 中的描述为 "用于获取设备信息的 Capacitor 插件"
- 在根目录的 README.md 文件中添加新插件到表格中：

```
| 插件名称 | 描述 | 版本 |
| --- | --- | --- |
| [@oukek/capacitor-photo](./packages/photo/README.md) | 相册相关功能的 Capacitor 插件 | 1.0.0 |
| [@oukek/capacitor-device-info](./packages/device-info/README.md) | 用于获取设备信息的 Capacitor 插件 | 0.1.0 |
```

## 更新插件列表

使用 `update-readme.js` 脚本可以一键更新根目录 README.md 文件中的插件列表表格。

### 使用方法

```bash
# 运行更新脚本
node script/update-readme.js
```

或者：

```bash
# 直接执行脚本
./script/update-readme.js
```

### 脚本功能

1. 自动扫描 `packages` 目录下的所有插件
2. 从每个插件的 package.json 文件中读取名称、描述和版本信息
3. 按字母顺序排列插件
4. 更新根目录 README.md 文件中的插件列表表格

### 示例输出

脚本执行后，会在控制台输出更新结果：

```
开始更新根目录 README.md 中的插件列表...
更新成功! 已找到并更新了 5 个插件的信息。

更新后的插件列表:
| 插件名称 | 描述 | 版本 |
| --- | --- | --- |
| [@oukek/capacitor-clipboard](./packages/clipboard/README.md) | 剪贴板相关插件 | 1.0.0 |
| [@oukek/capacitor-pay](./packages/pay/README.md) | 支付相关插件 | 1.0.0 |
| [@oukek/capacitor-photo](./packages/photo/README.md) | 相册相关插件 | 1.0.1 |
| [@oukek/capacitor-speech](./packages/speech/README.md) | 语音相关插件 | 2.0.0 |
| [@oukek/capacitor-updater](./packages/updater/README.md) | 检测 appstore 更新版本 | 0.0.0 |
``` 