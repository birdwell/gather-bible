import SwiftUI
import YouVersionPlatformCore

// MARK: - Book and Chapter Picker Sheet

struct BookAndChapterPickerSheet: View {
  @Bindable var viewModel: BibleReaderViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var expandedBookId: String?

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  private var cellSize: CGFloat {
    isRegularWidth ? 52 : 44
  }

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        List {
          ForEach(viewModel.selectedVersionBooks, id: \.id) { book in
            bookRow(book)
              .id(book.id ?? "")
          }
        }
        .listStyle(.plain)
        .onAppear {
          // Pre-expand and scroll to the currently selected book so the user
          // doesn't start at Genesis every time.
          let selected = viewModel.selectedBook
          expandedBookId = selected
          DispatchQueue.main.async {
            withAnimation(.none) {
              proxy.scrollTo(selected, anchor: .top)
            }
          }
        }
      }
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
    .presentationDetents(isRegularWidth ? [.large] : [.medium, .large])
  }

  @ViewBuilder
  private func bookRow(_ book: BibleBook) -> some View {
    let bookId = book.id ?? ""
    let isExpanded = expandedBookId == bookId
    let isSelected = viewModel.selectedBook == bookId

    VStack(alignment: .leading, spacing: 0) {
      Button {
        if isExpanded {
          expandedBookId = nil
        } else {
          expandedBookId = bookId
        }
      } label: {
        HStack {
          Text(book.title ?? "Unknown")
            .font(.body)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(Color.primary)
          Spacer()
          Image(systemName: "chevron.down")
            .font(.caption)
            .foregroundStyle(Color.secondary)
            .rotationEffect(.degrees(isExpanded ? 0 : -90))
            .frame(width: 16, height: 16)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
        .frame(minHeight: 44)
      }
      .buttonStyle(PlainButtonStyle())
      .accessibilityLabel(book.title ?? "Unknown")
      .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
      .accessibilityHint(isExpanded ? "Hides chapters" : "Shows chapters")

      if isExpanded, let chapters = book.chapters {
        chapterGrid(bookId: bookId, chapterCount: chapters.count)
          .padding(.bottom, 12)
          .transition(.opacity)
      }
    }
    .animation(nil, value: expandedBookId)
  }

  private func chapterGrid(bookId: String, chapterCount: Int) -> some View {
    let columns = [
      GridItem(.adaptive(minimum: cellSize), spacing: isRegularWidth ? 12 : 8)
    ]

    return LazyVGrid(columns: columns, spacing: isRegularWidth ? 12 : 8) {
      ForEach(1...chapterCount, id: \.self) { chapter in
        let isCurrent = viewModel.selectedBook == bookId && viewModel.selectedChapter == chapter
        Button {
          viewModel.selectedBook = bookId
          viewModel.selectedChapter = chapter
          viewModel.handleNavigation(book: bookId, chapter: chapter)
          dismiss()
        } label: {
          Text("\(chapter)")
            .font(.body.weight(.medium))
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .foregroundStyle(isCurrent ? Color.white : Color.primary)
            .frame(width: cellSize, height: cellSize)
            .background(isCurrent ? Color.accentColor : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: isRegularWidth ? 10 : 8))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Chapter \(chapter)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
      }
    }
  }
}

// MARK: - Preview

#Preview {
  let viewModel = BibleReaderViewModel()
  viewModel.selectedVersionBooks = BibleBook.mockBooks
  return BookAndChapterPickerSheet(viewModel: viewModel)
}
