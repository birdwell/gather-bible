import SwiftUI

struct ReaderMenu: View {
  @State private var showTextSettings = false

  var body: some View {
    Menu {
      Button {
        showTextSettings = true
      } label: {
        Label("Text Settings", systemImage: "textformat.size")
      }
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.title3)
        .frame(width: 44, height: 44)
    }
    .modifier(GlassButtonModifier())
    .accessibilityLabel("Reader options")
    .accessibilityHint("Adjusts text size and font")
    .sheet(isPresented: $showTextSettings) {
      ReaderSettingsSheet()
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
