//
//  StoreManager.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import StoreKit
import SwiftUI
import CoreData
import Combine
import os.log

/// Manager class for handling all in-app purchases and subscription management
class StoreManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Whether user has premium access
    @Published var isPremium = false
    
    /// Available products from App Store
    @Published var products: [Product] = []
    
    /// Currently selected product for purchase
    @Published var selectedProduct: Product?
    
    /// Whether products are loading
    @Published var isLoading = false
    
    /// Whether a purchase is in progress
    @Published var isPurchasing = false
    
    /// Whether a restore is in progress
    @Published var isRestoring = false
    
    /// Error message if purchase fails
    @Published var errorMessage: String?
    
    /// Success message after purchase
    @Published var successMessage: String?
    
    /// Whether to show paywall
    @Published var showPaywall = false
    
    /// Subscription expiration date
    @Published var subscriptionExpirationDate: Date?
    
    /// Subscription auto-renews
    @Published var subscriptionAutoRenews = false
    
    /// Whether the app is in sandbox environment
    @Published var isSandboxEnvironment = false
    
    /// Subscription tier
    @Published var subscriptionTier: SubscriptionTier = .free
    
    // MARK: - Private Properties
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.lifecoach.ai", category: "StoreManager")
    
    /// Core Data context for persisting subscription data
    private var viewContext: NSManagedObjectContext?
    
    /// Product identifiers
    private let productIdentifiers = [
        "com.lifecoach.ai.premium.monthly",
        "com.lifecoach.ai.premium.yearly"
    ]
    
    /// Subscription update task
    private var subscriptionUpdateTask: Task<Void, Error>?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Transaction listener task
    private var transactionListenerTask: Task<Void, Error>?
    
    /// User profile for persisting subscription status
    private var userProfile: UserProfile?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        logger.info("Initializing StoreManager")
        
        // Check if running in sandbox
        checkSandboxEnvironment()
        
        // Start listening for transactions
        startTransactionListener()
        
        // Register for notifications
        registerForNotifications()
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        logger.info("Running in simulator - will use mock data")
        loadMockData()
        #endif
    }
    
    /// Set the Core Data context
    func setViewContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        
        // Load user profile
        loadUserProfile()
        
        // Request products
        requestProducts()
    }
    
    // MARK: - User Profile
    
    /// Load user profile from Core Data
    private func loadUserProfile() {
        guard let context = viewContext else {
            logger.error("Cannot load user profile: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if let profile = profiles.first {
                userProfile = profile
                isPremium = profile.isPremium
                subscriptionTier = profile.isPremium ? .premium : .free
                
                // Load subscription if available
                loadSubscription()
                
                logger.info("Loaded user profile with premium status: \(profile.isPremium)")
            } else {
                logger.warning("No user profile found")
            }
        } catch {
            logger.error("Failed to fetch user profile: \(error.localizedDescription)")
        }
    }
    
    /// Load subscription from Core Data
    private func loadSubscription() {
        guard let context = viewContext, let userProfile = userProfile else {
            logger.error("Cannot load subscription: Core Data context or user profile not available")
            return
        }
        
        // Get subscription from user profile
        if let subscription = userProfile.subscription {
            isPremium = subscription.isActive
            subscriptionExpirationDate = subscription.expirationDate
            
            // Check if subscription has expired
            if let expirationDate = subscription.expirationDate, expirationDate < Date() {
                isPremium = false
                subscriptionTier = .free
                
                // Update user profile
                userProfile.isPremium = false
                
                // Save context
                do {
                    try context.save()
                    logger.info("Updated user profile for expired subscription")
                } catch {
                    logger.error("Failed to update user profile: \(error.localizedDescription)")
                }
            } else {
                subscriptionTier = .premium
            }
            
            logger.info("Loaded subscription with expiration date: \(String(describing: subscription.expirationDate))")
        }
    }
    
    // MARK: - Product Requests
    
    /// Request products from App Store
    func requestProducts() {
        guard !isLoading else {
            logger.info("Product request already in progress")
            return
        }
        
        logger.info("Requesting products")
        
        // Set loading state
        isLoading = true
        
        // Request products
        Task {
            do {
                // Request products from App Store
                let storeProducts = try await Product.products(for: productIdentifiers)
                
                // Update products on main thread
                await MainActor.run {
                    products = storeProducts
                    isLoading = false
                    errorMessage = nil
                    
                    logger.info("Loaded \(storeProducts.count) products")
                }
            } catch {
                await MainActor.run {
                    products = []
                    isLoading = false
                    errorMessage = "Failed to load products: \(error.localizedDescription)"
                    
                    logger.error("Failed to load products: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Purchase Handling
    
    /// Purchase a product
    func purchaseProduct(productId: String) {
        // Find product
        guard let product = products.first(where: { $0.id == productId }) else {
            errorMessage = "Product not found"
            logger.error("Product not found: \(productId)")
            return
        }
        
        // Purchase product
        purchaseProduct(product: product)
    }
    
    /// Purchase a product
    func purchaseProduct(product: Product) {
        guard !isPurchasing else {
            logger.info("Purchase already in progress")
            return
        }
        
        logger.info("Purchasing product: \(product.id)")
        
        // Set purchasing state
        isPurchasing = true
        selectedProduct = product
        errorMessage = nil
        
        // Purchase product
        Task {
            do {
                // Request purchase from App Store
                let result = try await product.purchase()
                
                // Handle purchase result
                await handlePurchaseResult(result)
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                    
                    logger.error("Purchase failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Handle purchase result
    @MainActor
    private func handlePurchaseResult(_ result: Product.PurchaseResult) {
        switch result {
        case .success(let verification):
            // Verify transaction
            Task {
                await verifyTransaction(verification)
            }
            
        case .userCancelled:
            isPurchasing = false
            logger.info("Purchase cancelled by user")
            
        case .pending:
            isPurchasing = false
            successMessage = "Purchase is pending approval"
            logger.info("Purchase is pending approval")
            
        @unknown default:
            isPurchasing = false
            errorMessage = "Unknown purchase result"
            logger.error("Unknown purchase result")
        }
    }
    
    /// Verify transaction
    private func verifyTransaction(_ verification: VerificationResult<Transaction>) async {
        // Check verification result
        switch verification {
        case .verified(let transaction):
            // Transaction is verified, update subscription status
            await updateSubscriptionStatus(with: transaction)
            
            // Finish transaction
            await transaction.finish()
            
            // Update UI
            await MainActor.run {
                isPurchasing = false
                successMessage = "Purchase successful!"
                
                logger.info("Transaction verified and finished: \(transaction.id)")
            }
            
        case .unverified(_, let error):
            // Transaction failed verification
            await MainActor.run {
                isPurchasing = false
                errorMessage = "Transaction verification failed: \(error.localizedDescription)"
                
                logger.error("Transaction verification failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update subscription status with transaction
    private func updateSubscriptionStatus(with transaction: Transaction) async {
        guard let context = viewContext, let userProfile = userProfile else {
            logger.error("Cannot update subscription status: Core Data context or user profile not available")
            return
        }
        
        // Get product ID and expiration date
        let productId = transaction.productID
        let expirationDate = transaction.expirationDate
        
        // Update subscription in Core Data
        await MainActor.run {
            // Check if user already has a subscription
            var subscription = userProfile.subscription
            
            if subscription == nil {
                // Create new subscription
                subscription = Subscription(context: context)
                subscription?.id = UUID()
                subscription?.userProfile = userProfile
            }
            
            // Update subscription details
            subscription?.productId = productId
            subscription?.purchaseDate = transaction.purchaseDate
            subscription?.expirationDate = expirationDate
            subscription?.originalPurchaseDate = transaction.originalPurchaseDate
            subscription?.isActive = true
            subscription?.type = productId.contains("yearly") ? "yearly" : "monthly"
            
            // Store receipt data if available
            if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
               let receiptData = try? Data(contentsOf: appStoreReceiptURL) {
                subscription?.receiptData = receiptData
            }
            
            // Update user profile
            userProfile.isPremium = true
            userProfile.subscription = subscription
            
            // Update published properties
            isPremium = true
            subscriptionTier = .premium
            subscriptionExpirationDate = expirationDate
            subscriptionAutoRenews = transaction.autoRenewStatus == .willRenew
            
            // Save context
            do {
                try context.save()
                logger.info("Updated subscription status in Core Data")
            } catch {
                logger.error("Failed to save subscription to Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Transaction Listener
    
    /// Start listening for transactions
    private func startTransactionListener() {
        // Cancel any existing task
        transactionListenerTask?.cancel()
        
        // Start new listener task
        transactionListenerTask = Task.detached { [weak self] in
            // Listen for transactions
            for await result in Transaction.updates {
                // Handle transaction update
                if let self = self {
                    await self.handleTransactionUpdate(result)
                }
            }
        }
        
        logger.info("Started transaction listener")
    }
    
    /// Handle transaction update
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        // Check verification result
        switch result {
        case .verified(let transaction):
            // Check if transaction is for a subscription
            if transaction.productType == .autoRenewable {
                // Update subscription status
                await updateSubscriptionStatus(with: transaction)
                
                // Check subscription state
                if let expirationDate = transaction.expirationDate {
                    if expirationDate < Date() {
                        // Subscription has expired
                        await updateSubscriptionExpired()
                    }
                }
            }
            
            // Finish transaction
            await transaction.finish()
            
            logger.info("Handled transaction update: \(transaction.id)")
            
        case .unverified(let transaction, let error):
            // Transaction failed verification
            logger.error("Transaction verification failed: \(error.localizedDescription)")
            
            // Still finish the transaction to avoid repeat processing
            await transaction.finish()
        }
    }
    
    /// Update subscription as expired
    private func updateSubscriptionExpired() async {
        guard let context = viewContext, let userProfile = userProfile else {
            logger.error("Cannot update expired subscription: Core Data context or user profile not available")
            return
        }
        
        // Update subscription in Core Data
        await MainActor.run {
            // Update user profile
            userProfile.isPremium = false
            
            // Update subscription
            if let subscription = userProfile.subscription {
                subscription.isActive = false
            }
            
            // Update published properties
            isPremium = false
            subscriptionTier = .free
            
            // Save context
            do {
                try context.save()
                logger.info("Updated expired subscription in Core Data")
            } catch {
                logger.error("Failed to update expired subscription: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore purchases
    func restorePurchases() {
        guard !isRestoring else {
            logger.info("Restore already in progress")
            return
        }
        
        logger.info("Restoring purchases")
        
        // Set restoring state
        isRestoring = true
        errorMessage = nil
        
        // Request restore
        Task {
            do {
                // Check for previous purchases
                try await AppStore.sync()
                
                // Get all transactions
                let transactions = await Transaction.currentEntitlements
                
                if transactions.isEmpty {
                    // No active subscriptions found
                    await MainActor.run {
                        isRestoring = false
                        errorMessage = "No active subscriptions found"
                        
                        logger.info("No active subscriptions found during restore")
                    }
                    return
                }
                
                // Process transactions
                var hasValidSubscription = false
                
                for await result in transactions {
                    switch result {
                    case .verified(let transaction):
                        // Check if transaction is for a subscription
                        if transaction.productType == .autoRenewable {
                            // Check if subscription is still valid
                            if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                                // Update subscription status
                                await updateSubscriptionStatus(with: transaction)
                                hasValidSubscription = true
                                
                                logger.info("Restored valid subscription: \(transaction.id)")
                            }
                        }
                        
                    case .unverified(_, let error):
                        logger.error("Transaction verification failed during restore: \(error.localizedDescription)")
                    }
                }
                
                // Update UI
                await MainActor.run {
                    isRestoring = false
                    
                    if hasValidSubscription {
                        successMessage = "Your subscription has been restored!"
                    } else {
                        errorMessage = "No active subscriptions found"
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = "Restore failed: \(error.localizedDescription)"
                    
                    logger.error("Restore failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Subscription Management
    
    /// Check if feature is available based on subscription tier
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        return subscriptionTier.hasAccess(to: feature)
    }
    
    /// Show paywall for a premium feature
    func showPaywallIfNeeded(for feature: PremiumFeature) -> Bool {
        // Check if feature requires premium
        if feature.isPremiumOnly && !isPremium {
            showPaywall = true
            return true
        }
        
        return false
    }
    
    /// Get monthly subscription product
    func getMonthlySubscription() -> Product? {
        return products.first { $0.id == "com.lifecoach.ai.premium.monthly" }
    }
    
    /// Get yearly subscription product
    func getYearlySubscription() -> Product? {
        return products.first { $0.id == "com.lifecoach.ai.premium.yearly" }
    }
    
    /// Get formatted price for a product
    func getFormattedPrice(for product: Product?) -> String {
        guard let product = product else { return "N/A" }
        return product.displayPrice
    }
    
    /// Get subscription period for a product
    func getSubscriptionPeriod(for product: Product?) -> String {
        guard let product = product else { return "" }
        
        if product.id.contains("monthly") {
            return "month"
        } else if product.id.contains("yearly") {
            return "year"
        }
        
        return ""
    }
    
    /// Calculate savings percentage between monthly and yearly plans
    func calculateSavingsPercentage() -> Int? {
        guard let monthlyProduct = getMonthlySubscription(),
              let yearlyProduct = getYearlySubscription() else {
            return nil
        }
        
        let monthlyPrice = monthlyProduct.price
        let yearlyPrice = yearlyProduct.price
        
        // Calculate equivalent monthly cost of yearly plan
        let monthlyEquivalent = yearlyPrice / 12
        
        // Calculate savings percentage
        let savingsPercentage = (1 - (monthlyEquivalent / monthlyPrice)) * 100
        
        return Int(savingsPercentage.rounded())
    }
    
    // MARK: - Environment Checks
    
    /// Check if running in sandbox environment
    private func checkSandboxEnvironment() {
        #if DEBUG
        isSandboxEnvironment = true
        logger.info("Running in DEBUG mode, assuming sandbox environment")
        return
        #endif
        
        // Check receipt URL
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receiptURLString = receiptURL.absoluteString
            isSandboxEnvironment = receiptURLString.contains("sandbox")
            
            logger.info("Receipt URL check: sandbox environment = \(isSandboxEnvironment)")
        }
    }
    
    // MARK: - Notification Observers
    
    /// Register for system notifications
    private func registerForNotifications() {
        // App will enter foreground notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    /// Handle app will enter foreground notification
    @objc private func handleAppWillEnterForeground() {
        // Check subscription status
        checkSubscriptionStatus()
    }
    
    /// Check subscription status
    private func checkSubscriptionStatus() {
        // Cancel any existing task
        subscriptionUpdateTask?.cancel()
        
        // Start new task
        subscriptionUpdateTask = Task {
            do {
                // Check for subscription updates
                try await AppStore.sync()
                
                // Get current subscriptions
                let transactions = await Transaction.currentEntitlements
                
                // Check if we have any active subscriptions
                var hasActiveSubscription = false
                
                for await result in transactions {
                    if case .verified(let transaction) = result,
                       transaction.productType == .autoRenewable,
                       let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        
                        hasActiveSubscription = true
                        
                        // Update subscription status
                        await updateSubscriptionStatus(with: transaction)
                        
                        logger.info("Found active subscription during status check")
                        break
                    }
                }
                
                // If no active subscription but user has premium, update status
                if !hasActiveSubscription && isPremium {
                    await updateSubscriptionExpired()
                    
                    logger.info("No active subscription found, updated status to expired")
                }
            } catch {
                logger.error("Failed to check subscription status: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Mock Data for Simulator
    
    /// Load mock data for simulator testing
    private func loadMockData() {
        logger.info("Loading mock store data for simulator")
        
        // Create mock products
        let mockMonthlyProduct = MockProduct(
            id: "com.lifecoach.ai.premium.monthly",
            displayName: "Premium Monthly",
            description: "Full access to all premium features",
            price: 4.99,
            displayPrice: "$4.99",
            isFamilyShareable: true,
            subscriptionPeriod: "month"
        )
        
        let mockYearlyProduct = MockProduct(
            id: "com.lifecoach.ai.premium.yearly",
            displayName: "Premium Yearly",
            description: "Full access to all premium features",
            price: 49.99,
            displayPrice: "$49.99",
            isFamilyShareable: true,
            subscriptionPeriod: "year"
        )
        
        // Update products
        DispatchQueue.main.async {
            self.products = [mockMonthlyProduct, mockYearlyProduct] as [Any] as! [Product]
            self.isLoading = false
            
            // In simulator, default to non-premium
            self.isPremium = false
            self.subscriptionTier = .free
            
            // Set sandbox environment
            self.isSandboxEnvironment = true
            
            self.logger.info("Loaded mock store products")
        }
    }
    
    /// Mock Product for simulator
    private class MockProduct: Product {
        let mockId: String
        let mockDisplayName: String
        let mockDescription: String
        let mockPrice: Decimal
        let mockDisplayPrice: String
        let mockIsFamilyShareable: Bool
        let mockSubscriptionPeriod: String
        
        init(id: String, displayName: String, description: String, price: Decimal, displayPrice: String, isFamilyShareable: Bool, subscriptionPeriod: String) {
            self.mockId = id
            self.mockDisplayName = displayName
            self.mockDescription = description
            self.mockPrice = price
            self.mockDisplayPrice = displayPrice
            self.mockIsFamilyShareable = isFamilyShareable
            self.mockSubscriptionPeriod = subscriptionPeriod
            
            // Initialize with dummy values
            super.init()
        }
        
        override var id: String {
            return mockId
        }
        
        override var displayName: String {
            return mockDisplayName
        }
        
        override var description: String {
            return mockDescription
        }
        
        override var price: Decimal {
            return mockPrice
        }
        
        override var displayPrice: String {
            return mockDisplayPrice
        }
        
        override var isFamilyShareable: Bool {
            return mockIsFamilyShareable
        }
        
        override var subscription: Product.SubscriptionInfo? {
            return MockSubscriptionInfo(subscriptionPeriod: mockSubscriptionPeriod)
        }
        
        override func purchase(options: Set<Product.PurchaseOption> = []) async throws -> Product.PurchaseResult {
            // Simulate purchase success
            return .success(MockVerificationResult())
        }
    }
    
    /// Mock SubscriptionInfo for simulator
    private class MockSubscriptionInfo: Product.SubscriptionInfo {
        let mockSubscriptionPeriod: String
        
        init(subscriptionPeriod: String) {
            self.mockSubscriptionPeriod = subscriptionPeriod
            super.init()
        }
        
        override var subscriptionPeriod: Product.SubscriptionPeriod {
            return MockSubscriptionPeriod(mockSubscriptionPeriod)
        }
    }
    
    /// Mock SubscriptionPeriod for simulator
    private class MockSubscriptionPeriod: Product.SubscriptionPeriod {
        let mockUnit: String
        
        init(_ unit: String) {
            self.mockUnit = unit
            super.init()
        }
        
        override var unit: Product.SubscriptionPeriod.Unit {
            return mockUnit == "month" ? .month : .year
        }
        
        override var value: Int {
            return 1
        }
    }
    
    /// Mock VerificationResult for simulator
    private class MockVerificationResult: VerificationResult<Transaction> {
        override var jwsRepresentation: String {
            return "mock_jws_representation"
        }
    }
}

// MARK: - StoreKit Extensions

extension Product.SubscriptionPeriod.Unit: Identifiable {
    public var id: Int {
        switch self {
        case .day: return 0
        case .week: return 1
        case .month: return 2
        case .year: return 3
        @unknown default: return 999
        }
    }
    
    var displayName: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "unknown"
        }
    }
}

extension Product.ProductType: Identifiable {
    public var id: Int {
        switch self {
        case .consumable: return 0
        case .nonConsumable: return 1
        case .autoRenewable: return 2
        case .nonRenewable: return 3
        @unknown default: return 999
        }
    }
    
    var displayName: String {
        switch self {
        case .consumable: return "Consumable"
        case .nonConsumable: return "Non-Consumable"
        case .autoRenewable: return "Auto-Renewable Subscription"
        case .nonRenewable: return "Non-Renewable Subscription"
        @unknown default: return "Unknown"
        }
    }
}
