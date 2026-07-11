//
//  SessionRepository.swift
//  Gather Bible
//
//  Protocol abstracting session data operations for testability
//

import Combine
import Foundation

/// Protocol for session data operations
/// Abstracts Firebase to enable unit testing with mocks
@MainActor
protocol SessionRepository: AnyObject {
  // MARK: - Publishers for real-time updates

  var currentStatePublisher: AnyPublisher<SessionState?, Never> { get }
  var participantsPublisher: AnyPublisher<[SessionParticipant], Never> { get }
  var discussionsPublisher: AnyPublisher<[Discussion], Never> { get }
  var discussionResponsesPublisher: AnyPublisher<[DiscussionResponse], Never> { get }

  // MARK: - Session Lifecycle

  /// Generate a unique join code for a new session
  func generateJoinCode() async throws -> String

  /// Look up a session by join code
  /// Returns the sessionId if found, throws if not found
  func lookupSession(joinCode: String) async throws -> String

  /// Create a new session as host
  func createSession(
    sessionId: String,
    userId: String,
    joinCode: String,
    hostDisplayName: String,
    initialBook: String,
    initialChapter: Int
  ) async throws

  /// Join an existing session as a participant
  func joinSession(
    sessionId: String,
    userId: String,
    displayName: String
  ) async throws

  /// Leave the current session
  /// If isHost is true, marks session inactive; otherwise removes participant
  func leaveSession(sessionId: String, userId: String, isHost: Bool) async throws

  /// Start listening to real-time updates for a session
  func startListening(sessionId: String)

  /// Stop listening and clean up observers
  func stopListening()

  /// Set up disconnect handlers for automatic cleanup
  func setupDisconnectHandler(sessionId: String, userId: String, isHost: Bool)

  // MARK: - Navigation

  /// Publish navigation state (host only)
  func publishNavigation(
    sessionId: String,
    book: String,
    chapter: Int,
    verseId: String,
    verseOffset: Double,
    scrolling: Bool,
    versionId: Int
  )

  // MARK: - Host Claiming

  /// Claim host role for a session
  func claimHost(sessionId: String, userId: String, displayName: String) async throws

  // MARK: - Discussions

  /// Create a new discussion
  func createDiscussion(
    sessionId: String,
    question: String,
    publishImmediately: Bool
  ) async throws -> String

  /// Publish a draft discussion
  func publishDiscussion(sessionId: String, discussionId: String) async throws

  /// Submit a response to a discussion
  func submitDiscussionResponse(
    sessionId: String,
    discussionId: String,
    userId: String,
    response: String,
    participantName: String
  ) async throws

  /// Complete/close a discussion
  func completeDiscussion(sessionId: String, discussionId: String) async throws

  /// Delete a draft discussion
  func deleteDiscussion(sessionId: String, discussionId: String) async throws
}
