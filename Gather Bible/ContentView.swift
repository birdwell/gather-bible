//
//  ContentView.swift
//  Gather Bible
//
//  Created by Josh Birdwell on 12/20/25.
//

import SwiftData
import SwiftUI
import YouVersionPlatformReader

struct ContentView: View {

    var body: some View {
        TabView {
            BibleReaderView(
                appName: "Gather Bible",
                signInMessage: "Sign in to see your YouVersion highlights in this Sample App."
            )
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
    }
}

#Preview {
    ContentView()
}
