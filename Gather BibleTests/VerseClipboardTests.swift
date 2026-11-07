import Testing
import YouVersionPlatformCore

@testable import Gather_Bible

struct VerseClipboardTests {
  private func verse(_ number: Int) -> BibleReference {
    BibleReference(versionId: 111, bookUSFM: "JHN", chapter: 8, verse: number)
  }

  @Test func testJoinsVersesInOrderAndAddsTheReference() async {
    let text = await VerseClipboard.text(for: [verse(5), verse(2)], label: "John 8:2, 5") { reference in
      " verse \(reference.verseStart ?? 0) "
    }

    #expect(text == "verse 2 verse 5\nJohn 8:2, 5")
  }

  @Test func testMissingVerseFailsTheWholeCopy() async {
    let text = await VerseClipboard.text(for: [verse(2), verse(5)], label: "John 8:2, 5") { reference in
      reference.verseStart == 5 ? nil : "verse"
    }

    #expect(text == nil)
  }

  @Test func testLoadErrorFailsTheCopy() async {
    struct LoadFailed: Error {}

    let text = await VerseClipboard.text(for: [verse(2)], label: "John 8:2") { _ in
      throw LoadFailed()
    }

    #expect(text == nil)
  }

  @Test func testBlankTextFailsTheCopy() {
    #expect(VerseClipboard.format(passages: ["  \n"], label: "John 8:2") == nil)
    #expect(VerseClipboard.format(passages: [], label: "John 8:2") == nil)
  }
}
