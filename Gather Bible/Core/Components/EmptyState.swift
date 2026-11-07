//
//  EmptyState.swift
//  Gather Bible
//
//  The one empty, unavailable, and retry state, in words rather than a stock glyph
//

import SwiftUI

struct EmptyState: View {
  let title: LocalizedStringKey
  let message: String
  var actionTitle: LocalizedStringKey?
  var action: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(AppFont.heading)
        .foregroundStyle(AppColor.ink)
        .accessibilityAddTraits(.isHeader)

      Text(message)
        .font(AppFont.body)
        .foregroundStyle(AppColor.muted)

      if let actionTitle, let action {
        Button(actionTitle, action: action)
          .buttonStyle(.appSecondary)
          .padding(.top, 8)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }
}

#Preview {
  EmptyState(title: "No responses yet", message: "Answers appear here as people respond.")
}
