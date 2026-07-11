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
    viewModel.selectedVersion?.localizedAbbreviation?.uppercased() ?? "..."
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      readerBody

      if viewModel.booksLoaded {
        chapterNavigationButtons
      }
    }
    // Single container-level haptic: Reduce Motion must NOT gate haptics
    // (they have their own system setting that `sensoryFeedback` respects),
    // and one trigger avoids the double-fire from per-button feedback.
    .sensoryFeedback(
      .impact(weight: .light),
      trigger: "\(viewModel.selectedBook).\(viewModel.selectedChapter)"
    )
    .navigationTitle(bookAndChapter)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          if !viewModel.availableVersions.isEmpty {
            viewModel.showVersionPicker = true
          }
        } label: {
          if viewModel.isLoadingVersions && viewModel.availableVersions.isEmpty {
            ProgressView()
              .controlSize(.small)
              .frame(minWidth: 44)
          } else {
            Text(versionAbbreviation)
              .frame(minWidth: 44)
          }
        }
        .disabled(viewModel.availableVersions.isEmpty)
        .modifier(GlassToolbarButtonModifier())
        .accessibilityLabel("Bible version: \(versionAbbreviation)")
        .accessibilityHint("Selects a different translation")
      }

      ToolbarItem(placement: .principal) {
        Button {
          viewModel.showBookPicker = true
        } label: {
          Text(bookAndChapter)
            .fontWeight(.semibold)
        }
        .disabled(!viewModel.booksLoaded)
        .modifier(GlassToolbarButtonModifier())
        .accessibilityLabel("Current chapter: \(bookAndChapter)")
        .accessibilityHint("Selects a different book or chapter")
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        if sessionViewModel.isInSession {
          Button {
            viewModel.showParticipantsSheet = true
          } label: {
            Label("\(sessionViewModel.activeParticipantCount)", systemImage: "person.2.fill")
          }
          .modifier(GlassToolbarButtonModifier())
          .accessibilityLabel("\(sessionViewModel.activeParticipantCount) participants")
        }

        AirPlayButton()
          .frame(width: 44, height: 44)
          .accessibilityLabel("AirPlay")
          .accessibilityHint("Streams to Apple TV or other AirPlay devices")

        ReaderMenu()
      }
    }
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
    .onChange(of: viewModel.selectedVersionId) { _, _ in
      Task { await viewModel.loadBooksForVersion() }
    }
  }

  @ViewBuilder
  private var readerBody: some View {
    if let errorMessage = viewModel.loadErrorMessage, !viewModel.booksLoaded {
      errorView(message: errorMessage)
    } else if !viewModel.booksLoaded {
      ProgressView("Loading…")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      SyncableScrollView(viewModel: viewModel) {
        BibleTextView(
          viewModel.bibleReference,
          textOptions: readerSettings.textOptions(for: dynamicTypeSize)
        )
        .id("\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)")
        .frame(maxWidth: maxContentWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, isRegularWidth ? 24 : 12)
      }
      // Reserve space for the floating chapter buttons so scroll indicators
      // and content end above them (replaces a magic `.padding(.bottom, 100)`).
      .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: 72)
      }
    }
  }

  private func errorView(message: String) -> some View {
    ContentUnavailableView {
      Label("Couldn't Load", systemImage: "wifi.exclamationmark")
    } description: {
      Text(message)
    } actions: {
      Button("Retry") {
        viewModel.retryLoad()
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var chapterNavigationButtons: some View {
    HStack {
      Button(action: { viewModel.previousChapter() }) {
        Image(systemName: "chevron.left")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .modifier(GlassNavigationButtonModifier())
      .disabled(!viewModel.canGoPrevious)
      .accessibilityLabel("Previous Chapter")
      .keyboardShortcut(.leftArrow, modifiers: [])

      Spacer()

      Button(action: { viewModel.nextChapter() }) {
        Image(systemName: "chevron.right")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .modifier(GlassNavigationButtonModifier())
      .disabled(!viewModel.canGoNext)
      .accessibilityLabel("Next Chapter")
      .keyboardShortcut(.rightArrow, modifiers: [])
    }
    .padding(.horizontal, isRegularWidth ? 48 : 16)
    .padding(.bottom, isRegularWidth ? 32 : 16)
  }
}

private struct GlassToolbarButtonModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.buttonStyle(.glass)
    } else {
      content.buttonStyle(.bordered)
    }
  }
}

private struct GlassNavigationButtonModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .buttonStyle(.glass)
    } else {
      content
        .foregroundStyle(Color.primary)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .buttonStyle(.plain)
    }
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
