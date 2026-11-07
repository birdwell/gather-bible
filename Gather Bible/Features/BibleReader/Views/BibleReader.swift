import Combine
import Foundation
import SwiftUI
import YouVersionPlatform
import YouVersionPlatformReader
import YouVersionPlatformCore
import YouVersionPlatformUI

/// Bible reader that uses YouVersion SDK's BibleTextView directly
struct BibleReader: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @State private var viewModel: BibleReaderViewModel?

  private let externalDisplayManager = ExternalDisplayManager.shared

  var body: some View {
    Group {
      if let viewModel {
        ReaderContentView(viewModel: viewModel)
      } else {
        ProgressView("Loading…")
      }
    }
    .onAppear {
      if viewModel == nil {
        let reader = BibleReaderViewModel(sessionViewModel: sessionViewModel)
        reader.restorePosition()
        viewModel = reader
      }
      viewModel?.loadVersions()
      viewModel?.syncFromSession()
      viewModel?.subscribeToSessionUpdates()

      if let viewModel {
        externalDisplayManager.attachReader(viewModel)
      }
    }
    .onDisappear {
      externalDisplayManager.detachReader()
    }
  }
}

// MARK: - Reader Content

private struct ReaderContentView: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @Bindable var viewModel: BibleReaderViewModel
  @Environment(\.readerSettings) private var readerSettings
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private let annotations = AnnotationStore.shared

  @State private var containerWidth: CGFloat = 0
  @State private var selectedVerses: Set<BibleReference> = []
  @State private var copyFailed = false
  @State private var showingSearch = false
  @State private var showingSettings = false
  @State private var noteTarget: NoteTarget?

  /// A comfortable reading measure on any screen, from a phone to an unfolded display.
  private static let readingColumnWidth: CGFloat = 680

  private var horizontalPadding: CGFloat {
    max(16, (containerWidth - Self.readingColumnWidth) / 2)
  }

  private var chapterKey: String {
    "\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)"
  }

  private var chapterAnnotations: [VerseAnnotation] {
    annotations.annotations(book: viewModel.selectedBook, chapter: viewModel.selectedChapter)
  }

  private var sortedSelectedVerses: [Int] {
    selectedVerses.compactMap(\.verseStart).sorted()
  }

  private var bookTitle: String {
    guard
      let book = viewModel.selectedVersionBooks.first(where: {
        ($0.id ?? "") == viewModel.selectedBook
      })
    else {
      return "Loading…"
    }
    return book.title ?? "Unknown"
  }

  /// The host first, then everyone else who's here, excluding you.
  private var companionNames: [String] {
    sessionViewModel.participants
      .filter { $0.active && $0.id != sessionViewModel.userId }
      .sorted { $0.isHost && !$1.isHost }
      .map(\.displayName)
  }

  private var versionAbbreviation: String {
    viewModel.selectedVersion?.localizedAbbreviation?.uppercased() ?? "..."
  }

  var body: some View {
    readerBody
    .toolbar {
      ReaderToolbar(
        bookTitle: bookTitle,
        chapter: viewModel.selectedChapter,
        version: versionAbbreviation,
        isLoadingVersion: viewModel.isLoadingVersions && viewModel.availableVersions.isEmpty,
        canPickPassage: viewModel.booksLoaded,
        canPickVersion: !viewModel.availableVersions.isEmpty,
        onPickPassage: { viewModel.showBookPicker = true },
        onPickVersion: { viewModel.showVersionPicker = true },
        onSearch: { showingSearch = true },
        onSettings: { showingSettings = true }
      )
    }
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if !selectedVerses.isEmpty {
        actionBar
          .frame(maxWidth: Self.readingColumnWidth)
          .padding(.horizontal, 16)
          .padding(.bottom, 8)
          .avoidingFold()
          .transition(.opacity)
      }
    }
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
    .background(AppColor.ground.ignoresSafeArea())
    // Single container-level haptic: Reduce Motion must NOT gate haptics
    // (they have their own system setting that `sensoryFeedback` respects),
    // and one trigger avoids the double-fire from per-button feedback.
    .sensoryFeedback(
      .impact(weight: .light),
      trigger: "\(viewModel.selectedBook).\(viewModel.selectedChapter)"
    )
    .sheet(isPresented: $showingSettings) {
      ReaderSettingsSheet()
    }
    .sheet(isPresented: $viewModel.showBookPicker) {
      BookAndChapterPickerSheet(viewModel: viewModel)
    }
    .sheet(isPresented: $viewModel.showVersionPicker) {
      VersionPickerSheet(
        viewModel: viewModel,
        onDismiss: { viewModel.showVersionPicker = false }
      )
    }
    .sheet(isPresented: $viewModel.showParticipantsSheet) {
      ParticipantsSheet(viewModel: sessionViewModel)
        .presentationDetents([.medium, .large])
    }
    // The participants sheet has nothing to show once the session is over, and
    // it would otherwise block the session-ended notice.
    .onChange(of: sessionViewModel.isInSession) { _, isInSession in
      if !isInSession { viewModel.showParticipantsSheet = false }
    }
    .onChange(of: viewModel.selectedVersionId) { _, _ in
      Task { await viewModel.loadBooksForVersion() }
    }
    .onChange(of: chapterKey) { _, _ in
      viewModel.savePosition()
      keepSelectionInCurrentChapter()
    }
    .task(id: chapterKey) {
      await prefetchNextChapter()
    }
    .sheet(isPresented: $showingSearch) {
      BibleSearchSheet(
        versionId: viewModel.selectedVersionId,
        store: annotations,
        onSelectVerse: { open($0) },
        onSelectNote: { annotation in
          open(
            BibleReference(
              versionId: viewModel.selectedVersionId,
              bookUSFM: annotation.book,
              chapter: annotation.chapter,
              verse: annotation.verse
            ),
            through: annotation.noteEndVerse
          )
        }
      )
    }
    .sheet(item: $noteTarget) { target in
      NoteEditorSheet(target: target, store: annotations) {
        clearSelection()
      }
    }
  }

  @ViewBuilder
  private var readerBody: some View {
    // Error takes priority even when a previous translation's books are still
    // loaded: after a failed version switch the reader state is inconsistent,
    // so show the retry UI instead of silently keeping the old translation.
    if let errorMessage = viewModel.loadErrorMessage {
      errorView(message: errorMessage)
    } else if !viewModel.booksLoaded {
      ProgressView("Loading…")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      SyncableScrollView(viewModel: viewModel) {
        VStack(alignment: .leading, spacing: 8) {
          ChapterOpener(
            chapter: viewModel.selectedChapter,
            companions: sessionViewModel.isInSession
              ? ReadingCompanions.text(names: companionNames) : nil,
            onShowCompanions: { viewModel.showParticipantsSheet = true }
          )
          BibleTextView(
            viewModel.bibleReference,
            textOptions: readerSettings.textOptions(for: dynamicTypeSize),
            selectedVerses: $selectedVerses,
            onVerseTap: { reference, _, _, _ in
              toggleSelection(reference)
            }
          )
          .id(chapterKey)
          // The text view only notices highlights that change after it appears, so this
          // has to run from its own lifecycle.
          .task(id: highlightSignature) {
            ReaderHighlightRenderer.apply(chapterAnnotations, to: viewModel.bibleReference)
          }

          let notes = chapterAnnotations.filter { $0.note != nil }
          if !notes.isEmpty {
            ChapterNotesSection(notes: notes) { annotation in
              noteTarget = NoteTarget(
                book: annotation.book,
                chapter: annotation.chapter,
                verse: annotation.verse,
                endVerse: annotation.noteEndVerse,
                reference: annotation.noteReference
              )
            }
            .padding(.top, 32)
          }

          ChapterFooter(
            canGoPrevious: viewModel.canGoPrevious,
            canGoNext: viewModel.canGoNext,
            onPrevious: { viewModel.previousChapter() },
            onNext: { viewModel.nextChapter() }
          )
          .padding(.top, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 12)
      }
    }
  }

  // MARK: - Selection

  private var selectionReference: String {
    let verses = sortedSelectedVerses
    let base = "\(bookTitle) \(viewModel.selectedChapter)"
    guard let first = verses.first, let last = verses.last else { return base }
    if first == last { return "\(base):\(first)" }
    let isContinuous = last - first + 1 == verses.count
    return isContinuous
      ? "\(base):\(first)-\(last)"
      : "\(base):\(verses.map(String.init).joined(separator: ", "))"
  }

  private var selectionAnnotations: [VerseAnnotation?] {
    sortedSelectedVerses.map {
      annotations.annotation(
        book: viewModel.selectedBook, chapter: viewModel.selectedChapter, verse: $0)
    }
  }

  /// The color to mark as active, only when every selected verse has it.
  private var selectionColor: HighlightColor? {
    let colors = Set(selectionAnnotations.map { $0?.highlight })
    return colors.count == 1 ? colors.first ?? nil : nil
  }

  private var actionBar: some View {
    VerseActionBar(
      reference: selectionReference,
      activeColor: selectionColor,
      hasNote: selectionAnnotations.first??.note != nil,
      errorMessage: copyFailed ? "Can't copy yet. Check your connection." : nil,
      onHighlight: { color in
        annotations.setHighlight(
          color,
          book: viewModel.selectedBook,
          chapter: viewModel.selectedChapter,
          verses: sortedSelectedVerses
        )
        clearSelection()
      },
      onNote: {
        noteTarget = NoteTarget(
          selectedVerses: sortedSelectedVerses,
          book: viewModel.selectedBook,
          chapter: viewModel.selectedChapter,
          existing: selectionAnnotations.first ?? nil,
          selectionLabel: selectionReference
        )
      },
      onCopy: { Task { await copySelection() } },
      onClose: { clearSelection() }
    )
  }

  private func toggleSelection(_ reference: BibleReference) {
    copyFailed = false
    if selectedVerses.contains(reference) {
      selectedVerses.remove(reference)
    } else {
      selectedVerses.insert(reference)
    }
  }

  private func copySelection() async {
    let verses = selectedVerses
    copyFailed = false
    guard let text = await VerseClipboard.text(for: Array(verses), label: selectionReference) else {
      copyFailed = selectedVerses == verses
      return
    }
    UIPasteboard.general.string = text
    if selectedVerses == verses { clearSelection() }
  }

  private func clearSelection() {
    selectedVerses = []
    copyFailed = false
  }

  private func keepSelectionInCurrentChapter() {
    let current = viewModel.bibleReference
    selectedVerses = selectedVerses.filter {
      $0.versionId == current.versionId && $0.bookUSFM == current.bookUSFM
        && $0.chapter == current.chapter
    }
  }

  /// Opens a verse's chapter and selects it, since the SDK can't scroll to a verse.
  private func open(_ reference: BibleReference, through endVerse: Int? = nil) {
    viewModel.selectedBook = reference.bookUSFM
    viewModel.selectedChapter = reference.chapter
    viewModel.handleNavigation(book: reference.bookUSFM, chapter: reference.chapter)
    copyFailed = false
    let start = reference.verseStart ?? 1
    selectedVerses = Set(
      (start...max(start, endVerse ?? start)).map {
        BibleReference(
          versionId: reference.versionId,
          bookUSFM: reference.bookUSFM,
          chapter: reference.chapter,
          verse: $0
        )
      })
  }

  // MARK: - Loading

  /// Changes whenever the highlights to draw change, so they're redrawn only then.
  private var highlightSignature: String {
    let highlights = chapterAnnotations.compactMap { annotation in
      annotation.highlight.map { "\(annotation.verse)\($0.rawValue)" }
    }
    return "\(chapterKey)|\(highlights.joined(separator: ","))"
  }

  /// Loads the next chapter in the background once this one has had time to appear.
  private func prefetchNextChapter() async {
    try? await Task.sleep(for: .seconds(1))
    guard !Task.isCancelled, let next = viewModel.nextChapterReference else { return }
    _ = try? await BibleChapterRepository.shared.chapter(withReference: next)
  }

  private func errorView(message: String) -> some View {
    EmptyState(
      title: "Couldn’t load this chapter",
      message: message,
      actionTitle: "Try again",
      action: { viewModel.retryLoad() }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
