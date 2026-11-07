import Foundation
import Testing

@testable import Gather_Bible

struct NoteTargetTests {
  private func note(verse: Int, through endVerse: Int?) -> VerseAnnotation {
    var annotation = VerseAnnotation(book: "JHN", chapter: 8, verse: verse, updatedAt: .now)
    annotation.note = "A note"
    annotation.noteEndVerse = endVerse
    return annotation
  }

  private func target(_ verses: [Int], existing: VerseAnnotation? = nil) -> NoteTarget? {
    NoteTarget(
      selectedVerses: verses,
      book: "JHN",
      chapter: 8,
      existing: existing,
      selectionLabel: "selection"
    )
  }

  @Test func testSingleVerseOfExistingNoteKeepsItsRange() {
    let result = target([3], existing: note(verse: 3, through: 4))

    #expect(result?.verse == 3)
    #expect(result?.endVerse == 4)
    #expect(result?.reference == "John 8:3-4")
  }

  @Test func testNewSingleVerseNoteHasNoRange() {
    let result = target([3])

    #expect(result?.endVerse == nil)
    #expect(result?.reference == "selection")
  }

  @Test func testSelectingMoreVersesExtendsTheNote() {
    let result = target([3, 4, 5], existing: note(verse: 3, through: 4))

    #expect(result?.endVerse == 5)
    #expect(result?.reference == "selection")
  }

  @Test func testHighlightOnlyVerseIsTreatedAsNew() {
    let highlighted = VerseAnnotation(book: "JHN", chapter: 8, verse: 3, updatedAt: .now)

    #expect(target([3], existing: highlighted)?.reference == "selection")
  }

  @Test func testEmptySelectionHasNoTarget() {
    #expect(target([]) == nil)
  }

  @Test func testSelectionWithGapsHasNoTarget() {
    #expect(target([16, 18]) == nil)
  }

  @Test func testUnbrokenSelectionCoversTheRange() {
    #expect(target([18, 16, 17])?.verse == 16)
    #expect(target([18, 16, 17])?.endVerse == 18)
  }
}
