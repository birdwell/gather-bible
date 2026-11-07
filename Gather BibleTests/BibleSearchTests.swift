import Foundation
import Testing
import YouVersionPlatformCore

@testable import Gather_Bible

private final class StubSearchClient: BibleSearching, @unchecked Sendable {
  var pages: [String: BibleSearchPage] = [:]
  var error: Error?
  var delays: [String: Duration] = [:]
  private(set) var queries: [String] = []

  func searchVerses(query: String, versionId: Int, pageToken: String?) async throws
    -> BibleSearchPage
  {
    queries.append(query)
    if let delay = delays[query] { try? await Task.sleep(for: delay) }
    if let error { throw error }
    return pages[pageToken ?? query] ?? BibleSearchPage(references: [], didYouMean: [], nextPageToken: nil)
  }
}

@MainActor
struct BibleSearchTests {

  private func reference(_ verse: Int) -> BibleReference {
    BibleReference(versionId: 111, bookUSFM: "JHN", chapter: 3, verse: verse)
  }

  private func page(_ verses: [Int], next: String? = nil) -> BibleSearchPage {
    BibleSearchPage(references: verses.map(reference), didYouMean: [], nextPageToken: next)
  }

  private func wait() async {
    try? await Task.sleep(for: .milliseconds(120))
  }

  // MARK: - Client

  @Test func testRequestURLEncodesTheQuery() throws {
    let url = try BibleSearchClient.url(query: "john 3:16", versionId: 111, pageToken: nil)
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

    #expect(url.host == "api.youversion.com")
    #expect(url.path == "/v1/search-verses")
    #expect(items?.first { $0.name == "query" }?.value == "john 3:16")
    #expect(items?.first { $0.name == "bible_id" }?.value == "111")
  }

  @Test func testTooLongQueryIsRejected() {
    #expect(throws: BibleSearchError.self) {
      try BibleSearchClient.url(
        query: String(repeating: "a", count: 101), versionId: 111, pageToken: nil)
    }
  }

  @Test func testResponseDecodesAndSkipsMalformedReferences() throws {
    let json = """
      {"verses":[{"reference":"JHN.3.16"},{"reference":"bad"}],"user_intent":"text",
      "did_you_mean":["light"],"search_instead_for":null,"next_page_token":"abc"}
      """
    let page = try BibleSearchClient.page(from: Data(json.utf8), versionId: 111)

    #expect(page.references == [reference(16)])
    #expect(page.didYouMean == ["light"])
    #expect(page.nextPageToken == "abc")
  }

  // MARK: - View model

  @Test func testTypingDebouncesToOneSearch() async {
    let client = StubSearchClient()
    let viewModel = BibleSearchViewModel(client: client, versionId: 111, debounce: .milliseconds(30))

    viewModel.query = "l"
    viewModel.query = "li"
    viewModel.query = "light"
    await wait()

    #expect(client.queries == ["light"])
  }

  @Test func testResultsAndEmptyPhases() async {
    let client = StubSearchClient()
    client.pages["light"] = page([16])
    let viewModel = BibleSearchViewModel(client: client, versionId: 111, debounce: .zero)

    viewModel.query = "light"
    await wait()
    #expect(viewModel.phase == .results)
    #expect(viewModel.references == [reference(16)])

    viewModel.query = "zzzz"
    await wait()
    #expect(viewModel.phase == .empty)
    #expect(viewModel.references.isEmpty)
  }

  @Test func testClearingTheQueryReturnsToIdle() async {
    let client = StubSearchClient()
    client.pages["light"] = page([16])
    let viewModel = BibleSearchViewModel(client: client, versionId: 111, debounce: .zero)

    viewModel.query = "light"
    await wait()
    viewModel.query = "  "

    #expect(viewModel.phase == .idle)
    #expect(viewModel.references.isEmpty)
  }

  @Test func testSlowOlderSearchDoesNotReplaceNewerResults() async {
    let client = StubSearchClient()
    client.pages["old"] = page([1])
    client.pages["new"] = page([2])
    client.delays["old"] = .milliseconds(80)
    let viewModel = BibleSearchViewModel(client: client, versionId: 111, debounce: .zero)

    viewModel.query = "old"
    try? await Task.sleep(for: .milliseconds(15))
    viewModel.query = "new"
    try? await Task.sleep(for: .milliseconds(160))

    #expect(viewModel.references == [reference(2)])
  }

  @Test func testFailureThenRetry() async {
    let client = StubSearchClient()
    client.error = BibleSearchError.serverError
    let viewModel = BibleSearchViewModel(client: client, versionId: 111, debounce: .zero)

    viewModel.query = "light"
    await wait()
    #expect(viewModel.phase == .failed)

    client.error = nil
    client.pages["light"] = page([16])
    viewModel.retry()
    await wait()
    #expect(viewModel.phase == .results)
  }

  @Test func testLoadMoreAppendsWithoutDuplicates() async {
    let client = StubSearchClient()
    client.pages["light"] = page([1, 2], next: "next")
    client.pages["next"] = page([2, 3])
    let viewModel = BibleSearchViewModel(client: client, versionId: 111, debounce: .zero)

    viewModel.query = "light"
    await wait()
    await viewModel.loadMore()

    #expect(viewModel.references == [reference(1), reference(2), reference(3)])
    #expect(viewModel.canLoadMore == false)
  }
}
