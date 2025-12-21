//
//  SyncableScrollView.swift
//  Gather Bible
//
//  Native SwiftUI ScrollView with scroll position tracking and sync
//

import os.log
import SwiftUI

// #region agent log
private let debugLogger = Logger(subsystem: "Josh-Birdwell.Gather-Bible", category: "DEBUG")
private func debugLog(_ location: String, _ message: String, _ data: [String: Any] = [:]) {
    var dataStr = ""
    if !data.isEmpty, let jsonData = try? JSONSerialization.data(withJSONObject: data),
       let str = String(data: jsonData, encoding: .utf8) { dataStr = " | \(str)" }
    debugLogger.notice("🔍 [DEBUG] \(location): \(message)\(dataStr)")
}
// #endregion

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
    @Binding var targetScrollOffset: Double
    
    let isHost: Bool
    let shouldApplyOffset: Bool
    let onScroll: (CGFloat) -> Void
    let content: Content
    
    // Use more anchors for finer precision
    private let anchorCount = 200
    
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
                    // Content with inline anchors in background
                    content
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ContentSizeKey.self, value: geo.size)
                            }
                        )
                        .background(alignment: .top) {
                            // Anchors that span the full content height
                            anchorsOverlay
                        }
                }
                // iOS 18+ scroll tracking - this fires continuously during scroll
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newOffset in
                    // #region agent log
                    debugLog("SyncableScrollView:scrollGeometry", "Scroll geometry changed", [
                        "hypothesisId": "H9",
                        "offset": newOffset,
                        "isHost": isHost
                    ])
                    // #endregion
                    scrollOffset = newOffset
                    onScroll(newOffset)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentSize.height
                } action: { _, newHeight in
                    // #region agent log
                    debugLog("SyncableScrollView:contentGeometry", "Content height changed", [
                        "hypothesisId": "H9",
                        "height": newHeight,
                        "isHost": isHost
                    ])
                    // #endregion
                    contentHeight = newHeight
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.visibleRect.height
                } action: { _, newHeight in
                    viewHeight = newHeight
                }
                .onAppear {
                    // #region agent log
                    debugLog("SyncableScrollView:onAppear", "View appeared", [
                        "hypothesisId": "H7",
                        "viewHeight": outerGeometry.size.height,
                        "isHost": isHost
                    ])
                    // #endregion
                    viewHeight = outerGeometry.size.height
                }
                .onPreferenceChange(ContentSizeKey.self) { size in
                    // Fallback content size tracking
                    if size.height > contentHeight {
                        contentHeight = size.height
                    }
                }
                // Guest scroll sync
                .onChange(of: targetScrollOffset) { oldValue, newOffset in
                    // #region agent log
                    debugLog("SyncableScrollView:onChange", "targetScrollOffset changed", [
                        "hypothesisId": "H5",
                        "oldValue": oldValue,
                        "newOffset": newOffset,
                        "shouldApplyOffset": shouldApplyOffset,
                        "isHost": isHost,
                        "contentHeight": contentHeight,
                        "viewHeight": viewHeight,
                        "offsetDiff": abs(newOffset - oldValue)
                    ])
                    // #endregion
                    guard shouldApplyOffset && !isHost else {
                        // #region agent log
                        debugLog("SyncableScrollView:guard1", "Failed shouldApplyOffset/isHost guard", [
                            "hypothesisId": "H5",
                            "shouldApplyOffset": shouldApplyOffset,
                            "isHost": isHost
                        ])
                        // #endregion
                        return
                    }
                    guard contentHeight > viewHeight else {
                        // #region agent log
                        debugLog("SyncableScrollView:guard2", "Failed contentHeight guard", [
                            "hypothesisId": "H5",
                            "contentHeight": contentHeight,
                            "viewHeight": viewHeight
                        ])
                        // #endregion
                        return
                    }
                    
                    // Only scroll if the offset actually changed significantly
                    guard abs(newOffset - oldValue) > 0.001 else {
                        // #region agent log
                        debugLog("SyncableScrollView:guard3", "Failed offset change threshold", [
                            "hypothesisId": "H5",
                            "diff": abs(newOffset - oldValue)
                        ])
                        // #endregion
                        return
                    }
                    
                    // Convert scroll percentage to target pixel offset
                    let clampedOffset = min(max(newOffset, 0), 1)
                    let scrollableHeight = contentHeight - viewHeight
                    let targetPixelOffset = clampedOffset * scrollableHeight
                    
                    // Map pixel offset to anchor index
                    // Anchors are at positions: index * (contentHeight / anchorCount)
                    let anchorSpacing = contentHeight / Double(anchorCount)
                    let anchorIndex = min(Int(targetPixelOffset / anchorSpacing), anchorCount - 1)
                    
                    // #region agent log
                    debugLog("SyncableScrollView:scrollTo", "Scrolling to anchor", [
                        "hypothesisId": "H5",
                        "clampedOffset": clampedOffset,
                        "targetPixelOffset": targetPixelOffset,
                        "anchorSpacing": anchorSpacing,
                        "anchorIndex": anchorIndex
                    ])
                    // #endregion
                    
                    withAnimation(.easeOut(duration: 0.15)) {
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
            .onAppear {
                // #region agent log
                debugLog("SyncableScrollView:anchors", "Anchors overlay appeared", [
                    "hypothesisId": "H8",
                    "contentHeight": contentHeight,
                    "anchorCount": anchorCount
                ])
                // #endregion
            }
        }
    }
}
