//
//  AppFont.swift
//  Gather Bible
//
//  Text styles from DESIGN.md. Every style scales with Dynamic Type.
//

import SwiftUI

enum AppFont {
  /// Bundled typeface, and the default for reading.
  static let family = "Newsreader"

  /// The large number that opens a chapter.
  static let chapter = Font.custom(family, size: 72, relativeTo: .largeTitle).weight(.medium)
  /// One large statement on a screen: a passage, a verse, or a session code.
  static let display = Font.custom(family, size: 36, relativeTo: .largeTitle).weight(.medium)
  /// Sheet titles and the current book.
  static let heading = Font.custom(family, size: 20, relativeTo: .title3).weight(.medium)
  /// Default interface text.
  static let body = Font.custom(family, size: 17, relativeTo: .body)
  /// Buttons and selected items.
  static let label = Font.custom(family, size: 17, relativeTo: .body).weight(.medium)
  /// Supporting text.
  static let caption = Font.custom(family, size: 14, relativeTo: .footnote)
}
