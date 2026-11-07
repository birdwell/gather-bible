import SwiftUI

/// Your notes for this chapter, under the text they belong to.
struct ChapterNotesSection: View {
  let notes: [VerseAnnotation]
  let onSelect: (VerseAnnotation) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Your notes")
        .font(AppFont.heading)
        .foregroundStyle(AppColor.ink)
        .accessibilityAddTraits(.isHeader)

      ForEach(notes) { annotation in
        NoteRow(annotation: annotation) {
          onSelect(annotation)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct NoteRow: View {
  let annotation: VerseAnnotation
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 4) {
        Text(annotation.noteReference)
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)

        Text(annotation.note ?? "")
          .font(AppFont.body)
          .foregroundStyle(AppColor.ink)
          .multilineTextAlignment(.leading)
          .lineLimit(4)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityHint("Opens this note")
  }
}
