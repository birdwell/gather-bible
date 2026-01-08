import Foundation
import MultipeerConnectivity

struct DiscoveredSession: Identifiable, Equatable {
  let id: String
  let peerID: MCPeerID
  let joinCode: String
  let hostName: String
  let discoveredAt: Date

  init(peerID: MCPeerID, joinCode: String, hostName: String) {
    self.id = peerID.displayName + joinCode
    self.peerID = peerID
    self.joinCode = joinCode
    self.hostName = hostName
    self.discoveredAt = Date()
  }

  static func == (lhs: DiscoveredSession, rhs: DiscoveredSession) -> Bool {
    lhs.id == rhs.id
  }
}
