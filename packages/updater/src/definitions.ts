export interface OukekUpdater {
  /**
   * 获取当前安装的应用版本号
   * @returns 返回当前应用的版本号和构建号
   */
  getCurrentVersion(): Promise<{ version: string; build: string }>;

  /**
   * 获取 App Store 上的最新版本号
   * @param options 可选参数，可以指定 appId
   * @returns 返回最新版本号、App Store 链接和更新内容
   */
  getStoreVersion(options?: { appId?: string }): Promise<{ 
    version: string; 
    releaseNotes?: string;
  }>;

  /**
   * 跳转到 App Store 的应用下载页面
   * @param options 可选参数，可以指定 appId
   * @returns 无返回值
   */
  openAppStore(options?: { appId?: string }): Promise<void>;
}