import Foundation

/// Discussion question model
struct Discussion: Codable, Identifiable {
  let id: String
  let sessionId: String
  let question: String
  let status: DiscussionStatus
  let createdAt: Double
  let activatedAt: Double?

  /// Initialize from Firebase dictionary
  init?(id: String, from dictionary: [String: Any]) {
    guard let sessionId = dictionary["sessionId"] as? String,
      let question = dictionary["question"] as? String,
      let statusRaw = dictionary["status"] as? String,
      let status = DiscussionStatus(rawValue: statusRaw),
      let createdAt = dictionary["createdAt"] as? Double
    else {
      return nil
    }

    self.id = id
    self.sessionId = sessionId
    self.question = question
    self.status = status
    self.createdAt = createdAt
    self.activatedAt = dictionary["activatedAt"] as? Double
  }

  /// Initialize for local creation
  init(
    id: String, sessionId: String, question: String, status: DiscussionStatus, createdAt: Double,
    activatedAt: Double? = nil
  ) {
    self.id = id
    self.sessionId = sessionId
    self.question = question
    self.status = status
    self.createdAt = createdAt
    self.activatedAt = activatedAt
  }
}
