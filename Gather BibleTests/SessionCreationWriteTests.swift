import Testing

@testable import Gather_Bible

@MainActor
struct SessionCreationWriteTests {

  /// Writing a `sessions` key at the database root replaces every session.
  @Test func testCreatingSessionOnlyWritesItsOwnPath() {
    let update = FirebaseSessionRepository.sessionCreationUpdate(
      sessionId: "abc",
      userId: "host",
      joinCode: "ABC123",
      hostDisplayName: "Josh",
      initialBook: "GEN",
      initialChapter: 1
    )

    #expect(Array(update.keys) == ["sessions/abc"])
  }
}
