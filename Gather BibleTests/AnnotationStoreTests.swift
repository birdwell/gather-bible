import Foundation
import Testing

@testable import Gather_Bible

@MainActor
struct AnnotationStoreTests {

  private func tempURL() -> URL {
    FileManager.default.temporaryDirectory.appending(path: "annotations-\(UUID()).json")
  }

  @Test func testHighlightSavesEachVerse() {
    let store = AnnotationStore(fileURL: tempURL())
    store.setHighlight(.honey, book: "JHN", chapter: 3, verses: [16, 17])

    #expect(store.annotation(book: "JHN", chapter: 3, verse: 16)?.highlight == .honey)
    #expect(store.annotation(book: "JHN", chapter: 3, verse: 17)?.highlight == .honey)
    #expect(store.annotations(book: "JHN", chapter: 3).map(\.verse) == [16, 17])
  }

  @Test func testRemovingOnlyHighlightDeletesTheAnnotation() {
    let store = AnnotationStore(fileURL: tempURL())
    store.setHighlight(.sage, book: "JHN", chapter: 3, verses: [16])
    store.setHighlight(nil, book: "JHN", chapter: 3, verses: [16])

    #expect(store.annotation(book: "JHN", chapter: 3, verse: 16) == nil)
  }

  @Test func testRemovingHighlightKeepsTheNote() {
    let store = AnnotationStore(fileURL: tempURL())
    store.setHighlight(.sky, book: "JHN", chapter: 3, verses: [16])
    store.setNote("So loved", book: "JHN", chapter: 3, verse: 16)
    store.setHighlight(nil, book: "JHN", chapter: 3, verses: [16])

    let annotation = store.annotation(book: "JHN", chapter: 3, verse: 16)
    #expect(annotation?.note == "So loved")
    #expect(annotation?.highlight == nil)
  }

  @Test func testBlankNoteRemovesIt() {
    let store = AnnotationStore(fileURL: tempURL())
    store.setNote("Temporary", book: "GEN", chapter: 1, verse: 1)
    store.setNote("   ", book: "GEN", chapter: 1, verse: 1)

    #expect(store.annotation(book: "GEN", chapter: 1, verse: 1) == nil)
  }

  @Test func testChangesSurviveReopening() {
    let url = tempURL()
    let store = AnnotationStore(fileURL: url)
    store.setHighlight(.honey, book: "PSA", chapter: 23, verses: [1])
    store.setNote("The Lord is my shepherd", book: "PSA", chapter: 23, verse: 1, endVerse: 3)

    let reopened = AnnotationStore(fileURL: url)
    let annotation = reopened.annotation(book: "PSA", chapter: 23, verse: 1)
    #expect(annotation?.highlight == .honey)
    #expect(annotation?.note == "The Lord is my shepherd")
    #expect(annotation?.noteReference == "Psalm 23:1-3")
  }

  @Test func testCorruptFileStartsEmpty() throws {
    let url = tempURL()
    try Data("not json".utf8).write(to: url)

    #expect(AnnotationStore(fileURL: url).annotations.isEmpty)
  }

  @Test func testNoteSearchMatchesTextAndReference() {
    let store = AnnotationStore(fileURL: tempURL())
    store.setNote("Grace upon grace", book: "JHN", chapter: 1, verse: 16)
    store.setNote("Be still", book: "PSA", chapter: 46, verse: 10)

    #expect(store.notes(matching: "grace").map(\.book) == ["JHN"])
    #expect(store.notes(matching: "psalm 46").map(\.book) == ["PSA"])
    #expect(store.notes().count == 2)
  }
}
