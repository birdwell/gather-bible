# Gather Bible — Apple HIG Design & UX Audit

Audit of the SwiftUI app against Apple's Human Interface Guidelines, covering the Bible Reader, Session, Community, External Display features and shared components. Findings cite `file:line` in the current codebase.

## What's already strong

The foundation is genuinely good and worth preserving:

- **App shell** — iOS 18 `Tab` API with `.tabViewStyle(.sidebarAdaptable)`, size-class-driven layout branching (not device checks), and a real `NavigationSplitView` on iPad (`ContentView.swift:17-34`, `CommunityViewiPad.swift:33-63`).
- **Color** — Semantic colors (`.secondarySystemBackground`, `.separator`, `.primary/.secondary`) nearly everywhere; dark mode is fundamentally sound. `FormField` even adapts to Increased Contrast.
- **Typography** — System text styles used in most views, so Dynamic Type mostly works.
- **Model citizens to copy from** — `SessionCodeBanner` (spoken per-character code, `@ScaledMetric`, Reduce Motion respect, 44pt targets) and `CopyableCodeButton` (44pt target, copy feedback via `contentTransition`).
- **External display** — A true second-screen experience via a dedicated `TVReaderView` (not mirroring), which is exactly what HIG recommends; system `AVRoutePickerView` for AirPlay.
- **Thoughtful group-session UX** — "Claim Host" recovery when the host goes inactive, chapter navigation that wraps across book boundaries, scroll-sync that yields to the guest's own touch.

---

## Top 10 highest-leverage fixes

Ranked by user impact:

### 1. Discussion sheets dismiss on failure and silently lose the user's text
`CreateDiscussionSheet.swift:53-58` and `DiscussionPromptSheet.swift:48-53` both `await` the submit then call `dismiss()` unconditionally. On a network failure the sheet closes, the typed question/answer is gone, and nothing renders `viewModel.errorMessage`. The host believes the discussion was sent.
**Fix:** only dismiss when `errorMessage == nil`; show the error inline in the sheet and keep the text.

### 2. Errors are invisible across most of the app
- `InSessionView`, `DraftDiscussionsView`, `DiscussionResultsView`, and both Community containers never render `viewModel.errorMessage` — failures of claim-host, publish, complete, delete, and leave are all silent.
- `BibleReaderViewModel.swift:190-193, 209-211` catches load errors and only `print`s — on network failure the reader shows "Loading..." forever with no retry.
- Deep-link failures are silent too: malformed links (`ContentView.swift:41-53`) and scanning a join QR while already in a session (`SessionManagementView.swift:34-40`) do nothing.

**Fix:** bind one `.alert` to `errorMessage` at the `SessionManagementView`/`CommunityViewiPad` level; add an error state + Retry to the reader VM; alert on bad/conflicting deep links ("Leave current session to join ABC123?").

### 3. "Leave Session" ends the session for everyone with no confirmation
`InSessionView.swift:201-211` — one tap. For the host this marks the session inactive for all participants (`FirebaseSessionRepository.swift:184-193`), with no `confirmationDialog`, no undo, and no wording distinction between guest-leave and host-end.
**Fix:** `.confirmationDialog` with a `.destructive` role; host copy like "End session for N participants?". Same treatment (lighter) for "End Discussion" in `DiscussionResultsView.swift:46-57`.

### 4. Every host shows up as "Host"
`CreateSessionSheet` collects the host's name but `FirebaseSessionRepository.swift:145` hardcodes `"displayName": "Host"` — the name only reaches Multipeer advertising.
**Fix:** thread `hostDisplayName` through `createSession` into the Firebase participant record. Related: empty names silently default to "Guest"/"Host" (indistinguishable duplicates), and `userId = UUID()` per launch (`SessionViewModel.swift:27`) makes an app relaunch create a ghost participant — persist the id.

### 5. Deep-link join is broken on iPad
`CommunityViewiPad`/`SessionDetailView` never read `pendingJoinCode` (only the compact-width `SessionManagementView` does), so `gatherbible://join?code=…` links do nothing on iPad. `SessionDetailView.swift:23` also omits `initialCode` when building `JoinSessionSheet`.
**Fix:** hoist the pending-code → sheet logic into a shared modifier used by both hierarchies. This is a symptom of #9 (duplicated iPhone/iPad view code).

### 6. Reader text size is capped below accessibility needs
`ReaderSettingsViewModel.swift:17,48-55` uses a fixed 12–32pt scale that ignores system Dynamic Type — users with accessibility text sizes (up to ~53pt) can't get comfortable reading sizes in the one view that matters most in a Bible app.
**Fix:** seed the scale from the scaled `.body` size via `UIFontMetrics`/`dynamicTypeSize` and treat the user's step as a delta, or extend the range when accessibility sizes are active.

### 7. Sub-44pt tap targets on primary controls
- Previous/next chapter buttons are 36×36pt (`BibleReader.swift:160,176`) — the app's most-used controls.
- Nearby-sessions "Search"/"Stop" are caption-size text buttons (`NearbySessionsView.swift:30-45`), and "Stop" styled `.secondary` looks disabled.
- Draft "Send" is `.controlSize(.small)` inside a swipe-to-delete row (`DraftDiscussionsView.swift:69-71`).
- The custom font-size slider's drag target is only its 20pt knob (`ReaderSettingsSheet.swift:109-122`) — replace with a standard `Slider`.

**Fix:** 44×44pt minimum everywhere (visual size can stay smaller with a padded `.contentShape`).

### 8. Nested `NavigationStack` in the reader
`ContentView.swift:19` wraps `BibleReader()` in a stack and `BibleReader.swift:78` creates another. Double nav bars / undefined toolbar behavior on some OS versions.
**Fix:** keep the outer stack, move title/toolbar onto the reader content.

### 9. Duplicated iPhone/iPad hierarchies are already drifting
`SessionDetailView.swift:41-93,130-174` re-implements `InSessionView`/`NotInSessionView`. Live drift bugs: iPad misses deep-links (#5), never marks "(You)" in participants (`ParticipantsDetailView.swift:28-30`), shows no Join Session quick action (`CommunityViewiPad.swift:107-123` has Create only), shows no loading state on session buttons (`SessionDetailView.swift:150-168`), and reuses the *active* discussion's response count for every completed card (`DiscussionsDetailView.swift:60` — wrong data). `CommunityView.swift:7-11` also carries an unreachable regular-width branch.
**Fix:** extract shared components (session info card, session controls, empty-state hero); keep only navigation chrome per size class.

### 10. Book/chapter picker doesn't start at the current book
`BookAndChapterPickerSheet.swift:24-43` — with 66 books, jumping from John back to John 4 means scrolling from Genesis every time.
**Fix:** `ScrollViewReader` + scroll to and pre-expand the selected book on appear; consider book search.

---

## Accessibility (beyond the top 10)

- **Status by color alone** — `ParticipantRow.swift:19-23` (green/gray dot, invisible to VoiceOver; the crown "host" icon is unlabeled) and the active-discussion dots in `DiscussionCard.swift:20-24` / `CommunityViewiPad.swift:81-84`. Fix: `.accessibilityElement(children: .combine)` with a composed label ("Sarah, host, active"), plus a non-color cue.
- **"Double tap to…" hints throughout** — `NotInSessionView.swift:69,80`, `InSessionView.swift:121,170,183,193,210`, `SessionCodeBanner.swift:65,89`, `CopyableCodeButton.swift:34`, etc. Apple says hints describe the result, never the gesture (VoiceOver adds that; Switch Control/Voice Control don't double-tap). Fix: "Starts a new reading session"-style hints.
- **Version rows aren't buttons** — `VersionPickerSheet.swift:42-46` uses `.onTapGesture` on an HStack: no button trait, no selected-state, no press feedback. Wrap in `Button` + `.isSelected` trait.
- **Chapter grid** — `BookAndChapterPickerSheet.swift:90-113`: bare "1, button" with no book/chapter context and no selected trait.
- **FormField labels aren't associated with their fields** — `FormField.swift:36` uses `.contain`; VoiceOver reads only the placeholder. Apply `.accessibilityLabel(label)` to the input or use `LabeledContent`.
- **State changes unannounced** — copy confirmations (`SessionCodeBanner`, `CopyableCodeButton`) swap labels instead of posting `AccessibilityNotification.Announcement`; `CopyableCodeButton.swift:16` reads `accessibilityReduceMotion` but never uses it.
- **Reduce Motion misuse** — `BibleReader.swift:165-184` gates *haptics* on Reduce Motion; haptics have their own system setting that `sensoryFeedback` already respects. Also both chevrons share the trigger, firing double haptics per chapter change.
- **Non-scaling fixed sizes** — `EmptyStateView.swift:15-21` (48pt icon), `StyledTextEditor.swift:13` (fixed 100pt min height), `NotInSessionView.swift:39`, `SessionDetailView.swift:136`, `SessionQRCodeView.swift:32` (fixed 250pt QR in a `.medium` detent clips at large text). Use `@ScaledMetric` (the pattern already exists in `SessionCodeBanner.swift:20`).

## Platform conventions & standard components

- **Replace `EmptyStateView` with `ContentUnavailableView`** — the app already uses the system component in four places; the custom one creates a second visual language and doesn't scale. Migrate `DraftDiscussionsView.swift:19` and `DiscussionResultsView.swift:24`.
- **Dead/duplicate reader UI** — `NavigationHeader.swift`, `HalfPillPickerView.swift`, `HalfPillShape.swift` are unused; `ReaderSettingsSheet.swift` (the *richer* font UI: slider, font grid, live preview) is never presented — the live controls are buried two levels deep in the "…" menu, where the custom-font previews don't even render (`ReaderMenu.swift:52` — UIKit-backed menus ignore custom fonts). **Recommendation:** wire `ReaderSettingsSheet` in as a first-class "Aa" toolbar/menu item and delete the dead files. Text settings are a core reader feature and deserve discoverability.
- **AirPlay hack** — `ReaderMenu.swift:92-128` hides an `AVRoutePickerView` and synthesizes a tap on its private internal button. Fragile across OS releases; expose the route picker directly as the control. The standalone `AirPlayButton` component is unused — consolidate.
- **Destructive style vs role** — `AsyncActionButton.swift:56` uses `.tint(.red)` instead of `Button(role: .destructive)` (role gets VoiceOver "destructive" announcement and correct system red). Also its `Task { await action() }` is fire-and-forget: no double-tap guard before `isLoading` flips, no error pathway.
- **Deprecated APIs** — `VersionPickerSheet.swift:22` still uses `NavigationView`; `ExternalDisplayManager.swift:24-53` relies on deprecated `UIScreen.main` + notification-grabbing — use scene-role detection (`session.role == .windowExternalDisplayNonInteractive`).
- **Sheets** — `DiscussionPromptSheet.swift:60` disables interactive dismissal even when the response field is empty (HIG: only to prevent data loss) — use `interactiveDismissDisabled(!trimmedResponse.isEmpty)`. Minor inconsistencies in detents/drag indicators across sibling sheets; `SessionQRCodeView` has an empty nav bar (title is in the body — move it to `.navigationTitle`).
- **Hardcoded `.blue`** where `Color.accentColor`/`.tint` belongs: `InSessionView.swift:135,155`, `NearbySessionsView.swift:84,102`, `DiscussionPromptSheet.swift:71`, `DiscussionCard.swift:22`, `CommunityViewiPad.swift:82`.
- **`.padding(.bottom, 100)`** to clear floating buttons (`BibleReader.swift:87`) — use `.safeAreaInset(edge: .bottom)`.

## UX friction & missing affordances

- **Joining a session** (`JoinSessionSheet.swift:92-104`): good constraints already (uppercase, 6-char limit, disabled Join until valid). Add: in-app QR scanning (VisionKit `DataScannerViewController`) instead of forcing a round-trip through the Camera app; `.keyboardType(.asciiCapable)`; `onSubmit` chaining name → code → Join; drop `.kerning(6)` on the editable field (caret misalignment); `.textContentType(.name)` + `.words` capitalization on name fields.
- **Nearby discovery is buried** — browsing doesn't auto-start when the Join sheet opens; the affordance is a caption-size "Search" text link (`NearbySessionsView.swift:38-45`). Auto-start on appear (it already stops on dismiss).
- **No ShareLink** — the only ways to invite are in-person QR and manual copy. Add `ShareLink` to `SessionQRCodeView` and the code banner. Prefer a **universal link** (https) over the `gatherbible://` custom scheme in QR payloads and invites — custom schemes can be claimed by other apps and show a weak affordance in Camera.
- **Discussion cards on iPad aren't interactive** — `DiscussionCard.swift:17-47` is a static VStack: no way to open, respond, or activate a draft from the iPad Discussions screen, and `lineLimit(2)` truncates the question with no way to read it.
- **No incoming-prompt cue** — when the host publishes a discussion, a sheet appears over the guest's reading with no haptic/sound (`SessionViewModel.swift:147-149`). The Session feature has zero haptics; add `.sensoryFeedback(.success/.impact)` for join/create/copy/prompt moments.
- **Chapter navigation** — no swipe gesture between chapters (chevrons + hidden keyboard shortcuts only); buttons don't disable at Genesis 1 / Revelation 22 (silent no-op); version button silently no-ops while versions load (`isLoadingVersions` is written but never read).
- **Reader subscriptions accumulate** — `BibleReader.swift:23-34` re-subscribes and refetches versions on every tab switch, stacking Combine sinks so session handlers run N times per event. Guard with a has-subscribed flag.
- **TV display can't show long chapters** — `TVReaderView.swift:19,32` is a ScrollView nobody can scroll; content below the fold is unreachable. Sync scroll position from the presenter or paginate. Also: pure `#000` + 48pt fixed text causes halation on TVs (use near-black + slightly off-white) and there's no host control over TV text size.
- **Stale shared `errorMessage`** — a failed join's error reappears when opening the Create sheet (`CreateSessionSheet.swift:21-23`); clear it on sheet dismiss/appear.

## Config / housekeeping

- `NSLocalNetworkUsageDescription` exists in two sources (plist + build settings) — drift risk; also reword to state the user benefit ("…so you can join a nearby group without typing a code").
- Sentry ships with `tracesSampleRate = 1.0`, profiling 1.0, and `sendDefaultPii = true` (`Gather_BibleApp.swift:23-31`) — tune before App Store release and check the privacy policy for PII collection.
- Tab selection keyed on magic strings `"Bible"`/`"Community"` (`ContentView.swift:14`) — use an enum.
- iPhone is portrait-locked; defensible for a reader, but consider landscape.

---

## Suggested sequencing

1. **Trust & data loss (do first):** findings 1–4 — error surfacing, sheet dismissal on failure, leave-session confirmation, host display name.
2. **Accessibility pass:** tap targets, color-only status, hint rewording, FormField label association, reader text-size ceiling.
3. **Consolidation:** shared session components across iPhone/iPad (fixes the iPad deep-link, "(You)", counts, and loading-state drift in one move), delete dead reader UI, adopt `ContentUnavailableView`, wire in `ReaderSettingsSheet`.
4. **Delight & polish:** QR scanning, ShareLink + universal links, haptics, swipe between chapters, picker scroll-to-current, TV display improvements.
