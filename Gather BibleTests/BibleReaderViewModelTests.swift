import Foundation
import Testing
import YouVersionPlatformCore

@testable import Gather_Bible

@MainActor
struct BibleReaderViewModelTests {

  @Test func testNextChapterWithinBook() async throws {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks  // GEN (5), EXO (3), MAT (2)
    viewModel.selectedBook = "GEN"
    viewModel.selectedChapter = 1

    viewModel.nextChapter()

    #expect(viewModel.selectedBook == "GEN")
    #expect(viewModel.selectedChapter == 2)
  }

  @Test func testNextChapterTransitionToNextBook() async throws {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "GEN"
    viewModel.selectedChapter = 5  // Last chapter of Genesis

    viewModel.nextChapter()

    #expect(viewModel.selectedBook == "EXO")
    #expect(viewModel.selectedChapter == 1)
  }

  @Test func testNextChapterLastBookLastChapter() async throws {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "MAT"
    viewModel.selectedChapter = 2  // Last chapter of Matthew

    viewModel.nextChapter()

    #expect(viewModel.selectedBook == "MAT")
    #expect(viewModel.selectedChapter == 2)
  }

  @Test func testPreviousChapterWithinBook() async throws {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "GEN"
    viewModel.selectedChapter = 2

    viewModel.previousChapter()

    #expect(viewModel.selectedBook == "GEN")
    #expect(viewModel.selectedChapter == 1)
  }

  @Test func testPreviousChapterTransitionToPreviousBook() async throws {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "EXO"
    viewModel.selectedChapter = 1

    viewModel.previousChapter()

    #expect(viewModel.selectedBook == "GEN")
    #expect(viewModel.selectedChapter == 5)  // Last chapter of Genesis
  }

  @Test func testPreviousChapterFirstBookFirstChapter() async throws {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "GEN"
    viewModel.selectedChapter = 1

    viewModel.previousChapter()

    #expect(viewModel.selectedBook == "GEN")
    #expect(viewModel.selectedChapter == 1)
  }

  // MARK: - Next chapter for prefetching

  @Test func testLateBooksForAnOldVersionAreDropped() async {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionId = 111

    await viewModel.loadBooksForVersion { _ in
      viewModel.selectedVersionId = 59
      return BibleBook.mockBooks
    }

    #expect(viewModel.selectedVersionBooks.isEmpty)
  }

  @Test func testLateFailureForAnOldVersionIsIgnored() async {
    struct LoadFailed: Error {}
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionId = 111

    await viewModel.loadBooksForVersion { _ in
      viewModel.selectedVersionId = 59
      throw LoadFailed()
    }

    #expect(viewModel.loadErrorMessage == nil)
  }

  @Test func testBooksForTheCurrentVersionAreApplied() async {
    let viewModel = BibleReaderViewModel()

    await viewModel.loadBooksForVersion { _ in BibleBook.mockBooks }

    #expect(viewModel.booksLoaded)
  }

  @Test func testNextChapterReferenceWithinBook() {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "GEN"
    viewModel.selectedChapter = 1

    #expect(viewModel.nextChapterReference?.bookUSFM == "GEN")
    #expect(viewModel.nextChapterReference?.chapter == 2)
  }

  @Test func testNextChapterReferenceMovesToNextBook() {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    viewModel.selectedBook = "GEN"
    viewModel.selectedChapter = BibleBook.mockBooks[0].chapters?.count ?? 1

    #expect(viewModel.nextChapterReference?.bookUSFM == "EXO")
    #expect(viewModel.nextChapterReference?.chapter == 1)
  }

  @Test func testNextChapterReferenceIsNilAtTheEnd() {
    let viewModel = BibleReaderViewModel()
    viewModel.selectedVersionBooks = BibleBook.mockBooks
    let lastBook = BibleBook.mockBooks[BibleBook.mockBooks.count - 1]
    viewModel.selectedBook = lastBook.id ?? ""
    viewModel.selectedChapter = lastBook.chapters?.count ?? 1

    #expect(viewModel.nextChapterReference == nil)
  }

  // MARK: - Reading position

  @Test func testPositionRoundTrips() throws {
    let defaults = try #require(UserDefaults(suiteName: "position-\(UUID())"))
    let saved = BibleReaderViewModel()
    saved.selectedBook = "JHN"
    saved.selectedChapter = 8
    saved.selectedVersionId = 59
    saved.savePosition(to: defaults)

    let restored = BibleReaderViewModel()
    restored.restorePosition(from: defaults)

    #expect(restored.selectedBook == "JHN")
    #expect(restored.selectedChapter == 8)
    #expect(restored.selectedVersionId == 59)
  }

  @Test func testNoSavedPositionKeepsDefaults() throws {
    let defaults = try #require(UserDefaults(suiteName: "position-\(UUID())"))
    let viewModel = BibleReaderViewModel()
    viewModel.restorePosition(from: defaults)

    #expect(viewModel.selectedBook == "GEN")
    #expect(viewModel.selectedChapter == 1)
  }
}
