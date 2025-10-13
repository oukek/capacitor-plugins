import Foundation
import StoreKit

@available(iOS 15.0, *)
actor Store {
    static let shared = Store()
    
    // 存储已购买的交易，用于恢复购买
    private var purchasedTransactions: [Transaction] = []
    
    private init() {
        // 开始监听交易更新
        listenForTransactions()
    }
    
    // MARK: - Public Methods
    
    /// 获取商品信息
    func getProducts(_ identifiers: [String]) async throws -> [Product] {
        return try await Product.products(for: identifiers)
    }
    
    @available(iOS 15.0, *)
    func purchase(_ product: Product) async throws -> VerificationResult<Transaction> {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            if case .verified(let transaction) = verificationResult {
                await transaction.finish()
                // Store the transaction in our purchased transactions list
                if transaction.revocationDate == nil {
                    purchasedTransactions.append(transaction)
                }
            }
            return verificationResult
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.paymentPending
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    /// 恢复购买 - 返回 VerificationResult 以便获取 jwsRepresentation
    func restorePurchases() async throws -> [VerificationResult<Transaction>] {
        var results: [VerificationResult<Transaction>] = []
        // 请求最新的交易
        for await result in Transaction.currentEntitlements {
            results.append(result)
            if case .verified(let transaction) = result {
                purchasedTransactions.append(transaction)
            }
        }
        return results
    }
    
    /// 获取收据数据（增加刷新兜底逻辑）
    func getReceiptData() async -> Data? {
        print("[OukekPay] 开始获取收据数据")
        let receiptURL = Bundle.main.appStoreReceiptURL
        print("[OukekPay] receiptURL: \(String(describing: receiptURL))")
        
        // 尝试直接读取收据
        if let url = receiptURL, let receiptData = try? Data(contentsOf: url) {
            print("[OukekPay] 收据数据读取成功，大小: \(receiptData.count) bytes")
            return receiptData
        }
        
        print("[OukekPay] 收据文件不存在或读取失败，尝试刷新收据")
        
        // 如果收据不存在，尝试刷新
        let refresher = ReceiptRefresher()
        let success = await refresher.refresh()
        
        if success, let url = receiptURL, let receiptData = try? Data(contentsOf: url) {
            print("[OukekPay] 收据刷新成功，大小: \(receiptData.count) bytes")
            return receiptData
        } else {
            print("[OukekPay] 收据刷新失败或仍无法读取")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() {
        print("[OukekPay-Store] 开始监听交易更新")
        Task.detached {
            for await result in Transaction.updates {
                print("[OukekPay-Store] 收到交易更新")
                if case .verified(let transaction) = result {
                    print("[OukekPay-Store] 收到已验证的交易，ID: \(transaction.id), 商品ID: \(transaction.productID)")
                    // 处理交易更新
                    await self.handle(transaction)
                } else {
                    print("[OukekPay-Store] 收到未验证的交易更新")
                }
            }
        }
    }
    
    private func handle(_ transaction: Transaction) async {
        print("[OukekPay-Store] 处理交易，ID: \(transaction.id), 商品ID: \(transaction.productID)")
        // 存储已购买的交易
        if transaction.revocationDate == nil {
            purchasedTransactions.append(transaction)
            print("[OukekPay-Store] 已存储交易到已购买列表")
        } else {
            print("[OukekPay-Store] 该交易已被撤销，撤销日期: \(String(describing: transaction.revocationDate))")
        }
        
        // 完成交易
        await transaction.finish()
        print("[OukekPay-Store] 交易已完成")
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        print("[OukekPay-Store] 开始验证交易")
        switch result {
        case .unverified:
            print("[OukekPay-Store] 交易验证失败")
            throw StoreError.verificationFailed
        case .verified(let safe):
            print("[OukekPay-Store] 交易验证成功")
            return safe
        }
    }
}

// 刷新收据帮助类
private class ReceiptRefresher: NSObject, SKRequestDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?
    
    func refresh() async -> Bool {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.continuation = continuation
            let request = SKReceiptRefreshRequest()
            request.delegate = self
            request.start()
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("[OukekPay-Store] 收据刷新成功")
        continuation?.resume(returning: true)
        continuation = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("[OukekPay-Store] 收据刷新失败: \(error.localizedDescription)")
        continuation?.resume(returning: false)
        continuation = nil
    }
}

// MARK: - Types

@available(iOS 15.0, *)
extension Store {
    enum StoreResult {
        case success(Transaction)
    }
    
    enum StoreError: LocalizedError {
        case productNotFound
        case purchaseFailed
        case userCancelled
        case paymentPending
        case verificationFailed
        case receiptNotFound
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "Product not found"
            case .purchaseFailed:
                return "Purchase failed"
            case .userCancelled:
                return "Purchase was cancelled"
            case .paymentPending:
                return "Payment is pending"
            case .verificationFailed:
                return "Transaction verification failed"
            case .receiptNotFound:
                return "Receipt not found"
            case .unknown:
                return "Unknown error occurred"
            }
        }
    }
}

// MARK: - Product Extensions
@available(iOS 15.0, *)
extension Product {
    // Removed invalid recursive displayPrice computed property
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceFormatStyle.locale
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price)"
    }
}