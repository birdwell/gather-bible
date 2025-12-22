import SwiftUI
import YouVersionPlatformCore

// MARK: - Book and Chapter Picker Sheet

struct BookAndChapterPickerSheet: View {
  @Bindable var viewModel: BibleReaderViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var expandedBookId: String?

  var body: some View {
    NavigationStack {
      List {
        ForEach(viewModel.selectedVersionBooks, id: \.id) { book in
          bookRow(book)
        }
      }
      .listStyle(.plain)
      .navigationTitle("Select Passage")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  @ViewBuilder
  private func bookRow(_ book: BibleBook) -> some View {
    let bookId = book.id ?? ""
    let isExpanded = expandedBookId == bookId
    let isSelected = viewModel.selectedBook == bookId

    VStack(spacing: 0) {
      Button {
        withAnimation(.easeInOut(duration: 0.2)) {
          if isExpanded {
            expandedBookId = nil
          } else {
            expandedBookId = bookId
          }
        }
      } label: {
        HStack {
          Text(book.title ?? "Unknown")
            .font(.body)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(Color.primary)
          Spacer()
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
      }
      .buttonStyle(PlainButtonStyle())

      if isExpanded, let chapters = book.chapters {
        chapterGrid(bookId: bookId, chapterCount: chapters.count)
          .padding(.bottom, 12)
      }
    }
  }

  private func chapterGrid(bookId: String, chapterCount: Int) -> some View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    return LazyVGrid(columns: columns, spacing: 8) {
      ForEach(1...chapterCount, id: \.self) { chapter in
        Button {
          viewModel.selectedBook = bookId
          viewModel.selectedChapter = chapter
          viewModel.handleNavigation(book: bookId, chapter: chapter)
          dismiss()
        } label: {
          Text("\(chapter)")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(
              viewModel.selectedBook == bookId && viewModel.selectedChapter == chapter
                ? Color.white
                : Color.primary
            )
            .frame(width: 44, height: 44)
            .background(
              viewModel.selectedBook == bookId && viewModel.selectedChapter == chapter
                ? Color.accentColor
                : Color(.systemGray5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
  }
}
