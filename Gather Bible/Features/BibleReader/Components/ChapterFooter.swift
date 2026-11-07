import SwiftUI

/// Chapter navigation at the end of the text, where a reader finishes.
struct ChapterFooter: View {
  let canGoPrevious: Bool
  let canGoNext: Bool
  let onPrevious: () -> Void
  let onNext: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      if canGoPrevious {
        Button(action: onPrevious) {
          HStack(spacing: 4) {
            AppIconView(.caretLeft, size: 16)
            Text("Previous")
          }
        }
        .buttonStyle(.appQuiet)
        .keyboardShortcut(.leftArrow, modifiers: [])
        .accessibilityLabel("Previous chapter")
      }

      Spacer(minLength: 0)

      if canGoNext {
        Button(action: onNext) {
          HStack(spacing: 8) {
            Text("Next chapter")
            AppIconView(.caretRight, size: 16)
          }
        }
        .buttonStyle(.appSecondary)
        .keyboardShortcut(.rightArrow, modifiers: [])
      }
    }
  }
}

#Preview {
  ChapterFooter(canGoPrevious: true, canGoNext: true, onPrevious: {}, onNext: {})
    .padding()
}
