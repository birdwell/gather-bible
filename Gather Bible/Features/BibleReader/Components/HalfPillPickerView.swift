import SwiftUI

// MARK: - Half Pill Picker View

struct HalfPillPickerView: View {
  let bookAndChapter: String
  let versionAbbreviation: String
  let handleChapterTap: () -> Void
  let handleVersionTap: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      // Book & Chapter button (left side)
      Button(action: handleChapterTap) {
        Text(bookAndChapter)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color.primary)
          .lineLimit(1)
          .frame(minWidth: 60)
          .frame(height: 40)
          .padding(.leading, 16)
          .padding(.trailing, 14)
      }
      .buttonStyle(PlainButtonStyle())
      .clipShape(HalfPillShape(side: .left))
      .accessibilityLabel("Current chapter: \(bookAndChapter)")
      .accessibilityHint("Double tap to select a different book or chapter")

      // Divider
      Rectangle()
        .fill(Color(.systemBackground))
        .frame(width: 2, height: 40)
        .accessibilityHidden(true)

      // Version button (right side)
      Button(action: handleVersionTap) {
        Text(versionAbbreviation)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color.primary)
          .frame(minWidth: 36)
          .frame(height: 40)
          .padding(.leading, 14)
          .padding(.trailing, 16)
      }
      .buttonStyle(PlainButtonStyle())
      .clipShape(HalfPillShape(side: .right))
      .accessibilityLabel("Bible version: \(versionAbbreviation)")
      .accessibilityHint("Double tap to select a different Bible translation")
    }
    .background(Color(.systemGray5))
    .clipShape(Capsule())
    .frame(height: 40)
  }
}
