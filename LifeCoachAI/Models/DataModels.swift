//
//  DataModels.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import SwiftUI
import Combine

// MARK: - User Profile

class UserProfile: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var name: String?
    @Published var birthDate: Date?
    @Published var gender: String?
    @Published var height: Double
    @Published var weight: Double
    @Published var createdDate: Date
    @Published var isOnboarded: Bool
    
    // Relationships
    @Published var goals: [Goal] = []
    @Published var healthMetrics: [HealthMetric] = []
    @Published var moodEntries: [MoodEntry] = []
    @Published var recommendations: [Recommendation] = []
    @Published var achievements: [Achievement] = []
    @Published var subscription: Subscription?
    
    enum CodingKeys: String, CodingKey {
        case id, name, birthDate, gender, height, weight, createdDate, isOnboarded
    }
    
    init(id: UUID = UUID(), 
         name: String? = nil, 
         birthDate: Date? = nil, 
         gender: String? = nil, 
         height: Double = 170.0, 
         weight: Double = 70.0, 
         createdDate: Date = Date(), 
         isOnboarded: Bool = false) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.height = height
        self.weight = weight
        self.createdDate = createdDate
        self.isOnboarded = isOnboarded
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        height = try container.decode(Double.self, forKey: .height)
        weight = try container.decode(Double.self, forKey: .weight)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        isOnboarded = try container.decode(Bool.self, forKey: .isOnboarded)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encode(height, forKey: .height)
        try container.encode(weight, forKey: .weight)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(isOnboarded, forKey: .isOnboarded)
    }
    
    // Computed properties
    var initials: String {
        guard let name = self.name, !name.isEmpty else { return "?" }
        
        let components = name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return String(first) + String(last)
        } else if let first = components.first?.first {
            return String(first)
        } else {
            return "?"
        }
    }
    
    var formattedAge: String {
        guard let birthDate = self.birthDate else { return "Not set" }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        if let age = ageComponents.year {
            return "\(age) years"
        } else {
            return "Unknown"
        }
    }
    
    var formattedGender: String {
        guard let gender = self.gender, !gender.isEmpty else { return "Not specified" }
        return Gender(rawValue: gender)?.displayName ?? "Not specified"
    }
}

// MARK: - Goal

class Goal: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var title: String?
    @Published var description: String?
    @Published var category: String?
    @Published var targetValue: Double
    @Published var unit: String?
    @Published var dueDate: Date?
    @Published var frequency: String?
    @Published var priority: Double
    @Published var progress: Double
    @Published var createdDate: Date?
    @Published var completionDate: Date?
    @Published var isCompleted: Bool
    @Published var hasReminder: Bool
    @Published var reminderTime: Date?
    
    // Relationships
    @Published var recommendedSessions: [AudioSession] = []
    weak var userProfile: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, targetValue, unit, dueDate, frequency
        case priority, progress, createdDate, completionDate, isCompleted, hasReminder, reminderTime
    }
    
    init(id: UUID = UUID(),
         title: String? = nil,
         description: String? = nil,
         category: String? = nil,
         targetValue: Double = 0.0,
         unit: String? = nil,
         dueDate: Date? = nil,
         frequency: String? = "daily",
         priority: Double = 1.0,
         progress: Double = 0.0,
         createdDate: Date? = Date(),
         completionDate: Date? = nil,
         isCompleted: Bool = false,
         hasReminder: Bool = false,
         reminderTime: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.targetValue = targetValue
        self.unit = unit
        self.dueDate = dueDate
        self.frequency = frequency
        self.priority = priority
        self.progress = progress
        self.createdDate = createdDate
        self.completionDate = completionDate
        self.isCompleted = isCompleted
        self.hasReminder = hasReminder
        self.reminderTime = reminderTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        targetValue = try container.decode(Double.self, forKey: .targetValue)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        frequency = try container.decodeIfPresent(String.self, forKey: .frequency)
        priority = try container.decode(Double.self, forKey: .priority)
        progress = try container.decode(Double.self, forKey: .progress)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
        completionDate = try container.decodeIfPresent(Date.self, forKey: .completionDate)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        hasReminder = try container.decode(Bool.self, forKey: .hasReminder)
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(targetValue, forKey: .targetValue)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(frequency, forKey: .frequency)
        try container.encode(priority, forKey: .priority)
        try container.encode(progress, forKey: .progress)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(completionDate, forKey: .completionDate)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(hasReminder, forKey: .hasReminder)
        try container.encodeIfPresent(reminderTime, forKey: .reminderTime)
    }
    
    // Computed properties
    var categoryName: String {
        let category = GoalCategory(rawValue: self.category ?? "health") ?? .health
        return category.displayName
    }
    
    var categoryIcon: String {
        let category = GoalCategory(rawValue: self.category ?? "health") ?? .health
        return category.icon
    }
    
    var categoryColor: Color {
        let category = GoalCategory(rawValue: self.category ?? "health") ?? .health
        return category.color
    }
    
    var frequencyName: String {
        let frequency = GoalFrequency(rawValue: self.frequency ?? "daily") ?? .daily
        return frequency.displayName
    }
    
    func isRelatedToHealthMetric(_ metricType: HealthMetricType) -> Bool {
        guard let category = self.category else { return false }
        
        switch metricType {
        case .steps:
            return category == "fitness" || category == "health"
        case .activeEnergy:
            return category == "fitness" || category == "health"
        case .heartRate:
            return category == "health" || category == "cardio"
        case .sleepHours:
            return category == "sleep" || category == "health"
        case .weight:
            return category == "health" || category == "nutrition"
        case .mindfulMinutes:
            return category == "mindfulness"
        case .standHours:
            return category == "fitness" || category == "health"
        case .workouts:
            return category == "fitness" || category == "health"
        }
    }
}

// MARK: - Health Metric

class HealthMetric: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var type: String?
    @Published var value: Double
    @Published var date: Date?
    
    // Relationships
    weak var userProfile: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id, type, value, date
    }
    
    init(id: UUID = UUID(), type: String? = nil, value: Double = 0.0, date: Date? = Date()) {
        self.id = id
        self.type = type
        self.value = value
        self.date = date
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        value = try container.decode(Double.self, forKey: .value)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(date, forKey: .date)
    }
}

// MARK: - Audio Session

class AudioSession: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var title: String?
    @Published var description: String?
    @Published var category: String
    @Published var audioFileName: String
    @Published var imageName: String?
    @Published var duration: Double
    @Published var isPremium: Bool
    @Published var isFeatured: Bool
    @Published var createdDate: Date?
    @Published var lastPlayedDate: Date?
    
    // Relationships
    @Published var goals: [Goal] = []
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, audioFileName, imageName, duration
        case isPremium, isFeatured, createdDate, lastPlayedDate
    }
    
    init(id: UUID = UUID(),
         title: String? = nil,
         description: String? = nil,
         category: String = "meditation",
         audioFileName: String = "",
         imageName: String? = nil,
         duration: Double = 0.0,
         isPremium: Bool = false,
         isFeatured: Bool = false,
         createdDate: Date? = Date(),
         lastPlayedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.audioFileName = audioFileName
        self.imageName = imageName
        self.duration = duration
        self.isPremium = isPremium
        self.isFeatured = isFeatured
        self.createdDate = createdDate
        self.lastPlayedDate = lastPlayedDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        audioFileName = try container.decode(String.self, forKey: .audioFileName)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        duration = try container.decode(Double.self, forKey: .duration)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
        lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(audioFileName, forKey: .audioFileName)
        try container.encodeIfPresent(imageName, forKey: .imageName)
        try container.encode(duration, forKey: .duration)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(lastPlayedDate, forKey: .lastPlayedDate)
    }
    
    // Computed properties
    var categoryName: String {
        switch category {
        case "meditation": return "Meditation"
        case "sleep": return "Sleep"
        case "focus": return "Focus"
        case "stress": return "Stress Relief"
        case "coaching": return "Coaching"
        case "motivation": return "Motivation"
        default: return "Other"
        }
    }
}

// MARK: - Mood Entry

class MoodEntry: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var moodScore: Int16
    @Published var notes: String?
    @Published var date: Date?
    
    // Relationships
    weak var userProfile: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id, moodScore, notes, date
    }
    
    init(id: UUID = UUID(), moodScore: Int16 = 0, notes: String? = nil, date: Date? = Date()) {
        self.id = id
        self.moodScore = moodScore
        self.notes = notes
        self.date = date
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        moodScore = try container.decode(Int16.self, forKey: .moodScore)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(moodScore, forKey: .moodScore)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(date, forKey: .date)
    }
}

// MARK: - Recommendation

class Recommendation: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var title: String?
    @Published var content: String?
    @Published var category: String?
    @Published var priority: Double
    @Published var isPremium: Bool
    @Published var createdDate: Date?
    
    // Relationships
    weak var userProfile: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, category, priority, isPremium, createdDate
    }
    
    init(id: UUID = UUID(),
         title: String? = nil,
         content: String? = nil,
         category: String? = nil,
         priority: Double = 0.0,
         isPremium: Bool = false,
         createdDate: Date? = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.priority = priority
        self.isPremium = isPremium
        self.createdDate = createdDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        priority = try container.decode(Double.self, forKey: .priority)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(priority, forKey: .priority)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
    }
}

// MARK: - Achievement

class Achievement: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var title: String
    @Published var desc: String?
    @Published var category: String
    @Published var badgeImageName: String?
    @Published var level: Int16
    @Published var isDisplayed: Bool
    @Published var achievedDate: Date?
    
    // Relationships
    weak var userProfile: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id, title, desc, category, badgeImageName, level, isDisplayed, achievedDate
    }
    
    init(id: UUID = UUID(),
         title: String = "",
         desc: String? = nil,
         category: String = "",
         badgeImageName: String? = nil,
         level: Int16 = 1,
         isDisplayed: Bool = false,
         achievedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.desc = desc
        self.category = category
        self.badgeImageName = badgeImageName
        self.level = level
        self.isDisplayed = isDisplayed
        self.achievedDate = achievedDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        category = try container.decode(String.self, forKey: .category)
        badgeImageName = try container.decodeIfPresent(String.self, forKey: .badgeImageName)
        level = try container.decode(Int16.self, forKey: .level)
        isDisplayed = try container.decode(Bool.self, forKey: .isDisplayed)
        achievedDate = try container.decodeIfPresent(Date.self, forKey: .achievedDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(desc, forKey: .desc)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(badgeImageName, forKey: .badgeImageName)
        try container.encode(level, forKey: .level)
        try container.encode(isDisplayed, forKey: .isDisplayed)
        try container.encodeIfPresent(achievedDate, forKey: .achievedDate)
    }
}

// MARK: - Streak

class Streak: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var currentStreak: Int32
    @Published var lastCompletedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, currentStreak, lastCompletedDate
    }
    
    init(id: UUID = UUID(), currentStreak: Int32 = 0, lastCompletedDate: Date? = nil) {
        self.id = id
        self.currentStreak = currentStreak
        self.lastCompletedDate = lastCompletedDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        currentStreak = try container.decode(Int32.self, forKey: .currentStreak)
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encodeIfPresent(lastCompletedDate, forKey: .lastCompletedDate)
    }
}

// MARK: - Session Completion

class SessionCompletion: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var completionDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, completionDate
    }
    
    init(id: UUID = UUID(), completionDate: Date? = Date()) {
        self.id = id
        self.completionDate = completionDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        completionDate = try container.decodeIfPresent(Date.self, forKey: .completionDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(completionDate, forKey: .completionDate)
    }
}

// MARK: - Subscription

class Subscription: ObservableObject, Identifiable, Codable {
    @Published var id: UUID
    @Published var productId: String?
    @Published var purchaseDate: Date?
    @Published var expirationDate: Date?
    @Published var isActive: Bool
    
    // Relationships
    weak var userProfile: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id, productId, purchaseDate, expirationDate, isActive
    }
    
    init(id: UUID = UUID(),
         productId: String? = nil,
         purchaseDate: Date? = nil,
         expirationDate: Date? = nil,
         isActive: Bool = false) {
        self.id = id
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(productId, forKey: .productId)
        try container.encodeIfPresent(purchaseDate, forKey: .purchaseDate)
        try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try container.encode(isActive, forKey: .isActive)
    }
}

// MARK: - Supporting Types

/// Gender options
enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"
    case nonBinary = "nonBinary"
    case notSpecified = "notSpecified"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .notSpecified: return "Prefer not to say"
        }
    }
}

/// Goal categories
enum GoalCategory: String, CaseIterable {
    case all = "all"
    case health = "health"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case sleep = "sleep"
    case work = "work"
    case learning = "learning"
    case personal = "personal"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .health: return "Health"
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .sleep: return "Sleep"
        case .work: return "Work"
        case .learning: return "Learning"
        case .personal: return "Personal"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .health: return "heart"
        case .fitness: return "figure.walk"
        case .nutrition: return "fork.knife"
        case .mindfulness: return "brain.head.profile"
        case .sleep: return "bed.double"
        case .work: return "briefcase"
        case .learning: return "book"
        case .personal: return "person"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return Color("AccentColor")
        case .health: return .red
        case .fitness: return .orange
        case .nutrition: return .green
        case .mindfulness: return .blue
        case .sleep: return .purple
        case .work: return .gray
        case .learning: return .yellow
        case .personal: return .pink
        }
    }
}

/// Goal frequency
enum GoalFrequency: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case once = "once"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .once: return "One-time"
        }
    }
}

/// Sort options for goals
enum GoalSortOption: String, CaseIterable {
    case priority = "priority"
    case dueDate = "dueDate"
    case progress = "progress"
    case alphabetical = "alphabetical"
    case creationDate = "creationDate"
    
    var displayName: String {
        switch self {
        case .priority: return "Priority"
        case .dueDate: return "Due Date"
        case .progress: return "Progress"
        case .alphabetical: return "A-Z"
        case .creationDate: return "Recently Created"
        }
    }
}

/// Health metric type
enum HealthMetricType: String, CaseIterable {
    case steps = "steps"
    case activeEnergy = "activeEnergy"
    case heartRate = "heartRate"
    case sleepHours = "sleepHours"
    case weight = "weight"
    case mindfulMinutes = "mindfulMinutes"
    case standHours = "standHours"
    case workouts = "workouts"
    
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .heartRate: return "Heart Rate"
        case .sleepHours: return "Sleep"
        case .weight: return "Weight"
        case .mindfulMinutes: return "Mindfulness"
        case .standHours: return "Stand Hours"
        case .workouts: return "Workouts"
        }
    }
}

/// Audio categories
enum AudioCategory: String, CaseIterable {
    case all = "all"
    case meditation = "meditation"
    case sleep = "sleep"
    case focus = "focus"
    case stress = "stress"
    case coaching = "coaching"
    case motivation = "motivation"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .meditation: return "Meditation"
        case .sleep: return "Sleep"
        case .focus: return "Focus"
        case .stress: return "Stress Relief"
        case .coaching: return "Coaching"
        case .motivation: return "Motivation"
        }
    }
}

/// Sort options for audio sessions
enum SortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case duration = "duration"
    case alphabetical = "alphabetical"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .duration: return "Duration"
        case .alphabetical: return "A-Z"
        }
    }
}

/// Subscription tier
enum SubscriptionTier {
    case free
    case premium
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Access to basic audio content",
                "Goal tracking",
                "Basic health insights"
            ]
        case .premium:
            return [
                "Unlimited access to all audio content",
                "Advanced health insights and recommendations",
                "Personalized coaching",
                "Premium goal tracking features",
                "Ad-free experience"
            ]
        }
    }
}

/// Health metric summary
struct HealthMetricSummary: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let total: Double
    let average: Double
    let max: Double
}

/// Insight model
struct Insight: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let details: String?
    let category: InsightCategory
    let date: Date
    let relatedMetrics: [HealthMetricType]
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
}

/// Streak information
struct StreakInfo {
    let currentStreak: Int
    let bestStreak: Int
    let lastCompletedDate: Date?
}

/// Insight category
enum InsightCategory: String, CaseIterable {
    case all = "all"
    case activity = "activity"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case cardio = "cardio"
    case weight = "weight"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .cardio: return "Cardiovascular"
        case .weight: return "Weight"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .activity: return "figure.walk"
        case .sleep: return "bed.double"
        case .nutrition: return "fork.knife"
        case .mindfulness: return "brain.head.profile"
        case .cardio: return "heart"
        case .weight: return "scalemass"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return Color("AccentColor")
        case .activity: return .orange
        case .sleep: return .purple
        case .nutrition: return .green
        case .mindfulness: return .blue
        case .cardio: return .red
        case .weight: return .gray
        }
    }
}

/// Correlation type
enum CorrelationType {
    case positive
    case negative
    case mixed
    
    var icon: String {
        switch self {
        case .positive: return "arrow.up.forward"
        case .negative: return "arrow.down.forward"
        case .mixed: return "arrow.up.arrow.down"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .mixed: return .orange
        }
    }
}

/// Timeframe options for data display
enum TimeframeOption: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    
    var strideBy: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch self {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d MMM"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
}

/// Trend direction
enum TrendDirection {
    case up
    case down
    case stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .up: return "Increasing"
        case .down: return "Decreasing"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Data Storage Helper

class DataStore {
    static let shared = DataStore()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Keys for UserDefaults
    private let userProfileKey = "userProfile"
    private let goalsKey = "goals"
    private let healthMetricsKey = "healthMetrics"
    private let audioSessionsKey = "audioSessions"
    private let moodEntriesKey = "moodEntries"
    private let recommendationsKey = "recommendations"
    private let achievementsKey = "achievements"
    private let streaksKey = "streaks"
    private let sessionCompletionsKey = "sessionCompletions"
    private let subscriptionKey = "subscription"
    
    private init() {}
    
    // MARK: - Save Methods
    
    func saveUserProfile(_ userProfile: UserProfile) {
        do {
            let data = try encoder.encode(userProfile)
            userDefaults.set(data, forKey: userProfileKey)
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
    
    func saveGoals(_ goals: [Goal]) {
        do {
            let data = try encoder.encode(goals)
            userDefaults.set(data, forKey: goalsKey)
        } catch {
            print("Error saving goals: \(error)")
        }
    }
    
    func saveHealthMetrics(_ metrics: [HealthMetric]) {
        do {
            let data = try encoder.encode(metrics)
            userDefaults.set(data, forKey: healthMetricsKey)
        } catch {
            print("Error saving health metrics: \(error)")
        }
    }
    
    func saveAudioSessions(_ sessions: [AudioSession]) {
        do {
            let data = try encoder.encode(sessions)
            userDefaults.set(data, forKey: audioSessionsKey)
        } catch {
            print("Error saving audio sessions: \(error)")
        }
    }
    
    func saveMoodEntries(_ entries: [MoodEntry]) {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: moodEntriesKey)
        } catch {
            print("Error saving mood entries: \(error)")
        }
    }
    
    func saveRecommendations(_ recommendations: [Recommendation]) {
        do {
            let data = try encoder.encode(recommendations)
            userDefaults.set(data, forKey: recommendationsKey)
        } catch {
            print("Error saving recommendations: \(error)")
        }
    }
    
    func saveAchievements(_ achievements: [Achievement]) {
        do {
            let data = try encoder.encode(achievements)
            userDefaults.set(data, forKey: achievementsKey)
        } catch {
            print("Error saving achievements: \(error)")
        }
    }
    
    func saveStreaks(_ streaks: [Streak]) {
        do {
            let data = try encoder.encode(streaks)
            userDefaults.set(data, forKey: streaksKey)
        } catch {
            print("Error saving streaks: \(error)")
        }
    }
    
    func saveSessionCompletions(_ completions: [SessionCompletion]) {
        do {
            let data = try encoder.encode(completions)
            userDefaults.set(data, forKey: sessionCompletionsKey)
        } catch {
            print("Error saving session completions: \(error)")
        }
    }
    
    func saveSubscription(_ subscription: Subscription?) {
        do {
            if let subscription = subscription {
                let data = try encoder.encode(subscription)
                userDefaults.set(data, forKey: subscriptionKey)
            } else {
                userDefaults.removeObject(forKey: subscriptionKey)
            }
        } catch {
            print("Error saving subscription: \(error)")
        }
    }
    
    // MARK: - Load Methods
    
    func loadUserProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: userProfileKey) else {
            return nil
        }
        
        do {
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            print("Error loading user profile: \(error)")
            return nil
        }
    }
    
    func loadGoals() -> [Goal] {
        guard let data = userDefaults.data(forKey: goalsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([Goal].self, from: data)
        } catch {
            print("Error loading goals: \(error)")
            return []
        }
    }
    
    func loadHealthMetrics() -> [HealthMetric] {
        guard let data = userDefaults.data(forKey: healthMetricsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([HealthMetric].self, from: data)
        } catch {
            print("Error loading health metrics: \(error)")
            return []
        }
    }
    
    func loadAudioSessions() -> [AudioSession] {
        guard let data = userDefaults.data(forKey: audioSessionsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([AudioSession].self, from: data)
        } catch {
            print("Error loading audio sessions: \(error)")
            return []
        }
    }
    
    func loadMoodEntries() -> [MoodEntry] {
        guard let data = userDefaults.data(forKey: moodEntriesKey) else {
            return []
        }
        
        do {
            return try decoder.decode([MoodEntry].self, from: data)
        } catch {
            print("Error loading mood entries: \(error)")
            return []
        }
    }
    
    func loadRecommendations() -> [Recommendation] {
        guard let data = userDefaults.data(forKey: recommendationsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([Recommendation].self, from: data)
        } catch {
            print("Error loading recommendations: \(error)")
            return []
        }
    }
    
    func loadAchievements() -> [Achievement] {
        guard let data = userDefaults.data(forKey: achievementsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([Achievement].self, from: data)
        } catch {
            print("Error loading achievements: \(error)")
            return []
        }
    }
    
    func loadStreaks() -> [Streak] {
        guard let data = userDefaults.data(forKey: streaksKey) else {
            return []
        }
        
        do {
            return try decoder.decode([Streak].self, from: data)
        } catch {
            print("Error loading streaks: \(error)")
            return []
        }
    }
    
    func loadSessionCompletions() -> [SessionCompletion] {
        guard let data = userDefaults.data(forKey: sessionCompletionsKey) else {
            return []
        }
        
        do {
            return try decoder.decode([SessionCompletion].self, from: data)
        } catch {
            print("Error loading session completions: \(error)")
            return []
        }
    }
    
    func loadSubscription() -> Subscription? {
        guard let data = userDefaults.data(forKey: subscriptionKey) else {
            return nil
        }
        
        do {
            return try decoder.decode(Subscription.self, from: data)
        } catch {
            print("Error loading subscription: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear Methods
    
    func clearAllData() {
        let keys = [
            userProfileKey, goalsKey, healthMetricsKey, audioSessionsKey,
            moodEntriesKey, recommendationsKey, achievementsKey,
            streaksKey, sessionCompletionsKey, subscriptionKey
        ]
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }
}
