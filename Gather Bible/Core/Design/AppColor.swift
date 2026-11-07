//
//  AppColor.swift
//  Gather Bible
//
//  Color roles from DESIGN.md. Views use these instead of raw colors.
//

import SwiftUI
import UIKit

enum AppColor {
  /// The screen background.
  static let ground = dynamic(light: 0xF4F1E8, dark: 0x171613)
  /// One tone step off the ground, for grouped controls.
  static let surface = dynamic(light: 0xE9E5D8, dark: 0x26241F)
  /// Primary text and icons.
  static let ink = dynamic(light: 0x25231E, dark: 0xEDE8DC)
  /// Supporting text and quiet icons.
  static let muted = dynamic(light: 0x6A665B, dark: 0xA9A496)
  /// Actions, selection, and focus. Matches `AccentColor` in the asset catalog.
  static let accent = dynamic(light: 0x2E6A50, dark: 0x5FAF8A)
  /// Content on an `accent` fill.
  static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x171613)
  /// Marks on a highlight swatch, which stays mid-tone in both modes.
  static let onHighlight = dynamic(light: 0x25231E, dark: 0x171613)
  /// Errors and destructive actions.
  static let danger = dynamic(light: 0xA63A2E, dark: 0xE8907F)
  /// Words of Christ in Scripture text. Not used for any other purpose.
  static let wordsOfChrist = dynamic(light: 0xA63A2E, dark: 0xE8907F)

  private static func dynamic(light: UInt32, dark: UInt32) -> Color {
    Color(
      uiColor: UIColor { traits in
        uiColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
      })
  }

  private static func uiColor(hex: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1
    )
  }
}
