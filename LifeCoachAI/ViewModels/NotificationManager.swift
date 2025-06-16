//
//  NotificationManager.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import UserNotifications
import SwiftUI
import CoreData
import Combine
import os.log

/// Manager class for handling all notification-related functionality
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // MARK: - Published Properties
    
    /// Whether notifications are authorized
    @Published var isNotificationsAuthorized = false
    
    /// Whether the app has requested notification permissions
    @Published var hasRequestedPermission = false
    
    /// Error message if notification setup fails
    @Published var errorMessage: String?
    
    /// Scheduled notifications
    @Published var scheduledNotifications: [UNNotificationRequest] = []
    
    /// Delivered notifications
    @Published var deliveredNotifications: [UNNotification] = []
    
    // MARK: - Private Properties
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.lifecoach.ai", category: "NotificationManager")
    
    /// Reference to the notification center
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Core Data context for accessing goals and user preferences
    private var viewContext: NSManagedObjectContext?
    
    /// User's preferred notification times
    private var preferredNotificationTimes: [String: DateComponents] = [:]
    
    /// User's notification preferences
    private var notificationPreferences: [String: Bool] = [:]
    
    /// User's do not disturb windows
    private var doNotDisturbWindows: [(start: DateComponents, end: DateComponents)] = []
    
    /// User's historical notification response patterns
    private var notificationResponsePatterns: [String: [DateComponents]] = [:]
    
    // MARK: - Notification Category Constants
    
    /// Notification category identifiers
    struct NotificationCategory {
        static let goal = "com.lifecoach.ai.notification.goal"
        static let recommendation = "com.lifecoach.ai.notification.recommendation"
        static let reminder = "com.lifecoach.ai.notification.reminder"
        static let achievement = "com.lifecoach.ai.notification.achievement"
        static let insight = "com.lifecoach.ai.notification.insight"
        static let healthAlert = "com.lifecoach.ai.notification.healthAlert"
        static let sessionStart = "com.lifecoach.ai.notification.sessionStart"
        static let streak = "com.lifecoach.ai.notification.streak"
        static let premiumOffer = "com.lifecoach.ai.notification.premiumOffer"
    }
    
    /// Notification action identifiers
    struct NotificationAction {
        static let complete = "com.lifecoach.ai.action.complete"
        static let snooze = "com.lifecoach.ai.action.snooze"
        static let skip = "com.lifecoach.ai.action.skip"
        static let view = "com.lifecoach.ai.action.view"
        static let accept = "com.lifecoach.ai.action.accept"
        static let decline = "com.lifecoach.ai.action.decline"
        static let startSession = "com.lifecoach.ai.action.startSession"
        static let reschedule = "com.lifecoach.ai.action.reschedule"
        static let subscribe = "com.lifecoach.ai.action.subscribe"
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Set this class as the notification delegate
        notificationCenter.delegate = self
        
        // Check current authorization status
        checkAuthorizationStatus()
        
        // Set up notification categories
        setupNotificationCategories()
        
        // Load user preferences
        loadUserPreferences()
        
        logger.info("NotificationManager initialized")
    }
    
    /// Set the Core Data context
    func setViewContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Authorization
    
    /// Request authorization for notifications
    func requestAuthorization() {
        // Request authorization for notifications
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .providesAppNotificationSettings]
        
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Notification authorization error: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to request notification permissions: \(error.localizedDescription)"
                } else {
                    self?.isNotificationsAuthorized = granted
                    self?.hasRequestedPermission = true
                    
                    if granted {
                        self?.logger.info("Notification authorization granted")
                        
                        // Register for remote notifications if needed
                        // UNUserNotificationCenter.current().registerForRemoteNotifications()
                        
                        // Load scheduled notifications
                        self?.loadScheduledNotifications()
                    } else {
                        self?.logger.warning("Notification authorization denied")
                    }
                }
            }
        }
    }
    
    /// Check the current authorization status
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self?.isNotificationsAuthorized = true
                    self?.hasRequestedPermission = true
                    self?.loadScheduledNotifications()
                case .denied:
                    self?.isNotificationsAuthorized = false
                    self?.hasRequestedPermission = true
                case .notDetermined:
                    self?.isNotificationsAuthorized = false
                    self?.hasRequestedPermission = false
                @unknown default:
                    self?.isNotificationsAuthorized = false
                }
            }
        }
    }
    
    /// Set up notification categories and actions
    private func setupNotificationCategories() {
        // Goal notification actions
        let completeAction = UNNotificationAction(
            identifier: NotificationAction.complete,
            title: "Complete",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: "Snooze",
            options: .authenticationRequired
        )
        
        let skipAction = UNNotificationAction(
            identifier: NotificationAction.skip,
            title: "Skip",
            options: .destructive
        )
        
        // Recommendation notification actions
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.view,
            title: "View",
            options: .foreground
        )
        
        let acceptAction = UNNotificationAction(
            identifier: NotificationAction.accept,
            title: "Accept",
            options: .foreground
        )
        
        let declineAction = UNNotificationAction(
            identifier: NotificationAction.decline,
            title: "Decline",
            options: .destructive
        )
        
        // Session notification actions
        let startSessionAction = UNNotificationAction(
            identifier: NotificationAction.startSession,
            title: "Start Now",
            options: .foreground
        )
        
        let rescheduleAction = UNNotificationAction(
            identifier: NotificationAction.reschedule,
            title: "Reschedule",
            options: .authenticationRequired
        )
        
        // Premium offer notification actions
        let subscribeAction = UNNotificationAction(
            identifier: NotificationAction.subscribe,
            title: "Subscribe",
            options: .foreground
        )
        
        // Create categories
        let goalCategory = UNNotificationCategory(
            identifier: NotificationCategory.goal,
            actions: [completeAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let recommendationCategory = UNNotificationCategory(
            identifier: NotificationCategory.recommendation,
            actions: [viewAction, acceptAction, declineAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.reminder,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: NotificationCategory.achievement,
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let insightCategory = UNNotificationCategory(
            identifier: NotificationCategory.insight,
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let healthAlertCategory = UNNotificationCategory(
            identifier: NotificationCategory.healthAlert,
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let sessionStartCategory = UNNotificationCategory(
            identifier: NotificationCategory.sessionStart,
            actions: [startSessionAction, rescheduleAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streak,
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let premiumOfferCategory = UNNotificationCategory(
            identifier: NotificationCategory.premiumOffer,
            actions: [subscribeAction, declineAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            goalCategory,
            recommendationCategory,
            reminderCategory,
            achievementCategory,
            insightCategory,
            healthAlertCategory,
            sessionStartCategory,
            streakCategory,
            premiumOfferCategory
        ])
    }
    
    // MARK: - Notification Management
    
    /// Load currently scheduled notifications
    func loadScheduledNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.scheduledNotifications = requests
                self?.logger.info("Loaded \(requests.count) scheduled notifications")
            }
        }
        
        notificationCenter.getDeliveredNotifications { [weak self] notifications in
            DispatchQueue.main.async {
                self?.deliveredNotifications = notifications
                self?.logger.info("Loaded \(notifications.count) delivered notifications")
            }
        }
    }
    
    /// Remove all scheduled notifications
    func removeAllScheduledNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        DispatchQueue.main.async {
            self.scheduledNotifications = []
            self.deliveredNotifications = []
            self.logger.info("Removed all scheduled and delivered notifications")
        }
    }
    
    /// Remove specific scheduled notifications
    func removeScheduledNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        
        // Update the cached lists
        loadScheduledNotifications()
    }
    
    // MARK: - Goal Notifications
    
    /// Schedule a notification for a goal
    func scheduleGoalNotification(
        goalId: UUID,
        title: String,
        body: String,
        categoryIdentifier: String = NotificationCategory.goal,
        triggerDate: Date,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule goal notification but notifications aren't authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["goalId"] = goalId.uuidString
        combinedUserInfo["notificationType"] = "goal"
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set badge number if needed
        // content.badge = 1
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Create trigger
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: adjustNotificationTime(triggerDate, for: goalId.uuidString)
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create request
        let identifier = "goal-\(goalId.uuidString)-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling goal notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled goal notification for \(title) at \(triggerDate)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
                
                // Log the notification for analytics
                self?.logScheduledNotification(
                    type: "goal",
                    identifier: identifier,
                    title: title,
                    scheduledFor: triggerDate
                )
            }
        }
    }
    
    /// Schedule a recurring goal notification
    func scheduleRecurringGoalNotification(
        goalId: UUID,
        title: String,
        body: String,
        categoryIdentifier: String = NotificationCategory.goal,
        frequency: GoalFrequency,
        timeComponents: DateComponents,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule recurring goal notification but notifications aren't authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["goalId"] = goalId.uuidString
        combinedUserInfo["notificationType"] = "recurringGoal"
        combinedUserInfo["frequency"] = frequency.rawValue
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Create trigger based on frequency
        var trigger: UNNotificationTrigger
        
        switch frequency {
        case .daily:
            // Daily at the specified time
            var components = timeComponents
            components.hour = adjustTimeComponentForPreference(components.hour, preference: "dailyReminder")
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekdays:
            // Schedule individual notifications for each weekday
            for weekday in 2...6 { // Monday = 2, Friday = 6
                var components = timeComponents
                components.weekday = weekday
                components.hour = adjustTimeComponentForPreference(components.hour, preference: "weekdayReminder")
                
                let weekdayTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                let identifier = "goal-\(goalId.uuidString)-weekday-\(weekday)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: weekdayTrigger)
                
                notificationCenter.add(request) { [weak self] error in
                    if let error = error {
                        self?.logger.error("Error scheduling weekday notification: \(error.localizedDescription)")
                    }
                }
            }
            return
            
        case .weekends:
            // Schedule individual notifications for weekend days
            for weekday in [1, 7] { // Sunday = 1, Saturday = 7
                var components = timeComponents
                components.weekday = weekday
                components.hour = adjustTimeComponentForPreference(components.hour, preference: "weekendReminder")
                
                let weekendTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                let identifier = "goal-\(goalId.uuidString)-weekend-\(weekday)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: weekendTrigger)
                
                notificationCenter.add(request) { [weak self] error in
                    if let error = error {
                        self?.logger.error("Error scheduling weekend notification: \(error.localizedDescription)")
                    }
                }
            }
            return
            
        case .weekly:
            // Weekly on a specific day
            var components = timeComponents
            components.weekday = components.weekday ?? 2 // Default to Monday if not specified
            components.hour = adjustTimeComponentForPreference(components.hour, preference: "weeklyReminder")
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .monthly:
            // Monthly on a specific day
            var components = timeComponents
            components.day = components.day ?? 1 // Default to 1st of month if not specified
            components.hour = adjustTimeComponentForPreference(components.hour, preference: "monthlyReminder")
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .custom:
            // For custom, we'll need to schedule individual notifications
            // This is just a placeholder - in a real app, you'd handle this differently
            var components = timeComponents
            components.hour = adjustTimeComponentForPreference(components.hour, preference: "customReminder")
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        // Create request
        let identifier = "goal-\(goalId.uuidString)-recurring"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling recurring goal notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled recurring goal notification for \(title) with frequency \(frequency.rawValue)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
            }
        }
    }
    
    // MARK: - Recommendation Notifications
    
    /// Schedule a notification for an AI recommendation
    func scheduleRecommendationNotification(
        recommendationId: UUID,
        title: String,
        body: String,
        category: GoalCategory,
        triggerDate: Date? = nil,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule recommendation notification but notifications aren't authorized")
            return
        }
        
        // Check if this category is enabled in user preferences
        if let categoryEnabled = notificationPreferences["recommendation_\(category.rawValue)"], !categoryEnabled {
            logger.info("Skipping recommendation notification for disabled category: \(category.rawValue)")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.recommendation
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["recommendationId"] = recommendationId.uuidString
        combinedUserInfo["notificationType"] = "recommendation"
        combinedUserInfo["category"] = category.rawValue
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Create trigger
        let trigger: UNNotificationTrigger
        
        if let triggerDate = triggerDate {
            // Schedule for a specific time
            let adjustedDate = adjustNotificationTime(triggerDate, for: "recommendation_\(category.rawValue)")
            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: adjustedDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        } else {
            // Schedule for immediate delivery (with a small delay)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        }
        
        // Create request
        let identifier = "recommendation-\(recommendationId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling recommendation notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled recommendation notification for \(title)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
                
                // Log the notification for analytics
                self?.logScheduledNotification(
                    type: "recommendation",
                    identifier: identifier,
                    title: title,
                    scheduledFor: triggerDate ?? Date().addingTimeInterval(2)
                )
            }
        }
    }
    
    /// Schedule daily recommendation notifications based on AI analysis
    func scheduleDailyRecommendationNotifications() {
        guard let context = viewContext else {
            logger.error("Cannot schedule daily recommendations: Core Data context not available")
            return
        }
        
        // Fetch active recommendations that haven't been notified yet
        let fetchRequest: NSFetchRequest<Recommendation> = Recommendation.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status == %@", "active"),
            NSPredicate(format: "isViewed == %@", NSNumber(value: false))
        ])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
        
        do {
            let recommendations = try context.fetch(fetchRequest)
            logger.info("Found \(recommendations.count) active recommendations to schedule")
            
            // Schedule notifications for high priority recommendations
            let highPriorityRecommendations = recommendations.filter { $0.priority >= 2 }
            
            for recommendation in highPriorityRecommendations {
                guard let id = recommendation.id,
                      let title = recommendation.title,
                      let description = recommendation.desc,
                      let category = recommendation.category else { continue }
                
                // Determine the best time to show this notification
                let triggerDate = recommendation.recommendedTime ?? findOptimalNotificationTime(for: category)
                
                // Schedule the notification
                scheduleRecommendationNotification(
                    recommendationId: id,
                    title: title,
                    body: description,
                    category: GoalCategory(rawValue: category) ?? .other,
                    triggerDate: triggerDate,
                    userInfo: [
                        "priority": recommendation.priority,
                        "category": category
                    ],
                    importance: recommendation.priority >= 3 ? .timeSensitive : .active
                )
                
                // Mark as notified in Core Data
                recommendation.isViewed = true
            }
            
            // Save context
            try context.save()
            
        } catch {
            logger.error("Error fetching recommendations: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Health Alert Notifications
    
    /// Schedule a health alert notification based on HealthKit data
    func scheduleHealthAlertNotification(
        alertType: String,
        title: String,
        body: String,
        metricType: HealthMetricType,
        value: Double,
        triggerDate: Date? = nil,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .timeSensitive
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule health alert but notifications aren't authorized")
            return
        }
        
        // Check if health alerts are enabled
        if let healthAlertsEnabled = notificationPreferences["healthAlerts"], !healthAlertsEnabled {
            logger.info("Skipping health alert notification: health alerts are disabled")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.healthAlert
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["alertType"] = alertType
        combinedUserInfo["notificationType"] = "healthAlert"
        combinedUserInfo["metricType"] = metricType.rawValue
        combinedUserInfo["value"] = value
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Create trigger
        let trigger: UNNotificationTrigger
        
        if let triggerDate = triggerDate {
            // Schedule for a specific time
            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        } else {
            // Schedule for immediate delivery (with a small delay)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        // Create request
        let identifier = "healthAlert-\(alertType)-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling health alert notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled health alert notification for \(title)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
            }
        }
    }
    
    // MARK: - Achievement Notifications
    
    /// Schedule a notification for an achievement
    func scheduleAchievementNotification(
        achievementId: UUID,
        title: String,
        body: String,
        badgeImageName: String? = nil,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule achievement notification but notifications aren't authorized")
            return
        }
        
        // Check if achievement notifications are enabled
        if let achievementsEnabled = notificationPreferences["achievements"], !achievementsEnabled {
            logger.info("Skipping achievement notification: achievements are disabled")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.achievement
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["achievementId"] = achievementId.uuidString
        combinedUserInfo["notificationType"] = "achievement"
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        if let badgeImageName = badgeImageName {
            combinedUserInfo["badgeImageName"] = badgeImageName
        }
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Add image attachment if available
        if let badgeImageName = badgeImageName, 
           let imageURL = Bundle.main.url(forResource: badgeImageName, withExtension: "png") {
            do {
                let attachment = try UNNotificationAttachment(identifier: badgeImageName, url: imageURL, options: nil)
                content.attachments = [attachment]
            } catch {
                logger.error("Error attaching image to achievement notification: \(error.localizedDescription)")
            }
        }
        
        // Create trigger for immediate delivery (with a small delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let identifier = "achievement-\(achievementId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling achievement notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled achievement notification for \(title)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
            }
        }
    }
    
    // MARK: - Session Notifications
    
    /// Schedule a notification for an audio session
    func scheduleSessionNotification(
        sessionId: UUID,
        title: String,
        body: String,
        category: AudioCategory,
        scheduledTime: Date,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule session notification but notifications aren't authorized")
            return
        }
        
        // Check if session reminders are enabled for this category
        if let sessionRemindersEnabled = notificationPreferences["session_\(category.rawValue)"], !sessionRemindersEnabled {
            logger.info("Skipping session notification for disabled category: \(category.rawValue)")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.sessionStart
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["sessionId"] = sessionId.uuidString
        combinedUserInfo["notificationType"] = "session"
        combinedUserInfo["category"] = category.rawValue
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Create trigger
        let adjustedTime = adjustNotificationTime(scheduledTime, for: "session_\(category.rawValue)")
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: adjustedTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create request
        let identifier = "session-\(sessionId.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling session notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled session notification for \(title) at \(scheduledTime)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
                
                // Log the notification for analytics
                self?.logScheduledNotification(
                    type: "session",
                    identifier: identifier,
                    title: title,
                    scheduledFor: adjustedTime
                )
            }
        }
    }
    
    // MARK: - Streak Notifications
    
    /// Schedule a notification for a streak milestone
    func scheduleStreakNotification(
        streakId: UUID,
        streakCount: Int,
        category: String,
        title: String,
        body: String,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule streak notification but notifications aren't authorized")
            return
        }
        
        // Check if streak notifications are enabled
        if let streaksEnabled = notificationPreferences["streaks"], !streaksEnabled {
            logger.info("Skipping streak notification: streaks are disabled")
            return
        }
        
        // Only notify for significant milestones to avoid notification fatigue
        let significantMilestones = [3, 5, 7, 10, 14, 21, 30, 50, 100, 200, 365]
        guard significantMilestones.contains(streakCount) else {
            logger.info("Skipping streak notification: \(streakCount) is not a significant milestone")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.streak
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["streakId"] = streakId.uuidString
        combinedUserInfo["notificationType"] = "streak"
        combinedUserInfo["category"] = category
        combinedUserInfo["streakCount"] = streakCount
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Find the best time to show this notification
        let triggerDate = findOptimalNotificationTime(for: category)
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create request
        let identifier = "streak-\(streakId.uuidString)-\(streakCount)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling streak notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled streak notification for \(streakCount) day streak in \(category)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
            }
        }
    }
    
    // MARK: - Premium Offer Notifications
    
    /// Schedule a notification for a premium offer
    func schedulePremiumOfferNotification(
        offerId: String,
        title: String,
        body: String,
        triggerDate: Date,
        userInfo: [String: Any] = [:],
        importance: UNNotificationInterruptionLevel = .active
    ) {
        // Don't schedule if notifications aren't authorized
        guard isNotificationsAuthorized else {
            logger.warning("Attempted to schedule premium offer notification but notifications aren't authorized")
            return
        }
        
        // Check if marketing notifications are enabled
        if let marketingEnabled = notificationPreferences["marketing"], !marketingEnabled {
            logger.info("Skipping premium offer notification: marketing notifications are disabled")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.premiumOffer
        
        // Add metadata to userInfo
        var combinedUserInfo = userInfo
        combinedUserInfo["offerId"] = offerId
        combinedUserInfo["notificationType"] = "premiumOffer"
        combinedUserInfo["scheduledAt"] = Date().timeIntervalSince1970
        
        content.userInfo = combinedUserInfo
        
        // Set interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = importance
        }
        
        // Create trigger
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create request
        let identifier = "premiumOffer-\(offerId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Error scheduling premium offer notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Scheduled premium offer notification for \(title) at \(triggerDate)")
                
                // Update the cached list
                self?.loadScheduledNotifications()
            }
        }
    }
    
    // MARK: - Notification Delegate Methods
    
    /// Called when a notification is delivered to a foreground app
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Log the notification
        logger.info("Received notification in foreground: \(notification.request.identifier)")
        
        // Extract notification data
        let userInfo = notification.request.content.userInfo
        let notificationType = userInfo["notificationType"] as? String ?? "unknown"
        
        // Log notification response for analytics
        logNotificationDelivered(
            identifier: notification.request.identifier,
            type: notificationType,
            userInfo: userInfo
        )
        
        // Determine how to present the notification
        var presentationOptions: UNNotificationPresentationOptions = []
        
        if #available(iOS 14.0, *) {
            // For iOS 14+, we can use more granular presentation options
            
            // High priority notifications show banner, sound, and badge
            if notificationType == "healthAlert" || 
               (notificationType == "recommendation" && (userInfo["priority"] as? Int ?? 0) >= 3) {
                presentationOptions = [.banner, .sound, .badge, .list]
            }
            // Medium priority show banner and list
            else if notificationType == "goal" || notificationType == "streak" {
                presentationOptions = [.banner, .sound, .list]
            }
            // Low priority just show in notification center
            else {
                presentationOptions = [.list]
            }
        } else {
            // For iOS 13 and earlier
            presentationOptions = [.alert, .sound, .badge]
        }
        
        // Complete with the determined presentation options
        completionHandler(presentationOptions)
    }
    
    /// Called when the user responds to a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Extract notification data
        let userInfo = response.notification.request.content.userInfo
        let notificationType = userInfo["notificationType"] as? String ?? "unknown"
        let actionIdentifier = response.actionIdentifier
        
        logger.info("User responded to notification: \(response.notification.request.identifier) with action: \(actionIdentifier)")
        
        // Log notification response for analytics
        logNotificationResponse(
            identifier: response.notification.request.identifier,
            type: notificationType,
            actionIdentifier: actionIdentifier,
            userInfo: userInfo
        )
        
        // Handle different notification types and actions
        switch notificationType {
        case "goal":
            handleGoalNotificationResponse(response, userInfo: userInfo)
            
        case "recommendation":
            handleRecommendationNotificationResponse(response, userInfo: userInfo)
            
        case "healthAlert":
            handleHealthAlertNotificationResponse(response, userInfo: userInfo)
            
        case "achievement":
            handleAchievementNotificationResponse(response, userInfo: userInfo)
            
        case "session":
            handleSessionNotificationResponse(response, userInfo: userInfo)
            
        case "streak":
            handleStreakNotificationResponse(response, userInfo: userInfo)
            
        case "premiumOffer":
            handlePremiumOfferNotificationResponse(response, userInfo: userInfo)
            
        default:
            logger.warning("Unknown notification type: \(notificationType)")
        }
        
        // Update notification response patterns for personalization
        updateNotificationResponsePatterns(for: notificationType, actionIdentifier: actionIdentifier)
        
        // Complete handling
        completionHandler()
    }
    
    // MARK: - Notification Response Handlers
    
    /// Handle response to a goal notification
    private func handleGoalNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        guard let goalIdString = userInfo["goalId"] as? String,
              let goalId = UUID(uuidString: goalIdString) else {
            logger.error("Invalid goal ID in notification")
            return
        }
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.complete:
            logger.info("User completed goal: \(goalId)")
            
            // Mark goal as completed in Core Data
            markGoalAsCompleted(goalId: goalId)
            
            // Post notification for UI update
            NotificationCenter.default.post(
                name: NSNotification.Name("GoalCompletedFromNotification"),
                object: nil,
                userInfo: ["goalId": goalId]
            )
            
        case NotificationAction.snooze:
            logger.info("User snoozed goal: \(goalId)")
            
            // Reschedule notification for later
            rescheduleGoalNotification(goalId: goalId, minutes: 30)
            
        case NotificationAction.skip:
            logger.info("User skipped goal: \(goalId)")
            
            // Mark goal as skipped in Core Data
            markGoalAsSkipped(goalId: goalId)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped goal notification: \(goalId)")
            
            // Post notification to open goal details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenGoalDetails"),
                object: nil,
                userInfo: ["goalId": goalId]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed goal notification: \(goalId)")
            
        default:
            logger.warning("Unknown action for goal notification: \(response.actionIdentifier)")
        }
    }
    
    /// Handle response to a recommendation notification
    private func handleRecommendationNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        guard let recommendationIdString = userInfo["recommendationId"] as? String,
              let recommendationId = UUID(uuidString: recommendationIdString) else {
            logger.error("Invalid recommendation ID in notification")
            return
        }
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.view:
            logger.info("User viewed recommendation: \(recommendationId)")
            
            // Mark recommendation as viewed in Core Data
            markRecommendationAsViewed(recommendationId: recommendationId)
            
            // Post notification to open recommendation details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenRecommendationDetails"),
                object: nil,
                userInfo: ["recommendationId": recommendationId]
            )
            
        case NotificationAction.accept:
            logger.info("User accepted recommendation: \(recommendationId)")
            
            // Mark recommendation as accepted in Core Data
            markRecommendationAsAccepted(recommendationId: recommendationId)
            
            // Post notification for UI update
            NotificationCenter.default.post(
                name: NSNotification.Name("RecommendationAccepted"),
                object: nil,
                userInfo: ["recommendationId": recommendationId]
            )
            
        case NotificationAction.decline:
            logger.info("User declined recommendation: \(recommendationId)")
            
            // Mark recommendation as declined in Core Data
            markRecommendationAsDeclined(recommendationId: recommendationId)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped recommendation notification: \(recommendationId)")
            
            // Mark recommendation as viewed in Core Data
            markRecommendationAsViewed(recommendationId: recommendationId)
            
            // Post notification to open recommendation details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenRecommendationDetails"),
                object: nil,
                userInfo: ["recommendationId": recommendationId]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed recommendation notification: \(recommendationId)")
            
        default:
            logger.warning("Unknown action for recommendation notification: \(response.actionIdentifier)")
        }
    }
    
    /// Handle response to a health alert notification
    private func handleHealthAlertNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        let alertType = userInfo["alertType"] as? String ?? "unknown"
        let metricTypeString = userInfo["metricType"] as? String ?? "unknown"
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.view:
            logger.info("User viewed health alert: \(alertType)")
            
            // Post notification to open health details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenHealthDetails"),
                object: nil,
                userInfo: [
                    "alertType": alertType,
                    "metricType": metricTypeString
                ]
            )
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped health alert notification: \(alertType)")
            
            // Post notification to open health details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenHealthDetails"),
                object: nil,
                userInfo: [
                    "alertType": alertType,
                    "metricType": metricTypeString
                ]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed health alert notification: \(alertType)")
            
        default:
            logger.warning("Unknown action for health alert notification: \(response.actionIdentifier)")
        }
    }
    
    /// Handle response to an achievement notification
    private func handleAchievementNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        guard let achievementIdString = userInfo["achievementId"] as? String,
              let achievementId = UUID(uuidString: achievementIdString) else {
            logger.error("Invalid achievement ID in notification")
            return
        }
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.view:
            logger.info("User viewed achievement: \(achievementId)")
            
            // Post notification to open achievement details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenAchievementDetails"),
                object: nil,
                userInfo: ["achievementId": achievementId]
            )
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped achievement notification: \(achievementId)")
            
            // Post notification to open achievement details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenAchievementDetails"),
                object: nil,
                userInfo: ["achievementId": achievementId]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed achievement notification: \(achievementId)")
            
        default:
            logger.warning("Unknown action for achievement notification: \(response.actionIdentifier)")
        }
    }
    
    /// Handle response to a session notification
    private func handleSessionNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        guard let sessionIdString = userInfo["sessionId"] as? String,
              let sessionId = UUID(uuidString: sessionIdString) else {
            logger.error("Invalid session ID in notification")
            return
        }
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.startSession:
            logger.info("User started session: \(sessionId)")
            
            // Post notification to start the session
            NotificationCenter.default.post(
                name: NSNotification.Name("StartAudioSession"),
                object: nil,
                userInfo: ["sessionId": sessionId]
            )
            
        case NotificationAction.reschedule:
            logger.info("User rescheduled session: \(sessionId)")
            
            // Post notification to open reschedule UI
            NotificationCenter.default.post(
                name: NSNotification.Name("RescheduleAudioSession"),
                object: nil,
                userInfo: ["sessionId": sessionId]
            )
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped session notification: \(sessionId)")
            
            // Post notification to open session details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenAudioSessionDetails"),
                object: nil,
                userInfo: ["sessionId": sessionId]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed session notification: \(sessionId)")
            
        default:
            logger.warning("Unknown action for session notification: \(response.actionIdentifier)")
        }
    }
    
    /// Handle response to a streak notification
    private func handleStreakNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        guard let streakIdString = userInfo["streakId"] as? String,
              let streakId = UUID(uuidString: streakIdString) else {
            logger.error("Invalid streak ID in notification")
            return
        }
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.view:
            logger.info("User viewed streak: \(streakId)")
            
            // Post notification to open streak details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenStreakDetails"),
                object: nil,
                userInfo: ["streakId": streakId]
            )
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped streak notification: \(streakId)")
            
            // Post notification to open streak details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenStreakDetails"),
                object: nil,
                userInfo: ["streakId": streakId]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed streak notification: \(streakId)")
            
        default:
            logger.warning("Unknown action for streak notification: \(response.actionIdentifier)")
        }
    }
    
    /// Handle response to a premium offer notification
    private func handlePremiumOfferNotificationResponse(_ response: UNNotificationResponse, userInfo: [String: Any]) {
        let offerId = userInfo["offerId"] as? String ?? "unknown"
        
        // Handle different actions
        switch response.actionIdentifier {
        case NotificationAction.subscribe:
            logger.info("User tapped subscribe from premium offer: \(offerId)")
            
            // Post notification to open subscription UI
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenSubscriptionUI"),
                object: nil,
                userInfo: ["offerId": offerId]
            )
            
        case NotificationAction.decline:
            logger.info("User declined premium offer: \(offerId)")
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            logger.info("User tapped premium offer notification: \(offerId)")
            
            // Post notification to open premium offer details
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenPremiumOfferDetails"),
                object: nil,
                userInfo: ["offerId": offerId]
            )
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            logger.info("User dismissed premium offer notification: \(offerId)")
            
        default:
            logger.warning("Unknown action for premium offer notification: \(response.actionIdentifier)")
        }
    }
    
    // MARK: - Core Data Interaction Methods
    
    /// Mark a goal as completed in Core Data
    private func markGoalAsCompleted(goalId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot mark goal as completed: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            if let goal = goals.first {
                goal.isCompleted = true
                goal.completionDate = Date()
                
                // Create progress entry
                let progressEntry = GoalProgress(context: context)
                progressEntry.id = UUID()
                progressEntry.date = Date()
                progressEntry.value = goal.targetValue
                progressEntry.goal = goal
                
                // Update streak if applicable
                updateStreak(for: goal)
                
                try context.save()
                logger.info("Marked goal as completed: \(goalId)")
            } else {
                logger.warning("Goal not found: \(goalId)")
            }
        } catch {
            logger.error("Error marking goal as completed: \(error.localizedDescription)")
        }
    }
    
    /// Mark a goal as skipped in Core Data
    private func markGoalAsSkipped(goalId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot mark goal as skipped: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            if let goal = goals.first {
                // We don't mark the goal as completed, but we note that it was skipped
                goal.status = "skipped"
                
                try context.save()
                logger.info("Marked goal as skipped: \(goalId)")
            } else {
                logger.warning("Goal not found: \(goalId)")
            }
        } catch {
            logger.error("Error marking goal as skipped: \(error.localizedDescription)")
        }
    }
    
    /// Reschedule a goal notification
    private func rescheduleGoalNotification(goalId: UUID, minutes: Int) {
        guard let context = viewContext else {
            logger.error("Cannot reschedule goal notification: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            if let goal = goals.first, let title = goal.title {
                // Calculate new reminder time
                let newReminderTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
                
                // Schedule new notification
                scheduleGoalNotification(
                    goalId: goalId,
                    title: "Reminder: \(title)",
                    body: "You snoozed this reminder. It's time to complete your goal.",
                    triggerDate: newReminderTime,
                    userInfo: ["snoozed": true]
                )
                
                logger.info("Rescheduled goal notification for \(goalId) in \(minutes) minutes")
            } else {
                logger.warning("Goal not found: \(goalId)")
            }
        } catch {
            logger.error("Error rescheduling goal notification: \(error.localizedDescription)")
        }
    }
    
    /// Update streak for a goal
    private func updateStreak(for goal: Goal) {
        guard let context = viewContext,
              let goalId = goal.id,
              let category = goal.category else {
            return
        }
        
        // Find or create streak for this goal category
        let fetchRequest: NSFetchRequest<Streak> = Streak.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let streaks = try context.fetch(fetchRequest)
            
            if let streak = streaks.first {
                // Update existing streak
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let lastUpdated = calendar.startOfDay(for: streak.lastUpdatedDate ?? Date.distantPast)
                
                // Check if this is a consecutive day
                if calendar.isDate(today, inSameDayAs: lastUpdated) {
                    // Already updated today, no change
                } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                          calendar.isDate(yesterday, inSameDayAs: lastUpdated) {
                    // Yesterday, increment streak
                    streak.currentCount += 1
                    streak.lastUpdatedDate = Date()
                    
                    // Update longest streak if needed
                    if streak.currentCount > streak.longestCount {
                        streak.longestCount = streak.currentCount
                    }
                    
                    // Check if this is a milestone worth notifying about
                    if [3, 5, 7, 10, 14, 21, 30, 50, 100, 200, 365].contains(streak.currentCount) {
                        scheduleStreakNotification(
                            streakId: streak.id ?? UUID(),
                            streakCount: Int(streak.currentCount),
                            category: category,
                            title: "🔥 \(streak.currentCount) Day Streak!",
                            body: "You've maintained your \(category) streak for \(streak.currentCount) days. Keep it up!"
                        )
                    }
                } else {
                    // Streak broken, reset to 1
                    streak.currentCount = 1
                    streak.lastUpdatedDate = Date()
                }
            } else {
                // Create new streak
                let newStreak = Streak(context: context)
                newStreak.id = UUID()
                newStreak.category = category
                newStreak.currentCount = 1
                newStreak.longestCount = 1
                newStreak.startDate = Date()
                newStreak.lastUpdatedDate = Date()
                
                // Find user profile to associate with
                let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
                if let userProfile = try? context.fetch(profileRequest).first {
                    newStreak.userProfile = userProfile
                }
            }
            
            try context.save()
        } catch {
            logger.error("Error updating streak: \(error.localizedDescription)")
        }
    }
    
    /// Mark a recommendation as viewed in Core Data
    private func markRecommendationAsViewed(recommendationId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot mark recommendation as viewed: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Recommendation> = Recommendation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", recommendationId as CVarArg)
        
        do {
            let recommendations = try context.fetch(fetchRequest)
            
            if let recommendation = recommendations.first {
                recommendation.isViewed = true
                
                try context.save()
                logger.info("Marked recommendation as viewed: \(recommendationId)")
            } else {
                logger.warning("Recommendation not found: \(recommendationId)")
            }
        } catch {
            logger.error("Error marking recommendation as viewed: \(error.localizedDescription)")
        }
    }
    
    /// Mark a recommendation as accepted in Core Data
    private func markRecommendationAsAccepted(recommendationId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot mark recommendation as accepted: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Recommendation> = Recommendation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", recommendationId as CVarArg)
        
        do {
            let recommendations = try context.fetch(fetchRequest)
            
            if let recommendation = recommendations.first {
                recommendation.status = RecommendationStatus.accepted.rawValue
                recommendation.actionTaken = true
                recommendation.isViewed = true
                
                try context.save()
                logger.info("Marked recommendation as accepted: \(recommendationId)")
            } else {
                logger.warning("Recommendation not found: \(recommendationId)")
            }
        } catch {
            logger.error("Error marking recommendation as accepted: \(error.localizedDescription)")
        }
    }
    
    /// Mark a recommendation as declined in Core Data
    private func markRecommendationAsDeclined(recommendationId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot mark recommendation as declined: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Recommendation> = Recommendation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", recommendationId as CVarArg)
        
        do {
            let recommendations = try context.fetch(fetchRequest)
            
            if let recommendation = recommendations.first {
                recommendation.status = RecommendationStatus.declined.rawValue
                recommendation.actionTaken = false
                recommendation.isViewed = true
                
                try context.save()
                logger.info("Marked recommendation as declined: \(recommendationId)")
            } else {
                logger.warning("Recommendation not found: \(recommendationId)")
            }
        } catch {
            logger.error("Error marking recommendation as declined: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Preferences
    
    /// Load user notification preferences from Core Data
    private func loadUserPreferences() {
        guard let context = viewContext else {
            logger.warning("Cannot load user preferences: Core Data context not available")
            
            // Set default preferences
            setDefaultPreferences()
            return
        }
        
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if let profile = profiles.first, let preferences = profile.notificationPreferences {
                self.notificationPreferences = preferences
                logger.info("Loaded user notification preferences")
                
                // Load preferred notification times
                loadPreferredNotificationTimes(from: profile)
                
                // Load do not disturb windows
                loadDoNotDisturbWindows(from: profile)
            } else {
                logger.info("No user profile found, using default preferences")
                setDefaultPreferences()
            }
        } catch {
            logger.error("Error loading user preferences: \(error.localizedDescription)")
            setDefaultPreferences()
        }
    }
    
    /// Set default notification preferences
    private func setDefaultPreferences() {
        // Default preferences (all enabled)
        notificationPreferences = [
            "goals": true,
            "achievements": true,
            "streaks": true,
            "healthAlerts": true,
            "recommendations": true,
            "sessions": true,
            "marketing": false, // Marketing off by default
            
            // Goal categories
            "recommendation_Physical": true,
            "recommendation_Mental": true,
            "recommendation_Sleep": true,
            "recommendation_Nutrition": true,
            "recommendation_Mindfulness": true,
            "recommendation_Productivity": true,
            "recommendation_Social": true,
            
            // Audio categories
            "session_Meditation": true,
            "session_Sleep": true,
            "session_Focus": true,
            "session_Motivation": true,
            "session_Anxiety": true,
            "session_Stress": true,
            "session_Gratitude": true,
            "session_Morning": true,
            "session_Evening": true
        ]
        
        // Default preferred times
        preferredNotificationTimes = [
            "dailyReminder": DateComponents(hour: 9, minute: 0), // 9:00 AM
            "weekdayReminder": DateComponents(hour: 8, minute: 0), // 8:00 AM
            "weekendReminder": DateComponents(hour: 10, minute: 0), // 10:00 AM
            "eveningReminder": DateComponents(hour: 19, minute: 0), // 7:00 PM
            "sleepReminder": DateComponents(hour: 21, minute: 0) // 9:00 PM
        ]
        
        // Default do not disturb windows
        doNotDisturbWindows = [
            (start: DateComponents(hour: 22, minute: 0), end: DateComponents(hour: 7, minute: 0)) // 10:00 PM - 7:00 AM
        ]
    }
    
    /// Load preferred notification times from user profile
    private func loadPreferredNotificationTimes(from profile: UserProfile) {
        guard let userPreferences = profile.userPreferences as? [String: Any] else {
            return
        }
        
        if let timePreferences = userPreferences["notificationTimes"] as? [String: [Int]] {
            for (key, value) in timePreferences {
                if value.count >= 2 {
                    preferredNotificationTimes[key] = DateComponents(hour: value[0], minute: value[1])
                }
            }
        }
    }
    
    /// Load do not disturb windows from user profile
    private func loadDoNotDisturbWindows(from profile: UserProfile) {
        guard let userPreferences = profile.userPreferences as? [String: Any] else {
            return
        }
        
        if let dndWindows = userPreferences["doNotDisturbWindows"] as? [[String: [Int]]] {
            var windows: [(start: DateComponents, end: DateComponents)] = []
            
            for window in dndWindows {
                if let start = window["start"], let end = window["end"],
                   start.count >= 2, end.count >= 2 {
                    windows.append((
                        start: DateComponents(hour: start[0], minute: start[1]),
                        end: DateComponents(hour: end[0], minute: end[1])
                    ))
                }
            }
            
            if !windows.isEmpty {
                doNotDisturbWindows = windows
            }
        }
    }
    
    /// Update notification preferences
    func updateNotificationPreferences(_ preferences: [String: Bool]) {
        guard let context = viewContext else {
            logger.error("Cannot update notification preferences: Core Data context not available")
            return
        }
        
        // Update in-memory preferences
        for (key, value) in preferences {
            notificationPreferences[key] = value
        }
        
        // Update in Core Data
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if let profile = profiles.first {
                profile.notificationPreferences = notificationPreferences
                try context.save()
                logger.info("Updated notification preferences")
            } else {
                logger.warning("No user profile found to update notification preferences")
            }
        } catch {
            logger.error("Error updating notification preferences: \(error.localizedDescription)")
        }
    }
    
    /// Update preferred notification time
    func updatePreferredNotificationTime(key: String, hour: Int, minute: Int) {
        guard let context = viewContext else {
            logger.error("Cannot update preferred notification time: Core Data context not available")
            return
        }
        
        // Update in-memory preference
        preferredNotificationTimes[key] = DateComponents(hour: hour, minute: minute)
        
        // Update in Core Data
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if let profile = profiles.first {
                var userPreferences = profile.userPreferences as? [String: Any] ?? [:]
                var timePreferences = userPreferences["notificationTimes"] as? [String: [Int]] ?? [:]
                
                timePreferences[key] = [hour, minute]
                userPreferences["notificationTimes"] = timePreferences
                
                profile.userPreferences = userPreferences as NSObject
                
                try context.save()
                logger.info("Updated preferred notification time for \(key): \(hour):\(minute)")
            } else {
                logger.warning("No user profile found to update preferred notification time")
            }
        } catch {
            logger.error("Error updating preferred notification time: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Smart Notification Timing
    
    /// Find the optimal time to show a notification based on user patterns
    private func findOptimalNotificationTime(for category: String) -> Date {
        // Start with a default time (now + 1 hour)
        var optimalTime = Date().addingTimeInterval(3600)
        
        // Check if we have response patterns for this category
        if let patterns = notificationResponsePatterns[category], !patterns.isEmpty {
            // Calculate the most common hour from patterns
            var hourFrequency: [Int: Int] = [:]
            
            for components in patterns {
                if let hour = components.hour {
                    hourFrequency[hour, default: 0] += 1
                }
            }
            
            // Find the hour with the highest frequency
            if let (optimalHour, _) = hourFrequency.max(by: { $0.value < $1.value }) {
                // Create a date for today at the optimal hour
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = optimalHour
                components.minute = 0
                
                if let date = Calendar.current.date(from: components) {
                    optimalTime = date
                    
                    // If the optimal time is in the past, schedule for tomorrow
                    if optimalTime < Date() {
                        optimalTime = Calendar.current.date(byAdding: .day, value: 1, to: optimalTime) ?? optimalTime
                    }
                }
            }
        } else {
            // No patterns yet, use preferred time if available
            let key = "recommendation_\(category)"
            if let preferredTime = preferredNotificationTimes[key] {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = preferredTime.hour
                components.minute = preferredTime.minute
                
                if let date = Calendar.current.date(from: components) {
                    optimalTime = date
                    
                    // If the optimal time is in the past, schedule for tomorrow
                    if optimalTime < Date() {
                        optimalTime = Calendar.current.date(byAdding: .day, value: 1, to: optimalTime) ?? optimalTime
                    }
                }
            }
        }
        
        // Check if the time falls within a do not disturb window
        if isInDoNotDisturbWindow(optimalTime) {
            // Adjust to the end of the do not disturb window
            optimalTime = adjustForDoNotDisturb(optimalTime)
        }
        
        return optimalTime
    }
    
    /// Adjust notification time based on user preferences and patterns
    private func adjustNotificationTime(_ date: Date, for identifier: String) -> Date {
        // If the date is in the past, use now + 1 minute
        if date < Date() {
            return Date().addingTimeInterval(60)
        }
        
        // Check if the time falls within a do not disturb window
        if isInDoNotDisturbWindow(date) {
            // Adjust to the end of the do not disturb window
            return adjustForDoNotDisturb(date)
        }
        
        // If we have response patterns for this identifier, use them
        if let patterns = notificationResponsePatterns[identifier], !patterns.isEmpty {
            // Find the most successful hour
            var successRates: [Int: Double] = [:]
            var responseCounts: [Int: Int] = [:]
            
            for components in patterns {
                if let hour = components.hour {
                    responseCounts[hour, default: 0] += 1
                }
            }
            
            // Calculate success rate (for now, just use frequency)
            for (hour, count) in responseCounts {
                successRates[hour] = Double(count) / Double(patterns.count)
            }
            
            // Find the hour with the highest success rate
            if let (bestHour, _) = successRates.max(by: { $0.value < $1.value }) {
                // Create a date for today at the best hour
                var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                components.hour = bestHour
                components.minute = 0
                
                if let adjustedDate = Calendar.current.date(from: components) {
                    // If the adjusted time is in the past, use the original time
                    if adjustedDate > Date() {
                        return adjustedDate
                    }
                }
            }
        }
        
        // If no patterns or the pattern-based time is in the past, return the original date
        return date
    }
    
    /// Adjust time component based on user preference
    private func adjustTimeComponentForPreference(_ hour: Int?, preference: String) -> Int? {
        if let preferredTime = preferredNotificationTimes[preference] {
            return preferredTime.hour
        }
        return hour
    }
    
    /// Check if a date falls within a do not disturb window
    private func isInDoNotDisturbWindow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        for window in doNotDisturbWindows {
            let startHour = window.start.hour ?? 0
            let startMinute = window.start.minute ?? 0
            let endHour = window.end.hour ?? 23
            let endMinute = window.end.minute ?? 59

            let currentTime = hour * 60 + minute
            let startTime = startHour * 60 + startMinute
            let endTime = endHour * 60 + endMinute

            if startTime <= endTime {
                // Same day window
                if currentTime >= startTime && currentTime <= endTime {
                    return true
                }
            } else {
                // Overnight window (crosses midnight)
                if currentTime >= startTime || currentTime <= endTime {
                    return true
                }
            }
        }

        return false
    }
}