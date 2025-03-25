import Foundation
import Capacitor
import UIKit

/**
 * OukekClipboard for handling clipboard operations
 */
@objc(OukekClipboard)
public class OukekClipboard: CAPPlugin {
    
    override public func load() {
        // 插件加载时的初始化
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppLaunch),
                                            name: UIApplication.didFinishLaunchingNotification,
                                            object: nil)
    }
    
    // 获取剪切板变更计数
    @objc func getChangeCount(_ call: CAPPluginCall) {
        let pasteboard = UIPasteboard.general
        let changeCount = pasteboard.changeCount
        
        call.resolve([
            "count": changeCount
        ])
    }
    
    // 读取剪切板内容
    @objc func read(_ call: CAPPluginCall) {
        let pasteboard = UIPasteboard.general
        let format = call.getString("format", "")
        
        let result = NSMutableDictionary()
        
        // 添加变更计数到结果中
        result["changeCount"] = pasteboard.changeCount
        
        // 根据指定格式读取数据
        if format.isEmpty || format == "string" {
            if let text = pasteboard.string {
                result["text"] = text
            }
        }
        
        if format.isEmpty || format == "url" {
            if let url = pasteboard.url?.absoluteString {
                result["url"] = url
            }
        }
        
        if format.isEmpty || format == "image" {
            if let image = pasteboard.image {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    result["image"] = imageData.base64EncodedString()
                }
            }
        }
        
        // 读取所有可用数据
        if format.isEmpty || format == "all" {
            let pasteboardItems = pasteboard.items
            var items = [[String: Any]]()
            
            for item in pasteboardItems {
                var itemDict = [String: Any]()
                
                for (type, value) in item {
                    itemDict[type] = String(describing: value)
                }
                
                items.append(itemDict)
            }
            
            result["items"] = items
        }
        
        call.resolve(result as! [String: Any])
    }
    
    // 写入剪切板
    @objc func write(_ call: CAPPluginCall) {
        let pasteboard = UIPasteboard.general
        
        // 支持写入文本
        if let text = call.getString("text") {
            pasteboard.string = text
            call.resolve([
                "success": true,
                "message": "Text written to clipboard",
                "changeCount": pasteboard.changeCount
            ])
            return
        }
        
        // 支持写入图片
        if let base64Image = call.getString("image") {
            if let imageData = Data(base64Encoded: base64Image),
               let image = UIImage(data: imageData) {
                pasteboard.image = image
                call.resolve([
                    "success": true,
                    "message": "Image written to clipboard",
                    "changeCount": pasteboard.changeCount
                ])
                return
            } else {
                call.reject("Invalid image data")
                return
            }
        }
        
        // 支持写入URL
        if let urlString = call.getString("url") {
            if let url = URL(string: urlString) {
                pasteboard.url = url
                call.resolve([
                    "success": true,
                    "message": "URL written to clipboard",
                    "changeCount": pasteboard.changeCount
                ])
                return
            } else {
                call.reject("Invalid URL")
                return
            }
        }
        
        call.reject("No valid data provided to write to clipboard")
    }
    
    // 清空剪切板
    @objc func clear(_ call: CAPPluginCall) {
        let pasteboard = UIPasteboard.general
        pasteboard.items = []
        
        call.resolve([
            "success": true,
            "message": "Clipboard cleared",
            "changeCount": pasteboard.changeCount
        ])
    }
    
    @objc private func handleAppLaunch(_ notification: Notification) {
        print("OukekClipboard: App launched")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}