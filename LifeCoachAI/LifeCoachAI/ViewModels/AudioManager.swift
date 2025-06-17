//
//  AudioManager.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import Foundation
import AVFoundation
import SwiftUI
import CoreData
import Combine
import MediaPlayer
import os.log

/// Manager class for handling all audio playback and session management
class AudioManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Current playback state
    @Published var isPlaying = false
    
    /// Current audio session
    @Published var currentSession: AudioSession?
    
    /// Current playback progress (0.0 to 1.0)
    @Published var playbackProgress: Double = 0.0
    
    /// Current playback time in seconds
    @Published var currentTime: TimeInterval = 0
    
    /// Total duration of current audio in seconds
    @Published var duration: TimeInterval = 0
    
    /// Whether audio is loading
    @Published var isLoading = false
    
    /// Error message if playback fails
    @Published var errorMessage: String?
    
    /// Whether audio is buffering
    @Published var isBuffering = false
    
    /// Volume level (0.0 to 1.0)
    @Published var volume: Float = 0.8
    
    /// Whether audio is muted
    @Published var isMuted = false
    
    /// Whether repeat mode is enabled
    @Published var isRepeatEnabled = false
    
    /// Available audio sessions
    @Published var availableSessions: [AudioSession] = []
    
    /// Recently played sessions
    @Published var recentlyPlayedSessions: [AudioSession] = []
    
    /// Recommended sessions
    @Published var recommendedSessions: [AudioSession] = []
    
    /// Completed sessions count
    @Published var completedSessionsCount = 0
    
    /// Total listening time in minutes
    @Published var totalListeningTime: TimeInterval = 0
    
    // MARK: - Private Properties
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.lifecoach.ai", category: "AudioManager")
    
    /// Audio player
    private var audioPlayer: AVPlayer?
    
    /// Audio player item
    private var playerItem: AVPlayerItem?
    
    /// Time observer token for tracking playback progress
    private var timeObserverToken: Any?
    
    /// Timer for updating playback progress
    private var progressUpdateTimer: Timer?
    
    /// Core Data context for persisting session data
    private var viewContext: NSManagedObjectContext?
    
    /// Speech synthesizer for text-to-speech
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// Current speech utterance
    private var currentUtterance: AVSpeechUtterance?
    
    /// Audio session completion handler
    private var sessionCompletionHandler: (() -> Void)?
    
    /// Background task identifier
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Now playing info center for lock screen controls
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    /// Remote command center for remote controls
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Set up audio session
        setupAudioSession()
        
        // Set up remote control commands
        setupRemoteTransportControls()
        
        // Register for notifications
        registerForNotifications()
        
        logger.info("AudioManager initialized")
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        logger.info("Running in simulator - will use mock audio data")
        loadMockData()
        #endif
    }
    
    /// Set the Core Data context
    func setViewContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        
        // Load audio sessions from Core Data
        loadAudioSessions()
    }
    
    // MARK: - Audio Session Setup
    
    /// Set up the audio session for playback
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure audio session for playback
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try audioSession.setActive(true)
            
            // Get current volume
            volume = audioSession.outputVolume
            
            // Observe volume changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleVolumeChange(_:)),
                name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                object: nil
            )
            
            logger.info("Audio session set up successfully")
        } catch {
            logger.error("Failed to set up audio session: \(error.localizedDescription)")
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }
    
    /// Set up remote transport controls for lock screen and AirPods
    private func setupRemoteTransportControls() {
        // Clear any existing commands
        remoteCommandCenter.playCommand.removeTarget(nil)
        remoteCommandCenter.pauseCommand.removeTarget(nil)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.skipForwardCommand.removeTarget(nil)
        remoteCommandCenter.skipBackwardCommand.removeTarget(nil)
        
        // Add play command
        remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Add pause command
        remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Add toggle play/pause command
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if self?.isPlaying == true {
                self?.pause()
            } else {
                self?.play()
            }
            return .success
        }
        
        // Add skip forward command (15 seconds)
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let event = event as? MPSkipIntervalCommandEvent {
                self?.seekForward(by: event.interval)
            }
            return .success
        }
        
        // Add skip backward command (15 seconds)
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let event = event as? MPSkipIntervalCommandEvent {
                self?.seekBackward(by: event.interval)
            }
            return .success
        }
        
        logger.info("Remote transport controls set up")
    }
    
    /// Update now playing info for lock screen
    private func updateNowPlayingInfo() {
        guard let currentSession = currentSession else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        // Add metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSession.title ?? "Unknown Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "LifeCoach AI"
        
        if let subtitle = currentSession.subtitle {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = subtitle
        }
        
        // Add duration and current time
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        // Add playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Add artwork if available
        if let imageFileName = currentSession.audioFileName?.replacingOccurrences(of: ".mp3", with: "_img") {
            if let image = UIImage(named: imageFileName) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }
        
        // Update now playing info center
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Audio Session Loading
    
    /// Load audio sessions from Core Data
    func loadAudioSessions() {
        guard let context = viewContext else {
            logger.error("Cannot load audio sessions: Core Data context not available")
            return
        }
        
        // Fetch audio sessions
        let fetchRequest: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            let sessions = try context.fetch(fetchRequest)
            
            DispatchQueue.main.async {
                self.availableSessions = sessions
                self.logger.info("Loaded \(sessions.count) audio sessions")
                
                // Calculate completed sessions count
                self.completedSessionsCount = sessions.filter { $0.isCompleted }.count
                
                // Calculate total listening time
                self.calculateTotalListeningTime()
                
                // Load recently played sessions
                self.loadRecentlyPlayedSessions()
                
                // Generate recommended sessions
                self.generateRecommendedSessions()
            }
        } catch {
            logger.error("Failed to fetch audio sessions: \(error.localizedDescription)")
            errorMessage = "Failed to load audio content: \(error.localizedDescription)"
        }
    }
    
    /// Load recently played sessions
    private func loadRecentlyPlayedSessions() {
        guard let context = viewContext else { return }
        
        // Fetch recently completed sessions
        let fetchRequest: NSFetchRequest<SessionCompletion> = SessionCompletion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completionDate", ascending: false)]
        fetchRequest.fetchLimit = 5
        
        do {
            let completions = try context.fetch(fetchRequest)
            
            // Get unique sessions from completions
            var recentSessions: [AudioSession] = []
            var sessionIds = Set<UUID>()
            
            for completion in completions {
                if let session = completion.audioSession,
                   let sessionId = session.id,
                   !sessionIds.contains(sessionId) {
                    recentSessions.append(session)
                    sessionIds.insert(sessionId)
                }
            }
            
            DispatchQueue.main.async {
                self.recentlyPlayedSessions = recentSessions
            }
        } catch {
            logger.error("Failed to fetch recently played sessions: \(error.localizedDescription)")
        }
    }
    
    /// Generate recommended sessions based on user data
    private func generateRecommendedSessions() {
        guard let context = viewContext else { return }
        
        // Fetch user profile to get preferences
        let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(profileRequest)
            
            if let profile = profiles.first,
               let preferredCategories = profile.preferredAudioCategories as? [String] {
                
                // Fetch sessions matching preferred categories
                let sessionRequest: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
                sessionRequest.predicate = NSPredicate(format: "category IN %@", preferredCategories)
                sessionRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
                sessionRequest.fetchLimit = 5
                
                let recommendedSessions = try context.fetch(sessionRequest)
                
                DispatchQueue.main.async {
                    self.recommendedSessions = recommendedSessions
                }
            } else {
                // No preferences found, recommend popular sessions
                recommendPopularSessions()
            }
        } catch {
            logger.error("Failed to generate recommended sessions: \(error.localizedDescription)")
            recommendPopularSessions()
        }
    }
    
    /// Recommend popular sessions as fallback
    private func recommendPopularSessions() {
        guard let context = viewContext else { return }
        
        // Fetch sessions with most completions
        let fetchRequest: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
        
        // We can't directly sort by completion count in Core Data
        // So we'll fetch all and sort in memory
        do {
            let allSessions = try context.fetch(fetchRequest)
            
            // Sort by completion count
            let sortedSessions = allSessions.sorted {
                $0.completions?.count ?? 0 > $1.completions?.count ?? 0
            }
            
            // Take top 5
            let topSessions = Array(sortedSessions.prefix(5))
            
            DispatchQueue.main.async {
                self.recommendedSessions = topSessions
            }
        } catch {
            logger.error("Failed to recommend popular sessions: \(error.localizedDescription)")
        }
    }
    
    /// Calculate total listening time
    private func calculateTotalListeningTime() {
        guard let context = viewContext else { return }
        
        // Fetch all session completions
        let fetchRequest: NSFetchRequest<SessionCompletion> = SessionCompletion.fetchRequest()
        
        do {
            let completions = try context.fetch(fetchRequest)
            
            // Sum up duration seconds
            let totalSeconds = completions.reduce(0) { $0 + $1.durationSeconds }
            
            DispatchQueue.main.async {
                self.totalListeningTime = totalSeconds
            }
        } catch {
            logger.error("Failed to calculate total listening time: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Playback Control
    
    /// Play an audio session
    func playSession(session: AudioSession, startPosition: TimeInterval? = nil) {
        guard let audioFileName = session.audioFileName else {
            logger.error("Audio file name is missing")
            errorMessage = "Audio file not found"
            return
        }
        
        // Stop current playback if any
        stop()
        
        // Set current session
        currentSession = session
        
        // Check if audio file exists
        if let audioURL = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") {
            // Create player item
            playerItem = AVPlayerItem(url: audioURL)
            
            // Create player
            audioPlayer = AVPlayer(playerItem: playerItem)
            
            // Add observers
            addPlayerObservers()
            
            // Start playback
            if let startPosition = startPosition {
                seek(to: startPosition)
            }
            
            play()
            
            // Update last playback position in Core Data
            updateLastPlaybackPosition(for: session, position: startPosition ?? 0)
            
            logger.info("Playing audio session: \(audioFileName)")
        } else {
            // File not found, try text-to-speech fallback
            logger.warning("Audio file not found: \(audioFileName), using text-to-speech fallback")
            
            if let transcriptText = session.transcriptText {
                playTextToSpeech(text: transcriptText)
            } else {
                errorMessage = "Audio file not found and no transcript available"
                logger.error("Audio file not found and no transcript available")
            }
        }
    }
    
    /// Play text using text-to-speech
    private func playTextToSpeech(text: String) {
        // Stop any current speech
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = volume
        
        // Set voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Store current utterance
        currentUtterance = utterance
        
        // Start speaking
        speechSynthesizer.speak(utterance)
        
        // Update state
        isPlaying = true
        isLoading = false
        duration = Double(text.count) / 15.0 // Rough estimate: 15 chars per second
        
        // Start progress timer
        startProgressTimer()
        
        logger.info("Playing text-to-speech fallback")
    }
    
    /// Play current audio
    func play() {
        if let audioPlayer = audioPlayer {
            audioPlayer.play()
            isPlaying = true
            
            // Update now playing info
            updateNowPlayingInfo()
            
            // Begin background task if needed
            beginBackgroundTask()
            
            logger.info("Playback started")
        } else if currentUtterance != nil {
            // Resume speech if paused
            speechSynthesizer.continueSpeaking()
            isPlaying = true
            
            logger.info("Text-to-speech resumed")
        }
    }
    
    /// Pause playback
    func pause() {
        if let audioPlayer = audioPlayer {
            audioPlayer.pause()
            isPlaying = false
            
            // Update now playing info
            updateNowPlayingInfo()
            
            // End background task
            endBackgroundTask()
            
            logger.info("Playback paused")
        } else if currentUtterance != nil {
            // Pause speech
            speechSynthesizer.pauseSpeaking(at: .word)
            isPlaying = false
            
            logger.info("Text-to-speech paused")
        }
    }
    
    /// Stop playback
    func stop() {
        // Stop audio player
        if let audioPlayer = audioPlayer {
            audioPlayer.pause()
            removePlayerObservers()
            audioPlayer.replaceCurrentItem(with: nil)
            self.audioPlayer = nil
            playerItem = nil
        }
        
        // Stop speech synthesizer
        if currentUtterance != nil {
            speechSynthesizer.stopSpeaking(at: .immediate)
            currentUtterance = nil
        }
        
        // Stop progress timer
        stopProgressTimer()
        
        // Reset state
        isPlaying = false
        playbackProgress = 0.0
        currentTime = 0
        
        // End background task
        endBackgroundTask()
        
        logger.info("Playback stopped")
    }
    
    /// Seek to a specific time
    func seek(to time: TimeInterval) {
        if let audioPlayer = audioPlayer {
            let targetTime = CMTime(seconds: time, preferredTimescale: 600)
            audioPlayer.seek(to: targetTime) { [weak self] finished in
                if finished {
                    self?.currentTime = time
<<<<<<< HEAD
                    self?.playbackProgress = (self?.duration ?? 0) > 0 ? time / (self?.duration ?? 1) : 0
=======
                    self?.playbackProgress = self?.duration > 0 ? time / self!.duration : 0
>>>>>>> 510ee9d (more changes')
                    
                    // Update now playing info
                    self?.updateNowPlayingInfo()
                    
                    self?.logger.info("Seeked to \(time) seconds")
                }
            }
        }
    }
    
    /// Seek forward by a specified number of seconds
    func seekForward(by seconds: TimeInterval = 15) {
        let targetTime = min(currentTime + seconds, duration)
        seek(to: targetTime)
    }
    
    /// Seek backward by a specified number of seconds
    func seekBackward(by seconds: TimeInterval = 15) {
        let targetTime = max(currentTime - seconds, 0)
        seek(to: targetTime)
    }
    
    /// Set volume level
    func setVolume(_ level: Float) {
        volume = max(0, min(level, 1))
        audioPlayer?.volume = volume
        
        // If using text-to-speech, update utterance volume
        if let utterance = currentUtterance {
            utterance.volume = volume
        }
        
        logger.info("Volume set to \(volume)")
    }
    
    /// Toggle mute
    func toggleMute() {
        isMuted = !isMuted
        audioPlayer?.volume = isMuted ? 0 : volume
        
        logger.info("Mute toggled: \(isMuted)")
    }
    
    /// Toggle repeat mode
    func toggleRepeat() {
        isRepeatEnabled = !isRepeatEnabled
        logger.info("Repeat toggled: \(isRepeatEnabled)")
    }
    
    // MARK: - Player Observers
    
    /// Add observers to player
    private func addPlayerObservers() {
        guard let audioPlayer = audioPlayer, let playerItem = playerItem else { return }
        
        // Observe playback status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.handleReadyToPlay()
                case .failed:
                    self?.handlePlaybackFailed(with: playerItem.error)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe buffer empty
        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.isBuffering = isEmpty
            }
            .store(in: &cancellables)
        
        // Add periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdate(time: time)
        }
        
        // Observe playback did end notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    /// Remove observers from player
    private func removePlayerObservers() {
        // Remove time observer
        if let timeObserverToken = timeObserverToken, let audioPlayer = audioPlayer {
            audioPlayer.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        // Remove notifications
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // Clear cancellables
        cancellables.removeAll()
    }
    
    /// Handle player ready to play
    private func handleReadyToPlay() {
        guard let playerItem = playerItem else { return }
        
        // Get duration
        let seconds = playerItem.duration.seconds
        if seconds.isFinite && seconds > 0 {
            duration = seconds
        }
        
        // Update state
        isLoading = false
        
        // Start progress timer
        startProgressTimer()
        
        // Update now playing info
        updateNowPlayingInfo()
        
        logger.info("Player ready to play, duration: \(duration) seconds")
    }
    
    /// Handle playback failure
    private func handlePlaybackFailed(with error: Error?) {
        isLoading = false
        isPlaying = false
        
        if let error = error {
            errorMessage = "Playback failed: \(error.localizedDescription)"
            logger.error("Playback failed: \(error.localizedDescription)")
        } else {
            errorMessage = "Playback failed with unknown error"
            logger.error("Playback failed with unknown error")
        }
        
        // Try text-to-speech fallback
        if let session = currentSession, let transcriptText = session.transcriptText {
            logger.info("Attempting text-to-speech fallback")
            playTextToSpeech(text: transcriptText)
        }
    }
    
    /// Handle time update
    private func handleTimeUpdate(time: CMTime) {
        currentTime = time.seconds
        
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
        
        // Update now playing info occasionally
        if Int(currentTime) % 5 == 0 {
            updateNowPlayingInfo()
        }
        
        // Update last playback position in Core Data occasionally
        if Int(currentTime) % 10 == 0, let session = currentSession {
            updateLastPlaybackPosition(for: session, position: currentTime)
        }
    }
    
    /// Player did finish playing notification handler
    @objc private func playerDidFinishPlaying(notification: Notification) {
        logger.info("Playback finished")
        
        // Handle completion
        handleSessionCompletion()
        
        // Check if repeat is enabled
        if isRepeatEnabled, let session = currentSession {
            // Restart playback
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.playSession(session: session)
            }
        } else {
            // Reset state
            isPlaying = false
            playbackProgress = 1.0
            
            // End background task
            endBackgroundTask()
        }
    }
    
    // MARK: - Progress Timer
    
    /// Start progress update timer
    private func startProgressTimer() {
        // Stop any existing timer
        stopProgressTimer()
        
        // Create new timer
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // If using audio player, time is handled by periodic time observer
            if self.audioPlayer != nil {
                return
            }
            
            // For text-to-speech, estimate progress
            if self.speechSynthesizer.isSpeaking {
                // Increment current time
                self.currentTime += 0.5
                
                // Calculate progress
                if self.duration > 0 {
                    self.playbackProgress = min(self.currentTime / self.duration, 1.0)
                }
                
                // Check if speech should be complete based on estimated duration
                if self.currentTime >= self.duration {
                    self.speechSynthesizer.stopSpeaking(at: .immediate)
                    self.handleSessionCompletion()
                    self.stopProgressTimer()
                    self.isPlaying = false
                    self.playbackProgress = 1.0
                    self.currentUtterance = nil
                }
            }
        }
    }
    
    /// Stop progress update timer
    private func stopProgressTimer() {
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
    }
    
    // MARK: - Session Completion
    
    /// Handle session completion
    private func handleSessionCompletion() {
        guard let session = currentSession else { return }
        
        // Mark session as completed in Core Data
        markSessionAsCompleted(session)
        
        // Call completion handler if set
        sessionCompletionHandler?()
        sessionCompletionHandler = nil
        
        logger.info("Session completed: \(session.title ?? "Unknown")")
    }
    
    /// Mark a session as completed in Core Data
    private func markSessionAsCompleted(_ session: AudioSession) {
        guard let context = viewContext, let sessionId = session.id else {
            logger.error("Cannot mark session as completed: Core Data context not available or session ID is nil")
            return
        }
        
        // Update session
        session.isCompleted = true
        
        // Create completion record
        let completion = SessionCompletion(context: context)
        completion.id = UUID()
        completion.completionDate = Date()
        completion.durationSeconds = currentTime
        completion.audioSession = session
        
        // Find user profile to associate with
        let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        do {
            if let userProfile = try context.fetch(profileRequest).first {
                completion.userProfile = userProfile
            }
        } catch {
            logger.error("Failed to fetch user profile: \(error.localizedDescription)")
        }
        
        // Save context
        do {
            try context.save()
            
            // Update completed sessions count
            completedSessionsCount += 1
            
            // Update total listening time
            totalListeningTime += currentTime
            
            // Refresh recently played sessions
            loadRecentlyPlayedSessions()
            
            logger.info("Session marked as completed in Core Data")
        } catch {
            logger.error("Failed to save completion to Core Data: \(error.localizedDescription)")
        }
    }
    
    /// Update last playback position for a session
    private func updateLastPlaybackPosition(for session: AudioSession, position: TimeInterval) {
        guard let context = viewContext else { return }
        
        // Update session
        session.lastPlaybackPosition = position
        
        // Save context
        do {
            try context.save()
        } catch {
            logger.error("Failed to update last playback position: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Background Tasks
    
    /// Begin background task for continued playback
    private func beginBackgroundTask() {
        // End any existing background task
        endBackgroundTask()
        
        // Begin a new background task
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        logger.info("Background task began: \(backgroundTaskID.rawValue)")
    }
    
    /// End background task
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            logger.info("Background task ended")
        }
    }
    
    // MARK: - Notification Handlers
    
    /// Register for system notifications
    private func registerForNotifications() {
        // Audio session interruption notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // Audio session route change notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // App will enter foreground notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // App did enter background notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    /// Handle audio session interruption (e.g., phone call)
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began, pause playback
            if isPlaying {
                pause()
                logger.info("Audio interrupted, playback paused")
            }
            
        case .ended:
            // Interruption ended, resume playback if option is set
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue),
               options.contains(.shouldResume) {
                play()
                logger.info("Audio interruption ended, playback resumed")
            }
            
        @unknown default:
            break
        }
    }
    
    /// Handle audio route change (e.g., headphones disconnected)
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        // If headphones were unplugged, pause playback
        if reason == .oldDeviceUnavailable {
            if isPlaying {
                pause()
                logger.info("Headphones disconnected, playback paused")
            }
        }
    }
    
    /// Handle volume change notification
    @objc private func handleVolumeChange(_ notification: Notification) {
        if let volumeView = MPVolumeView().subviews.first as? UISlider {
            volume = volumeView.value
        }
    }
    
    /// Handle app will enter foreground notification
    @objc private func handleAppWillEnterForeground() {
        // Reactivate audio session if needed
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Failed to reactivate audio session: \(error.localizedDescription)")
        }
    }
    
    /// Handle app did enter background notification
    @objc private func handleAppDidEnterBackground() {
        // If not playing, we can release the audio session
        if !isPlaying {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Set completion handler for current session
    func setSessionCompletionHandler(_ handler: @escaping () -> Void) {
        sessionCompletionHandler = handler
    }
    
    /// Get audio sessions by category
    func getSessionsByCategory(_ category: AudioCategory) -> [AudioSession] {
        return availableSessions.filter { $0.category == category.rawValue }
    }
    
    /// Get audio sessions by type
    func getSessionsByType(_ type: AudioSessionType) -> [AudioSession] {
        return availableSessions.filter { $0.title?.contains(type.rawValue) ?? false }
    }
    
    /// Check if a session is premium
    func isSessionPremium(_ session: AudioSession) -> Bool {
        return session.isPremium
    }
    
    /// Get session view model
    func getSessionViewModel(for session: AudioSession) -> AudioSessionViewModel? {
        guard let id = session.id,
              let title = session.title,
              let audioFileName = session.audioFileName else {
            return nil
        }
        
        return AudioSessionViewModel(
            id: id,
            title: title,
            subtitle: session.subtitle,
            category: AudioCategory(rawValue: session.category ?? "Meditation") ?? .meditation,
            type: AudioSessionType(rawValue: session.title?.components(separatedBy: " ").first ?? "Meditation") ?? .meditation,
            duration: session.duration,
            isPremium: session.isPremium,
            isCompleted: session.isCompleted,
            completionCount: session.completions?.count ?? 0,
            audioFileName: audioFileName,
            imageFileName: audioFileName.replacingOccurrences(of: ".mp3", with: "_img")
        )
    }
    
    /// Prepare audio resources
    func prepareAudioResources() {
        // Preload audio files in background
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Check if we have sessions
            if self.availableSessions.isEmpty {
                self.loadAudioSessions()
            }
            
            // Preload first few audio files
            for session in self.availableSessions.prefix(3) {
                if let audioFileName = session.audioFileName,
                   let audioURL = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") {
                    let asset = AVAsset(url: audioURL)
                    let _ = asset.duration // Force load metadata
                }
            }
        }
    }
    
    /// Handle app becoming inactive
    func handleAppInactive() {
        // If playing speech, pause it
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: .word)
            isPlaying = false
        }
        
        // Audio player will continue in background if background audio is enabled
    }
    
    // MARK: - Mock Data for Simulator
    
    /// Load mock data for simulator testing
    private func loadMockData() {
        logger.info("Loading mock audio data for simulator")
        
        // Create mock audio sessions if Core Data is empty
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self, let context = self.viewContext else { return }
            
            // Check if we already have sessions
            let fetchRequest: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
            
            do {
                let existingSessions = try context.fetch(fetchRequest)
                
                if existingSessions.isEmpty {
                    // Create mock sessions
                    self.createMockAudioSessions(in: context)
                } else {
                    // Use existing sessions
                    self.availableSessions = existingSessions
                    self.completedSessionsCount = existingSessions.filter { $0.isCompleted }.count
                    self.calculateTotalListeningTime()
                    self.loadRecentlyPlayedSessions()
                    self.generateRecommendedSessions()
                }
            } catch {
                self.logger.error("Failed to check for existing sessions: \(error.localizedDescription)")
                
                // Create mock sessions anyway
                self.createMockAudioSessions(in: context)
            }
        }
    }
    
    /// Create mock audio sessions in Core Data
    private func createMockAudioSessions(in context: NSManagedObjectContext) {
        // Create mock sessions
        let mockSessions: [(title: String, category: String, duration: TimeInterval, isPremium: Bool)] = [
            ("Morning Meditation", "Meditation", 600, false),
            ("Deep Sleep Journey", "Sleep", 1200, true),
            ("Stress Relief Breathing", "Stress", 300, false),
            ("Positive Affirmations", "Motivation", 180, false),
            ("Forest Soundscape", "Focus", 1800, true),
            ("Evening Wind Down", "Evening", 900, false),
            ("Gratitude Practice", "Gratitude", 420, false),
            ("Anxiety Relief", "Anxiety", 600, true),
            ("Wake Up Energizer", "Morning", 300, false),
            ("Body Scan Relaxation", "Meditation", 900, true)
        ]
        
        // Create user profile if needed
        var userProfile: UserProfile?
        let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(profileRequest)
            
            if let profile = profiles.first {
                userProfile = profile
            } else {
                // Create new profile
                let newProfile = UserProfile(context: context)
                newProfile.id = UUID()
                newProfile.creationDate = Date()
                newProfile.isOnboarded = true
                newProfile.isPremium = false
                newProfile.preferredAudioCategories = ["Meditation", "Sleep", "Focus"] as NSObject
                
                userProfile = newProfile
            }
        } catch {
            logger.error("Failed to fetch or create user profile: \(error.localizedDescription)")
        }
        
        // Create sessions
        var createdSessions: [AudioSession] = []
        
        for (index, mockSession) in mockSessions.enumerated() {
            let session = AudioSession(context: context)
            session.id = UUID()
            session.title = mockSession.title
            session.subtitle = "LifeCoach AI \(mockSession.category) Series"
            session.category = mockSession.category
            session.audioFileName = "audio_\(index + 1)"
            session.duration = mockSession.duration
            session.isPremium = mockSession.isPremium
            session.isCompleted = index < 3 // First 3 are completed
            session.startDate = Date().addingTimeInterval(-Double(index) * 86400) // Stagger start dates
            session.transcriptText = "This is a guided \(mockSession.category.lowercased()) session to help you feel more relaxed and centered. Close your eyes, take a deep breath, and let's begin."
            session.userProfile = userProfile
            
            // For completed sessions, add completion records
            if session.isCompleted {
                let completion = SessionCompletion(context: context)
                completion.id = UUID()
                completion.completionDate = Date().addingTimeInterval(-Double(index) * 43200) // Stagger completion dates
                completion.durationSeconds = mockSession.duration
                completion.audioSession = session
                completion.userProfile = userProfile
                completion.rating = Int16.random(in: 3...5) // Random rating between 3-5
            }
            
            createdSessions.append(session)
        }
        
        // Save context
        do {
            try context.save()
            
            // Update published properties
            availableSessions = createdSessions
            completedSessionsCount = createdSessions.filter { $0.isCompleted }.count
            calculateTotalListeningTime()
            loadRecentlyPlayedSessions()
            generateRecommendedSessions()
            
            logger.info("Created \(createdSessions.count) mock audio sessions")
        } catch {
            logger.error("Failed to save mock audio sessions: \(error.localizedDescription)")
        }
    }
}
