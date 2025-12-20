//
//  Gather_BibleApp.swift
//  Gather Bible
//
//  Created by Josh Birdwell on 12/20/25.
//

import SwiftUI
import SwiftData
import YouVersionPlatform


@main
struct Gather_BibleApp: App {
    init() {
        YouVersionPlatform.configure(appKey: "LzkWlyXoj6qM5OGnOhUdKGjjvIXNNEBTYQRjL68MUPtFkYmJ")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
