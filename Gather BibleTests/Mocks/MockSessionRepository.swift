//
//  MockSessionRepository.swift
//  Gather BibleTests
//
//  Mock implementation of SessionRepository for unit testing
//

import Combine
import Foundation

@testable import Gather_Bible

final class MockSessionRepository: SessionRepository {
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

  // MARK: - Call Tracking

  var generateJoinCodeCalled = false
  var lookupSessionCalled = false
  var createSessionCalled = false
  var joinSessionCalled = false
  var leaveSessionCalled = false
  var startListeningCalled = false
  var stopListeningCalled = false
  var setupDisconnectHandlerCalled = false
  var publishNavigationCalled = false
  var claimHostCalled = false
  var createDiscussionCalled = false
  var publishDiscussionCalled = false
  var submitDiscussionResponseCalled = false
  var completeDiscussionCalled = false
  var deleteDiscussionCalled = false

  // MARK: - Captured Arguments

  var lastSessionId: String?
  var lastUserId: String?
  var lastJoinCode: String?
  var lastDisplayName: String?
  var lastQuestion: String?
  var lastDiscussionId: String?
  var lastResponse: String?
  var lastPublishedBook: String?
  var lastPublishedChapter: Int?
  var lastPublishedVerseOffset: Double?
  var lastPublishedScrolling: Bool?

  // MARK: - Stubbed Results

  var stubbedJoinCode = "ABC123"
  var stubbedSessionId = "mock-session-id"
  var stubbedDiscussionId = "mock-discussion-id"
  var shouldThrowError: Error?

  // MARK: - Session Lifecycle

  func generateJoinCode() async throws -> String {
    generateJoinCodeCalled = true
    if let error = shouldThrowError { throw error }
    return stubbedJoinCode
  }

  func lookupSession(joinCode: String) async throws -> String {
    lookupSessionCalled = true
    lastJoinCode = joinCode
    if let error = shouldThrowError { throw error }
    return stubbedSessionId
  }

  func createSession(
    sessionId: String,
    userId: String,
    joinCode: String,
    hostDisplayName: String,
    initialBook: String,
    initialChapter: Int
  ) async throws {
    createSessionCalled = true
    lastSessionId = sessionId
    lastUserId = userId
    lastJoinCode = joinCode
    lastDisplayName = hostDisplayName
    if let error = shouldThrowError { throw error }
  }

  func joinSession(
    sessionId: String,
    userId: String,
    displayName: String
  ) async throws {
    joinSessionCalled = true
    lastSessionId = sessionId
    lastUserId = userId
    lastDisplayName = displayName
    if let error = shouldThrowError { throw error }
  }

  func leaveSession(sessionId: String, userId: String, isHost: Bool) async throws {
    leaveSessionCalled = true
    lastSessionId = sessionId
    lastUserId = userId
    if let error = shouldThrowError { throw error }
  }

  func startListening(sessionId: String) {
    startListeningCalled = true
    lastSessionId = sessionId
  }

  func stopListening() {
    stopListeningCalled = true
    currentStateSubject.send(nil)
    participantsSubject.send([])
    discussionsSubject.send([])
    discussionResponsesSubject.send([])
  }

  func setupDisconnectHandler(sessionId: String, userId: String, isHost: Bool) {
    setupDisconnectHandlerCalled = true
    lastSessionId = sessionId
    lastUserId = userId
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
    publishNavigationCalled = true
    lastSessionId = sessionId
    lastPublishedBook = book
    lastPublishedChapter = chapter
    lastPublishedVerseOffset = verseOffset
    lastPublishedScrolling = scrolling
  }

  // MARK: - Host Claiming

  func claimHost(sessionId: String, userId: String, displayName: String) async throws {
    claimHostCalled = true
    lastSessionId = sessionId
    lastUserId = userId
    lastDisplayName = displayName
    if let error = shouldThrowError { throw error }
  }

  // MARK: - Discussions

  func createDiscussion(
    sessionId: String,
    question: String,
    publishImmediately: Bool
  ) async throws -> String {
    createDiscussionCalled = true
    lastSessionId = sessionId
    lastQuestion = question
    if let error = shouldThrowError { throw error }
    return stubbedDiscussionId
  }

  func publishDiscussion(sessionId: String, discussionId: String) async throws {
    publishDiscussionCalled = true
    lastSessionId = sessionId
    lastDiscussionId = discussionId
    if let error = shouldThrowError { throw error }
  }

  func submitDiscussionResponse(
    sessionId: String,
    discussionId: String,
    userId: String,
    response: String,
    participantName: String
  ) async throws {
    submitDiscussionResponseCalled = true
    lastSessionId = sessionId
    lastDiscussionId = discussionId
    lastUserId = userId
    lastResponse = response
    if let error = shouldThrowError { throw error }
  }

  func completeDiscussion(sessionId: String, discussionId: String) async throws {
    completeDiscussionCalled = true
    lastSessionId = sessionId
    lastDiscussionId = discussionId
    if let error = shouldThrowError { throw error }
  }

  func deleteDiscussion(sessionId: String, discussionId: String) async throws {
    deleteDiscussionCalled = true
    lastSessionId = sessionId
    lastDiscussionId = discussionId
    if let error = shouldThrowError { throw error }
  }

  // MARK: - Test Helpers

  func simulateStateUpdate(_ state: SessionState?) {
    currentStateSubject.send(state)
  }

  func simulateParticipantsUpdate(_ participants: [SessionParticipant]) {
    participantsSubject.send(participants)
  }

  func simulateDiscussionsUpdate(_ discussions: [Discussion]) {
    discussionsSubject.send(discussions)
  }

  func simulateDiscussionResponsesUpdate(_ responses: [DiscussionResponse]) {
    discussionResponsesSubject.send(responses)
  }

  func reset() {
    generateJoinCodeCalled = false
    lookupSessionCalled = false
    createSessionCalled = false
    joinSessionCalled = false
    leaveSessionCalled = false
    startListeningCalled = false
    stopListeningCalled = false
    setupDisconnectHandlerCalled = false
    publishNavigationCalled = false
    claimHostCalled = false
    createDiscussionCalled = false
    publishDiscussionCalled = false
    submitDiscussionResponseCalled = false
    completeDiscussionCalled = false
    deleteDiscussionCalled = false

    lastSessionId = nil
    lastUserId = nil
    lastJoinCode = nil
    lastDisplayName = nil
    lastQuestion = nil
    lastDiscussionId = nil
    lastResponse = nil
    lastPublishedBook = nil
    lastPublishedChapter = nil
    lastPublishedVerseOffset = nil
    lastPublishedScrolling = nil

    shouldThrowError = nil
  }
}
