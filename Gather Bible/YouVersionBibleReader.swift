//
//  YouVersionBibleReader.swift
//  Gather Bible
//
//  Bible reader using YouVersion Swift SDK
//

import Combine
import Foundation
import SwiftUI
import YouVersionPlatform
import YouVersionPlatformReader
import YouVersionPlatformUI

// MARK: - Scroll Offset Preference Key (unused, keeping for reference)

/// Bible reader that uses YouVersion SDK's BibleTextView directly
struct YouVersionBibleReader: View {
    @ObservedObject var sessionViewModel: SessionViewModel

    @State private var selectedBook = "GEN"
    @State private var selectedChapter = 1
    @State private var selectedVersionId = 111  // Default to NIV
    @State private var availableVersions: [BibleVersion] = []
    @State private var selectedVersionBooks: [BibleBook] = []
    @State private var showVersionPicker = false
    @State private var isLoadingVersions = true
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 1
    @State private var viewHeight: CGFloat = 1
    @State private var lastPublishedOffset: Double = 0
    @State private var targetScrollOffset: Double = 0  // For guest scroll sync

    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation header
            NavigationHeader(
                selectedBook: $selectedBook,
                selectedChapter: $selectedChapter,
                selectedVersionId: $selectedVersionId,
                availableVersions: availableVersions,
                availableBooks: selectedVersionBooks,
                showVersionPicker: $showVersionPicker,
                onNavigate: handleNavigation
            )

            // Bible content with syncable scroll
            SyncableScrollView(
                scrollOffset: $scrollOffset,
                contentHeight: $contentHeight,
                viewHeight: $viewHeight,
                isHost: sessionViewModel.isHost,
                targetScrollOffset: $targetScrollOffset,
                shouldApplyOffset: !sessionViewModel.isHost && sessionViewModel.followHost,
                onScroll: { offset in
                    // Host publishes scroll position
                    if sessionViewModel.isHost {
                        let scrollPercentage =
                            contentHeight > viewHeight
                            ? offset / (contentHeight - viewHeight)
                            : 0

                        // Only publish if changed significantly
                        if abs(scrollPercentage - lastPublishedOffset) > 0.005 {
                            lastPublishedOffset = scrollPercentage
                            sessionViewModel.publishNavigation(
                                book: selectedBook,
                                chapter: selectedChapter,
                                verseId: "\(selectedBook).\(selectedChapter).1",
                                verseOffset: scrollPercentage,
                                scrolling: true
                            )
                        }
                    }
                }
            ) {
                BibleTextView(
                    BibleReference(
                        versionId: selectedVersionId,
                        bookUSFM: selectedBook,
                        chapter: selectedChapter
                    )
                )
                .id("\(selectedBook).\(selectedChapter).\(selectedVersionId)")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }

        .navigationTitle("Bible")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadVersions()
            syncFromSession()
        }
        .sheet(isPresented: $showVersionPicker) {
            VersionPickerSheet(
                versions: availableVersions,
                selectedVersionId: $selectedVersionId,
                onDismiss: { showVersionPicker = false }
            )
        }
        .onChange(of: selectedVersionId) { _, _ in
            Task { await loadBooksForVersion() }
        }
        .onReceive(sessionViewModel.$currentState.compactMap { $0 }) { state in
            // Follow host (book/chapter/version/scroll) if we're a guest
            if !sessionViewModel.isHost && sessionViewModel.followHost {
                selectedBook = state.book
                selectedChapter = state.chapter
                selectedVersionId = state.versionId
                targetScrollOffset = state.verseOffset  // Sync scroll position
            }
        }
    }

    private func loadVersions() {
        Task {
            do {
                let versions = try await YouVersionConfig.getAvailableVersions()
                await MainActor.run {
                    availableVersions = versions
                    isLoadingVersions = false

                    // Set default to NIV if available
                    if let niv = versions.first(where: {
                        ($0.abbreviation ?? "").uppercased() == "NIV"
                    }) {
                        selectedVersionId = niv.id
                    }
                }
                await loadBooksForVersion()
            } catch {
                print("Error loading versions: \(error)")
                await MainActor.run { isLoadingVersions = false }
            }
        }
    }

    private func loadBooksForVersion() async {
        do {
            let version = try await YouVersionConfig.getVersionDetails(versionId: selectedVersionId)
            await MainActor.run {
                if let books = version.books {
                    selectedVersionBooks = books

                    // Reset to valid book if current is not in this version
                    if !books.contains(where: { ($0.id ?? "") == selectedBook }) {
                        selectedBook = books.first?.id ?? "GEN"
                        selectedChapter = 1
                    }
                }
            }
        } catch {
            print("Error loading books: \(error)")
        }
    }

    private func syncFromSession() {
        if let state = sessionViewModel.sessionSync?.currentState {
            selectedBook = state.book
            selectedChapter = state.chapter
            selectedVersionId = state.versionId
        }
    }

    private func handleNavigation(book: String, chapter: Int) {
        selectedBook = book
        selectedChapter = chapter

        // Publish navigation if we're the host
        if sessionViewModel.isHost {
            sessionViewModel.publishNavigation(
                book: book,
                chapter: chapter,
                verseId: "\(book).\(chapter).1",
                verseOffset: 0.0,
                scrolling: false
            )
        }
    }
}

// MARK: - Navigation Header

struct NavigationHeader: View {
    @Binding var selectedBook: String
    @Binding var selectedChapter: Int
    @Binding var selectedVersionId: Int
    let availableVersions: [BibleVersion]
    let availableBooks: [BibleBook]
    @Binding var showVersionPicker: Bool
    let onNavigate: (String, Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Version picker button
            HStack {
                if let version = availableVersions.first(where: { $0.id == selectedVersionId }) {
                    Button {
                        showVersionPicker = true
                    } label: {
                        HStack {
                            Text((version.abbreviation ?? "").uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.1)))
                    }
                }
                Spacer()
            }
            .padding(.horizontal)

            // Book and chapter pickers
            HStack {
                Picker("Book", selection: $selectedBook) {
                    ForEach(availableBooks, id: \.id) { (book: BibleBook) in
                        Text(book.title ?? "Unknown")
                            .tag(book.id ?? "")
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedBook) { _, _ in
                    selectedChapter = 1
                    onNavigate(selectedBook, selectedChapter)
                }

                Spacer()

                Picker("Chapter", selection: $selectedChapter) {
                    if let book = availableBooks.first(where: { ($0.id ?? "") == selectedBook }),
                        let chapters = book.chapters
                    {
                        ForEach(1...chapters.count, id: \.self) { chapter in
                            Text("\(chapter)").tag(chapter)
                        }
                    } else {
                        Text("1").tag(1)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedChapter) { _, _ in
                    onNavigate(selectedBook, selectedChapter)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK: - Version Picker Sheet

struct VersionPickerSheet: View {
    let versions: [BibleVersion]
    @Binding var selectedVersionId: Int
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List(versions, id: \.id) { version in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text((version.abbreviation ?? "").uppercased())
                            .font(.headline)
                        Text(version.title ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if version.id == selectedVersionId {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedVersionId = version.id
                    onDismiss()
                }
            }
            .navigationTitle("Select Bible Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let bibleContentLoaded = Notification.Name("bibleContentLoaded")
    static let bibleReaderNavigateChapter = Notification.Name("bibleReaderNavigateChapter")
}

// MARK: - Preview

#Preview {
    NavigationView {
        YouVersionBibleReader(sessionViewModel: SessionViewModel())
    }
}
