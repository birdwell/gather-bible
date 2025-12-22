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
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color.primary)
          .lineLimit(1)
          .frame(minWidth: 60)
          .frame(height: 40)
          .padding(.leading, 16)
          .padding(.trailing, 14)
      }
      .buttonStyle(PlainButtonStyle())
      .clipShape(HalfPillShape(side: .left))

      // Divider
      Rectangle()
        .fill(Color(.systemBackground))
        .frame(width: 2, height: 40)

      // Version button (right side)
      Button(action: handleVersionTap) {
        Text(versionAbbreviation)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color.primary)
          .frame(minWidth: 36)
          .frame(height: 40)
          .padding(.leading, 14)
          .padding(.trailing, 16)
      }
      .buttonStyle(PlainButtonStyle())
      .clipShape(HalfPillShape(side: .right))
    }
    .background(Color(.systemGray5))
    .clipShape(Capsule())
    .frame(height: 40)
  }
}
