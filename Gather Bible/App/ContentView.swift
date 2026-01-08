//
//  ContentView.swift
//  Gather Bible
//
//  Updated to include session sync integration and iPad-optimized layout
//

import SwiftUI
import YouVersionPlatformReader

struct ContentView: View {
  @StateObject private var sessionViewModel = SessionViewModel()
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var selectedTab = "Bible"

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Bible", systemImage: "book.fill", value: "Bible") {
        NavigationStack {
          BibleReader()
        }
      }

      Tab("Community", systemImage: "person.3.fill", value: "Community") {
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
  }

  private func handleDeepLink(_ url: URL) {
    guard url.scheme == "gatherbible",
          url.host == "join",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
          let code = codeItem.value,
          code.count == 6 else {
      return
    }

    sessionViewModel.pendingJoinCode = code.uppercased()
    selectedTab = "Community"
  }
}

#Preview {
  ContentView()
}
