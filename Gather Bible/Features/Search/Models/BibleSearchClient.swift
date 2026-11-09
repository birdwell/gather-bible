//
//  BibleSearchClient.swift
//  Gather Bible
//
//  Verse search through the YouVersion Platform API
//

import Foundation
import YouVersionPlatformCore

struct BibleSearchPage: Equatable {
  let references: [BibleReference]
  let didYouMean: [String]
  let nextPageToken: String?
}

protocol BibleSearching {
  func searchVerses(query: String, versionId: Int, pageToken: String?) async throws
    -> BibleSearchPage
}

enum BibleSearchError: Error {
  case invalidRequest
  case serverError
}

/// Calls `/v1/search-verses` directly because SDK 1.x has no search API. SDK 5.6 does, but
/// it doesn't compile on the Xcode versions this project builds with.
struct BibleSearchClient: BibleSearching {
  static let queryLengthLimit = 1...100

  private static let host = "api.youversion.com"
  private static let pageSize = 20

  let appKey: String
  var session: URLSession = .shared

  func searchVerses(query: String, versionId: Int, pageToken: String?) async throws
    -> BibleSearchPage
  {
    let url = try Self.url(query: query, versionId: versionId, pageToken: pageToken)
    var request = URLRequest(url: url)
    request.setValue(appKey, forHTTPHeaderField: "X-YVP-App-Key")

    let (data, response) = try await session.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw BibleSearchError.serverError
    }
    return try Self.page(from: data, versionId: versionId)
  }

  static func url(query: String, versionId: Int, pageToken: String?) throws -> URL {
    guard queryLengthLimit.contains(query.count) else { throw BibleSearchError.invalidRequest }

    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.path = "/v1/search-verses"
    components.queryItems = [
      URLQueryItem(name: "query", value: query),
      URLQueryItem(name: "bible_id", value: String(versionId)),
      URLQueryItem(name: "page_size", value: String(pageSize)),
    ]
    if let pageToken {
      components.queryItems?.append(URLQueryItem(name: "page_token", value: pageToken))
    }

    guard let url = components.url else { throw BibleSearchError.invalidRequest }
    return url
  }

  static func page(from data: Data, versionId: Int) throws -> BibleSearchPage {
    let response = try JSONDecoder().decode(Response.self, from: data)
    return BibleSearchPage(
      references: response.verses.compactMap { $0.reference(versionId: versionId) },
      didYouMean: response.didYouMean ?? [],
      nextPageToken: response.nextPageToken
    )
  }

  private struct Response: Decodable {
    let verses: [Verse]
    let didYouMean: [String]?
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
      case verses
      case didYouMean = "did_you_mean"
      case nextPageToken = "next_page_token"
    }
  }

  private struct Verse: Decodable {
    let reference: String

    func reference(versionId: Int) -> BibleReference? {
      let parts = reference.split(separator: ".")
      guard parts.count == 3, let chapter = Int(parts[1]), let verse = Int(parts[2]) else {
        return nil
      }
      return BibleReference(
        versionId: versionId,
        bookUSFM: String(parts[0]),
        chapter: chapter,
        verse: verse
      )
    }
  }
}
