import Combine
import Foundation
import Observation
import SwiftUI
import YouVersionPlatform

/// ViewModel that encapsulates all Bible reader state and logic
@MainActor
@Observable
final class BibleReaderViewModel {
  // MARK: - Navigation State
  var selectedBook = "GEN"
  var selectedChapter = 1
  var selectedVersionId = 111  // Default to NIV

  var bibleReference: BibleReference {
    BibleReference(
      versionId: selectedVersionId,
      bookUSFM: selectedBook,
      chapter: selectedChapter
    )
  }

  // MARK: - Data State
  var availableVersions: [BibleVersion] = []
  var selectedVersionBooks: [BibleBook] = []
  var isLoadingVersions = true

  // MARK: - UI State
  var showVersionPicker = false
  var showBookPicker = false
  var showParticipantsSheet = false

  // MARK: - Scroll State
  var scrollOffset: CGFloat = 0
  var contentHeight: CGFloat = 1
  var viewHeight: CGFloat = 1
  var targetScrollOffset: Double = 0

  // MARK: - Private State
  private var lastPublishedOffset: Double = 0
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Dependencies
  private weak var sessionViewModel: SessionViewModel?

  // MARK: - Computed Properties
  var isHost: Bool {
    sessionViewModel?.isHost ?? false
  }

  var followHost: Bool {
    sessionViewModel?.followHost ?? false
  }

  var shouldApplyScrollOffset: Bool {
    !isHost && followHost
  }

  // MARK: - Initialization
  init(sessionViewModel: SessionViewModel? = nil) {
    self.sessionViewModel = sessionViewModel
  }

  func subscribeToSessionUpdates() {
    guard let sessionViewModel = sessionViewModel else { return }

    sessionViewModel.$currentState
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.handleSessionStateUpdate(state)
      }
      .store(in: &cancellables)
  }

  // MARK: - Session Sync
  private func handleSessionStateUpdate(_ state: SessionState) {
    guard !isHost && followHost else { return }

    selectedBook = state.book
    selectedChapter = state.chapter
    selectedVersionId = state.versionId
    targetScrollOffset = state.verseOffset
  }

  func syncFromSession() {
    guard let state = sessionViewModel?.currentState else { return }

    selectedBook = state.book
    selectedChapter = state.chapter
    selectedVersionId = state.versionId
  }

  // MARK: - Navigation
  func handleNavigation(book: String, chapter: Int) {
    selectedBook = book
    selectedChapter = chapter

    if isHost {
      publishNavigation()
    }
  }

  /// Called during scroll (real-time) or when stopped - publishes absolute Y position
  func publishScrollPosition(offset: CGFloat, isScrolling: Bool) {
    guard isHost else { return }

    sessionViewModel?.publishNavigation(
      book: selectedBook,
      chapter: selectedChapter,
      verseId: "\(selectedBook).\(selectedChapter).1",
      verseOffset: Double(offset),
      scrolling: isScrolling
    )
  }

  private func publishNavigation() {
    sessionViewModel?.publishNavigation(
      book: selectedBook,
      chapter: selectedChapter,
      verseId: "\(selectedBook).\(selectedChapter).1",
      verseOffset: 0,
      scrolling: false
    )
  }

  func nextChapter() {
    guard
      let currentBookIndex = selectedVersionBooks.firstIndex(where: {
        ($0.id ?? "") == selectedBook
      })
    else { return }
    let currentBook = selectedVersionBooks[currentBookIndex]
    let chapterCount = currentBook.chapters?.count ?? 1

    if selectedChapter < chapterCount {
      handleNavigation(book: selectedBook, chapter: selectedChapter + 1)
    } else if currentBookIndex < selectedVersionBooks.count - 1 {
      // Move to next book
      let nextBook = selectedVersionBooks[currentBookIndex + 1]
      handleNavigation(book: nextBook.id ?? "GEN", chapter: 1)
    }
  }

  func previousChapter() {
    guard
      let currentBookIndex = selectedVersionBooks.firstIndex(where: {
        ($0.id ?? "") == selectedBook
      })
    else { return }

    if selectedChapter > 1 {
      handleNavigation(book: selectedBook, chapter: selectedChapter - 1)
    } else if currentBookIndex > 0 {
      // Move to previous book
      let prevBook = selectedVersionBooks[currentBookIndex - 1]
      let prevChapterCount = prevBook.chapters?.count ?? 1
      handleNavigation(book: prevBook.id ?? "GEN", chapter: prevChapterCount)
    }
  }

  // MARK: - Data Loading
  func loadVersions() {
    Task {
      do {
        let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        availableVersions = try await YouVersionConfig.getAvailableVersions(
          forLanguageTag: deviceLanguage)

        isLoadingVersions = false

        if let niv = availableVersions.first(where: { $0.id == 111 }) {
          selectedVersionId = niv.id
        } else if let firstVersion = availableVersions.first {
          selectedVersionId = firstVersion.id
        }

        await loadBooksForVersion()
      } catch {
        isLoadingVersions = false
        print("📖 [BibleReader] ❌ Error loading versions: \(error)")
      }
    }
  }

  func loadBooksForVersion() async {
    do {
      let version = try await YouVersionConfig.getVersionDetails(versionId: selectedVersionId)

      if let books = version.books {
        selectedVersionBooks = books

        if !books.contains(where: { ($0.id ?? "") == selectedBook }) {
          selectedBook = books.first?.id ?? "GEN"
          selectedChapter = 1
        }
      }
    } catch {
      print("📖 [BibleReader] ❌ Error loading books: \(error)")
    }
  }
}
