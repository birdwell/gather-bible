//
//  SessionCodeBanner.swift
//  Gather Bible
//
//  Reusable component for displaying and copying a session code
//

import SwiftUI

/// A banner component that displays a session code with copy functionality
struct SessionCodeBanner: View {
  let code: String
  let isHost: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @State private var codeCopied = false

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  var body: some View {
    VStack(spacing: isRegularWidth ? 12 : 8) {
      Text("Session Code")
        .font(isRegularWidth ? .subheadline : .caption)
        .foregroundStyle(.secondary)

      HStack(spacing: isRegularWidth ? 16 : 12) {
        Text(code)
          .font(.system(size: isRegularWidth ? 48 : 34, weight: .bold, design: .monospaced))
          .foregroundStyle(.primary)
          .kerning(isRegularWidth ? 6 : 4)

        Button {
          copyCode()
        } label: {
          Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
            .font(isRegularWidth ? .title : .title2)
            .foregroundStyle(codeCopied ? .green : .accentColor)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
      }

      if codeCopied {
        Text("Copied!")
          .font(.caption)
          .foregroundStyle(.green)
          .transition(.opacity.combined(with: .scale))
      }

      if isHost {
        Label("You're hosting", systemImage: "crown.fill")
          .font(isRegularWidth ? .subheadline : .caption)
          .foregroundStyle(.orange)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(isRegularWidth ? 24 : 16)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: isRegularWidth ? 16 : 12))
    .animation(.easeInOut(duration: 0.2), value: codeCopied)
  }

  private func copyCode() {
    UIPasteboard.general.string = code
    codeCopied = true

    // Reset after 2 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      codeCopied = false
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    SessionCodeBanner(code: "ABC123", isHost: true)
    SessionCodeBanner(code: "XYZ789", isHost: false)
  }
  .padding()
}
