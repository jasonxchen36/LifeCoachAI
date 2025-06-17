import CoreData
import Foundation

@objc(Achievement)
public class Achievement: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var category: String?
    @NSManaged public var achievedDate: Date?
    @NSManaged public var level: Int16
}

@objc(AudioSession)
public class AudioSession: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var category: String?
    @NSManaged public var duration: Double
    @NSManaged public var audioFileName: String?
    @NSManaged public var isPremium: Bool
}

@objc(Goal)
public class Goal: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var category: String?
    @NSManaged public var targetValue: Double
    @NSManaged public var currentProgress: Double
    @NSManaged public var unit: String?
    @NSManaged public var priority: Double
    @NSManaged public var dueDate: Date?
    @NSManaged public var creationDate: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isActive: Bool
    @NSManaged public var status: String?
}

@objc(GoalProgress)
public class GoalProgress: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var value: Double
}

@objc(HealthMetric)
public class HealthMetric: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var metricType: String?
    @NSManaged public var value: Double
    @NSManaged public var date: Date?
    @NSManaged public var unit: String?
}

@objc(MoodEntry)
public class MoodEntry: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var moodScore: Int16
}

@objc(Recommendation)
public class Recommendation: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var category: String?
    @NSManaged public var priority: Int16
    @NSManaged public var creationDate: Date?
    @NSManaged public var isPremium: Bool
    @NSManaged public var status: String?
}

@objc(SessionCompletion)
public class SessionCompletion: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var completionDate: Date?
    @NSManaged public var durationSeconds: Double
}

@objc(Streak)
public class Streak: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var currentCount: Int32
    @NSManaged public var longestCount: Int32
    @NSManaged public var lastUpdatedDate: Date?
}

@objc(Subscription)
public class Subscription: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var expirationDate: Date?
}

@objc(UserProfile)
public class UserProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var isOnboarded: Bool
    @NSManaged public var isPremium: Bool
}