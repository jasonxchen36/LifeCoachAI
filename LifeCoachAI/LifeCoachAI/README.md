# LifeCoach AI 🧠💪  
Your personalized, AI-powered life-coaching companion built with Swift & SwiftUI.

---

## 1. Overview

LifeCoach AI combines on-device machine learning, Apple HealthKit, immersive audio guidance, and gentle gamification to improve mental, physical, and emotional wellbeing.

Key goals  
• Deliver real-time, context-aware coaching (“It looks like you’re stressed – try a 5-minute breathing session.”)  
• Provide beautiful dashboards of HealthKit metrics and progress toward goals  
• Keep users engaged through streaks, badges, and audio sessions  
• Ship an MVP that **runs fully in the iOS Simulator on MacinCloud** with zero third-party services

---

## 2. Core Features (MVP)

| Area | Highlights |
| --- | --- |
| AI Recommendations | Core ML model for sentiment + rule engine; daily & push-based tips |
| HealthKit Dashboard | Steps, heart-rate, sleep, mindful minutes, water, etc.; mock data injection in Simulator |
| Audio Sessions | 10 pre-recorded MP3s + TTS fallback; background playback; AirPods friendly |
| Goals & Gamification | Custom goals, streak tracking, badges, social share sheet |
| Freemium Monetization | StoreKit 2 subscription (`monthly` / `yearly`) paywall |
| Accessibility & Intl. | Dynamic Type, VoiceOver, English `Base.lproj` strings ready for localisation |

---

## 3. Architecture & Tech Stack

| Layer | Frameworks / Notes |
| ----- | ------------------ |
| **UI** | SwiftUI 3, MVVM, Combine |
| **Data** | Core Data (+CloudKit toggle-off by default) |
| **Health** | HealthKit, HKObserverQuery, mock injector for Simulator |
| **Audio** | AVFoundation, `AVAudioSession` (playback) |
| **AI** | Core ML (`SentimentClassifier.mlmodel`), UpdateTask to pull new models |
| **Payments** | StoreKit 2, sandbox by default |
| **Background** | BackgroundTasks for overnight processing |
| **Analytics** | Apple App Analytics (no 3rd-party) |

---

## 4. Project File Structure

```
LifeCoachAI/
├─ Assets.xcassets/          // icons, colors, audio covers
├─ LifeCoachAIApp.swift
├─ Models/                   // Core Data model + Swift enums
│  └─ LifeCoachAI.xcdatamodeld
├─ ViewModels/
│  ├─ HealthKitManager.swift
│  ├─ NotificationManager.swift
│  ├─ AudioManager.swift
│  ├─ MLManager.swift
│  └─ StoreManager.swift
├─ Services/                 // networking, persistence helpers
├─ Views/                    // SwiftUI screens & components
│  ├─ OnboardingView.swift
│  ├─ DashboardView.swift
│  ├─ AudioLibraryView.swift
│  └─ …
└─ README.md                 // you are here
```

_All folders are referenced groups; nothing lives outside `LifeCoachAI` target._

---

## 5. Setup Guide (MacinCloud)

1. **Spin up a MacinCloud “Managed Server”** with Xcode 15 (or newer).
2. **Clone repository**  
   ```
   git clone https://github.com/<your-org>/LifeCoachAI.git
   cd LifeCoachAI
   ```
3. **Open Xcode project**  
   `open LifeCoachAI.xcodeproj`
4. **Select Scheme ➜ “LifeCoachAI”** and **target “Any iOS Simulator Device (iOS 17)”**.
5. First build may take a few minutes (SwiftPM resolves nothing; only Apple frameworks).
6. ☑️ **Runs 100 % in Simulator** – HealthKit & audio are mocked automatically.

---

## 6. Testing Guidelines

### HealthKit
* `HealthKitManager` detects `#if targetEnvironment(simulator)` and feeds deterministic mock data.
* To test edge cases, toggle values in `MockDataGenerator` or attach Xcode debugger and set breakpoints.

### Audio
* Audio files live in **Assets ➜ Audio/**.  
* Spatial audio simulation works in Simulator when using wired / Bluetooth headphones.

### StoreKit
* Add Sandbox tester in App Store Connect.  
* Run **StoreKit ➜ Transaction Inspector** inside Xcode to validate purchases.

### UI Tests
* `LifeCoachAIUITests` includes:
  * Onboarding flow
  * Paywall purchase stub
  * Dashboard health cards visibility

Run:  
```
⌘U  // or Product ▸ Test
```

---

## 7. Development Roadmap (6-8 Weeks)

| Week | Milestone |
| ---- | --------- |
| 1 | Project scaffolding, Core Data model, splash + onboarding UI |
| 2 | HealthKitManager with mock pipeline; basic dashboard cards |
| 3 | Audio playback & library screen, integrate 10 MP3s |
| 4 | Recommendation engine (rule-based + Core ML sentiment); NotificationManager |
| 5 | Goals, streak logic, gamification UI |
| 6 | Paywall & StoreKit; accessibility polish; end-to-end integration test |
| 7 | Beta round: bug-fix, energy profiling, iPhone SE optimisation |
| 8 | App Store metadata, screenshots, legal review, TestFlight submission |

_Future: Apple Watch companion, Vision Pro spatial dashboard, meal-plan generator, social circles._

---

## 8. App Store Submission Notes

1. **App ID & Bundle**: `com.<company>.LifeCoachAI`
2. **Entitlements**  
   * HealthKit (read only)  
   * In-App Purchase  
   * Background Modes → Background fetch & processing  
3. **Privacy Manifest** – include `NSHealthShareUsageDescription`, `NSMicrophoneUsageDescription`, `NSCalendarsUsageDescription` (optional).  
4. **Family-Sensitive Data** – no, app is 17+.  
5. **TestFlight** – upload `.ipa` via Xcode Organizer (“Archive” then “Distribute App”).  
6. **Review Notes**  
   * All health recommendations are educational, not medical advice (FDA compliance).  
   * Mock data available for review team in demo mode (`Settings ▸ Developer ▸ Enable Demo Data`).  

---

### ❤️  Thank you for contributing!  
Found a bug or have a wellness idea? Open an issue or PR – together we build healthier lives.
"# LifeCoachAI" 
