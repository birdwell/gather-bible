//
//  AppAppearanceSetup.swift
//  Gather Bible
//
//  Typeface for the UIKit controls SwiftUI can't style directly
//

import UIKit

enum AppAppearanceSetup {
  static func apply() {
    let descriptor = UIFontDescriptor(fontAttributes: [.family: AppFont.family])
    let font = UIFont(descriptor: descriptor, size: 15)
    UISegmentedControl.appearance().setTitleTextAttributes([.font: font], for: .normal)
    UISegmentedControl.appearance().setTitleTextAttributes([.font: font], for: .selected)
  }
}
