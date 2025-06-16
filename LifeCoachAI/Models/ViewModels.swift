//
//  ViewModels.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import SwiftUI
import Combine

// MARK: - Enums for ViewModels

/// Recommendation priority levels
enum RecommendationPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        }
    }
}

/// Recommendation action types
enum RecommendationActionType: String, CaseIterable {
    case exercise = "exercise"
    case meditation = "meditation"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case hydration = "hydration"
    case mindfulness = "mindfulness"
    case goal = "goal"
    case habit = "habit"
    
    var displayName: String {
        switch self {
        case .exercise: return "Exercise"
        case .meditation: return "Meditation"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .hydration: return "Hydration"
        case .mindfulness: return "Mindfulness"
        case .goal: return "Goal Setting"
        case .habit: return "Habit Building"
        }
    }
    
    var icon: String {
        switch self {
        case .exercise: return "figure.run"
        case .meditation: return "leaf.fill"
        case .nutrition: return "fork.knife"
        case .sleep: return "bed.double.fill"
        case .hydration: return "drop.fill"
        case .mindfulness: return "brain.head.profile"
        case .goal: return "target"
        case .habit: return "repeat"
        }
    }
}

/// Audio session type
enum AudioSessionType: String, CaseIterable {
    case meditation = "meditation"
    case sleep = "sleep"
    case focus = "focus"
    case stress = "stress"
    case coaching = "coaching"
    case motivation = "motivation"

    var displayName: String {
        switch self {
        case .meditation: return "Meditation"
        case .sleep: return "Sleep"
        case .focus: return "Focus"
        case .stress: return "Stress Relief"
        case .coaching: return "Coaching"
        case .motivation: return "Motivation"
        }
    }
}

// MARK: - ViewModel Types

/// Goal view model for UI presentation
struct GoalViewModel: Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let category: GoalCategory
    let targetValue: Double
    let currentValue: Double
    let unit: String?
    let frequency: GoalFrequency
    let dueDate: Date?
    let isCompleted: Bool
    let progress: Double
    let createdDate: Date
    let lastUpdated: Date

    var progressPercentage: Int {
        return Int(progress * 100)
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
}

/// Health metric view model for UI presentation
struct HealthMetricViewModel: Identifiable {
    let id: UUID
    let type: HealthMetricType
    let value: Double
    let unit: String
    let date: Date
    let trend: TrendDirection?
    let weeklyAverage: Double?
    let monthlyAverage: Double?

    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = type == .heartRate ? 0 : 1

        guard let formatted = formatter.string(from: NSNumber(value: value)) else {
            return "\(value)"
        }

        return "\(formatted) \(unit)"
    }
}

/// Audio session view model for UI presentation
struct AudioSessionViewModel: Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let category: AudioCategory
    let type: AudioSessionType
    let duration: TimeInterval
    let audioURL: URL?
    let imageURL: URL?
    let isPremium: Bool
    let isDownloaded: Bool
    let playCount: Int
    let lastPlayed: Date?
    let createdDate: Date

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var isRecent: Bool {
        guard let lastPlayed = lastPlayed else { return false }
        return Calendar.current.isDate(lastPlayed, inSameDayAs: Date())
    }
}

/// Recommendation view model for UI presentation
struct RecommendationViewModel: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: GoalCategory
    let priority: RecommendationPriority
    let actionType: RecommendationActionType
    let targetValue: Double?
    let unit: String?
    let estimatedDuration: TimeInterval?
    let relatedGoalId: UUID?
    let relatedMetrics: [HealthMetricType]
    let createdDate: Date
    let expiryDate: Date?
    let isCompleted: Bool
    let completedDate: Date?

    var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate < Date()
    }

    var formattedDuration: String? {
        guard let duration = estimatedDuration else { return nil }
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
