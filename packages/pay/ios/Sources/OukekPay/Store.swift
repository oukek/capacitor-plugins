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
    
    /// 购买商品
    func purchase(_ productId: String) async throws -> StoreResult {
        guard let product = try await Product.products(for: [productId]).first else {
            throw StoreError.productNotFound
        }
        
        // 开始购买
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // 验证购买交易
            let transaction = try checkVerified(verification)
            // 完成交易
            await transaction.finish()
            // 返回结果
            return .success(transaction)
            
        case .userCancelled:
            throw StoreError.userCancelled
            
        case .pending:
            throw StoreError.paymentPending
            
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    /// 恢复购买
    func restorePurchases() async throws -> [Transaction] {
        // 请求最新的交易
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedTransactions.append(transaction)
            }
        }
        return purchasedTransactions
    }
    
    /// 获取收据数据
    func getReceiptData() throws -> String {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            throw StoreError.receiptNotFound
        }
        return receiptData.base64EncodedString()
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // 处理交易更新
                    await self.handle(transaction)
                }
            }
        }
    }
    
    private func handle(_ transaction: Transaction) async {
        // 存储已购买的交易
        if transaction.revocationDate == nil {
            purchasedTransactions.append(transaction)
        }
        
        // 完成交易
        await transaction.finish()
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
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
    var displayPrice: String {
        self.displayPrice
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceFormatStyle.locale
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
} 