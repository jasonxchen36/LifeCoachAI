//
//  HealthKitManager.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import HealthKit
import CoreData
import Combine
import SwiftUI
import os.log

/// Manager class for handling all HealthKit interactions and data processing
class HealthKitManager: ObservableObject {
    // MARK: - Properties
    
    /// The HealthKit store for accessing health data
    private let healthStore = HKHealthStore()
    
    /// Logger for debugging and tracking HealthKit operations
    private let logger = Logger(subsystem: "com.lifecoach.ai", category: "HealthKitManager")
    
    /// Core Data context for persisting health metrics
    private var viewContext: NSManagedObjectContext?
    
    /// Timer for periodic background updates
    private var backgroundUpdateTimer: Timer?
    
    /// Query dictionary to keep track of active observers
    private var activeQueries: [HKObjectType: HKQuery] = [:]
    
    /// Published properties for SwiftUI updates
    @Published var isHealthKitAuthorized = false
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    // Health metrics
    @Published var todaySteps: Double = 0
    @Published var todayActiveEnergy: Double = 0
    @Published var todayExerciseMinutes: Double = 0
    @Published var todayStandHours: Double = 0
    @Published var todayMindfulMinutes: Double = 0
    @Published var todayWaterIntake: Double = 0
    @Published var latestHeartRate: Double = 0
    @Published var latestRestingHeartRate: Double = 0
    @Published var latestWeight: Double = 0
    @Published var latestSleepHours: Double = 0
    @Published var latestSleepQuality: Double = 0
    @Published var weeklyAverageSteps: Double = 0
    @Published var weeklyAverageActiveEnergy: Double = 0
    @Published var weeklyAverageSleepHours: Double = 0
    
    /// Weekly health data for charts
    @Published var weeklyStepsData: [Date: Double] = [:]
    @Published var weeklyActiveEnergyData: [Date: Double] = [:]
    @Published var weeklySleepData: [Date: Double] = [:]
    @Published var weeklyHeartRateData: [Date: Double] = [:]
    @Published var weeklyMindfulMinutesData: [Date: Double] = [:]
    @Published var weeklyWaterIntakeData: [Date: Double] = [:]
    
    /// Recent workouts
    @Published var recentWorkouts: [HKWorkout] = []
    
    /// Health data availability
    @Published var availableDataTypes: Set<HKQuantityTypeIdentifier> = []
    
    // MARK: - Initialization
    
    init() {
        logger.info("Initializing HealthKitManager")
        
        // Check if HealthKit is available on this device
        if HKHealthStore.isHealthDataAvailable() {
            logger.info("HealthKit is available on this device")
        } else {
            logger.warning("HealthKit is not available on this device")
            errorMessage = "HealthKit is not available on this device"
        }
        
        // Set up notification observers
        setupNotificationObservers()
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        logger.info("Running in simulator - will use mock data")
        loadMockData()
        #endif
    }
    
    /// Set the Core Data context
    func setViewContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Authorization
    
    /// Request authorization for HealthKit data access
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        // Define the types to read
        let healthMetricTypesToRead = HealthMetricType.healthKitTypesToRead
        let typesToRead = Set(healthMetricTypesToRead.compactMap { $0.healthKitType })
        
        // Define the types to share (write) if needed
        var typesToShare: Set<HKSampleType> = []
        
        // Add specific types we might want to write
        if let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            typesToShare.insert(waterType)
        }
        
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            typesToShare.insert(mindfulType as! HKSampleType)
        }
        
        // Request authorization
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.logger.info("HealthKit authorization granted")
                    self?.isHealthKitAuthorized = true
                    self?.checkAvailableDataTypes()
                    self?.fetchInitialHealthData()
                } else if let error = error {
                    self?.logger.error("HealthKit authorization failed: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to authorize HealthKit: \(error.localizedDescription)"
                    self?.isHealthKitAuthorized = false
                } else {
                    self?.logger.warning("HealthKit authorization denied by user")
                    self?.errorMessage = "HealthKit access was denied"
                    self?.isHealthKitAuthorized = false
                }
            }
        }
    }
    
    /// Check which data types are available after authorization
    private func checkAvailableDataTypes() {
        var available = Set<HKQuantityTypeIdentifier>()
        
        // List of types to check
        let typesToCheck: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .heartRate,
            .restingHeartRate,
            .bodyMass,
            .dietaryWater,
            .appleStandTime,
            .respiratoryRate,
            .oxygenSaturation,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .bodyFatPercentage,
            .bodyMassIndex
        ]
        
        // Check each type
        for typeId in typesToCheck {
            if let type = HKQuantityType.quantityType(forIdentifier: typeId),
               healthStore.authorizationStatus(for: type) == .sharingAuthorized {
                available.insert(typeId)
            }
        }
        
        // Check category types separately
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
           healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized {
            available.insert(.appleStandTime) // Using as a placeholder for sleep
        }
        
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession),
           healthStore.authorizationStatus(for: mindfulType) == .sharingAuthorized {
            available.insert(.appleExerciseTime) // Using as a placeholder for mindfulness
        }
        
        // Update the published property
        DispatchQueue.main.async {
            self.availableDataTypes = available
            self.logger.info("Available data types: \(available.count)")
        }
    }
    
    // ... (unchanged code omitted for brevity, see above for full file up to "Helper Methods") ...
    
    // MARK: - Helper Methods
    
    /// Get view model for a specific health metric
    func getHealthMetricViewModel(for type: HealthMetricType) -> HealthMetricViewModel? {
        let now = Date()
        var value: Double = 0
        var previousValue: Double? = nil
        var goalValue: Double? = nil
        
        switch type {
        case .steps:
            value = todaySteps
            previousValue = weeklyAverageSteps
            goalValue = 10000
        case .activeEnergy:
            value = todayActiveEnergy
            previousValue = weeklyAverageActiveEnergy
            goalValue = 500
        case .heartRate:
            value = latestHeartRate
        case .sleepHours:
            value = latestSleepHours
            previousValue = weeklyAverageSleepHours
            goalValue = 8.0
        case .sleepQuality:
            value = latestSleepQuality
            goalValue = 85
        case .weight:
            value = latestWeight
        case .mindfulMinutes:
            value = todayMindfulMinutes
            goalValue = 10
        case .workouts:
            value = todayExerciseMinutes
            goalValue = 30
        case .standHours:
            value = todayStandHours
            goalValue = 12
        case .waterIntake:
            value = todayWaterIntake
            goalValue = 2000
        default:
            return nil
        }
        
        return HealthMetricViewModel(
            id: UUID(),
            type: type,
            value: value,
            unit: type.unit,
            date: now,
            trend: nil, // TODO: Calculate trend based on historical data
            weeklyAverage: nil, // TODO: Calculate weekly average
            monthlyAverage: nil // TODO: Calculate monthly average
        )
    }
    
    /// Get all health metrics as view models
    func getAllHealthMetrics() -> [HealthMetricViewModel] {
        let types: [HealthMetricType] = [
            .steps,
            .activeEnergy,
            .heartRate,
            .sleepHours,
            .sleepQuality,
            .weight,
            .mindfulMinutes,
            .workouts,
            .standHours,
            .waterIntake
        ]
        
        return types.compactMap { getHealthMetricViewModel(for: $0) }
    }
    
    /// Get health metrics for a specific category
    func getHealthMetrics(for category: GoalCategory) -> [HealthMetricViewModel] {
        switch category {
        case .fitness:
            return [
                getHealthMetricViewModel(for: .steps),
                getHealthMetricViewModel(for: .activeEnergy),
                getHealthMetricViewModel(for: .workouts)
            ].compactMap { $0 }
            
        case .sleep:
            return [
                getHealthMetricViewModel(for: .sleepHours),
                getHealthMetricViewModel(for: .sleepQuality)
            ].compactMap { $0 }
            
        case .mindfulness:
            return [
                getHealthMetricViewModel(for: .mindfulMinutes)
            ].compactMap { $0 }
            
        case .nutrition:
            return [
                getHealthMetricViewModel(for: .waterIntake),
                getHealthMetricViewModel(for: .weight)
            ].compactMap { $0 }
            
        case .habit:
            return []
        default:
            return []
        }
    }
    
    /// Check if a specific health metric is available
    func isMetricAvailable(_ type: HealthMetricType) -> Bool {
        switch type {
        case .steps:
            return availableDataTypes.contains(.stepCount)
        case .activeEnergy:
            return availableDataTypes.contains(.activeEnergyBurned)
        case .heartRate:
            return availableDataTypes.contains(.heartRate)
        case .sleepHours, .sleepQuality:
            // Sleep is a special case using category types
            return true
        case .weight:
            return availableDataTypes.contains(.bodyMass)
        case .mindfulMinutes:
            // Mindful minutes is a special case using category types
            return true
        case .workouts:
            // Workouts is a special case
            return true
        case .standHours:
            return availableDataTypes.contains(.appleStandTime)
        case .waterIntake:
            return availableDataTypes.contains(.dietaryWater)
        case .restingHeartRate:
            return availableDataTypes.contains(.restingHeartRate)
        case .bloodPressure:
            return availableDataTypes.contains(.bloodPressureSystolic)
        default:
            return false
        }
    }
}

// MARK: - Custom Errors

enum HealthKitError: Error, LocalizedError {
    case healthKitNotAvailable
    case dataTypeNotAvailable
    case noDataAvailable
    case authorizationDenied
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device."
        case .dataTypeNotAvailable:
            return "The requested health data type is not available."
        case .noDataAvailable:
            return "No health data is available for the requested type."
        case .authorizationDenied:
            return "Authorization to access health data was denied."
        case .processingFailed:
            return "Failed to process health data."
        }
    }
}