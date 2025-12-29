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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Button {
      UIPasteboard.general.string = code
      copied = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        copied = false
      }
    } label: {
      Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
        .font(iconFont)
        .foregroundStyle(copied ? .green : .accentColor)
        .contentTransition(.symbolEffect(.replace))
        .frame(minWidth: 44, minHeight: 44)
    }
    .buttonStyle(.borderless)
    .accessibilityLabel(copied ? "Code copied" : "Copy code")
    .accessibilityHint(copied ? "Code is already copied to clipboard" : "Double tap to copy to clipboard")
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
