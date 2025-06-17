//
//  OnboardingView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import HealthKit
<<<<<<< HEAD
import UserNotifications

struct OnboardingView: View {
    // MARK: - Environment & Bindings
    
    /// Environment objects for accessing managers
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    /// Binding to track onboarding completion
    @Binding var hasCompletedOnboarding: Bool
    
    // MARK: - State Variables
    
    /// Current step in the onboarding process
    @State private var currentStep = 0
    
    /// Personal information
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var gender = "Prefer not to say"
    @State private var height = 170.0
    @State private var weight = 70.0
    
    /// Selected goals and preferences
    @State private var selectedGoalCategories: Set<GoalCategory> = []
    @State private var selectedAudioCategories: Set<AudioCategory> = []
    @State private var initialGoals: [String: Double] = [:]
    
    /// Permission states
    @State private var healthKitPermissionGranted = false
    @State private var notificationPermissionGranted = false
    
    /// Animation states
    @State private var animateTransition = false
    @State private var showConfetti = false
    
    // MARK: - Constants
    
    /// Total number of onboarding steps
    private let totalSteps = 6
    
    /// Gender options
    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
=======

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
>>>>>>> 510ee9d (more changes')
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color("PrimaryBackground")
                .edgesIgnoringSafeArea(.all)
            
<<<<<<< HEAD
            // Content
            VStack {
                // Progress indicator
                ProgressBar(value: Double(currentStep) / Double(totalSteps - 1))
                    .frame(height: 6)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Step content
                ZStack {
                    // Welcome step
                    if currentStep == 0 {
                        welcomeStep
                            .transition(transition(for: 0))
                            .opacity(currentStep == 0 ? 1 : 0)
                    }
                    
                    // Personal info step
                    if currentStep == 1 {
                        personalInfoStep
                            .transition(transition(for: 1))
                            .opacity(currentStep == 1 ? 1 : 0)
                    }
                    
                    // Goals step
                    if currentStep == 2 {
                        goalsStep
                            .transition(transition(for: 2))
                            .opacity(currentStep == 2 ? 1 : 0)
                    }
                    
                    // Audio preferences step
                    if currentStep == 3 {
                        audioPreferencesStep
                            .transition(transition(for: 3))
                            .opacity(currentStep == 3 ? 1 : 0)
                    }
                    
                    // HealthKit permission step
                    if currentStep == 4 {
                        healthKitPermissionStep
                            .transition(transition(for: 4))
                            .opacity(currentStep == 4 ? 1 : 0)
                    }
                    
                    // Notification permission step
                    if currentStep == 5 {
                        notificationPermissionStep
                            .transition(transition(for: 5))
                            .opacity(currentStep == 5 ? 1 : 0)
                    }
                }
                .animation(.easeInOut, value: currentStep)
                .padding()
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
                    .padding()
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: currentStep) { newStep in
            // Update progress in user profile manager
            userProfileManager.updateOnboardingProgress(step: newStep, totalSteps: totalSteps)
            
            // Animate transition
            withAnimation {
                animateTransition = true
            }
            
            // Reset animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateTransition = false
            }
            
            // Show confetti on final step
            if newStep == totalSteps - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showConfetti = true
                    }
                }
            }
=======
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
>>>>>>> 510ee9d (more changes')
        }
    }
    
    // MARK: - Step Views
    
<<<<<<< HEAD
    /// Welcome step
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App logo
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding()
            
            // Welcome text
            Text("Welcome to LifeCoach AI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your personal AI coach for a healthier and more balanced life.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Features list
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "brain.head.profile", title: "AI-Powered Insights", description: "Personalized recommendations based on your data")
                FeatureRow(icon: "heart.text.square", title: "Health Integration", description: "Connects with Apple Health for deeper insights")
                FeatureRow(icon: "headphones", title: "Audio Guidance", description: "Guided meditations and coaching sessions")
                FeatureRow(icon: "chart.bar.fill", title: "Progress Tracking", description: "Track your goals and build healthy habits")
            }
            .padding()
            
            Spacer()
        }
    }
    
    /// Personal information step
    private var personalInfoStep: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Tell us about yourself")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("This information helps us personalize your experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Name fields
                VStack(alignment: .leading, spacing: 5) {
                    Text("First Name")
                        .font(.headline)
                    
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Last Name")
                        .font(.headline)
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                // Birth date picker
                VStack(alignment: .leading, spacing: 5) {
                    Text("Birth Date")
                        .font(.headline)
                    
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxHeight: 150)
                }
                
                // Gender picker
                VStack(alignment: .leading, spacing: 5) {
                    Text("Gender")
                        .font(.headline)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Height slider
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Height")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(height)) cm")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $height, in: 120...220, step: 1)
                }
                
                // Weight slider
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Weight")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(weight)) kg")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $weight, in: 30...150, step: 1)
                }
                
                Text("You can always update this information later in your profile")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
        }
    }
    
    /// Goals selection step
    private var goalsStep: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("What are your goals?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select the areas you'd like to focus on")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Goal categories
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(GoalCategory.allCases) { category in
                        GoalCategoryCard(
                            category: category,
                            isSelected: selectedGoalCategories.contains(category),
                            action: {
                                toggleGoalCategory(category)
                            }
                        )
                    }
                }
                
                // Initial goals setup
                if !selectedGoalCategories.isEmpty {
                    Text("Set your initial goals")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(spacing: 20) {
                        if selectedGoalCategories.contains(.physical) {
                            GoalSlider(
                                title: "Daily Steps",
                                value: Binding(
                                    get: { initialGoals["steps"] ?? 10000 },
                                    set: { initialGoals["steps"] = $0 }
                                ),
                                range: 5000...20000,
                                step: 500,
                                unit: "steps"
                            )
                        }
                        
                        if selectedGoalCategories.contains(.sleep) {
                            GoalSlider(
                                title: "Sleep Duration",
                                value: Binding(
                                    get: { initialGoals["sleep"] ?? 8 },
                                    set: { initialGoals["sleep"] = $0 }
                                ),
                                range: 5...10,
                                step: 0.5,
                                unit: "hours"
                            )
                        }
                        
                        if selectedGoalCategories.contains(.mindfulness) {
                            GoalSlider(
                                title: "Mindfulness",
                                value: Binding(
                                    get: { initialGoals["mindfulness"] ?? 10 },
                                    set: { initialGoals["mindfulness"] = $0 }
                                ),
                                range: 5...30,
                                step: 5,
                                unit: "min/day"
                            )
                        }
                        
                        if selectedGoalCategories.contains(.nutrition) {
                            GoalSlider(
                                title: "Water Intake",
                                value: Binding(
                                    get: { initialGoals["water"] ?? 2000 },
                                    set: { initialGoals["water"] = $0 }
                                ),
                                range: 1000...3000,
                                step: 100,
                                unit: "ml"
                            )
                        }
                    }
                }
                
                Text("You'll be able to add more goals and customize these later")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
=======
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
>>>>>>> 510ee9d (more changes')
            }
            .padding()
        }
    }
    
<<<<<<< HEAD
    /// Audio preferences step
    private var audioPreferencesStep: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Audio Preferences")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select the types of audio content you're interested in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Audio categories
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(AudioCategory.allCases) { category in
                        AudioCategoryCard(
                            category: category,
                            isSelected: selectedAudioCategories.contains(category),
                            action: {
                                toggleAudioCategory(category)
                            }
                        )
                    }
                }
                
                // Audio sample
                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio Sample")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "headphones")
                            .font(.largeTitle)
                            .foregroundColor(Color("AccentColor"))
                        
                        VStack(alignment: .leading) {
                            Text("Morning Meditation")
                                .font(.headline)
                            Text("0:30 sample")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Play sample audio
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                    .padding()
                    .background(Color("SecondaryBackground"))
                    .cornerRadius(12)
                }
                .padding(.top)
                
                Text("You'll be able to explore our full audio library after setup")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
=======
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
>>>>>>> 510ee9d (more changes')
            }
            .padding()
        }
    }
    
<<<<<<< HEAD
    /// HealthKit permission step
    private var healthKitPermissionStep: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AccentColor"))
                .padding()
            
            Text("Connect Health Data")
                .font(.title)
                .fontWeight(.bold)
            
            Text("LifeCoach AI works best with your health data. We'll use this information to provide personalized recommendations and track your progress.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Health metrics list
            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "figure.walk", title: "Steps & Activity", description: "Track your daily movement")
                PermissionRow(icon: "heart.fill", title: "Heart Rate", description: "Monitor your heart health")
                PermissionRow(icon: "bed.double.fill", title: "Sleep", description: "Analyze your sleep patterns")
                PermissionRow(icon: "leaf.fill", title: "Mindfulness", description: "Record your mindful minutes")
            }
            .padding()
            
            // Permission button
            Button(action: {
                requestHealthKitPermission()
            }) {
                Text(healthKitPermissionGranted ? "Connected" : "Connect Health Data")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(healthKitPermissionGranted ? Color.green : Color("AccentColor"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(healthKitPermissionGranted)
            
            Button(action: {
                // Skip for now
                healthKitPermissionGranted = false
                goToNextStep()
            }) {
                Text("Skip for now")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 5)
            
            Spacer()
        }
        .padding()
    }
    
    /// Notification permission step
    private var notificationPermissionStep: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AccentColor"))
                .padding()
            
            Text("Stay Updated")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Enable notifications to receive timely reminders, personalized recommendations, and important health insights.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Notification types list
            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "target", title: "Goal Reminders", description: "Stay on track with your goals")
                PermissionRow(icon: "lightbulb.fill", title: "Smart Insights", description: "Get personalized recommendations")
                PermissionRow(icon: "flame.fill", title: "Streak Updates", description: "Keep your momentum going")
                PermissionRow(icon: "trophy.fill", title: "Achievement Alerts", description: "Celebrate your successes")
            }
            .padding()
            
            // Permission button
            Button(action: {
                requestNotificationPermission()
            }) {
                Text(notificationPermissionGranted ? "Notifications Enabled" : "Enable Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(notificationPermissionGranted ? Color.green : Color("AccentColor"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(notificationPermissionGranted)
            
            Button(action: {
                // Skip for now
                notificationPermissionGranted = false
                goToNextStep()
            }) {
                Text("Skip for now")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 5)
            
            Spacer()
        }
        .padding()
=======
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
>>>>>>> 510ee9d (more changes')
    }
    
    // MARK: - Navigation Buttons
    
<<<<<<< HEAD
    /// Navigation buttons view
    private var navigationButtons: some View {
        HStack {
            // Back button
            if currentStep > 0 {
                Button(action: goToPreviousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                    .foregroundColor(Color("AccentColor"))
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next/Continue button
            Button(action: {
                if currentStep == totalSteps - 1 {
                    completeOnboarding()
                } else {
                    goToNextStep()
                }
            }) {
                HStack {
                    Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                    
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                .foregroundColor(.white)
                .background(Color("AccentColor"))
                .cornerRadius(10)
            }
            .disabled(isNextButtonDisabled)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    
    /// Feature row view
    private struct FeatureRow: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    /// Permission row view
    private struct PermissionRow: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    /// Goal category card view
    private struct GoalCategoryCard: View {
        let category: GoalCategory
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 30))
                        .foregroundColor(isSelected ? .white : category.color)
                    
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? category.color : Color("SecondaryBackground"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(category.color, lineWidth: isSelected ? 0 : 2)
                )
            }
        }
    }
    
    /// Audio category card view
    private struct AudioCategoryCard: View {
        let category: AudioCategory
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 30))
                        .foregroundColor(isSelected ? .white : category.color)
                    
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? category.color : Color("SecondaryBackground"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(category.color, lineWidth: isSelected ? 0 : 2)
                )
            }
        }
    }
    
    /// Goal slider view
    private struct GoalSlider: View {
        let title: String
        @Binding var value: Double
        let range: ClosedRange<Double>
        let step: Double
        let unit: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(Int(value)) \(unit)")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $value, in: range, step: step)
            }
        }
    }
    
    /// Progress bar view
    private struct ProgressBar: View {
        var value: Double
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(0.3)
                        .foregroundColor(Color("AccentColor").opacity(0.3))
                        .cornerRadius(45)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color("AccentColor"))
                        .cornerRadius(45)
                        .animation(.easeInOut, value: value)
                }
            }
        }
    }
    
    /// Confetti view for celebration
    private struct ConfettiView: View {
        @State private var isAnimating = false
        
        var body: some View {
            ZStack {
                ForEach(0..<50) { i in
                    Circle()
                        .fill(Color.random)
                        .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: isAnimating ? UIScreen.main.bounds.height + 100 : -100
                        )
                        .animation(
                            Animation.linear(duration: CGFloat.random(in: 2...4))
                                .repeatForever(autoreverses: false)
                                .delay(CGFloat.random(in: 0...2)),
                            value: isAnimating
                        )
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
=======
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
>>>>>>> 510ee9d (more changes')
    }
    
    // MARK: - Helper Methods
    
<<<<<<< HEAD
    /// Check if next button should be disabled
    private var isNextButtonDisabled: Bool {
        switch currentStep {
        case 0:
            return false
        case 1:
            return firstName.isEmpty
        case 2:
            return selectedGoalCategories.isEmpty
        case 3:
            return selectedAudioCategories.isEmpty
        case 4, 5:
            return false
        default:
            return false
        }
    }
    
    /// Go to next step
    private func goToNextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    /// Go to previous step
    private func goToPreviousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
=======
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
        userProfileManager.updateUserProfile(
            firstName: name,
            birthDate: birthDate,
            gender: gender.rawValue,
            height: heightInCm,
            weight: weightInKg
        )
        
        // Mark onboarding as complete
        withAnimation {
            hasCompletedOnboarding = true
>>>>>>> 510ee9d (more changes')
        }
    }
    
    /// Toggle goal category selection
<<<<<<< HEAD
    private func toggleGoalCategory(_ category: GoalCategory) {
=======
    private func toggleGoalCategory(_ category: LifeCoachAI.GoalCategory) {
>>>>>>> 510ee9d (more changes')
        if selectedGoalCategories.contains(category) {
            selectedGoalCategories.remove(category)
        } else {
            selectedGoalCategories.insert(category)
<<<<<<< HEAD
            
            // Set default goal values if not already set
            switch category {
            case .physical:
                if initialGoals["steps"] == nil {
                    initialGoals["steps"] = 10000
                }
            case .sleep:
                if initialGoals["sleep"] == nil {
                    initialGoals["sleep"] = 8
                }
            case .mindfulness:
                if initialGoals["mindfulness"] == nil {
                    initialGoals["mindfulness"] = 10
                }
            case .nutrition:
                if initialGoals["water"] == nil {
                    initialGoals["water"] = 2000
                }
            default:
                break
            }
=======
>>>>>>> 510ee9d (more changes')
        }
    }
    
    /// Toggle audio category selection
<<<<<<< HEAD
    private func toggleAudioCategory(_ category: AudioCategory) {
=======
    private func toggleAudioCategory(_ category: LifeCoachAI.AudioCategory) {
>>>>>>> 510ee9d (more changes')
        if selectedAudioCategories.contains(category) {
            selectedAudioCategories.remove(category)
        } else {
            selectedAudioCategories.insert(category)
        }
    }
    
<<<<<<< HEAD
    /// Request HealthKit permission
    private func requestHealthKitPermission() {
        healthKitManager.requestAuthorization()
        
        // In a real app, we would check the actual authorization status
        // For now, we'll just assume it was granted after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                healthKitPermissionGranted = true
            }
            
            // Automatically go to next step after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                goToNextStep()
            }
        }
    }
    
    /// Request notification permission
    private func requestNotificationPermission() {
        notificationManager.requestAuthorization()
        
        // In a real app, we would check the actual authorization status
        // For now, we'll just assume it was granted after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                notificationPermissionGranted = true
            }
            
            // Automatically go to next step after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                goToNextStep()
            }
        }
    }
    
    /// Complete the onboarding process
    private func completeOnboarding() {
        // Save user profile information
        userProfileManager.updateUserProfile(
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            gender: gender,
            height: height,
            weight: weight
        )
        
        // Set preferred categories
        userProfileManager.setPreferredCategories(Array(selectedGoalCategories))
        userProfileManager.setPreferredAudioCategories(Array(selectedAudioCategories))
        
        // Create initial goals
        createInitialGoals()
        
        // Mark onboarding as complete
        userProfileManager.completeOnboarding()
        
        // Update binding
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
    
    /// Create initial goals based on user selections
    private func createInitialGoals() {
        // Create step goal
        if let steps = initialGoals["steps"] {
            userProfileManager.createGoal(
                title: "Daily Steps",
                category: .physical,
                targetValue: steps,
                unit: "steps",
                frequency: .daily
            )
        }
        
        // Create sleep goal
        if let sleep = initialGoals["sleep"] {
            userProfileManager.createGoal(
                title: "Sleep Duration",
                category: .sleep,
                targetValue: sleep,
                unit: "hours",
                frequency: .daily
            )
        }
        
        // Create mindfulness goal
        if let mindfulness = initialGoals["mindfulness"] {
            userProfileManager.createGoal(
                title: "Mindfulness Practice",
                category: .mindfulness,
                targetValue: mindfulness,
                unit: "min",
                frequency: .daily
            )
        }
        
        // Create water intake goal
        if let water = initialGoals["water"] {
            userProfileManager.createGoal(
                title: "Water Intake",
                category: .nutrition,
                targetValue: water,
                unit: "ml",
                frequency: .daily
            )
        }
    }
    
    /// Get transition for a specific step
    private func transition(for step: Int) -> AnyTransition {
        if step < currentStep {
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        } else {
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
=======
    /// Get icon for audio category
    private func getAudioCategoryIcon(_ category: LifeCoachAI.AudioCategory) -> String {
        switch category {
        case .meditation: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        case .focus: return "target"
        case .relaxation: return "wind"
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
        case .relaxation: return .orange
        case .coaching: return .red
        case .motivation: return .yellow
        default: return Color("AccentColor")
>>>>>>> 510ee9d (more changes')
        }
    }
}

<<<<<<< HEAD
// MARK: - Extensions

extension Color {
    /// Generate a random color
    static var random: Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors.randomElement() ?? .blue
=======
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
>>>>>>> 510ee9d (more changes')
    }
}

// MARK: - Preview
<<<<<<< HEAD
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasCompletedOnboarding: .constant(false))
            .environmentObject(UserProfileManager())
            .environmentObject(HealthKitManager())
            .environmentObject(NotificationManager())
=======

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(hasCompletedOnboarding: .constant(false))
            .environmentObject(HealthKitManager())
            .environmentObject(NotificationManager())
            .environmentObject(UserProfileManager())
>>>>>>> 510ee9d (more changes')
    }
}
