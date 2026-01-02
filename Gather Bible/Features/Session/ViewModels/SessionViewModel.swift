//
//  SessionViewModel.swift
//  Gather Bible
//
//  View model for managing Bible reading sessions
//

import Combine
import Foundation
import SwiftUI

/// View model for managing Bible reading sessions
@MainActor
class SessionViewModel: ObservableObject {
  // MARK: - Dependencies

  private let repository: SessionRepository

  // MARK: - Session State

  @Published var isInSession = false
  @Published var isHost = false
  @Published var joinCode = ""
  @Published private(set) var sessionId: String?
  @Published var userId: String = UUID().uuidString

  // MARK: - UI State

  @Published var errorMessage: String?
  @Published var isLoading = false
  @Published var showDiscussionPrompt = false

  // MARK: - Sync State

  @Published var currentState: SessionState?
  @Published var participants: [SessionParticipant] = []
  @Published var followHost = true
  @Published var isScrolling = false

  // MARK: - Discussion State

  @Published var activeDiscussion: Discussion?
  @Published var discussionResponses: [DiscussionResponse] = []
  @Published var discussions: [Discussion] = []

  // MARK: - Queue State

  @Published var queue: [QueuedReference] = []
  @Published var currentQueueIndex: Int = 0

  // MARK: - Private

  private var cancellables = Set<AnyCancellable>()
  private var scrollTimer: Timer?

  // MARK: - Computed Properties

  var currentBook: String {
    currentState?.book ?? "GEN"
  }

  var currentChapter: Int {
    currentState?.chapter ?? 1
  }

  var currentVersionId: Int {
    currentState?.versionId ?? 111
  }

  var isSessionInactive: Bool {
    guard let state = currentState else { return false }
    return !state.active
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

  var draftDiscussions: [Discussion] {
    discussions.filter { $0.status == .draft }
  }

  var completedDiscussions: [Discussion] {
    discussions.filter { $0.status == .completed }
  }

  var hasQueue: Bool {
    !queue.isEmpty
  }

  var canGoToPreviousQueueItem: Bool {
    currentQueueIndex > 0
  }

  var canGoToNextQueueItem: Bool {
    currentQueueIndex < queue.count - 1
  }

  var currentQueueItem: QueuedReference? {
    guard currentQueueIndex >= 0 && currentQueueIndex < queue.count else { return nil }
    return queue[currentQueueIndex]
  }

  var visibleStartVerse: Int? {
    currentState?.visibleStartVerse
  }

  var visibleEndVerse: Int? {
    currentState?.visibleEndVerse
  }

  // MARK: - Init

  init(repository: SessionRepository? = nil) {
    self.repository = repository ?? FirebaseSessionRepository()
    setupSubscriptions()
  }

  private func setupSubscriptions() {
    repository.currentStatePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.currentState = state
      }
      .store(in: &cancellables)

    repository.participantsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] participants in
        self?.participants = participants
      }
      .store(in: &cancellables)

    repository.discussionsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] discussions in
        guard let self else { return }
        self.discussions = discussions
        let newActiveDiscussion = discussions.first { $0.status == .active }

        if newActiveDiscussion?.id != self.activeDiscussion?.id {
          self.activeDiscussion = newActiveDiscussion
          if !self.isHost, newActiveDiscussion != nil {
            self.showDiscussionPrompt = true
          }
        }
      }
      .store(in: &cancellables)

    repository.discussionResponsesPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] responses in
        self?.discussionResponses = responses
      }
      .store(in: &cancellables)

    repository.queuePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] queue in
        self?.queue = queue
      }
      .store(in: &cancellables)

    repository.currentStatePublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0?.currentQueueIndex }
      .sink { [weak self] index in
        self?.currentQueueIndex = index
      }
      .store(in: &cancellables)
  }

  // MARK: - Session Lifecycle

  func createSession(initialBook: String = "GEN", initialChapter: Int = 1) async {
    isLoading = true
    errorMessage = nil

    do {
      let joinCode = try await repository.generateJoinCode()
      let newSessionId = UUID().uuidString

      try await repository.createSession(
        sessionId: newSessionId,
        userId: userId,
        joinCode: joinCode,
        initialBook: initialBook,
        initialChapter: initialChapter
      )

      repository.startListening(sessionId: newSessionId)
      repository.setupDisconnectHandler(sessionId: newSessionId, userId: userId, isHost: true)

      self.sessionId = newSessionId
      self.joinCode = joinCode
      self.isHost = true
      self.isInSession = true

    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func joinSession(joinCode: String, displayName: String) async {
    isLoading = true
    errorMessage = nil

    do {
      let sessionId = try await repository.lookupSession(joinCode: joinCode)

      try await repository.joinSession(
        sessionId: sessionId,
        userId: userId,
        displayName: displayName
      )

      repository.startListening(sessionId: sessionId)
      repository.setupDisconnectHandler(sessionId: sessionId, userId: userId, isHost: false)

      self.sessionId = sessionId
      self.joinCode = joinCode
      self.isHost = false
      self.isInSession = true

    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func leaveSession() async {
    isLoading = true

    if let sessionId = sessionId {
      await repository.leaveSession(sessionId: sessionId, userId: userId, isHost: isHost)
    }

    repository.stopListening()
    resetSessionState()

    isLoading = false
  }

  private func resetSessionState() {
    isInSession = false
    isHost = false
    joinCode = ""
    sessionId = nil
    showDiscussionPrompt = false
    currentState = nil
    participants = []
    discussions = []
    discussionResponses = []
    activeDiscussion = nil
    followHost = true
    isScrolling = false
    queue = []
    currentQueueIndex = 0
  }

  // MARK: - Navigation

  func toggleFollowHost() {
    guard !isHost else { return }
    followHost.toggle()
  }

  func publishNavigation(
    book: String, chapter: Int, verseId: String, verseOffset: Double, scrolling: Bool
  ) {
    guard isHost, let sessionId = sessionId else { return }

    if scrolling {
      scrollTimer?.invalidate()
    }

    isScrolling = scrolling

    if !scrolling {
      scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) {
        [weak self] _ in
        guard let self else { return }
        Task { @MainActor [weak self] in
          self?.publishScrollStop()
        }
      }
    }

    repository.publishNavigation(
      sessionId: sessionId,
      book: book,
      chapter: chapter,
      verseId: verseId,
      verseOffset: verseOffset,
      scrolling: scrolling,
      versionId: currentVersionId
    )
  }

  private func publishScrollStop() {
    guard isHost, let sessionId = sessionId, let currentState = currentState else { return }
    repository.publishNavigation(
      sessionId: sessionId,
      book: currentState.book,
      chapter: currentState.chapter,
      verseId: currentState.startVerseId,
      verseOffset: currentState.verseOffset,
      scrolling: false,
      versionId: currentState.versionId
    )
  }

  // MARK: - Host Claiming

  func claimHost() async {
    guard let sessionId = sessionId, !isHost else { return }

    isLoading = true
    errorMessage = nil

    do {
      let displayName = participants.first { $0.id == userId }?.displayName ?? "Host"
      try await repository.claimHost(sessionId: sessionId, userId: userId, displayName: displayName)

      self.isHost = true
      repository.setupDisconnectHandler(sessionId: sessionId, userId: userId, isHost: true)

    } catch {
      handleError(error)
    }

    isLoading = false
  }

  // MARK: - Discussion Methods

  func createDiscussion(question: String, publishImmediately: Bool) async {
    guard isHost, let sessionId = sessionId else { return }
    isLoading = true
    errorMessage = nil

    do {
      _ = try await repository.createDiscussion(
        sessionId: sessionId,
        question: question,
        publishImmediately: publishImmediately
      )
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func publishDiscussion(_ discussion: Discussion) async {
    guard isHost, let sessionId = sessionId else { return }
    isLoading = true
    errorMessage = nil

    do {
      try await repository.publishDiscussion(sessionId: sessionId, discussionId: discussion.id)
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func submitDiscussionResponse(response: String) async {
    guard let discussion = activeDiscussion, let sessionId = sessionId else { return }

    isLoading = true
    errorMessage = nil

    let participantName = participants.first { $0.id == userId }?.displayName ?? "Guest"

    do {
      try await repository.submitDiscussionResponse(
        sessionId: sessionId,
        discussionId: discussion.id,
        userId: userId,
        response: response,
        participantName: participantName
      )
      showDiscussionPrompt = false
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func completeDiscussion() async {
    guard isHost, let discussion = activeDiscussion, let sessionId = sessionId else { return }

    isLoading = true
    errorMessage = nil

    do {
      try await repository.completeDiscussion(sessionId: sessionId, discussionId: discussion.id)
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func deleteDiscussion(_ discussion: Discussion) async {
    guard isHost, discussion.status == .draft, let sessionId = sessionId else { return }

    isLoading = true
    errorMessage = nil

    do {
      try await repository.deleteDiscussion(sessionId: sessionId, discussionId: discussion.id)
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func dismissDiscussionPrompt() {
    showDiscussionPrompt = false
  }

  // MARK: - Queue Management

  func addToQueue(reference: QueuedReference) async {
    guard isHost, let sessionId = sessionId else { return }

    isLoading = true
    errorMessage = nil

    do {
      try await repository.addToQueue(sessionId: sessionId, reference: reference)
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func removeFromQueue(referenceId: String) async {
    guard isHost, let sessionId = sessionId else { return }

    isLoading = true
    errorMessage = nil

    do {
      try await repository.removeFromQueue(sessionId: sessionId, referenceId: referenceId)
    } catch {
      handleError(error)
    }

    isLoading = false
  }

  func reorderQueue(queue: [QueuedReference]) async {
    guard isHost, let sessionId = sessionId else { return }

    do {
      try await repository.reorderQueue(sessionId: sessionId, queue: queue)
    } catch {
      handleError(error)
    }
  }

  func goToNextQueueItem() async {
    guard isHost, canGoToNextQueueItem else { return }
    await navigateToQueueIndex(currentQueueIndex + 1)
  }

  func goToPreviousQueueItem() async {
    guard isHost, canGoToPreviousQueueItem else { return }
    await navigateToQueueIndex(currentQueueIndex - 1)
  }

  func navigateToQueueIndex(_ index: Int) async {
    guard isHost,
      let sessionId = sessionId,
      index >= 0 && index < queue.count
    else { return }

    let reference = queue[index]

    do {
      try await repository.navigateToQueueIndex(
        sessionId: sessionId,
        index: index,
        reference: reference,
        versionId: currentVersionId
      )
    } catch {
      handleError(error)
    }
  }

  // MARK: - Error Handling

  private func handleError(_ error: Error) {
    if let error = error as? SessionRepositoryError {
      errorMessage = error.localizedDescription
    } else if let error = error as? SessionError {
      errorMessage = error.localizedDescription
    } else {
      errorMessage = "An unexpected error occurred."
    }
  }
}

// MARK: - Session Errors

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
