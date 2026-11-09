import Foundation
import YouVersionPlatformCore
import YouVersionPlatformUI

/// Builds the text placed on the clipboard when verses are copied.
enum VerseClipboard {
  /// Returns nil when any verse can't be loaded, so a copy is never missing verses.
  static func text(
    for verses: [BibleReference],
    label: String,
    load: (BibleReference) async throws -> String? = BibleVersionRendering.plainTextOf
  ) async -> String? {
    var passages: [String] = []
    for verse in verses.sorted() {
      guard let text = try? await load(verse) else { return nil }
      passages.append(text)
    }
    return format(passages: passages, label: label)
  }

  static func format(passages: [String], label: String) -> String? {
    let cleaned = passages
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    guard cleaned.count == passages.count, !cleaned.isEmpty else { return nil }
    return "\(cleaned.joined(separator: " "))\n\(label)"
  }
}
