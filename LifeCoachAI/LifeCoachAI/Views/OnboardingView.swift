//
//  OnboardingView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import HealthKit

struct OnboardingView: View {
    // MARK: - Environment & State
    
    /// Binding to indicate onboarding completion
    @Binding var hasCompletedOnboarding: Bool
    
    /// Access to environment objects
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var userProfileManager: UserProfileManager
    
    /// View state
    @State private var currentStep = 0
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender = Gender.notSpecified
    @State private var height = 170.0 // cm
    @State private var weight = 70.0  // kg
    @State private var selectedGoalCategories: Set<LifeCoachAI.GoalCategory> = []
    @State private var selectedAudioCategories: Set<LifeCoachAI.AudioCategory> = []
    @State private var enableHealthKit = false
    @State private var enableNotifications = false
    
    /// Animation states
    @State private var animateStep = false
    
    /// Measurement system (true for metric, false for imperial)
    @State private var useMetricSystem = true
    
    // MARK: - Onboarding Steps
    
    private let onboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to LifeCoach AI",
            description: "Your personal guide to a healthier and happier life. Let's get started by personalizing your experience.",
            icon: "figure.wave",
            viewType: .welcome
        ),
        OnboardingStep(
            title: "Personal Information",
            description: "Help us tailor recommendations by providing some basic information about yourself.",
            icon: "person.fill",
            viewType: .personalInfo
        ),
        OnboardingStep(
            title: "Set Your Goals",
            description: "What areas of your life would you like to focus on? Select your primary goal categories.",
            icon: "target",
            viewType: .goalSelection
        ),
        OnboardingStep(
            title: "Audio Preferences",
            description: "Choose your preferred audio content categories for guided meditations, coaching sessions, and more.",
            icon: "headphones",
            viewType: .audioSelection
        ),
        OnboardingStep(
            title: "Connect to Health",
            description: "Connect to Apple Health to allow LifeCoach AI to track your activity, sleep, and other health data for personalized insights.",
            icon: "heart.fill",
            viewType: .healthPermissions
        ),
        OnboardingStep(
            title: "Enable Notifications",
            description: "Stay on track with reminders, recommendations, and insights by enabling notifications.",
            icon: "bell.fill",
            viewType: .notificationPermissions
        ),
        OnboardingStep(
            title: "You're All Set!",
            description: "Your personalized LifeCoach AI experience is ready. Let's begin your journey to a better you.",
            icon: "checkmark.circle.fill",
            viewType: .summary
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color("PrimaryBackground")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(onboardingSteps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("AccentColor")))
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                // Step content
                TabView(selection: $currentStep) {
                    ForEach(onboardingSteps.indices, id: \.self) { index in
                        stepView(for: onboardingSteps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                navigationButtons
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Step Views
    
    /// View for a single onboarding step
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        VStack(spacing: 30) {
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 60))
                .foregroundColor(Color("AccentColor"))
                .padding(.top, 40)
            
            // Title
            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("PrimaryText"))
            
            // Description
            Text(step.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("SecondaryText"))
                .padding(.horizontal, 40)
            
            // Content based on view type
            switch step.viewType {
            case .personalInfo:
                personalInfoForm
            case .goalSelection:
                goalSelectionGrid
            case .audioSelection:
                audioSelectionGrid
            case .healthPermissions:
                healthPermissionsToggle
            case .notificationPermissions:
                notificationPermissionsToggle
            default:
                Spacer()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .opacity(animateStep ? 1 : 0)
        .offset(y: animateStep ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateStep = true
            }
        }
        .onChange(of: currentStep) { _ in
            animateStep = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateStep = true
                }
            }
        }
    }
    
    /// Personal information form
    private var personalInfoForm: some View {
        Form {
            Section(header: Text("About You")) {
                TextField("Name", text: $name)
                
                DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
            }
            
            Section(header: Text("Measurements")) {
                // Measurement system toggle
                Toggle("Use Metric System (cm/kg)", isOn: $useMetricSystem)
                
                // Height
                HStack {
                    Text("Height")
                    Spacer()
                    if useMetricSystem {
                        Text("\(Int(height)) cm")
                    } else {
                        let heightInInches = height / 2.54
                        let feet = Int(heightInInches / 12)
                        let inches = Int(heightInInches.truncatingRemainder(dividingBy: 12))
                        Text("\(feet)' \(inches)\"")
                    }
                }
                Slider(
                    value: $height,
                    in: useMetricSystem ? 120...220 : 48...87, // cm or inches
                    step: 1
                )
                
                // Weight
                HStack {
                    Text("Weight")
                    Spacer()
                    if useMetricSystem {
                        Text(String(format: "%.1f kg", weight))
                    } else {
                        let weightInPounds = weight * 2.20462
                        Text(String(format: "%.1f lbs", weightInPounds))
                    }
                }
                Slider(
                    value: $weight,
                    in: useMetricSystem ? 40...150 : 88...330, // kg or lbs
                    step: 0.5
                )
            }
        }
        .frame(height: 400) // Adjust height as needed
    }
    
    /// Goal selection grid
    private var goalSelectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                ForEach(LifeCoachAI.GoalCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                    CategorySelectionChip(
                        category: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedGoalCategories.contains(category)
                    ) {
                        toggleGoalCategory(category)
                    }
                }
            }
            .padding()
        }
    }
    
    /// Audio selection grid
    private var audioSelectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                ForEach(LifeCoachAI.AudioCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                    CategorySelectionChip(
                        category: category.displayName,
                        icon: getAudioCategoryIcon(category), // Helper function for icons
                        color: getAudioCategoryColor(category), // Helper function for colors
                        isSelected: selectedAudioCategories.contains(category)
                    ) {
                        toggleAudioCategory(category)
                    }
                }
            }
            .padding()
        }
    }
    
    /// Health permissions toggle
    private var healthPermissionsToggle: some View {
        Toggle("Connect to Apple Health", isOn: $enableHealthKit)
            .padding(.horizontal, 40)
            .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
    }
    
    /// Notification permissions toggle
    private var notificationPermissionsToggle: some View {
        Toggle("Enable Notifications", isOn: $enableNotifications)
            .padding(.horizontal, 40)
            .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
    }
    
    // MARK: - Navigation Buttons
    
    /// Navigation buttons (Back, Next, Finish)
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Back button (if not first step)
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(Color("AccentColor"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("SecondaryBackground"))
                        .cornerRadius(10)
                }
            }
            
            // Next/Finish button
            Button(action: handleNextButton) {
                Text(currentStep == onboardingSteps.count - 1 ? "Finish" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Methods
    
    /// Handle next button tap
    private func handleNextButton() {
        if currentStep < onboardingSteps.count - 1 {
            // Process current step data
            processStepData(stepIndex: currentStep)
            
            // Move to next step
            withAnimation {
                currentStep += 1
            }
        } else {
            // Finish onboarding
            finishOnboarding()
        }
    }
    
    /// Process data for the current step
    private func processStepData(stepIndex: Int) {
        let step = onboardingSteps[stepIndex]
        
        switch step.viewType {
        case .healthPermissions:
            if enableHealthKit {
                healthKitManager.requestAuthorization()
            }
        case .notificationPermissions:
            if enableNotifications {
                notificationManager.requestAuthorization()
            }
        default:
            break
        }
    }
    
    /// Finish onboarding and save user profile
    private func finishOnboarding() {
        // Convert height to cm if in imperial
        let heightInCm = useMetricSystem ? height : height * 2.54
        
        // Convert weight to kg if in imperial
        let weightInKg = useMetricSystem ? weight : weight / 2.20462
        
        // Save user profile
        userProfileManager.createProfile(
            name: name,
            birthDate: birthDate,
            gender: gender.rawValue,
            height: heightInCm,
            weight: weightInKg,
            goalCategories: selectedGoalCategories.map { $0.rawValue },
            audioCategories: selectedAudioCategories.map { $0.rawValue }
        )
        
        // Mark onboarding as complete
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
    
    /// Toggle goal category selection
    private func toggleGoalCategory(_ category: LifeCoachAI.GoalCategory) {
        if selectedGoalCategories.contains(category) {
            selectedGoalCategories.remove(category)
        } else {
            selectedGoalCategories.insert(category)
        }
    }
    
    /// Toggle audio category selection
    private func toggleAudioCategory(_ category: LifeCoachAI.AudioCategory) {
        if selectedAudioCategories.contains(category) {
            selectedAudioCategories.remove(category)
        } else {
            selectedAudioCategories.insert(category)
        }
    }
    
    /// Get icon for audio category
    private func getAudioCategoryIcon(_ category: LifeCoachAI.AudioCategory) -> String {
        switch category {
        case .meditation: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .focus: return "target"
        case .stress: return "wind"
        case .coaching: return "figure.stand.line.dotted.figure.stand"
        case .motivation: return "flame.fill"
        default: return "headphones"
        }
    }
    
    /// Get color for audio category
    private func getAudioCategoryColor(_ category: LifeCoachAI.AudioCategory) -> Color {
        switch category {
        case .meditation: return .blue
        case .sleep: return .purple
        case .focus: return .green
        case .stress: return .orange
        case .coaching: return .red
        case .motivation: return .yellow
        default: return Color("AccentColor")
        }
    }
}

// MARK: - Onboarding Step Model

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let viewType: OnboardingViewType
}

enum OnboardingViewType {
    case welcome
    case personalInfo
    case goalSelection
    case audioSelection
    case healthPermissions
    case notificationPermissions
    case summary
}

// MARK: - Category Selection Chip

struct CategorySelectionChip: View {
    let category: String
    let icon: String
    let color: Color
    var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(category)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(minWidth: 150, minHeight: 150)
            .background(isSelected ? color : Color("SecondaryBackground"))
            .cornerRadius(16)
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasCompletedOnboarding: .constant(false))
            .environmentObject(HealthKitManager())
            .environmentObject(NotificationManager())
            .environmentObject(UserProfileManager())
    }
}
