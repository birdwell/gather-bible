import Combine
import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class ExternalDisplayManager {
  static let shared = ExternalDisplayManager()

  private(set) var isExternalDisplayConnected = false
  private(set) var externalWindowScene: UIWindowScene?

  private var externalWindow: UIWindow?
  private var readerViewModel: BibleReaderViewModel?
  private var cancellables = Set<AnyCancellable>()

  private init() {
    setupSceneNotifications()
    checkForExistingExternalScenes()
  }

  private func setupSceneNotifications() {
    NotificationCenter.default.publisher(for: UIScene.willConnectNotification)
      .compactMap { $0.object as? UIWindowScene }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] scene in
        self?.handleSceneConnect(scene)
      }
      .store(in: &cancellables)

    NotificationCenter.default.publisher(for: UIScene.didDisconnectNotification)
      .compactMap { $0.object as? UIWindowScene }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] scene in
        self?.handleSceneDisconnect(scene)
      }
      .store(in: &cancellables)
  }

  private func checkForExistingExternalScenes() {
    for session in UIApplication.shared.openSessions {
      if let scene = session.scene as? UIWindowScene,
        isExternalScene(scene)
      {
        handleSceneConnect(scene)
        break
      }
    }
  }

  /// Identifies external displays by scene role rather than the deprecated
  /// `UIScreen.main` comparison. Any window scene that isn't the main app
  /// window counts as external, so displays connected under other external
  /// roles (e.g. the pre-iOS 16 interactive role) are still detected.
  private func isExternalScene(_ scene: UIWindowScene) -> Bool {
    scene.session.role != .windowApplication
  }

  private func handleSceneConnect(_ scene: UIWindowScene) {
    guard isExternalScene(scene) else { return }

    externalWindowScene = scene
    isExternalDisplayConnected = true

    if let viewModel = readerViewModel {
      showExternalWindow(on: scene, with: viewModel)
    }
  }

  private func handleSceneDisconnect(_ scene: UIWindowScene) {
    guard scene == externalWindowScene else { return }

    dismissExternalWindow()
    externalWindowScene = nil
    isExternalDisplayConnected = false
  }

  func attachReader(_ viewModel: BibleReaderViewModel) {
    readerViewModel = viewModel

    if let scene = externalWindowScene {
      showExternalWindow(on: scene, with: viewModel)
    }
  }

  func detachReader() {
    readerViewModel = nil
    dismissExternalWindow()
  }

  private func showExternalWindow(on scene: UIWindowScene, with viewModel: BibleReaderViewModel) {
    dismissExternalWindow()

    let window = UIWindow(windowScene: scene)

    let tvReaderView = TVReaderView(viewModel: viewModel)
    let hostingController = UIHostingController(rootView: tvReaderView)
    // Near-black rather than pure black to reduce halation on TVs, matching
    // TVReaderView's background.
    hostingController.view.backgroundColor = UIColor(white: 0.08, alpha: 1)

    window.rootViewController = hostingController
    window.isHidden = false

    externalWindow = window
  }

  private func dismissExternalWindow() {
    externalWindow?.isHidden = true
    externalWindow = nil
  }
}
