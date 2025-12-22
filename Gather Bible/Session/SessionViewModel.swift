//
//  SessionViewModel.swift
//  Gather Bible
//
//  View model for managing Bible reading sessions
//

import Foundation
import SwiftUI
import Combine
import FirebaseFunctions

/// View model for managing Bible reading sessions
@MainActor
class SessionViewModel: ObservableObject {
    @Published var sessionSync: SessionSync?
    
    // UI State
    @Published var isInSession = false
    @Published var isHost = false
    @Published var joinCode = ""
    @Published var participants: [SessionParticipant] = []
    @Published var currentBook = "GEN"
    @Published var currentChapter = 1
    @Published var currentVersionId = 111
    @Published var followHost = true
    @Published var isScrolling = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // Session info
    @Published var sessionId: String?
    @Published var userId: String = UUID().uuidString
    @Published var isSessionInactive = false
    @Published var currentState: SessionState?
    
    private var cancellables = Set<AnyCancellable>()
    private let functions = Functions.functions()
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        $sessionSync
            .compactMap { $0 }
            .sink { [weak self] sync in
                self?.observeSessionSync(sync)
            }
            .store(in: &cancellables)
    }
    
    private func observeSessionSync(_ sync: SessionSync) {
        sync.$participants
            .receive(on: DispatchQueue.main)
            .assign(to: &$participants)
        
        sync.$followHost
            .receive(on: DispatchQueue.main)
            .assign(to: &$followHost)
        
        sync.$isScrolling
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScrolling)
        
        sync.$currentState
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.currentState = state
                self?.currentBook = state.book
                self?.currentChapter = state.chapter
                self?.currentVersionId = state.versionId
                self?.isSessionInactive = !state.active
            }
            .store(in: &cancellables)
    }
    
    /// Create a new session as host
    func createSession(initialBook: String = "GEN", initialChapter: Int = 1) async {
        print("🔵 [Session] createSession() called")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔵 [Session] Calling generateUniqueJoinCode...")
            let result = try await functions.httpsCallable("generateUniqueJoinCode").call()
            print("🔵 [Session] Cloud function returned: \(result.data)")
            
            guard let data = result.data as? [String: Any],
                  let joinCode = data["joinCode"] as? String else {
                print("🔴 [Session] Invalid response - could not parse joinCode")
                throw SessionError.invalidResponse
            }
            
            print("🔵 [Session] Got join code: \(joinCode)")
            
            let sync = SessionSync()
            self.sessionSync = sync
            
            print("🔵 [Session] Starting session in Firebase...")
            try await sync.startSession(
                asHost: userId,
                joinCode: joinCode,
                initialBook: initialBook,
                initialChapter: initialChapter,
                initialVerseId: "\(initialBook).\(initialChapter).1"
            )
            
            print("🟢 [Session] Session created successfully!")
            self.joinCode = joinCode
            self.isHost = true
            self.isInSession = true
            self.sessionId = sync.currentSessionId
            print("🟢 [Session] State updated - isInSession: \(isInSession), joinCode: \(joinCode)")
            
        } catch {
            print("🔴 [Session] Error: \(error)")
            handleError(error)
        }
        
        isLoading = false
        print("🔵 [Session] createSession() finished, isLoading: \(isLoading)")
    }
    
    /// Join an existing session
    func joinSession(joinCode: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await functions.httpsCallable("lookupJoinCode").call(["joinCode": joinCode])
            
            guard let data = result.data as? [String: Any],
                  let status = data["status"] as? String else {
                throw SessionError.invalidResponse
            }
            
            if status == "NOT_FOUND" {
                throw SessionError.sessionNotFound
            }
            
            guard let sessionId = data["sessionId"] as? String else {
                throw SessionError.invalidResponse
            }
            
            let sync = SessionSync()
            self.sessionSync = sync
            
            try await sync.joinSession(
                sessionId: sessionId,
                userId: userId,
                displayName: displayName
            )
            
            self.joinCode = joinCode
            self.isHost = false
            self.isInSession = true
            self.sessionId = sessionId
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Leave current session
    func leaveSession() async {
        isLoading = true
        
        await sessionSync?.leaveSession()
        
        sessionSync = nil
        isInSession = false
        isHost = false
        joinCode = ""
        participants = []
        sessionId = nil
        
        isLoading = false
    }
    
    /// Toggle follow host mode (for guests)
    func toggleFollowHost() {
        sessionSync?.toggleFollowHost()
    }
    
    /// Update Bible position (called by Bible reader when host scrolls)
    func publishNavigation(book: String, chapter: Int, verseId: String, verseOffset: Double, scrolling: Bool) {
        sessionSync?.publishNavigation(
            book: book,
            chapter: chapter,
            verseId: verseId,
            verseOffset: verseOffset,
            scrolling: scrolling,
            versionId: currentVersionId
        )
    }
    
    /// Claim host role when current host is inactive
    func claimHost() async {
        guard let sessionId = sessionId, !isHost else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let displayName = participants.first { $0.id == userId }?.displayName ?? "Host"
            
            let result = try await functions.httpsCallable("claimHost").call([
                "sessionId": sessionId,
                "userId": userId,
                "displayName": displayName
            ])
            
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool, success else {
                throw SessionError.claimHostFailed
            }
            
            self.isHost = true
            self.isSessionInactive = false
            sessionSync?.updateHostStatus(isHost: true)
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    var activeParticipantCount: Int {
        participants.filter { $0.active }.count
    }
    
    var hostParticipant: SessionParticipant? {
        participants.first { $0.isHost }
    }
    
    var isCurrentHostInactive: Bool {
        guard let host = hostParticipant else { return true }
        if !host.active { return true }
        if let lastSeen = host.lastSeen {
            return lastSeen < Date().timeIntervalSince1970 - 120
        }
        return true
    }
    
    var sessionStatusText: String {
        if !isInSession {
            return "Not in session"
        } else if isHost {
            return "Hosting session • Code: \(joinCode)"
        } else if isSessionInactive {
            return "Session Inactive • Code: \(joinCode)"
        } else {
            return "Joined session • Code: \(joinCode)"
        }
    }
    
    private func handleError(_ error: Error) {
        if let error = error as? SessionError {
            errorMessage = error.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred."
        }
    }
}

/// Session-related errors
enum SessionError: LocalizedError {
    case invalidResponse
    case sessionNotFound
    case networkError
    case permissionDenied
    case claimHostFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .sessionNotFound: return "Session not found."
        case .networkError: return "Network error."
        case .permissionDenied: return "Permission denied."
        case .claimHostFailed: return "Failed to claim host role."
        }
    }
}
