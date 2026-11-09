//
//  AppPrimaryButtonStyle.swift
//  Gather Bible
//
//  The one primary action on a screen
//

import SwiftUI

struct AppPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Label(configuration: configuration)
  }

  private struct Label: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
      configuration.label
        .font(AppFont.label)
        .foregroundStyle(isEnabled ? AppColor.onAccent : AppColor.muted)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .background(
          isEnabled ? AppColor.accent : AppColor.surface,
          in: RoundedRectangle(cornerRadius: 12)
        )
        .opacity(configuration.isPressed ? 0.8 : 1)
    }
  }
}

extension ButtonStyle where Self == AppPrimaryButtonStyle {
  static var appPrimary: AppPrimaryButtonStyle { AppPrimaryButtonStyle() }
}
