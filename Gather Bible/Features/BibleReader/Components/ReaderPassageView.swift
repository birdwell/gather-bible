import SwiftUI
import YouVersionPlatformCore
import YouVersionPlatformUI

/// The scrolling chapter: its number, text, notes, and links to the next chapter.
struct ReaderPassageView: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @Environment(\.readerSettings) private var readerSettings
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  let viewModel: BibleReaderViewModel
  let annotations: AnnotationStore
  @Binding var selectedVerses: Set<BibleReference>
  let horizontalPadding: CGFloat
  let onSelectNote: (VerseAnnotation) -> Void

  private var chapterAnnotations: [VerseAnnotation] {
    annotations.annotations(book: viewModel.selectedBook, chapter: viewModel.selectedChapter)
  }

  /// The host first, then everyone else who's here, excluding you.
  private var companionNames: [String] {
    sessionViewModel.participants
      .filter { $0.active && $0.id != sessionViewModel.userId }
      .sorted { $0.isHost && !$1.isHost }
      .map(\.displayName)
  }

  /// Changes whenever the highlights to draw change, so they're redrawn only then.
  private var highlightSignature: String {
    let highlights = chapterAnnotations.compactMap { annotation in
      annotation.highlight.map { "\(annotation.verse)\($0.rawValue)" }
    }
    return "\(viewModel.chapterKey)|\(highlights.joined(separator: ","))"
  }

  var body: some View {
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
        .id(viewModel.chapterKey)
        // The text view only notices highlights that change after it appears, so this
        // has to run from its own lifecycle.
        .task(id: highlightSignature) {
          ReaderHighlightRenderer.apply(chapterAnnotations, to: viewModel.bibleReference)
        }

        let notes = chapterAnnotations.filter { $0.note != nil }
        if !notes.isEmpty {
          ChapterNotesSection(notes: notes, onSelect: onSelectNote)
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

  private func toggleSelection(_ reference: BibleReference) {
    if selectedVerses.contains(reference) {
      selectedVerses.remove(reference)
    } else {
      selectedVerses.insert(reference)
    }
  }
}
