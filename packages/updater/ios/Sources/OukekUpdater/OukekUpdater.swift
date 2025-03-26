import Foundation
import Capacitor
import UIKit
import StoreKit

/**
 * OukekUpdater for handling updater operations
 */
@objc(OukekUpdater)
public class OukekUpdater: CAPPlugin {
    private var appStoreId: String? = nil
    
    override public func load() {
        // 插件加载时的初始化
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppLaunch),
                                            name: UIApplication.didFinishLaunchingNotification,
                                            object: nil)
        
        // 从配置中读取App Store ID
        if let appId = getConfigValue("appStoreId") as? String {
            self.appStoreId = appId
        }
    }
    
    @objc func handleAppLaunch() {
        // 应用启动时的处理逻辑
    }
    
    /**
     * 获取当前安装的应用版本号
     */
    @objc func getCurrentVersion(_ call: CAPPluginCall) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
        call.resolve([
            "version": version,
            "build": build
        ])
    }
    
    /**
     * 获取App Store上的最新版本
     */
    @objc func getStoreVersion(_ call: CAPPluginCall) {
        guard let appId = call.getString("appId") ?? self.appStoreId else {
            call.reject("未设置应用的App Store ID")
            return
        }
        
        let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)")!
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                self.bridge?.viewController?.view?.isUserInteractionEnabled = true
                call.reject("获取App Store版本失败: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                self.bridge?.viewController?.view?.isUserInteractionEnabled = true
                call.reject("没有接收到数据")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appInfo = results.first,
                   let version = appInfo["version"] as? String {
                    
                    var response: [String: Any] = [
                        "version": version,
                    ]
                    
                    // 添加更新内容
                    if let releaseNotes = appInfo["releaseNotes"] as? String {
                        response["releaseNotes"] = releaseNotes
                    }
                    
                    call.resolve(response)
                } else {
                    call.reject("无法解析App Store数据")
                }
            } catch {
                call.reject("解析App Store数据时出错: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /**
     * 跳转到App Store更新页面
     */
    @objc func openAppStore(_ call: CAPPluginCall) {
        guard let appId = call.getString("appId") ?? self.appStoreId else {
            call.reject("未设置应用的App Store ID")
            return
        }
        
        let urlString = "itms-apps://itunes.apple.com/app/id\(appId)"
        guard let url = URL(string: urlString) else {
            call.reject("无法创建App Store URL")
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    call.resolve()
                } else {
                    call.reject("无法打开App Store")
                }
            }
        }
    }
}