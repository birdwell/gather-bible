import Foundation

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
      let active = dictionary["active"] as? Bool
    else {
      return nil
    }

    self.id = userId
    self.displayName = displayName
    self.isHost = isHost
    self.active = active
    self.lastSeen = dictionary["lastSeen"] as? Double
  }
}
