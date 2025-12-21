//
//  SessionSync.swift
//  Gather Bible
//
//  Firebase Realtime Database session synchronization
//

import Foundation
import FirebaseDatabase
import Combine
import os.log
import SwiftUI

// #region agent log
private let debugLogger = Logger(subsystem: "Josh-Birdwell.Gather-Bible", category: "DEBUG")
private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    var dataStr = ""
    if !data.isEmpty, let jsonData = try? JSONSerialization.data(withJSONObject: data),
       let str = String(data: jsonData, encoding: .utf8) { dataStr = " | \(str)" }
    debugLogger.notice("🔍 [DEBUG] \(location): \(message)\(dataStr)")
}
// #endregion

/// Throttle utility for limiting update frequency
class Throttle {
    private let interval: TimeInterval
    private let scheduler: DispatchQueue
    private var lastExecution: Date?
    private var pendingWork: (() -> Void)?
    
    init(interval: TimeInterval, scheduler: DispatchQueue = .global(qos: .userInitiated)) {
        self.interval = interval
        self.scheduler = scheduler
    }
    
    func run(work: @escaping () -> Void) {
        scheduler.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            
            if let lastExecution = self.lastExecution,
               now.timeIntervalSince(lastExecution) < self.interval {
                if self.pendingWork == nil {
                    self.pendingWork = work
                    let delay = self.interval - now.timeIntervalSince(lastExecution)
                    
                    self.scheduler.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else { return }
                        self.pendingWork?()
                        self.pendingWork = nil
                        self.lastExecution = Date()
                    }
                }
            } else {
                work()
                self.lastExecution = now
            }
        }
    }
}

/// Main session synchronization class
final class SessionSync: ObservableObject {
    private let db = Database.database().reference()
    private var stateRef: DatabaseReference?
    private var participantsRef: DatabaseReference?
    
    // Publishers for UI updates
    @Published var currentState: SessionState?
    @Published var participants: [SessionParticipant] = []
    @Published var followHost = true
    @Published var isScrolling = false
    @Published var isConnected = false
    
    // Throttling for host updates
    private let publishThrottle = Throttle(interval: 0.1)
    private var scrollTimer: Timer?
    
    // Current session info
    private var sessionId: String?
    private var userId: String?
    private(set) var isHost = false
    
    // Listeners
    private var stateObserver: UInt?
    private var participantsObserver: UInt?
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cleanup()
    }
    
    /// Start a new session as host
    func startSession(asHost userId: String, joinCode: String, initialBook: String, initialChapter: Int, initialVerseId: String, initialVersionId: Int = 111) async throws {
        let sessionId = UUID().uuidString
        self.sessionId = sessionId
        self.userId = userId
        self.isHost = true
        
        let initialState: [String: Any] = [
            "joinCode": joinCode,
            "hostId": userId,
            "book": initialBook,
            "chapter": initialChapter,
            "startVerseId": initialVerseId,
            "verseOffset": 0.0,
            "scrolling": false,
            "versionId": initialVersionId,
            "updatedAt": ServerValue.timestamp(),
            "active": true
        ]
        
        let sessionData: [String: Any] = [
            "sessions": [
                sessionId: [
                    "state": initialState,
                    "participants": [
                        userId: [
                            "displayName": "Host",
                            "isHost": true,
                            "active": true,
                            "lastSeen": ServerValue.timestamp()
                        ]
                    ]
                ]
            ]
        ]
        
        try await db.updateChildValues(sessionData)
        startListening(sessionId: sessionId)
        setupDisconnectHandler(sessionId: sessionId, userId: userId)
    }
    
    /// Join an existing session as guest
    func joinSession(sessionId: String, userId: String, displayName: String) async throws {
        self.sessionId = sessionId
        self.userId = userId
        self.isHost = false
        
        let participantData: [String: Any] = [
            "displayName": displayName,
            "isHost": false,
            "active": true,
            "lastSeen": ServerValue.timestamp()
        ]
        
        try await db.child("sessions").child(sessionId).child("participants").child(userId).setValue(participantData)
        startListening(sessionId: sessionId)
        setupDisconnectHandler(sessionId: sessionId, userId: userId)
    }
    
    /// Leave current session
    func leaveSession() async {
        guard let sessionId = sessionId, let userId = userId else { return }
        
        cleanup()
        
        if !isHost {
            try? await db.child("sessions").child(sessionId).child("participants").child(userId).removeValue()
        } else {
            try? await db.child("sessions").child(sessionId).child("state").child("active").setValue(false)
        }
    }
    
    /// Publish host navigation/scroll update
    func publishNavigation(book: String, chapter: Int, verseId: String, verseOffset: Double, scrolling: Bool, versionId: Int = 111) {
        // #region agent log
        debugLog("SessionSync:publishNavigation", "Called", [
            "hypothesisId": "H2",
            "isHost": isHost,
            "sessionId": sessionId ?? "nil",
            "verseOffset": verseOffset,
            "scrolling": scrolling
        ])
        // #endregion
        guard isHost, let sessionId = sessionId else {
            // #region agent log
            debugLog("SessionSync:publishNavigation", "Guard failed", [
                "hypothesisId": "H2",
                "isHost": isHost,
                "hasSessionId": sessionId != nil
            ])
            // #endregion
            return
        }
        
        if scrolling {
            scrollTimer?.invalidate()
        }
        
        isScrolling = scrolling
        
        if !scrolling {
            scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.publishScrollStop()
            }
        }
        
        publishThrottle.run { [weak self] in
            // #region agent log
            debugLog("SessionSync:throttle", "Throttle passed", ["hypothesisId": "H2", "verseOffset": verseOffset])
            // #endregion
            self?.publishUpdate(book: book, chapter: chapter, verseId: verseId, verseOffset: verseOffset, scrolling: scrolling, versionId: versionId)
        }
    }
    
    private func publishScrollStop() {
        guard isHost, let currentState = currentState else { return }
        publishUpdate(
            book: currentState.book,
            chapter: currentState.chapter,
            verseId: currentState.startVerseId,
            verseOffset: currentState.verseOffset,
            scrolling: false,
            versionId: currentState.versionId
        )
    }
    
    private func publishUpdate(book: String, chapter: Int, verseId: String, verseOffset: Double, scrolling: Bool, versionId: Int) {
        guard let sessionId = sessionId else { return }
        
        let payload: [String: Any] = [
            "book": book,
            "chapter": chapter,
            "startVerseId": verseId,
            "verseOffset": verseOffset,
            "scrolling": scrolling,
            "versionId": versionId,
            "updatedAt": ServerValue.timestamp()
        ]
        
        db.child("sessions").child(sessionId).child("state").updateChildValues(payload) { [weak self] error, _ in
            if error == nil {
                DispatchQueue.main.async {
                    self?.isScrolling = scrolling
                }
            }
        }
    }
    
    private func startListening(sessionId: String) {
        isConnected = true
        
        stateRef = db.child("sessions").child(sessionId).child("state")
        stateRef?.keepSynced(true)
        
        stateObserver = stateRef?.observe(.value) { [weak self] snapshot in
            // #region agent log
            debugLog("SessionSync:observer", "Firebase state received", [
                "hypothesisId": "H3",
                "hasValue": snapshot.value != nil,
                "valueType": String(describing: type(of: snapshot.value))
            ])
            // #endregion
            guard let self = self,
                  let dict = snapshot.value as? [String: Any],
                  let state = SessionState(from: dict) else {
                // #region agent log
                debugLog("SessionSync:observer", "Failed to parse state", [
                    "hypothesisId": "H3",
                    "dictKeys": (snapshot.value as? [String: Any])?.keys.map { $0 } ?? []
                ])
                // #endregion
                return
            }
            
            // #region agent log
            debugLog("SessionSync:observer", "Parsed state successfully", [
                "hypothesisId": "H3",
                "verseOffset": state.verseOffset,
                "book": state.book,
                "chapter": state.chapter
            ])
            // #endregion
            
            DispatchQueue.main.async {
                self.currentState = state
            }
        }
        
        participantsRef = db.child("sessions").child(sessionId).child("participants")
        
        participantsObserver = participantsRef?.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            var participants: [SessionParticipant] = []
            
            for child in snapshot.children {
                guard let snapshot = child as? DataSnapshot,
                      let dict = snapshot.value as? [String: Any],
                      let participant = SessionParticipant(userId: snapshot.key, from: dict) else {
                    continue
                }
                participants.append(participant)
            }
            
            DispatchQueue.main.async {
                self.participants = participants
            }
        }
    }
    
    private func setupDisconnectHandler(sessionId: String, userId: String) {
        let participantRef = db.child("sessions").child(sessionId).child("participants").child(userId)
        participantRef.onDisconnectUpdateChildValues(["active": false])
        
        if isHost {
            let stateRef = db.child("sessions").child(sessionId).child("state")
            stateRef.onDisconnectUpdateChildValues(["active": false])
        }
    }
    
    private func cleanup() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        
        if let stateObserver = stateObserver {
            stateRef?.removeObserver(withHandle: stateObserver)
        }
        if let participantsObserver = participantsObserver {
            participantsRef?.removeObserver(withHandle: participantsObserver)
        }
        
        stateRef?.keepSynced(false)
        stateRef = nil
        participantsRef = nil
        stateObserver = nil
        participantsObserver = nil
        isConnected = false
    }
    
    func toggleFollowHost() {
        guard !isHost else { return }
        followHost.toggle()
    }
    
    func updateHostStatus(isHost: Bool) {
        self.isHost = isHost
        if isHost, let sessionId = sessionId, let userId = userId {
            setupDisconnectHandler(sessionId: sessionId, userId: userId)
        }
    }
    
    var currentSessionId: String? { sessionId }
}