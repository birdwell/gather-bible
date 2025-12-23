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

      ZStack(alignment: .bottom) {
        SyncableScrollView(viewModel: viewModel) {
          BibleTextView(viewModel.bibleReference)
            .id(
              "\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }

        navigationButtons
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

  private var navigationButtons: some View {
    HStack {
      Button(action: { viewModel.previousChapter() }) {
        Image(systemName: "chevron.left")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Color.primary)
          .frame(width: 56, height: 56)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
      }
      .buttonStyle(PlainButtonStyle())
      .sensoryFeedback(
        .impact(weight: .light), trigger: "\(viewModel.selectedBook).\(viewModel.selectedChapter)")

      Spacer()

      Button(action: { viewModel.nextChapter() }) {
        Image(systemName: "chevron.right")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Color.primary)
          .frame(width: 56, height: 56)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
      }
      .buttonStyle(PlainButtonStyle())
      .sensoryFeedback(
        .impact(weight: .light), trigger: "\(viewModel.selectedBook).\(viewModel.selectedChapter)")
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 24)
  }
}

// MARK: - Preview

#Preview {
  NavigationView {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
