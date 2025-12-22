//
//  SyncableScrollView.swift
//  Gather Bible
//
//  iOS 18+ native ScrollView with efficient scroll position sync
//

import SwiftUI

/// A native SwiftUI scroll view with efficient scroll position sync
/// Uses iOS 18 ScrollPosition API and onScrollPhaseChange for batched updates
struct SyncableScrollView<Content: View>: View {
  @Bindable var viewModel: BibleReaderViewModel
  let content: Content

  @State private var scrollPosition = ScrollPosition()
  @State private var isUserScrolling = false
  @State private var lastScrollOffset: CGFloat = 0

  init(
    viewModel: BibleReaderViewModel,
    @ViewBuilder content: () -> Content
  ) {
    self.viewModel = viewModel
    self.content = content()
  }

  var body: some View {
    ScrollView {
      content
    }
    .scrollPosition($scrollPosition)
    .onScrollGeometryChange(for: CGFloat.self) { geo in
      geo.contentOffset.y + geo.contentInsets.top
    } action: { _, newOffset in
      lastScrollOffset = newOffset
    }
    .onScrollPhaseChange { _, newPhase in
      isUserScrolling = newPhase.isScrolling

      // Host publishes position when scrolling stops
      if viewModel.isHost && !newPhase.isScrolling {
        viewModel.publishScrollPosition(offset: lastScrollOffset)
      }
    }
    .onChange(of: viewModel.targetScrollOffset) { _, targetOffset in
      // Guests apply position when not actively scrolling
      guard viewModel.shouldApplyScrollOffset else { return }
      guard !isUserScrolling else { return }

      scrollPosition.scrollTo(y: targetOffset)
    }
  }
}
