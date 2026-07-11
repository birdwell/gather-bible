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

  var selectedVersion: BibleVersion? {
    availableVersions.first(where: { $0.id == selectedVersionId })
  }

  // MARK: - Data State
  var availableVersions: [BibleVersion] = []
  var selectedVersionBooks: [BibleBook] = []
  var isLoadingVersions = true

  /// User-facing message set when versions/books fail to load. `nil` when there's no error.
  var loadErrorMessage: String?

  /// True once books for the current version are available.
  var booksLoaded: Bool {
    !selectedVersionBooks.isEmpty
  }

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

  /// Guards so we don't refetch versions on every view appearance / tab switch.
  private var hasLoadedVersions = false
  /// Guards so we only attach one Combine sink for session updates.
  private var hasSubscribed = false

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

  /// Whether there's a previous chapter (or previous book) to move to.
  var canGoPrevious: Bool {
    guard
      let currentBookIndex = selectedVersionBooks.firstIndex(where: {
        ($0.id ?? "") == selectedBook
      })
    else { return false }
    return selectedChapter > 1 || currentBookIndex > 0
  }

  /// Whether there's a next chapter (or next book) to move to.
  var canGoNext: Bool {
    guard
      let currentBookIndex = selectedVersionBooks.firstIndex(where: {
        ($0.id ?? "") == selectedBook
      })
    else { return false }
    let chapterCount = selectedVersionBooks[currentBookIndex].chapters?.count ?? 1
    return selectedChapter < chapterCount
      || currentBookIndex < selectedVersionBooks.count - 1
  }

  // MARK: - Initialization
  init(sessionViewModel: SessionViewModel? = nil) {
    self.sessionViewModel = sessionViewModel
    setupBindings()
  }

  // MARK: - Setup
  private func setupBindings() {
    // Version change observation is handled by onVersionChange() called from view
  }

  func subscribeToSessionUpdates() {
    guard !hasSubscribed else { return }
    guard let sessionViewModel = sessionViewModel else { return }
    hasSubscribed = true

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

  /// Loads available versions. Skips the network fetch if versions were already
  /// loaded (e.g. on a tab switch) unless `force` is true (used by Retry).
  func loadVersions(force: Bool = false) {
    guard force || !hasLoadedVersions else { return }

    Task {
      isLoadingVersions = true
      loadErrorMessage = nil
      do {
        let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        availableVersions = try await YouVersionConfig.getAvailableVersions(
          forLanguageTag: deviceLanguage)

        hasLoadedVersions = true
        isLoadingVersions = false

        // Only apply the NIV/first-version default when the user's current
        // selection isn't available, so a forced reload (Retry) preserves
        // the translation they chose.
        if !availableVersions.contains(where: { $0.id == selectedVersionId }) {
          if let niv = availableVersions.first(where: { $0.id == 111 }) {
            selectedVersionId = niv.id
          } else if let firstVersion = availableVersions.first {
            selectedVersionId = firstVersion.id
          }
        }

        await loadBooksForVersion()
      } catch {
        isLoadingVersions = false
        loadErrorMessage =
          "We couldn't load Bible versions. Check your connection and try again."
        print("📖 [BibleReader] ❌ Error loading versions: \(error)")
      }
    }
  }

  /// Re-runs the failed load. If versions are already loaded, only the current
  /// version's books are refetched so the user's selected translation is kept;
  /// otherwise the full version list is loaded. Used by the reader's Retry button.
  func retryLoad() {
    if hasLoadedVersions {
      Task {
        loadErrorMessage = nil
        await loadBooksForVersion()
      }
    } else {
      loadVersions(force: true)
    }
  }

  func loadBooksForVersion() async {
    do {
      let version = try await YouVersionConfig.getVersionDetails(versionId: selectedVersionId)

      if let books = version.books {
        selectedVersionBooks = books
        loadErrorMessage = nil

        if !books.contains(where: { ($0.id ?? "") == selectedBook }) {
          selectedBook = books.first?.id ?? "GEN"
          selectedChapter = 1
        }
      } else {
        loadErrorMessage =
          "We couldn't load this translation. Check your connection and try again."
      }
    } catch {
      loadErrorMessage =
        "We couldn't load this translation. Check your connection and try again."
      print("📖 [BibleReader] ❌ Error loading books: \(error)")
    }
  }
}
