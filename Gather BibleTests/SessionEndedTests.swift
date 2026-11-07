import Foundation
import Testing

@testable import Gather_Bible

@MainActor
struct SessionEndedTests {

  private func state(active: Bool = true, endedAt: Double? = nil) -> SessionState {
    var dictionary: [String: Any] = [
      "joinCode": "ABC123",
      "hostId": "host",
      "book": "GEN",
      "chapter": 1,
      "startVerseId": "GEN.1.1",
      "verseOffset": 0.0,
      "scrolling": false,
      "active": active,
    ]
    if let endedAt { dictionary["endedAt"] = endedAt }
    return SessionState(from: dictionary)!
  }

  private func joinedGuest() async -> (SessionViewModel, MockSessionRepository) {
    let repository = MockSessionRepository()
    repository.stubbedSessionId = "session-123"
    let viewModel = SessionViewModel(repository: repository)
    await viewModel.joinSession(joinCode: "ABC123", displayName: "Sam")
    #expect(viewModel.isInSession)
    return (viewModel, repository)
  }

  private func settle() async {
    try? await Task.sleep(for: .milliseconds(50))
  }

  @Test func testGuestExitsWhenHostEndsSession() async {
    let (viewModel, repository) = await joinedGuest()

    repository.simulateStateUpdate(state(active: false, endedAt: 1000))
    await settle()

    #expect(viewModel.isInSession == false)
    #expect(viewModel.joinCode.isEmpty)
    #expect(viewModel.sessionEndedByHost == true)
  }

  @Test func testGuestStaysWhenHostOnlyDisconnects() async {
    let (viewModel, repository) = await joinedGuest()

    repository.simulateStateUpdate(state(active: false))
    await settle()

    #expect(viewModel.isInSession == true)
    #expect(viewModel.sessionEndedByHost == false)
  }

  @Test func testHostDoesNotGetEndedNotice() async {
    let repository = MockSessionRepository()
    let viewModel = SessionViewModel(repository: repository)
    await viewModel.createSession()

    repository.simulateStateUpdate(state(active: false, endedAt: 1000))
    await settle()

    #expect(viewModel.sessionEndedByHost == false)
  }

  @Test func testStateParsesEndedAt() {
    #expect(state().endedAt == nil)
    #expect(state(endedAt: 1000).endedAt == 1000)
  }
}
