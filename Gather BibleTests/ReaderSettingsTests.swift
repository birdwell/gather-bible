import SwiftUI
import Testing
import YouVersionPlatformUI

@testable import Gather_Bible

struct ReaderSettingsTests {
  /// The SDK multiplies line spacing by the font size, so it has to stay a small ratio.
  /// An absolute value here pushes every line of the reader off screen.
  @Test func testLineSpacingIsARatioAtEveryTextSize() {
    let settings = ReaderSettingsViewModel()

    #expect(settings.textOptions(for: .large).lineSpacing == 0.6)
    #expect(settings.textOptions(for: .accessibility3).lineSpacing == 0.6)
  }
}
