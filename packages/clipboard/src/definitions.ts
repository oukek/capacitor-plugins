export interface ClipboardReadOptions {
  /**
   * 指定要读取的数据格式: 'string', 'url', 'image', 'all'
   * 如果不指定，会尝试读取所有可用格式
   */
  format?: string;
}

export interface ClipboardReadResult {
  /**
   * 剪切板变更计数
   */
  changeCount: number;

  /**
   * 剪切板中的文本（如果有）
   */
  text?: string;

  /**
   * 剪切板中的URL（如果有）
   */
  url?: string;

  /**
   * 剪切板中的图片，以Base64编码（如果有）
   */
  image?: string;

  /**
   * 剪切板中的所有项目，包含所有类型
   */
  items?: any[];
}

export interface ClipboardWriteOptions {
  /**
   * 要写入剪切板的文本
   */
  text?: string;

  /**
   * 要写入剪切板的URL
   */
  url?: string;

  /**
   * 要写入剪切板的图片（Base64编码）
   */
  image?: string;
}

export interface ClipboardWriteResult {
  /**
   * 操作是否成功
   */
  success: boolean;

  /**
   * 操作结果消息
   */
  message: string;

  /**
   * 剪切板变更计数
   */
  changeCount?: number;
}

export interface OukekClipboard {
  /**
   * 获取剪切板变更计数，可用于检测剪切板内容是否变化
   */
  getChangeCount(): Promise<{ count: number }>;

  /**
   * 读取剪切板内容
   * @param options 读取选项
   */
  read(options?: ClipboardReadOptions): Promise<ClipboardReadResult>;

  /**
   * 写入内容到剪切板
   * @param options 写入选项
   */
  write(options: ClipboardWriteOptions): Promise<ClipboardWriteResult>;

  /**
   * 清空剪切板
   */
  clear(): Promise<ClipboardWriteResult>;
}