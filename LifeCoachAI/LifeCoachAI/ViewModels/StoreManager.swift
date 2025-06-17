//
//  StoreManager.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import StoreKit
import SwiftUI
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
        
        // Load user profile
        loadUserProfile()
        
        // Request products
        requestProducts()
    }
    
    // MARK: - User Profile
    
    /// Load user profile from DataStore
    private func loadUserProfile() {
<<<<<<< HEAD
        // Create a new user profile for store management
        let newProfile = UserProfile(context: PersistenceController.shared.container.viewContext)
        newProfile.id = UUID()
        newProfile.creationDate = Date()
        newProfile.isPremium = false
        userProfile = newProfile
=======
        userProfile = DataStore.shared.loadUserProfile()
>>>>>>> 510ee9d (more changes')
        if let profile = userProfile {
            isPremium = profile.subscription?.isActive ?? false
            subscriptionTier = isPremium ? .premium : .free
            subscriptionExpirationDate = profile.subscription?.expirationDate
<<<<<<< HEAD
            logger.info("Loaded user profile with premium status: \(self.isPremium)")
=======
            logger.info("Loaded user profile with premium status: \(isPremium)")
>>>>>>> 510ee9d (more changes')
        } else {
            logger.warning("No user profile found")
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
    private func verifyTransaction(_ verification: VerificationResult<StoreKit.Transaction>) async {
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
    private func updateSubscriptionStatus(with transaction: StoreKit.Transaction) async {
        guard let userProfile = userProfile else {
            logger.error("Cannot update subscription status: user profile not available")
            return
        }
        
        // Get product ID and expiration date
        let productId = transaction.productID
        let expirationDate = transaction.expirationDate
        
        // Update subscription in DataStore
        await MainActor.run {
            // Check if user already has a subscription
            var subscription = userProfile.subscription
            
            if subscription == nil {
                // Create new subscription
<<<<<<< HEAD
                subscription = Subscription(context: PersistenceController.shared.container.viewContext)
                subscription?.id = UUID()
=======
                subscription = Subscription(id: UUID())
>>>>>>> 510ee9d (more changes')
                userProfile.subscription = subscription
            }
            
            // Update subscription details
            subscription?.productId = productId
            subscription?.purchaseDate = transaction.purchaseDate
            subscription?.expirationDate = expirationDate
            subscription?.isActive = true
            
            // Update published properties
            isPremium = true
            subscriptionTier = .premium
            subscriptionExpirationDate = expirationDate
<<<<<<< HEAD
            subscriptionAutoRenews = true // TODO: Implement auto-renew status check
            
            // Save user profile
            // Save to Core Data context
            try? PersistenceController.shared.container.viewContext.save()
=======
            subscriptionAutoRenews = transaction.autoRenewStatus == .willRenew
            
            // Save user profile
            DataStore.shared.saveUserProfile(userProfile)
>>>>>>> 510ee9d (more changes')
            logger.info("Updated subscription status in DataStore")
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
            for await result in StoreKit.Transaction.updates {
                // Handle transaction update
                if let self = self {
                    await self.handleTransactionUpdate(result)
                }
            }
        }
        
        logger.info("Started transaction listener")
    }
    
    /// Handle transaction update
    private func handleTransactionUpdate(_ result: VerificationResult<StoreKit.Transaction>) async {
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
        guard let userProfile = userProfile else {
            logger.error("Cannot update expired subscription: user profile not available")
            return
        }
        
        // Update subscription in DataStore
        await MainActor.run {
            // Update subscription
            if let subscription = userProfile.subscription {
                subscription.isActive = false
            }
            
            // Update published properties
            isPremium = false
            subscriptionTier = .free
            
            // Save user profile
<<<<<<< HEAD
            let profileManager = UserProfileManager()
            // Save to Core Data context
            try? PersistenceController.shared.container.viewContext.save()
=======
            DataStore.shared.saveUserProfile(userProfile)
>>>>>>> 510ee9d (more changes')
            logger.info("Updated expired subscription in DataStore")
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
                let transactions = await StoreKit.Transaction.currentEntitlements
                
<<<<<<< HEAD
                var hasTransactions = false
                for await _ in transactions {
                    hasTransactions = true
                    break
                }

                await MainActor.run {
                    if !hasTransactions {
                        // No active subscriptions found
                        isRestoring = false
                        errorMessage = "No active subscriptions found"

                        logger.info("No active subscriptions found during restore")
                        return
                    }
=======
                if transactions.isEmpty {
                    // No active subscriptions found
                    await MainActor.run {
                        isRestoring = false
                        errorMessage = "No active subscriptions found"
                        
                        logger.info("No active subscriptions found during restore")
                    }
                    return
>>>>>>> 510ee9d (more changes')
                }
                
                // Process transactions
                var hasValidSubscription = false
                
                for await result in transactions {
                    if case .verified(let transaction) = result,
                       transaction.productType == .autoRenewable,
                       let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        
                        hasValidSubscription = true
                        
                        // Update subscription status
                        await updateSubscriptionStatus(with: transaction)
                        
                        logger.info("Restored valid subscription: \(transaction.id)")
                    } else if case .unverified(_, let error) = result {
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
    
    /// Enum for premium features
    enum PremiumFeature: String, CaseIterable {
        case advancedInsights = "Advanced Insights"
        case personalizedCoaching = "Personalized Coaching"
        case unlimitedAudio = "Unlimited Audio Content"
        case premiumGoals = "Premium Goal Tracking"
        case adFree = "Ad-Free Experience"
        
        var isPremiumOnly: Bool {
            switch self {
            case .advancedInsights, .personalizedCoaching, .unlimitedAudio, .premiumGoals, .adFree:
                return true
            }
        }
    }
    
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
        
<<<<<<< HEAD
        return Int(NSDecimalNumber(decimal: savingsPercentage).doubleValue.rounded())
=======
        return Int(savingsPercentage.rounded())
>>>>>>> 510ee9d (more changes')
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
            
<<<<<<< HEAD
            logger.info("Receipt URL check: sandbox environment = \(self.isSandboxEnvironment)")
=======
            logger.info("Receipt URL check: sandbox environment = \(isSandboxEnvironment)")
>>>>>>> 510ee9d (more changes')
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
                let transactions = await StoreKit.Transaction.currentEntitlements
                
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
<<<<<<< HEAD
            self.products = [] // Mock products don't conform to Product protocol
=======
            self.products = [mockMonthlyProduct, mockYearlyProduct]
>>>>>>> 510ee9d (more changes')
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
    private class MockProduct: Identifiable {
        let id: String
        let displayName: String
        let description: String
        let price: Decimal
        let displayPrice: String
        let isFamilyShareable: Bool
        let subscriptionInfo: MockSubscriptionInfo?
        
        init(id: String, displayName: String, description: String, price: Decimal, displayPrice: String, isFamilyShareable: Bool, subscriptionPeriod: String) {
            self.id = id
            self.displayName = displayName
            self.description = description
            self.price = price
            self.displayPrice = displayPrice
            self.isFamilyShareable = isFamilyShareable
            self.subscriptionInfo = MockSubscriptionInfo(subscriptionPeriod: subscriptionPeriod)
        }
        
        func purchase(options: Set<Product.PurchaseOption> = []) async throws -> Product.PurchaseResult {
<<<<<<< HEAD
            // Simulate purchase success - this is just a mock for testing
            throw NSError(domain: "MockStoreError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock purchase not implemented"])
=======
            // Simulate purchase success
            return .success(MockVerificationResult())
>>>>>>> 510ee9d (more changes')
        }
    }
    
    /// Mock SubscriptionInfo for simulator
    private class MockSubscriptionInfo {
        let subscriptionPeriod: MockSubscriptionPeriod
        
        init(subscriptionPeriod: String) {
            self.subscriptionPeriod = MockSubscriptionPeriod(subscriptionPeriod)
        }
    }
    
    /// Mock SubscriptionPeriod for simulator
    private class MockSubscriptionPeriod {
        let unit: String
        let value: Int
        
        init(_ unit: String) {
            self.unit = unit
            self.value = 1
        }
    }
    
    /// Mock VerificationResult for simulator
    private struct MockVerificationResult {
        // This is a simplified mock that doesn't actually verify anything
        // It's just for testing UI flows in the simulator

        var jwsRepresentation: String {
            return "mock_jws_representation"
        }
    }
}

// MARK: - StoreKit Extensions

extension Product.SubscriptionPeriod.Unit: @retroactive Identifiable {
    public var id: Int {
        switch self {
        case .day: return 0
        case .week: return 1
        case .month: return 2
        case .year: return 3
<<<<<<< HEAD
=======
        @unknown default: return 999
>>>>>>> 510ee9d (more changes')
        }
    }
    
    var displayName: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
<<<<<<< HEAD
=======
        @unknown default: return "unknown"
>>>>>>> 510ee9d (more changes')
        }
    }
}

extension Product.ProductType: @retroactive Identifiable {
    public var id: Int {
        switch self {
        case .consumable: return 0
        case .nonConsumable: return 1
        case .autoRenewable: return 2
        case .nonRenewable: return 3
<<<<<<< HEAD
        default: return 999
=======
        @unknown default: return 999
>>>>>>> 510ee9d (more changes')
        }
    }
    
    var displayName: String {
        switch self {
        case .consumable: return "Consumable"
        case .nonConsumable: return "Non-Consumable"
        case .autoRenewable: return "Auto-Renewable Subscription"
        case .nonRenewable: return "Non-Renewable Subscription"
<<<<<<< HEAD
        default: return "Unknown"
=======
        @unknown default: return "Unknown"
>>>>>>> 510ee9d (more changes')
        }
    }
}

// MARK: - SubscriptionTier Extension

extension SubscriptionTier {
    func hasAccess(to feature: StoreManager.PremiumFeature) -> Bool {
        switch self {
        case .free:
            return !feature.isPremiumOnly
        case .premium:
            return true
        }
    }
}
