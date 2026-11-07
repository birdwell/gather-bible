import SwiftUI
import YouVersionPlatformCore
import YouVersionPlatformUI

/// Searches Scripture and your own notes.
struct BibleSearchSheet: View {
  let store: AnnotationStore
  let onSelectVerse: (BibleReference) -> Void
  let onSelectNote: (VerseAnnotation) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: BibleSearchViewModel
  @FocusState private var isFieldFocused: Bool

  init(
    versionId: Int,
    store: AnnotationStore,
    client: BibleSearching = YouVersionConfig.makeSearchClient(),
    onSelectVerse: @escaping (BibleReference) -> Void,
    onSelectNote: @escaping (VerseAnnotation) -> Void
  ) {
    self.store = store
    self.onSelectVerse = onSelectVerse
    self.onSelectNote = onSelectNote
    _viewModel = State(initialValue: BibleSearchViewModel(client: client, versionId: versionId))
  }

  private var matchingNotes: [VerseAnnotation] {
    store.notes(matching: viewModel.query)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        searchField
          .padding(.horizontal, 16)
          .padding(.bottom, 8)

        ScrollView {
          LazyVStack(alignment: .leading, spacing: 24) {
            if viewModel.phase != .idle {
              scriptureResults
            }
            if !matchingNotes.isEmpty {
              notesSection
            }
            if viewModel.phase == .idle && matchingNotes.isEmpty {
              Text("Search by words, a topic, or a reference like John 3:16.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.muted)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .appNavigationTitle("Search")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
    .appSheet()
    .onAppear { isFieldFocused = true }
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      AppIconView(.search)
        .foregroundStyle(AppColor.muted)

      TextField("Search the Bible", text: $viewModel.query)
        .focused($isFieldFocused)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.search)

      if !viewModel.query.isEmpty {
        Button {
          viewModel.query = ""
          isFieldFocused = true
        } label: {
          AppIconView(.close, size: 16)
            .foregroundStyle(AppColor.muted)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear search")
      }
    }
    .appField()
  }

  @ViewBuilder
  private var scriptureResults: some View {
    switch viewModel.phase {
    case .idle:
      EmptyView()
    case .searching:
      Text("Searching…")
        .font(AppFont.body)
        .foregroundStyle(AppColor.muted)
    case .failed:
      EmptyState(
        title: "Couldn’t search right now",
        message: "Check your connection and try again.",
        actionTitle: "Try again",
        action: { viewModel.retry() }
      )
      .padding(-16)
    case .empty:
      VStack(alignment: .leading, spacing: 8) {
        Text("No verses found")
          .font(AppFont.heading)
          .foregroundStyle(AppColor.ink)
        Text("Try different words, or another translation.")
          .font(AppFont.body)
          .foregroundStyle(AppColor.muted)
        suggestions
      }
    case .results:
      VStack(alignment: .leading, spacing: 24) {
        suggestions

        ForEach(viewModel.references, id: \.self) { reference in
          SearchResultRow(reference: reference) {
            onSelectVerse(reference)
            dismiss()
          }
        }

        if viewModel.canLoadMore {
          Button {
            Task { await viewModel.loadMore() }
          } label: {
            Group {
              if viewModel.isLoadingMore {
                ProgressView()
              } else {
                Text("Show more")
              }
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.appSecondary)
          .disabled(viewModel.isLoadingMore)
        }
      }
    }
  }

  @ViewBuilder
  private var suggestions: some View {
    if let suggestion = viewModel.didYouMean.first {
      Button {
        viewModel.query = suggestion
      } label: {
        Text("Did you mean \(suggestion)?")
          .font(AppFont.label)
          .foregroundStyle(AppColor.accent)
          .frame(minHeight: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  private var notesSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Your notes")
        .font(AppFont.heading)
        .foregroundStyle(AppColor.ink)
        .accessibilityAddTraits(.isHeader)

      ForEach(matchingNotes) { annotation in
        NoteRow(annotation: annotation) {
          onSelectNote(annotation)
          dismiss()
        }
      }
    }
  }
}

private struct SearchResultRow: View {
  let reference: BibleReference
  let onTap: () -> Void

  private var title: String {
    let verse = reference.verseStart.map { ":\($0)" } ?? ""
    return "\(BibleBookNames.title(for: reference.bookUSFM)) \(reference.chapter)\(verse)"
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(AppFont.label)
          .foregroundStyle(AppColor.ink)

        BibleTextView(
          reference,
          textOptions: BibleTextOptions(
            fontFamily: AppFont.family,
            fontSize: 15,
            lineSpacing: 0.27,
            paragraphSpacing: 0,
            textColor: AppColor.muted,
            wocColor: AppColor.muted,
            renderHeadlines: false,
            renderVerseNumbers: false
          )
        )
        .allowsHitTesting(false)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityHint("Opens this verse")
  }
}
