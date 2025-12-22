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

  @State private var codeCopied = false

  var body: some View {
    VStack(spacing: 8) {
      Text("Session Code")
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack(spacing: 12) {
        Text(code)
          .font(.system(.largeTitle, design: .monospaced))
          .fontWeight(.bold)
          .foregroundStyle(.primary)
          .kerning(4)

        Button {
          copyCode()
        } label: {
          Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
            .font(.title2)
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
          .font(.caption)
          .foregroundStyle(.orange)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
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
