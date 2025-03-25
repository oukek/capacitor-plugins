import { WebPlugin } from '@capacitor/core';

import type { 
  OukekClipboard as OukekClipboardPlugin,
  ClipboardReadOptions,
  ClipboardReadResult,
  ClipboardWriteOptions,
  ClipboardWriteResult
} from './definitions';

export class OukekClipboardWeb extends WebPlugin implements OukekClipboardPlugin {
  private changeCount = 0;

  constructor() {
    super();
  }

  async getChangeCount(): Promise<{ count: number }> {
    return { count: this.changeCount };
  }

  async read(options?: ClipboardReadOptions): Promise<ClipboardReadResult> {
    const format = options?.format || '';
    const result: ClipboardReadResult = {
      changeCount: this.changeCount,
    };

    try {
      // 尝试读取剪贴板内容
      if (navigator.clipboard) {
        if (format === '' || format === 'string' || format === 'all') {
          try {
            const text = await navigator.clipboard.readText();
            if (text) {
              result.text = text;
            }
          } catch (e) {
            console.warn('无法读取剪贴板文本:', e);
          }
        }

        // Web API 限制无法读取图片和URL，只有通过paste事件才能获取
        if (format === 'image' || format === 'url') {
          console.warn('Web平台上无法直接读取剪贴板中的图片或URL');
        }
      } else {
        throw new Error('Clipboard API not available');
      }
    } catch (e) {
      console.error('读取剪贴板时出错:', e);
    }

    return result;
  }

  async write(options: ClipboardWriteOptions): Promise<ClipboardWriteResult> {
    if (!navigator.clipboard) {
      return {
        success: false,
        message: 'Clipboard API not available',
        changeCount: this.changeCount
      };
    }

    try {
      if (options.text) {
        await navigator.clipboard.writeText(options.text);
        this.changeCount++;
        return {
          success: true,
          message: 'Text written to clipboard',
          changeCount: this.changeCount
        };
      }

      if (options.url) {
        await navigator.clipboard.writeText(options.url);
        this.changeCount++;
        return {
          success: true,
          message: 'URL written to clipboard',
          changeCount: this.changeCount
        };
      }

      if (options.image) {
        try {
          // 尝试将Base64图片转换为Blob
          const byteString = atob(options.image.split(',')[1]);
          const mimeString = options.image.split(',')[0].split(':')[1].split(';')[0];
          const ab = new ArrayBuffer(byteString.length);
          const ia = new Uint8Array(ab);
          
          for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
          }
          
          const blob = new Blob([ab], { type: mimeString });
          
          // 检查是否支持writeBlob API
          if ('write' in navigator.clipboard) {
            // @ts-ignore - 标准中未定义但某些浏览器支持
            await navigator.clipboard.write([
              new ClipboardItem({
                [blob.type]: blob
              })
            ]);
            this.changeCount++;
            return {
              success: true,
              message: 'Image written to clipboard',
              changeCount: this.changeCount
            };
          } else {
            return {
              success: false,
              message: 'Writing images to clipboard is not supported in this browser',
              changeCount: this.changeCount
            };
          }
        } catch (e) {
          console.error('写入图片到剪贴板时出错:', e);
          return {
            success: false,
            message: 'Failed to write image to clipboard',
            changeCount: this.changeCount
          };
        }
      }

      return {
        success: false,
        message: 'No valid data provided to write to clipboard',
        changeCount: this.changeCount
      };
    } catch (e) {
      return {
        success: false,
        message: `Failed to write to clipboard`,
        changeCount: this.changeCount
      };
    }
  }

  async clear(): Promise<ClipboardWriteResult> {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      try {
        await navigator.clipboard.writeText('');
        this.changeCount++;
        return {
          success: true,
          message: 'Clipboard cleared',
          changeCount: this.changeCount
        };
      } catch (e) {
        return {
          success: false,
          message: `Failed to clear clipboard`,
          changeCount: this.changeCount
        };
      }
    }

    return {
      success: false,
      message: 'Clipboard API not available',
      changeCount: this.changeCount
    };
  }
}