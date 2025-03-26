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
}