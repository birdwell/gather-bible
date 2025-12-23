//
//  SessionSync.swift
//  Gather Bible
//
//  Firebase Realtime Database session synchronization
//

import Combine
import FirebaseDatabase
import Foundation
import SwiftUI

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
        now.timeIntervalSince(lastExecution) < self.interval
      {
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

  // Discussion publishers
  @Published var activeDiscussion: Discussion?
  @Published var discussionResponses: [DiscussionResponse] = []
  @Published var discussions: [Discussion] = []

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
  private var activeDiscussionObserver: UInt?
  private var discussionResponsesObserver: UInt?
  private var discussionsObserver: UInt?

  // Discussion references
  private var activeDiscussionRef: DatabaseReference?
  private var discussionResponsesRef: DatabaseReference?
  private var discussionsRef: DatabaseReference?

  private var cancellables = Set<AnyCancellable>()

  deinit {
    cleanup()
  }

  /// Start a new session as host
  func startSession(
    asHost userId: String, joinCode: String, initialBook: String, initialChapter: Int,
    initialVerseId: String, initialVersionId: Int = 111
  ) async throws {
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
      "active": true,
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
              "lastSeen": ServerValue.timestamp(),
            ]
          ],
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
      "lastSeen": ServerValue.timestamp(),
    ]

    try await db.child("sessions").child(sessionId).child("participants").child(userId)
      .setValue(participantData)
    startListening(sessionId: sessionId)
    setupDisconnectHandler(sessionId: sessionId, userId: userId)
  }

  /// Leave current session
  func leaveSession() async {
    guard let sessionId = sessionId, let userId = userId else { return }

    cleanup()

    if !isHost {
      do {
        try await db.child("sessions").child(sessionId).child("participants").child(userId)
          .removeValue()
      } catch {
        // Best-effort cleanup; log and continue
        #if DEBUG
          print("[SessionSync] Failed to remove participant on leave: \(error)")
        #endif
      }
    } else {
      do {
        try await db.child("sessions").child(sessionId).child("state").child("active")
          .setValue(false)
      } catch {
        // Best-effort host deactivation; log and continue
        #if DEBUG
          print("[SessionSync] Failed to mark session inactive on leave: \(error)")
        #endif
      }
    }
  }

  /// Publish host navigation/scroll update
  func publishNavigation(
    book: String, chapter: Int, verseId: String, verseOffset: Double, scrolling: Bool,
    versionId: Int = 111
  ) {
    guard isHost else { return }

    if scrolling {
      scrollTimer?.invalidate()
    }

    isScrolling = scrolling

    if !scrolling {
      scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) {
        [weak self] _ in
        self?.publishScrollStop()
      }
    }

    publishThrottle.run { [weak self] in
      self?.publishUpdate(
        book: book, chapter: chapter, verseId: verseId, verseOffset: verseOffset,
        scrolling: scrolling, versionId: versionId)
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

  private func publishUpdate(
    book: String, chapter: Int, verseId: String, verseOffset: Double, scrolling: Bool,
    versionId: Int
  ) {
    guard let sessionId = sessionId else { return }

    let payload: [String: Any] = [
      "book": book,
      "chapter": chapter,
      "startVerseId": verseId,
      "verseOffset": verseOffset,
      "scrolling": scrolling,
      "versionId": versionId,
      "updatedAt": ServerValue.timestamp(),
    ]

    db.child("sessions").child(sessionId).child("state").updateChildValues(payload) {
      [weak self] error, _ in
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
      guard let self = self,
        let dict = snapshot.value as? [String: Any],
        let state: SessionState = SessionState(from: dict)
      else {
        return
      }

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
          let participant = SessionParticipant(userId: snapshot.key, from: dict)
        else {
          continue
        }
        participants.append(participant)
      }

      DispatchQueue.main.async {
        self.participants = participants
      }
    }

    // Listen to discussions
    discussionsRef = db.child("sessions").child(sessionId).child("discussions")

    discussionsObserver = discussionsRef?.observe(.value) { [weak self] snapshot in
      guard let self = self else { return }

      var discussions: [Discussion] = []

      for child in snapshot.children {
        guard let snapshot = child as? DataSnapshot,
          let dict = snapshot.value as? [String: Any],
          let discussion = Discussion(id: snapshot.key, from: dict)
        else {
          continue
        }
        discussions.append(discussion)
      }

      DispatchQueue.main.async {
        self.discussions = discussions
        // Update active discussion if there is one
        self.activeDiscussion = discussions.first { $0.status == .active }
      }
    }

    // Listen to active discussion responses
    activeDiscussionRef = db.child("sessions").child(sessionId).child("activeDiscussionId")

    activeDiscussionObserver = activeDiscussionRef?.observe(.value) { [weak self] snapshot in
      guard let self = self,
        let discussionId = snapshot.value as? String,
        !discussionId.isEmpty
      else {
        DispatchQueue.main.async {
          self?.discussionResponses = []
        }
        return
      }

      // Start listening to responses for this discussion
      self.startListeningToResponses(sessionId: sessionId, discussionId: discussionId)
    }
  }

  private func setupDisconnectHandler(sessionId: String, userId: String) {
    let participantRef = db.child("sessions").child(sessionId).child("participants").child(
      userId)
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
    if let discussionsObserver = discussionsObserver {
      discussionsRef?.removeObserver(withHandle: discussionsObserver)
    }
    if let activeDiscussionObserver = activeDiscussionObserver {
      activeDiscussionRef?.removeObserver(withHandle: activeDiscussionObserver)
    }
    if let discussionResponsesObserver = discussionResponsesObserver {
      discussionResponsesRef?.removeObserver(withHandle: discussionResponsesObserver)
    }

    stateRef?.keepSynced(false)
    stateRef = nil
    participantsRef = nil
    discussionsRef = nil
    activeDiscussionRef = nil
    discussionResponsesRef = nil
    stateObserver = nil
    participantsObserver = nil
    discussionsObserver = nil
    activeDiscussionObserver = nil
    discussionResponsesObserver = nil
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

  // MARK: - Discussion Methods

  private func startListeningToResponses(sessionId: String, discussionId: String) {
    // Remove existing observer if any
    if let discussionResponsesObserver = discussionResponsesObserver {
      discussionResponsesRef?.removeObserver(withHandle: discussionResponsesObserver)
    }

    discussionResponsesRef = db.child("sessions").child(sessionId).child("discussionResponses")
      .child(discussionId)

    discussionResponsesObserver = discussionResponsesRef?.observe(.value) { [weak self] snapshot in
      guard let self = self else { return }

      var responses: [DiscussionResponse] = []

      for child in snapshot.children {
        guard let snapshot = child as? DataSnapshot,
          let dict = snapshot.value as? [String: Any],
          let response = DiscussionResponse(
            participantId: snapshot.key, discussionId: discussionId, from: dict)
        else {
          continue
        }
        responses.append(response)
      }

      DispatchQueue.main.async {
        self.discussionResponses = responses
      }
    }
  }

  /// Create a new discussion (host only)
  func createDiscussion(question: String, publishImmediately: Bool) async throws -> String {
    guard isHost, let sessionId = sessionId else {
      throw SessionError.permissionDenied
    }

    let discussionId = UUID().uuidString
    let status: DiscussionStatus = publishImmediately ? .active : .draft
    let now = Date().timeIntervalSince1970 * 1000

    var discussionData: [String: Any] = [
      "sessionId": sessionId,
      "question": question,
      "status": status.rawValue,
      "createdAt": now,
    ]

    if publishImmediately {
      discussionData["activatedAt"] = now
    }

    try await db.child("sessions").child(sessionId).child("discussions").child(discussionId)
      .setValue(discussionData)

    if publishImmediately {
      try await db.child("sessions").child(sessionId).child("activeDiscussionId").setValue(
        discussionId)
    }

    return discussionId
  }

  /// Publish a draft discussion (host only)
  func publishDiscussion(discussionId: String) async throws {
    guard isHost, let sessionId = sessionId else {
      throw SessionError.permissionDenied
    }

    let now = Date().timeIntervalSince1970 * 1000

    let updates: [String: Any] = [
      "sessions/\(sessionId)/discussions/\(discussionId)/status": DiscussionStatus.active.rawValue,
      "sessions/\(sessionId)/discussions/\(discussionId)/activatedAt": now,
      "sessions/\(sessionId)/activeDiscussionId": discussionId,
    ]

    try await db.updateChildValues(updates)
  }

  /// Submit a response to a discussion (guest only)
  func submitDiscussionResponse(discussionId: String, response: String, participantName: String)
    async throws
  {
    guard let sessionId = sessionId, let userId = userId else {
      throw SessionError.permissionDenied
    }

    let responseData: [String: Any] = [
      "participantName": participantName,
      "response": response,
      "submittedAt": Date().timeIntervalSince1970 * 1000,
    ]

    try await db.child("sessions").child(sessionId).child("discussionResponses").child(discussionId)
      .child(userId).setValue(responseData)
  }

  /// Complete/close a discussion (host only)
  func completeDiscussion(discussionId: String) async throws {
    guard isHost, let sessionId = sessionId else {
      throw SessionError.permissionDenied
    }

    let updates: [String: Any] = [
      "sessions/\(sessionId)/discussions/\(discussionId)/status": DiscussionStatus.completed
        .rawValue,
      "sessions/\(sessionId)/activeDiscussionId": NSNull(),
    ]

    try await db.updateChildValues(updates)
  }

  /// Delete a draft discussion (host only)
  func deleteDiscussion(discussionId: String) async throws {
    guard isHost, let sessionId = sessionId else {
      throw SessionError.permissionDenied
    }

    try await db.child("sessions").child(sessionId).child("discussions").child(discussionId)
      .removeValue()
  }
}
