# @oukek/capacitor-updater

检测 appstore 更新版本

## Install

```bash
npm install @oukek/capacitor-updater
npx cap sync
```

## API

<docgen-index>

* [`getCurrentVersion()`](#getcurrentversion)
* [`getStoreVersion(...)`](#getstoreversion)
* [`openAppStore(...)`](#openappstore)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### getCurrentVersion()

```typescript
getCurrentVersion() => Promise<{ version: string; build: string; }>
```

获取当前安装的应用版本号

**Returns:** <code>Promise&lt;{ version: string; build: string; }&gt;</code>

--------------------


### getStoreVersion(...)

```typescript
getStoreVersion(options?: { appId?: string | undefined; } | undefined) => Promise<{ version: string; releaseNotes?: string; }>
```

获取 App Store 上的最新版本号

| Param         | Type                             | Description     |
| ------------- | -------------------------------- | --------------- |
| **`options`** | <code>{ appId?: string; }</code> | 可选参数，可以指定 appId |

**Returns:** <code>Promise&lt;{ version: string; releaseNotes?: string; }&gt;</code>

--------------------


### openAppStore(...)

```typescript
openAppStore(options?: { appId?: string | undefined; } | undefined) => Promise<void>
```

跳转到 App Store 的应用下载页面

| Param         | Type                             | Description     |
| ------------- | -------------------------------- | --------------- |
| **`options`** | <code>{ appId?: string; }</code> | 可选参数，可以指定 appId |

--------------------

</docgen-api>
