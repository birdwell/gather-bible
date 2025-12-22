import SwiftUI
import YouVersionPlatformCore

struct NavigationHeader: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
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

      if sessionViewModel.isInSession {
        Button {
          viewModel.showParticipantsSheet = true
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
            Text("\(sessionViewModel.activeParticipantCount)")
          }
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color.primary)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(.systemGray5))
          .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .sheet(isPresented: $viewModel.showBookPicker) {
      BookAndChapterPickerSheet(viewModel: viewModel)
    }
    .sheet(isPresented: $viewModel.showParticipantsSheet) {
      ParticipantsSheet(viewModel: sessionViewModel)
        .presentationDetents([.medium, .large])
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
