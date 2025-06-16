//
//  LifeCoachAIApp.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import HealthKit
import UserNotifications
import BackgroundTasks

@main
struct LifeCoachAIApp: App {
    // MARK: - Environment Objects
    
    /// Audio playback manager
    @StateObject private var audioManager = AudioManager()
    
    /// Health data manager
    @StateObject private var healthKitManager = HealthKitManager()
    
    /// Machine learning manager for recommendations and insights
    @StateObject private var mlManager = MLManager()
    
    /// Notification manager
    @StateObject private var notificationManager = NotificationManager()
    
    /// In-app purchase and subscription manager
    @StateObject private var storeManager = StoreManager()
    
    /// User profile manager
    @StateObject private var userProfileManager = UserProfileManager()
    
    // MARK: - App Lifecycle
    
    init() {
        // Configure appearance
        configureAppearance()
        
        // Register background tasks
        registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Provide environment objects to views
                .environmentObject(audioManager)
                .environmentObject(healthKitManager)
                .environmentObject(mlManager)
                .environmentObject(notificationManager)
                .environmentObject(storeManager)
                .environmentObject(userProfileManager)
                .onAppear {
                    // Request permissions when app launches
                    requestPermissions()

                    // Setup health data collection
                    if healthKitManager.isHealthKitAuthorized {
                        healthKitManager.startObservingHealthData()
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Configure global app appearance
    private func configureAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "SecondaryBackground")
        appearance.titleTextAttributes = [.foregroundColor: UIColor(named: "PrimaryText") ?? .black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "PrimaryText") ?? .black]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "SecondaryBackground")
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    /// Register background tasks
    private func registerBackgroundTasks() {
        // Register health data refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lifecoach.ai.healthrefresh",
            using: nil
        ) { task in
            self.handleHealthDataRefreshTask(task: task as! BGProcessingTask)
        }
        
        // Register insights generation task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lifecoach.ai.insightsgeneration",
            using: nil
        ) { task in
            self.handleInsightsGenerationTask(task: task as! BGProcessingTask)
        }
        
        // Register goals update task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lifecoach.ai.goalsupdate",
            using: nil
        ) { task in
            self.handleGoalsUpdateTask(task: task as! BGProcessingTask)
        }
    }
    
    /// Request necessary permissions
    private func requestPermissions() {
        // Request HealthKit permissions
        healthKitManager.requestAuthorization()
        
        // Request notification permissions
        notificationManager.requestAuthorization()
    }
    
    // MARK: - Background Task Handlers
    
    /// Handle health data refresh background task
    private func handleHealthDataRefreshTask(task: BGProcessingTask) {
        // Schedule next background task
        scheduleHealthDataRefresh()
        
        // Create a task to ensure background task completes or times out
        let healthRefreshTask = Task {
            do {
                // Refresh health data
                try await healthKitManager.processHealthDataInBackground()
                task.setTaskCompleted(success: true)
            } catch {
                print("Error refreshing health data: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            healthRefreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    /// Handle insights generation background task
    private func handleInsightsGenerationTask(task: BGProcessingTask) {
        // Schedule next background task
        scheduleInsightsGeneration()
        
        // Create a task to ensure background task completes or times out
        let insightsTask = Task {
            do {
                // Generate insights based on health data
                try await mlManager.generateInsightsAsync()
                task.setTaskCompleted(success: true)
            } catch {
                print("Error generating insights: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            insightsTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    /// Handle goals update background task
    private func handleGoalsUpdateTask(task: BGProcessingTask) {
        // Schedule next background task
        scheduleGoalsUpdate()
        
        // Create a task to ensure background task completes or times out
        let goalsTask = Task {
            do {
                // Update goals progress - simulate background processing
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                task.setTaskCompleted(success: true)
            } catch {
                print("Error updating goals: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            goalsTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - Background Task Scheduling
    
    /// Schedule health data refresh background task
    private func scheduleHealthDataRefresh() {
        let request = BGProcessingTaskRequest(identifier: "com.lifecoach.ai.healthrefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600) // 6 hours from now
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule health data refresh: \(error)")
        }
    }
    
    /// Schedule insights generation background task
    private func scheduleInsightsGeneration() {
        let request = BGProcessingTaskRequest(identifier: "com.lifecoach.ai.insightsgeneration")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600) // 12 hours from now
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule insights generation: \(error)")
        }
    }
    
    /// Schedule goals update background task
    private func scheduleGoalsUpdate() {
        let request = BGProcessingTaskRequest(identifier: "com.lifecoach.ai.goalsupdate")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 3600) // 24 hours from now
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule goals update: \(error)")
        }
    }
}
