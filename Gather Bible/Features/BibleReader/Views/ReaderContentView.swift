import SwiftUI
import YouVersionPlatformCore

/// The reader screen: its toolbar, passage, action bar, and sheets.
struct ReaderContentView: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @Bindable var viewModel: BibleReaderViewModel

  private let annotations = AnnotationStore.shared

  @State private var containerWidth: CGFloat = 0
  @State private var selectedVerses: Set<BibleReference> = []
  @State private var showingSearch = false
  @State private var showingSettings = false
  @State private var noteTarget: NoteTarget?

  /// A comfortable reading measure on any screen, from a phone to an unfolded display.
  private static let readingColumnWidth: CGFloat = 680

  private var horizontalPadding: CGFloat {
    max(16, (containerWidth - Self.readingColumnWidth) / 2)
  }

  private var versionAbbreviation: String {
    viewModel.selectedVersion?.localizedAbbreviation?.uppercased() ?? "..."
  }

  var body: some View {
    readerBody
      .toolbar {
        ReaderToolbar(
          bookTitle: viewModel.selectedBookTitle,
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
          ReaderActionBar(
            viewModel: viewModel,
            annotations: annotations,
            selectedVerses: $selectedVerses,
            onWriteNote: { noteTarget = $0 }
          )
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
      .onChange(of: viewModel.chapterKey) { _, _ in
        viewModel.savePosition()
        keepSelectionInCurrentChapter()
      }
      .task(id: viewModel.chapterKey) {
        await viewModel.prefetchNextChapter()
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
          selectedVerses = []
        }
      }
  }

  @ViewBuilder
  private var readerBody: some View {
    // Error takes priority even when a previous translation's books are still
    // loaded: after a failed version switch the reader state is inconsistent,
    // so show the retry UI instead of silently keeping the old translation.
    if let errorMessage = viewModel.loadErrorMessage {
      EmptyState(
        title: "Couldn’t load this chapter",
        message: errorMessage,
        actionTitle: "Try again",
        action: { viewModel.retryLoad() }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if !viewModel.booksLoaded {
      ProgressView("Loading…")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ReaderPassageView(
        viewModel: viewModel,
        annotations: annotations,
        selectedVerses: $selectedVerses,
        horizontalPadding: horizontalPadding,
        onSelectNote: { annotation in
          noteTarget = NoteTarget(
            book: annotation.book,
            chapter: annotation.chapter,
            verse: annotation.verse,
            endVerse: annotation.noteEndVerse,
            reference: annotation.noteReference
          )
        }
      )
    }
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
}
