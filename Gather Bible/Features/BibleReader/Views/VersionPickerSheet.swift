import SwiftUI
import YouVersionPlatformCore

struct VersionPickerSheet: View {
  @Bindable var viewModel: BibleReaderViewModel
  let onDismiss: () -> Void
  @State private var searchText = ""

  private var filteredVersions: [BibleVersion] {
    if searchText.isEmpty {
      return viewModel.availableVersions
    }
    return viewModel.availableVersions.filter { version in
      let abbreviation = version.localizedAbbreviation ?? ""
      let title = version.title ?? ""
      return abbreviation.localizedCaseInsensitiveContains(searchText)
        || title.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.availableVersions.isEmpty && viewModel.isLoadingVersions {
          ProgressView("Loading versions…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredVersions.isEmpty {
          ContentUnavailableView.search(text: searchText)
        } else {
          List(filteredVersions, id: \.id) { version in
            let isSelected = version.id == viewModel.selectedVersionId
            Button {
              viewModel.selectedVersionId = version.id
              onDismiss()
            } label: {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text((version.localizedAbbreviation ?? "").uppercased())
                    .font(.headline)
                  Text(version.title ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
          }
        }
      }
      .searchable(text: $searchText, prompt: "Search versions")
      .navigationTitle("Select Bible Version")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { onDismiss() }
        }
      }
    }
  }
}
