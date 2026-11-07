//
//  ReaderHighlightRenderer.swift
//  Gather Bible
//

import YouVersionPlatformCore

/// Shows saved highlights in the SDK's text view, which draws what's in its shared cache.
/// The SDK's own sync only runs for signed-in users and only replaces highlights it marked
/// as coming from the server, so it can't remove these.
@MainActor
enum ReaderHighlightRenderer {
  static func apply(_ annotations: [VerseAnnotation], to chapter: BibleReference) {
    let cache = BibleHighlightsCache.shared

    let shown = cache.highlights(overlapping: chapter)
    if !shown.isEmpty {
      cache.removeHighlights(shown.map(\.reference))
    }

    let highlights: [BibleHighlight] = annotations.compactMap { annotation in
      guard let color = annotation.highlight else { return nil }
      return BibleHighlight(
        BibleReference(
          versionId: chapter.versionId,
          bookUSFM: annotation.book,
          chapter: annotation.chapter,
          verse: annotation.verse
        ),
        color: color.hex
      )
    }
    if !highlights.isEmpty {
      cache.addHighlights(highlights)
    }
  }
}
