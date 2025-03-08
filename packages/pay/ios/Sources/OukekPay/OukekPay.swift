import Foundation
import Capacitor
import DYFStore

/**
 * OukekPay for handling pay-related operations
 */
@objc(OukekPay)
public class OukekPay: CAPPlugin {
    private var notificationObserver: Any?
    
    override public func load() {
        // 初始化 DYFStore
        DYFStore.default.delegate = self
        
        // 添加交易观察者
        notificationObserver = NotificationCenter.default.addObserver(
            forName: DYFStore.purchasedNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            self?.handlePurchaseNotification(notification)
        }
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc func purchase(_ call: CAPPluginCall) {
        guard let productId = call.getString("productId") else {
            call.reject("Must provide a product ID")
            return
        }
        
        // 开始购买
        DYFStore.default.purchaseProduct(productId)
    }
    
    @objc func getProducts(_ call: CAPPluginCall) {
        guard let productIds = call.getArray("productIds", String.self) else {
            call.reject("Must provide product IDs")
            return
        }
        
        DYFStore.default.requestProducts(productIds) { products, invalidIdentifiers, error in
            if let error = error {
                call.reject("Failed to get products: \(error.localizedDescription)")
                return
            }
            
            let productList = products?.map { product in
                return [
                    "productId": product.productIdentifier,
                    "price": product.price.stringValue,
                    "localizedPrice": product.localizedPrice ?? "",
                    "localizedTitle": product.localizedTitle,
                    "localizedDescription": product.localizedDescription
                ]
            }
            
            call.resolve([
                "products": productList ?? [],
                "invalidProductIds": invalidIdentifiers ?? []
            ])
        }
    }
    
    @objc func restorePurchases(_ call: CAPPluginCall) {
        DYFStore.default.restoreTransactions()
    }
    
    private func handlePurchaseNotification(_ notification: Notification) {
        guard let info = notification.object as? DYFStore.NotificationInfo else { return }
        
        switch info.state! {
        case .purchasing:
            notifyListeners("purchaseUpdated", data: ["state": "purchasing"])
            
        case .cancelled:
            notifyListeners("purchaseUpdated", data: [
                "state": "cancelled",
                "productId": info.productIdentifier ?? ""
            ])
            
        case .failed:
            notifyListeners("purchaseUpdated", data: [
                "state": "failed",
                "error": info.error?.localizedDescription ?? "Unknown error",
                "productId": info.productIdentifier ?? ""
            ])
            
        case .succeeded, .restored:
            // 验证收据
            verifyReceipt(info)
            
        case .restoreFailed:
            notifyListeners("purchaseUpdated", data: [
                "state": "restoreFailed",
                "error": info.error?.localizedDescription ?? "Unknown error"
            ])
            
        case .deferred:
            notifyListeners("purchaseUpdated", data: ["state": "deferred"])
        }
    }
    
    private func verifyReceipt(_ info: DYFStore.NotificationInfo) {
        guard let receiptURL = DYFStore.receiptURL() else {
            notifyListeners("purchaseUpdated", data: [
                "state": "failed",
                "error": "No receipt URL",
                "productId": info.productIdentifier ?? ""
            ])
            return
        }
        
        do {
            let receiptData = try Data(contentsOf: receiptURL)
            let base64Receipt = receiptData.base64EncodedString()
            
            // 通知前端收据信息
            notifyListeners("purchaseUpdated", data: [
                "state": "succeeded",
                "productId": info.productIdentifier ?? "",
                "transactionId": info.transactionIdentifier ?? "",
                "receipt": base64Receipt
            ])
            
            // 完成交易
            if let transaction = info.transaction {
                DYFStore.default.finishTransaction(transaction)
            }
            
        } catch {
            notifyListeners("purchaseUpdated", data: [
                "state": "failed",
                "error": "Failed to read receipt: \(error.localizedDescription)",
                "productId": info.productIdentifier ?? ""
            ])
        }
    }
}

// MARK: - DYFStoreDelegate
extension OukekPay: DYFStoreDelegate {
    public func didReceiveProducts(_ products: [SKProduct], invalidIdentifiers: [String]) {
        // 可以在这里处理产品信息
    }
    
    public func didCompleteRestore(_ transactions: [SKPaymentTransaction]) {
        notifyListeners("purchaseUpdated", data: [
            "state": "restored",
            "transactions": transactions.map { tx in
                return [
                    "productId": tx.payment.productIdentifier,
                    "transactionId": tx.transactionIdentifier ?? ""
                ]
            }
        ])
    }
}
