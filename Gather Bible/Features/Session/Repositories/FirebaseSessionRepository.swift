//
//  FirebaseSessionRepository.swift
//  Gather Bible
//
//  Firebase implementation of SessionRepository
//

import Combine
import FirebaseDatabase
import FirebaseFunctions
import Foundation
import Sentry

final class FirebaseSessionRepository: SessionRepository {
  // MARK: - Firebase

  private let db: DatabaseReference
  private let functions: Functions

  // MARK: - Publishers

  private let currentStateSubject = CurrentValueSubject<SessionState?, Never>(nil)
  private let participantsSubject = CurrentValueSubject<[SessionParticipant], Never>([])
  private let discussionsSubject = CurrentValueSubject<[Discussion], Never>([])
  private let discussionResponsesSubject = CurrentValueSubject<[DiscussionResponse], Never>([])

  var currentStatePublisher: AnyPublisher<SessionState?, Never> {
    currentStateSubject.eraseToAnyPublisher()
  }

  var participantsPublisher: AnyPublisher<[SessionParticipant], Never> {
    participantsSubject.eraseToAnyPublisher()
  }

  var discussionsPublisher: AnyPublisher<[Discussion], Never> {
    discussionsSubject.eraseToAnyPublisher()
  }

  var discussionResponsesPublisher: AnyPublisher<[DiscussionResponse], Never> {
    discussionResponsesSubject.eraseToAnyPublisher()
  }

  // MARK: - Firebase References

  private var stateRef: DatabaseReference?
  private var participantsRef: DatabaseReference?
  private var discussionsRef: DatabaseReference?
  private var activeDiscussionRef: DatabaseReference?
  private var discussionResponsesRef: DatabaseReference?

  // MARK: - Firebase Observers

  private var stateObserver: UInt?
  private var participantsObserver: UInt?
  private var discussionsObserver: UInt?
  private var activeDiscussionObserver: UInt?
  private var discussionResponsesObserver: UInt?

  // MARK: - Throttling

  private let publishThrottle = Throttle(interval: 0.1)

  // MARK: - Init

  init() {
    self.db = Database.database().reference()
    self.functions = Functions.functions()
  }

  // MARK: - Session Lifecycle

  func generateJoinCode() async throws -> String {
    do {
      let result = try await functions.httpsCallable("generateUniqueJoinCode").call()

      guard let data = result.data as? [String: Any],
        let joinCode = data["joinCode"] as? String
      else {
        throw SessionRepositoryError.invalidResponse
      }

      return joinCode
    } catch {
      SentrySDK.capture(error: error) { scope in
        scope.setTag(value: "generateJoinCode", key: "cloudFunction")
      }
      throw error
    }
  }

  func lookupSession(joinCode: String) async throws -> String {
    do {
      let result = try await functions.httpsCallable("lookupJoinCode").call(["joinCode": joinCode])

      guard let data = result.data as? [String: Any],
        let status = data["status"] as? String
      else {
        throw SessionRepositoryError.invalidResponse
      }

      if status == "NOT_FOUND" {
        throw data["reason"] as? String == "ENDED"
          ? SessionRepositoryError.sessionEnded : SessionRepositoryError.sessionNotFound
      }

      guard let sessionId = data["sessionId"] as? String else {
        throw SessionRepositoryError.invalidResponse
      }

      return sessionId
    } catch {
      SentrySDK.capture(error: error) { scope in
        scope.setTag(value: "lookupJoinCode", key: "cloudFunction")
        scope.setExtra(value: joinCode, key: "joinCode")
      }
      throw error
    }
  }

  func createSession(
    sessionId: String,
    userId: String,
    joinCode: String,
    hostDisplayName: String,
    initialBook: String,
    initialChapter: Int
  ) async throws {
    let sessionData = Self.sessionCreationUpdate(
      sessionId: sessionId,
      userId: userId,
      joinCode: joinCode,
      hostDisplayName: hostDisplayName,
      initialBook: initialBook,
      initialChapter: initialChapter
    )

    try await db.updateChildValues(sessionData)
  }

  /// The root-level update that creates a session. The key must be the session's own
  /// path: writing a `sessions` key here would replace every other session.
  static func sessionCreationUpdate(
    sessionId: String,
    userId: String,
    joinCode: String,
    hostDisplayName: String,
    initialBook: String,
    initialChapter: Int
  ) -> [String: Any] {
    let initialState: [String: Any] = [
      "joinCode": joinCode,
      "hostId": userId,
      "book": initialBook,
      "chapter": initialChapter,
      "startVerseId": "\(initialBook).\(initialChapter).1",
      "verseOffset": 0.0,
      "scrolling": false,
      "versionId": 111,
      "updatedAt": ServerValue.timestamp(),
      "active": true,
    ]

    return [
      "sessions/\(sessionId)": [
        "state": initialState,
        "participants": [
          userId: [
            "displayName": hostDisplayName,
            "isHost": true,
            "active": true,
            "lastSeen": ServerValue.timestamp(),
          ]
        ],
      ]
    ]
  }

  func joinSession(
    sessionId: String,
    userId: String,
    displayName: String
  ) async throws {
    let participantData: [String: Any] = [
      "displayName": displayName,
      "isHost": false,
      "active": true,
      "lastSeen": ServerValue.timestamp(),
    ]

    try await db.child("sessions").child(sessionId).child("participants").child(userId)
      .setValue(participantData)
  }

  func leaveSession(sessionId: String, userId: String, isHost: Bool) async throws {
    if isHost, try await endSessionIfStillHost(sessionId: sessionId, userId: userId) {
      return
    }

    let participantRef = db.child("sessions").child(sessionId).child("participants").child(userId)
    // Otherwise a later disconnect writes `active` back into the removed record.
    try await participantRef.cancelDisconnectOperations()
    try await participantRef.removeValue()
  }

  /// Ends the session only if the server still lists this user as host, so a former
  /// host with stale state can't end a session someone else took over.
  private func endSessionIfStillHost(sessionId: String, userId: String) async throws -> Bool {
    let stateRef = db.child("sessions").child(sessionId).child("state")

    return try await withCheckedThrowingContinuation { continuation in
      stateRef.runTransactionBlock(
        { @Sendable data in
          // The first pass can see an empty cache. Passing it on makes the server
          // re-run this with the real data.
          guard var state = data.value as? [String: Any] else {
            return .success(withValue: data)
          }
          guard state["hostId"] as? String == userId else { return .abort() }

          // `endedAt` tells guests this was deliberate. A dropped host connection
          // only clears `active`, so guests can stay and claim host.
          state["active"] = false
          state["endedAt"] = ServerValue.timestamp()
          data.value = state
          return .success(withValue: data)
        },
        andCompletionBlock: { @Sendable error, committed, _ in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: committed)
          }
        }
      )
    }
  }

  func startListening(sessionId: String) {
    stateRef = db.child("sessions").child(sessionId).child("state")
    stateRef?.keepSynced(true)

    stateObserver = stateRef?.observe(.value) { [weak self] snapshot in
      guard let dict = snapshot.value as? [String: Any],
        let state = SessionState(from: dict)
      else {
        return
      }
      self?.currentStateSubject.send(state)
    }

    participantsRef = db.child("sessions").child(sessionId).child("participants")

    participantsObserver = participantsRef?.observe(.value) { [weak self] snapshot in
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
      self?.participantsSubject.send(participants)
    }

    discussionsRef = db.child("sessions").child(sessionId).child("discussions")

    discussionsObserver = discussionsRef?.observe(.value) { [weak self] snapshot in
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
      self?.discussionsSubject.send(discussions)
    }

    activeDiscussionRef = db.child("sessions").child(sessionId).child("activeDiscussionId")

    activeDiscussionObserver = activeDiscussionRef?.observe(.value) { [weak self] snapshot in
      guard let discussionId = snapshot.value as? String,
        !discussionId.isEmpty
      else {
        self?.discussionResponsesSubject.send([])
        return
      }
      self?.startListeningToResponses(sessionId: sessionId, discussionId: discussionId)
    }
  }

  private func startListeningToResponses(sessionId: String, discussionId: String) {
    if let discussionResponsesObserver = discussionResponsesObserver {
      discussionResponsesRef?.removeObserver(withHandle: discussionResponsesObserver)
    }

    discussionResponsesRef = db.child("sessions").child(sessionId).child("discussionResponses")
      .child(discussionId)

    discussionResponsesObserver = discussionResponsesRef?.observe(.value) { [weak self] snapshot in
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
      self?.discussionResponsesSubject.send(responses)
    }
  }

  func stopListening() {
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

    currentStateSubject.send(nil)
    participantsSubject.send([])
    discussionsSubject.send([])
    discussionResponsesSubject.send([])
  }

  func setupDisconnectHandler(sessionId: String, userId: String, isHost: Bool) {
    let participantRef = db.child("sessions").child(sessionId).child("participants").child(userId)
    participantRef.onDisconnectUpdateChildValues(["active": false])

    if isHost {
      let stateRef = db.child("sessions").child(sessionId).child("state")
      stateRef.onDisconnectUpdateChildValues(["active": false])
    }
  }

  // MARK: - Navigation

  func publishNavigation(
    sessionId: String,
    book: String,
    chapter: Int,
    verseId: String,
    verseOffset: Double,
    scrolling: Bool,
    versionId: Int
  ) {
    publishThrottle.run { [weak self] in
      self?.publishUpdate(
        sessionId: sessionId,
        book: book,
        chapter: chapter,
        verseId: verseId,
        verseOffset: verseOffset,
        scrolling: scrolling,
        versionId: versionId
      )
    }
  }

  private func publishUpdate(
    sessionId: String,
    book: String,
    chapter: Int,
    verseId: String,
    verseOffset: Double,
    scrolling: Bool,
    versionId: Int
  ) {
    let payload: [String: Any] = [
      "book": book,
      "chapter": chapter,
      "startVerseId": verseId,
      "verseOffset": verseOffset,
      "scrolling": scrolling,
      "versionId": versionId,
      "updatedAt": ServerValue.timestamp(),
    ]

    db.child("sessions").child(sessionId).child("state").updateChildValues(payload)
  }

  // MARK: - Host Claiming

  func claimHost(sessionId: String, userId: String, displayName: String) async throws {
    let result = try await functions.httpsCallable("claimHost").call([
      "sessionId": sessionId,
      "userId": userId,
      "displayName": displayName,
    ])

    guard let data = result.data as? [String: Any],
      let success = data["success"] as? Bool, success
    else {
      throw SessionRepositoryError.claimHostFailed
    }
  }

  // MARK: - Discussions

  func createDiscussion(
    sessionId: String,
    question: String,
    publishImmediately: Bool
  ) async throws -> String {
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

  func publishDiscussion(sessionId: String, discussionId: String) async throws {
    let now = Date().timeIntervalSince1970 * 1000

    let updates: [String: Any] = [
      "sessions/\(sessionId)/discussions/\(discussionId)/status": DiscussionStatus.active.rawValue,
      "sessions/\(sessionId)/discussions/\(discussionId)/activatedAt": now,
      "sessions/\(sessionId)/activeDiscussionId": discussionId,
    ]

    try await db.updateChildValues(updates)
  }

  func submitDiscussionResponse(
    sessionId: String,
    discussionId: String,
    userId: String,
    response: String,
    participantName: String
  ) async throws {
    let responseData: [String: Any] = [
      "participantName": participantName,
      "response": response,
      "submittedAt": Date().timeIntervalSince1970 * 1000,
    ]

    try await db.child("sessions").child(sessionId).child("discussionResponses")
      .child(discussionId)
      .child(userId).setValue(responseData)
  }

  func completeDiscussion(sessionId: String, discussionId: String) async throws {
    let updates: [String: Any] = [
      "sessions/\(sessionId)/discussions/\(discussionId)/status": DiscussionStatus.completed
        .rawValue,
      "sessions/\(sessionId)/activeDiscussionId": NSNull(),
    ]

    try await db.updateChildValues(updates)
  }

  func deleteDiscussion(sessionId: String, discussionId: String) async throws {
    try await db.child("sessions").child(sessionId).child("discussions").child(discussionId)
      .removeValue()
  }
}

// MARK: - Repository Errors

enum SessionRepositoryError: LocalizedError {
  case invalidResponse
  case sessionNotFound
  case sessionEnded
  case claimHostFailed

  var errorDescription: String? {
    switch self {
    case .invalidResponse: return "Invalid response from server."
    case .sessionNotFound: return "Session not found."
    case .sessionEnded: return "This session has ended. Ask the host to start a new one."
    case .claimHostFailed: return "Failed to claim host role."
    }
  }
}
