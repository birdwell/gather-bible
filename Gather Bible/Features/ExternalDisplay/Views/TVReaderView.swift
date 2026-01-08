import SwiftUI
import YouVersionPlatform
import YouVersionPlatformUI

struct TVReaderView: View {
  @Bindable var viewModel: BibleReaderViewModel

  private var tvTextOptions: BibleTextOptions {
    BibleTextOptions(
      fontFamily: "Georgia",
      fontSize: 48,
      lineSpacing: 32,
      paragraphSpacing: 24
    )
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          headerView
            .padding(.top, geometry.safeAreaInsets.top + 40)

          BibleTextView(viewModel.bibleReference, textOptions: tvTextOptions)
            .id("\(viewModel.selectedBook).\(viewModel.selectedChapter).\(viewModel.selectedVersionId)")
            .frame(maxWidth: min(geometry.size.width * 0.75, 1200))
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
    .persistentSystemOverlays(.hidden)
  }

  private var headerView: some View {
    VStack(spacing: 8) {
      Text(bookAndChapterTitle)
        .font(.system(size: 36, weight: .semibold, design: .serif))
        .foregroundStyle(.white)

      Text(versionAbbreviation)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.white.opacity(0.6))
    }
    .padding(.bottom, 32)
  }

  private var bookAndChapterTitle: String {
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
    if let version = viewModel.selectedVersion {
      return (version.localizedAbbreviation ?? "").uppercased()
    }
    return ""
  }
}

#Preview {
  TVReaderView(viewModel: BibleReaderViewModel())
}
