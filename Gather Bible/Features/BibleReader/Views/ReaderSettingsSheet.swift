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
            .font(.body.weight(.medium))
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
            .font(.title.weight(.medium))
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

  /// Standard `Slider` mapped onto the discrete size steps. Using the system
  /// control keeps free accessibility, RTL, and 44pt hit-target behavior.
  private var fontSizeSlider: some View {
    Slider(
      value: Binding(
        get: { Double(readerSettings.currentSizeIndex) },
        set: { newValue in
          let index = max(
            0, min(Int(newValue.rounded()), readerSettings.availableFontSizes.count - 1))
          readerSettings.fontSize = readerSettings.availableFontSizes[index]
        }
      ),
      in: 0...Double(readerSettings.availableFontSizes.count - 1),
      step: 1
    )
    .accessibilityLabel("Font size")
    .accessibilityValue("\(Int(readerSettings.fontSize)) points")
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
        .font(.custom(font.family, size: 14, relativeTo: .subheadline))
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
