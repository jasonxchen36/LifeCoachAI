//
//  ProfileView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import CoreData
import HealthKit
import StoreKit

struct ProfileView: View {
    // MARK: - Environment & State
    
    /// Core Data managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Access to environment objects
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var mlManager: MLManager
    
    /// View state
    @State private var isEditingProfile = false
    @State private var showingHealthPermissions = false
    @State private var showingNotificationSettings = false
    @State private var showingPaywall = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var showingFeedbackForm = false
    
    /// Edited profile information
    @State private var editedName = ""
    @State private var editedBirthDate = Date()
    @State private var editedGender = Gender.notSpecified
    @State private var editedHeight = 170.0
    @State private var editedWeight = 70.0
    
    /// App preferences
    @State private var useDarkMode = false
    @State private var useMetricSystem = true
    @State private var enableReminders = true
    @State private var reminderTime = Date()
    @State private var dataCollectionEnabled = true
    
    // MARK: - Computed Properties
    
    /// Current user profile
    private var userProfile: UserProfile? {
        return userProfileManager.userProfile
    }
    
    /// Formatted subscription status
    private var subscriptionStatus: String {
        if storeManager.isPremium {
            if let expirationDate = storeManager.subscriptionExpirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return "Premium (Expires: \(formatter.string(from: expirationDate)))"
            } else {
                return "Premium"
            }
        } else {
            return "Free"
        }
    }
    
    /// Formatted height based on measurement system
    private var formattedHeight: String {
        if useMetricSystem {
            return String(format: "%.0f cm", userProfile?.height ?? 0)
        } else {
            let heightInInches = (userProfile?.height ?? 0) / 2.54
            let feet = Int(heightInInches / 12)
            let inches = Int(heightInInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)' \(inches)\""
        }
    }
    
    /// Formatted weight based on measurement system
    private var formattedWeight: String {
        if useMetricSystem {
            return String(format: "%.1f kg", userProfile?.weight ?? 0)
        } else {
            let weightInPounds = (userProfile?.weight ?? 0) * 2.20462
            return String(format: "%.1f lbs", weightInPounds)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profile header
                profileHeader
                
                // Subscription card
                subscriptionCard
                
                // Settings sections
                Group {
                    // Profile settings
                    settingsSection(title: "Profile", icon: "person.fill") {
                        profileSettingsContent
                    }
                    
                    // Health & Data settings
                    settingsSection(title: "Health & Data", icon: "heart.fill") {
                        healthDataSettingsContent
                    }
                    
                    // App preferences
                    settingsSection(title: "App Preferences", icon: "gear") {
                        appPreferencesContent
                    }
                    
                    // Notifications
                    settingsSection(title: "Notifications", icon: "bell.fill") {
                        notificationSettingsContent
                    }
                    
                    // Support & Legal
                    settingsSection(title: "Support & Legal", icon: "questionmark.circle.fill") {
                        supportLegalContent
                    }
                }
                
                // Account actions
                accountActionsSection
                
                // App version
                Text("LifeCoach AI v1.0.0")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
            .padding(.vertical)
            .background(Color("PrimaryBackground").edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $isEditingProfile) {
            editProfileSheet
        }
        .sheet(isPresented: $showingHealthPermissions) {
            healthPermissionsSheet
        }
        .sheet(isPresented: $showingNotificationSettings) {
            notificationSettingsSheet
        }
        .sheet(isPresented: $showingFeedbackForm) {
            feedbackFormSheet
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingLogoutConfirmation) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out? You will need to sign in again to access your data."),
                primaryButton: .destructive(Text("Log Out")) {
                    logout()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            // Initialize state from user profile
            if let profile = userProfile {
                editedName = profile.name ?? ""
                editedBirthDate = profile.birthDate ?? Date()
                editedGender = Gender(rawValue: profile.gender ?? "") ?? .notSpecified
                editedHeight = profile.height
                editedWeight = profile.weight
            }
            
            // Initialize app preferences
            useDarkMode = UserDefaults.standard.bool(forKey: "useDarkMode")
            useMetricSystem = UserDefaults.standard.bool(forKey: "useMetricSystem")
            enableReminders = UserDefaults.standard.bool(forKey: "enableReminders")
            if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
                reminderTime = savedTime
            }
            dataCollectionEnabled = UserDefaults.standard.bool(forKey: "dataCollectionEnabled")
        }
    }
    
    // MARK: - UI Components
    
    /// Profile header component
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            ZStack {
                Circle()
                    .fill(Color("AccentColor").opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(userProfile?.initials ?? "?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
            }
            
            // User name and status
            VStack(spacing: 4) {
                Text(userProfile?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(subscriptionStatus)
                    .font(.subheadline)
                    .foregroundColor(storeManager.isPremium ? Color.yellow : Color("SecondaryText"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(storeManager.isPremium ? Color.yellow.opacity(0.2) : Color("SecondaryBackground"))
                    .cornerRadius(12)
            }
            
            // Edit profile button
            Button(action: {
                isEditingProfile = true
            }) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .foregroundColor(Color("AccentColor"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color("AccentColor").opacity(0.1))
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Subscription card component
    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: storeManager.isPremium ? "crown.fill" : "crown")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text(storeManager.isPremium ? "Premium Subscription" : "Upgrade to Premium")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
            }
            
            if storeManager.isPremium {
                // Premium subscription details
                VStack(alignment: .leading, spacing: 12) {
                    Text("You're enjoying all premium features!")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    if let expirationDate = storeManager.subscriptionExpirationDate {
                        HStack {
                            Text("Next billing date:")
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                            
                            Spacer()
                            
                            Text(formatDate(expirationDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("PrimaryText"))
                        }
                    }
                    
                    Button(action: {
                        // Open subscription management
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Manage Subscription")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("AccentColor"))
                            .cornerRadius(10)
                    }
                }
            } else {
                // Free tier with upgrade option
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unlock all premium features:")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    ForEach(SubscriptionTier.premium.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                        }
                    }
                    
                    Button(action: {
                        showingPaywall = true
                    }) {
                        Text("Upgrade Now")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Settings section component
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(Color("AccentColor"))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
            }
            
            content()
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Profile settings content
    private var profileSettingsContent: some View {
        VStack(spacing: 16) {
            settingsRow(title: "Name", value: userProfile?.name ?? "Not set")
            
            settingsRow(title: "Age", value: userProfile?.formattedAge ?? "Not set")
            
            settingsRow(title: "Gender", value: userProfile?.formattedGender ?? "Not specified")
            
            settingsRow(title: "Height", value: formattedHeight)
            
            settingsRow(title: "Weight", value: formattedWeight)
        }
    }
    
    /// Health data settings content
    private var healthDataSettingsContent: some View {
        VStack(spacing: 16) {
            settingsRow(
                title: "Health Permissions",
                value: healthKitManager.isHealthKitAuthorized ? "Connected" : "Not Connected",
                valueColor: healthKitManager.isHealthKitAuthorized ? .green : .red,
                hasDisclosure: true
            ) {
                showingHealthPermissions = true
            }
            
            Toggle("Sync Health Data", isOn: $dataCollectionEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                .onChange(of: dataCollectionEnabled) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "dataCollectionEnabled")
                    if newValue {
                        healthKitManager.startHealthKitDataCollection()
                    } else {
                        healthKitManager.stopHealthKitDataCollection()
                    }
                }
            
            settingsRow(
                title: "Last Synced",
                value: formatDate(healthKitManager.lastSyncDate ?? Date())
            )
            
            Button(action: {
                healthKitManager.refreshHealthData()
            }) {
                Text("Sync Now")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
        }
    }
    
    /// App preferences content
    private var appPreferencesContent: some View {
        VStack(spacing: 16) {
            Toggle("Dark Mode", isOn: $useDarkMode)
                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                .onChange(of: useDarkMode) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "useDarkMode")
                    // Apply theme change
                }
            
            Toggle("Use Metric System", isOn: $useMetricSystem)
                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                .onChange(of: useMetricSystem) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "useMetricSystem")
                }
            
            settingsRow(
                title: "Language",
                value: "English",
                hasDisclosure: true
            ) {
                // Show language selection
            }
            
            settingsRow(
                title: "Data Export",
                value: "Export your data",
                hasDisclosure: true
            ) {
                // Show data export options
            }
        }
    }
    
    /// Notification settings content
    private var notificationSettingsContent: some View {
        VStack(spacing: 16) {
            settingsRow(
                title: "Notification Permissions",
                value: notificationManager.isNotificationsAuthorized ? "Enabled" : "Disabled",
                valueColor: notificationManager.isNotificationsAuthorized ? .green : .red,
                hasDisclosure: true
            ) {
                showingNotificationSettings = true
            }
            
            Toggle("Daily Reminders", isOn: $enableReminders)
                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                .onChange(of: enableReminders) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "enableReminders")
                    if newValue {
                        notificationManager.scheduleReminders(at: reminderTime)
                    } else {
                        notificationManager.cancelReminders()
                    }
                }
            
            if enableReminders {
                HStack {
                    Text("Reminder Time")
                        .foregroundColor(Color("PrimaryText"))
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .onChange(of: reminderTime) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "reminderTime")
                        if enableReminders {
                            notificationManager.scheduleReminders(at: newValue)
                        }
                    }
                }
            }
            
            Toggle("Insights & Recommendations", isOn: .constant(true))
                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
            
            Toggle("Goal Updates", isOn: .constant(true))
                .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
        }
    }
    
    /// Support and legal content
    private var supportLegalContent: some View {
        VStack(spacing: 16) {
            settingsRow(
                title: "Help & Support",
                value: "Contact us",
                hasDisclosure: true
            ) {
                // Show help options
            }
            
            settingsRow(
                title: "Send Feedback",
                value: "Tell us what you think",
                hasDisclosure: true
            ) {
                showingFeedbackForm = true
            }
            
            settingsRow(
                title: "Privacy Policy",
                value: "",
                hasDisclosure: true
            ) {
                showingPrivacyPolicy = true
                if let url = URL(string: "https://www.lifecoach.ai/privacy") {
                    UIApplication.shared.open(url)
                }
            }
            
            settingsRow(
                title: "Terms of Service",
                value: "",
                hasDisclosure: true
            ) {
                showingTermsOfService = true
                if let url = URL(string: "https://www.lifecoach.ai/terms") {
                    UIApplication.shared.open(url)
                }
            }
            
            settingsRow(
                title: "App Version",
                value: "1.0.0"
            )
        }
    }
    
    /// Account actions section
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingLogoutConfirmation = true
            }) {
                Text("Log Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Text("Delete Account")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Settings row component
    private func settingsRow(
        title: String,
        value: String,
        valueColor: Color = Color("SecondaryText"),
        hasDisclosure: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(valueColor)
                
                if hasDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(action == nil)
    }
    
    // MARK: - Sheets
    
    /// Edit profile sheet
    private var editProfileSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $editedName)
                    
                    DatePicker(
                        "Birth Date",
                        selection: $editedBirthDate,
                        displayedComponents: .date
                    )
                    
                    Picker("Gender", selection: $editedGender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("Body Measurements")) {
                    HStack {
                        Text("Height")
                        Spacer()
                        if useMetricSystem {
                            Text("\(Int(editedHeight)) cm")
                        } else {
                            let heightInInches = editedHeight / 2.54
                            let feet = Int(heightInInches / 12)
                            let inches = Int(heightInInches.truncatingRemainder(dividingBy: 12))
                            Text("\(feet)' \(inches)\"")
                        }
                    }
                    
                    Slider(
                        value: $editedHeight,
                        in: useMetricSystem ? 120...220 : 48...87,
                        step: 1
                    )
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        if useMetricSystem {
                            Text(String(format: "%.1f kg", editedWeight))
                        } else {
                            let weightInPounds = editedWeight * 2.20462
                            Text(String(format: "%.1f lbs", weightInPounds))
                        }
                    }
                    
                    Slider(
                        value: $editedWeight,
                        in: useMetricSystem ? 40...150 : 88...330,
                        step: 0.5
                    )
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditingProfile = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        isEditingProfile = false
                    }
                }
            }
        }
    }
    
    /// Health permissions sheet
    private var healthPermissionsSheet: some View {
        NavigationView {
            List {
                Section(header: Text("Health Data Access")) {
                    Toggle("Steps", isOn: .constant(healthKitManager.isStepsAuthorized))
                        .disabled(true)
                    
                    Toggle("Heart Rate", isOn: .constant(healthKitManager.isHeartRateAuthorized))
                        .disabled(true)
                    
                    Toggle("Sleep", isOn: .constant(healthKitManager.isSleepAuthorized))
                        .disabled(true)
                    
                    Toggle("Active Energy", isOn: .constant(healthKitManager.isActiveEnergyAuthorized))
                        .disabled(true)
                    
                    Toggle("Weight", isOn: .constant(healthKitManager.isWeightAuthorized))
                        .disabled(true)
                    
                    Toggle("Mindful Minutes", isOn: .constant(healthKitManager.isMindfulMinutesAuthorized))
                        .disabled(true)
                }
                
                Section {
                    Button(action: {
                        healthKitManager.requestAuthorization()
                    }) {
                        Text("Update Permissions")
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Health App Settings")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
                
                Section(header: Text("About Health Data")) {
                    Text("LifeCoach AI uses your health data to provide personalized recommendations and insights. Your data is processed on-device and is never shared with third parties.")
                        .font(.footnote)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .navigationTitle("Health Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingHealthPermissions = false
                    }
                }
            }
        }
    }
    
    /// Notification settings sheet
    private var notificationSettingsSheet: some View {
        NavigationView {
            List {
                Section(header: Text("Notification Types")) {
                    Toggle("Daily Reminders", isOn: $enableReminders)
                        .onChange(of: enableReminders) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "enableReminders")
                            if newValue {
                                notificationManager.scheduleReminders(at: reminderTime)
                            } else {
                                notificationManager.cancelReminders()
                            }
                        }
                    
                    Toggle("Goal Updates", isOn: .constant(true))
                    
                    Toggle("Health Insights", isOn: .constant(true))
                    
                    Toggle("Recommendations", isOn: .constant(true))
                }
                
                Section {
                    Button(action: {
                        notificationManager.requestAuthorization()
                    }) {
                        Text("Request Notification Permissions")
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Notification Settings")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingNotificationSettings = false
                    }
                }
            }
        }
    }
    
    /// Feedback form sheet
    private var feedbackFormSheet: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Your Feedback")) {
                        Picker("Feedback Type", selection: .constant(0)) {
                            Text("Feature Request").tag(0)
                            Text("Bug Report").tag(1)
                            Text("General Feedback").tag(2)
                        }
                        
                        TextField("Subject", text: .constant(""))
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: .constant(""))
                                .frame(minHeight: 150)
                            
                            if true { // Replace with condition to check if text is empty
                                Text("Please describe your feedback in detail...")
                                    .foregroundColor(Color("SecondaryText").opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            // Submit feedback
                            showingFeedbackForm = false
                        }) {
                            Text("Submit Feedback")
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingFeedbackForm = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Save profile changes
    private func saveProfile() {
        userProfileManager.updateProfile(
            name: editedName,
            birthDate: editedBirthDate,
            gender: editedGender.rawValue,
            height: editedHeight,
            weight: editedWeight
        )
    }
    
    /// Delete account
    private func deleteAccount() {
        // Implement account deletion
        userProfileManager.deleteUserProfile()
        storeManager.cancelSubscriptions()
        healthKitManager.stopHealthKitDataCollection()
        notificationManager.cancelAllNotifications()
        
        // Reset app state
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        // Restart app
        exit(0)
    }
    
    /// Log out
    private func logout() {
        // Implement logout
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
        // Reset app state without deleting data
        NotificationCenter.default.post(name: NSNotification.Name("LogoutUser"), object: nil)
    }
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

// Note: Gender enum and related types are defined in DataModels.swift

// MARK: - UserProfile Extensions

// Note: UserProfile extensions are defined in DataModels.swift

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(UserProfileManager())
            .environmentObject(HealthKitManager())
            .environmentObject(NotificationManager())
            .environmentObject(StoreManager())
            .environmentObject(MLManager())
    }
}
