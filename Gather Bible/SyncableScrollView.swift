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
    @Binding var scrollOffset: CGFloat
    @Binding var contentHeight: CGFloat
    @Binding var viewHeight: CGFloat
    @Binding var targetScrollOffset: Double
    
    let isHost: Bool
    let shouldApplyOffset: Bool
    let onScroll: (CGFloat) -> Void
    let content: Content
    
    // Use more anchors for finer precision
    private let anchorCount = 400
    
    init(
        scrollOffset: Binding<CGFloat>,
        contentHeight: Binding<CGFloat>,
        viewHeight: Binding<CGFloat>,
        isHost: Bool,
        targetScrollOffset: Binding<Double>,
        shouldApplyOffset: Bool,
        onScroll: @escaping (CGFloat) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._scrollOffset = scrollOffset
        self._contentHeight = contentHeight
        self._viewHeight = viewHeight
        self.isHost = isHost
        self._targetScrollOffset = targetScrollOffset
        self.shouldApplyOffset = shouldApplyOffset
        self.onScroll = onScroll
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
                    scrollOffset = newOffset
                    onScroll(newOffset)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentSize.height
                } action: { _, newHeight in
                    contentHeight = newHeight
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.visibleRect.height
                } action: { _, newHeight in
                    viewHeight = newHeight
                }
                .onAppear {
                    viewHeight = outerGeometry.size.height
                }
                .onPreferenceChange(ContentSizeKey.self) { size in
                    if size.height > contentHeight {
                        contentHeight = size.height
                    }
                }
                .onChange(of: targetScrollOffset) { oldValue, newOffset in
                    guard shouldApplyOffset && !isHost else { return }
                    guard contentHeight > viewHeight else { return }
                    guard abs(newOffset - oldValue) > 0.001 else { return }
                    
                    let clampedOffset = min(max(newOffset, 0), 1)
                    let scrollableHeight = contentHeight - viewHeight
                    let targetPixelOffset = clampedOffset * scrollableHeight
                    let anchorSpacing = contentHeight / Double(anchorCount)
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
        if contentHeight > 1 {
            VStack(spacing: 0) {
                ForEach(0..<anchorCount, id: \.self) { index in
                    Color.clear
                        .frame(height: contentHeight / CGFloat(anchorCount))
                        .id("sync_anchor_\(index)")
                }
            }
            .allowsHitTesting(false)
        }
    }
}
