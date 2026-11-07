//
//  SessionCodeBanner.swift
//  Gather Bible
//
//  Reusable component for displaying and copying a session code
//

import SwiftUI

/// The session code at a size people can read across a room, with copy and QR.
struct SessionCodeBanner: View {
  let code: String
  let isHost: Bool

  @State private var codeCopied = false
  @State private var showingQRCode = false
  @State private var resetTask: Task<Void, Never>?

  private var spokenCode: String {
    code.map { String($0) }.joined(separator: " ")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Session code")
        .font(AppFont.caption)
        .foregroundStyle(AppColor.muted)

      HStack(spacing: 4) {
        Text(code)
          .font(AppFont.display)
          .monospacedDigit()
          .foregroundStyle(AppColor.ink)
          .textSelection(.enabled)
          .accessibilityLabel("Session code: \(spokenCode)")

        Spacer(minLength: 8)

        iconButton(
          icon: codeCopied ? .check : .copy,
          label: codeCopied ? "Code copied" : "Copy code",
          action: copyCode
        )
        .accessibilityHint("Copies the session code to the clipboard")

        if isHost {
          iconButton(icon: .qrCode, label: "Show QR code") {
            showingQRCode = true
          }
          .accessibilityHint("Shows a QR code for others to scan and join")
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .sensoryFeedback(trigger: codeCopied) { _, copied in
      copied ? .success : nil
    }
    .sheet(isPresented: $showingQRCode) {
      SessionQRCodeView(sessionCode: code)
    }
  }

  private func iconButton(
    icon: AppIcon,
    label: LocalizedStringKey,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      AppIconView(icon)
        .foregroundStyle(AppColor.ink)
        .frame(width: 44, height: 44)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private func copyCode() {
    UIPasteboard.general.string = code
    codeCopied = true
    AccessibilityNotification.Announcement("Code copied").post()

    // Reset after 2 seconds, cancelling any in-flight reset.
    resetTask?.cancel()
    resetTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
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
