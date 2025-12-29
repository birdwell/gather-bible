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

  var body: some View {
    TabView {
      Tab("Bible", systemImage: "book.fill") {
        NavigationStack {
          BibleReader()
        }
      }

      Tab("Community", systemImage: "person.3.fill") {
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
  }
}

#Preview {
  ContentView()
}
