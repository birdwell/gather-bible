import Combine
import Foundation
import SwiftUI
import YouVersionPlatform
import YouVersionPlatformReader
import YouVersionPlatformUI

/// Bible reader that uses YouVersion SDK's BibleTextView directly
struct BibleReader: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @State private var viewModel: BibleReaderViewModel?

  var body: some View {
    Group {
      if let viewModel {
        ReaderContentView(viewModel: viewModel)
      } else {
        ProgressView("Loading...")
      }
    }
    .onAppear {
      if viewModel == nil {
        viewModel = BibleReaderViewModel(sessionViewModel: sessionViewModel)
      }
      viewModel?.loadVersions()
      viewModel?.syncFromSession()
      viewModel?.subscribeToSessionUpdates()
    }
  }
}

// MARK: - Reader Content

private struct ReaderContentView: View {
  @Bindable var viewModel: BibleReaderViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavigationHeader(viewModel: viewModel)

      SyncableScrollView(viewModel: viewModel) {
        BibleTextView(viewModel.bibleReference)
        .id("\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)")
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
    .sheet(isPresented: $viewModel.showVersionPicker) {
      VersionPickerSheet(
        viewModel: viewModel,
        onDismiss: { viewModel.showVersionPicker = false }
      )
    }
    .onChange(of: viewModel.selectedVersionId) { _, _ in
      Task { await viewModel.loadBooksForVersion() }
    }
  }
}

// MARK: - Preview

#Preview {
  NavigationView {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
