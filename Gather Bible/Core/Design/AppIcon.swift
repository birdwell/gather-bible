//
//  AppIcon.swift
//  Gather Bible
//
//  The app's one icon set: Phosphor Light, MIT licensed
//  (Resources/Licenses/Phosphor-LICENSE.txt).
//

import SwiftUI

enum AppIcon: String {
  case book = "icon-book-open"
  case community = "icon-users-three"
  case caretDown = "icon-caret-down"
  case caretLeft = "icon-caret-left"
  case caretRight = "icon-caret-right"
  case check = "icon-check"
  case copy = "icon-copy"
  case qrCode = "icon-qr-code"
  case warning = "icon-warning-circle"
  case share = "icon-export"
  case plus = "icon-plus"
  case trash = "icon-trash"
  case send = "icon-paper-plane-tilt"
  case offline = "icon-wifi-slash"
  case search = "icon-magnifying-glass"
  case note = "icon-note-pencil"
  case close = "icon-x"
}

/// An icon that inherits the current color and scales with Dynamic Type.
struct AppIconView: View {
  let icon: AppIcon
  @ScaledMetric private var size: CGFloat

  init(_ icon: AppIcon, size: CGFloat = 20) {
    self.icon = icon
    self._size = ScaledMetric(wrappedValue: size, relativeTo: .body)
  }

  var body: some View {
    Image(decorative: icon.rawValue)
      .resizable()
      .renderingMode(.template)
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}

#Preview {
  HStack(spacing: 16) {
    AppIconView(.book)
    AppIconView(.community)
    AppIconView(.copy)
    AppIconView(.qrCode)
  }
  .foregroundStyle(AppColor.ink)
  .padding()
}
