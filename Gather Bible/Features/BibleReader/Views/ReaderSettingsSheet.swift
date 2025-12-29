import SwiftUI

struct ReaderSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.readerSettings) private var readerSettings

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Spacer()
          .frame(height: 8)

        previewSection
        fontSizeSection
        fontFamilySection
        Spacer()
      }
      .padding()
      .navigationTitle("Reader Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private var previewSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Preview")
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      Text("In the beginning God created the heavens and the earth.")
        .font(.custom(readerSettings.fontFamily, size: readerSettings.fontSize))
        .lineSpacing(readerSettings.fontSize * 0.3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  private var fontSizeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Text Size")
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      HStack(spacing: 16) {
        Button {
          withAnimation(.easeInOut(duration: 0.15)) {
            readerSettings.decreaseFontSize()
          }
        } label: {
          Text("A")
            .font(.system(size: 16, weight: .medium))
            .frame(width: 44, height: 44)
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())
        }
        .disabled(!readerSettings.canDecreaseFontSize)
        .opacity(readerSettings.canDecreaseFontSize ? 1 : 0.4)
        .accessibilityLabel("Decrease font size")

        fontSizeSlider

        Button {
          withAnimation(.easeInOut(duration: 0.15)) {
            readerSettings.increaseFontSize()
          }
        } label: {
          Text("A")
            .font(.system(size: 24, weight: .medium))
            .frame(width: 44, height: 44)
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())
        }
        .disabled(!readerSettings.canIncreaseFontSize)
        .opacity(readerSettings.canIncreaseFontSize ? 1 : 0.4)
        .accessibilityLabel("Increase font size")
      }
      .buttonStyle(.plain)
    }
  }

  private var fontSizeSlider: some View {
    GeometryReader { geometry in
      let stepWidth = geometry.size.width / CGFloat(readerSettings.availableFontSizes.count - 1)
      let currentPosition = stepWidth * CGFloat(readerSettings.currentSizeIndex)

      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color(.systemGray4))
          .frame(height: 4)

        Capsule()
          .fill(Color.accentColor)
          .frame(width: currentPosition + 8, height: 4)

        Circle()
          .fill(Color.accentColor)
          .frame(width: 20, height: 20)
          .offset(x: currentPosition - 6)
          .gesture(
            DragGesture()
              .onChanged { value in
                let newIndex = Int(round(value.location.x / stepWidth))
                let clampedIndex = max(0, min(newIndex, readerSettings.availableFontSizes.count - 1))
                if clampedIndex != readerSettings.currentSizeIndex {
                  readerSettings.fontSize = readerSettings.availableFontSizes[clampedIndex]
                }
              }
          )
      }
      .frame(height: 20)
      .frame(maxHeight: .infinity)
    }
    .frame(height: 44)
    .accessibilityElement()
    .accessibilityLabel("Font size")
    .accessibilityValue("\(Int(readerSettings.fontSize)) points")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: readerSettings.increaseFontSize()
      case .decrement: readerSettings.decreaseFontSize()
      @unknown default: break
      }
    }
  }

  private var fontFamilySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Font")
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: isRegularWidth ? 140 : 100), spacing: 8)],
        spacing: 8
      ) {
        ForEach(readerSettings.availableFonts) { font in
          FontButton(
            font: font,
            isSelected: font.family == readerSettings.fontFamily,
            action: {
              withAnimation(.easeInOut(duration: 0.15)) {
                readerSettings.selectFont(font)
              }
            }
          )
        }
      }
    }
  }
}

private struct FontButton: View {
  let font: ReaderFont
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(font.name)
        .font(.custom(font.family, size: 14))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

#Preview {
  ReaderSettingsSheet()
}
