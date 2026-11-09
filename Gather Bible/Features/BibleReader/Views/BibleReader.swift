import SwiftUI

/// Bible reader that uses YouVersion SDK's BibleTextView directly
struct BibleReader: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @State private var viewModel: BibleReaderViewModel?

  private let externalDisplayManager = ExternalDisplayManager.shared

  var body: some View {
    Group {
      if let viewModel {
        ReaderContentView(viewModel: viewModel)
      } else {
        ProgressView("Loading…")
      }
    }
    .onAppear {
      if viewModel == nil {
        let reader = BibleReaderViewModel(sessionViewModel: sessionViewModel)
        reader.restorePosition()
        viewModel = reader
      }
      viewModel?.loadVersions()
      viewModel?.syncFromSession()
      viewModel?.subscribeToSessionUpdates()

      if let viewModel {
        externalDisplayManager.attachReader(viewModel)
      }
    }
    .onDisappear {
      externalDisplayManager.detachReader()
    }
  }
}

#Preview {
  NavigationStack {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
