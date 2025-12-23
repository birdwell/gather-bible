import Foundation

/// Guest response to a discussion
struct DiscussionResponse: Codable, Identifiable {
  let id: String  // participantId
  let discussionId: String
  let participantName: String
  let response: String
  let submittedAt: Double

  /// Initialize from Firebase dictionary
  init?(participantId: String, discussionId: String, from dictionary: [String: Any]) {
    guard let participantName = dictionary["participantName"] as? String,
      let response = dictionary["response"] as? String,
      let submittedAt = dictionary["submittedAt"] as? Double
    else {
      return nil
    }

    self.id = participantId
    self.discussionId = discussionId
    self.participantName = participantName
    self.response = response
    self.submittedAt = submittedAt
  }
}
