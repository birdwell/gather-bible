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
        viewModel = BibleReaderViewModel(sessionViewModel: sessionViewModel)
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

// MARK: - Reader Content

private struct ReaderContentView: View {
  @EnvironmentObject private var sessionViewModel: SessionViewModel
  @Bindable var viewModel: BibleReaderViewModel
  @Environment(\.readerSettings) private var readerSettings
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  private var horizontalPadding: CGFloat {
    isRegularWidth ? 80 : 16
  }

  private var maxContentWidth: CGFloat {
    isRegularWidth ? 720 : .infinity
  }

  private var bookTitle: String {
    guard
      let book = viewModel.selectedVersionBooks.first(where: {
        ($0.id ?? "") == viewModel.selectedBook
      })
    else {
      return "Loading…"
    }
    return book.title ?? "Unknown"
  }

  /// The host first, then everyone else who's here, excluding you.
  private var companionNames: [String] {
    sessionViewModel.participants
      .filter { $0.active && $0.id != sessionViewModel.userId }
      .sorted { $0.isHost && !$1.isHost }
      .map(\.displayName)
  }

  private var versionAbbreviation: String {
    viewModel.selectedVersion?.localizedAbbreviation?.uppercased() ?? "..."
  }

  var body: some View {
    readerBody
    .safeAreaInset(edge: .top, spacing: 0) {
      ReaderTopBar(
        bookTitle: bookTitle,
        chapter: viewModel.selectedChapter,
        version: versionAbbreviation,
        isLoadingVersion: viewModel.isLoadingVersions && viewModel.availableVersions.isEmpty,
        canPickPassage: viewModel.booksLoaded,
        canPickVersion: !viewModel.availableVersions.isEmpty,
        horizontalPadding: horizontalPadding,
        onPickPassage: { viewModel.showBookPicker = true },
        onPickVersion: { viewModel.showVersionPicker = true }
      )
    }
    .background(AppColor.ground.ignoresSafeArea())
    // Single container-level haptic: Reduce Motion must NOT gate haptics
    // (they have their own system setting that `sensoryFeedback` respects),
    // and one trigger avoids the double-fire from per-button feedback.
    .sensoryFeedback(
      .impact(weight: .light),
      trigger: "\(viewModel.selectedBook).\(viewModel.selectedChapter)"
    )
    .navigationTitle("\(bookTitle) \(viewModel.selectedChapter)")
    .toolbar(.hidden, for: .navigationBar)
    .sheet(isPresented: $viewModel.showBookPicker) {
      BookAndChapterPickerSheet(viewModel: viewModel)
    }
    .sheet(isPresented: $viewModel.showVersionPicker) {
      VersionPickerSheet(
        viewModel: viewModel,
        onDismiss: { viewModel.showVersionPicker = false }
      )
    }
    .sheet(isPresented: $viewModel.showParticipantsSheet) {
      ParticipantsSheet(viewModel: sessionViewModel)
        .presentationDetents([.medium, .large])
    }
    // The participants sheet has nothing to show once the session is over, and
    // it would otherwise block the session-ended notice.
    .onChange(of: sessionViewModel.isInSession) { _, isInSession in
      if !isInSession { viewModel.showParticipantsSheet = false }
    }
    .onChange(of: viewModel.selectedVersionId) { _, _ in
      Task { await viewModel.loadBooksForVersion() }
    }
  }

  @ViewBuilder
  private var readerBody: some View {
    // Error takes priority even when a previous translation's books are still
    // loaded: after a failed version switch the reader state is inconsistent,
    // so show the retry UI instead of silently keeping the old translation.
    if let errorMessage = viewModel.loadErrorMessage {
      errorView(message: errorMessage)
    } else if !viewModel.booksLoaded {
      ProgressView("Loading…")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      SyncableScrollView(viewModel: viewModel) {
        VStack(alignment: .leading, spacing: 8) {
          ChapterOpener(
            chapter: viewModel.selectedChapter,
            companions: sessionViewModel.isInSession
              ? ReadingCompanions.text(names: companionNames) : nil,
            onShowCompanions: { viewModel.showParticipantsSheet = true }
          )
          BibleTextView(
            viewModel.bibleReference,
            textOptions: readerSettings.textOptions(for: dynamicTypeSize)
          )
          .id("\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)")

          ChapterFooter(
            canGoPrevious: viewModel.canGoPrevious,
            canGoNext: viewModel.canGoNext,
            onPrevious: { viewModel.previousChapter() },
            onNext: { viewModel.nextChapter() }
          )
          .padding(.top, 32)
        }
        .frame(maxWidth: maxContentWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, isRegularWidth ? 24 : 12)
      }
    }
  }

  private func errorView(message: String) -> some View {
    EmptyState(
      title: "Couldn’t load this chapter",
      message: message,
      actionTitle: "Try again",
      action: { viewModel.retryLoad() }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
