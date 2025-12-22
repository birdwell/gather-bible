//
//  SyncableScrollView.swift
//  Gather Bible
//
//  Native SwiftUI ScrollView with scroll position tracking and sync
//

import SwiftUI

/// Content size tracking preference key
struct ContentSizeKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    let next = nextValue()
    if next.height > value.height {
      value = next
    }
  }
}

/// A native SwiftUI scroll view with scroll position tracking
struct SyncableScrollView<Content: View>: View {
  @Bindable var viewModel: BibleReaderViewModel
  let content: Content

  // Use more anchors for finer precision
  private let anchorCount = 200

  init(
    viewModel: BibleReaderViewModel,
    @ViewBuilder content: () -> Content
  ) {
    self.viewModel = viewModel
    self.content = content()
  }

  var body: some View {
    GeometryReader { outerGeometry in
      ScrollViewReader { scrollProxy in
        ScrollView {
          content
            .background(
              GeometryReader { geo in
                Color.clear
                  .preference(key: ContentSizeKey.self, value: geo.size)
              }
            )
            .background(alignment: .top) {
              anchorsOverlay
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentOffset.y
        } action: { _, newOffset in
          viewModel.scrollOffset = newOffset
          viewModel.handleScroll(offset: newOffset)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentSize.height
        } action: { _, newHeight in
          viewModel.contentHeight = newHeight
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.visibleRect.height
        } action: { _, newHeight in
          viewModel.viewHeight = newHeight
        }
        .onAppear {
          viewModel.viewHeight = outerGeometry.size.height
        }
        .onPreferenceChange(ContentSizeKey.self) { size in
          if size.height > viewModel.contentHeight {
            viewModel.contentHeight = size.height
          }
        }
        .onChange(of: viewModel.targetScrollOffset) { oldValue, newOffset in
          guard viewModel.shouldApplyScrollOffset && !viewModel.isHost else { return }
          guard viewModel.contentHeight > viewModel.viewHeight else { return }
          guard abs(newOffset - oldValue) > 0.001 else { return }

          let clampedOffset = min(max(newOffset, 0), 1)
          let scrollableHeight = viewModel.contentHeight - viewModel.viewHeight
          let targetPixelOffset = clampedOffset * scrollableHeight
          let anchorSpacing = viewModel.contentHeight / Double(anchorCount)
          let anchorIndex = min(Int(targetPixelOffset / anchorSpacing), anchorCount - 1)

          withAnimation(.interpolatingSpring(stiffness: 100, damping: 15)) {
            scrollProxy.scrollTo("sync_anchor_\(anchorIndex)", anchor: .top)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var anchorsOverlay: some View {
    if viewModel.contentHeight > 1 {
      VStack(spacing: 0) {
        ForEach(0..<anchorCount, id: \.self) { index in
          Color.clear
            .frame(height: viewModel.contentHeight / CGFloat(anchorCount))
            .id("sync_anchor_\(index)")
        }
      }
      .allowsHitTesting(false)
    }
  }
}
