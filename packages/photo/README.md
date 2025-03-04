# @oukek/capacitor-photo

相册相关插件

## Install

```bash
npm install @oukek/capacitor-photo
npx cap sync
```

## iOS 权限配置

在 iOS 平台上使用此插件需要在 `Info.plist` 文件中添加以下权限：

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问您的相册以保存图片</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问您的相册以保存图片</string>
```

## API

<docgen-index>

* [`saveImageToAlbum(...)`](#saveimagetoalbum)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### saveImageToAlbum(...)

```typescript
saveImageToAlbum(options: { base64Data: string; }) => Promise<{ success: boolean; }>
```

Save base64 image data to photo album

| Param         | Type                                 | Description                  |
| ------------- | ------------------------------------ | ---------------------------- |
| **`options`** | <code>{ base64Data: string; }</code> | The options for saving image |

**Returns:** <code>Promise&lt;{ success: boolean; }&gt;</code>

--------------------

</docgen-api>
