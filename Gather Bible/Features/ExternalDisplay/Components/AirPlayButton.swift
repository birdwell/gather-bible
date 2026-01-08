import AVKit
import SwiftUI

struct AirPlayButton: UIViewRepresentable {
  var tintColor: UIColor = .label
  var activeTintColor: UIColor = .systemBlue

  func makeUIView(context: Context) -> AVRoutePickerView {
    let routePicker = AVRoutePickerView()
    routePicker.tintColor = tintColor
    routePicker.activeTintColor = activeTintColor
    routePicker.prioritizesVideoDevices = true
    return routePicker
  }

  func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    uiView.tintColor = tintColor
    uiView.activeTintColor = activeTintColor
  }
}

struct AirPlayButtonStyle: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    AirPlayButton(
      tintColor: colorScheme == .dark ? .white : .black,
      activeTintColor: .systemBlue
    )
    .frame(width: 44, height: 44)
    .background(Color(.systemGray5))
    .clipShape(Circle())
    .accessibilityLabel("AirPlay")
    .accessibilityHint("Stream to Apple TV or other AirPlay devices")
  }
}

#Preview {
  HStack {
    AirPlayButtonStyle()
  }
  .padding()
}
