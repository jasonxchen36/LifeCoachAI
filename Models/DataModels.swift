//
//  DataModels.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import SwiftUI
import HealthKit
import CoreData
import Combine

// MARK: - Category Enums

/// Categories for goals and recommendations
enum GoalCategory: String, CaseIterable, Identifiable, Codable {
    case physical = "Physical"
    case mental = "Mental"
    case sleep = "Sleep"
    case nutrition = "Nutrition"
    case mindfulness = "Mindfulness"
    case productivity = "Productivity"
    case social = "Social"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .physical: return "figure.walk"
        case .mental: return "brain"
        case .sleep: return "bed.double"
        case .nutrition: return "fork.knife"
        case .mindfulness: return "leaf"
        case .productivity: return "checklist"
        case .social: return "person.2"
        case .other: return "star"
        }
    }
    
    var color: Color {
        switch self {
        case .physical: return Color("PhysicalColor")
        case .mental: return Color("MentalColor")
        case .sleep: return Color("SleepColor")
        case .nutrition: return Color("NutritionColor")
        case .mindfulness: return Color("MindfulnessColor")
        case .productivity: return Color("ProductivityColor")
        case .social: return Color("SocialColor")
        case .other: return Color("OtherColor")
        }
    }
    
    var description: String {
        switch self {
        case .physical: return "Physical activity and exercise"
        case .mental: return "Mental health and well-being"
        case .sleep: return "Sleep quality and habits"
        case .nutrition: return "Nutrition and diet"
        case .mindfulness: return "Mindfulness and meditation"
        case .productivity: return "Productivity and focus"
        case .social: return "Social connections and relationships"
        case .other: return "Other goals and habits"
        }
    }
}

/// Categories for audio sessions
enum AudioCategory: String, CaseIterable, Identifiable, Codable {
    case meditation = "Meditation"
    case sleep = "Sleep"
    case focus = "Focus"
    case motivation = "Motivation"
    case anxiety = "Anxiety"
    case stress = "Stress"
    case gratitude = "Gratitude"
    case morning = "Morning"
    case evening = "Evening"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .meditation: return "leaf"
        case .sleep: return "moon.stars"
        case .focus: return "target"
        case .motivation: return "flame"
        case .anxiety: return "waveform.path"
        case .stress: return "heart.slash"
        case .gratitude: return "heart.text.square"
        case .morning: return "sunrise"
        case .evening: return "sunset"
        }
    }
    
    var color: Color {
        switch self {
        case .meditation: return Color("MeditationColor")
        case .sleep: return Color("SleepColor")
        case .focus: return Color("FocusColor")
        case .motivation: return Color("MotivationColor")
        case .anxiety: return Color("AnxietyColor")
        case .stress: return Color("StressColor")
        case .gratitude: return Color("GratitudeColor")
        case .morning: return Color("MorningColor")
        case .evening: return Color("EveningColor")
        }
    }
}

/// Mood categories for tracking emotional state
enum MoodState: Int, CaseIterable, Identifiable, Codable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case veryGood = 5
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .veryBad: return "Very Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryBad: return "😞"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }
    
    var color: Color {
        switch self {
        case .veryBad: return Color.red
        case .bad: return Color.orange
        case .neutral: return Color.yellow
        case .good: return Color.green
        case .veryGood: return Color.blue
        }
    }
}

// MARK: - Status Enums

/// Status for goals and habits
enum GoalStatus: String, CaseIterable, Identifiable, Codable {
    case active = "Active"
    case completed = "Completed"
    case paused = "Paused"
    case abandoned = "Abandoned"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .active: return "play.circle"
        case .completed: return "checkmark.circle"
        case .paused: return "pause.circle"
        case .abandoned: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return Color.blue
        case .completed: return Color.green
        case .paused: return Color.orange
        case .abandoned: return Color.gray
        }
    }
}

/// Status for recommendations
enum RecommendationStatus: String, CaseIterable, Identifiable, Codable {
    case active = "Active"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .active: return "bell"
        case .accepted: return "checkmark.circle"
        case .declined: return "xmark.circle"
        case .expired: return "clock"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return Color.blue
        case .accepted: return Color.green
        case .declined: return Color.red
        case .expired: return Color.gray
        }
    }
}

// MARK: - Frequency Enums

/// Frequency for goals and habits
enum GoalFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekdays: return "calendar.badge.clock"
        case .weekends: return "calendar.badge.exclamationmark"
        case .weekly: return "calendar.circle"
        case .monthly: return "calendar"
        case .custom: return "calendar.badge.plus"
        }
    }
    
    /// Returns the days of the week for this frequency
    var daysOfWeek: [Int] {
        switch self {
        case .daily:
            return [1, 2, 3, 4, 5, 6, 7] // Sunday = 1, Saturday = 7
        case .weekdays:
            return [2, 3, 4, 5, 6] // Monday to Friday
        case .weekends:
            return [1, 7] // Sunday and Saturday
        case .weekly:
            return [2] // Monday by default
        case .monthly:
            return [1] // First day of month
        case .custom:
            return [] // Custom days should be specified separately
        }
    }
    
    /// Returns the next due date based on the frequency
    func nextDueDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
            
        case .weekdays:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let weekday = calendar.component(.weekday, from: nextDate)
            
            // If next day is Sunday (1) or Saturday (7), adjust to Monday
            if weekday == 1 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            } else if weekday == 7 {
                nextDate = calendar.date(byAdding: .day, value: 2, to: nextDate) ?? nextDate
            }
            
            return nextDate
            
        case .weekends:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let weekday = calendar.component(.weekday, from: nextDate)
            
            // If next day is not Saturday (7) or Sunday (1), adjust to Saturday
            if weekday > 1 && weekday < 7 {
                nextDate = calendar.date(byAdding: .day, value: 7 - weekday + 1, to: nextDate) ?? nextDate
            }
            
            return nextDate
            
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
            
        case .custom:
            // Default to daily for custom
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Health Metric Types

/// HealthKit metric types supported by the app
enum HealthMetricType: String, CaseIterable, Identifiable, Codable {
    case steps = "Steps"
    case activeEnergy = "Active Energy"
    case heartRate = "Heart Rate"
    case sleepHours = "Sleep Hours"
    case sleepQuality = "Sleep Quality"
    case weight = "Weight"
    case mindfulMinutes = "Mindful Minutes"
    case workouts = "Workouts"
    case standHours = "Stand Hours"
    case waterIntake = "Water Intake"
    case restingHeartRate = "Resting Heart Rate"
    case bloodPressure = "Blood Pressure"
    case oxygenSaturation = "Oxygen Saturation"
    case respiratoryRate = "Respiratory Rate"
    case bodyFat = "Body Fat"
    case bmi = "BMI"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .activeEnergy: return "flame"
        case .heartRate: return "heart"
        case .sleepHours: return "bed.double"
        case .sleepQuality: return "moon.stars"
        case .weight: return "scalemass"
        case .mindfulMinutes: return "leaf"
        case .workouts: return "figure.run"
        case .standHours: return "figure.stand"
        case .waterIntake: return "drop"
        case .restingHeartRate: return "heart.text.square"
        case .bloodPressure: return "waveform.path"
        case .oxygenSaturation: return "lungs"
        case .respiratoryRate: return "wind"
        case .bodyFat: return "figure.arms.open"
        case .bmi: return "person.crop.rectangle"
        }
    }
    
    var color: Color {
        switch self {
        case .steps: return Color.green
        case .activeEnergy: return Color.orange
        case .heartRate: return Color.red
        case .sleepHours: return Color.indigo
        case .sleepQuality: return Color.purple
        case .weight: return Color.blue
        case .mindfulMinutes: return Color.mint
        case .workouts: return Color.pink
        case .standHours: return Color.teal
        case .waterIntake: return Color.cyan
        case .restingHeartRate: return Color.red.opacity(0.7)
        case .bloodPressure: return Color.red.opacity(0.5)
        case .oxygenSaturation: return Color.blue.opacity(0.7)
        case .respiratoryRate: return Color.gray
        case .bodyFat: return Color.blue.opacity(0.5)
        case .bmi: return Color.indigo.opacity(0.7)
        }
    }
    
    var unit: String {
        switch self {
        case .steps: return "steps"
        case .activeEnergy: return "kcal"
        case .heartRate: return "BPM"
        case .sleepHours: return "hours"
        case .sleepQuality: return "%"
        case .weight: return "kg"
        case .mindfulMinutes: return "min"
        case .workouts: return "min"
        case .standHours: return "hours"
        case .waterIntake: return "ml"
        case .restingHeartRate: return "BPM"
        case .bloodPressure: return "mmHg"
        case .oxygenSaturation: return "%"
        case .respiratoryRate: return "BPM"
        case .bodyFat: return "%"
        case .bmi: return "kg/m²"
        }
    }
    
    /// Returns the corresponding HealthKit quantity type if available
    var healthKitType: HKQuantityType? {
        switch self {
        case .steps:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .activeEnergy:
            return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        case .heartRate:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .sleepHours:
            return nil // Special handling for sleep analysis
        case .sleepQuality:
            return nil // Derived from sleep analysis
        case .weight:
            return HKQuantityType.quantityType(forIdentifier: .bodyMass)
        case .mindfulMinutes:
            return HKQuantityType.categoryType(forIdentifier: .mindfulSession) as? HKQuantityType
        case .workouts:
            return nil // Special handling for workouts
        case .standHours:
            return HKQuantityType.quantityType(forIdentifier: .appleStandTime)
        case .waterIntake:
            return HKQuantityType.quantityType(forIdentifier: .dietaryWater)
        case .restingHeartRate:
            return HKQuantityType.quantityType(forIdentifier: .restingHeartRate)
        case .bloodPressure:
            return HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        case .oxygenSaturation:
            return HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
        case .respiratoryRate:
            return HKQuantityType.quantityType(forIdentifier: .respiratoryRate)
        case .bodyFat:
            return HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
        case .bmi:
            return HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)
        }
    }
    
    /// Returns the unit used by HealthKit for this metric
    var healthKitUnit: HKUnit? {
        switch self {
        case .steps:
            return HKUnit.count()
        case .activeEnergy:
            return HKUnit.kilocalorie()
        case .heartRate, .restingHeartRate, .respiratoryRate:
            return HKUnit.count().unitDivided(by: HKUnit.minute())
        case .sleepHours:
            return HKUnit.hour()
        case .sleepQuality, .oxygenSaturation, .bodyFat:
            return HKUnit.percent()
        case .weight:
            return HKUnit.gramUnit(with: .kilo)
        case .mindfulMinutes, .workouts:
            return HKUnit.minute()
        case .standHours:
            return HKUnit.hour()
        case .waterIntake:
            return HKUnit.literUnit(with: .milli)
        case .bloodPressure:
            return HKUnit.millimeterOfMercury()
        case .bmi:
            return HKUnit.gramUnit(with: .kilo).unitDivided(by: HKUnit.meter().unitMultiplied(by: HKUnit.meter()))
        }
    }
    
    /// Returns the HealthKit types needed for read permission
    static var healthKitTypesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Add quantity types
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .heartRate,
            .bodyMass,
            .appleStandTime,
            .dietaryWater,
            .restingHeartRate,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .oxygenSaturation,
            .respiratoryRate,
            .bodyFatPercentage,
            .bodyMassIndex
        ]
        
        for typeId in quantityTypes {
            if let type = HKQuantityType.quantityType(forIdentifier: typeId) {
                types.insert(type)
            }
        }
        
        // Add category types
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulType)
        }
        
        // Add sleep analysis
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        
        // Add workout type
        types.insert(HKObjectType.workoutType())
        
        return types
    }
    
    /// Returns default goal value for this metric
    var defaultGoalValue: Double {
        switch self {
        case .steps: return 10000
        case .activeEnergy: return 500
        case .heartRate: return 0 // Not applicable as direct goal
        case .sleepHours: return 8
        case .sleepQuality: return 85
        case .weight: return 0 // Personalized
        case .mindfulMinutes: return 10
        case .workouts: return 30
        case .standHours: return 12
        case .waterIntake: return 2000
        case .restingHeartRate: return 0 // Not applicable as direct goal
        case .bloodPressure: return 0 // Not applicable as direct goal
        case .oxygenSaturation: return 0 // Not applicable as direct goal
        case .respiratoryRate: return 0 // Not applicable as direct goal
        case .bodyFat: return 0 // Personalized
        case .bmi: return 0 // Personalized
        }
    }
}

// MARK: - Audio Session Types

/// Types of audio content in the app
enum AudioSessionType: String, CaseIterable, Identifiable, Codable {
    case meditation = "Meditation"
    case guidedExercise = "Guided Exercise"
    case sleepStory = "Sleep Story"
    case affirmation = "Affirmation"
    case breathingExercise = "Breathing Exercise"
    case motivationalTalk = "Motivational Talk"
    case soundscape = "Soundscape"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .meditation: return "leaf"
        case .guidedExercise: return "figure.walk"
        case .sleepStory: return "book.closed"
        case .affirmation: return "text.bubble"
        case .breathingExercise: return "wind"
        case .motivationalTalk: return "megaphone"
        case .soundscape: return "waveform"
        }
    }
    
    var color: Color {
        switch self {
        case .meditation: return Color.mint
        case .guidedExercise: return Color.green
        case .sleepStory: return Color.indigo
        case .affirmation: return Color.orange
        case .breathingExercise: return Color.blue
        case .motivationalTalk: return Color.red
        case .soundscape: return Color.purple
        }
    }
    
    /// Returns typical duration range in seconds
    var typicalDurationRange: ClosedRange<TimeInterval> {
        switch self {
        case .meditation: return 300...1200 // 5-20 minutes
        case .guidedExercise: return 300...1800 // 5-30 minutes
        case .sleepStory: return 600...1800 // 10-30 minutes
        case .affirmation: return 60...300 // 1-5 minutes
        case .breathingExercise: return 120...600 // 2-10 minutes
        case .motivationalTalk: return 300...900 // 5-15 minutes
        case .soundscape: return 600...3600 // 10-60 minutes
        }
    }
}

// MARK: - Subscription Types

/// Subscription tiers available in the app
enum SubscriptionTier: String, CaseIterable, Identifiable, Codable {
    case free = "Free"
    case premium = "Premium"
    
    var id: String { self.rawValue }
    
    var productId: String? {
        switch self {
        case .free: return nil
        case .premium: return "com.lifecoach.ai.premium.monthly"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Basic AI recommendations",
                "Limited audio sessions (5)",
                "HealthKit data summaries",
                "Daily mood tracking",
                "Basic goal setting"
            ]
        case .premium:
            return [
                "Advanced AI coaching",
                "Full audio library (50+)",
                "Personalized meal plans",
                "Priority cloud model updates",
                "Detailed health analytics",
                "Custom goal templates",
                "Unlimited mood tracking with insights",
                "Ad-free experience",
                "Priority support"
            ]
        }
    }
    
    var monthlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .premium: return 4.99
        }
    }
    
    var yearlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .premium: return 49.99
        }
    }
    
    /// Check if a feature is available for this tier
    func hasAccess(to feature: PremiumFeature) -> Bool {
        switch self {
        case .free:
            return !feature.isPremiumOnly
        case .premium:
            return true
        }
    }
}

/// Premium features in the app
enum PremiumFeature: String, CaseIterable, Identifiable {
    case allAudioSessions = "All Audio Sessions"
    case advancedAICoaching = "Advanced AI Coaching"
    case detailedAnalytics = "Detailed Analytics"
    case customGoalTemplates = "Custom Goal Templates"
    case personalizedMealPlans = "Personalized Meal Plans"
    case priorityModelUpdates = "Priority Model Updates"
    case unlimitedMoodTracking = "Unlimited Mood Tracking"
    case exportData = "Export Data"
    case adFreeExperience = "Ad-Free Experience"
    
    var id: String { self.rawValue }
    
    var isPremiumOnly: Bool {
        switch self {
        case .allAudioSessions, .advancedAICoaching, .detailedAnalytics,
             .customGoalTemplates, .personalizedMealPlans, .priorityModelUpdates,
             .exportData, .adFreeExperience:
            return true
        case .unlimitedMoodTracking:
            return false // Basic mood tracking available in free tier
        }
    }
    
    var description: String {
        switch self {
        case .allAudioSessions:
            return "Access our complete library of 50+ guided meditations, sleep stories, and more"
        case .advancedAICoaching:
            return "Receive personalized coaching based on your goals, health data, and progress"
        case .detailedAnalytics:
            return "Get in-depth insights into your health trends, sleep patterns, and mood correlations"
        case .customGoalTemplates:
            return "Create and save custom goal templates tailored to your specific needs"
        case .personalizedMealPlans:
            return "Receive nutrition recommendations and meal plans based on your health data"
        case .priorityModelUpdates:
            return "Get the latest AI model updates first for more accurate recommendations"
        case .unlimitedMoodTracking:
            return "Track your mood with unlimited entries and detailed emotion analysis"
        case .exportData:
            return "Export your health data, goals, and progress in various formats"
        case .adFreeExperience:
            return "Enjoy the app without any advertisements or promotions"
        }
    }
    
    var icon: String {
        switch self {
        case .allAudioSessions: return "headphones"
        case .advancedAICoaching: return "brain.head.profile"
        case .detailedAnalytics: return "chart.bar.xaxis"
        case .customGoalTemplates: return "list.bullet.clipboard"
        case .personalizedMealPlans: return "fork.knife"
        case .priorityModelUpdates: return "arrow.clockwise.circle"
        case .unlimitedMoodTracking: return "face.smiling"
        case .exportData: return "square.and.arrow.up"
        case .adFreeExperience: return "hand.raised.slash"
        }
    }
}

// MARK: - UI Data Structures

/// View model for displaying goal information
struct GoalViewModel: Identifiable {
    let id: UUID
    let title: String
    let category: GoalCategory
    let progress: Double // 0.0 to 1.0
    let currentValue: Double
    let targetValue: Double
    let unit: String?
    let dueDate: Date?
    let isCompleted: Bool
    let streak: Int
    
    var formattedProgress: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }
    
    var formattedValue: String {
        if let unit = unit {
            return "\(Int(currentValue)) \(unit)"
        } else {
            return "\(Int(currentValue))"
        }
    }
    
    var formattedTarget: String {
        if let unit = unit {
            return "\(Int(targetValue)) \(unit)"
        } else {
            return "\(Int(targetValue))"
        }
    }
    
    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    var streakText: String {
        if streak == 0 {
            return "Start your streak today!"
        } else if streak == 1 {
            return "1 day streak"
        } else {
            return "\(streak) day streak"
        }
    }
}

/// View model for displaying audio session information
struct AudioSessionViewModel: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let category: AudioCategory
    let type: AudioSessionType
    let duration: TimeInterval
    let isPremium: Bool
    let isCompleted: Bool
    let completionCount: Int
    let audioFileName: String
    let imageFileName: String?
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes < 1 {
            return "< 1 min"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) mins"
        }
    }
    
    var accessibilityDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes == 0 {
            return "\(seconds) seconds"
        } else if minutes == 1 {
            return "1 minute \(seconds) seconds"
        } else {
            return "\(minutes) minutes \(seconds) seconds"
        }
    }
    
    var completionText: String {
        if completionCount == 0 {
            return "Not completed yet"
        } else if completionCount == 1 {
            return "Completed once"
        } else {
            return "Completed \(completionCount) times"
        }
    }
}

/// View model for displaying health metric information
struct HealthMetricViewModel: Identifiable {
    let id: UUID
    let type: HealthMetricType
    let value: Double
    let date: Date
    let previousValue: Double?
    let goalValue: Double?
    
    var formattedValue: String {
        switch type {
        case .steps, .standHours:
            return "\(Int(value))"
        case .activeEnergy, .weight:
            return String(format: "%.1f", value)
        case .heartRate, .restingHeartRate, .respiratoryRate:
            return String(format: "%.0f", value)
        case .sleepHours:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        case .sleepQuality, .oxygenSaturation, .bodyFat:
            return String(format: "%.0f%%", value)
        case .mindfulMinutes, .workouts:
            return "\(Int(value)) min"
        case .waterIntake:
            return "\(Int(value)) ml"
        case .bloodPressure:
            // Blood pressure is stored as systolic/diastolic
            if let previousValue = previousValue {
                return "\(Int(value))/\(Int(previousValue))"
            } else {
                return "\(Int(value))/-"
            }
        case .bmi:
            return String(format: "%.1f", value)
        }
    }
    
    var changePercentage: Double? {
        guard let previousValue = previousValue, previousValue != 0 else { return nil }
        return ((value - previousValue) / previousValue) * 100
    }
    
    var formattedChange: String? {
        guard let change = changePercentage else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        
        return formatter.string(from: NSNumber(value: change / 100))
    }
    
    var isPositiveChange: Bool? {
        guard let change = changePercentage else { return nil }
        
        switch type {
        case .steps, .activeEnergy, .sleepHours, .sleepQuality, .mindfulMinutes, 
             .workouts, .standHours, .waterIntake, .oxygenSaturation:
            // For these metrics, higher is better
            return change > 0
            
        case .heartRate, .restingHeartRate, .respiratoryRate, .bloodPressure:
            // For these metrics, lower is generally better (unless too low)
            return change < 0
            
        case .weight, .bodyFat, .bmi:
            // Context-dependent, but generally lower is better
            return change < 0
        }
    }
    
    var progressToGoal: Double? {
        guard let goal = goalValue, goal > 0 else { return nil }
        
        switch type {
        case .steps, .activeEnergy, .sleepHours, .sleepQuality, .mindfulMinutes,
             .workouts, .standHours, .waterIntake, .oxygenSaturation:
            // For these metrics, we want to reach or exceed the goal
            return min(value / goal, 1.0)
            
        case .weight, .heartRate, .restingHeartRate, .respiratoryRate, 
             .bloodPressure, .bodyFat, .bmi:
            // For these metrics, we want to get to or below the goal
            return goal >= value ? 1.0 : value / goal
        }
    }
}

/// View model for displaying recommendation information
struct RecommendationViewModel: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: GoalCategory
    let priority: Int
    let creationDate: Date
    let status: RecommendationStatus
    let isPremium: Bool
    let actionType: String?
    let confidence: Double?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: creationDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
    
    var priorityText: String {
        switch priority {
        case 3: return "High Priority"
        case 2: return "Medium Priority"
        case 1: return "Low Priority"
        default: return "Normal Priority"
        }
    }
    
    var confidenceText: String? {
        guard let confidence = confidence else { return nil }
        
        let percentage = Int(confidence * 100)
        return "\(percentage)% confidence"
    }
}

/// View model for displaying mood entry information
struct MoodEntryViewModel: Identifiable {
    let id: UUID
    let date: Date
    let moodScore: Int
    let moodState: MoodState
    let factors: [String]?
    let notes: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedFactors: String? {
        guard let factors = factors, !factors.isEmpty else { return nil }
        return factors.joined(separator: ", ")
    }
}

// MARK: - Mock Data Generators

/// Generates mock data for simulator testing
class MockDataGenerator {
    
    /// Generate a random date within the specified range
    static func randomDate(in range: ClosedRange<Date>) -> Date {
        let diff = range.upperBound.timeIntervalSince(range.lowerBound)
        let randomDiff = TimeInterval(arc4random_uniform(UInt32(diff)))
        return range.lowerBound.addingTimeInterval(randomDiff)
    }
    
    /// Generate a random date within the last n days
    static func randomDateWithinLast(days: Int) -> Date {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return randomDate(in: startDate...now)
    }
    
    /// Generate mock goals
    static func generateMockGoals() -> [GoalViewModel] {
        let categories: [GoalCategory] = [.physical, .mental, .sleep, .nutrition, .mindfulness]
        
        return [
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
            ),
            GoalViewModel(
                id: UUID(),
                title: "Water Intake",
                category: .nutrition,
                progress: 0.6,
                currentValue: 1200,
                targetValue: 2000,
                unit: "ml",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                isCompleted: false,
                streak: 0
            ),
            GoalViewModel(
                id: UUID(),
                title: "Journaling",
                category: .mental,
                progress: 0.0,
                currentValue: 0,
                targetValue: 1,
                unit: "entry",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                isCompleted: false,
                streak: 0
            )
        ]
    }
    
    /// Generate mock audio sessions
    static func generateMockAudioSessions() -> [AudioSessionViewModel] {
        return [
            AudioSessionViewModel(
                id: UUID(),
                title: "Morning Meditation",
                subtitle: "Start your day with clarity",
                category: .morning,
                type: .meditation,
                duration: 600, // 10 minutes
                isPremium: false,
                isCompleted: true,
                completionCount: 5,
                audioFileName: "morning_meditation",
                imageFileName: "morning_meditation_img"
            ),
            AudioSessionViewModel(
                id: UUID(),
                title: "Deep Sleep Journey",
                subtitle: "Fall asleep faster and deeper",
                category: .sleep,
                type: .sleepStory,
                duration: 1200, // 20 minutes
                isPremium: true,
                isCompleted: false,
                completionCount: 0,
                audioFileName: "deep_sleep_journey",
                imageFileName: "deep_sleep_journey_img"
            ),
            AudioSessionViewModel(
                id: UUID(),
                title: "Stress Relief",
                subtitle: "Quick breathing exercise",
                category: .stress,
                type: .breathingExercise,
                duration: 300, // 5 minutes
                isPremium: false,
                isCompleted: true,
                completionCount: 2,
                audioFileName: "stress_relief",
                imageFileName: "stress_relief_img"
            ),
            AudioSessionViewModel(
                id: UUID(),
                title: "Positive Affirmations",
                subtitle: "Boost your confidence",
                category: .motivation,
                type: .affirmation,
                duration: 180, // 3 minutes
                isPremium: false,
                isCompleted: false,
                completionCount: 0,
                audioFileName: "positive_affirmations",
                imageFileName: "positive_affirmations_img"
            ),
            AudioSessionViewModel(
                id: UUID(),
                title: "Forest Soundscape",
                subtitle: "Immerse in nature sounds",
                category: .focus,
                type: .soundscape,
                duration: 1800, // 30 minutes
                isPremium: true,
                isCompleted: false,
                completionCount: 0,
                audioFileName: "forest_soundscape",
                imageFileName: "forest_soundscape_img"
            )
        ]
    }
    
    /// Generate mock health metrics
    static func generateMockHealthMetrics() -> [HealthMetricViewModel] {
        return [
            HealthMetricViewModel(
                id: UUID(),
                type: .steps,
                value: 8543,
                date: Date(),
                previousValue: 7832,
                goalValue: 10000
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .heartRate,
                value: 72,
                date: Date(),
                previousValue: 75,
                goalValue: nil
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .sleepHours,
                value: 7.5,
                date: Date(),
                previousValue: 6.8,
                goalValue: 8.0
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .activeEnergy,
                value: 450,
                date: Date(),
                previousValue: 380,
                goalValue: 500
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .mindfulMinutes,
                value: 15,
                date: Date(),
                previousValue: 10,
                goalValue: 20
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .waterIntake,
                value: 1250,
                date: Date(),
                previousValue: 1100,
                goalValue: 2000
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .weight,
                value: 70.5,
                date: Date(),
                previousValue: 71.2,
                goalValue: 68.0
            )
        ]
    }
    
    /// Generate mock recommendations
    static func generateMockRecommendations() -> [RecommendationViewModel] {
        return [
            RecommendationViewModel(
                id: UUID(),
                title: "Take a short walk",
                description: "You've been sitting for 2 hours. A 10-minute walk would help your circulation and energy levels.",
                category: .physical,
                priority: 2,
                creationDate: Date(),
                status: .active,
                isPremium: false,
                actionType: "activity",
                confidence: 0.85
            ),
            RecommendationViewModel(
                id: UUID(),
                title: "Drink water",
                description: "You're 40% below your daily water intake goal. Hydrating now could improve your focus.",
                category: .nutrition,
                priority: 3,
                creationDate: Date(),
                status: .active,
                isPremium: false,
                actionType: "hydration",
                confidence: 0.92
            ),
            RecommendationViewModel(
                id: UUID(),
                title: "Try a sleep meditation",
                description: "Based on your sleep patterns, a guided meditation before bed could help you fall asleep 15 minutes faster.",
                category: .sleep,
                priority: 1,
                creationDate: Date().addingTimeInterval(-3600),
                status: .accepted,
                isPremium: true,
                actionType: "meditation",
                confidence: 0.78
            ),
            RecommendationViewModel(
                id: UUID(),
                title: "Schedule deep work",
                description: "Your productivity peaks between 9-11 AM. Schedule your most important tasks during this window.",
                category: .productivity,
                priority: 2,
                creationDate: Date().addingTimeInterval(-7200),
                status: .declined,
                isPremium: true,
                actionType: "schedule",
                confidence: 0.65
            ),
            RecommendationViewModel(
                id: UUID(),
                title: "Practice gratitude",
                description: "Your mood patterns show a dip in the afternoon. A 2-minute gratitude practice could help.",
                category: .mental,
                priority: 1,
                creationDate: Date().addingTimeInterval(-10800),
                status: .active,
                isPremium: false,
                actionType: "mindfulness",
                confidence: 0.72
            )
        ]
    }
    
    /// Generate mock mood entries
    static func generateMockMoodEntries(for days: Int = 7) -> [MoodEntryViewModel] {
        var entries: [MoodEntryViewModel] = []
        
        let now = Date()
        let calendar = Calendar.current
        
        for day in 0..<days {
            let date = calendar.date(byAdding: .day, value: -day, to: now) ?? now
            
            // Generate 1-3 entries per day
            let entriesPerDay = Int.random(in: 1...3)
            for entry in 0..<entriesPerDay {
                let hour = Int.random(in: 8...20) // Between 8 AM and 8 PM
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = hour
                dateComponents.minute = Int.random(in: 0...59)
                
                let entryDate = calendar.date(from: dateComponents) ?? date
                let moodScore = Int.random(in: 1...5)
                let moodState = MoodState(rawValue: moodScore) ?? .neutral
                
                var factors: [String]? = nil
                if Bool.random() {
                    let allFactors = ["Work", "Family", "Exercise", "Sleep", "Food", "Social", "Weather", "Health"]
                    let factorCount = Int.random(in: 1...3)
                    factors = Array(allFactors.shuffled().prefix(factorCount))
                }
                
                var notes: String? = nil
                if Bool.random() {
                    let allNotes = [
                        "Feeling good after my morning workout.",
                        "Stressed about work deadline.",
                        "Great conversation with a friend.",
                        "Didn't sleep well last night.",
                        "Enjoyed a healthy meal.",
                        "Feeling tired but accomplished."
                    ]
                    notes = allNotes.randomElement()
                }
                
                entries.append(MoodEntryViewModel(
                    id: UUID(),
                    date: entryDate,
                    moodScore: moodScore,
                    moodState: moodState,
                    factors: factors,
                    notes: notes
                ))
            }
        }
        
        // Sort by date, newest first
        return entries.sorted { $0.date > $1.date }
    }
    
    /// Generate mock health data for a specific date
    static func generateMockHealthData(for date: Date) -> [HealthMetricViewModel] {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        
        // Generate steps that increase throughout the day if today
        let stepsGoal = 10000.0
        var stepsValue = 0.0
        
        if isToday {
            let now = Date()
            let secondsInDay = 24 * 60 * 60
            let secondsSinceMidnight = Int(now.timeIntervalSince(calendar.startOfDay(for: now)))
            let dayProgress = Double(secondsSinceMidnight) / Double(secondsInDay)
            
            // Steps follow a curve: slow morning, peak midday, slower evening
            if dayProgress < 0.3 {
                // Morning: slow start
                stepsValue = stepsGoal * dayProgress * 0.5
            } else if dayProgress < 0.7 {
                // Midday: faster accumulation
                stepsValue = stepsGoal * (0.15 + (dayProgress - 0.3) * 1.2)
            } else {
                // Evening: slower accumulation
                stepsValue = stepsGoal * (0.63 + (dayProgress - 0.7) * 0.5)
            }
            
            // Add some randomness
            stepsValue *= Double.random(in: 0.9...1.1)
            stepsValue = min(stepsValue, stepsGoal * 1.2) // Cap at 120% of goal
        } else {
            // Past day: generate a random completion between 60-120% of goal
            stepsValue = stepsGoal * Double.random(in: 0.6...1.2)
        }
        
        // Round to nearest integer
        stepsValue = round(stepsValue)
        
        // Generate other metrics
        let heartRateValue = Double.random(in: 65...80)
        let sleepHoursValue = Double.random(in: 6.5...8.5)
        let activeEnergyValue = Double.random(in: 350...550)
        let mindfulMinutesValue = Double.random(in: 5...20)
        let waterIntakeValue = Double.random(in: 1000...2000)
        
        // Previous day values (slightly different)
        let previousStepsValue = stepsValue * Double.random(in: 0.9...1.1)
        let previousHeartRateValue = heartRateValue * Double.random(in: 0.95...1.05)
        let previousSleepHoursValue = sleepHoursValue * Double.random(in: 0.9...1.1)
        let previousActiveEnergyValue = activeEnergyValue * Double.random(in: 0.9...1.1)
        let previousMindfulMinutesValue = mindfulMinutesValue * Double.random(in: 0.8...1.2)
        let previousWaterIntakeValue = waterIntakeValue * Double.random(in: 0.9...1.1)
        
        return [
            HealthMetricViewModel(
                id: UUID(),
                type: .steps,
                value: stepsValue,
                date: date,
                previousValue: previousStepsValue,
                goalValue: stepsGoal
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .heartRate,
                value: heartRateValue,
                date: date,
                previousValue: previousHeartRateValue,
                goalValue: nil
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .sleepHours,
                value: sleepHoursValue,
                date: date,
                previousValue: previousSleepHoursValue,
                goalValue: 8.0
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .activeEnergy,
                value: activeEnergyValue,
                date: date,
                previousValue: previousActiveEnergyValue,
                goalValue: 500
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .mindfulMinutes,
                value: mindfulMinutesValue,
                date: date,
                previousValue: previousMindfulMinutesValue,
                goalValue: 15
            ),
            HealthMetricViewModel(
                id: UUID(),
                type: .waterIntake,
                value: waterIntakeValue,
                date: date,
                previousValue: previousWaterIntakeValue,
                goalValue: 2000
            )
        ]
    }
    
    /// Generate a week of mock health data
    static func generateWeekOfHealthData() -> [Date: [HealthMetricViewModel]] {
        var weekData: [Date: [HealthMetricViewModel]] = [:]
        let calendar = Calendar.current
        let today = Date()
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                weekData[date] = generateMockHealthData(for: date)
            }
        }
        
        return weekData
    }
}
