import SwiftUI

/// Lets the user follow the device appearance or force light or dark.
struct AppearancePicker: View {
  @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Appearance")
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      Picker("Appearance", selection: $appearance) {
        ForEach(AppAppearance.allCases) { option in
          Text(option.title).tag(option)
        }
      }
      .pickerStyle(.segmented)
    }
  }
}

#Preview {
  AppearancePicker()
    .padding()
}
