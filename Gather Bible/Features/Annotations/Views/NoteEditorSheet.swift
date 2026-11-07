import SwiftUI

/// The verses a note is being written for.
struct NoteTarget: Identifiable {
  let book: String
  let chapter: Int
  let verse: Int
  let endVerse: Int?
  let reference: String

  var id: String { VerseAnnotation.id(book: book, chapter: chapter, verse: verse) }
}

extension NoteTarget {
  /// The note target for selected verses. Selecting one verse of an existing note edits the
  /// whole note, so saving doesn't shrink the verses it covers.
  init?(
    selectedVerses: [Int],
    book: String,
    chapter: Int,
    existing: VerseAnnotation?,
    selectionLabel: String
  ) {
    guard let first = selectedVerses.min(), let last = selectedVerses.max() else { return nil }
    let editsExistingNote = first == last && existing?.note != nil
    self.init(
      book: book,
      chapter: chapter,
      verse: first,
      endVerse: editsExistingNote ? existing?.noteEndVerse : (first == last ? nil : last),
      reference: editsExistingNote ? (existing?.noteReference ?? selectionLabel) : selectionLabel
    )
  }
}

struct NoteEditorSheet: View {
  let target: NoteTarget
  let store: AnnotationStore
  let onFinish: () -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var confirmingDelete = false
  @State private var text: String
  @State private var existingNote: String?
  @FocusState private var isFocused: Bool

  init(target: NoteTarget, store: AnnotationStore, onFinish: @escaping () -> Void = {}) {
    self.target = target
    self.store = store
    self.onFinish = onFinish
    let note =
      store.annotation(book: target.book, chapter: target.chapter, verse: target.verse)?.note
    _text = State(initialValue: note ?? "")
    _existingNote = State(initialValue: note)
  }

  private var trimmedText: String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          StyledTextEditor(text: $text, placeholder: "What stands out to you?", minHeight: 160)
            .focused($isFocused)
            .accessibilityLabel("Note")

          Button {
            save(text)
          } label: {
            Text("Save note")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.appPrimary)
          .disabled(trimmedText.isEmpty)

          if existingNote != nil {
            Button("Delete note", role: .destructive) {
              confirmingDelete = true
            }
            .buttonStyle(.appQuiet)
            .confirmationDialog("Delete this note?", isPresented: $confirmingDelete) {
              Button("Delete note", role: .destructive) { save("") }
            }
          }
        }
        .padding(16)
      }
      .appNavigationTitle(LocalizedStringKey(target.reference))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
    .appSheet()
    .onAppear { isFocused = true }
  }

  private func save(_ value: String) {
    store.setNote(
      value,
      book: target.book,
      chapter: target.chapter,
      verse: target.verse,
      endVerse: target.endVerse
    )
    onFinish()
    dismiss()
  }
}
