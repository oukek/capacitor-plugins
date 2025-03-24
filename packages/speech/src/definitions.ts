export interface OukekSpeech {
  /**
   * 开始录音
   * @returns Promise<void>
   */
  startRecording(): Promise<void>;

  /**
   * 停止录音
   * @returns Promise<{audioBase64: string}> base64编码的音频数据
   */
  stopRecording(): Promise<{audioBase64: string}>;

  /**
   * 识别语音
   * @param options 包含base64编码的音频数据和可选的语言设置
   * @returns Promise<{text: string}> 识别结果文本
   */
  recognize(options: { audioBase64: string; locale?: string }): Promise<{text: string}>;
}
