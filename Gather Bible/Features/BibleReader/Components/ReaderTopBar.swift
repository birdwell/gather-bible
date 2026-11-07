import SwiftUI

/// The reader's quiet header: the current book, translation, and display controls.
struct ReaderTopBar: View {
  let bookTitle: String
  let chapter: Int
  let version: String
  let isLoadingVersion: Bool
  let canPickPassage: Bool
  let canPickVersion: Bool
  let horizontalPadding: CGFloat
  let onPickPassage: () -> Void
  let onPickVersion: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      passageButton
      Spacer(minLength: 8)
      versionButton
      AirPlayButton(
        tintColor: UIColor(AppColor.muted),
        activeTintColor: UIColor(AppColor.accent)
      )
      .frame(width: 44, height: 44)
      .accessibilityLabel("AirPlay")
      .accessibilityHint("Streams to Apple TV or other AirPlay devices")
      ReaderSettingsButton()
    }
    .padding(.horizontal, horizontalPadding)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    .background(AppColor.ground.ignoresSafeArea(edges: .top))
    // A short fade so text leaves under the header instead of being cut by an edge.
    .overlay(alignment: .bottom) {
      LinearGradient(
        colors: [AppColor.ground, AppColor.ground.opacity(0)],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 24)
      .offset(y: 24)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }

  private var passageButton: some View {
    Button(action: onPickPassage) {
      HStack(spacing: 4) {
        Text(bookTitle)
          .font(AppFont.heading)
          .foregroundStyle(AppColor.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        AppIconView(.caretDown, size: 14)
          .foregroundStyle(AppColor.muted)
      }
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!canPickPassage)
    .accessibilityLabel("Current chapter: \(bookTitle) \(chapter)")
    .accessibilityHint("Selects a different book or chapter")
  }

  private var versionButton: some View {
    Button(action: onPickVersion) {
      Group {
        if isLoadingVersion {
          ProgressView()
            .controlSize(.small)
        } else {
          Text(version)
            .font(AppFont.caption)
            .foregroundStyle(AppColor.muted)
        }
      }
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!canPickVersion)
    .accessibilityLabel("Bible version: \(version)")
    .accessibilityHint("Selects a different translation")
  }
}

#Preview {
  ReaderTopBar(
    bookTitle: "Genesis",
    chapter: 1,
    version: "NIV",
    isLoadingVersion: false,
    canPickPassage: true,
    canPickVersion: true,
    horizontalPadding: 16,
    onPickPassage: {},
    onPickVersion: {}
  )
}
