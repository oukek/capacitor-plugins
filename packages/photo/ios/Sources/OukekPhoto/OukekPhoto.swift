import Foundation
import Capacitor
import Photos
import UIKit

/**
 * OukekPhoto for handling photo-related operations
 */
@objc(OukekPhoto)
public class OukekPhoto: CAPPlugin {
    override public func load() {
        print("OukekPhoto: Plugin loaded")
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppLaunch),
                                            name: UIApplication.didFinishLaunchingNotification,
                                            object: nil)
    }
    
    @objc private func handleAppLaunch(_ notification: Notification) {
        print("OukekPhoto: App launched")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func saveImageToAlbum(_ call: CAPPluginCall) {
        guard let base64Data = call.getString("base64Data") else {
            call.reject("Must provide base64Data")
            return
        }
        
        // Remove data:image/png;base64, prefix if exists
        let cleanBase64 = base64Data.components(separatedBy: ",").last ?? base64Data
        
        guard let imageData = Data(base64Encoded: cleanBase64),
              let image = UIImage(data: imageData) else {
            call.reject("Invalid base64 image data")
            return
        }
        
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
                self?.handlePhotoLibraryAuthorization(status: status, image: image, call: call)
            }
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                self?.handlePhotoLibraryAuthorization(status: status, image: image, call: call)
            }
        }
    }
    
    private func handlePhotoLibraryAuthorization(status: PHAuthorizationStatus, image: UIImage, call: CAPPluginCall) {
        if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        call.resolve(["success": true])
                    } else {
                        call.reject("Failed to save image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                call.reject("No permission to save photos")
            }
        }
    }
}
