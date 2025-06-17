//
//  GoalsView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
<<<<<<< HEAD
import CoreData
import Charts
=======
>>>>>>> 510ee9d (more changes')

struct GoalsView: View {
    // MARK: - Environment & State
    
<<<<<<< HEAD
    /// Core Data managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
=======
>>>>>>> 510ee9d (more changes')
    /// Access to environment objects
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    /// View state
<<<<<<< HEAD
    @State private var selectedCategory: GoalCategory = .all
=======
    @State private var selectedCategory: LifeCoachAI.GoalCategory = .all
>>>>>>> 510ee9d (more changes')
    @State private var searchText = ""
    @State private var showAddGoalSheet = false
    @State private var showEditGoalSheet = false
    @State private var selectedGoal: Goal?
    @State private var showAchievementAnimation = false
    @State private var recentlyCompletedGoal: Goal?
    @State private var showFilters = false
<<<<<<< HEAD
    @State private var sortOption: GoalSortOption = .priority
=======
    @State private var sortOption: LifeCoachAI.GoalSortOption = .priority
>>>>>>> 510ee9d (more changes')
    
    // MARK: - Computed Properties
    
    /// All user goals
    private var allGoals: [Goal] {
        return userProfileManager.goals
    }
    
    /// Active goals (not completed)
    private var activeGoals: [Goal] {
        return filteredGoals.filter { !($0.isCompleted) }
    }
    
    /// Completed goals
    private var completedGoals: [Goal] {
        return filteredGoals.filter { $0.isCompleted }
    }
    
    /// Goals filtered by category and search text
    private var filteredGoals: [Goal] {
        var goals = allGoals
        
        // Filter by category if not "All"
        if selectedCategory != .all {
            goals = goals.filter { $0.category == selectedCategory.rawValue }
        }
        
        // Filter by search text if not empty
        if !searchText.isEmpty {
            goals = goals.filter {
                $0.title?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Sort goals
        return sortGoals(goals)
    }
    
    /// Goals due today
    private var todayGoals: [Goal] {
        let today = Calendar.current.startOfDay(for: Date())
        return activeGoals.filter {
            if let dueDate = $0.dueDate {
                return Calendar.current.isDate(dueDate, inSameDayAs: today)
            }
            return false
        }
    }
    
    /// Goals due this week
    private var thisWeekGoals: [Goal] {
        let today = Calendar.current.startOfDay(for: Date())
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        
        return activeGoals.filter {
            if let dueDate = $0.dueDate {
                let isAfterToday = dueDate >= today
                let isBeforeSevenDays = dueDate <= sevenDaysLater
                let isNotToday = !Calendar.current.isDate(dueDate, inSameDayAs: today)
                return isAfterToday && isBeforeSevenDays && isNotToday
            }
            return false
        }
    }
    
    /// Overall progress percentage across all active goals
    private var overallProgress: Double {
        if activeGoals.isEmpty {
            return 0.0
        }
        
        let totalProgress = activeGoals.reduce(0.0) { sum, goal in
<<<<<<< HEAD
            return sum + (goal.progress / 100.0)
=======
            return sum + (goal.progress / 100.0) // Assuming progress is 0-100
>>>>>>> 510ee9d (more changes')
        }
        
        return (totalProgress / Double(activeGoals.count)) * 100.0
    }
    
    // MARK: - Helper Methods
    
    /// Sort goals based on selected sort option
    private func sortGoals(_ goals: [Goal]) -> [Goal] {
        switch sortOption {
        case .priority:
            return goals.sorted { ($0.priority) > ($1.priority) }
        case .dueDate:
            return goals.sorted {
                if let date1 = $0.dueDate, let date2 = $1.dueDate {
                    return date1 < date2
                }
                return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
            }
        case .progress:
            return goals.sorted { ($0.progress) > ($1.progress) }
        case .alphabetical:
            return goals.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .creationDate:
            return goals.sorted { ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast) }
        }
    }
    
    /// Format date to readable string
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Calculate days remaining until due date
    private func daysRemaining(for goal: Goal) -> Int? {
        guard let dueDate = goal.dueDate else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDateDay = calendar.startOfDay(for: dueDate)
        
        if let days = calendar.dateComponents([.day], from: today, to: dueDateDay).day, days >= 0 {
            return days
        }
        
        return nil
    }
    
    /// Check if a goal is overdue
    private func isOverdue(_ goal: Goal) -> Bool {
        guard let dueDate = goal.dueDate else { return false }
        return dueDate < Date() && !goal.isCompleted
    }
    
    /// Update goal progress
    private func updateGoalProgress(_ goal: Goal, newProgress: Double) {
        userProfileManager.updateGoalProgress(goal: goal, progress: newProgress)
        
        // Check if goal is now completed
        if newProgress >= 100 && !goal.isCompleted {
            completeGoal(goal)
        }
    }
    
    /// Mark goal as complete and show celebration
    private func completeGoal(_ goal: Goal) {
        userProfileManager.completeGoal(goal: goal)
        
        // Show achievement animation
        recentlyCompletedGoal = goal
        withAnimation {
            showAchievementAnimation = true
        }
        
        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showAchievementAnimation = false
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Search bar
                    searchBar
                    
                    // Goal summary
                    goalSummaryCard
                    
                    // Category filter
                    categoryFilter
                    
                    // Today's goals
                    if !todayGoals.isEmpty {
                        sectionHeader(title: "Today", subtitle: "\(todayGoals.count) goals due today")
                        
                        ForEach(todayGoals) { goal in
                            goalCard(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                    showEditGoalSheet = true
                                }
                        }
                        .padding(.horizontal)
                    }
                    
                    // This week's goals
                    if !thisWeekGoals.isEmpty {
                        sectionHeader(title: "This Week", subtitle: "\(thisWeekGoals.count) goals due soon")
                        
                        ForEach(thisWeekGoals) { goal in
                            goalCard(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                    showEditGoalSheet = true
                                }
                        }
                        .padding(.horizontal)
                    }
                    
                    // All active goals
                    sectionHeader(
                        title: selectedCategory == .all ? "All Active Goals" : "\(selectedCategory.displayName) Goals",
                        subtitle: "\(activeGoals.count) active goals"
                    )
                    
                    // Sort options
                    HStack {
                        Text("Sort by:")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                        
                        Picker("Sort", selection: $sortOption) {
<<<<<<< HEAD
                            ForEach(GoalSortOption.allCases, id: \.self) { option in
=======
                            ForEach(LifeCoachAI.GoalSortOption.allCases, id: \.self) { option in
>>>>>>> 510ee9d (more changes')
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showFilters.toggle()
                            }
                        }) {
                            Label("Filter", systemImage: "slider.horizontal.3")
                                .font(.subheadline)
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                    .padding(.horizontal)
                    
                    if activeGoals.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(activeGoals) { goal in
                            goalCard(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                    showEditGoalSheet = true
                                }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Completed goals
                    if !completedGoals.isEmpty {
                        sectionHeader(title: "Completed Goals", subtitle: "\(completedGoals.count) goals achieved")
                        
                        ForEach(completedGoals.prefix(5)) { goal in
                            completedGoalCard(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                    showEditGoalSheet = true
                                }
                        }
                        .padding(.horizontal)
                        
                        if completedGoals.count > 5 {
                            Button(action: {
                                // Show all completed goals
                            }) {
                                Text("View All Completed Goals")
                                    .font(.subheadline)
                                    .foregroundColor(Color("AccentColor"))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color("SecondaryBackground"))
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(Color("PrimaryBackground").edgesIgnoringSafeArea(.all))
            
            // Floating action button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showAddGoalSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color("AccentColor"))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Achievement animation overlay
            if showAchievementAnimation, let goal = recentlyCompletedGoal {
                achievementAnimation(for: goal)
            }
        }
        .sheet(isPresented: $showAddGoalSheet) {
            AddGoalView()
                .environmentObject(userProfileManager)
                .environmentObject(notificationManager)
        }
        .sheet(item: $selectedGoal, onDismiss: {
            selectedGoal = nil
        }) { goal in
            EditGoalView(goal: goal)
                .environmentObject(userProfileManager)
                .environmentObject(notificationManager)
        }
    }
    
    // MARK: - UI Components
    
    /// Search bar component
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search goals", text: $searchText)
                .foregroundColor(Color("PrimaryText"))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    /// Goal summary card component
    private var goalSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(Int(overallProgress))% Complete")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.3)
                        .foregroundColor(.white)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(overallProgress / 100.0))
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.white)
                        .rotationEffect(Angle(degrees: 270.0))
                    
                    Text("\(Int(overallProgress))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(width: 80, height: 80)
            }
            
            HStack {
                VStack {
                    Text("\(activeGoals.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.5))
                    .frame(height: 40)
                
                VStack {
                    Text("\(todayGoals.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Due Today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.5))
                    .frame(height: 40)
                
                VStack {
                    Text("\(completedGoals.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color("AccentColor"), Color("AccentColor").opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    /// Category filter component
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
<<<<<<< HEAD
                ForEach(GoalCategory.allCases, id: \.self) { category in
=======
                ForEach(LifeCoachAI.GoalCategory.allCases, id: \.self) { category in
>>>>>>> 510ee9d (more changes')
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedCategory == category ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category ? 
                                    Color("AccentColor") : 
                                    Color("SecondaryBackground")
                            )
                            .foregroundColor(
                                selectedCategory == category ? 
                                    .white : 
                                    Color("PrimaryText")
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Section header component
    private func sectionHeader(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("PrimaryText"))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    /// Goal card component
    private func goalCard(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Goal category icon
                Image(systemName: goal.categoryIcon)
                    .font(.title2)
                    .foregroundColor(goal.categoryColor)
                    .frame(width: 40, height: 40)
                    .background(goal.categoryColor.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(goal.title ?? "Untitled Goal")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Spacer()
                        
                        // Priority indicator
                        if goal.priority > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<Int(goal.priority), id: \.self) { _ in
                                    Image(systemName: "flag.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    if let description = goal.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                            .lineLimit(2)
                    }
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress: \(Int(goal.progress))%")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Spacer()
                    
                    if let daysLeft = daysRemaining(for: goal) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            
                            Text(daysLeft == 0 ? "Due today" : "\(daysLeft) days left")
                                .font(.caption)
                        }
                        .foregroundColor(daysLeft < 3 ? .red : Color("SecondaryText"))
                    }
                }
                
                ProgressView(value: goal.progress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: goal.categoryColor))
            }
            
            // Goal actions
            HStack {
                // Update progress buttons
                Button(action: {
                    updateGoalProgress(goal, newProgress: min(100, goal.progress + 10))
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .padding(8)
                        .background(Color("SecondaryBackground"))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    updateGoalProgress(goal, newProgress: max(0, goal.progress - 10))
                }) {
                    Image(systemName: "minus")
                        .font(.caption)
                        .padding(8)
                        .background(Color("SecondaryBackground"))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Complete button (if not already complete)
                if goal.progress < 100 {
                    Button(action: {
                        completeGoal(goal)
                    }) {
                        Text("Mark Complete")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOverdue(goal) ? Color.red : Color.clear, lineWidth: 2)
        )
    }
    
    /// Completed goal card component
    private func completedGoalCard(goal: Goal) -> some View {
        HStack(spacing: 16) {
            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title ?? "Untitled Goal")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                    .strikethrough()
                
                if let completionDate = goal.completionDate {
                    Text("Completed on \(formatDate(completionDate))")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            
            Spacer()
            
            // Category indicator
            Text(goal.categoryName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(goal.categoryColor.opacity(0.2))
                .foregroundColor(goal.categoryColor)
                .cornerRadius(10)
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
        .opacity(0.8)
    }
    
    /// Empty state view when no goals match filters
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(Color("AccentColor").opacity(0.6))
            
            Text("No goals found")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            
            Text("Create a new goal or adjust your filters")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showAddGoalSheet = true
            }) {
                Text("Create New Goal")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    /// Achievement animation overlay
    private func achievementAnimation(for goal: Goal) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Confetti animation would go here
                
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("Goal Achieved!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(goal.title ?? "")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Congratulations on your achievement!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        showAchievementAnimation = false
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color("AccentColor"))
                        .cornerRadius(20)
                }
                .padding(.top, 16)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
            .scaleEffect(showAchievementAnimation ? 1.0 : 0.5)
            .opacity(showAchievementAnimation ? 1.0 : 0.0)
            .animation(.spring(), value: showAchievementAnimation)
        }
    }
}

// MARK: - Add Goal View

struct AddGoalView: View {
    @Environment(\.presentationMode) private var presentationMode
<<<<<<< HEAD
    @Environment(\.managedObjectContext) private var viewContext
=======
>>>>>>> 510ee9d (more changes')
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var title = ""
    @State private var description = ""
<<<<<<< HEAD
    @State private var category: GoalCategory = .health
=======
    @State private var category: LifeCoachAI.GoalCategory = .health
>>>>>>> 510ee9d (more changes')
    @State private var targetValue: Double = 0
    @State private var unit = ""
    @State private var dueDate = Date().addingTimeInterval(60*60*24*7) // One week from now
    @State private var priority: Double = 1
    @State private var enableReminders = false
    @State private var reminderTime = Date()
<<<<<<< HEAD
    @State private var frequency: GoalFrequency = .daily
=======
    @State private var frequency: LifeCoachAI.GoalFrequency = .daily
>>>>>>> 510ee9d (more changes')
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                        .frame(height: 80)
                    
                    Picker("Category", selection: $category) {
<<<<<<< HEAD
                        ForEach(GoalCategory.allCases.filter { $0 != .all }, id: \.self) { category in
=======
                        ForEach(LifeCoachAI.GoalCategory.allCases.filter { $0 != .all }, id: \.self) { category in
>>>>>>> 510ee9d (more changes')
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
<<<<<<< HEAD
                        ForEach(GoalFrequency.allCases, id: \.self) { frequency in
=======
                        ForEach(LifeCoachAI.GoalFrequency.allCases, id: \.self) { frequency in
>>>>>>> 510ee9d (more changes')
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("Target")) {
                    HStack {
                        Text("Target Value")
                        Spacer()
                        TextField("Value", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    TextField("Unit (e.g., steps, hours)", text: $unit)
                }
                
                Section(header: Text("Timeline")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    
                    HStack {
                        Text("Priority")
                        Spacer()
                        Picker("Priority", selection: $priority) {
                            Text("Low").tag(1.0)
                            Text("Medium").tag(2.0)
                            Text("High").tag(3.0)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                
                Section(header: Text("Reminders")) {
                    Toggle("Enable Reminders", isOn: $enableReminders)
                    
                    if enableReminders {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                    }
                }
            }
            .navigationTitle("Add New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveGoal() {
        userProfileManager.createGoal(
            title: title,
            description: description,
            category: category.rawValue,
            targetValue: targetValue,
            unit: unit,
            dueDate: dueDate,
            frequency: frequency.rawValue,
            priority: priority
        )
        
        // Schedule reminder if enabled
        if enableReminders {
            notificationManager.scheduleGoalReminder(
                title: title,
                body: "Don't forget to work on your goal: \(title)",
                date: reminderTime,
                frequency: frequency
            )
        }
    }
}

// MARK: - Edit Goal View

struct EditGoalView: View {
    @Environment(\.presentationMode) private var presentationMode
<<<<<<< HEAD
    @Environment(\.managedObjectContext) private var viewContext
=======
>>>>>>> 510ee9d (more changes')
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    let goal: Goal
    
    @State private var title: String
    @State private var description: String
<<<<<<< HEAD
    @State private var category: GoalCategory
=======
    @State private var category: LifeCoachAI.GoalCategory
>>>>>>> 510ee9d (more changes')
    @State private var targetValue: Double
    @State private var unit: String
    @State private var dueDate: Date
    @State private var priority: Double
    @State private var progress: Double
    @State private var enableReminders: Bool
    @State private var reminderTime: Date
<<<<<<< HEAD
    @State private var frequency: GoalFrequency
=======
    @State private var frequency: LifeCoachAI.GoalFrequency
>>>>>>> 510ee9d (more changes')
    @State private var showDeleteConfirmation = false
    
    init(goal: Goal) {
        self.goal = goal
        
        // Initialize state variables with goal properties
        _title = State(initialValue: goal.title ?? "")
        _description = State(initialValue: goal.description ?? "")
<<<<<<< HEAD
        _category = State(initialValue: GoalCategory(rawValue: goal.category ?? "health") ?? .health)
=======
        _category = State(initialValue: LifeCoachAI.GoalCategory(rawValue: goal.category ?? "health") ?? .health)
>>>>>>> 510ee9d (more changes')
        _targetValue = State(initialValue: goal.targetValue)
        _unit = State(initialValue: goal.unit ?? "")
        _dueDate = State(initialValue: goal.dueDate ?? Date().addingTimeInterval(60*60*24*7))
        _priority = State(initialValue: goal.priority)
        _progress = State(initialValue: goal.progress)
        _enableReminders = State(initialValue: goal.hasReminder)
        _reminderTime = State(initialValue: goal.reminderTime ?? Date())
<<<<<<< HEAD
        _frequency = State(initialValue: GoalFrequency(rawValue: goal.frequency ?? "daily") ?? .daily)
=======
        _frequency = State(initialValue: LifeCoachAI.GoalFrequency(rawValue: goal.frequency ?? "daily") ?? .daily)
>>>>>>> 510ee9d (more changes')
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                        .frame(height: 80)
                    
                    Picker("Category", selection: $category) {
<<<<<<< HEAD
                        ForEach(GoalCategory.allCases.filter { $0 != .all }, id: \.self) { category in
=======
                        ForEach(LifeCoachAI.GoalCategory.allCases.filter { $0 != .all }, id: \.self) { category in
>>>>>>> 510ee9d (more changes')
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
<<<<<<< HEAD
                        ForEach(GoalFrequency.allCases, id: \.self) { frequency in
=======
                        ForEach(LifeCoachAI.GoalFrequency.allCases, id: \.self) { frequency in
>>>>>>> 510ee9d (more changes')
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("Progress")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress: \(Int(progress))%")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                progress = 100
                            }) {
                                Text("Mark Complete")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color("AccentColor"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(progress >= 100)
                        }
                        
                        Slider(value: $progress, in: 0...100, step: 5)
                            .accentColor(category.color)
                    }
                    
                    HStack {
                        Text("Target Value")
                        Spacer()
                        TextField("Value", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    TextField("Unit (e.g., steps, hours)", text: $unit)
                }
                
                Section(header: Text("Timeline")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    
                    HStack {
                        Text("Priority")
                        Spacer()
                        Picker("Priority", selection: $priority) {
                            Text("Low").tag(1.0)
                            Text("Medium").tag(2.0)
                            Text("High").tag(3.0)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                
                Section(header: Text("Reminders")) {
                    Toggle("Enable Reminders", isOn: $enableReminders)
                    
                    if enableReminders {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                    }
                }
                
                Section {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Goal")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateGoal()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Goal"),
                    message: Text("Are you sure you want to delete this goal? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        userProfileManager.deleteGoal(goal: goal)
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func updateGoal() {
        userProfileManager.updateGoal(
            goal: goal,
            title: title,
            description: description,
            category: category.rawValue,
            targetValue: targetValue,
            unit: unit,
            dueDate: dueDate,
            frequency: frequency.rawValue,
            priority: priority,
            progress: progress
        )
        
        // Update reminder if enabled
        if enableReminders {
            notificationManager.scheduleGoalReminder(
                title: title,
                body: "Don't forget to work on your goal: \(title)",
                date: reminderTime,
                frequency: frequency
            )
        } else {
<<<<<<< HEAD
            notificationManager.removeReminders(for: goal.id?.uuidString ?? "")
=======
            notificationManager.removeReminders(for: goal.id.uuidString)
>>>>>>> 510ee9d (more changes')
        }
    }
}

<<<<<<< HEAD
// MARK: - Supporting Types

// Note: Goal-related enums are defined in DataModels.swift

// MARK: - Goal Extensions

// Note: Goal extensions are defined in DataModels.swift

=======
>>>>>>> 510ee9d (more changes')
// MARK: - Preview
struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
<<<<<<< HEAD
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
=======
>>>>>>> 510ee9d (more changes')
            .environmentObject(UserProfileManager())
            .environmentObject(StoreManager())
            .environmentObject(NotificationManager())
    }
}
