# uu-photo-plugin

相册相关插件

## Install

```bash
npm install uu-photo-plugin
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`saveImageToAlbum(...)`](#saveimagetoalbum)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => any
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>any</code>

--------------------


### saveImageToAlbum(...)

```typescript
saveImageToAlbum(options: { base64Data: string; }) => any
```

Save base64 image data to photo album

| Param         | Type                                 | Description                  |
| ------------- | ------------------------------------ | ---------------------------- |
| **`options`** | <code>{ base64Data: string; }</code> | The options for saving image |

**Returns:** <code>any</code>

--------------------

</docgen-api>
