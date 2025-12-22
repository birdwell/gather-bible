import SwiftUI

// MARK: - Half Pill Shape

enum HalfPillSide { case left, right }

struct HalfPillShape: Shape {
  let side: HalfPillSide

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let radius = rect.height / 2

    switch side {
    case .left:
      path.addArc(
        center: CGPoint(x: radius, y: rect.midY),
        radius: radius,
        startAngle: .degrees(90),
        endAngle: .degrees(270),
        clockwise: false
      )
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      path.closeSubpath()

    case .right:
      path.move(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
      path.addArc(
        center: CGPoint(x: rect.maxX - radius, y: rect.midY),
        radius: radius,
        startAngle: .degrees(270),
        endAngle: .degrees(90),
        clockwise: false
      )
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.closeSubpath()
    }

    return path
  }
}
