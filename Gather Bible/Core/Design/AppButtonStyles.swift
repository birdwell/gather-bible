//
//  AppButtonStyles.swift
//  Gather Bible
//
//  Secondary and quiet actions. See AppPrimaryButtonStyle for the main action.
//

import SwiftUI

/// A supporting action, set on a surface tone.
struct AppSecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    StyledLabel(configuration: configuration)
  }

  private struct StyledLabel: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
      configuration.label
        .font(AppFont.label)
        .foregroundStyle(foreground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
        .opacity(configuration.isPressed ? 0.8 : 1)
    }

    private var foreground: Color {
      guard isEnabled else { return AppColor.muted }
      return configuration.role == .destructive ? AppColor.danger : AppColor.ink
    }
  }
}

/// A text-only action that should recede, such as leaving a session.
struct AppQuietButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppFont.label)
      .foregroundStyle(configuration.role == .destructive ? AppColor.danger : AppColor.muted)
      .frame(minHeight: 44)
      .contentShape(Rectangle())
      .opacity(configuration.isPressed ? 0.6 : 1)
  }
}

extension ButtonStyle where Self == AppSecondaryButtonStyle {
  static var appSecondary: AppSecondaryButtonStyle { AppSecondaryButtonStyle() }
}

extension ButtonStyle where Self == AppQuietButtonStyle {
  static var appQuiet: AppQuietButtonStyle { AppQuietButtonStyle() }
}
