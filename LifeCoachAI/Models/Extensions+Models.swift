// Extensions+Models.swift
import SwiftUI
import CoreData

// MARK: - Goal Core Data Convenience Properties
extension Goal {
    /// Progress as a percentage (0-100).
    var progress: Double {
        get { targetValue > 0 ? (currentProgress / targetValue) * 100.0 : 0 }
        set { currentProgress = (newValue / 100.0) * targetValue }
    }
    /// Goal's category as GoalCategory enum.
    var categoryEnum: GoalCategory { GoalCategory(rawValue: category ?? "other") ?? .other }
    /// Category icon string.
    var categoryIcon: String { categoryEnum.icon }
    /// Category color as SwiftUI Color.
    var categoryColor: Color { categoryEnum.color }
    /// Category display name string.
    var categoryName: String { categoryEnum.displayName }
}

// MARK: - Recommendation Core Data Placeholder
extension Recommendation {
    /// Unified content property fallback for missing data.
    var content: String {
        desc ?? summary ?? title ?? ""
    }
}

// MARK: - GoalViewModel Convenience
extension GoalViewModel {
    /// Default streak (override via UserProfileManager if needed).
    var streak: Int { 0 }
    /// Completion status.
    var isCompleted: Bool { isCompleted }
    /// Formatted target value with unit.
    var formattedTarget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let val = formatter.string(from: NSNumber(value: targetValue)) ?? "\(targetValue)"
        return "\(val) \(unit ?? "")"
    }
}

// MARK: - RecommendationViewModel Convenience
extension RecommendationViewModel {
    /// Premium access flag.
    var isPremium: Bool { false }
    /// Formatted time string from createdDate.
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    /// Confidence as optional text (not implemented).
    var confidenceText: String? { nil }
}

// MARK: - AudioSessionViewModel Convenience
extension AudioSessionViewModel {
    /// Subtitle property for AudioSessionCard.
    var subtitle: String? { description }
}