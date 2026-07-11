import SwiftUI
import UIKit
import YouVersionPlatformUI

@Observable
final class ReaderSettingsViewModel {
  private let fontFamilyKey = "reader_font_family"
  private let fontSizeKey = "reader_font_size"

  var fontFamily: String {
    didSet { UserDefaults.standard.set(fontFamily, forKey: fontFamilyKey) }
  }

  var fontSize: CGFloat {
    didSet { UserDefaults.standard.set(fontSize, forKey: fontSizeKey) }
  }

  let availableFontSizes: [CGFloat] = [12, 15, 18, 21, 24, 28, 32]

  let availableFonts: [ReaderFont] = [
    ReaderFont(name: "System Serif", family: "New York", category: .system),
    ReaderFont(name: "System Sans", family: ".AppleSystemUIFont", category: .system),
    ReaderFont(name: "Georgia", family: "Georgia", category: .serif),
    ReaderFont(name: "Palatino", family: "Palatino", category: .serif),
    ReaderFont(name: "Baskerville", family: "Baskerville", category: .serif),
    ReaderFont(name: "Charter", family: "Charter", category: .serif),
    ReaderFont(name: "Times New Roman", family: "Times New Roman", category: .serif),
    ReaderFont(name: "Avenir Next", family: "Avenir Next", category: .sansSerif),
    ReaderFont(name: "Helvetica Neue", family: "Helvetica Neue", category: .sansSerif),
    ReaderFont(name: "Verdana", family: "Verdana", category: .sansSerif),
  ]

  var currentFontIndex: Int {
    availableFonts.firstIndex { $0.family == fontFamily } ?? 0
  }

  var currentSizeIndex: Int {
    availableFontSizes.firstIndex(of: fontSize) ?? 3
  }

  var canIncreaseFontSize: Bool {
    currentSizeIndex < availableFontSizes.count - 1
  }

  var canDecreaseFontSize: Bool {
    currentSizeIndex > 0
  }

  /// Text options using the raw chosen size, without Dynamic Type scaling.
  /// Prefer `textOptions(for:)` for on-screen reading so accessibility text
  /// sizes are respected.
  var textOptions: BibleTextOptions {
    makeTextOptions(size: fontSize)
  }

  /// Text options whose effective size scales with the system Dynamic Type
  /// setting. The user's chosen step is treated as the base `.body` size and
  /// scaled via `UIFontMetrics`, so accessibility sizes are no longer capped
  /// at the 32pt maximum step.
  func textOptions(for dynamicTypeSize: DynamicTypeSize) -> BibleTextOptions {
    let traits = UITraitCollection(
      preferredContentSizeCategory: dynamicTypeSize.uiContentSizeCategory)
    let scaledSize = UIFontMetrics(forTextStyle: .body)
      .scaledValue(for: fontSize, compatibleWith: traits)
    return makeTextOptions(size: scaledSize)
  }

  private func makeTextOptions(size: CGFloat) -> BibleTextOptions {
    BibleTextOptions(
      fontFamily: fontFamily,
      fontSize: size,
      lineSpacing: size * 0.6,
      paragraphSpacing: size * 0.5
    )
  }

  init() {
    let storedFamily = UserDefaults.standard.string(forKey: fontFamilyKey)
    let storedSize = UserDefaults.standard.double(forKey: fontSizeKey)

    fontFamily = storedFamily ?? "Georgia"
    fontSize = storedSize > 0 ? storedSize : 21
  }

  func increaseFontSize() {
    guard canIncreaseFontSize else { return }
    fontSize = availableFontSizes[currentSizeIndex + 1]
  }

  func decreaseFontSize() {
    guard canDecreaseFontSize else { return }
    fontSize = availableFontSizes[currentSizeIndex - 1]
  }

  func selectFont(_ font: ReaderFont) {
    fontFamily = font.family
  }
}

struct ReaderFont: Identifiable, Equatable {
  let id = UUID()
  let name: String
  let family: String
  let category: FontCategory

  enum FontCategory {
    case system
    case serif
    case sansSerif
  }
}

// MARK: - Dynamic Type Mapping

extension DynamicTypeSize {
  /// Maps a SwiftUI `DynamicTypeSize` to the equivalent `UIContentSizeCategory`
  /// so `UIFontMetrics` can scale a value against it.
  var uiContentSizeCategory: UIContentSizeCategory {
    switch self {
    case .xSmall: return .extraSmall
    case .small: return .small
    case .medium: return .medium
    case .large: return .large
    case .xLarge: return .extraLarge
    case .xxLarge: return .extraExtraLarge
    case .xxxLarge: return .extraExtraExtraLarge
    case .accessibility1: return .accessibilityMedium
    case .accessibility2: return .accessibilityLarge
    case .accessibility3: return .accessibilityExtraLarge
    case .accessibility4: return .accessibilityExtraExtraLarge
    case .accessibility5: return .accessibilityExtraExtraExtraLarge
    @unknown default: return .large
    }
  }
}

// MARK: - Environment Key

private struct ReaderSettingsKey: EnvironmentKey {
  static let defaultValue = ReaderSettingsViewModel()
}

extension EnvironmentValues {
  var readerSettings: ReaderSettingsViewModel {
    get { self[ReaderSettingsKey.self] }
    set { self[ReaderSettingsKey.self] = newValue }
  }
}
