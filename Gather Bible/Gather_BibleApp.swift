//
//  Gather_BibleApp.swift
//  Gather Bible
//
//  Created by Josh Birdwell on 12/20/25.
//

import SwiftUI
import SwiftData
import YouVersionPlatform
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct Gather_BibleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        YouVersionPlatform.configure(appKey: "LzkWlyXoj6qM5OGnOhUdKGjjvIXNNEBTYQRjL68MUPtFkYmJ")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
