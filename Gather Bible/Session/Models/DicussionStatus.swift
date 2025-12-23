import Foundation

/// Status of a discussion
enum DiscussionStatus: String, Codable {
  case draft  // Host created but not sent
  case active  // Prompt sent to guests
  case completed  // Discussion closed
}
