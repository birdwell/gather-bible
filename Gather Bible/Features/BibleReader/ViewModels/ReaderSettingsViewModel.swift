import SwiftUI
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

  var textOptions: BibleTextOptions {
    BibleTextOptions(
      fontFamily: fontFamily,
      fontSize: fontSize,
      lineSpacing: fontSize * 0.6,
      paragraphSpacing: fontSize * 0.5
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
