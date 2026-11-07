import SwiftUI
import YouVersionPlatformCore

/// Connects the selected verses to the action bar: highlight, write a note, or copy.
struct ReaderActionBar: View {
  let viewModel: BibleReaderViewModel
  let annotations: AnnotationStore
  @Binding var selectedVerses: Set<BibleReference>
  let onWriteNote: (NoteTarget) -> Void

  @State private var errorMessage: String?

  private var sortedVerses: [Int] {
    selectedVerses.compactMap(\.verseStart).sorted()
  }

  private var reference: String {
    let verses = sortedVerses
    let base = "\(viewModel.selectedBookTitle) \(viewModel.selectedChapter)"
    guard let first = verses.first, let last = verses.last else { return base }
    if first == last { return "\(base):\(first)" }
    let isContinuous = last - first + 1 == verses.count
    return isContinuous
      ? "\(base):\(first)-\(last)"
      : "\(base):\(verses.map(String.init).joined(separator: ", "))"
  }

  private var selectedAnnotations: [VerseAnnotation?] {
    sortedVerses.map {
      annotations.annotation(
        book: viewModel.selectedBook, chapter: viewModel.selectedChapter, verse: $0)
    }
  }

  /// The color to mark as active, only when every selected verse has it.
  private var activeColor: HighlightColor? {
    let colors = Set(selectedAnnotations.map { $0?.highlight })
    return colors.count == 1 ? colors.first ?? nil : nil
  }

  var body: some View {
    VerseActionBar(
      reference: reference,
      activeColor: activeColor,
      hasNote: selectedAnnotations.first??.note != nil,
      errorMessage: errorMessage,
      onHighlight: highlight,
      onNote: writeNote,
      onCopy: { Task { await copy() } },
      onClose: { selectedVerses = [] }
    )
    .onChange(of: selectedVerses) { _, _ in
      errorMessage = nil
    }
  }

  private func highlight(_ color: HighlightColor?) {
    let saved = annotations.setHighlight(
      color,
      book: viewModel.selectedBook,
      chapter: viewModel.selectedChapter,
      verses: sortedVerses
    )
    if saved {
      selectedVerses = []
    } else {
      errorMessage = "Couldn't save. Free up some storage and try again."
    }
  }

  private func writeNote() {
    let target = NoteTarget(
      selectedVerses: sortedVerses,
      book: viewModel.selectedBook,
      chapter: viewModel.selectedChapter,
      existing: selectedAnnotations.first ?? nil,
      selectionLabel: reference
    )
    if let target {
      onWriteNote(target)
    } else {
      errorMessage = "Select verses next to each other to add a note."
    }
  }

  private func copy() async {
    let verses = selectedVerses
    errorMessage = nil
    guard let text = await VerseClipboard.text(for: Array(verses), label: reference) else {
      if selectedVerses == verses {
        errorMessage = "Can't copy yet. Check your connection."
      }
      return
    }
    UIPasteboard.general.string = text
    if selectedVerses == verses { selectedVerses = [] }
  }
}
