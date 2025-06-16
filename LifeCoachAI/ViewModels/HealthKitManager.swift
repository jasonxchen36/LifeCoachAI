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
        let typesToRead = HealthMetricType.healthKitTypesToRead
        
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
    
    // MARK: - Data Fetching
    
    /// Fetch initial health data after authorization
    func fetchInitialHealthData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Fetch today's metrics
        group.enter()
        fetchTodaySteps { _ in group.leave() }
        
        group.enter()
        fetchTodayActiveEnergy { _ in group.leave() }
        
        group.enter()
        fetchTodayStandHours { _ in group.leave() }
        
        group.enter()
        fetchTodayMindfulMinutes { _ in group.leave() }
        
        group.enter()
        fetchTodayWaterIntake { _ in group.leave() }
        
        group.enter()
        fetchLatestHeartRate { _ in group.leave() }
        
        group.enter()
        fetchLatestRestingHeartRate { _ in group.leave() }
        
        group.enter()
        fetchLatestWeight { _ in group.leave() }
        
        group.enter()
        fetchLatestSleepData { _ in group.leave() }
        
        group.enter()
        fetchRecentWorkouts { _ in group.leave() }
        
        // Fetch weekly data
        group.enter()
        fetchWeeklyData { _ in group.leave() }
        
        // When all fetches are complete
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.lastSyncDate = Date()
            self?.logger.info("Initial health data fetch completed")
            
            // Start observing changes
            self?.startObservingHealthData()
        }
    }
    
    /// Start observing real-time changes to health data
    func startObservingHealthData() {
        observeStepCount()
        observeHeartRate()
        observeActiveEnergy()
        observeWaterIntake()
        observeSleep()
    }
    
    /// Stop observing health data changes
    func stopObservingHealthData() {
        // Stop all active queries
        for (_, query) in activeQueries {
            healthStore.stop(query)
        }
        activeQueries.removeAll()
    }
    
    // MARK: - Step Count Methods
    
    /// Fetch today's step count
    func fetchTodaySteps(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching step count: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todaySteps = 0
                    completion(.success(0))
                    return
                }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                self?.todaySteps = steps
                self?.logger.info("Fetched today's steps: \(steps)")
                completion(.success(steps))
                
                // Save to Core Data if context is available
                self?.saveHealthMetricToCoreData(
                    type: .steps,
                    value: steps,
                    date: now,
                    unit: "steps",
                    source: "HealthKit"
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Observe step count changes in real-time
    private func observeStepCount() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        // Stop any existing query
        if let existingQuery = activeQueries[stepType] {
            healthStore.stop(existingQuery)
            activeQueries.removeValue(forKey: stepType)
        }
        
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.logger.error("Step count observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Fetch the updated step count
            self?.fetchTodaySteps { _ in
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        activeQueries[stepType] = query
        
        // Also enable background delivery if possible
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if let error = error {
                self.logger.error("Failed to enable background delivery for steps: \(error.localizedDescription)")
            } else if success {
                self.logger.info("Background delivery enabled for steps")
            }
        }
    }
    
    // MARK: - Active Energy Methods
    
    /// Fetch today's active energy burned
    func fetchTodayActiveEnergy(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching active energy: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayActiveEnergy = 0
                    completion(.success(0))
                    return
                }
                
                let energy = sum.doubleValue(for: HKUnit.kilocalorie())
                self?.todayActiveEnergy = energy
                self?.logger.info("Fetched today's active energy: \(energy) kcal")
                completion(.success(energy))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .activeEnergy,
                    value: energy,
                    date: now,
                    unit: "kcal",
                    source: "HealthKit"
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Observe active energy changes
    private func observeActiveEnergy() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        // Stop any existing query
        if let existingQuery = activeQueries[energyType] {
            healthStore.stop(existingQuery)
            activeQueries.removeValue(forKey: energyType)
        }
        
        let query = HKObserverQuery(sampleType: energyType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.logger.error("Active energy observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Fetch the updated active energy
            self?.fetchTodayActiveEnergy { _ in
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        activeQueries[energyType] = query
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: energyType, frequency: .hourly) { success, error in
            if let error = error {
                self.logger.error("Failed to enable background delivery for active energy: \(error.localizedDescription)")
            } else if success {
                self.logger.info("Background delivery enabled for active energy")
            }
        }
    }
    
    // MARK: - Heart Rate Methods
    
    /// Fetch latest heart rate measurement
    func fetchLatestHeartRate(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching heart rate: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    self?.latestHeartRate = 0
                    completion(.success(0))
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                self?.latestHeartRate = heartRate
                self?.logger.info("Fetched latest heart rate: \(heartRate) BPM")
                completion(.success(heartRate))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .heartRate,
                    value: heartRate,
                    date: sample.endDate,
                    unit: "BPM",
                    source: sample.sourceRevision.source.name
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch latest resting heart rate
    func fetchLatestRestingHeartRate(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: restingHeartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching resting heart rate: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    self?.latestRestingHeartRate = 0
                    completion(.success(0))
                    return
                }
                
                let restingHeartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                self?.latestRestingHeartRate = restingHeartRate
                self?.logger.info("Fetched latest resting heart rate: \(restingHeartRate) BPM")
                completion(.success(restingHeartRate))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .restingHeartRate,
                    value: restingHeartRate,
                    date: sample.endDate,
                    unit: "BPM",
                    source: sample.sourceRevision.source.name
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Observe heart rate changes
    private func observeHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Stop any existing query
        if let existingQuery = activeQueries[heartRateType] {
            healthStore.stop(existingQuery)
            activeQueries.removeValue(forKey: heartRateType)
        }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.logger.error("Heart rate observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Fetch the updated heart rate
            self?.fetchLatestHeartRate { _ in
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        activeQueries[heartRateType] = query
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                self.logger.error("Failed to enable background delivery for heart rate: \(error.localizedDescription)")
            } else if success {
                self.logger.info("Background delivery enabled for heart rate")
            }
        }
    }
    
    // MARK: - Weight Methods
    
    /// Fetch latest weight measurement
    func fetchLatestWeight(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching weight: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    self?.latestWeight = 0
                    completion(.success(0))
                    return
                }
                
                let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                self?.latestWeight = weight
                self?.logger.info("Fetched latest weight: \(weight) kg")
                completion(.success(weight))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .weight,
                    value: weight,
                    date: sample.endDate,
                    unit: "kg",
                    source: sample.sourceRevision.source.name
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Stand Hours Methods
    
    /// Fetch today's stand hours
    func fetchTodayStandHours(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: standType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching stand hours: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayStandHours = 0
                    completion(.success(0))
                    return
                }
                
                // Convert seconds to hours
                let standSeconds = sum.doubleValue(for: HKUnit.second())
                let standHours = standSeconds / 3600
                self?.todayStandHours = standHours
                self?.logger.info("Fetched today's stand hours: \(standHours)")
                completion(.success(standHours))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .standHours,
                    value: standHours,
                    date: now,
                    unit: "hours",
                    source: "HealthKit"
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Mindful Minutes Methods
    
    /// Fetch today's mindful minutes
    func fetchTodayMindfulMinutes(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: mindfulType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching mindful minutes: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let samples = samples else {
                    self?.todayMindfulMinutes = 0
                    completion(.success(0))
                    return
                }
                
                // Calculate total mindful minutes
                var totalSeconds = 0.0
                for sample in samples {
                    totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }
                
                // Convert to minutes
                let minutes = totalSeconds / 60
                self?.todayMindfulMinutes = minutes
                self?.logger.info("Fetched today's mindful minutes: \(minutes)")
                completion(.success(minutes))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .mindfulMinutes,
                    value: minutes,
                    date: now,
                    unit: "min",
                    source: "HealthKit"
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Water Intake Methods
    
    /// Fetch today's water intake
    func fetchTodayWaterIntake(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: waterType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching water intake: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    self?.todayWaterIntake = 0
                    completion(.success(0))
                    return
                }
                
                // Convert liters to milliliters
                let waterLiters = sum.doubleValue(for: HKUnit.liter())
                let waterMilliliters = waterLiters * 1000
                self?.todayWaterIntake = waterMilliliters
                self?.logger.info("Fetched today's water intake: \(waterMilliliters) ml")
                completion(.success(waterMilliliters))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .waterIntake,
                    value: waterMilliliters,
                    date: now,
                    unit: "ml",
                    source: "HealthKit"
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Observe water intake changes
    private func observeWaterIntake() {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        // Stop any existing query
        if let existingQuery = activeQueries[waterType] {
            healthStore.stop(existingQuery)
            activeQueries.removeValue(forKey: waterType)
        }
        
        let query = HKObserverQuery(sampleType: waterType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.logger.error("Water intake observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Fetch the updated water intake
            self?.fetchTodayWaterIntake { _ in
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        activeQueries[waterType] = query
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: waterType, frequency: .immediate) { success, error in
            if let error = error {
                self.logger.error("Failed to enable background delivery for water intake: \(error.localizedDescription)")
            } else if success {
                self.logger.info("Background delivery enabled for water intake")
            }
        }
    }
    
    // MARK: - Sleep Methods
    
    /// Fetch latest sleep data
    func fetchLatestSleepData(completion: @escaping (Result<(hours: Double, quality: Double), Error>) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        // Get sleep data for the past 24 hours
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching sleep data: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    self?.latestSleepHours = 0
                    self?.latestSleepQuality = 0
                    completion(.success((hours: 0, quality: 0)))
                    return
                }
                
                // Process sleep samples
                var totalSleepTime: TimeInterval = 0
                var deepSleepTime: TimeInterval = 0
                var inBedTime: TimeInterval = 0
                
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    // Skip very short samples (less than 1 minute)
                    if duration < 60 {
                        continue
                    }
                    
                    if #available(iOS 16.0, *) {
                        // iOS 16+ has more detailed sleep stages
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.inBed.rawValue:
                            inBedTime += duration
                        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                            totalSleepTime += duration
                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                            totalSleepTime += duration
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            totalSleepTime += duration
                            deepSleepTime += duration
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            totalSleepTime += duration
                            deepSleepTime += duration // Count REM as quality sleep
                        default:
                            break
                        }
                    } else {
                        // Pre-iOS 16 has simpler sleep categorization
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.inBed.rawValue:
                            inBedTime += duration
                        case HKCategoryValueSleepAnalysis.asleep.rawValue:
                            totalSleepTime += duration
                            // Estimate deep sleep as 20% of total sleep
                            deepSleepTime += duration * 0.2
                        default:
                            break
                        }
                    }
                }
                
                // Convert to hours
                let sleepHours = totalSleepTime / 3600
                
                // Calculate sleep quality (percentage of deep sleep + REM)
                var sleepQuality = totalSleepTime > 0 ? (deepSleepTime / totalSleepTime) * 100 : 0
                
                // If in bed time is available and significantly larger than sleep time,
                // factor that into quality calculation
                if inBedTime > totalSleepTime * 1.2 {
                    let efficiencyFactor = totalSleepTime / inBedTime
                    sleepQuality *= efficiencyFactor
                }
                
                // Cap quality at 100%
                sleepQuality = min(sleepQuality, 100)
                
                self?.latestSleepHours = sleepHours
                self?.latestSleepQuality = sleepQuality
                
                self?.logger.info("Fetched sleep data: \(sleepHours) hours, \(sleepQuality)% quality")
                completion(.success((hours: sleepHours, quality: sleepQuality)))
                
                // Save to Core Data
                self?.saveHealthMetricToCoreData(
                    type: .sleepHours,
                    value: sleepHours,
                    date: now,
                    unit: "hours",
                    source: "HealthKit"
                )
                
                self?.saveHealthMetricToCoreData(
                    type: .sleepQuality,
                    value: sleepQuality,
                    date: now,
                    unit: "%",
                    source: "HealthKit"
                )
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Observe sleep data changes
    private func observeSleep() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        // Stop any existing query
        if let existingQuery = activeQueries[sleepType] {
            healthStore.stop(existingQuery)
            activeQueries.removeValue(forKey: sleepType)
        }
        
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.logger.error("Sleep observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            // Fetch the updated sleep data
            self?.fetchLatestSleepData { _ in
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        activeQueries[sleepType] = query
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .daily) { success, error in
            if let error = error {
                self.logger.error("Failed to enable background delivery for sleep: \(error.localizedDescription)")
            } else if success {
                self.logger.info("Background delivery enabled for sleep")
            }
        }
    }
    
    // MARK: - Workout Methods
    
    /// Fetch recent workouts
    func fetchRecentWorkouts(completion: @escaping (Result<[HKWorkout], Error>) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        // Get workouts from the past week
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: oneWeekAgo, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: 10, // Limit to 10 recent workouts
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Error fetching workouts: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    self?.recentWorkouts = []
                    completion(.success([]))
                    return
                }
                
                self?.recentWorkouts = workouts
                self?.logger.info("Fetched \(workouts.count) recent workouts")
                completion(.success(workouts))
                
                // Process workout data for insights
                self?.processWorkoutsForInsights(workouts)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Process workouts for insights and recommendations
    private func processWorkoutsForInsights(_ workouts: [HKWorkout]) {
        // Calculate total workout minutes for today
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let todayWorkouts = workouts.filter { 
            $0.endDate >= startOfDay && $0.endDate <= now
        }
        
        let todayWorkoutMinutes = todayWorkouts.reduce(0.0) { total, workout in
            total + workout.duration / 60
        }
        
        // Update exercise minutes
        self.todayExerciseMinutes = todayWorkoutMinutes
        
        // Save to Core Data
        self.saveHealthMetricToCoreData(
            type: .workouts,
            value: todayWorkoutMinutes,
            date: now,
            unit: "min",
            source: "HealthKit"
        )
    }
    
    // MARK: - Weekly Data Methods
    
    /// Fetch weekly data for charts and trends
    func fetchWeeklyData(completion: @escaping (Result<[String: [Date: Double]], Error>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let group = DispatchGroup()
        
        // Fetch weekly steps
        group.enter()
        fetchWeeklyMetric(
            type: .stepCount,
            startDate: oneWeekAgo,
            endDate: now,
            unit: .count(),
            intervalComponents: DateComponents(day: 1)
        ) { [weak self] result in
            switch result {
            case .success(let data):
                self?.weeklyStepsData = data
                self?.calculateWeeklyAverage(from: data, metricType: .steps)
            case .failure(let error):
                self?.logger.error("Error fetching weekly steps: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Fetch weekly active energy
        group.enter()
        fetchWeeklyMetric(
            type: .activeEnergyBurned,
            startDate: oneWeekAgo,
            endDate: now,
            unit: .kilocalorie(),
            intervalComponents: DateComponents(day: 1)
        ) { [weak self] result in
            switch result {
            case .success(let data):
                self?.weeklyActiveEnergyData = data
                self?.calculateWeeklyAverage(from: data, metricType: .activeEnergy)
            case .failure(let error):
                self?.logger.error("Error fetching weekly active energy: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Fetch weekly sleep (requires special handling)
        group.enter()
        fetchWeeklySleep(startDate: oneWeekAgo, endDate: now) { [weak self] result in
            switch result {
            case .success(let data):
                self?.weeklySleepData = data
                self?.calculateWeeklyAverage(from: data, metricType: .sleepHours)
            case .failure(let error):
                self?.logger.error("Error fetching weekly sleep: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Fetch weekly heart rate
        group.enter()
        fetchWeeklyHeartRateAverage(startDate: oneWeekAgo, endDate: now) { [weak self] result in
            switch result {
            case .success(let data):
                self?.weeklyHeartRateData = data
            case .failure(let error):
                self?.logger.error("Error fetching weekly heart rate: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Fetch weekly mindful minutes
        group.enter()
        fetchWeeklyMindfulMinutes(startDate: oneWeekAgo, endDate: now) { [weak self] result in
            switch result {
            case .success(let data):
                self?.weeklyMindfulMinutesData = data
            case .failure(let error):
                self?.logger.error("Error fetching weekly mindful minutes: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Fetch weekly water intake
        group.enter()
        fetchWeeklyMetric(
            type: .dietaryWater,
            startDate: oneWeekAgo,
            endDate: now,
            unit: .liter(),
            intervalComponents: DateComponents(day: 1),
            options: .cumulativeSum
        ) { [weak self] result in
            switch result {
            case .success(let data):
                // Convert liters to milliliters
                var mlData: [Date: Double] = [:]
                for (date, value) in data {
                    mlData[date] = value * 1000
                }
                self?.weeklyWaterIntakeData = mlData
            case .failure(let error):
                self?.logger.error("Error fetching weekly water intake: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // When all fetches complete
        group.notify(queue: .main) {
            // Combine all data
            var allData: [String: [Date: Double]] = [
                "steps": self.weeklyStepsData,
                "activeEnergy": self.weeklyActiveEnergyData,
                "sleep": self.weeklySleepData,
                "heartRate": self.weeklyHeartRateData,
                "mindfulMinutes": self.weeklyMindfulMinutesData,
                "waterIntake": self.weeklyWaterIntakeData
            ]
            
            completion(.success(allData))
        }
    }
    
    /// Fetch weekly data for a specific metric
    private func fetchWeeklyMetric(
        type: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        unit: HKUnit,
        intervalComponents: DateComponents,
        options: HKStatisticsOptions = .cumulativeSum,
        completion: @escaping (Result<[Date: Double], Error>) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: options,
            anchorDate: startDate,
            intervalComponents: intervalComponents
        )
        
        query.initialResultsHandler = { query, collection, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let collection = collection else {
                    completion(.failure(HealthKitError.noDataAvailable))
                    return
                }
                
                var results: [Date: Double] = [:]
                
                collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let quantity = options == .cumulativeSum ? statistics.sumQuantity() : statistics.averageQuantity() {
                        let value = quantity.doubleValue(for: unit)
                        results[statistics.startDate] = value
                    } else {
                        results[statistics.startDate] = 0
                    }
                }
                
                completion(.success(results))
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch weekly sleep data
    private func fetchWeeklySleep(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[Date: Double], Error>) -> Void
    ) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    completion(.success([:]))
                    return
                }
                
                // Group samples by day
                let calendar = Calendar.current
                var sleepByDay: [Date: TimeInterval] = [:]
                
                for sample in samples {
                    // Skip very short samples (less than 1 minute)
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    if duration < 60 {
                        continue
                    }
                    
                    // Use the start date's day as the key
                    let day = calendar.startOfDay(for: sample.startDate)
                    
                    // Only count asleep time, not in bed time
                    var sleepTime: TimeInterval = 0
                    
                    if #available(iOS 16.0, *) {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                             HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                             HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                             HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            sleepTime = duration
                        default:
                            break
                        }
                    } else {
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            sleepTime = duration
                        }
                    }
                    
                    // Add to the day's total
                    if sleepTime > 0 {
                        sleepByDay[day, default: 0] += sleepTime
                    }
                }
                
                // Convert seconds to hours
                var sleepHoursByDay: [Date: Double] = [:]
                for (day, seconds) in sleepByDay {
                    sleepHoursByDay[day] = seconds / 3600
                }
                
                completion(.success(sleepHoursByDay))
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch weekly heart rate averages
    private func fetchWeeklyHeartRateAverage(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[Date: Double], Error>) -> Void
    ) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { query, collection, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let collection = collection else {
                    completion(.failure(HealthKitError.noDataAvailable))
                    return
                }
                
                var results: [Date: Double] = [:]
                
                collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let quantity = statistics.averageQuantity() {
                        let value = quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                        results[statistics.startDate] = value
                    } else {
                        results[statistics.startDate] = 0
                    }
                }
                
                completion(.success(results))
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch weekly mindful minutes
    private func fetchWeeklyMindfulMinutes(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[Date: Double], Error>) -> Void
    ) {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: mindfulType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let samples = samples, !samples.isEmpty else {
                    completion(.success([:]))
                    return
                }
                
                // Group samples by day
                let calendar = Calendar.current
                var minutesByDay: [Date: TimeInterval] = [:]
                
                for sample in samples {
                    // Calculate duration
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    // Use the start date's day as the key
                    let day = calendar.startOfDay(for: sample.startDate)
                    
                    // Add to the day's total
                    minutesByDay[day, default: 0] += duration
                }
                
                // Convert seconds to minutes
                var mindfulMinutesByDay: [Date: Double] = [:]
                for (day, seconds) in minutesByDay {
                    mindfulMinutesByDay[day] = seconds / 60
                }
                
                completion(.success(mindfulMinutesByDay))
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Calculate weekly average for a metric
    private func calculateWeeklyAverage(from data: [Date: Double], metricType: HealthMetricType) {
        guard !data.isEmpty else { return }
        
        let total = data.values.reduce(0, +)
        let average = total / Double(data.count)
        
        switch metricType {
        case .steps:
            self.weeklyAverageSteps = average
        case .activeEnergy:
            self.weeklyAverageActiveEnergy = average
        case .sleepHours:
            self.weeklyAverageSleepHours = average
        default:
            break
        }
    }
    
    // MARK: - Background Processing
    
    /// Process health data in the background
    func processHealthDataInBackground() async throws {
        // This method is called by the background task
        // Fetch and process health data
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        // Create a task group for parallel processing
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Add tasks for each health metric
            group.addTask {
                try await self.processBackgroundMetric(.stepCount, startDate: startOfDay, endDate: now)
            }
            
            group.addTask {
                try await self.processBackgroundMetric(.activeEnergyBurned, startDate: startOfDay, endDate: now)
            }
            
            group.addTask {
                try await self.processBackgroundMetric(.heartRate, startDate: startOfDay, endDate: now)
            }
            
            group.addTask {
                try await self.processBackgroundSleep(startDate: startOfDay, endDate: now)
            }
            
            // Wait for all tasks to complete
            for try await _ in group { }
        }
        
        // Update last sync date
        DispatchQueue.main.async {
            self.lastSyncDate = now
        }
        
        logger.info("Background health data processing completed")
    }
    
    /// Process a specific health metric in the background
    private func processBackgroundMetric(
        _ identifier: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date
    ) async throws {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Create a query to get the data
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume()
                    return
                }
                
                // Get the appropriate unit for this metric type
                let unit: HKUnit
                let metricType: HealthMetricType
                
                switch identifier {
                case .stepCount:
                    unit = HKUnit.count()
                    metricType = .steps
                case .activeEnergyBurned:
                    unit = HKUnit.kilocalorie()
                    metricType = .activeEnergy
                case .heartRate:
                    unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    metricType = .heartRate
                default:
                    continuation.resume()
                    return
                }
                
                let value = sum.doubleValue(for: unit)
                
                // Save to Core Data
                DispatchQueue.main.async {
                    self.saveHealthMetricToCoreData(
                        type: metricType,
                        value: value,
                        date: endDate,
                        unit: metricType.unit,
                        source: "HealthKit"
                    )
                }
                
                continuation.resume()
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Process sleep data in the background
    private func processBackgroundSleep(startDate: Date, endDate: Date) async throws {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Create a query to get the sleep data
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume()
                    return
                }
                
                // Process sleep samples
                var totalSleepTime: TimeInterval = 0
                var deepSleepTime: TimeInterval = 0
                
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    // Skip very short samples
                    if duration < 60 {
                        continue
                    }
                    
                    if #available(iOS 16.0, *) {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                             HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                            totalSleepTime += duration
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                             HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            totalSleepTime += duration
                            deepSleepTime += duration
                        default:
                            break
                        }
                    } else {
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            totalSleepTime += duration
                            // Estimate deep sleep as 20% of total sleep
                            deepSleepTime += duration * 0.2
                        }
                    }
                }
                
                // Convert to hours
                let sleepHours = totalSleepTime / 3600
                
                // Calculate sleep quality
                let sleepQuality = totalSleepTime > 0 ? (deepSleepTime / totalSleepTime) * 100 : 0
                
                // Save to Core Data
                DispatchQueue.main.async {
                    self.saveHealthMetricToCoreData(
                        type: .sleepHours,
                        value: sleepHours,
                        date: endDate,
                        unit: "hours",
                        source: "HealthKit"
                    )
                    
                    self.saveHealthMetricToCoreData(
                        type: .sleepQuality,
                        value: sleepQuality,
                        date: endDate,
                        unit: "%",
                        source: "HealthKit"
                    )
                }
                
                continuation.resume()
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Core Data Integration
    
    /// Save health metric to Core Data
    private func saveHealthMetricToCoreData(
        type: HealthMetricType,
        value: Double,
        date: Date,
        unit: String,
        source: String
    ) {
        guard let context = viewContext, value > 0 else { return }
        
        // Check if we already have this metric for today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<HealthMetric> = HealthMetric.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metricType == %@", type.rawValue),
            NSPredicate(format: "date >= %@", startOfDay as NSDate),
            NSPredicate(format: "date < %@", endOfDay as NSDate)
        ])
        fetchRequest.fetchLimit = 1
        
        do {
            let existingMetrics = try context.fetch(fetchRequest)
            
            if let existingMetric = existingMetrics.first {
                // Update existing metric
                existingMetric.value = value
                existingMetric.setValue(date, forKey: "date")
                existingMetric.setValue(source, forKey: "source")
            } else {
                // Create new metric
                let newMetric = HealthMetric(context: context)
                newMetric.id = UUID()
                newMetric.metricType = type.rawValue
                newMetric.value = value
                newMetric.date = date
                newMetric.unit = unit
                newMetric.source = source
                newMetric.isManualEntry = false
                newMetric.healthKitIdentifier = type.healthKitType?.identifier
                
                // Find user profile to associate with
                let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
                if let userProfile = try? context.fetch(profileRequest).first {
                    newMetric.userProfile = userProfile
                }
            }
            
            // Save context
            try context.save()
            logger.info("Saved \(type.rawValue) metric to Core Data: \(value) \(unit)")
        } catch {
            logger.error("Failed to save health metric to Core Data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Mock Data for Simulator
    
    /// Load mock data for simulator testing
    func loadMockData() {
        logger.info("Loading mock health data for simulator")
        
        // Generate mock data
        let mockSteps = Double.random(in: 6000...12000)
        let mockActiveEnergy = Double.random(in: 300...600)
        let mockHeartRate = Double.random(in: 65...85)
        let mockRestingHeartRate = Double.random(in: 55...70)
        let mockSleepHours = Double.random(in: 6.5...8.5)
        let mockSleepQuality = Double.random(in: 75...95)
        let mockWeight = Double.random(in: 65...85)
        let mockStandHours = Double.random(in: 8...14)
        let mockMindfulMinutes = Double.random(in: 5...20)
        let mockWaterIntake = Double.random(in: 1000...2000)
        
        // Set mock data
        DispatchQueue.main.async {
            self.isHealthKitAuthorized = true
            self.todaySteps = mockSteps
            self.todayActiveEnergy = mockActiveEnergy
            self.latestHeartRate = mockHeartRate
            self.latestRestingHeartRate = mockRestingHeartRate
            self.latestSleepHours = mockSleepHours
            self.latestSleepQuality = mockSleepQuality
            self.latestWeight = mockWeight
            self.todayStandHours = mockStandHours
            self.todayMindfulMinutes = mockMindfulMinutes
            self.todayWaterIntake = mockWaterIntake
            self.todayExerciseMinutes = Double.random(in: 20...60)
            
            // Load mock weekly data
            self.loadMockWeeklyData()
            
            // Generate mock workouts
            self.loadMockWorkouts()
            
            self.lastSyncDate = Date()
        }
    }
    
    /// Load mock weekly data
    private func loadMockWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        
        var stepsData: [Date: Double] = [:]
        var energyData: [Date: Double] = [:]
        var sleepData: [Date: Double] = [:]
        var heartRateData: [Date: Double] = [:]
        var mindfulData: [Date: Double] = [:]
        var waterData: [Date: Double] = [:]
        
        // Generate data for the past week
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                
                // Generate realistic patterns
                let weekday = calendar.component(.weekday, from: date)
                let isWeekend = weekday == 1 || weekday == 7
                
                // Steps: lower on weekends, random variation on weekdays
                let baseSteps = isWeekend ? 7000.0 : 10000.0
                let stepsVariation = Double.random(in: 0.7...1.3)
                stepsData[dayStart] = baseSteps * stepsVariation
                
                // Energy: correlates with steps
                let baseEnergy = isWeekend ? 350.0 : 500.0
                let energyVariation = Double.random(in: 0.8...1.2)
                energyData[dayStart] = baseEnergy * energyVariation
                
                // Sleep: more on weekends, less on weekdays
                let baseSleep = isWeekend ? 8.5 : 7.5
                let sleepVariation = Double.random(in: 0.9...1.1)
                sleepData[dayStart] = baseSleep * sleepVariation
                
                // Heart rate: higher on active days
                let baseHeartRate = 70.0
                let heartRateVariation = (stepsVariation - 1.0) * 10 + Double.random(in: -5...5)
                heartRateData[dayStart] = baseHeartRate + heartRateVariation
                
                // Mindful minutes: more consistent pattern
                let baseMindful = 10.0
                let mindfulVariation = Double.random(in: 0.5...1.5)
                mindfulData[dayStart] = baseMindful * mindfulVariation
                
                // Water intake: correlates with activity
                let baseWater = 1500.0
                let waterVariation = (stepsVariation + energyVariation) / 2
                waterData[dayStart] = baseWater * waterVariation
            }
        }
        
        // Set the weekly data
        self.weeklyStepsData = stepsData
        self.weeklyActiveEnergyData = energyData
        self.weeklySleepData = sleepData
        self.weeklyHeartRateData = heartRateData
        self.weeklyMindfulMinutesData = mindfulData
        self.weeklyWaterIntakeData = waterData
        
        // Calculate averages
        self.weeklyAverageSteps = stepsData.values.reduce(0, +) / Double(stepsData.count)
        self.weeklyAverageActiveEnergy = energyData.values.reduce(0, +) / Double(energyData.count)
        self.weeklyAverageSleepHours = sleepData.values.reduce(0, +) / Double(sleepData.count)
    }
    
    /// Load mock workouts
    private func loadMockWorkouts() {
        // This is a simplified version since we can't create actual HKWorkout objects
        // In a real app, we'd use the actual data from HealthKit
        
        // Instead, we'll just log that mock workouts would be created
        logger.info("Mock workouts would be created here for simulator")
        
        // In a real implementation, we might create our own workout model objects
        // and populate them with mock data for the UI to display
    }
    
    // MARK: - Notification Observers
    
    /// Set up notification observers
    private func setupNotificationObservers() {
        // Observe when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Observe when app enters background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Refresh health data when app becomes active
        if isHealthKitAuthorized {
            fetchInitialHealthData()
        }
    }
    
    @objc private func appDidEnterBackground() {
        // Clean up when app enters background
        stopObservingHealthData()
    }
    
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
            // No previous or goal for heart rate
        case .sleepHours:
            value = latestSleepHours
            previousValue = weeklyAverageSleepHours
            goalValue = 8.0
        case .sleepQuality:
            value = latestSleepQuality
            goalValue = 85
        case .weight:
            value = latestWeight
            // Goal would be personalized
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
            date: now,
            previousValue: previousValue,
            goalValue: goalValue
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
        case .physical:
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
        case .oxygenSaturation:
            return availableDataTypes.contains(.oxygenSaturation)
        case .respiratoryRate:
            return availableDataTypes.contains(.respiratoryRate)
        case .bodyFat:
            return availableDataTypes.contains(.bodyFatPercentage)
        case .bmi:
            return availableDataTypes.contains(.bodyMassIndex)
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
