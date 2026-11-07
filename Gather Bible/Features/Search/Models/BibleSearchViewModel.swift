//
//  BibleSearchViewModel.swift
//  Gather Bible
//

import Foundation
import Observation
import YouVersionPlatformCore

@MainActor
@Observable
final class BibleSearchViewModel {
  enum Phase: Equatable {
    case idle
    case searching
    case results
    case empty
    case failed
  }

  var query = "" {
    didSet {
      guard query != oldValue else { return }
      scheduleSearch()
    }
  }

  private(set) var phase: Phase = .idle
  private(set) var references: [BibleReference] = []
  private(set) var didYouMean: [String] = []
  private(set) var isLoadingMore = false

  var canLoadMore: Bool { nextPageToken != nil }

  private let client: BibleSearching
  private let versionId: Int
  private let debounce: Duration
  private var nextPageToken: String?
  private var searchTask: Task<Void, Never>?

  init(client: BibleSearching, versionId: Int, debounce: Duration = .milliseconds(300)) {
    self.client = client
    self.versionId = versionId
    self.debounce = debounce
  }

  private var trimmedQuery: String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func retry() {
    scheduleSearch(waiting: false)
  }

  func loadMore() async {
    guard let token = nextPageToken, !isLoadingMore else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }

    // A failed extra page keeps the results already shown and leaves the option to retry.
    if let page = try? await client.searchVerses(
      query: trimmedQuery, versionId: versionId, pageToken: token)
    {
      references += page.references.filter { !references.contains($0) }
      nextPageToken = page.nextPageToken
    }
  }

  private func scheduleSearch(waiting: Bool = true) {
    searchTask?.cancel()

    let currentQuery = trimmedQuery
    guard !currentQuery.isEmpty else {
      reset()
      return
    }

    phase = .searching
    searchTask = Task { [debounce] in
      if waiting {
        try? await Task.sleep(for: debounce)
      }
      guard !Task.isCancelled else { return }
      await search(currentQuery)
    }
  }

  private func search(_ currentQuery: String) async {
    do {
      let page = try await client.searchVerses(
        query: currentQuery, versionId: versionId, pageToken: nil)
      // A slower, older search must not replace the results of a newer one.
      guard !Task.isCancelled, currentQuery == trimmedQuery else { return }

      references = page.references
      didYouMean = page.didYouMean
      nextPageToken = page.nextPageToken
      phase = page.references.isEmpty ? .empty : .results
    } catch {
      guard !Task.isCancelled, currentQuery == trimmedQuery else { return }
      references = []
      didYouMean = []
      nextPageToken = nil
      phase = .failed
    }
  }

  private func reset() {
    references = []
    didYouMean = []
    nextPageToken = nil
    phase = .idle
  }
}
