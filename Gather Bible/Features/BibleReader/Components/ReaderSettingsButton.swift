import SwiftUI

struct ReaderSettingsButton: View {
  @State private var showSettings = false

  var body: some View {
    Button {
      showSettings = true
    } label: {
      Text("Aa")
        .font(AppFont.label)
        .foregroundStyle(AppColor.muted)
        .lineLimit(1)
        .fixedSize()
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Reader settings")
    .accessibilityHint("Adjusts appearance, text size, and font")
    .sheet(isPresented: $showSettings) {
      ReaderSettingsSheet()
    }
  }
}

#Preview {
  ReaderSettingsButton()
}
