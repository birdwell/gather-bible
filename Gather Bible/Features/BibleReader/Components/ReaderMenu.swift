import AVKit
import SwiftUI

struct ReaderMenu: View {
  @Environment(\.readerSettings) private var readerSettings

  var body: some View {
    Menu {
      fontSizeSection
      Divider()
      fontFamilyPicker
      Divider()
      airPlaySection
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 17, weight: .semibold))
        .frame(width: 44, height: 44)
    }
    .modifier(GlassButtonModifier())
    .menuOrder(.fixed)
    .accessibilityLabel("Reader options")
    .accessibilityHint("Adjust font size, font style, and AirPlay settings")
  }

  private var fontSizeSection: some View {
    Section {
      ControlGroup {
        Button {
          readerSettings.decreaseFontSize()
        } label: {
          Label("Decrease", systemImage: "textformat.size.smaller")
        }
        .disabled(!readerSettings.canDecreaseFontSize)

        Button {
          readerSettings.increaseFontSize()
        } label: {
          Label("Increase", systemImage: "textformat.size.larger")
        }
        .disabled(!readerSettings.canIncreaseFontSize)
      }
      .menuActionDismissBehavior(.disabled)
    } header: {
      Text("Text Size")
    }
  }

  private var fontFamilyPicker: some View {
    Picker(selection: fontFamilyBinding) {
      ForEach(readerSettings.availableFonts) { font in
        Text(font.name)
          .font(.custom(font.family, size: 16))
          .tag(font.family)
      }
    } label: {
      Label("Font", systemImage: "textformat")
    }
    .pickerStyle(.menu)
  }

  private var fontFamilyBinding: Binding<String> {
    Binding(
      get: { readerSettings.fontFamily },
      set: { readerSettings.fontFamily = $0 }
    )
  }

  private var airPlaySection: some View {
    Section {
      AirPlayMenuButton()
    } header: {
      Text("Display")
    }
  }
}

private struct AirPlayMenuButton: View {
  @State private var showingRoutePicker = false

  var body: some View {
    Button {
      showingRoutePicker = true
    } label: {
      Label("AirPlay", systemImage: "airplayvideo")
    }
    .background {
      AirPlayRoutePickerTrigger(isPresented: $showingRoutePicker)
    }
  }
}

private struct AirPlayRoutePickerTrigger: UIViewRepresentable {
  @Binding var isPresented: Bool

  func makeUIView(context: Context) -> AVRoutePickerView {
    let picker = AVRoutePickerView()
    picker.prioritizesVideoDevices = true
    picker.isHidden = true
    context.coordinator.picker = picker
    return picker
  }

  func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    if isPresented {
      DispatchQueue.main.async {
        context.coordinator.triggerPicker()
        isPresented = false
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    weak var picker: AVRoutePickerView?

    func triggerPicker() {
      guard let picker = picker else { return }
      for subview in picker.subviews {
        if let button = subview as? UIButton {
          button.sendActions(for: .touchUpInside)
          break
        }
      }
    }
  }
}

private struct GlassButtonModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.buttonStyle(.glass)
    } else {
      content.buttonStyle(.plain)
    }
  }
}

#Preview {
  HStack {
    ReaderMenu()
  }
  .padding()
}
