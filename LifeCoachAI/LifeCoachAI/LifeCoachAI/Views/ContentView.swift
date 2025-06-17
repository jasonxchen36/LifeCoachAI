//
//  ContentView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import HealthKit
import AVFoundation

struct ContentView: View {
    // MARK: - Environment & State
    
    /// Access to environment objects from app
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var mlManager: MLManager
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var userProfileManager: UserProfileManager
    
    /// App state
    @State private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var showPaywall = false
    @State private var showHealthKitPermission = false
    @State private var showNotificationPermission = false
    @State private var showWelcomeBack = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    /// Animation states
    @State private var animateBackground = false
    @State private var animateLogo = false
    
    /// Helper to detect simulator (to skip onboarding automatically)
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif
    
    // MARK: - Initialization
    
    /// Initialize managers with Core Data context
    private func initializeManagers() {
        // Check onboarding status
        hasCompletedOnboarding = userProfileManager.hasCompletedOnboarding
        
        // In the simulator we always want to jump straight to the main UI so that
        // developers can see the full dashboard without doing the onboarding flow.
        if isSimulator { hasCompletedOnboarding = true }
        
        // Finish loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                isLoading = false
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Loading screen
            if isLoading {
                splashScreen
            }
            // Error screen
            else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            }
            // Onboarding flow
            else if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(healthKitManager)
                    .environmentObject(notificationManager)
                    .environmentObject(userProfileManager)
                    .transition(.opacity)
            }
            // Main app interface
            else {
                mainAppInterface
                    .transition(.opacity)
            }
            
            // Overlays
            if showHealthKitPermission {
                HealthKitPermissionView(isPresented: $showHealthKitPermission)
                    .environmentObject(healthKitManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showNotificationPermission {
                NotificationPermissionView(isPresented: $showNotificationPermission)
                    .environmentObject(notificationManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showPaywall {
                PaywallView(isPresented: $showPaywall)
                    .environmentObject(storeManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showWelcomeBack {
                WelcomeBackView(isPresented: $showWelcomeBack)
                    .environmentObject(userProfileManager)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            initializeManagers()
        }
        .onChange(of: hasCompletedOnboarding) { newValue in
            if newValue {
                // User just completed onboarding
                withAnimation {
                    showWelcomeBack = true
                }
                
                // Check if we need to show permission screens
                if !healthKitManager.isHealthKitAuthorized {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            showHealthKitPermission = true
                        }
                    }
                }
                
                if !notificationManager.isNotificationsAuthorized && !notificationManager.hasRequestedPermission {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (showHealthKitPermission ? 3 : 1)) {
                        withAnimation {
                            showNotificationPermission = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Splash Screen
    
    /// Splash screen shown during app loading
    private var splashScreen: some View {
        ZStack {
            // Animated background
            Color("PrimaryBackground")
                .scaleEffect(animateBackground ? 1.1 : 1.0)
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateBackground)
                .onAppear {
                    animateBackground = true
                }
            
            VStack {
                // App logo
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateLogo ? 1.1 : 1.0)
                    .opacity(animateLogo ? 1.0 : 0.8)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateLogo)
                    .onAppear {
                        animateLogo = true
                    }
                
                Text("LifeCoach AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
                    .padding(.top, 16)
                
                Text("Your Personal Wellness Guide")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .padding(.top, 4)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentColor")))
                    .scaleEffect(1.5)
                    .padding(.top, 40)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Error View
    
    /// View shown when there's an error
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                // Retry initialization
                errorMessage = nil
                isLoading = true
                initializeManagers()
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Main App Interface
    
    /// Main app interface with tab navigation
    private var mainAppInterface: some View {
        TabView(selection: $selectedTab) {
            // Home/Dashboard Tab
            NavigationView {
                DashboardView()
                    .navigationTitle("Today")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                withAnimation {
                                    showPaywall = !storeManager.isPremium
                                }
                            }) {
                                Image(systemName: storeManager.isPremium ? "crown.fill" : "crown")
                                    .foregroundColor(storeManager.isPremium ? .yellow : Color("AccentColor"))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Today", systemImage: "house.fill")
            }
            .tag(0)
            
            // Audio Sessions Tab
            NavigationView {
                AudioLibraryView()
                    .navigationTitle("Audio")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Audio", systemImage: "headphones")
            }
            .tag(1)
            
            // Goals Tab
            NavigationView {
                GoalsView()
                    .navigationTitle("Goals")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(2)
            
            // Insights Tab
            NavigationView {
                InsightsView()
                    .navigationTitle("Insights")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(3)
            
            // Profile Tab
            NavigationView {
                ProfileView()
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(Color("AccentColor"))
        .onAppear {
            // Set tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color("SecondaryBackground"))
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

// MARK: - Permission Views

/// View for requesting HealthKit permissions
struct HealthKitPermissionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var healthKitManager: HealthKitManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color("AccentColor"))
                
                Text("Health Data Access")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("LifeCoach AI needs access to your health data to provide personalized recommendations and track your progress.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Not Now")
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("SecondaryBackground"))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        healthKitManager.requestAuthorization()
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Allow Access")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("AccentColor"))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Color("PrimaryBackground"))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
    }
}

/// View for requesting notification permissions
struct NotificationPermissionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var notificationManager: NotificationManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color("AccentColor"))
                
                Text("Stay Updated")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enable notifications to receive timely reminders, personalized recommendations, and important health insights.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Not Now")
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("SecondaryBackground"))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        notificationManager.requestAuthorization()
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Enable")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("AccentColor"))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Color("PrimaryBackground"))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
    }
}

/// View for displaying paywall
struct PaywallView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var storeManager: StoreManager
    @State private var selectedPlan = 1 // 0: Monthly, 1: Annual
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image("PremiumIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("Upgrade to Premium")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unlock all features and take your wellness journey to the next level")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(SubscriptionTier.premium.features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Plan selection
                VStack(spacing: 12) {
                    Text("Choose Your Plan")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    HStack(spacing: 12) {
                        // Monthly plan
                        VStack {
                            Text("Monthly")
                                .font(.headline)
                            
                            Text("$\(SubscriptionTier.premium.monthlyPrice, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("per month")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedPlan == 0 ? Color("AccentColor").opacity(0.2) : Color("SecondaryBackground"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedPlan == 0 ? Color("AccentColor") : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedPlan = 0
                            }
                        }
                        
                        // Annual plan
                        VStack {
                            Text("Annual")
                                .font(.headline)
                            
                            Text("$\(SubscriptionTier.premium.yearlyPrice, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("per year")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Save 17%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedPlan == 1 ? Color("AccentColor").opacity(0.2) : Color("SecondaryBackground"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedPlan == 1 ? Color("AccentColor") : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedPlan = 1
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Subscribe button
                Button(action: {
                    // Purchase subscription
                    let productId = selectedPlan == 0 ? 
                        "com.lifecoach.ai.premium.monthly" : 
                        "com.lifecoach.ai.premium.yearly"
                    
                    storeManager.purchaseProduct(productId: productId)
                    
                    // Close paywall after purchase attempt
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Subscribe Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor"))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                // Terms and restore
                VStack(spacing: 16) {
                    Text("Auto-renewable subscription. Cancel anytime.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        storeManager.restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            // Open terms of service
                        }) {
                            Text("Terms of Service")
                                .font(.caption)
                                .foregroundColor(Color("AccentColor"))
                        }
                        
                        Button(action: {
                            // Open privacy policy
                        }) {
                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Close button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Continue with Free Version")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 30)
            }
            .background(Color("PrimaryBackground"))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 16)
            .frame(maxHeight: 650)
        }
    }
}

/// Welcome back view shown after onboarding
struct WelcomeBackView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var userProfileManager: UserProfileManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "hand.wave.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color("AccentColor"))
                
                Text("Welcome to LifeCoach AI!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your personal wellness journey starts now. We're excited to help you achieve your health and wellness goals.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor"))
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Color("PrimaryBackground"))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Placeholder Views

// The real implementations of DashboardView, AudioLibraryView, GoalsView,
// InsightsView and ProfileView live in their own files. The placeholders were
// masking them and have been removed.

// NOTE:
// Make sure the dedicated view files are included in the target so the app
// compiles successfully.

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HealthKitManager())
            .environmentObject(NotificationManager())
            .environmentObject(AudioManager())
            .environmentObject(MLManager())
            .environmentObject(StoreManager())
            .environmentObject(UserProfileManager())
    }
}
