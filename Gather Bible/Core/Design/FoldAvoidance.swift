import SwiftUI

/// Where a control goes when iPhone Duo is partly folded.
enum FoldAvoidance {
  /// Moves a control past a side-to-side fold, to the side of the screen it reopens on.
  /// A fold across the middle needs nothing, because the control is already in the lower half.
  static func leadingInset(for fold: CGRect?) -> CGFloat {
    guard let fold, fold.height > fold.width else { return 0 }
    return max(0, fold.maxX)
  }

  /// The active fold in this view's own space, or nil on devices and poses without one.
  fileprivate static func activeFold(in proxy: GeometryProxy) -> CGRect? {
    // Xcode 26 doesn't have this API. Swift 6.4 ships with Xcode 27.
    #if compiler(>=6.4)
      if #available(iOS 27.1, *) {
        return proxy.reservedRegions(kind: .division).first(where: \.isActive)?.frame
      }
    #endif
    return nil
  }
}

private struct FoldAvoidingModifier: ViewModifier {
  @State private var leadingInset: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .padding(.leading, leadingInset)
      .frame(maxWidth: .infinity)
      .onGeometryChange(for: CGRect?.self) { proxy in
        FoldAvoidance.activeFold(in: proxy)
      } action: { fold in
        leadingInset = FoldAvoidance.leadingInset(for: fold)
      }
  }
}

extension View {
  /// Keeps a custom control out of the fold. System controls do this on their own.
  func avoidingFold() -> some View {
    modifier(FoldAvoidingModifier())
  }
}
