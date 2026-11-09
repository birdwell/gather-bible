import SwiftUI

/// The reader's controls, as system toolbar items so iPhone Duo can move them to the side.
///
/// iOS only moves items with an icon and title. The passage and version names are too wide
/// for the side, and AirPlay is a custom view, so those three stay in the navigation bar.
struct ReaderToolbar: ToolbarContent {
  let bookTitle: String
  let chapter: Int
  let version: String
  let isLoadingVersion: Bool
  let canPickPassage: Bool
  let canPickVersion: Bool
  let onPickPassage: () -> Void
  let onPickVersion: () -> Void
  let onSearch: () -> Void
  let onSettings: () -> Void

  var body: some ToolbarContent {
    // Together on one side, so search and text size still fit beside a top tab bar.
    ToolbarItem(placement: .topBarLeading) {
      HStack(spacing: 8) {
        passageButton
        versionButton
      }
    }
    .withoutSharedBackground()

    ToolbarItem(placement: .topBarTrailing) {
      AirPlayButton(
        tintColor: UIColor(AppColor.muted),
        activeTintColor: UIColor(AppColor.accent)
      )
      .frame(width: 44, height: 44)
      .accessibilityLabel("AirPlay")
      .accessibilityHint("Streams to Apple TV or other AirPlay devices")
    }
    .withoutSharedBackground()

    ToolbarItem(placement: .topBarTrailing) {
      Button(action: onSearch) {
        Label {
          Text("Search")
        } icon: {
          AppIconView(.search)
        }
      }
      .tint(AppColor.muted)
      .accessibilityHint("Searches the Bible and your notes")
    }
    .withoutSharedBackground()

    ToolbarItem(placement: .topBarTrailing) {
      Button(action: onSettings) {
        Label("Reader settings", systemImage: "textformat.size")
      }
      .tint(AppColor.muted)
      .accessibilityHint("Adjusts appearance, text size, and font")
    }
    .withoutSharedBackground()
  }

  private var passageButton: some View {
    Button(action: onPickPassage) {
      HStack(spacing: 4) {
        Text(bookTitle)
          .font(AppFont.heading)
          .foregroundStyle(AppColor.ink)
          .lineLimit(1)
          .fixedSize()
        AppIconView(.caretDown, size: 14)
          .foregroundStyle(AppColor.muted)
      }
      .frame(minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!canPickPassage)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
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
            .fixedSize()
        }
      }
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!canPickVersion)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    .accessibilityLabel("Bible version: \(version)")
    .accessibilityHint("Selects a different translation")
  }
}

extension ToolbarContent {
  /// Removes the glass capsule so items sit directly on the page, like the rest of the reader.
  @ToolbarContentBuilder
  fileprivate func withoutSharedBackground() -> some ToolbarContent {
    if #available(iOS 26, *) {
      sharedBackgroundVisibility(.hidden)
    } else {
      self
    }
  }
}
