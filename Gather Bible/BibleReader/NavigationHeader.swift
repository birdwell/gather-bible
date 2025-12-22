import SwiftUI
import YouVersionPlatformCore

struct NavigationHeader: View {
  @Bindable var viewModel: BibleReaderViewModel

  var body: some View {
    HStack {
      HalfPillPickerView(
        bookAndChapter: bookAndChapter,
        versionAbbreviation: versionAbbreviation,
        handleChapterTap: { viewModel.showBookPicker = true },
        handleVersionTap: {
          if !viewModel.availableVersions.isEmpty {
            viewModel.showVersionPicker = true
          }
        }
      )
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .sheet(isPresented: $viewModel.showBookPicker) {
      BookAndChapterPickerSheet(viewModel: viewModel)
    }
  }

  private var bookAndChapter: String {
    guard
      let book = viewModel.selectedVersionBooks.first(where: {
        ($0.id ?? "") == viewModel.selectedBook
      })
    else {
      return "Loading..."
    }
    return "\(book.title ?? "Unknown") \(viewModel.selectedChapter)"
  }

  private var versionAbbreviation: String {
    if let version = viewModel.availableVersions.first(where: {
      $0.id == viewModel.selectedVersionId
    }) {
      return (version.localizedAbbreviation ?? "").uppercased()
    }
    return "..."
  }
}
