//
//  WindowAppearanceApplier.swift
//  Gather Bible
//
//  Applies an interface style to the window hosting this view
//

import SwiftUI
import UIKit

/// Overrides the style on the hosting window rather than using
/// `preferredColorScheme`, which leaves an open sheet in its old scheme when
/// switching back to following the device. Only this view's window is affected,
/// so the external display keeps its own appearance.
struct WindowAppearanceApplier: UIViewRepresentable {
  let style: UIUserInterfaceStyle

  func makeUIView(context: Context) -> WindowStyleView {
    let view = WindowStyleView()
    view.isUserInteractionEnabled = false
    view.isAccessibilityElement = false
    return view
  }

  func updateUIView(_ uiView: WindowStyleView, context: Context) {
    uiView.style = style
  }
}

final class WindowStyleView: UIView {
  var style: UIUserInterfaceStyle = .unspecified {
    didSet { applyStyle() }
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    applyStyle()
  }

  private func applyStyle() {
    window?.overrideUserInterfaceStyle = style
  }
}
