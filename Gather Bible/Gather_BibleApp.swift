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
import FirebaseDatabase

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Configure Firebase persistence for offline support
    Database.database().isPersistenceEnabled = true
    
    return true
  }
}

@main
struct Gather_BibleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        YouVersionConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
