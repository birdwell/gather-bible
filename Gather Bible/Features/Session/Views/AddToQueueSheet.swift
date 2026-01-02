//
//  AddToQueueSheet.swift
//  Gather Bible
//
//  Sheet for adding a scripture reference to the session queue
//

import SwiftUI
import YouVersionPlatform
import YouVersionPlatformCore

struct AddToQueueSheet: View {
  @ObservedObject var sessionViewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @State private var step: SelectionStep = .book
  @State private var selectedBook: BibleBook?
  @State private var selectedChapter: Int?
  @State private var useVerseRange = false
  @State private var startVerse: Int = 1
  @State private var endVerse: Int = 1
  @State private var maxVerses: Int = 1
  @State private var books: [BibleBook] = []
  @State private var isLoadingBooks = true

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  private var columnCount: Int {
    isRegularWidth ? 10 : 6
  }

  private var cellSize: CGFloat {
    isRegularWidth ? 52 : 44
  }

  private var previewLabel: String {
    guard let book = selectedBook, let chapter = selectedChapter else {
      return "Select a passage"
    }
    let bookName = book.title ?? book.id ?? "Unknown"
    if useVerseRange {
      if startVerse == endVerse {
        return "\(bookName) \(chapter):\(startVerse)"
      }
      return "\(bookName) \(chapter):\(startVerse)-\(endVerse)"
    }
    return "\(bookName) \(chapter)"
  }

  private var canAdd: Bool {
    selectedBook != nil && selectedChapter != nil
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        previewHeader

        Divider()

        if isLoadingBooks {
          ProgressView("Loading books...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          switch step {
          case .book:
            bookList
          case .chapter:
            chapterGrid
          case .verseRange:
            verseRangeSelector
          }
        }
      }
      .navigationTitle("Add to Queue")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            addToQueue()
          }
          .disabled(!canAdd)
        }
      }
      .task {
        await loadBooks()
      }
    }
    .presentationDetents(isRegularWidth ? [.large] : [.medium, .large])
  }

  private func loadBooks() async {
    let versionId = sessionViewModel.currentVersionId
    do {
      let version = try await YouVersionConfig.getVersionDetails(versionId: versionId)
      books = version.books ?? []
    } catch {
      print("[AddToQueueSheet] Failed to load books: \(error)")
    }
    isLoadingBooks = false
  }

  // MARK: - Preview Header

  private var previewHeader: some View {
    HStack {
      Text(previewLabel)
        .font(.headline)

      Spacer()

      if step != .book {
        Button {
          goBack()
        } label: {
          Image(systemName: "chevron.left")
            .font(.caption)
          Text("Back")
            .font(.subheadline)
        }
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
  }

  // MARK: - Book List

  private var bookList: some View {
    List {
      ForEach(books, id: \.id) { book in
        Button {
          selectedBook = book
          step = .chapter
        } label: {
          HStack {
            Text(book.title ?? "Unknown")
              .foregroundStyle(Color.primary)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
        }
      }
    }
    .listStyle(.plain)
  }

  // MARK: - Chapter Grid

  @ViewBuilder
  private var chapterGrid: some View {
    if let book = selectedBook, let chapters = book.chapters {
      ChapterGridContent(
        chapterCount: chapters.count,
        selectedChapter: selectedChapter,
        columnCount: columnCount,
        cellSize: cellSize,
        isRegularWidth: isRegularWidth,
        onSelect: { chapter in
          selectedChapter = chapter
          maxVerses = 176  // Maximum verses in Psalm 119
          endVerse = 30
          step = .verseRange
        }
      )
    }
  }

  // MARK: - Verse Range Selector

  private var verseRangeSelector: some View {
    List {
      Section {
        Toggle("Specific Verse Range", isOn: $useVerseRange)
      }

      if useVerseRange {
        let startVerseOptions = (1...maxVerses).map { $0 }
        let endVerseOptions = (startVerse...maxVerses).map { $0 }

        Section("Verse Range") {
          HStack {
            Text("Start Verse")
            Spacer()
            Picker("Start", selection: $startVerse) {
              ForEach(startVerseOptions, id: \.self) { verse in
                Text("\(verse)").tag(verse)
              }
            }
            .pickerStyle(.menu)
          }

          HStack {
            Text("End Verse")
            Spacer()
            Picker("End", selection: $endVerse) {
              ForEach(endVerseOptions, id: \.self) { verse in
                Text("\(verse)").tag(verse)
              }
            }
            .pickerStyle(.menu)
          }
        }
      }

      Section {
        Button {
          addToQueue()
        } label: {
          HStack {
            Spacer()
            Label("Add to Queue", systemImage: "plus.circle.fill")
              .fontWeight(.medium)
            Spacer()
          }
        }
        .disabled(!canAdd)
      }
    }
    .onChange(of: startVerse) { _, newValue in
      if endVerse < newValue {
        endVerse = newValue
      }
    }
  }

  // MARK: - Actions

  private func goBack() {
    switch step {
    case .book:
      break
    case .chapter:
      selectedBook = nil
      step = .book
    case .verseRange:
      selectedChapter = nil
      useVerseRange = false
      startVerse = 1
      step = .chapter
    }
  }

  private func addToQueue() {
    guard let book = selectedBook, let chapter = selectedChapter else { return }

    let reference = QueuedReference(
      book: book.id ?? "GEN",
      chapter: chapter,
      startVerse: useVerseRange ? startVerse : nil,
      endVerse: useVerseRange ? endVerse : nil
    )

    Task {
      await sessionViewModel.addToQueue(reference: reference)
      dismiss()
    }
  }
}

// MARK: - Selection Step

private enum SelectionStep {
  case book
  case chapter
  case verseRange
}

// MARK: - Chapter Grid Content

private struct ChapterGridContent: View {
  let chapterCount: Int
  let selectedChapter: Int?
  let columnCount: Int
  let cellSize: CGFloat
  let isRegularWidth: Bool
  let onSelect: (Int) -> Void

  var body: some View {
    ScrollView {
      let columns = [GridItem](
        repeating: GridItem(.flexible(), spacing: isRegularWidth ? 12 : 8),
        count: columnCount
      )

      LazyVGrid(columns: columns, spacing: isRegularWidth ? 12 : 8) {
        ForEach(1...chapterCount, id: \.self) { chapter in
          Button {
            onSelect(chapter)
          } label: {
            Text("\(chapter)")
              .font(.system(size: isRegularWidth ? 16 : 14, weight: .medium))
              .foregroundStyle(
                selectedChapter == chapter ? Color.white : Color.primary
              )
              .frame(width: cellSize, height: cellSize)
              .background(
                selectedChapter == chapter ? Color.accentColor : Color(.systemGray5)
              )
              .clipShape(RoundedRectangle(cornerRadius: isRegularWidth ? 10 : 8))
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding()
    }
  }
}

#Preview {
  AddToQueueSheet(sessionViewModel: SessionViewModel())
}
