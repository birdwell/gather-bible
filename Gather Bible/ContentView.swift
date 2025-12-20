//
//  ContentView.swift
//  Gather Bible
//
//  Created by Josh Birdwell on 12/20/25.
//

import SwiftUI
import SwiftData
import YouVersionPlatformReader

struct ContentView: View {

    var body: some View {
        BibleReaderView(
             appName: "Gather Bible",
             signInMessage: "Sign in to see your YouVersion highlights in this Sample App."
         )
    }
}

#Preview {
    ContentView()
}
