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
  var style: Variant = .prominent
  let action: () async -> Void

  /// The visual/semantic style of the button.
  ///
  /// Named `Variant` so it does not shadow SwiftUI's `ButtonStyle` protocol.
  /// `ButtonStyle` remains available as a type alias for source compatibility.
  enum Variant {
    case prominent, bordered, destructive
  }

  typealias ButtonStyle = Variant

  /// Tracks the in-flight action so we can guard against double-taps in the
  /// window before the caller's `isLoading` flag flips, and cancel on disappear.
  @State private var task: Task<Void, Never>?

  var body: some View {
    Button(role: style == .destructive ? .destructive : nil) {
      // Guard against re-entry: ignore taps while an action is already running.
      guard task == nil else { return }
      task = Task {
        await action()
        task = nil
      }
    } label: {
      Group {
        if isLoading {
          ProgressView()
            .accessibilityHidden(true)
        } else {
          Text(title)
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .accessibilityLabel(title)
    .modifier(LoadingAccessibilityValue(isLoading: isLoading))
    .modifier(ButtonStyleModifier(style: style))
    .controlSize(.large)
    .disabled(isDisabled || isLoading)
    .onDisappear {
      task?.cancel()
      task = nil
    }
  }
}

/// Applies an accessibility value of "Loading" only while loading, avoiding the
/// meaningless empty-string value that VoiceOver would otherwise announce.
private struct LoadingAccessibilityValue: ViewModifier {
  let isLoading: Bool

  func body(content: Content) -> some View {
    if isLoading {
      content.accessibilityValue(Text("Loading"))
    } else {
      content
    }
  }
}

private struct ButtonStyleModifier: ViewModifier {
  let style: AsyncActionButton.Variant

  func body(content: Content) -> some View {
    switch style {
    case .prominent:
      content.buttonStyle(.borderedProminent)
    case .bordered:
      content.buttonStyle(.bordered)
    case .destructive:
      // `Button(role: .destructive)` supplies the semantics and system red;
      // `.bordered` keeps the visual weight consistent with other styles.
      content.buttonStyle(.bordered)
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
