//
//  ContentView.swift
//  Gather Bible
//
//  Updated to include session sync integration
//

import SwiftData
import SwiftUI
import YouVersionPlatformReader

struct ContentView: View {
  @StateObject private var sessionViewModel = SessionViewModel()

  var body: some View {
    TabView {
      NavigationStack {
        BibleReader()
      }
      .tabItem {
        Label("Bible", systemImage: "book.fill")
      }

      NavigationStack {
        CommunityView()
      }
      .tabItem {
        Label("Community", systemImage: "person.3.fill")
      }
    }
    .environmentObject(sessionViewModel)
  }
}

#Preview {
  ContentView()
}
