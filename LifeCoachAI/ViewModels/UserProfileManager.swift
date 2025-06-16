//
//  UserProfileManager.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import SwiftUI
import CoreData
import Combine
import os.log

/// Manager class for handling user profile data, preferences, and analytics
class UserProfileManager: ObservableObject {
    // MARK: - Published Properties
    
    /// User profile data
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var birthDate: Date?
    @Published var gender: String = ""
    @Published var height: Double = 0
    @Published var weight: Double = 0
    @Published var profileImage: UIImage?
    
    /// Onboarding status
    @Published var hasCompletedOnboarding = false
    @Published var onboardingProgress: Double = 0
    @Published var currentOnboardingStep = 0
    
    /// User preferences
    @Published var preferredCategories: [GoalCategory] = []
    @Published var preferredAudioCategories: [AudioCategory] = []
    @Published var notificationPreferences: [String: Bool] = [:]
    @Published var themePreference: String = "system" // system, light, dark
    @Published var measurementSystem: String = "metric" // metric, imperial
    
    /// User goals and progress
    @Published var activeGoals: [GoalViewModel] = []
    @Published var completedGoals: [GoalViewModel] = []
    @Published var goalCompletionRate: Double = 0
    @Published var streakData: [String: Int] = [:]
    @Published var longestStreak: Int = 0
    
    /// User analytics
    @Published var totalSessionsCompleted: Int = 0
    @Published var totalMindfulMinutes: Double = 0
    @Published var totalActiveMinutes: Double = 0
    @Published var weeklyActivitySummary: [Date: Double] = [:]
    @Published var monthlyProgressData: [String: [Double]] = [:]
    
    /// Error handling
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.lifecoach.ai", category: "UserProfileManager")
    
    /// Core Data context for persisting user data
    private var viewContext: NSManagedObjectContext?
    
    /// Current user profile
    private var userProfile: UserProfile?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Analytics update task
    private var analyticsUpdateTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init() {
        logger.info("Initializing UserProfileManager")
        
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
        
        // Load user goals
        loadUserGoals()
        
        // Load analytics data
        loadAnalyticsData()
    }
    
    // MARK: - User Profile Management
    
    /// Load user profile from Core Data
    private func loadUserProfile() {
        guard let context = viewContext else {
            logger.error("Cannot load user profile: Core Data context not available")
            return
        }
        
        isLoading = true
        
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if let profile = profiles.first {
                // Found existing profile
                userProfile = profile
                
                // Update published properties
                firstName = profile.firstName ?? ""
                lastName = profile.lastName ?? ""
                email = profile.email ?? ""
                birthDate = profile.birthDate
                gender = profile.gender ?? ""
                height = profile.height
                weight = profile.weight
                
                // Load profile image if available
                if let imageData = profile.profileImageData {
                    profileImage = UIImage(data: imageData)
                }
                
                // Load preferences
                loadUserPreferences(from: profile)
                
                // Check onboarding status
                hasCompletedOnboarding = profile.isOnboarded
                
                logger.info("Loaded existing user profile")
            } else {
                // No profile found, create new one
                createNewUserProfile(in: context)
            }
            
            isLoading = false
        } catch {
            logger.error("Failed to fetch user profile: \(error.localizedDescription)")
            errorMessage = "Failed to load user profile"
            isLoading = false
        }
    }
    
    /// Create new user profile
    private func createNewUserProfile(in context: NSManagedObjectContext) {
        let newProfile = UserProfile(context: context)
        newProfile.id = UUID()
        newProfile.creationDate = Date()
        newProfile.isOnboarded = false
        newProfile.isPremium = false
        
        // Set default preferences
        let defaultPreferences: [String: Any] = [
            "notificationTimes": [
                "morning": [8, 0],
                "afternoon": [12, 0],
                "evening": [18, 0]
            ],
            "theme": "system",
            "measurementSystem": "metric",
            "doNotDisturbWindows": [
                ["start": [22, 0], "end": [7, 0]]
            ]
        ]
        
        newProfile.userPreferences = defaultPreferences as NSObject
        
        // Set default notification preferences
        let defaultNotificationPreferences: [String: Bool] = [
            "goals": true,
            "achievements": true,
            "streaks": true,
            "healthAlerts": true,
            "recommendations": true,
            "sessions": true,
            "marketing": false
        ]
        
        newProfile.notificationPreferences = defaultNotificationPreferences
        
        // Save context
        do {
            try context.save()
            userProfile = newProfile
            hasCompletedOnboarding = false
            
            // Set default preferences in published properties
            themePreference = "system"
            measurementSystem = "metric"
            notificationPreferences = defaultNotificationPreferences
            
            logger.info("Created new user profile")
        } catch {
            logger.error("Failed to create new user profile: \(error.localizedDescription)")
            errorMessage = "Failed to create user profile"
        }
    }
    
    /// Load user preferences from profile
    private func loadUserPreferences(from profile: UserProfile) {
        // Load preferred categories
        if let categories = profile.preferredAudioCategories as? [String] {
            preferredAudioCategories = categories.compactMap { AudioCategory(rawValue: $0) }
        }
        
        // Load notification preferences
        if let preferences = profile.notificationPreferences {
            notificationPreferences = preferences
        }
        
        // Load user preferences
        if let preferences = profile.userPreferences as? [String: Any] {
            // Theme preference
            if let theme = preferences["theme"] as? String {
                themePreference = theme
            }
            
            // Measurement system
            if let system = preferences["measurementSystem"] as? String {
                measurementSystem = system
            }
            
            // Other preferences can be loaded here
        }
    }
    
    /// Update user profile
    func updateUserProfile(firstName: String? = nil, lastName: String? = nil, email: String? = nil, 
                          birthDate: Date? = nil, gender: String? = nil, height: Double? = nil, 
                          weight: Double? = nil, profileImage: UIImage? = nil) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot update user profile: Core Data context or profile not available")
            errorMessage = "Failed to update profile"
            return
        }
        
        // Update profile properties
        if let firstName = firstName {
            profile.firstName = firstName
            self.firstName = firstName
        }
        
        if let lastName = lastName {
            profile.lastName = lastName
            self.lastName = lastName
        }
        
        if let email = email {
            profile.email = email
            self.email = email
        }
        
        if let birthDate = birthDate {
            profile.birthDate = birthDate
            self.birthDate = birthDate
        }
        
        if let gender = gender {
            profile.gender = gender
            self.gender = gender
        }
        
        if let height = height {
            profile.height = height
            self.height = height
        }
        
        if let weight = weight {
            profile.weight = weight
            self.weight = weight
        }
        
        if let profileImage = profileImage {
            profile.profileImageData = profileImage.jpegData(compressionQuality: 0.8)
            self.profileImage = profileImage
        }
        
        // Save context
        do {
            try context.save()
            logger.info("Updated user profile")
        } catch {
            logger.error("Failed to update user profile: \(error.localizedDescription)")
            errorMessage = "Failed to update profile"
        }
    }
    
    /// Get user's full name
    var fullName: String {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if first.isEmpty && last.isEmpty {
            return "User"
        } else if first.isEmpty {
            return last
        } else if last.isEmpty {
            return first
        } else {
            return "\(first) \(last)"
        }
    }
    
    /// Get user's initials for avatar
    var userInitials: String {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if first.isEmpty && last.isEmpty {
            return "U"
        } else if first.isEmpty {
            return String(last.prefix(1))
        } else if last.isEmpty {
            return String(first.prefix(1))
        } else {
            return "\(first.prefix(1))\(last.prefix(1))"
        }
    }
    
    // MARK: - Onboarding Management
    
    /// Complete onboarding
    func completeOnboarding() {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot complete onboarding: Core Data context or profile not available")
            errorMessage = "Failed to complete onboarding"
            return
        }
        
        // Update profile
        profile.isOnboarded = true
        
        // Save context
        do {
            try context.save()
            hasCompletedOnboarding = true
            logger.info("Completed onboarding")
        } catch {
            logger.error("Failed to complete onboarding: \(error.localizedDescription)")
            errorMessage = "Failed to complete onboarding"
        }
    }
    
    /// Update onboarding progress
    func updateOnboardingProgress(step: Int, totalSteps: Int) {
        currentOnboardingStep = step
        onboardingProgress = Double(step) / Double(totalSteps)
    }
    
    /// Reset onboarding (for testing)
    func resetOnboarding() {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot reset onboarding: Core Data context or profile not available")
            return
        }
        
        // Update profile
        profile.isOnboarded = false
        
        // Save context
        do {
            try context.save()
            hasCompletedOnboarding = false
            currentOnboardingStep = 0
            onboardingProgress = 0
            logger.info("Reset onboarding")
        } catch {
            logger.error("Failed to reset onboarding: \(error.localizedDescription)")
        }
    }
    
    /// Set preferred categories during onboarding
    func setPreferredCategories(_ categories: [GoalCategory]) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot set preferred categories: Core Data context or profile not available")
            return
        }
        
        // Update profile
        preferredCategories = categories
        
        // Save to user preferences
        var preferences = profile.userPreferences as? [String: Any] ?? [:]
        preferences["preferredCategories"] = categories.map { $0.rawValue }
        profile.userPreferences = preferences as NSObject
        
        // Save context
        do {
            try context.save()
            logger.info("Set preferred categories: \(categories.map { $0.rawValue })")
        } catch {
            logger.error("Failed to set preferred categories: \(error.localizedDescription)")
        }
    }
    
    /// Set preferred audio categories during onboarding
    func setPreferredAudioCategories(_ categories: [AudioCategory]) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot set preferred audio categories: Core Data context or profile not available")
            return
        }
        
        // Update profile
        preferredAudioCategories = categories
        profile.preferredAudioCategories = categories.map { $0.rawValue } as NSObject
        
        // Save context
        do {
            try context.save()
            logger.info("Set preferred audio categories: \(categories.map { $0.rawValue })")
        } catch {
            logger.error("Failed to set preferred audio categories: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Preferences Management
    
    /// Update notification preferences
    func updateNotificationPreferences(_ preferences: [String: Bool]) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot update notification preferences: Core Data context or profile not available")
            return
        }
        
        // Update profile
        profile.notificationPreferences = preferences
        
        // Update published property
        notificationPreferences = preferences
        
        // Save context
        do {
            try context.save()
            logger.info("Updated notification preferences")
        } catch {
            logger.error("Failed to update notification preferences: \(error.localizedDescription)")
        }
    }
    
    /// Update theme preference
    func updateThemePreference(_ theme: String) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot update theme preference: Core Data context or profile not available")
            return
        }
        
        // Update published property
        themePreference = theme
        
        // Update user preferences
        var preferences = profile.userPreferences as? [String: Any] ?? [:]
        preferences["theme"] = theme
        profile.userPreferences = preferences as NSObject
        
        // Save context
        do {
            try context.save()
            logger.info("Updated theme preference: \(theme)")
        } catch {
            logger.error("Failed to update theme preference: \(error.localizedDescription)")
        }
    }
    
    /// Update measurement system preference
    func updateMeasurementSystem(_ system: String) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot update measurement system: Core Data context or profile not available")
            return
        }
        
        // Update published property
        measurementSystem = system
        
        // Update user preferences
        var preferences = profile.userPreferences as? [String: Any] ?? [:]
        preferences["measurementSystem"] = system
        profile.userPreferences = preferences as NSObject
        
        // Save context
        do {
            try context.save()
            logger.info("Updated measurement system: \(system)")
        } catch {
            logger.error("Failed to update measurement system: \(error.localizedDescription)")
        }
    }
    
    /// Update notification time preference
    func updateNotificationTime(key: String, hour: Int, minute: Int) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot update notification time: Core Data context or profile not available")
            return
        }
        
        // Update user preferences
        var preferences = profile.userPreferences as? [String: Any] ?? [:]
        var notificationTimes = preferences["notificationTimes"] as? [String: [Int]] ?? [:]
        
        notificationTimes[key] = [hour, minute]
        preferences["notificationTimes"] = notificationTimes
        
        profile.userPreferences = preferences as NSObject
        
        // Save context
        do {
            try context.save()
            logger.info("Updated notification time for \(key): \(hour):\(minute)")
        } catch {
            logger.error("Failed to update notification time: \(error.localizedDescription)")
        }
    }
    
    /// Get notification time preference
    func getNotificationTime(for key: String) -> DateComponents? {
        guard let profile = userProfile else { return nil }
        
        if let preferences = profile.userPreferences as? [String: Any],
           let notificationTimes = preferences["notificationTimes"] as? [String: [Int]],
           let timeArray = notificationTimes[key],
           timeArray.count >= 2 {
            
            return DateComponents(hour: timeArray[0], minute: timeArray[1])
        }
        
        return nil
    }
    
    /// Update do not disturb windows
    func updateDoNotDisturbWindows(_ windows: [(start: DateComponents, end: DateComponents)]) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot update do not disturb windows: Core Data context or profile not available")
            return
        }
        
        // Convert to storable format
        var windowsData: [[String: [Int]]] = []
        
        for window in windows {
            let startHour = window.start.hour ?? 0
            let startMinute = window.start.minute ?? 0
            let endHour = window.end.hour ?? 0
            let endMinute = window.end.minute ?? 0
            
            windowsData.append([
                "start": [startHour, startMinute],
                "end": [endHour, endMinute]
            ])
        }
        
        // Update user preferences
        var preferences = profile.userPreferences as? [String: Any] ?? [:]
        preferences["doNotDisturbWindows"] = windowsData
        profile.userPreferences = preferences as NSObject
        
        // Save context
        do {
            try context.save()
            logger.info("Updated do not disturb windows")
        } catch {
            logger.error("Failed to update do not disturb windows: \(error.localizedDescription)")
        }
    }
    
    /// Get do not disturb windows
    func getDoNotDisturbWindows() -> [(start: DateComponents, end: DateComponents)] {
        guard let profile = userProfile else { return [] }
        
        if let preferences = profile.userPreferences as? [String: Any],
           let windowsData = preferences["doNotDisturbWindows"] as? [[String: [Int]]] {
            
            var windows: [(start: DateComponents, end: DateComponents)] = []
            
            for windowData in windowsData {
                if let startArray = windowData["start"], startArray.count >= 2,
                   let endArray = windowData["end"], endArray.count >= 2 {
                    
                    let start = DateComponents(hour: startArray[0], minute: startArray[1])
                    let end = DateComponents(hour: endArray[0], minute: endArray[1])
                    
                    windows.append((start: start, end: end))
                }
            }
            
            return windows
        }
        
        return []
    }
    
    // MARK: - Goals Management
    
    /// Load user goals from Core Data
    private func loadUserGoals() {
        guard let context = viewContext else {
            logger.error("Cannot load user goals: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            // Convert to view models
            let activeGoalModels = goals.filter { $0.isActive }
                .compactMap { createGoalViewModel(from: $0) }
            
            let completedGoalModels = goals.filter { $0.isCompleted }
                .compactMap { createGoalViewModel(from: $0) }
            
            // Update published properties
            DispatchQueue.main.async {
                self.activeGoals = activeGoalModels
                self.completedGoals = completedGoalModels
                
                // Calculate completion rate
                let totalGoals = goals.count
                let completedCount = goals.filter { $0.isCompleted }.count
                
                self.goalCompletionRate = totalGoals > 0 ? Double(completedCount) / Double(totalGoals) : 0
                
                self.logger.info("Loaded \(activeGoalModels.count) active goals and \(completedGoalModels.count) completed goals")
            }
            
            // Load streak data
            loadStreakData()
        } catch {
            logger.error("Failed to fetch goals: \(error.localizedDescription)")
        }
    }
    
    /// Create goal view model from Core Data entity
    private func createGoalViewModel(from goal: Goal) -> GoalViewModel? {
        guard let id = goal.id,
              let title = goal.title else {
            return nil
        }
        
        // Calculate progress
        let progress = goal.targetValue > 0 ? goal.currentProgress / goal.targetValue : 0
        
        // Get streak for this goal category
        let streak = getStreakForCategory(goal.category ?? "")
        
        return GoalViewModel(
            id: id,
            title: title,
            category: GoalCategory(rawValue: goal.category ?? "Other") ?? .other,
            progress: progress,
            currentValue: goal.currentProgress,
            targetValue: goal.targetValue,
            unit: goal.unit,
            dueDate: goal.dueDate,
            isCompleted: goal.isCompleted,
            streak: streak
        )
    }
    
    /// Create a new goal
    func createGoal(title: String, category: GoalCategory, targetValue: Double, 
                   unit: String? = nil, dueDate: Date? = nil, frequency: GoalFrequency = .daily) {
        guard let context = viewContext, let profile = userProfile else {
            logger.error("Cannot create goal: Core Data context or profile not available")
            return
        }
        
        // Create new goal
        let goal = Goal(context: context)
        goal.id = UUID()
        goal.title = title
        goal.category = category.rawValue
        goal.targetValue = targetValue
        goal.currentProgress = 0
        goal.unit = unit
        goal.dueDate = dueDate
        goal.frequency = frequency.rawValue
        goal.creationDate = Date()
        goal.isActive = true
        goal.isCompleted = false
        goal.status = GoalStatus.active.rawValue
        goal.userProfile = profile
        
        // Save context
        do {
            try context.save()
            
            // Reload goals
            loadUserGoals()
            
            logger.info("Created new goal: \(title)")
        } catch {
            logger.error("Failed to create goal: \(error.localizedDescription)")
        }
    }
    
    /// Update goal progress
    func updateGoalProgress(goalId: UUID, progress: Double) {
        guard let context = viewContext else {
            logger.error("Cannot update goal progress: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            if let goal = goals.first {
                // Update progress
                goal.currentProgress = progress
                
                // Check if goal is completed
                if progress >= goal.targetValue && !goal.isCompleted {
                    goal.isCompleted = true
                    goal.completionDate = Date()
                    
                    // Update streak
                    updateStreak(for: goal)
                }
                
                // Create progress entry
                let progressEntry = GoalProgress(context: context)
                progressEntry.id = UUID()
                progressEntry.date = Date()
                progressEntry.value = progress
                progressEntry.goal = goal
                
                // Save context
                try context.save()
                
                // Reload goals
                loadUserGoals()
                
                logger.info("Updated goal progress: \(goalId), progress: \(progress)")
            } else {
                logger.warning("Goal not found: \(goalId)")
            }
        } catch {
            logger.error("Failed to update goal progress: \(error.localizedDescription)")
        }
    }
    
    /// Complete a goal
    func completeGoal(goalId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot complete goal: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            if let goal = goals.first {
                // Mark as completed
                goal.isCompleted = true
                goal.completionDate = Date()
                goal.currentProgress = goal.targetValue
                
                // Update streak
                updateStreak(for: goal)
                
                // Save context
                try context.save()
                
                // Reload goals
                loadUserGoals()
                
                logger.info("Completed goal: \(goalId)")
            } else {
                logger.warning("Goal not found: \(goalId)")
            }
        } catch {
            logger.error("Failed to complete goal: \(error.localizedDescription)")
        }
    }
    
    /// Delete a goal
    func deleteGoal(goalId: UUID) {
        guard let context = viewContext else {
            logger.error("Cannot delete goal: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
        
        do {
            let goals = try context.fetch(fetchRequest)
            
            if let goal = goals.first {
                // Delete goal
                context.delete(goal)
                
                // Save context
                try context.save()
                
                // Reload goals
                loadUserGoals()
                
                logger.info("Deleted goal: \(goalId)")
            } else {
                logger.warning("Goal not found: \(goalId)")
            }
        } catch {
            logger.error("Failed to delete goal: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Streak Management
    
    /// Load streak data from Core Data
    private func loadStreakData() {
        guard let context = viewContext else {
            logger.error("Cannot load streak data: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<Streak> = Streak.fetchRequest()
        
        do {
            let streaks = try context.fetch(fetchRequest)
            
            // Convert to dictionary
            var streakDict: [String: Int] = [:]
            var maxStreak = 0
            
            for streak in streaks {
                let category = streak.category ?? "Unknown"
                let count = Int(streak.currentCount)
                
                streakDict[category] = count
                
                if count > maxStreak {
                    maxStreak = count
                }
            }
            
            // Update published properties
            DispatchQueue.main.async {
                self.streakData = streakDict
                self.longestStreak = maxStreak
                
                self.logger.info("Loaded streak data for \(streakDict.count) categories")
            }
        } catch {
            logger.error("Failed to fetch streak data: \(error.localizedDescription)")
        }
    }
    
    /// Get streak for a specific category
    private func getStreakForCategory(_ category: String) -> Int {
        return streakData[category] ?? 0
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
                if let userProfile = userProfile {
                    newStreak.userProfile = userProfile
                }
            }
            
            try context.save()
            
            // Reload streak data
            loadStreakData()
            
            logger.info("Updated streak for category: \(category)")
        } catch {
            logger.error("Error updating streak: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Analytics Management
    
    /// Load analytics data
    private func loadAnalyticsData() {
        // Load session completions
        loadSessionCompletions()
        
        // Load activity data
        loadActivityData()
        
        // Load progress data
        loadProgressData()
    }
    
    /// Load session completions
    private func loadSessionCompletions() {
        guard let context = viewContext else {
            logger.error("Cannot load session completions: Core Data context not available")
            return
        }
        
        let fetchRequest: NSFetchRequest<SessionCompletion> = SessionCompletion.fetchRequest()
        
        do {
            let completions = try context.fetch(fetchRequest)
            
            // Calculate total sessions and mindful minutes
            let totalSessions = completions.count
            let totalMinutes = completions.reduce(0.0) { $0 + $1.durationSeconds / 60.0 }
            
            // Update published properties
            DispatchQueue.main.async {
                self.totalSessionsCompleted = totalSessions
                self.totalMindfulMinutes = totalMinutes
                
                self.logger.info("Loaded \(totalSessions) session completions, \(Int(totalMinutes)) minutes total")
            }
        } catch {
            logger.error("Failed to fetch session completions: \(error.localizedDescription)")
        }
    }
    
    /// Load activity data
    private func loadActivityData() {
        guard let context = viewContext else {
            logger.error("Cannot load activity data: Core Data context not available")
            return
        }
        
        // Get health metrics for active minutes
        let fetchRequest: NSFetchRequest<HealthMetric> = HealthMetric.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "metricType == %@", HealthMetricType.activeEnergy.rawValue)
        
        do {
            let metrics = try context.fetch(fetchRequest)
            
            // Calculate total active minutes (estimate based on active energy)
            let totalActiveEnergy = metrics.reduce(0.0) { $0 + $1.value }
            let estimatedActiveMinutes = totalActiveEnergy / 10.0 // Rough estimate: 10 calories per minute
            
            // Group by day for weekly summary
            let calendar = Calendar.current
            var dailyData: [Date: Double] = [:]
            
            for metric in metrics {
                guard let date = metric.date else { continue }
                
                let day = calendar.startOfDay(for: date)
                dailyData[day, default: 0] += metric.value / 10.0 // Convert to minutes
            }
            
            // Update published properties
            DispatchQueue.main.async {
                self.totalActiveMinutes = estimatedActiveMinutes
                self.weeklyActivitySummary = dailyData
                
                self.logger.info("Loaded activity data: \(Int(estimatedActiveMinutes)) active minutes total")
            }
        } catch {
            logger.error("Failed to fetch activity data: \(error.localizedDescription)")
        }
    }
    
    /// Load progress data
    private func loadProgressData() {
        guard let context = viewContext else {
            logger.error("Cannot load progress data: Core Data context not available")
            return
        }
        
        // Get goal progress entries
        let fetchRequest: NSFetchRequest<GoalProgress> = GoalProgress.fetchRequest()
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@", threeMonthsAgo as NSDate)
        
        do {
            let progressEntries = try context.fetch(fetchRequest)
            
            // Group by month and category
            var monthlyData: [String: [Double]] = [:]
            
            for entry in progressEntries {
                guard let date = entry.date, let goal = entry.goal, let category = goal.category else { continue }
                
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                let monthKey = "\(year)-\(month)"
                
                // Normalize progress as percentage of target
                let normalizedProgress = goal.targetValue > 0 ? (entry.value / goal.targetValue) : 0
                
                // Add to category data
                if monthlyData[category] == nil {
                    monthlyData[category] = [0, 0, 0] // Last 3 months
                }
                
                // Determine which month index (0 = current month, 1 = last month, 2 = two months ago)
                let currentMonth = calendar.component(.month, from: Date())
                let currentYear = calendar.component(.year, from: Date())
                
                var monthIndex: Int
                if month == currentMonth && year == currentYear {
                    monthIndex = 0
                } else if (month == currentMonth - 1 || (currentMonth == 1 && month == 12)) && 
                          (year == currentYear || (currentMonth == 1 && year == currentYear - 1)) {
                    monthIndex = 1
                } else {
                    monthIndex = 2
                }
                
                // Add progress to the appropriate month
                if monthIndex >= 0 && monthIndex < 3 {
                    monthlyData[category]?[monthIndex] += normalizedProgress
                }
            }
            
            // Update published property
            DispatchQueue.main.async {
                self.monthlyProgressData = monthlyData
                
                self.logger.info("Loaded monthly progress data for \(monthlyData.count) categories")
            }
        } catch {
            logger.error("Failed to fetch progress data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Data Export
    
    /// Export user data as JSON
    func exportUserData() -> Data? {
        guard let profile = userProfile else {
            logger.error("Cannot export user data: user profile not available")
            return nil
        }
        
        // Create export dictionary
        var exportData: [String: Any] = [
            "profile": [
                "firstName": profile.firstName ?? "",
                "lastName": profile.lastName ?? "",
                "email": profile.email ?? "",
                "creationDate": profile.creationDate ?? Date()
            ],
            "goals": activeGoals.map { [
                "id": $0.id.uuidString,
                "title": $0.title,
                "category": $0.category.rawValue,
                "progress": $0.progress,
                "currentValue": $0.currentValue,
                "targetValue": $0.targetValue,
                "unit": $0.unit ?? ""
            ] },
            "streaks": streakData.map { [
                "category": $0.key,
                "count": $0.value
            ] },
            "analytics": [
                "totalSessionsCompleted": totalSessionsCompleted,
                "totalMindfulMinutes": totalMindfulMinutes,
                "totalActiveMinutes": totalActiveMinutes,
                "goalCompletionRate": goalCompletionRate
            ]
        ]
        
        // Convert to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return jsonData
        } catch {
            logger.error("Failed to export user data: \(error.localizedDescription)")
            return nil
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
        
        // Goal completed notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGoalCompletedNotification),
            name: NSNotification.Name("GoalCompletedFromNotification"),
            object: nil
        )
    }
    
    /// Handle app will enter foreground notification
    @objc private func handleAppWillEnterForeground() {
        // Refresh data
        if viewContext != nil {
            loadUserGoals()
            loadAnalyticsData()
        }
    }
    
    /// Handle goal completed notification
    @objc private func handleGoalCompletedNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let goalId = userInfo["goalId"] as? UUID {
            // Complete the goal
            completeGoal(goalId: goalId)
        }
    }
    
    // MARK: - Mock Data for Simulator
    
    /// Load mock data for simulator testing
    private func loadMockData() {
        logger.info("Loading mock user profile data for simulator")
        
        // Set mock profile data
        firstName = "Alex"
        lastName = "Morgan"
        email = "alex.morgan@example.com"
        birthDate = Calendar.current.date(byAdding: .year, value: -32, to: Date())
        gender = "Non-binary"
        height = 175.0
        weight = 68.5
        profileImage = UIImage(systemName: "person.crop.circle.fill")
        
        // Set mock preferences
        themePreference = "system"
        measurementSystem = "metric"
        notificationPreferences = [
            "goals": true,
            "achievements": true,
            "streaks": true,
            "healthAlerts": true,
            "recommendations": true,
            "sessions": true,
            "marketing": false
        ]
        
        preferredCategories = [.physical, .mindfulness, .sleep]
        preferredAudioCategories = [.meditation, .sleep, .focus]
        
        // Set mock onboarding status
        hasCompletedOnboarding = true
        
        // Set mock goals
        activeGoals = [
            GoalViewModel(
                id: UUID(),
                title: "Daily Steps",
                category: .physical,
                progress: 0.75,
                currentValue: 7500,
                targetValue: 10000,
                unit: "steps",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                isCompleted: false,
                streak: 5
            ),
            GoalViewModel(
                id: UUID(),
                title: "Meditation",
                category: .mindfulness,
                progress: 1.0,
                currentValue: 15,
                targetValue: 10,
                unit: "min",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                isCompleted: true,
                streak: 12
            ),
            GoalViewModel(
                id: UUID(),
                title: "Sleep Duration",
                category: .sleep,
                progress: 0.88,
                currentValue: 7,
                targetValue: 8,
                unit: "hours",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                isCompleted: false,
                streak: 3
            )
        ]
        
        completedGoals = [
            GoalViewModel(
                id: UUID(),
                title: "Weekly Workout",
                category: .physical,
                progress: 1.0,
                currentValue: 3,
                targetValue: 3,
                unit: "sessions",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                isCompleted: true,
                streak: 4
            ),
            GoalViewModel(
                id: UUID(),
                title: "Drink Water",
                category: .nutrition,
                progress: 1.0,
                currentValue: 2000,
                targetValue: 2000,
                unit: "ml",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                isCompleted: true,
                streak: 7
            )
        ]
        
        // Set mock streak data
        streakData = [
            "Physical": 5,
            "Mindfulness": 12,
            "Sleep": 3,
            "Nutrition": 7
        ]
        
        longestStreak = 12
        
        // Set mock analytics data
        totalSessionsCompleted = 28
        totalMindfulMinutes = 342
        totalActiveMinutes = 960
        goalCompletionRate = 0.72
        
        // Set mock weekly activity data
        var weeklyData: [Date: Double] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Generate random activity minutes (higher on weekdays)
                let weekday = calendar.component(.weekday, from: date)
                let isWeekend = weekday == 1 || weekday == 7
                
                let minutes = isWeekend ? Double.random(in: 20...45) : Double.random(in: 30...60)
                weeklyData[date] = minutes
            }
        }
        
        weeklyActivitySummary = weeklyData
        
        // Set mock monthly progress data
        monthlyProgressData = [
            "Physical": [0.82, 0.75, 0.68],
            "Mindfulness": [0.95, 0.90, 0.85],
            "Sleep": [0.78, 0.72, 0.65],
            "Nutrition": [0.65, 0.60, 0.55]
        ]
        
        logger.info("Loaded mock user profile data")
    }
    
    // MARK: - Helper Methods
    
    /// Format height based on measurement system
    func formattedHeight(height: Double? = nil) -> String {
        let heightValue = height ?? self.height
        
        if measurementSystem == "imperial" {
            // Convert to feet and inches
            let totalInches = heightValue / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        } else {
            // Metric (cm)
            return "\(Int(heightValue)) cm"
        }
    }
    
    /// Format weight based on measurement system
    func formattedWeight(weight: Double? = nil) -> String {
        let weightValue = weight ?? self.weight
        
        if measurementSystem == "imperial" {
            // Convert to pounds
            let pounds = weightValue * 2.20462
            return String(format: "%.1f lbs", pounds)
        } else {
            // Metric (kg)
            return String(format: "%.1f kg", weightValue)
        }
    }
    
    /// Get age from birth date
    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
    
    /// Get greeting based on time of day
    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 12 {
            return "Good morning"
        } else if hour >= 12 && hour < 17 {
            return "Good afternoon"
        } else if hour >= 17 && hour < 22 {
            return "Good evening"
        } else {
            return "Good night"
        }
    }
    
    /// Get personalized greeting
    var personalizedGreeting: String {
        if firstName.isEmpty {
            return timeBasedGreeting
        } else {
            return "\(timeBasedGreeting), \(firstName)"
        }
    }
    
    /// Check if user has completed all initial setup
    var hasCompletedInitialSetup: Bool {
        return hasCompletedOnboarding && !firstName.isEmpty
    }
}
