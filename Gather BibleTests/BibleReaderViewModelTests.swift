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
}
