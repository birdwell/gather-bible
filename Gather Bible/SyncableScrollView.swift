//
//  SyncableScrollView.swift
//  Gather Bible
//
//  Native SwiftUI ScrollView with scroll position tracking and sync
//

import SwiftUI

/// Scroll offset tracking preference key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    @Binding var targetScrollOffset: Double  // Changed to Binding
    
    let isHost: Bool
    let shouldApplyOffset: Bool
    let onScroll: (CGFloat) -> Void
    let content: Content
    
    // Anchor count for scroll-to positions (100 = 1% precision)
    private let anchorCount = 100
    
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
                    ZStack(alignment: .topLeading) {
                        // Scroll offset tracker
                        GeometryReader { innerGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetKey.self,
                                    value: outerGeometry.frame(in: .global).minY - innerGeometry.frame(in: .global).minY
                                )
                        }
                        .frame(height: 0)
                        
                        // Actual content with size tracking
                        VStack(spacing: 0) {
                            content
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ContentSizeKey.self,
                                    value: geo.size
                                )
                            }
                        )
                        
                        // Invisible anchors distributed through content for scrolling
                        VStack(spacing: 0) {
                            ForEach(0..<anchorCount, id: \.self) { index in
                                Color.clear
                                    .frame(height: max(1, contentHeight / CGFloat(anchorCount)))
                                    .id("anchor_\(index)")
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    scrollOffset = offset
                    onScroll(offset)
                }
                .onPreferenceChange(ContentSizeKey.self) { size in
                    contentHeight = size.height
                }
                .onAppear {
                    viewHeight = outerGeometry.size.height
                }
                .onChange(of: outerGeometry.size.height) { _, height in
                    viewHeight = height
                }
                // Guest scroll sync - now using Binding so onChange fires properly
                .onChange(of: targetScrollOffset) { _, newOffset in
                    guard shouldApplyOffset && !isHost else { return }
                    guard contentHeight > viewHeight else { return }
                    
                    // Map offset percentage to anchor index
                    let clampedOffset = min(max(newOffset, 0), 1)
                    let anchorIndex = Int(clampedOffset * Double(anchorCount - 1))
                    
                    withAnimation(.easeOut(duration: 0.08)) {
                        scrollProxy.scrollTo("anchor_\(anchorIndex)", anchor: .top)
                    }
                }
            }
        }
    }
}
