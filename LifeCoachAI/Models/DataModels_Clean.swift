//
//  DataModels.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import SwiftUI
import Combine

// MARK: - Enums and Supporting Types

/// Gender enumeration
enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

/// Goal category enumeration
enum GoalCategory: String, CaseIterable, Codable {
    case fitness = "fitness"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case sleep = "sleep"
    case stress = "stress"
    case weight = "weight"
    case habit = "habit"
    case health = "health"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .sleep: return "Sleep"
        case .stress: return "Stress Management"
        case .weight: return "Weight Management"
        case .habit: return "Habit Building"
        case .health: return "Health"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .fitness: return "figure.run"
        case .nutrition: return "leaf.fill"
        case .mindfulness: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .stress: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .habit: return "checkmark.circle.fill"
        case .health: return "heart.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .fitness: return .blue
        case .nutrition: return .green
        case .mindfulness: return .purple
        case .sleep: return .indigo
        case .stress: return .orange
        case .weight: return .red
        case .habit: return .teal
        case .health: return .pink
        case .other: return .gray
        }
    }
}

/// Goal frequency enumeration
enum GoalFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

/// Goal status enumeration
enum GoalStatus: String, CaseIterable, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .paused: return .orange
        case .cancelled: return .red
        }
    }
}

/// Health metric type enumeration
enum HealthMetricType: String, CaseIterable, Codable {
    case weight = "weight"
    case height = "height"
    case heartRate = "heart_rate"
    case bloodPressure = "blood_pressure"
    case steps = "steps"
    case activeEnergy = "active_energy"
    case sleepHours = "sleep_hours"
    case mindfulMinutes = "mindful_minutes"
    case standHours = "stand_hours"
    case workouts = "workouts"
    case water = "water"
    case mood = "mood"
    case stress = "stress"
    case energy = "energy"
    
    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .height: return "Height"
        case .heartRate: return "Heart Rate"
        case .bloodPressure: return "Blood Pressure"
        case .steps: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .sleepHours: return "Sleep Hours"
        case .mindfulMinutes: return "Mindful Minutes"
        case .standHours: return "Stand Hours"
        case .workouts: return "Workouts"
        case .water: return "Water Intake"
        case .mood: return "Mood"
        case .stress: return "Stress Level"
        case .energy: return "Energy Level"
        }
    }
    
    var unit: String {
        switch self {
        case .weight: return "kg"
        case .height: return "cm"
        case .heartRate: return "bpm"
        case .bloodPressure: return "mmHg"
        case .steps: return "steps"
        case .activeEnergy: return "cal"
        case .sleepHours: return "hours"
        case .mindfulMinutes: return "min"
        case .standHours: return "hours"
        case .workouts: return "count"
        case .water: return "L"
        case .mood: return "/10"
        case .stress: return "/10"
        case .energy: return "/10"
        }
    }
    
    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .height: return "ruler.fill"
        case .heartRate: return "heart.fill"
        case .bloodPressure: return "drop.fill"
        case .steps: return "figure.walk"
        case .activeEnergy: return "flame.fill"
        case .sleepHours: return "bed.double.fill"
        case .mindfulMinutes: return "brain.head.profile"
        case .standHours: return "figure.stand"
        case .workouts: return "figure.run"
        case .water: return "drop.fill"
        case .mood: return "face.smiling.fill"
        case .stress: return "exclamationmark.triangle.fill"
        case .energy: return "bolt.fill"
        }
    }
}

/// Audio session category enumeration
enum AudioCategory: String, CaseIterable, Codable {
    case meditation = "meditation"
    case sleep = "sleep"
    case focus = "focus"
    case relaxation = "relaxation"
    case motivation = "motivation"
    case breathing = "breathing"
    case mindfulness = "mindfulness"
    case coaching = "coaching"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .meditation: return "Meditation"
        case .sleep: return "Sleep"
        case .focus: return "Focus"
        case .relaxation: return "Relaxation"
        case .motivation: return "Motivation"
        case .breathing: return "Breathing"
        case .mindfulness: return "Mindfulness"
        case .coaching: return "Coaching"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .meditation: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .focus: return "target"
        case .relaxation: return "leaf.fill"
        case .motivation: return "flame.fill"
        case .breathing: return "lungs.fill"
        case .mindfulness: return "heart.fill"
        case .coaching: return "person.fill"
        case .other: return "music.note"
        }
    }
}

/// Recommendation category enumeration
enum RecommendationCategory: String, CaseIterable, Codable {
    case exercise = "exercise"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case mindfulness = "mindfulness"
    case habit = "habit"
    case health = "health"
    case motivation = "motivation"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .exercise: return "Exercise"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .mindfulness: return "Mindfulness"
        case .habit: return "Habits"
        case .health: return "Health"
        case .motivation: return "Motivation"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .exercise: return "figure.run"
        case .nutrition: return "leaf.fill"
        case .sleep: return "bed.double.fill"
        case .mindfulness: return "brain.head.profile"
        case .habit: return "checkmark.circle.fill"
        case .health: return "heart.fill"
        case .motivation: return "flame.fill"
        case .other: return "lightbulb.fill"
        }
    }
}

/// Achievement category enumeration
enum AchievementCategory: String, CaseIterable, Codable {
    case streak = "streak"
    case milestone = "milestone"
    case goal = "goal"
    case consistency = "consistency"
    case improvement = "improvement"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .streak: return "Streak"
        case .milestone: return "Milestone"
        case .goal: return "Goal Achievement"
        case .consistency: return "Consistency"
        case .improvement: return "Improvement"
        case .special: return "Special"
        }
    }
}

/// Subscription status enumeration
enum SubscriptionStatus: String, CaseIterable, Codable {
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    case trial = "trial"
    case pending = "pending"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        case .trial: return "Trial"
        case .pending: return "Pending"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .expired: return .red
        case .cancelled: return .gray
        case .trial: return .blue
        case .pending: return .orange
        }
    }
}

/// Insight category enumeration
enum InsightCategory: String, CaseIterable, Codable {
    case trend = "trend"
    case correlation = "correlation"
    case achievement = "achievement"
    case recommendation = "recommendation"
    case warning = "warning"
    case celebration = "celebration"

    var displayName: String {
        switch self {
        case .trend: return "Trend Analysis"
        case .correlation: return "Correlation"
        case .achievement: return "Achievement"
        case .recommendation: return "Recommendation"
        case .warning: return "Warning"
        case .celebration: return "Celebration"
        }
    }

    var icon: String {
        switch self {
        case .trend: return "chart.line.uptrend.xyaxis"
        case .correlation: return "link"
        case .achievement: return "trophy.fill"
        case .recommendation: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .celebration: return "party.popper.fill"
        }
    }
}

/// Correlation type enumeration
enum CorrelationType: String, CaseIterable, Codable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"

    var displayName: String {
        switch self {
        case .positive: return "Positive Correlation"
        case .negative: return "Negative Correlation"
        case .neutral: return "No Correlation"
        }
    }

    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - Non-Core Data Models

/// Health metric summary
struct HealthMetricSummary: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let total: Double
    let average: Double
    let max: Double
    let min: Double
    let count: Int
    let period: String
}

/// Insight model
struct Insight: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let details: String?
    let category: InsightCategory
    let priority: Double
    let createdDate: Date
    let metricValues: [HealthMetricType: Double]
    let recommendations: [String]?
}

/// Correlation insight model
struct CorrelationInsight: Identifiable {
    let id = UUID()
    let metricOne: HealthMetricType
    let metricTwo: HealthMetricType
    let correlationType: CorrelationType
    let strength: Double // 0.0 to 1.0
    let description: String
    let period: String
    let dataPoints: Int
}

/// Progress summary model
struct ProgressSummary: Identifiable {
    let id = UUID()
    let goalId: UUID
    let currentValue: Double
    let targetValue: Double
    let progressPercentage: Double
    let trend: String // "improving", "declining", "stable"
    let lastUpdated: Date
}

/// Weekly summary model
struct WeeklySummary: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let completedGoals: Int
    let totalGoals: Int
    let averageMood: Double
    let totalSteps: Int
    let totalExerciseMinutes: Int
    let averageSleep: Double
    let achievements: [UUID] // Achievement IDs
}

/// Monthly summary model
struct MonthlySummary: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let completedGoals: Int
    let totalGoals: Int
    let averageMood: Double
    let totalSteps: Int
    let totalExerciseMinutes: Int
    let averageSleep: Double
    let achievements: [UUID] // Achievement IDs
    let insights: [Insight]
}

/// Notification settings model
struct NotificationSettings: Codable {
    var dailyReminders: Bool = true
    var goalReminders: Bool = true
    var achievementNotifications: Bool = true
    var weeklyReports: Bool = true
    var motivationalMessages: Bool = true
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true
}

/// App settings model
struct AppSettings: Codable {
    var theme: String = "system"
    var language: String = "en"
    var units: String = "metric" // "metric" or "imperial"
    var privacyMode: Bool = false
    var dataExportEnabled: Bool = true
    var analyticsEnabled: Bool = true
    var crashReportingEnabled: Bool = true
    var notifications: NotificationSettings = NotificationSettings()
}

/// Export data model
struct ExportData: Codable {
    let exportDate: Date
    let userProfile: [String: Any]
    let goals: [[String: Any]]
    let healthMetrics: [[String: Any]]
    let moodEntries: [[String: Any]]
    let achievements: [[String: Any]]
    let audioSessions: [[String: Any]]
    let recommendations: [[String: Any]]

    enum CodingKeys: String, CodingKey {
        case exportDate, userProfile, goals, healthMetrics, moodEntries, achievements, audioSessions, recommendations
    }
}

/// Chart data point model
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String?
    let color: Color?
}

/// Chart data series model
struct ChartDataSeries: Identifiable {
    let id = UUID()
    let name: String
    let dataPoints: [ChartDataPoint]
    let color: Color
    let type: String // "line", "bar", "area"
}

/// Dashboard widget model
struct DashboardWidget: Identifiable {
    let id = UUID()
    let type: String // "goal_progress", "mood_chart", "steps", "achievements"
    let title: String
    let data: [String: Any]
    let position: Int
    let isVisible: Bool
    let size: String // "small", "medium", "large"
}
