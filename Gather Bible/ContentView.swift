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
            // Bible tab with YouVersion integration
            NavigationStack {
                YouVersionBibleReader(sessionViewModel: sessionViewModel)
            }
            .tabItem {
                Label("Bible", systemImage: "book.fill")
            }

            // Community tab with session management
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
