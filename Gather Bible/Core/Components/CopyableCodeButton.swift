//
//  CopyableCodeButton.swift
//  Gather Bible
//
//  Reusable button for copying a code to clipboard with visual feedback
//

import SwiftUI

/// A button that copies a code string to clipboard with animated feedback
struct CopyableCodeButton: View {
  let code: String
  var iconFont: Font = .title2

  @State private var copied = false
  @State private var resetTask: Task<Void, Never>?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Button {
      UIPasteboard.general.string = code
      copied = true

      // Announce the result for VoiceOver users; the label stays stable so the
      // control keeps its identity instead of morphing into a different button.
      AccessibilityNotification.Announcement("Copied").post()

      // Cancel any in-flight reset so a re-tap restarts the 2s window.
      resetTask?.cancel()
      resetTask = Task {
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        copied = false
      }
    } label: {
      Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
        .font(iconFont)
        .foregroundStyle(copied ? .green : .accentColor)
        .modifier(CopyIconTransition(enabled: !reduceMotion))
        .frame(minWidth: 44, minHeight: 44)
    }
    .buttonStyle(.borderless)
    .accessibilityLabel("Copy code")
    .modifier(CopiedAccessibilityValue(copied: copied))
    .accessibilityHint("Copies the code to the clipboard")
    .onDisappear {
      resetTask?.cancel()
      resetTask = nil
    }
  }
}

/// Applies the symbol-replace transition only when Reduce Motion is off.
private struct CopyIconTransition: ViewModifier {
  let enabled: Bool

  func body(content: Content) -> some View {
    if enabled {
      content.contentTransition(.symbolEffect(.replace))
    } else {
      content
    }
  }
}

/// Exposes the copied state as an accessibility value without mutating the label.
private struct CopiedAccessibilityValue: ViewModifier {
  let copied: Bool

  func body(content: Content) -> some View {
    if copied {
      content.accessibilityValue(Text("Copied"))
    } else {
      content
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    HStack {
      Text("ABC123")
        .font(.system(.largeTitle, design: .monospaced, weight: .bold))
      CopyableCodeButton(code: "ABC123")
    }

    HStack {
      Text("XYZ789")
      CopyableCodeButton(code: "XYZ789", iconFont: .body)
    }
  }
  .padding()
}
