//
//  AnnotationStore.swift
//  Gather Bible
//
//  Highlights and notes, saved on this device with no account needed
//

import Foundation
import Observation

@MainActor
@Observable
final class AnnotationStore {
  static let shared = AnnotationStore(fileURL: AnnotationStore.defaultFileURL)

  private(set) var annotations: [String: VerseAnnotation] = [:]

  private let fileURL: URL

  init(fileURL: URL) {
    self.fileURL = fileURL
    load()
  }

  private static var defaultFileURL: URL {
    URL.applicationSupportDirectory.appending(path: "verse-annotations.json")
  }

  // MARK: - Reading

  func annotations(book: String, chapter: Int) -> [VerseAnnotation] {
    annotations.values
      .filter { $0.book == book && $0.chapter == chapter }
      .sorted { $0.verse < $1.verse }
  }

  func annotation(book: String, chapter: Int, verse: Int) -> VerseAnnotation? {
    annotations[VerseAnnotation.id(book: book, chapter: chapter, verse: verse)]
  }

  /// Every note, newest first. A non-empty query narrows them by note text or reference.
  func notes(matching query: String = "") -> [VerseAnnotation] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    return annotations.values
      .filter { annotation in
        guard let note = annotation.note else { return false }
        return trimmed.isEmpty
          || note.localizedCaseInsensitiveContains(trimmed)
          || annotation.noteReference.localizedCaseInsensitiveContains(trimmed)
      }
      .sorted { $0.updatedAt > $1.updatedAt }
  }

  // MARK: - Writing

  /// Applies a color to each verse, or removes the highlight when the color is nil.
  /// Returns false, with nothing changed, if the change couldn't be saved.
  @discardableResult
  func setHighlight(_ color: HighlightColor?, book: String, chapter: Int, verses: [Int]) -> Bool {
    commit {
      for verse in verses {
        update(book: book, chapter: chapter, verse: verse) { $0.highlight = color }
      }
    }
  }

  /// Saves a note on the first verse, covering through `endVerse`. Blank text removes it.
  /// Returns false, with nothing changed, if the change couldn't be saved.
  @discardableResult
  func setNote(
    _ text: String,
    book: String,
    chapter: Int,
    verse: Int,
    endVerse: Int? = nil
  ) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return commit {
      update(book: book, chapter: chapter, verse: verse) {
        $0.note = trimmed.isEmpty ? nil : trimmed
        $0.noteEndVerse = trimmed.isEmpty ? nil : endVerse
      }
    }
  }

  /// Applies a change and saves it, undoing it if the save fails, so the screen never shows
  /// something that would vanish on the next launch.
  private func commit(_ change: () -> Void) -> Bool {
    let previous = annotations
    change()
    guard save() else {
      annotations = previous
      return false
    }
    return true
  }

  private func update(
    book: String,
    chapter: Int,
    verse: Int,
    change: (inout VerseAnnotation) -> Void
  ) {
    let id = VerseAnnotation.id(book: book, chapter: chapter, verse: verse)
    var annotation =
      annotations[id]
      ?? VerseAnnotation(book: book, chapter: chapter, verse: verse, updatedAt: .now)
    change(&annotation)
    annotation.updatedAt = .now
    annotations[id] = annotation.isEmpty ? nil : annotation
  }

  // MARK: - Persistence

  private func load() {
    guard let data = try? Data(contentsOf: fileURL),
      let saved = try? JSONDecoder().decode([VerseAnnotation].self, from: data)
    else { return }
    annotations = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
  }

  private func save() -> Bool {
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(Array(annotations.values))
      try data.write(to: fileURL, options: .atomic)
      return true
    } catch {
      return false
    }
  }
}
