import Testing

@testable import Gather_Bible

struct BibleBookNamesTests {

  @Test func testKnownCodes() {
    #expect(BibleBookNames.title(for: "GEN") == "Genesis")
    #expect(BibleBookNames.title(for: "jhn") == "John")
    #expect(BibleBookNames.title(for: "1CO") == "1 Corinthians")
  }

  @Test func testUnknownCodeFallsBack() {
    #expect(BibleBookNames.title(for: "XYZ") == "XYZ")
  }
}
