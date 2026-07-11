//
//  ContentView.swift
//  Gather Bible
//
//  Updated to include session sync integration and iPad-optimized layout
//

import SwiftUI
import YouVersionPlatformReader

struct ContentView: View {
  /// App-level tab identity. Backed by String raw values for `Tab` value compatibility
  /// while avoiding magic strings at the call sites.
  private enum AppTab: String, Hashable {
    case bible = "Bible"
    case community = "Community"
  }

  @StateObject private var sessionViewModel = SessionViewModel()
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var selectedTab: AppTab = .bible
  @State private var showInvalidLinkAlert = false

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Bible", systemImage: "book.fill", value: AppTab.bible) {
        NavigationStack {
          BibleReader()
        }
      }

      Tab("Community", systemImage: "person.3.fill", value: AppTab.community) {
        if horizontalSizeClass == .regular {
          CommunityViewiPad()
        } else {
          NavigationStack {
            CommunityView()
          }
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
    .environmentObject(sessionViewModel)
    .onOpenURL { url in
      handleDeepLink(url)
    }
    .alert("This invite link isn't valid.", isPresented: $showInvalidLinkAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Ask the host for a new link or enter the session code manually.")
    }
  }

  private func handleDeepLink(_ url: URL) {
    guard url.scheme == "gatherbible",
          url.host == "join",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
          let code = codeItem.value,
          code.count == 6 else {
      showInvalidLinkAlert = true
      return
    }

    sessionViewModel.pendingJoinCode = code.uppercased()
    selectedTab = .community
  }
}

#Preview {
  ContentView()
}
