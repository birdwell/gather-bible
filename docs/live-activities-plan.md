# Live Activities Implementation Plan

## Overview

Implement Live Activities for Gather Bible sessions to provide at-a-glance session information on the Lock Screen, Dynamic Island, and Apple Watch Smart Stack.

---

## What Users Will See

### Host View

| Location | Content |
|----------|---------|
| **Dynamic Island (Compact)** | 📖 Book Chapter • 👥 Count |
| **Dynamic Island (Expanded)** | Full scripture reference, participant count, active discussion status, "End Session" button |
| **Lock Screen** | Session code (shareable), scripture location, participant count, discussion status |
| **Apple Watch** | Current scripture, participant count |

### Guest View

| Location | Content |
|----------|---------|
| **Dynamic Island (Compact)** | 📖 Book Chapter • Following indicator |
| **Dynamic Island (Expanded)** | Scripture reference, host status, discussion prompt + "Respond" button |
| **Lock Screen** | Current scripture, host status indicator, active discussion question |
| **Apple Watch** | Current scripture, discussion prompt |

---

## Features to Implement

### Core Features
- [x] Lock Screen presentation with session state
- [x] Dynamic Island compact/expanded/minimal views
- [x] Real-time updates when host navigates scripture
- [x] Discussion alerts with sound when new discussion starts
- [x] Participant count updates

### Interactive Controls (iOS 17+)
- [x] **Host**: "End Session" button
- [x] **Host**: "View Responses" button (when discussion active)
- [x] **Guest**: "Respond to Discussion" button

### Platform Support
- [x] iPhone Dynamic Island (iOS 16.1+)
- [x] iPhone/iPad Lock Screen (iOS 16.1+)
- [x] Apple Watch Smart Stack (watchOS 11+)
- [x] StandBy mode support

---

## Implementation Tasks

### Phase 1: Project Setup

#### Task 1.1: Create Widget Extension
- [ ] File → New → Target → Widget Extension
- [ ] Name: `GatherBibleWidgets`
- [ ] Include Live Activity support
- [ ] Configure shared App Group for data sharing

#### Task 1.2: Configure Info.plist
- [ ] Add `NSSupportsLiveActivities = YES` to main app target
- [ ] Add `NSSupportsLiveActivitiesFrequentUpdates = YES` for real-time scripture updates

#### Task 1.3: Set Up App Groups
- [ ] Create App Group: `group.com.gatherbible.shared`
- [ ] Add to main app target
- [ ] Add to widget extension target
- [ ] Create shared `UserDefaults` suite for cross-process data

---

### Phase 2: Define Activity Attributes

#### Task 2.1: Create SessionActivityAttributes
Create shared model accessible by both app and widget extension:

```swift
// Shared/SessionActivityAttributes.swift

import ActivityKit
import Foundation

struct SessionActivityAttributes: ActivityAttributes {
    // Static data (doesn't change during session)
    let joinCode: String
    let hostName: String
    let isHost: Bool
    
    // Dynamic data (updates throughout session)
    struct ContentState: Codable, Hashable {
        let book: String
        let chapter: Int
        let startVerseId: String
        let versionName: String
        let participantCount: Int
        let activeDiscussionQuestion: String?
        let discussionResponseCount: Int
        let hostIsActive: Bool
        let updatedAt: Date
    }
}
```

#### Task 2.2: Create Helper Extensions
```swift
extension SessionActivityAttributes.ContentState {
    var scriptureReference: String {
        "\(book) \(chapter)"
    }
    
    var hasActiveDiscussion: Bool {
        activeDiscussionQuestion != nil
    }
}
```

---

### Phase 3: Build Live Activity UI

#### Task 3.1: Create Lock Screen View
File: `GatherBibleWidgets/Views/SessionLockScreenView.swift`

**Host Layout:**
```
┌─────────────────────────────────────────┐
│  📖 Genesis 1:1              👥 5       │
│  ─────────────────────────────────────  │
│  Session Code: ABC123                   │
│  ─────────────────────────────────────  │
│  💬 "What does this mean to you?"       │
│      3 responses    [View Responses]    │
└─────────────────────────────────────────┘
```

**Guest Layout:**
```
┌─────────────────────────────────────────┐
│  📖 Genesis 1:1              👥 5       │
│  ─────────────────────────────────────  │
│  Host: John                  ● Active   │
│  ─────────────────────────────────────  │
│  💬 "What does this mean to you?"       │
│                          [Respond]      │
└─────────────────────────────────────────┘
```

#### Task 3.2: Create Dynamic Island Views

**Compact Leading:**
- Book icon + abbreviated book name

**Compact Trailing:**
- Chapter:Verse or participant count

**Expanded:**
- Full scripture reference
- Participant avatars/count
- Discussion status
- Action buttons

**Minimal:**
- Book abbreviation only (e.g., "Gen")

#### Task 3.3: Create Apple Watch View
- Simplified scripture reference
- Discussion indicator
- Tap to open app

#### Task 3.4: Implement Widget Configuration
File: `GatherBibleWidgets/SessionActivityWidget.swift`

```swift
import WidgetKit
import SwiftUI

struct SessionActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            // Lock Screen view
            SessionLockScreenView(
                attributes: context.attributes,
                state: context.state,
                isStale: context.isStale
            )
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    SessionExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SessionExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    SessionExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SessionExpandedBottomView(context: context)
                }
            } compactLeading: {
                SessionCompactLeadingView(context: context)
            } compactTrailing: {
                SessionCompactTrailingView(context: context)
            } minimal: {
                SessionMinimalView(context: context)
            }
        }
    }
}
```

---

### Phase 4: Activity Lifecycle Management

#### Task 4.1: Create SessionActivityManager
File: `Gather Bible/Features/Session/Services/SessionActivityManager.swift`

```swift
import ActivityKit
import Foundation

@MainActor
final class SessionActivityManager: ObservableObject {
    static let shared = SessionActivityManager()
    
    private var currentActivity: Activity<SessionActivityAttributes>?
    
    // Start activity when joining/creating session
    func startActivity(
        joinCode: String,
        hostName: String,
        isHost: Bool,
        initialState: SessionActivityAttributes.ContentState
    ) async throws
    
    // Update activity when session state changes
    func updateActivity(with state: SessionActivityAttributes.ContentState) async
    
    // Update with alert (for new discussions)
    func updateActivityWithAlert(
        state: SessionActivityAttributes.ContentState,
        alertTitle: String
    ) async
    
    // End activity when leaving session
    func endActivity() async
}
```

#### Task 4.2: Implement Start Activity
```swift
func startActivity(
    joinCode: String,
    hostName: String,
    isHost: Bool,
    initialState: SessionActivityAttributes.ContentState
) async throws {
    // Check if Live Activities are enabled
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        throw SessionActivityError.activitiesDisabled
    }
    
    let attributes = SessionActivityAttributes(
        joinCode: joinCode,
        hostName: hostName,
        isHost: isHost
    )
    
    let content = ActivityContent(
        state: initialState,
        staleDate: Date().addingTimeInterval(60 * 60 * 2) // 2 hours
    )
    
    currentActivity = try Activity.request(
        attributes: attributes,
        content: content,
        pushType: .token // Enable push updates
    )
    
    // Observe push token for server-side updates
    if let activity = currentActivity {
        for await token in activity.pushTokenUpdates {
            await sendPushTokenToServer(token)
        }
    }
}
```

#### Task 4.3: Implement Update Activity
```swift
func updateActivity(with state: SessionActivityAttributes.ContentState) async {
    guard let activity = currentActivity else { return }
    
    let content = ActivityContent(
        state: state,
        staleDate: Date().addingTimeInterval(60 * 60 * 2)
    )
    
    await activity.update(content)
}

func updateActivityWithAlert(
    state: SessionActivityAttributes.ContentState,
    alertTitle: String
) async {
    guard let activity = currentActivity else { return }
    
    let content = ActivityContent(
        state: state,
        staleDate: Date().addingTimeInterval(60 * 60 * 2)
    )
    
    let alertConfig = AlertConfiguration(
        title: LocalizedStringResource(stringLiteral: alertTitle),
        body: LocalizedStringResource(stringLiteral: state.activeDiscussionQuestion ?? ""),
        sound: .default
    )
    
    await activity.update(content, alertConfiguration: alertConfig)
}
```

#### Task 4.4: Implement End Activity
```swift
func endActivity() async {
    guard let activity = currentActivity else { return }
    
    let finalState = SessionActivityAttributes.ContentState(
        book: "",
        chapter: 0,
        startVerseId: "",
        versionName: "",
        participantCount: 0,
        activeDiscussionQuestion: nil,
        discussionResponseCount: 0,
        hostIsActive: false,
        updatedAt: Date()
    )
    
    let content = ActivityContent(
        state: finalState,
        staleDate: nil
    )
    
    await activity.end(content, dismissalPolicy: .immediate)
    currentActivity = nil
}
```

---

### Phase 5: Integrate with SessionViewModel

#### Task 5.1: Add Activity Manager to SessionViewModel
File: `Gather Bible/Features/Session/ViewModels/SessionViewModel.swift`

```swift
// Add property
private let activityManager = SessionActivityManager.shared

// Add method to build content state
private func buildActivityContentState() -> SessionActivityAttributes.ContentState {
    SessionActivityAttributes.ContentState(
        book: currentBook,
        chapter: currentChapter,
        startVerseId: currentVerseId,
        versionName: currentVersionName,
        participantCount: activeParticipantCount,
        activeDiscussionQuestion: activeDiscussion?.question,
        discussionResponseCount: discussionResponses.count,
        hostIsActive: !isCurrentHostInactive,
        updatedAt: Date()
    )
}
```

#### Task 5.2: Start Activity on Session Join/Create
```swift
// In createSession() or joinSession()
Task {
    try await activityManager.startActivity(
        joinCode: joinCode,
        hostName: hostName,
        isHost: isHost,
        initialState: buildActivityContentState()
    )
}
```

#### Task 5.3: Update Activity on State Changes
```swift
// Call when session state updates from Firebase
private func handleSessionStateUpdate(_ state: SessionState) {
    // Existing logic...
    
    // Update Live Activity
    Task {
        await activityManager.updateActivity(with: buildActivityContentState())
    }
}
```

#### Task 5.4: Alert on New Discussion
```swift
// In startDiscussion() or when receiving new discussion
Task {
    await activityManager.updateActivityWithAlert(
        state: buildActivityContentState(),
        alertTitle: "New Discussion"
    )
}
```

#### Task 5.5: End Activity on Leave
```swift
// In leaveSession()
Task {
    await activityManager.endActivity()
}
```

---

### Phase 6: Interactive Controls (App Intents)

#### Task 6.1: Create End Session Intent
File: `GatherBibleWidgets/Intents/EndSessionIntent.swift`

```swift
import AppIntents

struct EndSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Session"
    
    func perform() async throws -> some IntentResult {
        // Use App Groups to communicate with main app
        let defaults = UserDefaults(suiteName: "group.com.gatherbible.shared")
        defaults?.set(true, forKey: "shouldEndSession")
        
        // Post notification for main app to handle
        DistributedNotificationCenter.default().postNotificationName(
            .init("EndSessionRequested"),
            object: nil
        )
        
        return .result()
    }
}
```

#### Task 6.2: Create View Responses Intent
```swift
struct ViewResponsesIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "View Responses"
    
    func perform() async throws -> some IntentResult {
        // Deep link to discussion responses
        return .result()
    }
}
```

#### Task 6.3: Create Respond to Discussion Intent
```swift
struct RespondToDiscussionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Respond"
    
    func perform() async throws -> some IntentResult {
        // Deep link to discussion response sheet
        return .result()
    }
}
```

#### Task 6.4: Add Buttons to Live Activity Views
```swift
// In SessionExpandedBottomView
if context.attributes.isHost {
    Button(intent: EndSessionIntent()) {
        Label("End Session", systemImage: "xmark.circle.fill")
    }
    .tint(.red)
    
    if context.state.hasActiveDiscussion {
        Button(intent: ViewResponsesIntent()) {
            Label("Responses", systemImage: "bubble.left.and.bubble.right")
        }
    }
} else {
    if context.state.hasActiveDiscussion {
        Button(intent: RespondToDiscussionIntent()) {
            Label("Respond", systemImage: "text.bubble")
        }
        .tint(.blue)
    }
}
```

---

### Phase 7: Deep Linking

#### Task 7.1: Configure URL Scheme
Add to Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>gatherbible</string>
        </array>
    </dict>
</array>
```

#### Task 7.2: Add Widget URLs
```swift
// Lock Screen view
SessionLockScreenView(...)
    .widgetURL(URL(string: "gatherbible://session/\(context.attributes.joinCode)"))
```

#### Task 7.3: Handle Deep Links in App
```swift
// In main App struct
.onOpenURL { url in
    handleDeepLink(url)
}

func handleDeepLink(_ url: URL) {
    guard url.scheme == "gatherbible" else { return }
    
    switch url.host {
    case "session":
        // Navigate to session view
    case "discussion":
        // Open discussion response sheet
    default:
        break
    }
}
```

---

### Phase 8: Push Notification Updates (Optional)

#### Task 8.1: Configure Push Notifications
- [ ] Set up APNs for Live Activity updates
- [ ] Configure Firebase Cloud Functions to send ActivityKit push notifications
- [ ] Handle push token registration in `SessionActivityManager`

#### Task 8.2: Server-Side Push Payload
```json
{
    "aps": {
        "timestamp": 1234567890,
        "event": "update",
        "content-state": {
            "book": "Genesis",
            "chapter": 2,
            "startVerseId": "GEN.2.1",
            "versionName": "ESV",
            "participantCount": 5,
            "activeDiscussionQuestion": null,
            "discussionResponseCount": 0,
            "hostIsActive": true,
            "updatedAt": 1234567890
        }
    }
}
```

---

### Phase 9: Testing

#### Task 9.1: Unit Tests
- [ ] Test `SessionActivityAttributes` encoding/decoding
- [ ] Test `SessionActivityManager` lifecycle methods
- [ ] Test content state building

#### Task 9.2: UI Tests
- [ ] Test Live Activity appears on session join
- [ ] Test Live Activity updates on scripture navigation
- [ ] Test Live Activity ends on session leave
- [ ] Test discussion alerts appear correctly

#### Task 9.3: Device Testing
- [ ] Test on iPhone with Dynamic Island
- [ ] Test on iPhone without Dynamic Island (Lock Screen only)
- [ ] Test on iPad
- [ ] Test in StandBy mode
- [ ] Test on Apple Watch (if available)

---

## File Structure

```
Gather Bible/
├── Gather Bible/
│   └── Features/
│       └── Session/
│           ├── Models/
│           │   └── SessionActivityAttributes.swift  # Shared with widget
│           └── Services/
│               └── SessionActivityManager.swift
│
└── GatherBibleWidgets/
    ├── GatherBibleWidgets.swift          # Widget bundle
    ├── SessionActivityWidget.swift        # Activity configuration
    ├── Views/
    │   ├── SessionLockScreenView.swift
    │   ├── DynamicIsland/
    │   │   ├── SessionCompactLeadingView.swift
    │   │   ├── SessionCompactTrailingView.swift
    │   │   ├── SessionMinimalView.swift
    │   │   └── SessionExpandedView.swift
    │   └── WatchOS/
    │       └── SessionWatchView.swift
    └── Intents/
        ├── EndSessionIntent.swift
        ├── ViewResponsesIntent.swift
        └── RespondToDiscussionIntent.swift
```

---

## Dependencies

- iOS 16.1+ (Live Activities)
- iOS 17+ (Interactive buttons)
- watchOS 11+ (Smart Stack support)
- ActivityKit framework
- WidgetKit framework
- AppIntents framework

---

## Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Setup | 1 day | None |
| Phase 2: Attributes | 0.5 day | Phase 1 |
| Phase 3: UI | 2-3 days | Phase 2 |
| Phase 4: Lifecycle | 1-2 days | Phase 2, 3 |
| Phase 5: Integration | 1 day | Phase 4 |
| Phase 6: Intents | 1 day | Phase 3 |
| Phase 7: Deep Linking | 0.5 day | Phase 6 |
| Phase 8: Push (Optional) | 2 days | Phase 4 |
| Phase 9: Testing | 1-2 days | All phases |

**Total: 10-14 days**

---

## Open Questions

1. Should the Live Activity auto-start when creating/joining, or should there be a toggle?
2. What should the stale date be? (Currently set to 2 hours)
3. Should we support multiple simultaneous sessions? (Currently assumes one)
4. Do we want haptic feedback on discussion alerts?
