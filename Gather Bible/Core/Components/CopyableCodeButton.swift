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
  var iconSize: CGFloat = 20

  @State private var copied = false
  @State private var resetTask: Task<Void, Never>?

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
      AppIconView(copied ? .check : .copy, size: iconSize)
        .foregroundStyle(AppColor.ink)
        .frame(minWidth: 44, minHeight: 44)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Copy code")
    .modifier(CopiedAccessibilityValue(copied: copied))
    .accessibilityHint("Copies the code to the clipboard")
    .onDisappear {
      resetTask?.cancel()
      resetTask = nil
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
        .font(AppFont.display)
      CopyableCodeButton(code: "ABC123")
    }

    HStack {
      Text("XYZ789")
      CopyableCodeButton(code: "XYZ789", iconSize: 16)
    }
  }
  .padding()
}
