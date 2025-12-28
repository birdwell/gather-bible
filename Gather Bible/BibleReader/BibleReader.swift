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
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  private var horizontalPadding: CGFloat {
    isRegularWidth ? 80 : 16
  }

  private var maxContentWidth: CGFloat {
    isRegularWidth ? 720 : .infinity
  }

  private var buttonSize: CGFloat {
    isRegularWidth ? 64 : 56
  }

  private var buttonIconSize: CGFloat {
    isRegularWidth ? 24 : 20
  }

  var body: some View {
    VStack(spacing: 0) {
      NavigationHeader(viewModel: viewModel)

      ZStack(alignment: .bottom) {
        SyncableScrollView(viewModel: viewModel) {
          BibleTextView(viewModel.bibleReference)
            .id(
              "\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)"
            )
            .frame(maxWidth: maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, isRegularWidth ? 24 : 12)
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
          .font(.system(size: buttonIconSize, weight: .bold))
          .foregroundStyle(Color.primary)
          .frame(width: buttonSize, height: buttonSize)
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
          .font(.system(size: buttonIconSize, weight: .bold))
          .foregroundStyle(Color.primary)
          .frame(width: buttonSize, height: buttonSize)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
      }
      .buttonStyle(PlainButtonStyle())
      .sensoryFeedback(
        .impact(weight: .light), trigger: "\(viewModel.selectedBook).\(viewModel.selectedChapter)")
    }
    .padding(.horizontal, isRegularWidth ? 48 : 24)
    .padding(.bottom, isRegularWidth ? 32 : 24)
  }
}

// MARK: - Preview

#Preview {
  NavigationView {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
