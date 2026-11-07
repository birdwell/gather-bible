import SwiftUI

/// The large number that opens a chapter, with who you're reading with beside it.
struct ChapterOpener: View {
  let chapter: Int
  var companions: String?
  var onShowCompanions: () -> Void = {}

  var body: some View {
    HStack(alignment: .lastTextBaseline, spacing: 16) {
      Text("\(chapter)")
        .font(AppFont.chapter)
        .foregroundStyle(AppColor.ink)
        .accessibilityLabel("Chapter \(chapter)")
        .accessibilityAddTraits(.isHeader)

      Spacer(minLength: 0)

      if let companions {
        Button(action: onShowCompanions) {
          Text(companions)
            .font(AppFont.caption)
            .foregroundStyle(AppColor.muted)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows who's in this session")
      }
    }
  }
}

#Preview {
  ChapterOpener(chapter: 23, companions: "with Sam and 2 others")
    .padding()
}
