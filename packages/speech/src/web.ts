import { WebPlugin } from '@capacitor/core';

import type { OukekSpeech as OukekSpeechPlugin } from './definitions';

export class OukekSpeechWeb extends WebPlugin implements OukekSpeechPlugin {
  constructor() {
    super();
  }

  async startRecording(): Promise<void> {
    try {
      // 检查浏览器是否支持 Web Speech API
      if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
        throw new Error('Speech recognition is not supported in this browser');
      }
      
    } catch (error) {
      throw error;
    }
  }

  async stopRecording(): Promise<{audioBase64: string}> {
    try {
      // Web 平台暂不支持获取原始音频数据
      // 返回空字符串作为占位符
      return { audioBase64: '' };
    } catch (error) {
      throw error;
    }
  }

  async recognize(_options: { audioBase64: string; locale?: string }): Promise<{text: string}> {
    try {
      // Web 平台使用 Web Speech API 进行实时识别
      // 由于浏览器限制，不支持从音频数据中识别
      throw new Error('Speech recognition from audio data is not supported in web platform');
    } catch (error) {
      throw error;
    }
  }
}
