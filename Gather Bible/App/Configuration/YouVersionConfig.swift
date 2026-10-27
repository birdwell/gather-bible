//
//  YouVersionConfig.swift
//  Gather Bible
//
//  Configuration for YouVersion SDK integration
//

import Foundation
import YouVersionPlatform

/// Configuration for YouVersion SDK integration.
///
/// The SDK calls YouVersion from the device, so this key is still embedded in
/// the app binary when it is injected at build time. It must not be committed.
struct YouVersionConfig {
    private static let appKeyName = "YOUVERSION_APP_KEY"

    /// Initialize YouVersion SDK.
    /// Crashes at startup when the key is missing or still an unexpanded build setting.
    static func configure() {
        guard let appKey = resolvedAppKey() else {
            fatalError(
                """
                YOUVERSION_APP_KEY is not set. Add it to the process environment \
                for local runs, or pass it as an xcodebuild build setting so it is \
                written into Info.plist. TestFlight reads the GitHub Actions secret \
                YOUVERSION_APP_KEY. Store the rotated value in Infisical and copy it \
                there before deploying.
                """
            )
        }
        YouVersionPlatform.configure(appKey: appKey)
    }

    /// Get available Bible versions
    static func getAvailableVersions(forLanguageTag: String?) async throws -> [BibleVersion] {
        return try await YouVersionAPI.Bible.versions(forLanguageTag: forLanguageTag)
    }

    /// Get version details including books
    static func getVersionDetails(versionId: Int) async throws -> BibleVersion {
        return try await YouVersionAPI.Bible.version(versionId: versionId)
    }

    /// Runtime environment wins so an Xcode scheme can supply the key.
    /// Archive/TestFlight builds read the Info.plist value baked in at build time.
    private static func resolvedAppKey() -> String? {
        let fromEnvironment = ProcessInfo.processInfo.environment[appKeyName]
        let fromBundle = Bundle.main.object(forInfoDictionaryKey: appKeyName) as? String
        return normalized(fromEnvironment) ?? normalized(fromBundle)
    }

    private static func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              !trimmed.hasPrefix("$(") else {
            return nil
        }
        return trimmed
    }
}

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
