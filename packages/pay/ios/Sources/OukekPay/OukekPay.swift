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
                    await self?.handleVerifiedTransaction(transaction, verificationResult: result)
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
        
        // 获取可选的 appAccountToken
        var appAccountToken: UUID? = nil
        if let appAccountTokenString = call.getString("appAccountToken") {
            if let uuid = UUID(uuidString: appAccountTokenString) {
                appAccountToken = uuid
                print("[OukekPay] 使用提供的 appAccountToken: \(appAccountTokenString)")
            } else {
                call.reject("Invalid appAccountToken format. Must be a valid UUID string.")
                return
            }
        }
        
        print("[OukekPay] 开始购买商品: \(productId)")
        
        // 开始购买
        Task {
            do {
                // 首先获取产品信息
                print("[OukekPay] 获取产品信息")
                let products = try await Store.shared.getProducts([productId])
                guard let product = products.first else {
                    call.reject("Product not found")
                    return
                }
                
                print("[OukekPay] 开始购买产品: \(product.displayName)")
                
                // 使用 StoreKit 2 的 purchase 方法，支持 appAccountToken
                let purchaseResult: Product.PurchaseResult
                if let appAccountToken = appAccountToken {
                    purchaseResult = try await product.purchase(options: [.appAccountToken(appAccountToken)])
                } else {
                    purchaseResult = try await product.purchase()
                }
                
                print("[OukekPay] 购买结果: \(purchaseResult)")
                
                switch purchaseResult {
                case .success(let verificationResult):
                    if case .verified(let transaction) = verificationResult {
                        print("[OukekPay] 交易成功，ID: \(transaction.id), 商品ID: \(transaction.productID)")
                        if let token = transaction.appAccountToken {
                            print("[OukekPay] 交易中的 appAccountToken: \(token)")
                        }
                        await transaction.finish()
                        await handleVerifiedTransaction(transaction, verificationResult: verificationResult)
                        call.resolve()
                    } else {
                        call.reject("Transaction verification failed")
                    }
                case .userCancelled:
                    call.reject("Purchase was cancelled by user")
                case .pending:
                    call.reject("Payment is pending")
                @unknown default:
                    call.reject("Unknown purchase result")
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
                let verificationResults = try await Store.shared.restorePurchases()
                let restoredTransactions = verificationResults.compactMap { result -> [String: Any]? in
                    switch result {
                    case .verified(let transaction):
                        var transactionData: [String: Any] = [
                            "productId": transaction.productID,
                            "transactionId": transaction.id
                        ]
                        
                        // 现在可以从 VerificationResult 获取 jwsRepresentation
                        transactionData["transactionJWS"] = result.jwsRepresentation
                        
                        return transactionData
                    case .unverified(let transaction, let error):
                        print("[OukekPay] 未验证的交易: \(transaction.id), 错误: \(error)")
                        // 可以选择是否包含未验证的交易
                        return [
                            "productId": transaction.productID,
                            "transactionId": transaction.id,
                            "verified": false
                        ]
                    }
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
    private func handleVerifiedTransaction(_ transaction: Transaction, verificationResult: VerificationResult<Transaction>) async {
        print("[OukekPay] 处理已验证的交易，ID: \(transaction.id), 商品ID: \(transaction.productID)")
        
        let receiptData = await Store.shared.getReceiptData()
        
        var data: [String: Any] = [
            "productId": transaction.productID,
            "transactionId": transaction.id,
            "originalTransactionId": transaction.originalID,
            "purchaseDate": transaction.purchaseDate.timeIntervalSince1970,
            "expirationDate": transaction.expirationDate?.timeIntervalSince1970 as Any,
            "isUpgraded": transaction.isUpgraded
        ]
        
        // 现在可以从 VerificationResult 获取 jwsRepresentation
        data["transactionJWS"] = verificationResult.jwsRepresentation
        
        // 添加 appAccountToken 到返回数据中
        if let appAccountToken = transaction.appAccountToken {
            data["appAccountToken"] = appAccountToken.uuidString
            print("[OukekPay] 交易包含 appAccountToken: \(appAccountToken.uuidString)")
        }
        
        // 如果有收据数据，添加到响应中
        if let receiptData = receiptData {
            data["receiptData"] = receiptData.base64EncodedString()
        }
        
        notifyListeners("purchaseUpdated", data: [
            "state": "purchased",
            "data": data
        ])
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
