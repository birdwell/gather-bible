import SwiftUI
import YouVersionPlatformCore

struct VersionPickerSheet: View {
  @Bindable var viewModel: BibleReaderViewModel
  let onDismiss: () -> Void

  var body: some View {
    NavigationView {
      List(viewModel.availableVersions, id: \.id) { version in
        HStack {
          VStack(alignment: .leading, spacing: 4) {
          Text((version.localizedAbbreviation ?? "").uppercased())
              .font(.headline)
            Text(version.title ?? "Unknown")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          if version.id == viewModel.selectedVersionId {
            Image(systemName: "checkmark")
              .foregroundColor(.accentColor)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          viewModel.selectedVersionId = version.id
          onDismiss()
        }
      }
      .navigationTitle("Select Bible Version")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") { onDismiss() }
        }
      }
    }
  }
}
