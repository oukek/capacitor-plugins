# @oukek/capacitor-speech

录音和语音识别

## Install

```bash
npm install @oukek/capacitor-speech
npx cap sync
```

## iOS 权限配置

在 iOS 平台上使用此插件需要在 `Info.plist` 文件中添加以下权限：

```xml
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>用于语音识别的权限</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>用于录音的权限</string>
```

## API

<docgen-index>

* [`startRecording()`](#startrecording)
* [`stopRecording()`](#stoprecording)
* [`recognize(...)`](#recognize)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startRecording()

```typescript
startRecording() => Promise<void>
```

开始录音

--------------------


### stopRecording()

```typescript
stopRecording() => Promise<{ audioBase64: string; }>
```

停止录音

**Returns:** <code>Promise&lt;{ audioBase64: string; }&gt;</code>

--------------------


### recognize(...)

```typescript
recognize(options: { audioBase64: string; locale?: string; }) => Promise<{ text: string; }>
```

识别语音

| Param         | Type                                                   | Description             |
| ------------- | ------------------------------------------------------ | ----------------------- |
| **`options`** | <code>{ audioBase64: string; locale?: string; }</code> | 包含base64编码的音频数据和可选的语言设置 |

**Returns:** <code>Promise&lt;{ text: string; }&gt;</code>

--------------------

</docgen-api>
