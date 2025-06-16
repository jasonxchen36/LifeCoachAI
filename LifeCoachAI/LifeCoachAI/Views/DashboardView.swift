//
//  DashboardView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import HealthKit

struct DashboardView: View {
    // MARK: - Environment Objects
    
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var mlManager: MLManager
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var storeManager: StoreManager
    
    // MARK: - State Variables
    
    @State private var selectedTab = 0
    @State private var showingRecommendationDetail = false
    @State private var selectedRecommendation: Recommendation?
    @State private var showingGoalDetail = false
    @State private var selectedGoal: Goal?
    @State private var showingAudioSession = false
    @State private var selectedAudioSession: AudioSession?
    @State private var isRefreshing = false
    @State private var showingPaywall = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with greeting and profile
                headerSection
                
                // Quick actions
                quickActionsSection
                
                // Today's recommendations
                recommendationsSection
                
                // Goal progress
                goalsSection
                
                // Health metrics
                healthMetricsSection
                
                // Achievements and streaks
                achievementsSection
                
                // Audio sessions
                audioSessionsSection
                
                // Spacer at bottom for better scrolling
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal)
        }
        .refreshable {
            await refreshData()
        }
        .overlay(
            // Loading indicator
            Group {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 60, height: 60)
                        .background(Color("SecondaryBackground").opacity(0.8))
                        .cornerRadius(10)
                }
            }
        )
        .sheet(isPresented: $showingRecommendationDetail) {
            if let recommendation = selectedRecommendation {
                RecommendationDetailView(recommendation: recommendation)
                    .environmentObject(mlManager)
            }
        }
        .sheet(isPresented: $showingGoalDetail) {
            if let goal = selectedGoal {
                GoalDetailView(goal: goal)
                    .environmentObject(userProfileManager)
                    .environmentObject(healthKitManager)
            }
        }
        .sheet(isPresented: $showingAudioSession) {
            if let session = selectedAudioSession {
                AudioPlayerView(session: session)
                    .environmentObject(audioManager)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isPresented: $showingPaywall)
                .environmentObject(storeManager)
        }
        .onAppear {
            // Refresh data when view appears
            Task {
                await refreshData()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 15) {
            // User profile and greeting
            VStack(alignment: .leading, spacing: 4) {
                Text(userProfileManager.personalizedGreeting)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(getTodayDateString())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Profile image or initials
            Button(action: {
                // Navigate to profile
                // This would typically use a navigation link or present a sheet
            }) {
                if let profileImage = userProfileManager.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Text(userProfileManager.userInitials)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color("AccentColor"))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Log mood action
                QuickActionButton(
                    icon: "face.smiling",
                    title: "Log Mood",
                    color: Color.blue,
                    action: {
                        // Navigate to mood logging screen
                    }
                )
                
                // Add water action
                QuickActionButton(
                    icon: "drop.fill",
                    title: "Add Water",
                    color: Color.cyan,
                    action: {
                        // Show water logging dialog
                    }
                )
                
                // Quick meditation action
                QuickActionButton(
                    icon: "brain.head.profile",
                    title: "Meditate",
                    color: Color.purple,
                    action: {
                        // Start quick meditation session
                        if let meditationSession = audioManager.getSessionsByCategory(.meditation).first {
                            selectedAudioSession = meditationSession
                            showingAudioSession = true
                        }
                    }
                )
                
                // Add goal action
                QuickActionButton(
                    icon: "plus.circle",
                    title: "Add Goal",
                    color: Color.green,
                    action: {
                        // Navigate to add goal screen
                    }
                )
                
                // View insights action
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Insights",
                    color: Color.orange,
                    action: {
                        // Navigate to insights tab
                    }
                )
            }
            .padding(.vertical, 5)
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's Recommendations", icon: "lightbulb.fill")
            
            if mlManager.highPriorityRecommendations.isEmpty {
                // No recommendations placeholder
                EmptyStateView(
                    icon: "lightbulb",
                    title: "No Recommendations Yet",
                    message: "Check back later for personalized recommendations based on your activity and goals."
                )
            } else {
                // Recommendations cards
                ForEach(mlManager.highPriorityRecommendations.prefix(3)) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                        .onTapGesture {
                            selectedRecommendation = recommendation
                            showingRecommendationDetail = true
                        }
                }
                
                // View all button if there are more recommendations
                if mlManager.todayRecommendations.count > 3 {
                    Button(action: {
                        // Navigate to all recommendations
                    }) {
                        Text("View All (\(mlManager.todayRecommendations.count))")
                            .font(.subheadline)
                            .foregroundColor(Color("AccentColor"))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color("SecondaryBackground"))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's Goals", icon: "target")
            
            if userProfileManager.activeGoals.isEmpty {
                // No goals placeholder
                EmptyStateView(
                    icon: "target",
                    title: "No Active Goals",
                    message: "Set goals to track your progress and build healthy habits."
                )
                
                // Add goal button
                Button(action: {
                    // Navigate to add goal screen
                }) {
                    Text("Add Your First Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor"))
                        .cornerRadius(10)
                }
            } else {
                // Goal progress cards
                ForEach(userProfileManager.activeGoals.prefix(3)) { goal in
                    GoalProgressCard(goal: goal)
                        .onTapGesture {
                            selectedGoal = goal
                            showingGoalDetail = true
                        }
                }
                
                // View all button if there are more goals
                if userProfileManager.activeGoals.count > 3 {
                    Button(action: {
                        // Navigate to all goals
                    }) {
                        Text("View All (\(userProfileManager.activeGoals.count))")
                            .font(.subheadline)
                            .foregroundColor(Color("AccentColor"))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color("SecondaryBackground"))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Health Metrics", icon: "heart.text.square")
            
            // Health metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                // Steps metric
                HealthMetricCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: formatNumber(healthKitManager.todaySteps),
                    goal: "10,000",
                    progress: healthKitManager.todaySteps / 10000,
                    color: .green
                )
                
                // Active energy metric
                HealthMetricCard(
                    icon: "flame.fill",
                    title: "Active Energy",
                    value: "\(Int(healthKitManager.todayActiveEnergy))",
                    unit: "kcal",
                    goal: "500",
                    progress: healthKitManager.todayActiveEnergy / 500,
                    color: .orange
                )
                
                // Heart rate metric
                HealthMetricCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(Int(healthKitManager.latestHeartRate))",
                    unit: "BPM",
                    color: .red
                )
                
                // Sleep metric
                HealthMetricCard(
                    icon: "bed.double.fill",
                    title: "Sleep",
                    value: formatHours(healthKitManager.latestSleepHours),
                    goal: "8h",
                    progress: healthKitManager.latestSleepHours / 8,
                    color: .indigo
                )
            }
            
            // Weekly activity chart
            if !healthKitManager.weeklyStepsData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Activity")
                        .font(.headline)
                    
                    WeeklyActivityChart(data: healthKitManager.weeklyStepsData)
                        .frame(height: 150)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Achievements & Streaks", icon: "trophy.fill")
            
            // Streak cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Show streak cards for top categories
                    ForEach(Array(userProfileManager.streakData.keys.prefix(3)), id: \.self) { category in
                        if let streak = userProfileManager.streakData[category], streak > 0 {
                            StreakCard(
                                category: category,
                                streak: streak,
                                color: getCategoryColor(category)
                            )
                        }
                    }
                    
                    // If no streaks, show a placeholder
                    if userProfileManager.streakData.isEmpty || userProfileManager.streakData.values.filter({ $0 > 0 }).isEmpty {
                        EmptyStreakCard()
                    }
                }
            }
            
            // Completion rate card
            CompletionRateCard(
                rate: userProfileManager.goalCompletionRate,
                completedCount: userProfileManager.completedGoals.count,
                totalCount: userProfileManager.activeGoals.count + userProfileManager.completedGoals.count
            )
        }
    }
    
    // MARK: - Audio Sessions Section
    
    private var audioSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Audio Sessions", icon: "headphones")
            
            // Recommended sessions
            if audioManager.recommendedSessions.isEmpty {
                // No sessions placeholder
                EmptyStateView(
                    icon: "headphones",
                    title: "No Audio Sessions",
                    message: "Explore our library to find guided meditations, sleep stories, and more."
                )
                
                // Explore button
                Button(action: {
                    // Navigate to audio library
                }) {
                    Text("Explore Audio Library")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor"))
                        .cornerRadius(10)
                }
            } else {
                // Session cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(audioManager.recommendedSessions.prefix(5)) { session in
                            AudioSessionCard(session: session)
                                .onTapGesture {
                                    // Check if premium session
                                    if session.isPremium && !storeManager.isPremium {
                                        showingPaywall = true
                                    } else {
                                        selectedAudioSession = session
                                        showingAudioSession = true
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Refresh all data
    private func refreshData() async {
        isRefreshing = true
        
        // Refresh health data
        healthKitManager.fetchInitialHealthData()
        
        // Generate recommendations if needed
        if mlManager.todayRecommendations.isEmpty || 
           Calendar.current.isDateInYesterday(mlManager.lastRecommendationDate ?? Date.distantPast) {
            try? await mlManager.generateDailyRecommendations()
        }
        
        // Refresh user goals
        // This would typically be an async call, but our UserProfileManager doesn't have async methods yet
        
        // Simulate a delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isRefreshing = false
    }
    
    /// Format number with commas
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    /// Format hours as "Xh Ym"
    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
    
    /// Get today's date as a formatted string
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    /// Get color for category
    private func getCategoryColor(_ category: String) -> Color {
        if let goalCategory = GoalCategory(rawValue: category) {
            return goalCategory.color
        }
        return .blue
    }
}

// MARK: - Helper Components

/// Section header view
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
        }
    }
}

/// Quick action button view
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 80)
        }
    }
}

/// Recommendation card view
struct RecommendationCard: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Category icon
                Image(systemName: getCategoryIcon(recommendation.category ?? ""))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(getCategoryColor(recommendation.category ?? ""))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title ?? "")
                        .font(.headline)
                    
                    Text(recommendation.category ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Priority indicator
                if recommendation.priority >= 2 {
                    Image(systemName: recommendation.priority >= 3 ? "exclamationmark.2" : "exclamationmark")
                        .foregroundColor(recommendation.priority >= 3 ? .red : .orange)
                }
                
                // Premium indicator
                if recommendation.isPremium {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(recommendation.content ?? "")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.secondary)
            
            HStack {
                // Time
                if let createdDate = recommendation.createdDate {
                    Text(formatDate(createdDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                Button(action: {
                    // Accept recommendation
                }) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    // Decline recommendation
                }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to get category icon
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "fitness": return "figure.walk"
        case "health": return "heart"
        case "nutrition": return "fork.knife"
        case "mindfulness": return "brain.head.profile"
        case "sleep": return "bed.double"
        default: return "lightbulb"
        }
    }
    
    // Helper function to get category color
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "fitness": return .orange
        case "health": return .red
        case "nutrition": return .green
        case "mindfulness": return .blue
        case "sleep": return .purple
        default: return Color("AccentColor")
        }
    }
}

/// Goal progress card view
struct GoalProgressCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Category icon
                Image(systemName: getCategoryIcon(goal.category ?? "health"))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(getCategoryColor(goal.category ?? "health"))
                    .clipShape(Circle())
                
                Text(goal.title ?? "")
                    .font(.headline)
                
                Spacer()
                
                // Streak badge (placeholder since Goal doesn't have streak)
                if let streak = getGoalStreak(goal) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        
                        Text("\(streak)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // Progress bar
            ProgressView(value: goal.progress, total: goal.targetValue)
                .progressViewStyle(LinearProgressViewStyle(tint: getCategoryColor(goal.category ?? "health")))
                .background(Color.gray.opacity(0.2).cornerRadius(10))
            
            HStack {
                // Current value
                Text(formatValue(goal.progress, unit: goal.unit))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Target value
                Text("Goal: \(formatValue(goal.targetValue, unit: goal.unit))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Complete button
            if !goal.isCompleted {
                Button(action: {
                    // Mark goal as completed
                }) {
                    Text("Complete")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(getCategoryColor(goal.category ?? "health"))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
    
    // Helper function to get category icon
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "fitness": return "figure.walk"
        case "health": return "heart"
        case "nutrition": return "fork.knife"
        case "mindfulness": return "brain.head.profile"
        case "sleep": return "bed.double"
        case "work": return "briefcase"
        case "learning": return "book"
        case "personal": return "person"
        default: return "target"
        }
    }
    
    // Helper function to get category color
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "health": return .red
        case "fitness": return .orange
        case "nutrition": return .green
        case "mindfulness": return .blue
        case "sleep": return .purple
        case "work": return .gray
        case "learning": return .yellow
        case "personal": return .pink
        default: return Color("AccentColor")
        }
    }
    
    // Helper function to format value with unit
    private func formatValue(_ value: Double, unit: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        let formattedValue = formatter.string(from: NSNumber(value: value)) ?? "0"
        if let unit = unit, !unit.isEmpty {
            return "\(formattedValue) \(unit)"
        } else {
            return formattedValue
        }
    }
    
    // Helper function to get goal streak (placeholder)
    private func getGoalStreak(_ goal: Goal) -> Int? {
        // In a real app, this would come from the goal or a related streak object
        // For now, return a random value for demonstration
        if goal.progress > 0 {
            return Int.random(in: 1...5)
        }
        return nil
    }
}

/// Health metric card view
struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    var unit: String? = nil
    var goal: String? = nil
    var progress: Double? = nil
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar if goal is provided
            if let progress = progress, let goal = goal {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .background(Color.gray.opacity(0.2).cornerRadius(10))
                    
                    Text("Goal: \(goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
        .frame(height: 140)
    }
}

/// Weekly activity chart view
struct WeeklyActivityChart: View {
    let data: [Date: Double]
    
    var body: some View {
        let sortedData = data.sorted { $0.key < $1.key }
        
        // Always use the fallback for iOS 15
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(sortedData, id: \.key) { date, value in
                VStack {
                    // Bar
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 30, height: getBarHeight(value))
                    
                    // Day label
                    Text(formatDayOfWeek(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 150)
    }
    
    /// Format date to day of week
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    /// Calculate bar height for iOS 15 fallback
    private func getBarHeight(_ value: Double) -> CGFloat {
        let maxValue = data.values.max() ?? 10000
        return CGFloat(value / maxValue) * 120
    }
}

/// Streak card view
struct StreakCard: View {
    let category: String
    let streak: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            // Flame icon
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundColor(color)
            
            // Streak count
            Text("\(streak)")
                .font(.title)
                .fontWeight(.bold)
            
            // Category name
            Text(category)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // Day text
            Text(streak == 1 ? "day" : "days")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 130)
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
}

/// Empty streak card view
struct EmptyStreakCard: View {
    var body: some View {
        VStack(spacing: 10) {
            // Flame icon
            Image(systemName: "flame")
                .font(.system(size: 30))
                .foregroundColor(.gray)
            
            // Text
            Text("No Streaks")
                .font(.headline)
            
            Text("Complete goals to build streaks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 150, height: 130)
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
}

/// Completion rate card view
struct CompletionRateCard: View {
    let rate: Double
    let completedCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text("Goal Completion Rate")
                .font(.headline)
            
            // Progress bar
            ProgressView(value: rate)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.green))
                .background(Color.gray.opacity(0.2).cornerRadius(10))
            
            // Stats
            HStack {
                Text("\(Int(rate * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("\(completedCount) of \(totalCount) goals completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
}

/// Audio session card view
struct AudioSessionCard: View {
    let session: AudioSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category icon and duration
            HStack {
                Image(systemName: getCategoryIcon(session.category))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(getCategoryColor(session.category))
                    .clipShape(Circle())
                
                Spacer()
                
                // Duration
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Title
            Text(session.title ?? "")
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Description if available
            if let description = session.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Play button
            HStack {
                // Premium badge if applicable
                if session.isPremium {
                    Label("Premium", systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(getCategoryColor(session.category))
            }
        }
        .padding()
        .frame(width: 160, height: 180)
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
    
    // Helper function to get category icon
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "meditation": return "brain.head.profile"
        case "sleep": return "bed.double"
        case "focus": return "target"
        case "stress": return "wind"
        case "coaching": return "person.fill.checkmark"
        case "motivation": return "flame.fill"
        default: return "headphones"
        }
    }
    
    // Helper function to get category color
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "meditation": return .blue
        case "sleep": return .purple
        case "focus": return .green
        case "stress": return .orange
        case "coaching": return .red
        case "motivation": return .yellow
        default: return Color("AccentColor")
        }
    }
    
    // Helper function to format duration
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

/// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
}

// MARK: - Placeholder Views for Sheets

/// Recommendation detail view placeholder
struct RecommendationDetailView: View {
    let recommendation: Recommendation
    @EnvironmentObject var mlManager: MLManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with category icon
                    HStack {
                        Image(systemName: getCategoryIcon(recommendation.category ?? ""))
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(getCategoryColor(recommendation.category ?? ""))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendation.title ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(recommendation.category ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Priority indicator
                        if recommendation.priority >= 2 {
                            Image(systemName: recommendation.priority >= 3 ? "exclamationmark.2" : "exclamationmark")
                                .foregroundColor(recommendation.priority >= 3 ? .red : .orange)
                                .font(.title2)
                        }
                    }
                    
                    // Content
                    Text(recommendation.content ?? "")
                        .font(.body)
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        Button(action: {
                            mlManager.markRecommendationAsAccepted(id: recommendation.id)
                            dismiss()
                        }) {
                            Text("Accept")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            mlManager.markRecommendationAsDeclined(id: recommendation.id)
                            dismiss()
                        }) {
                            Text("Decline")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Recommendation", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { dismiss() })
        }
    }
    
    // Helper function to get category icon
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "fitness": return "figure.walk"
        case "health": return "heart"
        case "nutrition": return "fork.knife"
        case "mindfulness": return "brain.head.profile"
        case "sleep": return "bed.double"
        default: return "lightbulb"
        }
    }
    
    // Helper function to get category color
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "fitness": return .orange
        case "health": return .red
        case "nutrition": return .green
        case "mindfulness": return .blue
        case "sleep": return .purple
        default: return Color("AccentColor")
        }
    }
}

/// Goal detail view placeholder
struct GoalDetailView: View {
    let goal: Goal
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Goal Detail View")
                .navigationBarTitle("Goal Details", displayMode: .inline)
                .navigationBarItems(trailing: Button("Close") { dismiss() })
        }
    }
}

/// Audio player view placeholder
struct AudioPlayerView: View {
    let session: AudioSession
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Audio Player View")
                .navigationBarTitle("Now Playing", displayMode: .inline)
                .navigationBarItems(trailing: Button("Close") { dismiss() })
        }
    }
}

/// Paywall view placeholder
struct PaywallView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        NavigationView {
            Text("Paywall View")
                .navigationBarTitle("Premium Features", displayMode: .inline)
                .navigationBarItems(trailing: Button("Close") { isPresented = false })
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserProfileManager())
            .environmentObject(HealthKitManager())
            .environmentObject(MLManager())
            .environmentObject(AudioManager())
            .environmentObject(StoreManager())
    }
}
