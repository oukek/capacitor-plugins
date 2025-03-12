import Foundation
import Capacitor
import StoreKit

// MARK: - StoreDelegate Protocol
protocol StoreDelegate: AnyObject {
    func didReceiveProducts(_ products: [SKProduct], invalidIdentifiers: [String])
    func didCompleteRestore(_ transactions: [SKPaymentTransaction])
}

/**
 * OukekPay for handling pay-related operations
 */
@objc(OukekPayPlugin)
public class OukekPayPlugin: CAPPlugin {
    private var transactionUpdateTask: Task<Void, Never>?
    
    override public func load() {
        // 监听交易更新
        if #available(iOS 15.0, *) {
            transactionUpdateTask = Task.detached { [weak self] in
                for await result in Transaction.updates {
                    if case .verified(let transaction) = result {
                        await self?.handleVerifiedTransaction(transaction)
                    }
                }
            }
        }
    }
    
    deinit {
        transactionUpdateTask?.cancel()
    }
    
    @objc func purchase(_ call: CAPPluginCall) {
        guard #available(iOS 15.0, *) else {
            call.reject("This feature requires iOS 15.0 or later")
            return
        }
        
        guard let productId = call.getString("productId") else {
            call.reject("Must provide a product ID")
            return
        }
        
        // 开始购买
        Task {
            do {
                let result = try await Store.shared.purchase(productId)
                switch result {
                case .success(let transaction):
                    await handleVerifiedTransaction(transaction)
                }
            } catch {
                handleError(error, call: call)
            }
        }
    }
    
    @objc func getProducts(_ call: CAPPluginCall) {
        guard #available(iOS 15.0, *) else {
            call.reject("This feature requires iOS 15.0 or later")
            return
        }
        
        guard let productIds = call.getArray("productIds", String.self) else {
            call.reject("Must provide product IDs")
            return
        }
        
        Task {
            do {
                let products = try await Store.shared.getProducts(productIds)
                let productList = products.map { product in
                    return [
                        "productId": product.id,
                        "price": product.price,
                        "localizedPrice": product.formattedPrice,
                        "localizedTitle": product.displayName,
                        "localizedDescription": product.description
                    ]
                }
                
                call.resolve([
                    "products": productList,
                    "invalidProductIds": []
                ])
            } catch {
                handleError(error, call: call)
            }
        }
    }
    
    @objc func restorePurchases(_ call: CAPPluginCall) {
        guard #available(iOS 15.0, *) else {
            call.reject("This feature requires iOS 15.0 or later")
            return
        }
        
        Task {
            do {
                let transactions = try await Store.shared.restorePurchases()
                let restoredTransactions = transactions.map { transaction in
                    return [
                        "productId": transaction.productID,
                        "transactionId": transaction.id
                    ]
                }
                
                await notifyListeners("purchaseUpdated", data: [
                    "state": "restored",
                    "transactions": restoredTransactions
                ])
                
                call.resolve()
            } catch {
                handleError(error, call: call)
            }
        }
    }
    
    // MARK: - Private Methods
    
    @available(iOS 15.0, *)
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        do {
            // 获取收据数据
            let receiptData = try await Store.shared.getReceiptData()
            
            // 通知前端
            await notifyListeners("purchaseUpdated", data: [
                "state": "succeeded",
                "productId": transaction.productID,
                "transactionId": transaction.id,
                "receipt": receiptData,
                "originalTransactionId": transaction.originalID,
                "purchaseDate": transaction.purchaseDate.timeIntervalSince1970,
                "expirationDate": transaction.expirationDate?.timeIntervalSince1970 as Any,
                "isUpgraded": transaction.isUpgraded
            ])
            
        } catch {
            notifyListeners("purchaseUpdated", data: [
                "state": "failed",
                "error": error.localizedDescription,
                "productId": transaction.productID
            ])
        }
    }
    
    private func handleError(_ error: Error, call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            switch error {
            case Store.StoreError.productNotFound:
                call.reject("Product not found")
            case Store.StoreError.userCancelled:
                call.reject("Purchase was cancelled by user")
            case Store.StoreError.paymentPending:
                call.reject("Payment is pending")
            case Store.StoreError.verificationFailed:
                call.reject("Transaction verification failed")
            case Store.StoreError.receiptNotFound:
                call.reject("Receipt not found")
            default:
                call.reject(error.localizedDescription)
            }
        } else {
            call.reject(error.localizedDescription)
        }
    }
}

// MARK: - StoreDelegate
extension OukekPayPlugin: StoreDelegate {
    func didReceiveProducts(_ products: [SKProduct], invalidIdentifiers: [String]) {
        // 可以在这里处理产品信息
    }
    
    func didCompleteRestore(_ transactions: [SKPaymentTransaction]) {
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

// MARK: - SKProduct Extension
private extension SKProduct {
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}
