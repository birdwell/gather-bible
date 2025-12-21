//
//  YouVersionConfig.swift
//  Gather Bible
//
//  Configuration for YouVersion SDK integration
//

import Foundation
import YouVersionPlatform

/// Configuration for YouVersion SDK integration
struct YouVersionConfig {
    private static let appKey = "LzkWlyXoj6qM5OGnOhUdKGjjvIXNNEBTYQRjL68MUPtFkYmJ"
    
    /// Initialize YouVersion SDK
    static func configure() {
        YouVersionPlatform.configure(appKey: appKey)
    }
    
    /// Get available Bible versions
    static func getAvailableVersions() async throws -> [BibleVersion] {
        return try await YouVersionAPI.Bible.versions()
    }
    
    /// Get version details including books
    static func getVersionDetails(versionId: Int) async throws -> BibleVersion {
        return try await YouVersionAPI.Bible.version(versionId: versionId)
    }
}

/// Extension to make BibleVersion identifiable for SwiftUI Lists
extension BibleVersion: Identifiable {}

/// Extensions for BibleReference to handle USFM parsing
extension BibleReference {
    /// Parse a verse ID into its components (e.g., "GEN.1.1" -> (book: "GEN", chapter: 1, verse: 1))
    static func parseVerseId(_ verseId: String) -> (book: String, chapter: Int, verse: Int)? {
        let components = verseId.split(separator: ".")
        guard components.count >= 2 else { return nil }
        
        let book = String(components[0])
        guard let chapter = Int(components[1]) else { return nil }
        let verse = components.count > 2 ? (Int(components[2]) ?? 1) : 1
        
        return (book, chapter, verse)
    }
    
    /// Validate verse ID format
    static func validateVerseId(_ verseId: String) -> Bool {
        return parseVerseId(verseId) != nil
    }
}