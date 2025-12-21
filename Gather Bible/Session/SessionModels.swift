//
//  SessionModels.swift
//  Gather Bible
//
//  Data models for Firebase session sync
//

import Foundation

/// Session state data model matching Firebase Realtime Database structure
struct SessionState: Codable {
    let joinCode: String
    let hostId: String
    let book: String
    let chapter: Int
    let startVerseId: String
    let verseOffset: Double
    let scrolling: Bool
    let versionId: Int
    let updatedAt: Double?
    let active: Bool
    
    /// Initialize from Firebase dictionary
    init?(from dictionary: [String: Any]) {
        guard let joinCode = dictionary["joinCode"] as? String,
              let hostId = dictionary["hostId"] as? String,
              let book = dictionary["book"] as? String,
              let chapter = dictionary["chapter"] as? Int,
              let startVerseId = dictionary["startVerseId"] as? String,
              let verseOffset = dictionary["verseOffset"] as? Double,
              let scrolling = dictionary["scrolling"] as? Bool,
              let active = dictionary["active"] as? Bool else {
            return nil
        }
        
        self.joinCode = joinCode
        self.hostId = hostId
        self.book = book
        self.chapter = chapter
        self.startVerseId = startVerseId
        self.verseOffset = verseOffset
        self.scrolling = scrolling
        self.versionId = dictionary["versionId"] as? Int ?? 111
        self.updatedAt = dictionary["updatedAt"] as? Double
        self.active = active
    }
}

/// Participant data model
struct SessionParticipant: Codable, Identifiable {
    let id: String
    let displayName: String
    let isHost: Bool
    let active: Bool
    let lastSeen: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case displayName, isHost, active, lastSeen
    }
    
    /// Initialize from Firebase dictionary
    init?(userId: String, from dictionary: [String: Any]) {
        guard let displayName = dictionary["displayName"] as? String,
              let isHost = dictionary["isHost"] as? Bool,
              let active = dictionary["active"] as? Bool else {
            return nil
        }
        
        self.id = userId
        self.displayName = displayName
        self.isHost = isHost
        self.active = active
        self.lastSeen = dictionary["lastSeen"] as? Double
    }
}