//
//  AsyncActionButton.swift
//  Gather Bible
//
//  Reusable button with loading state for async actions
//

import SwiftUI

/// A button that shows a loading indicator during async operations
struct AsyncActionButton: View {
  let title: String
  let isLoading: Bool
  var isDisabled: Bool = false
  var style: ButtonStyle = .prominent
  let action: () async -> Void

  enum ButtonStyle {
    case prominent, bordered, destructive
  }

  var body: some View {
    Button {
      Task { await action() }
    } label: {
      Group {
        if isLoading {
          ProgressView()
            .tint(style == .prominent ? .white : .accentColor)
        } else {
          Text(title)
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .modifier(ButtonStyleModifier(style: style))
    .controlSize(.large)
    .disabled(isDisabled || isLoading)
  }
}

private struct ButtonStyleModifier: ViewModifier {
  let style: AsyncActionButton.ButtonStyle

  func body(content: Content) -> some View {
    switch style {
    case .prominent:
      content.buttonStyle(.borderedProminent)
    case .bordered:
      content.buttonStyle(.bordered)
    case .destructive:
      content.buttonStyle(.bordered).tint(.red)
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    AsyncActionButton(title: "Submit", isLoading: false) {}
    AsyncActionButton(title: "Loading...", isLoading: true) {}
    AsyncActionButton(title: "Disabled", isLoading: false, isDisabled: true) {}
    AsyncActionButton(title: "Delete", isLoading: false, style: .destructive) {}
  }
  .padding()
}
