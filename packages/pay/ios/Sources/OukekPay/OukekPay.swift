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
@objc(OukekPay)
public class OukekPay: CAPPlugin {
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
        
        print("[OukekPay] 开始购买商品: \(productId)")
        
        // 开始购买
        Task {
            do {
                print("[OukekPay] 调用Store.shared.purchase")
                let result = try await Store.shared.purchase(productId)
                print("[OukekPay] 购买结果: \(result)")
                switch result {
                case .success(let transaction):
                    print("[OukekPay] 交易成功，ID: \(transaction.id), 商品ID: \(transaction.productID)")
                    await handleVerifiedTransaction(transaction)
                }
            } catch {
                print("[OukekPay] 购买过程出错: \(error.localizedDescription)")
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
                        "price": NSDecimalNumber(decimal: product.price).doubleValue,
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
                
                notifyListeners("purchaseUpdated", data: [
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
        print("[OukekPay] 处理已验证的交易，ID: \(transaction.id), 商品ID: \(transaction.productID)")
        do {
            // 获取收据数据
            print("[OukekPay] 尝试获取收据数据")
            let receiptData = try await Store.shared.getReceiptData()
            print("[OukekPay] 收据数据获取成功，长度: \(receiptData.count)")
            
            // 通知前端
            print("[OukekPay] 通知前端交易成功")
            notifyListeners("purchaseUpdated", data: [
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
            print("[OukekPay] 获取收据数据失败: \(error.localizedDescription)")
            notifyListeners("purchaseUpdated", data: [
                "state": "failed",
                "error": error.localizedDescription,
                "productId": transaction.productID
            ])
        }
    }
    
    private func handleError(_ error: Error, call: CAPPluginCall) {
        print("[OukekPay] 处理错误: \(error.localizedDescription)")
        if #available(iOS 15.0, *) {
            switch error {
            case Store.StoreError.productNotFound:
                print("[OukekPay] 错误类型: 商品未找到")
                call.reject("Product not found")
            case Store.StoreError.userCancelled:
                print("[OukekPay] 错误类型: 用户取消")
                call.reject("Purchase was cancelled by user")
            case Store.StoreError.paymentPending:
                print("[OukekPay] 错误类型: 支付等待中")
                call.reject("Payment is pending")
            case Store.StoreError.verificationFailed:
                print("[OukekPay] 错误类型: 验证失败")
                call.reject("Transaction verification failed")
            case Store.StoreError.receiptNotFound:
                print("[OukekPay] 错误类型: 收据未找到")
                call.reject("Receipt not found")
            default:
                print("[OukekPay] 错误类型: 其他错误")
                call.reject(error.localizedDescription)
            }
        } else {
            call.reject(error.localizedDescription)
        }
    }
}

// MARK: - StoreDelegate
extension OukekPay: StoreDelegate {
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
