//
//  EmptyStateView.swift
//  Gather Bible
//
//  Reusable empty state component with icon, title, and subtitle
//

import SwiftUI

/// A standardized empty state view with icon, title, and subtitle
struct EmptyStateView: View {
  let icon: String
  let title: String
  var subtitle: String? = nil
  var iconSize: CGFloat = 48

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: iconSize))
        .foregroundStyle(.tertiary)

      Text(title)
        .font(.headline)
        .foregroundStyle(.secondary)

      if let subtitle {
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.tertiary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}

#Preview {
  VStack(spacing: 32) {
    EmptyStateView(
      icon: "doc.text",
      title: "No drafts",
      subtitle: "Create a discussion and save it as a draft"
    )

    EmptyStateView(icon: "person.2.slash", title: "No responses yet")
  }
}
