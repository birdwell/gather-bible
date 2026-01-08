import Combine
import Foundation
import MultipeerConnectivity
import os

@MainActor
class NearbySessionService: NSObject, ObservableObject {
  private let serviceType = "gather-bible"
  private let myPeerID: MCPeerID
  private var session: MCSession?
  private var advertiser: MCNearbyServiceAdvertiser?
  private var browser: MCNearbyServiceBrowser?
  private let log = Logger(subsystem: "com.gatherbible", category: "NearbySession")

  @Published private(set) var nearbySessions: [DiscoveredSession] = []
  @Published private(set) var isAdvertising = false
  @Published private(set) var isBrowsing = false

  private var currentJoinCode: String?

  override init() {
    self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
    super.init()
  }

  // MARK: - Advertising (Host)

  func startAdvertising(joinCode: String, hostName: String) {
    stopAdvertising()

    currentJoinCode = joinCode
    session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    session?.delegate = self

    advertiser = MCNearbyServiceAdvertiser(
      peer: myPeerID,
      discoveryInfo: [
        "joinCode": joinCode,
        "hostName": hostName
      ],
      serviceType: serviceType
    )
    advertiser?.delegate = self
    advertiser?.startAdvertisingPeer()
    isAdvertising = true

    log.info("Started advertising session with code: \(joinCode), host: \(hostName)")
  }

  func stopAdvertising() {
    advertiser?.stopAdvertisingPeer()
    advertiser = nil
    isAdvertising = false
    currentJoinCode = nil
    log.info("Stopped advertising session")
  }

  // MARK: - Browsing (Participant)

  func startBrowsing() {
    stopBrowsing()

    session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    session?.delegate = self

    browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
    browser?.delegate = self
    browser?.startBrowsingForPeers()
    isBrowsing = true
    nearbySessions = []

    log.info("Started browsing for nearby sessions")
  }

  func stopBrowsing() {
    browser?.stopBrowsingForPeers()
    browser = nil
    isBrowsing = false
    nearbySessions = []
    log.info("Stopped browsing for sessions")
  }

  // MARK: - Cleanup

  func stopAll() {
    stopAdvertising()
    stopBrowsing()
    session?.disconnect()
    session = nil
  }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension NearbySessionService: MCNearbyServiceAdvertiserDelegate {
  nonisolated func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser,
    didNotStartAdvertisingPeer error: Error
  ) {
    Task { @MainActor in
      log.error("Failed to advertise: \(error.localizedDescription)")
    }
  }

  nonisolated func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser,
    didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    Task { @MainActor in
      log.info("Received invitation from \(peerID.displayName) - declining (discovery only)")
      invitationHandler(false, nil)
    }
  }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension NearbySessionService: MCNearbyServiceBrowserDelegate {
  nonisolated func browser(
    _ browser: MCNearbyServiceBrowser,
    didNotStartBrowsingForPeers error: Error
  ) {
    Task { @MainActor in
      log.error("Failed to browse: \(error.localizedDescription)")
    }
  }

  nonisolated func browser(
    _ browser: MCNearbyServiceBrowser,
    foundPeer peerID: MCPeerID,
    withDiscoveryInfo info: [String: String]?
  ) {
    Task { @MainActor in
      guard let joinCode = info?["joinCode"] else {
        log.info("Found peer without joinCode: \(peerID.displayName)")
        return
      }

      let hostName = info?["hostName"] ?? peerID.displayName
      let discoveredSession = DiscoveredSession(peerID: peerID, joinCode: joinCode, hostName: hostName)

      if !nearbySessions.contains(where: { $0.id == discoveredSession.id }) {
        nearbySessions.append(discoveredSession)
        log.info("Found session: \(hostName) with code \(joinCode)")
      }
    }
  }

  nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    Task { @MainActor in
      nearbySessions.removeAll { $0.peerID == peerID }
      log.info("Lost peer: \(peerID.displayName)")
    }
  }
}

// MARK: - MCSessionDelegate

extension NearbySessionService: MCSessionDelegate {
  nonisolated func session(
    _ session: MCSession,
    peer peerID: MCPeerID,
    didChange state: MCSessionState
  ) {
    Task { @MainActor in
      log.info("Peer \(peerID.displayName) state changed: \(state.rawValue)")
    }
  }

  nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
  }

  nonisolated func session(
    _ session: MCSession,
    didReceive stream: InputStream,
    withName streamName: String,
    fromPeer peerID: MCPeerID
  ) {}

  nonisolated func session(
    _ session: MCSession,
    didStartReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    with progress: Progress
  ) {}

  nonisolated func session(
    _ session: MCSession,
    didFinishReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    at localURL: URL?,
    withError error: Error?
  ) {}
}
