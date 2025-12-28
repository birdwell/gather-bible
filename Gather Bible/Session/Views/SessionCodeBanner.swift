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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var codeCopied = false

  @ScaledMetric(relativeTo: .largeTitle) private var codeFontSize: CGFloat = 34

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  private var spokenCode: String {
    code.map { String($0) }.joined(separator: " ")
  }

  private var bannerAccessibilityLabel: String {
    var label = "Session Code: \(spokenCode)"
    if isHost {
      label += ". You're hosting"
    }
    if codeCopied {
      label += ". Copied to clipboard"
    }
    return label
  }

  var body: some View {
    VStack(spacing: isRegularWidth ? 12 : 8) {
      Text("Session Code")
        .font(isRegularWidth ? .subheadline : .caption)
        .foregroundStyle(.secondary)

      HStack(spacing: isRegularWidth ? 16 : 12) {
        Text(code)
          .font(.system(size: isRegularWidth ? codeFontSize * 1.4 : codeFontSize, weight: .bold, design: .monospaced))
          .foregroundStyle(.primary)
          .kerning(isRegularWidth ? 6 : 4)
          .accessibilityLabel(spokenCode)

        Button {
          copyCode()
        } label: {
          Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
            .font(isRegularWidth ? .title : .title2)
            .foregroundStyle(codeCopied ? .green : .accentColor)
            .contentTransition(.symbolEffect(.replace))
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(codeCopied ? "Code copied" : "Copy code")
        .accessibilityHint(codeCopied ? "Code is already copied to clipboard" : "Double tap to copy session code to clipboard")
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
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: codeCopied)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(bannerAccessibilityLabel)
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
