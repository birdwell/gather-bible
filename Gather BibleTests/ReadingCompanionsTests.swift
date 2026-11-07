import Testing

@testable import Gather_Bible

struct ReadingCompanionsTests {

  @Test func testNoCompanions() {
    #expect(ReadingCompanions.text(names: []) == "Just you so far")
  }

  @Test func testOneCompanion() {
    #expect(ReadingCompanions.text(names: ["Sam"]) == "with Sam")
  }

  @Test func testTwoCompanions() {
    #expect(ReadingCompanions.text(names: ["Sam", "Ana"]) == "with Sam and Ana")
  }

  @Test func testManyCompanions() {
    #expect(ReadingCompanions.text(names: ["Sam", "Ana", "Eli"]) == "with Sam and 2 others")
    #expect(ReadingCompanions.text(names: ["Sam", "Ana", "Eli", "Joy"]) == "with Sam and 3 others")
  }
}
