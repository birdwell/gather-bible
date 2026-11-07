import CoreGraphics
import Testing

@testable import Gather_Bible

struct FoldAvoidanceTests {
  @Test func testNoFoldLeavesTheControlInPlace() {
    #expect(FoldAvoidance.leadingInset(for: nil) == 0)
  }

  @Test func testSideToSideFoldMovesTheControlPastIt() {
    let fold = CGRect(x: 320, y: 0, width: 30, height: 900)

    #expect(FoldAvoidance.leadingInset(for: fold) == 350)
  }

  @Test func testFoldAcrossTheMiddleLeavesTheControlInPlace() {
    let fold = CGRect(x: 0, y: 460, width: 670, height: 30)

    #expect(FoldAvoidance.leadingInset(for: fold) == 0)
  }
}
