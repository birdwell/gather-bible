//
//  SessionViewModelTests.swift
//  Gather BibleTests
//
//  Tests for SessionViewModel business logic
//

import Combine
import Foundation
import Testing

@testable import Gather_Bible

@MainActor
struct SessionViewModelTests {

  // MARK: - Test Setup

  private func createViewModel() -> (SessionViewModel, MockSessionRepository) {
    let mockRepo = MockSessionRepository()
    let viewModel = SessionViewModel(repository: mockRepo)
    return (viewModel, mockRepo)
  }

  // MARK: - Initial State Tests

  @Test func testInitialState() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.isInSession == false)
    #expect(viewModel.isHost == false)
    #expect(viewModel.joinCode == "")
    #expect(viewModel.sessionId == nil)
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.showDiscussionPrompt == false)
    #expect(viewModel.currentState == nil)
    #expect(viewModel.participants.isEmpty)
    #expect(viewModel.followHost == true)
    #expect(viewModel.isScrolling == false)
    #expect(viewModel.activeDiscussion == nil)
    #expect(viewModel.discussionResponses.isEmpty)
    #expect(viewModel.discussions.isEmpty)
  }

  @Test func testUserIdIsGenerated() {
    let (viewModel, _) = createViewModel()

    #expect(!viewModel.userId.isEmpty)
    #expect(viewModel.userId.count > 10)
  }

  // MARK: - Computed Properties: currentBook/currentChapter/currentVersionId

  @Test func testCurrentBookDefaultsWhenNoState() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.currentBook == "GEN")
    #expect(viewModel.currentChapter == 1)
    #expect(viewModel.currentVersionId == 111)
  }

  @Test func testCurrentBookFromState() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateStateUpdate(
      SessionState(from: [
        "book": "EXO", "chapter": 5, "startVerseId": "EXO.5.1",
        "verseOffset": 0.0, "scrolling": false, "versionId": 59,
        "active": true, "joinCode": "ABC",
      ]))

    #expect(viewModel.currentBook == "EXO")
    #expect(viewModel.currentChapter == 5)
    #expect(viewModel.currentVersionId == 59)
  }

  // MARK: - Computed Properties: isSessionInactive

  @Test func testIsSessionInactiveWhenNoState() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.isSessionInactive == false)
  }

  @Test func testIsSessionInactiveWhenActive() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateStateUpdate(
      SessionState(from: [
        "book": "GEN", "chapter": 1, "startVerseId": "GEN.1.1",
        "verseOffset": 0.0, "scrolling": false, "versionId": 111,
        "active": true, "joinCode": "ABC",
      ]))

    #expect(viewModel.isSessionInactive == false)
  }

  @Test func testIsSessionInactiveWhenInactive() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateStateUpdate(
      SessionState(from: [
        "book": "GEN", "chapter": 1, "startVerseId": "GEN.1.1",
        "verseOffset": 0.0, "scrolling": false, "versionId": 111,
        "active": false, "joinCode": "ABC",
      ]))

    #expect(viewModel.isSessionInactive == true)
  }

  // MARK: - Computed Properties: activeParticipantCount

  @Test func testActiveParticipantCountEmpty() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.activeParticipantCount == 0)
  }

  @Test func testActiveParticipantCountFromRepository() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateParticipantsUpdate([
      SessionParticipant(
        userId: "1", from: ["displayName": "User1", "isHost": true, "active": true])!,
      SessionParticipant(
        userId: "2", from: ["displayName": "User2", "isHost": false, "active": true])!,
      SessionParticipant(
        userId: "3", from: ["displayName": "User3", "isHost": false, "active": false])!,
    ])

    #expect(viewModel.activeParticipantCount == 2)
  }

  // MARK: - Computed Properties: hostParticipant

  @Test func testHostParticipantNone() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.hostParticipant == nil)
  }

  @Test func testHostParticipantFound() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateParticipantsUpdate([
      SessionParticipant(
        userId: "host-id", from: ["displayName": "Host", "isHost": true, "active": true])!,
      SessionParticipant(
        userId: "guest-id", from: ["displayName": "Guest", "isHost": false, "active": true])!,
    ])

    #expect(viewModel.hostParticipant?.id == "host-id")
    #expect(viewModel.hostParticipant?.displayName == "Host")
  }

  // MARK: - Computed Properties: isCurrentHostInactive

  @Test func testIsCurrentHostInactiveNoHost() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.isCurrentHostInactive == true)
  }

  @Test func testIsCurrentHostInactiveHostActiveRecently() {
    let (viewModel, mockRepo) = createViewModel()
    let recentTimestamp = Date().timeIntervalSince1970 - 30
    mockRepo.simulateParticipantsUpdate([
      SessionParticipant(
        userId: "host-id",
        from: [
          "displayName": "Host", "isHost": true, "active": true,
          "lastSeen": recentTimestamp * 1000,
        ]
      )!
    ])

    #expect(viewModel.isCurrentHostInactive == false)
  }

  @Test func testIsCurrentHostInactiveHostActiveStale() {
    let (viewModel, mockRepo) = createViewModel()
    let staleTimestamp = Date().timeIntervalSince1970 - 300
    mockRepo.simulateParticipantsUpdate([
      SessionParticipant(
        userId: "host-id",
        from: [
          "displayName": "Host", "isHost": true, "active": true,
          "lastSeen": staleTimestamp * 1000,
        ]
      )!
    ])

    #expect(viewModel.isCurrentHostInactive == true)
  }

  // MARK: - Computed Properties: sessionStatusText

  @Test func testSessionStatusTextNotInSession() {
    let (viewModel, _) = createViewModel()

    #expect(viewModel.sessionStatusText == "Not in session")
  }

  @Test func testSessionStatusTextHosting() {
    let (viewModel, _) = createViewModel()
    viewModel.isInSession = true
    viewModel.isHost = true
    viewModel.joinCode = "ABC123"

    #expect(viewModel.sessionStatusText == "Hosting session • Code: ABC123")
  }

  @Test func testSessionStatusTextInactive() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateStateUpdate(
      SessionState(from: [
        "book": "GEN", "chapter": 1, "startVerseId": "GEN.1.1",
        "verseOffset": 0.0, "scrolling": false, "versionId": 111,
        "active": false, "joinCode": "XYZ789",
      ]))
    viewModel.isInSession = true
    viewModel.isHost = false
    viewModel.joinCode = "XYZ789"

    #expect(viewModel.sessionStatusText == "Session Inactive • Code: XYZ789")
  }

  @Test func testSessionStatusTextJoined() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateStateUpdate(
      SessionState(from: [
        "book": "GEN", "chapter": 1, "startVerseId": "GEN.1.1",
        "verseOffset": 0.0, "scrolling": false, "versionId": 111,
        "active": true, "joinCode": "DEF456",
      ]))
    viewModel.isInSession = true
    viewModel.isHost = false
    viewModel.joinCode = "DEF456"

    #expect(viewModel.sessionStatusText == "Joined session • Code: DEF456")
  }

  // MARK: - Computed Properties: draftDiscussions / completedDiscussions

  @Test func testDraftDiscussionsFiltered() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "1", from: ["question": "Q1", "status": "draft", "createdAt": 1000, "sessionId": "s1"])!,
      Discussion(
        id: "2", from: ["question": "Q2", "status": "active", "createdAt": 2000, "sessionId": "s1"]
      )!,
      Discussion(
        id: "3", from: ["question": "Q3", "status": "draft", "createdAt": 3000, "sessionId": "s1"])!,
    ])

    #expect(viewModel.draftDiscussions.count == 2)
    #expect(viewModel.draftDiscussions.allSatisfy { $0.status == .draft })
  }

  @Test func testCompletedDiscussionsFiltered() {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "1", from: ["question": "Q1", "status": "draft", "createdAt": 1000, "sessionId": "s1"])!,
      Discussion(
        id: "2",
        from: ["question": "Q2", "status": "completed", "createdAt": 2000, "sessionId": "s1"])!,
    ])

    #expect(viewModel.completedDiscussions.count == 1)
  }

  // MARK: - toggleFollowHost

  @Test func testToggleFollowHostAsGuest() {
    let (viewModel, _) = createViewModel()
    viewModel.isHost = false
    viewModel.followHost = true

    viewModel.toggleFollowHost()

    #expect(viewModel.followHost == false)
  }

  @Test func testToggleFollowHostAsHostDoesNothing() {
    let (viewModel, _) = createViewModel()
    viewModel.isHost = true
    viewModel.followHost = true

    viewModel.toggleFollowHost()

    #expect(viewModel.followHost == true)
  }

  // MARK: - dismissDiscussionPrompt

  @Test func testDismissDiscussionPrompt() {
    let (viewModel, _) = createViewModel()
    viewModel.showDiscussionPrompt = true

    viewModel.dismissDiscussionPrompt()

    #expect(viewModel.showDiscussionPrompt == false)
  }

  // MARK: - createSession

  @Test func testCreateSessionSuccess() async {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.stubbedJoinCode = "TEST123"

    await viewModel.createSession(initialBook: "EXO", initialChapter: 3)

    #expect(mockRepo.generateJoinCodeCalled == true)
    #expect(mockRepo.createSessionCalled == true)
    #expect(mockRepo.startListeningCalled == true)
    #expect(mockRepo.setupDisconnectHandlerCalled == true)
    #expect(viewModel.isInSession == true)
    #expect(viewModel.isHost == true)
    #expect(viewModel.joinCode == "TEST123")
    #expect(viewModel.sessionId != nil)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.errorMessage == nil)
  }

  @Test func testCreateSessionError() async {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.shouldThrowError = SessionRepositoryError.invalidResponse

    await viewModel.createSession()

    #expect(viewModel.isInSession == false)
    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.isLoading == false)
  }

  // MARK: - joinSession

  @Test func testJoinSessionSuccess() async {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.stubbedSessionId = "session-123"

    await viewModel.joinSession(joinCode: "ABC123", displayName: "Guest User")

    #expect(mockRepo.lookupSessionCalled == true)
    #expect(mockRepo.joinSessionCalled == true)
    #expect(mockRepo.startListeningCalled == true)
    #expect(mockRepo.lastDisplayName == "Guest User")
    #expect(viewModel.isInSession == true)
    #expect(viewModel.isHost == false)
    #expect(viewModel.joinCode == "ABC123")
    #expect(viewModel.sessionId == "session-123")
  }

  @Test func testJoinSessionNotFound() async {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.shouldThrowError = SessionRepositoryError.sessionNotFound

    await viewModel.joinSession(joinCode: "INVALID", displayName: "Guest")

    #expect(viewModel.isInSession == false)
    #expect(viewModel.errorMessage == "Session not found.")
  }

  // MARK: - leaveSession

  @Test func testLeaveSessionAsHost() async {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.stubbedJoinCode = "ABC"
    await viewModel.createSession()
    mockRepo.reset()

    await viewModel.leaveSession()

    #expect(mockRepo.leaveSessionCalled == true)
    #expect(mockRepo.stopListeningCalled == true)
    #expect(viewModel.isInSession == false)
    #expect(viewModel.isHost == false)
    #expect(viewModel.sessionId == nil)
    #expect(viewModel.joinCode == "")
  }

  @Test func testLeaveSessionResetsAllState() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.simulateParticipantsUpdate([
      SessionParticipant(userId: "1", from: ["displayName": "Host", "isHost": true, "active": true])!
    ])
    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "1", from: ["question": "Q1", "status": "draft", "createdAt": 1000, "sessionId": "s1"])!
    ])

    await viewModel.leaveSession()

    #expect(viewModel.participants.isEmpty)
    #expect(viewModel.discussions.isEmpty)
    #expect(viewModel.currentState == nil)
    #expect(viewModel.followHost == true)
  }

  // MARK: - publishNavigation

  @Test func testPublishNavigationAsHost() {
    let (viewModel, mockRepo) = createViewModel()
    viewModel.isHost = true
    viewModel.isInSession = true

    viewModel.publishNavigation(
      book: "EXO", chapter: 5, verseId: "EXO.5.1", verseOffset: 100, scrolling: true)

    #expect(mockRepo.publishNavigationCalled == true)
    #expect(mockRepo.lastPublishedBook == "EXO")
    #expect(mockRepo.lastPublishedChapter == 5)
    #expect(mockRepo.lastPublishedVerseOffset == 100)
    #expect(viewModel.isScrolling == true)
  }

  @Test func testPublishNavigationIgnoredWhenNotHost() {
    let (viewModel, mockRepo) = createViewModel()
    viewModel.isHost = false

    viewModel.publishNavigation(
      book: "EXO", chapter: 5, verseId: "EXO.5.1", verseOffset: 100, scrolling: true)

    #expect(mockRepo.publishNavigationCalled == false)
  }

  // MARK: - claimHost

  @Test func testClaimHostSuccess() async {
    let (viewModel, mockRepo) = createViewModel()
    mockRepo.stubbedSessionId = "session-123"
    await viewModel.joinSession(joinCode: "ABC", displayName: "Guest")
    mockRepo.reset()

    await viewModel.claimHost()

    #expect(mockRepo.claimHostCalled == true)
    #expect(viewModel.isHost == true)
  }

  @Test func testClaimHostIgnoredWhenAlreadyHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.reset()

    await viewModel.claimHost()

    #expect(mockRepo.claimHostCalled == false)
  }

  @Test func testClaimHostError() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.joinSession(joinCode: "ABC", displayName: "Guest")
    mockRepo.reset()
    mockRepo.shouldThrowError = SessionRepositoryError.claimHostFailed

    await viewModel.claimHost()

    #expect(viewModel.isHost == false)
    #expect(viewModel.errorMessage == "Failed to claim host role.")
  }

  // MARK: - createDiscussion

  @Test func testCreateDiscussionAsHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.reset()

    await viewModel.createDiscussion(question: "Test question?", publishImmediately: true)

    #expect(mockRepo.createDiscussionCalled == true)
    #expect(mockRepo.lastQuestion == "Test question?")
  }

  @Test func testCreateDiscussionIgnoredWhenNotHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.joinSession(joinCode: "ABC", displayName: "Guest")
    mockRepo.reset()

    await viewModel.createDiscussion(question: "Test?", publishImmediately: false)

    #expect(mockRepo.createDiscussionCalled == false)
  }

  // MARK: - publishDiscussion

  @Test func testPublishDiscussionAsHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.reset()
    let discussion = Discussion(
      id: "d1", from: ["question": "Q1", "status": "draft", "createdAt": 1000, "sessionId": "s1"])!

    await viewModel.publishDiscussion(discussion)

    #expect(mockRepo.publishDiscussionCalled == true)
    #expect(mockRepo.lastDiscussionId == "d1")
  }

  // MARK: - submitDiscussionResponse

  @Test func testSubmitDiscussionResponse() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.joinSession(joinCode: "ABC", displayName: "Guest")
    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "d1", from: ["question": "Q1", "status": "active", "createdAt": 1000, "sessionId": "s1"]
      )!
    ])
    mockRepo.reset()

    await viewModel.submitDiscussionResponse(response: "My answer")

    #expect(mockRepo.submitDiscussionResponseCalled == true)
    #expect(mockRepo.lastResponse == "My answer")
    #expect(mockRepo.lastDiscussionId == "d1")
  }

  @Test func testSubmitDiscussionResponseRequiresActiveDiscussion() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.joinSession(joinCode: "ABC", displayName: "Guest")
    mockRepo.reset()

    await viewModel.submitDiscussionResponse(response: "My answer")

    #expect(mockRepo.submitDiscussionResponseCalled == false)
  }

  // MARK: - completeDiscussion

  @Test func testCompleteDiscussionAsHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "d1", from: ["question": "Q1", "status": "active", "createdAt": 1000, "sessionId": "s1"]
      )!
    ])
    mockRepo.reset()

    await viewModel.completeDiscussion()

    #expect(mockRepo.completeDiscussionCalled == true)
    #expect(mockRepo.lastDiscussionId == "d1")
  }

  @Test func testCompleteDiscussionRequiresActiveDiscussion() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.reset()

    await viewModel.completeDiscussion()

    #expect(mockRepo.completeDiscussionCalled == false)
  }

  // MARK: - deleteDiscussion

  @Test func testDeleteDiscussionAsHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.reset()
    let discussion = Discussion(
      id: "d1", from: ["question": "Q1", "status": "draft", "createdAt": 1000, "sessionId": "s1"])!

    await viewModel.deleteDiscussion(discussion)

    #expect(mockRepo.deleteDiscussionCalled == true)
    #expect(mockRepo.lastDiscussionId == "d1")
  }

  @Test func testDeleteDiscussionRequiresDraftStatus() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()
    mockRepo.reset()
    let discussion = Discussion(
      id: "d1", from: ["question": "Q1", "status": "active", "createdAt": 1000, "sessionId": "s1"])!

    await viewModel.deleteDiscussion(discussion)

    #expect(mockRepo.deleteDiscussionCalled == false)
  }

  // MARK: - Active Discussion Prompt

  @Test func testActiveDiscussionShowsPromptForGuest() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.joinSession(joinCode: "ABC", displayName: "Guest")

    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "d1", from: ["question": "Q1", "status": "active", "createdAt": 1000, "sessionId": "s1"]
      )!
    ])

    #expect(viewModel.showDiscussionPrompt == true)
    #expect(viewModel.activeDiscussion?.id == "d1")
  }

  @Test func testActiveDiscussionDoesNotShowPromptForHost() async {
    let (viewModel, mockRepo) = createViewModel()
    await viewModel.createSession()

    mockRepo.simulateDiscussionsUpdate([
      Discussion(
        id: "d1", from: ["question": "Q1", "status": "active", "createdAt": 1000, "sessionId": "s1"]
      )!
    ])

    #expect(viewModel.showDiscussionPrompt == false)
    #expect(viewModel.activeDiscussion?.id == "d1")
  }
}

// MARK: - SessionError Tests

struct SessionErrorTests {

  @Test func testInvalidResponseDescription() {
    let error = SessionError.invalidResponse
    #expect(error.errorDescription == "Invalid response from server.")
  }

  @Test func testSessionNotFoundDescription() {
    let error = SessionError.sessionNotFound
    #expect(error.errorDescription == "Session not found.")
  }

  @Test func testNetworkErrorDescription() {
    let error = SessionError.networkError
    #expect(error.errorDescription == "Network error.")
  }

  @Test func testPermissionDeniedDescription() {
    let error = SessionError.permissionDenied
    #expect(error.errorDescription == "Permission denied.")
  }

  @Test func testClaimHostFailedDescription() {
    let error = SessionError.claimHostFailed
    #expect(error.errorDescription == "Failed to claim host role.")
  }
}

// MARK: - SessionRepositoryError Tests

struct SessionRepositoryErrorTests {

  @Test func testInvalidResponseDescription() {
    let error = SessionRepositoryError.invalidResponse
    #expect(error.errorDescription == "Invalid response from server.")
  }

  @Test func testSessionNotFoundDescription() {
    let error = SessionRepositoryError.sessionNotFound
    #expect(error.errorDescription == "Session not found.")
  }

  @Test func testClaimHostFailedDescription() {
    let error = SessionRepositoryError.claimHostFailed
    #expect(error.errorDescription == "Failed to claim host role.")
  }
}
