# uu-photo-plugin

相册相关插件

## Install

```bash
npm install uu-photo-plugin
npx cap sync
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
