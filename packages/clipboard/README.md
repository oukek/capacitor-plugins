# @oukek/capacitor-clipboard

剪切板相关

## Install

```bash
npm install @oukek/capacitor-clipboard
npx cap sync
```

## API

<docgen-index>

* [`getChangeCount()`](#getchangecount)
* [`read(...)`](#read)
* [`write(...)`](#write)
* [`clear()`](#clear)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### getChangeCount()

```typescript
getChangeCount() => Promise<{ count: number; }>
```

获取剪切板变更计数，可用于检测剪切板内容是否变化

**Returns:** <code>Promise&lt;{ count: number; }&gt;</code>

--------------------


### read(...)

```typescript
read(options?: ClipboardReadOptions | undefined) => Promise<ClipboardReadResult>
```

读取剪切板内容

| Param         | Type                                                                  | Description |
| ------------- | --------------------------------------------------------------------- | ----------- |
| **`options`** | <code><a href="#clipboardreadoptions">ClipboardReadOptions</a></code> | 读取选项        |

**Returns:** <code>Promise&lt;<a href="#clipboardreadresult">ClipboardReadResult</a>&gt;</code>

--------------------


### write(...)

```typescript
write(options: ClipboardWriteOptions) => Promise<ClipboardWriteResult>
```

写入内容到剪切板

| Param         | Type                                                                    | Description |
| ------------- | ----------------------------------------------------------------------- | ----------- |
| **`options`** | <code><a href="#clipboardwriteoptions">ClipboardWriteOptions</a></code> | 写入选项        |

**Returns:** <code>Promise&lt;<a href="#clipboardwriteresult">ClipboardWriteResult</a>&gt;</code>

--------------------


### clear()

```typescript
clear() => Promise<ClipboardWriteResult>
```

清空剪切板

**Returns:** <code>Promise&lt;<a href="#clipboardwriteresult">ClipboardWriteResult</a>&gt;</code>

--------------------


### Interfaces


#### ClipboardReadResult

| Prop              | Type                | Description            |
| ----------------- | ------------------- | ---------------------- |
| **`changeCount`** | <code>number</code> | 剪切板变更计数                |
| **`text`**        | <code>string</code> | 剪切板中的文本（如果有）           |
| **`url`**         | <code>string</code> | 剪切板中的URL（如果有）          |
| **`image`**       | <code>string</code> | 剪切板中的图片，以Base64编码（如果有） |
| **`items`**       | <code>any[]</code>  | 剪切板中的所有项目，包含所有类型       |


#### ClipboardReadOptions

| Prop         | Type                | Description                                                   |
| ------------ | ------------------- | ------------------------------------------------------------- |
| **`format`** | <code>string</code> | 指定要读取的数据格式: 'string', 'url', 'image', 'all' 如果不指定，会尝试读取所有可用格式 |


#### ClipboardWriteResult

| Prop              | Type                 | Description |
| ----------------- | -------------------- | ----------- |
| **`success`**     | <code>boolean</code> | 操作是否成功      |
| **`message`**     | <code>string</code>  | 操作结果消息      |
| **`changeCount`** | <code>number</code>  | 剪切板变更计数     |


#### ClipboardWriteOptions

| Prop        | Type                | Description         |
| ----------- | ------------------- | ------------------- |
| **`text`**  | <code>string</code> | 要写入剪切板的文本           |
| **`url`**   | <code>string</code> | 要写入剪切板的URL          |
| **`image`** | <code>string</code> | 要写入剪切板的图片（Base64编码） |

</docgen-api>
