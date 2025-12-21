# Real-time Session & Scrolling Sync (Firebase Realtime Database)

## Goal
Host shares a Bible reading session via join code. Guests follow host’s chapter navigation and scroll position in near real time. Presence shows who’s active.

------------------------------------------------
## Data model (RTDB)
```
/sessions/{sessionId}/state:
  joinCode: string            // 6-char alphanumeric (2B combos)
  hostId: string
  book: string
  chapter: int
  startVerseId: string       // e.g. "GEN.1.5" – first visible verse
  verseOffset: double        // 0.0–1.0 within that verse
  scrolling: bool            // false when host hasn’t scrolled for 300ms
  updatedAt: server timestamp
  active: bool               // false when TTL marks stale

/sessions/{sessionId}/participants/{userId}:
  displayName: string
  isHost: bool
  active: bool               // local “probably online” + 10s grace
  lastSeen: server timestamp

/sessions/{sessionId}/metrics:
  rttMs: int                 // written by cloud function
  updatesPerMin: int
  driftEvents: int           // incremented by guests when manual scroll
```
- Use `keepSynced(true)` only on the session currently visible.
- Presence: `onDisconnectSetValue(false)` after 10s grace; heartbeat every 20–30s.

------------------------------------------------
## Security rules (deploy these!)
```json
{
  "rules": {
    "sessions": {
      "$sessionId": {
        "state": {
          ".write": "auth.uid == root.child('sessions/'+$sessionId+'/state/hostId').val()",
          ".read": true
        },
        "participants": {
          "$uid": {
            ".write": "$uid == auth.uid",
            ".read": true
          }
        },
        "metrics": { ".write": false, ".read": true }
      }
    }
  }
}
```
------------------------------------------------
## Cloud Functions (Node 20)
1. **lookupJoinCode** (callable, rate-limited 20/min IP):
   - Input: `joinCode`
   - Returns: `sessionId` or `NOT_FOUND`.
2. **markStaleSessions** (scheduled every 5min):
   - If `updatedAt < now-5min` → set `active=false`.
3. **recordMetrics** (RTDB onWrite trigger on `/state`):
   - Compute RTT: `now - updatedAt` when written by host.
   - Increment `updatesPerMin` counter.

------------------------------------------------
## Host flow
1) Create session doc under `/sessions/{sessionId}` with 6-char `joinCode`, `hostId=uid`, initial `book`/`chapter`, `startVerseId=first verse`, `verseOffset=0`, `scrolling=false`, `active=true`.
2) Show code + share link; “End session” button sets `active=false`.
3) Publish updates:
   - Chapter/book changes → write immediately, keep last `verseOffset`.
   - While scrolling throttle to 8–10Hz, delta >0.01 verse.
   - 300ms after last delta → write `scrolling=false`.
4) Queue publishes while offline (`FirebasePersistence` enabled); show “Waiting to reconnect…” banner.

------------------------------------------------
## Guest flow
1) Enter joinCode → call `lookupJoinCode` → get `sessionId`.
2) Subscribe to `/state` and `/participants`.
3) On state update (if `followHost=true`):
   - If `book` or `chapter` changed → navigate, then animate to `startVerseId` + `verseOffset` (150–250ms easeOut).
   - If only `verseOffset` changed → animate to new offset.
4) Manual scroll → pause following for 2s; show “Return to host” chip; on tap re-enable and animate to current host position.
5) Offline: hydrate last persisted `state` from disk; apply updates when reconnected.

------------------------------------------------
## Scroll-sync accuracy (verse-level)
- Store `(startVerseId, verseOffset)` instead of normalized ratio to handle dynamic verse heights across devices.
- Host taps “Next chapter” → keep same `verseOffset` if possible; guest clamps to chapter height.
- Send `scrolling=false` so guests know when to stop animating.

------------------------------------------------
## Presence & hand-off
- Grace period: local `active=true` until 10s after socket drop; heartbeat every 20s.
- Host leave policy (choose ONE and implement):
  - **Option A**: first guest to tap “Claim host” button runs RTDB transaction → becomes host.
  - **Option B**: session dies; guests see “Host left” banner + “Start your own session” CTA.
- UI shows active participant count and list; avatars don’t flicker on reconnect.

------------------------------------------------
## Performance & bandwidth
- Payload ≤ 200B: `{startVerseId, verseOffset, scrolling, updatedAt}`.
- Throttle host publishes; debounce guest updates 50ms.
- `keepSynced(true)` only for the visible session; disable on exit.

------------------------------------------------
## Offline / caching
- Persist last `state` to `UserDefaults`/SQLite; hydrate on cold start.
- Firebase disk persistence enabled; queue host writes while offline.

------------------------------------------------
## Analytics & debug
- Metrics node written by Cloud Function: RTT, updates/min, drift events.
- Hidden “Copy debug JSON” button exports last 20 `state` snapshots for support.

------------------------------------------------
## Swift sketch (pseudo) – updated
```swift
final class SessionSync: ObservableObject {
    private let db = Database.database().reference()
    private var stateRef: DatabaseReference?
    @Published var followHost = true
    private let throttle = Throttle(interval: .milliseconds(100), scheduler: DispatchQueue.global())

    func startSession(sessionId: String) {
        stateRef = db.child("sessions/\(sessionId)/state")
        stateRef?.keepSynced(true)
        listen()
    }

    func publish(verseId: String, offset: Double, book: String, chapter: Int, scrolling: Bool) {
        guard let stateRef else { return }
        let payload: [String: Any] = [
            "startVerseId": verseId,
            "verseOffset": offset,
            "book": book,
            "chapter": chapter,
            "scrolling": scrolling,
            "updatedAt": ServerValue.timestamp()
        ]
        throttle.run { stateRef.updateChildValues(payload) }
    }

    private func listen() {
        stateRef?.observe(.value) { [weak self] snapshot in
            guard let self, self.followHost,
                  let dict = snapshot.value as? [String: Any],
                  let vid = dict["startVerseId"] as? String,
                  let offset = dict["verseOffset"] as? Double else { return }
            // navigate to vid then animate to offset
        }
    }
}
```
------------------------------------------------
## Edge cases – handled
- Offline/lag: last state cached; queue host writes; guests apply latest on reconnect.
- Host leaves: explicit hand-off or session inactive; guests stop following.
- Validation: `lookupJoinCode` rate-limited; rules enforce host-only writes.
- Dynamic verse heights: verseId + offset keeps everyone on the same verse.

------------------------------------------------
## Why RTDB is still enough
- WebSockets/long-poll give ~20ms latency; throttling + small payloads keep bandwidth low.
- Cloud Functions cover TTL, metrics, and rate-limiting without extra infra.
- Verse-level sync + grace-period presence + offline cache deliver native feel on iOS/Android.