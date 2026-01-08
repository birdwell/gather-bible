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
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    NavigationStack {
      ZStack(alignment: .bottom) {
        SyncableScrollView(viewModel: viewModel) {
          BibleTextView(viewModel.bibleReference, textOptions: readerSettings.textOptions)
            .id("\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)")
            .frame(maxWidth: maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, isRegularWidth ? 24 : 12)
            .padding(.bottom, 100)
        }

        chapterNavigationButtons
      }
      .navigationTitle(bookAndChapter)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            if !viewModel.availableVersions.isEmpty {
              viewModel.showVersionPicker = true
            }
          } label: {
            Text(versionAbbreviation)
              .frame(minWidth: 44)
          }
          .modifier(GlassToolbarButtonModifier())
          .accessibilityLabel("Bible version: \(versionAbbreviation)")
          .accessibilityHint("Double tap to select a different translation")
        }

        ToolbarItem(placement: .principal) {
          Button {
            viewModel.showBookPicker = true
          } label: {
            Text(bookAndChapter)
              .fontWeight(.semibold)
          }
          .modifier(GlassToolbarButtonModifier())
          .accessibilityLabel("Current chapter: \(bookAndChapter)")
          .accessibilityHint("Double tap to select a different book or chapter")
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
  }

  private var chapterNavigationButtons: some View {
    HStack {
      Button(action: { viewModel.previousChapter() }) {
        Image(systemName: "chevron.left")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
          .frame(width: 36, height: 36)
      }
      .modifier(GlassNavigationButtonModifier())
      .accessibilityLabel("Previous Chapter")
      .keyboardShortcut(.leftArrow, modifiers: [])
      .sensoryFeedback(
        .impact(weight: .light),
        trigger: reduceMotion ? nil : "\(viewModel.selectedBook).\(viewModel.selectedChapter)"
      )

      Spacer()

      Button(action: { viewModel.nextChapter() }) {
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
          .frame(width: 36, height: 36)
      }
      .modifier(GlassNavigationButtonModifier())
      .accessibilityLabel("Next Chapter")
      .keyboardShortcut(.rightArrow, modifiers: [])
      .sensoryFeedback(
        .impact(weight: .light),
        trigger: reduceMotion ? nil : "\(viewModel.selectedBook).\(viewModel.selectedChapter)"
      )
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
  NavigationView {
    BibleReader()
      .environmentObject(SessionViewModel())
  }
}
