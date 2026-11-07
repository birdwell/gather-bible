import SwiftUI

/// Appears while verses are selected: highlight, write a note, copy, or dismiss.
struct VerseActionBar: View {
  let reference: String
  let activeColor: HighlightColor?
  let hasNote: Bool
  let errorMessage: String?
  let onHighlight: (HighlightColor?) -> Void
  let onNote: () -> Void
  let onCopy: () -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(errorMessage ?? reference)
        .font(AppFont.caption)
        .foregroundStyle(errorMessage == nil ? AppColor.muted : AppColor.danger)
        .lineLimit(1)
        .padding(.leading, 8)

      HStack(spacing: 0) {
        ForEach(HighlightColor.allCases) { color in
          swatch(color)
        }

        Spacer(minLength: 8)

        iconButton(.note, label: hasNote ? "Edit note" : "Add note", action: onNote)
        iconButton(.copy, label: "Copy verses", action: onCopy)
        iconButton(.close, label: "Clear selection", action: onClose)
      }
    }
    .padding(8)
    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
  }

  /// Tapping the active color removes the highlight. The check keeps it clear without color.
  private func swatch(_ color: HighlightColor) -> some View {
    let isActive = activeColor == color

    return Button {
      onHighlight(isActive ? nil : color)
    } label: {
      ZStack {
        Circle()
          .fill(Color(highlight: color))
          .frame(width: 28, height: 28)
        if isActive {
          AppIconView(.check, size: 16)
            .foregroundStyle(AppColor.onHighlight)
        }
      }
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isActive ? "Remove \(color.name) highlight" : "Highlight \(color.name)")
  }

  private func iconButton(
    _ icon: AppIcon,
    label: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      AppIconView(icon)
        .foregroundStyle(AppColor.ink)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

extension Color {
  /// An opaque preview of a highlight color for swatches.
  init(highlight: HighlightColor) {
    switch highlight {
    case .honey: self = Color(red: 0.88, green: 0.69, blue: 0.25)
    case .sage: self = Color(red: 0.50, green: 0.69, blue: 0.54)
    case .sky: self = Color(red: 0.44, green: 0.64, blue: 0.82)
    }
  }
}

#Preview {
  VerseActionBar(
    reference: "John 3:16",
    activeColor: .honey,
    hasNote: false,
    errorMessage: nil,
    onHighlight: { _ in },
    onNote: {},
    onCopy: {},
    onClose: {}
  )
  .padding()
}
