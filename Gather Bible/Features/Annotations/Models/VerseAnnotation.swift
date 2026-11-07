//
//  VerseAnnotation.swift
//  Gather Bible
//

import Foundation

/// Highlight colors, stored by name so the shades can change without touching saved data.
enum HighlightColor: String, Codable, CaseIterable, Identifiable {
  case honey
  case sage
  case sky

  var id: Self { self }

  var name: String {
    switch self {
    case .honey: "Honey"
    case .sage: "Sage"
    case .sky: "Sky"
    }
  }

  /// ARGB. Translucent so the same shade works behind ink in light and dark.
  var hex: String {
    switch self {
    case .honey: "#66E0B040"
    case .sage: "#5C7FB08A"
    case .sky: "#5C6FA3D0"
    }
  }
}

/// A highlight and note on a verse. Annotations belong to the verse, not the translation,
/// so they follow people when they switch versions.
struct VerseAnnotation: Codable, Equatable, Identifiable {
  let book: String
  let chapter: Int
  let verse: Int
  var highlight: HighlightColor?
  var note: String?
  /// The last verse a note covers, when it spans more than one.
  var noteEndVerse: Int?
  var updatedAt: Date

  var id: String { Self.id(book: book, chapter: chapter, verse: verse) }

  var isEmpty: Bool { highlight == nil && note == nil }

  /// Such as "John 3:16" or, for a note covering several verses, "John 3:16-18".
  var noteReference: String {
    let base = "\(BibleBookNames.title(for: book)) \(chapter):\(verse)"
    guard let noteEndVerse, noteEndVerse > verse else { return base }
    return "\(base)-\(noteEndVerse)"
  }

  static func id(book: String, chapter: Int, verse: Int) -> String {
    "\(book).\(chapter).\(verse)"
  }
}
