//
//  AppSurfaces.swift
//  Gather Bible
//
//  Shared sheet and input treatments
//

import SwiftUI

extension View {
  /// Puts a sheet and any lists inside it on the app's ground color.
  func appSheet() -> some View {
    scrollContentBackground(.hidden)
      .presentationBackground(AppColor.ground)
  }

  /// An inline navigation title set in the app's typeface.
  func appNavigationTitle(_ title: LocalizedStringKey) -> some View {
    navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(title)
            .font(AppFont.heading)
            .foregroundStyle(AppColor.ink)
        }
      }
  }

  /// The shared look for single-line text input.
  func appField() -> some View {
    font(AppFont.body)
      .foregroundStyle(AppColor.ink)
      .padding(.horizontal, 16)
      .frame(minHeight: 44)
      .padding(.vertical, 4)
      .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 8))
  }
}
