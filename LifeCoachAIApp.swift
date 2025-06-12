//
//  LifeCoachAIApp.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import CoreData
import HealthKit
import UserNotifications
import AVFoundation
import StoreKit

@main
struct LifeCoachAIApp: App {
    // MARK: - Environment Objects
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var mlManager = MLManager()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var userProfileManager = UserProfileManager()
    
    // MARK: - App State
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasCompletedOnboarding = false
    
    // MARK: - Core Data
    let persistenceController = PersistenceController.shared
    
    // MARK: - App Initialization
    init() {
        // Configure app appearance
        configureAppAppearance()
        
        // Log app launch for analytics
        #if DEBUG
        print("LifeCoach AI launching in debug mode")
        #if targetEnvironment(simulator)
        print("Running in iOS Simulator - using mock HealthKit data")
        #else
        print("Running on physical device")
        #endif
        #endif
    }
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(healthKitManager)
                .environmentObject(notificationManager)
                .environmentObject(audioManager)
                .environmentObject(mlManager)
                .environmentObject(storeManager)
                .environmentObject(userProfileManager)
                .onAppear {
                    // Request permissions on first launch
                    requestAppPermissions()
                    
                    // Check if onboarding is completed
                    hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    
                    // Initialize audio session
                    setupAudioSession()
                    
                    // Prepare ML models
                    mlManager.loadModels()
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    // MARK: - App Configuration Methods
    
    /// Configure global app appearance settings
    private func configureAppAppearance() {
        // Set up navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("PrimaryBackground"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color("PrimaryText"))]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color("PrimaryText"))]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set tab bar appearance
        UITabBar.appearance().backgroundColor = UIColor(Color("SecondaryBackground"))
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color("SecondaryText"))
        UITabBar.appearance().tintColor = UIColor(Color("AccentColor"))
    }
    
    /// Request all necessary app permissions
    private func requestAppPermissions() {
        // Request HealthKit permissions
        healthKitManager.requestAuthorization()
        
        // Request notification permissions
        notificationManager.requestAuthorization()
        
        // Setup background processing if needed
        registerBackgroundTasks()
    }
    
    /// Set up audio session for meditation and guided sessions
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    /// Register background tasks for periodic health data processing
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.lifecoach.healthDataUpdate", using: nil) { task in
            self.handleHealthDataBackgroundTask(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.lifecoach.dailyRecommendations", using: nil) { task in
            self.handleDailyRecommendationsTask(task: task as! BGProcessingTask)
        }
    }
    
    /// Handle scene phase changes (foreground, background, inactive)
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("App is active")
            healthKitManager.startObservingHealthData()
            audioManager.prepareAudioResources()
            
        case .inactive:
            print("App is inactive")
            // Pause any active sessions if needed
            audioManager.handleAppInactive()
            
        case .background:
            print("App is in background")
            // Save any pending data
            persistenceController.save()
            
            // Schedule background tasks
            scheduleBackgroundTasks()
            
            // Prepare for background state
            healthKitManager.stopObservingHealthData()
            
        @unknown default:
            print("Unknown scene phase")
        }
    }
    
    /// Schedule background tasks for health data processing
    private func scheduleBackgroundTasks() {
        let healthDataRequest = BGProcessingTaskRequest(identifier: "com.lifecoach.healthDataUpdate")
        healthDataRequest.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour
        healthDataRequest.requiresNetworkConnectivity = false
        healthDataRequest.requiresExternalPower = false
        
        let recommendationsRequest = BGProcessingTaskRequest(identifier: "com.lifecoach.dailyRecommendations")
        recommendationsRequest.earliestBeginDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400) // Next day
        recommendationsRequest.requiresNetworkConnectivity = true
        recommendationsRequest.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(healthDataRequest)
            try BGTaskScheduler.shared.submit(recommendationsRequest)
        } catch {
            print("Could not schedule background tasks: \(error.localizedDescription)")
        }
    }
    
    /// Handle background task for health data processing
    private func handleHealthDataBackgroundTask(task: BGProcessingTask) {
        // Create a task that processes health data in the background
        let processingTask = Task {
            do {
                // Process health data
                try await healthKitManager.processHealthDataInBackground()
                
                // Schedule the next background task
                scheduleBackgroundTasks()
                
                // Mark task complete
                task.setTaskCompleted(success: true)
            } catch {
                // Handle errors
                print("Background health data processing failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            processingTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    /// Handle background task for generating daily recommendations
    private func handleDailyRecommendationsTask(task: BGProcessingTask) {
        // Create a task that generates daily recommendations
        let recommendationsTask = Task {
            do {
                // Generate recommendations based on health data
                try await mlManager.generateDailyRecommendations()
                
                // Schedule notifications for these recommendations
                notificationManager.scheduleDailyRecommendationNotifications()
                
                // Schedule the next background task
                scheduleBackgroundTasks()
                
                // Mark task complete
                task.setTaskCompleted(success: true)
            } catch {
                // Handle errors
                print("Background recommendations processing failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            recommendationsTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}

// MARK: - Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LifeCoachAI")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Handle Core Data loading errors
                fatalError("Failed to load Core Data: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving Core Data context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Preview Helper
#if DEBUG
extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add sample data for previews here
        return controller
    }()
}
#endif
