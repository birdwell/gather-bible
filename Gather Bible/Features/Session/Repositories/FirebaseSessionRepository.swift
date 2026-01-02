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

final class FirebaseSessionRepository: SessionRepository {
  // MARK: - Firebase

  private let db: DatabaseReference
  private let functions: Functions

  // MARK: - Publishers

  private let currentStateSubject = CurrentValueSubject<SessionState?, Never>(nil)
  private let participantsSubject = CurrentValueSubject<[SessionParticipant], Never>([])
  private let discussionsSubject = CurrentValueSubject<[Discussion], Never>([])
  private let discussionResponsesSubject = CurrentValueSubject<[DiscussionResponse], Never>([])
  private let queueSubject = CurrentValueSubject<[QueuedReference], Never>([])

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

  var queuePublisher: AnyPublisher<[QueuedReference], Never> {
    queueSubject.eraseToAnyPublisher()
  }

  // MARK: - Firebase References

  private var stateRef: DatabaseReference?
  private var participantsRef: DatabaseReference?
  private var discussionsRef: DatabaseReference?
  private var activeDiscussionRef: DatabaseReference?
  private var discussionResponsesRef: DatabaseReference?
  private var queueRef: DatabaseReference?

  // MARK: - Firebase Observers

  private var stateObserver: UInt?
  private var participantsObserver: UInt?
  private var discussionsObserver: UInt?
  private var activeDiscussionObserver: UInt?
  private var discussionResponsesObserver: UInt?
  private var queueObserver: UInt?

  // MARK: - Throttling

  private let publishThrottle = Throttle(interval: 0.1)

  // MARK: - Init

  init() {
    self.db = Database.database().reference()
    self.functions = Functions.functions()
  }

  // MARK: - Session Lifecycle

  func generateJoinCode() async throws -> String {
    let result = try await functions.httpsCallable("generateUniqueJoinCode").call()

    guard let data = result.data as? [String: Any],
      let joinCode = data["joinCode"] as? String
    else {
      throw SessionRepositoryError.invalidResponse
    }

    return joinCode
  }

  func lookupSession(joinCode: String) async throws -> String {
    let result = try await functions.httpsCallable("lookupJoinCode").call(["joinCode": joinCode])

    guard let data = result.data as? [String: Any],
      let status = data["status"] as? String
    else {
      throw SessionRepositoryError.invalidResponse
    }

    if status == "NOT_FOUND" {
      throw SessionRepositoryError.sessionNotFound
    }

    guard let sessionId = data["sessionId"] as? String else {
      throw SessionRepositoryError.invalidResponse
    }

    return sessionId
  }

  func createSession(
    sessionId: String,
    userId: String,
    joinCode: String,
    initialBook: String,
    initialChapter: Int
  ) async throws {
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

  func leaveSession(sessionId: String, userId: String, isHost: Bool) async {
    if !isHost {
      do {
        try await db.child("sessions").child(sessionId).child("participants").child(userId)
          .removeValue()
      } catch {
        #if DEBUG
          print("[FirebaseSessionRepository] Failed to remove participant: \(error)")
        #endif
      }
    } else {
      do {
        try await db.child("sessions").child(sessionId).child("state").child("active")
          .setValue(false)
      } catch {
        #if DEBUG
          print("[FirebaseSessionRepository] Failed to mark session inactive: \(error)")
        #endif
      }
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

    queueRef = db.child("sessions").child(sessionId).child("queue")

    queueObserver = queueRef?.observe(.value) { [weak self] snapshot in
      var queue: [QueuedReference] = []

      for child in snapshot.children {
        guard let snapshot = child as? DataSnapshot,
          let dict = snapshot.value as? [String: Any],
          let reference = QueuedReference(from: dict)
        else {
          continue
        }
        queue.append(reference)
      }
      self?.queueSubject.send(queue)
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
    if let queueObserver = queueObserver {
      queueRef?.removeObserver(withHandle: queueObserver)
    }

    stateRef?.keepSynced(false)
    stateRef = nil
    participantsRef = nil
    discussionsRef = nil
    activeDiscussionRef = nil
    discussionResponsesRef = nil
    queueRef = nil
    stateObserver = nil
    participantsObserver = nil
    discussionsObserver = nil
    activeDiscussionObserver = nil
    discussionResponsesObserver = nil
    queueObserver = nil

    currentStateSubject.send(nil)
    participantsSubject.send([])
    discussionsSubject.send([])
    discussionResponsesSubject.send([])
    queueSubject.send([])
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

  // MARK: - Queue Management

  func addToQueue(sessionId: String, reference: QueuedReference) async throws {
    try await db.child("sessions").child(sessionId).child("queue").child(reference.id)
      .setValue(reference.toDictionary())
  }

  func removeFromQueue(sessionId: String, referenceId: String) async throws {
    try await db.child("sessions").child(sessionId).child("queue").child(referenceId)
      .removeValue()
  }

  func reorderQueue(sessionId: String, queue: [QueuedReference]) async throws {
    var queueData: [String: Any] = [:]
    for reference in queue {
      queueData[reference.id] = reference.toDictionary()
    }
    try await db.child("sessions").child(sessionId).child("queue").setValue(queueData)
  }

  func navigateToQueueIndex(
    sessionId: String,
    index: Int,
    reference: QueuedReference,
    versionId: Int
  ) async throws {
    let verseId = "\(reference.book).\(reference.chapter).\(reference.startVerse ?? 1)"

    let payload: [String: Any] = [
      "book": reference.book,
      "chapter": reference.chapter,
      "startVerseId": verseId,
      "verseOffset": 0.0,
      "scrolling": false,
      "versionId": versionId,
      "currentQueueIndex": index,
      "visibleStartVerse": reference.startVerse as Any,
      "visibleEndVerse": reference.endVerse as Any,
      "updatedAt": ServerValue.timestamp(),
    ]

    try await db.child("sessions").child(sessionId).child("state").updateChildValues(payload)
  }
}

// MARK: - Repository Errors

enum SessionRepositoryError: LocalizedError {
  case invalidResponse
  case sessionNotFound
  case claimHostFailed

  var errorDescription: String? {
    switch self {
    case .invalidResponse: return "Invalid response from server."
    case .sessionNotFound: return "Session not found."
    case .claimHostFailed: return "Failed to claim host role."
    }
  }
}
