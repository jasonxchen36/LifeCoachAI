//
//  AudioLibraryView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import CoreData
import AVFoundation

struct AudioLibraryView: View {
    // MARK: - Environment & State
    
    /// Core Data managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Audio manager for playback control
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var storeManager: StoreManager
    
    /// View state
    @State private var selectedCategory: AudioCategory = .all
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var sortOption: SortOption = .newest
    @State private var showingSessionDetail: AudioSession? = nil
    
    // MARK: - Computed Properties
    
    /// Filtered audio sessions based on selected category and search text
    private var filteredSessions: [AudioSession] {
        let sessions = audioManager.audioSessions
        
        // Filter by category if not "All"
        let categoryFiltered = selectedCategory == .all ? 
            sessions : 
            sessions.filter { $0.category == selectedCategory.rawValue }
        
        // Filter by search text if not empty
        if searchText.isEmpty {
            return sortSessions(categoryFiltered)
        } else {
            return sortSessions(categoryFiltered.filter { 
                $0.title?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.description?.localizedCaseInsensitiveContains(searchText) == true
            })
        }
    }
    
    /// Recently played sessions
    private var recentlyPlayed: [AudioSession] {
        return audioManager.audioSessions
            .filter { $0.lastPlayedDate != nil }
            .sorted { $0.lastPlayedDate! > $1.lastPlayedDate! }
            .prefix(5)
            .map { $0 }
    }
    
    /// Featured sessions (could be editorially selected or based on user preferences)
    private var featuredSessions: [AudioSession] {
        return audioManager.audioSessions
            .filter { $0.isFeatured }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Helper Methods
    
    /// Sort sessions based on selected sort option
    private func sortSessions(_ sessions: [AudioSession]) -> [AudioSession] {
        switch sortOption {
        case .newest:
            return sessions.sorted { ($0.createdDate ?? Date()) > ($1.createdDate ?? Date()) }
        case .oldest:
            return sessions.sorted { ($0.createdDate ?? Date()) < ($1.createdDate ?? Date()) }
        case .duration:
            return sessions.sorted { ($0.duration) < ($1.duration) }
        case .alphabetical:
            return sessions.sorted { ($0.title ?? "") < ($1.title ?? "") }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Search bar
                searchBar
                
                // Category filter
                categoryFilter
                
                // Now playing (if applicable)
                if audioManager.isPlaying, let currentSession = audioManager.currentSession {
                    nowPlayingCard(session: currentSession)
                }
                
                // Featured sessions
                if !featuredSessions.isEmpty {
                    sectionHeader(title: "Featured", subtitle: "Editor's picks")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(featuredSessions) { session in
                                featuredSessionCard(session: session)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recently played
                if !recentlyPlayed.isEmpty {
                    sectionHeader(title: "Recently Played", subtitle: "Continue where you left off")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(recentlyPlayed) { session in
                                recentSessionCard(session: session)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // All sessions (filtered)
                sectionHeader(
                    title: selectedCategory == .all ? "All Sessions" : selectedCategory.displayName,
                    subtitle: "\(filteredSessions.count) sessions"
                )
                
                // Sort options
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // List of sessions
                if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSessions) { session in
                            audioSessionRow(session: session)
                                .onTapGesture {
                                    showingSessionDetail = session
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color("PrimaryBackground").edgesIgnoringSafeArea(.all))
        .sheet(item: $showingSessionDetail) { session in
            AudioSessionDetailView(session: session)
                .environmentObject(audioManager)
        }
    }
    
    // MARK: - UI Components
    
    /// Search bar component
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search audio sessions", text: $searchText)
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
    
    /// Category filter component
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AudioCategory.allCases, id: \.self) { category in
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
    
    /// Now playing card component
    private func nowPlayingCard(session: AudioSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Now Playing")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    audioManager.stopPlayback()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            HStack(spacing: 16) {
                Image(session.imageName ?? "default_audio")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title ?? "Unknown Session")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(session.categoryName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            // Progress bar
            VStack(spacing: 4) {
                Slider(value: $audioManager.currentProgress, in: 0...1) { editing in
                    if !editing {
                        audioManager.seekToProgress(audioManager.currentProgress)
                    }
                }
                .accentColor(.white)
                
                HStack {
                    Text(formatTime(audioManager.currentTime))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(formatTime(audioManager.duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Playback controls
            HStack {
                Spacer()
                
                Button(action: {
                    audioManager.skipBackward()
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    if audioManager.isPlaying {
                        audioManager.pausePlayback()
                    } else {
                        audioManager.resumePlayback()
                    }
                }) {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    audioManager.skipForward()
                }) {
                    Image(systemName: "goforward.30")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
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
    
    /// Featured session card component
    private func featuredSessionCard(session: AudioSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(session.imageName ?? "default_audio")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 120)
                    .cornerRadius(12)
                
                if storeManager.isPremium || !session.isPremium {
                    Button(action: {
                        audioManager.startPlayback(session: session)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(8)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title ?? "Unknown Session")
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(session.categoryName)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text(formatTime(session.duration))
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        }
        .frame(width: 200)
        .onTapGesture {
            if storeManager.isPremium || !session.isPremium {
                showingSessionDetail = session
            }
        }
    }
    
    /// Recent session card component
    private func recentSessionCard(session: AudioSession) -> some View {
        HStack(spacing: 12) {
            Image(session.imageName ?? "default_audio")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title ?? "Unknown Session")
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(session.categoryName)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text(formatTime(session.duration))
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            
            Spacer()
            
            Button(action: {
                audioManager.startPlayback(session: session)
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("AccentColor"))
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
        .frame(width: 300)
    }
    
    /// Audio session row component
    private func audioSessionRow(session: AudioSession) -> some View {
        HStack(spacing: 16) {
            Image(session.imageName ?? "default_audio")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.title ?? "Unknown Session")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Spacer()
                    
                    if session.isPremium && !storeManager.isPremium {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
                
                Text(session.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .lineLimit(2)
                
                HStack {
                    Label(session.categoryName, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Spacer()
                    
                    Label(formatTime(session.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(12)
    }
    
    /// Empty state view when no sessions match filters
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(Color("AccentColor").opacity(0.6))
            
            Text("No audio sessions found")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
            
            Button(action: {
                selectedCategory = .all
                searchText = ""
            }) {
                Text("Clear Filters")
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
    
    /// Format seconds to MM:SS or HH:MM:SS
    private func formatTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}

// MARK: - Audio Session Detail View

struct AudioSessionDetailView: View {
    let session: AudioSession
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header image
                ZStack(alignment: .bottomLeading) {
                    Image(session.imageName ?? "default_audio")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title ?? "Unknown Session")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            Label(session.categoryName, systemImage: "tag")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Label(formatTime(session.duration), systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding()
                }
                
                // Description
                VStack(alignment: .leading, spacing: 16) {
                    Text("About this session")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(session.description ?? "No description available.")
                        .font(.body)
                        .foregroundColor(Color("SecondaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                // Benefits
                if let benefits = session.benefits, !benefits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("AccentColor"))
                                
                                Text(benefit)
                                    .font(.body)
                                    .foregroundColor(Color("SecondaryText"))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Related sessions
                if !relatedSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You might also like")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(relatedSessions) { relatedSession in
                                    relatedSessionCard(session: relatedSession)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color("PrimaryBackground"))
        .overlay(
            VStack {
                Spacer()
                
                // Play button
                if session.isPremium && !storeManager.isPremium {
                    premiumButton
                } else {
                    playButton
                }
            }
        )
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add to favorites or share
                }) {
                    Image(systemName: "heart")
                        .foregroundColor(Color("AccentColor"))
                }
            }
        }
    }
    
    /// Related sessions based on category
    private var relatedSessions: [AudioSession] {
        return audioManager.audioSessions
            .filter { $0.id != session.id && $0.category == session.category }
            .prefix(5)
            .map { $0 }
    }
    
    /// Play button for starting playback
    private var playButton: some View {
        Button(action: {
            audioManager.startPlayback(session: session)
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.headline)
                
                Text("Play Session")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(Color("AccentColor"))
            .cornerRadius(28)
            .padding()
            .shadow(radius: 5)
        }
    }
    
    /// Premium button for locked content
    private var premiumButton: some View {
        Button(action: {
            // Show paywall
        }) {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.headline)
                
                Text("Unlock Premium Content")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
            .padding()
            .shadow(radius: 5)
        }
    }
    
    /// Related session card component
    private func relatedSessionCard(session: AudioSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(session.imageName ?? "default_audio")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 100)
                .cornerRadius(8)
            
            Text(session.title ?? "Unknown Session")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(Color("PrimaryText"))
            
            Text(formatTime(session.duration))
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(width: 140)
        .onTapGesture {
            if storeManager.isPremium || !session.isPremium {
                audioManager.startPlayback(session: session)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    /// Format seconds to MM:SS or HH:MM:SS
    private func formatTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}

// MARK: - Supporting Types

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

/// Sort options
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

// MARK: - Preview
struct AudioLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        AudioLibraryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AudioManager())
            .environmentObject(StoreManager())
    }
}
