//
//  AppAppearance.swift
//  Gather Bible
//
//  The user's light/dark preference for the app
//

import SwiftUI
import UIKit

enum AppAppearance: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  /// `UserDefaults` key the preference is stored under.
  static let storageKey = "app_appearance"

  var id: Self { self }

  var title: LocalizedStringKey {
    switch self {
    case .system: "System"
    case .light: "Light"
    case .dark: "Dark"
    }
  }

  /// The style to force on the window; `.unspecified` follows the device setting.
  var interfaceStyle: UIUserInterfaceStyle {
    switch self {
    case .system: .unspecified
    case .light: .light
    case .dark: .dark
    }
  }
}
